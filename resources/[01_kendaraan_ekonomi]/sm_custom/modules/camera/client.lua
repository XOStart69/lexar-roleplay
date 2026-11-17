local config = require('config.client').camera

local ORIGIN <const> = vec3(0.0, 0.0, 0.0)
local SIGNS <const> = { -1.0, 1.0 }
local HEAD <const> = 31086
local HOLD <const> = 250

---@class CameraClient
local camera = {}

---@class CameraView
---@field heading number
---@field pitch number
---@field size? number
---@field fov? number
---@field target? vector3
---@field door? integer
---@field cockpit? boolean

---@class CameraSpring
---@field value number
---@field velocity number

---@type number?
local cam
local vehicle = 0
local started = 0
local clip = 0.0
---@type table<string, CameraView>
local bays = {}
local aspect = 16 / 9
local center, half, eye = ORIGIN, ORIGIN, ORIGIN
local lower, upper = ORIGIN, ORIGIN
local bounds, area = config.frame, config.frame
---@type CameraView
local view = config.views.overview
local yaw, pitch, zoom, limit = 0.0, 0.0, 1.0, config.zoom[2]
local fresh = true
local target = ORIGIN
local requested = 'overview'
local cabin, snap, inside = false, false, false
local probed, sensed, round, held = 0, 0, 0, 0
---@type { handle: integer, hit: vector3 | false }[]
local probes = {}
local anchor, axis = ORIGIN, ORIGIN
---@type number?
local cover
local lens = ORIGIN
---@type { wheel: integer, bone: integer }[]
local rims = {}
---@type integer?
local focused

---@type table<string, CameraSpring>
local springs = {
    heading = { value = 0.0, velocity = 0.0 },
    pitch = { value = 0.0, velocity = 0.0 },
    distance = { value = 0.0, velocity = 0.0 },
    reach = { value = 0.0, velocity = 0.0 },
    fov = { value = config.fov, velocity = 0.0 },
}

---@param v vector3
---@return number
local function length(v)
    return math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z)
end

---@param a vector3
---@param b vector3
---@return number
local function dot(a, b)
    return a.x * b.x + a.y * b.y + a.z * b.z
end

---@param spring CameraSpring
---@param goal number
---@param dt number
local function settle(spring, goal, dt)
    if snap then
        spring.value, spring.velocity = goal, 0.0
        return
    end

    local omega = config.stiffness
    local x = omega * dt
    local decay = 1.0 / (1.0 + x + 0.48 * x * x + 0.235 * x * x * x)
    local change = spring.value - goal
    local temp = (spring.velocity + omega * change) * dt
    local value = goal + (change + temp) * decay

    spring.velocity = (spring.velocity - omega * temp) * decay

    if (change > 0.0) == (value < goal) then
        value, spring.velocity = goal, 0.0
    end

    spring.value = value
end

---@param spring CameraSpring
---@param goal number
---@param dt number
local function turn(spring, goal, dt)
    settle(spring, spring.value + (goal - spring.value + 180.0) % 360.0 - 180.0, dt)
end

---@param heading number
---@param tilt number
---@return vector3 right
---@return vector3 up
---@return vector3 away
local function axes(heading, tilt)
    local h, p = math.rad(heading), math.rad(tilt)
    local sh, ch, sp, cp = math.sin(h), math.cos(h), math.sin(p), math.cos(p)

    return vec3(-ch, sh, 0.0), vec3(-sh * sp, -ch * sp, cp), vec3(sh * cp, ch * cp, sp)
end

---@param size number
---@param fov number
---@param right vector3
---@param up vector3
---@param away vector3
---@return number
local function fit(size, fov, right, up, away)
    local tall = math.tan(math.rad(fov) / 2)
    local wide = tall * aspect
    local cx, cy = area.x + area.z - 1.0, 1.0 - area.y - area.w
    local spanX, spanY = (area.z - area.x) * wide, (area.w - area.y) * tall
    local reach = 0.0

    for _, sx in ipairs(SIGNS) do
        for _, sy in ipairs(SIGNS) do
            for _, sz in ipairs(SIGNS) do
                local corner = vec3(half.x * sx, half.y * sy, half.z * sz) * size
                local depth = corner.x * away.x + corner.y * away.y + corner.z * away.z
                local across = math.abs(corner.x * right.x + corner.y * right.y + cx * depth * wide) / spanX
                local rise = math.abs(corner.x * up.x + corner.y * up.y + corner.z * up.z + cy * depth * tall) / spanY

                reach = math.max(reach, math.max(across, rise) + depth)
            end
        end
    end

    return reach * config.padding
