--[[
    sm_animalfarm :: server
    Kandang per citizenid, hewan per ekor, pakan/berat/kelaparan di server, bucket per plot.
]]

local cfg = localmodule 'config'

local PLOTS = cfg.plots or {}
local SPECIES = cfg.species or {}
local CARE = cfg.care or {}
local TROUGH = cfg.trough or {}
local STOCK = cfg.stock or {}
local BUCKET_BASE = cfg.bucketBase or 500000
local ACCOUNT = cfg.account or 'cash'
local MAX_ANIMALS = cfg.maxAnimals or 5
local NAME_MAX = cfg.nameMaxLength or 20
local MIN_TAKEOUT = cfg.takeOutMinHealth or 30.0
local STORE_DIST = cfg.storeDistance or 40.0
local PEN_LEAVE = cfg.penLeaveDistance or 110.0
local INVITE_DIST = cfg.invite and cfg.invite.distance or 15.0
local INVITE_TIMEOUT = cfg.invite and cfg.invite.timeout or 60
local MILK_DIST = cfg.milkDistance or 3.0
local CAPACITY = TROUGH.capacity or 100
local FILL_AMOUNT = TROUGH.fillAmount or 34
local SERVER_DIST = TROUGH.serverDistance or 4.0
local TIME_SCALE = (cfg.debug and cfg.debug.enabled) and (cfg.debug.timeScale or 60) or 1

local FARMS = 'animalfarm_farms'
local ANIMALS = 'animalfarm_animals'

local farms = {}
local animals = {}
local guests = {}
local invites = {}

local function playerOf(src)
    return qb_ecore:GetPlayer(src)
end

local function notify(src, message, kind)
    TriggerClientEvent('ox_lib:notify', src, { title = 'Peternakan', description = message, type = kind or 'error' })
end

local function cidOf(src)
    local player = playerOf(src)
    return player and player.PlayerData.citizenid or nil, player
end

local function plotOf(index)
    return PLOTS[tonumber(index) or 0]
end

local function speciesOf(key)
    return SPECIES[tostring(key or '')]
end

local function bucketOf(index)
    return BUCKET_BASE + (tonumber(index) or 0)
end

local function farmOf(cid)
    return cid and farms[cid] or nil
end

