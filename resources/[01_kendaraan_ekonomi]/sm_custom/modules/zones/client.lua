---@class ZonesShared
local zones = modules.zones

RegisterNetEvent('sm_custom:client:zones', function(data)
    if source == '' or type(data) ~= 'table' then return end

    zones.load(zones.decode(data))
end)

TriggerServerEvent('sm_custom:server:zones')

return zones
