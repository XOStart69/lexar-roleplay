local smatch = string.match
local slower = string.lower
local sfind = string.find
local sformat = string.format
local ssub = string.sub
local mathFloor = math.floor

local media = {}

local LABELS = {
    youtube = 'YouTube',
    twitch = 'Twitch',
    kick = 'Kick',
    streamable = 'Streamable',
    vimeo = 'Vimeo',
    dailymotion = 'Dailymotion',
    soundcloud = 'SoundCloud',
    video = 'Video',
    audio = 'Audio',
    image = 'Gambar',
}

local PLAYER_TYPES = { youtube = true, video = true, audio = true, image = true }

local EXTENSIONS = {
    mp4 = 'video',
    webm = 'video',
    mp3 = 'audio',
    ogg = 'audio',
    wav = 'audio',
    m4a = 'audio',
    png = 'image',
    jpg = 'image',
    jpeg = 'image',
    gif = 'image',
    webp = 'image',
}

local EMBEDS = {
    twitch = 'https://player.twitch.tv/?channel=%s&parent=streamernews.example.com&autoplay=true',
    kick = 'https://player.kick.com/%s?autoplay=true&muted=false',
    streamable = 'https://streamable.com/e/%s?autoplay=1&t=%d',
    vimeo = 'https://player.vimeo.com/video/%s?autoplay=1#t=%ds',
    dailymotion = 'https://www.dailymotion.com/embed/video/%s?autoplay=1&start=%d',
}

local MAX_LENGTH = 512

---@param host string
---@param path string
---@return string?
local function youtubeId(host, path)
    local id
    if host == 'youtu.be' then
        id = smatch(path, '^/([%w_%-]+)')
    elseif host == 'youtube.com' or host == 'music.youtube.com' or host == 'youtube-nocookie.com' then
        id = smatch(path, '[?&]v=([%w_%-]+)')
            or smatch(path, '^/shorts/([%w_%-]+)')
            or smatch(path, '^/live/([%w_%-]+)')
            or smatch(path, '^/embed/([%w_%-]+)')
    end
    if id and #id == 11 then
        return id
    end
end

---@param host string
---@param path string
---@return string? kind
---@return string? src
local function provider(host, path)
    local id = youtubeId(host, path)
    if id then
        return 'youtube', id
    end

    if host == 'twitch.tv' then
        id = smatch(path, '^/([%w_]+)/?$') or smatch(path, '^/([%w_]+)[?#]')
        return id and 'twitch', id
    elseif host == 'kick.com' then
        id = smatch(path, '^/([%w_%-]+)/?$') or smatch(path, '^/([%w_%-]+)[?#]')
        return id and 'kick', id
    elseif host == 'streamable.com' then
        id = smatch(path, '^/e/(%w+)') or smatch(path, '^/(%w+)')
        return id and 'streamable', id
    elseif host == 'vimeo.com' then
        id = smatch(path, '^/(%d+)')
        return id and 'vimeo', id
    elseif host == 'player.vimeo.com' then
        id = smatch(path, '^/video/(%d+)')
        return id and 'vimeo', id
    elseif host == 'dailymotion.com' then
        id = smatch(path, '^/video/(%w+)')
        return id and 'dailymotion', id
    elseif host == 'dai.ly' then
        id = smatch(path, '^/(%w+)')
        return id and 'dailymotion', id
    elseif host == 'soundcloud.com' then
        id = smatch(path, '^/([%w_%-]+/[%w_%-/]+)')
        return id and 'soundcloud', id
    end
end

---@param host string
---@param blocked string[]
---@return boolean
local function isBlocked(host, blocked)
    for i = 1, #blocked do
        local entry = blocked[i]
        local start = #host - #entry + 1
        if start >= 1 and ssub(host, start) == entry and (start == 1 or ssub(host, start - 1, start - 1) == '.') then
            return true
        end
    end
    return false
end

---@param raw string
---@param links table<string, boolean>
---@param blocked string[]
---@return table? result
---@return string? reason
function media.parse(raw, links, blocked)
    local url = smatch(raw, '^%s*(.-)%s*$')
    if #url == 0 or #url > MAX_LENGTH or sfind(url, '[%s"\'<>\\`]') then
        return nil, 'unsupported'
    end

    if not sfind(url, '^[Hh][Tt][Tt][Pp][Ss]?://') then
        url = 'https://' .. url
    end

    local host, path = smatch(url, '^[Hh][Tt][Tt][Pp][Ss]?://([^/?#]+)(.*)$')
    if not host then
        return nil, 'unsupported'
    end

    host = slower(smatch(host, '^([^:]+)') or host)
    host = smatch(host, '^www%.(.+)$') or smatch(host, '^m%.(.+)$') or host

    if isBlocked(host, blocked) then
        return nil, 'blocked'
    end

    local kind, src = provider(host, path)
    if not kind then
        local ext = smatch(smatch(path, '^([^?#]*)'), '%.(%w+)$')
        kind = ext and EXTENSIONS[slower(ext)]
        src = url
    end

    if not kind or not links[kind] then
        return nil, 'unsupported'
    end

    return { type = kind, src = src, label = LABELS[kind], url = url }
end

---@param kind string
---@return boolean
function media.isPlayer(kind)
    return PLAYER_TYPES[kind] == true
end

---@param item table
---@param elapsed number
---@return string
function media.embed(item, elapsed)
    local seconds = mathFloor(elapsed)
    if item.type == 'soundcloud' then
        return sformat('https://soundcloud.com/%s#t=%d:%02d', item.src, mathFloor(seconds / 60), seconds % 60)
    end
    return sformat(EMBEDS[item.type], item.src, seconds)
end

return media
