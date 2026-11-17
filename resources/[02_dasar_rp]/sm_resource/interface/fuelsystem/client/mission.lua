local timerInteval
local missionTimer

local blipRoute

local trailerloc = localmodule 'config.trailerloc'
local config = localmodule 'config.station'
local config_management = localmodule 'config.management'

local blipModule = require 'modules.blipHandle.client'
local timer = require 'modules.timers.shared'

---@class libSpawnVehicleClientParams
---@field model string|integer
---@field coords vector4
---@field networked? boolean
---@field props? table
---@field plate? string
---@field warp? boolean
---@field onCreate? fun(entity: integer, plate: string)
---@field serverPlate? boolean
---@field ignoreKeys? boolean

---@param spawnData libSpawnVehicleClientParams
---@return integer|boolean?
---@return string?
local function spawnVehicle ( spawnData )

    local network = spawnData.networked or true
    local coords = spawnData.coords or RHDCache.coords
    local model = spawnData.model or 'Kuruma'
    local plate = spawnData.plate
    local warp = spawnData.warp or false

    network = network or true

    if not pcall(lib.requestModel, model, 15000) then
        return false, ''
    end

    ---@diagnostic disable-next-line: undefined-field
    local veh = CreateVehicle(model, coords.x, coords.y, coords.z, coords.w, network, false)

    if network then
        local id = NetworkGetNetworkIdFromEntity(veh)
        SetNetworkIdCanMigrate(id, true)
        SetEntityAsMissionEntity(veh, true, true)
    end
    
    SetVehicleHasBeenOwnedByPlayer(veh, true)
    SetVehicleNeedsToBeHotwired(veh, false)
    SetVehRadioStation(veh, 'OFF')
    SetModelAsNoLongerNeeded(model)

    Wait(100)

    if warp then
        TaskWarpPedIntoVehicle(cache.ped, veh, -1)
    end

    return veh
end

local function clear(force)
    local trailer = playerState.mf_trailer
    local vehicle = playerState.mf_vehicle

    pcall(DeleteEntity, trailer)
    pcall(DeleteEntity, vehicle)

    if blipRoute?.remove then
        blipRoute:remove()
    end

    playerState.mf_trailer = nil
    playerState.mf_vehicle = nil

    infoUI.remove('fuelsystem:pengiriman')

    if force then
        TriggerTokenEvent('fuelsystem:forceEnd')
    end

    pcall(function (...)
        ClearInterval(timerInteval)
        timerInteval = nil
    end)

    missionTimer = nil
end

local function setupTimer()
    if missionTimer then
        missionTimer:stop(true)
        missionTimer = nil
    end

    local info = {
        id = 'fuelsystem:pengiriman',
        title = 'Pengiriman Minyak',
        icon = 'fas fa-gas-pump'
    }

    timerInteval = SetInterval(function()
        if missionTimer then
            info.description = {
                ['Waktu tersisa'] = missionTimer:getTimeLeftFormat()
            }
            infoUI.show(info)
        end
    end, 500)

    missionTimer = timer:new('menit', config_management.mission.delivery_timeout, function ()
        clear(true)
    end)
end

local function setupTrailer(stationID)
    local coords = trailerloc[math.random(#trailerloc)]

    if not coords then
        return
    end

    local tarilerPickUp = blipModule:new({
        coords = coords.xyz,
        sprite = 1,
        color = 60,
        scale = 0.5,
        label = 'Trailer Minyak',
        shortRange = false,
        route = true
    })

    local points = lib.points.new(coords.xyz, 50)

    function points:onEnter()
        if not (self.trailer and DoesEntityExist(self.trailer)) then
            local trailerEntity = spawnVehicle({
                model = 'tanker',
                coords = coords,
                warp = false
            })

            FreezeEntityPosition(trailerEntity, true)
            SetEntityCollision(trailerEntity, false, false)
            SetEntityCompletelyDisableCollision(trailerEntity, false, false)
            
            Entity(trailerEntity).state:set('fuel_station', stationID, true)
            playerState.mf_trailer = trailerEntity

            CreateThread(function ()
                while DoesEntityExist(trailerEntity) do
                    local tcoords = GetEntityCoords(trailerEntity)

                    if not IsVehicleAttachedToTrailer(playerState.mf_vehicle) then

                        DrawMarker(
                            20, tcoords.x, tcoords.y, tcoords.z + 3.5,
                            0.0, 0.0, 0.0,
                            0.0, 0.0, 0.0,
                            3.0, 3.0, 1.0,
                            255, 110, 100, 255,
                            true, true, 2, false, false, false, false
                        )
                        
                        if cache.vehicle == playerState.mf_vehicle and #(GetEntityCoords(cache.vehicle) - tcoords) < 10.0 and IsEntityPositionFrozen(trailerEntity) then
                            FreezeEntityPosition(trailerEntity, false)
                            SetEntityCollision(trailerEntity, true, false)
                        end
                    else
                        if not blipRoute then
                            local stationloc = sm_fuel.zones[stationID]?.coords

                            blipRoute = blipModule:new({
                                coords = stationloc.xyz,
                                sprite = 1,
                                color = 60,
                                scale = 0.5,
                                label = 'Tujuan pengantaran',
                                shortRange = false,
                                route = true
                            })
                            
                            if tarilerPickUp then
                                tarilerPickUp:remove()
                            end

                            lib.notify({
                                description = 'Bawa minyak ini dengan hati hati',
                            })
                        end
                    end
                    Wait(5)
                end
            end)

            self:remove()
        end
    end
end

lib.callback.register('fuelsystem:startMission', function ()
    local stationid = playerState.fuel_station_id

    if not stationid then
        return
    end

    if missionTimer then return end

    local station = array.find(config.location, function (station)
        return station.id == stationid
    end)

    if not station?.vehcoords then
        return
    end

    local model = 'hauler'
    local coords = station.vehcoords

    if not safecall.fun(lib.requestModel, model, 1500) then
        return
    end

    local vehExist = lib.getClosestVehicle(coords.xyz, 2.0, true)
    
    if vehExist then
        return lib.notify({
            description = 'Tidak cukup tempat untuk mengeluarkan kendaraan'
        })
    end

    local vehicle = spawnVehicle({
        model = model,
        coords = coords,
        warp = true
    })

    
    if not DoesEntityExist(vehicle) then
        pcall(DeleteEntity, vehicle)
        return
    end

    setupTrailer(stationid)

    pcall(function (...)
        local vehplate = GetVehicleNumberPlateText(vehicle)
        TriggerEvent('sm_vehiclekeys:client:setVehicleOwner', vehplate:trim())
    end)

    Entity(vehicle).state:set('fuel_station', stationid, true)
    playerState.mf_vehicle = vehicle

    lib.notify({
        description = 'Pergi ke lokasi pengambilan tanki minyak.'
    })

    setupTimer()

    return true
end)

RegisterNetEvent('fuelsystem:resetMission', function ()
    if source == '' then return end clear()
end)

