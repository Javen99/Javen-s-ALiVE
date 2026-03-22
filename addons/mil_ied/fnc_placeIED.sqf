#include "\x\alive\addons\mil_ied\script_component.hpp"
SCRIPT(placeIED);

// Find suitable spot for IED
// Pass location and booleans to look for roads, objects, entrances
// Returns an array of validated positions

/* IMPROVED VERSION v2.0:
   - Validates terrain slope (flat terrain only)
   - Checks proximity between positions
   - Filters out water positions
   - Prioritizes tactical placement locations
   - NEW: Building interior detection (prevents indoor spawns)
   - NEW: Chokepoint detection (bridges, narrow roads get priority)
   - NEW: Concealment scoring (prefers hidden positions)
*/

private ["_addroads","_addobjects","_addentrances","_goodspots","_location","_size"];

_location = _this select 0;
_addroads = _this select 1;
_addobjects = _this select 2;
_addentrances = _this select 3;
_size = _this select 4;

_goodspots = [];
_candidateSpots = []; // Initial candidates before validation

// ============================================================================
// PHASE 1: IDENTIFY CHOKEPOINTS (HIGH-VALUE TARGETS)
// ============================================================================
private ["_chokepoints","_chokepointPositions"];
_chokepoints = [];
_chokepointPositions = [];

if (_addroads) then {
    // Find tactical chokepoints (bridges, narrow roads, etc.)
    _chokepoints = ["findChokepoints", [_location, _size]] call ALIVE_fnc_IEDPlacementHelpers;
    
    // Extract top chokepoint positions and add with VERY high weight
    private ["_maxChokepoints","_count"];
    _maxChokepoints = 10; // Limit to top 10 chokepoints
    _count = (count _chokepoints) min _maxChokepoints;
    
    for "_i" from 0 to (_count - 1) do {
        private ["_chokepointData","_chokepointPos","_score"];
        _chokepointData = _chokepoints select _i;
        _chokepointPos = _chokepointData select 0;
        _score = _chokepointData select 1;
        
        // Store for later reference
        _chokepointPositions pushBack _chokepointPos;
        
        // Add chokepoints with weight based on score
        // High-value chokepoints (score 80+) appear 6x
        // Medium chokepoints (score 50-79) appear 4x
        // Low chokepoints (score 20-49) appear 2x
        private ["_weight"];
        _weight = 2; // Default
        if (_score >= 80) then {
            _weight = 6; // Bridges and critical points
        } else {
            if (_score >= 50) then {
                _weight = 4; // Important routes
            };
        };
        
        // Add position multiple times for weight
        for "_w" from 1 to _weight do {
            _candidateSpots pushBack _chokepointPos;
        };
    };
    
    if (ADDON getVariable ["debug", false]) then {
        diag_log format ["ALIVE-IED placeIED: Found %1 chokepoints, using top %2", count _chokepoints, _count];
    };
};

// ============================================================================
// PHASE 2: GATHER OTHER CANDIDATES
// ============================================================================

// Look for objects
If (_addobjects) then {
    private ["_spottype"];
    // broken fences, low walls, garbage, garbage containers, gates, rubble
    _spottype = ["Land_JunkPile_F","Land_GarbageContainer_closed_F","Land_GarbageBags_F","Land_Tyres_F","Land_GarbagePallet_F","Land_Pallets_F","Land_Ancient_Wall_8m_F","Land_City_8mD_F","Land_City2_8mD_F","Land_Wreck_HMMWV_F","Land_Wreck_Hunter_F","Land_Mil_WallBig_Gate_F","Land_Stone_Gate_F","Land_Mil_WiredFenceD_F","Land_Net_Fence_Gate_F","Land_Stone_8mD_F","Land_Wired_Fence_8mD_F","Land_Wall_IndCnc_4_D_F","Land_Wall_IndCnc_End_2_F","Land_Net_FenceD_8m_F","Land_New_WiredFence_10m_Dam_F"];
    {
        _candidateSpots pushback (getposATL  _x);
    } foreach nearestobjects [_location,_spottype,_size];
};

// Look for building entrances
If (_addentrances) then {
    // Get first building position (entrance) for each building within range
    {
        _candidateSpots pushback (getposATL  _x);
    } foreach (nearestobjects [_location ,["House"],_size]);
};

// Look for roads - Add regular roads (not chokepoints) with standard weight
If (_addroads) then {
    private ["_allRoads"];
    _allRoads = _location nearRoads _size;
    
    {
        private ["_roadPos","_isChokepoint"];
        _roadPos = getposATL _x;
        
        // Check if this road is already a chokepoint
        _isChokepoint = false;
        {
            if (_roadPos distance _x < 15) exitWith {
                _isChokepoint = true;
            };
        } forEach _chokepointPositions;
        
        // If not a chokepoint, add with standard road weight (3x)
        if (!_isChokepoint) then {
            _candidateSpots pushback _roadPos;
            _candidateSpots pushback _roadPos;
            _candidateSpots pushback _roadPos;
        };
        
    } foreach _allRoads;
};

// ============================================================================
// PHASE 3: VALIDATION & SCORING
// ============================================================================
private ["_maxSlope","_minProximity","_minConcealmentScore"];

_maxSlope = 15; // Maximum terrain slope in degrees
_minProximity = 12; // Minimum distance between IEDs in meters

