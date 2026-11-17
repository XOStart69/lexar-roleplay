local config = localmodule 'config.shared'

local rad, cos, sin, atan, deg, min = math.rad, math.cos, math.sin, math.atan, math.deg, math.min

local ZiplineShared = {}

---Resolve the config table backing a zipline of the given type.
---@param ziplineType 'item'|'gun'|'static'
---@param index any
---@return table?
function ZiplineShared.getConfig(ziplineType, index)
    if ziplineType == 'item' then
        return config.items[index]
    end

    if ziplineType == 'gun' then
        return config.ziplineGun
    end

    return config.ziplines[index]
end

---Travel angle in degrees between two points (positive = uphill).
---@param startPos vector3
---@param endPos vector3
---@return number angle
---@return number distance
function ZiplineShared.getAngle(startPos, endPos)
    local distance = #(endPos - startPos)

    if distance == 0 then
        return 0.0, 0.0
    end

    return deg(atan(endPos.z - startPos.z, distance)), distance
end

---How long a ride across the given span should take, in milliseconds.
---@param distance number
---@param angle number
---@param durationMultiplier number
---@param angleEffectMultiplier number
---@return number
function ZiplineShared.getTravelDuration(distance, angle, durationMultiplier, angleEffectMultiplier)
    local duration = distance / (durationMultiplier / 50)

    return duration * (1.0 - ((-angle / 90.0) * (angleEffectMultiplier * 1.5)))
end

---Rotate a vector around the Z axis.
---@param vector vector3
---@param angle number degrees
---@return vector3
function ZiplineShared.rotateVector(vector, angle)
    local radians = rad(angle)
    local cosAngle, sinAngle = cos(radians), sin(radians)

    return vec3(
        vector.x * cosAngle - vector.y * sinAngle,
        vector.x * sinAngle + vector.y * cosAngle,
        vector.z
    )
end

---Offset used to hang the ped below the pulley at a given travel angle.
---@param angle number degrees
---@param heading number
---@return vector3
function ZiplineShared.getHangOffset(angle, heading)
    local angleRad = rad(angle)
    local angleCos, angleSin = cos(angleRad), sin(angleRad)

    return ZiplineShared.rotateVector(
        vec3(0.05, -0.4 * angleCos + 0.93 * angleSin, -0.4 * angleSin - 0.93 * angleCos),
        heading
    )
end

---@param coords vector3
---@return boolean
function ZiplineShared.isInDisabledArea(coords)
    local areas = config.disabledAreas

    for i = 1, #areas do
        local area = areas[i]

        if #(coords - area.coords) < area.radius then
            return true
        end
    end

    return false
end

---@param progress number
---@return number
function ZiplineShared.clampProgress(progress)
    return min(progress, 1.0)
end

return ZiplineShared
