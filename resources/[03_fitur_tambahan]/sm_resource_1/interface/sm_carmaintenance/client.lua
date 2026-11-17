if not interface.init(false) then
    return
end

local Config = localmodule 'config'

local QBCore = exports['qb-core']:GetCoreObject()

local Parts = Config.Parts
local PartOrder = Config.PartOrder
local Penalty = Config.Penalty
local PenaltyBase = Config.PenaltyBase
local Jobs = Config.Jobs
local TickInterval = Config.TickInterval
local SyncInterval = Config.SyncInterval
local BodyImpact = Config.BodyImpact
local MinEngineHealth = Config.MinEngineHealth
local EffectInterval = Config.EffectInterval
local MinSpeedMs = Config.MinSpeedMs
local RepairDuration = Config.RepairDuration
local RepairAnim = Config.RepairAnim
local InspectAnim = Config.InspectAnim
local InspectRange = Config.InspectRange
local AllowedClasses = Config.AllowedClasses

local GetEntitySpeed = GetEntitySpeed
local GetEntityCoords = GetEntityCoords
local GetVehicleNumberPlateText = GetVehicleNumberPlateText
local GetVehicleWheelBrakePressure = GetVehicleWheelBrakePressure
local GetVehicleNumberOfWheels = GetVehicleNumberOfWheels
local SetVehicleHandlingFloat = SetVehicleHandlingFloat
local GetVehicleHandlingFloat = GetVehicleHandlingFloat
local SetVehicleEngineHealth = SetVehicleEngineHealth
local SetVehicleMaxSpeed = SetVehicleMaxSpeed
local GetVehicleEngineHealth = GetVehicleEngineHealth
local GetVehicleBodyHealth = GetVehicleBodyHealth
local DoesEntityExist = DoesEntityExist
local GetEntityModel = GetEntityModel
local GetVehicleClass = GetVehicleClass
local Wait = Wait
local mathFloor = math.floor

local INFO_ID = 'sm_carmaintenance:prompt'

local PART_COUNT = #PartOrder

local HANDLING = {
    brakes = { 'fBrakeForce', 'fHandBrakeForce', 'fTractionCurveMax', 'fTractionCurveMin' },
    clutch = { 'fInitialDriveForce', 'fDriveInertia', 'fClutchChangeRateScaleUpShift', 'fClutchChangeRateScaleDownShift' },
    engine = { 'fInitialDriveMaxFlatVel' }
}

local active = {
    plate = nil,
    parts = nil,
    vehicle = nil,
    netId = nil
}

local pending = nil
local brakeDirty = false
local accum = {}
local baseline = {}
local applied = {}
local lastCoords = nil
local driveThread = false
local powerApplied = false
local inspected = nil
local inspectAnim = false

local frameMounted = false
local frameReady = false
local uiOpen = false
local pendingPayload = nil
local currentZone = nil
local promptVisible = false
local viewPlate = nil
local viewNetId = nil

---@param plate string?
---@return string
local function normalize(plate)
    return plate and plate:gsub('%s+', ''):upper() or ''
end

---@param vehicle integer
---@return boolean
local function isSupported(vehicle)
    return AllowedClasses[GetVehicleClass(vehicle)] == true
end

---@param vehicle integer
---@return string
local function plateOf(vehicle)
    return normalize(GetVehicleNumberPlateText(vehicle))
end

---@param vehicle integer
---@return string
local function vehicleName(vehicle)
    local model = GetEntityModel(vehicle)
    local data = qb_vehicles.hash(model)

    if data and data.name then
        return data.name
    end

    return GetDisplayNameFromVehicleModel(model)
end

local function resetLocals()
    for i = 1, PART_COUNT do
        local part = PartOrder[i]
        accum[part] = 0.0
        baseline[part] = nil
        applied[part] = nil
    end

    lastCoords = nil
end

local function flushBrake()
    if not brakeDirty or not active.parts then return end

    brakeDirty = false
    pending = pending or {}
    pending.brakes = active.parts.brakes
end

local function pushSync()
    if not active.plate or not active.parts or not pending then return end

    TriggerServerEvent('sm_carmaintenance:sync', active.plate, pending, active.netId)
    pending = nil
end

