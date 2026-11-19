--[[
    voucherdonasi :: server
    Otoritas kepemilikan, format plat, keunikan plat, pemetaan plat palsu, konsumsi item.
]]

local config = localmodule 'config.shared'

local ITEMS = config.items or {}
local PLATE = config.plate or {}
local FAKE = config.fakeplate or {}
local MSG = config.messages or {}
local WEBHOOK = config.webhook

local MIN_LEN = PLATE.minLength or 1
local MAX_LEN = PLATE.maxLength or 8
local PATTERN = PLATE.pattern or '^[A-Z0-9]+$'
local FAKE_LEN = FAKE.randomLength or 6
local FAKE_CHARS = FAKE.chars or 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'

local FAKE_TABLE = 'sm_voucher_fake'

local function playerOf(src)
    return qb_ecore:GetPlayer(src)
end

local function notify(src, key, kind)
    TriggerClientEvent('ox_lib:notify', src, { description = MSG[key] or key, type = kind or 'error' })
end

local function clean(plate)
    return (tostring(plate or ''):gsub('^%s*(.-)%s*$', '%1')):upper()
end

local function validPlate(plate)
    if #plate < MIN_LEN or #plate > MAX_LEN then return false end
    return plate:match(PATTERN) ~= nil
end

local function ownerOf(plate)
    local row = MySQL.single.await('SELECT citizenid FROM player_vehicles WHERE plate = ?', { plate })
    if row and row.citizenid then return row.citizenid end

    return MySQL.scalar.await('SELECT citizenid FROM sm_vehiclekeys WHERE plate = ?', { plate })
end

local function plateTaken(plate)
    return ownerOf(plate) ~= nil
end

local function log(title, lines)
    if not WEBHOOK or WEBHOOK == '' or WEBHOOK:find('YOUR_') then return end

    PerformHttpRequest(WEBHOOK, function() end, 'POST', json.encode({
        username = 'Voucher',
        embeds = { { title = title, description = table.concat(lines, '\n'), color = 3447003 } },
    }), { ['Content-Type'] = 'application/json' })
end

local function consume(src, item, meta)
    if meta then
        local slots = ox_inventory:Search(src, 'slots', item) or {}
        for slot, entry in pairs(slots) do
            local md = entry.metadata or {}
            if md.originalPlate == meta.originalPlate then
                return ox_inventory:RemoveItem(src, item, 1, nil, slot)
            end
        end
        return false
    end

    return ox_inventory:RemoveItem(src, item, 1)
end

lib.callback.register('voucher:server:checkVehicleOwner', function(src, plate)
    local player = playerOf(src)
    if not player then return false end

    plate = clean(plate)
    if plate == '' then return false end

    local owner = ownerOf(plate)
    if not owner then return false end

    if owner == player.PlayerData.citizenid then return true end

    local fake = MySQL.single.await('SELECT original FROM ' .. FAKE_TABLE .. ' WHERE fake = ?', { plate })
    if fake then return ownerOf(fake.original) == player.PlayerData.citizenid end

    return false
end)

lib.callback.register('voucher:server:checkPlateAvailable', function(src, newPlate, currentPlate)
    local player = playerOf(src)
    if not player then return false end

    newPlate = clean(newPlate)
    if not validPlate(newPlate) then return false end
    if newPlate == clean(currentPlate) then return true end

    return not plateTaken(newPlate)
end)

RegisterNetEvent('voucher:server:saveMaxPerformance', function(plate, mods)
    local src = source
    local player = playerOf(src)
    if not player or type(mods) ~= 'table' then return end

    plate = clean(plate)
    if ownerOf(plate) ~= player.PlayerData.citizenid then return notify(src, 'notOwned') end

    local row = MySQL.single.await('SELECT mods FROM player_vehicles WHERE plate = ?', { plate })
    if not row then return notify(src, 'databaseError') end

    local current = {}
    local ok, decoded = pcall(json.decode, row.mods or '{}')
    if ok and type(decoded) == 'table' then current = decoded end

    for index, value in pairs(mods) do
        current[tostring(index)] = value
    end

    if not consume(src, 'voucher_ratnan') then return notify(src, 'databaseError') end

    MySQL.update('UPDATE player_vehicles SET mods = ? WHERE plate = ?', { json.encode(current), plate })

    notify(src, 'vehicleUpgraded', 'success')
    log('Performance', { ('Plate: %s'):format(plate), ('Oleh: %s'):format(player.PlayerData.citizenid) })
end)

RegisterNetEvent('voucher:server:updatePlate', function(currentPlate, newPlate)
    local src = source
    local player = playerOf(src)
    if not player then return end

    currentPlate, newPlate = clean(currentPlate), clean(newPlate)
    if not validPlate(newPlate) then return notify(src, 'invalidPlate') end
    if ownerOf(currentPlate) ~= player.PlayerData.citizenid then return notify(src, 'notOwned') end

    if newPlate ~= currentPlate and plateTaken(newPlate) then return notify(src, 'plateExists') end
    if not consume(src, 'voucher_plat') then return notify(src, 'databaseError') end

    if newPlate ~= currentPlate then
        MySQL.update('UPDATE player_vehicles SET plate = ? WHERE plate = ?', { newPlate, currentPlate })
        MySQL.update('UPDATE sm_vehiclekeys SET plate = ? WHERE plate = ?', { newPlate, currentPlate })
    end

    notify(src, 'plateInstalled', 'success')
    log('Custom Plate', { ('%s -> %s'):format(currentPlate, newPlate), ('Oleh: %s'):format(player.PlayerData.citizenid) })
end)

