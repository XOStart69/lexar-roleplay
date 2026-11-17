local client_config = localmodule 'config.client'
local shared_config = localmodule 'config.shared'
local minigame_config = client_config.pacificBank

local drillModule = require 'resource.illegal_activity.utils.drill'
local itemModule = require 'modules.items.client'
local sceneModule = require 'resource.illegal_activity.utils.scene'

local bank_interact = {}
local trolleyEntity = {}

local function getConfig()
    return shared_config.pacificBank
end

local function clearTrolley()
    local cacheEntity = trolleyEntity.pacific

    if cacheEntity and #cacheEntity > 0 then
        for i = 1, #cacheEntity do
            pcall(DeleteEntity, cacheEntity[i])
        end
    end

    local bank_config = getConfig()

    if bank_config and bank_config.trolley then
        for i = 1, #bank_config.trolley do
            local coords = bank_config.trolley[i].coords
            local obj = GetClosestObjectOfType(coords.x, coords.y, coords.z, 1.0, `hei_prop_hei_cash_trolly_01`, true, false, false)
            if obj ~= 0 then pcall(DeleteEntity, obj) end
        end
    end

    return {}
end

local function setUpBankTrolley()
    local bank_config = getConfig()
    if not bank_config then return end

    trolleyEntity.pacific = clearTrolley()

    local model = `hei_prop_hei_cash_trolly_01`
    pcall(lib.requestModel, model, 1500)

    for i = 1, #bank_config.trolley do
        local trolley = bank_config.trolley[i]
        local coords = trolley.coords

        -- Non-networked entity (false) to reduce sync overhead
        local entity = CreateObject(model, coords.x, coords.y, coords.z - 0.5, false, true, false)

        SetEntityHeading(entity, coords.w)
        FreezeEntityPosition(entity, true)
        PlaceObjectOnGroundProperly(entity)

        table.insert(trolleyEntity.pacific, entity)
    end

    SetModelAsNoLongerNeeded(model)
end

--- @param doorIndex number
local function openBarDoor(doorIndex)
    local bank_config = getConfig()
    local door = bank_config.door_hack[doorIndex]
    if not door then return end

    local coords = door.coords
    local obj = GetClosestObjectOfType(coords.x, coords.y, coords.z, 5.0, door.object, false, false, false)
    if obj == 0 then return end

    FreezeEntityPosition(obj, false)
end

--- @param doorIndex number
local function openVaultDoor(doorIndex)
    local bank_config = getConfig()
    local door = bank_config.door_hack[doorIndex]
    if not door or not door.heading then return end

    local coords = door.coords
    local obj = GetClosestObjectOfType(coords.x, coords.y, coords.z, 10.0, door.object, false, false, false)
    if obj == 0 then return end

    local entHeading = door.heading.closed
    local openHeading = door.heading.open
 
    CreateThread(function()
        local step = entHeading < openHeading and 0.5 or -0.5
        while math.abs(entHeading - openHeading) > 0.51 do
            SetEntityHeading(obj, entHeading)
            entHeading = entHeading + step
            Wait(10)
        end
        SetEntityHeading(obj, openHeading)
        shared_config.pacificBank.door_hack[doorIndex].isOpened = true
    end)
end

-- RegisterCommand('openvault', function ()
--     openVaultDoor(3)
-- end, false)

local function resetAllDoors()
    local bank_config = getConfig()
    if not bank_config then return end

    for i = 1, #bank_config.door_hack do
        local door = bank_config.door_hack[i]
        local coords = door.coords
        local obj = GetClosestObjectOfType(coords.x, coords.y, coords.z, 5.0, door.object, false, false, false)
        if obj ~= 0 then
            if door.heading then
                SetEntityHeading(obj, door.heading.closed)
            else
                local targetHeading = math.floor(coords.w + 0.5)
                SetEntityHeading(obj, targetHeading)
                FreezeEntityPosition(obj, true)
            end
        end
    end
end

-- ─── Hack door ────────────────────────────────────────────────────────────────

--- @param sceneName string
--- @return boolean
local function runMinigame(sceneName)
    if sceneName == 'plantThermite' then
        return minigame_config.bar_door()
    elseif sceneName == 'latopHackStart' then
        return minigame_config.vault_door()
    end
    return false
