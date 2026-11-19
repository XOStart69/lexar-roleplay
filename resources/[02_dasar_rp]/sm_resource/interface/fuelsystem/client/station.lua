local curNozzle
local isFueling = false
local allowedFueling = false
local chargerProps = {}

local config = localmodule 'config.station'
local fuelConsum = localmodule 'config.consum'

local blipModule = require 'modules.blipHandle.client'

local function clearNozzle()
    local rope = curNozzle?.rope
    local entity = curNozzle?.entity

    if entity and DoesEntityExist(entity) then
        pcall(DeleteEntity, entity)
    end

    if rope and DoesRopeExist(rope) then
        pcall(DeleteRope, rope)
    end

    curNozzle = nil
end

local function isOldModel(model)
    return array.findIndex(config.pump_props_old, function (pmodel)
        return joaat(pmodel) == model
    end)
end

local function isElectric(vehicle)
    local vehmodel = GetEntityModel(vehicle)
    return array.findIndex(fuelConsum.electric_vehicle, function (model)
        return joaat(model) == vehmodel
    end)
end

local function blacklist(vehicle)
    local vehmodel = GetEntityModel(vehicle)
    return array.findIndex(fuelConsum.noFuelUsage, function (model)
        return joaat(model) == vehmodel
    end)
end

local function allowedVehicle(stationid, vehicle)
    local station = stationid and array.find(config.location, function (data)
        return data.id == stationid and data.vehicles
    end)

    if not station then
        return true
    end

    local vehmodel = GetEntityModel(vehicle)

    return array.findIndex(station.vehicles, function (model)
        return joaat(model) == vehmodel
    end) and true or false
end

local function playGrabAnim()
    lib.playAnim(cache.ped, "anim@am_hold_up@male", "shoplift_high", 2.0, 8.0, -1, 50, 0, 0, 0, 0)
    TriggerServerEvent("InteractSound_SV:PlayOnSource", "pickupnozzle", 0.4)
    Wait(300)
    StopAnimTask(cache.ped, "anim@am_hold_up@male", "shoplift_high", 1.0)
end

local function grabNozzle(pump, ntype)

    clearNozzle()

    local coords = GetEntityCoords(cache.ped)
    local nozzledata = config.nozzle[ntype]

    if not nozzledata or not safecall.fun(lib.requestModel, nozzledata.model, 1500) then
        return lib.notify({
            description = 'Tidak bisa mengambil nozel, harap laporkan masalah ini kepada developer.',
            type = 'error'
        })
    end

    local open = lib.callback.await(
        'fuelsystem:station_status', 500, playerState.fuel_station_id
    )

    if not open then
        return lib.notify({
            description = 'Pom bensin ini sedang tutup!',
            type = 'error'
        })
    end

    playGrabAnim()
    local nozzle = CreateObject(nozzledata.model, coords.x, coords.y, coords.z, true, true, false)

    local x, y, z = table.unpack(nozzledata.pos)
    local rx, ry, rz = table.unpack(nozzledata.rot)
    local handBone = GetPedBoneIndex(cache.ped, nozzledata.bone)
    AttachEntityToEntity(nozzle, cache.ped, handBone, x, y, z, rx, ry, rz, false, true, false, true, false, true, false, false)

    local pumpModel = GetEntityModel(pump)
    local pumpCoords = GetEntityCoords(pump)
    local ropedata = nozzledata.rope

    RopeLoadTextures()
    while not RopeAreTexturesLoaded() do
        Wait(0)
        RopeLoadTextures()
    end

    local rope = AddRope(pumpCoords.x, pumpCoords.y, pumpCoords.z, 0.0, 0.0, 0.0, ropedata.length, ropedata.type, 1000.0, 0.0, 1.0, false, false, false, 1.0, true)

    Wait(200)
    ActivatePhysics(rope)
    Wait(100)

    local offset = vec(0.0, -0.033, -0.195)

    if ntype == 'electric' then
        offset = vec(-0.005, 0.185, -0.05)
    end

    local nozzlePos = GetOffsetFromEntityInWorldCoords(nozzle, offset.x, offset.y, offset.z)

    local adjustedCoords = pumpCoords

    if isOldModel(pumpModel) or pumpModel == joaat('electric_charger') then
        adjustedCoords = vec3(pumpCoords.x, pumpCoords.y, pumpCoords.z - 1.0)
    end

    AttachEntitiesToRope(
        rope,
        pump,
        nozzle,
        adjustedCoords.x, adjustedCoords.y, adjustedCoords.z + 2.25,
        nozzlePos.x, nozzlePos.y, nozzlePos.z,
        5.0, false, false, nil, nil
    )

    curNozzle = {
        type = ntype,
        entity = nozzle,
        rope = rope
    }
