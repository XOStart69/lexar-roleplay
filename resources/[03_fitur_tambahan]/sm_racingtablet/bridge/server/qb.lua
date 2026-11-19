if GetResourceState('qb-core') ~= 'started' or GetResourceState('qbx_core') == 'started' then return end
if Config.Debug then print('Using QB server bridge') end

local QBCore = exports['qb-core']:GetCoreObject()

---@param src number
---@return table?
local function playerOf(src)
    return QBCore.Functions.GetPlayer(src)
end

---@param src number
---@return string?
function getCitizenId(src)
    local player = playerOf(src)

    return player and player.PlayerData.citizenid or nil
end

---@param src number
---@return string?
function getPlayerName(src)
    local player = playerOf(src)

    return player and ('%s %s'):format(player.PlayerData.charinfo.firstname, player.PlayerData.charinfo.lastname) or nil
end

---@param src number
---@return string?
function getJobName(src)
    local player = playerOf(src)

    return player and player.PlayerData.job.name or nil
end

---@param src number
---@return number?
function getJobLevel(src)
    local player = playerOf(src)

    return player and player.PlayerData.job.grade.level or nil
end

---@param src number
---@param item string
---@return boolean
function hasItem(src, item)
    if Config.Inventory == 'ox' then
        return (exports.ox_inventory:GetItemCount(src, item) or 0) > 0
    end

    local player = playerOf(src)

    return player ~= nil and player.Functions.GetItemByName(item) ~= nil
end

---@param src number
---@param account string
---@param amount number
---@return boolean
function addMoney(src, account, amount)
    local player = playerOf(src)
    if not player then return false end

    return player.Functions.AddMoney(account, amount) == true
end

---@param src number
---@param account string
---@param amount number
---@return boolean
function removeMoney(src, account, amount)
    local player = playerOf(src)
    if not player then return false end

    return player.Functions.RemoveMoney(account, amount) == true
end