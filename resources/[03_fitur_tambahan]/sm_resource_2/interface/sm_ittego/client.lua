local config = localmodule 'config'
local flow = localmodule 'modules.flow'
local createScenes = localmodule 'modules.scenes'
local interact = exports.rhd_interact
local infoui = exports.rhd_infoui
local hasFrame = interface.init(false)

local Wait = Wait
local CreateThread = CreateThread
local GetGameTimer = GetGameTimer
local GetFrameTime = GetFrameTime
local DoesEntityExist = DoesEntityExist
local DeleteEntity = DeleteEntity
local SetEntityAsMissionEntity = SetEntityAsMissionEntity
local CreateObject = CreateObject
local SetModelAsNoLongerNeeded = SetModelAsNoLongerNeeded
local GetEntityCoords = GetEntityCoords
local GetEntityHeading = GetEntityHeading
local SetEntityCoords = SetEntityCoords
local SetEntityHeading = SetEntityHeading
local SetEntityAlpha = SetEntityAlpha
local ResetEntityAlpha = ResetEntityAlpha
local SetEntityCollision = SetEntityCollision
local FreezeEntityPosition = FreezeEntityPosition
local GetEntityHealth = GetEntityHealth
local SetEntityHealth = SetEntityHealth
local IsEntityDead = IsEntityDead
local ClearPedTasks = ClearPedTasks
local GetOffsetFromEntityInWorldCoords = GetOffsetFromEntityInWorldCoords
local GetHudScreenPositionFromWorldPosition = GetHudScreenPositionFromWorldPosition
local GetHeadingFromVector_2d = GetHeadingFromVector_2d
local NetworkGetNetworkIdFromEntity = NetworkGetNetworkIdFromEntity
local NetworkDoesNetworkIdExist = NetworkDoesNetworkIdExist
local NetworkRegisterEntityAsNetworked = NetworkRegisterEntityAsNetworked
local NetworkIsPlayerActive = NetworkIsPlayerActive
local GetPlayerFromServerId = GetPlayerFromServerId
local GetPlayerPed = GetPlayerPed
local DisableControlAction = DisableControlAction
local DisableAllControlActions = DisableAllControlActions
local EnableControlAction = EnableControlAction
local IsDisabledControlJustPressed = IsDisabledControlJustPressed
local GetGroundZFor_3dCoord = GetGroundZFor_3dCoord
local IsDisabledControlPressed = IsDisabledControlPressed
local CreateCamWithParams = CreateCamWithParams
local SetCamActive = SetCamActive
local RenderScriptCams = RenderScriptCams
local DestroyCam = DestroyCam
local GetGameplayCamFov = GetGameplayCamFov
local ClearFocus = ClearFocus
local IsScreenFadedOut = IsScreenFadedOut
local DoScreenFadeIn = DoScreenFadeIn
local fromCamera = lib.raycast.fromCamera
local pairs, type, tonumber, pcall = pairs, type, tonumber, pcall
local mfloor, mmax, mmin, sqrt = math.floor, math.max, math.min, math.sqrt

local LABELS = config.labels
local REASONS = LABELS.reasons
local MODELS = config.models
local CONTROL_PLACE = config.controls.place
local CONTROL_CANCEL = config.controls.cancel
local CONTROL_LEFT = config.controls.rotateLeft
local CONTROL_RIGHT = config.controls.rotateRight
local PLACE_DISTANCE = config.placeDistance
local INTERACT_DISTANCE = config.interactDistance
local DAMAGE = config.damagePerScene
local CHAIR = joaat(MODELS.Chair)
local STAGES = flow.stages
local MAIN_ACTIONS = {}
for i = 1, #STAGES.main.actions do
    MAIN_ACTIONS[STAGES.main.actions[i]] = true
end
local INFO_PLACE = 'sm_ittego:place'
local INTERACT_ID = 'sm_ittego_kit'
local RAY_FLAGS = 1 | 16
local RAY_DISTANCE = 20.0
local PLACE_BLOCKED = { 24, 25, 257, 140, 141, 142, CONTROL_PLACE, CONTROL_CANCEL, CONTROL_LEFT, CONTROL_RIGHT }
local PLACE_BLOCKED_COUNT = #PLACE_BLOCKED

---@type TortureState
local S = {
    scenes = {},
    objects = {},
    netIds = {},
    particles = {},
    coords = vec3(0.0, 0.0, 0.0),
    rotation = vec3(0.0, 0.0, 0.0),
    cam = 0,
    position = 0,
    otherPed = 0,
    started = false,
    inScene = false,
}

