
params [["_unit", objNull, [objNull]]];

if (isNull _unit) exitWith {[objNull, []]};

private _panicSource   = _unit getVariable ["ALiVE_advciv_panicSource", [0,0,0]];
private _homePos       = _unit getVariable ["ALiVE_advciv_homePos", getPos _unit];
private _buildings     = nearestObjects [_unit, ["House", "Building"], ALiVE_advciv_fleeRadius];
private _bestBuilding  = objNull;
private _bestPositions = [];
private _bestScore     = -999;

{
    private _bld = _x;
    private _positions = [_bld, 3.5, _unit] call ALiVE_fnc_advciv_getSafePositions;

    if (count _positions > 0) then {
        private _distToUnit     = _unit distance _bld;
        private _distFromDanger = 0;
        if !(_panicSource isEqualTo [0,0,0]) then {
            _distFromDanger = _bld distance _panicSource;
        };

        private _score = (100 - _distToUnit)
                       + (_distFromDanger * 0.5)
                       + (count _positions) * 5
                       - ((_bld distance _homePos) * 0.3);

        private _civInside = {
            alive _x && {side _x == civilian} && {!isPlayer _x} && {_x != _unit}
        } count (_bld nearEntities ["CAManBase", 15]);

        _score = _score - (_civInside * 15);

        if (_score > _bestScore) then {
            _bestScore     = _score;
            _bestBuilding  = _bld;
            _bestPositions = _positions;
        };
    };
} forEach _buildings;

[_bestBuilding, _bestPositions]