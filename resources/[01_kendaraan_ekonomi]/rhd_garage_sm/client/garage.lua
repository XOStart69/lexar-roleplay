local garage = {}

function garage.prepareVehicles()
    local vehicles = lib.cblt.await(
        'rhd_garage:server:fetchGarageVehicles',
        500
    )

    if not vehicles or type(vehicles) ~= 'table' then return {} end

    local zoneId = PlayerState?.rhd_garage_zoneId
    local garage_data = ClientLocations.getGarages(zoneId)?.garageData
    if not garage_data then return {} end

    ---@cast garage_data GarageData

    local filtered = {}
    local filterIndex = 1

    for i=1, #vehicles do
        local vehicle = vehicles[i]
        local model = vehicle.model

        if not vehicle.name or vehicle.name == 'Unknown' or tonumber(vehicle.name) then
            local hash = type(model) == 'string' and joaat(model) or model
            local displayName = GetDisplayNameFromVehicleModel(hash)
            local label = GetLabelText(displayName)

            if label and label ~= 'NULL' then
                vehicle.name = label
            elseif displayName and displayName ~= 'CARNOTFOUND' then
                vehicle.name = displayName
            end
        end

        vehicle.class = GetVehicleClassFromName(model)

        local garage_class = garage_data.vehicle_class or 'all'
        local validClass = utils.convertClass(garage_class)

        if lib.array.includes(validClass, vehicle.class) then
            filtered[filterIndex] = vehicle
            filterIndex = filterIndex + 1
        end
    end

    return filtered
end

---@param garageId GarageId
---@param garageData GarageData
function garage.openGarage(garageId, garageData)
    SendNUIMessage({
        action = 'openGarage',
        data = {
            name = garageId,
            garageIcon = garageData.garageIcon or 'warehouse',
        }
    })
    SetNuiFocus(true, true)
end

function garage.storeVehicle(self, vehicle, isAutoStore)
    if self.garageData.category == 'depot' then
        self.busy = false return
    end

    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
        self.busy = false return
    end

    local class = GetVehicleClass(vehicle)
    local garage_class = self.garageData.vehicle_class or 'all'
    local validClass = utils.convertClass(garage_class)

    if not lib.array.includes(validClass, class) then
        self.busy = false
        return sm_core:Notify('This vehicle cannot be stored in this garage', 'error')
    end

    local state = Entity(vehicle).state
    local props = lib.getVehicleProperties(vehicle)

    if not props then
        self.busy = false
        return sm_core:Notify('Gagal membaca data kendaraan, coba lagi', 'error')
    end

    props.bodyHealth = GetVehicleBodyHealth(vehicle)
    props.engineHealth = GetVehicleEngineHealth(vehicle)
    props.fuelLevel = exports.LegacyFuel:GetFuel(vehicle)
    props.harnessDurability = state.harnessDurability

    state:set('rhd_garage_lockvehicle', true, true)
    state:set('rhd_garage_vehicleProps', props, true)
    state:set('rhd_garage_zoneId', self.garageId, true)

    if GetPedInVehicleSeat(vehicle, -1) == cache.ped then
        TaskLeaveVehicle(cache.ped, vehicle, 1)

        local timeout = GetGameTimer() + 5000
        repeat
            Wait(250)
        until not cache.vehicle or GetGameTimer() > timeout
    end

    self.busy = false

    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    TriggerTokenEvent('rhd_garage:server:store_vehicle', netId, isAutoStore, self.garageId, props)
end

function garage.toggleFavorite(plate)
    local KVP = 'rhd_garage:favorites'
    local favorites = utils.kvpGet(KVP) or {}

    if favorites[plate] then
        favorites[plate] = nil
    else
        favorites[plate] = true
    end

    utils.kvpSet(KVP, favorites)
    return favorites
end

function garage.getFavorites()
    local KVP = 'rhd_garage:favorites'
    return utils.kvpGet(KVP) or {}
end

