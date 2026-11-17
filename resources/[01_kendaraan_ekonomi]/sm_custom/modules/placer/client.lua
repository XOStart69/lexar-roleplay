local RAYCAST_FLAGS <const> = 17
local RAYCAST_DISTANCE <const> = 30.0
local POLYGON_DISTANCE <const> = 150.0
local FEET <const> = 1.0
local STEP <const> = 5.0
local LIFT <const> = 0.02
local LIFT_LIMIT <const> = 6.0
local ALPHA <const> = 170
local HEIGHT_STEP <const> = 0.5
local POINT_GAP <const> = 0.1
local LOOK_SPEED <const> = 8.0
local MOVE_SPEED <const> = 0.1
local FAST <const> = 5.0
local UP <const> = vec3(0.0, 0.0, 1.0)
local LINE <const> = { 255, 255, 255, 220 }
local OUTSIDE <const> = { 255, 42, 24, 220 }
local CURSOR <const> = { r = 255, g = 42, b = 24, a = 230 }
local MARK <const> = { r = 255, g = 255, b = 255, a = 150 }
local MARK_OUTSIDE <const> = { r = 255, g = 42, b = 24, a = 150 }

local SCROLL_DOWN <const> = 14
local SCROLL_UP <const> = 15
local SHIFT <const> = 21
local ALT <const> = 19
local LOWER <const> = 23
local RAISE <const> = 45
local CONFIRM <const> = 176
local CANCEL <const> = 177
local GIZMO <const> = 47
local BLOCKED <const> = { 14, 15, 16, 17, 19, 23, 24, 25, 37, 45, 47, 140, 141, 142, 176, 177, 199, 200, 261, 262 }

local REACH <const> = 0.12
local RING <const> = 0.8
local SEGMENTS <const> = 32
local NUDGE_MOVE <const> = 0.01
local NUDGE_TURN <const> = 1.0
local NUDGE_LIMIT <const> = 10.0
local PRECISION <const> = 10000
local CAM_EASE <const> = 300
local WORLD <const> = { vec3(1.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0), vec3(0.0, 0.0, 1.0) }
local NAMES <const> = { 'x', 'y', 'z' }
local AXES <const> = { x = 1, y = 2, z = 3 }
local COMMANDS <const> = {
    confirm = true,
    cancel = true,
    aim = true,
    move = true,
    rotate = true,
    world = true,
    ['local'] = true,
}

---@class PlacerOptions
---@field kind 'point' | 'vehicle' | 'object'
---@field model? string
---@field tilt? boolean
---@field gizmo? boolean
---@field rotation? vector3
---@field area? CustomArea
---@field effect? PlacerEffect
---@field entity? integer

---@class PlacerEffect
---@field asset string
---@field effect string
---@field offset vector3
---@field rotation vector3
---@field scale number
---@field alpha number

---@class PlacerResult
---@field coords vector3
---@field rotation vector3

---@class PlacerGizmo
---@field mode 'move' | 'rotate'
---@field space 'world' | 'local'
---@field drags { axis: integer, from: number[], to: number[] }[]
---@field nudges { axis: integer, step: number }[]
---@field commands string[]
---@field sent string
---@field cam integer
---@field look boolean

---@class PlacerClient
local placer = {}
local active = false
---@type PlacerGizmo?
local gizmo

---@return boolean
function placer.active()
    return active
end

---@param guide table | false
local function prompt(guide)
    SendNUIMessage({ action = 'placer', data = guide })
end

---@param a vector3
---@param b vector3
---@return number
local function dot(a, b)
    return a.x * b.x + a.y * b.y + a.z * b.z
end

---@param a vector3
---@param b vector3
---@return vector3
local function cross(a, b)
    return vec3(a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x)
end

---@param v vector3
---@return vector3
local function unit(v)
    local size = math.sqrt(dot(v, v))

    return size > 1e-6 and v * (1.0 / size) or v
end

---@param value any
---@return number[]?
local function pair(value)
    if type(value) ~= 'table' then return end

    local x, y = tonumber(value[1]), tonumber(value[2])
    if not x or not y or x ~= x or y ~= y then return end

    return { x, y }
end

