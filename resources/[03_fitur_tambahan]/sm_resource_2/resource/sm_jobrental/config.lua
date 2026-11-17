local MECHANIC_ZONE = { size = vec3(2.0, 2.0, 2.0), rotation = 159.02 }

---@param liveries number[]
---@return table[]
local function mechanicFleet(liveries)
    return {
        { model = 'flattemu', label = 'Mobil Towing', livery = liveries[1] },
        { model = 'derektemu', label = 'Mobil Derek', livery = liveries[2] },
        { model = 'kx450f', label = 'KLX450f', livery = liveries[3] },
        { model = 'smrapt', label = 'smrapt', livery = liveries[4] },
        { model = 'smspeedo', label = 'smspeedo', livery = liveries[5] },
    }
end

local YACHT = { { model = 'amels200', label = 'Yacht Amels 200', livery = 0 } }

return {
    pedModel = 'csb_customer',
    interactDistance = 2.5,
    useDistance = 6.0,
    spotRadius = 3.0,
    cooldown = 3000,
    points = {
        smmotel = {
            label = 'Kendaraan Hotel',
            jobs = { smmotel = 0 },
            peds = {
                { coords = vec4(-826.0991, -753.7076, 22.6567, 357.7037), label = 'Sewa Kendaraan Hotel', vehicles = { { model = 'kuruma', label = 'Mobil Kuruma', livery = 0 } } },
            },
            spawns = { { coords = vec4(-834.8690, -762.8048, 21.8140, 355.6526) } },
        },
        hightable = {
            label = 'Kendaraan Hightable',
            jobs = { hightable = 0 },
            peds = {
                {
                    coords = vec4(4975.9, -5753.56, 19.89, 348.29),
                    label = 'Sewa Kendaraan Darat',
                    vehicles = {
                        { model = 'mule2', label = 'mule2', livery = 0 },
                        { model = 'artisanlm', label = 'artisanlm', livery = 0, custom = { mods = { { 8, 0 } } } },
                        { model = 'caddy3', label = 'caddy3', livery = 0 },
                        { model = 'guardian', label = 'guardian', livery = 0 },
                        { model = 'phantomlimo', label = 'phantomlimo', livery = 0 },
                        { model = 'mansoryg63', label = 'mansoryg63', livery = 0 },
                        { model = 'yzfsm', label = 'yzfsm', livery = 0 },
                        { model = 'smw906', label = 'smw906', livery = -1, custom = { mods = { { 48, -1 } }, colours = { 12, 12 }, extra = { 12, 12 }, dashboard = 12, interior = 12, tint = 1 } },
                    },
                },
                {
                    coords = vec4(4875.69, -5727.88, 26.72, 238.82),
                    label = 'Sewa Helicopter',
                    vehicles = {
                        { model = 'supervolito2', label = 'Helicopter Hightable', livery = 0 },
                        { model = 'frogger', label = 'Frogger Hightable', livery = 0 },
                        { model = 'buzzard', label = 'Buzzard Hightable', livery = 0 },
                    },
                },
            },
            spawns = {
                { coords = vec4(4980.41, -5749.69, 19.61, 70.97), models = { 'smw906', 'mule2', 'artisanlm', 'caddy3', 'guardian', 'phantomlimo', 'mansoryg63', 'yzfsm', '23sprintl4' } },
                { coords = vec4(4890.0894, -5736.4873, 26.3509, 161.7073), models = { 'supervolito2', 'frogger', 'buzzard' } },
            },
        },
        resto = {
            label = 'Kendaraan Resto',
            jobs = { resto = 0 },
            peds = {
                { coords = vec4(-1715.19, -1127.08, 13.16, 61.12), vehicles = { { model = 'pcxresto', label = 'Motor PCX Resto', livery = 0 }, { model = 'tacotemu', label = 'Mobil Taco Resto', livery = 0 } } },
            },
            spawns = { { coords = vec4(-1713.59, -1119.53, 12.88, 138.64) } },
            platePrefix = 'Resto',
        },
        wartelsm = {
            label = 'Kendaraan wartel',
            jobs = { wartelsm = 0 },
            peds = {
                { coords = vec4(-767.9666, 5592.5225, 33.4858, 91.1476), vehicles = { { model = 'ygm', label = 'Mobil', livery = 1 }, { model = 'nmaxygm', label = 'Motor', livery = 1 } } },
            },
            spawns = { { coords = vec4(-777.8327, 5589.4390, 33.4859, 167.0413) } },
            platePrefix = 'WR',
        },
        velvetsm = {
            label = 'Kendaraan Velvet',
            jobs = { velvetsm = 0 },
            peds = {
                {
                    coords = vec4(906.9544, 8.9691, 78.7640, 142.0218),
                    vehicles = {
                        { model = 'smbw07', label = 'smbw07', livery = 0, grade = { 0, 4 } },
                        { model = 'vuli', label = 'vuli', livery = 0, grade = { 2, 4 } },
                        { model = 'smmr500', label = 'smmr500', livery = 0, grade = { 2, 4 } },
                    },
                },
            },
            spawns = { { coords = vec4(906.1302, 6.0641, 78.7640, 58.9973) } },
            platePrefix = 'VL',
        },
        banmeskota = {
            label = 'Kendaraan Banmes Kota',
            jobs = { banmeskota = 0 },
            peds = {
                { coords = vec4(1102.0553, -1514.2189, 34.8067, 337.2565), vehicles = { { model = 'sprintermedic', label = 'sprintermedic', livery = 0 }, { model = 'klxems', label = 'klxems', livery = 0 } } },
            },
            spawns = { { coords = vec4(1102.7098, -1511.0229, 34.1887, 269.3014) } },
        },
        mercenarysm = {
            label = 'Kendaraan Mercenary',
            jobs = { mercenarysm = 0 },
            peds = {
                {
                    coords = vec4(-1936.2913, 2852.1790, 32.8181, 57.3172),
                    label = 'Sewa Kendaraan Mercenary',
                    vehicles = {
                        { model = 'besra', label = 'besra', livery = 0 },
                        { model = 'b21raider', label = 'b21raider', livery = 0 },
                        { model = 'leo2pso', label = 'leo2pso', livery = 0 },
                        { model = 'mh6mm', label = 'mh6mm', livery = 0 },
                        { model = 'cv22', label = 'cv22', livery = 0 },
                        { model = 'sb1defiant', label = 'sb1defiant', livery = 0 },
                        { model = 'aw109', label = 'aw109', livery = 0 },
                        { model = 'hvriot2', label = 'hvriot2', livery = 0 },
                        { model = 'hvswatbuffalo4', label = 'hvswatbuffalo4', livery = 0 },
                    },
                },
                {
                    coords = vec4(-2772.3413, 2784.5820, 1.4122, 101.5532),
                    label = 'Sewa Kapal Mercenary',
                    vehicles = {
                        { model = 'patrolboat', label = 'patrolboat', livery = 0 },
                        { model = 'virginiassn', label = 'virginiassn', livery = 0 },
                        { model = 'avisa', label = 'avisa', livery = 0 },
                        { model = 'pt109', label = 'pt109', livery = 0 },
                        { model = 'serkot', label = 'serkot', livery = 0 },
                    },
                },
            },
            spawns = {
                { coords = vec4(-1978.7310, 2841.9519, 33.5813, 59.3140), models = { 'besra', 'b21raider', 'leo2pso', 'mh6mm', 'cv22', 'hvriot2', 'hvswatbuffalo4', 'sb1defiant', 'aw109' } },
                { coords = vec4(-3189.5703, 2723.1243, -0.4931, 274.4790), models = { 'patrolboat', 'virginiassn', 'avisa', 'pt109', 'serkot' } },
            },
        },
        pdcafe = {
            label = 'Kendaraan Paradise',
            jobs = { pdcafe = 0 },
            peds = {
                { coords = vec4(-1303.8003, 6946.7554, 20.5173, 166.1404), vehicles = { { model = 'pcxatom', label = 'Motor Atom', livery = 0 }, { model = 'tacotemu', label = 'Mobil Atom', livery = 5 } } },
            },
            spawns = { { coords = vec4(-1300.7593, 6942.0537, 20.3265, 169.4265) } },
            platePrefix = 'Atom',
        },
        gzcafe = {
            label = 'Kendaraan ECL Kedai',
            jobs = { gzcafe = 0 },
            peds = {
                { coords = vec4(-2165.9727, 4268.4380, 48.6632, 329.5384), vehicles = { { model = 'pcxygm', label = 'Motor PCX', livery = 0 }, { model = 'tacotemu', label = 'Mobil Taco', livery = 7 } } },
            },
            spawns = { { coords = vec4(-2155.8694, 4290.3218, 49.7704, 150.5907) } },
            platePrefix = 'GZ',
        },
        mhcafe = {
            label = 'Kendaraan Maison Rainhart Cafe',
            jobs = { mhcafe = 0 },
            peds = {
                { coords = vec4(-272.1789, 6637.5542, 7.5590, 136.5438), vehicles = { { model = 'pcxreinhart', label = 'Motor PCX Maison Rainhart', livery = 0 }, { model = 'tacotemu', label = 'Mobil Taco Maison Rainhart', livery = 6 } } },
            },
            spawns = { { coords = vec4(-274.7075, 6632.5132, 7.5591, 222.5834) } },
            platePrefix = 'MH',
        },
        paud = {
            label = 'Kendaraan School kids',
            jobs = { paud = 0 },
            peds = {
                { coords = vec4(389.2635, 3561.5720, 33.3223, 251.6963), vehicles = { { model = 'smtk', label = 'Kendaraan 1', livery = 0, custom = { colours = { 111, 111 }, extra = { 0, 111 } } } } },
            },
            spawns = { { coords = vec4(406.2163, 3544.7043, 33.6104, 359.9615) } },
            platePrefix = 'SMTK',
        },
        nightclub = {
            label = 'Kendaraan Maxclub',
            jobs = { nightclub = 0 },
            peds = {
                { coords = vec4(144.0862, -1290.4747, 29.3658, 299.4756), vehicles = { { model = 'smmaxg63', label = 'smmaxg63', livery = 0 }, { model = 'tacotemu', label = 'tacotemu', livery = 3 }, { model = 'pcxmax', label = 'pcxmax', livery = 3 } } },
            },
            spawns = { { coords = vec4(149.2515, -1283.6245, 28.7755, 207.1472) } },
            platePrefix = 'MAX',
        },
        luxurynightclub = {
            label = 'Kendaraan ECLUB',
            jobs = { luxurynightclub = 0 },
            peds = {
                { coords = vec4(61.0550, 6548.5742, 31.4443, 226.4235), vehicles = { { model = 'pcxyclub', label = 'pcxyclub', livery = 0 }, { model = 'tacotemu', label = 'tacotemu', livery = 4 }, { model = 'smmaxg63', label = 'smmaxg63', livery = 2 } } },
            },
            spawns = { { coords = vec4(68.6243, 6541.0708, 31.0681, 132.0598) } },
            platePrefix = 'ECLUB',
        },
        digitalden = {
            label = 'Kendaraan YGMCenter',
            jobs = { digitalden = 0 },
            peds = {
                { coords = vec4(-1336.8, -406.51, 36.49, 23.86), vehicles = { { model = 'ygm', label = 'ygm', livery = 0 }, { model = 'nmaxygm', label = 'nmaxygm', livery = 0 } } },
            },
            spawns = { { coords = vec4(-1341.63, -404.35, 36.02, 29.89) } },
            platePrefix = 'YGM',
        },
        digitaldenroxwood = {
            label = 'Kendaraan Digital Den Roxwood',
            jobs = { digitaldenroxwood = 0 },
            peds = {
                {
                    coords = vec4(-2920.5708, 6232.5356, 9.6174, 180.1803),
                    label = 'Sewa Kendaraan Digital Den',
                    vehicles = {
                        { model = 'ygm', label = 'Mobil', livery = 2, custom = { primary = 111 } },
                        { model = 'nmaxygm', label = 'Motor', livery = 2, custom = { primary = 111 } },
                    },
                },
            },
            spawns = { { coords = vec4(-2938.4055, 6224.2173, 10.1688, 103.4254) } },
            platePrefix = 'DDR',
        },
        burgenkcafe = {
            label = 'Kendaraan Burgenk Cafe',
            jobs = { burgenkcafe = 0 },
            peds = {
                { coords = vec4(1503.3251, 3767.2585, 34.1470, 213.5806), vehicles = { { model = 'pcxburgenk', label = 'Motor PCX Burgenk Cafe', livery = 0 }, { model = 'tacotemu', label = 'Mobil Taco Resto', livery = 2 } } },
            },
            spawns = { { coords = vec4(1498.3698, 3759.4194, 33.9250, 207.4989) } },
            platePrefix = 'BC',
        },
        kkpresto = {
            label = 'Kendaraan Resto',
            jobs = { kkpresto = 0 },
            peds = {
                { coords = vec4(-611.5975, -1086.3553, 22.1735, 0.0), vehicles = { { model = 'pcxkung', label = 'Motor PCX Resto', livery = 0 }, { model = 'tacotemu', label = 'Mobil Taco Resto', livery = 1 } } },
            },
            spawns = { { coords = vec4(-617.0079, -1083.6794, 21.9103, 358.3109) } },
            platePrefix = 'KKP',
        },
        gokudosm = {
            label = 'Mobil Dinas Gokudo',
            jobs = { gokudosm = 0 },
            peds = {
                {
                    coords = vec4(-856.0876, 7146.6704, 99.7499, 233.9236),
                    vehicles = {
                        { model = 'sm_gle63', label = 'Mercedes-AMG GLE63', livery = -1, grade = { 1, 5 }, custom = { mods = { { 48, -1 } }, colours = { 111, 34 }, extra = { 0, 156 }, tint = 1 } },
                    },
                },
                {
                    coords = vec4(353.4941, 7313.9980, 1.9938, 210.2982),
                    label = 'Sewa Kapal Gokudo',
                    vehicles = { { model = 'dinghy4', label = 'Dinghy', livery = 0 } },
                },
            },
            spawns = {
                { coords = vec4(-858.4362, 7149.6982, 99.7500, 323.1526), models = { 'sm_gle63' } },
                { coords = vec4(344.0121, 7294.5298, 0.0967, 134.7417), models = { 'dinghy4' } },
            },
        },
        mechanic = {
            label = 'Kendaraan Tekno',
            jobs = { mechanic = 0 },
            requireDuty = true,
            zone = { coords = vec3(-2229.168701, -422.276215, 13.586574), label = 'Sewa Kendaraan Tekno', size = MECHANIC_ZONE.size, rotation = MECHANIC_ZONE.rotation },
            vehicles = mechanicFleet({ 0, 0, 0, 0, 0 }),
            spawns = { { coords = vec4(-2221.77, -418.29, 13.41, 261.73) }, { coords = vec4(-2221.56, -423.56, 13.41, 264.11) } },
            platePrefix = 'TG',
        },
        maxspeedgarage = {
            label = 'Kendaraan MaxSpeedGarage',
            jobs = { maxspeedgarage = 0 },
            requireDuty = true,
            zone = { coords = vec3(-369.2, -105.8, 38.68), label = 'Sewa Kendaraan MaxSpeed', size = MECHANIC_ZONE.size, rotation = MECHANIC_ZONE.rotation },
            vehicles = mechanicFleet({ 2, 2, 2, 1, 1 }),
            spawns = { { coords = vec4(-370.79, -111.22, 38.41, 72.3) } },
            platePrefix = 'MSG',
        },
        stunberg = {
            label = 'Kendaraan stunberg',
            jobs = { stunberg = 0 },
            requireDuty = true,
            zone = { coords = vec3(-205.261749, 6234.273438, 31.337404), label = 'Sewa Kendaraan stunberg', size = MECHANIC_ZONE.size, rotation = MECHANIC_ZONE.rotation },
            vehicles = mechanicFleet({ 4, 4, 4, 3, 3 }),
            spawns = { { coords = vec4(-202.5718, 6225.5498, 30.9568, 42.5170) } },
            platePrefix = 'SG',
        },
        mechanic969 = {
            label = 'Kendaraan 969Garages',
            jobs = { mechanic969 = 0 },
            requireDuty = true,
            zone = { coords = vec3(1217.2, 2641.05, 38.5), label = 'Sewa Kendaraan 969Garages', size = MECHANIC_ZONE.size, rotation = MECHANIC_ZONE.rotation },
            vehicles = mechanicFleet({ 3, 3, 3, 2, 2 }),
            spawns = { { coords = vec4(1212.64, 2652.16, 37.54, 359.53) } },
            platePrefix = '969Garages',
        },
        kkpgarage = {
            label = 'Kendaraan KKPGarage',
            jobs = { kkpgarage = 0 },
            requireDuty = true,
            zone = { coords = vec3(1359.791260, -2086.363037, 52.229610), label = 'Sewa Kendaraan KKPGarage', size = MECHANIC_ZONE.size, rotation = MECHANIC_ZONE.rotation },
            vehicles = {
                { model = 'kx450f', label = 'KLX450f', livery = 6 },
                { model = 'smrapt', label = 'smrapt', livery = 5 },
            },
            spawns = { { coords = vec4(1359.1635, -2097.5303, 51.9989, 213.7972) } },
            platePrefix = 'KKPG',
        },
        pabrik = {
            label = 'Kendaraan Sumber Rezeki',
            jobs = { pabrik = 0 },
            peds = {
                {
                    coords = vec4(229.0365, 1162.1576, 225.4685, 290.3850),
                    vehicles = {
                        { model = 'vuli', label = 'Mobil', livery = 0, grade = { 3, 6 }, custom = { colours = { 12, 95 }, extra = { 0, 120 }, dashboard = 38, interior = 42, xenon = 0, toggles = { 22 } } },
                        { model = 'nissantitan17', label = 'Mobil2', livery = 1, grade = { 3, 6 } },
                        { model = 'adv1502023', label = 'Motor', livery = 0, grade = { 0, 6 }, custom = { mods = { { 0, 0 }, { 3, 0 } }, colours = { 38, 131 } } },
                    },
                },
            },
            spawns = { { coords = vec4(232.3942, 1172.0646, 225.1903, 281.1404) } },
            platePrefix = 'SR',
            plateDigits = 6,
            keepOnDrop = true,
        },
        reporter = {
            label = 'Helicopter',
            jobs = { reporter = 0 },
            peds = {
                { coords = vec4(-288.8022, -624.8228, 50.3265, 0.0), vehicles = { { model = 'newsmav', label = 'Heli SM', livery = 0 } } },
            },
            spawns = { { coords = vec4(-286.2129, -618.4710, 50.7297, 0.4799) } },
            platePrefix = 'SM',
        },
        government = {
            label = 'Helicopter',
            jobs = { government = 0, paspampres = 0 },
            peds = {
                {
                    coords = vec4(-451.26, 1136.36, 327.62, 28.22),
                    vehicles = {
                        { model = 'negfrogger', label = 'Heli frogger', livery = 0, jobs = { government = { grade = { 13, 13 } }, paspampres = { grade = { 4, 10 } } } },
                        { model = 'awpmrnth', label = 'Heli Gov', livery = 0, jobs = { government = { grade = { 11, 12 } }, paspampres = { grade = { 9, 10 } } } },
                        { model = 'sh3', label = 'Heli Gov 2', livery = 0, jobs = { government = { grade = { 11, 12 } } } },
                    },
                },
            },
            spawns = { { coords = vec4(-456.18, 1144.11, 328.02, 342.58) } },
            platePrefix = { government = 'GOV', paspampres = 'PAS' },
        },
        usmsdoj = {
            label = 'US Marshall',
            jobs = { usmarshal = 0, pengadilan = 0 },
            peds = {
                {
                    coords = vec4(276.5554, -346.7037, 44.9198, 247.9172),
                    vehicles = {
                        { model = 'usmheli1', label = 'USMS|DOJ Heli 1', livery = 0, jobs = { usmarshal = { items = { 'badgeheliusms', 'badgehighcommandusms' } }, pengadilan = {} } },
                        { model = 'MH6M', label = 'USMS|DOJ Heli 2', livery = 0, jobs = { usmarshal = { items = { 'badgeheliusms', 'badgehighcommandusms' } }, pengadilan = {} } },
                    },
                },
            },
            spawns = { { coords = vec4(289.5070, -339.1286, 44.9198, 163.7610) } },
            platePrefix = 'USDOJ',
        },
        yacht_roels = {
            label = 'Kapal Yatch Roels',
            cid = true,
            peds = { { coords = vec4(2971.8630, 435.2852, 2.6842, 94.5051), vehicles = YACHT } },
            spawns = { { coords = vec4(3009.0156, 434.5408, 2.8027, 286.3268) } },
            platePrefix = 'ROELS',
        },
        yacht_haji969 = {
            label = 'Kapal Yatch Pak Haji 969',
            cid = true,
            peds = { { coords = vec4(-3671.4915, 3850.8218, 14.7670, 266.0548), vehicles = YACHT } },
            spawns = { { coords = vec4(-3208.8850, 3525.5134, -0.4747, 47.5435) } },
            platePrefix = 'H969',
        },
        yacht_komax = {
            label = 'Kapal Yatch Ko Max',
            cid = true,
            peds = { { coords = vec4(-3351.2178, 1762.3988, 34.1583, 225.8634), vehicles = YACHT } },
            spawns = { { coords = vec4(-3439.3042, 1794.1427, -0.4748, 144.6172) } },
            platePrefix = 'KMAX',
        },
        yacht_moscow = {
            label = 'YATCH MOSCOW GARNER',
            cid = true,
            peds = { { coords = vec4(-3180.6978, 2333.9197, 3.3226, 261.6798), vehicles = YACHT } },
            spawns = { { coords = vec4(-3167.6328, 2312.9248, 0.4475, 91.8554) } },
            platePrefix = 'DNT',
        },
        yacht_mikhayla = {
            label = 'YATCH Mikhayla',
            cid = true,
            peds = { { coords = vec4(-3174.8733, 2335.1672, 3.3226, 185.2799), vehicles = YACHT } },
            spawns = { { coords = vec4(-3167.6328, 2312.9248, 0.4475, 91.2799) } },
            platePrefix = 'MKH',
        },
        yacht_donatur = {
            label = 'YATCH DONATUR',
            cid = true,
            peds = { { coords = vec4(-1615.1033, 5260.9521, 3.9741, 202.5961), vehicles = YACHT } },
            spawns = { { coords = vec4(-1678.8464, 5248.3774, -0.0341, 97.5742) } },
            platePrefix = 'DNT',
        },
    },
}
