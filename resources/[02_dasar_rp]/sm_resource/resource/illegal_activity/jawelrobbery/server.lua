--[[
    jawel_robbery :: server
    Kunci per tahap + per indeks. Hadiah digulir server dari data/rewards.lua.
]]

local cfg = require 'resource.illegal_activity.jawelrobbery.config'
local location = require 'resource.illegal_activity.jawelrobbery.data.location'
local rewards = require 'resource.illegal_activity.jawelrobbery.data.rewards'

local REQUIRED_POLICE = (cfg.requiredJob or {}).police or 7
local REQUIRED_EMS = (cfg.requiredJob or {}).ems or 4
local COOLDOWN = (cfg.cooldown or 60) * 60
local ALARM = cfg.AlarmTime or 120000
local MAX_VITRINE = cfg.MaxVitrineItems or 20
local MECHANIC = cfg.ItemMechanic or {}
local MAX_FAILS = MECHANIC.maxFails or 2

local locks = {}
local fails = {}
local robbed = false
local cooldownUntil = 0
local vitrineCount = 0

local function playerOf(src)
    return qb_ecore:GetPlayer(src)
end

local function notify(src, message, kind)
    TriggerClientEvent('ox_lib:notify', src, { title = cfg.NotificationTitle, description = message, type = kind or 'error' })
end

local function countJob(jobName)
    local total = 0
    for _, raw in ipairs(GetPlayers()) do
        local player = playerOf(tonumber(raw))
        if player and player.PlayerData.job.name == jobName then total = total + 1 end
    end
    return total
end

local function lockKey(stage, id)
    return ('%s:%s'):format(stage, tostring(id or '0'))
end

local function busy(stage, id)
    return locks[lockKey(stage, id)] == true
end

local function setLock(stage, id, state)
    locks[lockKey(stage, id)] = state and true or nil
end

local function near(src, coords, radius)
    local ped = GetPlayerPed(src)
    if ped == 0 then return false end
    return #(GetEntityCoords(ped) - vector3(coords.x, coords.y, coords.z)) <= radius
end

local function publish()
    local snapshot = { robbed = robbed, cooldown = cooldownUntil, vitrine = {}, painting = {} }

    for i = 1, #location.vitrine do
        snapshot.vitrine[i] = { looted = location.vitrine[i].looted, inUse = busy('vitrine', i) }
    end

    for i = 1, #location.painting do
        snapshot.painting[i] = { looted = location.painting[i].looted, inUse = busy('painting', i) }
    end

    GlobalState.jawelState = snapshot
end

local function resetAll()
    robbed = false
    vitrineCount = 0
    locks = {}
    fails = {}

    location.robbed = false
    location.glass_cutting.looted = false
    location.locker.looted = false
    location.laser.laser_disabled = false

    for i = 1, #location.vitrine do
        location.vitrine[i].looted = false
        location.vitrine[i].inUse = false
    end

    for i = 1, #location.painting do
        location.painting[i].looted = false
        location.painting[i].inUse = false
    end

    publish()
    TriggerClientEvent('jawel_robbery:client:refresh', -1)
end

local function give(src, item, amount)
    if not item then return end
    ox_inventory:AddItem(src, item, math.max(tonumber(amount) or 1, 1))
end

lib.callback.register('jawel_robbery:canheist', function(src)
    if robbed then return false end
    if cooldownUntil > os.time() then return false end
    if countJob('police') < REQUIRED_POLICE then return false end
    if countJob('ems') < REQUIRED_EMS then return false end
    return true
end)

lib.callback.register('jawel_robbery:consumeItem', function(src, itemName)
    itemName = tostring(itemName or '')
    if itemName == '' then return false end
    if (ox_inventory:GetItemCount(src, itemName) or 0) < 1 then return false end

    if not ox_inventory:RemoveItem(src, itemName, 1) then return false end

    fails[src] = fails[src] or {}
    fails[src][itemName] = 0

    return true
end)

RegisterNetEvent('jawel_robbery:itemFailed', function(itemName)
    local src = source
    itemName = tostring(itemName or '')

    fails[src] = fails[src] or {}
    fails[src][itemName] = (fails[src][itemName] or 0) + 1

    if fails[src][itemName] >= MAX_FAILS then
        notify(src, ('%s hancur.'):format(itemName))
        fails[src][itemName] = 0
    else
        notify(src, ('%s gagal (%d/%d).'):format(itemName, fails[src][itemName], MAX_FAILS))
    end
end)

RegisterNetEvent('jawel_robbery:setInUse', function(stage, id, state)
    setLock(stage, id, state)
    publish()
end)