local kitPlaced = false
local placing = false
local busy = false
local selecting = false
local selectorCam = 0
local preview = 0
local trolleyEntity
local controlsLocked = false
local frameMounted = false
local frameReady = false
local menuStage
local pending

---@param text string
---@param kind? string
local function notify(text, kind)
    lib.notify({ title = LABELS.title, description = text, type = kind or 'error' })
end

---@param reason? string
local function notifyReason(reason)
    notify(REASONS[reason] or REASONS.invalid)
end

local function pushView()
    if not pending then return end
    interface.send({ action = 'open', data = pending })
    interface.focus(true, true)
end

---@param view 'players'|'scenes'|'menu'
---@param data table
local function openUi(view, data)
    if not hasFrame then return end
    data.view = view
    pending = data

    if frameReady then
        return pushView()
    end

    if not frameMounted then
        frameMounted = true
        interface.show()
    end
end

local function unmountLater()
    SetTimeout(50, function()
        if pending or not frameMounted or S.started then return end
        frameMounted = false
        frameReady = false
        interface.hide()
    end)
end

local function closeUi()
    if not pending then return end
    pending = nil
    menuStage = nil
    interface.focus(false, false)
    if frameReady then
        interface.send({ action = 'close' })
    end
    unmountLater()
end

---@param state boolean
local function setControls(state)
    if state == controlsLocked then return end
    controlsLocked = state
    if not state then return end

    CreateThread(function()
        while controlsLocked do
            DisableAllControlActions(0)
            EnableControlAction(0, 1, true)
            EnableControlAction(0, 2, true)
            EnableControlAction(0, 249, true)
            Wait(0)
        end
    end)
end

local function applyDamage()
    if DAMAGE <= 0 then return end
    local ped = cache.ped
    SetEntityHealth(ped, GetEntityHealth(ped) - DAMAGE)
end

---@param stage string
local function showMenu(stage)
    local data = STAGES[stage]
    if not data or not S.started then return end

    local actions = data.actions
    local buttons = {}
    for i = 1, #actions do
        local action = actions[i]
        buttons[i] = { action = action, label = LABELS.actions[action] or action }
    end

    openUi('menu', {
        title = LABELS.scenes[data.scene] or LABELS.title,
        buttons = buttons,
        exit = data.exit and { action = data.exit, label = LABELS.exit } or false,
    })
    menuStage = stage
end

local scenes = createScenes(S, { menu = showMenu, controls = setControls, damage = applyDamage })

---@param entity? integer
local function deleteLocal(entity)
    if entity and DoesEntityExist(entity) then
        SetEntityAsMissionEntity(entity, true, true)
        DeleteEntity(entity)
    end
end

---@param entity integer
---@return integer?
local function waitNetId(entity)
    local deadline = GetGameTimer() + 3000
    local netId = NetworkGetNetworkIdFromEntity(entity)
    while not NetworkDoesNetworkIdExist(netId) do
        if GetGameTimer() > deadline then return end
        NetworkRegisterEntityAsNetworked(entity)
        Wait(0)
        netId = NetworkGetNetworkIdFromEntity(entity)
    end
    return netId
end

---@param model string
---@param coords vector3
---@return integer? entity
---@return integer? netId
local function spawnNetworked(model, coords)
    local hash = joaat(model)
    if not pcall(lib.requestModel, hash, 5000) then return end
    local entity = CreateObject(hash, coords.x, coords.y, coords.z - 2.0, true, true, false)
    SetModelAsNoLongerNeeded(hash)
    if entity == 0 then return end
    return entity, waitNetId(entity)
end

local function removeInteract()
    if not trolleyEntity then return end
    interact:removeCoords(INTERACT_ID)
    trolleyEntity = nil
end

local function clearKit()
    removeInteract()
    scenes.stopAll()
    for key, entity in pairs(S.objects) do
        deleteLocal(entity)
        S.objects[key] = nil
    end
    kitPlaced = false
end

---@param target 0|255
local function fadePed(target)
    local ped = cache.ped
    local alpha = target == 0 and 255.0 or 0.0
    for _ = 1, 120 do
        local delta = GetFrameTime() * 500
        alpha = target == 0 and mmax(alpha - delta, 0.0) or mmin(alpha + delta, 255.0)
        SetEntityAlpha(ped, mfloor(alpha), false)
        if alpha == target then break end
        Wait(0)
    end
    if target == 255 then
        ResetEntityAlpha(ped)
    end
end

