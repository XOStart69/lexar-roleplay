local config = localmodule 'config.shared'

local Util = {}

local mathMax, mathMin, mathRad, mathSin, mathCos, mathCeil = math.max, math.min, math.rad, math.sin, math.cos, math.ceil

function Util.Clamp(value, min, max)
    return mathMax(min, mathMin(max, value))
end

function Util.Forward(heading)
    local rad = mathRad(heading)
    return vec3(-mathSin(rad), mathCos(rad), 0.0)
end

function Util.Right(heading)
    local rad = mathRad(heading)
    return vec3(mathCos(rad), mathSin(rad), 0.0)
end

function Util.Direction(rotation)
    local pitchRad = mathRad(rotation.x)
    return Util.Forward(rotation.z) * mathCos(pitchRad) + vec3(0.0, 0.0, mathSin(pitchRad))
end

function Util.Dot(a, b)
    return (a.x * b.x) + (a.y * b.y) + (a.z * b.z)
end

function Util.Lerp(a, b, t)
    return a + (b - a) * t
end

function Util.Ease(t)
    t = Util.Clamp(t, 0.0, 1.0)
    return (t * t) * 3.0 - 2.0 * t
end

function Util.Ray(from, to, ignoreEntity, flags)
    if #(to - from) < 1.0e-4 then
        return false, to, vec3(0.0, 0.0, 1.0), 0
    end

    flags = flags or config.traversal.probeFlags
    ignoreEntity = ignoreEntity or 0

    local handle = StartExpensiveSynchronousShapeTestLosProbe(from.x, from.y, from.z, to.x, to.y, to.z, flags, ignoreEntity, 4)
    local status, hit, hitCoords, surfaceNormal, entityHit = GetShapeTestResult(handle)

    if status ~= 2 then
        return true, from, vec3(0.0, 0.0, 0.0), 0
    end

    return hit == 1 or hit == true, hitCoords, surfaceNormal, entityHit
end

local bodyRadius = config.traversal.bodyRadius
local bodyOffsets = {
    vec3(0.0, 0.0, 0.0),
    vec3(bodyRadius, 0.0, 0.0),
    vec3(-bodyRadius, 0.0, 0.0),
    vec3(0.0, bodyRadius, 0.0),
    vec3(0.0, -bodyRadius, 0.0)
}

---@param coords vector3
---@param ignoreEntity number
---@param heightOffset number
---@return boolean
function Util.BodyClear(coords, ignoreEntity, heightOffset)
    local clearanceFlags = config.traversal.clearanceFlags
    local bottom = coords + vec3(0.0, 0.0, 0.12 - heightOffset)
    local top = coords + vec3(0.0, 0.0, 1.8 - heightOffset)

    for i = 1, 5 do
        local offset = bodyOffsets[i]

        if Util.Ray(bottom + offset, top + offset, ignoreEntity, clearanceFlags) then
            return false
        end

        if i > 1 and Util.Ray(coords, coords + offset, ignoreEntity, clearanceFlags) then
            return false
        end
    end

    return true
end

local pathOffsets = { 0.12, 0.9, 1.8 }

---@param from vector3
---@param to vector3
---@param ignoreEntity number
---@param heightOffset number
---@return boolean
function Util.BodyPath(from, to, ignoreEntity, heightOffset)
    local clearanceFlags = config.traversal.clearanceFlags

    for i = 1, 3 do
        local offset = vec3(0.0, 0.0, pathOffsets[i] - heightOffset)

        if Util.Ray(from + offset, to + offset, ignoreEntity, clearanceFlags) then
            return false
        end
    end

    local steps = mathMax(1, mathCeil(#(to - from) / 0.18))

    for i = 1, steps do
        if not Util.BodyClear(Util.Lerp(from, to, i / steps), ignoreEntity, heightOffset) then
            return false
        end
    end

    return true
end

function Util.Surface(coords, upOffset, downOffset, ignoreEntity)
    return Util.Ray(coords + vec3(0.0, 0.0, upOffset), coords - vec3(0.0, 0.0, downOffset), ignoreEntity)
end

return Util
