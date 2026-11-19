--[[
    sm_pets :: server/actions
    Efek statistik untuk aksi: elus, lempar bola, pakai aksesori, kasur.
    Cooldown per pemain disimpan di memori.
]]

local Config = localmodule 'config.shared'
local Catalog = localmodule 'config.catalog'
local S = SmPetsServer

local wardrobe = Catalog.wardrobe or {}
local STATS = Config.Stats or {}

local following = {}
local cooldowns = {}
local beds = {}

local function petRow(src)
    local petId = S.active[src]
    if not petId then return nil, nil end

    local row = S.cacheRows[petId]
    if not row then return nil, nil end

    return petId, row
end

local function inWardrobe(row, key)
    local list = S.hydrate(row).wardrobe

    for i = 1, #list do
        if list[i] == key then return true end
    end

    return false
end

local function applyCost(row, cost)
    for key, value in pairs(cost or {}) do
        row[key] = S.clamp((row[key] or 0) - value, 0, 100)
    end
end

local function cooling(src, kind, ms)
    cooldowns[src] = cooldowns[src] or {}

    local now = GetGameTimer()
    local untilAt = cooldowns[src][kind]

    if untilAt and now < untilAt then return true, untilAt - now end

    cooldowns[src][kind] = now + ms

    return false
end

lib.callback.register('sm_pets:follow', function(src, state)
    local _, row = petRow(src)
    if not row or row.health <= 0 then return false end

    following[src] = state == true

    return true
end)

lib.callback.register('sm_pets:cuddle', function(src)
    local _, row = petRow(src)
    if not row or row.health <= 0 then return false end

    local busy, left = cooling(src, 'cuddle', (STATS.cuddleCooldownSeconds or 300) * 1000)

    if busy then
        S.notify(src, ('Tunggu %d detik lagi.'):format(math.ceil(left / 1000)), 'error')
        return false
    end

    row.happiness = S.clamp(row.happiness + (STATS.happinessCuddle or 5), 0, 100)

    if row.happiness >= (STATS.loyalThreshold or 80) then
        row.loyalty = S.clamp(row.loyalty + (STATS.loyaltyGainHappy or 1), 0, 100)
    end

    row.mood = S.moodOf(row)
    S.save(row)
    S.pushStats(src, S.hydrate(row))

    return true
end)

lib.callback.register('sm_pets:bedState', function(src, state)
    beds[src] = state == true
    return true
end)

lib.callback.register('sm_pets:canAct', function(src)
    local _, row = petRow(src)
    return row ~= nil and row.health > 0
end)

lib.callback.register('sm_pets:pose', function(src)
    local _, row = petRow(src)
    return row ~= nil and row.health > 0
end)

lib.callback.register('sm_pets:fetchThrow', function(src)
    local _, row = petRow(src)
    if not row or row.health <= 0 then return false end

    local cost = STATS.fetch or {}
    if row.stamina < (cost.stamina or 4) then
        S.notify(src, 'Pet kelelahan.', 'error')
        return false
    end

    local busy, left = cooling(src, 'fetch', cost.cooldownMs or 2500)
    if busy then
        S.notify(src, ('Tunggu %d detik.'):format(math.ceil(left / 1000)), 'error')
        return false
    end

    applyCost(row, cost)
    row.mood = S.moodOf(row)
    S.save(row)
    S.pushStats(src, S.hydrate(row))

    return true
end)

lib.callback.register('sm_pets:fetchReturn', function(src)
    local _, row = petRow(src)
    if not row then return end

    row.happiness = S.clamp(row.happiness + (STATS.fetch and STATS.fetch.happiness or 5), 0, 100)
    row.mood = S.moodOf(row)
    S.save(row)
    S.pushStats(src, S.hydrate(row))
end)

lib.callback.register('sm_pets:equip', function(src, key)
    local _, row = petRow(src)
    if not row then return { ok = false, msg = 'Keluarkan pet dulu.' } end

    local item = wardrobe[key]
    if not item then return { ok = false, msg = 'Item tidak dikenal.' } end
    if not inWardrobe(row, key) then return { ok = false, msg = 'Item tidak ada di lemari.' } end

    if item.cat == 'bowl' then
        row.bowl = key
        S.save(row)
        return { ok = true, bowl = key }
    end

    local look = S.hydrate(row).look
    look[tostring(item.comp)] = { item.draw or 0, item.tex or 0 }
    row.look = look
    S.save(row)

    return { ok = true, look = look, rawLook = look }
end)

lib.callback.register('sm_pets:useAccessory', function(src, key)
    local _, row = petRow(src)
    if not row then return { ok = false, msg = 'Keluarkan pet dulu.' } end

    local item = wardrobe[key]
    if not item then return { ok = false } end
    if not inWardrobe(row, key) then return { ok = false, msg = 'Item tidak ada di lemari.' } end
    if row.health <= 0 and item.kind ~= 'bed' then return { ok = false, msg = 'Pet sedang pingsan.' } end

    local kind = item.kind
    local cost, cooldown

    if kind == 'fetch' or kind == 'playball' then
        cost = STATS.fetch
        cooldown = STATS.fetch and STATS.fetch.cooldownMs
    elseif kind == 'training' then
        cost = { stamina = 5 }
        cooldown = Config.K9 and Config.K9.trainingCooldownMs
    elseif kind == 'bed' then
        beds[src] = true
    end

    if cost and row.stamina < (cost.stamina or 0) then
        return { ok = false, msg = 'Pet kelelahan.' }
    end

    if cooldown then
        local busy, left = cooling(src, kind, cooldown)
        if busy then return { ok = false, msg = ('Tunggu %d detik.'):format(math.ceil(left / 1000)) } end
    end

    if cost then applyCost(row, cost) end

    row.mood = S.moodOf(row)
    S.save(row)
    S.pushStats(src, S.hydrate(row))

    return { ok = true }
end)

CreateThread(function()
    local regen = (STATS.staminaRegenBed or 20) / 12

    while true do
        Wait(5000)

        for src in pairs(beds) do
            local _, row = petRow(src)

            if not row then
                beds[src] = nil
            else
                row.stamina = S.clamp(row.stamina + regen, 0, 100)
            end
        end
    end
end)

AddEventHandler('playerDropped', function()
    local src = source

    following[src] = nil
    cooldowns[src] = nil
    beds[src] = nil
end)