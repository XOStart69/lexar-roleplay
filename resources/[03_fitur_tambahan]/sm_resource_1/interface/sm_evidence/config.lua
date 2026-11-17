return {
    Jobs = {
        police = 0,
        usmarshal = 0,
        pengadilan = 0,
        mercenarysm = 0,
        ambulance = 0,
    },

    Flashlight = `WEAPON_FLASHLIGHT`,

    Lifetime = 5 * 60,

    Chance = {
        bullet_casing = 60,  -- percentage
        blood_sample  = 60,
    },

    -- cooldown abis drop evidence
    Cooldown = {
        bullet_casing = 6000,
        blood_sample  = 6000,
    },

    MaxActive = 1000,

    MinDistance = {
        bullet_casing = 0.5,
        blood_sample  = 0.8,
    },

    GlovesBlock = {
        bullet_casing = false,
    },

    Marker = {
        drawDistance = 12.0,
        interactDistance = 1.6,
    },

    CollectDuration = 4000,

    AnalyzePoints = {
        {
            coords = vec3(460.378784, -988.991394, 24.856808),
            label = 'Analisa Barang Bukti',
            types = { 'bullet_casing' },
        },
        {
            coords = vec3(1166.33, -1564.30, 30.62),
            label = 'Analisa Blood Sample',
            types = { 'blood_sample', 'fingerprint' },
        },
        {
            coords = vec3(1170.13, -1562.21, 30.78),
            label = 'Analisa Blood Sample',
            types = { 'blood_sample', 'fingerprint' },
        },
        {
            coords = vec3(2437.971436, 1575.280396, 30.763973),
            label = 'Analisa Bullet Casing',
            types = { 'bullet_casing' },
        },
    },

    Items = {
        blood_sample  = 'blood_sample',
        bullet_casing = 'bullet_casing',
        fingerprint   = 'fingerprint',
    },
}
