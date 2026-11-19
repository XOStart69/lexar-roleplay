local QBCore = exports['qb-core']:GetCoreObject()

local serverConfig = require 'gardener.config.server'
local GardenerMission = require 'gardener.modules.server.mission'
local Rewards = require 'gardener.modules.server.rewards'
local vehUtils = require 'modules.vehicles'

local function ev(name)
    return 'sm_gardener:' .. name
end

---@type table<string, table>
local missions = {}
---@type table<number, string>
local playerGroup = {}

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
---@param plate string
---@return table?
local function truckByPlate(mission, plate)
    return GardenerMission.findTruck(mission, plate)
end

---@param mission table
local function deleteVehicles(mission)
    for _, list in ipairs({ mission.trucks, mission.mowers }) do
        for _, data in ipairs(list) do
            if data.netId then vehUtils.remove(data.netId) end
        end
    end
end

---@param groupId string
---@param reason string
local function stopMission(groupId, reason)
    local mission = missions[groupId]
    if not mission then return end

    broadcast(groupId, 'client:missionEnd', reason)
    deleteVehicles(mission)

    for _, src in ipairs(membersOf(groupId)) do
        playerGroup[src] = nil
    end
    missions[groupId] = nil
end

---@param mission table
local function syncSnapshot(mission)
    local snapshot = GardenerMission.snapshot(mission)
    for _, src in ipairs(membersOf(mission.groupId)) do
        TriggerClientEvent(ev('client:missionStart'), src, snapshot)
    end
end

---@param mission table
local function syncTasks(mission)
    for _, src in ipairs(membersOf(mission.groupId)) do
        for _, task in ipairs(mission.tasks) do
            TriggerClientEvent(ev('client:taskProgress'), src, task.jobName, task.madeAmount, task.finish)
        end
    end
end