end

---@param electric boolean
---@return boolean shouldRestart
local function handleCancellation(electric)
    
    local header = electric and 'Pengisian Daya Dibatalkan'
        or 'Pengisian Bahan Bakar Dibatalkan'

    local content = electric
        and 'Pengisian daya dihentikan sebelum selesai. Mau lanjutkan lagi?'
        or 'Pengisian bahan bakar dihentikan sebelum selesai. Mau lanjutkan lagi?'

    local confirmLabel = electric and 'Lanjutkan Pengisian Daya'
        or 'Lanjutkan Pengisian'

    local cancelLabel = 'Tidak'

    local alert = lib.alertDialog({
        header = header,
        content = content,
        centered = true,
        cancel = true,
        labels = {
            confirm = confirmLabel,
            cancel = cancelLabel
        }
    })

    return alert == 'confirm'
end

local function refuelFromJerrycan(slot, jerrycanFuelAmount)
    local petrolCanFuel = tonumber(jerrycanFuelAmount) or 0
    local vehicle = lib.getClosestVehicle(RHDCache.coords.xyz, 3.0, false)

    if not vehicle then
        return lib.notify({
            description = 'Tidak ada kendaraan',
            type = 'error'
        })
    end

    if isElectric(vehicle) then
        return lib.notify({
            description = 'Kendaraan ini tidak bisa diisi bahan bakar',
            type = 'error'
        })
    end

    if not petrolCanFuel then return end

    local currentFuel = sm_fuel.get(vehicle)

    if currentFuel > 90 then
        return lib.notify({
            description = 'Bahan bakar kendaraan masih penuh',
            type = 'error'
        })
    end

    if petrolCanFuel < 1 then
        return lib.notify({
            description = 'Isi jerigen tidak cukup!',
            type = 'error'
        })
    end

    isFueling = true
    local duration = math.ceil((100 - currentFuel) / 0.50) * 100

    CreateThread(function()
        lib.progressCircle({
            duration = duration,
            label = 'Mengisi bahan bakar...',
            canCancel = true,
            useWhileDead = false,
            anim = {
                dict = 'weapon@w_sp_jerrycan',
                clip = 'fire'
            },
            disable = { move = true, combat = true, car = true }
        })
        isFueling = false
    end)

    while isFueling do
        if petrolCanFuel < 1 then
            isFueling = false
            break
        end

        petrolCanFuel = math.max(0, petrolCanFuel - 0.50)
        currentFuel = math.min(100, currentFuel + 0.50)

        if currentFuel >= 100 then
            isFueling = false
        end

        Wait(100)
    end

    ClearPedTasks(cache.ped)
    local success = lib.callback.await('fuelsystem:updatePetrolcan', 500, {slot, petrolCanFuel})

    if not success then return end
    sm_fuel.set(vehicle, currentFuel)
end

local function startRefuel(vehicle, fuelAmount, electric)
    ::restart::

    local startFuel = sm_fuel.get(vehicle)
    local targetFuel = math.min(100, startFuel + fuelAmount)

    local fuelToAdd = targetFuel - startFuel
    local duration = fuelToAdd * 200 -- 0.50 per 100ms = 5 per detik = 1 fuel = 200ms

    local startTime = GetGameTimer()
    local cancelled = false
    isFueling = true

    lib.playAnim(cache.ped, 'timetable@gardener@filling_can', 'gar_ig_5_filling_can', 1.0, 1.0, -1, 9, 1.0, false, false, false)

    CreateThread(function()
        if not lib.progressBar({
            duration = duration,
            label = electric and 'Mengisi daya...' or 'Mengisi bahan bakar...',
            useWhileDead = false,
            canCancel = true,
            disable = {
                move = true,
                car = true,
                combat = true
            },
        }) then
            cancelled = true
        end

        isFueling = false
    end)

    while isFueling do
        local elapsed = GetGameTimer() - startTime
        local progress = math.min(elapsed / duration, 1.0)

        local currentFuel = startFuel + (fuelToAdd * progress)
        sm_fuel.set(vehicle, currentFuel)

        Wait(0)
    end

    local finalFuel = sm_fuel.get(vehicle)

    if cancelled and finalFuel < targetFuel then
        if handleCancellation(electric) then
            fuelAmount = targetFuel - finalFuel
            goto restart
        end
    end

    ClearPedTasks(cache.ped)
    sm_fuel.set(vehicle, cancelled and finalFuel or targetFuel)
