local T = Config.Server.tables

---@param src number
---@param home table
---@return boolean
local function canEdit(src, home)
    return Housing:IsAdmin(src) or Housing:CanManage(src, home, 'configuration')
end

RegisterNetEvent('Housing:server:AddWardrobe', function(homeId, data, aptId)
    local src = source
    local home = Housing:GetHome(homeId)
    if not home or type(data) ~= 'table' or not data.name then return end
    if not canEdit(src, home) then return end

    local limit = home.configuration.limitWardrobes or Config.configuration.LimitWardrobes
    if #home.wardrobes >= limit then
        Housing:Notify(src, 'Batas lemari tercapai', 'error')
        return
    end

    local wardrobe = { name = data.name, coords = data.coords, outfits = {} }
    home.wardrobes[#home.wardrobes + 1] = wardrobe

    MySQL.insert(('INSERT INTO `%s` (`home`, `aptId`, `name`, `coords`, `outfits`) VALUES (?, ?, ?, ?, ?)'):format(T.wardrobes),
        { homeId, aptId, wardrobe.name, json.encode(wardrobe.coords or {}), json.encode({}) })

    TriggerClientEvent('Housing:client:AddWardrobe', -1, homeId, wardrobe, aptId)
end)

RegisterNetEvent('Housing:server:DeleteWardrobe', function(homeId, name, aptId)
    local src = source
    local home = Housing:GetHome(homeId)
    if not home or not name then return end
    if not canEdit(src, home) then return end

    for i = 1, #home.wardrobes do
        if home.wardrobes[i].name == name then
            table.remove(home.wardrobes, i)
            break
        end
    end

    MySQL.query(('DELETE FROM `%s` WHERE `home` = ? AND `name` = ?'):format(T.wardrobes), { homeId, name })
    TriggerClientEvent('Housing:client:DeleteWardrobe', -1, homeId, name)
end)

RegisterNetEvent('Housing:server:SaveOutfit', function(homeId, label, appearance)
    local src = source
    local home = Housing:GetHome(homeId)
    if not home or not label or type(appearance) ~= 'table' then return end

    local identifier = Housing:GetIdentifier(src)
    if not home:HasAccess(identifier, 'wardrobe') then return end

    home.data.outfits = home.data.outfits or {}
    home.data.outfits[#home.data.outfits + 1] = { label = label, appearance = appearance, owner = identifier }
    home:Save()
end)

RegisterNetEvent('Housing:server:DeleteOutfit', function(homeId, label)
    local src = source
    local home = Housing:GetHome(homeId)
    if not home or not label or not home.data.outfits then return end

    local identifier = Housing:GetIdentifier(src)
    if not home:HasAccess(identifier, 'wardrobe') then return end

    for i = 1, #home.data.outfits do
        if home.data.outfits[i].label == label then
            table.remove(home.data.outfits, i)
            break
        end
    end
    home:Save()
end)