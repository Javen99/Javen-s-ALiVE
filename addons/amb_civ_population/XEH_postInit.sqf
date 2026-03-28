#include "script_component.hpp"

// Wait for the Civilian Population module to publish all Advanced Civilian
// globals before doing anything. On the server the module init runs before
// postInit so this resolves immediately. On clients it blocks until the
// server broadcasts the publicVariable calls.
if (isNil "ALiVE_advciv_enabled") then {
    waitUntil { !isNil "ALiVE_advciv_enabled" };
};

["ALiVE Advanced Civilians - postInit starting | ALiVE_advciv_enabled = %1", ALiVE_advciv_enabled] call ALIVE_fnc_dump;

// Exit if AdvCiv is disabled
if (!ALiVE_advciv_enabled) exitWith {
    ["ALiVE Advanced Civilians - postInit EXITED (disabled)"] call ALIVE_fnc_dump;
};

// ==============================================
//  SERVER INITIALIZATION
// ==============================================
if (isServer) then {
    ["ALiVE Advanced Civilians - Server postInit starting..."] call ALIVE_fnc_dump;

    // Call the main AdvCiv initialization
    call ALiVE_fnc_advciv_init;

    // Decay nearShots value over time (per-frame handler)
    [{
        if (!ALiVE_advciv_enabled) exitWith {};
        private _units = +ALiVE_advciv_activeUnits;
        {
            if (!isNull _x && {alive _x}) then {
                private _ns = _x getVariable ["ALiVE_advciv_nearShots", 0];
                if (_ns > 0) then {
                    _x setVariable ["ALiVE_advciv_nearShots", (_ns - 0.5) max 0];
                };
            };
        } forEach _units;
    }, 1, []] call CBA_fnc_addPerFrameHandler;

    // Civilian killed event - spread panic
    addMissionEventHandler ["EntityKilled", {
        params ["_killed", "_killer", "_instigator"];
        if (side _killed != civilian) exitWith {};
        private _attackerUnit = if (!isNull _instigator) then {_instigator} else {_killer};
        if (isNull _attackerUnit) exitWith {};
        if (_attackerUnit == _killed) exitWith {};
        if (side _attackerUnit == civilian) exitWith {};
        _attackerUnit setVariable ["ALiVE_advciv_firedAtCiv", true, true];
        {
            if (alive _x && {side _x == civilian} && {!isPlayer _x} && {_x != _killed} && {_x getVariable ["ALiVE_advciv_active", false]}) then {
                _x setVariable ["ALiVE_advciv_state", "PANIC", true];
                _x setVariable ["ALiVE_advciv_panicSource", getPos _killed, true];
                _x setVariable ["ALiVE_advciv_hidingPos", [], true];
                _x setVariable ["ALiVE_advciv_nearShots", 10];
                _x setVariable ["ALiVE_advciv_lastShotTime", time];
            };
        } forEach (_killed nearEntities ["CAManBase", 50]);
    }];

    // Vehicle killed event - treat as explosion
    addMissionEventHandler ["EntityKilled", {
        params ["_killed", "_killer", "_instigator"];
        if (!(_killed isKindOf "LandVehicle") && !(_killed isKindOf "Air") && !(_killed isKindOf "Ship")) exitWith {};
        private _src = if (!isNull _instigator) then {_instigator} else {_killer};
        [getPos _killed, _src] call ALiVE_fnc_advciv_handleExplosion;
    }];

    // Track player-used vehicles
    private _fnc_addGetInEH = {
        params ["_veh"];
        if (isNil {_veh getVariable "ALiVE_advciv_getInEH"}) then {
            _veh setVariable ["ALiVE_advciv_getInEH", true];
            _veh addEventHandler ["GetIn", {
                params ["_vehicle", "_role", "_unit"];
                if (isPlayer _unit) then {
                    _vehicle setVariable ["ALiVE_advciv_wasUsedByPlayer", true, true];
                };
            }];
        };
    };

    { [_x] call _fnc_addGetInEH; } forEach vehicles;

    ["LandVehicle", "initPost", {
        params ["_veh"];
        if (isNil {_veh getVariable "ALiVE_advciv_getInEH"}) then {
            _veh setVariable ["ALiVE_advciv_getInEH", true];
            _veh addEventHandler ["GetIn", {
                params ["_vehicle", "_role", "_unit"];
                if (isPlayer _unit) then {
                    _vehicle setVariable ["ALiVE_advciv_wasUsedByPlayer", true, true];
                };
            }];
        };
    }, true] call CBA_fnc_addClassEventHandler;

    ["Air", "initPost", {
        params ["_veh"];
        if (isNil {_veh getVariable "ALiVE_advciv_getInEH"}) then {
            _veh setVariable ["ALiVE_advciv_getInEH", true];
            _veh addEventHandler ["GetIn", {
                params ["_vehicle", "_role", "_unit"];
                if (isPlayer _unit) then {
                    _vehicle setVariable ["ALiVE_advciv_wasUsedByPlayer", true, true];
                };
            }];
        };
    }, true] call CBA_fnc_addClassEventHandler;

    // Initialize existing units
    { [_x] call ALiVE_fnc_advciv_initUnit; } forEach allUnits;

    // Auto-initialize new units
    ["CAManBase", "initPost", {
        params ["_unit"];
        [{ [_this select 0] call ALiVE_fnc_advciv_initUnit; }, [_unit], 1] call CBA_fnc_waitAndExecute;
    }, true] call CBA_fnc_addClassEventHandler;

    ["LandVehicle", "initPost", {
        params ["_veh"];
        [{
            { if (alive _x && {!isPlayer _x} && {side _x != civilian}) then { [_x] call ALiVE_fnc_advciv_initUnit; }; } forEach crew (_this select 0);
        }, [_veh], 2] call CBA_fnc_waitAndExecute;
    }, true] call CBA_fnc_addClassEventHandler;

    // Main brain tick loop
    [{
        params ["_args", "_handle"];
        if (!ALiVE_advciv_enabled) exitWith {};

        ALiVE_advciv_activeUnits = ALiVE_advciv_activeUnits select {
            !isNull _x && {alive _x} && {!isPlayer _x} && {_x getVariable ["ALiVE_advciv_active", false]}
        };

        private _units = +ALiVE_advciv_activeUnits;
        private _batchSize = ALiVE_advciv_batchSize;

        if (_batchSize > 0 && {count _units > _batchSize}) then {
            private _offset = missionNamespace getVariable ["ALiVE_advciv_batchOffset", 0];
            _units = _units select [_offset, _batchSize];
            missionNamespace setVariable ["ALiVE_advciv_batchOffset", (_offset + _batchSize) mod (count ALiVE_advciv_activeUnits)];
        };

        { [_x] call ALiVE_fnc_advciv_brainTick; } forEach _units;
    }, ALiVE_advciv_tickRate, []] call CBA_fnc_addPerFrameHandler;

    // Initialize player fired event handlers
    {
        if (isPlayer _x && {side _x != civilian} && {!(_x getVariable ["ALiVE_advciv_firedEH", false])}) then {
            [_x] call ALiVE_fnc_advciv_initUnit;
        };
    } forEach allPlayers;

    addMissionEventHandler ["PlayerConnected", {
        [{
            {
                if (isPlayer _x && {side _x != civilian} && {!(_x getVariable ["ALiVE_advciv_firedEH", false])}) then {
                    [_x] call ALiVE_fnc_advciv_initUnit;
                };
            } forEach allPlayers;
        }, [], 3] call CBA_fnc_waitAndExecute;
    }];

    // Catch-all initialization loop for late-spawning units
    [{
        if (!ALiVE_advciv_enabled) exitWith {};
        {
            if (alive _x && {!isPlayer _x}) then {
                if (side _x == civilian) then {
                    if (!(_x getVariable ["ALiVE_advciv_active", false])) then {
                        [_x] call ALiVE_fnc_advciv_initUnit;
                    };
                } else {
                    if (!(_x getVariable ["ALiVE_advciv_firedEH", false])) then {
                        [_x] call ALiVE_fnc_advciv_initUnit;
                    };
                };
            };
        } forEach allUnits;
    }, 15, []] call CBA_fnc_addPerFrameHandler;

    ["ALiVE Advanced Civilians - Server postInit complete."] call ALIVE_fnc_dump;
};

