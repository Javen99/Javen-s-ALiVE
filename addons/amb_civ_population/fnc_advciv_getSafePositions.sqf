
params [
    ["_building", objNull, [objNull]],
    ["_maxHeight", 3.5, [0]],
    ["_unit", objNull, [objNull]]
];

if (isNull _building) exitWith { [] };

private _allPos = _building buildingPos -1;
if (count _allPos == 0) exitWith { [] };

private _bldPosATL = getPosATL _building;
private _bldZ = _bldPosATL select 2;

private _filtered = [];

{
    private _posATL = _x;
    private _relHeight = (_posATL select 2) - _bldZ;

    if (_relHeight < _maxHeight) then {
        private _above = [_posATL select 0, _posATL select 1, (_posATL select 2) + 0.5];
        private _high  = [_posATL select 0, _posATL select 1, (_posATL select 2) + 15];

        private _surfaces = lineIntersectsSurfaces [
            AGLToASL _above,
            AGLToASL _high,
            _building,
            objNull,
            true,
            1,
            "GEOM",
            "NONE"
        ];
        if (count _surfaces > 0) then {
            _filtered pushBack _posATL;
        } else {
            if (_relHeight < 1.5) then {
                _filtered pushBack _posATL;
            };
        };
    };
} forEach _allPos;

_filtered