end

---@param origin vector3
---@param direction vector3
---@return number
local function clearance(origin, direction)
    local near, far = -math.huge, math.huge

    for axis = 1, 3 do
        local start, delta = origin[axis], direction[axis]

        if math.abs(delta) < 1e-6 then
            if start < lower[axis] or start > upper[axis] then return 0.0 end
        else
            local a, b = (lower[axis] - start) / delta, (upper[axis] - start) / delta

            near, far = math.max(near, math.min(a, b)), math.min(far, math.max(a, b))

            if near > far then return 0.0 end
        end
    end

    return far
end

local function sense()
    if #probes == 0 then return end

    for _, test in ipairs(probes) do
        if test.handle ~= 0 then
            local status, hit, coords = GetShapeTestResult(test.handle)

            if status == 1 then return end

            test.handle, test.hit = 0, status == 2 and hit and coords or false
        end
    end

    local results = probes

    probes = {}

    if probed ~= round then return end

    local nearest

    for _, test in ipairs(results) do
        if test.hit then
            local along = dot(test.hit - anchor, axis)

            nearest = math.min(nearest or along, along)
        end
    end

    if nearest then
        cover, held = nearest, GetGameTimer() + HOLD
    elseif GetGameTimer() >= held then
        cover = nil
    end

    sensed = round
end

---@param from vector3
---@param to vector3
---@param right vector3
---@param up vector3
local function cast(from, to, right, up)
    if #probes > 0 then return end

    local origin = GetOffsetFromEntityInWorldCoords(vehicle, from.x, from.y, from.z)
    local sides = { ORIGIN, right * -config.margin, right * config.margin, up * config.margin }

    probed, anchor = round, origin

    for i, side in ipairs(sides) do
        local spot = to + side
        local goal = GetOffsetFromEntityInWorldCoords(vehicle, spot.x, spot.y, spot.z)

        if i == 1 then
            local span = length(goal - origin)

            axis = span > 0.0 and (goal - origin) * (1.0 / span) or ORIGIN
        end

        probes[i] = {
            handle = StartShapeTestLosProbe(origin.x, origin.y, origin.z, goal.x, goal.y, goal.z, 19, vehicle, 7),
            hit = false,
        }
    end
end

---@param model number
---@return CameraView overview
---@return number? cover
local function compose(model)
    local base, style = config.views.overview, config.aesthetic
    local heading, tilt = base.heading, base.pitch

    if IsThisModelABike(model) or IsThisModelABicycle(model) then
        heading = style.bike
    else
        local ratio = half.z / math.max(half.y, 0.01)
        local tall = math.min(math.max((ratio - style.ratio[1]) / (style.ratio[2] - style.ratio[1]), 0.0), 1.0)

        tilt = style.pitch[1] + (style.pitch[2] - style.pitch[1]) * tall
    end

    local from = GetOffsetFromEntityInWorldCoords(vehicle, center.x, center.y, center.z)
    local options = { heading, -heading, 180.0 - heading, 180.0 + heading }
    local tests = {}

    for i, option in ipairs(options) do
        local right, up, away = axes(option, tilt)
        local reach = fit(1.0, config.fov, right, up, away)
        local spot = center + away * reach
        local to = GetOffsetFromEntityInWorldCoords(vehicle, spot.x, spot.y, spot.z)

        tests[i] = {
            reach = reach,
            handle = StartShapeTestLosProbe(from.x, from.y, from.z, to.x, to.y, to.z, 19, vehicle, 7),
        }
    end

    local pick, score = 1, -math.huge

    for i, test in ipairs(tests) do
        local status, hit, coords = GetShapeTestResult(test.handle)

        while status == 1 do
            Wait(0)
            status, hit, coords = GetShapeTestResult(test.handle)
        end

        test.free = status == 2 and hit and length(coords - from) or test.reach

        local value = math.min(test.free / test.reach, 1.0) - i * 0.001

        if value > score then
            pick, score = i, value
        end
    end

    local chosen = tests[pick]
    local blocked = chosen.free < chosen.reach and chosen.free or nil

    return { heading = options[pick], pitch = tilt, size = base.size }, blocked
