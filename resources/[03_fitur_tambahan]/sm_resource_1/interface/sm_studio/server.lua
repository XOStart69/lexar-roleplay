--[[
    sm_studio :: server
    Otoritas: job/grade, jarak, kunci komputer, kunci mic, kuota, cooldown, throttle ekspor.
    Satu studio = satu pemegang komputer, satu pemegang mic, satu rekaman.
]]

local config = localmodule 'config'

local Studios = config.Studios or {}
local Labels = config.Labels or {}
local MIC = config.microphone or {}
local COMPUTER = config.computer or {}

local MAX_FILES = config.MaxFiles or 200
local MAX_SONGS = config.MaxSongs or 50
local MAX_TRACKS = config.MaxTracks or 16
local MAX_RECORD = config.MaxRecordSeconds or 300
local MAX_IMPORT = config.MaxImportSeconds or 600
local UPLOAD_COOLDOWN = (config.UploadCooldown or 3) * 1000
local IMPORT_COOLDOWN = (config.ImportCooldown or 15) * 1000
local CHUNK_RATE = config.ExportBytesPerSecond or 1048576
local CHUNK_SIZE = 65536
local UPLOAD_BASE = GetConvar('sm_studio_upload_base', '')

local FILES = 'sm_studio_files'
local SONGS = 'sm_studio_songs'

local rooms = {}
local cooldown = {}

local function room(key)
    rooms[key] = rooms[key] or { occupants = {}, mirror = false, mirrorFiles = {} }
    return rooms[key]
end

local function label(key)
    return Labels[key] or key
end

local function notify(src, key, kind)
    TriggerClientEvent('ox_lib:notify', src, { title = 'Studio', description = label(key), type = kind or 'error' })
end

local function playerOf(src)
    return qb_ecore:GetPlayer(src)
end

local function broadcast(key, event, ...)
    local r = rooms[key]
    if not r then return end
    for src in pairs(r.occupants) do
        TriggerClientEvent(event, src, ...)
    end
end

local function authorized(player, studio)
    if not player then return false end
    if studio.forall then return true end

    local jobs = studio.jobs or {}
    local need = jobs[player.PlayerData.job.name]
    if not need then return false end

    return (player.PlayerData.job.grade.level or 0) >= need
end

local function near(src, coords, radius)
    local ped = GetPlayerPed(src)
    if ped == 0 then return false end
    return #(GetEntityCoords(ped) - coords) <= radius
end

local function holder(r, src)
    return r.computer == src
end

local function cooled(src, kind, ms)
    local key = src .. ':' .. kind
    local stamp = GetGameTimer()
    if cooldown[key] and stamp - cooldown[key] < ms then return false end
    cooldown[key] = stamp
    return true
end

local function filesOf(key)
    return MySQL.query.await('SELECT * FROM ' .. FILES .. ' WHERE studio = ? ORDER BY id DESC', { key }) or {}
end

local function songsOf(key)
    return MySQL.query.await('SELECT * FROM ' .. SONGS .. ' WHERE studio = ? ORDER BY id DESC', { key }) or {}
end

local function pushMirror(key, state, files)
    local r = room(key)
    r.mirror = state == true
    r.mirrorFiles = files or {}
    broadcast(key, 'sm_studio:mirror', r.mirror, r.mirrorFiles)
end

local function releaseComputer(key, src)
    local r = room(key)
    if r.computer ~= src then return end
    r.computer = nil
    if r.mirror then pushMirror(key, false, {}) end
end

local function releaseMic(key, src)
    local r = room(key)
    if r.mic ~= src then return end
    r.mic = nil
    r.recording = nil
    broadcast(key, 'sm_studio:mic', false, false)
end

lib.callback.register('sm_studio:room:enter', function(src, key)
    local studio = Studios[key]
    if not studio then return nil end

    local player = playerOf(src)
    if not authorized(player, studio) then return nil end
    if not near(src, studio.computer.coords, studio.EnterRange or 60.0) then return nil end

    local r = room(key)
    r.occupants[src] = true

    return {
        label = studio.label,
        speaker = r.speaker or false,
        mirror = r.mirror and r.mirrorFiles or false,
    }
end)

