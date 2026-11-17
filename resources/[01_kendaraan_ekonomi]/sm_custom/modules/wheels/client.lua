local config = require('config.client').fitment

local CLONE <const> = vec3(-1084.9698, -8489.8350, 444.4068)
local DRIFT <const> = 0.0001

---@class WheelsClient
local wheels = {}

---@class FitmentValues
---@field height number
---@field size? number
---@field width? number
---@field rim? string
---@field offset table<string, number>
---@field rotation table<string, number>

---@class FitmentRange
---@field min number
---@field max number

---@class FitmentRanges
---@field height FitmentRange
---@field size? FitmentRange
---@field width? FitmentRange
---@field offset table<string, FitmentRange>
---@field rotation table<string, FitmentRange>

---@class FitmentChange
---@field property string
---@field value number
---@field mode 'group' | 'single'
---@field target? string

---@type table<number, { upper: number, lower: number }>
local baselines = {}

---@param vehicle number
---@param height number
local function setHeight(vehicle, height)
    SetVehicleSuspensionHeight(vehicle, height)

    local settings = config.suspension[GetEntityModel(vehicle)]
    if not settings then return end

    local model = GetEntityModel(vehicle)
    local base = baselines[model]

    if not base then
        base = {
            upper = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fSuspensionUpperLimit'),
            lower = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fSuspensionLowerLimit'),
        }
        baselines[model] = base
    end

    local shift = math.max(settings.threshold - height, 0.0) * settings.compensation
    local upper = math.max(base.upper + shift, settings.minUpperLimit)

    SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fSuspensionUpperLimit', upper)
    SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fSuspensionLowerLimit', base.lower + shift)
end

local scalar = {
    height = { get = GetVehicleSuspensionHeight, set = setHeight },
}

local sizing = {
    size = { get = GetVehicleWheelSize, set = SetVehicleWheelSize },
    width = { get = GetVehicleWheelWidth, set = SetVehicleWheelWidth },
}

local single = {
    offset = { get = GetVehicleWheelXOffset, set = SetVehicleWheelXOffset },
    rotation = { get = GetVehicleWheelYRotation, set = SetVehicleWheelYRotation },
}

---@param vehicle number
---@return string?
function wheels.key(vehicle)
    local plate = GetVehicleNumberPlateText(vehicle):match('^%s*(.-)%s*$')
    if plate == '' then return end

    return ('%s_%s'):format(plate, GetEntityModel(vehicle))
end

---@param vehicle number
---@return string?
function wheels.rim(vehicle)
    local mod = GetVehicleMod(vehicle, 23)
    if mod < 0 then return end

    return ('%d:%d'):format(GetVehicleWheelType(vehicle), mod)
end

---@param vehicle number
---@return integer
function wheels.count(vehicle)
    return math.max(GetVehicleNumberOfWheels(vehicle), 0)
end

---@param values FitmentValues
---@return FitmentValues
function wheels.copy(values)
    return {
        height = values.height,
        size = values.size,
        width = values.width,
        rim = values.rim,
        offset = table.clone(values.offset),
        rotation = table.clone(values.rotation),
    }
end

---@param values FitmentValues
---@param source FitmentValues
function wheels.rebase(values, source)
    values.rim, values.size, values.width = source.rim, source.size, source.width
end

---@param axle integer
---@param axles integer
---@return string
local function axleName(axle, axles)
    if axle == 1 then return locale('wheel.front') end
    if axle == axles then return locale('wheel.rear') end

    return locale('wheel.middle', axle - 1)
end

---@class FitmentTarget
---@field id string
---@field label string
---@field wheels integer[]

