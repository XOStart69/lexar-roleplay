local config = localmodule 'config'
local speedLimits = localmodule 'data.speedlimits'

interface.init(false)

local Wait = Wait
local GetGameTimer = GetGameTimer
local GetEntityCoords = GetEntityCoords
local GetEntitySpeed = GetEntitySpeed
local IsEntityAVehicle = IsEntityAVehicle
local IsPlayerFreeAiming = IsPlayerFreeAiming
local DisableControlAction = DisableControlAction
local DisablePlayerFiring = DisablePlayerFiring
local IsControlJustPressed = IsControlJustPressed
local GetDisabledControlNormal = GetDisabledControlNormal
local StartExpensiveSynchronousShapeTestLosProbe = StartExpensiveSynchronousShapeTestLosProbe
local GetShapeTestResult = GetShapeTestResult
local GetGameplayCamRot = GetGameplayCamRot
local GetGameplayCamCoord = GetGameplayCamCoord
local GetCamRot = GetCamRot
local GetCamFov = GetCamFov
local SetCamRot = SetCamRot
local SetCamFov = SetCamFov
local rad, sin, cos, abs, ceil, max, min = math.rad, math.sin, math.cos, math.abs, math.ceil, math.max, math.min

local RADAR_HASH = joaat(config.weapon)
local ANIM_ZOOM = `FirstPersonAiming`
local ANIM_NORMAL = `Default`
local FEET_PER_METER = 3.281

local metric = config.metric
local speedFactor = metric and 3.6 or 2.23694
local speedPrefix = metric and 'kmh' or 'mph'
local rangePrefix = metric and 'm' or 'ft'
local defaultPlate = config.enableALPR and '00000000' or ''
local rangeCfg = config.range
local scopeCfg = config.scope

local holding = false
local zoomed = false
local range = rangeCfg.default
local speedLimit = 65
local currentStreet = ''
local cam
local fov = (scopeCfg.fovMax + scopeCfg.fovMin) * 0.5

local defaultData = {
    speed = '00',
    range = '00',
    speedPrefix = speedPrefix,
    rangePrefix = rangePrefix,
    fastsl = '',
    slowsl = '▼',
    triggeredSpeed = '00',
    plate = defaultPlate,
}

local vehicleData = {
    speedPrefix = speedPrefix,
    rangePrefix = rangePrefix,
}

AddTextEntry(config.weapon, config.label)

---@param entity number
---@return number?
local function asVehicle(entity)
    if not entity or entity == 0 or not DoesEntityExist(entity) then return end
    if IsEntityAVehicle(entity) then return entity end
    if IsEntityAPed(entity) then
        local vehicle = GetVehiclePedIsIn(entity, false)
        if vehicle ~= 0 then return vehicle end
    end
end

---@param origin vector3
---@param rot vector3
---@return number?
local function probeFrom(origin, rot)
    local rx, rz = rad(rot.x), rad(rot.z)
    local horizontal = abs(cos(rx))
    local dx, dy, dz = -sin(rz) * horizontal, cos(rz) * horizontal, sin(rx)
    local skip = #(GetEntityCoords(cache.ped) - origin) + 1.0
    local distance = range / 0.7
    local handle = StartExpensiveSynchronousShapeTestLosProbe(origin.x + dx * skip, origin.y + dy * skip, origin.z + dz * skip,
        origin.x + dx * distance, origin.y + dy * distance, origin.z + dz * distance,
        -1, cache.ped, 7)
    local _, hit, _, _, entity = GetShapeTestResult(handle)
    if hit == 1 or hit == true then
        return asVehicle(entity)
    end
end

---@return number?
local function measureNormal()
    local aiming, target = GetEntityPlayerIsFreeAimingAt(cache.playerId)
    local vehicle = aiming and asVehicle(target)
    if vehicle then return vehicle end
    return probeFrom(GetGameplayCamCoord(), GetGameplayCamRot(2))
end

---@return number?
local function measureZoomed()
    if cam then
        return probeFrom(GetCamCoord(cam), GetCamRot(cam, 2))
    end
    return measureNormal()
end

---@param ped number
local function updateSpeedLimit(ped)
    local coords = GetEntityCoords(ped)
    local street = GetStreetNameFromHashKey(GetStreetNameAtCoord(coords.x, coords.y, coords.z))
    if street ~= currentStreet then
        currentStreet = street
        speedLimit = speedLimits[street] or config.defaultSpeedLimit
    end
