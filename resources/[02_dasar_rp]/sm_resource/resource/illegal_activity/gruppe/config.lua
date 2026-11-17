return {
    item = {
        rewards = {
            {
                name = 'black_money',
                count = 514300
            },
            {
                name = 'gunpowder',
                count = { min = 15, max = 30 },
            }
        },
    },
    jobcheck = {
        police = 4,
        ems = 3
    },
    limit = {
        max = 3,
        cooldown = 30, -- menit
    },
    model = {
        guard = {
            's_m_m_prisguard_01'
        },
        truck = {
            'stockade'
        },
    },
    guard_weapon = {
        'weapon_carbinerifle',
        'weapon_assaultrifle',
        'weapon_specialcarbine'
    },
    cleanup = {
        fuse = 30,
        afterLoot = 20,
        afterExplode = 900,
        maxLifetime = 2700,
        deliverRadius = 20.0,
    },
    c4_mechanic = {
        maxFails = 2,
    },
    spawn = {
        minDistance = 50.0,
        maxDistance = 500.0,
        nodeRadius = 60.0,
        nodeTries = 12,
        regions = {
            kota = {
                vector4(905.7598, -801.7031, 43.5649, 216.5022),
                vector4(-186.6337, -1489.4663, 32.0534, 229.5074),
                vector4(-2985.5195, 103.6122, 14.2313, 44.1309),
                vector4(-735.8558, -364.0176, 35.0447, 334.4865),
                vector4(38.4583, -709.3126, 44.0705, 336.1524),
                vector4(-309.9859, 270.5146, 87.5889, 107.9195),
            },
            sandy = {
                vector4(901.7162, 3628.6497, 32.5908, 91.3745),
                vector4(2051.9727, 3747.7493, 32.5967, 211.8649),
                vector4(230.4221, 2992.6614, 42.5322, 3.2327),
            },
            paleto = {
                vector4(-321.5160, 6353.1504, 30.3230, 131.1497),
                vector4(1236.4209, 6478.5005, 20.7618, 87.3071),
                vector4(-577.3400, 5709.1035, 37.4756, 157.1397),
            },
        },
    },
    location = {
        truck_finish = {
            vector3(-46.37, -762.79, 32.82)
        }
    },
    lang = {
        arm = "Pasang C4 Bomb",
        loot = "Looting...",
        noc4 = "Kamu membutuhkan C4 bomb untuk meledakan truk!",
        c4_success = "C4 bomb berhasil dipasang!",
        c4_failed = "Gagal menggunakan C4 bomb!",
        c4_destroyed = "C4 bomb hancur setelah %s kali gagal!",
        minigame_failed = "Gagal memasang C4! Percobaan tersisa: ",
        blip_initial = "Truck Robbery Gruppe6",
        cop_notify = "Peringatan Darurat! Sinyal GPS truk bank hilang - sedang menyelidiki perampokan!",
        time_limit = "Kamu terlambat, truk berhasil dikirim dengan aman.",
        spawn_blocked = "Semua jalur truk Gruppe6 di sekitar sini sedang tertutup kendaraan. Coba lagi sebentar lagi atau pakai telepon umum lain!",
        no_spawn = "Tidak ada rute truk Gruppe6 di sekitar sini. Pindah dan telepon dari telepon umum lain (Kota / Sandy / Paleto)!",
    }
}