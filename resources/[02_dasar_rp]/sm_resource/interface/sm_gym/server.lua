--[[
    sm_gym :: server
    Member gym per zona dengan masa aktif, progres gym/stamina dari latihan dan lari,
    dan pengurangan stress saat latihan.
]]

local config = localmodule 'config.gym'
local staminaTable = localmodule 'data.stamina'

local QBCore = exports['qb-core']:GetCoreObject()

local WORKOUT_GAIN = 0.1
local RUN_GAIN = 0.05
local GYM_MAX = math.max(1, #staminaTable - 1)

local SCHEMA = [[
CREATE TABLE IF NOT EXISTS `sm_gym_members` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `citizenid` varchar(64) NOT NULL,
    `zone` varchar(64) NOT NULL,
    `expires` bigint(20) NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `citizenid_zone` (`citizenid`, `zone`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
]]

local function notify(src, message, nType)
    TriggerClientEvent('QBCore:Notify', src, message, nType or 'primary')
end

local function ply(src)
    return QBCore.Functions.GetPlayer(src)
end

local function planOf(zone, value)
    local entry = config.location[zone]
    if not entry or not entry.price then return nil end

    for i = 1, #entry.price do
        if entry.price[i].value == value then return entry.price[i] end
    end
end

local function bumpGym(src, gain)
    local player = ply(src)
    if not player then return end

    local current = tonumber(player.PlayerData.metadata.gym) or 0
    if current >= GYM_MAX then return end

    local next_ = math.min(GYM_MAX, current + gain)
    player.Functions.SetMetaData('gym', next_)
end

lib.callback.register('sm_gym:server:checkMember', function(src, zone)
    local player = ply(src)
    if not player or type(zone) ~= 'string' then return false end
    if not config.location[zone] then return false end

    local row = MySQL.single.await(
        'SELECT expires FROM sm_gym_members WHERE citizenid = ? AND zone = ?',
        { player.PlayerData.citizenid, zone }
    )

    if not row then
        notify(src, 'Kamu belum member gym ini. Daftar ke instruktur.', 'error')
        return false
    end

    if tonumber(row.expires) <= os.time() then
        notify(src, 'Member gym kamu sudah habis.', 'error')
        return false
    end

    return true
end)

RegisterNetEvent('sm_gym:server:add', function()
    bumpGym(source, WORKOUT_GAIN)
end)

RegisterNetEvent('sm_gym:server:remove', function()
    bumpGym(source, RUN_GAIN)
end)

RegisterNetEvent('sm_gym:server:registerMember', function(payload)
    local src = source
    local player = ply(src)
    if not player or type(payload) ~= 'table' then return end

    local zone, value = payload[1], payload[2]
    local plan = planOf(zone, value)

    if not plan then return notify(src, 'Paket member tidak valid.', 'error') end

    local money = player.PlayerData.money
    local price = tonumber(plan.price) or 0

    if (money.cash or 0) >= price then
        player.Functions.RemoveMoney('cash', price, 'gym-membership')
    elseif (money.bank or 0) >= price then
        player.Functions.RemoveMoney('bank', price, 'gym-membership')
    else
        return notify(src, ('Uang tidak cukup ($%s).'):format(price), 'error')
    end

    local expires = os.time() + (tonumber(plan.days) or 0) * 86400

    MySQL.insert.await([[
        INSERT INTO sm_gym_members (citizenid, zone, expires) VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE expires = GREATEST(expires, VALUES(expires))
    ]], { player.PlayerData.citizenid, zone, expires })

    notify(src, ('Member gym aktif %d hari.'):format(plan.days or 0), 'success')
end)

CreateThread(function()
    MySQL.query.await(SCHEMA)
    MySQL.update.await('DELETE FROM sm_gym_members WHERE expires < ?', { os.time() })
end)