--[[
    automodif :: server
    Stasiun perbaikan mandiri. Stasiun hanya melayani job-nya sendiri dan hanya
    saat tidak ada mekanik job itu yang online.
]]

local config = localmodule 'config.shared'

local QBCore = exports['qb-core']:GetCoreObject()

local REPAIR_RADIUS = 25.0

local function notify(src, message, nType)
    lib.notify(src, { description = message, type = nType or 'inform' })
end

local function jobsOnline()
    local list = {}

    for _, player in pairs(QBCore.Functions.GetQBPlayers()) do
        local job = player.PlayerData.job
        if job then list[job.name] = (list[job.name] or 0) + 1 end
    end

    return list
end

lib.callback.register('sm_workshops:server:getActiveStations', function()
    local online = jobsOnline()
    local active = {}

    for i = 1, #(config.stations or {}) do
        local station = config.stations[i]
        if station.jobs and (online[station.jobs] or 0) == 0 then
            active[#active + 1] = station.jobs
        end
    end

    return active
end)

local function nearestStation(coords)
    local stations = config.stations or {}
    local best, bestDist = nil, REPAIR_RADIUS

    for i = 1, #stations do
        local station = stations[i]
        local points = station.zone and station.zone.points

        if points then
            for j = 1, #points do
                local dist = #(coords - points[j])
                if dist < bestDist then best, bestDist = station, dist end
            end
        end
    end

    return best
end

lib.callback.register('sm_workshops:server:repairVehicleAxon', function(src, price, job)
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return false end

    local ped = GetPlayerPed(src)
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle == 0 then
        notify(src, 'Tidak ada kendaraan.', 'error')
        return false
    end

    local station = nearestStation(GetEntityCoords(ped))
    if not station then
        notify(src, 'Kamu di luar area stasiun.', 'error')
        return false
    end

    if station.jobs ~= job then
        notify(src, 'Stasiun ini bukan untuk job itu.', 'error')
        return false
    end

    local cost = math.floor(tonumber(station.price) or tonumber(price) or 0)
    if cost <= 0 then return false end

    local money = player.PlayerData.money

    if (money.bank or 0) >= cost then
        player.Functions.RemoveMoney('bank', cost, 'auto-repair')
    elseif (money.cash or 0) >= cost then
        player.Functions.RemoveMoney('cash', cost, 'auto-repair')
    else
        notify(src, 'Uang tidak cukup.', 'error')
        return false
    end

    return true
end)