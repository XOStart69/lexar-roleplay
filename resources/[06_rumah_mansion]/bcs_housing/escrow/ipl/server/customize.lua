local T = Config.Server.tables

---@param home table
---@return table
local function dataOf(home)
    home.data.customizeIPL = home.data.customizeIPL or {}
    return home.data.customizeIPL
end

lib.callback.register('Housing:server:GetDataCustomizeIPL', function(source, homeId, aptId)
    local home = Housing:GetHome(homeId)
    if not home then return {} end

    local identifier = Housing:GetIdentifier(source)
    if not home:HasAccess(identifier, nil, aptId) and not Housing:IsAdmin(source) then return {} end

    return dataOf(home)
end)

RegisterNetEvent('Housing:server:SetDataCustomizeIPL', function(homeId, aptId, key, value, extra)
    local src = source
    local home = Housing:GetHome(homeId)
    if not home or not key then return end

    local identifier = Housing:GetIdentifier(src)
    if not home:HasAccess(identifier, nil, aptId) and not Housing:IsAdmin(src) then return end

    local data = dataOf(home)
    if key == 'Name' then
        data.name = value
    else
        data[key] = extra ~= nil and { value, extra } or value
    end

    home:Save()
    TriggerClientEvent('Housing:client:SetDataCustomizeIPL', -1, homeId, key, value)
end)

RegisterNetEvent('Housing:server:LoadDefaultCustomizeIPL', function(homeId, aptId)
    local src = source
    local home = Housing:GetHome(homeId)
    if not home then return end

    local identifier = Housing:GetIdentifier(src)
    if not home:HasAccess(identifier, nil, aptId) and not Housing:IsAdmin(src) then return end

    home.data.customizeIPL = nil
    home:Save()
    TriggerClientEvent('Housing:client:LoadDefaultCustomizeIPL', -1, homeId)
end)