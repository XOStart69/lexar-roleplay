local util = localmodule 'modules.util'

local pairs = pairs
local abs = math.abs
local sqrt = math.sqrt
local deg = math.deg
local rad = math.rad
local sin = math.sin
local cos = math.cos
local atan = math.atan
local DrawLine = DrawLine
local DrawMarker = DrawMarker

local AXES = {
    x = vector3(1.0, 0.0, 0.0),
    y = vector3(0.0, 1.0, 0.0),
    z = vector3(0.0, 0.0, 1.0),
}

local COLORS = {
    x = { 230, 70, 70 },
    y = { 70, 200, 100 },
    z = { 70, 140, 240 },
    all = { 230, 230, 230 },
    hover = { 38, 187, 183 },
}

local SEGMENTS = 40

local gizmo = {}

---@class GmGizmo
---@field pos vector3
---@field rot { x: number, y: number, z: number }
---@field mode 'translate'|'rotate'
---@field hover? 'x'|'y'|'z'|'all'
---@field active? 'x'|'y'|'z'|'all'
---@field drag? string
---@field start? vector3
---@field startRot? { x: number, y: number, z: number }
---@field anchorT? number
---@field startVec? vector3
---@field hoverVec? vector3
---@field freeOffset? vector3

---@param pos vector3
---@param rot { x: number, y: number, z: number }
---@return GmGizmo
function gizmo.new(pos, rot)
    return {
        pos = pos,
        rot = { x = rot.x, y = rot.y, z = rot.z },
        mode = 'translate',
    }
end

---@param p1 vector3
---@param d1 vector3
---@param p2 vector3
---@param d2 vector3
---@return number t1, number distance
local function closestOnLines(p1, d1, p2, d2)
    local a = util.normalize(d1)
    local b = util.normalize(d2)
    local diff = p1 - p2
    local aa = util.dot(a, a)
    local ab = util.dot(a, b)
    local bb = util.dot(b, b)
    local ad = util.dot(a, diff)
    local bd = util.dot(b, diff)
    local denom = aa * bb - ab * ab
    local t1
    local t2

    if abs(denom) < 0.000001 then
        t1 = ad
        t2 = 0.0
    else
        t1 = (ab * bd - bb * ad) / denom
        t2 = (aa * bd - ab * ad) / denom
    end

    local q1 = p1 + a * t1
    local q2 = p2 + b * t2
    local gap = q1 - q2

    return t1, sqrt(gap.x * gap.x + gap.y * gap.y + gap.z * gap.z)
end

---@param pos vector3
---@param axis vector3
---@param origin vector3
---@param dir vector3
---@param radius number
---@return number?, vector3?
local function ringHit(pos, axis, origin, dir, radius)
    local denom = util.dot(axis, dir)

    if abs(denom) < 0.000001 then return nil end

    local t = util.dot(axis, pos - origin) / denom

    if t < 0.0 then return nil end

    local hit = origin + dir * t
    local toHit = hit - pos
    local length = sqrt(toHit.x * toHit.x + toHit.y * toHit.y + toHit.z * toHit.z)

    return abs(length - radius), length > 0.0 and util.normalize(toHit) or vector3(1.0, 0.0, 0.0)
end

---@param g GmGizmo
---@param origin vector3
---@return number size, number radius, number length
local function sizes(g, origin)
    local diff = g.pos - origin
    local dist = sqrt(diff.x * diff.x + diff.y * diff.y + diff.z * diff.z)

    return util.clamp(dist * 0.035, 0.07, 0.7), math.max(dist * 0.18 * 0.9, 0.2), dist * 0.18
end

---@param pitch number
---@param heading number
---@return vector3
local function camForward(pitch, heading)
    local p = rad(pitch)
    local h = rad(heading)
    local cp = cos(p)

    return vector3(-sin(h) * cp, cos(h) * cp, sin(p))
end

---@param g GmGizmo
---@param origin vector3
---@param dir vector3
local function updateHover(g, origin, dir)
    local size, radius = sizes(g, origin)

    if g.mode == 'translate' then
        local toCenter = g.pos - origin
        local proj = util.dot(dir, toCenter)

        if proj > 0.0 then
            local point = origin + dir * proj
            local gap = point - g.pos

            if sqrt(gap.x * gap.x + gap.y * gap.y + gap.z * gap.z) <= size * 0.9 then
                g.hover = 'all'
                return
            end
        end

        local best = nil
        local bestDist = size

        for id, axis in pairs(AXES) do
            local _, distance = closestOnLines(g.pos, axis, origin, dir)

            if distance <= bestDist then
                bestDist = distance
                best = id
            end
        end

        g.hover = best
        return
    end

    local best = nil
    local bestDist = size * 0.9
    local bestVec = nil

    for id, axis in pairs(AXES) do
        local distance, vec = ringHit(g.pos, axis, origin, dir, radius)

        if distance and distance <= bestDist then
            bestDist = distance
            best = id
            bestVec = vec
        end
    end

    g.hover = best
    g.hoverVec = bestVec
end

