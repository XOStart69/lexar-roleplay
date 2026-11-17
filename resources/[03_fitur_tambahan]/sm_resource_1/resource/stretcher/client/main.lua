local config = require 'resource.stretcher.config.client'

local stretcherModel = joaat(config.model)
local carriedStretcher
local mountedStretcher

local function isStretcherIdle(entity)
    return not carriedStretcher and not mountedStretcher and GetEntityModel(entity) == stretcherModel
end

local function isOccupied(entity)
    return Entity(entity).state.stretcherPatient ~= nil
end

local function canMount(entity)
    return isStretcherIdle(entity) and not isOccupied(entity)
end

local function dropStretcher()
    local entity = carriedStretcher
    if not entity then return end

    carriedStretcher = nil

    ClearPedTasks(cache.ped)
    DetachEntity(entity, true, true)
    SetVehicleExtra(entity, 1, true)
    SetVehicleExtra(entity, 2, false)
    SetVehicleOnGroundProperly(entity)

    infoUI.remove('stretcher')
end

local function clearMount(reposition)
    local entity = mountedStretcher
    if not entity then return end

    mountedStretcher = nil

    ClearPedTasks(cache.ped)
    DetachEntity(cache.ped, true, true)

    if reposition then
        local coords = GetEntityCoords(entity) + GetEntityForwardVector(entity) * -2.4
        SetEntityCoords(cache.ped, coords.x, coords.y, coords.z, false, false, false, false)
    end

    if NetworkGetEntityIsNetworked(entity) then
        lib.callback.await('rhd_stretcher:dismount', false, NetworkGetNetworkIdFromEntity(entity))
    end
end

local function dismountStretcher()
    clearMount(true)
end

local carryDisabledControls = { 21, 22, 23, 24, 25, 140, 141, 142, 257, 263, 264 }

local function monitorStretcher()
    CreateThread(function ()
        while carriedStretcher or mountedStretcher do
            if carriedStretcher then
                if IsPedDeadOrDying(cache.ped, true) then
                    dropStretcher()
                    return
                end

                local anim = config.anim.take

                if not IsEntityPlayingAnim(cache.ped, anim.dict, anim.clip, 3) then
                    lib.playAnim(cache.ped, anim.dict, anim.clip, 8.0, 8.0, -1, 50, 0, false, false, false)
                end

                for i = 1, #carryDisabledControls do
                    DisableControlAction(0, carryDisabledControls[i], true)
                end

                DisablePlayerFiring(cache.playerId, true)

                if IsControlJustReleased(0, 47) then
                    dropStretcher()
                    return
                end

                Wait(0)
            else
                Wait(250)

                if mountedStretcher and not IsEntityAttachedToEntity(cache.ped, mountedStretcher) then
                    clearMount(false)
                    return
                end
            end
        end
    end)
end

local function pickUpStretcher(entity)
    if carriedStretcher or mountedStretcher then return end

    NetworkRequestControlOfEntity(entity)
    SetVehicleExtra(entity, 1, false)
    SetVehicleExtra(entity, 2, true)
    AttachEntityToEntity(entity, cache.ped, 0, -0.05, 1.3, -0.345, 180.0, 180.0, 180.0, false, false, false, false, 2, true)

    carriedStretcher = entity
    monitorStretcher()

    infoUI.show({
        title = 'Stretcher',
        description = [[
        Tekan [kbd]G[/kbd] untuk melepaskan stretcher.
        ]],
        icon = 'fa-solid fa-bed',
        id = 'stretcher'
    })
end

local function attachToStretcher(entity, animName)
    local anim = config.anim[animName]
    local offset = anim.coords

    if animName == 'sit1' then
        SetVehicleDoorOpen(entity, 4, false, false)
    end

    AttachEntityToEntity(cache.ped, entity, 0, offset.x, offset.y, offset.z, 0.0, 0.0, offset.w, false, false, false, true, 2, true)
    lib.playAnim(cache.ped, anim.dict, anim.clip, 8.0, 8.0, -1, 1, 0, false, false, false)

    mountedStretcher = entity
    monitorStretcher()
end

local function mountStretcher(entity, animName)
    if carriedStretcher or mountedStretcher then return end

    if not lib.callback.await('rhd_stretcher:mount', false, NetworkGetNetworkIdFromEntity(entity)) then
        return lib.notify({ type = 'error', description = 'Stretcher sedang dipakai' })
    end

    attachToStretcher(entity, animName)
end

local function toggleExtra(entity, extraId)
    if not DoesExtraExist(entity, extraId) then return end

    SetVehicleExtra(entity, extraId, IsVehicleExtraTurnedOn(entity, extraId))
end

