local config = localmodule 'config.shared'
local placement = localmodule 'modules.placement'

local Wait = Wait
local GetGameTimer = GetGameTimer
local GetFrameTime = GetFrameTime
local GetEntityCoords = GetEntityCoords
local GetEntityHeading = GetEntityHeading
local GetEntityRotation = GetEntityRotation
local GetEntityVelocity = GetEntityVelocity
local GetEntityForwardVector = GetEntityForwardVector
local GetEntityHealth = GetEntityHealth
local GetEntityMaxHealth = GetEntityMaxHealth
local GetOffsetFromEntityInWorldCoords = GetOffsetFromEntityInWorldCoords
local SetEntityRotation = SetEntityRotation
local SetEntityVelocity = SetEntityVelocity
local DoesEntityExist = DoesEntityExist
local DeleteEntity = DeleteEntity
local DisableControlAction = DisableControlAction
local GetDisabledControlNormal = GetDisabledControlNormal
local IsDisabledControlJustPressed = IsDisabledControlJustPressed
local HideHudAndRadarThisFrame = HideHudAndRadarThisFrame
local GetCamRot = GetCamRot
local SetCamRot = SetCamRot
local IsEntityDead = IsEntityDead
local IsPedRagdoll = IsPedRagdoll
local IsEntityPlayingAnim = IsEntityPlayingAnim
local HasEntityBeenDamagedByAnyPed = HasEntityBeenDamagedByAnyPed
local TaskPlayAnim = TaskPlayAnim
local ShootSingleBulletBetweenCoordsIgnoreEntity = ShootSingleBulletBetweenCoordsIgnoreEntity
local NetworkGetNetworkIdFromEntity = NetworkGetNetworkIdFromEntity
local mathFloor = math.floor
local mathMax = math.max
local mathMin = math.min
local mathRad = math.rad
local mathSin = math.sin
local mathCos = math.cos
local mathAbs = math.abs

local droneCfg = config.drone
local tabletCfg = droneCfg.tablet
local droneVariants = config.droneVariants
local text = config.text
local keys = config.keys

local GUN_WEAPON = droneCfg.gunWeapon
local GUN_RANGE = 40.0
local MAX_SHOTS = droneCfg.shots
local MAX_BATTERY = droneCfg.battery * 1000
local CONTROL_RANGE = droneCfg.controlRange
local TABLET_RANGE = droneCfg.tabletRange
local MAX_SPEED = droneCfg.maxSpeed
local REVERSE_SPEED = droneCfg.reverseSpeed
local TURN_RATE = droneCfg.turnRate
local ACCELERATION = droneCfg.acceleration
local CAMERA_OFFSET = droneCfg.cameraOffset
local CAMERA_FOV = droneCfg.cameraFov
local CAMERA_SPEED = 4.0
local CHECK_INTERVAL = 250
local MOVE_LIMIT_SQ = 2.0 * 2.0
local DISABLED = { 0, 1, 2, 21, 22, 23, 24, 25, 26, 30, 31, 32, 33, 34, 35, 36, 37, 44, 45, 75, 79, 80, 140, 141, 142, 257, 263, 264 }
local DISABLED_COUNT = #DISABLED
local INTERACT_DISTANCE = 2.0
local SPAWN_TIMEOUT = 5000

local droneShieldHashes, droneVehicleHashes = {}, {}
for label, variant in pairs(droneVariants) do
    droneShieldHashes[label] = joaat(variant.deployed)
    droneVehicleHashes[label] = joaat(variant.vehicle)
end

local drone = {}
local instances = {}
local active
local frameEnabled = interface.init(false)
local frameMounted = false
local frameReady = false
local framePending
local hudMessage = { action = 'update', data = {} }
local hudData = hudMessage.data
local deployKey, exitKey, nightKey, thermalKey

---@param description string
---@param kind? string
local function notify(description, kind)
    lib.notify({ title = text.title, description = description, type = kind or 'error' })
end

---@param value number
---@param low number
---@param high number
---@return number
local function clamp(value, low, high)
    return value < low and low or (value > high and high or value)
