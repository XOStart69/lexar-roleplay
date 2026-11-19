--[[
    sm_pets :: server/k9
    Perintah K9: serang, takedown, endus pemain/kendaraan, dan latihan (cones/ramp/hoop/dummy).
    Pemahaman perintah bergantung skill, skill naik saat latihan dan turun bila lama tak dipakai.
]]

local Config = localmodule 'config.shared'
local Catalog = localmodule 'config.catalog'
local S = SmPetsServer

local k9 = Config.K9 or {}
local SKILL = k9.skills or {}
local wardrobe = Catalog.wardrobe or {}

local attackCooldown = {}
local sniffCooldown = {}

local function petRow(src)
    local petId = S.active[src]
    if not petId then return nil, nil end

    local row = S.cacheRows[petId]
    if not row then return nil, nil end

    return petId, row
end

local function isHandler(src)
    local player = exports['qb-core']:GetCoreObject().Functions.GetPlayer(src)
    local job = player and player.PlayerData.job

    return job ~= nil and k9.jobs and k9.jobs[job.name] == true
end

local function skillsOf(row)
    local pet = S.hydrate(row)
    return pet.skills or {}
end

local function skillValue(row, name)
    local value = skillsOf(row)[name]
    local cfg = SKILL[name]

    return tonumber(value) or (cfg and cfg.default) or 20
end

local function gainSkill(row, name)
    local cfg = SKILL[name]
    if not cfg then return end

    local skills = skillsOf(row)
    skills[name] = math.min(100, (tonumber(skills[name]) or cfg.default) + (cfg.gain or 5))
    row.skills = skills
end

local function cooling(store, src, ms)
    local now = GetGameTimer()
    local untilAt = store[src]

    if untilAt and now < untilAt then return true, untilAt - now end

    store[src] = now + ms

    return false
end

local function hasItem(name, list)
    for i = 1, #list do
        if list[i] == name then return true end
    end

    return false
end

