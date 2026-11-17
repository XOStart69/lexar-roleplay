---@class PartConfig
---@field name string
---@field label string
---@field item string
---@field amount integer jumlah item per perbaikan
---@field distance number jarak (meter) untuk satu tick keausan
---@field wear number pengurangan persen tiap tick
---@field threshold number batas persen sebelum efek negatif aktif
---@field order integer urutan tampil di UI
---@field anim { dict: string, clip: string, flag: integer? }? animasi saat ganti part, kosong = config.RepairAnim

---@class ZoneArea
---@field coords vector3 titik pusat untuk validasi jarak di server
---@field thickness number tinggi area poly
---@field points vector3[] titik sudut area

---@class ZoneConfig
---@field job string
---@field label string
---@field grade integer grade minimum untuk memperbaiki
---@field areas ZoneArea[] satu bengkel bisa punya beberapa area terpisah

local config = {}

config.BlockedCategories = {
    cycles = true,
    boats = true,
    helicopters = true,
    planes = true
}

config.AllowedClasses = {
    [0] = true,
    [1] = true,
    [2] = true,
    [3] = true,
    [4] = true,
    [5] = true,
    [6] = true,
    [7] = true,
    [8] = true,
    [9] = true,
    [10] = true,
    [11] = true,
    [12] = true,
    [17] = true,
    [18] = true,
    [19] = true,
    [20] = true,
    [22] = true
}

config.Jobs = {
    mechanic = true,
    maxspeedgarage = true,
    mechanic969 = true,
    stunberg = true,
    kkpgarage = true
}

config.RepairDistance = 8.0
config.ZoneRadius = 12.0

config.AdminGroups = {
    'god',
    'admin'
}

config.TickInterval = 500
config.EffectInterval = 1500
config.SyncInterval = 10000

config.RepairDuration = 12000

config.InspectRange = 6.0

config.InspectAnim = {
    dict = 'anim@amb@carmeet@checkout_engine@',
    clip = 'female_c_idle_d'
}

config.RepairAnim = {
    dict = 'mini@repair',
    clip = 'fixing_a_ped',
    flag = 1
}

config.MinSpeedMs = 8.0
config.BodyImpact = 5.0
config.MinEngineHealth = 150.0

