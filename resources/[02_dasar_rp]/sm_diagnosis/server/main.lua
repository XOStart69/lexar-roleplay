local config = require 'config.init'
local bridge = require 'bridge.init'
local net = require 'modules.net'

local reports = {}
local viewing = {}

local function distance(source, target)
    local a, b = GetPlayerPed(source), GetPlayerPed(target)

    if not a or not b or a == 0 or b == 0 then return 999.0 end

    return #(GetEntityCoords(a) - GetEntityCoords(b))
end

local function sendTargetLost(viewer)
    local target = viewing[viewer]

    viewing[viewer] = nil

    if target and GetPlayerName(target) then
        TriggerClientEvent('rhd_bodydamage:setWatched', target, false)
    end

    if GetPlayerName(viewer) then
        TriggerClientEvent('rhd_bodydamage:targetLost', viewer)
    end
end

RegisterNetEvent('rhd_bodydamage:push', function(report)
    local source = source

    if type(report) ~= 'table' or type(report.regions) ~= 'table' then return end

    reports[source] = report

    for viewer, target in pairs(viewing) do
        if target == source and GetPlayerName(viewer) then
            net.emitLatentClient('rhd_bodydamage:update', viewer, source, report)
        end
    end
end)

RegisterNetEvent('rhd_bodydamage:close', function()
    local source = source

    if viewing[source] then
        sendTargetLost(source)
    end
end)

RegisterNetEvent('rhd_bodydamage:requestOpen', function(target)
    local source = source

    target = tonumber(target)

    if not target or target == source or not GetPlayerName(target) then return end

    if not bridge.checkJob(source, config.allowed_jobs) then return end
    if distance(source, target) > 5.0 then return end

    local report = lib.callback.await('rhd_bodydamage:collect', target)

    if not report then return end

    if viewing[source] then sendTargetLost(source) end

    viewing[source] = target

    TriggerClientEvent('rhd_bodydamage:setWatched', target, true)
    net.emitLatentClient('rhd_bodydamage:open', source, target, report)
end)

RegisterCommand(config.command, function(source)
    if source == 0 then return end
    if not bridge.checkJob(source, config.allowed_jobs) then return end

    TriggerClientEvent('rhd_bodydamage:open', source, source, nil)
end, false)

AddEventHandler('playerDropped', function()
    local source = source

    reports[source] = nil

    if viewing[source] then sendTargetLost(source) end

    for viewer, target in pairs(viewing) do
        if target == source and GetPlayerName(viewer) then
            viewing[viewer] = nil
            TriggerClientEvent('rhd_bodydamage:targetLost', viewer)
        end
    end
end)

lib.print.info('sm_diagnosis server siap')
