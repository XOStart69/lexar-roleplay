---@class PedConfig
---@field resource string
---@field id? any used to remove the ped location later if desired
---@field ped? number hash of ped after spawned
---@field model string The model identifier for the pedestrian.
---@field coords vector4 | vector4[] The spawn coordinates and orientation for the pedestrian.
---@field scenario? string the scenario you want the ped to play when spawned
---@field animation? {dict: string, anim: string, flag?: number} the animation you want the ped to play when spawned
---@field prop? {propModel: string | number, bone: string | number, rot?: vector3, pos?: vector3, entity: number} -- prop is spawned and attached to ped
---@field renderDistance number The distance at which the pedestrian starts being rendered.
---@field targetOptions OxTargetOption[] A list of options for interaction targets with the pedestrian.
---@field interactOptions LocalEntityData Configuration for text UI interactions.
---@field faceData? table Face customization for freemode peds only (mp_m_freemode_01 / mp_f_freemode_01)
---@field outfit? table[] Outfit configuration for freemode peds only
---@field onSpawn function A callback function that is called when the pedestrian is spawned.
---@field onDespawn function A callback function that is called when the pedestrian is despawned

---@type PedConfig[]
return {

    {
        model = "mp_m_boatstaff_01",
        coords = vec4(-318.2813, 6633.4712, 1.7465, 54.1601),
        renderDistance = 15.0,
        scenario = "WORLD_HUMAN_CLIPBOARD",
    },

    {
        model = "cs_bankman",
        coords = vec4(-1029.96, -2734.8, 20.25, 330.76),
        renderDistance = 15.0,
        scenario = "WORLD_HUMAN_CLIPBOARD",
    },

    {
        model = "a_m_y_genstreet_02",
        coords = vec4(159.4324, 3130.0242, 43.5841, 16.9920),
        renderDistance = 15.0,
        scenario = "WORLD_HUMAN_SMOKING",
        interactOptions = {
            {
                label = "Jual Barang Blackmarket",
                onSelect = function()
                    TriggerEvent("axon-sellitems:openSellMenuBlackmarket")
                end,
            },
            {
                label = "Beli Barang Blackmarket",
                onSelect = function()
                    TriggerEvent("axon-sellitems:openSellMenuShopBlackmarket")
                end,
            },
        },
    },

    {
        model = "a_m_y_genstreet_02",
        coords = vec4(2484.7590, 3718.6719, 43.4672, 215.0806),
        renderDistance = 15.0,
        scenario = "WORLD_HUMAN_SMOKING",
    },

    {
        model = "a_m_y_genstreet_01",
        coords = vec4(-430.1340, 1205.3219, 325.7586, 169.5727),
        renderDistance = 15.0,
        scenario = "WORLD_HUMAN_CLIPBOARD",
        interactOptions = {
            {
                label = "Jual Barang Disnaker",
                icon = "hand",
                onSelect = function()
                    TriggerEvent("axon-sellitems:openSellMenuPawn")
                end,
            },
            {
                label = "Jual Ikan 🐟",
                icon = "fish",
                onSelect = function()
                    TriggerEvent("axon-sellitems:openSellMenuFishingMan")
                end,
            },
        },
    },
    {
        model = "cs_bankman",
        coords = {
            vec4(-426.73, 1109.31, 327.68, 347.81),
            vec4(-749.24, -1294.08, 5.15, 115.8),
            vec4(12.1670, 353.0339, 112.0902, 87.0897),
            vec4(1164.1127, -1517.1561, 34.8438,355.9461),
            vec4(1270.6146, 3774.3372, 37.5523, 192.1346),
            vec4(-2708.5518, 4178.0732, 25.6233, 236.2740),
        },
        renderDistance = 15.0,
        scenario = "WORLD_HUMAN_CLIPBOARD",
    },

    {
        model = "g_m_m_chicold_01",
        coords = {
            vec4(801.2426, -2464.2527, 21.8183, 188.0939),
            vec4(793.3742, -2464.9729, 21.1766, 172.1512),
            vec4(785.2886, -2468.5781, 20.5147, 180.6426),
        },
        renderDistance = 25.0,
        scenario = "WORLD_HUMAN_GUARD_STAND_ARMY",
    },

    {
        model = "mp_m_freemode_01",
        coords = vec4(-850.8816, 7189.5425, 99.7976, 27.1089),
        renderDistance = 40.0,
        scenario = "WORLD_HUMAN_PROSTITUTE_HIGH_CLASS",
        faceData = {
            father = 48,
            mother = 47,
            skinFather = 23,
            skinMother = 0,
            shapeMix = 0.5,
            skinMix = 0.0,
            hair = {
                model = 1228,
                color = 14,
                highlight = 14
            },
            eyebrows = {
                model = 12,
                color = 0,
                opacity = 0.0
            }
        },
        outfit = {
            { component = 1,  drawable = 0, texture = 0 },
            { component = 2,  drawable = 1228, texture = 0 },
            { component = 3,  drawable = 5, texture = 0 },
            { component = 4,  drawable = 595, texture = 0 },
            { component = 5,  drawable = 0, texture = 0 },
            { component = 6,  drawable = 180, texture = 0 },
            { component = 7,  drawable = 510, texture = 1 },
            { component = 8,  drawable = 229, texture = 0 },
            { component = 9,  drawable = 0, texture = 0 },
            { component = 10, drawable = 0, texture = 0 },
            { component = 11, drawable = 587, texture = 0 },
        }
    },

    -- TOP 1 MG
    {
        model = "mg",
        coords = vec4(-735.92, -1303.56, 5.87, 141.92),
        renderDistance = 40.0,
        scenario = "WORLD_HUMAN_SMOKING_CLUBHOUSE",
        outfit = {
            { component = 2,  drawable = 1, texture = 0 },
            { component = 3,  drawable = 7, texture = 0 },
            { component = 4,  drawable = 4, texture = 0 },
            { component = 5,  drawable = 2, texture = 0 },
            { component = 6,  drawable = 6, texture = 0 },
            { component = 10, drawable = 1, texture = 0 },
            { component = 11, drawable = 10, texture = 0 },
        }
    },

    -- TOP 2 GINZ ARD
    {
        model = "mp_m_freemode_01",
        coords = vec4(-736.9, -1302.69, 5.66, 139.13),
        renderDistance = 40.0,
        scenario = "WORLD_HUMAN_STAND_MOBILE",
        faceData = {
            father = 92,
            mother = 0,
            skinFather = 1,
            skinMother = 6,
            shapeMix = 0.0,
            skinMix = 1.0,
            hair = {
                model = 942,
                color = 15,
                highlight = 29
            },
            eyebrows = {
                model = 0,
                opacity = 1.0
            }
        },
        outfit = {
            { component = 1,  drawable = 0,   texture = 0 },
            { component = 3,  drawable = 14,  texture = 0 },
            { component = 4,  drawable = 24,  texture = 0 },
            { component = 5,  drawable = 0,   texture = 0 },
            { component = 6,  drawable = 106, texture = 0 },
            { component = 7,  drawable = 28,  texture = 2 },
            { component = 8,  drawable = 28,  texture = 0 },
            { component = 10, drawable = 291, texture = 0 },
            { component = 11, drawable = 28,  texture = 0 },
        }
    },

    -- TOP 3 MAX WELL
    {
        model = "ig_bosemon",
        coords = vec4(-735.03, -1304.57, 5.66, 139.07),
        renderDistance = 40.0,
        scenario = "WORLD_HUMAN_PARTYING",
        outfit = {
            { component = 2,  drawable = 1, texture = 0 },
            { component = 3,  drawable = 2, texture = 0 },
            { component = 4,  drawable = 1, texture = 1 },
            { component = 6,  drawable = 1, texture = 0 },
            { component = 11, drawable = 2, texture = 1 },
        }
    },

    -- TOP 4 Pak Haji
    {
        model = "mp_m_freemode_01",
        coords = vec4(-762.5682, -1335.1185, 5.8730, 319.2339),
        renderDistance = 40.0,
        scenario = "WORLD_HUMAN_GOLF_PLAYER",
        faceData = {
            father = 31,
            mother = 0,
            skinFather = 1,
            skinMother = 6,
            shapeMix = 0.0,
            skinMix = 1.0,
            hair = {
                model = 19,
                color = 14,
                highlight = 14
            },
            eyebrows = {
                model = 2,
                opacity = 1.0
            }
        },
        outfit = {
            { component = 1,  drawable = 51,  texture = 0 },
            { component = 3,  drawable = 75,  texture = 0 },
            { component = 4,  drawable = 24,  texture = 5 },
            { component = 5,  drawable = 0,   texture = 0 },
            { component = 6,  drawable = 10,  texture = 0 },
            { component = 7,  drawable = 24,  texture = 2 },
            { component = 8,  drawable = 22,  texture = 4 },
            { component = 10, drawable = 0,   texture = 0 },
            { component = 11, drawable = 21,  texture = 3 },
        }
    },

    -- TOP 5 Mikhayla
    {
        model = "mikhayla",
        coords = vec4(-761.4091, -1335.6803, 5.6593, 321.0869),
        renderDistance = 40.0,
        scenario = "WORLD_HUMAN_AA_SMOKE",
        outfit = {
            { component = 2,  drawable = 0, texture = 0 },
            { component = 3,  drawable = 5, texture = 0 },
            { component = 4,  drawable = 0, texture = 0 },
            { component = 5,  drawable = 2, texture = 0 },
            { component = 6,  drawable = 6, texture = 0 },
            { component = 8,  drawable = 1, texture = 0 },
            { component = 11, drawable = 15, texture = 0 },
        }
    },

    -- TOP 6 Angga Black
    {
        model = "ig_aw_male",
        coords = vec4(-763.4880, -1334.0499, 5.6593, 319.0726),
        renderDistance = 40.0,
        scenario = "WORLD_HUMAN_AA_COFFEE",
        outfit = {
            { component = 2,  drawable = 0, texture = 0 },
            { component = 3,  drawable = 1, texture = 0 },
            { component = 4,  drawable = 14, texture = 0 },
            { component = 6,  drawable = 5, texture = 0 },
            { component = 11, drawable = 17, texture = 0 },
        }
    },



    {
        model = "mp_m_freemode_01",
        coords = vec4(-793.0948, -1320.6278, 6.5219, 260.7874),
        renderDistance = 40.0,
        scenario = "WORLD_HUMAN_GUARD_STAND_CASINO",
        faceData = {
            father = 0,
            mother = 87,
            skinFather = 41,
            skinMother = 42,
            shapeMix = 0.0,
            skinMix = 0.0,
            hair = {
                model = 12,
                color = 61,
                highlight = 0
            },
            eyebrows = {
                model = 12,
                opacity = 1.0
            }
        },
        outfit = {
            { component = 1,  drawable = 5, texture = 0 },
            { component = 2,  drawable = 12, texture = 0 },
            { component = 3,  drawable = 1, texture = 0 },
            { component = 4,  drawable = 77, texture = 5 },
            { component = 5,  drawable = 0, texture = 0 },
            { component = 6,  drawable = 55, texture = 5 },
            { component = 7,  drawable = 510, texture = 1 },
            { component = 8,  drawable = 15, texture = 0 },
            { component = 9,  drawable = 0, texture = 0 },
            { component = 10, drawable = 0, texture = 0 },
            { component = 11, drawable = 178, texture = 5 },
        }
    },

    {
        model = "mp_m_freemode_01",
        coords = vec4(-793.5391, -1322.5887, 5.7954, 260.9868),
        renderDistance = 40.0,
        scenario = "WORLD_HUMAN_GUARD_STAND_CASINO",
        faceData = {
            father = 60,
            mother = 90,
            skinFather = 3,
            skinMother = 0,
            shapeMix = 0.0,
            skinMix = 0.0,
            hair = {
                model = 0,
                color = 0,
                highlight = 0
            },
            eyebrows = {
                model = 0,
                opacity = 0.0
            }
        },
        outfit = {
            { component = 1,  drawable = 307, texture = 0 },
            { component = 2,  drawable = 0, texture = 0 },
            { component = 3,  drawable = 1, texture = 0 },
            { component = 4,  drawable = 77, texture = 5 },
            { component = 5,  drawable = 0, texture = 0 },
            { component = 6,  drawable = 55, texture = 5 },
            { component = 7,  drawable = 510, texture = 1 },
            { component = 8,  drawable = 15, texture = 0 },
            { component = 9,  drawable = 0, texture = 0 },
            { component = 10, drawable = 0, texture = 0 },
            { component = 11, drawable = 178, texture = 5 },
        }
    },

    {
        model = "mp_m_freemode_01",
        coords = vec4(-792.7322, -1318.5188, 5.7954, 258.2446),
        renderDistance = 40.0,
        scenario = "WORLD_HUMAN_GUARD_STAND_CASINO",
        faceData = {
            father = 31,
            mother = 40,
            skinFather = 2,
            skinMother = 0,
            shapeMix = 0.5,
            skinMix = 0.5,
            hair = {
                model = 1073,
                color = 0,
                highlight = 4
            },
            eyebrows = {
                model = 30,
                opacity = 1.0
            }
        },
        outfit = {
            { component = 1,  drawable = 241, texture = 0 },
            { component = 2,  drawable = 1073, texture = 0 },
            { component = 3,  drawable = 1, texture = 0 },
            { component = 4,  drawable = 77, texture = 5 },
            { component = 5,  drawable = 0, texture = 0 },
            { component = 6,  drawable = 55, texture = 5 },
            { component = 7,  drawable = 510, texture = 1 },
            { component = 8,  drawable = 15, texture = 0 },
            { component = 9,  drawable = 0, texture = 0 },
            { component = 10, drawable = 0, texture = 0 },
            { component = 11, drawable = 178, texture = 5 },
        }
    },

    {
        model = "mp_m_freemode_01",
        coords = {
            vec4(4984.1362, -5707.3936, 19.8869, 49.6714),
            vec4(4979.2539, -5713.0601, 19.8869, 48.9476),
            vec4(5008.3467, -5723.1567, 19.4891, 141.4685),
            vec4(5031.9746, -5749.5835, 16.2780, 90.5237),
            vec4(5033.6304, -5769.9653, 15.6777, 307.2238),
            vec4(5041.9014, -5757.1147, 15.6865, 136.5408),
        },
        renderDistance = 40.0,
        faceData = {
            father = 0,
            mother = 21,
            skinFather = 0,
            skinMother = 0,
            shapeMix = 0.5,
            skinMix = 0.5,
            hair = {
                model = 2,
                color = 0,
                highlight = 0
            },
            eyebrows = {
                model = 0,
                opacity = 1.0
            }
        },
        outfit = {
            { component = 1,  drawable = 52, texture = 0 },
            { component = 0,  drawable = 58, texture = 0 },
            { component = 3,  drawable = 42, texture = 0 },
            { component = 4,  drawable = 24, texture = 0 },
            { component = 6,  drawable = 10, texture = 0 },
            { component = 8,  drawable = 35, texture = 0 },
            { component = 11, drawable = 32, texture = 0 },
        },
        onSpawn = function(ped)
            GiveWeaponToPed(ped, GetHashKey("WEAPON_ASSAULTRIFLE"), 999, false, true)
            SetCurrentPedWeapon(ped, GetHashKey("WEAPON_ASSAULTRIFLE"), true)
            TaskStartScenarioInPlace(ped, "WORLD_HUMAN_GUARD_STAND_ARMY", 0, false)
        end,
    },

}

