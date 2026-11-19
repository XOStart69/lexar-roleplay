--[[
    sm_dispatch :: server
    Panggilan disimpan server, disaring per job, unit dilampirkan server.
    Bodycam: daftar aktif, feed per portal, rekaman.
]]

local Config = localmodule 'config'

local DISPATCH = Config.Dispatch or {}
local ALERTS = Config.Alerts or {}
local MAX_CALLS = Config.MaxStoredCalls or 50
local REMOVE_TIME = Config.DefaultRemoveTime or 300
local ATTACH_ALL_GROUP = Config.AttachAllUnitsInGroupToCall == true
local ATTACH_ALL_VEHICLE = Config.AttachAllUnitsInVehicleToCall == true

local calls = {}
local units = {}
local activeBodycam = {}
local recordings = {}
local nextId = 0
local nextRecording = 0

local function playerOf(src)
    return qb_ecore:GetPlayer(src)
end

local function notify(src, message, kind)
    TriggerClientEvent('ox_lib:notify', src, { description = message, type = kind or 'error' })
end

local function jobOf(player)
    return player and player.PlayerData.job.name or nil
end

local function gradeOf(player)
    return player and player.PlayerData.job.grade.level or 0
end

local function isAdmin(player)
    return player and qb_ecore:HasPermission(player.PlayerData.source, 'admin')
end

local function screenAllowed(player, screen)
    if not player then return nil end
    if isAdmin(player) then return (DISPATCH.police and 'police') or next(DISPATCH) end

    for key, entry in pairs(DISPATCH) do
        if entry.jobs and entry.jobs[jobOf(player)] then return key, entry end
    end

    return nil
end

local function dispatchAllowed(player, key)
    local screen = screenAllowed(player)
    if not screen then return false end
    return screen == key
end

local function canDispatch(player, key)
    if not dispatchAllowed(player, key) then return false end

    local entry = DISPATCH[key]
    if not entry or not entry.permissions then return true end

    local rule = entry.permissions.dispatcher
    if not rule then return true end

    return gradeOf(player) >= (rule[jobOf(player)] or 999)
end

local function broadcastCalls(event, ...)
    for _, raw in ipairs(GetPlayers()) do
        local src = tonumber(raw)
        local player = playerOf(src)
        if screenAllowed(player) then
            TriggerClientEvent(event, src, ...)
        end
    end
end

local function trim()
    local total = 0
    for _ in pairs(calls) do total = total + 1 end
    if total <= MAX_CALLS then return end

    local oldest, stamp

    for id, call in pairs(calls) do
        if not stamp or call.created < stamp then oldest, stamp = id, call.created end
    end

    if oldest then
        calls[oldest] = nil
        units[oldest] = nil
        broadcastCalls('sm_dispatch:client:removeCall', oldest)
    end
end

local function pack(call)
    local copy = {}

    for key, value in pairs(call) do
        if key ~= 'hiddenJobs' and key ~= 'created' then copy[key] = value end
    end

    copy.id = call.id
    copy.units = units[call.id] or {}

    return copy
end

local function eligible(call, player)
    if call.hiddenJobs and call.hiddenJobs[jobOf(player)] then return false end
    if not call.jobs then return true end

    for i = 1, #call.jobs do
        if call.jobs[i] == jobOf(player) then return true end
    end

    return false
end

RegisterNetEvent('sm_dispatch:server:addCall', function(payload)
    local src = source
    local player = playerOf(src)
    if not player or type(payload) ~= 'table' then return end
    if type(payload.coords) ~= 'table' then return end

    nextId = nextId + 1

    local call = {
        id = nextId,
        title = tostring(payload.title or 'Panggilan'):sub(1, 96),
        code = tostring(payload.code or ''),
        priority = tonumber(payload.priority) or 3,
        image = payload.image,
        message = payload.message,
        location = payload.location,
        direction = payload.direction,
        coords = vector3(tonumber(payload.coords.x) or 0.0, tonumber(payload.coords.y) or 0.0, tonumber(payload.coords.z) or 0.0),
        gender = payload.gender,
        vehicle = payload.vehicle,
        weapon = payload.weapon,
        person = payload.person,
        showTime = payload.showTime,
        removeTime = tonumber(payload.removeTime) or REMOVE_TIME,
        color = payload.color,
        flash = payload.flash,
        playSound = payload.playSound,
        playSoundAll = payload.playSoundAll,
        soundId = payload.soundId,
        jobs = payload.jobs,
        hiddenJobs = payload.hiddenJobs,
        blip = payload.blip,
        replyable = payload.replyable,
        callerId = tonumber(payload.callerId) or src,
        created = os.time(),
    }

    calls[call.id] = call
    units[call.id] = {}

    trim()

    for _, raw in ipairs(GetPlayers()) do
        local target = tonumber(raw)
        local other = playerOf(target)

        if other and eligible(call, other) and screenAllowed(other) then
            TriggerClientEvent('sm_dispatch:client:addCall', target, pack(call))
        end
    end

    SetTimeout(call.removeTime * 1000, function()
        if calls[call.id] then
            calls[call.id] = nil
            units[call.id] = nil
            broadcastCalls('sm_dispatch:client:removeCall', call.id)
        end
    end)
end)

