--[[
    bocahpass :: server
    Pass harian untuk job paud: level, exp, ronde misi, hadiah level, dan misi foto.
    Semua progres disimpan per karakter dan di-reset harian.
]]

local sharedConfig = localmodule 'config.shared'

local QBCore = exports['qb-core']:GetCoreObject()

local MISSIONS = sharedConfig.missions or {}
local DAILY = sharedConfig.dailyCount or 4
local LEVELS = sharedConfig.levels or {}
local EXP_PER_LEVEL = LEVELS.expPerLevel or {}
local MAX_LEVEL = LEVELS.maxLevel or #EXP_PER_LEVEL

local pendingFoto = {}

local SCHEMA = [[
CREATE TABLE IF NOT EXISTS `bocahpass_progress` (
    `citizenid` varchar(64) NOT NULL,
    `level` int(11) NOT NULL DEFAULT 1,
    `exp` int(11) NOT NULL DEFAULT 0,
    `day` date NOT NULL,
    `daily` longtext NULL,
    `rounds` longtext NULL,
    `claimed` longtext NULL,
    PRIMARY KEY (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
]]

local function notify(src, message, nType)
    lib.notify(src, { description = message, type = nType or 'inform' })
end

local function player(src)
    return QBCore.Functions.GetPlayer(src)
end

local function decode(raw, fallback)
    if type(raw) == 'table' then return raw end
    if not raw or raw == '' then return fallback end

    local ok, value = pcall(json.decode, raw)
    return ok and value or fallback
end

local function rowFor(citizenid)
    local row = MySQL.single.await('SELECT * FROM bocahpass_progress WHERE citizenid = ?', { citizenid })

    if row and tostring(row.day) ~= os.date('%Y-%m-%d') then
        row.day = os.date('%Y-%m-%d')
        row.daily = '{}'
        row.rounds = '{}'
        MySQL.update.await('UPDATE bocahpass_progress SET day = CURDATE(), daily = ?, rounds = ? WHERE citizenid = ?', {
            row.daily, row.rounds, citizenid
        })
    end

    if not row then
        MySQL.insert.await('INSERT INTO bocahpass_progress (citizenid, day) VALUES (?, CURDATE())', { citizenid })
        row = MySQL.single.await('SELECT * FROM bocahpass_progress WHERE citizenid = ?', { citizenid })
    end

    return row
end

local function save(row)
    MySQL.update.await([[
        UPDATE bocahpass_progress SET level = ?, exp = ?, daily = ?, rounds = ?, claimed = ? WHERE citizenid = ?
    ]], { row.level, row.exp, json.encode(decode(row.daily, {})), json.encode(decode(row.rounds, {})), json.encode(decode(row.claimed, {})), row.citizenid })
end

lib.callback.register('bocahpass:getData', function(src)
    local ply = player(src)
    if not ply then return end

    local row = rowFor(ply.PlayerData.citizenid)
    if not row then return end

    local daily = decode(row.daily, {})
    local rounds = decode(row.rounds, {})
    local claimed = decode(row.claimed, {})

    local list = {}

    for key, cfg in pairs(MISSIONS) do
        if not daily[key] or daily[key] < DAILY then
            list[#list + 1] = {
                key = key,
                label = cfg.label,
                description = cfg.description,
                icon = cfg.icon,
                exp = cfg.exp,
                rounds = cfg.requiredRounds or 1,
                done = daily[key] or 0
            }
        end
    end

    return {
        level = tonumber(row.level) or 1,
        exp = tonumber(row.exp) or 0,
        missions = list,
        progress = rounds,
        claimed = claimed,
        dailyActivities = daily
    }
end)

lib.callback.register('bocahpass:getPlayerJob', function(_, target)
    local ply = player(tonumber(target) or 0)
    local job = ply and ply.PlayerData.job

    return job and job.name or nil
end)

lib.callback.register('bocahpass:canStartMission', function(src, key)
    local ply = player(src)
    if not ply then return false end

    local cfg = MISSIONS[key]
    if not cfg then return false end

    local row = rowFor(ply.PlayerData.citizenid)
    if not row then return false end

    local daily = decode(row.daily, {})

    return (daily[key] or 0) < DAILY
end)

lib.callback.register('bocahpass:getRemainingRounds', function(src, key)
    local ply = player(src)
    if not ply then return false end

    local cfg = MISSIONS[key]
    if not cfg then return 0 end

    local row = rowFor(ply.PlayerData.citizenid)
    if not row then return 0 end

    local rounds = decode(row.rounds, {})
    local required = cfg.requiredRounds or 1
    local done = rounds[key] or 0

    return math.max(0, required - done)
end)

RegisterNetEvent('bocahpass:addRound', function(key)
    local src = source
    local ply = player(src)
    if not ply then return end

    local cfg = MISSIONS[key]
    if not cfg then return end

    local row = rowFor(ply.PlayerData.citizenid)
    if not row then return end

    local rounds = decode(row.rounds, {})
    local daily = decode(row.daily, {})
    local required = cfg.requiredRounds or 1

    rounds[key] = (rounds[key] or 0) + 1

    if rounds[key] >= required then
        rounds[key] = 0
        daily[key] = (daily[key] or 0) + 1

        row.exp = (tonumber(row.exp) or 0) + (tonumber(cfg.exp) or 0)

        local level = tonumber(row.level) or 1
        while level < MAX_LEVEL and row.exp >= (EXP_PER_LEVEL[level] or math.huge) do
            row.exp = row.exp - EXP_PER_LEVEL[level]
            level = level + 1
            notify(src, ('Naik ke level %d!'):format(level), 'success')
        end

        row.level = level
        notify(src, ('Misi %s selesai. +%d exp.'):format(cfg.label, cfg.exp), 'success')
    end

    row.rounds = rounds
    row.daily = daily
    save(row)
end)

lib.callback.register('bocahpass:requestFoto', function(src, target, key)
    local ply = player(src)
    local other = player(tonumber(target) or 0)

    if not ply or not other then return false end
    if pendingFoto[other.PlayerData.source] then return false end

    pendingFoto[other.PlayerData.source] = src

    local info = ply.PlayerData.charinfo
    local accepted = lib.callback.await('bocahpass:fotoRequest', other.PlayerData.source, src,
        ('%s %s'):format(info.firstname or '?', info.lastname or '?'), key)

    pendingFoto[other.PlayerData.source] = nil

    return accepted == true
end)

RegisterNetEvent('bocahpass:fotoResponse', function(requester, accepted)
    local src = source
    if not pendingFoto[src] then return end

    -- dikirim balik ke peminta lewat event lokal klien, cukup catat saja
    pendingFoto[src] = nil
end)

lib.callback.register('bocahpass:claimReward', function(src, level)
    local ply = player(src)
    if not ply then return false end

    level = tonumber(level)
    if not level then return false end

    local row = rowFor(ply.PlayerData.citizenid)
    if not row then return false end

    if (tonumber(row.level) or 1) < level then return false end

    local claimed = decode(row.claimed, {})
    if claimed[tostring(level)] then return false end

    local rewards = LEVELS.rewards and LEVELS.rewards[level]
    if not rewards then return false end

    for i = 1, #rewards do
        local reward = rewards[i]

        if reward.item == 'money' then
            ply.Functions.AddMoney('cash', reward.count, 'bocahpass-reward')
        else
            exports.ox_inventory:AddItem(src, reward.item, reward.count)
        end
    end

    claimed[tostring(level)] = true
    row.claimed = claimed
    save(row)

    notify(src, ('Hadiah level %d diterima.'):format(level), 'success')

    return true
end)

CreateThread(function()
    MySQL.query.await(SCHEMA)
end)