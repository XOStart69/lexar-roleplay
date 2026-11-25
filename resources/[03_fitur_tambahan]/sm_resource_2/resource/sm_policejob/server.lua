--[[
    sm_policejob :: server  (ditulis ulang agar cocok dengan client)

    Borgol disimpan di state bag Player(src).state.cuffed = <nama item> (dibaca client lewat cuffOf)
    dan di tabel police_cuffed (tahan relog). Alur:
      CuffPlayer(target, item, side)  -> police:client:SetCuffed(item, side)
      EscortPlayer([target])          -> SetEscorted(target, dragger) / SetEscorting(dragger, target)
      Search/RobPlayer -> StartSearch(_, ms, label) -> OpenSearch -> buka inventory target
      PutPlayerInVehicle / SetPlayerOutVehicle, cutStart/cutFinish, lockpickCuffStart/Finish,
      /breakout (skill check) -> BreakoutResult.
    Garasi, laci bukti, pelacak plat di bagian bawah.
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
local BADGE_PASPAMPRES = 'badgepaspampres'

local CUFF_TABLE = 'police_cuffed'
local VEH_TABLE = 'police_vehicles'

local cuffed = {}        -- target src -> { item, by, at }
local escort = {}        -- dragger src -> target src
local dragged = {}       -- target src -> dragger src
local cuffStamp, garageStamp = {}, {}
local cutSession, pickSession, pickLast = {}, {}, {}
local searchSession = {}
local breakout = {}      -- src -> { at }
local platePending = {}  -- src -> plate

-- ───────────── util ─────────────

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

local function items(src, name)
    return exports.ox_inventory:GetItemCount(src, name) or 0
end

local function near(src, coords, radius)
    local ped = GetPlayerPed(src)
    return ped ~= 0 and #(GetEntityCoords(ped) - coords) <= radius
end

local function nearPed(src, target, radius)
    local a, b = GetPlayerPed(src), GetPlayerPed(target)
    return a ~= 0 and b ~= 0 and #(GetEntityCoords(a) - GetEntityCoords(b)) <= radius
end

local function hasAll(src, list)
    for i = 1, #list do
        if items(src, list[i]) < 1 then return false end
    end
    return true
end

local function bypass(player, kind)
    local rule = BYPASS[kind] and BYPASS[kind][jobOf(player)]
    if not rule then return false end
    local grade = gradeOf(player)
    return grade >= (rule[1] or 0) and grade <= (rule[2] or 99)
end

local function targetOf(id)
    id = tonumber(id)
    return id, id and playerOf(id)
end

-- ───────────── borgol ─────────────

local function saveCuff(cid, state)
    if state then
        MySQL.insert(('INSERT INTO %s (citizenid, item, by_citizenid, created) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE item = VALUES(item), by_citizenid = VALUES(by_citizenid)'):format(CUFF_TABLE),
            { cid, state.item, state.by, os.time() })
    else
        MySQL.update(('DELETE FROM %s WHERE citizenid = ?'):format(CUFF_TABLE), { cid })
    end
end

local function stopEscort(dragger)
    local target = escort[dragger]
    if not target then return end

    escort[dragger] = nil
    dragged[target] = nil

    if GetPlayerPing(target) > 0 then TriggerClientEvent('police:client:SetEscorted', target, nil) end
    if GetPlayerPing(dragger) > 0 then TriggerClientEvent('police:client:SetEscorting', dragger, nil) end
end

local function release(target)
    local player = playerOf(target)

    if dragged[target] then stopEscort(dragged[target]) end
    cuffed[target] = nil
    breakout[target] = nil

    if GetPlayerPing(target) > 0 then
        Player(target).state:set('cuffed', nil, true)
        TriggerClientEvent('police:client:SetCuffed', target, nil)
    end

    if player then saveCuff(player.PlayerData.citizenid, nil) end
end

local function applyCuff(target, targetPlayer, item, side, by)
    local state = { item = item, by = by, at = GetGameTimer() }
    cuffed[target] = state

    Player(target).state:set('cuffed', item, true)
    saveCuff(targetPlayer.PlayerData.citizenid, state)
    TriggerClientEvent('police:client:SetCuffed', target, item, side)
end

RegisterTokenEvent('police:server:CuffPlayer', function(targetId, item, side)
    local src = source
    local player = playerOf(src)
    local target, targetPlayer = targetOf(targetId)
    if not player or not targetPlayer or target == src then return end

    local now = GetGameTimer()
    if cuffStamp[src] and now - cuffStamp[src] < 1000 then return end
    cuffStamp[src] = now

    if not nearPed(src, target, INTERACT + 1.0) then return notify(src, 'Terlalu jauh.') end

    item = tostring(item or '')

    local cuff = CUFF_ITEMS[item]
    local key = KEY_ITEMS[item]

    if cuff then
        if not (CUFF_JOBS[jobOf(player)] or cuff.public) then return notify(src, 'Job tidak bisa memborgol.') end
        if cuffed[target] then return notify(src, 'Sudah diborgol.') end
        if items(src, item) < 1 then return notify(src, ('Butuh %s.'):format(item)) end

        if cuff.consume then exports.ox_inventory:RemoveItem(src, item, 1) end

        applyCuff(target, targetPlayer, item, side == 'front' and 'front' or 'back', player.PlayerData.citizenid)
        notify(src, 'Diborgol.', 'success')
    elseif key then
        local state = cuffed[target]
        if not state then return notify(src, 'Target tidak diborgol.') end
        if not (CUFF_JOBS[jobOf(player)] or key.public) then return notify(src, 'Job tidak bisa membuka borgol.') end

        local lock = CUFF_ITEMS[state.item]
        if not lock or lock.key ~= item then return notify(src, 'Kunci tidak cocok.') end
        if items(src, item) < 1 then return notify(src, ('Butuh %s.'):format(item)) end

        if key.consume then exports.ox_inventory:RemoveItem(src, item, 1) end

        release(target)
        notify(src, 'Borgol dibuka.', 'success')
    end
end)

-- ───────────── escort ─────────────

RegisterTokenEvent('police:server:EscortPlayer', function(targetId)
    local src = source
    local player = playerOf(src)
    if not player then return end

    if escort[src] then return stopEscort(src) end

    if not (ESCORT_JOBS[jobOf(player)] or CUFF_JOBS[jobOf(player)]) then return end

    local target, targetPlayer = targetOf(targetId)
    if not targetPlayer or target == src then return end
    if not cuffed[target] then return notify(src, 'Target tidak diborgol.') end
    if dragged[target] then return notify(src, 'Sudah di-escort.') end
    if not nearPed(src, target, ESCORT_DIST + 1.0) then return notify(src, 'Terlalu jauh.') end

    escort[src] = target
    dragged[target] = src

    TriggerClientEvent('police:client:SetEscorted', target, src)
    TriggerClientEvent('police:client:SetEscorting', src, target)
end)

RegisterTokenEvent('police:server:PutPlayerInVehicle', function(targetId, netId)
    local src = source
    local player = playerOf(src)
    local target, targetPlayer = targetOf(targetId)
    if not player or not targetPlayer or not (CUFF_JOBS[jobOf(player)] or ESCORT_JOBS[jobOf(player)]) then return end
    if not cuffed[target] or not nearPed(src, target, 6.0) then return end

    local vehicle = NetworkGetEntityFromNetworkId(tonumber(netId) or 0)
    if vehicle == 0 or not DoesEntityExist(vehicle) then return end
    if #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(vehicle)) > 8.0 then return end

    if dragged[target] then stopEscort(dragged[target]) end

    TriggerClientEvent('police:client:PutInVehicle', target, netId)
end)

RegisterTokenEvent('police:server:SetPlayerOutVehicle', function(targetId)
    local src = source
    local player = playerOf(src)
    local target, targetPlayer = targetOf(targetId)
    if not player or not targetPlayer or not (CUFF_JOBS[jobOf(player)] or ESCORT_JOBS[jobOf(player)]) then return end
    if not nearPed(src, target, 6.0) then return end

    TriggerClientEvent('police:client:SetOutVehicle', target)
end)

-- ───────────── potong / lockpick / breakout ─────────────

lib.callback.register('police:server:cutStart', function(src, targetId)
    local target, targetPlayer = targetOf(targetId)
    if not playerOf(src) or not targetPlayer then return false, 'Data pemain tidak siap.' end
    if not cuffed[target] then return false, 'Target tidak diborgol.' end
    if not BOLT.item then return false, 'Alat potong belum diset.' end
    if not nearPed(src, target, INTERACT + 1.0) then return false, 'Terlalu jauh.' end
    if items(src, BOLT.item) < 1 then return false, ('Butuh %s.'):format(BOLT.item) end

    cutSession[src] = { target = target, at = GetGameTimer() }
    return true
end)

RegisterTokenEvent('police:server:cutFinish', function()
    local src = source
    local session = cutSession[src]
    cutSession[src] = nil

    if not session or not cuffed[session.target] then return end
    if GetGameTimer() - session.at < (BOLT.duration or 6000) * 0.8 then return end
    if not nearPed(src, session.target, INTERACT + 2.0) then return end

    if not exports.ox_inventory:RemoveItem(src, BOLT.item, 1) then return end
    if BOLT.brokenItem then exports.ox_inventory:AddItem(src, BOLT.brokenItem, 1) end

    release(session.target)
    notify(src, 'Borgol dipotong.', 'success')
end)

lib.callback.register('police:server:lockpickCuffStart', function(src, targetId)
    local target, targetPlayer = targetOf(targetId)
    if not playerOf(src) or not targetPlayer then return false, 'Data pemain tidak siap.' end

    local state = cuffed[target]
    if not state then return false, 'Target tidak diborgol.' end
    if not (LOCKPICK.cuffs and LOCKPICK.cuffs[state.item]) then return false, 'Jenis borgol ini tidak bisa di-lockpick.' end
    if not nearPed(src, target, (LOCKPICK.distance or 2.0) + 1.0) then return false, 'Terlalu jauh.' end
    if items(src, LOCKPICK.item) < 1 then return false, ('Butuh %s.'):format(LOCKPICK.item) end

    local now = GetGameTimer()
    if pickLast[src] and now - pickLast[src] < (LOCKPICK.cooldown or 0) * 1000 then
        return false, 'Tunggu sebentar.'
    end

    pickSession[src] = { target = target, at = now }
    return true
end)

lib.callback.register('police:server:lockpickCuffFinish', function(src, success)
    local session = pickSession[src]
    pickSession[src] = nil
    pickLast[src] = GetGameTimer()

    if not session or not success or not cuffed[session.target] then return false end

    local elapsed = GetGameTimer() - session.at
    if elapsed < (LOCKPICK.minDuration or 0) or elapsed > (LOCKPICK.maxDuration or 90000) then return false end

    release(session.target)
    return true
end)

RegisterCommand('breakout', function(src)
    if src == 0 or not BREAKOUT.enabled or not cuffed[src] or breakout[src] then return end

    breakout[src] = { at = GetGameTimer() }
    TriggerClientEvent('police:client:Breakout', src)

    SetTimeout(BREAKOUT.timeout or 15000, function()
        if breakout[src] and breakout[src].at then breakout[src] = nil end
    end)
end, false)

RegisterTokenEvent('police:server:BreakoutResult', function(success)
    local src = source
    local session = breakout[src]
    breakout[src] = nil

    if not BREAKOUT.enabled or not session or success ~= true or not cuffed[src] then return end

    local elapsed = GetGameTimer() - session.at
    if elapsed < (BREAKOUT.minTime or 0) or elapsed > (BREAKOUT.timeout or 15000) then return end

    release(src)
end)

-- ───────────── geledah / rampok ─────────────

local function searchRule(player, rob, src)
    local job = player.PlayerData.job
    local grade = job.grade.level or 0
    local range = SEARCH.jobGrades and SEARCH.jobGrades[job.name]

    if rob then return job.type == 'badside' end

    if job.type == 'leo' or SEARCH.forceJobs and SEARCH.forceJobs[job.name] then return true end
    if range and grade >= range[1] and grade <= range[2] then return true end
    if SEARCH.viewOnlyJobs and SEARCH.viewOnlyJobs[job.name] and job.onduty then return true end

    return items(src, BADGE_PASPAMPRES) > 0
end

local function startSearch(src, targetId, rob)
    local player = playerOf(src)
    local target, targetPlayer = targetOf(targetId)
    if not player or not targetPlayer or target == src then return end

    if not searchRule(player, rob, src) then
        return notify(src, rob and 'Tidak bisa merampok.' or 'Tidak memiliki akses untuk menggeledah')
    end

    local forced = SEARCH.forceJobs and SEARCH.forceJobs[jobOf(player)]
    if not forced and not nearPed(src, target, INTERACT + 1.0) then return notify(src, 'Terlalu jauh.') end

    local rule = rob and SEARCH.rob or SEARCH.police
    local duration = math.random(rule.min, rule.max)

    searchSession[src] = { target = target, at = GetGameTimer(), duration = duration, forced = forced }

    TriggerClientEvent('police:client:StartSearch', src, target, duration, rule.label)
    TriggerClientEvent('police:client:BeingSearched', target)
end

RegisterTokenEvent('police:server:SearchPlayer', function(targetId) startSearch(source, targetId, false) end)
RegisterTokenEvent('police:server:RobPlayer', function(targetId) startSearch(source, targetId, true) end)

RegisterTokenEvent('police:server:OpenSearch', function()
    local src = source
    local session = searchSession[src]
    searchSession[src] = nil

    if not session or GetGameTimer() - session.at < session.duration * 0.8 then return end
    if not session.forced and not nearPed(src, session.target, INTERACT + 2.0) then return end
    if not playerOf(session.target) then return end

    exports.ox_inventory:forceOpenInventory(src, 'player', session.target)
end)

-- ───────────── garasi ─────────────

lib.callback.register('police:server:TakeOutVehicle', function(src, kind, index, model)
    local player = playerOf(src)
    if not player then return false, 'Data pemain tidak siap.' end

    local now = GetGameTimer()
    if garageStamp[src] and now - garageStamp[src] < GARAGE_CD then return false, 'Tunggu sebentar.' end
    garageStamp[src] = now

    local garage = GARAGES[kind] and GARAGES[kind][tonumber(index) or 0]
    if not garage then return false, 'Garasi tidak dikenal.' end
    if not near(src, vector3(garage.ped.x, garage.ped.y, garage.ped.z), GARAGE_DIST + 6.0) then
        return false, 'Terlalu jauh dari garasi.'
    end

    local entry
    for i = 1, #(VEHICLES[kind] or {}) do
        if VEHICLES[kind][i].model == model then entry = VEHICLES[kind][i] break end
    end
    if not entry then return false, 'Kendaraan tidak tersedia.' end

    local bypassed = bypass(player, kind)
    if gradeOf(player) < (entry.minGrade or 0) and not bypassed then return false, 'Pangkat belum cukup.' end
    if entry.items and not bypassed and not hasAll(src, entry.items) then return false, 'Badge tidak lengkap.' end

    local price = tonumber(entry.price) or 0
    if price > 0 then
        local paid = false
        for _, account in ipairs({ 'cash', 'bank' }) do
            if (player.PlayerData.money[account] or 0) >= price and player.Functions.RemoveMoney(account, price, 'police-garage') then
                paid = true
                break
            end
        end
        if not paid then return false, 'Uang tidak cukup.' end
    end

    local plate = ('%s%04d'):format(PREFIX[kind] or 'LSPD', math.random(0, 9999))
    platePending[src] = plate

    return true, garage.spawn, plate
end)

lib.callback.register('police:server:RegisterVehicle', function(src, netId)
    local player = playerOf(src)
    if not player then return false, 'Data pemain tidak siap.' end

    local plate = platePending[src]
    platePending[src] = nil
    if not plate then return false, 'Tidak ada permintaan kendaraan.' end

    local entity = NetworkGetEntityFromNetworkId(tonumber(netId) or 0)
    if entity == 0 or not DoesEntityExist(entity) then return false, 'Kendaraan tidak ditemukan.' end
    if #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(entity)) > GARAGE_DIST + 6.0 then
        return false, 'Terlalu jauh.'
    end

    local kind = GetVehicleClass(entity) == 15 and 'heli' or 'car'

    MySQL.insert(('INSERT INTO %s (plate, model, kind, by_citizenid, created) VALUES (?, ?, ?, ?, ?)'):format(VEH_TABLE),
        { plate, tostring(GetEntityModel(entity)), kind, player.PlayerData.citizenid, os.time() })

    TriggerEvent('sm_vehiclekeys:server:setVehicleOwner', plate, player.PlayerData.citizenid)

    return true
end)

-- ───────────── laci bukti & pelacak plat ─────────────

lib.callback.register('police:server:openDrawer', function(src, slot)
    local player = playerOf(src)
    if not player then return nil end

    local allowed = CUFF_JOBS[jobOf(player)] == true
    for i = 1, #EVIDENCE_BADGES do
        if items(src, EVIDENCE_BADGES[i]) > 0 then allowed = true end
    end
    if not allowed then return nil end

    slot = math.floor(tonumber(slot) or 0)
    if slot < 1 then return nil end

    local near_ = false
    for i = 1, #EVIDENCE do
        if near(src, EVIDENCE[i], EVIDENCE_DIST + 2.0) then near_ = true break end
    end
    if not near_ then return nil end

    local id = ('evidence_%d'):format(slot)
    exports.ox_inventory:RegisterStash(id, ('Laci Bukti %d'):format(slot), 40, 200000)

    return id
end)

lib.callback.register('police:server:checkPlate', function(src, plate)
    local player = playerOf(src)
    if not player then return false, 'Data pemain tidak siap.' end
    if TRACKER and not near(src, TRACKER, TRACKER_DIST + 3.0) then return false, 'Kamu tidak di lokasi pelacak.' end

    plate = tostring(plate or ''):match('^%s*(.-)%s*$'):upper()
    if plate == '' then return false, 'Plat kosong.' end

    local row = MySQL.single.await([[
        SELECT pv.citizenid, pv.vehicle, pv.plate, pv.state, pv.garage, p.charinfo
        FROM player_vehicles pv LEFT JOIN players p ON p.citizenid = pv.citizenid
        WHERE UPPER(TRIM(pv.plate)) = ? LIMIT 1]], { plate })

    if row then
        local info = row.charinfo and json.decode(row.charinfo) or {}
        local name = info.firstname and ('%s %s'):format(info.firstname, info.lastname or '') or nil
        return true, {
            citizenid = row.citizenid, owner = name, vehicle = row.vehicle,
            plate = row.plate, state = row.state, garage = row.garage,
        }
    end

    local police = MySQL.single.await(('SELECT plate, model FROM %s WHERE plate = ? LIMIT 1'):format(VEH_TABLE), { plate })
    if police then
        return true, { citizenid = 'Kendaraan Dinas', owner = 'Kepolisian', vehicle = police.model, plate = police.plate, state = 1, garage = 'Garasi Polisi' }
    end

    return true, nil
end)

-- ───────────── lifecycle ─────────────

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

local function restoreCuff(src)
    local player = playerOf(src)
    if not player then return end

    local row = MySQL.single.await(('SELECT * FROM %s WHERE citizenid = ?'):format(CUFF_TABLE), { player.PlayerData.citizenid })
    if not row or not CUFF_ITEMS[row.item] then return end

    cuffed[src] = { item = row.item, by = row.by_citizenid, at = GetGameTimer() }
    Player(src).state:set('cuffed', row.item, true)
    TriggerClientEvent('police:client:SetCuffed', src, row.item, 'back')
end

AddEventHandler('QBCore:Server:PlayerLoaded', function(player)
    local src = type(player) == 'table' and player.PlayerData and player.PlayerData.source or tonumber(player)
    if src then SetTimeout(3000, function() restoreCuff(src) end) end
end)

AddEventHandler('playerDropped', function()
    local src = source

    if escort[src] then stopEscort(src) end
    if dragged[src] then stopEscort(dragged[src]) end

    cuffed[src], breakout[src] = nil, nil
    cuffStamp[src], garageStamp[src] = nil, nil
    cutSession[src], pickSession[src], pickLast[src] = nil, nil, nil
    searchSession[src], platePending[src] = nil, nil
end)

-- item bisa dipakai dari inventory -> client menjalankan aksinya
for item in pairs(CUFF_ITEMS) do
    qb_ecore:CreateUseableItem(item, function(src) TriggerClientEvent('police:client:CuffPlayer', src, item) end)
end

for item in pairs(KEY_ITEMS) do
    qb_ecore:CreateUseableItem(item, function(src) TriggerClientEvent('police:client:CuffPlayer', src, item) end)
end

if BOLT.item then
    qb_ecore:CreateUseableItem(BOLT.item, function(src) TriggerClientEvent('police:client:useCuffCutter', src) end)
end
