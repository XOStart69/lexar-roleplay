--[[
    sm_gruppe :: server
    Satu truk per pemain, rute dipilih server dari region terdekat, C4 dengan fuse server.
]]

local cfg = localmodule 'config'

local REWARDS = (cfg.item or {}).rewards or {}
local JOBCHECK = cfg.jobcheck or {}
local LIMIT = cfg.limit or {}
local MODELS = cfg.model or {}
local WEAPONS = cfg.guard_weapon or {}
local CLEANUP = cfg.cleanup or {}
local C4 = cfg.c4_mechanic or {}
local SPAWN = cfg.spawn or {}
local FINISH = (cfg.location or {}).truck_finish or {}
local LANG = cfg.lang or {}

local MAX_ACTIVE = LIMIT.max or 3
local COOLDOWN = (LIMIT.cooldown or 30) * 60
local MAX_FAILS = C4.maxFails or 2
local FUSE = CLEANUP.fuse or 30
local AFTER_LOOT = CLEANUP.afterLoot or 20
local AFTER_EXPLODE = CLEANUP.afterExplode or 900
local MAX_LIFETIME = CLEANUP.maxLifetime or 2700
local DELIVER = CLEANUP.deliverRadius or 20.0
local C4_ITEM = cfg.c4Item or 'c4_bomb'

local runs = {}
local cooldownUntil = {}
local fails = {}
local active = 0

local function playerOf(src)
    return qb_ecore:GetPlayer(src)
end

local function notify(src, message, kind)
    TriggerClientEvent('ox_lib:notify', src, { description = message, type = kind or 'error' })
end

local function countJob(jobName)
    local total = 0
    for _, raw in ipairs(GetPlayers()) do
        local player = playerOf(tonumber(raw))
        if player and player.PlayerData.job.name == jobName then total = total + 1 end
    end
    return total
end

local function nodes()
    local list = {}

    for region, points in pairs(SPAWN.regions or {}) do
        for i = 1, #points do list[#list + 1] = { region = region, coords = points[i] } end
    end

    return list
end

