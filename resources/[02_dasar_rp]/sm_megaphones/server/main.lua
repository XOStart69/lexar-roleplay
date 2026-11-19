local function broadcast(event, except, id)
    for _, raw in ipairs(GetPlayers()) do
        local target = tonumber(raw)

        if target and target ~= except then
            TriggerClientEvent(event, target, id)
        end
    end
end

RegisterNetEvent('sm_megaphones:server:addsubmix', function(id)
    local source = source

    id = tonumber(id) or source

    broadcast('sm_megaphones:client:addsubmix', source, id)
end)

RegisterNetEvent('sm_megaphones:server:removesubmix', function(id)
    local source = source

    id = tonumber(id) or source

    broadcast('sm_megaphones:client:removesubmix', source, id)
end)

AddEventHandler('playerDropped', function()
    broadcast('sm_megaphones:client:removesubmix', source, source)
end)

lib.print.info('sm_megaphones server siap')
