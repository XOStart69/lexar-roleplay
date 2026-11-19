--[[
    sm_pets :: server (core)
    Kepemilikan pet, spawn/store, transfer, statistik (lapar, haus, stamina, kebahagiaan,
    loyalitas, mood), dan penyimpanan berkala.
]]

local Config = localmodule 'config.shared'
local Pets = localmodule 'config.pets'

local QBCore = exports['qb-core']:GetCoreObject()

local STATS = Config.Stats
local MAX_OWNED = Config.MaxOwnedPets or 5
local TICK = (Config.StatTickSeconds or 60) * 1000
local PUSH = (Config.StatsPushSeconds or 10) * 1000
local SAVE = (Config.SaveIntervalSeconds or 300) * 1000
local MONEY = Config.MoneyAccount or 'cash'

local active = {}
local cacheRows = {}

local SCHEMA = [[
CREATE TABLE IF NOT EXISTS `sm_pets_pets` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `citizenid` varchar(64) NOT NULL,
    `type` varchar(32) NOT NULL,
    `name` varchar(32) NOT NULL,
    `species` varchar(32) NOT NULL,
    `model` varchar(64) NOT NULL,
    `health` int(11) NOT NULL DEFAULT 100,
    `hunger` int(11) NOT NULL DEFAULT 100,
    `thirst` int(11) NOT NULL DEFAULT 100,
    `stamina` int(11) NOT NULL DEFAULT 100,
    `happiness` int(11) NOT NULL DEFAULT 100,
    `loyalty` int(11) NOT NULL DEFAULT 20,
    `mood` varchar(16) NOT NULL DEFAULT 'happy',
    `look` longtext NULL,
    `bowl` longtext NULL,
    `clothing` longtext NULL,
    `wardrobe` longtext NULL,
    `k9` tinyint(4) NOT NULL DEFAULT 0,
    `skills` longtext NULL,
    `active` tinyint(4) NOT NULL DEFAULT 0,
    `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
]]

local function notify(src, message, nType)
    lib.notify(src, { title = 'Pet', description = message, type = nType or 'inform' })
end

local function cid(src)
    local player = QBCore.Functions.GetPlayer(src)
    return player and player.PlayerData.citizenid or nil
end

local function jobName(src)
    local player = QBCore.Functions.GetPlayer(src)
    local job = player and player.PlayerData.job
    return job and job.name or nil
end

local function decodeList(raw)
    if type(raw) == 'table' then return raw end
    if not raw or raw == '' then return {} end
    local ok, list = pcall(json.decode, raw)
    return ok and type(list) == 'table' and list or {}
end

local function decodeMap(raw)
    if type(raw) == 'table' then return raw end
    if not raw or raw == '' then return {} end
    local ok, map = pcall(json.decode, raw)
    return ok and type(map) == 'table' and map or {}
end

local function clamp(value, min, max)
    value = math.floor(tonumber(value) or 0)
    return math.max(min, math.min(max, value))
end

local function moodOf(row)
    if row.health <= 0 then return 'dead' end
    if row.stamina <= STATS.lowWarning then return 'tired' end
    if row.happiness < STATS.angryBelow then return 'angry' end
    if row.hunger <= STATS.lowWarning or row.thirst <= STATS.lowWarning then return 'sad' end

    return 'happy'
end

local function save(row)
    MySQL.update([[
        UPDATE sm_pets_pets SET health = ?, hunger = ?, thirst = ?, stamina = ?,
        happiness = ?, loyalty = ?, mood = ?, look = ?, bowl = ?, clothing = ?,
        wardrobe = ?, skills = ?, active = ? WHERE id = ?
    ]], {
        row.health, row.hunger, row.thirst, row.stamina, row.happiness, row.loyalty, row.mood,
        json.encode(row.look or {}), json.encode(row.bowl or {}), json.encode(row.clothing or {}),
        json.encode(row.wardrobe or {}), json.encode(row.skills or {}), row.active or 0, row.id
    })
end

local function hydrate(row)
    if not row then return nil end

    return {
        id = row.id,
        type = row.type,
        name = row.name,
        species = row.species,
        model = row.model,
        health = tonumber(row.health) or 0,
        hunger = tonumber(row.hunger) or 100,
        thirst = tonumber(row.thirst) or 100,
        stamina = tonumber(row.stamina) or 100,
        happiness = tonumber(row.happiness) or 100,
        loyalty = tonumber(row.loyalty) or 20,
        mood = row.mood or 'happy',
        look = decodeMap(row.look),
        bowl = decodeMap(row.bowl),
        clothing = decodeList(row.clothing),
        wardrobe = decodeList(row.wardrobe),
        skills = decodeMap(row.skills),
        k9 = tonumber(row.k9) == 1,
        active = tonumber(row.active) or 0
    }
end

local function owned(src, petId)
    local id = cid(src)
    if not id then return nil end

    local row = cacheRows[petId] or MySQL.single.await('SELECT * FROM sm_pets_pets WHERE id = ?', { petId })
    if not row then return nil end
    if row.citizenid ~= id then return nil end

    cacheRows[petId] = row

    return hydrate(row)
end

local function pushStats(src, pet)
    TriggerClientEvent('sm_pets:client:stats', src, pet.id, {
        health = pet.health, hunger = pet.hunger, thirst = pet.thirst,
        stamina = pet.stamina, happiness = pet.happiness, loyalty = pet.loyalty
    }, pet.skills or {})

    TriggerClientEvent('sm_pets:client:setHealth', src, pet.id, pet.health)
    TriggerClientEvent('sm_pets:client:mood', src, pet.mood)
end

lib.callback.register('sm_pets:bag', function(src)
    local id = cid(src)
    if not id then return end

    local rows = MySQL.query.await('SELECT * FROM sm_pets_pets WHERE citizenid = ? ORDER BY id', { id }) or {}
    local list = {}

    for i = 1, #rows do
        local pet = hydrate(rows[i])
        if pet then
            list[#list + 1] = {
                id = pet.id,
                type = pet.type,
                name = pet.name,
                species = pet.species,
                model = pet.model,
                health = pet.health,
                look = pet.look,
                bowl = pet.bowl,
                clothing = pet.clothing,
                wardrobe = pet.wardrobe,
                k9 = pet.k9,
                image = pet.type
            }
        end
    end

    return {
        pets = list,
        canTransfer = Config.Transfer and Config.Transfer.enabled == true
    }
end)

lib.callback.register('sm_pets:spawn', function(src, petId)
    if active[src] then return { ok = false, msg = 'Simpan pet yang sedang keluar dulu.' } end

    local pet = owned(src, petId)
    if not pet then return { ok = false, msg = 'Pet tidak ditemukan.' } end

    if pet.k9 and Config.K9 and Config.K9.blockSpawnWithoutJob then
        local job = jobName(src)

        if not job or not Config.K9.ownerJobs[job] then
            return { ok = false, msg = 'Job kamu tidak boleh memakai K9.' }
        end
    end

    local id = cid(src)
    local count = MySQL.scalar.await('SELECT COUNT(*) FROM sm_pets_pets WHERE citizenid = ?', { id }) or 0
    if count > MAX_OWNED then return { ok = false, msg = 'Terlalu banyak pet.' } end

    active[src] = petId

    return { ok = true, pet = pet }
end)

lib.callback.register('sm_pets:spawned', function(src, netId)
    local petId = active[src]
    if not petId then return false end

    if not netId or netId == 0 then
        active[src] = nil
        return false
    end

    local row = cacheRows[petId]
    if row then
        row.active = 1
        save(hydrate(row))
    end

    return true
end)

lib.callback.register('sm_pets:store', function(src)
    local petId = active[src]
    if not petId then return false end

    active[src] = nil

    local row = cacheRows[petId]
    if row then
        row.active = 0
        save(hydrate(row))
    end

    TriggerClientEvent('sm_pets:client:despawned', src, petId, 'stored')

    return true
end)

lib.callback.register('sm_pets:transfer', function(src, petId, target, fee)
    local transferCfg = Config.Transfer or {}
    if not transferCfg.enabled then return { ok = false, msg = 'Transfer dinonaktifkan.' } end

    target = tonumber(target)
    fee = clamp(fee or 0, 0, transferCfg.maxFee or 0)

    local targetId = target and cid(target)
    if not targetId then return { ok = false, msg = 'Pemain target tidak ditemukan.' } end

    local from = cid(src)
    if from == targetId then return { ok = false, msg = 'Itu pet kamu sendiri.' } end

    local pet = owned(src, petId)
    if not pet then return { ok = false, msg = 'Pet tidak ditemukan.' } end

    if transferCfg.adminOnly then
        local aces = Config.AdminJobs or {}

        if not IsPlayerAceAllowed(src, 'admin') then
            local job = jobName(src)
            if not job or not aces[job] then
                return { ok = false, msg = 'Hanya admin yang bisa transfer.' }
            end
        end
    end

    local a = GetEntityCoords(GetPlayerPed(src))
    local b = GetEntityCoords(GetPlayerPed(target))
    if #(a - b) > (transferCfg.maxDistance or 10.0) then
        return { ok = false, msg = 'Terlalu jauh dari target.' }
    end

    local owner = QBCore.Functions.GetPlayer(src)
    local info = owner and owner.PlayerData.charinfo or {}

    local accepted = lib.callback.await('sm_pets:client:transferPrompt', target, {
        from = ('%s %s'):format(info.firstname or '?', info.lastname or '?'),
        pet = pet.name,
        type = pet.type,
        fee = fee,
        seconds = transferCfg.promptSeconds or 30
    })

    if not accepted then return { ok = false, msg = 'Target menolak.' } end
    local buyer = QBCore.Functions.GetPlayer(target)
    if fee > 0 then
        if (buyer.PlayerData.money[MONEY] or 0) < fee then
            return { ok = false, msg = 'Target tidak punya cukup uang.' }
        end
        buyer.Functions.RemoveMoney(MONEY, fee, 'pet-transfer')
        QBCore.Functions.GetPlayer(src).Functions.AddMoney(MONEY, fee, 'pet-transfer')
    end

    MySQL.update.await('UPDATE sm_pets_pets SET citizenid = ? WHERE id = ?', { targetId, petId })

    if cacheRows[petId] then cacheRows[petId].citizenid = targetId end

    if active[src] == petId then
        active[src] = nil
        TriggerClientEvent('sm_pets:client:despawned', src, petId, 'owner')
    end

    notify(src, ('%s ditransfer.'):format(pet.name), 'success')
    notify(target, ('Kamu menerima %s.'):format(pet.name), 'success')

    return { ok = true, msg = 'Transfer selesai.' }
end)

RegisterNetEvent('sm_pets:server:viewing', function(state)
    local src = source
    local ped = GetPlayerPed(src)
    if ped == 0 then return end

    Player(ped).state:set('petUiOpen', state == true, true)
end)

RegisterNetEvent('sm_pets:server:hitByOwner', function()
    local src = source
    local petId = active[src]
    if not petId then return end

    local row = cacheRows[petId]
    if not row then return end

    row.happiness = clamp(row.happiness - (STATS.happinessLossHitByOwner or 20), 0, 100)
    row.loyalty = clamp(row.loyalty - (STATS.loyaltyLossHitByOwner or 5), 0, 100)
    row.mood = moodOf(row)

    pushStats(src, hydrate(row))
end)

CreateThread(function()
    MySQL.query.await(SCHEMA)

    while true do
        Wait(TICK)

        for src, petId in pairs(active) do
            local row = cacheRows[petId]

            if not row then
                active[src] = nil
            elseif not GetPlayerName(src) then
                active[src] = nil
            elseif row.health > 0 then
                row.hunger = clamp(row.hunger - (STATS.hungerDecay or 0.4), 0, 100)
                row.thirst = clamp(row.thirst - (STATS.thirstDecay or 0.4), 0, 100)
                row.stamina = clamp(row.stamina + 2, 0, 100)

                if row.hunger <= 0 then row.health = clamp(row.health - (STATS.starvationDamage or 15) / 4, 0, 100) end
                if row.thirst <= 0 then row.health = clamp(row.health - (STATS.dehydrationDamage or 15) / 4, 0, 100) end

                row.mood = moodOf(row)
                save(row)

                TriggerClientEvent('sm_pets:client:setHealth', src, petId, row.health)
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(PUSH)

        for src, petId in pairs(active) do
            local row = cacheRows[petId]
            if row then pushStats(src, hydrate(row)) end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(SAVE)

        for _, row in pairs(cacheRows) do save(hydrate(row)) end
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    local petId = active[src]
    if not petId then return end

    active[src] = nil

    local row = cacheRows[petId]
    if row then
        row.active = 0
        save(hydrate(row))
    end
end)

CreateThread(function()
    local rows = MySQL.query.await('SELECT * FROM sm_pets_pets WHERE active = 1') or {}

    for i = 1, #rows do
        rows[i].active = 0
        save(hydrate(rows[i]))
    end

    print(('^2[sm_pets] %d pet di database^7'):format(#rows))
end)
SmPetsServer = {
    active = active,
    cacheRows = cacheRows,
    owned = owned,
    save = save,
    hydrate = hydrate,
    pushStats = pushStats,
    notify = notify,
    clamp = clamp,
    moodOf = moodOf,
    cid = cid
}