end

---@param payload table
local function frameSend(payload)
    if frameReady then
        interface.send(payload)
    end
end

---@param payload table
local function frameOpen(payload)
    if not frameEnabled then return end
    framePending = payload
    if frameMounted then
        return frameSend(payload)
    end
    frameMounted = true
    frameReady = false
    interface.show()
end

local function frameClose()
    framePending = nil
    if not frameMounted then return end
    frameSend({ action = 'close' })
    frameMounted = false
    frameReady = false
    interface.hide()
end

if frameEnabled then
    interface.callback('ready', function(_, cb)
        frameReady = true
        if framePending then
            interface.send(framePending)
        end
        cb({ ok = true })
    end)
end

---@param bind table
---@param fallback string
---@return string
local function keyLabel(bind, fallback)
    local key = bind and bind:getCurrentKey()
    if not key or key == '' or key:match('^%d+$') then
        return fallback
    end
    return key
end

---@param enabled boolean
local function setKeybinds(enabled)
    deployKey:disable(not enabled)
    exitKey:disable(not enabled)
    nightKey:disable(not enabled)
    thermalKey:disable(not enabled)
end

---@param state table
---@return number
local function signalPercent(state)
    local distance = #(GetEntityCoords(state.vehicle) - state.origin)
    return clamp(mathFloor((1.0 - distance / CONTROL_RANGE) * 100), 0, 100)
end

---@param vehicle number
---@return number
local function hullPercent(vehicle)
    local maxHealth = GetEntityMaxHealth(vehicle)
    if maxHealth <= 0 then return 0 end
    return clamp(mathFloor(GetEntityHealth(vehicle) / maxHealth * 100), 0, 100)
end

---@param state table
local function addInteract(state)
    if state.interact or not DoesEntityExist(state.vehicle) then return end
    state.interact = true
    local id = state.id
    exports.rhd_interact:addLocalEntity(state.vehicle, {
        {
            name = 'sm_droneshield_control',
            label = text.controlDrone,
            icon = 'fa-solid fa-gamepad',
            distance = INTERACT_DISTANCE,
            canInteract = function()
                return active == nil
            end,
            onSelect = function()
                drone.control(id)
            end,
        },
        {
            name = 'sm_droneshield_return',
            label = text.returnDrone,
            icon = 'fa-solid fa-box-open',
            distance = INTERACT_DISTANCE,
            canInteract = function()
                return active == nil
            end,
            onSelect = function()
                TriggerTokenEvent('sm_droneshield:server:returnDrone', id)
            end,
        },
    })
end

---@param state table
local function removeInteract(state)
    if not state.interact then return end
    state.interact = false
    if DoesEntityExist(state.vehicle) then
        exports.rhd_interact:removeLocalEntity(state.vehicle)
    end
end

---@param ped number
local function playTablet(ped)
    TaskPlayAnim(ped, tabletCfg.dict, tabletCfg.clip, 2.0, 2.0, -1, 49, 0, false, false, false)
end

---@param ped number
---@return number?
local function startTablet(ped)
    if pcall(lib.requestAnimDict, tabletCfg.dict) then
        playTablet(ped)
    end
    if not pcall(lib.requestModel, tabletCfg.prop) then return nil end
    local coords = GetEntityCoords(ped)
    local prop = CreateObject(tabletCfg.prop, coords.x, coords.y, coords.z, true, true, false)
    SetModelAsNoLongerNeeded(tabletCfg.prop)
    AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, tabletCfg.bone), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 0, true)
    return prop
end

---@param ped number
---@param prop number?
local function stopTablet(ped, prop)
    StopAnimTask(ped, tabletCfg.dict, tabletCfg.clip, 2.0)
    RemoveAnimDict(tabletCfg.dict)
    if prop and DoesEntityExist(prop) then
        DeleteEntity(prop)
    end
end

---@param hidden boolean
local function setHudHidden(hidden)
    LocalPlayer.state:set('droneControl', hidden or nil, false)
    LocalPlayer.state:set('invBusy', hidden, false)
    TriggerEvent('sm_hud:client:setVisible', not hidden)
