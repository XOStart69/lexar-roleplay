--[[ sm_notepad / server.lua ]]

local SCHEMA = [[CREATE TABLE IF NOT EXISTS `sm_notepad_notes` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(50) NOT NULL,
    `title` VARCHAR(64) DEFAULT NULL,
    `body` TEXT NOT NULL,
    `coords` VARCHAR(128) NOT NULL,
    `created_at` INT UNSIGNED NOT NULL,
    `expires_at` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`id`),
    KEY `citizenid` (`citizenid`),
    KEY `expires_at` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;]]

local ITEM           = 'notepad'
local LIFETIME       = 60 * 60 * 24
local MAX_PER_PLAYER = 10
local MAX_TOTAL      = 150
local COOLDOWN       = 3
local READ_DISTANCE  = 3.0
local GIVE_DISTANCE  = 4.0

local notes    = {}
local owned    = {}
local cooldown = {}

local function now() return os.time() end

local function framework()
    for _, name in ipairs({ 'sm_core', 'qb-core', 'qbx_core' }) do
        if GetResourceState(name) == 'started' then return name end
    end
end

local function getPlayer(src)
    local fw = framework()
    if not fw then return nil end
    local ok, player = pcall(function() return exports[fw]:GetPlayer(src) end)
    if ok and player then return player end
end

local function public(note)
    return { id = note.id, title = note.title, coords = note.coords }
end

local function within(src, coords, dist)
    local ped = GetPlayerPed(src)
    if ped == 0 then return false end
    local c = GetEntityCoords(ped)
    return #(c - vector3(coords.x, coords.y, coords.z)) <= dist
end

local function purge(id)
    local note = notes[id]
    if not note then return end
    notes[id] = nil
    owned[note.citizenid] = math.max((owned[note.citizenid] or 1) - 1, 0)
    TriggerClientEvent('sm_notepad:client:despawn', -1, id)
end

local function expireLoop()
    while true do
        Wait(60000)
        local t = now()
        for id, note in pairs(notes) do
            if note.expires_at <= t then
                MySQL.update.await('DELETE FROM sm_notepad_notes WHERE id = ?', { id })
                purge(id)
            end
        end
    end
end

lib.callback.register('sm_notepad:server:place', function(src, title, body, coords)
    local player = getPlayer(src)
    if not player then return false, 'player' end
    if cooldown[src] and now() - cooldown[src] < COOLDOWN then return false, 'cooldown' end

    local citizenid = player.PlayerData.citizenid
    if (owned[citizenid] or 0) >= MAX_PER_PLAYER then return false, 'limit' end

    local count = MySQL.scalar.await('SELECT COUNT(*) FROM sm_notepad_notes WHERE expires_at > ?', { now() })
    if (count or 0) >= MAX_TOTAL then return false, 'full' end

    title = tostring(title or ''):sub(1, 64)
    body  = tostring(body  or ''):sub(1, 2000)
    if body == '' then return false, 'empty' end

    cooldown[src] = now()

    local id = MySQL.insert.await(
        'INSERT INTO sm_notepad_notes (citizenid, title, body, coords, created_at, expires_at) VALUES (?, ?, ?, ?, ?, ?)',
        { citizenid, title, body, json.encode(coords), now(), now() + LIFETIME }
    )
    if not id then return false, 'db' end

    local note = {
        id = id, citizenid = citizenid, title = title, body = body,
        coords = coords, expires_at = now() + LIFETIME,
    }
    notes[id] = note
    owned[citizenid] = (owned[citizenid] or 0) + 1

    TriggerClientEvent('sm_notepad:client:spawn', -1, public(note))
    return true, id
end)

lib.callback.register('sm_notepad:server:read', function(src, id)
    local note = notes[tonumber(id) or 0]
    if not note then return nil end
    if not within(src, note.coords, READ_DISTANCE) then return nil end
    return { id = note.id, title = note.title, body = note.body }
end)

lib.callback.register('sm_notepad:server:edit', function(src, id, body)
    local player = getPlayer(src)
    if not player then return false end

    local note = notes[tonumber(id) or 0]
    if not note then return false end
    if note.citizenid ~= player.PlayerData.citizenid then return false end
    if not within(src, note.coords, GIVE_DISTANCE) then return false end

    body = tostring(body or ''):sub(1, 2000)
    note.body = body
    MySQL.update.await('UPDATE sm_notepad_notes SET body = ? WHERE id = ?', { body, note.id })
    return true
end)

RegisterNetEvent('sm_notepad:server:pickup', function(id)
    local src = source
    local player = getPlayer(src)
    if not player then return end

    local note = notes[tonumber(id) or 0]
    if not note then return end
    if note.citizenid ~= player.PlayerData.citizenid then return end
    if not within(src, note.coords, GIVE_DISTANCE) then return end

    local ok = pcall(function()
        return exports.ox_inventory:AddItem(src, ITEM, 1, { noteId = note.id, title = note.title })
    end)
    if not ok then return end

    MySQL.update.await('DELETE FROM sm_notepad_notes WHERE id = ?', { note.id })
    purge(note.id)
end)

RegisterUsableItem(ITEM, function(src, item)
    local meta = item and item.metadata
    if meta and meta.noteId then
        TriggerClientEvent('sm_notepad:client:openReader', src, meta.noteId)
    else
        TriggerClientEvent('sm_notepad:client:openEditor', src)
    end
end)

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    MySQL.query.await(SCHEMA)
    local rows = MySQL.query.await('SELECT * FROM sm_notepad_notes WHERE expires_at > ?', { now() })
    for _, row in ipairs(rows or {}) do
        notes[row.id] = {
            id = row.id, citizenid = row.citizenid, title = row.title, body = row.body,
            coords = json.decode(row.coords), expires_at = row.expires_at,
        }
        owned[row.citizenid] = (owned[row.citizenid] or 0) + 1
    end
    CreateThread(expireLoop)
end)

AddEventHandler('playerJoining', function()
    local src = source
    SetTimeout(3000, function()
        local list = {}
        for _, note in pairs(notes) do list[#list + 1] = public(note) end
        TriggerClientEvent('sm_notepad:client:sync', src, list)
    end)
end)