end

--- @param doorIndex number
local function hackDoor(doorIndex)
    local bank_config = getConfig()
    if not bank_config then return end

    local door = bank_config.door_hack[doorIndex]
    if not door then return end

    if door.checkDoor then
        local prereq = bank_config.door_hack[door.checkDoor]
        if not prereq or not prereq.isOpened then
            lib.notify({
                title = 'Pacific Bank',
                description = 'Pintu sebelumnya harus dibuka terlebih dahulu.',
                type = 'error',
            })
            return
        end
    end

    if not itemModule.checkRequired(door.requiredItem) then
        return
    end

    local checkPolice = doorIndex == 1
    local canExecute = lib.callback.await('illegal_pacificBank:canExecute', 1500, {'hack_door', checkPolice, doorIndex})
    if not canExecute then return end

    local success = sceneModule[door.scene.name] and sceneModule[door.scene.name]({
        coords = door.scene.coords,
        minigame = function()
            return runMinigame(door.scene.name)
                and lib.callback.await('illegal_pacificBank:consumeItem', false, doorIndex)
        end,
    })

    if success then
        local street = qbLib.getStreetName(door.coords)
        local streetName = ('%s %s'):format(street.main, street.cross)
        TriggerTokenEvent('illegal_pacificBank:onDoorHacked', {doorIndex, streetName})
    else
        lib.notify({
            title = 'Pacific Bank',
            description = 'Gagal membuka pintu.',
            type = 'error',
        })
        TriggerTokenEvent('illegal_pacificBank:resetBusy', 'hack_door')
    end
end

local function resetInteraction()
    if bank_interact.trolley_zones then
        for _, zone in ipairs(bank_interact.trolley_zones) do
            ox_target:removeZone(zone)
        end
    end

    if bank_interact.drill_zones then
        for _, zone in ipairs(bank_interact.drill_zones) do
            ox_target:removeZone(zone)
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

    if bank_interact.trolley_zones and #bank_interact.trolley_zones > 0 then return end

    bank_interact.trolley_zones = {}
    bank_interact.drill_zones   = {}

    for i = 1, #bank_config.trolley do
        local trolley = bank_config.trolley[i]
        local zone = ox_target:addSphereZone({
            coords = trolley.coords.xyz,
            radius = 0.8,
            options = {
                {
                    label = 'Ambil uang dari trolley',
                    icon = 'fa-solid fa-hand-holding-dollar',
                    distance = 1.5,
                    onSelect = function()
                        local canExecute = lib.callback.await('illegal_pacificBank:canExecute', 1500, {'loot_trolley', false, i})
                        if not canExecute then return end

                        FreezeEntityPosition(cache.ped, true)
                        local success = sceneModule.grabMoneyFromTrolley({ coords = trolley.coords })
                        FreezeEntityPosition(cache.ped, false)

                        if success then
                            TriggerTokenEvent('illegal_pacificBank:onTrolleyLooted', {i})
                        else
                            lib.notify({ title = 'Pacific Bank', description = 'Gagal mengambil uang.', type = 'error' })
                            TriggerTokenEvent('illegal_pacificBank:resetBusy', 'loot_trolley')
                        end
                    end,
                    canInteract = function()
                        return shared_config.pacificBank.door_hack[3]?.isOpened
                            and not shared_config.pacificBank.trolley[i].looted
                    end
                }
            }
        })
        table.insert(bank_interact.trolley_zones, zone)
    end

    for i = 1, #bank_config.drill do
        local drill = bank_config.drill[i]
        local zone = ox_target:addSphereZone({
            coords = drill.coords.xyz,
            radius = 0.8,
            options = {
                {
                    label = 'Bor deposit box',
                    icon = 'fas fa-screwdriver-wrench',
                    distance = 1.5,
                    onSelect = function()
                        local toolItem = drill.tool or 'drill'
                        if not itemModule.checkRequired({ [toolItem] = 1 }) then
                            return
                        end

                        local canExecute = lib.callback.await('illegal_pacificBank:canExecute', 1500, {'drill_deposit_box', false, i})
                        if not canExecute then return end

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
                                TriggerTokenEvent('illegal_pacificBank:onDepositBoxDrilled', {i})
                                lib.notify({ title = 'Pacific Bank', description = 'Deposit box berhasil dibor!', type = 'success' })
                            else
                                TriggerTokenEvent('illegal_pacificBank:onDepositBoxDrillFailed', {i})
                                lib.notify({ title = 'Pacific Bank', description = 'Gagal membor deposit box.', type = 'error' })
                            end
                        end)
                    end,
                    canInteract = function()
                        return shared_config.pacificBank.door_hack[3]?.isOpened
                            and not shared_config.pacificBank.drill[i].looted
                    end
                }
            }
        })
        table.insert(bank_interact.drill_zones, zone)
    end

    local centerTable = bank_config.centerTable

    if centerTable then
        bank_interact.center_table_zone = ox_target:addSphereZone({
            coords = centerTable.coords.xyz,
            radius = 0.8,
            options = {
                {
                    label = 'Periksa meja',
                    icon = 'fa-solid fa-hand-holding-dollar',
                    distance = 1.5,
                    onSelect = function()
                        local canExecute = lib.callback.await('illegal_pacificBank:canExecute', 1500, {'loot_center_table', false})
                        if not canExecute then return end

                        FreezeEntityPosition(cache.ped, true)

                        local animDict = 'anim@heists@ornate_bank@grab_cash'
                        pcall(lib.requestAnimDict, animDict, 15000)
                        lib.playAnim(cache.ped, animDict, 'grab', 8.0, 8.0, -1, 1, 0, false, false, false)

                        local success = lib.progressCircle({
                            duration = 5000,
                            label = 'Memeriksa meja...',
                            position = 'bottom',
                            canCancel = true,
                            disable = { move = true, car = true, combat = true },
                        })

                        ClearPedTasks(cache.ped)
                        FreezeEntityPosition(cache.ped, false)

                        if success then
                            TriggerTokenEvent('illegal_pacificBank:onCenterTableLooted')
                        else
                            TriggerTokenEvent('illegal_pacificBank:resetBusy', 'loot_center_table')
                        end
                    end,
                    canInteract = function()
                        local vaultDoor = shared_config.pacificBank.door_hack[3]
                        return vaultDoor and vaultDoor.isOpened
                            and not shared_config.pacificBank.centerTable.looted
                    end
                }
            }
        })
    end
