local utils = require 'server.utils'

local BOX = 'merdeka'

local function claimed(source)
    local cid = utils.citizen(source)

    if not cid then return {} end

    local set = {}
    local rows = utils.db('SELECT reward_index FROM sm_donate_claims WHERE citizenid = ? AND box = ?', { cid, BOX })

    for i = 1, #rows do set[rows[i].reward_index] = true end

    return set
end

lib.callback.register('sm_donate:merdekaOpen', function(source)
    local cid = utils.citizen(source)

    if not cid then return nil end

    return {
        rewards = Gacha.Merdeka and Gacha.Merdeka.Rewards or {},
        claimed = claimed(source),
    }
end)

lib.callback.register('sm_donate:merdekaCollect', function(source, data)
    local cid = utils.citizen(source)
    local Player = utils.player(source)

    if not cid or not Player or not data or not data.index then return false, 'Data tidak valid' end

    local index = tonumber(data.index)
    local list = Gacha.Merdeka and Gacha.Merdeka.Rewards or {}
    local reward = list[index]

    if not reward then return false, 'Hadiah tidak ada' end
    if claimed(source)[index] then return false, 'Sudah diambil' end

    utils.exec('INSERT IGNORE INTO sm_donate_claims (citizenid, box, reward_index) VALUES (?, ?, ?)', { cid, BOX, index })

    if reward.type == 'vehicle' and reward.model then
        utils.deliverVehicle(source, Player, reward.model, reward.garage)
    elseif reward.name then
        exports.ox_inventory:AddItem(source, reward.name, reward.amount or 1)
    end

    return true, ('%s diambil'):format(reward.label or 'Hadiah')
end)
