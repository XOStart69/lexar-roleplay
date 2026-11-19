local QBCore = exports['qb-core']:GetCoreObject()

local vehicles = lib.loadJson('data.vehicles')

local function player(source)
    return QBCore.Functions.GetPlayer(source)
end

local function priceOf(shopId, model)
    local shop = cfg.shops[shopId]

    if not shop then return nil end

    local list = vehicles[shop.vehicles]

    if not list then return nil end

    return list[joaat(model)]
end

local function plateFor(shopId)
    local shop = cfg.shops[shopId]
    local prefix = shop and shop.prefix_plate or ''

    for _ = 1, 30 do
        local plate = prefix .. lib.string.random('...')

        if not MySQL.scalar.await('SELECT 1 FROM player_vehicles WHERE plate = ? LIMIT 1', { plate }) then
            return plate
        end
    end
end

CreateThread(function()
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS sm_vehicleshop_installments (
        id INT AUTO_INCREMENT PRIMARY KEY,
        citizenid VARCHAR(50) NOT NULL,
        plate VARCHAR(16) NOT NULL,
        model VARCHAR(48) NOT NULL,
        remaining BIGINT NOT NULL,
        per_period BIGINT NOT NULL,
        due_at DATETIME NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_owner (citizenid)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]])
end)

lib.callback.register('rhd_vehicleshops:getCache', function(source)
    return lib.callback.await('rhd_vehicleshops:getProps', source)
end)

lib.callback.register('rhd_vehicleshops:getInstallmentDetails', function(source)
    local Player = player(source)

    if not Player then return nil end

    local rows = MySQL.query.await([[SELECT plate, model, remaining, per_period, due_at
        FROM sm_vehicleshop_installments WHERE citizenid = ? ORDER BY id ASC]], {
        Player.PlayerData.citizenid,
    })

    return rows
end)

lib.callback.register('rhd_vehicleshops:payInstallment', function(source, plate, amount)
    local Player = player(source)

    if not Player or type(plate) ~= 'string' then return false end

    local row = MySQL.single.await('SELECT * FROM sm_vehicleshop_installments WHERE plate = ? AND citizenid = ?', {
        plate, Player.PlayerData.citizenid,
    })

    if not row then return false end

    amount = math.floor(tonumber(amount) or 0)

    if amount <= 0 then return false end

    if not Player.Functions.RemoveMoney('bank', amount, 'installment') then return false end

    local remaining = math.max(row.remaining - amount, 0)

    if remaining <= 0 then
        MySQL.update.await('DELETE FROM sm_vehicleshop_installments WHERE id = ?', { row.id })
        MySQL.update.await('UPDATE player_vehicles SET state = 1 WHERE plate = ?', { plate })
    else
        MySQL.update.await('UPDATE sm_vehicleshop_installments SET remaining = ?, due_at = DATE_ADD(NOW(), INTERVAL 1 DAY) WHERE id = ?', {
            remaining, row.id,
        })
    end

    return true
end)

lib.callback.register('rhd_vehicleshops:buyVehicle', function(source, shopId, data)
    local Player = player(source)

    if not Player or not data or type(data) ~= 'table' or not data.props then return false end

    local model = data.props.model or data.model

    if not model then return false end

    local price = priceOf(shopId, model)

    if not price then return false end

    local shop = cfg.shops[shopId]
    local method = data.paymentMethod or data.method or 'bank'
    local plate = plateFor(shopId)

    if not plate then return false end

    local mods = data.props
    mods.model = model

    local params = {
        Player.PlayerData.license,
        Player.PlayerData.citizenid,
        model,
        joaat(model),
        json.encode(mods),
        plate,
        shop.default_garage or 'Garasi Kota',
    }

    if method == 'installment' then
        local option = cfg.installment.options[tonumber(data.installmentIndex) or 1]

        if not option then return false end

        local downPercent = math.max(tonumber(data.downPayment) or cfg.installment.minDownPayment, cfg.installment.minDownPayment)
        local down = math.floor(price * downPercent / 100)
        local total = math.floor(price * (1 + option.interest / 100)) - down

        if total <= 0 then return false end

        if not Player.Functions.RemoveMoney('bank', down, 'vehicle down payment') then return false end

        MySQL.insert.await([[
            INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, state)
            VALUES (?, ?, ?, ?, ?, ?, ?, 1)
        ]], params)

        MySQL.insert.await([[
            INSERT INTO sm_vehicleshop_installments (citizenid, plate, model, remaining, per_period, due_at)
            VALUES (?, ?, ?, ?, ?, DATE_ADD(NOW(), INTERVAL ? DAY))
        ]], {
            Player.PlayerData.citizenid,
            plate,
            model,
            total,
            math.ceil(total / math.max(option.duration, 1)),
            cfg.installment.type == 'days' and 1 or 1,
        })

        return true
    end

    local account = method == 'cash' and 'cash' or 'bank'

    if not Player.Functions.RemoveMoney(account, price, 'vehicle purchase') then return false end

    MySQL.insert.await([[
        INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, state)
        VALUES (?, ?, ?, ?, ?, ?, ?, 1)
    ]], params)

    return true
end)

lib.callback.register('rhd_vehicleshops:startTestDrive', function(source)
    local Player = player(source)

    if not Player then return false end

    if Player.PlayerData.metadata.inTestDrive then return false end

    Player.Functions.SetMetaData('inTestDrive', true)

    return true
end)

RegisterNetEvent('rhd_vehicleshops:endTestDrive', function()
    local Player = player(source)

    if not Player then return end

    Player.Functions.SetMetaData('inTestDrive', false)
end)

lib.callback.register('rhd_vehicleshops:isVehicleOwner', function(source)
    local Player = player(source)

    if not Player then return false end

    local ped = GetPlayerPed(source)

    if not ped or ped == 0 then return false end

    local veh = GetVehiclePedIsIn(ped, false)

    if not veh or veh == 0 then return false end

    local plate = qbLib.string.trim(GetVehicleNumberPlateText(veh))

    local owner = MySQL.scalar.await('SELECT citizenid FROM player_vehicles WHERE plate = ?', { plate })

    return owner == Player.PlayerData.citizenid
end)

CreateThread(function()
    while true do
        Wait(15 * 60 * 1000)

        local rows = MySQL.query.await('SELECT * FROM sm_vehicleshop_installments WHERE due_at <= NOW()')

        for i = 1, #rows do
            local row = rows[i]
            local Player = QBCore.Functions.GetPlayerByCitizenId(row.citizenid)

            local paid = false

            if Player then
                paid = Player.Functions.RemoveMoney('bank', row.per_period, 'installment auto')
            else
                local bank = MySQL.scalar.await('SELECT bank FROM players WHERE citizenid = ?', { row.citizenid })

                if bank and bank >= row.per_period then
                    MySQL.update.await('UPDATE players SET bank = bank - ? WHERE citizenid = ?', { row.per_period, row.citizenid })
                    paid = true
                end
            end

            if paid then
                local remaining = math.max(row.remaining - row.per_period, 0)

                if remaining <= 0 then
                    MySQL.update.await('DELETE FROM sm_vehicleshop_installments WHERE id = ?', { row.id })
                else
                    MySQL.update.await('UPDATE sm_vehicleshop_installments SET remaining = ?, due_at = DATE_ADD(NOW(), INTERVAL 1 DAY) WHERE id = ?', {
                        remaining, row.id,
                    })
                end
            else
                MySQL.update.await('UPDATE player_vehicles SET state = 2 WHERE plate = ?', { row.plate })
            end
        end
    end
end)

lib.print.info('sm_vehicleshop server siap')
