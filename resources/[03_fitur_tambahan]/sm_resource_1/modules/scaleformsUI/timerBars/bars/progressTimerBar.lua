---@diagnostic disable: missing-parameter

---@class ProgressTimerBar
---@field label string
---@field percentage number
---@field maxTime number
---@field time number
---@field backgroundColor {r: number, g: number, b: number, a: number}
---@field foregroundColor {r: number, g: number, b: number, a: number}
---@field backgroundRect UIResRectangle
---@field foregroundRect UIResRectangle
---@field enabled boolean
---@field labelFont number
---@field handle number|nil
local ProgressTimerBar = lib.class('ProgressTimerBar')

local UIResRectangle = require 'modules.scaleformsUI.timerBars.uiResRectangle'
local UIResText = require 'modules.scaleformsUI.timerBars.uiResText'
local Sprite = require 'modules.scaleformsUI.timerBars.sprite'
local Utils = require 'modules.scaleformsUI.utils.shared'

---@param label string?
---@param backgroundColor table?
---@param foregroundColor table?
---@param percentage number?
---@param time number?
function ProgressTimerBar:constructor(label, backgroundColor, foregroundColor, percentage, time)

    backgroundColor = backgroundColor or {r = 112, g = 25, b = 25, a = 255}
    foregroundColor = foregroundColor or {r = 224, g = 50, b = 50, a = 255}

    percentage = percentage or 0
    if percentage > 1 then percentage = 1 end
    if percentage < 0 then percentage = 0 end

    time = time or 0
    if time < 0 then time = 0 end

    self.label = label or ""
    self.percentage = percentage
    self.maxTime = time
    self.time = GetGameTimer()
    self.backgroundColor = backgroundColor
    self.foregroundColor = foregroundColor
    self.enabled = true
    self.labelFont = Utils.Fonts.CHALET_LONDON
    self.handle = nil

    ---@diagnostic disable-next-line: undefined-field
    self.backgroundRect = UIResRectangle:new(
        0, 0, 150, 15,
        backgroundColor.r, backgroundColor.g, backgroundColor.b, backgroundColor.a
    )

    ---@diagnostic disable-next-line: undefined-field
    self.foregroundRect = UIResRectangle:new(
        0, 0, 0, 15,
        foregroundColor.r, foregroundColor.g, foregroundColor.b, foregroundColor.a
    )

    ---@diagnostic disable-next-line: undefined-field
    self.labelText = UIResText:new(
        self.label,
        0, 0,
        0.35,
        240, 240, 240, 255,
        self.labelFont,
        2  -- Right alignment
    )

    ---@diagnostic disable-next-line: undefined-field
    self.bgSprite = Sprite:new(
        "timerbars",
        "all_black_bg",
        0, 0,
        300, 37, 0.0,
        255, 255, 255, 180
    )
end

---@param label string?
---@return string?
function ProgressTimerBar:setLabel(label)
    if label == nil then
        return self.label
    end

    self.label = label
end

---@param font number?
---@return number?
function ProgressTimerBar:setLabelFont(font)
    if font == nil then
        return self.labelFont
    end

    self.labelFont = font
end

---@param color table?
---@return table?
function ProgressTimerBar:setBackgroundColor(color)
    if color == nil then
        return self.backgroundColor
    end

    self.backgroundColor = color
end

---@param color table?
---@return table?
function ProgressTimerBar:setForegroundColor(color)
    if color == nil then
        return self.foregroundColor
    end

    self.foregroundColor = color
end

---@param val number?
---@return number?
function ProgressTimerBar:setPercentage(val)
    if val == nil then
        return self.percentage
    end

    self.percentage = val
    if self.maxTime > 0 then
        self.time = (self.maxTime / 1.0) * val
    end
end

---@return number
function ProgressTimerBar:getTime()
    return self.time
end

---@param bool boolean?
---@return boolean?
function ProgressTimerBar:setEnabled(bool)
    if bool then
        self.time = GetGameTimer()
    end
    self.enabled = bool --[[@as boolean]]
end

---@param interval number
function ProgressTimerBar:draw(interval)
    if not self.enabled then return end

    local resx, resy = Utils.resolutionMaintainRatio()
    local safex, safey = Utils.safezoneBounds()

    if self.percentage > 0 and self.maxTime > 0 then
        local t = GetGameTimer() - self.time
        self.percentage = 1.0 - (t / (self.maxTime / 1.0))
        if self.percentage < 0 then
            self.percentage = 0
        end
    end

    self.labelText:position(resx - safex - 180, resy - safey - (35 + (4 * interval)))
    self.labelText:draw()

    self.bgSprite:position(resx - safex - 298, resy - safey - (40 + (4 * interval)))
    self.bgSprite:draw()

    local startx = resx - safex - 160
    local starty = resy - safey - (28 + (4 * interval))

    self.backgroundRect:position(startx, starty)
    self.foregroundRect:position(startx, starty)
    self.foregroundRect:size(150 * self.percentage, 15)

    self.backgroundRect:setColour(
        self.backgroundColor.r,
        self.backgroundColor.g,
        self.backgroundColor.b,
        self.backgroundColor.a
    )

    self.foregroundRect:setColour(
        self.foregroundColor.r,
        self.foregroundColor.g,
        self.foregroundColor.b,
        self.foregroundColor.a
    )

    self.backgroundRect:draw()
    self.foregroundRect:draw()

    HideHudComponentThisFrame(6)
    HideHudComponentThisFrame(7)
    HideHudComponentThisFrame(9)
end

return ProgressTimerBar