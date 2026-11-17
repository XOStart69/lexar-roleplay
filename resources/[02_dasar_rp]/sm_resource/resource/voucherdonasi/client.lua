local config = localmodule 'config.shared'
local QBCore = exports['qb-core']:GetCoreObject()

local function notify(msg, msgType)
    lib.notify({
        description = msg,
        type = msgType or 'inform'
    })
end

local function isInVehicle()
    return IsPedInAnyVehicle(PlayerPedId(), false)
end

local function isDriver()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    return GetPedInVehicleSeat(veh, -1) == ped
end

local function getCurrentVehicle()
    return GetVehiclePedIsIn(PlayerPedId(), false)
end

local function playMechanicAnim()
    local dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@'
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(10)
    end
    TaskPlayAnim(PlayerPedId(), dict, 'machinic_loop_mechandplayer', 8.0, -8.0, -1, 1, 0, false, false, false)
end

local function stopAnim()
    ClearPedTasks(PlayerPedId())
end

local function getClosestVehicle()
    local vehicle, dist = lib.getClosestVehicle(GetEntityCoords(PlayerPedId()), 10.0, false)
    if not vehicle or vehicle == 0 then return nil end
    return vehicle
end

local function useRataKanan()
    if not isInVehicle() then
        return notify(config.messages.notInVehicle, 'error')
    end

    if not isDriver() then
        return notify(config.messages.notDriver, 'error')
    end

    local vehicle = getCurrentVehicle()
    local plate = GetVehicleNumberPlateText(vehicle)

    lib.callback('voucher:server:checkVehicleOwner', false, function(isOwned)
        if not isOwned then
            return notify(config.messages.notOwned, 'error')
        end

        local itemConfig = config.items.voucher_ratnan

        playMechanicAnim()

        if lib.progressBar({
            duration = itemConfig.progressDuration,
            label = itemConfig.progressLabel,
            useWhileDead = false,
            canCancel = false,
            disable = { car = true, move = true, combat = true }
        }) then
            stopAnim()

            local maxEngine = GetNumVehicleMods(vehicle, 11) - 1
            local maxBrakes = GetNumVehicleMods(vehicle, 12) - 1
            local maxTransmission = GetNumVehicleMods(vehicle, 13) - 1
            local maxSuspension = GetNumVehicleMods(vehicle, 15) - 1
            local maxArmor = GetNumVehicleMods(vehicle, 16) - 1

            if maxEngine >= 0 then SetVehicleMod(vehicle, 11, maxEngine, false) end
            if maxBrakes >= 0 then SetVehicleMod(vehicle, 12, maxBrakes, false) end
            if maxTransmission >= 0 then SetVehicleMod(vehicle, 13, maxTransmission, false) end
            if maxSuspension >= 0 then SetVehicleMod(vehicle, 15, maxSuspension, false) end
            if maxArmor >= 0 then SetVehicleMod(vehicle, 16, maxArmor, false) end

            ToggleVehicleMod(vehicle, 18, true)

            TriggerTokenEvent('voucher:server:saveMaxPerformance', plate, {
                modEngine = maxEngine >= 0 and maxEngine or -1,
                modBrakes = maxBrakes >= 0 and maxBrakes or -1,
                modTransmission = maxTransmission >= 0 and maxTransmission or -1,
                modSuspension = maxSuspension >= 0 and maxSuspension or -1,
                modArmor = maxArmor >= 0 and maxArmor or -1,
                modTurbo = true
            })

            notify(config.messages.vehicleUpgraded, 'success')
        else
            stopAnim()
        end
    end, plate)
end

