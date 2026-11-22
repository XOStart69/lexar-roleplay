--[[
    fuelsystem :: server
    Status pom, harga per liter/kwh, pembayaran pengisian, jerigen, dan manajemen pom
    (label, harga, status, role, kas, karyawan) plus misi pengiriman minyak.
]]

local config = localmodule 'config.station'
local management = localmodule 'config.management'
local fuelConsum = localmodule 'config.consum'

local QBCore = exports['qb-core']:GetCoreObject()

local PRICE = management.price_config or {}
local DEFAULT_FUEL = management.default_fuel or 10
local MAX_EMPLOYEE = management.max_employee or 10
local MISSION = management.mission or {}

local stations = {}

local SCHEMA = [[
CREATE TABLE IF NOT EXISTS `sm_fuel_stations` (
    `id` varchar(32) NOT NULL,
    `label` varchar(64) NOT NULL DEFAULT 'Pom Bensin',
    `status` varchar(16) NOT NULL DEFAULT 'open',
    `fuel` int(11) NOT NULL DEFAULT 100,
    `price_refuel` int(11) NOT NULL DEFAULT 400,
    `price_charger` int(11) NOT NULL DEFAULT 350,
    `price_jerrycan` int(11) NOT NULL DEFAULT 10000,
    `balance` bigint(20) NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `sm_fuel_roles` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `station` varchar(32) NOT NULL,
    `citizenid` varchar(64) NOT NULL,
    `roleid` varchar(16) NOT NULL,
    `mission_complete` int(11) NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    UNIQUE KEY `station_citizen` (`station`, `citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `sm_fuel_role_defs` (
    `station` varchar(32) NOT NULL,
    `roleid` varchar(16) NOT NULL,
    `access` text NOT NULL,
    PRIMARY KEY (`station`, `roleid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `sm_fuel_logs` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `station` varchar(32) NOT NULL,
    `type` varchar(8) NOT NULL,
    `amount` bigint(20) NOT NULL,
    `date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `station_date` (`station`, `date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
]]

local function notify(src, message, nType)
    lib.notify(src, { description = message, type = nType or 'inform' })
end

local function ply(src)
    return QBCore.Functions.GetPlayer(src)
end

local function stationOf(id)
    if type(id) ~= 'string' then return nil end
    return stations[id]
end

local function access(src, station, key)
    local player = ply(src)
    if not player then return false end

    local row = MySQL.single.await('SELECT roleid FROM sm_fuel_roles WHERE station = ? AND citizenid = ?', {
        station.id, player.PlayerData.citizenid
    })

    if not row then return IsPlayerAceAllowed(src, 'admin') end

    if row.roleid == 'owner' then return true end

    local map = roleAccess(station, row.roleid)
    if not map then return false end

    return map[key] == true
end

local function save(station)
    MySQL.update.await([[
        UPDATE sm_fuel_stations SET label = ?, status = ?, fuel = ?, price_refuel = ?, price_charger = ?, price_jerrycan = ?, balance = ? WHERE id = ?
    ]], {
        station.label, station.status, station.fuel, station.price_refuel,
        station.price_charger, station.price_jerrycan, station.balance, station.id
    })
end

lib.callback.register('fuelsystem:station_status', function(_, id)
    local station = stationOf(id)
    if not station then return true end

    return station.status == 'open' and station.fuel > 0
end)

lib.callback.register('fuelsystem:getPrice', function(_, payload)
    local id, kind = type(payload) == 'table' and payload[1], type(payload) == 'table' and payload[2]
    local station = stationOf(id)

    if not station then
        local fallback = PRICE[kind]
        return fallback and math.floor((fallback.min + fallback.max) / 2) or 400
    end

    if kind == 'charger' then return station.price_charger end

    return station.price_refuel
end)

lib.callback.register('fuelsystem:success', function(src, payload)
    local id, payment, amount, electric = payload[1], payload[2], tonumber(payload[3]), payload[4]
    local player = ply(src)
    local station = stationOf(id)

    if not player or not station then return false end
    if station.status ~= 'open' then
        notify(src, 'Pom sedang tutup.', 'error')
        return false
    end

    amount = math.floor(amount or 0)
    if amount <= 0 then return false end

    local unit = electric and station.price_charger or station.price_refuel
    local total = math.floor(unit * amount)

    local account = payment == 'cash' and 'cash' or 'bank'
    if (player.PlayerData.money[account] or 0) < total then
        notify(src, 'Uang tidak cukup.', 'error')
        return false
    end

    player.Functions.RemoveMoney(account, total, 'fuel')
    MySQL.insert('INSERT INTO sm_fuel_logs (station, type, amount) VALUES (?, ?, ?)', { station.id, 'income', total })

    station.balance = station.balance + total
    station.fuel = math.max(0, station.fuel - math.floor(amount / 4))
    save(station)

    return true
end)

lib.callback.register('fuelsystem:updatePetrolcan', function(src, payload)
    local slot, fuel = payload[1], tonumber(payload[2])
    if not slot then return false end

    exports.ox_inventory:SetMetadata(src, slot, { cdn_fuel = math.floor(fuel or 0) })

    return true
end)

RegisterNetEvent('fuelsystem:beliJerigen', function(id)
    local src = source
    local player = ply(src)
    local station = stationOf(id)

    if not player or not station then return end

    local price = station.price_jerrycan

    if (player.PlayerData.money.cash or 0) < price then
        return notify(src, ('Jerigen butuh $%s.'):format(price), 'error')
    end

    if not exports.ox_inventory:AddItem(src, 'jerrycan', 1, { cdn_fuel = 100 }) then
        return notify(src, 'Inventory penuh.', 'error')
    end

    player.Functions.RemoveMoney('cash', price, 'jerrycan')
    MySQL.insert('INSERT INTO sm_fuel_logs (station, type, amount) VALUES (?, ?, ?)', { station.id, 'income', price })
    station.balance = station.balance + price
    save(station)

    notify(src, 'Jerigen dibeli.', 'success')
end)

-- manajemen ---------------------------------------------------------------

local viewers = {}

local function logBalance(station, kind, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return end

    MySQL.insert('INSERT INTO sm_fuel_logs (station, type, amount) VALUES (?, ?, ?)', {
        station.id, kind, amount
    })
end

function roleAccess(station, roleid)
    local roles = management.default_setting.roles or {}

    for i = 1, #roles do
        if roles[i].roleid == roleid then return roles[i].access end
    end

    local row = MySQL.single.await('SELECT access FROM sm_fuel_role_defs WHERE station = ? AND roleid = ?', {
        station.id, roleid
    })

    if not row then return nil end

    local ok, decoded = pcall(json.decode, row.access or '{}')
    if not ok or type(decoded) ~= 'table' then return {} end

    return decoded
end

local function roleList(station)
    local base = management.default_setting.roles or {}
    local defs = MySQL.query.await('SELECT roleid, access FROM sm_fuel_role_defs WHERE station = ?', {
        station.id
    }) or {}

    local roles = {}

    for i = 1, #base do
        roles[#roles + 1] = { roleid = base[i].roleid, access = base[i].access }
    end

    for i = 1, #defs do
        local ok, decoded = pcall(json.decode, defs[i].access or '{}')
        roles[#roles + 1] = { roleid = defs[i].roleid, access = ok and decoded or {} }
    end

    return roles
end

local function managePayload(station)
    local rows = MySQL.query.await('SELECT citizenid, roleid, mission_complete FROM sm_fuel_roles WHERE station = ?', {
        station.id
    }) or {}

    local employee = {}

    for i = 1, #rows do
        local row = rows[i]
        local other = QBCore.Functions.GetPlayerByCitizenId(row.citizenid)
        local info = other and other.PlayerData.charinfo
        local name = info and ('%s %s'):format(info.firstname, info.lastname) or row.citizenid

        employee[#employee + 1] = {
            name = name,
            citizenid = row.citizenid,
            mission_complete = tonumber(row.mission_complete) or 0,
            role = row.roleid
        }
    end

    local logs = MySQL.query.await('SELECT type, amount, date FROM sm_fuel_logs WHERE station = ? ORDER BY date DESC LIMIT 100', {
        station.id
    }) or {}

    return {
        stationid = station.id,
        balance = station.balance,
        fuel = station.fuel,
        employee = employee,
        balance_logs = logs,
        price_setting = PRICE,
        setting = {
            label = station.label,
            status = station.status,
            price = {
                refuel = station.price_refuel,
                charger = station.price_charger,
                jerrycan = station.price_jerrycan
            },
            roles = roleList(station)
        }
    }
end

local function pushManage(station)
    local list = viewers[station.id]
    if not list then return end

    local payload = managePayload(station)
    for src in pairs(list) do
        TriggerClientEvent('fuelsystem:syncManagementData', src, payload)
    end
end

local function openManage(src, stationid)
    local station = stationOf(stationid)
    if not station then return nil end

    local player = ply(src)
    if not player then return nil end

    local row = MySQL.single.await('SELECT roleid FROM sm_fuel_roles WHERE station = ? AND citizenid = ?', {
        station.id, player.PlayerData.citizenid
    })

    if not row and not IsPlayerAceAllowed(src, 'admin') then
        notify(src, 'Kamu bukan pengelola pom ini.', 'error')
        return nil
    end

    viewers[station.id] = viewers[station.id] or {}
    viewers[station.id][src] = true

    return managePayload(station)
end

lib.callback.register('fuelsystem:getmdata', function(src, stationid)
    return openManage(src, stationid)
end)

lib.callback.register('fuelsystem:openManage', function(src, stationid)
    return openManage(src, stationid)
end)

RegisterNetEvent('fuelsystem:closeManage', function(stationid)
    local list = viewers[stationid]
    if list then list[source] = nil end
end)

local function manage(src, stationid, key, fn)
    local station = stationOf(stationid)
    if not station then return false end

    if not access(src, station, key) then
        notify(src, 'Akses ditolak.', 'error')
        return false
    end

    fn(station)
    save(station)
    pushManage(station)

    return true
end

lib.callback.register('fuelsystem:updateLabel', function(src, data)
    local stationid, label = data.stationId, data.label

    local ok = manage(src, stationid, 'setting_label', function(station)
        station.label = tostring(label or station.label):sub(1, 64)
    end)

    local station = stationOf(stationid)
    if ok and station then
        TriggerClientEvent('fuelsystem:updateManagementLabel', -1, station.id, station.label)
    end
end)

lib.callback.register('fuelsystem:updatePrice', function(src, data)
    local stationid, price = data.stationId, data.price
    if type(price) ~= 'table' then return end

    manage(src, stationid, 'setting_price', function(station)
        local function clamp(kind, value, current)
            local bounds = PRICE[kind]
            value = tonumber(value)
            if not bounds or not value then return current end
            return math.max(bounds.min, math.min(bounds.max, math.floor(value)))
        end

        station.price_refuel = clamp('refuel', price.refuel, station.price_refuel)
        station.price_charger = clamp('charger', price.charger, station.price_charger)
        station.price_jerrycan = clamp('jerrycan', price.jerrycan, station.price_jerrycan)
    end)
end)

lib.callback.register('fuelsystem:toggleStatus', function(src, data)
    local stationid, status = data.stationId, data.status

    manage(src, stationid, 'setting_label', function(station)
        station.status = status == 'open' and 'open' or 'closed'
        notify(src, 'Status pom: ' .. station.status, 'success')
    end)
end)

lib.callback.register('fuelsystem:withdraw', function(src, data)
    local stationid, amount = data.stationId, math.floor(tonumber(data.amount) or 0)

    manage(src, stationid, 'withdraw', function(station)
        if amount <= 0 or station.balance < amount then
            return notify(src, 'Saldo kas tidak cukup.', 'error')
        end

        local player = ply(src)
        station.balance = station.balance - amount
        logBalance(station, 'expense', amount)
        player.Functions.AddMoney('cash', amount, 'fuel-withdraw')
    end)
end)

lib.callback.register('fuelsystem:deposit', function(src, data)
    local stationid, amount = data.stationId, math.floor(tonumber(data.amount) or 0)

    manage(src, stationid, 'deposit', function(station)
        local player = ply(src)
        if amount <= 0 or (player.PlayerData.money.cash or 0) < amount then
            return notify(src, 'Uang tidak cukup.', 'error')
        end

        player.Functions.RemoveMoney('cash', amount, 'fuel-deposit')
        station.balance = station.balance + amount
        logBalance(station, 'income', amount)
    end)
end)

lib.callback.register('fuelsystem:hireEmployee', function(src, data)
    local stationid, target = data.stationId, tonumber(data.playerId)
    local created

    local ok = manage(src, stationid, 'hire_emp', function(station)
        local other = target and ply(target)
        if not other then return notify(src, 'Pemain tidak ditemukan.', 'error') end

        local count = MySQL.scalar.await('SELECT COUNT(*) FROM sm_fuel_roles WHERE station = ?', { station.id }) or 0
        if count >= MAX_EMPLOYEE then return notify(src, 'Karyawan penuh.', 'error') end

        MySQL.insert.await([[
            INSERT INTO sm_fuel_roles (station, citizenid, roleid) VALUES (?, ?, 'employee')
            ON DUPLICATE KEY UPDATE roleid = 'employee'
        ]], { station.id, other.PlayerData.citizenid })

        local info = other.PlayerData.charinfo
        created = {
            name = info and ('%s %s'):format(info.firstname, info.lastname) or other.PlayerData.citizenid,
            citizenid = other.PlayerData.citizenid,
            mission_complete = 0,
            role = 'employee'
        }

        TriggerClientEvent('fuelsystem:loadStation', target, { stationid = station.id, setting = { label = station.label } })
        notify(src, 'Karyawan ditambahkan.', 'success')
    end)

    return { success = ok and created ~= nil, employee = created }
end)

lib.callback.register('fuelsystem:fireEmployee', function(src, data)
    local stationid, citizenid = data.stationId, data.citizenid

    manage(src, stationid, 'fire_emp', function(station)
        MySQL.update.await('DELETE FROM sm_fuel_roles WHERE station = ? AND citizenid = ?', {
            station.id, citizenid
        })

        for _, id in ipairs(GetPlayers()) do
            local other = ply(tonumber(id))
            if other and other.PlayerData.citizenid == citizenid then
                TriggerClientEvent('fuelsystem:removeStation', other.PlayerData.source, station.id)
                break
            end
        end

        notify(src, 'Karyawan dikeluarkan.', 'success')
    end)
end)

lib.callback.register('fuelsystem:setRole', function(src, data)
    local stationid, citizenid, roleid = data.stationId, data.citizenid, data.roleid

    manage(src, stationid, 'hire_emp', function(station)
        MySQL.update.await('UPDATE sm_fuel_roles SET roleid = ? WHERE station = ? AND citizenid = ?', {
            roleid, station.id, citizenid
        })
    end)
end)

lib.callback.register('fuelsystem:addRole', function(src, data)
    local stationid, roleid = data.stationId, data.roleid
    if type(roleid) ~= 'string' or roleid == '' then return end

    manage(src, stationid, 'hire_emp', function(station)
        MySQL.insert.await([[
            INSERT INTO sm_fuel_role_defs (station, roleid, access) VALUES (?, ?, '{}')
            ON DUPLICATE KEY UPDATE roleid = roleid
        ]], { station.id, roleid:sub(1, 16) })
    end)
end)

lib.callback.register('fuelsystem:updateRoleAccess', function(src, data)
    local stationid, roleid, map = data.stationId, data.roleid, data.access
    if type(map) ~= 'table' then return end

    local allowed = {}
    local keys = { 'withdraw', 'deposit', 'hire_emp', 'fire_emp', 'setting_label', 'setting_price' }

    for i = 1, #keys do
        allowed[keys[i]] = map[keys[i]] == true
    end

    manage(src, stationid, 'hire_emp', function(station)
        MySQL.insert.await([[
            INSERT INTO sm_fuel_role_defs (station, roleid, access) VALUES (?, ?, ?)
            ON DUPLICATE KEY UPDATE access = VALUES(access)
        ]], { station.id, roleid:sub(1, 16), json.encode(allowed) })
    end)
end)

lib.callback.register('fuelsystem:deleteRole', function(src, data)
    local stationid, roleid = data.stationId, data.roleid

    manage(src, stationid, 'hire_emp', function(station)
        MySQL.update.await('DELETE FROM sm_fuel_role_defs WHERE station = ? AND roleid = ?', {
            station.id, roleid
        })

        MySQL.update.await('UPDATE sm_fuel_roles SET roleid = \'employee\' WHERE station = ? AND roleid = ?', {
            station.id, roleid
        })
    end)
end)

lib.callback.register('fuelsystem:getNearbyPlayers', function(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return { players = {} } end

    local coords = GetEntityCoords(ped)
    local players = {}

    for _, id in ipairs(GetPlayers()) do
        local sid = tonumber(id)
        if sid ~= src then
            local otherPed = GetPlayerPed(sid)
            if otherPed and otherPed ~= 0 and #(GetEntityCoords(otherPed) - coords) <= 5.0 then
                players[#players + 1] = {
                    value = tostring(sid),
                    label = ('Player (%d)'):format(sid)
                }
            end
        end
    end

    return { players = players }
end)

local function setupManagement(src)
    local player = ply(src)
    if not player then return end

    local rows = MySQL.query.await('SELECT station FROM sm_fuel_roles WHERE citizenid = ?', {
        player.PlayerData.citizenid
    }) or {}

    local payload = {}

    if #rows == 0 then
        if not IsPlayerAceAllowed(src, 'admin') then return end

        for i = 1, #(config.location or {}) do
            local station = config.location[i]
            payload[station.id] = { setting = { label = 'Pom Bensin' } }
        end
    else
        for i = 1, #rows do
            local station = stationOf(rows[i].station)
            if station then
                payload[station.id] = { setting = { label = station.label } }
            end
        end
    end

    TriggerClientEvent('fuelsystem:setupmanagement', src, payload)
end

AddEventHandler('QBCore:Server:PlayerLoaded', function(player)
    setupManagement(player.PlayerData.source)
end)

-- misi pengiriman ----------------------------------------------------------

local missions = {}
local missionCooldown = {}
local missionRate = {}

local TRUCK_RADIUS = 25.0
local STATION_RADIUS = 60.0

local function stationAnchor(station)
    local anchor = station.vehcoords or station.chargercoords
    if not anchor then return nil end
    return vec3(anchor.x, anchor.y, anchor.z)
end

local function nearestStation(coords, radius)
    local best, bestDistance

    for i = 1, #(config.location or {}) do
        local station = config.location[i]
        local anchor = stationAnchor(station)

        if anchor then
            local distance = #(coords - anchor)
            if distance <= radius and (not bestDistance or distance < bestDistance) then
                best, bestDistance = station, distance
            end
        end
    end

    return best
end

local function vehiclePool()
    local ok, list = pcall(GetAllVehicles)
    if ok and type(list) == 'table' then return list end

    local ok2, list2 = pcall(function() return GetGamePool('CVehicle') end)
    if ok2 and type(list2) == 'table' then return list2 end

    return {}
end

local function ownsVehicle(veh, citizenid, station)
    if not DoesEntityExist(veh) then return false end

    local state = Entity(veh).state
    if state.fuel_owner ~= citizenid then return false end
    if station and state.fuel_station ~= station then return false end

    return true
end

local function missionVehicles(citizenid, station)
    local found = {}

    for _, veh in pairs(vehiclePool()) do
        if ownsVehicle(veh, citizenid, station) then
            found[#found + 1] = veh
        end
    end

    return found
end

local function deleteMissionVehicles(citizenid, station)
    local list = missionVehicles(citizenid, station)

    for i = 1, #list do
        SetEntityAsMissionEntity(list[i], true, true)
        DeleteEntity(list[i])
    end

    return #list
end

local function clearMission(src, message, kind)
    local mission = missions[src]
    missions[src] = nil
    missionRate[src] = nil

    TriggerClientEvent('fuelsystem:resetMission', src)
    if message then notify(src, message, kind or 'inform') end

    return mission
end

local function missionTimeout()
    return (MISSION.delivery_timeout or 30) * 60
end

lib.callback.register('fuelsystem:startMission', function(src, data)
    local player = ply(src)
    if not player then return false end

    local citizenid = player.PlayerData.citizenid
    local current = missions[src]

    if current then
        if os.time() <= current.expires then
            notify(src, 'Kamu masih punya misi pengiriman yang berjalan.', 'error')
            return false
        end

        clearMission(src)
        deleteMissionVehicles(citizenid, current.station)
    end

    local cooldown = missionCooldown[citizenid]
    if cooldown and cooldown > os.time() then
        notify(src, ('Tunggu %d detik sebelum mengambil misi lagi.'):format(cooldown - os.time()), 'error')
        return false
    end

    local coords = GetEntityCoords(GetPlayerPed(src))
    local station = nearestStation(coords, 80)

    if not station then
        notify(src, 'Kamu tidak berada di pom bensin.', 'error')
        return false
    end

    if data and data.stationId and data.stationId ~= station.id then
        notify(src, 'Pom tidak cocok dengan posisimu.', 'error')
        return false
    end

    if not station.vehcoords then
        notify(src, 'Pom ini tidak punya titik keluar kendaraan.', 'error')
        return false
    end

    local record = stationOf(station.id)
    if record and record.status ~= 'open' then
        notify(src, 'Pom ini sedang tutup.', 'error')
        return false
    end

    deleteMissionVehicles(citizenid, station.id)

    missions[src] = {
        station = station.id,
        citizenid = citizenid,
        fuelOrder = math.max(0, math.floor(tonumber(data and data.fuelOrder) or 0)),
        expires = os.time() + missionTimeout()
    }

    local started = lib.callback.await('fuelsystem:startMission', src)
    if not started then
        missions[src] = nil
        return false
    end

    return true
end)

RegisterNetEvent('fuelsystem:finishMission', function()
    local src = source

    local now = GetGameTimer()
    if missionRate[src] and now - missionRate[src] < 1500 then return end
    missionRate[src] = now

    local player = ply(src)
    if not player then return end

    local citizenid = player.PlayerData.citizenid
    local mission = missions[src]

    if not mission then
        notify(src, 'Tidak ada misi pengiriman aktif.', 'error')
        return
    end

    if os.time() > mission.expires then
        clearMission(src, 'Misi sudah kedaluwarsa.', 'error')
        deleteMissionVehicles(citizenid, mission.station)
        return
    end

    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return end

    local coords = GetEntityCoords(ped)
    local vehicle = GetVehiclePedIsIn(ped, false)

    if vehicle == 0 then
        for _, veh in pairs(vehiclePool()) do
            if DoesEntityExist(veh)
                and Entity(veh).state.fuel_station == mission.station
                and #(GetEntityCoords(veh) - coords) < TRUCK_RADIUS then
                local owner = Entity(veh).state.fuel_owner
                if owner == nil or owner == citizenid then
                    vehicle = veh
                    break
                end
            end
        end
    end

    if vehicle == 0 then
        notify(src, 'Truk pengiriman tidak ada di dekatmu.', 'error')
        return
    end

    local owner = Entity(vehicle).state.fuel_owner
    if owner ~= nil and owner ~= citizenid then
        notify(src, 'Truk ini bukan misi milikmu.', 'error')
        return
    end

    if Entity(vehicle).state.fuel_station ~= mission.station then
        notify(src, 'Truk ini bukan untuk pom ini.', 'error')
        return
    end

    local hasTrailer, trailer = GetVehicleTrailerVehicle(vehicle)
    if not hasTrailer or not trailer or trailer == 0 then
        notify(src, 'Truk tidak menarik tanki minyak.', 'error')
        return
    end

    if Entity(trailer).state.fuel_station ~= mission.station then
        notify(src, 'Tanki ini bukan untuk pom ini.', 'error')
        return
    end

    local station = array.find(config.location, function(entry)
        return entry.id == mission.station
    end)

    local anchor = station and stationAnchor(station)
    if not anchor then
        clearMission(src, 'Pom tujuan tidak ditemukan.', 'error')
        deleteMissionVehicles(citizenid, mission.station)
        return
    end

    if #(GetEntityCoords(vehicle) - anchor) > STATION_RADIUS then
        notify(src, 'Kamu belum sampai di pom tujuan.', 'error')
        return
    end

    local pay = (MISSION.fuel_price or 250) + (math.floor(mission.fuelOrder / 10) * 10)
    player.Functions.AddMoney('cash', pay, 'fuel-mission')

    MySQL.update('UPDATE sm_fuel_roles SET mission_complete = mission_complete + 1 WHERE station = ? AND citizenid = ?', {
        mission.station, citizenid
    })

    missionCooldown[citizenid] = os.time() + ((MISSION.delivery_cooldown or 2) * 60)

    local record = stationOf(mission.station)
    if record then
        record.fuel = 100
        MySQL.update('UPDATE sm_fuel_stations SET fuel = 100 WHERE id = ?', { record.id })
        pushManage(record)
    end

    clearMission(src)
    deleteMissionVehicles(citizenid, mission.station)

    notify(src, ('Pengiriman selesai, upah $%s.'):format(pay), 'success')
end)

RegisterNetEvent('fuelsystem:forceEnd', function()
    local src = source
    local mission = missions[src]
    if not mission then return end

    local player = ply(src)
    clearMission(src)

    if not player then return end

    local citizenid = player.PlayerData.citizenid
    deleteMissionVehicles(citizenid, mission.station)
    missionCooldown[citizenid] = os.time() + 60
end)

AddEventHandler('playerDropped', function()
    local src = source
    local mission = missions[src]

    missions[src] = nil
    missionRate[src] = nil

    for _, list in pairs(viewers) do list[src] = nil end

    if not mission then return end

    local player = ply(src)
    if not player then return end

    deleteMissionVehicles(player.PlayerData.citizenid, mission.station)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    for _, mission in pairs(missions) do
        deleteMissionVehicles(mission.citizenid, mission.station)
    end
end)

CreateThread(function()
    while true do
        Wait(30000)

        local now = os.time()
        for src, mission in pairs(missions) do
            if now > mission.expires then
                clearMission(src, 'Misi pengiriman kedaluwarsa, truk ditarik.', 'error')
                deleteMissionVehicles(mission.citizenid, mission.station)
            end
        end
    end
end)

CreateThread(function()
    for stmt in string.gmatch(SCHEMA, '([^;]+)') do
        local s = stmt:gsub('^%s+', ''):gsub('%s+$', '')
        if s ~= '' then MySQL.query.await(s) end
    end

    pcall(function()
        MySQL.query.await('ALTER TABLE sm_fuel_roles ADD COLUMN mission_complete INT NOT NULL DEFAULT 0')
    end)

    local rows = MySQL.query.await('SELECT * FROM sm_fuel_stations') or {}

    for i = 1, #rows do
        local row = rows[i]
        stations[row.id] = {
            id = row.id,
            label = row.label,
            status = row.status,
            fuel = tonumber(row.fuel) or 100,
            price_refuel = tonumber(row.price_refuel) or 400,
            price_charger = tonumber(row.price_charger) or 350,
            price_jerrycan = tonumber(row.price_jerrycan) or 10000,
            balance = tonumber(row.balance) or 0
        }
    end

    for i = 1, #(config.location or {}) do
        local station = config.location[i]
        if station.id and not stations[station.id] then
            stations[station.id] = {
                id = station.id,
                label = 'Pom Bensin',
                status = 'open',
                fuel = 100,
                price_refuel = 400,
                price_charger = 350,
                price_jerrycan = 10000,
                balance = 0
            }

            MySQL.insert.await('INSERT INTO sm_fuel_stations (id) VALUES (?)', { station.id })
        end
    end

    local total = 0
    for _ in pairs(stations) do total = total + 1 end
    print(('^2[fuelsystem] %d pom dimuat^7'):format(total))

    for _, id in ipairs(GetPlayers()) do
        setupManagement(tonumber(id))
    end
end)
