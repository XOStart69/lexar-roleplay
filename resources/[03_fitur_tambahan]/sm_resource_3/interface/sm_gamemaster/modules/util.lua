local sqrt = math.sqrt
local exp = math.exp
local max = math.max
local min = math.min
local GetGroundZFor_3dCoord = GetGroundZFor_3dCoord
local GetHeadingFromVector_2d = GetHeadingFromVector_2d
local GetEntityCoords = GetEntityCoords
local GetEntityHealth = GetEntityHealth
local GetEntityMaxHealth = GetEntityMaxHealth

local util = {}

---@param value number
---@param low number
---@param high number
---@return number
function util.clamp(value, low, high)
    if value < low then return low end
    if value > high then return high end

    return value
end

---@param value number
---@return number
function util.wrap360(value)
    local result = value % 360.0

    if result < 0.0 then
        result = result + 360.0
    end

    return result
end

---@param current number
---@param target number
---@param velocity number
---@param smoothTime number
---@param maxSpeed number
---@param dt number
---@return number, number
function util.smoothDamp(current, target, velocity, smoothTime, maxSpeed, dt)
    local time = max(0.0001, smoothTime)
    local omega = 2.0 / time
    local x = omega * dt
    local factor = 1.0 / (1.0 + x + 0.48 * x * x + 0.235 * x * x * x)
    local maxChange = maxSpeed * time
    local change = util.clamp(current - target, -maxChange, maxChange)
    local goal = current - change
    local temp = (velocity + omega * change) * dt
    local nextVelocity = (velocity - omega * temp) * factor
    local output = goal + (change + temp) * factor

    if (target - current > 0.0) == (output > target) then
        output = target
        nextVelocity = 0.0
    end

    return output, nextVelocity
end

---@param remaining number
---@param smoothing number
---@param dt number
---@return number
function util.expStep(remaining, smoothing, dt)
    local factor = util.clamp(1.0 - exp(-smoothing * dt), 0.0, 1.0)

    return remaining * factor
end

---@param t number
---@return number
function util.smootherStep(t)
    if t <= 0.0 then return 0.0 end
    if t >= 1.0 then return 1.0 end

    return t * t * t * (t * (t * 6.0 - 15.0) + 10.0)
end

---@param a number
---@param b number
---@param t number
---@return number
function util.lerp(a, b, t)
    return a + (b - a) * t
end

---@param t number
---@return number
function util.easeOutCubic(t)
    local p = 1.0 - util.clamp(t, 0.0, 1.0)

    return 1.0 - p * p * p
end

---@param v vector3
---@return vector3
function util.normalize(v)
    local length = sqrt(v.x * v.x + v.y * v.y + v.z * v.z)

    if length <= 0.0000001 then return vector3(0.0, 0.0, 0.0) end

    return vector3(v.x / length, v.y / length, v.z / length)
end

---@param a vector3
---@param b vector3
---@return number
function util.dot(a, b)
    return a.x * b.x + a.y * b.y + a.z * b.z
end

---@param a vector3
---@param b vector3
---@return vector3
function util.cross(a, b)
    return vector3(a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x)
end

---@param x number
---@param y number
---@param z number
---@return number?
function util.groundZ(x, y, z)
    local found, ground = GetGroundZFor_3dCoord(x, y, z, false)

    if found then return ground end

    found, ground = GetGroundZFor_3dCoord(x, y, z + 50.0, false)

    if found then return ground end

    return nil
end

---@param coords vector3
---@return vector3
function util.toGround(coords)
    local ground = util.groundZ(coords.x, coords.y, coords.z + 1.0)

    if not ground then return coords end

    return vector3(coords.x, coords.y, ground)
end

---@param dx number
---@param dy number
---@return number
function util.headingFrom(dx, dy)
    return util.wrap360(GetHeadingFromVector_2d(dx, dy))
end

---@param entity integer
---@param target vector3
---@return number
function util.headingTo(entity, target)
    local coords = GetEntityCoords(entity)

    return util.headingFrom(target.x - coords.x, target.y - coords.y)
end

---@param entity integer
---@return integer, integer
function util.health(entity)
    local health = GetEntityHealth(entity)
    local maxHealth = GetEntityMaxHealth(entity)

    if maxHealth <= 0 or health > maxHealth then
        maxHealth = max(100, health)
    end

    return min(health, maxHealth), maxHealth
end

---@param center vector3
---@param count integer
---@param spacing number
---@return vector3[]
function util.formation(center, count, spacing)
    local positions = { center }

    if count <= 1 then return positions end

    local made = 1
    local ring = 1
    local offset = 2.399963229728653
    local tau = math.pi * 2.0
    local cos = math.cos
    local sin = math.sin

    while made < count do
        local points = 6 * ring
        local radius = spacing * ring

        for i = 0, points - 1 do
            local a = (i / points) * tau + offset
            local x = center.x + cos(a) * radius
            local y = center.y + sin(a) * radius
            local ground = util.groundZ(x, y, center.z + 2.0)

            made += 1
            positions[made] = vector3(x, y, ground and ground + 0.05 or center.z)

            if made >= count then break end
        end

        ring += 1
    end

    return positions
end

return util
