local WIDTH <const> = 1024
local HEIGHT <const> = 384
local CELL <const> = 128
local FAR <const> = 45.0
local SIZE <const> = 0.04
local GAP <const> = 0.004
local RESEND <const> = 500
local WARMUP <const> = 500

local ICONS <const> = { rack = 0, work = 1, paint = 2, wheel = 3, jack = 4, hoist = 5, help = 6 }

---@class InteractClient
local interact = {}

---@type Dui?
local dui
---@type table<string, true>
local holders = {}
local label = ''
local sent = 0
local born = 0

---@return Dui
local function texture()
    if not dui then
        dui = lib.dui:new({ url = ('nui://%s/html/dui.html'):format(cache.resource), width = WIDTH, height = HEIGHT })
        born = GetGameTimer()
    end

    return dui
end

---@param atlas Dui
---@param index integer
---@param x number
---@param y number
local function cell(atlas, index, x, y)
    local u = index * CELL / WIDTH

    DrawSpriteUv(atlas.dictName, atlas.txtName, x, y, SIZE / GetAspectRatio(false), SIZE, u, 0.0, u + CELL / WIDTH, CELL / HEIGHT, 0.0, 255, 255, 255, 255)
end

---@param atlas Dui
---@param x number
---@param y number
---@param row integer
local function prompt(atlas, x, y, row)
    local ratio = GetAspectRatio(false)
    local icon = SIZE / ratio
    local width = SIZE * WIDTH / CELL / ratio
    local top = row * CELL / HEIGHT

    DrawSpriteUv(
        atlas.dictName,
        atlas.txtName,
        x + icon / 2 + GAP + width / 2,
        y + (row - 1) * SIZE,
        width,
        SIZE,
        0.0,
        top,
        1.0,
        top + CELL / HEIGHT,
        0.0,
        255,
        255,
        255,
        255
    )
end

---@param point vector3
---@param icon string
---@param distance number
---@param text? string
---@param tally? string
function interact.draw(point, icon, distance, text, tally)
    if distance > FAR then return end

    local visible, x, y = GetScreenCoordFromWorldCoord(point.x, point.y, point.z)
    if not visible then return end

    local atlas = texture()
    if GetGameTimer() - born < WARMUP then return end

    cell(atlas, ICONS[icon] or ICONS.work, x, y)

    if text then
        local now = GetGameTimer()
        local key = tally and ('%s|%s'):format(text, tally) or text

        if key ~= label or now - sent > RESEND then
            label, sent = key, now
            atlas:sendMessage({ label = text, tally = tally or '', hint = locale('ui.interact.switch') })
        end

        prompt(atlas, x, y, 1)

        if tally then prompt(atlas, x, y, 2) end
    end
end

function interact.clear()
    if not dui or label == '' then return end

    label = ''
    dui:sendMessage({ label = '', tally = '' })
end

---@param owner string
---@param active boolean
function interact.hold(owner, active)
    if active then
        holders[owner] = true
        texture()
        return
    end

    holders[owner] = nil

    if next(holders) or not dui then return end

    dui:remove()
    dui, label = nil, ''
end

return interact
