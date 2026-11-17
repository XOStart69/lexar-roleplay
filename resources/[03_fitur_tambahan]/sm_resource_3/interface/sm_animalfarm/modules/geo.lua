local config = localmodule 'config'

local rad, sin, cos = math.rad, math.sin, math.cos

local geo = {}

---@param coords vector4
---@param right number
---@param forward number
---@return number x
---@return number y
function geo.offset(coords, right, forward)
    local h = rad(coords.w)
    local s, c = sin(h), cos(h)

    return coords.x + c * right - s * forward, coords.y + s * right + c * forward
end

---@param plot integer
---@param kind 'food'|'water'
---@return vector3|nil
function geo.trough(plot, kind)
    local entry = config.plots[plot]
    local trough = config.trough[kind]

    if not entry or not trough then return end

    local coords = entry.coords
    local x, y = geo.offset(coords, trough.offset.x, trough.offset.y)

    return vec3(x, y, coords.z)
end

---@param growth number
---@param weight number
---@return number
function geo.scale(growth, weight)
    local scale = config.scale
    local size = scale.baby + (scale.adult - scale.baby) * (growth / 100.0)
    local body = scale.thin + (1.0 - scale.thin) * (weight / 100.0)

    return size * body
end

---@param rule string|string[]|nil
---@param name string|nil
---@return boolean
function geo.jobAllowed(rule, name)
    if not rule then return true end
    if not name then return false end
    if type(rule) == 'string' then return rule == name end

    for i = 1, #rule do
        if rule[i] == name then return true end
    end

    return false
end

local kidSet

---@param model integer
---@return boolean
function geo.isKidModel(model)
    if not kidSet then
        kidSet = {}

        local list = config.ride.kidModels or {}

        for i = 1, #list do
            kidSet[joaat(list[i])] = true
        end
    end

    return kidSet[model] == true
end

---@param growth number
---@return 'baby'|'young'|'adult'
function geo.stage(growth)
    if growth >= 100.0 then return 'adult' end
    if growth < config.care.babyUntil then return 'baby' end

    return 'young'
end

return geo
