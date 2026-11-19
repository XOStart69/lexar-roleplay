local pedPoints = require 'modules.pedPoints'
local blipUtils = require 'modules.blips'

local State = require 'gardener.modules.client.state'
local Nui = require 'gardener.modules.client.nui'
local Blips = require 'gardener.modules.client.blips'
local Mission = require 'gardener.modules.client.mission'
local Branch = require 'gardener.modules.client.branch'
local Flower = require 'gardener.modules.client.flower'
local Vehicle = require 'gardener.modules.client.vehicle'

local cfg = State.cfg
local sharedCfg = State.sharedCfg
local event = State.event

interface.init(true)

interface.callback('checkNUI', function(_, cb)
    State.nuiLoaded = true
    cb('ok')
end)

interface.callback('miniGameResult', function(data, cb)
    Nui.focus(false)
    Branch.onMinigameResult(data)
    cb('ok')
end)

Nui.pingUntilReady()

CreateThread(function()
    blipUtils.create({
        coords = sharedCfg.start.pedCoords,
        sprite = cfg.blip.ped.sprite,
        color = cfg.blip.ped.color,
        scale = cfg.blip.ped.scale,
        name = cfg.blip.ped.name,
    })
end)

local deliveryBlip
local areaBlip
local areaBlipCoords

---@type table<string, table[]>
local pendingBlips = {}

local taskToBlips = {
    lawnmowing = 'lawnmowing',
    prunegrass = 'prunegrass',
    branch = 'branch',
    plantflower = 'flower',
}

local function removeAreaRoute()
    blipUtils.remove(areaBlip)
    blipUtils.clearWaypoint()
    areaBlip = nil
    areaBlipCoords = nil
end

local function setupAreaRoute()
    removeAreaRoute()

    local region = State.getRegion()
    local coords = region and region.areaCoords
    if not coords then return end

    local settings = cfg.blip.mission.area
    areaBlip = blipUtils.create({
        coords = coords,
        sprite = settings.sprite,
        color = settings.color,
        scale = settings.scale,
        name = settings.name,
    })
    areaBlipCoords = coords

    blipUtils.setWaypoint(coords)
end

local function showActiveTaskBlips()
    local current = State.getCurrentTaskName()
    local blipsName = current and taskToBlips[current]
    if not blipsName then return end

    local pending = pendingBlips[blipsName]
    if not pending then return end

    for _, data in ipairs(pending) do
        Blips.addMissionBlip(data.task, blipsName, data.id, data.radius)
    end
end

local function fullTeardown()
    Mission.teardown()
    Branch.teardown()
    Flower.teardown()
    Vehicle.teardown()
    Blips.removeAll()
    blipUtils.remove(deliveryBlip)
    deliveryBlip = nil
    removeAreaRoute()
    pendingBlips = {}

    State.resetPlayerHandObject()
    State.resetFlowerState()
    State.resetLadderObject()
    State.resetStateThread()

    State.mowerObject = {}
    State.prunegrassObject = {}
    State.flowerObject = {}
    State.branchObject = {}
    State.isPlacingObject = false
    State.isPlacingLadder = false
    State.isPlacingWateringcan = false
    State.isInteracting = false
    State.showBar = false
    State.mission = nil

    ClearPedTasks(cache.ped)
end