local function toggleSeat(entity)
    local folded = IsVehicleExtraTurnedOn(entity, 12)

    SetVehicleExtra(entity, 11, not folded)
    SetVehicleExtra(entity, 12, folded)
end

local function storeStretcher(entity)
    if not NetworkGetEntityIsNetworked(entity) then return end

    if not lib.callback.await('rhd_stretcher:store', false, NetworkGetNetworkIdFromEntity(entity)) then
        lib.notify({ type = 'error', description = 'Stretcher tidak bisa disimpan' })
    end
end

local function loadPatient(entity)
    local playerId = lib.getClosestPlayer(GetEntityCoords(entity), 3.0, false)

    if not playerId then
        return lib.notify({ type = 'error', description = 'Tidak ada orang di dekat stretcher' })
    end

    if not lib.callback.await('rhd_stretcher:loadPatient', false, NetworkGetNetworkIdFromEntity(entity), GetPlayerServerId(playerId)) then
        lib.notify({ type = 'error', description = 'Gagal menaikkan orang ke stretcher' })
    end
end

local function unloadPatient(entity)
    if not lib.callback.await('rhd_stretcher:unloadPatient', false, NetworkGetNetworkIdFromEntity(entity)) then
        lib.notify({ type = 'error', description = 'Gagal menurunkan orang dari stretcher' })
    end
end

local mounts = {
    { anim = 'sit1', label = 'Duduk di stretcher', icon = 'fa-solid fa-chair' },
    { anim = 'sit3', label = 'Duduk di stretcher (kiri)', icon = 'fa-solid fa-chair' },
    { anim = 'sit2', label = 'Duduk di stretcher (kanan)', icon = 'fa-solid fa-chair' },
    { anim = 'sleep', label = 'Berbaring di stretcher', icon = 'fa-solid fa-bed' }
}

local targetOptions = {
    {
        name = 'stretcher:menu',
        label = 'Stretcher',
        icon = 'fa-solid fa-truck-medical',
        distance = 2.0,
        openMenu = 'stretcher',
        canInteract = isStretcherIdle
    },
    {
        name = 'stretcher:carry',
        menuName = 'stretcher',
        label = 'Bawa stretcher',
        icon = 'fa-solid fa-hands-holding',
        distance = 2.0,
        canInteract = isStretcherIdle,
        onSelect = function (data)
            pickUpStretcher(data.entity)
        end
    }
}

for i = 1, #mounts do
    local mount = mounts[i]

    targetOptions[#targetOptions + 1] = {
        name = 'stretcher:mount:' .. mount.anim,
        menuName = 'stretcher',
        label = mount.label,
        icon = mount.icon,
        distance = 2.0,
        canInteract = canMount,
        onSelect = function (data)
            mountStretcher(data.entity, mount.anim)
        end
    }
end

targetOptions[#targetOptions + 1] = {
    name = 'stretcher:patient:load',
    menuName = 'stretcher',
    label = 'Naikkan orang',
    icon = 'fa-solid fa-person-circle-plus',
    distance = 2.0,
    groups = config.allowedJobs,
    canInteract = canMount,
    onSelect = function (data)
        loadPatient(data.entity)
    end
}

targetOptions[#targetOptions + 1] = {
    name = 'stretcher:patient:unload',
    menuName = 'stretcher',
    label = 'Turunkan orang',
    icon = 'fa-solid fa-person-circle-minus',
    distance = 2.0,
    groups = config.allowedJobs,
    canInteract = function (entity)
        return isStretcherIdle(entity) and isOccupied(entity)
    end,
    onSelect = function (data)
        unloadPatient(data.entity)
    end
}

targetOptions[#targetOptions + 1] = {
    name = 'stretcher:settings',
    menuName = 'stretcher',
    label = 'Pengaturan stretcher',
    icon = 'fa-solid fa-sliders',
    distance = 2.0,
    openMenu = 'stretcher:settings',
    canInteract = isStretcherIdle
}

targetOptions[#targetOptions + 1] = {
    name = 'stretcher:store',
    menuName = 'stretcher',
    label = 'Simpan stretcher',
    icon = 'fa-solid fa-box-archive',
    distance = 2.0,
    canInteract = canMount,
    onSelect = function (data)
        storeStretcher(data.entity)
    end
}

for i = 1, #config.extras do
    local extra = config.extras[i]

    targetOptions[#targetOptions + 1] = {
        name = 'stretcher:extra:' .. extra.id,
        menuName = 'stretcher:settings',
        label = extra.label,
        icon = 'fa-solid fa-toggle-on',
        distance = 2.0,
        canInteract = isStretcherIdle,
        onSelect = function (data)
            toggleExtra(data.entity, extra.id)
        end
    }
end

