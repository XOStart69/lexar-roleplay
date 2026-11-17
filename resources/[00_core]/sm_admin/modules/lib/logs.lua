local Logs = {}

---@class DiscordColor
local DiscordColors = {
    default = 3447003,    -- Blue
    success = 3066993,    -- Green
    warning = 15105570,   -- Orange
    error = 15158332,     -- Red
    info = 3447003,       -- Blue
    admin = 10181046,     -- Purple
    money = 15844367,     -- Gold
    vehicle = 9807270,    -- Gray
    items = 9807270,    -- Gray
    allaction = 9807270,    -- Gray
    admincarplate = 9807270,    -- Gray
    inventory = 3066993,  -- Green
    player = 5763719,     -- Aqua
    system = 9936031,     -- Dark gray
    god = 16711680,       -- Bright red
}

---@class EmbedField
---@field name string
---@field value string
---@field inline? boolean

---@class EmbedFooter
---@field text string
---@field icon_url? string

---@class EmbedAuthor
---@field name string
---@field url? string
---@field icon_url? string

---@class EmbedImage
---@field url string

---@class EmbedThumbnail
---@field url string

---@class DiscordEmbed
---@field title? string
---@field description? string
---@field color? number
---@field fields? EmbedField[]
---@field footer? EmbedFooter
---@field author? EmbedAuthor
---@field image? EmbedImage
---@field thumbnail? EmbedThumbnail
---@field timestamp? string

---@class LogData
---@field title? string
---@field description? string
---@field color? string|number
---@field fields? table<string, any>
---@field thumbnail? string
---@field image? string
---@field footer? string
---@field timestamp? boolean
---@field author? {name: string, icon?: string}

local utils = require 'modules.lib.utils'

---@param fields table<string, any>
---@return EmbedField[]
local function FormatFields(fields)
    local embedFields = {}

    for key, value in pairs(fields) do
        local formattedValue = value

        if type(value) == 'table' then
            formattedValue = json.encode(value, {indent = true})
        elseif type(value) == 'boolean' then
            formattedValue = value and 'Yes' or 'No'
        elseif type(value) == 'nil' then
            formattedValue = 'N/A'
        else
            formattedValue = tostring(value)
        end

        table.insert(embedFields, {
            name = key,
            value = formattedValue,
            inline = true
        })
    end

    return embedFields
end

---@param color string|number|nil
---@return number
local function GetColor(color)
    if type(color) == 'number' then
        return color
    elseif type(color) == 'string' then
        return DiscordColors[color] or DiscordColors.default
    end
    return DiscordColors.default
end

local LOG_USERNAME = 'SMLogs'
local LOG_AVATAR = GetConvar('smlogs_avatar', 'https://media.discordapp.net/attachments/1218808338956161062/1412428693174882496/Satu_Mimpi_Logo.png?ex=6adffdfa&is=6adeac7a&hm=b70092015422fd1db0bfb8245e8e078d91e132451074ffc383d634ee9e156371&=&format=webp&quality=lossless')

local function CreatePlayerInfo(source, embed, isTarget)
    local identifiers = exports.sm_core:GetIdentifier(source) or {}
    local discord = identifiers.discord and identifiers.discord:match('^discord:(%d+)')

    table.insert(embed.fields, {
        name = isTarget and 'Target' or 'Admin',
        value = ('[%s] %s\nCharacter: %s\nSteam: `%s`\nDiscord: %s'):format(
            source,
            GetPlayerName(source) or 'Offline',
            exports.sm_core:GetName(source) or 'N/A',
            identifiers.steam or '-',
            discord and ('<@%s>'):format(discord) or '-'
        ),
        inline = true
    })
end

---@param logData LogData
---@param source? number
---@param targetSource? number
---@return DiscordEmbed
local function CreateEmbed(logData, source, targetSource)
    local embed = {
        title = logData.title or 'Admin Log',
        description = logData.description,
        color = GetColor(logData.color),
        fields = {},
        timestamp = logData.timestamp ~= false and os.date('!%Y-%m-%dT%H:%M:%SZ') or nil
    }

    if source then
        CreatePlayerInfo(source, embed, false)
    end

    if targetSource then
        CreatePlayerInfo(targetSource, embed, true)
    end

    if not source and not targetSource and logData.author then
        embed.author = {
            name = logData.author.name,
            icon_url = logData.author.icon
        }
    end

    if logData.fields then
        local customFields = FormatFields(logData.fields)
        for _, field in ipairs(customFields) do
            table.insert(embed.fields, field)
        end
    end

    embed.footer = {
        text = logData.footer or 'SMLogs • Admin'
    }

    if logData.thumbnail then
        embed.thumbnail = {
            url = logData.thumbnail
        }
    end

    if logData.image then
        embed.image = {
            url = logData.image
        }
    end

    return embed
end

---@param webhook string
---@param embed DiscordEmbed
local function SendToDiscord(webhook, embed)
    local payload = json.encode({
        username = LOG_USERNAME,
        avatar_url = LOG_AVATAR,
        embeds = {embed}
    })

    PerformHttpRequest(webhook, function(statusCode, response)
        if statusCode ~= 204 then
            lib.print.error('Failed to send log: ' .. statusCode)
            if response then
                lib.print.error('Response: ' .. response)
            end
        end
    end, 'POST', payload, {
        ['Content-Type'] = 'application/json'
    })
end

---@param source number
---@param serverLog ServerLogs
---@param fields? table<string, any>
---@param targetSource? number
function Logs.Send(source, serverLog, fields, targetSource)
    if not serverLog or not serverLog.enable then
        return
    end

    if not serverLog.webhook or serverLog.webhook == '' then
        lib.print.warn('Webhook not configured')
        return
    end

    if serverLog.onlyFor and not utils.havePerms(source, { onlyFor = serverLog.onlyFor }) then
        return
    end

    local logData = {
        title = serverLog.title,
        description = serverLog.description,
        color = serverLog.color,
        fields = fields or serverLog.fields,
        thumbnail = serverLog.thumbnail,
        image = serverLog.image,
        footer = serverLog.footer,
        timestamp = serverLog.timestamp,
        author = serverLog.author
    }

    local embed = CreateEmbed(logData, source, targetSource)
    SendToDiscord(serverLog.webhook, embed)
end

Logs.Colors = DiscordColors

return Logs
