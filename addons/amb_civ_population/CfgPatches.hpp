// Simply a package which requires other addons.
class CfgPatches {
    class ADDON {
        units[] = {};
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        requiredAddons[] = {"ALIVE_main","A3_Anims_F"};
        versionDesc = "ALiVE";
        //versionAct = "['amb_civ_population',_this] execVM '\x\alive\addons\main\about.sqf';";
        VERSION_CONFIG;
        author = MODULE_AUTHOR;
        authors[] = {"ARJay"};
        authorUrl = "http://alivemod.com/";
    };
};
class Extended_PreInit_EventHandlers {
    class ADDON {
        init = QUOTE(call COMPILE_FILE(XEH_preInit));
    };
};
class Extended_PostInit_EventHandlers {
    class ADDON {
        init = QUOTE(call COMPILE_FILE(XEH_postInit));
    };
};
class ALiVE_amb_civ_population_advciv {
    name = "ALiVE Advanced Civilians";
    author = "Jman";
    url = "";
    units[] = {};
    weapons[] = {};
    requiredVersion = 1.0;
    requiredAddons[] = {"ALiVE_amb_civ_population", "cba_xeh"};
};
