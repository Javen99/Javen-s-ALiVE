/* ----------------------------------------------------------------------------
Function: ALIVE_fnc_advciv_isVehicleProtected
Description:
    Determines whether a vehicle should be protected from civilian theft during
    panic vehicle-escape attempts. Checks are applied in order and short-circuit
    as soon as one protection criterion is met. A vehicle is protected if:
    military faction protection is enabled and the vehicle belongs to a
    recognised military side or faction; player-used vehicle protection is
    enabled and the vehicle has been used by a player; or loaded cargo
    protection is enabled and the combined weapon, magazine, and item cargo
    exceeds ALiVE_advciv_loadedThreshold.
Parameters:
    _this select 0: OBJECT - The vehicle to evaluate
Returns:
    BOOLEAN - True if the vehicle is protected and should not be stolen,
              false otherwise
See Also:
    ALIVE_fnc_advciv_brainTick
Author:
    Jman (advanced civs)
Peer Reviewed:
    nil
---------------------------------------------------------------------------- */

params [["_veh", objNull, [objNull]]];

if (isNull _veh) exitWith { true };   // Null vehicle is treated as protected to be safe

private _protected = false;

// -----------------------------------------------------------------------
// Check 1: Military vehicle protection
// Protects vehicles belonging to a military side (0=WEST,1=EAST,2=IND) or
// a known military faction string to prevent civilians stealing combat vehicles
// -----------------------------------------------------------------------
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

// -----------------------------------------------------------------------
// Check 2: Player-used vehicle protection
// Prevents civilians stealing vehicles that a player has previously occupied
// -----------------------------------------------------------------------
if (ALiVE_advciv_noStealUsed && {!_protected}) then {
    if (_veh getVariable ["ALiVE_advciv_wasUsedByPlayer", false]) then {
        _protected = true;
    };
};

// -----------------------------------------------------------------------
// Check 3: Loaded cargo protection
// Protects vehicles carrying significant gear above the configured threshold,
// preventing civilians from inadvertently driving off with mission equipment
// -----------------------------------------------------------------------
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
