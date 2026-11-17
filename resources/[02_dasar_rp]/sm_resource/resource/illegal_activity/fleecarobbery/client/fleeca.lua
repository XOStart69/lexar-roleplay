local client_config = localmodule 'config.client'
local shared_config = localmodule 'config.shared'
local minigame_config = client_config.fleeca

local drillModule = require 'resource.illegal_activity.utils.drill'
local itemModule = require 'modules.items.client'
local sceneModule = require 'resource.illegal_activity.utils.scene'
local trolleyModule = require 'resource.illegal_activity.utils.trolley_client'

local bank_interact = {}

--- @param bankId number
--- @return nil
local function openFleecaVaultDoor(bankId)
    local bank_config = shared_config.basic[bankId]
    if not bank_config then return end

    local bar_door = bank_config.door_hack[2]
    local vault_door = bank_config.door_hack[1]

    local coords = vault_door.coords
    local bardorCoords = bar_door.coords

    local doorModel = vault_door.object
    local barDoorModel = bar_door.object

    local object = GetClosestObjectOfType(coords.x, coords.y, coords.z, 5.0, doorModel, false, false, false)
    local bardorObject = GetClosestObjectOfType(bardorCoords.x, bardorCoords.y, bardorCoords.z, 5.0, barDoorModel, false, false, false)

    local entHeading = vault_door.heading.closed
    local barEntHeading = math.floor(bardorCoords.w + 0.5)

    if bardorObject ~= 0 then
        SetEntityHeading(bardorObject, barEntHeading)
        FreezeEntityPosition(bardorObject, true)
    end

    shared_config.basic[bankId].door_hack[2].isOpened = false

    if object ~= 0 then
        CreateThread(function()
            local openHeading = vault_door.heading.open
            local step = entHeading < openHeading and 0.5 or -0.5
            while math.abs(entHeading - openHeading) > 0.51 do
                SetEntityHeading(object, entHeading)
                entHeading = entHeading + step
                Wait(10)
            end
            SetEntityHeading(object, openHeading)
            shared_config.basic[bankId].door_hack[1].isOpened = true
        end)
    else
        shared_config.basic[bankId].door_hack[1].isOpened = true
    end
end

local function resetFleecaBankDoor(bankId)
    local bank_config = shared_config.basic[bankId]
    if not bank_config then return end

    local vault_door = bank_config.door_hack[1]
    if not vault_door then return end

    local closedHeading = vault_door.heading.closed
    local object = GetClosestObjectOfType(vault_door.coords.x, vault_door.coords.y, vault_door.coords.z, 5.0, vault_door.object, false, false, false)
    
    if object ~= 0 then
        SetEntityHeading(object, closedHeading)
    end
end

local function hackVaultDoor(bankId)
    local bank_config = shared_config.basic[bankId]
    if not bank_config then return end

    local vault_door = bank_config.door_hack[1]

    if not itemModule.checkRequired(vault_door.requiredItem) then
        return
    end

    local canExecute = lib.callback.await('illegal_fleeca:canExecute', 1500, {bankId, 'hack_vault_door', true})

    if canExecute then
        local success = sceneModule[vault_door.scene.name] and sceneModule[vault_door.scene.name]({
            coords = vault_door.scene.coords,
            minigame = function()
                return minigame_config.vault_door()
                    and lib.callback.await('illegal_fleeca:consumeItem', false, {bankId, 'hack_vault_door'})
            end,
            card = vault_door.scene.card,
        })

        if success then
            local street = qbLib.getStreetName(vault_door.coords)
            local streetName = ('%s %s'):format(street.main, street.cross)
            TriggerTokenEvent('illegal_fleeca:onVaultDoorHacked', {bankId, streetName})
        else
            lib.notify({
                title = 'Fleeca Bank',
                description = 'You failed to hack the door.',
                type = 'error',
            })
            TriggerTokenEvent('illegal_fleeca:resetBusy', bankId, 'hack_vault_door')
        end
    end
