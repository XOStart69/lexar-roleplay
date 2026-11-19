--[[
    sm_blindfold :: server
    Pasang / lepas blindfold antar pemain, item dikelola di server.
]]

local Config = localmodule 'config'

local QBCore = exports['qb-core']:GetCoreObject()

local ITEM = Config.item
local MAX_DISTANCE = (Config.maxDistance or 2.0) + 1.0
local INSTALL = Config.installDuration or 3000
local REMOVE = Config.removeDuration or 2000

local busy = {}
local props = {}

local function ply(src)
    return QBCore.Functions.GetPlayer(src)
end

local function notify(src, message, nType)
    lib.notify(src, { description = message, type = nType or 'inform' })
end

local function closeEnough(src, target)
    local from = GetEntityCoords(GetPlayerPed(src))
    local to = GetEntityCoords(GetPlayerPed(target))

    return #(from - to) <= MAX_DISTANCE
end

local function act(src, target, label, duration)
    TriggerClientEvent('sm_blindfold:client:act', src, label, duration)
    TriggerClientEvent('sm_blindfold:client:act', target, label, duration)
end

RegisterNetEvent('sm_blindfold:server:put', function(target)
    local src = source
    target = tonumber(target)

    if not target or target == src then return end
    if not ply(src) or not ply(target) then return end
    if busy[target] then return end

    if Player(target).state.blindfolded then
        notify(src, 'Target sudah memakai blindfold.', 'error')
        return
    end

    if not closeEnough(src, target) then
        notify(src, 'Target terlalu jauh.', 'error')
        return
    end

    local player = ply(src)
    if not player.Functions.GetItemByName(ITEM) then
        notify(src, 'Kamu tidak punya blindfold.', 'error')
        return
    end

    busy[target] = true

    player.Functions.RemoveItem(ITEM, 1)
    act(src, target, 'Memasang blindfold', INSTALL)

    SetTimeout(INSTALL, function()
        busy[target] = nil

        if not ply(target) then return end

        Player(target).state:set('blindfolded', true, true)
        notify(target, 'Kamu dipasangi blindfold.', 'inform')
        notify(src, 'Blindfold terpasang.', 'success')
    end)
end)

RegisterNetEvent('sm_blindfold:server:remove', function(target)
    local src = source
    target = tonumber(target)

    if not target or target == src then return end
    if not ply(src) or not ply(target) then return end
    if busy[target] then return end

    if not Player(target).state.blindfolded then
        notify(src, 'Target tidak memakai blindfold.', 'error')
        return
    end

    if not closeEnough(src, target) then
        notify(src, 'Target terlalu jauh.', 'error')
        return
    end

    busy[target] = true
    act(src, target, 'Melepas blindfold', REMOVE)

    SetTimeout(REMOVE, function()
        busy[target] = nil

        if not ply(target) then return end

        Player(target).state:set('blindfolded', false, true)
        props[target] = nil

        local player = ply(src)
        if player then
            player.Functions.AddItem(ITEM, 1)
            notify(src, 'Blindfold diambil kembali.', 'success')
        end

        notify(target, 'Blindfold dilepas.', 'inform')
    end)
end)

RegisterNetEvent('sm_blindfold:server:prop', function(netId)
    local src = source
    if not src then return end

    props[src] = netId
end)

AddEventHandler('playerDropped', function()
    busy[source] = nil
    props[source] = nil
end)