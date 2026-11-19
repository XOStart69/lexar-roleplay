local T = Config.Server.tables

lib.callback.register('apartments:GetOwnedApartment', function(source, citizenid)
    local identifier = citizenid or Housing:GetIdentifier(source)
    if not identifier then return {} end

    local list = {}
    for _, home in pairs(Housing.homes) do
        if home:IsApartment() then
            for i = 1, #home.apartments do
                if home.apartments[i].owner == identifier then
                    list[#list + 1] = { homeId = home.identifier, aptId = home.apartments[i].apartment }
                end
            end
        end
    end
    return list
end)

lib.callback.register('apartments:GetStarterApartment', function()
    local list = {}
    if not Config.Server.starterApartment.enabled then return list end

    for identifier in pairs(Housing.starter) do
        local home = Housing:GetHome(identifier)
        if home then
            list[#list + 1] = Minify(home:Snapshot())
        end
    end
    return list
end)

lib.callback.register('Housing:server:GetLastProperty', function(source)
    local data = Housing.players[source]
    return data and data.lastProperty or nil
end)

lib.callback.register('Housing:server:GiveHomeKeyHolder', function(source, homeId, target, keyName, aptId)
    local src = source
    local home = Housing:GetHome(homeId)
    if not home then return false end

    local identifier = Housing:GetIdentifier(src)
    if not home:IsOwner(identifier, aptId) then return false end

    local limit = home.configuration.limitKeys or Config.configuration.LimitKeys
    if #home.keys.holders >= limit then
        Housing:Notify(src, 'Batas kunci rumah tercapai', 'error')
        return false
    end

    local targetPlayer = QBCore.Functions.GetPlayer(target)
    if not targetPlayer then return false end

    local targetIdentifier = targetPlayer.PlayerData.citizenid
    if home.keys:HasKey(targetIdentifier) then return false end

    if not home.keys:AddHolder(targetIdentifier, keyName or Housing:Name(target)) then return false end

    Housing:SyncKeys(home)
    Housing:Notify(target, ('Kamu menerima kunci %s'):format(home.name), 'success')
    Housing:Log('key', ('%s memberi kunci %s ke %s'):format(identifier, home.name, targetIdentifier), home, Housing:Name(src))
    return true
end)

lib.callback.register('Housing:server:RemoveKeyHolder', function(source, homeId, identifier, aptId)
    local src = source
    local home = Housing:GetHome(homeId)
    if not home then return false end

    local ownerIdentifier = Housing:GetIdentifier(src)
    if not home:IsOwner(ownerIdentifier, aptId) then return false end

    if not home.keys:RemoveHolder(identifier) then return false end

    Housing:SyncKeys(home)
    local target = Housing:SourceByIdentifier(identifier)
    if target then Housing:Notify(target, ('Kunci %s dicabut'):format(home.name), 'error') end
    Housing:Log('key', ('%s mencabut kunci %s dari %s'):format(ownerIdentifier, home.name, identifier), home, Housing:Name(src))
    return true
end)

lib.callback.register('Housing:server:GetCreator', function(source, homeId)
    local home = Housing:GetHome(homeId)
    if not home then return nil end
    return { realestate = home.realestate, fee = home.realestateFee }
end)

lib.callback.register('Housing:server:GetUpgradeList', function(source, homeId, aptId)
    local home = Housing:GetHome(homeId)
    if not home then return {} end

    local identifier = Housing:GetIdentifier(source)
    if not home:IsOwner(identifier, aptId) then return {} end

    return {
        keys = { current = #home.keys.holders, max = Config.Server.upgradeLimits.keys },
        storage = { current = #home.storages, max = Config.Server.upgradeLimits.storage },
        wardrobes = { current = #home.wardrobes, max = Config.Server.upgradeLimits.wardrobes },
        garages = { current = #home.garages, max = Config.Server.upgradeLimits.garages },
    }
end)

exports('GetHomesList', function()
    local list = {}
    for _, home in pairs(Housing.homes) do
        list[#list + 1] = home:Snapshot()
    end
    return list
end)