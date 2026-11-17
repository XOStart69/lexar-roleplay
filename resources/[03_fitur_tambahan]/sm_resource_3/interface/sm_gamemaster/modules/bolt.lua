local config = localmodule 'config'

local Wait = Wait
local GetGameTimer = GetGameTimer
local DrawPoly = DrawPoly
local DrawLightWithRange = DrawLightWithRange
local GetFinalRenderedCamCoord = GetFinalRenderedCamCoord
local HasNamedPtfxAssetLoaded = HasNamedPtfxAssetLoaded
local random = math.random
local sqrt = math.sqrt
local floor = math.floor
local cos = math.cos
local sin = math.sin

local BOLT = config.lightningBolt
local HEIGHT = BOLT.height
local SEGMENTS = BOLT.segments
local JITTER = BOLT.jitter
local BRANCHES = BOLT.branches
local BRANCH_SEGMENTS = BOLT.branchSegments
local WIDTH = BOLT.width
local HALO_WIDTH = BOLT.haloWidth
local MIN_SCREEN_WIDTH = BOLT.minScreenWidth
local DURATION = BOLT.durationMs
local MAX_ACTIVE = BOLT.maxActive
local RED, GREEN, BLUE = BOLT.color[1], BOLT.color[2], BOLT.color[3]
local LIGHT = BOLT.light
local IMPACT = BOLT.impact
local SHAKE = BOLT.shake
local FIRST_FLASH_END = 90
local DARK_END = 140
local SECOND_FLASH_END = 230
local STRIDE = 7

local bolt = {}
local active = 0

---@param segments number[]
---@param sx number
---@param sy number
---@param sz number
---@param ex number
---@param ey number
---@param ez number
---@param count integer
---@param jitter number
---@param scale number
---@return number[] nodes
local function addPath(segments, sx, sy, sz, ex, ey, ez, count, jitter, scale)
    local nodes = { sx, sy, sz }
    local px, py, pz = sx, sy, sz

    for i = 1, count do
        local t = i / count
        local spread = i == count and 0.0 or jitter * (1.0 - t * 0.6)
        local x = sx + (ex - sx) * t + (random() - 0.5) * 2.0 * spread
        local y = sy + (ey - sy) * t + (random() - 0.5) * 2.0 * spread
        local z = sz + (ez - sz) * t
        local n = #segments

        segments[n + 1] = px
        segments[n + 2] = py
        segments[n + 3] = pz
        segments[n + 4] = x
        segments[n + 5] = y
        segments[n + 6] = z
        segments[n + 7] = scale

        local m = #nodes

        nodes[m + 1] = x
        nodes[m + 2] = y
        nodes[m + 3] = z

        px, py, pz = x, y, z
    end

    return nodes
end

---@param x number
---@param y number
---@param z number
---@return number[]
local function build(x, y, z)
    local segments = {}
    local topX = x + (random() - 0.5) * 2.0 * JITTER * 3.0
    local topY = y + (random() - 0.5) * 2.0 * JITTER * 3.0
    local nodes = addPath(segments, topX, topY, z + HEIGHT, x, y, z, SEGMENTS, JITTER, 1.0)

    for _ = 1, BRANCHES do
        local index = random(2, SEGMENTS - 2)
        local base = index * 3
        local bx, by, bz = nodes[base + 1], nodes[base + 2], nodes[base + 3]
        local length = (bz - z) * (0.25 + random() * 0.3)
        local reach = length * (0.5 + random() * 0.6)
        local angle = random() * 6.2831853
        local endX = bx + cos(angle) * reach
        local endY = by + sin(angle) * reach

        addPath(segments, bx, by, bz, endX, endY, bz - length, BRANCH_SEGMENTS, JITTER * 0.5, 0.45)
    end

    return segments
end

---@param elapsed integer
---@return number
local function brightness(elapsed)
    if elapsed < FIRST_FLASH_END then return 1.0 end
    if elapsed < DARK_END then return 0.0 end
    if elapsed < SECOND_FLASH_END then return 1.0 end

    return 1.0 - (elapsed - SECOND_FLASH_END) / (DURATION - SECOND_FLASH_END)
end

