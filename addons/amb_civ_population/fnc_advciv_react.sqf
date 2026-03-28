params [["_unit", objNull, [objNull]], ["_type", "GUNFIRE", [""]], ["_extraParam", nil]];

if (isNull _unit || {!alive _unit}) exitWith {};
if (isPlayer _unit) exitWith {};
if (vehicle _unit != _unit && {_type == "HIT"}) exitWith {};

private _inVehicle = (vehicle _unit != _unit);

private _fnc_shout = {
    params ["_unit", "_lines"];
    if (!ALiVE_advciv_voiceEnabled) exitWith {};
    if (random 1 > ALiVE_advciv_voiceChance) exitWith {};
    private _lastVoice = _unit getVariable ["ALiVE_advciv_lastVoice", 0];
    if (time - _lastVoice < 5) exitWith {};
    [_unit, selectRandom _lines] remoteExec ["say3D", 0];
    _unit setVariable ["ALiVE_advciv_lastVoice", time];
};

switch (_type) do {

    case "GUNFIRE": {
        // Only log state transitions, not every shot
        if (ALiVE_advciv_debug) then {
            private _currentState = _unit getVariable ["ALiVE_advciv_state", "CALM"];
            if (_currentState in ["CALM", "ALERT"]) then {
                systemChat format ["[AdvCiv] %1 → PANIC", name _unit];
            };
        };
        
        [_unit, ALiVE_advciv_voiceLines_panic] call _fnc_shout;

        if (!_inVehicle) then {
            _unit setUnitPos "UP";
            _unit setSpeedMode "FULL";
        };

        if (ALiVE_advciv_cascadeRadius > 0) then {
            private _mySource = _unit getVariable ["ALiVE_advciv_panicSource", [0,0,0]];
            if !(_mySource isEqualTo [0,0,0]) then {
                {
                    if (alive _x
                        && {side _x == civilian}
                        && {!isPlayer _x}
                        && {_x != _unit}
                        && {_x getVariable ["ALiVE_advciv_state", "CALM"] == "CALM"}
                        && {random 1 < ALiVE_advciv_cascadeChance}
                        && {(time - (_x getVariable ["ALiVE_advciv_lastCascadeTime", 0])) > 10}
                    ) then {
                        _x setVariable ["ALiVE_advciv_state", "ALERT", true];
                        _x setVariable ["ALiVE_advciv_stateTimer", 0];
                        _x setVariable ["ALiVE_advciv_panicSource", _mySource, true];
                        _x setVariable ["ALiVE_advciv_lastCascadeTime", time];
                    };
                } forEach (_unit nearEntities ["CAManBase", ALiVE_advciv_cascadeRadius]);
            };
        };
    };

    case "HIT": {
        if (ALiVE_advciv_debug) then {
            systemChat format ["[AdvCiv] %1 → HIT reaction", name _unit];
        };
        
        [_unit, ALiVE_advciv_voiceLines_hit] call _fnc_shout;

        private _roll       = random 1;
        private _cumHandsUp = ALiVE_advciv_handsUpChance;
        private _cumDrop    = _cumHandsUp + ALiVE_advciv_dropChance;
        private _cumFreeze  = _cumDrop + ALiVE_advciv_freezeChance;
        private _cumScream  = _cumFreeze + ALiVE_advciv_screamChance;

        private _reaction = "CRAWL";
        if (_roll < _cumHandsUp)       then { _reaction = "STOP_STAND"; }
        else { if (_roll < _cumDrop)    then { _reaction = "DROP"; }
        else { if (_roll < _cumFreeze)  then { _reaction = "FREEZE"; }
        else { if (_roll < _cumScream)  then { _reaction = "SCREAM"; }; }; }; };

        switch (_reaction) do {

            case "STOP_STAND": {
                doStop _unit;
                _unit setSpeedMode "LIMITED";
                _unit setUnitPos "UP";
                [{
                    params ["_u"];
                    if (alive _u) then {
                        _u setVariable ["ALiVE_advciv_state", "PANIC", true];
                        _u setVariable ["ALiVE_advciv_hitReacting", false, true];
                        _u setVariable ["ALiVE_advciv_hidingPos", [], true];
                    };
                }, [_unit], 3 + random 3] call CBA_fnc_waitAndExecute;
            };

            case "DROP": {
                doStop _unit;
                _unit setUnitPos "DOWN";
                _unit setSpeedMode "LIMITED";
                [{
                    params ["_u"];
                    if (alive _u) then {
                        _u setUnitPos "UP";
                        _u setVariable ["ALiVE_advciv_state", "PANIC", true];
                        _u setVariable ["ALiVE_advciv_hitReacting", false, true];
                        _u setVariable ["ALiVE_advciv_hidingPos", [], true];
                    };
                }, [_unit], 4 + random 5] call CBA_fnc_waitAndExecute;
            };

            case "FREEZE": {
                doStop _unit;
                _unit setUnitPos "MIDDLE";
                _unit setSpeedMode "LIMITED";
                [{
                    params ["_u"];
                    if (alive _u) then {
                        _u setVariable ["ALiVE_advciv_state", "PANIC", true];
                        _u setVariable ["ALiVE_advciv_hitReacting", false, true];
                        _u setVariable ["ALiVE_advciv_hidingPos", [], true];
                    };
                }, [_unit], 3 + random 4] call CBA_fnc_waitAndExecute;
            };

            case "SCREAM": {
                [_unit, selectRandom ALiVE_advciv_voiceLines_panic] remoteExec ["say3D", 0];
                _unit setSpeedMode "FULL";
                private _source = _unit getVariable ["ALiVE_advciv_panicSource", [0,0,0]];
                if !(_source isEqualTo [0,0,0]) then {
                    _unit doMove (_unit getPos [30 + random 20, _source getDir (getPos _unit) + 180]);
                };
                [{
                    params ["_u"];
                    if (alive _u) then {
                        _u setVariable ["ALiVE_advciv_state", "PANIC", true];
                        _u setVariable ["ALiVE_advciv_hitReacting", false, true];
                        _u setVariable ["ALiVE_advciv_hidingPos", [], true];
                    };
                }, [_unit], 2 + random 2] call CBA_fnc_waitAndExecute;
            };

            case "CRAWL": {
                _unit setUnitPos "DOWN";
                _unit enableAI "PATH";
                _unit setSpeedMode "FULL";
                private _source = _unit getVariable ["ALiVE_advciv_panicSource", [0,0,0]];
                if !(_source isEqualTo [0,0,0]) then {
                    _unit doMove (_unit getPos [15 + random 10, _source getDir (getPos _unit)]);
                };
                [{
                    params ["_u"];
                    if (alive _u) then {
                        _u setUnitPos "UP";
                        _u setVariable ["ALiVE_advciv_state", "PANIC", true];
                        _u setVariable ["ALiVE_advciv_hitReacting", false, true];
                        _u setVariable ["ALiVE_advciv_hidingPos", [], true];
                    };
                }, [_unit], 5 + random 5] call CBA_fnc_waitAndExecute;
            };
        };

        {
            if (alive _x && {side _x == civilian} && {!isPlayer _x} && {_x != _unit}) then {
                private _civState = _x getVariable ["ALiVE_advciv_state", "CALM"];
                if (_civState in ["CALM", "ALERT"]) then {
                    if (_x distance _unit < 15) then {
                        _x setVariable ["ALiVE_advciv_state", "PANIC", true];
                        _x setVariable ["ALiVE_advciv_panicSource", getPos _unit, true];
                        _x setVariable ["ALiVE_advciv_hidingPos", [], true];
                        _x setVariable ["ALiVE_advciv_lastShotTime", time];
                    } else {
                        _x setVariable ["ALiVE_advciv_state", "ALERT", true];
                        _x setVariable ["ALiVE_advciv_panicSource", getPos _unit, true];
                        _x setVariable ["ALiVE_advciv_stateTimer", 0];
                    };
                };
            };
        } forEach (_unit nearEntities ["CAManBase", ALiVE_advciv_reactionRadius * 0.33]);
    };

    case "HIDING": {
        if (ALiVE_advciv_debug) then {
            systemChat format ["[AdvCiv] %1 → HIDING", name _unit];
        };
        
        if (!_inVehicle) then {
            _unit setUnitPos (selectRandom ["DOWN","DOWN","MIDDLE"]);
        };
        private _source = _unit getVariable ["ALiVE_advciv_panicSource", [0,0,0]];
        if !(_source isEqualTo [0,0,0]) then { _unit doWatch _source; };

        private _lastVoice = _unit getVariable ["ALiVE_advciv_lastVoice", 0];
        if (ALiVE_advciv_voiceEnabled && {time - _lastVoice > 20} && {random 1 < 0.15}) then {
            [_unit, ALiVE_advciv_voiceLines_hiding] call _fnc_shout;
        };
    };

    // ========================================================
    // PLAYER ORDER COMMANDS
    // ========================================================
    
    case "FOLLOW": {
        if (ALiVE_advciv_debug) then {
            systemChat format ["[AdvCiv] %1 ordered: FOLLOW", name _unit];
        };
        
        // SMART HYBRID: Convert agent to unit only when needed
        if (isNull (group _unit)) then {
            // This is an agent (null group) - upgrade to real unit
            if (ALiVE_advciv_debug) then {
                systemChat format ["[AdvCiv] Converting agent %1 to unit for group membership", name _unit];
            };
            
            private _pos = getPosATL _unit;
            private _dir = direction _unit;
            private _class = typeOf _unit;
            private _name = name _unit;
            
            // Store all AdvCiv variables to transfer
            private _advCivActive = _unit getVariable ["ALiVE_advciv_active", false];
            private _advCivState = _unit getVariable ["ALiVE_advciv_state", "CALM"];
            private _nearShots = _unit getVariable ["ALiVE_advciv_nearShots", 0];
            private _panicLevel = _unit getVariable ["ALiVE_advciv_panicLevel", 0];
            
            // Create new unit with group
            private _grp = createGroup [civilian, true];
            private _newUnit = _grp createUnit [_class, _pos, [], 0, "NONE"];
            _newUnit setDir _dir;
            _newUnit setPosATL _pos;
            
            // Copy settings from agent
            _newUnit disableAI "FSM";
            _newUnit setBehaviour "CARELESS";
            _newUnit setSpeedMode "LIMITED";
            
            // Transfer AdvCiv variables
            _newUnit setVariable ["ALiVE_advciv_active", _advCivActive, true];
            _newUnit setVariable ["ALiVE_advciv_state", "ORDERED", true];
            _newUnit setVariable ["ALiVE_advciv_order", "FOLLOW", true];
            _newUnit setVariable ["ALiVE_advciv_orderTarget", player, true];
            _newUnit setVariable ["ALiVE_advciv_nearShots", 0, true];
            _newUnit setVariable ["ALiVE_advciv_hidingPos", [], true];
            _newUnit setVariable ["ALiVE_advciv_panicLevel", _panicLevel];
            
            // Update active units array
            private _idx = ALiVE_advciv_activeUnits find _unit;
            if (_idx >= 0) then {
                ALiVE_advciv_activeUnits set [_idx, _newUnit];
            };
            
            // Delete the old agent
            deleteVehicle _unit;
            
            // Join player's group with new unit
            [_newUnit] joinSilent (group player);
            _newUnit setUnitPos "AUTO";
            _newUnit enableAI "MOVE";
            _newUnit enableAI "PATH";
            _newUnit setSpeedMode "NORMAL";
            
            // Re-add order menu to new unit
            [_newUnit] call ALiVE_fnc_advciv_orderMenu;
            
            if (ALiVE_advciv_debug) then {
                systemChat format ["[AdvCiv] Conversion complete: %1 now following in group %2", name _newUnit, group _newUnit];
            };
            
        } else {
            // Already a unit with group, just join normally
            _unit setVariable ["ALiVE_advciv_state", "ORDERED", true];
            _unit setVariable ["ALiVE_advciv_order", "FOLLOW", true];
            _unit setVariable ["ALiVE_advciv_orderTarget", player, true];
            _unit setVariable ["ALiVE_advciv_nearShots", 0, true];
            _unit setVariable ["ALiVE_advciv_hidingPos", [], true];
            
            [_unit] joinSilent (group player);
            _unit setUnitPos "AUTO";
            _unit enableAI "MOVE";
            _unit enableAI "PATH";
            _unit setSpeedMode "NORMAL";
        };
    };

    case "STAY": {
        if (ALiVE_advciv_debug) then {
            systemChat format ["[AdvCiv] %1 ordered: STAY", name _unit];
        };
        
        _unit setVariable ["ALiVE_advciv_state", "ORDERED", true];
        _unit setVariable ["ALiVE_advciv_order", "STAY", true];
        _unit setVariable ["ALiVE_advciv_nearShots", 0, true];
        _unit setVariable ["ALiVE_advciv_hidingPos", [], true];
        
        doStop _unit;
        _unit disableAI "MOVE";
        _unit setUnitPos "AUTO";
    };

    case "GOHOME": {
        if (ALiVE_advciv_debug) then {
            systemChat format ["[AdvCiv] %1 ordered: GO HOME", name _unit];
        };
        
        _unit setVariable ["ALiVE_advciv_state", "ORDERED", true];  // Use ORDERED state so brainTick handles it
        _unit setVariable ["ALiVE_advciv_order", "GOHOME", true];
        _unit setVariable ["ALiVE_advciv_nearShots", 0, true];
        _unit setVariable ["ALiVE_advciv_hidingPos", [], true];
        
        // Leave player's group if in it
        if (group _unit == group player) then {
            [_unit] joinSilent (createGroup civilian);
        };
        
        _unit enableAI "MOVE";
        _unit enableAI "PATH";
        _unit setUnitPos "AUTO";
        _unit setSpeedMode "LIMITED";
        
        // brainTick will handle the actual movement home
    };

    case "HANDSUP": {
        if (ALiVE_advciv_debug) then {
            systemChat format ["[AdvCiv] %1 ordered: HANDS UP", name _unit];
        };
        
        _unit setVariable ["ALiVE_advciv_state", "ORDERED", true];
        _unit setVariable ["ALiVE_advciv_order", "HANDSUP", true];
        
        doStop _unit;
        _unit disableAI "MOVE";
        _unit setUnitPos "UP";
        _unit playMove "AmovPercMstpSnonWnonDnon_AmovPercMstpSsurWnonDnon";
    };

    case "GETDOWN": {
        if (ALiVE_advciv_debug) then {
            systemChat format ["[AdvCiv] %1 ordered: GET DOWN", name _unit];
        };
        
        _unit setVariable ["ALiVE_advciv_state", "ORDERED", true];
        _unit setVariable ["ALiVE_advciv_order", "GETDOWN", true];
        
        doStop _unit;
        _unit disableAI "MOVE";
        _unit setUnitPos "DOWN";
    };

    case "KNEEL": {
        if (ALiVE_advciv_debug) then {
            systemChat format ["[AdvCiv] %1 ordered: KNEEL", name _unit];
        };
        
        _unit setVariable ["ALiVE_advciv_state", "ORDERED", true];
        _unit setVariable ["ALiVE_advciv_order", "KNEEL", true];
        
        doStop _unit;
        _unit disableAI "MOVE";
        _unit setUnitPos "MIDDLE";
    };

    case "CALM": {
        if (ALiVE_advciv_debug) then {
            systemChat format ["[AdvCiv] %1 ordered: CALM DOWN", name _unit];
        };
        
        // Reset to calm state
        _unit setVariable ["ALiVE_advciv_state", "CALM", true];
        _unit setVariable ["ALiVE_advciv_order", "NONE", true];
        _unit setVariable ["ALiVE_advciv_nearShots", 0, true];
        _unit setVariable ["ALiVE_advciv_hidingPos", [], true];
        _unit setVariable ["ALiVE_advciv_panicSource", [0,0,0], true];
        
        _unit enableAI "MOVE";
        _unit enableAI "PATH";
        _unit setUnitPos "AUTO";
        _unit setSpeedMode "LIMITED";
        
        doStop _unit;
    };

    case "GETIN": {
        // _extraParam should be the vehicle object
        if (!isNil "_extraParam" && {_extraParam isEqualType objNull} && {!isNull _extraParam}) then {
            private _vehicle = _extraParam;
            
            if (ALiVE_advciv_debug) then {
                systemChat format ["[AdvCiv] %1 ordered: GET IN vehicle", name _unit];
            };
            
            _unit setVariable ["ALiVE_advciv_state", "ORDERED", true];
            _unit setVariable ["ALiVE_advciv_order", "GETIN", true];
            _unit setVariable ["ALiVE_advciv_orderVehicle", _vehicle, true];  // CRITICAL: set the vehicle
            
            _unit enableAI "MOVE";
            _unit enableAI "PATH";
            _unit assignAsCargo _vehicle;
            [_unit] orderGetIn true;
        };
    };
};
