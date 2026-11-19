local T = Config.Server.tables

---@param home table
---@param aptId string|number|nil
---@return table[]
local function storagesOf(home, aptId)
    if home:IsApartment() and aptId and aptId ~= 'nil' then
        local apt = home:GetApartment(aptId)
        return apt and apt.storages or {}
    end
    return home.storages
end

lib.callback.register('Housing:server:GetHomeStoragesAdmin', function(source, homeId, aptId)
    local home = Housing:GetHome(homeId)
    if not home then return {} end
    if not Housing:IsAdmin(source) and not Housing:CanManage(source, home, 'storage') then return {} end

    return storagesOf(home, aptId)
end)

RegisterNetEvent('Housing:server:ForceOpenInventory', function(storageId)
    local src = source
    local data = Housing.players[src]
    if not data or not data.homeId then return end

    local home = Housing:GetHome(data.homeId)
    if not home then return end
    if not home:HasAccess(data.identifier, 'storage', data.aptId) and not Housing:IsAdmin(src) then return end

    local list = home:IsApartment() and data.aptId and (home:GetApartment(data.aptId) or {}).storages or home.storages
    local storage
    for i = 1, #(list or {}) do
        if tostring(list[i].id) == tostring(storageId) then
            storage = list[i]
            break
        end
    end
    if not storage then return end

    local stashId = ('storage:%s:%s'):format(home.identifier, storageId)
    Inventory.RegisterStash(stashId, ('Storage %s'):format(home.name),
        storage.slots or Config.FurnitureStorage.slots, storage.weight or Config.FurnitureStorage.weight,
        home.owner, storage.coords)

    TriggerClientEvent('ox_inventory:openInventory', src, 'stash', stashId)
end)

lib.callback.register('Housing:server:DeleteStorage', function(source, homeId, storageId)
    local src = source
    local home = Housing:GetHome(homeId)
    if not home or not storageId then return false end

    local identifier = Housing:GetIdentifier(src)
    if not home:HasAccess(identifier, 'storage') and not Housing:CanManage(src, home, 'storage') then return false end

    local list = home.storages
    local removed
    for i = 1, #list do
        if tostring(list[i].id) == tostring(storageId) then
            removed = table.remove(list, i)
            break
        end
    end
    if not removed then return false end

    MySQL.query(('DELETE FROM `%s` WHERE `home` = ? AND `storageId` = ?'):format(T.storages),
        { homeId, tostring(storageId) })

    TriggerClientEvent('Housing:client:DeleteStorage', -1, homeId, storageId, nil)
    Housing:Log('storage', ('%s menghapus storage %s'):format(identifier, storageId), home, Housing:Name(src))
    return true
end)

RegisterNetEvent('Housing:server:SaveStorages', function(data)
    local src = source
    local homeId = type(data) == 'table' and data.homeId or nil
    if not homeId or type(data.storages) ~= 'table' then return end

    local home = Housing:GetHome(homeId)
    if not home then return end
    if not Housing:IsAdmin(src) and not Housing:CanManage(src, home, 'storage') then return end

    local list = storagesOf(home, data.aptId)
    for i = 1, #list do
        for j = 1, #data.storages do
            if tostring(list[i].id) == tostring(data.storages[j].id) then
                list[i].weight = data.storages[j].weight
                list[i].slots = data.storages[j].slots
                MySQL.update(('UPDATE `%s` SET `weight` = ?, `slots` = ? WHERE `home` = ? AND `storageId` = ?'):format(T.storages),
                    { list[i].weight, list[i].slots, homeId, tostring(list[i].id) })
                break
            end
        end
    end

    TriggerClientEvent('Housing:client:SaveStorages', -1, homeId, list)
end)