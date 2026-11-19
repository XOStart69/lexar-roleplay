local QBCore = exports['qb-core']:GetCoreObject()

local Items = {
    binoculars = 'binoculars:client:use',
    newscam = 'newscam:useItem',
    newsmic = 'newsmic:client:use',
    newsbmic = 'newsbmic:client:use',
}

for item, clientEvent in pairs(Items) do
    QBCore.Functions.CreateUseableItem(item, function(source)
        TriggerClientEvent(clientEvent, source)
    end)
end

exports('ToggleBinoculars', function(source)
    TriggerClientEvent('binoculars:client:use', source)
end)

exports('ToggleNewscam', function(source)
    TriggerClientEvent('newscam:useItem', source)
end)

lib.print.info('sm_emotes item siap')
