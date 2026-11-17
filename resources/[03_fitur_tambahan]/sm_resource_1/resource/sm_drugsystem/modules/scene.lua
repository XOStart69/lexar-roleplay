local config = localmodule 'config.shared'
local props = localmodule 'data.props'
local Render = localmodule 'modules.render'

local ZERO = vec3(0.0, 0.0, 0.0)
local ROTATION_ORDER = 2
local CURSOR_X = 239
local CURSOR_Y = 240
local CLICK = 24
local CANCEL = 177
local CURSOR_ARROW = 1
local CURSOR_OPEN = 3
local CURSOR_GRAB = 4
local PATH_SAMPLES = 24
local PATH_DONE = 0.95
local STIR_STEP = 0.6
local STIR_DEADZONE = 0.01
local DISABLED_CONTROLS = { 1, 2, 24, 25, 37, 44, 140, 141, 142, 177, 199, 200, 257, 263 }
local CANCEL_HINT = '[Backspace] Batal'

---@alias CameraView { offset: vector3, pitch: number, yaw: number, fov: number }

---@class SceneContext
---@field obj DrugClientObject
---@field option? any
---@field amount? integer
---@field deadline integer
---@field startedAt integer
---@field entities integer[]
---@field fx integer[]
---@field outlined integer[]
---@field outlineAlpha? integer
---@field outlineShader? integer
---@field cam integer
---@field hint? string
---@field done? boolean
---@field cleaned? boolean

---@class DragSpec
---@field entity integer
---@field target vector3
---@field radius number
---@field center vector3
---@field height number
---@field reach number
---@field yaw number
---@field rotation? vector3
---@field preview? integer
---@field rest fun()
---@field text string

---@class PourSpec
---@field entity integer
---@field start vector3
---@field center vector3
---@field height number
---@field reach number
---@field yaw number
---@field tilt number
---@field tiltMs integer
---@field radius number
---@field fx { dict: string, name: string, offset: vector3, rotation: vector3, scale: number }
---@field ms integer
---@field text string
---@field pressing? fun(dt: integer)
---@field progress fun(share: number)

---@class PathSpec
---@field entity integer
---@field point fun(t: number): vector3
---@field pose fun(t: number)
---@field text string

---@class StirSpec
---@field tool integer
---@field center vector3
---@field turns number
---@field attach fun(angle: number)
---@field text string

---@class StrikeSpec
---@field tool integer
---@field targets integer[]
---@field cooldown integer
---@field rearm boolean
---@field rest fun()
---@field move fun(x: number, y: number)
---@field hit fun(index: integer): boolean
---@field text fun(): string

---@type SceneContext?
local active

---@param t number
---@return number
local function ease(t)
    return t * t * (3.0 - 2.0 * t)
end

---@param from vector3
---@param to vector3
---@param t number
---@return vector3
local function lerp(from, to, t)
    return from + (to - from) * t
end

---@param current number
---@param target number
---@param delta number
---@return number
local function approach(current, target, delta)
    if current < target then
        return math.min(current + delta, target)
    end

    return math.max(current - delta, target)
end

---@param entity integer
---@param value vector3
---@return vector3
local function offset(entity, value)
    return GetOffsetFromEntityInWorldCoords(entity, value.x, value.y, value.z)
end

---@param value vector3
---@param degrees number
---@return vector3
local function rotateZ(value, degrees)
    local radians = math.rad(degrees)
    local c, s = math.cos(radians), math.sin(radians)

    return vec3(value.x * c - value.y * s, value.x * s + value.y * c, value.z)
end

---@param entity integer
---@param coords vector3
---@param pitch number
---@param roll number
---@param yaw number
local function place(entity, coords, pitch, roll, yaw)
    SetEntityCoordsNoOffset(entity, coords.x, coords.y, coords.z, false, false, false)
    SetEntityRotation(entity, pitch, roll, yaw, ROTATION_ORDER, false)
end

---@param models integer[]
local function preload(models)
    for i = 1, #models do
        lib.requestModel(models[i])
    end
end

