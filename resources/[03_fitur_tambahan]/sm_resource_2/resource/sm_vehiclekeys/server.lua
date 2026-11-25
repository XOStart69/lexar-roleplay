--[[
    sm_vehiclekeys :: server  (ditulis ulang agar cocok dengan client)

    Kunci disimpan per (plat, citizenid) di tabel `sm_vehiclekeys_holders` (boleh banyak pemegang).
    Pemilik kendaraan di `player_vehicles` otomatis punya kunci tanpa perlu entri.
    Kunci curian (hotwire / carjack / ambil dari mayat) disimpan juga.
    Event/callback: list, hotwireStart/Finish, toggleLock, lockpick, carjackStart/Finish,
    takeKeys, claim, npcLock, give, setVehicleOwner, removeKeys.
]]

local config = localmodule 'config'

local LOCK_DISTANCE = config.lockDistance or 8.0
local GIVE_DISTANCE = config.giveDistance or 3.0
local CLAIM_DISTANCE = config.claimDistance or 30.0
local PICK = config.lockpick
local HOTWIRE = config.hotwire
local CARJACK = config.carjack
local HOLDERS = 'sm_vehiclekeys_holders'

local IMMUNE, NOLOCK, NOCLASS, BLOCKED_WEAPON = {}, {}, {}, {}
for i = 1, #(config.immuneModels or {}) do IMMUNE[joaat(config.immuneModels[i])] = true end
for i = 1, #(config.noLockModels or {}) do NOLOCK[joaat(config.noLockModels[i])] = true end
for class, on in pairs(config.noLockClasses or {}) do if on then NOCLASS[class] = true end end
for i = 1, #(CARJACK.blockedWeapons or {}) do BLOCKED_WEAPON[joaat(CARJACK.blockedWeapons[i])] = true end

local SHARED = {}
for job, data in pairs(config.sharedKeys or {}) do
    local models = {}
    for i = 1, #(data.models or {}) do models[joaat(data.models[i])] = true end
    SHARED[job] = { onduty = data.requireOnduty, models = models }
end

local hotwire = {}   -- src -> { plate, netId, at, duration }
local carjack = {}   -- src -> { plate, netId, at }
local lastHotwire = {}

-- ───────────── util ─────────────

local function notify(src, message, kind)
    TriggerClientEvent('ox_lib:notify', src, { title = 'Kunci Kendaraan', description = message, type = kind or 'error' })
end

local function normPlate(plate)
    if type(plate) ~= 'string' then return nil end
    plate = plate:match('^%s*(.-)%s*$'):upper()
    if plate == '' then return nil end
    return plate
end

local function vehicleFromNet(netId)
    local entity = NetworkGetEntityFromNetworkId(tonumber(netId) or 0)
    if entity == 0 or not DoesEntityExist(entity) then return nil end
    if GetEntityType(entity) ~= 2 then return nil end
    return entity
end

local function plateOf(entity)
    return normPlate(GetVehicleNumberPlateText(entity))
end

local function near(src, entity, distance)
    local ped = GetPlayerPed(src)
    return ped ~= 0 and #(GetEntityCoords(ped) - GetEntityCoords(entity)) <= distance
end

local function cidOf(src)
    local player = qb_ecore:GetPlayer(src)
    return player and player.PlayerData.citizenid or nil, player
end

local function isOwner(cid, plate)
    local ok, row = pcall(MySQL.scalar.await,
        'SELECT 1 FROM player_vehicles WHERE citizenid = ? AND UPPER(TRIM(plate)) = ? LIMIT 1', { cid, plate })
    return ok and row ~= nil
end

local function isHolder(cid, plate)
    return MySQL.scalar.await(('SELECT 1 FROM %s WHERE plate = ? AND citizenid = ?'):format(HOLDERS), { plate, cid }) ~= nil
end

local function isShared(player, entity)
    local entry = SHARED[player.PlayerData.job.name]
    if not entry then return false end
    if entry.onduty and not player.PlayerData.job.onduty then return false end
    return entry.models[GetEntityModel(entity)] == true
end

local function hasKeys(src, entity)
    local cid, player = cidOf(src)
    if not cid then return false end

    local plate = plateOf(entity)
    if not plate then return false end

    return isShared(player, entity) or isHolder(cid, plate) or isOwner(cid, plate)
end

local function addHolder(cid, plate)
    MySQL.insert.await(('INSERT IGNORE INTO %s (plate, citizenid, created) VALUES (?, ?, ?)'):format(HOLDERS),
        { plate, cid, os.time() })
end

local function grantKeys(src, entity)
    local cid = cidOf(src)
    local plate = plateOf(entity)
    if not cid or not plate then return false end

    addHolder(cid, plate)
    SetVehicleDoorsLocked(entity, 1)
    TriggerClientEvent('sm_vehiclekeys:client:AddKeys', src, plate)
    return true
end

local function roll(chance)
    return math.random() < (tonumber(chance) or 0.0)
end

-- ───────────── daftar kunci ─────────────

