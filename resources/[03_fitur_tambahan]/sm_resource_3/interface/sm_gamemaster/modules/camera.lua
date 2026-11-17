local config = localmodule 'config'
local state = localmodule 'modules.state'
local util = localmodule 'modules.util'
local keys = localmodule 'modules.keys'

local rad = math.rad
local deg = math.deg
local sin = math.sin
local cos = math.cos
local tan = math.tan
local atan = math.atan
local sqrt = math.sqrt
local abs = math.abs
local max = math.max
local min = math.min
local mfloor = math.floor
local GetGameTimer = GetGameTimer
local PlayerPedId = PlayerPedId
local GetEntityCoords = GetEntityCoords
local DoesEntityExist = DoesEntityExist
local IsEntityAPed = IsEntityAPed
local IsPedDeadOrDying = IsPedDeadOrDying
local GetGameplayCamCoord = GetGameplayCamCoord
local GetGameplayCamRot = GetGameplayCamRot
local GetGameplayCamFov = GetGameplayCamFov
local CreateCam = CreateCam
local SetCamCoord = SetCamCoord
local SetCamRot = SetCamRot
local SetCamFov = SetCamFov
local SetCamActive = SetCamActive
local DoesCamExist = DoesCamExist
local DestroyCam = DestroyCam
local RenderScriptCams = RenderScriptCams
local GetDisabledControlNormal = GetDisabledControlNormal
local StartExpensiveSynchronousShapeTestLosProbe = StartExpensiveSynchronousShapeTestLosProbe
local GetShapeTestResult = GetShapeTestResult

local CAM = config.camera
local START_ALT = CAM.startAltitude
local MOVE_SPEED = CAM.moveSpeed
local SPRINT = CAM.sprintMultiplier
local HEIGHT_FACTOR = CAM.heightFactor
local ZOOM_STEP = CAM.zoomStep
local ROTATE_SPEED = CAM.rotateSpeed
local MOUSE_MULT = 3.0 * CAM.mouseSensitivity / 100.0
local SCROLL_SMOOTH = CAM.scrollSmoothing
local BLEND_IN = CAM.blendInMs
local TRAVEL = CAM.travelMs
local BLEND_OUT = CAM.blendOutMs
local MIN_PITCH = CAM.minPitch
local MAX_PITCH = CAM.maxPitch
local ORBIT_MIN = rad(-89.5)
local ORBIT_MAX = rad(70.0)
local FLAGS_GROUND = 1 | 16

local camera = {}

---@type { from: vector3, to: vector3, startAt: integer, duration: integer }?
local transition = nil
local wheel = 0.0
local rotateToggled = false
local lastMmb = false

---@return boolean
local function mouseRotating()
    local down = keys.down(keys.MMB)

    if state.options.cameraToggle then
        if down and not lastMmb then
            rotateToggled = not rotateToggled
        end

        lastMmb = down

        return rotateToggled
    end

    lastMmb = down

    return down
end

---@return number, number
local function mouseDelta()
    return GetDisabledControlNormal(0, 1), GetDisabledControlNormal(0, 2)
end

function camera.create()
    if state.cam then return end

    local coords = GetEntityCoords(PlayerPedId())
    local start = GetGameplayCamCoord()
    local rot = GetGameplayCamRot(2)

    state.heading = util.wrap360(rot.z)
    state.pitch = util.clamp(rot.x, MIN_PITCH, MAX_PITCH)
    state.fov = GetGameplayCamFov()

    local cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)

    SetCamCoord(cam, start.x, start.y, start.z)
    SetCamRot(cam, state.pitch, 0.0, state.heading, 2)
    SetCamFov(cam, state.fov)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, BLEND_IN, true, true)

    state.cam = cam
    state.camPos = start
    state.follow = nil

    local ground = util.groundZ(coords.x, coords.y, coords.z + 50.0) or coords.z

    transition = {
        from = start,
        to = vector3(coords.x, coords.y, ground + START_ALT),
        startAt = GetGameTimer() + BLEND_IN,
        duration = TRAVEL,
    }

    wheel = 0.0
    rotateToggled = false
end

---@param immediate? boolean
function camera.destroy(immediate)
    local cam = state.cam

    state.cam = nil
    state.follow = nil
    transition = nil
    wheel = 0.0

    if not cam then
        RenderScriptCams(false, false, 0, true, true)
        return
    end

    if immediate then
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(cam, false)
        return
    end

    RenderScriptCams(false, true, BLEND_OUT, true, true)

    SetTimeout(BLEND_OUT + 20, function()
        if DoesCamExist(cam) then
            DestroyCam(cam, false)
        end
    end)
end

