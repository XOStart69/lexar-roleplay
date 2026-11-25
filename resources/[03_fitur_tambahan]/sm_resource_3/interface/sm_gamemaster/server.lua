--[[
    sm_gamemaster :: server  (ditulis ulang agar cocok dengan client)

    - Entitas (ped/kendaraan): dibuat di server, dilacak per pemain, kuota + rate limit.
    - Objek: record {id:string, model, x,y,z, rx,ry,rz, persist}. Dispawn di CLIENT
      (modules/objects.lua), server hanya menyimpan record dan menyiarkan
      sm_gamemaster:client:objects / objectAdd / objectUpdate / objectRemove.
      Objek `persist` disimpan di tabel sm_gamemaster_objects.
]]

local config = localmodule 'config'

local ACE = config.ace or 'command.gamemaster'
local MAX_ENTITIES = config.spawn.maxEntities or 25
local SPAWN_PER_SECOND = config.spawn.perSecond or 4
local MAX_DISTANCE = config.spawn.maxDistance or 650.0
local MAX_STORED = config.objects.maxStored or 50
local OBJECT_PER_SECOND = config.objects.perSecond or 2
local SELECT_RADIUS = config.selectRadius or 300.0
local LIGHTNING_RADIUS = config.lightningRadius or 450.0

local EXPLOSIONS = {}
for i = 1, #(config.explosions or {}) do
    EXPLOSIONS[config.explosions[i].type] = true
end

local STORE = 'sm_gamemaster_objects'

---@type table<number, table<number, boolean>>  src -> netId set
local owned = {}
---@type table<number, { model: string, kind: string, by: string, src: number }>
local meta = {}
local rate = {}
local sessions = {}

---@type table<string, table>
local records = {}
local tempCounter = 0

-- ───────────── util ─────────────

local function allowed(src)
    return IsPlayerAceAllowed(src, ACE)
end

local function count(tbl)
    local total = 0
    for _ in pairs(tbl) do total = total + 1 end
    return total
end

local function limited(src, kind, perSecond)
    rate[src] = rate[src] or {}

    local stamp = GetGameTimer()
    local entry = rate[src][kind]

    if not entry or stamp - entry.stamp >= 1000 then
        rate[src][kind] = { stamp = stamp, count = 1 }
        return false
    end

    entry.count = entry.count + 1
    return entry.count > perSecond
end

local function pedCoords(src)
    local ped = GetPlayerPed(src)
    if ped == 0 then return nil end
    return GetEntityCoords(ped)
end

local function nearPed(src, coords, radius)
    local origin = pedCoords(src)
    return origin ~= nil and #(origin - coords) <= radius
end

local function toVec(coords)
    if type(coords) ~= 'table' and type(coords) ~= 'vector3' then return nil end
    local x, y, z = tonumber(coords.x), tonumber(coords.y), tonumber(coords.z)
    if not x or not y or not z then return nil end
    return vector3(x, y, z)
end

local function entityOf(netId)
    netId = tonumber(netId)
    if not netId then return nil end

    local entity = NetworkGetEntityFromNetworkId(netId)
    if entity and entity ~= 0 and DoesEntityExist(entity) then return entity end
end

local function sendQuota(src)
    TriggerClientEvent('sm_gamemaster:client:quota', src, count(owned[src] or {}), MAX_ENTITIES)
end

local function track(src, netId, info)
    owned[src] = owned[src] or {}
    owned[src][netId] = true
    meta[netId] = info
    sendQuota(src)
end

local function untrack(netId)
    local info = meta[netId]
    meta[netId] = nil

    if info and owned[info.src] then
        owned[info.src][netId] = nil
        sendQuota(info.src)
    end
end

local function occupiedByPlayer(entity)
    if GetEntityType(entity) == 1 then return IsPedAPlayer(entity) end
    if GetEntityType(entity) ~= 2 then return false end

    for seat = -1, 6 do
        local ped = GetPedInVehicleSeat(entity, seat)
        if ped ~= 0 and IsPedAPlayer(ped) then return true end
    end

    return false
end

local function packRecord(record)
    return {
        id = record.id, model = record.model,
        x = record.x, y = record.y, z = record.z,
        rx = record.rx, ry = record.ry, rz = record.rz,
        persist = record.persist,
    }
