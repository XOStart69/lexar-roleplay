local T = Config.Server.tables

RegisterNetEvent('Housing:LogoutLocation', function()
    local src = source
    local data = Housing.players[src]
    if not data then return end

    if data.homeId then
        data.lastProperty = data.homeId .. (data.aptId and (':' .. data.aptId) or '')
    end
end)

RegisterNetEvent('Housing:server:CreateApartment', function(homeId)
    local src = source
    local home = Housing:GetHome(homeId)
    if not home or not home:IsApartment() then return end
    if not Housing:IsAdmin(src) and not Housing:CanManage(src, home, 'configuration') then return end

    local index = #home.apartments + 1
    local id = MySQL.insert(('INSERT INTO `%s` (`home`, `name`, `price`, `storages`, `wardrobes`, `furniture`) VALUES (?, ?, ?, ?, ?, ?)'):format(T.apartments), {
        homeId, ('Unit %d'):format(index), 0, json.encode({}), json.encode({}), json.encode({}),
    })

    local apartment = HousingApartment:new({
        id = id, home = homeId, name = ('Unit %d'):format(index), price = 0,
    })
    home.apartments[#home.apartments + 1] = apartment

    TriggerClientEvent('Housing:client:GiveApartment', -1, homeId, apartment.apartment, apartment)
end)

RegisterNetEvent('Housing:server:RenameFlat', function(homeId, name)
    local src = source
    local home = Housing:GetHome(homeId)
    if not home or not name or not home:IsOwner(Housing:GetIdentifier(src)) then return end

    home.data.flat = home.data.flat or {}
    home.data.flat.name = name
    home:Save()
    Housing:BroadcastHome(home)
end)

RegisterNetEvent('Housing:server:Writeoffset', function(model, x, y, z, heading)
    print(('[bcs_housing:offset] %s = { x = %.4f, y = %.4f, z = %.4f, w = %.4f }'):format(
        model or '?', x or 0, y or 0, z or 0, heading or 0))
end)

RegisterNetEvent('Housing:server:WriteIPL', function(label, name, x, y, z, heading)
    print(('[bcs_housing:ipl] %s -> %s = vec4(%.4f, %.4f, %.4f, %.4f)'):format(
        label or '?', name or '?', x or 0, y or 0, z or 0, heading or 0))
end)

RegisterNetEvent('Housing:addlog', function(action, message, detail)
    local src = source
    local data = Housing.players[src]
    local home = data and data.homeId and Housing:GetHome(data.homeId)

    Housing:Log(action or 'action', message or detail or '', home, Housing:Name(src))
end)

exports('IsAdmin', function(src)
    return Housing:IsAdmin(src)
end)