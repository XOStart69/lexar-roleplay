local ped = require "core.ped"

local forced = {}

---@return boolean
function forced.active()
    return LocalPlayer.state.forcedOutfit ~= nil
end

---@param value table?
---@return boolean
function forced.apply(value)
    value = value or LocalPlayer.state.forcedOutfit

    if not value or not ped.isFreemode(cache.ped) then return false end

    local list = value[ped.gender(cache.ped)]

    if not list then return false end

    ped.setComponents(cache.ped, list)

    return true
end

---@param entity number?
function forced.reapply(entity)
    if entity and entity ~= cache.ped then return end

    forced.apply()
end

return forced
