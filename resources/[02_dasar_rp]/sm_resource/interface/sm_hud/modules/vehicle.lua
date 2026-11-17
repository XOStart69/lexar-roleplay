
---@param vehicle number entity handle
---@return number 0-100
local function getFuel(vehicle)
    return sm_fuel.get(vehicle) or GetVehicleFuelLevel(vehicle)
end

---@param vehicle number entity handle
---@return 'off'|'low'|'high'
local function getHeadlights(vehicle)
    local lightsOn, highBeams = GetVehicleLightsState(vehicle)
    if highBeams then return 'high' end
    if lightsOn  then return 'low'  end
    return 'off'
end

local nosLevel = 0
local GetEntitySpeed = GetEntitySpeed
local GetVehicleCurrentRpm = GetVehicleCurrentRpm
local GetVehicleCurrentGear = GetVehicleCurrentGear
local GetVehicleEngineHealth = GetVehicleEngineHealth
local GetEntityModel = GetEntityModel
local HideHudComponentThisFrame = HideHudComponentThisFrame
local GetVehicleClass = GetVehicleClass
local GetEntityCoords = GetEntityCoords
local GetEntityPitch = GetEntityPitch
local GetEntityRoll = GetEntityRoll
local GetEntityHeading = GetEntityHeading
local GetEntityVelocity = GetEntityVelocity
local GetGroundZFor_3dCoord = GetGroundZFor_3dCoord
local GetWaterHeight = GetWaterHeight
local GetIsVehicleEngineRunning = GetIsVehicleEngineRunning
local GetLandingGearState = GetLandingGearState
local IsThisModelAHeli = IsThisModelAHeli
local IsThisModelAPlane = IsThisModelAPlane
local floor = math.floor
local max = math.max
local min = math.min

local METER_TO_FEET = 3.28084
local MS_TO_KNOTS = 1.94384
local MS_TO_FPM = 196.85

---@alias AircraftKind 'plane'|'heli'

---@param vehicle number
---@param model number
---@return AircraftKind|nil
local function getAircraftKind(vehicle, model)
    if IsThisModelAPlane(model) then return 'plane' end
    if IsThisModelAHeli(model) then return 'heli' end

    local class = GetVehicleClass(vehicle)
    if class == 16 then return 'plane' end
    if class == 15 then return 'heli' end

    return nil
end

--- Landing gear native returns 0/4 = down, 1/2/3 = moving/up.
--- Helicopters with skids report -1 / no valid state.
---@param vehicle number
---@return 'down'|'up'|'moving'|nil
local function getGearState(vehicle)
    local state = GetLandingGearState(vehicle)
    if state == 0 or state == 4 then return 'down' end
    if state == 3 then return 'up' end
    if state == 1 or state == 2 then return 'moving' end
    return nil
end

--- Ground reference below the aircraft: terrain, or water surface when it is higher.
---@param coords vector3
---@return number|nil meters
local function getGroundZ(coords)
    local found, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z, false)
    local hasWater, waterZ = GetWaterHeight(coords.x, coords.y, coords.z)

    if hasWater and waterZ then
        if not found or waterZ > groundZ then return waterZ end
    end

    if found then return groundZ end
    return nil
end

local lastAgl = 0

---@param data table destination filled in place
---@param vehicle number
---@param kind AircraftKind
local function buildAviationData(data, vehicle, kind)
    local coords = GetEntityCoords(vehicle)
    local velocity = GetEntityVelocity(vehicle)
    local speedMs = GetEntitySpeed(vehicle)

    -- MSL altitude: GTA world Z is roughly sea level at 0.
    local altitude = coords.z * METER_TO_FEET

    local groundZ = getGroundZ(coords)
    local agl
    if groundZ then
        agl = max(0, (coords.z - groundZ) * METER_TO_FEET)
        lastAgl = agl
    else
        -- Out of collision streaming range (very high up); keep the last known reading.
        agl = lastAgl
    end

    data.aircraft = true
    data.aircraftType = kind
    data.altitude = floor(altitude + 0.5)
    data.agl = floor(agl + 0.5)
    data.airspeed = floor(speedMs * MS_TO_KNOTS + 0.5)
    data.speed = floor(speedMs * 3.6 + 0.5)
    data.vspeed = floor(velocity.z * MS_TO_FPM + 0.5)
    data.pitch = floor(GetEntityPitch(vehicle) * 10 + 0.5) / 10
    data.roll = floor(GetEntityRoll(vehicle) * 10 + 0.5) / 10
    data.heading = floor(GetEntityHeading(vehicle) + 0.5) % 360
    data.gearState = getGearState(vehicle)
    data.engineOn = GetIsVehicleEngineRunning(vehicle)
