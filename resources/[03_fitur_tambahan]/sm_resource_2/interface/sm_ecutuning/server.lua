--[[
    sm_ecutuning :: server
    Dibangun ulang dari kontrak client (modules/client_main.lua, client_dyno.lua, client_rollers.lua).

    Isi:
      * part terpasang per plat (DB `sm_ecutuning_vehicles`): install / remove / repair / flash ECU
      * settings tuning per plat (JSON dari client, peta `map` disanitasi lewat HRSPerf)
      * paket performa -> state bag `hrs_perf` di kendaraan, valve -> `hrsValve`
      * toko part (buyCart), Map Switch, Valve Control
      * search kendaraan + minigame sembunyi (searchVehicle / searchHideResult)
      * HUD & bahasa per karakter (`sm_ecutuning_prefs`)
      * dyno: beli / pasang / simpan / pakai, hasil run, posisi roller (carriage)
      * relay efek suara/api (shift, flame, diesel, turbo blow, pop) ke pemain sekitar

    Semua event dari client memakai RegisterTokenEvent (se_v2/trigger.lua).
    ASUMSI (ubah di bagian CONFIG bila perlu):
      - Society dikreditkan lewat salah satu dari Renewed-Banking / qb-banking / qb-management.
      - Paket performa dihitung dengan base 300 PS / 400 Nm (sama seperti fallback client).
      - Peluang gagal flash lewat menu = 0 (hanya aus karena FlashLimit).
]]

localmodule 'config'
localmodule 'modules.perf'
localmodule 'modules.locales'
local config = ECUConfig   -- config.lua mendefinisikan global ECUConfig

-- ===================== CONFIG (server) =====================
local BASE_PS, BASE_NM, BASE_ENGINE = 300, 400, 'turbo'
local MENU_FLASH_FAIL = 0.0          -- peluang gagal flash dari menu (selain aus)
local RELAY_RADIUS = 120.0           -- radius siaran efek (api, diesel, pop, turbo)
local SEARCH_HIDE_TIMEOUT = 25000    -- ms tunggu hasil minigame sembunyi
local SEARCH_RANGE = 8.0             -- jarak pencari ke kendaraan
local SETTINGS_MAX = 24000           -- batas panjang JSON settings
local SOCIETY_BANKS = {
    { 'Renewed-Banking', function(acc, amt) exports['Renewed-Banking']:addAccountMoney(acc, amt) end },
    { 'qb-banking',      function(acc, amt) exports['qb-banking']:AddMoney(acc, amt, 'ecutuning') end },
    { 'qb-management',   function(acc, amt) exports['qb-management']:AddMoney(acc, amt) end },
}

-- ===================== DB =====================
CreateThread(function()
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS sm_ecutuning_vehicles (
        plate VARCHAR(16) NOT NULL PRIMARY KEY,
        parts TEXT NULL,
        bricked TINYINT(1) NOT NULL DEFAULT 0,
        flashes INT NOT NULL DEFAULT 0,
        settings LONGTEXT NULL,
        updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    )]])
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS sm_ecutuning_prefs (
        citizenid VARCHAR(50) NOT NULL PRIMARY KEY,
        hud TEXT NULL,
        lang VARCHAR(8) NULL
    )]])
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS sm_ecutuning_dyno_owner (
        citizenid VARCHAR(50) NOT NULL PRIMARY KEY,
        placed TINYINT(1) NOT NULL DEFAULT 0,
        props LONGTEXT NULL
    )]])
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS sm_ecutuning_dyno_runs (
        plate VARCHAR(16) NOT NULL PRIMARY KEY,
        model VARCHAR(64) NULL,
        ps INT NOT NULL DEFAULT 0,
        nm INT NOT NULL DEFAULT 0,
        psrpm INT NULL,
        nmrpm INT NULL,
        curve LONGTEXT NULL,
        parts TEXT NULL,
        updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    )]])
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS sm_ecutuning_dyno_carriage (
        pos VARCHAR(48) NOT NULL PRIMARY KEY,
        x DOUBLE NOT NULL, y DOUBLE NOT NULL, z DOUBLE NOT NULL,
        wheelbase DOUBLE NOT NULL
    )]])
    ECU_DB_READY = true
end)

-- ===================== helpers =====================
local function clean(p)
    return (tostring(p or ''):gsub('%s+', ''):upper())
end

local function now() return GetGameTimer() end

local function getPlayer(src)
    return qb_ecore:GetPlayer(src)
end

local function cidOf(src)
    local p = getPlayer(src)
    return p and p.PlayerData.citizenid or nil
end

local function jobOf(src)
    local p = getPlayer(src)
    return p and p.PlayerData.job and p.PlayerData.job.name or nil
end

local function isAdmin(src)
    if IsPlayerAceAllowed(src, config.AdminAce or 'ecutune.admin') then return true end
    if IsPlayerAceAllowed(src, 'admin') or IsPlayerAceAllowed(src, 'command') then return true end
    local ok, res = pcall(function() return qb_ecore:HasPermission(src, 'admin') end)
    return ok and res == true
end

local function isMechanic(src)
    if isAdmin(src) then return true end
    if config.MechanicCheck == 'ace' then
        return IsPlayerAceAllowed(src, config.MechanicAce or 'ecutune.mechanic')
    end
    local job = jobOf(src)
    for _, j in ipairs(config.MechanicJobs or {}) do
        if j == job then return true end
    end
    return IsPlayerAceAllowed(src, config.MechanicAce or 'ecutune.mechanic')
end

local function notify(src, ntype, key, ...)
    local e = ECU_L(key)
    local title, msg = key, ''
    if type(e) == 'table' then
        title, msg = e[1] or key, e[2] or ''
        if select('#', ...) > 0 then
            local ok, out = pcall(string.format, msg, ...)
            if ok then msg = out end
        end
    end
    TriggerClientEvent('sm_ecutuning:notify', src, ntype, title, msg)
end

local function dynoNotify(src, ntype, key, ...)
    TriggerClientEvent('sm_ecutuning:dyno:notify', src, ntype, key, ...)
end

local function fmtMoney(n)
    return ('$%d'):format(math.floor(tonumber(n) or 0))
end

local function totalMoney(player)
    local t = 0
    for _, a in ipairs(config.Payment or { 'cash', 'bank' }) do
        t = t + (player.PlayerData.money[a] or 0)
    end
    return t
end

local function charge(player, amount, reason)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return true end
    if totalMoney(player) < amount then return false end
    local left = amount
    for _, a in ipairs(config.Payment or { 'cash', 'bank' }) do
        local have = player.PlayerData.money[a] or 0
        local take = math.min(have, left)
        if take > 0 then
            player.Functions.RemoveMoney(a, take, reason or 'sm_ecutuning')
            left = left - take
        end
        if left <= 0 then break end
    end
    return left <= 0
end

local function creditSociety(amount)
    local soc = config.ShopSociety
    amount = math.floor(tonumber(amount) or 0)
    if not soc or not soc.account or amount <= 0 then return end
    for i = 1, #SOCIETY_BANKS do
        local b = SOCIETY_BANKS[i]
        if GetResourceState(b[1]) == 'started' then
            local ok = pcall(b[2], soc.account, amount)
            if ok then return end
        end
    end
end

local function itemCount(src, item)
    return exports.ox_inventory:GetItemCount(src, item) or 0
end

local function distToCoords(src, x, y, z)
    local c = GetEntityCoords(GetPlayerPed(src))
    return #(c - vector3(x, y, z))
