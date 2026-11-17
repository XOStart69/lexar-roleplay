cfg = cfg or {}

cfg.farmer = {
    fw = 'QBCore',
    object = function ()
        return exports['qb-core']:GetCoreObject()
    end,
    jarakAntarTanaman = 1.5,
    maxPlants = 20,
    progress = {
        duration = {
            planting = 4000,
            harvesting = 4000,
        },
        label = {
            planting = 'Menanam %s',
            harvesting = 'Memanen %s',
        },
        anim = {
            planting = {
                scenario = 'world_human_gardener_plant',
            },
            harvesting = {
                dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
                clip = 'machinic_loop_mechandplayer',
            }
        }
    },
    nanem = {
        {
            hasil = 'tomato',
            count = function ()
                return math.random(3, 6)
            end,
            bibit = 'tomato_seed',
            durasi = 3 * 60,
            drawDistance = 30.0,
            model = 'bzzz_plants_tomato_03',
            minigame = function ()
                return true
            end,
            land = 'land_1',
            validasi = function (tipe)
                if tipe == 'planting' then
                    TriggerEvent('ak4y-battlepass:addtaskcount:premium', 3, 1)
                    return true
                elseif tipe == 'harvesting' then
                    TriggerEvent('ak4y-battlepass:addtaskcount:premium', 4, 1)
                    return true
                end
                return true
            end
        },
        {
            hasil = 'wheat',
            bibit = 'wheat_seed',
            durasi = 3 * 60,
            count = function ()
                return math.random(3, 6)
            end,
            drawDistance = 30.0,
            model = 'bzzz_plant_rice_c',
            land = 'land_2',
            minigame = function ()
                return true
            end,
            validasi = function (tipe)
                return true
            end,
        },
        {
            hasil = 'jeruk',
            bibit = 'orange_seed',
            durasi = 3 * 60,
            count = function ()
                return math.random(3, 6)
            end,
            drawDistance = 30.0,
            model = 'bzzz_plants_tomato_03',
            land = 'land_3',
            minigame = function ()
                return true
            end,
            validasi = function (tipe)
                return true
            end,
        },
        {
            hasil = 'chili',
            bibit = 'chili_seed',
            durasi = 3 * 60,
            count = function ()
                return math.random(3, 6)
            end,
            drawDistance = 30.0,
            model = 'bzzz_plants_tomato_02',
            land = 'land_4',
            minigame = function ()
                return true
            end,
            validasi = function (tipe)
                if tipe == 'planting' then
                    TriggerEvent('ak4y-battlepass:addtaskcount:standart', 3, 1)
                    return true
                elseif tipe == 'harvesting' then
                    TriggerEvent('ak4y-battlepass:addtaskcount:standart', 4, 1)
                    return true
                end
                return true
            end,
        },
        {
            hasil = 'corn',
            bibit = 'corn_seed',
            durasi = 3 * 60,
            count = function ()
                return math.random(3, 6)
            end,
            drawDistance = 30.0,
            model = 'prop_bzzz_gardenpack_cornstalk001',
            land = 'land_5',
            minigame = function ()
                return true
            end,
            validasi = function (tipe)
                if tipe == 'planting' then
                    TriggerEvent('ak4y-battlepass:addtaskcount:standart', 5, 1)
                    return true
                elseif tipe == 'harvesting' then
                    TriggerEvent('ak4y-battlepass:addtaskcount:standart', 6, 1)
                    return true
                end
                return true
            end,
        },
        {
            hasil = 'carrot',
            bibit = 'carrot_seed',
            durasi = 3 * 60,
            count = function ()
                return math.random(3, 6)
            end,
            drawDistance = 30.0,
            model = 'bzzz_garden_plant_carrot_c',
            land = 'land_6',
            minigame = function ()
                return true
            end,
            validasi = function (tipe)
                return true
            end,
        },
        {
            hasil = 'bawang',
            bibit = 'bawang_seed',
            durasi = 3 * 60,
            count = function ()
                return math.random(3, 6)
            end,
            drawDistance = 30.0,
            model = 'bzzz_plants_onion_04',
            land = 'land_7',
            minigame = function ()
                return true
            end,
            validasi = function (tipe)
                return true
            end,
        },
    }
}

cfg.farmer.zones = {}

