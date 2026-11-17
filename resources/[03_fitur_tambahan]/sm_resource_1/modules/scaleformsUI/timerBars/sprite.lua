---@class Sprite
---@field txtDictionary string
---@field txtName string
---@field x number
---@field y number
---@field width number
---@field height number
---@field heading number
---@field colour {r: number, g: number, b: number, a: number}
local Sprite = lib.class('Sprite')

local utils = require 'modules.scaleformsUI.utils.shared'

---Constructor untuk Sprite
---@param txtDictionary string
---@param txtName string
---@param x number?
---@param y number?
---@param width number?
---@param height number?
---@param heading number?
---@param r number?
---@param g number?
---@param b number?
---@param a number?
function Sprite:constructor(txtDictionary, txtName, x, y, width, height, heading, r, g, b, a)
    self.txtDictionary = tostring(txtDictionary)
    self.txtName = tostring(txtName)
    self.x = tonumber(x) or 0
    self.y = tonumber(y) or 0
    self.width = tonumber(width) or 0
    self.height = tonumber(height) or 0
    self.heading = tonumber(heading) or 0
    self.colour = {
        r = tonumber(r) or 255,
        g = tonumber(g) or 255,
        b = tonumber(b) or 255,
        a = tonumber(a) or 255
    }
end

---@param x number?
---@param y number?
---@return table?
function Sprite:position(x, y)
    if tonumber(x) and tonumber(y) then
        self.x = x --[[@as number]]
        self.y = y --[[@as number]]
    end
end

---@param width number?
---@param height number?
---@return table?
function Sprite:size(width, height)
    if tonumber(width) and tonumber(height) then
        self.width = width --[[@as number]]
        self.height = height --[[@as number]]
    end
end

---@param r number?
---@param g number?
---@param b number?
---@param a number?
---@return table?
function Sprite:setColour(r, g, b, a)
    if tonumber(r) or tonumber(g) or tonumber(b) or tonumber(a) then
        self.colour.r = r or self.colour.r
        self.colour.g = g or self.colour.g
        self.colour.b = b or self.colour.b
        self.colour.a = a or self.colour.a
    end
end

function Sprite:draw()
    pcall(function (...)
        lib.requestStreamedTextureDict(self.txtDictionary, 1500)
    end)

    local formattedWidth, formattedHeight = utils.formatXWYH(self.width, self.height)
    local formattedX, formattedY = utils.formatXWYH(self.x, self.y)

    DrawSprite(
        self.txtDictionary,
        self.txtName,
        formattedX + formattedWidth * 0.5,
        formattedY + formattedHeight * 0.5,
        formattedWidth,
        formattedHeight,
        self.heading,
        self.colour.r,
        self.colour.g,
        self.colour.b,
        self.colour.a
    )
end

return Sprite