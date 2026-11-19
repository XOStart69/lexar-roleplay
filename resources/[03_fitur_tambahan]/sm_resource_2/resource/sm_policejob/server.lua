--[[
    sm_policejob :: server
    Borgol per citizenid (tahan relog), escort, potong/lockpick, geledah, garasi, laci bukti, cek plat.
]]

local cfg = localmodule 'config'

local CUFF_JOBS = cfg.cuffJobs or {}
local ESCORT_JOBS = cfg.escortJobs or {}
local CUFF_ITEMS = cfg.cuffItems or {}
local KEY_ITEMS = cfg.keyItems or {}
local BREAKOUT = cfg.breakout or {}
local BOLT = cfg.boltCutter or {}
local LOCKPICK = cfg.lockpick or {}
local SEARCH = cfg.search or {}
local VEHICLES = cfg.vehicles or {}
local GARAGES = cfg.garages or {}
local BYPASS = cfg.itemBypass or {}
local EVIDENCE = cfg.evidence or {}
local EVIDENCE_BADGES = cfg.evidenceBadges or {}
local PREFIX = cfg.platePrefix or {}

local INTERACT = cfg.interactDistance or 2.5
local ESCORT_DIST = cfg.escortDistance or 3.0
local CUFF_CD = (cfg.cuffCooldown or 5) * 1000
local GARAGE_DIST = cfg.garageDistance or 6.0
local GARAGE_CD = cfg.garageCooldown or 3000
local EVIDENCE_DIST = cfg.evidenceDistance or 5.0
local TRACKER = cfg.plateTracker
local TRACKER_DIST = cfg.plateTrackerDistance or 5.0

local CUFF_TABLE = 'police_cuffed'
local VEH_TABLE = 'police_vehicles'

local cuffed = {}
local escort = {}
local cuffStamp = {}
local garageStamp = {}

local function playerOf(src)
    return qb_ecore:GetPlayer(src)
end

local function notify(src, message, kind)
    TriggerClientEvent('ox_lib:notify', src, { description = message, type = kind or 'error' })
end

local function jobOf(player)
    return player and player.PlayerData.job.name or ''
end

local function gradeOf(player)
    return player and player.PlayerData.job.grade.level or 0
end

local function near(src, coords, radius)
    local ped = GetPlayerPed(src)
    if ped == 0 then return false end
    return #(GetEntityCoords(ped) - coords) <= radius
end

local function nearPed(src, target, radius)
    local ped, tped = GetPlayerPed(src), GetPlayerPed(target)
    if ped == 0 or tped == 0 then return false end
    return #(GetEntityCoords(ped) - GetEntityCoords(tped)) <= radius
end

local function hasAll(src, list)
    for i = 1, #list do
        if (ox_inventory:GetItemCount(src, list[i]) or 0) < 1 then return false end
    end
    return true
end

local function bypass(player, kind)
    local rule = BYPASS[kind] and BYPASS[kind][jobOf(player)]
    if not rule then return false end
    local grade = gradeOf(player)
    return grade >= (rule[1] or 0) and grade <= (rule[2] or 99)
end

local function saveCuff(cid, state)
    if state then
        MySQL.insert(
            ('INSERT INTO %s (citizenid, item, by_citizenid, created) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE item = VALUES(item), by_citizenid = VALUES(by_citizenid)'):format(CUFF_TABLE),
            { cid, state.item, state.by, os.time() }
        )
    else
        MySQL.update('DELETE FROM ' .. CUFF_TABLE .. ' WHERE citizenid = ?', { cid })
    end
end

local function release(target)
    local player = playerOf(target)
    if not player then return end

    cuffed[target] = nil
    saveCuff(player.PlayerData.citizenid, nil)

    TriggerClientEvent('police:client:UncuffPlayer', target)

    for src, id in pairs(escort) do
        if id == target then escort[src] = nil end
    end
end

