
params [["_unit", objNull, [objNull]]];

if (isNull _unit || !alive _unit) exitWith {};
if (isPlayer _unit) exitWith {};
if (vehicle _unit != _unit) exitWith {};

private _lastAction = _unit getVariable ["ALiVE_advciv_lastAction", 0];
private _homePos    = _unit getVariable ["ALiVE_advciv_homePos", getPos _unit];

if (time < _lastAction) exitWith {};


private _isIndoors = false;
private _currentBuilding = objNull;
private _unitFloorZ = (getPosATL _unit) select 2;
{
    if (_unit distance2D _x < 15) then {
        private _above = getPos _unit vectorAdd [0, 0, 0.5];
        private _high  = getPos _unit vectorAdd [0, 0, 15];
        private _surfaces = lineIntersectsSurfaces [
            AGLToASL _above,
            AGLToASL _high,
            _unit,
            objNull,
            true,
            1,
            "GEOM",
            "NONE"
        ];
        if (count _surfaces > 0) then {
            _isIndoors       = true;
            _currentBuilding = _x;
        };
    };
} forEach (nearestObjects [_unit, ["House","Building"], 15]);

private _hour      = daytime;
private _isNight   = (_hour < 6 || _hour > 22);
private _isMorning = (_hour >= 6  && _hour < 10);
private _isDay     = (_hour >= 10 && _hour < 18);
private _isEvening = (_hour >= 18 && _hour <= 22);


if (_isNight) exitWith {
    if (_isIndoors) then {
        doStop _unit;
        _unit setVariable ["ALiVE_advciv_actionType", "SLEEPING", true];
        _unit setVariable ["ALiVE_advciv_lastAction", time + 120];
    } else {
        // FIX #2: doMove сразу к внутренней позиции, без промежуточного шага
        private _houseData = [_unit] call ALiVE_fnc_advciv_findHouse;
        _houseData params [["_building", objNull], ["_positions", []]];
        if (!isNull _building && count _positions > 0) then {
            _unit doMove (selectRandom _positions);
            _unit setVariable ["ALiVE_advciv_actionType", "SLEEPING", true];
            _unit setVariable ["ALiVE_advciv_lastAction", time + 120];
        };
    };
};


private _actions = [];

if (_isIndoors) then {
    // FIX #1: убран EXIT_BUILDING, долгие indoor таймеры
    if (_isMorning) then { _actions = ["STAND_INDOOR","STAND_INDOOR","SIT","WALK_INDOOR"]; };
    if (_isDay)     then { _actions = ["STAND_INDOOR","SIT","SIT","WALK_INDOOR","WALK_INDOOR"]; };
    if (_isEvening) then { _actions = ["STAND_INDOOR","SIT","STAND_INDOOR"]; };
} else {
    if (_isMorning) then { _actions = ["WALK","WALK","STAND","WATCH"]; };
    if (_isDay)     then { _actions = ["WALK","WALK","WALK","STAND","SIT","GATHER","WATCH","WORK"]; };
    if (_isEvening) then { _actions = ["WALK","STAND","GOHOME","GOHOME","GATHER"]; };
};

if (count _actions == 0) then { _actions = ["STAND"]; };

private _action = selectRandom _actions;
_unit setVariable ["ALiVE_advciv_actionType", _action, true];

