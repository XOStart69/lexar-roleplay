local T = Config.Server.tables

RegisterNetEvent('Housing:server:OpenHomeStorage', function(homeId, storageId, aptId)
    local src = source
    local home = Housing:GetHome(homeId)
    if not home or not storageId then return end

    local identifier = Housing:GetIdentifier(src)
    if not home:HasAccess(identifier, 'storage', aptId) then
        Housing:Notify(src, 'Kamu tidak punya akses', 'error')
        return
    end

    local list = home:IsApartment() and aptId and (home:GetApartment(aptId) or {}).storages or home.storages
    local storage
    for i = 1, #(list or {}) do
        if tostring(list[i].id) == tostring(storageId) then
            storage = list[i]
            break
        end
    end
    if not storage then return end

    local stashId = ('storage:%s:%s'):format(homeId, storageId)
    Inventory.RegisterStash(stashId, ('Storage %s'):format(home.name),
        storage.slots or Config.FurnitureStorage.slots, storage.weight or Config.FurnitureStorage.weight,
        home.owner, storage.coords)

    if Config.Inventory == 'ox_inventory' then
        TriggerClientEvent('ox_inventory:openInventory', src, 'stash', stashId)
    else
        TriggerClientEvent('Housing:client:OpenStash', src, stashId, storage.weight, storage.slots)
    end
end)