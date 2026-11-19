local QBCore = exports['qb-core']:GetCoreObject()

local framework = {}

function framework.player(source)
    return QBCore.Functions.GetPlayer(tonumber(source))
end

function framework.citizen(source)
    local Player = framework.player(source)

    return Player and Player.PlayerData.citizenid or nil
end

function framework.name(source)
    local Player = framework.player(source)
    local info = Player and Player.PlayerData.charinfo

    if not info then return 'Tidak diketahui' end

    return ('%s %s'):format(info.firstname or '?', info.lastname or '')
end

function framework.notify(source, message, kind)
    TriggerClientEvent('Renewed-Banking:client:sendNotification', source, {
        message = message,
        title = 'Bank',
        type = kind or 'info',
    })
end

return framework
