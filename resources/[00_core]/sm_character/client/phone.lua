local config = require 'config.client'.phone
local debugMode = require 'config.client'.debug
local camera = require 'modules.client.camera'
local utils = require 'modules.client.utils'
local nui = require 'modules.client.nui'

local OPEN_FLAG <const> = 2 | 16 | 32 | 8 | 1048576
local CLOSE_FLAG <const> = 16 | 32 | 1048576
local HEAD_BONE <const> = 31086
local CALIBRATION <const> = { { 0.15, 0.15 }, { 0.85, 0.85 } }
local DUI_TIMEOUT <const> = 8000
local PAGE_TIMEOUT <const> = 5000
local FIRST_RENDER_MS <const> = 150
local BIND_TIMEOUT <const> = 10000
local BIND_INTERVAL <const> = 250
local PROP_TIMEOUT <const> = 8000
local PROP_RETRY_MS <const> = 1000
local PRELOAD_TIMEOUT <const> = 60000
local RESEND_DELAYS <const> = { 1000, 3000 }
local RUNTIME_TXD <const> = ('%s_phone'):format(cache.resource)
local OFF_SIZE <const> = 4
local OFF_COLOR <const> = { 20, 20, 20 }
local GLIDE_MS <const> = 1800
local REFOCUS_MS <const> = 600
local ARC_SIDE <const> = 0.55
local ARC_LIFT <const> = 0.18
local ARC_LEAD <const> = 0.12

local phone = {}

---@class PhoneScreen
---@field center vector3
---@field normal vector3
---@field up vector3
---@field raw vector3[]
---@field corners vector3[]
---@field power vector3[]

---@class PhoneDui
---@field id integer
---@field object integer
---@field created integer
---@field txn? string

---@class PhoneOptions
---@field child? boolean
---@field steady? fun(): boolean

---@class PhoneState
---@field ped number
---@field steady? fun(): boolean
---@field stance? { dict: string, clip: string }
---@field prop? number
---@field dui? PhoneDui
---@field pageReady boolean
---@field screen? PhoneScreen
---@field view { distance: number, lift: number, fov: number }
---@field list table[]
---@field info table
---@field onPick fun(id: string)
---@field animated boolean
---@field replaced boolean
---@field powered boolean
---@field rendering boolean
---@field renders integer
---@field attaching boolean
---@field closed boolean
---@field poweredAt? integer

---@class ScreenUv
---@field left number
---@field top number
---@field right number
---@field bottom number

---@type PhoneState?
local active
---@type { u: number, v: number }[]?
local calibration
---@type integer?
local runtimeTxd
local textures = 0
local duis = 0

---@param ax number
---@param ay number
---@param bx number
---@param by number
---@return number
local function cross2(ax, ay, bx, by)
    return ax * by - ay * bx
end

---@param a vector3
---@param b vector3
---@return vector3
local function cross3(a, b)
    return vec3(a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x)
end

---@param axis integer
---@param sign number
---@return vector3
local function unit(axis, sign)
    return vec3(axis == 1 and sign or 0.0, axis == 2 and sign or 0.0, axis == 3 and sign or 0.0)
end

---@param prop number
---@param offset vector3
---@return vector3
local function toWorld(prop, offset)
    return GetOffsetFromEntityInWorldCoords(prop, offset.x, offset.y, offset.z)
end

---@param raw vector3[]
---@param uv ScreenUv
---@return vector3[]
local function applyUv(raw, uv)
    local function at(u, v)
        local top = raw[1] + (raw[2] - raw[1]) * u
        local bottom = raw[4] + (raw[3] - raw[4]) * u

        return top + (bottom - top) * v
    end

    return { at(uv.left, uv.top), at(uv.right, uv.top), at(uv.right, uv.bottom), at(uv.left, uv.bottom) }
end

