/* ----------------------------------------------------------------------------
Function: ALIVE_fnc_advciv_getSafePositions
Description:
    Returns a filtered list of safe interior positions within a building,
    suitable for civilian occupation. Filters all building positions by a
    maximum relative height threshold to restrict results to ground-floor or
    low-level positions, then retains only those that are either covered by
    an overhead surface (determined via lineIntersectsSurfaces) or sit below
    1.5 m relative height, ensuring units are genuinely sheltered indoors.
Parameters:
    _this select 0: OBJECT - The building to query
    _this select 1: NUMBER - Maximum relative height above building base (default: 3.5)
    _this select 2: OBJECT - The unit requesting positions (used to exclude self
                             from intersection checks)
Returns:
    ARRAY - Array of AGL positions [x, y, z] that pass the shelter filter,
            or an empty array if the building is null or has no positions
See Also:
    ALIVE_fnc_advciv_findHouse, ALIVE_fnc_advciv_ambientLife
Author:
    Jman (advanced civs)
Peer Reviewed:
    nil
---------------------------------------------------------------------------- */

params [
    ["_building", objNull, [objNull]],
    ["_maxHeight", 3.5, [0]],
    ["_unit", objNull, [objNull]]
];

if (isNull _building) exitWith { [] };

private _allPos = _building buildingPos -1;   // -1 = all interior positions
if (count _allPos == 0) exitWith { [] };

// Use the building's world-space Z as the baseline for relative height calculations
private _bldPosATL = getPosATL _building;
private _bldZ = _bldPosATL select 2;

private _filtered = [];

{
    private _posATL = _x;
    private _relHeight = (_posATL select 2) - _bldZ;

    // Discard positions above the requested height cap (e.g. upper floors)
    if (_relHeight < _maxHeight) then {
        // Cast a ray straight up from just above this position. If a surface is
        // found, the position is covered by a roof/ceiling and is genuinely indoors.
        private _above = [_posATL select 0, _posATL select 1, (_posATL select 2) + 0.5];
        private _high  = [_posATL select 0, _posATL select 1, (_posATL select 2) + 15];

        private _surfaces = lineIntersectsSurfaces [
            AGLToASL _above,
            AGLToASL _high,
            _building,    // Ignore the building geometry itself when casting
            objNull,
            true,
            1,
            "GEOM",
            "NONE"
        ];

        if (count _surfaces > 0) then {
            // Overhead surface confirmed — this is a sheltered interior position
            _filtered pushBack _posATL;
        } else {
            // No overhead surface, but if the position is very low (< 1.5 m relative)
            // it is likely a ground-floor doorway or covered alcove — include it
            if (_relHeight < 1.5) then {
                _filtered pushBack _posATL;
            };
        };
    };
} forEach _allPos;

_filtered
