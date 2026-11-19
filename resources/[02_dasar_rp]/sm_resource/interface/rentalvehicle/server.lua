--[[
    rentalvehicle :: server
    Sewa kendaraan: validasi harga/job/cooldown, potong uang, buat plat unik,
    lalu minta klien men-spawn. Sewa aktif dicatat supaya bisa dipulihkan saat relog.
]]

local config = localmodule 'config.shared'

local QBCore = exports['qb-core']:GetCoreObject()

local COOLDOWN_MS = 4000
local MAX_ACTIVE = 1

local cooldown = {}
local active = {}

local function notify(src, message, nType)
    lib.notify(src, { title = 'Rental', description = message, type = nType or 'inform' })
end

local function randomPlate()
    local charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    local out = {}

    for _ = 1, 3 do
        local i = math.random(1, #charset)
        out[#out + 1] = charset:sub(i, i)
    end

    out[#out + 1] = ' '

    for _ = 1, 3 do
        local i = math.random(1, #charset)
        out[#out + 1] = charset:sub(i, i)
    end

    return table.concat(out)
end

local function vehicleEntry(model)
    local list = config.vehicles or {}

    for i = 1, #list do
        if list[i].model == model then return list[i] end
    end
end

local function countActive(src)
    local total = 0

    for _, entry in pairs(active) do
        if entry.src == src then total = total + 1 end
    end

    return total
end

lib.callback.register('rental:checkTaxiAvailability', function()
    return GetResourceState('sm_taxi') == 'started' or true
end)

RegisterNetEvent('rental:rentVehicle', function(model, price, duration, label, rentalLocation)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end

    local entry = vehicleEntry(model)
    if not entry then return notify(src, 'Kendaraan tidak tersedia.', 'error') end

    local now = GetGameTimer()
    if cooldown[src] and now < cooldown[src] then return end
    cooldown[src] = now + COOLDOWN_MS

    if countActive(src) >= MAX_ACTIVE then
        return notify(src, 'Kembalikan kendaraan sewaan dulu.', 'error')
    end

    if type(rentalLocation) ~= 'table' or not rentalLocation.spawnLocations then
        return notify(src, 'Lokasi rental tidak valid.', 'error')
    end

    local cost = tonumber(entry.price) or 0
    if (player.PlayerData.money.cash or 0) < cost then
        return notify(src, ('Uang tidak cukup ($%s).'):format(cost), 'error')
    end

    player.Functions.RemoveMoney('cash', cost, 'vehicle-rental')

    local plate = randomPlate()
    local minutes = tonumber(entry.duration) or 30

    active[plate] = {
        src = src,
        citizenid = player.PlayerData.citizenid,
        model = model,
        label = label or entry.label,
        expires = os.time() + minutes * 60,
        location = rentalLocation
    }

    TriggerClientEvent('rental:spawnVehicle', src, model, plate, minutes, label or entry.label, rentalLocation)

    notify(src, ('%s disewa %d menit ($%s).'):format(label or entry.label, minutes, cost), 'success')
end)

RegisterNetEvent('rental:checkRentalStatus', function()
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end

    for plate, entry in pairs(active) do
        if entry.citizenid == player.PlayerData.citizenid then
            if entry.expires <= os.time() then
                active[plate] = nil
                TriggerClientEvent('rental:deleteVehicle', src, plate)
            else
                local minutes = math.max(1, math.floor((entry.expires - os.time()) / 60))

                TriggerClientEvent('rental:spawnVehicle', src, entry.model, plate, minutes, entry.label, entry.location)
            end
        end
    end
end)

RegisterNetEvent('rental:resetCooldown', function()
    local src = source
    cooldown[src] = nil

    for plate, entry in pairs(active) do
        if entry.src == src then active[plate] = nil end
    end
end)

RegisterNetEvent('rental:returnVehicle', function(plate)
    local src = source
    if type(plate) ~= 'string' then return end

    local entry = active[plate]
    if not entry or entry.src ~= src then return end

    active[plate] = nil
    TriggerClientEvent('rental:deleteVehicle', src, plate)
end)

CreateThread(function()
    while true do
        Wait(60000)

        local now = os.time()

        for plate, entry in pairs(active) do
            if entry.expires <= now then
                active[plate] = nil

                if GetPlayerName(entry.src) then
                    TriggerClientEvent('rental:deleteVehicle', entry.src, plate)
                end
            end
        end
    end
end)

AddEventHandler('playerDropped', function()
    cooldown[source] = nil
end)