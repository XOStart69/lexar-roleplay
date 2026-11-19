--[[
    sm_scenes :: server
    Kuota per pemain, jarak, durasi, validasi style. Penghapusan berbasis progres.
]]

local config = localmodule 'config'

local WRITE_ITEM = config.writeItem or 'spidol'
local ERASE_ITEM = config.eraseItem or 'penghapus'
local ADMIN_ACE = config.adminAce or 'admin'
local FREE_ACE = config.freeAce or 'group.god'

local MAX_DISTANCE = config.maxDistance or 25.0
local MAX_SCENES = config.maxScenes or 5
local MAX_DURATION = config.maxDuration or 50
local MAX_TEXT = config.maxText or 160
local BULK_RADIUS = config.maxBulkRadius or 50.0
local ERASE_RADIUS = config.eraseRadius or 3.0
local WRITE_MS = config.writeMs or 3000
local ERASE_MS = config.eraseMs or 2500

local FONTS, BACKGROUNDS = {}, {}
for i = 1, #(config.fonts or {}) do FONTS[config.fonts[i].key] = true end
for i = 1, #(config.backgrounds or {}) do BACKGROUNDS[config.backgrounds[i].key] = true end

local TABLE = 'sm_scenes'

local scenes = {}
local pendingBulk = {}
local erasing = {}
local nextId = 0

local function playerOf(src)
    return qb_ecore:GetPlayer(src)
end

local function isAdmin(src)
    return IsPlayerAceAllowed(src, ADMIN_ACE)
end

local function freeAccess(src)
    return IsPlayerAceAllowed(src, FREE_ACE)
end

local function notify(src, message, kind)
    TriggerClientEvent('ox_lib:notify', src, { description = message, type = kind or 'error' })
end

local function ownedCount(cid)
    local total = 0
    for _ , scene in pairs(scenes) do
        if scene.owner == cid then total = total + 1 end
    end
    return total
end

local function broadcast(event, ...)
    for _, raw in ipairs(GetPlayers()) do
        TriggerClientEvent(event, tonumber(raw), ...)
    end
end

local function pack(scene)
    return {
        id = scene.id,
        coords = scene.coords,
        style = scene.style,
        duration = scene.duration,
        neverExpire = scene.neverExpire,
        expires = scene.expires,
    }
end

local function sanitizeStyle(style)
    if type(style) ~= 'table' then return nil end

    local text = tostring(style.text or ''):sub(1, MAX_TEXT)
    if text == '' then return nil end

    local font = tostring(style.font or '')
    if not FONTS[font] then return nil end

    local background = tostring(style.background or 'none')
    if not BACKGROUNDS[background] then background = 'none' end

    return {
        text = text,
        font = font,
        colour = tostring(style.colour or '#ffffff'):sub(1, 9),
        fontSize = math.min(math.max(tonumber(style.fontSize) or 0.3, 0.05), 2.0),
        viewDistance = math.min(math.max(tonumber(style.viewDistance) or 10.0, 1.0), 100.0),
        shadow = style.shadow == true,
        outline = style.outline == true,
        background = background,
        backgroundColour = tostring(style.backgroundColour or '#000000'):sub(1, 9),
        backgroundAlpha = math.min(math.max(tonumber(style.backgroundAlpha) or 160, 0), 255),
        backgroundX = tonumber(style.backgroundX) or 0.0,
        backgroundY = tonumber(style.backgroundY) or 0.034,
        backgroundWidth = tonumber(style.backgroundWidth) or 0.01,
        backgroundHeight = tonumber(style.backgroundHeight) or 0.01,
    }
end

local function insert(src, coords, style, duration, neverExpire)
    local player = playerOf(src)
    if not player then return { ok = false, message = 'Data pemain tidak siap.' } end

    local admin = isAdmin(src)

    if not admin and not freeAccess(src) then
        if (ox_inventory:GetItemCount(src, WRITE_ITEM) or 0) < 1 then
            return { ok = false, message = ('Butuh %s.'):format(WRITE_ITEM) }
        end
    end

    if #(GetEntityCoords(GetPlayerPed(src)) - coords) > MAX_DISTANCE then
        return { ok = false, message = 'Terlalu jauh.' }
    end

    local cid = player.PlayerData.citizenid
    if not admin and ownedCount(cid) >= MAX_SCENES then
        return { ok = false, message = ('Batas %d scene.'):format(MAX_SCENES) }
    end

    duration = math.floor(tonumber(duration) or config.defaults.duration or 12)
    duration = math.min(math.max(duration, 1), MAX_DURATION)
    if admin then neverExpire = neverExpire == true end

    local clean = sanitizeStyle(style)
    if not clean then return { ok = false, message = 'Style tidak valid.' } end

    nextId = nextId + 1

    local scene = {
        id = nextId,
        owner = cid,
        coords = coords,
        style = clean,
        duration = duration,
        neverExpire = neverExpire == true,
        expires = (neverExpire == true) and nil or (os.time() + duration),
    }

    scenes[scene.id] = scene

    MySQL.insert('INSERT INTO ' .. TABLE .. ' (owner, x, y, z, style, duration, never_expire, created) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
        cid, coords.x, coords.y, coords.z, json.encode(clean), duration, scene.neverExpire and 1 or 0, os.time(),
    })

    broadcast('sm_scenes:client:add', pack(scene))

    return { ok = true }
