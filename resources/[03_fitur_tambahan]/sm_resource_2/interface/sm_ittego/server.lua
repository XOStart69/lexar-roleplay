--[[
    sm_ittego :: server
    Pasang / simpan torture kit, pilih korban, jalankan penyiksaan, dan putus sesi kalau jarak jauh.
]]

local config = localmodule 'config'

local QBCore = exports['qb-core']:GetCoreObject()

local ITEM = config.item
local NEARBY = config.nearbyDistance or 5.0
local BREAK = config.breakDistance or 15.0
local COOLDOWN = config.actionCooldown or 1000

local kits = {}
local sessions = {}
local lastAction = {}

local function ply(src)
    return QBCore.Functions.GetPlayer(src)
end

local function notify(src, reason)
    TriggerClientEvent('sm_ittego:client:notify', src, reason)
end

local function distanceToKit(src, coords)
    local ped = GetPlayerPed(src)
    if ped == 0 then return math.huge end

    return #(GetEntityCoords(ped) - coords)
end

local function endSession(torturer, reason)
    local session = sessions[torturer]
    if not session then return end

    sessions[torturer] = nil

    TriggerClientEvent('sm_ittego:client:end', session.torturer, reason)
    TriggerClientEvent('sm_ittego:client:end', session.victim, reason)
end

local function sessionOf(src)
    if sessions[src] then return sessions[src], src end

    for torturer, session in pairs(sessions) do
        if session.victim == src then return session, torturer end
    end
end

lib.callback.register('sm_ittego:place', function(src, coords, heading)
    local player = ply(src)
    if not player then return false, 'invalid' end

    if GetVehiclePedIsIn(GetPlayerPed(src), false) ~= 0 then return false, 'vehicle' end
    if kits[src] then return false, 'placed' end
    if not player.Functions.GetItemByName(ITEM) then return false, 'noItem' end

    if type(coords) ~= 'table' or type(coords.x) ~= 'number' then return false, 'invalid' end

    if not player.Functions.RemoveItem(ITEM, 1) then return false, 'noItem' end

    kits[src] = {
        coords = vec3(coords.x, coords.y, coords.z),
        heading = tonumber(heading) or 0.0,
        netIds = {}
    }

    return true
end)

lib.callback.register('sm_ittego:pickup', function(src)
    local player = ply(src)
    if not player then return false, 'invalid' end

    local kit = kits[src]
    if not kit then return false, 'noKit' end
    if sessionOf(src) then return false, 'busy' end

    kits[src] = nil

    if not player.Functions.AddItem(ITEM, 1) then
        notify(src, 'full')
    end

    return true
end)

lib.callback.register('sm_ittego:nearby', function(src)
    local kit = kits[src]
    if not kit then return false, 'noKit' end

    local list = {}

    for _, other in ipairs(GetPlayers()) do
        local target = tonumber(other)

        if target ~= src and ply(target) then
            local ped = GetPlayerPed(target)

            if ped ~= 0 and #(GetEntityCoords(ped) - kit.coords) <= NEARBY then
                list[#list + 1] = { id = target, name = GetPlayerName(target) }
            end
        end
    end

    return list
end)

lib.callback.register('sm_ittego:objects', function(src, netIds)
    local kit = kits[src]
    if not kit or type(netIds) ~= 'table' then return false end

    for key, netId in pairs(netIds) do
        if netId then kit.netIds[key] = netId end
    end

    return true
end)

lib.callback.register('sm_ittego:start', function(src, target)
    target = tonumber(target)

    local kit = kits[src]
    if not kit then return false, 'noKit' end
    if not target or target == src then return false, 'self' end
    if not ply(target) then return false, 'invalid' end
    if sessionOf(src) then return false, 'busy' end
    if sessionOf(target) then return false, 'targetBusy' end

    if distanceToKit(src, kit.coords) > NEARBY then return false, 'tooFar' end
    if distanceToKit(target, kit.coords) > NEARBY then return false, 'targetFar' end

    sessions[src] = { torturer = src, victim = target }

    local coords = { x = kit.coords.x, y = kit.coords.y, z = kit.coords.z }

    TriggerClientEvent('sm_ittego:client:start', src, target, coords, kit.heading, 1, kit.netIds)
    TriggerClientEvent('sm_ittego:client:start', target, src, coords, kit.heading, 2, kit.netIds)

    return true
end)

lib.callback.register('sm_ittego:action', function(src, action)
    local session, torturer = sessionOf(src)
    if not session then return false, 'invalid' end
    if torturer ~= src then return false, 'invalid' end

    local kit = kits[src]
    if not kit then return false, 'noKit' end

    if distanceToKit(src, kit.coords) > BREAK or distanceToKit(session.victim, kit.coords) > BREAK then
        endSession(torturer, 'wentFar')
        return false, 'wentFar'
    end

    local now = GetGameTimer()
    if lastAction[src] and now - lastAction[src] < COOLDOWN then return false, 'cooldown' end
    lastAction[src] = now

    TriggerClientEvent('sm_ittego:client:scene', session.torturer, action)
    TriggerClientEvent('sm_ittego:client:scene', session.victim, action)

    return true
end)

RegisterNetEvent('sm_ittego:server:end', function()
    local src = source

    local session, torturer = sessionOf(src)
    if not session then return end

    endSession(torturer, nil)
end)

CreateThread(function()
    while true do
        Wait(2000)

        for torturer, session in pairs(sessions) do
            local kit = kits[torturer]

            if not kit or not ply(session.victim) then
                endSession(torturer, nil)
            elseif distanceToKit(torturer, kit.coords) > BREAK or distanceToKit(session.victim, kit.coords) > BREAK then
                endSession(torturer, 'wentFar')
            end
        end
    end
end)

AddEventHandler('playerDropped', function()
    local src = source

    local session, torturer = sessionOf(src)
    if session then endSession(torturer, nil) end

    kits[src] = nil
    lastAction[src] = nil
end)