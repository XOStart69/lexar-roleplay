return {
    npcs = {
        {
            model = 'a_m_m_business_01',
            coords = vector4(-778.85, -1294.59, 5.0, 261.1),
            scenario = 'WORLD_HUMAN_CLIPBOARD'
        }
    },
    exchanges = {
        {
            id = 'voucher_peredakeram',
            label = 'Tukar Voucher Pereda Keram',
            description = 'Tukar barang untuk mendapatkan Voucher Pereda Keram',
            requiredItems = {
                { item = 'coupon_a', amount = 2, label = 'Coupon A' },
                { item = 'coupon_b', amount = 2, label = 'Coupon B' }
            },
            rewardItem = {
                item = 'voucher_peredakeram',
                amount = 1,
                label = 'Voucher Pereda Keram'
            },
            progressDuration = 3000,
            progressLabel = 'Menukar barang...'
        },
        {
            id = 'craft_coupon_a',
            label = 'Crafting Bahan Disnaker',
            description = '50 Homemade Milk menjadi 1 voucher A',
            requiredItems = {
                { item = 'homemademilk', amount = 50, label = 'Homemade Milk' }
            },
            rewardItem = {
                item = 'coupon_a',
                amount = 1,
                label = 'Coupon A'
            },
            progressDuration = 5000,
            progressLabel = 'Crafting coupon...'
        },
        {
            id = 'craft_coupon_b',
            label = 'Crafting Bahan Disnaker',
            description = '350 Drum Oil menjadi 1 voucher B',
            requiredItems = {
                { item = 'drum_oil', amount = 350, label = 'Drum Oil' }
            },
            rewardItem = {
                item = 'coupon_b',
                amount = 1,
                label = 'Coupon B'
            },
            progressDuration = 5000,
            progressLabel = 'Crafting coupon...'
        }
    },
    interactionDistance = 5.0,
    cooldownTime = 2000,
    menuTitle = 'MENGURANGI 12 JAM KERAM ANDA',
    messages = {
        waitCooldown = 'Tunggu sebentar sebelum menukar lagi',
        invalidExchange = 'Penukaran tidak valid',
        tooFarFromNPC = 'Anda terlalu jauh dari NPC',
        itemNotEnough = 'Anda membutuhkan lebih banyak coupon',
        itemInsufficient = 'Item tidak mencukupi',
        exchangeSuccess = 'Anda mendapatkan %dx %s',
        exchangeCancelled = 'Penukaran barang dibatalkan'
    }
}