---@param segments number[]
---@param camX number
---@param camY number
---@param camZ number
---@param width number
---@param alpha integer
local function drawLayer(segments, camX, camY, camZ, width, alpha)
    for i = 1, #segments, STRIDE do
        local x1, y1, z1 = segments[i], segments[i + 1], segments[i + 2]
        local x2, y2, z2 = segments[i + 3], segments[i + 4], segments[i + 5]
        local dx, dy, dz = x2 - x1, y2 - y1, z2 - z1
        local vx, vy, vz = camX - (x1 + x2) * 0.5, camY - (y1 + y2) * 0.5, camZ - (z1 + z2) * 0.5
        local px, py, pz = dy * vz - dz * vy, dz * vx - dx * vz, dx * vy - dy * vx
        local length = sqrt(px * px + py * py + pz * pz)

        if length > 0.0001 then
            local distance = sqrt(vx * vx + vy * vy + vz * vz)
            local half = width * segments[i + 6]
            local minimum = distance * MIN_SCREEN_WIDTH

            if half < minimum then
                half = minimum
            end

            half = half * 0.5 / length
            px, py, pz = px * half, py * half, pz * half

            local ax, ay, az = x1 - px, y1 - py, z1 - pz
            local bx, by, bz = x1 + px, y1 + py, z1 + pz
            local cx, cy, cz = x2 + px, y2 + py, z2 + pz
            local ex, ey, ez = x2 - px, y2 - py, z2 - pz

            DrawPoly(ax, ay, az, bx, by, bz, cx, cy, cz, RED, GREEN, BLUE, alpha)
            DrawPoly(cx, cy, cz, bx, by, bz, ax, ay, az, RED, GREEN, BLUE, alpha)
            DrawPoly(ax, ay, az, cx, cy, cz, ex, ey, ez, RED, GREEN, BLUE, alpha)
            DrawPoly(ex, ey, ez, cx, cy, cz, ax, ay, az, RED, GREEN, BLUE, alpha)
        end
    end
end

---@param x number
---@param y number
---@param z number
local function impact(x, y, z)
    if not IMPACT then return end

    if not HasNamedPtfxAssetLoaded(IMPACT.asset) then
        RequestNamedPtfxAsset(IMPACT.asset)

        local deadline = GetGameTimer() + 1000

        while not HasNamedPtfxAssetLoaded(IMPACT.asset) do
            if GetGameTimer() > deadline then return end

            Wait(0)
        end
    end

    UseParticleFxAssetNextCall(IMPACT.asset)
    StartParticleFxNonLoopedAtCoord(IMPACT.name, x, y, z, 0.0, 0.0, 0.0, IMPACT.scale, false, false, false)
end

---@param x number
---@param y number
---@param z number
local function shake(x, y, z)
    if not SHAKE then return end

    local cam = GetFinalRenderedCamCoord()
    local dx, dy, dz = cam.x - x, cam.y - y, cam.z - z
    local distance = sqrt(dx * dx + dy * dy + dz * dz)

    if distance >= SHAKE.distance then return end

    ShakeGameplayCam(SHAKE.name, SHAKE.amount * (1.0 - distance / SHAKE.distance))
end

---@param x number
---@param y number
---@param z number
function bolt.strike(x, y, z)
    if type(x) ~= 'number' or type(y) ~= 'number' or type(z) ~= 'number' then return end
    if active >= MAX_ACTIVE then return end

    active += 1

    CreateThread(function()
        local segments = build(x, y, z)
        local started = GetGameTimer()

        shake(x, y, z)
        impact(x, y, z)

        while true do
            local elapsed = GetGameTimer() - started

            if elapsed >= DURATION then break end

            local level = brightness(elapsed)

            if level > 0.0 then
                local cam = GetFinalRenderedCamCoord()

                drawLayer(segments, cam.x, cam.y, cam.z, HALO_WIDTH, floor(70 * level))
                drawLayer(segments, cam.x, cam.y, cam.z, WIDTH, floor(255 * level))
                DrawLightWithRange(x, y, z + 2.0, RED, GREEN, BLUE, LIGHT.range, LIGHT.intensity * level)
                DrawLightWithRange(x, y, z + HEIGHT * 0.25, RED, GREEN, BLUE, LIGHT.range * 1.5, LIGHT.intensity * level)
            end

            Wait(0)
        end

        active -= 1
    end)
end

return bolt