end

local function vehPlate(v)
    return clean(GetVehicleNumberPlateText(v))
end

local function findVehicle(src, plate, maxd)
    local ped = GetPlayerPed(src)
    local v = GetVehiclePedIsIn(ped, false)
    if v ~= 0 and vehPlate(v) == plate then return v end
    local pc = GetEntityCoords(ped)
    for _, e in ipairs(GetAllVehicles()) do
        if vehPlate(e) == plate and #(GetEntityCoords(e) - pc) <= maxd then return e end
    end
    return 0
end

local function inDriverSeat(src, v)
    return v ~= 0 and GetPedInVehicleSeat(v, -1) == GetPlayerPed(src)
end

local lastCall = {}
local function throttle(src, key, ms)
    local k = key .. ':' .. src
    local t = now()
    if lastCall[k] and t - lastCall[k] < ms then return true end
    lastCall[k] = t
    return false
end

-- ===================== data kendaraan =====================
local vehData = {}
local registeredCache = {}

local function loadVeh(plate)
    local d = vehData[plate]
    if d then return d end
    local row = MySQL.single.await('SELECT parts, bricked, flashes, settings FROM sm_ecutuning_vehicles WHERE plate = ?', { plate })
    d = { parts = {}, bricked = false, flashes = 0, settings = nil, ver = 0 }
    if row then
        local ok, parts = pcall(json.decode, row.parts or '[]')
        if ok and type(parts) == 'table' then d.parts = parts end
        d.bricked = (row.bricked or 0) == 1
        d.flashes = row.flashes or 0
        if row.settings and row.settings ~= '' then
            local ok2, st = pcall(json.decode, row.settings)
            if ok2 and type(st) == 'table' then d.settings = st end
        end
    end
    vehData[plate] = d
    return d
end

local function saveVeh(plate)
    local d = vehData[plate]
    if not d then return end
    MySQL.insert('INSERT INTO sm_ecutuning_vehicles (plate, parts, bricked, flashes, settings) VALUES (?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE parts = VALUES(parts), bricked = VALUES(bricked), flashes = VALUES(flashes), settings = VALUES(settings)',
        { plate, json.encode(d.parts), d.bricked and 1 or 0, d.flashes or 0, d.settings and json.encode(d.settings) or nil })
end

local function hasPart(d, key)
    for _, p in ipairs(d.parts) do
        if p == key then return true end
    end
    return false
end

local function removePartKey(d, key)
    for i = #d.parts, 1, -1 do
        if d.parts[i] == key then table.remove(d.parts, i) end
    end
end

local function isRegistered(plate)
    if not config.RegisteredOnly then return true end
    local c = registeredCache[plate]
    if c ~= nil and now() - c.t < 60000 then return c.v end
    local v = MySQL.scalar.await("SELECT 1 FROM player_vehicles WHERE REPLACE(plate, ' ', '') = ? LIMIT 1", { plate }) ~= nil
    registeredCache[plate] = { v = v, t = now() }
    return v
end

local function totalBoost(d)
    local t = 0
    for _, k in ipairs(d.parts) do
        local def = config.Parts[k]
        if def then t = t + (def.boost or 0) end
    end
    return t
end

-- paket performa -> state bag
local perfVer = 0
local function applyPerf(plate, veh)
    if not veh or veh == 0 or not DoesEntityExist(veh) then return nil end
    local d = loadVeh(plate)
    local map = d.settings and d.settings.map or nil
    local pkg = HRSPerf.compute({ ps = BASE_PS, nm = BASE_NM, engine = BASE_ENGINE }, d.parts, map)
    perfVer = perfVer + 1
    pkg.v = perfVer
    Entity(veh).state:set('hrs_perf', pkg, true)
    return pkg
end

local function sendParts(src, plate)
    local d = loadVeh(plate)
    TriggerClientEvent('sm_ecutuning:receiveParts', src, plate, d.parts, d.bricked)
end

local function perms(src)
    local mech = isMechanic(src)
    local mo = config.MechanicOnly or {}
    return {
        mapLocked = mo.customMap == true and not mech,
        stage3Locked = mo.stage3 == true and not mech,
        msLocked = mo.mapSwitch == true and not mech,
        isAdmin = isAdmin(src),
    }
end

-- ===================== sesi kerja (install / remove / flash) =====================
local jobs = {}        -- src -> sesi
local plateBusy = {}   -- plate -> src

local function clearJob(src)
    local j = jobs[src]
    if j then
        if plateBusy[j.plate] == src then plateBusy[j.plate] = nil end
        jobs[src] = nil
    end
end

local function startJob(src, plate, kind, key, dur, extra)
    local j = jobs[src]
    if j and now() - j.at < j.dur + 30000 then
        notify(src, 'warn', 'busy')
        return nil
    end
    local other = plateBusy[plate]
    if other and other ~= src and jobs[other] and now() - jobs[other].at < jobs[other].dur + 30000 then
        notify(src, 'warn', 'veh_busy')
        return nil
    end
    local s = { kind = kind, plate = plate, key = key, dur = dur, at = now() }
    if extra then for k, v in pairs(extra) do s[k] = v end end
    jobs[src] = s
    plateBusy[plate] = src
    return s
end

local function takeJob(src, kind, plate, key)
    local j = jobs[src]
    if not j or j.kind ~= kind or j.plate ~= plate or (key and j.key ~= key) then return nil end
    if now() - j.at < j.dur * 0.85 then return nil end
    clearJob(src)
    return j
end

local function speedFactor(src)
    local sb = config.SpeedBoost
    if not sb or not sb.enabled then return 1.0 end
    if isAdmin(src) then return sb.adminFactor or 1.0 end
    return (sb.jobs and sb.jobs[jobOf(src)]) or 1.0
end

local function freeInstall(src)
    if isAdmin(src) then return true end
    local fj = config.FreeInstallJobs or {}
    return fj[jobOf(src)] == true
end

-- ===================== open / data =====================
RegisterTokenEvent('sm_ecutuning:requestOpen', function(plate, model, class, netId)
    local src = source
    plate = clean(plate)
    if throttle(src, 'open', 500) then return end
    if plate == '' then return TriggerClientEvent('sm_ecutuning:openDenied', src) end

    if config.AccessMode == 'mechanic' and not isMechanic(src) then
        notify(src, 'err', 'no_perm_open')
        return TriggerClientEvent('sm_ecutuning:openDenied', src)
    end
    if config.RequireOBD and not isAdmin(src) and itemCount(src, config.OBDItem) < 1 then
        notify(src, 'err', 'obd_missing')
        return TriggerClientEvent('sm_ecutuning:openDenied', src)
    end
    if HRSVehicleBlocked(model, class) then
        notify(src, 'err', 'veh_blocked')
        return TriggerClientEvent('sm_ecutuning:openDenied', src)
    end
    local v = findVehicle(src, plate, 15.0)
    if v ~= 0 and config.AllowedTypes and not config.AllowedTypes[GetVehicleType(v)] then
        notify(src, 'err', 'veh_blocked')
        return TriggerClientEvent('sm_ecutuning:openDenied', src)
    end
    if v == 0 then
        return TriggerClientEvent('sm_ecutuning:openDenied', src)
    end

    local d = loadVeh(plate)
    TriggerClientEvent('sm_ecutuning:openGranted', src, plate, d.parts, d.bricked, perms(src))
end)

