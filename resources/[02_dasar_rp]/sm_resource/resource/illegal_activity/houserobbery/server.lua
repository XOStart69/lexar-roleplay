--[[
    houserobbery :: server
    Otoritas: jam, polisi, level, info, kunci pickup/loot, routing bucket, timer reset.
]]

local sharedConfig = require 'resource.illegal_activity.houserobbery.config.shared'
local serverConfig = require 'resource.illegal_activity.houserobbery.config.server'

local HOUSES = sharedConfig.houses
local INTERIORS = sharedConfig.interiors
local LANG = sharedConfig.lang
local REWARDS = serverConfig.rewards

local REQUIRED_POLICE = (serverConfig.requiredJob and serverConfig.requiredJob.police) or 3
local RESET_MS = serverConfig.timeToResetHouse or 1440000
local RESERVE_MS = serverConfig.timeToReserveHouse or 600000
local BREAK_CHANCE = serverConfig.chanceOfBreakingLockpickOnSucess or 20
local SILENT_CHANCE = serverConfig.chanceOfSilentAlarmOnSucess or 20
local ALARM_CHANCE = serverConfig.chanceOfTriggerAlarmOnFail or 50
local MAX_CARRY = serverConfig.maxCarry or 2
local INFO_PRICE = (sharedConfig.houseInfoSystem and sharedConfig.houseInfoSystem.price) or 500

local state = {}
local buckets = {}
local bucketOf = {}
local carrying = {}

local function say(src, key)
    local text = LANG[key] or key
    TriggerClientEvent('ox_lib:notify', src, { description = text, type = 'inform' })
end

local function playerOf(src)
    return qb_ecore:GetPlayer(src)
end

local function countJob(jobName)
    local total = 0
    for _, raw in ipairs(GetPlayers()) do
        local player = qb_ecore:GetPlayer(tonumber(raw))
        if player and player.PlayerData.job.name == jobName then total = total + 1 end
    end
    return total
end

local function houseState(index)
    state[index] = state[index] or { loot = {}, pickups = {}, takenLoot = {}, takenPickup = {}, busyLoot = {}, busyPickup = {} }
    return state[index]
end

local function nearHouse(src, house)
    local ped = GetPlayerPed(src)
    if ped == 0 then return false end
    return #(GetEntityCoords(ped) - house.coords) <= 4.0
end

local function roll(minimum, maximum)
    return math.random(tonumber(minimum) or 1, tonumber(maximum) or 1)
end

local function grant(src, item, amount)
    if not item or amount < 1 then return end
    ox_inventory:AddItem(src, item, amount)
end

