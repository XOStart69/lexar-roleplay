--[[
    sm_pets :: server/admin
    Panel Pet Manager: daftar semua pet dengan pencarian dan halaman, hapus, dan pulihkan.
]]

local Config = localmodule 'config.shared'
local S = SmPetsServer

local QBCore = exports['qb-core']:GetCoreObject()

local PER_PAGE = 20

local function isAdmin(src)
    if IsPlayerAceAllowed(src, 'admin') then return true end

    local player = QBCore.Functions.GetPlayer(src)
    local job = player and player.PlayerData.job
    local adminJobs = Config.AdminJobs or {}

    return job ~= nil and adminJobs[job.name] == true
end

local function addCommand(name, help)
    lib.addCommand(name, { help = help }, function(src)
        if not isAdmin(src) then
            return lib.notify(src, { description = 'Akses ditolak.', type = 'error' })
        end

        TriggerClientEvent('sm_pets:client:openAdmin', src)
    end)
end

addCommand(Config.Commands.manager or 'petmanager', 'Buka Pet Manager')

lib.callback.register('sm_pets:admin:list', function(src, search, page)
    if not isAdmin(src) then return nil end

    page = math.max(0, math.floor(tonumber(page) or 0))
    search = type(search) == 'string' and search:sub(1, 64) or ''

    local rows
    local total

    if search == '' then
        total = MySQL.scalar.await('SELECT COUNT(*) FROM sm_pets_pets') or 0
        rows = MySQL.query.await('SELECT * FROM sm_pets_pets ORDER BY id DESC LIMIT ? OFFSET ?', {
            PER_PAGE, page * PER_PAGE
        }) or {}
    else
        local like = '%' .. search .. '%'

        total = MySQL.scalar.await(
            'SELECT COUNT(*) FROM sm_pets_pets WHERE name LIKE ? OR citizenid LIKE ? OR type LIKE ?',
            { like, like, like }
        ) or 0

        rows = MySQL.query.await([[
            SELECT * FROM sm_pets_pets WHERE name LIKE ? OR citizenid LIKE ? OR type LIKE ?
            ORDER BY id DESC LIMIT ? OFFSET ?
        ]], { like, like, like, PER_PAGE, page * PER_PAGE }) or {}
    end

    local list = {}

    for i = 1, #rows do
        list[#list + 1] = {
            id = rows[i].id,
            citizenid = rows[i].citizenid,
            type = rows[i].type,
            name = rows[i].name,
            health = tonumber(rows[i].health) or 0,
            active = tonumber(rows[i].active) == 1
        }
    end

    return { rows = list, page = page, total = total }
end)

lib.callback.register('sm_pets:admin:delete', function(src, id)
    if not isAdmin(src) then return false end

    id = tonumber(id)
    if not id then return false end

    local row = S.cacheRows[id] or MySQL.single.await('SELECT * FROM sm_pets_pets WHERE id = ?', { id })
    if not row then return false end
    if tonumber(row.active) == 1 then return false end

    S.cacheRows[id] = nil
    MySQL.update.await('DELETE FROM sm_pets_pets WHERE id = ?', { id })

    return true
end)

lib.callback.register('sm_pets:admin:restore', function(src, id)
    if not isAdmin(src) then return false end

    id = tonumber(id)
    if not id then return false end

    local row = S.cacheRows[id] or MySQL.single.await('SELECT * FROM sm_pets_pets WHERE id = ?', { id })
    if not row then return false end
    if tonumber(row.active) == 1 then return false end

    row.health = 100
    row.hunger = 100
    row.thirst = 100
    row.stamina = 100
    row.happiness = 100
    row.mood = 'happy'

    S.cacheRows[id] = row
    S.save(row)

    return true
end)

lib.addCommand(Config.Commands.addpet or 'addpet', {
    help = 'Tambah pet ke pemain',
    params = {
        { name = 'id', type = 'number', help = 'ID pemain' },
        { name = 'type', type = 'string', help = 'ID jenis pet' }
    },
    restricted = 'admin'
}, function(src, args)
    local target = tonumber(args.id)
    if not target or not GetPlayerName(target) then
        return lib.notify(src, { description = 'Pemain tidak ditemukan.', type = 'error' })
    end

    local player = QBCore.Functions.GetPlayer(target)
    if not player then return end

    local entry
    local pets = localmodule 'config.pets'

    for i = 1, #pets do
        if pets[i].id == args.type then entry = pets[i] break end
    end

    if not entry then
        return lib.notify(src, { description = 'Jenis pet tidak dikenal.', type = 'error' })
    end

    local skills = {}
    for name, cfg in pairs((Config.K9 and Config.K9.skills) or {}) do
        skills[name] = cfg.default
    end

    MySQL.insert.await([[
        INSERT INTO sm_pets_pets (citizenid, type, name, species, model, health, k9, skills)
        VALUES (?, ?, ?, ?, ?, 100, ?, ?)
    ]], {
        player.PlayerData.citizenid, entry.id, entry.label, entry.species, entry.model,
        entry.k9 and 1 or 0, json.encode(skills)
    })

    lib.notify(src, { description = ('%s ditambahkan ke %s.'):format(entry.label, player.PlayerData.charinfo.firstname or args.id), type = 'success' })
end)

lib.addCommand(Config.Commands.delpet or 'delpet', {
    help = 'Hapus pet milik pemain berdasarkan ID pet',
    params = { { name = 'petid', type = 'number', help = 'ID pet' } },
    restricted = 'admin'
}, function(src, args)
    local id = tonumber(args.petid)
    if not id then return end

    local row = MySQL.single.await('SELECT active FROM sm_pets_pets WHERE id = ?', { id })
    if not row then
        return lib.notify(src, { description = 'Pet tidak ditemukan.', type = 'error' })
    end

    if tonumber(row.active) == 1 then
        return lib.notify(src, { description = 'Simpan pet dulu sebelum dihapus.', type = 'error' })
    end

    S.cacheRows[id] = nil
    MySQL.update.await('DELETE FROM sm_pets_pets WHERE id = ?', { id })

    lib.notify(src, { description = 'Pet dihapus.', type = 'success' })
end)