local cfg = {} ---@type Drugsell_Config

cfg.start = {
    ped = 'CSB_Ramp_gang',
    coords = vec(174.3394, 2219.6729, 90.7262, 140.1111),
    requiredJob = {
        police = 1,
        ems = 1
    },
}

cfg.drugsItem = {
    { item = 'packaged_meth',    weight = 20 },
    { item = 'packaged_ganja',   weight = 20 },
    { item = 'packaged_cocaine', weight = 60 },
}

cfg.roxwoodDrugsItem = {
    { item = 'blue_paradise_package', weight = 50 },
    { item = 'k2_package',            weight = 50 },
}

cfg.customer_ped = {
    'a_m_y_business_01',
    'a_m_y_business_02',
}

cfg.maxPeds = 6
cfg.spawnInterval = 3000
cfg.despawnDistance = 80.0
cfg.chancePoliceAlert = 0.2

cfg.marker = {
    drawDistance = 30.0,
    height = 1.0,
    size = { x = 0.25, y = 0.25, z = 0.2 },
    color = { r = 0, g = 200, b = 255, a = 180 },
    type = 2,
}

cfg.selling = {
    price = {
        min = 6000,
        max = 10000,
        jackpot = 20000
    },
    maxSell = 10,
    scammer_chance = 0.1
}

return cfg