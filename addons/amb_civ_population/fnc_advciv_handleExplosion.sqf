
params [
    ["_pos", [0,0,0], [[]]],
    ["_source", objNull, [objNull]]
];

if (!isServer) exitWith {};
if (!ALiVE_advciv_enabled) exitWith {};

private _range    = ALiVE_advciv_explosionRange;
private _nearCivs = _pos nearEntities ["CAManBase", _range];

{
    private _civ = _x;

    if (!alive _civ || {side _civ != civilian} || {isPlayer _civ} || {!(_civ getVariable ["ALiVE_advciv_active", false])}) then {
    } else {

        private _dist  = _civ distance _pos;
        private _order = _civ getVariable ["ALiVE_advciv_order", "NONE"];

        private _intensity = linearConversion [0, _range, _dist, 15, 2, true];
        private _cur = _civ getVariable ["ALiVE_advciv_nearShots", 0];
        _civ setVariable ["ALiVE_advciv_nearShots", (_cur + _intensity) min 20];
        _civ setVariable ["ALiVE_advciv_lastShotTime", time];

        if (!isNull _source) then {
            _source setVariable ["ALiVE_advciv_firedAtCiv", true, true];
        };

        if (_order in ["HANDSUP", "GETDOWN", "KNEEL"]) then {
            if (_civ getVariable ["ALiVE_advciv_state", "CALM"] == "HIDING") then {
                _civ setVariable ["ALiVE_advciv_stateTimer", time + ALiVE_advciv_hideTimeMin + random (ALiVE_advciv_hideTimeMax - ALiVE_advciv_hideTimeMin)];
            };
        } else {

            private _state = _civ getVariable ["ALiVE_advciv_state", "CALM"];

            if (_state in ["CALM", "ALERT"]) then {
                if (_dist < _range * 0.7 || {_civ getVariable ["ALiVE_advciv_nearShots", 0] > 3}) then {
                    _civ setVariable ["ALiVE_advciv_state", "PANIC", true];
                    _civ setVariable ["ALiVE_advciv_panicSource", _pos, true];
                    _civ setVariable ["ALiVE_advciv_hidingPos", [], true];
                    _civ setSpeedMode "FULL";
                    if (vehicle _civ == _civ) then { _civ setUnitPos "UP"; };
                    _civ setBehaviour "AWARE";
                    _civ enableAI "PATH";
                    if (vehicle _civ == _civ) then {
                        private _fleeDir = (_pos getDir (getPos _civ)) + (-30 + random 60);
                        _civ doMove ((getPos _civ) getPos [40 + random 40, _fleeDir]);
                    };
                } else {
                    if (_state == "CALM") then {
                        _civ setVariable ["ALiVE_advciv_state", "ALERT", true];
                        _civ setVariable ["ALiVE_advciv_panicSource", _pos, true];
                        _civ setVariable ["ALiVE_advciv_stateTimer", 0];
                        _civ setBehaviour "AWARE";
                        if (vehicle _civ == _civ) then { _civ setUnitPos "UP"; };
                        _civ doWatch _pos;
                    };
                };
            };

            if (_state == "HIDING") then {
                _civ setVariable ["ALiVE_advciv_stateTimer", time + ALiVE_advciv_hideTimeMin + random (ALiVE_advciv_hideTimeMax - ALiVE_advciv_hideTimeMin)];
            };

            if (_state == "ORDERED" && {_order == "FOLLOW"} && {_dist < 50}) then {
                _civ setVariable ["ALiVE_advciv_order", "NONE", true];
                _civ setVariable ["ALiVE_advciv_state", "PANIC", true];
                _civ setVariable ["ALiVE_advciv_panicSource", _pos, true];
                _civ setVariable ["ALiVE_advciv_hidingPos", [], true];
                _civ setSpeedMode "FULL";
                if (vehicle _civ == _civ) then { _civ setUnitPos "UP"; };
                _civ enableAI "PATH";
                if (vehicle _civ == _civ) then {
                    private _fleeDir = (_pos getDir (getPos _civ)) + (-30 + random 60);
                    _civ doMove ((getPos _civ) getPos [40, _fleeDir]);
                };
            };
        };
    };
} forEach _nearCivs;