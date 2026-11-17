local QBCore = exports['qb-core']:GetCoreObject()

local serverConfig = require 'pelumber.config.server'

local Rewards = {}
local rewardCfg = serverConfig.reward

local function giveMoney(source)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return end
    player.Functions.AddMoney(rewardCfg.moneyType, rewardCfg.moneyPerMember, 'pelumber-reward')
end

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
function Rewards.give(source)
    giveMoney(source)

    if rewardCfg.items and rewardCfg.items.enabled then
        if rewardCfg.items.mode == 'perItem' then
            givePerItem(source)
        else
            giveWeightedPool(source)
        end
    end
end

return Rewards