---@param prop number
---@param ped number
---@return PhoneScreen
local function measureScreen(prop, ped)
    local min, max = GetModelDimensions(config.model)
    local size = { max.x - min.x, max.y - min.y, max.z - min.z }
    local mid = (min + max) / 2
    local order = { 1, 2, 3 }

    table.sort(order, function(a, b) return size[a] < size[b] end)

    local thin, short, long = order[1], order[2], order[3]
    local head = GetPedBoneCoords(ped, HEAD_BONE, 0.0, 0.0, 0.0)
    local normal = unit(thin, 1.0)

    if #(toWorld(prop, mid + normal * size[thin]) - head) > #(toWorld(prop, mid - normal * size[thin]) - head) then
        normal = unit(thin, -1.0)
    end

    local up = unit(long, 1.0)

    if toWorld(prop, mid + up).z < toWorld(prop, mid - up).z then
        up = unit(long, -1.0)
    end

    local right = cross3(up, normal)
    local inset = config.screen.inset
    local center = mid + normal * (size[thin] / 2 + config.screen.offset)
    local top = size[long] / 2 - size[long] * inset.top
    local bottom = -size[long] / 2 + size[long] * inset.bottom
    local side = size[short] / 2 - size[short] * inset.x

    local raw = {
        center + up * top - right * side,
        center + up * top + right * side,
        center + up * bottom + right * side,
        center + up * bottom - right * side,
    }

    return {
        center = center,
        normal = normal,
        up = up,
        raw = raw,
        corners = config.screen.uv and applyUv(raw, config.screen.uv) or raw,
        power = applyUv(raw, config.powerButton),
    }
end

---@param state PhoneState
---@return boolean
local function hasScreen(state)
    return state.screen ~= nil and state.prop ~= nil and DoesEntityExist(state.prop)
end

---@param state PhoneState
---@param corners? vector3[]
---@return vector3[]
local function worldCorners(state, corners)
    corners = corners or state.screen.corners

    local points = {}

    for i = 1, 4 do
        points[i] = toWorld(state.prop, corners[i])
    end

    return points
end

---@param points vector3[]
---@param dict string
---@param name string
local function drawScreen(points, dict, name)
    local a, b, c, d = points[1], points[2], points[3], points[4]

    DrawTexturedPoly(a.x, a.y, a.z, b.x, b.y, b.z, c.x, c.y, c.z, 255, 255, 255, 255, dict, name, 0.0, 0.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0)
    DrawTexturedPoly(a.x, a.y, a.z, c.x, c.y, c.z, d.x, d.y, d.z, 255, 255, 255, 255, dict, name, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0)
    DrawTexturedPoly(c.x, c.y, c.z, b.x, b.y, b.z, a.x, a.y, a.z, 255, 255, 255, 255, dict, name, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 0.0, 0.0, 1.0)
    DrawTexturedPoly(d.x, d.y, d.z, c.x, c.y, c.z, a.x, a.y, a.z, 255, 255, 255, 255, dict, name, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 0.0, 1.0)
end

---@param points vector3[]
---@param r integer
---@param g integer
---@param b integer
local function drawEdges(points, r, g, b)
    for i = 1, 4 do
        local from, to = points[i], points[i % 4 + 1]
        DrawLine(from.x, from.y, from.z, to.x, to.y, to.z, r, g, b, 255)
    end
end

---@param points vector3[]
local function drawOutline(points)
    drawEdges(points, 34, 184, 207)
    DrawLine(points[1].x, points[1].y, points[1].z, points[3].x, points[3].y, points[3].z, 250, 82, 82, 255)
end

---@param state PhoneState
---@return vector3
local function screenTarget(state)
    local prop = state.prop

    if prop and DoesEntityExist(prop) then
        return state.screen and toWorld(prop, state.screen.center) or GetEntityCoords(prop)
    end

    return GetPedBoneCoords(state.ped, config.bone, 0.0, 0.0, 0.0)
end

---@param state PhoneState
---@return vector3 position
---@return vector3 target
local function framing(state)
    local view = state.view
    local target = screenTarget(state)
    local direction = GetPedBoneCoords(state.ped, HEAD_BONE, 0.0, 0.0, 0.0) - target
    local length = #direction

    if length < 0.001 then
        return target + vec3(0.0, 0.0, view.distance), target
    end

    local distance = math.min(view.distance, length * 0.8)

    return target + (direction / length) * distance + vec3(0.0, 0.0, view.lift), target
