--[[
    sm_communityservice :: server
    Polisi menjatuhkan sanksi (/cs). Tugas disimpan di DB, dilanjutkan saat login.
]]

local config = localmodule 'config'

-- SESUAIKAN: job yang boleh memberi sanksi
local ENFORCERS = { police = true, sasp = true, bcso = true, usmarshal = true, sheriff = true }
local TABLE = 'sm_communityservice'

---@type table<string, { tasks: integer, spot: integer }>
local active = {}

local function notify(src, message, kind)
    TriggerClientEvent('ox_lib:notify', src, { description = message, type = kind or 'error' })
end

local function isEnforcer(src)
    local player = qb_ecore:GetPlayer(src)
    if not player then return false end
    local job = player.PlayerData.job
    return ENFORCERS[job.name] == true and job.onduty ~= false
end

local function randomSpot(except)
    local total = #config.spots
    if total <= 1 then return 1 end

    local index
    repeat index = math.random(total) until index ~= except
    return index
end

local function nameOf(player)
    local info = player.PlayerData.charinfo or {}
    return ('%s %s'):format(info.firstname or '?', info.lastname or '')
end

local function begin(src, player, tasks, fresh, reason, by)
    local cid = player.PlayerData.citizenid
    local spot = randomSpot()

    active[cid] = { tasks = tasks, spot = spot }

    if fresh then
        MySQL.insert.await(('INSERT INTO %s (citizenid, tasks, reason, assigned_by, created) VALUES (?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE tasks = VALUES(tasks), reason = VALUES(reason), assigned_by = VALUES(assigned_by), created = VALUES(created)'):format(TABLE),
            { cid, tasks, reason, by, os.time() })
    end

    TriggerClientEvent('sm_cs:client:start', src, tasks, spot, fresh)
end

local function resume(src)
    local player = qb_ecore:GetPlayer(src)
    if not player then return end

    local row = MySQL.single.await(('SELECT tasks FROM %s WHERE citizenid = ?'):format(TABLE), { player.PlayerData.citizenid })
    if row and row.tasks > 0 then
        begin(src, player, row.tasks, false)
    end
end

lib.callback.register('sm_cs:server:nearby', function(src)
    if not isEnforcer(src) and not IsPlayerAceAllowed(src, 'command') then return {} end

    local origin = GetEntityCoords(GetPlayerPed(src))
    local list = {}

    for _, raw in ipairs(GetPlayers()) do
        local id = tonumber(raw)
        local other = id ~= src and qb_ecore:GetPlayer(id)

        if other then
            local distance = #(origin - GetEntityCoords(GetPlayerPed(id)))
            if distance <= config.assignRadius then
                list[#list + 1] = {
                    serverId = id,
                    name = nameOf(other),
                    distance = distance,
                    inService = active[other.PlayerData.citizenid] ~= nil,
                }
            end
        end
    end

    table.sort(list, function(a, b) return a.distance < b.distance end)
    return list
end)

lib.callback.register('sm_cs:server:assign', function(src, data)
    if type(data) ~= 'table' then return { success = false, message = 'Data tidak valid.' } end

    local admin = IsPlayerAceAllowed(src, 'command')
    if not isEnforcer(src) and not admin then
        return { success = false, message = 'Kamu tidak berwenang.' }
    end

    local targetId = tonumber(data.targetId)
    local tasks = math.floor(tonumber(data.tasks) or 0)
    local reason = tostring(data.reason or ''):match('^%s*(.-)%s*$')

    if not targetId then return { success = false, message = 'Target tidak valid.' } end
    if tasks < 1 or tasks > config.maxTasks then
        return { success = false, message = ('Jumlah tugas 1-%d.'):format(config.maxTasks) }
    end
    if #reason < config.reason.min or #reason > config.reason.max then
        return { success = false, message = 'Panjang alasan tidak valid.' }
    end

    local target = qb_ecore:GetPlayer(targetId)
    if not target then return { success = false, message = 'Target tidak ditemukan.' } end
    if targetId == src and not admin then
        return { success = false, message = 'Tidak bisa memberi sanksi ke diri sendiri.' }
    end

    if targetId ~= src then
        local distance = #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(GetPlayerPed(targetId)))
        if distance > config.assignRadius + 2.0 then
            return { success = false, message = 'Target terlalu jauh.' }
        end
    end

    if active[target.PlayerData.citizenid] then
        return { success = false, message = 'Target sedang menjalani sanksi.' }
    end

    local by = qb_ecore:GetPlayer(src)
    begin(targetId, target, tasks, true, reason, by and by.PlayerData.citizenid or 'console')

    return { success = true, message = ('Sanksi %d tugas diberikan ke %s.'):format(tasks, nameOf(target)) }
end)

lib.callback.register('sm_cs:server:complete', function(src)
    local player = qb_ecore:GetPlayer(src)
    local entry = player and active[player.PlayerData.citizenid]
    if not entry then return false end

    local spot = config.spots[entry.spot]
    if spot and #(GetEntityCoords(GetPlayerPed(src)) - spot) > config.sweepRadius + 4.0 then
        return false
    end

    entry.tasks = entry.tasks - 1
    local cid = player.PlayerData.citizenid

    if entry.tasks <= 0 then
        active[cid] = nil
        MySQL.update(('DELETE FROM %s WHERE citizenid = ?'):format(TABLE), { cid })
        TriggerClientEvent('sm_cs:client:finish', src)
        return 0
    end

    entry.spot = randomSpot(entry.spot)
    MySQL.update(('UPDATE %s SET tasks = ? WHERE citizenid = ?'):format(TABLE), { entry.tasks, cid })

    return entry.tasks, entry.spot
end)

RegisterCommand('cs', function(src)
    if src == 0 then return end
    if not isEnforcer(src) and not IsPlayerAceAllowed(src, 'command') then
        return notify(src, 'Kamu tidak berwenang.')
    end
    TriggerClientEvent('sm_cs:client:openMenu', src)
end, false)

CreateThread(function()
    MySQL.query.await(([[
    CREATE TABLE IF NOT EXISTS `%s` (
        `citizenid` varchar(64) NOT NULL,
        `tasks` int(11) NOT NULL,
        `reason` varchar(255) DEFAULT NULL,
        `assigned_by` varchar(64) DEFAULT NULL,
        `created` int(11) NOT NULL,
        PRIMARY KEY (`citizenid`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]]):format(TABLE))

    for _, raw in ipairs(GetPlayers()) do resume(tonumber(raw)) end
end)

AddEventHandler('QBCore:Server:PlayerLoaded', function(player)
    local src = type(player) == 'table' and player.PlayerData and player.PlayerData.source or tonumber(player)
    if not src then return end
    SetTimeout(4000, function() resume(src) end)
end)

AddEventHandler('QBCore:Server:OnPlayerUnload', function(src)
    local player = qb_ecore:GetPlayer(src)
    if player then active[player.PlayerData.citizenid] = nil end
end)