local function closeSelector()
    if not selecting then return end
    selecting = false
    ClearFocus()
    RenderScriptCams(false, true, 1000, true, false)
    if selectorCam ~= 0 then
        DestroyCam(selectorCam, false)
        selectorCam = 0
    end
    CreateThread(function() fadePed(255) end)
end

---@param coords vector3
---@return number x
---@return number y
local function project(coords)
    local _, x, y = GetHudScreenPositionFromWorldPosition(coords.x, coords.y, coords.z)
    return x * 100, y * 100
end

---@param key string
---@param coords vector3
---@return table
local function target(key, coords)
    local x, y = project(coords)
    return { type = key, label = LABELS.scenes[key] or key, x = x, y = y }
end

local function pickupKit()
    if busy or S.started then return end
    busy = true
    local ok, reason = lib.callback.await('sm_ittego:pickup', false)
    busy = false
    if not ok then return notifyReason(reason) end
    clearKit()
end

local function openPlayers()
    if busy or S.started or pending then return end
    busy = true
    local list, reason = lib.callback.await('sm_ittego:nearby', false)
    busy = false
    if not list then return notifyReason(reason) end
    if #list == 0 then return notifyReason('noPlayers') end
    openUi('players', { title = LABELS.selectPlayer, players = list })
end

local function openSelector()
    if selecting or pending or S.inScene or not S.started or S.position ~= 1 then return end

    local o = S.objects
    local trolley = o.Trolley
    if not trolley or not DoesEntityExist(trolley) then return end

    selecting = true
    local camPos = GetOffsetFromEntityInWorldCoords(trolley, 0.0, -0.8, 1.6)
    selectorCam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', camPos.x, camPos.y, camPos.z, -57.0, 0.0, GetEntityHeading(trolley), GetGameplayCamFov(), false, 0)
    SetCamActive(selectorCam, true)
    RenderScriptCams(true, true, 1000, true, false)
    CreateThread(function() fadePed(0) end)

    Wait(1000)
    if not selecting or not S.started then return closeSelector() end

    local clip1, clip2 = GetEntityCoords(o.Clip1), GetEntityCoords(o.Clip2)
    openUi('scenes', {
        title = LABELS.selectScene,
        scenes = {
            target('wrench', GetEntityCoords(o.Wrench)),
            target('syringe', GetEntityCoords(o.Syringe)),
            target('jerrycan', GetEntityCoords(o.Jerrycan) - vec3(0.0, 0.0, 0.3)),
            target('pullTooth', GetEntityCoords(o.Pliers)),
            target('electrocute', (clip1 + clip2) / 2),
        },
    })
end

local function requestEnd()
    TriggerTokenEvent('sm_ittego:server:end')
end

---@param action string
---@param stage? string
local function requestAction(action, stage)
    CreateThread(function()
        local ok, reason = lib.callback.await('sm_ittego:action', false, action)
        if ok then return end
        notifyReason(reason)
        if stage then showMenu(stage) end
    end)
end

local trolleyOptions = {
    {
        name = 'sm_ittego_victim',
        label = LABELS.selectPlayer,
        icon = 'fa-solid fa-user',
        distance = INTERACT_DISTANCE,
        canInteract = function() return not S.started and not busy end,
        onSelect = function() CreateThread(openPlayers) end,
    },
    {
        name = 'sm_ittego_pickup',
        label = LABELS.removeKit,
        icon = 'fa-solid fa-box',
        distance = INTERACT_DISTANCE,
        canInteract = function() return not S.started and not busy end,
        onSelect = function() CreateThread(pickupKit) end,
    },
    {
        name = 'sm_ittego_scene',
        label = LABELS.selectScene,
        icon = 'fa-solid fa-hand-fist',
        distance = INTERACT_DISTANCE,
        canInteract = function() return S.started and not S.inScene and not selecting end,
        onSelect = function() CreateThread(openSelector) end,
    },
    {
        name = 'sm_ittego_end',
        label = LABELS.endTorture,
        icon = 'fa-solid fa-xmark',
        distance = INTERACT_DISTANCE,
        canInteract = function() return S.started and not S.inScene and not selecting end,
        onSelect = requestEnd,
    },
}

local function addInteract()
    removeInteract()
    local trolley = S.objects.Trolley
    if not trolley or not DoesEntityExist(trolley) then return end
    trolleyEntity = trolley
    interact:addCoords({
        id = INTERACT_ID,
        coords = GetOffsetFromEntityInWorldCoords(trolley, 0.0, -0.6, 0.6),
        options = trolleyOptions,
    })
end

