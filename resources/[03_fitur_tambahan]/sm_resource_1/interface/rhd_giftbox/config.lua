local config = {}

config.PrepareDB = true
config.EmptyGiftBoxItem = 'empty_giftbox'
config.GiftBoxItem = 'giftbox'
config.GiftBoxNotesItem = 'giftbox_notes'
config.MaxSlots = 16
config.MaxNoteLength = 420
config.PackCost = 50000

config.ForbiddenPackItems = {
    [config.EmptyGiftBoxItem] = true,
    [config.GiftBoxItem] = true,
    [config.GiftBoxNotesItem] = true,
    money = true,
    red_money = true,
    black_money = true,

    backpack = true,
    backpackstandar = true,
    backpackdewa = true,

    --attachments
    at_clip_extended_pistol = true,
    at_clip_extended_smg = true,
    at_suppressor_light = true,
    at_suppressor_heavy = true,

    -- Drugs
    cocaine = true,
    meth = true,
    joint = true,
    k2narko = true,
    blueparadise = true,
    packaged_meth = true,
    crystalmeth = true,
    daunkokain = true,
    packaged_cocaine = true,
    ganja = true,
    packaged_ganja = true,

    blue_paradise_package = true,
    k2_package = true,
    --ammo
    ["ammo-untraceable"] = true,
    ["ammo-9"] = true,
    ["ammo-38"] = true,
    ["ammo-12"] = true,
    ["ammo-44"] = true,
    ["ammo-45"] = true,
    ["ammo-rifle"] = true,
    ["ammo-50"] = true,
    ["ammo-rifle2"] = true,
    ["ammo-shotgun"] = true,
    ["ammo-pistol"] = true,
    pistol_ammo = true,
    ["ammo-9karet"] = true,
    ["ammo-sniper"] = true,

    --misc/crafting
    blueprint = true,
    blackprint = true,
    gunhandle = true,
    spring = true,
    rolling_paper = true,
    gunpowder = true,
    trojan_usb = true,
    advancedlockpick = true,
    torture_kit = true,
    lockpick = true,
    drill = true,
    thermite = true,

    pipe_bomb = true,
    backdoor_kit = true,
    laptop_pink = true,
    laptop_gold = true,
    laptop_malware = true,
    rusty_drill = true,
    at_clip_extended_rifle = true,
    security_card = true,
    security_card_01 = true,
    security_card_02 = true,
    harness = true,
    racing_tablet = true,
    fakeplate = true,
    race_chip = true,
    code_injector = true,
    armor = true,
    armorroxwood = true,
    boxstarterpack = true,
}

config.BlockDegradable = false       -- Allow any item that is configured to degrade in ox_inventory
config.BlockWithDurability = false   -- Allow any item that has durability/decay metadata
config.MaxPackQuantity = 20         -- Global maximum quantity per item slot in a gift box
config.CustomPackLimits = {         -- Per-item custom quantity limits
    bandage = 10,
}

config.Drop = {
    tableName = 'rhd_giftbox_drops',
    placeDistance = 1.35,
    interactDistance = 1.5,
    streamDistance = 50.0,
    pickupTimeout = 15000,
}

config.CarryControls = {
    putBack = 322, -- ESC
    drop = 38, -- E
    give = 47, -- G
}

config.PropsData = {
    carry = {
        props = {
            model = 'bzzz_prop_gift_orange',
            bone = 60309,
            position = {
                vec3(0.018, 0.039, 0.116),
                vec3(-82.41, -157.58, -27.67),
            }
        },
        animation = {
            dict = 'hold_flowers@dad',
            clip = 'hold_flowers_clip',
            flag = 51
        }
    },
    packing = {
        props = {
            model = 'bzzz_prop_gift_orange',
            coords = vec3(-1273.520386, -1136.398193, 5.785041),
            heading = 30.0776,
        },
        target = {
            coords = vec3(-1273.520386, -1136.398193, 5.785041),
            label = 'Pack Gift Box',
            distance = 1.5,
            zoneRadius = 0.5,
            -- groups = 'admin'
        },
        progressBar = {
            label = 'Packing Gift Box',
            duration = 5000,
            useWhileDead = false,
            canCancel = true,
        }
    },
    opening = {
        anim = {
            dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
            clip = 'machinic_loop_mechandplayer',
            flag = 41
        },
        progressBar = {
            label = 'Opening Gift Box',
            duration = 5000,
            useWhileDead = false,
            canCancel = true,
        }
    }
}

return config