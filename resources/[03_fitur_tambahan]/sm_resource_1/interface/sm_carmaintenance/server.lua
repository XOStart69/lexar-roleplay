--[[
    sm_carmaintenance :: server
    Health per plat di DB. Otoritas: zona, job, grade, kelas, kategori, item, jarak.
]]

local config = localmodule 'config'

local Parts = config.Parts or {}
local Order = config.PartOrder or {}
local Zones = config.Zones or {}
local Jobs = config.Jobs or {}
local AdminGroups = config.AdminGroups or { 'admin', 'god' }
local Blocked = {}
local Allowed = {}

for i = 1, #(config.BlockedCategories or {}) do Blocked[config.BlockedCategories[i]] = true end
for i = 1, #(config.AllowedClasses or {}) do Allowed[config.AllowedClasses[i]] = true end
local REPAIR_DISTANCE = config.RepairDistance or 8.0
local ZONE_RADIUS = config.ZoneRadius or 12.0
local DEFAULT_HEALTH = 100.0

local TABLE = 'sm_carmaint_parts'

local function playerOf(src)
    return qb_ecore:GetPlayer(src)
end

local function isAdmin(player)
    for i = 1, #AdminGroups do
        if qb_ecore:HasPermission(player.PlayerData.source, AdminGroups[i]) then return true end
    end
    return false
end

local function vehicleOf(netId)
    local entity = NetworkGetEntityFromNetworkId(tonumber(netId) or 0)
    if entity == 0 or not DoesEntityExist(entity) then return nil end
    if GetEntityType(entity) ~= 2 then return nil end
    return entity
end

local function plateOf(entity)
    local plate = GetVehicleNumberPlateText(entity)
    if not plate then return nil end
    plate = plate:gsub('%s+$', '')
    if plate == '' then return nil end
    return plate
end

local function insideArea(coords, area)
    local points = area.points or {}
    if #points < 3 then return false end

    local thickness = area.thickness or 8.0
    local base = area.z or points[1].z or coords.z
    if math.abs(coords.z - base) > thickness then return false end

    local hit = false
    local j = #points

    for i = 1, #points do
        local a, b = points[i], points[j]
        if ((a.y > coords.y) ~= (b.y > coords.y)) then
            local cross = (b.x - a.x) * (coords.y - a.y) / ((b.y - a.y) == 0 and 1e-9 or (b.y - a.y)) + a.x
            if coords.x < cross then hit = not hit end
        end
        j = i
    end

    return hit
end

local function zoneFor(player, coords)
    if isAdmin(player) then return true end

    for i = 1, #Zones do
        local zone = Zones[i]
        if Jobs[zone.job] or zone.job == player.PlayerData.job.name then
            if (player.PlayerData.job.grade.level or 0) >= (zone.grade or 0) then
                for k = 1, #(zone.areas or {}) do
                    if insideArea(coords, zone.areas[k]) then return true end
                end
            end
        end
    end

    return false
end

