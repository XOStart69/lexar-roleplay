local utils = require 'server.utils'

local EXP_PER_LEVEL = 100

local function ensure(citizenid)
    utils.exec('INSERT IGNORE INTO sm_donate_bp (citizenid) VALUES (?)', { citizenid })
end

local function profile(citizenid)
    ensure(citizenid)

    return utils.db('SELECT level, exp, premium FROM sm_donate_bp WHERE citizenid = ?', { citizenid })[1]
end

local function claimedSet(citizenid, box)
    local set = {}
    local rows = utils.db('SELECT reward_index FROM sm_donate_claims WHERE citizenid = ? AND box = ?', { citizenid, box })

    for i = 1, #rows do set[rows[i].reward_index] = true end

    return set
end

lib.callback.register('sm_donate:getBattlepassData', function(source, withConfig)
    local cid = utils.citizen(source)

    if not cid then return nil end

    local p = profile(cid)

    return {
        level = p.level,
        exp = p.exp,
        expMax = EXP_PER_LEVEL,
        premium = p.premium == 1,
        claimedStandart = claimedSet(cid, 'bp_standart'),
        claimedPremium = claimedSet(cid, 'bp_premium'),
        config = withConfig and Battlepass or nil,
    }
end)

lib.callback.register('sm_donate:bpGetStandartReward', function(source, data)
    local cid = utils.citizen(source)
    local Player = utils.player(source)

    if not cid or not Player or not data or not data.level then return false, 'Data tidak valid' end

    local level = tonumber(data.level)
    local p = profile(cid)

    if level > p.level then return false, 'Level belum tercapai' end
    if claimedSet(cid, 'bp_standart')[level] then return false, 'Sudah diambil' end

    local reward = Battlepass.Rewards.Standart[level]

    if not reward then return false, 'Reward kosong' end

    utils.exec('INSERT IGNORE INTO sm_donate_claims (citizenid, box, reward_index) VALUES (?, ?, ?)', { cid, 'bp_standart', level })

    if reward.carData and reward.carData.model then
        utils.deliverVehicle(source, Player, reward.carData.model, reward.carData.garage)
    end

    if reward.rewards then
        for i = 1, #reward.rewards do
            local r = reward.rewards[i]

            if r.type == 'vehicle' and r.model then
                utils.deliverVehicle(source, Player, r.model, r.garage)
            elseif r.name then
                exports.ox_inventory:AddItem(source, r.name, r.amount or 1)
            end
        end
    end

    return true, 'Reward diambil'
end)

lib.callback.register('sm_donate:bpGetPremiumReward', function(source, data)
    local cid = utils.citizen(source)
    local Player = utils.player(source)

    if not cid or not Player or not data or not data.level then return false, 'Data tidak valid' end

    local level = tonumber(data.level)
    local p = profile(cid)

    if p.premium ~= 1 then return false, 'Battlepass premium tidak aktif' end
    if level > p.level then return false, 'Level belum tercapai' end
    if claimedSet(cid, 'bp_premium')[level] then return false, 'Sudah diambil' end

    local reward = Battlepass.Rewards.Premium[level]

    if not reward then return false, 'Reward kosong' end

    utils.exec('INSERT IGNORE INTO sm_donate_claims (citizenid, box, reward_index) VALUES (?, ?, ?)', { cid, 'bp_premium', level })

    if reward.carData and reward.carData.model then
        utils.deliverVehicle(source, Player, reward.carData.model, reward.carData.garage)
    end

    if reward.rewards then
        for i = 1, #reward.rewards do
            local r = reward.rewards[i]

            if r.type == 'vehicle' and r.model then
                utils.deliverVehicle(source, Player, r.model, r.garage)
            elseif r.name then
                exports.ox_inventory:AddItem(source, r.name, r.amount or 1)
            end
        end
    end

    return true, 'Reward diambil'
end)

local function taskDone(source, kind, data)
    local cid = utils.citizen(source)

    if not cid or not data or not data.taskId then return false end

    local taskId = tonumber(data.taskId)

    utils.exec([[INSERT INTO sm_donate_bp_tasks (citizenid, kind, task_id, count, done) VALUES (?, ?, ?, 0, 1)
        ON DUPLICATE KEY UPDATE done = 1]], { cid, kind, taskId })

    local p = profile(cid)
    local exp = p.exp + 25
    local level = p.level

    while exp >= EXP_PER_LEVEL do
        exp -= EXP_PER_LEVEL
        level += 1
    end

    utils.exec('UPDATE sm_donate_bp SET exp = ?, level = ? WHERE citizenid = ?', { exp, level, cid })

    return true
end

lib.callback.register('sm_donate:bpStandartTaskDone', function(source, data)
    return taskDone(source, 'standart', data)
end)

lib.callback.register('sm_donate:bpPremiumTaskDone', function(source, data)
    return taskDone(source, 'premium', data)
end)

lib.callback.register('sm_donate:bpSendInput', function(source, data)
    local cid = utils.citizen(source)

    if not cid or not data or not data.taskId then return false end

    utils.exec([[INSERT INTO sm_donate_bp_tasks (citizenid, kind, task_id, count, done) VALUES (?, 'standart', ?, 1, 0)
        ON DUPLICATE KEY UPDATE count = count + 1]], { cid, tonumber(data.taskId) })

    TriggerClientEvent('sm_donate:bpAddTaskCount:standart', source, tonumber(data.taskId))

    return true

end)

RegisterNetEvent('sm_donate:bpTaskCountAdd:standart', function(taskId)
    local cid = utils.citizen(source)

    if not cid or not taskId then return end

    utils.exec([[INSERT INTO sm_donate_bp_tasks (citizenid, kind, task_id, count, done) VALUES (?, 'standart', ?, 1, 0)
        ON DUPLICATE KEY UPDATE count = count + 1]], { cid, tonumber(taskId) })

    TriggerClientEvent('sm_donate:bpAddTaskCount:standart', source, tonumber(taskId))
end)

RegisterNetEvent('sm_donate:bpTaskCountAdd:premium', function(taskId)
    local cid = utils.citizen(source)

    if not cid or not taskId then return end

    utils.exec([[INSERT INTO sm_donate_bp_tasks (citizenid, kind, task_id, count, done) VALUES (?, 'premium', ?, 1, 0)
        ON DUPLICATE KEY UPDATE count = count + 1]], { cid, tonumber(taskId) })

    TriggerClientEvent('sm_donate:bpAddTaskCount:premium', source, tonumber(taskId))
end)

RegisterNetEvent('sm_donate:endTestDrive', function()
    local Player = utils.player(source)

    if not Player then return end
end)
