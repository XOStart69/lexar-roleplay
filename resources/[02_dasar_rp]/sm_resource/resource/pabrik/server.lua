--[[
    vehicle_assembly :: server
    Kendaraan hantu, material per part, kepemilikan SPK, dan pencatatan ke player_vehicles.
]]

local cfg = localmodule 'config.shared'

local JOB = cfg.RequiredJob or {}
local OFFSETS = cfg.PartOffsets or {}
local VEHICLES = cfg.VehicleList or {}
local SPAWNS = cfg.SpawnLocations or {}
local GHOST = cfg.GhostVehicle or {}
local SYSTEM = cfg.AssemblySystem or {}
local LOCATION = cfg.AssemblyLocation

local JOB_NAME = JOB.name or 'pabrik'
local GRADE_ASSEMBLY = JOB.assemblyGrade or 0
local GRADE_SPK = JOB.spkGrade or 0
local PREFIX = cfg.PlatePrefix or 'SPK'
local TABLE = cfg.DatabaseTable or 'player_vehicles'
local GARAGE = cfg.DefaultGarage or 'Garasi Pabrik'
local SPK_ITEM = cfg.SPKItem or 'spk_form'

local assemblies = {}
local spawnOwner = {}

local function playerOf(src)
    return qb_ecore:GetPlayer(src)
end

local function notify(src, message, kind)
    TriggerClientEvent('ox_lib:notify', src, { description = message, type = kind or 'error' })
end

local function gradeOf(player)
    return player and player.PlayerData.job.grade.level or -1
end

local function hasJob(player, grade)
    if not player then return false end
    if player.PlayerData.job.name ~= JOB_NAME then return false end
    return gradeOf(player) >= grade
end

local function near(src, coords, radius)
    local ped = GetPlayerPed(src)
    if ped == 0 then return false end
    return #(GetEntityCoords(ped) - vector3(coords.x, coords.y, coords.z)) <= radius
end

local function findVehicle(model)
    for category, list in pairs(VEHICLES) do
        for i = 1, #list do
            if list[i].model == model then
                return list[i], category
            end
        end
    end
end

local function freeSpawn()
    for i = 1, #SPAWNS do
        if not spawnOwner[i] then return i, SPAWNS[i] end
    end
end

local function plate()
    return ('%s%05d'):format(PREFIX, math.random(0, 99999))
end

local function cleanup(netId, notifyOwner)
    local job = assemblies[netId]
    if not job then return end

    assemblies[netId] = nil
    if job.spawnIndex then spawnOwner[job.spawnIndex] = nil end

    local entity = NetworkGetEntityFromNetworkId(netId)
    if entity ~= 0 and DoesEntityExist(entity) then DeleteEntity(entity) end

    if job.owner then
        local player = playerOf(job.owner)
        if player then TriggerClientEvent('vehicle_assembly:cleanupGhostVehicle', job.owner) end
    end

    if notifyOwner and job.owner then notify(job.owner, 'Perakitan dibatalkan.') end
end

lib.callback.register('vehicle_assembly:checkJob', function(src, kind)
    local player = playerOf(src)
    if kind == 'spk' then return hasJob(player, GRADE_SPK) end
    return hasJob(player, GRADE_ASSEMBLY)
end)

RegisterNetEvent('vehicle_assembly:requestSpawn', function(model)
    local src = source
    local player = playerOf(src)
    if not player or not hasJob(player, GRADE_SPK) then return end

    local entry, category = findVehicle(tostring(model or ''))
    if not entry then return notify(src, 'Model tidak dikenal.') end

    if LOCATION and not near(src, LOCATION, 25.0) then return notify(src, 'Terlalu jauh dari pabrik.') end

    local index, spawn = freeSpawn()
    if not index then return notify(src, 'Slot spawn penuh.') end

    local entity = CreateVehicle(GetHashKey(entry.model), spawn.x, spawn.y, spawn.z, spawn.w or 0.0, true)
    if not entity or entity == 0 then return notify(src, 'Gagal membuat kendaraan.') end

    local netId = NetworkGetNetworkIdFromEntity(entity)
    if netId == 0 then
        DeleteEntity(entity)
        return notify(src, 'Gagal sinkronisasi kendaraan.')
    end

    spawnOwner[index] = src
    assemblies[netId] = {
        owner = src,
        category = category,
        vehicleId = entry.model,
        name = entry.name,
        materials = entry.materials or {},
        active = {},
        completed = {},
        spawnIndex = index,
    }

    TriggerClientEvent('vehicle_assembly:spawnResponse', src, true, spawn, entry, category, netId)
    TriggerClientEvent('vehicle_assembly:applyGhostProperties', src, netId, GHOST)
end)

lib.callback.register('vehicle_assembly:startPartAssembly', function(src, netId, partName)
    local job = assemblies[tonumber(netId) or 0]
    if not job or job.owner ~= src then return false end

    partName = tostring(partName or '')
    local materials = job.materials[partName]
    if not materials then return false end
    if job.completed[partName] then return false end
    if job.active[partName] then return false end

    local entity = NetworkGetEntityFromNetworkId(netId)
    if entity == 0 or not DoesEntityExist(entity) then return false end
    if #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(entity)) > 8.0 then return false end

    for i = 1, #materials do
        if (ox_inventory:GetItemCount(src, materials[i].item) or 0) < materials[i].count then return false end
    end

    for i = 1, #materials do
        if not ox_inventory:RemoveItem(src, materials[i].item, materials[i].count) then
            for k = 1, i - 1 do ox_inventory:AddItem(src, materials[k].item, materials[k].count) end
            return false
        end
    end

    job.active[partName] = true
    TriggerClientEvent('vehicle_assembly:updatePartStatus', src, netId, partName, 'active')

    return true
end)

