local firstOpening = true

local testDriveActive = false
local testDriveEndTime = 0
local testDriveVehicle = nil
local originalPosition = nil

local openSpamProtect = 0

function openDonateUI(initialTab)
    if uiOpen then return end

    if openSpamProtect >= GetGameTimer() then return end
    openSpamProtect = GetGameTimer() + 1500

    local playerData = QBCore.Functions.GetPlayerData()
    if not playerData or not playerData.citizenid then
        lib.notify({ description = 'Data pemain belum siap, coba lagi sebentar.', type = 'error' })
        return
    end

    if IsEntityDead(PlayerPedId()) or playerData.metadata['isdead'] or playerData.metadata['inlaststand'] then
        lib.notify({ description = 'Tidak bisa membuka menu saat sedang mati', type = 'error' })
        return
    end

    if playerData.metadata['ishandcuffed'] then
        lib.notify({ description = 'Tidak bisa membuka menu saat diborgol', type = 'error' })
        return
    end

    CreateThread(function()
        local withConfig = firstOpening
        local vipData = lib.callback.await('sm_donate:getVipData', false, withConfig)
        local bpData = lib.callback.await('sm_donate:getBattlepassData', false, withConfig)
        local gachaData = lib.callback.await('sm_donate:gachaGetData', false, withConfig)

        SetNuiFocus(true, true)
        uiOpen = true

        playTabletAnimation()

        local vipConfig
        if withConfig then
            vipConfig = {
                Categories = AK4Y.Categories,
                buyCoin = AK4Y.buyCoin,
                hotDeals = AK4Y.hotDeals,
                Translate = AK4Y.Translate,
                CustomPlatePrice = AK4Y.CustomPlatePrice,
                CustomPlateDruingPurchase = AK4Y.CustomPlateDruingPurchase,
                customizeLenghts = AK4Y.customizeLenghts,
            }
        end

        SendNUIMessage({
            action = 'openMenu',
            data = {
                initialTab = initialTab or 'donasi',
                vip = {
                    player = vipData,
                    config = vipConfig,
                },
                battlepass = bpData,
                gacha = gachaData,
            },
        })

        firstOpening = false
    end)
end

RegisterCommand(Settings.openCommand, function()
    openDonateUI('donasi')
end, false)

local function getCarData(itemData)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local vehHash = GetHashKey(itemData.itemName)
    if not IsModelInCdimage(vehHash) then return end

    RequestModel(vehHash)
    while not HasModelLoaded(vehHash) do Wait(0) end

    local vehicle = CreateVehicle(vehHash, playerCoords.x, playerCoords.y, playerCoords.z - 200.0, 1.0, false, false)
    FreezeEntityPosition(vehicle, true)
    local carData = QBCore.Functions.GetVehicleProperties(vehicle)

    if itemData.rataKanan and itemData.rataKanan.enabled then
        SetVehicleModKit(vehicle, 0)
        SetVehicleMod(vehicle, 11, GetNumVehicleMods(vehicle, 11) - 1, false)
        SetVehicleMod(vehicle, 12, GetNumVehicleMods(vehicle, 12) - 1, false)
        SetVehicleMod(vehicle, 13, GetNumVehicleMods(vehicle, 13) - 1, false)
        SetVehicleMod(vehicle, 15, GetNumVehicleMods(vehicle, 15) - 1, false)
        SetVehicleMod(vehicle, 16, GetNumVehicleMods(vehicle, 16) - 1, false)
        ToggleVehicleMod(vehicle, 18, true)
        carData = QBCore.Functions.GetVehicleProperties(vehicle)
    end

    DeleteVehicle(vehicle)
    return carData
end

local spamProtectRedeem = 0

RegisterNUICallback('redeemCode', function(data, cb)
    if GetGameTimer() < spamProtectRedeem then
        cb('Wait a moment before trying again')
        return
    end
    spamProtectRedeem = GetGameTimer() + 1000

    lib.callback('sm_donate:redeemCode', false, function(state)
        cb(state)
    end, data)
end)

RegisterNUICallback('itemBuy', function(data, cb)
    if data.itemType == Settings.SqlVehicleType or data.itemType == Settings.SqlAirType or data.itemType == Settings.SqlBoatType then
        data.carData = getCarData(data)
        lib.callback('sm_donate:buyItem', false, function(state) cb(state) end, data)

    elseif data.itemType == 'bundle' then
        for _, v in pairs(data.giveItems) do
            if v.itemType == Settings.SqlVehicleType or v.itemType == Settings.SqlAirType or v.itemType == Settings.SqlBoatType then
                v.carData = getCarData(v)
            end
        end
        lib.callback('sm_donate:buyItem', false, function(state) cb(state) end, data)

    elseif data.itemType == 'plate' then
        if IsPedInAnyVehicle(PlayerPedId(), false) then
            local veh = GetVehiclePedIsIn(PlayerPedId(), false)
            data.oldPlate = GetVehicleNumberPlateText(veh)
            local newPlate = data.customizePopUp.plateNumber
            lib.callback('sm_donate:buyItem', false, function(state)
                SetVehicleNumberPlateText(veh, newPlate)
                if Settings.GiveAddKeys then
                    Settings.GiveAddKeysFunction(newPlate)
                end
                cb(state)
            end, data)
        else
            cb(AK4Y.Translate.youHaveToBeInVehicle)
        end

    else
        lib.callback('sm_donate:buyItem', false, function(state) cb(state) end, data)
    end
end)