end

CreateThread(function()
    local bank_config = getConfig()
    if not bank_config then return end

    for i = 1, #bank_config.door_hack do
        local door = bank_config.door_hack[i]
        local isVaultDoor = door.heading ~= nil

        local points = lib.points.new(door.coords, 8, {})

        -- Cache object reference to avoid repeated GetClosestObjectOfType calls
        local cachedObj = nil
        local lastHeadingSet = nil

        function points:nearby()
            self.tick = 1000

            if not cachedObj or not DoesEntityExist(cachedObj) then
                cachedObj = GetClosestObjectOfType(
                    door.coords.x, door.coords.y, door.coords.z,
                    5.0, door.object, false, false, false
                )
            end

            if not cachedObj or cachedObj == 0 then return end

            local cfg = shared_config.pacificBank.door_hack[i]
            if not cfg then return end

            if isVaultDoor then
                local targetHeading = cfg.isOpened and door.heading.open or door.heading.closed
                -- Only update heading if it actually changed
                if lastHeadingSet ~= targetHeading then
                    local curHeading = GetEntityHeading(cachedObj)
                    if math.abs(curHeading - targetHeading) > 1.0 then
                        SetEntityHeading(cachedObj, targetHeading)
                    end
                    lastHeadingSet = targetHeading
                end
            else
                if not cfg.isOpened then
                    local targetHeading = math.floor(door.coords.w + 0.5)
                    if lastHeadingSet ~= targetHeading then
                        SetEntityHeading(cachedObj, targetHeading)
                        lastHeadingSet = targetHeading
                    end
                    if not IsEntityPositionFrozen(cachedObj) then
                        FreezeEntityPosition(cachedObj, true)
                    end
                else
                    if IsEntityPositionFrozen(cachedObj) then
                        FreezeEntityPosition(cachedObj, false)
                        lastHeadingSet = nil
                    end
                end
            end
        end

        function points:onExit()
            cachedObj = nil
            lastHeadingSet = nil
        end

        ox_target:addSphereZone({
            coords = door.scene.coords.xyz,
            radius = 1.0,
            options = {
                {
                    label = isVaultDoor and 'Hack pintu vault' or 'Pasang thermite',
                    icon  = isVaultDoor and 'fa-solid fa-computer' or 'fa-solid fa-fire',
                    distance = 1.5,
                    onSelect = function()
                        hackDoor(i)
                    end,
                    canInteract = function()
                        local cfg = shared_config.pacificBank.door_hack[i]
                        if not cfg or cfg.isOpened then return false end

                        if cfg.checkDoor then
                            local prereq = shared_config.pacificBank.door_hack[cfg.checkDoor]
                            if not prereq or not prereq.isOpened then return false end
                        end

                        return true
                    end
                }
            }
        })
    end
end)

