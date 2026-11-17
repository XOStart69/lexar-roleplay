ECUConfig = {}

ECUConfig.ModifyHandling = true
ECUConfig.EnableDrift = false
ECUConfig.EnableAntiLag = false

ECUConfig.Language = 'en'

ECUConfig.AccessMode = 'all'
ECUConfig.InstallMode = 'all'
ECUConfig.ShopAccess = 'mechanic'

ECUConfig.MechanicCheck = 'job'
ECUConfig.MechanicJobs = { 'remapecu' }
ECUConfig.MechanicAce = 'ecutune.mechanic'
ECUConfig.AdminAce = 'ecutune.admin'

ECUConfig.EngineVolume = {
    enabled = true,
    stages = { 100, 200, 300 },
    adminMax = 4400,
    hearCommand = 'loudcars',
    closed = -30,
    key = 'H',
    sound = 'valve.ogg',
    soundVol = 0.8,
}

ECUConfig.EngineVolumeLevels = { 50, 100, 150, 200, 250, 300, 700, 1500, 3100, 4400 }

---@param pct number
---@return number value
---@return number index
function HRS_EngVolSnap(pct)
    pct = tonumber(pct) or 0
    if pct <= 0 then return 0, 0 end
    local levels = ECUConfig.EngineVolumeLevels
    local best, bi, bd = 0, 0, math.huge
    for i = 1, #levels do
        local d = math.abs(levels[i] - pct)
        if d < bd then best, bi, bd = levels[i], i, d end
    end
    return best, bi
end

ECUConfig.MechanicOnly = {
    customMap = false,
    stage3 = false,
    mapSwitch = false,
}

ECUConfig.FreeInstallJobs = {
    ['admin'] = true,
}

ECUConfig.TuningSpots = {
    job = 'remapecu',
    radius = 3.0,
    locations = {
        vec3(-45.3052, 8068.6577, 6.3343),
        vec3(-53.0642, 8066.6816, 6.3342),
        vec3(-56.3006, 8090.0610, 6.3342),
        vec3(-48.9179, 8091.8872, 6.3342),
        vec3(-41.5501, 8093.9976, 6.3342),
        vec3(-33.7786, 8095.9663, 6.3343),
    },
}

ECUConfig.SpeedBoost = {
    enabled = true,
    skipItems = false,
    adminFactor = 10.0,
    jobs = {
        ['mechanic'] = 2.0,
    },
}

ECUConfig.RequireOBD = true
ECUConfig.OBDItem = 'obdadapter'
ECUConfig.HudNeedsOBD = true
ECUConfig.RepairItem = 'ecurepair'

ECUConfig.Tools = {
    { item = 'ecurepair', label = 'ECU Repair Kit', price = 1500000 },
}

ECUConfig.Payment = { 'cash', 'bank' }

ECUConfig.RegisteredOnly = true

ECUConfig.BlacklistVehicles = {}
ECUConfig.BlacklistClasses = { 18 }
ECUConfig.AllowedClasses = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 17, 19, 20, 22 }
ECUConfig.AllowedTypes = { automobile = true, bike = true }

ECUConfig.DefaultRedline = 7800
ECUConfig.DynoForceFactor = 1850
ECUConfig.DynoOverride = {}

ECUConfig.Parts = {
    downpipe = {
        label       = 'Downpipe',
        item        = 'ecu_downpipe',
        category    = 'hw',
        boost       = 4,
        price       = 950000,
        installTime = 20000,
        failChance  = 0.12,
        breakItem   = true,
    },
    straightpipe = {
        label       = 'Straight Pipe',
        item        = 'ecu_straightpipe',
        category    = 'hw',
        boost       = 1,
        price       = 800000,
        installTime = 20000,
        failChance  = 0.0,
    },
    endschalldaempfer = {
        label       = 'Rear Muffler',
        item        = 'ecu_muffler',
        category    = 'hw',
        boost       = 0,
        unlocks     = 'megaflamme',
        requiresAny = { 'ecustage1', 'ecustage2', 'ecustage3' },
        price       = 500000,
        installTime = 20000,
        failChance  = 0.0,
    },
    ladeluftkuehler = {
        label       = 'Intercooler',
        item        = 'ecu_intercooler',
        category    = 'hw',
        boost       = 2,
        price       = 650000,
        installTime = 20000,
        failChance  = 0.0,
    },
    airfilter = {
        label       = 'Air Filter',
        item        = 'ecu_airfilter',
        category    = 'hw',
        boost       = 2,
        price       = 500000,
        installTime = 20000,
        failChance  = 0.0,
    },
    turbo = {
        label       = 'Turbo Upgrade',
        item        = 'ecu_turbo',
        category    = 'hw',
        boost       = 9,
        requires    = { 'downpipe' },
        price       = 1000000,
        installTime = 20000,
        failChance  = 0.15,
        breakItem   = true,
    },
    mapswitch = {
        label       = 'Map Switch',
        noItem      = true,
        desc        = 'Three profiles per vehicle. Switch with F5.',
        category    = 'ecu',
        boost       = 0,
        price       = 25000,
        installTime = 8000,
        failChance  = 0.0,
        isECU       = true,
    },

    exhaustvalve = {
        label       = 'Valve Control',
        noItem      = true,
        hidden      = true,
        desc        = 'Exhaust valve: louder engine, open and close with H.',
        category    = 'ecu',
        boost       = 0,
        price       = 650000,
        installTime = 6000,
        failChance  = 0.0,
        isECU       = true,
    },

    ecustage1 = {
        label       = 'ECU Stage 1',
        item        = 'ecu_stage1',
        category    = 'ecu',
        boost       = 3,
        unlocks     = 'popbang',
        price       = 500000,
        installTime = 30000,
        isECU       = true,
        failChance  = 0.10,
    },
    ecustage2 = {
        label       = 'ECU Stage 2',
        item        = 'ecu_stage2',
        category    = 'ecu',
        boost       = 5,
        unlocks     = 'popbang_aggressiv',
        requires    = { 'downpipe' },
        replaces    = { 'ecustage1' },
        price       = 600000,
        installTime = 30000,
        isECU       = true,
        failChance  = 0.10,
    },
    ecustage3 = {
        label       = 'ECU Stage 3',
        item        = 'ecu_stage3',
        category    = 'ecu',
        boost       = 6,
        requires    = { 'downpipe', 'straightpipe', 'turbo' },
        replaces    = { 'ecustage1', 'ecustage2' },
        price       = 750000,
        installTime = 30000,
        isECU       = true,
        failChance  = 0.10,
    },
    getriebeflash = {
        label       = 'Gearbox Flash',
        item        = 'ecu_gearflash',
        category    = 'ecu',
        boost       = 0,
        unlocks     = 'schaltpop',
        price       = 750000,
        installTime = 30000,
        isECU       = true,
        failChance  = 0.08,
    },
    driftflash = {
        label       = 'Differential-Flash',
        item        = 'ecu_driftflash',
        category    = 'ecu',
        boost       = 0,
        unlocks     = 'drift',
        price       = 11000,
        installTime = 30000,
        isECU       = true,
        failChance  = 0.08,
    },
    antilagflash = {
        label       = 'Anti-Lag-Flash',
        item        = 'ecu_antilagflash',
        category    = 'ecu',
        boost       = 0,
        unlocks     = 'antilag',
        price       = 13000,
        installTime = 30000,
        isECU       = true,
        failChance  = 0.08,
    },
}

