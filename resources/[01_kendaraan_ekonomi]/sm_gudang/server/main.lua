local QBCore = exports['qb-core']:GetCoreObject()

local function db(query, params)
    return exports.oxmysql:query(query, params or {})
end

CreateThread(function()
    db([[CREATE TABLE IF NOT EXISTS sm_gudang_rentals (
        citizenid VARCHAR(50) NOT NULL,
        stash_type VARCHAR(32) NOT NULL,
        expires_at DATETIME NOT NULL,
        PRIMARY KEY (citizenid, stash_type)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]])
end)

local function getPlayer(source)
    return QBCore.Functions.GetPlayer(source)
end

local function nearAny(source, list)
    local ped = GetPlayerPed(source)

    if not ped or ped == 0 then return false end

    local coords = GetEntityCoords(ped)

    for i = 1, #list do
        if #(coords - list[i].coords) <= (Config.MaxInteractDistance + 2.0) then
            return true
        end
    end

    return false
end

local function nearStash(source, stashType)
    local list = {}

    for i = 1, #Config.RentalLocations do
        local loc = Config.RentalLocations[i]

        if loc.stashType == stashType then list[#list + 1] = loc end
    end

    return nearAny(source, list)
end

local function getVip(source)
    local Player = getPlayer(source)

    if not Player then return nil end

    local meta = Player.PlayerData.metadata
    local vip = meta and (meta.vip or meta.vip_type)

    if type(vip) == 'string' and vip ~= '' then
        return { vip_type = vip:lower(), timeLeft = meta.vip_expires and tostring(meta.vip_expires) or 'Aktif' }
    end

    local ok, rows = pcall(db, [[SELECT vip_type, expires_at,
        TIMESTAMPDIFF(HOUR, NOW(), expires_at) AS hours
        FROM player_vip WHERE citizenid = ? AND expires_at > NOW()]], { Player.PlayerData.citizenid })

    if not ok or not rows or not rows[1] then return nil end

    local row = rows[1]
    local hours = tonumber(row.hours) or 0

    return {
        vip_type = tostring(row.vip_type):lower(),
        timeLeft = ('%d hari %d jam'):format(math.floor(hours / 24), hours % 24),
    }
end

local function stashId(stashType, citizenid)
    return ('gudang_%s_%s'):format(stashType, citizenid)
end

local function openStash(source, stashType)
    local Player = getPlayer(source)
    local cfg = Config.StashTypes[stashType]

    if not Player or not cfg then return false end

    local id = stashId(stashType, Player.PlayerData.citizenid)

    exports.ox_inventory:RegisterStash(id, cfg.label, cfg.slots, cfg.weight, Player.PlayerData.citizenid)
    TriggerClientEvent('ni_stash:client:openStash', source, id)

    return true
end

local function rentalRow(citizenid, stashType)
    local rows = db('SELECT expires_at, TIMESTAMPDIFF(DAY, NOW(), expires_at) AS days FROM sm_gudang_rentals WHERE citizenid = ? AND stash_type = ?', {
        citizenid,
        stashType,
    })

    return rows and rows[1] or nil
end

RegisterNetEvent('ni_stash:server:getStashStatus', function(stashType)
    local source = source
    local Player = getPlayer(source)
    local cfg = Config.StashTypes[stashType]

    if not Player or not cfg then return end
    if not nearStash(source, stashType) then return end

    local row = rentalRow(Player.PlayerData.citizenid, stashType)

    if not row then
        return TriggerClientEvent('ni_stash:client:receiveStashStatus', source, 'none', 0, stashType)
    end

    local days = tonumber(row.days) or 0

    if days <= 0 then
        return TriggerClientEvent('ni_stash:client:receiveStashStatus', source, 'expired', 0, stashType)
    end

    TriggerClientEvent('ni_stash:client:receiveStashStatus', source, 'active', days, stashType)
end)

RegisterNetEvent('ni_stash:server:rentStash', function(stashType, days)
    local source = source
    local Player = getPlayer(source)
    local cfg = Config.StashTypes[stashType]

    if not Player or not cfg then return end
    if not nearStash(source, stashType) then return end

    days = math.floor(tonumber(days) or 0)

    if days < cfg.minDays or days > cfg.maxDays then return end

    local row = rentalRow(Player.PlayerData.citizenid, stashType)
    local currentDays = row and math.max(tonumber(row.days) or 0, 0) or 0

    if currentDays + days > (cfg.maxTotalDays or cfg.maxDays) then
        return TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = ('Maksimal total sewa %d hari'):format(cfg.maxTotalDays or cfg.maxDays),
        })
    end

    local price = cfg.pricePerDay * days

    if not Player.Functions.RemoveMoney(Config.Currency, price, ('sewa %s'):format(cfg.label)) then
        return TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Uang tidak cukup',
        })
    end

    local base = currentDays > 0 and ('DATE_ADD(expires_at, INTERVAL ? DAY)') or 'DATE_ADD(NOW(), INTERVAL ? DAY)'

    db(([[INSERT INTO sm_gudang_rentals (citizenid, stash_type, expires_at)
        VALUES (?, ?, DATE_ADD(NOW(), INTERVAL ? DAY))
        ON DUPLICATE KEY UPDATE expires_at = %s]]):format(base), {
        Player.PlayerData.citizenid,
        stashType,
        days,
    })

    TriggerClientEvent('ox_lib:notify', source, {
        type = 'success',
        description = ('%s disewa %d hari'):format(cfg.label, days),
    })

    TriggerClientEvent('ni_stash:client:receiveStashStatus', source, 'active',
        math.min(currentDays + days, cfg.maxTotalDays or cfg.maxDays), stashType)
end)

RegisterNetEvent('ni_stash:server:openRentalStash', function(stashType)
    local source = source
    local Player = getPlayer(source)

    if not Player or not Config.StashTypes[stashType] then return end
    if not nearStash(source, stashType) then return end

    local row = rentalRow(Player.PlayerData.citizenid, stashType)

    if not row or (tonumber(row.days) or 0) <= 0 then
        return TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Sewa gudang sudah habis',
        })
    end

    openStash(source, stashType)
end)

RegisterNetEvent('ni_stash:server:getVipStatus', function()
    local source = source

    if not nearAny(source, Config.VipStashLocations) then return end

    TriggerClientEvent('ni_stash:client:showVipMenu', source, getVip(source))
end)

RegisterNetEvent('ni_stash:server:openVipStash', function(stashType)
    local source = source
    local cfg = Config.StashTypes[stashType]

    if not cfg or not cfg.requiresVip then return end
    if not nearAny(source, Config.VipStashLocations) then return end

    local vip = getVip(source)

    if not vip or vip.vip_type ~= cfg.requiresVip then
        return TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = ('Butuh status %s'):format(cfg.requiresVip:upper()),
        })
    end

    openStash(source, stashType)
end)

lib.print.info('sm_gudang server siap')
