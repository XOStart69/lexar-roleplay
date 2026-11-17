---@class DispatchConfig
local Config = {}

Config.Debug = false

Config.Locale = 'en'

Config.Controls = {
    callManager = 'U',
    toggleMoveMode = 'I',
    sidebar = 'PERIOD',
    toggleFocus = 'LMENU',
    panicButton = 'O',
    calls = {
        next = 'LEFT',
        previous = 'RIGHT',
        accept = 'UP',
    },
}

Config.MaxStoredCalls = 50

Config.DefaultRemoveTime = 1000 * 60 * 5

Config.RemoveCallFromEveryone = true
Config.AttachAllUnitsInGroupToCall = false
Config.AttachAllUnitsInVehicleToCall = false

Config.NotificationPosition = { x = 74, y = 78 }

Config.CallManagerPosition = { x = 1, y = 45 }
Config.CallManagerSize = { width = 24 }

Config.Dispatch = {
    police = {
        jobs = {
            police = true,
            badsidehandler = true,
        },
        permissions = {
            dispatcher = {
                police = 4,
            },
        },
        panicButton = true,
        pages = {
            sidebar = true,
            callManager = true,
            notification = true,
        },
    },
    ems = {
        jobs = {
            ambulance = true,
            rsroxwood = true,
            banmeskota = true,
        },
        panicButton = true,
        pages = {
            sidebar = true,
            callManager = true,
            notification = true,
        },
    },
    usmarshal = {
        jobs = {
            usmarshal = true,
            pengadilan = true,
        },
        permissions = {
            dispatcher = {
                usmarshal = 4,
                pengadilan = 4,
            },
        },
        panicButton = true,
        pages = {
            sidebar = true,
            callManager = true,
            notification = true,
        },
    },
    government = {
        jobs = {
            government = true,
            paspampres = true,
        },
        permissions = {
            panicButton = {
                government = 12,
            },
        },
        panicButton = true,
        pages = {
            sidebar = false,
            callManager = false,
            notification = true,
        },
    },
    mercenary = {
        jobs = {
            mercenarysm = true,
        },
        panicButton = false,
        pages = {
            sidebar = false,
            callManager = false,
            notification = true,
        },
    },
}

Config.Alerts = {
    shooting = {
        enable = true,
        jobs = { 'police', 'badsidehandler', 'usmarshal' },
        hiddenJobs = { pengadilan = true },
        ignoredJobs = {
            police = true,
            badsidehandler = true,
            mercenarysm = true,
            usmarshal = true,
            pengadilan = false,
        },
        cooldown = 35000,
        checkForSuppressor = true,
        nearbyPed = {
            enable = false,
            needLos = false,
            dist = 100,
            anim = {
                dict = 'cellphone@',
                name = 'cellphone_text_read_base',
                prop = {
                    model = `prop_npc_phone_02`,
                    bone = 28422,
                    pos = vec3(0.0, 0.0, 0.0),
                    rot = vec3(0.0, 0.0, 0.0),
                },
                duration = 5000,
            },
        },
        platePercentage = { min = 25, max = 100 },
        coordsOffset = 20,
        chance = 30,
    },
    gunSeen = {
        enable = false,
        jobs = { 'police' },
        ignoredJobs = { police = true },
        cooldown = 15000,
        checkForSuppressor = false,
        nearbyPed = {
            enable = true,
            needLos = true,
            dist = 50,
            anim = {
                dict = 'cellphone@',
                name = 'cellphone_text_read_base',
                prop = {
                    model = `prop_npc_phone_02`,
                    bone = 28422,
                    pos = vec3(0.0, 0.0, 0.0),
                    rot = vec3(0.0, 0.0, 0.0),
                },
                duration = 5000,
            },
        },
        platePercentage = { min = 25, max = 100 },
        coordsOffset = 20,
    },
    speeding = {
        enable = false,
        jobs = { 'police' },
        ignoredJobs = {
            police = true,
            ambulance = true,
        },
        cooldown = 15000,
        locations = {
            { coords = vec3(100.78, -1016.51, 29.41), radius = 20.0, minSpeed = 25 },
        },
        platePercentage = { min = 25, max = 100 },
    },
    vehStealing = {
        enable = false,
        jobs = { 'police' },
        ignoredJobs = { police = true },
        cooldown = 15000,
        platePercentage = { min = 25, max = 100 },
    },
    fighting = {
        enable = false,
        jobs = { 'police' },
        ignoredJobs = { police = true },
        cooldown = 15000,
        nearbyPed = {
            enable = true,
            needLos = true,
            dist = 100,
            anim = {
                dict = 'cellphone@',
                name = 'cellphone_text_read_base',
                prop = {
                    model = `prop_npc_phone_02`,
                    bone = 28422,
                    pos = vec3(0.0, 0.0, 0.0),
                    rot = vec3(0.0, 0.0, 0.0),
                },
                duration = 5000,
            },
        },
        coordsOffset = 20,
    },
    injuredPerson = {
        enable = false,
        jobs = { 'ambulance', 'banmeskota' },
        cooldown = 60000,
        nearbyPed = {
            enable = true,
            needLos = true,
            dist = 50,
            anim = {
                dict = 'cellphone@',
                name = 'cellphone_text_read_base',
                prop = {
                    model = `prop_npc_phone_02`,
                    bone = 28422,
                    pos = vec3(0.0, 0.0, 0.0),
                    rot = vec3(0.0, 0.0, 0.0),
                },
                duration = 5000,
            },
        },
    },
    panicButton = {
        enable = true,
        cooldown = 15000,
        anim = {
            dict = 'random@arrests',
            name = 'generic_radio_chatter',
        },
        playSound = true,
        playSoundAll = true,
    },
    call = {
        enable = true,
        cooldown = 60000,
        removeTime = 1000 * 60 * 5,
        maxLength = 150,
        notifyDuration = 12000,
        emote = 'phonecall',
        emoteDuration = 8000,
        blip = { color = 1, sprite = 58, scale = 1.0, flash = true, radius = 60.0 },

        services = {
            { value = 'police', label = 'Police', jobs = { 'police' }, sound = 'beepwarning' },
            { value = 'ambulance', label = 'EMS', jobs = { 'ambulance' } },
        },
    },
}

Config.BlacklistedWeapons = {
    [`WEAPON_SNIPERRIFLE`] = true,
    [`WEAPON_FIREWORKSINGLE`] = true,
    [`WEAPON_FIREWORK`] = true,
    [`WEAPON_STUNGUN`] = true,
    [`WEAPON_BALL`] = true,
    [`WEAPON_SNOWBALL`] = true,
    [`WEAPON_FLARE`] = true,
    [`WEAPON_SMOKEGRENADE`] = true,
    [`WEAPON_BZGAS`] = true,
    [`WEAPON_FIREEXTINGUISHER`] = true,
    [`WEAPON_JERRYCAN`] = true,
    [`WEAPON_HAZARDCAN`] = true,
    [`WEAPON_FERTILIZERCAN`] = true,
}

Config.SkipAlertResources = {
    { resource = 'pug-paintball', export = 'IsInPaintball' },
    { resource = 'pug-battleroyale', export = 'IsInBattleRoyale' },
}

return Config
