local client_config = localmodule 'config.client'
local shared_config = localmodule 'config.shared'
local minigame_config = client_config.blaneCounty

local drillModule = require 'resource.illegal_activity.utils.drill'
local itemModule = require 'modules.items.client'
local sceneModule = require 'resource.illegal_activity.utils.scene'
local trolleyModule = require 'resource.illegal_activity.utils.trolley_client'

local bank_interact = {}

local function getConfig()
    return shared_config.blaneCounty
end

local BAR_DOOR_HASH = `sm_blane_bar_gate`

---@param barDoorConfig table
---@param locked boolean
local function setBarDoorLocked(barDoorConfig, locked)
    local coords = barDoorConfig.coords

    if not IsDoorRegisteredWithSystem(BAR_DOOR_HASH) then
        AddDoorToSystem(BAR_DOOR_HASH, barDoorConfig.object, coords.x, coords.y, coords.z, false, false, false)
    end

    DoorSystemSetDoorState(BAR_DOOR_HASH, locked and 1 or 0, false, false)

    local barDoor = GetClosestObjectOfType(coords.x, coords.y, coords.z, 5.0, barDoorConfig.object, false, false, false)
    if barDoor == 0 then return end

    if locked then
        SetEntityHeading(barDoor, math.floor(coords.w + 0.5))
    end

    FreezeEntityPosition(barDoor, locked)
end

--- @return nil
local function openBlaneCountyVaultDoor()
    local bank_config = getConfig()
    if not bank_config then return end

    local bar_door = bank_config.door_hack[2]
    local vault_door = bank_config.door_hack[1]

    local coords = vault_door.coords
    local bardorCoords = bar_door.coords

    local doorModel = vault_door.object
    local barDoorModel = bar_door.object

    local object = GetClosestObjectOfType(coords.x, coords.y, coords.z, 5.0, doorModel, false, false, false)
    local bardorObject = GetClosestObjectOfType(bardorCoords.x, bardorCoords.y, bardorCoords.z, 5.0, barDoorModel, false, false, false)

    local barEntHeading = math.floor(bardorCoords.w + 0.5)

    if bardorObject ~= 0 then
        SetEntityHeading(bardorObject, barEntHeading)
        FreezeEntityPosition(bardorObject, true)
    end

    shared_config.blaneCounty.door_hack[2].isOpened = false

    if object ~= 0 then
        local entHeading = vault_door.heading.closed
        local openHeading = vault_door.heading.open
        local step = entHeading < openHeading and 0.5 or -0.5

        CreateThread(function()
            while math.abs(entHeading - openHeading) > 0.51 do
                SetEntityHeading(object, entHeading)
                entHeading = entHeading + step
                Wait(10)
            end
            SetEntityHeading(object, openHeading)
            shared_config.blaneCounty.door_hack[1].isOpened = true
        end)
    else
        shared_config.blaneCounty.door_hack[1].isOpened = true
    end
end

local function resetBlaneCountyDoor()
    local bank_config = getConfig()
    if not bank_config then return end

    local vault_door = bank_config.door_hack[1]
    if not vault_door then return end

    local closedHeading = vault_door.heading.closed
    local object = GetClosestObjectOfType(vault_door.coords.x, vault_door.coords.y, vault_door.coords.z, 5.0, vault_door.object, false, false, false)

    if object ~= 0 then
        SetEntityHeading(object, closedHeading)
    end
end

local function hackComputer()
    local bank_config = getConfig()
    if not bank_config then return end

    local computer = bank_config.computer

    if not itemModule.checkRequired(computer.requiredItem) then
        return
    end

    local canExecute = lib.callback.await('illegal_blaneCounty:canExecute', 1500, {'hack_computer', true})

    if canExecute then
        FreezeEntityPosition(cache.ped, true)
        ox_target:disableTargeting(true)

        local success = minigame_config.computer()

        FreezeEntityPosition(cache.ped, false)
        ox_target:disableTargeting(false)

        if success then
            local street = qbLib.getStreetName(computer.coords)
            local streetName = ('%s %s'):format(street.main, street.cross)
            TriggerTokenEvent('illegal_blaneCounty:onComputerHacked', {streetName})
        else
            lib.notify({
                title = 'Blane County Bank',
                description = 'You failed to hack the computer.',
                type = 'error',
            })
            TriggerTokenEvent('illegal_blaneCounty:resetBusy', 'hack_computer')
        end
    end