---@param entity integer
---@param distance? number
function camera.follow(entity, distance)
    if not DoesEntityExist(entity) then return end

    local coords = GetEntityCoords(entity)
    local height = 2.0
    local pos = state.camPos
    local dx = pos.x - coords.x
    local dy = pos.y - coords.y
    local dz = pos.z - (coords.z + height)
    local horizontal = sqrt(dx * dx + dy * dy)
    local dist = max(3.0, sqrt(horizontal * horizontal + dz * dz))

    if distance then
        dist = distance
    end

    state.follow = {
        entity = entity,
        distance = dist,
        target = dist,
        velocity = 0.0,
        azimuth = atan(dy, dx),
        pitch = util.clamp(atan(dz, max(horizontal, 0.001)), ORBIT_MIN, ORBIT_MAX),
        height = height,
    }
end

---@param target vector3
function camera.flyTo(target)
    if not state.cam then return end

    local pitch = -35.0
    local distance = 14.0
    local h = rad(state.heading)
    local p = rad(pitch)
    local back = cos(p) * distance
    local to = vector3(target.x + sin(h) * back, target.y - cos(h) * back, target.z - sin(p) * distance)

    state.follow = nil
    state.pitch = pitch
    wheel = 0.0
    transition = {
        from = state.camPos,
        to = to,
        startAt = GetGameTimer(),
        duration = 900,
    }
end

function camera.stopFollow()
    state.follow = nil
end

---@param delta number
function camera.wheel(delta)
    if delta == 0 then return end

    local follow = state.follow

    if follow then
        local step = delta > 0 and ZOOM_STEP or -ZOOM_STEP

        follow.target = util.clamp(follow.target + step, 4.0, 200.0)
        return
    end

    wheel = wheel + (delta > 0 and -ZOOM_STEP or ZOOM_STEP)
end

---@return boolean
local function moveKeysDown()
    return keys.down(keys.W) or keys.down(keys.A) or keys.down(keys.S) or keys.down(keys.D) or keys.down(keys.SPACE)
end

---@return number turn, number tilt
local function rotateKeys()
    local turn = 0.0
    local tilt = 0.0

    if keys.down(keys.Q) or keys.down(keys.LEFT) then
        turn = turn - 1.0
    end

    if keys.down(keys.E) or keys.down(keys.RIGHT) then
        turn = turn + 1.0
    end

    if keys.down(keys.R) or keys.down(keys.UP) then
        tilt = tilt + 1.0
    end

    if keys.down(keys.F) or keys.down(keys.DOWN) then
        tilt = tilt - 1.0
    end

    return turn, tilt
end

local function updateTransition()
    local now = GetGameTimer()

    if now < transition.startAt then return end

    local t = (now - transition.startAt) / transition.duration
    local f = util.smootherStep(t)
    local from = transition.from
    local to = transition.to
    local pos = vector3(util.lerp(from.x, to.x, f), util.lerp(from.y, to.y, f), util.lerp(from.z, to.z, f))

    if t >= 1.0 then
        transition = nil
    end

    state.camPos = pos
    SetCamCoord(state.cam, pos.x, pos.y, pos.z)
    SetCamRot(state.cam, state.pitch, 0.0, state.heading, 2)
end

---@param follow GmFollow
---@param dt number
---@param input boolean
local function updateFollow(follow, dt, input)
    local deltaHeading = 0.0
    local deltaPitch = 0.0

    if input then
        local step = rad(ROTATE_SPEED * dt)
        local turn, tilt = rotateKeys()

        deltaHeading = turn * step
        deltaPitch = tilt * step

        if mouseRotating() then
            local lx, ly = mouseDelta()
            local sens = MOUSE_MULT * 0.05

            deltaHeading = deltaHeading - lx * sens
            deltaPitch = deltaPitch - ly * sens
        end
    end

    follow.azimuth = follow.azimuth + deltaHeading
    follow.pitch = util.clamp(follow.pitch - deltaPitch, ORBIT_MIN, ORBIT_MAX)
    follow.distance, follow.velocity = util.smoothDamp(follow.distance, follow.target, follow.velocity, 0.15, 200.0, dt)

    local coords = GetEntityCoords(follow.entity)
    local tx = coords.x
    local ty = coords.y
    local tz = coords.z + follow.height
    local cp = cos(follow.pitch)
    local x = tx + cos(follow.azimuth) * cp * follow.distance
    local y = ty + sin(follow.azimuth) * cp * follow.distance
    local z = tz + sin(follow.pitch) * follow.distance
    local dx = tx - x
    local dy = ty - y
    local dz = tz - z
    local flat = sqrt(dx * dx + dy * dy)
    local headingDeg = deg(atan(-dx, dy))
    local pitchDeg = deg(atan(dz, max(flat, 0.0001)))

    state.heading = util.wrap360(headingDeg)
    state.pitch = pitchDeg
    state.camPos = vector3(x, y, z)

    SetCamCoord(state.cam, x, y, z)
    SetCamRot(state.cam, pitchDeg, 0.0, headingDeg, 2)
