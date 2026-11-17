local inTestDrive
local currentShop
local previewVehicle

local installmentUI = false
local vehicleShopUI = false

local shops = cfg.shops
local vehicles = lib.loadJson('data.vehicles')
local vehicle_storage = require 'modules.vehicle_storage'

local function resetFocus()
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
end

local function openInstallmentUI()
    if installmentUI then
        return
    end

    local installments = lib.callback.await('rhd_vehicleshops:getInstallmentDetails', false)

    if not installments then
        lib.notify({
            description = 'Failed to load installment data',
            type = 'error'
        })
        return
    end

    SendNUIMessage({
        action = 'setInstallmentVisible',
        data = {
            state = true,
            vehicles = installments
        }
    })

    SetNuiFocus(true, true)
    installmentUI = true
end

local function refreshInstallmentData()
    if not installmentUI then
        return
    end

    local installments = lib.callback.await('rhd_vehicleshops:getInstallmentDetails', false)

    if not installments then
        return
    end

    SendNUIMessage({
        action = 'setInstallmentVisible',
        data = {
            state = true,
            vehicles = installments
        }
    })
end

local storageResolved = {}

---@param key string
---@return VehicleProps[]
local function getVehicleTable(key)
    local list = vehicles[key]

    if not list then
        return {}
    end

    if storageResolved[key] then
        return list
    end

    for i = 1, #list do
        local vehicle = list[i]
        local storage = vehicle_storage.getStorage(vehicle.model)

        if storage then
            vehicle.trunkSlots = storage.trunkSlots
            vehicle.trunkWeight = storage.trunkWeight
            vehicle.gloveSlots = storage.gloveSlots
            vehicle.gloveWeight = storage.gloveWeight
        end
    end

    storageResolved[key] = true
    return list
end

local function onCloseUI(shop)
    if shop and vehicleShopUI then
        currentShop = nil
        resetFocus()
        Client.deletePreview()
        vehicleShopUI = false
    elseif not shop and installmentUI then
        resetFocus()
        installmentUI = false
    end
end

local function deletePreview()
    if previewVehicle and DoesEntityExist(previewVehicle) then
        DeleteEntity(previewVehicle)
    end

    camera.destroy()
    SetNuiFocusKeepInput(false)
end

local function drivePurchasedVehicle()
    local lastShop = currentShop
    local shop_data = cfg.shops[lastShop]

    onCloseUI(true)

    if not shop_data then
        return
    end
    
    currentShop = nil
    local props = lib.callback.await('rhd_vehicleshops:getCache', false)
    
    if not props then
        return
    end

    local model = props.model
    local coords = shop_data.coords.spawnOnBuy

    lib.requestModel(model, 1500)
    
    local vehEntity = CreateVehicle(
        model, coords.x, coords.y, coords.z, coords.w, true, false)

    if not DoesEntityExist(vehEntity) then
        return
    end

    DoScreenFadeOut(500)
    Wait(1000)

    local netId = NetworkGetNetworkIdFromEntity(vehEntity)
    SetNetworkIdCanMigrate(netId, true)
    
    FreezeEntityPosition(vehEntity, true)
    RequestCollisionAtCoord(coords.x, coords.y, coords.z)
    lib.setVehicleProperties(vehEntity, props)
    SetVehicleFixed(vehEntity)
    Wait(100)
    SetVehicleDirtLevel(vehEntity, 0.0)
    SetVehicleFuelLevel(vehEntity, 100.0)
    FreezeEntityPosition(vehEntity, false)
    SetVehicleHasBeenOwnedByPlayer(vehEntity, true)
    TaskWarpPedIntoVehicle(cache.ped, vehEntity, -1)
    
    Wait(1000)
    DoScreenFadeIn(500)
    SetModelAsNoLongerNeeded(model)
    cfg.giveKeys(netId, qbLib.string.trim(GetVehicleNumberPlateText(vehEntity)))
end

---@param purchaseData PurchaseData
local function purchaseVehicle(purchaseData)
    local success = lib.callback.await('rhd_vehicleshops:buyVehicle', false, currentShop, purchaseData)
    return success
end

---@param r string
---@param g string
---@param b string
local function changeColor(r, g, b)
    ---@diagnostic disable-next-line: cast-local-type
    r, g, b = tonumber(r) , tonumber(g), tonumber(b)

    if not (r and g and b) then
        return
    end

    if not (previewVehicle and DoesEntityExist(previewVehicle)) then
        return
    end

    SetVehicleCustomPrimaryColour(previewVehicle, r, g, b)
    SetVehicleModColor_1(previewVehicle, 1 --[[@as integer]], 0, 0)

    SetVehicleCustomSecondaryColour(previewVehicle, r, g, b)
    SetVehicleModColor_2(previewVehicle, 1 --[[@as integer]], 0)
end

