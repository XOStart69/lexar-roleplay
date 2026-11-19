local T = Config.Server.tables

---@param home table
---@param aptId string|number|nil
---@return table[]
local function billsOf(home, aptId)
    local list = {}
    for i = 1, #home.bills do
        local bill = home.bills[i]
        if not bill.paid and (not aptId or tostring(bill.aptId) == tostring(aptId)) then
            list[#list + 1] = bill
        end
    end
    return list
end

lib.callback.register('Housing:server:GetBill', function(source, homeId, aptId)
    local home = Housing:GetHome(homeId)
    if not home then return {} end

    local identifier = Housing:GetIdentifier(source)
    if not home:HasAccess(identifier, nil, aptId) and not Housing:IsAdmin(source) then return {} end

    return billsOf(home, aptId)
end)

lib.callback.register('Housing:server:PayBill', function(source, name, homeId, aptId)
    local src = source
    local home = Housing:GetHome(homeId)
    if not home or not name then return false end

    local identifier = Housing:GetIdentifier(src)
    if not home:HasAccess(identifier, nil, aptId) then return false end

    local bill
    for i = 1, #home.bills do
        if home.bills[i].type == name and not home.bills[i].paid then
            bill = home.bills[i]
            break
        end
    end
    if not bill then return false end

    if not Housing:RemoveMoney(src, Config.Server.defaultAccount, bill.amount, 'housing-bill') then
        Housing:Notify(src, 'Uang tidak cukup', 'error')
        return false
    end

    bill.paid = true
    MySQL.update(('UPDATE `%s` SET `paid` = 1 WHERE `id` = ?'):format(T.bills), { bill.id })

    TriggerClientEvent('Housing:client:UpdateBill', -1, homeId, billsOf(home, aptId))
    Housing:Notify(src, ('Tagihan %s lunas'):format(name), 'success')
    return true
end)

---@param home table
---@param billType string
---@param amount number
---@param aptId string|number|nil
function Housing:AddBill(home, billType, amount, aptId)
    local bill = { type = billType, amount = amount, aptId = aptId, paid = false, created_at = os.time() }
    home.bills[#home.bills + 1] = bill

    MySQL.insert(('INSERT INTO `%s` (`home`, `aptId`, `type`, `amount`, `created_at`) VALUES (?, ?, ?, ?, ?)'):format(T.bills),
        { home.identifier, aptId, billType, amount, bill.created_at })

    TriggerClientEvent('Housing:client:UpdateBill', -1, home.identifier, bill)
end

RegisterNetEvent('Housing:server:ToggleLightSwitch', function(homeId, furniture)
    local src = source
    local home = Housing:GetHome(homeId)
    if not home then return end

    local identifier = Housing:GetIdentifier(src)
    if not home:HasAccess(identifier, 'furniture') then return end

    for _, target in ipairs(home:GetInside()) do
        TriggerClientEvent('Housing:client:ToggleLightSwitch', target, homeId, furniture)
    end
end)