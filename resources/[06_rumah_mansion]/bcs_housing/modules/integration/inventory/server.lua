Inventory = Inventory or {}

---@param id string
---@param label string
---@param slots number
---@param weight number
---@param owner string?
---@param coords table?
function Inventory.RegisterStash(id, label, slots, weight, owner, coords)
    if Config.Inventory ~= 'ox_inventory' then return end

    local ok, err = pcall(function()
        exports.ox_inventory:RegisterStash(id, label, slots, weight, owner, nil, coords)
    end)

    if not ok then
        print(('[bcs_housing] gagal register stash %s: %s'):format(id, err))
    end
end

RegisterNetEvent('Housing:server:OpenStash', function(identifier, weight, slots)
    local src = source
    if not identifier then return end

    Inventory.RegisterStash(identifier, 'Penyimpanan Rumah', slots or Config.FurnitureStorage.slots,
        weight or Config.FurnitureStorage.weight, identifier)

    if Config.Inventory == 'ox_inventory' then
        TriggerClientEvent('ox_inventory:openInventory', src, 'stash', identifier)
    else
        TriggerClientEvent('Housing:client:OpenStash', src, identifier, weight, slots)
    end
end)