local function randomPlate()
    for _ = 1, 50 do
        local out = {}

        for _ = 1, FAKE_LEN do
            local index = math.random(#FAKE_CHARS)
            out[#out + 1] = FAKE_CHARS:sub(index, index)
        end

        local plate = table.concat(out)
        if not plateTaken(plate) then return plate end
    end
end

lib.callback.register('voucher:server:applyFakePlate', function(src, currentPlate)
    local player = playerOf(src)
    if not player then return nil end

    currentPlate = clean(currentPlate)
    if ownerOf(currentPlate) ~= player.PlayerData.citizenid then return notify(src, 'notOwned') end

    local existing = MySQL.single.await('SELECT fake FROM ' .. FAKE_TABLE .. ' WHERE original = ?', { currentPlate })
    if existing then return notify(src, 'alreadyFakeplated') end

    local fakePlate = randomPlate()
    if not fakePlate then return notify(src, 'databaseError') end

    MySQL.insert('INSERT INTO ' .. FAKE_TABLE .. ' (fake, original, citizenid, created) VALUES (?, ?, ?, ?)', {
        fakePlate, currentPlate, player.PlayerData.citizenid, os.time(),
    })

    MySQL.update('UPDATE sm_vehiclekeys SET plate = ? WHERE plate = ?', { fakePlate, currentPlate })

    if not consume(src, 'fakeplate') then
        MySQL.update('DELETE FROM ' .. FAKE_TABLE .. ' WHERE fake = ?', { fakePlate })
        return notify(src, 'databaseError')
    end

    if not ox_inventory:AddItem(src, 'originalplate', 1, { originalPlate = currentPlate }) then
        return notify(src, 'databaseError')
    end

    log('Fake Plate', { ('%s -> %s'):format(currentPlate, fakePlate), ('Oleh: %s'):format(player.PlayerData.citizenid) })

    return fakePlate
end)

lib.callback.register('voucher:server:restoreFakePlate', function(src, currentPlate, originalPlate)
    local player = playerOf(src)
    if not player then return nil end

    currentPlate, originalPlate = clean(currentPlate), clean(originalPlate)

    local row = MySQL.single.await('SELECT * FROM ' .. FAKE_TABLE .. ' WHERE fake = ? AND original = ?', {
        currentPlate, originalPlate,
    })

    if not row then return notify(src, 'notFakeplateItem') end
    if row.citizenid ~= player.PlayerData.citizenid then return notify(src, 'notOwned') end

    MySQL.update('UPDATE sm_vehiclekeys SET plate = ? WHERE plate = ?', { originalPlate, currentPlate })
    MySQL.update('DELETE FROM ' .. FAKE_TABLE .. ' WHERE fake = ?', { currentPlate })

    if not consume(src, 'originalplate', { originalPlate = originalPlate }) then
        return notify(src, 'notFakeplateItem')
    end

    notify(src, 'fakeplateRestored', 'success')
    log('Restore Plate', { ('%s -> %s'):format(currentPlate, originalPlate), ('Oleh: %s'):format(player.PlayerData.citizenid) })

    return originalPlate
end)

AddEventHandler('ox_inventory:usedItem', function(src, item)
    local player = playerOf(src)
    if not player then return end

    if item == 'voucher_pass' then
        if player.PlayerData.metadata.pass then return notify(src, 'alreadyHasPass') end
        player.Functions.SetMetaData('pass', true)
        ox_inventory:RemoveItem(src, item, 1)
        return notify(src, 'passActivated', 'success')
    end

    if item == 'voucher_vvip' then
        local cfg = ITEMS[item]
        if not cfg then return end

        local meta = player.PlayerData.metadata or {}
        if meta.vip or meta.vvip then return notify(src, 'alreadyHasVIP') end

        if GetResourceState('sm_vip') ~= 'started' then return notify(src, 'databaseError') end

        local days = cfg.duration or 30
        local stamp = math.floor(os.time() * 1000)

        MySQL.insert(
            ('INSERT INTO sm_vip_players (citizenid, vip_type, started_at, expired_at, vehicle_claimed, tv_claimed, daily_stamp) VALUES (?, ?, ?, ?, 0, 0, NULL) ON DUPLICATE KEY UPDATE vip_type = VALUES(vip_type), expired_at = VALUES(expired_at)'):format(),
            { player.PlayerData.citizenid, 'vvip', stamp, stamp + (days * 86400000) }
        )

        if GetResourceState('sm_donate') == 'started' then
            MySQL.update('DELETE FROM player_vip WHERE citizenid = ?', { player.PlayerData.citizenid })
            MySQL.insert('INSERT INTO player_vip (citizenid, vip_type, expires_at) VALUES (?, ?, DATE_ADD(NOW(), INTERVAL ? DAY))', {
                player.PlayerData.citizenid, 'vvip', days,
            })
        end

        player.Functions.SetMetaData('vvip', true)
        ox_inventory:RemoveItem(src, item, 1)

        return notify(src, 'vvipActivated', 'success')
    end
end)

CreateThread(function()
    MySQL.query.await(([[
    CREATE TABLE IF NOT EXISTS `%s` (
        `fake` varchar(16) NOT NULL,
        `original` varchar(16) NOT NULL,
        `citizenid` varchar(64) NOT NULL,
        `created` int(11) NOT NULL,
        PRIMARY KEY (`fake`),
        KEY `original` (`original`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]]):format(FAKE_TABLE))
end)

print('^2[voucherdonasi] server siap^7')