local config = localmodule 'config.shared'

local Wait = Wait
local GetGameTimer = GetGameTimer
local GetFrameTime = GetFrameTime
local GetEntityCoords = GetEntityCoords
local GetEntityHeading = GetEntityHeading
local GetEntityHeightAboveGround = GetEntityHeightAboveGround
local DoesEntityExist = DoesEntityExist
local DeleteEntity = DeleteEntity
local SetEntityCoordsNoOffset = SetEntityCoordsNoOffset
local SetEntityRotation = SetEntityRotation
local SetEntityVelocity = SetEntityVelocity
local SetEntityLodDist = SetEntityLodDist
local SetCamRot = SetCamRot
local DisableAllControlActions = DisableAllControlActions
local EnableControlAction = EnableControlAction
local GetDisabledControlNormal = GetDisabledControlNormal
local IsDisabledControlPressed = IsDisabledControlPressed
local HideHudAndRadarThisFrame = HideHudAndRadarThisFrame
local StartExpensiveSynchronousShapeTestLosProbe = StartExpensiveSynchronousShapeTestLosProbe
local GetShapeTestResult = GetShapeTestResult
local TestProbeAgainstWater = TestProbeAgainstWater
local SetTimecycleModifierStrength = SetTimecycleModifierStrength
local IsPedDeadOrDying = IsPedDeadOrDying
local IsPedRagdoll = IsPedRagdoll
local IsPedInAnyVehicle = IsPedInAnyVehicle
local IsEntityPlayingAnim = IsEntityPlayingAnim
local TaskPlayAnim = TaskPlayAnim
local GetEntityRotation = GetEntityRotation
local GetEntityVelocity = GetEntityVelocity
local SetEntityLocallyInvisible = SetEntityLocallyInvisible
local NetworkDoesNetworkIdExist = NetworkDoesNetworkIdExist
local NetworkGetEntityFromNetworkId = NetworkGetEntityFromNetworkId
local NetworkGetEntityOwner = NetworkGetEntityOwner
local GetCloudTimeAsInt = GetCloudTimeAsInt
local GetFinalRenderedCamCoord = GetFinalRenderedCamCoord
local UseParticleFxAssetNextCall = UseParticleFxAssetNextCall
local StartParticleFxLoopedOnEntity = StartParticleFxLoopedOnEntity
local TriggerServerEvent = TriggerServerEvent
local mathRad = math.rad
local mathSin = math.sin
local mathCos = math.cos
local mathMin = math.min
local mathMax = math.max
local mathFloor = math.floor
local pcall = pcall

local missileCfg = config.missile
local signalCfg = config.signal
local tabletCfg = config.tablet
local particles = config.particles
local boostParticles = config.boostParticles
local keys = config.keys
local text = config.text

local MISSILE_MODEL = missileCfg.model
local CRUISE_SPEED = missileCfg.speed
local BOOST_SPEED = missileCfg.boostSpeed
local ACCELERATION = missileCfg.acceleration
local MAX_FUEL = missileCfg.fuel
local BOOST_CONSUMPTION = missileCfg.boostConsumption
local TURN_RATE = missileCfg.turnRate
local MOUSE_SENSITIVITY = missileCfg.mouseSensitivity
local MIN_PITCH = missileCfg.minPitch
local MAX_PITCH = missileCfg.maxPitch
local MAX_ROLL = missileCfg.maxRoll
local MAX_FLIGHT_MS = missileCfg.maxFlightTime * 1000
local ARM_DELAY = missileCfg.armDelay
local CAM_OFFSET = missileCfg.camOffset
local WEAK_DISTANCE = signalCfg.weakDistance
local MAX_DISTANCE = signalCfg.maxDistance
local SIGNAL_RANGE = MAX_DISTANCE - WEAK_DISTANCE
local LOST_SCREEN_TIME = signalCfg.lostScreenTime
local LOD_DISTANCE = mathFloor(missileCfg.cullingRadius)