end

local function hackVaultDoor()
    local bank_config = getConfig()
    if not bank_config then return end

    local vault_door = bank_config.door_hack[1]

    if not itemModule.checkRequired(vault_door.requiredItem) then
        return
    end

    local canExecute = lib.callback.await('illegal_blaneCounty:canExecute', 1500, {'hack_vault_door', false})

    if canExecute then
        local success = sceneModule[vault_door.scene.name] and sceneModule[vault_door.scene.name]({
            coords = vault_door.scene.coords,
            minigame = function()
                return minigame_config.vault_door()
                    and lib.callback.await('illegal_blaneCounty:consumeItem', false, 'hack_vault_door')
            end,
            card = vault_door.scene.card,
        })

        if success then
            TriggerTokenEvent('illegal_blaneCounty:onVaultDoorHacked', {})
        else
            lib.notify({
                title = 'Blane County Bank',
                description = 'You failed to hack the door.',
                type = 'error',
            })
            TriggerTokenEvent('illegal_blaneCounty:resetBusy', 'hack_vault_door')
        end
    end
end

local function hackBarDoor()
    local bank_config = getConfig()
    if not bank_config then return end

    local bar_door = bank_config.door_hack[2]

    if not itemModule.checkRequired(bar_door.requiredItem) then
        return
    end

    local canExecute = lib.callback.await('illegal_blaneCounty:canExecute', 1500, {'hack_bar_door', false})

    if canExecute then
        local success = sceneModule[bar_door.scene.name] and sceneModule[bar_door.scene.name]({
            coords = bar_door.scene.coords,
            minigame = function()
                return minigame_config.bar_door()
                    and lib.callback.await('illegal_blaneCounty:consumeItem', false, 'hack_bar_door')
            end,
            card = bar_door.scene.card,
        })

        if success then
            TriggerTokenEvent('illegal_blaneCounty:onBarDoorHacked', {})
        else
            lib.notify({
                title = 'Blane County Bank',
                description = 'You failed to hack the bar door.',
                type = 'error',
            })
            TriggerTokenEvent('illegal_blaneCounty:resetBusy', 'hack_bar_door')
        end
    end
end

local function resetInteraction()
    local trolley_zones = bank_interact.trolley_zones
    local drill_zones = bank_interact.drill_zones

    if trolley_zones and #trolley_zones > 0 then
        for i = 1, #trolley_zones do
            ox_target:removeZone(trolley_zones[i])
        end
    end

    if drill_zones and #drill_zones > 0 then
        for i = 1, #drill_zones do
            ox_target:removeZone(drill_zones[i])
        end
    end

    if bank_interact.center_table_zone then
        ox_target:removeZone(bank_interact.center_table_zone)
    end

    bank_interact.trolley_zones = nil
    bank_interact.drill_zones = nil
    bank_interact.center_table_zone = nil
end