RegisterNetEvent('sm_studio:room:leave', function()
    local src = source

    for key, r in pairs(rooms) do
        if r.occupants[src] then
            releaseComputer(key, src)
            releaseMic(key, src)
            r.occupants[src] = nil
            return
        end
    end
end)

lib.callback.register('sm_studio:computer:open', function(src, key)
    local studio = Studios[key]
    if not studio then return { status = false, message = label('went_wrong') } end

    local player = playerOf(src)
    if not authorized(player, studio) then return { status = false, message = label('no_access') } end
    if not near(src, studio.computer.coords, COMPUTER.radius or 1.5) then
        return { status = false, message = label('too_far') }
    end

    local r = room(key)
    if r.computer and r.computer ~= src then
        local other = playerOf(r.computer)
        local name = other and other.PlayerData.charinfo.firstname or '?'
        return { status = false, message = ('Komputer dipakai %s.'):format(name) }
    end

    r.computer = src

    return {
        status = true,
        files = filesOf(key),
        songs = songsOf(key),
        mirror = r.mirror,
        mirrorFiles = r.mirrorFiles,
        maxFiles = MAX_FILES,
        maxSongs = MAX_SONGS,
        maxTracks = MAX_TRACKS,
        maxRecordSeconds = MAX_RECORD,
        maxImportSeconds = MAX_IMPORT,
    }
end)

RegisterNetEvent('sm_studio:computer:release', function()
    local src = source
    for key in pairs(rooms) do releaseComputer(key, src) end
end)

lib.callback.register('sm_studio:mic:take', function(src, key)
    local studio = Studios[key]
    if not studio then return false end

    local player = playerOf(src)
    if not authorized(player, studio) then return false end
    if not near(src, studio.microphone.coords, MIC.radius or 0.5) then return false end

    local r = room(key)
    if r.mic and r.mic ~= src then return false end

    r.mic = src
    broadcast(key, 'sm_studio:mic', true, r.recording ~= nil)

    return true
end)

lib.callback.register('sm_studio:mic:leave', function(src, key)
    local r = rooms[key]
    if not r or r.mic ~= src then return false end

    releaseMic(key, src)
    return true
end)

RegisterNetEvent('sm_studio:mirror:set', function(data)
    local src = source

    for key, r in pairs(rooms) do
        if r.computer == src then
            pushMirror(key, type(data) == 'table' and data.state or false, type(data) == 'table' and data.files or {})
            return
        end
    end
end)

RegisterNetEvent('sm_studio:speaker:set', function(data)
    local src = source
    if type(data) ~= 'table' then return end

    for key, r in pairs(rooms) do
        if r.computer == src then
            r.speaker = data
            broadcast(key, 'sm_studio:speaker', src, data)
            return
        end
    end
end)

RegisterNetEvent('sm_studio:speaker:stop', function()
    local src = source

    for key, r in pairs(rooms) do
        if r.computer == src then
            r.speaker = nil
            broadcast(key, 'sm_studio:speaker', src, false)
            return
        end
    end
end)

lib.callback.register('sm_studio:upload:url', function(src, key)
    if UPLOAD_BASE == '' then return false end
    if not cooled(src, 'upload', UPLOAD_COOLDOWN) then return false end
    if not rooms[key] or rooms[key].computer ~= src then return false end

    return ('%s/upload/%s-%d'):format(UPLOAD_BASE:gsub('/$', ''), src, os.time())
end)

