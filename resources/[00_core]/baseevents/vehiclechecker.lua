local isInVehicle = false
local isEnteringVehicle = false
local currentVehicle = 0
local currentSeat = 0

Citizen.CreateThread(function()
    while true do
        local ped = PlayerPedId()

        if not isInVehicle and not IsPlayerDead(ped) then
            if not isEnteringVehicle then
                local tryingVehicle = GetVehiclePedIsTryingToEnter(ped)
                if tryingVehicle and DoesEntityExist(tryingVehicle) then
                    isEnteringVehicle = true

                    local seat = GetSeatPedIsTryingToEnter(ped)
                    local model = GetEntityModel(tryingVehicle)
                    local name = GetDisplayNameFromVehicleModel(model)
                    local netId = VehToNet(tryingVehicle)

                    TriggerServerEvent('baseevents:enteringVehicle', tryingVehicle, seat, name, netId)
                end
            else
                if not IsPedInAnyVehicle(ped, true) and not DoesEntityExist(GetVehiclePedIsTryingToEnter(ped)) then
                    isEnteringVehicle = false
                    TriggerServerEvent('baseevents:enteringAborted')
                elseif IsPedInAnyVehicle(ped, false) then
                    currentVehicle = GetVehiclePedIsUsing(ped)
                    currentSeat = GetPedVehicleSeat(ped)
                    local model = GetEntityModel(currentVehicle)
                    local name = GetDisplayNameFromVehicleModel(model)
                    local netId = VehToNet(currentVehicle)

                    isEnteringVehicle = false
                    isInVehicle = true
                    TriggerServerEvent('baseevents:enteredVehicle', currentVehicle, currentSeat, name, netId)
                end
            end
        elseif isInVehicle then
            if not IsPedInAnyVehicle(ped, false) or IsPlayerDead(ped) then
                local model = GetEntityModel(currentVehicle)
                local name = GetDisplayNameFromVehicleModel(model)
                local netId = VehToNet(currentVehicle)

                TriggerServerEvent('baseevents:leftVehicle', currentVehicle, currentSeat, name, netId)

                isInVehicle = false
                currentVehicle = 0
                currentSeat = 0
            end
        end
        Citizen.Wait(200)
    end
end)

function GetPedVehicleSeat(ped)
    local vehicle = GetVehiclePedIsIn(ped, false)
    for i = -2, GetVehicleMaxNumberOfPassengers(vehicle) do
        if GetPedInVehicleSeat(vehicle, i) == ped then
            return i
        end
    end
    return -2
end