ECUConfig.ShopOrder = {
    'downpipe', 'straightpipe', 'endschalldaempfer',
    'ladeluftkuehler', 'airfilter', 'turbo',
    'ecustage1', 'ecustage2', 'ecustage3', 'getriebeflash', 'driftflash', 'antilagflash',
}

ECUConfig.RequirePartsForFeatures = true

ECUConfig.FeatureUnlocks = {
    popbang            = { all = { 'ecustage1OrHigher' } },
    popbang_aggressiv  = { all = { 'downpipe', 'ecustage2OrHigher' } },
    schaltpop          = { all = { 'getriebeflash' } },
    megaflamme         = { all = { 'endschalldaempfer' } },
    flammenwerfer      = { all = { 'downpipe', 'straightpipe', 'ecustage3' } },
    drift              = { all = { 'driftflash' } },
    antilag            = { all = { 'antilagflash' } },
}

ECUConfig.ECU = {
    rpmMin        = 30,
    rpmMax        = 95,
    popDuration   = 200,
    popsStage     = 2,
    standPops     = false,
    schaltPop     = false,
    megaFlameMode = 0,
    flammenwerfer = {
        enabled     = false,
        rpmMin      = 70,
        rpmMax      = 99,
        duration    = 300,
        standFlamme = false,
        knall       = false,
        gluehen     = false,
        random      = false,
        randomPreset = 'aggressiv',
    },
}

ECUConfig.MaxPressure = 25.0

ECUConfig.MenuFlashTime = 15000

ECUConfig.FlashLimit = 15

ECUConfig.BrickEngineOnFail = true

ECUConfig.SmokeOnHardwareFail = true

ECUConfig.RemoveTime = 8000

ECUConfig.Boot = {
    enabled = false,

    speed   = 100,

    firstDuration  = 10000,
    replayDuration = 1500,
    tablet  = true,
    hood    = true,
    cancel  = true,

    reach   = 5.0,

    animDict  = 'amb@world_human_tourist_map@male@base',
    animName  = 'base',

    propModel    = 'prop_cs_tablet',
    propBone     = 28422,
    propOffset   = vector3(0.03, 0.00, -0.03),
    propRotation = vector3(20.0, 160.0, 0.0),
}

ECUConfig.HudMode = 'always'

ECUConfig.HudToggleDuration = 5000

ECUConfig.HudDebug = false

ECUConfig.ShopLocations = {
    { x = -37.7856,   y = 8065.1948, z =  6.3346, h = 193.0167 },
}

ECUConfig.ShopBlip = {
    enabled    = false,
    sprite     = 446,
    color      = 5,
    scale      = 0.95,
    alpha      = 255,
    shortRange = false,
    name       = 'ECU Tuning Shop',
}

ECUConfig.ShopInteractDistance = 2.0
ECUConfig.ShopMaxDistance = 6.0

ECUConfig.ShopSociety = {
    account = 'remapecu',
    share = 0.4,
}

ECUConfig.PopsToggleKey = 'F9'

ECUConfig.MapSwitchKey    = 'F5'

ECUConfig.AntiLagKeyboard = 'F4'

ECUConfig.AntiLagController       = false

ECUConfig.AntiLagControllerButton = 'GAMEPAD_DPAD_DOWN'

ECUConfig.DriftKey = 19

ECUConfig.SearchKey = ''

ECUConfig.PopsStages = {
    [1] = { flameSize = 1.0, probability = 0.45, soundCount = 1, explosionChance = 0.40, rpmMin = 30, rpmMax = 75, popDuration = 350 },
    [2] = { flameSize = 1.2, probability = 0.70, soundCount = 1, explosionChance = 0.55, rpmMin = 30, rpmMax = 95, popDuration = 200 },
    [3] = { flameSize = 1.3, probability = 0.80, soundCount = 1, explosionChance = 0.95, rpmMin = 40, rpmMax = 99, popDuration = 100 },
}

ECUConfig.FlameThresholds = {
    NoAction   = 0.3,
    JustSound  = 0.8,
    SmallFlame = 1.5,
}

ECUConfig.FlameVariation = 50

ECUConfig.MegaFlameMultiplier = 1.0

ECUConfig.PopBurstMs  = 60

ECUConfig.PopHardStop = false

ECUConfig.PopUseBoneAttach = false

ECUConfig.PopFlameFollowExhaustAngle = true

ECUConfig.PopFlameAngleOffset = { x = 0.0, y = 0.0, z = 0.0 }

ECUConfig.Particles = {
    Small   = { { Library = "core", Name = "veh_sm_car_small_backfire" } },
    Large   = { { Library = "core", Name = "veh_backfire" } },
    Mega    = { { Library = "core", Name = "veh_backfire" } },
    Nitrous = { { Library = "core", Name = "veh_nitrous" } },
}

ECUConfig.DefaultFlamePacks = { 'standard' }

ECUConfig.FlamePacks = {
    standard = {
        label   = 'Standard',
        library = 'core',
        name    = 'veh_backfire',
        scale   = 1.0,
    },
    auto = {
        label = 'Auto',
    },
    small = {
        label   = 'Subtle',
        library = 'core',
        name    = 'veh_sm_car_small_backfire',
        scale   = 1.1,
    },
    sanctus = {
        label   = 'Sanctus',
        library = 'veh_sanctus',
        name    = 'veh_sanctus_backfire',
        scale   = 1.0,
    },
    r35 = {
        label   = 'Bang',
        library = 'hrs_r35',
        name    = 'hrs_r35_knall',
        scale   = 0.7,
        scaleRandom = { 0.8, 1.2 },
        boneAttach = true,
        burstMs    = { 50, 110 },
        rotJitter  = { 6.0, 6.0, 8.0 },
    },
    stich = {
        label   = 'Jet Flame',
        library = 'hrs_r35',
        name    = 'hrs_r35_stich',
        scale   = 0.85,
        scaleRandom = { 0.85, 1.15 },
        boneAttach = true,
        burstMs    = { 120, 220 },
        rotJitter  = { 4.0, 4.0, 7.0 },
    },
    riesen = {
        label   = 'Giant Pop',
        library = 'hrs_r35',
        name    = 'hrs_r35_riesen',
        scale   = 0.9,
        scaleRandom = { 0.85, 1.25 },
        boneAttach = true,
        burstMs    = { 90, 180 },
        rotJitter  = { 8.0, 8.0, 10.0 },
    },
    glut = {
        label    = 'Afterglow',
        library  = 'core',
        name     = 'fire_wrecked_car',
        scale    = 0.4,
        addon    = true,
        chance   = 0.3,
        delay    = 120,
        duration = 650,
    },
}

ECUConfig.FlamePackOrder = { 'standard', 'auto', 'small', 'sanctus', 'r35', 'stich', 'riesen', 'glut' }

ECUConfig.AddonPop = {
    file        = 'sounds/popsound.ogg',
    volume      = 0.6,
    maxDistance = 60.0,
}

ECUConfig.AddonPops = {
    { key = 'pop1', file = 'sounds/popsound.ogg', label = 'Pop 1' },
}

ECUConfig.AddonPopLimits = {
    rpmMin = 0,  rpmMax = 100,
}

ECUConfig.AddonPopFlame     = true

ECUConfig.AddonPopFlameSize = 1.3

ECUConfig.CalmNPCRadius  = 40.0

ECUConfig.CalmNPCRefresh = 15000

ECUConfig.DefaultNitroColor = 'standard'

