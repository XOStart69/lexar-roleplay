local Entity = Entity

RegisterNetEvent('ox_target:setEntityHasOptions', function(netId)
    local entity = NetworkGetEntityFromNetworkId(netId)

    if entity == 0 or not DoesEntityExist(entity) then return end

    Entity(entity).state.hasTargetOptions = true
end)

RegisterNetEvent('ox_target:toggleEntityDoor', function(netId, door)
    if type(netId) ~= 'number' or type(door) ~= 'number' then return end
    if door < 0 or door > 5 then return end

    local entity = NetworkGetEntityFromNetworkId(netId)

    if entity == 0 or not DoesEntityExist(entity) then return end

    local source = source

    for _, raw in ipairs(GetPlayers()) do
        local target = tonumber(raw)

        if target and target ~= source then
            TriggerClientEvent('ox_target:toggleEntityDoor', target, netId, door)
        end
    end
end)

lib.print.info('ox_target server siap')
