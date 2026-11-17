local Config = localmodule 'config'
local ClientUtil = localmodule 'modules/clientutil'

local DoesEntityExist = DoesEntityExist
local CreateObjectNoOffset = CreateObjectNoOffset
local SetEntityRotation = SetEntityRotation
local SetEntityCoords = SetEntityCoords
local FreezeEntityPosition = FreezeEntityPosition
local SetEntityAsMissionEntity = SetEntityAsMissionEntity
local DeleteEntity = DeleteEntity
local SetModelAsNoLongerNeeded = SetModelAsNoLongerNeeded

local interactPoints = {}
local outerPoints = {}
local interactKeybind
local closestSpeakerId

local INFO_INTERACT = 'sm_audio:interact'

targetResource = nil
currentBucketId = 0

---@param speakerId string
local function interactWithSpeaker(speakerId)
    if not speakerId then return end

    if IsPedInAnyVehicle(cache.ped, true) or IsPedGettingIntoAVehicle(cache.ped) then
        ClientUtil.notify(locale("This can't be done while inside a vehicle."), 'error')
        return
    end

    InteractSpeaker(speakerId)
end

CreateThread(function()
    if Config.useTargeting then
        if GetResourceState('ox_target') ~= 'missing' then
            targetResource = 'ox_target'
            return
        end

        lib.print.error('[sm_audio] useTargeting aktif tapi ox_target tidak ditemukan.')
        Config.useTargeting = false
    end

    interactKeybind = lib.addKeybind({
        name = 'speaker-interact',
        description = locale('Interact with closest speaker'),
        defaultKey = Config.keybinds.interact,
        onPressed = function()
            interactWithSpeaker(closestSpeakerId)
        end,
        disabled = true,
    })
end)

---@param disabled boolean
function SetInteractKeybindDisabled(disabled)
    if interactKeybind then
        interactKeybind:disable(disabled)
    end
end

---@return boolean
function IsCloseToAnotherSpeaker()
    return closestSpeakerId ~= nil
end

---@param speakerId string
local function showInteract(speakerId)
    if not interactPoints[speakerId] then return end

    infoUI.show({
        id = INFO_INTERACT,
        title = 'Speaker',
        icon = 'fa-solid fa-music',
        description = ('[kbd]%s[/kbd] Interaksi dengan speaker'):format(interactKeybind and interactKeybind.currentKey or Config.keybinds.interact),
    })

    closestSpeakerId = speakerId
    SetInteractKeybindDisabled(false)
end

---@param speakerId string
local function hideInteract(speakerId)
    if not interactPoints[speakerId] then return end

    infoUI.remove(INFO_INTERACT)
    closestSpeakerId = nil
    SetInteractKeybindDisabled(true)
end

---@param entity number
---@param speakerId string
---@param data table
local function addTargetOptions(entity, speakerId, data)
    if targetResource ~= 'ox_target' then return end

    exports.ox_target:addLocalEntity({ entity }, {
        {
            label = locale('Play music'),
            icon = 'fa-solid fa-play',
            name = 'sm-speaker-play',
            distance = 2.0,
            onSelect = function() InteractSpeakerTarget(speakerId, 'playMusic') end,
        },
        {
            label = locale('Change volume/range'),
            icon = 'fa-solid fa-volume-high',
            name = 'sm-speaker-range',
            distance = 2.0,
            onSelect = function() InteractSpeakerTarget(speakerId, 'volumeRange') end,
        },
        {
            label = locale('Hold speaker'),
            icon = 'fa-solid fa-hand-paper',
            name = 'sm-speaker-pickup',
            distance = 2.0,
            onSelect = function() InteractSpeakerTarget(speakerId, 'carry') end,
        },
        {
            label = locale('Connect'),
            icon = 'fa-brands fa-bluetooth',
            name = 'sm-speaker-connect',
            distance = 2.0,
            onSelect = function() InteractSpeakerTarget(speakerId, 'addGroup') end,
            canInteract = function() return not data.groupId end,
        },
        {
            label = locale('Disconnect'),
            icon = 'fa-brands fa-bluetooth',
            name = 'sm-speaker-disconnect',
            distance = 2.0,
            onSelect = function() TriggerServerEvent('sm_audio:server:removeFromGroup', speakerId) end,
            canInteract = function() return data.groupId ~= nil end,
        },
        {
            label = locale('Store speaker'),
            icon = 'fa-solid fa-box',
            name = 'sm-speaker-store',
            distance = 2.0,
            onSelect = function() InteractSpeakerTarget(speakerId, 'store') end,
        },
        {
            label = locale('Other'),
            icon = 'fa-solid fa-cog',
            name = 'sm-speaker-other',
            distance = 2.0,
            onSelect = function() interactWithSpeaker(speakerId) end,
        },
    })
