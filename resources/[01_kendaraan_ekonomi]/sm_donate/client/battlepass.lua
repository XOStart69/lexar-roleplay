RegisterCommand('battlepass', function()
    openDonateUI('battlepass')
end, false)

local function getVehicleCarData(itemName)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local hash = GetHashKey(itemName)
    if not IsModelInCdimage(hash) then return nil end

    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(0) end

    local vehicle = CreateVehicle(hash, playerCoords.x, playerCoords.y, playerCoords.z - 200.0, 1.0, false, false)
    FreezeEntityPosition(vehicle, true)
    local carData = QBCore.Functions.GetVehicleProperties(vehicle)
    DeleteVehicle(vehicle)
    DeleteEntity(vehicle)
    return carData
end

local getStandartSpam = 0
RegisterNUICallback('bpGetStandartReward', function(data, cb)
    if getStandartSpam >= GetGameTimer() then cb(false) return end
    getStandartSpam = GetGameTimer() + 1000

    local carData = nil
    if data.itemDetails and data.itemDetails.type == 'vehicle' then
        carData = getVehicleCarData(data.itemDetails.itemName)
    end

    lib.callback('sm_donate:bpGetStandartReward', false, function(result)
        cb(result and true or false)
    end, data, carData)
end)

local getPremiumSpam = 0
RegisterNUICallback('bpGetPremiumReward', function(data, cb)
    if getPremiumSpam >= GetGameTimer() then cb(false) return end
    getPremiumSpam = GetGameTimer() + 1000

    local carData = nil
    if data.itemDetails and data.itemDetails.type == 'vehicle' then
        carData = getVehicleCarData(data.itemDetails.itemName)
    end

    lib.callback('sm_donate:bpGetPremiumReward', false, function(result)
        cb(result and true or false)
    end, data, carData)
end)

local standartTaskSpam = 0
RegisterNUICallback('bpStandartTaskDone', function(data, cb)
    if standartTaskSpam >= GetGameTimer() then cb(false) return end
    standartTaskSpam = GetGameTimer() + 1000

    lib.callback('sm_donate:bpStandartTaskDone', false, function(result)
        if result then
            SendNUIMessage({ action = 'bpAddEXP', data = { exp = tonumber(result) } })
            cb(true)
        else
            cb(false)
        end
    end, data)
end)

local premiumTaskSpam = 0
RegisterNUICallback('bpPremiumTaskDone', function(data, cb)
    if premiumTaskSpam >= GetGameTimer() then cb(false) return end
    premiumTaskSpam = GetGameTimer() + 1000

    lib.callback('sm_donate:bpPremiumTaskDone', false, function(result)
        if result then
            SendNUIMessage({ action = 'bpAddEXP', data = { exp = tonumber(result) } })
            cb(true)
        else
            cb(false)
        end
    end, data)
end)

local sendInputSpam = 0
RegisterNUICallback('bpSendInput', function(data, cb)
    if sendInputSpam >= GetGameTimer() then cb(false) return end
    sendInputSpam = GetGameTimer() + 1000

    lib.callback('sm_donate:bpSendInput', false, function(result)
        cb(result and true or false)
    end, data)
end)

RegisterNetEvent('sm_donate:bpAddTaskCount:standart', function(taskId, count)
    TriggerServerEvent('sm_donate:bpTaskCountAdd:standart', taskId, count)
end)

RegisterNetEvent('sm_donate:bpAddTaskCount:premium', function(taskId, count)
    TriggerServerEvent('sm_donate:bpTaskCountAdd:premium', taskId, count)
end)

RegisterNetEvent('sm_donate:bpTaskCompleted', function(taskTitle)
    SendNUIMessage({ action = 'bpTaskCompleted', data = { taskTitle = taskTitle } })
end)

RegisterNetEvent('ak4y-battlepass:addtaskcount:standart', function(taskId, count)
    TriggerServerEvent('sm_donate:bpTaskCountAdd:standart', taskId, count)
end)

RegisterNetEvent('ak4y-battlepass:addtaskcount:premium', function(taskId, count)
    TriggerServerEvent('sm_donate:bpTaskCountAdd:premium', taskId, count)
end)
