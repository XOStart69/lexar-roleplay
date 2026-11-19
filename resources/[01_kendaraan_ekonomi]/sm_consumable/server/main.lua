local QBCore = exports['qb-core']:GetCoreObject()

local makanan = require 'consumable.makanan'
local minuman = require 'consumable.minuman'
local alkohol = require 'consumable.alcohol'
local other = require 'consumable.other'

local items = {}

local function merge(source)
    for key, value in pairs(source) do
        items[key] = value
    end
end

merge(makanan)
merge(minuman)
merge(alkohol)
merge(other)

local function clampStatus(Player, key, delta)
    local current = Player.PlayerData.metadata[key] or 100

    Player.Functions.SetMetaData(key, math.max(math.min(current + delta, 100), 0))
end

local function applyStatus(Player, cfg)
    if type(cfg.status) ~= 'table' then return end

    for key, delta in pairs(cfg.status) do
        if (key == 'hunger' or key == 'thirst') and type(delta) == 'number' then
            clampStatus(Player, key, delta)
        end
    end
end

local function useItem(source, itemName, label)
    local cfg = items[itemName]

    if not cfg then return false end

    TriggerClientEvent(('consumables:client:%s'):format(itemName), source, label)

    return true
end

exports('use', useItem)

RegisterNetEvent('consumables:server:use', function(itemName, label)
    useItem(source, itemName, label)
end)

for itemName, cfg in pairs(items) do
    RegisterNetEvent(('consumables:server:response:%s'):format(itemName), function(success)
        local source = source
        local Player = QBCore.Functions.GetPlayer(source)

        if not Player or not success then return end

        local item = Player.Functions.GetItemByName(itemName)

        if not item then return end

        if cfg.removeItems then
            Player.Functions.RemoveItem(itemName, 1)
        end

        applyStatus(Player, cfg)
    end)
end

RegisterNetEvent('ni_consumable:saveHealthArmour', function()
    local source = source
    local Player = QBCore.Functions.GetPlayer(source)
    local ped = GetPlayerPed(source)

    if not Player or not ped or ped == 0 then return end

    local health = GetEntityHealth(ped)
    local armour = GetPedArmour(ped)

    if health > 0 then
        Player.Functions.SetMetaData('health', math.max(health, 100))
    end

    Player.Functions.SetMetaData('armour', armour)
end)

AddEventHandler('playerDropped', function()
    TriggerClientEvent('onPlayerDropped', -1, source)
end)

lib.print.info(('sm_consumable server siap (%d item)'):format((function()
    local n = 0
    for _ in pairs(items) do n = n + 1 end
    return n
end)()))
