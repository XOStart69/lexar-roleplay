--[[ sm_starterpack / server.lua ]]

local config = localmodule 'config'

local TABLE = 'sm_starterpack_claims'

local sessions = {}
local vCols

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

local function nearLocation(src)
    local ped = GetPlayerPed(src)
    if ped == 0 then return false end
    local coords = GetEntityCoords(ped)
    for _, loc in ipairs(config.locations) do
        if #(coords - vector3(loc.x, loc.y, loc.z)) <= config.claimRadius then return true end
    end
    return false
end

local function shuffle(list)
    for i = #list, 2, -1 do
        local j = math.random(i)
        list[i], list[j] = list[j], list[i]
    end
    return list
end

local function claimed(citizenid)
    return MySQL.scalar.await(('SELECT 1 FROM %s WHERE citizenid = ?'):format(TABLE), { citizenid }) ~= nil
end

local function vehicleColumns()
    if vCols then return vCols end
    local rows = MySQL.query.await('SHOW COLUMNS FROM player_vehicles')
    vCols = {}
    for _, row in ipairs(rows or {}) do vCols[row.Field] = true end
    return vCols
end

local function makePlate()
    local chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    for _ = 1, 25 do
        local plate = config.platePrefix
        for _ = 1, 5 do
            local i = math.random(#chars)
            plate = plate .. chars:sub(i, i)
        end
        if not MySQL.scalar.await('SELECT 1 FROM player_vehicles WHERE plate = ?', { plate }) then
            return plate
        end
    end
end

local function insertVehicle(citizenid, license, model, plate)
    local cols = vehicleColumns()
    local data = {
        citizenid = citizenid,
        license   = license,
        vehicle   = model,
        plate     = plate,
        garage    = config.garage,
        fuel      = config.fuel,
        state     = 1,
    }

    local names, marks, values = {}, {}, {}
    for name, value in pairs(data) do
        if cols[name] then
            names[#names + 1] = ('`%s`'):format(name)
            marks[#marks + 1] = '?'
            values[#values + 1] = value
        end
    end

    if #names == 0 then return false end

    local query = ('INSERT INTO player_vehicles (%s) VALUES (%s)'):format(
        table.concat(names, ', '), table.concat(marks, ', '))

    return MySQL.insert.await(query, values) ~= nil
end

lib.callback.register('sm_starterpack:server:start', function(src)
    local player = getPlayer(src)
    if not player then return { error = 'Karakter belum siap.' } end

    if claimed(player.PlayerData.citizenid) then
        return { error = 'Kamu sudah pernah mengambil starter pack.' }
    end

    if not nearLocation(src) then
        return { error = 'Terlalu jauh dari lokasi starter pack.' }
    end

    local list = {}
    for i, entry in ipairs(config.quiz) do
        local options = { entry.correct }
        for _, wrong in ipairs(entry.wrong) do options[#options + 1] = wrong end
        shuffle(options)

        list[i] = {
            question    = entry.question,
            description = entry.description,
            options     = options,
            answer      = entry.correct,
        }
    end

    sessions[src] = { questions = list, expires = os.time() + config.sessionSeconds }

    local payload = {}
    for i, entry in ipairs(list) do
        payload[i] = { question = entry.question, description = entry.description, options = entry.options }
    end

    return { questions = payload }
end)

lib.callback.register('sm_starterpack:server:claim', function(src, answers)
    local session = sessions[src]
    if not session then return { error = 'Sesi tidak ditemukan, coba lagi.' } end
    if session.expires < os.time() then
        sessions[src] = nil
        return { error = 'Sesi kuis kedaluwarsa, coba lagi.' }
    end
    if type(answers) ~= 'table' then return { error = 'Jawaban tidak valid.' } end

    local player = getPlayer(src)
    if not player then return { error = 'Karakter belum siap.' } end

    if not nearLocation(src) then return { error = 'Terlalu jauh dari lokasi starter pack.' } end

    local wrong = 0
    for i, entry in ipairs(session.questions) do
        if answers[i] ~= entry.answer then wrong = wrong + 1 end
    end

    if wrong > 0 then
        return { error = ('Masih ada %d jawaban salah. Ulangi kuis.'):format(wrong) }
    end

    local citizenid = player.PlayerData.citizenid
    local license = player.PlayerData.license

    local affected = MySQL.update.await(
        ('INSERT IGNORE INTO %s (citizenid, license, claimed_at) VALUES (?, ?, ?)'):format(TABLE),
        { citizenid, license, os.time() }
    )

    if affected == 0 then
        sessions[src] = nil
        return { error = 'Starter pack sudah pernah diambil.' }
    end

    local given = {}
    for _, entry in ipairs(config.items) do
        local ok = pcall(function()
            return exports.ox_inventory:AddItem(src, entry.name, entry.count)
        end)

        if not ok then
            for _, back in ipairs(given) do
                pcall(function() exports.ox_inventory:RemoveItem(src, back.name, back.count) end)
            end
            MySQL.update.await(('DELETE FROM %s WHERE citizenid = ?'):format(TABLE), { citizenid })
            return { error = 'Inventory penuh, klaim dibatalkan.' }
        end

        given[#given + 1] = entry
    end

    local model = config.vehicles[math.random(#config.vehicles)].model
    local plate = makePlate()
    local stored = plate ~= nil and insertVehicle(citizenid, license, model, plate)

    sessions[src] = nil

    if not stored then
        return { message = 'Starter pack diterima, tapi kendaraan gagal dicatat. Hubungi admin.' }
    end

    return { message = ('Starter pack diterima. %s (%s) menunggu di %s.'):format(model, plate, config.garage) }
end)

AddEventHandler('playerDropped', function()
    sessions[source] = nil
end)

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS `sm_starterpack_claims` (
        `citizenid` VARCHAR(50) NOT NULL,
        `license` VARCHAR(100) DEFAULT NULL,
        `claimed_at` INT UNSIGNED NOT NULL,
        PRIMARY KEY (`citizenid`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;]])
end)