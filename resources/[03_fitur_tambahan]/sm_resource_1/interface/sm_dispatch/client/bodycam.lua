local Config = localmodule 'config.bodycam'
local Util = localmodule 'config.util'
local Bridge = localmodule 'modules.bridge'

local exportWrapper = require 'export_wrapper'

local L = Util.L

local Wait = Wait
local CreateThread = CreateThread
local GetGameTimer = GetGameTimer
local DoesEntityExist = DoesEntityExist
local GetEntityCoords = GetEntityCoords
local GetEntityHeading = GetEntityHeading
local SetEntityCoords = SetEntityCoords
local SetCamRot = SetCamRot
local IsPedInAnyVehicle = IsPedInAnyVehicle
local GetPlayerFromServerId = GetPlayerFromServerId
local GetPlayerPed = GetPlayerPed
local NetworkDoesNetworkIdExist = NetworkDoesNetworkIdExist
local NetworkGetEntityFromNetworkId = NetworkGetEntityFromNetworkId
local SetFollowPedCamViewMode = SetFollowPedCamViewMode
local mrandom = math.random
local sformat = string.format

local STREAM_TIMEOUT = 5000
local STREAM_POLL = 50
local FADE_TIME = 800
local FOLLOW_DISTANCE_SQ = 150.0 * 150.0
local HEAD_BONE = 46240
local TABLET_MODEL = `prop_cs_tablet`
local TABLET_DICT = 'amb@code_human_in_bus_passenger_idles@female@tablet@idle_a'
local OFF_RELEASE_DELAY = 1200

local bodycamOn = false
local busy = false
local hudHidden = false
local unitInfo = nil
local watch = nil
local recording = nil
local recordsOpen = false
local recordsPortal = nil
local recordsPayload = nil
local tabletProp = nil
local releaseToken = 0
local ownDashcams = {}
local setBodycam

local function noop() end

---@param description string
---@param notifyType string?
local function notify(description, notifyType)
    lib.notify({ description = description, type = notifyType or 'inform' })
end

---@return boolean
local function isAllowedJob()
    local job = QBPlayerData.job
    return job ~= nil and Config.Jobs[job.name] == true
end

---@return table
local function buildUnitInfo()
    local charinfo = QBPlayerData.charinfo or {}
    local metadata = QBPlayerData.metadata or {}
    local job = QBPlayerData.job or {}

    return {
        department = job.label or job.name,
        grade = type(job.grade) == 'table' and job.grade.name or nil,
        body = sformat('BODY %d', GetPlayerServerId(PlayerId())),
        serial = sformat('X%dN', mrandom(100000, 999999)),
        callsign = metadata.callsign,
        name = sformat('%s %s', charinfo.firstname or '', charinfo.lastname or ''),
    }
end

---@param toggled boolean?
local function sendState(toggled)
    Bridge.send({
        action = 'bodycamState',
        data = {
            toggled = toggled == true,
            active = bodycamOn,
            hidden = hudHidden,
            unit = unitInfo,
            layout = Bridge.getLayout(),
            locales = Bridge.strings,
        },
    })
end

local function sendWatch()
    Bridge.send({
        action = 'bodycamWatch',
        data = watch and {
            kind = watch.kind,
            title = watch.title,
            subtitle = watch.subtitle,
            exitKey = Config.ExitKey,
        } or false,
    })
end

---@param enabled boolean
local function setInventoryBusy(enabled)
    LocalPlayer.state:set('invBusy', enabled, false)
    LocalPlayer.state:set('invHotkeys', not enabled, false)
end

