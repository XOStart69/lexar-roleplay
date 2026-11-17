local pedPoints = require 'modules.pedPoints'
local blipUtils = require 'modules.blips'

local State = require 'pelumber.modules.client.state'
local Util = require 'pelumber.modules.client.util'
local Nui = require 'pelumber.modules.client.nui'
local Vehicle = require 'pelumber.modules.client.vehicle'
local Minigame = require 'pelumber.modules.client.minigame'

require 'pelumber.modules.client.minigames.insertpipe'
require 'pelumber.modules.client.minigames.repairpipe'
require 'pelumber.modules.client.minigames.toilet'
require 'pelumber.modules.client.minigames.openvalve'
require 'pelumber.modules.client.minigames.fixswitch'

local cfg = State.cfg
local sharedCfg = State.sharedCfg
local event = State.event

interface.init(true)
interface.callback('checkNUI', function(_, cb)
    State.nuiLoaded = true
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

local areaBlip
local areaBlipCoords
local vehicleBlip
local returnBlip

local function teardownBlips()
    blipUtils.remove(areaBlip)
    blipUtils.remove(vehicleBlip)
    blipUtils.remove(returnBlip)
    blipUtils.clearWaypoint()
    areaBlip = nil
    areaBlipCoords = nil
    vehicleBlip = nil
    returnBlip = nil
end

local function setupAreaRoute()
    blipUtils.remove(areaBlip)
    areaBlip = nil
    areaBlipCoords = nil

    local mission = State.mission
    if not mission then return end
    local coords = mission.location and mission.location.areaCoords
    if not coords then return end

    areaBlip = blipUtils.create({
        coords = coords,
        sprite = cfg.blip.mission.sprite,
        color = cfg.blip.mission.color,
        scale = cfg.blip.mission.scale,
        name = cfg.blip.mission.name,
    })
    areaBlipCoords = coords

    blipUtils.setWaypoint(coords)
end

local function attachVehicleBlip()
    CreateThread(function()
        local mission = State.mission
        if not mission or not mission.vehicleNetId then return end
        local netId = mission.vehicleNetId
        local timeout = GetGameTimer() + 10000

        while State.mission and GetGameTimer() < timeout do
            if NetworkDoesEntityExistWithNetworkId(netId) then
                local veh = NetworkGetEntityFromNetworkId(netId)
                if veh and DoesEntityExist(veh) then
                    vehicleBlip = blipUtils.create.entity({
                        entity = veh,
                        sprite = cfg.blip.vehicle.sprite,
                        color = cfg.blip.vehicle.color,
                        scale = cfg.blip.vehicle.scale,
                        name = cfg.blip.vehicle.name,
                    })
                    return
                end
            end
            Wait(500)
        end
    end)
end

local function setupReturnBlip()
    returnBlip = blipUtils.create({
        coords = sharedCfg.start.pedCoords,
        sprite = cfg.blip.vehicle.sprite,
        color = 2,
        scale = 0.9,
        name = 'Kembalikan Kendaraan',
    })

    blipUtils.setWaypoint(sharedCfg.start.pedCoords)
end

local function fullTeardown()
    Minigame.stopPipe()
    Minigame.stopToilet()
    Minigame.teardownCurrentTask()
    Nui.cancel()
    Vehicle.teardown()
    teardownBlips()
    Util.resetPlayerHandObject()
    Util.exitCamera()
    if State.nuiLoaded then
        Nui.send('CLOSE_PIPE_GAME')
        Nui.focus(false, false)
    end
    State.clearMission()
end

RegisterNetEvent(event('client:missionStart'), function(snapshot)
    if State.mission then fullTeardown() end

    State.startMission(snapshot)
    Vehicle.setup()
    attachVehicleBlip()
    setupAreaRoute()
    Minigame.setupCurrentTask()
end)

RegisterNetEvent(event('client:objectDone'), function(objId)
    if not State.mission then return end
    State.setDone(objId)
    Minigame.onObjectDone(objId)
end)

RegisterNetEvent(event('client:valveState'), function(objId, state)
    if not State.mission then return end
    State.setValveState(objId, state)
    Minigame.onValveState(objId, state)
end)

RegisterNetEvent(event('client:pipeRemoved'), function(objId)
    if not State.mission then return end
    State.setPipeRemoved(objId)
    Minigame.onPipeRemoved(objId)
end)

RegisterNetEvent(event('client:processing'), function(objId, src)
    if not State.mission then return end
    State.setProcessing(objId, src)
    Minigame.onProcessing(objId, src)
end)

RegisterNetEvent(event('client:taskAdvance'), function(idx)
    local mission = State.mission
    if not mission then return end

    Minigame.teardownCurrentTask()
    mission.currentTaskIndex = idx
    Minigame.setupCurrentTask()

    Util.notifyLocal('Tugas selesai! Lanjut ke tugas berikutnya.', 'success')
end)

RegisterNetEvent(event('client:missionComplete'), function()
    local mission = State.mission
    if not mission then return end

    mission.finishing = true
    Minigame.teardownCurrentTask()
    blipUtils.remove(areaBlip)
    areaBlip = nil
    areaBlipCoords = nil
    Util.resetPlayerHandObject()

    setupReturnBlip()
    Util.notifyLocal('Selamat, pekerjaan selesai! Kembalikan kendaraan ke base.', 'success')
end)

RegisterNetEvent(event('client:missionEnd'), function(reason)
    if not State.mission then return end
    fullTeardown()

    if reason == 'completed' then
        Util.notifyLocal('Pekerjaan selesai. Terima kasih!', 'success')
    elseif reason == 'cancelled' then
        Util.notifyLocal('Pekerjaan dibatalkan.', 'warning')
    elseif reason == 'disbanded' then
        Util.notifyLocal('Group dibubarkan, pekerjaan dihentikan.', 'warning')
    end
end)

CreateThread(function()
    pedPoints({
        model = sharedCfg.start.pedModel,
        coords = sharedCfg.start.pedCoords,
        scenario = 'WORLD_HUMAN_CLIPBOARD',
        interactOptions = {
            {
                name = 'sm_pelumber_start_job',
                label = 'Mulai Kerja Pelumber',
                icon = 'fa-solid fa-clipboard',
                distance = 1.5,
                canInteract = function()
                    return State.mission == nil
                end,
                onSelect = function()
                    lib.callback.await(event('server:startJob'), false)
                end,
            },
            {
                name = 'sm_pelumber_cancel_job',
                label = 'Batalkan Kerja',
                icon = 'fa-solid fa-xmark',
                distance = 1.5,
                canInteract = function()
                    local mission = State.mission
                    return mission ~= nil and mission.ownerSrc == (cache.serverId --[[@as number]])
                end,
                onSelect = function()
                    TriggerServerEvent(event('server:cancelJob'))
                end,
            },
            {
                name = 'sm_pelumber_return_vehicle',
                label = 'Kembalikan Kendaraan & Selesaikan',
                icon = 'fa-solid fa-flag-checkered',
                distance = 2.5,
                canInteract = function()
                    local mission = State.mission
                    if not mission or not mission.finishing then return false end
                    local veh = Util.getJobVehicle()
                    if not veh then return false end
                    return #(GetEntityCoords(veh) - sharedCfg.start.pedCoords.xyz) < 10.0
                end,
                onSelect = function()
                    TriggerServerEvent(event('server:completeJob'))
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
    local hideDistance = cfg.blip.mission.routeHideDistance

    while true do
        if areaBlip and hideDistance and areaBlipCoords and DoesBlipExist(areaBlip) then
            local dist = #(GetEntityCoords(cache.ped) - areaBlipCoords)
            if dist <= hideDistance then
                blipUtils.remove(areaBlip)
                blipUtils.clearWaypoint()
                areaBlip = nil
                areaBlipCoords = nil
            end
            Wait(500)
        else
            Wait(1000)
        end
    end
end)