lib.callback.register('sm_vehiclekeys:list', function(src)
    local cid = cidOf(src)
    local out = {}
    if not cid then return out end

    for _, row in ipairs(MySQL.query.await(('SELECT plate FROM %s WHERE citizenid = ?'):format(HOLDERS), { cid }) or {}) do
        local plate = normPlate(row.plate)
        if plate then out[plate] = true end
    end

    local ok, owned = pcall(MySQL.query.await, 'SELECT plate FROM player_vehicles WHERE citizenid = ?', { cid })
    if ok then
        for _, row in ipairs(owned or {}) do
            local plate = normPlate(row.plate)
            if plate then out[plate] = true end
        end
    end

    return out
end)

-- ───────────── hotwire ─────────────

lib.callback.register('sm_vehiclekeys:hotwireStart', function(src, netId)
    local cid = cidOf(src)
    if not cid then return false end

    local entity = vehicleFromNet(netId)
    if not entity or not near(src, entity, 5.0) then return false end

    if IMMUNE[GetEntityModel(entity)] then return false, 'blocked' end

    local okType, vtype = pcall(GetVehicleType, entity)
    if okType and HOTWIRE.blockedTypes and HOTWIRE.blockedTypes[vtype] then return false, 'blocked' end

    if hasKeys(src, entity) then return false end

    local now = GetGameTimer()
    if lastHotwire[src] and now - lastHotwire[src] < (HOTWIRE.cooldown or 0) then return false end
    lastHotwire[src] = now

    local duration = math.random(HOTWIRE.minTime or 20000, HOTWIRE.maxTime or 40000)
    hotwire[src] = { netId = tonumber(netId), at = now, duration = duration }

    return duration
end)

lib.callback.register('sm_vehiclekeys:hotwireFinish', function(src, cancelled)
    local session = hotwire[src]
    hotwire[src] = nil

    if not session or cancelled then return false end
    if GetGameTimer() - session.at < session.duration * 0.8 then return false end

    local entity = vehicleFromNet(session.netId)
    if not entity or not near(src, entity, 6.0) then return false end

    if not roll(HOTWIRE.chance) then return false end

    return grantKeys(src, entity)
end)

-- ───────────── lock / unlock ─────────────

lib.callback.register('sm_vehiclekeys:toggleLock', function(src, netId, wanted)
    local entity = vehicleFromNet(netId)
    if not entity or not near(src, entity, LOCK_DISTANCE + 2.0) then return false end

    if NOLOCK[GetEntityModel(entity)] or NOCLASS[GetVehicleClass(entity)] then return false end
    if not hasKeys(src, entity) then return false end

    local state = wanted == 2 and 2 or 1
    SetVehicleDoorsLocked(entity, state)

    return state
end)

lib.callback.register('sm_vehiclekeys:lockpick', function(src, netId, success)
    local entity = vehicleFromNet(netId)
    if not entity or not near(src, entity, (PICK.distance or 2.5) + 2.0) then return false end

    local tool
    for name in pairs(PICK.breakChance or {}) do
        if (exports.ox_inventory:GetItemCount(src, name) or 0) > 0 then tool = name break end
    end
    if not tool then return false end

    if not success then
        if roll(PICK.breakChance[tool]) then exports.ox_inventory:RemoveItem(src, tool, 1) end
        return false
    end

    SetVehicleDoorsLocked(entity, 1)
    return true
end)

RegisterTokenEvent('sm_vehiclekeys:server:npcLock', function(netId)
    local src = source
    local entity = vehicleFromNet(netId)
    if not entity or not near(src, entity, 12.0) then return end

    if NOLOCK[GetEntityModel(entity)] or NOCLASS[GetVehicleClass(entity)] or IMMUNE[GetEntityModel(entity)] then return end
    if hasKeys(src, entity) then return end

    local driver = GetPedInVehicleSeat(entity, -1)
    if driver ~= 0 and IsPedAPlayer(driver) then return end

    local moving = driver ~= 0
    if (moving and config.lockNpcDriving) or (not moving and config.lockNpcParked) then
        SetVehicleDoorsLocked(entity, 2)
    end
end)

-- ───────────── carjack / ambil dari mayat ─────────────

lib.callback.register('sm_vehiclekeys:carjackStart', function(src, netId)
    if not CARJACK.enabled then return false end

    local entity = vehicleFromNet(netId)
    if not entity or not near(src, entity, (CARJACK.distance or 5.0) + 3.0) then return false end
    if IMMUNE[GetEntityModel(entity)] or hasKeys(src, entity) then return false end

    local driver = GetPedInVehicleSeat(entity, -1)
    if driver == 0 or IsPedAPlayer(driver) then return false end

    local weapon = GetSelectedPedWeapon(GetPlayerPed(src))
    if weapon == 0 or BLOCKED_WEAPON[weapon] then return false end

    carjack[src] = { netId = tonumber(netId), at = GetGameTimer() }
    return true
end)

