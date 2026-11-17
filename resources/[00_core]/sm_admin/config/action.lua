local action = {}

local isServer = lib.context == 'server'
local webhook = isServer and require 'private.webhook' or {}
local IA = isServer and require 'private.identifierAccess' or {}

---@type table<string, ActionData>
action.admin = {
    admin_car = {
        label = 'Admin Car',
        icon = 'fas fa-car',
        localServerEvent = 'sm_admin:saveCurrentVehicle',
        serverLog = {
            enable = true,
            webhook = webhook.admincarplate,
            title = 'Admin Car',
            description = 'Spawned an admin car from the admin menu',
            color = 'vehicle',
            -- onlyFor = IA.log
        },
        onlyFor = IA.accessadmincar,
        dropdown = {
            { label = 'Garage', type = 'select', data = 'garages', required = true }
        }
    },
    give_car = {
        label = 'Give Car',
        icon = 'fas fa-car',
        localServerEvent = 'sm_admin:giveVehicle',
        serverLog = {
            enable = true,
            webhook = webhook.vehicle,
            title = 'Give Car',
            description = 'Gave a vehicle to a player from the admin menu',
            color = 'vehicle',
            onlyFor = IA.log
        },
        onlyFor = IA.access,
        restrictedFor = {
            {
                identifiers = {
                    "steam:11000015f3b0057", -- eca
                },
                allowedModels = {
                    "pbfl5nfs",
                    "sm1evolady",
                }
            },
            {
                identifiers = {
                    "steam:11000015619c5f0", -- Kyo
                    "steam:11000015d81fdf7", -- Renata
                },
                allowedModels = {
                    "pbacuranfs",
                    "smidolrrstech",
                }
            },
            {
                identifiers = {
                    "steam:11000014a6055be", -- Lopez
                },
                allowedModels = {
                    "21trxsuv",
                    "yzfsm",
                    "fj402",
                    "cvo",
                    "amge60",
                    "artisanlm",
                    "pajieluo",
                    "indian",
                }
            },
        },
        dropdown = {
            { label = 'Model', type = 'select', data = 'vehicles', required = true },
            { label = 'Plate', type = 'text' },
            { label = 'Garage', type = 'select', data = 'garages', required = true },
            { label = 'PlayerId', type = 'number', required = true, min = 1, default = 1 },
            { label = 'Rata kanan', type = 'checkbox' , default = false }
        }
    },
    delete_vehicle_fromdb = {
        label = 'Delete vehicle from DB',
        icon = 'fas fa-trash',
        localServerEvent = 'sm_admin:deltevehFromDB',
        serverLog = {
            enable = true,
            webhook = webhook.allaction,
            title = 'Delete Vehicle From Database',
            description = 'Deleted a player vehicle from the database',
            color = 'vehicle',
            onlyFor = IA.log
        },
        onlyFor = IA.access,
        dropdown = {
            { label = 'Plate', type = 'text' },
        }
    },
    setjob = {
        label = 'Set Job',
        icon = 'fas fa-briefcase',
        localServerEvent = 'sm_admin:setjob',
        perms = 'admin',
        dropdown = {
            { label = 'Player Id', type = 'number', default = 1, min = 1, required = true },
            { label = 'Job', type = 'select', data = 'jobs', default = 'unemployed', required = true },
            { label = 'Job Grade', type = 'select', data = 'job_grades', dependsOn = 'job', required = true }
        }
    },
    transfer_vehicle = {
        label = 'Transfer Vehicle',
        icon = 'fas fa-car',
        localServerEvent = 'sm_admin:transferVehicle',
        serverLog = {
            enable = true,
            webhook = webhook.transveh,
            title = 'Transfer Vehicle',
            description = 'Transferred a vehicle to a player from the admin menu',
            color = 'vehicle',
            onlyFor = IA.log
        },
        onlyFor = IA.access,
        dropdown = {
            { label = 'Plate', type = 'text' },
            { label = 'PlayerId', type = 'number', required = true, min = 1, default = 1 }
        }
    },
    migrasi_garasi = {
        label = 'Garage Migration',
        icon = 'fas fa-warehouse',
        localServerEvent = 'sm_admin:migrasiGarasi',
        serverLog = {
            enable = true,
            webhook = webhook.allaction,
            title = 'Garage Migration',
            description = 'Migrated a player garage',
            color = 'vehicle',
        },
        onlyFor = IA.accessmigrasi,
        dropdown = {
            { label = 'Old Garage', type = 'select', data ='garages', required = true},
            { label = 'New Garage', type = 'select', data ='garages', required = true},
        }
    },
    giveitem = {
        label = 'Give Item',
        icon = 'fas fa-hand-holding',
        perms = 'god',
        localServerEvent = 'sm_admin:giveItem',
        args = false,
        serverLog = {
            enable = true,
            webhook = webhook.items,
            title = 'Give Item',
            description = 'Gave an item to a player',
            color = 'inventory',
        },
        restrictedFor = {
            {
                identifiers = {
                    "steam:11000015f3b0057", -- eca
                },
                allowedItems = {
                    "jpx_dj_headears",
                    "jpx_popstar_melody_doll",
                    "jpx_zoe_ears",
                    "jpx_fortune_wings",
                    --baru
                    "jpx_kuromi_plushie",
                    "jpx_kuromi_headband",
                    "jpx_cinnamoroll_headwear",
                    "jpx_cinnamoroll_drink",
                }
            },
            {
                identifiers = {
                    "steam:1100001132c31b9", -- simmon
                    "steam:11000015d81fdf7", -- renata
                    "steam:11000015619c5f0", -- kyo
                },
                allowedItems = {
                    "box_merdeka",
                }
            },
            {
                identifiers = {
                    "steam:11000010c53414e", -- kings
                },
                allowedItems = {
                    "racing_tablet",
                    "race_access",
                    "harness",
                    "fakeplate",
                    "advancedrepairkit",
                    "tirerepairkit",
                    "cleaningkit",
                    "radiator",
                    "nitrous",
                    "copper",
                    "tirekit",
                    "obdadapter",
                    "ecurepair",
                    "ecu_stage1",
                    "ecu_stage2",
                    "ecu_stage3",
                    "ecu_antilagflash",
                    "ecu_downpipe",
                    "ecu_straightpipe",
                    "ecu_muffler",
                    "ecu_intercooler",
                    "ecu_airfilter",
                    "ecu_turbo",
                    "ecu_gearflash",
                }
            },
        },
        dropdown = {
            { label = 'PlayerId', type = 'number', required = true, default = 1, min = 1 },
            { label = 'Item', type = 'select', required = true, data = 'items' },
            { label = 'Amount', type = 'number', required = true, default = 1, min = 1 }
        }
    },
    giveitemtoall = {
        label = 'Give Item To All',
        icon = 'fas fa-hand-holding',
        perms = 'god',
        localServerEvent = 'sm_admin:giveItem',
        args = true,
        serverLog = {
            enable = true,
            webhook = webhook.items,
            title = 'Give Item',
            description = 'Gave an item to a player',
            color = 'inventory',
        },
        dropdown = {
            { label = 'Item', type = 'select', required = true, data = 'items' },
            { label = 'Amount', type = 'number', required = true, default = 1, min = 1 }
        }
    },
    removeitem = {
        label = 'Remove Item',
        icon = 'fas fa-trash-can',
        perms = 'god',
        localServerEvent = 'sm_admin:removeitem',
        args = false,
        serverLog = {
            enable = true,
            webhook = webhook.items,
            title = 'Remove Item',
            description = 'Removed an item from a player',
            color = 'inventory',
        },
        dropdown = {
            { label = 'PlayerId', type = 'number', required = true, default = 1, min = 1 },
            { label = 'Item', type = 'select', required = true, data = 'items' },
            { label = 'Amount', type = 'number', required = true, default = 1, min = 1 }
        }
    },
    removeitemtoall = {
        label = 'Remove Item From All',
        icon = 'fas fa-trash-can',
        perms = 'god',
        localServerEvent = 'sm_admin:removeitem',
        args = true,
        serverLog = {
            enable = true,
            webhook = webhook.items,
            title = 'Remove Item',
            description = 'Removed an item from all players',
            color = 'inventory',
        },
        dropdown = {
            { label = 'Item', type = 'select', required = true, data = 'items' },
            { label = 'Amount', type = 'number', required = true, default = 1, min = 1 }
        }
    },
    give_money = {
        label = 'Give Money',
        icon = 'fas fa-money-bill-wave',
        -- perms = 'god',
        serverLog = {
            enable = true,
            webhook = webhook.money,
            title = 'Give Money',
            description = 'Gave money to a player',
            color = 'money',
        },
        onlyFor = IA.accessduit,
        localServerEvent = 'sm_admin:giveMoney',
        args = false,
        dropdown = {
            { label = 'PlayerId', type = 'number', required = true, default = 1, min = 1 },
            { label = 'Money Type', type = 'select', required = true, data = {
                    { label = 'Cash', value = 'cash' },
                    { label = 'Bank', value = 'bank' }
                }
            },
            { label = 'Amount', type = 'number', required = true, default = 1000, min = 1 }
        }
    },
    tuningmin = {
        label = 'Tuning Menu',
        icon = 'fas fa-wrench',
        perms = 'admin',
        command = 'tuningmin',
        closeOnExecute = true
    },
    give_money_to_all = {
        label = 'Give Money To All',
        icon = 'fas fa-money-bill-wave',
        perms = 'god',
        serverLog = {
            enable = true,
            webhook = webhook.money,
            title = 'Give Money To All',
            description = 'Gave money to all players',
            color = 'money',
        },
        localServerEvent = 'sm_admin:giveMoney',
        args = true,
        dropdown = {
            { label = 'Money Type', type = 'select', required = true, data = {
                    { label = 'Cash', value = 'cash' },
                    { label = 'Bank', value = 'bank' }
                }
            },
            { label = 'Amount', type = 'number', required = true, default = 1000, min = 1 }
        }
    },
    open_stash = {
        label = 'Open Stash',
        icon = 'fas fa-box',
        perms = 'admin',
        closeOnExecute = true,
        localServerEvent = 'sm_admin:openStash',
        dropdown = {
            { label = 'Stash ID', type = 'text', required = true }
        }
    },
    open_trunk = {
        label = 'Open Trunk',
        icon = 'fas fa-car-side',
        perms = 'admin',
        closeOnExecute = true,
        localServerEvent = 'sm_admin:openTrunk',
        dropdown = {
            { label = 'Plate', type = 'text', required = true }
        }
    },
    revive_all = {
        label = 'Revive All',
        icon = 'fas fa-heartbeat',
        perms = 'admin',
        serverLog = {
            enable = true,
            webhook = webhook.allaction,
            title = 'Revive All',
            description = 'Revived every player on the server',
            color = 'admin',
        },
        localServerEvent = 'sm_admin:reviveAll',
        canExecute = function (options, args)
            local alert = lib.alertDialog({
                header = '',
                content = 'Apakah kamu yakin mau revive semua player?',
                centered = true,
                cancel = true,
                labels = {
                    confirm = 'Ya',
                    cancel = 'Batalkan'
                }
            })

            return alert == 'confirm'
        end,
    },
    maxmods = {
        label = 'Max vehicle mods',
        icon = 'fas fa-wrench',
        perms = 'admin',
        localFunction = 'maxmods'
    },
    maxperformance = {
        label = 'Max performance + harness',
        icon = 'fas fa-gauge-high',
        perms = 'admin',
        localFunction = 'maxperformance',
        serverLog = {
            enable = true,
            webhook = webhook.allaction,
            title = 'Max Performance',
            description = 'Applied full vehicle mods and installed a harness',
            color = 'vehicle',
            onlyFor = IA.log
        }
    },
    setfuel = {
        label = 'Set vehicle fuel',
        icon = 'fas fa-gas-pump',
        perms = 'admin',
        localFunction = 'setFuel',
        dropdown = {
            { label = 'New Fuel', type = 'number', min = 1, max = 100, required = true, default = 1 }
        }
    },
    toggleDuty = {
        label = 'Toggle Duty',
        icon = 'fas fa-briefcase',
        perms = 'admin',
        serverEvent = 'QBCore:ToggleDuty'
    },
    toggleNoclip = {
        label = 'Toggle Noclip',
        icon = 'fas fa-magic-wand-sparkles',
        perms = 'admin',
        localFunction = 'toggleNoclip'
    },
    toggleName = {
        label = 'Toggle Player Name',
        icon = 'fas fa-user',
        perms = 'admin',
        localFunction = 'toggleName'
    },
    toggelBlips = {
        label = 'Toggle Player Blips',
        icon = 'fas fa-user',
        -- perms = 'admin',
        onlyFor = IA.acessblip,
        localFunction = 'toggleBlips'
    },
    toggleCuff = {
        label = 'Toggle Cuff',
        icon = 'fas fa-handcuffs',
        perms = 'admin',
        localServerEvent = 'sm_admin:toggleCuff',
        dropdown = {
            { label = 'PlayerId', type = 'number', required = true, min = 1, default = 1 }
        }
    },
    toggleLaser = {
        label = 'Toggle Laser',
        icon = 'fas fa-code',
        perms = 'admin',
        localFunction = 'toggleLaser',
    },
    invicible = {
        label = 'Invicible',
        icon = 'fas fa-ghost',
        perms = 'admin',
        localFunction = 'toggleInvisible',
    },
    setammo = {
        label = 'Set Ammo',
        icon = 'fas fa-gun',
        perms = 'admin',
        localFunction = 'setAmmo',
        dropdown = {
            { label = 'Ammo', type = 'number', required = true, min = 0, default = 1 }
        }
    },
    setWeather = {
        label = 'Set Weather',
        icon = 'fas fa-cloud',
        perms = 'admin',
        localServerEvent = 'sm_admin:setWeather',
        dropdown = {
            { label = 'Weather', type = 'select', required = true, data = {
                { label = 'Blizzard', value = 'BLIZZARD' },
                { label = 'Clear', value = 'CLEAR' },
                { label = 'Clearing', value = 'CLEARING' },
                { label = 'Clouds', value = 'CLOUDS' },
                { label = 'Extra Sunny', value = 'EXTRASUNNY' },
                { label = 'Foggy', value = 'FOGGY' },
                { label = 'Neutral', value = 'NEUTRAL' },
                { label = 'Overcast', value = 'OVERCAST' },
                { label = 'Rain', value = 'RAIN' },
                { label = 'Smog', value = 'SMOG' },
                { label = 'Snow', value = 'SNOW' },
                { label = 'Snowlight', value = 'SNOWLIGHT' },
                { label = 'Thunder', value = 'THUNDER' },
                { label = 'Xmas', value = 'XMAS' },
                { label = 'HALLOWEEN', value = 'HALLOWEEN' }
            }}
        }
    },
    setTime = {
        label = 'Set Time',
        icon = 'fas fa-cloud',
        perms = 'admin',
        localServerEvent = 'sm_admin:setTime',
        dropdown = {
            { label = 'Hours', type = 'number', default = 12, min = 0, max = 24 },
            { label = 'Minutes', type = 'number', default = 0, min = 0, max = 59 }
        }
    },
    setPed = {
        label = 'Set Player Model',
        icon = 'fas fa-user',
        perms = 'admin',
        localServerEvent = 'sm_admin:setPlayerModel',
        dropdown = {
            { label = 'PlayerId', type = 'number', default = 1, min = 1, required = true },
            { label = 'Model', type = 'select', data = 'peds', required = true, allowCustom = true }
        }
    },
    addkeys = {
        label = 'Add vehicle keys',
        icon = 'fas fa-key',
        perms = 'admin',
        localServerEvent = 'sm_admin:addKeys',
    }
}

