return {
    AssemblyLocation = vec3(223.360367, 1137.683594, 225.510742),

    SpawnLocations = {
        vector4(212.2060, 1123.4526, 225.3926, 102.9449),
        vector4(214.4638, 1114.2101, 225.3926, 104.3385),
        vector4(216.4706, 1104.5244, 225.3928, 103.1315),
        vector4(230.7332, 1118.1903, 225.3930, 282.7568),
        vector4(233.0640, 1108.5974, 225.3927, 283.8497),
    },

    RequiredJob = {
        name = 'pabrik',
        spkGrade = 0,
        assemblyGrade = 2,
    },

    GhostVehicle = {
        alpha = 100,
        showBlip = false,
        preventDamage = true,
        missionEntity = true,
    },

    AssemblySystem = {
        progressDuration = 5000,
        animationScenario = 'WORLD_HUMAN_CLIPBOARD',
    },

    TestDrive = {
        coords = vector4(-2021.0852, 2865.8320, 32.9060, 0.0),
        duration = 60,
        npcModel = `a_m_m_business_01`,
        npcCoords = vector4(224.3332, 1182.5156, 224.4605, 281.4175),
        platePrefix = 'TEST',
    },

    DatabaseTable = 'player_vehicles',

    PlatePrefix = 'SPK',
    DefaultGarage = 'Garasi Pabrik',

    PartOffsets = {
        trunk    = vector3(0.0, -2.5, 0.5),
        hood     = vector3(0.0, 2.5, 0.5),
        engine   = vector3(0.0, 2.0, 1.0),
        door_lf  = vector3(-1.2, 0.5, 0.5),
        door_rf  = vector3(1.2, 0.5, 0.5),
        door_lr  = vector3(-1.2, -0.5, 0.5),
        door_rr  = vector3(1.2, -0.5, 0.5),
    },

    VehicleList = {
        ['sport'] = {
            {
                model = 'sm35z',
                name = 'SANNIS Z350 (CLASS S+)',
                materials = {
                    trunk   = { {item = 'aluminum', count = 6}, {item = 'stone', count = 4} },
                    hood    = { {item = 'aluminum', count = 5}, {item = 'iron', count = 3} },
                    engine  = { {item = 'steel', count = 10},   {item = 'rubber', count = 5} },
                    door_lf = { {item = 'glass', count = 2},    {item = 'aluminum', count = 3} },
                    door_rf = { {item = 'glass', count = 2},    {item = 'aluminum', count = 3} },
                },
            },
            {
                model = 'mxpan',
                name = 'DAMAZ 5MX (CLASS S+)',
                materials = {
                    trunk   = { {item = 'aluminum', count = 6}, {item = 'stone', count = 4} },
                    hood    = { {item = 'aluminum', count = 5}, {item = 'iron', count = 3} },
                    engine  = { {item = 'steel', count = 10},   {item = 'rubber', count = 5} },
                    door_lf = { {item = 'glass', count = 2},    {item = 'aluminum', count = 3} },
                    door_rf = { {item = 'glass', count = 2},    {item = 'aluminum', count = 3} },
                },
            },
            {
                model = 'smcjzx',
                name = 'YOTATO CHAISAR (CLASS S)',
                materials = {
                    trunk   = { {item = 'aluminum', count = 6}, {item = 'stone', count = 4} },
                    hood    = { {item = 'aluminum', count = 5}, {item = 'iron', count = 3} },
                    engine  = { {item = 'steel', count = 10},   {item = 'rubber', count = 5} },
                    door_lf = { {item = 'glass', count = 2},    {item = 'aluminum', count = 3} },
                    door_rf = { {item = 'glass', count = 2},    {item = 'aluminum', count = 3} },
                },
            },
            {
                model = 'cam8tun',
                name = 'YOTATO CEMRY (CLASS S)',
                materials = {
                    trunk   = { {item = 'aluminum', count = 6}, {item = 'stone', count = 4} },
                    hood    = { {item = 'aluminum', count = 5}, {item = 'iron', count = 3} },
                    engine  = { {item = 'steel', count = 10},   {item = 'rubber', count = 5} },
                    door_lf = { {item = 'glass', count = 2},    {item = 'aluminum', count = 3} },
                    door_rf = { {item = 'glass', count = 2},    {item = 'aluminum', count = 3} },
                },
            },
            {
                model = 'coupefg4',
                name = 'DAHON CEVEC SI (CLASS S)',
                materials = {
                    trunk   = { {item = 'aluminum', count = 6}, {item = 'stone', count = 4} },
                    hood    = { {item = 'aluminum', count = 5}, {item = 'iron', count = 3} },
                    engine  = { {item = 'steel', count = 10},   {item = 'rubber', count = 5} },
                    door_lf = { {item = 'glass', count = 2},    {item = 'aluminum', count = 3} },
                    door_rf = { {item = 'glass', count = 2},    {item = 'aluminum', count = 3} },
                },
            },
            {
                model = 'is350mod',
                name = 'XUSLE 350SI (CLASS S)',
                materials = {
                    trunk   = { {item = 'aluminum', count = 6}, {item = 'stone', count = 4} },
                    hood    = { {item = 'aluminum', count = 5}, {item = 'iron', count = 3} },
                    engine  = { {item = 'steel', count = 10},   {item = 'rubber', count = 5} },
                    door_lf = { {item = 'glass', count = 2},    {item = 'aluminum', count = 3} },
                    door_rf = { {item = 'glass', count = 2},    {item = 'aluminum', count = 3} },
                },
            },
            {
                model = 'bme6',
                name = 'BME6 (CLASS A)',
                materials = {
                    trunk   = { {item = 'aluminum', count = 6}, {item = 'stone', count = 4} },
                    hood    = { {item = 'aluminum', count = 5}, {item = 'iron', count = 3} },
                    engine  = { {item = 'steel', count = 10},   {item = 'rubber', count = 5} },
                    door_lf = { {item = 'glass', count = 2},    {item = 'aluminum', count = 3} },
                    door_rf = { {item = 'glass', count = 2},    {item = 'aluminum', count = 3} },
                },
            },
            {
                model = 'yumi',
                name = 'Yumi (CLASS A)',
                materials = {
                    trunk   = { {item = 'aluminum', count = 6}, {item = 'stone', count = 4} },
                    hood    = { {item = 'aluminum', count = 5}, {item = 'iron', count = 3} },
                    engine  = { {item = 'steel', count = 10},   {item = 'rubber', count = 5} },
                    door_lf = { {item = 'glass', count = 2},    {item = 'aluminum', count = 3} },
                    door_rf = { {item = 'glass', count = 2},    {item = 'aluminum', count = 3} },
                },
            },
            {
                model = 'a45amg',
                name = 'CYMER 45A (CLASS A)',
                materials = {
                    trunk   = { {item = 'aluminum', count = 6}, {item = 'stone', count = 4} },
                    hood    = { {item = 'aluminum', count = 5}, {item = 'iron', count = 3} },
                    engine  = { {item = 'steel', count = 10},   {item = 'rubber', count = 5} },
                    door_lf = { {item = 'glass', count = 2},    {item = 'aluminum', count = 3} },
                    door_rf = { {item = 'glass', count = 2},    {item = 'aluminum', count = 3} },
                },
            },
            {
                model = 'subisti08',
                name = 'BARUSU 08 STI (CLASS A)',
                materials = {
                    trunk   = { {item = 'aluminum', count = 6}, {item = 'stone', count = 4} },
                    hood    = { {item = 'aluminum', count = 5}, {item = 'iron', count = 3} },
                    engine  = { {item = 'steel', count = 10},   {item = 'rubber', count = 5} },
                    door_lf = { {item = 'glass', count = 2},    {item = 'aluminum', count = 3} },
                    door_rf = { {item = 'glass', count = 2},    {item = 'aluminum', count = 3} },
                },
            },
            {
                model = 'smsim22',
                name = 'BARUSU IMPREZ 22 (CLASS S)',
                materials = {
                    trunk   = { {item = 'aluminum', count = 6}, {item = 'stone', count = 4} },
                    hood    = { {item = 'aluminum', count = 5}, {item = 'iron', count = 3} },
                    engine  = { {item = 'steel', count = 10},   {item = 'rubber', count = 5} },
                    door_lf = { {item = 'glass', count = 2},    {item = 'aluminum', count = 3} },
                    door_rf = { {item = 'glass', count = 2},    {item = 'aluminum', count = 3} },
                },
            },
            {
                model = 'mr2',
                name = 'TOY MR2 (CLASS S)',
                materials = {
                    trunk   = { {item = 'aluminum', count = 6}, {item = 'stone', count = 4} },
                    hood    = { {item = 'aluminum', count = 5}, {item = 'iron', count = 3} },
                    engine  = { {item = 'steel', count = 10},   {item = 'rubber', count = 5} },
                    door_lf = { {item = 'glass', count = 2},    {item = 'aluminum', count = 3} },
                    door_rf = { {item = 'glass', count = 2},    {item = 'aluminum', count = 3} },
                },
            },
            {
                model = 'elsapek',
                name = 'MITSU L300 (CLASS B)',
                materials = {
                    trunk   = { {item = 'aluminum', count = 6}, {item = 'stone', count = 4} },
                    hood    = { {item = 'aluminum', count = 5}, {item = 'iron', count = 3} },
                    engine  = { {item = 'steel', count = 10},   {item = 'rubber', count = 5} },
                    door_lf = { {item = 'glass', count = 2},    {item = 'aluminum', count = 3} },
                    door_rf = { {item = 'glass', count = 2},    {item = 'aluminum', count = 3} },
                },
            },
            {
                model = 'x6mf16',
                name = 'WMB M6X (CLASS B)',
                materials = {
                    trunk   = { {item = 'aluminum', count = 6}, {item = 'stone', count = 4} },
                    hood    = { {item = 'aluminum', count = 5}, {item = 'iron', count = 3} },
                    engine  = { {item = 'steel', count = 10},   {item = 'rubber', count = 5} },
                    door_lf = { {item = 'glass', count = 2},    {item = 'aluminum', count = 3} },
                    door_rf = { {item = 'glass', count = 2},    {item = 'aluminum', count = 3} },
                },
            },
            {
                model = 'wildtrak',
                name = 'FRD COBRON (CLASS B)',
                materials = {
                    trunk   = { {item = 'aluminum', count = 6}, {item = 'stone', count = 4} },
                    hood    = { {item = 'aluminum', count = 5}, {item = 'iron', count = 3} },
                    engine  = { {item = 'steel', count = 10},   {item = 'rubber', count = 5} },
                    door_lf = { {item = 'glass', count = 2},    {item = 'aluminum', count = 3} },
                    door_rf = { {item = 'glass', count = 2},    {item = 'aluminum', count = 3} },
                },
            },
            {
                model = 'smfj',
                name = 'YOTATO FJ',
                materials = {
                    trunk   = { {item = 'aluminum', count = 6}, {item = 'stone', count = 4} },
                    hood    = { {item = 'aluminum', count = 5}, {item = 'iron', count = 3} },
                    engine  = { {item = 'steel', count = 10},   {item = 'rubber', count = 5} },
                    door_lf = { {item = 'glass', count = 2},    {item = 'aluminum', count = 3} },
                    door_rf = { {item = 'glass', count = 2},    {item = 'aluminum', count = 3} },
                },
            },
            {
                model = 'smlct200h',
                name = 'XUSLE GS 350',
                materials = {
                    trunk   = { {item = 'aluminum', count = 6}, {item = 'stone', count = 4} },
                    hood    = { {item = 'aluminum', count = 5}, {item = 'iron', count = 3} },
                    engine  = { {item = 'steel', count = 10},   {item = 'rubber', count = 5} },
                    door_lf = { {item = 'glass', count = 2},    {item = 'aluminum', count = 3} },
                    door_rf = { {item = 'glass', count = 2},    {item = 'aluminum', count = 3} },
                },
            },
        },
        ['motorcycle'] = {
            {
                model = 'smzx',
                name = 'SMZX MOTORCYCLE',
                materials = {
                    trunk   = { {item = 'aluminum', count = 6}, {item = 'stone', count = 4} },
                    hood    = { {item = 'aluminum', count = 5}, {item = 'iron', count = 3} },
                    engine  = { {item = 'steel', count = 10},   {item = 'rubber', count = 5} },
                    door_lf = { {item = 'glass', count = 2},    {item = 'aluminum', count = 3} },
                    door_rf = { {item = 'glass', count = 2},    {item = 'aluminum', count = 3} },
                },
            },
            {
                model = 'smlowhd',
                name = 'SMLOWHD MOTORCYCLE',
                materials = {
                    trunk   = { {item = 'aluminum', count = 6}, {item = 'stone', count = 4} },
                    hood    = { {item = 'aluminum', count = 5}, {item = 'iron', count = 3} },
                    engine  = { {item = 'steel', count = 10},   {item = 'rubber', count = 5} },
                    door_lf = { {item = 'glass', count = 2},    {item = 'aluminum', count = 3} },
                    door_rf = { {item = 'glass', count = 2},    {item = 'aluminum', count = 3} },
                },
            },
            {
                model = 'smvstroms',
                name = 'IKUZUS DL250',
                materials = {
                    trunk   = { {item = 'aluminum', count = 6}, {item = 'stone', count = 4} },
                    hood    = { {item = 'aluminum', count = 5}, {item = 'iron', count = 3} },
                    engine  = { {item = 'steel', count = 10},   {item = 'rubber', count = 5} },
                    door_lf = { {item = 'glass', count = 2},    {item = 'aluminum', count = 3} },
                    door_rf = { {item = 'glass', count = 2},    {item = 'aluminum', count = 3} },
                },
            },
            {
                model = 'smhaya',
                name = 'IKUZUS HAYABUSA',
                materials = {
                    trunk   = { {item = 'aluminum', count = 6}, {item = 'stone', count = 4} },
                    hood    = { {item = 'aluminum', count = 5}, {item = 'iron', count = 3} },
                    engine  = { {item = 'steel', count = 10},   {item = 'rubber', count = 5} },
                    door_lf = { {item = 'glass', count = 2},    {item = 'aluminum', count = 3} },
                    door_rf = { {item = 'glass', count = 2},    {item = 'aluminum', count = 3} },
                },
            },
        },
    },
}