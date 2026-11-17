return {
    NPC = {
        coords = vector4(-779.33, -1297.93, 4.0, 255.77),
        model = 's_m_m_armoured_01',
        name = 'MENAMBAH KAPASITAS TAS ANDA',
        scenario = 'WORLD_HUMAN_CLIPBOARD',
    },

    Settings = {
        defaultWeight = 50000,
        enableLevelCheck = false,
        enableDebug = false,
        enableNPCAnimation = true,
        targetDistance = 2.0,
        targetIcon = 'fas fa-briefcase',
        targetLabel = 'Berbicara..',
    },

    CraftingRecipes = {
        bahan_tas = {
            label = 'Bahan Tas',
            description = 'Bahan dasar untuk membuat tas',
            ingredients = {
                { item = 'recycle_package', amount = 100, label = 'Recycle Package' },
            },
            output = { item = 'bahan_tas', amount = 1 },
        },
        patchwork = {
            label = 'Patchwork Tas',
            description = 'Jahitan untuk memperkuat tas',
            ingredients = {
                { item = 'clothes', amount = 100, label = 'Clothes' },
            },
            output = { item = 'patchwork', amount = 1 },
        },
        kerangka_tas = {
            label = 'Kerangka Tas',
            description = 'Struktur dasar tas',
            ingredients = {
                { item = 'packaged_plank', amount = 100, label = 'Packaged Plank' },
            },
            output = { item = 'kerangka_tas', amount = 1 },
        },
        aksesoris_tas = {
            label = 'Aksesoris Tas',
            description = 'Aksesoris pelengkap tas',
            ingredients = {
                { item = 'clean_stone', amount = 100, label = 'Clean Stone' },
            },
            output = { item = 'aksesoris_tas', amount = 1 },
        },
        pelumas_tas = {
            label = 'Pelumas Tas',
            description = 'Pelumas untuk resleting dan aksesoris',
            ingredients = {
                { item = 'drum_oil', amount = 100, label = 'Drum Oil' },
            },
            output = { item = 'pelumas_tas', amount = 1 },
        },
    },

    Upgrades = {
        [60000] = {
            label = 'Level 1: Upgrade tas ke 60kg',
            description = 'Tingkatkan kapasitas tas menjadi 60kg',
            cost = {
                money = 25000,
                items = {
                    { item = 'bahan_tas',     amount = 5, label = 'Bahan Tas' },
                    { item = 'patchwork',     amount = 5, label = 'Patchwork Tas' },
                    { item = 'kerangka_tas',  amount = 5, label = 'Kerangka Tas' },
                    { item = 'aksesoris_tas', amount = 5, label = 'Aksesoris Tas' },
                    { item = 'pelumas_tas',   amount = 5, label = 'Pelumas Tas' },
                },
            },
            requiredLevel = 0,
            requiredUpgrade = 0,
        },
        [70000] = {
            label = 'Level 2: Upgrade tas ke 70kg',
            description = 'Tingkatkan kapasitas tas menjadi 70kg (Harus punya Level 1)',
            cost = {
                money = 50000,
                items = {
                    { item = 'bahan_tas',     amount = 8, label = 'Bahan Tas' },
                    { item = 'patchwork',     amount = 8, label = 'Patchwork Tas' },
                    { item = 'kerangka_tas',  amount = 8, label = 'Kerangka Tas' },
                    { item = 'aksesoris_tas', amount = 8, label = 'Aksesoris Tas' },
                    { item = 'pelumas_tas',   amount = 8, label = 'Pelumas Tas' },
                },
            },
            requiredLevel = 0,
            requiredUpgrade = 60000,
        },
        [75000] = {
            label = 'Level 3: Upgrade tas ke 75kg',
            description = 'Tingkatkan kapasitas tas maksimal menjadi 75kg (Harus punya Level 2)',
            cost = {
                money = 100000,
                items = {
                    { item = 'bahan_tas',     amount = 13, label = 'Bahan Tas' },
                    { item = 'patchwork',     amount = 13, label = 'Patchwork Tas' },
                    { item = 'kerangka_tas',  amount = 13, label = 'Kerangka Tas' },
                    { item = 'aksesoris_tas', amount = 13, label = 'Aksesoris Tas' },
                    { item = 'pelumas_tas',   amount = 13, label = 'Pelumas Tas' },
                },
            },
            requiredLevel = 0,
            requiredUpgrade = 70000,
        },
    },

    Messages = {
        upgradeSuccess           = 'Tas berhasil di-upgrade ke %skg',
        upgradeNotAvailable      = 'Upgrade tidak tersedia',
        alreadyHaveUpgrade       = 'Kamu sudah punya kapasitas yang sama atau lebih besar',
        notEnoughMoney           = 'Uang tidak cukup. Butuh $%s',
        notEnoughItem            = 'Item %s tidak cukup. Butuh %s',
        levelTooLow              = 'Level kamu terlalu rendah. Butuh level %s',
        failedMoney              = 'Gagal memotong uang',
        failedItem               = 'Gagal mengambil item %s',
        currentCapacity          = 'Kapasitas tas kamu: %skg',
        menuTitle                = 'Upgrade Kapasitas Tas',
        checkCapacityTitle       = 'Cek Kapasitas Saat Ini',
        checkCapacityDesc        = 'Lihat kapasitas tas kamu sekarang',
        craftingMenuTitle        = 'Crafting Bahan Tas',
        craftingMenuDesc         = 'Buat bahan-bahan untuk upgrade tas',
        craftSuccess             = 'Berhasil membuat %s',
        requiresPreviousUpgrade  = 'Harus punya upgrade %skg terlebih dahulu',
    },
}