RegisterNetEvent('illegal_pacificBank:sync_config', function(cfg)
    if source == '' then return end

    if cfg.door_hack then
        for i, door in pairs(cfg.door_hack) do
            if shared_config.pacificBank.door_hack[i] then
                shared_config.pacificBank.door_hack[i].isOpened = door.isOpened
            end
        end
    end

    if cfg.trolley then
        for i, trolley in pairs(cfg.trolley) do
            if shared_config.pacificBank.trolley[i] then
                shared_config.pacificBank.trolley[i].looted = trolley.looted
            end
        end
    end

    if cfg.drill then
        for i, drill in pairs(cfg.drill) do
            if shared_config.pacificBank.drill[i] then
                shared_config.pacificBank.drill[i].looted = drill.looted
            end
        end
    end

    if cfg.centerTable and shared_config.pacificBank.centerTable then
        shared_config.pacificBank.centerTable.looted = cfg.centerTable.looted
    end
end)

RegisterNetEvent('illegal_pacificBank:sync_config_data', function(data, options)
    if source == '' then return end
    if not data or type(data) ~= 'table' then return end

    for k, v in pairs(data) do
        if k == 'centerTable' then
            if shared_config.pacificBank.centerTable then
                shared_config.pacificBank.centerTable.looted = v.looted
            end
        else
            shared_config.pacificBank[k] = lib.table.map(shared_config.pacificBank[k], function(item, index)
                return v[index] or item
            end)
        end
    end

    if options == 'reset' then
        resetInteraction()
        resetAllDoors()
        trolleyEntity.pacific = clearTrolley()

    elseif options == 'door_opened' then
        if data.door_hack then
            for i, door in pairs(data.door_hack) do
                if door.isOpened then
                    local doorCfg = shared_config.pacificBank.door_hack[i]
                    if doorCfg then
                        if doorCfg.heading then
                            openVaultDoor(i)
                        else
                            openBarDoor(i)
                        end

                        if i == 3 then
                            pcall(lib.requestModel, `hei_prop_hei_cash_trolly_01`, 1500)
                            setUpBankTrolley()
                            setUpInteraction()
                        end
                    end
                end
            end
        end
    end
end)

-- Sync only specific door that changed (lightweight)
RegisterNetEvent('illegal_pacificBank:sync_door', function(doorIndex, isOpened)
    if source == '' then return end
    if shared_config.pacificBank.door_hack[doorIndex] and doorIndex ~= 3 then
        shared_config.pacificBank.door_hack[doorIndex].isOpened = isOpened
    end
end)

-- Sync only specific trolley that changed
RegisterNetEvent('illegal_pacificBank:sync_trolley', function(trolleyIndex, looted)
    if source == '' then return end
    if shared_config.pacificBank.trolley[trolleyIndex] then
        shared_config.pacificBank.trolley[trolleyIndex].looted = looted
    end
end)

-- Sync only specific drill that changed
RegisterNetEvent('illegal_pacificBank:sync_drill', function(drillIndex, looted)
    if source == '' then return end
    if shared_config.pacificBank.drill[drillIndex] then
        shared_config.pacificBank.drill[drillIndex].looted = looted
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    clearTrolley()
    resetInteraction()
end)

TriggerServerEvent('illegal_pacificBank:request_config')