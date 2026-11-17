return {
    items = {
        rose_valentine = {
            label = 'Rose',
            prop = 'prop_single_rose',
            bone = 18905,
            placement = { 0.13, 0.15, 0.0, -100.0, 0.0, -20.0 },
            animation = {
                dict = 'anim@heists@humane_labs@finale@keycards',
                anim = 'ped_a_enter_loop',
                flag = 51
            },
            infoUI = {
                title = 'Rose',
                description = 'Tekan [G] untuk memberikan rose ke player terdekat\nTekan [X] untuk membatalkan'
            }
        },
        bouquet_valentine = {
            label = 'Bouquet',
            prop = 'prop_snow_flower_02',
            bone = 60309,
            placement = { 0.11, -0.13, 0.12, -18.7186, 121.0529, -11.7724 },
            animation = {
                dict = 'hold_flowers@dad',
                anim = 'hold_flowers_clip',
                flag = 51
            },
            infoUI = {
                title = 'Bouquet',
                description = 'Tekan [G] untuk memberikan bouquet ke player terdekat\nTekan [X] untuk membatalkan'
            }
        },
        bouquet2_valentine = {
            label = 'Bouquet 2',
            prop = 'pata_freevalentinesday3',
            bone = 28422,
            placement = { -0.01, 0.03, -0.17, -6.0697, 60.1852, 3.4934 },
            animation = {
                dict = 'hold_flowers@dad',
                anim = 'hold_flowers_clip',
                flag = 51
            },
            infoUI = {
                title = 'Bouquet',
                description = 'Tekan [G] untuk memberikan bouquet ke player terdekat\nTekan [X] untuk membatalkan'
            }
        }
    },
    giveDistance = 3.0,
    giveKeybind = 'G',
    cancelKeybind = 'X',
    alertTimeout = 10000, -- 10 seconds
    messages = {
        noPlayerNearby = 'Tidak ada player di dekatmu!',
        requestSent = 'Permintaan dikirim',
        requestReceived = 'sesorang ingin memberikanmu sebuah hadiah',
        requestAccepted = 'menerima permintaanmu',
        requestRejected = 'menolak permintaanmu',
        requestExpired = 'Permintaan sudah kadaluarsa',
        cannotGiveToSelf = 'Kamu tidak bisa memberikan kepada diri sendiri!',
        alreadyHasRequest = 'Player tersebut sedang menerima permintaan lain',
        giftReceived = 'Kamu menerima hadiah',
        inventoryFull = 'Inventory kamu penuh!',
        itemCancelled = 'Item dibatalkan'
    }
}