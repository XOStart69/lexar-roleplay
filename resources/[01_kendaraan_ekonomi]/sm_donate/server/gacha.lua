local utils = require 'server.utils'

local function ownedList(citizenid)
    return utils.db([[SELECT id, case_id, item_name, label, tier, is_vehicle
        FROM sm_donate_gacha WHERE citizenid = ? AND collected = 0 AND sold = 0
        ORDER BY id DESC]], { citizenid })
end

lib.callback.register('sm_donate:gachaGetData', function(source, withConfig)
    local cid = utils.citizen(source)

    if not cid then return nil end

    return {
        coins = utils.coins(cid),
        items = ownedList(cid),
        config = withConfig and Gacha or nil,
        cases = withConfig and Gacha.Cases or nil,
        sellPrices = Settings.SellCoinsPerTier,
    }
end)

local function roll(source, case, paidWith)
    local cid = utils.citizen(source)

    if not cid then return false, 'Karakter tidak ditemukan' end

    local item = utils.rollCase(case)

    utils.insert([[
        INSERT INTO sm_donate_gacha (citizenid, case_id, item_name, label, tier, is_vehicle)
        VALUES (?, ?, ?, ?, ?, ?)
    ]], {
        cid,
        case.id,
        item.name or item.model or 'unknown',
        item.label or item.name or 'Hadiah',
        item.tier or 'common',
        (item.isVehicle or item.type == 'vehicle') and 1 or 0,
    })

    return true, item
end

lib.callback.register('sm_donate:gachaOpenCase', function(source, data)
    local cid = utils.citizen(source)

    if not cid or type(data) ~= 'table' then return false, 'Data tidak valid' end

    local case = utils.findCase(data.caseId or data.id)

    if not case then return false, 'Case tidak ditemukan' end

    local price = tonumber(case.price) or 0

    if price > 0 and not utils.takeCoins(cid, price) then return false, 'Coin tidak cukup' end

    local ok, item = roll(source, case)

    if not ok then return false, item end

    TriggerClientEvent('sm_donate:gachaNotify', source, item)

    return true, item
end)

lib.callback.register('sm_donate:gachaOpenCaseWithItem', function(source, data)
    local cid = utils.citizen(source)

    if not cid or type(data) ~= 'table' then return false, 'Data tidak valid' end

    local case = utils.findCase(data.caseId or data.id)

    if not case then return false, 'Case tidak ditemukan' end

    local ticket = case.ticket or case.item

    if ticket then
        local count = exports.ox_inventory:Search(source, 'count', ticket)

        if not count or count < 1 then return false, 'Tiket tidak cukup' end

        exports.ox_inventory:RemoveItem(source, ticket, 1)
    end

    local ok, item = roll(source, case)

    if not ok then return false, item end

    TriggerClientEvent('sm_donate:gachaNotify', source, item)

    return true, item
end)

lib.callback.register('sm_donate:gachaCollectItem', function(source, data)
    local cid = utils.citizen(source)
    local Player = utils.player(source)

    if not cid or not Player or not data or not data.id then return false, 'Data tidak valid' end

    local row = utils.db([[SELECT id, item_name, label, is_vehicle
        FROM sm_donate_gacha WHERE id = ? AND citizenid = ? AND collected = 0 AND sold = 0]], {
        tonumber(data.id), cid,
    })[1]

    if not row then return false, 'Hadiah tidak ditemukan' end

    if row.is_vehicle == 1 then
        utils.deliverVehicle(source, Player, row.item_name, data.garage)
    elseif Settings.GiveItemOnCollect then
        if not exports.ox_inventory:AddItem(source, row.item_name, 1) then
            return false, 'Inventory penuh'
        end
    end

    utils.exec('UPDATE sm_donate_gacha SET collected = 1 WHERE id = ?', { row.id })

    return true, ('%s diambil'):format(row.label)
end)

lib.callback.register('sm_donate:gachaSellItem', function(source, data)
    local cid = utils.citizen(source)

    if not cid or not data or not data.id then return false, 'Data tidak valid' end

    local row = utils.db('SELECT id, label, tier FROM sm_donate_gacha WHERE id = ? AND citizenid = ? AND collected = 0 AND sold = 0', {
        tonumber(data.id), cid,
    })[1]

    if not row then return false, 'Hadiah tidak ditemukan' end

    local price = Settings.SellCoinsPerTier[row.tier] or 0

    if price <= 0 then return false, 'Hadiah ini tidak bisa dijual' end

    utils.exec('UPDATE sm_donate_gacha SET sold = 1 WHERE id = ?', { row.id })
    utils.addCoins(cid, price)

    return true, ('%s dijual, +%d coin'):format(row.label, price)
end)
