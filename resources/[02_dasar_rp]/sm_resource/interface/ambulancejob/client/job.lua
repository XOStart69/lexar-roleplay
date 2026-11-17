local config = localmodule 'config.client'
local locations = localmodule 'data.locations'
local vehicleData = localmodule 'data.vehicles'

local function isMedicalJob(name)
    return config.medicalJobs[name] or false
end

local function setVehicleMaxPerformance(vehicle)
    SetVehicleMod(vehicle, 11, GetNumVehicleMods(vehicle, 11) - 1, false)
    SetVehicleMod(vehicle, 12, GetNumVehicleMods(vehicle, 12) - 1, false)
    SetVehicleMod(vehicle, 13, GetNumVehicleMods(vehicle, 13) - 1, false)
    SetVehicleMod(vehicle, 15, GetNumVehicleMods(vehicle, 15) - 1, false)
    SetVehicleMod(vehicle, 16, GetNumVehicleMods(vehicle, 16) - 1, false)
    ToggleVehicleMod(vehicle, 18, true)
    ToggleVehicleMod(vehicle, 20, true)
    ToggleVehicleMod(vehicle, 22, true)
end

local function applyLivery(veh, vehicleInfo, vehData)
    if vehicleInfo == 'smgsems' then
        local liveryIndex = vehData.livery > 0 and (vehData.livery - 1) or 0
        local maxLiveryMods = GetNumVehicleMods(veh, 48)

        if maxLiveryMods > 0 and liveryIndex < maxLiveryMods then
            SetVehicleMod(veh, 48, liveryIndex, false)
        end

        if vehData.livery == 0 then
            SetVehicleExtra(veh, 1, 0)
            SetVehicleExtra(veh, 2, 1)
            SetVehicleExtra(veh, 3, 1)
        elseif vehData.livery == 1 then
            SetVehicleExtra(veh, 1, 1)
            SetVehicleExtra(veh, 2, 0)
            SetVehicleExtra(veh, 3, 1)
        elseif vehData.livery == 2 then
            SetVehicleExtra(veh, 1, 1)
            SetVehicleExtra(veh, 2, 1)
            SetVehicleExtra(veh, 3, 0)
        end

        return
    end

    if not vehData.livery then return end

    local liveryCount = GetVehicleLiveryCount(veh)

    if liveryCount > 0 then
        SetVehicleLivery(veh, vehData.livery)
    end

    local maxMods = GetNumVehicleMods(veh, 48)
    if maxMods > 0 then
        local modIndex = vehData.livery > 0 and (vehData.livery - 1) or 0
        if modIndex < maxMods then
            SetVehicleMod(veh, 48, modIndex, false)
        end
    end
end

local function setupSpawnedVehicle(veh, vehicleModel, vehData, plate)
    if plate then
        SetVehicleNumberPlateText(veh, plate)
    end

    local timeout = 0
    while not DoesEntityExist(veh) and timeout < 100 do
        Wait(10)
        timeout = timeout + 1
    end

    Wait(500)

    SetVehicleModKit(veh, 0)
    Wait(200)

    if vehData.maxPerformance then
        setVehicleMaxPerformance(veh)
    end

    applyLivery(veh, vehicleModel, vehData)

    SetVehicleDirtLevel(veh, 0.0)
    exports['LegacyFuel']:SetFuel(veh, 100.0)
    TaskWarpPedIntoVehicle(cache.ped, veh, -1)
    TriggerEvent('sm_vehiclekeys:client:setVehicleOwner', GetVehicleNumberPlateText(veh))
    SetVehicleEngineOn(veh, true, true)
end

local function takeOutVehicle(vehicleModel, garageId, spawnId)
    local netId, vehData, plate = lib.callback.await('ambulance:buyVehicle', false, vehicleModel, garageId, spawnId)

    if not netId then
        return lib.notify({ description = vehData or 'Gagal membeli kendaraan', type = 'error' })
    end

    local veh = NetToVeh(netId)
    setupSpawnedVehicle(veh, vehicleModel, vehData, plate)
end

local function takeOutHelicopter(helicopterModel, garageId)
    local netId, heliData = lib.callback.await('ambulance:spawnHelicopter', false, helicopterModel, garageId)

    if not netId then
        return lib.notify({ description = heliData or 'Gagal mengambil helikopter', type = 'error' })
    end

    local veh = NetToVeh(netId)
    setupSpawnedVehicle(veh, helicopterModel, heliData, 'HELI' .. tostring(math.random(1000, 9999)))
    lib.notify({ description = 'Helikopter berhasil diambil', type = 'success' })
end

local function getAuthorizedVehicles(grade, jobName)
    local accessible = {}
    local vehConfig = vehicleData.vehicles[jobName]

    if not vehConfig then return accessible end

    for availableGrade, vehicles in pairs(vehConfig) do
        if grade >= availableGrade then
            for name, data in pairs(vehicles) do
                accessible[name] = data
            end
        end
    end

    return accessible
