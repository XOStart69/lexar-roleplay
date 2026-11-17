local Config = localmodule 'config'
local Util = localmodule 'config.util'
local Colors = localmodule 'config.colors'
local Alerts = localmodule 'modules.alerts'
local Compat = localmodule 'modules.compat'
local Bridge = localmodule 'modules.bridge'
local BodycamConfig = localmodule 'config.bodycam'

local L = Util.L

local weaponsByHash

local function getWeaponsByHash()
    if weaponsByHash then return weaponsByHash end

    weaponsByHash = {}

    for name, item in pairs(ox_items or {}) do
        if item.weapon and item.ammoname then
            weaponsByHash[item.hash or joaat(name)] = item
        end
    end

    return weaponsByHash
end

local PlayerPedId = PlayerPedId
local GetEntityCoords = GetEntityCoords
local GetVehiclePedIsIn = GetVehiclePedIsIn
local DoesEntityExist = DoesEntityExist
local GetGameTimer = GetGameTimer
local mrandom = math.random
local mfloor = math.floor
local sformat = string.format
local ssub = string.sub
local tconcat = table.concat

local state = {
    focused = false,
    opening = false,
    editing = false,
    openPages = {},
    holds = {},
    focusHold = false,
    frameMounted = false,
    frameReady = false,
    initSent = false,
}

local cache = {
    ped = nil,
    coords = nil,
    vehicle = nil,
    weapon = nil,
    armed = false,
    closestPed = nil,
    witnessPed = nil,
}

local callBlips = {}
local lastPanicTime = nil

interface.init(false)

local pendingMessages = {}
local readyListeners = Bridge.readyListeners

---@return boolean
local function isFrameNeeded()
    return state.editing or next(state.openPages) ~= nil or next(state.holds) ~= nil
end

local function applyFocus()
    local wanted = state.focused or state.editing or state.focusHold
    interface.focus(wanted, wanted)
end

local function mountFrame()
    if state.frameMounted then return end
    state.frameReady = false
    state.frameMounted = true
    interface.show()
end

local function unmountFrame()
    if not state.frameMounted then return end
    interface.hide()
    state.frameMounted = false
    state.frameReady = false
    state.initSent = false
    pendingMessages = {}
end