switch (_action) do {

    case "WALK_INDOOR": {
        if (!isNull _currentBuilding) then {
            private _allSafe = [_currentBuilding, 999, _unit] call ALiVE_fnc_advciv_getSafePositions;
            private _sameFloor = _allSafe select {
                abs ((_x select 2) - _unitFloorZ) < 2
            };
            if (count _sameFloor == 0) then {
                _sameFloor = [_currentBuilding, 3.5, _unit] call ALiVE_fnc_advciv_getSafePositions;
            };

            if (count _sameFloor > 0) then {
                _unit setUnitPos "UP";
                _unit setSpeedMode "LIMITED";
                _unit setBehaviour "CARELESS";
                _unit doMove (selectRandom _sameFloor);
                // FIX #1: длинный таймер внутри зданий
                _unit setVariable ["ALiVE_advciv_lastAction", time + 40 + random 60];
            } else {
                doStop _unit;
                _unit setVariable ["ALiVE_advciv_lastAction", time + 30];
            };
        } else {
            doStop _unit;
            _unit setVariable ["ALiVE_advciv_lastAction", time + 20];
        };
    };

    case "STAND_INDOOR": {
        _unit setUnitPos "UP";
        _unit setSpeedMode "LIMITED";
        doStop _unit;
        private _anim = selectRandom ["Acts_CivilTalking_1", "Acts_StandingSpeakingRU", ""];
        if (_anim != "") then { [_unit, _anim] remoteExec ["playMove", 0]; };
        _unit setVariable ["ALiVE_advciv_lastAction", time + 40 + random 60];
    };

    case "WALK": {
        _unit setUnitPos "UP";
        _unit setSpeedMode "LIMITED";
        _unit setBehaviour "CARELESS";
        private _radius = 20 + random (ALiVE_advciv_homeRadius * 0.6);
        private _target = _homePos getPos [_radius, random 360];
        private _roads = _target nearRoads 30;
        if (count _roads > 0) then { _target = getPos (selectRandom _roads); };
        _unit doMove _target;
        _unit setVariable ["ALiVE_advciv_lastAction", time + 15];
    };

    case "STAND": {
        _unit setUnitPos "UP";
        _unit setSpeedMode "LIMITED";
        doStop _unit;
        _unit doWatch (getPos _unit getPos [50 + random 100, random 360]);
        private _anim = selectRandom ["Acts_CivilTalking_1", "Acts_StandingSpeakingRU", ""];
        if (_anim != "") then { [_unit, _anim] remoteExec ["playMove", 0]; };
        _unit setVariable ["ALiVE_advciv_lastAction", time + 15];
    };

    case "SIT": {
        private _chairTypes = [
            "Land_ChairPlastic_F","Land_ChairWood_F","Land_RattanChair_01_F",
            "Land_CampingChair_V1_F","Land_CampingChair_V2_F","Land_OfficeChair_01_F",
            "Land_ArmChair_01_F","Land_Bench_01_F","Land_Bench_F","Land_BenchIndoor_01_F",
            "Land_Bench_03_F","Land_Bench_04_F","Land_ChairPlastic_V1_F","Land_ChairPlastic_V2_F"
        ];
        private _chairs = nearestObjects [_unit, _chairTypes, 25];

        _chairs = _chairs select {
            abs ((getPosATL _x select 2) - _unitFloorZ) < 2
        };

        if (count _chairs > 0) then {
            private _chair = _chairs select 0;
            _unit doMove (getPos _chair);

            [{
                params ["_u", "_c"];
                !alive _u || _u distance _c < 1.8 || time > (_this select 2)
            }, {
                params ["_u", "_c", "_timeout"];
                if (alive _u && {_u distance _c < 1.8} && {vehicle _u == _u}) then {
                    doStop _u;
                    _u setDir (getDir _c);
                    [_u, "HubSittingChairUA_idle1"] remoteExec ["switchMove", 0];
                    _u setVariable ["ALiVE_advciv_lastAction", time + 60 + random 60];
                };
            }, [_unit, _chair, time + 20]] call CBA_fnc_waitUntilAndExecute;

            _unit setVariable ["ALiVE_advciv_lastAction", time + 25];
        } else {
            doStop _unit;
            _unit setVariable ["ALiVE_advciv_actionType", "STAND", true];
            _unit setVariable ["ALiVE_advciv_lastAction", time + 20];
        };
    };

    case "GATHER": {
        _unit setUnitPos "UP";
        private _nearbyCiv = allUnits select {
            side _x == civilian && alive _x && !isPlayer _x && _x != _unit
            && _x distance _unit < 80 && {vehicle _x == _x}
        };

        if (count _nearbyCiv > 0) then {
            private _target = selectRandom _nearbyCiv;
            _unit doMove ((getPos _target) getPos [2 + random 3, random 360]);

            [{
                params ["_unit"];
                if (alive _unit && {_unit getVariable ["ALiVE_advciv_state", "CALM"] == "CALM"} && {vehicle _unit == _unit}) then {
                    [_unit, "Acts_CivilTalking_2"] remoteExec ["playMove", 0];
                };
            }, [_unit], 10 + random 5] call CBA_fnc_waitAndExecute;
        } else {
            doStop _unit;
        };
        _unit setVariable ["ALiVE_advciv_lastAction", time + 15];
    };

    case "WATCH": {
        _unit setUnitPos "UP";
        private _vehicles = nearestObjects [_unit, ["LandVehicle", "Air"], ALiVE_advciv_curiosityRange];
        _vehicles = _vehicles select {alive _x && speed _x > 5};
        if (count _vehicles > 0) then {
            _unit doWatch (_vehicles select 0);
            _unit setVariable ["ALiVE_advciv_lastAction", time + 8];
        } else {
            _unit setVariable ["ALiVE_advciv_lastAction", time + 15];
        };
    };

    case "WORK": {
        _unit setUnitPos "UP";
        private _buildings = nearestObjects [_unit, ["House"], 50];
        if (count _buildings > 0) then {
            _unit doMove (getPos (selectRandom _buildings) getPos [3, random 360]);
            _unit setVariable ["ALiVE_advciv_lastAction", time + 40];
        } else {
            _unit setVariable ["ALiVE_advciv_lastAction", time + 15];
        };
    };

    case "GOHOME": {
        _unit setUnitPos "UP";
        _unit doMove _homePos;
        _unit setVariable ["ALiVE_advciv_lastAction", time + 15];
    };
};