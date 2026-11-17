return {
    item = 'domino_table',
    tableModel = 'suty_domino_table',
    chairModel = 'bkr_prop_clubhouse_chair_03',
    tileModel = 'suty_domino_%d_%d',
    caseModel = 'suty_domino_case',
    caseLidModel = 'suty_domino_case_lid',
    boardTexture = 'suty_domino_artwork',
    boardColor = { 26, 71, 52 },

    maxTables = 30,
    placeDistance = 5.0,
    minTableSpacing = 3.2,
    streamDistance = 35.0,
    interactDistance = 1.6,
    actionDistance = 3.5,
    actionCooldown = 250,

    surfaceHeight = 0.738,
    chairDistance = 0.92,
    chairHeadingOffset = 180.0,
    seatHeight = 0.56,
    handDistance = 0.4435,
    handSpacing = 0.034,
    handHeight = 0.7634,
    handTilt = 65.0,
    tileYawOffset = 0.0,
    dropRadius = 0.09,
    shuffleFx = { width = 0.42, depth = 0.3, speed = 0.35, turnSpeed = 220.0 },
    openDropArea = 0.3,
    pickRadius = 0.035,

    sit = {
        dict = 'anim@scripted@freemode_npc@fix_astu_ig3_pooh_jimmy@jimmy@',
        clip = 'sit_base_jimmy',
    },

    anims = {
        place = { dict = 'suty@domino_place', clip = 'place', duration = 1600 },
        shuffle = { dict = 'suty@domino_shuffle_video_v2', clip = 'shuffle', duration = 3000 },
        pass = { dict = 'gestures@m@standing@casual', clip = 'gesture_hello', duration = 1500 },
    },

    hands = {
        pick = {
            dict = 'suty@domino_hands', clip = 'take', duration = 1400, grasp = 0.28, release = 0.8,
            offset = vector3(0.121835, 0.023047, -0.005683), rotation = vector3(-162.63291, -11.22109, -92.83379),
        },
        place = {
            dict = 'suty@domino_place', clip = 'place', duration = 1600, grasp = 0.24, release = 0.68,
            offset = vector3(0.123711, 0.026061, -0.015139), rotation = vector3(17.367091, -11.221089, -87.166212),
        },
        unpack = { dict = 'suty@domino_hands', clip = 'take', duration = 3400 },
    },

    cameras = {
        seat = { offset = vector3(0.0, -0.6, 1.41), target = vector3(0.0, -0.14, 0.74), fov = 66.0 },
        top = { offset = vector3(0.0, -0.18, 1.95), target = vector3(0.0, 0.02, 0.74), fov = 60.0 },
    },

    game = {
        targets = { 100, 150, 200, 250, 500 },
        defaultTarget = 200,
        turnSeconds = 30,
        shuffleMs = 3000,
        unpackMs = 4200,
        resultTimeoutMs = 60000,
        autoPassMs = 1500,
        playDelayMs = 900,
        botThinkMs = { 1100, 2300 },
        dealTimeoutMs = 40000,
        botPickMs = { 450, 900 },
    },

    bots = {
        models = { 'a_m_o_soucent_01', 'a_m_o_genstreet_01', 'a_m_o_soucent_02', 'a_m_o_soucent_03' },
        names = { 'Tony', 'Ramon', 'Carlos', 'Luis', 'Pedro', 'Hector', 'Manny', 'Rafa' },
    },

    adminAce = 'admin',
}
