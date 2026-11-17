local ClientUtil = localmodule 'modules/clientutil'

local DisableControlAction = DisableControlAction
local EnableControlAction = EnableControlAction
local IsDisabledControlPressed = IsDisabledControlPressed
local IsDisabledControlJustPressed = IsDisabledControlJustPressed
local GetFinalRenderedCamCoord = GetFinalRenderedCamCoord
local GetFinalRenderedCamRot = GetFinalRenderedCamRot
local GetEntityCoords = GetEntityCoords
local GetEntityRotation = GetEntityRotation
local SetEntityCoords = SetEntityCoords
local SetEntityRotation = SetEntityRotation
local DoesEntityExist = DoesEntityExist

local INFO_GIZMO = 'sm_audio:gizmo'

local CONTROL_ENTER = 191
local CONTROL_ESC = 322

local gizmoEntity
local activePromise
local gizmoMode
local attachData
local frameMounted = false

interface.init(false)

local blockedControls = {
    0, 1, 2, 16, 17, 22, 23, 24, 25, 26, 30, 31, 36, 37, 44, 47, 55, 69,
    81, 82, 91, 92, 99, 106, 114, 115, 121, 122, 135, 140, 142, 191, 199, 200, 245, 257, 322,
}

local lookAroundControls = { 1, 2, 22, 23, 30, 31 }

local function closeGizmo()
    gizmoEntity = nil

    interface.send({ action = 'setGizmoEntity', data = {} })
    interface.focus(false, false)

    if frameMounted then
        interface.hide()
        frameMounted = false
    end

    infoUI.remove(INFO_GIZMO)
end

---@param result table|false
local function resolveGizmo(result)
    local promiseRef = activePromise
    if not promiseRef then return end

    activePromise = nil
    promiseRef:resolve(result)
end

local function restoreAttachedObject(entity)
    if gizmoMode ~= 'attach' or not attachData then return end
    if not entity or not DoesEntityExist(entity) then return end

    local ped = cache.ped

    AttachEntityToEntity(entity, ped, GetPedBoneIndex(ped, attachData.bone),
        attachData.xCoord, attachData.yCoord, attachData.zCoord,
        attachData.xRotation, attachData.yRotation, attachData.zRotation,
        true, true, false, true, 1, true)
end

---@param entity number
local function openGizmo(entity)
    gizmoEntity = entity

    if not frameMounted then
        frameMounted = true
        interface.show()
        Wait(250)
    end

    infoUI.show({
        id = INFO_GIZMO,
        title = 'Atur Posisi Speaker',
        icon = 'fa-solid fa-arrows-to-dot',
        description = [[
        [kbd]Z[/kbd] Geser
        [kbd]R[/kbd] Putar
        [kbd]ENTER[/kbd] Simpan
        [kbd]ESC[/kbd] Batal
        [kbd]RMB[/kbd] Lihat sekeliling
        ]],
    })

    interface.send({
        action = 'setGizmoEntity',
        data = {
            handle = entity,
            position = GetEntityCoords(entity),
            rotation = GetEntityRotation(entity),
        },
    })

    interface.focus(true, true, true)

    CreateThread(function()
        while gizmoEntity do
            interface.send({
                action = 'setCameraPosition',
                data = {
                    position = GetFinalRenderedCamCoord(),
                    rotation = GetFinalRenderedCamRot(),
                },
            })
            Wait(0)
        end
    end)

    CreateThread(function()
        while gizmoEntity do
            for i = 1, #blockedControls do
                DisableControlAction(0, blockedControls[i], true)
            end

            if IsDisabledControlPressed(0, 25) then
                for i = 1, #lookAroundControls do
                    EnableControlAction(0, lookAroundControls[i], true)
                end
            end

            if IsDisabledControlJustPressed(0, CONTROL_ENTER) then
                local target = gizmoEntity
                closeGizmo()
                resolveGizmo({ GetEntityCoords(target), GetEntityRotation(target) })
            elseif IsDisabledControlJustPressed(0, CONTROL_ESC) then
                local target = gizmoEntity
                closeGizmo()
                restoreAttachedObject(target)
                attachData = nil
                resolveGizmo(false)
            end

            Wait(0)
        end
    end)
end

interface.callback('moveEntity', function(data, cb)
    cb('ok')

    if not data or not data.handle or not DoesEntityExist(data.handle) then return end

    SetEntityCoords(data.handle, data.position.x, data.position.y, data.position.z, false, false, false, false)
    SetEntityRotation(data.handle, data.rotation.x, data.rotation.y, data.rotation.z, 2, true)
end)

interface.callback('saveEntity', function(_, cb)
    cb('ok')

    if not activePromise then return end

    local entity = gizmoEntity
    closeGizmo()
    resolveGizmo({ GetEntityCoords(entity), GetEntityRotation(entity) })
end)

interface.callback('cancel', function(_, cb)
    cb('ok')

    if not activePromise then return end

    local entity = gizmoEntity
    closeGizmo()
    restoreAttachedObject(entity)
    attachData = nil
    resolveGizmo(false)
end)

lib.callback.register('sm_audio:client:getAttachOffset', function(serverId, data, netId)
    if activePromise then
        resolveGizmo(false)
    end

    local entity = GetAttachedEntityByKey(serverId, data.key)
    if not entity or not DoesEntityExist(entity) then
        return false
    end

    gizmoMode = 'attach'
    attachData = data

    DetachEntity(entity, true, true)
    PlaceObjectOnGroundProperly(entity)

    activePromise = promise.new()
    openGizmo(entity)

    local result = Citizen.Await(activePromise)
    if not result then return false end

    local vehicle = NetToVeh(netId)

    if not IsEntityTouchingEntity(entity, vehicle) then
        restoreAttachedObject(entity)
        attachData = nil

        ClientUtil.notify(locale('The speaker must be in contact with the vehicle.'), 'error')
        return false
    end

    attachData = nil

    local newCoords, newRotation = result[1], result[2]
    local offset = GetOffsetFromEntityGivenWorldCoords(vehicle, newCoords.x, newCoords.y, newCoords.z)
    local vehicleRotation = GetEntityRotation(vehicle)

    return {
        offset,
        vec3(
            (newRotation.x - vehicleRotation.x + 360) % 360,
            (newRotation.y - vehicleRotation.y + 360) % 360,
            (newRotation.z - vehicleRotation.z + 360) % 360
        ),
    }
end)

lib.callback.register('sm_audio:client:getNewCoords', function(soundId, sourceId)
    if activePromise then
        resolveGizmo(false)
    end

    local entity = GetSoundSourceEntity(soundId, sourceId)
    if not entity or not DoesEntityExist(entity) then
        return false
    end

    gizmoMode = 'move'
    attachData = nil

    activePromise = promise.new()
    openGizmo(entity)

    return Citizen.Await(activePromise)
end)

RegisterNetEvent('sm_audio:client:stop', function()
    if not gizmoEntity then return end

    closeGizmo()
    resolveGizmo(false)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    if gizmoEntity then
        closeGizmo()
        resolveGizmo(false)
    end
end)