---@param coords vector3
---@param heading number
local function spawnKit(coords, heading)
    S.coords = coords
    S.rotation = vec3(0.0, 0.0, heading)

    for key, entity in pairs(S.objects) do
        deleteLocal(entity)
        S.objects[key] = nil
    end

    local netIds = {}
    for key, model in pairs(MODELS) do
        local entity, netId = spawnNetworked(model, coords)
        S.objects[key] = entity
        netIds[key] = netId
    end

    kitPlaced = true
    scenes.setupKit()

    if not lib.callback.await('sm_ittego:objects', false, netIds) then
        notifyReason('noObjects')
        return pickupKit()
    end

    Wait(500)
    addInteract()
end

local function placeKit()
    if placing or kitPlaced or S.started or cache.vehicle then return end
    if not pcall(lib.requestModel, CHAIR, 5000) then return end

    placing = true
    preview = CreateObject(CHAIR, 0.0, 0.0, 0.0, false, false, false)
    SetModelAsNoLongerNeeded(CHAIR)
    SetEntityAlpha(preview, 155, false)
    SetEntityCollision(preview, false, false)
    FreezeEntityPosition(preview, true)
    infoui:show({ id = INFO_PLACE, title = LABELS.title, icon = 'fa-solid fa-chair', description = LABELS.placeHint })

    local ped = cache.ped
    local offset = 0.0
    local chosen, heading

    while placing do
        for i = 1, PLACE_BLOCKED_COUNT do
            DisableControlAction(0, PLACE_BLOCKED[i], true)
        end

        local pos = GetEntityCoords(ped)
        local hit, _, endCoords = fromCamera(RAY_FLAGS, 4, RAY_DISTANCE)
        local x, y, z

        if hit then
            x, y, z = endCoords.x, endCoords.y, endCoords.z
        else
            local ahead = GetOffsetFromEntityInWorldCoords(ped, 0.0, 2.0, 0.0)
            x, y, z = ahead.x, ahead.y, nil
        end

        local dx, dy = x - pos.x, y - pos.y
        local dist = sqrt(dx * dx + dy * dy)
        if dist > PLACE_DISTANCE then
            local scale = PLACE_DISTANCE / dist
            x, y, z = pos.x + dx * scale, pos.y + dy * scale, nil
        end

        if not z then
            local found, groundZ = GetGroundZFor_3dCoord(x, y, pos.z + 1.5, false)
            z = found and groundZ or pos.z - 1.0
        end

        z = z + 0.4
        local h = GetHeadingFromVector_2d(x - pos.x, y - pos.y) + offset
        SetEntityCoords(preview, x, y, z, false, false, false, false)
        SetEntityHeading(preview, h)

        if IsDisabledControlJustPressed(0, CONTROL_PLACE) then
            chosen = vec3(x, y, z)
            heading = (h + 180.0) % 360.0
            break
        end

        if IsDisabledControlJustPressed(0, CONTROL_CANCEL) then break end

        if IsDisabledControlPressed(0, CONTROL_LEFT) then
            offset = offset + 50 * GetFrameTime()
        elseif IsDisabledControlPressed(0, CONTROL_RIGHT) then
            offset = offset - 50 * GetFrameTime()
        end

        Wait(0)
    end

    placing = false
    deleteLocal(preview)
    preview = 0
    infoui:remove(INFO_PLACE)

    if not chosen then return end

    local ok, reason = lib.callback.await('sm_ittego:place', false, { x = chosen.x, y = chosen.y, z = chosen.z }, heading)
    if not ok then return notifyReason(reason) end

    spawnKit(chosen, heading)
end

RegisterNetEvent('sm_ittego:client:place', function()
    if source == '' then return end
    CreateThread(placeKit)
end)

RegisterNetEvent('sm_ittego:client:notify', function(reason)
    if source == '' then return end
    notifyReason(reason)
end)

RegisterNetEvent('sm_ittego:client:start', function(other, coords, heading, position, netIds)
    if source == '' or S.started then return end

    S.coords = vec3(coords.x, coords.y, coords.z)
    S.rotation = vec3(0.0, 0.0, heading)
    S.position = position
    S.netIds = type(netIds) == 'table' and netIds or {}
    S.inScene = false

    if position == 1 then
        local deadline = GetGameTimer() + 5000
        local player = GetPlayerFromServerId(other)
        while (player == -1 or not NetworkIsPlayerActive(player) or GetPlayerPed(player) == 0) and GetGameTimer() < deadline do
            Wait(100)
            player = GetPlayerFromServerId(other)
        end

        local ped = player ~= -1 and GetPlayerPed(player) or 0
        if ped == 0 or not DoesEntityExist(ped) then
            S.position = 0
            return requestEnd()
        end

        S.otherPed = ped
        S.started = true
        deleteLocal(S.objects.Chair)
        S.objects.Chair = nil
        return
    end

    S.started = true
    local chair, netId = spawnNetworked(MODELS.Chair, S.coords)
    if not S.started or S.position ~= 2 then
        return deleteLocal(chair)
    end

    S.objects.Chair = chair
    scenes.seat(true)
    if netId then
        lib.callback.await('sm_ittego:objects', false, { Chair = netId })
    end
end)