end

---@param ped number
---@param vehicle number
local function sendVehicleData(ped, vehicle)
    local speed = ceil(GetEntitySpeed(vehicle) * speedFactor)
    local trigger = metric and ceil(speedLimit * 1.6) or speedLimit
    local fast = speed > trigger

    if fast then
        PlaySoundFrontend(-1, '5_Second_Timer', 'DLC_HEISTS_GENERAL_FRONTEND_SOUNDS', false)
    end

    local plate = config.enableALPR and GetVehicleNumberPlateText(vehicle) or ''
    vehicleData.speed = tostring(speed)
    vehicleData.fastsl = fast and '▲' or ''
    vehicleData.slowsl = (not fast and speed < speedLimit) and '▼' or ''
    vehicleData.triggeredSpeed = tostring(trigger)
    vehicleData.plate = plate

    if not zoomed then
        local meters = #(GetEntityCoords(ped) - GetEntityCoords(vehicle))
        vehicleData.range = tostring(ceil(metric and meters or meters * FEET_PER_METER))
    else
        vehicleData.range = nil
    end

    interface.send(vehicleData)
end

local function hideHud()
    HideHelpTextThisFrame()
    HideHudAndRadarThisFrame()
    for i = 1, 4 do HideHudComponentThisFrame(i) end
    for i = 6, 9 do HideHudComponentThisFrame(i) end
    for i = 11, 13 do HideHudComponentThisFrame(i) end
    HideHudComponentThisFrame(15)
    HideHudComponentThisFrame(18)
    HideHudComponentThisFrame(19)
end

---@param ped number
local function updateScope(ped)
    if not cam then
        SetTimecycleModifier('default')
        SetTimecycleModifierStrength(0.3)
        cam = CreateCam('DEFAULT_SCRIPTED_FLY_CAMERA', true)
        AttachCamToEntity(cam, ped, 0.0, 0.0, 1.0, true)
        SetCamRot(cam, 0.0, 0.0, GetEntityHeading(ped), 2)
        SetCamFov(cam, fov)
        RenderScriptCams(true, false, 0, true, false)
    end

    local zoomValue = (fov - scopeCfg.fovMin) / (scopeCfg.fovMax - scopeCfg.fovMin)
    local axisX = GetDisabledControlNormal(0, 220)
    local axisY = GetDisabledControlNormal(0, 221)
    if axisX ~= 0.0 or axisY ~= 0.0 then
        local rot = GetCamRot(cam, 2)
        local factor = scopeCfg.panSpeed * (zoomValue + 0.1)
        SetCamRot(cam, max(min(20.0, rot.x - axisY * factor), -89.5), 0.0, rot.z - axisX * factor, 2)
    end

    local inVehicle = IsPedSittingInAnyVehicle(ped)
    if IsControlJustPressed(0, inVehicle and 17 or 241) then
        fov = max(fov - scopeCfg.zoomSpeed, scopeCfg.fovMin)
    elseif IsControlJustPressed(0, inVehicle and 16 or 242) then
        fov = min(fov + scopeCfg.zoomSpeed, scopeCfg.fovMax)
    end

    local current = GetCamFov(cam)
    if abs(fov - current) >= 0.1 then
        SetCamFov(cam, current + (fov - current) * 0.05)
    end

    hideHud()
end

local function closeScope()
    if not cam then return end
    ClearTimecycleModifier()
    RenderScriptCams(false, false, 0, true, false)
    DestroyCam(cam, false)
    cam = nil
    fov = (scopeCfg.fovMax + scopeCfg.fovMin) * 0.5
end

local function drawCrosshair()
    SetTextFont(4)
    SetTextScale(0.5, 0.5)
    SetTextOutline()
    SetTextJustification(0)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName('.')
    EndTextCommandDisplayText(0.5, 0.475)
end

---@param playerId number
---@param ignored boolean
local function setIgnored(playerId, ignored)
    SetPoliceIgnorePlayer(playerId, ignored)
    SetEveryoneIgnorePlayer(playerId, ignored)
    SetPlayerCanBeHassledByGangs(playerId, not ignored)
    SetIgnoreLowPriorityShockingEvents(playerId, ignored)
end

