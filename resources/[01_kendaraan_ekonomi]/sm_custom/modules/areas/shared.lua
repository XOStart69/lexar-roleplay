---@class CustomArea
---@field points vector3[]
---@field thickness number

local Z_TOLERANCE <const> = 1.0

---@class AreasShared
local area = {
    MAX_POINTS = 32,
    MIN_HEIGHT = 1.0,
    MAX_HEIGHT = 50.0,
}

---@param points vector3[]
---@return number
function area.level(points)
    local sum = 0.0

    for _, point in ipairs(points) do
        sum += point.z
    end

    return sum / math.max(#points, 1)
end

---@param points vector3[]
---@return vector3[]
function area.flatten(points)
    local z, result = area.level(points), {}

    for i, point in ipairs(points) do
        result[i] = vec3(point.x, point.y, z)
    end

    return result
end

---@param ring vector3[]
---@param height number
---@return vector3[][]
function area.prism(ring, height)
    local offset = vec3(0.0, 0.0, height / 2)
    local count = #ring
    local segments = {}

    for i, point in ipairs(ring) do
        local bottom, top = point - offset, point + offset
        local following = count > 2 and ring[i % count + 1] or ring[i + 1]

        segments[#segments + 1] = { bottom, top }

        if following then
            segments[#segments + 1] = { bottom, following - offset }
            segments[#segments + 1] = { top, following + offset }
        end
    end

    return segments
end

---@param points vector3[]
---@param x number
---@param y number
---@return boolean
local function inside(points, x, y)
    local result, previous = false, points[#points]

    for _, current in ipairs(points) do
        local crosses = (current.y > y) ~= (previous.y > y)

        if crosses and x < (previous.x - current.x) * (y - current.y) / (previous.y - current.y) + current.x then
            result = not result
        end

        previous = current
    end

    return result
end

---@param a vector3
---@param b vector3
---@param x number
---@param y number
---@return number
local function gap(a, b, x, y)
    local dx, dy = b.x - a.x, b.y - a.y
    local length = dx * dx + dy * dy
    local t = length > 0 and math.min(math.max(((x - a.x) * dx + (y - a.y) * dy) / length, 0.0), 1.0) or 0.0
    local px, py = a.x + dx * t - x, a.y + dy * t - y

    return math.sqrt(px * px + py * py)
end

---@param shape CustomArea
---@param coords vector3
---@param margin? number
---@return boolean
function area.contains(shape, coords, margin)
    local points, slack = shape.points, margin or 0.0
    if #points < 3 then return false end
    if math.abs(coords.z - area.level(points)) > shape.thickness / 2 + Z_TOLERANCE + slack then return false end
    if inside(points, coords.x, coords.y) then return true end
    if slack <= 0.0 then return false end

    local previous = points[#points]

    for _, current in ipairs(points) do
        if gap(previous, current, coords.x, coords.y) <= slack then return true end

        previous = current
    end

    return false
end

return area
