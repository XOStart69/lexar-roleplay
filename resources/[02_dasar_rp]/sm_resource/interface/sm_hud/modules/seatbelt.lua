
local minSpeeds = {
    unbuckled = 80.0 / 3.6,
    buckled = 160.0 / 3.6
}

if lib.context == 'client' then
    local function toggleSeatbelt()
        local vehicle = cache.vehicle
        if not vehicle then return end
        
        local hasVehicleHarness = (Entity(vehicle).state.harnessDurability or 0) > 0

        if hasVehicleHarness then
            if playerState.seatbelt and not playerState.harness then
                playerState.seatbelt = false
            end
            local harnessOn = not playerState.harness
            playerState.harness = harnessOn
            playerState.seatbelt = harnessOn

            SetPedConfigFlag(cache.ped, 32, not harnessOn)
            if not harnessOn then
                SetFlyThroughWindscreenParams(minSpeeds.unbuckled, minSpeeds.unbuckled, 17.0, 5.0)
            end

            qb_ecore:Notify(harnessOn and 'Harness terpasang' or 'Harness dilepas', harnessOn and 'success' or 'error')
        else
            if playerState.harness then
                playerState.harness = false
            end
            local seatbeltOn = not playerState.seatbelt
            playerState.seatbelt = seatbeltOn
            SetPedConfigFlag(cache.ped, 32, true)
            SetFlyThroughWindscreenParams(seatbeltOn and minSpeeds.buckled or minSpeeds.unbuckled, seatbeltOn and minSpeeds.buckled or minSpeeds.unbuckled, 17.0, 5.0)
            qb_ecore:Notify(seatbeltOn and 'Seatbelt terpasang' or 'Seatbelt dilepas', seatbeltOn and 'success' or 'error')
        end
    end

    local function seatbelt()
        playerState.seatbelt = false
        playerState.harness = false
        SetPedConfigFlag(cache.ped, 32, true)
        SetFlyThroughWindscreenParams(minSpeeds.unbuckled, minSpeeds.unbuckled, 17.0, 5.0)

        local lastSpeed = 0.0
        local lastCheckTime = GetGameTimer()

        while cache.vehicle do
            local sleep = 1000
            local inSeatbelt = playerState.seatbelt
            local inHarness = playerState.harness

            if inSeatbelt or inHarness then
                sleep = 10
                DisableControlAction(0, 75, true)
                DisableControlAction(27, 75, true)
            end

            local vehicle = cache.vehicle
            local currentTime = GetGameTimer()

            if inHarness and cache.seat == -1 and currentTime - lastCheckTime >= 100 then
                local currentSpeed = GetEntitySpeed(vehicle) * 3.6
                local speedDiff = lastSpeed - currentSpeed
                
                if speedDiff > 25.0 then
                    local durability = Entity(vehicle).state.harnessDurability or 0
                    if durability > 0 then
                        local damage = math.floor(speedDiff * 0.2)
                        if damage < 5 then damage = 5 end
                        
                        local newDurability = math.max(0, durability - damage)
                        TriggerServerEvent('sm_hud:server:updateHarnessDurability', GetVehicleNumberPlateText(vehicle), newDurability)
                        
                        if newDurability <= 0 then
                            playerState.harness = false
                            playerState.seatbelt = false
                            SetPedConfigFlag(cache.ped, 32, true)
                            SetFlyThroughWindscreenParams(minSpeeds.unbuckled, minSpeeds.unbuckled, 17.0, 5.0)
                            qb_ecore:Notify('Harness Anda putus karena tabrakan keras!', 'error')
                        end
                    end
                end
                lastSpeed = currentSpeed
                lastCheckTime = currentTime
            elseif not inHarness then
                lastSpeed = 0.0
                lastCheckTime = GetGameTimer()
            end

            Wait(sleep)
        end
        playerState.seatbelt = false
        playerState.harness = false
        SetPedConfigFlag(cache.ped, 32, true)
        SetFlyThroughWindscreenParams(minSpeeds.unbuckled, minSpeeds.unbuckled, 17.0, 5.0)
    end

    CreateThread(function()
        SetFlyThroughWindscreenParams(minSpeeds.unbuckled, minSpeeds.unbuckled, 17.0, 5.0)
    end)

    lib.onCache('vehicle', function(vehicle)
        if vehicle then
            local plate = GetVehicleNumberPlateText(vehicle)
            if plate then
                TriggerServerEvent('sm_hud:server:checkVehicleHarness', plate)
            end
            Wait(500)
            seatbelt()
        end
    end)

    RegisterNetEvent('sm_hud:client:UseHarness', function(ItemData)
        if not cache.vehicle then
            qb_ecore:Notify('Anda tidak berada di dalam kendaraan', 'error')
            return
        end

        if cache.seat ~= -1 then
            qb_ecore:Notify('Hanya pengemudi yang dapat memasang harness!', 'error')
            return
        end

        local class = GetVehicleClass(cache.vehicle)
        if class == 8 or class == 13 or class == 14 then
            qb_ecore:Notify('Anda tidak berada di dalam kendaraan yang valid', 'error')
            return
        end

        local currentDurability = Entity(cache.vehicle).state.harnessDurability or 0
        if currentDurability > 0 then
            qb_ecore:Notify('Kendaraan ini sudah dipasangi harness!', 'error')
            return
        end

        if lib.progressCircle({
            duration = 5000,
            label = 'Memasang harness',
            position = 'bottom',
            useWhileDead = false,
            canCancel = true,
            disable = {
                combat = true
            }
        }) then
            TriggerServerEvent('sm_hud:server:installHarness', ItemData.slot)
        end
    end)

    lib.addKeybind({
        name = 'toggleseatbelt',
        description = 'Untuk memasang/melepaskan seatbelt',
        defaultKey = 'B',
        onPressed = function()
            if not cache.vehicle or IsPauseMenuActive() then return end
            local class = GetVehicleClass(cache.vehicle)
            if class == 8 or class == 13 or class == 14 then return end
            toggleSeatbelt()
        end
    })

    AddStateBagChangeHandler('harnessDurability', nil, function(bagName, key, value, _unused, replicated)
        local netId = tonumber(bagName:gsub('entity:', ''), 10)
        if not netId or not NetworkDoesEntityExistWithNetworkId(netId) then return end

        local entity = NetworkGetEntityFromNetworkId(netId)
        if entity == 0 or not DoesEntityExist(entity) then return end
        
        if cache.vehicle == entity then
            if not value or value <= 0 then
                if playerState.harness then
                    playerState.harness = false
                    playerState.seatbelt = false
                    SetPedConfigFlag(cache.ped, 32, true)
                    SetFlyThroughWindscreenParams(minSpeeds.unbuckled, minSpeeds.unbuckled, 17.0, 5.0)
                    qb_ecore:Notify('Harness kendaraan ini telah terputus/rusak!', 'error')
                end
            else
                if playerState.seatbelt and not playerState.harness then
                    playerState.seatbelt = false
                    SetPedConfigFlag(cache.ped, 32, true)
                    SetFlyThroughWindscreenParams(minSpeeds.unbuckled, minSpeeds.unbuckled, 17.0, 5.0)
                    qb_ecore:Notify('Harness baru terpasang! Tekan B untuk mengaktifkan.', 'primary')
                end
            end
        end
    end)