end

---@param dt number
---@return boolean drawn
local function exterior(dt)
    local step = snap and 1.0 or math.min(dt * config.speed, 1.0)
    local size = view.size or 1.0

    target += ((view.target or ORIGIN) - target) * step
    area += (bounds - area) * step

    turn(springs.heading, view.heading + yaw, dt)
    settle(springs.pitch, view.pitch + pitch, dt)
    settle(springs.fov, view.fov or config.fov, dt)
    sense()

    local fov = springs.fov.value
    local right, up, away = axes(springs.heading.value, springs.pitch.value)
    local offset = target * half
    local span = length(offset)
    local facing = span > 0.01 and (away.x * offset.x + away.y * offset.y + away.z * offset.z) / span or 1.0
    local reveal = math.min(math.max(0.5 - facing, 0.0), 1.0)
    local whole = fit(1.0, config.fov, axes(bays.overview.heading, bays.overview.pitch))
    local near = whole * (size + (1.0 - size) * reveal)
    local far = whole * config.zoom[2]

    limit = math.max(far / near, config.zoom[1])

    if fresh then
        fresh = false
        zoom = math.min(1.0, config.zoom[1] + (limit - config.zoom[1]) * config.rest)
    end

    local goal = math.min(near * zoom, far)
    settle(springs.distance, goal, dt)
    settle(springs.reach, goal, dt)

    local distance = springs.distance.value
    local widen = far > near and math.min(math.max((distance - near) / (far - near), 0.0), 1.0) or 0.0
    local spread = math.tan(math.rad(fov) / 2) * distance
    local focus = center
        + offset * (1.0 - math.max(reveal, widen))
        - right * ((area.x + area.z - 1.0) * spread * aspect)
        - up * ((1.0 - area.y - area.w) * spread)
    local body = clearance(focus, away)
    local wanted = focus + away * math.max(distance, body)
    local look = GetOffsetFromEntityInWorldCoords(vehicle, focus.x, focus.y, focus.z)

    cast(focus, wanted, right, up)

    if sensed ~= round then
        if inside then
            SetEntityLocallyInvisible(cache.ped)
        end

        return false
    end

    if inside then
        inside = false
        SetCamNearClip(cam --[[@as number]], clip)
        SetVehicleInteriorlight(vehicle, false)
    end

    local room = cover and math.max(cover - config.clearance, 0.5) or math.huge

    if springs.reach.value > room then
        springs.reach.value, springs.reach.velocity = room, 0.0
    end

    local orbit = focus + away * math.min(math.max(springs.reach.value, body), room)
    local position = GetOffsetFromEntityInWorldCoords(vehicle, orbit.x, orbit.y, orbit.z)

    lens = orbit

    SetCamCoord(cam --[[@as number]], position.x, position.y, position.z)
    SetCamFov(cam --[[@as number]], fov)
    PointCamAtCoord(cam --[[@as number]], look.x, look.y, look.z)

    return true
end

