local config = {}

config.adminAce = 'admin'

config.payment = {
    purchase = 'bank',
    finance = 'bank',
    methods = { 'cash', 'bank' },
}

config.defaults = {
    commissionRate = 30,
    selfServiceRate = 80,
}

config.purchesable_shop = {
    enable = false,
    price = 9000000
}

config.limits = {
    maxCommissionRate = 90,
    minSelfServiceRate = 10,
    maxSelfServiceRate = 100,
    maxEmployees = 15,
    maxFinanceAmount = 1000000,
    minShopName = 3,
    maxShopName = 32,
    maxRoles = 8,
    minRoleName = 2,
    maxRoleName = 24,
    invoiceTimeout = 60,
    selfServiceTimeout = 600,
    cutDuration = 8000,
    logPageSize = 8,
    maxPageSize = 20,
    recentLogsLimit = 9,
    topEmployeeDays = 30,
    topEmployeeLimit = 9,
}

config.permissions = {
    { key = 'duty', label = 'Mulai shift dan melayani' },
    { key = 'portable', label = 'Pasang kursi cukur' },
    { key = 'logs', label = 'Lihat riwayat layanan' },
    { key = 'finance', label = 'Lihat keuangan dan setor' },
    { key = 'withdraw', label = 'Tarik saldo' },
    { key = 'prices', label = 'Atur harga' },
    { key = 'hire', label = 'Rekrut karyawan' },
    { key = 'fire', label = 'Pecat karyawan' },
    { key = 'setRole', label = 'Ubah role karyawan' },
    { key = 'settings', label = 'Ganti nama toko' },
    { key = 'supplies', label = 'Beli perlengkapan' },
}

config.roles = {
    { key = 'barber', label = 'Barber', permissions = { 'duty', 'portable', 'logs' } },
    { key = 'manager', label = 'Manajer', permissions = { 'duty', 'portable', 'logs', 'finance', 'hire', 'fire', 'supplies' } },
}

config.priceGroups = {
    { id = 'hair', label = 'Hair', min = 5000, max = 6000 },
    { id = 'beard', label = 'Beard', min = 4000, max = 5000 },
    { id = 'eyebrows', label = 'Eyebrows', min = 500, max = 1000 },
    { id = 'eyeColor', label = 'Eye colour', min = 5000, max = 6000 },
    { id = 'makeUp', label = 'Make up', min = 1000, max = 2000 },
    { id = 'blush', label = 'Blush', min = 500, max = 800 },
    { id = 'lipstick', label = 'Lipstick', min = 1000, max = 2500 },
    { id = 'blemishes', label = 'Blemishes', min = 500, max = 800 },
    { id = 'ageing', label = 'Ageing', min = 500, max = 800 },
    { id = 'complexion', label = 'Complexion', min = 500, max = 800 },
    { id = 'sunDamage', label = 'Sun damage', min = 500, max = 800 },
    { id = 'moleAndFreckles', label = 'Moles and freckles', min = 500, max = 800 },
    { id = 'chestHair', label = 'Chest hair', min = 1000, max = 2500 },
    { id = 'bodyBlemishes', label = 'Body blemishes', min = 500, max = 800 },
}