end

local function menuPengisian(vehicle)
    if not (vehicle and DoesEntityExist(vehicle)) then
        return
    end

    if not allowedVehicle(playerState.fuel_station_id, vehicle) then
        return lib.notify({
            description = 'Kendaraan ini tidak diizinkan mengisi di pom ini.',
            type = 'error'
        })
    end

    local electric = isElectric(vehicle)
    local title = electric and 'Charger Station' or 'Fuel Station'

    local vehFuel = sm_fuel.get(vehicle)
    local refuelAmount = math.floor(100 - vehFuel)

    if refuelAmount < 1 then
        local fuelType = electric and 'Daya' or 'Bahan bakar'
        return lib.notify({
            description = fuelType .. ' kendaraan masih penuh.',
            type = 'error'
        })
    end

    local input = lib.inputDialog(title, {
        {
            type = 'slider',
            max = refuelAmount,
            step = 1,
            label = 'Mau isi berapa ' .. (electric and 'Kwh' or 'Liter'),
            default = refuelAmount
        },
        {
            type = 'select',
            options = {
                { value = 'bank', label = 'Bank' },
                { value = 'cash', label = 'Cash' }
            },
            default = 'bank',
            searchable = true
        }
    })

    if not input then return end

    local fuelAmount = input[1]
    local paymentType = input[2]

    local pricePerUnit = lib.callback.await('fuelsystem:getPrice', 500, {
        playerState.fuel_station_id,
        electric and 'charger' or 'refuel'
    })

    if not tonumber(pricePerUnit) then
        return lib.notify({
            description = 'Gagal mengambil harga, coba lagi.',
            type = 'error'
        })
    end

    local unit = electric and 'Kwh' or 'Liter'
    local totalPrice = math.floor(pricePerUnit * fuelAmount)

    local alert = lib.alertDialog({
        header = 'Konfirmasi Pengisian',
        content = ('**Jumlah**: %s %s\n**Pembayaran**: %s\n**Total Harga**: $%s'):format(
            fuelAmount, unit,
            paymentType == 'bank' and 'Bank' or 'Cash',
            lib.math.groupdigits(totalPrice, ',')
        ),
        centered = true,
        cancel = true
    })

    if alert ~= 'confirm' then
        return
    end

    local refuelSuccess = lib.callback.await(
        'fuelsystem:success', 500, {
            playerState.fuel_station_id, paymentType, fuelAmount, electric
        }
    )

    if not refuelSuccess then
        return
    end

    startRefuel(vehicle, fuelAmount, electric)
end

local function isAircraft(vehicle)
    local class = GetVehicleClass(vehicle)
    return class == 15 or class == 16
end

local function aircraftRefuel(zone)
    local vehicle = cache.vehicle

    if not (vehicle and cache.seat == -1 and isAircraft(vehicle)) then
        if zone.aircraftUI then
            zone.aircraftUI = false
            infoUI.remove('fuelsystem:aircraft')
        end
        return
    end

    if not zone.aircraftUI then
        infoUI.show({
            id = 'fuelsystem:aircraft',
            title = 'Fuel Station',
            icon = 'fas fa-plane',
            description = 'Tekan [kbd]E[/kbd] untuk mengisi bahan bakar'
        })
        zone.aircraftUI = true
    end

    DisableControlAction(0, 38, true)

    if IsDisabledControlJustPressed(0, 38) and not isFueling and allowedFueling then
        menuPengisian(vehicle)
    end
end

