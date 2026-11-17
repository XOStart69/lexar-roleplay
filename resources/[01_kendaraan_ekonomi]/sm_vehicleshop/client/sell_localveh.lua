local vehicles = lib.loadJson('data.vehicles')

local cv
local am = {}
local dt = false

for category, vehicleList in pairs(vehicles) do
    if not am[category] then
        am[category] = {}
    end
    for i=1, #vehicleList do
        local vehicle = vehicleList[i]
        am[category][joaat(vehicle.model)] = vehicle.price
    end
end

local alertMessage = "Harga asli kendaraan: $%s     \nHarga jual ke dealer: $%s (%d%% dari harga asli)      \nPotongan: $%s\n\nApakah Anda yakin ingin menjual kendaraan ini?"

local function dt_thread(coords)
    if dt then return end

    dt = true
    CreateThread(function()
        local show = false
        while dt do
            local pc = GetEntityCoords(cache.ped)
            local distance = #(pc - coords.xyz)

            if distance < 1.5 then
                if cache.vehicle and not show then
                    show = true
                    lib.showTextUI('E - Jual kendaraan', {
                        position = 'bottom-center'
                    })
                elseif not cache.vehicle and show then
                    show = false
                    lib.hideTextUI()
                end
            else
                if show then
                    show = false
                    lib.hideTextUI()
                end
            end
            Wait(500)
        end

        show = false
        lib.hideTextUI()
    end)
end

local function setupLocation()
    for i=1, #cfg.sell_localveh do
        local data = cfg.sell_localveh[i]

        local points = lib.points.new(data.coords.xyz, data.distance or 25, {
            showtext = false
        })

        function points:onExit() dt = false end
        function points:onEnter() dt_thread(self.coords) end

        function points:nearby()
            if not cache.vehicle then return end
            local vehicleModel = GetEntityModel(cache.vehicle)
            local vehiclePrice = am[data.vehicles]?[vehicleModel]
            
            if not vehiclePrice then
                return
            end

            ---@diagnostic disable-next-line: missing-parameter
            DrawMarker(
                29,
                self.coords.x, self.coords.y, self.coords.z,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                1.0, 1.0, 1.0,
                0, 255, 0, 100,
                false, true, 2, false, nil, nil
            )

            if self.currentDistance < 1.5 then
                if IsControlJustPressed(0, 38) then
                    local isOwner = lib.callback.await('rhd_vehicleshops:isVehicleOwner', 1500)
                    
                    if not isOwner then
                        lib.notify({
                            description = 'Ini bukan kendaraan milikmu!',
                            type = 'error',
                            duration = 8000
                        })
                        return
                    end

                    local potongan = (vehiclePrice * data.pricePercentage) / 100
                    local hargaJual = vehiclePrice - potongan
                    
                    local alert = lib.alertDialog({
                        header = 'Jual Kendaraan ke Dealer.',
                        content = alertMessage:format(
                            lib.math.groupdigits(vehiclePrice),
                            lib.math.groupdigits(math.floor(hargaJual)),
                            data.pricePercentage,
                            lib.math.groupdigits(math.floor(potongan))
                        ),
                        centered = true,
                        cancel = true,
                        labels = {
                            confirm = 'Ya, saya mau jual',
                            cancel = 'Tidak jadi'
                        }
                    })

                    if alert == 'confirm' then
                        local vehicle = cache.vehicle
                        TaskLeaveVehicle(cache.ped, vehicle, 0)

                        repeat
                            Wait(50)
                        until not cache.vehicle

                        cv = {
                            c = data.vehicles,
                            p = data.pricePercentage
                        }

                        local netId = NetworkGetNetworkIdFromEntity(vehicle)
                        TriggerTokenEvent('rhd_vehicleshops:sell_localveh', netId)
                    end
                end
            end
        end
    end
end

lib.callback.register('rhd_vehicleshops:getcv', function()
    local d = cv cv = nil
    return d
end)

CreateThread(setupLocation)