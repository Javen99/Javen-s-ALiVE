#include "\x\alive\addons\mil_C2ISTAR\script_component.hpp"
SCRIPT(taskSelectFromCommanderAssessment);

/* ----------------------------------------------------------------------------
Function: ALIVE_fnc_taskSelectFromCommanderAssessment

Description:
Select a task type from the configured auto generated list based on the current
OPCOM objective assessment for the requesting faction.

Parameters:
String - side
String - faction
String - enemy faction
Array - side players datasource [uids, playerObjects]
Array - available task pool

Returns:
String - selected task type

Author:
ALiVE Team
---------------------------------------------------------------------------- */

params [
    ["_taskSide", "", [""]],
    ["_taskFaction", "", [""]],
    ["_taskEnemyFaction", "", [""]],
    ["_sidePlayers", [[], []], [[]]],
    ["_taskPool", [], [[]]]
];

private _fallbackTask = if (count _taskPool > 0) then {
    selectRandom _taskPool
} else {
    "DestroyInfantry"
};

private _opcom = objNull;
{
    if ({_x == _taskFaction} count ([_x, "factions", []] call ALiVE_fnc_HashGet) > 0) exitWith {
        _opcom = _x;
    };
} forEach OPCOM_instances;

if (isNull _opcom) exitWith {
    _fallbackTask
};

private _referencePosition = [];
private _playerUids = _sidePlayers param [0, []];

if (count _playerUids > 0) then {
    private _referencePlayer = [_playerUids select 0] call ALIVE_fnc_getPlayerByUID;
    if !(isNull _referencePlayer) then {
        _referencePosition = position _referencePlayer;
    };
};

if (count _referencePosition == 0) then {
    _referencePosition = [_opcom, "position", []] call ALiVE_fnc_HashGet;
};

private _attackingObjectives = [_opcom, "nearestObjectives", [_referencePosition, "attacking"]] call ALiVE_fnc_OPCOM;
private _defendingObjectives = [_opcom, "nearestObjectives", [_referencePosition, "defending"]] call ALiVE_fnc_OPCOM;

private _weightedTaskCandidates = [];

private _appendWeightedTasks = {
    params ["_tasks", "_weight"];

    {
        private _taskType = _x;
        if (_taskType in _taskPool) then {
            for "_i" from 1 to _weight do {
                _weightedTaskCandidates pushBack _taskType;
            };
        };
    } forEach _tasks;
};

private _attackMil = {_x isEqualType [] && {([_x, "objectiveType", "MIL"] call ALiVE_fnc_HashGet) == "MIL"}} count _attackingObjectives;
private _attackCiv = {_x isEqualType [] && {([_x, "objectiveType", "MIL"] call ALiVE_fnc_HashGet) == "CIV"}} count _attackingObjectives;
private _defendMil = {_x isEqualType [] && {([_x, "objectiveType", "MIL"] call ALiVE_fnc_HashGet) == "MIL"}} count _defendingObjectives;
private _defendCiv = {_x isEqualType [] && {([_x, "objectiveType", "MIL"] call ALiVE_fnc_HashGet) == "CIV"}} count _defendingObjectives;

if (_attackMil > 0) then {
    [["CaptureObjective", "MilAssault", "DestroyInfantry", "DestroyVehicles", "CAS"], 4] call _appendWeightedTasks;
};

if (_defendMil > 0) then {
    [["MilDefence", "InsurgencyPatrol", "CAS", "DestroyInfantry"], 3] call _appendWeightedTasks;
};

if (_attackCiv > 0) then {
    [["CivAssault", "InsurgencyPatrol", "Assassination", "Wiretap"], 3] call _appendWeightedTasks;
};

if (_defendCiv > 0) then {
    [["InsurgencyPatrol", "Wiretap", "DestroyInfantry"], 2] call _appendWeightedTasks;
};

if (_taskEnemyFaction == "") then {
    [["InsurgencyPatrol", "Wiretap"], 1] call _appendWeightedTasks;
};

if (count _weightedTaskCandidates == 0) exitWith {
    _fallbackTask
};

selectRandom _weightedTaskCandidates