---@param vehicle integer
---@param part string
---@param health number
local function applyEffect(vehicle, part, health)
    local fields = HANDLING[part]
    local config = Parts[part]
    if not config then return end

    local threshold = config.threshold

    if part == 'body' then
        applied.body = health < threshold
        return
    end

    if not fields then return end

    if health >= threshold then
        if applied[part] then
            local backup = baseline[part]

            if backup then
                for i = 1, #fields do
                    local field = fields[i]
                    if backup[field] then
                        SetVehicleHandlingFloat(vehicle, 'CHandlingData', field, backup[field])
                    end
                end
            end

            if part == 'engine' then
                SetVehicleMaxSpeed(vehicle, 0.0)
            end

            applied[part] = nil
        end

        return
    end

    if not baseline[part] then
        local backup = {}

        for i = 1, #fields do
            local field = fields[i]
            backup[field] = GetVehicleHandlingFloat(vehicle, 'CHandlingData', field)
        end

        baseline[part] = backup
    end

    local ratio = health / threshold
    local base = PenaltyBase[part] or 0.0
    local scale = 1.0 - (base + (1.0 - ratio) * (Penalty[part] - base))

    if scale < 0.15 then scale = 0.15 end

    if applied[part] == scale then return end

    local backup = baseline[part]

    for i = 1, #fields do
        local field = fields[i]
        local base = backup[field]

        if base then
            local value

            if field == 'fDriveInertia' then
                value = base * (1.0 + (1.0 - scale) * 0.5)
            elseif field == 'fTractionCurveMax' or field == 'fTractionCurveMin' then
                value = base * (1.0 - (1.0 - scale) * 0.35)
            else
                value = base * scale
            end

            SetVehicleHandlingFloat(vehicle, 'CHandlingData', field, value)
        end
    end

    if part == 'engine' then
        local topSpeed = backup.fInitialDriveMaxFlatVel

        if topSpeed then
            SetVehicleMaxSpeed(vehicle, topSpeed * 0.75 * scale)
        end
    end

    applied[part] = scale
end

---@param vehicle integer
local function restoreAll(vehicle)
    if not DoesEntityExist(vehicle) then return end

    if powerApplied then
        SetVehicleMaxSpeed(vehicle, 0.0)
        powerApplied = false
    end

    for part, backup in pairs(baseline) do
        if applied[part] and backup then
            for field, value in pairs(backup) do
                SetVehicleHandlingFloat(vehicle, 'CHandlingData', field, value)
            end
        end
    end
end

local function startDriveThread()
    if driveThread then return end
    driveThread = true

    CreateThread(function()
        local effectTimer = 0
        local syncTimer = 0
        local lastBody = nil
        brakeDirty = false

        while active.vehicle and cache.seat == -1 do
            local vehicle = active.vehicle
            local parts = active.parts

            if not parts or not DoesEntityExist(vehicle) then
                break
            end

            local speed = GetEntitySpeed(vehicle)

            if speed > MinSpeedMs then
                local coords = GetEntityCoords(vehicle)

                if lastCoords then
                    local travelled = #(coords - lastCoords)

                    for i = 1, PART_COUNT do
                        local part = PartOrder[i]
                        local config = Parts[part]
                        local step = config.distance

                        if step > 0 then
                            local total = accum[part] + travelled

                            if total >= step then
                                local ticks = mathFloor(total / step)
                                total = total - ticks * step

                                local health = parts[part] - config.wear * ticks
                                if health < 0.0 then health = 0.0 end

                                parts[part] = health
                                pending = pending or {}
                                pending[part] = health
                            end

                            accum[part] = total
                        end
                    end
                end

                lastCoords = coords

                local brakeConfig = Parts.brakes
                local pressure = 0.0
                local wheels = GetVehicleNumberOfWheels(vehicle)

                for i = 0, wheels - 1 do
                    pressure = pressure + GetVehicleWheelBrakePressure(vehicle, i)
                end

                if pressure > 0.0 then
                    local health = parts.brakes - brakeConfig.wear * (pressure / (wheels > 0 and wheels or 1))
                    if health < 0.0 then health = 0.0 end

                    parts.brakes = health
                    brakeDirty = true
                end
            else
                lastCoords = nil
            end

            effectTimer = effectTimer + TickInterval

            if effectTimer >= EffectInterval then
                effectTimer = 0

                for i = 1, PART_COUNT do
                    local part = PartOrder[i]
                    applyEffect(vehicle, part, parts[part])
                end

                if applied.engine and baseline.engine then
                    local topSpeed = baseline.engine.fInitialDriveMaxFlatVel

                    if topSpeed then
                        SetVehicleMaxSpeed(vehicle, topSpeed * 0.75 * applied.engine)
                        powerApplied = true
                    end
                elseif powerApplied then
                    SetVehicleMaxSpeed(vehicle, 0.0)
                    powerApplied = false
                end

                if applied.body then
                    local body = GetVehicleBodyHealth(vehicle)

                    if lastBody and body < lastBody - BodyImpact then
                        local ratio = parts.body / Parts.body.threshold
                        local extra = (1.0 - ratio) * Penalty.body * (lastBody - body)

                        SetTimeout(250, function()
                            if not DoesEntityExist(vehicle) then return end

                            local engineHealth = GetVehicleEngineHealth(vehicle) - extra

                            if engineHealth < MinEngineHealth then
                                engineHealth = MinEngineHealth
                            end

                            SetVehicleEngineHealth(vehicle, engineHealth)
                        end)
                    end

                    lastBody = body
                else
                    lastBody = nil
                end
            end

            syncTimer = syncTimer + TickInterval

            if syncTimer >= SyncInterval then
                syncTimer = 0

                flushBrake()

                if pending then
                    pushSync()
                end
            end

            Wait(TickInterval)
        end

        driveThread = false

        flushBrake()

        if pending then
            pushSync()
        end
    end)
