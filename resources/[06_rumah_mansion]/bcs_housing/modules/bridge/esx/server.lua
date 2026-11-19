Bridge = Bridge or {}

if Config.framework ~= 'ESX' then return end

function Bridge.GetPlayer(src)
    return ESX.GetPlayerFromId(src)
end

function Bridge.GetIdentifier(src)
    local player = Bridge.GetPlayer(src)
    return player and player.identifier or nil
end

function Bridge.GetName(src)
    local player = Bridge.GetPlayer(src)
    return player and player.getName() or nil
end

function Bridge.GetJob(src)
    local player = Bridge.GetPlayer(src)
    return player and player.job or nil
end

function Bridge.GetPlayers()
    return ESX.GetPlayers()
end

function Bridge.HasMoney(src, account, amount)
    local player = Bridge.GetPlayer(src)
    if not player then return false end
    return player.getAccount(account).money >= amount
end

function Bridge.RemoveMoney(src, account, amount, reason)
    local player = Bridge.GetPlayer(src)
    if not player then return false end
    player.removeAccountMoney(account, amount, reason)
    return true
end

function Bridge.AddMoney(src, account, amount, reason)
    local player = Bridge.GetPlayer(src)
    if not player then return end
    player.addAccountMoney(account, amount, reason)
end

function Bridge.HasItem(src, item, count)
    local player = Bridge.GetPlayer(src)
    if not player then return false end
    return player.getInventoryItem(item).count >= (count or 1)
end

function Bridge.RemoveItem(src, item, count)
    local player = Bridge.GetPlayer(src)
    if not player then return false end
    player.removeInventoryItem(item, count or 1)
    return true
end

function Bridge.AddItem(src, item, count)
    local player = Bridge.GetPlayer(src)
    if not player then return end
    player.addInventoryItem(item, count or 1)
end

function Bridge.Notify(src, message, notifyType)
    TriggerClientEvent('Housing:notify', src, 'Perumahan', message, notifyType or 'info', 5000)
end