lib.callback.register('sm_vehiclekeys:carjackFinish', function(src, group, failed)
    local session = carjack[src]
    carjack[src] = nil

    if not session or failed then return false end
    if GetGameTimer() - session.at < (CARJACK.duration or 7500) * 0.7 then return false end

    local entity = vehicleFromNet(session.netId)
    if not entity then return false end

    local chance = CARJACK.chance and CARJACK.chance[tostring(group)]
    if not roll(chance or CARJACK.fallbackChance) then return false end

    return grantKeys(src, entity)
end)

lib.callback.register('sm_vehiclekeys:takeKeys', function(src, netId)
    local entity = vehicleFromNet(netId)
    if not entity or not near(src, entity, 6.0) or IMMUNE[GetEntityModel(entity)] then return false end

    local driver = GetPedInVehicleSeat(entity, -1)
    if driver == 0 or IsPedAPlayer(driver) or GetEntityHealth(driver) >= 100 then return false end

    return grantKeys(src, entity)
end)

-- ───────────── klaim, beri, kelola ─────────────

RegisterTokenEvent('sm_vehiclekeys:server:claim', function(netId, plate)
    local src = source
    local cid = cidOf(src)
    plate = normPlate(plate)
    local entity = vehicleFromNet(netId)
    if not cid or not plate or not entity then return end

    if plateOf(entity) ~= plate or not near(src, entity, CLAIM_DISTANCE) then return end
    if not (isHolder(cid, plate) or isOwner(cid, plate)) then return end

    SetVehicleDoorsLocked(entity, 1)
    TriggerClientEvent('sm_vehiclekeys:client:AddKeys', src, plate)
end)

RegisterTokenEvent('sm_vehiclekeys:server:give', function(netId, targets)
    local src = source
    local entity = vehicleFromNet(netId)
    if not entity or type(targets) ~= 'table' then return end
    if not near(src, entity, LOCK_DISTANCE) then return end
    if not hasKeys(src, entity) then return notify(src, 'Kamu tidak punya kunci kendaraan ini.') end

    local plate = plateOf(entity)
    local given = 0

    for i = 1, math.min(#targets, 8) do
        local targetId = tonumber(targets[i])
        local target = targetId and targetId ~= src and qb_ecore:GetPlayer(targetId)

        if target then
            local a, b = GetPlayerPed(src), GetPlayerPed(targetId)
            if a ~= 0 and b ~= 0 and #(GetEntityCoords(a) - GetEntityCoords(b)) <= GIVE_DISTANCE + 3.0 then
                addHolder(target.PlayerData.citizenid, plate)
                TriggerClientEvent('sm_vehiclekeys:client:AddKeys', targetId, plate)
                notify(targetId, 'Kamu menerima kunci kendaraan.', 'success')
                given = given + 1
            end
        end
    end

    if given > 0 then
        notify(src, ('Kunci diberikan ke %d orang.'):format(given), 'success')
    else
        notify(src, 'Tidak ada yang cukup dekat.')
    end
end)

-- dipanggil resource lain (garasi, dealer, rental) lewat TriggerEvent / TriggerServerEvent internal
AddEventHandler('sm_vehiclekeys:server:setVehicleOwner', function(plate, citizenid)
    plate, citizenid = normPlate(plate), tostring(citizenid or '')
    if not plate or citizenid == '' then return end

    addHolder(citizenid, plate)

    for _, raw in ipairs(GetPlayers()) do
        local src = tonumber(raw)
        if cidOf(src) == citizenid then
            TriggerClientEvent('sm_vehiclekeys:client:setVehicleOwner', src, plate)
        end
    end
end)

AddEventHandler('sm_vehiclekeys:server:removeKeys', function(plate)
    plate = normPlate(plate)
    if not plate then return end

    MySQL.update.await(('DELETE FROM %s WHERE plate = ?'):format(HOLDERS), { plate })
    TriggerClientEvent('sm_vehiclekeys:client:RemoveKeys', -1, plate)
end)

exports('AddKeys', function(src, plate)
    local cid = cidOf(src)
    plate = normPlate(plate)
    if not cid or not plate then return false end

    addHolder(cid, plate)
    TriggerClientEvent('sm_vehiclekeys:client:AddKeys', src, plate)
    return true
end)

CreateThread(function()
    MySQL.query.await(([[
    CREATE TABLE IF NOT EXISTS `%s` (
        `plate` varchar(16) NOT NULL,
        `citizenid` varchar(64) NOT NULL,
        `created` int(11) NOT NULL,
        PRIMARY KEY (`plate`, `citizenid`),
        KEY `citizenid` (`citizenid`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]]):format(HOLDERS))

    -- migrasi sekali dari tabel lama (plate -> citizenid) kalau ada
    local ok = pcall(MySQL.query.await, ('INSERT IGNORE INTO %s (plate, citizenid, created) SELECT UPPER(TRIM(plate)), citizenid, created FROM sm_vehiclekeys'):format(HOLDERS))
    if ok then print('^2[sm_vehiclekeys] tabel lama dimigrasi (jika ada)^7') end
end)

AddEventHandler('playerDropped', function()
    local src = source
    hotwire[src], carjack[src], lastHotwire[src] = nil, nil, nil
end)
