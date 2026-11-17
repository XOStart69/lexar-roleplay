local abs, rad, deg, cos, sin, atan = math.abs, math.rad, math.deg, math.cos, math.sin, math.atan

local HALF_W = 0.0125
local HALF_L = 0.025
local GAP = 0.0008
local BEND_LIMIT = 0.34
local BOUND = 0.38
local GRID_STEP = 0.03

local layout = {}

---@param yaw number
---@return number halfX
---@return number halfY
local function extents(yaw)
    local r = rad(yaw)
    local c, s = abs(cos(r)), abs(sin(r))
    return c * HALF_W + s * HALF_L, s * HALF_W + c * HALF_L
end

---@param board table[]
---@param x number
---@param y number
---@param yaw number
---@return boolean
local function isClear(board, x, y, yaw)
    local hx, hy = extents(yaw)
    if abs(x) + hx > BOUND or abs(y) + hy > BOUND then return false end

    for i = 1, #board do
        local placed = board[i]
        local px, py = extents(placed.r)
        if abs(x - placed.x) < hx + px - 0.0001 and abs(y - placed.y) < hy + py - 0.0001 then
            return false
        end
    end

    return true
end

---@param dx number
---@param dy number
---@param tile { lo: number, hi: number }
---@param match number
---@return number
local function yawFor(dx, dy, tile, match)
    local yaw = deg(atan(-dx, dy))
    if tile.lo == tile.hi then
        yaw = yaw + 90.0
    elseif tile.lo == match then
        yaw = yaw + 180.0
    end
    return (yaw + 0.5) // 90 * 90 % 360
end

---@param tile { lo: number, hi: number }
---@return number x
---@return number y
---@return number yaw
---@return table branches
function layout.first(tile)
    local double = tile.lo == tile.hi
    local along = double and HALF_W or HALF_L
    local across = double and HALF_L or HALF_W

    return 0.0, 0.0, double and 0.0 or 90.0, {
        { x = 0.0, y = 0.0, dx = -1, dy = 0, along = along, across = across, turn = -1 },
        { x = 0.0, y = 0.0, dx = 1, dy = 0, along = along, across = across, turn = 1 },
    }
end

---@param board table[]
---@param branch table
---@param tile { lo: number, hi: number }
---@param match number
---@return number x
---@return number y
---@return number yaw
---@return table branch
function layout.next(board, branch, tile, match)
    local double = tile.lo == tile.hi
    local along = double and HALF_W or HALF_L
    local across = double and HALF_L or HALF_W
    local bx, by, dx, dy = branch.x, branch.y, branch.dx, branch.dy

    if dy == 0 then
        local cx = bx + dx * (branch.along + along + GAP)
        local yaw = yawFor(dx, 0, tile, match)
        if abs(cx) + along <= BEND_LIMIT and isClear(board, cx, by, yaw) then
            return cx, by, yaw, { x = cx, y = by, dx = dx, dy = 0, along = along, across = across, turn = branch.turn }
        end

        local turn = branch.turn
        local vAlong = double and HALF_W or HALF_L
        local vAcross = double and HALF_L or HALF_W
        local vx = bx + dx * (branch.along - vAcross)
        local vy = by + turn * (branch.across + vAlong + GAP)
        yaw = yawFor(0, turn, tile, match)
        if isClear(board, vx, vy, yaw) then
            return vx, vy, yaw, { x = vx, y = vy, dx = 0, dy = turn, along = vAlong, across = vAcross, turn = turn, back = -dx }
        end
    else
        local back = branch.back or 1
        local hy = by + dy * (branch.along - across)
        local hx = bx + back * (branch.across + along + GAP)
        local yaw = yawFor(back, 0, tile, match)
        if isClear(board, hx, hy, yaw) then
            return hx, hy, yaw, { x = hx, y = hy, dx = back, dy = 0, along = along, across = across, turn = branch.turn }
        end
    end

    local yaw = yawFor(dx, dy, tile, match)
    local start = -BOUND + 0.03
    local gy = start
    while gy <= BOUND - 0.03 do
        local gx = start
        while gx <= BOUND - 0.03 do
            if isClear(board, gx, gy, yaw) then
                return gx, gy, yaw, { x = gx, y = gy, dx = dx, dy = dy, along = along, across = across, turn = branch.turn, back = branch.back }
            end
            gx = gx + GRID_STEP
        end
        gy = gy + GRID_STEP
    end

    return bx, by, yaw, branch
end

return layout
