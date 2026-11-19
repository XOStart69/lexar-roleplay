local T = Config.Server.tables

---@param src number
---@param home table
---@return boolean
local function canEdit(src, home)
    return Housing:IsAdmin(src) or Housing:CanManage(src, home, 'teleports')
end

---@param home table
---@param name string
---@return table?, number?
local function findTeleport(home, name)
    for i = 1, #home.teleports do
        if home.teleports[i].name == name then
            return home.teleports[i], i
        end
    end
end

RegisterNetEvent('Housing:server:AddTeleport', function(homeId, name, inside, outside)
    local src = source
    local home = Housing:GetHome(homeId)
    if not home or not name or type(inside) ~= 'table' or type(outside) ~= 'table' then return end
    if not canEdit(src, home) then return end

    local data = { name = name, inside = inside, outside = outside, locked = false }
    home.teleports[#home.teleports + 1] = data

    MySQL.insert(('INSERT INTO `%s` (`home`, `name`, `inside`, `outside`) VALUES (?, ?, ?, ?)'):format(T.teleports),
        { homeId, name, json.encode(inside), json.encode(outside) })

    TriggerClientEvent('Housing:client:AddTeleport', -1, homeId, data)
end)

RegisterNetEvent('Housing:server:DeleteTeleport', function(homeId, name)
    local src = source
    local home = Housing:GetHome(homeId)
    if not home or not name then return end
    if not canEdit(src, home) then return end

    local _, index = findTeleport(home, name)
    if not index then return end

    table.remove(home.teleports, index)
    MySQL.query(('DELETE FROM `%s` WHERE `home` = ? AND `name` = ?'):format(T.teleports), { homeId, name })

    TriggerClientEvent('Housing:client:DeleteTeleport', -1, homeId, name)
end)

RegisterNetEvent('Housing:server:MoveTeleport', function(homeId, name, inside, outside)
    local src = source
    local home = Housing:GetHome(homeId)
    if not home or not name then return end
    if not canEdit(src, home) then return end

    local teleport = findTeleport(home, name)
    if not teleport then return end

    teleport.inside = inside
    teleport.outside = outside
    MySQL.update(('UPDATE `%s` SET `inside` = ?, `outside` = ? WHERE `home` = ? AND `name` = ?'):format(T.teleports),
        { json.encode(inside), json.encode(outside), homeId, name })

    TriggerClientEvent('Housing:client:MoveTeleport', -1, homeId, teleport)
end)

RegisterNetEvent('Housing:server:ToggleLockTeleport', function(homeId, name)
    local src = source
    local home = Housing:GetHome(homeId)
    if not home or not name then return end

    local identifier = Housing:GetIdentifier(src)
    if not home:HasAccess(identifier, 'doorlock') and not canEdit(src, home) then return end

    local teleport = findTeleport(home, name)
    if not teleport then return end

    teleport.locked = not teleport.locked
    MySQL.update(('UPDATE `%s` SET `locked` = ? WHERE `home` = ? AND `name` = ?'):format(T.teleports),
        { teleport.locked and 1 or 0, homeId, name })

    TriggerClientEvent('Housing:client:ToggleLockTeleport', -1, homeId, name, teleport.locked)
end)