---@param citizenid string
---@return string
local function tierOf(citizenid)
    local row = MySQL.single.await('SELECT auth FROM racing_access WHERE citizenid = ?', { citizenid })

    return (row and row.auth) or Config.BasePermission
end

---@param citizenid string
---@return table
local function permsOf(citizenid)
    return Config.Permissions[tierOf(citizenid)] or Config.Permissions[Config.BasePermission] or {}
end

cwCallback.register('sm_racingtablet:server:getAccess', function(src)
    return tierOf(getCitizenId(src) or '')
end)

cwCallback.register('sm_racingtablet:server:isAuthorizedToCreateRaces', function(src)
    local citizenid = getCitizenId(src)
    if not citizenid then return false end

    return permsOf(citizenid).create == true
end)

cwCallback.register('sm_racingtablet:server:getAdminData', function(src)
    local citizenid = getCitizenId(src)
    if not citizenid then return end

    local row = MySQL.single.await('SELECT auth, hosting, autohost FROM racing_access WHERE citizenid = ?', { citizenid })

    return { auth = tierOf(citizenid), hosting = row and row.hosting or 0, autohost = row and row.autohost or 0, perms = permsOf(citizenid) }
end)

cwCallback.register('sm_racingtablet:server:setUserAuth', function(src, target, tier)
    if permsOf(getCitizenId(src) or '').adminMenu ~= true then return nil, 'Tidak berwenang.' end
    if not Config.Permissions[tier] then return nil, 'Tier tidak dikenal.' end

    MySQL.update.await(
        'INSERT INTO racing_access (citizenid, auth) VALUES (?, ?) ON DUPLICATE KEY UPDATE auth = VALUES(auth)',
        { target, tier }
    )

    return true
end)

cwCallback.register('sm_racingtablet:server:toggleHosting', function(src)
    local citizenid = getCitizenId(src)
    if not citizenid then return end
    if permsOf(citizenid).handleHosting ~= true then return nil, 'Tidak berwenang.' end

    MySQL.update.await(
        'INSERT INTO racing_access (citizenid, hosting) VALUES (?, 1) ON DUPLICATE KEY UPDATE hosting = 1 - hosting',
        { citizenid }
    )

    local row = MySQL.single.await('SELECT hosting FROM racing_access WHERE citizenid = ?', { citizenid })

    return row and row.hosting or 0
end)

cwCallback.register('sm_racingtablet:server:toggleAutoHost', function(src)
    local citizenid = getCitizenId(src)
    if not citizenid then return end
    if permsOf(citizenid).handleAutoHost ~= true then return nil, 'Tidak berwenang.' end

    MySQL.update.await(
        'INSERT INTO racing_access (citizenid, autohost) VALUES (?, 1) ON DUPLICATE KEY UPDATE autohost = 1 - autohost',
        { citizenid }
    )

    local row = MySQL.single.await('SELECT autohost FROM racing_access WHERE citizenid = ?', { citizenid })

    return row and row.autohost or 0
end)

cwCallback.register('sm_racingtablet:server:getDashboardData', function()
    return {
        racers = MySQL.scalar.await('SELECT COUNT(*) FROM racing_racers') or 0,
        tracks = MySQL.scalar.await('SELECT COUNT(*) FROM racing_tracks') or 0,
        results = MySQL.scalar.await('SELECT COUNT(*) FROM racing_results') or 0,
    }
end)

cwCallback.register('sm_racingtablet:server:fetchRacerHistory', function(_, citizenid)
    return MySQL.query.await(
        'SELECT track, position, time, created FROM racing_results WHERE citizenid = ? ORDER BY id DESC LIMIT 25',
        { citizenid }
    ) or {}
end)

cwCallback.register('sm_racingtablet:server:getRacersCreatedByUser', function(src)
    return MySQL.query.await(
        'SELECT citizenid, racername FROM racing_racer_names WHERE citizenid = ?',
        { getCitizenId(src) }
    ) or {}
end)

cwCallback.register('sm_racingtablet:server:getAllRacers', function()
    return MySQL.query.await(
        'SELECT citizenid, racername, ranking, auth FROM racing_racer_names ORDER BY ranking DESC LIMIT 100'
    ) or {}
end)