lib.callback.register('sm_dispatch:server:getDispatchData', function(src)
    local player = playerOf(src)
    if not player then return nil end

    local key, entry = screenAllowed(player)
    if not key then return nil end

    local result = {}

    for name, data in pairs(DISPATCH) do
        if name == key then
            result[name] = data
        end
    end

    local list = {}
    for id, call in pairs(calls) do
        if eligible(call, player) then list[#list + 1] = pack(call) end
    end

    return {
        dispatch = result,
        key = key,
        permissions = entry and entry.permissions or {},
        calls = list,
        canDispatch = canDispatch(player, key),
        panic = entry and entry.panicButton == true,
    }
end)

local function callAllowed(src, id)
    local player = playerOf(src)
    local call = calls[tonumber(id) or 0]
    if not player or not call then return nil end
    if not eligible(call, player) or not screenAllowed(player) then return nil end

    return call, player
end

RegisterNetEvent('sm_dispatch:server:acceptCall', function(id)
    local src = source
    local call = callAllowed(src, id)
    if not call then return end

    units[call.id] = units[call.id] or {}
    units[call.id][src] = true

    broadcastCalls('sm_dispatch:client:callUnits', call.id, units[call.id])
end)

RegisterNetEvent('sm_dispatch:server:closeCall', function(id, code)
    local src = source
    local call = callAllowed(src, id)
    if not call then return end

    calls[call.id] = nil
    units[call.id] = nil

    broadcastCalls('sm_dispatch:client:removeCall', call.id)
end)

RegisterNetEvent('sm_dispatch:server:clearCalls', function()
    local src = source
    local player = playerOf(src)
    if not player then return end

    local key = screenAllowed(player)
    if not key then return end

    for id, call in pairs(calls) do
        if eligible(call, player) then
            calls[id] = nil
            units[id] = nil
        end
    end

    broadcastCalls('sm_dispatch:client:clearCalls')
end)

RegisterNetEvent('sm_dispatch:server:panic', function()
    local src = source
    local player = playerOf(src)
    if not player then return end

    local key = screenAllowed(player)
    if not key then return end

    for _, raw in ipairs(GetPlayers()) do
        local target = tonumber(raw)
        local other = playerOf(target)

        if other and screenAllowed(other) == key and target ~= src then
            TriggerClientEvent('sm_dispatch:client:panic', target, src, GetEntityCoords(GetPlayerPed(src)))
        end
    end
end)

lib.callback.register('sm_dispatch:bodycam:setActive', function(src, state)
    local player = playerOf(src)
    if not player then return false end

    local key = screenAllowed(player)
    if not key then return false end

    if state then
        activeBodycam[src] = {
            job = jobOf(player),
            name = ('%s %s'):format(player.PlayerData.charinfo.firstname, player.PlayerData.charinfo.lastname),
            label = player.PlayerData.job.label,
        }
    else
        activeBodycam[src] = nil
    end

    return true
end)

lib.callback.register('sm_dispatch:bodycam:getFeeds', function(src, portalIndex)
    local player = playerOf(src)
    if not player then return {} end

    local key = screenAllowed(player)
    if not key then return {} end

    local out = {}

    for unit, data in pairs(activeBodycam) do
        local entry = DISPATCH[data.job] and data.job or nil
        if DISPATCH[key] and DISPATCH[key].jobs and DISPATCH[key].jobs[data.job] then
            out[#out + 1] = { id = unit, name = data.name, label = data.label, kind = 'bodycam' }
        end
    end

    return out
end)

lib.callback.register('sm_dispatch:bodycam:startWatch', function(src, portalIndex, kind, id)
    local target = tonumber(id) or 0
    local ped = GetPlayerPed(target)
    if ped == 0 then return nil end

    return GetEntityCoords(ped)
end)

RegisterNetEvent('sm_dispatch:bodycam:stopWatch', function() end)

lib.callback.register('sm_dispatch:bodycam:toggleDashcam', function(src, netId, label, class)
    local entity = NetworkGetEntityFromNetworkId(tonumber(netId) or 0)
    if entity == 0 or not DoesEntityExist(entity) then return false end

    return true
end)

lib.callback.register('sm_dispatch:bodycam:requestUpload', function(src)
    local base = GetConvar('sm_dispatch_upload_base', '')
    if base == '' then return false end

    return ('%s/rec/%s-%d'):format(base:gsub('/$', ''), src, os.time())
end)

lib.callback.register('sm_dispatch:bodycam:getRecordings', function(src, portalIndex)
    local player = playerOf(src)
    if not player then return {} end

    local key = screenAllowed(player)
    if not key then return {} end

    local out = {}

    for i = 1, #recordings do
        local rec = recordings[i]
        if DISPATCH[key] and DISPATCH[key].jobs and DISPATCH[key].jobs[rec.job] then
            out[#out + 1] = { id = rec.id, name = rec.name, url = rec.url, duration = rec.duration }
        end
    end

    return out
end)

lib.callback.register('sm_dispatch:bodycam:deleteRecording', function(src, portalIndex, recordId)
    for i = 1, #recordings do
        if recordings[i].id == tonumber(recordId) then
            table.remove(recordings, i)
            return true
        end
    end

    return false
end)

lib.callback.register('sm_dispatch:bodycam:recordingFailed', function(src)
    return true
end)

lib.callback.register('sm_dispatch:bodycam:setRemoteRecording', function(src, portalIndex, unitId, state)
    local target = tonumber(unitId)
    if not target or not playerOf(target) then return false end

    if state then
        TriggerClientEvent('sm_dispatch:bodycam:startRecording', target, 300)
    else
        TriggerClientEvent('sm_dispatch:bodycam:stopRecording', target)
    end

    return true
end)

AddEventHandler('playerDropped', function()
    local src = source
    activeBodycam[src] = nil

    for id, list in pairs(units) do
        if list[src] then
            list[src] = nil
            broadcastCalls('sm_dispatch:client:callUnits', id, list)
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    calls = {}
    units = {}
    activeBodycam = {}
end)

print('^2[sm_dispatch] server siap^7')