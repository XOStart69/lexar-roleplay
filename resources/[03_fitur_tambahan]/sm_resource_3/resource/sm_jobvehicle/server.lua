--[[
    sm_jobvehicle :: server
    Beli kendaraan job. Semua syarat (job, grade, item, one-time) dicek ulang di server.
    Kendaraan disimpan ke player_vehicles (kolom menyesuaikan tabel yang ada).
]]

local config = localmodule 'config'

local SHOPS = config.shops or {}
local COOLDOWN = config.cooldown or 3000
local GARAGE = config.garage or 'Garasi Kota'
local PAY_ORDER = { 'cash', 'bank' }  -- urutan akun yang dipotong

local last = {}
local columns

local function vehicleColumns()
    if columns then return columns end
    columns = {}
    for _, row in ipairs(MySQL.query.await('SHOW COLUMNS FROM player_vehicles') or {}) do
        columns[row.Field] = true
    end
    return columns
end

local function makePlate()
    local chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    for _ = 1, 30 do
        local plate = ''
        for _ = 1, 8 do
            local i = math.random(#chars)
            plate = plate .. chars:sub(i, i)
        end
        if not MySQL.scalar.await('SELECT 1 FROM player_vehicles WHERE plate = ?', { plate }) then
            return plate
        end
    end
end

local function insertVehicle(player, model, plate)
    local cols = vehicleColumns()
    local data = {
        citizenid = player.PlayerData.citizenid,
        license = player.PlayerData.license,
        vehicle = model,
        hash = tostring(joaat(model)),
        mods = '{}',
        plate = plate,
        garage = GARAGE,
        fuel = 100,
        engine = 1000.0,
        body = 1000.0,
        state = 0,
    }

    local names, marks, values = {}, {}, {}
    for name, value in pairs(data) do
        if cols[name] then
            names[#names + 1] = ('`%s`'):format(name)
            marks[#marks + 1] = '?'
            values[#values + 1] = value
        end
    end

    if #names == 0 then return false end

    return MySQL.insert.await(('INSERT INTO player_vehicles (%s) VALUES (%s)'):format(
        table.concat(names, ', '), table.concat(marks, ', ')), values) ~= nil
end

local function jobAllowed(shop, jobName)
    if shop.job == jobName then return true end
    for i = 1, #(shop.jobs or {}) do
        if shop.jobs[i] == jobName then return true end
    end
    return false
end

local function vehicleAllowed(vehicle, jobName)
    local jobs = vehicle.allowedJobs
    if not jobs then return true end
    for i = 1, #jobs do
        if jobs[i] == jobName then return true end
    end
    return false
end

local function hasItem(src, required)
    local list = type(required) == 'table' and required or { required }
    for i = 1, #list do
        if (exports.ox_inventory:GetItemCount(src, list[i]) or 0) > 0 then return true end
    end
    return false
end

local function ownedModels(citizenid)
    local owned = {}
    for _, row in ipairs(MySQL.query.await('SELECT vehicle FROM player_vehicles WHERE citizenid = ?', { citizenid }) or {}) do
        owned[row.vehicle] = true
    end
    return owned
end

lib.callback.register('sm_jobvehicle:server:owned', function(src)
    local player = qb_ecore:GetPlayer(src)
    if not player then return {} end
    return ownedModels(player.PlayerData.citizenid)
end)

lib.callback.register('sm_jobvehicle:server:purchase', function(src, shopKey, vehicleKey, spawnIndex)
    local now = GetGameTimer()
    if last[src] and now - last[src] < COOLDOWN then return false, 'Tunggu sebentar.' end
    last[src] = now

    local player = qb_ecore:GetPlayer(src)
    if not player then return false, 'Karakter belum siap.' end

    local shop = SHOPS[tostring(shopKey)]
    local vehicle = shop and shop.vehicles and shop.vehicles[tostring(vehicleKey)]
    if not vehicle then return false, 'Kendaraan tidak ditemukan.' end

    local job = player.PlayerData.job
    if not jobAllowed(shop, job.name) then return false, 'Kamu tidak berwenang.' end
    if not vehicleAllowed(vehicle, job.name) then return false, 'Job kamu tidak boleh membeli ini.' end
    if (job.grade.level or 0) < (vehicle.requiredGrade or 0) then return false, 'Grade belum cukup.' end

    if vehicle.requiredItem and not hasItem(src, vehicle.requiredItem) then
        return false, 'Item syarat tidak ada.'
    end

    local spawn = shop.spawnLocations and shop.spawnLocations[tonumber(spawnIndex) or 0]
    if not spawn then return false, 'Titik spawn tidak valid.' end

    local ped = GetPlayerPed(src)
    local near = false
    for _, loc in ipairs(shop.pedLocations or {}) do
        if #(GetEntityCoords(ped) - vector3(loc.coords.x, loc.coords.y, loc.coords.z)) <= 25.0 then near = true break end
    end
    if not near then return false, 'Terlalu jauh dari toko.' end

    if vehicle.oneTimePurchase and ownedModels(player.PlayerData.citizenid)[vehicle.model] then
        return false, 'Kendaraan ini sudah kamu miliki.'
    end

    local price = tonumber(vehicle.price) or 0
    local paid = false
    for i = 1, #PAY_ORDER do
        local account = PAY_ORDER[i]
        if (player.PlayerData.money[account] or 0) >= price and player.Functions.RemoveMoney(account, price, 'jobvehicle-' .. vehicle.model) then
            paid = true
            break
        end
    end
    if not paid then return false, 'Uang tidak cukup.' end

    local plate = makePlate()
    if not plate or not insertVehicle(player, vehicle.model, plate) then
        player.Functions.AddMoney('cash', price, 'jobvehicle-refund')
        return false, 'Gagal menyimpan kendaraan.'
    end

    return true, { model = vehicle.model, plate = plate, livery = vehicle.livery, coords = spawn }
end)

AddEventHandler('playerDropped', function()
    last[source] = nil
end)
