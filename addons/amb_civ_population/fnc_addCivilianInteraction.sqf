params ["_unit"];

if (!isNil "ALiVE_civInteractHandler" && {side _unit == CIVILIAN}) then {
    // Check if unit has AdvCiv active
    private _hasAdvCiv = _unit getVariable ["ALiVE_advciv_active", false];
    
    if (!_hasAdvCiv) then {
        // Non-AdvCiv civilian: Add standalone Interact action
        // Use same range as AdvCiv for consistency
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
    // If unit HAS AdvCiv, the Interact option will be in the AdvCiv menu
};