local function ensureRow(plate)
    local row = MySQL.single.await('SELECT * FROM ' .. TABLE .. ' WHERE plate = ?', { plate })
    if row then return row end

    local blank = {}
    for i = 1, #Order do blank[Order[i]] = DEFAULT_HEALTH end

    MySQL.insert(
        ('INSERT INTO %s (plate, %s, updated) VALUES (?, %s, ?)'):format(
            TABLE, table.concat(Order, ', '), ('?'):rep(#Order):gsub('', '')
        ),
        { plate, table.unpack((function() local t = {} for i = 1, #Order do t[i] = DEFAULT_HEALTH end return t end)()), os.time() }
    )

    return blank
end

local function partsOf(row)
    local out = {}
    for i = 1, #Order do out[Order[i]] = tonumber(row[Order[i]]) or DEFAULT_HEALTH end
    return out
end

lib.callback.register('sm_carmaintenance:load', function(src, plate, netId)
    local entity = vehicleOf(netId)
    if not entity then return {} end

    plate = plateOf(entity) or tostring(plate or '')
    if plate == '' then return {} end

    return partsOf(ensureRow(plate))
end)

lib.callback.register('sm_carmaintenance:sync', function(src, plate, parts, netId)
    local entity = vehicleOf(netId)
    plate = (entity and plateOf(entity)) or tostring(plate or '')
    if plate == '' or type(parts) ~= 'table' then return false end

    local row = ensureRow(plate)
    if not row then return false end

    local sets, args = {}, {}

    for i = 1, #Order do
        local name = Order[i]
        local value = math.min(math.max(tonumber(parts[name]) or DEFAULT_HEALTH, 0.0), DEFAULT_HEALTH)

        sets[#sets + 1] = ('%s = ?'):format(name)
        args[#args + 1] = value
    end

    args[#args + 1] = os.time()
    args[#args + 1] = plate

    MySQL.update(('UPDATE %s SET %s, updated = ? WHERE plate = ?'):format(TABLE, table.concat(sets, ', ')), args)

    return true
end)

local function canRepairLocal(src, plate, part, netId)
    local player = playerOf(src)
    if not player then return false, 'Data pemain tidak siap.' end

    local entity = vehicleOf(netId)
    if not entity then return false, 'Kendaraan tidak ditemukan.' end

    local partConfig = Parts[part]
    if not partConfig then return false, 'Part tidak dikenal.' end

    local ped = GetPlayerPed(src)
    if #(GetEntityCoords(ped) - GetEntityCoords(entity)) > REPAIR_DISTANCE then
        return false, 'Terlalu jauh dari kendaraan.'
    end

    local class = GetVehicleClass(entity)
    if not Allowed[class] then return false, 'Kelas kendaraan tidak dilayani.' end
    if Blocked[part] or Blocked[class] then return false, 'Part ini butuh alat khusus.' end

    if not zoneFor(player, GetEntityCoords(ped)) then return false, 'Bukan di area servis.' end

    local plateNow = plateOf(entity)
    if not plateNow then return false, 'Plat tidak terbaca.' end

    local row = ensureRow(plateNow)
    local health = tonumber(row[part]) or DEFAULT_HEALTH
    if health > (partConfig.threshold or 50.0) then return false, 'Part masih bagus.' end

    if (ox_inventory:GetItemCount(src, partConfig.item) or 0) < (partConfig.amount or 1) then
        return false, ('Butuh %s.'):format(partConfig.item)
    end

    return true
end

lib.callback.register('sm_carmaintenance:canRepair', function(src, plate, part, netId)
    return canRepairLocal(src, plate, part, netId)
end)

lib.callback.register('sm_carmaintenance:repair', function(src, plate, part, netId)
    local ok, reason = canRepairLocal(src, plate, part, netId)
    if not ok then return false, reason end

    local player = playerOf(src)
    local entity = vehicleOf(netId)
    if not player or not entity then return false, 'Kendaraan tidak ditemukan.' end

    local partConfig = Parts[part]
    local plateNow = plateOf(entity)
    if not plateNow then return false, 'Plat tidak terbaca.' end

    if not ox_inventory:RemoveItem(src, partConfig.item, partConfig.amount or 1) then
        return false, 'Gagal mengambil part.'
    end

    MySQL.update(('UPDATE %s SET %s = ? WHERE plate = ?'):format(TABLE, part), { DEFAULT_HEALTH, plateNow })

    local parts = partsOf(ensureRow(plateNow))

    for _, raw in ipairs(GetPlayers()) do
        local target = tonumber(raw)
        TriggerClientEvent('sm_carmaintenance:forceRefresh', target, plateNow, parts)
    end

    return true, ('%s diperbaiki.'):format(partConfig.label or part)
end)

lib.callback.register('sm_carmaintenance:release', function(src, plate, pending, netId)
    return true
end)

CreateThread(function()
    MySQL.query.await(([[
    CREATE TABLE IF NOT EXISTS `%s` (
        `plate` varchar(16) NOT NULL,
        %s
        `updated` int(11) NOT NULL,
        PRIMARY KEY (`plate`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]]):format(TABLE, (function()
        local cols = {}
        for i = 1, #Order do cols[#cols + 1] = ('`%s` double NOT NULL DEFAULT 100'):format(Order[i]) end
        return table.concat(cols, ',\n        ') .. ',\n'
    end)()))
end)

print('^2[sm_carmaintenance] server siap^7')