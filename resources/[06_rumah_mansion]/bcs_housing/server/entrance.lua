local T = Config.Server.tables

---@param src number
---@param home table
---@param aptId string|number|nil
---@return boolean
local function hasEntryAccess(src, home, aptId)
    if Housing:IsAdmin(src) then return true end

    local identifier = Housing:GetIdentifier(src)
    if not identifier then return false end

    if home:HasAccess(identifier, 'doorlock', aptId) then return true end
    return Housing:IsPolice(src) and Config.robbery.enableRaid
end

RegisterNetEvent('Housing:server:LockHome', function(homeId, force, aptId, fromInside)
    local src = source
    local home = Housing:GetHome(homeId)
    if not home then return end

    if not force and not hasEntryAccess(src, home, aptId) then return end

    home:SetLocked(not home.locked)
    home.aptId = aptId

    if not home.locked and fromInside then
        local inside = home:GetInside(aptId)
        if #inside > 1 then return end
    end
end)

lib.callback.register('Housing:server:ToggleLock', function(source, homeId, aptId)
    local src = source
    local home = Housing:GetHome(homeId)
    if not home then return false end
    if not hasEntryAccess(src, home, aptId) then return home.locked end

    home:SetLocked(not home.locked)
    return home.locked
end)

lib.callback.register('Housing:server:EnterCheck', function(source, homeId, aptId, teleport)
    local src = source
    local home = Housing:GetHome(homeId)
    if not home then return false end
    if home.disabled then
        Housing:Notify(src, 'Rumah ini sedang dinonaktifkan', 'error')
        return false
    end

    local identifier = Housing:GetIdentifier(src)
    if home:CanEnter(identifier, aptId) then return true end

    if not Config.robbery.enable then
        Housing:Notify(src, 'Rumah terkunci', 'error')
        return false
    end

    local policeCount = 0
    for _, player in ipairs(QBCore.Functions.GetPlayers()) do
        if Housing:IsPolice(player) then policeCount = policeCount + 1 end
    end
    if policeCount < Config.robbery.minPolice then
        Housing:Notify(src, 'Rumah terkunci, polisi belum cukup', 'error')
        return false
    end

    return true
end)

RegisterNetEvent('Housing:server:AlertLockpick', function(homeId, aptId)
    local src = source
    local home = Housing:GetHome(homeId)
    if not home then return end

    home.data.lockpickFails = (home.data.lockpickFails or 0) + 1

    if Config.robbery.alertLockpick then
        Housing:Alert(home, ('%s sedang dibobol'):format(home.name), 'warning', aptId)
    end

    if Config.robbery.alertPolice and home.data.lockpickFails >= Config.robbery.alertAfterFailed then
        home.data.lockpickFails = 0
        for _, player in ipairs(QBCore.Functions.GetPlayers()) do
            if Housing:IsPolice(player) then
                TriggerClientEvent('Housing:client:BlipAlert', player, home.identifier)
            end
        end
    end

    TriggerClientEvent('Housing:client:StartLockpick', src, home.identifier, aptId)
    Housing:Log('lockpick', ('%s membobol %s'):format(Housing:Name(src) or src, home.name), home, Housing:Name(src))
end)

RegisterNetEvent('Housing:server:RemoveItem', function(item)
    if not item then return end
    Housing:RemoveItem(source, item, 1)
end)

RegisterNetEvent('Housing:removeItem', function(item)
    if not item then return end
    Housing:RemoveItem(source, item, 1)
end)

RegisterNetEvent('Housing:server:KnockDoor', function(homeId)
    local src = source
    local home = Housing:GetHome(homeId)
    if not home then return end

    local name = Config.ShowNameOnKnock and (Housing:Name(src) or 'Seseorang') or 'Seseorang'
    for _, target in ipairs(home:GetInside()) do
        Housing:Notify(target, ('%s mengetuk pintu %s'):format(name, home.name), 'info')
    end
end)

RegisterNetEvent('Housing:server:AlertOwner', function(homeId, aptId)
    local src = source
    if not Config.robbery.alertNonOwnerEntering then return end

    local home = Housing:GetHome(homeId)
    if not home then return end

    local identifier = Housing:GetIdentifier(src)
    if home:HasAccess(identifier, nil, aptId) then return end

    Housing:Alert(home, ('%s memasuki %s tanpa kunci'):format(Housing:Name(src) or 'Seseorang', home.name), 'warning', aptId)
end)

lib.callback.register('Housing:server:GetPlayersInside', function(source, homeId, aptId)
    local home = Housing:GetHome(homeId)
    if not home then return {} end

    local list = {}
    for _, target in ipairs(home:GetInside(aptId)) do
        local player = QBCore.Functions.GetPlayer(target)
        if player then
            list[#list + 1] = { source = target, name = Housing:Name(target) }
        end
    end
    return list
end)