lib.callback.register('sm_studio:file:save', function(src, key, data)
    if not rooms[key] or rooms[key].computer ~= src then return false end
    if type(data) ~= 'table' then return false end

    local total = MySQL.scalar.await('SELECT COUNT(*) FROM ' .. FILES .. ' WHERE studio = ?', { key }) or 0
    if total >= MAX_FILES then return false end

    local tracks = type(data.tracks) == 'table' and data.tracks or {}
    if #tracks > MAX_TRACKS then return false end

    local kind = tostring(data.kind or 'file')
    local duration = math.floor(tonumber(data.duration) or 0)
    if kind == 'import' and duration > MAX_IMPORT then return false end

    local player = playerOf(src)
    local id = MySQL.insert.await(
        ('INSERT INTO %s (studio, kind, name, url, size, duration, tracks, owner, created) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)'):format(FILES),
        {
            key, kind, tostring(data.name or 'Tanpa Nama'):sub(1, 120),
            tostring(data.url or ''), math.floor(tonumber(data.size) or 0), duration,
            json.encode(tracks), player and player.PlayerData.citizenid or nil, os.time(),
        }
    )

    if not id then return false end

    local file = {
        id = id, studio = key, kind = kind, name = data.name, url = data.url,
        size = data.size, duration = duration, tracks = tracks, offset = total + 1,
    }

    broadcast(key, 'sm_studio:file:added', file, file.offset, true)

    return file
end)

lib.callback.register('sm_studio:file:rename', function(src, key, id, name)
    if not rooms[key] or rooms[key].computer ~= src then return false end
    name = tostring(name or ''):sub(1, 120)
    if name == '' then return false end

    MySQL.update('UPDATE ' .. FILES .. ' SET name = ? WHERE id = ? AND studio = ?', { name, tonumber(id), key })
    return true
end)

lib.callback.register('sm_studio:file:delete', function(src, key, id)
    if not rooms[key] or rooms[key].computer ~= src then return false end

    MySQL.update('DELETE FROM ' .. FILES .. ' WHERE id = ? AND studio = ?', { tonumber(id), key })
    return true
end)

lib.callback.register('sm_studio:song:save', function(src, key, data)
    if not rooms[key] or rooms[key].computer ~= src then return false end
    if type(data) ~= 'table' then return false end

    local total = MySQL.scalar.await('SELECT COUNT(*) FROM ' .. SONGS .. ' WHERE studio = ?', { key }) or 0
    if total >= MAX_SONGS then return false end

    local tracks = type(data.tracks) == 'table' and data.tracks or {}
    if #tracks > MAX_TRACKS then return false end

    local player = playerOf(src)
    local id = MySQL.insert.await(
        ('INSERT INTO %s (studio, name, kind, tracks, owner, created) VALUES (?, ?, ?, ?, ?, ?)'):format(SONGS),
        {
            key, tostring(data.name or 'Tanpa Nama'):sub(1, 120), tostring(data.kind or 'song'),
            json.encode(tracks), player and player.PlayerData.citizenid or nil, os.time(),
        }
    )

    if not id then return false end

    return { id = id, studio = key, name = data.name, kind = data.kind, tracks = tracks }
end)

lib.callback.register('sm_studio:song:delete', function(src, key, id)
    if not rooms[key] or rooms[key].computer ~= src then return false end
    MySQL.update('DELETE FROM ' .. SONGS .. ' WHERE id = ? AND studio = ?', { tonumber(id), key })
    return true
end)

lib.callback.register('sm_studio:record:start', function(src, key, position)
    local r = rooms[key]
    if not r or r.mic ~= src then return { status = false, message = label('microphone_busy') } end
    if r.recording then return { status = false, message = label('record_running') } end

    local offset = math.max(math.floor(tonumber(position) or 0), 0)
    r.recording = { src = src, started = os.time() }

    broadcast(key, 'sm_studio:record:start', offset, MAX_RECORD)
    broadcast(key, 'sm_studio:mic', true, true)

    return { status = true, message = label('record_started') }
end)

lib.callback.register('sm_studio:record:stop', function(src, key, save)
    local r = rooms[key]
    if not r or r.mic ~= src or not r.recording then
        return { status = false, message = label('went_wrong') }
    end

    r.recording = nil
    broadcast(key, 'sm_studio:record:stop', save == true)
    broadcast(key, 'sm_studio:mic', true, false)

    return { status = true, message = label('record_stopped') }
end)

RegisterNetEvent('sm_studio:record:ended', function()
    local src = source
    for key, r in pairs(rooms) do
        if r.mic == src and r.recording then
            r.recording = nil
            broadcast(key, 'sm_studio:record:stop', true)
            broadcast(key, 'sm_studio:mic', true, false)
            return
        end
    end
end)

