--[[ sm_notepad / server.lua ]]

local config = localmodule 'config'

local ITEM = config.item
local TABLE = 'sm_notepad_notes'
local KEY = 'smnote:'

local notes = {}
local cooldowns = {}

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

local function within(a, b, dist)
    local pa, pb = GetPlayerPed(a), GetPlayerPed(b)
    if pa == 0 or pb == 0 then return false end
    return #(GetEntityCoords(pa) - GetEntityCoords(pb)) <= dist
end

local function cooldown(src)
    local last = cooldowns[src]
    if last and (GetGameTimer() - last) < config.actionCooldown then return false end
    cooldowns[src] = GetGameTimer()
    return true
end

local function getSlot(src, slot)
    local ok, item = pcall(function() return exports.ox_inventory:GetSlot(src, slot) end)
    if ok and item and item.name == ITEM then return item end
end

local function setMetadata(src, slot, meta)
    local ok = pcall(function() return exports.ox_inventory:SetMetadata(src, slot, meta) end)
    return ok
end

local function sanitizeText(text)
    if type(text) ~= 'string' then return '' end
    return text:sub(1, config.maxLength)
end

local function sanitizeFont(font)
    for _, entry in ipairs(config.fonts) do
        if entry == font then return font end
    end
    return config.defaultFont
end

local function countOwn(citizenid)
    return MySQL.scalar.await(('SELECT COUNT(*) FROM %s WHERE citizenid = ? AND expires_at > ?'):format(TABLE), { citizenid, now() }) or 0
end

local function publish(note)
    notes[note.id] = note
    GlobalState[KEY .. note.id] = { id = note.id, x = note.x, y = note.y, z = note.z }
end

local function unpublish(id)
    notes[id] = nil
    GlobalState[KEY .. id] = nil
end

local function cleanup()
    while true do
        Wait(config.cleanupInterval)
        local expired = MySQL.query.await(('SELECT id FROM %s WHERE expires_at <= ?'):format(TABLE), { now() })
        if expired and #expired > 0 then
            for _, row in ipairs(expired) do unpublish(row.id) end
            MySQL.update.await(('DELETE FROM %s WHERE expires_at <= ?'):format(TABLE), { now() })
        end
    end
end