---@param vehicle number
---@return { group: FitmentTarget[], single: FitmentTarget[] }
function wheels.targets(vehicle)
    local sides = { 'wheel.left', 'wheel.right' }
    local count = wheels.count(vehicle)
    local axles = math.ceil(count / 2)
    local targets = { group = {}, single = {} }

    for axle = 1, axles do
        local first = (axle - 1) * 2

        targets.group[axle] = {
            id = ('axle:%d'):format(axle),
            label = axleName(axle, axles),
            wheels = first + 1 < count and { first, first + 1 } or { first },
        }
    end

    for wheel = 0, count - 1 do
        targets.single[wheel + 1] = {
            id = ('wheel:%d'):format(wheel),
            label = ('%s %s'):format(axleName(wheel // 2 + 1, axles), locale(sides[wheel % 2 + 1])),
            wheels = { wheel },
        }
    end

    return targets
end

---@param vehicle number
---@return FitmentValues
function wheels.capture(vehicle)
    local rim = wheels.rim(vehicle)
    local values = { offset = {}, rotation = {} }

    for property, fn in pairs(scalar) do
        values[property] = fn.get(vehicle)
    end

    if rim then
        values.rim, values.size, values.width = rim, GetVehicleWheelSize(vehicle), GetVehicleWheelWidth(vehicle)
    end

    for wheel = 0, wheels.count(vehicle) - 1 do
        for property, fn in pairs(single) do
            values[property][tostring(wheel)] = fn.get(vehicle, wheel)
        end
    end

    return values
end

---@param vehicle number
---@param values FitmentValues
function wheels.hold(vehicle, values)
    for property, fn in pairs(single) do
        for wheel, value in pairs(values[property]) do
            fn.set(vehicle, tonumber(wheel) --[[@as integer]], value)
        end
    end

    if not values.rim or values.rim ~= wheels.rim(vehicle) then return end

    for property, fn in pairs(sizing) do
        local value = values[property]

        if value and math.abs(fn.get(vehicle) - value) > DRIFT then
            fn.set(vehicle, value)
        end
    end
end

---@param vehicle number
---@param values FitmentValues
function wheels.apply(vehicle, values)
    for property, fn in pairs(scalar) do
        fn.set(vehicle, tonumber(values[property]) or 0.0)
    end

    wheels.hold(vehicle, values)
end

---@param range FitmentRange?
---@param value number
---@return boolean
local function within(range, value)
    return range ~= nil and value >= range.min and value <= range.max
end

---@param count integer
---@param mode string
---@param target any
---@return integer[]?
local function resolve(count, mode, target)
    local index = tonumber(tostring(target):match(mode == 'group' and '^axle:(%d+)$' or '^wheel:(%d+)$'))
    if not index then return end

    if mode == 'single' then
        return index < count and { index } or nil
    end

    local first = (index - 1) * 2
    if index < 1 or first >= count then return end

    return first + 1 < count and { first, first + 1 } or { first }
end

---@param vehicle number
---@param values FitmentValues
---@param ranges FitmentRanges
---@param change FitmentChange
---@return boolean
function wheels.adjust(vehicle, values, ranges, change)
    local value = tonumber(change.value)
    if not value or value ~= value then return false end

    local property = change.property
    local fn = scalar[property] or sizing[property]

    if fn then
        if not within(ranges[property], value) then return false end
        if sizing[property] and values.rim ~= wheels.rim(vehicle) then return false end

        fn.set(vehicle, value)
        values[property] = value

        return true
    end

    fn = single[property]
    local list = fn and resolve(wheels.count(vehicle), change.mode, change.target)
    if not list then return false end

    for _, wheel in ipairs(list) do
        local adjusted = change.mode == 'group' and wheel % 2 == 0 and -value or value
        if not within(ranges[property][tostring(wheel)], adjusted) then return false end
    end

    for _, wheel in ipairs(list) do
        local adjusted = change.mode == 'group' and wheel % 2 == 0 and -value or value

        fn.set(vehicle, wheel, adjusted)
        values[property][tostring(wheel)] = adjusted
    end

    return true
end

---@param initial number
---@param set fun(value: number)
---@param get fun(): number
---@param direction integer
---@return number
local function boundary(initial, set, get, direction)
    local last = initial
    local step = math.max(math.abs(initial) * 0.25, 0.025)

    for _ = 1, 12 do
        local requested = initial + direction * step

        set(requested)

        local actual = tonumber(get())
        if not actual or actual ~= actual or math.abs(actual) == math.huge then break end
        if math.abs(actual - last) < 0.0001 then break end

        last = actual

        if math.abs(actual - requested) > 0.001 then break end

        step *= 2
    end

    set(initial)

    return last
end

---@param initial number
---@param set fun(value: number)
---@param get fun(): number
---@return FitmentRange
local function range(initial, set, get)
    return { min = boundary(initial, set, get, -1), max = boundary(initial, set, get, 1) }
end

---@param vehicle number
---@return FitmentValues? defaults
---@return FitmentRanges? ranges
function wheels.probe(vehicle)
    local model = GetEntityModel(vehicle)
    local clone = CreateVehicle(model, CLONE.x, CLONE.y, CLONE.z, 0.0, false, false)

    if clone == 0 then return end

    SetEntityAlpha(clone, 0, false)
    FreezeEntityPosition(clone, true)
    SetEntityInvincible(clone, true)
    SetVehicleModKit(clone, 0)
    SetVehicleWheelType(clone, GetVehicleWheelType(vehicle))
    SetVehicleMod(clone, 15, GetVehicleMod(vehicle, 15), false)
    SetVehicleMod(clone, 23, GetVehicleMod(vehicle, 23), GetVehicleModVariation(vehicle, 23))
    SetVehicleMod(clone, 24, GetVehicleMod(vehicle, 24), GetVehicleModVariation(vehicle, 24))
    Wait(100)

    local defaults = wheels.capture(clone)
    local ranges = { offset = {}, rotation = {} }

    for _, group in ipairs(defaults.rim and { scalar, sizing } or { scalar }) do
        for property, fn in pairs(group) do
            local set = function(value) fn.set(clone, value) end
            local get = function() return fn.get(clone) end

            ranges[property] = range(defaults[property], set, get)
        end
    end

    for wheel = 0, wheels.count(clone) - 1 do
        local key = tostring(wheel)

        for property, fn in pairs(single) do
            local set = function(value) fn.set(clone, wheel, value) end
            local get = function() return fn.get(clone, wheel) end

            ranges[property][key] = range(defaults[property][key], set, get)
        end
    end

    DeleteEntity(clone)

    return defaults, ranges
end

return wheels
