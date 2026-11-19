local resource = GetCurrentResourceName()

local function webhook()
    return GetConvar(('%s:webhook'):format(resource), '')
end

local log = {}

---@param title string
---@param description string
---@param colour? integer
function log.send(title, description, colour)
    local url = webhook()
    if url == '' then return false end

    PerformHttpRequest(url, function() end, 'POST', json.encode({
        username = resource,
        embeds = { { title = title, description = description, color = colour or 3447003, timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ') } },
    }), { ['Content-Type'] = 'application/json' })

    return true
end

---@param action string
---@param source number
---@param extra? table
function log.action(action, source, extra)
    local lines = { ('**%s** oleh `%s`'):format(action, GetPlayerName(source) or source) }

    if extra then
        for key, value in pairs(extra) do
            lines[#lines + 1] = ('%s: `%s`'):format(key, tostring(value))
        end
    end

    log.send(action, table.concat(lines, '\n'))
end

return log