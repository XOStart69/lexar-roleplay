local QBCore = exports['qb-core']:GetCoreObject()

local vehicles = lib.loadJson('data.vehicles')

RegisterNetEvent('rhd_vehicleshops:sell_localveh', function(netId)
    local source = source
    local Player = QBCore.Functions.GetPlayer(source)

    if not Player then return end

    local entity = NetworkGetEntityFromNetworkId(netId)

    if not entity or entity == 0 then return end

    local cv = lib.callback.await('rhd_vehicleshops:getcv', source)

    if not cv then return end

    local model = GetEntityModel(entity)
    local list = vehicles[cv.c]

    if not list then return end

    local price = list[model]

    if not price then return end

    local payout = math.floor(price - (price * cv.p / 100))

    if MySQL.scalar.await('SELECT 1 FROM player_vehicles WHERE plate = ? LIMIT 1', {
        qbLib.string.trim(GetVehicleNumberPlateText(entity)),
    }) then
        return
    end

    Player.Functions.AddMoney('bank', payout, 'sell local vehicle')

    DeleteEntity(entity)

    TriggerClientEvent('ox_lib:notify', source, {
        type = 'success',
        description = ('Kendaraan dijual, kamu menerima $%s'):format(payout),
    })
end)
