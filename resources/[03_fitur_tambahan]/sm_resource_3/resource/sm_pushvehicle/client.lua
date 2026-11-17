local Wait = Wait
local DisableControlAction = DisableControlAction
local IsDisabledControlPressed = IsDisabledControlPressed
local IsDisabledControlJustPressed = IsDisabledControlJustPressed
local IsControlPressed = IsControlPressed
local IsEntityAttachedToEntity = IsEntityAttachedToEntity
local TaskVehicleTempAction = TaskVehicleTempAction
local SetVehicleForwardSpeed = SetVehicleForwardSpeed
local GetEntityRoll = GetEntityRoll
local GetEntitySpeed = GetEntitySpeed
local DoesEntityExist = DoesEntityExist
local IsEntityDead = IsEntityDead

local ANIM_DICT = 'missfinale_c2ig_11'
local ANIM_CLIP = 'pushcar_offcliff_m'

local CONTROL_FORWARD = 71
local CONTROL_LEFT = 34
local CONTROL_RIGHT = 9
local CONTROL_STOP = 23
local CONTROL_STOP_ALT = 105
local CONTROL_DUCK = 75

local pushing = false

---@return boolean
local function isDead()
    local metadata = QBPlayerData.metadata
    if metadata and (metadata.isdead or metadata.inlaststand) then return true end

    return IsEntityDead(cache.ped)
end

---@param ped number
---@param vehicle number
---@param message string
local function stopPushing(ped, vehicle, message)
    DetachEntity(ped, false, false)
    ClearPedTasks(ped)
    SetVehicleForwardSpeed(vehicle, 0.0)
    lib.notify({ description = message, type = 'error' })
end

---@param vehicle number
---@param fromFront boolean
local function push(vehicle, fromFront)
    if pushing then return end

    if isDead() or GetPedInVehicleSeat(vehicle, -1) ~= 0 then
        return lib.notify({ description = 'You cant do that..', type = 'error' })
    end

    if not lib.requestAnimDict(ANIM_DICT, 5000) then return end

    pushing = true

    local ped = cache.ped
    local dimension = GetModelDimensions(GetEntityModel(vehicle))
    local offsetY = fromFront and (dimension.y * -1 + 0.1) or (dimension.y - 0.3)
    local heading = fromFront and 180.0 or 0.0
    local speed = fromFront and -1.0 or 1.0

    NetworkRequestControlOfEntity(vehicle)
    AttachEntityToEntity(ped, vehicle, 0, 0.0, offsetY, dimension.z + 1.0, 0.0, 0.0, heading, false, false, true, false, true)
    TaskPlayAnim(ped, ANIM_DICT, ANIM_CLIP, 2.0, -8.0, -1, 35, 0, false, false, false)
    RemoveAnimDict(ANIM_DICT)
    Wait(200)

    lib.notify({ description = 'Press [W] for forward, [A/D] for turn it, and [F/X] for stop pushing' })

    while true do
        DisableControlAction(0, CONTROL_STOP, true)
        DisableControlAction(0, CONTROL_DUCK, true)

        if not DoesEntityExist(vehicle) or IsEntityDead(ped) then
            DetachEntity(ped, false, false)
            ClearPedTasks(ped)
            break
        end

        if not IsEntityAttachedToEntity(ped, vehicle) then
            ClearPedTasks(ped)
            SetVehicleForwardSpeed(vehicle, 0.0)
            lib.notify({ description = 'You stop pushing vehicle..', type = 'error' })
            break
        end

        if IsDisabledControlPressed(0, CONTROL_LEFT) then
            TaskVehicleTempAction(ped, vehicle, 11, 1000)
        end

        if IsDisabledControlPressed(0, CONTROL_RIGHT) then
            TaskVehicleTempAction(ped, vehicle, 10, 1000)
        end

        if IsControlPressed(0, CONTROL_FORWARD) then
            SetVehicleForwardSpeed(vehicle, speed)
        end

        local roll = GetEntityRoll(vehicle)

        if (roll > 75.0 or roll < -75.0) and GetEntitySpeed(vehicle) < 2 then
            stopPushing(ped, vehicle, 'You cant push an overturned car..')
            break
        end

        if IsDisabledControlJustPressed(0, CONTROL_STOP) or IsControlPressed(0, CONTROL_STOP_ALT) then
            stopPushing(ped, vehicle, 'You stop pushing vehicle..')
            break
        end

        Wait(0)
    end

    pushing = false
end

---@param entity number
---@return boolean
local function canPush(entity)
    return not pushing and not cache.vehicle and GetPedInVehicleSeat(entity, -1) == 0
end

ox_target:addGlobalVehicle({
    {
        name = 'sm_pushvehicle:front',
        icon = 'fa-solid fa-car',
        label = 'Dorong Depan',
        canInteract = canPush,
        onSelect = function(data)
            push(data.entity, true)
        end
    },
    {
        name = 'sm_pushvehicle:rear',
        icon = 'fa-solid fa-car',
        label = 'Dorong Belakang',
        canInteract = canPush,
        onSelect = function(data)
            push(data.entity, false)
        end
    },
})

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource or not pushing then return end

    DetachEntity(cache.ped, false, false)
    ClearPedTasks(cache.ped)
end)
