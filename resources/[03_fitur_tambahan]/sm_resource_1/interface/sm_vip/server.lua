--[[
    sm_vip :: server
    Masa aktif disimpan dalam milidetik absolut. Klaim kendaraan & TV remote sekali per periode,
    item harian reset per hari. Semua timestamp di server.
]]

local Config = localmodule 'config'

local PLAYERS = 'sm_vip_players'
local HISTORY = 'sm_vip_history'

local ADMIN_GROUPS = Config.AdminGroups or { 'god', 'admin' }
local TYPES = Config.VipTypes or {}
local VEHICLES = Config.VipVehicles or {}
local DAILY = Config.DailyItems or {}
local TV = Config.TVRemote or {}

local SCHEMA = {
    ([[
    CREATE TABLE IF NOT EXISTS `%s` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `citizenid` varchar(64) NOT NULL,
        `vip_type` varchar(48) NOT NULL,
        `started_at` bigint(20) NOT NULL,
        `expired_at` bigint(20) NOT NULL,
        `vehicle_claimed` tinyint(1) NOT NULL DEFAULT 0,
        `tv_claimed` tinyint(1) NOT NULL DEFAULT 0,
        `daily_stamp` varchar(10) DEFAULT NULL,
        `granted_by` varchar(64) DEFAULT NULL,
        PRIMARY KEY (`id`),
        UNIQUE KEY `citizenid` (`citizenid`),
        KEY `expired` (`expired_at`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]]):format(PLAYERS),

    ([[
    CREATE TABLE IF NOT EXISTS `%s` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `citizenid` varchar(64) NOT NULL,
        `vip_type` varchar(48) DEFAULT NULL,
        `action` varchar(32) NOT NULL,
        `actor` varchar(64) DEFAULT NULL,
        `detail` text DEFAULT NULL,
        `stamp` bigint(20) NOT NULL,
        PRIMARY KEY (`id`),
        KEY `citizenid` (`citizenid`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]]):format(HISTORY),
}

local function ms()
    return math.floor(os.time() * 1000)
end

local function today()
    return os.date('%Y-%m-%d')
end

local function isAdmin(src)
    for i = 1, #ADMIN_GROUPS do
        if qb_ecore:HasPermission(src, ADMIN_GROUPS[i]) then return true end
    end
    return false
end

local function actorName(player)
    if not player then return 'system' end
    return player.PlayerData.citizenid
end

local function log(citizenid, action, actor, vipType, detail)
    MySQL.insert('INSERT INTO ' .. HISTORY .. ' (citizenid, vip_type, action, actor, detail, stamp) VALUES (?, ?, ?, ?, ?, ?)', {
        citizenid, vipType, action, actor, detail, ms(),
    })
end

local function byCitizen(citizenid)
    for _, raw in ipairs(GetPlayers()) do
        local player = qb_ecore:GetPlayer(tonumber(raw))
        if player and player.PlayerData.citizenid == citizenid then return player, tonumber(raw) end
    end
end

local function timeLeft(expiredAt)
    local diff = math.floor(((tonumber(expiredAt) or 0) - ms()) / 1000)
    if diff <= 0 then return 'Kedaluwarsa' end

    local days = math.floor(diff / 86400)
    local hours = math.floor((diff % 86400) / 3600)
    local minutes = math.floor((diff % 3600) / 60)

    if days > 0 then return ('%d hari %d jam'):format(days, hours) end
    if hours > 0 then return ('%d jam %d menit'):format(hours, minutes) end
    return ('%d menit'):format(minutes)
end

local function activeRow(citizenid)
    local row = MySQL.single.await('SELECT * FROM ' .. PLAYERS .. ' WHERE citizenid = ?', { citizenid })
    if not row then return nil end
    if tonumber(row.expired_at) <= ms() then return nil end
    return row
end

lib.callback.register('sm_vip:server:getPlayerVipStatus', function(src)
    local player = qb_ecore:GetPlayer(src)
    if not player then return nil end

    local row = activeRow(player.PlayerData.citizenid)
    if not row then return nil end

    return { vip_type = row.vip_type, timeLeft = timeLeft(row.expired_at), expired_at = row.expired_at }
end)

lib.callback.register('sm_vip:server:getVehicleClaimStatus', function(src)
    local player = qb_ecore:GetPlayer(src)
    if not player then return { hasClaimed = true } end

    local row = activeRow(player.PlayerData.citizenid)
    if not row then return { hasClaimed = true } end

    return { hasClaimed = tonumber(row.vehicle_claimed) == 1 }
end)

lib.callback.register('sm_vip:server:getTVRemoteClaimStatus', function(src)
    local player = qb_ecore:GetPlayer(src)
    if not player then return { hasClaimed = true } end

    local row = activeRow(player.PlayerData.citizenid)
    if not row then return { hasClaimed = true } end

    return { hasClaimed = tonumber(row.tv_claimed) == 1 }
end)

lib.callback.register('sm_vip:server:getDailyItemStatus', function(src)
    local player = qb_ecore:GetPlayer(src)
    if not player then return { canClaim = false } end

    local row = activeRow(player.PlayerData.citizenid)
    if not row then return { canClaim = false } end

    return { canClaim = row.daily_stamp ~= today() }
end)

RegisterNetEvent('sm_vip:server:claimVehicle', function()
    local src = source
    local player = qb_ecore:GetPlayer(src)
    if not player then return end

    local row = activeRow(player.PlayerData.citizenid)
    if not row then return end
    if tonumber(row.vehicle_claimed) == 1 then return end

    local pool = VEHICLES[row.vip_type]
    local list = pool and pool.vehicles
    if not list or #list == 0 then return end

    local model = list[math.random(#list)]
    local coords = GetEntityCoords(GetPlayerPed(src))
    local heading = GetEntityHeading(GetPlayerPed(src))

    local vehicle = CreateVehicle(GetHashKey(model), coords.x + 2.0, coords.y, coords.z, heading, true)
    if vehicle == 0 then return end

    local plate = ('VIP%05d'):format(math.random(0, 99999))
    SetVehicleNumberPlateText(vehicle, plate)
    SetVehicleFuelLevel(vehicle, 100.0)
    SetVehicleDirtLevel(vehicle, 0.0)

    if GetResourceState('qb-vehiclekeys') == 'started' then
        TriggerEvent('qb-vehiclekeys:server:SetKeys', plate)
    end

    MySQL.update('UPDATE ' .. PLAYERS .. ' SET vehicle_claimed = 1 WHERE id = ?', { row.id })
    log(player.PlayerData.citizenid, 'claim_vehicle', player.PlayerData.citizenid, row.vip_type, model)

    TriggerClientEvent('ox_lib:notify', src, { description = ('Kendaraan %s dikirim.'):format(model), type = 'success' })
end)

RegisterNetEvent('sm_vip:server:claimTVRemote', function()
    local src = source
    local player = qb_ecore:GetPlayer(src)
    if not player then return end

    local row = activeRow(player.PlayerData.citizenid)
    if not row then return end
    if tonumber(row.tv_claimed) == 1 then return end

    local item = TV.item or 'tv_remote'
    if not ox_inventory:AddItem(src, item, 1) then return end

    MySQL.update('UPDATE ' .. PLAYERS .. ' SET tv_claimed = 1 WHERE id = ?', { row.id })
    log(player.PlayerData.citizenid, 'claim_tv', player.PlayerData.citizenid, row.vip_type, item)

    TriggerClientEvent('ox_lib:notify', src, { description = 'TV remote dikirim.', type = 'success' })
end)

RegisterNetEvent('sm_vip:server:claimDailyItem', function()
    local src = source
    local player = qb_ecore:GetPlayer(src)
    if not player then return end

    local row = activeRow(player.PlayerData.citizenid)
    if not row then return end
    if row.daily_stamp == today() then return end

    local given = {}

    for i = 1, #DAILY do
        local entry = DAILY[i]
        if entry and entry.item then
            local amount = tonumber(entry.amount) or 1
            if ox_inventory:AddItem(src, entry.item, amount) then
                given[#given + 1] = ('%s x%d'):format(entry.item, amount)
            end
        end
    end

    if #given == 0 then return end

    MySQL.update('UPDATE ' .. PLAYERS .. ' SET daily_stamp = ? WHERE id = ?', { today(), row.id })
    log(player.PlayerData.citizenid, 'claim_daily', player.PlayerData.citizenid, row.vip_type, table.concat(given, ', '))

    TriggerClientEvent('ox_lib:notify', src, { description = 'Item harian diterima.', type = 'success' })
end)

lib.callback.register('sm_vip:server:searchPlayer', function(src, query)
    if not isAdmin(src) then return {} end

    query = tostring(query or ''):sub(1, 48)
    if query == '' then return {} end

    local like = '%' .. query .. '%'

    return MySQL.query.await(
        'SELECT citizenid, firstname, lastname FROM players WHERE citizenid LIKE ? OR CONCAT(firstname, " ", lastname) LIKE ? LIMIT 10',
        { like, like }
    ) or {}
end)

lib.callback.register('sm_vip:server:getVipPlayers', function(src)
    if not isAdmin(src) then return {} end

    local rows = MySQL.query.await(
        'SELECT v.id, v.citizenid, v.vip_type, v.expired_at, p.firstname, p.lastname FROM ' .. PLAYERS .. ' v LEFT JOIN players p ON p.citizenid = v.citizenid ORDER BY v.expired_at DESC LIMIT 100'
    ) or {}

    for i = 1, #rows do
        local row = rows[i]
        row.display_name = ('%s %s'):format(row.firstname or '-', row.lastname or ''):gsub('^%s+', '')
        row.expired_at = tonumber(row.expired_at)
        row.timeLeft = timeLeft(row.expired_at)
        row.firstname = nil
        row.lastname = nil
    end

    return rows
end)

lib.callback.register('sm_vip:server:getVipHistory', function(src)
    if not isAdmin(src) then return {} end

    return MySQL.query.await('SELECT * FROM ' .. HISTORY .. ' ORDER BY id DESC LIMIT 100') or {}
end)

lib.callback.register('sm_vip:server:addVip', function(src, data)
    if not isAdmin(src) then return { success = false, message = 'Bukan admin.' } end
    if type(data) ~= 'table' then return { success = false, message = 'Data tidak valid.' } end

    local citizenid = tostring(data.citizenid or '')
    local vipType = tostring(data.vipType or '')

    if citizenid == '' then return { success = false, message = 'Pemain kosong.' } end
    if not TYPES[vipType] then return { success = false, message = 'Tipe VIP tidak dikenal.' } end

    local player = byCitizen(citizenid)
    if not player then return { success = false, message = 'Pemain harus online.' } end

    local duration = tonumber(TYPES[vipType].duration) or (30 * 86400000)
    local started = ms()

    MySQL.insert(
        ('INSERT INTO %s (citizenid, vip_type, started_at, expired_at, vehicle_claimed, tv_claimed, daily_stamp, granted_by) VALUES (?, ?, ?, ?, 0, 0, NULL, ?) ON DUPLICATE KEY UPDATE vip_type = VALUES(vip_type), started_at = VALUES(started_at), expired_at = VALUES(expired_at), vehicle_claimed = 0, tv_claimed = 0, daily_stamp = NULL, granted_by = VALUES(granted_by)'):format(PLAYERS),
        { citizenid, vipType, started, started + duration, actorName(qb_ecore:GetPlayer(src)) }
    )

    log(citizenid, 'add', actorName(qb_ecore:GetPlayer(src)), vipType)

    return { success = true, message = 'VIP ditambahkan.' }
end)

lib.callback.register('sm_vip:server:editVip', function(src, data)
    if not isAdmin(src) then return { success = false, message = 'Bukan admin.' } end
    if type(data) ~= 'table' then return { success = false, message = 'Data tidak valid.' } end

    local id = tonumber(data.id)
    local endDate = tonumber(data.endDate)
    if not id or not endDate then return { success = false, message = 'Data tidak valid.' } end

    local row = MySQL.single.await('SELECT * FROM ' .. PLAYERS .. ' WHERE id = ?', { id })
    if not row then return { success = false, message = 'Data VIP tidak ditemukan.' } end

    MySQL.update('UPDATE ' .. PLAYERS .. ' SET expired_at = ? WHERE id = ?', { endDate, id })
    log(row.citizenid, 'edit', actorName(qb_ecore:GetPlayer(src)), row.vip_type, tostring(endDate))

    return { success = true, message = 'Masa aktif diperbarui.' }
end)

lib.callback.register('sm_vip:server:deleteVip', function(src, ids)
    if not isAdmin(src) then return { success = false, message = 'Bukan admin.' } end
    if type(ids) ~= 'table' or #ids == 0 then return { success = false, message = 'Tidak ada data.' } end

    local clean = {}
    for i = 1, #ids do
        local id = tonumber(ids[i])
        if id then clean[#clean + 1] = id end
    end

    if #clean == 0 then return { success = false, message = 'Tidak ada data.' } end

    local marks = ('?'):rep(#clean):gsub('', '')
    marks = table.concat((function() local m = {} for i = 1, #clean do m[i] = '?' end return m end)(), ',')

    local rows = MySQL.query.await('SELECT * FROM ' .. PLAYERS .. ' WHERE id IN (' .. marks .. ')', clean) or {}

    MySQL.query.await('DELETE FROM ' .. PLAYERS .. ' WHERE id IN (' .. marks .. ')', clean)

    local actor = actorName(qb_ecore:GetPlayer(src))
    for i = 1, #rows do
        log(rows[i].citizenid, 'delete', actor, rows[i].vip_type)
    end

    return { success = true, message = ('%d data dihapus.'):format(#rows) }
end)

RegisterCommand(Config.AdminCommand or 'vipmanager', function(src)
    if src == 0 then return end
    if not isAdmin(src) then return end
    TriggerClientEvent('sm_vip:client:openAdminMenu', src)
end, false)

CreateThread(function()
    MySQL.query.await(SCHEMA[1])
    MySQL.query.await(SCHEMA[2])

    while true do
        Wait(300000)
        local cut = ms()
        MySQL.update('DELETE FROM ' .. PLAYERS .. ' WHERE expired_at < ?', { cut })
    end
end)

print('^2[sm_vip] server siap^7')