cfg.farmer.zones['land_1'] = {
    label = 'Lahan: Tomat',
    bibit = 'tomato_seed',
    model = 'bzzz_plants_tomato_03',
    points = {
        vec3(2046.0, 4968.0, 41.0),
        vec3(2018.0, 4940.0, 41.0),
        vec3(2041.0, 4916.0, 41.0),
        vec3(2070.0, 4944.0, 41.0),
    },
    data = {
        minZ = 38.0,
        maxZ = 50.0,
        name = "land_1",
        center = vec3(2045.2725, 4940.2891, 40.9644),
    },
}

cfg.farmer.zones['land_2'] = {
    label = 'Lahan: Beras',
    bibit = 'wheat_seed',
    model = 'bzzz_plant_rice_c',
    points = {
        vec3(1928.0, 4847.0, 44.0),
        vec3(1945.0, 4830.0, 44.0),
        vec3(1980.0, 4864.0, 44.0),
        vec3(1963.0, 4882.0, 44.0),
    },
    data = {
        minZ = 40.0,
        maxZ = 60.0,
        name = "land_2",
        center = vec3(1949.5576, 4854.7974, 44.3852),
    },
}

cfg.farmer.zones['land_3'] = {
    label = 'Lahan: Jeruk',
    bibit = 'orange_seed',
    model = 'bzzz_plants_tomato_03',
    points = {
        vec3(2112.0, 4906.0, 40.0),
        vec3(2060.0, 4853.0, 40.0),
        vec3(2097.0, 4826.0, 40.0),
        vec3(2136.0, 4881.0, 40.0),
    },
    data = {
        minZ = 38.0,
        maxZ = 50.0,
        name = "land_3",
        center = vec3(2088.8647, 4857.9082, 40.5754),
    },
}

cfg.farmer.zones['land_4'] = {
    label = 'Lahan: Cabe',
    bibit = 'chili_seed',
    model = 'bzzz_plants_tomato_02',
    points = {
        vec3(2031.0, 4853.0, 41.0),
        vec3(2058.0, 4879.0, 41.0),
        vec3(2033.0, 4903.0, 41.0),
        vec3(2007.0, 4877.0, 41.0),
    },
    data = {
        minZ = 38.0,
        maxZ = 50.0,
        name = "land_4",
        center = vec3(2029.5571, 4874.7524, 41.7531),
    },
}

cfg.farmer.zones['land_5'] = {
    label = 'Lahan: Jagung',
    bibit = 'corn_seed',
    model = 'prop_bzzz_gardenpack_cornstalk001',
    points = {
        vec3(2068.0, 4890.0, 40.0),
        vec3(2096.0, 4917.0, 40.0),
        vec3(2073.0, 4942.0, 40.0),
        vec3(2045.0, 4913.0, 40.0),
    },
    data = {
        minZ = 38.0,
        maxZ = 50.0,
        name = "land_5",
        center = vec3(2069.6577, 4913.2109, 40.0836),
    },
}

cfg.farmer.zones['land_6'] = {
    label = 'Lahan: Wortel',
    bibit = 'carrot_seed',
    model = 'bzzz_garden_plant_carrot_c',
    points = {
        vec3(2005.0, 4879.0, 41.0),
        vec3(2031.0, 4904.0, 41.0),
        vec3(2006.0, 4929.0, 41.0),
        vec3(1980.0, 4903.0, 41.0),
    },
    data = {
        minZ = 38.0,
        maxZ = 50.0,
        name = "land_6",
        center = vec3(2005.6582, 4900.4277, 41.8818),
    },
}

cfg.farmer.zones['land_7'] = {
    label = 'Lahan: Bawang',
    bibit = 'bawang_seed',
    model = 'bzzz_plants_onion_04',
    points = {
        vec3(-2278.0, 7159.0, 29.0),
        vec3(-2262.0, 7213.0, 29.0),
        vec3(-2376.0, 7242.0, 29.0),
        vec3(-2389.0, 7188.0, 29.0),
    },
    data = {
        minZ = 27.0,
        maxZ = 33.0,
        name = "land_7",
        center = vec3(-2324.8325, 7196.1392, 29.8288),
    },
}

cfg.findFromTable = function(tableToSearch, key, value)
    for k, v in pairs(tableToSearch) do
        if v[key] == value then
            return k
        end
    end
    return nil
end

cfg.getPlayerState = function(src, key)
    if lib.context == 'server' then
        return Player(src).state[key]
    else
        return LocalPlayer.state[key]
    end
end