ECUConfig.NitroColors = {
    standard = { label = 'Standard', asset = 'hrs_flame_standard', name = 'hrsnx_cl3t3' },

    ncolor1  = { label = 'Blue',      asset = 'hrs_flame_blue',    name = 'hrsnx_8l80d' },
    ncolor2  = { label = 'Purple',      asset = 'hrs_flame_purple',  name = 'hrsnx_upa2h' },
    ncolor3  = { label = 'Green',      asset = 'hrs_flame_green',   name = 'hrsnx_p5t55' },
    ncolor4  = { label = 'Red',       asset = 'hrs_flame_red',     name = 'hrsnx_pd3pr' },
    ncolor5  = { label = 'Yellow',      asset = 'hrs_flame_yellow',  name = 'hrsnx_6jh4g' },
    ncolor6  = { label = 'Lime',   asset = 'hrs_flame_lime',    name = 'hrsnx_ytc44' },
    ncolor7  = { label = 'Cyan',    asset = 'hrs_flame_cyan',    name = 'hrsnx_4lq8k' },

    ncolor8  = { label = 'Orange',    asset = 'hrs_flame_orange',  name = 'hrsnx_swgxm' },
    ncolor9  = { label = 'Pink',      asset = 'hrs_flame_pink',    name = 'hrsnx_xp7u5' },
    ncolor10 = { label = 'White',      asset = 'hrs_flame_white',   name = 'hrsnx_ofd4c' },
    ncolor11 = { label = 'Ice blue',   asset = 'hrs_flame_ice',     name = 'hrsnx_nuih4' },

    ncolor15 = { label = 'Blue · Purple',   asset = 'hrs_flame_blue_purple',  name = 'hrsnx_mmvxy' },
    ncolor16 = { label = 'Fire',         asset = 'hrs_flame_red_yellow',   name = 'hrsnx_cbfh2' },
    ncolor17 = { label = 'Cyan · White', asset = 'hrs_flame_cyan_white',   name = 'hrsnx_ymo9v' },
    ncolor18 = { label = 'Green · Yellow',   asset = 'hrs_flame_green_yellow', name = 'hrsnx_zjg5v' },
    ncolor19 = { label = 'Pink · Blue',   asset = 'hrs_flame_pink_blue',    name = 'hrsnx_61l10' },
    ncolor20 = { label = 'Orange · Blue', asset = 'hrs_flame_orange_blue',  name = 'hrsnx_obz11' },

    ncolor21 = {
        label = 'GTR R35', asset = 'hrs_r35', name = 'hrs_r35_loop',
        scaleRandom = { 0.8, 1.25 },
        rotJitter   = { 4.0, 4.0, 6.0 },
        wobble      = { scale = 0.20, rot = 2.5, speed = 0.8, surge = 0.9 },
    },
}

ECUConfig.NitroCustomColor = {
    enabled = false,
    asset   = 'hrs_flame_white',
    name    = 'hrsnx_ofd4c',
    default = { r = 1.0, g = 0.45, b = 0.08 },
}

ECUConfig.NitroColorOrder = {
    'standard',
    'ncolor1', 'ncolor11', 'ncolor7', 'ncolor2', 'ncolor9',
    'ncolor4', 'ncolor8', 'ncolor5', 'ncolor6', 'ncolor3', 'ncolor10',
    'ncolor16', 'ncolor15', 'ncolor17', 'ncolor18', 'ncolor19', 'ncolor20', 'ncolor21',
}

ECUConfig.NitroConflictAssets = {
    'veh_xs_vehicle_mods',
}

ECUConfig.NitroScanAssets = {
    'nitrous', 'nitro', 'veh_nitrous', 'scr_nitrous', 'scr_veh_nitrous',
    'veh_xs_vehicle_mods_nitro', 'nd_nitro', 'nitrous_colors',
}

ECUConfig.FlameRandom = {
    refRedline  = 9000,

    fastPopsAbove = 8000,
    flickerFrom   = 8000,  flickerTo = 6500,
    longFrom      = 5000,  longTo    = 4000,
    slowPopsDown  = 3000,

    popFast     = { 150, 180 },
    popSlow     = { 180, 230 },

    short       = { 80, 140 },
    gap         = { 180, 320 },

    quietBefore = 150,

    popPacks    = { 'standard', 'small' },
}

ECUConfig.FlameRandomPresets = {
    aggressiv = {
        label = 'Aggressive',
    },
    extrem = {
        label = 'Extreme',
        flickerFrom = 8500,  flickerTo = 6000,
        longFrom    = 5500,  longTo    = 3800,
        slowPopsDown = 2500,
        popFast     = { 95, 125 },
        popSlow     = { 130, 170 },
        short       = { 100, 170 },
        gap         = { 130, 230 },
    },
    dezent = {
        label = 'Subtle',
        fastPopsAbove = 8500,
        flickerFrom = 7800,  flickerTo = 7000,
        longFrom    = 4800,  longTo    = 4300,
        slowPopsDown = 3300,
        popFast     = { 260, 330 },
        popSlow     = { 320, 420 },
        short       = { 60, 100 },
        gap         = { 320, 480 },
    },
}

ECUConfig.FlameRandomPresetOrder = { 'aggressiv', 'extrem', 'dezent' }

ECUConfig.PopSounds = {
    'zr350_exhaust_pops', 'calico_exhaust_pops', 'comet6_exhaust_pops',
    'cypher_exhaust_pops', 'dominator7_exhaust_pops', 'futo2_exhaust_pops',
    'jester4_exhaust_pops', 'remus_exhaust_pops', 'rt3000_exhaust_pops',
    'tailgater2_exhaust_pops', 'tuner_hatch01_exhaust_pops',
    'tuner_hatch02_exhaust_pops', 'tuner_hatch03_exhaust_pops',
    'tuner_hatch04_exhaust_pops', 'tuner_muscle01_exhaust_pops',
    'vectre_exhaust_pops', 'warrener2_exhaust_pops',
    'calico_exhaust_pops_upgrade', 'comet6_exhaust_pops_upgrade',
    'cypher_exhaust_pops_upgraded', 'dominator7_exhaust_pops_upgrade',
    'jester4_exhaust_pops_upgrade', 'remus_exhaust_pops_upgraded',
    'rt3000_exhaust_pops_upgrade', 'tailgater2_exhaust_pops_upgraded',
    'tuner_hatch02_exhaust_pops_upgraded', 'tuner_hatch03_exhaust_pops_upgrade',
    'tuner_hatch04_exhaust_pops_upgraded', 'vectre_exhaust_pops_upgrade',
    'zr350_exhaust_pops_upgraded', 'cypher_limiter_pops', 'remus_limiter_pops',
    'tailgater2_limiter_pops', 'tuner_hatch02_limiter_pops',
    'tuner_hatch04_limiter_pops', 'tuner_muscle01_limiter_pops',
    'vectre_limiter_pops', 'warrener2_limiter_pops',
    'rt3000_upgraded_limiter_pops', 'tuner_hatch03_upgraded_limiter_pops',
}

ECUConfig.NetworkSound = true