---@type table<string, ActionData>
action.player = {
    heal = {
        label = 'Heal',
        icon = 'fas fa-bandage',
        perms = 'admin',
        localServerEvent = 'sm_admin:heal',
    },
    revive = {
        label = 'Revive',
        icon = 'fas fa-heart',
        perms = 'admin',
        localServerEvent = 'sm_admin:revive',
    },
    bring = {
        label = 'Bring',
        icon = 'fas fa-person-arrow-down-to-line',
        perms = 'admin',
        localServerEvent = 'sm_admin:bring',
    },
    ['goto'] = {
        label = 'Goto',
        icon = 'fas fa-person-arrow-up-from-line',
        perms = 'admin',
        localServerEvent = 'sm_admin:goto',
    },
    resetac = {
        label = 'Reset anti combat',
        icon = 'fas fa-refresh',
        perms = 'admin',
        localServerEvent = 'sm_admin:resetac',
    },
    toggleat = {
        label = 'Toggle anti troll',
        icon = 'fas fa-toggle-on',
        -- perms = 'admin',
        onlyFor = IA.accesstroll,
        localServerEvent = 'sm_admin:toggleantitroll',
    },
    changename = {
        label = 'Change name',
        icon = 'fas fa-pen-to-square',
        perms = 'god',
        localServerEvent = 'sm_admin:setplayername',
        dropdown = {
            { label = 'First name', type = 'text', required = true },
            { label = 'Last name', type = 'text' },
            { label = 'Birthdate', type = 'date' },
            { label = 'Nationality', type = 'text' },
        }
    },
    setphonenumber = {
        label = 'Set phone number',
        icon = 'fas fa-mobile',
        -- perms = 'admin',
        onlyFor = IA.accessgantinomorhp,
        localServerEvent = 'sm_admin:setphonenumber',
        dropdown = {
            { label = 'New number', type = 'number', min = 1, required = true }
        }
    },
    playSound = {
        label = 'Play Sound',
        icon = 'fas fa-circle-play',
        perms = 'admin',
        localFunction = 'playSound',
        dropdown = {
            {label = 'Sound', type = 'select', data = {
                { label = "Alert",      value = "alert" },
                { label = "Cuff",       value = "cuff" },
                { label = "Air Wrench", value = "airwrench" },
            }},
        }
    },
    jumpScare = {
        label = 'Jump Scare',
        icon = 'fas fa-skull',
        perms = 'admin',
        localServerEvent = 'sm_admin:jumpScare',
        dropdown = {
            { label = 'Url', type = 'text', required = true, },
            { label = 'Sound', type = 'select', data = {
                { label = "Jump scare", value = "jumpscare" },
            }, required = true },
        }
    },
    meledak = {
        label = 'Meledak',
        icon = 'fas fa-bomb',
        perms = 'admin',
        canExecute = function (options, args)
            local alert = lib.alertDialog({
                header = '',
                content = 'Apakah kamu yakin mau meledakkan dia?',
                centered = true,
                cancel = true,
                labels = {
                    confirm = 'Ya',
                    cancel = 'Batalkan'
                }
            })

            return alert == 'confirm'
        end,
        localServerEvent = 'sm_admin:meledak',
    },
    terbang = {
        label = 'Terbangkan',
        icon = 'fas fa-dove',
        perms = 'admin',
        canExecute = function (options, args)
            local alert = lib.alertDialog({
                header = '',
                content = 'Apakah kamu yakin mau menerbangkan dia?',
                centered = true,
                cancel = true,
                labels = {
                    confirm = 'Ya',
                    cancel = 'Batalkan'
                }
            })

            return alert == 'confirm'
        end,
        localServerEvent = 'sm_admin:terbang',
    },
    copyped = {
        label = 'Copy Ped',
        icon = 'fas fa-clone',
        perms = 'god',
        localServerEvent = 'sm_admin:copyped',
    },
    deletechar = {
        label = 'Delete character',
        icon = 'fas fa-trash-can',
        perms = 'god',
        localServerEvent = 'sm_admin:deletecharacter',
        canExecute = function (options, args)
            local alert = lib.alertDialog({
                header = '',
                content = 'Apakah kamu yakin mau hapus karakter pemain ini?',
                centered = true,
                cancel = true,
                labels = {
                    confirm = 'Ya',
                    cancel = 'Batalkan'
                }
            })

            return alert == 'confirm'
        end
    },
}

