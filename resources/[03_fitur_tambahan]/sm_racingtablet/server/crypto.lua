---@param nameId number
---@return table?
local function nameOf(nameId)
    return MySQL.single.await('SELECT id, citizenid, crypto FROM racing_racer_names WHERE id = ?', { nameId })
end

cwCallback.register('sm_racingtablet:server:purchaseCrypto', function(src, nameId, amount)
    local name = nameOf(tonumber(nameId))
    if not name or name.citizenid ~= getCitizenId(src) then return nil, 'Nama tidak valid.' end

    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return nil, 'Jumlah tidak valid.' end

    if not removeMoney(src, 'bank', amount * (Config.CryptoPrice or 100)) then return nil, 'Uang tidak cukup.' end

    MySQL.update.await('UPDATE racing_racer_names SET crypto = crypto + ? WHERE id = ?', { amount, name.id })

    return name.crypto + amount
end)

cwCallback.register('sm_racingtablet:server:sellCrypto', function(src, nameId, amount)
    local name = nameOf(tonumber(nameId))
    if not name or name.citizenid ~= getCitizenId(src) then return nil, 'Nama tidak valid.' end

    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return nil, 'Jumlah tidak valid.' end
    if name.crypto < amount then return nil, 'Saldo tidak cukup.' end

    MySQL.update.await('UPDATE racing_racer_names SET crypto = crypto - ? WHERE id = ?', { amount, name.id })
    addMoney(src, 'bank', math.floor(amount * (Config.CryptoPrice or 100) * 0.95))

    return name.crypto - amount
end)

cwCallback.register('sm_racingtablet:server:transferCrypto', function(src, nameId, targetName, amount)
    local name = nameOf(tonumber(nameId))
    if not name or name.citizenid ~= getCitizenId(src) then return nil, 'Nama tidak valid.' end

    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return nil, 'Jumlah tidak valid.' end
    if name.crypto < amount then return nil, 'Saldo tidak cukup.' end

    local target = MySQL.single.await('SELECT id FROM racing_racer_names WHERE racername = ?', { StrictSanitize(targetName) })
    if not target or target.id == name.id then return nil, 'Tujuan tidak valid.' end

    MySQL.update.await('UPDATE racing_racer_names SET crypto = crypto - ? WHERE id = ?', { amount, name.id })
    MySQL.update.await('UPDATE racing_racer_names SET crypto = crypto + ? WHERE id = ?', { amount, target.id })

    return true
end)