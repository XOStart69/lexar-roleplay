local config = localmodule 'config'

local MAX_DISTANCE = config.maxDistance
local ANIM_DICT = config.animDict
local ANIM_NAME = config.animName

---@type table<number, table>
local offsets = {}

for model, offset in pairs(config.bikes) do
    offsets[joaat(model)] = offset
end

local attachedBike = 0

local function detach()
    local ped = cache.ped
    local bike = attachedBike
    attachedBike = 0

    DetachEntity(ped, false, true)
    ClearPedTasks(ped)

    local coords = GetEntityCoords(ped)
    SetEntityCoords(ped, coords.x + 1.0, coords.y + 1.0, coords.z - 1.0, false, false, false, false)

    if bike ~= 0 then
        TriggerTokenEvent('sm_bikeseat:server:release')
    end
end

local function watchBike()
    while attachedBike ~= 0 do
        Wait(1000)

        if attachedBike ~= 0 and not DoesEntityExist(attachedBike) then
            attachedBike = 0
            DetachEntity(cache.ped, true, false)
            ClearPedTasks(cache.ped)
            TriggerTokenEvent('sm_bikeseat:server:release')
        end
    end
end

---@param bike number
---@param offset table
local function attach(bike, offset)
    if not NetworkGetEntityIsNetworked(bike) then return end

    local ok = lib.callback.await('sm_bikeseat:server:claim', false, NetworkGetNetworkIdFromEntity(bike))
    if not ok then return end

    local ped = cache.ped

    AttachEntityToEntity(ped, bike, 0, offset.x, offset.y, offset.z, offset.pitch, offset.roll, offset.yaw, true, false, false, false, 0, true)

    if lib.requestAnimDict(ANIM_DICT, 5000) then
        TaskPlayAnim(ped, ANIM_DICT, ANIM_NAME, 3.0, 3.0, -1, 1, 0, false, false, false)
        RemoveAnimDict(ANIM_DICT)
    end

    attachedBike = bike
    CreateThread(watchBike)
end

RegisterCommand('attachbike', function()
    local ped = cache.ped

    if cache.vehicle or GetVehiclePedIsTryingToEnter(ped) ~= 0 then return end

    if attachedBike ~= 0 then
        return detach()
    end

    local bike = lib.getClosestVehicle(GetEntityCoords(ped), MAX_DISTANCE, false)
    if not bike then return end

    local offset = offsets[GetEntityModel(bike)]
    if not offset then return end

    if Entity(bike).state.bikeSeat then return end

    attach(bike, offset)
end, false)

RegisterKeyMapping('attachbike', 'Attach to Bike', 'keyboard', config.key)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource or attachedBike == 0 then return end

    attachedBike = 0
    DetachEntity(cache.ped, true, false)
    ClearPedTasks(cache.ped)
end)