RegisterNetEvent('police:server:CuffPlayer', function(targetId, item, side)
    local src = source
    local player = playerOf(src)
    local target = playerOf(tonumber(targetId) or 0)
    if not player or not target then return end

    if not CUFF_JOBS[jobOf(player)] then return notify(src, 'Job tidak bisa memborgol.') end

    local stamp = GetGameTimer()
    if cuffStamp[src] and stamp - cuffStamp[src] < CUFF_CD then return end
    cuffStamp[src] = stamp

    if not nearPed(src, target.PlayerData.source, INTERACT) then return notify(src, 'Terlalu jauh.') end
    if cuffed[target.PlayerData.source] then return notify(src, 'Sudah diborgol.') end

    item = tostring(item or cfg.handcuffItem)
    local data = CUFF_ITEMS[item]
    if not data then return notify(src, 'Alat borgol tidak dikenal.') end

    if (ox_inventory:GetItemCount(src, item) or 0) < 1 then return notify(src, ('Butuh %s.'):format(item)) end
    if data.consume then ox_inventory:RemoveItem(src, item, 1) end

    cuffed[target.PlayerData.source] = { item = item, by = player.PlayerData.citizenid }
    saveCuff(target.PlayerData.citizenid, cuffed[target.PlayerData.source])

    TriggerClientEvent('police:client:CuffPlayer', target.PlayerData.source, data.prop, data.flag, side == 'right')
    notify(src, 'Diborgol.', 'success')
end)

RegisterNetEvent('police:server:EscortPlayer', function()
    local src = source
    local player = playerOf(src)
    if not player or not ESCORT_JOBS[jobOf(player)] then return end

    local target = escort[src]

    if target and playerOf(target) then
        escort[src] = nil
        TriggerClientEvent('police:client:EscortPlayer', src, target, false)
        return
    end

    for other, state in pairs(cuffed) do
        if playerOf(other) and nearPed(src, other, ESCORT_DIST) then
            escort[src] = other
            TriggerClientEvent('police:client:EscortPlayer', src, other, true)
            return
        end
    end
end)

lib.callback.register('police:server:cutStart', function(src, targetId)
    local player = playerOf(src)
    local target = playerOf(tonumber(targetId) or 0)
    if not player or not target then return false, 'Data pemain tidak siap.' end
    if not cuffed[target.PlayerData.source] then return false, 'Target tidak diborgol.' end
    if not BOLT.item then return false, 'Alat potong belum diset.' end
    if not nearPed(src, target.PlayerData.source, INTERACT) then return false, 'Terlalu jauh.' end
    if (ox_inventory:GetItemCount(src, BOLT.item) or 0) < 1 then return false, ('Butuh %s.'):format(BOLT.item) end

    return true
end)

RegisterNetEvent('police:server:cutFinish', function(targetId)
    local src = source
    local target = playerOf(tonumber(targetId) or 0)
    if not target then return end

    if not ox_inventory:RemoveItem(src, BOLT.item, 1) then return end
    ox_inventory:AddItem(src, BOLT.brokenItem, 1)

    release(target.PlayerData.source)
    notify(src, 'Borgol dipotong.', 'success')
end)

lib.callback.register('police:server:lockpickCuffStart', function(src, targetId)
    local player = playerOf(src)
    local target = playerOf(tonumber(targetId) or 0)
    if not player or not target then return false, 'Data pemain tidak siap.' end

    local state = cuffed[target.PlayerData.source]
    if not state then return false, 'Target tidak diborgol.' end
    if not LOCKPICK.cuffs[state.item] then return false, 'Jenis borgol ini tidak bisa di-lockpick.' end
    if not nearPed(src, target.PlayerData.source, LOCKPICK.distance or 2.0) then return false, 'Terlalu jauh.' end
    if (ox_inventory:GetItemCount(src, LOCKPICK.item) or 0) < 1 then return false, ('Butuh %s.'):format(LOCKPICK.item) end

    return true
end)