RegisterNetEvent(event('client:missionStart'), function(snapshot)
    if source == '' then return end

    if State.mission then fullTeardown() end

    State.mission = snapshot
    Vehicle.setup()
    Flower.toggleAreaInteractions(true)
    setupAreaRoute()

    local flowerBlips = {}
    for index, area in ipairs(snapshot.flowerArea) do
        flowerBlips[#flowerBlips + 1] = { task = area.coords, id = index, radius = area.area }
    end
    pendingBlips.flower = flowerBlips

    if State.isOwner() then
        local lawnmowing = State.getTask('lawnmowing')
        local prunegrass = State.getTask('prunegrass')
        local branch = State.getTask('branch')

        if lawnmowing and lawnmowing.jobCount > 0 then
            Mission.spawnAreaObjects('potongRumput', lawnmowing.jobCount)
        end
        if prunegrass and prunegrass.jobCount > 0 then
            Mission.spawnAreaObjects('pangkasSemak', prunegrass.jobCount)
        end
        if branch and branch.jobCount > 0 then
            Branch.spawnBranchObjects(branch.jobCount)
        end
    end

    State.notify('Pekerjaan dimulai! Ikuti rute GPS menuju area kerja', 'success')
end)

RegisterNetEvent(event('client:syncAddObject'), function(modelName, coords, heading, areaName, id, update, initiatorSrc)
    if source == '' then return end

    if not State.mission or initiatorSrc == (cache.serverId --[[@as number]]) then return end
    Mission.onObjectSynced(modelName, coords, heading, areaName, id, update)
end)

RegisterNetEvent(event('client:deleteLawnMowerObject'), function(id, initiatorSrc)
    if source == '' then return end

    if not State.mission then return end
    Mission.onLawnMowerDeleted(id, initiatorSrc == (cache.serverId --[[@as number]]))
end)

RegisterNetEvent(event('client:trimPruneTree'), function(key, initiatorSrc)
    if source == '' then return end

    if not State.mission then return end
    Mission.onTrimPruneTree(key, initiatorSrc == (cache.serverId --[[@as number]]))
end)

RegisterNetEvent(event('client:syncBlipsBatch'), function(blipsData)
    if source == '' then return end

    if not State.mission or not blipsData or #blipsData == 0 then return end

    local blipsName = blipsData[1].blipsName
    if blipsName == 'prunegrass' then
        Mission.toggleTrimInteractions(true)
    elseif blipsName == 'lawnmowing' then
        Mission.startLawnmowerThread()
    elseif blipsName == 'branch' then
        Branch.refreshInteractions()
        Branch.toggleLadderInteractions(true)
    end

    local pending = pendingBlips[blipsName] or {}
    for _, data in ipairs(blipsData) do
        pending[#pending + 1] = { task = data.task, id = data.id }
    end
    pendingBlips[blipsName] = pending

    showActiveTaskBlips()
end)

RegisterNetEvent(event('client:syncBlipsDelete'), function(blipIndex, blipName)
    if source == '' then return end

    if not State.mission then return end
    Blips.removeMissionBlip(blipName, blipIndex)

    local pending = pendingBlips[blipName]
    if pending then
        for i = #pending, 1, -1 do
            if pending[i].id == blipIndex then
                table.remove(pending, i)
            end
        end
    end
end)

RegisterNetEvent(event('client:updateMissionTable'), function(missionName, missionTable, initiatorSrc)
    if source == '' then return end

    if not State.mission or initiatorSrc == (cache.serverId --[[@as number]]) then return end

    local targets = {
        mowerObject = State.mowerObject,
        prunegrassObject = State.prunegrassObject,
        flowerObject = State.flowerObject,
        branchObject = State.branchObject,
        ladderObject = State.ladderObject,
    }
    local targetTable = targets[missionName]
    if not targetTable then return end

    for key in pairs(targetTable) do
        if missionTable[key] == nil then
            targetTable[key] = nil
        end
    end
    for key, value in pairs(missionTable) do
        targetTable[key] = value
    end

    if missionName == 'branchObject' then
        Branch.refreshInteractions()
    elseif missionName == 'flowerObject' then
        Flower.refreshInteractions()
    elseif missionName == 'ladderObject' then
        Branch.toggleLadderInteractions(true)
    end
end)

RegisterNetEvent(event('client:taskProgress'), function(jobName, madeAmount, finish)
    if source == '' then return end

    local task = State.getTask(jobName)
    if not task then return end
    task.madeAmount = madeAmount
    task.finish = finish
end)

RegisterNetEvent(event('client:taskAdvance'), function(idx)
    if source == '' then return end

    local mission = State.mission
    if not mission then return end

    mission.currentTaskIndex = idx
    showActiveTaskBlips()
    State.notify('Tugas selesai! Lanjut ke tugas berikutnya', 'success')
end)

RegisterNetEvent(event('client:toggleEntityDoor'), function(netId, door)
    if source == '' then return end

    Vehicle.onToggleEntityDoor(netId, door)
end)

RegisterNetEvent(event('client:updateVehicleExtra'), function(plate, extra, enabled)
    if source == '' then return end

    Vehicle.onUpdateVehicleExtra(plate, extra, enabled)
end)

RegisterNetEvent(event('client:attachMower'), function(mowerNetId, truckNetId)
    if source == '' then return end

    Vehicle.onAttachMower(mowerNetId, truckNetId, true)
end)

RegisterNetEvent(event('client:detachMower'), function(mowerNetId)
    if source == '' then return end

    Vehicle.onDetachMower(mowerNetId)
end)

RegisterNetEvent(event('client:missionComplete'), function()
    if source == '' then return end

    local mission = State.mission
    if not mission then return end

    mission.finishing = true
    removeAreaRoute()
    deliveryBlip = blipUtils.create({
        coords = mission.deliverCoords,
        sprite = cfg.blip.mission.delivery.sprite,
        color = cfg.blip.mission.delivery.color,
        scale = cfg.blip.mission.delivery.scale,
        name = 'Serahkan Kendaraan',
    })
    blipUtils.setWaypoint(mission.deliverCoords)
    Vehicle.toggleDelivery(true)
    State.notify('Semua tugas selesai! Bawa semua kendaraan ke titik penyerahan', 'success')
end)

RegisterNetEvent(event('client:missionEnd'), function(reason)
    if source == '' then return end

    if not State.mission then return end
    fullTeardown()

    if reason == 'completed' then
        State.notify('Pekerjaan selesai. Terima kasih!', 'success')
    elseif reason == 'cancelled' then
        State.notify('Pekerjaan dibatalkan', 'error')
    elseif reason == 'disbanded' then
        State.notify('Group dibubarkan, pekerjaan dihentikan', 'error')
    end
end)

CreateThread(function()
    pedPoints({
        model = sharedCfg.start.pedModel,
        coords = sharedCfg.start.pedCoords,
        scenario = 'WORLD_HUMAN_GARDENER_LEAF_BLOWER',
        interactOptions = {
            {
                name = 'sm_gardener_start_job',
                label = 'Mulai Kerja Tukang Kebun',
                icon = 'fa-solid fa-seedling',
                distance = 1.5,
                canInteract = function()
                    return State.mission == nil
                end,
                onSelect = function()
                    lib.callback.await(event('server:startJob'), false)
                end,
            },
            {
                name = 'sm_gardener_cancel_job',
                label = 'Batalkan Kerja',
                icon = 'fa-solid fa-xmark',
                distance = 1.5,
                canInteract = function()
                    return State.mission ~= nil and State.isOwner()
                end,
                onSelect = function()
                    TriggerServerEvent(event('server:cancelJob'))
                end,
            },
        },
    })
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if State.mission then fullTeardown() end
end)

CreateThread(function()
    local hideDistance = cfg.blip.mission.area.routeHideDistance

    while true do
        if areaBlip and areaBlipCoords and DoesBlipExist(areaBlip) then
            if #(GetEntityCoords(cache.ped) - areaBlipCoords) <= hideDistance then
                removeAreaRoute()
            end
            Wait(500)
        else
            Wait(1000)
        end
    end
end)

RegisterNetEvent(event('client:notify'), function(description, notifyType)
    State.notify(description, notifyType)
end)