---@param message table
local function sendUI(message)
    if state.frameReady then
        return interface.send(message)
    end

    pendingMessages[#pendingMessages + 1] = message
end

interface.callback('ready', function(_, cb)
    cb('ok')
    state.frameReady = true

    local queued = pendingMessages
    pendingMessages = {}

    for i = 1, #queued do
        interface.send(queued[i])
    end

    for i = 1, #readyListeners do
        readyListeners[i]()
    end
end)

local DIRECTIONS = {
    'north', 'northeast', 'east', 'southeast',
    'south', 'southwest', 'west', 'northwest',
}

---@param heading number
---@return string
local function getCompassDirection(heading)
    heading = heading % 360.0
    local sector = mfloor(((heading + 22.5) % 360.0) / 45.0) + 1
    return L(DIRECTIONS[sector] or 'unknown')
end

---@param value number
---@param places number?
---@return number
local function round(value, places)
    local multiplier = 10 ^ (places or 0)
    return mfloor(value * multiplier + 0.5) / multiplier
end

---@param targetCoords vector3|table
---@return string
local function formatDistance(targetCoords)
    local playerCoords = GetEntityCoords(PlayerPedId())
    local distance = #(playerCoords - vec3(targetCoords.x, targetCoords.y, targetCoords.z))

    if distance > 999 then
        return L('distance_km', round(distance / 1000, 2))
    end

    return L('distance_m', mfloor(distance))
end

---@param plate string
---@param percentage table|number
---@return string
local function maskPlate(plate, percentage)
    local length = #plate
    local ratio

    if type(percentage) == 'table' then
        local min = percentage.min / 100
        local max = percentage.max / 100
        ratio = min + (mrandom() * (max - min))
    else
        ratio = percentage / 100
    end

    if ratio < 0 then ratio = 0 elseif ratio > 1 then ratio = 1 end

    local revealCount = mfloor(length * ratio)

    local order = {}
    for i = 1, length do order[i] = i end

    for i = length, 2, -1 do
        local j = mrandom(1, i)
        order[i], order[j] = order[j], order[i]
    end

    local revealed = {}
    for i = 1, revealCount do revealed[order[i]] = true end

    local out = {}
    for i = 1, length do
        out[i] = revealed[i] and ssub(plate, i, i) or '?'
    end

    return tconcat(out)
end

---@param coords vector3
---@return string?
local function getStreetLabel(coords)
    local streetHash, crossingHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local street = GetStreetNameFromHashKey(streetHash)
    local crossing = GetStreetNameFromHashKey(crossingHash)

    if street and crossing and street ~= '' and crossing ~= '' then
        return sformat('%s, %s', street, crossing)
    end

    return street ~= '' and street or (crossing ~= '' and crossing or nil)
end

---@param model number
---@return string
local function getVehicleLabel(model)
    model = tonumber(model)
    local make = GetLabelText(GetMakeNameFromVehicleModel(model))
    local name = GetLabelText(GetDisplayNameFromVehicleModel(model))
    return sformat('%s %s', make, name)
end

---@param vehicle number
---@return table?
local function getVehicleData(vehicle)
    if not DoesEntityExist(vehicle) then return nil end

    return {
        model = getVehicleLabel(GetEntityModel(vehicle)),
        color = Colors[GetVehicleColours(vehicle)],
        plate = GetVehicleNumberPlateText(vehicle),
    }
end

---@param ped number
---@return string?
local function getWeaponLabel(ped)
    local weapon = getWeaponsByHash()[GetSelectedPedWeapon(ped)]
    return weapon and weapon.label or nil
end

local function getJobName()
    local job = QBPlayerData.job
    return job and job.name
end

local function getGrade()
    local job = QBPlayerData.job
    return job and job.grade and job.grade.level or 0
end

local function isOnDuty()
    local job = QBPlayerData.job
    return job and job.onduty
end

local function getCharName()
    local info = QBPlayerData.charinfo
    if not info then return L('unknown') end
    return sformat('%s %s', info.firstname, info.lastname)
end

local function getGender()
    local info = QBPlayerData.charinfo
    return (info and info.gender == 1) and L('female') or L('male')
end

local function isDead()
    local metadata = QBPlayerData.metadata
    return metadata and metadata.isdead
end

---@return string?
local function getCurrentDispatchIndex()
    if not isOnDuty() then return nil end
    return Util.getDispatchIndexByJob(getJobName())
end

local function getItemCount(item)
    return ox_inventory:Search('count', item) or 0
end

---@param callData table
function AddCall(callData)
    callData = callData or {}

    local ped = PlayerPedId()
    local coords

    local given = callData.coords
    if type(given) == 'vector4' then
        coords = given.xyz
    elseif type(given) == 'vector3' then
        coords = given
    elseif type(given) == 'table' and given.x then
        coords = vec3(given.x, given.y, given.z or 0.0)
    else
        coords = GetEntityCoords(ped)
    end

    if not callData.title or not callData.jobs then
        return lib.print.error('sm_dispatch: call rejected, missing `title`/`jobs`')
    end

    local offset = mfloor(tonumber(callData.coordsOffset) or 0)

    if offset > 0 then
        coords = coords + vec3(mrandom(-offset, offset), mrandom(-offset, offset), 0.0)
    end

    local vehicle = GetVehiclePedIsIn(ped, false)
    if not DoesEntityExist(vehicle) then
        vehicle = GetVehiclePedIsEntering(ped)
    end

    local vehicleData = getVehicleData(vehicle)

    if vehicleData and vehicleData.plate and callData.platePercentage then
        vehicleData.plate = maskPlate(vehicleData.plate, callData.platePercentage)
    end

    TriggerServerEvent('sm_dispatch:server:addCall', {
        title = callData.title,
        code = callData.code,
        priority = callData.priority,
        image = callData.image,
        message = callData.message,
        location = callData.showLocation and getStreetLabel(coords) or nil,
        direction = callData.showDirection and getCompassDirection(GetEntityHeading(ped)) or nil,
        coords = coords,
        gender = callData.showGender and getGender() or nil,
        vehicle = callData.showVehicle and vehicleData or nil,
        weapon = callData.showWeapon and getWeaponLabel(ped) or nil,
        person = callData.showPerson and getCharName() or nil,
        showTime = callData.showTime,
        removeTime = callData.removeTime,
        color = callData.color,
        flash = callData.flash,
        playSound = callData.playSound,
        playSoundAll = callData.playSoundAll,
        soundId = callData.soundId,
        jobs = callData.jobs,
        hiddenJobs = callData.hiddenJobs,
        blip = callData.blip,
        replyable = callData.replyable,
        callerId = GetPlayerServerId(PlayerId()),
        units = {},
    })
end

---@param callData table
local function createCallBlip(callData)
    local blipConfig = callData and callData.blip
    if not blipConfig then return end

    local coords = callData.coords
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)

    SetBlipSprite(blip, blipConfig.sprite)
    SetBlipScale(blip, blipConfig.scale or 1.0)
    SetBlipColour(blip, blipConfig.color)
    SetBlipDisplay(blip, blipConfig.display or 4)
    SetBlipAsShortRange(blip, blipConfig.shortRange ~= false)

    if blipConfig.flash then
        SetBlipFlashes(blip, true)
        SetBlipFlashInterval(blip, 500)
    end

    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(callData.title)
    EndTextCommandSetBlipName(blip)

    local entry = { normal = blip }
    callBlips[callData.id] = entry

    if blipConfig.radius then
        local radiusBlip = AddBlipForRadius(coords.x, coords.y, coords.z, blipConfig.radius)
        SetBlipColour(radiusBlip, blipConfig.color)
        SetBlipAlpha(radiusBlip, 127)
        entry.radius = radiusBlip
    end

    local removeTime = callData.removeTime or 300000
    local callId = callData.id

    CreateThread(function()
        local startTime = GetGameTimer()

        while true do
            local elapsed = GetGameTimer() - startTime
            if elapsed >= removeTime then break end

            if not callBlips[callId] then return end

            local alpha = mfloor(255 - ((elapsed / removeTime) * 255))
            SetBlipAlpha(blip, alpha)

            if entry.radius then
                SetBlipAlpha(entry.radius, mfloor(alpha / 2))
            end

            Wait(250)
        end

        if DoesBlipExist(blip) then RemoveBlip(blip) end
        if entry.radius and DoesBlipExist(entry.radius) then RemoveBlip(entry.radius) end

        callBlips[callId] = nil
    end)