lib.callback.register('police:server:lockpickCuffFinish', function(src, targetId, called, success)
    local target = playerOf(tonumber(targetId) or 0)
    if not target then return false end
    if not cuffed[target.PlayerData.source] then return false end

    if not success then return false end

    release(target.PlayerData.source)
    return true
end)

RegisterNetEvent('police:server:breakoutResult', function(success)
    local src = source
    if not BREAKOUT.enabled or not success then return end
    if not cuffed[src] then return end

    release(src)
end)

local function searchGrade(player)
    local rule = SEARCH.jobGrades and SEARCH.jobGrades[jobOf(player)]
    if not rule then return nil end
    return rule
end

local function canSearch(src, target)
    local player = playerOf(src)
    local other = playerOf(target)
    if not player or not other then return false, 'Data pemain tidak siap.' end
    if not nearPed(src, target, INTERACT + 0.5) then return false, 'Terlalu jauh.' end

    if SEARCH.viewOnlyJobs[jobOf(player)] then return true, true end
    if SEARCH.forceJobs[jobOf(player)] then return true, false end

    local rule = searchGrade(player)
    if rule and gradeOf(player) >= (rule[1] or 0) and gradeOf(player) <= (rule[2] or 99) then
        return true, false
    end

    return false, 'Job/grade tidak bisa menggeledah.'
end

RegisterNetEvent('police:server:SearchPlayer', function(targetId)
    local src = source
    local ok, viewOnly = canSearch(src, tonumber(targetId) or 0)
    if not ok then return notify(src, viewOnly or 'Tidak bisa menggeledah.') end

    TriggerClientEvent('police:client:SearchPlayer', src, tonumber(targetId), viewOnly)
end)

RegisterNetEvent('police:server:RobPlayer', function(targetId)
    local src = source
    local ok, viewOnly = canSearch(src, tonumber(targetId) or 0)
    if not ok then return notify(src, 'Tidak bisa merampok.') end
    if viewOnly then return notify(src, 'Hanya bisa melihat.') end

    TriggerClientEvent('police:client:RobPlayer', src, tonumber(targetId))
end)

lib.callback.register('police:server:RegisterVehicle', function(src, netId)
    local player = playerOf(src)
    if not player then return false, 'Data pemain tidak siap.' end
    if not CUFF_JOBS[jobOf(player)] then return false, 'Bukan petugas.' end

    local entity = NetworkGetEntityFromNetworkId(tonumber(netId) or 0)
    if entity == 0 or not DoesEntityExist(entity) then return false, 'Kendaraan tidak ditemukan.' end
    if #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(entity)) > GARAGE_DIST then
        return false, 'Terlalu jauh.'
    end

    local kind = (GetVehicleClass(entity) == 15) and 'heli' or 'car'
    local prefix = PREFIX[kind] or 'LSPD'
    local plate = ('%s%04d'):format(prefix, math.random(0, 9999))

    SetVehicleNumberPlateText(entity, plate)

    MySQL.insert('INSERT INTO ' .. VEH_TABLE .. ' (plate, model, kind, by_citizenid, created) VALUES (?, ?, ?, ?, ?)', {
        plate, GetEntityModel(entity), kind, player.PlayerData.citizenid, os.time(),
    })

    return true, plate
end)

