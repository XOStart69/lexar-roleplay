--[[
    taxui :: server
    Pajak kekayaan harian (persentase dari uang + nilai kendaraan) dan pajak bank.
    Potong otomatis dari bank lalu tunai, catat status per hari, kirim notifikasi ke pemain.
]]

local Config = localmodule 'config'

local QBCore = exports['qb-core']:GetCoreObject()

local Tables = Config.Tables or {}
local PLAYERS = Tables.players or 'players'
local HISTORY = Tables.taxHistory or 'tax_history'
local BANK = Config.BankTax or {}

local VEHICLE = Config.VehicleValues or {}
local IMPORTS = Config.ImportBrands or {}

local SCHEMA = [[
CREATE TABLE IF NOT EXISTS `tax_history` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `citizenid` varchar(64) NOT NULL,
    `tax_amount` int(11) NOT NULL DEFAULT 0,
    `wealth` bigint(20) NOT NULL DEFAULT 0,
    `status` varchar(16) NOT NULL DEFAULT 'pending',
    `day` date NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `citizenid_day` (`citizenid`, `day`),
    KEY `day` (`day`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `bank_tax_history` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `citizenid` varchar(64) NOT NULL,
    `tax_amount` int(11) NOT NULL DEFAULT 0,
    `balance` bigint(20) NOT NULL DEFAULT 0,
    `day` date NOT NULL,
    PRIMARY KEY (`id`),
    KEY `day` (`day`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
]]

local function notify(src, payload)
    TriggerClientEvent('tax-system:client:notification', src, payload)
end

local function vehicleWealth(citizenid)
    local rows = MySQL.query.await('SELECT vehicle FROM player_vehicles WHERE citizenid = ?', { citizenid }) or {}
    local total = 0

    for i = 1, #rows do
        local model = rows[i].vehicle
        local brand

        local ok, data = pcall(function() return QBCore.Shared.Vehicles[model] end)
        if ok and data then brand = data.brand end

        if brand and IMPORTS[brand] then
            total = total + (VEHICLE.import or 500000)
        else
            total = total + (VEHICLE.lokal or 250000)
        end
    end

    return total
end

local function wealthOf(player)
    local money = player.PlayerData.money or {}

    return (money.cash or 0) + (money.bank or 0) + vehicleWealth(player.PlayerData.citizenid)
end

lib.callback.register('tax-system:server:getTaxInfo', function(src)
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end

    local citizenid = player.PlayerData.citizenid

    local today = MySQL.single.await('SELECT tax_amount, status FROM tax_history WHERE citizenid = ? AND day = CURDATE()', { citizenid })
    local summary = MySQL.single.await([[
        SELECT COALESCE(SUM(tax_amount), 0) AS total_paid, COUNT(*) AS paid_days
        FROM tax_history WHERE citizenid = ? AND status = 'paid'
    ]], { citizenid })

    return {
        todayTax = today and { tax_amount = tonumber(today.tax_amount), status = today.status } or nil,
        summary = {
            total_paid = summary and tonumber(summary.total_paid) or 0,
            paid_days = summary and tonumber(summary.paid_days) or 0
        },
        wealth = { total = wealthOf(player) }
    }
end)

local function parseCron(expr)
    local minute, hour = (expr or ''):match('^(%d+)%s+(%d+)')

    return tonumber(minute), tonumber(hour)
end

local function runTax()
    local players = QBCore.Functions.GetQBPlayers()
    local delay = (Config.Processing and Config.Processing.playerDelay or 10)

    for _, player in pairs(players) do
        local src = player.PlayerData.source
        local citizenid = player.PlayerData.citizenid

        local wealth = wealthOf(player)
        local tax = math.floor(wealth * (Config.TaxRate or 0.005))

        if tax > 0 then
            local money = player.PlayerData.money
            local available = (money.cash or 0) + (money.bank or 0)

            if available >= tax then
                if (money.bank or 0) >= tax then
                    player.Functions.RemoveMoney('bank', tax, 'tax-wealth')
                else
                    player.Functions.RemoveMoney('cash', tax, 'tax-wealth')
                end

                MySQL.insert.await([[
                    INSERT INTO tax_history (citizenid, tax_amount, wealth, status, day) VALUES (?, ?, ?, 'paid', CURDATE())
                    ON DUPLICATE KEY UPDATE tax_amount = VALUES(tax_amount), wealth = VALUES(wealth), status = 'paid'
                ]], { citizenid, tax, wealth })

                notify(src, {
                    type = 'deduction',
                    amount = tax,
                    wealth = { total = wealth }
                })
            else
                MySQL.insert.await([[
                    INSERT INTO tax_history (citizenid, tax_amount, wealth, status, day) VALUES (?, ?, ?, 'failed', CURDATE())
                    ON DUPLICATE KEY UPDATE tax_amount = VALUES(tax_amount), wealth = VALUES(wealth), status = 'failed'
                ]], { citizenid, tax, wealth })

                notify(src, {
                    type = 'insufficient',
                    amount = tax,
                    available = available,
                    message = 'Saldo tidak cukup untuk pajak kekayaan'
                })
            end
        end

        Wait(delay)
    end
end

local function runBankTax()
    local rate = BANK.TaxRate or 0.001
    local minimum = BANK.MinimumBalance or 1000000
    local players = QBCore.Functions.GetQBPlayers()

    for _, player in pairs(players) do
        local balance = player.PlayerData.money.bank or 0

        if balance > minimum then
            local tax = math.floor(balance * rate)

            if tax > 0 and player.Functions.RemoveMoney('bank', tax, 'tax-bank') then
                MySQL.insert.await('INSERT INTO bank_tax_history (citizenid, tax_amount, balance, day) VALUES (?, ?, ?, CURDATE())', {
                    player.PlayerData.citizenid, tax, balance
                })
            end
        end

        Wait(BANK.ProcessingDelay or 10)
    end
end

CreateThread(function()
    MySQL.query.await(SCHEMA)

    local taxMinute, taxHour = parseCron(Config.TaxTime)
    local bankMinute, bankHour = parseCron(BANK.TaxTime)
    local lastTax, lastBank = '', ''

    while true do
        Wait(20000)

        local now = os.date('*t')
        local stamp = os.date('%Y-%m-%d')

        if taxHour and taxMinute == now.min and taxHour == now.hour and lastTax ~= stamp then
            lastTax = stamp
            CreateThread(runTax)
        end

        if bankHour and bankMinute == now.min and bankHour == now.hour and lastBank ~= stamp then
            lastBank = stamp
            CreateThread(runBankTax)
        end
    end
end)