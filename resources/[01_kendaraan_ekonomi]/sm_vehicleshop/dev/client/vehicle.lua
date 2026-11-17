---@param vehicle integer
---@return string VehicleType
local function GetVehicleType(vehicle)
    local class = GetVehicleClass(vehicle)
    if class == 8 or class == 13 then
        return "bike"
    elseif class == 14 or class == 15 or class == 16 then
        return class == 14 and "boat" or class == 15 and "helicopter" or "plane"
    else
        return "automobile"
    end
end

---@param val number
---@return number? Value
local function prefixValue(val)
    if type(val) ~= 'number' then return end
    return math.min(100, math.max(0, math.floor(val)))
end

local function getPerformanceStats(vehicle)
    local fInitialDriveMaxFlatVel = GetVehicleHandlingFloat(vehicle, "CHandlingData", "fInitialDriveMaxFlatVel")
    local fInitialDriveForce = GetVehicleHandlingFloat(vehicle, "CHandlingData", "fInitialDriveForce")
    local fBrakeForce = GetVehicleHandlingFloat(vehicle, "CHandlingData", "fBrakeForce")
    local fTractionCurveMax = GetVehicleHandlingFloat(vehicle, "CHandlingData", "fTractionCurveMax")
    local fTractionCurveMin = GetVehicleHandlingFloat(vehicle, "CHandlingData", "fTractionCurveMin")
    local fSteeringLock = GetVehicleHandlingFloat(vehicle, "CHandlingData", "fSteeringLock")

    local maxSpeedKMH = (fInitialDriveMaxFlatVel * 0.75) * 3.6

    local stats = {
        speed = prefixValue((maxSpeedKMH / 530.0) * 100),
        acceleration = prefixValue((fInitialDriveForce / 1.3) * 100),
        braking = prefixValue((fBrakeForce / 2.0) * 100),
        handling = prefixValue(((fSteeringLock / 42.0) * 0.7 + ((fTractionCurveMax + fTractionCurveMin) / 5.5) * 0.3) * 100),
        traction = prefixValue((fTractionCurveMax / 3.0) * 100)
    }

    return stats
end

local function getVehicleData(model)
    local hash = joaat(model)

    if not qbLib.safecall(lib.requestModel, model, 1500) then
        return false
    end

    local coords = vector3(0, 0, 0)
    local vehicle = CreateVehicle(hash, coords.x, coords.y, coords.z, 0.0, false, false)

    if not DoesEntityExist(vehicle) then
        SetModelAsNoLongerNeeded(hash)
        lib.print.warn('Failed to load vehicle!')
        return
    end

    Wait(100)

    local vehicleData = {
        model = model,
        name = GetDisplayNameFromVehicleModel(hash),
        brand = GetMakeNameFromVehicleModel(hash),
        price = 999999999999999,
        type = GetVehicleType(vehicle),
        class = GetVehicleClass(vehicle),
    }

    lib.table.merge(vehicleData, (getPerformanceStats(vehicle) or {}))

    DeleteEntity(vehicle)
    SetModelAsNoLongerNeeded(hash)

    lib.setClipboard(json.encode(vehicleData, { indent = true }))
    lib.print.info('Vehicle data has been pasted to the clipboard')
end

RegisterNetEvent('rhd_vehicleshops_getVehicleData', function(model)
    -- server will send net id `65535` for events from the server
    if source ~= 65535 then return end

    getVehicleData(model)
end)