end

---@param callId any
local function removeCallBlip(callId)
    local entry = callBlips[callId]
    if type(entry) ~= 'table' then return end

    if DoesBlipExist(entry.normal) then RemoveBlip(entry.normal) end
    if entry.radius and DoesBlipExist(entry.radius) then RemoveBlip(entry.radius) end

    callBlips[callId] = nil
end

local function clearAllCallBlips()
    for callId in pairs(callBlips) do
        removeCallBlip(callId)
    end
end

local function isAudioEnabled()
    local value = GetResourceKvpString('sm_dispatch:audio')
    return value == nil or value == 'true'
end

local KVP_LAYOUT = 'sm_dispatch:layout'

local FALLBACK_POSITION = { x = 50, y = 50 }

---@param position table?
---@return table?
local function readPosition(position)
    if type(position) ~= 'table' then return nil end

    local x = tonumber(position.x)
    local y = tonumber(position.y)

    if not x or not y or x < 0 or y < 0 or x > 100 or y > 100 then
        return nil
    end

    return { x = x, y = y }
end

---@param position table?
---@param fallback table?
---@return table
local function validPosition(position, fallback)
    return readPosition(position) or readPosition(fallback) or FALLBACK_POSITION
end

---@return table
local function getLayout()
    local saved = GetResourceKvpString(KVP_LAYOUT)
    local decoded = saved and json.decode(saved) or nil

    if type(decoded) ~= 'table' then decoded = {} end

    return {
        callManager = validPosition(decoded.callManager, Config.CallManagerPosition),
        notification = validPosition(decoded.notification, Config.NotificationPosition),
        bodycam = validPosition(decoded.bodycam, BodycamConfig.Position),
    }