end

---@param vehicle integer
local function attach(vehicle)
    if not isSupported(vehicle) then return end

    local plate = plateOf(vehicle)
    if plate == '' then return end

    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    local cached = Entity(vehicle).state.carParts
    local parts

    if cached then
        parts = {}

        for i = 1, PART_COUNT do
            local part = PartOrder[i]
            parts[part] = tonumber(cached[part]) or 100.0
        end
    else
        parts = lib.callback.await('sm_carmaintenance:load', false, plate, netId)
        if not parts then return end

        if cache.vehicle ~= vehicle or cache.seat ~= -1 then return end
    end

    active.plate = plate
    active.parts = parts
    active.vehicle = vehicle
    active.netId = netId

    resetLocals()
    startDriveThread()
end

local function detach()
    local vehicle = active.vehicle
    local plate = active.plate

    flushBrake()

    if plate and pending then
        TriggerServerEvent('sm_carmaintenance:release', plate, pending, active.netId)
        pending = nil
    end

    if vehicle then
        restoreAll(vehicle)
    end

    active.plate = nil
    active.parts = nil
    active.vehicle = nil
    active.netId = nil

    resetLocals()
end

lib.onCache('seat', function(seat)
    if seat == -1 and cache.vehicle then
        attach(cache.vehicle)
    else
        detach()
    end
end)

lib.onCache('vehicle', function(vehicle)
    if not vehicle then
        detach()
    end
end)

---@param vehicle integer
local function openDoors(vehicle)
    if not DoesEntityExist(vehicle) then return end

    inspected = vehicle

    for door = 0, 5 do
        SetVehicleDoorOpen(vehicle, door, false, false)
    end
end

local function closeDoors()
    local vehicle = inspected
    inspected = nil

    if not vehicle or not DoesEntityExist(vehicle) then return end

    for door = 0, 5 do
        SetVehicleDoorShut(vehicle, door, false)
    end
end

local function startInspectAnim()
    if inspectAnim then return end

    lib.requestAnimDict(InspectAnim.dict)

    TaskPlayAnim(cache.ped, InspectAnim.dict, InspectAnim.clip, 3.0, -1.0, -1, 1, 0.0, false, false, false)
    inspectAnim = true
end

local function stopInspectAnim()
    if not inspectAnim then return end

    inspectAnim = false
    StopAnimTask(cache.ped, InspectAnim.dict, InspectAnim.clip, 2.0)
end

local function closeUI()
    if not uiOpen then return end

    closeDoors()
    stopInspectAnim()

    uiOpen = false
    viewPlate = nil
    viewNetId = nil
    interface.focus(false, false)

    if frameMounted then
        interface.hide()
        frameMounted = false
        frameReady = false
    end
end

---@param payload table
local function openUI(payload)
    pendingPayload = payload
    uiOpen = true

    if not frameMounted then
        frameReady = false
        frameMounted = true
        interface.show()
    elseif frameReady then
        interface.send({ action = 'setData', data = payload })
        interface.focus(true, true)
        pendingPayload = nil
    end
end

interface.callback('ready', function(_, cb)
    frameReady = true

    if pendingPayload then
        interface.send({ action = 'setData', data = pendingPayload })
        interface.focus(true, true)
        pendingPayload = nil
    end

    cb('ok')
end)

interface.callback('exit', function(_, cb)
    closeUI()
    cb('ok')
end)

