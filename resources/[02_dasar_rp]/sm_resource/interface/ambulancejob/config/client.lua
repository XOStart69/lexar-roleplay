return {
    eventMode = false,
    eventHint = 'untuk magic revive',
    eventCommand = '/helpme',

    deathTime = 1800,
    billCost = 50000,
    fastSpawn = vector4(1150.6968, -1525.7926, 34.8435, 347.6865),
    respawnAtNearestHospital = true,
    painkillerInterval = 60,
    clearInventoryOnDisconnect = true,

    anim = {
        bed_sleep = {
            dict = 'anim@gangops@morgue@table@',
            clip = 'body_search'
        },
        bed_leave = {
            dict = 'switch@franklin@bed',
            clip = 'sleep_getup_rubeyes'
        },
        death = {
            dict = 'dead',
            clip = 'dead_a'
        },
        death_vehicle = {
            dict = 'veh@low@front_ps@idle_duck',
            clip = 'sit'
        },
        revive = {
            dict = 'timetable@amanda@drunk@base',
            clip = 'base'
        },
        heal = {
            dict = 'mini@cpr@char_a@cpr_str',
            clip = 'cpr_pumpchest'
        },
        bandage = {
            dict = 'emergency1@bandagearm@clip',
            clip = 'bandagearm_clip',
            prop = {
                model = `bandage2`,
                bone = 28252,
                pos = vec3(-0.233, -0.016, 0.203),
                rot = vec3(0.0, 100.0, 0.0)
            }
        },
    },

    walkstyle = {
        injured = 'move_m@injured',
        lester = 'move_heist_lester'
    },

    anticombat = {
        cooldownTime = 900,
        whitelistedWeapons = {
            `weapon_machete`,
            `weapon_wrench`,
            `weapon_crowbar`,
            `weapon_sledgehammer`,
            `weapon_hatchet`,
            `weapon_flashlight`,
            `weapon_nightstick`,
            `weapon_stungun`,
        }
    },

    medicalJobs = {
        ambulance = true,
        banmeskota = true,
        puskesmas = true,
        rsroxwood = true,
    },

    jobItems = {
        ambulance = 'firstaid',
        banmeskota = 'firstaid',
        puskesmas = 'firstaidblue',
        rsroxwood = 'medkit',
    },

    garageNames = {
        ambulance = { vehicle = 'Garage Ambulance', helicopter = 'Hangar Helikopter' },
        banmeskota = { vehicle = 'Garage Banmeskota', helicopter = 'Hangar Banmeskota' },
        puskesmas = { vehicle = 'Garage Puskesmas', helicopter = 'Hangar Puskesmas' },
        rsroxwood = { vehicle = 'Garage RSRoxwood', helicopter = 'Hangar RSRoxwood' },
    },
}