---@type table<string, ActionData>
action.vehicle = {
    change_garage = {
        label = 'Change Garage',
        icon = 'fas fa-warehouse',
        perms = 'admin',
        serverLog = {
            enable = true,
            webhook = webhook.admincarplate,
            title = 'Change Garage',
            description = 'Moved a vehicle to another garage',
            color = 'vehicle',
            -- onlyFor = IA.log
        },
        color = 'yellow',
        localServerEvent = 'sm_admin:changeGarage',
        dropdown = {
            { label = 'Garage', type = 'select', data = 'garages', required = true }
        }
    },
    change_plate = {
        label = 'Change Plate',
        icon = 'fas fa-pen-to-square',
        -- perms = 'admin',
        onlyFor = IA.access,
        serverLog = {
            enable = true,
            webhook = webhook.admincarplate,
            title = 'Change Plate',
            description = 'Changed a vehicle plate',
            color = 'vehicle',
            -- onlyFor = IA.log
        },
        localServerEvent = 'sm_admin:changePlate',
        dropdown = {
            { label = 'New Plate', type = 'text', required = true }
        }
    },
    change_state = {
        label = 'Change State',
        icon = 'fas fa-right-left',
        perms = 'admin',
        localServerEvent = 'sm_admin:changeState',
        dropdown = {
            { label = 'New State', type = 'select', required = true, data = {
                { label = 'Garaged', value = 1 },
                { label = 'Out', value = 0 },
                { label = 'Impounded', value = 2 }
            }}
        }
    },
}

return action