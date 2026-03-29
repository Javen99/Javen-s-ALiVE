/* ----------------------------------------------------------------------------
Function: ALIVE_fnc_addCivilianInteraction
Description:
    Adds the ALiVE civilian interaction action to a unit. For civilians without
    AdvCiv active, attaches a standalone Interact action linked to the
    ALiVE_civInteractHandler. If the unit already has AdvCiv enabled, no action
    is added here as the Interact option is provided within the AdvCiv order menu.
Parameters:
    _this select 0: OBJECT - The civilian unit to add the interaction to
Returns:
    Nil
See Also:
    ALIVE_fnc_advciv_orderMenu
Author:
    Jman (advanced civs)
Peer Reviewed:
    nil
---------------------------------------------------------------------------- */

params ["_unit"];

// Only proceed if the global interaction handler has been initialised and
// the unit is actually a civilian
if (!isNil "ALiVE_civInteractHandler" && {side _unit == CIVILIAN}) then {
    private _hasAdvCiv = _unit getVariable ["ALiVE_advciv_active", false];

    if (!_hasAdvCiv) then {
        // Non-AdvCiv civilian: add a standalone Interact action.
        // Match the range to ALiVE_advciv_orderMenuRange for visual consistency;
        // fall back to 4 m if AdvCiv hasn't set it (module not loaded).
        private _range = if (!isNil "ALiVE_advciv_orderMenuRange") then {
            ALiVE_advciv_orderMenuRange
        } else {
            4
        };

        _unit addAction [
            "Interact",
            {[ALiVE_civInteractHandler, "openMenu", _this select 0] call ALiVE_fnc_civInteract},
            "",
            50,
            true,
            false,
            "",
            format ["alive _target && _this distance _target < %1", _range],
            _range
        ];
    };
    // If the unit HAS AdvCiv active, the Interact option is already present
    // in the AdvCiv order menu added by fnc_advciv_orderMenu — skip it here.
};