local RAY_FLAGS = 1 | 2 | 4 | 8 | 16 | 256
local HUD_INTERVAL = 100
local GUARD_INTERVAL = 250
local BASE_FUZZ = 0.15
local FUZZ_MODIFIER = 'CAMERA_secuirity_FUZZ'
local VISION_LABELS = { 'NORMAL', 'NIGHT', 'THERMAL' }
local ACTIVE_KEY = 'smMissiles'
local BOOST_POLL_MS = 200
local REMOTE_IDLE_MS = 250
local CORRECTION_RATE = 4.0
local SNAP_DISTANCE_SQ = 60.0 * 60.0
local SOUND_ENABLED = config.launchSound.enabled
local SOUND_VOLUME = config.launchSound.volume
local SOUND_DISTANCE = config.launchSound.hearDistance
local SOUND_UPDATE_MS = 100
local BOOST_KEY = 'smMissileBoost'
local HUD_HIDE_KEY = 'missileControl'
local BOOST_SYNC_INTERVAL = 400
local BOOST_FLAME_SCALE = missileCfg.boostFlameScale or 1.0

local hudEnabled = interface.init(false)
local hudMounted = false
local hudReady = false
local hudPending
local soundCount = 0

local flight
---@type number|false
local launching = false

local boostKey, detonateKey, visionKey

---@param payload table
local function hudSend(payload)
    if hudReady then
        interface.send(payload)
    end
end

local function mountFrame()
    if hudMounted or not hudEnabled then return end
    hudMounted = true
    hudReady = false
    interface.show()
end

local function unmountFrame()
    if not hudMounted or hudPending or soundCount > 0 then return end
    hudMounted = false
    hudReady = false
    interface.hide()
end

---@param payload table
local function hudOpen(payload)
    hudPending = payload
    if hudMounted then
        return hudSend(payload)
    end
    mountFrame()
end

local function hudClose()
    hudPending = nil
    hudSend({ action = 'close' })
    unmountFrame()
end

if hudEnabled then
    interface.callback('ready', function(_, cb)
        hudReady = true
        if hudPending then
            interface.send(hudPending)
        end
        cb('ok')
    end)
end

---@return boolean
local function isIncapacitated()
    local metadata = QBPlayerData.metadata
    return metadata ~= nil and (metadata.isdead or metadata.inlaststand) == true
end

---@param pitch number
---@param yaw number
---@return vector3
local function direction(pitch, yaw)
    local p, y = mathRad(pitch), mathRad(yaw)
    local cp = mathCos(p)
    return vec3(-mathSin(y) * cp, mathCos(y) * cp, mathSin(p))
end

---@param value number
---@param low number
---@param high number
---@return number
local function clamp(value, low, high)
    return value < low and low or (value > high and high or value)
end

local function startTablet()
    local ped = cache.ped
    lib.requestAnimDict(tabletCfg.dict)
    lib.requestModel(tabletCfg.prop)

    local coords = GetEntityCoords(ped)
    local prop = CreateObject(tabletCfg.prop, coords.x, coords.y, coords.z + 0.2, true, true, false)
    SetModelAsNoLongerNeeded(tabletCfg.prop)

    local offset, rotation = tabletCfg.offset, tabletCfg.rotation
    AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, tabletCfg.bone), offset.x, offset.y, offset.z, rotation.x, rotation.y, rotation.z, true, true, false, true, 1, true)
    TaskPlayAnim(ped, tabletCfg.dict, tabletCfg.clip, 3.0, 3.0, -1, 49, 0, false, false, false)

    LocalPlayer.state:set('invBusy', true, false)
    ox_target:disableTargeting(true)

    return prop
end

local gameHudHidden = false

---@param hidden boolean
local function setGameHudHidden(hidden)
    if gameHudHidden == hidden then return end
    gameHudHidden = hidden
    LocalPlayer.state:set(HUD_HIDE_KEY, hidden or nil, false)
    TriggerEvent('sm_hud:client:setVisible', not hidden)
end

