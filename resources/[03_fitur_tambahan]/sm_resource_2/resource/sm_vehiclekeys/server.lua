--[[
    sm_vehiclekeys :: server
    Kunci per plat. Hotwire, lock, give, shared key per job. Semua otoritatif di sini.
]]

local config = localmodule 'config'

local LOCK_DISTANCE = config.lockDistance or 3.0
local GIVE_DISTANCE = config.giveDistance or 3.0
local LOCKPICK = config.lockpick or 'lockpick'
local CARJACK = config.carjack or 'screwdriverset'
local IMMUNE = {}
local NOLOCK = {}
local NOCLASS = {}

for i = 1, #(config.immuneModels or {}) do IMMUNE[GetHashKey(config.immuneModels[i])] = true end
for i = 1, #(config.noLockModels or {}) do NOLOCK[GetHashKey(config.noLockModels[i])] = true end
for i = 1, #(config.noLockClasses or {}) do NOCLASS[config.noLockClasses[i]] = true end

local SHARED = {}
for job, data in pairs(config.sharedKeys or {}) do
    local models = {}
    for i = 1, #(data.models or {}) do models[GetHashKey(data.models[i])] = true end
    SHARED[job] = { onduty = data.requireOnduty, models = models }
end

local TABLE = 'sm_vehiclekeys'
local locked = {}

local function playerOf(src)
    return qb_ecore:GetPlayer(src)
end

local function notify(src, message, kind)
    TriggerClientEvent('ox_lib:notify', src, { description = message, type = kind or 'error' })
end

local function plateOf(entity)
    if not entity or entity == 0 or not DoesEntityExist(entity) then return nil end
    local plate = GetVehicleNumberPlateText(entity)
    if not plate then return nil end
    plate = plate:gsub('%s+$', '')
    if plate == '' then return nil end
    return plate
end

local function vehicleFromNet(netId)
    local entity = NetworkGetEntityFromNetworkId(tonumber(netId) or 0)
    if entity == 0 or not DoesEntityExist(entity) then return nil end
    if GetEntityType(entity) ~= 2 then return nil end
    return entity
end

local function near(src, entity, distance)
    local ped = GetPlayerPed(src)
    if ped == 0 then return false end
    return #(GetEntityCoords(ped) - GetEntityCoords(entity)) <= distance
end

local function ownerOf(plate)
    return MySQL.scalar.await('SELECT citizenid FROM ' .. TABLE .. ' WHERE plate = ?', { plate })
end

local function hasShared(player, entity)
    local entry = SHARED[player.PlayerData.job.name]
    if not entry then return false end
    if entry.onduty and not player.PlayerData.job.onduty then return false end
    return entry.models[GetEntityModel(entity)] == true
end

local function hasKeys(player, plate, entity)
    if not player or not plate then return false end
    if ownerOf(plate) == player.PlayerData.citizenid then return true end
    if entity and hasShared(player, entity) then return true end
    return false
end

local function grant(player, plate, entity)
    local cid = player.PlayerData.citizenid
    if ownerOf(plate) then return end

    MySQL.insert('INSERT INTO ' .. TABLE .. ' (plate, citizenid, created) VALUES (?, ?, ?)', { plate, cid, os.time() })
    TriggerClientEvent('sm_vehiclekeys:client:setVehicleOwner', player.PlayerData.source, plate)

    if entity then SetVehicleDoorsLocked(entity, 1) end
end

lib.callback.register('sm_vehiclekeys:list', function(src)
    local player = playerOf(src)
    if not player then return {} end

    local rows = MySQL.query.await('SELECT plate FROM ' .. TABLE .. ' WHERE citizenid = ?', { player.PlayerData.citizenid }) or {}
    local out = {}

    for i = 1, #rows do out[i] = rows[i].plate end
    return out
end)

lib.callback.register('sm_vehiclekeys:hotwireStart', function(src, netId)
    local player = playerOf(src)
    if not player then return 0, 'Data pemain tidak siap.' end

    local entity = vehicleFromNet(netId)
    if not entity then return 0, 'Kendaraan tidak ditemukan.' end
    if not near(src, entity, 4.0) then return 0, 'Terlalu jauh.' end

    local model = GetEntityModel(entity)
    if IMMUNE[model] then return 0, 'Kendaraan ini tidak perlu dihotwire.' end
    if NOCLASS[GetVehicleClass(entity)] then return 0, 'Kelas kendaraan tidak bisa dihotwire.' end

    local plate = plateOf(entity)
    if not plate then return 0, 'Plat tidak terbaca.' end
    if hasKeys(player, plate, entity) then return 0, 'Kamu sudah punya kunci.' end

    local tool = CARJACK
    if (ox_inventory:GetItemCount(src, tool) or 0) < 1 then
        if (ox_inventory:GetItemCount(src, LOCKPICK) or 0) < 1 then
            return 0, 'Butuh alat.'
        end
        tool = LOCKPICK
    end

    local duration = math.random(6, 12) * 1000

    return duration, tool
end)