// DYNAMIC CONCEALMENT SCORING - Adapts to terrain type
// Check ALiVE map composition type and set appropriate minimum concealment
private ["_terrainType","_minConcealmentScore"];
_terrainType = missionNamespace getVariable ["ALiVE_mapCompositionType", "Unknown"];

switch (_terrainType) do {
    case "Desert": {
        _minConcealmentScore = 0; // Desert: Very permissive (little natural cover)
    };
    case "Pacific": {
        _minConcealmentScore = 0; // Pacific/Tropical: Permissive (mixed terrain)
    };
    case "Urban": {
        _minConcealmentScore = 5; // Urban: Slightly strict (expect some building/object cover)
    };
    case "Woodland": {
        _minConcealmentScore = 15; // Woodland: Strict (expect vegetation/natural cover)
    };
    default {
        _minConcealmentScore = 0; // Unknown terrain: Permissive (safe default)
        if (ADDON getVariable ["debug", false]) then {
            diag_log format ["ALIVE-IED: Unknown terrain type '%1', using permissive concealment (0)", _terrainType];
        };
    };
};

if (ADDON getVariable ["debug", false]) then {
    diag_log format ["ALIVE-IED: Terrain type '%1', minimum concealment score set to %2", _terrainType, _minConcealmentScore];
};

{
    private ["_pos","_isValid","_terrainNormal","_slopeAngle","_concealmentScore","_isOutside"];
    _pos = _x;
    _isValid = true;
    
    // Check 1: Not in water
    if (surfaceIsWater _pos) then {
        _isValid = false;
        if (ADDON getVariable ["debug", false]) then {
            diag_log format ["ALIVE-IED: Position rejected (water) at %1", _pos];
        };
    };
    
    // Check 2: Terrain slope validation (flat terrain only)
    if (_isValid) then {
        _terrainNormal = surfaceNormal _pos;
        _slopeAngle = acos (_terrainNormal select 2);
        
        if (_slopeAngle > _maxSlope) then {
            _isValid = false;
            if (ADDON getVariable ["debug", false]) then {
                diag_log format ["ALIVE-IED: Position rejected (slope %.1f°) at %2", _slopeAngle, _pos];
            };
        };
    };
    
    // Check 3: Building interior check (NEW FEATURE)
    if (_isValid) then {
        _isOutside = ["isPositionOutside", [_pos]] call ALIVE_fnc_IEDPlacementHelpers;
        
        if (!_isOutside) then {
            _isValid = false;
            if (ADDON getVariable ["debug", false]) then {
                diag_log format ["ALIVE-IED: Position rejected (inside building) at %1", _pos];
            };
        };
    };
    
    // Check 4: Concealment score (NEW FEATURE)
    if (_isValid) then {
        _concealmentScore = ["getConcealmentScore", [_pos]] call ALIVE_fnc_IEDPlacementHelpers;
        
        // Reject positions that are too exposed
        if (_concealmentScore < _minConcealmentScore) then {
            _isValid = false;
            if (ADDON getVariable ["debug", false]) then {
                diag_log format ["ALIVE-IED: Position rejected (too exposed, score %1) at %2", _concealmentScore, _pos];
            };
        } else {
            // Log good concealment
            if (ADDON getVariable ["debug", false]) then {
                if (_concealmentScore > 50) then {
                    diag_log format ["ALIVE-IED: Good concealment (score %1) at %2", _concealmentScore, _pos];
                };
            };
        };
    };
    
    // Check 5: Proximity to already validated positions
    if (_isValid && count _goodspots > 0) then {
        {
            if (_pos distance _x < _minProximity) exitWith {
                _isValid = false;
                if (ADDON getVariable ["debug", false]) then {
                    diag_log format ["ALIVE-IED: Position rejected (too close to existing IED) at %1", _pos];
                };
            };
        } forEach _goodspots;
    };
    
    // If position passed all checks, add to good spots
    if (_isValid) then {
        _goodspots pushback _pos;
    };
    
} forEach _candidateSpots;

// ============================================================================
// PHASE 4: FINAL SORTING (Optional - prioritize by concealment)
// ============================================================================
// Sort validated positions by concealment score (best first)
private ["_scoredPositions"];
_scoredPositions = [];

{
    private ["_pos","_score"];
    _pos = _x;
    _score = ["getConcealmentScore", [_pos]] call ALIVE_fnc_IEDPlacementHelpers;
    _scoredPositions pushBack [_pos, _score];
} forEach _goodspots;

// Sort by score (highest first)
_scoredPositions sort false;

// Extract just the positions
_goodspots = [];
{
    _goodspots pushBack (_x select 0);
} forEach _scoredPositions;

// Debug output
if (ADDON getVariable ["debug", false]) then {
    private ["_chokepointCount","_regularCount"];
    _chokepointCount = count _chokepointPositions;
    _regularCount = (count _candidateSpots) - (_chokepointCount * 4); // Approximate
    
    diag_log format ["ALIVE-IED placeIED: Found %1 chokepoints, %2 regular candidates, validated %3 positions", 
        _chokepointCount, 
        _regularCount, 
        count _goodspots
    ];
    
    // Log top 3 positions with concealment scores
    private ["_topCount"];
    _topCount = (count _scoredPositions) min 3;
    for "_i" from 0 to (_topCount - 1) do {
        private ["_data","_pos","_score"];
        _data = _scoredPositions select _i;
        _pos = _data select 0;
        _score = _data select 1;
        diag_log format ["ALIVE-IED: Top position #%1: Concealment score %2 at %3", _i + 1, _score, _pos];
    };
};

_goodspots