end

---@param state PhoneState
---@return number? x
---@return number? y
local function powerAnchor(state)
    if not hasScreen(state) then return end

    local area = state.screen.power
    local point = toWorld(state.prop, (area[2] + area[3]) / 2)
    local visible, x, y = GetScreenCoordFromWorldCoord(point.x, point.y, point.z)

    if visible then return x, y end
end

---@param state PhoneState
---@param durationMs integer
---@param arc boolean
local function focusScreen(state, durationMs, arc)
    local position, target = framing(state)
    local from = arc and camera.view()
    local head = GetPedBoneCoords(state.ped, HEAD_BONE, 0.0, 0.0, 0.0)
    local ahead = target - head
    local reach = math.sqrt(ahead.x * ahead.x + ahead.y * ahead.y)
    local via

    if from and reach > 0.001 then
        local forward = vec3(ahead.x / reach, ahead.y / reach, 0.0)
        local right = vec3(forward.y, -forward.x, 0.0)
        local offset = from.position - head
        local side = (offset.x * right.x + offset.y * right.y >= 0.0 and 1.0 or -1.0) * ARC_SIDE
        local beside = position + right * side + forward * ARC_LEAD + vec3(0.0, 0.0, ARC_LIFT)

        via = { (from.position + beside) / 2, position + (beside - position) * 0.8 }
    end

    camera.glide({ position = position, target = target, fov = state.view.fov, dof = { near = 0.05, far = 0.6 } }, durationMs, via)
end

---@param state PhoneState
local function run(state)
    CreateThread(function()
        local sentX, sentY = -2.0, -2.0

        while active == state do
            local x, y = powerAnchor(state)

            if math.abs((x or -1.0) - sentX) + math.abs((y or -1.0) - sentY) > 0.0008 then
                sentX, sentY = x or -1.0, y or -1.0
                nui.send('phoneAnchor', { x = x, y = y })
            end

            local poly = config.render == 'poly' and state.powered and state.dui?.txn

            if (poly or debugMode) and hasScreen(state) then
                local points = worldCorners(state)

                if poly then
                    drawScreen(points, RUNTIME_TXD, poly)
                end

                if debugMode then
                    drawOutline(points)
                    drawEdges(worldCorners(state, state.screen.power), 250, 200, 60)
                end
            end

            Wait(0)
        end
    end)
end

---@param state PhoneState
local function measure(state)
    if state.screen or not state.prop or not DoesEntityExist(state.prop) then return end

    state.screen = measureScreen(state.prop, state.ped)

    if debugMode then
        lib.print.info(('layar HP: tengah %s, normal %s, atas %s'):format(state.screen.center, state.screen.normal, state.screen.up))
    end
end

---@param state PhoneState
---@param prop number
local function attachTo(state, prop)
    local ped = state.ped

    AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, config.bone), config.offset.x, config.offset.y, config.offset.z, config.rotation.x, config.rotation.y, config.rotation.z, false, false, false, false, 2, true)
end

---@param state PhoneState
---@return boolean created
local function attachProp(state)
    if state.attaching or state.prop and DoesEntityExist(state.prop) then return false end

    state.attaching = true

    local prop = utils.createObject(config.model, GetEntityCoords(state.ped), PROP_TIMEOUT)

    state.attaching = false

    if not prop then return false end

    if state.closed then
        DeleteEntity(prop)
        return false
    end

    attachTo(state, prop)
    state.prop = prop
    state.screen = nil

    return true
end

---@param state PhoneState
---@return boolean raised
local function holdPose(state)
    if not state.animated or IsEntityPlayingAnim(state.ped, config.dict, config.enter, 3) then return false end

    TaskPlayAnim(state.ped, config.dict, config.enter, 8.0, -8.0, -1, OPEN_FLAG, 0.0, false, false, false)
    Wait(math.floor(GetAnimDuration(config.dict, config.enter) * 1000))

    return true
end