end

---@param layout table
local function saveLayout(layout)
    SetResourceKvp(KVP_LAYOUT, json.encode({
        callManager = validPosition(layout.callManager, Config.CallManagerPosition),
        notification = validPosition(layout.notification, Config.NotificationPosition),
        bodycam = validPosition(layout.bodycam, BodycamConfig.Position),
    }))
end

local function fetchDispatchData()
    return lib.callback.await('sm_dispatch:server:getDispatchData', false)
end

---@param dispatchIndex string
---@param dispatchData table
local function pushInitPayload(dispatchIndex, dispatchData)
    local dispatchConfig = Config.Dispatch[dispatchIndex]
    local jobName = getJobName()
    local grade = getGrade()

    state.initSent = true

    sendUI({
        action = 'init',
        data = {
            locales = Util.strings,
            localeCode = Config.Locale,
            playerId = GetPlayerServerId(PlayerId()),
            notificationEnabled = dispatchConfig.pages.notification,
            layout = getLayout(),
            callManagerSize = Config.CallManagerSize,
            audioEnabled = isAudioEnabled(),
            isDispatcher = Util.hasPermission(dispatchIndex, 'dispatcher', jobName, grade),
            keys = {
                accept = Config.Controls.calls and Config.Controls.calls.accept,
                next = Config.Controls.calls and Config.Controls.calls.next,
                previous = Config.Controls.calls and Config.Controls.calls.previous,
                focus = Config.Controls.toggleFocus,
                moveMode = Config.Controls.toggleMoveMode,
            },
            units = dispatchData.players,
            groups = dispatchData.groups,
            calls = dispatchData.calls,
        },
    })
end

---@param visible boolean
---@param page string?
local function setUIVisibility(visible, page)
    local needsCursor = state.openPages.callManager or state.openPages.sidebar or false

    state.focused = needsCursor
    applyFocus()

    sendUI({
        action = 'setVisible',
        data = { visible = visible, page = page },
    })
    sendUI({ action = 'setFocus', data = needsCursor })
end

---@param page string
local function hideUI(page)
    state.openPages[page] = nil
    setUIVisibility(false, page)

    if not isFrameNeeded() then
        unmountFrame()
    end
end

---@param page string
local function toggleUI(page)
    if state.openPages[page] then
        return hideUI(page)
    end

    if state.opening then return end

    local dispatchIndex = getCurrentDispatchIndex()
    if not dispatchIndex then return end

    local dispatchConfig = Config.Dispatch[dispatchIndex]
    if not dispatchConfig.pages or not dispatchConfig.pages[page] then return end

    if dispatchConfig.neededItem and getItemCount(dispatchConfig.neededItem) <= 0 then
        return
    end

    state.opening = true

    local dispatchData = fetchDispatchData()

    state.opening = false

    if not dispatchData then
        return lib.notify({ type = 'error', description = L('open_failed') })
    end

    state.openPages[page] = true
    mountFrame()

    pushInitPayload(dispatchIndex, dispatchData)
    setUIVisibility(true, page)
end

