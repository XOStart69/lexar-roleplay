local Inventory = require 'modules.inventory.server'
local QB = exports['qb-core']:GetCoreObject()

local function fullName(charinfo)
    return ('%s %s'):format(charinfo.firstname or '', charinfo.lastname or '')
end

local function setupPlayer(player)
    local data = player.PlayerData
    data.identifier = data.citizenid
    data.name = fullName(data.charinfo)
    server.setPlayerInventory(data)

    local accounts = Inventory.GetAccountItemCounts(data.source)
    if not accounts then return end

    for account in pairs(accounts) do
        local key = account == 'money' and 'cash' or account
        Inventory.SetItem(data.source, account, data.money[key] or 0)
    end
end

AddEventHandler('QBCore:Server:PlayerLoaded', function(player)
    if player and player.PlayerData then setupPlayer(player) end
end)

AddEventHandler('QBCore:Server:OnPlayerUnload', function(source)
    server.playerDropped(source)
end)

AddEventHandler('QBCore:Server:OnJobUpdate', function(source, job)
    local inv = Inventory(source)
    if inv and inv.player and job then inv.player.groups[job.name] = job.grade.level end
end)

AddEventHandler('QBCore:Server:OnGangUpdate', function(source, gang)
    local inv = Inventory(source)
    if inv and inv.player and gang then inv.player.groups[gang.name] = gang.grade.level end
end)

function server.UseItem(source, itemName, data)
    local item = QB.Shared.Items[itemName]
    if item and item.usable then
        TriggerClientEvent('QBCore:Client:UseItem', source, itemName, data)
    end
end

function server.setPlayerData(player)
    local groups = {}
    if player.job and player.job.name then groups[player.job.name] = player.job.grade.level end
    if player.gang and player.gang.name then groups[player.gang.name] = player.gang.grade.level end

    return {
        source = player.source,
        name = fullName(player.charinfo),
        groups = groups,
        sex = player.charinfo.gender,
        dateofbirth = player.charinfo.birthdate,
    }
end

function server.syncInventory(inv)
    local accounts = Inventory.GetAccountItemCounts(inv)
    if not accounts then return end

    local player = QB.Functions.GetPlayer(inv.id)
    if not player then return end

    for account, amount in pairs(accounts) do
        local key = account == 'money' and 'cash' or account
        if player.Functions.GetMoney(key) ~= amount then
            player.Functions.SetMoney(key, amount, ('Sync %s with inventory'):format(account))
        end
    end
end

function server.hasLicense(inv, license)
    local player = QB.Functions.GetPlayer(inv.id)
    return player and player.PlayerData.metadata.licences[license]
end

function server.buyLicense(inv, license)
    local player = QB.Functions.GetPlayer(inv.id)
    if not player then return end

    if player.PlayerData.metadata.licences[license.name] then
        return false, 'already_have'
    elseif Inventory.GetItem(inv, 'money', false, true) < license.price then
        return false, 'can_not_afford'
    end

    Inventory.RemoveItem(inv, 'money', license.price)
    player.PlayerData.metadata.licences[license.name] = true
    player.Functions.SetMetaData('licences', player.PlayerData.metadata.licences)

    return true, 'have_purchased'
end

function server.isPlayerBoss(playerId)
    local player = QB.Functions.GetPlayer(playerId)
    return player and player.PlayerData.job.isboss and true or false
end

function server.getOwnedVehicleId(entityId)
    return Entity(entityId).state.vehicleid
end