// ==============================================
//  CLIENT INITIALIZATION
// ==============================================
if (hasInterface) then {
    // Globals are already guaranteed by the waitUntil at the top of this file.
    // Additionally wait for the utility functions to arrive, since publicVariable
    // for code blocks may land slightly after the scalar globals on a loaded server.
    waitUntil { !isNil "ALiVE_fnc_advciv_isValidCiv" };

    // Add order menus to existing civilians
    {
        if ([_x] call ALiVE_fnc_advciv_isValidCiv) then {
            [_x] call ALiVE_fnc_advciv_orderMenu;
        };
    } forEach allUnits;

    // Auto-add order menus to new civilians
    ["CAManBase", "initPost", {
        params ["_unit"];
        [{
            if ([_this select 0] call ALiVE_fnc_advciv_isValidCiv) then {
                [_this select 0] call ALiVE_fnc_advciv_orderMenu;
            };
        }, [_unit], 1.5] call CBA_fnc_waitAndExecute;
    }, true] call CBA_fnc_addClassEventHandler;

    // Debug 3D labels
    if (ALiVE_advciv_debug) then {
        addMissionEventHandler ["Draw3D", {
            if (!ALiVE_advciv_debug) exitWith {};

            private _playerPos = getPosATL player;
            private _cameraPos = positionCameraToWorld [0,0,0];
            private _checkPos = if (_playerPos distance _cameraPos < 10) then {_playerPos} else {_cameraPos};

            {
                if (alive _x && {side _x == civilian} && {!isPlayer _x} && {_x getVariable ["ALiVE_advciv_active", false]}) then {
                    private _distCheck = (_x distance player < 100) || {_x distance _cameraPos < 100};
                    if (_distCheck) then {
                        private _label = _x getVariable ["ALiVE_advciv_dbgState", ""];
                        if (_label != "") then {
                            private _state = _x getVariable ["ALiVE_advciv_state", "CALM"];
                            private _color = switch (_state) do {
                                case "CALM":     { [0,1,0,0.8] };
                                case "ALERT":    { [1,1,0,0.8] };
                                case "PANIC":    { [1,0.5,0,0.8] };
                                case "HIDING":   { [0.5,0,1,0.8] };
                                case "HIT_REACT":{ [1,0,0,0.8] };
                                case "ORDERED":  { [0,0.5,1,0.8] };
                                default          { [1,1,1,0.8] };
                            };
                            drawIcon3D ["", _color, ASLToAGL (getPosASL _x) vectorAdd [0,0,2.2], 0, 0, 0, _label, 2, 0.04, "PuristaMedium"];
                        };
                    };
                };
            } forEach (_checkPos nearEntities [["CAManBase"], 150]);
        }];
    };

    // Debug console helper function
    ALiVE_fnc_advciv_debugInfo = {
        params [["_unit", objNull]];

        if (isNull _unit) then {
            private _allCivs = allUnits select {side _x == civilian && !isPlayer _x};
            private _advCivs = _allCivs select {_x getVariable ["ALiVE_advciv_active", false]};

            systemChat "=== AdvCiv System Info ===";
            systemChat format ["Total civilians: %1", count _allCivs];
            systemChat format ["AdvCiv active: %1", count _advCivs];
            systemChat format ["ActiveUnits array: %1", count ALiVE_advciv_activeUnits];
            systemChat format ["Settings: Debug=%1, TickRate=%2s, Range=%3m",
                ALiVE_advciv_debug, ALiVE_advciv_tickRate, ALiVE_advciv_orderMenuRange];

            private _calm     = _advCivs select {(_x getVariable ["ALiVE_advciv_state", ""]) == "CALM"};
            private _alert    = _advCivs select {(_x getVariable ["ALiVE_advciv_state", ""]) == "ALERT"};
            private _panic    = _advCivs select {(_x getVariable ["ALiVE_advciv_state", ""]) == "PANIC"};
            private _hiding   = _advCivs select {(_x getVariable ["ALiVE_advciv_state", ""]) == "HIDING"};
            private _hitReact = _advCivs select {(_x getVariable ["ALiVE_advciv_state", ""]) == "HIT_REACT"};
            private _ordered  = _advCivs select {(_x getVariable ["ALiVE_advciv_state", ""]) == "ORDERED"};

            systemChat format ["CALM=%1, ALERT=%2, PANIC=%3, HIDING=%4, HIT_REACT=%5, ORDERED=%6",
                count _calm, count _alert, count _panic, count _hiding, count _hitReact, count _ordered];
            systemChat "======================";
        } else {
            systemChat "=== AdvCiv Unit Info ===";
            systemChat format ["Unit: %1", _unit];
            systemChat format ["Active: %1", _unit getVariable ["ALiVE_advciv_active", false]];
            systemChat format ["State: %1", _unit getVariable ["ALiVE_advciv_state", "undefined"]];
            systemChat format ["Order: %1", _unit getVariable ["ALiVE_advciv_order", "NONE"]];
            systemChat format ["NearShots: %1", _unit getVariable ["ALiVE_advciv_nearShots", 0]];
            systemChat format ["HomePos: %1", _unit getVariable ["ALiVE_advciv_homePos", []]];
            systemChat format ["PanicSource: %1", _unit getVariable ["ALiVE_advciv_panicSource", [0,0,0]]];
            systemChat format ["In activeUnits: %1", _unit in ALiVE_advciv_activeUnits];
            systemChat "======================";
        };
    };

    systemChat "[AdvCiv] Debug helper loaded. Use: call ALiVE_fnc_advciv_debugInfo";
};
