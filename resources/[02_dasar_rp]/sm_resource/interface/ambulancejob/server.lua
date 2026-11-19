--[[
    ambulancejob :: server
    Status mati per citizenid, hapus item saat mati, tagihan respawn, kasur, NPC dokter, anticombat.
]]

local srv = localmodule 'config.server'
local shared = localmodule 'config.shared'
local beds = localmodule 'data.bed'
local checkins = localmodule 'data.checkin'

local MEDIC = srv.medicalJobs or {}
local JOB_ITEM = srv.jobItems or shared.medicItem or {}
local PURGE = srv.itemsToDeleteOnDeath or {}
local BILL = srv.billCost or 50000
local DOC_CD = srv.docCooldown or 1
local WIPE = srv.wipeInventoryOnRespawn == true
local GRACE = srv.disconnectGracePeriod or 600
local ANTICOMBAT = srv.anticombatCooldownTime or 900

local TABLE = 'ambulance_dead'

local dead = {}
local docStamp = {}

local function playerOf(src)
    return qb_ecore:GetPlayer(src)
end

local function notify(src, message, kind)
    TriggerClientEvent('ox_lib:notify', src, { description = message, type = kind or 'error' })
end

local function isMedic(player)
    return player and MEDIC[player.PlayerData.job.name] == true
end

local function near(src, coords, radius)
    local ped = GetPlayerPed(src)
    if ped == 0 then return false end
    return #(GetEntityCoords(ped) - coords) <= radius
end

