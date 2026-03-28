
params [["_unit", objNull, [objNull]]];

if (isNull _unit || {!alive _unit} || {isPlayer _unit}) exitWith {};
if (!(_unit getVariable ["ALiVE_advciv_active", false])) exitWith {};


if (side _unit != civilian) exitWith {
    _unit setVariable ["ALiVE_advciv_active", false, true];
    ALiVE_advciv_activeUnits = ALiVE_advciv_activeUnits - [_unit];
};


if (_unit getVariable ["ALiVE_advciv_boarding", false]) exitWith {};
if (_unit getVariable ["ALiVE_advciv_vehicleEscaping", false]) exitWith {};

private _state    = _unit getVariable ["ALiVE_advciv_state", "CALM"];
private _homePos  = _unit getVariable ["ALiVE_advciv_homePos", getPos _unit];
private _timer    = _unit getVariable ["ALiVE_advciv_stateTimer", 0];
private _order    = _unit getVariable ["ALiVE_advciv_order", "NONE"];

private _prevState    = _unit getVariable ["ALiVE_advciv_prevState", ""];
private _stateChanged = (_state != _prevState);
if (_stateChanged) then {
    _unit setVariable ["ALiVE_advciv_prevState", _state, true];
};

if (ALiVE_advciv_debug) then {
    private _nearShots = _unit getVariable ["ALiVE_advciv_nearShots", 0];
    private _label = if (_order != "NONE") then {
        format ["%1 [%2] | Shots:%3", _state, _order, floor _nearShots]
    } else { 
        format ["%1 | Shots:%2", _state, floor _nearShots]
    };
    _unit setVariable ["ALiVE_advciv_dbgState", _label, true];
};

if (_state == "ORDERED") exitWith {
    switch (_order) do {

        case "FOLLOW": {
            private _target = _unit getVariable ["ALiVE_advciv_orderTarget", objNull];
            if (!isNull _target && {alive _target}) then {
                // If they're in the player's group, let group AI handle following
                if (group _unit == group _target) exitWith {};
                
                // Fallback: if not in group, use manual waypoints
                if (vehicle _unit != _unit) exitWith {};
                private _dist = _unit distance _target;
                if (_dist > 5) then {
                    _unit doMove (getPos _target);
                    _unit setSpeedMode (if (_dist > 20) then {"FULL"} else {"NORMAL"});
                } else {
                    doStop _unit;
                };
            } else {
                _unit setVariable ["ALiVE_advciv_order", "NONE", true];
                _unit setVariable ["ALiVE_advciv_state", "CALM", true];
            };
        };

        case "STAY": {
            if (_stateChanged) then { doStop _unit; };
        };

        case "GOHOME": {
            if (vehicle _unit != _unit) exitWith {};
            if (_unit distance _homePos < 5) then {
                _unit setVariable ["ALiVE_advciv_order", "NONE", true];
                _unit setVariable ["ALiVE_advciv_state", "CALM", true];
                doStop _unit;
            } else {
                if (_stateChanged) then { _unit doMove _homePos; };
            };
        };

        case "HANDSUP": {
            if (_stateChanged) then {
                doStop _unit;
                _unit disableAI "PATH";
            };
        };

        case "GETDOWN": {
            if (_stateChanged) then {
                doStop _unit;
                _unit disableAI "PATH";
                if (vehicle _unit == _unit) then { _unit setUnitPos "DOWN"; };
            };
        };

        case "KNEEL": {
            if (_stateChanged) then {
                doStop _unit;
                _unit disableAI "PATH";
                if (vehicle _unit == _unit) then { _unit setUnitPos "MIDDLE"; };
            };
        };

        case "GETIN": {
            private _veh = _unit getVariable ["ALiVE_advciv_orderVehicle", objNull];

            if (isNull _veh || {!alive _veh} || {!canMove _veh}) exitWith {
                _unit setVariable ["ALiVE_advciv_order", "NONE", true];
                _unit setVariable ["ALiVE_advciv_state", "CALM", true];
                _unit setVariable ["ALiVE_advciv_boarding", false, true];
            };

            if ([_veh] call ALiVE_fnc_advciv_isVehicleProtected) exitWith {
                _unit setVariable ["ALiVE_advciv_order", "NONE", true];
                _unit setVariable ["ALiVE_advciv_state", "CALM", true];
                _unit setVariable ["ALiVE_advciv_boarding", false, true];
            };

            if (vehicle _unit == _veh) exitWith {};
            if (vehicle _unit != _unit) exitWith {};

            private _dist = _unit distance _veh;
            private _isBoarding = _unit getVariable ["ALiVE_advciv_boarding", false];

            if (_dist < 8 && {!_isBoarding}) then {
                _unit setVariable ["ALiVE_advciv_boarding", true, true];

                if (isNull driver _veh) then {
                    _unit assignAsDriver _veh;
                } else {
                    if (_veh emptyPositions "cargo" > 0) then {
                        _unit assignAsCargo _veh;
                    } else {
                        _unit setVariable ["ALiVE_advciv_order", "NONE", true];
                        _unit setVariable ["ALiVE_advciv_state", "CALM", true];
                        _unit setVariable ["ALiVE_advciv_boarding", false, true];
                    };
                };

                if (_unit getVariable ["ALiVE_advciv_order", "NONE"] == "GETIN") then {
                    [_unit] orderGetIn true;

                    [_unit, _veh] spawn {
                        params ["_u", "_v"];
                        private _timeout = time + 15;
                        waitUntil { sleep 0.5; !alive _u || vehicle _u == _v || time > _timeout };

                        if (alive _u && {vehicle _u != _v} && {_u distance _v < 12}) then {
                            if (isNull driver _v) then {
                                [_u, _v] remoteExecCall ["moveInDriver", 0];
                            } else {
                                if (_v emptyPositions "cargo" > 0) then {
                                    [_u, _v] remoteExecCall ["moveInCargo", 0];
                                };
                            };
                        };

                        sleep 0.5;
                        if (alive _u) then {
                            _u setVariable ["ALiVE_advciv_boarding", false, true];
                        };
                    };
                };

            } else {
                if (!_isBoarding) then {
                    _unit doMove (getPos _veh);
                    _unit setSpeedMode "FULL";
                };
            };
        };
    };
};