---@param force boolean?
local function toggleFocus(force)
    if not force and not state.openPages.sidebar and not state.openPages.callManager then
        return
    end

    state.focused = not state.focused
    applyFocus()
    sendUI({ action = 'setFocus', data = state.focused })
end

interface.callback('hideUI', function(data, cb)
    cb(1)
    hideUI(type(data) == 'table' and data.page or data)
end)

local function releaseUI()
    for page in pairs(state.openPages) do
        state.openPages[page] = nil
    end

    state.editing = false
    state.opening = false
    state.focused = false
    state.focusHold = false

    interface.focus(false, false)
    unmountFrame()

    if next(state.holds) ~= nil then
        mountFrame()
    end
end

RegisterCommand('dispatchfix', function()
    releaseUI()
    lib.notify({ type = 'success', description = L('ui_released') })
end, false)

interface.callback('renderFailed', function(data, cb)
    cb(1)

    lib.print.error(('sm_dispatch: UI render failed - %s'):format(
        type(data) == 'table' and tostring(data.message) or 'unknown'
    ))

    releaseUI()
    lib.notify({ type = 'error', description = L('ui_failed') })
end)

interface.callback('toggleFocus', function(_, cb)
    cb(1)
    toggleFocus(true)
end)

interface.callback('saveLayout', function(data, cb)
    cb(1)
    saveLayout(data)
end)

interface.callback('setAudioEnabled', function(enabled, cb)
    cb(1)
    SetResourceKvp('sm_dispatch:audio', tostring(enabled and true or false))
end)

interface.callback('getDistanceToCall', function(coords, cb)
    cb(formatDistance(coords))
end)

---@return number[]
local function getVehiclePassengerIds()
    local ids = {}
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)

    if not DoesEntityExist(vehicle) then return ids end

    local seats = GetVehicleMaxNumberOfPassengers(vehicle)
    local count = 0

    for seat = -1, seats - 1 do
        if not IsVehicleSeatFree(vehicle, seat) then
            local seatPed = GetPedInVehicleSeat(vehicle, seat)

            if DoesEntityExist(seatPed) and seatPed ~= ped then
                count = count + 1
                ids[count] = GetPlayerServerId(NetworkGetPlayerIndexFromPed(seatPed))
            end
        end
    end

    return ids
end

interface.callback('acceptCall', function(data, cb)
    cb(1)

    local passengers = Config.AttachAllUnitsInVehicleToCall and getVehiclePassengerIds() or nil
    TriggerServerEvent('sm_dispatch:server:acceptCall', data.id or data, passengers)

    if data.coords then
        SetNewWaypoint(data.coords.x, data.coords.y)
    end
end)

local FORWARD_CALLBACKS = {
    removeUnitFromGroup = 'sm_dispatch:server:removeUnitFromGroup',
    addUnitToGroup = 'sm_dispatch:server:addUnitToGroup',
    updateGroupName = 'sm_dispatch:server:updateGroupName',
    setUnitValue = 'sm_dispatch:server:setUnitValue',
    removeCall = 'sm_dispatch:server:removeCall',
}

for callbackName, serverEvent in pairs(FORWARD_CALLBACKS) do
    interface.callback(callbackName, function(data, cb)
        cb(1)
        TriggerServerEvent(serverEvent, data)
    end)
end

local PASSTHROUGH_EVENTS = {
    'setUnitValue',
    'removeUnitFromGroup', 'addUnitToGroup', 'updateGroupName',
    'addUnit', 'removeUnit', 'addUnitToCall',
}

for i = 1, #PASSTHROUGH_EVENTS do
    local name = PASSTHROUGH_EVENTS[i]

    RegisterNetEvent('sm_dispatch:client:' .. name, function(data)
        sendUI({ action = name, data = data })
    end)
end

