--[[
    sm_antivdm :: server
    Hitung strike VDM per korban, kirim peringatan, dan laporkan ke admin saat batas tercapai.
]]

local config = localmodule 'config.shared'

local QBCore = exports['qb-core']:GetCoreObject()

local MAX_WARNINGS = config.maxWarnings or 3
local WINDOW = config.strikeWindow or 180000
local MAX_DISTANCE = config.maxDistance or 25.0

local strikes = {}
local reported = {}

local function notify(src, message, nType)
    lib.notify(src, { description = message, type = nType or 'inform' })
end

local function reportToAdmins(victim, driver, count)
    local victimName = GetPlayerName(victim) or 'unknown'
    local driverName = GetPlayerName(driver) or 'unknown'
    local text = ('[VDM] %s (%d) kena tabrak %s (%d) - %d strike'):format(victimName, victim, driverName, driver, count)

    for _, src in ipairs(GetPlayers()) do
        if IsPlayerAceAllowed(src, 'admin') or IsPlayerAceAllowed(src, 'command.kick') then
            notify(tonumber(src), text, 'warning')
        end
    end
end

RegisterNetEvent('sm_antivdm:server:report', function(driver)
    local victim = source
    driver = tonumber(driver)

    if not driver or driver == victim then return end
    if not QBCore.Functions.GetPlayer(driver) then return end

    local victimPed = GetPlayerPed(victim)
    local driverPed = GetPlayerPed(driver)

    if victimPed == 0 or driverPed == 0 then return end
    if #(GetEntityCoords(victimPed) - GetEntityCoords(driverPed)) > MAX_DISTANCE then return end

    local player = QBCore.Functions.GetPlayer(victim)
    if not player then return end

    local citizenid = player.PlayerData.citizenid
    local now = GetGameTimer()
    local strike = strikes[citizenid]

    if not strike or now - strike.last > WINDOW then
        strike = { count = 0, last = now }
        strikes[citizenid] = strike
        reported[citizenid] = nil
    end

    strike.count = strike.count + 1
    strike.last = now

    TriggerClientEvent('sm_antivdm:client:warn', victim, strike.count)

    if strike.count >= MAX_WARNINGS and not reported[citizenid] then
        reported[citizenid] = true
        reportToAdmins(victim, driver, strike.count)
    end
end)

AddEventHandler('playerDropped', function()
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return end

    strikes[player.PlayerData.citizenid] = nil
    reported[player.PlayerData.citizenid] = nil
end)