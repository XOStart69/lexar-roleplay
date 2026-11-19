---@type table<number, table>
local races = {}
---@type table<number, number>
local ofSource = {}

local seq = 0

---@param src number
---@return string?
local function citizen(src)
    local citizenid = getCitizenId(src)
    if not citizenid then return end

    ensureRacer(citizenid, getPlayerName(src) or citizenid)

    return citizenid
end

---@param id number
---@return table?
local function raceOf(id)
    return races[id]
end

---@param race table
local function names(race)
    for _, src in ipairs(race.members) do
        TriggerClientEvent('sm_racingtablet:client:updateRacerNames', src)
    end
end

---@param race table
---@param citizenid string
---@param data table
local function racerData(race, citizenid, data)
    for _, src in ipairs(race.members) do
        TriggerClientEvent('sm_racingtablet:client:updateRaceRacerData', src, race.id, citizenid, data)
    end
end

---@param race table
---@return table
local function summary(race)
    return {
        RaceId = race.id,
        RaceName = race.name,
        TrackId = race.trackId,
        IsElimination = race.elimination,
        TotalLaps = race.laps,
        TotalRacers = #race.members,
        Racers = race.racers,
    }
end

cwCallback.register('sm_racingtablet:server:getRaces', function()
    local list = {}

    for _, race in pairs(races) do
        if not race.finished then list[#list + 1] = summary(race) end
    end

    return list
end)

RegisterNetEvent('sm_racingtablet:server:joinRace', function(raceId, racerName)
    local src = source
    local citizenid = citizen(src)
    if not citizenid then return end

    local race = raceOf(tonumber(raceId))
    if not race or race.started or race.finished then return end
    if ofSource[src] then return end

    local track = MySQL.single.await('SELECT * FROM racing_tracks WHERE id = ?', { race.trackId })
    if not track then return end

    local checkpoints = json.decode(track.checkpoints or '[]') or {}

    race.members[#race.members + 1] = src
    race.racers[citizenid] = { Racername = racerName or getPlayerName(src) }
    ofSource[src] = race.id

    TriggerClientEvent('sm_racingtablet:client:joinRace', src, summary(race), checkpoints, race.laps, racerName)

    racerData(race, citizenid, race.racers[citizenid])
    names(race)
end)

RegisterNetEvent('sm_racingtablet:server:leaveRace', function(_, state)
    local src = source
    local id = ofSource[src]

    ofSource[src] = nil
    clearBucket(src)

    local race = id and raceOf(id)
    if not race then return end

    local citizenid = getCitizenId(src)

    for i = #race.members, 1, -1 do
        if race.members[i] == src then table.remove(race.members, i) end
    end

    if citizenid then race.racers[citizenid] = nil end

    if #race.members == 0 then
        races[id] = nil
    else
        names(race)
    end

    DebugInfo(('pemain %s keluar dari balapan %d (%s)'):format(src, id, state or 'left'))
end)

RegisterNetEvent('sm_racingtablet:server:updateRaceState', function(raceId, started, finished)
    local race = raceOf(tonumber(raceId))
    if not race then return end

    if started then
        race.started = true

        for _, src in ipairs(race.members) do
            setBucket(src, race.id)
            TriggerClientEvent('sm_racingtablet:client:raceCountdown', src, #race.members)
        end
    end

    if finished then
        race.finished = true

        local position, first = 0, nil

        for citizenid, data in pairs(race.racers) do
            position = position + 1
            first = first or citizenid

            MySQL.update.await('INSERT INTO racing_results (race, track, citizenid, racername, position) VALUES (?, ?, ?, ?, ?)', { race.id, race.name, citizenid, data.Racername, position })

            if race.ranked and citizenid ~= first then
                applyElo(first, citizenid, true)
            end
        end

        local position, first = 0, nil

        for citizenid, data in pairs(race.racers) do
            position = position + 1
            first = first or citizenid

            MySQL.update.await('INSERT INTO racing_results (race, track, citizenid, racername, position) VALUES (?, ?, ?, ?, ?)', { race.id, race.name, citizenid, data.Racername, position })

            if race.ranked and citizenid ~= first then
                applyElo(first, citizenid, true)
            end
        end
        races[race.id] = nil
    end
end)

cwCallback.register('sm_racingtablet:server:setupRace', function(src, trackId, laps, elimination)
    local citizenid = citizen(src)
    if not citizenid then return end
    if ofSource[src] then return nil, 'Sudah berada di balapan.' end

    local track = MySQL.single.await('SELECT id, name FROM racing_tracks WHERE id = ?', { tonumber(trackId) })
    if not track then return nil, 'Track tidak ditemukan.' end

    seq = seq + 1

    local race = {
        id = seq,
        name = track.name,
        trackId = track.id,
        laps = math.max(tonumber(laps) or 1, 1),
        elimination = elimination == true,
        ranked = false,
        ranked = false,
        host = citizenid,
        started = false,
        finished = false,
        members = { src },
        racers = {},
    }

    race.racers[citizenid] = { Racername = getPlayerName(src) }

    races[race.id] = race
    ofSource[src] = race.id

    return race.id
end)

cwCallback.register('sm_racingtablet:server:cancelRace', function(src, raceId)
    local race = raceOf(tonumber(raceId))
    if not race or race.host ~= getCitizenId(src) then return nil, 'Bukan host.' end

    for _, member in ipairs(race.members) do
        ofSource[member] = nil
        clearBucket(member)
    end

    races[race.id] = nil

    return true
end)

cwCallback.register('sm_racingtablet:server:getRaceResults', function(_, raceId)
    return MySQL.query.await(
        'SELECT racerName, position, time FROM racing_results WHERE race = ? ORDER BY position ASC',
        { tonumber(raceId) }
    ) or {}
end)

AddEventHandler('playerDropped', function()
    local src = source
    local id = ofSource[src]

    clearBucket(src)
    ofSource[src] = nil

    local race = id and raceOf(id)
    if not race then return end

    for i = #race.members, 1, -1 do
        if race.members[i] == src then table.remove(race.members, i) end
    end

    if #race.members == 0 then races[id] = nil else names(race) end
end)
