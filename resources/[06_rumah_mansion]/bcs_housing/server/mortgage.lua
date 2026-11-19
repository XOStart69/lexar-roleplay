local T = Config.Server.tables

lib.callback.register('Housing:server:GetMortgages', function(source, homeId)
    local home = Housing:GetHome(homeId)
    if not home then return {} end
    return home.mortgages
end)

lib.callback.register('Housing:server:SaveMortgages', function(source, homeId, data)
    local src = source
    local home = Housing:GetHome(homeId)
    if not home or type(data) ~= 'table' then return false end
    if not Housing:IsAdmin(src) and not Housing:CanManage(src, home, 'configuration') then return false end

    MySQL.query(('DELETE FROM `%s` WHERE `home` = ?'):format(T.mortgages), { homeId })

    home.mortgages = {}
    for _, entry in ipairs(data) do
        local id = MySQL.insert(('INSERT INTO `%s` (`home`, `owner`, `downpayment`, `interest`, `duration`, `payment`, `lastPayment`, `remaining`) VALUES (?, ?, ?, ?, ?, ?, ?, ?)'):format(T.mortgages), {
            homeId, entry.owner, entry.downpayment or 0, entry.interest or 0,
            entry.duration or 0, entry.payment or 0, entry.lastPayment or 0, entry.remaining or 0,
        })
        entry.id = id
        home.mortgages[#home.mortgages + 1] = entry
    end

    return true
end)