---@param ped number
local function pacifyNearbyPeds(ped)
    local origin = GetEntityCoords(ped)
    local peds = GetGamePool('CPed')
    local radius, limit, count = config.pacifyRadius, config.pacifyLimit, 0
    for i = 1, #peds do
        local npc = peds[i]
        if npc ~= ped and not IsPedAPlayer(npc) and #(GetEntityCoords(npc) - origin) < radius and not IsEntityDead(npc) and IsPedHuman(npc) then
            SetBlockingOfNonTemporaryEvents(npc, true)
            SetPedFleeAttributes(npc, 0, false)
            SetPedCombatAttributes(npc, 17, true)
            SetPedAlertness(npc, 0)
            count = count + 1
            if count >= limit then return end
        end
    end
end

local function setZoom(state)
    zoomed = state
    if state then
        interface.send({ zoom = 'open', action = 'close' })
    else
        interface.send({ zoom = 'close', action = 'open' })
        closeScope()
    end
end

local function stop()
    if not holding then return end
    holding = false
end

local session = 0

local function start()
    if holding then return end
    holding = true
    zoomed = false
    session = session + 1
    local token = session

    interface.show()
    interface.send({ action = 'open' })
    interface.send(defaultData)

    local playerId = cache.playerId
    setIgnored(playerId, true)

    CreateThread(function()
        local nextMeasure, nextIdle, nextPacify, nextStreet = 0, 0, 0, 0
        local measureInterval, idleInterval, pacifyInterval = config.measureInterval, config.idleInterval, config.pacifyInterval
        local crosshair = config.enableCrosshair

        while holding and token == session do
            local ped = cache.ped
            local now = GetGameTimer()

            DisableControlAction(0, 24, true)
            DisableControlAction(0, 142, true)
            DisablePlayerFiring(playerId, true)

            local aiming = IsPlayerFreeAiming(playerId)

            if aiming then
                if not zoomed and crosshair then
                    drawCrosshair()
                end

                if now >= nextMeasure then
                    nextMeasure = now + measureInterval
                    local vehicle
                    if zoomed then
                        vehicle = measureZoomed()
                        SetWeaponAnimationOverride(ped, ANIM_ZOOM)
                    else
                        vehicle = measureNormal()
                        SetWeaponAnimationOverride(ped, ANIM_NORMAL)
                    end

                    if now >= nextStreet then
                        nextStreet = now + 3000
                        updateSpeedLimit(ped)
                    end

                    if vehicle then
                        sendVehicleData(ped, vehicle)
                    elseif now >= nextIdle then
                        nextIdle = now + 500
                        interface.send(defaultData)
                    end
                end
            elseif now >= nextIdle then
                nextIdle = now + idleInterval
                interface.send(defaultData)
            end

            if zoomed then
                updateScope(ped)
            end

            if now >= nextPacify then
                nextPacify = now + pacifyInterval
                pacifyNearbyPeds(ped)
            end

            Wait(0)
        end

        if token ~= session then return end
        closeScope()
        zoomed = false
        setIgnored(playerId, false)
        interface.send({ action = 'close', zoom = 'close' })
        interface.hide()
    end)
end

lib.onCache('weapon', function(weapon)
    if weapon == RADAR_HASH then
        start()
    else
        stop()
    end
end)

RegisterCommand('IncreaseRadarRange', function()
    if not holding then return end
    range = min(range + rangeCfg.step, rangeCfg.max)
    lib.notify({ title = 'Radar Gun', description = ('Jarak: %d'):format(range) })
end, false)

RegisterCommand('DecreaseRadarRange', function()
    if not holding then return end
    range = max(range - rangeCfg.step, rangeCfg.min)
    lib.notify({ title = 'Radar Gun', description = ('Jarak: %d'):format(range) })
end, false)

RegisterCommand('AimRadarGun', function()
    if holding then
        setZoom(not zoomed)
    end
end, false)

RegisterKeyMapping('IncreaseRadarRange', 'Radargun: Tambah jarak', 'keyboard', 'right')
RegisterKeyMapping('DecreaseRadarRange', 'Radargun: Kurangi jarak', 'keyboard', 'left')
RegisterKeyMapping('AimRadarGun', 'Radargun: Bidik', 'keyboard', 'Q')

CreateThread(function()
    if cache.weapon == RADAR_HASH then
        start()
    end
end)

AddEventHandler('onClientResourceStop', function(resource)
    if resource == cache.resource and cam then
        RenderScriptCams(false, false, 0, true, false)
        ClearTimecycleModifier()
    end
end)
