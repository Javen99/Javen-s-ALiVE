// ----------------------------------------------------------------------------
#include "\x\alive\addons\mil_opcom\script_component.hpp"
SCRIPT(test_OPCOM);
// ----------------------------------------------------------------------------

if !(isnil QGVAR(TEST_OPCOM)) exitwith {};

GVAR(TEST_OPCOM) = true;

#define MAINCLASS ALiVE_fnc_OPCOM

// ----------------------------------------------------------------------------

private ["_result","_err","_logic","_state","_result2"];

#define STAT(msg) sleep 3; \
diag_log ["TEST("+str player+": "+msg]; \
titleText [msg,"PLAIN"]

#define STAT1(msg) CONT = false; \
waitUntil{CONT}; \
diag_log ["TEST("+str player+": "+msg]; \
titleText [msg,"PLAIN"]

#define TIMERSTART \
_timeStart = diag_tickTime; \
diag_log "Timer Start";

#define TIMEREND \
_timeEnd = diag_tickTime - _timeStart; \
["Timer End %1",_timeEnd] call ALiVE_fnc_dump;

//========================================

LOG("Testing OPCOM");

TIMERSTART

STAT("Testing task profile override parsing");

private _overrideHandler = [] call ALIVE_fnc_hashCreate;
private _countOverrides = [objNull, "parseTaskProfileCountOverrides", "[[""attack"",6],[""defend"",3],[""terrorize"",2],[""ambush"",1],[""reserve"",0]]"] call MAINCLASS;
private _typeOverrides = [objNull, "parseTaskProfileTypeOverrides", "[[""attack"",[""mechanized"",""ARMORED""]],[""ambush"",[""infantry""]],[""terrorize"",[""motorized""]],[""reserve"",[]]]"] call MAINCLASS;
private _malformedOverrideHandler = [] call ALIVE_fnc_hashCreate;
private _malformedCountOverrides = [objNull, "parseTaskProfileCountOverrides", "[[123,2],[""attack"",5]]"] call MAINCLASS;
private _malformedTypeOverrides = [objNull, "parseTaskProfileTypeOverrides", "[[123,[""air""]],[""attack"",[""mechanized""]]]"] call MAINCLASS;
private _syntaxErrorOverrideHandler = [] call ALIVE_fnc_hashCreate;
private _syntaxErrorCountOverrides = [objNull, "parseTaskProfileCountOverrides", "[[""attack"",6]"] call MAINCLASS;
private _syntaxErrorTypeOverrides = [objNull, "parseTaskProfileTypeOverrides", "[[""attack"",[""mechanized""]]" ] call MAINCLASS;
private _invalidTokenOverrideHandler = [] call ALIVE_fnc_hashCreate;
private _invalidTokenTypeOverrides = [objNull, "parseTaskProfileTypeOverrides", "[[""attack"",[""mechnized""]],[""reserve"",[]]]"] call MAINCLASS;

[_overrideHandler, "taskProfileCountOverrides", _countOverrides] call ALIVE_fnc_hashSet;
[_overrideHandler, "taskProfileTypeOverrides", _typeOverrides] call ALIVE_fnc_hashSet;
[_malformedOverrideHandler, "taskProfileCountOverrides", _malformedCountOverrides] call ALIVE_fnc_hashSet;
[_malformedOverrideHandler, "taskProfileTypeOverrides", _malformedTypeOverrides] call ALIVE_fnc_hashSet;
[_syntaxErrorOverrideHandler, "taskProfileCountOverrides", _syntaxErrorCountOverrides] call ALIVE_fnc_hashSet;
[_syntaxErrorOverrideHandler, "taskProfileTypeOverrides", _syntaxErrorTypeOverrides] call ALIVE_fnc_hashSet;
[_invalidTokenOverrideHandler, "taskProfileTypeOverrides", _invalidTokenTypeOverrides] call ALIVE_fnc_hashSet;

_err = "Attack count override parse failed";
ASSERT_TRUE(([_overrideHandler, "getTaskProfileCount", ["attack", 4]] call MAINCLASS) == 6, _err);

_err = "Terrorize fallback count override failed";
ASSERT_TRUE(([_overrideHandler, "getTaskProfileCount", ["factory", 1, "terrorize"]] call MAINCLASS) == 2, _err);

_err = "Zero reserve override should be preserved";
ASSERT_TRUE(([_overrideHandler, "getTaskProfileCount", ["reserve", 3]] call MAINCLASS) == 0, _err);

_err = "Attack type override parse failed";
ASSERT_TRUE(([_overrideHandler, "getTaskProfileTypes", ["attack", ["infantry"]]] call MAINCLASS) isEqualTo ["mechanized", "armored"], _err);

_err = "Terrorize fallback type override failed";
ASSERT_TRUE(([_overrideHandler, "getTaskProfileTypes", ["suicide", ["infantry"], "terrorize"]] call MAINCLASS) isEqualTo ["motorized"], _err);

_err = "Empty reserve type override should be preserved";
ASSERT_TRUE(([_overrideHandler, "getTaskProfileTypes", ["reserve", ["infantry"]]] call MAINCLASS) isEqualTo [], _err);

_err = "Malformed count override entries should be ignored safely";
ASSERT_TRUE(([_malformedOverrideHandler, "getTaskProfileCount", ["attack", 4]] call MAINCLASS) == 5, _err);

_err = "Malformed type override entries should be ignored safely";
ASSERT_TRUE(([_malformedOverrideHandler, "getTaskProfileTypes", ["attack", ["infantry"]]] call MAINCLASS) isEqualTo ["mechanized"], _err);

