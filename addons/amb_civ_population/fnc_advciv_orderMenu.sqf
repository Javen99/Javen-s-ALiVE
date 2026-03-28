params [["_unit", objNull, [objNull]]];

if (isNull _unit || {!alive _unit}) exitWith {};
if (_unit getVariable ["ALiVE_advciv_orderMenuAdded", false]) exitWith {};

_unit setVariable ["ALiVE_advciv_orderMenuAdded", true];

private _range = ALiVE_advciv_orderMenuRange;

// --- FOLLOW ME ---
_unit addAction [
    "<t color='#00FF00'>Follow Me</t>",
    {
        params ["_target", "_caller"];
        [_target, "FOLLOW"] call ALiVE_fnc_advciv_react;
    },
    [],
    6,
    true,
    true,
    "",
    format ["alive _target && _this distance _target < %1", _range],
    _range
];

// --- STAY HERE ---
_unit addAction [
    "<t color='#00FF00'>Stay Here</t>",
    {
        params ["_target", "_caller"];
        [_target, "STAY"] call ALiVE_fnc_advciv_react;
    },
    [],
    6,
    true,
    true,
    "",
    format ["alive _target && _this distance _target < %1", _range],
    _range
];

// --- GO HOME ---
_unit addAction [
    "<t color='#00FF00'>Go Home</t>",
    {
        params ["_target", "_caller"];
        [_target, "GOHOME"] call ALiVE_fnc_advciv_react;
    },
    [],
    6,
    true,
    true,
    "",
    format ["alive _target && _this distance _target < %1", _range],
    _range
];

// --- HANDS UP ---
_unit addAction [
    "<t color='#00FF00'>Hands Up</t>",
    {
        params ["_target", "_caller"];
        [_target, "HANDSUP"] call ALiVE_fnc_advciv_react;
    },
    [],
    6,
    true,
    true,
    "",
    format ["alive _target && _this distance _target < %1", _range],
    _range
];

// --- GET DOWN ---
_unit addAction [
    "<t color='#00FF00'>Get Down</t>",
    {
        params ["_target", "_caller"];
        [_target, "GETDOWN"] call ALiVE_fnc_advciv_react;
    },
    [],
    6,
    true,
    true,
    "",
    format ["alive _target && _this distance _target < %1", _range],
    _range
];

// --- CALM DOWN ---
_unit addAction [
    "<t color='#00FF00'>Calm Down</t>",
    {
        params ["_target", "_caller"];
        [_target, "CALM"] call ALiVE_fnc_advciv_react;
    },
    [],
    6,
    true,
    true,
    "",
    format ["alive _target && _this distance _target < %1", _range],
    _range
];

// --- KNEEL ---
_unit addAction [
    "<t color='#00FF00'>Kneel</t>",
    {
        params ["_target", "_caller"];
        [_target, "KNEEL"] call ALiVE_fnc_advciv_react;
    },
    [],
    6,
    true,
    true,
    "",
    format ["alive _target && _this distance _target < %1", _range],
    _range
];

// --- GET IN VEHICLE (dynamic, only if vehicle nearby) ---
private _nearVehicles = nearestObjects [_unit, ["Car", "Truck", "Helicopter", "Plane", "Ship"], 10];
_nearVehicles = _nearVehicles select {
    alive _x && {
        (_x emptyPositions "cargo" > 0) || 
        (_x emptyPositions "driver" > 0)
    }
};

if (count _nearVehicles > 0) then {
    {
        private _veh = _x;
        private _vehName = getText (configFile >> "CfgVehicles" >> typeOf _veh >> "displayName");
        _unit addAction [
            format ["<t color='#00FF00'>Get in %1</t>", _vehName],
            {
                params ["_target", "_caller", "_id", "_args"];
                _args params ["_vehicle"];
                [_target, "GETIN", _vehicle] call ALiVE_fnc_advciv_react;  // Pass vehicle as 3rd param
            },
            [_veh],
            6,
            true,
            true,
            "",
            format ["alive _target && _this distance _target < %1", _range],
            _range
        ];
    } forEach _nearVehicles;
};

// =================================================================
// ADD ALIVE INTERACT OPTION (if available)
// =================================================================
if (!isNil "ALiVE_civInteractHandler") then {
    _unit addAction [
        "<t color='#FFD700'>────────────────</t>",  // Separator (gold)
        {},
        [],
        5,
        false,  // Can't be used
        false,
        "",
        "false",  // Never show (visual separator only)
        _range
    ];
    
    _unit addAction [
        "<t color='#FFD700'>ALiVE: Interact (Dialog)</t>",  // Gold color to distinguish
        {
            params ["_target", "_caller"];
            [ALiVE_civInteractHandler, "openMenu", _target] call ALiVE_fnc_civInteract;
        },
        [],
        5,  // Lower priority than AdvCiv quick actions
        true,
        true,
        "",
        format ["alive _target && _this distance _target < %1", _range],
        _range
    ];
};