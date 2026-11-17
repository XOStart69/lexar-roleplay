---@class VehicleCache
---@field private cache table
local VehicleCache = lib.class('VehicleCache')

function VehicleCache:constructor()
    self.cache = {}
end

---@param key string
---@param value any
---@return boolean success
function VehicleCache:set(key, value)
    if not key then return false end

    self.cache[key] = value
    return true
end

---@param key string
---@return any value
function VehicleCache:get(key)
    return self.cache[key]
end

---@return number count
function VehicleCache:clear()
    local count = 0
    for _ in pairs(self.cache) do
        count = count + 1
    end

    self.cache = {}
    return count
end

return VehicleCache