RegisterNetEvent('vehicle_assembly:finishPart', function(netId, partName)
    local src = source
    local job = assemblies[tonumber(netId) or 0]
    if not job or job.owner ~= src then return end

    partName = tostring(partName or '')
    if not job.active[partName] then return end

    job.active[partName] = nil
    job.completed[partName] = true

    TriggerClientEvent('vehicle_assembly:updatePartStatus', src, netId, partName, 'done')
end)

RegisterNetEvent('vehicle_assembly:cancelPart', function(netId)
    local src = source
    local job = assemblies[tonumber(netId) or 0]
    if not job or job.owner ~= src then return end

    for partName in pairs(job.active) do
        job.active[partName] = nil
        TriggerClientEvent('vehicle_assembly:updatePartStatus', src, netId, partName, 'idle')
    end
end)

RegisterNetEvent('vehicle_assembly:cancelAssembly', function(netId)
    local src = source
    local job = assemblies[tonumber(netId) or 0]
    if not job or job.owner ~= src then return end

    cleanup(tonumber(netId), false)
end)

RegisterNetEvent('vehicle_assembly:completeAssembly', function(netId)
    local src = source
    local player = playerOf(src)
    local job = assemblies[tonumber(netId) or 0]
    if not player or not job or job.owner ~= src then return end

    for partName in pairs(job.materials) do
        if not job.completed[partName] then return notify(src, 'Masih ada part belum selesai.') end
    end

    local vehiclePlate = plate()

    MySQL.insert(
        ('INSERT INTO %s (citizenid, vehicle, plate, garage, mods, state) VALUES (?, ?, ?, ?, ?, ?)'):format(TABLE),
        { player.PlayerData.citizenid, job.vehicleId, vehiclePlate, GARAGE, '{}', 1 }
    )

    TriggerClientEvent('vehicle_assembly:assemblyCompleted', src, netId, job.name)
    notify(src, ('%s selesai, plat %s.'):format(job.name, vehiclePlate), 'success')

    cleanup(tonumber(netId), false)
end)

RegisterNetEvent('vehicle_assembly:transferVehicle', function(targetId, uniqueId)
    local src = source
    local giver = playerOf(src)
    local target = playerOf(tonumber(targetId) or 0)
    if not giver or not target then return end

    local slots = ox_inventory:Search(src, 'slots', SPK_ITEM) or {}
    local found

    for slot, entry in pairs(slots) do
        if entry.metadata and entry.metadata.uniqueId == uniqueId then found = slot break end
    end

    if not found then return notify(src, 'SPK tidak ditemukan.') end

    local metadata = slots[found].metadata
    metadata.creatorCid = target.PlayerData.citizenid
    metadata.creatorName = ('%s %s'):format(target.PlayerData.charinfo.firstname, target.PlayerData.charinfo.lastname)

    if not ox_inventory:RemoveItem(src, SPK_ITEM, 1, nil, found) then return end
    ox_inventory:AddItem(target.PlayerData.source, SPK_ITEM, 1, metadata)

    notify(src, 'SPK ditransfer.', 'success')
    notify(target.PlayerData.source, 'Kamu menerima SPK.', 'success')
end)

RegisterNetEvent('vehicle_assembly:endTestDrive', function()
    local src = source
    for netId, job in pairs(assemblies) do
        if job.owner == src and job.testDrive then
            job.testDrive = nil
            if job.spawnIndex then spawnOwner[job.spawnIndex] = nil end
            local entity = NetworkGetEntityFromNetworkId(netId)
            if entity ~= 0 and DoesEntityExist(entity) then DeleteEntity(entity) end
            return
        end
    end
end)

RegisterNetEvent('vehicle_assembly:server:createSPK', function(vehicleId)
    local src = source
    local player = playerOf(src)
    if not player or not hasJob(player, GRADE_SPK) then return end

    local entry = findVehicle(tostring(vehicleId or ''))
    if not entry then return notify(src, 'Model tidak dikenal.') end

    local uniqueId = ('%s-%d-%d'):format(player.PlayerData.citizenid, os.time(), math.random(1000, 9999))

    local ok = ox_inventory:AddItem(src, SPK_ITEM, 1, {
        uniqueId = uniqueId,
        vehicleId = entry.model,
        vehicleName = entry.name,
        creatorCid = player.PlayerData.citizenid,
        creatorName = ('%s %s'):format(player.PlayerData.charinfo.firstname, player.PlayerData.charinfo.lastname),
        createdDate = os.date('%d/%m/%Y'),
    })

    if not ok then return notify(src, 'Tas penuh.') end

    notify(src, 'SPK diterbitkan.', 'success')
end)

AddEventHandler('ox_inventory:usedItem', function(src, item, slot)
    if item ~= SPK_ITEM then return end

    local entry = ox_inventory:GetSlot(src, slot)
    if not entry or not entry.metadata or not entry.metadata.uniqueId then return end

    TriggerClientEvent('vehicle_assembly:openSPKMenu', src, {
        vehicleId = entry.metadata.vehicleId,
        creatorName = entry.metadata.creatorName,
        creatorCid = entry.metadata.creatorCid,
        createdDate = entry.metadata.createdDate,
        vehicleName = entry.metadata.vehicleName,
    }, slot, entry.metadata.uniqueId)
end)

AddEventHandler('playerDropped', function()
    local src = source
    for netId, job in pairs(assemblies) do
        if job.owner == src then cleanup(netId, false) end
    end
end)

print('^2[vehicle_assembly] server siap^7')