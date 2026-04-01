#include "\x\alive\addons\civ_placement_custom\script_component.hpp"
SCRIPT(CPCInit);
/* ----------------------------------------------------------------------------
Function: ALIVE_fnc_CPCInit
Description:
Creates the server side object to store settings

Author:
OpenAI
---------------------------------------------------------------------------- */

params ["_logic"];

ASSERT_DEFINED("ALIVE_fnc_CPC", "Main function missing");

private _moduleID = [_logic, true] call ALIVE_fnc_dumpModuleInit;

[_logic, "init"] call ALIVE_fnc_CPC;

[_logic, false, _moduleID] call ALIVE_fnc_dumpModuleInit;