_err = "Syntax errors in count overrides should fall back safely";
ASSERT_TRUE(([_syntaxErrorOverrideHandler, "getTaskProfileCount", ["attack", 4]] call MAINCLASS) == 4, _err);

_err = "Syntax errors in type overrides should fall back safely";
ASSERT_TRUE(([_syntaxErrorOverrideHandler, "getTaskProfileTypes", ["attack", ["infantry"]]] call MAINCLASS) isEqualTo ["infantry"], _err);

_err = "Invalid type tokens should not create empty overrides";
ASSERT_TRUE(([_invalidTokenOverrideHandler, "getTaskProfileTypes", ["attack", ["infantry"]]] call MAINCLASS) isEqualTo ["infantry"], _err);

_err = "Explicit empty type overrides should still be preserved";
ASSERT_TRUE(([_invalidTokenOverrideHandler, "getTaskProfileTypes", ["reserve", ["infantry"]]] call MAINCLASS) isEqualTo [], _err);

STAT("Testing asymmetric installation override parsing");

private _installationOverrides = [objNull, "parseAsymmetricInstallationCountOverrides", "[[""HQ"",2],[""depot"",0],[""roadblock"",1],[""factory"",3]]"] call MAINCLASS;
private _aliasInstallationOverrides = [objNull, "parseAsymmetricInstallationCountOverrides", "[[""recruit"",1],[""ied_factory"",2]]"] call MAINCLASS;
private _malformedInstallationOverrides = [objNull, "parseAsymmetricInstallationCountOverrides", "[[123,2],[""factory"",1]]"] call MAINCLASS;
private _syntaxErrorInstallationOverrides = [objNull, "parseAsymmetricInstallationCountOverrides", "[[""factory"",2]"] call MAINCLASS;

_err = "HQ installation override parse failed";
ASSERT_TRUE(([_installationOverrides, "HQ", -1] call ALIVE_fnc_hashGet) == 2, _err);

_err = "Roadblock alias should normalize to roadblocks";
ASSERT_TRUE(([_installationOverrides, "roadblocks", -1] call ALIVE_fnc_hashGet) == 1, _err);

_err = "Zero depot override should be preserved";
ASSERT_TRUE(([_installationOverrides, "depot", -1] call ALIVE_fnc_hashGet) == 0, _err);

_err = "Recruit alias should normalize to HQ";
ASSERT_TRUE(([_aliasInstallationOverrides, "HQ", -1] call ALIVE_fnc_hashGet) == 1, _err);

_err = "IED factory alias should normalize to factory";
ASSERT_TRUE(([_aliasInstallationOverrides, "factory", -1] call ALIVE_fnc_hashGet) == 2, _err);

_err = "Malformed installation override entries should be ignored safely";
ASSERT_TRUE(([_malformedInstallationOverrides, "factory", -1] call ALIVE_fnc_hashGet) == 1, _err);

_err = "Syntax errors in installation overrides should fall back safely";
ASSERT_TRUE(count (_syntaxErrorInstallationOverrides select 1) == 0, _err);

_err = "Unknown installation types should normalize to an empty string";
ASSERT_TRUE(([objNull, "normalizeAsymmetricInstallationType", "unknown"] call MAINCLASS) == "", _err);

STAT("Creating Virtual AI System...");

//Profile System
private ["_logic"];
_logic = (createGroup sideLogic) createUnit ["ALiVE_sys_profile", [0,0], [], 0, "NONE"];
_logic setVariable ["debug","true"];
_logic setVariable ["spawnRadius","1500"];
_profiles = _logic;
waituntil {!isnil "ALIVE_profileSystem"};


STAT("Creating Military Placement instance");

//Military Placement
private ["_logic"];
_logic = (createGroup sideLogic) createUnit ["ALiVE_mil_placement", [2000,2000], [], 0, "NONE"];
_logic setVariable ["faction","BLU_F"];
_logic setVariable ["debug","true"];
_MP = _logic;
waituntil {_logic getVariable ["startupComplete", false]};

STAT("Creating Military AI Commander instance");

//OPCOM
private ["_logic"];
_logic = [nil,"create"] call MAINCLASS;
_logic setvariable ["faction1","BLU_F"];
_logic setvariable ["debug","true"];
_logic synchronizeObjectsAdd [_MP];

_cond = typeof _logic == QUOTE(ADDON);
_err = "Creation of OPCOM failed";
if !(_cond) then {STAT(_err)};
ASSERT_TRUE(_cond, _err);

sleep 2;

STAT("Destroying Military AI Commander instance");
_instances = count OPCOM_instances;
_result = [_logic, "destroy"] call MAINCLASS;
_err = "Destruction of Military AI Commander failed";
if !(_instances - (count OPCOM_instances) == 1) then {STAT(_err)};
ASSERT_TRUE(_instances - (count OPCOM_instances) == 1, _err);

STAT("Waiting for FSM to end");
sleep 20;

STAT("Cleaning up MP");
_result = [_MP, "destroy"] call ALiVE_fnc_MP;
_err = "Destruction of Military Placement instance failed";
if !(isnull _MP) then {STAT(_err)};
ASSERT_TRUE(isnull _MP, _err);

sleep 2;

STAT("Destroying Virtual AI System");
_result = [ALIVE_profileSystem, "destroy"] call ALIVE_fnc_profileSystem;
_err = "Destruction of Virtual AI System failed";
if (count (ALiVE_ProfileSystem select 1) > 0) then {STAT(_err)};
ASSERT_TRUE(count (ALiVE_ProfileSystem select 1) == 0, _err);

TIMEREND

GVAR(TEST_OPCOM) = nil;