end

local function getAuthorizedHelicopters(grade, jobName)
    local accessible = {}
    local heliConfig = vehicleData.helicopters[jobName]

    if not heliConfig then return accessible end

    for availableGrade, helicopters in pairs(heliConfig) do
        if grade >= availableGrade then
            for name, data in pairs(helicopters) do
                accessible[name] = data
            end
        end
    end

    return accessible
end

local function storeVehicle()
    if not IsPedInAnyVehicle(cache.ped, false) then
        return lib.notify({ description = 'Anda harus berada di dalam kendaraan', type = 'error' })
    end

    DeleteEntity(GetVehiclePedIsIn(cache.ped, false))
    lib.notify({ description = 'Kendaraan berhasil disimpan', type = 'success' })
end

-- local function vehicleGarageMenu(garageId)
--     local pdata = qb_ecore:GetPlayerData()
--     local authorizedVehicles = getAuthorizedVehicles(pdata.job.grade.level, pdata.job.name)
--     local options = {}

--     for veh, vData in pairs(authorizedVehicles) do
--         local vehprice = vData.price or 0
--         local pricetext = vehprice > 0 and ('Harga: $%s'):format(vehprice) or 'Gratis'

--         options[#options + 1] = {
--             title = vData.label,
--             description = pricetext,
--             icon = 'fas fa-ambulance',
--             onSelect = function()
--                 takeOutVehicle(veh, garageId, nil)
--             end
--         }
--     end

--     if #options == 0 then
--         options[#options + 1] = {
--             title = 'Tidak Ada Kendaraan',
--             description = 'Tidak ada kendaraan yang tersedia',
--             icon = 'fas fa-times',
--             disabled = true
--         }
--     end

--     local names = config.garageNames[pdata.job.name] or config.garageNames.ambulance

--     lib.registerContext({
--         id = 'ambulance_vehicle_menu',
--         title = names.vehicle,
--         options = options
--     })
--     lib.showContext('ambulance_vehicle_menu')
-- end

local function helicopterGarageMenu(garageId)
    local pdata = qb_ecore:GetPlayerData()
    local authorizedHelicopters = getAuthorizedHelicopters(pdata.job.grade.level, pdata.job.name)
    local options = {}

    if next(authorizedHelicopters) then
        for heli, hData in pairs(authorizedHelicopters) do
            options[#options + 1] = {
                title = hData.label,
                description = 'Sewa helikopter ' .. hData.label,
                icon = 'fas fa-helicopter',
                onSelect = function()
                    takeOutHelicopter(heli, garageId)
                end
            }
        end
    else
        options[#options + 1] = {
            title = 'Akses Terbatas',
            description = 'Grade anda tidak memiliki akses ke helikopter',
            icon = 'fas fa-lock',
            disabled = true
        }
    end

    local names = config.garageNames[pdata.job.name] or config.garageNames.ambulance

    lib.registerContext({
        id = 'ambulance_helicopter_menu',
        title = names.helicopter,
        options = options
    })
    lib.showContext('ambulance_helicopter_menu')
end

-- local function vehicleStoreMenu(garageId)
--     local options = {}

--     if IsPedInAnyVehicle(cache.ped, false) then
--         options[#options + 1] = {
--             title = 'Simpan Kendaraan',
--             description = 'Simpan kendaraan yang sedang dikendarai',
--             icon = 'fas fa-parking',
--             onSelect = storeVehicle
--         }
--     else
--         options[#options + 1] = {
--             title = 'Beli Kendaraan',
--             description = 'Pilih kendaraan untuk dibeli',
--             icon = 'fas fa-cart-shopping',
--             onSelect = function()
--                 vehicleGarageMenu(garageId)
--             end
--         }
--     end

--     lib.registerContext({
--         id = 'ambulance_vehicle_store_menu',
--         title = 'Garage Ambulance',
--         options = options
--     })
--     lib.showContext('ambulance_vehicle_store_menu')
-- end

local function helicopterStoreMenu(garageId)
    local options = {}

    if IsPedInAnyVehicle(cache.ped, false) then
        options[#options + 1] = {
            title = 'Simpan Helikopter',
            description = 'Simpan helikopter yang sedang dikendarai',
            icon = 'fas fa-parking',
            onSelect = storeVehicle
        }
    else
        options[#options + 1] = {
            title = 'Sewa Helikopter',
            description = 'Sewa helikopter dari hangar',
            icon = 'fas fa-helicopter',
            onSelect = function()
                helicopterGarageMenu(garageId)
            end
        }
    end

    lib.registerContext({
        id = 'ambulance_helicopter_store_menu',
        title = 'Hangar Helikopter',
        options = options
    })
    lib.showContext('ambulance_helicopter_store_menu')
end