RegisterTokenEvent('sm_ecutuning:requestParts', function(plate)
    local src = source
    plate = clean(plate)
    if plate == '' or throttle(src, 'parts', 300) then return end
    sendParts(src, plate)
end)

RegisterTokenEvent('sm_ecutuning:loadSettings', function(plate)
    local src = source
    plate = clean(plate)
    if plate == '' or throttle(src, 'load', 300) then return end
    local d = loadVeh(plate)
    TriggerClientEvent('sm_ecutuning:receiveSettings', src, plate, d.settings and json.encode(d.settings) or nil)
end)

local function sanitizeSettings(raw, d, src)
    if type(raw) ~= 'string' or #raw > SETTINGS_MAX then return nil end
    local ok, t = pcall(json.decode, raw)
    if not ok or type(t) ~= 'table' then return nil end
    local stage = HRSPerf.stageOf(d.parts)
    local mo = config.MechanicOnly or {}
    if mo.customMap and not isMechanic(src) then
        t.map = d.settings and d.settings.map or nil
    end
    if t.map ~= nil then t.map = HRSPerf.sanitizeMap(t.map, stage) end
    return t
end

RegisterTokenEvent('sm_ecutuning:saveSettings', function(plate, raw)
    local src = source
    plate = clean(plate)
    if plate == '' or throttle(src, 'save', 800) then return end
    local v = findVehicle(src, plate, 6.0)
    if v == 0 then return end
    if not isRegistered(plate) then return end
    local d = loadVeh(plate)
    if d.bricked then return end
    local t = sanitizeSettings(raw, d, src)
    if not t then return end
    d.settings = t
    saveVeh(plate)
    applyPerf(plate, v)
end)

RegisterTokenEvent('sm_ecutuning:resetSettings', function(plate, netId, model)
    local src = source
    plate = clean(plate)
    if plate == '' or throttle(src, 'reset', 800) then return end
    local v = findVehicle(src, plate, 8.0)
    if v == 0 or not isRegistered(plate) then return end
    local d = loadVeh(plate)
    if d.bricked then return notify(src, 'err', 'ecu_bricked') end
    d.settings = nil
    saveVeh(plate)
    applyPerf(plate, v)
    notify(src, 'ok', 'settings_reset')
    TriggerClientEvent('sm_ecutuning:settingsReset', src, plate)
end)

RegisterTokenEvent('sm_ecutuning:perf:request', function(plate, model, netId)
    local src = source
    plate = clean(plate)
    if plate == '' or throttle(src, 'perf', 700) then return end
    local v = findVehicle(src, plate, 30.0)
    if v == 0 then return end
    local pkg = applyPerf(plate, v)
    if pkg then
        TriggerClientEvent('sm_ecutuning:perf:package', src, plate, pkg)
    end
end)

RegisterTokenEvent('sm_ecutuning:perf:reset', function(plate, model, netId)
    local src = source
    plate = clean(plate)
    if plate == '' or throttle(src, 'perf', 700) then return end
    local v = findVehicle(src, plate, 8.0)
    if v == 0 then return end
    local d = loadVeh(plate)
    if d.settings then
        d.settings.map = nil
        if isRegistered(plate) then saveVeh(plate) end
    end
    local pkg = applyPerf(plate, v)
    if pkg then TriggerClientEvent('sm_ecutuning:perf:package', src, plate, pkg) end
end)

-- ===================== install / remove =====================
local function reqMissing(d, def)
    for _, r in ipairs(def.requires or {}) do
        if not hasPart(d, r) then return r end
    end
    return nil
end

RegisterTokenEvent('sm_ecutuning:installPart', function(plate, key)
    local src = source
    plate = clean(plate)
    key = tostring(key or '')
    local def = config.Parts[key]
    if plate == '' or not def or def.noItem then return end
    if HRSPartDisabled(key) then return end

    local v = findVehicle(src, plate, 6.0)
    if v == 0 or not inDriverSeat(src, v) and GetVehiclePedIsIn(GetPlayerPed(src), false) ~= 0 then return end
    if config.AllowedTypes and not config.AllowedTypes[GetVehicleType(v)] then return notify(src, 'err', 'veh_blocked') end

    if config.InstallMode == 'mechanic' and not isMechanic(src) then
        return notify(src, 'err', 'no_perm_install')
    end
    local mo = config.MechanicOnly or {}
    if key == 'ecustage3' and mo.stage3 and not isMechanic(src) then return notify(src, 'err', 'mech_only_stage3') end
    if not isRegistered(plate) then return notify(src, 'err', 'save_not_owned') end

    local d = loadVeh(plate)
    if hasPart(d, key) then return notify(src, 'warn', 'part_already', def.label) end
    if def.isECU and d.bricked then return notify(src, 'err', 'ecu_bricked') end
    local miss = reqMissing(d, def)
    if miss then return notify(src, 'warn', 'req_missing', config.Parts[miss] and config.Parts[miss].label or miss) end
    if def.requiresAny then
        local any = false
        for _, r in ipairs(def.requiresAny) do if hasPart(d, r) then any = true break end end
        if not any then return notify(src, 'warn', 'req_missing', config.Parts[def.requiresAny[1]].label) end
    end

    local free = freeInstall(src)
    if not free and itemCount(src, def.item) < 1 then
        return notify(src, 'err', 'part_missing', def.label)
    end

    local dur = math.floor((def.installTime or 20000) / speedFactor(src))
    local failed = math.random() < (def.failChance or 0.0)
    local s = startJob(src, plate, 'install', key, dur, { failed = failed, free = free })
    if not s then return end
    TriggerClientEvent('sm_ecutuning:startInstall', src, plate, key, failed, dur)
end)