ECUConfig.ExhaustSounds = {
    { key = 'bumm_tief', label = 'Deep Boom', files = {
        'sounds/bumm_tief_1.wav', 'sounds/bumm_tief_2.wav', 'sounds/bumm_tief_3.wav',
    } },
    { key = 'bumm_hart', label = 'Hard Boom', files = {
        'sounds/bumm_hart_1.wav', 'sounds/bumm_hart_2.wav', 'sounds/bumm_hart_3.wav',
    } },
    { key = 'bumm_dumpf', label = 'Dull Boom', files = {
        'sounds/bumm_dumpf_1.wav', 'sounds/bumm_dumpf_2.wav', 'sounds/bumm_dumpf_3.wav',
    } },
    { key = 'pop1', file = 'sounds/pop1.ogg', label = 'Pop 1' },
    { key = 'pop2', file = 'sounds/pop2.ogg', label = 'Pop 2' },
    { key = 'pop3', file = 'sounds/pop3.ogg', label = 'Pop 3' },
}

ECUConfig.ExhaustSoundVolume  = 0.7

ECUConfig.ExhaustSoundMaxDist = 60.0

ECUConfig.ShiftSounds = {
    { key = 'dsg1', file = 'sounds/dsg1.ogg', label = 'DSG 1' },
    { key = 'dsg2', file = 'sounds/dsg2.ogg', label = 'DSG 2' },
    { key = 'dsg3', file = 'sounds/dsg3.ogg', label = 'DSG 3' },
}

ECUConfig.ShiftSoundVolume  = 0.7

ECUConfig.ShiftSoundMaxDist = 45.0

ECUConfig.RemoteSoundVolume = 0.1

ECUConfig.RemoteVolumes = {
    pops  = 0.5,
    shift = 0.25,
}

ECUConfig.PopSyncDistance = 120.0

ECUConfig.Diesel = {
    enabled     = false,
    standSmoke  = true,
    sound       = true,

    color       = 'original',
    alpha       = nil,

    duration    = 500,

    requiresTurbo = true,

    hardcut = {
        enabled     = false,
        rpm         = 0.92,
        interval    = 130,
        minInterval = 100,
        maxInterval = 300,
    },

    offset      = { x = 0.0, y = 0.0, z = 0.0 },

    effect      = { asset = 'core', name = 'ent_amb_generator_smoke', scale = 1.0 },
    spawnPerTick = 2,
    maxParticles = 250,
    tickMs       = 50,
}

ECUConfig.SmokeEffects = {
    { asset = 'core', name = 'ent_amb_generator_smoke', scale = 1.0 },
    { asset = 'core', name = 'veh_exhaust_truck_rig',   scale = 3.0 },
    { asset = 'core', name = 'ent_amb_smoke_general',   scale = 1.0 },
    { asset = 'scr_agencyheistb', name = 'scr_env_agency3b_smoke', scale = 1.0 },
    { asset = 'core', name = 'fire_wrecked_car',        scale = 1.0 },
    { asset = 'core', name = 'exp_grd_grenade_smoke',   scale = 1.0 },
    { asset = 'core', name = 'exp_extinguisher',        scale = 1.0 },
    { asset = 'core', name = 'exp_grd_bzgas_smoke',     scale = 1.0 },
    { asset = 'scr_carsteal4', name = 'scr_carsteal4_wheel_burnout', scale = 1.0 },
}

ECUConfig.SmokeColors = {
    original = { label = 'Original' },
    black    = { label = 'Black',      r = 0.02, g = 0.02, b = 0.02 },
    darkgrey = { label = 'Dark grey',  r = 0.18, g = 0.18, b = 0.20 },
    grey     = { label = 'Grey',       r = 0.45, g = 0.45, b = 0.48 },
    brown    = { label = 'Brown',      r = 0.28, g = 0.18, b = 0.08 },
    white    = { label = 'White',      r = 0.90, g = 0.90, b = 0.92 },
    blue     = { label = 'Blue',       r = 0.10, g = 0.20, b = 0.55 },
}

ECUConfig.SmokeColorOrder = { 'original', 'white', 'grey', 'black' }

ECUConfig.DieselSound = {
    file        = 'sounds/diesel.ogg',
    name        = '',
    set         = '',
    volume      = 0.5,
    maxDistance = 60.0,
    interval    = 900,
}

ECUConfig.TurboSound = {
    enabled     = false,
    pick        = 'turbo1',
    dumpValve   = false,
    spoolTime    = 300,
    liftDebounce = 250,
    liftDelay    = 0,
    dumpAfter   = 200,

    dumpChargeMin = 200,
    dumpChargeMax = 2000,
    dumpVolMin    = 0.30,
    dumpVolMax    = 1.00,
    minRpm      = 30,
    volume      = 0.3,
    volumeMin   = 5,
    volumeMax   = 100,
    maxDistance = 55.0,
    dumpFile    = 'sounds/dumpvalve.ogg',
}

ECUConfig.TurboSounds = {
    { key = 'turbo1', label = 'Turbo 1', file = 'sounds/turbo1.ogg' },
    { key = 'turbo2', label = 'Turbo 2', file = 'sounds/turbo2.ogg' },
    { key = 'turbo3', label = 'Turbo 3', file = 'sounds/turbo3.ogg' },
}

ECUConfig.TurboHeat = {
    allCars      = true,

    stageHeat    = { [0] = 0.45, [1] = 0.75, [2] = 0.90, [3] = 1.00 },

    stockMaxHeat = false,

    enabled      = false,
    showHud      = false,

    ambient      = 30,
    operatingMin = 92,
    operatingMax = 105,

    driftMin      = 92,
    driftMax      = 99,
    driftEverySec = 6,
    driftSpeed    = 0.8,

    settleSeconds = 90,
    popHeatPerSec   = 0.35,
    popHeatDiesel   = 0.25,

    heatPerReliability = 2.0,

    needsRepair  = true,

    repairPrice  = 5000,

    faultCodes = {
        { code = 'P0301', id = 'Misfire silinder 1', en = 'Misfire cylinder 1' },
        { code = 'P0303', id = 'Misfire silinder 3', en = 'Misfire cylinder 3' },
        { code = 'P0304', id = 'Misfire silinder 4', en = 'Misfire cylinder 4' },
        { code = 'P1520', id = 'VANOS intake di luar batas', en = 'VANOS intake out of range' },
        { code = 'P1523', id = 'VANOS exhaust macet', en = 'VANOS exhaust stuck' },
        { code = 'P0087', id = 'Tekanan bensin terlalu rendah', en = 'Fuel rail pressure too low' },
        { code = 'P0234', id = 'Turbo overboost', en = 'Turbo overboost' },
        { code = 'P0128', id = 'Thermostat macet tertutup', en = 'Thermostat stuck closed' },
        { code = 'P0016', id = 'Timing camshaft meleset', en = 'Camshaft timing out of phase' },
        { code = 'P0430', id = 'Katalis overheat', en = 'Catalyst overheated' },
    },

    greenMax     = 115,
    critAt       = 130,
    blowAt       = 140,

    warmUpPerSec = 1.6,
    heatPerSec   = 0.86,
    coolPerSec   = 3.0,

    coolBonusParts = {
        ladeluftkuehler = 0.10,
        airfilter       = 0.05,
    },
    idleCool     = 1.5,
    heatFromRpm  = 55,

    deadTime     = 25000,
    engineHealth = 120.0,
    heatAfterBlow= 105,

    hoodSmoke    = false,
    smokeEffects = {
        { asset = 'core', name = 'exp_extinguisher' },
        { asset = 'core', name = 'ent_amb_smoke_foundry' },
    },
    exhaustEffect = { asset = 'core', name = 'exp_grd_bzgas_smoke' },

    smokeDensity = 120,
    smokeColor   = 'white',
    smokeTime    = 25000,

    linkDyno     = true,
}

