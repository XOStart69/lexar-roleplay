--[[
    sm_outfitbag :: server
    Tas outfit berbasis item. Satu tas aktif per karakter, hanya pemilik yang bisa buka/ambil.
    Masa berlaku dihitung sejak tas pertama kali di-use dan disimpan di metadata item.
]]

local config = localmodule 'config'

local item = config.Item or 'outfitbag'
local expireDays = config.ExpireDays or 30
local Locale = config.Locale or {}

local QBCore = exports['qb-core']:GetCoreObject()

local bags = {}
local pending = {}

local SCHEMA = [[
CREATE TABLE IF NOT EXISTS `sm_outfitbag_bags` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `citizenid` varchar(64) NOT NULL,
    `x` double NOT NULL,
    `y` double NOT NULL,
    `z` double NOT NULL,
    `heading` double NOT NULL DEFAULT 0,
    `expires` bigint(20) NOT NULL,
    PRIMARY KEY (`id`),
    KEY `citizenid` (`citizenid`),
    KEY `expires` (`expires`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
]]

local function notify(src, message, nType)
    lib.notify(src, { description = message, type = nType or 'inform', position = 'center-right' })
end

local function cid(src)
    local player = QBCore.Functions.GetPlayer(src)
    return player and player.PlayerData.citizenid or nil
end

local function bagOf(citizenid)
    for bagId, bag in pairs(bags) do
        if bag.citizenid == citizenid then return bagId, bag end
    end
end

local function toClient(bag)
    return { coords = bag.coords, heading = bag.heading, ownerSrc = bag.ownerSrc }
end

exports('outfitbag', function(_, event, itemData, inventory, slot)
    if event ~= 'usingItem' then return end
    local src = inventory and inventory.id or source
    if not src then return end

    local id = cid(src)
    if not id then return end

    if bagOf(id) then
        return notify(src, Locale.already_placed, 'error')
    end

    local metadata = (inventory.items[slot] and inventory.items[slot].metadata) or {}
    local now = os.time()

    if metadata.expires and now > tonumber(metadata.expires) then
        notify(src, Locale.expired, 'error')
        exports.ox_inventory:RemoveItem(src, item, 1, nil, slot)
        return
    end

    if not metadata.expires then
        metadata.expires = now + expireDays * 86400
        metadata.owner = id
        exports.ox_inventory:SetMetadata(src, slot, metadata)
    end

    pending[src] = { slot = slot, metadata = metadata }
    TriggerClientEvent('sm_outfitbag:client:placeBag', src)
end)

RegisterNetEvent('sm_outfitbag:server:cancelPlace', function()
    pending[source] = nil
end)

RegisterNetEvent('sm_outfitbag:server:bagPlaced', function(coords, heading)
    local src = source
    local state = pending[src]
    if not state or type(coords) ~= 'table' then return end

    pending[src] = nil

    local id = cid(src)
    if not id then return end
    if bagOf(id) then return end

    local expires = tonumber(state.metadata.expires) or (os.time() + expireDays * 86400)

    exports.ox_inventory:RemoveItem(src, item, 1, nil, state.slot)

    local bagId = MySQL.insert.await([[
        INSERT INTO sm_outfitbag_bags (citizenid, x, y, z, heading, expires) VALUES (?, ?, ?, ?, ?, ?)
    ]], { id, coords.x, coords.y, coords.z, tonumber(heading) or 0.0, expires })

    if not bagId then return end

    local bag = {
        id = bagId,
        citizenid = id,
        coords = vec3(coords.x, coords.y, coords.z),
        heading = tonumber(heading) or 0.0,
        ownerSrc = src,
        expires = expires
    }

    bags[bagId] = bag
    TriggerClientEvent('sm_outfitbag:client:addBag', -1, bagId, toClient(bag))
end)

RegisterNetEvent('sm_outfitbag:server:bagPicked', function()
    local src = source
    local id = cid(src)
    if not id then return end

    local bagId, bag = bagOf(id)
    if not bagId then return end

    if not exports.ox_inventory:AddItem(src, item, 1, { expires = bag.expires, owner = id }) then
        return notify(src, 'Inventory penuh.', 'error')
    end

    bags[bagId] = nil
    MySQL.update('DELETE FROM sm_outfitbag_bags WHERE id = ?', { bagId })
    TriggerClientEvent('sm_outfitbag:client:removeBag', -1, bagId)
end)

lib.callback.register('sm_outfitbag:server:syncBags', function(src)
    local list = {}

    for bagId, bag in pairs(bags) do
        list[bagId] = toClient(bag)
    end

    return list
end)

AddEventHandler('playerDropped', function()
    pending[source] = nil
end)

CreateThread(function()
    MySQL.query.await(SCHEMA)
    MySQL.update.await('DELETE FROM sm_outfitbag_bags WHERE expires < ?', { os.time() })

    local rows = MySQL.query.await('SELECT * FROM sm_outfitbag_bags') or {}

    for i = 1, #rows do
        local row = rows[i]

        bags[row.id] = {
            id = row.id,
            citizenid = row.citizenid,
            coords = vec3(row.x, row.y, row.z),
            heading = tonumber(row.heading) or 0.0,
            ownerSrc = 0,
            expires = tonumber(row.expires) or 0
        }
    end

    print(('^2[sm_outfitbag] %d tas dimuat^7'):format(#rows))
end)

