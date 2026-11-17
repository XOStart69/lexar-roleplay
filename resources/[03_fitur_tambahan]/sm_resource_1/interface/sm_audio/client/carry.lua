local Config = localmodule 'config'
local ClientUtil = localmodule 'modules/clientutil'

local DoesEntityExist = DoesEntityExist
local GetEntityCoords = GetEntityCoords
local IsEntityPlayingAnim = IsEntityPlayingAnim
local TaskPlayAnim = TaskPlayAnim
local ClearPedTasksImmediately = ClearPedTasksImmediately
local IsPedGettingIntoAVehicle = IsPedGettingIntoAVehicle
local NetworkDoesEntityExistWithNetworkId = NetworkDoesEntityExistWithNetworkId
local NetworkGetEntityFromNetworkId = NetworkGetEntityFromNetworkId

local INFO_CARRY = 'sm_audio:carry'

local dropKeybind, attachKeybind, detachKeybind, vehicleInteractKeybind
local nearestVehicle = false
local nearestSpeaker = false
local isCarrying = false
local inVehicle = false

local attachedNetIds = {}
local attachedSpeakers = {}
local speakerEntities = {}

---@param keybind? table
---@param disabled boolean
local function setKeybindDisabled(keybind, disabled)
    if keybind then
        keybind:disable(disabled)
    end
end

---@param keybind? table
---@param fallback string
---@return string
local function keybindLabel(keybind, fallback)
    return keybind and keybind.currentKey or fallback
end

---@param extra? string
local function showCarryInfo(extra)
    local lines = ('[kbd]%s[/kbd] Taruh speaker di tanah'):format(keybindLabel(dropKeybind, Config.keybinds.drop))

    if extra then
        lines = lines .. '\n' .. extra
    end

    infoUI.show({
        id = INFO_CARRY,
        title = 'Membawa Speaker',
        icon = 'fa-solid fa-music',
        description = lines,
    })
end

CreateThread(function()
    vehicleInteractKeybind = lib.addKeybind({
        name = 'speaker-interact-vehicle',
        description = locale('Interact with speaker inside vehicle'),
        defaultKey = Config.keybinds.interactVehicle,
        onPressed = function(self)
            if self.speakerId then
                InteractSpeaker(self.speakerId)
            end
        end,
        disabled = true,
    })

    dropKeybind = lib.addKeybind({
        name = 'speaker-drop',
        description = locale('Drop speaker'),
        defaultKey = Config.keybinds.drop,
        onPressed = function()
            DropSpeaker()
        end,
        disabled = true,
    })

    attachKeybind = lib.addKeybind({
        name = 'speaker-attach',
        description = locale('Attach speaker to a vehicle'),
        defaultKey = Config.keybinds.attach,
        onPressed = function()
            if not nearestVehicle or not ClientUtil.interactionCheck() then return end
            TriggerServerEvent('sm_audio:server:attachToVehicle', VehToNet(nearestVehicle))
        end,
        disabled = true,
    })

    detachKeybind = lib.addKeybind({
        name = 'speaker-detach',
        description = locale('Detach speaker from a vehicle'),
        defaultKey = Config.keybinds.detach,
        onPressed = function()
            if not nearestSpeaker or not ClientUtil.interactionCheck() then return end
            TriggerServerEvent('sm_audio:server:detachFromVehicle', VehToNet(nearestSpeaker))
        end,
        disabled = true,
    })
end)

---@param netId number
local function addDetachTarget(netId)
    if targetResource ~= 'ox_target' then return end

    local ok, exists = pcall(lib.waitFor, function()
        if NetworkDoesNetworkIdExist(netId) then return true end
    end, 'netId tidak muncul', 2000)

    if not ok or not exists then return end

    exports.ox_target:addEntity({ netId }, {
        {
            label = locale('Detach speaker'),
            icon = 'fa-solid fa-paperclip',
            name = 'sm-speaker-detach',
            distance = 1.4,
            onSelect = function(data)
                if not ClientUtil.interactionCheck() then return end
                TriggerServerEvent('sm_audio:server:detachFromVehicle', VehToNet(data.entity))
            end,
            canInteract = function(entity)
                return GetEntityHealth(entity) > 200
            end,
        },
    })
