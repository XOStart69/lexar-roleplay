local vconfig = localmodule 'config.vehicle'
local hconfig = localmodule 'config.handling'

local handling = {
    float = {
        get = GetVehicleHandlingFloat,
        set = function (vehicle, _type, fieldName, value)
            if tonumber(value) == nil then error("value not number") end
            SetVehicleHandlingFloat(vehicle, _type, fieldName, value + 0.0)
        end
    },
    int = {
        get = GetVehicleHandlingInt,
        set = function (vehicle, _type, fieldName, value)
            if tonumber(value) == nil then error("value not number") end
            SetVehicleHandlingInt(vehicle, _type, fieldName, math.floor(value))
        end
    },
    vector = {
        get = GetVehicleHandlingVector,
        set = function (vehicle, _type, fieldName, value)
            SetVehicleHandlingVector(vehicle, _type, fieldName, value)
        end
    }
}

local function applyHandling(vehicle)
    local model = GetEntityModel(vehicle)
    local custom = hconfig.custom[model]

    if hconfig.floats then
        for k, v in pairs(hconfig.floats) do
            handling.float.set(vehicle, 'CHandlingData', k, v)
        end
    end
    
    if hconfig.ints then
        for k, v in pairs(hconfig.ints) do
            handling.int.set(vehicle, 'CHandlingData', k, v)
        end
    end

    if hconfig.vectors then
        for k, v in pairs(hconfig.vectors) do
            handling.vector.set(vehicle, 'CHandlingData', k, v)
        end
    end

    if custom then
        if custom.floats then
            for k, v in pairs(custom.floats) do
                handling.float.set(vehicle, 'CHandlingData', k, v)
            end
        end
        
        if custom.ints then
            for k, v in pairs(custom.ints) do
                handling.int.set(vehicle, 'CHandlingData', k, v)
            end
        end

        if custom.vectors then
            for k, v in pairs(custom.vectors) do
                handling.vector.set(vehicle, 'CHandlingData', k, v)
            end
        end
    end

    if hconfig.engineMultiplier then
        SetVehicleEnginePowerMultiplier(vehicle, hconfig.engineMultiplier)
    end

    if custom and custom.engineMultiplier then
        SetVehicleEnginePowerMultiplier(vehicle, custom.engineMultiplier)
    end
end

local backups = {}
local DRIFT_MAX_SPEED = 120.0 / 3.6

local function backupHandling(vehicle)
    if backups[vehicle] then return end

    local backup = { floats = {}, ints = {}, vectors = {} }

    for k in pairs(hconfig.floats) do
        backup.floats[k] = handling.float.get(vehicle, 'CHandlingData', k)
    end
    for k in pairs(hconfig.ints) do
        backup.ints[k] = handling.int.get(vehicle, 'CHandlingData', k)
    end
    for k in pairs(hconfig.vectors) do
        backup.vectors[k] = handling.vector.get(vehicle, 'CHandlingData', k)
    end

    backups[vehicle] = backup
end

local function restoreHandling(vehicle)
    local backup = backups[vehicle]
    if not backup then return end
    backups[vehicle] = nil

    if not DoesEntityExist(vehicle) then return end

    for k, v in pairs(backup.floats) do
        handling.float.set(vehicle, 'CHandlingData', k, v)
    end
    for k, v in pairs(backup.ints) do
        handling.int.set(vehicle, 'CHandlingData', k, v)
    end
    for k, v in pairs(backup.vectors) do
        handling.vector.set(vehicle, 'CHandlingData', k, v)
    end

    SetVehicleEnginePowerMultiplier(vehicle, 1.0)
    SetDriftTyresEnabled(vehicle, false)
    SetReduceDriftVehicleSuspension(vehicle, false)
    SetEntityMaxSpeed(vehicle, backup.floats.fInitialDriveMaxFlatVel or 1000.0)
end

local function startDrift(vehicle)
    backupHandling(vehicle)
    applyHandling(vehicle)
    SetDriftTyresEnabled(vehicle, true)
    SetReduceDriftVehicleSuspension(vehicle, true)
end

local function isAllowed(vehicle)
    local class = GetVehicleClass(vehicle)
    local model = GetEntityModel(vehicle)
    return vconfig.allowed_class[class] or vconfig.allowed_models[model]
end

local function toggleDrift(vehicle)
    if not vehicle then return end
    if not isAllowed(vehicle) then return end

    local state = Entity(vehicle).state

    if not state.driftmode then
        state:set('driftmode', true, true)
        lib.print.info('Drift mode: ON')
        lib.notify({
            title = 'Drift Mode',
            description = 'Drift Mode aktif! Tekan & Tahan SHIFT sambil jalan untuk mulai ngesot.',
            type = 'info',
        })
    else
        restoreHandling(vehicle)
        state:set('driftmode', false, true)
        lib.print.info('Drift mode: OFF')
        lib.notify({
            title = 'Drift Mode',
            description = 'Drift Mode dinonaktifkan.',
            type = 'error',
        })
    end
end

CreateThread(function()
    local driftVehicle = nil

    while true do
        local waitTime = 500
        local vehicle = cache.vehicle

        if driftVehicle and driftVehicle ~= vehicle then
            restoreHandling(driftVehicle)
            driftVehicle = nil
        end

        if vehicle and cache.seat == -1 and Entity(vehicle).state.driftmode and isAllowed(vehicle) then
            waitTime = 0

            if IsControlPressed(0, 21) then
                if not driftVehicle then
                    driftVehicle = vehicle
                    startDrift(vehicle)
                end
                SetEntityMaxSpeed(vehicle, DRIFT_MAX_SPEED)
            elseif driftVehicle then
                restoreHandling(driftVehicle)
                driftVehicle = nil
            end
        elseif driftVehicle then
            restoreHandling(driftVehicle)
            driftVehicle = nil
        end

        Wait(waitTime)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end
    for vehicle in pairs(backups) do
        restoreHandling(vehicle)
    end
end)

exports('toggleDrift', toggleDrift)

