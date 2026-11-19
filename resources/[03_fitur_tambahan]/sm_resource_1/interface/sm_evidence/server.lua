--[[
    sm_evidence :: server
    Bukti hidup di DB dengan TTL. Otoritas: job/grade, jarak, cooldown, chance, jarak antar bukti.
]]

local Config = localmodule 'config'
local Data = localmodule 'data.evidence'

local Jobs = Config.Jobs or {}
local Items = Config.Items or {}
local Chance = Config.Chance or {}
local Cooldown = Config.Cooldown or {}
local MinDistance = Config.MinDistance or {}
local GlovesBlock = Config.GlovesBlock or {}
local Points = Config.AnalyzePoints or {}

local LIFETIME = Config.Lifetime or 300
local MAX_ACTIVE = Config.MaxActive or 1000
local INTERACT = (Config.Marker and Config.Marker.interactDistance or 1.6) + 1.0
local SYNC_RADIUS = 60.0

local TABLE = 'sm_evidence'
local lastDrop = {}

local function playerOf(src)
    return qb_ecore:GetPlayer(src)
end

local function authorized(player)
    if not player then return false end
    local need = Jobs[player.PlayerData.job.name]
    if need == nil then return false end
    return (player.PlayerData.job.grade.level or 0) >= need
end

local function notify(src, message, kind)
    TriggerClientEvent('ox_lib:notify', src, { description = message, type = kind or 'error' })
end

local function activeCount()
    return MySQL.scalar.await('SELECT COUNT(*) FROM ' .. TABLE) or 0
end

local function decode(raw)
    local ok, data = pcall(json.decode, raw or '{}')
    if not ok or type(data) ~= 'table' then return {} end
    return data
end

local function nearSameType(coords, kind, distance)
    local row = MySQL.single.await(
        ('SELECT id FROM %s WHERE type = ? AND x BETWEEN ? AND ? AND y BETWEEN ? AND ? LIMIT 1'):format(TABLE),
        { kind, coords.x - distance, coords.x + distance, coords.y - distance, coords.y + distance }
    )
    return row ~= nil
end

local function broadcast(event, ...)
    for _, raw in ipairs(GetPlayers()) do
        local src = tonumber(raw)
        local player = playerOf(src)
        if authorized(player) then
            TriggerClientEvent(event, src, ...)
        end
    end
end

local function create(src, kind, coords, extra)
    local player = playerOf(src)
    if not player or not authorized(player) then return nil end

    local typeConfig = Data.types[kind]
    if not typeConfig then return nil end

    local item = Items[kind]
    if not item then return nil end

    if (Chance[kind] or 100) < math.random(1, 100) then return nil end

    local stamp = GetGameTimer()
    local key = src .. ':' .. kind
    if lastDrop[key] and stamp - lastDrop[key] < (Cooldown[kind] or 0) then return nil end

    if nearSameType(coords, kind, MinDistance[kind] or 0.5) then return nil end
    if activeCount() >= MAX_ACTIVE then return nil end

    lastDrop[key] = stamp

    local meta = type(extra) == 'table' and extra or {}
    meta.officer = player.PlayerData.citizenid
    meta.time = os.time()

    local id = MySQL.insert.await(
        ('INSERT INTO %s (type, x, y, z, meta, ttl, created) VALUES (?, ?, ?, ?, ?, ?, ?)'):format(TABLE),
        { kind, coords.x, coords.y, coords.z, json.encode(meta), LIFETIME, os.time() }
    )

    if not id then return nil end

    broadcast('sm_evidence:add', {
        id = id, type = kind, coords = coords, ttl = LIFETIME,
    })

    return id
end

lib.callback.register('sm_evidence:create', function(src, kind, coords, extra)
    if type(coords) ~= 'table' then return false end
    local pos = vector3(tonumber(coords.x) or 0.0, tonumber(coords.y) or 0.0, tonumber(coords.z) or 0.0)
    return create(src, kind, pos, extra) ~= nil
end)

RegisterNetEvent('sm_evidence:server:add', function(kind, coords, extra)
    local src = source
    if type(coords) ~= 'table' then return end
    local pos = vector3(tonumber(coords.x) or 0.0, tonumber(coords.y) or 0.0, tonumber(coords.z) or 0.0)
    create(src, kind, pos, extra)
end)

