Config = {}

Config.Debug = GetConvarInt('pdtablet_debug', 0) == 1

Config.ItemName = 'pdtablet'

Config.Job = {
    allowed = { police = true },
    createGrade = 11,
    requireDuty = true,
}

Config.Divisions = {
    order = { 'stf', 'asd' },

    stf = {
        label = 'Speed Task Force',
        short = 'STF',
        description = 'Latihan pursuit kendaraan darat',
        logo = 'stf.png',
        trackType = 'ground',
        vehicles = {
            npolstang = 'Police Mustang',
            npolvette = 'Police Corvette',
            npolchar = 'Police Charger',
            npolchal = 'Police Challenger',
            h2rpolice = 'Police H2R',
            npolvic = 'Police Victoria',
            npolexp = 'Police Explorer',
            npolmm = 'Police Npol',
        },
    },

    asd = {
        label = 'Air Support Division',
        short = 'ASD',
        description = 'Latihan pursuit udara',
        logo = 'asd.png',
        trackType = 'air',
        vehicles = {
            polmav = 'Police Maverick',
        },
    },
}

Config.Track = {
    minCheckpoints = 4,
    maxCheckpoints = 0,
    maxPerOfficer = 15,
    minNameLength = 3,
    maxNameLength = 32,
    minTireDistance = 2.0,
    maxTireDistance = 30.0,
    defaultTireDistance = 8.0,
    markerRenderDistance = 250.0,
}

Config.Race = {
    joinDistance = 200.0,
    maxRacers = 16,
    countdown = 5,
    checkpointBuffer = 1.0,
    checkpointsAhead = 3,
    resetTimer = 20 * 60 * 1000,
    idleKickTime = 10 * 60 * 1000,
    historyLimit = 50,
    racerSyncInterval = 400,
    leaderboardLimit = 100,
}

Config.Ghosting = {
    enabled = true,
    alpha = 100,
    loopTime = 250,
    options = {
        { value = -1, label = 'Nonaktif' },
        { value = 0, label = 'Sepanjang sesi' },
        { value = 30000, label = '30 detik' },
        { value = 60000, label = '60 detik' },
    },
    default = 0,
}

Config.Bucket = {
    enabled = true,
    firstId = 7000,
    lastId = 7099,
}

Config.Props = {
    checkpoint = 'nk_checkpoint',
    startFinish = 'prop_beachflag_le',
}

Config.AirTrack = {
    minAltitude = 0.0,
    defaultRadius = 25.0,
    minRadius = 10.0,
    maxRadius = 60.0,
    radiusStep = 5.0,
    marker = {
        type = 28,
        color = { r = 47, g = 127, b = 214, a = 90 },
        nextColor = { r = 255, g = 150, b = 0, a = 110 },
    },
}

Config.Flare = {
    enabled = true,
    dict = 'core',
    name = 'exp_grd_flare',
    scale = 1.0,
    time = 10000,
    color = { r = 0.0, g = 0.35, b = 1.0 },
}

Config.Blips = {
    color = 38,
    size = 0.8,
}

Config.Marker = {
    type = 1,
    baseSize = 0.1,
    minHeight = 0.5,
    maxHeight = 30.0,
    color = { r = 255, g = 255, b = 255, a = 200 },
    distanceColor = { r = 255, g = 255, b = 255, a = 255 },
    primaryColor = { r = 47, g = 127, b = 214, a = 255 },
}

Config.Animation = {
    enabled = true,
    dict = 'amb@code_human_in_bus_passenger_idles@female@tablet@idle_a',
    clip = 'idle_a',
    prop = 'prop_cs_tablet',
    bone = 28422,
    offset = { x = 0.0, y = -0.03, z = 0.0 },
    rotation = { x = 20.0, y = -90.0, z = 0.0 },
}

Config.GateMarker = {
    type = 22,
    scale = { x = 1.0, y = 2.5, z = 1.5 },
    color = { r = 255, g = 150, b = 0, a = 255 },
}

Config.Keys = {
    addCheckpoint = 22,
    deleteCheckpoint = 73,
    saveTrack = 191,
    increaseDistance = 172,
    decreaseDistance = 173,
    increaseAlt = 96,
    decreaseAlt = 97,
    exit = 194,
}

Config.KeyLabels = {
    addCheckpoint = 'Space',
    deleteCheckpoint = 'X',
    saveTrack = 'Enter',
    distance = 'Arrow Up/Down or NUM + / NUM -',
    exit = 'Backspace',
}