local function pickNode(src)
    local ped = GetPlayerPed(src)
    if ped == 0 then return nil end

    local coords = GetEntityCoords(ped)
    local all = nodes()
    if #all == 0 then return nil end

    for _ = 1, (SPAWN.nodeTries or 12) do
        local node = all[math.random(#all)]
        local gap = #(coords - vector3(node.coords.x, node.coords.y, node.coords.z))

        if gap >= (SPAWN.minDistance or 50.0) and gap <= (SPAWN.maxDistance or 500.0) then
            return node
        end
    end

    return nil
end

local function destroy(netId)
    local entity = NetworkGetEntityFromNetworkId(netId)
    if entity ~= 0 and DoesEntityExist(entity) then DeleteEntity(entity) end
end

local function finish(src, reason)
    local run = runs[src]
    if not run then return end

    if run.guards then
        for i = 1, #run.guards do
            if DoesEntityExist(run.guards[i]) then DeleteEntity(run.guards[i]) end
        end
    end

    if run.netId then destroy(run.netId) end

    runs[src] = nil
    active = math.max(active - 1, 0)

    if reason then notify(src, reason) end
end

lib.callback.register('sm_gruppe:server:start', function(src)
    local player = playerOf(src)
    if not player then return false end
    if runs[src] then return false end

    local cid = player.PlayerData.citizenid
    if (cooldownUntil[cid] or 0) > os.time() then return false end
    if MAX_ACTIVE > 0 and active >= MAX_ACTIVE then return false end

    if countJob('police') < (JOBCHECK.police or 0) then notify(src, LANG.cop_notify) return false end
    if countJob('ems') < (JOBCHECK.ems or 0) then return false end

    local node = pickNode(src)
    if not node then notify(src, LANG.no_spawn) return false end

    local truckModel = (MODELS.truck or {})[math.random(#(MODELS.truck or {}))]
    if not truckModel then return false end

    local entity = CreateVehicle(GetHashKey(truckModel), node.coords.x, node.coords.y, node.coords.z, node.coords.w, true)
    if not entity or entity == 0 then notify(src, LANG.spawn_blocked) return false end

    local netId = NetworkGetNetworkIdFromEntity(entity)
    if netId == 0 then
        DeleteEntity(entity)
        return false
    end

    local guards = {}
    local guardModel = (MODELS.guard or {})[1]

    if guardModel then
        for seat = -1, 1 do
            local ped = CreatePed(4, GetHashKey(guardModel), node.coords.x, node.coords.y, node.coords.z, 0.0, true)
            if ped and ped ~= 0 then
                SetPedIntoVehicle(ped, entity, seat)
                if #WEAPONS > 0 then
                    GiveWeaponToPed(ped, GetHashKey(WEAPONS[math.random(#WEAPONS)]), 250, false, true)
                end
                guards[#guards + 1] = ped
            end
        end
    end

    runs[src] = {
        netId = netId,
        guards = guards,
        stage = 'drive',
        expires = os.time() + MAX_LIFETIME,
    }

    active = active + 1
    fails[src] = 0

    local info = { netId = netId, node = node, finish = FINISH[1] }
    local result = lib.callback.await('sm_gruppe:beginRoute', src, info)

    return result ~= false
end)

lib.callback.register('sm_gruppe:armC4', function(src, netId)
    local player = playerOf(src)
    local run = runs[src]
    if not player or not run then return nil end
    if tonumber(netId) ~= run.netId then return nil end
    if run.stage ~= 'drive' then return nil end

    if (ox_inventory:GetItemCount(src, C4_ITEM) or 0) < 1 then
        notify(src, LANG.noc4)
        return nil
    end

    if not ox_inventory:RemoveItem(src, C4_ITEM, 1) then return nil end

    fails[src] = (fails[src] or 0) + 1
    if fails[src] >= MAX_FAILS then
        notify(src, (LANG.c4_destroyed or '%s'):format(MAX_FAILS))
    end

    run.stage = 'armed'
    run.fuse = os.time() + FUSE

    notify(src, LANG.c4_success, 'success')

    for _, raw in ipairs(GetPlayers()) do
        local target = playerOf(tonumber(raw))
        if target and target.PlayerData.job.name == 'police' then
            TriggerClientEvent('ox_lib:notify', tonumber(raw), { description = LANG.cop_notify, type = 'inform' })
        end
    end

    return FUSE
end)

RegisterNetEvent('sm_gruppe:removeC4', function()
    local run = runs[source]
    if not run or run.stage ~= 'armed' then return end

    run.stage = 'drive'
    run.fuse = nil
end)

RegisterNetEvent('sm_gruppe:loot', function(netId)
    local src = source
    local run = runs[src]
    if not run or tonumber(netId) ~= run.netId then return end
    if run.stage ~= 'exploded' and run.stage ~= 'drive' then return end
    if run.looted then return end

    local duration = lib.callback.await('sm_gruppe:lootProgress', src, netId)
    if not duration then return end

    run.looted = true

    for i = 1, #REWARDS do
        local reward = REWARDS[i]
        local amount = reward.count
        if type(amount) == 'table' then
            amount = math.random(amount.min or 1, amount.max or 1)
        end
        ox_inventory:AddItem(src, reward.name, amount or 1)
    end

    notify(src, LANG.loot, 'success')

    SetTimeout(AFTER_LOOT * 1000, function()
        if runs[src] then finish(src, nil) end
    end)
end)

RegisterNetEvent('sm_gruppe:arrived', function(netId)
    local src = source
    local run = runs[src]
    if not run or tonumber(netId) ~= run.netId then return end
    if run.stage == 'exploded' then return end

    local point = FINISH[1]
    if point then
        local entity = NetworkGetEntityFromNetworkId(netId)
        if entity ~= 0 and DoesEntityExist(entity) then
            if #(GetEntityCoords(entity) - point) > DELIVER then return end
        end
    end

    local player = playerOf(src)
    if player then cooldownUntil[player.PlayerData.citizenid] = os.time() + COOLDOWN end

    finish(src, nil)
end)

CreateThread(function()
    while true do
        Wait(1000)
        local stamp = os.time()

        for src, run in pairs(runs) do
            if run.stage == 'armed' and run.fuse and stamp >= run.fuse then
                run.stage = 'exploded'
                run.fuse = nil

                TriggerClientEvent('sm_gruppe:doExplode', -1, run.netId)

                if run.guards then
                    for i = 1, #run.guards do
                        if DoesEntityExist(run.guards[i]) then DeleteEntity(run.guards[i]) end
                    end
                    run.guards = {}
                end

                SetTimeout(AFTER_EXPLODE * 1000, function()
                    if runs[src] then finish(src, nil) end
                end)
            elseif run.expires <= stamp then
                local player = playerOf(src)
                if player then cooldownUntil[player.PlayerData.citizenid] = os.time() + COOLDOWN end
                finish(src, LANG.time_limit)
            end
        end
    end
end)

AddEventHandler('playerDropped', function()
    finish(source, nil)
    fails[source] = nil
end)

print('^2[sm_gruppe] server siap^7')