local function setUpInteraction()
    local bank_config = getConfig()
    if not bank_config then return end

    resetInteraction()

    if not bank_interact.trolley_zones then
        bank_interact.trolley_zones = {}
    end

    local trolleys = bank_config.trolley

    for i = 1, #trolleys do
        local trolley = trolleys[i]
        local zone = ox_target:addSphereZone({
            coords = trolley.coords.xyz,
            radius = 0.8,
            options = {
                {
                    label = 'Loot the trolley',
                    icon = 'fa-solid fa-hand-holding-dollar',
                    distance = 1.5,
                    onSelect = function()
                        local canExecute = lib.callback.await('illegal_blaneCounty:canExecute', 1500, {'loot_trolley', false, i})

                        if canExecute then
                            FreezeEntityPosition(cache.ped, true)
                            local success = sceneModule.grabMoneyFromTrolley({
                                coords = trolley.coords,
                            })

                            FreezeEntityPosition(cache.ped, false)

                            if success then
                                TriggerTokenEvent('illegal_blaneCounty:onTrolleyLooted', {i})
                            else
                                lib.notify({
                                    title = 'Blane County Bank',
                                    description = 'You failed to loot the trolley.',
                                    type = 'error',
                                })
                                TriggerTokenEvent('illegal_blaneCounty:resetBusy', 'loot_trolley')
                            end
                        end
                    end,
                    canInteract = function()
                        return shared_config.blaneCounty.door_hack[1].isOpened and not shared_config.blaneCounty.trolley[i].looted
                    end
                }
            }
        })

        bank_interact.trolley_zones[i] = zone
    end

    if not bank_interact.drill_zones then
        bank_interact.drill_zones = {}
    end

    local drills = bank_config.drill

    for i = 1, #drills do
        local drill = drills[i]
        bank_interact.drill_zones[i] = ox_target:addSphereZone({
            coords = drill.coords.xyz,
            radius = 0.8,
            options = {
                {
                    label = 'Drill the deposit box',
                    icon = 'fas fa-circle-info',
                    distance = 1.5,
                    onSelect = function()
                        local toolItem = drill.tool or 'rusty_drill'
                        if not itemModule.checkRequired({ [toolItem] = 1 }) then
                            return
                        end

                        local canExecute = lib.callback.await('illegal_blaneCounty:canExecute', 1500, {'drill_deposit_box', false, i})

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
                                TriggerTokenEvent('illegal_blaneCounty:onDepositBoxDrilled', {i})
                                lib.notify({ title = "Success", description = "You successfully drilled the deposit box!", type = "success" })
                            else
                                TriggerTokenEvent('illegal_blaneCounty:onDepositBoxDrillFailed', {i})
                                lib.notify({ title = "Failed", description = "You failed to drill the deposit box.", type = "error" })
                            end
                        end)
                    end,
                    canInteract = function()
                        return shared_config.blaneCounty.door_hack[1].isOpened and not shared_config.blaneCounty.drill[i].looted
                    end
                }
            }
        })
    end

    local centerTable = bank_config.centerTable

    if centerTable then
        bank_interact.center_table_zone = ox_target:addSphereZone({
            coords = centerTable.coords.xyz,
            radius = 0.8,
            options = {
                {
                    label = 'Search the table',
                    icon = 'fa-solid fa-hand-holding-dollar',
                    distance = 1.5,
                    onSelect = function()
                        local canExecute = lib.callback.await('illegal_blaneCounty:canExecute', 1500, {'loot_center_table', false})

                        if not canExecute then
                            return
                        end

                        FreezeEntityPosition(cache.ped, true)

                        local animDict = 'anim@heists@ornate_bank@grab_cash'
                        pcall(lib.requestAnimDict, animDict, 15000)
                        lib.playAnim(cache.ped, animDict, 'grab', 8.0, 8.0, -1, 1, 0, false, false, false)

                        local success = lib.progressCircle({
                            duration = 5000,
                            label = 'Searching the table...',
                            position = 'bottom',
                            canCancel = true,
                            disable = { move = true, car = true, combat = true },
                        })

                        ClearPedTasks(cache.ped)
                        FreezeEntityPosition(cache.ped, false)

                        if success then
                            TriggerTokenEvent('illegal_blaneCounty:onCenterTableLooted')
                        else
                            TriggerTokenEvent('illegal_blaneCounty:resetBusy', 'loot_center_table')
                        end
                    end,
                    canInteract = function()
                        return shared_config.blaneCounty.door_hack[1].isOpened and not shared_config.blaneCounty.centerTable.looted
                    end
                }
            }
        })
    end
end

