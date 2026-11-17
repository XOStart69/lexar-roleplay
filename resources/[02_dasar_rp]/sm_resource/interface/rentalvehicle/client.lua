local QBCore = exports['qb-core']:GetCoreObject()
local config = localmodule 'config.shared'
local timerModule = require 'modules.timers.shared'

local rentedVehicles = {}
local rentalTimers = {}

local function getFreeSpawnPoint(rentalLocation)
    for _, loc in pairs(rentalLocation.spawnLocations) do
        if not IsAnyVehicleNearPoint(loc.x, loc.y, loc.z, 2.0) then
            return loc
        end
    end
    return nil
end

RegisterNetEvent('rental:openMenu', function(data)
    local rentalLocation = data.rentalData

    if rentalLocation.type == "road" then
        local isOpen = lib.callback.await('rental:checkTaxiAvailability', false)
        if not isOpen then
            lib.notify({ title = 'Rental', description = 'Rental tutup, silahkan menghubungi taxi!', type = 'error' })
            return
        end
    end

    local options = {}

    for _, v in pairs(config.vehicles) do
        if rentalLocation.type == v.type then
            table.insert(options, {
                title = v.label .. ' - $' .. v.price .. ' [' .. v.duration .. ' Menit]',
                description = 'Sewa kendaraan ini',
                icon = 'car',
                onSelect = function()
                    if not getFreeSpawnPoint(rentalLocation) then
                        lib.notify({ title = 'Rental', description = 'Tidak ada tempat parkir yang tersedia! Silahkan coba lagi nanti.', type = 'error' })
                        return
                    end
                    TriggerTokenEvent('rental:rentVehicle', v.model, v.price, v.duration, v.label, rentalLocation)
                end
            })
        end
    end

    lib.registerContext({ id = 'rental_menu', title = rentalLocation.name, options = options })
    lib.showContext('rental_menu')
end)

RegisterNetEvent('rental:spawnVehicle', function(model, plate, duration, vehicleLabel, rentalLocation)
    local spawnCoords = getFreeSpawnPoint(rentalLocation)

    if not spawnCoords then
        lib.notify({ description = 'Tidak ada tempat parkir yang tersedia!', type = 'error' })
        return
    end

    QBCore.Functions.SpawnVehicle(model, function(veh)
        SetEntityCoords(veh, spawnCoords.x, spawnCoords.y, spawnCoords.z, false, false, false, true)
        SetEntityHeading(veh, spawnCoords.w)
        SetVehicleNumberPlateText(veh, plate)
        TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
        TriggerEvent('sm_vehiclekeys:client:setVehicleOwner', plate)

        rentedVehicles[plate] = NetworkGetNetworkIdFromEntity(veh)

        local rentalTimer = timerModule:new('detik', duration * 60, function()
            if DoesEntityExist(veh) then
                DeleteEntity(veh)
            end

            rentedVehicles[plate] = nil
            rentalTimers[plate] = nil

            infoUI.remove('rental_' .. plate)
            TriggerTokenEvent('rental:resetCooldown')
            lib.notify({ description = 'Waktu rental habis! Kendaraan dikembalikan.', type = 'error' })
        end)

        rentalTimers[plate] = rentalTimer

        CreateThread(function()
            while rentalTimers[plate] do
                infoUI.show({
                    id = 'rental_' .. plate,
                    icon = 'fa-solid fa-car',
                    title = 'RENTAL KENDARAAN',
                    description = {
                        [vehicleLabel .. ' [' .. plate .. ']'] = rentalTimer:getTimeLeftFormat()
                    }
                })
                Wait(1000)
            end

            infoUI.remove('rental_' .. plate)
        end)
    end, vector3(spawnCoords.x, spawnCoords.y, spawnCoords.z), true)
end)

RegisterNetEvent('rental:deleteVehicle', function(plate)
    for _, vehicle in ipairs(GetGamePool('CVehicle')) do
        if GetVehicleNumberPlateText(vehicle) == plate then
            DeleteEntity(vehicle)
            break
        end
    end

    if rentalTimers[plate] then
        rentalTimers[plate]:stop(true)
        rentalTimers[plate] = nil
    end

    rentedVehicles[plate] = nil
    infoUI.remove('rental_' .. plate)

    TriggerTokenEvent('rental:resetCooldown')
    lib.notify({ description = 'Kendaraan dengan plat ' .. plate .. ' telah dikembalikan!', type = 'error' })
end)

CreateThread(function()
    for _, rental in pairs(config.rentalLocations) do
        if rental.showBlip ~= false then
            local blip = AddBlipForCoord(rental.coords.x, rental.coords.y, rental.coords.z)
            local blipSprite = rental.name == "Rental Kapal" and 427 or 225

            SetBlipSprite(blip, blipSprite)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, 0.8)
            SetBlipColour(blip, 3)
            SetBlipAsShortRange(blip, true)

            AddTextEntry('BLIP_CAT_' .. 35, 'Rental')
            SetBlipCategory(blip, 35)
            -- header already says "Rental", drop the "Rental " prefix on the map
            local blipName = (rental.name:gsub('^Rental%s*', ''))

            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(blipName)
            EndTextCommandSetBlipName(blip)
        end

        exports.ox_target:addBoxZone({
            coords = rental.coords,
            size = vec3(2.0, 2.0, 2.0),
            rotation = 0.0,
            debug = false,
            options = {
                {
                    name = 'rental_menu_' .. rental.name,
                    event = 'rental:openMenu',
                    icon = 'fa-solid fa-car',
                    label = 'Sewa Kendaraan',
                    rentalData = rental
                }
            }
        })
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    TriggerTokenEvent('rental:checkRentalStatus')
end)