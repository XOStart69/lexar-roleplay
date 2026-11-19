local Image = {}

local provider = Config.Server.screenshot.provider or 'offline'

---@param name string
---@param base64 string
---@return string? url
function Image.save(name, base64)
    local payload = base64:gsub('^data:image/%w+;base64,', '')
    local fileName = ('%s_%d.png'):format(name:gsub('[^%w]+', '_'), os.time())

    if provider == 'offline' then
        local path = ('%s/%s'):format(Config.Server.screenshot.folder, fileName)
        SaveResourceFile(GetCurrentResourceName(), path, payload, -1)
        return ('nui://%s/%s'):format(GetCurrentResourceName(), path)
    end

    if provider == 'discord' and Config.Server.screenshot.webhook ~= '' then
        PerformHttpRequest(Config.Server.screenshot.webhook, function() end, 'POST', payload, {
            ['Content-Type'] = 'image/png',
        })
        return nil
    end

    if provider == 'fivemanage' or provider == 'fivemerr' or provider == 'fivehub' then
        local url = Image.uploadRemote(payload, fileName)
        return url
    end

    local path = ('%s/%s'):format(Config.Server.screenshot.folder, fileName)
    SaveResourceFile(GetCurrentResourceName(), path, payload, -1)
    return ('nui://%s/%s'):format(GetCurrentResourceName(), path)
end

---@param payload string
---@param fileName string
---@return string? url
function Image.uploadRemote(payload, fileName)
    local endpoint = Config.Server.screenshot.imageServer
    if endpoint == '' then return nil end

    local body = json.encode({ name = fileName, image = payload })
    local result

    PerformHttpRequest(endpoint .. '/upload', function(status, response)
        if status ~= 200 or not response then return end
        local ok, parsed = pcall(json.decode, response)
        if ok and type(parsed) == 'table' then
            result = parsed.url or parsed.data
        end
    end, 'POST', body, {
        ['Content-Type'] = 'application/json',
        ['Authorization'] = Config.Server.screenshot.token,
    })

    local deadline = GetGameTimer() + 5000
    while not result and GetGameTimer() < deadline do Wait(50) end
    return result
end

return Image