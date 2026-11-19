---@param citizenid string
---@return string?
function crewOf(citizenid)
    local row = MySQL.single.await(
        'SELECT c.name FROM racing_crew_members m INNER JOIN racing_crews c ON c.id = m.crew WHERE m.citizenid = ?',
        { citizenid }
    )

    return row and row.name or nil
end

---@param citizenid string
---@return number?
local function crewIdOf(citizenid)
    local row = MySQL.single.await('SELECT crew FROM racing_crew_members WHERE citizenid = ?', { citizenid })

    return row and row.crew or nil
end

cwCallback.register('sm_racingtablet:server:getAllCrews', function()
    return MySQL.query.await(
        'SELECT c.id, c.name, c.tag, c.points, (SELECT COUNT(*) FROM racing_crew_members m WHERE m.crew = c.id) AS members FROM racing_crews c ORDER BY c.points DESC LIMIT 50'
    ) or {}
end)

cwCallback.register('sm_racingtablet:server:getCrewData', function(_, crewId)
    local crew = MySQL.single.await('SELECT id, name, tag, points FROM racing_crews WHERE id = ?', { tonumber(crewId) })
    if not crew then return end

    crew.members = MySQL.query.await(
        'SELECT m.citizenid, r.racername, r.ranking FROM racing_crew_members m LEFT JOIN racing_racer_names r ON r.citizenid = m.citizenid WHERE m.crew = ?',
        { crew.id }
    ) or {}

    return crew
end)

cwCallback.register('sm_racingtablet:server:createCrew', function(src, name, tag)
    local citizenid = getCitizenId(src)
    if not citizenid then return end

    name = StrictSanitize(name)
    if name == '' then return nil, 'Nama tidak valid.' end
    if crewIdOf(citizenid) then return nil, 'Sudah punya crew.' end

    local taken = MySQL.scalar.await('SELECT COUNT(*) FROM racing_crews WHERE name = ?', { name })
    if (taken or 0) > 0 then return nil, 'Nama crew sudah dipakai.' end

    local id = MySQL.insert.await('INSERT INTO racing_crews (name, tag, owner) VALUES (?, ?, ?)', {
        name,
        StrictSanitize(tag),
        citizenid,
    })

    if not id then return nil, 'Gagal membuat crew.' end

    MySQL.update.await('INSERT IGNORE INTO racing_crew_members (citizenid, crew) VALUES (?, ?)', { citizenid, id })

    return id
end)

cwCallback.register('sm_racingtablet:server:joinCrew', function(src, crewId)
    local citizenid = getCitizenId(src)
    if not citizenid then return end
    if crewIdOf(citizenid) then return nil, 'Sudah punya crew.' end

    MySQL.update.await('INSERT IGNORE INTO racing_crew_members (citizenid, crew) VALUES (?, ?)', {
        citizenid,
        tonumber(crewId),
    })

    return true
end)

cwCallback.register('sm_racingtablet:server:leaveCrew', function(src)
    local citizenid = getCitizenId(src)
    if not citizenid then return end

    MySQL.update.await('DELETE FROM racing_crew_members WHERE citizenid = ?', { citizenid })

    return true
end)

cwCallback.register('sm_racingtablet:server:disbandCrew', function(src)
    local citizenid = getCitizenId(src)
    if not citizenid then return end

    local crewId = crewIdOf(citizenid)
    if not crewId then return nil, 'Tidak punya crew.' end

    local crew = MySQL.single.await('SELECT owner FROM racing_crews WHERE id = ?', { crewId })
    if not crew or crew.owner ~= citizenid then return nil, 'Bukan pemilik crew.' end

    MySQL.update.await('DELETE FROM racing_crew_members WHERE crew = ?', { crewId })
    MySQL.update.await('DELETE FROM racing_crews WHERE id = ?', { crewId })

    return true
end)

cwCallback.register('sm_racingtablet:server:kickMemberFromCrew', function(src, target)
    local citizenid = getCitizenId(src)
    if not citizenid then return end

    local crewId = crewIdOf(citizenid)
    if not crewId then return nil, 'Tidak punya crew.' end

    MySQL.update.await('DELETE FROM racing_crew_members WHERE crew = ? AND citizenid = ?', { crewId, target })

    return true
end)

cwCallback.register('sm_racingtablet:server:crewStillExists', function(_, crewId)
    local count = MySQL.scalar.await('SELECT COUNT(*) FROM racing_crews WHERE id = ?', { tonumber(crewId) })

    return (count or 0) > 0
end)

cwCallback.register('sm_racingtablet:server:sendInvite', function(src, crewId, target)
    local citizenid = getCitizenId(src)
    if not citizenid then return end

    MySQL.update.await('INSERT INTO racing_crew_invites (crew, citizenid, invited) VALUES (?, ?, ?)', {
        tonumber(crewId),
        target,
        citizenid,
    })

    return true
end)

cwCallback.register('sm_racingtablet:server:sendInviteClosest', function(src, crewId)
    local ped = GetPlayerPed(src)
    if ped == 0 then return end

    local coords = GetEntityCoords(ped)
    local closest, best = nil, 15.0

    for _, id in ipairs(GetPlayers()) do
        local other = tonumber(id)

        if other ~= src then
            local otherPed = GetPlayerPed(other)

            if otherPed ~= 0 then
                local d = distance(coords, GetEntityCoords(otherPed))

                if d < best then closest, best = other, d end
            end
        end
    end

    if not closest then return nil, 'Tidak ada pemain di dekat.' end

    local citizenid = getCitizenId(closest)
    if not citizenid then return end

    MySQL.update.await('INSERT INTO racing_crew_invites (crew, citizenid, invited) VALUES (?, ?, ?)', {
        tonumber(crewId),
        citizenid,
        getCitizenId(src),
    })

    return citizenid
end)

cwCallback.register('sm_racingtablet:server:acceptInvite', function(src, crewId)
    local citizenid = getCitizenId(src)
    if not citizenid then return end

    MySQL.update.await('INSERT IGNORE INTO racing_crew_members (citizenid, crew) VALUES (?, ?)', {
        citizenid,
        tonumber(crewId),
    })
    MySQL.update.await('DELETE FROM racing_crew_invites WHERE citizenid = ? AND crew = ?', { citizenid, tonumber(crewId) })

    return true
end)

cwCallback.register('sm_racingtablet:server:denyInvite', function(src, crewId)
    local citizenid = getCitizenId(src)
    if not citizenid then return end

    MySQL.update.await('DELETE FROM racing_crew_invites WHERE citizenid = ? AND crew = ?', { citizenid, tonumber(crewId) })

    return true
end)

RegisterNetEvent('sm_racingtablet:server:changeCrew', function(crewId)
    local src = source
    local citizenid = getCitizenId(src)
    if not citizenid then return end

    MySQL.update.await('DELETE FROM racing_crew_members WHERE citizenid = ?', { citizenid })
    MySQL.update.await('INSERT IGNORE INTO racing_crew_members (citizenid, crew) VALUES (?, ?)', {
        citizenid,
        tonumber(crewId),
    })
end)