config.priceItems = {
    { key = 'hair.style', group = 'hair', label = 'Style' },
    { key = 'hair.texture', group = 'hair', label = 'Texture', includedWith = 'hair.style' },
    { key = 'hair.fade', group = 'hair', label = 'Fade' },
    { key = 'hair.color', group = 'hair', label = 'Colour' },
    { key = 'hair.highlight', group = 'hair', label = 'Highlight' },
    { key = 'beard.style', group = 'beard', label = 'Style' },
    { key = 'beard.color', group = 'beard', label = 'Colour' },
    { key = 'beard.opacity', group = 'beard', label = 'Opacity' },
    { key = 'eyebrows.style', group = 'eyebrows', label = 'Style' },
    { key = 'eyebrows.color', group = 'eyebrows', label = 'Colour' },
    { key = 'eyebrows.opacity', group = 'eyebrows', label = 'Opacity' },
    { key = 'eyeColor', group = 'eyeColor', label = 'Colour' },
    { key = 'makeUp.style', group = 'makeUp', label = 'Style' },
    { key = 'makeUp.color', group = 'makeUp', label = 'Colour' },
    { key = 'makeUp.secondColor', group = 'makeUp', label = 'Second colour' },
    { key = 'makeUp.opacity', group = 'makeUp', label = 'Opacity' },
    { key = 'blush.style', group = 'blush', label = 'Style' },
    { key = 'blush.color', group = 'blush', label = 'Colour' },
    { key = 'blush.secondColor', group = 'blush', label = 'Second colour' },
    { key = 'blush.opacity', group = 'blush', label = 'Opacity' },
    { key = 'lipstick.style', group = 'lipstick', label = 'Style' },
    { key = 'lipstick.color', group = 'lipstick', label = 'Colour' },
    { key = 'lipstick.secondColor', group = 'lipstick', label = 'Second colour' },
    { key = 'lipstick.opacity', group = 'lipstick', label = 'Opacity' },
    { key = 'blemishes.style', group = 'blemishes', label = 'Style' },
    { key = 'blemishes.opacity', group = 'blemishes', label = 'Opacity' },
    { key = 'ageing.style', group = 'ageing', label = 'Style' },
    { key = 'ageing.opacity', group = 'ageing', label = 'Opacity' },
    { key = 'complexion.style', group = 'complexion', label = 'Style' },
    { key = 'complexion.opacity', group = 'complexion', label = 'Opacity' },
    { key = 'sunDamage.style', group = 'sunDamage', label = 'Style' },
    { key = 'sunDamage.opacity', group = 'sunDamage', label = 'Opacity' },
    { key = 'moleAndFreckles.style', group = 'moleAndFreckles', label = 'Style' },
    { key = 'moleAndFreckles.opacity', group = 'moleAndFreckles', label = 'Opacity' },
    { key = 'chestHair.style', group = 'chestHair', label = 'Style' },
    { key = 'chestHair.color', group = 'chestHair', label = 'Colour' },
    { key = 'chestHair.opacity', group = 'chestHair', label = 'Opacity' },
    { key = 'bodyBlemishes.style', group = 'bodyBlemishes', label = 'Style' },
    { key = 'bodyBlemishes.opacity', group = 'bodyBlemishes', label = 'Opacity' },
}

config.chairModels = {
    'v_serv_bs_barbchair3',
    'v_serv_bs_barbchair5',
    'v_serv_bs_barbchair2',
    'v_serv_bs_barbchair',
    'm25_2_int_01_barber_chair',
    'v_ilev_hd_chair',
}

config.chairDistance = 1.2
config.counterRadius = 0.8

config.items = {
    scissors = 'barber_scissors',
    chair = 'barber_chair',
}

config.supplies = {
    { item = 'barber_scissors', label = 'Gunting Cukur', image = 'scissors.png', price = 5000, maxQuantity = 1, uses = 3 },
    { item = 'barber_chair', label = 'Kursi Cukur', image = 'barber_chair.png', price = 10000, maxQuantity = 1, uses = 3 },
}

config.portable = {
    model = 'v_serv_bs_barbchair',
    animation = 'barbers',
    limit = 1,
    reach = 3.0,
    spacing = 1.5,
    renderDistance = 60.0,
}

config.scene = {
    headingOffset = -90.0,
    exitPhase = 0.5,
}

config.animation = {
    scissors = 'p_cs_scissors_s',
    sets = {
        barbers = {
            dict = 'misshair_shop@barbers',
            keeper = 's_f_m_fembarber',
            seated = { 'player_base' },
            cutting = { 'keeper_idle_a', 'keeper_idle_b' },
        },
        hairdressers = {
            dict = 'misshair_shop@hair_dressers',
            keeper = 's_m_m_hairdress_01',
            seated = { 'player_idle_a', 'player_idle_b', 'player_idle_c' },
            cutting = { 'keeper_hair_cut_a', 'keeper_hair_cut_b' },
        },
    },
}

config.blip = { sprite = 71, color = 0, scale = 0.7, category = 38, categoryLabel = 'Barber Shop' }

