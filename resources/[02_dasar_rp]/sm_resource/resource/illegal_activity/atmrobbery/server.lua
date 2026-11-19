--[[
    atmrobbery :: server
    Kunci per ATM (kunci = model+koordinat bulat), damage dari tarikan kendaraan, cooldown 20 menit.
]]

local sharedConfig = require 'resource.illegal_activity.atmrobbery.shared'

local START_ITEM = sharedConfig.item.start
local REWARDS = sharedConfig.item.rewards or {}
local JOBCHECK = sharedConfig.jobcheck or {}
local DAMAGE = sharedConfig.damage or {}
local TIMING = sharedConfig.timing or {}
local LANG = sharedConfig.lang or {}

local TIME_TO_LOOT = TIMING.time_to_loot or 300
local COOLDOWN = TIMING.cooldown or 1200

local BASE = DAMAGE.base or 5
local COPS_THRESHOLD = DAMAGE.cops_threshold or 5
local VEHICLE_MULT = DAMAGE.vehicle_multiplier or {}
local CLASS_MULT = DAMAGE.class_multiplier or {}

local atms = {}
local pulling = {}

local function say(src, key)
    TriggerClientEvent('ox_lib:notify', src, { description = LANG[key] or key, type = 'inform' })
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

local function atmKey(model, coords)
    return ('%s:%.1f:%.1f:%.1f'):format(tostring(model), coords.x, coords.y, coords.z)
end

local function stateOf(key)
    atms[key] = atms[key] or {}
    return atms[key]
end

local function available(key)
    local st = atms[key]
    if not st then return true end
    if st.pulling then return false end
    if st.cooldownUntil and st.cooldownUntil > os.time() then return false end
    return true
end

local function requiredDamage(class, model)
    local factor = VEHICLE_MULT[model] or 1.0
    local classFactor = CLASS_MULT[class + 1] or 1.0
    if classFactor <= 0.0 then classFactor = 1.0 end

    local required = BASE * factor * classFactor
    if countJob('police') > COPS_THRESHOLD then required = required * 0.8 end

    return math.max(math.ceil(required), 1)
end

lib.callback.register('sm_atmrobbery:checkServiceStatus', function()
    local police = countJob('police')
    local ems = countJob('ems')

    return police >= (JOBCHECK.police or 4) and ems >= (JOBCHECK.ems or 2)
end)

lib.callback.register('sm_atmrobbery:checkCooldown', function()
    for key in pairs(atms) do
        if available(key) then return true end
    end
    return next(atms) == nil
end)

lib.callback.register('sm_atmrobbery:removedAtms', function()
    local out = {}

    for key, st in pairs(atms) do
        if st.pulling or (st.cooldownUntil and st.cooldownUntil > os.time()) then
            out[#out + 1] = { model = st.model, coords = st.coords }
        end
    end

    return out
end)

lib.callback.register('sm_atmrobbery:pullAtm', function(src, vehNet, atmModel, ropeCoords, atmHeading, atmCoords, vehOffset)
    local player = playerOf(src)
    if not player then return false end

    local coords = type(atmCoords) == 'table'
        and vector3(tonumber(atmCoords.x) or 0.0, tonumber(atmCoords.y) or 0.0, tonumber(atmCoords.z) or 0.0)
        or nil

    if not coords then return false end

    local vehicle = NetworkGetEntityFromNetworkId(tonumber(vehNet) or 0)
    if vehicle == 0 or not DoesEntityExist(vehicle) then return false end

    local ped = GetPlayerPed(src)
    if #(GetEntityCoords(ped) - coords) > 6.0 then say(src, 'too_far') return false end

    local key = atmKey(atmModel, coords)
    if not available(key) then say(src, 'cooldown') return false end

    if (ox_inventory:GetItemCount(src, START_ITEM.name) or 0) < (START_ITEM.count or 1) then
        say(src, 'no_rope')
        return false
    end

    if not ox_inventory:RemoveItem(src, START_ITEM.name, START_ITEM.count or 1) then return false end

    local class = GetVehicleClass(vehicle)
    local modelName = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)):lower()

    local st = stateOf(key)
    st.model = atmModel
    st.coords = coords
    st.owner = player.PlayerData.citizenid
    st.pulling = true
    st.damage = 0
    st.required = requiredDamage(class, modelName)

    local atmEntity = GetClosestObjectOfType(coords.x, coords.y, coords.z, 2.5, GetHashKey(atmModel), false, false, false)
    st.netId = (atmEntity and atmEntity ~= 0) and NetworkGetNetworkIdFromEntity(atmEntity) or 0

    pulling[src] = key

    TriggerClientEvent('sm_atmrobbery:removeAtm', -1, coords, atmModel)
    TriggerClientEvent('sm_atmrobbery:client:trackerUpdate', src, coords)

    return true
end)

RegisterNetEvent('sm_atmrobbery:pullTick', function(ripDamage)
    local src = source
    local key = pulling[src]
    if not key then return end

    local st = atms[key]
    if not st or not st.pulling then return end

    st.damage = st.damage + math.max(tonumber(ripDamage) or 0, 0)
    if st.damage < st.required then return end

    st.pulling = false
    st.broken = true

    TriggerClientEvent('sm_atmrobbery:enablePhysics', -1, st.netId or 0)
end)

RegisterNetEvent('sm_atmrobbery:breakAtm', function(netId)
    local src = source
    local key = pulling[src]
    if not key then return end

    local st = atms[key]
    if not st then return end

    st.pulling = false
    st.broken = true
    st.netId = tonumber(netId) or st.netId
    st.readyAt = os.time() + TIME_TO_LOOT

    TriggerClientEvent('sm_atmrobbery:enablePhysics', -1, st.netId or 0)
end)

RegisterNetEvent('sm_atmrobbery:triggerDispatch', function()
    for _, raw in ipairs(GetPlayers()) do
        local src = tonumber(raw)
        local player = qb_ecore:GetPlayer(src)
        if player and player.PlayerData.job.name == 'police' then
            TriggerClientEvent('sm_atmrobbery:client:dispatch', src)
        end
    end
end)

lib.callback.register('sm_atmrobbery:crackedAtm', function(src)
    local key = pulling[src]
    if not key then return false end

    local st = atms[key]
    if not st then return false end
    if not st.readyAt or st.readyAt > os.time() then say(src, 'not_ready') return false end

    for i = 1, #REWARDS do
        local reward = REWARDS[i]
        if math.random() <= (reward.chance or 1.0) then
            local amount = reward.count
            if type(amount) == 'table' then
                amount = math.random(amount.min or 1, amount.max or 1)
            end
            ox_inventory:AddItem(src, reward.name, amount or 1)
        end
    end

    pulling[src] = nil
    st.broken = false
    st.readyAt = nil
    st.cooldownUntil = os.time() + COOLDOWN

    TriggerClientEvent('sm_atmrobbery:client:trackerRemove', src)
    say(src, 'collected')

    return true
end)

CreateThread(function()
    while true do
        Wait(300000)
        local stamp = os.time()

        for key, st in pairs(atms) do
            if not st.pulling and (not st.cooldownUntil or st.cooldownUntil <= stamp) then
                atms[key] = nil
            end
        end
    end
end)

AddEventHandler('playerDropped', function()
    pulling[source] = nil
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    atms = {}
    pulling = {}
end)

print('^2[atmrobbery] server siap ^7')