RegisterNetEvent('sm_ittego:client:scene', function(action)
    if source == '' or not S.started then return end
    local scene = scenes[action]
    if scene and flow.results[action] then
        scene()
    end
end)

RegisterNetEvent('sm_ittego:client:end', function(reason)
    if source == '' or S.position == 0 then return end

    local position = S.position
    S.started = false
    closeSelector()
    closeUi()

    if reason then notifyReason(reason) end

    local ped = cache.ped
    if position == 1 then
        local chair, netId = spawnNetworked(MODELS.Chair, S.coords)
        S.objects.Chair = chair
        scenes.seat(false)
        ClearPedTasks(ped)
        if netId then
            lib.callback.await('sm_ittego:objects', false, { Chair = netId })
        end
        if S.inScene and S.objects.Trolley and DoesEntityExist(S.objects.Trolley) then
            scenes['default-exit']()
        end
    else
        local chair = S.objects.Chair
        if chair and DoesEntityExist(chair) then
            local pos = GetOffsetFromEntityInWorldCoords(chair, 0.0, -0.7, -0.4)
            SetEntityCoords(ped, pos.x, pos.y, pos.z, false, false, false, false)
        end
        deleteLocal(chair)
        S.objects.Chair = nil
        if S.inScene then
            scenes['default-exit']()
        end
        scenes.stopAll()
        ClearPedTasks(ped)
    end

    S.inScene = false
    setControls(false)
    S.position = 0
    S.otherPed = 0
    S.netIds = {}
    unmountLater()
end)

AddEventHandler('gameEventTriggered', function(name, args)
    if not S.started or name ~= 'CEventNetworkEntityDamage' then return end
    local ped = cache.ped
    if args[1] == ped and IsEntityDead(ped) then
        requestEnd()
    end
end)

if hasFrame then
    interface.callback('ready', function(_, cb)
        frameReady = true
        pushView()
        cb({})
    end)

    interface.callback('close', function(_, cb)
        cb({})
        local view = pending and pending.view
        if not view or view == 'menu' then return end
        closeUi()
        if view == 'scenes' then closeSelector() end
    end)

    interface.callback('select', function(data, cb)
        cb({})
        if not pending or pending.view ~= 'players' then return end
        closeUi()

        local id = type(data) == 'table' and tonumber(data.id)
        if not id then return end

        CreateThread(function()
            local ok, reason = lib.callback.await('sm_ittego:start', false, id)
            if not ok then notifyReason(reason) end
        end)
    end)

    interface.callback('scene', function(data, cb)
        cb({})
        if not pending or pending.view ~= 'scenes' then return end
        closeUi()
        closeSelector()

        local scene = type(data) == 'table' and data.scene
        if not MAIN_ACTIONS[scene] then return end
        requestAction(scene)
    end)

    interface.callback('action', function(data, cb)
        cb({})
        if not pending or pending.view ~= 'menu' then return end
        local stage = menuStage
        closeUi()

        local action = type(data) == 'table' and data.action
        if type(action) ~= 'string' or not flow.results[action] then return end
        requestAction(action, stage)
    end)
end

AddEventHandler('sm_ittego:client:forceClose', function()
    placing = false
    local view = pending and pending.view
    closeSelector()
    closeUi()
    if view == 'menu' and S.started then
        requestEnd()
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    placing = false
    deleteLocal(preview)
    infoui:remove(INFO_PLACE)
    removeInteract()
    setControls(false)
    scenes.stopFx()
    scenes.closeCam()

    if selecting then
        selecting = false
        RenderScriptCams(false, false, 0, true, false)
        if selectorCam ~= 0 then DestroyCam(selectorCam, false) end
    end

    local ped = cache.ped
    ResetEntityAlpha(ped)
    if S.started then ClearPedTasks(ped) end
    if IsScreenFadedOut() then DoScreenFadeIn(0) end
    if pending then SetNuiFocus(false, false) end
end)
