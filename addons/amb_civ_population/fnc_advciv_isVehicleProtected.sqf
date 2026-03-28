
params [["_veh", objNull, [objNull]]];

if (isNull _veh) exitWith { true };

private _protected = false;

if (ALiVE_advciv_noStealMilitary && {!_protected}) then {
    private _cfg = configFile >> "CfgVehicles" >> (typeOf _veh);
    if (isClass _cfg) then {
        private _side = getNumber (_cfg >> "side");
        if (_side in [0, 1, 2]) then {
            _protected = true;
        };

        if (!_protected) then {
            private _faction = toLower (getText (_cfg >> "faction"));
            private _milFactions = ["blu_f","opf_f","ind_f","blu_g_f","opf_g_f","ind_g_f",
                                    "blu_t_f","opf_t_f","ind_c_f","blu_ctrg_f","blu_gen_f"];
            if (_faction in _milFactions) then {
                _protected = true;
            };
        };
    };
};

if (ALiVE_advciv_noStealUsed && {!_protected}) then {
    if (_veh getVariable ["ALiVE_advciv_wasUsedByPlayer", false]) then {
        _protected = true;
    };
};

if (ALiVE_advciv_noStealLoaded && {!_protected}) then {
    private _cargo   = magazineCargo _veh;
    private _items   = itemCargo _veh;
    private _weapons = weaponCargo _veh;

    if (isNil "_cargo")   then { _cargo = []; };
    if (isNil "_items")   then { _items = []; };
    if (isNil "_weapons") then { _weapons = []; };

    private _total = (count _cargo) + (count _items) + (count _weapons);
    if (_total > ALiVE_advciv_loadedThreshold) then {
        _protected = true;
    };
};

_protected