---@param state PhoneState
local function stand(state)
    local stances = config.stance
    if not stances then return end

    local stance = IsPedMale(state.ped) and stances.male or stances.female

    if not utils.loadAnimDict(stance.dict) then return end

    TaskPlayAnim(state.ped, stance.dict, stance.clip, 8.0, -8.0, -1, 1, 0.0, false, false, false)

    pcall(lib.waitFor, function()
        return IsEntityPlayingAnim(state.ped, stance.dict, stance.clip, 3) or nil
    end, nil, 500)

    SetEntityAnimSpeed(state.ped, stance.dict, stance.clip, 0.0)
    state.stance = stance
end

---@param state PhoneState
local function steady(state)
    if state.steady and state.steady() then return end

    stand(state)
end

---@param state PhoneState
local function raise(state)
    local ped = state.ped

    steady(state)
    state.animated = utils.loadAnimDict(config.dict)

    if state.animated then
        TaskPlayAnim(ped, config.dict, config.enter, 8.0, -8.0, -1, OPEN_FLAG, 0.0, false, false, false)
        Wait(300)
    end

    attachProp(state)

    if state.animated then
        Wait(math.max(GetAnimDuration(config.dict, config.enter) * 1000 - 300, 0))
    end

    measure(state)
end

---@param state PhoneState
local function createDui(state)
    duis += 1

    local url = ('https://cfx-nui-%s/web/build/phone.html?dui=%d'):format(cache.resource, duis)
    local dui = { id = duis, object = CreateDui(url, config.resolution.x, config.resolution.y), created = GetGameTimer() }

    state.pageReady = false
    state.dui = dui
    lib.print.info(('dui %d: dibuat'):format(dui.id))

    CreateThread(function()
        while state.dui == dui and not IsDuiAvailable(dui.object) do
            Wait(100)
        end

        if state.dui == dui then
            lib.print.info(('dui %d: browser tersedia (%d ms)'):format(dui.id, GetGameTimer() - dui.created))
        end
    end)
end

---@return integer
local function phoneTxd()
    runtimeTxd = runtimeTxd or CreateRuntimeTxd(RUNTIME_TXD)

    return runtimeTxd
end

---@param state PhoneState
---@param dui PhoneDui
---@return string? txn
---@return integer attempts
---@return integer elapsed
local function bindDui(state, dui)
    if dui.txn then return dui.txn, 0, 0 end

    local began = GetGameTimer()
    local attempts = 0

    repeat
        attempts += 1
        textures += 1

        local txn = ('screen_%d'):format(textures)
        local texture = CreateRuntimeTextureFromDuiHandle(phoneTxd(), txn, GetDuiHandle(dui.object))

        if texture and texture ~= 0 and GetRuntimeTextureWidth(texture) > 0 then
            dui.txn = txn

            return txn, attempts, GetGameTimer() - began
        end

        Wait(BIND_INTERVAL)
    until active ~= state or GetGameTimer() - began >= BIND_TIMEOUT

    return nil, attempts, GetGameTimer() - began
end

---@param dui PhoneDui
---@param message table
local function postDui(dui, message)
    SendDuiMessage(dui.object, json.encode(message))
end

---@param state PhoneState
local function screenOff(state)
    textures += 1

    local txn = ('off_%d'):format(textures)
    local texture = CreateRuntimeTexture(phoneTxd(), txn, OFF_SIZE, OFF_SIZE)

    for x = 0, OFF_SIZE - 1 do
        for y = 0, OFF_SIZE - 1 do
            SetRuntimeTexturePixel(texture, x, y, OFF_COLOR[1], OFF_COLOR[2], OFF_COLOR[3], 255)
        end
    end

    CommitRuntimeTexture(texture)
    RemoveReplaceTexture(config.txd, config.txn)
    AddReplaceTexture(config.txd, config.txn, RUNTIME_TXD, txn)
    state.replaced = true
end

---@param state PhoneState
local function restoreScreen(state)
    if not state.replaced then return end

    RemoveReplaceTexture(config.txd, config.txn)
    state.replaced = false
end

---@param state PhoneState
local function destroyDui(state)
    local dui = state.dui
    if not dui then return end

    state.dui = nil
    SetDuiUrl(dui.object, 'about:blank')
    DestroyDui(dui.object)
    lib.print.info(('dui %d: dihapus'):format(dui.id))
