local QBCore = exports['qb-core']:GetCoreObject()

local serverConfig = require 'gardener.config.server'

local Rewards = {}
local rewardCfg = serverConfig.reward

local function giveItem(source, item, count)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return end
    player.Functions.AddItem(item, count)
end

---@param source number
local function giveWeightedPool(source)
    local pool = rewardCfg.items.pool
    for i = 1, #pool do
        local entry = pool[i]
        if math.random(100) <= entry.chance then
            giveItem(source, entry.item, entry.count)
            return
        end
    end
end

---@param source number
local function givePerItem(source)
    local pool = rewardCfg.items.pool
    for i = 1, #pool do
        local entry = pool[i]
        if math.random(100) <= entry.chance then
            giveItem(source, entry.item, entry.count)
        end
    end
end

---@param source number
---@param money number
function Rewards.give(source, money)
    local player = QBCore.Functions.GetPlayer(source)
    if player then
        player.Functions.AddMoney(rewardCfg.moneyType, money, 'gardener-reward')
    end

    if rewardCfg.items and rewardCfg.items.enabled then
        if rewardCfg.items.mode == 'perItem' then
            givePerItem(source)
        else
            giveWeightedPool(source)
        end
    end
end

return Rewards