---@param point vector3
---@return number[] | false
local function project(point)
    local visible, x, y = GetScreenCoordFromWorldCoord(point.x, point.y, point.z)
    if not visible then return false end

    return { math.floor(x * PRECISION + 0.5) / PRECISION, math.floor(y * PRECISION + 0.5) / PRECISION }
end

---@param space 'world' | 'local'
---@param basis vector3[]
---@return vector3[]
local function axesOf(space, basis)
    return space == 'local' and basis or WORLD
end

---@param basis vector3[]
---@param axis vector3
---@param angle number
---@return vector3[]
local function twist(basis, axis, angle)
    local c, s = math.cos(angle), math.sin(angle)

    local function spin(v)
        return v * c + cross(axis, v) * s + axis * (dot(axis, v) * (1.0 - c))
    end

    local up = unit(spin(basis[3]))
    local forward = unit(spin(basis[2]))

    forward = unit(forward - up * dot(forward, up))

    return { cross(forward, up), forward, up }
end

---@param center vector3
---@param axis vector3
---@param radius number
---@return (number[] | false)[]
local function ring(center, axis, radius)
    local helper = math.abs(axis.z) < 0.9 and WORLD[3] or WORLD[1]
    local u = unit(cross(axis, helper))
    local v = cross(axis, u)
    local points = {}

    for step = 0, SEGMENTS do
        local angle = step / SEGMENTS * math.pi * 2.0

        points[step + 1] = project(center + (u * math.cos(angle) + v * math.sin(angle)) * radius)
    end

    return points
end