end

---@param state PhoneState
local function sendLocations(state)
    if not state.dui then return end

    postDui(state.dui, { action = 'locations', data = { locations = state.list, character = state.info } })
end

---@param state PhoneState
---@param cooldown? integer
local function sendStatus(state, cooldown)
    nui.send('phoneStatus', { powered = state.powered, cooldown = cooldown })
end

---@param state PhoneState
---@param check fun(): boolean
---@param timeout integer
---@return boolean
local function waitUntil(state, check, timeout)
    pcall(lib.waitFor, function()
        if active ~= state or check() then return true end
    end, nil, timeout)

    return active == state and check()
end

---@param state PhoneState
local function showProp(state)
    if not state.powered then
        screenOff(state)
    elseif state.dui?.txn and config.render == 'texture' then
        RemoveReplaceTexture(config.txd, config.txn)
        AddReplaceTexture(config.txd, config.txn, RUNTIME_TXD, state.dui.txn)
        state.replaced = true
    end

    Wait(100)
    measure(state)

    if active ~= state then return end

    focusScreen(state, REFOCUS_MS, false)
    nui.send('phone', { visible = true, fallback = not hasScreen(state) })
end

---@param state PhoneState
---@param attempts integer
---@return integer attempts
local function checkProp(state, attempts)
    if active ~= state or state.attaching then return attempts end

    local prop = state.prop

    if prop and DoesEntityExist(prop) then
        if not IsEntityAttachedToEntity(prop, state.ped) then
            lib.print.warn('prop hp: lepas dari tangan, dipasang ulang')
            attachTo(state, prop)
        end

        return 0
    end

    if prop then
        state.prop = nil
        lib.print.warn('prop hp: hilang, dibuat ulang')
    end

    attempts += 1

    if not attachProp(state) then
        if active == state then
            lib.print.warn(('prop hp: gagal dibuat (percobaan %d)'):format(attempts))
        end

        return attempts
    end

    lib.print.info(('prop hp: dibuat (percobaan %d)'):format(attempts))
    showProp(state)

    return 0
end

---@param state PhoneState
local function keepProp(state)
    CreateThread(function()
        local attempts = 0

        while active == state do
            Wait(PROP_RETRY_MS)
            attempts = checkProp(state, attempts)
        end
    end)
end

---@param state PhoneState
local function render(state)
    state.renders += 1

    local renders = state.renders

    if not state.animated then
        state.animated = utils.loadAnimDict(config.dict)
    end

    local moved = holdPose(state)

    if attachProp(state) then
        moved = true
        screenOff(state)
        Wait(100)
    end

    measure(state)

    if moved and active == state then
        focusScreen(state, REFOCUS_MS, false)
    end

    if not state.dui then
        createDui(state)
    end

    local dui = state.dui --[[@as PhoneDui]]

    if not waitUntil(state, function() return IsDuiAvailable(dui.object) end, DUI_TIMEOUT) then
        if active ~= state then return end

        lib.print.error(('dui %d: browser tidak tersedia (%d ms), dibatalkan'):format(dui.id, GetGameTimer() - dui.created))
        destroyDui(state)
        state.powered = false
        return
    end

    if not waitUntil(state, function() return state.pageReady end, PAGE_TIMEOUT) then
        if active ~= state then return end

        lib.print.warn(('dui %d: halaman belum siap (%d ms), texture tetap diikat'):format(dui.id, GetGameTimer() - dui.created))
    end

    Wait(FIRST_RENDER_MS)

    if active ~= state then return end

    local txn, attempts, elapsed = bindDui(state, dui)

    if active ~= state then return end

    if not txn then
        lib.print.error(('dui %d: texture tidak terikat (%d percobaan, %d ms), dibatalkan'):format(dui.id, attempts, elapsed))
        destroyDui(state)
        state.powered = false
        return
    end

    if attempts > 0 then
        local log = attempts > 1 and lib.print.warn or lib.print.info

        log(('dui %d: texture terikat (percobaan %d, %d ms)'):format(dui.id, attempts, elapsed))
    end

    if config.render == 'texture' then
        RemoveReplaceTexture(config.txd, config.txn)
        AddReplaceTexture(config.txd, config.txn, RUNTIME_TXD, txn)
        state.replaced = true
    end

    lib.print.info(('dui %d: layar on'):format(dui.id))
    state.powered = true
    postDui(dui, { action = 'power' })
    sendLocations(state)

    for i = 1, #RESEND_DELAYS do
        SetTimeout(RESEND_DELAYS[i], function()
            if active == state and state.renders == renders then
                sendLocations(state)
            end
        end)
    end

    nui.send('phone', { visible = true, fallback = not hasScreen(state) })
