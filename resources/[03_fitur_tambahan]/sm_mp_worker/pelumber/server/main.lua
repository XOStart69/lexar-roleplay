local QBCore = exports['qb-core']:GetCoreObject()

local serverConfig = require 'pelumber.config.server'
local sharedConfig = require 'pelumber.config.shared'
local Mission = require 'pelumber.modules.server.mission'
local Rewards = require 'pelumber.modules.server.rewards'
local vehUtils = require 'modules.vehicles'

local function ev(name)
    return 'sm_pelumber:' .. name
end

---@type table<string, table>
local missions = {}
---@type table<number, string>
local playerGroup = {}
---@type table<string, number>
local cooldowns = {}

---@param src number
---@return string?
local function groupIdOf(src)
    local player = QBCore.Functions.GetPlayer(src)
    return player and player.PlayerData.citizenid or nil
end

---@param groupId string
---@return number[]
local function membersOf(groupId)
    local list = {}
    for src, gid in pairs(playerGroup) do
        if gid == groupId then
            list[#list + 1] = src
        end
    end
    return list
end

---@param groupId string
---@param name string
local function broadcast(groupId, name, ...)
    for _, src in ipairs(membersOf(groupId)) do
        TriggerClientEvent(ev(name), src, ...)
    end
end

---@param src number
---@param description string
---@param notifyType? string
local function notify(src, description, notifyType)
    TriggerClientEvent(ev('client:notify'), src, description, notifyType)
end

---@param src number
---@return table?, string?
local function missionOf(src)
    local groupId = groupIdOf(src)
    if not groupId then return nil end
    return missions[groupId], groupId
end

---@param mission table
---@param objId string
---@param src number
---@return boolean
local function nearUnit(mission, objId, src)
    local coords = mission.unitCoords[objId]
    if not coords then return false end

    local ped = GetPlayerPed(src)
    if ped == 0 then return false end

    return #(GetEntityCoords(ped) - coords) <= serverConfig.validation.objectDistance
end

---@param mission table
local function deleteVehicle(mission)
    if mission.vehicleNetId then
        vehUtils.remove(mission.vehicleNetId)
        mission.vehicleNetId = nil
    end
end

---@param groupId string
---@param reason string
local function stopMission(groupId, reason)
    local mission = missions[groupId]
    if not mission then return end

    broadcast(groupId, 'client:missionEnd', reason)
    deleteVehicle(mission)

    for _, src in ipairs(membersOf(groupId)) do
        playerGroup[src] = nil
    end
    missions[groupId] = nil
    cooldowns[groupId] = os.time() + serverConfig.startCooldownSeconds
end

---@param mission table
---@param groupId string
local function finishMission(mission, groupId)
    mission.finishing = true

    for objId in pairs(mission.processing) do
        mission.processing[objId] = nil
        broadcast(groupId, 'client:processing', objId, false)
    end

    broadcast(groupId, 'client:missionComplete')
end

---@param mission table
---@param groupId string
local function advanceTask(mission, groupId)
    local advanced, finished = Mission.advance(mission)
    if finished then
        finishMission(mission, groupId)
    elseif advanced then
        broadcast(groupId, 'client:taskAdvance', mission.currentTaskIndex)
    end
end

---@param mission table
local function syncTasks(mission)
    local tasks = Mission.groupTasks(mission)
    for _, src in ipairs(membersOf(mission.groupId)) do
        TriggerClientEvent(ev('client:taskSync'), src, tasks, mission.currentTaskIndex)
    end
end

lib.callback.register(ev('server:startJob'), function(source)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return false end

    local groupId = player.PlayerData.citizenid
    if missions[groupId] then
        notify(src, 'Kamu sudah memiliki pekerjaan aktif.', 'error')
        return false
    end

    local untilTime = cooldowns[groupId]
    if untilTime and untilTime > os.time() then
        notify(src, ('Tunggu %d detik lagi.'):format(untilTime - os.time()), 'error')
        return false
    end

    local ped = GetPlayerPed(src)
    if #(GetEntityCoords(ped) - sharedConfig.start.pedCoords.xyz) > serverConfig.validation.startDistance then
        notify(src, 'Terlalu jauh dari papan kerja.', 'error')
        return false
    end

    local spawns = serverConfig.vehicle.spawnCoords
    local spawn = spawns[math.random(#spawns)]

    local vehicle = vehUtils.create({
        model = serverConfig.vehicle.model,
        coords = spawn,
        platePrefix = serverConfig.vehicle.platePrefix,
    })
    if not vehicle then
        notify(src, 'Gagal menyiapkan kendaraan kerja.', 'error')
        return false
    end

    local mission = Mission.new(groupId, src, math.random(#Mission.locations), vehicle)
    mission.groupId = groupId
    missions[groupId] = mission
    playerGroup[src] = groupId

    pcall(vehUtils.giveKey, { source = src, plate = vehicle.plate })

    TriggerClientEvent(ev('client:missionStart'), src, Mission.snapshot(mission))
    syncTasks(mission)

    notify(src, 'Pekerjaan dimulai. Ambil peralatan di bagasi kendaraan.', 'success')
    return true
end)

RegisterNetEvent(ev('server:cancelJob'), function()
    local src = source
    local mission, groupId = missionOf(src)
    if not mission then return end
    if mission.ownerSrc ~= src then
        notify(src, 'Hanya pemilik pekerjaan yang bisa membatalkan.', 'error')
        return
    end

    stopMission(groupId, 'cancelled')
end)

RegisterNetEvent(ev('server:completeJob'), function()
    local src = source
    local mission, groupId = missionOf(src)
    if not mission then return end
    if not mission.finishing then
        notify(src, 'Selesaikan semua tugas terlebih dahulu.', 'error')
        return
    end
    if not mission.vehicleNetId then return end

    local vehicle = NetworkGetEntityFromNetworkId(mission.vehicleNetId)
    if vehicle == 0 or not DoesEntityExist(vehicle) then return end

    if #(GetEntityCoords(vehicle) - sharedConfig.start.pedCoords.xyz) > serverConfig.validation.vehicleReturnDistance then
        notify(src, 'Kendaraan belum berada di base.', 'error')
        return
    end

    for _, member in ipairs(membersOf(groupId)) do
        Rewards.give(member)
    end

    stopMission(groupId, 'completed')
end)

lib.callback.register(ev('server:acquireProcessing'), function(source, objId)
    local src = source
    local mission, groupId = missionOf(src)
    if not mission then return false end
    if mission.finishing then return false end
    if type(objId) ~= 'string' then return false end
    if not nearUnit(mission, objId, src) then return false end

    if not Mission.acquireProcessing(mission, objId, src) then
        return false
    end

    broadcast(groupId, 'client:processing', objId, src)
    return true
end)

RegisterNetEvent(ev('server:releaseProcessing'), function(objId)
    local src = source
    local mission, groupId = missionOf(src)
    if not mission or type(objId) ~= 'string' then return end

    if Mission.releaseProcessing(mission, objId, src) then
        broadcast(groupId, 'client:processing', objId, false)
    end
end)

RegisterNetEvent(ev('server:objectDone'), function(objId)
    local src = source
    local mission, groupId = missionOf(src)
    if not mission or type(objId) ~= 'string' then return end
    if mission.done[objId] then return end
    if mission.processing[objId] ~= src then return end

    if not nearUnit(mission, objId, src) then
        notify(src, 'Terlalu jauh dari objek.', 'error')
        return
    end

    if not Mission.markDone(mission, objId) then
        Mission.releaseProcessing(mission, objId, src)
        broadcast(groupId, 'client:processing', objId, false)
        return
    end

    mission.processing[objId] = nil
    broadcast(groupId, 'client:objectDone', objId)
    broadcast(groupId, 'client:processing', objId, false)
    syncTasks(mission)

    if Mission.isCurrentTaskComplete(mission) then
        advanceTask(mission, groupId)
    end
end)

RegisterNetEvent(ev('server:pipeRemoved'), function(objId)
    local src = source
    local mission, groupId = missionOf(src)
    if not mission or type(objId) ~= 'string' then return end
    if mission.processing[objId] ~= src then return end
    if not nearUnit(mission, objId, src) then return end

    if not Mission.setPipeRemoved(mission, objId) then return end

    mission.processing[objId] = nil
    broadcast(groupId, 'client:pipeRemoved', objId)
    broadcast(groupId, 'client:processing', objId, false)
end)

RegisterNetEvent(ev('server:valveState'), function(objId, state)
    local src = source
    local mission, groupId = missionOf(src)
    if not mission or type(objId) ~= 'string' then return end
    if mission.processing[objId] ~= src then return end
    if state ~= 'closed' and state ~= 'open' and state ~= 'placed' then return end
    if not nearUnit(mission, objId, src) then return end

    if not Mission.setValveState(mission, objId, state) then return end

    mission.processing[objId] = nil
    broadcast(groupId, 'client:valveState', objId, state)
    broadcast(groupId, 'client:processing', objId, false)
end)

RegisterNetEvent(ev('server:relayGroupNotify'), function(description, notifyType)
    local src = source
    local _, groupId = missionOf(src)
    if not groupId then return end

    for _, member in ipairs(membersOf(groupId)) do
        notify(member, description, notifyType)
    end
end)

RegisterNetEvent(ev('server:joinGroup'), function(ownerSrc)
    local src = source
    local mission, groupId = missionOf(ownerSrc)
    if not mission or not groupId then
        notify(src, 'Pemain itu tidak sedang bekerja.', 'error')
        return
    end
    if playerGroup[src] then return end

    playerGroup[src] = groupId
    pcall(vehUtils.giveKey, { source = src, plate = mission.vehiclePlate })
    TriggerClientEvent(ev('client:missionStart'), src, Mission.snapshot(mission))
end)

AddEventHandler('QBCore:Server:PlayerDropped', function(source)
    local src = source
    local mission, groupId = missionOf(src)
    if not mission then return end

    for objId in pairs(mission.processing) do
        if mission.processing[objId] == src then
            mission.processing[objId] = nil
            broadcast(groupId, 'client:processing', objId, false)
        end
    end

    playerGroup[src] = nil

    if mission.ownerSrc == src then
        stopMission(groupId, 'disbanded')
    end
end)

RegisterCommand('pelumber_force', function(source)
    local mission, groupId = missionOf(source)
    if not mission then return end
    if mission.ownerSrc ~= source then return end

    local completed = Mission.forceCompletePipes(mission)
    for _, objId in ipairs(completed) do
        broadcast(groupId, 'client:objectDone', objId)
    end
    syncTasks(mission)

    if Mission.isCurrentTaskComplete(mission) then
        advanceTask(mission, groupId)
    end
end, false)