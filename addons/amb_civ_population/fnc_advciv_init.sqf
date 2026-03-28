#include "\x\alive\addons\amb_civ_population\script_component.hpp"
SCRIPT(advciv_init);

/* ----------------------------------------------------------------------------
Function: ALIVE_fnc_advciv_init
Description:
Main initialization for Advanced Civilians system

Parameters:
None

Returns:
Nothing

Examples:
(begin example)
call ALIVE_fnc_advciv_init;
(end)

See Also:

Author:
Jman
---------------------------------------------------------------------------- */

if (!isServer) exitWith {};

["ALiVE Advanced Civilians - Initializing Realistic Civilians..."] call ALIVE_fnc_dump;

ALiVE_advciv_voiceLines_panic = [
    "ALiVE_advciv_dont_shoot_1",
    "ALiVE_advciv_dont_shoot_2",
    "ALiVE_advciv_no_no",
    "ALiVE_advciv_please_no",
    "ALiVE_advciv_help",
    "ALiVE_advciv_scream_1",
    "ALiVE_advciv_scream_2"
];

ALiVE_advciv_voiceLines_hit = [
    "ALiVE_advciv_dont_shoot_1",
    "ALiVE_advciv_dont_shoot_2",
    "ALiVE_advciv_no_no",
    "ALiVE_advciv_please_no",
    "ALiVE_advciv_scream_1",
    "ALiVE_advciv_scream_2",
    "ALiVE_advciv_crying"
];

ALiVE_advciv_voiceLines_hiding = [
    "ALiVE_advciv_please_no",
    "ALiVE_advciv_go_away",
    "ALiVE_advciv_crying"
];

addMissionEventHandler ["EachFrame", {
    if (diag_frameNo % 30 != 0) exitWith {};
    {
        if (alive _x && {side _x == civilian} && {!isPlayer _x} && {_x getVariable ["ALiVE_advciv_active", false]}) then {
            private _nearShots = _x getVariable ["ALiVE_advciv_nearShots", 0];
            if (_nearShots > 0) then {
                _x setVariable ["ALiVE_advciv_nearShots", (_nearShots - 0.1) max 0];
            };
        };
    } forEach allUnits;
}];

addMissionEventHandler ["EntityKilled", {
    params ["_killed", "_killer", "_instigator"];
    if (side _killed == civilian) then {
        private _attackerUnit = if (!isNull _instigator) then {_instigator} else {_killer};
        if (!isNull _attackerUnit) then {
            _attackerUnit setVariable ["ALiVE_advciv_firedAtCiv", true, true];
        };

        {
            if (alive _x && {side _x == civilian} && {!isPlayer _x} && {_x != _killed}) then {
                _x setVariable ["ALiVE_advciv_state", "PANIC", true];
                _x setVariable ["ALiVE_advciv_panicSource", getPos _killed, true];
                _x setVariable ["ALiVE_advciv_nearShots", 10];
            };
        } forEach (_killed nearEntities ["CAManBase", ALiVE_advciv_reactionRadius]);
    };
}];

{
    if (side _x != civilian) then {
        _x addEventHandler ["FiredMan", {
            params ["_unit"];
            private _pos = getPos _unit;

            private _nearCivs = _pos nearEntities ["CAManBase", 50];
            private _civNear = {alive _x && {side _x == civilian} && {!isPlayer _x}} count _nearCivs;
            if (_civNear > 0) then {
                _unit setVariable ["ALiVE_advciv_firedAtCiv", true, true];
            };

            {
                if (alive _x && {side _x == civilian} && {!isPlayer _x} && {_x getVariable ["ALiVE_advciv_active", false]}) then {
                    private _dist = _x distance _pos;
                    if (_dist < ALiVE_advciv_maxRange) then {
                        private _intensity = linearConversion [0, ALiVE_advciv_maxRange, _dist, 10, 1, true];
                        private _cur = _x getVariable ["ALiVE_advciv_nearShots", 0];
                        _x setVariable ["ALiVE_advciv_nearShots", (_cur + _intensity) min 20];
                        if (_x getVariable ["ALiVE_advciv_state", "CALM"] == "CALM" && {_intensity > 3}) then {
                            if (random 1 < ALiVE_advciv_panicChance) then {
                                _x setVariable ["ALiVE_advciv_state", "ALERT", true];
                                _x setVariable ["ALiVE_advciv_panicSource", _pos, true];
                            };
                        };
                    };
                };
            } forEach allUnits;
        }];
    };
} forEach allUnits;

{
    [_x] call ALiVE_fnc_advciv_brainLoop;
} forEach (allUnits select {side _x == civilian && alive _x && !isPlayer _x});

[] spawn {
    while {ALiVE_advciv_enabled} do {
        {
            if (alive _x && {side _x == civilian} && {!isPlayer _x} && {!(_x getVariable ["ALiVE_advciv_active", false])}) then {
                [_x] call ALiVE_fnc_advciv_brainLoop;
            };
        } forEach allUnits;
        sleep 10;
    };
};

["ALiVE Advanced Civilians - Initialization complete"] call ALIVE_fnc_dump;
