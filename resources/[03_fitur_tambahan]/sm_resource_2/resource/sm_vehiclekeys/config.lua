return {
    lockKey = 'L',
    engineKey = 'G',
    hotwireKey = 'H',
    lockDistance = 8.0,
    giveDistance = 3.0,
    claimDistance = 30.0,

    lockAnim = {
        dict = 'anim@mp_player_intmenu@key_fob@',
        clip = 'fob_click',
        prop = 'prop_cuff_keys_01',
        bone = 57005,
        duration = 1200,
    },

    lockNpcDriving = true,
    lockNpcParked = true,

    lockpick = {
        reps = { 2, 4 },
        distance = 2.5,
        grantSeconds = 60,
        breakChance = {
            lockpick = 0.5,
            advancedlockpick = 0.2,
        },
    },

    takeKeysDuration = 2500,

    hotwire = {
        chance = 0.5,
        cooldown = 5000,
        minTime = 20000,
        maxTime = 40000,
        blockedTypes = { heli = true },
    },

    carjack = {
        enabled = true,
        duration = 7500,
        cooldown = 10000,
        distance = 5.0,
        fallbackChance = 0.5,
        chance = {
            ['2685387236'] = 0.0,
            ['416676503'] = 0.5,
            ['-957766203'] = 0.75,
            ['860033945'] = 0.90,
            ['970310034'] = 0.90,
            ['1159398588'] = 0.99,
            ['3082541095'] = 0.99,
            ['2725924767'] = 0.99,
            ['1548507267'] = 0.0,
            ['4257178988'] = 0.0,
        },
        blockedWeapons = {
            'WEAPON_UNARMED', 'WEAPON_KNIFE', 'WEAPON_NIGHTSTICK', 'WEAPON_HAMMER', 'WEAPON_BAT',
            'WEAPON_CROWBAR', 'WEAPON_GOLFCLUB', 'WEAPON_BOTTLE', 'WEAPON_DAGGER', 'WEAPON_HATCHET',
            'WEAPON_KNUCKLE', 'WEAPON_MACHETE', 'WEAPON_FLASHLIGHT', 'WEAPON_SWITCHBLADE', 'WEAPON_POOLCUE',
            'WEAPON_WRENCH', 'WEAPON_BATTLEAXE', 'WEAPON_GRENADE', 'WEAPON_STICKYBOMB', 'WEAPON_PROXMINE',
            'WEAPON_BZGAS', 'WEAPON_MOLOTOV', 'WEAPON_FIREEXTINGUISHER', 'WEAPON_PETROLCAN', 'WEAPON_FLARE',
            'WEAPON_BALL', 'WEAPON_SNOWBALL', 'WEAPON_SMOKEGRENADE',
        },
    },

    sharedKeys = {
        police = { requireOnduty = false, models = { 'police', 'police2' } },
        mechanic = { requireOnduty = false, models = { 'towtruck' } },
    },

    immuneModels = { 'stockade' },
    noLockModels = {},
    noLockClasses = { [13] = true },
}