local function resolvePools(poolIds)
    local out = {}

    for i = 1, #poolIds do
        local pool = REWARDS[poolIds[i]]
        if pool then
            local guaranteed = pool.isGuaranteed
            local single = pool.guaranteedType == 'single'
            local attempts = 1

            if not guaranteed then
                attempts = math.random(1, 100) <= 60 and 1 or 0
            end

            if attempts > 0 and pool.items and #pool.items > 0 then
                local picks = single and 1 or roll(pool.togive.min, pool.togive.max)

                for _ = 1, picks do
                    local item = pool.items[math.random(#pool.items)]
                    local amount = roll(pool.toget.min, pool.toget.max)
                    out[#out + 1] = { item = item, amount = amount }
                end
            end
        end
    end

    return out
end

local function allocBucket(index)
    for bucket = 600, 699 do
        if not buckets[bucket] then
            buckets[bucket] = index
            bucketOf[index] = bucket
            return bucket
        end
    end
end

local function freeBucket(index)
    local bucket = bucketOf[index]
    if bucket then
        buckets[bucket] = nil
        bucketOf[index] = nil
    end
end

local function occupants(index)
    local bucket = bucketOf[index]
    if not bucket then return {} end

    local list = {}
    for _, raw in ipairs(GetPlayers()) do
        local src = tonumber(raw)
        if GetPlayerRoutingBucket(src) == bucket then list[#list + 1] = src end
    end
    return list
end

local function syncLoot(index)
    local house = houseState(index)

    for _, src in ipairs(occupants(index)) do
        TriggerClientEvent('mad-houserobbery:client:syncLoot', src, index, house.loot, house.pickups)
    end
end

local function resetHouse(index)
    local house = HOUSES[index]
    local st = state[index]
    if not house or not st then return end

    for _, src in ipairs(occupants(index)) do
        SetPlayerRoutingBucket(src, 0)
        TriggerClientEvent('houserobbery:client:removeLoot', src, house.interior)
    end

    if house.peds then
        for i = 1, #house.peds do
            if DoesEntityExist(house.peds[i]) then DeleteEntity(house.peds[i]) end
        end
        house.peds = {}
    end

    house.opened = false
    house.isAlarmTriggered = false
    freeBucket(index)

    state[index] = { loot = {}, pickups = {}, takenLoot = {}, takenPickup = {}, busyLoot = {}, busyPickup = {} }
end

local function openHouse(index, st)
    local house = HOUSES[index]
    local pool = INTERIORS[house.interior]

    local lootCount = roll(house.setup.loot.min, house.setup.loot.max)
    local pickupCount = roll(house.setup.pickups.min, house.setup.pickups.max)

    local lootSource = {}
    for i = 1, #pool.loot do lootSource[i] = i end

    for _ = 1, math.min(lootCount, #lootSource) do
        local pick = math.random(#lootSource)
        st.loot[#st.loot + 1] = pool.loot[lootSource[pick]]
        table.remove(lootSource, pick)
    end

    local pickupSource = {}
    for i = 1, #pool.pickups do pickupSource[i] = i end

    for _ = 1, math.min(pickupCount, #pickupSource) do
        local pick = math.random(#pickupSource)
        st.pickups[#st.pickups + 1] = pool.pickups[pickupSource[pick]]
        table.remove(pickupSource, pick)
    end

    house.opened = true
    st.openedAt = os.time()
    st.reservedUntil = os.time() + math.floor(RESERVE_MS / 1000)
end

lib.callback.register('mad-houserobbery:server:enterHouse', function(src, index)
    index = tonumber(index)
    local house = index and HOUSES[index]
    if not house then say(src, 'nohouse') return false end

    local player = playerOf(src)
    if not player then return false end

    local cid = player.PlayerData.citizenid
    local st = houseState(index)
    local now = os.time()

    if house.opened then
        if st.reservedBy and st.reservedBy ~= cid and st.reservedUntil and st.reservedUntil > now then
            say(src, 'busy')
            return false
        end

        if not nearHouse(src, house) then say(src, 'nohouse') return false end

        if not st.reservedBy then st.reservedBy = cid end

        local bucket = bucketOf[index] or allocBucket(index)
        if not bucket then say(src, 'busy') return false end

        SetPlayerRoutingBucket(src, bucket)
        TriggerClientEvent('mad-houserobbery:client:syncLoot', src, index, st.loot, st.pickups)
        return true
    end

    if not nearHouse(src, house) then say(src, 'nohouse') return false end

    local hour = GetClockHours()
    if not (hour >= 22 or hour < 5) then say(src, 'wrong_time') return false end

    if countJob('police') < REQUIRED_POLICE then
        if serverConfig.notEnoughCopsNotify then say(src, 'nopolice') end
        return false
    end

    local levels = serverConfig.levels or {}
    local need = levels[house.level or 1]
    if need and need > 0 then
        local xp = tonumber(player.PlayerData.metadata.housexp) or 0
        if xp < need then say(src, 'noxp') return false end
    end

    local info = player.PlayerData.metadata.houseinfo or {}
    if not info[tostring(index)] then say(src, 'noinfo') return false end

    local tool = sharedConfig.lockpickItem or 'lockpick'
    if (ox_inventory:GetItemCount(src, tool) or 0) < 1 then say(src, 'nolockpick') return false end

    if math.random(1, 100) <= BREAK_CHANCE then
        ox_inventory:RemoveItem(src, tool, 1)
        say(src, 'lockpick_broken')
    end

    openHouse(index, st)
    st.reservedBy = cid

    if math.random(1, 100) <= SILENT_CHANCE then
        house.isAlarmTriggered = true
        say(src, 'alarm_silent')
        TriggerClientEvent('houserobbery:triggerDispatch', -1, { coords = house.coords, silent = true })
    elseif math.random(1, 100) <= ALARM_CHANCE then
        house.isAlarmTriggered = true
        say(src, 'alarm_triggered')
        TriggerClientEvent('houserobbery:triggerDispatch', -1, { coords = house.coords })
    end

    local bucket = allocBucket(index)
    if bucket then SetPlayerRoutingBucket(src, bucket) end

    TriggerClientEvent('mad-houserobbery:client:syncLoot', src, index, st.loot, st.pickups)
    say(src, 'lockpick_success')

    return true
end)

lib.callback.register('mad-houserobbery:server:checkLoot', function(src, index, lootId)
    index, lootId = tonumber(index), tonumber(lootId)

    local player = playerOf(src)
    local st = index and state[index]
    if not player or not st then return false end

    local cid = player.PlayerData.citizenid
    if st.takenLoot[lootId] then return false end
    if st.busyLoot[lootId] and st.busyLoot[lootId] ~= cid then return false end
    if (carrying[cid] or 0) >= MAX_CARRY then say(src, 'alreadycarry') return false end

    st.busyLoot[lootId] = cid
    return true
end)

lib.callback.register('mad-houserobbery:server:checkPickup', function(src, index, pickupId)
    index, pickupId = tonumber(index), tonumber(pickupId)

    local player = playerOf(src)
    local st = index and state[index]
    if not player or not st then return false end

    local cid = player.PlayerData.citizenid
    if st.takenPickup[pickupId] then return false end
    if st.busyPickup[pickupId] and st.busyPickup[pickupId] ~= cid then return false end
    if (carrying[cid] or 0) >= MAX_CARRY then say(src, 'alreadycarry') return false end

    st.busyPickup[pickupId] = cid
    return true
end)

local function finishCommon(src, index, id, kind)
    local player = playerOf(src)
    local st = index and state[index]
    local house = index and HOUSES[index]
    if not player or not st or not house then return end

    local cid = player.PlayerData.citizenid
    local entry = (kind == 'loot') and st.loot[id] or st.pickups[id]
    if not entry then return end

    if kind == 'loot' then
        st.busyLoot[id] = nil
        if st.takenLoot[id] then return end
        st.takenLoot[id] = true

        local drops = resolvePools(entry.pool or {})
        for i = 1, #drops do grant(src, drops[i].item, drops[i].amount) end
        say(src, 'loot_success')
    else
        st.busyPickup[id] = nil
        if st.takenPickup[id] then return end
        st.takenPickup[id] = true

        if entry.reward then grant(src, entry.reward, 1) end
        say(src, 'loot_success')
    end

    carrying[cid] = (carrying[cid] or 0) + 1
    SetTimeout(2000, function() carrying[cid] = math.max((carrying[cid] or 1) - 1, 0) end)

    local lootLeft, pickupLeft = false, false
    for i = 1, #st.loot do if not st.takenLoot[i] then lootLeft = true break end end
    for i = 1, #st.pickups do if not st.takenPickup[i] then pickupLeft = true break end end

    syncLoot(index)

    if not lootLeft and not pickupLeft then
        for _, target in ipairs(occupants(index)) do
            TriggerClientEvent('houserobbery:client:removeLoot', target, house.interior)
        end
    end
end

RegisterNetEvent('mad-houserobbery:server:lootFinished', function(index, lootId)
    finishCommon(source, tonumber(index), tonumber(lootId), 'loot')
end)

RegisterNetEvent('mad-houserobbery:server:pickupFinished', function(index, pickupId)
    finishCommon(source, tonumber(index), tonumber(pickupId), 'pickup')
end)

RegisterNetEvent('mad-houserobbery:server:lootCancelled', function(index, lootId)
    local player = playerOf(source)
    local st = tonumber(index) and state[tonumber(index)]
    if not player or not st then return end
    if st.busyLoot[tonumber(lootId)] == player.PlayerData.citizenid then
        st.busyLoot[tonumber(lootId)] = nil
    end
end)

RegisterNetEvent('mad-houserobbery:server:pickupCancelled', function(index, pickupId)
    local player = playerOf(source)
    local st = tonumber(index) and state[tonumber(index)]
    if not player or not st then return end
    if st.busyPickup[tonumber(pickupId)] == player.PlayerData.citizenid then
        st.busyPickup[tonumber(pickupId)] = nil
    end
end)

RegisterNetEvent('houserobbery:triggerDispatch', function(data)
    local house = nil
    if type(data) == 'table' and data.coords then house = data.coords end
    if not house then return end

    for _, raw in ipairs(GetPlayers()) do
        local src = tonumber(raw)
        local player = qb_ecore:GetPlayer(src)
        if player and player.PlayerData.job.name == 'police' then
            TriggerClientEvent('houserobbery:triggerDispatch', src, data)
        end
    end
end)

lib.callback.register('mad-houserobbery:server:buyInfo', function(src, index)
    index = tonumber(index)
    local house = index and HOUSES[index]
    if not house then return false end

    local player = playerOf(src)
    if not player then return false end

    local info = player.PlayerData.metadata.houseinfo or {}
    if info[tostring(index)] then return true end

    if not player.Functions.RemoveMoney('cash', INFO_PRICE, 'house-info') then
        if not player.Functions.RemoveMoney('bank', INFO_PRICE, 'house-info') then return false end
    end

    info[tostring(index)] = true
    player.Functions.SetMetaData('houseinfo', info)

    return true
end)

CreateThread(function()
    while true do
        Wait(10000)
        local now = os.time()

        for index, st in pairs(state) do
            if st.openedAt and now - st.openedAt >= math.floor(RESET_MS / 1000) then
                resetHouse(index)
            end
        end

        for index, st in pairs(state) do
            if st.reservedBy and #occupants(index) == 0 then
                st.reservedBy = nil
                st.reservedUntil = nil
            end
        end

        for _, raw in ipairs(GetPlayers()) do
            local src = tonumber(raw)
            local bucket = GetPlayerRoutingBucket(src)
            if bucket ~= 0 then
                local index = buckets[bucket]
                local house = index and HOUSES[index]

                if not house or #(GetEntityCoords(GetPlayerPed(src)) - house.coords) > 25.0 then
                    SetPlayerRoutingBucket(src, 0)
                end
            end
        end
    end
end)

AddEventHandler('playerDropped', function()
    local player = qb_ecore:GetPlayer(source)
    if player then carrying[player.PlayerData.citizenid] = nil end
    SetPlayerRoutingBucket(source, 0)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    for _, raw in ipairs(GetPlayers()) do
        SetPlayerRoutingBucket(tonumber(raw), 0)
    end
end)

print('^2[houserobbery] server siap^7')