---@class ZonesServer
local zones = {}

local shared = modules.zones

RegisterNetEvent('sm_custom:server:zones', function()
    TriggerClientEvent('sm_custom:client:zones', source, shared.encode(shared.data))
end)

---@return table<string, table>
function zones.data()
    return shared.data
end

return zones
