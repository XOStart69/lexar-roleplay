local Search = {}

local active = {}
local searchedBy = {}

---@param source number
---@return boolean
function Search.canSearch(source)
    return active[source] == nil
end

---@param source number
---@param target number
---@return boolean
function Search.isTargetVulnerable(source, target)
    if not target or target == source then return false end

    local ped = GetPlayerPed(source)
    local targetPed = GetPlayerPed(target)

    if ped == 0 or targetPed == 0 then return false end
    if searchedBy[target] and searchedBy[target] ~= source then return false end

    local limit = (Config.SearchDistance or 3.0) + 0.5

    return #(GetEntityCoords(ped) - GetEntityCoords(targetPed)) <= limit
end

---@param source number
---@param target number?
function Search.setActive(source, target)
    local previous = active[source]

    if previous and searchedBy[previous] == source then searchedBy[previous] = nil end

    active[source] = target

    if target then searchedBy[target] = source end
end

AddEventHandler('playerDropped', function()
    Search.setActive(source, nil)
end)

return Search