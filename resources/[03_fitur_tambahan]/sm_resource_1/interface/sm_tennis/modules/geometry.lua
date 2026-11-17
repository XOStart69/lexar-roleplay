local mathCos = math.cos
local mathSin = math.sin
local mathRad = math.rad
local IsPointInAngledArea = IsPointInAngledArea

local geometry = {}

---@param angle number
---@return vector3
local function direction(angle)
    local r = mathRad(angle)
    return vec3(mathCos(r), mathSin(r), 0.0)
end

---@param side string
---@return string
function geometry.other(side)
    return side == 'a' and 'b' or 'a'
end

---@param center vector3
---@param heading number
---@param width number
---@param length number
---@param netOffset number
---@return table
function geometry.build(center, heading, width, length, netOffset)
    local toA = direction(heading + 90.0)
    local right = direction(heading)
    local halfWidth = width / 2
    local lower = vec3(0.0, 0.0, 0.1)

    local endA = center + toA * length
    local endB = center - toA * length
    local netA = center + toA * netOffset + right * halfWidth
    local netB = center + toA * netOffset - right * halfWidth

    local serveDepth = length + 0.7
    local serveWide = width / 3

    local geo = {
        center = center,
        heading = heading,
        width = width,
        halfWidth = halfWidth,
        right = right,
        toA = toA,
        netMid = center + toA * netOffset,
        endA = endA,
        endB = endB,
        extA = center + toA * (length + 8.0),
        extB = center - toA * (length + 8.0),
        extWidth = width + 16.0,
        netA = netA,
        netB = netB,
        servePoints = {
            a = {
                right = center + toA * serveDepth - right * serveWide - lower,
                left = center + toA * serveDepth + right * serveWide - lower,
            },
            b = {
                right = center - toA * serveDepth + right * serveWide - lower,
                left = center - toA * serveDepth - right * serveWide - lower,
            },
        },
        serveBounds = {},
    }

    for _, side in ipairs({ 'a', 'b' }) do
        local sideForward = side == 'a' and toA or -toA
        local sideRight = side == 'a' and -right or right
        local center1 = center + sideForward * (length - 2.0)
        local center2 = center + sideForward * (length + 3.0)
        local edgeOffset = sideRight * (halfWidth + 0.75)

        geo.serveBounds[side] = {
            right = { left = { center1, center2 }, right = { center1 + edgeOffset, center2 + edgeOffset } },
            left = { left = { center1 - edgeOffset, center2 - edgeOffset }, right = { center1, center2 } },
        }
    end

    return geo
end

---@param geo table
---@param point vector3
---@param mySide string?
---@return boolean inArea
---@return boolean inExtended
---@return boolean isASide
---@return string lateral
function geometry.pointData(geo, point, mySide)
    local px, py = point.x, point.y
    local n1, n2 = geo.netA, geo.netB
    local e1, e2 = geo.endA, geo.endB

    local isASide = (n1.x - n2.x) * (py - n2.y) - (n1.y - n2.y) * (px - n2.x) > 0
    local onARightHalf = (e1.x - e2.x) * (py - e2.y) - (e1.y - e2.y) * (px - e2.x) > 0

    local lateral
    if mySide == 'a' then
        lateral = onARightHalf and 'right' or 'left'
    else
        lateral = onARightHalf and 'left' or 'right'
    end

    local x1, x2 = geo.extA, geo.extB
    local inArea = IsPointInAngledArea(px, py, point.z, e1.x, e1.y, e1.z, e2.x, e2.y, e2.z, geo.width, false, false)
    local inExtended = IsPointInAngledArea(px, py, point.z, x1.x, x1.y, x1.z, x2.x, x2.y, x2.z, geo.extWidth, false, false)

    return inArea, inExtended, isASide, lateral
end

return geometry
