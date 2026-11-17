local config = localmodule 'config.shared'
local geometry = localmodule 'modules.geometry'
local ui = localmodule 'modules.ui'

local Wait = Wait
local GetFrameTime = GetFrameTime
local GetGameTimer = GetGameTimer
local IsControlPressed = IsControlPressed
local IsDisabledControlPressed = IsDisabledControlPressed
local IsControlJustPressed = IsControlJustPressed
local IsDisabledControlJustPressed = IsDisabledControlJustPressed
local DrawPoly = DrawPoly
local DrawLine = DrawLine
local DrawMarker = DrawMarker

local LIFT = vec3(0.0, 0.0, 0.03)

local tool = {}
local running = false

---@param control number
---@return boolean
local function held(control)
    return IsDisabledControlPressed(0, control) or IsControlPressed(0, control)
end

---@param control number
---@return boolean
local function tapped(control)
    return IsDisabledControlJustPressed(0, control) or IsControlJustPressed(0, control)
end

local function drawQuad(p1, p2, p3, p4, r, g, b, a)
    DrawPoly(p1, p2, p3, r, g, b, a)
    DrawPoly(p3, p2, p1, r, g, b, a)
    DrawPoly(p3, p4, p1, r, g, b, a)
    DrawPoly(p1, p4, p3, r, g, b, a)
end

local function drawOutline(p1, p2, p3, p4, r, g, b)
    DrawLine(p1.x, p1.y, p1.z, p2.x, p2.y, p2.z, r, g, b, 255)
    DrawLine(p2.x, p2.y, p2.z, p3.x, p3.y, p3.z, r, g, b, 255)
    DrawLine(p3.x, p3.y, p3.z, p4.x, p4.y, p4.z, r, g, b, 255)
    DrawLine(p4.x, p4.y, p4.z, p1.x, p1.y, p1.z, r, g, b, 255)
end

---@param point vector3
local function drawPost(point, r, g, b)
    DrawMarker(1, point.x, point.y, point.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.15, 0.15, 1.2, r, g, b, 200, false, false, 2, false, nil, nil, false)
end

---@param geo table
local function drawCourt(geo)
    local side = geo.right * geo.halfWidth
    local c1, c2 = geo.endB - side + LIFT, geo.endA - side + LIFT
    local c3, c4 = geo.endA + side + LIFT, geo.endB + side + LIFT

    local extSide = geo.right * (geo.extWidth / 2)
    local e1, e2 = geo.extB - extSide + LIFT, geo.extA - extSide + LIFT
    local e3, e4 = geo.extA + extSide + LIFT, geo.extB + extSide + LIFT

    drawQuad(e1, e2, e3, e4, 0, 90, 255, 40)
    drawQuad(c1, c2, c3, c4, 255, 0, 0, 90)
    drawOutline(e1, e2, e3, e4, 0, 90, 255)
    drawOutline(c1, c2, c3, c4, 255, 40, 40)

    local netA, netB = geo.netA + LIFT, geo.netB + LIFT
    DrawLine(netA.x, netA.y, netA.z, netB.x, netB.y, netB.z, 0, 255, 0, 255)

    drawPost(c1, 255, 40, 40)
    drawPost(c2, 255, 40, 40)
    drawPost(c3, 255, 40, 40)
    drawPost(c4, 255, 40, 40)
    drawPost(geo.netA, 0, 255, 0)
    drawPost(geo.netB, 0, 255, 0)
end

---@param court table
local function copyConfig(court)
    local c = court.center
    local snippet = ('court_%d = { z = %.2f, center = vec3(%.3f, %.3f, %.2f), heading = %.3f, width = %.2f, length = %.2f, netOffset = %.3f },'):format(
        GetGameTimer(), c.z, c.x, c.y, c.z, court.heading, court.width, court.length, court.netOffset
    )
    lib.setClipboard(snippet)
    ui.notify(config.text.toolCopied, 'success')
end

---@param origin vector3
function tool.start(origin)
    if running then return end
    running = true
    ui.toolCard(true)

    local court = { center = origin, heading = 0.0, width = 7.98, length = 11.89, netOffset = 0.0 }

    CreateThread(function()
        while running do
            Wait(0)

            drawCourt(geometry.build(court.center, court.heading, court.width, court.length, court.netOffset))

            local step = GetFrameTime() * ((held(21) or held(131)) and 1.5 or 0.2)
            local center = court.center

            if held(172) then
                court.center = vec3(center.x, center.y + step, center.z)
            elseif held(173) then
                court.center = vec3(center.x, center.y - step, center.z)
            elseif held(174) then
                court.center = vec3(center.x - step, center.y, center.z)
            elseif held(175) then
                court.center = vec3(center.x + step, center.y, center.z)
            end

            if held(96) then
                court.heading -= step * 10
            elseif held(97) then
                court.heading += step * 10
            end

            if held(127) then
                court.netOffset += step
            elseif held(126) then
                court.netOffset -= step
            end

            if held(108) then
                court.width -= step
            elseif held(117) then
                court.width += step
            end

            if held(118) then
                court.length += step
            elseif held(109) then
                court.length -= step
            end

            if tapped(176) or tapped(201) then
                copyConfig(court)
                break
            end

            if tapped(194) then
                break
            end
        end

        running = false
        ui.toolCard(false)
    end)
end

function tool.stop()
    running = false
end

return tool
