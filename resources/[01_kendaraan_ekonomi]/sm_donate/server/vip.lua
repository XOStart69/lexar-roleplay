local utils = require 'server.utils'

local function vipRow(citizenid)
    return utils.db([[SELECT vip_type, TIMESTAMPDIFF(HOUR, NOW(), expires_at) AS hours
        FROM player_vip WHERE citizenid = ? AND expires_at > NOW()]], { citizenid })[1]
end

local function vipData(citizenid)
    local row = vipRow(citizenid)

    if not row then return { vip_type = nil, timeLeft = nil } end

    local hours = tonumber(row.hours) or 0

    return {
        vip_type = row.vip_type,
        timeLeft = ('%d hari %d jam'):format(math.floor(hours / 24), hours % 24),
    }
end

lib.callback.register('sm_donate:getVipData', function(source, withConfig)
    local cid = utils.citizen(source)

    if not cid then return nil end

    local data = vipData(cid)

    data.coins = utils.coins(cid)
    data.vipConfig = withConfig and VIP or nil
    data.categories = withConfig and VIP.Categories or nil

    return data
end)

local function findItem(category, name)
    for i = 1, #VIP.Categories do
        local cat = VIP.Categories[i]

        if cat.type == category then
            for j = 1, #cat.items do
                if cat.items[j].name == name then return cat.items[j] end
            end
        end
    end
end

lib.callback.register('sm_donate:buyItem', function(source, data)
    local cid = utils.citizen(source)
    local Player = utils.player(source)

    if not cid or not Player or type(data) ~= 'table' then return false, 'Data tidak valid' end

    local item = findItem(data.category, data.name)

    if not item then return false, 'Item tidak ditemukan' end

    local price = tonumber(item.price) or 0

    if not utils.takeCoins(cid, price) then return false, 'Coin tidak cukup' end

    if item.model then
        utils.deliverVehicle(source, Player, item.model, item.garage)
    else
        exports.ox_inventory:AddItem(source, item.name, 1)
    end

    if item.house then
        TriggerClientEvent('sm_donate:houseBought', source, item)
    end

    return true, ('%s dibeli'):format(item.label or item.name)
end)

lib.callback.register('sm_donate:validateCustomPlate', function(source, plate)
    if type(plate) ~= 'string' then return false end

    plate = plate:upper():gsub('%s+', '')

    if #plate < 3 or #plate > 8 then return false end

    local cid = utils.citizen(source) or ''

    return not utils.scalar('SELECT 1 FROM player_vehicles WHERE plate = ? AND citizenid <> ? LIMIT 1', { plate, cid }), plate
end)

lib.callback.register('sm_donate:redeemCode', function(source, data)
    local cid = utils.citizen(source)

    if not cid or type(data) ~= 'table' or type(data.code) ~= 'string' then return false, 'Kode tidak valid' end

    local code = data.code:upper():gsub('%s+', '')
    local row = utils.db('SELECT coins, vip_type, vip_days, uses, max_uses FROM sm_donate_codes WHERE code = ?', { code })[1]

    if not row then return false, 'Kode tidak ditemukan' end
    if row.max_uses > 0 and row.uses >= row.max_uses then return false, 'Kode sudah habis' end

    if utils.scalar('SELECT 1 FROM sm_donate_code_uses WHERE code = ? AND citizenid = ?', { code, cid }) then
        return false, 'Kamu sudah memakai kode ini'
    end

    utils.exec('INSERT INTO sm_donate_code_uses (code, citizenid) VALUES (?, ?)', { code, cid })
    utils.exec('UPDATE sm_donate_codes SET uses = uses + 1 WHERE code = ?', { code })

    if row.coins and row.coins > 0 then utils.addCoins(cid, row.coins) end

    if row.vip_type and row.vip_days and row.vip_days > 0 then
        utils.exec([[INSERT INTO player_vip (citizenid, vip_type, expires_at) VALUES (?, ?, DATE_ADD(NOW(), INTERVAL ? DAY))
            ON DUPLICATE KEY UPDATE expires_at = GREATEST(expires_at, NOW()) + INTERVAL ? DAY, vip_type = VALUES(vip_type)]], {
            cid, row.vip_type, row.vip_days, row.vip_days,
        })
    end

    return true, 'Kode berhasil dipakai'
end)

lib.callback.register('sm_donate:validateTestDrive', function(source, data)
    local cid = utils.citizen(source)

    if not cid or type(data) ~= 'table' or not data.model then return false end

    return true
end)

CreateThread(function()
    utils.exec([[CREATE TABLE IF NOT EXISTS sm_donate_codes (
        code VARCHAR(32) PRIMARY KEY,
        coins INT NOT NULL DEFAULT 0,
        vip_type VARCHAR(16) DEFAULT NULL,
        vip_days INT NOT NULL DEFAULT 0,
        uses INT NOT NULL DEFAULT 0,
        max_uses INT NOT NULL DEFAULT 0
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]])

    utils.exec([[CREATE TABLE IF NOT EXISTS sm_donate_code_uses (
        code VARCHAR(32) NOT NULL,
        citizenid VARCHAR(50) NOT NULL,
        PRIMARY KEY (code, citizenid)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]])
end)
