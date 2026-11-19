local QBCore = exports['qb-core']:GetCoreObject()

local function db(query, params)
    return exports.oxmysql:query(query, params or {})
end

CreateThread(function()
    db([[CREATE TABLE IF NOT EXISTS sm_media_posts (
        id INT AUTO_INCREMENT PRIMARY KEY,
        title VARCHAR(120) NOT NULL,
        body TEXT,
        url VARCHAR(255),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]])

    db([[CREATE TABLE IF NOT EXISTS sm_media_read (
        citizenid VARCHAR(50) PRIMARY KEY,
        last_read_id INT NOT NULL DEFAULT 0
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]])
end)

local function citizenId(source)
    local Player = QBCore.Functions.GetPlayer(source)

    return Player and Player.PlayerData.citizenid or nil
end

local function sendUnread(source)
    local cid = citizenId(source)

    if not cid then return end

    local read = db('SELECT last_read_id FROM sm_media_read WHERE citizenid = ?', { cid })
    local last = read and read[1] and read[1].last_read_id or 0

    local latest = db('SELECT MAX(id) AS id FROM sm_media_posts')
    local latestId = latest and latest[1] and latest[1].id or 0

    if not latestId or latestId <= last then
        TriggerClientEvent('sm_media_notify:unread', source, { latestId = latestId or 0, total = 0 })
        return
    end

    local total = db('SELECT COUNT(*) AS c FROM sm_media_posts WHERE id > ?', { last })

    TriggerClientEvent('sm_media_notify:unread', source, {
        latestId = latestId,
        total = total and total[1] and total[1].c or 0,
    })
end

local function publish(title, body, url)
    if type(title) ~= 'string' or title == '' then return end

    local id = db('INSERT INTO sm_media_posts (title, body, url) VALUES (?, ?, ?)', {
        title:sub(1, 120),
        body or '',
        url or '',
    })

    local payload = { id = id, title = title, body = body or '', url = url or '' }

    TriggerClientEvent('sm_media_notify:show', -1, payload)

    for _, raw in ipairs(GetPlayers()) do
        sendUnread(tonumber(raw))
    end

    return id
end

exports('publish', publish)
exports('refresh', sendUnread)

RegisterNetEvent('sm_media_notify:markRead', function(id)
    local source = source
    local cid = citizenId(source)

    if not cid then return end

    id = math.max(tonumber(id) or 0, 0)

    db([[INSERT INTO sm_media_read (citizenid, last_read_id) VALUES (?, ?)
        ON DUPLICATE KEY UPDATE last_read_id = GREATEST(last_read_id, VALUES(last_read_id))]], { cid, id })
end)

AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
    local source = Player and Player.PlayerData and Player.PlayerData.source

    if source then sendUnread(source) end
end)

AddEventHandler('playerJoining', function()
    local source = source

    SetTimeout(5000, function()
        if GetPlayerName(source) then sendUnread(source) end
    end)
end)

RegisterCommand('satumedia', function(_, args)
    local raw = table.concat(args, ' ')

    if raw == '' then
        print('pakai: satumedia judul|isi|url')
        return
    end

    local title, body, url = raw:match('^([^|]*)|?([^|]*)|?(.*)$')

    if not title or title == '' then
        print('judul kosong')
        return
    end

    local id = publish(title, body, url)

    print(('post media #%s terkirim'):format(tostring(id)))
end, true)

lib.print.info('sm_media_notify server siap')
