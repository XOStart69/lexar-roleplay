local BADGE_INTERCEPTOR = { 'badgeinterceptor', 'badgeshc' }
local BADGE_SWAT = { 'badgeswatlspd', 'badgeshc' }
local BADGE_HELI = { 'badgehelicopter', 'badgeshc' }

return {
    interactDistance = 2.5,
    escortDistance = 3.0,
    cuffCooldown = 5,
    disableSprintWhileEscorting = false,

    cuffJobs = {
        police = true,
        usmarshal = true,
        pengadilan = true,
        government = true,
        paspampres = true,
        admin = true,
        mercenarysm = true,
    },

    escortJobs = {
        mercenarysm = true,
        pengadilan = true,
    },

    handcuffItem = 'handcuffs',
    cuffKeyItem = 'cuffkeys',

    cuffItems = {
        handcuffs = { prop = 'p_cs_cuffs_02_s', key = 'cuffkeys', flag = 19 },
        ziptie = { prop = 'bzzz_prop_gag_b', key = 'flush_cutter', flag = 49, public = true, consume = true },
    },

    keyItems = {
        cuffkeys = {},
        flush_cutter = { public = true, consume = true },
    },

    breakout = {
        enabled = true,
        difficulty = 'medium',
        inputs = { 'w', 'a', 's', 'd' },
        minTime = 600,
        timeout = 15000,
    },

    boltCutter = {
        item = 'bolt_cutter',
        brokenItem = 'broken_handcuffs',
        duration = 6000,
    },

    lockpick = {
        item = 'lockpick',
        cuffs = { handcuffs = true },
        distance = 2.0,
        difficulty = 3,
        pins = 5,
        minDuration = 3000,
        maxDuration = 90000,
        cooldown = 10,
    },

    search = {
        police = { min = 3000, max = 5000, label = 'Menggeledah pemain...' },
        rob = { min = 5000, max = 7000, label = 'Merampok orang...' },
        forceJobs = { admin = true },
        jobGrades = { sksm = { 3, 8 } },
        viewOnlyJobs = { ambulance = true },
    },

    ownedPoliceCars = true,
    garageCooldown = 3000,
    garageDistance = 6.0,
    garagePed = 's_m_y_hwaycop_01',
    platePrefix = { car = 'LSPD', heli = 'ZULU' },

    vehicles = {
        car = {
            { model = 'npolmm', label = 'NpolMM', price = 1000, minGrade = 1, livery = 0, items = BADGE_INTERCEPTOR },
            { model = 'npolexp', label = 'Police Explorer', price = 1000, minGrade = 1, livery = 0 },
            { model = 'npolvic', label = 'Police Victoria', price = 1000, minGrade = 1, livery = 0 },
            { model = 'police3', label = 'Police Cruiser', price = 1000, minGrade = 1, livery = 0 },
            { model = 'policet', label = 'Police Transporter', price = 1000, minGrade = 1, livery = 0 },
            { model = 'fbi', label = 'FBI', price = 1000, minGrade = 1, livery = 0 },
            { model = 'npolstang', label = 'Police Mustang', price = 1000, minGrade = 1, livery = 0, items = BADGE_INTERCEPTOR },
            { model = 'npolchal', label = 'Police Challenger', price = 1000, minGrade = 1, livery = 0, items = BADGE_INTERCEPTOR },
            { model = 'npolchar', label = 'Police Charger', price = 1000, minGrade = 1, livery = 0, items = BADGE_INTERCEPTOR },
            { model = 'npolvette', label = 'Police Corvette', price = 1000, minGrade = 1, livery = 0, items = BADGE_INTERCEPTOR },
            { model = 'riot', label = 'RIOT', price = 1000, minGrade = 1, livery = 0, items = BADGE_SWAT },
        },
        heli = {
            { model = 'polmav', label = 'Police Maverick', price = 1, minGrade = 1, livery = 0, items = BADGE_HELI },
        },
    },

    itemBypass = {
        car = { police = { 12, 99 } },
        heli = { police = { 15, 16 } },
    },

    garages = {
        car = {
            { ped = vec4(-459.0504, 6031.6079, 31.3405, 139.4868), spawn = vec4(-457.2596, 6024.8564, 31.3338, 314.4784) },
            { ped = vec4(1862.3417, 3684.1848, 33.9908, 31.7380), spawn = vec4(1861.2227, 3676.9661, 33.7198, 212.9439) },
            { ped = vec4(2442.7856, 1549.4247, 30.7587, 173.8732), spawn = vec4(2452.6699, 1545.1056, 30.4707, 180.9346) },
        },
        heli = {
            { ped = vec4(-483.7837, 5977.3008, 31.3025, 323.4080), spawn = vec4(-474.6581, 5989.4194, 31.7223, 43.4872) },
            { ped = vec4(1821.5109, 3671.5281, 44.3788, 207.5309), spawn = vec4(1820.1213, 3666.6489, 44.7754, 206.7998) },
            { ped = vec4(443.5267, -975.4025, 43.6918, 277.6346), spawn = vec4(450.2836, -980.8965, 44.0832, 86.1482) },
            { ped = vec4(2442.7417, 1519.8292, 30.7903, 0.1543), spawn = vec4(2434.0034, 1527.4711, 31.1750, 357.6815) },
        },
    },

    evidenceDistance = 5.0,
    evidence = {
        vec3(1834.974365, 3697.551514, 29.427706),
        vec3(148.071213, -769.289429, 242.501617),
        vec3(458.835632, -988.356018, 24.803434),
        vec3(2465.988037, 1601.718628, 30.865210),
        vec3(-441.75, 6013.06, 31.42),
        vec3(215.66, -420.02, 42.87),
    },
    evidenceBadges = { 'badgeiaf', 'badgeshc' },

    plateTracker = vec3(2472.986816, 1612.152954, 30.397867),
    plateTrackerDistance = 5.0,

    licenseVehicleModels = { `simpol` },

    stations = {
        { label = 'Police Station Paleto', coords = vec3(-448.2174, 6012.5508, 31.7164) },
        { label = 'Police Station SandyShores', coords = vec3(1830.2292, 3671.3889, 34.0657) },
        { label = 'Police Station SASP', coords = vec3(2507.7725, 1586.8928, 30.4185) },
    },
    stationBlip = { sprite = 137, scale = 0.7, colour = 29 },
}