RegisterNetEvent('jawel_robbery:start', function()
    local src = source
    if robbed then return end

    robbed = true
    location.robbed = true
    cooldownUntil = os.time() + COOLDOWN

    publish()
    TriggerClientEvent('jawel_robbery:client:alarm', -1, true)

    for _, raw in ipairs(GetPlayers()) do
        local player = playerOf(tonumber(raw))
        if player and player.PlayerData.job.name == 'police' then
            TriggerClientEvent('jawel_robbery:client:dispatch', tonumber(raw))
        end
    end

    SetTimeout(ALARM, function()
        TriggerClientEvent('jawel_robbery:client:alarm', -1, false)
        resetAll()
    end)
end)

local function vitrineAt(index)
    return location.vitrine[tonumber(index) or 0]
end

lib.callback.register('jawel_robbery:syncLoot', function(src, index)
    local entry = vitrineAt(index)
    if not entry then return false end
    if entry.looted then return false end
    if busy('vitrine', index) then return false end
    if not near(src, entry.coords, 3.0) then return false end

    setLock('vitrine', index, true)
    publish()

    return true
end)

RegisterNetEvent('jawel_robbery:syncLoot', function(index)
    local entry = vitrineAt(index)
    if not entry or entry.looted then return end
    setLock('vitrine', index, true)
end)

RegisterNetEvent('jawel_robbery:smashSync', function(index)
    local entry = vitrineAt(index)
    if not entry then return end
    entry.smashed = true
    publish()
end)

RegisterNetEvent('jawel_robbery:lootVitrine', function(index)
    local src = source
    local entry = vitrineAt(index)
    if not entry or entry.looted then return end

    if vitrineCount >= MAX_VITRINE then return notify(src, 'Vitrin sudah habis.') end

    entry.looted = true
    vitrineCount = vitrineCount + 1
    setLock('vitrine', index, false)

    local reward = rewards.vitrine[math.random(#rewards.vitrine)]
    if reward then give(src, reward.item, math.random(reward.min or 1, reward.max or 1)) end

    publish()
    TriggerClientEvent('jawel_robbery:client:refresh', -1)
end)

lib.callback.register('jawel_robbery:syncLootPainting', function(src, sceneId)
    local entry = location.painting[tonumber(sceneId) or 0]
    if not entry or entry.looted or busy('painting', sceneId) then return false end
    if not near(src, entry.scenePos, 3.0) then return false end

    setLock('painting', sceneId, true)
    publish()

    return true
end)

RegisterNetEvent('jawel_robbery:lootPainting', function(sceneId)
    local src = source
    local entry = location.painting[tonumber(sceneId) or 0]
    if not entry or entry.looted then return end

    entry.looted = true
    setLock('painting', sceneId, false)

    give(src, rewards.painting.item, rewards.painting.amount)

    publish()
    TriggerClientEvent('jawel_robbery:client:refresh', -1)
end)

lib.callback.register('jawel_robbery:syncLootOverheat', function(src)
    if location.glass_cutting.looted or busy('glass_cutting') then return false end
    if not near(src, location.glass_cutting.displayPos, 3.5) then return false end

    setLock('glass_cutting', nil, true)
    publish()

    return true
end)

RegisterNetEvent('jawel_robbery:lootOverHeat', function()
    local src = source
    if location.glass_cutting.looted then return end

    location.glass_cutting.looted = true
    setLock('glass_cutting', nil, false)

    local reward = rewards.glass_cutting[math.random(#rewards.glass_cutting)]
    if reward then give(src, reward.item, reward.amount) end

    publish()
    TriggerClientEvent('jawel_robbery:client:refresh', -1)
end)

RegisterNetEvent('jawel_robbery:syncLasersObj', function()
    local src = source
    if location.laser.laser_disabled then return end
    if not near(src, location.laser.coords, location.laser.distance or 25) then return end

    location.laser.laser_disabled = true
    setLock('laser', nil, false)

    publish()
    TriggerClientEvent('jawel_robbery:client:refresh', -1)
end)

lib.callback.register('jawel_robbery:syncLockerLoot', function(src)
    if location.locker.looted or busy('locker') then return false end
    if not near(src, location.locker.coords, 3.0) then return false end

    setLock('locker', nil, true)
    publish()

    return true
end)

RegisterNetEvent('jawel_robbery:giveLockerReward', function()
    local src = source
    if location.locker.looted then return end

    location.locker.looted = true
    setLock('locker', nil, false)

    if math.random(1, 100) <= (rewards.locker.lucky.chance or 30) then
        give(src, rewards.locker.lucky.item, math.random(1, rewards.locker.lucky.max or 2))
    else
        local zonk = rewards.locker.zonk[math.random(#rewards.locker.zonk)]
        if zonk then give(src, zonk.item, zonk.amount) end
    end

    publish()
    TriggerClientEvent('jawel_robbery:client:refresh', -1)
end)

AddEventHandler('playerDropped', function()
    fails[source] = nil
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    publish()
end)

print('^2[jawel_robbery] server siap^7')