lib.callback.register('sm_studio:export:file', function(src, key, fileId)
    local r = rooms[key]
    if not r or r.computer ~= src then return { error = label('went_wrong') } end

    local file = MySQL.single.await('SELECT * FROM ' .. FILES .. ' WHERE id = ? AND studio = ?', { tonumber(fileId), key })
    if not file then return { error = label('file_missing') } end

    local blob = file.data
    if not blob or #blob == 0 then return { error = label('file_missing') } end

    local req = ('%s-%d-%d'):format(src, file.id, os.time())
    local total = math.ceil(#blob / CHUNK_SIZE)

    r.export = { req = req, blob = blob, index = 1, total = total, src = src, stamp = GetGameTimer() }

    TriggerClientEvent('sm_studio:export:chunk', src, req, 1, total, blob:sub(1, CHUNK_SIZE))
    if total == 1 then return { status = true } end

    return { status = true, req = req }
end)

RegisterNetEvent('sm_studio:export:next', function(req, index)
    local src = source

    for key, r in pairs(rooms) do
        local job = r.export
        if job and job.req == req and job.src == src then
            local nextIndex = (tonumber(index) or job.index) + 1
            if nextIndex > job.total then return end

            job.index = nextIndex
            job.stamp = GetGameTimer()

            local part = job.blob:sub((nextIndex - 1) * CHUNK_SIZE + 1, nextIndex * CHUNK_SIZE)

            SetTimeout(math.max(math.floor(CHUNK_SIZE / CHUNK_RATE * 1000), 1), function()
                local current = rooms[key] and rooms[key].export
                if current and current.req == req then
                    TriggerClientEvent('sm_studio:export:chunk', src, req, nextIndex, job.total, part)
                end
            end)

            return
        end
    end
end)

RegisterNetEvent('sm_studio:export:ack', function(req)
    local src = source

    for _, r in pairs(rooms) do
        if r.export and r.export.req == req and r.export.src == src then
            r.export = nil
            return
        end
    end
end)

lib.callback.register('sm_studio:youtube', function(src, key, url)
    local r = rooms[key]
    if not r or r.computer ~= src then return { error = label('went_wrong') } end
    if not cooled(src, 'import', IMPORT_COOLDOWN) then return { error = label('import_wait') } end

    url = tostring(url or '')
    if not url:match('^https://[%w%-%._]+') then return { error = label('bad_url') } end
    if not url:find('youtu%.be') and not url:find('youtube%.com') then
        return { error = label('bad_url') }
    end

    return { status = true, url = url }
end)

CreateThread(function()
    MySQL.query.await([[
    CREATE TABLE IF NOT EXISTS `sm_studio_files` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `studio` varchar(48) NOT NULL,
        `kind` varchar(24) NOT NULL,
        `name` varchar(128) NOT NULL,
        `url` varchar(512) DEFAULT NULL,
        `size` int(11) NOT NULL DEFAULT 0,
        `duration` int(11) NOT NULL DEFAULT 0,
        `tracks` longtext DEFAULT NULL,
        `data` longblob DEFAULT NULL,
        `owner` varchar(64) DEFAULT NULL,
        `created` int(11) NOT NULL,
        PRIMARY KEY (`id`),
        KEY `studio` (`studio`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    MySQL.query.await([[
    CREATE TABLE IF NOT EXISTS `sm_studio_songs` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `studio` varchar(48) NOT NULL,
        `name` varchar(128) NOT NULL,
        `kind` varchar(24) NOT NULL,
        `tracks` longtext DEFAULT NULL,
        `owner` varchar(64) DEFAULT NULL,
        `created` int(11) NOT NULL,
        PRIMARY KEY (`id`),
        KEY `studio` (`studio`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
end)

CreateThread(function()
    while true do
        Wait(15000)
        local stamp = GetGameTimer()

        for _, r in pairs(rooms) do
            if r.export and stamp - r.export.stamp > 30000 then
                r.export = nil
            end
        end
    end
end)

AddEventHandler('playerDropped', function()
    local src = source

    for key, r in pairs(rooms) do
        releaseComputer(key, src)
        releaseMic(key, src)
        r.occupants[src] = nil
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    rooms = {}
end)

print('^2[sm_studio] server siap^7')