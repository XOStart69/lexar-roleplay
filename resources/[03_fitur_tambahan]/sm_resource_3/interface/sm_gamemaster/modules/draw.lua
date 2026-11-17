local state = localmodule 'modules.state'
local util = localmodule 'modules.util'
local selection = localmodule 'modules.selection'
local orders = localmodule 'modules.orders'
local spawn = localmodule 'modules.spawn'
local camera = localmodule 'modules.camera'

local pairs = pairs
local mfloor = math.floor
local sqrt = math.sqrt
local tremove = table.remove
local twipe = table.wipe
local GetGameTimer = GetGameTimer
local DoesEntityExist = DoesEntityExist
local IsEntityAPed = IsEntityAPed
local GetEntityCoords = GetEntityCoords
local DrawMarker = DrawMarker
local DrawLine = DrawLine
local DrawRect = DrawRect
local SetDrawOrigin = SetDrawOrigin
local ClearDrawOrigin = ClearDrawOrigin

local RING_MS = 220
local ORDER_MS = 260

local COLOR_PED = { 38, 187, 183 }
local COLOR_VEHICLE = { 245, 160, 60 }
local COLOR_OBJECT = { 245, 185, 66 }
local COLOR_LINE = { 38, 187, 183 }

local draw = {}

---@type table<integer, integer>
local ringStart = {}
---@type table<integer, true>
local alive = {}

---@param fraction number
---@return integer, integer, integer
local function healthColor(fraction)
    if fraction < 0.5 then
        local t = fraction / 0.5

        return mfloor(util.lerp(230, 245, t)), mfloor(util.lerp(70, 165, t)), mfloor(util.lerp(70, 40, t))
    end

    local t = (fraction - 0.5) / 0.5

    return mfloor(util.lerp(245, 70, t)), mfloor(util.lerp(165, 200, t)), mfloor(util.lerp(40, 100, t))
end

---@param entity integer
---@param coords vector3
---@param isVehicle boolean
local function healthBar(entity, coords, isVehicle)
    local health, maxHealth = util.health(entity)
    local fraction = maxHealth > 0 and health / maxHealth or 0.0
    local cam = state.camPos
    local dx = cam.x - coords.x
    local dy = cam.y - coords.y
    local dz = cam.z - coords.z
    local dist = sqrt(dx * dx + dy * dy + dz * dz)
    local scale = util.clamp(1.0 - dist / 160.0, 0.45, 1.0)
    local width = (isVehicle and 0.05 or 0.036) * scale
    local height = (isVehicle and 0.0075 or 0.006) * scale
    local r, g, b = healthColor(util.clamp(fraction, 0.0, 1.0))
    local fill = width * fraction

    SetDrawOrigin(coords.x, coords.y, coords.z + (isVehicle and 1.2 or 0.38), 0)
    DrawRect(0.0, 0.0, width, height, 20, 20, 20, 190)
    DrawRect(-width * 0.5 + fill * 0.5, 0.0, fill, height, r, g, b, 235)
    ClearDrawOrigin()
end

---@param now integer
local function rings(now)
    local list = state.selection
    local rotation = 360.0 - (now % 18000) / 50.0

    twipe(alive)

    for i = 1, #list do
        local entity = list[i]

        if DoesEntityExist(entity) then
            alive[entity] = true

            local startAt = ringStart[entity]

            if not startAt then
                startAt = now
                ringStart[entity] = now
            end

            local progress = util.easeOutCubic((now - startAt) / RING_MS)
            local isPed = IsEntityAPed(entity)
            local isVehicle = not isPed and selection.isVehicle(entity)
            local color = isPed and COLOR_PED or isVehicle and COLOR_VEHICLE or COLOR_OBJECT
            local size = (isVehicle and 3.0 or 1.0) * util.lerp(1.6, 1.0, progress)
            local coords = GetEntityCoords(entity)
            local ground = util.groundZ(coords.x, coords.y, coords.z + 0.5)
            local z = ground and ground + 0.05 or coords.z - 1.0

            DrawMarker(27, coords.x, coords.y, z, 0.0, 0.0, 0.0, 0.0, 0.0, rotation, size, size, 1.0, color[1], color[2], color[3], mfloor(130 * progress), false, false, 2, false, nil, nil, false)

            if isPed or isVehicle then
                healthBar(entity, isPed and selection.anchor(entity) or coords, isVehicle)
            end
        end
    end

    for entity in pairs(ringStart) do
        if not alive[entity] then
            ringStart[entity] = nil
        end
    end
end

---@param now integer
local function orderMarkers(now)
    local list = state.markers

    for i = #list, 1, -1 do
        local m = list[i]

        if now >= m.expiresAt then
            tremove(list, i)
        else
            local progress = util.easeOutCubic((now - m.startAt) / ORDER_MS)
            local size = util.lerp(2.0, 1.0, progress)
            local fade = util.clamp((m.expiresAt - now) / 600.0, 0.0, 1.0)

            DrawMarker(26, m.x, m.y, m.z, 0.0, 0.0, 0.0, 0.0, 0.0, m.heading, size, size, 1.0, m.r, m.g, m.b, mfloor(150 * fade), false, false, 2, false, nil, nil, false)
        end
    end
end

local function dragPreview()
    if not state.rmbDragging or #state.selection == 0 then return end

    local target = camera.ground()

    if not target then return end

    local actors = selection.actors()
    local z = target.z + 0.05

    for i = 1, #actors do
        local from = selection.anchor(actors[i])

        DrawLine(from.x, from.y, from.z + 0.3, target.x, target.y, z, COLOR_LINE[1], COLOR_LINE[2], COLOR_LINE[3], 200)
    end

    DrawMarker(27, target.x, target.y, z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.2, COLOR_LINE[1], COLOR_LINE[2], COLOR_LINE[3], 180, false, false, 2, false, nil, nil, false)
end

local function holdArrow()
    local hold = spawn.hold()

    if not hold or state.mode ~= 'spawn' then return end

    local pos = hold.start

    DrawMarker(26, pos.x, pos.y, pos.z + 0.05, 0.0, 0.0, 0.0, 0.0, 0.0, hold.heading, 1.0, 1.0, 1.0, COLOR_PED[1], COLOR_PED[2], COLOR_PED[3], 140, false, false, 2, false, nil, nil, false)
end

local function rangeRing()
    local preview = orders.rangePreview()

    if not preview or not DoesEntityExist(preview.ped) then return end

    local coords = GetEntityCoords(preview.ped)
    local ground = util.groundZ(coords.x, coords.y, coords.z + 2.0) or coords.z - 1.0
    local size = preview.radius * 2.0

    DrawMarker(1, coords.x, coords.y, ground, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, size, size, 0.6, 230, 70, 70, 70, false, false, 2, false, nil, nil, false)
end

function draw.frame()
    local now = GetGameTimer()

    rings(now)
    orderMarkers(now)
    dragPreview()
    holdArrow()
    rangeRing()
end

function draw.reset()
    ringStart = {}
end

return draw
