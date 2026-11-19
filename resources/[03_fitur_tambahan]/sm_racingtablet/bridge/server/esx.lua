if GetResourceState('es_extended') ~= 'started' then return end
if Config.Debug then print('Using ESX server bridge') end

local ESX = exports['es_extended']:getSharedObject()

local function playerOf(src) return ESX.GetPlayerFromId(src) end

function getCitizenId(src)
    local player = playerOf(src)
    return player and player.identifier or nil
end

function getPlayerName(src)
    local player = playerOf(src)
    return player and player.getName() or nil
end

function getJobName(src)
    local player = playerOf(src)
    return player and player.job.name or nil
end

function getJobLevel(src)
    local player = playerOf(src)
    return player and player.job.grade or nil
end

function hasItem(src, item)
    local player = playerOf(src)
    if not player then return false end
    return (player.getInventoryItem(item) or {}).count > 0
end

function addMoney(src, _, amount)
    local player = playerOf(src)
    if not player then return false end
    player.addMoney(amount)
    return true
end

function removeMoney(src, _, amount)
    local player = playerOf(src)
    if not player then return false end
    player.removeMoney(amount)
    return true
end