end

---@param dt number
---@param input boolean
local function updateFree(dt, input)
    local pos = state.camPos

    if input then
        local step = ROTATE_SPEED * dt
        local turn, tilt = rotateKeys()

        state.heading = state.heading - turn * step
        state.pitch = state.pitch + tilt * step

        if mouseRotating() then
            local lx, ly = mouseDelta()

            state.heading = state.heading - lx * MOUSE_MULT
            state.pitch = state.pitch - ly * MOUSE_MULT
        end

        state.heading = util.wrap360(state.heading)
        state.pitch = util.clamp(state.pitch, MIN_PITCH, MAX_PITCH)
    end

    local mx = 0.0
    local my = 0.0
    local mz = 0.0

    if input then
        local h = rad(state.heading)
        local fx = -sin(h)
        local fy = cos(h)

        if keys.down(keys.W) then
            mx = mx + fx
            my = my + fy
        end

        if keys.down(keys.S) then
            mx = mx - fx
            my = my - fy
        end

        if keys.down(keys.D) then
            mx = mx + fy
            my = my - fx
        end

        if keys.down(keys.A) then
            mx = mx - fy
            my = my + fx
        end

        if keys.down(keys.SPACE) then
            mz = mz + 1.0
        end

        if not keys.ctrl() and (keys.down(keys.C) or keys.down(keys.X)) then
            mz = mz - 1.0
        end
    end

    local length = sqrt(mx * mx + my * my + mz * mz)
    local x = pos.x
    local y = pos.y
    local z = pos.z

    if length > 0.0 then
        local ground = util.groundZ(x, y, z)
        local height = ground and z - ground or z
        local speed = MOVE_SPEED * min(1.0 + max(height, 0.0) / HEIGHT_FACTOR, 45.0)

        if keys.shift() then
            speed = speed * SPRINT
        end

        local scale = speed * dt / length

        x = x + mx * scale
        y = y + my * scale
        z = z + mz * scale
    end

    if wheel ~= 0.0 then
        local p = rad(state.pitch)
        local h = rad(state.heading)
        local cp = cos(p)
        local stepped = util.expStep(wheel, SCROLL_SMOOTH, dt)

        x = x + (-sin(h) * cp) * stepped
        y = y + (cos(h) * cp) * stepped
        z = z + sin(p) * stepped
        wheel = wheel - stepped

        if abs(wheel) < 0.001 then
            wheel = 0.0
        end
    end

    state.camPos = vector3(x, y, z)

    SetCamCoord(state.cam, x, y, z)
    SetCamRot(state.cam, state.pitch, 0.0, state.heading, 2)
end

---@param dt number
function camera.update(dt)
    if not state.cam then return end

    if transition then
        updateTransition()
        return
    end

    local input = not state.typing
    local follow = state.follow

    if follow then
        local entity = follow.entity
        local gone = not DoesEntityExist(entity) or (IsEntityAPed(entity) and IsPedDeadOrDying(entity, true))

        if gone or (input and moveKeysDown()) then
            state.follow = nil
            follow = nil
        end
    end

    if follow then
        wheel = 0.0
        updateFollow(follow, dt, input)
        return
    end

    updateFree(dt, input)
end

---@return vector3, vector3
function camera.ray()
    local p = rad(state.pitch)
    local h = rad(state.heading)
    local cp = cos(p)
    local forward = vector3(-sin(h) * cp, cos(h) * cp, sin(p))
    local right = util.normalize(vector3(forward.y, -forward.x, 0.0))
    local up = util.normalize(util.cross(right, forward))
    local tanFov = tan(rad(state.fov) * 0.5)
    local aspect = state.screenW / state.screenH
    local nx = (state.cursorX - 0.5) * 2.0
    local ny = (state.cursorY - 0.5) * -2.0
    local dir = util.normalize(forward + right * (nx * tanFov * aspect) + up * (ny * tanFov))

    return state.camPos, dir
end

---@param flags? integer
---@param ignore? integer
---@return vector3?, integer
function camera.raycast(flags, ignore)
    local origin, dir = camera.ray()
    local dest = origin + dir * 1500.0
    local handle = StartExpensiveSynchronousShapeTestLosProbe(origin.x, origin.y, origin.z, dest.x, dest.y, dest.z, flags or -1, ignore or PlayerPedId(), 7)
    local _, hit, coords, _, entity = GetShapeTestResult(handle)

    if not hit or hit == 0 then return nil, 0 end

    return coords, entity or 0
end

---@param ignore? integer
---@return vector3?
function camera.ground(ignore)
    local coords = camera.raycast(FLAGS_GROUND, ignore)

    return coords
end

---@return number
function camera.headingInt()
    return mfloor(util.wrap360(state.heading))
end

---@return boolean
function camera.inTransition()
    return transition ~= nil
end

return camera
