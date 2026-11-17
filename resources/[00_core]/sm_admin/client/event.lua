RegisterNetEvent('sm_admin:heal', function()
    if source ~= 65535 then return end
    SetEntityHealth(cache.ped, GetPedMaxHealth(cache.ped))
end)

RegisterNetEvent('sm_admin:maxperformance', function()
    if source ~= 65535 then return end

    require 'modules.action'.maxperformance({ action = 'maxperformance', type = 'admin' })
end)

RegisterNetEvent('sm_admin:meledak', function()
    if source ~= 65535 then return end

    local coords = GetEntityCoords(cache.ped)
    AddExplosion(coords.x, coords.y, coords.z, 4, 5.0, true, false, 1.0)
end)

RegisterNetEvent('sm_admin:terbang', function()
    if source ~= 65535 then return end

    local coords = GetEntityCoords(cache.ped)
    SetEntityCoords(cache.ped, coords.x, coords.y, coords.z + 1900.0, false, false, false, false)

    -- ApplyForceToEntity(cache.ped, 1, 0.0, 0.0, 500.0, 0.0, 0.0, 0.0, 0, false, true, true, true, true)

    local chute = `GADGET_PARACHUTE`
    SetPlayerParachuteTintIndex(cache.playerId, -1)
    GiveWeaponToPed(cache.ped, chute, 0, true, false)
    SetPedGadget(cache.ped, chute, true)
end)


lib.callback.register('sm_admin:getAppearance', function ()
    return exports['illenium-appearance']:getPedAppearance(cache.ped)
end)

RegisterNetEvent('sm_admin:applyAppearance', function (appearance)
    if source ~= 65535 then return end
    if not appearance then return end

    exports['illenium-appearance']:setPlayerAppearance(appearance)
end)

lib.callback.register('sm_admin:setPlayerModel', function (model)
    if not qbLib.safecall(lib.requestModel, model, 1500) then
        return false
    end

    SetPlayerModel(cache.playerId, model)
    SetPedDefaultComponentVariation(cache.ped)
    SetModelAsNoLongerNeeded(model)

    return true
end)

lib.callback.register('sm_admin:getVehicleProps', function()
    if not cache.vehicle then
        return lib.notify({
            description = 'Kamu harus menaiki kendaraan',
            type = 'error'
        })
    end

    local netId = NetworkGetNetworkIdFromEntity(cache.vehicle)
    local vehProps = lib.getVehicleProperties(cache.vehicle)

    if not netId then
        NetworkRegisterEntityAsNetworked(cache.vehicle)
        netId = NetworkGetNetworkIdFromEntity(cache.vehicle)
        NetworkUseHighPrecisionBlending(netId, false)
        SetNetworkIdExistsOnAllMachines(netId, true)
        SetNetworkIdCanMigrate(netId, true)
    end
            
    NetworkRequestControlOfEntity(cache.vehicle)
    return vehProps, netId
end)

lib.callback.register('sm_admin:getMaxupgradeProps', function (model)
    if not IsModelInCdimage(model) then return {} end

    lib.requestModel(model, 1500)
    local x, y, z = table.unpack(GetEntityCoords(cache.ped))
    local vehicle = CreateVehicle(model, x, y, z, 0.0, false, false)

    FreezeEntityPosition(vehicle, true)
    SetEntityCollision(vehicle, false, false)
    SetEntityCompletelyDisableCollision(vehicle, false, false)
    SetEntityVisible(vehicle, false, false)

    
    local max
    local Mod = { 11, 12, 13, 15, 16 }

    if DoesEntityExist(vehicle) and IsEntityAVehicle(vehicle) then
        SetVehicleModKit(vehicle, 0)

        for _, modType in ipairs(Mod) do
            max = GetNumVehicleMods(vehicle, tonumber(modType) --[[@as number]]) - 1
            SetVehicleMod(vehicle, modType, max, false)
        end

        ToggleVehicleMod(vehicle, 18, true) -- Turbo
    end

    local props = lib.getVehicleProperties(vehicle)

    Wait(0)
    pcall(DeleteEntity, vehicle)

    return props
end)