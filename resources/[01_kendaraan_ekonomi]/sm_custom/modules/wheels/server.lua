---@class WheelsServer
local wheels = {}

local shared = modules.cart

---@param kind integer
---@return string?
function wheels.wheel(kind)
    return shared.wheel(kind)
end

---@param vehicle number
---@return string?
function wheels.rim(vehicle)
    local kind = GetVehicleWheelType(vehicle)
    local mod = GetVehicleMod(vehicle, 23)

    if mod < 0 then return end

    return ("%d:%d"):format(kind, mod)
end

---@param vehicle number
---@return string
function wheels.key(vehicle)
    local plate = (GetVehicleNumberPlateText(vehicle) or ''):gsub('^%s*(.-)%s*$', '%1')

    return ("%s_%s"):format(plate, GetEntityModel(vehicle))
end

---@param vehicle number
---@return number
function wheels.count(vehicle)
    return math.max(GetVehicleNumberOfWheels(vehicle), 0)
end

return wheels