local function purchaseVehicleMenu(jobName, spawnIdx)
    local pdata = qb_ecore:GetPlayerData()
    local authorizedVehicles = getAuthorizedVehicles(pdata.job.grade.level, pdata.job.name)
    local options = {}

    for veh, vData in pairs(authorizedVehicles) do
        local vehprice = vData.price or 0
        local pricetext = vehprice > 0 and ('Harga: $%s'):format(vehprice) or 'Gratis'

        options[#options + 1] = {
            title = vData.label,
            description = pricetext,
            icon = 'fas fa-ambulance',
            onSelect = function()
                takeOutVehicle(veh, nil, jobName .. ':' .. spawnIdx)
            end
        }
    end

    if #options == 0 then
        options[#options + 1] = {
            title = 'Tidak Ada Kendaraan',
            description = 'Tidak ada kendaraan yang tersedia untuk grade anda',
            icon = 'fas fa-times',
            disabled = true
        }
    end

    local names = config.garageNames[pdata.job.name] or config.garageNames.ambulance

    lib.registerContext({
        id = 'ambulance_purchase_menu',
        title = 'Beli Kendaraan ' .. (names.vehicle or 'Ambulance'),
        options = options
    })
    lib.showContext('ambulance_purchase_menu')
end

local PurchasePeds = {}

CreateThread(function()
    while not qb_ecore:GetPlayerData().job do
        Wait(100)
    end

    if locations.purchasePed then
        for jobName, pedLocations in pairs(locations.purchasePed) do
            if pedLocations and pedLocations ~= false then
                for i = 1, #pedLocations do
                    local v = pedLocations[i]
                    if v.x == 0.0 and v.y == 0.0 then goto continue end

                    local pedModel = 's_m_m_paramedic_01'
                    local hash = GetHashKey(pedModel)
                    RequestModel(hash)
                    while not HasModelLoaded(hash) do Wait(10) end

                    local pedKey = jobName .. '_' .. i
                    PurchasePeds[pedKey] = CreatePed(5, hash, v.x, v.y, v.z - 1.0, v.w, false, false)
                    FreezeEntityPosition(PurchasePeds[pedKey], true)
                    SetBlockingOfNonTemporaryEvents(PurchasePeds[pedKey], true)
                    SetEntityInvincible(PurchasePeds[pedKey], true)
                    TaskStartScenarioInPlace(PurchasePeds[pedKey], 'WORLD_HUMAN_CLIPBOARD', 0, true)

                    local capturedJob = jobName
                    local capturedIdx = i

                    exports.ox_target:addBoxZone({
                        coords = vec3(v.x, v.y, v.z),
                        size = vec3(1.0, 1.0, 2.0),
                        rotation = v.w,
                        debug = false,
                        options = {{
                            name = 'ambulance_purchase_' .. pedKey,
                            icon = 'fas fa-car-on',
                            label = 'Beli Kendaraan',
                            canInteract = function()
                                local pdata = qb_ecore:GetPlayerData()
                                return pdata.job.name == capturedJob and pdata.job.onduty
                            end,
                            onSelect = function()
                                purchaseVehicleMenu(capturedJob, capturedIdx)
                            end,
                        }}
                    })

                    ::continue::
                end
            end
        end
    end

    -- for i = 1, #locations.vehicle do
    --     local v = locations.vehicle[i]

    --     lib.zones.box({
    --         coords = vector3(v.x, v.y, v.z),
    --         size = vector3(5, 5, 3),
    --         rotation = v.w or 0,
    --         debug = false,
    --         onEnter = function()
    --             local pdata = qb_ecore:GetPlayerData()
    --             if isMedicalJob(pdata.job.name) and pdata.job.onduty then
    --                 local names = config.garageNames[pdata.job.name] or config.garageNames.ambulance
    --                 lib.showTextUI('[E] - ' .. names.vehicle)
    --             end
    --         end,
    --         onExit = function()
    --             lib.hideTextUI()
    --         end,
    --         inside = function()
    --             local pdata = qb_ecore:GetPlayerData()
    --             if isMedicalJob(pdata.job.name) and pdata.job.onduty then
    --                 if IsControlJustPressed(0, 38) then
    --                     vehicleStoreMenu(i)
    --                 end
    --             end
    --         end
    --     })
    -- end

    for i = 1, #locations.helicopter do
        local v = locations.helicopter[i]

        lib.zones.box({
            coords = vector3(v.x, v.y, v.z),
            size = vector3(5, 5, 3),
            rotation = v.w or 0,
            debug = false,
            onEnter = function()
                local pdata = qb_ecore:GetPlayerData()
                if isMedicalJob(pdata.job.name) and pdata.job.onduty then
                    local names = config.garageNames[pdata.job.name] or config.garageNames.ambulance
                    lib.showTextUI('[E] - ' .. names.helicopter)
                end
            end,
            onExit = function()
                lib.hideTextUI()
            end,
            inside = function()
                local pdata = qb_ecore:GetPlayerData()
                if isMedicalJob(pdata.job.name) and pdata.job.onduty then
                    if IsControlJustPressed(0, 38) then
                        helicopterStoreMenu(i)
                    end
                end
            end
        })
    end
end)