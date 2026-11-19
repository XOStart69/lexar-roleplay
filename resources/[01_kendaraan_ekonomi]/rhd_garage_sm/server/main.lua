-- Wrapper blocking: modules/storage.lua memakai db:query_async / db:update_async
-- dan langsung membaca hasilnya sebagai tabel.
db = {
    query_async = function(_, q, params) return MySQL.query.await(q, params or {}) end,
    update_async = function(_, q, params) return MySQL.update.await(q, params or {}) end,
    execute = function(_, q, params) return MySQL.query.await(q, params or {}) end,
    insert_async = function(_, q, params) return MySQL.insert.await(q, params or {}) end,
    scalar_async = function(_, q, params) return MySQL.scalar.await(q, params or {}) end,
}

require 'server.locations'

local storage = require 'modules.storage'

local QBCore = exports['qb-core']:GetCoreObject()

local function player(source)
    return QBCore.Functions.GetPlayer(source)
end

local function pushLocations(source)
    TriggerClientEvent('rhd_garage:client:loadGarageLocations', source, glocations.registered)
end

AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
    local source = Player and Player.PlayerData and Player.PlayerData.source

    if source then pushLocations(source) end
end)

CreateThread(function()
    Wait(1000)

    for _, raw in ipairs(GetPlayers()) do
        pushLocations(tonumber(raw))
    end
end)

local function garageOf(source, garageId)
    local Player = player(source)

    if not Player or not garageId then return nil, nil end

    local data = glocations.registered[garageId]

    if not data then return nil, Player end

    return data, Player
end

lib.callback.register('rhd_garage:server:fetchGarageVehicles', function(source, garageId)
    local data, Player = garageOf(source, garageId)

    if not data then return {} end

    return storage.fetchGarageVehicles(Player.PlayerData.citizenid, garageId)
end)

lib.callback.register('rhd_garage:server:fetchServerVehicleDetails', function(source, plate)
    local Player = player(source)

    if not Player or type(plate) ~= 'string' then return { fuel = 0, engine = 0, body = 0 } end

    local rows = MySQL.query.await('SELECT mods FROM player_vehicles WHERE plate = ? AND citizenid = ?', {
        plate,
        Player.PlayerData.citizenid,
    })

    local mods = rows and rows[1] and rows[1].mods and json.decode(rows[1].mods) or {}

    local trunk = {}
    local glovebox = {}

    local ok, items = pcall(function()
        return exports.ox_inventory:GetInventory('trunk' .. plate)
    end)

    if ok and items and items.items then trunk = items.items end

    return {
        fuel = mods.fuelLevel or 100,
        engine = mods.engineHealth or 1000,
        body = mods.bodyHealth or 1000,
        trunkItems = trunk,
        gloveboxItems = glovebox,
    }
end)

local function spawnCoords(garageData)
    local locations = garageData.locations

    if locations.spawn_points and locations.spawn_points[1] then
        return locations.spawn_points[1]
    end

    local coords = locations.coords
    local heading = coords.w or 0.0

    return utils.getNearbySpawnPoints(vec3(coords.x, coords.y, coords.z), heading, 3.0)
        or vec4(coords.x, coords.y, coords.z, heading)
end

lib.callback.register('rhd_garage:server:spawnVehicle', function(source, data)
    local Player = player(source)

    if not Player or type(data) ~= 'table' or type(data.plate) ~= 'string' then return false end

    local garageId = data.garageId or Player.state.rhd_garage_zoneId
    local garageData = garageId and glocations.registered[garageId]

    if not garageData then return false end

    local vehicle = storage.getVehicleData(Player.PlayerData.citizenid, data.plate, garageId, {
        'mods', 'vehicle', 'hash', 'state', 'garage',
    })

    if not vehicle then return false end

    local isDepot = garageData.category == 'depot'
    local state = tonumber(vehicle.state) or 1

    if not isDepot and state ~= 1 then return false end

    if isDepot then
        local price = utils.calculateDepotPrice(vehicle.hash or vehicle.vehicle, 0)

        if not Player.Functions.RemoveMoney('bank', price, 'impound') then
            TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = 'Uang tidak cukup' })
            return false
        end

        MySQL.update.await('DELETE FROM sm_impound WHERE citizenid = ? AND plate = ?', {
            Player.PlayerData.citizenid, data.plate,
        })

        MySQL.update.await('UPDATE player_vehicles SET state = 0 WHERE plate = ?', { data.plate })
    end

    local mods = vehicle.mods

    if type(mods) == 'string' then mods = json.decode(mods) end

    if type(mods) ~= 'table' then return false end

    mods.model = vehicle.vehicle or mods.model

    MySQL.update.await('UPDATE player_vehicles SET state = 0 WHERE citizenid = ? AND plate = ?', {
        Player.PlayerData.citizenid, data.plate,
    })

    local netId = lib.callback.await('rhd_garage:client:spawn_vehicle', source, {
        mods = mods,
        coords = spawnCoords(garageData),
    })

    return netId ~= nil
end)

RegisterNetEvent('rhd_garage:server:store_vehicle', function(netId, isAutoStore, garageId, props)
    local source = source
    local Player = player(source)

    if not Player or not garageId then return end

    local entity = NetworkGetEntityFromNetworkId(netId)

    if not entity or entity == 0 then return end

    local plate = GetVehicleNumberPlateText(entity)

    if not plate then return end

    plate = qbLib.string.trim(plate)

    local owner = storage.getVehicleOwnerByPlate(plate)

    if not owner then return end

    local garageData = glocations.registered[garageId]

    if not garageData then return end

    local isDepot = garageData.category == 'depot'
    local state = isDepot and 2 or 1

    local encoded = props and json.encode(props) or nil

    if encoded then
        MySQL.update.await('UPDATE player_vehicles SET mods = ?, garage = ?, state = ? WHERE plate = ?', {
            encoded, garageId, state, plate,
        })
    else
        MySQL.update.await('UPDATE player_vehicles SET garage = ?, state = ? WHERE plate = ?', {
            garageId, state, plate,
        })
    end

    TriggerClientEvent('rhd_garage:client:removeAutoStoreVehicle', -1, netId)

    if DoesEntityExist(entity) then
        DeleteEntity(entity)
    end
end)

RegisterNetEvent('rhd_garage:server:update_vehicle_props', function(plate, props)
    if type(plate) ~= 'string' or type(props) ~= 'table' then return end

    MySQL.update.await('UPDATE player_vehicles SET mods = ? WHERE plate = ?', {
        json.encode(props),
        qbLib.string.trim(plate),
    })
end)

lib.print.info('rhd_garage_sm server siap')
