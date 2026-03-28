class CfgVehicles {
    class ModuleAliveBase;
    class ADDON : ModuleAliveBase
    {
        scope = 2;
        displayName = "$STR_ALIVE_CIV_POP";
        function = "ALIVE_fnc_civilianPopulationSystemInit";
        author = MODULE_AUTHOR;
        functionPriority = 70;
        isGlobal = 2;
        icon = "x\alive\addons\amb_civ_population\icon_civ_pop.paa";
        picture = "x\alive\addons\amb_civ_population\icon_civ_pop.paa";
        class Arguments
        {
            class debug
            {
                    displayName = "$STR_ALIVE_CIV_POP_DEBUG";
                    description = "$STR_ALIVE_CIV_POP_DEBUG_COMMENT";
                    class Values
                    {
                            class Yes
                            {
                                    name = "Yes";
                                    value = true;
                            };
                            class No
                            {
                                    name = "No";
                                    value = false;
                                    default = 1;
                            };
                    };
            };
            class spawnRadius
            {
                    displayName = "$STR_ALIVE_CIV_POP_SPAWN_RADIUS";
                    description = "$STR_ALIVE_CIV_POP_SPAWN_RADIUS_COMMENT";
                    defaultvalue = "900";
            };
            class spawnTypeHeliRadius
            {
                    displayName = "$STR_ALIVE_CIV_POP_SPAWN_HELI_RADIUS";
                    description = "$STR_ALIVE_CIV_POP_SPAWN_HELI_RADIUS_COMMENT";
                    defaultvalue = "900";
            };
            class spawnTypeJetRadius
            {
                    displayName = "$STR_ALIVE_CIV_POP_SPAWN_JET_RADIUS";
                    description = "$STR_ALIVE_CIV_POP_SPAWN_JET_RADIUS_COMMENT";
                    defaultvalue = "0";
            };
            class activeLimiter
            {
                    displayName = "$STR_ALIVE_CIV_POP_ACTIVE_LIMITER";
                    description = "$STR_ALIVE_CIV_POP_ACTIVE_LIMITER_COMMENT";
                    defaultvalue = "25";
            };
            class hostilityWest
            {
                    displayName = "$STR_ALIVE_CIV_POP_HOSTILITY_WEST";
                    description = "$STR_ALIVE_CIV_POP_HOSTILITY_WEST_COMMENT";
                    class Values
                    {
                            class LOW
                            {
                                    name = "$STR_ALIVE_CIV_POP_HOSTILITY_WEST_LOW";
                                    value = "0";
                                    default = 1;
                            };
                            class MEDIUM
                            {
                                    name = "$STR_ALIVE_CIV_POP_HOSTILITY_WEST_MEDIUM";
                                    value = "30";
                            };
                            class HIGH
                            {
                                    name = "$STR_ALIVE_CIV_POP_HOSTILITY_WEST_HIGH";
                                    value = "60";
                            };
                            class EXTREME
                            {
                                    name = "$STR_ALIVE_CIV_POP_HOSTILITY_WEST_EXTREME";
                                    value = "130";
                            };
                    };
            };
            class hostilityEast
            {
                  displayName = "$STR_ALIVE_CIV_POP_HOSTILITY_EAST";
                  description = "$STR_ALIVE_CIV_POP_HOSTILITY_EAST_COMMENT";
                  class Values
                  {
                          class LOW
                          {
                                  name = "$STR_ALIVE_CIV_POP_HOSTILITY_EAST_LOW";
                                  value = "0";
                                  default = 1;
                          };
                          class MEDIUM
                          {
                                  name = "$STR_ALIVE_CIV_POP_HOSTILITY_EAST_MEDIUM";
                                  value = "30";
                          };
                          class HIGH
                          {
                                  name = "$STR_ALIVE_CIV_POP_HOSTILITY_EAST_HIGH";
                                  value = "60";
                          };
                          class EXTREME
                          {
                                  name = "$STR_ALIVE_CIV_POP_HOSTILITY_EAST_EXTREME";
                                  value = "130";
                          };
                  };
            };
            class hostilityIndep
            {
                  displayName = "$STR_ALIVE_CIV_POP_HOSTILITY_INDEP";
                  description = "$STR_ALIVE_CIV_POP_HOSTILITY_INDEP_COMMENT";
                  class Values
                  {
                          class LOW
                          {
                                  name = "$STR_ALIVE_CIV_POP_HOSTILITY_INDEP_LOW";
                                  value = "0";
                                  default = 1;
                          };
                          class MEDIUM
                          {
                                  name = "$STR_ALIVE_CIV_POP_HOSTILITY_INDEP_MEDIUM";
                                  value = "30";
                          };
                          class HIGH
                          {
                                  name = "$STR_ALIVE_CIV_POP_HOSTILITY_INDEP_HIGH";
                                  value = "60";
                          };
                          class EXTREME
                          {
                                  name = "$STR_ALIVE_CIV_POP_HOSTILITY_INDEP_EXTREME";
                                  value = "130";
                          };
                  };
            };
            class ambientCivilianRoles
            {
                    displayName = "$STR_ALIVE_CIV_POP_CIVILIAN_ROLES";
                    description = "$STR_ALIVE_CIV_POP_CIVILIAN_ROLES_COMMENT";
                    class Values
                    {
                            class NONE
                            {
                                    name = "$STR_ALIVE_CIV_POP_CIVILIAN_ROLES_NONE";
                                    value = [];
                                    default = 1;
                            };
                            class WESTERN
                            {
                                    name = "$STR_ALIVE_CIV_POP_CIVILIAN_ROLES_WEST";
                                    value = ["major","priest","politician"];
                            };
                            class EASTERN
                            {
                                    name = "$STR_ALIVE_CIV_POP_CIVILIAN_ROLES_EAST";
                                    value = ["townelder","muezzin","politician"];
                            };
                    };
            };
            class enableInteraction
            {
                displayName = "Enable Interaction";
                description = "Enable advanced interaction with civilians";
                class values
                {
                    class Yes {
                        name = "Yes";
                        value = true;
                    };

                    class No {
                        name = "No";
                        value = false;
                        default = 1;
                    };
                };
            };
            class limitInteraction
            {
                    displayName = "Limit Interaction";
                    description = "To limit civilian interaction to specific classes or playes, Specify the classnames or player IDs here. i.e. ['B_Officer_F','123456789']";
                    defaultvalue = "";
            };
            class insurgentFaction
            {
                    displayName = "Insurgent Faction";
                    description = "Specify the faction that civilians will inform on to players during interactions.";
                    defaultvalue = "";
            };
            class ambientCrowdSpawn
            {
                    displayName = "$STR_ALIVE_CIV_POP_CROWD_SPAWN_RADIUS";
                    description = "$STR_ALIVE_CIV_POP_CROWD_SPAWN_RADIUS_COMMENT";
                    defaultvalue = "50";
            };
            class ambientCrowdDensity
            {
                    displayName = "$STR_ALIVE_CIV_POP_CROWD_DENSITY";
                    description = "$STR_ALIVE_CIV_POP_CROWD_DENSITY_COMMENT";
                    defaultvalue = "3";
            };
            class ambientCrowdLimit
            {
                    displayName = "$STR_ALIVE_CIV_POP_CROWD_ACTIVE_LIMITER";
                    description = "$STR_ALIVE_CIV_POP_CROWD_ACTIVE_LIMITER_COMMENT";
                    defaultvalue = "50";
            };
            class ambientCrowdFaction
            {
                    displayName = "$STR_ALIVE_CIV_POP_CROWD_FACTION";
                    description = "$STR_ALIVE_CIV_POP_CROWD_FACTION_COMMENT";
                    defaultvalue = "";
            };
            class humanitarianHostilityChance
            {
                displayName = "$STR_ALIVE_CIV_POP_HOSTILITY_CHANCE";
                description = "$STR_ALIVE_CIV_POP_HOSTILITY_CHANCE_COMMENT";
                class Values
                  {
                          class LOW
                          {
                                  name = "Low Chance";
                                  value = "20";
                                  default = 1;
                          };
                          class MEDIUM
                          {
                                  name = "Medium Chance";
                                  value = "40";
                          };
                          class HIGH
                          {
                                  name = "High Chance";
                                  value = "60";
                          };
                          class EXTREME
                          {
                                  name = "Extreme Chance";
                                  value = "80";
                          };
                  };
            };
            class maxAllowAid
            {
                displayName = "$STR_ALIVE_CIV_POP_MAX_ALLOWED_AID";
                description = "$STR_ALIVE_CIV_POP_MAX_ALLOWED_AID_COMMENT";
                defaultvalue = "3";
            };
            class customWaterItems
            {
                displayName = "$STR_ALIVE_CIV_POP_WATER_ITEMS";
                description = "$STR_ALIVE_CIV_POP_WATER_ITEMS_COMMENT";
                defaultvalue = "";
            };
            class customHumRatItems
            {
                displayName = "$STR_ALIVE_CIV_POP_HUMRAT_ITEMS";
                description = "$STR_ALIVE_CIV_POP_HUMRAT_ITEMS_COMMENT";
                defaultvalue = "";
            };
            class disableACEX
            {
                displayName = "$STR_ALIVE_CIV_POP_ACEX_COMPAT";
                description = "$STR_ALIVE_CIV_POP_ACEX_COMPAT_COMMENT";
                typeName = "BOOL";
                defaultValue = 0;
            };

            // ----------------------------------------------------------------
            //  Advanced Civilians - General
            // ----------------------------------------------------------------
            class advciv_enabled
            {
                displayName = "$STR_ALIVE_ADVCIV_ENABLED";
                description = "$STR_ALIVE_ADVCIV_ENABLED_COMMENT";
                class Values
                {
                    class Yes
                    {
                        name = "Yes";
                        value = true;
                        default = 1;
                    };
                    class No
                    {
                        name = "No";
                        value = false;
                    };
                };
            };
            class advciv_debug
            {
                displayName = "$STR_ALIVE_ADVCIV_DEBUG";
                description = "$STR_ALIVE_ADVCIV_DEBUG_COMMENT";
                class Values
                {
                    class No
                    {
                        name = "No";
                        value = false;
                        default = 1;
                    };
                    class Yes
                    {
                        name = "Yes";
                        value = true;
                    };
                };
            };
            class advciv_tickRate
            {
                displayName = "$STR_ALIVE_ADVCIV_TICK_RATE";
                description = "$STR_ALIVE_ADVCIV_TICK_RATE_COMMENT";
                defaultvalue = "3";
            };
            class advciv_batchSize
            {
                displayName = "$STR_ALIVE_ADVCIV_BATCH_SIZE";
                description = "$STR_ALIVE_ADVCIV_BATCH_SIZE_COMMENT";
                defaultvalue = "0";
            };

            // ----------------------------------------------------------------
            //  Advanced Civilians - Trigger Ranges
            // ----------------------------------------------------------------
            class advciv_unsuppressedRange
            {
                displayName = "$STR_ALIVE_ADVCIV_UNSUPPRESSED_RANGE";
                description = "$STR_ALIVE_ADVCIV_UNSUPPRESSED_RANGE_COMMENT";
                defaultvalue = "250";
            };
            class advciv_suppressedRange
            {
                displayName = "$STR_ALIVE_ADVCIV_SUPPRESSED_RANGE";
                description = "$STR_ALIVE_ADVCIV_SUPPRESSED_RANGE_COMMENT";
                defaultvalue = "50";
            };
            class advciv_explosionRange
            {
                displayName = "$STR_ALIVE_ADVCIV_EXPLOSION_RANGE";
                description = "$STR_ALIVE_ADVCIV_EXPLOSION_RANGE_COMMENT";
                defaultvalue = "500";
            };

            // ----------------------------------------------------------------
            //  Advanced Civilians - Behaviour
            // ----------------------------------------------------------------
            class advciv_reactionRadius
            {
                displayName = "$STR_ALIVE_ADVCIV_REACTION_RADIUS";
                description = "$STR_ALIVE_ADVCIV_REACTION_RADIUS_COMMENT";
                defaultvalue = "150";
            };
            class advciv_fleeRadius
            {
                displayName = "$STR_ALIVE_ADVCIV_FLEE_RADIUS";
                description = "$STR_ALIVE_ADVCIV_FLEE_RADIUS_COMMENT";
                defaultvalue = "120";
            };
            class advciv_homeRadius
            {
                displayName = "$STR_ALIVE_ADVCIV_HOME_RADIUS";
                description = "$STR_ALIVE_ADVCIV_HOME_RADIUS_COMMENT";
                defaultvalue = "150";
            };
            class advciv_curiosityRange
            {
                displayName = "$STR_ALIVE_ADVCIV_CURIOSITY_RANGE";
                description = "$STR_ALIVE_ADVCIV_CURIOSITY_RANGE_COMMENT";
                defaultvalue = "200";
            };
            class advciv_panicChance
            {
                displayName = "$STR_ALIVE_ADVCIV_PANIC_CHANCE";
                description = "$STR_ALIVE_ADVCIV_PANIC_CHANCE_COMMENT";
                defaultvalue = "0.7";
            };
            class advciv_alertChance
            {
                displayName = "$STR_ALIVE_ADVCIV_ALERT_CHANCE";
                description = "$STR_ALIVE_ADVCIV_ALERT_CHANCE_COMMENT";
                defaultvalue = "0.5";
            };
            class advciv_cascadeRadius
            {
                displayName = "$STR_ALIVE_ADVCIV_CASCADE_RADIUS";
                description = "$STR_ALIVE_ADVCIV_CASCADE_RADIUS_COMMENT";
                defaultvalue = "20";
            };
            class advciv_cascadeChance
            {
                displayName = "$STR_ALIVE_ADVCIV_CASCADE_CHANCE";
                description = "$STR_ALIVE_ADVCIV_CASCADE_CHANCE_COMMENT";
                defaultvalue = "0.25";
            };
            class advciv_shotMemoryTime
            {
                displayName = "$STR_ALIVE_ADVCIV_SHOT_MEMORY_TIME";
                description = "$STR_ALIVE_ADVCIV_SHOT_MEMORY_TIME_COMMENT";
                defaultvalue = "30";
            };
            class advciv_handsUpChance
            {
                displayName = "$STR_ALIVE_ADVCIV_HANDSUP_CHANCE";
                description = "$STR_ALIVE_ADVCIV_HANDSUP_CHANCE_COMMENT";
                defaultvalue = "0.30";
            };
            class advciv_dropChance
            {
                displayName = "$STR_ALIVE_ADVCIV_DROP_CHANCE";
                description = "$STR_ALIVE_ADVCIV_DROP_CHANCE_COMMENT";
                defaultvalue = "0.25";
            };
            class advciv_freezeChance
            {
                displayName = "$STR_ALIVE_ADVCIV_FREEZE_CHANCE";
                description = "$STR_ALIVE_ADVCIV_FREEZE_CHANCE_COMMENT";
                defaultvalue = "0.15";
            };
            class advciv_screamChance
            {
                displayName = "$STR_ALIVE_ADVCIV_SCREAM_CHANCE";
                description = "$STR_ALIVE_ADVCIV_SCREAM_CHANCE_COMMENT";
                defaultvalue = "0.15";
            };
            class advciv_crawlChance
            {
                displayName = "$STR_ALIVE_ADVCIV_CRAWL_CHANCE";
                description = "$STR_ALIVE_ADVCIV_CRAWL_CHANCE_COMMENT";
                defaultvalue = "0.15";
            };
            class advciv_hideTimeMin
            {
                displayName = "$STR_ALIVE_ADVCIV_HIDE_TIME_MIN";
                description = "$STR_ALIVE_ADVCIV_HIDE_TIME_MIN_COMMENT";
                defaultvalue = "60";
            };
            class advciv_hideTimeMax
            {
                displayName = "$STR_ALIVE_ADVCIV_HIDE_TIME_MAX";
                description = "$STR_ALIVE_ADVCIV_HIDE_TIME_MAX_COMMENT";
                defaultvalue = "180";
            };
            class advciv_preferBuildings
            {
                displayName = "$STR_ALIVE_ADVCIV_PREFER_BUILDINGS";
                description = "$STR_ALIVE_ADVCIV_PREFER_BUILDINGS_COMMENT";
                class Values
                {
                    class Yes
                    {
                        name = "Yes";
                        value = true;
                        default = 1;
                    };
                    class No
                    {
                        name = "No";
                        value = false;
                    };
                };
            };
            class advciv_voiceEnabled
            {
                displayName = "$STR_ALIVE_ADVCIV_VOICE_ENABLED";
                description = "$STR_ALIVE_ADVCIV_VOICE_ENABLED_COMMENT";
                class Values
                {
                    class Yes
                    {
                        name = "Yes";
                        value = true;
                        default = 1;
                    };
                    class No
                    {
                        name = "No";
                        value = false;
                    };
                };
            };
            class advciv_voiceChance
            {
                displayName = "$STR_ALIVE_ADVCIV_VOICE_CHANCE";
                description = "$STR_ALIVE_ADVCIV_VOICE_CHANCE_COMMENT";
                defaultvalue = "0.6";
            };
            class advciv_orderMenuEnabled
            {
                displayName = "$STR_ALIVE_ADVCIV_ORDER_MENU_ENABLED";
                description = "$STR_ALIVE_ADVCIV_ORDER_MENU_ENABLED_COMMENT";
                class Values
                {
                    class Yes
                    {
                        name = "Yes";
                        value = true;
                        default = 1;
                    };
                    class No
                    {
                        name = "No";
                        value = false;
                    };
                };
            };
            class advciv_orderMenuRange
            {
                displayName = "$STR_ALIVE_ADVCIV_ORDER_MENU_RANGE";
                description = "$STR_ALIVE_ADVCIV_ORDER_MENU_RANGE_COMMENT";
                defaultvalue = "4";
            };
            class advciv_playerAnimations
            {
                displayName = "$STR_ALIVE_ADVCIV_PLAYER_ANIMATIONS";
                description = "$STR_ALIVE_ADVCIV_PLAYER_ANIMATIONS_COMMENT";
                class Values
                {
                    class Yes
                    {
                        name = "Yes";
                        value = true;
                        default = 1;
                    };
                    class No
                    {
                        name = "No";
                        value = false;
                    };
                };
            };

            // ----------------------------------------------------------------
            //  Advanced Civilians - Vehicle
            // ----------------------------------------------------------------
            class advciv_vehicleEscape
            {
                displayName = "$STR_ALIVE_ADVCIV_VEHICLE_ESCAPE";
                description = "$STR_ALIVE_ADVCIV_VEHICLE_ESCAPE_COMMENT";
                class Values
                {
                    class Yes
                    {
                        name = "Yes";
                        value = true;
                        default = 1;
                    };
                    class No
                    {
                        name = "No";
                        value = false;
                    };
                };
            };
            class advciv_vehicleEscapeChance
            {
                displayName = "$STR_ALIVE_ADVCIV_VEHICLE_ESCAPE_CHANCE";
                description = "$STR_ALIVE_ADVCIV_VEHICLE_ESCAPE_CHANCE_COMMENT";
                defaultvalue = "0.3";
            };
            class advciv_noStealMilitary
            {
                displayName = "$STR_ALIVE_ADVCIV_NO_STEAL_MILITARY";
                description = "$STR_ALIVE_ADVCIV_NO_STEAL_MILITARY_COMMENT";
                class Values
                {
                    class Yes
                    {
                        name = "Yes";
                        value = true;
                        default = 1;
                    };
                    class No
                    {
                        name = "No";
                        value = false;
                    };
                };
            };
            class advciv_noStealUsed
            {
                displayName = "$STR_ALIVE_ADVCIV_NO_STEAL_USED";
                description = "$STR_ALIVE_ADVCIV_NO_STEAL_USED_COMMENT";
                class Values
                {
                    class Yes
                    {
                        name = "Yes";
                        value = true;
                        default = 1;
                    };
                    class No
                    {
                        name = "No";
                        value = false;
                    };
                };
            };
            class advciv_noStealLoaded
            {
                displayName = "$STR_ALIVE_ADVCIV_NO_STEAL_LOADED";
                description = "$STR_ALIVE_ADVCIV_NO_STEAL_LOADED_COMMENT";
                class Values
                {
                    class Yes
                    {
                        name = "Yes";
                        value = true;
                        default = 1;
                    };
                    class No
                    {
                        name = "No";
                        value = false;
                    };
                };
            };
            class advciv_loadedThreshold
            {
                displayName = "$STR_ALIVE_ADVCIV_LOADED_THRESHOLD";
                description = "$STR_ALIVE_ADVCIV_LOADED_THRESHOLD_COMMENT";
                defaultvalue = "4";
            };

            // ----------------------------------------------------------------
            //  Advanced Civilians - Compatibility
            // ----------------------------------------------------------------
            class advciv_missionCriticalCheck
            {
                displayName = "$STR_ALIVE_ADVCIV_MISSION_CRITICAL";
                description = "$STR_ALIVE_ADVCIV_MISSION_CRITICAL_COMMENT";
                class Values
                {
                    class Yes
                    {
                        name = "Yes";
                        value = true;
                        default = 1;
                    };
                    class No
                    {
                        name = "No";
                        value = false;
                    };
                };
            };
        };

    };

    class Item_Base_F;
    class ALiVE_Waterbottle_Item: Item_Base_F
    {
        scope = 2;
        scopeCurator = 2;
        displayName = "ALiVE Water Bottle (Full)";
        author = "ALiVE Mod";
        vehicleClass = "Items";
        class TransportItems {
                class ALiVE_Waterbottle {
                        name = "ALiVE_Waterbottle";
                        count = 1;
                };
        };
    };
    class ALiVE_Humrat_Item: Item_Base_F
    {
        scope = 2;
        scopeCurator = 2;
        displayName = "ALiVE Rice Pack";
        author = "ALiVE Mod";
        vehicleClass = "Items";
        class TransportItems {
                class ALiVE_Humrat {
                        name = "ALiVE_Humrat";
                        count = 1;
                };
        };
    };

    class NATO_Box_Base;
    class ALiVE_Humanitarian_Crates: NATO_Box_Base
    {
        scope = 2;
        accuracy = 1;
        displayName = "ALiVE Humanitarian Crate";
        transportMaxItems = 2000;
        maximumload = 2000;
        model = "\A3\weapons_F\AmmoBoxes\WpnsBox_large_F";
        editorPreview = "\A3\EditorPreviews_F\Data\CfgVehicles\Box_NATO_WpsSpecial_F.jpg";
        class TransportItems {
                MACRO_ADDITEM(ALiVE_Waterbottle,100);
                MACRO_ADDITEM(ALiVE_Humrat,100);
        };
    };
};