lib.callback.register('sm_notepad:getAll', function()
    local rows = MySQL.query.await(('SELECT id, x, y, z FROM %s WHERE expires_at > ?'):format(TABLE), { now() })
    local out = {}
    for _, row in ipairs(rows or {}) do
        out[#out + 1] = { id = row.id, x = row.x, y = row.y, z = row.z }
    end
    return out
end)

lib.callback.register('sm_notepad:read', function(src, id)
    local note = notes[tonumber(id) or 0]
    if not note then return nil end

    local ped = GetPlayerPed(src)
    if ped == 0 then return nil end
    if #(GetEntityCoords(ped) - vector3(note.x, note.y, note.z)) > config.readDistance then return nil end

    return { text = note.text, font = note.font }
end)

lib.callback.register('sm_notepad:save', function(src, slot, text, font)
    slot = tonumber(slot)
    if not slot then return false end
    if not getSlot(src, slot) then return false end

    text = sanitizeText(text)
    font = sanitizeFont(font)

    local meta = { text = text, font = font }
    if text ~= '' then meta.label = config.writtenLabel end

    return setMetadata(src, slot, meta)
end)

lib.callback.register('sm_notepad:drop', function(src, slot, text, font)
    slot = tonumber(slot)
    if not slot then return false, 'gone' end
    if not cooldown(src) then return false, 'cooldown' end
    if not getSlot(src, slot) then return false, 'gone' end

    text = sanitizeText(text)
    if text == '' then return false, 'blank' end

    local ped = GetPlayerPed(src)
    if ped == 0 then return false, 'gone' end
    if GetVehiclePedIsIn(ped, false) ~= 0 then return false, 'vehicle' end
    if GetPlayerRoutingBucket(src) ~= 0 then return false, 'bucket' end

    local player = getPlayer(src)
    if not player then return false, 'gone' end

    if countOwn(player.PlayerData.citizenid) >= config.maxPerPlayer then return false, 'limit' end

    local total = MySQL.scalar.await(('SELECT COUNT(*) FROM %s WHERE expires_at > ?'):format(TABLE), { now() }) or 0
    if total >= config.maxTotal then return false, 'full' end

    local coords = GetEntityCoords(ped)
    local id = MySQL.insert.await(
        ('INSERT INTO %s (citizenid, text, font, x, y, z, created_at, expires_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)'):format(TABLE),
        { player.PlayerData.citizenid, text, sanitizeFont(font), coords.x, coords.y, coords.z, now(), now() + config.lifetime }
    )

    if not id then return false, 'gone' end

    pcall(function() exports.ox_inventory:RemoveItem(src, ITEM, 1, nil, slot) end)

    publish({ id = id, citizenid = player.PlayerData.citizenid, text = text, font = sanitizeFont(font), x = coords.x, y = coords.y, z = coords.z })
    return true
end)

lib.callback.register('sm_notepad:give', function(src, slot, target, text, font)
    slot = tonumber(slot)
    target = tonumber(target)
    if not slot or not target then return false, 'gone' end
    if not cooldown(src) then return false, 'cooldown' end
    if not getSlot(src, slot) then return false, 'gone' end

    text = sanitizeText(text)
    if text == '' then return false, 'blank' end

    local player = getPlayer(src)
    if not player or not getPlayer(target) then return false, 'gone' end
    if not within(src, target, config.giveDistance) then return false, 'distance' end

    local canCarry = pcall(function() return exports.ox_inventory:CanCarryItem(target, ITEM, 1) end)
    if not canCarry then return false, 'target_full' end

    local removed = pcall(function() return exports.ox_inventory:RemoveItem(src, ITEM, 1, nil, slot) end)
    if not removed then return false, 'gone' end

    local meta = { text = text, font = sanitizeFont(font), label = config.writtenLabel }
    local added = pcall(function() return exports.ox_inventory:AddItem(target, ITEM, 1, meta) end)

    if not added then
        pcall(function() exports.ox_inventory:AddItem(src, ITEM, 1, meta) end)
        return false, 'target_full'
    end

    TriggerClientEvent('sm_notepad:client:received', target)
    return true
end)

lib.callback.register('sm_notepad:pickup', function(src, id)
    id = tonumber(id)
    if not id then return false, 'gone' end
    if not cooldown(src) then return false, 'cooldown' end

    local note = notes[id]
    if not note then return false, 'gone' end

    local ped = GetPlayerPed(src)
    if ped == 0 then return false, 'gone' end
    if #(GetEntityCoords(ped) - vector3(note.x, note.y, note.z)) > config.readDistance then return false, 'distance' end

    local canCarry = pcall(function() return exports.ox_inventory:CanCarryItem(src, ITEM, 1) end)
    if not canCarry then return false, 'full' end

    local meta = { text = note.text, font = note.font, label = config.writtenLabel }
    local added = pcall(function() return exports.ox_inventory:AddItem(src, ITEM, 1, meta) end)
    if not added then return false, 'full' end

    MySQL.update.await(('DELETE FROM %s WHERE id = ?'):format(TABLE), { id })
    unpublish(id)
    return true
end)

AddEventHandler('playerDropped', function()
    cooldowns[source] = nil
end)

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end

    MySQL.query.await([[CREATE TABLE IF NOT EXISTS `sm_notepad_notes` (
        `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
        `citizenid` VARCHAR(50) NOT NULL,
        `text` TEXT NOT NULL,
        `font` VARCHAR(32) DEFAULT NULL,
        `x` FLOAT NOT NULL,
        `y` FLOAT NOT NULL,
        `z` FLOAT NOT NULL,
        `created_at` INT UNSIGNED NOT NULL,
        `expires_at` INT UNSIGNED NOT NULL,
        PRIMARY KEY (`id`),
        KEY `expires_at` (`expires_at`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;]])

    local rows = MySQL.query.await(('SELECT * FROM %s WHERE expires_at > ?'):format(TABLE), { now() })
    for _, row in ipairs(rows or {}) do
        publish({ id = row.id, citizenid = row.citizenid, text = row.text, font = row.font, x = row.x, y = row.y, z = row.z })
    end

    CreateThread(cleanup)
end)