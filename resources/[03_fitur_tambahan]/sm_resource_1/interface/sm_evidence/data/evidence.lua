---@meta

local TYPES = {
    blood_sample = {
        label = 'Blood Sample',
        color = { r = 168, g = 24, b = 34 },
    },
    bullet_casing = {
        label = 'Bullet Casing',
        color = { r = 214, g = 158, b = 46 },
    },
    fingerprint = {
        label = 'Fingerprint',
        color = { r = 56, g = 138, b = 222 },
    },
}

local CALIBERS = {
    pistol  = '9x19mm Parabellum',
    smg     = '.45 ACP',
    rifle   = '5.56x45mm NATO',
    shotgun = '12 Gauge',
    mg      = '7.62x51mm NATO',
    sniper  = '.338 Lapua Magnum',
    heavy   = 'High Explosive',
    unknown = 'Tidak teridentifikasi',
}

local GROUPS = {
    [416676503]  = 'pistol',
    [3337201093] = 'smg',
    [970310034]  = 'rifle',
    [860033945]  = 'shotgun',
    [1159398588] = 'mg',
    [3082541095] = 'sniper',
    [2725924767] = 'heavy',
}

return {
    types = TYPES,
    calibers = CALIBERS,
    groups = GROUPS,
}