end

---@param state table
local function exitControl(state)
    if active ~= state then return end
    active = nil
    state.controlling = false
    setKeybinds(false)
    SetNightvision(false)
    SetSeethrough(false)

    if state.cam then
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(state.cam, false)
        state.cam = nil
    end
    ClearFocus()

    local vehicle = state.vehicle
    if DoesEntityExist(vehicle) then
        SetVehicleForwardSpeed(vehicle, 0.0)
        SetVehicleEngineOn(vehicle, false, true, true)
    end

    stopTablet(cache.ped, state.prop)
    state.prop = nil
    frameClose()
    setHudHidden(false)

    if instances[state.id] == state then
        addInteract(state)
    end
end

---@param state table
local function updateHud(state)
    local signal = signalPercent(state)
    local battery = clamp(mathFloor(state.battery / MAX_BATTERY * 100), 0, 100)
    local hull = hullPercent(state.vehicle)
    if signal == hudData.signal and battery == hudData.battery and hull == hudData.hull and state.shots == hudData.shots then
        return signal
    end
    hudData.signal = signal
    hudData.latency = mathFloor(20 + (100 - signal) * 1.2)
    hudData.battery = battery
    hudData.hull = hull
    hudData.shots = state.shots
    frameSend(hudMessage)
    return signal
end

---@param state table
---@param ped number
local function fireGun(state, ped)
    local vehicle = state.vehicle
    local from = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, 0.7, 0.15)
    local rot = GetCamRot(state.cam, 2)
    local pitch, yaw = mathRad(rot.x), mathRad(rot.z)
    local reach = mathCos(pitch) * GUN_RANGE
    ShootSingleBulletBetweenCoordsIgnoreEntity(
        from.x, from.y, from.z,
        from.x - mathSin(yaw) * reach, from.y + mathCos(yaw) * reach, from.z + mathSin(pitch) * GUN_RANGE,
        0, true, GUN_WEAPON, ped, true, false, -1.0, vehicle
    )
    state.shots = state.shots - 1
end

---@param state table
local function controlLoop(state)
    local ped = cache.ped
    local vehicle = state.vehicle
    local cam = state.cam
    local origin = state.origin
    local yaw, pitch = 0.0, 0.0
    local speed = 0.0
    local lastTick = GetGameTimer()
    local nextCheck = 0

    ClearEntityLastDamageEntity(ped)

    while active == state do
        local now = GetGameTimer()
        local dt = GetFrameTime()

        for i = 1, DISABLED_COUNT do
            DisableControlAction(0, DISABLED[i], true)
        end
        HideHudAndRadarThisFrame()

        local throttle = GetDisabledControlNormal(0, 32) - GetDisabledControlNormal(0, 33)
        local steer = GetDisabledControlNormal(0, 34) - GetDisabledControlNormal(0, 35)
        local target = throttle >= 0.0 and throttle * MAX_SPEED or throttle * REVERSE_SPEED
        speed = speed + (target - speed) * mathMin(1.0, dt * ACCELERATION)

        local rot = GetEntityRotation(vehicle, 2)
        local heading = rot.z
        if steer ~= 0.0 then
            heading = heading + steer * TURN_RATE * dt * (speed < -0.1 and -1.0 or 1.0)
            SetEntityRotation(vehicle, rot.x, rot.y, heading, 2, true)
        end

        if mathAbs(speed) > 0.05 then
            local forward = GetEntityForwardVector(vehicle)
            local velocity = GetEntityVelocity(vehicle)
            SetEntityVelocity(vehicle, forward.x * speed, forward.y * speed, velocity.z)
        end

        yaw = clamp(yaw - GetDisabledControlNormal(0, 1) * CAMERA_SPEED, -14.0, 14.0)
        pitch = clamp(pitch - GetDisabledControlNormal(0, 2) * CAMERA_SPEED, -9.0, 9.0)
        SetCamRot(cam, rot.x + pitch, rot.y, heading + yaw, 2)

        if state.shots > 0 and IsDisabledControlJustPressed(0, 24) then
            fireGun(state, ped)
        end

        state.battery = mathMax(0, state.battery - (now - lastTick))
        lastTick = now

        if now >= nextCheck then
            nextCheck = now + CHECK_INTERVAL

            if not DoesEntityExist(vehicle) or GetEntityHealth(vehicle) <= 0 then
                exitControl(state)
                notify(text.droneDestroyed)
                break
            end

            if state.battery <= 0 then
                state.depleted = true
                exitControl(state)
                notify(text.droneDepleted)
                break
            end

            local pos = GetEntityCoords(ped)
            local dx, dy = pos.x - origin.x, pos.y - origin.y
            if IsEntityDead(ped) or IsPedRagdoll(ped) or HasEntityBeenDamagedByAnyPed(ped) or dx * dx + dy * dy > MOVE_LIMIT_SQ then
                exitControl(state)
                break
            end

            if not IsEntityPlayingAnim(ped, tabletCfg.dict, tabletCfg.clip, 3) then
                playTablet(ped)
            end

            if updateHud(state) <= 0 then
                exitControl(state)
                notify(text.droneLost)
                break
            end
        end

        Wait(0)
    end
