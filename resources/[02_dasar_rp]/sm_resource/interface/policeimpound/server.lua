--[[
    policeimpound :: server
    Impound kendaraan oleh polisi: simpan properti kendaraan, denda, dan bukti foto.
    Pemilik bisa melihat daftar, bayar denda, lalu mengambil kendaraannya.
]]

local shared = localmodule 'config.shared'

local QBCore = exports['qb-core']:GetCoreObject()

local JOBS = shared.jobs or {}
local FINE_DEFAULT = 25000
local UNLOCK_FEE = 5000

local SCHEMA = [[
CREATE TABLE IF NOT EXISTS `sm_impound` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `plate` varchar(16) NOT NULL,
    `citizenid` varchar(64) NULL,
    `model` varchar(64) NOT NULL,
    `mods` longtext NULL,
    `impdata` longtext NULL,
    `officer` varchar(128) NULL,
    `photo` varchar(512) NULL,
    `location` int(11) NOT NULL DEFAULT 1,
    `fine` int(11) NOT NULL DEFAULT 0,
    `unlocked` tinyint(4) NOT NULL DEFAULT 0,
    `paid` tinyint(4) NOT NULL DEFAULT 0,
    `released` tinyint(4) NOT NULL DEFAULT 0,
    `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `plate` (`plate`),
    KEY `citizenid` (`citizenid`),
    KEY `released` (`released`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
]]

local function notify(src, message, nType)
    lib.notify(src, { description = message, type = nType or 'inform' })
end

local function ply(src)
    return QBCore.Functions.GetPlayer(src)
end

local function isPolice(src)
    local player = ply(src)
    local job = player and player.PlayerData.job
    if not job then return false end

    for i = 1, #JOBS do
        if JOBS[i] == job.name then return true end
    end

    return false
end

local function trim(plate)
    if type(plate) ~= 'string' then return nil end
    return (plate:gsub('^%s*(.-)%s*$', '%1'))
end

RegisterNetEvent('pimpound:impound', function(netId, impdata)
    local src = source
    if not isPolice(src) then return notify(src, 'Hanya polisi yang bisa mengimpound.', 'error') end

    local entity = NetworkGetEntityFromNetworkId(tonumber(netId) or 0)
    if not entity or entity == 0 then return end

    local props = lib.callback.await('pimpound:getprops', src, tonumber(netId))
    if not props then return notify(src, 'Gagal membaca data kendaraan.', 'error') end

    local plate = trim(props.plate) or trim(GetVehicleNumberPlateText(entity))
    local model = props.model and tostring(props.model) or tostring(GetEntityModel(entity))

    if not plate then return end

    local owner = MySQL.single.await('SELECT citizenid FROM player_vehicles WHERE plate = ?', { plate })
    local fine = tonumber(type(impdata) == 'table' and impdata.fine) or FINE_DEFAULT

    local id = MySQL.insert.await([[
        INSERT INTO sm_impound (plate, citizenid, model, mods, impdata, officer, photo, location, fine)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        plate,
        owner and owner.citizenid or nil,
        model,
        json.encode(props),
        json.encode(type(impdata) == 'table' and impdata or {}),
        type(impdata) == 'table' and tostring(impdata.officer or '') or '',
        type(impdata) == 'table' and tostring(impdata.photo or '') or '',
        tonumber(type(impdata) == 'table' and impdata.location) or 1,
        fine
    })

    if not id then return notify(src, 'Gagal menyimpan impound.', 'error') end

    MySQL.update.await('UPDATE player_vehicles SET state = 2 WHERE plate = ?', { plate })

    DeleteEntity(entity)

    TriggerClientEvent('pimpound:updateVehicle', -1, plate, {
        id = id,
        officer = type(impdata) == 'table' and impdata.officer or nil,
        fine = fine
    })

    notify(src, ('%s diimpound (denda $%s).'):format(plate, fine), 'success')

    local ownerSrc = owner and owner.citizenid and QBCore.Functions.GetPlayerByCitizenId(owner.citizenid)
    if ownerSrc and ownerSrc.PlayerData.source then
        notify(ownerSrc.PlayerData.source, ('Kendaraan %s kamu diimpound. Denda $%s.'):format(plate, fine), 'error')
    end
end)

lib.callback.register('pimpound:getlist', function(src)
    local player = ply(src)
    if not player then return {} end

    local rows

    if isPolice(src) then
        rows = MySQL.query.await('SELECT * FROM sm_impound WHERE released = 0 ORDER BY id DESC LIMIT 100') or {}
    else
        rows = MySQL.query.await('SELECT * FROM sm_impound WHERE citizenid = ? AND released = 0 ORDER BY id DESC', {
            player.PlayerData.citizenid
        }) or {}
    end

    local list = {}

    for i = 1, #rows do
        local row = rows[i]
        local impdata = {}

        local ok, decoded = pcall(json.decode, row.impdata or '')
        if ok and type(decoded) == 'table' then impdata = decoded end

        list[#list + 1] = {
            id = row.id,
            plate = row.plate,
            model = tonumber(row.model) or row.model,
            officer = row.officer,
            photo = row.photo,
            location = tonumber(row.location) or 1,
            fine = tonumber(row.fine) or 0,
            unlocked = tonumber(row.unlocked) == 1,
            paid = tonumber(row.paid) == 1,
            at = tostring(row.created_at),
            notes = impdata.notes or impdata.reason or ''
        }
    end

    return list
end)

lib.callback.register('pimpound:unlock', function(src, data)
    local id = tonumber(type(data) == 'table' and data.id or data)
    if not id then return false end

    local row = MySQL.single.await('SELECT * FROM sm_impound WHERE id = ? AND released = 0', { id })
    if not row then return false end
    if tonumber(row.unlocked) == 1 then return true end

    local player = ply(src)
    if not player then return false end

    local owner = player.PlayerData.citizenid == row.citizenid

    if not owner and not isPolice(src) then
        notify(src, 'Kendaraan ini bukan milikmu.', 'error')
        return false
    end

    if owner then
        if (player.PlayerData.money.cash or 0) < UNLOCK_FEE then
            notify(src, ('Butuh $%s untuk membuka data.'):format(UNLOCK_FEE), 'error')
            return false
        end

        player.Functions.RemoveMoney('cash', UNLOCK_FEE, 'impound-unlock')
    end

    MySQL.update.await('UPDATE sm_impound SET unlocked = 1 WHERE id = ?', { id })

    return true
end)

lib.callback.register('pimpound:payFine', function(src, data)
    local id = tonumber(type(data) == 'table' and data.id or data)
    if not id then return false end

    local row = MySQL.single.await('SELECT * FROM sm_impound WHERE id = ? AND released = 0', { id })
    if not row then return false end
    if tonumber(row.paid) == 1 then return true end

    local player = ply(src)
    if not player then return false end

    local fine = tonumber(row.fine) or 0
    local money = player.PlayerData.money

    if (money.bank or 0) >= fine then
        player.Functions.RemoveMoney('bank', fine, 'impound-fine')
    elseif (money.cash or 0) >= fine then
        player.Functions.RemoveMoney('cash', fine, 'impound-fine')
    else
        notify(src, ('Uang tidak cukup untuk denda $%s.'):format(fine), 'error')
        return false
    end

    MySQL.update.await('UPDATE sm_impound SET paid = 1, unlocked = 1 WHERE id = ?', { id })

    notify(src, 'Denda dibayar.', 'success')

    return true
end)

lib.callback.register('pimpound:release', function(src, data)
    local id = tonumber(type(data) == 'table' and data.id or data)
    if not id then return end

    local row = MySQL.single.await('SELECT * FROM sm_impound WHERE id = ? AND released = 0', { id })
    if not row then return end

    local player = ply(src)
    if not player then return end

    if tonumber(row.paid) ~= 1 then
        notify(src, 'Denda belum dibayar.', 'error')
        return
    end

    local owner = player.PlayerData.citizenid == row.citizenid
    if not owner and not isPolice(src) then
        notify(src, 'Kendaraan ini bukan milikmu.', 'error')
        return
    end

    local ok, mods = pcall(json.decode, row.mods or '')
    if not ok or type(mods) ~= 'table' then return end

    MySQL.update.await('UPDATE sm_impound SET released = 1 WHERE id = ?', { id })

    MySQL.update.await('UPDATE player_vehicles SET state = 0 WHERE plate = ?', { row.plate })

    mods.plate = row.plate

    return { index = tonumber(row.location) or 1, mods = mods }
end)

CreateThread(function()
    MySQL.query.await(SCHEMA)
end)

CreateThread(function()
    Wait(60000)

    while true do
        MySQL.update.await('DELETE FROM sm_impound WHERE released = 1 AND created_at < NOW() - INTERVAL 7 DAY')

        Wait(3600000)
    end
end)
