RegisterNetEvent('Housing:server:CreateKeyItem', function(homeId, aptId, name, permissions)
    local src = source
    local home = Housing:GetHome(homeId)
    if not home or not name then return end

    local identifier = Housing:GetIdentifier(src)
    if not home:IsOwner(identifier, aptId) then return end

    local price = Config.KeyAsItem.Price or 0
    if not Housing:RemoveMoney(src, Config.KeyAsItem.Account or 'bank', price, 'housing-key') then
        Housing:Notify(src, 'Uang tidak cukup', 'error')
        return
    end

    local key = home.keys:CreateKey(name, permissions)
    if not key then
        Housing:Notify(src, 'Nama kunci sudah dipakai', 'error')
        return
    end

    Housing:AddItem(src, Config.KeyAsItem.ItemName, 1)
    Housing:SyncKeys(home)
    Housing:Notify(src, 'Kunci dibuat', 'success')
end)

RegisterNetEvent('Housing:server:DuplicateKeyItem', function(item)
    local src = source
    local homeId = item and item.info and item.info.home
    if not homeId then return end

    local home = Housing:GetHome(homeId)
    if not home then return end

    local price = Config.KeyAsItem.DuplicatePrice or 0
    if not Housing:RemoveMoney(src, Config.KeyAsItem.Account or 'bank', price, 'housing-key-copy') then
        Housing:Notify(src, 'Uang tidak cukup', 'error')
        return
    end

    Housing:AddItem(src, Config.KeyAsItem.ItemName, 1)
    Housing:Notify(src, 'Kunci diduplikasi', 'success')
end)