CreateThread(function()
    local sleep

    local desc1 = [[
Tekan [kbd]E[/kbd] untuk mengisi %s
    ]]

    local desc2 = [[
Dekati kendaraan untuk mengisi %s
    ]]

    local info = {
        id = 'gas_station:refuel',
        title = 'Station',
    }

    while true do
        sleep = 1000

        if curNozzle and safecall.fun(DoesEntityExist, curNozzle?.entity) then
            local vehicle = lib.getClosestVehicle(RHDCache.coords.xyz, 2.5)

            local isCharger = curNozzle.type == 'electric'
            info.icon = isCharger and 'fas fa-bolt' or 'fas fa-gas-pump'

            local infodesc1 = desc1:format(isCharger and 'daya' or 'bahan bakar')
            local infodesc2 = desc2:format(isCharger and 'daya' or 'bahan bakar')

            if vehicle and not blacklist(vehicle) then
                if GetPedInVehicleSeat(vehicle, -1) ~= 0 then
                    info.description = 'Tidak bisa mengisi kendaraan\n yang sedang dikendarai oleh orang'
                else
                    sleep = 25
                    info.description = infodesc1

                    DisableControlAction(0, 38, true)

                    if IsDisabledControlJustPressed(0, 38) then
                        local allowed = true

                        if isCharger and not isElectric(vehicle) then
                            lib.notify({
                                description = 'Ini bukan kendaraan listrik.',
                                type = 'error'
                            })
                            allowed = false
                        elseif not isCharger and isElectric(vehicle) then
                            lib.notify({
                                description = 'Kendaraan ini tidak bisa diisi bahan bakar',
                                type = 'error'
                            })
                            allowed = false
                        end

                        if allowed then
                            menuPengisian(vehicle)
                        end
                    end
                end
            else
                info.description = infodesc2
            end

            infoUI.show(info)
        elseif not curNozzle then
            infoUI.remove('gas_station:refuel')
        end

        if cache.vehicle and curNozzle then
            clearNozzle()
        end

        Wait(sleep)
    end
end)

