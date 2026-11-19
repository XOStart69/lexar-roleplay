--[[
    illegal_blackout :: server
    Tahap berurutan: start -> thermite -> shutdown -> perbaikan.
    Item dimakan server, transisi tahap dijaga di sini, pemadaman disiarkan.
]]

local config = localmodule 'config'

local STAGES = { 'start', 'thermite', 'shutdown' }
local COOLDOWN = 15000

local enabled = {}
local cooldown = {}

for i = 1, #STAGES do
    enabled[STAGES[i]] = config[STAGES[i]].enable == true
end

local blackoutOn = false

local function notify(src, message, kind)
    TriggerClientEvent('ox_lib:notify', src, { description = message, type = kind or 'error' })
end

local function playerOf(src)
    return qb_ecore:GetPlayer(src)
end

local function broadcast(event, ...)
    for _, raw in ipairs(GetPlayers()) do
        TriggerClientEvent(event, tonumber(raw), ...)
    end
end

local function sync()
    broadcast('illegal_blackout:syncstate', enabled)
    broadcast('illegal_blackout:setBlackout', blackoutOn)
end

lib.callback.register('illegal_blackout:gc', function()
    return enabled
end)

lib.callback.register('illegal_blackout:cooldown', function(src, stage)
    stage = tostring(stage or '')
    if not config[stage] then return false end
    if not enabled[stage] then return false end

    local stamp = GetGameTimer()
    if cooldown[stage] and stamp - cooldown[stage] < COOLDOWN then return false end

    cooldown[stage] = stamp
    return true
end)

lib.callback.register('illegal_blackout:consume', function(src, stage)
    local data = config[tostring(stage or '')]
    if not data or not data.requireItems then return false end

    for item, amount in pairs(data.requireItems) do
        if (ox_inventory:GetItemCount(src, item) or 0) < amount then return false end
    end

    for item, amount in pairs(data.requireItems) do
        if not ox_inventory:RemoveItem(src, item, amount) then
            return false
        end
    end

    return true
end)

local function soundFor(stage)
    local data = config[stage]
    if not data then return nil end
    if data.scene and data.scene.particle then return data.scene.particle end
    if data.target then return data.target.coords end
end

RegisterNetEvent('illegal_blackout:execute', function()
    local src = source
    local player = playerOf(src)
    if not player then return end

    local stage = lib.callback.await('illegal_blackout:cs', src)
    if not stage or not config[stage] then return notify(src, 'Tahap tidak dikenal.') end
    if not enabled[stage] then return notify(src, 'Tahap ini belum terbuka.') end

    local data = config[stage]

    if data.doorId and GetResourceState('ox_doorlock') == 'started' then
        local door = exports.ox_doorlock:getDoorFromName(data.doorId)
        if door then exports.ox_doorlock:setDoorState(door.id, 0) end
    end

    enabled[stage] = false

    if stage == 'start' then
        enabled.thermite = true
        blackoutOn = true
    elseif stage == 'thermite' then
        enabled.shutdown = true
        blackoutOn = true
    end

    sync()
    broadcast('illegal_blackout:syncsound', true, soundFor(stage))

    for _, raw in ipairs(GetPlayers()) do
        local target = playerOf(tonumber(raw))
        if target and target.PlayerData.job.name == 'police' then
            TriggerClientEvent('illegal_blackout:syncsound', tonumber(raw), true, soundFor(stage))
        end
    end
end)

RegisterNetEvent('illegal_blackout:perbaikan', function()
    local src = source
    local player = playerOf(src)
    if not player then return end

    if not blackoutOn then return notify(src, 'Tidak ada pemadaman.') end
    if (ox_inventory:GetItemCount(src, 'repair_kit') or 0) < 1 then
        return notify(src, 'Butuh repair kit.')
    end

    ox_inventory:RemoveItem(src, 'repair_kit', 1)

    for i = 1, #STAGES do enabled[STAGES[i]] = (STAGES[i] == 'start') end
    blackoutOn = false

    if config.thermite.doorId and GetResourceState('ox_doorlock') == 'started' then
        local door = exports.ox_doorlock:getDoorFromName(config.thermite.doorId)
        if door then exports.ox_doorlock:setDoorState(door.id, 1) end
    end

    sync()
    broadcast('illegal_blackout:syncsound', false)
    notify(src, 'Gardu diperbaiki.', 'success')
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    SetTimeout(2000, sync)
end)

print('^2[illegal_blackout] server siap^7')