---@param dt number
local function cockpit(dt)
    area += (bounds - area) * (snap and 1.0 or math.min(dt * config.speed, 1.0))

    turn(springs.heading, view.heading - yaw, dt)
    settle(springs.pitch, view.pitch + pitch, dt)
    settle(springs.fov, (view.fov or config.fov) * zoom, dt)
    sense()

    local fov = springs.fov.value
    local tangent = math.tan(math.rad(fov) / 2)
    local rx, rz = (area.x + area.z - 1.0) * tangent * aspect, (1.0 - area.y - area.w) * tangent
    local norm = math.sqrt(rx * rx + 1.0 + rz * rz)
    local vx, vy, vz = rx / norm, 1.0 / norm, rz / norm
    local lift = math.sin(math.rad(springs.pitch.value)) / math.sqrt(vy * vy + vz * vz)
    local p = math.asin(lib.math.clamp(lift, -1.0, 1.0)) - math.atan(vz, vy)
    local h = math.rad(springs.heading.value) - math.atan(vx, vy * math.cos(p) - vz * math.sin(p))
    local ahead = eye + vec3(math.sin(h) * math.cos(p), math.cos(h) * math.cos(p), math.sin(p))
    local position = GetOffsetFromEntityInWorldCoords(vehicle, eye.x, eye.y, eye.z)
    local look = GetOffsetFromEntityInWorldCoords(vehicle, ahead.x, ahead.y, ahead.z)

    if not inside then
        inside = true
        SetCamNearClip(cam --[[@as number]], config.cockpit.nearClip)
        SetVehicleInteriorlight(vehicle, true)
    end

    SetEntityLocallyInvisible(cache.ped)
    SetCamCoord(cam --[[@as number]], position.x, position.y, position.z)
    SetCamFov(cam --[[@as number]], fov)
    PointCamAtCoord(cam --[[@as number]], look.x, look.y, look.z)
end

function camera.tick()
    local dt = math.min(GetFrameTime(), 0.05)
    local drawn = true

    if view.cockpit then
        cockpit(dt)
    else
        drawn = exterior(dt)
    end

    if drawn then
        snap = false
    end
end

---@param entity number
---@param name string
---@return integer?
local function sideOf(entity, name)
    local bone = GetEntityBoneIndexByName(entity, name)
    if bone == -1 then return end

    local position = GetWorldPositionOfEntityBone(entity, bone)

    return GetOffsetFromEntityGivenWorldCoords(entity, position.x, position.y, position.z).y < 0 and -1 or 1
end

---@param base CameraView
---@param flip boolean
---@param door integer
---@return CameraView
local function shape(base, flip, door)
    local offset = base.target or ORIGIN

    return {
        heading = flip and 180.0 - base.heading or base.heading,
        pitch = base.pitch,
        size = base.size,
        fov = base.fov,
        target = flip and vec3(offset.x, -offset.y, offset.z) or offset,
        door = door,
    }
end

---@param entity number
function camera.start(entity)
    local model = GetEntityModel(entity)
    local min, max = GetModelDimensions(model)
    local bonnet, boot = sideOf(entity, 'bonnet'), sideOf(entity, 'boot')
    local engine = sideOf(entity, 'engine') or bonnet or 1
    local door = (bonnet == engine or boot ~= engine) and 4 or 5
    local head = GetPedBoneCoords(cache.ped, HEAD, 0.0, 0.0, 0.0)

    vehicle = entity
    started = GetGameTimer()
    aspect = GetAspectRatio(false)
    center = (min + max) / 2
    half = (max - min) / 2
    lower, upper = min - config.clearance, max + config.clearance
    eye = GetOffsetFromEntityGivenWorldCoords(entity, head.x, head.y, head.z) + config.cockpit.eye
    area = bounds

    local overview, blocked = compose(model)
    local count = GetVehicleNumberOfWheels(entity)
    local axles = math.ceil(count / 2)

    rims, focused = {}, nil

    for wheel = 0, count - 1 do
        local axle, side = wheel // 2, wheel % 2 == 0 and 'l' or 'r'
        local name = axle == 0 and ('wheel_%sf'):format(side)
            or axle == axles - 1 and ('wheel_%sr'):format(side)
            or ('wheel_%sm%d'):format(side, axle)

        rims[#rims + 1] = { wheel = wheel, bone = GetEntityBoneIndexByName(entity, name) }
    end

    bays = {
        overview = overview,
        engine = shape(config.views.engine, engine < 0, door),
        trunk = shape(config.views.trunk, engine < 0, door == 4 and 5 or 4),
    }
    view, yaw, pitch, zoom, limit = overview, 0.0, 0.0, 1.0, config.zoom[2]
    fresh = true
    requested, cabin = 'overview', false
    target, cover, round, snap, inside = ORIGIN, blocked, round + 1, true, false
    sensed = round
    cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, config.fov, true, 2)
    clip = GetCamNearClip(cam)

    camera.tick()
    RenderScriptCams(true, false, 0, true, false)
end