end

---@param id number
---@return boolean
function drone.control(id)
    if active or placement.isActive() then return false end

    local state = instances[id]
    if not state then return false end

    local vehicle = state.vehicle
    if not DoesEntityExist(vehicle) then
        drone.forget(id)
        return false
    end

    if state.depleted then
        notify(text.droneDepleted)
        return false
    end

    local ped = cache.ped
    if IsEntityDead(ped) or IsPedInAnyVehicle(ped, false) or IsPedRagdoll(ped) then return false end

    removeInteract(state)
    active = state
    state.controlling = true
    state.origin = GetEntityCoords(ped)

    SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
    state.prop = startTablet(ped)
    RequestWeaponAsset(GUN_WEAPON, 31, 0)
    SetVehicleEngineOn(vehicle, true, true, false)
    SetFocusEntity(vehicle)

    local cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    AttachCamToEntity(cam, vehicle, CAMERA_OFFSET.x, CAMERA_OFFSET.y, CAMERA_OFFSET.z, true)
    SetCamFov(cam, CAMERA_FOV)
    SetCamNearClip(cam, 0.001)
    SetCamActive(cam, true)
    RenderScriptCams(true, false, 0, true, true)
    state.cam = cam

    setHudHidden(true)
    setKeybinds(true)

    hudData.signal, hudData.battery, hudData.hull, hudData.shots = nil, nil, nil, nil
    hudData.vision = 'NORMAL'
    frameOpen({
        action = 'open',
        data = {
            totalShots = MAX_SHOTS,
            keys = {
                { key = 'WASD', label = 'Jalan' },
                { key = 'LMB', label = 'Stun gun' },
                { key = keyLabel(deployKey, keys.deploy), label = 'Pasang shield' },
                { key = keyLabel(exitKey, keys.exit), label = 'Keluar' },
                { key = keyLabel(nightKey, keys.night), label = 'Night vision' },
                { key = keyLabel(thermalKey, keys.thermal), label = 'Thermal' },
            },
        },
    })
    updateHud(state)

    CreateThread(function()
        controlLoop(state)
    end)
    return true
end

local function finish()
    local state = active
    if not state or state.finishing then return end
    state.finishing = true

    local vehicle = state.vehicle
    local coords = GetEntityCoords(vehicle)
    local heading = GetEntityHeading(vehicle)
    exitControl(state)

    CreateThread(function()
        local grounded = placement.groundCoords(droneShieldHashes[state.variant], coords, heading) or coords
        local ok = lib.callback.await('sm_droneshield:deployDrone', false, state.id, grounded, heading)
        if ok then
            drone.forget(state.id)
        else
            state.finishing = false
        end
    end)
end