RegisterNetEvent('sm_dispatch:client:addCall', function(data)
    local dispatchIndex = getCurrentDispatchIndex()
    if not dispatchIndex then return end

    local neededItem = Config.Dispatch[dispatchIndex].neededItem
    if neededItem and getItemCount(neededItem) <= 0 then return end

    if isAudioEnabled() then
        Alerts.playCallSound(data)
    end

    createCallBlip(data)
    data.distance = formatDistance(data.coords)

    if Config.Dispatch[dispatchIndex].pages.notification and not state.initSent then
        mountFrame()

        local snapshot = fetchDispatchData()
        if snapshot then pushInitPayload(dispatchIndex, snapshot) end
    end

    sendUI({ action = 'addCall', data = data })
end)

local callNotifyDuration = Config.Alerts.call and Config.Alerts.call.notifyDuration or 12000

RegisterNetEvent('sm_dispatch:client:notify', function(notifyType, localeKey)
    lib.notify({
        type = notifyType,
        description = L(localeKey),
        duration = callNotifyDuration,
    })
end)

RegisterNetEvent('sm_dispatch:client:callReply', function(data)
    local responder = data.callsign and sformat('[%s] %s', data.callsign, data.responder)
        or data.responder

    lib.notify({
        type = 'info',
        title = L('reply_title', tostring(data.publicId)),
        description = sformat('%s: %s', responder, data.message),
        duration = callNotifyDuration,
    })
end)

RegisterNetEvent('sm_dispatch:client:callAnswered', function(data)
    local responder = data.callsign and sformat('[%s] %s', data.callsign, data.responder)
        or data.responder

    lib.notify({
        type = 'success',
        title = L('call'),
        description = sformat('%s: %s', responder, data.message),
        duration = callNotifyDuration,
    })
end)

RegisterNetEvent('sm_dispatch:client:removeCall', function(callId)
    removeCallBlip(callId)
    sendUI({ action = 'removeCall', data = callId })
end)

local function refreshDispatchState()
    local dispatchIndex = getCurrentDispatchIndex()

    if not dispatchIndex then
        clearAllCallBlips()

        if state.frameMounted then
            sendUI({ action = 'reset' })
        end

        return
    end

    if not state.frameMounted then return end

    local dispatchData = fetchDispatchData()
    if not dispatchData then return end

    pushInitPayload(dispatchIndex, dispatchData)
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    TriggerServerEvent('sm_dispatch:server:playerLoaded')
    refreshDispatchState()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function()
    TriggerServerEvent('sm_dispatch:server:jobUpdated')
    refreshDispatchState()
end)

RegisterNetEvent('QBCore:Client:SetDuty', function()
    TriggerServerEvent('sm_dispatch:server:jobUpdated')
    refreshDispatchState()
end)

---@param name string
---@param description string
---@param key string
---@param handler function
local function registerKey(name, description, key, handler)
    if not key then return end

    RegisterCommand(name, function()
        CreateThread(handler)
    end, false)

    RegisterKeyMapping(name, description, 'keyboard', key)
end

registerKey('dispatch:callmanager', 'Dispatch: Call Manager', Config.Controls.callManager, function()
    toggleUI('callManager')
end)

registerKey('dispatch:sidebar', 'Dispatch: Sidebar', Config.Controls.sidebar, function()
    toggleUI('sidebar')
end)

registerKey('dispatch:togglefocus', L('toggle_focus'), Config.Controls.toggleFocus, function()
    toggleFocus()
end)

local function openLayoutEditor()
    if state.editing then return end

    local dispatchIndex = getCurrentDispatchIndex()

    if not dispatchIndex then
        return lib.notify({ type = 'error', description = L('editor_no_permission') })
    end

    local snapshot = fetchDispatchData()
    if not snapshot then return end

    state.editing = true
    mountFrame()

    pushInitPayload(dispatchIndex, snapshot)

    interface.focus(true, true)
    sendUI({ action = 'openLayoutEditor' })
end

