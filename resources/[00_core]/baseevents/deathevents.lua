local isDead = false
local hasBeenDead = false
local diedAt = nil

Citizen.CreateThread(function()
    while true do
        Wait(250)

        local player = PlayerId()
        if not NetworkIsPlayerActive(player) then goto continue end

        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)

        if IsPedFatallyInjured(ped) and not isDead then
            isDead = true
            if not diedAt then
                diedAt = GetGameTimer()
            end

            local killer, weapon = NetworkGetEntityKillerOfPlayer(player)
            local killerType = -1
            local killerId = -1
            local inVehicle = false
            local vehicleName = ''
            local vehicleSeat = 0

            if killer ~= ped then
                local entityType = GetEntityType(killer)
                if entityType == 1 then -- ped
                    killerType = GetPedType(killer)
                    if IsPedInAnyVehicle(killer, false) then
                        inVehicle = true
                        local veh = GetVehiclePedIsUsing(killer)
                        vehicleName = GetDisplayNameFromVehicleModel(GetEntityModel(veh))
                        vehicleSeat = GetPedVehicleSeatDead(killer)
                    end
                end

                local killerNetId = GetPlayerByEntityID(killer)
                if killerNetId and NetworkIsPlayerActive(killerNetId) then
                    killerId = GetPlayerServerId(killerNetId)
                end
            end

            if killer == ped or killer == -1 then
                TriggerEvent('baseevents:onPlayerDied', killerType, { table.unpack(coords) })
                TriggerServerEvent('baseevents:onPlayerDied', killerType, { table.unpack(coords) })
            else
                TriggerEvent('baseevents:onPlayerKilled', killerId, {
                    killertype = killerType,
                    weaponhash = weapon,
                    killerinveh = inVehicle,
                    killervehseat = vehicleSeat,
                    killervehname = vehicleName,
                    killerpos = { table.unpack(coords) }
                })
                TriggerServerEvent('baseevents:onPlayerKilled', killerId, {
                    killertype = killerType,
                    weaponhash = weapon,
                    killerinveh = inVehicle,
                    killervehseat = vehicleSeat,
                    killervehname = vehicleName,
                    killerpos = { table.unpack(coords) }
                })
            end

            hasBeenDead = true

        elseif not IsPedFatallyInjured(ped) then
            if isDead then
                isDead = false
                diedAt = nil
            end
        end

        if not hasBeenDead and diedAt then
            TriggerEvent('baseevents:onPlayerWasted', { table.unpack(coords) })
            TriggerServerEvent('baseevents:onPlayerWasted', { table.unpack(coords) })
            hasBeenDead = true
        elseif hasBeenDead and not diedAt then
            hasBeenDead = false
        end

        ::continue::
    end
end)

function GetPlayerByEntityID(entity)
    for i = 0, 32 do
        if NetworkIsPlayerActive(i) and GetPlayerPed(i) == entity then
            return i
        end
    end
    return nil
end

function GetPedVehicleSeatDead(ped)
    local veh = GetVehiclePedIsIn(ped, false)
    for i = -1, GetVehicleMaxNumberOfPassengers(veh) do
        if GetPedInVehicleSeat(veh, i) == ped then return i end
    end
    return -2
end
