local Config = localmodule 'config'

local DoesEntityExist = DoesEntityExist
local IsEntityVisible = IsEntityVisible
local GetEntityCoords = GetEntityCoords
local CreateObjectNoOffset = CreateObjectNoOffset
local AttachEntityToEntity = AttachEntityToEntity
local SetEntityAsMissionEntity = SetEntityAsMissionEntity
local SetEntityCollision = SetEntityCollision
local SetModelAsNoLongerNeeded = SetModelAsNoLongerNeeded
local DeleteEntity = DeleteEntity
local GetPedBoneIndex = GetPedBoneIndex

local attachRegistry = {}
local attachedObjects = {}
local players = {}
local vehicleAttachments = {}

RegisterNetEvent('sm_audio:client:receiveAttachRegistry', function(registry)
    attachRegistry = registry
end)

RegisterNetEvent('sm_audio:client:updateRegistry', function(name, data)
    attachRegistry[name] = data
end)

---@param serverId number
---@param objects table[]
local function attachObjects(serverId, objects)
    local ped = GetPlayerPed(GetPlayerFromServerId(serverId))

    if not DoesEntityExist(ped) or not IsEntityVisible(ped) then
        return
    end

    local coords = GetEntityCoords(ped)

    for i = 1, #objects do
        local object = objects[i]

        if not (object.handle and DoesEntityExist(object.handle)) then
            local config = attachRegistry[object.name]

            if config and lib.requestModel(config.model, Config.modelTimeout) then
                local handle = CreateObjectNoOffset(config.model, coords.x, coords.y, coords.z, false, false, false)

                SetEntityAsMissionEntity(handle, true, true)
                SetEntityCollision(handle, false, false)

                local offset, rotation = config.offset, config.rotation
                AttachEntityToEntity(handle, ped, GetPedBoneIndex(ped, config.bone),
                    offset.x, offset.y, offset.z, rotation.x, rotation.y, rotation.z,
                    true, true, false, true, 1, true)

                SetModelAsNoLongerNeeded(config.model)
                object.handle = handle
            end
        end
    end
end

RegisterNetEvent('sm_audio:client:attachObject', function(serverId, name)
    local objects = attachedObjects[serverId]

    if not objects then
        objects = {}
        attachedObjects[serverId] = objects
    end

    objects[#objects + 1] = { name = name }

    if players[serverId] then
        attachObjects(serverId, objects)
    end
end)

RegisterNetEvent('sm_audio:client:detachObject', function(serverId, name)
    local objects = attachedObjects[serverId]
    if not objects then return end

    for i = #objects, 1, -1 do
        local object = objects[i]

        if object.name == name then
            if object.handle and DoesEntityExist(object.handle) then
                SetEntityAsMissionEntity(object.handle, true, true)
                DeleteEntity(object.handle)
            end
            table.remove(objects, i)
        end
    end
end)

---@param serverId number
---@param name string
---@return number|false
function GetAttachedEntityByKey(serverId, name)
    local objects = attachedObjects[serverId]
    if not objects then return false end

    for i = 1, #objects do
        if objects[i].name == name then
            return objects[i].handle or false
        end
    end

    return false
end

---@param serverId number
local function removePlayerObjects(serverId)
    local objects = attachedObjects[serverId]
    if not objects then return end

    for i = 1, #objects do
        local object = objects[i]

        if object.handle and DoesEntityExist(object.handle) then
            SetEntityAsMissionEntity(object.handle, true, true)
            DeleteEntity(object.handle)
        end

        object.handle = nil
    end
end

CreateThread(function()
    local active = GetActivePlayers()

    for i = 1, #active do
        players[GetPlayerServerId(active[i])] = true
    end
end)

RegisterNetEvent('onPlayerJoining', function(serverId)
    players[serverId] = true
end)

RegisterNetEvent('onPlayerDropped', function(serverId)
    players[serverId] = nil
    removePlayerObjects(serverId)
    attachedObjects[serverId] = nil
end)

local attachRenderRange = Config.attachRenderRange

CreateThread(function()
    while true do
        Wait(4000)

        if next(attachedObjects) then
            local playerCoords = GetEntityCoords(cache.ped)

            for serverId, objects in pairs(attachedObjects) do
                if players[serverId] then
                    local ped = GetPlayerPed(GetPlayerFromServerId(serverId))

                    if ped and ped ~= 0 and #(playerCoords - GetEntityCoords(ped)) < attachRenderRange then
                        attachObjects(serverId, objects)
                    end
                end
            end
        end
    end
end)

---@param entity number
---@param data table
local function attachVehicleObject(entity, data)
    if not DoesEntityExist(entity) or not IsEntityVisible(entity) then
        return
    end

    if data.handle and DoesEntityExist(data.handle) then
        return
    end

    if not lib.requestModel(data[1], Config.modelTimeout) then
        return
    end

    local coords = GetEntityCoords(entity)
    local handle = CreateObjectNoOffset(data[1], coords.x, coords.y, coords.z, false, false, false)

    SetEntityAsMissionEntity(handle, true, true)
    SetEntityCollision(handle, false, false)

    local offset, rotation = data[2], data[3]
    AttachEntityToEntity(handle, entity, 0,
        offset.x, offset.y, offset.z, rotation.x, rotation.y, rotation.z,
        false, false, false, false, 0, true)

    SetModelAsNoLongerNeeded(data[1])
    data.handle = handle
end

---@param data table
local function detachVehicleObject(data)
    if data.handle and DoesEntityExist(data.handle) then
        SetEntityAsMissionEntity(data.handle, true, true)
        DeleteEntity(data.handle)
    end

    data.handle = nil
end

CreateThread(function()
    while true do
        Wait(500)

        for entity, data in pairs(vehicleAttachments) do
            if DoesEntityExist(entity) then
                attachVehicleObject(entity, data)
            else
                detachVehicleObject(data)
                vehicleAttachments[entity] = nil
            end
        end
    end
end)

AddStateBagChangeHandler('raObjectToVehicle', nil, function(bagName, _, value)
    local entity = GetEntityFromStateBagName(bagName)
    if not entity or entity == 0 then return end

    local existing = vehicleAttachments[entity]
    if existing then
        detachVehicleObject(existing)
    end

    vehicleAttachments[entity] = value or nil
end)

lib.callback.register('sm_audio:client:getSpeakerAttachOption', function()
    return lib.inputDialog(locale('Attach method'), {
        {
            type = 'select',
            label = locale('Attach method'),
            description = locale('How would you like to attach the speaker.'),
            options = {
                { value = 'direct', label = locale('Attach directly to vehicle') },
                { value = 'gizmo', label = locale('Attach to vehicle using gizmo') },
            },
            default = 'direct',
            required = true,
        },
    })
end)

CreateThread(function()
    Wait(1000)
    TriggerServerEvent('sm_audio:server:requestAttachRegistry')
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    for serverId in pairs(players) do
        removePlayerObjects(serverId)
    end

    for _, data in pairs(vehicleAttachments) do
        detachVehicleObject(data)
    end
end)
