local giveDesc = 'Tekan [G] untuk memberikan ke player terdekat\nTekan [X] untuk membatalkan'

return {
    items = {
        nk_propgacha_mn1 = {
            label = 'Minion Bob',
            prop = 'nk_propgacha_mn1',
            boneIndex = 24817,
            pos = vec(-0.10, 0.46, -0.016),
            rot = vec(-180.00, -90.00, 0.00),
            animation = {
                dict = 'impexp_int-0',
                anim = 'mp_m_waremech_01_dual-0',
                flag = 51
            },
            infoUI = {
                title = 'Minion Bob',
                description = giveDesc
            }
        },
        nk_propgacha_mn2 = {
            label = 'Minion Stuart',
            prop = 'nk_propgacha_mn2',
            boneIndex = 24817,
            pos = vec(-0.10, 0.46, -0.016),
            rot = vec(-180.00, -90.00, 0.00),
            animation = {
                dict = 'impexp_int-0',
                anim = 'mp_m_waremech_01_dual-0',
                flag = 51
            },
            infoUI = {
                title = 'Minion Stuart',
                description = giveDesc
            }
        },
        nk_propgacha_mn3 = {
            label = 'Minion Kevin',
            prop = 'nk_propgacha_mn3',
            boneIndex = 24817,
            pos = vec(-0.10, 0.46, -0.016),
            rot = vec(-180.00, -90.00, 0.00),
            animation = {
                dict = 'impexp_int-0',
                anim = 'mp_m_waremech_01_dual-0',
                flag = 51
            },
            infoUI = {
                title = 'Minion Kevin',
                description = giveDesc
            }
        },
        nk_propgacha_lf = {
            label = 'Kimbi',
            prop = 'nk_propgacha_lf',
            boneIndex = 24817,
            pos = vec(-0.10, 0.46, -0.016),
            rot = vec(-180.00, -90.00, 0.00),
            animation = {
                dict = 'impexp_int-0',
                anim = 'mp_m_waremech_01_dual-0',
                flag = 51
            },
            infoUI = {
                title = 'Kimbi',
                description = giveDesc
            }
        },
        nk_propgacha_nf = {
            label = 'Kimba',
            prop = 'nk_propgacha_nf',
            boneIndex = 24817,
            pos = vec(-0.10, 0.46, -0.016),
            rot = vec(-180.00, -90.00, 0.00),
            animation = {
                dict = 'impexp_int-0',
                anim = 'mp_m_waremech_01_dual-0',
                flag = 51
            },
            infoUI = {
                title = 'Kimba',
                description = giveDesc
            }
        },
    },
    giveDistance = 3.0,
    giveKeybind = 'G',
    cancelKeybind = 'X',
    alertTimeout = 10000,
    messages = {
        noPlayerNearby = 'Tidak ada player di dekatmu!',
        requestSent = 'Permintaan dikirim ke %s',
        requestReceived = '%s ingin memberikanmu %s',
        requestAccepted = '%s menerima permintaanmu (%s)',
        requestRejected = '%s menolak permintaanmu (%s)',
        requestExpired = 'Permintaan sudah kadaluarsa',
        cannotGiveToSelf = 'Kamu tidak bisa memberikan kepada diri sendiri!',
        alreadyHasRequest = 'Player tersebut sedang menerima permintaan lain',
        giftReceived = 'Kamu menerima %s dari %s',
        inventoryFull = 'Inventory kamu penuh!',
        itemCancelled = 'Item disimpan kembali'
    }
}
