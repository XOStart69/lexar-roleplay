--[[
    sm_tcgcards :: server
    Serial per kartu, album per warga, gulir pack di server, degradasi berkala.
]]

local cfg = localmodule 'config'
local data = localmodule 'data.cards'

local ITEM = cfg.items.card or 'tcg_card'
local SLEEVE = cfg.items.sleeve or 'tcg_sleeve'
local GRADING = cfg.items.grading or 'tcg_grading'
local ADMIN = cfg.editor.group or 'group.admin'

local CLASSES = {}
for i = 1, #cfg.classes do CLASSES[cfg.classes[i].id] = cfg.classes[i] end

local QUALITY = cfg.quality or {}
local CONDITIONS = cfg.conditions or {}
local GRADES = cfg.grades or {}
local DEGRADE = cfg.degradation or {}
local PACK = cfg.pack or {}
local BOX = cfg.box or {}
local SLEEVE_CFG = cfg.sleeve or {}
local ALBUM_CFG = cfg.album or {}

local function loadCards()
    local raw = LoadResourceFile(GetCurrentResourceName(), 'data/cards.json')

    if raw then
        local ok, decoded = pcall(json.decode, raw)

        if ok and type(decoded) == 'table' then return decoded end
    end

    return data.cards or {}
end

local CARDS = loadCards()
local ARTIST = data.artist or ''

local CARDS_TABLE = 'tcg_cards'
local ALBUM_TABLE = 'tcg_albums'

local serial = 0
local catalogVersion = 1
local pendingPack = {}
local packStamp = {}
local boxStamp = {}

local RPC = {}

local function playerOf(src)
    return qb_ecore:GetPlayer(src)
end

local function notify(src, message, kind)
    TriggerClientEvent('ox_lib:notify', src, { description = message, type = kind or 'error' })
end

local function isAdmin(src)
    return IsPlayerAceAllowed(src, ADMIN)
end

local function rollQuality()
    local total = 0
    for i = 1, #QUALITY do total = total + QUALITY[i].weight end

    local pick = math.random() * total
    local acc = 0

    for i = 1, #QUALITY do
        acc = acc + QUALITY[i].weight
        if pick <= acc then
            return QUALITY[i].min + math.random() * (QUALITY[i].max - QUALITY[i].min)
        end
    end

    return QUALITY[1].min
end

