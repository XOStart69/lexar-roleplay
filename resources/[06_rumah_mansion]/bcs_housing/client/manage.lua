RegisterNUICallback('payRent', function(homeId, cb)
    TriggerServerEvent('Housing:server:PayRent', homeId, LocalPlayer.state.CurrentApartment)
    cb(1)
end)

RegisterNUICallback('payMortgagePage', function(data, cb)
    TriggerEvent('Housing:client:PayMortgage', data.identifier, tonumber(data.aptId))
    cb(1)
end)

RegisterNUICallback('payMortgage', function(data, cb)
    ToggleNuiFrame(false)
    if data.type then
        TriggerServerEvent('Housing:server:PayMortgageRemaining', data.identifier, data.aptId)
    else
        TriggerServerEvent('Housing:server:PayMortgage', data.identifier, data.aptId)
    end
    cb(1)
end)

RegisterNUICallback('getOngoingMortgage', function(data, cb)
    cb(lib.callback.await('Housing:server:GetOngoingMortgage', false, data.identifier, data.aptId))
end)

RegisterNUICallback('saveOnGoingMortgage', function(data, cb)
    cb(lib.callback.await('Housing:server:SaveOngoingMortgage', false, data.identifier, data.aptId, data.mortgage,
        data.downpayment))
end)

RegisterNetEvent('Housing:client:SetHomePlan', function(homeId, aptId, plan)
    local home = Homes[homeId]

    if home then
        if home.complex == 'Apartment' and aptId then
            for i = 1, #home.apartments, 1 do
                if home.apartments[i].apartment == aptId then
                    Apartments[home.identifier].apartments[i].plan = plan
                    break
                end
            end
        else
            Homes[homeId].properties.plan = plan
        end
    end
end)