---@param ped number
local function playTablet(ped)
    if tabletProp then return end

    if not lib.requestModel(TABLET_MODEL, 5000) or not lib.requestAnimDict(TABLET_DICT, 5000) then return end

    local coords = GetEntityCoords(ped)
    tabletProp = CreateObject(TABLET_MODEL, coords.x, coords.y, coords.z + 0.2, true, true, false)

    AttachEntityToEntity(tabletProp, ped, GetPedBoneIndex(ped, 28422), -0.05, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
    TaskPlayAnim(ped, TABLET_DICT, 'idle_a', 3.0, -8.0, -1, 49, 0, false, false, false)

    SetModelAsNoLongerNeeded(TABLET_MODEL)
    RemoveAnimDict(TABLET_DICT)
end

---@param ped number
local function stopTablet(ped)
    StopAnimTask(ped, TABLET_DICT, 'idle_a', 1.0)

    if tabletProp and DoesEntityExist(tabletProp) then
        DetachEntity(tabletProp, true, true)
        DeleteEntity(tabletProp)
    end

    tabletProp = nil
end

local function watchItem()
    local item = Config.Item

    CreateThread(function()
        while bodycamOn do
            Wait(2500)

            if bodycamOn and (ox_inventory:Search('count', item) or 0) < 1 then
                setBodycam(false)
            end
        end
    end)
end

---@param enabled boolean
function setBodycam(enabled)
    if enabled == bodycamOn then return end

    if enabled then
        if not lib.callback.await('sm_dispatch:bodycam:setActive', false, true) then
            return notify(L('bodycam_not_allowed'), 'error')
        end

        bodycamOn = true
        unitInfo = buildUnitInfo()
        releaseToken = releaseToken + 1

        Bridge.hold('bodycam', true)
        sendState(true)
        watchItem()

        return notify(L('bodycam_activated'), 'success')
    end

    bodycamOn = false

    lib.callback('sm_dispatch:bodycam:setActive', false, noop, false)

    sendState(true)

    releaseToken = releaseToken + 1
    local token = releaseToken

    SetTimeout(OFF_RELEASE_DELAY, function()
        if token == releaseToken and not bodycamOn then
            Bridge.hold('bodycam', false)
        end
    end)

    notify(L('bodycam_deactivated'))
end

AddEventHandler('sm_bodycamx:bodycamstatus', function()
    if busy or watch then return end
    if not isAllowedJob() then return notify(L('bodycam_not_allowed'), 'error') end

    busy = true

    local enabling = not bodycamOn
    local completed = lib.progressBar({
        duration = 2500,
        label = L(enabling and 'bodycam_activating' or 'bodycam_deactivating'),
        useWhileDead = false,
        canCancel = true,
        disable = { combat = true },
        anim = { dict = 'clothingtie', clip = 'try_tie_positive_a' },
    })

    if completed then
        setBodycam(enabling)
    else
        notify(L('bodycam_cancelled'), 'error')
    end

    busy = false
end)

---@param model number
---@return string
local function getVehicleLabel(model)
    local name = GetDisplayNameFromVehicleModel(model)
    local label = GetLabelText(name)

    return label ~= 'NULL' and label or name
end

AddEventHandler('sm_bodycamx:toggleCarCam', function()
    if busy then return end
    if not isAllowedJob() then return notify(L('bodycam_not_allowed'), 'error') end

    local ped = cache.ped
    local vehicle = GetVehiclePedIsIn(ped, false)

    if vehicle == 0 then return notify(L('bodycam_not_in_vehicle'), 'error') end
    if GetPedInVehicleSeat(vehicle, -1) ~= ped then return notify(L('bodycam_not_driver'), 'error') end

    local vehicleClass = GetVehicleClass(vehicle)
    if not Config.DashcamClasses[vehicleClass] then return notify(L('bodycam_vehicle_not_allowed'), 'error') end

    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    local enabling = not ownDashcams[netId]

    busy = true

    local completed = lib.progressBar({
        duration = 2500,
        label = L(enabling and 'dashcam_activating' or 'dashcam_deactivating'),
        useWhileDead = false,
        canCancel = true,
        disable = { car = true, move = true, combat = true, sprint = true },
        anim = { dict = 'veh@submersible@ds@base', clip = 'change_station', flag = 49 },
    })

    if not completed then
        busy = false
        return notify(L('bodycam_cancelled'), 'error')
    end

    local result = lib.callback.await('sm_dispatch:bodycam:toggleDashcam', false, netId, getVehicleLabel(GetEntityModel(vehicle)), vehicleClass)

    busy = false

    if result == nil then
        return notify(L('bodycam_not_allowed'), 'error')
    end

    ownDashcams[netId] = result or nil
    notify(L(result and 'dashcam_activated' or 'dashcam_deactivated'), 'success')
end)

---@param ped number
---@param hidden boolean
local function hidePlayer(ped, hidden)
    FreezeEntityPosition(ped, hidden)
    SetEntityVisible(ped, not hidden, false)
    SetEntityCollision(ped, not hidden, not hidden)
    SetEntityInvincible(ped, hidden)
    NetworkSetEntityInvisibleToNetwork(ped, hidden)
end

local function waitForFade(fadeOut)
    local deadline = GetGameTimer() + FADE_TIME + 1500

    if fadeOut then
        DoScreenFadeOut(FADE_TIME)
        while not IsScreenFadedOut() and GetGameTimer() < deadline do Wait(50) end
    else
        DoScreenFadeIn(FADE_TIME)
    end
end

---@param current table
---@return number
local function resolveTarget(current)
    if current.self then return cache.ped end

    if current.kind == 'dash' then
        if not NetworkDoesNetworkIdExist(current.id) then return 0 end

        local vehicle = NetworkGetEntityFromNetworkId(current.id)
        return DoesEntityExist(vehicle) and vehicle or 0
    end

    local player = GetPlayerFromServerId(current.id)
    if player == -1 then return 0 end

    local ped = GetPlayerPed(player)
    return (ped ~= 0 and DoesEntityExist(ped)) and ped or 0
end

---@param current table
---@return number
local function waitForTarget(current)
    local deadline = GetGameTimer() + STREAM_TIMEOUT

    repeat
        local target = resolveTarget(current)
        if target ~= 0 then return target end

        Wait(STREAM_POLL)
    until GetGameTimer() > deadline

    return 0
end

---@param current table
---@param target number
local function attachCamera(current, target)
    local cam = current.cam

    if current.kind == 'dash' then
        local offset = Config.VehicleOffsets[GetEntityModel(target)] or Config.DefaultVehicleOffset
        AttachCamToVehicleBone(cam, target, GetEntityBoneIndexByName(target, 'windscreen'), true, 0.0, 0.0, 0.0, offset.x, offset.y, offset.z, true)
        return
    end

    current.inVehicle = IsPedInAnyVehicle(target, false)

    if current.inVehicle then
        AttachCamToPedBone(cam, target, HEAD_BONE, 0.1, 0.25, -0.1, true)
    else
        AttachCamToPedBone(cam, target, HEAD_BONE, 0.1, 0.025, 0.1, true)
    end
end

---@param lost boolean
---@param instant boolean?
local function endWatch(lost, instant)
    local current = watch
    if not current then return end

    watch = nil

    TriggerServerEvent('sm_dispatch:bodycam:stopWatch')

    if not instant then waitForFade(true) end

    local ped = cache.ped

    RenderScriptCams(false, false, 0, true, false)

    if current.cam and DoesCamExist(current.cam) then
        DestroyCam(current.cam, false)
    end

    ClearTimecycleModifier()

    if current.self then
        stopTablet(ped)
        FreezeEntityPosition(ped, false)
    else
        hidePlayer(ped, false)

        local back = current.returnCoords
        SetEntityCoords(ped, back.x, back.y, back.z, false, false, false, false)
        SetEntityHeading(ped, back.w)
    end

    setInventoryBusy(false)
    sendWatch()
    Bridge.hold('watch', false)

    if not instant then waitForFade(false) end

    if lost then notify(L('bodycam_feed_lost'), 'error') end
end

---@param current table
local function runWatchLoop(current)
    local target = current.target
    local isDash = current.kind == 'dash'
    local tick = 0
    local lostSince = nil

    while watch == current do
        Wait(isDash and 500 or 50)
        tick = tick + 1

        local valid = target ~= 0 and DoesEntityExist(target)

        if valid and not isDash then
            SetCamRot(current.cam, 0.0, 0.0, GetEntityHeading(target), 2)
        end

        if isDash or tick % 40 == 0 then
            if not valid then
                target = resolveTarget(current)

                if target ~= 0 then
                    current.target = target
                    attachCamera(current, target)
                    lostSince = nil
                else
                    lostSince = lostSince or GetGameTimer()

                    if GetGameTimer() - lostSince > STREAM_TIMEOUT then
                        return endWatch(true)
                    end
                end
            else
                lostSince = nil

                if not isDash and IsPedInAnyVehicle(target, false) ~= current.inVehicle then
                    attachCamera(current, target)
                end

                if not current.self then
                    local ped = cache.ped
                    local own = GetEntityCoords(ped)
                    local pos = GetEntityCoords(target)
                    local dx, dy, dz = own.x - pos.x, own.y - pos.y, own.z - pos.z

                    if dx * dx + dy * dy + dz * dz > FOLLOW_DISTANCE_SQ then
                        SetEntityCoords(ped, pos.x, pos.y, pos.z - 100.0, false, false, false, false)
                    end
                end
            end
        end
    end
end

---@param portalIndex number
---@param kind 'body'|'dash'
---@param id number
---@param title string
---@param subtitle string
local function watchFeed(portalIndex, kind, id, title, subtitle)
    if watch or busy then return end

    busy = true

    local coords = lib.callback.await('sm_dispatch:bodycam:startWatch', false, portalIndex, kind, id)

    if not coords then
        busy = false
        return notify(L('bodycam_feed_unavailable'), 'error')
    end

    local ped = cache.ped
    local origin = GetEntityCoords(ped)

    local current = {
        kind = kind,
        id = id,
        title = title,
        subtitle = subtitle,
        self = kind == 'body' and id == GetPlayerServerId(PlayerId()),
        returnCoords = vec4(origin.x, origin.y, origin.z - 1.0, GetEntityHeading(ped)),
    }

    watch = current
    setInventoryBusy(true)
    waitForFade(true)

    if current.self then
        playTablet(ped)
        FreezeEntityPosition(ped, true)
    else
        hidePlayer(ped, true)
        SetEntityCoords(ped, coords.x, coords.y, coords.z - 100.0, false, false, false, false)
    end

    local target = waitForTarget(current)

    if target == 0 or watch ~= current then
        busy = false
        endWatch(true, true)
        waitForFade(false)
        return
    end

    current.target = target
    current.cam = CreateCam('DEFAULT_SCRIPTED_FLY_CAMERA', true)

    attachCamera(current, target)

    if kind == 'dash' then
        SetCamFov(current.cam, 80.0)
        SetTimecycleModifier(Config.CameraEffect.dashcam)
        SetTimecycleModifierStrength(1.0)
    else
        SetCamFov(current.cam, 100.0)
        SetCamRot(current.cam, 0.0, 0.0, GetEntityHeading(target), 2)
        ShakeCam(current.cam, 'HAND_SHAKE', 1.0)
        SetCamShakeAmplitude(current.cam, 2.0)
        SetTimecycleModifier(Config.CameraEffect.bodycam)
        SetTimecycleModifierStrength(0.5)
    end

    RenderScriptCams(true, false, 0, true, false)

    Bridge.hold('watch', true)
    sendWatch()
    waitForFade(false)

    busy = false

    runWatchLoop(current)
end

RegisterNetEvent('sm_dispatch:bodycam:feedLost', function()
    if watch then endWatch(true) end
end)

RegisterCommand('bodycamexit', function()
    if watch and not busy then
        CreateThread(function() endWatch(false) end)
    end
end, false)

RegisterKeyMapping('bodycamexit', 'Bodycam: Exit feed', 'keyboard', Config.ExitKey)

---@param portal table
---@return boolean
local function canUsePortal(portal)
    local job = QBPlayerData.job
    if not job then return false end

    return not portal.access or portal.access[job.name] == true
end

---@param portalIndex number
local function openPortal(portalIndex)
    local feeds = lib.callback.await('sm_dispatch:bodycam:getFeeds', false, portalIndex)
    if not feeds then return notify(L('bodycam_not_allowed'), 'error') end

    local bodyOptions = {}
    local bodycams = feeds.bodycams

    for i = 1, #bodycams do
        local unit = bodycams[i]

        bodyOptions[i] = {
            title = unit.name,
            description = sformat('%s | %s', unit.job, unit.rank),
            icon = 'video',
            onSelect = function()
                CreateThread(function()
                    watchFeed(portalIndex, 'body', unit.id, unit.name, sformat('%s: %d', L('bodycam_cam_id'), unit.id))
                end)
            end,
        }
    end

    if #bodyOptions == 0 then
        bodyOptions[1] = { title = L('bodycam_no_feeds'), disabled = true }
    end

    local dashOptions = {}
    local dashcams = feeds.dashcams

    for i = 1, #dashcams do
        local dashcam = dashcams[i]

        dashOptions[i] = {
            title = dashcam.model,
            description = L('bodycam_plate', dashcam.plate, dashcam.name),
            icon = 'car',
            onSelect = function()
                CreateThread(function()
                    watchFeed(portalIndex, 'dash', dashcam.netId, dashcam.model, dashcam.plate)
                end)
            end,
        }
    end

    if #dashOptions == 0 then
        dashOptions[1] = { title = L('bodycam_no_feeds'), disabled = true }
    end

    lib.registerContext({
        id = 'sm_bodycam_bodies',
        title = L('bodycam_active_bodycams'),
        menu = 'sm_bodycam_portal',
        options = bodyOptions,
    })

    lib.registerContext({
        id = 'sm_bodycam_dashes',
        title = L('bodycam_active_dashcams'),
        menu = 'sm_bodycam_portal',
        options = dashOptions,
    })

    lib.registerContext({
        id = 'sm_bodycam_portal',
        title = L('bodycam_portal'),
        options = {
            {
                title = L('bodycam_active_bodycams'),
                description = tostring(#bodycams),
                icon = 'user',
                menu = 'sm_bodycam_bodies',
            },
            {
                title = L('bodycam_active_dashcams'),
                description = tostring(#dashcams),
                icon = 'car',
                menu = 'sm_bodycam_dashes',
            },
        },
    })

    lib.showContext('sm_bodycam_portal')
end

---@param portalIndex number
local function openRecordControl(portalIndex)
    local feeds = lib.callback.await('sm_dispatch:bodycam:getFeeds', false, portalIndex)
    if not feeds then return notify(L('bodycam_not_allowed'), 'error') end

    local options = {}
    local bodycams = feeds.bodycams

    for i = 1, #bodycams do
        local unit = bodycams[i]
        local isRecording = unit.recording

        options[i] = {
            title = unit.name,
            description = sformat('%s | %s - %s', unit.job, unit.rank, L(isRecording and 'bodycam_stop_record' or 'bodycam_start_record')),
            icon = isRecording and 'stop' or 'record-vinyl',
            iconColor = isRecording and '#e03131' or nil,
            onSelect = function()
                CreateThread(function()
                    lib.callback.await('sm_dispatch:bodycam:setRemoteRecording', false, portalIndex, unit.id, not isRecording)
                    Wait(300)
                    openRecordControl(portalIndex)
                end)
            end,
        }
    end

    if #options == 0 then
        options[1] = { title = L('bodycam_no_feeds'), disabled = true }
    end

    lib.registerContext({
        id = 'sm_bodycam_record_control',
        title = L('bodycam_record_control'),
        options = options,
    })

    lib.showContext('sm_bodycam_record_control')
end

local function sendRecords()
    Bridge.send({
        action = 'bodycamRecords',
        data = recordsOpen and {
            open = true,
            records = recordsPayload.records,
            jobLabel = recordsPayload.jobLabel,
            canDelete = recordsPayload.canDelete,
        } or { open = false },
    })
end

---@param portalIndex number
local function openRecords(portalIndex)
    if recordsOpen or watch then return end

    local payload = lib.callback.await('sm_dispatch:bodycam:getRecordings', false, portalIndex)
    if not payload then return notify(L('bodycam_not_allowed'), 'error') end

    recordsOpen = true
    recordsPortal = portalIndex
    recordsPayload = payload

    Bridge.hold('records', true)
    Bridge.focus(true)
    sendRecords()
    playTablet(cache.ped)
end

local function closeRecords()
    if not recordsOpen then return end

    recordsOpen = false
    recordsPortal = nil
    recordsPayload = nil

    Bridge.focus(false)
    sendRecords()
    stopTablet(cache.ped)

    SetTimeout(50, function()
        if not recordsOpen then
            Bridge.hold('records', false)
        end
    end)
end

interface.callback('bodycamCloseRecords', function(_, cb)
    cb(1)
    closeRecords()
end)

interface.callback('bodycamDeleteRecording', function(data, cb)
    CreateThread(function()
        local portalIndex = recordsPortal
        local recordId = type(data) == 'table' and tonumber(data.id)

        if not recordsOpen or not portalIndex or not recordId then return cb(false) end

        local rows = lib.callback.await('sm_dispatch:bodycam:deleteRecording', false, portalIndex, recordId)

        if rows and recordsPayload then
            recordsPayload.records = rows
        end

        cb(rows or false)
    end)
end)

CreateThread(function()
    local portals = Config.Portals

    for i = 1, #portals do
        local portal = portals[i]

        ox_target:addSphereZone({
            coords = portal.coords,
            radius = portal.radius,
            debug = false,
            drawSprite = false,
            options = {
                {
                    name = sformat('sm_bodycam_portal_%d', i),
                    label = L('bodycam_portal_open'),
                    icon = 'fas fa-video',
                    distance = 2.5,
                    canInteract = function() return canUsePortal(portal) end,
                    onSelect = function() CreateThread(function() openPortal(i) end) end,
                },
                {
                    name = sformat('sm_bodycam_records_%d', i),
                    label = L('bodycam_records_open'),
                    icon = 'fas fa-list',
                    distance = 2.5,
                    canInteract = function() return canUsePortal(portal) end,
                    onSelect = function() CreateThread(function() openRecords(i) end) end,
                },
                {
                    name = sformat('sm_bodycam_control_%d', i),
                    label = L('bodycam_record_control'),
                    icon = 'fas fa-record-vinyl',
                    distance = 2.5,
                    canInteract = function() return canUsePortal(portal) end,
                    onSelect = function() CreateThread(function() openRecordControl(i) end) end,
                },
            },
        })
    end
end)

local function forceFirstPerson()
    if not Config.ForceFirstPerson then return end

    CreateThread(function()
        SetTimecycleModifier(Config.CameraEffect.bodycam)
        SetTimecycleModifierStrength(0.5)

        while recording do
            SetFollowPedCamViewMode(4)
            Wait(0)
        end

        SetFollowPedCamViewMode(1)

        if not watch then ClearTimecycleModifier() end
    end)
end

RegisterNetEvent('sm_dispatch:bodycam:startRecording', function(duration)
    if not bodycamOn or recording then
        lib.callback('sm_dispatch:bodycam:recordingFailed', false, noop)
        return
    end

    recording = 'pending'

    Bridge.hold('recording', true)
    Bridge.send({ action = 'bodycamRecord', data = { duration = tonumber(duration) or Config.RecordTime } })
    forceFirstPerson()
end)

RegisterNetEvent('sm_dispatch:bodycam:stopRecording', function()
    if recording then
        Bridge.send({ action = 'bodycamStopRecord' })
    end
end)

interface.callback('bodycamRecordStarted', function(_, cb)
    cb(1)
    if recording then recording = 'active' end
end)

interface.callback('bodycamRequestUpload', function(_, cb)
    CreateThread(function()
        cb(lib.callback.await('sm_dispatch:bodycam:requestUpload', false) or false)
    end)
end)

interface.callback('bodycamSaveRecording', function(data, cb)
    CreateThread(function()
        local url = type(data) == 'table' and data.url
        if type(url) ~= 'string' then return cb(false) end

        local coords = GetEntityCoords(cache.ped)
        local streetHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)

        cb(lib.callback.await('sm_dispatch:bodycam:saveRecording', false, url, GetStreetNameFromHashKey(streetHash)) == true)
    end)
end)

---@param success boolean
local function finishRecording(success)
    if not recording then return end

    recording = nil

    if not success then
        lib.callback('sm_dispatch:bodycam:recordingFailed', false, noop)
    end

    notify(L(success and 'bodycam_record_saved' or 'bodycam_record_failed'), success and 'success' or 'error')

    SetTimeout(50, function()
        if not recording then
            Bridge.hold('recording', false)
        end
    end)
end

interface.callback('bodycamRecordDone', function(data, cb)
    cb(1)
    finishRecording(type(data) == 'table' and data.success == true)
end)

Bridge.onReady(function()
    if recording == 'active' then
        finishRecording(false)
    end

    if bodycamOn then sendState() end
    if watch and watch.cam then sendWatch() end
    if recordsOpen then sendRecords() end
end)

local function shutdown()
    if watch then endWatch(false, true) end
    if recordsOpen then closeRecords() end

    if bodycamOn then
        setBodycam(false)
    end
end

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    if bodycamOn and not (job and Config.Jobs[job.name]) then
        CreateThread(function() setBodycam(false) end)
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    CreateThread(shutdown)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    if watch then endWatch(false, true) end

    stopTablet(cache.ped)
end)

exportWrapper('sm_bodycam', 'suspendProp', noop)
exportWrapper('sm_bodycam', 'restoreProp', noop)

exportWrapper('sm_bodycam', 'isBodycamActive', function()
    return bodycamOn
end)

exportWrapper('sm_bodycam', 'hideBodycamHud', function(hide)
    hide = hide == true
    if hide == hudHidden then return end

    hudHidden = hide

    if bodycamOn then sendState() end
end)
