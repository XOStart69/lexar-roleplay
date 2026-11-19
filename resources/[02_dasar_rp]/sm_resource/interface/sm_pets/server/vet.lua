--[[
    sm_pets :: server/vet
    Meja perawatan di toko pemain. Pet di atas meja dikunci per meja, hanya vet yang boleh merawat.
]]

local Config = localmodule 'config.shared'
local S = SmPetsServer

local vet = Config.Vet or {}

local QBCore = exports['qb-core']:GetCoreObject()

local tables = {}

local function jobOf(src)
    local player = QBCore.Functions.GetPlayer(src)
    local job = player and player.PlayerData.job
    if not job then return nil, 0 end

    return job.name, tonumber(type(job.grade) == 'table' and job.grade.level or job.grade) or 0
end

local function isVet(src)
    local name, grade = jobOf(src)
    if not name then return false end
    if vet.jobs and vet.jobs[name] then return true end

    local list = GlobalState.smPetTables and shopsCache or nil
    local shops = GlobalState.smPetShops

    if not shops then return false end

    for i = 1, #shops do
        local shop = shops[i]
        if shop.job == name and grade >= (shop.vetGrade or 1) then return true end
    end

    return false
end

local function publish()
    GlobalState.smPetTables = tables
end

local function key(shopId, index)
    return ('%s:%s'):format(shopId, index)
end

lib.callback.register('sm_pets:vet:placeOnTable', function(src, shopId, index)
    local petId = S.active[src]
    if not petId then return { ok = false, msg = 'Kamu tidak sedang membawa pet.' } end

    local row = S.cacheRows[petId]
    if not row then return { ok = false, msg = 'Pet tidak ditemukan.' } end

    local k = key(tonumber(shopId) or 0, tonumber(index) or 0)
    if tables[k] then return { ok = false, msg = 'Meja sedang dipakai.' } end

    tables[k] = { citizenid = row.citizenid, src = src, petId = petId }
    publish()

    return { ok = true }
end)

lib.callback.register('sm_pets:vet:removeFromTable', function(src)
    for k, entry in pairs(tables) do
        if entry.src == src then
            tables[k] = nil
            publish()
            return true
        end
    end

    return false
end)

lib.callback.register('sm_pets:vet:treat', function(src, shopId, index)
    local k = key(tonumber(shopId) or 0, tonumber(index) or 0)
    local entry = tables[k]

    if not entry then return { ok = false, msg = 'Tidak ada pet di meja ini.' } end
    if not isVet(src) then return { ok = false, msg = 'Kamu bukan vet di toko ini.' } end

    local row = S.cacheRows[entry.petId]
    if not row then return { ok = false, msg = 'Pet tidak ditemukan.' } end

    local cost = (Config.Stats and Config.Stats.healCost) or {}
    row.hunger = S.clamp(row.hunger - (cost.hunger or 3), 0, 100)
    row.thirst = S.clamp(row.thirst - (cost.thirst or 3), 0, 100)
    row.health = 100
    row.loyalty = S.clamp(row.loyalty + ((Config.Stats and Config.Stats.loyaltyGainHeal) or 1), 0, 100)
    row.mood = S.moodOf(row)

    S.save(row)

    if entry.src and GetPlayerName(entry.src) then
        S.pushStats(entry.src, S.hydrate(row))
        TriggerClientEvent('sm_pets:client:setHealth', entry.src, entry.petId, 100)
        S.notify(entry.src, 'Pet kamu sudah dirawat.', 'success')
    end

    return { ok = true, msg = 'Pet dirawat.' }
end)

AddEventHandler('playerDropped', function()
    local src = source
    local changed = false

    for k, entry in pairs(tables) do
        if entry.src == src then
            tables[k] = nil
            changed = true
        end
    end

    if changed then publish() end
end)

CreateThread(function()
    publish()
end)