end

local targetNames = {
    'sm-speaker-play',
    'sm-speaker-range',
    'sm-speaker-pickup',
    'sm-speaker-connect',
    'sm-speaker-disconnect',
    'sm-speaker-store',
    'sm-speaker-other',
}

---@param entity number
local function removeTargetOptions(entity)
    if targetResource ~= 'ox_target' or not entity then return end
    exports.ox_target:removeLocalEntity({ entity }, targetNames)
end

---@param speakerId string
local function spawnPointObject(speakerId)
    local point = outerPoints[speakerId]
    if not point or point.handle then return end

    if not lib.requestModel(point.model, Config.modelTimeout) then
        return
    end

    local coords = point.coords
    local handle = CreateObjectNoOffset(point.model, coords.x, coords.y, coords.z, false, false, false)

    if not DoesEntityExist(handle) then
        SetModelAsNoLongerNeeded(point.model)
        return
    end

    FreezeEntityPosition(handle, true)
    SetEntityRotation(handle, point.rotation.x, point.rotation.y, point.rotation.z, 2, true)
    SetModelAsNoLongerNeeded(point.model)

    point.handle = handle

    TriggerEvent('sm_audio:client:mapEntityToSource', point.soundId, point.sourceId, handle)

    if Config.useTargeting then
        addTargetOptions(handle, speakerId, {
            groupId = point.groupId,
            permissions = point.permissions,
        })
    end
end

---@param speakerId string
local function despawnPointObject(speakerId)
    local point = outerPoints[speakerId]
    if not point then return end

    if Config.useTargeting then
        removeTargetOptions(point.handle)
    end

    if point.handle and DoesEntityExist(point.handle) then
        SetEntityAsMissionEntity(point.handle, true, true)
        DeleteEntity(point.handle)
    end

    point.handle = nil

    TriggerEvent('sm_audio:client:mapEntityToSource', point.soundId, point.sourceId, nil)
end

---@param speakerId string
---@param data table
function CreatePoint(speakerId, data)
    if outerPoints[speakerId] then return end

    if not Config.useTargeting and not interactPoints[speakerId] then
        local inner = lib.points.new(data.coords, 2.5, {
            speakerId = speakerId,
            bucketId = data.bucketId,
        })

        function inner:onEnter()
            if currentBucketId ~= self.bucketId then return end
            showInteract(self.speakerId)
        end

        function inner:onExit()
            hideInteract(self.speakerId)
        end

        interactPoints[speakerId] = inner
    end

    local outer = lib.points.new(data.coords, 150.0, {
        model = data.model,
        rotation = data.rotation,
        soundId = data.soundId,
        sourceId = data.sourceId,
        groupId = data.groupId,
        permissions = data.permissions,
        speakerId = speakerId,
        bucketId = data.bucketId,
    })

    function outer:onEnter()
        if currentBucketId ~= self.bucketId then return end
        spawnPointObject(self.speakerId)
    end

    function outer:onExit()
        despawnPointObject(self.speakerId)
    end

    outerPoints[speakerId] = outer
end

RegisterNetEvent('sm_audio:client:addPoint', function(speakerId, data)
    CreatePoint(speakerId, data)
end)

