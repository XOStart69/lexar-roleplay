if GetResourceState('ox_core') ~= 'started' then return end
if Config.Debug then print('Using OX server bridge') end

local Ox = exports.ox_core

function getCitizenId(src) return Ox:GetPlayer(src) end

function getPlayerName(src)
    local player = Ox:GetPlayer(src)
    return player and player.get('name') or nil
end

function getJobName(src)
    local player = Ox:GetPlayer(src)
    if not player then return nil end

    local group = player.getGroup()

    return group and group.name or nil
end

function getJobLevel(src) return nil end

function hasItem(src, item) return (exports.ox_inventory:GetItemCount(src, item) or 0) > 0 end

function addMoney(src, account, amount) return Ox:AddMoney(src, account or 'money', amount) end

function removeMoney(src, account, amount) return Ox:RemoveMoney(src, account or 'money', amount) end