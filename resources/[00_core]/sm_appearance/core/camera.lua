local constants = require "data.constants"

local PRESETS = constants.CAMERA.presets
local ZOOM_ZONES = constants.CAMERA.zoomZones
local LIMITS = constants.CAMERA.limits
local ORBIT = constants.CAMERA.orbit

---@param from number
---@param to number
---@param ratio number
---@return number
local function lerp(from, to, ratio)
    return from * (1.0 - ratio) + to * ratio
end

---@param value number
---@param min number
---@param max number
---@return number
local function clamp(value, min, max)
    return math.min(max, math.max(min, value))
end

---@class OrbitState
---@field target number
---@field anchor vector3
---@field yaw number
---@field targetYaw number
---@field pitch number
---@field targetPitch number

local state = {
    handle = nil,
    active = false,
    suspended = false,
    origin = nil,
    sideX = 0.0,
    sideY = 0.0,
    z = 0.5,
    targetZ = 0.5,
    fov = 50.0,
    targetFov = 50.0,
    heading = 0.0,
    targetHeading = 0.0,
    token = 0,
    ---@type OrbitState?
    orbit = nil
}

---@return number
local function zoomLimit()
    for i = 1, #ZOOM_ZONES do
        if state.targetZ >= ZOOM_ZONES[i].minZ then
            return ZOOM_ZONES[i].minFov
        end
    end

    return ZOOM_ZONES[#ZOOM_ZONES].minFov
end

---@return vector3
local function findOrigin()
    local ped = cache.ped
    local coords = GetEntityCoords(ped)
    local front = GetOffsetFromEntityInWorldCoords(ped, 0.0, LIMITS.distance, 0.0)

    local handle = StartShapeTestCapsule(
        coords.x, coords.y, coords.z + 0.5,
        front.x, front.y, coords.z + 0.5,
        0.4, 23, ped, 0
    )

    local status, hit, hitCoords
    local attempts = 0

    repeat
        status, hit, hitCoords = GetShapeTestResult(handle)
        attempts += 1
        Wait(0)
    until status ~= 1 or attempts > 20

    if status == 2 and hit then
        local distance = #(vec3(hitCoords.x, hitCoords.y, coords.z) - coords)

        if distance >= LIMITS.minDistance and distance <= LIMITS.distance then
            return vec3(hitCoords.x, hitCoords.y, coords.z)
        end
    end

    return vec3(front.x, front.y, coords.z)
end

---@param coords vector3
---@return number x
---@return number y
local function sideDirection(coords)
    local dx = coords.x - state.origin.x
    local dy = coords.y - state.origin.y
    local length = math.sqrt(dx * dx + dy * dy)

    if length == 0.0 then return 0.0, 0.0 end

    return -dy / length, dx / length
end

local function project()
    if not state.handle then return end

    local coords = GetEntityCoords(cache.ped)
    local height = coords.z + state.z
    local shift = 2.0 * LIMITS.distance * math.tan(math.rad(state.fov) * 0.5) * LIMITS.sideShift

    SetCamFov(state.handle, state.fov)
    SetCamCoord(state.handle, state.origin.x, state.origin.y, height)
    PointCamAtCoord(state.handle, coords.x + state.sideX * shift, coords.y + state.sideY * shift, height)
end

---@param target number
---@return vector3
local function headOf(target)
    return GetPedBoneCoords(target, ORBIT.bone, 0.0, 0.0, 0.0)
end

local function projectOrbit()
    local orbit = state.orbit

    if not state.handle or not orbit then return end

    local anchor = orbit.anchor
    local heading = math.rad(GetEntityHeading(orbit.target) + orbit.yaw)
    local pitch = math.rad(orbit.pitch)
    local flat = ORBIT.distance * math.cos(pitch)

    SetCamFov(state.handle, state.fov)
    SetCamCoord(state.handle,
        anchor.x - math.sin(heading) * flat,
        anchor.y + math.cos(heading) * flat,
        anchor.z + ORBIT.height + ORBIT.distance * math.sin(pitch))
    PointCamAtCoord(state.handle, anchor.x, anchor.y, anchor.z + ORBIT.height)
end

local camera = {}

local INTRO_FOV = 1.35

---@param key string
function camera.preset(key)
    local orbit = state.orbit

    if orbit then
        orbit.targetYaw = 0.0
        orbit.targetPitch = ORBIT.pitch
        state.targetFov = ORBIT.fov

        return
    end

    local preset = PRESETS[key]

    if not preset then return end

    state.targetZ = preset.z
    state.targetFov = preset.fov
end

---@param dx number
---@param dy number
function camera.move(dx, dy)
    local orbit = state.orbit

    if orbit then
        orbit.targetYaw = clamp(orbit.targetYaw - dx * ORBIT.turnSpeed, -ORBIT.maxYaw, ORBIT.maxYaw)
        orbit.targetPitch = clamp(orbit.targetPitch + dy * ORBIT.pitchSpeed, ORBIT.minPitch, ORBIT.maxPitch)

        return
    end

    state.targetZ = clamp(state.targetZ + dy * LIMITS.moveSpeed, LIMITS.minZ, LIMITS.maxZ)
    state.targetHeading = state.targetHeading + dx * LIMITS.turnSpeed
end

---@param steps number
function camera.zoom(steps)
    if state.orbit then
        state.targetFov = clamp(state.targetFov + steps * ORBIT.zoomStep, ORBIT.minFov, ORBIT.maxFov)

        return
    end

    state.targetFov = clamp(state.targetFov + steps * LIMITS.zoomStep, zoomLimit(), LIMITS.maxFov)
end

function camera.start()
    local preset = PRESETS.default
    local coords = GetEntityCoords(cache.ped)

    state.orbit = nil
    state.origin = findOrigin()
    state.sideX, state.sideY = sideDirection(coords)
    state.z, state.targetZ = preset.z, preset.z
    state.fov, state.targetFov = math.min(LIMITS.maxFov, preset.fov * INTRO_FOV), preset.fov
    state.heading = GetEntityHeading(cache.ped)
    state.targetHeading = state.heading

    state.handle = CreateCameraWithParams("DEFAULT_SCRIPTED_CAMERA", state.origin.x, state.origin.y,
        coords.z + state.z, 0.0, 0.0, 0.0, state.fov, false, 0)

    SetCamActive(state.handle, true)
    project()

    state.active = true
    state.token += 1

    local token = state.token

    CreateThread(function()
        while state.active and state.token == token do
            if state.suspended then
                Wait(0)
                goto continue
            end

            do
                local frameTime = GetFrameTime()

                state.targetFov = math.max(zoomLimit(), state.targetFov)
                state.z = lerp(state.z, state.targetZ, 10.0 * frameTime)
                state.fov = lerp(state.fov, state.targetFov, 5.0 * frameTime)
                state.heading = lerp(state.heading, state.targetHeading, 5.0 * frameTime)

                SetEntityHeading(cache.ped, state.heading)
                project()
            end

            Wait(0)
            ::continue::
        end
    end)
end

---@param target number
function camera.orbit(target)
    state.orbit = {
        target = target,
        anchor = headOf(target),
        yaw = 0.0,
        targetYaw = 0.0,
        pitch = ORBIT.pitch,
        targetPitch = ORBIT.pitch
    }

    state.fov, state.targetFov = math.min(ORBIT.maxFov, ORBIT.fov * INTRO_FOV), ORBIT.fov

    local anchor = state.orbit.anchor

    state.handle = CreateCameraWithParams("DEFAULT_SCRIPTED_CAMERA", anchor.x, anchor.y, anchor.z,
        0.0, 0.0, 0.0, state.fov, false, 0)

    SetCamActive(state.handle, true)
    projectOrbit()

    state.active = true
    state.token += 1

    local token = state.token

    CreateThread(function()
        while state.active and state.orbit and state.token == token do
            local orbit = state.orbit --[[@as OrbitState]]

            if DoesEntityExist(orbit.target) then
                local frameTime = GetFrameTime()
                local head = headOf(orbit.target)
                local follow = math.min(1.0, ORBIT.follow * frameTime)

                orbit.anchor = vec3(
                    lerp(orbit.anchor.x, head.x, follow),
                    lerp(orbit.anchor.y, head.y, follow),
                    lerp(orbit.anchor.z, head.z, follow)
                )
                orbit.yaw = lerp(orbit.yaw, orbit.targetYaw, 5.0 * frameTime)
                orbit.pitch = lerp(orbit.pitch, orbit.targetPitch, 5.0 * frameTime)
                state.fov = lerp(state.fov, state.targetFov, 5.0 * frameTime)

                projectOrbit()
            end

            Wait(0)
        end
    end)
end

function camera.suspend()
    state.suspended = true
end

function camera.resume()
    state.suspended = false
end

function camera.stop()
    state.active = false
    state.suspended = false
    state.orbit = nil
    state.token += 1

    if state.handle then
        DestroyCam(state.handle, false)
        state.handle = nil
    end
end

return camera
