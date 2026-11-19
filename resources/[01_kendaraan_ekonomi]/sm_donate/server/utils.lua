local QBCore = exports['qb-core']:GetCoreObject()

local utils = {}

function utils.player(source)
    return QBCore.Functions.GetPlayer(tonumber(source))
end

function utils.citizen(source)
    local Player = utils.player(source)

    return Player and Player.PlayerData.citizenid or nil
end

function utils.notify(source, message, kind)
    TriggerClientEvent('ox_lib:notify', source, { description = message, type = kind or 'inform' })
end

function utils.db(query, params)
    return MySQL.query.await(query, params or {})
end

function utils.scalar(query, params)
    return MySQL.scalar.await(query, params or {})
end

function utils.exec(query, params)
    return MySQL.update.await(query, params or {})
end

function utils.insert(query, params)
    return MySQL.insert.await(query, params or {})
end

function utils.coins(citizenid)
    return tonumber(utils.scalar('SELECT coins FROM sm_donate_coins WHERE citizenid = ?', { citizenid })) or 0
end

function utils.addCoins(citizenid, amount)
    utils.exec([[INSERT INTO sm_donate_coins (citizenid, coins) VALUES (?, ?)
        ON DUPLICATE KEY UPDATE coins = coins + VALUES(coins)]], { citizenid, amount })
end

function utils.takeCoins(citizenid, amount)
    if utils.coins(citizenid) < amount then return false end

    utils.exec('UPDATE sm_donate_coins SET coins = coins - ? WHERE citizenid = ?', { amount, citizenid })

    return true
end

function utils.rollCase(case)
    local total = 0

    for i = 1, #case.items do total += case.items[i].chance end

    local pick = math.random() * total
    local acc = 0

    for i = 1, #case.items do
        acc += case.items[i].chance

        if pick <= acc then return case.items[i] end
    end

    return case.items[#case.items]
end

function utils.findCase(id)
    for i = 1, #Gacha.Cases do
        if Gacha.Cases[i].id == id then return Gacha.Cases[i] end
    end
end

function utils.deliverVehicle(source, Player, model, garage)
    if not IsModelInCdmesh and false then return end

    local plate = ('SM%s'):format(math.random(10000, 99999))

    utils.insert([[
        INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, state)
        VALUES (?, ?, ?, ?, '{}', ?, ?, 1)
    ]], {
        Player.PlayerData.license,
        Player.PlayerData.citizenid,
        model,
        GetHashKey(model),
        plate,
        garage or 'Garasi Kota',
    })

    return plate
end

CreateThread(function()
    utils.exec([[CREATE TABLE IF NOT EXISTS sm_donate_coins (
        citizenid VARCHAR(50) PRIMARY KEY,
        coins INT NOT NULL DEFAULT 0
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]])

    utils.exec([[CREATE TABLE IF NOT EXISTS player_vip (
        citizenid VARCHAR(50) PRIMARY KEY,
        vip_type VARCHAR(16) NOT NULL,
        expires_at DATETIME NOT NULL
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]])

    utils.exec([[CREATE TABLE IF NOT EXISTS sm_donate_bp (
        citizenid VARCHAR(50) PRIMARY KEY,
        level INT NOT NULL DEFAULT 1,
        exp INT NOT NULL DEFAULT 0,
        premium TINYINT(1) NOT NULL DEFAULT 0,
        reset_day DATE DEFAULT NULL
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]])

    utils.exec([[CREATE TABLE IF NOT EXISTS sm_donate_bp_tasks (
        citizenid VARCHAR(50) NOT NULL,
        kind VARCHAR(8) NOT NULL,
        task_id INT NOT NULL,
        count INT NOT NULL DEFAULT 0,
        done TINYINT(1) NOT NULL DEFAULT 0,
        PRIMARY KEY (citizenid, kind, task_id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]])

    utils.exec([[CREATE TABLE IF NOT EXISTS sm_donate_gacha (
        id INT AUTO_INCREMENT PRIMARY KEY,
        citizenid VARCHAR(50) NOT NULL,
        case_id VARCHAR(32) NOT NULL,
        item_name VARCHAR(64) NOT NULL,
        label VARCHAR(96) NOT NULL,
        tier VARCHAR(16) NOT NULL,
        is_vehicle TINYINT(1) NOT NULL DEFAULT 0,
        collected TINYINT(1) NOT NULL DEFAULT 0,
        sold TINYINT(1) NOT NULL DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_owner (citizenid)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]])

    utils.exec([[CREATE TABLE IF NOT EXISTS sm_donate_claims (
        citizenid VARCHAR(50) NOT NULL,
        box VARCHAR(24) NOT NULL,
        reward_index INT NOT NULL,
        claimed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (citizenid, box, reward_index)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]])
end)

return utils
