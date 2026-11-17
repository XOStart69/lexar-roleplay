if lib.context == 'client' then
    function ThermiteParticleSync(entity)
        if not entity then return end
        if not DoesEntityExist(entity) then return end

        local netId = NetworkGetEntityIsNetworked(entity) and NetworkGetNetworkIdFromEntity(entity)
        if not netId then
            NetworkRegisterEntityAsNetworked(entity)
            netId = NetworkGetNetworkIdFromEntity(entity)
            SetNetworkIdCanMigrate(netId, true)
        end

        NetworkRequestControlOfEntity(entity)
        TriggerTokenEvent('illegal_activity:thermiteParticleSync', netId)
    end

    RegisterNetEvent('illegal_activity:thermiteParticleSync', function (coords)
        if source == '' then return end
        local x, y, z = 0.04, 1.00, -0.06

        lib.requestNamedPtfxAsset('scr_ornate_heist')
        SetPtfxAssetNextCall("scr_ornate_heist")
        local effect = StartParticleFxLoopedAtCoord("scr_heist_ornate_thermal_burn", coords.x + x, coords.y + y, coords.z + z, 0.0, 0.0, 0.0, 1.0, false, false, false, false)

        Wait(18500)
        StopParticleFxLooped(effect, false)
    end)
else
    RegisterTokenEvent('illegal_activity:thermiteParticleSync', function (netId)
        local source = source
        local entity = NetworkGetEntityFromNetworkId(netId)
        Wait(500)
        if not entity or not DoesEntityExist(entity) then return end

        local playerped = GetPlayerPed(source)
        local playercoords = GetEntityCoords(playerped)

        local coords = GetEntityCoords(entity)

        local dist = #(playercoords - coords)
        if dist > 5.0 then return end

        TriggerClientEvent('illegal_activity:thermiteParticleSync', -1, coords)
    end)
end