end

local function allRecords()
    local list = {}
    for _, record in pairs(records) do list[#list + 1] = packRecord(record) end
    return list
end

local function rotOf(rot)
    rot = type(rot) == 'table' and rot or {}
    return tonumber(rot.x) or 0.0, tonumber(rot.y) or 0.0, tonumber(rot.z) or 0.0
end

-- ───────────── katalog / sesi ─────────────

lib.callback.register('sm_gamemaster:server:catalog', function(src)
    if not allowed(src) then return { ok = false } end

    local list = {}
    local ok, vehicles = pcall(function() return qb_ecore:GetSharedVehicles() end)

    if ok and type(vehicles) == 'table' then
        for key, data in pairs(vehicles) do
            local model = data.model or key
            list[#list + 1] = { m = tostring(model), l = data.name or tostring(model) }
        end
        table.sort(list, function(a, b) return a.m < b.m end)
    end

    return { ok = true, vehicles = list }
end)

lib.callback.register('sm_gamemaster:server:session', function(src, enable)
    if not allowed(src) then return { ok = false } end

    sessions[src] = enable and true or nil
    if enable then sendQuota(src) end

    return { ok = true }
end)

-- ───────────── entitas ─────────────

lib.callback.register('sm_gamemaster:server:spawn', function(src, payload)
    if not allowed(src) then return { ok = false, reason = 'Tidak punya akses.' } end
    if type(payload) ~= 'table' then return { ok = false, reason = 'Payload kosong.' } end

    if count(owned[src] or {}) >= MAX_ENTITIES then
        return { ok = false, reason = ('Kuota %d entitas tercapai.'):format(MAX_ENTITIES) }
    end
    if limited(src, 'spawn', SPAWN_PER_SECOND) then
        return { ok = false, reason = 'Terlalu cepat.' }
    end

    local coords = toVec(payload.coords)
    if not coords then return { ok = false, reason = 'Koordinat tidak valid.' } end
    if not nearPed(src, coords, MAX_DISTANCE) then
        return { ok = false, reason = 'Terlalu jauh dari kamera.' }
    end

    local kind = payload.kind
    local model = tostring(payload.model or '')
    if model == '' then return { ok = false, reason = 'Model kosong.' } end

    local heading = tonumber(payload.heading) or 0.0
    local hash = joaat(model)
    local entity

    if kind == 'vehicle' then
        entity = CreateVehicle(hash, coords.x, coords.y, coords.z, heading, true, true)
    elseif kind == 'ped' then
        entity = CreatePed(4, hash, coords.x, coords.y, coords.z, heading, true, true)
    else
        return { ok = false, reason = 'Jenis tidak dikenal.' }
    end

    if not entity or entity == 0 then
        return { ok = false, reason = ('Model %s gagal dibuat.'):format(model) }
    end

    local netId = NetworkGetNetworkIdFromEntity(entity)
    if netId == 0 then
        DeleteEntity(entity)
        return { ok = false, reason = 'Gagal sinkronisasi entitas.' }
    end

    track(src, netId, { model = model, kind = kind, by = GetPlayerName(src) or tostring(src), src = src })

    return { ok = true, netId = netId }
end)

lib.callback.register('sm_gamemaster:server:delete', function(src, netIds)
    if not allowed(src) then return { ok = false, reason = 'Tidak punya akses.' } end
    if type(netIds) ~= 'table' then return { ok = false, reason = 'Data tidak valid.' } end

    local removed, skipped = 0, 0

    for i = 1, #netIds do
        local netId = tonumber(netIds[i])
        local entity = entityOf(netId)

        if entity then
            if occupiedByPlayer(entity) then
                skipped = skipped + 1
            else
                DeleteEntity(entity)
                removed = removed + 1
                untrack(netId)
            end
        elseif netId then
            untrack(netId)
        end
    end

    return { ok = true, removed = removed, skipped = skipped }
end)

lib.callback.register('sm_gamemaster:server:control', function(src, netIds)
    if not allowed(src) then return { ok = false } end
    if type(netIds) ~= 'table' then return { ok = false } end

    local taken = 0

    for i = 1, #netIds do
        local entity = entityOf(netIds[i])
        if entity then
            SetEntityAsMissionEntity(entity, true, true)
            taken = taken + 1
        end
    end

    return { ok = true, taken = taken }
end)

lib.callback.register('sm_gamemaster:server:entities', function(src)
    if not allowed(src) then return { ok = false } end

    local list = {}

    for netId, info in pairs(meta) do
        local entity = entityOf(netId)

        if entity then
            local c = GetEntityCoords(entity)
            list[#list + 1] = { netId = netId, kind = info.kind, model = info.model, x = c.x, y = c.y, z = c.z, by = info.by }
        else
            untrack(netId)
        end
    end

    return { ok = true, entities = list }
end)

lib.callback.register('sm_gamemaster:server:locate', function(src, netId)
    if not allowed(src) then return nil end

    local entity = entityOf(netId)
    if not entity then return nil end

    local c = GetEntityCoords(entity)
    return { x = c.x, y = c.y, z = c.z }
end)

lib.callback.register('sm_gamemaster:server:cleanup', function(src)
    if not allowed(src) then return { ok = false, reason = 'Tidak punya akses.' } end

    local removed = 0

    for netId in pairs(meta) do
        local entity = entityOf(netId)
        if entity and not occupiedByPlayer(entity) then
            DeleteEntity(entity)
            removed = removed + 1
        end
        untrack(netId)
    end

    return { ok = true, removed = removed }
end)

-- ───────────── objek ─────────────

lib.callback.register('sm_gamemaster:server:objects', function(src)
    TriggerClientEvent('sm_gamemaster:client:objects', src, allRecords())
    return true
end)

lib.callback.register('sm_gamemaster:server:objectPlace', function(src, payload)
    if not allowed(src) then return { ok = false, reason = 'Tidak punya akses.' } end
    if type(payload) ~= 'table' then return { ok = false, reason = 'Payload kosong.' } end

    if count(records) >= MAX_STORED then
        return { ok = false, reason = ('Kuota %d objek tercapai.'):format(MAX_STORED) }
    end
    if limited(src, 'object', OBJECT_PER_SECOND) then
        return { ok = false, reason = 'Terlalu cepat.' }
    end

    local coords = toVec(payload.coords)
    if not coords then return { ok = false, reason = 'Koordinat tidak valid.' } end
    if not nearPed(src, coords, MAX_DISTANCE) then
        return { ok = false, reason = 'Terlalu jauh dari kamera.' }
    end

    local model = tostring(payload.model or '')
    if model == '' then return { ok = false, reason = 'Model kosong.' } end

    local rx, ry, rz = rotOf(payload.rot)
    local persist = payload.persist and true or false
    local player = qb_ecore:GetPlayer(src)
    local owner = player and player.PlayerData.citizenid or nil
    local id

    if persist then
        local row = MySQL.insert.await(
            ('INSERT INTO %s (owner, model, x, y, z, rx, ry, rz, created) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)'):format(STORE),
            { owner, model, coords.x, coords.y, coords.z, rx, ry, rz, os.time() })
        if not row then return { ok = false, reason = 'Gagal menyimpan objek.' } end
        id = 'p' .. row
    else
        tempCounter = tempCounter + 1
        id = 't' .. tempCounter
    end

    local record = {
        id = id, model = model, x = coords.x, y = coords.y, z = coords.z,
        rx = rx, ry = ry, rz = rz, persist = persist, owner = owner,
    }
    records[id] = record

    TriggerClientEvent('sm_gamemaster:client:objectAdd', -1, packRecord(record))

    return { ok = true, id = id }
end)

lib.callback.register('sm_gamemaster:server:objectUpdate', function(src, payload)
    if not allowed(src) then return { ok = false, reason = 'Tidak punya akses.' } end
    if type(payload) ~= 'table' then return { ok = false, reason = 'Payload kosong.' } end

    local record = records[tostring(payload.id or '')]
    if not record then return { ok = false, reason = 'Objek tidak ditemukan.' } end

    local coords = toVec(payload.coords)
    if not coords then return { ok = false, reason = 'Koordinat tidak valid.' } end
    if not nearPed(src, coords, MAX_DISTANCE) then return { ok = false, reason = 'Terlalu jauh dari kamera.' } end

    local rx, ry, rz = rotOf(payload.rot)
    record.x, record.y, record.z = coords.x, coords.y, coords.z
    record.rx, record.ry, record.rz = rx, ry, rz

    if record.persist then
        MySQL.update(('UPDATE %s SET x = ?, y = ?, z = ?, rx = ?, ry = ?, rz = ? WHERE id = ?'):format(STORE),
            { record.x, record.y, record.z, rx, ry, rz, tonumber(record.id:sub(2)) })
    end

    TriggerClientEvent('sm_gamemaster:client:objectUpdate', -1, packRecord(record))

    return { ok = true }
end)

lib.callback.register('sm_gamemaster:server:objectRemove', function(src, ids)
    if not allowed(src) then return { ok = false, reason = 'Tidak punya akses.' } end
    if type(ids) ~= 'table' then return { ok = false, reason = 'Data tidak valid.' } end

    local removedIds = {}

    for i = 1, #ids do
        local id = tostring(ids[i])
        local record = records[id]

        if record then
            if record.persist then
                MySQL.update(('DELETE FROM %s WHERE id = ?'):format(STORE), { tonumber(id:sub(2)) })
            end
            records[id] = nil
            removedIds[#removedIds + 1] = id
        end
    end

    if #removedIds > 0 then
        TriggerClientEvent('sm_gamemaster:client:objectRemove', -1, removedIds)
    end

    return { ok = true, removed = #removedIds }
end)

-- ───────────── efek ─────────────

lib.callback.register('sm_gamemaster:server:lightning', function(src, coords)
    if not allowed(src) then return { ok = false, reason = 'Tidak punya akses.' } end

    local pos = toVec(coords)
    if not pos then return { ok = false, reason = 'Koordinat tidak valid.' } end
    if not nearPed(src, pos, LIGHTNING_RADIUS + SELECT_RADIUS) then return { ok = false, reason = 'Terlalu jauh.' } end

    TriggerClientEvent('sm_gamemaster:client:lightning', -1, pos.x, pos.y, pos.z)

    return { ok = true }
end)

lib.callback.register('sm_gamemaster:server:explosion', function(src, kind, coords)
    if not allowed(src) then return { ok = false, reason = 'Tidak punya akses.' } end
    if not EXPLOSIONS[tonumber(kind)] then return { ok = false, reason = 'Jenis ledakan tidak dikenal.' } end

    local pos = toVec(coords)
    if not pos then return { ok = false, reason = 'Koordinat tidak valid.' } end
    if not nearPed(src, pos, SELECT_RADIUS) then return { ok = false, reason = 'Terlalu jauh.' } end

    -- client memanggil AddExplosion(isNetwork=true) sendiri setelah disetujui
    return { ok = true }
end)

-- ───────────── lifecycle ─────────────

CreateThread(function()
    MySQL.query.await(([[
    CREATE TABLE IF NOT EXISTS `%s` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `owner` varchar(64) DEFAULT NULL,
        `model` varchar(96) NOT NULL,
        `x` double NOT NULL,
        `y` double NOT NULL,
        `z` double NOT NULL,
        `rx` double NOT NULL DEFAULT 0,
        `ry` double NOT NULL DEFAULT 0,
        `rz` double NOT NULL DEFAULT 0,
        `created` int(11) NOT NULL,
        PRIMARY KEY (`id`),
        KEY `owner` (`owner`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]]):format(STORE))

    for _, row in ipairs(MySQL.query.await(('SELECT * FROM %s'):format(STORE)) or {}) do
        local id = 'p' .. row.id
        records[id] = {
            id = id, model = row.model, x = row.x, y = row.y, z = row.z,
            rx = row.rx, ry = row.ry, rz = row.rz, persist = true, owner = row.owner,
        }
    end

    TriggerClientEvent('sm_gamemaster:client:objects', -1, allRecords())
end)

AddEventHandler('playerDropped', function()
    local src = source

    for netId in pairs(owned[src] or {}) do
        local entity = entityOf(netId)
        if entity and not occupiedByPlayer(entity) then DeleteEntity(entity) end
        meta[netId] = nil
    end

    owned[src] = nil
    rate[src] = nil
    sessions[src] = nil
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    for netId in pairs(meta) do
        local entity = entityOf(netId)
        if entity and not occupiedByPlayer(entity) then DeleteEntity(entity) end
    end
end)
