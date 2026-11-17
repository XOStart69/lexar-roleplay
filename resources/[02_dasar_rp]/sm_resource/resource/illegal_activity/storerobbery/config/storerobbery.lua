return {
    requiredJob = {
        police = 5,
        ems = 3,
    },
    requiredItem = 'advancedlockpick',
    itemMechanic = {
        maxFails = 2,           -- 2x gagal = item rusak (destroyed)
        removeOnSuccess = true, -- berhasil = item hilang
    },
    reward = {
        cash_register = {
            black_money = 1198250,
        },
        bonus = {
            item = 'motherboard_gps',
            min = 1,
            max = 3,
            chance = 50,
        },
        safe = {
            black_money = 1198250,
        },
        -- Computer: trojan_usb chance hoki, zonk system
        computer = {
            lucky = {
                item = 'trojan_usb',
                max = 2,
                chance = 25, -- 25% chance per attempt to get trojan_usb
            },
            zonk = {
                { item = 'gunpowder', min = 5,      max = 7 },
                { item = 'gunhandle', min = 7,      max = 20 },
                { item = 'red_money', min = 100000, max = 100000 },
            }
        },
    },
    robberyLimit = {
        max = 2,
        time = 60,
        unit = 'menit',
    },
    maxTry = {
        safe = 3,
        computer = 3,
    },
    locations = require 'resource.illegal_activity.storerobbery.data.defaultlocation',
}
