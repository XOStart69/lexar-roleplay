--[[
    antitroll :: server
    Proteksi antitroll berbasis waktu. Sisa waktu disimpan ke database supaya
    tetap jalan setelah relog, dan dihitung ulang saat pemain masuk.
]]

local config = localmodule 'config'

local QBCore = exports['qb-core']:GetCoreObject()

local SAVE_INTERVAL = (config.TimeToSave or 5) * 1000
local PUSH_INTERVAL = 30000
local VOUCHER_ITEM = 'voucher_peredakeram'

local timers = {}

local SCHEMA = [[
CREATE TABLE IF NOT EXISTS `antitroll` (
    `identifier` varchar(64) NOT NULL,
    `time_left` int(11) NOT NULL DEFAULT 0,
    `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
]]

local function steamOf(src)
    return GetPlayerIdentifierByType(src, 'steam')
end

local function listed(src, list)
    local steam = steamOf(src)
    if not steam then return false end

    for i = 1, #list do
        if list[i] == steam then return true end
    end

    return false
end

local function canUse(src)
    return IsPlayerAceAllowed(src, config.Rang or 'admin') or listed(src, config.AllowedSteamIDs or {})
end

local function canOffline(src)
    return IsPlayerAceAllowed(src, config.Rang or 'admin') or listed(src, config.offlinePerms or {})
end

local function notify(src, message, nType)
    lib.notify(src, { description = message, type = nType or 'inform' })
end

local function identifierOf(src)
    local player = QBCore.Functions.GetPlayer(src)
    return player and player.PlayerData.license or nil
end

local function stop(src, silent)
    local state = timers[src]
    if not state then return end

    timers[src] = nil

    TriggerClientEvent('antitroll_client:pause', src)
    TriggerClientEvent('antitroll_client:voucherResult', src, false, 'Proteksi antitroll habis.', 0)

    if not silent then
        notify(src, 'Proteksi antitroll sudah habis.', 'inform')
    end
end

local function resume(src)
    local id = identifierOf(src)
    if not id then return end

    local row = MySQL.single.await('SELECT time_left FROM antitroll WHERE identifier = ?', { id })
    if not row then return end

    local left = tonumber(row.time_left) or 0
    if left <= 0 then return end

    timers[src] = { identifier = id, left = left, lastPush = GetGameTimer() }
    TriggerClientEvent('antitroll_client:check', src, left)
end

RegisterNetEvent('antitroll_server:check', function()
    local src = source
    if timers[src] then return end

    resume(src)
end)

RegisterNetEvent('antitroll_server:useVoucher', function(slot)
    local src = source
    local id = identifierOf(src)
    if not id then return end

    local slotId = tonumber(slot)
    if slotId and not exports.ox_inventory:GetSlot(src, slotId) then return end

    if slotId and not exports.ox_inventory:RemoveItem(src, VOUCHER_ITEM, 1, nil, slotId) then
        return notify(src, 'Voucher tidak ditemukan.', 'error')
    end

    local add = (config.HowLong or 4320) * 60
    local state = timers[src]

    if state then
        state.left = state.left + add
    else
        state = { identifier = id, left = add, lastPush = GetGameTimer() }
        timers[src] = state
        TriggerClientEvent('antitroll_client:check', src, state.left)
    end

    TriggerClientEvent('antitroll_client:voucherResult', src, true,
        ('Proteksi antitroll ditambah %d menit.'):format(config.HowLong or 4320), state.left)

    notify(src, 'Voucher pereda keram dipakai.', 'success')
end)

lib.addCommand(config.AdminCommand or 'troll', {
    help = 'Beri proteksi antitroll ke pemain',
    params = {
        { name = 'id', type = 'number', help = 'ID pemain' },
        { name = 'menit', type = 'number', help = 'Durasi (menit), default dari config', optional = true }
    }
}, function(src, args)
    if not canUse(src) then return notify(src, 'Kamu tidak punya akses.', 'error') end

    local target = tonumber(args.id)
    if not target then return end

    local minutes = math.floor(tonumber(args.menit) or config.HowLong or 4320)
    if minutes <= 0 then return end

    local id = identifierOf(target)
    if not id then
        if not canOffline(src) then
            return notify(src, 'Pemain tidak ditemukan (dan kamu tidak punya izin offline).', 'error')
        end
    end

    local add = minutes * 60
    local state = timers[target]

    if state then
        state.left = state.left + add
    elseif id then
        timers[target] = { identifier = id, left = add, lastPush = GetGameTimer() }
        TriggerClientEvent('antitroll_client:check', target, add)
    end

    if id then
        MySQL.insert.await([[
            INSERT INTO antitroll (identifier, time_left) VALUES (?, ?)
            ON DUPLICATE KEY UPDATE time_left = time_left + VALUES(time_left)
        ]], { id, add })
    end

    notify(src, ('Proteksi %d menit diberikan ke %s.'):format(minutes, GetPlayerName(target) or args.id), 'success')

    if GetPlayerName(target) then
        TriggerClientEvent('antitroll_client:voucherResult', target, true,
            ('Kamu mendapat proteksi antitroll %d menit.'):format(minutes), state and state.left or add)
    end
end)

CreateThread(function()
    MySQL.query.await(SCHEMA)

    while true do
        Wait(1000)

        for src, state in pairs(timers) do
            if not GetPlayerName(src) then
                timers[src] = nil
            else
                state.left = state.left - 1

                if state.left <= 0 then
                    stop(src)
                elseif GetGameTimer() - state.lastPush >= PUSH_INTERVAL then
                    state.lastPush = GetGameTimer()
                    TriggerClientEvent('antitroll_client:updateTimer', src, state.left)
                end
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(SAVE_INTERVAL)

        for _, state in pairs(timers) do
            MySQL.update('UPDATE antitroll SET time_left = ? WHERE identifier = ?', { state.left, state.identifier })
        end
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    local state = timers[src]
    if not state then return end

    timers[src] = nil
    MySQL.update.await('UPDATE antitroll SET time_left = ? WHERE identifier = ?', { state.left, state.identifier })
end)

QBCore.Functions.CreateCallback('antitroll:getState', function(src, cb)
    local state = timers[src]
    cb(state and state.left or 0)
end)