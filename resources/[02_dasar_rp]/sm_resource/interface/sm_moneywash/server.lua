--[[
    sm_moneywash :: server
    Penukaran uang per lokasi. Akses per job/grade atau publik, rate bisa di-override per lokasi,
    ada batas per transaksi dan batas harian per karakter.
]]

local Config = localmodule 'config.shared'

local QBCore = exports['qb-core']:GetCoreObject()
local locations = Config.Locations or {}
local exchanges = Config.Exchanges or {}

local MIN_AMOUNT = Config.MinAmount or 1
local MAX_DURATION = Config.MaxWashDuration or 45000
local DURATION_PER_MILLION = Config.DurationPerMillion or 20000

local pending = {}

local SCHEMA = [[
CREATE TABLE IF NOT EXISTS `sm_moneywash_log` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `citizenid` varchar(64) NOT NULL,
    `location` int(11) NOT NULL,
    `day` date NOT NULL,
    `amount` bigint(20) NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    UNIQUE KEY `citizenid_location_day` (`citizenid`, `location`, `day`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
]]

local function notify(src, message, nType)
    TriggerClientEvent('QBCore:Notify', src, message, nType or 'primary')
end

local function ply(src)
    return QBCore.Functions.GetPlayer(src)
end

local function hasAccess(player, location)
    if location.isPublic then return true end

    local job = player.PlayerData.job
    if not job then return false end

    local name, grade = job.name, tonumber(type(job.grade) == 'table' and job.grade.level or job.grade) or 0

    if location.jobs then
        for i = 1, #location.jobs do
            local entry = location.jobs[i]
            if name == entry.name and grade >= entry.minGrade then return true end
        end
        return false
    end

    return name == location.job and grade >= (location.minGrade or 0)
end

local function rateOf(location, key)
    local override = location.rateOverrides and location.rateOverrides[key]
    if override then return override end

    local exchange = exchanges[key]
    return exchange and exchange.rate
end

local function washedToday(citizenid, index)
    local row = MySQL.single.await(
        'SELECT amount FROM sm_moneywash_log WHERE citizenid = ? AND location = ? AND day = CURDATE()',
        { citizenid, index }
    )

    return row and tonumber(row.amount) or 0
end

local function remainingAllowance(player, location, index)
    if not location.maxPerPlayer then return nil end

    local used = washedToday(player.PlayerData.citizenid, index)
    return math.max(0, location.maxPerPlayer - used)
end

lib.callback.register('sm_moneywash:open', function(src, index)
    local player = ply(src)
    if not player then return false end

    local location = locations[tonumber(index) or 0]
    if not location then return false, 'Lokasi tidak dikenal.' end
    if not hasAccess(player, location) then return false, 'Kamu tidak punya akses di sini.' end

    local allowance = remainingAllowance(player, location, index)

    local list = {}

    for i = 1, #location.allowedExchanges do
        local key = location.allowedExchanges[i]
        local exchange = exchanges[key]
        local rate = exchange and rateOf(location, key)

        if exchange and rate then
            local cap = location.maxPerWash
            if allowance and (not cap or allowance < cap) then cap = allowance end

            list[#list + 1] = {
                key = key,
                label = exchange.label,
                fromItem = exchange.fromItem,
                toItem = exchange.toItem,
                rate = rate,
                maxAmount = cap
            }
        end
    end

    if #list == 0 then return false, 'Tidak ada penukaran yang tersedia.' end

    return true, { exchanges = list, label = location.label }
end)

lib.callback.register('sm_moneywash:start', function(src, index, key, amount)
    local player = ply(src)
    if not player then return false, 'Data pemain tidak ditemukan.' end
    if pending[src] then return false, 'Masih ada pencucian berjalan.' end

    index = tonumber(index)
    amount = math.floor(tonumber(amount) or 0)

    local location = locations[index]
    if not location then return false, 'Lokasi tidak dikenal.' end
    if not hasAccess(player, location) then return false, 'Kamu tidak punya akses di sini.' end

    local allowed = false
    for i = 1, #location.allowedExchanges do
        if location.allowedExchanges[i] == key then allowed = true break end
    end
    if not allowed then return false, 'Penukaran tidak tersedia di sini.' end

    local exchange = exchanges[key]
    local rate = exchange and rateOf(location, key)
    if not exchange or not rate then return false, 'Penukaran tidak dikenal.' end

    if amount < MIN_AMOUNT then return false, 'Jumlah terlalu kecil.' end
    if location.maxPerWash and amount > location.maxPerWash then
        return false, ('Maksimal %d per pencucian.'):format(location.maxPerWash)
    end

    local allowance = remainingAllowance(player, location, index)
    if allowance and amount > allowance then
        return false, ('Sisa jatah harian %d.'):format(allowance)
    end

    if not exports.ox_inventory:RemoveItem(src, exchange.fromItem, amount) then
        return false, ('%s tidak cukup.'):format(exchange.fromItem)
    end

    local out = math.floor(amount * rate)

    pending[src] = {
        index = index,
        citizenid = player.PlayerData.citizenid,
        fromItem = exchange.fromItem,
        toItem = exchange.toItem,
        amount = amount,
        out = out
    }

    local duration = math.floor((amount / 1000000) * DURATION_PER_MILLION)
    duration = math.max(3000, math.min(location.washDuration or MAX_DURATION, duration))

    return true, duration
end)

lib.callback.register('sm_moneywash:finish', function(src)
    local state = pending[src]
    if not state then return false, 'Tidak ada pencucian berjalan.' end

    pending[src] = nil

    if state.out <= 0 then
        exports.ox_inventory:AddItem(src, state.fromItem, state.amount)
        return false, 'Hasil penukaran nol.'
    end

    if not exports.ox_inventory:AddItem(src, state.toItem, state.out) then
        exports.ox_inventory:AddItem(src, state.fromItem, state.amount)
        return false, 'Inventory penuh, uang dikembalikan.'
    end

    MySQL.insert.await([[
        INSERT INTO sm_moneywash_log (citizenid, location, day, amount) VALUES (?, ?, CURDATE(), ?)
        ON DUPLICATE KEY UPDATE amount = amount + VALUES(amount)
    ]], { state.citizenid, state.index, state.amount })

    return true, ('Diterima %d %s.'):format(state.out, state.toItem)
end)

RegisterNetEvent('sm_moneywash:cancel', function()
    local src = source
    local state = pending[src]
    if not state then return end

    pending[src] = nil
    exports.ox_inventory:AddItem(src, state.fromItem, state.amount)
end)

AddEventHandler('playerDropped', function()
    local src = source
    local state = pending[src]
    if not state then return end

    pending[src] = nil
    exports.ox_inventory:AddItem(src, state.fromItem, state.amount)
end)

CreateThread(function()
    MySQL.query.await(SCHEMA)
end)