---@type table<string, PartConfig>
config.Parts = {
    brakes = {
        name = 'brakes',
        label = 'Brakes',
        item = 'brake_parts',
        amount = 1,
        distance = 0,
        wear = 0.00875,
        threshold = 50.0,
        order = 1,
        anim = { dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', clip = 'machinic_loop_mechandplayer', flag = 1 },
        description = 'Vehicle will be less stable',
        effect = 'Pengereman menurun drastis'
    },
    clutch = {
        name = 'clutch',
        label = 'Clutch',
        item = 'clutch_parts',
        amount = 1,
        distance = 900,
        wear = 0.125,
        threshold = 50.0,
        order = 2,
        anim = { dict = 'amb@world_human_vehicle_mechanic@male@base', clip = 'base', flag = 1 },
        description = 'Vehicle will lose acceleration',
        effect = 'Akselerasi melemah'
    },
    engine = {
        name = 'engine',
        label = 'Engine',
        item = 'engine_parts',
        amount = 1,
        distance = 1200,
        wear = 0.125,
        threshold = 50.0,
        order = 3,
        anim = { dict = 'mini@repair', clip = 'fixing_a_ped', flag = 1 },
        description = 'Vehicle will lose top speed',
        effect = 'Top speed menurun'
    },
    body = {
        name = 'body',
        label = 'Body',
        item = 'body_parts',
        amount = 1,
        distance = 2000,
        wear = 0.0875,
        threshold = 50.0,
        order = 4,
        anim = { dict = 'mini@repair', clip = 'fixing_a_player', flag = 1 },
        description = 'Vehicle will smoke faster on impact',
        effect = 'Lebih cepat berasap saat menabrak'
    }
}

---@type string[] urutan tetap agar loop numerik dan sinkron client/server
config.PartOrder = { 'brakes', 'clutch', 'engine', 'body' }

config.Penalty = {
    brakes = 0.85,
    clutch = 0.85,
    engine = 0.70,
    body = 1.5
}

config.PenaltyBase = {
    brakes = 0.35,
    clutch = 0.40,
    engine = 0.25,
    body = 0.0
}

---@type ZoneConfig[]
config.Zones = {
    {
        job = 'mechanic',
        label = 'Tekno Garage',
        grade = 1,
        areas = {
            {
                coords = vec3(-2255.9440, -416.9460, 13.0),
                thickness = 5.55,
                points = {
                    vec3(-2261.2700195312, -418.60000610352, 13.0),
                    vec3(-2260.5200195312, -413.23999023438, 13.0),
                    vec3(-2250.7199707031, -414.45001220703, 13.0),
                    vec3(-2251.2099609375, -419.44000244141, 13.0),
                    vec3(-2256, -419, 13.0),
                }
            },
            {
                coords = vec3(-2254.9219, -408.9120, 13.0),
                thickness = 5.95,
                points = {
                    vec3(-2259.6499023438, -410.35998535156, 13.0),
                    vec3(-2259.3999023438, -405.54998779297, 13.0),
                    vec3(-2249.919921875, -406.75, 13.0),
                    vec3(-2250.4899902344, -411.26000976562, 13.0),
                    vec3(-2255.1499023438, -410.64001464844, 13.0),
                }
            },
            {
                coords = vec3(-2253.8240, -401.1100, 13.0),
                thickness = 5.35,
                points = {
                    vec3(-2258.4699707031, -402.60000610352, 13.0),
                    vec3(-2258.0600585938, -397.7799987793, 13.0),
                    vec3(-2249.1398925781, -398.92001342773, 13.0),
                    vec3(-2249.3999023438, -403.42001342773, 13.0),
                    vec3(-2254.0500488281, -402.82998657227, 13.0),
                }
            },
            {
                coords = vec3(-2253.0860, -393.1940, 13.0),
                thickness = 5.25,
                points = {
                    vec3(-2257.5, -394.5, 13.0),
                    vec3(-2257.2900390625, -390.10998535156, 13.0),
                    vec3(-2248.5200195312, -390.92001342773, 13.0),
                    vec3(-2249.2199707031, -395.44000244141, 13.0),
                    vec3(-2252.8999023438, -395, 13.0),
                }
            },
            {
                coords = vec3(-2252.2820, -385.2300, 13.0),
                thickness = 6.15,
                points = {
                    vec3(-2256.5100097656, -386.79998779297, 13.0),
                    vec3(-2256.3601074219, -381.7200012207, 13.0),
                    vec3(-2247.4799804688, -382.64999389648, 13.0),
                    vec3(-2247.9399414062, -387.70001220703, 13.0),
                    vec3(-2253.1201171875, -387.2799987793, 13.0),
                }
            },
        }
    },
    {
        job = 'maxspeedgarage',
        label = 'Max Speed',
        grade = 1,
        areas = {
            {
                coords = vec3(-309.51000976562, -133.63999938965, 39.0),
                thickness = 5.0,
                points = {
                    vec3(-309.51000976562, -133.63999938965, 39.0),
                    vec3(-311.51998901367, -137.80000305176, 39.0),
                    vec3(-318.92999267578, -135.05999755859, 39.0),
                    vec3(-317.35000610352, -131.10000610352, 39.0),
                    vec3(-317.0, -131.0, 39.0),
                }
            },
            {
                coords = vec3(-313.64001464844, -143.86000061035, 39.0),
                thickness = 5.0,
                points = {
                    vec3(-313.64001464844, -143.86000061035, 39.0),
                    vec3(-315.75, -148.21000671387, 39.0),
                    vec3(-323.39001464844, -145.58000183105, 39.0),
                    vec3(-321.75, -141.0, 39.0),
                    vec3(-317.69000244141, -142.30000305176, 39.0),
                }
            },
            {
                coords = vec3(-317.70999145508, -154.53999328613, 39.0),
                thickness = 5.0,
                points = {
                    vec3(-317.70999145508, -154.53999328613, 39.0),
                    vec3(-319.32000732422, -159.77000427246, 39.0),
                    vec3(-327.64001464844, -156.55000305176, 39.0),
                    vec3(-325.67001342773, -151.82000732422, 39.0),
                    vec3(-321.07000732422, -153.52000427246, 39.0),
                }
            },
        }
    },
    {
        job = 'mechanic969',
        label = '969 Garage',
        grade = 1,
        areas = {
            {
                coords = vec3(1195.7080, 2627.3260, 38.0),
                thickness = 5.5,
                points = {
                    vec3(1197.3199462891, 2624.7099609375, 38.0),
                    vec3(1193.2399902344, 2624.5200195312, 38.0),
                    vec3(1193.3599853516, 2630.5, 38.0),
                    vec3(1197.1700439453, 2630.4799804688, 38.0),
                    vec3(1197.4499511719, 2626.419921875, 38.0),
                }
            },
            {
                coords = vec3(1201.7500, 2627.3180, 38.0),
                thickness = 4,
                points = {
                    vec3(1203.2600097656, 2624.3000488281, 38.0),
                    vec3(1199.6800537109, 2624.2900390625, 38.0),
                    vec3(1199.5899658203, 2630.3898925781, 38.0),
                    vec3(1203.0699462891, 2630.1101074219, 38.0),
                    vec3(1203.1500244141, 2627.5, 38.0),
                }
            },
            {
                coords = vec3(1207.6960, 2627.3940, 38.0),
                thickness = 5.15,
                points = {
                    vec3(1209.2399902344, 2624.7099609375, 38.0),
                    vec3(1205.4799804688, 2624.6298828125, 38.0),
                    vec3(1205.4499511719, 2630.0600585938, 38.0),
                    vec3(1209.0899658203, 2630.1000976562, 38.0),
                    vec3(1209.2199707031, 2627.4699707031, 38.0),
                }
            },
            {
                coords = vec3(1213.7320, 2627.5560, 38.0),
                thickness = 5.15,
                points = {
                    vec3(1215.0799560547, 2625, 38.0),
                    vec3(1211.6500244141, 2625, 38.0),
                    vec3(1211.6700439453, 2630.1101074219, 38.0),
                    vec3(1214.9300537109, 2630.2399902344, 38.0),
                    vec3(1215.3299560547, 2627.4299316406, 38.0),
                }
            },
        }
    },
    {
        job = 'stunberg',
        label = 'Stunberg Garage',
        grade = 1,
        areas = {
            {
                coords = vec3(-254.6220, 6243.8980, 32.0),
                thickness = 4.7,
                points = {
                    vec3(-259.55999755859, 6245.8598632812, 32.0),
                    vec3(-255.61999511719, 6249.6801757812, 32.0),
                    vec3(-249.00999450684, 6242.7099609375, 32.0),
                    vec3(-253, 6239, 32.0),
                    vec3(-255.91999816895, 6242.240234375, 32.0),
                }
            },
            {
                coords = vec3(-248.3200, 6250.3341, 32.0),
                thickness = 4.65,
                points = {
                    vec3(-253.2799987793, 6252.2202148438, 32.0),
                    vec3(-249.10000610352, 6255.8999023438, 32.0),
                    vec3(-242.58000183105, 6249.4702148438, 32.0),
                    vec3(-246.66999816895, 6245.330078125, 32.0),
                    vec3(-249.9700012207, 6248.75, 32.0),
                }
            },
            {
                coords = vec3(-242.0080, 6256.7800, 32.0),
                thickness = 4,
                points = {
                    vec3(-247.17999267578, 6258.8798828125, 32.0),
                    vec3(-243.00999450684, 6262.990234375, 32.0),
                    vec3(-235.88999938965, 6255.759765625, 32.0),
                    vec3(-240.39999389648, 6251.6000976562, 32.0),
                    vec3(-243.55999755859, 6254.669921875, 32.0),
                }
            },
            {
                coords = vec3(-235.3520, 6263.0320, 32.0),
                thickness = 4.7,
                points = {
                    vec3(-240.44000244141, 6264.830078125, 32.0),
                    vec3(-236.13000488281, 6268.8701171875, 32.0),
                    vec3(-229.52000427246, 6262.0400390625, 32.0),
                    vec3(-233.72999572754, 6258.2700195312, 32.0),
                    vec3(-236.94000244141, 6261.1499023438, 32.0),
                }
            },
            {
                coords = vec3(-229.0860, 6269.2920, 32.0),
                thickness = 4,
                points = {
                    vec3(-234.88000488281, 6271.7202148438, 32.0),
                    vec3(-230.61999511719, 6276.3798828125, 32.0),
                    vec3(-222.80999755859, 6268.4399414062, 32.0),
                    vec3(-227.24000549316, 6263.759765625, 32.0),
                    vec3(-229.88000488281, 6266.16015625, 32.0),
                }
            },
        }
    },
    {
        job = 'kkpgarage',
        label = 'KKP Garage',
        grade = 0,
        areas = {
            {
                coords = vec3(1384.7717, -2069.3562, 52.0022),
                thickness = 5.0,
                points = {
                    vec3(1385.0500488281, -2072.8898925781, 52.0),
                    vec3(1381.1800537109, -2068.3500976562, 52.0),
                    vec3(1384.3699951172, -2065.75, 52.0),
                    vec3(1388.1899414062, -2070.2099609375, 52.0),
                    vec3(1386.3499755859, -2071.7900390625, 52.0),
                }
            },
            {
                coords = vec3(1390.2891, -2063.5720, 52.0022),
                thickness = 5.0,
                points = {
                    vec3(1390.9799804688, -2067.5, 52.0),
                    vec3(1387.1199951172, -2063.1298828125, 52.0),
                    vec3(1390.3299560547, -2060.6499023438, 52.0),
                    vec3(1393.7399902344, -2065.0300292969, 52.0),
                    vec3(1392.5999755859, -2066.2600097656, 52.0),
                }
            },
            {
                coords = vec3(1400.9591, -2072.4268, 52.0017),
                thickness = 5.0,
                points = {
                    vec3(1396.1999511719, -2073.919921875, 52.0),
                    vec3(1401.6899414062, -2069.3500976562, 52.0),
                    vec3(1403.6199951172, -2072.8500976562, 52.0),
                    vec3(1398.8699951172, -2076.7199707031, 52.0),
                    vec3(1397.4899902344, -2075.3400878906, 52.0),
                }
            },
            {
                coords = vec3(1390.3416, -2082.0583, 52.0016),
                thickness = 5.0,
                points = {
                    vec3(1393.5200195312, -2082.6999511719, 52.0),
                    vec3(1390.7600097656, -2085.0500488281, 52.0),
                    vec3(1387.0899658203, -2080.6499023438, 52.0),
                    vec3(1389.6300048828, -2078.3701171875, 52.0),
                    vec3(1392.1899414062, -2081.1298828125, 52.0),
                }
            },
        }
    }
}

return config
