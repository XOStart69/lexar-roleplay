local config = require 'shared.config'
local db = require 'server.database'

local QBCore = exports['qb-core']:GetCoreObject()

local lobbySeq = 0
local lobbies = {}
local inRace = {}
local tablets = {}

local function notify(source, message, kind)
    TriggerClientEvent('sm_pdtablet:client:notify', source, message, kind)
end

local function player(source)
    return QBCore.Functions.GetPlayer(source)
end

local function officer(source, needGrade)
    local Player = player(source)

    if not Player then return false end

    local job = Player.PlayerData.job

    if not job or not config.Job.allowed[job.name] then return false end
    if config.Job.requireDuty and not job.onduty then return false end
    if needGrade and (job.grade.level or 0) < config.Job.createGrade then return false end

    return true
end

local function citizenId(source)
    local Player = player(source)

    return Player and Player.PlayerData.citizenid or nil
end

local function lobbyData(race)
    local racers = {}

    for i = 1, #race.racers do
        local src = race.racers[i]

        racers[#racers + 1] = { id = src, name = GetPlayerName(tostring(src)) }
    end

    return {
        id = race.id,
        trackId = race.trackId,
        trackName = race.trackName,
        trackType = race.trackType,
        host = race.host,
        hostName = GetPlayerName(tostring(race.host)),
        laps = race.laps,
        ghosting = race.ghosting,
        started = race.started,
        racers = racers,
    }
end

local function lobbyList()
    local list = {}

    for _, race in pairs(lobbies) do
        list[#list + 1] = lobbyData(race)
    end

    table.sort(list, function(a, b) return a.id < b.id end)

    return list
end

local function pushLobbies()
    local data = lobbyList()

    for source in pairs(tablets) do
        TriggerClientEvent('sm_pdtablet:client:updateLobbies', source, data)
    end
end

local function pushRacers(race)
    local list = {}

    for i = 1, #race.racers do
        list[#list + 1] = { id = race.racers[i], name = GetPlayerName(tostring(race.racers[i])) }
    end

    for i = 1, #race.racers do
        TriggerClientEvent('sm_pdtablet:client:updateRacers', race.racers[i], race.id, list)
    end
end

local function dropFromRace(source, quiet)
    local race = lobbies[inRace[source]]

    inRace[source] = nil

    if not race then return end

    for i = #race.racers, 1, -1 do
        if race.racers[i] == source then table.remove(race.racers, i) end
    end

    if not quiet and GetPlayerName(source) then
        TriggerClientEvent('sm_pdtablet:client:leaveRace', source)
    end

    if #race.racers == 0 then
        lobbies[race.id] = nil
    else
        if race.host == source then
            race.host = race.racers[1]

            for i = 1, #race.racers do
                notify(race.racers[i], 'Host left, you are now the host.', 'inform')
            end

            for i = 1, #race.racers do
                TriggerClientEvent('sm_pdtablet:client:updateSession', race.racers[i], lobbyData(race))
            end
        end

        pushRacers(race)
    end

    pushLobbies()
end

local function checkpointsOf(race)
    local track = db.getTrack(race.trackId)

    if not track then return {} end

    return json.decode(track.checkpoints) or {}
end

lib.callback.register('sm_pdtablet:server:getBaseData', function(source)
    if not officer(source) then return nil end

    local cid = citizenId(source)

    if not cid then return nil end

    local division = db.getDivision(cid) or config.Divisions.order[1]

    if not config.Divisions[division] then
        division = config.Divisions.order[1]
    end

    local divisions = { order = config.Divisions.order }

    for key, entry in pairs(config.Divisions) do
        if type(entry) == 'table' then
            divisions[key] = {
                label = entry.label,
                short = entry.short,
                description = entry.description,
                logo = entry.logo,
                trackType = entry.trackType,
            }
        end
    end

    return {
        division = division,
        divisions = divisions,
        tracks = db.listTracks(cid),
        history = db.getHistory(cid, config.Race.historyLimit),
        lobbies = lobbyList(),
        session = inRace[source] and lobbies[inRace[source]] and lobbyData(lobbies[inRace[source]]) or nil,
    }
end)

lib.callback.register('sm_pdtablet:server:getHistory', function(source)
    local cid = citizenId(source)

    if not cid then return {} end

    return db.getHistory(cid, config.Race.historyLimit) or {}
end)

lib.callback.register('sm_pdtablet:server:canCreateTrack', function(source, name)
    if not officer(source, true) then return false, ('Only grade %d+ can create tracks.'):format(config.Job.createGrade) end

    if type(name) ~= 'string' then return false, 'Track name is required.' end

    name = name:gsub('^%s+', ''):gsub('%s+$', '')

    if #name < config.Track.minNameLength or #name > config.Track.maxNameLength then
        return false, ('Name must be %d-%d characters.'):format(config.Track.minNameLength, config.Track.maxNameLength)
    end

    local cid = citizenId(source)

    if not cid then return false, 'No character loaded.' end

    if db.countTracks(cid) >= config.Track.maxPerOfficer then
        return false, ('Track limit reached (%d).'):format(config.Track.maxPerOfficer)
    end

    local division = db.getDivision(cid) or config.Divisions.order[1]

    return true, name, (config.Divisions[division] or {}).trackType or 'ground'
end)

lib.callback.register('sm_pdtablet:server:getTrackForEdit', function(source, trackId)
    if not officer(source, true) then return nil end

    local track = db.getTrack(tonumber(trackId) or 0)

    if not track then return nil end
    if track.citizenid ~= citizenId(source) then return nil end

    return {
        name = track.name,
        trackId = track.id,
        trackType = track.track_type,
        checkpoints = json.decode(track.checkpoints) or {},
    }
end)

lib.callback.register('sm_pdtablet:server:setDivision', function(source, division)
    if not officer(source) then return false end
    if not config.Divisions[division] then return false end

    local cid = citizenId(source)

    if not cid then return false end

    db.setDivision(cid, division)

    return true
end)

lib.callback.register('sm_pdtablet:server:getLeaderboard', function(source, trackId)
    if not officer(source) then return {} end

    return db.getLeaderboard(tonumber(trackId) or 0, config.Race.leaderboardLimit) or {}
end)

lib.callback.register('sm_pdtablet:server:hostRace', function(source, data)
    if not officer(source) then return false, 'Police only.' end
    if type(data) ~= 'table' then return false, 'Invalid data.' end

    local trackId = tonumber(data.trackId or data.TrackId)

    if not trackId then return false, 'Pick a track first.' end

    local track = db.getTrack(trackId)

    if not track then return false, 'Track not found.' end

    local laps = math.floor(tonumber(data.laps) or 1)

    if laps < 1 then laps = 1 end
    if laps > 50 then laps = 50 end

    lobbySeq += 1

    local race = {
        id = lobbySeq,
        trackId = trackId,
        trackName = track.name,
        trackType = track.track_type,
        host = source,
        laps = laps,
        ghosting = tonumber(data.ghosting) or config.Ghosting.default,
        started = false,
        racers = {},
    }

    lobbies[race.id] = race

    pushLobbies()

    return true, race.id
end)

lib.callback.register('sm_pdtablet:server:joinRace', function(source, raceId)
    if not officer(source) then return false, 'Police only.' end

    raceId = tonumber(raceId)

    local race = raceId and lobbies[raceId]

    if not race then return false, 'Session is gone.' end
    if race.started then return false, 'Session already started.' end
    if inRace[source] then return false, 'Leave your current session first.' end
    if #race.racers >= config.Race.maxRacers then return false, 'Session is full.' end

    race.racers[#race.racers + 1] = source
    inRace[source] = race.id

    TriggerClientEvent('sm_pdtablet:client:joinRace', source, {
        RaceId = race.id,
        TrackName = race.trackName,
        IsHost = race.host == source,
        Laps = race.laps,
        Ghosting = race.ghosting,
        TrackType = race.trackType,
    }, checkpointsOf(race))

    pushRacers(race)
    pushLobbies()

    return true, 'Joined'
end)

RegisterNetEvent('sm_pdtablet:server:saveTrack', function(payload)
    local source = source

    if not officer(source, true) then return notify(source, 'Not allowed.', 'error') end
    if type(payload) ~= 'table' or type(payload.Checkpoints) ~= 'table' then return end

    local name = tostring(payload.Name or ''):gsub('^%s+', ''):gsub('%s+$', '')
    local points = payload.Checkpoints

    if #points < config.Track.minCheckpoints then
        return notify(source, ('Minimum %d checkpoints.'):format(config.Track.minCheckpoints), 'error')
    end

    local cid = citizenId(source)

    if not cid then return end

    local encoded = json.encode(points)
    local trackId = tonumber(payload.TrackId)

    if trackId then
        local track = db.getTrack(trackId)

        if not track or track.citizenid ~= cid then return notify(source, 'Track not yours.', 'error') end

        db.updateTrack(trackId, name, encoded)
        notify(source, 'Track updated.', 'success')

        return
    end

    local division = db.getDivision(cid) or config.Divisions.order[1]
    local trackType = (config.Divisions[division] or {}).trackType or 'ground'

    db.insertTrack(cid, name, trackType, encoded)
    notify(source, 'Track saved.', 'success')
end)

RegisterNetEvent('sm_pdtablet:server:deleteTrack', function(trackId)
    local source = source

    if not officer(source) then return end

    trackId = tonumber(trackId)

    local track = trackId and db.getTrack(trackId)

    if not track then return end

    local Player = player(source)
    local grade = Player and Player.PlayerData.job.grade.level or 0

    if track.citizenid ~= citizenId(source) and grade < config.Job.createGrade then
        return notify(source, 'Not your track.', 'error')
    end

    db.deleteTrack(trackId)

    notify(source, 'Track deleted.', 'success')
end)

RegisterNetEvent('sm_pdtablet:server:startRace', function()
    local source = source
    local race = lobbies[inRace[source]]

    if not race or race.host ~= source or race.started then return end
    if #race.racers < 1 then return end

    race.started = true

    for i = 1, #race.racers do
        TriggerClientEvent('sm_pdtablet:client:startCountdown', race.racers[i])
    end

    pushLobbies()
end)

RegisterNetEvent('sm_pdtablet:server:updateRacer', function(index, lap, finished, elapsed)
    local source = source
    local race = lobbies[inRace[source]]

    if not race then return end

    if finished then
        local cid = citizenId(source)

        if cid then
            db.addHistory(race.trackId, cid, math.floor(tonumber(elapsed) or 0), math.floor(tonumber(lap) or 1), true)
        end

        local position = 1

        for i = 1, #race.racers do
            if race.racers[i] ~= source then position += 1 end
        end

        for i = 1, #race.racers do
            TriggerClientEvent('sm_pdtablet:client:racerFinished', race.racers[i], GetPlayerName(tostring(source)), position)
        end
    end
end)

RegisterNetEvent('sm_pdtablet:server:leaveRace', function()
    dropFromRace(source)
end)

RegisterNetEvent('sm_pdtablet:server:tabletClosed', function()
    tablets[source] = nil
end)

RegisterNetEvent('sm_pdtablet:server:use', function()
    local source = source

    if not officer(source) then return notify(source, 'Police only.', 'error') end

    tablets[source] = true
    TriggerClientEvent('sm_pdtablet:client:openTablet', source)
end)

exports('use', function(source)
    TriggerClientEvent('sm_pdtablet:client:openTablet', source)
    tablets[source] = true
end)

RegisterCommand('pdtablet', function(source)
    if source == 0 then return end

    TriggerClientEvent('sm_pdtablet:client:openTablet', source)
end, false)

AddEventHandler('playerDropped', function()
    local source = source

    tablets[source] = nil

    if inRace[source] then dropFromRace(source, true) end
end)

lib.print.info('sm_pdtablet server siap')
