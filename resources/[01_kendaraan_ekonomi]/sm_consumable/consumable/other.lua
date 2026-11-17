return {
    suppresant_pill = {
        progress = {
            label = 'Menggunakan {itemname}',
            duration = 2500,
            anim = {
                dict = 'mp_suicide',
                clip = 'pill',
                flag = 49
            }
        },
        removeItems = true,
        drunk = 30,
        status = {
            hunger = 30,
        },
    },
    maxcandy = {
        progress = {
            label = 'Memakan {itemname}',
            duration = 2500,
            emote = 'lollipop1'
        },
        removeItems = true,
        removeStress = 15,
        status = {
            hunger = -2,
            thirst = -2,
        },
    },
    ycandy = {
        progress = {
            label = 'Memakan {itemname}',
            duration = 2500,
            emote = 'lollipop1'
        },
        removeItems = true,
        removeStress = 15,
        status = {
            hunger = -2,
            thirst = -2,
        },
    },
    boxstarterpack = {
        progress = {
            label = 'Membuka {itemname}',
            duration = 5000,
        },
        removeItems = true,
        serverFunction = function(source)
            local dataItems = {
                { name = 'burger', count = 10 },
                { name = 'water', count = 10 },
                { name = 'phone', count = 1 },
                { name = 'money', count = 50000 },
            }

            local player = exports['qb-core']:GetPlayer(source)
            for _, val in ipairs(dataItems) do
                player.Functions.AddItem(val.name, val.count)
            end
        end
    },
    paketmakanan = {
        progress = {
            label = 'Membuka {itemname}',
            duration = 5000,
        },
        removeItems = true,
        serverFunction = function(source)
            local dataItems = {
                { name = 'satemaranggi', count = 2 },
                { name = 'oliang', count = 2 },
            }

            local player = exports['qb-core']:GetPlayer(source)
            for _, val in ipairs(dataItems) do
                player.Functions.AddItem(val.name, val.count)
            end
        end
    },
    tespek = {
        emote = 'pee2',
        progress = {
            label = 'Menggunakan {itemname}',
            duration = 2500,
        },
        removeItems = false,
    },
    dipurine = {
        emote = 'pee2',
        progress = {
            label = 'Menggunakan {itemname}',
            duration = 2500,
        },
        removeItems = false,
    },
    paracetamol = {
        progress = {
            label = 'Menggunakan {itemname}',
            duration = 2500,
            anim = {
                dict = 'mp_suicide',
                clip = 'pill',
                flag = 49
            }
        },
        removeItems = true,
        removeStress = 25
    },
    ibuprofen = {
        progress = {
            label = 'Menggunakan {itemname}',
            duration = 2500,
            anim = {
                dict = 'mp_suicide',
                clip = 'pill',
                flag = 49
            }
        },
        removeItems = true,
        removeStress = 25
    },
    ondansetron = {
        progress = {
            label = 'Menggunakan {itemname}',
            duration = 2500,
            anim = {
                dict = 'mp_suicide',
                clip = 'pill',
                flag = 49
            }
        },
        removeItems = true,
        removeStress = 5
    },
    obat_custom = {
        progress = {
            label = 'Menggunakan {itemname}',
            duration = 2500,
            anim = {
                dict = 'mp_suicide',
                clip = 'pill',
                flag = 49
            }
        },
        removeItems = true,
        removeStress = 5
    },
    golden_coffee = {
        progress = {
            label = 'Meminum {itemname}',
            duration = 5000,
            emote = 'coffee'
        },
        removeItems = true,
        status = {
            hunger = 20,
            thirst = 20,
        },
    },
    vitaminec = {
        progress = {
            label = 'Menggunakan {itemname}',
            duration = 2500,
            anim = {
                dict = 'mp_suicide',
                clip = 'pill',
                flag = 49
            }
        },
        removeItems = true,
        status = {
            hunger = 10,
            thirst = 10,
        },
    },
    pregnanmilk = {
        status = {
            hunger = 10,
            thirst = 10,
        },
        progress = {
            label = 'Meminum {itemname}',
            duration = 5000,
            emote = 'drink'
        },
        removeItems = true
    },
    perban_anak = {
        emote = 'mechanic4',
        progress = {
            label = 'Menggunakan {itemname}',
            duration = 2500,
        },
        removeItems = true,
        addHealth = 35,
        validateClient = function(itemData)
            local toddlerModels = require 'consumable.toddler_models'
            local pedModel = GetEntityModel(cache.ped)

            for _, model in ipairs(toddlerModels) do
                if pedModel == model then
                    return true
                end
            end

            lib.notify({
                description = 'Obat ini hanya bisa digunakan oleh anak-anak',
                type = 'error'
            })
            return false
        end
    },
    paracetamol_syrup = {
        emote = 'drink',
        progress = {
            label = 'Menggunakan {itemname}',
            duration = 2500,
        },
        removeItems = true,
        removeStress = 45,
        validateClient = function(itemData)
            local toddlerModels = require 'consumable.toddler_models'
            local pedModel = GetEntityModel(cache.ped)

            for _, model in ipairs(toddlerModels) do
                if pedModel == model then
                    return true
                end
            end

            lib.notify({
                description = 'Obat ini hanya bisa digunakan oleh anak-anak',
                type = 'error'
            })
            return false
        end
    },
    heavyarmor = {
        grantArmour = 95,
        groups = {
            'admin',
            'police',
            'government',
            'paspampres',
            'usmarshal',
            'pengadilan'
        },
        progress = {
            label = 'Memakai armor..',
            duration = 3000,
            anim = {
                dict = 'rick3d@weapons',
                clip = 'armorplate',
                flag = 49
            },
            prop = {
                model = 'prop_armorplate',
                bone = 28422,
                pos = vec3(0.030, 0.010, -0.145),
                rot = vec3(-168.0, 96.0, 0.0)
            }
        },
        removeItems = true,
        clientFunction = function(items)
            local currentArmor = GetPedArmour(cache.ped)
            if currentArmor >= 95 then
                lib.notify({ description = "Armor sudah maksimal!", type = 'error' })
                return false
            end
            
            local addAmount = currentArmor + 95
            if addAmount > 95 then
                addAmount = 95
            end
            SetPedArmour(cache.ped, addAmount)
        end
    },
    lockpick = {
        serverFunction = function(source)
            TriggerClientEvent('lockpicks:UseLockpick', source, false)
            TriggerEvent('lockpicks:UseLockpick', source, false)
            TriggerEvent('lockpicks:UseLockpickHouseRobbery', source, false)
        end
    },
    advancedlockpick = {
        serverFunction = function(source)
            TriggerClientEvent('lockpicks:UseLockpick', source, true)
            TriggerEvent('lockpicks:UseLockpick', source, true)
        end
    }
}