RegisterTokenEvent('sm_ecutuning:finishInstall', function(plate, key, _failedFromClient)
    local src = source
    plate = clean(plate)
    key = tostring(key or '')
    local j = takeJob(src, 'install', plate, key)
    if not j then return end
    local def = config.Parts[key]
    if not def then return end
    local d = loadVeh(plate)

    if not j.free then
        if not exports.ox_inventory:RemoveItem(src, def.item, 1) then
            return notify(src, 'err', 'part_missing', def.label)
        end
    end

    if j.failed then
        if def.isECU and config.BrickEngineOnFail then
            d.bricked = true
            saveVeh(plate)
            TriggerClientEvent('sm_ecutuning:engineBricked', src, plate)
            notify(src, 'err', 'ecu_brick_fail')
        else
            notify(src, 'err', 'install_fail', def.label)
        end
        return sendParts(src, plate)
    end

    for _, r in ipairs(def.replaces or {}) do removePartKey(d, r) end
    if not hasPart(d, key) then d.parts[#d.parts + 1] = key end
    d.flashes = def.isECU and ((d.flashes or 0) + 1) or (d.flashes or 0)
    saveVeh(plate)
    notify(src, 'ok', 'part_installed', def.label, '')
    sendParts(src, plate)
    local v = findVehicle(src, plate, 10.0)
    local pkg = applyPerf(plate, v)
    if pkg then TriggerClientEvent('sm_ecutuning:perf:package', src, plate, pkg) end
end)

RegisterTokenEvent('sm_ecutuning:removePart', function(plate, key)
    local src = source
    plate = clean(plate)
    key = tostring(key or '')
    local def = config.Parts[key]
    if plate == '' or not def or def.hidden then return end
    local v = findVehicle(src, plate, 6.0)
    if v == 0 then return end
    if config.InstallMode == 'mechanic' and not isMechanic(src) then return notify(src, 'err', 'no_perm_install') end
    if not isRegistered(plate) then return notify(src, 'err', 'save_not_owned') end

    local d = loadVeh(plate)
    if not hasPart(d, key) then return notify(src, 'warn', 'part_not_installed', def.label) end
    if def.isECU and d.bricked then return notify(src, 'err', 'ecu_bricked') end
    for _, other in ipairs(d.parts) do
        local od = config.Parts[other]
        if od and od.requires then
            for _, r in ipairs(od.requires) do
                if r == key then return notify(src, 'warn', 'remove_blocked', od.label) end
            end
        end
    end
    if def.item and not exports.ox_inventory:CanCarryItem(src, def.item, 1) then
        return notify(src, 'warn', 'inventory_full', def.label)
    end

    local dur = math.floor((config.RemoveTime or 8000) / speedFactor(src))
    if not startJob(src, plate, 'remove', key, dur) then return end
    TriggerClientEvent('sm_ecutuning:startRemove', src, plate, key, dur)
end)

RegisterTokenEvent('sm_ecutuning:finishRemove', function(plate, key)
    local src = source
    plate = clean(plate)
    key = tostring(key or '')
    local j = takeJob(src, 'remove', plate, key)
    if not j then return end
    local def = config.Parts[key]
    local d = loadVeh(plate)
    if not def or not hasPart(d, key) then return end

    removePartKey(d, key)
    saveVeh(plate)
    if def.item then exports.ox_inventory:AddItem(src, def.item, 1) end
    notify(src, 'ok', 'part_removed', def.label)
    sendParts(src, plate)
    local v = findVehicle(src, plate, 10.0)
    local pkg = applyPerf(plate, v)
    if pkg then TriggerClientEvent('sm_ecutuning:perf:package', src, plate, pkg) end
end)

-- ===================== repair =====================
RegisterTokenEvent('sm_ecutuning:repairECU', function(plate)
    local src = source
    plate = clean(plate)
    if plate == '' or throttle(src, 'repair', 800) then return end
    if findVehicle(src, plate, 8.0) == 0 then return end
    local d = loadVeh(plate)
    if not d.bricked then return notify(src, 'warn', 'repair_not_needed') end
    local item = config.RepairItem
    if not isAdmin(src) then
        if not exports.ox_inventory:RemoveItem(src, item, 1) then
            local label = item
            for _, t in ipairs(config.Tools or {}) do if t.item == item then label = t.label end end
            return notify(src, 'err', 'no_repair_kit', label)
        end
    end
    d.bricked = false
    d.flashes = 0
    saveVeh(plate)
    notify(src, 'ok', 'ecu_repaired')
    TriggerClientEvent('sm_ecutuning:engineFixed', src, plate)
end)

local blown = {}   -- plate -> ms

RegisterTokenEvent('sm_ecutuning:engineBlown', function(plate)
    local src = source
    plate = clean(plate)
    if plate == '' or throttle(src, 'blown', 2000) then return end
    if findVehicle(src, plate, 8.0) == 0 then return end
    blown[plate] = now()
end)

RegisterTokenEvent('sm_ecutuning:engineRepairedFree', function(plate)
    local src = source
    plate = clean(plate)
    if plate ~= '' then blown[plate] = nil end
end)

RegisterTokenEvent('sm_ecutuning:repairEngine', function(plate)
    local src = source
    plate = clean(plate)
    if plate == '' or throttle(src, 'repairEng', 1000) then return end
    if not isMechanic(src) then return notify(src, 'err', 'no_permission') end
    if findVehicle(src, plate, 8.0) == 0 then return end
    blown[plate] = nil
    TriggerClientEvent('sm_ecutuning:engineRepaired', src, plate)
end)

-- ===================== flash dari menu =====================
RegisterTokenEvent('sm_ecutuning:menuFlash', function(plate)
    local src = source
    plate = clean(plate)
    if plate == '' then return end
    local v = findVehicle(src, plate, 8.0)
    if v == 0 then return end
    if not isRegistered(plate) then return notify(src, 'err', 'flash_not_saved') end
    local d = loadVeh(plate)
    if d.bricked then return notify(src, 'err', 'ecu_bricked2') end

    local worn = (d.flashes or 0) >= (config.FlashLimit or 15)
    local failed = worn or math.random() < MENU_FLASH_FAIL
    local dur = math.floor((config.MenuFlashTime or 15000) / speedFactor(src))
    if not startJob(src, plate, 'flash', nil, dur, { failed = failed, worn = worn }) then return end
    TriggerClientEvent('sm_ecutuning:startMenuFlash', src, plate, failed, dur)
end)

RegisterTokenEvent('sm_ecutuning:finishMenuFlash', function(plate, raw, _failed, model, netId)
    local src = source
    plate = clean(plate)
    local j = takeJob(src, 'flash', plate, nil)
    if not j then return end
    local d = loadVeh(plate)

    if j.failed then
        if config.BrickEngineOnFail then
            d.bricked = true
            TriggerClientEvent('sm_ecutuning:engineBricked', src, plate)
        end
        saveVeh(plate)
        notify(src, 'err', j.worn and 'ecu_worn' or 'ecu_dead_flash')
        return sendParts(src, plate)
    end

    local t = sanitizeSettings(raw, d, src)
    if not t then return end
    d.settings = t
    d.flashes = (d.flashes or 0) + 1
    saveVeh(plate)
    notify(src, 'ok', 'flash_ok')
    local v = findVehicle(src, plate, 10.0)
    local pkg = applyPerf(plate, v)
    if pkg then TriggerClientEvent('sm_ecutuning:perf:package', src, plate, pkg) end
end)

-- ===================== Map Switch & Valve Control =====================
RegisterTokenEvent('sm_ecutuning:buyMapSwitch', function(plate)
    local src = source
    plate = clean(plate)
    local def = config.Parts.mapswitch
    if plate == '' or not def or throttle(src, 'buyms', 1500) then return end
    local v = findVehicle(src, plate, 6.0)
    if v == 0 then return notify(src, 'warn', 'mapswitch_no_vehicle') end
    local mo = config.MechanicOnly or {}
    if mo.mapSwitch and not isMechanic(src) then return notify(src, 'err', 'mech_only_mapswitch') end
    if not isRegistered(plate) then return notify(src, 'err', 'save_not_owned') end
    local d = loadVeh(plate)
    if hasPart(d, 'mapswitch') then return notify(src, 'warn', 'mapswitch_owned') end
    if d.bricked then return notify(src, 'err', 'ecu_bricked') end

    local player = getPlayer(src)
    if not player then return end
    local dur = math.floor((def.installTime or 8000) / speedFactor(src))
    if not startJob(src, plate, 'mapswitch', 'mapswitch', dur) then return end
    local price = freeInstall(src) and 0 or (def.price or 0)
    if not charge(player, price, 'ecutuning-mapswitch') then
        clearJob(src)
        return notify(src, 'err', 'not_enough_money', price, def.label)
    end
    creditSociety(price * ((config.ShopSociety and config.ShopSociety.share) or 0))
    TriggerClientEvent('sm_ecutuning:mapSwitchInstall', src, dur, def.label)
    SetTimeout(dur, function()
        clearJob(src)
        local dd = loadVeh(plate)
        if not hasPart(dd, 'mapswitch') then dd.parts[#dd.parts + 1] = 'mapswitch' end
        saveVeh(plate)
        TriggerClientEvent('sm_ecutuning:mapSwitchDone', src)
        notify(src, 'ok', 'part_installed', def.label, '')
        sendParts(src, plate)
    end)
end)

RegisterTokenEvent('sm_ecutuning:buyExhaustValve', function(plate)
    local src = source
    plate = clean(plate)
    local def = config.Parts.exhaustvalve
    if plate == '' or not def or throttle(src, 'buyvalve', 1500) then return end
    local v = findVehicle(src, plate, 6.0)
    if v == 0 then return notify(src, 'warn', 'mapswitch_no_vehicle') end
    if not isRegistered(plate) then return notify(src, 'err', 'save_not_owned') end
    local d = loadVeh(plate)
    if hasPart(d, 'exhaustvalve') then return notify(src, 'warn', 'valve_owned') end

    local player = getPlayer(src)
    if not player then return end
    local price = freeInstall(src) and 0 or (def.price or 0)
    if not charge(player, price, 'ecutuning-valve') then
        return notify(src, 'err', 'not_enough_money', price, def.label)
    end
    creditSociety(price * ((config.ShopSociety and config.ShopSociety.share) or 0))
    d.parts[#d.parts + 1] = 'exhaustvalve'
    saveVeh(plate)
    notify(src, 'ok', 'part_installed', def.label, '')
    sendParts(src, plate)
end)

RegisterTokenEvent('sm_ecutuning:valveToggle', function(netId, closeNow)
    local src = source
    if throttle(src, 'valve', 300) then return end
    netId = tonumber(netId)
    if not netId or not NetworkDoesNetworkIdExist(netId) then return end
    local v = NetworkGetEntityFromNetworkId(netId)
    if v == 0 or not DoesEntityExist(v) or not inDriverSeat(src, v) then return end
    local d = loadVeh(vehPlate(v))
    if not hasPart(d, 'exhaustvalve') then return end
    Entity(v).state:set('hrsValve', closeNow == true and 1 or 0, true)
end)

-- ===================== toko =====================
local function nearShop(src)
    local max = config.ShopMaxDistance or 6.0
    for _, l in ipairs(config.ShopLocations or {}) do
        if distToCoords(src, l.x, l.y, l.z) <= max then return true end
    end
    return false
end

local function shopAllowed(src)
    if config.ShopAccess == 'mechanic' then return isMechanic(src) end
    return true
end

RegisterTokenEvent('sm_ecutuning:requestShop', function()
    local src = source
    if throttle(src, 'shop', 500) then return end
    if not shopAllowed(src) then return notify(src, 'err', 'shop_no_access') end
    if not nearShop(src) then return end
    local player = getPlayer(src)
    if not player then return end
    TriggerClientEvent('sm_ecutuning:openShop', src, totalMoney(player), nil)
end)

RegisterTokenEvent('sm_ecutuning:buyCart', function(items)
    local src = source
    if throttle(src, 'cart', 800) then return end
    if not shopAllowed(src) then return notify(src, 'err', 'shop_no_access') end
    if not nearShop(src) then return end
    local player = getPlayer(src)
    if not player or type(items) ~= 'table' then return end

    local lines, total = {}, 0
    for i = 1, math.min(#items, 30) do
        local it = items[i]
        local key = type(it) == 'table' and tostring(it.key or '') or ''
        local qty = type(it) == 'table' and math.floor(tonumber(it.qty) or 0) or 0
        if qty >= 1 and qty <= 20 then
            local item, price, label
            local def = config.Parts[key]
            if def and def.item and not def.hidden and not HRSPartDisabled(key) then
                item, price, label = def.item, def.price or 0, def.label
            else
                for _, t in ipairs(config.Tools or {}) do
                    if t.item == key then item, price, label = t.item, t.price or 0, t.label end
                end
            end
            if item then
                lines[#lines + 1] = { item = item, qty = qty, label = label, price = price }
                total = total + price * qty
            end
        end
    end
    if #lines == 0 then return TriggerClientEvent('sm_ecutuning:cartResult', src, false, totalMoney(player)) end

    for _, l in ipairs(lines) do
        if not exports.ox_inventory:CanCarryItem(src, l.item, l.qty) then
            notify(src, 'warn', 'inventory_full', l.label)
            return TriggerClientEvent('sm_ecutuning:cartResult', src, false, totalMoney(player))
        end
    end
    if totalMoney(player) < total or not charge(player, total, 'ecutuning-shop') then
        notify(src, 'err', 'not_enough_money', total - totalMoney(player), '')
        return TriggerClientEvent('sm_ecutuning:cartResult', src, false, totalMoney(player))
    end
    for _, l in ipairs(lines) do
        exports.ox_inventory:AddItem(src, l.item, l.qty)
        notify(src, 'ok', 'bought', l.qty > 1 and (l.label .. ' x' .. l.qty) or l.label, l.price * l.qty)
    end
    creditSociety(total * ((config.ShopSociety and config.ShopSociety.share) or 0))
    TriggerClientEvent('sm_ecutuning:cartResult', src, true, totalMoney(player))
end)

-- ===================== HUD & bahasa =====================
local function ensurePrefs(cid)
    MySQL.insert.await('INSERT IGNORE INTO sm_ecutuning_prefs (citizenid) VALUES (?)', { cid })
end

RegisterTokenEvent('sm_ecutuning:hudSave', function(data)
    local src = source
    local cid = cidOf(src)
    if not cid or type(data) ~= 'table' or throttle(src, 'hudsave', 1000) then return end
    local ok, enc = pcall(json.encode, data)
    if not ok or not enc or #enc >= 4000 then return end
    ensurePrefs(cid)
    MySQL.update('UPDATE sm_ecutuning_prefs SET hud = ? WHERE citizenid = ?', { enc, cid })
end)

RegisterTokenEvent('sm_ecutuning:hudLoad', function()
    local src = source
    local cid = cidOf(src)
    if not cid then return end
    local raw = MySQL.scalar.await('SELECT hud FROM sm_ecutuning_prefs WHERE citizenid = ?', { cid })
    local cfg = {}
    if raw then
        local ok, dec = pcall(json.decode, raw)
        if ok and type(dec) == 'table' then cfg = dec end
    end
    TriggerClientEvent('sm_ecutuning:hudLoaded', src, cfg)
end)

RegisterTokenEvent('sm_ecutuning:setLang', function(l)
    local src = source
    local cid = cidOf(src)
    if not cid or type(l) ~= 'string' or #l > 8 or not ECULocales[l] then return end
    if throttle(src, 'lang', 1000) then return end
    ensurePrefs(cid)
    MySQL.update('UPDATE sm_ecutuning_prefs SET lang = ? WHERE citizenid = ?', { l, cid })
end)

-- ===================== search kendaraan =====================
local searches = {}   -- src pencari -> { plate, label, hider, at }

local function buildReport(plate, label, d, reveal)
    local list = {}
    for _, k in ipairs(d.parts) do
        local def = config.Parts[k]
        if def and not def.hidden then
            list[#list + 1] = {
                key = k, label = def.label, isECU = def.isECU == true,
                illegal = k ~= 'mapswitch' and k ~= 'exhaustvalve',
            }
        end
    end
    if reveal and reveal >= 0 then
        while #list > reveal do table.remove(list) end
    end
    return { vehLabel = label, plate = plate, totalBoost = totalBoost(d), parts = list }
end

local function finishSearch(src, hits)
    local s = searches[src]
    if not s then return end
    searches[src] = nil
    local d = loadVeh(s.plate)
    local sh = config.SearchHide or {}
    local reveal = -1
    if s.hider and sh.reveal then
        hits = math.max(0, math.min(3, math.floor(tonumber(hits) or 0)))
        reveal = sh.reveal[hits]
        if reveal == nil then reveal = -1 end
    end
    TriggerClientEvent('sm_ecutuning:searchResult', src, buildReport(s.plate, s.label, d, reveal))
end

RegisterTokenEvent('sm_ecutuning:searchVehicle', function(plate, label)
    local src = source
    plate = clean(plate)
    if plate == '' or throttle(src, 'search', 2000) then return end
    local sh = config.SearchHide or {}
    if (sh.requireItem or config.RequireOBD) and not isAdmin(src) and itemCount(src, sh.requireItem or config.OBDItem) < 1 then
        return notify(src, 'err', 'search_no_obd')
    end
    local v = findVehicle(src, plate, SEARCH_RANGE)
    if v == 0 then return notify(src, 'warn', 'search_no_vehicle') end
    label = tostring(label or plate):sub(1, 48)

    -- cari pemain yang bisa menyembunyikan: pengemudi / penumpang, atau pemain terdekat
    local hider
    if sh.enabled then
        for seat = -1, 3 do
            local ped = GetPedInVehicleSeat(v, seat)
            if ped ~= 0 then
                for _, pid in ipairs(GetPlayers()) do
                    local n = tonumber(pid)
                    if n ~= src and GetPlayerPed(n) == ped then hider = n break end
                end
            end
            if hider then break end
        end
    end

    local dur = config.SearchDuration or 2500
    TriggerClientEvent('sm_ecutuning:searchScan', src, label, dur)
    searches[src] = { plate = plate, label = label, hider = hider, at = now() }

    if hider then
        TriggerClientEvent('sm_ecutuning:searchHideOffer', hider, src, plate, {
            rounds = sh.rounds, zone = sh.zone, speed = sh.speed, distance = sh.distance,
        })
        SetTimeout(SEARCH_HIDE_TIMEOUT, function()
            local s = searches[src]
            if s and s.hider == hider then finishSearch(src, 0) end
        end)
    else
        SetTimeout(dur, function() finishSearch(src, 0) end)
    end
end)

RegisterTokenEvent('sm_ecutuning:searchHideResult', function(answerTo, hits)
    local src = source
    answerTo = tonumber(answerTo)
    if not answerTo then return end
    local s = searches[answerTo]
    if not s or s.hider ~= src then return end
    finishSearch(answerTo, hits)
end)

-- status untuk sm_carmaintenance
lib.callback.register('sm_ecutuning:status', function(src, plate)
    plate = clean(plate)
    if plate == '' then return nil end
    local d = loadVeh(plate)
    return { stage = HRSPerf.stageOf(d.parts), bricked = d.bricked, parts = #d.parts }
end)

-- ===================== relay efek =====================
local function nearbyPlayers(origin, radius, except)
    local out = {}
    for _, pid in ipairs(GetPlayers()) do
        local n = tonumber(pid)
        if n ~= except then
            local ped = GetPlayerPed(n)
            if ped ~= 0 and #(GetEntityCoords(ped) - origin) <= radius then out[#out + 1] = n end
        end
    end
    return out
end

local function originFor(src, netId, coords)
    netId = tonumber(netId)
    if not netId or netId == 0 or not NetworkDoesNetworkIdExist(netId) then return nil end
    local e = NetworkGetEntityFromNetworkId(netId)
    if e == 0 or not DoesEntityExist(e) then return nil end
    local c = GetEntityCoords(e)
    local pc = GetEntityCoords(GetPlayerPed(src))
    if #(c - pc) > 40.0 then return nil end
    return c
end

local function relay(src, key, ms, netId, radius, event, ...)
    if throttle(src, key, ms) then return end
    local origin = originFor(src, netId)
    if not origin then return end
    local args = { ... }
    for _, target in ipairs(nearbyPlayers(origin, radius or RELAY_RADIUS, src)) do
        TriggerClientEvent(event, target, table.unpack(args))
    end
end

local function str(v, max)
    if type(v) ~= 'string' then return nil end
    return v:sub(1, max or 32)
end

local function cleanRgb(rgb)
    if type(rgb) ~= 'table' then return nil end
    return { r = tonumber(rgb.r), g = tonumber(rgb.g), b = tonumber(rgb.b) }
end

RegisterTokenEvent('sm_ecutuning:broadcastShift', function(netId, key, vol, coords)
    local src = source
    relay(src, 'bshift', 150, netId, (config.ShiftSoundMaxDist or 45.0) + 10.0,
        'sm_ecutuning:playShift', tonumber(netId), str(key), tonumber(vol))
end)

RegisterTokenEvent('sm_ecutuning:broadcastFW', function(netId, enable, colorKey, coords, rgb)
    local src = source
    relay(src, 'bfw', 100, netId, RELAY_RADIUS, 'sm_ecutuning:renderFW',
        tonumber(netId), enable == true, str(colorKey), cleanRgb(rgb) or rgb)
end)

RegisterTokenEvent('sm_ecutuning:broadcastFWRandom', function(netId, an, colorKey, presetKey, coords, rgb)
    local src = source
    relay(src, 'bfwr', 100, netId, RELAY_RADIUS, 'sm_ecutuning:renderFWRandom',
        tonumber(netId), an == true, str(colorKey), str(presetKey), cleanRgb(rgb) or rgb)
end)

RegisterTokenEvent('sm_ecutuning:broadcastDiesel', function(netId, on, color, density, coords)
    local src = source
    relay(src, 'bdiesel', 100, netId, RELAY_RADIUS, 'sm_ecutuning:renderDiesel',
        tonumber(netId), on == true, str(color), tonumber(density))
end)

RegisterTokenEvent('sm_ecutuning:broadcastTurboBlow', function(netId, coords)
    local src = source
    relay(src, 'bblow', 1500, netId, RELAY_RADIUS, 'sm_ecutuning:renderTurboBlow', tonumber(netId))
end)

RegisterTokenEvent('sm_ecutuning:broadcastPop', function(netId, arr)
    local src = source
    if type(arr) ~= 'table' or #arr > 64 then return end
    local clean_arr = {}
    for i = 1, #arr do
        local e = arr[i]
        if type(e) == 'table' or type(e) == 'number' then clean_arr[i] = e end
    end
    relay(src, 'bpop', 60, netId, RELAY_RADIUS, 'sm_ecutuning:renderPop', tonumber(netId), clean_arr)
end)

-- ===================== dyno =====================
local DY = config.Dyno or {}
local dynoOwners = {}     -- citizenid -> { placed = bool, props = {...} }
local carriage = {}       -- 'x:y:z' -> { x, y, z, wb }
local useCooldown = {}

local function dynoPropDef(model)
    for _, d in ipairs(DY.Props or {}) do
        if d.model == model then return d end
    end
end

local function staticList()
    local out = {}
    local st = DY.Static
    if not st or not st.enabled then return out end
    for i, set in ipairs(st.list or {}) do
        local props = {}
        for _, p in ipairs(set) do
            props[#props + 1] = {
                model = p.model, x = p.x, y = p.y, z = p.z,
                rx = 0.0, ry = 0.0, rz = p.h or 0.0,
                isdyno = p.isDyno and 1 or 0,
            }
        end
        out[#out + 1] = { owner = 'static' .. i, props = props }
    end
    return out
end

local function dynoList()
    local list = staticList()
    for cid, o in pairs(dynoOwners) do
        if o.placed and o.props and #o.props > 0 then
            list[#list + 1] = { owner = cid, props = o.props }
        end
    end
    return list
end

local function placedCount()
    local n = 0
    for _, o in pairs(dynoOwners) do if o.placed then n = n + 1 end end
    return n
end

local function loadDynoOwner(cid)
    local o = dynoOwners[cid]
    if o ~= nil then return o or nil end
    local row = MySQL.single.await('SELECT placed, props FROM sm_ecutuning_dyno_owner WHERE citizenid = ?', { cid })
    if not row then dynoOwners[cid] = false return nil end
    local props = {}
    local ok, dec = pcall(json.decode, row.props or '[]')
    if ok and type(dec) == 'table' then props = dec end
    o = { placed = (row.placed or 0) == 1, props = props }
    dynoOwners[cid] = o
    return o
end

local function saveDynoOwner(cid)
    local o = dynoOwners[cid]
    if not o then return end
    MySQL.insert('INSERT INTO sm_ecutuning_dyno_owner (citizenid, placed, props) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE placed = VALUES(placed), props = VALUES(props)',
        { cid, o.placed and 1 or 0, json.encode(o.props or {}) })
end

-- owner yang belum dimuat dari DB (restart server): muat semua yang terpasang
CreateThread(function()
    while not ECU_DB_READY do Wait(200) end
    local rows = MySQL.query.await('SELECT citizenid, placed, props FROM sm_ecutuning_dyno_owner') or {}
    for _, r in ipairs(rows) do
        local props = {}
        local ok, dec = pcall(json.decode, r.props or '[]')
        if ok and type(dec) == 'table' then props = dec end
        dynoOwners[r.citizenid] = { placed = (r.placed or 0) == 1, props = props }
    end
    local car = MySQL.query.await('SELECT pos, x, y, z, wheelbase FROM sm_ecutuning_dyno_carriage') or {}
    for _, r in ipairs(car) do
        carriage[r.pos] = { x = r.x, y = r.y, z = r.z, wb = r.wheelbase }
    end
end)

local function canUseDyno(src)
    local mode = DY.UseAccess
    if mode == nil or mode == 'all' then return true end
    if isAdmin(src) then return true end
    local job = jobOf(src)
    return job ~= nil and DY.UseJobs ~= nil and DY.UseJobs[job] == true
end

local function canBuyDyno(src)
    local mode = DY.Access
    if mode == nil or mode == 'all' then return true end
    if isAdmin(src) then return true end
    local job = jobOf(src)
    return job ~= nil and DY.Jobs ~= nil and DY.Jobs[job] == true
end

local function ownState(src)
    local cid = cidOf(src)
    local o = cid and loadDynoOwner(cid) or nil
    return { owns = o ~= nil, stored = o ~= nil and not o.placed, mayUse = canUseDyno(src) }
end

local function pushState(src)
    TriggerClientEvent('sm_ecutuning:dyno:ownState', src, ownState(src))
end

local function broadcastDyno()
    TriggerClientEvent('sm_ecutuning:dyno:sync', -1, dynoList())
end

RegisterTokenEvent('sm_ecutuning:dyno:request', function()
    local src = source
    if throttle(src, 'dreq', 500) then return end
    TriggerClientEvent('sm_ecutuning:dyno:sync', src, dynoList())
    pushState(src)
end)

RegisterTokenEvent('sm_ecutuning:dyno:buy', function()
    local src = source
    if throttle(src, 'dbuy', 1500) then return end
    local player, cid = getPlayer(src), cidOf(src)
    if not player or not cid then return dynoNotify(src, 'error', 'dyno_no_framework') end
    if not canBuyDyno(src) then return dynoNotify(src, 'error', 'dyno_no_perm') end
    if loadDynoOwner(cid) then return dynoNotify(src, 'error', 'dyno_already_own') end
    local price = DY.PriceBuy or 0
    if not charge(player, price, 'ecutuning-dyno-buy') then return dynoNotify(src, 'error', 'dyno_no_money') end
    dynoOwners[cid] = { placed = false, props = {} }
    saveDynoOwner(cid)
    dynoNotify(src, 'success', 'dyno_bought', fmtMoney(price))
    pushState(src)
end)

local function validProps(src, out)
    if type(out) ~= 'table' or #out < 1 or #out > #(DY.Props or {}) + 2 then return nil end
    local props, hasDyno = {}, false
    local maxd = (DY.PlaceMaxDistance or 25.0) + 10.0
    for i = 1, #out do
        local p = out[i]
        if type(p) ~= 'table' then return nil end
        local def = dynoPropDef(tostring(p.model))
        local x, y, z = tonumber(p.x), tonumber(p.y), tonumber(p.z)
        if not def or not x or not y or not z then return nil end
        if distToCoords(src, x, y, z) > maxd then return false end
        props[#props + 1] = {
            model = def.model, x = x, y = y, z = z,
            rx = tonumber(p.rx) or 0.0, ry = tonumber(p.ry) or 0.0, rz = tonumber(p.rz) or 0.0,
            isdyno = def.isDyno and 1 or 0,
        }
        if def.isDyno then hasDyno = true end
    end
    if not hasDyno then return nil end
    return props
end

RegisterTokenEvent('sm_ecutuning:dyno:place', function(out, edit)
    local src = source
    if throttle(src, 'dplace', 1000) then return end
    local cid = cidOf(src)
    if not cid then return dynoNotify(src, 'error', 'dyno_no_framework') end
    local o = loadDynoOwner(cid)
    if not o then return dynoNotify(src, 'error', 'dyno_none_own') end

    if edit then
        if not o.placed then return dynoNotify(src, 'error', 'dyno_not_placed') end
        local near = false
        for _, p in ipairs(o.props) do
            if distToCoords(src, p.x, p.y, p.z) <= (DY.EditRange or 15.0) + 5.0 then near = true break end
        end
        if not near then return dynoNotify(src, 'warn', 'dyno_edit_far', 99) end
    else
        if o.placed then return dynoNotify(src, 'error', 'dyno_already_placed') end
        if placedCount() >= (DY.MaxDynos or 5) then return dynoNotify(src, 'error', 'dyno_limit') end
    end

    local props = validProps(src, out)
    if props == false then return dynoNotify(src, 'error', 'dyno_too_far') end
    if not props then return end
    o.placed = true
    o.props = props
    saveDynoOwner(cid)
    broadcastDyno()
    pushState(src)
    dynoNotify(src, 'success', edit and 'dyno_edited' or 'dyno_placed')
end)

RegisterTokenEvent('sm_ecutuning:dyno:store', function()
    local src = source
    if throttle(src, 'dstore', 1000) then return end
    local player, cid = getPlayer(src), cidOf(src)
    if not player or not cid then return dynoNotify(src, 'error', 'dyno_no_framework') end
    local o = loadDynoOwner(cid)
    if not o then return dynoNotify(src, 'error', 'dyno_none_own') end
    if not o.placed then return dynoNotify(src, 'error', 'dyno_already_stored') end
    local price = DY.PriceRelocate or 0
    if not charge(player, price, 'ecutuning-dyno-store') then return dynoNotify(src, 'error', 'dyno_no_money') end
    o.placed = false
    o.props = {}
    saveDynoOwner(cid)
    broadcastDyno()
    pushState(src)
    dynoNotify(src, 'success', 'dyno_stored', fmtMoney(price))
end)

local function findDyno(owner)
    owner = tostring(owner or '')
    for _, d in ipairs(dynoList()) do
        if d.owner == owner then return d end
    end
end

RegisterTokenEvent('sm_ecutuning:dyno:requestUse', function(owner)
    local src = source
    if throttle(src, 'duse', 800) then return end
    if not canUseDyno(src) then return dynoNotify(src, 'error', 'dyno_no_use') end
    local d = findDyno(owner)
    if not d then return dynoNotify(src, 'error', 'dyno_not_placed') end

    local near = false
    for _, p in ipairs(d.props) do
        if (p.isdyno == 1 or p.isdyno == true) and distToCoords(src, p.x, p.y, p.z) <= (DY.MountDistance or 4.0) + 8.0 then
            near = true
            break
        end
    end
    if not near then return dynoNotify(src, 'error', 'dyno_too_far') end

    local fee = DY.UseFee
    if fee and fee.enabled and (fee.price or 0) > 0 then
        local player = getPlayer(src)
        if not player then return end
        if not charge(player, fee.price, 'ecutuning-dyno-fee') then
            return dynoNotify(src, 'error', 'dyno_no_money')
        end
        dynoNotify(src, 'info', 'dyno_fee_paid', fmtMoney(fee.price))
        if fee.toOwner and not tostring(d.owner):find('^static') then
            local owner = qb_ecore:GetPlayerByCitizenId(d.owner)
            if owner then
                owner.Functions.AddMoney('bank', fee.price, 'ecutuning-dyno-fee')
                dynoNotify(owner.PlayerData.source, 'info', 'dyno_fee_earned', fmtMoney(fee.price))
            end
        end
    end
    TriggerClientEvent('sm_ecutuning:dyno:useGranted', src)
end)

RegisterTokenEvent('sm_ecutuning:dyno:remoteState', function(netId, active, wheels)
    local src = source
    if throttle(src, 'dremote', 200) then return end
    netId = tonumber(netId)
    if not netId or not NetworkDoesNetworkIdExist(netId) then return end
    local v = NetworkGetEntityFromNetworkId(netId)
    if v == 0 or not DoesEntityExist(v) then return end
    local w
    if active == true and type(wheels) == 'table' and #wheels <= 8 then
        w = {}
        for i = 1, #wheels do
            local n = tonumber(wheels[i])
            if n and n >= 0 and n <= 11 then w[#w + 1] = math.floor(n) end
        end
    end
    TriggerClientEvent('sm_ecutuning:dyno:remoteState', -1, src, netId, active == true, w)
end)

local function clampNum(v, lo, hi)
    v = tonumber(v)
    if not v then return nil end
    return math.max(lo, math.min(hi, v))
end

RegisterTokenEvent('sm_ecutuning:dyno:saveResult', function(model, ps, nm, plate, curve, psRpm, nmRpm, partList)
    local src = source
    plate = clean(plate)
    if plate == '' or throttle(src, 'dsave', 1500) then return end
    ps, nm = clampNum(ps, 0, 5000), clampNum(nm, 0, 8000)
    if not ps or not nm then return end
    local slim = {}
    if type(curve) == 'table' then
        for i = 1, math.min(#curve, 200) do
            local c = curve[i]
            if type(c) == 'table' then
                slim[#slim + 1] = { r = tonumber(c.r) or 0, p = tonumber(c.p) or 0, n = tonumber(c.n) or 0 }
            end
        end
    end
    local parts = {}
    if type(partList) == 'table' then
        for i = 1, math.min(#partList, 30) do
            local e = partList[i]
            if type(e) == 'string' then parts[#parts + 1] = e:sub(1, 48)
            elseif type(e) == 'table' then parts[#parts + 1] = e end
        end
    end
    MySQL.insert('INSERT INTO sm_ecutuning_dyno_runs (plate, model, ps, nm, psrpm, nmrpm, curve, parts) VALUES (?, ?, ?, ?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE model = VALUES(model), ps = VALUES(ps), nm = VALUES(nm), psrpm = VALUES(psrpm), nmrpm = VALUES(nmrpm), curve = VALUES(curve), parts = VALUES(parts)',
        { plate, tostring(model or ''):sub(1, 64), math.floor(ps), math.floor(nm),
          clampNum(psRpm, 0, 99999), clampNum(nmRpm, 0, 99999), json.encode(slim), json.encode(parts) })
end)

RegisterTokenEvent('sm_ecutuning:dyno:lastRun', function(plate)
    local src = source
    plate = clean(plate)
    if plate == '' or throttle(src, 'dlast', 400) then return end
    local row = MySQL.single.await('SELECT model, ps, nm, psrpm, nmrpm, curve FROM sm_ecutuning_dyno_runs WHERE plate = ?', { plate })
    if not row then return TriggerClientEvent('sm_ecutuning:dyno:lastRunResult', src, nil) end
    local curve
    local ok, dec = pcall(json.decode, row.curve or '[]')
    if ok and type(dec) == 'table' and #dec > 0 then curve = dec end
    TriggerClientEvent('sm_ecutuning:dyno:lastRunResult', src, {
        ps = row.ps, nm = row.nm, psrpm = row.psrpm, nmrpm = row.nmrpm, model = row.model, curve = curve,
    })
end)

RegisterTokenEvent('sm_ecutuning:dyno:carriageSnapshot', function()
    local src = source
    if throttle(src, 'dcsnap', 2000) then return end
    for _, c in pairs(carriage) do
        TriggerClientEvent('sm_ecutuning:dyno:carriage', src, c.x, c.y, c.z, c.wb)
    end
end)

RegisterTokenEvent('sm_ecutuning:dyno:carriage', function(x, y, z, wheelbase)
    local src = source
    if throttle(src, 'dcar', 300) then return end
    x, y, z = tonumber(x), tonumber(y), tonumber(z)
    local r = DY.Rollers or {}
    wheelbase = clampNum(wheelbase, r.minWheelbase or 2.2, r.maxWheelbase or 3.4)
    if not x or not y or not z or not wheelbase then return end
    if distToCoords(src, x, y, z) > 20.0 then return end
    local key = ('%.2f:%.2f:%.2f'):format(x, y, z)
    carriage[key] = { x = x, y = y, z = z, wb = wheelbase }
    MySQL.insert('INSERT INTO sm_ecutuning_dyno_carriage (pos, x, y, z, wheelbase) VALUES (?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE wheelbase = VALUES(wheelbase)',
        { key, x, y, z, wheelbase })
    TriggerClientEvent('sm_ecutuning:dyno:carriage', -1, x, y, z, wheelbase)
end)

lib.callback.register('sm_ecutuning:dyno:canStatic', function(src)
    if isAdmin(src) then return true end
    local ok, grp = pcall(function() return qb_ecore:GetPermission(src) end)
    if ok then
        local groups = DY.AdminGroups or {}
        if type(grp) == 'table' then
            for g in pairs(grp) do if groups[g] then return true end end
        elseif type(grp) == 'string' and groups[grp] then
            return true
        end
    end
    return false
end)

-- ===================== cleanup =====================
AddEventHandler('playerDropped', function()
    local src = source
    clearJob(src)
    searches[src] = nil
    for k in pairs(lastCall) do
        if k:sub(-#tostring(src) - 1) == ':' .. src then lastCall[k] = nil end
    end
    TriggerClientEvent('sm_ecutuning:dyno:remoteState', -1, src, 0, false)
end)
