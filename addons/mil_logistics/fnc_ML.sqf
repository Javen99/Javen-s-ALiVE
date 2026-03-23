//#define DEBUG_MPDE_FULL
#include "\x\alive\addons\mil_logistics\script_component.hpp"
SCRIPT(ML);

/* ----------------------------------------------------------------------------
Function: ALIVE_fnc_ML
Description:
Military objectives

Parameters:
Nil or Object - If Nil, return a new instance. If Object, reference an existing instance.
String - The selected function
Array - The selected parameters

Returns:
Any - The new instance or the result of the selected function and parameters

Attributes:
Nil - init - Initiate instance
Nil - destroy - Destroy instance
Boolean - debug - Debug enabled
Array - state - Save and restore module state
Array - faction - Faction associated with module

Examples:
[_logic, "debug", true] call ALiVE_fnc_ML;

See Also:
- <ALIVE_fnc_MLInit>

Author:
ARJay & Jman
---------------------------------------------------------------------------- */

#define SUPERCLASS ALIVE_fnc_baseClass
#define MAINCLASS ALIVE_fnc_ML
#define MTEMPLATE "ALiVE_ML_%1"
#define DEFAULT_FACTIONS []
#define DEFAULT_OBJECTIVES []
#define DEFAULT_EVENT_QUEUE []
#define DEFAULT_REINFORCEMENT_ANALYSIS []
#define DEFAULT_SIDE "EAST"
#define DEFAULT_FORCE_POOL_TYPE "FIXED"
#define DEFAULT_FORCE_POOL "1000"
#define DEFAULT_ALLOW true
#define DEFAULT_TYPE "DYNAMIC"
#define DEFAULT_REGISTRY_ID ""
#define PARADROP_HEIGHT 500
#define DESTINATION_VARIANCE 150
#define DESTINATION_RADIUS 300
#define WAIT_TIME_AIR 10
#define WAIT_TIME_HELI 20
#define WAIT_TIME_MARINE 30
#define WAIT_TIME_DROP 40
#define START_FORCE_STRENGTH_INC false
#define START_FORCE_STRENGTH_INC_FACTOR "1"
#define START_FORCE_STRENGTH_DEC false
#define START_FORCE_STRENGTH_DEC_FACTOR "1"
// LZ search constants
#define LZ_MIN_CLEAR_RADIUS 5
#define LZ_OBJECT_CLEAR_RADIUS 20
#define LZ_VEHICLE_CLEAR_RADIUS 15
#define LZ_VERTICAL_CHECK_HEIGHT 35
#define LZ_MAX_GRADIENT 15
#define LZ_MAX_SEARCH_ATTEMPTS 8
#define LZ_SEARCH_RADIUS_INCREMENT 25
#define FUEL_WATCHDOG_STARTUP_DELAY 120
#define FUEL_WATCHDOG_CHECK_INTERVAL 10
#define FUEL_WATCHDOG_LOW_FUEL_THRESHOLD 0.15
#define FUEL_WATCHDOG_RECOVER_FUEL 0.5
#define FUEL_WATCHDOG_HOVER_SPEED_THRESHOLD 5
#define FUEL_WATCHDOG_MIN_HOVER_HEIGHT 5
#define MAX_GROUPS_PER_REQUEST 5
#define DISMOUNT_RADIUS 500
#define VEHICLE_LEAD_DIST 50

private ["_result"];

TRACE_1("ML - input",_this);

params [
    ["_logic", objNull, [objNull]],
    ["_operation", "", [""]],
    ["_args", objNull, [objNull,[],"",0,true,false]]
];
_result = true;

switch(_operation) do {
    default {
        _result = [_logic, _operation, _args] call SUPERCLASS;
    };
    case "destroy": {
        [_logic, "debug", false] call MAINCLASS;
        if (isServer) then {
            // if server
            _logic setVariable ["super", nil];
            _logic setVariable ["class", nil];
            _logic setVariable ["markers", []];

            [_logic, "destroy"] call SUPERCLASS;
        };
    };
    case "debug": {
        if (typeName _args == "BOOL") then {
            _logic setVariable ["debug", _args];
        } else {
            _args = _logic getVariable ["debug", false];
        };
        if (typeName _args == "STRING") then {
                if(_args == "true") then {_args = true;} else {_args = false;};
                _logic setVariable ["debug", _args];
        };
        ASSERT_TRUE(typeName _args == "BOOL",str _args);

        _result = _args;
    };
    case "persistent": {
        if (typeName _args == "BOOL") then {
            _logic setVariable ["persistent", _args];
        } else {
            _args = _logic getVariable ["persistent", false];
        };
        if (typeName _args == "STRING") then {
                if(_args == "true") then {_args = true;} else {_args = false;};
                _logic setVariable ["persistent", _args];
        };
        ASSERT_TRUE(typeName _args == "BOOL",str _args);

        _result = _args;
    };
    case "pause": {
        if(typeName _args != "BOOL") then {
            // if no new value was provided return current setting
            _args = [_logic,"pause",objNull,false] call ALIVE_fnc_OOsimpleOperation;
        } else {
                // if a new value was provided set groups list
                ASSERT_TRUE(typeName _args == "BOOL",str typeName _args);

                private ["_state"];
                _state = [_logic,"pause",objNull,false] call ALIVE_fnc_OOsimpleOperation;
                if (_state && _args) exitwith {};

                //Set value
                _args = [_logic,"pause",_args,false] call ALIVE_fnc_OOsimpleOperation;
                ["Pausing state of %1 instance set to %2!",QMOD(ADDON),_args] call ALiVE_fnc_dumpR;
        };
        _result = _args;
    };
    case "createMarker": {
        private["_position","_faction","_text","_markers","_debugColor","_markerID","_m"];

        _position = _args select 0;
        _faction = _args select 1;
        _text = _args select 2;

        _markers = _logic getVariable ["markers", []];

        if(count _markers > 10) then {
            {
                deleteMarker _x;
            } forEach _markers;
            _markers = [];
        };

        _debugColor = "ColorPink";

        switch(_faction) do {
            case "OPF_F":{
                _debugColor = "ColorRed";
            };
            case "BLU_F":{
                _debugColor = "ColorBlue";
            };
            case "IND_F":{
                _debugColor = "ColorGreen";
            };
            case "BLU_G_F":{
                _debugColor = "ColorBrown";
            };
            default {
                _debugColor = "ColorGreen";
            };
        };

        _markerID = time;

        if(count _position > 0) then {
            _m = createMarker [format["%1_%2",MTEMPLATE,_markerID], _position];
            _m setMarkerShape "ICON";
            _m setMarkerSize [0.5, 0.5];
            _m setMarkerType "mil_join";
            _m setMarkerColor _debugColor;
            _m setMarkerText _text;

            _markers pushback _m;
        };

        _logic setVariable ["markers", _markers];
    };
    case "side": {
        _result = [_logic,_operation,_args,DEFAULT_SIDE] call ALIVE_fnc_OOsimpleOperation;
    };
    case "factions": {
        _result = [_logic,_operation,_args,DEFAULT_FACTIONS] call ALIVE_fnc_OOsimpleOperation;
    };
    case "objectives": {
        _result = [_logic,_operation,_args,DEFAULT_OBJECTIVES] call ALIVE_fnc_OOsimpleOperation;
    };
    case "eventQueue": {
        _result = [_logic,_operation,_args,DEFAULT_EVENT_QUEUE] call ALIVE_fnc_OOsimpleOperation;
    };
    case "reinforcementAnalysis": {
        _result = [_logic,_operation,_args,DEFAULT_REINFORCEMENT_ANALYSIS] call ALIVE_fnc_OOsimpleOperation;
    };
    case "forcePoolType": {
        _result = [_logic,_operation,_args,DEFAULT_FORCE_POOL_TYPE] call ALIVE_fnc_OOsimpleOperation;
    };
    case "registryID": {
        _result = [_logic,_operation,_args,DEFAULT_REGISTRY_ID] call ALIVE_fnc_OOsimpleOperation;
    };
    case "allowInfantryReinforcement": {
        if (typeName _args == "BOOL") then {
            _logic setVariable ["allowInfantryReinforcement", _args];
        } else {
            _args = _logic getVariable ["allowInfantryReinforcement", false];
        };
        if (typeName _args == "STRING") then {
            if(_args == "true") then {_args = true;} else {_args = false;};
            _logic setVariable ["allowInfantryReinforcement", _args];
        };
        ASSERT_TRUE(typeName _args == "BOOL",str _args);

        _result = _args;
    };
    case "allowMechanisedReinforcement": {
        if (typeName _args == "BOOL") then {
            _logic setVariable ["allowMechanisedReinforcement", _args];
        } else {
            _args = _logic getVariable ["allowMechanisedReinforcement", false];
        };
        if (typeName _args == "STRING") then {
            if(_args == "true") then {_args = true;} else {_args = false;};
            _logic setVariable ["allowMechanisedReinforcement", _args];
        };
        ASSERT_TRUE(typeName _args == "BOOL",str _args);

        _result = _args;
    };
    case "allowMotorisedReinforcement": {
        if (typeName _args == "BOOL") then {
            _logic setVariable ["allowMotorisedReinforcement", _args];
        } else {
            _args = _logic getVariable ["allowMotorisedReinforcement", false];
        };
        if (typeName _args == "STRING") then {
            if(_args == "true") then {_args = true;} else {_args = false;};
            _logic setVariable ["allowMotorisedReinforcement", _args];
        };
        ASSERT_TRUE(typeName _args == "BOOL",str _args);

        _result = _args;
    };
    case "allowArmourReinforcement": {
        if (typeName _args == "BOOL") then {
            _logic setVariable ["allowArmourReinforcement", _args];
        } else {
            _args = _logic getVariable ["allowArmourReinforcement", false];
        };
        if (typeName _args == "STRING") then {
            if(_args == "true") then {_args = true;} else {_args = false;};
            _logic setVariable ["allowArmourReinforcement", _args];
        };
        ASSERT_TRUE(typeName _args == "BOOL",str _args);

        _result = _args;
    };
    case "allowHeliReinforcement": {
        if (typeName _args == "BOOL") then {
            _logic setVariable ["allowHeliReinforcement", _args];
        } else {
            _args = _logic getVariable ["allowHeliReinforcement", false];
        };
        if (typeName _args == "STRING") then {
            if(_args == "true") then {_args = true;} else {_args = false;};
            _logic setVariable ["allowHeliReinforcement", _args];
        };
        ASSERT_TRUE(typeName _args == "BOOL",str _args);

        _result = _args;
    };
    case "allowPlaneReinforcement": {
        if (typeName _args == "BOOL") then {
            _logic setVariable ["allowPlaneReinforcement", _args];
        } else {
            _args = _logic getVariable ["allowPlaneReinforcement", false];
        };
        if (typeName _args == "STRING") then {
            if(_args == "true") then {_args = true;} else {_args = false;};
            _logic setVariable ["allowPlaneReinforcement", _args];
        };
        ASSERT_TRUE(typeName _args == "BOOL",str _args);

        _result = _args;
    };
    case "enableAirTransport": {
        if (typeName _args == "BOOL") then {
            _logic setVariable ["enableAirTransport", _args];
        } else {
            _args = _logic getVariable ["enableAirTransport", false];
        };
        if (typeName _args == "STRING") then {
            if(_args == "true") then {_args = true;} else {_args = false;};
            _logic setVariable ["enableAirTransport", _args];
        };
        ASSERT_TRUE(typeName _args == "BOOL",str _args);

        _result = _args;
    };
    case "limitTransportToFaction": {
        if (typeName _args == "BOOL") then {
            _logic setVariable ["limitTransportToFaction", _args];
        } else {
            _args = _logic getVariable ["limitTransportToFaction", false];
        };
        if (typeName _args == "STRING") then {
            if(_args == "true") then {_args = true;} else {_args = false;};
            _logic setVariable ["limitTransportToFaction", _args];
        };
        ASSERT_TRUE(typeName _args == "BOOL",str _args);

        _result = _args;
    };
    case "type": {
        if(typeName _args == "STRING") then {
            _logic setVariable [_operation, parseNumber _args];
        };

        _result = _logic getVariable [_operation, DEFAULT_TYPE];
    };
    case "forcePool": {
        if(typeName _args == "STRING") then {
            _logic setVariable [_operation, parseNumber _args];
        };

        if(typeName _args == "SCALAR") then {
            _logic setVariable [_operation, _args];
        };

        _result = _logic getVariable [_operation, DEFAULT_FORCE_POOL];
    };
    case "startForceStrengthInc": {
        if (typeName _args == "BOOL") then {
            _logic setVariable ["startForceStrengthInc", _args];
        } else {
            _args = _logic getVariable ["startForceStrengthInc", START_FORCE_STRENGTH_INC];
        };
        if (typeName _args == "STRING") then {
            if(_args == "true") then {_args = true;} else {_args = START_FORCE_STRENGTH_INC;};
            _logic setVariable ["startForceStrengthInc", _args];
        };
        ASSERT_TRUE(typeName _args == "BOOL",str _args);

        _result = _args;
    };
    case "startForceStrengthIncFactor": {
        _result = [_logic,_operation,_args,START_FORCE_STRENGTH_INC_FACTOR] call ALIVE_fnc_OOsimpleOperation;
    };
    case "startForceStrengthDec": {
        if (typeName _args == "BOOL") then {
            _logic setVariable ["startForceStrengthDec", _args];
        } else {
            _args = _logic getVariable ["startForceStrengthDec", START_FORCE_STRENGTH_DEC];
        };
        if (typeName _args == "STRING") then {
            if(_args == "true") then {_args = true;} else {_args = START_FORCE_STRENGTH_DEC;};
            _logic setVariable ["startForceStrengthDec", _args];
        };
        ASSERT_TRUE(typeName _args == "BOOL",str _args);

        _result = _args;
    };
    case "startForceStrengthDecFactor": {
        _result = [_logic,_operation,_args,START_FORCE_STRENGTH_DEC_FACTOR] call ALIVE_fnc_OOsimpleOperation;
    };    
    
    // ============================================================
    // NEW OPERATION: prepareHelicopterLZ
    // Finds a clear landing zone near a position, moves any
    // blocking infantry out of the way, and returns the cleared pos.
    // Args: [_centerPosition, _searchRadius (optional, default 80)]
    // Returns: position array
    // ============================================================
    case "prepareHelicopterLZ": {

        private _centerPos    = _args select 0;
        private _searchRadius = if (count _args > 1) then {_args select 1} else {80};
        private _debug        = [_logic, "debug"] call MAINCLASS;

        ["ML - prepareHelicopterLZ: Searching for clear LZ near %1 radius %2",
            _centerPos, _searchRadius] call ALiVE_fnc_dump;

        private _clearPos  = [];
        private _attempts  = 0;
        private _curRadius = _searchRadius;

        while {count _clearPos == 0 && _attempts < LZ_MAX_SEARCH_ATTEMPTS} do {

            private _candidate = [
                _centerPos,
                LZ_MIN_CLEAR_RADIUS,
                _curRadius,
                LZ_OBJECT_CLEAR_RADIUS,
                0,
                LZ_MAX_GRADIENT,
                0
            ] call BIS_fnc_findSafePos;

            if (_debug) then {
                ["ML - prepareHelicopterLZ: Attempt %1 candidate %2",
                    _attempts + 1, _candidate] call ALiVE_fnc_dump;
            };

            if (!(surfaceIsWater _candidate) && !(_candidate isEqualTo []) && (count _candidate < 3 || (_candidate select 2) < 10)) then {

                private _nearTerrain  = nearestTerrainObjects [
                    _candidate,
                    ["ROCK","TREE","BUSH","WALL","FENCE","HOUSE"],
                    LZ_OBJECT_CLEAR_RADIUS
                ];
                private _nearVehicles = _candidate nearEntities [
                    ["Car","Tank","Air","Ship"],
                    LZ_VEHICLE_CLEAR_RADIUS
                ];

                private _checkHigh  = _candidate vectorAdd [0, 0, LZ_VERTICAL_CHECK_HEIGHT];
                private _checkLow   = _candidate vectorAdd [0, 0, 1];
                private _obstructed = count (lineIntersectsSurfaces [
                    AGLtoASL _checkHigh,
                    AGLtoASL _checkLow,
                    objNull, objNull, true, 1, "GEOM"
                ]) > 0;

                if (_debug) then {
                    ["ML - prepareHelicopterLZ: terrain=%1 vehicles=%2 obstructed=%3",
                        count _nearTerrain, count _nearVehicles, _obstructed] call ALiVE_fnc_dump;
                };

                if (count _nearTerrain == 0 && count _nearVehicles == 0 && !_obstructed) then {
                    _clearPos = _candidate;
                    if (_debug) then {
                        ["ML - prepareHelicopterLZ: Clear LZ found at %1 on attempt %2",
                            _clearPos, _attempts + 1] call ALiVE_fnc_dump;
                    };
                };
            };

            _curRadius = _curRadius + LZ_SEARCH_RADIUS_INCREMENT;
            _attempts  = _attempts + 1;
        };

        if (count _clearPos == 0) then {
            _clearPos = _centerPos;
            ["ML - prepareHelicopterLZ: WARNING - No clear LZ found after %1 attempts, using original pos %2",
                LZ_MAX_SEARCH_ATTEMPTS, _centerPos] call ALiVE_fnc_dump;
        };

        // Move blocking infantry clear of the chosen LZ
        private _blockingInfantry = _clearPos nearEntities [["Man"], LZ_OBJECT_CLEAR_RADIUS];
        if (count _blockingInfantry > 0) then {
            ["ML - prepareHelicopterLZ: Moving %1 blocking infantry from LZ %2",
                count _blockingInfantry, _clearPos] call ALiVE_fnc_dump;
            {
                private _movePos = [getPos _x, 8, 30, 1, 0, LZ_MAX_GRADIENT, 0] call BIS_fnc_findSafePos;
                if (count _movePos > 0 && !(surfaceIsWater _movePos)) then {
                    _x setPos _movePos;
                    if (_debug) then {
                        ["ML - prepareHelicopterLZ: Moved unit %1 to %2", _x, _movePos] call ALiVE_fnc_dump;
                    };
                };
            } forEach _blockingInfantry;
        };

        if (_debug) then {
            [_logic, "createMarker", [_clearPos, "BLU_F", "ML LZ"]] call MAINCLASS;
            ["ML - prepareHelicopterLZ: Final LZ: %1", _clearPos] call ALiVE_fnc_dump;
        };

        // Ensure returned position has Z coordinate
        if (count _clearPos == 2) then { _clearPos pushback 0; };

        _result = _clearPos;
    };

    // ============================================================
    // NEW OPERATION: findHelicopterLandingPos
    // Terrain and obstacle aware destination position search.
    // Checks terrain objects, vehicles, and vertical clearance.
    // Args: [_centerPosition, _minRadius, _maxRadius]
    // Returns: position array
    // ============================================================
    case "findHelicopterLandingPos": {

        private _centerPos     = _args select 0;
        private _minRadius     = _args select 1;
        private _maxRadius     = _args select 2;
        private _usedPositions = if (count _args > 3) then { _args select 3 } else { [] };
        private _debug         = [_logic, "debug"] call MAINCLASS;

        ["ML - findHelicopterLandingPos: Searching near %1 min %2 max %3",
            _centerPos, _minRadius, _maxRadius] call ALiVE_fnc_dump;

        private _foundPos = [];

        // --- Pass 1: Try roads first - they are clear of buildings by definition ---
        private _searchRadius = _maxRadius;
        for "_r" from 0 to 3 do {
            if (count _foundPos > 0) exitWith {};
            private _roads = _centerPos nearRoads _searchRadius;
            // Sort by distance
            _roads = _roads apply { [_x distance2D _centerPos, _x] };
            _roads sort true;

            // Merge caller's usedPositions with global tracker
            private _allUsedPos = _usedPositions + (missionNamespace getVariable ["ALIVE_ML_usedLZPositions", []]);

            {
                private _road = _x select 1;
                private _candidate = getPos _road;
                if (count _candidate < 2) then { continue };

                // Skip if too close to any used position (global or local)
                private _tooClose = false;
                {
                    private _usedPos = _x;
                    // Global entries have 4 elements [x,y,z,time], local have 3
                    if (count _usedPos > 3) then { _usedPos = [_usedPos select 0, _usedPos select 1, _usedPos select 2]; };
                    if (_candidate distance _usedPos < 150) then { _tooClose = true; };
                } forEach _allUsedPos;
                if (_tooClose) then { continue };

                // Must be within radius bounds
                private _dist = _candidate distance2D _centerPos;
                if (_dist < _minRadius || _dist > _searchRadius + 100) then { continue };

                // Road surface check - no terrain objects or overhead structures
                private _nearTerrain = nearestTerrainObjects [
                    _candidate,
                    ["ROCK","HOUSE","WALL","FENCE","BUILDING"],
                    LZ_OBJECT_CLEAR_RADIUS
                ];
                // Check for any objects above the candidate (catches petrol station canopies etc)
                private _nearObjects = _candidate nearObjects LZ_OBJECT_CLEAR_RADIUS;
                private _hasOverhead = false;
                {
                    if ((getPosASL _x select 2) > (AGLtoASL _candidate select 2) + 1) then {
                        _hasOverhead = true;
                    };
                } forEach _nearObjects;
                private _nearVehicles = _candidate nearEntities [["Car","Tank","Air","Ship"], LZ_VEHICLE_CLEAR_RADIUS];

                private _checkHigh = _candidate vectorAdd [0, 0, LZ_VERTICAL_CHECK_HEIGHT];
                private _checkLow  = _candidate vectorAdd [0, 0, 1];
                private _obstructed = count (lineIntersectsSurfaces [
                    AGLtoASL _checkHigh, AGLtoASL _checkLow,
                    objNull, objNull, true, 1, "GEOM"
                ]) > 0;

                // Gradient check - sample terrain height at 4 cardinal points 15m away
                // and check the slope is within limits for a helicopter to land safely
                private _h0 = getTerrainHeightASL _candidate;
                private _gradientTooSteep = false;
                {
                    private _samplePos = _candidate getPos [15, _x];
                    private _h1 = getTerrainHeightASL _samplePos;
                    if (abs(_h1 - _h0) > 2.5) then { _gradientTooSteep = true; }; // ~9 degree slope limit
                } forEach [0, 90, 180, 270];
                if (_gradientTooSteep) then { continue };

                if (count _nearTerrain == 0 && !_hasOverhead && count _nearVehicles == 0 && !_obstructed) then {
                    _foundPos = _candidate;
                    if (count _foundPos == 2) then { _foundPos pushback 0; };
                    // Register in global tracker so other events avoid this spot
                    private _globalUsed = missionNamespace getVariable ["ALIVE_ML_usedLZPositions", []];
                    // Expire entries older than 10 minutes
                    _globalUsed = _globalUsed select { (time - (_x select 3)) < 600 };
                    _globalUsed pushback (_foundPos + [time]);
                    missionNamespace setVariable ["ALIVE_ML_usedLZPositions", _globalUsed];
                    if (_debug) then {
                        ["ML - findHelicopterLandingPos: Road LZ found at %1", _foundPos] call ALiVE_fnc_dump;
                    };
                };
                if (count _foundPos > 0) exitWith {};
            } forEach _roads;
            _searchRadius = _searchRadius + 100;
        };

        // --- Pass 2: BIS_fnc_findSafePos fallback if no road found ---
        private _attempts    = 0;
        private _maxAttempts = 16;
        private _curMax      = _maxRadius;

        while {count _foundPos == 0 && _attempts < _maxAttempts} do {

            private _candidate = [
                _centerPos,
                _minRadius,
                _curMax,
                LZ_OBJECT_CLEAR_RADIUS,
                0,
                LZ_MAX_GRADIENT,
                0
            ] call BIS_fnc_findSafePos;

            if (!(surfaceIsWater _candidate) && !(_candidate isEqualTo []) && (count _candidate < 3 || (_candidate select 2) < 10)) then {

                private _nearTerrain  = nearestTerrainObjects [
                    _candidate,
                    ["ROCK","TREE","HOUSE","BUSH","WALL","FENCE"],
                    LZ_OBJECT_CLEAR_RADIUS
                ];
                private _nearVehicles = _candidate nearEntities [
                    ["Car","Tank","Air","Ship"],
                    LZ_VEHICLE_CLEAR_RADIUS
                ];

                private _checkHigh  = _candidate vectorAdd [0, 0, LZ_VERTICAL_CHECK_HEIGHT];
                private _checkLow   = _candidate vectorAdd [0, 0, 1];
                private _obstructed = count (lineIntersectsSurfaces [
                    AGLtoASL _checkHigh,
                    AGLtoASL _checkLow,
                    objNull, objNull, true, 1, "GEOM"
                ]) > 0;

                // Check spacing from already-assigned heli positions (local and global)
                private _tooClose = false;
                private _allUsed2 = _usedPositions + (missionNamespace getVariable ["ALIVE_ML_usedLZPositions", []]);
                {
                    private _usedPos2 = _x;
                    if (count _usedPos2 > 3) then { _usedPos2 = [_usedPos2 select 0, _usedPos2 select 1, _usedPos2 select 2]; };
                    if (_candidate distance _usedPos2 < 150) then { _tooClose = true; };
                } forEach _allUsed2;

                if (_debug) then {
                    ["ML - findHelicopterLandingPos: Attempt %1 terrain=%2 vehicles=%3 obstructed=%4 tooClose=%5",
                        _attempts + 1, count _nearTerrain, count _nearVehicles, _obstructed, _tooClose] call ALiVE_fnc_dump;
                };

                if (count _nearTerrain == 0 && count _nearVehicles == 0 && !_obstructed && !_tooClose) then {
                    _foundPos = _candidate;
                    // Register in global tracker
                    private _globalUsed2 = missionNamespace getVariable ["ALIVE_ML_usedLZPositions", []];
                    _globalUsed2 = _globalUsed2 select { (time - (_x select 3)) < 600 };
                    _globalUsed2 pushback (_foundPos + [time]);
                    missionNamespace setVariable ["ALIVE_ML_usedLZPositions", _globalUsed2];
                    if (_debug) then {
                        ["ML - findHelicopterLandingPos: Valid pos found %1 on attempt %2",
                            _foundPos, _attempts + 1] call ALiVE_fnc_dump;
                    };
                };
            };

            _curMax   = _curMax + LZ_SEARCH_RADIUS_INCREMENT;
            _attempts = _attempts + 1;
        };

        if (count _foundPos == 0) then {
            _foundPos = _centerPos getPos [_minRadius + 20 + (count _usedPositions * 30), random 360];
            ["ML - findHelicopterLandingPos: WARNING - No clear pos after %1 attempts, fallback %2",
                _maxAttempts, _foundPos] call ALiVE_fnc_dump;
        };

        if (_debug) then {
            ["ML - findHelicopterLandingPos: Final pos: %1", _foundPos] call ALiVE_fnc_dump;
        };

        // Ensure returned position has Z coordinate
        if (count _foundPos == 2) then { _foundPos pushback 0; };

        _result = _foundPos;
    };
    
    
    // ============================================================
    // NEW OPERATION: findBestDeliveryObjective
    // Scores OPCOM objectives by tactical need and friendly unit
    // presence to find the most useful helicopter delivery destination.
    // Prefers objectives that are actively contested (attack/defend)
    // with few friendly units already present.
    // Args: [_objectives, _insertionPos, _eventFaction, _side]
    // Returns: position array, or [] if no suitable objective found
    // ============================================================
    case "findBestDeliveryObjective": {

        private _objectives   = _args select 0;
        private _insertionPos = _args select 1;
        private _faction      = _args select 2;
        private _side         = _args select 3;
        private _departurePos = if (count _args > 4) then { _args select 4 } else { [] };
        private _debug        = [_logic, "debug"] call MAINCLASS;

        if (_debug) then {
            ["ML - findBestDeliveryObjective: Scoring %1 objectives for faction %2",
                count _objectives, _faction] call ALiVE_fnc_dump;
        };

        // Tactical state score - higher means more urgently needs reinforcement
        // attack/capture: OPCOM is actively taking this with units present - best target
        // defend: under pressure, reinforcements critical
        // reserve: already held, safe fallback if no active objectives exist
        // recon: skipped entirely (enemy/unknown territory)
        // none: skipped entirely - OPCOM hasn't assessed it, could be enemy territory
        private _stateScores = [
            ["attack",  100],
            ["capture", 100],
            ["defend",   80],
            ["reserve",  10]
        ];

        // Cap applied to raw OPCOM priority before scoring.
        // Prevents a single very high priority objective (e.g. priority=1000)
        // from dominating all tactical state considerations.
        // Effective range after normalisation becomes 0-50 points.
        private _priorityCap = 100;

        // Radius within which to count friendly and enemy units near an objective
        private _presenceCheckRadius = 500;

        // Maximum friendly unit count at which an objective is considered
        // well-staffed and deprioritised.
        private _wellStaffedThreshold = 8;

        // Valid active states for delivery destinations.
        // attack/capture/defend = OPCOM has units actively engaged there - best target.
        // reserve = OPCOM holds it - safe fallback when no active objectives exist.
        // recon and none are excluded - unknown/unassessed territory.
        private _activeStates = ["attack", "capture", "defend"];

        private _bestObjective   = nil;
        private _bestScore       = -1;
        private _bestPos         = [];
        private _bestIsActive    = false;
        private _bestObjState    = "none";
        private _bestEnemyCount  = 0;

        {
            private _obj         = _x;
            private _objPos      = [_obj, "center"] call ALIVE_fnc_hashGet;
            private _objPriority = [_obj, "priority"] call ALIVE_fnc_hashGet;
            private _objState    = "none";

            if ("tacom_state" in (_obj select 1)) then {
                _objState = [_obj, "tacom_state", "none"] call ALIVE_fnc_hashGet;
            };

            // Skip recon and none objectives entirely.
            // recon = OPCOM scouting enemy territory - unsafe.
            // none = OPCOM hasn't assessed it yet - could be anything.
            // Only attack/capture/defend/reserve are safe delivery targets.
            if (_objState == "recon" || _objState == "none") then {
                if (_debug) then {
                    ["ML - findBestDeliveryObjective: Skipping objective %1 - state=%2 (unassessed/enemy territory)",
                        _objPos, _objState] call ALiVE_fnc_dump;
                };
            } else {

            // Skip objectives that are the same as or too close to the insertion point,
            // or too close to the departure base - destination must be distinct from both
            private _distFromInsertion = _insertionPos distance _objPos;
            private _distFromDeparture = if (count _departurePos > 0) then { _departurePos distance _objPos } else { 9999 };
            if (_distFromInsertion < 500) then {
                if (_debug) then {
                    ["ML - findBestDeliveryObjective: Skipping objective %1 - too close to insertion point (%2m)",
                        _objPos, _distFromInsertion] call ALiVE_fnc_dump;
                };
            } else {
            if (_distFromDeparture < 500) then {
                if (_debug) then {
                    ["ML - findBestDeliveryObjective: Skipping objective %1 - too close to departure base (%2m)",
                        _objPos, _distFromDeparture] call ALiVE_fnc_dump;
                };
            } else {

                private _isActive = _objState in _activeStates;

                // If we already have an active-state candidate, skip inactive ones
                if (_bestIsActive && !_isActive) then {
                    if (_debug) then {
                        ["ML - findBestDeliveryObjective: Skipping inactive objective %1 (state=%2) - active candidate already found",
                            _objPos, _objState] call ALiVE_fnc_dump;
                    };
                } else {

                    // State score
                    private _stateScore = 40; // default for unknown states
                    {
                        if (_x select 0 == _objState) exitWith {
                            _stateScore = _x select 1;
                        };
                    } forEach _stateScores;

                    // Priority score - cap then normalise to 0-50 range.
                    // Capping prevents outlier priorities from overwhelming
                    // tactical state scores.
                    private _cappedPriority = _objPriority min _priorityCap;
                    private _priorityScore = (_cappedPriority / _priorityCap) * 50;

                    // Count friendly and enemy units near the objective
                    private _sideObj = [_side] call ALIVE_fnc_sideTextToObject;
                    private _friendlyCount = 0;
                    private _enemyCount = 0;
                    private _nearUnits = _objPos nearEntities [["Man","Car","Tank"], _presenceCheckRadius];
                    {
                        if (side _x == _sideObj) then {
                            _friendlyCount = _friendlyCount + 1;
                        } else {
                            if (side _x != civilian) then {
                                _enemyCount = _enemyCount + 1;
                            };
                        };
                    } forEach _nearUnits;

                    // Skip objectives with significant enemy presence -
                    // delivering reinforcements into an occupied enemy position
                    // is counterproductive regardless of tactical state score.
                    // Threshold of 3 allows for small patrols but blocks clearly
                    // enemy-held locations.
                    if (_enemyCount >= 3) then {
                        if (_debug) then {
                            ["ML - findBestDeliveryObjective: Skipping objective %1 (state=%2) - %3 enemy units within %4m",
                                _objPos, _objState, _enemyCount, _presenceCheckRadius] call ALiVE_fnc_dump;
                        };
                    } else {

                    // Presence score: 50 points when empty, scaling down to 0 at threshold
                    private _presenceScore = 0;
                    if (_friendlyCount < _wellStaffedThreshold) then {
                        _presenceScore = ((_wellStaffedThreshold - _friendlyCount) / _wellStaffedThreshold) * 50;
                    };

                    // Combined score
                    private _totalScore = _stateScore + _priorityScore + _presenceScore;

                    if (_debug) then {
                        ["ML - findBestDeliveryObjective: Objective at %1 state=%2 priority=%3 friendly=%4 enemy=%5 scores: state=%6 priority=%7 presence=%8 total=%9",
                            _objPos, _objState, _objPriority, _friendlyCount, _enemyCount,
                            _stateScore, _priorityScore, _presenceScore, _totalScore] call ALiVE_fnc_dump;
                    };

                    if (_totalScore > _bestScore || (_isActive && !_bestIsActive)) then {
                        _bestScore      = _totalScore;
                        _bestObjective  = _obj;
                        _bestPos        = _objPos;
                        _bestIsActive   = _isActive;
                        _bestObjState   = _objState;
                        _bestEnemyCount = _enemyCount;
                    };

                    }; // end enemy presence check

                };
            };
            }; // end departure proximity check

            }; // end recon skip

        } forEach _objectives;

        if (!isNil "_bestObjective" && count _bestPos > 0) then {
            if (_debug) then {
                private _bestLocName = [_bestPos] call ALIVE_fnc_taskGetNearestLocationName;
                ["ML - findBestDeliveryObjective: Best objective selected near %1 at %2 with score %3 state=%4 enemyCount=%5",
                    _bestLocName, _bestPos, _bestScore, _bestObjState, _bestEnemyCount] call ALiVE_fnc_dump;
            };
        } else {
            if (_debug) then {
                ["ML - findBestDeliveryObjective: No suitable objective found"] call ALiVE_fnc_dump;
            };
            _bestPos = [];
        };

        _result = [_bestPos, _bestEnemyCount, _bestObjState];
    };

    // ============================================================
    // NEW OPERATION: spawnHelicopterFuelWatchdog
    // Monitors a helicopter for hover-lock / fuel starvation.
    // Forces emergency landing and restores fuel for RTB.
    // Args: [_transportProfileID, _fallbackPosition, _eventFaction]
    // Returns: nil
    // ============================================================
    case "spawnHelicopterFuelWatchdog": {

        private _profileID   = _args select 0;
        private _fallbackPos = _args select 1;
        private _faction     = _args select 2;
        private _debug       = [_logic, "debug"] call MAINCLASS;

        ["ML - spawnHelicopterFuelWatchdog: Starting watchdog for profile %1",
            _profileID] call ALiVE_fnc_dump;

        [_profileID, _fallbackPos, _faction, _debug] spawn {

            private _profileID   = _this select 0;
            private _fallbackPos = _this select 1;
            private _faction     = _this select 2;
            private _debug       = _this select 3;

            sleep FUEL_WATCHDOG_STARTUP_DELAY;

            private _active = true;

            while {_active} do {
                sleep FUEL_WATCHDOG_CHECK_INTERVAL;

                private _profile = [ALIVE_profileHandler, "getProfile", _profileID] call ALIVE_fnc_profileHandler;

                if (isNil "_profile") exitWith {
                    if (_debug) then {
                        ["ML - spawnHelicopterFuelWatchdog: Profile %1 gone, exiting",
                            _profileID] call ALiVE_fnc_dump;
                    };
                    _active = false;
                };

                private _isActive = _profile select 2 select 1;

                if (_isActive) then {
                    private _heli = _profile select 2 select 10;

                    if (!isNull _heli && alive _heli) then {

                        private _fuel      = fuel _heli;
                        private _posASL    = getPosASL _heli;
                        private _groundASL = getTerrainHeightASL _posASL;
                        private _heightAGL = (_posASL select 2) - _groundASL;
                        private _spd       = speed _heli;

                        if (_debug) then {
                            ["ML - spawnHelicopterFuelWatchdog: %1 fuel=%2 heightAGL=%3 speed=%4",
                                _profileID, _fuel, _heightAGL, _spd] call ALiVE_fnc_dump;
                        };

                        if (
                            _fuel      < FUEL_WATCHDOG_LOW_FUEL_THRESHOLD &&
                            _heightAGL > FUEL_WATCHDOG_MIN_HOVER_HEIGHT   &&
                            _spd       < FUEL_WATCHDOG_HOVER_SPEED_THRESHOLD
                        ) then {
                            ["ML - spawnHelicopterFuelWatchdog: ALERT profile %1 hover-locked, fuel=%2. Forcing landing.",
                                _profileID, _fuel] call ALiVE_fnc_dump;

                            private _emergencyPos = [
                                _fallbackPos, 0, 150,
                                LZ_OBJECT_CLEAR_RADIUS,
                                0, LZ_MAX_GRADIENT, 0
                            ] call BIS_fnc_findSafePos;

                            if (surfaceIsWater _emergencyPos || _emergencyPos isEqualTo []) then {
                                _emergencyPos = _fallbackPos;
                            };

                            private _emergencyPad = createVehicle ["Land_HelipadEmpty_F", _emergencyPos, [], 0, "CAN_COLLIDE"];
                            _heli landAt _emergencyPad;
                            _heli setFuel FUEL_WATCHDOG_RECOVER_FUEL;

                            // Clean up pad once landed or after timeout
                            [_heli, _emergencyPad] spawn {
                                private _h = _this select 0;
                                private _p = _this select 1;
                                private _t = 0;
                                waitUntil { sleep 2; _t = _t + 2; (isTouchingGround _h || !alive _h || _t > 60) };
                                deleteVehicle _p;
                            };

                            ["ML - spawnHelicopterFuelWatchdog: Emergency landing at %1, fuel restored for profile %2",
                                _emergencyPos, _profileID] call ALiVE_fnc_dump;

                            _active = false;
                        };

                    } else {
                        if (_debug) then {
                            ["ML - spawnHelicopterFuelWatchdog: Heli null/dead for %1, exiting",
                                _profileID] call ALiVE_fnc_dump;
                        };
                        _active = false;
                    };
                };
            };
        };
    };



    // ============================================================
    // spawnHeliDeliveryWatchdog
    // Monitors a transport heli through its delivery cycle.
    // Only acts when the heli is ACTIVE (spawned near players).
    // Never fights ALiVE's virtualisation system.
    // Phases: TRANSIT(0) -> LANDING(1) -> UNLOAD(2) -> RTB(3)
    // Args: [_transportProfileID, _vehicleProfileID, _eventPosition, _returnPosition, _debug]
    // ============================================================
    case "spawnHeliDeliveryWatchdog": {

        private _transportProfileID = _args select 0;
        private _vehicleProfileID   = _args select 1;
        private _eventPosition      = _args select 2;
        private _returnPosition     = _args select 3;
        private _debug              = _args select 4;

        [_transportProfileID, _vehicleProfileID, _eventPosition, _returnPosition, _debug] spawn {

            private _tProfID   = _this select 0;
            private _vProfID   = _this select 1;
            private _destPos   = _this select 2;
            private _returnPos = _this select 3;
            private _dbg       = _this select 4;

            private _phase        = 0; // 0=transit 1=landing 2=unload 3=rtb
            private _phaseTimer   = 0;
            private _running      = true;
            private _landAtIssued = false;

            while {_running} do {
                sleep 5;
                _phaseTimer = _phaseTimer + 5;

                private _tProf = [ALIVE_profileHandler, "getProfile", _tProfID] call ALIVE_fnc_profileHandler;
                private _vProf = [ALIVE_profileHandler, "getProfile", _vProfID] call ALIVE_fnc_profileHandler;

                // Profile gone - heli destroyed or cleaned up
                if (isNil "_tProf" || isNil "_vProf") exitWith {
                    if (_dbg) then { ["ML - heliDeliveryWatchdog: Profile gone (%1), exiting.", _tProfID] call ALiVE_fnc_dump; };
                    _running = false;
                };

                private _isActive = _vProf select 2 select 1;
                private _heli     = _vProf select 2 select 10;

                // Only act when physically spawned - never force virtualisation state
                if (_isActive && !isNull _heli && alive _heli) then {

                    private _posASL    = getPosASL _heli;
                    private _groundASL = getTerrainHeightASL _posASL;
                    private _heightAGL = (_posASL select 2) - _groundASL;
                    private _spd       = speed _heli;

                    switch (_phase) do {

                        // TRANSIT - wait until heli reaches destination area
                        case 0: {
                            if (_heli distance _destPos < 350) then {
                                _phase = 1; _phaseTimer = 0; _landAtIssued = false;
                                if (_dbg) then { ["ML - heliDeliveryWatchdog: %1 LANDING phase.", _tProfID] call ALiVE_fnc_dump; };
                            };
                            // Hard timeout - something went wrong in transit
                            if (_phaseTimer > 900) then {
                                ["ML - heliDeliveryWatchdog: %1 TRANSIT timeout, watchdog exiting.", _tProfID] call ALiVE_fnc_dump;
                                _running = false;
                            };
                        };

                        // LANDING - issue landAt immediately on phase entry, retry every 30s
                        case 1: {
                            if (isTouchingGround _heli) then {
                                _phase = 2; _phaseTimer = 0;
                                if (_dbg) then { ["ML - heliDeliveryWatchdog: %1 UNLOAD phase.", _tProfID] call ALiVE_fnc_dump; };
                            } else {
                                // Issue landAt immediately and retry every 30s
                                // Use _landAtIssued as a 30s cooldown flag only - phaseTimer tracks total time in phase
                                if (!_landAtIssued) then {
                                    private _landPos = +_destPos;
                                    _landPos set [2, 0];
                                    private _landPad = createVehicle ["Land_HelipadEmpty_F", _landPos, [], 0, "CAN_COLLIDE"];
                                    _heli landAt _landPad;
                                    _landAtIssued = true;
                                    [_heli, _landPad] spawn {
                                        private _h = _this select 0; private _p = _this select 1; private _t = 0;
                                        waitUntil { sleep 2; _t = _t + 2; isTouchingGround _h || !alive _h || _t > 120 };
                                        deleteVehicle _p;
                                    };
                                    if (_dbg) then { ["ML - heliDeliveryWatchdog: %1 landAt issued.", _tProfID] call ALiVE_fnc_dump; };
                                };
                                // Allow retry after 30s by clearing the flag - but don't reset phaseTimer
                                if (_landAtIssued && (_phaseTimer mod 35) < 5) then {
                                    _landAtIssued = false;
                                };
                                // Give up after 5 min total in landing phase
                                if (_phaseTimer > 300) then {
                                    _phase = 2; _phaseTimer = 0;
                                    ["ML - heliDeliveryWatchdog: %1 LANDING timeout (%2m AGL), forcing UNLOAD.", _tProfID, _heightAGL] call ALiVE_fnc_dump;
                                };
                            };
                        };

                        // UNLOAD - wait for cargo to exit, then issue RTB waypoints
                        case 2: {
                            private _cargoCount = 0;
                            {
                                if (alive _x && vehicle _x == _heli && !(_x in crew _heli)) then {
                                    _cargoCount = _cargoCount + 1;
                                };
                            } forEach crew _heli;

                            if (_cargoCount == 0 || _phaseTimer > 120) then {
                                // Force eject any remaining cargo
                                if (_cargoCount > 0) then {
                                    { if (alive _x && !(vehicle _x == _x) && !(_x in crew _heli)) then { unassignVehicle _x; _x moveOut _heli; }; } forEach crew _heli;
                                };

                                // Issue RTB waypoints via profile - go direct to return position
                                // No intermediate waypoint to avoid heli hovering at air position
                                private _tProfNow = [ALIVE_profileHandler, "getProfile", _tProfID] call ALIVE_fnc_profileHandler;
                                if !(isNil "_tProfNow") then {
                                    private _wpReturn  = [_returnPos, 400, "MOVE", "NORMAL", 300, [], "LINE"] call ALIVE_fnc_createProfileWaypoint;
                                    [_tProfNow, "clearWaypoints"] call ALIVE_fnc_profileEntity;
                                    [_tProfNow, "addWaypoint", _wpReturn] call ALIVE_fnc_profileEntity;
                                };

                                _phase = 3; _phaseTimer = 0;
                                if (_dbg) then { ["ML - heliDeliveryWatchdog: %1 RTB phase, waypoints issued.", _tProfID] call ALiVE_fnc_dump; };
                            };
                        };

                        // RTB - once far enough away, done
                        case 3: {
                            if (_heli distance _destPos > 1200 || _phaseTimer > 600) then {
                                _running = false;
                                if (_dbg) then { ["ML - heliDeliveryWatchdog: %1 RTB complete, exiting.", _tProfID] call ALiVE_fnc_dump; };
                            };
                        };

                    }; // end switch

                } else {
                    // Heli is virtual (not near players) - just track time and exit if too long
                    // Don't try to force it active - trust ALiVE's virtualisation
                    if (_phase == 3 && _phaseTimer > 120) then {
                        // RTB and virtual = successfully departed, done
                        _running = false;
                        if (_dbg) then { ["ML - heliDeliveryWatchdog: %1 virtualised in RTB, done.", _tProfID] call ALiVE_fnc_dump; };
                    };
                    if (_phaseTimer > 1200) then {
                        // Something went wrong - exit to avoid zombie watchdog
                        _running = false;
                        ["ML - heliDeliveryWatchdog: %1 global timeout, exiting.", _tProfID] call ALiVE_fnc_dump;
                    };
                };

            }; // end while

        }; // end spawn

    }; // end case spawnHeliDeliveryWatchdog



    // ============================================================
    // OPERATION: spawnHeliParadropWatchdog
    // ============================================================
    case "spawnHeliParadropWatchdog": {

        private _tProfID     = _args select 0;
        private _vProfID     = _args select 1;
        private _destPos     = _args select 2;
        private _returnPos   = _args select 3;
        private _infantryIDs = _args select 4;
        private _dropHeight  = _args select 5;
        private _dbg         = _args select 6;

        [_tProfID, _vProfID, _destPos, _returnPos, _infantryIDs, _dropHeight, _dbg] spawn {

            private _tProfID     = _this select 0;
            private _vProfID     = _this select 1;
            private _destPos     = _this select 2;
            private _returnPos   = _this select 3;
            private _infantryIDs = _this select 4;
            private _dropHeight  = _this select 5;
            private _dbg         = _this select 6;

            private _dropRadius     = 350;
            private _transitTimeout = 900;
            private _phaseTimer     = 0;
            private _phase          = 0;
            private _dropped        = false;

            if (_dbg) then {
                ["ML - heliParadropWatchdog: %1 STARTED. dest=%2 groups=%3 dropHeight=%4", _tProfID, _destPos, count _infantryIDs, _dropHeight] call ALiVE_fnc_dump;
            };

            while { _phase == 0 } do {
                sleep 5;
                _phaseTimer = _phaseTimer + 5;
                private _tp = [ALIVE_profileHandler, "getProfile", _tProfID] call ALIVE_fnc_profileHandler;
                if (isNil "_tp") then {
                    ["ML - heliParadropWatchdog: %1 profile gone at %2s. Aborting.", _tProfID, _phaseTimer] call ALiVE_fnc_dump;
                    _phase = 2;
                } else {
                    if (_phaseTimer > _transitTimeout) then {
                        ["ML - heliParadropWatchdog: %1 TRANSIT timeout at %2s. Forcing drop.", _tProfID, _phaseTimer] call ALiVE_fnc_dump;
                        _phase = 1;
                    } else {
                        private _heli = _tp select 2 select 10;
                        if (!isNull _heli && alive _heli) then {
                            private _dist = _heli distance2D _destPos;
                            if (_dbg) then {
                                ["ML - heliParadropWatchdog: %1 TRANSIT active. dist=%2m heightAGL=%3m t=%4s", _tProfID, round _dist, round ((_heli modelToWorldVisual [0,0,0]) select 2), _phaseTimer] call ALiVE_fnc_dump;
                            };
                            if (_dist < _dropRadius) then {
                                ["ML - heliParadropWatchdog: %1 over DZ (active) dist=%2m. Beginning drop.", _tProfID, round _dist] call ALiVE_fnc_dump;
                                _phase = 1;
                            };
                        } else {
                            private _profPos = _tp select 2 select 2;
                            private _dist2D = if (count _profPos > 1) then { _profPos distance2D _destPos } else { -1 };
                            if (_dbg) then {
                                ["ML - heliParadropWatchdog: %1 TRANSIT virtual. profPos=%2 dist=%3m t=%4s", _tProfID, _profPos, round _dist2D, _phaseTimer] call ALiVE_fnc_dump;
                            };
                            if (_dist2D >= 0 && _dist2D < _dropRadius) then {
                                ["ML - heliParadropWatchdog: %1 over DZ (virtual) dist=%2m. Beginning drop.", _tProfID, round _dist2D] call ALiVE_fnc_dump;
                                _phase = 1;
                            } else {
                                if (_phaseTimer > 180) then {
                                    ["ML - heliParadropWatchdog: %1 virtual timeout at %2s dist=%3m. Forcing drop.", _tProfID, _phaseTimer, round _dist2D] call ALiVE_fnc_dump;
                                    _phase = 1;
                                };
                            };
                        };
                    };
                };
            };

            if (_phase == 1) then {
                private _tp2   = [ALIVE_profileHandler, "getProfile", _tProfID] call ALIVE_fnc_profileHandler;
                private _heli2 = if (!isNil "_tp2") then { _tp2 select 2 select 10 } else { objNull };
                private _heliActive = (!isNull _heli2 && alive _heli2);

                if (_dbg) then {
                    ["ML - heliParadropWatchdog: %1 DROP phase. heliActive=%2 groups=%3", _tProfID, _heliActive, count _infantryIDs] call ALiVE_fnc_dump;
                };

                {
                    private _infProfID  = _x;
                    private _infProfile = [ALIVE_profileHandler, "getProfile", _infProfID] call ALIVE_fnc_profileHandler;
                    if (!isNil "_infProfile") then {

                        if (_heliActive) then {
                            // -------------------------------------------------------
                            // ACTIVE drop: heli is within activation range.
                            // Teleport infantry profile to heli position first so
                            // ALiVE will spawn them (out-of-range spawn silently fails),
                            // then physically place them in parachutes.
                            // -------------------------------------------------------
                            // Teleport infantry profile to ground below the heli so
                            // ALiVE's spawn system activates them (spawn fails if outside range).
                            // Use ground position directly beneath heli, not the heli's altitude.
                            private _heliPos = getPos _heli2;  // AGL ground-level x,y
                            [_infProfile, "position", _heliPos] call ALIVE_fnc_profileEntity;

                            private _infUnits = _infProfile select 2 select 21;
                            if (_dbg) then {
                                ["ML - heliParadropWatchdog: %1 inf profile %2 units before spawn: %3 active=%4", _tProfID, _infProfID, count _infUnits, _infProfile select 2 select 1] call ALiVE_fnc_dump;
                            };
                            if (count _infUnits == 0) then {
                                [_infProfile, "spawn"] call ALIVE_fnc_profileEntity;
                                // Wait for ALiVE to materialise units -- max 5 seconds
                                private _spawnTimer = 0;
                                waitUntil {
                                    sleep 0.1;
                                    _spawnTimer = _spawnTimer + 0.1;
                                    _infUnits = _infProfile select 2 select 21;
                                    (count _infUnits > 0) || (_spawnTimer > 5)
                                };
                                if (_dbg) then {
                                    ["ML - heliParadropWatchdog: %1 inf profile %2 units after spawn: %3 (waited %4s)", _tProfID, _infProfID, count _infUnits, _spawnTimer] call ALiVE_fnc_dump;
                                };
                            };
                            {
                                private _unit = _x;
                                if (alive _unit) then {
                                    private _dropPosASL = getPosASL _heli2;
                                    _dropPosASL set [2, (_dropPosASL select 2) - 8];
                                    private _para = createVehicle ["NonSteerableParachute_F", ASLToAGL _dropPosASL, [], 0, "FLY"];
                                    _para allowDamage false;
                                    _para setPosASL _dropPosASL;
                                    _para setVelocity (velocity _heli2);
                                    _unit moveInDriver _para;
                                    [_para] spawn { sleep 2; (_this select 0) allowDamage true; };
                                    if (_dbg) then {
                                        ["ML - heliParadropWatchdog: Unit %1 dropped in parachute at %2", _unit, ASLToAGL _dropPosASL] call ALiVE_fnc_dump;
                                    };
                                    sleep 0.4;
                                };
                            } forEach _infUnits;

                        } else {
                            // -------------------------------------------------------
                            // VIRTUAL drop: move infantry profile to destination.
                            // -------------------------------------------------------
                            [_infProfile, "position", _destPos] call ALIVE_fnc_profileEntity;
                            private _wpDest = [_destPos, 100, "MOVE", "NORMAL", 60, [], "LINE"] call ALIVE_fnc_createProfileWaypoint;
                            [_infProfile, "clearWaypoints"] call ALIVE_fnc_profileEntity;
                            [_infProfile, "addWaypoint", _wpDest] call ALIVE_fnc_profileEntity;
                            if (_dbg) then {
                                ["ML - heliParadropWatchdog: %1 virtual drop -- inf profile %2 teleported to %3", _tProfID, _infProfID, _destPos] call ALiVE_fnc_dump;
                            };
                        };

                    } else {
                        if (_dbg) then {
                            ["ML - heliParadropWatchdog: %1 inf profile %2 is nil, skipping.", _tProfID, _infProfID] call ALiVE_fnc_dump;
                        };
                    };
                } forEach _infantryIDs;
                _dropped = true;
                if (_dbg) then {
                    ["ML - heliParadropWatchdog: %1 drop phase complete. dropped=%2", _tProfID, _dropped] call ALiVE_fnc_dump;
                };
            };

            // Signal completion only after a successful drop
            if (_dropped) then {
                if (isNil "ALIVE_ML_paradropComplete") then { ALIVE_ML_paradropComplete = []; };
                ALIVE_ML_paradropComplete pushBackUnique _tProfID;
                if (_dbg) then {
                    ["ML - heliParadropWatchdog: %1 paradropComplete signalled. Watchdog exiting.", _tProfID] call ALiVE_fnc_dump;
                };
            } else {
                if (_dbg) then {
                    ["ML - heliParadropWatchdog: %1 exiting WITHOUT drop (phase=%2). paradropComplete NOT signalled.", _tProfID, _phase] call ALiVE_fnc_dump;
                };
            };

        };

    }; // end case spawnHeliParadropWatchdog

    // Main process
    case "init": {
        if (isServer) then {

            private ["_debug","_forcePool","_type","_allowInfantry","_allowMechanised","_allowMotorised","_allowArmour","_allowHeli","_allowPlane"];

            // if server, initialise module game logic
            _logic setVariable ["super", SUPERCLASS];
            _logic setVariable ["class", MAINCLASS];
            _logic setVariable ["moduleType", "ALIVE_ML"];
            _logic setVariable ["startupComplete", false];
            _logic setVariable ["listenerID", ""];
            _logic setVariable ["registryID", ""];
            _logic setVariable ["initialAnalysisComplete", false];
            _logic setVariable ["analysisInProgress", false];
            _logic setVariable ["eventQueue", [] call ALIVE_fnc_hashCreate];

            _debug = [_logic, "debug"] call MAINCLASS;
            _forcePool = [_logic, "forcePool"] call MAINCLASS;
            _type = [_logic, "type"] call MAINCLASS;

            if(typeName _forcePool == "STRING") then {
                _forcePool = parseNumber _forcePool;
            };

            if(_forcePool == 10) then {
                [_logic, "forcePool", 1000] call MAINCLASS;
                [_logic, "forcePoolType", "DYNAMIC"] call MAINCLASS;
            };

            _allowInfantry = [_logic, "allowInfantryReinforcement"] call MAINCLASS;
            _allowMechanised = [_logic, "allowMechanisedReinforcement"] call MAINCLASS;
            _allowMotorised = [_logic, "allowMotorisedReinforcement"] call MAINCLASS;
            _allowArmour = [_logic, "allowArmourReinforcement"] call MAINCLASS;
            _allowHeli = [_logic, "allowHeliReinforcement"] call MAINCLASS;
            _allowPlane = [_logic, "allowPlaneReinforcement"] call MAINCLASS;

            _enableAirTransport = [_logic, "enableAirTransport"] call MAINCLASS;
            _limitTransportToFaction = [_logic, "limitTransportToFaction"] call MAINCLASS;

            _startForceStrengthIncrement = [_logic, "startForceStrengthInc"] call MAINCLASS;
            _startForceStrengthIncrementFactor = parseNumber([_logic, "startForceStrengthIncFactor"] call MAINCLASS);
            _startForceStrengthDecrement = [_logic, "startForceStrengthDec"] call MAINCLASS;
            _startForceStrengthDecrementFactor = parseNumber([_logic, "startForceStrengthDecFactor"] call MAINCLASS);

            // DEBUG -------------------------------------------------------------------------------------
            if(_debug) then {
                ["----------------------------------------------------------------------------------------"] call ALIVE_fnc_dump;
                ["ML - Init"] call ALiVE_fnc_dump;
                ["ML - Type: %1",_type] call ALiVE_fnc_dump;
                ["ML - Force pool type: %1 limit: %2",[_logic, "forcePool"] call MAINCLASS,[_logic, "forcePoolType"] call MAINCLASS] call ALiVE_fnc_dump;
                ["ML - Allow infantry requests: %1",_allowInfantry] call ALiVE_fnc_dump;
                ["ML - Allow mechanised requests: %1",_allowMechanised] call ALiVE_fnc_dump;
                ["ML - Allow motorised requests: %1",_allowMotorised] call ALiVE_fnc_dump;
                ["ML - Allow armour requests: %1",_allowArmour] call ALiVE_fnc_dump;
                ["ML - Allow heli requests: %1",_allowHeli] call ALiVE_fnc_dump;
                ["ML - Allow plane requests: %1",_allowPlane] call ALiVE_fnc_dump;
                ["ML - Enable air transport: %1",_enableAirTransport] call ALiVE_fnc_dump;
                ["ML - Limit air assets to faction only: %1",_limitTransportToFaction] call ALiVE_fnc_dump;
                ["ML - Enable incremental force strength on objective capture: %1",_startForceStrengthIncrement] call ALiVE_fnc_dump;
                ["ML - Incremental force strength factor: %1",_startForceStrengthIncrementFactor] call ALiVE_fnc_dump;
                ["ML - Enable decremental force strength on objective loss: %1",_startForceStrengthDecrement] call ALiVE_fnc_dump;
                ["ML - Decremental force strength factor: %1",_startForceStrengthDecrementFactor] call ALiVE_fnc_dump;
            };
            // DEBUG -------------------------------------------------------------------------------------


            // create the global registry
            if(isNil "ALIVE_MLGlobalRegistry") then {
                ALIVE_MLGlobalRegistry = [nil, "create"] call ALIVE_fnc_MLGlobalRegistry;
                [ALIVE_MLGlobalRegistry, "init"] call ALIVE_fnc_MLGlobalRegistry;
                [ALIVE_MLGlobalRegistry, "debug", _debug] call ALIVE_fnc_MLGlobalRegistry;
            };

            TRACE_1("After module init",_logic);

            [_logic,"start"] call MAINCLASS;
        };
    };

    case "start": {
        if (isServer) then {

            private ["_debug","_modules","_module","_worldName","_file","_moduleObject"];

            _debug = [_logic, "debug"] call MAINCLASS;


            // DEBUG -------------------------------------------------------------------------------------
            if(_debug) then {
                ["----------------------------------------------------------------------------------------"] call ALIVE_fnc_dump;
                ["ML - Startup"] call ALiVE_fnc_dump;
            };
            // DEBUG -------------------------------------------------------------------------------------


            // check modules are available
            if !(["ALiVE_sys_profile","ALiVE_mil_opcom"] call ALiVE_fnc_isModuleAvailable) exitwith {
                ["Military Logistics reports that Virtual AI module or OPCOM module not placed! Exiting..."] call ALiVE_fnc_DumpR;
            };
            waituntil {!(isnil "ALiVE_ProfileHandler") && {[ALiVE_ProfileSystem,"startupComplete",false] call ALIVE_fnc_hashGet}};

            // if civ cluster data not loaded, load it
            if(isNil "ALIVE_clustersCiv" && isNil "ALIVE_loadedCivClusters") then {
                _worldName = toLower(worldName);
                _file = format["x\alive\addons\civ_placement\clusters\clusters.%1_civ.sqf", _worldName];
                call compile preprocessFileLineNumbers _file;
                ALIVE_loadedCIVClusters = true;
            };
            waituntil {!(isnil "ALIVE_loadedCIVClusters") && {ALIVE_loadedCIVClusters}};

            // if mil cluster data not loaded, load it
            if(isNil "ALIVE_clustersMil" && isNil "ALIVE_loadedMilClusters") then {
                _worldName = toLower(worldName);
                _file = format["x\alive\addons\mil_placement\clusters\clusters.%1_mil.sqf", _worldName];
                call compile preprocessFileLineNumbers _file;
                ALIVE_loadedMilClusters = true;
            };
            waituntil {!(isnil "ALIVE_loadedMilClusters") && {ALIVE_loadedMilClusters}};

            // get all synced modules
            _modules = [];

            for "_i" from 0 to ((count synchronizedObjects _logic)-1) do {
                _moduleObject = (synchronizedObjects _logic) select _i;

                waituntil {_module = _moduleObject getVariable "handler"; !(isnil "_module")};
                _module = _moduleObject getVariable "handler";
                _modules pushback _module;
            };

            // DEBUG -------------------------------------------------------------------------------------
            if(_debug) then {
                ["ML - Startup completed"] call ALiVE_fnc_dump;
                ["----------------------------------------------------------------------------------------"] call ALIVE_fnc_dump;
            };
            // DEBUG -------------------------------------------------------------------------------------


            _logic setVariable ["startupComplete", true];

            if(count _modules > 0) then {

                // start listening for logcom events
                [_logic,"listen"] call MAINCLASS;

                // start initial analysis
                [_logic, "initialAnalysis", _modules] call MAINCLASS;
            }else{
                ["ML - Warning no OPCOM modules synced to Military Logistics module, nothing to do.."] call ALiVE_fnc_dumpR;

            };
        };
    };

    case "initialAnalysis": {
        if (isServer) then {

            private ["_debug","_modules","_module","_modulesFactions","_moduleSide","_moduleFactions","_modulesObjectives","_moduleFactionBreakdowns",
            "_faction","_factionBreakdown","_objectives"];

            _modules = _args;

            _debug = [_logic, "debug"] call MAINCLASS;
            _modulesFactions = [];
            _modulesObjectives = [];

            // get objectives and modules settings from syncronised OPCOM instances
            // should only be 1...
            {
                _module = _x;
                _moduleSide = [_module,"side"] call ALiVE_fnc_HashGet;

                // Register side with clients
                MOD(Require) setVariable [format["ALIVE_MIL_LOG_AVAIL_%1", _moduleSide], true, true];

                _moduleFactions = [_module,"factions"] call ALiVE_fnc_HashGet;

                // store side
                [_logic, "side", _moduleSide] call MAINCLASS;

                // get the objectives from the module
                _objectives = [];

                waituntil {
                    sleep 10;
                    _objectives = nil;
                    _objectives = [_module,"objectives"] call ALIVE_fnc_hashGet;
                    (!(isnil "_objectives") && {count _objectives > 0})
                };

                _modulesFactions pushback [_moduleSide,_moduleFactions];
                _modulesObjectives pushback _objectives;

                // set the faction force pools
                {
                    [ALIVE_globalForcePool,_x,0] call ALIVE_fnc_hashSet;
                } forEach _moduleFactions;

            } forEach _modules;

            [_logic, "factions", _modulesFactions] call MAINCLASS;
            [_logic, "objectives", _modulesObjectives] call MAINCLASS;

            // register the module
            [ALIVE_MLGlobalRegistry,"register",_logic] call ALIVE_fnc_MLGlobalRegistry;

            // set as initial analysis complete
            _logic setVariable ["initialAnalysisComplete", true];

            // trigger main processing loop
            [_logic, "monitor"] call MAINCLASS;
        };
    };

    case "listen": {
        private["_listenerID"];

        _listenerID = [ALIVE_eventLog, "addListener",[_logic, ["LOGCOM_REQUEST","LOGCOM_STATUS_REQUEST","LOGCOM_CANCEL_REQUEST","OPCOM_CAPTURE"]]] call ALIVE_fnc_eventLog;
        _logic setVariable ["listenerID", _listenerID];
    };

    case "handleEvent": {
        private["_event","_type","_eventData"];

        if(typeName _args == "ARRAY") then {

            _event = _args;
            _type = [_event, "type"] call ALIVE_fnc_hashGet;

            [_logic, _type, _event] call MAINCLASS;

        };
    };
    
    case "OPCOM_CAPTURE": {

        private["_debug","_event","_eventData","_eventQueue","_side","_factions","_eventFaction","_eventSide","_factionFound","_data","_id","_startForceStrengthIncrement","_startForceStrengthDecrement","_startForceStrengthIncrementFactor","_startForceStrengthDecrementFactor",
        "_moduleFactions","_eventPlayerID","_eventRequestID","_countToAdd","_countToRemove", "_instanceProfilesCount","_thisInstanceSFS","_thissideTarget","_objectiveID","_objectivePos","_randomWeightedElement"];
        
        if(typeName _args == "ARRAY") then {

		        _event = _args;
		        _debug = [_logic, "debug"] call MAINCLASS;
		        _id = [_event, "id"] call ALIVE_fnc_hashGet;
		        _data = [_event, "data"] call ALIVE_fnc_hashGet;
		        _factions = [_logic, "factions"] call MAINCLASS;
		        _eventFaction = _data select 0;
		        _eventSide = _data select 1;
		        _startForceStrengthIncrement = [_logic, "startForceStrengthInc"] call MAINCLASS;
		        _startForceStrengthDecrement = [_logic, "startForceStrengthDec"] call MAINCLASS;
		        _startForceStrengthIncrementFactor = parseNumber([_logic, "startForceStrengthIncFactor"] call MAINCLASS);
		        _startForceStrengthDecrementFactor = parseNumber([_logic, "startForceStrengthDecFactor"] call MAINCLASS);
		           
		        _data params ["_side","_objective"]; 
		         // DEBUG -------------------------------------------------------------------------------------
             if (_debug) then {
              ["ML - Force Strength 'OPCOM_CAPTURE' -> _side (event): %1, _eventFaction: %2, _faction: %3, _factions: %4", _side, _eventFaction, (_factions select 0 select 0), _factions] call ALiVE_fnc_dump;
		         };
		        // DEBUG -------------------------------------------------------------------------------------
		        // the side that captured && startForceStrengthInc is true...
		        if (_eventFaction == _side && _startForceStrengthIncrement) then {
		        	if (_side == (_factions select 0 select 0)) then {
		        		// DEBUG -------------------------------------------------------------------------------------
                if (_debug) then {
		        	   ["ML - Force Strength 'OPCOM_CAPTURE' (Increment) -> _faction: %1, _side (event): %2, _eventFaction: %3, _objective: %4, _startForceStrengthIncrementFactor: %5", (_factions select 0 select 0), _side, _eventFaction, _objective, _startForceStrengthIncrementFactor] call ALiVE_fnc_dump;
		        	  };
		        	  // DEBUG -------------------------------------------------------------------------------------
		             _objectiveID = [_objective,"id"] call ALiVE_fnc_hashGet;
		             _objectivePos = [_objective,"center"] call ALiVE_fnc_hashGet;
		            {
		            	 _thissideTarget = [_x, "side", ""] call ALIVE_fnc_hashGet;  
		            	if (_thissideTarget == _side) then {   
		            	 _thisInstanceSFS =  [_x,"startForceStrength"] call ALiVE_fnc_HashGet;
		        		// DEBUG -------------------------------------------------------------------------------------
                if (_debug) then {
                 ["ML - Force Strength 'OPCOM_CAPTURE' -> _thisInstanceSFS: %1", _thisInstanceSFS] call ALiVE_fnc_dump;
		        	  };
		        	  // DEBUG -------------------------------------------------------------------------------------
		              };
		            } forEach OPCOM_INSTANCES; 
		            _instanceProfilesCount = 0; 
		            { 
		            	_instanceProfilesCount = _instanceProfilesCount + _x;
		            } forEach _thisInstanceSFS;
		             _countToAdd = ceil((_instanceProfilesCount * _startForceStrengthIncrementFactor)/100);
		            for "_i" from 0 to (_countToAdd -1) do {
		            	_randomWeightedElement = [["Infantry","Motorized","Mechanized","Armored","Artillery","AAA","Air","Sea"], _thisInstanceSFS] call BIS_fnc_selectRandomWeighted;
                  [_side, _randomWeightedElement, 1] call ALIVE_fnc_OPCOMIncrementStartForceStrength;    
		            };
		          };
		        }; 
		        // the side that lost && startForceStrengthDec is true...
		        if (_eventFaction == _side && _startForceStrengthDecrement) then {
		        	if (_side != (_factions select 0 select 0)) then {
		        		// DEBUG -------------------------------------------------------------------------------------
                if (_debug) then {
		        	   ["ML - Force Strength 'OPCOM_CAPTURE' (Decrement) -> _faction: %1, _side (event): %2, _eventFaction: %3, _objective: %4, _startForceStrengthDecrementFactor: %5", (_factions select 0 select 0), _side, _eventFaction, _objective, _startForceStrengthDecrementFactor] call ALiVE_fnc_dump;
		        	  };
		        	  // DEBUG -------------------------------------------------------------------------------------
		             _objectiveID = [_objective,"id"] call ALiVE_fnc_hashGet;
		             _objectivePos = [_objective,"center"] call ALiVE_fnc_hashGet;
		            {
		            	 _thissideTarget = [_x, "side", ""] call ALIVE_fnc_hashGet;  
		            	if (_thissideTarget == (_factions select 0 select 0)) then {   
		            	 _thisInstanceSFS =  [_x,"startForceStrength"] call ALiVE_fnc_HashGet;
		        		// DEBUG -------------------------------------------------------------------------------------
                if (_debug) then {
                 ["ML - Force Strength 'OPCOM_CAPTURE' -> _thisInstanceSFS: %1", _thisInstanceSFS] call ALiVE_fnc_dump;
		        	  };
		        	  // DEBUG -------------------------------------------------------------------------------------
		              };
		            } forEach OPCOM_INSTANCES; 
		            _instanceProfilesCount = 0; 
		            { 
		            	_instanceProfilesCount = _instanceProfilesCount + _x;
		            } forEach _thisInstanceSFS;
		             _countToRemove = ceil((_instanceProfilesCount * _startForceStrengthDecrementFactor)/100);
		            for "_i" from 0 to (_countToRemove -1) do {
		            	_randomWeightedElement = [["Infantry","Motorized","Mechanized","Armored","Artillery","AAA","Air","Sea"], _thisInstanceSFS] call BIS_fnc_selectRandomWeighted;
                  [(_factions select 0 select 0), _randomWeightedElement, 1] call ALIVE_fnc_OPCOMdecrementStartForceStrength;    
		            };
		        	};
		        };
        }; 
    };

    case "LOGCOM_STATUS_REQUEST": {

        private["_debug","_event","_eventData","_eventQueue","_side","_factions","_eventFaction","_eventSide","_factionFound",
        "_moduleFactions","_eventPlayerID","_eventRequestID"];

        if(typeName _args == "ARRAY") then {

            _event = _args;
            _eventData = [_event, "data"] call ALIVE_fnc_hashGet;

            _side = [_logic, "side"] call MAINCLASS;
            _factions = [_logic, "factions"] call MAINCLASS;

            _eventFaction = _eventData select 0;
            _eventSide = _eventData select 1;
            _eventRequestID = _eventData select 2;
            _eventPlayerID = _eventData select 3;

            // check if the faction in the event is handled
            // by this module
            _factionFound = false;

            {
                _moduleFactions = _x select 1;
                if(_eventFaction in _moduleFactions) then {
                    _factionFound = true;
                };
            } forEach _factions;

            // faction not handled by this mil logistics module
            if!(_factionFound) then {

                private ["_sideOPCOMModules","_factionOPCOMModules","_checkModule","_moduleType","_handler","_OPCOMSide","_OPCOMFactions","_OPCOMHasLogistics","_mod"];

                _sideOPCOMModules = [];
                _factionOPCOMModules = [];

                // loop through OPCOM modules with mil logistics synced and find any matching the events side and faction
                {

                    _checkModule = _x;
                    _moduleType = _x getVariable "moduleType";

                    if!(isNil "_moduleType") then {

                        if(_moduleType == "ALIVE_OPCOM") then {

                            _handler = _checkModule getVariable "handler";
                            _OPCOMSide = [_handler,"side"] call ALIVE_fnc_hashGet;
                            _OPCOMFactions = [_handler,"factions"] call ALIVE_fnc_hashGet;
                            _OPCOMHasLogistics = false;

                            for "_i" from 0 to ((count synchronizedObjects _checkModule)-1) do {

                                _mod = (synchronizedObjects _checkModule) select _i;

                                if ((typeof _mod) == "ALiVE_mil_logistics") then {
                                    _OPCOMHasLogistics = true;
                                };
                            };

                            if(_OPCOMHasLogistics) then {

                                if(_OPCOMSide == _eventSide) then {
                                    _sideOPCOMModules pushback _checkModule;
                                };

                                {
                                    if(_x == _eventFaction) then {
                                        _factionOPCOMModules pushback _checkModule;
                                    };

                                } forEach _OPCOMFactions;

                            };
                        };
                    };
                } forEach (entities "Module_F");

                // if no mil logistics handles this faction, and there is more than one mil
                // logistics for this side return an error
                if(((count _factionOPCOMModules == 0) && (count _sideOPCOMModules > 1)) || ((count _factionOPCOMModules == 0) && (count _sideOPCOMModules == 0))) then {
                    _factionFound = false;
                };

                // if no mil logistics handles this faction, and there is one mil
                // logistics for this side and this module handles that side
                if((count _factionOPCOMModules == 0) && (count _sideOPCOMModules == 1) && (_side == _eventSide)) then {
                    _factionFound = true;
                };

            };

            if!(_factionFound) exitWith {};

            if(_factionFound) then {

                private ["_eventQueue","_response","_responseItem","_playerRequested","_eventData","_logEvent","_playerID",
                "_eventState","_eventType","_eventForceMakeup","_requestID","_transportProfiles","_position","_playerRequestProfileID","_profile"];

                // get the event data for this player

                _eventQueue = [_logic, "eventQueue"] call MAINCLASS;

                _response = [];

                if((count (_eventQueue select 2)) > 0) then {

                    {
                        _playerRequested = [_x, "playerRequested"] call ALIVE_fnc_hashGet;

                        if(_playerRequested) then {
                            _eventData = [_x, "data"] call ALIVE_fnc_hashGet;
                            _playerID = _eventData select 5;
                            _eventType = _eventData select 4;
                            _eventForceMakeup = _eventData select 3;

                            if(_eventPlayerID == _playerID) then {

                                _responseItem = [];

                                _requestID = _eventForceMakeup select 0;
                                _eventState = [_x, "state"] call ALIVE_fnc_hashGet;
                                _transportProfiles = [_x, "transportProfiles"] call ALIVE_fnc_hashGet;

                                _positions = [];

                                if(count _transportProfiles > 0) then {

                                    {
                                        _profile = [ALIVE_profileHandler, "getProfile", _x] call ALIVE_fnc_profileHandler;

                                        if!(isNil "_profile") then {
                                            _position = _profile select 2 select 2;
                                            _positions pushBack _position;
                                        };

                                    } forEach _transportProfiles;

                                };

                                _responseItem pushBack _eventType;
                                _responseItem pushBack _requestID;
                                _responseItem pushBack _eventState;
                                _responseItem pushBack _positions;

                                _response pushBack _responseItem;
                            };
                        };

                    } forEach (_eventQueue select 2);

                };

                // respond to player request
                _logEvent = ['LOGCOM_RESPONSE', [_eventRequestID,_eventPlayerID,_response],"Logistics","STATUS"] call ALIVE_fnc_event;
                [ALIVE_eventLog, "addEvent",_logEvent] call ALIVE_fnc_eventLog;

            };
        };
    };

    case "LOGCOM_CANCEL_REQUEST": {

        private["_debug","_event","_eventData","_eventQueue","_side","_factions","_eventFaction","_eventSide","_factionFound",
        "_moduleFactions","_eventPlayerID","_eventRequestID","_eventCancelRequestID"];

        if(typeName _args == "ARRAY") then {

            _event = _args;
            _eventData = [_event, "data"] call ALIVE_fnc_hashGet;

            _side = [_logic, "side"] call MAINCLASS;
            _factions = [_logic, "factions"] call MAINCLASS;

            _eventFaction = _eventData select 0;
            _eventSide = _eventData select 1;
            _eventRequestID = _eventData select 2;
            _eventPlayerID = _eventData select 3;
            _eventCancelRequestID = _eventData select 4;

            // check if the faction in the event is handled
            // by this module
            _factionFound = false;

            {
                _moduleFactions = _x select 1;
                if(_eventFaction in _moduleFactions) then {
                    _factionFound = true;
                };
            } forEach _factions;

            // faction not handled by this mil logistics module
            if!(_factionFound) then {

                private ["_sideOPCOMModules","_factionOPCOMModules","_checkModule","_moduleType","_handler","_OPCOMSide","_OPCOMFactions","_OPCOMHasLogistics","_mod"];

                _sideOPCOMModules = [];
                _factionOPCOMModules = [];

                // loop through OPCOM modules with mil logistics synced and find any matching the events side and faction
                {

                    _checkModule = _x;
                    _moduleType = _x getVariable "moduleType";

                    if!(isNil "_moduleType") then {

                        if(_moduleType == "ALIVE_OPCOM") then {

                            _handler = _checkModule getVariable "handler";
                            _OPCOMSide = [_handler,"side"] call ALIVE_fnc_hashGet;
                            _OPCOMFactions = [_handler,"factions"] call ALIVE_fnc_hashGet;
                            _OPCOMHasLogistics = false;

                            for "_i" from 0 to ((count synchronizedObjects _checkModule)-1) do {

                                _mod = (synchronizedObjects _checkModule) select _i;

                                if ((typeof _mod) == "ALiVE_mil_logistics") then {
                                    _OPCOMHasLogistics = true;
                                };
                            };

                            if(_OPCOMHasLogistics) then {

                                if(_OPCOMSide == _eventSide) then {
                                    _sideOPCOMModules pushback _checkModule;
                                };

                                {
                                    if(_x == _eventFaction) then {
                                        _factionOPCOMModules pushback _checkModule;
                                    };

                                } forEach _OPCOMFactions;

                            };
                        };
                    };
                } forEach (entities "Module_F");

                // if no mil logistics handles this faction, and there is more than one mil
                // logistics for this side return an error
                if(((count _factionOPCOMModules == 0) && (count _sideOPCOMModules > 1)) || ((count _factionOPCOMModules == 0) && (count _sideOPCOMModules == 0))) then {
                    _factionFound = false;
                };

                // if no mil logistics handles this faction, and there is one mil
                // logistics for this side and this module handles that side
                if((count _factionOPCOMModules == 0) && (count _sideOPCOMModules == 1) && (_side == _eventSide)) then {
                    _factionFound = true;
                };

            };

            if!(_factionFound) exitWith {};

            if(_factionFound) then {

                private ["_eventQueue","_response","_responseItem","_playerRequested","_eventID","_eventData","_logEvent","_playerID",
                "_eventState","_eventType","_eventForceMakeup","_responseItem","_eventCargoProfiles","_infantryProfiles","_armourProfiles",
                "_mechanisedProfiles","_motorisedProfiles","_planeProfiles","_heliProfiles","_eventAssets","_allRequestedProfiles","_anyActive",
                "_transportProfiles","_transportVehiclesProfiles","_requestID","_position","_playerRequestProfileID","_profile","_active","_profileType"];

                // get the event data for this player

                _eventQueue = [_logic, "eventQueue"] call MAINCLASS;

                _response = [];

                if((count (_eventQueue select 2)) > 0) then {

                    {
                        _playerRequested = [_x, "playerRequested"] call ALIVE_fnc_hashGet;

                        if(_playerRequested) then {
                            _eventID = [_x, "id"] call ALIVE_fnc_hashGet;
                            _eventData = [_x, "data"] call ALIVE_fnc_hashGet;
                            _playerID = _eventData select 5;
                            _eventType = _eventData select 4;
                            _eventForceMakeup = _eventData select 3;

                            if(_eventPlayerID == _playerID) then {

                                _responseItem = [];

                                _requestID = _eventForceMakeup select 0;

                                if(_requestID == _eventCancelRequestID) then {

                                    //_x call ALIVE_fnc_inspectHash;

                                    _eventCargoProfiles = [_x, "cargoProfiles"] call ALIVE_fnc_hashGet;

                                    _transportProfiles = [_x, "transportProfiles"] call ALIVE_fnc_hashGet;
                                    _transportVehiclesProfiles = [_x, "transportVehiclesProfiles"] call ALIVE_fnc_hashGet;

                                    _infantryProfiles = [_eventCargoProfiles, 'infantry'] call ALIVE_fnc_hashGet;
                                    _armourProfiles = [_eventCargoProfiles, 'armour'] call ALIVE_fnc_hashGet;
                                    _mechanisedProfiles = [_eventCargoProfiles, 'mechanised'] call ALIVE_fnc_hashGet;
                                    _motorisedProfiles = [_eventCargoProfiles, 'motorised'] call ALIVE_fnc_hashGet;
                                    _planeProfiles = [_eventCargoProfiles, 'plane'] call ALIVE_fnc_hashGet;
                                    _heliProfiles = [_eventCargoProfiles, 'heli'] call ALIVE_fnc_hashGet;

                                    _allRequestedProfiles = [];
                                    _anyActive = false;

                                    {
                                        _profile = [ALIVE_profileHandler, "getProfile", _x] call ALIVE_fnc_profileHandler;
                                        if!(isNil "_profile") then {
                                            _active = _profile select 2 select 1;
                                            if(_active) then {
                                                _anyActive = true;
                                            };
                                            _allRequestedProfiles pushBack _profile;
                                        };

                                    } forEach _transportProfiles;

                                    {
                                        _profile = [ALIVE_profileHandler, "getProfile", _x] call ALIVE_fnc_profileHandler;
                                        if!(isNil "_profile") then {
                                            _active = _profile select 2 select 1;
                                            if(_active) then {
                                                _anyActive = true;
                                            };
                                            _allRequestedProfiles pushBack _profile;
                                        };

                                    } forEach _transportVehiclesProfiles;

                                    {
                                        _profile = [ALIVE_profileHandler, "getProfile", _x select 0] call ALIVE_fnc_profileHandler;
                                        if!(isNil "_profile") then {
                                            _active = _profile select 2 select 1;
                                            if(_active) then {
                                                _anyActive = true;
                                            };
                                            _allRequestedProfiles pushBack _profile;
                                        };

                                    } forEach _infantryProfiles;

                                    {
                                        {
                                            _profile = [ALIVE_profileHandler, "getProfile", _x] call ALIVE_fnc_profileHandler;
                                            if!(isNil "_profile") then {
                                                _active = _profile select 2 select 1;
                                                if(_active) then {
                                                    _anyActive = true;
                                                };
                                                _allRequestedProfiles pushBack _profile;
                                            };
                                        } forEach _x;

                                    } forEach _armourProfiles;

                                    {
                                        {
                                            _profile = [ALIVE_profileHandler, "getProfile", _x] call ALIVE_fnc_profileHandler;
                                            if!(isNil "_profile") then {
                                                _active = _profile select 2 select 1;
                                                if(_active) then {
                                                    _anyActive = true;
                                                };
                                                _allRequestedProfiles pushBack _profile;
                                            };
                                        } forEach _x;

                                    } forEach _mechanisedProfiles;

                                    {
                                        {
                                            _profile = [ALIVE_profileHandler, "getProfile", _x] call ALIVE_fnc_profileHandler;
                                            if!(isNil "_profile") then {
                                                _active = _profile select 2 select 1;
                                                if(_active) then {
                                                    _anyActive = true;
                                                };
                                                _allRequestedProfiles pushBack _profile;
                                            };
                                        } forEach _x;

                                    } forEach _motorisedProfiles;

                                    {
                                        {
                                            _profile = [ALIVE_profileHandler, "getProfile", _x] call ALIVE_fnc_profileHandler;
                                            if!(isNil "_profile") then {
                                                _active = _profile select 2 select 1;
                                                if(_active) then {
                                                    _anyActive = true;
                                                };
                                                _allRequestedProfiles pushBack _profile;
                                            };
                                        } forEach _x;

                                    } forEach _planeProfiles;

                                    {
                                        {
                                            _profile = [ALIVE_profileHandler, "getProfile", _x] call ALIVE_fnc_profileHandler;
                                            if!(isNil "_profile") then {
                                                _active = _profile select 2 select 1;
                                                if(_active) then {
                                                    _anyActive = true;
                                                };
                                                _allRequestedProfiles pushBack _profile;
                                            };
                                        } forEach _x;

                                    } forEach _heliProfiles;

                                    if(_anyActive) then {

                                        // respond to player request
                                        _logEvent = ['LOGCOM_RESPONSE', [_eventRequestID,_eventPlayerID,_response],"Logistics","CANCEL_FAILED"] call ALIVE_fnc_event;
                                        [ALIVE_eventLog, "addEvent",_logEvent] call ALIVE_fnc_eventLog;

                                    }else{

                                        // delete all profiles

                                        {
                                            _profileType = _x select 2 select 5;
                                            if(_profileType == 'entity') then {
                                                [_x, "destroy"] call ALIVE_fnc_profileEntity;
                                            }else{
                                                [_x, "destroy"] call ALIVE_fnc_profileVehicle;
                                            };

                                        } forEach _allRequestedProfiles;

                                        _eventAssets = [_x, "eventAssets"] call ALIVE_fnc_hashGet;

                                        {
                                            deleteVehicle _x;
                                        } forEach _eventAssets;

                                        // set state to event complete
                                        [_x, "state", "eventComplete"] call ALIVE_fnc_hashSet;
                                        [_eventQueue, _eventID, _x] call ALIVE_fnc_hashSet;

                                        // respond to player request
                                        _logEvent = ['LOGCOM_RESPONSE', [_eventRequestID,_eventPlayerID,_response],"Logistics","CANCEL_OK"] call ALIVE_fnc_event;
                                        [ALIVE_eventLog, "addEvent",_logEvent] call ALIVE_fnc_eventLog;

                                    };
                                };
                            };
                        };

                    } forEach (_eventQueue select 2);

                };
            };
        };
    };

    case "LOGCOM_REQUEST": {

        private["_debug","_event","_eventQueue","_side","_factions","_eventFaction","_eventSide","_factionFound","_moduleFactions","_forcePool","_type","_eventID",
        "_eventData","_eventType","_eventForceMakeup","_eventForceInfantry","_eventForceMotorised","_eventForceMechanised","_eventForceArmour",
        "_eventForcePlane","_eventForceHeli","_forceMakeupTotal","_allowInfantry","_allowMechanised","_allowMotorised",
        "_allowArmour","_allowHeli","_allowPlane","_playerID","_requestID","_logEvent","_initComplete"];

        if(typeName _args == "ARRAY") then {

            _debug = [_logic, "debug"] call MAINCLASS;
            _event = _args;
            _eventData = [_event, "data"] call ALIVE_fnc_hashGet;
            _eventType = _eventData select 4;

            _initComplete = true;

            if(_eventType == "PR_STANDARD" || _eventType == "PR_AIRDROP" || _eventType == "PR_HELI_INSERT") then {
                _initComplete = _logic getVariable "initialAnalysisComplete";
                if!(_initComplete) then {
                    _eventForceMakeup = _eventData select 3;
                    _playerID = _eventData select 5;
                    _requestID = _eventForceMakeup select 0;
                    // respond to player request
                    _logEvent = ['LOGCOM_RESPONSE', [_requestID,_playerID],"Logistics","DENIED_WAITING_INIT"] call ALIVE_fnc_event;
                    [ALIVE_eventLog, "addEvent",_logEvent] call ALIVE_fnc_eventLog;
                };
            };

            if!(_initComplete) exitWith {};

            _side = [_logic, "side"] call MAINCLASS;
            _factions = [_logic, "factions"] call MAINCLASS;

            _eventFaction = _eventData select 1;
            _eventSide = _eventData select 2;

            // check if the faction in the event is handled
            // by this module
            _factionFound = false;

            {
                _moduleFactions = _x select 1;
                if(_eventFaction in _moduleFactions) then {
                    _factionFound = true;
                };
            } forEach _factions;

            // check if any other mil logistics modules can handle this event

            if(_eventType == "PR_STANDARD" || _eventType == "PR_AIRDROP" || _eventType == "PR_HELI_INSERT") then {

                // faction not handled by this mil logistics module
                if!(_factionFound) then {

                    private ["_sideOPCOMModules","_factionOPCOMModules","_checkModule","_moduleType","_handler","_OPCOMSide","_OPCOMFactions","_OPCOMHasLogistics","_mod"];

                    _sideOPCOMModules = [];
                    _factionOPCOMModules = [];

                    // loop through OPCOM modules with mil logistics synced and find any matching the events side and faction
                    {

                        _checkModule = _x;
                        _moduleType = _x getVariable "moduleType";

                        if!(isNil "_moduleType") then {

                            if(_moduleType == "ALIVE_OPCOM") then {

                                _handler = _checkModule getVariable "handler";
                                _OPCOMSide = [_handler,"side"] call ALIVE_fnc_hashGet;
                                _OPCOMFactions = [_handler,"factions"] call ALIVE_fnc_hashGet;
                                _OPCOMHasLogistics = false;

                                for "_i" from 0 to ((count synchronizedObjects _checkModule)-1) do {

                                    _mod = (synchronizedObjects _checkModule) select _i;

                                    if ((typeof _mod) == "ALiVE_mil_logistics") then {
                                        _OPCOMHasLogistics = true;
                                    };
                                };

                                if(_OPCOMHasLogistics) then {

                                    if(_OPCOMSide == _eventSide) then {
                                        _sideOPCOMModules pushback _checkModule;
                                    };

                                    {
                                        if(_x == _eventFaction) then {
                                            _factionOPCOMModules pushback _checkModule;
                                        };

                                    } forEach _OPCOMFactions;

                                };
                            };
                        };
                    } forEach (entities "Module_F");

                    // if no mil logistics handles this faction, and there is more than one mil
                    // logistics for this side return an error
                    if(((count _factionOPCOMModules == 0) && (count _sideOPCOMModules > 1)) || ((count _factionOPCOMModules == 0) && (count _sideOPCOMModules == 0))) then {
                        _eventForceMakeup = _eventData select 3;
                        _playerID = _eventData select 5;
                        _requestID = _eventForceMakeup select 0;
                        // respond to player request
                        _logEvent = ['LOGCOM_RESPONSE', [_requestID,_playerID],"Logistics","DENIED_FACTION_HANDLER_NOT_FOUND"] call ALIVE_fnc_event;
                        [ALIVE_eventLog, "addEvent",_logEvent] call ALIVE_fnc_eventLog;
                    };

                    // if no mil logistics handles this faction, and there is one mil
                    // logistics for this side and this module handles that side
                    if((count _factionOPCOMModules == 0) && (count _sideOPCOMModules == 1) && (_side == _eventSide)) then {

                        _factionFound = true;

                        _eventData set [1,_factions select 0 select 1 select 0];
                        [_event, "data", _eventData] call ALIVE_fnc_hashSet;
                        _eventFaction = _factions select 0 select 1 select 0;
                    };

                };
            };

            if!(_factionFound) exitWith {};


            if(_factionFound) then {

                _type = [_logic, "type"] call MAINCLASS;

                _forcePool = [ALIVE_globalForcePool,_eventFaction] call ALIVE_fnc_hashGet;


                // DEBUG -------------------------------------------------------------------------------------
                if(_debug) then {
                    ["ML - Global force pool:"] call ALiVE_fnc_dump;
                    ALIVE_globalForcePool call ALIVE_fnc_inspectHash;
                };
                // DEBUG -------------------------------------------------------------------------------------


                // if there are still forces available
                if(_forcePool > 0) then {

                    _eventID = [_event, "id"] call ALIVE_fnc_hashGet;
                    _eventData = [_event, "data"] call ALIVE_fnc_hashGet;
                    _eventType = _eventData select 4;

                    _forceMakeupTotal = 0;

                    if(_eventType == "STANDARD" || _eventType == "AIRDROP" || _eventType == "HELI_INSERT" || _eventType == "HELI_PARADROP") then {

                        //Sanitize _eventForceMakeup, 0 is the minimum for every reinforcement type, only for default logistics
                        //Restricted to opcom calls as the player logistic requests are made different
                        _eventForceMakeup = (_eventData select 3) apply { _x max 0 };

                        _allowInfantry = [_logic, "allowInfantryReinforcement"] call MAINCLASS;
                        _allowMechanised = [_logic, "allowMechanisedReinforcement"] call MAINCLASS;
                        _allowMotorised = [_logic, "allowMotorisedReinforcement"] call MAINCLASS;
                        _allowArmour = [_logic, "allowArmourReinforcement"] call MAINCLASS;
                        _allowHeli = [_logic, "allowHeliReinforcement"] call MAINCLASS;
                        _allowPlane = [_logic, "allowPlaneReinforcement"] call MAINCLASS;

                        _eventForceInfantry = _eventForceMakeup select 0;
                        _eventForceMotorised = _eventForceMakeup select 1;
                        _eventForceMechanised = _eventForceMakeup select 2;
                        _eventForceArmour = _eventForceMakeup select 3;
                        _eventForcePlane = _eventForceMakeup select 4;
                        _eventForceHeli = _eventForceMakeup select 5;

                        _forceMakeupTotal = _eventForceInfantry + _eventForceMotorised + _eventForceMechanised + _eventForceArmour + _eventForcePlane + _eventForceHeli;

                        //["CHECK AI: %1 AM: %2 AM: %3 AA: %4 AH: %5 AP: %6",_allowInfantry,_allowMechanised,_allowMotorised,_allowArmour,_allowHeli,_allowPlane] call ALIVE_fnc_dump;
                        //["FORCE MAKEUP BEFORE: %1", _eventForceMakeup] call ALIVE_fnc_dump;

                        if!(_allowInfantry) then {
                            _forceMakeupTotal = _forceMakeupTotal - _eventForceInfantry;
                            _eventForceMakeup set [0,0];
                        };

                        if!(_allowMotorised) then {
                            _forceMakeupTotal = _forceMakeupTotal - _eventForceMotorised;
                            _eventForceMakeup set [1,0];
                        };

                        if!(_allowMechanised) then {
                            _forceMakeupTotal = _forceMakeupTotal - _eventForceMechanised;
                            _eventForceMakeup set [2,0];
                        };

                        if!(_allowArmour) then {
                            _forceMakeupTotal = _forceMakeupTotal - _eventForceArmour;
                            _eventForceMakeup set [3,0];
                        };

                        if!(_allowPlane) then {
                            _forceMakeupTotal = _forceMakeupTotal - _eventForcePlane;
                            _eventForceMakeup set [4,0];
                        };

                        if!(_allowHeli) then {
                            _forceMakeupTotal = _forceMakeupTotal - _eventForceHeli;
                            _eventForceMakeup set [5,0];
                        };

                        // -----------------------------------------------------------------
                        // FIX: Cap each force type to MAX_GROUPS_PER_REQUEST to prevent
                        // OPCOM from requesting unreasonably large reinforcements.
                        // Also recompute _forceMakeupTotal after capping.
                        // -----------------------------------------------------------------
                        private _capApplied = false;
                        for "_capIdx" from 0 to ((count _eventForceMakeup) - 1) do {
                            private _capVal = _eventForceMakeup select _capIdx;
                            if (_capVal > MAX_GROUPS_PER_REQUEST) then {
                                _eventForceMakeup set [_capIdx, MAX_GROUPS_PER_REQUEST];
                                _capApplied = true;
                            };
                        };

                        if (_capApplied && _debug) then {
                            ["ML - LOGCOM_REQUEST: Force makeup capped to max %1 per type. Capped makeup: %2",
                                MAX_GROUPS_PER_REQUEST, _eventForceMakeup] call ALiVE_fnc_dump;
                        };

                        // Recompute total after capping
                        _eventForceInfantry   = _eventForceMakeup select 0;
                        _eventForceMotorised  = _eventForceMakeup select 1;
                        _eventForceMechanised = _eventForceMakeup select 2;
                        _eventForceArmour     = _eventForceMakeup select 3;
                        _eventForcePlane      = _eventForceMakeup select 4;
                        _eventForceHeli       = _eventForceMakeup select 5;

                        _forceMakeupTotal = _eventForceInfantry + _eventForceMotorised + _eventForceMechanised + _eventForceArmour + _eventForcePlane + _eventForceHeli;

                        if (_debug) then {
                            ["ML - LOGCOM_REQUEST: Final force makeup after cap: %1 total groups: %2",
                                _eventForceMakeup, _forceMakeupTotal] call ALiVE_fnc_dump;
                        };
                        // -----------------------------------------------------------------

                        _eventData set [3, _eventForceMakeup];
                        [_event, "data", _eventData] call ALIVE_fnc_hashSet;

                        // set the state of the event
                        [_event, "state", "requested"] call ALIVE_fnc_hashSet;

                        // set the player requested flag on the event
                        [_event, "playerRequested", false] call ALIVE_fnc_hashSet;

                    }else{

                        _eventForceMakeup = _eventData select 3; //The array of player logistics is different than opcom one
                        
                        _playerID = _eventData select 5;
                        _requestID = _eventForceMakeup select 0;

                        // if it's a player request
                        // accept automatically

                        _forceMakeupTotal = 1;

                        // set the state of the event
                        [_event, "state", "playerRequested"] call ALIVE_fnc_hashSet;

                        // set the player requested flag on the event
                        [_event, "playerRequested", true] call ALIVE_fnc_hashSet;

                        // respond to player request
                        _logEvent = ['LOGCOM_RESPONSE', [_requestID,_playerID],"Logistics","ACKNOWLEDGED"] call ALIVE_fnc_event;
                        [ALIVE_eventLog, "addEvent",_logEvent] call ALIVE_fnc_eventLog;

                    };


                    //["FORCE MAKEUP AFTER: %1 FORCE MAKEUP TOTAL: %2", _eventForceMakeup, _forceMakeupTotal] call ALIVE_fnc_dump;
                    //_event call ALIVE_fnc_inspectHash;

                    if(_forceMakeupTotal > 0) then {

                        // set the time the event was received
                        [_event, "time", time] call ALIVE_fnc_hashSet;

                        // set the state data array of the event
                        [_event, "stateData", []] call ALIVE_fnc_hashSet;

                        // set the profiles array of the event
                        [_event, "cargoProfiles", [] call ALIVE_fnc_hashCreate] call ALIVE_fnc_hashSet;
                        [_event, "transportProfiles", []] call ALIVE_fnc_hashSet;
                        [_event, "transportVehiclesProfiles", []] call ALIVE_fnc_hashSet;
                        [_event, "playerRequestProfiles", [] call ALIVE_fnc_hashCreate] call ALIVE_fnc_hashSet;

                        [_event, "finalDestination", []] call ALIVE_fnc_hashSet;

                        [_event, "eventAssets", []] call ALIVE_fnc_hashSet;

                        // -----------------------------------------------------------------
                        // FIX: Reserve force pool immediately at request receipt to prevent
                        // burst requests all passing the pool check before any deduction.
                        // We deduct _forceMakeupTotal as a reservation. The actual profile
                        // creation may produce a different count, which is reconciled in
                        // monitorEvent by deducting the true count and refunding the
                        // reservation difference.
                        // -----------------------------------------------------------------
                        private _reservationAmount = _forceMakeupTotal;
                        if(_eventType != "PR_STANDARD" && _eventType != "PR_AIRDROP" && _eventType != "PR_HELI_INSERT") then {
                            private _registryID = [_logic, "registryID"] call MAINCLASS;
                            _forcePool = _forcePool - _reservationAmount;
                            [ALIVE_MLGlobalRegistry,"updateGlobalForcePool",[_registryID,_forcePool]] call ALIVE_fnc_MLGlobalRegistry;
                            [_event, "poolReservation", _reservationAmount] call ALIVE_fnc_hashSet;

                            if(_debug) then {
                                ["ML - LOGCOM_REQUEST: Reserved %1 from force pool. Remaining pool: %2",
                                    _reservationAmount, _forcePool] call ALiVE_fnc_dump;
                            };
                        } else {
                            [_event, "poolReservation", 0] call ALIVE_fnc_hashSet;
                        };
                        // -----------------------------------------------------------------

                        // store the event on the event queue
                        _eventQueue = [_logic, "eventQueue"] call MAINCLASS;
                        [_eventQueue, _eventID, _event] call ALIVE_fnc_hashSet;


                        // DEBUG -------------------------------------------------------------------------------------
                        if(_debug) then {
                            ["ML - Reinforce event received"] call ALiVE_fnc_dump;
                            ["ML - Current force pool for side: %2 available: %3", _side, _forcePool] call ALiVE_fnc_dump;
                            _event call ALIVE_fnc_inspectHash;
                        };
                        // DEBUG -------------------------------------------------------------------------------------


                        // trigger analysis
                        [_logic,"onDemandAnalysis"] call MAINCLASS;


                    }else{

                        // nothing left after non allowed types ruled out

                    };

                }else{


                    // DEBUG -------------------------------------------------------------------------------------
                    if(_debug) then {
                        ["ML - Reinforce event denied, force pool for side: %1 exhausted : %2", _side, _forcePool] call ALiVE_fnc_dump;
                    };
                    // DEBUG -------------------------------------------------------------------------------------


                    _eventID = [_event, "id"] call ALIVE_fnc_hashGet;
                    _eventData = [_event, "data"] call ALIVE_fnc_hashGet;
                    _eventForceMakeup = _eventData select 3;
                    _eventType = _eventData select 4;

                    if(_eventType == "PR_STANDARD" || _eventType == "PR_AIRDROP" || _eventType == "PR_HELI_INSERT") then {

                        _playerID = _eventData select 5;
                        _requestID = _eventForceMakeup select 0;

                        // respond to player request
                        _logEvent = ['LOGCOM_RESPONSE', [_requestID,_playerID],"Logistics","DENIED_FORCEPOOL"] call ALIVE_fnc_event;
                        [ALIVE_eventLog, "addEvent",_logEvent] call ALIVE_fnc_eventLog;

                    };


                };

            }else{

                // faction not handled by this module, ignored..

            };

        };
    };

    case "onDemandAnalysis": {
        private["_debug","_analysisInProgress","_type","_forcePoolType","_registryID","_forcePool","_objectives"];

        if (isServer) then {

            _debug = [_logic, "debug"] call MAINCLASS;
            _analysisInProgress = _logic getVariable ["analysisInProgress", false];

            // if analysis not already underway
            if!(_analysisInProgress) then {

                _logic setVariable ["analysisInProgress", true];

                _type = [_logic, "type"] call MAINCLASS;
                _forcePoolType = [_logic, "forcePoolType"] call MAINCLASS;
                _registryID = [_logic, "registryID"] call MAINCLASS;
                _forcePool = [ALIVE_globalForcePool,_eventFaction] call ALIVE_fnc_hashGet;
                if(typeName _forcePool == "STRING") then {
                    _forcePool = parseNumber _forcePool;
                };

                _objectives = [_logic, "objectives"] call MAINCLASS;
                _objectives = _objectives select 0;


                // DEBUG -------------------------------------------------------------------------------------
                if(_debug) then {
                    ["ML - On demand dynamic analysis started"] call ALiVE_fnc_dump;
                };
                // DEBUG -------------------------------------------------------------------------------------


                private["_reserve","_tacom_state","_priorityTotal","_priority"];

                _reserve = [];
                _priorityTotal = 0;

                // sort OPCOM objective states to find
                // reserved objectives
                {
                    _tacom_state = '';
                    if("tacom_state" in (_x select 1)) then {
                        _tacom_state = [_x,"tacom_state","none"] call ALIVE_fnc_hashGet;
                    };

                    switch(_tacom_state) do {
                        case "reserve":{

                            // increase the priority count by adding
                            // all held objective priorities
                            _priority = [_x,"priority"] call ALIVE_fnc_hashGet;
                            _priorityTotal = _priorityTotal + _priority;

                            // store the objective
                            _reserve pushback _x;
                        };
                    };

                } forEach _objectives;

                private["_previousReinforcementAnalysis","_previousReinforcementAnalysisPriorityTotal"];

                _previousReinforcementAnalysis = [_logic, "reinforcementAnalysis"] call MAINCLASS;

                // if the force pool type is dynamic
                // calculate the new pool
                if(_forcePoolType == "DYNAMIC") then {

                    //["DYNAMIC FORCE POOL"] call ALIVE_fnc_dump;
                    //["CURRENT FORCE POOL: %1",_forcePool] call ALIVE_fnc_dump;

                    // if there is a previous analysis
                    if(count _previousReinforcementAnalysis > 0) then {

                        //["PREVIOUS ANALYSIS FOUND"] call ALIVE_fnc_dump;

                        _previousReinforcementAnalysisPriorityTotal = [_previousReinforcementAnalysis, "priorityTotal"] call ALIVE_fnc_hashGet;

                        // if the current priority total is greater
                        // than the previous priority total
                        // objectives have been captured
                        // increase the available pool
                        if(_priorityTotal > _previousReinforcementAnalysisPriorityTotal) then {

                            //["CURRENT PRIORITY TOTAL IS GREATER THAN PREVIOUS"] call ALIVE_fnc_dump;

                            _forcePool = _forcePool + (_priorityTotal - _previousReinforcementAnalysisPriorityTotal);

                        }else{

                            if(_priorityTotal < _previousReinforcementAnalysisPriorityTotal) then {

                                // objectives have been lost
                                // reduce the force pool

                                if(_forcePool > 0) then {

                                    //["CURRENT PRIORITY TOTAL IS LESS THAN PREVIOUS"] call ALIVE_fnc_dump;

                                    _forcePool = _forcePool - (_previousReinforcementAnalysisPriorityTotal - _priorityTotal);

                                };

                            };

                        };

                    }else{

                        //["NO PREVIOUS ANALYSIS"] call ALIVE_fnc_dump;

                        // set the force pool as the
                        // current total
                        _forcePool = _priorityTotal;

                    };

                    // update the global force pool
                    [ALIVE_MLGlobalRegistry,"updateGlobalForcePool",[_registryID,_forcePool]] call ALIVE_fnc_MLGlobalRegistry;

                };


                private["_primaryReinforcementObjective","_reinforcementType","_sortedClusters",
                "_sortedObjectives","_primaryReinforcementObjectivePriority","_reinforcementAnalysis",
                "_previousPrimaryObjective","_available"];

                _primaryReinforcementObjective = [] call ALIVE_fnc_hashCreate;
                _reinforcementType = "";
                _available = false;

                if(_type == "STATIC") then {

                    // Static analysis, only one insertion point
                    // may be held. This point is dictated
                    // by the placement location
                    // once lost the insertion point is
                    // deactivated until recaptured

                    // if there is no previous analysis
                    if(count _previousReinforcementAnalysis == 0) then {

                        if(count _objectives > 0) then {

                            // sort objectives by distance to module
                            _sortedObjectives = [_objectives,[],{(position _logic) distance (_x select 2 select 1)},"DESCEND"] call ALiVE_fnc_SortBy;

                            // get the highest priority objective
                            _primaryReinforcementObjective = _sortedObjectives select ((count _sortedObjectives)-1);

                            // Preliminary type - deferred to case "requested" where
                            // route, terrain and asset data are available
                            _reinforcementType = "HELI";

                            if (_debug) then {
                                ["ML - onDemandAnalysis (STATIC): Preliminary type HELI (deferred to requested for final decision)."] call ALiVE_fnc_dump;
                            };

                            // Check if objective is held (available for use)
                            _tacom_state = '';
                            if("tacom_state" in (_primaryReinforcementObjective select 1)) then {
                                _tacom_state = [_primaryReinforcementObjective,"tacom_state","none"] call ALIVE_fnc_hashGet;
                            };
                            if(_tacom_state == "reserve") then { _available = true; };
                            
                            
                        // -----------------------------------------------------------------
                        // NEW: Single objective guard - if there is only one reserved
                        // objective it is simultaneously the insertion point AND the
                        // destination, which means helicopters fly units nowhere.
                        // When this is detected, find the nearest enemy-contested or
                        // uncontrolled mil cluster to use as the actual delivery target
                        // instead, so units are sent somewhere useful.
                        // -----------------------------------------------------------------
                        if (count _reserve == 1) then {

                            private _insertionPos = [_primaryReinforcementObjective, "center"] call ALIVE_fnc_hashGet;

                            if (_debug) then {
                                ["ML - onDemandAnalysis: Single reserved objective detected at %1. Searching for frontline destination.",
                                    _insertionPos] call ALiVE_fnc_dump;
                            };

                            private _frontlineObjective = nil;
                            private _frontlineDist = 0;

                            // First preference: look for objectives OPCOM does not currently hold
                            // sorted by distance from the insertion point - closest contested
                            // objective is the most tactically relevant destination
                            if (count _objectives > 0) then {

                                private _nonReserveObjectives = _objectives select {
                                    private _objState = "";
                                    if ("tacom_state" in (_x select 1)) then {
                                        _objState = [_x, "tacom_state", "none"] call ALIVE_fnc_hashGet;
                                    };
                                    // Include objectives that are being attacked or are unassigned
                                    // but exclude our own reserve (held) objectives
                                    _objState != "reserve"
                                };

                                if (_debug) then {
                                    ["ML - onDemandAnalysis: Found %1 non-reserve objectives as potential destinations",
                                        count _nonReserveObjectives] call ALiVE_fnc_dump;
                                };

                                if (count _nonReserveObjectives > 0) then {

                                    // Sort by distance from insertion point ascending
                                    // so we pick the closest frontline objective
                                    private _sortedFrontline = [
                                        _nonReserveObjectives, [],
                                        {(_insertionPos distance ([_x, "center"] call ALIVE_fnc_hashGet))},
                                        "ASCEND"
                                    ] call ALiVE_fnc_SortBy;

                                    private _candidate = _sortedFrontline select 0;
                                    private _candidateDist = _insertionPos distance ([_candidate, "center"] call ALIVE_fnc_hashGet);

                                    // Only use if meaningfully far from insertion point
                                    // (avoids swapping to an objective that is essentially
                                    // co-located with the base)
                                    if (_candidateDist > 500) then {
                                        _frontlineObjective = _candidate;
                                        _frontlineDist = _candidateDist;

                                        if (_debug) then {
                                            ["ML - onDemandAnalysis: Using non-reserve objective as destination. Distance: %1m",
                                                _frontlineDist] call ALiVE_fnc_dump;
                                        };
                                    } else {
                                        if (_debug) then {
                                            ["ML - onDemandAnalysis: Closest non-reserve objective too close (%1m), falling back to mil clusters.",
                                                _candidateDist] call ALiVE_fnc_dump;
                                        };
                                    };
                                };
                            };

                            // Second preference: if no suitable OPCOM objective found,
                            // fall back to mil clusters sorted by distance from insertion
                            if (isNil "_frontlineObjective" || {_frontlineDist <= 500}) then {

                                if (count(ALIVE_clustersMil select 2) > 0) then {

                                    private _sortedMilClusters = [
                                        ALIVE_clustersMil select 2, [],
                                        {(_insertionPos distance ([_x, "center"] call ALIVE_fnc_hashGet))},
                                        "ASCEND"
                                    ] call ALiVE_fnc_SortBy;

                                    // Walk through sorted clusters to find one that is
                                    // far enough away to be a meaningful destination
                                    {
                                        private _clusterDist = _insertionPos distance ([_x, "center"] call ALIVE_fnc_hashGet);
                                        if (_clusterDist > 500) exitWith {
                                            _frontlineObjective = _x;
                                            _frontlineDist = _clusterDist;
                                        };
                                    } forEach _sortedMilClusters;

                                    if (_debug) then {
                                        if (!isNil "_frontlineObjective" && {_frontlineDist > 500}) then {
                                            ["ML - onDemandAnalysis: Using mil cluster as destination. Distance: %1m",
                                                _frontlineDist] call ALiVE_fnc_dump;
                                        } else {
                                            ["ML - onDemandAnalysis: WARNING - No suitable mil cluster found beyond 500m. Keeping original destination."] call ALiVE_fnc_dump;
                                        };
                                    };
                                };
                            };

                            // Apply the frontline objective as the primary reinforcement
                            // destination if we found a valid one
                            if (!isNil "_frontlineObjective" && {_frontlineDist > 500}) then {
                                _primaryReinforcementObjective = _frontlineObjective;

                                // Recalculate reinforcement type based on distance
                                // Long distances favour air delivery, short favour ground
                                _reinforcementType = switch (true) do {
                                    case (_frontlineDist > 3000): { "AIR" };
                                    case (_frontlineDist > 1500): { "HELI" };
                                    default { "DROP" };
                                };

                                ["ML - onDemandAnalysis: Single objective scenario resolved. Destination set to frontline at %1m. Type: %2",
                                    _frontlineDist, _reinforcementType] call ALiVE_fnc_dump;
                            } else {
                                ["ML - onDemandAnalysis: WARNING - Could not resolve single objective scenario. Units may be delivered to insertion point."] call ALiVE_fnc_dump;
                            };
                        };
                        // -----------------------------------------------------------------
                        // END single objective guard
                        // -----------------------------------------------------------------

                        }else{

                            // no objectives nothing available
                            _available = false;
                        };

                    }else{

                        // there is previous analysis

                        _primaryReinforcementObjective = [_previousReinforcementAnalysis, "primary"] call ALIVE_fnc_hashGet;
                        _reinforcementType = [_previousReinforcementAnalysis, "type"] call ALIVE_fnc_hashGet;

                        // if the state of the objective is reserved
                        // objective is available for use
                        _tacom_state = '';
                        if("tacom_state" in (_primaryReinforcementObjective select 1)) then {
                            _tacom_state = [_primaryReinforcementObjective,"tacom_state","none"] call ALIVE_fnc_hashGet;
                        };

                        if(_tacom_state == "reserve") then {
                            _available = true;
                        };

                    };

                }else{

                    _available = true;

                    // Dynamic analysis, primary insertion objective
                    // will fall back to held objectives, finally
                    // falling back to non held marine or bases

                    if(count _reserve > 0) then {

                        // OPCOM controls some objectives
                        // reinforcements can be delivered
                        // directly assuming heli pads or
                        // airstrips are available


                        // sort reserved objectives by priority
                        _sortedObjectives = [_reserve,[],{([_x, "priority"] call ALIVE_fnc_hashGet)},"ASCEND"] call ALiVE_fnc_SortBy;

                        // get the highest priority objective
                        _primaryReinforcementObjective = _sortedObjectives select ((count _sortedObjectives)-1);

                        // Preliminary type - final decision is made in case "requested"
                        // where route distance, water, force composition and air asset
                        // availability are all known. Set HELI as the default preferred
                        // type when OPCOM holds objectives; requested will override to
                        // STANDARD if conditions don't support helicopter delivery.
                        _reinforcementType = "HELI";

                        if (_debug) then {
                            ["ML - onDemandAnalysis: Preliminary type HELI (deferred to requested for final decision based on route/assets)."] call ALiVE_fnc_dump;
                        };


                    }else{

                        // OPCOM controls no objectives
                        // reinforcements must be delivered
                        // via paradrops and or marine landings
                        // near to location of any existing troops

                        // randomly pick between marine and mil location for start position
                        if(random 1 > 0.5) then {

                            if(count(ALIVE_clustersCivMarine select 2) > 0) then {

                                // there are marine objectives available

                                // pick a primary one
                                _primaryReinforcementObjective = selectRandom (ALIVE_clustersCivMarine select 2);

                                _reinforcementType = "MARINE";

                            }else{

                                // no marine objectives available
                                // pick a low priority location for airdrops

                                if(count(ALIVE_clustersMil select 2) > 0) then {

                                    _sortedClusters = [ALIVE_clustersMil select 2,[],{([_x, "priority"] call ALIVE_fnc_hashGet)},"DESCEND"] call ALiVE_fnc_SortBy;

                                    // get the highest priority objective
                                    _primaryReinforcementObjective = _sortedClusters select ((count _sortedClusters)-1);

                                    _reinforcementType = "AIR";

                                };

                            };

                        }else{

                            // pick a low priority location for airdrops

                            if(count(ALIVE_clustersMil select 2) > 0) then {

                                _sortedClusters = [ALIVE_clustersMil select 2,[],{([_x, "priority"] call ALIVE_fnc_hashGet)},"DESCEND"] call ALiVE_fnc_SortBy;

                                // get the highest priority objective
                                _primaryReinforcementObjective = _sortedClusters select ((count _sortedClusters)-1);

                                _reinforcementType = "AIR";

                            };

                        };

                    };
                };

                // store the analysis results
                _reinforcementAnalysis = [] call ALIVE_fnc_hashCreate;
                [_reinforcementAnalysis, "priorityTotal", _priorityTotal] call ALIVE_fnc_hashSet;
                [_reinforcementAnalysis, "type", _reinforcementType] call ALIVE_fnc_hashSet;
                [_reinforcementAnalysis, "available", _available] call ALIVE_fnc_hashSet;
                [_reinforcementAnalysis, "primary", _primaryReinforcementObjective] call ALIVE_fnc_hashSet;

                [_logic, "reinforcementAnalysis", _reinforcementAnalysis] call MAINCLASS;

                // DEBUG -------------------------------------------------------------------------------------
                if(_debug) then {
                    ["ML - On demand analysis complete"] call ALiVE_fnc_dump;
                    ["ML - Priority total: %1",_priorityTotal] call ALiVE_fnc_dump;
                    ["ML - Reinforcement type: %1",_reinforcementType] call ALiVE_fnc_dump;
                    ["ML - Primary reinforcement objective available: %1",_available] call ALiVE_fnc_dump;
                    ["ML - Primary reinforcement objective:"] call ALiVE_fnc_dump;
                    _primaryReinforcementObjective call ALIVE_fnc_inspectHash;
                };
                // DEBUG -------------------------------------------------------------------------------------


                _logic setVariable ["analysisInProgress", false];
            };
        };
    };

    case "monitor": {
        if (isServer) then {

            // spawn monitoring loop

            [_logic] spawn {

                private ["_logic","_debug"];

                _logic = _this select 0;
                _debug = [_logic, "debug"] call MAINCLASS;


                // DEBUG -------------------------------------------------------------------------------------
                if(_debug) then {
                    ["ML - Monitoring loop started"] call ALiVE_fnc_dump;
                };
                // DEBUG -------------------------------------------------------------------------------------


                waituntil {

                    sleep (10);

                    if!([_logic, "pause"] call MAINCLASS) then {

                        private ["_reinforcementAnalysis","_analysisInProgress","_eventQueue"];

                        _reinforcementAnalysis = [_logic, "reinforcementAnalysis"] call MAINCLASS;

                        // analysis has run
                        if(count _reinforcementAnalysis > 0) then {

                            _analysisInProgress = _logic getVariable ["analysisInProgress", false];

                            // if analysis not processing
                            if!(_analysisInProgress) then {

                                // loop the event queue
                                // and manage each event
                                _eventQueue = [_logic, "eventQueue"] call MAINCLASS;

                                if((count (_eventQueue select 2)) > 0) then {

                                    {
                                        [_logic,"monitorEvent",[_x, _reinforcementAnalysis]] call MAINCLASS;
                                    } forEach (_eventQueue select 2);

                                };

                            };

                        };

                    };

                    false
                };

            };

        };
    };

    case "monitorEvent": {

        private _debug = [_logic, "debug"] call MAINCLASS;
        private _registryID = [_logic, "registryID"] call MAINCLASS;
        private _event = _args select 0;
        private _reinforcementAnalysis = _args select 1;

        private _side = [_logic, "side"] call MAINCLASS;
        private _eventQueue = [_logic, "eventQueue"] call MAINCLASS;

        private _enableAirTransport = [_logic, "enableAirTransport"] call MAINCLASS;
        private _limitTransportToFaction = [_logic, "limitTransportToFaction"] call MAINCLASS;

        private _eventID = [_event, "id"] call ALIVE_fnc_hashGet;
        private _eventData = [_event, "data"] call ALIVE_fnc_hashGet;
        private _eventTime = [_event, "time"] call ALIVE_fnc_hashGet;
        private _eventState = [_event, "state"] call ALIVE_fnc_hashGet;
        private _eventStateData = [_event, "stateData"] call ALIVE_fnc_hashGet;
        private _eventCargoProfiles = [_event, "cargoProfiles"] call ALIVE_fnc_hashGet;
        private _eventTransportProfiles = [_event, "transportProfiles"] call ALIVE_fnc_hashGet;
        private _eventTransportVehiclesProfiles = [_event, "transportVehiclesProfiles"] call ALIVE_fnc_hashGet;
        private _playerRequested = [_event, "playerRequested"] call ALIVE_fnc_hashGet;
        private _playerRequestProfiles = [_event, "playerRequestProfiles"] call ALIVE_fnc_hashGet;

        private _reinforcementPriorityTotal = [_reinforcementAnalysis, "priorityTotal"] call ALIVE_fnc_hashGet;
        private _reinforcementType = [_reinforcementAnalysis, "type"] call ALIVE_fnc_hashGet;
        private _reinforcementAvailable = [_reinforcementAnalysis, "available"] call ALIVE_fnc_hashGet;
        private _reinforcementPrimaryObjective = [_reinforcementAnalysis, "primary"] call ALIVE_fnc_hashGet;

        private _eventPosition = _eventData select 0;
        private _eventFaction = _eventData select 1;
        private _eventSide = _eventData select 2;
        private _eventForceMakeup = _eventData select 3;
        private _eventType = _eventData select 4;

        private _forcePool = [ALIVE_globalForcePool,_eventFaction] call ALIVE_fnc_hashGet;

        private [
            "_playerID","_requestID","_payload","_emptyVehicles","_staticIndividuals","_joinIndividuals","_reinforceIndividuals","_staticGroups","_joinGroups","_reinforceGroups",
            "_eventForceInfantry","_eventForceMotorised","_eventForceMechanised","_eventForceArmour","_eventForcePlane","_eventForceHeli"
        ];

        if(_playerRequested) then {

            _playerID = _eventData select 5;
            _requestID = _eventForceMakeup select 0;
            _payload = _eventForceMakeup select 1;
            _emptyVehicles = _eventForceMakeup select 2;
            _staticIndividuals = _eventForceMakeup select 3;
            _joinIndividuals = _eventForceMakeup select 4;
            _reinforceIndividuals = _eventForceMakeup select 5;
            _staticGroups = _eventForceMakeup select 6;
            _joinGroups = _eventForceMakeup select 7;
            _reinforceGroups = _eventForceMakeup select 8;

        }else{

            _eventForceInfantry = _eventForceMakeup select 0;
            _eventForceMotorised = _eventForceMakeup select 1;
            _eventForceMechanised = _eventForceMakeup select 2;
            _eventForceArmour = _eventForceMakeup select 3;
            _eventForcePlane = _eventForceMakeup select 4;
            _eventForceHeli = _eventForceMakeup select 5;

        };

        // DEBUG -------------------------------------------------------------------------------------
        if(_debug) then {
            ["ML - Monitoring Event"] call ALiVE_fnc_dump;
            _event call ALIVE_fnc_inspectHash;
            //_reinforcementAnalysis call ALIVE_fnc_inspectHash;
        };
        // DEBUG -------------------------------------------------------------------------------------

        private "_logEvent";

        // react according to current event state
        switch(_eventState) do {

            // AI REQUEST ---------------------------------------------------------------------------------------------------------------------------------

            // the units have been requested
            // spawn the units at the insertion point
            case "requested": {

                private ["_waitTime"];

                // Wait time before spawning profiles.
                // Use helicopter wait time as default since that is the preferred
                // delivery method; the decision logic below will select STANDARD
                // if conditions don't support helicopter insertion.
                private _waitTime = WAIT_TIME_HELI;


                // DEBUG -------------------------------------------------------------------------------------
                if(_debug) then {
                    ["ML - Event state: %1 event timer: %2 wait time on event: %3 ",_eventState, (time - _eventTime), _waitTime] call ALiVE_fnc_dump;
                };
                // DEBUG -------------------------------------------------------------------------------------


                // if the reinforcement objective is
                // not available, cancel the event

                if(_reinforcementAvailable) then {

                    if((time - _eventTime) > _waitTime) then {

                        private ["_reinforcementPosition","_playersInRange","_paraDrop","_remotePosition","_airTrans","_noHeavy","_slingAvailable","_water","_AA","_newPos","_routeDistance","_routeDirection"];

                        // Override delivery mechanism if there is water or AA or armored vehicles required
                        _noHeavy = _eventForceMechanised == 0 && _eventForceArmour == 0;

                        _water = false; // water is in the way

                        // Check route
                        _routeDistance = _eventPosition distance ([_reinforcementPrimaryObjective,"center"] call ALIVE_fnc_hashGet);
                        _routeDirection = (_eventPosition getDir ([_reinforcementPrimaryObjective,"center"] call ALIVE_fnc_hashGet));
                        _newPos = _eventPosition;
                        for "_i" from 0 to _routeDistance step 20 do {
                            _newPos = _newPos getpos [20, _routeDirection];
                            if (surfaceIsWater _newPos) exitWith {_water = true;};
                        };

                        _slingAvailable = false; // slingloading is available as a service
                        _airTrans = [];

                        if (_enableAirTransport) then {
                            _airTrans = [ALIVE_factionDefaultAirTransport,_eventFaction,[]] call ALIVE_fnc_hashGet;
                            if(count _airTrans == 0 && !_limitTransportToFaction) then {
                                 _airTrans = [ALIVE_sideDefaultAirTransport,_side] call ALIVE_fnc_hashGet;
                            };
                            // Check helicopters can slingload
                            {
                                _slingAvailable = [(configFile >> "CfgVehicles" >> _x >> "slingLoadMaxCargoMass"), 0] call ALiVE_fnc_getConfigValue > 1000;
                                if (_slingAvailable) exitWith {};
                            } foreach  _airTrans;
                        };

                        // ---------------------------------------------------------------
                        // DELIVERY TYPE DECISION
                        // Makes the authoritative delivery type decision using all
                        // available data: force composition, route terrain, distance,
                        // and air asset availability.
                        //
                        // Decision order (highest to lowest precedence):
                        // 1. Heavy vehicles requested -> STANDARD (can't be helicoptered)
                        // 2. No air transport assets  -> STANDARD
                        // 3. Distance is 0 (single held objective, destination unknown yet)
                        //    -> HELI_INSERT so findBestDeliveryObjective can score a real target
                        // 4. Water on route           -> HELI_INSERT (if assets available)
                        // 5. Short distance (<1500m)  -> STANDARD (ground is faster/cheaper)
                        // 6. Distance >=1500m         -> HELI_INSERT
                        // ---------------------------------------------------------------

                        // Rule 1: Heavy vehicles cannot be helicoptered
                        if (!_noHeavy) then {
                            _eventType = "STANDARD";
                            if (_debug) then {
                                ["ML - Delivery type: STANDARD (heavy vehicles requested, distance %1m)", _routeDistance] call ALiVE_fnc_dump;
                            };
                        } else {
                            // Rule 2: No air assets available - must go by ground
                            if (count _airTrans == 0) then {
                                _eventType = "STANDARD";
                                if (_debug) then {
                                    ["ML - Delivery type: STANDARD (no air transport assets available)"] call ALiVE_fnc_dump;
                                };
                            } else {
                                // Rule 3: Zero distance means departure base = destination (single objective)
                                // Let HELI_INSERT path score a proper frontline target
                                if (_routeDistance < 1) then {
                                    _eventType = "HELI_INSERT";
                                    if (_debug) then {
                                        ["ML - Delivery type: HELI_INSERT (single objective scenario, deferring destination to scoring)"] call ALiVE_fnc_dump;
                                    };
                                } else {
                                    // Rule 4: Water on route forces helicopter regardless of distance
                                    if (_water) then {
                                        _eventType = "HELI_INSERT";
                                        if (_debug) then {
                                            ["ML - Delivery type: HELI_INSERT (water obstacle on route, distance %1m)", _routeDistance] call ALiVE_fnc_dump;
                                        };
                                    } else {
                                        // Rules 5-6: Distance-based selection
                                        if (_routeDistance < 1500) then {
                                            _eventType = "STANDARD";
                                            if (_debug) then {
                                                ["ML - Delivery type: STANDARD (short distance %1m, ground preferred)", _routeDistance] call ALiVE_fnc_dump;
                                            };
                                        } else {
                                            _eventType = "HELI_INSERT";
                                            if (_debug) then {
                                                ["ML - Delivery type: HELI_INSERT (distance %1m, helicopter preferred)", _routeDistance] call ALiVE_fnc_dump;
                                            };
                                        };
                                    };
                                };
                            };
                        };

                        // Both STANDARD and HELI_INSERT depart from a held objective
                        _reinforcementPosition = [_reinforcementPrimaryObjective,"center"] call ALIVE_fnc_hashGet;

                        ["AI LOGCOM Side: %1 Type: %2 From: %3 To: %4 Dist: %5m Water: %6 Heavy: %7",
                            _side, _eventType, _reinforcementPosition, _eventPosition,
                            round _routeDistance, _water, !_noHeavy] call ALiVE_fnc_dump;

                        // if heli insert allow only air and
                        // infantry groups & Motorized
                        if(_eventType == "HELI_INSERT") then {
                            _eventForceMechanised = 0;
                            _eventForceArmour = 0;
                        };

                        // players near check

                        _playersInRange = [_reinforcementPosition, 500] call ALiVE_fnc_anyPlayersInRange;

                        // if players are in visible range
                        // para drop groups instead of
                        // spawning on the ground

                        _paraDrop = false;
                        if(_playersInRange > 0) then {
                            _paraDrop = true;
                            _remotePosition = [_reinforcementPosition, 2000] call ALIVE_fnc_getPositionDistancePlayers;
                        };

                        // -----------------------------------------------------------------
                        // -----------------------------------------------------------------
                        // HELI_INSERT departure base and destination selection.
                        //
                        // Rules:
                        // 1. Helicopters must depart from a friendly held objective
                        //    that is DIFFERENT from the delivery destination.
                        // 2. If only one friendly objective is held, helicopter
                        //    insertion is not tactically viable - cancel and do nothing.
                        //    Do NOT substitute another delivery type.
                        // 3. If multiple friendly objectives exist, pick the one
                        //    furthest from the destination as the departure base
                        //    so helicopters fly the longest meaningful route.
                        // 4. Override the delivery destination with the best scored
                        //    objective from findBestDeliveryObjective.
                        // -----------------------------------------------------------------
                        if (_eventType == "HELI_INSERT") then {

                            // Get all friendly held objectives
                            private _allObjectives = [_logic, "objectives"] call MAINCLASS;
                            if (count _allObjectives > 0) then {
                                _allObjectives = _allObjectives select 0;
                            };

                            // Validate held objectives using multiple criteria:
                            // 1. tacom_state must be "reserve" (OPCOM assignment)
                            // 2. At least one assigned section profile must still exist
                            //    (confirms OPCOM units haven't been wiped out)
                            // 3. No more than 3 enemy units within 300m
                            //    (confirms not currently enemy-occupied)
                            private _heldObjectives = [];
                            {
                                private _obj = _x;
                                private _objState = "";
                                if ("tacom_state" in (_obj select 1)) then {
                                    _objState = [_obj, "tacom_state", "none"] call ALIVE_fnc_hashGet;
                                };

                                if (_objState == "reserve") then {

                                    // Check section profiles - at least one must still be registered
                                    private _section = [_obj, "section", []] call ALIVE_fnc_hashGet;
                                    private _hasAliveProfiles = false;
                                    if (count _section > 0) then {
                                        {
                                            private _profile = [ALIVE_profileHandler, "getProfile", _x] call ALIVE_fnc_profileHandler;
                                            if (!isNil "_profile") exitWith { _hasAliveProfiles = true; };
                                        } forEach _section;
                                    } else {
                                        // No section assigned yet - trust tacom_state alone
                                        _hasAliveProfiles = true;
                                    };

                                    if (_hasAliveProfiles) then {

                                        // Check for enemy presence near the objective
                                        private _objPos = [_obj, "center"] call ALIVE_fnc_hashGet;
                                        private _sideObj = [_side] call ALIVE_fnc_sideTextToObject;
                                        private _nearUnits = _objPos nearEntities [["Man","Car","Tank"], 300];
                                        private _enemyNear = _nearUnits select { side _x != _sideObj && side _x != civilian };

                                        if (count _enemyNear < 3) then {
                                            _heldObjectives pushback _obj;
                                        } else {
                                            if (_debug) then {
                                                ["ML - HELI_INSERT: Objective at %1 has tacom_state=reserve but %2 enemy units within 300m - treating as lost",
                                                    _objPos, count _enemyNear] call ALiVE_fnc_dump;
                                            };
                                        };

                                    } else {
                                        if (_debug) then {
                                            ["ML - HELI_INSERT: Objective at %1 has tacom_state=reserve but all section profiles gone - treating as lost",
                                                [_obj, "center"] call ALIVE_fnc_hashGet] call ALiVE_fnc_dump;
                                        };
                                    };
                                };
                            } forEach _allObjectives;

                            if (_debug) then {
                                ["ML - HELI_INSERT: Found %1 validated friendly held objectives (tacom_state=reserve, profiles alive, no enemy presence):",
                                    count _heldObjectives] call ALiVE_fnc_dump;
                                {
                                    private _objPos   = [_x, "center"] call ALIVE_fnc_hashGet;
                                    private _objID    = [_x, "objectiveID"] call ALIVE_fnc_hashGet;
                                    private _objState = [_x, "tacom_state", "none"] call ALIVE_fnc_hashGet;
                                    private _nearLocName = [_objPos] call ALIVE_fnc_taskGetNearestLocationName;
                                    ["ML - HELI_INSERT: Held objective %1 near %2 at %3 tacom_state=%4",
                                        _objID, _nearLocName, _objPos, _objState] call ALiVE_fnc_dump;

                                    // Temporary marker - auto-deletes after 3 minutes
                                    [_objPos, _objID] spawn {
                                        private _pos   = _this select 0;
                                        private _id    = _this select 1;
                                        private _mName = format ["ML_HELD_%1_%2", _id, time];
                                        private _m = createMarker [_mName, _pos];
                                        _m setMarkerShape "ICON";
                                        _m setMarkerType "mil_flag";
                                        _m setMarkerColor "ColorGreen";
                                        _m setMarkerSize [0.6, 0.6];
                                        _m setMarkerText format ["HELD: %1", _id];
                                        sleep 180;
                                        deleteMarker _mName;
                                    };
                                } forEach _heldObjectives;
                            };

                            // Rule 2: Fewer than 2 validated held objectives - heli insert
                            // not yet viable. Keep event in requested state and re-check
                            // next monitor cycle. Fall back to ground convoy after timeout.
                            if (count _heldObjectives <= 1) then {

                                private _heliWaitIterations = _eventStateData param [1, 0]; if (isNil "_heliWaitIterations" || typeName _heliWaitIterations != "SCALAR") then { _heliWaitIterations = 0; };
                                _heliWaitIterations = _heliWaitIterations + 1;
                                _eventStateData set [1, _heliWaitIterations];
                                [_event, "stateData", _eventStateData] call ALIVE_fnc_hashSet;
                                [_eventQueue, _eventID, _event] call ALIVE_fnc_hashSet;

                                // ~33 minutes at 10s monitor interval
                                private _heliWaitMax = 200;

                                if (_heliWaitIterations >= _heliWaitMax) then {
                                    ["ML - HELI_INSERT: Timeout waiting for valid held objectives (%1 cycles). Falling back to ground convoy for event %2.",
                                        _heliWaitIterations, _eventID] call ALiVE_fnc_dump;
                                    _eventType = "STANDARD";
                                    // Reset stateData so ground convoy path starts clean
                                    _eventStateData set [1, 0];
                                    [_event, "stateData", _eventStateData] call ALIVE_fnc_hashSet;
                                    // Fall through - _eventType is now STANDARD and will
                                    // be handled by the profile creation below
                                } else {
                                    if (_debug) then {
                                        ["ML - HELI_INSERT: Only %1 validated held objective(s). Waiting for more to be captured. Cycle %2/%3.",
                                            count _heldObjectives, _heliWaitIterations, _heliWaitMax] call ALiVE_fnc_dump;
                                    };
                                    // Exit this monitor cycle - re-evaluate next time
                                };

                            };

                            if (_eventType == "HELI_INSERT") then { // still heli after held check

                                // Held objectives check passed - clear that wait counter
                                if (count _eventStateData > 1) then {
                                    _eventStateData set [1, 0];
                                    [_event, "stateData", _eventStateData] call ALIVE_fnc_hashSet;
                                };

                                // Find the likely departure base (held obj furthest from event position)
                                // before scoring so we can exclude it from valid destinations.
                                // We re-run this selection properly after destination is confirmed.
                                private _candidateDeparturePos = [];
                                private _candidateMaxDist = 0;
                                {
                                    private _objPos = [_x, "center"] call ALIVE_fnc_hashGet;
                                    private _d = _objPos distance _eventPosition;
                                    if (_d > 500 && _d > _candidateMaxDist) then {
                                        _candidateMaxDist = _d;
                                        _candidateDeparturePos = _objPos;
                                    };
                                } forEach _heldObjectives;

                                // Rule 4: Find the best scored delivery destination,
                                // excluding both the insertion point and the likely departure base
                                private _scoredDestPos    = [];
                                private _scoredEnemyCount = 0;
                                private _scoredObjState   = "none";
                                if (count _allObjectives > 0) then {
                                    private _scoredResult = [_logic, "findBestDeliveryObjective", [
                                        _allObjectives,
                                        _eventPosition,
                                        _eventFaction,
                                        _side,
                                        _candidateDeparturePos
                                    ]] call MAINCLASS;
                                    _scoredDestPos    = _scoredResult select 0;
                                    _scoredEnemyCount = _scoredResult select 1;
                                    _scoredObjState   = _scoredResult select 2;
                                };

                                if (count _scoredDestPos > 0) then {
                                    private _scoredDist = _scoredDestPos distance _reinforcementPosition;

                                    if (_scoredDist > 500) then {
                                    if (_debug) then {
                                            private _destLocName = [_scoredDestPos] call ALIVE_fnc_taskGetNearestLocationName;
                                            ["ML - HELI_INSERT: Delivery destination set to scored objective near %1 at %2 (%3m from base)",
                                                _destLocName, _scoredDestPos, _scoredDist] call ALiVE_fnc_dump;
                                        };
                                        _eventPosition = _scoredDestPos;
                                        // Persist the updated destination into the event data
                                        // so all subsequent states (heliTransportStart etc.) use it
                                        _eventData set [0, _eventPosition];
                                        [_event, "data", _eventData] call ALIVE_fnc_hashSet;
                                        // Clear all heli wait counters so the guard doesn't
                                        // block profile creation on this and subsequent cycles
                                        _eventStateData set [1, 0];
                                        _eventStateData set [2, 0];
                                        _eventStateData set [3, 0];
                                        [_event, "stateData", _eventStateData] call ALIVE_fnc_hashSet;
                                    } else {
                                        // Scored destination too close to departure base -
                                        // treat as no valid destination found
                                        _scoredDestPos = [];
                                    };
                                };

                                // No valid delivery destination yet - wait for OPCOM to
                                // capture objectives before committing to heli insert.
                                if (count _scoredDestPos == 0) then {
                                    private _heliDestWaitIterations = _eventStateData param [2, 0]; if (isNil "_heliDestWaitIterations" || typeName _heliDestWaitIterations != "SCALAR") then { _heliDestWaitIterations = 0; };
                                    _heliDestWaitIterations = _heliDestWaitIterations + 1;
                                    _eventStateData set [2, _heliDestWaitIterations];
                                    [_event, "stateData", _eventStateData] call ALIVE_fnc_hashSet;
                                    [_eventQueue, _eventID, _event] call ALIVE_fnc_hashSet;

                                    private _heliDestWaitMax = 200;

                                    if (_heliDestWaitIterations >= _heliDestWaitMax) then {
                                        ["ML - HELI_INSERT: Timeout waiting for valid delivery destination (%1 cycles). Falling back to ground convoy for event %2.",
                                            _heliDestWaitIterations, _eventID] call ALiVE_fnc_dump;
                                        _eventType = "STANDARD";
                                        _eventStateData set [2, 0];
                                        [_event, "stateData", _eventStateData] call ALIVE_fnc_hashSet;
                                        // Fall through to profile creation as STANDARD
                                    } else {
                                        if (_debug) then {
                                            ["ML - HELI_INSERT: No valid delivery destination found yet. Waiting for objectives to be captured. Cycle %1/%2.",
                                                _heliDestWaitIterations, _heliDestWaitMax] call ALiVE_fnc_dump;
                                        };
                                        // Exit this monitor cycle - re-evaluate next time
                                    };
                                };

                                if (_eventType == "HELI_INSERT") then { // still heli after destination check

                                // Rule 1 and 3: Pick the held objective furthest from the
                                // delivery destination as the helicopter departure base.
                                // This gives the longest meaningful flight path.
                                private _departureObjective = nil;
                                private _maxDist = 0;

                                {
                                    private _objPos = [_x, "center"] call ALIVE_fnc_hashGet;
                                    private _distToDest = _objPos distance _eventPosition;

                                    // Must be a different location from the destination
                                    if (_distToDest > 500 && _distToDest > _maxDist) then {
                                        _maxDist = _distToDest;
                                        _departureObjective = _x;
                                    };
                                } forEach _heldObjectives;

                                if (isNil "_departureObjective") then {

                                    // All held objectives too close to destination - wait
                                    private _heliBaseWaitIterations = _eventStateData param [3, 0]; if (isNil "_heliBaseWaitIterations" || typeName _heliBaseWaitIterations != "SCALAR") then { _heliBaseWaitIterations = 0; };
                                    _heliBaseWaitIterations = _heliBaseWaitIterations + 1;
                                    _eventStateData set [3, _heliBaseWaitIterations];
                                    [_event, "stateData", _eventStateData] call ALIVE_fnc_hashSet;
                                    [_eventQueue, _eventID, _event] call ALIVE_fnc_hashSet;

                                    private _heliBaseWaitMax = 100;

                                    if (_heliBaseWaitIterations >= _heliBaseWaitMax) then {
                                        ["ML - HELI_INSERT: Timeout waiting for departure base far enough from destination (%1 cycles). Falling back to ground convoy for event %2.",
                                            _heliBaseWaitIterations, _eventID] call ALiVE_fnc_dump;
                                        _eventType = "STANDARD";
                                        _eventStateData set [3, 0];
                                        [_event, "stateData", _eventStateData] call ALIVE_fnc_hashSet;
                                    } else {
                                        if (_debug) then {
                                            ["ML - HELI_INSERT: No held objective far enough from destination for departure base. Waiting. Cycle %1/%2.",
                                                _heliBaseWaitIterations, _heliBaseWaitMax] call ALiVE_fnc_dump;
                                        };
                                        // Exit this monitor cycle - re-evaluate next time
                                    };

                                } else {


                                    // Override the reinforcement position with the
                                    // selected departure objective
                                    private _departurePos = [_departureObjective, "center"] call ALIVE_fnc_hashGet;

                                    if (_debug) then {
                                        private _baseLocName = [_departurePos] call ALIVE_fnc_taskGetNearestLocationName;
                                        private _dstLocName = [_eventPosition] call ALIVE_fnc_taskGetNearestLocationName;
                                        ["ML - HELI_INSERT: Departure base near %1 at %2 (%3m from destination). Destination near %4 at %5",
                                            _baseLocName, _departurePos, _maxDist, _dstLocName, _eventPosition] call ALiVE_fnc_dump;
                                    };

                                    // Update reinforcement position to the chosen departure base
                                    _reinforcementPosition = _departurePos;

                                    // Find a clear LZ at the departure base for helicopter spawning
                                    _remotePosition = [_logic, "prepareHelicopterLZ", [
                                        _reinforcementPosition getPos [random 200, random 360], 100
                                    ]] call MAINCLASS;

                                    if (_debug) then {
                                        ["ML - HELI_INSERT: Heli spawn LZ: %1 Departure base: %2 Destination: %3 Flight dist: %4m",
                                            _remotePosition, _reinforcementPosition, _eventPosition,
                                            _remotePosition distance _eventPosition] call ALiVE_fnc_dump;
                                    };

                                    // PARADROP vs INSERT decision
                                    if (_scoredEnemyCount > 0 || _scoredObjState in ["attack","capture"]) then {
                                        _eventType = "HELI_PARADROP";
                                        ["ML - HELI_PARADROP selected: enemy=%1 objState=%2 at destination.",
                                            _scoredEnemyCount, _scoredObjState] call ALiVE_fnc_dump;
                                    } else {
                                        if (_debug) then {
                                            ["ML - HELI_INSERT confirmed: enemy=%1 objState=%2 at destination. LZ clear.",
                                                _scoredEnemyCount, _scoredObjState] call ALiVE_fnc_dump;
                                        };
                                    };

                                }; // end departure base else

                                }; // end if (_eventType == "HELI_INSERT") destination check

                            }; // end if (_eventType == "HELI_INSERT") held check

                        } else {
                            if (!_paraDrop) then {
                                _remotePosition = _reinforcementPosition;
                            };
                        };
                        // -----------------------------------------------------------------


                        // Guard: if event is in a wait state (no destination or departure base
                        // found yet) or was cancelled, skip profile creation this cycle.
                        // The event remains in the queue with state="requested" and will be
                        // re-evaluated on the next monitor cycle.
                        private ["_activeCheck","_eventStillActive","_sd","_w1","_w2","_w3","_waitingForHeli"];
                        _activeCheck = [_eventQueue, _eventID] call ALIVE_fnc_hashGet;
                        _eventStillActive = !isNil "_activeCheck";
                        _sd = _eventStateData;
                        _w1 = _sd param [1, 0]; if (isNil "_w1" || typeName _w1 != "SCALAR") then { _w1 = 0; };
                        _w2 = _sd param [2, 0]; if (isNil "_w2" || typeName _w2 != "SCALAR") then { _w2 = 0; };
                        _w3 = _sd param [3, 0]; if (isNil "_w3" || typeName _w3 != "SCALAR") then { _w3 = 0; };
                        _waitingForHeli = _eventStillActive && ((_w1 > 0 && _w1 < 200) || (_w2 > 0 && _w2 < 200) || (_w3 > 0 && _w3 < 100));

                        if (_debug) then {
                            if (!_eventStillActive) then {
                                ["ML - requested: Event %1 was cancelled before profile creation, skipping.", _eventID] call ALiVE_fnc_dump;
                            } else {
                                if (_waitingForHeli) then {
                                    ["ML - requested: Event %1 waiting for valid heli conditions, skipping profile creation this cycle.", _eventID] call ALiVE_fnc_dump;
                                };
                            };
                        };

                        if (_eventStillActive && !_waitingForHeli) then {

                        // Throttle: limit concurrent HELI_INSERT missions to avoid
                        // flooding the AO with helicopters from the same destination
                        private _heliThrottleExceeded = false;
                        if (_eventType in ["HELI_INSERT","HELI_PARADROP"]) then {
                            private _activeHeliEvents = 0;
                            {
                                private _qEvent = _x;
                                private _qState = [_qEvent, "state"] call ALIVE_fnc_hashGet;
                                private _qID    = [_qEvent, "id"]    call ALIVE_fnc_hashGet;
                                private _qData  = [_qEvent, "data"]  call ALIVE_fnc_hashGet;
                                private _qType  = if (count _qData > 4) then { _qData select 4 } else { "" };
                                if (_qID != _eventID && _qType in ["HELI_INSERT","HELI_PARADROP"]) then {
                                    // Count both HELI_INSERT/HELI_PARADROP-specific states AND standard transport
                                    // states, since HELI_INSERT can fall back to the STANDARD path
                                    if (_qState in [
                                        "transportLoad","transportLoadWait","transportStart","transportTravel",
                                        "heliTransportStart","heliTransport","heliTransportUnloadWait",
                                        "heliTransportComplete","heliTransportReturn","heliTransportReturnWait",
                                        "heliParadropStart","heliParadropFly","heliParadropReturn","heliParadropReturnWait"
                                    ]) then {
                                        _activeHeliEvents = _activeHeliEvents + 1;
                                    };
                                };
                            } forEach (_eventQueue select 2);
                            if (_activeHeliEvents >= 2) then {
                                _heliThrottleExceeded = true;
                                if (_debug) then {
                                    ["ML - HELI_INSERT: Throttle active - %1 heli missions in cycle. Deferring event %2.",
                                        _activeHeliEvents, _eventID] call ALiVE_fnc_dump;
                                };
                            };
                        };

                        if (!_heliThrottleExceeded) then {

                        // wait time complete create profiles
                        // get groups according to requested force makeup

                        private ["_infantryGroups","_infantryProfiles","_transportGroups","_transportProfiles",
                        "_transportVehicleProfiles","_group","_groupCount","_totalCount","_vehicleClass",
                        "_profiles","_profileIDs","_profileID","_position"];

                        _groupCount = 0;
                        _totalCount = 0;

                        // motorised

                        private ["_motorisedGroups","_motorisedProfiles"];

                        _motorisedGroups = [];
                        _motorisedProfiles = [];

                        for "_i" from 0 to _eventForceMotorised -1 do {
                            private ["_group","_tempGroups"];
                            _tempGroups = [];
                            _group = ["Motorized",_eventFaction] call ALIVE_fnc_configGetRandomGroup;
                            if!(_group == "FALSE") then {
                                _tempGroups pushback _group;
                            };
                            _group = ["Motorized_MTP",_eventFaction] call ALIVE_fnc_configGetRandomGroup;
                            if!(_group == "FALSE") then {
                                _tempGroups pushback _group;
                            };
                            if (count _tempGroups > 0) then {
                                _group = selectRandom _tempGroups;
                                _motorisedGroups pushback _group;
                            };
                        };

                        _motorisedGroups = _motorisedGroups - ALiVE_PLACEMENT_GROUPBLACKLIST;
                        _groupCount = count _motorisedGroups;
                        _totalCount = _totalCount + _groupCount;

                        // FIX: Track skipped motorised groups
                        private _motorisedSkipped = 0;

                        for "_i" from 0 to _groupCount -1 do {

                            _group = _motorisedGroups select _i;

                            if (_eventType == "HELI_INSERT") then {
                                _position = [_logic, "prepareHelicopterLZ", [
                                    _reinforcementPosition getPos [random(200), random(360)], 60
                                ]] call MAINCLASS;
                                if (_debug) then {
                                    ["ML - HELI_INSERT motorised pickup LZ prepared at %1", _position] call ALiVE_fnc_dump;
                                };
                            } else {
                                _position = _reinforcementPosition getPos [random(200), random(360)];
                                if (_paraDrop && _eventType != "HELI_INSERT") then {
                                    _position set [2,PARADROP_HEIGHT];
                                };
                            };

                            if!(surfaceIsWater _position) then {

                                _profiles = [_group, _position, random(360), false, _eventFaction, true] call ALIVE_fnc_createProfilesFromGroupConfig;

                                _profileIDs = [];
                                {
                                    _profileID = _x select 2 select 4;
                                    _profileIDs pushback _profileID;
                                } forEach _profiles;

                                _motorisedProfiles pushback _profileIDs;

                            } else {
                                _groupCount = _groupCount - 1;
                                _totalCount = _totalCount - 1;
                                _motorisedSkipped = _motorisedSkipped + 1;

                                if (_debug) then {
                                    ["ML - Motorised group %1 skipped (water at position). Running skipped count: %2",
                                        _group, _motorisedSkipped] call ALiVE_fnc_dump;
                                };
                            };
                        };

                        if (_debug) then {
                            ["ML - Motorised groups created: %1 skipped: %2 profiles: %3",
                                _groupCount, _motorisedSkipped, count _motorisedProfiles] call ALiVE_fnc_dump;
                        };

                        // create profiles
                        for "_i" from 0 to _groupCount -1 do {

                            _group = _motorisedGroups select _i;

                            if (_eventType == "HELI_INSERT") then {
                                _position = [_logic, "prepareHelicopterLZ", [
                                    _reinforcementPosition getPos [random(200), random(360)], 60
                                ]] call MAINCLASS;
                                if (_debug) then {
                                    ["ML - HELI_INSERT motorised pickup LZ prepared at %1", _position] call ALiVE_fnc_dump;
                                };
                            } else {
                                _position = _reinforcementPosition getPos [random(200), random(360)];
                                if (_paraDrop && _eventType != "HELI_INSERT") then {
                                    _position set [2,PARADROP_HEIGHT];
                                };
                            };

                            if!(surfaceIsWater _position) then {

                                _profiles = [_group, _position, random(360), false, _eventFaction, true] call ALIVE_fnc_createProfilesFromGroupConfig;

                                _profileIDs = [];
                                {
                                    _profileID = _x select 2 select 4;
                                    _profileIDs pushback _profileID;
                                } forEach _profiles;

                                _motorisedProfiles pushback _profileIDs;

                            } else {
                                _groupCount = _groupCount - 1;
                                _totalCount = _totalCount - 1;
                            };
                        };

                        [_eventCargoProfiles, "motorised", _motorisedProfiles] call ALIVE_fnc_hashSet;

                        if(_debug) then {
                            ["ML - Profiles: %1 %2 %3 ", _eventForceMotorised, _motorisedGroups, _motorisedProfiles] call ALiVE_fnc_dump;
                        };

                        TRACE_1("ML HELI INSERT", _motorisedProfiles);

                        if(_eventType == "HELI_INSERT" && (count _motorisedProfiles > 0)) then {

                            // create heli transport vehicles for groups with vehicles

                            _transportGroups = [ALIVE_factionDefaultAirTransport,_eventFaction,[]] call ALIVE_fnc_hashGet;
                            _transportProfiles = [];
                            _transportVehicleProfiles = [];

                            _payloadGroupProfiles = [];

                            if(count _transportGroups == 0 || !_limitTransportToFaction) then {
                                _transportGroups append ([ALIVE_sideDefaultAirTransport,_side] call ALIVE_fnc_hashGet);
                            };

                            if(count _transportGroups > 0) then {

                                // If any of the vehicles cannot be airlifted, will need to switch to a standard delivery for vehicles
                                private _requiresStandardDelivery = false;

                                {
                                    _groupProfile = _x;

                                    {
                                        private ["_currentDiff","_vehicleClass","_position","_payloadWeight","_slingLoadProfile"];

                                        // Check to see if profile is a vehicle
                                        if ([_x,"vehicle"] call CBA_fnc_find != -1) then {

                                            // Get the profile
                                            _slingLoadProfile = [ALiVE_ProfileHandler, "getProfile", _x] call ALIVE_fnc_profileHandler;

                                            // _slingloadProfile call ALIVE_fnc_inspectHash;

                                            _payloadWeight = [(_slingLoadProfile select 2 select 11)] call ALIVE_fnc_getObjectWeight;

                                            // Select helicopter that can slingload the vehicle
                                            _vehicleClass = "";
                                            _currentDiff = 15000;
                                            {
                                                private ["_capacity","_slingloadmax","_maxLoad","_slingDiff","_loadDiff"];

                                                _slingloadmax = [(configFile >> "CfgVehicles" >> _x >> "slingLoadMaxCargoMass")] call ALiVE_fnc_getConfigValue;

												if (!isnil "_slingloadmax") then {
                                                	_slingDiff = _slingloadmax - _payloadWeight;

                                                	if ((_slingDiff < _currentDiff) && (_slingDiff > 0)) then {_currentDiff = _slingDiff; _vehicleClass = _x;};
												};
                                            } foreach _transportGroups;

                                            // Cannot find vehicle big enough to slingload...
                                            if (_vehicleClass == "") exitWith {_requiresStandardDelivery = true};

                                            //save vehicle class to group profile
                                            [_slingloadProfile, "vehicleClassSling", _vehicleClass] call ALiVE_fnc_hashSet;
                                        };

                                    } foreach _groupProfile;

                                } foreach _motorisedProfiles;

                                // If we can't helo a vehicle then just send it by land
                                if (_requiresStandardDelivery) exitWith {_eventType = "STANDARD";};

                                // For each group - create helis to carry their vehicles
                                {
                                    _groupProfile = _x;

                                    {

                                        private ["_vehicleClass","_position","_slingLoadProfile"];

                                        if ([_x,"vehicle"] call CBA_fnc_find != -1) then {

                                            // Get the profile
                                            _slingLoadProfile = [ALiVE_ProfileHandler, "getProfile", _x] call ALIVE_fnc_profileHandler;
                                            _vehicleClass = [_slingloadProfile, "vehicleClassSling"] call ALiVE_fnc_hashGet;
                                            [_slingloadProfile, "vehicleClassSling"] call ALiVE_fnc_hashRem;

                                            // setup slingloading
                                            _position = [_logic, "findHelicopterLandingPos", [
                                                _reinforcementPosition, 50, 200
                                            ]] call MAINCLASS;
                                            _position set [2,PARADROP_HEIGHT];
                                            if (_debug) then {
                                                ["ML - HELI_INSERT slingload heli spawn pos: %1 class: %2",
                                                _position, _vehicleClass] call ALiVE_fnc_dump;
                                            };

                                            // Create slingloading heli (slingloading another profile!)
                                            _profiles = [_vehicleClass,_side,_eventFaction,"CAPTAIN",_position,random(360),false,_eventFaction,true,true,[], [[_x], []]] call ALIVE_fnc_createProfilesCrewedVehicle;

                                            // Set slingload state on profile
                                            [_slingloadProfile,"slung",[[_profiles select 1 select 2 select 4]]] call ALIVE_fnc_profileVehicle;

                                            if(_debug) then {
                                                ["ML - Slingloading: %1", _vehicleClass] call ALiVE_fnc_dump;
                                                _slingloadProfile call ALIVE_fnc_inspectHash;
                                            };

                                            _transportProfiles pushback (_profiles select 0 select 2 select 4);
                                            _transportVehicleProfiles pushback (_profiles select 1 select 2 select 4);

                                            _profileIDs = [];
                                            {
                                                _profileID = _x select 2 select 4;
                                                _profileIDs pushback _profileID;
                                            } forEach _profiles;

                                            _payloadGroupProfiles pushback _profileIDs;

                                            _profileWaypoint = [_reinforcementPosition, 100, "MOVE", "LIMITED", 300, [], "LINE"] call ALIVE_fnc_createProfileWaypoint;
                                            _profile = _profiles select 0;
                                            [_profile, "addWaypoint", _profileWaypoint] call ALIVE_fnc_profileEntity;

                                            _totalCount = _totalCount + 1;
                                            
                                            // Fuel watchdog for slingload transport heli
                                            [_logic, "spawnHelicopterFuelWatchdog", [
                                                _profiles select 0 select 2 select 4,
                                                _reinforcementPosition,
                                                _eventFaction
                                            ]] call MAINCLASS;
                                            if (_debug) then {
                                                ["ML - HELI_INSERT slingload watchdog started for profile %1",
                                                    _profiles select 0 select 2 select 4] call ALiVE_fnc_dump;
                                            };
                                            
                                        };

                                    } foreach _groupProfile;

                                } foreach _motorisedProfiles;

                            };
                            _eventTransportProfiles = _transportProfiles;
                            _eventTransportVehiclesProfiles = _transportVehicleProfiles;

                            [_eventCargoProfiles,"payloadGroups",_payloadGroupProfiles] call ALIVE_fnc_hashSet;

                        };

                        // infantry
                        _infantryGroups = [];
                        _infantryProfiles = [];

                        for "_i" from 0 to _eventForceInfantry -1 do {
                            _group = ["Infantry",_eventFaction] call ALIVE_fnc_configGetRandomGroup;
                            if!(_group == "FALSE") then {
                                _infantryGroups pushback _group;
                            }
                        };

                        _infantryGroups = _infantryGroups - ALiVE_PLACEMENT_GROUPBLACKLIST;
                        _groupCount = count _infantryGroups;
                        _totalCount = _totalCount + _groupCount;

                        // create profiles
                        // FIX: Track skipped groups separately so _infantryProfiles
                        // index stays in sync with the heli transport loop below.
                        private _infantrySkipped = 0;

                        for "_i" from 0 to _groupCount -1 do {

                            _group = _infantryGroups select _i;

                            if(_paraDrop) then {
                                if(_eventType == "HELI_INSERT" || _eventType == "HELI_PARADROP") then {
                                    _position = _remotePosition;
                                }else{
                                    _position = _reinforcementPosition getPos [random(200), random(360)];
                                    _position set [2,PARADROP_HEIGHT];
                                };
                            } else {
                                if (_eventType == "HELI_INSERT" || _eventType == "HELI_PARADROP") then {
                                    // Spawn at departure base - position will be overridden
                                    // to the specific pickup LZ during heli assignment below
                                    _position = _remotePosition;
                                } else {
                                    _position = _reinforcementPosition getPos [random(200), random(360)];
                                };
                            };

                            if!(surfaceIsWater _position) then {

                                _profiles = [_group, _position, random(360), false, _eventFaction, true] call ALIVE_fnc_createProfilesFromGroupConfig;

                                _profileIDs = [];
                                {
                                    _profileID = _x select 2 select 4;
                                    _profileIDs pushback _profileID;
                                } forEach _profiles;

                                _infantryProfiles pushback _profileIDs;

                            } else {
                                _groupCount = _groupCount - 1;
                                _totalCount = _totalCount - 1;
                                _infantrySkipped = _infantrySkipped + 1;

                                if (_debug) then {
                                    ["ML - Infantry group %1 skipped (water at position). Running skipped count: %2",
                                        _group, _infantrySkipped] call ALiVE_fnc_dump;
                                };
                            };
                        };

                        if (_debug) then {
                            ["ML - Infantry groups created: %1 skipped: %2 profiles: %3",
                                _groupCount, _infantrySkipped, count _infantryProfiles] call ALiVE_fnc_dump;
                        };
                        
                        [_eventCargoProfiles, "infantry", _infantryProfiles] call ALIVE_fnc_hashSet;

                        if(_eventType == "HELI_INSERT") then {

                            private ["_infantryProfileID","_infantryProfile","_profileWaypoint","_profile"];

                            // create air transport vehicles for the profiles

                            _transportGroups = [ALIVE_factionDefaultAirTransport,_eventFaction,[]] call ALIVE_fnc_hashGet;
                            _transportProfiles = [];
                            _transportVehicleProfiles = [];

                            if(count _transportGroups == 0) then {
                                _transportGroups = [ALIVE_sideDefaultAirTransport,_side] call ALIVE_fnc_hashGet;
                            };

                            if(count _transportGroups > 0) then {

                                for "_i" from 0 to _groupCount -1 do {

                                    private _pickupLZPos = [_logic, "prepareHelicopterLZ", [
                                        _remotePosition getPos [random(200), random(360)], 80
                                    ]] call MAINCLASS;

                                    if (_paraDrop) then {
                                        _position = +_pickupLZPos;
                                        _position set [2,PARADROP_HEIGHT];
                                    } else {
                                        _position = _pickupLZPos;
                                    };

                                    if (_debug) then {
                                        ["ML - HELI_INSERT infantry [%1/%2] pickup LZ: %3",
                                            _i + 1, _groupCount, _pickupLZPos] call ALiVE_fnc_dump;
                                    };

                                    if(count _transportGroups > 0) then {

                                        _vehicleClass = selectRandom _transportGroups;

                                        _profiles = [_vehicleClass,_side,_eventFaction,"CAPTAIN",_position,random(360),false,_eventFaction,true,true] call ALIVE_fnc_createProfilesCrewedVehicle;

                                        _transportProfiles pushback (_profiles select 0 select 2 select 4);
                                        _transportVehicleProfiles pushback (_profiles select 1 select 2 select 4);

                                        if(count _infantryProfiles > _i) then {
                                            if(count (_infantryProfiles select _i) > 0) then {
                                                // Assign ALL entities in this infantry group to the transport vehicle
                                                {
                                                    if!(isNil "_x") then {
                                                        _infantryProfile = [ALIVE_profileHandler, "getProfile", _x] call ALIVE_fnc_profileHandler;
                                                        if!(isNil "_infantryProfile") then {
                                                            [_infantryProfile,_profiles select 1] call ALIVE_fnc_createProfileVehicleAssignment;
                                                            [_infantryProfile, "position", _pickupLZPos] call ALIVE_fnc_profileEntity;
                                                        };
                                                    };
                                                } forEach (_infantryProfiles select _i);
                                            };
                                        };

                                        // Give heli a loiter waypoint at the pickup LZ first,
                                        // then the destination - so infantry have time to board
                                        // before the heli departs
                                        private _loiterWaypoint = [_pickupLZPos, 10, "MOVE", "LIMITED", 60, [], "LINE"] call ALIVE_fnc_createProfileWaypoint;
                                        _profile = _profiles select 0;
                                        [_profile, "addWaypoint", _loiterWaypoint] call ALIVE_fnc_profileEntity;

                                        private _destPos = [_logic, "findHelicopterLandingPos", [
                                            _eventPosition, 200, 600
                                        ]] call MAINCLASS;
                                        _profileWaypoint = [_destPos, 30, "MOVE", "LIMITED", 100, [], "LINE"] call ALIVE_fnc_createProfileWaypoint;
                                        [_profile, "addWaypoint", _profileWaypoint] call ALIVE_fnc_profileEntity;

                                        if (_debug) then {
                                            ["ML - HELI_INSERT infantry transport [%1] dest waypoint: %2",
                                                _i + 1, _destPos] call ALiVE_fnc_dump;
                                        };

                                        // Fuel watchdog for infantry transport heli
                                        [_logic, "spawnHelicopterFuelWatchdog", [
                                            _profiles select 0 select 2 select 4,
                                            _reinforcementPosition,
                                            _eventFaction
                                        ]] call MAINCLASS;

                                    };

                                };

                            };

                            _eventTransportProfiles = _eventTransportProfiles + _transportProfiles;
                            _eventTransportVehiclesProfiles = _eventTransportVehiclesProfiles + _transportVehicleProfiles;
                        };

                        if(_eventType == "HELI_PARADROP") then {

                            private ["_infantryProfileID","_infantryProfile","_profileWaypoint","_profile"];

                            _transportGroups = [ALIVE_factionDefaultAirTransport,_eventFaction,[]] call ALIVE_fnc_hashGet;
                            _transportProfiles = [];
                            _transportVehicleProfiles = [];

                            if(count _transportGroups == 0) then {
                                _transportGroups = [ALIVE_sideDefaultAirTransport,_side] call ALIVE_fnc_hashGet;
                            };

                            if(count _transportGroups > 0) then {

                                for "_i" from 0 to _groupCount -1 do {

                                    private _pickupLZPos = [_logic, "prepareHelicopterLZ", [
                                        _remotePosition getPos [random(200), random(360)], 80
                                    ]] call MAINCLASS;

                                    if (_debug) then {
                                        ["ML - HELI_PARADROP: Heli [%1/%2] spawn LZ: %3",
                                            _i + 1, _groupCount, _pickupLZPos] call ALiVE_fnc_dump;
                                    };

                                    _vehicleClass = selectRandom _transportGroups;

                                    _profiles = [_vehicleClass,_side,_eventFaction,"CAPTAIN",_pickupLZPos,random(360),false,_eventFaction,true,true] call ALIVE_fnc_createProfilesCrewedVehicle;

                                    _transportProfiles pushback (_profiles select 0 select 2 select 4);
                                    _transportVehicleProfiles pushback (_profiles select 1 select 2 select 4);

                                    if(count _infantryProfiles > _i) then {
                                        if(count (_infantryProfiles select _i) > 0) then {
                                            {
                                                if!(isNil "_x") then {
                                                    _infantryProfile = [ALIVE_profileHandler, "getProfile", _x] call ALIVE_fnc_profileHandler;
                                                    if!(isNil "_infantryProfile") then {
                                                        [_infantryProfile, "position", _eventPosition] call ALIVE_fnc_profileEntity;
                                                    };
                                                };
                                            } forEach (_infantryProfiles select _i);
                                        };
                                    };

                                    [_logic, "spawnHelicopterFuelWatchdog", [
                                        _profiles select 0 select 2 select 4,
                                        _reinforcementPosition,
                                        _eventFaction
                                    ]] call MAINCLASS;

                                };

                            };

                            _eventTransportProfiles = _eventTransportProfiles + _transportProfiles;
                            _eventTransportVehiclesProfiles = _eventTransportVehiclesProfiles + _transportVehicleProfiles;
                        };

                        if(_eventType == "STANDARD") then {

                            // create ground transport vehicles for the profiles

                            _transportGroups = [ALIVE_factionDefaultTransport,_eventFaction,[]] call ALIVE_fnc_hashGet;
                            _transportProfiles = [];
                            _transportVehicleProfiles = [];

                            if(count _transportGroups == 0) then {
                                _transportGroups = [ALIVE_sideDefaultTransport,_side] call ALIVE_fnc_hashGet;
                            };

                            if(count _transportGroups > 0) then {
                                for "_i" from 0 to _groupCount -1 do {

                                    _position = _reinforcementPosition getPos [random(200), random(360)];

                                    if(_paraDrop) then {
                                        _position set [2,PARADROP_HEIGHT];
                                    };

                                    if(count _transportGroups > 0) then {

                                        _vehicleClass = selectRandom _transportGroups;

                                        _profiles = [_vehicleClass,_side,_eventFaction,"CAPTAIN",_position,random(360),false,_eventFaction,false,true] call ALIVE_fnc_createProfilesCrewedVehicle;

                                        _transportProfiles pushback (_profiles select 0 select 2 select 4);
                                        _transportVehicleProfiles pushback (_profiles select 1 select 2 select 4);

                                    };

                                };
                            };

                            _eventTransportProfiles = _eventTransportProfiles + _transportProfiles;
                            _eventTransportVehiclesProfiles = _eventTransportVehiclesProfiles + _transportVehicleProfiles;
                        };

                        // armour
                        private ["_armourGroups","_armourProfiles"];

                        _armourGroups = [];
                        _armourProfiles = [];

                        for "_i" from 0 to _eventForceArmour -1 do {
                            _group = ["Armored",_eventFaction] call ALIVE_fnc_configGetRandomGroup;
                            if!(_group == "FALSE") then {
                                _armourGroups pushback _group;
                            };
                        };

                        _armourGroups = _armourGroups - ALiVE_PLACEMENT_GROUPBLACKLIST;
                        _groupCount = count _armourGroups;
                        _totalCount = _totalCount + _groupCount;

                        // create profiles
                        for "_i" from 0 to _groupCount -1 do {

                            _group = _armourGroups select _i;

                            _position = _reinforcementPosition getPos [random(200), random(360)];

                            if(_paraDrop) then {
                                _position set [2,PARADROP_HEIGHT];
                            };

                            if!(surfaceIsWater _position) then {

                                _profiles = [_group, _position, random(360), false, _eventFaction, true] call ALIVE_fnc_createProfilesFromGroupConfig;

                                _profileIDs = [];
                                {
                                    _profileID = _x select 2 select 4;
                                    _profileIDs pushback _profileID;
                                } forEach _profiles;

                                _armourProfiles pushback _profileIDs;

                            } else {
                                _groupCount = _groupCount - 1;
                                _totalCount = _totalCount - 1;
                            };
                        };

                        [_eventCargoProfiles, "armour", _armourProfiles] call ALIVE_fnc_hashSet;


                        // mechanised

                        private ["_mechanisedGroups","_mechanisedProfiles"];

                        _mechanisedGroups = [];
                        _mechanisedProfiles = [];

                        for "_i" from 0 to _eventForceMechanised -1 do {
                            _group = ["Mechanized",_eventFaction] call ALIVE_fnc_configGetRandomGroup;
                            if!(_group == "FALSE") then {
                                _mechanisedGroups pushback _group;
                            }
                        };

                        _mechanisedGroups = _mechanisedGroups - ALiVE_PLACEMENT_GROUPBLACKLIST;
                        _groupCount = count _mechanisedGroups;
                        _totalCount = _totalCount + _groupCount;

                        // create profiles
                        for "_i" from 0 to _groupCount -1 do {

                            _group = _mechanisedGroups select _i;

                            _position = _reinforcementPosition getPos [random(200), random(360)];

                            if(_paraDrop) then {
                                _position set [2,PARADROP_HEIGHT];
                            };

                            if!(surfaceIsWater _position) then {

                                _profiles = [_group, _position, random(360), false, _eventFaction, true] call ALIVE_fnc_createProfilesFromGroupConfig;

                                _profileIDs = [];
                                {
                                    _profileID = _x select 2 select 4;
                                    _profileIDs pushback _profileID;
                                } forEach _profiles;

                                _mechanisedProfiles pushback _profileIDs;

                            } else {
                                _groupCount = _groupCount - 1;
                                _totalCount = _totalCount - 1;
                            };
                        };

                        [_eventCargoProfiles, "mechanised", _mechanisedProfiles] call ALIVE_fnc_hashSet;

                        // plane

                        private ["_planeProfiles","_planeClasses","_motorisedProfiles","_vehicleClass"];

                        _planeProfiles = [];

                        if(_eventType == "STANDARD" || _eventType == "HELI_INSERT") then {

                            _planeClasses = [0,_eventFaction,"Plane"] call ALiVE_fnc_findVehicleType;
                            _planeClasses = _planeClasses - ALiVE_PLACEMENT_VEHICLEBLACKLIST;

                            for "_i" from 0 to _eventForcePlane -1 do {

                                _position = [_logic, "findHelicopterLandingPos", [
                                    _remotePosition, 50, 250
                                ]] call MAINCLASS;
                                _position set [2,1000];

                                if(count _planeClasses > 0) then {

                                    _vehicleClass = selectRandom _planeClasses;

                                    _profiles = [_vehicleClass,_side,_eventFaction,"CAPTAIN",_position,random(360),false,_eventFaction,true,true] call ALIVE_fnc_createProfilesCrewedVehicle;

                                    _profileIDs = [];
                                    {
                                        _profileID = _x select 2 select 4;
                                        _profileIDs pushback _profileID;
                                    } forEach _profiles;

                                    _planeProfiles pushback _profileIDs;

                                    private _heliDestPos = [_logic, "findHelicopterLandingPos", [
                                        _eventPosition, 200, 600
                                    ]] call MAINCLASS;
                                    _profileWaypoint = [_heliDestPos, 30, "MOVE", "LIMITED", 100, [], "LINE"] call ALIVE_fnc_createProfileWaypoint;
                                    _profile = _profiles select 0;
                                    [_profile, "addWaypoint", _profileWaypoint] call ALIVE_fnc_profileEntity;

                                    if (_debug) then {
                                        ["ML - Dedicated heli [%1] class %2 dest: %3",
                                            _i + 1, _vehicleClass, _heliDestPos] call ALiVE_fnc_dump;
                                    };

                                    // Fuel watchdog for dedicated heli asset
                                    [_logic, "spawnHelicopterFuelWatchdog", [
                                        _profiles select 0 select 2 select 4,
                                        _reinforcementPosition,
                                        _eventFaction
                                    ]] call MAINCLASS;
                                }
                            };

                            _groupCount = count _planeProfiles;
                            _totalCount = _totalCount + _groupCount;

                        };

                        [_eventCargoProfiles, "plane", _planeProfiles] call ALIVE_fnc_hashSet;


                        // heli

                        private ["_heliProfiles","_heliClasses","_motorisedProfiles","_vehicleClass"];

                        _heliProfiles = [];

                        if(_eventType == "STANDARD" || _eventType == "HELI_INSERT") then {

                            _heliClasses = [0,_eventFaction,"Helicopter"] call ALiVE_fnc_findVehicleType;
                            _heliClasses = _heliClasses - ALiVE_PLACEMENT_VEHICLEBLACKLIST;

                            for "_i" from 0 to _eventForceHeli -1 do {

                                _position = _remotePosition getPos [random(200), random(360)];
                                _position set [2,1000];

                                if(count _heliClasses > 0) then {

                                    _vehicleClass = selectRandom _heliClasses;

                                    _profiles = [_vehicleClass,_side,_eventFaction,"CAPTAIN",_position,random(360),false,_eventFaction,true,true] call ALIVE_fnc_createProfilesCrewedVehicle;

                                    _profileIDs = [];
                                    {
                                        _profileID = _x select 2 select 4;
                                        _profileIDs pushback _profileID;
                                    } forEach _profiles;

                                    _heliProfiles pushback _profileIDs;

                                    _profileWaypoint = [_reinforcementPosition, 100, "MOVE", "LIMITED", 300, [], "LINE"] call ALIVE_fnc_createProfileWaypoint;
                                    _profile = _profiles select 0;
                                    [_profile, "addWaypoint", _profileWaypoint] call ALIVE_fnc_profileEntity;
                                }
                            };

                            _groupCount = count _heliProfiles;
                            _totalCount = _totalCount + _groupCount;

                        };

                        [_eventCargoProfiles, "heli", _heliProfiles] call ALIVE_fnc_hashSet;


                        // DEBUG -------------------------------------------------------------------------------------
                        if(_debug) then {
                            ["ML - Profiles created total: %1", _totalCount] call ALiVE_fnc_dump;
                            ["ML - Profile breakdown - Infantry groups: %1 Motorised groups: %2 Mechanised groups: %3 Armour groups: %4 Plane groups: %5 Heli groups: %6",
                                count _infantryProfiles,
                                count _motorisedProfiles,
                                count _mechanisedProfiles,
                                count _armourProfiles,
                                count _planeProfiles,
                                count _heliProfiles] call ALiVE_fnc_dump;
                            ["ML - Transport profiles: %1 Transport vehicle profiles: %2",
                                count _eventTransportProfiles,
                                count _eventTransportVehiclesProfiles] call ALiVE_fnc_dump;
                            ["ML - Force pool before deduction: %1 After deduction: %2",
                                _forcePool, (_forcePool - _totalCount)] call ALiVE_fnc_dump;
                            switch(_eventType) do {
                                case "STANDARD": {
                                    [_logic, "createMarker", [_reinforcementPosition,_eventFaction,"ML INSERTION"]] call MAINCLASS;
                                    [_logic, "createMarker", [_eventPosition,_eventFaction,"ML DESTINATION"]] call MAINCLASS;
                                };
                                case "HELI_INSERT": {
                                    [_logic, "createMarker", [_reinforcementPosition,_eventFaction,"ML BASE"]] call MAINCLASS;
                                    [_logic, "createMarker", [_remotePosition,_eventFaction,"ML HELI SPAWN"]] call MAINCLASS;
                                    [_logic, "createMarker", [_eventPosition,_eventFaction,"ML DESTINATION"]] call MAINCLASS;
                                };
                                case "HELI_PARADROP": {
                                    [_logic, "createMarker", [_reinforcementPosition,_eventFaction,"ML BASE"]] call MAINCLASS;
                                    [_logic, "createMarker", [_remotePosition,_eventFaction,"ML PARADROP SPAWN"]] call MAINCLASS;
                                    [_logic, "createMarker", [_eventPosition,_eventFaction,"ML DROP ZONE"]] call MAINCLASS;
                                };
                                case "AIRDROP": {
                                    [_logic, "createMarker", [_eventPosition,_eventFaction,"ML AIRDROP"]] call MAINCLASS;
                                };
                            };
                        };
                        // DEBUG -------------------------------------------------------------------------------------


                        if(_totalCount > 0) then {

                            // -----------------------------------------------------------------
                            // FIX: Reconcile pool reservation made at request receipt.
                            // Refund the reservation and deduct the true spawned count.
                            // This prevents double-deduction.
                            // -----------------------------------------------------------------
                            private _reservation = [_event, "poolReservation", 0] call ALIVE_fnc_hashGet;
                            _forcePool = _forcePool + _reservation;
                            _forcePool = _forcePool - _totalCount;

                            if(_debug) then {
                                ["ML - monitorEvent: Pool reconciliation. Reservation refunded: %1 True count deducted: %2 Remaining pool: %3",
                                    _reservation, _totalCount, _forcePool] call ALiVE_fnc_dump;
                            };

                            [ALIVE_MLGlobalRegistry,"updateGlobalForcePool",[_registryID,_forcePool]] call ALIVE_fnc_MLGlobalRegistry;
                            switch(_eventType) do {
                                case "STANDARD": {

                                    // update the state of the event
                                    // next state is transport load
                                    [_event, "state", "transportLoad"] call ALIVE_fnc_hashSet;

                                    // dispatch event
                                    _logEvent = ['LOGISTICS_INSERTION', [_reinforcementPosition,_eventFaction,_side,_eventID],"Logistics"] call ALIVE_fnc_event;
                                    [ALIVE_eventLog, "addEvent",_logEvent] call ALIVE_fnc_eventLog;

                                };
                                case "HELI_INSERT": {

                                    // update the state of the event
                                    // next state is transport load
                                    [_event, "state", "heliTransportStart"] call ALIVE_fnc_hashSet;

                                    // dispatch event
                                    _logEvent = ['LOGISTICS_INSERTION', [_reinforcementPosition,_eventFaction,_side,_eventID],"Logistics"] call ALIVE_fnc_event;
                                    [ALIVE_eventLog, "addEvent",_logEvent] call ALIVE_fnc_eventLog;

                                };
                                case "HELI_PARADROP": {

                                    [_event, "state", "heliParadropStart"] call ALIVE_fnc_hashSet;

                                    _logEvent = ['LOGISTICS_INSERTION', [_reinforcementPosition,_eventFaction,_side,_eventID],"Logistics"] call ALIVE_fnc_event;
                                    [ALIVE_eventLog, "addEvent",_logEvent] call ALIVE_fnc_eventLog;

                                };
                                case "AIRDROP": {

                                    // update the state of the event
                                    // next state is aridrop wait
                                    [_event, "state", "airdropWait"] call ALIVE_fnc_hashSet;

                                    // dispatch event
                                    _logEvent = ['LOGISTICS_DESTINATION', [_eventPosition,_eventFaction,_side,_eventID],"Logistics"] call ALIVE_fnc_event;
                                    [ALIVE_eventLog, "addEvent",_logEvent] call ALIVE_fnc_eventLog;

                                };
                            };

                            [_event, "cargoProfiles", _eventCargoProfiles] call ALIVE_fnc_hashSet;
                            [_event, "transportProfiles", _eventTransportProfiles] call ALIVE_fnc_hashSet;
                            [_event, "transportVehiclesProfiles", _eventTransportVehiclesProfiles] call ALIVE_fnc_hashSet;

                            [_logic, "prepareUnitCounts", _event] call MAINCLASS;

                            [_eventQueue, _eventID, _event] call ALIVE_fnc_hashSet;

                        }else{

                            // no profiles were created
                            // nothing to do so cancel...

                            if(_debug) then {
                                ["ML - No reinforcements have been created! Cancelling event: %1", _eventID] call ALiVE_fnc_dump;
                            };

                            [_logic, "removeEvent", _eventID] call MAINCLASS;
                        };
                    };
                        }; // end if (!_heliThrottleExceeded)
                        }; // end if (_eventStillActive && !_waitingForHeli)
                }else{
                    // no insertion point available
                    // nothing to do so cancel...

                    if(_debug) then {
                        ["ML - No insertion point available! Cancelling event: %1", _eventID] call ALiVE_fnc_dump;
                    };

                    [_logic, "removeEvent", _eventID] call MAINCLASS;

                };
            };

            // HELI INSERT ------------------------------------------------------------------------------------------------------------------------------

            case "heliTransportStart": {

                // assign waypoints to all
                // vehicle commanders

                private ["_transportProfiles","_infantryProfiles","_planeProfiles","_heliProfiles","_position","_profileWaypoint","_profile","_count","_slingLoadProfiles"];

                _transportProfiles = _eventTransportProfiles;
                _infantryProfiles = [_eventCargoProfiles, 'infantry'] call ALIVE_fnc_hashGet;
                _planeProfiles = [_eventCargoProfiles, 'plane'] call ALIVE_fnc_hashGet;
                _heliProfiles = [_eventCargoProfiles, 'heli'] call ALIVE_fnc_hashGet;

                _count = [_logic, "checkEvent", _event] call MAINCLASS;
                if(_count == 0) exitWith {
                    // set state to event complete
                    [_event, "state", "eventComplete"] call ALIVE_fnc_hashSet;
                    [_eventQueue, _eventID, _event] call ALIVE_fnc_hashSet;
                };

                // Throttle: count all HELI_INSERT events in any active transport state
                private _activeHeliCount = 0;
                {
                    private _qState = [_x, "state"] call ALIVE_fnc_hashGet;
                    private _qID    = [_x, "id"]    call ALIVE_fnc_hashGet;
                    private _qData  = [_x, "data"]  call ALIVE_fnc_hashGet;
                    private _qType  = if (count _qData > 4) then { _qData select 4 } else { "" };
                    if (_qID != _eventID && _qType in ["HELI_INSERT","HELI_PARADROP"]) then {
                        if (_qState in [
                            "transportLoad","transportLoadWait","transportStart","transportTravel",
                            "heliTransport","heliTransportUnloadWait","heliTransportComplete",
                            "heliTransportReturn","heliTransportReturnWait",
                            "heliParadropStart","heliParadropFly","heliParadropReturn","heliParadropReturnWait"
                        ]) then {
                            _activeHeliCount = _activeHeliCount + 1;
                        };
                    };
                } forEach (_eventQueue select 2);

                if (_activeHeliCount >= 2) exitWith {
                    // Stay in heliTransportStart - will retry next monitor cycle
                    if (_debug) then {
                        ["ML - heliTransportStart: Throttle - %1 events in flight, deferring event %2.",
                            _activeHeliCount, _eventID] call ALiVE_fnc_dump;
                    };
                };

                [_event, "finalDestination", _eventPosition getPos [random(DESTINATION_VARIANCE), random(360)]] call ALIVE_fnc_hashSet;

                // Track assigned landing positions to prevent helis landing on top of each other
                private _usedLandingPositions = [];

                {
                    private _destPos = [_logic, "findHelicopterLandingPos", [
                        _eventPosition, 200, 600, _usedLandingPositions
                    ]] call MAINCLASS;
                    _usedLandingPositions pushback _destPos;
                    _profileWaypoint = [_destPos, 200, "MOVE", "NORMAL", 100, [], "LINE"] call ALIVE_fnc_createProfileWaypoint;

                    _profile = [ALIVE_profileHandler, "getProfile", _x] call ALIVE_fnc_profileHandler;
                    if!(isNil "_profile") then {
                        [_profile, "addWaypoint", _profileWaypoint] call ALIVE_fnc_profileEntity;
                        if (_debug) then {
                            ["ML - heliTransportStart: Transport profile %1 waypoint -> %2", _x, _destPos] call ALiVE_fnc_dump;
                        };

                        // Spawn delivery watchdog for this transport heli
                        private _vProfID = "";
                        private _tIdx = _transportProfiles find _x;
                        if (_tIdx >= 0 && _tIdx < count _eventTransportVehiclesProfiles) then {
                            _vProfID = _eventTransportVehiclesProfiles select _tIdx;
                        };
                        if (_vProfID != "") then {
                            private _returnPos = [_reinforcementPrimaryObjective, "center"] call ALIVE_fnc_hashGet;
                            [_logic, "spawnHeliDeliveryWatchdog", [
                                _x, _vProfID, _destPos, _returnPos, _debug
                            ]] call MAINCLASS;
                            if (_debug) then {
                                ["ML - heliTransportStart: Delivery watchdog started for transport %1 vehicle %2", _x, _vProfID] call ALiVE_fnc_dump;
                            };
                        };
                    } else {
                        ["ML - heliTransportStart: WARNING transport profile %1 nil, removing from event.", _x] call ALiVE_fnc_dump;
                        // Remove dead profile ID from transport lists to prevent downstream issues
                        private _tIdx = _transportProfiles find _x;
                        if (_tIdx >= 0) then {
                            _transportProfiles deleteAt _tIdx;
                            if (_tIdx < count _eventTransportVehiclesProfiles) then {
                                _eventTransportVehiclesProfiles deleteAt _tIdx;
                            };
                        };
                        [_event, "transportProfiles", _transportProfiles] call ALIVE_fnc_hashSet;
                        [_event, "transportVehiclesProfiles", _eventTransportVehiclesProfiles] call ALIVE_fnc_hashSet;
                    };

                } forEach _transportProfiles;

                {
                    _profileWaypoint = [_eventPosition, 100, "MOVE", "NORMAL", 100, [], "LINE"] call ALIVE_fnc_createProfileWaypoint;

                    _profile = [ALIVE_profileHandler, "getProfile", _x select 0] call ALIVE_fnc_profileHandler;

                    if!(isNil "_profile") then {
                        [_profile, "addWaypoint", _profileWaypoint] call ALIVE_fnc_profileEntity;
                    };

                } forEach _infantryProfiles;

                {
                    private _destPos = [_logic, "findHelicopterLandingPos", [
                        _eventPosition, 200, 600
                    ]] call MAINCLASS;
                    _profileWaypoint = [_destPos, 200, "MOVE", "NORMAL", 100, [], "LINE"] call ALIVE_fnc_createProfileWaypoint;

                    _profile = [ALIVE_profileHandler, "getProfile", _x select 0] call ALIVE_fnc_profileHandler;
                    if!(isNil "_profile") then {
                        [_profile, "addWaypoint", _profileWaypoint] call ALIVE_fnc_profileEntity;
                        if (_debug) then {
                            ["ML - heliTransportStart: Plane profile %1 waypoint -> %2",
                                _x select 0, _destPos] call ALiVE_fnc_dump;
                        };
                    } else {
                        ["ML - heliTransportStart: WARNING plane profile %1 nil, waypoint not assigned",
                            _x select 0] call ALiVE_fnc_dump;
                    };

                } forEach _planeProfiles;

                {
                    private _destPos = [_logic, "findHelicopterLandingPos", [
                        _eventPosition, 200, 600
                    ]] call MAINCLASS;
                    _profileWaypoint = [_destPos, 200, "MOVE", "NORMAL", 100, [], "LINE"] call ALIVE_fnc_createProfileWaypoint;

                    _profile = [ALIVE_profileHandler, "getProfile", _x select 0] call ALIVE_fnc_profileHandler;
                    if!(isNil "_profile") then {
                        [_profile, "addWaypoint", _profileWaypoint] call ALIVE_fnc_profileEntity;
                        if (_debug) then {
                            ["ML - heliTransportStart: Heli profile %1 waypoint -> %2",
                                _x select 0, _destPos] call ALiVE_fnc_dump;
                        };
                    } else {
                        ["ML - heliTransportStart: WARNING heli profile %1 nil, waypoint not assigned",
                            _x select 0] call ALiVE_fnc_dump;
                    };

                } forEach _heliProfiles;


                // DEBUG -------------------------------------------------------------------------------------
                if(_debug) then {
                    [_logic, "createMarker", [_eventPosition,_eventFaction,"ML DESTINATION"]] call MAINCLASS;
                };
                // DEBUG -------------------------------------------------------------------------------------


                // dispatch event
                _logEvent = ['LOGISTICS_DESTINATION', [_eventPosition,_eventFaction,_side,_eventID],"Logistics"] call ALIVE_fnc_event;
                [ALIVE_eventLog, "addEvent",_logEvent] call ALIVE_fnc_eventLog;

                // respond to player request
                if(_playerRequested) then {
                    _logEvent = ['LOGCOM_RESPONSE', [_requestID,_playerID],"Logistics","REQUEST_ENROUTE"] call ALIVE_fnc_event;
                    [ALIVE_eventLog, "addEvent",_logEvent] call ALIVE_fnc_eventLog;
                };


                [_event, "state", "heliTransport"] call ALIVE_fnc_hashSet;
                [_eventQueue, _eventID, _event] call ALIVE_fnc_hashSet;

            };

            case "heliTransport": {

                // waypoint complete check stage

                private ["_waitTotalIterations","_waitIterations","_waitDifference","_transportProfiles","_infantryProfiles","_completed",
                "_planeProfiles","_heliProfiles","_waypointsCompleted","_waypointsNotCompleted","_profile","_position","_distance","_count"];

                _count = [_logic, "checkEvent", _event] call MAINCLASS;
                if(_count == 0) exitWith {
                    // set state to event complete
                    [_event, "state", "eventComplete"] call ALIVE_fnc_hashSet;
                    [_eventQueue, _eventID, _event] call ALIVE_fnc_hashSet;
                };

                // mechanism for aborting this state
                // once set time limit has passed
                // if all units haven't reached objective
                _waitTotalIterations = 200;
                _waitIterations = _eventStateData param [0, 0]; if (isNil "_waitIterations" || typeName _waitIterations != "SCALAR") then { _waitIterations = 0; };

                // check waypoints
                // if all waypoints are complete
                // trigger end of logistics control

                _transportProfiles = _eventTransportProfiles;
                _infantryProfiles = [_eventCargoProfiles, 'infantry'] call ALIVE_fnc_hashGet;
                _planeProfiles = [_eventCargoProfiles, 'plane'] call ALIVE_fnc_hashGet;
                _heliProfiles = [_eventCargoProfiles, 'heli'] call ALIVE_fnc_hashGet;

                _waypointsCompleted = 0;
                _waypointsNotCompleted = 0;

                {
                    _profile = [ALIVE_profileHandler, "getProfile", _x] call ALIVE_fnc_profileHandler;

                    if!(isNil "_profile") then {

                        _completed = [_logic,"checkWaypointCompleted",_profile] call MAINCLASS;

                        if!(_completed) then {

                            [_logic,"setHelicopterTravel",_profile] call MAINCLASS;

                            // If this transport has been hovering a long time without
                            // completing its waypoint, force it to land
                            if (_waitIterations > 20) then {
                                [_logic, "forceHelicopterLanding", [_profile, _eventPosition]] call MAINCLASS;

                                if (_debug) then {
                                    ["ML - heliTransport: Transport profile %1 hover intervention after %2 iterations",
                                        _x, _waitIterations] call ALiVE_fnc_dump;
                                };
                            };

                            // Position-based fallback: if active heli is within 200m of
                            // destination, treat waypoint as complete regardless
                            private _heliActive = _profile select 2 select 1;
                            if (_heliActive) then {
                                private _heliObj = _profile select 2 select 10;
                                if (!isNull _heliObj && alive _heliObj) then {
                                    if (_heliObj distance _eventPosition < 200) then {
                                        _completed = true;
                                    };
                                };
                            };

                        };

                        if (_completed) then {
                            _waypointsCompleted = _waypointsCompleted + 1;
                            [_logic,"unloadTransportHelicopter",[_event,_profile]] call MAINCLASS;
                        } else {
                            _waypointsNotCompleted = _waypointsNotCompleted + 1;
                        };

                    };

                } forEach _transportProfiles;

                // if some waypoints are completed
                // can assume most units are close to
                // destination, adjust timeout
                if(_waypointsCompleted > 0) then {
                    _waitDifference = _waitTotalIterations - _waitIterations;
                    if(_waitDifference > 30) then {
                        _waitIterations = _waitTotalIterations - 10;
                    };
                };

                {
                    _profile = [ALIVE_profileHandler, "getProfile", _x select 0] call ALIVE_fnc_profileHandler;
                    if!(isNil "_profile") then {

                        _completed = [_logic,"checkWaypointCompleted",_profile] call MAINCLASS;

                        if!(_completed) then {
                            _waypointsNotCompleted = _waypointsNotCompleted + 1;
                        }else{
                            _waypointsCompleted = _waypointsCompleted + 1;
                        };

                    };

                } forEach _planeProfiles;

                {
                    _profile = [ALIVE_profileHandler, "getProfile", _x select 0] call ALIVE_fnc_profileHandler;
                    if!(isNil "_profile") then {

                        _completed = [_logic,"checkWaypointCompleted",_profile] call MAINCLASS;

                        if!(_completed) then {

                            [_logic,"setHelicopterTravel",_profile] call MAINCLASS;

                            // If this transport has been hovering a long time without
                            // completing its waypoint, force it to land
                            if (_waitIterations > 20) then {
                                [_logic, "forceHelicopterLanding", [_profile, _eventPosition]] call MAINCLASS;

                                if (_debug) then {
                                    ["ML - heliTransport: Transport profile %1 hover intervention after %2 iterations",
                                        _x, _waitIterations] call ALiVE_fnc_dump;
                                };
                            };

                            // Position-based fallback: if active heli is within 200m of
                            // destination, treat waypoint as complete regardless
                            private _heliActive = _profile select 2 select 1;
                            if (_heliActive) then {
                                private _heliObj = _profile select 2 select 10;
                                if (!isNull _heliObj && alive _heliObj) then {
                                    if (_heliObj distance _eventPosition < 200) then {
                                        _completed = true;
                                    };
                                };
                            };

                        };

                        if (_completed) then {
                            _waypointsCompleted = _waypointsCompleted + 1;
                            [_logic,"unloadTransportHelicopter",[_event,_profile]] call MAINCLASS;
                        } else {
                            _waypointsNotCompleted = _waypointsNotCompleted + 1;
                        };

                    };

                } forEach _heliProfiles;


                // all waypoints completed

                if(_waypointsNotCompleted == 0) then {

                    if(_waypointsCompleted > 0) then {
                        [_event, "state", "heliTransportUnloadWait"] call ALIVE_fnc_hashSet;
                        [_eventQueue, _eventID, _event] call ALIVE_fnc_hashSet;
                    }else{
                        // set state to event complete
                        [_event, "state", "eventComplete"] call ALIVE_fnc_hashSet;
                        [_eventQueue, _eventID, _event] call ALIVE_fnc_hashSet;
                    };

                    // respond to player request
                    if(_playerRequested) then {
                        if(_waypointsCompleted > 0) then {
                            _logEvent = ['LOGCOM_RESPONSE', [_requestID,_playerID],"Logistics","REQUEST_ARRIVED"] call ALIVE_fnc_event;
                            [ALIVE_eventLog, "addEvent",_logEvent] call ALIVE_fnc_eventLog;
                        }else{
                            _logEvent = ['LOGCOM_RESPONSE', [_requestID,_playerID],"Logistics","REQUEST_LOST"] call ALIVE_fnc_event;
                            [ALIVE_eventLog, "addEvent",_logEvent] call ALIVE_fnc_eventLog;
                        };
                    };

                }else{

                    // not all waypoints have been completed
                    // to ensure control passes to OPCOM eventually
                    // limited number of iterations in this
                    // state are used.

                    _waitIterations = _waitIterations + 1;
                    _eventStateData set [0, _waitIterations];
                    [_event, "stateData", _eventStateData] call ALIVE_fnc_hashSet;

                    if(_waitIterations > _waitTotalIterations) then {

                        _eventStateData set [0, 0];
                        [_event, "stateData", _eventStateData] call ALIVE_fnc_hashSet;

                        //["TRANSPORT TRAVEL WAIT - ITERATIONS COMPLETE"] call ALIVE_fnc_dump;
                        [_event, "state", "heliTransportUnloadWait"] call ALIVE_fnc_hashSet;
                        [_eventQueue, _eventID, _event] call ALIVE_fnc_hashSet;

                    };
                };

            };

            case "heliTransportReturn": {

                private _count = [_logic, "checkEvent", _event] call MAINCLASS;
                if(_count == 0 && count _eventTransportProfiles == 0) exitWith {
                    // set state to event complete
                    [_event, "state", "eventComplete"] call ALIVE_fnc_hashSet;
                    [_eventQueue, _eventID, _event] call ALIVE_fnc_hashSet;
                };

                if(count _eventTransportProfiles > 0) then {

                    // send transport vehicles back to insertion point and beyond 1500m to ensure it
                    // egress in opposite direction of ingress to avoid AI fun time

                    private _eventDestination = [_event, "finalDestination"] call ALIVE_fnc_hashGet;
                    private _reinforcementPosition = [_reinforcementPrimaryObjective,"center"] call ALIVE_fnc_hashGet;
                    // Guard against empty finalDestination
                    private _returnDest = if (count _eventDestination > 1) then {
                        // Bearing FROM destination TOWARD reinforcement position = egress direction
                        private _egressDir = _eventDestination getDir _reinforcementPosition;
                        _reinforcementPosition getPos [1500, _egressDir]
                    } else {
                        _reinforcementPosition getPos [1500, random 360]
                    };

                    // #TODO: Change this so each helicopter peels off in the direction of it's offset from the eventDestination position
                    {
                        private _transportProfile = [ALIVE_profileHandler,"getProfile", _x] call ALiVE_fnc_profileHandler;
                        if!(isNil "_transportProfile") then {
                            private _transportProfilePos = _transportProfile select 2 select 2;

                            private _leaveDir = [(_transportProfilePos getDir _reinforcementPosition) - 180] call ALiVE_fnc_modDegrees;
                            private _turnDirOffset = if (random 1 > 0.5) then { 50 } else { -50 };
                            private _leaveDist = 300 + (random 200);

                            private _leavePosStraight = _transportProfilePos getpos [_leaveDist, _leaveDir];
                            private _leavePosTurn = _transportProfilePos getpos [_leaveDist * 1.5, [_leaveDir + _turnDirOffset] call ALiVE_fnc_modDegrees];

                            private _leaveWPStraight = [_leavePosStraight, 100, "MOVE", "LIMITED", 300, [], "LINE"] call ALIVE_fnc_createProfileWaypoint;
                            private _leaveWPTurn = [_leavePosTurn, 100, "MOVE", "NORMAL", 300, [], "LINE"] call ALIVE_fnc_createProfileWaypoint;
                            private _leaveWPFinal = [_returnDest, 100, "MOVE", "NORMAL", 300, [], "LINE"] call ALIVE_fnc_createProfileWaypoint;

                            [_transportProfile, "clearWaypoints"] call ALIVE_fnc_profileEntity;
                            [_transportProfile, "addWaypoint", _leaveWPStraight] call ALIVE_fnc_profileEntity;
                            [_transportProfile, "addWaypoint", _leaveWPTurn] call ALIVE_fnc_profileEntity;
                            [_transportProfile, "addWaypoint", _leaveWPFinal] call ALIVE_fnc_profileEntity;
                        };
                    } forEach _eventTransportProfiles;

                    // set state to wait for return of transports
                    // Reset stateData counter so heliTransportReturnWait starts at 0
                    _eventStateData set [0, 0];
                    [_event, "stateData", _eventStateData] call ALIVE_fnc_hashSet;
                    [_event, "state", "heliTransportReturnWait"] call ALIVE_fnc_hashSet;
                    [_eventQueue, _eventID, _event] call ALIVE_fnc_hashSet;

                }else{

                    // no transport vehicles
                    // set state to event complete
                    [_event, "state", "eventComplete"] call ALIVE_fnc_hashSet;
                    [_eventQueue, _eventID, _event] call ALIVE_fnc_hashSet;

                };

            };

            // AIR DROP ------------------------------------------------------------------------------------------------------------------------------

            case "airdropWait": {

                private ["_waitIterations","_waitTotalIterations"];

                _waitTotalIterations = 15;
                _waitIterations = _eventStateData param [0, 0]; if (isNil "_waitIterations" || typeName _waitIterations != "SCALAR") then { _waitIterations = 0; };

                _waitIterations = _waitIterations + 1;
                _eventStateData set [0, _waitIterations];
                [_event, "stateData", _eventStateData] call ALIVE_fnc_hashSet;

                if(_waitIterations > _waitTotalIterations) then {

                    _eventStateData set [0, 0];
                    [_event, "stateData", _eventStateData] call ALIVE_fnc_hashSet;

                    [_event, "state", "eventComplete"] call ALIVE_fnc_hashSet;
                    [_eventQueue, _eventID, _event] call ALIVE_fnc_hashSet;

                };

            };

            // CONVOY ---------------------------------------------------------------------------------------------------------------------------------

            case "transportLoad": {

                // for any infantry groups order
                // them to load onto the transport vehicles

                private ["_infantryProfiles","_processedProfiles","_infantryProfile","_transportProfileID","_transportProfile"];

                _infantryProfiles = [_eventCargoProfiles, 'infantry'] call ALIVE_fnc_hashGet;
                _processedProfiles = 0;

                if(count _eventTransportVehiclesProfiles > 0) then {

                    {
                        _infantryProfile = [ALIVE_profileHandler, "getProfile", _x select 0] call ALIVE_fnc_profileHandler;
                        if!(isNil "_infantryProfile") then {

                            _transportProfileID = _eventTransportVehiclesProfiles select _processedProfiles;
                            _transportProfile = [ALIVE_profileHandler, "getProfile", _transportProfileID] call ALIVE_fnc_profileHandler;
                            if!(isNil "_transportProfile") then {

                                [_infantryProfile,_transportProfile] call ALIVE_fnc_createProfileVehicleAssignment;

                                _processedProfiles = _processedProfiles + 1;
                            };
                        };

                    } forEach _infantryProfiles;

                };

                [_event, "state", "transportLoadWait"] call ALIVE_fnc_hashSet;
                [_eventQueue, _eventID, _event] call ALIVE_fnc_hashSet;

            };

            case "transportLoadWait": {

                private ["_infantryProfiles","_waitIterations","_waitTotalIterations","_loadedUnits","_notLoadedUnits",
                "_infantryProfile","_active","_units","_vehicle","_vehicleClass"];

                _infantryProfiles = [_eventCargoProfiles, 'infantry'] call ALIVE_fnc_hashGet;

                // mechanism for aborting this state
                // once set time limit has passed
                // if all units havent loaded up
                _waitTotalIterations = 35;
                _waitIterations = _eventStateData param [0, 0]; if (isNil "_waitIterations" || typeName _waitIterations != "SCALAR") then { _waitIterations = 0; };

                // if there are transport vehicles available

                if(count _eventTransportVehiclesProfiles > 0) then {

                    _loadedUnits = [];
                    _notLoadedUnits = [];

                    {
                        _infantryProfile = [ALIVE_profileHandler, "getProfile", _x select 0] call ALIVE_fnc_profileHandler;
                        if!(isNil "_infantryProfile") then {
                            _active = _infantryProfile select 2 select 1;

                            // only need to worry about this is there are
                            // players nearby

                            if(_active) then {

                                _units = _infantryProfile select 2 select 21;

                                // catagorise units into loaded and not
                                // loaded arrays
                                {
                                    _vehicle = vehicle _x;
                                    _vehicleClass = typeOf _vehicle;
                                    if(_vehicleClass != "Steerable_Parachute_F") then {
                                        if(vehicle _x == _x) then {
                                            _notLoadedUnits pushback _x;
                                        }else{
                                            _loadedUnits pushback _x;
                                        };
                                    }else{
                                        _notLoadedUnits pushback _x;
                                    };

                                } forEach _units;

                            }else{

                                // profiles are not active, can skip this wait
                                // continue on to travel

                                [_event, "state", "transportStart"] call ALIVE_fnc_hashSet;
                                [_eventQueue, _eventID, _event] call ALIVE_fnc_hashSet;

                            };

                        };

                    } forEach _infantryProfiles;

                    // if there are units left to be loaded
                    // wait for x iterations for loading to occur
                    // once time is up delete all not loaded units

                    if(count _notLoadedUnits > 0) then {

                        _waitIterations = _waitIterations + 1;
                        _eventStateData set [0, _waitIterations];
                        [_event, "stateData", _eventStateData] call ALIVE_fnc_hashSet;

                        if(_waitIterations > _waitTotalIterations) then {

                            {
                                deleteVehicle _x;
                            } forEach _notLoadedUnits;

                            _eventStateData set [0, 0];
                            [_event, "stateData", _eventStateData] call ALIVE_fnc_hashSet;

                            [_event, "state", "transportStart"] call ALIVE_fnc_hashSet;
                            [_eventQueue, _eventID, _event] call ALIVE_fnc_hashSet;
                        };

                    }else{

                        // all units have loaded
                        // continue on to travel

                        [_event, "state", "transportStart"] call ALIVE_fnc_hashSet;
                        [_eventQueue, _eventID, _event] call ALIVE_fnc_hashSet;

                    };


                }else{

                    // no transport vehicles available
                    // continue on to travel

                    [_event, "state", "transportStart"] call ALIVE_fnc_hashSet;
                    [_eventQueue, _eventID, _event] call ALIVE_fnc_hashSet;
                };

            };

            case "transportStart": {

                // assign waypoints to all
                // vehicle commanders

                private ["_transportProfiles","_infantryProfiles","_armourProfiles","_mechanisedProfiles","_motorisedProfiles",
                "_planeProfiles","_heliProfiles","_profileWaypoint","_profile","_position","_countProfiles","_positionSeries","_seriesIndex","_count"];

                _count = [_logic, "checkEvent", _event] call MAINCLASS;
                if(_count == 0) exitWith {
                    // set state to event complete
                    [_event, "state", "eventComplete"] call ALIVE_fnc_hashSet;
                    [_eventQueue, _eventID, _event] call ALIVE_fnc_hashSet;
                };

                _transportProfiles = _eventTransportProfiles;
                _infantryProfiles = [_eventCargoProfiles, 'infantry'] call ALIVE_fnc_hashGet;
                _armourProfiles = [_eventCargoProfiles, 'armour'] call ALIVE_fnc_hashGet;
                _mechanisedProfiles = [_eventCargoProfiles, 'mechanised'] call ALIVE_fnc_hashGet;
                _motorisedProfiles = [_eventCargoProfiles, 'motorised'] call ALIVE_fnc_hashGet;
                _planeProfiles = [_eventCargoProfiles, 'plane'] call ALIVE_fnc_hashGet;
                _heliProfiles = [_eventCargoProfiles, 'heli'] call ALIVE_fnc_hashGet;

                _countProfiles = (count(_transportProfiles)) + (count(_armourProfiles)) + (count(_mechanisedProfiles)) + (count(_motorisedProfiles));

                _position = [_eventPosition] call ALIVE_fnc_getClosestRoad;

                _positionSeries = [_position,300,_countProfiles,false] call ALIVE_fnc_getSeriesRoadPositions;

                if((count _positionSeries) < _countProfiles) then {
                    for "_i" from 0 to _countProfiles -1 do {
                        _position = _eventPosition getPos [random(DESTINATION_VARIANCE), random(360)];
                        _positionSeries set [_i, _position];
                    };
                };

                _seriesIndex = 0;

                [_event, "finalDestination", _positionSeries select 0] call ALIVE_fnc_hashSet;

                {

                    _position = _positionSeries select _seriesIndex;
                    _profileWaypoint = [_position, 1, "MOVE", "LIMITED", 2, [], "COLUMN"] call ALIVE_fnc_createProfileWaypoint;

                    _profile = [ALIVE_profileHandler, "getProfile", _x] call ALIVE_fnc_profileHandler;
                    if!(isNil "_profile") then {
                        [_profile, "addWaypoint", _profileWaypoint] call ALIVE_fnc_profileEntity;
                    };

                    _seriesIndex = _seriesIndex + 1;

                } forEach _transportProfiles;

                {
                    _position = _eventPosition getPos [random(DESTINATION_VARIANCE), random(360)];
                    _profileWaypoint = [_position, 1, "MOVE", "LIMITED", 2, [], "LINE"] call ALIVE_fnc_createProfileWaypoint;

                    _profile = [ALIVE_profileHandler, "getProfile", _x select 0] call ALIVE_fnc_profileHandler;
                    if!(isNil "_profile") then {
                        [_profile, "addWaypoint", _profileWaypoint] call ALIVE_fnc_profileEntity;
                    };

                } forEach _infantryProfiles;

                {
                    _position = _positionSeries select _seriesIndex;
                    _profileWaypoint = [_position, 1, "MOVE", "NORMAL", 2, [], "COLUMN"] call ALIVE_fnc_createProfileWaypoint;

                    _profile = [ALIVE_profileHandler, "getProfile", _x select 0] call ALIVE_fnc_profileHandler;
                    if!(isNil "_profile") then {
                        [_profile, "addWaypoint", _profileWaypoint] call ALIVE_fnc_profileEntity;
                    };

                    _seriesIndex = _seriesIndex + 1;

                } forEach _armourProfiles;

                {
                    _position = _positionSeries select _seriesIndex;
                    _profileWaypoint = [_position, 1, "MOVE", "LIMITED", 2, [], "COLUMN"] call ALIVE_fnc_createProfileWaypoint;

                    _profile = [ALIVE_profileHandler, "getProfile", _x select 0] call ALIVE_fnc_profileHandler;
                    if!(isNil "_profile") then {
                        [_profile, "addWaypoint", _profileWaypoint] call ALIVE_fnc_profileEntity;
                    };

                    _seriesIndex = _seriesIndex + 1;

                } forEach _mechanisedProfiles;

                {
                    _position = _positionSeries select _seriesIndex;
                    _profileWaypoint = [_position, 1, "MOVE", "LIMITED", 2, [], "COLUMN"] call ALIVE_fnc_createProfileWaypoint;

                    _profile = [ALIVE_profileHandler, "getProfile", _x select 0] call ALIVE_fnc_profileHandler;
                    if!(isNil "_profile") then {
                        [_profile, "addWaypoint", _profileWaypoint] call ALIVE_fnc_profileEntity;
                    };

                    _seriesIndex = _seriesIndex + 1;

                } forEach _motorisedProfiles;

                {
                    _position = _eventPosition getPos [random(DESTINATION_VARIANCE), random(360)];
                    _profileWaypoint = [_position, 100, "MOVE", "LIMITED", 300, [], "LINE"] call ALIVE_fnc_createProfileWaypoint;

                    _profile = [ALIVE_profileHandler, "getProfile", _x select 0] call ALIVE_fnc_profileHandler;
                    if!(isNil "_profile") then {
                        [_profile, "addWaypoint", _profileWaypoint] call ALIVE_fnc_profileEntity;
                    };

                } forEach _planeProfiles;

                {
                    _position = _eventPosition getPos [random(DESTINATION_VARIANCE), random(360)];
                    _profileWaypoint = [_position, 100, "MOVE", "LIMITED", 300, [], "LINE"] call ALIVE_fnc_createProfileWaypoint;

                    _profile = [ALIVE_profileHandler, "getProfile", _x select 0] call ALIVE_fnc_profileHandler;
                    if!(isNil "_profile") then {
                        [_profile, "addWaypoint", _profileWaypoint] call ALIVE_fnc_profileEntity;
                    };

                } forEach _heliProfiles;


                // DEBUG -------------------------------------------------------------------------------------
                if(_debug) then {
                    [_logic, "createMarker", [_eventPosition,_eventFaction,"ML DESTINATION"]] call MAINCLASS;
                };
                // DEBUG -------------------------------------------------------------------------------------


                // dispatch event
                _logEvent = ['LOGISTICS_DESTINATION', [_eventPosition,_eventFaction,_side,_eventID],"Logistics"] call ALIVE_fnc_event;
                [ALIVE_eventLog, "addEvent",_logEvent] call ALIVE_fnc_eventLog;


                if(_playerRequested) then {
                    _logEvent = ['LOGCOM_RESPONSE', [_requestID,_playerID],"Logistics","REQUEST_ENROUTE"] call ALIVE_fnc_event;
                    [ALIVE_eventLog, "addEvent",_logEvent] call ALIVE_fnc_eventLog;
                };


                [_event, "state", "transportTravel"] call ALIVE_fnc_hashSet;
                [_eventQueue, _eventID, _event] call ALIVE_fnc_hashSet;
            };

            case "transportTravel": {

                // waypoint complete check stage

                private ["_waitTotalIterations","_waitIterations","_waitDifference","_transportProfiles","_infantryProfiles",
                "_armourProfiles","_mechanisedProfiles","_motorisedProfiles","_planeProfiles","_heliProfiles",
                "_waypointsCompleted","_waypointsNotCompleted","_profile","_position","_distance","_count","_completed"];

                _count = [_logic, "checkEvent", _event] call MAINCLASS;
                if(_count == 0) exitWith {
                    // set state to event complete
                    [_event, "state", "eventComplete"] call ALIVE_fnc_hashSet;
                    [_eventQueue, _eventID, _event] call ALIVE_fnc_hashSet;
                };

                // mechanism for aborting this state
                // once set time limit has passed
                // if all units haven't reached objective
                _waitTotalIterations = 400;
                _waitIterations = _eventStateData param [0, 0]; if (isNil "_waitIterations" || typeName _waitIterations != "SCALAR") then { _waitIterations = 0; };

                // ---------------------------------------------------------------
                // EARLY DISMOUNT - ground transport vehicles only
                // When an active ground transport vehicle (not helicopter) is
                // within DISMOUNT_RADIUS of the destination, unload infantry
                // early so they approach on foot. The vehicle then advances
                // VEHICLE_LEAD_DIST ahead toward the objective as overwatch.
                // Only triggers once per event (stateData slot 1 used as flag).
                // Transport vehicle profiles are in _eventTransportVehiclesProfiles.
                // ---------------------------------------------------------------
                private _DISMOUNT_RADIUS = DISMOUNT_RADIUS;
                private _VEHICLE_LEAD_DIST = VEHICLE_LEAD_DIST;
                private _dismountDone = _eventStateData param [1, false];
                if (isNil "_dismountDone" || typeName _dismountDone != "BOOL") then { _dismountDone = false; };

                if (!_dismountDone) then {

                    if (_debug && count _eventTransportVehiclesProfiles > 0) then {
                        ["ML - transportTravel: Checking early dismount. Transport vehicles: %1 Dismount radius: %2m Event: %3",
                            count _eventTransportVehiclesProfiles, _DISMOUNT_RADIUS, _eventID] call ALiVE_fnc_dump;
                    };

                    private _dismountTriggered = false;

                    {
                        private _vehProfID  = _x;
                        private _vehProfile = [ALIVE_profileHandler, "getProfile", _vehProfID] call ALIVE_fnc_profileHandler;
                        if (isNil "_vehProfile") then { continue };

                        // Skip helicopters - they have their own delivery watchdog
                        private _vehClass = _vehProfile select 2 select 11;
                        private _simType = getText (configFile >> "CfgVehicles" >> _vehClass >> "simulation");
                        private _isHeli = (_simType == "helicopter");
                        if (_isHeli) then { continue };

                        private _isActive = _vehProfile select 2 select 1;
                        if (_debug) then {
                            ["ML - transportTravel: Transport vehicle %1 class=%2 active=%3",
                                _vehProfID, _vehClass, _isActive] call ALiVE_fnc_dump;
                        };
                        if (!_isActive) then { continue };

                        private _vehPos     = _vehProfile select 2 select 2;
                        private _distToDest = _vehPos distance2D _eventPosition;

                        if (_debug) then {
                            ["ML - transportTravel: Transport vehicle %1 dist to dest=%2m (threshold=%3m)",
                                _vehProfID, round _distToDest, _DISMOUNT_RADIUS] call ALiVE_fnc_dump;
                        };

                        if (_distToDest > _DISMOUNT_RADIUS) then { continue };

                        // Within dismount radius - check for cargo
                        private _inCargo = _vehProfile select 2 select 9;
                        if (_debug) then {
                            ["ML - transportTravel: Transport vehicle %1 within dismount radius. Cargo profiles: %2",
                                _vehProfID, count _inCargo] call ALiVE_fnc_dump;
                        };
                        if (count _inCargo == 0) then { continue };

                        ["ML - transportTravel: Early dismount triggered for %1 (%2) at %3m from destination. Event: %4",
                            _vehProfID, _vehClass, round _distToDest, _eventID] call ALiVE_fnc_dump;

                        // Unload each cargo profile and give them a foot waypoint to the destination
                        {
                            private _cargoProfile = [ALIVE_profileHandler, "getProfile", _x] call ALIVE_fnc_profileHandler;
                            if (isNil "_cargoProfile") then { continue };

                            [_cargoProfile, _vehProfile] call ALIVE_fnc_removeProfileVehicleAssignment;

                            // If physically spawned, moveOut the units
                            private _cargoActive = _cargoProfile select 2 select 1;
                            if (_cargoActive) then {
                                private _cargoUnits = _cargoProfile select 2 select 21;
                                private _vehObj     = _vehProfile select 2 select 10;
                                if (!isNull _vehObj) then {
                                    { if (alive _x) then { unassignVehicle _x; _x moveOut _vehObj; }; } forEach _cargoUnits;
                                    if (_debug) then {
                                        ["ML - transportTravel: Physically dismounted %1 units from %2",
                                            count _cargoUnits, _vehProfID] call ALiVE_fnc_dump;
                                    };
                                };
                            };

                            // Give infantry a waypoint to continue to destination on foot
                            [_cargoProfile, "clearWaypoints"] call ALIVE_fnc_profileEntity;
                            private _infWP = [_eventPosition, 50, "MOVE", "LIMITED", 2, [], "LINE"] call ALIVE_fnc_createProfileWaypoint;
                            [_cargoProfile, "addWaypoint", _infWP] call ALIVE_fnc_profileEntity;

                            if (_debug) then {
                                ["ML - transportTravel: Infantry profile %1 given foot waypoint to %2",
                                    _x, _eventPosition] call ALiVE_fnc_dump;
                            };

                        } forEach _inCargo;

                        // Give vehicle a waypoint VEHICLE_LEAD_DIST ahead toward objective,
                        // then continue to destination to act as overwatch
                        private _dirToDest  = _vehPos getDir _eventPosition;
                        private _leadPos    = _vehPos getPos [_VEHICLE_LEAD_DIST, _dirToDest];
                        _leadPos set [2, 0];
                        private _nearRoad   = _leadPos nearRoads 40;
                        private _roadSnapped = false;
                        if (count _nearRoad > 0) then {
                            _leadPos = getPos (_nearRoad select 0);
                            _roadSnapped = true;
                        };

                        if (_debug) then {
                            ["ML - transportTravel: Vehicle %1 overwatch position %2 (road snapped: %3)",
                                _vehProfID, _leadPos, _roadSnapped] call ALiVE_fnc_dump;
                        };

                        [_vehProfile, "clearWaypoints"] call ALIVE_fnc_profileEntity;
                        private _leadWP = [_leadPos,      10, "MOVE", "LIMITED", 2, [], "COLUMN"] call ALIVE_fnc_createProfileWaypoint;
                        private _destWP = [_eventPosition, 50, "MOVE", "LIMITED", 2, [], "COLUMN"] call ALIVE_fnc_createProfileWaypoint;
                        [_vehProfile, "addWaypoint", _leadWP] call ALIVE_fnc_profileEntity;
                        [_vehProfile, "addWaypoint", _destWP] call ALIVE_fnc_profileEntity;

                        _dismountTriggered = true;

                    } forEach _eventTransportVehiclesProfiles;

                    if (_dismountTriggered) then {
                        _eventStateData set [1, true];
                        [_event, "stateData", _eventStateData] call ALIVE_fnc_hashSet;
                        ["ML - transportTravel: Early dismount complete. Infantry on foot, vehicles advancing as overwatch. Event: %1",
                            _eventID] call ALiVE_fnc_dump;
                    } else {
                        if (_debug) then {
                            ["ML - transportTravel: No active ground transports within dismount radius yet. Event: %1", _eventID] call ALiVE_fnc_dump;
                        };
                    };
                } else {
                    if (_debug) then {
                        ["ML - transportTravel: Early dismount already completed for event %1, skipping check.", _eventID] call ALiVE_fnc_dump;
                    };
                };
                // ---------------------------------------------------------------
                // END EARLY DISMOUNT
                // ---------------------------------------------------------------

                // check waypoints

                _transportProfiles = _eventTransportProfiles;
                _infantryProfiles = [_eventCargoProfiles, 'infantry'] call ALIVE_fnc_hashGet;
                _armourProfiles = [_eventCargoProfiles, 'armour'] call ALIVE_fnc_hashGet;
                _mechanisedProfiles = [_eventCargoProfiles, 'mechanised'] call ALIVE_fnc_hashGet;
                _motorisedProfiles = [_eventCargoProfiles, 'motorised'] call ALIVE_fnc_hashGet;
                _planeProfiles = [_eventCargoProfiles, 'plane'] call ALIVE_fnc_hashGet;
                _heliProfiles = [_eventCargoProfiles, 'heli'] call ALIVE_fnc_hashGet;

                _waypointsCompleted = 0;
                _waypointsNotCompleted = 0;

                {
                    _profile = [ALIVE_profileHandler, "getProfile", _x] call ALIVE_fnc_profileHandler;
                    if!(isNil "_profile") then {

                        _completed = [_logic,"checkWaypointCompleted",_profile] call MAINCLASS;

                        if!(_completed) then {
                            _waypointsNotCompleted = _waypointsNotCompleted + 1;
                        }else{
                            _waypointsCompleted = _waypointsCompleted + 1;

                            [_logic,"unloadTransport",[_event,_profile]] call MAINCLASS;
                        };

                    };
                } forEach _transportProfiles;

                // if some waypoints are completed
                // can assume most units are close to
                // destination, adjust timeout
                if(_waypointsCompleted > 0) then {
                    _waitDifference = _waitTotalIterations - _waitIterations;
                    if(_waitDifference > 50) then {
                        _waitIterations = _waitTotalIterations - 15;
                    };
                };

                {
                    _profile = [ALIVE_profileHandler, "getProfile", _x select 0] call ALIVE_fnc_profileHandler;
                    if!(isNil "_profile") then {

                        _completed = [_logic,"checkWaypointCompleted",_profile] call MAINCLASS;

                        if!(_completed) then {
                            _waypointsNotCompleted = _waypointsNotCompleted + 1;
                        }else{
                            _waypointsCompleted = _waypointsCompleted + 1;

                            [_logic,"unloadTransport",[_event,_profile]] call MAINCLASS;
                        };

                    };

                } forEach _armourProfiles;

                {
                    _profile = [ALIVE_profileHandler, "getProfile", _x select 0] call ALIVE_fnc_profileHandler;
                    if!(isNil "_profile") then {

                        _completed = [_logic,"checkWaypointCompleted",_profile] call MAINCLASS;

                        if!(_completed) then {
                            _waypointsNotCompleted = _waypointsNotCompleted + 1;
                        }else{
                            _waypointsCompleted = _waypointsCompleted + 1;

                            [_logic,"unloadTransport",[_event,_profile]] call MAINCLASS;
                        };

                    };

                } forEach _mechanisedProfiles;

                {
                    _profile = [ALIVE_profileHandler, "getProfile", _x select 0] call ALIVE_fnc_profileHandler;
                    if!(isNil "_profile") then {

                        _completed = [_logic,"checkWaypointCompleted",_profile] call MAINCLASS;

                        if!(_completed) then {
                            _waypointsNotCompleted = _waypointsNotCompleted + 1;
                        }else{
                            _waypointsCompleted = _waypointsCompleted + 1;

                            [_logic,"unloadTransport",[_event,_profile]] call MAINCLASS;
                        };

                    };

                } forEach _motorisedProfiles;

                {
                    _profile = [ALIVE_profileHandler, "getProfile", _x select 0] call ALIVE_fnc_profileHandler;
                    if!(isNil "_profile") then {

                        _completed = [_logic,"checkWaypointCompleted",_profile] call MAINCLASS;

                        if!(_completed) then {
                            _waypointsNotCompleted = _waypointsNotCompleted + 1;
                        }else{
                            _waypointsCompleted = _waypointsCompleted + 1;

                        };

                    };

                } forEach _planeProfiles;

                {
                    _profile = [ALIVE_profileHandler, "getProfile", _x select 0] call ALIVE_fnc_profileHandler;
                    if!(isNil "_profile") then {

                        _completed = [_logic,"checkWaypointCompleted",_profile] call MAINCLASS;

                        if!(_completed) then {
                            _waypointsNotCompleted = _waypointsNotCompleted + 1;
                        }else{
                            _waypointsCompleted = _waypointsCompleted + 1;
                        };

                    };

                } forEach _heliProfiles;


                // all waypoints completed

                if(_waypointsNotCompleted == 0) then {

                    if(_waypointsCompleted > 0) then {
                        [_event, "state", "transportUnloadWait"] call ALIVE_fnc_hashSet;
                        [_eventQueue, _eventID, _event] call ALIVE_fnc_hashSet;
                    }else{
                        // set state to event complete
                        [_event, "state", "eventComplete"] call ALIVE_fnc_hashSet;
                        [_eventQueue, _eventID, _event] call ALIVE_fnc_hashSet;
                    };

                    // respond to player request
                    if(_playerRequested) then {
                        if(_waypointsCompleted > 0) then {
                            _logEvent = ['LOGCOM_RESPONSE', [_requestID,_playerID],"Logistics","REQUEST_ARRIVED"] call ALIVE_fnc_event;
                            [ALIVE_eventLog, "addEvent",_logEvent] call ALIVE_fnc_eventLog;
                        }else{
                            _logEvent = ['LOGCOM_RESPONSE', [_requestID,_playerID],"Logistics","REQUEST_LOST"] call ALIVE_fnc_event;
                            [ALIVE_eventLog, "addEvent",_logEvent] call ALIVE_fnc_eventLog;
                        };
                    };

                }else{

                    // not all waypoints have been completed
                    // to ensure control passes to OPCOM eventually
                    // limited number of iterations in this
                    // state are used.

                    _waitIterations = _waitIterations + 1;
                    _eventStateData set [0, _waitIterations];
                    [_event, "stateData", _eventStateData] call ALIVE_fnc_hashSet;

                    if(_waitIterations > _waitTotalIterations) then {

                        _eventStateData set [0, 0];
                        [_event, "stateData", _eventStateData] call ALIVE_fnc_hashSet;

                        [_event, "state", "transportUnloadWait"] call ALIVE_fnc_hashSet;
                        [_eventQueue, _eventID, _event] call ALIVE_fnc_hashSet;


                    };
                };

            };

            case "transportUnloadWait";
            case "heliTransportUnloadWait": {
                // wait until all vehicles
                // have unloaded their cargo
                private _count = [_logic, "checkEvent", _event] call MAINCLASS;

                if (_count == 0) exitWith {
                    if (_debug) then {
                        ["ML - heliTransportUnloadWait: No profiles remain, moving to eventComplete. Event: %1", _eventID] call ALiVE_fnc_dump;
                    };
                    [_event, "state", "eventComplete"] call ALIVE_fnc_hashSet;
                    [_eventQueue, _eventID, _event] call ALIVE_fnc_hashSet;
                };

                // mechanism for aborting this state
                // once set time limit has passed
                // if all units haven't reached objective
                private _waitTotalIterations = 40;
                private _waitIterations = _eventStateData param [0, 0]; if (isNil "_waitIterations" || typeName _waitIterations != "SCALAR") then { _waitIterations = 0; };

                private _infantryProfiles = [_eventCargoProfiles, "infantry"] call ALIVE_fnc_hashGet;
                private _loadedUnits = 0;

                {
                    private _infantryProfile = [ALIVE_profileHandler, "getProfile", _x select 0] call ALIVE_fnc_profileHandler;

                    if !(isNil "_infantryProfile") then {
                        private _active = _infantryProfile select 2 select 1;

                        // only need to worry about this if there are players nearby
                        if (_active) then {
                            private _units = _infantryProfile select 2 select 21;

                            {
                                if (alive _x && vehicle _x != _x) then {
                                    _loadedUnits = _loadedUnits + 1;
                                };
                            } forEach _units;
                        } else {
                            // profiles are not active, can skip this wait
                            /* TODO(marcel): Why?! Seems kinda pointless
                            [_event, "state", "eventComplete"] call ALIVE_fnc_hashSet;
                            [_eventQueue, _eventID, _event] call ALIVE_fnc_hashSet;
                            */
                        };
                    };
                } forEach _infantryProfiles;

                // Check to see if payload profiles are ready to return
                // If vehicle no longer has cargo it can return
                private _payloadUnloaded = true;
                private _payloadProfiles = [];

                if (_playerRequested) then {
                    _payloadProfiles append ((_playerRequestProfiles select 2) select 7)
                };

                _payloadProfiles append ([_eventCargoProfiles, "payloadGroups"] call ALIVE_fnc_hashGet);

                if (!isNil "_payloadProfiles") then {
                    {
                        if (count _x > 1) then {
                            private _vehicleProfile = [ALIVE_profileHandler, "getProfile", _x select 1] call ALIVE_fnc_profileHandler;


                            if !(isNil "_vehicleProfile") then {
                                if (_debug) then { _vehicleProfile call ALIVE_fnc_inspectHash; };

                                private _active = (_vehicleProfile select 2) select 1;
                                private _vehicle = (_vehicleProfile select 2) select 10;
                                private _noCargo = count (_vehicle getvariable ["ALiVE_SYS_LOGISTICS_CARGO", []]) == 0;
                                private _slingLoading = [_vehicleProfile, "slingloading", false] call ALiVE_fnc_hashGet;

                                // If payload vehicle is not slingloading and its cargo is empty - its done.
                                TRACE_1("PR UNLOADED", !_slingLoading, _noCargo);

                                if (_active && _noCargo && !_slingLoading) then {
                                    _payloadUnloaded = true;
                                } else {
                                    _payloadUnloaded = false;
                                };

                                // If we've run out of time, dump cargo
                                if (_waitIterations == _waitTotalIterations) then {
                                    if (_active && !_noCargo) then {
                                        [MOD(SYS_LOGISTICS), "unloadObjects", [_vehicle, _vehicle]] call ALiVE_fnc_logistics;
                                    };
                                };
                            };
                        };
                    } foreach _payloadProfiles;
                };

                TRACE_2("PR UNLOADED", _loadedUnits, _payloadUnloaded);

                // If all inf units are unloaded and all payloads are unloaded, then complete
                if ((_loadedUnits == 0 && _payloadUnloaded) || _waitIterations > _waitTotalIterations) then {

                    if (_debug) then {
                        if (_waitIterations > _waitTotalIterations) then {
                            ["ML - heliTransportUnloadWait: Timeout after %1 iterations. loadedUnits=%2 payloadUnloaded=%3. Forcing transition.",
                                _waitIterations, _loadedUnits, _payloadUnloaded] call ALiVE_fnc_dump;
                        } else {
                            ["ML - heliTransportUnloadWait: All units unloaded after %1 iterations. Moving to heliTransportComplete.",
                                _waitIterations] call ALiVE_fnc_dump;
                        };
                    };

                    _eventStateData set [0, 0];
                    [_event, "stateData", _eventStateData] call ALIVE_fnc_hashSet;

                    if (_eventState == "heliTransportUnloadWait") then {
                        [_event, "state", "heliTransportComplete"] call ALIVE_fnc_hashSet;
                    } else {
                        [_event, "state", "transportComplete"] call ALIVE_fnc_hashSet;
                    };

                    [_eventQueue, _eventID, _event] call ALIVE_fnc_hashSet;
                } else {
                    if (_debug) then {
                        ["ML - heliTransportUnloadWait: Waiting for unload. iteration=%1/%2 loadedUnits=%3 payloadUnloaded=%4",
                            _waitIterations, _waitTotalIterations, _loadedUnits, _payloadUnloaded] call ALiVE_fnc_dump;
                    };
                };

                _waitIterations = _waitIterations + 1;
                _eventStateData set [0, _waitIterations];
                [_event, "stateData", _eventStateData] call ALIVE_fnc_hashSet;
            };

            case "transportComplete";
            case "heliTransportComplete": {

                // unloading complete
                // if profiles are active move on
                // to return to insertion point
                // if not active destroy transport profiles
                private ["_transportProfile","_inCargo","_cargoProfileID","_cargoProfile","_active","_inCommand","_commandProfileID","_commandProfile","_anyActive","_count"];
                _count = [_logic, "checkEvent", _event] call MAINCLASS;

                if (_debug) then {
                    ["ML - heliTransportComplete: Event %1 transportVehicles=%2 count=%3",
                        _eventID, count _eventTransportVehiclesProfiles, _count] call ALiVE_fnc_dump;
                };

                if (_count == 0 && count _eventTransportVehiclesProfiles == 0) exitWith {
                    if (_debug) then {
                        ["ML - heliTransportComplete: No profiles remain, moving to eventComplete. Event: %1", _eventID] call ALiVE_fnc_dump;
                    };
                    [_event, "state", "eventComplete"] call ALIVE_fnc_hashSet;
                    [_eventQueue, _eventID, _event] call ALIVE_fnc_hashSet;
                };

                if (count _eventTransportVehiclesProfiles > 0) then {
                    _anyActive = 0;

                    {
                        _transportProfile = [ALIVE_profileHandler, "getProfile", _x] call ALIVE_fnc_profileHandler;
                        if !(isNil "_transportProfile") then {
                            _active = _transportProfile select 2 select 1;
                            private _vehicleObj = _transportProfile select 2 select 10;
                            private _hasLiveVehicle = (!isNull _vehicleObj && alive _vehicleObj);

                            // Count as active if profile says so OR if there's a live vehicle object
                            // (landed helis may briefly show inactive while their object still exists)
                            if (_active || _hasLiveVehicle) then {
                                _anyActive = _anyActive + 1;
                            } else {
                                // Truly virtual - no live object, safe to destroy
                                if (_debug) then {
                                    ["ML - heliTransportComplete: Transport vehicle %1 virtual (no live object), destroying profile.", _x] call ALiVE_fnc_dump;
                                };

                                private _inCommand = _transportProfile select 2 select 8;

                                if (count _inCommand > 0) then {
                                    _commandProfileID = _inCommand select 0;
                                    _commandProfile = [ALIVE_profileHandler, "getProfile", _commandProfileID] call ALIVE_fnc_profileHandler;

                                    if !(isNil "_commandProfile") then {
                                        [_commandProfile, "destroy"] call ALIVE_fnc_profileEntity;
                                    };
                                };

                                [_transportProfile, "destroy"] call ALIVE_fnc_profileVehicle;
                            };
                        };
                    } forEach _eventTransportVehiclesProfiles;

                    // Now decide state based on whether any were active
                    if (_anyActive > 0) then {
                        if (_debug) then {
                            ["ML - heliTransportComplete: %1 transport vehicle(s) active, releasing cargo and sending helis RTB. Event: %2",
                                _anyActive, _eventID] call ALiVE_fnc_dump;
                        };
                        [_logic, "setEventProfilesAvailable", _event] call MAINCLASS;

                        if (_eventState == "transportComplete") then {
                            [_event, "state", "transportReturn"] call ALIVE_fnc_hashSet;
                        } else {
                            [_event, "state", "heliTransportReturn"] call ALIVE_fnc_hashSet;
                        };

                        [_eventQueue, _eventID, _event] call ALIVE_fnc_hashSet;
                    } else {
                        // All vehicles were inactive/virtual - release cargo and complete
                        if (_debug) then {
                            ["ML - heliTransportComplete: All transport vehicles inactive, releasing cargo and completing. Event: %1", _eventID] call ALiVE_fnc_dump;
                        };
                        [_logic, "setEventProfilesAvailable", _event] call MAINCLASS;
                        [_event, "state", "eventComplete"] call ALIVE_fnc_hashSet;
                        [_eventQueue, _eventID, _event] call ALIVE_fnc_hashSet;
                    };
                } else {
                    if (_debug) then {
                        ["ML - heliTransportComplete: No transport vehicles, moving to eventComplete. Event: %1", _eventID] call ALiVE_fnc_dump;
                    };
                    // no transport vehicles
                    // set state to event complete
                    [_event, "state", "eventComplete"] call ALIVE_fnc_hashSet;
                    [_eventQueue, _eventID, _event] call ALIVE_fnc_hashSet;
                };
            };

            case "transportReturn": {

                private ["_position","_profileWaypoint","_reinforcementPosition","_count"];

                _count = [_logic, "checkEvent", _event] call MAINCLASS;
                if(_count == 0) exitWith {
                    // set state to event complete
                    [_event, "state", "eventComplete"] call ALIVE_fnc_hashSet;
                    [_eventQueue, _eventID, _event] call ALIVE_fnc_hashSet;
                };

                if(count _eventTransportProfiles > 0) then {

                    // send transport vehicles back to insertion point
                    {
                        _reinforcementPosition = [_reinforcementPrimaryObjective,"center"] call ALIVE_fnc_hashGet;
                        _position = _reinforcementPosition getPos [random(300), random(360)];
                        _position = [_position] call ALIVE_fnc_getClosestRoad;
                        _profileWaypoint = [_position, 100, "MOVE", "LIMITED", 300, [], "LINE"] call ALIVE_fnc_createProfileWaypoint;

                        _transportProfile = [ALIVE_profileHandler, "getProfile", _x] call ALIVE_fnc_profileHandler;
                        if!(isNil "_transportProfile") then {
                            [_transportProfile, "addWaypoint", _profileWaypoint] call ALIVE_fnc_profileEntity;
                        };


                    } forEach _eventTransportProfiles;

                    // set state to wait for return of transports
                    [_event, "state", "transportReturnWait"] call ALIVE_fnc_hashSet;
                    [_eventQueue, _eventID, _event] call ALIVE_fnc_hashSet;

                }else{

                    // no transport vehicles
                    // set state to event complete
                    [_event, "state", "eventComplete"] call ALIVE_fnc_hashSet;
                    [_eventQueue, _eventID, _event] call ALIVE_fnc_hashSet;

                };

            };

            case "transportReturnWait";
            case "heliTransportReturnWait": {
                private ["_anyActive","_anyAlive","_transportProfile","_active","_inCommand","_commandProfileID","_commandProfile","_count"];

                _count = [_logic, "checkEvent", _event] call MAINCLASS;

                if (_count == 0 && count _eventTransportProfiles == 0) exitWith {
                    if (_debug) then {
                        ["ML - heliTransportReturnWait: No profiles remain, moving to eventComplete. Event: %1", _eventID] call ALiVE_fnc_dump;
                    };
                    [_event, "state", "eventComplete"] call ALIVE_fnc_hashSet;
                    [_eventQueue, _eventID, _event] call ALIVE_fnc_hashSet;
                };

                if (count _eventTransportProfiles > 0) then {
                    _anyActive = 0;
                    _anyAlive = 0;

                    // mechanism for aborting this state
                    // once set time limit has passed
                    // if all units haven't reached objective
                    _waitTotalIterations = 60;
                    _waitIterations = _eventStateData param [0, 0]; if (isNil "_waitIterations" || typeName _waitIterations != "SCALAR") then { _waitIterations = 0; };

                    // once transport vehicles are inactive
                    // dispose of the profiles
                    {
                        _transportProfile = [ALIVE_profileHandler, "getProfile", _x] call ALIVE_fnc_profileHandler;
                        if !(isNil "_transportProfile") then {
                            _active = _transportProfile select 2 select 1;
                            _vehicle = _transportProfile select 2 select 10;
                            private _hasLiveVehicle = (!isNull _vehicle && alive _vehicle);

                            // For heli RTB: force inactive on timeout OR if it has flown far enough from delivery destination
                            if (_eventState == "heliTransportReturnWait") then {
                                private _finalDest = [_event, "finalDestination"] call ALIVE_fnc_hashGet;
                                private _farEnough = false;
                                if (count _finalDest > 1) then {
                                    // Use live vehicle position if spawned, otherwise profile's recorded position
                                    private _checkPos = if (!isNull _vehicle && alive _vehicle) then {
                                        getPos _vehicle
                                    } else {
                                        _transportProfile select 2 select 2
                                    };
                                    _farEnough = _checkPos distance2D _finalDest > 1500;
                                };
                                if (_waitIterations > _waitTotalIterations || _farEnough) then {
                                    // Force heli to land and despawn if still active
                                    if (!isNull _vehicle && alive _vehicle && _active) then {
                                        private _landPad = createVehicle ["Land_HelipadEmpty_F", getPosATL _vehicle, [], 0, "CAN_COLLIDE"];
                                        _vehicle landAt _landPad;
                                        [_vehicle, _landPad] spawn {
                                            private _h = _this select 0; private _p = _this select 1; private _t = 0;
                                            waitUntil { sleep 2; _t = _t + 2; isTouchingGround _h || !alive _h || _t > 30 };
                                            deleteVehicle _p;
                                            if (alive _h) then { _h setDamage 1; }; // despawn by destroying if won't land
                                        };
                                    };
                                    _active = false;
                                };
                            };

                            if (_active) then {
                                if (canMove _vehicle) then {
                                    _anyAlive = _anyAlive + 1;
                                } else {
                                    // Vehicle can't move (broken rotors etc) - treat as done
                                    if (_debug) then {
                                        ["ML - heliTransportReturnWait: Transport vehicle can't move (damaged?), counting as RTB done.", _x] call ALiVE_fnc_dump;
                                    };
                                    // Destroy the profile to free resources
                                    private _inCommand2 = _transportProfile select 2 select 8;
                                    if (count _inCommand2 > 0) then {
                                        private _cmdProf = [ALIVE_profileHandler, "getProfile", _inCommand2 select 0] call ALIVE_fnc_profileHandler;
                                        if !(isNil "_cmdProf") then { [_cmdProf, "destroy"] call ALIVE_fnc_profileEntity; };
                                    };
                                    [_transportProfile, "destroy"] call ALIVE_fnc_profileVehicle;
                                };

                                _anyActive = _anyActive + 1;
                            } else {
                                // if not active dispose of transport profiles
                                _inCommand = _transportProfile select 2 select 8;

                                if (count _inCommand > 0) then {
                                    _commandProfileID = _inCommand select 0;
                                    _commandProfile = [ALIVE_profileHandler, "getProfile", _commandProfileID] call ALIVE_fnc_profileHandler;

                                    if !(isNil "_commandProfile") then {
                                        [_commandProfile, "destroy"] call ALIVE_fnc_profileEntity;
                                    };
                                };

                                [_transportProfile, "destroy"] call ALIVE_fnc_profileVehicle;
                            };
                        };
                    } forEach _eventTransportVehiclesProfiles;

                    _waitIterations = _waitIterations + 1;
                    _eventStateData set [0, _waitIterations];
                    [_event, "stateData", _eventStateData] call ALIVE_fnc_hashSet;

                    if (_anyActive == 0 || _anyAlive == 0 || _waitIterations > _waitTotalIterations) then {
                        if (_debug) then {
                            ["ML - heliTransportReturnWait: RTB complete. anyActive=%1 anyAlive=%2 iterations=%3/%4. Moving to eventComplete. Event: %5",
                                _anyActive, _anyAlive, _waitIterations, _waitTotalIterations, _eventID] call ALiVE_fnc_dump;
                        };
                        _eventStateData set [0, 0];
                        [_event, "stateData", _eventStateData] call ALIVE_fnc_hashSet;
                        [_event, "state", "eventComplete"] call ALIVE_fnc_hashSet;
                        [_eventQueue, _eventID, _event] call ALIVE_fnc_hashSet;
                    } else {
                        if (_debug) then {
                            ["ML - heliTransportReturnWait: Waiting for RTB. anyActive=%1 anyAlive=%2 iteration=%3/%4. Event: %5",
                                _anyActive, _anyAlive, _waitIterations, _waitTotalIterations, _eventID] call ALiVE_fnc_dump;
                        };
                    };
                } else {
                    if (_debug) then {
                        ["ML - heliTransportReturnWait: No transport profiles, moving to eventComplete. Event: %1", _eventID] call ALiVE_fnc_dump;
                    };
                    [_event, "state", "eventComplete"] call ALIVE_fnc_hashSet;
                    [_eventQueue, _eventID, _event] call ALIVE_fnc_hashSet;
                };
            };

            // HELI PARADROP ---------------------------------------------------------------

            case "heliParadropStart": {

                private ["_transportProfiles","_infantryProfiles","_profileWaypoint","_profile","_count"];
                _transportProfiles = _eventTransportProfiles;
                _infantryProfiles  = [_eventCargoProfiles, 'infantry'] call ALIVE_fnc_hashGet;

                _count = [_logic, "checkEvent", _event] call MAINCLASS;
                if(_count == 0) exitWith {
                    [_event, "state", "eventComplete"] call ALIVE_fnc_hashSet;
                    [_eventQueue, _eventID, _event] call ALIVE_fnc_hashSet;
                };

                private _activeHeliCount = 0;
                {
                    private _qState = [_x, "state"] call ALIVE_fnc_hashGet;
                    private _qID    = [_x, "id"]    call ALIVE_fnc_hashGet;
                    private _qData  = [_x, "data"]  call ALIVE_fnc_hashGet;
                    private _qType  = if (count _qData > 4) then { _qData select 4 } else { "" };
                    if (_qID != _eventID && _qType in ["HELI_INSERT","HELI_PARADROP"]) then {
                        if (_qState in [
                            "heliTransport","heliTransportUnloadWait","heliTransportComplete",
                            "heliTransportReturn","heliTransportReturnWait",
                            "heliParadropFly","heliParadropReturn","heliParadropReturnWait"
                        ]) then {
                            _activeHeliCount = _activeHeliCount + 1;
                        };
                    };
                } forEach (_eventQueue select 2);

                if (_activeHeliCount >= 2) exitWith {
                    if (_debug) then {
                        ["ML - heliParadropStart: Throttle - %1 heli events in flight, deferring %2.",
                            _activeHeliCount, _eventID] call ALiVE_fnc_dump;
                    };
                };

                [_event, "finalDestination", _eventPosition getPos [random(DESTINATION_VARIANCE), random(360)]] call ALIVE_fnc_hashSet;

                private _paradropHeight = PARADROP_HEIGHT;

                {
                    private _dropWPPos = +_eventPosition;
                    _dropWPPos set [2, _paradropHeight];
                    _profileWaypoint = [_dropWPPos, 400, "MOVE", "NORMAL", 100, [], "LINE"] call ALIVE_fnc_createProfileWaypoint;
                    _profile = [ALIVE_profileHandler, "getProfile", _x] call ALIVE_fnc_profileHandler;
                    if (!isNil "_profile") then {
                        [_profile, "addWaypoint", _profileWaypoint] call ALIVE_fnc_profileEntity;

                        private _tIdx = _transportProfiles find _x;
                        private _groupInfantryIDs = if (_tIdx >= 0 && _tIdx < count _infantryProfiles) then {
                            _infantryProfiles select _tIdx
                        } else { [] };

                        private _vProfID = "";
                        if (_tIdx >= 0 && _tIdx < count _eventTransportVehiclesProfiles) then {
                            _vProfID = _eventTransportVehiclesProfiles select _tIdx;
                        };

                        private _returnPos = [_reinforcementPrimaryObjective, "center"] call ALIVE_fnc_hashGet;

                        [_logic, "spawnHeliParadropWatchdog", [
                            _x, _vProfID, _eventPosition, _returnPos, _groupInfantryIDs, _paradropHeight, _debug
                        ]] call MAINCLASS;

                        if (_debug) then {
                            ["ML - heliParadropStart: Watchdog started for transport %1 dropping %2 groups.",
                                _x, count _groupInfantryIDs] call ALiVE_fnc_dump;
                        };

                    } else {
                        ["ML - heliParadropStart: WARNING transport profile %1 nil, skipping.", _x] call ALiVE_fnc_dump;
                    };
                } forEach _transportProfiles;

                [_event, "state", "heliParadropFly"] call ALIVE_fnc_hashSet;
                [_eventQueue, _eventID, _event] call ALIVE_fnc_hashSet;

                if (_debug) then {
                    ["ML - heliParadropStart: %1 helis dispatched. Event: %2",
                        count _transportProfiles, _eventID] call ALiVE_fnc_dump;
                };
            };

            case "heliParadropFly": {

                private _count = [_logic, "checkEvent", _event] call MAINCLASS;
                if (_count == 0) exitWith {
                    [_event, "state", "eventComplete"] call ALIVE_fnc_hashSet;
                    [_eventQueue, _eventID, _event] call ALIVE_fnc_hashSet;
                };

                private _waitTotalIterations = 300;
                private _waitIterations = _eventStateData param [0, 0];
                if (isNil "_waitIterations" || typeName _waitIterations != "SCALAR") then { _waitIterations = 0; };

                private _allDropped = true;
                private _anyAlive   = false;

                {
                    private _tProfID  = _x;
                    private _tProfile = [ALIVE_profileHandler, "getProfile", _tProfID] call ALIVE_fnc_profileHandler;
                    if (!isNil "_tProfile") then {
                        _anyAlive = true;
                        private _completed = if (isNil "ALIVE_ML_paradropComplete") then { false } else {
                            _tProfID in ALIVE_ML_paradropComplete
                        };
                        if (!_completed) then { _allDropped = false; };
                        if (_debug) then {
                            ["ML - heliParadropFly: transport %1 profile=%2 completed=%3", _tProfID, (!isNil "_tProfile"), _completed] call ALiVE_fnc_dump;
                        };
                    } else {
                        if (_debug) then {
                            ["ML - heliParadropFly: transport %1 profile=NIL (gone)", _tProfID] call ALiVE_fnc_dump;
                        };
                    };
                } forEach _eventTransportProfiles;

                if ((_allDropped || _waitIterations > _waitTotalIterations) || (!_anyAlive && _waitIterations > 5)) then {
                    if (_debug) then {
                        ["ML - heliParadropFly: Drops complete. Moving to heliParadropReturn. Event: %1", _eventID] call ALiVE_fnc_dump;
                    };
                    _eventStateData set [0, 0];
                    [_event, "stateData", _eventStateData] call ALIVE_fnc_hashSet;
                    [_event, "state", "heliParadropReturn"] call ALIVE_fnc_hashSet;
                    [_eventQueue, _eventID, _event] call ALIVE_fnc_hashSet;
                } else {
                    _waitIterations = _waitIterations + 1;
                    _eventStateData set [0, _waitIterations];
                    [_event, "stateData", _eventStateData] call ALIVE_fnc_hashSet;
                    if (_debug) then {
                        ["ML - heliParadropFly: Waiting for drops. iter=%1/%2 Event: %3",
                            _waitIterations, _waitTotalIterations, _eventID] call ALiVE_fnc_dump;
                    };
                };
            };

            case "heliParadropReturn": {

                private _count = [_logic, "checkEvent", _event] call MAINCLASS;
                if (_count == 0 && count _eventTransportProfiles == 0) exitWith {
                    [_event, "state", "eventComplete"] call ALIVE_fnc_hashSet;
                    [_eventQueue, _eventID, _event] call ALIVE_fnc_hashSet;
                };

                // Mirror heliTransportReturn: 3-waypoint egress to avoid AI hover issues.
                // Profile waypoints must use 2D/terrain positions -- explicit Z causes descent.
                private _reinforcementPosition = [_reinforcementPrimaryObjective, "center"] call ALIVE_fnc_hashGet;
                private _eventDestination = [_event, "finalDestination"] call ALIVE_fnc_hashGet;
                private _returnDest = if (count _eventDestination > 1) then {
                    private _egressDir = _eventDestination getDir _reinforcementPosition;
                    _reinforcementPosition getPos [1500, _egressDir]
                } else {
                    _reinforcementPosition getPos [1500, random 360]
                };

                {
                    private _tProfile = [ALIVE_profileHandler, "getProfile", _x] call ALIVE_fnc_profileHandler;
                    if (!isNil "_tProfile") then {
                        private _tPos = _tProfile select 2 select 2;

                        private _leaveDir = [(_tPos getDir _reinforcementPosition) - 180] call ALiVE_fnc_modDegrees;
                        private _turnDirOffset = if (random 1 > 0.5) then { 50 } else { -50 };
                        private _leaveDist = 300 + (random 200);

                        private _leavePosStraight = _tPos getPos [_leaveDist, _leaveDir];
                        private _leavePosTurn     = _tPos getPos [_leaveDist * 1.5, [_leaveDir + _turnDirOffset] call ALiVE_fnc_modDegrees];

                        private _wpStraight = [_leavePosStraight, 100, "MOVE", "LIMITED", 300, [], "LINE"] call ALIVE_fnc_createProfileWaypoint;
                        private _wpTurn     = [_leavePosTurn,     100, "MOVE", "NORMAL",  300, [], "LINE"] call ALIVE_fnc_createProfileWaypoint;
                        private _wpFinal    = [_returnDest,       100, "MOVE", "NORMAL",  300, [], "LINE"] call ALIVE_fnc_createProfileWaypoint;

                        [_tProfile, "clearWaypoints"] call ALIVE_fnc_profileEntity;
                        [_tProfile, "addWaypoint", _wpStraight] call ALIVE_fnc_profileEntity;
                        [_tProfile, "addWaypoint", _wpTurn]     call ALIVE_fnc_profileEntity;
                        [_tProfile, "addWaypoint", _wpFinal]    call ALIVE_fnc_profileEntity;

                        if (_debug) then {
                            ["ML - heliParadropReturn: RTB issued to %1. exit->%2 turn->%3 base->%4", _x, _leavePosStraight, _leavePosTurn, _returnDest] call ALiVE_fnc_dump;
                        };
                    };
                } forEach _eventTransportProfiles;

                _eventStateData set [0, 0];
                [_event, "stateData", _eventStateData] call ALIVE_fnc_hashSet;
                [_event, "state", "heliParadropReturnWait"] call ALIVE_fnc_hashSet;
                [_eventQueue, _eventID, _event] call ALIVE_fnc_hashSet;
            };

            case "heliParadropReturnWait": {

                private _count = [_logic, "checkEvent", _event] call MAINCLASS;
                if (_count == 0 && count _eventTransportProfiles == 0) exitWith {
                    [_event, "state", "eventComplete"] call ALIVE_fnc_hashSet;
                    [_eventQueue, _eventID, _event] call ALIVE_fnc_hashSet;
                };

                if (count _eventTransportVehiclesProfiles > 0) then {
                    private _waitTotalIterations = 60;
                    private _waitIterations = _eventStateData param [0, 0];
                    if (isNil "_waitIterations" || typeName _waitIterations != "SCALAR") then { _waitIterations = 0; };

                    private _anyActive = 0;
                    private _anyAlive  = 0;
                    private _finalDest = [_event, "finalDestination"] call ALIVE_fnc_hashGet;

                    {
                        private _tProfile = [ALIVE_profileHandler, "getProfile", _x] call ALIVE_fnc_profileHandler;
                        if (!isNil "_tProfile") then {
                            private _active  = _tProfile select 2 select 1;
                            private _vehicle = _tProfile select 2 select 10;

                            private _farEnough = false;
                            if (count _finalDest > 1) then {
                                private _checkPos = if (!isNull _vehicle && alive _vehicle) then {
                                    getPos _vehicle
                                } else {
                                    _tProfile select 2 select 2
                                };
                                _farEnough = _checkPos distance2D _finalDest > 1500;
                            };

                            if (_waitIterations > _waitTotalIterations || _farEnough) then {
                                if (!isNull _vehicle && alive _vehicle && _active) then {
                                    private _landPad = createVehicle ["Land_HelipadEmpty_F", getPosATL _vehicle, [], 0, "CAN_COLLIDE"];
                                    _vehicle landAt _landPad;
                                    [_vehicle, _landPad] spawn {
                                        private _h = _this select 0; private _p = _this select 1; private _t = 0;
                                        waitUntil { sleep 2; _t = _t + 2; isTouchingGround _h || !alive _h || _t > 30 };
                                        deleteVehicle _p;
                                        if (alive _h) then { _h setDamage 1; };
                                    };
                                };
                                _active = false;
                            };

                            if (_active) then {
                                if (!isNull _vehicle && alive _vehicle && canMove _vehicle) then {
                                    _anyAlive = _anyAlive + 1;
                                } else {
                                    // damaged or gone -- destroy profiles
                                    private _inCommand = _tProfile select 2 select 8;
                                    if (count _inCommand > 0) then {
                                        private _cmdProf = [ALIVE_profileHandler, "getProfile", _inCommand select 0] call ALIVE_fnc_profileHandler;
                                        if (!isNil "_cmdProf") then { [_cmdProf, "destroy"] call ALIVE_fnc_profileEntity; };
                                    };
                                    [_tProfile, "destroy"] call ALIVE_fnc_profileVehicle;
                                };
                                _anyActive = _anyActive + 1;
                            } else {
                                private _inCommand = _tProfile select 2 select 8;
                                if (count _inCommand > 0) then {
                                    private _cmdProf = [ALIVE_profileHandler, "getProfile", _inCommand select 0] call ALIVE_fnc_profileHandler;
                                    if (!isNil "_cmdProf") then { [_cmdProf, "destroy"] call ALIVE_fnc_profileEntity; };
                                };
                                [_tProfile, "destroy"] call ALIVE_fnc_profileVehicle;
                            };
                        };
                    } forEach _eventTransportVehiclesProfiles;

                    _waitIterations = _waitIterations + 1;
                    _eventStateData set [0, _waitIterations];
                    [_event, "stateData", _eventStateData] call ALIVE_fnc_hashSet;

                    if (_anyActive == 0 || _anyAlive == 0 || _waitIterations > _waitTotalIterations) then {
                        ["ML - heliParadropReturnWait: RTB complete. Event: %1", _eventID] call ALiVE_fnc_dump;
                        _eventStateData set [0, 0];
                        [_event, "stateData", _eventStateData] call ALIVE_fnc_hashSet;
                        [_event, "state", "eventComplete"] call ALIVE_fnc_hashSet;
                        [_eventQueue, _eventID, _event] call ALIVE_fnc_hashSet;
                    } else {
                        if (_debug) then {
                            ["ML - heliParadropReturnWait: Waiting RTB. anyActive=%1 anyAlive=%2 iter=%3/%4. Event: %5",
                                _anyActive, _anyAlive, _waitIterations, _waitTotalIterations, _eventID] call ALiVE_fnc_dump;
                        };
                    };
                } else {
                    [_event, "state", "eventComplete"] call ALIVE_fnc_hashSet;
                    [_eventQueue, _eventID, _event] call ALIVE_fnc_hashSet;
                };
            };

            // END HELI PARADROP -----------------------------------------------------------

            case "eventComplete": {

                private["_sideObject","_factionName","_forcePool","_message","_radioBroadcast","_debug"];

                _debug = [_logic, "debug"] call MAINCLASS;

                [_logic, "setEventProfilesAvailable", _event] call MAINCLASS;

				// Moved behind debug per request #348
				if (_debug) then {

	                // send radio broadcast
	                _sideObject = [_eventSide] call ALIVE_fnc_sideTextToObject;
	                _factionName = getText((_eventFaction call ALiVE_fnc_configGetFactionClass) >> "displayName");
	                _forcePool = [ALIVE_globalForcePool,_eventFaction] call ALIVE_fnc_hashGet;

                    private _HQ = switch (_sideObject) do {
                        case WEST: {
                            "BLU"
                        };
                        case EAST: {
                            "OPF"
                        };
                        case RESISTANCE: {
                            "IND"
                        };
                        default {
                            "HQ"
                        };
                    };
	                // send a message to all side players from HQ
	                private _finalDest = [_event, "finalDestination"] call ALIVE_fnc_hashGet;
	                private _destLocName = "";
	                if (count _finalDest > 0) then {
	                    private _nearLocStr = [_finalDest] call ALIVE_fnc_taskGetNearestLocationName;
	                    if (_nearLocStr != "" && _nearLocStr != "unknown") then {
	                        _destLocName = format [" near %1", _nearLocStr];
	                    };
	                };
	                _message = format["%1 reinforcements have arrived%2. Available reinforcement level: %3", _factionName, _destLocName, _forcePool];
	                _radioBroadcast = [objNull,_message,"side",_sideObject,false,false,false,true,_HQ];
	                [_eventSide,_radioBroadcast] call ALIVE_fnc_radioBroadcastToSide;
                };

                // remove the event
                [_logic, "removeEvent", _eventID] call MAINCLASS;

            };

            // PLAYER REQUEST ---------------------------------------------------------------------------------------------------------------------------------

            // the units have been requested by a player
            // spawn the units at the insertion point
            case "playerRequested": {

                private ["_waitTime"];

                // according to the type of reinforcement
                // adjust wait time for creation of profiles

                switch(_reinforcementType) do {
                    case "AIR": {
                        _waitTime = WAIT_TIME_AIR;
                    };
                    case "HELI": {
                        _waitTime = WAIT_TIME_HELI;
                    };
                    case "MARINE": {
                        _waitTime = WAIT_TIME_MARINE;
                    };
                    case "DROP": {
                        _waitTime = WAIT_TIME_DROP;
                    };
                };


                // DEBUG -------------------------------------------------------------------------------------
                if(_debug) then {
                    ["ML - Event state: %1 event timer: %2 wait time on event: %3 ",_eventState, (time - _eventTime), _waitTime] call ALiVE_fnc_dump;
                };
                // DEBUG -------------------------------------------------------------------------------------


                // if the reinforcement objective is
                // not available, cancel the event
                if(_reinforcementAvailable) then {

                    if((time - _eventTime) > _waitTime) then {

                        private ["_reinforcementPosition","_playersInRange","_paraDrop","_remotePosition","_totalCount"];

                        if(_eventType == "PR_STANDARD" || _eventType == "PR_HELI_INSERT") then {

                            _reinforcementPosition = [_reinforcementPrimaryObjective,"center"] call ALIVE_fnc_hashGet;

                        }else{
                            _reinforcementPosition = _eventPosition;
                        };

                        // players near check

                        _playersInRange = [_reinforcementPosition, 350] call ALiVE_fnc_anyPlayersInRange;

                        // if players are in visible range
                        // para drop groups instead of
                        // spawning on the ground

                        _paraDrop = false;
                        if(_playersInRange > 0) then {
                            _paraDrop = true;
                            // remote position should probably be spawn range - risk of heli getting shot down though too...
                            _remotePosition = [_reinforcementPosition, 1600] call ALIVE_fnc_getPositionDistancePlayers;
                        }else{
                            _remotePosition = _reinforcementPosition;
                        };

                        // wait time complete create profiles
                        // get groups according to requested force makeup

                        _totalCount = 0;


                        private ["_position","_profiles","_profileID","_profileIDs","_emptyVehicleProfiles","_itemCategory","_infantryProfiles","_armourProfiles",
                        "_mechanisedProfiles","_motorisedProfiles","_heliProfiles","_planeProfiles","_itemClass"];

                        _infantryProfiles = [];
                        _mechanisedProfiles = [];
                        _motorisedProfiles = [];
                        _armourProfiles = [];
                        _heliProfiles = [];
                        _planeProfiles = [];
                        _marineProfiles = [];
                        _specOpsProfiles = [];

                        _payloadGroupProfiles = [];

                        // empty vehicles

                        _emptyVehicleProfiles = [];

                        {
                            _itemClass = _x select 0;

                            _position = _reinforcementPosition getPos [random(200), random(360)];

                            if!(surfaceIsWater _position) then {

                                _itemCategory = _x select 1 select 1;

                                switch(_itemCategory) do {
                                    case "Car":{
                                        if(_paraDrop) then {
                                            _position set [2,PARADROP_HEIGHT];
                                        };
                                    };
                                    case "Armored":{
                                        if(_paraDrop) then {
                                            _position set [2,PARADROP_HEIGHT];
                                        };
                                    };
                                    case "Ship":{
                                        if(_paraDrop) then {
                                            _position set [2,PARADROP_HEIGHT];
                                        } else {
                                            // Find the nearest bit of water
                                            _position = [_position, true] call ALIVE_fnc_getClosestSea;
                                        };
                                    };
                                    case "Air":{
                                        _position = _remotePosition getPos [random(200), random(360)];
                                        _position set [2,1000];
                                    };
                                };

                                if(_eventType == "PR_AIRDROP" || (_eventType == "PR_HELI_INSERT" && _itemCategory != "Air")) then {

                                    if (_paraDrop && _eventType == "PR_HELI_INSERT") then {
                                        _position = _remotePosition getPos [random(200), random(360)];
                                        _position set [2,0]; // position might be in water :(
                                    } else {
                                        _position = _reinforcementPosition getPos [random(200), random(360)];
                                    };

                                    TRACE_2(">>>>>>>>>>>>>>>>>>>>>>>>",_itemClass, _position);

                                    _profiles = [_itemClass,_side,_eventFaction,_position] call ALIVE_fnc_createProfileVehicle;
                                    _profiles = [_profiles];
                                    // Once spawned, prevent despawn while being slung
                                    _profile = _profiles select 0;
                                    [_profile, "spawnType", ["preventDespawn"]] call ALIVE_fnc_profileVehicle;

                                }else{
                                    _profiles = [_itemClass,_side,_eventFaction,"CAPTAIN",_position,random(360),false,_eventFaction,true,true] call ALIVE_fnc_createProfilesCrewedVehicle;
                                };

                                _profileIDs = [];
                                {
                                    _profileID = _x select 2 select 4;
                                    _profileIDs pushback _profileID;
                                } forEach _profiles;

                                _emptyVehicleProfiles pushback _profileIDs;

                                switch(_itemCategory) do {
                                    case "Car":{
                                        _motorisedProfiles pushback _profileIDs;
                                    };
                                    case "Armored":{
                                        _armourProfiles pushback _profileIDs;
                                    };
                                    case "Ship":{
                                        _marineProfiles pushback _profileIDs;
                                    };
                                    case "Air":{
                                        _heliProfiles pushback _profileIDs;

                                        _profileWaypoint = [_reinforcementPosition, 100, "MOVE", "LIMITED", 300, [], "LINE"] call ALIVE_fnc_createProfileWaypoint;
                                        _profile = _profiles select 0;
                                        [_profile, "addWaypoint", _profileWaypoint] call ALIVE_fnc_profileEntity;
                                    };
                                };

                                _totalCount = _totalCount + 1;

                            };

                        } forEach _emptyVehicles;

                        // set up slingload for empty vehicles
                        if(_eventType == "PR_HELI_INSERT" && {_x select 1 select 1 != "Air"} count _emptyVehicles > 0) then {

                            // create heli transport vehicles for the empty vehicles

                            _transportGroups = [ALIVE_factionDefaultAirTransport,_eventFaction,[]] call ALIVE_fnc_hashGet;
                            _transportProfiles = [];
                            _transportVehicleProfiles = [];

                            if(count _transportGroups == 0) then {
                                _transportGroups = [ALIVE_sideDefaultAirTransport,_side] call ALIVE_fnc_hashGet;
                            };

                            if(count _transportGroups > 0) then {

                                // For each empty vehicle - create a heli to carry it
                                {
                                    private ["_currentDiff","_vehicleClass","_position","_payloadWeight","_slingLoadProfile"];

                                    private _prPickupBase = if (_paraDrop) then {
                                        _remotePosition getPos [random(200), random(360)]
                                    } else {
                                        _reinforcementPosition getPos [random(200), random(360)]
                                    };

                                    _position = [_logic, "prepareHelicopterLZ", [_prPickupBase, 80]] call MAINCLASS;


                                    // Get the profile
                                    _slingLoadProfile = [ALiVE_ProfileHandler, "getProfile", (_x select 0)] call ALIVE_fnc_profileHandler;

                                    // _slingloadProfile call ALIVE_fnc_inspectHash;

                                    _payloadWeight = [(_slingLoadProfile select 2 select 11)] call ALIVE_fnc_getObjectWeight;

                                    // Select helicopter that can slingload the vehicle
                                    _vehicleClass = "";
                                    _currentDiff = 15000;
                                    {
                                        private ["_capacity","_slingloadmax","_maxLoad","_slingDiff","_loadDiff"];

                                        _slingloadmax = [(configFile >> "CfgVehicles" >> _x >> "slingLoadMaxCargoMass")] call ALiVE_fnc_getConfigValue;

                                        if!(isNil "_slingloadmax") then {
                                        	_slingDiff = _slingloadmax - _payloadWeight;

                                        	if ((_slingDiff < _currentDiff) && (_slingDiff > 0)) then {_currentDiff = _slingDiff; _vehicleClass = _x;};
                                        };
                                    } foreach _transportGroups;

                                    // Cannot find vehicle big enough to slingload...
                                    if (_vehicleClass == "") exitWith {_totalCount = _totalCount - 1;};

                                    if (_paraDrop) then {
                                        _position set [2,PARADROP_HEIGHT];
                                    };

                                    if (_debug) then {
                                        ["ML - PR_HELI_INSERT infantry [%1] transport LZ: %2",
                                            _i + 1, _position] call ALiVE_fnc_dump;
                                    };

                                    // Create slingloading heli (slingloading another profile!)
                                    _profiles = [_vehicleClass,_side,_eventFaction,"CAPTAIN",_position,random(360),false,_eventFaction,true,true,[], [[_x select 0], []]] call ALIVE_fnc_createProfilesCrewedVehicle;

                                    // Set slingloaded profile
                                    [_slingloadProfile,"slung",[[_profiles select 1 select 2 select 4]]] call ALIVE_fnc_profileVehicle;

                                    _transportProfiles pushback (_profiles select 0 select 2 select 4);
                                    _transportVehicleProfiles pushback (_profiles select 1 select 2 select 4);

                                    _profileIDs = [];
                                    {
                                        _profileID = _x select 2 select 4;
                                        _profileIDs pushback _profileID;
                                    } forEach _profiles;

                                    _payloadGroupProfiles pushback _profileIDs;

                                        private _prDestPos = [_logic, "findHelicopterLandingPos", [
                                            _reinforcementPosition, 0, DESTINATION_VARIANCE
                                        ]] call MAINCLASS;
                                        _profileWaypoint = [_prDestPos, 30, "MOVE", "LIMITED", 100, [], "LINE"] call ALIVE_fnc_createProfileWaypoint;
                                        _profile = _profiles select 0;
                                        [_profile, "addWaypoint", _profileWaypoint] call ALIVE_fnc_profileEntity;

                                        if (_debug) then {
                                            ["ML - PR_HELI_INSERT [%1] dest waypoint: %2", _i + 1, _prDestPos] call ALiVE_fnc_dump;
                                        };

                                        // Fuel watchdog for PR infantry transport heli
                                        [_logic, "spawnHelicopterFuelWatchdog", [
                                            _profiles select 0 select 2 select 4,
                                            _reinforcementPosition,
                                            _eventFaction
                                        ]] call MAINCLASS;

                                    _totalCount = _totalCount + 1;

                                } foreach _emptyVehicleProfiles;

                            } else {
                                ["WARNING: No %1 transport vehicles found for Heli Insert.",_eventFaction] call ALIVE_fnc_dump;
                            };

                            _eventTransportProfiles = _eventTransportProfiles + _transportProfiles;
                            _eventTransportVehiclesProfiles = _eventTransportVehiclesProfiles + _transportVehicleProfiles;

                        };


                        // static individuals

                        private ["_staticIndividualProfiles","_unitClasses"];

                        _staticIndividualProfiles = [];

                        if(count _staticIndividuals > 0) then {

                            _staticIndividualProfiles = [];

                            _position = _reinforcementPosition getPos [random(200), random(360)];

                            if(_paraDrop) then {
                                if(_eventType == "PR_HELI_INSERT") then {
                                    _position = _remotePosition;
                                }else{
                                    _position set [2,PARADROP_HEIGHT];
                                };
                            };

                            _unitClasses = [];
                            {
                                _unitClasses pushback (_x select 0);
                            } forEach _staticIndividuals;

                            _profile = [_unitClasses,_side,_eventFaction,_position,0,_side,true] call ALIVE_fnc_createProfileEntity;
                            _profileID = _profile select 2 select 4;
                            _staticIndividualProfiles pushback [_profileID];
                            _infantryProfiles pushback [_profileID];

                            _totalCount = _totalCount + 1;

                        };


                        // join individuals

                        private ["_joinIndividualProfiles"];

                        _joinIndividualProfiles = [];

                        if(count _joinIndividuals > 0) then {

                            _joinIndividualProfiles = [];

                            _position = _reinforcementPosition getPos [random(200), random(360)];

                            if(_paraDrop) then {
                                if(_eventType == "PR_HELI_INSERT") then {
                                    _position = _remotePosition;
                                }else{
                                    _position set [2,PARADROP_HEIGHT];
                                };
                            };

                            _unitClasses = [];
                            {
                                _unitClasses pushback (_x select 0);
                            } forEach _joinIndividuals;

                            _profile = [_unitClasses,_side,_eventFaction,_position,0,_side,true] call ALIVE_fnc_createProfileEntity;
                            _profileID = _profile select 2 select 4;
                            _joinIndividualProfiles pushback [_profileID];
                            _infantryProfiles pushback [_profileID];

                            _totalCount = _totalCount + 1;

                        };

                        // reinforce individuals

                        private ["_reinforceIndividualProfiles"];

                        _reinforceIndividualProfiles = [];

                        if(count _reinforceIndividuals > 0) then {

                            _reinforceIndividualProfiles = [];

                            _position = _reinforcementPosition getPos [random(200), random(360)];

                            if(_paraDrop) then {
                                if(_eventType == "PR_HELI_INSERT") then {
                                    _position = _remotePosition;
                                }else{
                                    _position set [2,PARADROP_HEIGHT];
                                };
                            };

                            _unitClasses = [];
                            {
                                _unitClasses pushback (_x select 0);
                            } forEach _reinforceIndividuals;

                            _profile = [_unitClasses,_side,_eventFaction,_position,0,_side,true] call ALIVE_fnc_createProfileEntity;
                            _profileID = _profile select 2 select 4;
                            _reinforceIndividualProfiles pushback [_profileID];
                            _infantryProfiles pushback [_profileID];

                            _totalCount = _totalCount + 1;

                        };

                        // Handle Groups - spawn inf and vehicles, slingload/paradrop vehicles if necessary

                        private _staticGroupProfiles = [];
                        private _joinGroupProfiles = [];
                        private _reinforceGroupProfiles = [];

                        {

                            private _profileList = _x select 0;
                            private _groupList = _x select 1;

                            {
                                private _group = _x select 0;
                                private _position = _reinforcementPosition getPos [random(200), random(360)];

                                if !(surfaceIsWater _position) then {
                                    private _groupFaction = (_x select 1) select 1;
                                    private _itemCategory = (_x select 1) select 2;

                                    // Handle other infantry groups such as Infantry_WDL
                                    if ([_itemCategory, "Infantry"] call CBA_fnc_find != -1) then {
                                        _itemCategory = "Infantry";
                                    };

                                    // Handle other Motorized groups such as Motorized_WDL
                                    if ([_itemCategory, "Motorized"] call CBA_fnc_find != -1) then {
                                        _itemCategory = "Motorized";
                                    };

                                    // RHS hacky stuff :(
                                    if !(_itemCategory in ["Infantry", "Support", "SpecOps", "Naval", "Armored", "Mechanized", "Motorized", "Air"]) then {
                                        if(!isNil "ALIVE_factionCustomMappings") then {
                                            if(_groupfaction in (ALIVE_factionCustomMappings select 1)) then {
                                                private _customMappings = [ALIVE_factionCustomMappings, _groupfaction] call ALIVE_fnc_hashGet;
                                                _groupfaction = [_customMappings, "GroupFactionName"] call ALIVE_fnc_hashGet;
                                            };
                                        };
                                        private _key = format ["%1_%2", _groupFaction, _group];
                                        private _value = [ALIVE_groupConfig, _key] call CBA_fnc_hashGet;
                                        private _side = (_value select 1) select 0;
                                        private _faction = (_value select 1) select 1;
                                        private _category = (_value select 1) select 2;
                                        private _configPath = ((((configFile >> "CfgGroups") select _side) select _faction) select _category) >> "aliveCategory";

                                        if (isText _configPath) then {
                                            _itemCategory = getText _configPath;
                                        } else {
                                            // Try the icon...
                                            private _iconText = getText(((((configFile >> "CfgGroups") select _side) select _faction) select _category) >> _group >> "icon");
                                            switch (true) do {
                                                case ([_iconText,"_air"] call CBA_fnc_find != -1): {
                                                    _itemCategory = "Air";
                                                };
                                                case ([_iconText,"_motor_inf"] call CBA_fnc_find != -1): {
                                                    _itemCategory = "Motorized";
                                                };
                                                case ([_iconText,"_mech_inf"] call CBA_fnc_find != -1): {
                                                    _itemCategory = "Mechanized";
                                                };
                                                case ([_iconText,"_armor"] call CBA_fnc_find != -1): {
                                                    _itemCategory = "Armored";
                                                };
                                                case ([_iconText,"_naval"] call CBA_fnc_find != -1): {
                                                    _itemCategory = "Naval";
                                                };
                                                case ([_iconText,"_recon"] call CBA_fnc_find != -1): {
                                                    _itemCategory = "SpecOps";
                                                };
                                                case ([_iconText,"_art"] call CBA_fnc_find != -1 || [_iconText,"_mortar"] call CBA_fnc_find != -1 || [_iconText,"_antiair"] call CBA_fnc_find != -1): {
                                                    _itemCategory = "Support";
                                                };

                                                default {
                                                     _itemCategory = "Infantry";
                                                };
                                            };
                                            ["ML - WARNING: No item category defined for group %1, using %2 based on group icon.",_group, _itemCategory] call ALIVE_fnc_dump;
                                        };
                                    };

                                    switch (_itemCategory) do {
                                        case "Naval": {
                                            if (_paraDrop) then {
                                                _position set [2, PARADROP_HEIGHT];
                                            } else {
                                                // Find the nearest bit of water
                                                _position = [_position, true] call ALIVE_fnc_getClosestSea;
                                            };
                                        };
                                        case "Air": {
                                            _position = _remotePosition getPos [random(200), random(360)];
                                            _position set [2,1000];
                                        };
                                        default {
                                            if (_eventType == "PR_HELI_INSERT") then {
                                                _position = _remotePosition;
                                            } else {
                                                if (_paraDrop) then {
                                                    _position set [2, PARADROP_HEIGHT];
                                                };
                                            };
                                        };
                                    };

                                    private _profiles = [_group, _position, random(360), false, _groupFaction, true] call ALIVE_fnc_createProfilesFromGroupConfig;
                                    private _profileIDs = [];
                                    private _containsVehicles = 0;

                                    {
                                        private _profileID = _x select 2 select 4;
                                        private _inCargo = _x select 2 select 9;

                                        //Count vehicles in group
                                        if ([_profileID,"vehicle"] call CBA_fnc_find != -1) then {
                                            _containsVehicles = _containsVehicles + 1;
                                        };

                                        _profileIDs pushback _profileID;
                                    } forEach _profiles;

                                    _profileList pushBack _profileIDs;

                                    switch(_itemCategory) do {
                                        case "Infantry":{
                                            _infantryProfiles pushback _profileIDs;
                                        };
                                        case "Support":{
                                            _infantryProfiles pushback _profileIDs;
                                        };
                                        case "SpecOps":{
                                            //If the spec op team, does not have a vehicle (like submarines in A3 vanilla)
                                            //treat them as infantry to allow heli insertion and paradrop
                                            if (_containsVehicles == 0) then {
                                                _infantryProfiles pushback _profileIDs;
                                            } else {
                                                _specOpsProfiles pushback _profileIDs;
                                            };
                                        };
                                        case "Naval":{
                                            _marineProfiles pushback _profileIDs;
                                        };
                                        case "Armored":{
                                            _armourProfiles pushback _profileIDs;
                                        };
                                        case "Mechanized":{
                                             _mechanisedProfiles pushback _profileIDs;
                                        };
                                        case "Motorized":{
                                             _motorisedProfiles pushback _profileIDs;
                                        };
                                        case "Air":{
                                            _heliProfiles pushback _profileIDs;

                                            _profileWaypoint = [_reinforcementPosition, 100, "MOVE", "LIMITED", 300, [], "LINE"] call ALIVE_fnc_createProfileWaypoint;
                                            _profile = _profiles select 0;
                                            [_profile, "addWaypoint", _profileWaypoint] call ALIVE_fnc_profileEntity;
                                        };
                                        default {
                                            ["ML - WARNING: No item category defined for group %1, using infantry.",_group] call ALIVE_fnc_dump;
                                            _infantryProfiles pushback _profileIDs;
                                        };
                                    };

                                    _totalCount = _totalCount + 1;
                                };
                            } forEach _groupList;
                        } forEach [
                            [_staticGroupProfiles, _staticGroups],
                            [_joinGroupProfiles, _joinGroups],
                            [_reinforceGroupProfiles, _reinforceGroups]
                        ];

                        // Handle infantry

                        if(_eventType == "PR_STANDARD") then {

                            // create ground transport vehicles for the profiles

                            _transportGroups = [ALIVE_factionDefaultTransport,_eventFaction,[]] call ALIVE_fnc_hashGet;
                            _transportProfiles = [];
                            _transportVehicleProfiles = [];

                            if(count _transportGroups == 0) then {
                                _transportGroups = [ALIVE_sideDefaultTransport,_side] call ALIVE_fnc_hashGet;
                            };

                            if(count _transportGroups > 0) then {
                                for "_i" from 0 to (count _infantryProfiles) -1 do {

                                    _position = _reinforcementPosition getPos [random(200), random(360)];

                                    if(_paraDrop) then {
                                        _position set [2,PARADROP_HEIGHT];
                                    };

                                    if(count _transportGroups > 0) then {

                                        _vehicleClass = selectRandom _transportGroups;

                                        _profiles = [_vehicleClass,_side,_eventFaction,"CAPTAIN",_position,random(360),false,_eventFaction,false,true] call ALIVE_fnc_createProfilesCrewedVehicle;

                                        _transportProfiles pushback (_profiles select 0 select 2 select 4);
                                        _transportVehicleProfiles pushback (_profiles select 1 select 2 select 4);

                                    }

                                };
                            };

                            _eventTransportProfiles = _eventTransportProfiles + _transportProfiles;
                            _eventTransportVehiclesProfiles = _eventTransportVehiclesProfiles + _transportVehicleProfiles;

                        };

                        if(_eventType == "PR_HELI_INSERT") then {

                            private ["_infantryProfileID","_infantryProfile","_profileWaypoint","_profile"];

                            // create air transport vehicles for the profiles

                            _transportGroups = [ALIVE_factionDefaultAirTransport,_eventFaction,[]] call ALIVE_fnc_hashGet;
                            _transportProfiles = [];
                            _transportVehicleProfiles = [];

                            if(count _transportGroups == 0) then {
                                _transportGroups = [ALIVE_sideDefaultAirTransport,_side] call ALIVE_fnc_hashGet;
                            };

                            if(count _transportGroups > 0) then {

                                for "_i" from 0 to (count _infantryProfiles) -1 do {

                                    if (_paraDrop) then {
                                        _position = _remotePosition getPos [random(200), random(360)];
                                    } else {
                                        _position = _reinforcementPosition getPos [random(200), random(360)];
                                    };

                                    if(_paraDrop) then {
                                        _position set [2,PARADROP_HEIGHT];
                                    };

                                    if(count _transportGroups > 0) then {

                                        // Select helicopter that can carry most troops
                                        private "_heliTransport";
                                        _heliTransport = 2;
                                        _vehicleClass = _transportGroups select 0;
                                        {
                                            private ["_transport"];
                                            _transport = [(configFile >> "CfgVehicles" >> _x >> "transportSoldier")] call ALiVE_fnc_getConfigValue;
                                            if (_transport > _heliTransport) then {_vehicleClass = _x};
                                        } foreach _transportGroups;


                                        if (_debug) then {
                                            ["ML - Found %1 for heli insert of %2", _vehicleclass, _infantryProfiles] call ALIVE_fnc_dump;
                                        };

                                        // Create profiles
                                        _profiles = [_vehicleClass,_side,_eventFaction,"CAPTAIN",_position,random(360),false,_eventFaction,true,true] call ALIVE_fnc_createProfilesCrewedVehicle;

                                        _transportProfiles pushback (_profiles select 0 select 2 select 4);
                                        _transportVehicleProfiles pushback (_profiles select 1 select 2 select 4);

                                        _infantryProfileID = _infantryProfiles select _i select 0;
                                        if!(isNil "_infantryProfileID") then {
                                            _infantryProfile = [ALIVE_profileHandler, "getProfile", _infantryProfileID] call ALIVE_fnc_profileHandler;
                                            if!(isNil "_infantryProfile") then {
                                                [_infantryProfile,_profiles select 1] call ALIVE_fnc_createProfileVehicleAssignment;
                                            };
                                        };

                                        _profileWaypoint = [_reinforcementPosition, 100, "MOVE", "LIMITED", 300, [], "LINE"] call ALIVE_fnc_createProfileWaypoint;
                                        _profile = _profiles select 0;
                                        [_profile, "addWaypoint", _profileWaypoint] call ALIVE_fnc_profileEntity;

                                    };

                                };

                            } else {
                                ["ML - WARNING: No %1 transport vehicles found for Heli Insert.",_eventFaction] call ALIVE_fnc_dump;
                            };

                            _eventTransportProfiles = _eventTransportProfiles + _transportProfiles;
                            _eventTransportVehiclesProfiles = _eventTransportVehiclesProfiles + _transportVehicleProfiles;

                        };

                        // Handle Groups
                        // set up slingload for groups with vehicles

                        _groupProfiles = _joinGroupProfiles + _reinforceGroupProfiles + _staticGroupProfiles;

                        if(_eventType == "PR_HELI_INSERT" && (count _groupProfiles > 0)) then {

                            // create heli transport vehicles for groups with vehicles

                            _transportGroups = [ALIVE_factionDefaultAirTransport,_eventFaction,[]] call ALIVE_fnc_hashGet;
                            _transportProfiles = [];
                            _transportVehicleProfiles = [];

                            if(count _transportGroups == 0) then {
                                _transportGroups = [ALIVE_sideDefaultAirTransport,_side] call ALIVE_fnc_hashGet;
                            };

                            if(count _transportGroups > 0) then {

                                // For each group - create helis to carry their vehicles

                                {
                                    _groupProfile = _x;

                                    {
                                        private ["_currentDiff","_vehicleClass","_position","_payloadWeight","_slingLoadProfile"];

                                        // Check to see if profile is a vehicle
                                        if ([_x,"vehicle"] call CBA_fnc_find != -1) then {

                                            if (_paraDrop) then {
                                                _position = _remotePosition getPos [random(200), random(360)];
                                            } else {
                                                _position = _reinforcementPosition getPos [random(200), random(360)];
                                            };

                                            // Get the profile
                                            _slingLoadProfile = [ALiVE_ProfileHandler, "getProfile", _x] call ALIVE_fnc_profileHandler;

                                            // _slingloadProfile call ALIVE_fnc_inspectHash;

                                            _payloadWeight = [(_slingLoadProfile select 2 select 11)] call ALIVE_fnc_getObjectWeight;

                                            // Select helicopter that can slingload the vehicle
                                            _vehicleClass = "";
                                            _currentDiff = 15000;
                                            {
                                                private ["_capacity","_slingloadmax","_maxLoad","_slingDiff","_loadDiff"];

                                                _slingloadmax = [(configFile >> "CfgVehicles" >> _x >> "slingLoadMaxCargoMass")] call ALiVE_fnc_getConfigValue;

												if (!isnil "_slingloadmax") then {
                                                	_slingDiff = _slingloadmax - _payloadWeight;

                                                	if ((_slingDiff < _currentDiff) && (_slingDiff > 0)) then {_currentDiff = _slingDiff; _vehicleClass = _x;};
												};
                                            } foreach _transportGroups;

                                            // Cannot find vehicle big enough to slingload...
                                            if (_vehicleClass == "") exitWith {_totalCount = _totalCount - 1;};

                                            _position set [2,PARADROP_HEIGHT];

                                            // Create slingloading heli (slingloading another profile!)
                                            _profiles = [_vehicleClass,_side,_eventFaction,"CAPTAIN",_position,random(360),false,_eventFaction,true,true,[], [[_x], []]] call ALIVE_fnc_createProfilesCrewedVehicle;

                                            ["HELI PROFILE FOR SLINGLOADING: %1",_profiles select 1 select 2 select 4] call ALiVE_fnc_dump;
                                            // Set slingloaded profile
                                            [_slingloadProfile,"slung",[[_profiles select 1 select 2 select 4]]] call ALIVE_fnc_profileVehicle;

                                            _transportProfiles pushback (_profiles select 0 select 2 select 4);
                                            _transportVehicleProfiles pushback (_profiles select 1 select 2 select 4);

                                            _profileIDs = [];
                                            {
                                                _profileID = _x select 2 select 4;
                                                _profileIDs pushback _profileID;
                                            } forEach _profiles;

                                            _payloadGroupProfiles pushback _profileIDs;

                                            _profileWaypoint = [_reinforcementPosition, 100, "MOVE", "LIMITED", 300, [], "LINE"] call ALIVE_fnc_createProfileWaypoint;
                                            _profile = _profiles select 0;
                                            [_profile, "addWaypoint", _profileWaypoint] call ALIVE_fnc_profileEntity;

                                            _totalCount = _totalCount + 1;
                                        };

                                    } foreach _groupProfile;

                                } foreach _groupProfiles;

                            } else {
                                ["WARNING: No %1 transport vehicles found for Heli Insert.",_eventFaction] call ALIVE_fnc_dump;
                            };

                            _eventTransportProfiles = _eventTransportProfiles + _transportProfiles;
                            _eventTransportVehiclesProfiles = _eventTransportVehiclesProfiles + _transportVehicleProfiles;

                        };

                        // Handle payload

                        // spawn vehicles to fit the requested
                        // payload items in

                        private ["_payloadGroupProfiles","_transportGroups","_transportProfiles","_transportVehicleProfiles","_vehicleClass","_vehicle","_itemClass",
                        "_itemWeight","_payloadWeight","_payloadcount","_payloadSize","_payloadMaxSize"];

                        if(count _payload > 0) then {

                            _payloadWeight = 0;
                            _payloadSize = 0;
                            _payloadMaxSize = 0;
                            {
                                _itemWeight = [_x] call ALIVE_fnc_getObjectWeight;
                                _payloadWeight = _payloadWeight + _itemWeight;
                                _itemSize = [_x] call ALIVE_fnc_getObjectSize;
                                _payloadSize = _payloadSize + _itemSize;
                                if (_itemSize > _payloadMaxSize) then {_payloadMaxSize = _itemSize;};
                            } forEach _payload;

                            _payloadcount = floor(_payloadWeight / 2000);
                            if(_payloadcount <= 0) then {
                                _payloadcount = 1;
                            };
                            _totalCount = _totalCount + _payloadcount;

                            if(_eventType == "PR_STANDARD") then {

                                // create ground transport vehicles for the payload

                                _transportGroups = [ALIVE_factionDefaultTransport,_eventFaction,[]] call ALIVE_fnc_hashGet;
                                _transportProfiles = [];
                                _transportVehicleProfiles = [];

                                if(count _transportGroups == 0) then {
                                    _transportGroups = [ALIVE_sideDefaultTransport,_side] call ALIVE_fnc_hashGet;
                                };

                                if(count _transportGroups > 0) then {

                                    _position = _reinforcementPosition getPos [random(200), random(360)];

                                    if(_paraDrop) then {
                                        _position set [2,PARADROP_HEIGHT];
                                    };

                                    _vehicleClass = selectRandom _transportGroups;

                                    _profiles = [_vehicleClass,_side,_eventFaction,"CAPTAIN",_position,random(360),false,_eventFaction,false,true,_payload] call ALIVE_fnc_createProfilesCrewedVehicle;

                                    _transportProfiles pushback (_profiles select 0 select 2 select 4);
                                    _transportVehicleProfiles pushback (_profiles select 1 select 2 select 4);

                                    _profileIDs = [];
                                    {
                                        _profileID = _x select 2 select 4;
                                        _profileIDs pushback _profileID;
                                    } forEach _profiles;

                                    _payloadGroupProfiles pushback _profileIDs;

                                };

                                _totalCount = _totalCount + 1;

                                _eventTransportProfiles = _eventTransportProfiles + _transportProfiles;
                                _eventTransportVehiclesProfiles = _eventTransportVehiclesProfiles + _transportVehicleProfiles;

                            };

                            if(_eventType == "PR_HELI_INSERT") then {

                                // If payload weight is greater than maximumLoad, then items are put in a container and slingloaded.

                                // create heli transport vehicles for the payload

                                _transportGroups = [ALIVE_factionDefaultAirTransport,_eventFaction,[]] call ALIVE_fnc_hashGet;
                                _transportProfiles = [];
                                _transportVehicleProfiles = [];

                                if(count _transportGroups == 0) then {
                                    _transportGroups = [ALIVE_sideDefaultAirTransport,_side] call ALIVE_fnc_hashGet;
                                };

                                if(count _transportGroups > 0) then {
                                    private ["_slingload","_currentDiff"];

                                    if (_paraDrop) then {
                                        _position = _remotePosition getPos [random(200), random(360)];
                                    } else {
                                        _position = _reinforcementPosition getPos [random(200), random(360)];
                                    };

                                    // Select helicopter that can carry enough for payload
                                    _vehicleClass = _transportGroups select 0;
                                    _slingload = false;
                                    _currentDiff = 15000;
                                    {
                                        private ["_capacity","_slingloadmax","_maxLoad","_slingDiff","_loadDiff"];

                                        _slingloadmax = [(configFile >> "CfgVehicles" >> _x >> "slingLoadMaxCargoMass")] call ALiVE_fnc_getConfigValue;
                                        _maxLoad = [(configFile >> "CfgVehicles" >> _x >> "maximumLoad")] call ALiVE_fnc_getConfigValue;

                                        if (!isNil "_slingloadmax" && {!isNil "_maxLoad"}) then {
	                                        _slingDiff = _slingloadmax - _payloadWeight;
	                                        _loadDiff = _maxLoad - _payloadWeight;

	                                        if ((_slingDiff < _currentDiff) && (_slingDiff > 0)) then {_currentDiff = _slingDiff; _vehicleClass = _x; _slingload = true;};
	                                        if ((_loadDiff <= _currentDiff) && (_loadDiff > 0)) then {_currentDiff = _loadDiff; _vehicleClass = _x; _slingload = false;};
                                        };
                                    } foreach _transportGroups;

                                    // If total size > vehicle size then force slingload if available
                                    if ( (_payloadSize > [(configFile >> "CfgVehicles" >> _vehicleClass >> "mapSize")] call ALiVE_fnc_getConfigValue) && ([(configFile >> "CfgVehicles" >> _vehicleClass >> "slingLoadMaxCargoMass")] call ALiVE_fnc_getConfigValue > 0)) then {
                                        _slingload = true;
                                    };


                                    _position set [2,PARADROP_HEIGHT];


                                    if (!_slingload) then {
                                        _profiles = [_vehicleClass,_side,_eventFaction,"CAPTAIN",_position,random(360),false,_eventFaction,true,true,_payload] call ALIVE_fnc_createProfilesCrewedVehicle;

                                    } else {

                                        // Do slingloading
                                        private ["_containers","_containerClass","_container"];

                                        LOG("RESUPPLY WILL BE SLINGLOADING");

                                        // Get a suitable container
                                        _containers = [ALIVE_factionDefaultContainers,_eventFaction,[]] call ALIVE_fnc_hashGet;

                                        if(count _containers == 0) then {
                                            _containers = [ALIVE_sideDefaultContainers,_side] call ALIVE_fnc_hashGet;
                                        };

                                        if(count _containers > 0) then {
                                            private ["_tempContainer","_tempContainerSize"];
                                            if (_paraDrop) then {
                                                _position = _remotePosition getPos [random(200), random(360)];
                                            } else {
                                                _position = _reinforcementPosition getPos [random(200), random(360)];
                                            };

                                            // Choose a good sized container
                                            _containerClass = _containers select 0;

                                            // Find a container big enough and the helicopter can slingload
                                            _tempContainer = _containerClass;
                                            _tempContainerSize = [(configFile >> "CfgVehicles" >> _containerClass >> "mapSize")] call ALiVE_fnc_getConfigValue;
                                            {
                                                private ["_containerSize","_heliCanSling"];
                                                _containerSize = [(configFile >> "CfgVehicles" >> _x >> "mapSize")] call ALiVE_fnc_getConfigValue;

                                                // Work around for cargo container that is 7500kg
                                                _heliCanSling = if ([(configFile >> "CfgVehicles" >> _vehicleClass >> "slingLoadMaxCargoMass")] call ALiVE_fnc_getConfigValue < 7500 && _x == "B_Slingload_01_Cargo_F") then {false;}else{true;};

                                                if (_containerSize > _tempContainerSize && _heliCanSling) then {_tempContainer = _x; _tempContainerSize = _containerSize;};

                                                TRACE_3("RESUPPLY", _payloadMaxSize, _containerSize, _x);

                                                if ((_containerSize * 2) > _payloadMaxSize && _heliCanSling) exitWith {_containerClass = _x;};
                                            } foreach _containers;

                                            // If no container is big enough, then just use biggest
                                            if (_tempContainerSize > [(configFile >> "CfgVehicles" >> _containerClass >> "mapSize")] call ALiVE_fnc_getConfigValue) then {
                                                _containerClass = _tempContainer;
                                            };

                                            // Create slingloading heli
                                            _profiles = [_vehicleClass,_side,_eventFaction,"CAPTAIN",_position,random(360),false,_eventFaction,true,true,[], [_containerClass, _payload]] call ALIVE_fnc_createProfilesCrewedVehicle;

                                        };
                                    };

                                    _transportProfiles pushback (_profiles select 0 select 2 select 4);
                                    _transportVehicleProfiles pushback (_profiles select 1 select 2 select 4);

                                    _profileIDs = [];
                                    {
                                        _profileID = _x select 2 select 4;
                                        _profileIDs pushback _profileID;
                                    } forEach _profiles;

                                    _payloadGroupProfiles pushback _profileIDs;

                                    _profileWaypoint = [_reinforcementPosition, 100, "MOVE", "LIMITED", 300, [], "LINE"] call ALIVE_fnc_createProfileWaypoint;
                                    _profile = _profiles select 0;
                                    [_profile, "addWaypoint", _profileWaypoint] call ALIVE_fnc_profileEntity;

                                };

                                _totalCount = _totalCount + 1;

                                _eventTransportProfiles = _eventTransportProfiles + _transportProfiles;
                                _eventTransportVehiclesProfiles = _eventTransportVehiclesProfiles + _transportVehicleProfiles;

                            };

                            private ["_containers","_vehicle","_parachute","_soundFlyover"];

                            if(_eventType == "PR_AIRDROP") then {

                                _containers = [ALIVE_factionDefaultContainers,_eventFaction,[]] call ALIVE_fnc_hashGet;

                                if(count _containers == 0) then {
                                    _containers = [ALIVE_sideDefaultContainers,_side] call ALIVE_fnc_hashGet;
                                };

                                if(count _containers > 0) then {

                                    _position = _reinforcementPosition getPos [random(200), random(360)];

                                    if(_paraDrop) then {
                                        _position set [2,PARADROP_HEIGHT];
                                    };

                                    _vehicleClass = selectRandom _containers;

                                    //_profile = [_vehicleClass,_side,_eventFaction,_position,random(360),false,_eventFaction,_payload] call ALIVE_fnc_createProfileVehicle;

                                    _vehicle = createVehicle [_vehicleClass, _position, [], 0, "NONE"];

                                    clearItemCargoGlobal _vehicle;
                                    clearMagazineCargoGlobal _vehicle;
                                    clearWeaponCargoGlobal _vehicle;

                                    [ALiVE_SYS_LOGISTICS,"fillContainer",[_vehicle,_payload]] call ALiVE_fnc_Logistics;

                                    if(_paraDrop) then {
                                        _parachute = createvehicle ["B_Parachute_02_F",position _vehicle ,[],0,"none"];
                                        _vehicle attachto [_parachute,[0,0,(abs ((boundingbox _vehicle select 0) select 2))]];

                                        _parachute setpos position _vehicle;
                                        _parachute setdir direction _vehicle;
                                        _parachute setvelocity [0,0,-1];

                                        if (time - (missionnamespace getvariable ["bis_fnc_curatorobjectedited_paraSoundTime",0]) > 0) then {
                                            _soundFlyover = selectRandom ["BattlefieldJet1","BattlefieldJet2"];
                                            [_parachute,_soundFlyover,"say3d"] remoteExec ["bis_fnc_sayMessage"];
                                            missionnamespace setvariable ["bis_fnc_curatorobjectedited_paraSoundTime",time + 10]
                                        };

                                        [_vehicle,_parachute] spawn {
                                            _vehicle = _this select 0;
                                            _parachute = _this select 1;

                                            waituntil {isnull _parachute || isnull _vehicle};
                                            _vehicle setdir direction _vehicle;
                                            deletevehicle _parachute;

                                            [_vehicle] call ALIVE_fnc_MLAttachSmokeOrStrobe;
                                        };
                                    };

                                };

                                _totalCount = _totalCount + 1;
                            };

                        };


                        [_playerRequestProfiles,"empty",_emptyVehicleProfiles] call ALIVE_fnc_hashSet;
                        [_playerRequestProfiles,"joinIndividuals",_joinIndividualProfiles] call ALIVE_fnc_hashSet;
                        [_playerRequestProfiles,"staticIndividuals",_staticIndividualProfiles] call ALIVE_fnc_hashSet;
                        [_playerRequestProfiles,"reinforceIndividuals",_reinforceIndividualProfiles] call ALIVE_fnc_hashSet;
                        [_playerRequestProfiles,"joinGroups",_joinGroupProfiles] call ALIVE_fnc_hashSet;
                        [_playerRequestProfiles,"staticGroups",_staticGroupProfiles] call ALIVE_fnc_hashSet;
                        [_playerRequestProfiles,"reinforceGroups",_reinforceGroupProfiles] call ALIVE_fnc_hashSet;
                        [_playerRequestProfiles,"payloadGroups",_payloadGroupProfiles] call ALIVE_fnc_hashSet;
                        [_event, "playerRequestProfiles", _playerRequestProfiles] call ALIVE_fnc_hashSet;


                        [_eventCargoProfiles, "armour", _armourProfiles] call ALIVE_fnc_hashSet;
                        [_eventCargoProfiles, "infantry", _infantryProfiles] call ALIVE_fnc_hashSet;
                        [_eventCargoProfiles, "mechanised", _mechanisedProfiles] call ALIVE_fnc_hashSet;
                        [_eventCargoProfiles, "motorised", _motorisedProfiles] call ALIVE_fnc_hashSet;
                        [_eventCargoProfiles, "heli", _heliProfiles] call ALIVE_fnc_hashSet;
                        [_eventCargoProfiles, "plane", _planeProfiles] call ALIVE_fnc_hashSet;


                        // DEBUG -------------------------------------------------------------------------------------
                        if(_debug) then {
                            ["ML - Profiles created: %1 ",_totalCount] call ALiVE_fnc_dump;
                            switch(_eventType) do {
                                case "PR_STANDARD": {
                                    [_logic, "createMarker", [_reinforcementPosition,_eventFaction,"PR CONVOY START"]] call MAINCLASS;
                                };
                                case "PR_HELI_INSERT": {
                                    [_logic, "createMarker", [_reinforcementPosition,_eventFaction,"PR AIR INSERTION"]] call MAINCLASS;
                                };
                                case "PR_AIRDROP": {
                                    [_logic, "createMarker", [_eventPosition,_eventFaction,"PR AIRDROP"]] call MAINCLASS;
                                };
                            };
                        };
                        // DEBUG -------------------------------------------------------------------------------------


                        if(_totalCount > 0) then {

                            // remove the created group count
                            // from the force pool
                            _forcePool = _forcePool - _totalCount;
                            // update the global force pool
                            [ALIVE_MLGlobalRegistry,"updateGlobalForcePool",[_registryID,_forcePool]] call ALIVE_fnc_MLGlobalRegistry;

                            switch(_eventType) do {
                                case "PR_STANDARD": {

                                    // update the state of the event
                                    // next state is transport load
                                    [_event, "state", "transportLoad"] call ALIVE_fnc_hashSet;

                                    // dispatch event
                                    _logEvent = ['LOGISTICS_INSERTION', [_reinforcementPosition,_eventFaction,_side,_eventID],"Logistics"] call ALIVE_fnc_event;
                                    [ALIVE_eventLog, "addEvent",_logEvent] call ALIVE_fnc_eventLog;

                                };
                                case "PR_HELI_INSERT": {

                                    // update the state of the event
                                    // next state is transport load
                                    [_event, "state", "heliTransportStart"] call ALIVE_fnc_hashSet;

                                    // dispatch event
                                    _logEvent = ['LOGISTICS_INSERTION', [_reinforcementPosition,_eventFaction,_side,_eventID],"Logistics"] call ALIVE_fnc_event;
                                    [ALIVE_eventLog, "addEvent",_logEvent] call ALIVE_fnc_eventLog;

                                };
                                case "PR_AIRDROP": {

                                    // update the state of the event
                                    // next state is aridrop wait
                                    [_event, "state", "airdropWait"] call ALIVE_fnc_hashSet;

                                    // dispatch event
                                    _logEvent = ['LOGISTICS_DESTINATION', [_eventPosition,_eventFaction,_side,_eventID],"Logistics"] call ALIVE_fnc_event;
                                    [ALIVE_eventLog, "addEvent",_logEvent] call ALIVE_fnc_eventLog;

                                };
                            };

                            [_event, "cargoProfiles", _eventCargoProfiles] call ALIVE_fnc_hashSet;
                            [_event, "transportProfiles", _eventTransportProfiles] call ALIVE_fnc_hashSet;
                            [_event, "transportVehiclesProfiles", _eventTransportVehiclesProfiles] call ALIVE_fnc_hashSet;

                            [_logic, "prepareUnitCounts", _event] call MAINCLASS;

                            [_eventQueue, _eventID, _event] call ALIVE_fnc_hashSet;

                            // respond to player request
                            _logEvent = ['LOGCOM_RESPONSE', [_requestID,_playerID],"Logistics","REQUEST_INSERTION"] call ALIVE_fnc_event;
                            [ALIVE_eventLog, "addEvent",_logEvent] call ALIVE_fnc_eventLog;

                        }else{

                            // respond to player request
                            _logEvent = ['LOGCOM_RESPONSE', [_requestID,_playerID],"Logistics","DENIED_FORCE_CREATION"] call ALIVE_fnc_event;
                            [ALIVE_eventLog, "addEvent",_logEvent] call ALIVE_fnc_eventLog;

                            // no profiles were created
                            // nothing to do so cancel..
                            [_logic, "removeEvent", _eventID] call MAINCLASS;
                        };

                    };
                }else{

                    // no insertion point available
                    // nothing to do so cancel..
                    [_logic, "removeEvent", _eventID] call MAINCLASS;

                    // respond to player request
                    _logEvent = ['LOGCOM_RESPONSE', [_requestID,_playerID],"Logistics","DENIED_NOT_AVAILABLE"] call ALIVE_fnc_event;
                    [ALIVE_eventLog, "addEvent",_logEvent] call ALIVE_fnc_eventLog;

                };
            };
        };
    };

    case "prepareUnitCounts": {
        private _event = _args;
        private _eventCargoProfiles = [_event, "cargoProfiles"] call ALIVE_fnc_hashGet;
        private _playerRequested = [_event, "playerRequested"] call ALIVE_fnc_hashGet;
        private _playerRequestProfiles = [_event, "playerRequestProfiles"] call ALIVE_fnc_hashGet;
        private _unitCounts = [] call ALIVE_fnc_hashCreate;

        private _eventTransportProfiles = [_event, "transportProfiles"] call ALIVE_fnc_hashGet;
        [_unitCounts,"transport",count _eventTransportProfiles] call ALIVE_fnc_hashSet;

        private _eventTransportVehiclesProfiles = [_event, "transportVehiclesProfiles"] call ALIVE_fnc_hashGet;
        [_unitCounts,"transportVehicle",count _eventTransportVehiclesProfiles] call ALIVE_fnc_hashSet;

        {
            private _list = _x select 0;
            private _condition = _x select 1;
            private _categories = _x select 2;

            if (_condition) then {
                {
                    private _category = _x;
                    private _profiles = [_list, _category] call ALIVE_fnc_hashGet;
                    [_unitCounts, _category, count _profiles] call ALIVE_fnc_hashSet;
                } forEach _categories;
            };
        } forEach [
            [_eventCargoProfiles, true, ["infantry", "armour", "mechanised", "motorised", "plane", "heli"]],
            [_playerRequestProfiles, _playerRequested, ["empty", "joinIndividuals", "staticIndividuals",
                                                        "reinforceIndividuals", "joinGroups", "staticGroups",
                                                        "reinforceGroups", "payloadGroups"]]
        ];

        [_event, "initialUnitCounts", _unitCounts] call ALIVE_fnc_hashSet;
    };

    // takes an event
    // and removes any dead profileIDs from event data

    case "checkEvent": {
        private _event = _args;
        private _eventCargoProfiles = [_event, "cargoProfiles"] call ALIVE_fnc_hashGet;
        private _playerRequested = [_event, "playerRequested"] call ALIVE_fnc_hashGet;
        private _playerRequestProfiles = [_event, "playerRequestProfiles"] call ALIVE_fnc_hashGet;
        private _totalCount = 0;
        private _unitCounts = [] call ALIVE_fnc_hashCreate;

        private _eventTransportProfiles = [_event, "transportProfiles"] call ALIVE_fnc_hashGet;
        _eventTransportProfiles = [_logic, "removeUnregisteredProfiles", _eventTransportProfiles] call MAINCLASS;

        [_unitCounts, "transport", count _eventTransportProfiles] call ALIVE_fnc_hashSet;
        [_event, "transportProfiles", _eventTransportProfiles] call ALIVE_fnc_hashSet;

        private _eventTransportVehiclesProfiles = [_event, "transportVehiclesProfiles"] call ALIVE_fnc_hashGet;
        _eventTransportVehiclesProfiles = [_logic, "removeUnregisteredProfiles", _eventTransportVehiclesProfiles] call MAINCLASS;

        [_unitCounts,"transportVehicle", count _eventTransportVehiclesProfiles] call ALIVE_fnc_hashSet;
        [_event, "transportVehiclesProfiles", _eventTransportVehiclesProfiles] call ALIVE_fnc_hashSet;

        {
            private _list = _x select 0;
            private _condition = _x select 1;
            private _categories = _x select 2;

            if (_condition) then {
                {
                    private _category = _x;
                    private _profiles = [_list, _category] call ALIVE_fnc_hashGet;

                    {
                        private _profile = _x;
                        _profile = [_logic, "removeUnregisteredProfiles", _profile] call MAINCLASS;
                        _profiles set [_forEachIndex, _profile];
                    } forEach _profiles;

                    _totalCount = _totalCount + (count _profiles);
                    [_unitCounts, _category, count _profiles] call ALIVE_fnc_hashSet;
                    [_list, _category, _profiles] call ALIVE_fnc_hashSet;
                } forEach _categories;
            };
        } forEach [
            [_eventCargoProfiles, true, ["infantry", "armour", "mechanised", "motorised", "plane", "heli"]],
            [_playerRequestProfiles, _playerRequested, ["empty", "joinIndividuals", "staticIndividuals",
                                                        "reinforceIndividuals", "joinGroups", "staticGroups",
                                                        "reinforceGroups", "payloadGroups"]]
        ];

        [_event, "currentUnitCounts", _unitCounts] call ALIVE_fnc_hashSet;

        _result = _totalCount;
    };

    // takes an array of profileIDs
    // and returns a new array with the inactive profileIDs removed

    case "removeUnregisteredProfiles": {

        private _profiles = _args;

        _result = _profiles select { !isNil { [ALIVE_profileHandler, "getProfile", _x] call ALIVE_fnc_profileHandler } };

    };

    // takes an entity profile
    // and returns true if it has zero active waypoints

    case "checkWaypointCompleted": {

        private ["_entityProfile","_debug","_active","_profileID","_waypointCompleted"];

        _entityProfile = _args;

        _debug = [_logic, "debug"] call MAINCLASS;

        _active = _entityProfile select 2 select 1;
        _profileID = _entityProfile select 2 select 4;

        _waypointCompleted = false;

        if(_active) then {
            private ["_group","_leader","_currentPosition","_currentWaypoint","_waypoints","_waypointCount",
            "_destination","_completionRadius","_distance"];

            _group = _entityProfile select 2 select 13;

            if !(!isnil "_group" && {typeName _group == "GROUP"}) exitwith {_waypointCompleted = true};

            _leader = leader _group;
            _currentPosition = position _leader;
            _currentWaypoint = currentWaypoint _group;
            _waypoints = waypoints _group;

            if (count _waypoints == 0) exitWith {_waypointCompleted = true};

            _currentWaypoint = _waypoints select ((count _waypoints)-1);

            if!(isNil "_currentWaypoint") then {

                _destination = waypointPosition _currentWaypoint;
                _completionRadius = waypointCompletionRadius _currentWaypoint;

                _completionRadius = (_completionRadius * 2) + 20;

                _distance = _currentPosition distance _destination;

                if(_distance < _completionRadius) then {
                    _waypointCompleted = true;
                };

            }else{
                _waypointCompleted = true;
            }

        } else {
            private ["_waypoints"];

            _waypoints = [_entityProfile,"waypoints"] call ALIVE_fnc_hashGet;

            if!(isNil "_waypoints") then {
                if(count _waypoints == 0) then {
                    _waypointCompleted = true;
                };
            }else{
                _waypointCompleted = true;
            }
        };

        _result = _waypointCompleted;

    };

    case "setHelicopterTravel": {

        private _entityProfile = _args;

        private _active = _entityProfile select 2 select 1;

        if(_active) then {

            private _group = _entityProfile select 2 select 13;

            _group setBehaviour "CARELESS";
            _group allowFleeing 0;
            _group setCombatMode "BLUE";
            _group setSpeedMode "FULL";

            {
                private _unit = _x;
                _unit disableAI "AUTOTARGET";
                _unit disableAI "TARGET";
                _unit setSkill 1;

                // Fly faster when enemies are nearby
                private _nearEnemies = (position _unit) nearEntities [["Man","Car","Tank","Air"], 1500];
                private _enemyNear = _nearEnemies select { side _x != side _unit };
                if (count _enemyNear > 0) then {
                    _unit forceSpeed 70;
                } else {
                    _unit forceSpeed 50;
                };
            } forEach (units _group);

        }else{
            [_entityProfile,"spawn"] call ALIVE_fnc_profileEntity;
        }

    };
    
    case "forceHelicopterLanding": {

        // Called when a helicopter transport has been hovering too long
        // at its destination without landing. Forces a landAt command
        // to a validated nearby position.

        private _entityProfile = _args select 0;
        private _targetPos     = _args select 1;
        private _debug         = [_logic, "debug"] call MAINCLASS;

        private _active = _entityProfile select 2 select 1;

        if (_active) then {
            private _heli = _entityProfile select 2 select 10;

            if (!isNull _heli && alive _heli) then {

                private _posASL    = getPosASL _heli;
                private _groundASL = getTerrainHeightASL _posASL;
                private _heightAGL = (_posASL select 2) - _groundASL;
                private _spd       = speed _heli;

                // Only intervene if clearly hovering - airborne and slow
                if (_heightAGL > 5 && _spd < 8) then {

                // Validate target position before searching near it
                if (typeName _targetPos != "ARRAY" || count _targetPos < 2) then {
                    ["ML - forceHelicopterLanding: WARNING invalid _targetPos %1 for heli %2, using heli current position",
                        _targetPos, _heli] call ALiVE_fnc_dump;
                    _targetPos = getPosATL _heli;
                };

                // Use the helicopter's current position as the land target,
                // offset slightly to avoid obstructions directly below.
                // Use heli's current position projected to ground as land target
                // BIS_fnc_findSafePos is unreliable on Takistan and can return sky positions
                private _landPos = getPosATL _heli;
                _landPos set [2, 0];

                if (_debug) then {
                    ["ML - forceHelicopterLanding: Heli %1 hovering at %2m AGL speed %3. Forcing land at %4",
                        _heli, _heightAGL, _spd, _landPos] call ALiVE_fnc_dump;
                };

                // Clear existing waypoints and issue direct land command
                private _group = _entityProfile select 2 select 13;
                if (!isNull _group) then {
                    while {count (waypoints _group) > 0} do {
                        deleteWaypoint [_group, 0];
                    };
                };

                // landAt requires an object - create a temporary helipad at the target pos
                if (typeName _landPos == "ARRAY" && count _landPos >= 2) then {

                    if (count _landPos == 2) then { _landPos pushback 0; };

                    private _tempPad = createVehicle ["Land_HelipadEmpty_F", _landPos, [], 0, "CAN_COLLIDE"];

                    [_heli, _tempPad] spawn {
                        private _heli   = _this select 0;
                        private _tmpPad = _this select 1;
                        _heli landAt _tmpPad;
                        // Wait until heli has landed or 60s timeout, then delete pad
                        private _t = 0;
                        waitUntil { sleep 2; _t = _t + 2; (isTouchingGround _heli || !alive _heli || _t > 60) };
                        deleteVehicle _tmpPad;
                    };

                    ["ML - forceHelicopterLanding: landAt issued to %1 via temp helipad at %2", _heli, _landPos] call ALiVE_fnc_dump;
                } else {
                    ["ML - forceHelicopterLanding: WARNING could not determine safe land position for %1, skipping landAt",
                        _heli] call ALiVE_fnc_dump;
                };
                };
            };
        };
    };
    
    case "spawnStalledUnitWatchdog": {

        // Monitors a set of cargo profiles after delivery.
        // If units have not moved meaningfully within the check period
        // a new waypoint toward the event destination is issued to
        // kick them out of any idle state before OPCOM picks them up.
        // Args: [_cargoProfileIDs, _eventPosition, _eventFaction, _side]

        private _profileIDs  = _args select 0;
        private _destPos     = _args select 1;
        private _faction     = _args select 2;
        private _side        = _args select 3;
        private _debug       = [_logic, "debug"] call MAINCLASS;

        if (_debug) then {
            ["ML - spawnStalledUnitWatchdog: Starting for %1 profiles destination %2",
                count _profileIDs, _destPos] call ALiVE_fnc_dump;
        };

        [_profileIDs, _destPos, _faction, _side, _debug] spawn {

            private _profileIDs = _this select 0;
            private _destPos    = _this select 1;
            private _faction    = _this select 2;
            private _side       = _this select 3;
            private _debug      = _this select 4;

            // Allow time for units to dismount and OPCOM to pick them up normally
            sleep 120;

            private _checkInterval   = 60;
            private _maxChecks       = 5;
            private _movementThreshold = 50; // metres - less than this = stalled

            for "_check" from 1 to _maxChecks do {

                sleep _checkInterval;

                {
                    private _profileID = _x;
                    private _profile = [ALIVE_profileHandler, "getProfile", _profileID] call ALIVE_fnc_profileHandler;

                    if (!isNil "_profile") then {

                        private _active   = _profile select 2 select 1;
                        private _busy     = [_profile, "busy", false] call ALIVE_fnc_hashGet;
                        private _pos      = _profile select 2 select 2;
                        private _profileType = _profile select 2 select 5;

                        // Only check entity profiles (infantry/crews) not vehicles
                        if (_profileType == "entity" && !_busy) then {

                            private _waypoints = [_profile, "waypoints"] call ALIVE_fnc_hashGet;
                            private _hasWaypoints = !isNil "_waypoints" && {count _waypoints > 0};

                            if (_active) then {
                                // Profile is spawned - check actual unit movement
                                private _group = _profile select 2 select 13;
                                if (!isNull _group) then {
                                    private _leader = leader _group;
                                    private _distToDest = position _leader distance _destPos;
                                    private _currentWPs = waypoints _group;

                                    // If close enough to destination consider done
                                    if (_distToDest < 200) exitWith {};

                                    // If no waypoints and not at destination - stalled
                                    if (count _currentWPs == 0) then {
                                        if (_debug) then {
                                            ["ML - spawnStalledUnitWatchdog: Profile %1 active, no waypoints, dist to dest %2m. Assigning move waypoint.",
                                                _profileID, _distToDest] call ALiVE_fnc_dump;
                                        };

                                        private _moveWP = _group addWaypoint [_destPos, 50];
                                        _moveWP setWaypointType "MOVE";
                                        _moveWP setWaypointBehaviour "AWARE";
                                        _moveWP setWaypointCombatMode "YELLOW";
                                        _moveWP setWaypointSpeed "NORMAL";
                                        _group setCurrentWaypoint _moveWP;
                                    };
                                };
                            } else {
                                // Profile not spawned - if no waypoints assign one
                                if (!_hasWaypoints) then {
                                    private _distToDest = _pos distance _destPos;

                                    if (_distToDest > 200) then {
                                        if (_debug) then {
                                            ["ML - spawnStalledUnitWatchdog: Profile %1 inactive, no waypoints, dist %2m. Assigning profile waypoint.",
                                                _profileID, _distToDest] call ALiVE_fnc_dump;
                                        };

                                        private _profileWaypoint = [_destPos, 50, "MOVE", "AWARE", 100, [], "LINE"] call ALIVE_fnc_createProfileWaypoint;
                                        [_profile, "addWaypoint", _profileWaypoint] call ALIVE_fnc_profileEntity;
                                    };
                                };
                            };
                        };
                    };
                } forEach _profileIDs;
            };

            if (_debug) then {
                ["ML - spawnStalledUnitWatchdog: Watchdog complete for destination %1", _destPos] call ALiVE_fnc_dump;
            };
        };
    };

    case "unloadTransport": {

        private ["_event","_entityProfile","_active","_profileID","_vehiclesInCommandOf","_debug","_eventID","_eventData","_eventCargoProfiles",
        "_eventTransportProfiles","_eventTransportVehiclesProfiles","_playerRequested","_playerRequestProfiles","_eventPosition",
        "_eventType","_playerID","_requestID","_type","_emptyProfiles","_payloadProfiles","_vehicleProfileID","_vehicleProfile","_eventForceMakeup"];

        _event = _args select 0;
        _entityProfile = _args select 1;

        _active = _entityProfile select 2 select 1;
        _profileID = _entityProfile select 2 select 4;
        _vehiclesInCommandOf = _entityProfile select 2 select 8;

        if(count _vehiclesInCommandOf == 0) exitWith { _result = false; };

        _vehicleProfileID = _vehiclesInCommandOf select 0;

        _vehicleProfile = [ALIVE_profileHandler, "getProfile", _vehicleProfileID] call ALIVE_fnc_profileHandler;

        if(isNil "_vehicleProfile") exitWith { _result = false; };

        _debug = [_logic, "debug"] call MAINCLASS;

        _eventID = [_event, "id"] call ALIVE_fnc_hashGet;
        _eventData = [_event, "data"] call ALIVE_fnc_hashGet;
        _eventCargoProfiles = [_event, "cargoProfiles"] call ALIVE_fnc_hashGet;
        _eventTransportProfiles = [_event, "transportProfiles"] call ALIVE_fnc_hashGet;
        _eventTransportVehiclesProfiles = [_event, "transportVehiclesProfiles"] call ALIVE_fnc_hashGet;
        _playerRequested = [_event, "playerRequested"] call ALIVE_fnc_hashGet;
        _playerRequestProfiles = [_event, "playerRequestProfiles"] call ALIVE_fnc_hashGet;

        _eventForceMakeup = _eventData select 3;
        _eventPosition = _eventData select 0;
        _eventType = _eventData select 4;
        _type = "STANDARD";

        if(_playerRequested) then {
            _playerID = _eventData select 5;
            _requestID = _eventForceMakeup select 0;
            _emptyProfiles = [_playerRequestProfiles,"empty"] call ALIVE_fnc_hashGet;
            _payloadProfiles = [_playerRequestProfiles,"payloadGroups"] call ALIVE_fnc_hashGet;

            {
                if(_profileID in _x) then {
                    _type = "EMPTY";
                };
            } forEach _emptyProfiles;

            {
                if(_profileID in _x) then {
                    _type = "PAYLOAD";
                };
            } forEach _payloadProfiles;

        };

        switch(_type) do {
            case "STANDARD":{

                if(_active) then {

                    private ["_group","_position","_heliPad","_inCargo","_cargoProfileID","_cargoProfile"];

                    _inCargo = _vehicleProfile select 2 select 9;

                    if(count _inCargo > 0) then {
                        {
                            _cargoProfileID = _x;
                            _cargoProfile = [ALIVE_profileHandler, "getProfile", _cargoProfileID] call ALIVE_fnc_profileHandler;

                            if!(isNil "_cargoProfile") then {
                                [_cargoProfile,_vehicleProfile] call ALIVE_fnc_removeProfileVehicleAssignment;

                                // If the cargo profile is active (spawned), physically
                                // unload the units and move them to their own group so
                                // they are not commanded by the heli crew
                                private _cargoActive = _cargoProfile select 2 select 1;
                                if (_cargoActive) then {
                                    private _cargoUnits = _cargoProfile select 2 select 21;
                                    private _heliVehicle = _vehicleProfile select 2 select 10;

                                    if (count _cargoUnits > 0) then {
                                        // Create a new group on the same side for the infantry
                                        private _newGroup = createGroup (side (_cargoUnits select 0));

                                        {
                                            if (alive _x) then {
                                                unassignVehicle _x;
                                                [_x] orderGetIn false;
                                                _x moveOut _heliVehicle;
                                                [_x] joinSilent _newGroup;
                                            };
                                        } forEach _cargoUnits;

                                        if (_debug) then {
                                            ["ML - unloadTransportHelicopter: Moved %1 units from heli crew group to new group %2",
                                                count _cargoUnits, _newGroup] call ALiVE_fnc_dump;
                                        };
                                    };
                                };
                            };

                        } forEach _inCargo;
                    };

                }else{

                    private ["_inCargo","_cargoProfileID","_cargoProfile","_position"];

                    _inCargo = _vehicleProfile select 2 select 9;

                    if(count _inCargo > 0) then {
                        {
                            _cargoProfileID = _x;
                            _cargoProfile = [ALIVE_profileHandler, "getProfile", _cargoProfileID] call ALIVE_fnc_profileHandler;

                            _position = _vehicleProfile select 2 select 2;
                            _position set [2,0];

                            if!(isNil "_cargoProfile") then {
                             [_cargoProfile,_vehicleProfile] call ALIVE_fnc_removeProfileVehicleAssignment;
                             [_cargoProfile,"position",_position] call ALIVE_fnc_profileEntity;
                            };

                        } forEach _inCargo;
                    };

                 };

            };
            case "EMPTY":{

                if!(_active) then {

                    private ["_group","_position","_heliPad"];

                    [_entityProfile,_vehicleProfile] call ALIVE_fnc_removeProfileVehicleAssignment;

                    _position = _vehicleProfile select 2 select 2;
                    _position set [2,0];
                    [_vehicleProfile,"position",_position] call ALIVE_fnc_profileVehicle;
                    [_vehicleProfile,"hasSimulated",false] call ALIVE_fnc_profileVehicle;
                    [_vehicleProfile,"engineOn",false] call ALIVE_fnc_profileVehicle;
                    [_vehicleProfile,"despawnPosition",_position] call ALIVE_fnc_profileVehicle;

                    [_entityProfile, "destroy"] call ALIVE_fnc_profileEntity;
                    //[ALIVE_profileHandler, "unregisterProfile", _entityProfile] call ALIVE_fnc_profileHandler;


                }else{

                    [_entityProfile,_vehicleProfile] call ALIVE_fnc_removeProfileVehicleAssignment;

                };

            };
            case "PAYLOAD":{

                private ["_index","_heliPad"];

              /*  _index = _eventTransportProfiles find _profileID;
                _eventTransportProfiles set [_index,objNull];
                _eventTransportProfiles = _eventTransportProfiles - [objNull];
                [_event, "transportProfiles",_eventTransportProfiles] call ALIVE_fnc_hashSet;


                _index = _eventTransportVehiclesProfiles find _vehicleProfileID;
                _eventTransportVehiclesProfiles set [_index,objNull];
                _eventTransportVehiclesProfiles = _eventTransportVehiclesProfiles - [objNull];
                [_event, "transportVehiclesProfiles",_eventTransportVehiclesProfiles] call ALIVE_fnc_hashSet; */

            };
        };

    };

    case "unloadTransportHelicopter": {

        private ["_event","_entityProfile","_active","_profileID","_vehiclesInCommandOf","_debug","_eventID","_eventData","_eventCargoProfiles",
        "_eventTransportProfiles","_eventTransportVehiclesProfiles","_playerRequested","_playerRequestProfiles","_eventPosition",
        "_eventType","_playerID","_requestID","_type","_emptyProfiles","_payloadProfiles","_vehicleProfileID","_vehicleProfile","_eventForceMakeup","_eventAssets","_slingloading"];

        _event = _args select 0;
        _entityProfile = _args select 1;

        _active = _entityProfile select 2 select 1;
        _profileID = _entityProfile select 2 select 4;
        _vehiclesInCommandOf = _entityProfile select 2 select 8;

        if(count _vehiclesInCommandOf == 0) exitWith { _result = false; };

        _vehicleProfileID = _vehiclesInCommandOf select 0;

        _vehicleProfile = [ALIVE_profileHandler, "getProfile", _vehicleProfileID] call ALIVE_fnc_profileHandler;

        if(isNil "_vehicleProfile") exitWith { _result = false; };

        _debug = [_logic, "debug"] call MAINCLASS;

        _eventID = [_event, "id"] call ALIVE_fnc_hashGet;
        _eventData = [_event, "data"] call ALIVE_fnc_hashGet;
        _eventCargoProfiles = [_event, "cargoProfiles"] call ALIVE_fnc_hashGet;
        _eventTransportProfiles = [_event, "transportProfiles"] call ALIVE_fnc_hashGet;
        _eventTransportVehiclesProfiles = [_event, "transportVehiclesProfiles"] call ALIVE_fnc_hashGet;
        _playerRequested = [_event, "playerRequested"] call ALIVE_fnc_hashGet;
        _playerRequestProfiles = [_event, "playerRequestProfiles"] call ALIVE_fnc_hashGet;

        _eventAssets = [_event, "eventAssets"] call ALIVE_fnc_hashGet;

        _eventForceMakeup = _eventData select 3;
        _eventPosition = _eventData select 0;
        _eventType = _eventData select 4;
        _type = "STANDARD";

        _slingloading = [_vehicleProfile, "slingloading", false] call ALiVE_fnc_hashGet;

        if(_playerRequested) then {
            _playerID = _eventData select 5;
            _requestID = _eventForceMakeup select 0;
            _emptyProfiles = [_playerRequestProfiles,"empty"] call ALIVE_fnc_hashGet;
            _payloadProfiles = [_playerRequestProfiles,"payloadGroups"] call ALIVE_fnc_hashGet;

            {
                if(_profileID in _x) then {
                    _type = "EMPTY";
                };
            } forEach _emptyProfiles;

            {
                if(_profileID in _x) then {
                    _type = "PAYLOAD";
                };
            } forEach _payloadProfiles;

        };

        if(!_playerRequested && _slingLoading) then {
            _payloadProfiles = [_eventCargoProfiles,"payloadGroups"] call ALIVE_fnc_hashGet;

            {
                if(_profileID in _x) then {
                    _type = "PAYLOAD";
                };
            } forEach _payloadProfiles;

        };

        switch(_type) do {
            case "STANDARD":{

                if(_active) then {

                    private ["_group","_position","_heliPad","_inCargo","_cargoProfileID","_cargoProfile"];

                    _group = _entityProfile select 2 select 13;
                    _group setBehaviour "CARELESS";

                    private _blacklistPositions = [];
                    {
                        if (typeof _x == "Land_HelipadEmpty_F") then {
                            _blacklistPositions pushback [getpos _x, 20];
                        };
                    } foreach _eventAssets;

                    _position = [_logic, "findHelicopterLandingPos", [
                        _eventPosition, 200, 600
                    ]] call MAINCLASS;

                    _heliPad = "Land_HelipadEmpty_F" createVehicle _position;

                    _eventAssets pushback _heliPad;
                    [_event, "eventAssets",_eventAssets] call ALIVE_fnc_hashSet;

                    _inCargo = _vehicleProfile select 2 select 9;

                    if(count _inCargo > 0) then {
                        {
                            _cargoProfileID = _x;
                            _cargoProfile = [ALIVE_profileHandler, "getProfile", _cargoProfileID] call ALIVE_fnc_profileHandler;

                            if!(isNil "_cargoProfile") then {
                                [_cargoProfile,_vehicleProfile] call ALIVE_fnc_removeProfileVehicleAssignment;
                            };

                        } forEach _inCargo;
                    };

                    private _vehiclesInCommandOf = _entityProfile select 2 select 8;
                    {
                        private _vehicleProfile = [ALIVE_profileHandler,"getProfile", _x] call ALiVE_fnc_profileHandler;
                        private _isActive = _vehicleProfile select 2 select 1;
                        if (_isActive) then {
                            private _vehicleObject = _vehicleProfile select 2 select 10;
                            if (_vehicleObject iskindof "Helicopter") then {
                                private _landPos = getpos _helipad;

                                // Issue landAt via temp helipad so heli physically lands
                                private _tmpPad = createVehicle ["Land_HelipadEmpty_F", _landPos, [], 0, "CAN_COLLIDE"];
                                _vehicleObject landAt _tmpPad;

                                // Spawn thread: wait for landing then physically unload troops
                                [_vehicleObject, _tmpPad, _inCargo, _vehicleProfile, _debug] spawn {
                                    private _heli    = _this select 0;
                                    private _pad     = _this select 1;
                                    private _cargo   = _this select 2;
                                    private _vProf   = _this select 3;
                                    private _dbg     = _this select 4;

                                    // Wait until landed or 90s timeout
                                    private _t = 0;
                                    waitUntil {
                                        sleep 2; _t = _t + 2;
                                        isTouchingGround _heli || !alive _heli || _t > 90
                                    };

                                    deleteVehicle _pad;

                                    if (alive _heli) then {
                                        // Physically move all cargo units out
                                        {
                                            private _profID = _x;
                                            private _prof = [ALIVE_profileHandler, "getProfile", _profID] call ALIVE_fnc_profileHandler;
                                            if !(isNil "_prof") then {
                                                private _units = _prof select 2 select 21;
                                                if !(isNil "_units") then {
                                                    private _newGroup = if (count _units > 0) then {
                                                        createGroup (side (_units select 0))
                                                    } else { grpNull };

                                                    {
                                                        if (alive _x) then {
                                                            unassignVehicle _x;
                                                            [_x] orderGetIn false;
                                                            _x moveOut _heli;
                                                            if !(isNull _newGroup) then {
                                                                [_x] joinSilent _newGroup;
                                                            };
                                                        };
                                                    } forEach _units;

                                                    if (_dbg) then {
                                                        ["ML - unloadTransportHelicopter: Physically unloaded %1 units from heli", count _units] call ALiVE_fnc_dump;
                                                    };
                                                };
                                            };
                                        } forEach _cargo;
                                    };
                                };

                                // Profile waypoint to the land position (fallback for virtual helis)
                                private _landWaypoint = [_landPos, 15, "MOVE"] call ALIVE_fnc_createProfileWaypoint;
                                [_entityProfile, "clearWaypoints"] call ALIVE_fnc_profileEntity;
                                [_entityProfile, "addWaypoint", _landWaypoint] call ALIVE_fnc_profileEntity;
                            };
                        };
                    } foreach _vehiclesInCommandOf;
                }else{

                    private ["_position","_inCargo","_cargoProfileID","_cargoProfile"];

                    _inCargo = _vehicleProfile select 2 select 9;
                    _position = _eventPosition getPos [random(DESTINATION_VARIANCE), random(360)];

                    if(count _inCargo > 0) then {
                        {
                            _cargoProfileID = _x;
                            _cargoProfile = [ALIVE_profileHandler, "getProfile", _cargoProfileID] call ALIVE_fnc_profileHandler;

                            if!(isNil "_cargoProfile") then {
                                [_cargoProfile,_vehicleProfile] call ALIVE_fnc_removeProfileVehicleAssignment;
                                [_cargoProfile,"position",_position] call ALIVE_fnc_profileEntity;
                            };

                        } forEach _inCargo;
                    };

                };

            };
            case "EMPTY":{

                if(_active) then {

                    private ["_group","_position","_heliPad"];

                    _group = _entityProfile select 2 select 13;
                    _group setBehaviour "CARELESS";

                    _position = _eventPosition getPos [random(DESTINATION_VARIANCE), random(360)];
                    _position = _position findEmptyPosition [10,200];

                    if(count _position == 0) then {
                        _position = _eventPosition getPos [random(DESTINATION_VARIANCE), random(360)];
                    };
                    _heliPad = "Land_HelipadEmpty_F" createVehicle _position;

                    _eventAssets pushback _heliPad;
                    [_event, "eventAssets",_eventAssets] call ALIVE_fnc_hashSet;

                    [_entityProfile,_vehicleProfile] call ALIVE_fnc_removeProfileVehicleAssignment;

                }else{

                    private ["_position"];

                    [_entityProfile,_vehicleProfile] call ALIVE_fnc_removeProfileVehicleAssignment;

                    _position = _vehicleProfile select 2 select 2;
                    _position set [2,0];
                    [_vehicleProfile,"position",_position] call ALIVE_fnc_profileVehicle;
                    [_vehicleProfile,"hasSimulated",false] call ALIVE_fnc_profileVehicle;
                    [_vehicleProfile,"engineOn",false] call ALIVE_fnc_profileVehicle;
                    [_vehicleProfile,"despawnPosition",_position] call ALIVE_fnc_profileVehicle;

                    [_entityProfile, "destroy"] call ALIVE_fnc_profileEntity;
                    //[ALIVE_profileHandler, "unregisterProfile", _entityProfile] call ALIVE_fnc_profileHandler;

                };

            };
            case "PAYLOAD":{

                private ["_index","_heliPad"];

               /* _index = _eventTransportProfiles find _profileID;
                _eventTransportProfiles set [_index,objNull];
                _eventTransportProfiles = _eventTransportProfiles - [objNull];
                [_event, "transportProfiles",_eventTransportProfiles] call ALIVE_fnc_hashSet;


                _index = _eventTransportVehiclesProfiles find _vehicleProfileID;
                _eventTransportVehiclesProfiles set [_index,objNull];
                _eventTransportVehiclesProfiles = _eventTransportVehiclesProfiles - [objNull];
                [_event, "transportVehiclesProfiles",_eventTransportVehiclesProfiles] call ALIVE_fnc_hashSet; */


                if(_active) then {

                    private ["_vehicle","_group","_position","_heliPad"];

                    _vehicle = _vehicleProfile select 2 select 10;
                    _group = _entityProfile select 2 select 13;
                    _group setBehaviour "CARELESS";

                    // _position = _eventPosition getPos [random(DESTINATION_VARIANCE), random(360)];
                    // _position = _position findEmptyPosition [10,200];

                    private _position = [_logic, "findHelicopterLandingPos", [
                        _eventPosition, 200, 600
                    ]] call MAINCLASS;

                    _heliPad = "Land_HelipadEmpty_F" createVehicle _position;

                    _eventAssets pushback _heliPad;
                    [_event, "eventAssets",_eventAssets] call ALIVE_fnc_hashSet;

                    if!(isNil "_vehicle") then {

                        [_vehicle, _slingloading, _position, _eventPosition] spawn {

                            _vehicle = _this select 0;
                            _slingloading = _this select 1;
                            _position = _this select 2;
                            _eventPosition = _this select 3;

                            sleep 3;

                            while { ( (alive _vehicle) && !(unitReady _vehicle) ) } do {
                                sleep 2;
                            };

                            if (alive _vehicle) then {
                                if (_slingLoading) then {

                                    _slingloadVehicle = getSlingLoad _vehicle;

                                    // If slingloading a boat, find the nearest patch of water
                                    If (_slingloadVehicle isKindOf "Ship") then {
                                        _position = [
                                            _eventPosition, // center position
                                            0, // minimum distance
                                            100, // maximum distance
                                            (sizeOf typeOf _slingloadVehicle) / 2, // minimum to nearest object
                                            2, // water mode
                                            0, // gradient
                                            0, // shore mode
                                            [], // blacklist
                                            [
                                                _eventPosition, // default position on land
                                                _eventPosition // default position on water
                                            ]
                                        ] call bis_fnc_findSafePos;
                                    };

                                    _vehicle setVariable ["alive_ml_slingload_object", _slingloadVehicle];

                                    _wp = group _vehicle addWaypoint [_position, 0];
                                    _wp setWaypointType "UNHOOK";
                                    _wp setWaypointStatements ["true",
                                        "_ID = (vehicle this) getVariable ['profileID',''];
                                        _profile = [ALIVE_profileHandler,'getProfile',_ID] call ALIVE_fnc_profileHandler;
                                        _slingload = [_profile, 'slingload'] call ALIVE_fnc_profileVehicle;
                                        _slungID = _slingload select 0;
                                        if (typeName _slungID == 'ARRAY') then {
                                            _slungprofile = [ALIVE_profileHandler,'getProfile',_slungID select 0] call ALIVE_fnc_profileHandler;
                                            [_slungprofile, 'slung', []] call ALIVE_fnc_hashSet;
                                            [_slungProfile,'spawnType',[]] call ALIVE_fnc_profileVehicle;
                                        } else {
                                            [(vehicle this) getVariable [""alive_ml_slingload_object"", objNull]] spawn ALIVE_fnc_MLAttachSmokeOrStrobe;
                                        };
                                        [_profile, 'slingload', []] call ALIVE_fnc_profileVehicle;
                                        [_profile, 'slingloading', false] call ALIVE_fnc_hashSet;"
                                    ];
                                    // [_vehicle] call ALiVE_fnc_unhookRemote;
                                } else {
                                   [_vehicle,"LAND"] call ALiVE_fnc_landRemote;
                                };
                            };

                        };

                    };

                }else{

                    private ["_position"];

                    _position = _vehicleProfile select 2 select 2;
                    _position set [2,0];
                    [_vehicleProfile,"position",_position] call ALIVE_fnc_profileVehicle;
                    [_vehicleProfile,"hasSimulated",false] call ALIVE_fnc_profileVehicle;
                    [_vehicleProfile,"engineOn",false] call ALIVE_fnc_profileVehicle;
                    [_vehicleProfile,"despawnPosition",_position] call ALIVE_fnc_profileVehicle;

                    // Update any slingload
                    _slungID = ([_vehicleProfile, "slingload"] call ALIVE_fnc_profileVehicle) select 0;
                    if (typeName _slungID == "ARRAY") then {
                        _slungprofile = [ALIVE_profileHandler,'getProfile',_slungID] call ALIVE_fnc_profileHandler;
                        [_slungprofile, "slung", []] call ALIVE_fnc_hashSet;
                        [_slungProfile,"position",_position] call ALIVE_fnc_profileVehicle;
                        [_slungProfile,"despawnPosition",_position] call ALIVE_fnc_profileVehicle;
                        [_slungProfile,"spawnType",[]] call ALIVE_fnc_profileVehicle;
                    };
                    [_vehicleProfile,"spawnType",[]] call ALIVE_fnc_profileVehicle;
                    [_vehicleProfile,"slingload",[]] call ALIVE_fnc_profileVehicle;
                    [_vehicleProfile, 'slingloading', false] call ALIVE_fnc_hashSet;

                };

            };
        };

    };

    case "setEventProfilesAvailable": {

        // logistics event complete
        // release profiles to OPCOM
        // control if AI requested
        // if player requested, it's more
        // complicated

        private ["_debug","_event","_eventData","_eventID","_eventFaction","_side","_eventPosition","_eventCargoProfiles","_infantryProfiles","_armourProfiles",
        "_mechanisedProfiles","_motorisedProfiles","_planeProfiles","_heliProfiles","_profile","_eventAssets","_finalDestination","_logEvent"];

        _debug = [_logic, "debug"] call MAINCLASS;
        _event = _args;

        _eventData = [_event, "data"] call ALIVE_fnc_hashGet;

        _eventID = [_event, "id"] call ALIVE_fnc_hashGet;
        _eventFaction = _eventData select 1;
        _side = _eventData select 2;

        _eventPosition = _eventData select 0;
        _eventCargoProfiles = [_event, "cargoProfiles"] call ALIVE_fnc_hashGet;

        _infantryProfiles = [_eventCargoProfiles, 'infantry'] call ALIVE_fnc_hashGet;
        _armourProfiles = [_eventCargoProfiles, 'armour'] call ALIVE_fnc_hashGet;
        _mechanisedProfiles = [_eventCargoProfiles, 'mechanised'] call ALIVE_fnc_hashGet;
        _motorisedProfiles = [_eventCargoProfiles, 'motorised'] call ALIVE_fnc_hashGet;
        _planeProfiles = [_eventCargoProfiles, 'plane'] call ALIVE_fnc_hashGet;
        _heliProfiles = [_eventCargoProfiles, 'heli'] call ALIVE_fnc_hashGet;

        _eventAssets = [_event, "eventAssets"] call ALIVE_fnc_hashGet;

        {
            deleteVehicle _x;
        } forEach _eventAssets;

        if!(_playerRequested) then {

            // AI requested
            // set all cargo profiles as not busy

            {
                _profile = [ALIVE_profileHandler, "getProfile", _x select 0] call ALIVE_fnc_profileHandler;
                if!(isNil "_profile") then {
                    [_profile,"busy",false] call ALIVE_fnc_hashSet;
                };

            } forEach _infantryProfiles;

            {
                {
                    _profile = [ALIVE_profileHandler, "getProfile", _x] call ALIVE_fnc_profileHandler;
                    if!(isNil "_profile") then {
                        [_profile,"busy",false] call ALIVE_fnc_hashSet;
                    };
                } forEach _x;

            } forEach _armourProfiles;

            {
                {
                    _profile = [ALIVE_profileHandler, "getProfile", _x] call ALIVE_fnc_profileHandler;
                    if!(isNil "_profile") then {
                        [_profile,"busy",false] call ALIVE_fnc_hashSet;
                    };
                } forEach _x;

            } forEach _mechanisedProfiles;

            {
                {
                    _profile = [ALIVE_profileHandler, "getProfile", _x] call ALIVE_fnc_profileHandler;
                    if!(isNil "_profile") then {
                        [_profile,"busy",false] call ALIVE_fnc_hashSet;
                    };
                } forEach _x;

            } forEach _motorisedProfiles;

            {
                {
                    _profile = [ALIVE_profileHandler, "getProfile", _x] call ALIVE_fnc_profileHandler;
                    if!(isNil "_profile") then {
                        [_profile,"busy",false] call ALIVE_fnc_hashSet;
                    };
                } forEach _x;

            } forEach _planeProfiles;

            {
                {
                    _profile = [ALIVE_profileHandler, "getProfile", _x] call ALIVE_fnc_profileHandler;
                    if!(isNil "_profile") then {
                        [_profile,"busy",false] call ALIVE_fnc_hashSet;
                    };
                } forEach _x;

            } forEach _heliProfiles;


            // -----------------------------------------------------------------
            // FIX: Start stalled unit watchdog for all released cargo profiles
            // to ensure units move toward their destination if OPCOM does not
            // pick them up promptly after delivery.
            // -----------------------------------------------------------------
            private _allCargoProfileIDs = [];
            {
                if (count _x > 0) then {
                    _allCargoProfileIDs pushback (_x select 0);
                };
            } forEach _infantryProfiles;
            {
                if (count _x > 0) then {
                    _allCargoProfileIDs pushback (_x select 0);
                };
            } forEach _armourProfiles;
            {
                if (count _x > 0) then {
                    _allCargoProfileIDs pushback (_x select 0);
                };
            } forEach _motorisedProfiles;

            if (count _allCargoProfileIDs > 0) then {
                private _finalDest = [_event, "finalDestination"] call ALIVE_fnc_hashGet;
                if (count _finalDest > 0) then {
                    [_logic, "spawnStalledUnitWatchdog", [
                        _allCargoProfileIDs,
                        _finalDest,
                        _eventFaction,
                        _side
                    ]] call MAINCLASS;

                    if (_debug) then {
                        ["ML - setEventProfilesAvailable: Stalled unit watchdog started for %1 profiles at destination %2",
                            count _allCargoProfileIDs, _finalDest] call ALiVE_fnc_dump;
                    };
                };
            };
            // -----------------------------------------------------------------


            // dispatch event
            _finalDestination = [_event, "finalDestination"] call ALIVE_fnc_hashGet;
            _logEvent = ['LOGISTICS_COMPLETE', [_finalDestination,_eventFaction,_side,_eventID],"Logistics"] call ALIVE_fnc_event;
            [ALIVE_eventLog, "addEvent",_logEvent] call ALIVE_fnc_eventLog;


        }else{

            // Player requested

            private ["_emptyProfiles","_joinIndividualProfiles","_staticIndividualProfiles","_reinforceIndividualProfiles",
            "_joinGroupProfiles","_staticGroupProfiles","_reinforceGroupProfiles","_payloadGroupProfiles","_player","_logEvent","_finalDestination"];

            _emptyProfiles = [_playerRequestProfiles,"empty"] call ALIVE_fnc_hashGet;
            _joinIndividualProfiles = [_playerRequestProfiles,"joinIndividuals"] call ALIVE_fnc_hashGet;
            _staticIndividualProfiles = [_playerRequestProfiles,"staticIndividuals"] call ALIVE_fnc_hashGet;
            _reinforceIndividualProfiles = [_playerRequestProfiles,"reinforceIndividuals"] call ALIVE_fnc_hashGet;
            _joinGroupProfiles = [_playerRequestProfiles,"joinGroups"] call ALIVE_fnc_hashGet;
            _staticGroupProfiles = [_playerRequestProfiles,"staticGroups"] call ALIVE_fnc_hashGet;
            _reinforceGroupProfiles = [_playerRequestProfiles,"reinforceGroups"] call ALIVE_fnc_hashGet;
            _payloadGroupProfiles = [_playerRequestProfiles,"payloadGroups"] call ALIVE_fnc_hashGet;

            // reinforce profiles get released
            // to OPCOM control

            {
                {
                    _profile = [ALIVE_profileHandler, "getProfile", _x] call ALIVE_fnc_profileHandler;
                    if!(isNil "_profile") then {
                        [_profile,"busy",false] call ALIVE_fnc_hashSet;
                    };
                } forEach _x;

            } forEach _reinforceIndividualProfiles;

            {
                {
                    _profile = [ALIVE_profileHandler, "getProfile", _x] call ALIVE_fnc_profileHandler;
                    if!(isNil "_profile") then {
                        [_profile,"busy",false] call ALIVE_fnc_hashSet;
                    };
                } forEach _x;

            } forEach _reinforceGroupProfiles;


            // find the player object

            if((isServer && isMultiplayer) || isDedicated) then {

                _player = objNull;
                {
                    if (getPlayerUID _x == _playerID) exitWith {
                        _player = _x;
                    };
                } forEach playableUnits;
            }else{

                 _player = player;
            };

            // player found

            if (!(isNull _player)) then {

                private ["_active","_type","_units"];

                // join player profiles, if active
                // join the player group

                {
                    {
                        _profile = [ALIVE_profileHandler, "getProfile", _x] call ALIVE_fnc_profileHandler;
                        if!(isNil "_profile") then {

                            _active = _profile select 2 select 1;
                            _type = _profile select 2 select 5;

                            if(_type == "entity") then {

                                if(_active) then {

                                    _units = _profile select 2 select 21;

                                    _units joinSilent (group _player);

                                    [ALIVE_profileHandler, "unregisterProfile", _profile] call ALIVE_fnc_profileHandler;
                                }else{

                                    [_profile,"busy",false] call ALIVE_fnc_hashSet;

                                };

                            }else{

                                if!(_active) then {

                                    [_profile,"busy",false] call ALIVE_fnc_hashSet;

                                };

                            };

                        };
                    } forEach _x;

                } forEach _joinIndividualProfiles;

                {
                    {
                        _profile = [ALIVE_profileHandler, "getProfile", _x] call ALIVE_fnc_profileHandler;
                        if!(isNil "_profile") then {

                            _active = _profile select 2 select 1;
                            _type = _profile select 2 select 5;

                            if(_type == "entity") then {

                                if(_active) then {

                                    _units = _profile select 2 select 21;

                                    _units joinSilent (group _player);

                                    [ALIVE_profileHandler, "unregisterProfile", _profile] call ALIVE_fnc_profileHandler;
                                }else{

                                    [_profile,"busy",false] call ALIVE_fnc_hashSet;

                                };

                            }else{

                                if!(_active) then {

                                    [_profile,"busy",false] call ALIVE_fnc_hashSet;

                                };

                            };

                        };
                    } forEach _x;

                } forEach _joinGroupProfiles;

                // static defence profiles
                // if active set to garrison
                // nearby structures

                {
                    {
                        _profile = [ALIVE_profileHandler, "getProfile", _x] call ALIVE_fnc_profileHandler;
                        if!(isNil "_profile") then {

                            _active = _profile select 2 select 1;
                            _type = _profile select 2 select 5;

                            if(_type == "entity") then {

                                if(_active) then {
                                    // [_profile, "setActiveCommand", ["ALIVE_fnc_managedGarrison","managed",[200,"false",_eventPosition]]] call ALIVE_fnc_profileEntity;
                                    [_profile, "setActiveCommand", ["ALIVE_fnc_managedGarrison","managed",[200,"false",_eventPosition, (count _staticIndividualProfiles)]]] call ALIVE_fnc_profileEntity;

                                }else{

                                    [_profile,"busy",false] call ALIVE_fnc_hashSet;

                                };

                            }else{

                                if!(_active) then {

                                    [_profile,"busy",false] call ALIVE_fnc_hashSet;

                                };

                            };

                        };
                    } forEach _x;

                } forEach _staticIndividualProfiles;

                {
                    if(count _x < 2) then {

                        _profile = [ALIVE_profileHandler, "getProfile", (_x select 0)] call ALIVE_fnc_profileHandler;
                        if!(isNil "_profile") then {

                            _active = _profile select 2 select 1;
                            _type = _profile select 2 select 5;

                            if(_type == "entity") then {

                                if(_active) then {

                                    // [_profile, "setActiveCommand", ["ALIVE_fnc_managedGarrison","managed",[200,"false",_eventPosition]]] call ALIVE_fnc_profileEntity;
                                    [_profile, "setActiveCommand", ["ALIVE_fnc_managedGarrison","managed",[200,"false",_eventPosition, (count _staticGroupProfiles)]]] call ALIVE_fnc_profileEntity;

                                }else{

                                    [_profile,"busy",false] call ALIVE_fnc_hashSet;

                                };

                            }else{

                                if!(_active) then {

                                    [_profile,"busy",false] call ALIVE_fnc_hashSet;

                                };

                            };

                        };

                    };

                } forEach _staticGroupProfiles;

                // If payload profiles are still carrying their load, wait a while then dump them
                private ["_payloadProfiles","_payloadProfileID","_payloadVehicleID","_payloadProfile","_payloadVehicle","_payloadCount",
                "_reinforcementPosition","_position","_vehicle"];

                _payloadProfiles = [];

                {
                    if(count _x > 1) then {
                        _payloadProfileID = _x select 0;
                        _payloadVehicleID = _x select 1;

                        _payloadProfile = [ALIVE_profileHandler, "getProfile", _payloadProfileID] call ALIVE_fnc_profileHandler;
                        _payloadVehicle = [ALIVE_profileHandler, "getProfile", _payloadVehicleID] call ALIVE_fnc_profileHandler;

                        if(!(isNil "_payloadProfile") && !(isNil "_payloadVehicle")) then {
                            _payloadProfiles pushback [_payloadProfileID, _payloadVehicleID];

                            _vehicle = _payloadVehicle select 2 select 10;

                            [_event, "finalDestination", position _vehicle] call ALIVE_fnc_hashSet;
                        };
                    };

                } forEach _payloadGroupProfiles;

                if(count _payloadProfiles > 0) then {

                    _reinforcementPosition = [_reinforcementPrimaryObjective,"center"] call ALIVE_fnc_hashGet;
                    _position = _reinforcementPosition getPos [1500, (([_event, "finalDestination"] call ALIVE_fnc_hashGet) getDir _reinforcementPosition)];

                    [_payloadGroupProfiles,_position] spawn {

                        private ["_payloadProfiles","_returnPosition","_currentTime","_waitTime","_profileWaypoint","_anyActive","_active",
                        "_profileCount","_vehicle"];

                        _payloadProfiles = _this select 0;
                        _returnPosition = _this select 1;

                        // Check to see if payload profiles are ready to return
                        // Slingloaders can return once done.
                        // If vehicle no longer has cargo it can return

                        private ["_payloadUnloaded"];

                        _payloadUnloaded = true;

                        {
                            private ["_Profile","_vehicleProfile"];

                            _vehicleProfile = [ALIVE_profileHandler, "getProfile", _x select 1] call ALIVE_fnc_profileHandler;

                            if!(isNil "_vehicleProfile") then {

                                private ["_active","_slingLoading","_slingload","_noCargo","_vehicle"];

                                _active = _vehicleProfile select 2 select 1;

                                _slingLoading = [_vehicleProfile,"slingloading",false] call ALiVE_fnc_hashGet;

                                _vehicle = _vehicleProfile select 2 select 10;
                                _noCargo = count (_vehicle getvariable ["ALiVE_SYS_LOGISTICS_CARGO",[]]) == 0;

                                // If payload vehicle is not slingloading and its cargo is empty - its done.
                                TRACE_2("PR UNLOADED", !_slingLoading, _noCargo);

                                if( _active && _noCargo && !_slingloading ) then {
                                    _payloadUnloaded = true;

                                } else {

                                    _payloadUnloaded = false;

                                };

                                // If we've run out of time, dump cargo
                                if (_active && !_noCargo) then {
                                    [MOD(SYS_LOGISTICS),"unloadObjects",[_vehicle,_vehicle]] call ALiVE_fnc_logistics;
                                };

                                // Drop slingload
                                if (_active && _slingloading) then {
                                    private ["_slungID"];
                                    _slungID = ([_vehicleProfile, 'slingload'] call ALIVE_fnc_profileVehicle) select 0;
                                    if (typeName _slungID == 'ARRAY') then {
                                        private ["_slungprofile"];
                                        _slungprofile = [ALIVE_profileHandler,'getProfile',_slungID select 0] call ALIVE_fnc_profileHandler;
                                        [_slungprofile, 'slung', []] call ALIVE_fnc_hashSet;
                                        [_slungProfile,'spawnType',[]] call ALIVE_fnc_profileVehicle;
                                    };
                                    [_vehicleProfile, 'slingload', []] call ALIVE_fnc_profileVehicle;
                                    [_vehicleProfile, 'slingloading', false] call ALIVE_fnc_hashSet;
                                    _vehicle setSlingLoad objNull;
                                    // Delete current unhook waypoint
                                    deleteWaypoint [group _vehicle, (currentWaypoint (group _vehicle))];
                                };

                            };
                        } foreach _payloadProfiles;

                        _waitTime = 12; // 2 minutes = 12 x 10 secs
                        _currentTime = 0;

                        if (!_payloadUnloaded) then {
                            waituntil {
                                sleep 10;
                                _currentTime = _currentTime + 1;
                                (_currentTime > _waitTime)
                            };
                        };

                        _profileWaypoint = [_returnPosition, 100, "MOVE", "NORMAL", 300, [], "LINE"] call ALIVE_fnc_createProfileWaypoint;
                        _profileCount = 0;

                        {
                            private ["_payloadProfile"];
                            _payloadProfile = _x;
                            {
                                private ["_payloadProfileID","_payloadProfile","_isEntity"];
                                _payloadProfileID = _x;

                                _payloadProfile = [ALIVE_profileHandler, "getProfile", _payloadProfileID] call ALIVE_fnc_profileHandler;

                                _isEntity = [_payloadProfile,"type"] call ALiVE_fnc_hashGet != "vehicle";

                                if(!(isNil "_payloadProfile") && _isEntity) then {
                                    [_payloadProfile, "addWaypoint", _profileWaypoint] call ALIVE_fnc_profileEntity;
                                    _profileCount = _profileCount + 1;
                                };
                            } foreach _payloadProfile;

                        } forEach _payloadProfiles;

                        if(_profileCount > 0) then {

                            waituntil {
                                sleep (10);

                                _anyActive = 0;

                                // once transport vehicles are inactive
                                // dispose of the profiles
                                {

                                    if (count _x > 0) then {
                                        private ["_ID","_profile","_pVehicle"];
                                        _ID = _x select 0;
                                        _profile = [ALIVE_profileHandler, "getProfile", _ID] call ALIVE_fnc_profileHandler;

                                        if (count _x > 1) then {
                                            _ID = _x select 1;
                                            _pVehicle = [ALIVE_profileHandler, "getProfile", _ID] call ALIVE_fnc_profileHandler;
                                        };

                                        if(!(isNil "_profile") && !(isNil "_pVehicle")) then {

                                            _vehicle = _pVehicle select 2 select 10;

                                            if([position _vehicle, 1500] call ALiVE_fnc_anyPlayersInRange == 0) then {

                                                [_profile, "destroy"] call ALIVE_fnc_profileEntity;
                                                [_pVehicle, "destroy"] call ALIVE_fnc_profileVehicle;

                                                //[ALIVE_profileHandler, "unregisterProfile", _payloadProfile] call ALIVE_fnc_profileHandler;
                                                //[ALIVE_profileHandler, "unregisterProfile", _payloadVehicle] call ALIVE_fnc_profileHandler;

                                            }else{

                                                _anyActive = _anyActive + 1;

                                            };

                                        };
                                    };

                                } forEach _payloadProfiles;

                                (_anyActive == 0)
                            };

                            //["PAYLOAD RTB COMPLETE!!!!"] call ALIVE_fnc_dump;

                        };

                    };

                    // dispatch event
                    _finalDestination = [_event, "finalDestination"] call ALIVE_fnc_hashGet;
                    _logEvent = ['LOGISTICS_COMPLETE', [_finalDestination,_eventFaction,_side,_eventID],"Logistics"] call ALIVE_fnc_event;
                    [ALIVE_eventLog, "addEvent",_logEvent] call ALIVE_fnc_eventLog;

                    // respond to player request
                    if(_playerRequested) then {
                        _finalDestination = [_event, "finalDestination"] call ALIVE_fnc_hashGet;
                        _logEvent = ['LOGCOM_RESPONSE', [_requestID,_playerID,_finalDestination,true],"Logistics","REQUEST_DELIVERED"] call ALIVE_fnc_event;
                        [ALIVE_eventLog, "addEvent",_logEvent] call ALIVE_fnc_eventLog;
                    };



                }else{

                    // dispatch event
                    _finalDestination = [_event, "finalDestination"] call ALIVE_fnc_hashGet;
                    _logEvent = ['LOGISTICS_COMPLETE', [_finalDestination,_eventFaction,_side,_eventID],"Logistics"] call ALIVE_fnc_event;
                    [ALIVE_eventLog, "addEvent",_logEvent] call ALIVE_fnc_eventLog;

                    // respond to player request
                    if(_playerRequested) then {
                        _finalDestination = [_event, "finalDestination"] call ALIVE_fnc_hashGet;
                        _logEvent = ['LOGCOM_RESPONSE', [_requestID,_playerID,_finalDestination,false],"Logistics","REQUEST_DELIVERED"] call ALIVE_fnc_event;
                        [ALIVE_eventLog, "addEvent",_logEvent] call ALIVE_fnc_eventLog;
                    };

                };

            }else{

                // player not found just set
                // the requested groups as
                // reinforcements

                {
                    {
                        _profile = [ALIVE_profileHandler, "getProfile", _x] call ALIVE_fnc_profileHandler;
                        if!(isNil "_profile") then {
                            [_profile,"busy",false] call ALIVE_fnc_hashSet;
                        };
                    } forEach _x;

                } forEach _reinforceIndividualProfiles;

                {
                    {
                        _profile = [ALIVE_profileHandler, "getProfile", _x] call ALIVE_fnc_profileHandler;
                        if!(isNil "_profile") then {
                            [_profile,"busy",false] call ALIVE_fnc_hashSet;
                        };
                    } forEach _x;

                } forEach _reinforceGroupProfiles;

                {
                    {
                        _profile = [ALIVE_profileHandler, "getProfile", _x] call ALIVE_fnc_profileHandler;
                        if!(isNil "_profile") then {
                            [_profile,"busy",false] call ALIVE_fnc_hashSet;
                        };
                    } forEach _x;

                } forEach _staticIndividualProfiles;

                {
                    {
                        _profile = [ALIVE_profileHandler, "getProfile", _x] call ALIVE_fnc_profileHandler;
                        if!(isNil "_profile") then {
                            [_profile,"busy",false] call ALIVE_fnc_hashSet;
                        };
                    } forEach _x;

                } forEach _staticGroupProfiles;


                // dispatch event
                _finalDestination = [_event, "finalDestination"] call ALIVE_fnc_hashGet;
                _logEvent = ['LOGISTICS_COMPLETE', [_finalDestination,_eventFaction,_side,_eventID],"Logistics"] call ALIVE_fnc_event;
                [ALIVE_eventLog, "addEvent",_logEvent] call ALIVE_fnc_eventLog;

            };

        };
    };

    case "removeEvent": {
        private["_debug","_eventID","_eventQueue"];

        // remove the event from the queue

        _eventID = _args;
        _eventQueue = [_logic, "eventQueue"] call MAINCLASS;

        [_eventQueue,_eventID] call ALIVE_fnc_hashRem;

        [_logic, "eventQueue", _eventQueue] call MAINCLASS;

    };
};

TRACE_1("ML - output",_result);
_result ;
