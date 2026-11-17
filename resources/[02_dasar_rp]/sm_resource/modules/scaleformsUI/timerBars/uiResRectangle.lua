---@class UIResRectangle
---@field x number
---@field y number
---@field width number
---@field height number
---@field colour {r: number, g: number, b: number, a: number}
local UIResRectangle = lib.class('UIResRectangle')

local utils = require 'modules.scaleformsUI.utils.shared'

---@param x number?
---@param y number?
---@param width number?
---@param height number?
---@param r number?
---@param g number?
---@param b number?
---@param a number?
function UIResRectangle:constructor(x, y, width, height, r, g, b, a)
    self.x = tonumber(x) or 0
    self.y = tonumber(y) or 0
    self.width = tonumber(width) or 0
    self.height = tonumber(height) or 0
    self.colour = {
        r = tonumber(r) or 255,
        g = tonumber(g) or 255,
        b = tonumber(b) or 255,
        a = tonumber(a) or 255
    }
end

---@param x number?
---@param y number?
function UIResRectangle:position(x, y)
    if tonumber(x) and tonumber(y) then
        self.x = x --[[@as number]]
        self.y = y --[[@as number]]
    end
end

---@param width number?
---@param height number?
function UIResRectangle:size(width, height)
    if tonumber(width) and tonumber(height) then
        self.width = width --[[@as number]]
        self.height = height --[[@as number]]
    end
end

---@param r number?
---@param g number?
---@param b number?
---@param a number?
function UIResRectangle:setColour(r, g, b, a)
    if tonumber(r) or tonumber(g) or tonumber(b) or tonumber(a) then
        self.colour.r = r or self.colour.r
        self.colour.g = g or self.colour.g
        self.colour.b = b or self.colour.b
        self.colour.a = a or self.colour.a
    end
end

function UIResRectangle:draw()
    local formattedWidth, formattedHeight = utils.formatXWYH(self.width, self.height)
    local formattedX, formattedY = utils.formatXWYH(self.x, self.y)

    DrawRect(
        formattedX + formattedWidth * 0.5,
        formattedY + formattedHeight * 0.5,
        formattedWidth,
        formattedHeight,
        self.colour.r,
        self.colour.g,
        self.colour.b,
        self.colour.a
    )
end

return UIResRectangle