ECUConfig.Drift = {
    enabled      = false,
    angle        = 22,
    grip         = 45,
    power        = 190,
    aggression   = 50,
    vmax         = 250,
}

ECUConfig.DriftLimits = {
    angleMin = 10,  angleMax = 60,
    gripMin  = 0,   gripMax  = 100,
    powerMin = 100, powerMax = 200,
    aggrMin  = 0,   aggrMax  = 100,
    vmaxMin  = 50,  vmaxMax  = 250,
}

ECUConfig.DriftClassWhitelist = { 0, 1, 2, 3, 4, 5, 6, 7, 9 }

ECUConfig.AntiLag = {
    rpmLock   = 7000,
    targetPsi = 18,
}

ECUConfig.AntiLagLimits = {
    rpmMin = 4000, rpmMax = 9000,
    psiMin = 5,    psiMax = 30,
}

ECUConfig.AntiLagMaxSpeed = 0

ECUConfig.AntiLagLaunchUpTo = 120

ECUConfig.AntiLagMaxArmTime = 20000

ECUConfig.AntiLagMaxSpeedDrop = 15

ECUConfig.AntiLagBuildTimeMin = 0.7

ECUConfig.AntiLagBuildTimeMax = 2.6

ECUConfig.AntiLagRpmRampPerSec = 2.2

ECUConfig.AntiLagStartRpm = 0.27

ECUConfig.AntiLagPushPerPsi   = 0.16

ECUConfig.AntiLagSpeedPerPsi  = 0.22

ECUConfig.AntiLagBoostHold    = 2500

ECUConfig.AntiLagLaunchBoost  = 0.25

ECUConfig.AntiLagPopInterval  = 200

ECUConfig.AntiLagFlameScale   = 0.75

ECUConfig.SearchHide = {
    enabled  = true,
    rounds   = 3,
    zone     = 16,
    speed    = 1100,
    distance = 12.0,

    reveal   = { [0] = -1, [1] = 3, [2] = 1, [3] = 0 },

    requireItem = 'obdadapter',
}

ECUConfig.SearchDuration = 2500

ECUConfig.ExhaustBones = {
    "exhaust", "exhaust_2", "exhaust_3", "exhaust_4",
}

ECUConfig.MaxBoneCheck = 8

ECUConfig.ExhaustOffset = { x = 0.0, y = 0.0, z = 0.0 }

ECUConfig.ExhaustOffsetByBone = {
}

ECUConfig.ExhaustOffsetByModel = {

}

function HRSVehicleBlocked(model, class)
    if model and model ~= '' then
        local m = string.lower(tostring(model))
        for _, name in ipairs(ECUConfig.BlacklistVehicles or {}) do
            if string.lower(name) == m then return true end
        end
    end
    if class then
        local cl = tonumber(class)
        for _, c in ipairs(ECUConfig.BlacklistClasses or {}) do
            if tonumber(c) == cl then return true end
        end
        local allowed = ECUConfig.AllowedClasses
        if allowed and #allowed > 0 then
            for _, c in ipairs(allowed) do
                if tonumber(c) == cl then return false end
            end
            return true
        end
    end
    return false
end

function HRSPartDisabled(key)
    local keinHandling = ECUConfig.ModifyHandling == false
    if (ECUConfig.EnableDrift   == false or keinHandling) and key == 'driftflash'   then return true end
    if (ECUConfig.EnableAntiLag == false or keinHandling) and key == 'antilagflash' then return true end
    return false
end

ECUConfig.Dyno = {}

ECUConfig.Dyno.Currency      = '$'
ECUConfig.Dyno.PriceBuy      = 150000
ECUConfig.Dyno.PriceRelocate = 50000

ECUConfig.Dyno.MaxDynos = 5

ECUConfig.Dyno.UseFee = {
    enabled = true,
    price   = 2500,
    toOwner = true,
}

ECUConfig.Dyno.Static = {
    enabled = true,

    list = {
        {
            { model = 'hrs_dyno',      x = -32.3592, y = 8076.8696, z = 5.3842, h = 285.4420, isDyno = true },
            { model = 'hrs_dynotable', x = -32.1810, y = 8080.1895, z = 5.3058, h = 285.4420 },
            { model = 'hrs_dynotv',    x = -31.5382, y = 8080.3584, z = 5.3532, h = 285.4420 },
        },
    },
}

ECUConfig.Dyno.MountSnap = {
    enabled = false,
    offset  = vector3(0.0, 0.0, 0.93),
    heading = 0.0,
}

ECUConfig.Dyno.Blip = {
    enabled    = true,
    sprite     = 446,
    color      = 3,
    scale      = 0.75,
    label      = 'Remap Ecu Tuning',
    staticOnly = true,
}

ECUConfig.Dyno.Access = 'all'

ECUConfig.Dyno.Debug = false

ECUConfig.Dyno.UseAccess = 'job'

ECUConfig.Dyno.UseJobs = {
    ['remapecu'] = true,
}

ECUConfig.Dyno.Jobs = {
    ['mechanic'] = true,
    ['tuner']    = true,
}

ECUConfig.Dyno.AdminGroups = {
    ['admin']      = true,
    ['superadmin'] = true,
}

ECUConfig.Dyno.Screen = {
    enabled  = true,
    distance = 40.0,
    brand    = 'SM ECU TUNING',

    targets = {
        { model = 'hrs_dynotv',    mode = 'texture', texture = 'script_rt_tvscreen' },
        { model = 'hrs_dynotable', mode = 'texture',      texture = 'prop_laptop_screen_01a' },
    },

    layout = {
        flipX = false,
        flipY = false,
        zoom  = 1.0,
        offX  = 0,
        offY  = 0,
        bg    = '#0a1622',
    },
}

ECUConfig.Dyno.Props = {
    {
        model     = 'hrs_dyno',
        heading   = 0.0,
        originFix = vector3(0.0, 0.0, 0.0),
        isDyno    = true,
    },
    {
        model     = 'hrs_dynotable',
        heading   = 0.0,
        originFix = vector3(0.0, 0.0, 0.0),
    },
    {
        model     = 'hrs_dynotv',
        heading   = 0.0,
        originFix = vector3(0.0, 0.0, 0.0),
    },
}

ECUConfig.Dyno.PlaceMaxDistance = 25.0
ECUConfig.Dyno.CamSpeed         = 0.35

ECUConfig.Dyno.MountDistance = 4.0

ECUConfig.Dyno.LiftHeight    = 0.01
ECUConfig.Dyno.EngineMode = 'native'

ECUConfig.Dyno.WheelSpeedFactor = 44.1
ECUConfig.Dyno.WheelMinRpm      = 0.25

ECUConfig.Dyno.Rollers = {
    enabled = true,
    model = 'hrs_dyno_roller',
    radius = 0.320,
    fallbackTireRadius = 0.34,
    drawDistance = 80.0,
    minWheelbase = 2.20,
    maxWheelbase = 3.40,
    adjustSpeed = 0.35,
}

ECUConfig.Dyno.EditRange = 15.0

ECUConfig.Dyno.Heat = {
    enabled  = false,
    upRate   = 2.6,
    coolRate = 3.2,
    idleTemp = 60,

    windowMin  = 90,
    windowMax  = 115,
    penaltyMin = 5,
    penaltyMax = 10,
    damageRate = 55.0,
    minHealth  = 120.0,
}

ECUConfig.Dyno.NetRate          = 80

