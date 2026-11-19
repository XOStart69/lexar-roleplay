--[[
    sm_carheist :: server
    Satu heist per pemain, maksimal sesuai maxActive, cooldown setelah selesai.
    Lokasi dipilih server, tracker dan pemotongan divalidasi berurutan.
]]

local srv = localmodule 'config.server'
local shared = localmodule 'config.shared'

local REQUIRED = srv.requiredJob or {}
local REWARDS = srv.rewards or {}
local LOCATIONS = shared.locations or {}
local TIMER = shared.timer or {}
local MAX_ACTIVE = shared.maxActive or 3
local MODELS = shared.vehicles or {}

local MISSION = (TIMER.mission or 20) * 60
local COOLDOWN = (TIMER.cooldown or 15) * 60

local heists = {}
local cooldownUntil = {}
local pending = {}
local active = 0

local function playerOf(src)
    return qb_ecore:GetPlayer(src)
end

local function notify(src, message, kind)
    TriggerClientEvent('ox_lib:notify', src, { description = message, type = kind or 'error' })
end

local function countJob(jobName)
    local total = 0
    for _, raw in ipairs(GetPlayers()) do
        local player = playerOf(tonumber(raw))
        if player and player.PlayerData.job.name == jobName then total = total + 1 end
    end
    return total
end

local function near(src, coords, radius)
    local ped = GetPlayerPed(src)
    if ped == 0 then return false end
    return #(GetEntityCoords(ped) - vector3(coords.x, coords.y, coords.z)) <= radius
end

local function reset(src, silent)
    local job = heists[src]
    if not job then return end

    if job.netId then
        local entity = NetworkGetEntityFromNetworkId(job.netId)
        if entity ~= 0 and DoesEntityExist(entity) then DeleteEntity(entity) end
    end

    heists[src] = nil
    active = math.max(active - 1, 0)

    TriggerClientEvent('sm_carheist:client:resetHeist', src, silent == true)
end

lib.callback.register('sm_carheist:attemptjob', function(src)
    local player = playerOf(src)
    if not player then return nil end

    if heists[src] then return nil end
    if (cooldownUntil[src] or 0) > os.time() then return nil end
    if MAX_ACTIVE > 0 and active >= MAX_ACTIVE then return nil end

    if countJob('police') < (REQUIRED.police or 0) then return nil end
    if countJob('ems') < (REQUIRED.ems or 0) then return nil end

    local pool = MODELS[1]
    if not pool or #pool == 0 then return nil end

    local data = {
        vehicle = pool[math.random(#pool)],
        choppingIndex = math.random(#LOCATIONS.chopping),
        trackerIndex = 1,
        locationIndex = math.random(#LOCATIONS.pickup),
    }

    pending[src] = data
    return data
end)

lib.callback.register('sm_carheist:createVehicle', function(src, vehData)
    local player = playerOf(src)
    if not player then return nil end
    if heists[src] then return nil end

    vehData = pending[src] or (type(vehData) == 'table' and vehData or nil)
    if not vehData then return nil end

    pending[src] = nil

    local pickup = LOCATIONS.pickup[tonumber(vehData.locationIndex) or 1]
    if not pickup then return nil end

    local entity = CreateVehicle(GetHashKey(vehData.vehicle), pickup.spawn.x, pickup.spawn.y, pickup.spawn.z, pickup.spawn.w, true)
    if not entity or entity == 0 then return nil end

    local netId = NetworkGetNetworkIdFromEntity(entity)
    if netId == 0 then
        DeleteEntity(entity)
        return nil
    end

    SetVehicleNumberPlateText(entity, ('CH%d%d%d'):format(math.random(100, 999), math.random(10, 99), os.time() % 100))

    heists[src] = {
        stage = 'pickup',
        netId = netId,
        choppingIndex = tonumber(vehData.choppingIndex) or 1,
        expires = os.time() + MISSION,
    }

    active = active + 1

    TriggerClientEvent('sm_carheist:client:syncTimer', src, MISSION)

    return netId, MISSION
end)

RegisterNetEvent('sm_carheist:server:trackerRemoved', function()
    local src = source
    local job = heists[src]
    if not job or job.stage ~= 'pickup' then return end

    local point = LOCATIONS.removeTracker[1]
    if point and not near(src, point, 6.0) then return notify(src, 'Bukan di titik pelepasan tracker.') end

    job.stage = 'chop'
    job.trackerRemoved = true

    for _, raw in ipairs(GetPlayers()) do
        local target = playerOf(tonumber(raw))
        if target and target.PlayerData.job.name == 'police' then
            TriggerClientEvent('sm_carheist:client:removePoliceTracker', tonumber(raw))
        end
    end

    notify(src, 'Tracker dilepas. Bawa ke tempat potong.', 'success')
end)

lib.callback.register('sm_carheist:beginChop', function(src)
    local job = heists[src]
    if not job or job.stage ~= 'chop' then return false end
    if job.chopping then return false end

    local point = LOCATIONS.chopping[job.choppingIndex]
    if not point or not near(src, point, 8.0) then return false end

    local entity = NetworkGetEntityFromNetworkId(job.netId)
    if entity == 0 or not DoesEntityExist(entity) then return false end

    job.chopping = true
    return true
end)

RegisterNetEvent('sm_carheist:server:abortChop', function()
    local job = heists[source]
    if job then job.chopping = false end
end)

lib.callback.register('sm_carheist:finishHeist', function(src, netId)
    local job = heists[src]
    if not job then return false end
    if job.stage ~= 'chop' or not job.trackerRemoved then return false end
    if tonumber(netId) ~= job.netId then return false end

    local pool = REWARDS[1]
    if pool then
        local picks = math.random(3, 6)
        for _ = 1, picks do
            local reward = pool[math.random(#pool)]
            if reward then
                ox_inventory:AddItem(src, reward.item, math.random(reward.amount[1], reward.amount[2]))
            end
        end
    end

    cooldownUntil[src] = os.time() + COOLDOWN
    reset(src, false)

    notify(src, 'Kendaraan berhasil dipotong.', 'success')
    return true
end)

RegisterNetEvent('sm_carheist:server:resetHeist', function()
    reset(source, false)
end)

RegisterNetEvent('police_alert_carheist:triggerDispatch', function(coords)
    for _, raw in ipairs(GetPlayers()) do
        local target = playerOf(tonumber(raw))
        if target and target.PlayerData.job.name == 'police' then
            TriggerClientEvent('police_alert_carheist:triggerDispatch', tonumber(raw), coords)
        end
    end
end)

CreateThread(function()
    while true do
        Wait(5000)
        local stamp = os.time()

        for src, job in pairs(heists) do
            if job.expires <= stamp then
                reset(src, false)
                notify(src, 'Waktu misi habis.')
            else
                TriggerClientEvent('sm_carheist:client:syncTimer', src, job.expires - stamp)
                local entity = NetworkGetEntityFromNetworkId(job.netId)
                if entity ~= 0 and DoesEntityExist(entity) then
                    TriggerClientEvent('sm_carheist:client:trackerUpdate', src, GetEntityCoords(entity))
                end
            end
        end
    end
end)

AddEventHandler('playerDropped', function()
    reset(source, true)
    cooldownUntil[source] = nil
end)

print('^2[sm_carheist] server siap^7')