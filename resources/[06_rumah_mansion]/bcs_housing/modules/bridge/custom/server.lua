Bridge = Bridge or {}

if Config.framework ~= 'custom' then return end

function Bridge.GetPlayer(src)
    return QBCore and QBCore.Functions.GetPlayer(src) or nil
end

function Bridge.GetIdentifier(src)
    local player = Bridge.GetPlayer(src)
    return player and player.PlayerData.citizenid or nil
end

function Bridge.GetName(src)
    local player = Bridge.GetPlayer(src)
    if not player then return nil end
    local info = player.PlayerData.charinfo or {}
    return ('%s %s'):format(info.firstname or '', info.lastname or '')
end

function Bridge.GetJob(src)
    local player = Bridge.GetPlayer(src)
    return player and player.PlayerData.job or nil
end

function Bridge.GetPlayers()
    return QBCore and QBCore.Functions.GetPlayers() or {}
end

function Bridge.HasMoney(src, account, amount)
    local player = Bridge.GetPlayer(src)
    if not player then return false end
    return (player.PlayerData.money[account] or 0) >= amount
end

function Bridge.RemoveMoney(src, account, amount, reason)
    local player = Bridge.GetPlayer(src)
    if not player then return false end
    return player.Functions.RemoveMoney(account, amount, reason) == true
end

function Bridge.AddMoney(src, account, amount, reason)
    local player = Bridge.GetPlayer(src)
    if not player then return end
    player.Functions.AddMoney(account, amount, reason)
end

function Bridge.HasItem(src, item, count)
    local player = Bridge.GetPlayer(src)
    if not player then return false end
    local entry = player.Functions.GetItemByName(item)
    return entry ~= nil and entry.amount >= (count or 1)
end

function Bridge.RemoveItem(src, item, count)
    local player = Bridge.GetPlayer(src)
    if not player then return false end
    return player.Functions.RemoveItem(item, count or 1) == true
end

function Bridge.AddItem(src, item, count)
    local player = Bridge.GetPlayer(src)
    if not player then return end
    player.Functions.AddItem(item, count or 1)
end

function Bridge.Notify(src, message, notifyType)
    TriggerClientEvent('Housing:notify', src, 'Perumahan', message, notifyType or 'info', 5000)
end