---@class InstallServer
local install = {}

local shared = modules.install

---@param patch table
---@return string[]
function install.keys(patch)
    return shared.keys(patch)
end

---@param name string
---@return string
function install.area(name)
    return shared.area(name)
end

---@return table<integer, true>
function install.models()
    return shared.models()
end

RegisterNetEvent('sm_custom:server:orderProp', function(netId)
    if type(netId) ~= 'number' then return end

    TriggerClientEvent('sm_custom:client:orderProp', -1, netId, source)
end)

return install