end

---@param state PhoneState
---@return boolean
local function power(state)
    if state.rendering then return false end

    state.rendering = true

    local ok, result = pcall(render, state)

    state.rendering = false

    if not ok then
        lib.print.error(('gagal render handphone: %s'):format(result))
    end

    if active == state then
        sendStatus(state)
    end

    return ok
end

---@param state PhoneState
local function powerOff(state)
    state.renders += 1
    state.powered = false
    calibration = nil
    screenOff(state)
    lib.print.info(('dui %d: layar off'):format(state.dui and state.dui.id or 0))
    destroyDui(state)
    createDui(state)
    sendStatus(state)
end

---@param corners vector3[]
---@param x number
---@param y number
---@return number? u
---@return number? v
local function cursorUv(corners, x, y)
    local points = {}

    for i = 1, 4 do
        local visible, sx, sy = GetScreenCoordFromWorldCoord(corners[i].x, corners[i].y, corners[i].z)

        if not visible then return end

        points[i] = { x = sx, y = sy }
    end

    local p0, p1, p2, p3 = points[1], points[2], points[3], points[4]
    local u, v = 0.5, 0.5

    for _ = 1, 10 do
        local iu, iv = 1 - u, 1 - v
        local qx = iu * iv * p0.x + u * iv * p1.x + u * v * p2.x + iu * v * p3.x
        local qy = iu * iv * p0.y + u * iv * p1.y + u * v * p2.y + iu * v * p3.y
        local ex, ey = x - qx, y - qy

        if math.abs(ex) < 0.00001 and math.abs(ey) < 0.00001 then break end

        local dux = -iv * p0.x + iv * p1.x + v * p2.x - v * p3.x
        local duy = -iv * p0.y + iv * p1.y + v * p2.y - v * p3.y
        local dvx = -iu * p0.x - u * p1.x + u * p2.x + iu * p3.x
        local dvy = -iu * p0.y - u * p1.y + u * p2.y + iu * p3.y
        local det = cross2(dux, duy, dvx, dvy)

        if math.abs(det) < 0.0000001 then break end

        u = u + cross2(ex, ey, dvx, dvy) / det
        v = v + cross2(dux, duy, ex, ey) / det
    end

    return u, v
end

---@param x number
---@param y number
---@return number? u
---@return number? v
local function screenToUv(x, y)
    local u, v = cursorUv(worldCorners(active --[[@as PhoneState]]), x, y)

    if not u or u < 0 or u > 1 or v < 0 or v > 1 then return end

    if config.render == 'texture' then
        if config.screen.flipX then u = 1 - u end
        if config.screen.flipY then v = 1 - v end
    end

    return u, v
end

---@param state PhoneState
---@param x number
---@param y number
---@return boolean
local function onPowerButton(state, x, y)
    local corners = worldCorners(state, state.screen.power)
    local points = {}

    for i = 1, 4 do
        local visible, sx, sy = GetScreenCoordFromWorldCoord(corners[i].x, corners[i].y, corners[i].z)

        if not visible then return false end

        points[i] = { x = sx, y = sy }
    end

    local sign = 0

    for i = 1, 4 do
        local a, b = points[i], points[i % 4 + 1]
        local side = cross2(b.x - a.x, b.y - a.y, x - a.x, y - a.y)
        local current = side > 0 and 1 or side < 0 and -1 or 0

        if current ~= 0 then
            if sign ~= 0 and current ~= sign then return false end

            sign = current
        end
    end

    return true