end

local function hackBarDoor(bankId)
    local bank_config = shared_config.basic[bankId]
    if not bank_config then return end
    
    local bar_door = bank_config.door_hack[2]
    
    if not itemModule.checkRequired(bar_door.requiredItem) then
        return
    end

    local canExecute = lib.callback.await('illegal_fleeca:canExecute', 1500, {bankId, 'hack_bar_door', false})

    if canExecute then
        local success = sceneModule[bar_door.scene.name] and sceneModule[bar_door.scene.name]({
            coords = bar_door.scene.coords,
            minigame = function()
                return minigame_config.bar_door()
                    and lib.callback.await('illegal_fleeca:consumeItem', false, {bankId, 'hack_bar_door'})
            end,
            card = bar_door.scene.card,
        })

        if success then
            TriggerTokenEvent('illegal_fleeca:onBarDoorHacked', {bankId})
        else
            lib.notify({
                title = 'Fleeca Bank',
                description = 'You failed to hack the bar door.',
                type = 'error',
            })
            TriggerTokenEvent('illegal_fleeca:resetBusy', bankId, 'hack_bar_door')
        end
    end
end

local function resetInteraction(bankId)
    if not bank_interact[bankId] then return end

    local trolley_zones = bank_interact[bankId].trolley_zones
    local drill_zones = bank_interact[bankId].drill_zones

    if trolley_zones and #trolley_zones > 0 then
        for i=1, #trolley_zones do
            local zone = trolley_zones[i]
            ox_target:removeZone(zone)
        end
    end

    if drill_zones and #drill_zones > 0 then
        for i=1, #drill_zones do
            local zone = drill_zones[i]
            ox_target:removeZone(zone)
        end
    end

    bank_interact[bankId].trolley_zones = nil
    bank_interact[bankId].drill_zones = nil
end

