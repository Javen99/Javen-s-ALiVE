
params [
    ["_pos", [0,0,0], [[]]],
    ["_firer", objNull, [objNull]],
    ["_hasSuppressor", false, [false]]
];

if (!isServer) exitWith {};
if (!ALiVE_advciv_enabled) exitWith {};
if (!isNull _firer && {side _firer == civilian}) exitWith {};

private _range    = if (_hasSuppressor) then { ALiVE_advciv_suppressedRange } else { ALiVE_advciv_unsuppressedRange };
private _nearCivs = _pos nearEntities ["CAManBase", _range];

{
    private _civ = _x;

    if (!alive _civ || {side _civ != civilian} || {isPlayer _civ} || {!(_civ getVariable ["ALiVE_advciv_active", false])}) then {
    } else {

        private _dist  = _civ distance _pos;
        private _order = _civ getVariable ["ALiVE_advciv_order", "NONE"];

        private _intensity = linearConversion [0, _range, _dist, 10, 1, true];
        private _cur = _civ getVariable ["ALiVE_advciv_nearShots", 0];
        private _newShots = (_cur + _intensity) min 20;
        _civ setVariable ["ALiVE_advciv_nearShots", _newShots];
        _civ setVariable ["ALiVE_advciv_lastShotTime", time];

        if (_dist < 50 && {!isNull _firer}) then {
            _firer setVariable ["ALiVE_advciv_firedAtCiv", true, true];
        };

        if (_order in ["HANDSUP", "GETDOWN", "KNEEL"]) then {
            if (_civ getVariable ["ALiVE_advciv_state", "CALM"] == "HIDING") then {
                _civ setVariable ["ALiVE_advciv_stateTimer", time + ALiVE_advciv_hideTimeMin + random (ALiVE_advciv_hideTimeMax - ALiVE_advciv_hideTimeMin)];
            };
        } else {

            private _state   = _civ getVariable ["ALiVE_advciv_state", "CALM"];
            private _onFoot  = (vehicle _civ == _civ);

            if (_dist < 30 && {_state in ["CALM","ALERT"]}) then {

                _civ setVariable ["ALiVE_advciv_state", "PANIC", true];
                _civ setVariable ["ALiVE_advciv_panicSource", _pos, true];
                _civ setVariable ["ALiVE_advciv_hidingPos", [], true];
                _civ enableAI "PATH";
                _civ enableAI "MOVE";

                if (_onFoot) then {
                    [_civ, ""] remoteExec ["switchMove", 0];

                    _civ setUnitPos "UP";
                    _civ setBehaviour "AWARE";
                    _civ setSpeedMode "FULL";
                    _civ forceSpeed -1;

                    private _fleeDir = (_pos getDir (getPos _civ)) + (-40 + random 80);
                    private _fleePos = (getPos _civ) getPos [30 + random 40, _fleeDir];
                    _civ doMove _fleePos;
                };

                if (ALiVE_advciv_voiceEnabled && {random 1 < 0.85}) then {
                    private _lastVoice = _civ getVariable ["ALiVE_advciv_lastVoice", 0];
                    if (time - _lastVoice > 2) then {
                        [_civ, selectRandom ALiVE_advciv_voiceLines_panic] remoteExec ["say3D", 0];
                        _civ setVariable ["ALiVE_advciv_lastVoice", time];
                    };
                };

            } else {
            if (_dist < 75 && {_state in ["CALM","ALERT"]}) then {

                _civ setVariable ["ALiVE_advciv_state", "PANIC", true];
                _civ setVariable ["ALiVE_advciv_panicSource", _pos, true];
                _civ setVariable ["ALiVE_advciv_hidingPos", [], true];
                _civ enableAI "PATH";

                if (_onFoot) then {
                    if (_state == "CALM") then {
                        [_civ, ""] remoteExec ["switchMove", 0];
                    };

                    _civ setUnitPos "UP";
                    _civ setBehaviour "AWARE";
                    _civ setSpeedMode "FULL";
                    _civ forceSpeed -1;

                    private _fleeDir = (_pos getDir (getPos _civ)) + (-30 + random 60);
                    _civ doMove ((getPos _civ) getPos [30 + random 30, _fleeDir]);
                };

                if (ALiVE_advciv_voiceEnabled && {random 1 < 0.6}) then {
                    private _lastVoice = _civ getVariable ["ALiVE_advciv_lastVoice", 0];
                    if (time - _lastVoice > 3) then {
                        [_civ, selectRandom ALiVE_advciv_voiceLines_panic] remoteExec ["say3D", 0];
                        _civ setVariable ["ALiVE_advciv_lastVoice", time];
                    };
                };

            } else {
            if (_dist < _range * 0.5 && {_state in ["CALM","ALERT"]}) then {

                _civ setVariable ["ALiVE_advciv_state", "PANIC", true];
                _civ setVariable ["ALiVE_advciv_panicSource", _pos, true];
                _civ setVariable ["ALiVE_advciv_hidingPos", [], true];
                _civ setSpeedMode "FULL";
                if (_onFoot) then { _civ setUnitPos "UP"; };
                _civ setBehaviour "AWARE";
                _civ enableAI "PATH";
                if (_onFoot) then {
                    private _fleeDir = (_pos getDir (getPos _civ)) + (-30 + random 60);
                    _civ doMove ((getPos _civ) getPos [30 + random 30, _fleeDir]);
                };

            } else {

                switch (_state) do {

                    case "CALM": {
                        private _alertRoll = ALiVE_advciv_alertChance + (_newShots * 0.05);
                        if (random 1 < _alertRoll) then {
                            if (_newShots > 4) then {
                                _civ setVariable ["ALiVE_advciv_state", "PANIC", true];
                                _civ setVariable ["ALiVE_advciv_panicSource", _pos, true];
                                _civ setVariable ["ALiVE_advciv_hidingPos", [], true];
                                _civ setSpeedMode "FULL";
                                if (_onFoot) then { _civ setUnitPos "UP"; };
                                _civ setBehaviour "AWARE";
                                _civ enableAI "PATH";
                                if (_onFoot) then {
                                    private _fleeDir = (_pos getDir (getPos _civ)) + (-30 + random 60);
                                    _civ doMove ((getPos _civ) getPos [30 + random 30, _fleeDir]);
                                };
                            } else {
                                _civ setVariable ["ALiVE_advciv_state", "ALERT", true];
                                _civ setVariable ["ALiVE_advciv_panicSource", _pos, true];
                                _civ setVariable ["ALiVE_advciv_stateTimer", 0];
                                _civ setBehaviour "AWARE";
                                if (_onFoot) then { _civ setUnitPos "UP"; };
                                _civ doWatch _pos;
                            };
                        };
                    };

                    case "ALERT": {
                        if (_dist < _range * 0.75 || {_newShots > 3}) then {
                            _civ setVariable ["ALiVE_advciv_state", "PANIC", true];
                            _civ setVariable ["ALiVE_advciv_panicSource", _pos, true];
                            _civ setVariable ["ALiVE_advciv_hidingPos", [], true];
                            _civ setSpeedMode "FULL";
                            if (_onFoot) then { _civ setUnitPos "UP"; };
                            _civ setBehaviour "AWARE";
                            _civ enableAI "PATH";
                            if (_onFoot) then {
                                private _fleeDir = (_pos getDir (getPos _civ)) + (-30 + random 60);
                                _civ doMove ((getPos _civ) getPos [30 + random 30, _fleeDir]);
                            };
                        };
                    };

                    case "HIDING": {
                        _civ setVariable ["ALiVE_advciv_stateTimer", time + ALiVE_advciv_hideTimeMin + random (ALiVE_advciv_hideTimeMax - ALiVE_advciv_hideTimeMin)];
                    };

                    case "ORDERED": {
                        if (_order == "FOLLOW" && {_dist < 30}) then {
                            _civ setVariable ["ALiVE_advciv_order", "NONE", true];
                            _civ setVariable ["ALiVE_advciv_state", "PANIC", true];
                            _civ setVariable ["ALiVE_advciv_panicSource", _pos, true];
                            _civ setVariable ["ALiVE_advciv_hidingPos", [], true];
                            _civ setSpeedMode "FULL";
                            if (_onFoot) then { _civ setUnitPos "UP"; };
                            _civ enableAI "PATH";
                            if (_onFoot) then {
                                private _fleeDir = (_pos getDir (getPos _civ)) + (-30 + random 60);
                                _civ doMove ((getPos _civ) getPos [40, _fleeDir]);
                            };
                        };
                    };
                };

            }; }; };
        };
    };
} forEach _nearCivs;