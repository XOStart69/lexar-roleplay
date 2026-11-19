local T = Config.Server.tables

---@param home table
---@param aptId string|number|nil
---@return table[]
local function furnitureOf(home, aptId)
    if home:IsApartment() and aptId and aptId ~= 'nil' then
        local apt = home:GetApartment(aptId)
        return apt and apt.furniture or {}
    end
    return home.furniture
end

---@param home table
---@param aptId string|number|nil
local function persistFurniture(home, aptId)
    if home:IsApartment() and aptId then
        local apt = home:GetApartment(aptId)
        if apt then apt:Save() end
        return
    end

    MySQL.query(('DELETE FROM `%s` WHERE `home` = ? AND `aptId` IS NULL'):format(T.furniture), { home.identifier })
    for i = 1, #home.furniture do
        local item = home.furniture[i]
        MySQL.insert(('INSERT INTO `%s` (`home`, `model`, `label`, `coords`, `rotation`, `heading`, `area`, `identifier`) VALUES (?, ?, ?, ?, ?, ?, ?, ?)'):format(T.furniture), {
            home.identifier, item.model, item.label, json.encode(item.coords or {}),
            json.encode(item.rotation or {}), item.heading or 0, item.area, item.identifier,
        })
    end
end

lib.callback.register('Housing:server:GetOwnedFurnitures', function(source)
    local player = Housing:Player(source)
    if not player then return {} end

    local items = player.PlayerData.items or {}
    local list = {}
    for _, item in pairs(items) do
        if item and item.name == Config.FurnitureItem then
            list[#list + 1] = item
        end
    end
    return list
end)

lib.callback.register('Housing:server:BuyFurniture', function(source, data)
    local src = source
    if type(data) ~= 'table' or not data.model then return false end

    local price = tonumber(data.price) or 0
    if price > 0 and not Housing:RemoveMoney(src, Config.Server.defaultAccount, price, 'housing-furniture') then
        Housing:Notify(src, 'Uang tidak cukup', 'error')
        return false
    end

    if Config.FurnitureAsItem then
        Housing:AddItem(src, Config.FurnitureItem, 1)
    end

    return true
end)

lib.callback.register('Housing:server:CanStoreFurniture', function(source, data)
    local src = source
    if type(data) ~= 'table' then return false end

    local home = Housing:GetHome(data.homeId)
    if not home then return false end

    local identifier = Housing:GetIdentifier(src)
    if not home:HasAccess(identifier, 'furniture', data.aptId) then return false end

    local limit = home.configuration.maxStorage or Config.configuration.DefaultMaxStorage
    local count = 0
    for _, item in ipairs(furnitureOf(home, data.aptId)) do
        if item.identifier then count = count + 1 end
    end

    return count < limit
end)

RegisterNetEvent('Housing:server:PlaceFurniture', function(data)
    local src = source
    if type(data) ~= 'table' or not data.model then return end

    local home = Housing:GetHome(data.homeId)
    if not home then return end

    local identifier = Housing:GetIdentifier(src)
    if not home:HasAccess(identifier, 'furniture', data.aptId) then
        TriggerClientEvent('Housing:client:PlaceFurnitureFailed', src, data.key)
        return
    end

    if Config.FurnitureAsItem and not Housing:RemoveItem(src, Config.FurnitureItem, 1) then
        TriggerClientEvent('Housing:client:PlaceFurnitureFailed', src, data.key)
        return
    end

    local item = {
        model = data.model,
        label = data.label,
        coords = data.coords,
        rotation = data.rotation,
        heading = data.heading,
        area = data.area,
        identifier = data.identifier,
    }

    local list = furnitureOf(home, data.aptId)
    list[#list + 1] = item
    persistFurniture(home, data.aptId)

    TriggerClientEvent('Housing:client:UpdateFurniture', -1, home.identifier, list, data.aptId)
end)

RegisterNetEvent('Housing:server:StoreFurniture', function(data)
    local src = source
    if type(data) ~= 'table' then return end

    local home = Housing:GetHome(data.homeId)
    if not home then return end

    local identifier = Housing:GetIdentifier(src)
    if not home:HasAccess(identifier, 'furniture', data.aptId) then return end

    local list = furnitureOf(home, data.aptId)
    for i = 1, #list do
        if list[i].model == data.model and list[i].heading == data.heading then
            table.remove(list, i)
            break
        end
    end

    persistFurniture(home, data.aptId)
    if Config.FurnitureAsItem then Housing:AddItem(src, Config.FurnitureItem, 1) end

    TriggerClientEvent('Housing:client:UpdateFurniture', -1, home.identifier, list, data.aptId)
end)

RegisterNetEvent('Housing:server:GiveFurniture', function(model, targetId)
    local src = source
    local target = QBCore.Functions.GetPlayer(tonumber(targetId) or 0)
    if not target or not model then return end

    if Config.FurnitureAsItem and not Housing:RemoveItem(src, Config.FurnitureItem, 1) then
        Housing:Notify(src, 'Kamu tidak punya item furnitur', 'error')
        return
    end

    Housing:AddItem(target.PlayerData.source, Config.FurnitureItem, 1)
    Housing:Notify(src, 'Furnitur diberikan', 'success')
end)

lib.callback.register('Housing:server:SellFurniture', function(source, data)
    local src = source
    local price = type(data) == 'table' and tonumber(data.price) or nil
    if not price then return false end

    local refund = math.floor(price * ((Config.sellFurniturePercentage or 0) / 100))
    if refund > 0 then
        Housing:AddMoney(src, Config.Server.defaultAccount, refund, 'housing-furniture-sell')
    end
    return true
end)