lib.callback.register('sm_vehiclekeys:hotwireFinish', function(src, success)
    local player = playerOf(src)
    if not player then return false end

    local ped = GetPlayerPed(src)
    if ped == 0 then return false end

    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle == 0 then
        local coords = GetEntityCoords(ped)
        vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 71)
    end
    if vehicle == 0 or not DoesEntityExist(vehicle) then return false end

    local plate = plateOf(vehicle)
    if not plate then return false end

    if not success then return false end

    grant(player, plate, vehicle)
    TriggerClientEvent('sm_vehiclekeys:client:AddKeys', src, plate)

    return true
end)

lib.callback.register('sm_vehiclekeys:toggleLock', function(src, netId, wanted)
    local player = playerOf(src)
    if not player then return false end

    local entity = vehicleFromNet(netId)
    if not entity then return false end
    if not near(src, entity, LOCK_DISTANCE + 1.0) then return false end

    local model = GetEntityModel(entity)
    if NOLOCK[model] then return false end

    local plate = plateOf(entity)
    if not plate then return false end
    if not hasKeys(player, plate, entity) then return false end

    local state = wanted and 2 or 1
    SetVehicleDoorsLocked(entity, state)
    locked[plate] = state

    return state == 2
end)

RegisterNetEvent('sm_vehiclekeys:server:give', function(targetSource)
    local src = source
    local player = playerOf(src)
    local target = playerOf(tonumber(targetSource) or 0)
    if not player or not target then return end

    local ped = GetPlayerPed(src)
    local vehicle = GetVehiclePedIsIn(ped, false)

    if vehicle == 0 then
        local coords = GetEntityCoords(ped)
        vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, GIVE_DISTANCE, 0, 71)
    end

    if vehicle == 0 or not DoesEntityExist(vehicle) then return notify(src, 'Tidak ada kendaraan.') end
    if #(GetEntityCoords(ped) - GetEntityCoords(GetPlayerPed(target.PlayerData.source))) > GIVE_DISTANCE + 2.0 then
        return notify(src, 'Terlalu jauh.')
    end

    local plate = plateOf(vehicle)
    if not plate then return end
    if not hasKeys(player, plate, vehicle) then return notify(src, 'Kamu tidak punya kunci kendaraan ini.') end

    MySQL.insert(
        ('INSERT IGNORE INTO %s (plate, citizenid, created) VALUES (?, ?, ?)'):format(TABLE),
        { plate, target.PlayerData.citizenid, os.time() }
    )

    TriggerClientEvent('sm_vehiclekeys:client:AddKeys', target.PlayerData.source, plate)
    notify(src, ('Kunci diberikan ke %s.'):format(target.PlayerData.charinfo.firstname), 'success')
    notify(target.PlayerData.source, 'Kamu menerima kunci.', 'success')
end)

RegisterNetEvent('sm_vehiclekeys:server:setVehicleOwner', function(plate, citizenid)
    plate = tostring(plate or ''):gsub('%s+$', '')
    citizenid = tostring(citizenid or '')
    if plate == '' or citizenid == '' then return end

    MySQL.insert(
        ('INSERT INTO %s (plate, citizenid, created) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE citizenid = VALUES(citizenid)'):format(TABLE),
        { plate, citizenid, os.time() }
    )

    for _, raw in ipairs(GetPlayers()) do
        local src = tonumber(raw)
        local player = playerOf(src)
        if player and player.PlayerData.citizenid == citizenid then
            TriggerClientEvent('sm_vehiclekeys:client:setVehicleOwner', src, plate)
        end
    end
end)

RegisterNetEvent('sm_vehiclekeys:server:removeKeys', function(plate)
    plate = tostring(plate or ''):gsub('%s+$', '')
    if plate == '' then return end

    MySQL.update('DELETE FROM ' .. TABLE .. ' WHERE plate = ?', { plate })

    for _, raw in ipairs(GetPlayers()) do
        TriggerClientEvent('sm_vehiclekeys:client:RemoveKeys', tonumber(raw), plate)
    end
end)

CreateThread(function()
    MySQL.query.await([[
    CREATE TABLE IF NOT EXISTS `sm_vehiclekeys` (
        `plate` varchar(16) NOT NULL,
        `citizenid` varchar(64) NOT NULL,
        `created` int(11) NOT NULL,
        PRIMARY KEY (`plate`),
        KEY `citizenid` (`citizenid`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    CreateThread(function()
        Wait(2000)
        local rows = MySQL.query.await('SELECT plate FROM ' .. TABLE) or {}
        for i = 1, #rows do locked[rows[i].plate] = 2 end
    end)
end)

print('^2[sm_vehiclekeys] server siap^7')