---@param prop number?
local function stopTablet(prop)
    local ped = cache.ped
    StopAnimTask(ped, tabletCfg.dict, tabletCfg.clip, 2.0)
    RemoveAnimDict(tabletCfg.dict)
    if prop and DoesEntityExist(prop) then
        DeleteEntity(prop)
    end
    LocalPlayer.state:set('invBusy', false, false)
    ox_target:disableTargeting(false)
    setGameHudHidden(false)
end

---@param state table
local function applyVision(state)
    local mode = state.vision
    SetNightvision(mode == 2)
    SetSeethrough(mode == 3)
end

local KEY_NAMES = { CAPITAL = 'CAPS LOCK', ['1012'] = 'CAPS LOCK' }

---@param bind table
---@param fallback string
---@return string
local function keyLabel(bind, fallback)
    local key = bind:getCurrentKey()
    if not key or key == '' then
        key = fallback
    end
    return KEY_NAMES[key] or (key:match('^%d+$') and (KEY_NAMES[fallback] or fallback)) or key
end

---@param enabled boolean
local function setKeybindsEnabled(enabled)
    boostKey:disable(not enabled)
    detonateKey:disable(not enabled)
    visionKey:disable(not enabled)
end

---@param entity number
---@param list table
---@return table
local function startParticles(entity, list)
    local handles = {}
    for i = 1, #list do
        local fx = list[i]
        if pcall(lib.requestNamedPtfxAsset, fx.asset) then
            UseParticleFxAssetNextCall(fx.asset)
            local offset, rotation = fx.offset, fx.rotation
            local handle = StartParticleFxLoopedOnEntity(fx.name, entity, offset.x, offset.y, offset.z, rotation.x, rotation.y, rotation.z, fx.scale, false, false, false)
            if fx.alpha then
                SetParticleFxLoopedAlpha(handle, fx.alpha)
            end
            handles[#handles + 1] = handle
        end
    end
    return handles
end

---@param handles table?
local function stopParticles(handles)
    if not handles then return end
    for i = 1, #handles do
        RemoveParticleFx(handles[i], false)
    end
end

---@param entity number
---@return table
local function createTrail(entity)
    return { fx = startParticles(entity, particles), smoke = nil, boosting = false }
end

---@param trail table
local function clearTrail(trail)
    stopParticles(trail.fx)
    stopParticles(trail.smoke)
    trail.fx = nil
    trail.smoke = nil
end

---@param entity number
---@param trail table
---@param boosting boolean
local function setBoostVisual(entity, trail, boosting)
    if trail.boosting == boosting then return end
    trail.boosting = boosting

    local handles = trail.fx
    if handles then
        local multiplier = boosting and BOOST_FLAME_SCALE or 1.0
        for i = 1, #handles do
            local fx = particles[i]
            if fx then
                SetParticleFxLoopedScale(handles[i], fx.scale * multiplier)
            end
        end
    end

    if boosting then
        trail.smoke = startParticles(entity, boostParticles)
    else
        stopParticles(trail.smoke)
        trail.smoke = nil
    end
end

---@param state table
---@param reason string
local function endFlight(state, reason)
    if state.ended then return end
    state.ended = true
    flight = nil
    setKeybindsEnabled(false)

    local missile = state.missile
    local cam = state.cam
    local camCoords = GetCamCoord(cam)
    local camRot = GetCamRot(cam, 2)
    DetachCam(cam)
    SetCamCoord(cam, camCoords.x, camCoords.y, camCoords.z)
    SetCamRot(cam, camRot.x, camRot.y, camRot.z, 2)

    local hit = state.hitCoords or (DoesEntityExist(missile) and GetEntityCoords(missile))
    if hit then
        SetFocusPosAndVel(hit.x, hit.y, hit.z, 0.0, 0.0, 0.0)
        AddOwnedExplosion(cache.ped, hit.x, hit.y, hit.z, missileCfg.explosionType, missileCfg.damageScale, true, false, missileCfg.cameraShake)
    end

    clearTrail(state.trail)
    if DoesEntityExist(missile) then
        DeleteEntity(missile)
    end

    TriggerServerEvent('sm_mwmissile:server:finish', state.token)
    hudSend({ action = 'lost', data = { reason = reason } })

    if reason == 'range' or reason == 'operator' or reason == 'timeout' then
        lib.notify({ description = text.signalLost, type = 'error' })
    end

    CreateThread(function()
        local releaseAt = GetGameTimer() + LOST_SCREEN_TIME
        while GetGameTimer() < releaseAt do
            DisableAllControlActions(0)
            EnableControlAction(0, 249, true)
            HideHudAndRadarThisFrame()
            Wait(0)
        end
        SetNightvision(false)
        SetSeethrough(false)
        ClearTimecycleModifier()
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(cam, false)
        ClearFocus()
        stopTablet(state.tablet)
        hudClose()
        launching = false
    end)
end

---@param state table
local function flightLoop(state)
    local missile = state.missile
    local cam = state.cam
    local origin = state.origin
    local ped = cache.ped
    local pitch, yaw, roll = state.pitch, state.yaw, 0.0
    local speed = CRUISE_SPEED
    local fuel = MAX_FUEL
    local position = GetEntityCoords(missile)
    local launchedAt = GetGameTimer()
    local nextHud = 0
    local nextGuard = 0
    local lastFuzz = -1.0
    local boostSynced = false
    local nextBoostSync = 0
    local missileState = Entity(missile).state
    local trail = state.trail

    SetTimecycleModifier(FUZZ_MODIFIER)
    SetTimecycleModifierStrength(BASE_FUZZ)

    while not state.ended do
        local dt = GetFrameTime()
        local now = GetGameTimer()

        DisableAllControlActions(0)
        EnableControlAction(0, 249, true)
        HideHudAndRadarThisFrame()

        local maxTurn = TURN_RATE * dt
        local yawInput = -GetDisabledControlNormal(0, 1) * MOUSE_SENSITIVITY
        local pitchInput = -GetDisabledControlNormal(0, 2) * MOUSE_SENSITIVITY

        if IsDisabledControlPressed(0, 34) then yawInput = yawInput + maxTurn end
        if IsDisabledControlPressed(0, 35) then yawInput = yawInput - maxTurn end
        if IsDisabledControlPressed(0, 32) then pitchInput = pitchInput - maxTurn end
        if IsDisabledControlPressed(0, 33) then pitchInput = pitchInput + maxTurn end

        local yawStep = clamp(yawInput, -maxTurn, maxTurn)
        yaw = (yaw + yawStep) % 360.0
        pitch = clamp(pitch + clamp(pitchInput, -maxTurn, maxTurn), MIN_PITCH, MAX_PITCH)

        local rollTarget = maxTurn > 0 and -(yawStep / maxTurn) * MAX_ROLL or 0.0
        roll = roll + (rollTarget - roll) * mathMin(1.0, dt * 4.0)

        local boosting = state.boosting and fuel > 0.0
        if boosting then
            fuel = mathMax(0.0, fuel - BOOST_CONSUMPTION * dt)
        end

        if boosting ~= trail.boosting then
            setBoostVisual(missile, trail, boosting)
        end

        if boosting ~= boostSynced and now >= nextBoostSync then
            boostSynced = boosting
            nextBoostSync = now + BOOST_SYNC_INTERVAL
            missileState:set(BOOST_KEY, boosting, true)
        end

        local targetSpeed = boosting and BOOST_SPEED or CRUISE_SPEED
        if speed < targetSpeed then
            speed = mathMin(targetSpeed, speed + ACCELERATION * dt)
        elseif speed > targetSpeed then
            speed = mathMax(targetSpeed, speed - ACCELERATION * dt)
        end

        local dir = direction(pitch, yaw)
        local velocity = dir * speed
        local nextPos = position + velocity * dt
        local probeEnd = nextPos + dir * 1.5

        local probe = StartExpensiveSynchronousShapeTestLosProbe(position.x, position.y, position.z, probeEnd.x, probeEnd.y, probeEnd.z, RAY_FLAGS, missile, 7)
        local _, hit, hitCoords = GetShapeTestResult(probe)

        if hit == 1 or hit == true then
            state.hitCoords = hitCoords
            return endFlight(state, 'impact')
        end

        local inWater, waterCoords = TestProbeAgainstWater(position.x, position.y, position.z, probeEnd.x, probeEnd.y, probeEnd.z)
        if inWater then
            state.hitCoords = waterCoords
            return endFlight(state, 'impact')
        end

        position = nextPos
        SetEntityCoordsNoOffset(missile, position.x, position.y, position.z, false, false, false)
        SetEntityRotation(missile, pitch, 0.0, yaw, 2, true)
        SetEntityVelocity(missile, velocity.x, velocity.y, velocity.z)
        SetCamRot(cam, pitch, roll, yaw, 2)

        if state.detonate then
            if now - launchedAt >= ARM_DELAY then
                return endFlight(state, 'detonate')
            end
            state.detonate = false
        end

        local distance = #(position - origin)

        if distance >= MAX_DISTANCE then
            return endFlight(state, 'range')
        end

        if now - launchedAt >= MAX_FLIGHT_MS then
            return endFlight(state, 'fuel')
        end

        local signal = distance <= WEAK_DISTANCE and 1.0 or 1.0 - (distance - WEAK_DISTANCE) / SIGNAL_RANGE

        if now >= nextGuard then
            nextGuard = now + GUARD_INTERVAL

            if not DoesEntityExist(missile) then
                return endFlight(state, 'impact')
            end

            if IsPedDeadOrDying(ped, true) or IsPedRagdoll(ped) or IsPedInAnyVehicle(ped, false) or isIncapacitated() then
                return endFlight(state, 'operator')
            end

            if not IsEntityPlayingAnim(ped, tabletCfg.dict, tabletCfg.clip, 3) then
                TaskPlayAnim(ped, tabletCfg.dict, tabletCfg.clip, 3.0, 3.0, -1, 49, 0, false, false, false)
            end

            local fuzz = BASE_FUZZ + (1.0 - signal) * 0.85
            if fuzz - lastFuzz > 0.02 or lastFuzz - fuzz > 0.02 then
                lastFuzz = fuzz
                SetTimecycleModifierStrength(fuzz)
            end
        end

        if now >= nextHud then
            nextHud = now + HUD_INTERVAL
            local hud = state.hud
            hud.speed = mathFloor(speed * 3.6)
            hud.heading = mathFloor((360.0 - yaw) % 360.0)
            hud.altitude = mathFloor(GetEntityHeightAboveGround(missile))
            hud.distance = mathFloor(distance)
            hud.signal = mathFloor(signal * 100)
            hud.fuel = mathFloor(fuel / MAX_FUEL * 100)
            hud.boosting = boosting
            hud.vision = VISION_LABELS[state.vision]
            hud.timeLeft = mathMax(0, mathFloor((MAX_FLIGHT_MS - (now - launchedAt)) / 1000))
            hud.x = mathFloor(position.x)
            hud.y = mathFloor(position.y)
            hudSend(state.hudMessage)
        end

        Wait(0)
    end
end

---@param origin vector3
---@param yaw number
---@return number?
---@return number?
local function spawnMissile(origin, yaw)
    local dir = direction(0.0, yaw)
    local spawn = origin + dir * missileCfg.spawnForward + vec3(0.0, 0.0, missileCfg.spawnHeight)

    lib.requestModel(MISSILE_MODEL)
    SetFocusPosAndVel(spawn.x, spawn.y, spawn.z, 0.0, 0.0, 0.0)

    local missile = CreateObjectNoOffset(MISSILE_MODEL, spawn.x, spawn.y, spawn.z, true, true, false)
    SetModelAsNoLongerNeeded(MISSILE_MODEL)
    if not missile or missile == 0 then return nil end

    local networked = pcall(lib.waitFor, function()
        return NetworkGetEntityIsNetworked(missile) and NetworkGetNetworkIdFromEntity(missile) ~= 0 or nil
    end, nil, 3000)

    if not networked then
        DeleteEntity(missile)
        return nil
    end

    SetEntityAsMissionEntity(missile, true, true)
    SetEntityInvincible(missile, true)
    SetEntityCollision(missile, false, true)
    SetEntityHasGravity(missile, false)
    SetEntityLodDist(missile, LOD_DISTANCE)
    SetEntityRotation(missile, missileCfg.startPitch, 0.0, yaw, 2, true)

    local netId = NetworkGetNetworkIdFromEntity(missile)
    SetNetworkIdCanMigrate(netId, false)
    NetworkUseHighPrecisionBlending(netId, true)

    return missile, netId
end

---@param token number
---@param prop number|false
---@param message string?
local function abortLaunch(token, prop, message)
    TriggerServerEvent('sm_mwmissile:server:finish', token)
    if prop ~= false then
        stopTablet(prop)
    end
    ClearFocus()
    launching = false
    if message then
        lib.notify({ description = message, type = 'error' })
    end
end

---@param token number
local function launch(token)
    local ped = cache.ped

    if IsPedInAnyVehicle(ped, false) then
        return abortLaunch(token, false, text.inVehicle)
    end

    if IsPedDeadOrDying(ped, true) or isIncapacitated() then
        return abortLaunch(token, false, text.isDead)
    end

    if IsPedSwimming(ped) or IsEntityInWater(ped) then
        return abortLaunch(token, false, text.inWater)
    end

    local prop = startTablet()

    local connected = lib.progressCircle({
        duration = config.connectDuration,
        label = text.connecting,
        position = 'bottom',
        canCancel = true,
        disable = { move = true, car = true, combat = true },
    })

    if not connected or launching ~= token then
        return abortLaunch(token, prop, text.cancelled)
    end

    local origin = GetEntityCoords(ped)
    local yaw = GetEntityHeading(ped)
    local missile, netId = spawnMissile(origin, yaw)

    if not missile then
        lib.print.warn('[sm_mwmissile] objek missile gagal dibuat / tidak ter-network dalam 3 detik')
        return abortLaunch(token, prop, text.failed)
    end

    if not lib.callback.await('sm_mwmissile:register', false, token, netId) then
        if DoesEntityExist(missile) then DeleteEntity(missile) end
        return abortLaunch(token, prop, text.failed)
    end

    local cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    AttachCamToEntity(cam, missile, CAM_OFFSET.x, CAM_OFFSET.y, CAM_OFFSET.z, true)
    SetCamFov(cam, missileCfg.camFov)
    SetCamRot(cam, missileCfg.startPitch, 0.0, yaw, 2)
    SetCamActive(cam, true)
    RenderScriptCams(true, false, 0, true, true)
    SetFocusEntity(missile)
    setGameHudHidden(true)

    local hud = {}
    local state = {
        token = token,
        missile = missile,
        cam = cam,
        tablet = prop,
        origin = origin,
        pitch = missileCfg.startPitch,
        yaw = yaw,
        vision = 1,
        boosting = false,
        detonate = false,
        ended = false,
        trail = createTrail(missile),
        hud = hud,
        hudMessage = { action = 'update', data = hud },
    }

    flight = state
    setKeybindsEnabled(true)

    hudOpen({
        action = 'open',
        data = {
            label = missileCfg.label,
            maxDistance = MAX_DISTANCE,
            soundVolume = config.launchSound.enabled and config.launchSound.volume or 0,
            keys = {
                { key = keyLabel(detonateKey, keys.detonate), label = 'Detonate' },
                { key = keyLabel(boostKey, keys.boost), label = 'Boost' },
                { key = keyLabel(visionKey, keys.vision), label = 'Switch Vision' },
            },
        },
    })

    flightLoop(state)
end

boostKey = lib.addKeybind({
    name = 'sm_mwmissile_boost',
    description = 'Missile: boost',
    defaultKey = keys.boost,
    disabled = true,
    onPressed = function()
        if flight then flight.boosting = true end
    end,
    onReleased = function()
        if flight then flight.boosting = false end
    end,
})

detonateKey = lib.addKeybind({
    name = 'sm_mwmissile_detonate',
    description = 'Missile: detonate',
    defaultKey = keys.detonate,
    disabled = true,
    onPressed = function()
        if flight then flight.detonate = true end
    end,
})

visionKey = lib.addKeybind({
    name = 'sm_mwmissile_vision',
    description = 'Missile: switch vision',
    defaultKey = keys.vision,
    disabled = true,
    onPressed = function()
        local state = flight
        if not state then return end
        state.vision = state.vision % #VISION_LABELS + 1
        applyVision(state)
    end,
})

RegisterNetEvent('sm_mwmissile:client:start', function(token)
    if launching then
        return TriggerServerEvent('sm_mwmissile:server:finish', token)
    end
    launching = token
    launch(token)
end)

RegisterNetEvent('sm_mwmissile:client:abort', function(token)
    local state = flight
    if state and state.token == token then
        endFlight(state, 'timeout')
    elseif launching == token then
        launching = false
    end
end)

local activeIds = {}
local startTimes = {}
local remotes = {}
local remoteWatcher = false
local soundMessage = { action = 'sound', data = { id = 0, volume = 0.0, offset = 0 } }
local soundData = soundMessage.data

---@param netId number
---@param volume number
local function sendSound(netId, volume)
    soundData.id = netId
    soundData.volume = volume
    soundData.offset = GetCloudTimeAsInt() - (startTimes[netId] or GetCloudTimeAsInt())
    hudSend(soundMessage)
end

---@param remote table
local function stopRemoteSound(remote)
    if not remote.soundOn then return end
    remote.soundOn = false
    soundCount = soundCount - 1
    hudSend({ action = 'soundStop', data = { id = remote.netId } })
    unmountFrame()
end

---@param remote table
---@param now number
local function updateRemoteSound(remote, now)
    if now < remote.nextSound then return end
    remote.nextSound = now + SOUND_UPDATE_MS

    local listener = GetFinalRenderedCamCoord()
    local distance = #(remote.pos - listener)

    if distance >= SOUND_DISTANCE then
        return stopRemoteSound(remote)
    end

    local falloff = 1.0 - distance / SOUND_DISTANCE
    local volume = SOUND_VOLUME * falloff * falloff

    if not remote.soundOn then
        remote.soundOn = true
        soundCount = soundCount + 1
        mountFrame()
    end

    sendSound(remote.netId, volume)
end

---@param netId number
---@param entity number
---@return table
local function createRemote(netId, entity)
    lib.requestModel(MISSILE_MODEL)
    local pos = GetEntityCoords(entity)
    local rot = GetEntityRotation(entity, 2)
    local clone = CreateObjectNoOffset(MISSILE_MODEL, pos.x, pos.y, pos.z, false, false, false)
    SetModelAsNoLongerNeeded(MISSILE_MODEL)
    SetEntityCollision(clone, false, false)
    FreezeEntityPosition(clone, true)
    SetEntityLodDist(clone, LOD_DISTANCE)
    SetEntityRotation(clone, rot.x, rot.y, rot.z, 2, false)

    return {
        netId = netId,
        entity = entity,
        clone = clone,
        trail = createTrail(clone),
        pos = pos,
        lastPos = pos,
        lastChange = GetGameTimer(),
        vel = vec3(0.0, 0.0, 0.0),
        nextBoostPoll = 0,
        nextSound = 0,
        soundOn = false,
    }
end

---@param netId number
local function destroyRemote(netId)
    local remote = remotes[netId]
    if not remote then return end
    remotes[netId] = nil
    stopRemoteSound(remote)
    clearTrail(remote.trail)
    if DoesEntityExist(remote.clone) then
        DeleteEntity(remote.clone)
    end
end

---@param remote table
---@param now number
---@param dt number
local function updateRemote(remote, now, dt)
    local entity = remote.entity
    local netPos = GetEntityCoords(entity)
    local moved = netPos - remote.lastPos

    if moved.x ~= 0.0 or moved.y ~= 0.0 or moved.z ~= 0.0 then
        local elapsed = (now - remote.lastChange) * 0.001
        if elapsed >= 0.03 then
            remote.vel = remote.vel + (moved / elapsed - remote.vel) * 0.5
            remote.lastPos = netPos
            remote.lastChange = now
        end
    end

    local syncedVel = GetEntityVelocity(entity)
    local vel = (syncedVel.x * syncedVel.x + syncedVel.y * syncedVel.y + syncedVel.z * syncedVel.z) > 1.0 and syncedVel or remote.vel

    local pos = remote.pos + vel * dt
    local drift = netPos - pos
    if (drift.x * drift.x + drift.y * drift.y + drift.z * drift.z) > SNAP_DISTANCE_SQ then
        pos = netPos
    else
        pos = pos + drift * mathMin(1.0, dt * CORRECTION_RATE)
    end
    remote.pos = pos

    local clone = remote.clone
    SetEntityCoordsNoOffset(clone, pos.x, pos.y, pos.z, false, false, false)
    local rot = GetEntityRotation(entity, 2)
    SetEntityRotation(clone, rot.x, rot.y, rot.z, 2, false)
    SetEntityLocallyInvisible(entity)

    if now >= remote.nextBoostPoll then
        remote.nextBoostPoll = now + BOOST_POLL_MS
        setBoostVisual(clone, remote.trail, Entity(entity).state[BOOST_KEY] == true)
    end

    if SOUND_ENABLED then
        updateRemoteSound(remote, now)
    end
end

local function remoteLoop()
    local myId = cache.playerId

    while #activeIds > 0 do
        local list = activeIds
        local now = GetGameTimer()
        local dt = GetFrameTime()
        local visible = false

        for i = 1, #list do
            local netId = list[i]
            local remote = remotes[netId]
            local entity = NetworkDoesNetworkIdExist(netId) and NetworkGetEntityFromNetworkId(netId) or 0

            if entity ~= 0 and DoesEntityExist(entity) and NetworkGetEntityOwner(entity) ~= myId then
                if remote and remote.entity ~= entity then
                    destroyRemote(netId)
                    remote = nil
                end
                if not remote then
                    remote = createRemote(netId, entity)
                    remotes[netId] = remote
                    now = GetGameTimer()
                end
                updateRemote(remote, now, dt)
                visible = true
            elseif remote then
                destroyRemote(netId)
            end
        end

        Wait(visible and 0 or REMOTE_IDLE_MS)
    end

    for netId in pairs(remotes) do
        destroyRemote(netId)
    end
    remoteWatcher = false
end

---@param value any
local function syncActive(value)
    local entries = type(value) == 'table' and value or {}
    local list = {}
    table.wipe(startTimes)

    for i = 1, #entries do
        local entry = entries[i]
        if type(entry) == 'table' and entry.id then
            list[#list + 1] = entry.id
            startTimes[entry.id] = entry.t
        end
    end

    activeIds = list

    for netId in pairs(remotes) do
        if not startTimes[netId] then
            destroyRemote(netId)
        end
    end

    if #list > 0 and not remoteWatcher then
        remoteWatcher = true
        CreateThread(remoteLoop)
    end
end

AddStateBagChangeHandler(ACTIVE_KEY, 'global', function(_, _, value)
    syncActive(value)
end)

CreateThread(function()
    syncActive(GlobalState[ACTIVE_KEY])
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    for netId in pairs(remotes) do
        destroyRemote(netId)
    end

    local state = flight
    if not state then return end

    state.ended = true
    if state.trail then
        clearTrail(state.trail)
    end
    if DoesEntityExist(state.missile) then
        DeleteEntity(state.missile)
    end
    SetNightvision(false)
    SetSeethrough(false)
    ClearTimecycleModifier()
    RenderScriptCams(false, false, 0, true, true)
    DestroyCam(state.cam, false)
    ClearFocus()
    stopTablet(state.tablet)
end)
