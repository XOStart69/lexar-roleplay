local IsControlPressed = IsControlPressed
local IsControlJustPressed = IsControlJustPressed
local GetEntitySpeed = GetEntitySpeed
local IsVehicleOnAllWheels = IsVehicleOnAllWheels
local SetVehicleForwardSpeed = SetVehicleForwardSpeed
local Wait = Wait

local TOGGLE_COOLDOWN = 1000
local SPEED_DROP_TOLERANCE = 1.5
local MIN_FORWARD_RATIO = 0.95

local CONTROL_BRAKE = 72
local CONTROL_HANDBRAKE = 76
local CONTROL_STEER_LEFT = 63
local CONTROL_STEER_RIGHT = 64

local ALLOWED_CLASSES = {}

for class = 0, 12 do
    ALLOWED_CLASSES[class] = true
end

for class = 17, 20 do
    ALLOWED_CLASSES[class] = true
end

local cruisedSpeed = 0
local lastToggle = 0

---@param text string
---@param kind string
local function notify(text, kind)
    lib.notify({ description = text, type = kind })
end

local function stopCruise()
    cruisedSpeed = 0
    notify('Cruise control deactivated', 'error')
end

---@param vehicle number
local function runCruise(vehicle)
    while cruisedSpeed > 0 and cache.vehicle == vehicle do
        if IsControlJustPressed(2, CONTROL_BRAKE) or IsControlPressed(2, CONTROL_HANDBRAKE) then
            return stopCruise()
        end

        local speed = GetEntitySpeed(vehicle)
        local steering = IsControlPressed(2, CONTROL_STEER_LEFT) or IsControlPressed(2, CONTROL_STEER_RIGHT)

        if not steering then
            if speed < cruisedSpeed - SPEED_DROP_TOLERANCE then
                return stopCruise()
            end

            if speed < cruisedSpeed and IsVehicleOnAllWheels(vehicle) then
                SetVehicleForwardSpeed(vehicle, cruisedSpeed)
            end
        end

        Wait(0)
    end

    cruisedSpeed = 0
end

---@param vehicle number
---@param speed number
---@return boolean
local function isSliding(vehicle, speed)
    if speed <= 2.0 then return false end

    local velocity = GetEntityVelocity(vehicle)
    local forward = GetEntityForwardVector(vehicle)
    local forwardSpeed = velocity.x * forward.x + velocity.y * forward.y + velocity.z * forward.z

    return forwardSpeed < 0 or forwardSpeed / speed < MIN_FORWARD_RATIO
end

local function toggleCruise()
    if cruisedSpeed > 0 then
        return stopCruise()
    end

    local vehicle = cache.vehicle
    if not vehicle or cache.seat ~= -1 then return end

    local now = GetGameTimer()
    if now - lastToggle < TOGGLE_COOLDOWN then return end

    lastToggle = now

    local braking = IsControlPressed(2, CONTROL_HANDBRAKE) or IsControlPressed(2, CONTROL_BRAKE)
    local steering = IsControlPressed(2, CONTROL_STEER_LEFT) or IsControlPressed(2, CONTROL_STEER_RIGHT)

    if braking or steering then
        return notify('Cruise control unavailable', 'error')
    end

    local speed = GetEntitySpeed(vehicle)

    if isSliding(vehicle, speed) then
        return notify('Cruise control unavailable', 'error')
    end

    if speed <= 0 or GetVehicleCurrentGear(vehicle) <= 0 then return end

    cruisedSpeed = speed
    notify('Cruise control activated', 'success')
    CreateThread(function()
        runCruise(vehicle)
    end)
end

lib.addKeybind({
    name = 'toggle_cruise_control',
    description = 'Toggle Cruise Control',
    defaultKey = 'Y',
    onPressed = function()
        local vehicle = cache.vehicle
        if not vehicle or cache.seat ~= -1 then return end

        if not ALLOWED_CLASSES[GetVehicleClass(vehicle)] then
            return notify('Cruise control unavailable', 'error')
        end

        toggleCruise()
    end
})
