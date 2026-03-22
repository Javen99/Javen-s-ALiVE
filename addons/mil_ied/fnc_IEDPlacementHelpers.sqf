#include "\x\alive\addons\mil_ied\script_component.hpp"
SCRIPT(iedPlacementHelpers);

/* ----------------------------------------------------------------------------
Function: ALIVE_fnc_IEDPlacementHelpers
Description:
Helper functions for improved IED placement with terrain and tactical validation

Parameters:
String - Function name
Array - Arguments

Returns:
Varies based on function

Functions:
- "validateTerrainSlope" - Check if position is on flat terrain
- "findNearbyRoads" - Get roads within radius
- "validateProximity" - Check minimum distance from other IEDs
- "getValidPlacementPosition" - Find a suitable position for IED placement
- "isPositionValid" - Combined validation check
- "isPositionOutside" - Check if position is outside buildings (not inside)
- "findChokepoints" - Find tactical chokepoints (bridges, narrow roads)
- "getConcealmentScore" - Calculate concealment quality of position

Author:
Jman

---------------------------------------------------------------------------- */

private ["_operation","_args","_result"];

_operation = _this select 0;
_args = if (count _this > 1) then {_this select 1} else {[]};
_result = nil;

switch(_operation) do {
    
    case "validateTerrainSlope": {
        /*
        Check if a position has acceptable terrain slope for IED placement
        Args: [position, maxSlope (optional, default 15)]
        Returns: BOOL - true if slope is acceptable
        */
        private ["_pos","_maxSlope","_terrainNormal","_slopeAngle"];
        
        _pos = _args select 0;
        _maxSlope = if (count _args > 1) then {_args select 1} else {15};
        
        // Get terrain normal at position
        _terrainNormal = surfaceNormal _pos;
        
        // Calculate slope angle in degrees
        // Normal vector [x,y,z] where z component indicates slope
        // For flat terrain, normal is [0,0,1]
        _slopeAngle = acos (_terrainNormal select 2);
        
        _result = (_slopeAngle <= _maxSlope);
        
        if (_result) then {
            // Additional check: ensure not in water
            if (surfaceIsWater _pos) then {
                _result = false;
            };
        };
        
        _result;
    };
    
    case "findNearbyRoads": {
        /*
        Find roads near a position
        Args: [position, radius]
        Returns: ARRAY of road segments
        */
        private ["_pos","_radius","_roads"];
        
        _pos = _args select 0;
        _radius = _args select 1;
        
        _roads = _pos nearRoads _radius;
        
        _result = _roads;
    };
    
    case "validateProximity": {
        /*
        Check if position is at least minimum distance from existing IEDs
        Args: [position, existingIEDPositions, minDistance]
        Returns: BOOL - true if position is valid
        */
        private ["_pos","_existingPositions","_minDist","_tooClose"];
        
        _pos = _args select 0;
        _existingPositions = _args select 1;
        _minDist = _args select 2;
        
        _tooClose = false;
        
        {
            if (_pos distance _x < _minDist) exitWith {
                _tooClose = true;
            };
        } forEach _existingPositions;
        
        _result = !_tooClose;
    };
    
    case "getValidPlacementPosition": {
        /*
        Find a valid position for IED placement within an area
        Prioritizes roads, validates terrain, checks proximity
        Args: [centerPos, radius, existingIEDPositions, preferRoads (bool)]
        Returns: ARRAY position or empty array if no valid position found
        */
        private ["_center","_radius","_existingPos","_preferRoads","_roads","_validPos","_attempts","_foundValid"];
        
        _center = _args select 0;
        _radius = _args select 1;
        _existingPos = if (count _args > 2) then {_args select 2} else {[]};
        _preferRoads = if (count _args > 3) then {_args select 3} else {true};
        
        _validPos = [];
        _foundValid = false;
        _attempts = 0;
        _maxAttempts = 30;
        
        // Get nearby roads if we prefer road placement
        _roads = if (_preferRoads) then {
            [_operation, [_center, _radius]] call ALIVE_fnc_IEDPlacementHelpers;
        } else {
            [];
        };
        
        // Try to place on/near roads first (70% of attempts if roads available)
        if (count _roads > 0 && _preferRoads) then {
            _roadAttempts = round (_maxAttempts * 0.7);
            
            for "_i" from 1 to _roadAttempts do {
                private ["_road","_roadPos","_offset","_testPos"];
                
                _road = selectRandom _roads;
                _roadPos = getPos _road;
                
                // Random offset from road (0-5m to side)
                _offset = [
                    (random 10) - 5,
                    (random 10) - 5,
                    0
                ];
                
                _testPos = _roadPos vectorAdd _offset;
                _testPos set [2, 0]; // Reset Z coordinate
                _testPos = ATLtoASL _testPos;
                
                // Validate this position
                if (
                    ["validateTerrainSlope", [_testPos, 12]] call ALIVE_fnc_IEDPlacementHelpers &&
                    ["validateProximity", [_testPos, _existingPos, 12]] call ALIVE_fnc_IEDPlacementHelpers
                ) then {
                    _validPos = _testPos;
                    _foundValid = true;
                    _attempts = _i;
                    _i = _roadAttempts + 1; // Exit loop
                };
            };
        };
        
        // If no valid road position found, try random positions in area
        if (!_foundValid) then {
            for "_i" from 1 to _maxAttempts do {
                private ["_randomPos","_testPos"];
                
                // Generate random position in circle
                _randomPos = [
                    (_center select 0) + (random (_radius * 2)) - _radius,
                    (_center select 1) + (random (_radius * 2)) - _radius,
                    0
                ];
                
                _testPos = ATLtoASL _randomPos;
                
                // Validate this position
                if (
                    ["validateTerrainSlope", [_testPos, 15]] call ALIVE_fnc_IEDPlacementHelpers &&
                    ["validateProximity", [_testPos, _existingPos, 15]] call ALIVE_fnc_IEDPlacementHelpers &&
                    !(surfaceIsWater _testPos)
                ) then {
                    _validPos = _testPos;
                    _foundValid = true;
                    _i = _maxAttempts + 1; // Exit loop
                };
            };
        };
        
        _result = _validPos;
    };
    
    case "isPositionValid": {
        /*
        Combined validation check for IED placement position
        Args: [position, existingPositions, checkSlope, checkProximity, checkWater]
        Returns: BOOL
        */
        private ["_pos","_existing","_checkSlope","_checkProx","_checkWater","_valid"];
        
        _pos = _args select 0;
        _existing = if (count _args > 1) then {_args select 1} else {[]};
        _checkSlope = if (count _args > 2) then {_args select 2} else {true};
        _checkProx = if (count _args > 3) then {_args select 3} else {true};
        _checkWater = if (count _args > 4) then {_args select 4} else {true};
        
        _valid = true;
        
        // Check water
        if (_checkWater && surfaceIsWater _pos) then {
            _valid = false;
        };
        
        // Check slope
        if (_valid && _checkSlope) then {
            _valid = ["validateTerrainSlope", [_pos, 15]] call ALIVE_fnc_IEDPlacementHelpers;
        };
        
        // Check proximity
        if (_valid && _checkProx && count _existing > 0) then {
            _valid = ["validateProximity", [_pos, _existing, 12]] call ALIVE_fnc_IEDPlacementHelpers;
        };
        
        _result = _valid;
    };
    
    case "getBestPlacementPositions": {
        /*
        Get multiple valid positions for IED placement
        Args: [centerPos, radius, numPositions, existingIEDPositions]
        Returns: ARRAY of positions
        */
        private ["_center","_radius","_numPos","_existing","_positions","_attempts"];
        
        _center = _args select 0;
        _radius = _args select 1;
        _numPos = _args select 2;
        _existing = if (count _args > 3) then {_args select 3} else {[]};
        
        _positions = [];
        _allExisting = +_existing; // Copy array
        
        // Try to get requested number of positions
        for "_i" from 1 to _numPos do {
            private ["_newPos"];
            
            _newPos = ["getValidPlacementPosition", [_center, _radius, _allExisting, true]] call ALIVE_fnc_IEDPlacementHelpers;
            
            if (count _newPos > 0) then {
                _positions pushBack _newPos;
                _allExisting pushBack _newPos; // Add to existing list for next iteration
            };
        };
        
        _result = _positions;
    };
    
    case "isPositionOutside": {
        /*
        Check if position is outside buildings (not inside)
        Uses raycasting to detect if position is under a roof
        Args: [position]
        Returns: BOOL - true if outside, false if inside building
        */
        private ["_pos","_abovePos","_hits","_isOutside"];
        
        _pos = _args select 0;
        _abovePos = [_pos select 0, _pos select 1, (_pos select 2) + 50]; // 50m above position
        
        _isOutside = true;
        
        // Cast ray downward from above position to check for roof
        _hits = lineIntersectsSurfaces [
            AGLtoASL _abovePos,
            AGLtoASL _pos,
            objNull,
            objNull,
            true,
            1,
            "GEOM",
            "NONE"
        ];
        
        // If ray hits building before reaching ground, we're inside
        {
            private ["_hitObject"];
            _hitObject = _x select 2;
            
            // Check if hit object is a building/house
            if (!isNull _hitObject && {_hitObject isKindOf "House" || _hitObject isKindOf "Building"}) exitWith {
                _isOutside = false;
            };
        } forEach _hits;
        
        _result = _isOutside;
    };
    
    case "findChokepoints": {
        /*
        Find tactical chokepoints (bridges, narrow roads, canyon passages)
        Args: [centerPos, radius]
        Returns: ARRAY of [position, score] pairs sorted by tactical value (highest first)
        */
        private ["_center","_radius","_roads","_chokepoints"];
        
        _center = _args select 0;
        _radius = _args select 1;
        _chokepoints = [];
        
        // Get all roads in area
        _roads = _center nearRoads _radius;
        
        {
            private ["_road","_roadPos","_score","_nearRoads","_nearBuildings","_nearBridges","_nearWater","_roadInfo"];
            
            _road = _x;
            _roadPos = getPos _road;
            _score = 0;
            
            // VERY HIGH VALUE: Bridges (road over water)
            _nearBridges = _roadPos nearObjects ["Bridge", 25];
            if (count _nearBridges > 0) then {
                _score = _score + 100; // Maximum tactical value
            };
            
            // HIGH VALUE: Isolated roads (few parallel routes = chokepoint)
            _nearRoads = _roadPos nearRoads 50;
            if (count _nearRoads < 3) then {
                _score = _score + 50; // Only route through area
            } else {
                if (count _nearRoads < 6) then {
                    _score = _score + 25; // Limited alternatives
                };
            };
            
            // MEDIUM VALUE: Urban canyon (buildings on both sides)
            _nearBuildings = _roadPos nearObjects ["House", 30];
            if (count _nearBuildings > 5) then {
                _score = _score + 30; // Confined urban passage
            };
            
            // MEDIUM VALUE: Water nearby (forces traffic to this road)
            _nearWater = nearestObjects [_roadPos, ["#water"], 100];
            if (count _nearWater > 0) then {
                _score = _score + 20; // Natural obstacle forces route
            };
            
            // BONUS: Main road type (higher traffic)
            _roadInfo = getRoadInfo _road;
            if (count _roadInfo > 0) then {
                _roadType = _roadInfo select 0;
                switch (_roadType) do {
                    case "MAIN ROAD": { _score = _score + 15; };
                    case "ROAD": { _score = _score + 10; };
                    case "TRACK": { _score = _score + 5; };
                };
            };
            
            // Only include positions with tactical value
            if (_score > 20) then {
                _chokepoints pushBack [_roadPos, _score];
            };
            
        } forEach _roads;
        
        // Sort by score (highest first)
        _chokepoints sort false;
        
        _result = _chokepoints;
    };
    
    case "getConcealmentScore": {
        /*
        Calculate how well-concealed a position is
        Args: [position]
        Returns: SCALAR 0-100 (higher = better concealed)
        */
        private ["_pos","_score","_nearTrees","_nearBushes","_nearSmallObjects","_nearBuildings","_nearWalls"];
        
        _pos = _args select 0;
        _score = 0;
        
        // Trees provide excellent concealment
        _nearTrees = nearestTerrainObjects [_pos, ["TREE"], 10];
        _score = _score + ((count _nearTrees) * 10);
        
        // Bushes provide good concealment
        _nearBushes = nearestTerrainObjects [_pos, ["BUSH"], 5];
        _score = _score + ((count _nearBushes) * 5);
        
        // Small objects (rubble, containers, tires, garbage)
        _nearSmallObjects = nearestObjects [
            _pos,
            [
                "Land_JunkPile_F",
                "Land_GarbageContainer_closed_F",
                "Land_GarbageBags_F",
                "Land_Tyres_F",
                "Land_GarbagePallet_F",
                "Land_Sacks_heap_F",
                "Land_BarrelTrash_F",
                "Land_Wreck_HMMWV_F",
                "Land_Wreck_Hunter_F"
            ],
            8
        ];
        _score = _score + ((count _nearSmallObjects) * 8);
        
        // Walls and fences
        _nearWalls = nearestObjects [
            _pos,
            [
                "Wall",
                "Fence",
                "Land_Stone_8mD_F",
                "Land_Mil_WiredFenceD_F",
                "Land_Net_FenceD_8m_F"
            ],
            10
        ];
        _score = _score + ((count _nearWalls) * 6);
        
        // Buildings (doorways, corners provide concealment)
        _nearBuildings = _pos nearObjects ["House", 15];
        _score = _score + ((count _nearBuildings) * 8);
        
        // PENALTY: Wide open areas (very exposed)
        if (_score < 10) then {
            _score = _score - 20; // Heavily penalize exposed positions
        };
        
        // Cap score at 100
        _score = _score min 100;
        _score = _score max 0;
        
        _result = _score;
    };
};

_result;