local function useCustomPlat()
    if not isInVehicle() then
        return notify(config.messages.notInVehicle, 'error')
    end

    if not isDriver() then
        return notify(config.messages.notDriver, 'error')
    end

    local vehicle = getCurrentVehicle()
    local currentPlate = GetVehicleNumberPlateText(vehicle)

    lib.callback('voucher:server:checkVehicleOwner', false, function(isOwned)
        if not isOwned then
            return notify(config.messages.notOwned, 'error')
        end

        local input = lib.inputDialog('Custom Plate', {
            {
                type = 'input',
                label = 'Plate Number',
                description = 'Max 8 characters (A-Z, 0-9)',
                placeholder = 'MYPLATE',
                required = true,
                min = config.plate.minLength,
                max = config.plate.maxLength
            }
        })

        if not input then return end

        local newPlate = string.upper(input[1])

        if not string.match(newPlate, config.plate.pattern) then
            return notify(config.messages.invalidPlate, 'error')
        end

        lib.callback('voucher:server:checkPlateAvailable', false, function(isAvailable)
            if not isAvailable then
                return notify(config.messages.plateExists, 'error')
            end

            local itemConfig = config.items.voucher_plat

            playMechanicAnim()

            if lib.progressBar({
                duration = itemConfig.progressDuration,
                label = itemConfig.progressLabel,
                useWhileDead = false,
                canCancel = false,
                disable = { car = true, move = true, combat = true }
            }) then
                stopAnim()
                SetVehicleNumberPlateText(vehicle, newPlate)
                TriggerTokenEvent('voucher:server:updatePlate', currentPlate, newPlate)
                TriggerEvent('sm_vehiclekeys:client:setVehicleOwner', newPlate)
                notify(config.messages.plateInstalled, 'success')
            else
                stopAnim()
            end
        end, newPlate, currentPlate)
    end, currentPlate)
end

local function useFakePlate()
    if isInVehicle() then
        return notify(config.messages.mustExitVehicle, 'error')
    end

    local vehicle = getClosestVehicle()
    if not vehicle then
        return notify(config.messages.noVehicleFound, 'error')
    end

    local currentPlate = GetVehicleNumberPlateText(vehicle)
    local itemConfig = config.items.fakeplate

    playMechanicAnim()

    if lib.progressBar({
        duration = itemConfig.progressDuration,
        label = itemConfig.progressLabel,
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, combat = true }
    }) then
        stopAnim()
        lib.callback('voucher:server:applyFakePlate', false, function(fakePlate)
            if not fakePlate then return end
            SetVehicleNumberPlateText(vehicle, fakePlate)
            TriggerEvent('sm_vehiclekeys:client:setVehicleOwner', fakePlate)
            notify(config.messages.fakeplateInstalled, 'success')
        end, currentPlate)
    else
        stopAnim()
    end
end

local function useOriginalPlate(itemData)
    if isInVehicle() then
        return notify(config.messages.mustExitVehicle, 'error')
    end

    local vehicle = getClosestVehicle()
    if not vehicle then
        return notify(config.messages.noVehicleFound, 'error')
    end

    local metadata = itemData and itemData.metadata or nil
    if not metadata or not metadata.originalPlate then
        return notify(config.messages.notFakeplateItem, 'error')
    end

    local currentPlate = string.gsub(GetVehicleNumberPlateText(vehicle), '^%s*(.-)%s*$', '%1')
    local originalPlate = metadata.originalPlate
    local itemConfig = config.items.originalplate

    playMechanicAnim()

    if lib.progressBar({
        duration = itemConfig.progressDuration,
        label = itemConfig.progressLabel,
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, combat = true }
    }) then
        stopAnim()
        lib.callback('voucher:server:restoreFakePlate', false, function(restoredPlate)
            if not restoredPlate or type(restoredPlate) ~= 'string' then return end
            SetVehicleNumberPlateText(vehicle, restoredPlate)
            TriggerEvent('sm_vehiclekeys:client:setVehicleOwner', restoredPlate)
            notify(config.messages.fakeplateRestored, 'success')
        end, currentPlate, originalPlate)
    else
        stopAnim()
    end
end

RegisterNetEvent('voucher:client:useRataKanan', useRataKanan)
RegisterNetEvent('voucher:client:useCustomPlat', useCustomPlat)
RegisterNetEvent('voucher:client:useFakePlate', useFakePlate)
RegisterNetEvent('voucher:client:useOriginalPlate', function(itemData)
    useOriginalPlate(itemData)
end)