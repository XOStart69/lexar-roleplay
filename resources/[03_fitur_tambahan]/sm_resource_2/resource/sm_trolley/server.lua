--[[
    sm_trolley :: server
    Satu troli per pemain. Stash ox_inventory, whitelist item, jarak otoritatif.
]]

local config = localmodule 'config'

local ITEM = config.item or 'trolley'
local MODEL = config.model or 'prop_rub_trolley01a'
local STASH = config.stash or {}
local SHARE = config.shareStash == true
local MAX_PER_PLAYER = config.maxPerPlayer or 1
local SERVER_RADIUS = config.serverRadius or 3.0
local INTERACT = config.interactDistance or 2.0

local trolleys = {}
local pending = {}

local function notify(src, message, kind)
    TriggerClientEvent('ox_lib:notify', src, { description = message, type = kind or 'error' })
end

local function playerOf(src)
    return qb_ecore:GetPlayer(src)
end

local function stashName(cid)
    if SHARE then return 'sm_trolley_shared' end
    return ('sm_trolley_%s'):format(cid)
end

local function registerStash(cid)
    local name = stashName(cid)
    ox_inventory:RegisterStash(name, STASH.label or 'Troli', STASH.slots or 50, STASH.maxWeight or 500000)
    return name
end

local function entityOf(src)
    local entry = trolleys[src]
    if not entry then return nil end
    if not entry.netId then return nil end

    local entity = NetworkGetEntityFromNetworkId(entry.netId)
    if entity == 0 or not DoesEntityExist(entity) then return nil end

    return entity
end

local function distanceTo(src, entity)
    local ped = GetPlayerPed(src)
    if ped == 0 then return 999.0 end
    return #(GetEntityCoords(ped) - GetEntityCoords(entity))
end

lib.callback.register('sm_trolley:place', function(src, slot, coords, heading)
    local player = playerOf(src)
    if not player then return false, 'Data pemain tidak siap.' end
    if trolleys[src] then return false, 'Kamu sudah membawa troli.' end
    if type(coords) ~= 'table' then return false, 'Posisi tidak valid.' end

    local pos = vector3(tonumber(coords.x) or 0.0, tonumber(coords.y) or 0.0, tonumber(coords.z) or 0.0)
    local ped = GetPlayerPed(src)
    if #(GetEntityCoords(ped) - pos) > 4.0 then return false, 'Terlalu jauh.' end

    if (ox_inventory:GetItemCount(src, ITEM) or 0) < 1 then return false, 'Troli tidak ada di tas.' end
    if not ox_inventory:RemoveItem(src, ITEM, 1, nil, slot) then return false, 'Gagal mengambil troli.' end

    local entity = CreateObject(GetHashKey(MODEL), pos.x, pos.y, pos.z, true, true)
    if not entity or entity == 0 then return false, 'Gagal membuat troli.' end

    SetEntityHeading(entity, (tonumber(heading) or 0.0) % 360.0)
    FreezeEntityPosition(entity, true)

    local netId = NetworkGetNetworkIdFromEntity(entity)
    if netId == 0 then
        DeleteEntity(entity)
        return false, 'Gagal sinkronisasi troli.'
    end

    trolleys[src] = { netId = netId, cid = player.PlayerData.citizenid, stash = registerStash(player.PlayerData.citizenid) }

    return true, nil, netId
end)

RegisterNetEvent('sm_trolley:open', function(netId)
    local src = source
    local entry = trolleys[src]
    if not entry then return notify(src, 'Kamu tidak memegang troli.') end
    if entry.netId ~= tonumber(netId) then return end

    local entity = entityOf(src)
    if not entity then return notify(src, 'Troli tidak ditemukan.') end
    if distanceTo(src, entity) > INTERACT + 1.0 then return notify(src, 'Terlalu jauh.') end

    ox_inventory:forceOpenInventory(src, 'stash', entry.stash)
end)

RegisterNetEvent('sm_trolley:push', function(netId)
    local src = source
    local entry = trolleys[src]
    if not entry or entry.netId ~= tonumber(netId) then return end

    local entity = entityOf(src)
    if not entity then return end
    if distanceTo(src, entity) > INTERACT + 1.0 then return notify(src, 'Terlalu jauh.') end

    TriggerClientEvent('sm_trolley:client:push', src, netId)
end)

RegisterNetEvent('sm_trolley:store', function(netId)
    local src = source
    local entry = trolleys[src]
    if not entry then return end

    local entity = entityOf(src)
    if entity and distanceTo(src, entity) > SERVER_RADIUS + 1.0 then
        return notify(src, 'Terlalu jauh.')
    end

    local items = ox_inventory:GetInventoryItems(entry.stash) or {}
    local hasItems = false
    for _ in pairs(items) do hasItems = true break end

    if hasItems then return notify(src, 'Kosongkan troli dulu.') end

    if entity then DeleteEntity(entity) end
    trolleys[src] = nil

    if not ox_inventory:AddItem(src, ITEM, 1) then
        notify(src, 'Tas penuh, troli hilang.')
    end
end)

RegisterNetEvent('sm_trolley:release', function()
    local src = source
    local entry = trolleys[src]
    if not entry then return end

    local entity = entityOf(src)
    if entity then FreezeEntityPosition(entity, true) end

    TriggerClientEvent('sm_trolley:client:release', src)
end)

AddEventHandler('playerDropped', function()
    local src = source
    local entry = trolleys[src]
    if not entry then return end

    local entity = NetworkGetEntityFromNetworkId(entry.netId)
    if entity ~= 0 and DoesEntityExist(entity) then DeleteEntity(entity) end

    trolleys[src] = nil
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    for src, entry in pairs(trolleys) do
        local entity = NetworkGetEntityFromNetworkId(entry.netId)
        if entity ~= 0 and DoesEntityExist(entity) then DeleteEntity(entity) end
    end

    trolleys = {}
end)

print('^2[sm_trolley] server siap^7')