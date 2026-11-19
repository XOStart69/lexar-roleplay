RegisterCommand('vehdata', function(source, _, args)
    local model = args[1]

    if not model then return end

    local hash = joaat(model)

    print(('%s -> hash %s | class %s'):format(model, hash, GetVehicleClassFromName(hash)))

    if source ~= 0 then
        TriggerClientEvent('rhd_vehicleshops_getVehicleData', source, model)
    end
end, false)