targetOptions[#targetOptions + 1] = {
    name = 'stretcher:extra:seat',
    menuName = 'stretcher:settings',
    label = 'Sandaran',
    icon = 'fa-solid fa-toggle-on',
    distance = 2.0,
    canInteract = isStretcherIdle,
    onSelect = function (data)
        toggleSeat(data.entity)
    end
}

targetOptions[#targetOptions + 1] = {
    name = 'stretcher:drop',
    label = 'Letakkan stretcher',
    icon = 'fa-solid fa-hand-point-down',
    distance = 2.5,
    canInteract = function (entity)
        return entity == carriedStretcher
    end,
    onSelect = dropStretcher
}

targetOptions[#targetOptions + 1] = {
    name = 'stretcher:dismount',
    label = 'Bangun dari stretcher',
    icon = 'fa-solid fa-person-walking',
    distance = 2.5,
    canInteract = function (entity)
        return entity == mountedStretcher
    end,
    onSelect = dismountStretcher
}

exports.ox_target:addGlobalVehicle(targetOptions)

local function canTransferToBed()
    return carriedStretcher ~= nil and isOccupied(carriedStretcher)
end

local function transferToBed(index)
    local entity = carriedStretcher

    if not entity or not NetworkGetEntityIsNetworked(entity) then return end

    if not lib.callback.await('rhd_stretcher:transferToBed', false, NetworkGetNetworkIdFromEntity(entity), index) then
        return lib.notify({ type = 'error', description = 'Gagal memindahkan pasien ke bed' })
    end

    lib.notify({ type = 'success', description = 'Pasien dipindahkan ke bed' })
end

CreateThread(function ()
    local bedlist = exports['sm_resource']:getBedList()

    if type(bedlist) ~= 'table' then
        return warn('Failed to load ambulance bed list')
    end

    for i = 1, #bedlist do
        local bed = bedlist[i]
        local bedIndex = i
        local coords = bed.coords

        ox_target:addSphereZone({
            coords = vec(coords.x, coords.y, coords.z),
            radius = 1.5,
            options = {
                {
                    name = 'stretcher:bed:' .. bedIndex,
                    label = 'Pindahkan pasien ke bed',
                    icon = 'fa-solid fa-bed-pulse',
                    groups = config.allowedJobs,
                    canInteract = canTransferToBed,
                    onSelect = function ()
                        transferToBed(bedIndex)
                    end
                }
            }
        })
    end
end)

RegisterNetEvent('rhd_stretcher:client:mountPatient', function (netId)
    if carriedStretcher or mountedStretcher then return end

    local ok, entity = pcall(lib.waitFor, function ()
        local vehicle = NetworkGetEntityFromNetworkId(netId)

        if vehicle ~= 0 and DoesEntityExist(vehicle) and GetEntityModel(vehicle) == stretcherModel then
            return vehicle
        end
    end, nil, 1000)

    if not ok then return end

    attachToStretcher(entity, 'sleep')
end)

RegisterNetEvent('rhd_stretcher:client:dismountPatient', function ()
    clearMount(true)
end)

exports('releaseFromStretcher', function ()
    if not mountedStretcher then return false end

    mountedStretcher = nil

    ClearPedTasks(cache.ped)
    DetachEntity(cache.ped, true, true)

    return true
end)

AddEventHandler('onResourceStop', function (resource)
    if resource ~= GetCurrentResourceName() then return end

    if carriedStretcher then
        dropStretcher()
    elseif mountedStretcher then
        dismountStretcher()
    end
end)

local function spawnStretcher()
    if not pcall(lib.requestModel, config.model, 1500) then return
        warn('Failed to request stretcher model')
    end

    local spawnCoords = GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, 2.0, 0.0)
    local spawnHeading = GetEntityHeading(cache.ped)
    local vehicle = CreateVehicle(config.model, spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnHeading, true, false)

    if not pcall(lib.waitFor, function ()
        if DoesEntityExist(vehicle) then
            return true
        end
    end) then
        warn('Failed to spawn stretcher')
        return
    end

    local plate = tostring(math.random(1000, 9999)  + tonumber(cache.serverId))
    SetVehicleNumberPlateText(vehicle, plate:trim())
    SetEntityHeading(vehicle, spawnHeading)

    SetVehicleExtra(vehicle, 1, true)
    SetVehicleExtra(vehicle, 2, false)
    SetVehicleExtra(vehicle, 11, false)
    SetVehicleExtra(vehicle, 12, true)

    for i = 1, #config.extras do
        SetVehicleExtra(vehicle, config.extras[i].id, true)
    end

    return NetworkGetNetworkIdFromEntity(vehicle)
end

lib.callback.register('rhd_stretcher:spawn', function ()
    return spawnStretcher()
end)