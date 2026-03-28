// ============================================================
//  ALiVE_fnc_advciv_saveStateToProfile.sqf
// ============================================================
params [["_unit", objNull]];

if (isNull _unit) exitWith {[]};

[
    ["ALiVE_advciv_state", _unit getVariable ["ALiVE_advciv_state", "CALM"]],
    ["ALiVE_advciv_homePos", _unit getVariable ["ALiVE_advciv_homePos", getPos _unit]],
    ["ALiVE_advciv_hidingPos", _unit getVariable ["ALiVE_advciv_hidingPos", []]],
    ["ALiVE_advciv_nearShots", _unit getVariable ["ALiVE_advciv_nearShots", 0]],
    ["ALiVE_advciv_lastShotTime", _unit getVariable ["ALiVE_advciv_lastShotTime", 0]]
]