lib.callback.register('police:server:TakeOutVehicle', function(src, kind, index, model)
    local player = playerOf(src)
    if not player then return false, nil, nil end

    local stamp = GetGameTimer()
    if garageStamp[src] and stamp - garageStamp[src] < GARAGE_CD then return false, nil, nil end
    garageStamp[src] = stamp

    local garage = GARAGES[kind] and GARAGES[kind][tonumber(index) or 0]
    if not garage then return false, nil, nil end
    if not near(src, vector3(garage.ped.x, garage.ped.y, garage.ped.z), GARAGE_DIST) then
        return false, nil, nil
    end

    local entry
    for i = 1, #(VEHICLES[kind] or {}) do
        if VEHICLES[kind][i].model == model then entry = VEHICLES[kind][i] break end
    end

    if not entry then return false, nil, nil end

    if gradeOf(player) < (entry.minGrade or 0) and not bypass(player, kind) then
        return false, nil, nil
    end

    if entry.items and not bypass(player, kind) then
        if not hasAll(src, entry.items) then return false, 'Badge tidak lengkap.' end
    end

    local spot = garage.spawn
    local entity = CreateVehicle(GetHashKey(entry.model), spot.x, spot.y, spot.z, spot.w, true)
    if entity == 0 then return false, nil, nil end

    local prefix = PREFIX[kind] or 'LSPD'
    local plate = ('%s%04d'):format(prefix, math.random(0, 9999))

    SetVehicleNumberPlateText(entity, plate)
    SetVehicleLivery(entity, entry.livery or 0)

    return true, spot, plate
end)

lib.callback.register('police:server:openDrawer', function(src, slot)
    local player = playerOf(src)
    if not player then return nil end
    if not CUFF_JOBS[jobOf(player)] then return nil end

    slot = tonumber(slot) or 0
    local point = EVIDENCE[slot]
    if not point then return nil end
    if not near(src, point, EVIDENCE_DIST) then return nil end

    local id = ('evidence_%d'):format(slot)
    ox_inventory:RegisterStash(id, ('Laci Bukti %d'):format(slot), 40, 200000)

    return id
end)

lib.callback.register('police:server:checkPlate', function(src, plate)
    local player = playerOf(src)
    if not player then return false, nil end
    if TRACKER and not near(src, TRACKER, TRACKER_DIST) then return false, nil end

    plate = tostring(plate or ''):upper():gsub('%s+$', '')
    if plate == '' then return false, nil end

    local row = MySQL.single.await('SELECT * FROM ' .. VEH_TABLE .. ' WHERE plate = ?', { plate })
    if row then
        return true, { plate = row.plate, model = row.model, kind = row.kind, registered = true }
    end

    local owned = MySQL.single.await('SELECT citizenid FROM player_vehicles WHERE plate = ?', { plate })
    if owned then return true, { plate = plate, registered = false } end

    return false, nil
end)

CreateThread(function()
    MySQL.query.await([[
    CREATE TABLE IF NOT EXISTS `police_cuffed` (
        `citizenid` varchar(64) NOT NULL,
        `item` varchar(32) NOT NULL,
        `by_citizenid` varchar(64) DEFAULT NULL,
        `created` int(11) NOT NULL,
        PRIMARY KEY (`citizenid`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    MySQL.query.await([[
    CREATE TABLE IF NOT EXISTS `police_vehicles` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `plate` varchar(16) NOT NULL,
        `model` varchar(64) NOT NULL,
        `kind` varchar(16) NOT NULL,
        `by_citizenid` varchar(64) DEFAULT NULL,
        `created` int(11) NOT NULL,
        PRIMARY KEY (`id`),
        KEY `plate` (`plate`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
end)

AddEventHandler('playerDropped', function()
    local src = source
    cuffed[src] = nil
    cuffStamp[src] = nil
    garageStamp[src] = nil

    for officer, target in pairs(escort) do
        if target == src then escort[officer] = nil end
    end
end)

AddEventHandler('playerLoaded', function(src)
    local player = playerOf(src)
    if not player then return end

    local row = MySQL.single.await('SELECT * FROM ' .. CUFF_TABLE .. ' WHERE citizenid = ?', { player.PlayerData.citizenid })
    if not row then return end

    cuffed[src] = { item = row.item, by = row.by_citizenid }
    TriggerClientEvent('police:client:CuffPlayer', src, (CUFF_ITEMS[row.item] or {}).prop, (CUFF_ITEMS[row.item] or {}).flag, false)
end)

print('^2[sm_policejob] server siap^7')