local function itemsOf(src)
    local items = exports.ox_inventory:GetInventoryItems(src) or {}
    local names = {}

    for _, item in pairs(items) do
        if item and item.name then names[#names + 1] = item.name end
    end

    return names
end

local function understands(row, name)
    local value = skillValue(row, name)
    return math.random(1, 100) <= value
end

lib.callback.register('sm_pets:k9:attack', function(src, target)
    local petId, row = petRow(src)
    if not row then return { ok = false, msg = 'Keluarkan pet dulu.' } end
    if row.health <= 0 then return { ok = false, msg = 'Pet sedang pingsan.' } end
    if not isHandler(src) then return { ok = false, msg = 'Hanya petugas yang bisa memberi perintah K9.' } end

    local targetId = tonumber(target)
    if not targetId or not GetPlayerName(targetId) then
        return { ok = false, msg = 'Target tidak ditemukan.' }
    end

    local busy, left = cooling(attackCooldown, src, k9.attackCooldownMs or 20000)
    if busy then return { ok = false, msg = ('Tunggu %d detik.'):format(math.ceil(left / 1000)) } end

    local cost = (Config.Stats and Config.Stats.attack) or {}
    row.stamina = S.clamp(row.stamina - (cost.stamina or 5), 0, 100)
    row.hunger = S.clamp(row.hunger - (cost.hunger or 5), 0, 100)
    row.thirst = S.clamp(row.thirst - (cost.thirst or 5), 0, 100)

    local understood = understands(row, 'attack')
    if understood then gainSkill(row, 'attack') end

    row.mood = S.moodOf(row)
    S.save(row)
    S.pushStats(src, S.hydrate(row))

    return { ok = true, understood = understood, agility = skillValue(row, 'agility') }
end)

lib.callback.register('sm_pets:k9:takedown', function(src, target)
    local _, row = petRow(src)
    if not row then return false end

    local targetId = tonumber(target)
    if not targetId or not GetPlayerName(targetId) then return false end

    local lethal = row.health <= 0 or (k9.attackerKills == true and false)

    TriggerClientEvent('sm_pets:client:takedown', targetId, src, k9.takedownMs or 10000, lethal == true)

    return true
end)

lib.callback.register('sm_pets:k9:sniffPlayer', function(src, target)
    local _, row = petRow(src)
    if not row then return 0 end
    if not isHandler(src) then return 0 end

    local busy = cooling(sniffCooldown, src, k9.sniffCooldownMs or 5000)
    if busy then return 0 end

    local targetId = tonumber(target)
    if not targetId or not GetPlayerName(targetId) then return 0 end

    local items = itemsOf(targetId)
    local found = 0

    for i = 1, #items do
        if hasItem(items[i], k9.drugItems or {}) then found = 1 break end
    end

    if found == 0 then
        for i = 1, #items do
            if hasItem(items[i], k9.moneyItems or {}) then found = 2 break end
        end
    end

    if found == 0 then
        for i = 1, #items do
            if hasItem(items[i], k9.weaponItems or {}) then found = 3 break end
        end
    end

    if found == 0 then
        for i = 1, #items do
            if hasItem(items[i], k9.contrabandItems or {}) then found = 4 break end
        end
    end

    gainSkill(row, 'sniff')
    S.save(row)

    if found > 0 and math.random(1, 100) > skillValue(row, 'sniff') then return 0 end

    return found
end)

lib.callback.register('sm_pets:k9:sniffVehicle', function(src, netId)
    local _, row = petRow(src)
    if not row then return 0 end
    if not isHandler(src) then return 0 end

    local busy = cooling(sniffCooldown, src, k9.sniffCooldownMs or 5000)
    if busy then return 0 end

    local entity = NetworkGetEntityFromNetworkId(tonumber(netId) or 0)
    if not entity or entity == 0 then return 0 end

    local trunk = GetVehicleDoorLockStatus(entity)

    gainSkill(row, 'sniff')
    S.save(row)

    if math.random(1, 100) > skillValue(row, 'sniff') then return 0 end

    return math.random(1, 4)
end)

lib.callback.register('sm_pets:k9:trainStart', function(src, key)
    local _, row = petRow(src)
    if not row then return { ok = false, msg = 'Keluarkan pet dulu.' } end
    if row.health <= 0 then return { ok = false, msg = 'Pet sedang pingsan.' } end
    if not isHandler(src) then return { ok = false, msg = 'Hanya petugas yang bisa melatih K9.' } end

    local item = wardrobe[key]
    if not item then return { ok = false, msg = 'Alat latihan tidak dikenal.' } end

    local cfg = k9.training and k9.training[item.kind] or k9.training and k9.training[item.training]
    if not cfg then return { ok = false, msg = 'Alat latihan tidak valid.' } end

    if row.stamina < (cfg.stamina or 5) then return { ok = false, msg = 'Pet kelelahan.' } end

    row.stamina = S.clamp(row.stamina - (cfg.stamina or 5), 0, 100)
    row.mood = S.moodOf(row)
    S.save(row)
    S.pushStats(src, S.hydrate(row))

    return { ok = true, kind = item.training or item.kind, success = math.random(1, 100) > (cfg.tripChance or 50) }
end)

lib.callback.register('sm_pets:k9:trainFinish', function(src)
    local _, row = petRow(src)
    if not row then return { ok = false } end

    gainSkill(row, 'agility')
    row.mood = S.moodOf(row)
    S.save(row)
    S.pushStats(src, S.hydrate(row))

    return { ok = true, result = 'perfect' }
end)

lib.callback.register('sm_pets:k9:dummyBite', function(src)
    local _, row = petRow(src)
    if not row then return false end

    gainSkill(row, 'attack')
    S.save(row)

    return true
end)

CreateThread(function()
    local decay = (SKILL.sniff and SKILL.sniff.decay) or 5
    local every = (k9.skillDecaySeconds or 720) * 1000

    while true do
        Wait(every)

        for _, row in pairs(S.cacheRows) do
            local skills = skillsOf(row)
            local changed = false

            for name, value in pairs(skills) do
                local cfg = SKILL[name]
                if cfg and tonumber(value) then
                    skills[name] = math.max(cfg.min or 1, (tonumber(value) or 0) - decay)
                    changed = true
                end
            end

            if changed then row.skills = skills end
        end
    end
end)

AddEventHandler('playerDropped', function()
    local src = source

    attackCooldown[src] = nil
    sniffCooldown[src] = nil
end)