local function conditionOf(quality)
    for i = 1, #CONDITIONS do
        if quality >= CONDITIONS[i].min then return CONDITIONS[i].id end
    end
    return CONDITIONS[#CONDITIONS].id
end

local function gradeOf(quality)
    for i = 1, #GRADES do
        if quality >= GRADES[i].min then return GRADES[i].grade end
    end
    return 1
end

local serialReady = false

local function ensureSerial()
    if serialReady then return end

    serialReady = true

    local max = MySQL.scalar.await('SELECT MAX(CAST(SUBSTRING_INDEX(serial, \'-\', -1) AS UNSIGNED)) FROM ' .. CARDS_TABLE)
    serial = math.max(serial, tonumber(max) or 0)
end

local function newSerial(division)
    ensureSerial()
    serial = serial + 1
    return ('TCG-%s-%06d'):format(division or 'DVA', serial)
end

local function cardByIndex(index)
    return CARDS[tonumber(index) or 0]
end

local function poolOf(division, class)
    local out = {}

    for i = 1, #CARDS do
        if CARDS[i].class == class and (not CARDS[i].division or CARDS[i].division == division) then
            out[#out + 1] = i
        end
    end

    return out
end

local DIVISIONS = {}
local DIVISION_LIST = {}
local DIVISION_BY_ITEM = {}

local function registerDivision(entry, code)
    if type(entry) ~= 'table' then return end

    entry.code = entry.code or code
    if not entry.code then return end

    local target = DIVISIONS[entry.code]

    if target then
        for name, div in pairs(DIVISION_BY_ITEM) do
            if div == target then DIVISION_BY_ITEM[name] = nil end
        end

        for k, v in pairs(entry) do target[k] = v end
    else
        target = entry
        DIVISIONS[entry.code] = target
        DIVISION_LIST[#DIVISION_LIST + 1] = target
    end

    if target.packItem then DIVISION_BY_ITEM[target.packItem] = target end
    if target.boxItem then DIVISION_BY_ITEM[target.boxItem] = target end
    if target.albumItem then DIVISION_BY_ITEM[target.albumItem] = target end

    return target
end

local function loadDivisions()
    local raw = LoadResourceFile(GetCurrentResourceName(), 'data/divisions.json')

    if raw then
        local ok, decoded = pcall(json.decode, raw)

        if ok and type(decoded) == 'table' then return decoded end
    end

    return cfg.divisions or {}
end

for key, entry in pairs(loadDivisions()) do
    registerDivision(entry, type(key) == 'string' and key or nil)
end

registerDivision(cfg.defaultDivision)

local function packDivision(itemName)
    return DIVISION_BY_ITEM[itemName]
end

local function divisionByCode(code)
    return DIVISIONS[code] or cfg.defaultDivision
end

local function rowsOf(cid)
    return MySQL.query.await('SELECT * FROM ' .. CARDS_TABLE .. ' WHERE owner = ? ORDER BY id ASC', { cid }) or {}
end

local function rowOf(serialId)
    return MySQL.single.await('SELECT * FROM ' .. CARDS_TABLE .. ' WHERE serial = ?', { tostring(serialId or '') })
end

local function packRow(row)
    local card = cardByIndex(row.card_index) or {}

    return {
        serial = row.serial,
        index = row.card_index,
        name = card.name,
        class = card.class,
        template = card.template,
        effect = card.effect,
        description = card.description,
        hp = card.hp,
        attack = card.attack,
        image = card.image,
        quality = row.quality,
        condition = row.condition,
        grade = row.grade,
        sleeved = row.sleeved == 1,
        albumSlot = row.album_slot,
    }
end

local function insertCard(cid, index, division)
    local quality = rollQuality()
    local s = newSerial(division)

    local id = MySQL.insert.await(
        ('INSERT INTO %s (serial, owner, card_index, division, quality, `condition`, grade, sleeved, created) VALUES (?, ?, ?, ?, ?, ?, ?, 0, ?)'):format(CARDS_TABLE),
        { s, cid, tonumber(index), division, quality, conditionOf(quality), gradeOf(quality), os.time() }
    )

    if not id then return nil end

    return s
end

RPC.catalog = function()
    local divisions = {}

    for i = 1, #DIVISION_LIST do
        if DIVISION_LIST[i].enabled ~= false then divisions[#divisions + 1] = DIVISION_LIST[i] end
    end

    return {
        version = catalogVersion,
        divisions = divisions,
        classes = cfg.classes,
        templates = cfg.templates,
        effects = cfg.effects,
        cards = CARDS,
        artist = ARTIST,
        quality = QUALITY,
    }
end

RPC['album:list'] = function(src)
    local player = playerOf(src)
    if not player then return {} end

    local rows = rowsOf(player.PlayerData.citizenid)
    local out = {}

    for i = 1, #rows do out[i] = packRow(rows[i]) end

    return out
end

RPC['album:info'] = function(src, division)
    local player = playerOf(src)
    if not player then return nil end

    local div = divisionByCode(division)
    if not div then return nil end

    local slots = {}

    local rows = MySQL.query.await(
        'SELECT a.slot, c.serial FROM ' .. ALBUM_TABLE .. ' a LEFT JOIN ' .. CARDS_TABLE .. ' c ON c.serial = a.serial WHERE a.citizenid = ? AND a.division = ?',
        { player.PlayerData.citizenid, div.code }
    ) or {}

    for i = 1, #rows do slots[rows[i].slot] = rows[i].serial end

    return { division = div, slots = slots, total = div.slots or 24 }
end

RPC['album:open'] = function(src, slot)
    local player = playerOf(src)
    if not player then return nil end

    local entry = ox_inventory:GetSlot(src, tonumber(slot) or 0)
    if not entry then return nil end

    local div = packDivision(entry.name)
    if not div or div.albumItem ~= entry.name then return nil end

    return RPC['album:info'](src, div.code)
end

RPC['album:insert'] = function(src, slot)
    local player = playerOf(src)
    if not player then return false, nil, nil end

    slot = tonumber(slot) or 0
    local rows = rowsOf(player.PlayerData.citizenid)
    local target

    for i = 1, #rows do
        if not rows[i].album_slot and (ALBUM_CFG.takesGraded or rows[i].grade == nil) then target = rows[i] break end
    end

    if not target then return false, nil, nil end

    MySQL.update('UPDATE ' .. CARDS_TABLE .. ' SET album_slot = ? WHERE id = ?', { slot, target.id })
    MySQL.insert(
        ('INSERT INTO %s (citizenid, division, slot, serial) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE serial = VALUES(serial)'):format(ALBUM_TABLE),
        { player.PlayerData.citizenid, target.division or 'DVA', slot, target.serial }
    )

    return true, packRow(target), cardByIndex(target.card_index) and cardByIndex(target.card_index).name
end

RPC['album:take'] = function(src, serialId)
    local player = playerOf(src)
    if not player then return false end

    local row = rowOf(serialId)
    if not row or row.owner ~= player.PlayerData.citizenid or not row.album_slot then return false end

    MySQL.update('DELETE FROM ' .. ALBUM_TABLE .. ' WHERE citizenid = ? AND serial = ?', { player.PlayerData.citizenid, row.serial })
    MySQL.update('UPDATE ' .. CARDS_TABLE .. ' SET album_slot = NULL WHERE id = ?', { row.id })

    return true
end

RPC['album:swap'] = function(src, from, to)
    local player = playerOf(src)
    if not player then return false end

    local cid = player.PlayerData.citizenid
    local a = MySQL.single.await('SELECT * FROM ' .. ALBUM_TABLE .. ' WHERE citizenid = ? AND slot = ?', { cid, tonumber(from) or 0 })
    local b = MySQL.single.await('SELECT * FROM ' .. ALBUM_TABLE .. ' WHERE citizenid = ? AND slot = ?', { cid, tonumber(to) or 0 })

    if not a then return false end

    MySQL.update('UPDATE ' .. ALBUM_TABLE .. ' SET slot = ? WHERE citizenid = ? AND serial = ?', { tonumber(to), cid, a.serial })
    if b then
        MySQL.update('UPDATE ' .. ALBUM_TABLE .. ' SET slot = ? WHERE citizenid = ? AND serial = ?', { tonumber(from), cid, b.serial })
    end

    return true
end

RPC['card:view'] = function(src, slot)
    local player = playerOf(src)
    if not player then return false, 'player_unavailable' end

    local entry = ox_inventory:GetSlot(src, tonumber(slot) or 0)
    if not entry or entry.name ~= ITEM then return false, 'card_unknown' end

    local row = rowOf(entry.metadata and entry.metadata.serial)
    if not row then return false, 'card_unknown' end

    return true, packRow(row)
end

RPC['card:sleeve'] = function(src, serialId)
    local player = playerOf(src)
    if not player then return false end

    local row = rowOf(serialId)
    if not row or row.owner ~= player.PlayerData.citizenid then return false end

    if row.sleeved == 1 then
        row.sleeved = 0
        if SLEEVE_CFG.reusable then ox_inventory:AddItem(src, SLEEVE, 1) end
    else
        if (ox_inventory:GetItemCount(src, SLEEVE) or 0) < 1 then return false end
        ox_inventory:RemoveItem(src, SLEEVE, 1)
        row.sleeved = 1
    end

    MySQL.update('UPDATE ' .. CARDS_TABLE .. ' SET sleeved = ? WHERE id = ?', { row.sleeved, row.id })

    return true, row.serial, ox_inventory:GetItemCount(src, SLEEVE) or 0
end

RPC['card:unsleeve'] = function(src, serialId)
    local player = playerOf(src)
    if not player then return false end

    local row = rowOf(serialId)
    if not row or row.owner ~= player.PlayerData.citizenid then return false end
    if row.sleeved ~= 1 then return true, row.serial, ox_inventory:GetItemCount(src, SLEEVE) or 0 end

    return RPC['card:sleeve'](src, serialId)
end

RPC['card:show'] = function(src, serialId)
    local player = playerOf(src)
    if not player then return false end

    local row = rowOf(serialId)
    if not row then return false end

    local coords = GetEntityCoords(GetPlayerPed(src))

    for _, raw in ipairs(GetPlayers()) do
        local target = tonumber(raw)
        if target ~= src and #(GetEntityCoords(GetPlayerPed(target)) - coords) <= (cfg.show.distance or 4.0) then
            TriggerClientEvent('sm_tcgcards:client:show', target, packRow(row), cfg.show.duration)
        end
    end

    return true
end

RPC['card:give'] = function(src, targetSrc, serialId)
    local player = playerOf(src)
    local target = playerOf(tonumber(targetSrc) or 0)
    if not player or not target then return false end

    if #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(GetPlayerPed(target.PlayerData.source))) > (cfg.give.distance or 3.0) then
        return false
    end

    local row = rowOf(serialId)
    if not row or row.owner ~= player.PlayerData.citizenid then return false end

    local slots = ox_inventory:Search(src, 'slots', ITEM) or {}
    local found

    for slot, entry in pairs(slots) do
        if entry.metadata and entry.metadata.serial == row.serial then found = slot break end
    end

    if not found then return false end
    if not ox_inventory:RemoveItem(src, ITEM, 1, nil, found) then return false end

    local ok = ox_inventory:AddItem(target.PlayerData.source, ITEM, 1, { serial = row.serial })

    if not ok then
        ox_inventory:AddItem(src, ITEM, 1, { serial = row.serial })
        return false, 'inventory_full'
    end

    MySQL.update('UPDATE ' .. CARDS_TABLE .. ' SET owner = ? WHERE id = ?', { target.PlayerData.citizenid, row.id })

    return true
end

local function rollPack(division)
    local picked = {}

    for i = 1, #(PACK.slots or {}) do
        local slot = PACK.slots[i]
        local total = 0
        for _, weight in pairs(slot) do total = total + weight end

        local pick = math.random() * total
        local acc, chosen = 0, nil

        for class, weight in pairs(slot) do
            acc = acc + weight
            if pick <= acc then chosen = class break end
        end

        chosen = chosen or PACK.fallbackClass

        local pool = poolOf(division, chosen)
        if #pool == 0 then pool = poolOf(division, PACK.fallbackClass) end

        local index = pool[math.random(#pool)]

        if PACK.noDuplicate then
            local tries = 0
            while index and picked[index] and tries < 20 do
                index = pool[math.random(#pool)]
                tries = tries + 1
            end
        end

        if index then picked[index] = true end
    end

    local list = {}
    for index in pairs(picked) do list[#list + 1] = index end

    return list
end

RPC['pack:open'] = function(src, slot)
    local player = playerOf(src)
    if not player then return false, 'player_unavailable' end

    local stamp = GetGameTimer()
    if packStamp[src] and stamp - packStamp[src] < (PACK.cooldown or 2000) then return false, 'pack_cooldown' end

    local entry = ox_inventory:GetSlot(src, tonumber(slot) or 0)
    if not entry then return false, 'pack_empty' end

    local division = packDivision(entry.name)
    if not division or division.packItem ~= entry.name then return false, 'pack_unknown' end

    packStamp[src] = stamp

    if not ox_inventory:RemoveItem(src, entry.name, 1, nil, entry.slot) then return false, 'pack_empty' end

    local indexes = rollPack(division.code)
    local serials = {}

    for i = 1, #indexes do
        local s = insertCard(player.PlayerData.citizenid, indexes[i], division.code)
        if s then serials[#serials + 1] = { serial = s, index = indexes[i] } end
    end

    if #serials == 0 then
        ox_inventory:AddItem(src, entry.name, 1)
        return false, 'pack_empty_pool'
    end

    pendingPack[src] = serials

    return true, #serials
end

RPC['pack:reveal'] = function(src)
    local list = pendingPack[src]
    if not list or #list == 0 then return nil end

    local index = table.remove(list, 1)
    if #list == 0 then pendingPack[src] = nil end

    local row = rowOf(index.serial)
    if not row then return nil end

    local ok = ox_inventory:AddItem(src, ITEM, 1, { serial = row.serial })

    if not ok then
        table.insert(list, 1, { serial = row.serial })
        pendingPack[src] = list
        return nil, 'inventory_full'
    end

    return packRow(row)
end

RPC['pack:claim'] = function(src)
    local list = pendingPack[src]
    if not list then return true, 0 end

    local given = 0

    for i = 1, #list do
        local row = rowOf(list[i].serial)

        if row and ox_inventory:AddItem(src, ITEM, 1, { serial = row.serial }) then
            given = given + 1
        else
            local rest = {}

            for j = i, #list do rest[#rest + 1] = list[j] end

            pendingPack[src] = rest

            return false, 'inventory_full'
        end
    end

    pendingPack[src] = nil
end

RPC['box:open'] = function(src, slot)
    local player = playerOf(src)
    if not player then return false, 'player_unavailable' end

    local stamp = GetGameTimer()
    if boxStamp[src] and stamp - boxStamp[src] < (BOX.cooldown or 2000) then return false, 'box_cooldown' end

    local entry = ox_inventory:GetSlot(src, tonumber(slot) or 0)
    if not entry then return false, 'box_empty' end

    local division = packDivision(entry.name)
    if not division or division.boxItem ~= entry.name then return false, 'box_unknown' end

    boxStamp[src] = stamp

    if not ox_inventory:RemoveItem(src, entry.name, 1, nil, entry.slot) then return false, 'box_empty' end

    local packs = BOX.packs or 10
    ox_inventory:AddItem(src, division.packItem, packs)

    return true, packs
end

RPC['grading:seal'] = function(src, serialId)
    local player = playerOf(src)
    if not player then return false end

    local row = rowOf(serialId)
    if not row or row.owner ~= player.PlayerData.citizenid then return false end
    if row.grade then return false end
    if (ox_inventory:GetItemCount(src, GRADING) or 0) < 1 then return false end

    ox_inventory:RemoveItem(src, GRADING, 1)

    local grade = gradeOf(row.quality)

    MySQL.update('UPDATE ' .. CARDS_TABLE .. ' SET grade = ? WHERE id = ?', { grade, row.id })

    return true, grade, row.quality, ox_inventory:GetItemCount(src, GRADING) or 0
end

local function bumpCatalog()
    catalogVersion = catalogVersion + 1
    GlobalState['sm_tcgcards:catalog'] = catalogVersion
end

local function saveCards()
    SaveResourceFile(GetCurrentResourceName(), 'data/cards.json', json.encode(CARDS), -1)
end

local function saveDivisions()
    SaveResourceFile(GetCurrentResourceName(), 'data/divisions.json', json.encode(DIVISIONS), -1)
end

local function divisionOfId(src, id)
    if not isAdmin(src) then return nil, 'not_admin' end
    if type(id) ~= 'string' then return nil, 'division_unknown' end

    local div = DIVISIONS[id]
    if not div then return nil, 'division_unknown' end

    return div
end

RPC['editor:division'] = function(src, payload)
    if not isAdmin(src) then return false, 'not_admin' end
    if type(payload) ~= 'table' then return false, 'division_unknown' end

    local code = payload.code or payload.id
    if not code then return false, 'division_unknown' end

    local div = registerDivision(payload, code)
    if not div then return false, 'division_unknown' end

    saveDivisions()
    bumpCatalog()

    return true, div
end

RPC['editor:divisionEnabled'] = function(src, id, enabled)
    local div, err = divisionOfId(src, id)
    if not div then return false, err end

    div.enabled = enabled and true or false
    saveDivisions()
    bumpCatalog()

    return true, div
end

RPC['editor:divisionDelete'] = function(src, id)
    local div, err = divisionOfId(src, id)
    if not div then return false, err end

    local used = 0

    for n = 1, #CARDS do
        if CARDS[n] and CARDS[n].division == div.code then used = used + 1 end
    end

    if used > 0 then return false, 'division_in_use' end

    DIVISIONS[id] = nil

    for name, entry in pairs(DIVISION_BY_ITEM) do
        if entry == div then DIVISION_BY_ITEM[name] = nil end
    end

    for i = #DIVISION_LIST, 1, -1 do
        if DIVISION_LIST[i] == div then table.remove(DIVISION_LIST, i) end
    end

    saveDivisions()
    bumpCatalog()

    return true, true
end

RPC['editor:divisionAdd'] = function(src, payload)
    if not isAdmin(src) then return false, 'not_admin' end
    if type(payload) ~= 'table' then return false, 'division_unknown' end

    local code = payload.code or payload.id
    if type(code) ~= 'string' or code == '' then return false, 'division_unknown' end
    if DIVISIONS[code] then return false, 'division_exists' end
    if payload.packItem and DIVISION_BY_ITEM[payload.packItem] then return false, 'division_item_taken' end

    local div = registerDivision(payload, code)
    if not div then return false, 'division_unknown' end

    saveDivisions()
    bumpCatalog()

    return true, div
end

RPC['editor:booster'] = function(src, id, booster)
    local div, err = divisionOfId(src, id)
    if not div then return false, err end

    div.booster = type(booster) == 'table' and booster or nil
    saveDivisions()
    bumpCatalog()

    return true, div
end

RPC['editor:boosterReset'] = function(src, id)
    local div, err = divisionOfId(src, id)
    if not div then return false, err end

    div.booster = nil
    saveDivisions()
    bumpCatalog()

    return true, div
end

RPC['editor:quality'] = function(src, id, quality)
    local div, err = divisionOfId(src, id)
    if not div then return false, err end

    div.quality = tonumber(quality) or div.quality
    saveDivisions()
    bumpCatalog()

    return true, div
end

RPC['editor:qualityReset'] = function(src, id)
    local div, err = divisionOfId(src, id)
    if not div then return false, err end

    div.quality = nil
    saveDivisions()
    bumpCatalog()

    return true, div
end

RPC['editor:card'] = function(src, payload)
    if not isAdmin(src) then return false, 'not_admin' end
    if type(payload) ~= 'table' then return false, 'card_unknown' end

    local card = cardByIndex(payload.id)
    if not card then return false, 'card_unknown' end

    for key, value in pairs(payload) do
        if key ~= 'id' then card[key] = value end
    end

    saveCards()
    bumpCatalog()

    return true, card
end

RPC['editor:cardDelete'] = function(src, id)
    if not isAdmin(src) then return false, 'not_admin' end

    local index = tonumber(id)
    if not cardByIndex(index) then return false, 'card_unknown' end

    local used = MySQL.scalar.await('SELECT COUNT(*) FROM ' .. CARDS_TABLE .. ' WHERE card_index = ?', { index })
    if used and used > 0 then return false, 'card_in_use' end

    table.remove(CARDS, index)

    MySQL.update('UPDATE ' .. CARDS_TABLE .. ' SET card_index = card_index - 1 WHERE card_index > ?', { index })

    saveCards()
    bumpCatalog()

    return true, true
end

RPC['editor:cardAdd'] = function(src, payload)
    if not isAdmin(src) then return nil, 'not_admin' end
    if type(payload) ~= 'table' then return nil, 'card_unknown' end
    if type(payload.name) ~= 'string' or payload.name == '' then return nil, 'card_unknown' end

    local card = { name = payload.name }

    for key, value in pairs(payload) do
        if key ~= 'id' then card[key] = value end
    end

    card.enabled = card.enabled ~= false

    CARDS[#CARDS + 1] = card

    saveCards()
    bumpCatalog()

    return true, #CARDS, card
end

RPC['editor:cardGive'] = function(src, index, quality)
    if not isAdmin(src) then return false, 'not_admin' end

    local player = playerOf(src)
    if not player then return false, 'player_unavailable' end

    local card = cardByIndex(index)
    if not card then return false, 'card_unknown' end

    local div = cfg.defaultDivision
    local s = insertCard(player.PlayerData.citizenid, tonumber(index), div and div.code or 'DVA')
    if not s then return false, 'insert_failed' end

    local q = tonumber(quality)
    if q then
        q = math.max(1.0, math.min(q, 100.0))
        MySQL.update('UPDATE ' .. CARDS_TABLE .. ' SET quality = ?, `condition` = ?, grade = ? WHERE serial = ?', { q, conditionOf(q), gradeOf(q), s })
    end

    if not ox_inventory:AddItem(src, ITEM, 1, { serial = s }) then
        MySQL.update('DELETE FROM ' .. CARDS_TABLE .. ' WHERE serial = ?', { s })
        return false, 'inventory_full'
    end

    return true, true
end

RegisterNetEvent('sm_tcgcards:album:close', function()
    -- album tidak menyimpan sesi di memori, event ini hanya penanda tutup
end)

RegisterNetEvent('sm_tcgcards:pull', function(id, name, ...)
    local src = source
    local handler = type(name) == 'string' and RPC[name] or nil

    if not handler then
        TriggerClientEvent('sm_tcgcards:push', src, id, nil)
        return
    end

    local result = table.pack(pcall(handler, src, ...))

    if not result[1] then
        print(('[sm_tcgcards] pull %s gagal: %s'):format(name, tostring(result[2])))
        TriggerClientEvent('sm_tcgcards:push', src, id, nil)
        return
    end

    TriggerClientEvent('sm_tcgcards:push', src, id, { result[2], result[3], result[4] })
end)

RegisterCommand('tcgcards', function(src)
    if src == 0 then return end
    if not isAdmin(src) then return end

    TriggerClientEvent('sm_tcgcards:editor:open', src)
end, false)

for name, handler in pairs(RPC) do
    lib.callback.register('sm_tcgcards:' .. name, handler)
end