---@param left number
---@param top number
---@param right number
---@param bottom number
function camera.frame(left, top, right, bottom)
    if right - left < 0.1 or bottom - top < 0.1 then return end

    bounds = vec4(left, top, right, bottom)

    if GetGameTimer() - started < 500 then
        snap = true
    end
end

---@param name string
---@return CameraView?
local function resolve(name)
    local goal = bays[name] or config.views[name]
    if not goal then return end

    if cabin and not goal.cockpit then return config.views.dashboard end
    if not cabin and goal.cockpit then return config.views.interior end

    return goal
end

---@param goal CameraView?
local function apply(goal)
    if not goal or goal == view then return end

    if view.door then
        SetVehicleDoorShut(vehicle, view.door, false)
    end

    view, yaw, pitch, zoom = goal, 0.0, 0.0, 1.0
    fresh = not goal.cockpit
    snap, cover, round = true, nil, round + 1

    if view.door then
        SetVehicleDoorOpen(vehicle, view.door, false, false)
    end
end

---@param name string
function camera.focus(name)
    requested, focused = name, nil
    apply(resolve(name))
end

---@return boolean cabin
function camera.toggle()
    cabin, focused = not cabin, nil
    apply(resolve(requested))

    return cabin
end

---@return { wheel: integer, x: number, y: number }[]
function camera.wheels()
    local list = {}

    if not cam or view.cockpit then return list end

    for _, rim in ipairs(rims) do
        if rim.bone ~= -1 then
            local world = GetWorldPositionOfEntityBone(vehicle, rim.bone)
            local spot = GetOffsetFromEntityGivenWorldCoords(vehicle, world.x, world.y, world.z)
            local toward = lens - spot
            local side = rim.wheel % 2 == 0 and -1.0 or 1.0

            if toward.x * side / math.max(length(toward), 0.01) > 0.12 then
                local visible, x, y = GetScreenCoordFromWorldCoord(world.x, world.y, world.z)

                if visible then
                    list[#list + 1] = { wheel = rim.wheel, x = x, y = y }
                end
            end
        end
    end

    return list
end

---@param wheel integer?
---@return integer? focused
function camera.focusWheel(wheel)
    local rim = wheel and rims[wheel + 1]

    if not rim or rim.bone == -1 or focused == wheel then
        if focused then
            focused = nil
            apply(resolve(requested))
        end

        return nil
    end

    local base = config.views.wheel
    local world = GetWorldPositionOfEntityBone(vehicle, rim.bone)
    local spot = GetOffsetFromEntityGivenWorldCoords(vehicle, world.x, world.y, world.z) - center
    local side = rim.wheel % 2 == 0 and -1.0 or 1.0

    focused = rim.wheel
    apply({
        heading = side * (spot.y >= 0.0 and base.heading or 180.0 - base.heading),
        pitch = base.pitch,
        size = base.size,
        fov = base.fov,
        target = vec3(spot.x / half.x, spot.y / half.y, spot.z / half.z),
    })

    return focused
end

---@param x number
---@param y number
---@param scroll number
function camera.orbit(x, y, scroll)
    if view.cockpit then
        local setup = config.cockpit

        local turned = yaw + x * config.sensitivity

        yaw = lib.math.clamp(turned, view.heading - setup.heading[2], view.heading - setup.heading[1])
        pitch = lib.math.clamp(pitch + y * config.sensitivity, setup.pitch[1] - view.pitch, setup.pitch[2] - view.pitch)
        zoom = lib.math.clamp(zoom + scroll, setup.zoom[1], setup.zoom[2])
        return
    end

    yaw += x * config.sensitivity
    pitch = lib.math.clamp(pitch + y * config.sensitivity, config.pitch[1] - view.pitch, config.pitch[2] - view.pitch)
    zoom = lib.math.clamp(zoom + scroll, config.zoom[1], limit)
end

---@param keep? boolean
function camera.stop(keep)
    if not cam then return end

    if DoesEntityExist(vehicle) then
        SetVehicleDoorsShut(vehicle, false)

        if inside then
            SetVehicleInteriorlight(vehicle, false)
        end
    end

    inside = false

    if not keep then
        RenderScriptCams(false, false, 0, true, false)
    end

    DestroyCam(cam, false)
    cam = nil
end

return camera