---@param g GmGizmo
---@param origin vector3
---@param dir vector3
---@param pitch number
---@param heading number
local function beginDrag(g, origin, dir, pitch, heading)
    local hover = g.hover

    if not hover then return end

    g.active = hover
    g.start = g.pos

    if g.mode == 'rotate' then
        g.drag = 'rotate'
        g.startRot = { x = g.rot.x, y = g.rot.y, z = g.rot.z }
        g.startVec = g.hoverVec or vector3(1.0, 0.0, 0.0)
        return
    end

    if hover == 'all' then
        local forward = camForward(pitch, heading)
        local denom = util.dot(forward, dir)

        g.drag = 'free'

        if abs(denom) < 0.000001 then
            g.freeOffset = vector3(0.0, 0.0, 0.0)
            return
        end

        local t = util.dot(forward, g.start - origin) / denom

        g.freeOffset = g.start - (origin + dir * t)
        return
    end

    g.drag = 'axis'
    g.anchorT = closestOnLines(g.pos, AXES[hover], origin, dir)
end

---@param g GmGizmo
---@param origin vector3
---@param dir vector3
---@param pitch number
---@param heading number
local function continueDrag(g, origin, dir, pitch, heading)
    if g.drag == 'axis' then
        local axis = AXES[g.active]
        local t = closestOnLines(g.start, axis, origin, dir)

        g.pos = g.start + axis * (t - g.anchorT)
        return
    end

    if g.drag == 'free' then
        local forward = camForward(pitch, heading)
        local denom = util.dot(forward, dir)

        if abs(denom) < 0.000001 then return end

        local t = util.dot(forward, g.start - origin) / denom

        if t < 0.0 then return end

        g.pos = origin + dir * t + g.freeOffset
        return
    end

    local axis = AXES[g.active]
    local denom = util.dot(axis, dir)

    if abs(denom) <= 0.000001 then return end

    local t = util.dot(axis, g.pos - origin) / denom

    if t < 0.0 then return end

    local toHit = origin + dir * t - g.pos

    if toHit.x * toHit.x + toHit.y * toHit.y + toHit.z * toHit.z < 0.0000000001 then return end

    local a = util.normalize(g.startVec)
    local b = util.normalize(toHit)
    local cross = util.cross(a, b)
    local crossLength = sqrt(cross.x * cross.x + cross.y * cross.y + cross.z * cross.z)
    local angle = deg(atan(crossLength, util.dot(a, b)))
    local delta = util.dot(axis, cross) >= 0.0 and angle or -angle
    local base = g.startRot

    if g.active == 'x' then
        g.rot.y = base.y + delta
    elseif g.active == 'y' then
        g.rot.x = base.x - delta
    else
        g.rot.z = base.z + delta
    end
end

---@param g GmGizmo
---@param origin vector3
---@param dir vector3
---@param input { pressed: boolean, released: boolean, pitch: number, heading: number }
function gizmo.update(g, origin, dir, input)
    if not g.drag then
        updateHover(g, origin, dir)
    end

    if input.pressed and not g.drag then
        beginDrag(g, origin, dir, input.pitch, input.heading)
    end

    if g.drag then
        continueDrag(g, origin, dir, input.pitch, input.heading)
    end

    if input.released then
        g.drag = nil
        g.active = nil
    end
end

---@param g GmGizmo
function gizmo.toggleMode(g)
    if g.drag then return end

    g.mode = g.mode == 'translate' and 'rotate' or 'translate'
    g.hover = nil
end

---@param g GmGizmo
---@param id string
---@return integer, integer, integer
local function colorOf(g, id)
    local color = (g.hover == id or g.active == id) and COLORS.hover or COLORS[id]

    return color[1], color[2], color[3]
end

---@param center vector3
---@param u vector3
---@param v vector3
---@param radius number
---@param r integer
---@param gr integer
---@param b integer
local function circle(center, u, v, radius, r, gr, b)
    local tau = math.pi * 2.0
    local prev = center + u * radius

    for i = 1, SEGMENTS do
        local a = (i / SEGMENTS) * tau
        local point = center + u * (cos(a) * radius) + v * (sin(a) * radius)

        DrawLine(prev.x, prev.y, prev.z, point.x, point.y, point.z, r, gr, b, 230)
        prev = point
    end
end

---@param g GmGizmo
---@param origin vector3
function gizmo.draw(g, origin)
    local size, radius, length = sizes(g, origin)
    local pos = g.pos

    if g.mode == 'translate' then
        for id, axis in pairs(AXES) do
            local r, gr, b = colorOf(g, id)
            local tip = pos + axis * length

            DrawLine(pos.x, pos.y, pos.z, tip.x, tip.y, tip.z, r, gr, b, 255)
            DrawMarker(28, tip.x, tip.y, tip.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, size * 0.5, size * 0.5, size * 0.5, r, gr, b, 220, false, false, 2, false, nil, nil, false)
        end

        local r, gr, b = colorOf(g, 'all')

        DrawMarker(28, pos.x, pos.y, pos.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, size * 0.6, size * 0.6, size * 0.6, r, gr, b, 180, false, false, 2, false, nil, nil, false)
        return
    end

    local xr, xg, xb = colorOf(g, 'x')
    local yr, yg, yb = colorOf(g, 'y')
    local zr, zg, zb = colorOf(g, 'z')

    circle(pos, AXES.y, AXES.z, radius, xr, xg, xb)
    circle(pos, AXES.x, AXES.z, radius, yr, yg, yb)
    circle(pos, AXES.x, AXES.y, radius, zr, zg, zb)
end

return gizmo
