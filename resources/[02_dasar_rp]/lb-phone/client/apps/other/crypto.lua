if not (Config.Crypto and Config.Crypto.Enabled) then
    return
end

local coins = {}
local busy = false

local function findCoin(id)
    for i = 1, #coins do
        local coin = coins[i]
        if coin.id == id then
            return i, coin
        end
    end
    return false
end

local function addQBit()
    if not (Config.Crypto.QBit and Config.Framework == "qb") then
        return
    end
    local index = findCoin("qbit")
    if not index then
        index = #coins + 1
    end
    local qbit = GetQBit()
    local prices = {}
    for i = 1, #qbit.History do
        prices[#prices + 1] = qbit.History[i].PreviousWorth
        prices[#prices + 1] = qbit.History[i].NewWorth
    end
    if #qbit.History == 0 then
        for i = 1, 10 do
            prices[i] = qbit.Worth + math.random(-10, 10)
        end
    end
    local entry = {}
    local change24h = 0
    if #qbit.History > 0 then
        change24h = qbit.History[#qbit.History].NewWorth - qbit.History[1].PreviousWorth
    end
    entry.change_24h = change24h
    entry.current_price = qbit.Worth
    entry.id = "qbit"
    entry.image = "https://avatars.githubusercontent.com/u/81791099?s=200&v=4"
    entry.name = "QBit"
    entry.prices = prices
    entry.symbol = "qbit"
    entry.owned = qbit.Portfolio
    coins[index] = entry
end

local function buyCoin(coin, amount)
    local result
    if "qbit" == coin then
        if BuyQBit then
            result = BuyQBit(amount)
        end
    else
        result = AwaitCallback("crypto:buy", coin, amount)
    end
    busy = false
    if not result.success then
        return result
    end
    local _, owned = findCoin(coin)
    if not owned then
        return result
    end
    owned.owned = (owned.owned or 0) + amount / owned.current_price
    owned.invested = (owned.invested or 0) + amount
    return result
end

local function sellCoin(coin, amount)
    local result
    if "qbit" == coin then
        if SellQBit then
            result = SellQBit(amount)
        end
    else
        result = AwaitCallback("crypto:sell", coin, amount)
    end
    busy = false
    if not result.success then
        return result
    end
    local _, owned = findCoin(coin)
    if not owned then
        return result
    end
    local invested = owned.invested
    local amountOwned = owned.owned
    if not invested or not amountOwned then
        return result
    end
    owned.invested = invested - amount * owned.current_price
    owned.owned = amountOwned - amount
    return result
end

local function transferCoin(coin, amount, number)
    local result
    if "qbit" == coin then
        if TransferQBit then
            result = TransferQBit(amount)
        end
    else
        result = AwaitCallback("crypto:transfer", coin, amount, number)
    end
    busy = false
    if not result.success then
        return result
    end
    local _, owned = findCoin(coin)
    if not owned then
        return result
    end
    local invested = owned.invested
    local amountOwned = owned.owned
    if not invested or not amountOwned then
        return result
    end
    owned.invested = invested - amount * owned.current_price
    owned.owned = amountOwned - amount
    return result
end

RegisterNUICallback("Crypto", function(data, cb)
    local action = data.action
    debugprint("Crypto:" .. (action or ""))
    if "buy" == action or "sell" == action or "transfer" == action then
        if busy then
            return cb({ success = false, msg = "BUSY" })
        end
        busy = true
    end
    if "buy" == action then
        return cb(buyCoin(data.coin, data.amount))
    elseif "sell" == action then
        return cb(sellCoin(data.coin, data.amount))
    elseif "transfer" == action then
        return cb(transferCoin(data.coin, data.amount, data.number))
    elseif "get" == action then
        addQBit()
        TriggerServerEvent("phone:crypto:fetchCoins")
        return cb(coins)
    elseif "openedApp" == action then
        TriggerServerEvent("phone:crypto:setAppOpen", true)
    elseif "closedApp" == action then
        TriggerServerEvent("phone:crypto:setAppOpen", false)
    end
    cb("ok")
end)

function FetchCryptoCoins()
    local fetched = AwaitCallback("crypto:get")
    if not fetched then
        return
    end
    table.wipe(coins)
    for _, coin in pairs(fetched) do
        coins[#coins + 1] = coin
    end
    SendNUIAction("crypto:updateCoins", coins)
end

CreateThread(function()
    while not FrameworkLoaded do
        Wait(500)
    end
    FetchCryptoCoins()
end)

RegisterNetEvent("phone:crypto:updateCoins", function(updated)
    for i = 1, #coins do
        local coin = coins[i]
        local data = updated[coin.id]
        if data then
            coin.current_price = data.current_price
            coin.change_24h = data.change_24h
            coin.prices = data.prices
        end
    end
    for id, coin in pairs(updated) do
        if not findCoin(id) then
            coins[#coins + 1] = coin
        end
    end
    debugprint("updated crypto cache")
    SendNUIAction("crypto:updateCoins", coins)
end)

RegisterNetEvent("phone:crypto:changeOwnedAmount", function(id, amount)
    local _, coin = findCoin(id)
    if not coin then
        return
    end
    coin.owned = (coin.owned or 0) + amount
    debugprint("updated crypto cache", id, amount, coin.owned)
    SendNUIAction("crypto:updateCoins", coins)
end)

exports("GetCoinValue", function(id)
    local _, coin = findCoin(id)
    return coin and coin.current_price
end)

exports("GetCryptoWallet", function()
    return coins
end)

exports("GetOwnedCoin", function(id)
    local _, coin = findCoin(id)
    return coin
end)