local function closeLayoutEditor()
    if not state.editing then return end

    state.editing = false
    sendUI({ action = 'closeLayoutEditor' })

    applyFocus()

    if not isFrameNeeded() then
        unmountFrame()
    end
end

interface.callback('openLayoutEditor', function(_, cb)
    cb(1)
    CreateThread(openLayoutEditor)
end)

interface.callback('closeLayoutEditor', function(_, cb)
    cb(1)
    closeLayoutEditor()
end)

RegisterCommand('dispatcheditor', function()
    CreateThread(openLayoutEditor)
end, false)

local callKeys = Config.Controls.calls

if callKeys then
    registerKey('dispatch:callnext', 'Dispatch: Next Call', callKeys.next, function()
        sendUI({ action = 'navigateCall', data = 'next' })
    end)

    registerKey('dispatch:callprev', 'Dispatch: Previous Call', callKeys.previous, function()
        sendUI({ action = 'navigateCall', data = 'previous' })
    end)

    registerKey('dispatch:callaccept', 'Dispatch: Accept Call', callKeys.accept, function()
        sendUI({ action = 'acceptFocusedCall' })
    end)
end

local panicConfig = Config.Alerts.panicButton

if panicConfig and panicConfig.enable then
    registerKey('dispatch:panic', 'Dispatch: Panic Button', Config.Controls.panicButton, function()
        local dispatchIndex = getCurrentDispatchIndex()
        if not dispatchIndex or not Config.Dispatch[dispatchIndex].panicButton then return end

        if not Util.hasPermission(dispatchIndex, 'panicButton', getJobName(), getGrade()) then return end

        local now = GetGameTimer()
        if lastPanicTime and (now - lastPanicTime) < panicConfig.cooldown then return end
        lastPanicTime = now

        Alerts.panic(dispatchIndex)
    end)
end

local exportWrapper = require 'export_wrapper'

local function addCallAsync(callData)
    CreateThread(function()
        AddCall(callData)
    end)
end

exportWrapper('tk_dispatch', 'addCall', addCallAsync)

exportWrapper('tk_dispatch', 'toggleUI', function(page)
    CreateThread(function()
        toggleUI(page)
    end)
end)

local function buildPlayerData()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    return {
        vehicle = getVehicleData(GetVehiclePedIsIn(ped, false)),
        gender = getGender(),
        location = getStreetLabel(coords),
        direction = getCompassDirection(GetEntityHeading(ped)),
        weapon = getWeaponLabel(ped),
    }
end

exportWrapper('tk_dispatch', 'getPlayerData', buildPlayerData)
exportWrapper('sm_dispatch', 'addCall', addCallAsync)
exportWrapper('sm_dispatch', 'getPlayerData', buildPlayerData)
exportWrapper('sm_dispatch', 'toggleUI', function(page)
    CreateThread(function()
        toggleUI(page)
    end)
end)

Bridge.send = sendUI
Bridge.getLayout = getLayout
Bridge.strings = Util.strings

---@param key string
---@param enabled boolean
function Bridge.hold(key, enabled)
    if enabled then
        state.holds[key] = true
        mountFrame()
        return
    end

    if not state.holds[key] then return end

    state.holds[key] = nil

    if not isFrameNeeded() then
        unmountFrame()
    end
end

---@param enabled boolean
function Bridge.focus(enabled)
    state.focusHold = enabled
    applyFocus()
end

local moduleContext = {
    cache = cache,
    addCall = AddCall,
    buildPlayerData = buildPlayerData,
    getJobName = getJobName,
    isDead = isDead,
    getCurrentDispatchIndex = getCurrentDispatchIndex,
}

Alerts.bind(moduleContext)
Compat.register(moduleContext)

CreateThread(function()
    while not getJobName() do Wait(500) end

    TriggerServerEvent('sm_dispatch:server:playerLoaded')

    Alerts.start()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    clearAllCallBlips()
end)