end

---@param netId number
local function removeDetachTarget(netId)
    if targetResource ~= 'ox_target' then return end
    exports.ox_target:removeEntity({ netId }, { 'sm-speaker-detach' })
end

---@param vehicleClasses number[]
local function addAttachTarget(vehicleClasses)
    if targetResource ~= 'ox_target' then return end

    exports.ox_target:addGlobalVehicle({
        {
            label = locale('Attach speaker'),
            icon = 'fa-solid fa-paperclip',
            name = 'sm-speaker-attach',
            distance = 1.4,
            onSelect = function(data)
                if not ClientUtil.interactionCheck() then return end
                TriggerServerEvent('sm_audio:server:attachToVehicle', VehToNet(data.entity))
            end,
            canInteract = function(entity)
                return GetEntityHealth(entity) > 200 and lib.table.contains(vehicleClasses, GetVehicleClass(entity))
            end,
        },
    })
end

local function removeAttachTarget()
    if targetResource ~= 'ox_target' then return end
    exports.ox_target:removeGlobalVehicle({ 'sm-speaker-attach' })
end

function DropSpeaker()
    if IsCloseToAnotherSpeaker() then
        ClientUtil.notify(locale('You are too close to another speaker.'), 'error')
        return
    end

    if not ClientUtil.interactionCheck() then return end

    removeAttachTarget()
    setKeybindDisabled(dropKeybind, true)
    isCarrying = false
    infoUI.remove(INFO_CARRY)

    TriggerServerEvent('sm_audio:server:dropSpeaker')
end

---@param data table
local function playCarryAnimation(data)
    if not lib.requestAnimDict(data.animationDict, Config.modelTimeout) then
        return
    end

    CreateThread(function()
        local ped = cache.ped

        while isCarrying do
            if not IsEntityPlayingAnim(ped, data.animationDict, data.animationName, 3) then
                TaskPlayAnim(ped, data.animationDict, data.animationName, data.blendInSpeed, data.blendOutSpeed,
                    data.duration, data.flag, data.playbackRate, data.lockX, data.lockY, data.lockZ)
            end
            Wait(250)
        end

        ClearPedTasksImmediately(ped)
    end)
end

local function vehicleProximityLoop()
    CreateThread(function()
        local showing = false
        local lastModel

        while isCarrying do
            Wait(500)

            local coords = GetEntityCoords(cache.ped)
            local vehicle = ClientUtil.getNearestVehicle(coords.x, coords.y, coords.z, 0.75)

            if vehicle then
                nearestVehicle = vehicle

                local model = GetEntityModel(vehicle)
                if lastModel ~= model then
                    lastModel = model
                    showing = false
                end

                if not showing then
                    showing = true
                    showCarryInfo(('[kbd]%s[/kbd] Pasang ke %s'):format(
                        keybindLabel(attachKeybind, Config.keybinds.attach), GetDisplayNameFromVehicleModel(model)))
                    setKeybindDisabled(attachKeybind, false)
                end
            else
                nearestVehicle = false

                if showing then
                    showing = false
                    showCarryInfo()
                    setKeybindDisabled(attachKeybind, true)
                end
            end
        end

        nearestVehicle = false
        setKeybindDisabled(attachKeybind, true)
    end)
end

RegisterNetEvent('sm_audio:client:carrySpeaker', function(data)
    isCarrying = true

    CreateThread(function()
        local ped = cache.ped

        while isCarrying do
            if IsPedGettingIntoAVehicle(ped) then
                ClientUtil.notify(locale("You can't enter a vehicle while holding a speaker."), 'error')
                ClearPedTasksImmediately(ped)
            end
            Wait(200)
        end
    end)

    CreateThread(function()
        Wait(500)
        setKeybindDisabled(dropKeybind, false)
        showCarryInfo()
    end)

    if data.animationData then
        playCarryAnimation(data.animationData)
    end

    local attachType = data.vehicleAttach

    if attachType == 'direct' or attachType == 'gizmo' or attachType == 'both' then
        if Config.useTargeting then
            addAttachTarget(data.vehicleClasses)
        else
            vehicleProximityLoop()
        end
    end
end)