switch (_state) do {
    case "CALM": {
        if (_stateChanged) then {
            _unit setBehaviour "CARELESS";
            _unit setSpeedMode "LIMITED";
            if (vehicle _unit == _unit) then { _unit setUnitPos "UP"; };
            _unit enableAI "PATH";
            // FIX #1: сброс vehicleEscapeTried при КАЖДОМ входе в CALM
            _unit setVariable ["ALiVE_advciv_vehicleEscapeTried", false];
            _unit setVariable ["ALiVE_advciv_nearShots", 0];
            _unit setVariable ["ALiVE_advciv_panicRunStart", 0];
            _unit setVariable ["ALiVE_advciv_hidingBuilding", objNull, true];
        };
        if (vehicle _unit == _unit) then {
            [_unit] call ALiVE_fnc_advciv_ambientLife;
        };
    };
    case "ALERT": {
        if (_stateChanged) then {
            _unit setBehaviour "AWARE";
            _unit setSpeedMode "LIMITED";
            if (vehicle _unit == _unit) then { _unit setUnitPos "UP"; };
            _unit setVariable ["ALiVE_advciv_stateTimer", time + 8 + random 12];
            // FIX #1: сброс при каждом ALERT
            _unit setVariable ["ALiVE_advciv_vehicleEscapeTried", false];
            private _source = _unit getVariable ["ALiVE_advciv_panicSource", [0,0,0]];
            if !(_source isEqualTo [0,0,0]) then { _unit doWatch _source; };
        };

        private _alertTimer = _unit getVariable ["ALiVE_advciv_stateTimer", 0];
        if (_alertTimer > 0 && {time > _alertTimer}) then {
            private _lastShot = _unit getVariable ["ALiVE_advciv_lastShotTime", 0];
            private _shots    = _unit getVariable ["ALiVE_advciv_nearShots", 0];

            private _realThreat = false;
            if ((time - _lastShot) < ALiVE_advciv_shotMemoryTime && {_shots > 5}) then {
                private _hostiles = _unit nearEntities ["CAManBase", ALiVE_advciv_reactionRadius];
                _hostiles = _hostiles select {
                    alive _x
                    && {side _x != civilian}
                    && {side _x != sideLogic}
                    && {(_x getVariable ["ALiVE_advciv_firedAtCiv", false]) || {rating _x < -500}}
                };
                _realThreat = (count _hostiles > 0);
            };

            if (_realThreat) then {
                _unit setVariable ["ALiVE_advciv_state", "PANIC", true];
                _unit setVariable ["ALiVE_advciv_stateTimer", 0];
                _unit setVariable ["ALiVE_advciv_hidingPos", [], true];
            } else {
                _unit setVariable ["ALiVE_advciv_state", "CALM", true];
                _unit setVariable ["ALiVE_advciv_stateTimer", 0];
                _unit setVariable ["ALiVE_advciv_nearShots", 0];
                _unit doWatch objNull;
            };
        };
    };
    case "PANIC": {
        if (!alive _unit) exitWith {};

        private _inVehicle = (vehicle _unit != _unit);

        if (_stateChanged) then {
            _unit setBehaviour "AWARE";
            _unit setSpeedMode "FULL";
            if (!_inVehicle) then { _unit setUnitPos "UP"; };
            _unit enableAI "PATH";
            _unit setVariable ["ALiVE_advciv_panicRunStart", 0];
            _unit setVariable ["ALiVE_advciv_hidingBuilding", objNull, true];
        };
        if (_inVehicle) exitWith {
            private _veh = vehicle _unit;
            if (driver _veh == _unit) exitWith {};
            if (_order == "GETIN") exitWith {};

            doGetOut _unit;
            [{
                params ["_u"];
                !alive _u || vehicle _u == _u
            }, {
                params ["_u"];
                if (alive _u) then {
                    _u setVariable ["ALiVE_advciv_state", "PANIC", true];
                    _u setVariable ["ALiVE_advciv_hidingPos", [], true];
                };
            }, [_unit], 10] call CBA_fnc_waitUntilAndExecute;
        };
        private _triedVeh = _unit getVariable ["ALiVE_advciv_vehicleEscapeTried", false];
        if (!_triedVeh && {ALiVE_advciv_vehicleEscape}) then {

            _unit setVariable ["ALiVE_advciv_vehicleEscapeTried", true];

            if (random 1 < ALiVE_advciv_vehicleEscapeChance) then {
                private _vehicles = nearestObjects [_unit, ["Car","Truck","Motorcycle"], 80];
                _vehicles = _vehicles select {
                    alive _x
                    && {canMove _x}
                    && {locked _x < 2}
                    && {isNull driver _x}
                    && {speed _x < 1}
                    && {fuel _x > 0}
                    && {!([_x] call ALiVE_fnc_advciv_isVehicleProtected)}
                };

                if (count _vehicles > 0) then {
                    _vehicles = [_vehicles, [], { _unit distance _x }, "ASCEND"] call BIS_fnc_sortBy;
                    private _veh = _vehicles select 0;

                    _unit setVariable ["ALiVE_advciv_vehicleEscaping", true, true];
                    _unit setVariable ["ALiVE_advciv_boarding", true, true];
                    _unit doMove (getPos _veh);
                    _unit setSpeedMode "FULL";
                    _unit forceSpeed -1;

                    [_unit, _veh] spawn {
                        params ["_u", "_v"];
                        private _timeout = time + 25;
                        waitUntil { sleep 0.5; !alive _u || _u distance _v < 6 || time > _timeout };

                        if (!alive _u || time > _timeout) exitWith {
                            if (alive _u) then {
                                _u setVariable ["ALiVE_advciv_vehicleEscaping", false, true];
                                _u setVariable ["ALiVE_advciv_boarding", false, true];
                            };
                        };
                        if (isNull driver _v && {alive _v} && {canMove _v}) then {
                            _u assignAsDriver _v;
                            [_u] orderGetIn true;

                            private _boardTimeout = time + 12;
                            waitUntil { sleep 0.5; !alive _u || vehicle _u == _v || time > _boardTimeout };

                            if (alive _u && {vehicle _u != _v} && {_u distance _v < 15} && {isNull driver _v}) then {
                                _u moveInDriver _v;
                            };
                        };

                        _u setVariable ["ALiVE_advciv_boarding", false, true];
                        if (!alive _u || vehicle _u != _v) exitWith {
                            if (alive _u) then {
                                _u setVariable ["ALiVE_advciv_vehicleEscaping", false, true];
                            };
                        };

                        sleep 1;
                        private _escapeStartPos = getPos _u;

                        private _source = _u getVariable ["ALiVE_advciv_panicSource", [0,0,0]];
                        private _escapeDir = if !(_source isEqualTo [0,0,0]) then {
                            (_source getDir _escapeStartPos) + (-30 + random 60)
                        } else { random 360 };
                        private _escapePos = _escapeStartPos getPos [500 + random 300, _escapeDir];

                        private _grp = group _u;
                        while {count waypoints _grp > 0} do { deleteWaypoint [_grp, 0]; };
                        private _wp = _grp addWaypoint [_escapePos, 0];
                        _wp setWaypointType "MOVE";
                        _wp setWaypointSpeed "FULL";
                        _wp setWaypointBehaviour "CARELESS";
                        _wp setWaypointCompletionRadius 50;

                        private _driveStart   = time;
                        private _lastDrivePos = getPos _u;
                        private _stuckCount   = 0;
                        private _minDriveTime = 15;

                        waitUntil {
                            sleep 3;
                            if (!alive _u || vehicle _u != _v) exitWith { true };
                            if (!canMove _v || fuel _v <= 0) exitWith { true };

                            private _elapsed = time - _driveStart;

                            if (_u distance _lastDrivePos < 3) then {
                                _stuckCount = _stuckCount + 1;
                            } else {
                                _stuckCount = 0;
                                _lastDrivePos = getPos _u;
                            };
                            if (_stuckCount > 6) exitWith { true };
                            if (_elapsed > 90) exitWith { true };
                            if (_elapsed > _minDriveTime) then {
                                if (_u distance _escapeStartPos > 400) exitWith { true };
                            };

                            false
                        };

                        if (alive _u) then {
                            if (vehicle _u == _v) then {
                                doGetOut _u;
                                sleep 5;
                            };

                            private _grp2 = group _u;
                            while {count waypoints _grp2 > 0} do { deleteWaypoint [_grp2, 0]; };

                            _u setVariable ["ALiVE_advciv_vehicleEscaping", false, true];
                            _u setVariable ["ALiVE_advciv_boarding", false, true];
                            _u setVariable ["ALiVE_advciv_hidingPos", [], true];
                            _u setVariable ["ALiVE_advciv_panicRunStart", 0];
                            _u setVariable ["ALiVE_advciv_homePos", getPos _u, true];
                            _u setVariable ["ALiVE_advciv_state", "CALM", true];
                        };
                    };
                };
            };
        };

        private _hidingPos = _unit getVariable ["ALiVE_advciv_hidingPos", []];

        if (_hidingPos isEqualTo []) then {

            private _fnc_fleeOpen = {
                params ["_u"];
                private _source = _u getVariable ["ALiVE_advciv_panicSource", [0,0,0]];
                private _dir = if !(_source isEqualTo [0,0,0]) then {
                    _source getDir (getPos _u)
                } else { random 360 };
                private _fleeDist = (ALiVE_advciv_fleeRadius * 0.5) + random (ALiVE_advciv_fleeRadius * 0.5);
                private _fleePos = (getPos _u) getPos [_fleeDist, _dir + (-30 + random 60)];
                _u doMove _fleePos;
                _u forceSpeed -1;
                [_u, "GUNFIRE"] call ALiVE_fnc_advciv_react;

                [{
                    params ["_u2"];
                    if (alive _u2 && {_u2 getVariable ["ALiVE_advciv_state", "CALM"] == "PANIC"}) then {
                        if (vehicle _u2 == _u2) then { _u2 setUnitPos "DOWN"; };
                        _u2 setVariable ["ALiVE_advciv_state", "HIDING", true];
                        _u2 setVariable ["ALiVE_advciv_stateTimer", time + ALiVE_advciv_hideTimeMin + random (ALiVE_advciv_hideTimeMax - ALiVE_advciv_hideTimeMin)];
                    };
                }, [_u], 25] call CBA_fnc_waitAndExecute;
            };

            if (ALiVE_advciv_preferBuildings) then {
                private _houseData = [_unit] call ALiVE_fnc_advciv_findHouse;
                private _building  = _houseData select 0;
                private _positions = _houseData select 1;

                if (!isNull _building && {count _positions > 0}) then {
                    private _targetPos = selectRandom _positions;
                    _unit setVariable ["ALiVE_advciv_hidingPos", _targetPos, true];
                    _unit setVariable ["ALiVE_advciv_hidingBuilding", _building, true];
                    _unit doMove _targetPos;
                    _unit setSpeedMode "FULL";
                    _unit forceSpeed -1;
                    [_unit, "GUNFIRE"] call ALiVE_fnc_advciv_react;
                } else {
                    [_unit] call _fnc_fleeOpen;
                };
            } else {
                [_unit] call _fnc_fleeOpen;
            };

        } else {
            private _dist = 999;
            if (typeName _hidingPos == "ARRAY" && {count _hidingPos >= 2}) then {
                _dist = _unit distance _hidingPos;
            };

            if (_dist < 3) then {
                _unit setVariable ["ALiVE_advciv_state", "HIDING", true];
                _unit setVariable ["ALiVE_advciv_hidingPos", [], true];
                _unit setVariable ["ALiVE_advciv_stateTimer", time + ALiVE_advciv_hideTimeMin + random (ALiVE_advciv_hideTimeMax - ALiVE_advciv_hideTimeMin)];
            } else {
                if (_dist < 999 && {speed _unit < 1}) then {
                    _unit doMove _hidingPos;
                    _unit setSpeedMode "FULL";
                    _unit forceSpeed -1;
                };

                if (_unit getVariable ["ALiVE_advciv_panicRunStart", 0] == 0) then {
                    _unit setVariable ["ALiVE_advciv_panicRunStart", time];
                };

                if (time - (_unit getVariable ["ALiVE_advciv_panicRunStart", time]) > 30) then {
                    _unit setVariable ["ALiVE_advciv_hidingPos", [], true];
                    _unit setVariable ["ALiVE_advciv_panicRunStart", 0];
                    _unit setVariable ["ALiVE_advciv_hidingBuilding", objNull, true];
                    if (vehicle _unit == _unit) then { _unit setUnitPos "DOWN"; };
                    _unit setVariable ["ALiVE_advciv_state", "HIDING", true];
                    _unit setVariable ["ALiVE_advciv_stateTimer", time + 60 + random 60];
                };
            };
        };
    };

    case "HIT_REACT": {
        if (time - (_unit getVariable ["ALiVE_advciv_hitReactStart", time]) > 20) then {
            _unit setVariable ["ALiVE_advciv_state", "PANIC", true];
            _unit setVariable ["ALiVE_advciv_hitReacting", false, true];
            _unit setVariable ["ALiVE_advciv_hitReactStart", 0];
            _unit setVariable ["ALiVE_advciv_hidingPos", [], true];
            _unit enableAI "PATH";
        };
    };

    case "HIDING": {
        if (_stateChanged) then {
            _unit disableAI "PATH";
            _unit setBehaviour "AWARE";
            _unit setSpeedMode "LIMITED";
        };

        if (vehicle _unit == _unit) then {
            [_unit, "HIDING"] call ALiVE_fnc_advciv_react;
        };

        if (_timer > 0 && {time > _timer}) then {
            private _lastShot = _unit getVariable ["ALiVE_advciv_lastShotTime", 0];

            private _hostileNear = {
                alive _x
                && {side _x != civilian}
                && {side _x != sideLogic}
                && {(_x getVariable ["ALiVE_advciv_firedAtCiv", false]) || {rating _x < -500}}
            } count (_unit nearEntities ["CAManBase", ALiVE_advciv_reactionRadius]);

            if (_hostileNear > 0 && {(time - _lastShot) < ALiVE_advciv_shotMemoryTime}) then {
                _unit setVariable ["ALiVE_advciv_stateTimer", time + ALiVE_advciv_hideTimeMin + random (ALiVE_advciv_hideTimeMax - ALiVE_advciv_hideTimeMin)];
            } else {
                _unit setVariable ["ALiVE_advciv_state", "ALERT", true];
                _unit setVariable ["ALiVE_advciv_stateTimer", 0];
                _unit setVariable ["ALiVE_advciv_nearShots", 0];
                _unit enableAI "PATH";
                if (vehicle _unit == _unit) then { _unit setUnitPos "UP"; };
                _unit doWatch objNull;

                private _hidingBld = _unit getVariable ["ALiVE_advciv_hidingBuilding", objNull];
                _unit setVariable ["ALiVE_advciv_hidingBuilding", objNull, true];

                if (_unit distance _homePos > 30 && {vehicle _unit == _unit}) then {
                    if (!isNull _hidingBld) then {
                        private _unitZ = (getPosATL _unit) select 2;
                        private _bldZ  = (getPosATL _hidingBld) select 2;

                        if ((_unitZ - _bldZ) > 3.5) then {
                            private _groundPos = [_hidingBld, 3.5, _unit] call ALiVE_fnc_advciv_getSafePositions;
                            if (count _groundPos > 0) then {
                                _unit doMove (selectRandom _groundPos);
                                [{
                                    params ["_u", "_hp"];
                                    if (alive _u && {vehicle _u == _u}) then {
                                        _u doMove _hp;
                                    };
                                }, [_unit, _homePos], 15] call CBA_fnc_waitAndExecute;
                            } else {
                                _unit doMove (getPos _hidingBld);
                                [{
                                    params ["_u", "_hp"];
                                    if (alive _u && {vehicle _u == _u}) then {
                                        _u doMove _hp;
                                    };
                                }, [_unit, _homePos], 15] call CBA_fnc_waitAndExecute;
                            };
                        } else {
                            _unit doMove _homePos;
                        };
                    } else {
                        _unit doMove _homePos;
                    };
                };
            };
        };
    };
};

if (_order == "NONE" && {_state in ["CALM", "ALERT"]}) then {
    if (vehicle _unit == _unit && {_unit distance _homePos > ALiVE_advciv_homeRadius}) then {
        _unit doMove _homePos;
    };
};