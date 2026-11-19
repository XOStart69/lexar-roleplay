--[[
    sm_notepad :: server
    Simpan catatan di metadata item, jatuhkan ke dunia lewat statebag global, beri ke pemain lain.
]]

local config = localmodule 'config'

local QBCore = exports['qb-core']:GetCoreObject()

local ITEM = config.item
local LIFETIME = config.lifetime or 10800
local MAX_PER_PLAYER = config.maxPerPlayer or 3
local MAX_TOTAL = config.maxTotal or 300
local COOLDOWN = config.actionCooldown or 750
local READ_DISTANCE = (config.readDistance or 2.0) + 2.0
local GIVE_DISTANCE = (config.giveDistance or 4.0) + 1.0

local SCHEMA = [[
CREATE TABLE IF NOT EXISTS `sm_notepad_notes` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `citizenid` varchar(64) NOT NULL,
    `text` text NOT NULL,
    `font` varchar(32) NOT NULL DEFAULT 'Arial',
    `x` float NOT NULL,
    `y` float NOT NULL,
    `z` float NOT NULL,
    `expires` bigint(20) NOT NULL,
    PRIMARY KEY (`id`),
    KEY `expires` (`expires`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
]]

local notes = {}
local cooldowns = {}

local function ply(src)
    return QBCore.Functions.GetPlayer(src)
end

local function notify(src, description, nType)
    lib.notify(src, { title = 'Catatan', description = description, type = nType or 'error' })
end

local function key(id)
    return ('smnote:%d'):format(id)
end

local function publish(note)
    GlobalState[key(note.id)] = { id = note.id, x = note.x, y = note.y, z = note.z }
end

local function unpublish(id)
    GlobalState[key(id)] = nil
end

local function clean(text, font)
    local body = type(text) == 'string' and text:sub(1, config.maxLength or 1500) or ''
    local face = type(font) == 'string' and font or config.defaultFont

    local valid = false
    for i = 1, #(config.fonts or {}) do
        if config.fonts[i] == face then
            valid = true
            break
        end
    end

    return body, valid and face or config.defaultFont
end

local function metadata(text, font)
    if text == '' then return { font = font } end
    return { text = text, font = font, label = config.writtenLabel }
end

local function invOf(player)
    return player.PlayerData.citizenid
end

local function noteSlot(player, slot)
    local item = exports.ox_inventory:GetSlot(invOf(player), tonumber(slot))
    if not item or item.name ~= ITEM then return end

    return item
end

local function cooldown(src)
    local now = GetGameTimer()
    if cooldowns[src] and now - cooldowns[src] < COOLDOWN then return false end

    cooldowns[src] = now
    return true
end

local function countOwned(citizenid)
    local row = MySQL.single.await('SELECT COUNT(*) AS total FROM sm_notepad_notes WHERE citizenid = ?', { citizenid })
    return row and tonumber(row.total) or 0
end

lib.callback.register('sm_notepad:getAll', function()
    local list = {}

    for id, note in pairs(notes) do
        list[#list + 1] = { id = id, x = note.x, y = note.y, z = note.z }
    end

    return list
end)

lib.callback.register('sm_notepad:read', function(src, id)
    local note = notes[tonumber(id)]
    if not note then return end

    local coords = GetEntityCoords(GetPlayerPed(src))
    if #(coords - vec3(note.x, note.y, note.z)) > READ_DISTANCE then return end

    return { text = note.text, font = note.font }
end)

lib.callback.register('sm_notepad:save', function(src, slot, text, font)
    local player = ply(src)
    if not player then return false end
    if not noteSlot(player, slot) then return false end

    local body, face = clean(text, font)

    return exports.ox_inventory:SetMetadata(invOf(player), tonumber(slot), metadata(body, face)) and true or false
end)

lib.callback.register('sm_notepad:drop', function(src, slot, text, font)
    local player = ply(src)
    if not player then return false, 'gone' end

    if not cooldown(src) then return false, 'cooldown' end
    if GetVehiclePedIsIn(GetPlayerPed(src), false) ~= 0 then return false, 'vehicle' end

    local item = noteSlot(player, slot)
    if not item then return false, 'gone' end

    local body, face = clean(text, font)
    if body == '' then return false, 'blank' end

    local citizenid = player.PlayerData.citizenid
    if countOwned(citizenid) >= MAX_PER_PLAYER then return false, 'limit' end

    local total = 0
    for _ in pairs(notes) do total = total + 1 end
    if total >= MAX_TOTAL then return false, 'full' end

    local coords = GetEntityCoords(GetPlayerPed(src))

    local id = MySQL.insert.await('INSERT INTO sm_notepad_notes (citizenid, text, font, x, y, z, expires) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        citizenid, body, face, coords.x, coords.y, coords.z + 0.0, os.time() + LIFETIME
    })

    if not id then return false, 'full' end

    exports.ox_inventory:RemoveItem(invOf(player), ITEM, 1, nil, tonumber(slot))

    local note = { id = id, citizenid = citizenid, text = body, font = face, x = coords.x, y = coords.y, z = coords.z }
    notes[id] = note
    publish(note)

    return true
end)

lib.callback.register('sm_notepad:give', function(src, slot, target, text, font)
    local player = ply(src)
    local other = ply(tonumber(target) or 0)

    if not player or not other then return false, 'gone' end
    if not cooldown(src) then return false, 'cooldown' end

    local item = noteSlot(player, slot)
    if not item then return false, 'gone' end

    local body, face = clean(text, font)

    local from = GetEntityCoords(GetPlayerPed(src))
    local to = GetEntityCoords(GetPlayerPed(other.PlayerData.source))

    if #(from - to) > GIVE_DISTANCE then return false, 'distance' end
    if not exports.ox_inventory:CanCarryItem(invOf(other), ITEM, 1) then return false, 'target_full' end

    exports.ox_inventory:RemoveItem(invOf(player), ITEM, 1, nil, tonumber(slot))

    if not exports.ox_inventory:AddItem(invOf(other), ITEM, 1, metadata(body, face)) then
        exports.ox_inventory:AddItem(invOf(player), ITEM, 1, metadata(body, face))
        return false, 'target_full'
    end

    TriggerClientEvent('sm_notepad:client:received', other.PlayerData.source)

    return true
end)

lib.callback.register('sm_notepad:pickup', function(src, id)
    local player = ply(src)
    if not player then return false, 'gone' end

    if not cooldown(src) then return false, 'cooldown' end

    local note = notes[tonumber(id)]
    if not note then return false, 'gone' end

    local coords = GetEntityCoords(GetPlayerPed(src))
    if #(coords - vec3(note.x, note.y, note.z)) > READ_DISTANCE then return false, 'distance' end

    if not exports.ox_inventory:CanCarryItem(invOf(player), ITEM, 1) then return false, 'target_full' end

    if not exports.ox_inventory:AddItem(invOf(player), ITEM, 1, metadata(note.text, note.font)) then
        return false, 'target_full'
    end

    notes[note.id] = nil
    unpublish(note.id)
    MySQL.update('DELETE FROM sm_notepad_notes WHERE id = ?', { note.id })

    return true
end)

CreateThread(function()
    MySQL.query.await(SCHEMA)

    local rows = MySQL.query.await('SELECT * FROM sm_notepad_notes WHERE expires > ?', { os.time() }) or {}

    for i = 1, #rows do
        local row = rows[i]
        local note = {
            id = row.id,
            citizenid = row.citizenid,
            text = row.text,
            font = row.font,
            x = row.x,
            y = row.y,
            z = row.z
        }

        notes[row.id] = note
        publish(note)
    end

    print(('^2[sm_notepad] %d catatan dimuat^7'):format(#rows))
end)

CreateThread(function()
    while true do
        Wait(config.cleanupInterval or 60000)

        local now = os.time()
        local expired = MySQL.query.await('SELECT id FROM sm_notepad_notes WHERE expires <= ?', { now }) or {}

        for i = 1, #expired do
            local id = expired[i].id
            notes[id] = nil
            unpublish(id)
        end

        if #expired > 0 then
            MySQL.update('DELETE FROM sm_notepad_notes WHERE expires <= ?', { now })
        end
    end
end)

AddEventHandler('playerDropped', function()
    cooldowns[source] = nil
end)