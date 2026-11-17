---@diagnostic disable: undefined-field, param-type-mismatch

local store_zone
local kendaraan_kerja
local kendaraan_rusak

local blip_finish
local blip_kendaraan
local point_kendaraan

local action_busy = false

local job = {}
local di_antarkan = false

local pedEntity
local vehicleEentity = {}

local blipModule = require 'modules.blipHandle.client'
local client_config = require 'resource.rhd_towjob.config.client'

AddTextEntry('lepas_kendaraan', 'Tekan dan tahan ~INPUT_VEH_HEADLIGHT~ untuk melepaskan kendaraan')

local function request_data()
    local lokasi, model

    if math.random() < client_config.chance_dapat_orderan then
        lokasi = client_config.kendaraan_rusak.lokasi[math.random(#client_config.kendaraan_rusak.lokasi)]
        model = client_config.kendaraan_rusak.model[math.random(#client_config.kendaraan_rusak.model)]
    end

    return lokasi, model
end

local function cVehicle(model, coords, warp)
    if not pcall(lib.requestModel, model) then
        return
    end

    local Vehicle = CreateVehicle(
        model, coords.x, coords.y, coords.z, coords.w, true, true
    )

    SetVehicleHasBeenOwnedByPlayer(Vehicle, true)
    SetVehicleFixed(Vehicle)
    SetVehicleOnGroundProperly(Vehicle)
    SetVehicleFuelLevel(Vehicle, 100.0)
    SetEntityAsMissionEntity(Vehicle, true, true)
    
    if warp then
        TaskWarpPedIntoVehicle(cache.ped, Vehicle, -1)
    end

    vehicleEentity[#vehicleEentity+1] = Vehicle

    return Vehicle, #vehicleEentity
end

local function reset_job()
    safecall.fun(DeleteEntity, kendaraan_kerja)
    safecall.fun(DeleteEntity, kendaraan_rusak)

    if blip_kendaraan then
        blip_kendaraan:remove()
    end

    if blip_finish then
        blip_finish:remove()
    end

    if point_kendaraan then
        point_kendaraan:remove()
    end

    blip_finish = nil
    blip_kendaraan = nil
    kendaraan_kerja = nil
    point_kendaraan = nil
    kendaraan_rusak = nil
end

local function start_queue()
    CreateThread(function()
        local waktu_lama = GetGameTimer()
        local waiting_time = client_config.waiting_time() * 1000
    
        while kendaraan_kerja and DoesEntityExist(kendaraan_kerja) do
            local waktu_baru = GetGameTimer()
            local jarak_waktu = waktu_baru - waktu_lama
            
            if jarak_waktu >= waiting_time then
                local lokasi, model = request_data()
                if lokasi and model then
                    job.buat_point(model, lokasi)
                    lib.notify({description = "Pergi ambil kendaraan pelanggan yang rusak di lokasi yang sudah di tandai di map. Jangan buat pelanggan kecewa", duration = 8000})
                    break
                end
            end
            Wait(50)
        end
    end)

    lib.notify({description = 'Tunggu sampai ada panggilan dari pelanggan.', duration = 8000})
end

function job.buat_point(model, lokasi)
    blip_kendaraan = blipModule:new({
        label = 'Kendaraan rusak (towing job)',
        sprite = 326,
        coords = lokasi,
        scale = 0.7,
        color = 3,
        route = true
    })

    point_kendaraan = lib.points.new(lokasi.xyz, 100)

    function point_kendaraan:onEnter()
        if kendaraan_rusak and DoesEntityExist(kendaraan_rusak) then
            safecall.fun(DeleteEntity, kendaraan_rusak)
        end

        di_antarkan = false
        kendaraan_rusak = cVehicle(model, lokasi) --[[@as integer]]

        if kendaraan_rusak and DoesEntityExist(kendaraan_rusak) then
            SetVehicleEngineHealth(kendaraan_rusak, 0.0)
            SetVehicleDirtLevel(kendaraan_rusak, 12.0)
            SetVehicleUndriveable(kendaraan_rusak, true)
            SetVehicleDoorsLocked(kendaraan_rusak, 2)

            SetTimeout(500, function ()
                local netId = NetworkGetNetworkIdFromEntity(kendaraan_rusak)
                TriggerTokenEvent('rhd_towjob:server:create_tow_vehicle', netId)
            end)

            CreateThread(function()
                local sleep
                local udah_gakbisa = false
                local lokasi_kendaraanRusak = lokasi.xyz

                while kendaraan_kerja and DoesEntityExist(kendaraan_kerja) and kendaraan_kerja and DoesEntityExist(kendaraan_kerja) do
                    if not udah_gakbisa then
                        if not IsVehicleAttachedToTowTruck(kendaraan_kerja, kendaraan_rusak) then
                            sleep = 0
                            local coords = GetEntityCoords(kendaraan_rusak)
                            DrawMarker(20, coords.x, coords.y, coords.z + 3.5, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 3.0, 3.0, 1.0, 255,110, 100, 255, false, true, 2, false, nil, nil, false)
                            
                            if lokasi_kendaraanRusak ~= coords then
                                lokasi_kendaraanRusak = coords

                                if not (blip_kendaraan and blip_kendaraan:exists()) then
                                    blip_kendaraan = blipModule:new({
                                        label = 'Kendaraan rusak (towing job)',
                                        sprite = 326,
                                        coords = lokasi,
                                        scale = 0.7,
                                        color = 3,
                                        route = true
                                    })
                                end

                                blip_kendaraan:setCoords(lokasi_kendaraanRusak)
                            end

                            if blip_finish then
                                blip_finish:remove()
                                blip_finish = nil
                            end
    
                            if store_zone:contains(coords) then
                                udah_gakbisa = true
                                Entity(kendaraan_rusak).state:set('_towing_vehicle', true, true)
                                Wait(1500)
                                di_antarkan = true
                                break
                            end
                        else
                            sleep = 100
                            if blip_kendaraan then
                                blip_kendaraan:remove()
                                blip_kendaraan = nil
                            end

                            if not blip_finish or not blip_finish:exists() then
                                blip_finish = blipModule:new({
                                    coords = client_config.store_zone.coords,
                                    sprite = 1,
                                    color = 60,
                                    scale = 0.7,
                                    label = 'Lokasi pengantaran (towing job)',
                                    route = true
                                })
                            end
    
                            local lokasi_kendaraan = GetEntityCoords(kendaraan_rusak)
                            local distance = #(client_config.store_zone.coords - lokasi_kendaraan)
    
                            if distance < 50 then
                                sleep = 0
    
                                local marker_color = {242, 0, 48, 255}
                                if store_zone:contains(lokasi_kendaraan) then
                                    marker_color = {20, 246, 12, 255}
                                    DisplayHelpTextThisFrame('lepas_kendaraan', false)
                                end
                                
                                DrawMarker(43,
                                    client_config.store_zone.coords.x,
                                    client_config.store_zone.coords.y,
                                    client_config.store_zone.coords.z + -2,
                                    0.0, 0.0, 0.0,
                                    0.0, 0.0, client_config.store_zone.marker_heading,
                                    client_config.store_zone.size.x, client_config.store_zone.size.y --[[scale y]], 2.5,
                                    marker_color[1], marker_color[2], marker_color[3], marker_color[4],
                                    false, false, 2, false, nil, nil, false
                                )
                            end
                        end
                    end
                    
                    Wait(sleep)
                end

                if blip_kendaraan then
                    blip_kendaraan:remove()
                end

                if blip_finish then
                    blip_finish:remove()
                end
        
                safecall.fun(DeleteEntity, kendaraan_rusak)

                blip_kendaraan = nil
                kendaraan_rusak = nil

                if di_antarkan then
                    TriggerTokenEvent('rhd_towjob:server:getPendapatan')
                    lib.notify({description = 'Kamu telah menyelesaikan pekerjaanmu.', type = 'success'})

                    local alert = lib.alertDialog({
                        header = '',
                        content = 'Apakah kamu mau lanjut bekerja?',
                        centered = true,
                        cancel = true,
                        labels = {
                            cancel = 'Tidak',
                            confirm = 'Ya'
                        }
                    })

                    if alert == 'confirm' then
                        start_queue()
                    else
                        TaskLeaveVehicle(cache.ped, kendaraan_kerja, 1)
                        Wait(2000)
                        safecall.fun(DeleteEntity, kendaraan_kerja)
                        kendaraan_kerja = nil
                    end
                end
            end)

            point_kendaraan:remove()
            point_kendaraan = nil
        end
    end
end

function job.mulai_pekerjaan()
    if action_busy then return end
    reset_job() action_busy = true Wait(500)
    
    kendaraan_kerja = cVehicle(client_config.vehicle.model, client_config.vehicle.spawn_coords, true)

    if not kendaraan_kerja then return end

    local plate = GetVehicleNumberPlateText(kendaraan_kerja)
    client_config.give_vehicle_keys(string.trim(plate))

    action_busy = false
    start_queue()
end

CreateThread(function ()
    local pedStartPoints = lib.points.new(client_config.ped_start.coords.xyz, 15, {
        entity = nil
    })

    blipModule:new({
        label = 'Towing Job',
        coords = client_config.ped_start.coords.xyz,
        sprite = 637,
        color = 3,
        scale = 0.7
    })

    store_zone = lib.zones.box({
        coords = client_config.store_zone.coords,
        size = client_config.store_zone.size,
        rotation = client_config.store_zone.rotation,
        debug = client_config.store_zone.debug.zone
    })

    function pedStartPoints:onEnter()
        if not self.entity then
            if pcall(lib.requestModel, client_config.ped_start.model) then
                self.entity = CreatePed(
                    4, client_config.ped_start.model,
                    client_config.ped_start.coords.x, client_config.ped_start.coords.y, client_config.ped_start.coords.z, client_config.ped_start.coords.w,
                    false, false
                )
    
                FreezeEntityPosition(self.entity, true)
                SetEntityProofs(self.entity, true, true, true, true, true, true, true, true)
                SetBlockingOfNonTemporaryEvents(self.entity, true)
                
                if self.entity then
                    pedEntity = self.entity
                    ox_target:addLocalEntity(self.entity, {
                        {
                            label = 'Kerja Towing',
                            icon = 'fas fa-circle-info',
                            distance = 1.5,
                            onSelect = job.mulai_pekerjaan,
                            canInteract = function ()
                                return not (
                                    kendaraan_kerja and DoesEntityExist(kendaraan_kerja)
                                )
                            end
                        },
                        {
                            label = 'Berhenti kerja',
                            icon = 'fas fa-circle-info',
                            distance = 1.5,
                            onSelect = reset_job
                        }
                    })
                end
            end
        end
    end

    function pedStartPoints:onExit()
        if self.entity then
            ox_target:removeLocalEntity(self.entity)
            pcall(DeleteEntity, self.entity)
        end
        pedEntity = nil
        self.entity = nil
    end
end)

lib.callback.register('rhd_towjob:client:get_kendaraan_rusak', function(source)
    return kendaraan_rusak and VehToNet(kendaraan_rusak) or false
end)

CreateThread(function()
    while client_config.store_zone.debug.marker do
        local marker_color = {242, 0, 48, 255}
        DrawMarker(43,
            client_config.store_zone.coords.x,
            client_config.store_zone.coords.y,
            client_config.store_zone.coords.z + -2,
            0.0, 0.0, 0.0,
            0.0, 0.0, client_config.store_zone.marker_heading,
            client_config.store_zone.size.x, client_config.store_zone.size.y --[[scale y]], 2.5,
            marker_color[1], marker_color[2], marker_color[3], marker_color[4],
            false, false, 2, false, nil, nil, false
        )
        Wait(1)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        for i=1, #vehicleEentity do
            local ent = vehicleEentity[i]
            pcall(DeleteEntity, ent)
        end

        if pedEntity then
            pcall(DeleteEntity, pedEntity)
        end
    end
end)