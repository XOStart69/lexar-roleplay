RegisterNetEvent('vehiclehandler:sync', function()
    TriggerClientEvent('vehiclehandler:sync', -1)
end)

lib.callback.register('vehiclehandler:sync', function(source)
    return true
end)

lib.print.info('vehiclehandler server siap')