end

--- Payload reused across ticks so a steady drive allocates nothing.
local data = {}
local sent = {}

--- True when `data` differs from what the NUI last received, syncing `sent` as it compares.
---@return boolean
local function takeDirty()
    local dirty = false

    for k, v in pairs(data) do
        if sent[k] ~= v then
            sent[k] = v
            dirty = true
        end
    end

    for k in pairs(sent) do
        if data[k] == nil then
            sent[k] = nil
            dirty = true
        end
    end

    return dirty
end

local function vehicleThread()
    CreateThread(function()
        local sleep
        local aircraftKind = getAircraftKind(cache.vehicle, GetEntityModel(cache.vehicle))
        local harnessDura = Entity(cache.vehicle).state.harnessDurability or 0

        -- Watch the bag instead of reading it every tick. A non-networked vehicle has no bag to
        -- subscribe to, so those fall back to polling.
        local netId = NetworkGetEntityIsNetworked(cache.vehicle) and VehToNet(cache.vehicle) or 0
        local harnessHandler = netId ~= 0 and
            AddStateBagChangeHandler('harnessDurability', ('entity:%d'):format(netId), function(_, _, value)
                harnessDura = value or 0
            end) or nil

        while cache.vehicle do
            sleep = 500

            local vehicle = cache.vehicle
            if not (vehicle and DoesEntityExist(vehicle)) then
                break
            end

            local rpm = floor(GetVehicleCurrentRpm(vehicle) * 100 + 0.5) / 100
            local speed = floor(GetEntitySpeed(vehicle) * 3.6 + 0.5)

            if speed > 0 or rpm > 0.2 then
                sleep = aircraftKind and 50 or 100
            end

            if not SM_HUD.visible then
                sleep = 1000
            end

            data.speed = speed
            data.rpm = rpm
            data.gear = GetVehicleCurrentGear(vehicle)
            data.fuel = floor(getFuel(vehicle) + 0.5)
            data.engineHealth = max(0, min(100, floor(GetVehicleEngineHealth(vehicle) / 10 + 0.5)))
            data.nitrous = floor(nosLevel + 0.5)
            data.inVehicle = true
            data.seatbelt = playerState.seatbelt
            data.hasHarness = playerState.harness
            if not harnessHandler then
                harnessDura = Entity(vehicle).state.harnessDurability or 0
            end

            data.harnessDurability = harnessDura
            data.headlights = getHeadlights(vehicle)
            data.aircraft = false

            if aircraftKind then
                buildAviationData(data, vehicle, aircraftKind)
            end

            if takeDirty() then
                interface.send({
                    action = 'updateVehicle',
                    data = data,
                })
            end

            Wait(sleep)
        end

        if harnessHandler then
            RemoveStateBagChangeHandler(harnessHandler)
        end

        lastAgl = 0

        for k in pairs(data) do data[k] = nil end
        for k in pairs(sent) do sent[k] = nil end

        interface.send({
            action = 'updateVehicle',
            data = {
                inVehicle = false,
                aircraft = false,
            },
        })
    end)
end


--- Both components re-appear every frame, so this has to run per-frame -- but only while driving.
local function hideVehicleHudThread()
    CreateThread(function ()
        while cache.vehicle do
            HideHudComponentThisFrame(6)
            HideHudComponentThisFrame(8)
            Wait(0)
        end
    end)
end

lib.onCache('vehicle', function (vehicle)
    local model = vehicle and GetEntityModel(vehicle)

    if not model then return end

    hideVehicleHudThread()

    if IsThisModelABicycle(model) then return end

    vehicleThread()
end)

RegisterNetEvent('sm_hud:client:updateNitrous', function (level)
    nosLevel = level
end)