RegisterNetEvent('sm_donate:houseBought', function(data)
    if data.afterPurchaseTrigger.clientOrServer == 'server' then
        TriggerServerEvent(data.afterPurchaseTrigger.trigger, data.afterPurchaseTrigger.parameters)
    else
        TriggerEvent(data.afterPurchaseTrigger.trigger, data.afterPurchaseTrigger.parameters)
    end
end)

RegisterNUICallback('validatePlate', function(data, cb)
    lib.callback('sm_donate:validateCustomPlate', false, function(result)
        cb(result)
    end, data.plateNumber)
end)

RegisterNUICallback('locate', function(data, cb)
    if data.coords then
        SetNewWaypoint(data.coords.x, data.coords.y)
        lib.notify({ description = AK4Y.Translate.locationMarked, type = 'success' })
    end
    cb(true)
end)

local function endTestDrive(exitedVehicle)
    testDriveActive = false
    lib.hideTextUI()

    local playerPed = PlayerPedId()

    if DoesEntityExist(testDriveVehicle) then
        SetEntityAsMissionEntity(testDriveVehicle, false, true)
        DeleteVehicle(testDriveVehicle)
    end
    testDriveVehicle = nil

    if originalPosition then
        SetEntityCoords(playerPed, originalPosition.coords.x, originalPosition.coords.y, originalPosition.coords.z, false, false, false, true)
        SetEntityHeading(playerPed, originalPosition.heading)
        originalPosition = nil
    end

    TriggerTokenEvent('sm_donate:endTestDrive')

    lib.notify({
        description = exitedVehicle and 'Test drive berakhir karena keluar kendaraan' or 'Test drive selesai',
        type = 'info',
    })
end

local function spawnCarForTest(itemData, timing, savedCoords, savedHeading)
    originalPosition = { coords = savedCoords, heading = savedHeading }

    local playerPed = PlayerPedId()
    local spawnLocation = Settings.testDriveSpawn
    local vehHash = GetHashKey(itemData.itemName)

    if not IsModelInCdimage(vehHash) then
        lib.notify({ description = 'Model kendaraan tidak valid', type = 'error' })
        testDriveActive = false
        TriggerTokenEvent('sm_donate:endTestDrive')
        return
    end

    RequestModel(vehHash)
    while not HasModelLoaded(vehHash) do Wait(10) end

    local vehicle = CreateVehicle(vehHash, spawnLocation.x, spawnLocation.y, spawnLocation.z, spawnLocation.w, true, false)
    local testPlate = 'TEST' .. math.random(1000, 9999)
    SetVehicleNumberPlateText(vehicle, testPlate)
    SetVehicleOnGroundProperly(vehicle)
    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleHasBeenOwnedByPlayer(vehicle, true)
    SetVehicleNeedsToBeHotwired(vehicle, false)
    SetVehicleEngineOn(vehicle, true, true, false)

    if itemData.itemName == 'smcruis' then
        SetVehicleModKit(vehicle, 0)
        SetVehicleMod(vehicle, 8, 0, false)
    elseif itemData.itemName == 'smm3g80' then
        SetVehicleModKit(vehicle, 0)
        RemoveVehicleMod(vehicle, 7)
        RemoveVehicleMod(vehicle, 5)
    end

    SetEntityCoords(playerPed, spawnLocation.x, spawnLocation.y, spawnLocation.z, false, false, false, true)
    SetEntityHeading(playerPed, spawnLocation.w)
    Wait(500)
    TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
    TriggerEvent('sm_vehiclekeys:client:setVehicleOwner', testPlate)

    testDriveVehicle = vehicle
    testDriveEndTime = GetGameTimer() + (timing * 1000)

    lib.notify({ description = ('%s (%d detik)'):format(AK4Y.Translate.testDriveStarted, timing), type = 'success' })

    CreateThread(function()
        while testDriveActive do
            local timeLeft = math.ceil((testDriveEndTime - GetGameTimer()) / 1000)
            if timeLeft <= 0 or IsControlJustPressed(0, 38) then
                endTestDrive(false)
                break
            end
            lib.showTextUI(('[E] Hentikan Test Drive | Waktu: %02d:%02d'):format(math.floor(timeLeft / 60), timeLeft % 60), { position = 'top-center' })
            Wait(1)
        end
    end)
end

RegisterNUICallback('testDrive', function(data, cb)
    if testDriveActive then
        lib.notify({ description = 'Test drive sedang berlangsung', type = 'error' })
        cb(false)
        return
    end

    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    if not isPointInPolygon(playerCoords, Settings.TestDriveZone) then
        lib.notify({ description = 'Test drive hanya bisa dilakukan di lokasi Sumber Rezeki', type = 'error' })
        cb(false)
        return
    end

    local originalCoords = playerCoords
    local originalHeading = GetEntityHeading(playerPed)
    testDriveActive = true

    lib.callback('sm_donate:validateTestDrive', false, function(isValid)
        if not isValid then
            lib.notify({ description = AK4Y.Translate.testDriveNotAvailable or 'Test drive tidak tersedia', type = 'error' })
            testDriveActive = false
            cb(false)
            return
        end

        closeDonateUI()
        spawnCarForTest(data, Settings.testDriveTime or 60, originalCoords, originalHeading)
        cb(true)
    end, data)
end)