local function handleTimer(testDriveTime, prevCoords)

    if inTestDrive then
        return
    end

    inTestDrive = true
    local gameTimer = GetGameTimer()
    local totalMs = 1000 * testDriveTime
    local lastSent

    while inTestDrive and DoesEntityExist(previewVehicle) do
        local elapsed = GetGameTimer() - gameTimer

        if elapsed >= totalMs - 20 or GetPedInVehicleSeat(previewVehicle, -1) ~= cache.ped then
            SetEntityCoords(cache.ped, prevCoords.x, prevCoords.y, prevCoords.z, false, false, false, false)
            deletePreview()
            lib.notify({ description = 'Vehicle test drive complete' })
            break
        end

        local secondsLeft = math.ceil(testDriveTime - elapsed / 1000)

        if secondsLeft ~= lastSent then
            lastSent = secondsLeft

            SendNUIMessage({
                action = 'updateTimer',
                data = {
                    time = secondsLeft
                }
            })
        end

        Wait(250)
    end

    SendNUIMessage({
        action = 'updateTimer',
        data = { time = nil }
    })

    LocalPlayer.state.inTestDrive = false
    inTestDrive = false
    TriggerTokenEvent('rhd_vehicleshops:endTestDrive')
end

local function testDrive()
    local lastShop = currentShop

    camera.destroy()
    resetFocus()
    currentShop = nil
    vehicleShopUI = false

    if not (previewVehicle and DoesEntityExist(previewVehicle)) then
        return
    end

    local shop_data = shops[lastShop]

    if not shop_data then
        return
    end

    if not lib.callback.await('rhd_vehicleshops:startTestDrive', false, lastShop) then
        deletePreview()
        lib.notify({ description = 'Test drive tidak tersedia', type = 'error' })
        return
    end

    local coords = shop_data.coords.testDrive
    local lastCoords = GetEntityCoords(cache.ped)

    DoScreenFadeOut(500)
    Wait(1000)
    RequestCollisionAtCoord(coords.x, coords.y, coords.z)
    SetEntityCoords(previewVehicle, coords.x, coords.y, coords.z, false, false, false, false)
    TaskWarpPedIntoVehicle(cache.ped, previewVehicle, -1)
    SetEntityHeading(previewVehicle, coords.w)
    SetEntityCollision(previewVehicle, true, true)
    FreezeEntityPosition(previewVehicle, false)
    Wait(1000)
    DoScreenFadeIn(500)

    LocalPlayer.state.inTestDrive = true
    handleTimer(shop_data.testdriveTime * 60, lastCoords)
end

---@param vehicle VehicleProps
---@return boolean? VehicleSpawned
local function createPreview(vehicle)
    local model = qbLib.safecall(
        lib.requestModel, vehicle.model, 1500
    )

    if not model then return end

    local coords = shops[currentShop]?.coords?.preview

    if not coords then
        return
    end

    if previewVehicle and DoesEntityExist(previewVehicle) then
        DeleteEntity(previewVehicle)
    end

    previewVehicle = CreateVehicle(
        vehicle.model, coords.x, coords.y, coords.z, coords.w, false, false)

    Wait(100)
    FreezeEntityPosition(previewVehicle, true)
    SetVehicleFixed(previewVehicle)
    SetEntityCollision(previewVehicle, false, false)
    SetVehicleEngineOn(previewVehicle, true, true, true)
    SetVehicleDirtLevel(previewVehicle, 0.0)
    SetModelAsNoLongerNeeded(model)

    SendNUIMessage({
        action = 'updateStorage',
        data = {
            model = vehicle.model,
            hasTrunk = vehicle_storage.hasTrunkDoor(previewVehicle, vehicle.model)
        }
    })

    camera.create(previewVehicle)
    SetNuiFocusKeepInput(true)

    return DoesEntityExist(previewVehicle)
end

---@param shopId string
local function openShop(shopId)
    if vehicleShopUI then
        return
    end

    local shop_data = shops[shopId]

    if not shop_data then
        return
    end

    SendNUIMessage({
        action = 'setVisible',
        data = {
            state = true,
            vehicles = getVehicleTable(shop_data.vehicles)
        }
    })

    currentShop = shopId
    vehicleShopUI = true
    SetNuiFocus(true, true)
end

lib.callback.register('rhd_vehicleshops:getProps', function ()
    if not (previewVehicle and DoesEntityExist(previewVehicle)) then
        return
    end

    local props = lib.getVehicleProperties(previewVehicle)

    if not props then
        return
    end

    return {
        model = props.model,
        color1 = props.color1,
        color2 = props.color2,
        engineHealth = props.engineHealth,
        bodyHealth = props.bodyHealth,
        fuelLevel = props.fuelLevel
    }
end)

Client = {
    openShop = openShop,
    onCloseUI = onCloseUI,
    deletePreview = deletePreview,
    previewVehicle = createPreview,
    getVehicleTable = getVehicleTable,
    changeColor = changeColor,
    testDrive = testDrive,
    purchaseVehicle = purchaseVehicle,
    drivePurchasedVehicle = drivePurchasedVehicle,
    resetFocus = resetFocus,
    openInstallmentUI = openInstallmentUI,
    refreshInstallmentData = refreshInstallmentData
}

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        deletePreview()
    end
end)
