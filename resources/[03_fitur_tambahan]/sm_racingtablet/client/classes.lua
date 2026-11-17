local GetVehicleHandlingFloat = GetVehicleHandlingFloat
local GetVehicleAcceleration = GetVehicleAcceleration
local GetVehicleEstimatedMaxSpeed = GetVehicleEstimatedMaxSpeed
local GetVehicleMaxBraking = GetVehicleMaxBraking
local mexp = math.exp
local mfloor = math.floor

local pi = Config.PerformanceIndex
local accelMagic = pi.accelerationMagic
local mods = pi.mods
local balance = pi.balance

local sortedClasses = {}
for class, startsAt in pairs(pi.classes) do
    sortedClasses[#sortedClasses + 1] = { class = class, startsAt = startsAt }
end
table.sort(sortedClasses, function(a, b) return a.startsAt < b.startsAt end)
local sortedCount = #sortedClasses

---@param vehicle number
---@param field string
---@return number
local function handlingField(vehicle, field)
    return GetVehicleHandlingFloat(vehicle, 'CHandlingData', field)
end

---@param acceleration number
---@return number
local function normalizeAcceleration(acceleration)
    local adjusted = (acceleration - accelMagic.adjust) / accelMagic.divide
    return 1 / (1 + mexp(accelMagic.negMulti * (adjusted - accelMagic.adjustTwo))) * 9 + 1
end

---@param score number
---@return string
local function classFromScore(score)
    local result = pi.lowestClass
    for i = 1, sortedCount do
        local entry = sortedClasses[i]
        if entry.startsAt > score then return result end
        result = entry.class
    end
    return result
end

---@param vehicle number
---@return number
local function getPerformanceScore(vehicle)
    local driveBiasFront = handlingField(vehicle, 'fDriveBiasFront')
    local awdMod = (driveBiasFront ~= 0.0 and driveBiasFront ~= 1.0) and mods.awdDrivetrain or 0.0

    local lowSpeedTraction = 1.0
    if mods.lowSpeedTractionLoss then
        local lowSpeedMult = handlingField(vehicle, 'fLowSpeedTractionLossMult')
        lowSpeedTraction = lowSpeedTraction + (lowSpeedMult - lowSpeedTraction) * 0.15
    end

    local normalizedAccel = normalizeAcceleration(GetVehicleAcceleration(vehicle))
    local accelScore = normalizedAccel + awdMod * normalizedAccel + handlingField(vehicle, 'fClutchChangeRateScaleUpShift') * mods.gearUpMultiplier
    local speedScore = GetVehicleEstimatedMaxSpeed(vehicle) / (handlingField(vehicle, 'fInitialDragCoeff') + 2.0)
    local brakingScore = GetVehicleMaxBraking(vehicle) * 10.0
    local suspension = (handlingField(vehicle, 'fSuspensionForce') + handlingField(vehicle, 'fSuspensionReboundDamp') + handlingField(vehicle, 'fSuspensionCompDamp') + handlingField(vehicle, 'fAntiRollBarForce')) / 4
    local handlingScore = (handlingField(vehicle, 'fTractionCurveMax') + suspension) * (handlingField(vehicle, 'fTractionCurveMin') / lowSpeedTraction) + awdMod

    return mfloor(((accelScore ^ balance.acceleration) + (speedScore ^ balance.speed) + (handlingScore ^ balance.handling) + (brakingScore ^ balance.braking)) * balance.ratingMultiplier)
end

---@param vehicle number
---@return string
function getVehicleClass(vehicle)
    if Config.UseCustomClassSystem then
        return 'No Class'
    end
    return classFromScore(getPerformanceScore(vehicle))
end

---@return table<string, number>
function getVehicleClasses()
    if Config.UseCustomClassSystem then
        return { ['No Class'] = 100 }
    end
    return pi.classes
end