local function setUpInteraction(bankId)
    local bank_config = shared_config.basic[bankId]
    if not bank_config then return end

    resetInteraction(bankId)

    if not bank_interact[bankId] then
        bank_interact[bankId] = {}
    end

    if not bank_interact[bankId].trolley_zones then
        bank_interact[bankId].trolley_zones = {}
    end

    local trolleys = bank_config.trolley

    for i=1, #trolleys do
        local trolley = trolleys[i]
        local zone = ox_target:addSphereZone({
            coords = trolley.coords.xyz,
            radius = 0.8,
            options = {
                {
                    label = 'Loot the trolley',
                    icon = 'fa-solid fa-hand-holding-dollar',
                    distance = 1.5,
                    onSelect = function ()
                        local canExecute = lib.callback.await('illegal_fleeca:canExecute', 1500, {bankId, 'loot_trolley', false, i})

                        if canExecute then
                            FreezeEntityPosition(cache.ped, true)
                            local success = sceneModule.grabMoneyFromTrolley({
                                coords = trolley.coords,
                            })

                            FreezeEntityPosition (cache.ped, false)

                            if success then
                                TriggerTokenEvent('illegal_fleeca:onTrolleyLooted', {bankId, i})
                            else
                                lib.notify({
                                    title = 'Fleeca Bank',
                                    description = 'You failed to loot the trolley.',
                                    type = 'error',
                                })
                                TriggerTokenEvent('illegal_fleeca:resetBusy', bankId, 'loot_trolley')
                            end
                        end
                    end,
                    canInteract = function ()
                        return shared_config.basic[bankId].door_hack[1].isOpened and not shared_config.basic[bankId].trolley[i].looted
                    end
                }
            }
        })
        
        bank_interact[bankId].trolley_zones[i] = zone
    end

    if not bank_interact[bankId].drill_zones then
        bank_interact[bankId].drill_zones = {}
    end
    
    local drills = bank_config.drill

    for i=1, #drills do
        local drill = drills[i]
        bank_interact[bankId].drill_zones[i] = ox_target:addSphereZone({
            coords = drill.coords.xyz,
            radius = 0.8,
            options = {
                {
                    label = 'Drill the deposit box',
                    icon = 'fas fa-circle-info',
                    distance = 1.5,
                    onSelect = function ()
                        if not itemModule.checkRequired(drill.requiredItem) then
                            return
                        end

                        local canExecute = lib.callback.await('illegal_fleeca:canExecute', 1500, {bankId, 'drill_deposit_box', false, i})

                        if not canExecute then
                            return
                        end

                        FreezeEntityPosition(cache.ped, true)

                        local animDict = 'anim@heists@fleeca_bank@drilling'
                        local propModel = `hei_prop_heist_drill`

                        pcall(lib.requestAnimDict, animDict, 15000)
                        pcall(lib.requestModel, propModel, 15000)

                        local coords = GetEntityCoords(cache.ped)
                        local drillEntity = CreateObject(propModel, coords, true, true, false)
                        AttachEntityToEntity(drillEntity, cache.ped, GetPedBoneIndex(cache.ped, 28422), 0.00, 0, -0.01, -220.0, 90.0, -180.0, false, false, false, false, 2, true)
                        lib.playAnim(cache.ped, animDict, 'drill_straight_idle', 8.0, 8.0, -1, 1, 0, false, false, false)

                        drillModule.LoadDrillSound()

                        Wait(250)
                        local soundId = GetSoundId()
                        PlaySoundFromEntity(soundId, 'Drill', drillEntity, 'DLC_HEIST_FLEECA_SOUNDSET', true, 0)

                        pcall(lib.requestNamedPtfxAsset, 'core', 1500)
                        UseParticleFxAssetNextCall('core')
                        local effect = StartParticleFxLoopedAtCoord('ent_ray_finale_vault_sparks', GetEntityCoords(drillEntity), 0, 0, 0, 1.0, false, false, false, false)

                        drillModule.Start(function(success)
                            drillModule.UnloadDrillSound(soundId)
                            StopParticleFxLooped(effect, 0)
                            RemovePtfxAsset('core')
                            ClearPedTasks(cache.ped)
                            DeleteObject(drillEntity)
                            FreezeEntityPosition(cache.ped, false)

                            if success then
                                TriggerTokenEvent('illegal_fleeca:onDepositBoxDrilled', {bankId, i})
                                lib.notify({ title = "Success", description = "You successfully drilled the deposit box!", type = "success" })
                            else
                                lib.notify({ title = "Failed", description = "You failed to drill the deposit box.", type = "error" })
                            end
                        end)
                    end,
                    canInteract = function ()
                        return shared_config.basic[bankId].door_hack[1].isOpened and not shared_config.basic[bankId].drill[i].looted
                    end
                }
            }
        })
    end
end