CreateThread(function()
    ox_target:addModel(array.merge(config.pump_props, config.pump_props_old), {
        {
            label = 'Ambil Nozel',
            icon = 'fas fa-hand-rock',
            distance = 2.5,
            onSelect = function (data)
                grabNozzle(data.entity, 'fuel')
            end,
            canInteract = function ()
                return playerState.fuel_station_id and
                curNozzle?.type ~= 'fuel' and
                not cache.vehicle and
                not isFueling and
                allowedFueling
            end
        },
        {
            label = 'Taruh Nozel',
            icon = 'fas fa-hand',
            distance = 2.5,
            onSelect = function ()
                clearNozzle()
            end,
            canInteract = function ()
                return playerState.fuel_station_id and
                curNozzle?.type == 'fuel' and
                not cache.vehicle and
                not isFueling and
                allowedFueling
            end
        },
        {
            label = 'Beli Jerigen',
            icon = 'fas fa-oil-can',
            distance = 2.5,
            onSelect = function ()
                TriggerTokenEvent('fuelsystem:beliJerigen', playerState.fuel_station_id)
            end,
            canInteract = function ()
                return playerState.fuel_station_id and
                curNozzle?.type ~= 'fuel' and
                not cache.vehicle and
               not isFueling and
                allowedFueling
            end
        }
    })

    if not sm_fuel.zones then
        sm_fuel.zones = {}
    end; if not sm_fuel.blips then
        sm_fuel.blips = {}
    end;

    playerState.fuel_station_id = nil

    array.forEach(config.location, function (station)
        local polygon = station.polygon
        -- polygon.debug = true
        local zones = lib.zones.poly(polygon)

        function zones:onEnter()
            allowedFueling = true

            if station.groups and not jobhandler.check(station.groups, station.requiredDuty) then
                allowedFueling = false
            end

            playerState.fuel_station_id = station.id
        end

        function zones:inside()
            if not playerState.fuel_station_id then return end

            if station.aircraft then
                return aircraftRefuel(self)
            end

            local stationTruck = cache.vehicle == playerState.mf_vehicle

            if stationTruck then
                local isTrailer, trailerEntity = GetVehicleTrailerVehicle(cache.vehicle)

                if not isTrailer then
                    return
                end

                if not self.infoUI then
                    infoUI.show({
                        id = 'fuelsystem:storeFuel',
                        title = 'Fuel Station',
                        icon = 'fas fa-gas-pump',
                        description = 'Tekan [kbd]E[/kbd] untuk menyelesaikan misi'
                    })
                    self.infoUI = true
                end

                if IsControlJustPressed(0, 38) and not self.busy then

                    local trailerid = safecall.fun(function ()
                        return Entity(trailerEntity).state.fuel_station
                    end)

                    local truckid = safecall.fun(function ()
                        return Entity(cache.vehicle).state.fuel_station
                    end)

                    print(trailerid, station.id)
                    if trailerid ~= truckid then
                        return lib.notify({
                            description = 'Ini bukan trailer yang dipesan!',
                            type = 'error'
                        })
                    end

                    if trailerid ~= station.id then
                        return lib.notify({
                            description = 'Ini bukan lokasi pengiriman minyak!',
                            type = 'error'
                        })
                    end

                    if trailerEntity ~= playerState.mf_trailer then
                        return lib.notify({
                            description = 'Ini bukan trailer yang dipesan!',
                            type = 'error'
                        })
                    end

                    self.busy = true
                    TaskLeaveVehicle(cache.ped, cache.vehicle, 1)

                    repeat
                        Wait(100)
                    until not cache.vehicle

                    TriggerTokenEvent('fuelsystem:finishMission')
                end
            else
                if self.infoUI then
                    self.infoUI = false
                    infoUI.remove('fuelsystem:storeFuel')
                end
            end
        end

        function zones:onExit()
            playerState.fuel_station_id = nil
            self.busy = false

            if self.infoUI then
                self.infoUI = false
                infoUI.remove('fuelsystem:storeFuel')
            end

            if self.aircraftUI then
                self.aircraftUI = false
                infoUI.remove('fuelsystem:aircraft')
            end
        end

        if station.blip ~= false and not sm_fuel.blips[station.id] then
            sm_fuel.blips[station.id] = blipModule:new({
                id = station.id,
                coords = zones.coords.xyz,
                label = 'Pom Bensin',
                sprite = 361,
                color = 0,
                scale = 0.5,
                shortRange = true
            })
        end

        if station.chargercoords and safecall.fun(lib.requestModel, 'electric_charger') then
            local prop =  CreateObject('electric_charger', station.chargercoords.x, station.chargercoords.y, station.chargercoords.z, false, true, true)
            SetEntityHeading(prop, (station.chargercoords.w or 0.0) - 180)
            FreezeEntityPosition(prop, true)
            PlaceObjectOnGroundProperly(prop)

            ox_target:addLocalEntity(prop, {
                {
                    label = 'Ambil Nozel',
                    icon = 'fas fa-hand-rock',
                    distance = 2.5,
                    onSelect = function (data)
                        grabNozzle(data.entity, 'electric')
                    end,
                    canInteract = function ()
                        return playerState.fuel_station_id and
                        curNozzle?.type ~= 'electric' and
                        not cache.vehicle and
                        not isFueling and allowedFueling
                    end
                },
                {
                    label = 'Taruh Nozel',
                    icon = 'fas fa-hand',
                    distance = 2.5,
                    onSelect = function ()
                        clearNozzle()
                    end,
                    canInteract = function ()
                        return playerState.fuel_station_id and
                        curNozzle?.type == 'electric' and
                        not cache.vehicle and
                        not isFueling and allowedFueling
                    end
                },
            })

            chargerProps[#chargerProps+1] = prop
        end

        sm_fuel.zones[station.id] = zones
    end)
end)

RegisterNetEvent('fuelsystem:getStationId', function ()
    if source == '' then return end

    local stationId = playerState.fuel_station_id

    lib.notify({
        description = 'ID Pom Bensin: ' .. (stationId or 'Tidak berada di pom bensin manapun'),
        type = stationId and 'success' or 'error'
    })

    if stationId then
        lib.setClipboard(stationId)
    end
end)

RegisterNetEvent('fuelsystem:usePetrolcan', function(data)
    if source == '' then return end

    refuelFromJerrycan(data.slot, data.fuel)
end)

AddEventHandler('QBCore:Client:OnJobUpdate', function (job)
    local stationId = playerState.fuel_station_id

    if not stationId then
        return
    end

    local station = array.find(config.location, function (station)
        return station.id == stationId
    end)

    if not station then
        return
    end

    Wait(500)
    if station.groups then
        allowedFueling = jobhandler.check(station.groups, station.requiredDuty)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then

        local rope = curNozzle?.rope
        local entity = curNozzle?.entity

        if entity and DoesEntityExist(entity) then
            pcall(DeleteEntity, entity)
        end

        if rope and DoesRopeExist(rope) then
            pcall(DeleteRope, rope)
        end

        for i=1, #chargerProps do
            pcall(DeleteEntity, chargerProps[i])
        end
    end
end)

---cdn fuel metadata
if LocalPlayer.state['isLoggedIn'] then
    ox_inventory:displayMetadata({
        cdn_fuel = "Fuel",
    })
end
AddEventHandler("QBCore:Client:OnPlayerLoaded", function()
    if GetResourceState('ox_inventory'):match("start") then
        ox_inventory:displayMetadata({
            cdn_fuel = "Fuel",
        })
    end
end)