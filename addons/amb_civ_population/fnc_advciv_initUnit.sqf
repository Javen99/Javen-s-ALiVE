
params [["_unit", objNull, [objNull]]];

if (isNull _unit || {!alive _unit}) exitWith {};

if (isPlayer _unit) exitWith {
    if (side _unit == civilian) exitWith {};
    if (_unit getVariable ["ALiVE_advciv_firedEH", false]) exitWith {};
    _unit setVariable ["ALiVE_advciv_firedEH", true];

    _unit addEventHandler ["FiredMan", {
        params ["_firer", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile"];

        private _lastFired = _firer getVariable ["ALiVE_advciv_lastFiredTime", 0];
        if (time - _lastFired < 0.25) exitWith {};
        _firer setVariable ["ALiVE_advciv_lastFiredTime", time];

        private _veh         = vehicle _firer;
        private _isInVehicle = (_veh != _firer);
        private _pos = if (_isInVehicle) then { getPos _veh } else { getPos _firer };

        private _hasSuppressor = false;
        if (!_isInVehicle && {_weapon != ""}) then {
            private _curWeapon = currentWeapon _firer;
            if (_weapon == _curWeapon) then {
                private _acc = _firer weaponAccessories _weapon;
                if (count _acc > 0) then {
                    private _muzzleItem = _acc select 0;
                    if (typeName _muzzleItem == "STRING" && {_muzzleItem != ""}) then {
                        _hasSuppressor = true;
                    };
                };
            };
        };

        private _isExplosive = false;
        private _ammoConfig = configFile >> "CfgAmmo" >> _ammo;
        if (isClass _ammoConfig) then {
            private _ammoSim = getText (_ammoConfig >> "simulation");
            if (_ammoSim in ["shotShell","shotRocket","shotMissile","shotGrenade","shotMine"]) then {
                _isExplosive = true;
            };
        };

        if (_isExplosive) then {
            if (!isNull _projectile) then {
                private _trackData = [_projectile, _firer, time + 30, getPos _projectile];
                [{
                    params ["_args", "_handle"];
                    _args params ["_proj", "_src", "_timeout", "_lastPos"];
                    if (!isNull _proj) then {
                        _args set [3, getPos _proj];
                    } else {
                        [_lastPos, _src] remoteExecCall ["ALiVE_fnc_advciv_handleExplosion", 2];
                        [_handle] call CBA_fnc_removePerFrameHandler;
                    };
                    if (time > _timeout) then {
                        [_handle] call CBA_fnc_removePerFrameHandler;
                    };
                }, 0.1, _trackData] call CBA_fnc_addPerFrameHandler;
            };
        } else {
            [_pos, _firer, _hasSuppressor] remoteExecCall ["ALiVE_fnc_advciv_handleFired", 2];
        };
    }];
};

if (side _unit != civilian) exitWith {
    if (_unit getVariable ["ALiVE_advciv_firedEH", false]) exitWith {};
    _unit setVariable ["ALiVE_advciv_firedEH", true];

    _unit addEventHandler ["FiredMan", {
        params ["_firer", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile"];

        private _lastFired = _firer getVariable ["ALiVE_advciv_lastFiredTime", 0];
        if (time - _lastFired < 0.25) exitWith {};
        _firer setVariable ["ALiVE_advciv_lastFiredTime", time];

        private _veh         = vehicle _firer;
        private _isInVehicle = (_veh != _firer);
        private _pos = if (_isInVehicle) then { getPos _veh } else { getPos _firer };

        private _hasSuppressor = false;
        if (!_isInVehicle && {_weapon != ""}) then {
            private _curWeapon = currentWeapon _firer;
            if (_weapon == _curWeapon) then {
                private _acc = _firer weaponAccessories _weapon;
                if (count _acc > 0) then {
                    private _muzzleItem = _acc select 0;
                    if (typeName _muzzleItem == "STRING" && {_muzzleItem != ""}) then {
                        _hasSuppressor = true;
                    };
                };
            };
        };

        private _isExplosive = false;
        private _ammoConfig = configFile >> "CfgAmmo" >> _ammo;
        if (isClass _ammoConfig) then {
            private _ammoSim = getText (_ammoConfig >> "simulation");
            if (_ammoSim in ["shotShell","shotRocket","shotMissile","shotGrenade","shotMine"]) then {
                _isExplosive = true;
            };
        };

        if (_isExplosive) then {
            if (!isNull _projectile) then {
                private _trackData = [_projectile, _firer, time + 30, getPos _projectile];
                [{
                    params ["_args", "_handle"];
                    _args params ["_proj", "_src", "_timeout", "_lastPos"];
                    if (!isNull _proj) then {
                        _args set [3, getPos _proj];
                    } else {
                        [_lastPos, _src] remoteExecCall ["ALiVE_fnc_advciv_handleExplosion", 2];
                        [_handle] call CBA_fnc_removePerFrameHandler;
                    };
                    if (time > _timeout) then {
                        [_handle] call CBA_fnc_removePerFrameHandler;
                    };
                }, 0.1, _trackData] call CBA_fnc_addPerFrameHandler;
            };
        } else {
            [_pos, _firer, _hasSuppressor] remoteExecCall ["ALiVE_fnc_advciv_handleFired", 2];
        };
    }];
};

if (!isServer) exitWith {};
if (_unit getVariable ["ALiVE_advciv_active", false]) exitWith {};
if ([_unit] call ALiVE_fnc_advciv_isMissionCritical) exitWith {};

_unit setVariable ["ALiVE_advciv_active", true, true];
_unit setVariable ["ALiVE_advciv_state", "CALM", true];
// Add initial debug label
if (ALiVE_advciv_debug) then {
    _unit setVariable ["ALiVE_advciv_dbgState", "CALM", true];
};
_unit setVariable ["ALiVE_advciv_prevState", "", true];
_unit setVariable ["ALiVE_advciv_homePos", getPos _unit, true];
_unit setVariable ["ALiVE_advciv_nearShots", 0];
_unit setVariable ["ALiVE_advciv_stateTimer", 0];
_unit setVariable ["ALiVE_advciv_panicSource", [0,0,0], true];
_unit setVariable ["ALiVE_advciv_hidingPos", [], true];
_unit setVariable ["ALiVE_advciv_hidingBuilding", objNull, true];
_unit setVariable ["ALiVE_advciv_hitReacting", false, true];
_unit setVariable ["ALiVE_advciv_hitReactStart", 0];
_unit setVariable ["ALiVE_advciv_panicRunStart", 0];
_unit setVariable ["ALiVE_advciv_lastAction", time + 20 + random 40];
_unit setVariable ["ALiVE_advciv_actionType", "NONE", true];
_unit setVariable ["ALiVE_advciv_lastVoice", 0];
_unit setVariable ["ALiVE_advciv_vehicleEscaping", false, true];
_unit setVariable ["ALiVE_advciv_vehicleEscapeTried", false];
_unit setVariable ["ALiVE_advciv_order", "NONE", true];
_unit setVariable ["ALiVE_advciv_orderTarget", objNull, true];
_unit setVariable ["ALiVE_advciv_orderVehicle", objNull, true];
_unit setVariable ["ALiVE_advciv_boarding", false, true];
_unit setVariable ["ALiVE_advciv_lastShotTime", 0];

_unit allowFleeing 0;
_unit enableAI "PATH";
_unit setBehaviour "CARELESS";
_unit setSpeedMode "LIMITED";
if (vehicle _unit == _unit) then { _unit setUnitPos "UP"; };


_unit addEventHandler ["Hit", {
    params ["_unit", "_source", "_damage", "_instigator"];

    if (isNull _unit || {!alive _unit}) exitWith {};
    if (isPlayer _unit) exitWith {};
    if (_damage < 0.01) exitWith {};
    if (_unit getVariable ["ALiVE_advciv_hitReacting", false]) exitWith {};

    _unit setVariable ["ALiVE_advciv_order", "NONE", true];
    _unit setVariable ["ALiVE_advciv_lastShotTime", time];

    private _dangerPos = getPos _unit;
    if (!isNull _instigator) then { _dangerPos = getPos _instigator; }
    else { if (!isNull _source) then { _dangerPos = getPos _source; }; };
    _unit setVariable ["ALiVE_advciv_panicSource", _dangerPos, true];

    if (vehicle _unit != _unit) then {
        private _veh = vehicle _unit;

        if (alive _veh && {driver _veh == _unit}) then {
            _unit setVariable ["ALiVE_advciv_vehicleEscaping", true, true];
            _unit setSpeedMode "FULL";
            private _escapeDir = if (!isNull _instigator) then {
                (_dangerPos getDir (getPos _unit)) + (-30 + random 60)
            } else { random 360 };
            private _escapePos = (getPos _unit) getPos [200 + random 150, _escapeDir];
            private _grp = group _unit;
            while {count waypoints _grp > 0} do { deleteWaypoint [_grp, 0]; };
            private _wp = _grp addWaypoint [_escapePos, 0];
            _wp setWaypointType "MOVE";
            _wp setWaypointSpeed "FULL";
            _wp setWaypointBehaviour "CARELESS";

            [{
                params ["_u", "_v"];
                if (alive _u && {vehicle _u == _v}) then {
                    doGetOut _u;
                    [{
                        params ["_u2"];
                        if (alive _u2) then {
                            _u2 setVariable ["ALiVE_advciv_vehicleEscaping", false, true];
                            _u2 setVariable ["ALiVE_advciv_state", "PANIC", true];
                            _u2 setVariable ["ALiVE_advciv_hidingPos", [], true];
                        };
                    }, [_u], 3] call CBA_fnc_waitAndExecute;
                } else {
                    if (alive _u) then {
                        _u setVariable ["ALiVE_advciv_vehicleEscaping", false, true];
                        _u setVariable ["ALiVE_advciv_state", "PANIC", true];
                    };
                };
            }, [_unit, _veh], 8 + random 8] call CBA_fnc_waitAndExecute;

        } else {
            if (alive _veh) then { doGetOut _unit; };

            [{
                params ["_u"];
                if (alive _u && {vehicle _u == _u}) then {
                    _u setVariable ["ALiVE_advciv_state", "HIT_REACT", true];
                    _u setVariable ["ALiVE_advciv_hitReacting", true, true];
                    _u setVariable ["ALiVE_advciv_hitReactStart", time];
                    [_u, "HIT"] call ALiVE_fnc_advciv_react;
                } else {
                    if (alive _u) then { _u setVariable ["ALiVE_advciv_state", "PANIC", true]; };
                };
            }, [_unit], 4] call CBA_fnc_waitAndExecute;
        };

    } else {
        _unit setVariable ["ALiVE_advciv_state", "HIT_REACT", true];
        _unit setVariable ["ALiVE_advciv_hitReacting", true, true];
        _unit setVariable ["ALiVE_advciv_hitReactStart", time];
        [_unit, "HIT"] call ALiVE_fnc_advciv_react;
    };
}];


_unit addEventHandler ["Deleted", {
    params ["_unit"];
    _unit setVariable ["ALiVE_advciv_active", false];
    _unit setVariable ["ALiVE_advciv_brainRunning", false];
    ALiVE_advciv_activeUnits = ALiVE_advciv_activeUnits - [_unit];
    remoteExec ["", format ["ALiVE_advciv_menu%1", netId _unit]];
}];

[_unit] call ALiVE_fnc_advciv_orderMenu;
[_unit] call ALiVE_fnc_advciv_brainLoop;

if (ALiVE_advciv_debug) then {
    ["ALiVE Advanced Civilians - initUnit complete: %1 | in array: %2", _unit, _unit in ALiVE_advciv_activeUnits] call ALIVE_fnc_dump;
};

