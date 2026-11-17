local config = require 'config.client'

local appAdded = false
local appOpen = false
local hudEnabled = GetResourceKvpString('playergroup_hud') ~= 'off'

---@type table?
local lastState

---@type { id: string, blip: number, area: CPoint, trigger?: CPoint }?
local tracked

---@param action string
---@param data any
local function sendApp(action, data)
    if not appAdded then return end
    exports['lb-phone']:SendCustomAppMessage(config.app.identifier, { action = action, data = data })
end

local function clearLocation()
    if not tracked then return end

    tracked.area:remove()
    if tracked.trigger then
        tracked.trigger:remove()
    end
    if DoesBlipExist(tracked.blip) then
        RemoveBlip(tracked.blip)
    end

    tracked = nil
    SendNUIMessage({ action = 'setDistance', data = false })
    sendApp('setDistance', false)
end

---@param task table
local function trackLocation(task)
    clearLocation()

    local settings = config.location
    local coords = vector3(task.coords.x, task.coords.y, task.coords.z)
    local radius = task.radius
    local colour = settings.markerColour

    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, settings.blipSprite)
    SetBlipColour(blip, settings.blipColour)
    SetBlipScale(blip, settings.blipScale)
    SetBlipAsShortRange(blip, false)
    SetBlipRoute(blip, true)
    SetBlipRouteColour(blip, settings.blipColour)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(task.name)
    EndTextCommandSetBlipName(blip)

    local current = {
        id = task.id,
        blip = blip,
        area = lib.points.new({
            coords = coords,
            distance = settings.markerDrawDistance,
            nearby = function()
                ---@diagnostic disable-next-line: param-type-mismatch
                DrawMarker(settings.markerType, coords.x, coords.y, coords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, radius * 2.0, radius * 2.0, 1.0, colour[1], colour[2], colour[3], colour[4], false, false, 2, false, nil, nil, false)
            end,
        }),
    }

    if task.autoComplete then
        current.trigger = lib.points.new({
            coords = coords,
            distance = radius,
            onEnter = function()
                TriggerServerEvent('rhd_playergroup:reachedLocation', task.id)
            end,
        })
    end

    tracked = current

    CreateThread(function()
        while tracked == current do
            local payload = { id = task.id, distance = #(GetEntityCoords(cache.ped) - coords) }
            SendNUIMessage({ action = 'setDistance', data = payload })
            sendApp('setDistance', payload)
            Wait(settings.distanceInterval)
        end
    end)
end

---@param state table
local function applyState(state)
    lastState = state
    SendNUIMessage({ action = 'setState', data = state })
    sendApp('setState', state)

    local tasks = state.group and state.group.tasks or {}
    local active

    for i = 1, #tasks do
        local task = tasks[i]
        if task.type == 'location' and task.isActive and task.coords and not task.isDone and not task.isFailed and not task.hidden then
            active = task
            break
        end
    end

    if not active then
        clearLocation()
    elseif not tracked or tracked.id ~= active.id then
        trackLocation(active)
    end
end

local function addApp()
    local resource = GetCurrentResourceName()
    local added, errorMessage = exports['lb-phone']:AddCustomApp({
        identifier = config.app.identifier,
        name = config.app.name,
        description = config.app.description,
        developer = config.app.developer,
        defaultApp = config.app.defaultApp,
        size = config.app.size,
        ui = ('%s/html/app.html'):format(resource),
        icon = ('https://cfx-nui-%s/html/icon.svg'):format(resource),
        fixBlur = true,
        onOpen = function()
            appOpen = true
            SetTimeout(500, function()
                if appOpen and lastState then
                    sendApp('setState', lastState)
                end
            end)
        end,
        onClose = function()
            appOpen = false
        end,
    })

    appAdded = added == true

    if not added then
        print(('[%s] could not add phone app: %s'):format(resource, errorMessage))
    end
end

CreateThread(function()
    while GetResourceState('lb-phone') ~= 'started' do
        if GetResourceState('lb-phone') == 'missing' then
            print(('[%s] lb-phone is not installed, the group app will not be available'):format(GetCurrentResourceName()))
            return
        end
        Wait(500)
    end

    Wait(500)
    addApp()
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= 'lb-phone' then return end

    appAdded = false
    appOpen = false
    Wait(500)
    addApp()
end)

RegisterNetEvent('rhd_playergroup:state', function(state)
    if source == '' then return end

    applyState(state)
end)

RegisterNetEvent('rhd_playergroup:notify', function(data)
    if source == '' then return end
    if not appAdded then return end
    if data.kind == 'chat' and appOpen then return end
    if data.kind == 'task' and hudEnabled then return end

    exports['lb-phone']:SendNotification({
        app = config.app.identifier,
        title = data.title,
        content = data.content,
    })
end)

RegisterNUICallback('getState', function(_, cb)
    cb(lib.callback.await('rhd_playergroup:getState', false))
end)

RegisterNUICallback('create', function(data, cb)
    cb(lib.callback.await('rhd_playergroup:create', false, data.name))
end)

RegisterNUICallback('requestJoin', function(data, cb)
    cb(lib.callback.await('rhd_playergroup:requestJoin', false, data.groupId))
end)

RegisterNUICallback('cancelRequest', function(_, cb)
    cb(lib.callback.await('rhd_playergroup:cancelRequest', false))
end)

RegisterNUICallback('sendChat', function(data, cb)
    cb(lib.callback.await('rhd_playergroup:sendChat', false, data.text))
end)

RegisterNUICallback('leave', function(_, cb)
    TriggerServerEvent('rhd_playergroup:leave')
    cb(true)
end)

RegisterNUICallback('acceptRequest', function(data, cb)
    TriggerServerEvent('rhd_playergroup:acceptRequest', data.source)
    cb(true)
end)

RegisterNUICallback('denyRequest', function(data, cb)
    TriggerServerEvent('rhd_playergroup:denyRequest', data.source)
    cb(true)
end)

RegisterNUICallback('kick', function(data, cb)
    TriggerServerEvent('rhd_playergroup:kick', data.source)
    cb(true)
end)

RegisterNUICallback('getSettings', function(_, cb)
    cb({ hudEnabled = hudEnabled })
end)

RegisterNUICallback('setHudEnabled', function(data, cb)
    hudEnabled = data.enabled == true
    SetResourceKvp('playergroup_hud', hudEnabled and 'on' or 'off')
    SendNUIMessage({ action = 'setHudEnabled', data = hudEnabled })
    cb(true)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= cache.resource then return end
    clearLocation()
end)