ECUConfig.Dyno.GearCount     = 6

ECUConfig.Dyno.MeasureGear   = 4

ECUConfig.Dyno.RunEndRpm     = 2000

ECUConfig.Dyno.SweepTime     = 6.0
ECUConfig.Dyno.RevSpeed = 1.15

ECUConfig.Dyno.NeutralRevSpeed = 2.5

ECUConfig.Dyno.GearRatios = {
    [1] = { 0.90 },
    [2] = { 3.33, 0.90 },
    [3] = { 3.33, 1.57, 0.90 },
    [4] = { 3.33, 1.83, 1.22, 0.90 },
    [5] = { 3.33, 1.92, 1.36, 1.05, 0.90 },
    [6] = { 3.33, 1.95, 1.39, 1.09, 0.95, 0.90 },
    [7] = { 4.00, 2.34, 1.67, 1.31, 1.14, 1.08, 0.90 },
    [8] = { 4.025, 2.025, 1.523, 1.314, 1.154, 1.073, 1.0, 0.90 },
    [9] = { 7.70, 4.51, 3.22, 2.52, 2.20, 2.08, 1.73, 1.31, 0.90 },
}

ECUConfig.Dyno.ChartBuckets  = 24

ECUConfig.Dyno.LiveWindow    = 8000

ECUConfig.Dyno.ChartRpmMin   = 1000
ECUConfig.Dyno.RevUpRate     = 0.32
ECUConfig.Dyno.RevDownRate   = 0.45

ECUConfig.Dyno.Keys = {
    mount    = 38,
    stop     = 47,
    run      = 311,
    gearUp   = 172,
    gearDown = 173,
}

ECUConfig.Dyno.Fallback = { ps = 150, nm = 200 }

ECUConfig.Dyno.StageBoost = {
    ecustage1    = 6,
    ecustage2    = 9,
    ecustage3    = 15,
    turbo        = 15,
    downpipe     = 7,
    straightpipe = 5,
}

