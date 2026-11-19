local T = Config.Server.tables

---@param src number
---@param home table
---@return boolean
local function canEdit(src, home)
    return Housing:IsAdmin(src) or Housing:CanManage(src, home, 'garage')
end

RegisterNetEvent('Housing:server:AddGarage', function(homeId, data)
    local src = source
    local home = Housing:GetHome(homeId)
    if not home or type(data) ~= 'table' or not data.name then return end
    if not canEdit(src, home) then return end

    local limit = home.configuration.maxGarages or Config.configuration.DefaultMaxGarages
    if #home.garages >= limit then
        Housing:Notify(src, 'Batas garasi tercapai', 'error')
        return
    end

    local garage = { name = data.name, coords = data.coords, type = data.type }
    home.garages[#home.garages + 1] = garage

    MySQL.insert(('INSERT INTO `%s` (`home`, `name`, `coords`, `type`) VALUES (?, ?, ?, ?)'):format(T.garages),
        { homeId, garage.name, json.encode(garage.coords or {}), garage.type and json.encode(garage.type) or nil })

    TriggerClientEvent('Housing:client:AddGarage', -1, homeId, garage)
end)

RegisterNetEvent('Housing:server:DeleteGarage', function(homeId, data)
    local src = source
    local home = Housing:GetHome(homeId)
    local name = type(data) == 'table' and data.name or data
    if not home or not name then return end
    if not canEdit(src, home) then return end

    for i = 1, #home.garages do
        if home.garages[i].name == name then
            table.remove(home.garages, i)
            break
        end
    end

    MySQL.query(('DELETE FROM `%s` WHERE `home` = ? AND `name` = ?'):format(T.garages), { homeId, name })
    TriggerClientEvent('Housing:client:DeleteGarage', -1, homeId, data)
end)

RegisterNetEvent('Housing:server:MoveGarage', function(homeId, data)
    local src = source
    local home = Housing:GetHome(homeId)
    if not home or type(data) ~= 'table' or not data.name then return end
    if not canEdit(src, home) then return end

    for i = 1, #home.garages do
        if home.garages[i].name == data.name then
            home.garages[i].coords = data.coords
            MySQL.update(('UPDATE `%s` SET `coords` = ? WHERE `home` = ? AND `name` = ?'):format(T.garages),
                { json.encode(data.coords or {}), homeId, data.name })
            break
        end
    end

    TriggerClientEvent('Housing:client:MoveGarage', -1, homeId, data)
end)