local function animalsOf(cid)
    local out = {}
    for _, animal in pairs(animals) do
        if animal.owner == cid then out[#out + 1] = animal end
    end
    table.sort(out, function(a, b) return a.id < b.id end)
    return out
end

local function snapshot(cid)
    local farm = farmOf(cid)
    if not farm then return nil end

    local plot = plotOf(farm.plot)
    local list = {}

    for _, animal in ipairs(animalsOf(cid)) do
        local species = speciesOf(animal.species) or {}

        list[#list + 1] = {
            id = animal.id,
            species = animal.species,
            label = species.localLabel or species.label,
            name = animal.name,
            weight = animal.weight,
            health = animal.health,
            state = animal.state,
            baby = animal.weight < (CARE.babyUntil or 35.0),
            scale = animal.weight < (CARE.babyUntil or 35.0) and (cfg.scale and cfg.scale.baby or 0.65) or (cfg.scale and cfg.scale.adult or 1.0),
            milkReady = species.milk and animal.milkAt and animal.milkAt <= os.time() or false,
        }
    end

    return {
        plot = { index = farm.plot, label = plot and plot.label, price = plot and plot.price },
        animals = list,
        trough = { food = farm.food, water = farm.water },
        stock = { food = farm.stock_food, water = farm.stock_water },
        capacity = CAPACITY,
        maxAnimals = MAX_ANIMALS,
        minTakeOut = MIN_TAKEOUT,
    }
end

local function refresh(cid)
    local farm = farmOf(cid)
    if not farm then return end

    local data = snapshot(cid)
    for _, raw in ipairs(GetPlayers()) do
        local src = tonumber(raw)
        local player = playerOf(src)

        if player and (player.PlayerData.citizenid == cid or guests[src] == cid) then
            TriggerClientEvent('sm_animalfarm:client:refresh', src, data)
        end
    end
end

local function refreshAll()
    for cid in pairs(farms) do refresh(cid) end
end

local function saveAnimal(animal)
    MySQL.update(('UPDATE %s SET name = ?, weight = ?, health = ?, state = ?, milk_at = ?, last_tick = ? WHERE id = ?'):format(ANIMALS), {
        animal.name, animal.weight, animal.health, animal.state, animal.milk_at, animal.last_tick, animal.id,
    })
end

local function saveFarm(farm)
    MySQL.update(('UPDATE %s SET food = ?, water = ?, stock_food = ?, stock_water = ? WHERE citizenid = ?'):format(FARMS), {
        farm.food, farm.water, farm.stock_food, farm.stock_water, farm.cid,
    })
end

lib.callback.register('sm_animalfarm:init', function(src)
    local cid, player = cidOf(src)
    if not player then return { ok = false, message = 'Data pemain tidak siap.' } end

    SetPlayerRoutingBucket(src, bucketOf(farmOf(cid) and farmOf(cid).plot or 0))

    return { ok = true, data = snapshot(cid) }
end)

lib.callback.register('sm_animalfarm:buyPlot', function(src, index)
    local cid, player = cidOf(src)
    if not player then return { ok = false, message = 'Data pemain tidak siap.' } end

    local plot = plotOf(index)
    if not plot then return { ok = false, message = 'Plot tidak ada.' } end
    if farmOf(cid) then return { ok = false, message = 'Sudah punya plot.' } end

    if not player.Functions.RemoveMoney(ACCOUNT, plot.price, 'farm-plot') then
        return { ok = false, message = 'Uang tidak cukup.' }
    end

    local id = MySQL.insert.await(
        ('INSERT INTO %s (citizenid, plot, food, water, stock_food, stock_water, created) VALUES (?, ?, 0, 0, 0, 0, ?)'):format(FARMS),
        { cid, tonumber(index), os.time() }
    )

    if not id then return { ok = false, message = 'Gagal menyimpan.' } end

    farms[cid] = { cid = cid, plot = tonumber(index), food = 0, water = 0, stock_food = 0, stock_water = 0 }

    return { ok = true, data = snapshot(cid) }
end)

lib.callback.register('sm_animalfarm:buyAnimal', function(src, speciesKey, name)
    local cid, player = cidOf(src)
    if not player then return { ok = false, message = 'Data pemain tidak siap.' } end
    if not farmOf(cid) then return { ok = false, message = 'Belum punya plot.' } end

    local species = speciesOf(speciesKey)
    if not species then return { ok = false, message = 'Spesies tidak dikenal.' } end

    if species.job then
        local ok = false
        for i = 1, #species.job do
            if species.job[i] == player.PlayerData.job.name then ok = true break end
        end
        if not ok then return { ok = false, message = 'Job tidak memenuhi.' } end
    end

    if #animalsOf(cid) >= MAX_ANIMALS then return { ok = false, message = 'Kandang penuh.' } end

    name = tostring(name or ''):sub(1, NAME_MAX)
    if name == '' then return { ok = false, message = 'Nama kosong.' } end

    if not player.Functions.RemoveMoney(ACCOUNT, species.price, 'farm-animal') then
        return { ok = false, message = 'Uang tidak cukup.' }
    end

    local weight = species.noCare and 100.0 or (CARE.startWeight or 50.0)

    local id = MySQL.insert.await(
        ('INSERT INTO %s (owner, species, name, weight, health, state, born_at, last_tick) VALUES (?, ?, ?, ?, 100, ?, ?, ?)'):format(ANIMALS),
        { cid, speciesKey, name, weight, 'pen', os.time(), os.time() }
    )

    if not id then return { ok = false, message = 'Gagal menyimpan.' } end

    animals[id] = { id = id, owner = cid, species = speciesKey, name = name, weight = weight, health = 100.0, state = 'pen', last_tick = os.time() }

    refresh(cid)

    return { ok = true, data = snapshot(cid) }
end)

lib.callback.register('sm_animalfarm:buyStock', function(src, kind)
    local cid, player = cidOf(src)
    if not player then return { ok = false, message = 'Data pemain tidak siap.' } end

    local farm = farmOf(cid)
    if not farm then return { ok = false, message = 'Belum punya plot.' } end

    local entry = STOCK[kind]
    if not entry then return { ok = false, message = 'Jenis tidak dikenal.' } end

    local field = kind == 'food' and 'stock_food' or 'stock_water'
    if farm[field] >= (entry.max or 50) then return { ok = false, message = 'Stok penuh.' } end

    if not player.Functions.RemoveMoney(ACCOUNT, entry.price, 'farm-stock') then
        return { ok = false, message = 'Uang tidak cukup.' }
    end

    farm[field] = farm[field] + 1
    saveFarm(farm)
    refresh(cid)

    return { ok = true, data = snapshot(cid) }
end)

lib.callback.register('sm_animalfarm:fill', function(src, kind)
    local cid = cidOf(src)
    local farm = farmOf(cid)
    if not farm then return { ok = false, message = 'Belum punya plot.' } end

    local plot = plotOf(farm.plot)
    if plot and #(GetEntityCoords(GetPlayerPed(src)) - vector3(plot.coords.x, plot.coords.y, plot.coords.z)) > SERVER_DIST + 4.0 then
        return { ok = false, message = 'Terlalu jauh dari palung.' }
    end

    local field = kind == 'food' and 'stock_food' or 'stock_water'
    local troughField = kind == 'food' and 'food' or 'water'

    if farm[field] < 1 then return { ok = false, message = 'Stok habis.' } end
    if farm[troughField] >= CAPACITY then return { ok = false, message = 'Palung penuh.' } end

    farm[field] = farm[field] - 1
    farm[troughField] = math.min(farm[troughField] + FILL_AMOUNT, CAPACITY)

    saveFarm(farm)
    refresh(cid)

    return { ok = true, data = snapshot(cid) }
end)

local function ownedAnimal(src, id)
    local cid = cidOf(src)
    local animal = animals[tonumber(id) or 0]
    if not cid or not animal or animal.owner ~= cid then return nil end
    return animal
end

lib.callback.register('sm_animalfarm:take', function(src, id)
    local animal = ownedAnimal(src, id)
    if not animal then return { ok = false, message = 'Bukan hewanmu.' } end
    if animal.state ~= 'pen' then return { ok = false, message = 'Sudah di luar.' } end
    if animal.health < MIN_TAKEOUT then return { ok = false, message = 'Kesehatan terlalu rendah.' } end

    local cid = cidOf(src)
    local farm = farmOf(cid)
    local plot = farm and plotOf(farm.plot)
    if not plot then return { ok = false, message = 'Plot hilang.' } end

    if #(GetEntityCoords(GetPlayerPed(src)) - vector3(plot.coords.x, plot.coords.y, plot.coords.z)) > SERVER_DIST + 6.0 then
        return { ok = false, message = 'Terlalu jauh dari kandang.' }
    end

    animal.state = 'out'
    saveAnimal(animal)

    refresh(cid)

    return { ok = true, data = { id = animal.id, coords = plot.coords, species = animal.species, scale = animal.weight < (CARE.babyUntil or 35.0) and 0.65 or 1.0 } }
end)

lib.callback.register('sm_animalfarm:spawned', function(src, id, netId)
    local animal = ownedAnimal(src, id)
    if not animal then return false end

    local entity = NetworkGetEntityFromNetworkId(tonumber(netId) or 0)
    if entity == 0 or not DoesEntityExist(entity) then return false end

    local species = speciesOf(animal.species)
    if not species or GetEntityModel(entity) ~= GetHashKey(species.model) then return false end

    animal.netId = tonumber(netId)
    return true
end)

lib.callback.register('sm_animalfarm:lost', function(src, id)
    local animal = ownedAnimal(src, id)
    if not animal then return false end

    animal.state = 'pen'
    animal.netId = nil
    saveAnimal(animal)
    refresh(animal.owner)

    return true
end)

lib.callback.register('sm_animalfarm:died', function(src, id)
    local animal = ownedAnimal(src, id)
    if not animal then return false end

    animal.state = 'dead'
    animal.health = 0.0
    animal.netId = nil
    saveAnimal(animal)
    refresh(animal.owner)

    return true
end)

lib.callback.register('sm_animalfarm:store', function(src)
    local cid = cidOf(src)
    if not cid then return { ok = false, message = 'Data pemain tidak siap.' } end

    for _, animal in ipairs(animalsOf(cid)) do
        if animal.state == 'out' then
            animal.state = 'pen'
            animal.netId = nil
            saveAnimal(animal)
        end
    end

    refresh(cid)

    return { ok = true, data = snapshot(cid) }
end)

lib.callback.register('sm_animalfarm:milk', function(src, id)
    local animal = ownedAnimal(src, id)
    if not animal then return { ok = false, message = 'Bukan hewanmu.' } end

    local species = speciesOf(animal.species)
    local milk = species and species.milk
    if not milk then return { ok = false, message = 'Tidak bisa diperah.' } end
    if animal.health < 60.0 then return { ok = false, message = 'Terlalu lemah.' } end
    if animal.weight < (milk.minWeight or 60.0) then return { ok = false, message = 'Belum cukup besar.' } end
    if animal.milkAt and animal.milkAt > os.time() then return { ok = false, message = 'Belum siap.' } end

    local amount = math.random(milk.min or 1, milk.max or 1)
    ox_inventory:AddItem(src, milk.item, amount)

    animal.milkAt = os.time() + ((milk.cooldownMinutes or 30) * 60)
    saveAnimal(animal)
    refresh(animal.owner)

    return { ok = true, data = { amount = amount, item = milk.item } }
end)

lib.callback.register('sm_animalfarm:slaughter', function(src, id)
    local animal = ownedAnimal(src, id)
    if not animal then return { ok = false, message = 'Bukan hewanmu.' } end
    if animal.state ~= 'pen' then return { ok = false, message = 'Simpan dulu hewannya.' } end

    local species = speciesOf(animal.species)
    local meat = species and species.meat
    if not meat then return { ok = false, message = 'Tidak bisa disembelih.' } end

    local amount = math.random(meat.min or 1, meat.max or 1)
    ox_inventory:AddItem(src, meat.item, amount)

    animals[animal.id] = nil
    MySQL.update('DELETE FROM ' .. ANIMALS .. ' WHERE id = ?', { animal.id })

    refresh(animal.owner)

    return { ok = true, data = { amount = amount, item = meat.item } }
end)

lib.callback.register('sm_animalfarm:revive', function(src, id)
    local animal = ownedAnimal(src, id)
    local _, player = cidOf(src)
    if not animal or not player then return { ok = false, message = 'Bukan hewanmu.' } end
    if animal.state ~= 'dead' then return { ok = false, message = 'Tidak mati.' } end

    local species = speciesOf(animal.species)
    if not species then return { ok = false, message = 'Spesies hilang.' } end

    if not player.Functions.RemoveMoney(ACCOUNT, species.revivePrice or 0, 'farm-revive') then
        return { ok = false, message = 'Uang tidak cukup.' }
    end

    animal.state = 'pen'
    animal.health = CARE.reviveHealth or 50.0
    saveAnimal(animal)
    refresh(animal.owner)

    return { ok = true, data = snapshot(animal.owner) }
end)

lib.callback.register('sm_animalfarm:release', function(src, id)
    local animal = ownedAnimal(src, id)
    if not animal then return { ok = false, message = 'Bukan hewanmu.' } end

    animal.state = 'released'
    animal.netId = nil
    saveAnimal(animal)
    refresh(animal.owner)

    return { ok = true, data = cfg.releaseCoords }
end)

lib.callback.register('sm_animalfarm:invite', function(src, targetSrc)
    local cid, player = cidOf(src)
    local target = playerOf(tonumber(targetSrc) or 0)
    if not player or not target then return { ok = false, message = 'Pemain tidak ditemukan.' } end

    if #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(GetPlayerPed(target.PlayerData.source))) > INVITE_DIST then
        return { ok = false, message = 'Terlalu jauh.' }
    end

    TriggerClientEvent('sm_animalfarm:client:invite', target.PlayerData.source, src,
        ('%s %s'):format(player.PlayerData.charinfo.firstname, player.PlayerData.charinfo.lastname))

    invites[target.PlayerData.source] = { owner = src, until_ = os.time() + INVITE_TIMEOUT }

    return { ok = true }
end)

lib.callback.register('sm_animalfarm:acceptInvite', function(src, ownerSrc)
    local cid = cidOf(src)
    local owner = cidOf(tonumber(ownerSrc) or 0)
    if not cid or not owner then return { ok = false, message = 'Undangan kedaluwarsa.' } end

    local invite = invites[src]
    if not invite or invite.owner ~= tonumber(ownerSrc) or invite.until_ < os.time() then
        return { ok = false, message = 'Undangan kedaluwarsa.' }
    end

    invites[src] = nil

    guests[src] = owner
    SetPlayerRoutingBucket(src, bucketOf(farmOf(owner) and farmOf(owner).plot or 0))

    return { ok = true, data = snapshot(owner) }
end)

RegisterNetEvent('sm_animalfarm:leavePen', function()
    local src = source
    guests[src] = nil
    SetPlayerRoutingBucket(src, 0)
    TriggerClientEvent('sm_animalfarm:client:penLeft', src)
end)

lib.callback.register('sm_animalfarm:mount', function(src, id)
    local animal = ownedAnimal(src, id)
    if not animal then return { ok = false, message = 'Bukan hewanmu.' } end
    if animal.state ~= 'out' then return { ok = false, message = 'Keluarkan dulu hewannya.' } end

    local species = speciesOf(animal.species)
    if not species or not species.ride then return { ok = false, message = 'Tidak bisa ditunggangi.' } end
    if animal.health < 50.0 then return { ok = false, message = 'Terlalu lemah.' } end
    if animal.weight < (CARE.adultWeight or 60.0) then return { ok = false, message = 'Belum dewasa.' } end

    return { ok = true }
end)

lib.callback.register('sm_animalfarm:dismount', function(src, id, dead)
    local animal = ownedAnimal(src, id)
    if not animal then return { ok = false } end

    if dead then
        animal.state = 'pen'
        animal.netId = nil
        saveAnimal(animal)
        refresh(animal.owner)
    end

    return { ok = true, pendingId = animal.id }
end)

lib.callback.register('sm_animalfarm:board', function(src, driverSrc, id)
    local animal = ownedAnimal(src, id)
    local driver = playerOf(tonumber(driverSrc) or 0)
    if not animal or not driver then return { ok = false, message = 'Data tidak siap.' } end
    if animal.state ~= 'out' then return { ok = false, message = 'Hewan tidak di luar.' } end

    local species = speciesOf(animal.species)
    if not species or not species.ride then return { ok = false, message = 'Tidak bisa diangkut.' } end

    return { ok = true }
end)

RegisterNetEvent('sm_animalfarm:unboard', function()
    TriggerClientEvent('sm_animalfarm:client:unboard', source)
end)

lib.callback.register('sm_animalfarm:leash', function(src, id)
    local animal = ownedAnimal(src, id)
    if not animal then return { ok = false, message = 'Bukan hewanmu.' } end
    if animal.state ~= 'out' then return { ok = false, message = 'Hewan tidak di luar.' } end

    animal.leashed = not animal.leashed
    return { ok = true, leashed = animal.leashed }
end)

CreateThread(function()
    MySQL.query.await([[
    CREATE TABLE IF NOT EXISTS `animalfarm_farms` (
        `citizenid` varchar(64) NOT NULL,
        `plot` int(11) NOT NULL,
        `food` int(11) NOT NULL DEFAULT 0,
        `water` int(11) NOT NULL DEFAULT 0,
        `stock_food` int(11) NOT NULL DEFAULT 0,
        `stock_water` int(11) NOT NULL DEFAULT 0,
        `created` int(11) NOT NULL,
        PRIMARY KEY (`citizenid`),
        UNIQUE KEY `plot` (`plot`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    MySQL.query.await([[
    CREATE TABLE IF NOT EXISTS `animalfarm_animals` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `owner` varchar(64) NOT NULL,
        `species` varchar(24) NOT NULL,
        `name` varchar(32) NOT NULL,
        `weight` double NOT NULL DEFAULT 50,
        `health` double NOT NULL DEFAULT 100,
        `state` varchar(16) NOT NULL DEFAULT 'pen',
        `born_at` int(11) NOT NULL,
        `last_tick` int(11) NOT NULL,
        `milk_at` int(11) DEFAULT NULL,
        PRIMARY KEY (`id`),
        KEY `owner` (`owner`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    local farmRows = MySQL.query.await('SELECT * FROM ' .. FARMS) or {}
    for i = 1, #farmRows do
        local row = farmRows[i]
        farms[row.citizenid] = row
    end

    local animalRows = MySQL.query.await('SELECT * FROM ' .. ANIMALS) or {}
    for i = 1, #animalRows do
        local row = animalRows[i]
        animals[row.id] = row
    end

    while true do
        Wait((CARE.tickSeconds or 60) * 1000)

        local stamp = os.time()

        for id, animal in pairs(animals) do
            local species = speciesOf(animal.species)
            local farm = farmOf(animal.owner)

            if species and farm and not species.noCare and animal.state == 'pen' then
                local hours = (stamp - (animal.last_tick or stamp)) / 3600 * TIME_SCALE
                local needFood = (species.foodPerHour or 10.0) * hours
                local needWater = (species.waterPerHour or 10.0) * hours

                local fed = farm.food >= needFood
                local watered = farm.water >= needWater

                if fed then farm.food = farm.food - needFood else farm.food = 0 end
                if watered then farm.water = farm.water - needWater else farm.water = 0 end

                if fed and watered then
                    animal.weight = math.min(animal.weight + (CARE.weightGainPerHour or 30.0) * hours, 100.0)
                    animal.health = math.min(animal.health + 10.0 * hours, 100.0)
                else
                    animal.weight = math.max(animal.weight - (CARE.weightLossPerHour or 6.0) * hours, 1.0)
                    animal.health = math.max(animal.health - (100.0 / (CARE.starveDeathHours or 48.0)) * hours, 0.0)
                end

                animal.last_tick = stamp

                if animal.health <= 0.0 then
                    animal.state = 'dead'
                    animal.netId = nil
                end

                saveAnimal(animal)
                saveFarm(farm)
            end
        end
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    guests[src] = nil
    SetPlayerRoutingBucket(src, 0)
end)

print('^2[sm_animalfarm] server siap^7')