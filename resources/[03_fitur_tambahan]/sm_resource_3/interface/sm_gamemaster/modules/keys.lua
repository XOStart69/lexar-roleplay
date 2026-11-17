local IsRawKeyDown = IsRawKeyDown
local IsRawKeyPressed = IsRawKeyPressed

local keys = {
    MMB = 4,
    BACKSPACE = 8,
    TAB = 9,
    ENTER = 13,
    SHIFT = 16,
    CTRL = 17,
    SPACE = 32,
    LEFT = 37,
    UP = 38,
    RIGHT = 39,
    DOWN = 40,
    DELETE = 46,
    A = 65,
    B = 66,
    C = 67,
    D = 68,
    E = 69,
    F = 70,
    G = 71,
    Q = 81,
    R = 82,
    S = 83,
    V = 86,
    W = 87,
    X = 88,
}

---@param code integer
---@return boolean
function keys.down(code)
    return IsRawKeyDown(code)
end

---@param code integer
---@return boolean
function keys.pressed(code)
    return IsRawKeyPressed(code)
end

---@return boolean
function keys.shift()
    return IsRawKeyDown(16) or IsRawKeyDown(160) or IsRawKeyDown(161)
end

---@return boolean
function keys.ctrl()
    return IsRawKeyDown(17) or IsRawKeyDown(162) or IsRawKeyDown(163)
end

return keys
