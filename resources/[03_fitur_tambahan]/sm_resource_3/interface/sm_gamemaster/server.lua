--[[
    sm_gamemaster :: server
    ACE gate, kuota entitas, rate limit, persistensi objek.
    Semua koordinat dari klien divalidasi ulang terhadap ped.
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

local catalog
do
    local ok, mod = pcall(localmodule, 'modules.catalog')
    catalog = ok and mod or nil
end

local STORE = 'sm_gamemaster_objects'

local quota = {}
local rate = {}

local function bucket(src)
    quota[src] = quota[src] or { entities = {}, objects = {} }
    rate[src] = rate[src] or {}
    return quota[src]
end

local function allowed(src)
    return IsPlayerAceAllowed(src, ACE)
end

local function notify(src, message, kind)
    TriggerClientEvent('ox_lib:notify', src, { description = message, type = kind or 'error' })
end

local function limited(src, kind, perSecond)
    local stamp = GetGameTimer()
    local entry = rate[src][kind]

    if not entry or stamp - entry.stamp >= 1000 then
        rate[src][kind] = { stamp = stamp, count = 1 }
        return false
    end

    entry.count = entry.count + 1
    return entry.count > perSecond
end

local function count(tbl)
    local total = 0
    for _ in pairs(tbl) do total = total + 1 end
    return total
end

local function pedCoords(src)
    local ped = GetPlayerPed(src)
    if ped == 0 then return nil end
    return GetEntityCoords(ped)
end

local function nearPed(src, coords, radius)
    local origin = pedCoords(src)
    if not origin then return false end
    return #(origin - coords) <= radius
end

local function toVec(coords)
    if type(coords) ~= 'table' then return nil end
    local x, y, z = tonumber(coords.x), tonumber(coords.y), tonumber(coords.z)
    if not x or not y or not z then return nil end
    return vector3(x, y, z)
end

local function track(src, list, id)
    local entry = bucket(src)
    entry[list][id] = true
end

local function untrack(src, list, id)
    local entry = quota[src]
    if entry then entry[list][id] = nil end
end

lib.callback.register('sm_gamemaster:server:catalog', function(src)
    if not allowed(src) then return {} end
    return catalog or {}
end)

lib.callback.register('sm_gamemaster:server:spawn', function(src, payload)
    if not allowed(src) then return { ok = false, reason = 'Tidak punya akses.' } end
    if type(payload) ~= 'table' then return { ok = false, reason = 'Payload kosong.' } end

    local entry = bucket(src)
    if count(entry.entities) >= MAX_ENTITIES then
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
    local hash = GetHashKey(model)
    local entity

    if kind == 'vehicle' then
        entity = CreateVehicle(hash, coords.x, coords.y, coords.z, heading, true)
    elseif kind == 'ped' then
        entity = CreatePed(4, hash, coords.x, coords.y, coords.z, heading, true)
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

    track(src, 'entities', netId)

    return { ok = true, netId = netId }
end)

lib.callback.register('sm_gamemaster:server:delete', function(src, netIds)
    if not allowed(src) then return { ok = false } end
    if type(netIds) ~= 'table' then return { ok = false } end

    local removed = 0

    for i = 1, #netIds do
        local netId = tonumber(netIds[i])
        local entity = netId and NetworkGetEntityFromNetworkId(netId)

        if entity and entity ~= 0 and DoesEntityExist(entity) then
            DeleteEntity(entity)
            removed = removed + 1
        end

        if netId then untrack(src, 'entities', netId) end
    end

    return { ok = true, removed = removed }
end)

lib.callback.register('sm_gamemaster:server:control', function(src, netIds)
    if not allowed(src) then return { ok = false } end
    if type(netIds) ~= 'table' then return { ok = false } end

    local taken = 0

    for i = 1, #netIds do
        local netId = tonumber(netIds[i])
        local entity = netId and NetworkGetEntityFromNetworkId(netId)

        if entity and entity ~= 0 and DoesEntityExist(entity) then
            SetEntityAsMissionEntity(entity, true, true)
            taken = taken + 1
        end
    end

    return { ok = true, taken = taken }
end)

lib.callback.register('sm_gamemaster:server:objectPlace', function(src, payload)
    if not allowed(src) then return { ok = false, reason = 'Tidak punya akses.' } end
    if type(payload) ~= 'table' then return { ok = false, reason = 'Payload kosong.' } end

    local entry = bucket(src)
    if count(entry.objects) >= MAX_STORED then
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

    local rot = type(payload.rot) == 'table' and payload.rot or {}
    local rx, ry, rz = tonumber(rot.x) or 0.0, tonumber(rot.y) or 0.0, tonumber(rot.z) or 0.0

    local entity = CreateObject(GetHashKey(model), coords.x, coords.y, coords.z, true, true)
    if not entity or entity == 0 then
        return { ok = false, reason = ('Model %s gagal dibuat.'):format(model) }
    end

    SetEntityRotation(entity, rx, ry, rz, 2, true)

    local netId = NetworkGetNetworkIdFromEntity(entity)
    if netId == 0 then
        DeleteEntity(entity)
        return { ok = false, reason = 'Gagal sinkronisasi objek.' }
    end

    local player = qb_ecore:GetPlayer(src)
    local persist = payload.persist and true or false
    local id

    if persist and player then
        id = MySQL.insert.await(
            ('INSERT INTO %s (owner, model, x, y, z, rx, ry, rz, created) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)'):format(STORE),
            { player.PlayerData.citizenid, model, coords.x, coords.y, coords.z, rx, ry, rz, os.time() }
        )
    end

    track(src, 'objects', netId)

    return { ok = true, netId = netId, id = id }
end)

lib.callback.register('sm_gamemaster:server:objectUpdate', function(src, payload)
    if not allowed(src) then return { ok = false } end
    if type(payload) ~= 'table' then return { ok = false } end

    local coords = toVec(payload.coords)
    if not coords then return { ok = false } end
    if not nearPed(src, coords, MAX_DISTANCE) then return { ok = false } end

    local rot = type(payload.rot) == 'table' and payload.rot or {}
    local rx, ry, rz = tonumber(rot.x) or 0.0, tonumber(rot.y) or 0.0, tonumber(rot.z) or 0.0

    local netId = tonumber(payload.netId)
    local entity = netId and NetworkGetEntityFromNetworkId(netId)

    if entity and entity ~= 0 and DoesEntityExist(entity) then
        SetEntityCoords(entity, coords.x, coords.y, coords.z, false, false, false, true)
        SetEntityRotation(entity, rx, ry, rz, 2, true)
    end

    local id = tonumber(payload.id)
    if id then
        MySQL.update(
            ('UPDATE %s SET x = ?, y = ?, z = ?, rx = ?, ry = ?, rz = ? WHERE id = ?'):format(STORE),
            { coords.x, coords.y, coords.z, rx, ry, rz, id }
        )
    end

    return { ok = true }
end)

lib.callback.register('sm_gamemaster:server:objectRemove', function(src, ids)
    if not allowed(src) then return { ok = false } end
    if type(ids) ~= 'table' then return { ok = false } end

    local removed = 0

    for i = 1, #ids do
        local id = tonumber(ids[i])
        if id then
            local row = MySQL.single.await('SELECT * FROM ' .. STORE .. ' WHERE id = ?', { id })
            if row then
                local entity = NetworkGetEntityFromNetworkId(
                    NetworkGetNetworkIdFromEntity(GetClosestObjectOfType(row.x, row.y, row.z, 2.0, GetHashKey(row.model), false, false, false))
                )

                MySQL.update('DELETE FROM ' .. STORE .. ' WHERE id = ?', { id })
                removed = removed + 1
            end
        end
    end

    return { ok = true, removed = removed }
end)

lib.callback.register('sm_gamemaster:server:lightning', function(src, coords)
    if not allowed(src) then return { ok = false } end

    local pos = toVec(coords)
    if not pos then return { ok = false } end
    if not nearPed(src, pos, LIGHTNING_RADIUS + SELECT_RADIUS) then return { ok = false, reason = 'Terlalu jauh.' } end

    TriggerClientEvent('sm_gamemaster:client:lightning', -1, pos)

    return { ok = true }
end)

lib.callback.register('sm_gamemaster:server:explosion', function(src, kind, coords)
    if not allowed(src) then return { ok = false } end
    if not EXPLOSIONS[tonumber(kind)] then return { ok = false, reason = 'Jenis ledakan tidak dikenal.' } end

    local pos = toVec(coords)
    if not pos then return { ok = false } end
    if not nearPed(src, pos, SELECT_RADIUS) then return { ok = false, reason = 'Terlalu jauh.' } end

    TriggerClientEvent('sm_gamemaster:client:explosion', -1, tonumber(kind), pos)

    return { ok = true }
end)

CreateThread(function()
    MySQL.query.await([[
    CREATE TABLE IF NOT EXISTS `sm_gamemaster_objects` (
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
    ]])
end)

AddEventHandler('playerDropped', function()
    local src = source
    local entry = quota[src]
    if not entry then return end

    for netId in pairs(entry.entities) do
        local entity = NetworkGetEntityFromNetworkId(netId)
        if entity and entity ~= 0 and DoesEntityExist(entity) then DeleteEntity(entity) end
    end

    for netId in pairs(entry.objects) do
        local entity = NetworkGetEntityFromNetworkId(netId)
        if entity and entity ~= 0 and DoesEntityExist(entity) then DeleteEntity(entity) end
    end

    quota[src] = nil
    rate[src] = nil
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    quota = {}
    rate = {}
end)

print('^2[sm_gamemaster] server siap^7')