config.shops = {
    {
        id = 'davis',
        label = 'Barbershop Davis',
        coords = {
            management = vec3(134.312851, -1708.580322, 29.271952),
            pedspawn = vec4(138.2039, -1703.8553, 29.2916, 200.2262),
            chairs = {
                vector4(139.3318939209, -1708.0994873047, 28.318195343018, 45.000034332275),
                vector4(138.36465454102, -1709.2521972656, 28.318195343018, 50.000022888184),
                vector4(137.39752197266, -1710.4047851563, 28.318195343018, 50.000022888184),
            },
        },
    },
    {
        id = 'vespucci',
        label = 'Barbershop Vespucci',
        coords = {
            management = vec3(-1284.730469, -1115.417847, 6.970455),
            pedspawn = vec4(-1279.0623, -1115.7048, 6.9901, 124.8787),
            chairs = {
                vector4(-1281.283203125, -1119.0698242188, 6.0166993141174, 355.0),
                vector4(-1282.7879638672, -1119.0698242188, 6.0166993141174, 360.0),
                vector4(-1284.2926025391, -1119.0698242188, 6.0166993141174, 360.0),
            },
        }
    },
    {
        id = 'sandy',
        label = 'Barbershop Sandy Shores',
        coords = {
            management = vec3(1931.319580, 3727.710205, 32.824780),
            pedspawn = vec4(1928.1686, 3732.8433, 32.8444, 260.8316),
            chairs = {
                vector4(1932.5445556641, 3732.5104980469, 31.871026992798, 115.021484375),
                vector4(1933.2973632813, 3731.2075195313, 31.871026992798, 120.02146911621),
                vector4(1934.0501708984, 3729.9047851563, 31.871026992798, 120.02146911621),
            },
        },
    },
    {
        id = 'mirrorpark',
        label = 'Barbershop Mirror Park',
        coords = {
            management = vector3(1210.844482, -470.609161, 66.188385),
            pedspawn = vector4(1216.5450, -472.3705, 66.2080, 118.8353),
            chairs = {
                vector4(1213.3612060547, -474.95257568359, 65.23462677002, 339.99926757813),
                vector4(1211.9077148438, -474.56311035156, 65.23462677002, 344.99923706055),
                vector4(1210.4543457031, -474.17367553711, 65.23462677002, 344.99923706055),
            },
        }
    },
    {
        id = 'hawick',
        label = 'Barbershop Hawick',
        coords = {
            management = vector3(-30.643845, -151.060837, 57.056858),
            pedspawn = vector4(-32.7311, -156.5567, 57.0765, 24.7287),
            chairs = {
                vector4(-35.245048522949, -153.19590759277, 56.103103637695, 245.00004577637),
                vector4(-34.730388641357, -151.78189086914, 56.103103637695, 250.00003051758),
                vector4(-34.215789794922, -150.36804199219, 56.103103637695, 250.00003051758),
            },
        }
    },
    -- {
    --     id = 'paleto',
    --     label = 'Barbershop Paleto Bay',
    --     coords = {
    --         management = vector3(-278.423889, 6230.856445, 31.675865),
    --         pedspawn = vector4(-274.4786, 6226.4609, 31.6955, 87.4103),
    --         chairs = {
    --             vector4(-278.4602355957, 6225.7895507813, 30.722108840942, 310.2463684082),
    --             vector4(-279.52883911133, 6226.8491210938, 30.722108840942, 315.2463684082),
    --             vector4(-280.59729003906, 6227.908203125, 30.722108840942, 315.2463684082),
    --         },
    --     }
    -- },
    
    {
        id = 'roxwood',
        label = 'Barbershop Roxwood',
        coords = {
            management = vector3(85.69, 7893.23, 6.74),
            pedspawn = vector4(86.1998, 7899.0259, 5.7583, 218.7163),
            chairs = {
                vector4(89.17, 7893.56, 5.78, 88.00),
                vector4(89.22, 7895.07, 5.78, 88.00),
                vector4(89.28, 7896.57, 5.78, 83.00),
            },
        }
    },
    {
        id = 'rockford',
        label = 'Barbershop Rockford Hills',
        animation = 'hairdressers',
        coords = {
            management = vector3(-822.410095, -184.177994, 37.702660),
            pedspawn = vector4(-809.1055, -180.5050, 37.5689, 126.8326),         
            chairs = {
                vector4(-812.75811767578, -180.97079467773, 36.569408416748, 209.99996948242),
                vector4(-814.49017333984, -181.97079467773, 36.569408416748, 209.99996948242),
                vector4(-816.22216796875, -182.97079467773, 36.569408416748, 209.99996948242),
                vector4(-817.95422363281, -183.97079467773, 36.569408416748, 209.99996948242),
            },
        },
    },
}

return config