local function snapshot(src)
    local items = ox_inventory:GetInventoryItems(src) or {}
    local out = {}

    for _, entry in pairs(items) do
        out[#out + 1] = { name = entry.name, count = entry.count, metadata = entry.metadata, slot = entry.slot }
    end

    return out
end

local function purge(src)
    for i = 1, #PURGE do
        local item = PURGE[i]
        local count = ox_inventory:GetItemCount(src, item)

        if count and count > 0 then
            ox_inventory:RemoveItem(src, item, count)
        end
    end
end

local function saveState(cid, state)
    local row = MySQL.single.await('SELECT citizenid FROM ' .. TABLE .. ' WHERE citizenid = ?', { cid })

    if row then
        MySQL.update('UPDATE ' .. TABLE .. ' SET dead = ?, died_at = ?, anticombat_until = ?, inventory = ? WHERE citizenid = ?', {
            state.dead and 1 or 0, state.died_at or 0, state.anticombat_until or 0,
            state.inventory and json.encode(state.inventory) or nil, cid,
        })
    else
        MySQL.insert('INSERT INTO ' .. TABLE .. ' (citizenid, dead, died_at, anticombat_until, inventory) VALUES (?, ?, ?, ?, ?)', {
            cid, state.dead and 1 or 0, state.died_at or 0, state.anticombat_until or 0,
            state.inventory and json.encode(state.inventory) or nil,
        })
    end
end

RegisterNetEvent('ambulance:set_dead', function(state)
    local src = source
    local player = playerOf(src)
    if not player then return end

    local cid = player.PlayerData.citizenid
    dead[src] = dead[src] or {}

    if state then
        dead[src].dead = true
        dead[src].died_at = os.time()
        dead[src].inventory = snapshot(src)

        purge(src)
        saveState(cid, dead[src])
    else
        dead[src].dead = false
        dead[src].anticombat_until = os.time() + ANTICOMBAT

        TriggerClientEvent('ambulance:anticombat:start', src, ANTICOMBAT)
        saveState(cid, dead[src])
    end
end)

RegisterNetEvent('ambulance:set_anticombat', function(state)
    local src = source
    if not dead[src] then return end
    dead[src].anticombat_until = state and (os.time() + ANTICOMBAT) or 0
end)

lib.callback.register('ambulance:action:startCpr', function(src, targetId)
    local player = playerOf(src)
    local target = playerOf(tonumber(targetId) or 0)
    if not player or not target then return false end
    if not isMedic(player) then return false end

    local tped = GetPlayerPed(target.PlayerData.source)
    if tped == 0 or not near(src, GetEntityCoords(tped), 3.0) then return false end

    TriggerClientEvent('ambulance:action:playCprTarget', target.PlayerData.source, GetEntityCoords(GetPlayerPed(src)))

    return true
end)

RegisterNetEvent('ambulance:reviveplayer', function(targetId, requiredItem)
    local src = source
    local player = playerOf(src)
    local target = playerOf(tonumber(targetId) or 0)
    if not player or not target then return end
    if not isMedic(player) then return notify(src, 'Bukan tenaga medis.') end

    local tped = GetPlayerPed(target.PlayerData.source)
    if tped == 0 or not near(src, GetEntityCoords(tped), 4.0) then return notify(src, 'Terlalu jauh.') end

    local item = requiredItem or JOB_ITEM[player.PlayerData.job.name]
    if item and (ox_inventory:GetItemCount(src, item) or 0) < 1 then
        return notify(src, ('Butuh %s.'):format(item))
    end

    if item then ox_inventory:RemoveItem(src, item, 1) end

    TriggerClientEvent('ambulance:client:revive', target.PlayerData.source)
    TriggerClientEvent('hospital:client:RevivePlayer', target.PlayerData.source)

    notify(src, 'Pasien dihidupkan.', 'success')
end)

RegisterNetEvent('ambulance:treatWounds', function(targetId, requiredItem)
    local src = source
    local player = playerOf(src)
    local target = playerOf(tonumber(targetId) or 0)
    if not player or not target then return end
    if not isMedic(player) then return end

    local item = requiredItem or JOB_ITEM[player.PlayerData.job.name]
    if item and (ox_inventory:GetItemCount(src, item) or 0) < 1 then
        return notify(src, ('Butuh %s.'):format(item))
    end

    if item then ox_inventory:RemoveItem(src, item, 1) end

    TriggerClientEvent('hospital:client:TreatWounds', target.PlayerData.source)
    TriggerClientEvent('ambulance:action:heal', target.PlayerData.source)
end)

RegisterNetEvent('ambulance:treatment:heal', function()
    local src = source
    TriggerClientEvent('ambulance:action:heal', src)
end)

RegisterNetEvent('ambulance:respawn', function()
    local src = source
    local player = playerOf(src)
    if not player then return end

    local cid = player.PlayerData.citizenid
    local state = dead[src]

    if BILL > 0 then
        if not player.Functions.RemoveMoney('bank', BILL, 'hospital-bill') then
            player.Functions.RemoveMoney('cash', BILL, 'hospital-bill')
        end
    end

    if WIPE then
        local items = ox_inventory:GetInventoryItems(src) or {}
        for _, entry in pairs(items) do
            ox_inventory:RemoveItem(src, entry.name, entry.count, nil, entry.slot)
        end
    end

    if state then
        state.dead = false
        state.anticombat_until = os.time() + ANTICOMBAT
        saveState(cid, state)
    end

    TriggerClientEvent('ambulance:client:revive', src)
end)

RegisterNetEvent('ambulance:clearInventoryIfDead', function()
    local src = source
    if not dead[src] or not dead[src].dead then return end

    local items = ox_inventory:GetInventoryItems(src) or {}
    for _, entry in pairs(items) do
        ox_inventory:RemoveItem(src, entry.name, entry.count, nil, entry.slot)
    end
end)

RegisterNetEvent('ambulance:removeItem', function(itemType)
    local src = source
    itemType = tostring(itemType or '')
    if itemType == '' then return end

    local count = ox_inventory:GetItemCount(src, itemType)
    if count and count > 0 then ox_inventory:RemoveItem(src, itemType, count) end
end)

lib.callback.register('ambulance:bed:isUse', function(src, index)
    local bed = beds[tonumber(index) or 0]
    if not bed then return false end
    return bed.used == true
end)

RegisterNetEvent('ambulance:bed:leave', function(index)
    local bed = beds[tonumber(index) or 0]
    if bed then bed.used = false end
end)

RegisterNetEvent('ambulance:bed:send_checkin', function(checkinId)
    local src = source
    local player = playerOf(src)
    if not player then return end

    local entry
    for i = 1, #checkins do
        if checkins[i].checkinId == checkinId then entry = checkins[i] break end
    end

    if not entry then return end

    if not player.Functions.RemoveMoney('bank', entry.cost, 'hospital-checkin') then
        return notify(src, 'Uang tidak cukup.')
    end

    TriggerClientEvent('ambulance:bed:send_checkin', src, entry)
end)

RegisterNetEvent('ambulance:bed:send_treatment', function(checkinId)
    local src = source
    local player = playerOf(src)
    if not player then return end

    local entry
    for i = 1, #checkins do
        if checkins[i].checkinId == checkinId then entry = checkins[i] break end
    end

    if not entry then return end

    if not player.Functions.RemoveMoney('bank', entry.treatmentCost, 'hospital-treatment') then
        return notify(src, 'Uang tidak cukup.')
    end

    TriggerClientEvent('ambulance:bed:transferPatient', src, entry)
end)

RegisterNetEvent('ambulance:dokter_npc', function(data)
    local src = source
    local player = playerOf(src)
    if not player or type(data) ~= 'table' then return end

    local npc = (shared.dokter_npc or {})[data.k]
    if not npc then return end

    local action = npc.options[data.action]
    if not action or not action.enable then return end

    local stamp = GetGameTimer()
    if docStamp[src] and stamp - docStamp[src] < (DOC_CD * 1000) then return end
    docStamp[src] = stamp

    if not player.Functions.RemoveMoney('bank', action.price, 'doctor') then
        return notify(src, 'Uang tidak cukup.')
    end

    if data.action == 'revive' then
        local state = dead[src]
        if state and state.anticombat_until and state.anticombat_until > os.time() then
            return notify(src, 'Masih dalam masa tempur.')
        end

        TriggerClientEvent('hospital:client:RevivePlayer', src)
        TriggerClientEvent('ambulance:client:revive', src)
    else
        TriggerClientEvent('ambulance:action:heal', src)
    end
end)

RegisterNetEvent('ambulance:crutch:track', function(netId)
    local src = source
    if GetResourceState('sm_crutch') ~= 'started' then return end

    local entity = NetworkGetEntityFromNetworkId(tonumber(netId) or 0)
    if entity == 0 or not DoesEntityExist(entity) then return end

    TriggerEvent('sm_crutch:server:death', src)
end)

lib.callback.register('ambulance:buyVehicle', function(src, model, garageId, spawnId)
    local player = playerOf(src)
    if not player or not isMedic(player) then return nil end
    if type(model) ~= 'string' then return nil end

    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    local entity = CreateVehicle(GetHashKey(model), coords.x + 3.0, coords.y, coords.z, heading, true)
    if entity == 0 then return nil end

    local netId = NetworkGetNetworkIdFromEntity(entity)
    if netId == 0 then DeleteEntity(entity) return nil end

    local plate = ('AMB%04d'):format(math.random(0, 9999))
    SetVehicleNumberPlateText(entity, plate)

    return netId, { model = model }, plate
end)

lib.callback.register('ambulance:spawnHelicopter', function(src, model, garageId)
    local player = playerOf(src)
    if not player or not isMedic(player) then return nil end
    if type(model) ~= 'string' then return nil end

    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)

    local entity = CreateVehicle(GetHashKey(model), coords.x + 8.0, coords.y, coords.z + 1.0, GetEntityHeading(ped), true)
    if entity == 0 then return nil end

    local netId = NetworkGetNetworkIdFromEntity(entity)
    if netId == 0 then DeleteEntity(entity) return nil end

    SetVehicleOnGroundProperly(entity)

    return netId, { model = model }
end)

RegisterNetEvent('ambulance:send_dispatch', function(callData)
    if type(callData) ~= 'table' then return end
    callData.callerId = source
    TriggerEvent('sm_dispatch:server:addCall', callData)
end)

CreateThread(function()
    MySQL.query.await([[
    CREATE TABLE IF NOT EXISTS `ambulance_dead` (
        `citizenid` varchar(64) NOT NULL,
        `dead` tinyint(1) NOT NULL DEFAULT 0,
        `died_at` int(11) NOT NULL DEFAULT 0,
        `anticombat_until` int(11) NOT NULL DEFAULT 0,
        `inventory` longtext DEFAULT NULL,
        PRIMARY KEY (`citizenid`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    while true do
        Wait(60000)
        local cut = os.time() - GRACE

        MySQL.update('UPDATE ' .. TABLE .. ' SET inventory = NULL WHERE dead = 1 AND died_at < ?', { cut })
    end
end)

AddEventHandler('playerDropped', function()
    dead[source] = nil
    docStamp[source] = nil
end)

print('^2[ambulancejob] server siap^7')