-- Computer hack target zone
CreateThread(function()
    local bank_config = getConfig()
    if not bank_config then return end

    local computer = bank_config.computer

    ox_target:addSphereZone({
        coords = computer.coords,
        radius = 1.0,
        options = {
            {
                label = 'Hack the computer',
                icon = 'fa-solid fa-desktop',
                distance = 1.5,
                onSelect = function()
                    hackComputer()
                end,
                canInteract = function()
                    return not shared_config.blaneCounty.computer.hacked
                end
            }
        }
    })

    -- Door hack target zones
    for i = 1, #bank_config.door_hack do
        local hack_config = bank_config.door_hack[i]
        local coords = hack_config.coords
        local isVault = hack_config.id == 'vault'

        local points = lib.points.new(coords, 5, {
            isOpen = hack_config.isOpened,
        })

        function points:nearby()
            self.tick = 1000

            if not self.object or self.object == 0 or not DoesEntityExist(self.object) then
                self.object = GetClosestObjectOfType(coords.x, coords.y, coords.z, 5.0, hack_config.object, false, false, false)
                self.barLocked = nil
            end

            if self.object == 0 then return end

            local vaultConfig = shared_config.blaneCounty.door_hack[1]
            local barConfig = shared_config.blaneCounty.door_hack[2]

            local barOpened = barConfig?.isOpened
            local doorOpened = vaultConfig?.isOpened

            if not isVault then
                local shouldLock = not barOpened
                if self.barLocked ~= shouldLock then
                    self.barLocked = shouldLock
                    setBarDoorLocked(hack_config, shouldLock)
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
            self.barLocked = nil
        end

        ox_target:addSphereZone({
            coords = hack_config.scene.coords.xyz,
            radius = 1.0,
            options = {
                {
                    label = isVault and 'Hack the door' or 'Plant thermite',
                    icon = isVault and 'fa-solid fa-computer' or 'fa-solid fa-fire',
                    distance = 1.0,
                    onSelect = function()
                        if isVault then
                            hackVaultDoor()
                        else
                            hackBarDoor()
                        end
                    end,
                    canInteract = function()
                        local computerHacked = shared_config.blaneCounty.computer.hacked
                        local vaultConfig = shared_config.blaneCounty.door_hack[1]
                        local barConfig = shared_config.blaneCounty.door_hack[2]
                        local doorOpened = vaultConfig?.isOpened
                        local barOpened = barConfig?.isOpened

                        if isVault then
                            return computerHacked and not doorOpened
                        else
                            return doorOpened and not barOpened
                        end
                    end
                }
            }
        })
    end
end)

RegisterNetEvent('illegal_blaneCounty:openDoor', function()
    if source == '' then return end

    setUpInteraction()
    openBlaneCountyVaultDoor()
end)

RegisterNetEvent('illegal_blaneCounty:setupTrolley', function(netIds)
    if source == '' then return end
    trolleyModule.placeOnGround(netIds)
end)

RegisterNetEvent('illegal_blaneCounty:sync_config', function(cfg)
    if source == '' then return end

    if cfg.computer then
        shared_config.blaneCounty.computer.hacked = cfg.computer.hacked
    end

    if cfg.door_hack then
        for i, door in pairs(cfg.door_hack) do
            if shared_config.blaneCounty.door_hack[i] then
                shared_config.blaneCounty.door_hack[i].isOpened = door.isOpened
            end
        end
    end

    if cfg.trolley then
        for i, trolley in pairs(cfg.trolley) do
            if shared_config.blaneCounty.trolley[i] then
                shared_config.blaneCounty.trolley[i].looted = trolley.looted
            end
        end
    end

    if cfg.drill then
        for i, drill in pairs(cfg.drill) do
            if shared_config.blaneCounty.drill[i] then
                shared_config.blaneCounty.drill[i].looted = drill.looted
            end
        end
    end

    if cfg.centerTable and shared_config.blaneCounty.centerTable then
        shared_config.blaneCounty.centerTable.looted = cfg.centerTable.looted
    end

    if shared_config.blaneCounty.door_hack[1].isOpened then
        setUpInteraction()
    end
end)

RegisterNetEvent('illegal_blaneCounty:sync_config_data', function(data, options)
    if source == '' then return end

    if not data or type(data) ~= "table" then return end

    for k, v in pairs(data) do
        shared_config.blaneCounty[k] = v
    end

    if options == 'reset' then
        resetInteraction()
        resetBlaneCountyDoor()
    elseif options == 'open_bar_door' then
        local barDoorConfig = shared_config.blaneCounty.door_hack[2]
        if barDoorConfig and barDoorConfig.isOpened then
            setBarDoorLocked(barDoorConfig, false)
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    resetInteraction()
end)

TriggerServerEvent('illegal_blaneCounty:request_config')