---@param mission table
---@param groupId string
local function advanceTask(mission, groupId)
    local current = GardenerMission.currentTask(mission)
    if not current then return end

    if GardenerMission.isAllRequiredFinished(mission) then
        mission.finishing = true
        broadcast(groupId, 'client:missionComplete')
        return
    end

    mission.currentTaskIndex = mission.currentTaskIndex + 1
    while mission.taskOrder[mission.currentTaskIndex] do
        local task = GardenerMission.getTask(mission, mission.taskOrder[mission.currentTaskIndex])
        if task and not task.finish then break end
        mission.currentTaskIndex = mission.currentTaskIndex + 1
    end

    broadcast(groupId, 'client:taskAdvance', mission.currentTaskIndex)
    syncTasks(mission)
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

    local candidates = {}
    for regionIndex in pairs(serverConfig.regions) do
        if GardenerMission.regionHasTasks(regionIndex) then
            candidates[#candidates + 1] = regionIndex
        end
    end
    if #candidates == 0 then
        notify(src, 'Tidak ada area kerja tersedia.', 'error')
        return false
    end

    local regionIndex = candidates[math.random(#candidates)]
    local mission = GardenerMission.new(groupId, src, regionIndex)
    mission.groupId = groupId

    local truckCfg = serverConfig.vehicle
    local count = math.min(#truckCfg.truckSpawns, #truckCfg.mowerSpawns)
    local spawned = true

    for i = 1, count do
        local truck = vehUtils.create({
            model = truckCfg.truck,
            coords = truckCfg.truckSpawns[i],
            platePrefix = truckCfg.truckPlatePrefix,
        })
        local mower = vehUtils.create({
            model = truckCfg.mower,
            coords = truckCfg.mowerSpawns[i],
            platePrefix = truckCfg.mowerPlatePrefix,
        })

        if truck and mower then
            mission.trucks[#mission.trucks + 1] = {
                netId = truck.netId,
                plate = truck.plate,
                id = i,
                items = { trimmer = true, ladder = true, flower = true, wateringcan = true },
                branchCount = 0,
            }
            mission.mowers[#mission.mowers + 1] = { netId = mower.netId, plate = mower.plate, id = i }

            pcall(vehUtils.giveKey, { source = src, plate = truck.plate })
            pcall(vehUtils.giveKey, { source = src, plate = mower.plate })
        else
            spawned = false
        end
    end

    if not spawned or #mission.trucks == 0 then
        deleteVehicles(mission)
        notify(src, 'Gagal menyiapkan kendaraan kerja.', 'error')
        return false
    end

    missions[groupId] = mission
    playerGroup[src] = groupId

    syncSnapshot(mission)
    syncTasks(mission)
    notify(src, 'Pekerjaan dimulai. Kendaraan sudah disiapkan.', 'success')
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

    local deliverCoords = serverConfig.vehicle.deliverCoords
    for _, list in ipairs({ mission.trucks, mission.mowers }) do
        for _, data in ipairs(list) do
            local vehicle = NetworkGetEntityFromNetworkId(data.netId)
            if vehicle == 0 or not DoesEntityExist(vehicle) then
                notify(src, 'Kendaraan kerja hilang.', 'error')
                return
            end
            if #(GetEntityCoords(vehicle) - deliverCoords) > serverConfig.validation.deliverDistance then
                notify(src, 'Semua kendaraan harus berada di titik penyerahan.', 'error')
                return
            end
        end
    end

    local members = membersOf(groupId)
    local share = math.floor(mission.money / math.max(#members, 1))
    for _, member in ipairs(members) do
        Rewards.give(member, share)
    end

    stopMission(groupId, 'completed')
end)

RegisterNetEvent(ev('server:updateMissionTable'), function(missionName, missionTable)
    local src = source
    local mission, groupId = missionOf(src)
    if not mission or type(missionName) ~= 'string' or type(missionTable) ~= 'table' then return end

    mission.shared[missionName] = missionTable
    for _, member in ipairs(membersOf(groupId)) do
        if member ~= src then
            TriggerClientEvent(ev('client:updateMissionTable'), member, missionName, missionTable, src)
        end
    end
end)

RegisterNetEvent(ev('server:updateJobTask'), function(jobName)
    local src = source
    local mission, groupId = missionOf(src)
    if not mission then return end

    local current = GardenerMission.currentTask(mission)
    if current ~= jobName then return end

    local task = GardenerMission.advanceTask(mission, jobName)
    if not task then return end

    syncTasks(mission)
    if task.finish then
        advanceTask(mission, groupId)
    end
end)

RegisterNetEvent(ev('server:updateBonusJobTask'), function(bonusName)
    local src = source
    local mission = missionOf(src)
    if not mission then return end

    local task = GardenerMission.getTask(mission, bonusName)
    if not task or task.finish then return end

    GardenerMission.advanceTask(mission, bonusName)
    syncTasks(mission)
end)

RegisterNetEvent(ev('server:syncAddObject'), function(modelName, coords, heading, areaName, id, update)
    local src = source
    local _, groupId = missionOf(src)
    if not groupId then return end
    broadcast(groupId, 'client:syncAddObject', modelName, coords, heading, areaName, id, update, src)
end)

RegisterNetEvent(ev('server:deleteLawnMowerObject'), function(id)
    local src = source
    local _, groupId = missionOf(src)
    if not groupId then return end
    broadcast(groupId, 'client:deleteLawnMowerObject', id, src)
end)

RegisterNetEvent(ev('server:trimPruneTree'), function(key, id)
    local src = source
    local _, groupId = missionOf(src)
    if not groupId then return end
    broadcast(groupId, 'client:trimPruneTree', key, src)
end)

RegisterNetEvent(ev('server:syncBlipsBatch'), function(blipsData)
    local src = source
    local _, groupId = missionOf(src)
    if not groupId then return end
    broadcast(groupId, 'client:syncBlipsBatch', blipsData)
end)

RegisterNetEvent(ev('server:syncBlipsDelete'), function(blipIndex, blipName)
    local src = source
    local _, groupId = missionOf(src)
    if not groupId then return end
    broadcast(groupId, 'client:syncBlipsDelete', blipIndex, blipName)
end)

RegisterNetEvent(ev('server:toggleEntityDoor'), function(netId, door)
    local src = source
    local _, groupId = missionOf(src)
    if not groupId then return end
    broadcast(groupId, 'client:toggleEntityDoor', netId, door)
end)

RegisterNetEvent(ev('server:attachMower'), function(mowerNetId, truckNetId)
    local src = source
    local _, groupId = missionOf(src)
    if not groupId then return end
    broadcast(groupId, 'client:attachMower', mowerNetId, truckNetId, true)
end)

RegisterNetEvent(ev('server:detachMower'), function(mowerNetId)
    local src = source
    local _, groupId = missionOf(src)
    if not groupId then return end
    broadcast(groupId, 'client:detachMower', mowerNetId)
end)

RegisterNetEvent(ev('server:updateVehicleItems'), function(plate, item, value)
    local src = source
    local mission, groupId = missionOf(src)
    if not mission then return end

    local truck = truckByPlate(mission, plate)
    if not truck then return end

    truck.items[item] = value
    broadcast(groupId, 'client:updateVehicleItems', plate, item, value)
end)

RegisterNetEvent(ev('server:updateVehicleBranch'), function(plate)
    local src = source
    local mission, groupId = missionOf(src)
    if not mission then return end

    local truck = truckByPlate(mission, plate)
    if not truck then return end

    truck.branchCount += 1
    broadcast(groupId, 'client:updateVehicleBranch', plate, truck.branchCount)
end)

RegisterNetEvent(ev('server:updateVehicleExtra'), function(plate, extra, enabled)
    local src = source
    local _, groupId = missionOf(src)
    if not groupId then return end
    broadcast(groupId, 'client:updateVehicleExtra', plate, extra, enabled)
end)

lib.callback.register(ev('server:deleteObject'), function(source, netId)
    local mission = missionOf(source)
    if not mission then return false end
    if not NetworkDoesNetworkIdExist(netId) then return false end

    local entity = NetworkGetEntityFromNetworkId(netId)
    if entity == 0 or not DoesEntityExist(entity) then return false end

    SetEntityAsMissionEntity(entity, true, true)
    DeleteEntity(entity)
    return true
end)

lib.callback.register(ev('server:requestVehicleItem'), function(source, plate, item, action)
    local mission = missionOf(source)
    if not mission then return false end

    local truck = truckByPlate(mission, plate)
    if not truck or not truck.items then return false end
    if truck.items[item] == nil then return false end

    if action == 'take' then
        if not truck.items[item] then return false end
        truck.items[item] = false
        return true
    end

    if action == 'putback' then
        if truck.items[item] then return false end
        truck.items[item] = true
        return true
    end

    return false
end)

lib.callback.register(ev('server:getVehicleBranchCount'), function(source, plate)
    local mission = missionOf(source)
    if not mission then return 0 end

    local truck = truckByPlate(mission, plate)
    return truck and truck.branchCount or 0
end)

AddEventHandler('QBCore:Server:PlayerDropped', function(source)
    local src = source
    local mission, groupId = missionOf(src)
    if not mission then return end

    playerGroup[src] = nil
    if mission.ownerSrc == src then
        stopMission(groupId, 'disbanded')
    end
end)