CreateThread(function ()
    for k, v in pairs(shared_config.basic) do
        if v.door_hack then
            for i=1, #v.door_hack do
                local hack_config = v.door_hack[i]
                local coords = hack_config.coords
                local isVault = hack_config.id == 'vault'

                local points = lib.points.new(coords, 5, {
                    isOpen = hack_config.isOpened,
                })

                function points:nearby()
                    self.tick = 1000

                    if not self.object then
                        self.object = GetClosestObjectOfType(coords.x, coords.y, coords.z, 2.0, hack_config.object, false, false, false)
                    end

                    local vaultConfig = shared_config.basic[k].door_hack[1]
                    local barConfig = shared_config.basic[k].door_hack[2]

                    local barOpened = barConfig?.isOpened
                    local doorOpened = vaultConfig?.isOpened

                    if not isVault then
                        if doorOpened and not barOpened and GetEntityHeading(self.object) ~= math.floor(coords.w + 0.5) then
                            SetEntityHeading(self.object, math.floor(coords.w + 0.5))
                            FreezeEntityPosition(self.object, true)
                        elseif (not doorOpened or doorOpened and barOpened) and IsEntityPositionFrozen(self.object) then
                            FreezeEntityPosition(self.object, false)
                        end
                    else
                        local doorHeading = GetEntityHeading(self.object)
                        if doorOpened and (not self.isOpen or doorHeading ~= hack_config.heading.open) then
                            self.isOpen = true
                            SetEntityHeading(self.object, hack_config.heading.open)
                        elseif not doorOpened and doorHeading ~= hack_config.heading.closed then
                            self.isOpen = false
                            SetEntityHeading(self.object, hack_config.heading.closed)
                        end
                    end
                end

                function points:onExit()
                    self.isOpen = nil
                    self.object = nil
                end

                ox_target:addSphereZone({
                    coords = hack_config.scene.coords.xyz,
                    radius = 1.0,
                    options = {
                        {
                            label = 'Hack the door',
                            icon = 'fa-solid fa-computer',
                            distance = 1.0,
                            onSelect = function ()
                                if isVault then
                                    hackVaultDoor(k)
                                else
                                    hackBarDoor(k)
                                end
                            end,
                            canInteract = function ()
                                local vaultConfig = shared_config.basic[k].door_hack[1]
                                local barConfig = shared_config.basic[k].door_hack[2]
                                local doorOpened = vaultConfig?.isOpened
                                local barOpened = barConfig?.isOpened

                                if not isVault then
                                    return doorOpened and not barOpened
                                end

                                return true
                            end
                        }
                    }
                })
            end
        end
    end
end)

RegisterNetEvent('illegal_fleeca:openDoor', function (bankId)
    if source == '' then return end

    setUpInteraction(bankId)
    openFleecaVaultDoor(bankId)
end)

RegisterNetEvent('illegal_fleeca:setupTrolley', function (netIds)
    if source == '' then return end
    trolleyModule.placeOnGround(netIds)
end)

RegisterNetEvent('illegal_fleeca:sync_config', function (cfg)
    if source == '' then return end

    for bankId, bankData in pairs(cfg) do
        if shared_config.basic[bankId] then
            if bankData.door_hack then
                for i, door in pairs(bankData.door_hack) do
                    if shared_config.basic[bankId].door_hack[i] then
                        shared_config.basic[bankId].door_hack[i].isOpened = door.isOpened
                    end
                end
            end

            if bankData.trolley then
                for i, trolley in pairs(bankData.trolley) do
                    if shared_config.basic[bankId].trolley[i] then
                        shared_config.basic[bankId].trolley[i].looted = trolley.looted
                    end
                end
            end

            if bankData.drill then
                for i, drill in pairs(bankData.drill) do
                    if shared_config.basic[bankId].drill[i] then
                        shared_config.basic[bankId].drill[i].looted = drill.looted
                    end
                end
            end

            if shared_config.basic[bankId].door_hack[1].isOpened then
                setUpInteraction(bankId)
            end
        end
    end
end)

RegisterNetEvent('illegal_fleeca:sync_config_data', function (bankId, data, options)

    if source == '' then return end

    local bank_config = shared_config.basic[bankId]

    if not bank_config then return end
    if not data or type(data) ~= "table" then return end

    for k, v in pairs(data) do
        shared_config.basic[bankId][k] = v
    end

    if options == 'reset' then
        resetInteraction(bankId)
        resetFleecaBankDoor(bankId)
    elseif options == 'open_bar_door' then
        local barDoorConfig = bank_config.door_hack[2]
        if barDoorConfig and not barDoorConfig.isOpened then
            local barDoor = GetClosestObjectOfType(barDoorConfig.coords.x, barDoorConfig.coords.y, barDoorConfig.coords.z, 5.0, barDoorConfig.object, false, false, false)
            if barDoor ~= 0 and IsEntityPositionFrozen(barDoor) then
                FreezeEntityPosition(barDoor, false)
            end
        end
    end
end)

AddEventHandler('onResourceStop', function (resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    for bankId, _ in pairs(shared_config.basic) do
        resetInteraction(bankId)
    end
end)

TriggerServerEvent('illegal_fleeca:request_config')