local State = require 'pelumber.modules.client.state'
local utils = require 'modules.utils'

local Util = {}

---@param dict string
function Util.loadParticleLib(dict)
    if HasNamedPtfxAssetLoaded(dict) then
        UseParticleFxAssetNextCall(dict)
        return
    end
    RequestNamedPtfxAsset(dict)
    while not HasNamedPtfxAssetLoaded(dict) do
        Wait(0)
    end
    UseParticleFxAssetNextCall(dict)
end

---@param label string
---@param duration number ms
---@param anim? { dict: string, clip: string, flag?: number }
---@return boolean
function Util.progress(label, duration, anim)
    if State.showBar then return false end
    State.showBar = true

    local ok = lib.progressBar({
        duration = duration,
        label = label,
        useWhileDead = false,
        canCancel = false,
        disable = { car = true, move = true, combat = true },
        anim = anim,
    })

    State.showBar = false
    return ok == true
end

---@param description string
---@param notifyType? 'success'|'error'|'info'|'warning'
function Util.notifyLocal(description, notifyType)
    lib.notify({
        title = 'Kerja Pelumber',
        description = description,
        type = notifyType or 'info',
    })
end

---@param description string
---@param notifyType? 'success'|'error'|'info'|'warning'
function Util.notifyGroup(description, notifyType)
    TriggerServerEvent(State.event('server:relayGroupNotify'), description, notifyType)
end

---@return boolean
function Util.startDisableThread()
    if State.disableThreadRunning then return false end
    State.disableThreadRunning = true
    CreateThread(function()
        while State.disableThreadRunning do
            DisableControlAction(0, 140, true)
            DisableControlAction(0, 141, true)
            DisableControlAction(0, 142, true)
            Wait(0)
        end
    end)
    return true
end

function Util.stopDisableThread()
    State.disableThreadRunning = false
end

local carryDict = 'missfinale_c2mcs_1'
local carryClip = 'fin_c2_mcs_1_camman'

local function startCarryAnim()
    local ped = cache.ped
    if IsEntityPlayingAnim(ped, carryDict, carryClip, 3) then return end
    if not utils.waitForAnim(carryDict) then return end
    TaskPlayAnim(ped, carryDict, carryClip, 4.0, 4.0, -1, 51, 0, false, false, false)
end

---@param object number
---@param modelName string
---@param kind 'pipe'|'valve'
---@param pipeType? string
function Util.addPlayerHandObject(object, modelName, kind, pipeType)
    if not object or not modelName then return end

    State.playerHandObject.object = object
    State.playerHandObject.objectNetId = NetworkGetNetworkIdFromEntity(object)
    State.playerHandObject.objectModel = modelName
    State.playerHandObject.pipe = kind == 'pipe'
    State.playerHandObject.valve = kind == 'valve'
    State.playerHandObject.pipeType = pipeType

    local attach = State.offsets.attach[modelName]
    if attach then
        local ped = cache.ped
        AttachEntityToEntity(
            object, ped, attach.bone,
            attach.xPos, attach.yPos, attach.zPos,
            attach.xRot, attach.yRot, attach.zRot,
            true, true, false, true, 1, true
        )
    end

    startCarryAnim()
    Util.startDisableThread()
end

function Util.resetPlayerHandObject()
    local ped = cache.ped
    local ho = State.playerHandObject

    if ho.object and DoesEntityExist(ho.object) then
        DetachEntity(ho.object, true, true)
        DeleteEntity(ho.object)
    end

    ho.object = nil
    ho.objectNetId = nil
    ho.objectModel = nil
    ho.pipe = false
    ho.valve = false
    ho.pipeType = nil

    ClearPedTasks(ped)
    ClearPedTasksImmediately(ped)
    Util.stopDisableThread()
end

---@return number? object
---@return string? model
function Util.getValidHandObject()
    local ho = State.playerHandObject
    if not ho.object then return nil, nil end

    if DoesEntityExist(ho.object) then
        return ho.object, ho.objectModel
    end

    if ho.objectNetId and NetworkDoesEntityExistWithNetworkId(ho.objectNetId) then
        local ent = NetworkGetEntityFromNetworkId(ho.objectNetId)
        if ent and DoesEntityExist(ent) then
            ho.object = ent
            return ent, ho.objectModel
        end
    end

    return nil, ho.objectModel
end

---@param model string
---@return boolean
function Util.isHoldingModel(model)
    local obj, held = Util.getValidHandObject()
    if not obj then return false end
    return held == model
end

---@param pipeType string
---@return boolean
function Util.isHoldingPipeType(pipeType)
    if not State.playerHandObject.pipe then return false end
    return State.playerHandObject.pipeType == pipeType
end

---@return boolean
function Util.isHoldingValve()
    return State.playerHandObject.valve == true
end

---@param coords vector3
---@param maxDistance number
---@return number[] vehicles
function Util.getVehiclesInArea(coords, maxDistance)
    local list = {}
    for _, entity in ipairs(GetGamePool('CVehicle')) do
        if #(coords - GetEntityCoords(entity)) <= maxDistance then
            list[#list + 1] = entity
        end
    end
    return list
end

---@return number? vehicle
function Util.getJobVehicle()
    local mission = State.mission
    if not mission or not mission.vehicleNetId then return nil end
    if not NetworkDoesEntityExistWithNetworkId(mission.vehicleNetId) then return nil end
    local veh = NetworkGetEntityFromNetworkId(mission.vehicleNetId)
    if not veh or veh == 0 or not DoesEntityExist(veh) then return nil end
    return veh
end

---@param coords vector3
---@param rot vector3
---@param fov? number
function Util.createCamera(coords, rot, fov)
    if IsPedInAnyVehicle(cache.ped, false) then return end

    RenderScriptCams(true, true, 500, true, true)
    DestroyCam(State.cam, false)

    State.cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamActive(State.cam, true)
    RenderScriptCams(true, true, 500, true, true)
    SetCamCoord(State.cam, coords.x, coords.y, coords.z)
    SetCamRot(State.cam, rot.x, rot.y, rot.z, 2)
    SetCamNearClip(State.cam, 0.1)
    SetCamFarClip(State.cam, 1000.0)
    SetCamFov(State.cam, fov or 40.0)
end

function Util.exitCamera()
    SetEntityAlpha(cache.ped, 255, false)
    RenderScriptCams(false, true, 500, true, true)
    DestroyCam(State.cam, false)
    ClearFocus()
    State.cam = nil
end

return Util
