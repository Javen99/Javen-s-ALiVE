#include "\x\alive\addons\amb_civ_population\script_component.hpp"
SCRIPT(advciv_brainLoop);

/* ----------------------------------------------------------------------------
Function: ALIVE_fnc_advciv_brainLoop
Description:
Registers a civilian unit for AdvCiv brain processing

Parameters:
Object - The civilian unit

Returns:
Nothing

Examples:
(begin example)
[_unit] call ALIVE_fnc_advciv_brainLoop;
(end)

See Also:

Author:
Jman
---------------------------------------------------------------------------- */

params [["_unit", objNull, [objNull]]];

if (!isServer) exitWith {};
if (isNull _unit || {!alive _unit}) exitWith {};
if (isPlayer _unit) exitWith {};
if ([_unit] call ALiVE_fnc_advciv_isMissionCritical) exitWith {};
if (_unit in ALiVE_advciv_activeUnits) exitWith {};

ALiVE_advciv_activeUnits pushBack _unit;

if (ALiVE_advciv_debug) then {
    ["ALiVE Advanced Civilians - Registered unit: %1 | Total active: %2", _unit, count ALiVE_advciv_activeUnits] call ALIVE_fnc_dump;
};
