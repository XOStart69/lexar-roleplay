local T = Config.Server.tables

---@param home table
---@param identifier string
---@return table?
local function mortgageOf(home, identifier)
    for i = 1, #home.mortgages do
        if home.mortgages[i].owner == identifier then
            return home.mortgages[i]
        end
    end
end

RegisterNetEvent('Housing:server:PayRent', function(homeId, aptId)
    local src = source
    local home = Housing:GetHome(homeId)
    if not home or not home.rent or not home.rent.isRented then return end

    local identifier = Housing:GetIdentifier(src)
    if home.rent.tenant ~= identifier then return end

    local price = home.rent.price or 0
    if not Housing:RemoveMoney(src, Config.Server.rent.account, price, 'housing-rent') then
        Housing:Notify(src, 'Uang tidak cukup', 'error')
        return
    end

    local ownerIdentifier = home:GetOwner(home.owner or '', aptId)
    local ownerSrc = ownerIdentifier and Housing:SourceByIdentifier(ownerIdentifier)
    if ownerSrc and price > 0 then
        Housing:AddMoney(ownerSrc, Config.Server.rent.account, price, 'housing-rent-income')
    end

    home.rent.dueAt = os.time() + ((home.rent.durationType == 'week' and home.rent.duration * 7 or home.rent.duration) * 86400)
    home.rent.overdue = 0
    home:Save()
    Housing:Notify(src, 'Sewa dibayar', 'success')
end)

lib.callback.register('Housing:server:GetOngoingMortgage', function(source, homeId, aptId)
    local home = Housing:GetHome(homeId)
    if not home then return nil end

    local identifier = Housing:GetIdentifier(source)
    return mortgageOf(home, identifier)
end)

lib.callback.register('Housing:server:SaveOngoingMortgage', function(source, homeId, aptId, data)
    local home = Housing:GetHome(homeId)
    if not home or type(data) ~= 'table' then return false end

    local identifier = Housing:GetIdentifier(source)
    if not home:IsOwner(identifier, aptId) then return false end

    local mortgage = mortgageOf(home, identifier)
    if not mortgage then return false end

    mortgage.payment = tonumber(data.payment) or mortgage.payment
    mortgage.remaining = tonumber(data.remaining) or mortgage.remaining

    MySQL.update(('UPDATE `%s` SET `payment` = ?, `remaining` = ? WHERE `id` = ?'):format(T.mortgages),
        { mortgage.payment, mortgage.remaining, mortgage.id })

    home.payment = mortgage.payment
    home:SetProperty('payment', mortgage.payment)
    return true
end)

RegisterNetEvent('Housing:server:PayMortgage', function(homeId, aptId)
    local src = source
    local home = Housing:GetHome(homeId)
    if not home then return end

    local identifier = Housing:GetIdentifier(src)
    local mortgage = mortgageOf(home, identifier)
    if not mortgage then return end

    local amount = mortgage.payment or 0
    if amount <= 0 then return end

    if not Housing:RemoveMoney(src, Config.Server.mortgage.account, amount, 'housing-mortgage') then
        Housing:Notify(src, 'Uang tidak cukup', 'error')
        return
    end

    mortgage.remaining = math.max((mortgage.remaining or 0) - amount, 0)
    mortgage.lastPayment = os.time()

    MySQL.update(('UPDATE `%s` SET `remaining` = ?, `lastPayment` = ? WHERE `id` = ?'):format(T.mortgages),
        { mortgage.remaining, mortgage.lastPayment, mortgage.id })

    home.lastPayment = mortgage.lastPayment

    if mortgage.remaining <= 0 then
        table.remove(home.mortgages, mortgage.id)
        MySQL.query(('DELETE FROM `%s` WHERE `id` = ?'):format(T.mortgages), { mortgage.id })
        home.payment = 0
        home:SetProperty('payment', 0)
        Housing:Notify(src, 'Cicilan lunas', 'success')
    else
        Housing:Notify(src, ('Cicilan dibayar, sisa $%d'):format(mortgage.remaining), 'success')
    end
end)

RegisterNetEvent('Housing:server:PayMortgageRemaining', function(homeId, aptId)
    local src = source
    local home = Housing:GetHome(homeId)
    if not home then return end

    local identifier = Housing:GetIdentifier(src)
    local mortgage = mortgageOf(home, identifier)
    if not mortgage or (mortgage.remaining or 0) <= 0 then return end

    local amount = mortgage.remaining
    if not Housing:RemoveMoney(src, Config.Server.mortgage.account, amount, 'housing-mortgage-full') then
        Housing:Notify(src, 'Uang tidak cukup', 'error')
        return
    end

    MySQL.query(('DELETE FROM `%s` WHERE `id` = ?'):format(T.mortgages), { mortgage.id })
    table.remove(home.mortgages, mortgage.id)

    home.payment = 0
    home:SetProperty('payment', 0)
    Housing:Notify(src, 'Cicilan lunas', 'success')
end)