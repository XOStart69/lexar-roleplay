---@class ShopsServer
local shops = {}

RegisterNetEvent('sm_custom:server:area', function(key, inside)
    local source = source

    if type(key) ~= 'string' then return end

    local ped = GetPlayerPed(source)
    if ped == 0 then return end

    local targets = {}

    for _, target in ipairs(lib.getNearbyPlayers(GetEntityCoords(ped), 60.0)) do
        targets[#targets + 1] = target
    end

    modules.net.emitLatentClients('sm_custom:client:area', targets, source, key, inside == true)
end)

return shops
