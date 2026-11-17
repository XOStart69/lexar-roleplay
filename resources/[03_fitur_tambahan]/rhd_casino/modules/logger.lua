local Logger = {}

local webhookUrl = GetConvar('rhd_casino:log_webhook', 'https://discord.com/api/webhooks/1519907942961250405/BPsixzZJOu5P1LIi_zDFdQWVjI8_g1ZPB9IxS4HN1bcNgaaHk7eahymGPtiqdc6DRUgv')
local username = GetConvar('rhd_casino:log_username', 'SMLogs')
local avatar = GetConvar('rhd_casino:log_avatar', GetConvar('smlogs_avatar', 'https://media.discordapp.net/attachments/1218808338956161062/1412428693174882496/Satu_Mimpi_Logo.png?ex=6adffdfa&is=6adeac7a&hm=b70092015422fd1db0bfb8245e8e078d91e132451074ffc383d634ee9e156371&=&format=webp&quality=lossless'))
local batchSize = GetConvarInt('rhd_casino:log_batch_size', 10)
local maxQueue = GetConvarInt('rhd_casino:log_max_queue', 500)

---@alias CasinoLogType 'default'|'success'|'error'|'warning'|'info'|'money'

---@type table<CasinoLogType, integer>
local colors = {
    default = 3447003,
    success = 3066993,
    error = 15158332,
    warning = 15844367,
    info = 3447003,
    money = 15844367,
}

---@type table[]
local queue = {}
local sending = false

---@class CasinoLogField
---@field name string
---@field value string
---@field inline? boolean

---@class CasinoLogData
---@field title string
---@field description? string
---@field type? CasinoLogType
---@field color? integer overrides the color resolved from type
---@field fields? CasinoLogField[]
---@field footer? string

---@param data CasinoLogData
---@return table
local function buildEmbed(data)
    return {
        title = data.title,
        description = data.description,
        color = data.color or colors[data.type or 'default'] or colors.default,
        fields = data.fields,
        footer = { text = data.footer and ('SMLogs • Casino • %s'):format(data.footer) or 'SMLogs • Casino' },
        timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ'),
    }
end

---Enqueues a log entry to be delivered to Discord on the next cron flush.
---@param data CasinoLogData
function Logger.log(data)
    if webhookUrl == '' or type(data) ~= 'table' or not data.title then return end

    if #queue >= maxQueue then
        table.remove(queue, 1)
    end

    queue[#queue + 1] = buildEmbed(data)
end

local function flush()
    if sending or webhookUrl == '' or #queue == 0 then return end

    local count = math.min(batchSize, #queue)
    local batch = {}
    for i = 1, count do
        batch[i] = table.remove(queue, 1)
    end

    sending = true

    local payload = json.encode({
        username = username,
        avatar_url = avatar ~= '' and avatar or nil,
        embeds = batch,
    })

    PerformHttpRequest(webhookUrl, function(status)
        sending = false

        if status ~= 200 and status ~= 204 then
            lib.print.warn(('[CasinoLogger] Discord webhook failed (status: %s), re-queueing %s log(s)'):format(status, count))
            for i = count, 1, -1 do
                table.insert(queue, 1, batch[i])
            end
        end
    end, 'POST', payload, { ['Content-Type'] = 'application/json' })
end

if webhookUrl ~= '' then
    lib.cron.new('* * * * *', flush)
else
    lib.print.warn('[CasinoLogger] rhd_casino:log_webhook is not set, Discord logging disabled')
end

return Logger