end

lib.callback.register('sm_scenes:server:context', function(src)
    local player = playerOf(src)
    if not player then return nil end

    return {
        admin = isAdmin(src),
        used = ownedCount(player.PlayerData.citizenid),
        max = MAX_SCENES,
    }
end)

lib.callback.register('sm_scenes:server:create', function(src, coords, style, duration, neverExpire)
    if type(coords) ~= 'table' then return { ok = false, message = 'Koordinat kosong.' } end

    local pos = vector3(tonumber(coords.x) or 0.0, tonumber(coords.y) or 0.0, tonumber(coords.z) or 0.0)

    if erasing[src] then return { ok = false, message = 'Sedang menghapus.' } end

    return insert(src, pos, style, duration, neverExpire)
end)

RegisterNetEvent('sm_scenes:server:sync', function()
    local src = source
    local list = {}

    for _, scene in pairs(scenes) do
        list[#list + 1] = pack(scene)
    end

    TriggerClientEvent('sm_scenes:client:all', src, list)
end)

RegisterNetEvent('sm_scenes:server:erase', function(finished)
    local src = source
    local player = playerOf(src)
    if not player then return end

    if not finished then
        if not erasing[src] then
            erasing[src] = true
            TriggerClientEvent('sm_scenes:client:erase', src, ERASE_MS)
        end
        return
    end

    erasing[src] = nil

    local admin = isAdmin(src)
    local cid = player.PlayerData.citizenid
    local coords = GetEntityCoords(GetPlayerPed(src))
    local removed = {}

    for id, scene in pairs(scenes) do
        if scene.owner == cid or admin then
            if #(coords - scene.coords) <= ERASE_RADIUS then
                removed[#removed + 1] = id
                scenes[id] = nil
                MySQL.update('DELETE FROM ' .. TABLE .. ' WHERE id = ?', { id })
            end
        end
    end

    if #removed > 0 then broadcast('sm_scenes:client:remove', removed) end
end)

RegisterNetEvent('sm_scenes:server:confirmBulk', function(texts)
    local src = source
    local player = playerOf(src)
    if not player then return end

    local list = type(texts) == 'table' and texts or pendingBulk[src]
    if not list or #list == 0 then return notify(src, 'Tidak ada teks.') end

    local coords = GetEntityCoords(GetPlayerPed(src))
    local created, failed = 0, 0

    for i = 1, #list do
        local text = tostring(list[i] or '')
        if text ~= '' then
            local angle = math.random() * math.pi * 2
            local radius = math.random() * BULK_RADIUS
            local point = vector3(coords.x + math.cos(angle) * radius, coords.y + math.sin(angle) * radius, coords.z)

            local style = {}
            for key, value in pairs(config.defaults) do style[key] = value end
            style.text = text

            if insert(src, point, style, config.defaults.duration, false).ok then
                created = created + 1
            else
                failed = failed + 1
            end
        end
    end

    pendingBulk[src] = nil
    notify(src, ('%d dipasang, %d gagal.'):format(created, failed), created > 0 and 'success' or 'error')
end)

CreateThread(function()
    MySQL.query.await(([[
    CREATE TABLE IF NOT EXISTS `%s` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `owner` varchar(64) NOT NULL,
        `x` double NOT NULL,
        `y` double NOT NULL,
        `z` double NOT NULL,
        `style` longtext NOT NULL,
        `duration` int(11) NOT NULL,
        `never_expire` tinyint(1) NOT NULL DEFAULT 0,
        `created` int(11) NOT NULL,
        PRIMARY KEY (`id`),
        KEY `owner` (`owner`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]]):format(TABLE))

    local rows = MySQL.query.await('SELECT * FROM ' .. TABLE) or {}

    for i = 1, #rows do
        local row = rows[i]
        nextId = math.max(nextId, row.id)

        scenes[row.id] = {
            id = row.id,
            owner = row.owner,
            coords = vector3(row.x, row.y, row.z),
            style = json.decode(row.style or '{}'),
            duration = row.duration,
            neverExpire = row.never_expire == 1,
            expires = row.never_expire == 1 and nil or (row.created + row.duration),
        }
    end

    while true do
        Wait(1000)
        local stamp = os.time()
        local gone = {}

        for id, scene in pairs(scenes) do
            if not scene.neverExpire and scene.expires and scene.expires <= stamp then
                gone[#gone + 1] = id
                scenes[id] = nil
                MySQL.update('DELETE FROM ' .. TABLE .. ' WHERE id = ?', { id })
            end
        end

        if #gone > 0 then broadcast('sm_scenes:client:remove', gone) end
    end
end)

AddEventHandler('playerDropped', function()
    pendingBulk[source] = nil
    erasing[source] = nil
end)

print('^2[sm_scenes] server siap^7')