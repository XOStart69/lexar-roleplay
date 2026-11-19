local utils = require 'server.utils'

local function ace(source)
    if source == 0 then return true end

    return IsPlayerAceAllowed(tostring(source), 'god') or IsPlayerAceAllowed(tostring(source), 'admin')
end

RegisterCommand('donate', function(source, args)
    if not ace(source) then return end

    local action = args[1]

    if action == 'coins' then
        local target = utils.player(args[2])
        local amount = tonumber(args[3])

        if not target or not amount then return print('pakai: donate coins <id> <jumlah>') end

        utils.addCoins(target.PlayerData.citizenid, amount)
        utils.notify(target.PlayerData.source, ('+%d coin'):format(amount), 'success')

        return print(('%s +%d coin'):format(target.PlayerData.citizenid, amount))
    end

    if action == 'vip' then
        local target = utils.player(args[2])
        local kind = args[3]
        local days = tonumber(args[4]) or 30

        if not target or not kind then return print('pakai: donate vip <id> <vip|vvip> <hari>') end

        utils.exec([[INSERT INTO player_vip (citizenid, vip_type, expires_at) VALUES (?, ?, DATE_ADD(NOW(), INTERVAL ? DAY))
            ON DUPLICATE KEY UPDATE expires_at = GREATEST(expires_at, NOW()) + INTERVAL ? DAY, vip_type = VALUES(vip_type)]], {
            target.PlayerData.citizenid, kind, days, days,
        })

        utils.notify(target.PlayerData.source, ('VIP %s aktif %d hari'):format(kind, days), 'success')

        return print(('%s vip %s %d hari'):format(target.PlayerData.citizenid, kind, days))
    end

    if action == 'code' then
        local code = args[2]
        local coins = tonumber(args[3]) or 0
        local kind = args[4]
        local days = tonumber(args[5]) or 0
        local maxUses = tonumber(args[6]) or 0

        if not code then return print('pakai: donate code <KODE> <coin> [vip|vvip] [hari] [maxpakai]') end

        utils.exec([[INSERT INTO sm_donate_codes (code, coins, vip_type, vip_days, max_uses) VALUES (?, ?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE coins = VALUES(coins), vip_type = VALUES(vip_type), vip_days = VALUES(vip_days), max_uses = VALUES(max_uses)]], {
            code:upper(), coins, kind, days, maxUses,
        })

        return print('kode dibuat: ' .. code:upper())
    end

    if action == 'kompensasi' then
        local target = utils.player(args[2])
        if not target then return print('pakai: donate kompensasi <id>') end

        TriggerClientEvent('sm_donate:openKompensasi', target.PlayerData.source)
        return print('kompensasi dibuka: ' .. target.PlayerData.citizenid)
    end

    if action == 'merdeka' then
        local target = utils.player(args[2])
        if not target then return print('pakai: donate merdeka <id>') end

        TriggerClientEvent('sm_donate:openMerdeka', target.PlayerData.source)
        return print('merdeka dibuka: ' .. target.PlayerData.citizenid)
    end

    print('donate coins <id> <jumlah> | donate vip <id> <vip|vvip> <hari> | donate code <KODE> <coin> [vip] [hari] [max] | donate kompensasi <id> | donate merdeka <id>')
end, false)

lib.print.info('sm_donate admin siap')