interface.callback('repair', function(data, cb)
    if not data or not data.part or not viewPlate then
        return cb({ success = false })
    end

    local part = data.part
    local plate = viewPlate
    local netId = viewNetId
    local config = Parts[part]

    local ok, reason = lib.callback.await('sm_carmaintenance:canRepair', false, plate, part, netId)

    if not ok then
        lib.notify({ type = 'error', description = reason })
        return cb({ success = false })
    end

    cb({ success = true, closing = true })

    closeUI()

    local anim = config and config.anim or RepairAnim

    CreateThread(function()
        local done = lib.progressBar({
            duration = RepairDuration,
            label = ('Mengganti %s'):format(config and config.label or part),
            useWhileDead = false,
            canCancel = true,
            disable = {
                move = true,
                car = true,
                combat = true
            },
            anim = {
                dict = anim.dict,
                clip = anim.clip,
                flag = anim.flag or 1
            }
        })

        ClearPedTasks(cache.ped)

        if not done then
            return lib.notify({ type = 'error', description = 'Perbaikan dibatalkan' })
        end

        local success, message = lib.callback.await('sm_carmaintenance:repair', false, plate, part, netId)

        lib.notify({
            type = success and 'success' or 'error',
            description = message
        })
    end)
end)

---@param vehicle integer
---@param canRepair boolean
local function showStatus(vehicle, canRepair)
    if not isSupported(vehicle) then return end

    local plate = plateOf(vehicle)
    if plate == '' then return end

    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    local parts = Entity(vehicle).state.carParts

    if not parts then
        parts = lib.callback.await('sm_carmaintenance:load', false, plate, netId)
        if not parts then return end
    end

    viewPlate = plate
    viewNetId = netId

    local list = {}

    for i = 1, PART_COUNT do
        local part = PartOrder[i]
        local config = Parts[part]

        list[i] = {
            name = part,
            label = config.label,
            health = parts[part],
            item = config.item,
            itemLabel = ox_items[config.item] and ox_items[config.item].label or config.label,
            owned = canRepair and (ox_inventory:Search('count', config.item) or 0) or 0,
            amount = config.amount,
            description = config.description,
            effect = config.effect,
            threshold = config.threshold
        }
    end

    if not cache.vehicle then
        openDoors(vehicle)
        startInspectAnim()

        CreateThread(function()
            while uiOpen and inspected == vehicle do
                if not DoesEntityExist(vehicle) then break end
                if #(GetEntityCoords(cache.ped) - GetEntityCoords(vehicle)) > InspectRange then break end

                Wait(500)
            end

            if uiOpen and inspected == vehicle then
                closeUI()
            end
        end)
    end

    local tune
    if GetResourceState('sm_resource_2') == 'started' then
        tune = lib.callback.await('sm_ecutuning:status', false, GetVehicleNumberPlateText(vehicle), netId)
        if type(tune) == 'table' then
            local ok, live = pcall(function() return exports.sm_ecutuning:getTuneStatus(vehicle) end)
            if ok and type(live) == 'table' then
                tune.pops, tune.flame, tune.mode = live.pops, live.flame, live.mode
            end
        else
            tune = nil
        end
    end

    openUI({
        plate = plate,
        vehicle = vehicleName(vehicle),
        canRepair = canRepair,
        parts = list,
        tune = tune
    })
end

exports('showVehicleStatus', showStatus)

AddStateBagChangeHandler('carParts', nil, function(bagName, _, value)
    if type(value) ~= 'table' then return end

    local netId = tonumber(bagName:match('entity:(%d+)'))
    if not netId then return end

    local entity = NetworkDoesEntityExistWithNetworkId(netId) and NetworkGetEntityFromNetworkId(netId)
    if not entity or entity == 0 or not DoesEntityExist(entity) then return end

    local mine = active.parts ~= nil and active.netId == netId

    for i = 1, PART_COUNT do
        local part = PartOrder[i]
        local health = tonumber(value[part])

        if health then
            if mine and health > active.parts[part] then
                active.parts[part] = health
                accum[part] = 0.0
            end

            if mine or applied[part] ~= nil then
                applyEffect(entity, part, health)
            end
        end
    end
end)

RegisterNetEvent('sm_carmaintenance:forceRefresh', function(plate, parts)
    if active.plate ~= plate or not active.parts or type(parts) ~= 'table' then return end

    local vehicle = active.vehicle

    if vehicle and not DoesEntityExist(vehicle) then
        vehicle = nil
    end

    pending = nil

    for i = 1, PART_COUNT do
        local part = PartOrder[i]
        local health = tonumber(parts[part])

        if health then
            active.parts[part] = health
            accum[part] = 0.0

            if vehicle then
                applyEffect(vehicle, part, health)
            end
        end
    end
end)

