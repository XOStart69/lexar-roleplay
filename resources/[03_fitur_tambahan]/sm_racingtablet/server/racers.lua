---@param citizenid string
---@return table
local function namesOf(citizenid)
    return MySQL.query.await(
        'SELECT id, racername, ranking, auth, crypto FROM racing_racer_names WHERE citizenid = ? ORDER BY id ASC',
        { citizenid }
    ) or {}
end

cwCallback.register('sm_racingtablet:server:getRacerNamesByPlayer', function(src)
    local citizenid = getCitizenId(src)
    if not citizenid then return {} end

    local names = namesOf(citizenid)
    local result = {}

    for i = 1, #names do
        result[#result + 1] = {
            id = names[i].id,
            racername = names[i].racername,
            auth = names[i].auth,
            ranking = names[i].ranking,
            crypto = names[i].crypto,
        }
    end

    return result
end)

cwCallback.register('sm_racingtablet:server:isFirstUser', function(src)
    local citizenid = getCitizenId(src)
    if not citizenid then return false end

    return #namesOf(citizenid) == 0
end)

cwCallback.register('sm_racingtablet:server:nameIsAvailable', function(_, name)
    name = StrictSanitize(name)
    if name == '' then return false end

    local taken = MySQL.scalar.await('SELECT COUNT(*) FROM racing_racer_names WHERE racername = ?', { name })

    return (taken or 0) == 0
end)

cwCallback.register('sm_racingtablet:server:changeRacerName', function(src, name)
    local citizenid = getCitizenId(src)
    if not citizenid then return end

    name = StrictSanitize(name)
    if name == '' then return nil, 'Nama tidak valid.' end

    local taken = MySQL.scalar.await(
        'SELECT COUNT(*) FROM racing_racer_names WHERE racername = ? AND citizenid <> ?',
        { name, citizenid }
    )

    if (taken or 0) > 0 then return nil, 'Nama sudah dipakai.' end

    local count = MySQL.scalar.await('SELECT COUNT(*) FROM racing_racer_names WHERE citizenid = ?', { citizenid }) or 0

    if count == 0 then
        MySQL.insert.await('INSERT INTO racing_racer_names (citizenid, racername, auth) VALUES (?, ?, ?)', { citizenid, name, Config.BasePermission })
        return true
    end

    MySQL.update.await('UPDATE racing_racer_names SET racername = ? WHERE citizenid = ?', { name, citizenid })

    return true
end)

cwCallback.register('sm_racingtablet:server:renameRacer', function(_, id, name)
    name = StrictSanitize(name)
    if name == '' then return nil, 'Nama tidak valid.' end

    MySQL.update.await('UPDATE racing_racer_names SET racername = ? WHERE id = ?', { name, tonumber(id) })

    return true
end)

---@param citizenid string
---@return string?
function activeNameOf(citizenid)
    local row = MySQL.single.await(
        'SELECT racername FROM racing_racer_names WHERE citizenid = ? ORDER BY id ASC LIMIT 1',
        { citizenid }
    )

    return row and row.racername or nil
end