---@param ctx SceneContext
---@param model integer
---@param coords vector3
---@param solid? boolean
---@return integer
local function spawn(ctx, model, coords, solid)
    local entity = Render.create(model, coords, solid)

    ctx.entities[#ctx.entities + 1] = entity
    return entity
end

---@param ctx SceneContext
---@param model integer
---@param parent integer
---@param at vector3
---@param rotation? vector3
---@return integer
local function guide(ctx, model, parent, at, rotation)
    local entity = spawn(ctx, model, GetEntityCoords(parent))

    SetEntityAlpha(entity, props.scenes.guideAlpha, false)
    Render.attach(entity, parent, at, rotation)
    return entity
end

---@param ctx SceneContext
---@param fx { dict: string, name: string, offset: vector3, rotation: vector3, scale: number, color?: vector3 }
---@param entity integer
---@return integer
local function loopFx(ctx, fx, entity)
    lib.requestNamedPtfxAsset(fx.dict)
    UseParticleFxAsset(fx.dict)

    local handle = StartParticleFxLoopedOnEntity(fx.name, entity, fx.offset.x, fx.offset.y, fx.offset.z, fx.rotation.x, fx.rotation.y, fx.rotation.z, fx.scale, false, false, false)

    if fx.color then
        SetParticleFxLoopedColour(handle, fx.color.x, fx.color.y, fx.color.z, false)
        SetParticleFxLoopedAlpha(handle, 1.0)
    end

    ctx.fx[#ctx.fx + 1] = handle
    return handle
end

---@param handle? integer
local function stopFx(handle)
    if handle and DoesParticleFxLoopedExist(handle) then
        StopParticleFxLooped(handle, false)
    end
end

---@param ctx SceneContext
---@param color integer[]
local function setOutlineColor(ctx, color)
    SetEntityDrawOutlineColor(color[1], color[2], color[3], ctx.outlineAlpha or color[4])
end

---@param ctx SceneContext
---@param entity integer
---@param enabled boolean
local function outline(ctx, entity, enabled)
    SetEntityDrawOutline(entity, enabled)

    if enabled then
        ctx.outlined[#ctx.outlined + 1] = entity
    end
end

---@param ctx SceneContext
---@param text? string
local function hint(ctx, text)
    if ctx.hint == text then return end

    ctx.hint = text

    if text then
        lib.showTextUI(('%s  %s'):format(text, CANCEL_HINT))
    else
        lib.hideTextUI()
    end
end

---@param ctx SceneContext
---@return boolean
local function step(ctx)
    Wait(0)

    if ctx.done then return false end

    SetMouseCursorThisFrame()
    SetMouseCursorStyle(CURSOR_ARROW)

    for i = 1, #DISABLED_CONTROLS do
        DisableControlAction(0, DISABLED_CONTROLS[i], true)
    end

    if IsDisabledControlJustPressed(0, CANCEL) or GetGameTimer() > ctx.deadline then
        ctx.done = true
    end

    return not ctx.done
end

---@return boolean
local function clicked()
    return IsDisabledControlJustPressed(0, CLICK)
end

---@return boolean
local function holding()
    return IsDisabledControlPressed(0, CLICK)
end

---@return number x
---@return number y
local function cursor()
    return GetDisabledControlNormal(0, CURSOR_X), GetDisabledControlNormal(0, CURSOR_Y)
end

---@param x number
---@param y number
---@return vector3 origin
---@return vector3 direction
local function cursorRay(x, y)
    local rotation = GetFinalRenderedCamRot(ROTATION_ORDER)
    local pitch = math.rad(rotation.x)
    local yaw = math.rad(rotation.z)
    local forward = vec3(-math.sin(yaw) * math.cos(pitch), math.cos(yaw) * math.cos(pitch), math.sin(pitch))
    local right = vec3(math.cos(yaw), math.sin(yaw), 0.0)
    local up = vec3(math.sin(yaw) * math.sin(pitch), -math.cos(yaw) * math.sin(pitch), math.cos(pitch))
    local spread = math.tan(math.rad(GetFinalRenderedCamFov()) / 2.0)
    local direction = forward + right * ((x - 0.5) * 2.0 * spread * GetAspectRatio(false)) - up * ((y - 0.5) * 2.0 * spread)

    return GetFinalRenderedCamCoord(), norm(direction)
end

---@param x number
---@param y number
---@param center vector3
---@param height number
---@param reach number
---@return vector3?
local function planePoint(x, y, center, height, reach)
    local origin, direction = cursorRay(x, y)

    if math.abs(direction.z) < 0.001 then return end

    local distance = (height - origin.z) / direction.z

    if distance <= 0 then return end

    local point = origin + direction * distance
    local dx, dy = point.x - center.x, point.y - center.y
    local length = math.sqrt(dx * dx + dy * dy)

    if length > reach then
        return vec3(center.x + dx / length * reach, center.y + dy / length * reach, height)
    end

    return point
end

---@param point vector3
---@param center vector3
---@param radius number
---@return boolean
local function isAbove(point, center, radius)
    local dx, dy = point.x - center.x, point.y - center.y

    return dx * dx + dy * dy <= radius * radius
end

---@param entity integer
---@param x number
---@param y number
---@return number?
local function hitDistance(entity, x, y)
    local min, max = GetModelDimensions(GetEntityModel(entity))
    local xs, ys, zs = { min.x, max.x }, { min.y, max.y }, { min.z, max.z }
    local left, right, top, bottom

    for i = 1, 2 do
        for j = 1, 2 do
            for k = 1, 2 do
                local corner = GetOffsetFromEntityInWorldCoords(entity, xs[i], ys[j], zs[k])
                local visible, screenX, screenY = GetScreenCoordFromWorldCoord(corner.x, corner.y, corner.z)

                if visible then
                    left = math.min(left or screenX, screenX)
                    right = math.max(right or screenX, screenX)
                    top = math.min(top or screenY, screenY)
                    bottom = math.max(bottom or screenY, screenY)
                end
            end
        end
    end

    if not left then return end

    local dx = math.max(left - x, 0.0, x - right) * GetAspectRatio(false)
    local dy = math.max(top - y, 0.0, y - bottom)

    return math.sqrt(dx * dx + dy * dy)
end

---@param entity integer
---@param x number
---@param y number
---@return boolean
local function isPointed(entity, x, y)
    local distance = hitDistance(entity, x, y)

    return distance ~= nil and distance <= props.scenes.pickPadding
end

---@param entities integer[]
---@param x number
---@param y number
---@return integer?
local function nearest(entities, x, y)
    local best, bestDistance

    for i = 1, #entities do
        local distance = hitDistance(entities[i], x, y)

        if distance and distance <= props.scenes.pickPadding and (not bestDistance or distance < bestDistance) then
            best, bestDistance = i, distance
        end
    end

    return best
end

---@param ctx SceneContext
---@param fn fun(): boolean
---@return boolean
local function waitFor(ctx, fn)
    while step(ctx) do
        if fn() then return true end
    end

    return false
end

---@param ctx SceneContext
---@param ms number
---@param fn fun(t: number)
---@return boolean
local function tween(ctx, ms, fn)
    local start = GetGameTimer()

    return waitFor(ctx, function()
        local t = math.min((GetGameTimer() - start) / ms, 1.0)

        fn(t)
        return t >= 1.0
    end)
end

---@param ctx SceneContext
---@param ms number
---@return boolean
local function hold(ctx, ms)
    return tween(ctx, ms, function() end)
end

---@param ctx SceneContext
---@param entity integer
---@param to vector3
---@param ms number
---@return boolean
local function glide(ctx, entity, to, ms)
    local from = GetEntityCoords(entity)

    return tween(ctx, ms, function(t)
        local coords = lerp(from, to, ease(t))

        SetEntityCoordsNoOffset(entity, coords.x, coords.y, coords.z, false, false, false)
    end)
end

---@param ctx SceneContext
---@param entity integer
---@param pitch number
---@param yaw number
---@param ms number
---@return boolean
local function tilt(ctx, entity, pitch, yaw, ms)
    return tween(ctx, ms, function(t)
        SetEntityRotation(entity, pitch * ease(t), 0.0, yaw, ROTATION_ORDER, false)
    end)
end

---@param entity integer
---@param heading number
---@param view CameraView
---@param active boolean
---@return integer
local function createCamera(entity, heading, view, active)
    local coords = offset(entity, view.offset)

    return CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', coords.x, coords.y, coords.z, view.pitch, 0.0, heading + view.yaw, view.fov, active, ROTATION_ORDER)
end

---@param ctx SceneContext
---@param view CameraView
local function shiftCamera(ctx, view)
    local previous = ctx.cam

    ctx.cam = createCamera(ctx.obj.parts.main, ctx.obj.heading, view, true)
    DestroyCam(previous, false)
    RenderScriptCams(true, false, 0, true, false)
end

---@param ctx SceneContext
---@param spec DragSpec
---@return boolean
local function drag(ctx, spec)
    local rotation = spec.rotation or ZERO
    local held = false
    local ready = false

    local function showPreview(enabled)
        if spec.preview then
            outline(ctx, spec.preview, enabled)
        end
    end

    hint(ctx, spec.text)
    outline(ctx, spec.entity, true)

    local delivered = waitFor(ctx, function()
        local x, y = cursor()

        if not held then
            if not isPointed(spec.entity, x, y) then return false end

            SetMouseCursorStyle(CURSOR_OPEN)

            if clicked() then
                held = true
                DetachEntity(spec.entity, false, false)
                setOutlineColor(ctx, props.scenes.outlineWait)
                showPreview(true)
            end

            return false
        end

        SetMouseCursorStyle(CURSOR_GRAB)

        local point = planePoint(x, y, spec.center, spec.height, spec.reach)
        local drop = planePoint(x, y, spec.target, spec.target.z, spec.reach)
        local over = drop ~= nil and isAbove(drop, spec.target, spec.radius)

        if point then
            place(spec.entity, point, rotation.x, rotation.y, spec.yaw + rotation.z)
        end

        if over ~= ready then
            ready = over
            setOutlineColor(ctx, ready and props.scenes.outline or props.scenes.outlineWait)
        end

        if holding() then return false end

        held = false
        ready = false
        showPreview(false)
        setOutlineColor(ctx, props.scenes.outline)

        if over then return true end

        spec.rest()
        return false
    end)

    showPreview(false)
    setOutlineColor(ctx, props.scenes.outline)
    outline(ctx, spec.entity, false)
    return delivered
end

---@param ctx SceneContext
---@param spec PourSpec
---@return boolean
local function pour(ctx, spec)
    local anchor = spec.start
    local angle = 0.0
    local poured = 0
    local pressed = false
    local last = GetGameTimer()
    local stream

    local done = waitFor(ctx, function()
        local now = GetGameTimer()
        local dt = now - last
        local x, y = cursor()

        last = now
        anchor = planePoint(x, y, spec.center, spec.height, spec.reach) or anchor

        if clicked() then
            pressed = true
        elseif not holding() then
            pressed = false
        end

        if pressed then
            SetMouseCursorStyle(CURSOR_GRAB)

            if spec.pressing then
                spec.pressing(dt)
            end
        end

        angle = approach(angle, pressed and spec.tilt or 0.0, spec.tilt * dt / spec.tiltMs)
        SetEntityRotation(spec.entity, 0.0, angle, spec.yaw, ROTATION_ORDER, false)

        local position = anchor - (offset(spec.entity, spec.fx.offset) - GetEntityCoords(spec.entity))

        SetEntityCoordsNoOffset(spec.entity, position.x, position.y, position.z, false, false, false)

        local pouring = pressed and angle >= spec.tilt * 0.9

        if pouring and not stream then
            stream = loopFx(ctx, spec.fx, spec.entity)
        elseif not pouring and stream then
            stopFx(stream)
            stream = nil
        end

        if pouring and isAbove(anchor, spec.center, spec.radius) then
            poured += dt
        end

        local share = math.min(poured / spec.ms, 1.0)

        spec.progress(share)
        hint(ctx, ('%s %d%%'):format(spec.text, math.floor(share * 100)))
        return share >= 1.0
    end)

    stopFx(stream)
    return done
end

---@param point fun(t: number): vector3
---@param x number
---@param y number
---@return number
local function nearestOnPath(point, x, y)
    local aspect = GetAspectRatio(false)
    local cx = x * aspect
    local best, bestDistance = 0.0, math.huge
    local lastT, lastX, lastY

    for i = 0, PATH_SAMPLES do
        local t = i / PATH_SAMPLES
        local world = point(t)
        local visible, sx, sy = GetScreenCoordFromWorldCoord(world.x, world.y, world.z)

        if not visible then
            lastT = nil
        else
            sx *= aspect

            if lastT then
                local dx, dy = sx - lastX, sy - lastY
                local length = dx * dx + dy * dy
                local u = length > 0.0 and math.min(math.max(((cx - lastX) * dx + (y - lastY) * dy) / length, 0.0), 1.0) or 0.0
                local ex, ey = cx - (lastX + dx * u), y - (lastY + dy * u)
                local distance = ex * ex + ey * ey

                if distance < bestDistance then
                    best, bestDistance = lastT + (t - lastT) * u, distance
                end
            end

            lastT, lastX, lastY = t, sx, sy
        end
    end

    return best
end

---@param ctx SceneContext
---@param spec PathSpec
---@return boolean
local function follow(ctx, spec)
    local held = false

    hint(ctx, spec.text)
    outline(ctx, spec.entity, true)

    local done = waitFor(ctx, function()
        local x, y = cursor()

        if not held then
            if not isPointed(spec.entity, x, y) then return false end

            SetMouseCursorStyle(CURSOR_OPEN)
            held = clicked()
            return false
        end

        if not holding() then
            held = false
            return false
        end

        SetMouseCursorStyle(CURSOR_GRAB)

        local t = nearestOnPath(spec.point, x, y)

        spec.pose(t)
        return t >= PATH_DONE
    end)

    outline(ctx, spec.entity, false)

    if done then
        spec.pose(1.0)
    end

    return done
end

---@param ctx SceneContext
---@param spec StirSpec
---@return boolean
local function stir(ctx, spec)
    local goal = spec.turns * 2.0 * math.pi
    local held = false
    local total = 0.0
    local angle

    outline(ctx, spec.tool, true)

    local done = waitFor(ctx, function()
        local x, y = cursor()

        hint(ctx, ('%s %d%%'):format(spec.text, math.floor(math.min(total / goal, 1.0) * 100)))

        if not held then
            angle = nil

            if not isPointed(spec.tool, x, y) then return false end

            SetMouseCursorStyle(CURSOR_OPEN)
            held = clicked()
            return false
        end

        if not holding() then
            held = false
            return false
        end

        SetMouseCursorStyle(CURSOR_GRAB)

        local point = planePoint(x, y, spec.center, spec.center.z, math.huge)

        if not point then return false end

        local dx, dy = point.x - spec.center.x, point.y - spec.center.y

        if dx * dx + dy * dy < STIR_DEADZONE * STIR_DEADZONE then return false end

        local current = math.atan(dy, dx)

        if angle then
            local delta = (current - angle + math.pi) % (2.0 * math.pi) - math.pi

            total += math.min(math.abs(delta), STIR_STEP)
        end

        angle = current
        spec.attach(current)
        return total >= goal
    end)

    outline(ctx, spec.tool, false)
    return done
end

---@param ctx SceneContext
---@param spec StrikeSpec
---@return boolean
local function strike(ctx, spec)
    local held = false
    local armed = true
    local ready = 0

    outline(ctx, spec.tool, true)

    local done = waitFor(ctx, function()
        local x, y = cursor()

        hint(ctx, spec.text())

        if not held then
            if not isPointed(spec.tool, x, y) then return false end

            SetMouseCursorStyle(CURSOR_OPEN)
            held = clicked()
            return false
        end

        if not holding() then
            held = false
            spec.rest()
            return false
        end

        SetMouseCursorStyle(CURSOR_GRAB)
        spec.move(x, y)

        local target = nearest(spec.targets, x, y)

        if not target then
            armed = true
            return false
        end

        if not armed or GetGameTimer() < ready then return false end

        armed = not spec.rearm
        ready = GetGameTimer() + spec.cooldown
        return spec.hit(target)
    end)

    outline(ctx, spec.tool, false)
    return done
end

---@param ctx SceneContext
---@param from number
---@param to number
---@param text string
---@return boolean
local function swingDoor(ctx, from, to, text)
    local parts = ctx.obj.parts --[[@as DrugParts]]
    local door = parts.door

    if not door then return true end

    local body = parts.main
    local hinge = props.chiller.door.offset
    local min, max = GetModelDimensions(GetEntityModel(door))
    local edge = math.abs(min.x) > math.abs(max.x) and min.x or max.x
    local handle = vec3(edge * 0.9, (min.y + max.y) * 0.5, (min.z + max.z) * 0.5)

    local function angleAt(t)
        return from + (to - from) * t
    end

    return follow(ctx, {
        entity = door,
        point = function(t)
            return offset(body, hinge + rotateZ(handle, angleAt(t)))
        end,
        pose = function(t)
            Render.attach(door, body, hinge, vec3(0.0, 0.0, angleAt(t)))
        end,
        text = text,
    })
end

local scenes = {}

---@param ctx SceneContext
---@return boolean
function scenes.soil(ctx)
    local data = props.scenes.soil
    local pot = ctx.obj.parts.main
    local center = GetEntityCoords(pot)
    local yaw = ctx.obj.heading + 180.0
    local opened = 0.0
    local soil
    local current

    preload({ data.bag, data.cover, table.unpack(data.stages) })
    lib.requestNamedPtfxAsset(data.fx.dict)

    local start = offset(pot, vec3(data.reach * 0.5, 0.0, data.height))
    local bag = spawn(ctx, data.bag, start)
    local cover = spawn(ctx, data.cover, start)

    Render.attach(cover, bag, ZERO)
    place(bag, start, 0.0, 0.0, yaw)

    return pour(ctx, {
        entity = bag,
        start = start,
        center = center,
        height = center.z + data.height,
        reach = data.reach,
        yaw = yaw,
        tilt = data.tilt,
        tiltMs = data.tiltMs,
        radius = data.pourRadius,
        fx = data.fx,
        ms = config.pourMs.soil,
        text = 'Arahkan ke pot, tahan klik kiri untuk menuang tanah',
        pressing = function(dt)
            if opened >= 1.0 then return end

            opened = math.min(opened + dt / data.openMs, 1.0)
            SetEntityAlpha(cover, math.floor(255 * (1.0 - opened)), false)
        end,
        progress = function(share)
            if share <= 0.0 then return end

            local model = data.stages[share < 0.35 and 1 or share < 0.6 and 2 or share < 0.9 and 3 or 4]

            if model == current then return end

            Render.delete(soil)
            soil = spawn(ctx, model, center)
            Render.attach(soil, pot, ZERO)
            current = model
        end,
    })
end

---@param ctx SceneContext
---@return boolean
function scenes.seed(ctx)
    local data = props.scenes.seed
    local parts = ctx.obj.parts --[[@as DrugParts]]
    local pot = parts.main
    local center = GetEntityCoords(pot)
    local hole = offset(pot, data.holeOffset)
    local yaw = ctx.obj.heading + 180.0
    local seedModel = props.plants[ctx.option].seed
    local models = { data.hole, seedModel }
    local clusters = {}

    for i = 1, #data.clusters do
        models[#models + 1] = data.clusters[i].model
    end

    preload(models)

    if parts.soil then
        SetEntityVisible(parts.soil, false, false)
    end

    Render.attach(spawn(ctx, data.hole, center), pot, ZERO)

    for i = 1, #data.clusters do
        local cluster = data.clusters[i]
        local entity = spawn(ctx, cluster.model, center)

        Render.attach(entity, pot, cluster.offset)
        clusters[i] = entity
    end

    local rest = offset(pot, data.rest)
    local seed = spawn(ctx, seedModel, rest)

    place(seed, rest, 0.0, 0.0, yaw)

    local planted = drag(ctx, {
        entity = seed,
        target = hole,
        radius = data.snapRadius,
        center = center,
        height = center.z + data.height,
        reach = data.reach,
        yaw = yaw,
        rest = function()
            place(seed, rest, 0.0, 0.0, yaw)
        end,
        text = 'Tahan klik kiri pada benih, lepas di atas lubang',
    })

    if not planted then return false end

    hint(ctx)

    local from = GetEntityCoords(seed)

    local snapped = tween(ctx, data.snapMs, function(t)
        place(seed, lerp(from, hole, ease(t)), 0.0, 0.0, yaw)
    end)

    if not snapped or not hold(ctx, data.holdMs) then return false end

    local closed = tween(ctx, data.closeMs, function(t)
        local spread = 1.0 - ease(t)

        for i = 1, #clusters do
            Render.attach(clusters[i], pot, data.clusters[i].offset * spread)
        end
    end)

    return closed and hold(ctx, data.holdMs)
end

---@param ctx SceneContext
---@return boolean
function scenes.water(ctx)
    local data = props.scenes.water
    local parts = ctx.obj.parts --[[@as DrugParts]]
    local pot = parts.main
    local center = GetEntityCoords(pot)
    local yaw = ctx.obj.heading + 180.0
    local wet = props.pot.wetSoil
    local baseLevel = ctx.obj.state.watered and wet or props.pot.drySoil
    local current

    preload({ data.can })
    lib.requestNamedPtfxAsset(data.fx.dict)

    local start = offset(pot, vec3(data.reach * 0.5, 0.0, data.height))
    local can = spawn(ctx, data.can, start)

    place(can, start, 0.0, 0.0, yaw)

    return pour(ctx, {
        entity = can,
        start = start,
        center = center,
        height = center.z + data.height,
        reach = data.reach,
        yaw = yaw,
        tilt = data.tilt,
        tiltMs = data.tiltMs,
        radius = data.pourRadius,
        fx = data.fx,
        ms = config.pourMs.water,
        text = 'Arahkan ke pot, tahan klik kiri untuk menyiram',
        progress = function(share)
            local level = math.min(wet, baseLevel + (share >= 0.8 and 3 or share >= 0.4 and 2 or share >= 0.2 and 1 or 0))

            if level == current or not parts.soil then return end

            SetObjectTextureVariation(parts.soil, level)
            current = level
        end,
    })
end

---@param ctx SceneContext
---@return boolean
function scenes.harvest(ctx)
    local data = props.scenes.harvest
    local parts = ctx.obj.parts --[[@as DrugParts]]
    local buds = {}

    for i = 1, #parts.ready do
        local bud = parts.ready[i]

        if DoesEntityExist(bud) then
            buds[#buds + 1] = bud
        end
    end

    local total = #buds

    if total == 0 or not parts.plant then return false end

    preload({ data.scissors })
    lib.requestAnimDict(data.dict)

    for i = 1, total do
        outline(ctx, buds[i], true)
    end

    local yaw = ctx.obj.heading
    local plantCoords = GetEntityCoords(parts.plant)
    local rest = offset(parts.main, data.rest)
    local scissors = spawn(ctx, data.scissors, rest)

    local function park()
        place(scissors, rest, 0.0, 0.0, yaw)
    end

    park()

    local cut = strike(ctx, {
        tool = scissors,
        targets = buds,
        cooldown = data.cutMs,
        rearm = false,
        rest = park,
        move = function(x, y)
            local origin, direction = cursorRay(x, y)

            place(scissors, origin + direction * (#(plantCoords - origin) - data.depth), 0.0, 0.0, yaw)
        end,
        hit = function(index)
            local bud = table.remove(buds, index)
            local rotation = GetEntityRotation(bud, ROTATION_ORDER)
            local piece = spawn(ctx, GetEntityModel(bud), GetEntityCoords(bud), true)

            SetEntityRotation(piece, rotation.x, rotation.y, rotation.z, ROTATION_ORDER, false)
            outline(ctx, bud, false)
            Render.delete(bud)
            PlayEntityAnim(scissors, data.clip, data.dict, 8.0, false, false, false, 0.0, 0)
            FreezeEntityPosition(piece, false)
            ApplyForceToEntity(piece, 1, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0, false, true, true, false, true)
            return #buds == 0
        end,
        text = function()
            return ('Tahan klik kiri pada gunting, sentuhkan ke bud (%d/%d)'):format(total - #buds, total)
        end,
    })

    if not cut then return false end

    hint(ctx)
    return hold(ctx, data.finishMs)
end

---@param ctx SceneContext
---@return boolean
function scenes.cook(ctx)
    local data = props.scenes.cook
    local liquidData = props.table.liquid
    local flaskOffset = props.table.flask.offset
    local parts = ctx.obj.parts --[[@as DrugParts]]
    local desk = parts.main
    local flask = parts.flask --[[@as integer]]
    local yaw = ctx.obj.heading
    local stirData = data.spatula

    preload({
        data.beaker.model,
        data.beakerLiquids[1],
        data.beakerLiquids[2],
        data.acetone.model,
        data.acetone.open,
        data.pills.model,
        data.pills.drop,
        data.iodine.model,
        stirData.model,
        liquidData.model,
    })
    lib.requestNamedPtfxAsset(data.acetone.fx.dict)
    lib.requestNamedPtfxAsset(data.iodine.fx.dict)

    local base = GetEntityCoords(desk)
    local beaker = spawn(ctx, data.beaker.model, base, true)
    local acetone = spawn(ctx, data.acetone.model, base)
    local pills = spawn(ctx, data.pills.model, base)
    local iodine = spawn(ctx, data.iodine.model, base)
    local spatula = spawn(ctx, stirData.model, base)

    Render.attach(beaker, desk, data.beaker.offset)
    Render.attach(acetone, desk, data.acetone.offset)
    Render.attach(pills, desk, data.pills.offset)
    Render.attach(iodine, desk, data.iodine.offset)
    Render.attach(spatula, desk, stirData.rest, stirData.restRotation)

    local top = offset(desk, data.beaker.offset + data.beakerTop)
    local mouth = top + vec3(0.0, 0.0, data.lift)

    local function deliver(entity, slot, target, radius, item, destination, rotation)
        return drag(ctx, {
            entity = entity,
            target = target,
            radius = radius,
            center = target,
            height = target.z,
            reach = data.reach,
            yaw = yaw,
            rest = function()
                Render.attach(entity, desk, slot, rotation)
            end,
            text = ('Tahan klik kiri pada %s, lepas di atas %s'):format(item, destination),
        })
    end

    if not deliver(acetone, data.acetone.offset, top, data.beakerRadius, 'acetone', 'gelas ukur') then return false end

    hint(ctx)

    if not glide(ctx, acetone, mouth, data.glideMs) then return false end
    if not tilt(ctx, acetone, data.pourTilt, yaw, data.tiltMs) then return false end

    local open = spawn(ctx, data.acetone.open, mouth)

    SetObjectTextureVariation(open, data.acetone.openTexture)
    Render.attach(open, acetone, ZERO)
    SetEntityVisible(acetone, false, false)

    local stream = loopFx(ctx, data.acetone.fx, acetone)

    if not hold(ctx, data.acetone.firstMs) then return false end

    local liquid = spawn(ctx, data.beakerLiquids[1], base)

    Render.attach(liquid, beaker, ZERO)

    if not hold(ctx, data.acetone.secondMs) then return false end

    Render.delete(liquid)
    liquid = spawn(ctx, data.beakerLiquids[2], base)
    Render.attach(liquid, beaker, ZERO)
    stopFx(stream)

    if not hold(ctx, data.acetone.endMs) then return false end

    Render.delete(open)
    Render.delete(acetone)

    if not deliver(pills, data.pills.offset, top, data.beakerRadius, 'pills', 'gelas ukur') then return false end

    hint(ctx)

    if not glide(ctx, pills, mouth, data.glideMs) then return false end

    local drop = top + vec3(0.0, 0.0, data.pills.dropHeight)

    for _ = 1, data.pills.count do
        local pill = spawn(ctx, data.pills.drop, drop, true)

        if not hold(ctx, data.pills.holdMs) then return false end

        FreezeEntityPosition(pill, false)
        ApplyForceToEntity(pill, 1, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0, false, true, true, false, true)

        if not hold(ctx, data.pills.fallMs) then return false end

        Render.delete(pill)
    end

    Render.delete(pills)

    if not deliver(iodine, data.iodine.offset, top, data.beakerRadius, 'iodine', 'gelas ukur') then return false end

    hint(ctx)

    if not glide(ctx, iodine, mouth, data.glideMs) then return false end
    if not tilt(ctx, iodine, data.pourTilt, yaw, data.tiltMs) then return false end

    local spray = loopFx(ctx, data.iodine.fx, iodine)

    if not hold(ctx, data.iodine.sprayMs) then return false end

    stopFx(spray)

    if not hold(ctx, data.iodine.endMs) then return false end

    Render.delete(iodine)

    if not deliver(spatula, stirData.rest, top, data.beakerRadius, 'spatula', 'gelas ukur', stirData.restRotation) then return false end

    local function stirAt(angle)
        local relative = angle - math.rad(yaw)
        local position = vec3(math.cos(relative) * stirData.radius, math.sin(relative) * stirData.radius, stirData.height)

        Render.attach(spatula, beaker, position, vec3(stirData.pitch, 0.0, 0.0))
    end

    stirAt(math.rad(yaw))

    local stirred = stir(ctx, {
        tool = spatula,
        center = top,
        turns = stirData.turns,
        attach = stirAt,
        text = 'Tahan klik kiri pada spatula, putar untuk mengaduk',
    })

    if not stirred then return false end

    Render.delete(spatula)
    SetObjectTextureVariation(liquid, liquidData.texture)

    local low = vec3(flaskOffset.x, flaskOffset.y, data.flaskLowZ)

    local lowered = follow(ctx, {
        entity = flask,
        point = function(t)
            return offset(desk, lerp(flaskOffset, low, t))
        end,
        pose = function(t)
            Render.attach(flask, desk, lerp(flaskOffset, low, t), vec3(0.0, 0.0, data.flaskTurn * t))
        end,
        text = 'Tahan klik kiri pada flask, tarik ke bawah',
    })

    if not lowered then return false end

    local flaskTop = offset(flask, data.flaskTarget)

    if not deliver(beaker, data.beaker.offset, flaskTop, data.flaskRadius, 'gelas ukur', 'flask') then return false end

    hint(ctx)

    if not glide(ctx, beaker, offset(flask, data.flaskPour), data.glideMs) then return false end

    local poured = tween(ctx, data.pourTiltMs, function(t)
        Render.attach(beaker, flask, data.flaskPour, vec3(data.flaskTilt * t, 0.0, data.flaskYaw))
    end)

    if not poured or not hold(ctx, data.pourHoldMs) then return false end

    local filled = spawn(ctx, liquidData.model, base)

    Render.delete(liquid)
    Render.delete(beaker)
    SetObjectTextureVariation(filled, liquidData.texture)
    Render.attach(filled, flask, ZERO)

    return follow(ctx, {
        entity = flask,
        point = function(t)
            return offset(desk, lerp(low, flaskOffset, t))
        end,
        pose = function(t)
            Render.attach(flask, desk, lerp(low, flaskOffset, t), vec3(0.0, 0.0, data.flaskTurn * (1.0 - t)))
        end,
        text = 'Tahan klik kiri pada flask, tarik ke atas',
    })
end

---@param ctx SceneContext
---@return boolean
function scenes.pack(ctx)
    local recipe = config.packing.recipes[config.equipment[ctx.obj.kind].group][ctx.option]
    local data = props.scenes.pack
    local look = data.visuals[recipe.visual]
    local desk = ctx.obj.parts.main
    local base = GetEntityCoords(desk)
    local yaw = ctx.obj.heading
    local slots = #data.products
    local work = offset(desk, look.work)
    local mouth = work + vec3(0.0, 0.0, data.mouth)
    local items, bags, stacked = {}, {}, {}

    preload({ look.ingredient, look.bag, look.open, look.full, look.done })

    local function stage(slot)
        local product = data.products[slot]

        items[slot] = spawn(ctx, look.ingredient, base)
        bags[slot] = spawn(ctx, look.bag, base)
        Render.attach(items[slot], desk, product[1], product[2] + look.productRotation)
        Render.attach(bags[slot], desk, data.bags[slot] + look.bagOffset)
    end

    local function carry(entity, target, radius, rotation, rest, text, preview)
        return drag(ctx, {
            entity = entity,
            target = target,
            radius = radius,
            center = base,
            height = target.z + data.lift,
            reach = data.reach,
            yaw = yaw,
            rotation = rotation,
            preview = preview,
            rest = rest,
            text = text,
        })
    end

    for slot = 1, math.min(ctx.amount, slots) do
        stage(slot)
    end

    for i = 1, ctx.amount do
        local slot = (i - 1) % slots + 1
        local product = data.products[slot]
        local rack = data.bags[slot] + look.bagOffset
        local finish = data.done[slot]
        local stack = finish[1] + look.doneOffset
        local count = ('(%d/%d)'):format(i, ctx.amount)

        if i > slots then
            stage(slot)
        end

        local bag = bags[slot]
        local item = items[slot]
        local marker = guide(ctx, look.open, desk, look.work)

        local opened = carry(bag, work, data.workRadius, ZERO, function()
            Render.attach(bag, desk, rack)
        end, ('Tahan klik kiri pada %s, lepas di area kerja %s'):format(look.container, count), marker)

        if not opened then return false end

        Render.delete(marker)
        Render.delete(bag)

        local open = spawn(ctx, look.open, base)

        Render.attach(open, desk, look.work)

        local filled = carry(item, mouth, look.radius, look.ingredientRotation, function()
            Render.attach(item, desk, product[1], product[2] + look.productRotation)
        end, ('Tahan klik kiri pada bahan, masukkan ke %s %s'):format(look.container, count))

        if not filled then return false end

        Render.delete(item)
        Render.delete(open)

        local full = spawn(ctx, look.full, base)

        Render.attach(full, desk, look.work)
        Render.delete(stacked[slot])
        marker = guide(ctx, look.done, desk, stack, finish[2])

        local placed = carry(full, offset(desk, stack), data.doneRadius, ZERO, function()
            Render.attach(full, desk, look.work)
        end, ('Tahan klik kiri pada %s, taruh di area hasil %s'):format(look.product, count), marker)

        if not placed then return false end

        Render.delete(marker)
        Render.delete(full)
        stacked[slot] = spawn(ctx, look.done, base)
        Render.attach(stacked[slot], desk, stack, finish[2])
    end

    hint(ctx)
    return hold(ctx, data.finishMs)
end

---@param ctx SceneContext
---@return boolean
function scenes.dry(ctx)
    local data = props.scenes.dry
    local look = props.dry
    local stand = ctx.obj.parts.main
    local base = GetEntityCoords(stand)
    local yaw = ctx.obj.heading
    local count = math.min(ctx.amount or 0, #look.slots)
    local source = data.offset + data.budOffset

    ctx.outlineAlpha = data.outlineAlpha
    ctx.outlineShader = data.outlineShader
    SetEntityDrawOutlineShader(data.outlineShader)
    setOutlineColor(ctx, props.scenes.outline)
    preload({ data.bag, look.model })

    local bag = spawn(ctx, data.bag, base)

    Render.attach(bag, stand, data.offset)

    for i = 1, count do
        local slot = look.slots[i]
        local target = offset(stand, slot[1])
        local marker = guide(ctx, look.model, stand, slot[1], slot[2])
        local bud = spawn(ctx, look.model, base)

        local function park()
            Render.attach(bud, stand, source)
        end

        park()

        local hung = drag(ctx, {
            entity = bud,
            target = target,
            radius = data.radius,
            center = base,
            height = target.z,
            reach = data.reach,
            yaw = yaw,
            preview = marker,
            rest = park,
            text = ('Tahan klik kiri pada bud, gantung di stand (%d/%d)'):format(i, count),
        })

        if not hung then return false end

        Render.delete(marker)
        Render.attach(bud, stand, slot[1], slot[2])
    end

    Render.delete(bag)
    hint(ctx)
    return hold(ctx, data.finishMs)
end

---@param ctx SceneContext
---@return boolean
function scenes.cauldron(ctx)
    local data = props.scenes.cauldron
    local cauldron = ctx.obj.parts.main
    local base = GetEntityCoords(cauldron)
    local yaw = ctx.obj.heading
    local drop = offset(cauldron, data.drop)
    local count = math.min(math.max(ctx.amount or 1, 1), #data.spots)
    local pieces = {}

    preload({ data.piece })

    for i = 1, count do
        pieces[i] = spawn(ctx, data.piece, base)
        Render.attach(pieces[i], cauldron, data.spots[i][1], data.spots[i][2])
    end

    for i = 1, count do
        local piece = pieces[i]
        local spot = data.spots[i]

        local dropped = drag(ctx, {
            entity = piece,
            target = drop,
            radius = data.radius,
            center = drop,
            height = drop.z,
            reach = data.reach,
            yaw = yaw,
            rest = function()
                Render.attach(piece, cauldron, spot[1], spot[2])
            end,
            text = ('Tahan klik kiri pada kokain, masukkan ke kuali (%d/%d)'):format(i, count),
        })

        if not dropped then return false end

        hint(ctx)

        if not glide(ctx, piece, offset(cauldron, data.inside), data.fallMs) then return false end

        Render.delete(piece)
    end

    loopFx(ctx, props.cauldron.steam, cauldron)
    return hold(ctx, data.finishMs)
end

---@param ctx SceneContext
---@return boolean
function scenes.chiller(ctx)
    local data = props.scenes.chiller
    local look = props.chiller
    local rack = look.slots[1][1]
    local body = ctx.obj.parts.main
    local base = GetEntityCoords(body)
    local yaw = ctx.obj.heading

    preload({ data.emptyTray, data.package, look.tray })

    local tray = spawn(ctx, data.emptyTray, base)
    local package = spawn(ctx, data.package, base)

    local function parkPackage()
        Render.attach(package, body, data.packageRest, data.packageRotation)
    end

    Render.attach(tray, body, data.work, data.workRotation)
    parkPackage()

    local top = offset(tray, data.trayTop)

    local carried = drag(ctx, {
        entity = package,
        target = top,
        radius = data.pourRadius,
        center = top,
        height = top.z,
        reach = data.reach,
        yaw = yaw + data.packageRotation.z,
        rest = parkPackage,
        text = 'Tahan klik kiri pada galon liquid meth, lepas di atas tray',
    })

    if not carried then return false end

    hint(ctx)

    if not glide(ctx, package, offset(tray, data.pourOffset), data.glideMs) then return false end

    local tipped = tween(ctx, data.tiltMs, function(t)
        Render.attach(package, tray, data.pourOffset, vec3(data.pourTilt * ease(t), 0.0, 0.0))
    end)

    if not tipped then return false end

    local stream = loopFx(ctx, data.pourFx, package)

    if not hold(ctx, data.pourMs) then return false end

    stopFx(stream)
    Render.delete(package)
    Render.delete(tray)
    tray = spawn(ctx, look.tray, base)
    Render.attach(tray, body, data.work, data.workRotation)

    shiftCamera(ctx, props.scenes.cameras.chillerCollect)

    if not swingDoor(ctx, 0.0, data.doorAngle, 'Tahan klik kiri pada pintu, tarik untuk membuka') then return false end

    local slot = offset(body, rack)
    local marker = guide(ctx, look.tray, body, rack)

    local stored = drag(ctx, {
        entity = tray,
        target = slot,
        radius = data.slotRadius,
        center = slot,
        height = slot.z,
        reach = data.reach,
        yaw = yaw,
        preview = marker,
        rest = function()
            Render.attach(tray, body, data.work, data.workRotation)
        end,
        text = 'Tahan klik kiri pada tray, masukkan ke rak chiller',
    })

    if not stored then return false end

    Render.delete(marker)
    hint(ctx)

    if not glide(ctx, tray, slot, data.slideMs) then return false end

    Render.attach(tray, body, rack)

    return swingDoor(ctx, data.doorAngle, 0.0, 'Tahan klik kiri pada pintu, dorong untuk menutup')
end

---@param ctx SceneContext
---@return boolean
function scenes.chillerCollect(ctx)
    local data = props.scenes.chiller
    local look = props.chiller
    local parts = ctx.obj.parts --[[@as DrugParts]]
    local body = parts.main
    local base = GetEntityCoords(body)
    local yaw = ctx.obj.heading
    local stages = data.stages
    local rack = look.slots[1][1]
    local count = math.min(math.max(ctx.obj.state.amount or 1, 1), #data.buds)

    preload({ look.frozen, data.hammer, data.bud, data.collectBag, stages[2], stages[4], stages[6] })

    if parts.items[1] then
        SetEntityVisible(parts.items[1], false, false)
    end

    local tray = spawn(ctx, look.frozen, base)

    Render.attach(tray, body, rack)

    if not swingDoor(ctx, 0.0, data.doorAngle, 'Tahan klik kiri pada pintu, tarik untuk membuka') then return false end

    local work = offset(body, data.work)
    local marker = guide(ctx, look.frozen, body, data.work, data.workRotation)

    local taken = drag(ctx, {
        entity = tray,
        target = work,
        radius = data.workRadius,
        center = work,
        height = work.z + data.lift,
        reach = data.reach,
        yaw = yaw + data.workRotation.z,
        preview = marker,
        rest = function()
            Render.attach(tray, body, rack)
        end,
        text = 'Tahan klik kiri pada tray, keluarkan ke meja',
    })

    if not taken then return false end

    Render.delete(marker)
    Render.attach(tray, body, data.work, data.workRotation)

    if not swingDoor(ctx, data.doorAngle, 0.0, 'Tahan klik kiri pada pintu, dorong untuk menutup') then return false end

    shiftCamera(ctx, props.scenes.cameras.chiller)

    local hammer = spawn(ctx, data.hammer, base)
    local rest = offset(body, data.hammerRest)
    local rotation = data.hammerRotation
    local targets = { tray }
    local hits = 0
    local swungAt = 0

    local function pose(coords)
        local dip = math.max(0.0, 1.0 - (GetGameTimer() - swungAt) / data.swingMs) * data.swingAngle

        place(hammer, coords, rotation.x + dip, rotation.y, yaw + rotation.z)
    end

    pose(rest)
    outline(ctx, tray, true)

    local smashed = strike(ctx, {
        tool = hammer,
        targets = targets,
        cooldown = data.hitMs,
        rearm = true,
        rest = function()
            pose(rest)
        end,
        move = function(x, y)
            local origin, direction = cursorRay(x, y)

            pose(origin + direction * (#(GetEntityCoords(tray) - origin) - data.hammerDepth))
        end,
        hit = function()
            local model

            hits += 1
            swungAt = GetGameTimer()
            model = stages[hits]

            if model then
                Render.delete(tray)
                tray = spawn(ctx, model, base)
                targets[1] = tray
                Render.attach(tray, body, data.work, data.workRotation)
                outline(ctx, tray, true)
            end

            return hits >= data.hits
        end,
        text = function()
            return ('Tahan klik kiri pada palu, pukul tray (%d/%d)'):format(hits, data.hits)
        end,
    })

    if not smashed then return false end

    outline(ctx, tray, false)
    Render.delete(hammer)

    local bag = spawn(ctx, data.collectBag, base)

    Render.attach(bag, body, data.collectBagOffset)

    local mouth = offset(bag, vec3(0.0, 0.0, data.mouth))
    local buds = {}

    for i = 1, count do
        buds[i] = spawn(ctx, data.bud, base)
        Render.attach(buds[i], tray, data.buds[i][1], data.buds[i][2])
    end

    for i = 1, count do
        local bud = buds[i]
        local spot = data.buds[i]

        local bagged = drag(ctx, {
            entity = bud,
            target = mouth,
            radius = data.budRadius,
            center = mouth,
            height = mouth.z,
            reach = data.reach,
            yaw = yaw,
            rest = function()
                Render.attach(bud, tray, spot[1], spot[2])
            end,
            text = ('Tahan klik kiri pada crack meth, masukkan ke kantong (%d/%d)'):format(i, count),
        })

        if not bagged then return false end

        Render.delete(bud)
    end

    hint(ctx)
    return hold(ctx, data.finishMs)
end

---@param ctx SceneContext
local function cleanup(ctx)
    if ctx.cleaned then return end

    ctx.done = true
    ctx.cleaned = true

    if active == ctx then
        active = nil
    end

    hint(ctx)
    SetMouseCursorStyle(CURSOR_ARROW)

    for i = 1, #ctx.outlined do
        if DoesEntityExist(ctx.outlined[i]) then
            SetEntityDrawOutline(ctx.outlined[i], false)
        end
    end

    if ctx.outlineShader then
        SetEntityDrawOutlineShader(0)
    end

    for i = 1, #ctx.fx do
        stopFx(ctx.fx[i])
    end

    for i = 1, #ctx.entities do
        Render.delete(ctx.entities[i])
    end

    RenderScriptCams(false, false, 0, true, false)
    DestroyCam(ctx.cam, false)
    ResetEntityAlpha(cache.ped)
    FreezeEntityPosition(cache.ped, false)
    LocalPlayer.state.invBusy = false
end

---@param action string
---@param group string
---@return string
local function sceneName(action, group)
    if action == 'process' then return group end
    if action == 'collect' then return ('%sCollect'):format(group) end

    return action
end

local Scene = {}

---@param action string
---@param obj DrugClientObject
---@return boolean
function Scene.supported(action, obj)
    return scenes[sceneName(action, config.equipment[obj.kind].group)] ~= nil
end

---@param action string
---@param obj DrugClientObject
---@param option? any
---@param amount? integer
---@param minimum? integer
---@return boolean completed
---@return fun() cleanup
---@return boolean failed
function Scene.play(action, obj, option, amount, minimum)
    local parts = obj.parts --[[@as DrugParts]]
    local group = config.equipment[obj.kind].group
    local name = sceneName(action, group)
    local cameras = props.scenes.cameras
    local view = action == 'harvest' and props.plants[obj.state.seed].camera or cameras[name] or cameras[group]
    local now = GetGameTimer()

    local ctx = {
        obj = obj,
        option = option,
        amount = amount,
        deadline = now + config.sceneTimeoutMs * (action == 'pack' and amount or 1),
        startedAt = now,
        entities = {},
        fx = {},
        outlined = {},
        cam = createCamera(parts.main, obj.heading, view, true),
    }

    RenderScriptCams(true, false, 0, true, false)
    active = ctx
    SetEntityAlpha(cache.ped, 0, false)
    FreezeEntityPosition(cache.ped, true)
    setOutlineColor(ctx, props.scenes.outline)
    LocalPlayer.state.invBusy = true

    local ok, completed = pcall(scenes[name], ctx)

    if ok and completed == true and minimum then
        local rest = minimum - (GetGameTimer() - ctx.startedAt)

        if rest > 0 then
            hint(ctx)
            ok, completed = pcall(hold, ctx, rest)
        end
    end

    if not ok then
        lib.print.error(completed)
    end

    ctx.done = true

    return ok and completed == true, function()
        cleanup(ctx)
    end, not ok
end

function Scene.abort()
    if active then
        cleanup(active)
    end
end

return Scene
