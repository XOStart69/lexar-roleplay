local format = string.format
local match = string.match
local gsub = string.gsub
local upper = string.upper
local floor = math.floor
local random = math.random

local Util = {}

local animals = {
    'Lion', 'Tiger', 'Elephant', 'Giraffe', 'Zebra', 'Hippo', 'Rhino',
    'Kangaroo', 'Koala', 'Panda', 'Leopard', 'Cheetah', 'Bear', 'Wolf',
    'Fox', 'Deer', 'Moose', 'Rabbit', 'Squirrel', 'Raccoon', 'Otter',
    'Skunk', 'Horse', 'Camel', 'Gazelle', 'Buffalo', 'Sheep', 'Goat',
    'Cow', 'Chicken', 'Duck', 'Goose', 'Turkey', 'Peacock', 'Ostrich',
    'Penguin', 'Flamingo', 'Eagle', 'Hawk', 'Owl', 'Parrot', 'Sparrow',
    'Swan', 'Seagull', 'Pelican',
}

local animalCount = #animals

local timeMultipliers = {
    S = 1,
    M = 60,
    H = 3600,
    D = 86400,
    W = 604800,
}

---@param str string
---@return string
function Util.ucfirst(str)
    return (gsub(str, '^%l', upper))
end

---@return string
function Util.uniqueId()
    return (gsub('xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx', '[xy]', function(c)
        if c == 'x' then
            return format('%x', random(0, 15))
        end
        return format('%x', 8 + random(0, 3))
    end))
end

---@return string
function Util.generateSpeakerName()
    return Util.ucfirst(animals[random(animalCount)])
        .. Util.ucfirst(animals[random(animalCount)])
        .. Util.ucfirst(animals[random(animalCount)])
end

---@param value number
---@return number
function Util.formatFloat(value)
    return tonumber(format('%.2f', value))
end

---@param value number
---@param total number
---@return number
function Util.percent(value, total)
    return floor(value * (total / 100) * 100 + 0.5) / 100
end

---@param url string
---@return string
function Util.formatShortUrl(url)
    local id = match(url, 'youtu%.be/([%w-_]+)')
    if not id then
        return url
    end

    local result = format('https://www.youtube.com/watch?v=%s', id)

    local list = match(url, 'list=([%w-_]+)')
    if list then
        result = result .. format('&list=%s', list)
    end

    local time = match(url, 't=(%d+)')
    if time then
        result = result .. format('&t=%ss', time)
    end

    return result
end

---@param url string
---@return boolean
function Util.isValidYouTubeUrl(url)
    url = Util.formatShortUrl(url)

    return match(url, 'https://www%.youtube%.com/watch%?v=...........') ~= nil
        or match(url, 'https://music%.youtube%.com/watch%?v=...........') ~= nil
end

---@param url string
---@return string? videoId
---@return string? playlistId
---@return string? startTime
function Util.getYouTubeIds(url)
    url = Util.formatShortUrl(url)
    return match(url, 'v=([%w-_]+)'), match(url, 'list=([%w-_]+)'), match(url, 't=(%d+)')
end

---@param iso string
---@return number
function Util.isoToSeconds(iso)
    local seconds = 0

    for value, unit in iso:gmatch('([%d.,]+)(%u)') do
        local multiplier = timeMultipliers[unit]
        if multiplier then
            seconds = seconds + (tonumber(value) or 0) * multiplier
        end
    end

    return seconds
end

return Util