---@param state PlacerGizmo
---@param position vector3
---@param basis vector3[]
---@param tilt boolean
---@param inside boolean
local function publish(state, position, basis, tilt, inside)
    local size = #(GetFinalRenderedCamCoord() - position) * REACH
    local handles = {}

    for index, axis in ipairs(axesOf(state.space, basis)) do
        if state.mode == 'move' then
            handles[#handles + 1] = { axis = NAMES[index], tip = project(position + axis * size) }
        elseif tilt or index == 3 then
            handles[#handles + 1] = { axis = NAMES[index], ring = ring(position, axis, size * RING) }
        end
    end

    local text = json.encode({
        action = 'gizmo',
        data = {
            mode = state.mode,
            space = state.space,
            tilt = tilt,
            inside = inside,
            origin = project(position),
            handles = handles,
        },
    })

    if text == state.sent then return end

    state.sent = text
    SendNuiMessage(text)
end

---@param state PlacerGizmo
---@param position vector3
---@param basis vector3[]
---@param tilt boolean
---@return vector3 position
---@return vector3[] basis
local function steer(state, position, basis, tilt)
    local aspect = GetAspectRatio(false)
    local camera = GetFinalRenderedCamCoord()
    local size = #(camera - position) * REACH

    for _, drag in ipairs(state.drags) do
        local axis = axesOf(state.space, basis)[drag.axis]
        local origin = project(position)
        local tip = origin and state.mode == 'move' and project(position + axis * size)

        if origin and tip then
            local sx, sy = (tip[1] - origin[1]) * aspect, tip[2] - origin[2]
            local span = sx * sx + sy * sy

            if span > 1e-8 then
                local dx, dy = (drag.to[1] - drag.from[1]) * aspect, drag.to[2] - drag.from[2]

                position += axis * ((dx * sx + dy * sy) / span * size)
            end
        elseif origin and state.mode == 'rotate' and (tilt or drag.axis == 3) then
            local before = math.atan(drag.from[2] - origin[2], (drag.from[1] - origin[1]) * aspect)
            local after = math.atan(drag.to[2] - origin[2], (drag.to[1] - origin[1]) * aspect)
            local delta = (after - before + math.pi) % (math.pi * 2.0) - math.pi
            local facing = dot(axis, camera - position) >= 0.0 and 1.0 or -1.0

            basis = twist(basis, axis, -delta * facing)
        end
    end

    for _, nudge in ipairs(state.nudges) do
        local axis = axesOf(state.space, basis)[nudge.axis]

        if state.mode == 'move' then
            position += axis * (nudge.step * NUDGE_MOVE)
        elseif tilt or nudge.axis == 3 then
            basis = twist(basis, axis, math.rad(nudge.step * NUDGE_TURN))
        end
    end

    table.wipe(state.drags)
    table.wipe(state.nudges)

    return position, basis
end

---@param entity integer
---@param position vector3
---@param basis vector3[]
local function place(entity, position, basis)
    local right, forward, up = basis[1], basis[2], basis[3]

    SetEntityMatrix(
        entity,
        forward.x,
        forward.y,
        forward.z,
        right.x,
        right.y,
        right.z,
        up.x,
        up.y,
        up.z,
        position.x,
        position.y,
        position.z
    )
end

---@param cam integer
---@param limit? fun(from: vector3, to: vector3): vector3
local function fly(cam, limit)
    local rotation = GetCamRot(cam, 2)
    local pitch = math.min(math.max(rotation.x - GetDisabledControlNormal(0, 2) * LOOK_SPEED, -89.0), 89.0)
    local yaw = (rotation.z - GetDisabledControlNormal(0, 1) * LOOK_SPEED) % 360.0
    local p, h = math.rad(pitch), math.rad(yaw)
    local forward = vec3(-math.sin(h) * math.cos(p), math.cos(h) * math.cos(p), math.sin(p))
    local right = vec3(math.cos(h), math.sin(h), 0.0)
    local move = vec3(0.0, 0.0, 0.0)

    SetCamRot(cam, pitch, 0.0, yaw, 2)

    if IsDisabledControlPressed(0, 32) then move += forward end
    if IsDisabledControlPressed(0, 33) then move -= forward end
    if IsDisabledControlPressed(0, 35) then move += right end
    if IsDisabledControlPressed(0, 34) then move -= right end
    if IsDisabledControlPressed(0, 38) then move += UP end
    if IsDisabledControlPressed(0, 44) then move -= UP end

    local from = GetCamCoord(cam)
    local coords = from + move * (MOVE_SPEED * (IsDisabledControlPressed(0, 21) and FAST or 1.0))

    if limit then coords = limit(from, coords) end

    SetCamCoord(cam, coords.x, coords.y, coords.z)
    SetFocusPosAndVel(coords.x, coords.y, coords.z, 0.0, 0.0, 0.0)
end

---@param shape CustomArea
---@param anchor vector3
---@param from vector3
---@param to vector3
---@return vector3
local function contain(shape, anchor, from, to)
    if modules.areas.contains(shape, to) then return to end
    if not modules.areas.contains(shape, from) then return #(to - anchor) < #(from - anchor) and to or from end

    local step, result = to - from, from

    for _, part in ipairs({ vec3(step.x, 0.0, 0.0), vec3(0.0, step.y, 0.0), vec3(0.0, 0.0, step.z) }) do
        if modules.areas.contains(shape, result + part) then result += part end
    end

    return result
end

local function release()
    if not gizmo then return end

    local cam = gizmo.cam

    gizmo = nil
    SetNuiFocusKeepInput(false)
    SetNuiFocus(false, false)
    RenderScriptCams(false, true, CAM_EASE, true, true)
    DestroyCam(cam, false)
    ClearFocus()
    SendNUIMessage({ action = 'gizmo', data = false })
end

RegisterNUICallback('gizmoDrag', function(data, cb)
    cb(1)

    if not gizmo or type(data) ~= 'table' then return end

    local axis, from, to = AXES[data.axis], pair(data.from), pair(data.to)

    if axis and from and to then gizmo.drags[#gizmo.drags + 1] = { axis = axis, from = from, to = to } end
end)

RegisterNUICallback('gizmoNudge', function(data, cb)
    cb(1)

    if not gizmo or type(data) ~= 'table' then return end

    local axis, step = AXES[data.axis], tonumber(data.step)

    if axis and step and step == step then
        gizmo.nudges[#gizmo.nudges + 1] = { axis = axis, step = lib.math.clamp(step, -NUDGE_LIMIT, NUDGE_LIMIT) }
    end
end)

RegisterNUICallback('gizmoLook', function(data, cb)
    cb(1)

    if gizmo then gizmo.look = type(data) == 'table' and data.active == true end
end)

RegisterNUICallback('gizmoKey', function(data, cb)
    cb(1)

    local key = type(data) == 'table' and data.key

    if gizmo and type(key) == 'string' and COMMANDS[key] then gizmo.commands[#gizmo.commands + 1] = key end
end)

---@return vector3
local function direction()
    local rotation = GetFinalRenderedCamRot(2)
    local pitch, yaw = math.rad(rotation.x), math.rad(rotation.z)
    local flat = math.abs(math.cos(pitch))

    return vec3(-math.sin(yaw) * flat, math.cos(yaw) * flat, math.sin(pitch))
end

---@param probe? integer
---@param aim? vector3
---@param distance? number
---@return integer probe
---@return vector3? aim
local function trace(probe, aim, distance)
    if probe then
        local status, hit, coords = GetShapeTestResult(probe)
        if status == 1 then return probe, aim end

        aim = hit and coords or nil
    end

    local origin = GetFinalRenderedCamCoord()
    local target = origin + direction() * (distance or RAYCAST_DISTANCE)

    return StartShapeTestLosProbe(
        origin.x,
        origin.y,
        origin.z,
        target.x,
        target.y,
        target.z,
        RAYCAST_FLAGS,
        cache.ped,
        4
    ), aim
end

---@param entity integer
---@param fx PlacerEffect
---@return integer?
local function emit(entity, fx)
    if not pcall(lib.requestNamedPtfxAsset, fx.asset) then return end

    UseParticleFxAsset(fx.asset)

    local offset, rotation = fx.offset, fx.rotation
    local handle = StartParticleFxLoopedOnEntity(
        fx.effect,
        entity,
        offset.x,
        offset.y,
        offset.z,
        rotation.x,
        rotation.y,
        rotation.z,
        fx.scale,
        false,
        false,
        false
    )

    SetParticleFxLoopedAlpha(handle, fx.alpha)

    return handle
end

---@param options PlacerOptions
---@return integer
local function ghost(options)
    if options.kind == 'point' or not options.model then return 0 end

    local ok, hash = pcall(lib.requestModel, options.model, 10000)
    if not ok then return 0 end

    local entity = options.kind == 'vehicle' and CreateVehicle(hash, 0.0, 0.0, 0.0, 0.0, false, false)
        or CreateObjectNoOffset(hash, 0.0, 0.0, 0.0, false, false, false)

    SetModelAsNoLongerNeeded(hash)
    SetEntityAlpha(entity, ALPHA, false)
    SetEntityCollision(entity, false, false)
    FreezeEntityPosition(entity, true)

    return entity
end

---@param rotation vector3
---@param tilt boolean
---@return vector3
local function turn(rotation, tilt)
    local step = IsDisabledControlJustPressed(0, SCROLL_UP) and STEP
        or IsDisabledControlJustPressed(0, SCROLL_DOWN) and -STEP
        or nil

    if not step then return rotation end

    if tilt and IsDisabledControlPressed(0, SHIFT) then
        return vec3((rotation.x + step) % 360.0, rotation.y, rotation.z)
    end

    if tilt and IsDisabledControlPressed(0, ALT) then
        return vec3(rotation.x, (rotation.y + step) % 360.0, rotation.z)
    end

    return vec3(rotation.x, rotation.y, (rotation.z + step) % 360.0)
end

---@param segments vector3[][]
---@param colour? integer[]
local function lines(segments, colour)
    local tone = colour or LINE

    for _, segment in ipairs(segments) do
        local a, b = segment[1], segment[2]

        DrawLine(a.x, a.y, a.z, b.x, b.y, b.z, tone[1], tone[2], tone[3], tone[4])
    end
end

---@param options PlacerOptions
---@return PlacerResult?
function placer.run(options)
    if active then return end

    active = true

    local borrowed = options.entity and DoesEntityExist(options.entity) and options.entity or nil
    local entity = borrowed or ghost(options)
    local home, pose, solid

    if borrowed then
        home, pose = GetEntityCoords(entity), GetEntityRotation(entity, 2)
        solid = not GetEntityCollisionDisabled(entity)

        SetEntityAlpha(entity, ALPHA, false)
        SetEntityCollision(entity, false, false)
    end

    local spray = entity ~= 0 and options.effect and emit(entity, options.effect) or nil
    local marker = lib.marker.new({
        type = 1,
        coords = vec3(0.0, 0.0, 0.0),
        width = 0.6,
        height = 0.6,
        color = MARK,
    })
    local shape = options.area
    local bounds = shape and modules.areas.prism(modules.areas.flatten(shape.points), shape.thickness)
    local rotation = options.rotation or vec3(0.0, 0.0, GetEntityHeading(cache.ped))
    local tilt = options.tilt == true
    local handy = options.gizmo == true and entity ~= 0
    local guide = { mode = 'aim', gizmo = handy, tilt = tilt }
    local lift = 0.0
    local probe, aim, result, anchor, basis

    prompt(guide)

    while true do
        for _, control in ipairs(BLOCKED) do
            DisableControlAction(0, control, true)
        end

        if entity ~= 0 and not DoesEntityExist(entity) then break end

        if gizmo then
            DisableAllControlActions(0)

            if gizmo.look then
                fly(gizmo.cam, shape and function(from, to) return contain(shape, anchor, from, to) end or nil)
            end

            anchor, basis = steer(gizmo, anchor, basis, tilt)
            place(entity, anchor, basis)

            local inside = not shape or modules.areas.contains(shape, anchor)
            local command = table.remove(gizmo.commands, 1)

            if bounds then lines(bounds, inside and LINE or OUTSIDE) end

            publish(gizmo, anchor, basis, tilt, inside)

            if command == 'confirm' and inside then
                result = { coords = anchor, rotation = GetEntityRotation(entity, 2) }
                break
            elseif command == 'confirm' then
                lib.notify({ type = 'error', description = locale('placer.outside') })
            elseif command == 'cancel' then
                SetPauseMenuActive(false)
                break
            elseif command == 'aim' then
                rotation = GetEntityRotation(entity, 2)
                release()
                prompt(guide)
            elseif command == 'move' or command == 'rotate' then
                gizmo.mode = command
            elseif command == 'world' or command == 'local' then
                gizmo.space = command
            end

            Wait(0)
            goto continue
        end

        probe, aim = trace(probe, aim)

        local position = aim and aim + vec3(0.0, 0.0, lift)

        if position and entity ~= 0 then
            SetEntityCoordsNoOffset(entity, position.x, position.y, position.z, false, false, false)
            SetEntityRotation(entity, rotation.x, rotation.y, rotation.z, 2, false)

            if options.kind == 'vehicle' then SetVehicleOnGroundProperly(entity) end
        end

        local grounded = options.kind == 'vehicle' and entity ~= 0
        local coords = position and grounded and GetEntityCoords(entity, false) or position
        local inside = coords ~= nil and (not shape or modules.areas.contains(shape, coords))

        if bounds then lines(bounds, inside and LINE or OUTSIDE) end

        if position and entity == 0 then
            marker.coords = position
            marker.color = inside and MARK or MARK_OUTSIDE
            marker:draw()
        end

        rotation = turn(rotation, options.tilt == true)

        if IsDisabledControlPressed(0, RAISE) then lift = math.min(LIFT_LIMIT, lift + LIFT) end
        if IsDisabledControlPressed(0, LOWER) then lift = math.max(-LIFT_LIMIT, lift - LIFT) end

        if coords and IsDisabledControlJustPressed(0, CONFIRM) then
            if inside then
                result = { coords = coords, rotation = rotation }
                break
            end

            lib.notify({ type = 'error', description = locale('placer.outside') })
        end

        if IsDisabledControlJustPressed(0, CANCEL) then break end

        if handy and coords and IsDisabledControlJustPressed(0, GIZMO) then
            local forward, right, up = GetEntityMatrix(entity)
            local eye, view = GetGameplayCamCoord(), GetGameplayCamRot(2)
            local fov = GetGameplayCamFov()
            local cam = CreateCamWithParams(
                'DEFAULT_SCRIPTED_CAMERA',
                eye.x,
                eye.y,
                eye.z,
                view.x,
                0.0,
                view.z,
                fov,
                true,
                2
            )

            anchor, basis = coords, { right, forward, up }
            gizmo = {
                mode = 'move',
                space = 'world',
                drags = {},
                nudges = {},
                commands = {},
                sent = '',
                cam = cam,
                look = false,
            }
            RenderScriptCams(true, true, CAM_EASE, true, true)
            prompt(false)
            SetNuiFocus(true, true)
            SetNuiFocusKeepInput(true)
        end

        Wait(0)

        ::continue::
    end

    release()
    prompt(false)

    if spray then StopParticleFxLooped(spray, false) end

    if borrowed and DoesEntityExist(entity) then
        SetEntityCoordsNoOffset(entity, home.x, home.y, home.z, false, false, false)
        SetEntityRotation(entity, pose.x, pose.y, pose.z, 2, false)
        SetEntityCollision(entity, solid, false)
        ResetEntityAlpha(entity)
    elseif entity ~= 0 and DoesEntityExist(entity) then
        DeleteEntity(entity)
    end

    active = false

    return result
end

---@param initial vector3[]
---@param thickness number
---@return CustomArea?
function placer.polygon(initial, thickness)
    if active then return end

    active = true

    local coords, rotation = GetGameplayCamCoord(), GetGameplayCamRot(2)
    local cam = CreateCamWithParams(
        'DEFAULT_SCRIPTED_CAMERA',
        coords.x,
        coords.y,
        coords.z,
        rotation.x,
        0.0,
        rotation.z,
        GetGameplayCamFov(),
        true,
        2
    )
    local dot = lib.marker.new({ type = 28, coords = coords, width = 0.12, height = 0.12 })
    local pointer = lib.marker.new({ type = 28, coords = coords, width = 0.16, height = 0.16, color = CURSOR })
    local points = table.clone(initial)
    local height = math.min(math.max(thickness, modules.areas.MIN_HEIGHT), modules.areas.MAX_HEIGHT)
    local level = #points > 0 and modules.areas.level(points) or GetEntityCoords(cache.ped).z - FEET
    local lift, result = 0.0, nil

    local function hint()
        prompt({ mode = 'polygon', points = #points, max = modules.areas.MAX_POINTS, height = height })
    end

    RenderScriptCams(true, true, 400, true, true)
    hint()

    while true do
        DisableAllControlActions(0)
        fly(cam)

        local origin, ray = GetFinalRenderedCamCoord(), direction()
        local distance = math.abs(ray.z) > 1e-4 and (level + lift - origin.z) / ray.z or -1.0
        local cursor = distance > 0.0 and distance <= POLYGON_DISTANCE and origin + ray * distance or nil
        local ring = table.clone(points)

        if cursor and #ring < modules.areas.MAX_POINTS then ring[#ring + 1] = cursor end
        if #ring > 0 then lines(modules.areas.prism(modules.areas.flatten(ring), height)) end

        for _, point in ipairs(points) do
            dot.coords = point
            dot:draw()
        end

        if cursor then
            pointer.coords = cursor
            pointer:draw()
        end

        local changed = true

        if IsDisabledControlJustPressed(0, 24) and cursor and #points < modules.areas.MAX_POINTS then
            local last = points[#points]

            if not last or #(cursor.xy - last.xy) > POINT_GAP then points[#points + 1] = cursor end
        elseif (IsDisabledControlJustPressed(0, 25) or IsDisabledControlJustPressed(0, 194)) and #points > 0 then
            points[#points] = nil
        elseif IsDisabledControlJustReleased(0, 17) then
            height = math.min(modules.areas.MAX_HEIGHT, height + HEIGHT_STEP)
        elseif IsDisabledControlJustReleased(0, 16) then
            height = math.max(modules.areas.MIN_HEIGHT, height - HEIGHT_STEP)
        elseif IsDisabledControlJustReleased(0, 201) and #points >= 3 then
            result = { points = modules.areas.flatten(points), thickness = height }
            break
        elseif IsDisabledControlJustReleased(0, 200) then
            SetPauseMenuActive(false)
            break
        elseif IsDisabledControlPressed(0, 45) then
            lift = math.min(LIFT_LIMIT, lift + LIFT)
        elseif IsDisabledControlPressed(0, 23) then
            lift = math.max(-LIFT_LIMIT, lift - LIFT)
        else
            changed = false
        end

        if changed then hint() end

        Wait(0)
    end

    RenderScriptCams(false, true, 400, true, true)
    DestroyCam(cam, false)
    ClearFocus()
    prompt(false)

    active = false

    return result
end

return placer
