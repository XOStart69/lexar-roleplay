---@param id number
---@return table?
local function trackOf(id)
    return MySQL.single.await('SELECT * FROM racing_tracks WHERE id = ?', { id })
end

---@param track table
---@return table
local function decode(track)
    local okc, checkpoints = pcall(json.decode, track.checkpoints or '[]')
    local okm, meta = pcall(json.decode, track.meta or '{}')

    track.checkpoints = okc and checkpoints or {}
    track.meta = okm and meta or {}
    track.checkpoints_raw = nil
    track.meta_raw = nil

    return track
end

cwCallback.register('sm_racingtablet:server:getTracksTrimmed', function(src)
    local citizenid = getCitizenId(src)

    return MySQL.query.await(
        'SELECT id, name, curated FROM racing_tracks WHERE curated = 1 OR owner = ? ORDER BY curated DESC, name ASC LIMIT ?',
        { citizenid, Config.LimitTracks or 100 }
    ) or {}
end)

cwCallback.register('sm_racingtablet:server:getTracks', function(src)
    local citizenid = getCitizenId(src)
    local rows = MySQL.query.await(
        'SELECT * FROM racing_tracks WHERE curated = 1 OR owner = ? ORDER BY curated DESC, name ASC LIMIT ?',
        { citizenid, Config.LimitTracks or 100 }
    ) or {}

    for i = 1, #rows do
        rows[i] = decode(rows[i])
    end

    return rows
end)

cwCallback.register('sm_racingtablet:server:getTrackData', function(_, id)
    local track = trackOf(tonumber(id))
    if not track then return end

    return decode(track)
end)

cwCallback.register('sm_racingtablet:server:getAmountOfTracks', function(src)
    local citizenid = getCitizenId(src)
    local mine = MySQL.scalar.await('SELECT COUNT(*) FROM racing_tracks WHERE owner = ?', { citizenid }) or 0
    local curated = MySQL.scalar.await('SELECT COUNT(*) FROM racing_tracks WHERE curated = 1') or 0

    return { mine = mine, curated = curated, max = Config.MaxCharacterTracks or 20 }
end)

cwCallback.register('sm_racingtablet:server:curateTrack', function(_, id, curated)
    MySQL.update.await('UPDATE racing_tracks SET curated = ? WHERE id = ?', { curated and 1 or 0, tonumber(id) })

    return true
end)

cwCallback.register('sm_racingtablet:server:updateTrackMetadata', function(src, id, checkpoints, meta)
    local track = id and trackOf(tonumber(id))
    local citizenid = getCitizenId(src)

    if type(checkpoints) ~= 'table' then return nil, 'Checkpoint tidak valid.' end
    if #checkpoints > (Config.MaxCheckpoints or 120) then return nil, 'Checkpoint terlalu banyak.' end

    if not track then
        local count = MySQL.scalar.await('SELECT COUNT(*) FROM racing_tracks WHERE owner = ?', { citizenid }) or 0

        local tier = MySQL.scalar.await('SELECT auth FROM racing_access WHERE citizenid = ?', { citizenid }) or Config.BasePermission
        local limit = math.min(Config.TrackLimitPerTier[tier] or Config.MaxCharacterTracks or 20, Config.MaxCharacterTracks or 20)

        if count >= limit then return nil, 'Batas track tercapai.' end

        local newId = MySQL.insert.await(
            'INSERT INTO racing_tracks (owner, name, checkpoints, meta) VALUES (?, ?, ?, ?)',
            { citizenid, StrictSanitize(meta and meta.name or 'Track Baru'), json.encode(checkpoints), json.encode(meta or {}) }
        )

        return newId
    end

    if track.owner and track.owner ~= citizenid then return nil, 'Bukan pemilik track.' end

    MySQL.update.await(
        'UPDATE racing_tracks SET checkpoints = ?, meta = ? WHERE id = ?',
        { json.encode(checkpoints), json.encode(meta or {}), track.id }
    )

    return track.id
end)

cwCallback.register('sm_racingtablet:server:getRaceRecordsForTrack', function(_, track, class)
    return MySQL.query.await(
        'SELECT racername, time FROM racing_results WHERE track = ? AND (class IS NULL OR class = ?) ORDER BY time ASC LIMIT 10',
        { StrictSanitize(track), StrictSanitize(class) }
    ) or {}
end)
