local config = localmodule 'config'

local type = type
local tonumber = tonumber
local floor = math.floor
local smatch = string.match
local sgsub = string.gsub
local ssub = string.sub

local DEFAULTS = config.defaults
local MAX_TEXT = config.maxText
local RAW_LIMIT = MAX_TEXT * 4
local MAX_DISTANCE = config.maxDistance
local MAX_DURATION = config.maxDuration
local LEGACY_FONTS = config.legacyFonts

---@type table<string, true>
local fontKeys = {}
for i = 1, #config.fonts do
    fontKeys[config.fonts[i].key] = true
end

---@type table<string, true>
local backgroundKeys = {}
for i = 1, #config.backgrounds do
    backgroundKeys[config.backgrounds[i].key] = true
end

---@class SceneStyle
---@field text string
---@field font string
---@field colour string
---@field fontSize number
---@field viewDistance number
---@field shadow boolean
---@field outline boolean
---@field background string
---@field backgroundColour string
---@field backgroundAlpha integer
---@field backgroundX number
---@field backgroundY number
---@field backgroundWidth number
---@field backgroundHeight number

---@param value any
---@param min number
---@param max number
---@param fallback number
---@return number
local function clampNumber(value, min, max, fallback)
    local number = tonumber(value)

    if not number or number ~= number then return fallback end
    if number < min then return min end
    if number > max then return max end

    return number
end

---@param value any
---@param fallback string
---@return string
local function hexColour(value, fallback)
    if type(value) ~= 'string' then return fallback end
    if not smatch(value, '^#%x%x%x%x%x%x$') then return fallback end

    return value
end

---@param value any
---@return string
local function cleanText(value)
    if type(value) ~= 'string' then return '' end

    if #value > RAW_LIMIT then
        value = ssub(value, 1, RAW_LIMIT)
    end

    local text = sgsub(value, '\r', '')
    text = sgsub(text, '[\0-\9\11-\31\127]', '')
    text = sgsub(text, '~', '')
    text = sgsub(text, '\n\n\n+', '\n\n')
    text = smatch(text, '^%s*(.-)%s*$') or ''

    if #text > MAX_TEXT then
        text = ssub(text, 1, MAX_TEXT)
        text = sgsub(text, '[\128-\191]*$', '')
        text = sgsub(text, '[\192-\255]$', '')
    end

    return text
end

---@param value any
---@return string
local function fontKey(value)
    if type(value) == 'string' and fontKeys[value] then return value end

    local legacy = tonumber(value)

    return legacy and LEGACY_FONTS[legacy] or DEFAULTS.font
end

---@param input any
---@return SceneStyle
local function style(input)
    if type(input) ~= 'table' then input = {} end

    local background = input.background

    if type(background) ~= 'string' or not backgroundKeys[background] then
        background = 'none'
    end

    return {
        text = cleanText(input.text),
        font = fontKey(input.font),
        colour = hexColour(input.colour, DEFAULTS.colour),
        fontSize = clampNumber(input.fontSize, 0.1, 1.0, DEFAULTS.fontSize),
        viewDistance = floor(clampNumber(input.viewDistance, 1, MAX_DISTANCE, DEFAULTS.viewDistance)),
        shadow = input.shadow == true,
        outline = input.outline == true,
        background = background,
        backgroundColour = hexColour(input.backgroundColour, DEFAULTS.backgroundColour),
        backgroundAlpha = floor(clampNumber(input.backgroundAlpha, 0, 255, DEFAULTS.backgroundAlpha)),
        backgroundX = clampNumber(input.backgroundX, -0.2, 0.2, DEFAULTS.backgroundX),
        backgroundY = clampNumber(input.backgroundY, -0.2, 0.2, DEFAULTS.backgroundY),
        backgroundWidth = clampNumber(input.backgroundWidth, -0.5, 0.5, DEFAULTS.backgroundWidth),
        backgroundHeight = clampNumber(input.backgroundHeight, -0.5, 0.5, DEFAULTS.backgroundHeight),
    }
end

---@param value any
---@return integer
local function duration(value)
    return floor(clampNumber(value, 1, MAX_DURATION, DEFAULTS.duration))
end

---@param value any
---@return vector3?
local function coords(value)
    if type(value) ~= 'table' and type(value) ~= 'vector3' then return nil end

    local x, y, z = tonumber(value.x), tonumber(value.y), tonumber(value.z)

    if not x or not y or not z then return nil end
    if x ~= x or y ~= y or z ~= z then return nil end

    return vector3(x, y, z)
end

return {
    style = style,
    duration = duration,
    coords = coords,
}