---@param id number
---@param variant string
---@param coords vector3
---@param heading number
---@return boolean
function drone.spawn(id, variant, coords, heading)
    local model = droneVehicleHashes[variant]
    if not model or not pcall(lib.requestModel, model) then
        lib.callback.await('sm_droneshield:registerDrone', false, id, 0)
        return false
    end

    local vehicle = CreateVehicle(model, coords.x, coords.y, coords.z, heading, true, false)
    SetModelAsNoLongerNeeded(model)

    local netId = 0
    local deadline = GetGameTimer() + SPAWN_TIMEOUT
    while vehicle ~= 0 and DoesEntityExist(vehicle) and GetGameTimer() < deadline do
        netId = NetworkGetNetworkIdFromEntity(vehicle)
        if netId ~= 0 then break end
        Wait(25)
    end

    if netId == 0 then
        if vehicle ~= 0 and DoesEntityExist(vehicle) then DeleteEntity(vehicle) end
        lib.callback.await('sm_droneshield:registerDrone', false, id, 0)
        notify(text.failed)
        return false
    end

    SetNetworkIdCanMigrate(netId, false)
    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleOnGroundProperly(vehicle)
    SetVehicleWheelsCanBreak(vehicle, false)
    SetVehicleTyresCanBurst(vehicle, false)
    SetVehicleDoorsLocked(vehicle, 2)
    SetVehicleEngineOn(vehicle, false, true, true)

    if not lib.callback.await('sm_droneshield:registerDrone', false, id, netId) then
        if DoesEntityExist(vehicle) then DeleteEntity(vehicle) end
        notify(text.failed)
        return false
    end

    local state = {
        id = id,
        netId = netId,
        vehicle = vehicle,
        variant = variant,
        shots = MAX_SHOTS,
        battery = MAX_BATTERY,
        depleted = false,
    }
    instances[id] = state
    addInteract(state)
    return true
end

---@param id number
function drone.forget(id)
    local state = instances[id]
    if not state then return end
    if active == state then
        exitControl(state)
    end
    instances[id] = nil
    removeInteract(state)
end

---@return boolean
function drone.controlNearest()
    if active then return false end
    local coords = GetEntityCoords(cache.ped)
    local best, bestDistance
    for id, state in pairs(instances) do
        if DoesEntityExist(state.vehicle) then
            local distance = #(coords - GetEntityCoords(state.vehicle))
            if distance <= TABLET_RANGE and (not bestDistance or distance < bestDistance) then
                best, bestDistance = id, distance
            end
        end
    end
    return best ~= nil and drone.control(best)
end

---@return boolean
function drone.isControlling()
    return active ~= nil
end

function drone.shutdown()
    if active then
        exitControl(active)
    end
    for id in pairs(instances) do
        drone.forget(id)
    end
end

deployKey = lib.addKeybind({
    name = 'sm_droneshield_deploy',
    description = 'Drone: pasang shield',
    defaultKey = keys.deploy,
    disabled = true,
    onPressed = finish,
})

exitKey = lib.addKeybind({
    name = 'sm_droneshield_exit',
    description = 'Drone: keluar kendali',
    defaultKey = keys.exit,
    disabled = true,
    onPressed = function()
        if active then exitControl(active) end
    end,
})

nightKey = lib.addKeybind({
    name = 'sm_droneshield_night',
    description = 'Drone: night vision',
    defaultKey = keys.night,
    disabled = true,
    onPressed = function()
        if not active then return end
        local enabled = not GetUsingnightvision()
        SetSeethrough(false)
        SetNightvision(enabled)
        hudData.vision = enabled and 'NIGHT' or 'NORMAL'
        frameSend(hudMessage)
    end,
})

thermalKey = lib.addKeybind({
    name = 'sm_droneshield_thermal',
    description = 'Drone: thermal',
    defaultKey = keys.thermal,
    disabled = true,
    onPressed = function()
        if not active then return end
        local enabled = not GetUsingseethrough()
        SetNightvision(false)
        SetSeethrough(enabled)
        hudData.vision = enabled and 'THERMAL' or 'NORMAL'
        frameSend(hudMessage)
    end,
})

return drone