ECUConfig.Dyno.VehiclePower = {
    ['hcivicr23']                 = { ps = 329, nm = 420 },
    ['f12cilindri24']             = { ps = 830, nm = 678 },
    ['curxedm8']                  = { ps = 625, nm = 750 },
    ['foxleggera']                = { ps = 510, nm = 600 },
    ['thevalkspdr']               = { ps = 1160, nm = 900 },
    ['vantagefv12']               = { ps = 665, nm = 780 },
    ['a1abt']                     = { ps = 231, nm = 350 },
    ['b5s4']                      = { ps = 380, nm = 440 },
    ['rs4revosport']              = { ps = 450, nm = 430 },
    ['audirs4']                   = { ps = 450, nm = 600 },
    ['jdtwinr8']                  = { ps = 610, nm = 560 },
    ['audir8dec']                 = { ps = 620, nm = 580 },
    ['abtxgt']                    = { ps = 640, nm = 600 },
    ['rs3s20']                    = { ps = 400, nm = 500 },
    ['rs322sedancarbont']         = { ps = 400, nm = 500 },
    ['rs3krypt']                  = { ps = 340, nm = 450 },
    ['27rs5b10']                  = { ps = 470, nm = 600 },
    ['2014rs5']                   = { ps = 450, nm = 430 },
    ['rs520']                     = { ps = 450, nm = 600 },
    ['ars620']                    = { ps = 600, nm = 800 },
    ['rs6c6s']                    = { ps = 580, nm = 650 },
    ['audirs6tk']                 = { ps = 560, nm = 700 },
    ['rmodrs6r']                  = { ps = 600, nm = 800 },
    ['rs6gt25md']                 = { ps = 630, nm = 850 },
    ['rs7maxton']                 = { ps = 600, nm = 800 },
    ['centrs7abt']                = { ps = 560, nm = 700 },
    ['arsq8']                     = { ps = 600, nm = 800 },
    ['complainrsq8']              = { ps = 600, nm = 800 },
    ['audis8d42013wb']            = { ps = 605, nm = 750 },
    ['oycs8']                     = { ps = 571, nm = 800 },
    ['asq522']                    = { ps = 354, nm = 500 },
    ['fofprev29']                 = { ps = 340, nm = 500 },
    ['centmvfkcomplain_330e91']   = { ps = 245, nm = 520 },
    ['bido_330i']                 = { ps = 258, nm = 400 },
    ['zzzxxmxxzzz']               = { ps = 306, nm = 400 },
    ['pluto335e92v5']             = { ps = 700, nm = 850 },
    ['m3s']                       = { ps = 306, nm = 400 },
    ['340if30']                   = { ps = 326, nm = 450 },
    ['435i']                      = { ps = 306, nm = 400 },
    ['760lig12f']                 = { ps = 609, nm = 800 },
    ['royalcustom_e38']           = { ps = 326, nm = 490 },
    ['m140iss']                   = { ps = 340, nm = 500 },
    ['m140i20md']                 = { ps = 400, nm = 550 },
    ['130ievohc']                 = { ps = 265, nm = 315 },
    ['m2csmpower']                = { ps = 450, nm = 550 },
    ['m2g87']                     = { ps = 460, nm = 550 },
    ['gcars_m2_g87_adrokit']      = { ps = 460, nm = 550 },
    ['addon_styropianm2']         = { ps = 550, nm = 650 },
    ['m235i']                     = { ps = 326, nm = 450 },
    ['trucksm240iv2']             = { ps = 450, nm = 600 },
    ['jdg80adro']                 = { ps = 800, nm = 900 },
    ['m3e30']                     = { ps = 238, nm = 240 },
    ['m3e36']                     = { ps = 321, nm = 350 },
    ['bm3e36']                    = { ps = 321, nm = 350 },
    ['05m3e46']                   = { ps = 343, nm = 365 },
    ['tw_bm2w4603']               = { ps = 343, nm = 365 },
    ['e92m3']                     = { ps = 420, nm = 400 },
    ['m3e90']                     = { ps = 420, nm = 400 },
    ['bm3e92c']                   = { ps = 420, nm = 400 },
    ['trucksg80m3']               = { ps = 900, nm = 1000 },
    ['25m3g80cs']                 = { ps = 550, nm = 650 },
    ['3erg20f']                   = { ps = 374, nm = 500 },
    ['m340i24']                   = { ps = 650, nm = 800 },
    ['m340i']                     = { ps = 450, nm = 600 },
    ['bmwm3f80']                  = { ps = 431, nm = 550 },
    ['18m3f80cs']                 = { ps = 460, nm = 600 },
    ['m3turbo']                   = { ps = 700, nm = 850 },
    ['rbmwm3f80']                 = { ps = 431, nm = 550 },
    ['vc_m3g80streetfighter']     = { ps = 510, nm = 650 },
    ['snikers_adro']              = { ps = 510, nm = 650 },
    ['23touring']                 = { ps = 530, nm = 650 },
    ['vc_m4g82sporttech']         = { ps = 510, nm = 650 },
    ['f82']                       = { ps = 431, nm = 550 },
    ['marvinm4']                  = { ps = 460, nm = 600 },
    ['m4cc']                      = { ps = 431, nm = 550 },
    ['bm4f82cab']                 = { ps = 431, nm = 550 },
    ['lwg82']                     = { ps = 510, nm = 650 },
    ['vc_m4g82adrowidebody']      = { ps = 550, nm = 700 },
    ['m5g60']                     = { ps = 727, nm = 1000 },
    ['m5f90cs']                   = { ps = 635, nm = 750 },
    ['sa_m5f10vor']               = { ps = 560, nm = 680 },
    ['aq_m5e60']                  = { ps = 507, nm = 520 },
    ['complaingpowerm5']          = { ps = 800, nm = 1000 },
    ['bmwm5v22022wb']             = { ps = 625, nm = 750 },
    ['trucksm5cs']                = { ps = 1000, nm = 1100 },
    ['f10m5']                     = { ps = 560, nm = 680 },
    ['bmwm5f90']                  = { ps = 600, nm = 750 },
    ['e34']                       = { ps = 211, nm = 290 },
    ['bmwe39']                    = { ps = 400, nm = 500 },
    ['m6f06']                     = { ps = 560, nm = 680 },
    ['m6f13']                     = { ps = 560, nm = 680 },
    ['royalcustom_e63m6gpower3']  = { ps = 750, nm = 900 },
    ['m8keyvany']                 = { ps = 625, nm = 750 },
    ['m8f91']                     = { ps = 625, nm = 750 },
    ['x3md']                      = { ps = 510, nm = 600 },
    ['x5_radmir']                 = { ps = 286, nm = 650 },
    ['24x5mvaki']                 = { ps = 625, nm = 750 },
    ['x6mf96']                    = { ps = 625, nm = 750 },
    ['x6kwk']                     = { ps = 575, nm = 750 },
    ['26xb7']                     = { ps = 530, nm = 750 },
    ['bmwxm']                     = { ps = 653, nm = 800 },
    ['911brabusr']                = { ps = 820, nm = 950 },
    ['mobrabuscrawler']           = { ps = 900, nm = 1050 },
    ['bshadow800']                = { ps = 700, nm = 950 },
    ['brabusgt600']               = { ps = 600, nm = 800 },
    ['brabusrocket900']           = { ps = 900, nm = 1250 },
    ['2017chiron']                = { ps = 1500, nm = 1600 },
    ['pursport']                  = { ps = 1500, nm = 1600 },
    ['veyronjch']                 = { ps = 1200, nm = 1500 },
    ['thelmz0623']                = { ps = 502, nm = 637 },
    ['nathanzl1']                 = { ps = 650, nm = 881 },
    ['czr1']                      = { ps = 647, nm = 819 },
    ['rmodz06']                   = { ps = 512, nm = 637 },
    ['23yenkozr1']                = { ps = 765, nm = 969 },
    ['seatleon3cupra2018wb']      = { ps = 300, nm = 380 },
    ['cupra22f']                  = { ps = 390, nm = 480 },
    ['tccat']                     = { ps = 717, nm = 881 },
    ['charger21']                 = { ps = 717, nm = 881 },
    ['rmodcharger69']             = { ps = 425, nm = 610 },
    ['durangocrb']                = { ps = 710, nm = 875 },
    ['viper']                     = { ps = 645, nm = 814 },
    ['296speca']                  = { ps = 880, nm = 740 },
    ['812gts']                    = { ps = 800, nm = 718 },
    ['oyc812n']                   = { ps = 800, nm = 718 },
    ['ikx3daytona22']             = { ps = 840, nm = 697 },
    ['f2012']                     = { ps = 750, nm = 600 },
    ['rmodf40']                   = { ps = 478, nm = 577 },
    ['rmodf8']                    = { ps = 720, nm = 770 },
    ['laferrari17']               = { ps = 963, nm = 900 },
    ['pistaspider19']             = { ps = 720, nm = 770 },
    ['italia']                    = { ps = 570, nm = 540 },
    ['fsf90xx']                   = { ps = 1000, nm = 800 },
    ['oycsf90sp']                 = { ps = 1000, nm = 800 },
    ['alcdh25']                   = { ps = 450, nm = 529 },
    ['gt17']                      = { ps = 656, nm = 746 },
    ['gt500tdb']                  = { ps = 770, nm = 847 },
    ['mustanggtd']                = { ps = 815, nm = 875 },
    ['raptorsxr25']               = { ps = 456, nm = 691 },
    ['19ftype']                   = { ps = 575, nm = 700 },
    ['rmodjeepg']                 = { ps = 285, nm = 353 },
    ['hawkcrb']                   = { ps = 717, nm = 875 },
    ['agera11']                   = { ps = 940, nm = 1100 },
    ['agerars']                   = { ps = 1176, nm = 1280 },
    ['ccx']                       = { ps = 806, nm = 920 },
    ['gemera']                    = { ps = 1724, nm = 3500 },
    ['jesko2020']                 = { ps = 1600, nm = 1500 },
    ['regera']                    = { ps = 1500, nm = 2000 },
    ['aventador17']               = { ps = 740, nm = 690 },
    ['lavent12']                  = { ps = 700, nm = 690 },
    ['rrhuracanevo']              = { ps = 640, nm = 600 },
    ['hevo']                      = { ps = 640, nm = 600 },
    ['huracan']                   = { ps = 610, nm = 560 },
    ['perftt']                    = { ps = 1000, nm = 900 },
    ['mdmilo']                    = { ps = 1000, nm = 900 },
    ['revueltosec']               = { ps = 1015, nm = 725 },
    ['sto']                       = { ps = 640, nm = 565 },
    ['rmodsvj']                   = { ps = 770, nm = 720 },
    ['offstradavent']             = { ps = 750, nm = 700 },
    ['urus']                      = { ps = 650, nm = 850 },
    ['murus20']                   = { ps = 650, nm = 850 },
    ['urus22evos']                = { ps = 666, nm = 850 },
    ['ikx3urus23']                = { ps = 666, nm = 850 },
    ['lp670sv']                   = { ps = 670, nm = 660 },
    ['mc20h']                     = { ps = 630, nm = 730 },
    ['stradale18']                = { ps = 630, nm = 730 },
    ['fd']                        = { ps = 280, nm = 294 },
    ['mrx811']                    = { ps = 231, nm = 211 },
    ['rx7veilside']               = { ps = 350, nm = 400 },
    ['600ltmso']                  = { ps = 600, nm = 620 },
    ['ikx3620r']                  = { ps = 620, nm = 620 },
    ['750sp']                     = { ps = 750, nm = 800 },
    ['oycn65']                    = { ps = 765, nm = 800 },
    ['p1']                        = { ps = 916, nm = 900 },
    ['senna001']                  = { ps = 800, nm = 800 },
    ['rmodspeed']                 = { ps = 1055, nm = 1150 },
    ['190e']                      = { ps = 235, nm = 245 },
    ['a45amg']                    = { ps = 421, nm = 500 },
    ['amgoneh']                   = { ps = 1063, nm = 1000 },
    ['c43']                       = { ps = 390, nm = 520 },
    ['mbc63']                     = { ps = 517, nm = 620 },
    ['c63damac']                  = { ps = 510, nm = 700 },
    ['c63sw205s']                 = { ps = 510, nm = 700 },
    ['c63sblack']                 = { ps = 510, nm = 700 },
    ['cl65']                      = { ps = 612, nm = 1000 },
    ['cla45black']                = { ps = 421, nm = 500 },
    ['cle53amg24']                = { ps = 449, nm = 560 },
    ['cls63mafia']                = { ps = 585, nm = 800 },
    ['benze55']                   = { ps = 476, nm = 700 },
    ['e632014']                   = { ps = 585, nm = 800 },
    ['mercedese63w2112008wb']     = { ps = 514, nm = 630 },
    ['e63sdmo']                   = { ps = 612, nm = 850 },
    ['e63stamg']                  = { ps = 612, nm = 850 },
    ['g63amg24m']                 = { ps = 585, nm = 850 },
    ['g63amg6x6']                 = { ps = 544, nm = 760 },
    ['gle63']                     = { ps = 612, nm = 850 },
    ['gsl600larte']               = { ps = 557, nm = 730 },
    ['ikx3gtblack']               = { ps = 730, nm = 800 },
    ['gt63cp24']                  = { ps = 816, nm = 1420 },
    ['gt63s19']                   = { ps = 639, nm = 900 },
    ['amggts']                    = { ps = 522, nm = 670 },
    ['2014s632']                  = { ps = 850, nm = 1450 },
    ['s63amgmaybach']             = { ps = 612, nm = 900 },
    ['ms63cab20']                 = { ps = 612, nm = 900 },
    ['s65f']                      = { ps = 630, nm = 1000 },
    ['benzsl55']                  = { ps = 476, nm = 700 },
    ['sl63amg22']                 = { ps = 585, nm = 800 },
    ['sl65bs']                    = { ps = 670, nm = 1000 },
    ['gcmslsblack']               = { ps = 631, nm = 635 },
    ['slsblackseries']            = { ps = 631, nm = 635 },
    ['sl63']                      = { ps = 537, nm = 800 },
    ['s63ew223']                  = { ps = 802, nm = 1430 },
    ['s65amg']                    = { ps = 630, nm = 1000 },
    ['oyce63amg']                 = { ps = 612, nm = 850 },
    ['gle63sgg']                  = { ps = 612, nm = 850 },
    ['esnevox']                   = { ps = 295, nm = 407 },
    ['ngtrr35']                   = { ps = 570, nm = 637 },
    ['ngtrr3507']                 = { ps = 485, nm = 588 },
    ['ngtr50']                    = { ps = 570, nm = 637 },
    ['r32']                       = { ps = 280, nm = 353 },
    ['nskygtrr34']                = { ps = 330, nm = 392 },
    ['s15']                       = { ps = 250, nm = 275 },
    ['nissantitan17']             = { ps = 395, nm = 528 },
    ['nznismo24']                 = { ps = 420, nm = 520 },
    ['imola']                     = { ps = 827, nm = 1100 },
    ['zonda760roadster']          = { ps = 760, nm = 780 },
    ['rmodporsche918']            = { ps = 887, nm = 1280 },
    ['919hybrid']                 = { ps = 900, nm = 900 },
    ['930t']                      = { ps = 300, nm = 412 },
    ['turbos911sd']               = { ps = 650, nm = 800 },
    ['p944']                      = { ps = 163, nm = 205 },
    ['911r']                      = { ps = 500, nm = 600 },
    ['gcm992gt3']                 = { ps = 510, nm = 470 },
    ['p992gts25']                 = { ps = 541, nm = 610 },
    ['992targa4s']                = { ps = 450, nm = 530 },
    ['p911ts']                    = { ps = 580, nm = 700 },
    ['porcgt03']                  = { ps = 612, nm = 590 },
    ['rrcgt']                     = { ps = 680, nm = 650 },
    ['wxgt3']                     = { ps = 510, nm = 470 },
    ['992gt3rs']                  = { ps = 525, nm = 465 },
    ['992gt3rsmr']                = { ps = 560, nm = 480 },
    ['caymangt4rs']               = { ps = 500, nm = 450 },
    ['18macan']                   = { ps = 360, nm = 480 },
    ['rrtrx']                     = { ps = 702, nm = 881 },
    ['404ram5th']                 = { ps = 702, nm = 881 },
    ['trx']                       = { ps = 702, nm = 881 },
    ['gstcdy1']                   = { ps = 500, nm = 600 },
    ['keitorac']                  = { ps = 600, nm = 700 },
    ['zip']                       = { ps = 120, nm = 150 },
    ['i30ntdb']                   = { ps = 280, nm = 392 },
    ['flyingspur']                = { ps = 635, nm = 900 },
    ['fk8']                       = { ps = 320, nm = 400 },
    ['defender21']                = { ps = 400, nm = 550 },
    ['zc31s']                     = { ps = 125, nm = 148 },
    ['gt4586']                    = { ps = 570, nm = 540 },
    ['a80mk4']                    = { ps = 330, nm = 441 },
    ['gsmallsupra']               = { ps = 800, nm = 900 },
    ['setsuna']                   = { ps = 340, nm = 500 },
    ['vanz21yaris']               = { ps = 261, nm = 360 },
    ['volvo850r']                 = { ps = 250, nm = 350 },
    ['golf4']                     = { ps = 204, nm = 270 },
    ['golf2marv']                 = { ps = 700, nm = 800 },
    ['mk6r']                      = { ps = 300, nm = 400 },
    ['golf25r']                   = { ps = 333, nm = 420 },
    ['tiguan2022']                = { ps = 245, nm = 370 },
    ['mk3vr6']                    = { ps = 174, nm = 235 },
    ['mk1rabbit']                 = { ps = 110, nm = 140 },
    ['hcbr17']                    = { ps = 189, nm = 114 },
    ['exc530']                    = { ps = 55, nm = 55 },
    ['h2carb']                    = { ps = 231, nm = 142 },
    ['m1000rr']                   = { ps = 212, nm = 113 },
    ['cbr650r']                   = { ps = 95, nm = 64 },
    ['fz07']                      = { ps = 75, nm = 68 },
    ['r1']                        = { ps = 200, nm = 113 },
    ['r6']                        = { ps = 118, nm = 62 },
    ['bs17']                      = { ps = 207, nm = 113 },
    ['smc690']                    = { ps = 74, nm = 74 },

    ['escalade']                  = { ps = 409, nm = 565 },
    ['vaki87f40']                 = { ps = 478, nm = 577 },
    ['svr17md']                   = { ps = 550, nm = 680 },
    ['huayrabcdk']                = { ps = 802, nm = 1000 },
    ['c8corvettesx']              = { ps = 850, nm = 950 },
    ['m8gcf93']                   = { ps = 625, nm = 750 },
    ['21LX600SN']                 = { ps = 415, nm = 650 },
    ['23ramtrx']                  = { ps = 712, nm = 881 },
    ['23GT3RSDP']                 = { ps = 1000, nm = 1050 },
    ['zaex3m']                    = { ps = 700, nm = 900 },
    ['cullinan25md']              = { ps = 571, nm = 850 },
    ['troc']                      = { ps = 400, nm = 500 },
    ['simson']                    = { ps = 4, nm = 8 },
    ['GoldSTOUGR']                = { ps = 640, nm = 565 },
    ['exotic_rs3revozport']       = { ps = 600, nm = 750 },
    ['ons_x_sn_m2twoface']        = { ps = 410, nm = 550 },
    ['potatog80']                 = { ps = 900, nm = 1000 },
    ['ajsv230']                   = { ps = 682, nm = 893 },
    ['bf_25nali']                 = { ps = 476, nm = 1322 },
    ['1kDDEKBHuracan']            = { ps = 1000, nm = 1100 },
    ['1kDDEMurcieLM']             = { ps = 1000, nm = 1050 },
    ['forgedm2']                  = { ps = 700, nm = 800 },
    ['812aju']                    = { ps = 830, nm = 692 },
    ['pgt2']                      = { ps = 620, nm = 700 },
}

ECUConfig.Dyno.SaveResults    = true

return ECUConfig