---@return boolean
local function hidePrompt()
    if not promptVisible then return end

    promptVisible = false
    infoUI.remove(INFO_ID)
end

---@param label string
local function showPrompt(label)
    if promptVisible then return end

    promptVisible = true

    infoUI.show({
        id = INFO_ID,
        title = 'Car Maintenance',
        icon = 'wrench',
        description = label
    })
end

---@param zone ZoneConfig
---@return boolean
local function canRepairHere(zone)
    local job = QBCore.Functions.GetPlayerData().job
    if not job or not job.name then return false end
    if not Jobs[job.name] then return false end
    if job.name ~= zone.job then return false end
    if not job.onduty then return false end

    local grade = job.grade and job.grade.level or 0

    return grade >= zone.grade
end

local function hideZoneInfo()
    if not promptVisible then return end

    promptVisible = false
    infoUI.remove(INFO_ID)
end

---@param zone ZoneConfig
local function showZoneInfo(zone)
    if promptVisible then return end

    promptVisible = true

    infoUI.show({
        id = INFO_ID,
        title = 'Car Maintenance',
        icon = 'wrench',
        description = zone.label
    })
end

---@param vehicle integer
---@return boolean
local function repairTarget(vehicle)
    if not currentZone then return false end
    if not vehicle or not DoesEntityExist(vehicle) then return false end

    return canRepairHere(currentZone)
end

CreateThread(function()
    local zones = Config.Zones

    for i = 1, #zones do
        local zone = zones[i]
        local areas = zone.areas

        for j = 1, #areas do
            local area = areas[j]

            lib.zones.poly({
                points = area.points,
                thickness = area.thickness,
                debug = false,
                onEnter = function()
                    currentZone = zone
                    showZoneInfo(zone)
                end,
                onExit = function()
                    if currentZone ~= zone then return end

                    currentZone = nil
                    hideZoneInfo()

                    if uiOpen then
                        closeUI()
                    end
                end
            })
        end
    end
end)

ox_target:addGlobalVehicle({
    {
        name = 'sm_carmaintenance:inspect',
        label = 'Cek Kondisi Part',
        icon = 'fa-solid fa-screwdriver-wrench',
        distance = 2.5,
        canInteract = function(entity)
            return entity and entity ~= 0 and not uiOpen and isSupported(entity)
        end,
        onSelect = function(data)
            local entity = data and data.entity

            if not entity or not DoesEntityExist(entity) then return end

            showStatus(entity, repairTarget(entity))
        end
    }
})

-- RegisterCommand('cmdebug', function()
--     local vehicle = cache.vehicle

--     if not vehicle then
--         return print('^1[cmdebug] tidak di dalam kendaraan^0')
--     end

--     print('^3================ CAR MAINTENANCE DEBUG ================^0')
--     print(('seat            : %s (harus -1)'):format(tostring(cache.seat)))
--     print(('driveThread     : %s'):format(tostring(driveThread)))
--     print(('active.plate    : %s'):format(tostring(active.plate)))
--     print(('active.vehicle  : %s (cache.vehicle: %s)'):format(tostring(active.vehicle), tostring(vehicle)))

--     if not active.parts then
--         return print('^1active.parts    : NIL  <-- thread tidak jalan / attach gagal^0')
--     end

--     for i = 1, PART_COUNT do
--         local part = PartOrder[i]
--         print(('  %-7s health=%6.2f  applied=%s'):format(
--             part, active.parts[part], tostring(applied[part])
--         ))
--     end

--     print('^3--- nilai handling AKTUAL di game ---^0')

--     for part, fields in pairs(HANDLING) do
--         for i = 1, #fields do
--             local field = fields[i]
--             local now = GetVehicleHandlingFloat(vehicle, 'CHandlingData', field)
--             local base = baseline[part] and baseline[part][field]

--             print(('  %-34s now=%-10.4f asli=%s'):format(field, now, base and ('%.4f'):format(base) or 'belum dibackup'))
--         end
--     end

--     print(('  powerApplied   : %s'):format(tostring(powerApplied)))
--     print(('  speed sekarang : %.1f km/h'):format(GetEntitySpeed(vehicle) * 3.6))
--     print('^3=======================================================^0')
-- end, false)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    closeDoors()

    if inspectAnim then
        ClearPedTasks(cache.ped)
    end

    if active.vehicle then
        restoreAll(active.vehicle)
    end
end)
