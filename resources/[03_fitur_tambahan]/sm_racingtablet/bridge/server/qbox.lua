if GetResourceState('qbx_core') ~= 'started' then return end
if Config.Debug then print('Using QBX server bridge') end

local QBCore = exports.qbx_core:GetCoreObject()

local function playerOf(src) return QBCore.Functions.GetPlayer(src) end

function getCitizenId(src)
    local player = playerOf(src)
    return player and player.PlayerData.citizenid or nil
end

function getPlayerName(src)
    local player = playerOf(src)
    return player and ('%s %s'):format(player.PlayerData.charinfo.firstname, player.PlayerData.charinfo.lastname) or nil
end

function getJobName(src)
    local player = playerOf(src)
    return player and player.PlayerData.job.name or nil
end

function getJobLevel(src)
    local player = playerOf(src)
    return player and player.PlayerData.job.grade.level or nil
end

function hasItem(src, item)
    if Config.Inventory == 'ox' then
        return (exports.ox_inventory:GetItemCount(src, item) or 0) > 0
    end

    local player = playerOf(src)
    return player ~= nil and player.Functions.GetItemByName(item) ~= nil
end

function addMoney(src, account, amount)
    local player = playerOf(src)
    if not player then return false end
    return player.Functions.AddMoney(account, amount) == true
end

function removeMoney(src, account, amount)
    local player = playerOf(src)
    if not player then return false end
    return player.Functions.RemoveMoney(account, amount) == true
end