RegisterNetEvent('sm_audio:client:removePoint', function(speakerId)
    local inner = interactPoints[speakerId]

    if inner then
        inner:remove()
        interactPoints[speakerId] = nil
    end

    if closestSpeakerId == speakerId then
        infoUI.remove(INFO_INTERACT)
        closestSpeakerId = nil
        SetInteractKeybindDisabled(true)
    end

    local outer = outerPoints[speakerId]
    if not outer then return end

    despawnPointObject(speakerId)
    outer:remove()
    outerPoints[speakerId] = nil
end)

RegisterNetEvent('sm_audio:client:updatePointCoords', function(speakerId, coords, rotation)
    local outer = outerPoints[speakerId]
    if not outer then return end

    outer.coords = coords
    outer.rotation = rotation

    local inner = interactPoints[speakerId]
    if inner then
        inner.coords = coords
    end

    if outer.handle and DoesEntityExist(outer.handle) then
        SetEntityCoords(outer.handle, coords.x, coords.y, coords.z, false, false, false, false)
        SetEntityRotation(outer.handle, rotation.x, rotation.y, rotation.z, 2, true)
    end
end)

RegisterNetEvent('sm_audio:client:updatePointData', function(speakerId, data)
    local outer = outerPoints[speakerId]
    if not outer then return end

    outer.groupId = data.groupId
    outer.permissions = data.permissions

    if outer.handle and DoesEntityExist(outer.handle) then
        removeTargetOptions(outer.handle)
        addTargetOptions(outer.handle, speakerId, data)
    end
end)

AddEventHandler('sm_audio:client:routingBucketUpdated', function(bucketId)
    for speakerId, point in pairs(outerPoints) do
        if point.currentDistance then
            if point.bucketId == bucketId then
                spawnPointObject(speakerId)
            else
                despawnPointObject(speakerId)
            end
        end
    end

    for speakerId, point in pairs(interactPoints) do
        if point.currentDistance then
            if point.bucketId == bucketId then
                showInteract(speakerId)
            else
                hideInteract(speakerId)
            end
        end
    end
end)

lib.callback.register('sm_audio:client:getCreationCoords', function(model)
    if closestSpeakerId then
        return false
    end

    if not lib.requestModel(model, Config.modelTimeout) then
        return false
    end

    local ped = cache.ped
    local dimensions = GetModelDimensions(GetEntityModel(ped))
    local offset = GetOffsetFromEntityInWorldCoords(ped, 0.0, dimensions.y + 0.8, dimensions.z)

    local object = CreateObjectNoOffset(model, offset.x, offset.y, offset.z + 0.35, false, false, false)

    if not DoesEntityExist(object) then
        SetModelAsNoLongerNeeded(model)
        return false
    end

    SetEntityAsMissionEntity(object, true, true)
    FreezeEntityPosition(object, true)
    PlaceObjectOnGroundProperly(object)

    local coords = GetEntityCoords(object)
    local rotation = GetEntityRotation(ped)

    DeleteEntity(object)
    SetModelAsNoLongerNeeded(model)

    return true, coords, rotation + vec3(0.0, 0.0, 180.0)
end)

---@param soundId string
---@param sourceId number
---@return number?
function GetSoundSourceEntity(soundId, sourceId)
    for _, point in pairs(outerPoints) do
        if point.soundId == soundId and point.sourceId == sourceId then
            return point.handle
        end
    end
end

AddStateBagChangeHandler('routingBucket', ('player:%s'):format(GetPlayerServerId(PlayerId())), function(_, _, value)
    if value ~= currentBucketId then
        currentBucketId = value
        TriggerEvent('sm_audio:client:routingBucketUpdated', value)
    end
end)

RegisterNetEvent('sm_audio:client:receiveStartup', function(startupPoints, filters, filterLimits)
    local state = LocalPlayer.state
    if state and state.routingBucket then
        currentBucketId = state.routingBucket
    end

    for speakerId, data in pairs(startupPoints) do
        CreatePoint(speakerId, data)
    end

    TriggerEvent('sm_audio:client:receiveFilters', filters, filterLimits)
end)

CreateThread(function()
    Wait(1000)
    TriggerServerEvent('sm_audio:server:requestStartup')
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    infoUI.remove(INFO_INTERACT)

    for speakerId in pairs(outerPoints) do
        despawnPointObject(speakerId)
    end
end)
