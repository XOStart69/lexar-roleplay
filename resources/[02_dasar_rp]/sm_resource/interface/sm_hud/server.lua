--[[
    sm_hud :: server
    Sisi server HUD: harness (item, pasang, durabilitas, cek saat masuk kendaraan),
    penambahan stress, dan siaran jumlah pemain.
]]

local QBCore = exports['qb-core']:GetCoreObject()

local HARNESS_MAX = 100
local STRESS_MAX = 100
local STRESS_TOKEN_CAP = 5

local function trimPlate(plate)
    if type(plate) ~= 'string' then return nil end

    local lib_ = qbLib
    if lib_ and lib_.string and lib_.string.trim then return lib_.string.trim(plate) end

    return (plate:gsub('^%s*(.-)%s*$', '%1'))
end

local function player(src)
    return QBCore.Functions.GetPlayer(src)
end

local function notify(src, message, nType)
    TriggerClientEvent('QBCore:Notify', src, message, nType or 'primary')
end

local function vehicleOf(src)
    local vehicle = GetVehiclePedIsIn(GetPlayerPed(src), false)
    if vehicle == 0 then return nil end

    return vehicle
end

local function saveHarness(plate, durability)
    if not plate then return end

    local row = MySQL.single.await('SELECT mods FROM player_vehicles WHERE plate = ?', { plate })
    if not row or not row.mods then return end

    local mods = json.decode(row.mods) or {}

    if durability <= 0 then
        mods.harnessDurability = nil
    else
        mods.harnessDurability = durability
    end

    MySQL.update.await('UPDATE player_vehicles SET mods = ? WHERE plate = ?', { json.encode(mods), plate })
end

QBCore.Functions.CreateUseableItem('harness', function(src, item)
    TriggerClientEvent('sm_hud:client:UseHarness', src, item)
end)

RegisterNetEvent('sm_hud:server:installHarness', function(slotId)
    local src = source
    local vehicle = vehicleOf(src)
    if not vehicle then return end

    local item = ox_inventory:GetSlot(src, slotId)
    if not item or item.name ~= 'harness' then return end

    if not ox_inventory:RemoveItem(src, 'harness', 1, nil, slotId) then return end

    Entity(vehicle).state:set('harnessDurability', HARNESS_MAX, true)

    local plate = trimPlate(GetVehicleNumberPlateText(vehicle))
    if plate then saveHarness(plate, HARNESS_MAX) end

    notify(src, 'Harness berhasil terpasang di kendaraan!', 'success')
end)

RegisterNetEvent('sm_hud:server:updateHarnessDurability', function(plate, durability)
    local src = source
    local vehicle = vehicleOf(src)
    if not vehicle then return end

    durability = math.max(0, math.min(HARNESS_MAX, math.floor(tonumber(durability) or 0)))
    Entity(vehicle).state:set('harnessDurability', durability, true)

    saveHarness(trimPlate(plate) or trimPlate(GetVehicleNumberPlateText(vehicle)), durability)
end)

RegisterNetEvent('sm_hud:server:checkVehicleHarness', function(plate)
    local src = source
    local vehicle = vehicleOf(src)
    if not vehicle then return end

    local current = Entity(vehicle).state.harnessDurability
    if current ~= nil then return end

    local trimmed = trimPlate(plate) or trimPlate(GetVehicleNumberPlateText(vehicle))
    local durability = 0

    if trimmed then
        local row = MySQL.single.await('SELECT mods FROM player_vehicles WHERE plate = ?', { trimmed })

        if row and row.mods then
            local ok, mods = pcall(json.decode, row.mods)

            if ok and type(mods) == 'table' and tonumber(mods.harnessDurability) then
                durability = math.max(0, math.min(HARNESS_MAX, math.floor(tonumber(mods.harnessDurability))))
            end
        end
    end

    Entity(vehicle).state:set('harnessDurability', durability, true)
end)

RegisterNetEvent('sm_hud:server:addStress', function(amount)
    local src = source
    local ply = player(src)
    if not ply then return end

    amount = math.floor(tonumber(amount) or 0)
    if amount == 0 then return end
    if amount > STRESS_TOKEN_CAP then amount = STRESS_TOKEN_CAP end

    local current = tonumber(ply.PlayerData.metadata.stress) or 0
    local next_ = math.max(0, math.min(STRESS_MAX, current + amount))

    if next_ == current then return end

    ply.Functions.SetMetaData('stress', next_)
end)

RegisterNetEvent('sm_hud:server:removeStress', function(amount)
    local src = source
    local ply = player(src)
    if not ply then return end

    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return end

    local current = tonumber(ply.PlayerData.metadata.stress) or 0
    local next_ = math.max(0, current - amount)

    if next_ == current then return end

    ply.Functions.SetMetaData('stress', next_)
end)

local function broadcastInfo()
    TriggerClientEvent('sm_hud:client:updateServerInfo', -1, #GetPlayers(), GetConvarInt('sv_maxclients', 64))
end

AddEventHandler('playerJoining', function()
    SetTimeout(2000, broadcastInfo)
end)

AddEventHandler('playerDropped', function()
    SetTimeout(2000, broadcastInfo)
end)

CreateThread(function()
    while true do
        Wait(30000)
        broadcastInfo()
    end
end)