else
    SetConvarReplicated('game_enableFlyThroughWindscreen', 'true')

    qb_ecore:CreateUseableItem('harness', function(source, item)
        TriggerClientEvent('sm_hud:client:UseHarness', source, item)
    end)

    RegisterNetEvent('sm_hud:server:installHarness', function(slotId)
        local src = source
        local playerPed = GetPlayerPed(src)
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        if vehicle == 0 then return end

        local item = ox_inventory:GetSlot(src, slotId)
        if not item or item.name ~= 'harness' then return end

        if ox_inventory:RemoveItem(src, 'harness', 1, nil, slotId) then
            Entity(vehicle).state:set('harnessDurability', 100, true)

            local rawPlate = GetVehicleNumberPlateText(vehicle)
            if rawPlate then
                local plate = qbLib.string.trim(rawPlate)
                local result = MySQL.single.await('SELECT mods FROM player_vehicles WHERE plate = ?', { plate })
                if result and result.mods then
                    local mods = json.decode(result.mods) or {}
                    mods.harnessDurability = 100
                    MySQL.update.await('UPDATE player_vehicles SET mods = ? WHERE plate = ?', { json.encode(mods), plate })
                end
            end
            TriggerClientEvent('QBCore:Notify', src, 'Harness berhasil terpasang di kendaraan!', 'success')
        end
    end)

    RegisterNetEvent('sm_hud:server:updateHarnessDurability', function(plate, durability)
        local src = source
        local playerPed = GetPlayerPed(src)
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        if vehicle == 0 then return end

        Entity(vehicle).state:set('harnessDurability', durability, true)

        if plate then
            local trimmedPlate = qbLib.string.trim(plate)
            local result = MySQL.single.await('SELECT mods FROM player_vehicles WHERE plate = ?', { trimmedPlate })
            if result and result.mods then
                local mods = json.decode(result.mods) or {}
                if durability <= 0 then
                    mods.harnessDurability = nil
                else
                    mods.harnessDurability = durability
                end
                MySQL.update.await('UPDATE player_vehicles SET mods = ? WHERE plate = ?', { json.encode(mods), trimmedPlate })
            end
        end
    end)

    RegisterNetEvent('sm_hud:server:checkVehicleHarness', function(plate)
        local src = source
        local playerPed = GetPlayerPed(src)
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        if vehicle == 0 then return end

        if Entity(vehicle).state.harnessDurability ~= nil then return end

        local trimmedPlate = qbLib.string.trim(plate)
        local result = MySQL.single.await('SELECT mods FROM player_vehicles WHERE plate = ?', { trimmedPlate })
        if result and result.mods then
            local mods = json.decode(result.mods) or {}
            if mods.harnessDurability and mods.harnessDurability > 0 then
                Entity(vehicle).state:set('harnessDurability', mods.harnessDurability, true)
            else
                Entity(vehicle).state:set('harnessDurability', 0, true)
            end
        else
            Entity(vehicle).state:set('harnessDurability', 0, true)
        end
    end)
end