lib.callback.register('rhd_garage:client:spawn_vehicle', function (data)
    local mods = data.mods
    local coords = data.coords

    local vehicle, err = utils.spawnCar(mods.model, coords, true)

    if not vehicle then
        local errorMsg = err or 'Failed to spawn vehicle'
        return sm_core:Notify(errorMsg, 'error')
    end

    lib.setVehicleProperties(vehicle, mods)

    if mods.harnessDurability and mods.harnessDurability > 0 then
        Entity(vehicle).state:set('harnessDurability', mods.harnessDurability, true)
    end

    CreateThread(function ()
        Wait(500)
        SetVehicleBodyHealth(vehicle --[[@as integer]], mods.bodyHealth)
        SetVehicleEngineHealth(vehicle --[[@as integer]], mods.engineHealth)
        exports.LegacyFuel:SetFuel(vehicle, mods.fuelLevel or 100)

        if mods.doors then
            for i = 1, #mods.doors do
                SetVehicleDoorBroken(vehicle, mods.doors[i], true)
            end
        end

        if mods.windows then
            for i = 1, #mods.windows do
                RemoveVehicleWindow(vehicle, mods.windows[i])
            end
        end

        if mods.tyres then
            for tyre, state in pairs(mods.tyres) do
                SetVehicleTyreBurst(vehicle, tonumber(tyre) --[[@as number]], state == 2, 1000.0)
            end
        end
    end)

    TaskWarpPedIntoVehicle(cache.ped, vehicle --[[@as integer]], -1)
    TriggerEvent('sm_vehiclekeys:client:setVehicleOwner', GetVehicleNumberPlateText(vehicle --[[@as integer]]))

    return NetworkGetNetworkIdFromEntity(vehicle --[[@as integer]])
end)

local lastVehicle = 0
local lastVehiclePlate = nil
local lastVehicleProps = nil

CreateThread(function()
    while true do
        local sleep = 2000
        if cache.vehicle and DoesEntityExist(cache.vehicle) then
            -- Cache the plate and damage properties while inside the vehicle
            -- in case it gets unexpectedly deleted (e.g. /dv)
            local plateText = GetVehicleNumberPlateText(cache.vehicle)
            if plateText then
                lastVehiclePlate = string.gsub(plateText, '^%s*(.-)%s*$', '%1')
                local fullProps = lib.getVehicleProperties(cache.vehicle)
                fullProps.bodyHealth = GetVehicleBodyHealth(cache.vehicle)
                fullProps.engineHealth = GetVehicleEngineHealth(cache.vehicle)
                fullProps.fuelLevel = exports.LegacyFuel:GetFuel(cache.vehicle)
                fullProps.harnessDurability = Entity(cache.vehicle).state.harnessDurability
                lastVehicleProps = fullProps
            end
        else
            sleep = 1000
        end
        Wait(sleep)
    end
end)

lib.onCache('vehicle', function(vehicle)
    if vehicle then
        -- Player entered a vehicle
        lastVehicle = vehicle
    elseif lastVehicle ~= 0 then
        -- Player left the vehicle or vehicle was deleted
        local veh = lastVehicle
        lastVehicle = 0

        local plate = lastVehiclePlate
        local props = nil
        
        if DoesEntityExist(veh) then
            local plateText = GetVehicleNumberPlateText(veh)
            plate = plateText and string.gsub(plateText, '^%s*(.-)%s*$', '%1') or ''
            
            props = lib.getVehicleProperties(veh)
            props.bodyHealth = GetVehicleBodyHealth(veh)
            props.engineHealth = GetVehicleEngineHealth(veh)
            props.fuelLevel = exports.LegacyFuel:GetFuel(veh)
            props.harnessDurability = Entity(veh).state.harnessDurability
        else
            props = lastVehicleProps
        end

        if plate and plate ~= '' and props then
            TriggerServerEvent('rhd_garage:server:update_vehicle_props', plate, props)
        end
        
        lastVehiclePlate = nil
        lastVehicleProps = nil
    end
end)

_ENV.Client = garage