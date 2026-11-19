local T = Config.Server.tables

---@param home table
---@param name string
---@return table?, number?
local function findDoor(home, name)
    for i = 1, #home.doors do
        if home.doors[i].name == name then
            return home.doors[i], i
        end
    end
end

RegisterNetEvent('Housing:server:SetDoorState', function(homeId, name, state)
    local src = source
    local home = Housing:GetHome(homeId)
    if not home then return end

    local door = findDoor(home, name)
    if not door then return end

    local identifier = Housing:GetIdentifier(src)
    if not home:HasAccess(identifier, 'doorlock') and not Housing:IsPolice(src) and not Housing:IsAdmin(src) then
        return
    end

    door.state = state == true
    MySQL.update(('UPDATE `%s` SET `state` = ? WHERE `home` = ? AND `name` = ?'):format(T.doors),
        { door.state and 1 or 0, homeId, name })

    TriggerClientEvent('Housing:client:SetDoorState', -1, homeId, name, door.state)
end)

RegisterNetEvent('Housing:server:AddDoor', function(homeId, door)
    local src = source
    local home = Housing:GetHome(homeId)
    if not home or type(door) ~= 'table' then return end
    if not Housing:CanManage(src, home, 'createdoor') then return end

    local name = door.name or ('door_%d'):format(#home.doors + 1)
    local coords = door.coords or {}

    local id = MySQL.insert(('INSERT INTO `%s` (`home`, `name`, `coords`, `model`) VALUES (?, ?, ?, ?)'):format(T.doors),
        { homeId, name, json.encode(coords), door.model })

    home.doors[#home.doors + 1] = {
        id = id, name = name, coords = coords, model = door.model, state = false,
    }

    TriggerClientEvent('Housing:client:AddDoor', -1, homeId, home.doors[#home.doors])
    Housing:Log('door', ('%s menambah pintu %s'):format(Housing:Name(src) or src, name), home, Housing:Name(src))
end)

lib.callback.register('Housing:server:DeleteDoor', function(source, data)
    local src = source
    local homeId = type(data) == 'table' and data.homeId or nil
    local name = type(data) == 'table' and data.name or nil
    if not homeId or not name then return false end

    local home = Housing:GetHome(homeId)
    if not home then return false end
    if not Housing:CanManage(src, home, 'createdoor') then return false end

    local door, index = findDoor(home, name)
    if not door then return false end

    table.remove(home.doors, index)
    MySQL.query(('DELETE FROM `%s` WHERE `home` = ? AND `name` = ?'):format(T.doors), { homeId, name })

    TriggerClientEvent('Housing:client:DeleteDoor', -1, data)
    return true
end)