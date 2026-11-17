---@class UIResText
---@field text string
---@field x number
---@field y number
---@field scale number
---@field colour {r: number, g: number, b: number, a: number}
---@field font number
---@field alignment string|number|nil
---@field dropShadow boolean|nil
---@field outline boolean|nil
---@field wordWrap number
local UIResText = lib.class('UIResText')

local utils = require 'modules.scaleformsUI.utils.shared'

---@param str string
---@return number
local function getCharacterCount(str)
    local characters = 0
    for c in str:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        local a = c:byte(1, -1)
        if a ~= nil then
            characters = characters + 1
        end
    end
    return characters
end

---@param str string
---@return number
local function getByteCount(str)
    local bytes = 0
    for c in str:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        local a, b, c, d = c:byte(1, -1)
        if a ~= nil then bytes = bytes + 1 end
        if b ~= nil then bytes = bytes + 1 end
        if c ~= nil then bytes = bytes + 1 end
        if d ~= nil then bytes = bytes + 1 end
    end
    return bytes
end

---@param str string
local function addLongStringForAscii(str)
    local maxbytelength = 99
    for i = 0, getCharacterCount(str), 99 do
        AddTextComponentSubstringPlayerName(string.sub(str, i, math.min(maxbytelength, getCharacterCount(str) - i)))
    end
end

---@param str string
local function addLongStringForUtf8(str)
    local maxbytelength = 99
    local bytecount = getByteCount(str)

    if bytecount < maxbytelength then
        AddTextComponentSubstringPlayerName(str)
        return
    end
    
    local startIndex = 0
    for i = 0, getCharacterCount(str), 1 do
        local length = i - startIndex
        if getByteCount(string.sub(str, startIndex, length)) > maxbytelength then
            AddTextComponentSubstringPlayerName(string.sub(str, startIndex, length - 1))
            i = i - 1
            startIndex = startIndex + (length - 1)
        end
    end
    AddTextComponentSubstringPlayerName(string.sub(str, startIndex, getCharacterCount(str) - startIndex))
end

---@param str string
local function addLongString(str)
    local bytecount = getByteCount(str)
    if bytecount == getCharacterCount(str) then
        addLongStringForAscii(str)
    else
        addLongStringForUtf8(str)
    end
end

---@param str string
---@param font number
---@param scale number
---@return number
local function measureStringWidthNoConvert(str, font, scale)
    BeginTextCommandGetWidth("STRING")
    addLongString(str)
    SetTextFont(font or 0)
    SetTextScale(1.0, scale or 0)
    return EndTextCommandGetWidth(true)
end

---@param str string
---@param font number
---@param scale number
---@return number
function UIResText.measureStringWidth(str, font, scale)
    return measureStringWidthNoConvert(str, font, scale) * 1920
end

---@param text string
---@param x number?
---@param y number?
---@param scale number?
---@param r number?
---@param g number?
---@param b number?
---@param a number?
---@param font number?
---@param alignment string|number|nil
---@param dropShadow boolean|nil
---@param outline boolean|nil
---@param wordWrap number?
function UIResText:constructor(text, x, y, scale, r, g, b, a, font, alignment, dropShadow, outline, wordWrap)
    self.text = tostring(text) or ""
    self.x = tonumber(x) or 0
    self.y = tonumber(y) or 0
    self.scale = tonumber(scale) or 0
    self.colour = {
        r = tonumber(r) or 255,
        g = tonumber(g) or 255,
        b = tonumber(b) or 255,
        a = tonumber(a) or 255
    }
    self.font = tonumber(font) or 0
    self.alignment = alignment
    self.dropShadow = dropShadow
    self.outline = outline
    self.wordWrap = tonumber(wordWrap) or 0
end

---@param x number?
---@param y number?
---@return table?
function UIResText:position(x, y)
    if tonumber(x) and tonumber(y) then
        self.x = x --[[@as number]]
        self.y = y --[[@as number]]
    end
end

---@param r number?
---@param g number?
---@param b number?
---@param a number?
---@return table?
function UIResText:setColour(r, g, b, a)
    if tonumber(r) and tonumber(g) and tonumber(b) and tonumber(a) then
        self.colour.r = r --[[@as number]]
        self.colour.g = g --[[@as number]]
        self.colour.b = b --[[@as number]]
        self.colour.a = a --[[@as number]]
    end
end

---@param text string?
---@return string?
function UIResText:setText(text)
    if text ~= nil and tostring(text) then
        self.text = tostring(text)
    end
end

function UIResText:draw()
    -- Convert koordinat ke format layar (0.0-1.0)
    local screenX, screenY = utils.formatXWYH(self.x, self.y)
    
    SetTextFont(self.font)
    SetTextScale(1.0, self.scale)
    SetTextColour(self.colour.r, self.colour.g, self.colour.b, self.colour.a)

    if self.dropShadow then
        SetTextDropShadow()
    end
    
    if self.outline then
        SetTextOutline()
    end

    if self.alignment ~= nil then
        if self.alignment == 1 or self.alignment == "Center" or self.alignment == "Centre" then
            SetTextCentre(true)
        elseif self.alignment == 2 or self.alignment == "Right" then
            SetTextRightJustify(true)
            SetTextWrap(0, screenX)
        end
    end

    if tonumber(self.wordWrap) and tonumber(self.wordWrap) ~= 0 then
        local width, height = utils.resolutionMaintainRatio()
        SetTextWrap(screenX, screenX + (tonumber(self.wordWrap) / width))
    end

    BeginTextCommandDisplayText("STRING")
    addLongString(self.text)
    EndTextCommandDisplayText(screenX, screenY)
end

return UIResText