end

---@param state PhoneState
---@return boolean ok
---@return integer wait
local function tryPower(state)
    local now = GetGameTimer()
    local wait = state.poweredAt and state.poweredAt + config.powerCooldown - now or 0

    if wait > 0 or state.rendering then return false, math.max(wait, 0) end

    state.poweredAt = now
    sendStatus(state, config.powerCooldown)

    CreateThread(function()
        if state.powered then
            powerOff(state)
        else
            power(state)
        end
    end)

    return true, config.powerCooldown
end

---@param state PhoneState
---@param step integer
local function showCalibration(state, step)
    postDui(state.dui --[[@as PhoneDui]], { action = 'calibrate', data = { step = step, targets = CALIBRATION } })
end

---@param x number
---@param y number
local function calibrateClick(x, y)
    local state = active --[[@as PhoneState]]
    local u, v = cursorUv(worldCorners(state, state.screen.raw), x, y)
    if not u or not calibration then return end

    calibration[#calibration + 1] = { u = u, v = v }

    if #calibration < #CALIBRATION then
        return showCalibration(state, #calibration + 1)
    end

    local first, second = calibration[1], calibration[2]
    local a, b = CALIBRATION[1], CALIBRATION[2]
    local width = (second.u - first.u) / (b[1] - a[1])
    local height = (second.v - first.v) / (b[2] - a[2])

    calibration = nil
    showCalibration(state, 0)

    if math.abs(width) < 0.05 or math.abs(height) < 0.05 then
        return lib.print.warn('kalibrasi layar HP gagal: dua klik terlalu berdekatan, ulangi /smchar_phonecal')
    end

    ---@type ScreenUv
    local uv = { left = first.u - a[1] * width, top = first.v - a[2] * height }

    uv.right = uv.left + width
    uv.bottom = uv.top + height
    state.screen.corners = applyUv(state.screen.raw, uv)

    lib.print.info(('kalibrasi layar HP: uv = { left = %.4f, top = %.4f, right = %.4f, bottom = %.4f }'):format(uv.left, uv.top, uv.right, uv.bottom))
end

---@param list table[]
---@param info table
---@param onPick fun(id: string)
---@param options? PhoneOptions
function phone.open(list, info, onPick, options)
    options = options or {}

    ---@type PhoneState
    local state = {
        ped = PlayerPedId(),
        steady = options.steady,
        view = options.child and config.childCamera or config.camera,
        list = list,
        info = info,
        onPick = onPick,
        animated = false,
        pageReady = false,
        replaced = false,
        powered = false,
        rendering = false,
        renders = 0,
        attaching = false,
        closed = false,
    }

    screenOff(state)
    raise(state)
    screenOff(state)

    active = state
    createDui(state)
    focusScreen(state, GLIDE_MS, true)
    run(state)
    keepProp(state)

    nui.send('phone', { visible = true, fallback = not hasScreen(state) })
    sendStatus(state)
    nui.focus(true)
end

---@param list table[]
---@param info table
function phone.rerender(list, info)
    local state = active
    if not state then return end

    state.list = list
    state.info = info

    if state.powered then
        sendLocations(state)
    end
end

---@param list table[]
---@param info table
---@return boolean
function phone.render(list, info)
    local state = active
    if not state or state.rendering then return false end

    state.list = list
    state.info = info

    if state.powered then
        powerOff(state)
    end

    return power(state)
end

---@return boolean
function phone.isOpen()
    return active ~= nil
end

function phone.preload()
    CreateThread(function()
        utils.loadModel(config.model, PRELOAD_TIMEOUT)
        utils.loadAnimDict(config.dict, PRELOAD_TIMEOUT)

        if config.stance then
            utils.loadAnimDict(config.stance.male.dict, PRELOAD_TIMEOUT)
            utils.loadAnimDict(config.stance.female.dict, PRELOAD_TIMEOUT)
        end
    end)
end

---@return boolean
function phone.calibrate()
    if not active or not active.powered or not hasScreen(active) then return false end

    calibration = {}
    showCalibration(active, 1)

    return true
end

---@param instant? boolean
function phone.close(instant)
    local state = active
    if not state then return end

    active = nil
    calibration = nil
    state.closed = true

    nui.send('phone', { visible = false })
    nui.focus(false)
    restoreScreen(state)
    destroyDui(state)

    if not instant and state.animated then
        TaskPlayAnim(state.ped, config.dict, config.exit, 8.0, -8.0, 950, CLOSE_FLAG, 0.0, false, false, false)
        Wait(400)
    end

    if state.prop and DoesEntityExist(state.prop) then
        DeleteEntity(state.prop)
    end

    if state.stance then
        StopAnimTask(state.ped, state.stance.dict, state.stance.clip, 2.0)
        RemoveAnimDict(state.stance.dict)
    end

    RemoveAnimDict(config.dict)
end

RegisterNUICallback('phonePower', function(_, cb)
    if not active then return cb({ ok = false }) end

    local ok, wait = tryPower(active)

    cb({ ok = ok, wait = wait })
end)

RegisterNUICallback('phoneReady', function(data, cb)
    cb(1)

    local dui = active and active.dui
    local id = type(data) == 'table' and math.tointeger(data.dui)

    if not dui or id ~= dui.id then return end

    active.pageReady = true
    lib.print.info(('dui %d: halaman siap (%d ms)'):format(dui.id, GetGameTimer() - dui.created))

    if active.powered then
        postDui(dui, { action = 'power' })
    end

    sendLocations(active)
end)

RegisterNUICallback('phoneMouse', function(data, cb)
    cb(1)

    if not active or not hasScreen(active) or type(data) ~= 'table' then return end

    if data.type == 'down' and data.button ~= 2 then
        local x, y = tonumber(data.x) or -1, tonumber(data.y) or -1
        local hit = onPowerButton(active, x, y)

        if debugMode then
            lib.print.info(('klik %.3f, %.3f: tombol power %s'):format(x, y, hit and 'kena' or 'tidak kena'))
        end

        if hit then
            tryPower(active)
            return
        end
    end

    if not active.powered then return end

    if calibration and data.type ~= 'move' then
        if data.type == 'down' and data.button ~= 2 then
            calibrateClick(tonumber(data.x) or -1, tonumber(data.y) or -1)
        end

        return
    end

    local u, v = screenToUv(tonumber(data.x) or -1, tonumber(data.y) or -1)

    if debugMode and data.type == 'down' then
        lib.print.info(('klik layar %.3f, %.3f -> uv %s'):format(tonumber(data.x) or -1, tonumber(data.y) or -1, u and ('%.3f, %.3f'):format(u, v) or 'di luar layar'))
    end

    if not u or not active.dui then return end

    local object = active.dui.object

    SendDuiMouseMove(object, math.floor(u * config.resolution.x + 0.5), math.floor(v * config.resolution.y + 0.5))

    if data.type == 'down' then
        SendDuiMouseDown(object, data.button == 2 and 'right' or 'left')
    elseif data.type == 'up' then
        SendDuiMouseUp(object, data.button == 2 and 'right' or 'left')
    elseif data.type == 'wheel' then
        SendDuiMouseWheel(object, -(tonumber(data.delta) or 0), 0.0)
    end
end)

RegisterNUICallback('phoneKey', function(data, cb)
    cb(1)

    if not active or not active.powered or not active.dui or type(data) ~= 'table' or type(data.key) ~= 'string' then return end

    postDui(active.dui, { action = 'key', data = { key = data.key } })
end)

RegisterNUICallback('phonePick', function(data, cb)
    cb(1)

    if not active or type(data) ~= 'table' or type(data.id) ~= 'string' then return end

    local onPick = active.onPick

    CreateThread(function()
        onPick(data.id)
    end)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource or not active then return end

    restoreScreen(active)
    destroyDui(active)

    if active.prop and DoesEntityExist(active.prop) then
        DeleteEntity(active.prop)
    end

    if active.stance then
        StopAnimTask(active.ped, active.stance.dict, active.stance.clip, 2.0)
    end
end)

return phone
