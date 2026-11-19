RegisterNetEvent('InteractSound_SV:PlayOnOne', function(file, volume)
    TriggerClientEvent('InteractSound_CL:PlayOnOne', source, file, volume)
end)

RegisterNetEvent('InteractSound_SV:PlayOnAll', function(file, volume)
    TriggerClientEvent('InteractSound_CL:PlayOnAll', -1, file, volume)
end)
