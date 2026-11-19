--[[
    sm_report :: server
    Antrean laporan pemain: klaim staf, chat dua arah, prioritas, resolusi, rating, log, leaderboard.
]]

local config = localmodule 'config.shared'

local QBCore = exports['qb-core']:GetCoreObject()

local COOLDOWN = config.cooldown or 60
local MAX_ACTIVE = config.maxActiveReports or 3
local MSG_INTERVAL = config.messageInterval or 1000
local HISTORY_LIMIT = config.historyLimit or 50
local RESOLVED_LIMIT = config.resolvedLimit or 30
local MESSAGE_LIMIT = config.messageLimit or 200

local CATEGORIES = {}
for i = 1, #config.categories do
    CATEGORIES[config.categories[i].id] = true
end

local PRIORITY_MAX = 0
for i = 1, #config.priorities do
    if config.priorities[i].id > PRIORITY_MAX then
        PRIORITY_MAX = config.priorities[i].id
    end
end

local STAFF_JOBS = { police = true, ambulance = true }
local STAFF_PERMS = { admin = true, god = true, mod = true }

local SCHEMA = {
    [[
    CREATE TABLE IF NOT EXISTS `sm_report_reports` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `citizenid` varchar(64) NOT NULL,
        `name` varchar(64) NOT NULL,
        `category` varchar(32) NOT NULL,
        `subject` varchar(255) NOT NULL,
        `description` text NOT NULL,
        `priority` tinyint(4) NOT NULL DEFAULT 1,
        `status` varchar(16) NOT NULL DEFAULT 'open',
        `assigned` varchar(64) DEFAULT NULL,
        `assignedName` varchar(64) DEFAULT NULL,
        `x` float DEFAULT NULL,
        `y` float DEFAULT NULL,
        `z` float DEFAULT NULL,
        `created` bigint(20) NOT NULL,
        `updated` bigint(20) NOT NULL,
        `resolved` bigint(20) DEFAULT NULL,
        `resolvedBy` varchar(64) DEFAULT NULL,
        `resolvedName` varchar(64) DEFAULT NULL,
        `rating` tinyint(4) DEFAULT NULL,
        `feedback` text DEFAULT NULL,
        PRIMARY KEY (`id`),
        KEY `status` (`status`),
        KEY `citizenid` (`citizenid`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]],
    [[
    CREATE TABLE IF NOT EXISTS `sm_report_messages` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `reportId` int(11) NOT NULL,
        `citizenid` varchar(64) NOT NULL,
        `name` varchar(64) NOT NULL,
        `staff` tinyint(1) NOT NULL DEFAULT 0,
        `message` text NOT NULL,
        `created` bigint(20) NOT NULL,
        PRIMARY KEY (`id`),
        KEY `reportId` (`reportId`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]],
    [[
    CREATE TABLE IF NOT EXISTS `sm_report_logs` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `actor` varchar(64) NOT NULL,
        `actorName` varchar(64) NOT NULL,
        `action` varchar(48) NOT NULL,
        `reportId` int(11) DEFAULT NULL,
        `detail` text DEFAULT NULL,
        `created` bigint(20) NOT NULL,
        PRIMARY KEY (`id`),
        KEY `created` (`created`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]],
    [[
    CREATE TABLE IF NOT EXISTS `sm_report_duty` (
        `citizenid` varchar(64) NOT NULL,
        `name` varchar(64) NOT NULL,
        `onDuty` tinyint(1) NOT NULL DEFAULT 0,
        `updated` bigint(20) NOT NULL,
        PRIMARY KEY (`citizenid`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]],
}

local cooldowns = {}
local messageCooldowns = {}
local spectating = {}

local function ply(src)
    return QBCore.Functions.GetPlayer(src)
end

local function identity(player)
    local charinfo = player.PlayerData.charinfo or {}
    local name = ('%s %s'):format(charinfo.firstname or 'Warga', charinfo.lastname or '')
    return player.PlayerData.citizenid, name
end

local function isStaff(player)
    if not player then return false end

    local src = player.PlayerData.source
    for perm in pairs(STAFF_PERMS) do
        if QBCore.Functions.HasPermission(src, perm) then return true end
    end

    local job = player.PlayerData.job
    return STAFF_JOBS[job.name] == true and job.onduty == true
end

local function onlineOf(citizenid)
    local players = QBCore.Functions.GetQBPlayers()
    for src, player in pairs(players) do
        if player.PlayerData.citizenid == citizenid then return src end
    end
end

local function notify(src, description, nType)
    lib.notify(src, { title = 'Laporan', description = description, type = nType or 'error' })
end

local function log(actor, action, reportId, detail)
    local citizenid, name = 'system', 'System'
    local player = ply(actor)

    if player then
        citizenid, name = identity(player)
    end

    MySQL.insert('INSERT INTO sm_report_logs (actor, actorName, action, reportId, detail, created) VALUES (?, ?, ?, ?, ?, ?)', {
        citizenid, name, action, reportId, detail, os.time()
    })
end

local function activeCount(citizenid)
    local row = MySQL.single.await("SELECT COUNT(*) AS total FROM sm_report_reports WHERE citizenid = ? AND status <> 'resolved'", { citizenid })
    return row and tonumber(row.total) or 0
end

local function fetchReport(id)
    return MySQL.single.await('SELECT * FROM sm_report_reports WHERE id = ?', { id })
end

local function serialize(row)
    return {
        id = row.id,
        citizenid = row.citizenid,
        name = row.name,
        category = row.category,
        subject = row.subject,
        description = row.description,
        priority = row.priority,
        status = row.status,
        assigned = row.assigned,
        assignedName = row.assignedName,
        coords = { x = row.x, y = row.y, z = row.z },
        created = row.created,
        updated = row.updated,
        resolved = row.resolved,
        resolvedName = row.resolvedName,
        rating = row.rating,
        feedback = row.feedback,
    }
end

local function broadcastStaff(kind, payload, sound)
    local players = QBCore.Functions.GetQBPlayers()

    for src, player in pairs(players) do
        if isStaff(player) then
            TriggerClientEvent('sm_report:client:push', src, kind, payload)
            if sound then
                TriggerClientEvent('sm_report:client:sound', src, sound)
            end
        end
    end
end

local function pushDuty()
    local rows = MySQL.query.await('SELECT name FROM sm_report_duty WHERE onDuty = 1') or {}
    local names = {}

    for i = 1, #rows do
        names[i] = rows[i].name
    end

    GlobalState.reportDuty = { count = #names, names = names }
end

local function dutySet(citizenid, name, value)
    MySQL.insert.await('INSERT INTO sm_report_duty (citizenid, name, onDuty, updated) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE onDuty = ?, name = ?, updated = ?', {
        citizenid, name, value and 1 or 0, os.time(), value and 1 or 0, name, os.time()
    })
    pushDuty()
end

CreateThread(function()
    for i = 1, #SCHEMA do
        MySQL.query.await(SCHEMA[i])
    end

    Wait(500)
    pushDuty()
end)

lib.callback.register('sm_report:init', function(src)
    local player = ply(src)
    if not player then return end

    local staff = isStaff(player)
    local citizenid, name = identity(player)

    local reports
    if staff then
        reports = MySQL.query.await("SELECT * FROM sm_report_reports WHERE status <> 'resolved' ORDER BY priority DESC, created ASC LIMIT 60") or {}
    else
        reports = MySQL.query.await("SELECT * FROM sm_report_reports WHERE citizenid = ? AND status <> 'resolved' ORDER BY created DESC LIMIT 10", { citizenid }) or {}
    end

    local list = {}
    for i = 1, #reports do
        list[i] = serialize(reports[i])
    end

    return {
        staff = staff,
        name = name,
        duty = GlobalState.reportDuty or {},
        categories = config.categories,
        priorities = config.priorities,
        reports = list,
        resolvedLimit = RESOLVED_LIMIT,
    }
end)

lib.callback.register('sm_report:mine', function(src)
    local player = ply(src)
    if not player then return {} end

    local rows = MySQL.query.await('SELECT * FROM sm_report_reports WHERE citizenid = ? ORDER BY created DESC LIMIT ?', {
        player.PlayerData.citizenid, HISTORY_LIMIT
    }) or {}

    local list = {}
    for i = 1, #rows do
        list[i] = serialize(rows[i])
    end

    return list
end)

lib.callback.register('sm_report:list', function(src)
    local player = ply(src)
    if not isStaff(player) then return {} end

    local rows = MySQL.query.await("SELECT * FROM sm_report_reports WHERE status <> 'resolved' ORDER BY priority DESC, created ASC LIMIT 60") or {}

    local list = {}
    for i = 1, #rows do
        list[i] = serialize(rows[i])
    end

    return list
end)

lib.callback.register('sm_report:create', function(src, data)
    local player = ply(src)
    if not player or type(data) ~= 'table' then return false, 'Data laporan tidak valid.' end

    local now = os.time()
    if cooldowns[src] and now - cooldowns[src] < COOLDOWN then
        return false, ('Tunggu %d detik lagi.'):format(COOLDOWN - (now - cooldowns[src]))
    end

    local category = type(data.category) == 'string' and data.category or ''
    if not CATEGORIES[category] then return false, 'Kategori tidak valid.' end

    local subject = type(data.subject) == 'string' and data.subject:gsub('^%s+', ''):sub(1, config.maxSubject or 20) or ''
    local description = type(data.description) == 'string' and data.description:sub(1, config.maxDescription or 2000) or ''

    if #subject < 3 then return false, 'Judul terlalu pendek.' end
    if #description < 5 then return false, 'Deskripsi terlalu pendek.' end

    local citizenid, name = identity(player)
    if activeCount(citizenid) >= MAX_ACTIVE then
        return false, ('Maksimal %d laporan aktif.'):format(MAX_ACTIVE)
    end

    local coords = GetEntityCoords(GetPlayerPed(src))

    local id = MySQL.insert.await('INSERT INTO sm_report_reports (citizenid, name, category, subject, description, priority, status, x, y, z, created, updated) VALUES (?, ?, ?, ?, ?, 1, ?, ?, ?, ?, ?, ?)', {
        citizenid, name, category, subject, description, 'open', coords.x, coords.y, coords.z, now, now
    })

    if not id then return false, 'Gagal menyimpan laporan.' end

    cooldowns[src] = now

    local row = fetchReport(id)
    local report = serialize(row)

    broadcastStaff('report', report, 'report')
    log(src, 'create', id, subject)

    return true, report
end)

lib.callback.register('sm_report:messages', function(src, id)
    local player = ply(src)
    local row = fetchReport(tonumber(id) or 0)
    if not player or not row then return false, 'Laporan tidak ditemukan.' end

    local staff = isStaff(player)
    if not staff and row.citizenid ~= player.PlayerData.citizenid then return false, 'Bukan laporan kamu.' end

    local rows = MySQL.query.await('SELECT * FROM sm_report_messages WHERE reportId = ? ORDER BY id ASC LIMIT ?', { row.id, MESSAGE_LIMIT }) or {}

    local list = {}
    for i = 1, #rows do
        local m = rows[i]
        list[i] = {
            id = m.id,
            name = m.name,
            staff = m.staff == 1,
            message = m.message,
            created = m.created,
            own = m.citizenid == player.PlayerData.citizenid,
        }
    end

    return true, { report = serialize(row), messages = list }
end)

lib.callback.register('sm_report:send', function(src, id, message)
    local player = ply(src)
    local row = fetchReport(tonumber(id) or 0)
    if not player or not row then return false, 'Laporan tidak ditemukan.' end

    if row.status == 'resolved' then return false, 'Laporan sudah selesai.' end

    local citizenid, name = identity(player)
    local staff = isStaff(player)

    if not staff and row.citizenid ~= citizenid then return false, 'Bukan laporan kamu.' end
    if staff and row.assigned and row.assigned ~= citizenid and not isStaff(player) then
        return false, 'Laporan sudah dipegang staf lain.'
    end

    local body = type(message) == 'string' and message:gsub('^%s+', ''):sub(1, config.maxMessage or 1000) or ''
    if body == '' then return false, 'Pesan kosong.' end

    local now = GetGameTimer()
    if messageCooldowns[src] and now - messageCooldowns[src] < MSG_INTERVAL then
        return false, 'Terlalu cepat.'
    end
    messageCooldowns[src] = now

    local msgId = MySQL.insert.await('INSERT INTO sm_report_messages (reportId, citizenid, name, staff, message, created) VALUES (?, ?, ?, ?, ?, ?)', {
        row.id, citizenid, name, staff and 1 or 0, body, os.time()
    })

    if not msgId then return false, 'Gagal mengirim pesan.' end

    MySQL.update('UPDATE sm_report_reports SET updated = ? WHERE id = ?', { os.time(), row.id })

    local payload = {
        id = msgId,
        reportId = row.id,
        name = name,
        staff = staff,
        message = body,
        created = os.time(),
    }

    local reporterSrc = onlineOf(row.citizenid)
    if reporterSrc then
        TriggerClientEvent('sm_report:client:push', reporterSrc, 'message', payload)
        TriggerClientEvent('sm_report:client:sound', reporterSrc, 'message')
    end

    local players = QBCore.Functions.GetQBPlayers()
    for otherSrc, other in pairs(players) do
        if otherSrc ~= src and isStaff(other) then
            TriggerClientEvent('sm_report:client:push', otherSrc, 'message', payload)
        end
    end

    return true, payload
end)

lib.callback.register('sm_report:claim', function(src, id)
    local player = ply(src)
    local row = fetchReport(tonumber(id) or 0)
    if not player or not row then return false, 'Laporan tidak ditemukan.' end
    if not isStaff(player) then return false, 'Hanya staf.' end
    if row.status == 'resolved' then return false, 'Laporan sudah selesai.' end
    if row.assigned then return false, 'Sudah diklaim.' end

    local citizenid, name = identity(player)

    MySQL.update('UPDATE sm_report_reports SET status = ?, assigned = ?, assignedName = ?, updated = ? WHERE id = ? AND assigned IS NULL', {
        'claimed', citizenid, name, os.time(), row.id
    })

    log(src, 'claim', row.id, name)

    local updated = fetchReport(row.id)
    local report = serialize(updated)
    broadcastStaff('report', report)

    local reporterSrc = onlineOf(row.citizenid)
    if reporterSrc then
        TriggerClientEvent('sm_report:client:push', reporterSrc, 'report', report)
    end

    return true, report
end)

lib.callback.register('sm_report:unclaim', function(src, id)
    local player = ply(src)
    local row = fetchReport(tonumber(id) or 0)
    if not player or not row then return false, 'Laporan tidak ditemukan.' end
    if not isStaff(player) then return false, 'Hanya staf.' end

    local citizenid = player.PlayerData.citizenid
    if row.assigned and row.assigned ~= citizenid and not QBCore.Functions.HasPermission(src, 'admin') then
        return false, 'Laporan dipegang staf lain.'
    end

    MySQL.update('UPDATE sm_report_reports SET status = ?, assigned = NULL, assignedName = NULL, updated = ? WHERE id = ?', {
        'open', os.time(), row.id
    })

    log(src, 'unclaim', row.id)

    local updated = fetchReport(row.id)
    local report = serialize(updated)
    broadcastStaff('report', report)

    local reporterSrc = onlineOf(row.citizenid)
    if reporterSrc then
        TriggerClientEvent('sm_report:client:push', reporterSrc, 'report', report)
    end

    return true, report
end)

lib.callback.register('sm_report:resolve', function(src, id, note)
    local player = ply(src)
    local row = fetchReport(tonumber(id) or 0)
    if not player or not row then return false, 'Laporan tidak ditemukan.' end
    if not isStaff(player) then return false, 'Hanya staf.' end
    if row.status == 'resolved' then return false, 'Sudah selesai.' end

    local citizenid, name = identity(player)
    local body = type(note) == 'string' and note:sub(1, 1000) or ''

    MySQL.update('UPDATE sm_report_reports SET status = ?, resolved = ?, resolvedBy = ?, resolvedName = ?, updated = ? WHERE id = ?', {
        'resolved', os.time(), citizenid, name, os.time(), row.id
    })

    if body ~= '' then
        MySQL.insert('INSERT INTO sm_report_messages (reportId, citizenid, name, staff, message, created) VALUES (?, ?, ?, 1, ?, ?)', {
            row.id, citizenid, name, body, os.time()
        })
    end

    log(src, 'resolve', row.id, body)

    local updated = fetchReport(row.id)
    local report = serialize(updated)
    broadcastStaff('report', report)

    local reporterSrc = onlineOf(row.citizenid)
    if reporterSrc then
        TriggerClientEvent('sm_report:client:push', reporterSrc, 'report', report)
        notify(reporterSrc, 'Laporan kamu sudah diselesaikan. Beri rating kalau mau.', 'success')
    end

    return true, report
end)

lib.callback.register('sm_report:delete', function(src, id)
    local player = ply(src)
    local row = fetchReport(tonumber(id) or 0)
    if not player or not row then return false, 'Laporan tidak ditemukan.' end

    local staff = isStaff(player)
    if not staff and row.citizenid ~= player.PlayerData.citizenid then return false, 'Bukan laporan kamu.' end
    if not staff and row.status ~= 'open' then return false, 'Laporan sudah diproses.' end

    MySQL.update('DELETE FROM sm_report_reports WHERE id = ?', { row.id })
    MySQL.update('DELETE FROM sm_report_messages WHERE reportId = ?', { row.id })

    log(src, 'delete', row.id, row.subject)
    broadcastStaff('removed', { id = row.id })

    return true
end)

lib.callback.register('sm_report:priority', function(src, id, level)
    local player = ply(src)
    local row = fetchReport(tonumber(id) or 0)
    if not player or not row then return false, 'Laporan tidak ditemukan.' end
    if not isStaff(player) then return false, 'Hanya staf.' end

    local value = math.floor(tonumber(level) or 0)
    if value < 0 or value > PRIORITY_MAX then return false, 'Prioritas tidak valid.' end

    MySQL.update('UPDATE sm_report_reports SET priority = ?, updated = ? WHERE id = ?', { value, os.time(), row.id })
    log(src, 'priority', row.id, tostring(value))

    local updated = fetchReport(row.id)
    local report = serialize(updated)
    broadcastStaff('report', report)

    return true, report
end)

lib.callback.register('sm_report:action', function(src, id, action)
    local player = ply(src)
    local row = fetchReport(tonumber(id) or 0)
    if not player or not row then return false, 'Laporan tidak ditemukan.' end
    if not isStaff(player) then return false, 'Hanya staf.' end

    if action == 'teleport' then
        if not row.x or not row.y or not row.z then return false, 'Lokasi tidak tersimpan.' end
        TriggerClientEvent('sm_report:client:teleport', src, row.x, row.y, row.z)
        return true
    end

    if action == 'spectate' then
        local reporterSrc = onlineOf(row.citizenid)
        if not reporterSrc then return false, 'Pelapor sedang offline.' end
        if spectating[src] then return false, 'Sedang spectate.' end

        spectating[src] = reporterSrc
        local coords = GetEntityCoords(GetPlayerPed(reporterSrc))
        TriggerClientEvent('sm_report:client:spectate', src, reporterSrc, coords.x, coords.y, coords.z)
        return true
    end

    return false, 'Aksi tidak dikenal.'
end)

lib.callback.register('sm_report:spectateEnd', function(src)
    spectating[src] = nil
    return true
end)

lib.callback.register('sm_report:history', function(src)
    local player = ply(src)
    if not isStaff(player) then return {} end

    local rows = MySQL.query.await("SELECT * FROM sm_report_reports WHERE status = 'resolved' ORDER BY resolved DESC LIMIT ?", { RESOLVED_LIMIT }) or {}

    local list = {}
    for i = 1, #rows do
        list[i] = serialize(rows[i])
    end

    return list
end)

lib.callback.register('sm_report:logs', function(src)
    local player = ply(src)
    if not isStaff(player) then return {} end

    return MySQL.query.await('SELECT * FROM sm_report_logs ORDER BY id DESC LIMIT 120') or {}
end)

lib.callback.register('sm_report:clearResolved', function(src)
    local player = ply(src)
    if not player then return false end
    if not QBCore.Functions.HasPermission(src, 'admin') then return false, 'Hanya admin.' end

    local rows = MySQL.query.await("SELECT id FROM sm_report_reports WHERE status = 'resolved'") or {}
    if #rows == 0 then return false, 'Tidak ada laporan selesai.' end

    for i = 1, #rows do
        MySQL.update('DELETE FROM sm_report_messages WHERE reportId = ?', { rows[i].id })
    end

    MySQL.update("DELETE FROM sm_report_reports WHERE status = 'resolved'")
    log(src, 'clearResolved', nil, tostring(#rows))

    return true, #rows
end)

lib.callback.register('sm_report:setDuty', function(src, value)
    local player = ply(src)
    if not player then return false end
    if not isStaff(player) then return false, 'Bukan staf.' end

    local citizenid, name = identity(player)
    dutySet(citizenid, name, value == true)

    return true, GlobalState.reportDuty or {}
end)

lib.callback.register('sm_report:rate', function(src, id, stars, feedback)
    local player = ply(src)
    local row = fetchReport(tonumber(id) or 0)
    if not player or not row then return false, 'Laporan tidak ditemukan.' end
    if row.citizenid ~= player.PlayerData.citizenid then return false, 'Bukan laporan kamu.' end
    if row.status ~= 'resolved' then return false, 'Belum selesai.' end
    if row.rating then return false, 'Sudah dinilai.' end

    local value = math.floor(tonumber(stars) or 0)
    if value < 1 or value > 5 then return false, 'Rating 1 sampai 5.' end

    local body = type(feedback) == 'string' and feedback:sub(1, 500) or ''

    MySQL.update('UPDATE sm_report_reports SET rating = ?, feedback = ? WHERE id = ?', { value, body, row.id })
    log(src, 'rate', row.id, tostring(value))

    return true
end)

lib.callback.register('sm_report:leaderboard', function(src)
    local player = ply(src)
    if not isStaff(player) then return {} end

    local rows = MySQL.query.await("SELECT resolvedBy, resolvedName, COUNT(*) AS total, AVG(rating) AS avgRating FROM sm_report_reports WHERE status = 'resolved' AND resolvedBy IS NOT NULL GROUP BY resolvedBy, resolvedName ORDER BY total DESC LIMIT 10") or {}

    local list = {}
    for i = 1, #rows do
        list[i] = {
            name = rows[i].resolvedName or rows[i].resolvedBy,
            total = tonumber(rows[i].total) or 0,
            rating = tonumber(rows[i].avgRating) or 0,
        }
    end

    return list
end)

AddEventHandler('playerDropped', function()
    cooldowns[source] = nil
    messageCooldowns[source] = nil
    spectating[source] = nil

    local player = ply(source)
    if not player then return end

    local citizenid = player.PlayerData.citizenid

    local row = MySQL.single.await('SELECT onDuty FROM sm_report_duty WHERE citizenid = ?', { citizenid })
    if row and row.onDuty == 1 then
        dutySet(citizenid, ('%s %s'):format(player.PlayerData.charinfo.firstname, player.PlayerData.charinfo.lastname), false)
    end

    local claims = MySQL.query.await("SELECT id FROM sm_report_reports WHERE assigned = ? AND status = 'claimed'", { citizenid }) or {}
    if #claims == 0 then return end

    MySQL.update("UPDATE sm_report_reports SET status = 'open', assigned = NULL, assignedName = NULL WHERE assigned = ? AND status = 'claimed'", { citizenid })

    local list = MySQL.query.await("SELECT * FROM sm_report_reports WHERE status = 'open'") or {}
    for i = 1, #list do
        broadcastStaff('report', serialize(list[i]))
    end
end)