RegisterNetEvent('sm_audio:client:speakerAttached', function()
    isCarrying = false
    setKeybindDisabled(dropKeybind, true)
    infoUI.remove(INFO_CARRY)
    removeAttachTarget()
end)

RegisterNetEvent('sm_audio:client:attachedToVehicle', function(netId, speakerId)
    attachedSpeakers[netId] = speakerId
    attachedNetIds[#attachedNetIds + 1] = netId

    if Config.useTargeting then
        addDetachTarget(netId)
    end
end)

RegisterNetEvent('sm_audio:client:detachedFromVehicle', function(netId)
    attachedSpeakers[netId] = nil
    speakerEntities[netId] = nil

    for i = #attachedNetIds, 1, -1 do
        if attachedNetIds[i] == netId then
            table.remove(attachedNetIds, i)
            break
        end
    end

    if Config.useTargeting then
        removeDetachTarget(netId)
    end
end)

CreateThread(function()
    while true do
        Wait(1000)

        for i = 1, #attachedNetIds do
            local netId = attachedNetIds[i]
            local cached = speakerEntities[netId]

            if not cached or not DoesEntityExist(cached) then
                if NetworkDoesEntityExistWithNetworkId(netId) then
                    local entity = NetworkGetEntityFromNetworkId(netId)
                    speakerEntities[netId] = (entity and entity ~= 0) and entity or nil
                else
                    speakerEntities[netId] = nil
                end
            end
        end
    end
end)

CreateThread(function()
    if Config.useTargeting then return end

    while true do
        Wait(2000)

        if not inVehicle and next(speakerEntities) then
            local coords = GetEntityCoords(cache.ped)
            local found = false

            for _, entity in pairs(speakerEntities) do
                if DoesEntityExist(entity) and #(coords - GetEntityCoords(entity)) < 2.0 then
                    found = entity
                    break
                end
            end

            if found then
                nearestSpeaker = found
                if detachKeybind and detachKeybind.disabled then
                    detachKeybind:disable(false)
                end
            else
                nearestSpeaker = false
                if detachKeybind and not detachKeybind.disabled then
                    detachKeybind:disable(true)
                end
            end
        end
    end
end)

lib.onCache('vehicle', function(vehicle)
    inVehicle = vehicle ~= false

    if not inVehicle then
        setKeybindDisabled(vehicleInteractKeybind, true)
        setKeybindDisabled(detachKeybind, true)

        if vehicleInteractKeybind then
            vehicleInteractKeybind.speakerId = nil
        end

        return
    end

    local speakerId = attachedSpeakers[VehToNet(vehicle)]

    if not vehicleInteractKeybind then return end

    if not speakerId then
        vehicleInteractKeybind.speakerId = nil
        return
    end

    SetInteractKeybindDisabled(true)
    vehicleInteractKeybind:disable(false)
    vehicleInteractKeybind.speakerId = speakerId
end)

local speakerProps = {
    [`prop_boombox_01`] = true,
    [`prop_ghettoblast_01`] = true,
    [`prop_ghettoblast_02`] = true,
    [`prop_portable_hifi_01`] = true,
    [`ch_prop_radio_speaker_01a`] = true,
    [`ch_prop_radio_speaker_02a`] = true,
    [`prop_speaker_01`] = true,
    [`prop_speaker_02`] = true,
    [`prop_speaker_03`] = true,
    [`prop_speaker_05`] = true,
    [`prop_speaker_06`] = true,
    [`prop_speaker_07`] = true,
    [`prop_speaker_08`] = true,
    [`prop_sub_woofer_01`] = true,
    [`sf_prop_sf_speaker_stand_01a`] = true,
    [`h4_prop_battle_club_speaker_med`] = true,
}

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    isCarrying = false
    infoUI.remove(INFO_CARRY)
end)

RegisterNetEvent('sm_audio:client:stop', function()
    isCarrying = false
    infoUI.remove(INFO_CARRY)
end)

exports('isCarryingSpeaker', function()
    if isCarrying then return true end

    local ped = cache.ped
    local objects = GetGamePool('CObject')

    for i = 1, #objects do
        local object = objects[i]
        if IsEntityAttachedToEntity(ped, object) and speakerProps[GetEntityModel(object)] then
            return true
        end
    end

    return false
end)
