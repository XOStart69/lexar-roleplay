RegisterNUICallback('preview', function (data, cb)
    local vehicle = data.vehicle --[[@as VehicleProps]]
    local created = Client.previewVehicle(vehicle)

    cb(created)
end)

RegisterNUICallback('changeColor', function (data, cb)
    Client.changeColor(data.color:match("rgb%((%d+),%s*(%d+),%s*(%d+)%)"))

    cb('ok')
end)

RegisterNUICallback('spawnVehicle', function (data, cb)
    Client.drivePurchasedVehicle()
    cb(true)
end)

RegisterNUICallback('getInstallmentConfig', function(data, cb)
    cb(cfg.installment)
end)

RegisterNUICallback('buyVehicle', function (purchaseData, cb)
    local success = Client.purchaseVehicle(purchaseData)
    
    cb(success)
end)

RegisterNUICallback('testDrive', function (data, cb)
    Client.testDrive()

    cb('ok')
end)

RegisterNUICallback('payInstallment', function(data, cb)
    local plate = data.plate
    local amount = data.amount

    if not plate or not amount then
        cb(false)
        return
    end

    local success = lib.callback.await('rhd_vehicleshops:payInstallment', false, plate, amount)

    if success then
        Wait(500)
        Client.refreshInstallmentData()
    end

    cb(success)
end)

RegisterNUICallback('refreshInstallments', function(data, cb)
    Client.refreshInstallmentData()
    cb(true)
end)

RegisterNUICallback('exitShop', function (data, cb)
    Client.onCloseUI(true)
    cb('ok')
end)

RegisterNUICallback('exitInstallment', function (data, cb)
    Client.onCloseUI(false)
    cb('ok')
end)