lib.callback.register('sm_evidence:sync', function(src, coords)
    local player = playerOf(src)
    if not authorized(player) then return {} end
    if type(coords) ~= 'table' then return {} end

    local pos = vector3(tonumber(coords.x) or 0.0, tonumber(coords.y) or 0.0, tonumber(coords.z) or 0.0)
    local now = os.time()

    local rows = MySQL.query.await(
        ('SELECT * FROM %s WHERE x BETWEEN ? AND ? AND y BETWEEN ? AND ?'):format(TABLE),
        { pos.x - SYNC_RADIUS, pos.x + SYNC_RADIUS, pos.y - SYNC_RADIUS, pos.y + SYNC_RADIUS }
    ) or {}

    local out = {}

    for i = 1, #rows do
        local row = rows[i]
        local ttl = (row.created + row.ttl) - now
        if ttl > 0 and #(pos - vector3(row.x, row.y, row.z)) <= SYNC_RADIUS then
            out[#out + 1] = {
                id = row.id, type = row.type, ttl = ttl,
                coords = { x = row.x, y = row.y, z = row.z },
            }
        end
    end

    return out
end)

lib.callback.register('sm_evidence:collect', function(src, id)
    local player = playerOf(src)
    if not authorized(player) then return false end

    local row = MySQL.single.await('SELECT * FROM ' .. TABLE .. ' WHERE id = ?', { tonumber(id) })
    if not row then return false end

    local ped = GetPlayerPed(src)
    if #(GetEntityCoords(ped) - vector3(row.x, row.y, row.z)) > INTERACT then return false end

    local item = Items[row.type]
    if not item then return false end

    local meta = decode(row.meta)
    meta.collected = os.time()

    if not ox_inventory:AddItem(src, item, 1, meta) then return false end

    MySQL.update('DELETE FROM ' .. TABLE .. ' WHERE id = ?', { row.id })
    broadcast('sm_evidence:remove', { row.id })

    return true
end)

local function stationOf(id)
    return Points[tonumber(id) or 0]
end

local function allowedType(station, kind)
    for i = 1, #(station.types or {}) do
        if station.types[i] == kind then return true end
    end
    return false
end

lib.callback.register('sm_evidence:getSamples', function(src, stationId)
    local player = playerOf(src)
    if not authorized(player) then return {} end

    local station = stationOf(stationId)
    if not station then return {} end

    local items = ox_inventory:GetInventoryItems(src) or {}
    local out = {}

    for slot, entry in pairs(items) do
        local kind = entry.name
        if allowedType(station, kind) then
            out[#out + 1] = {
                slot = slot,
                type = kind,
                label = (Data.types[kind] and Data.types[kind].label) or kind,
            }
        end
    end

    return out
end)

lib.callback.register('sm_evidence:analyze', function(src, slot, stationId)
    local player = playerOf(src)
    if not authorized(player) then return nil end

    local station = stationOf(stationId)
    if not station then return nil end

    local entry = ox_inventory:GetSlot(src, tonumber(slot) or 0)
    if not entry or not allowedType(station, entry.name) then return nil end

    local meta = entry.metadata or {}
    local kind = entry.name

    local report = {
        type = kind,
        label = (Data.types[kind] and Data.types[kind].label) or kind,
        officer = meta.officer,
        collected = meta.collected,
        time = meta.time,
        dna = meta.dna,
        owner = meta.owner,
        caliber = meta.caliber and Data.calibers[meta.caliber] or Data.calibers.unknown,
        conclusion = 'Sampel teridentifikasi.',
    }

    ox_inventory:RemoveItem(src, kind, 1, nil, tonumber(slot))

    return report
end)

CreateThread(function()
    MySQL.query.await(([[
    CREATE TABLE IF NOT EXISTS `%s` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `type` varchar(32) NOT NULL,
        `x` double NOT NULL,
        `y` double NOT NULL,
        `z` double NOT NULL,
        `meta` longtext DEFAULT NULL,
        `ttl` int(11) NOT NULL,
        `created` int(11) NOT NULL,
        PRIMARY KEY (`id`),
        KEY `pos` (`x`, `y`),
        KEY `created` (`created`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]]):format(TABLE))

    while true do
        Wait(30000)
        local cut = os.time() - LIFETIME
        MySQL.update('DELETE FROM ' .. TABLE .. ' WHERE created < ?', { cut })
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    lastDrop = {}
end)

print('^2[sm_evidence] server siap^7')