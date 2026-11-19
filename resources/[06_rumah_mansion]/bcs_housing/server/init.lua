RegisterNetEvent('Housing:server:LoadHomes', function()
    if not Housing.booted then return end
    Housing:SendHomeList(source)
end)

RegisterNetEvent('Housing:initialize', function()
    local src = source
    local identifier = Housing:GetIdentifier(src)
    if not identifier then return end

    Housing.players[src] = { identifier = identifier, homeId = nil }
end)

RegisterNetEvent('Housing:server:UpdateLastProperty', function(property)
    local src = source
    local data = Housing.players[src]
    if not data then return end

    if property == 'outside' then
        data.lastProperty = nil
        return
    end

    data.lastProperty = property
end)

RegisterNetEvent('Housing:server:Enter', function(homeId, aptId)
    local src = source
    local home = Housing:GetHome(homeId)
    if not home then return end

    local data = Housing.players[src]
    if data then
        data.homeId = homeId
        data.aptId = aptId
    end

    home:AddInside(src, aptId)

    if Config.Server.log.events.enter then
        Housing:Log('enter', ('%s masuk %s'):format(src, home.name), home)
    end
end)

RegisterNetEvent('Housing:server:Exit', function(homeId)
    local src = source
    local home = Housing:GetHome(homeId)
    local data = Housing.players[src]

    if home then home:RemoveInside(src) end
    if data then
        data.homeId = nil
        data.aptId = nil
    end

    if Config.Server.log.events.exit and home then
        Housing:Log('exit', ('%s keluar %s'):format(src, home.name), home)
    end
end)

RegisterNetEvent('Housing:server:OnEnterArea', function(homeId)
    local src = source
    local home = Housing:GetHome(homeId)
    if not home then return end

    home:AddInside(src, nil)

    if Config.Server.log.events.enter then
        Housing:Log('enter', ('%s masuk area %s'):format(src, home.name), home)
    end
end)

RegisterNetEvent('Housing:server:OnExitArea', function(homeId)
    local src = source
    local home = Housing:GetHome(homeId)
    if not home then return end

    home:RemoveInside(src)

    if Config.Server.log.events.exit then
        Housing:Log('exit', ('%s keluar area %s'):format(src, home.name), home)
    end
end)