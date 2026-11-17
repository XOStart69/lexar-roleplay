local config = localmodule 'config.shared'
local media = localmodule 'modules.media'

local Wait = Wait
local CreateThread = CreateThread
local GetGameTimer = GetGameTimer
local GetCloudTimeAsInt = GetCloudTimeAsInt
local GetEntityCoords = GetEntityCoords
local GetEntityModel = GetEntityModel
local GetEntityHeading = GetEntityHeading
local GetOffsetFromEntityInWorldCoords = GetOffsetFromEntityInWorldCoords
local GetClosestObjectOfType = GetClosestObjectOfType
local NetworkGetNetworkIdFromEntity = NetworkGetNetworkIdFromEntity
local NetworkGetEntityIsNetworked = NetworkGetEntityIsNetworked
local NetworkIsPlayerActive = NetworkIsPlayerActive
local PlayerId = PlayerId
local RequestModel = RequestModel
local HasModelLoaded = HasModelLoaded
local SetModelAsNoLongerNeeded = SetModelAsNoLongerNeeded
local CreateObjectNoOffset = CreateObjectNoOffset
local AttachEntityToEntity = AttachEntityToEntity
local SetEntityCollision = SetEntityCollision
local SetEntityRotation = SetEntityRotation
local FreezeEntityPosition = FreezeEntityPosition
local DoesEntityExist = DoesEntityExist
local DeleteEntity = DeleteEntity
local CreateDui = CreateDui
local DestroyDui = DestroyDui
local IsDuiAvailable = IsDuiAvailable
local SetDuiUrl = SetDuiUrl
local SendDuiMessage = SendDuiMessage
local GetDuiHandle = GetDuiHandle
local SendDuiMouseMove = SendDuiMouseMove
local SendDuiMouseDown = SendDuiMouseDown
local SendDuiMouseUp = SendDuiMouseUp
local CreateRuntimeTxd = CreateRuntimeTxd
local CreateRuntimeTextureFromDuiHandle = CreateRuntimeTextureFromDuiHandle
local IsNamedRendertargetRegistered = IsNamedRendertargetRegistered
local RegisterNamedRendertarget = RegisterNamedRendertarget
local IsNamedRendertargetLinked = IsNamedRendertargetLinked
local LinkNamedRendertarget = LinkNamedRendertarget
local GetNamedRendertargetRenderId = GetNamedRendertargetRenderId
local ReleaseNamedRendertarget = ReleaseNamedRendertarget
local GetDefaultScriptRendertargetRenderId = GetDefaultScriptRendertargetRenderId
local SetTextRenderId = SetTextRenderId
local SetScriptGfxDrawOrder = SetScriptGfxDrawOrder
local SetScriptGfxDrawBehindPausemenu = SetScriptGfxDrawBehindPausemenu
local DrawSprite = DrawSprite
local DrawRect = DrawRect
local RequestScaleformMovie = RequestScaleformMovie
local HasScaleformMovieLoaded = HasScaleformMovieLoaded
local SetScaleformMovieAsNoLongerNeeded = SetScaleformMovieAsNoLongerNeeded
local BeginScaleformMovieMethod = BeginScaleformMovieMethod
local ScaleformMovieMethodAddParamTextureNameString = ScaleformMovieMethodAddParamTextureNameString
local ScaleformMovieMethodAddParamInt = ScaleformMovieMethodAddParamInt
local EndScaleformMovieMethod = EndScaleformMovieMethod
local DrawScaleformMovie_3dSolid = DrawScaleformMovie_3dSolid
local DisableIdleCamera = DisableIdleCamera
local DisableControlAction = DisableControlAction
local IsDisabledControlPressed = IsDisabledControlPressed
local IsDisabledControlJustPressed = IsDisabledControlJustPressed
local mathHuge = math.huge
local mathMax = math.max
local mathFloor = math.floor
local mathCeil = math.ceil
local jsonEncode = json.encode
local tableRemove = table.remove
local sformat = string.format
local pairs = pairs

local text = config.text
local models = config.models
local screens = config.screens
local vehicleCfg = config.vehicle
local fadeStart = config.fadeStart
local keepMargin = config.duiKeepMargin
local toolCfg = config.screenTool

local PLAYER_URL = ('https://cfx-nui-%s/interface/sm_tv/web/build/dui/player.html'):format(cache.resource)
local TXD_NAME = 'sm_tv_dui'
local TEX_PREFIX = 'screen'
local SCALEFORM = 'sm_tvscreen'
local DUI_WIDTH, DUI_HEIGHT = 1280, 720
local BLOCK_TOLERANCE = 0.5
local MODEL_TIMEOUT = 5000

local SLIDERS = {
    streamable = { hover = { 75, 700 }, base = 75, span = 39, pad = 1, line = 700, rest = 800 },
    dailymotion = { hover = { 1150, 702 }, base = 1155, span = 99, pad = 1, line = 702, rest = 750 },
    twitch = { base = 70, span = 99, pad = 6, line = 690, rest = 750 },
    vimeo = { base = 1120, span = 21, pad = 1, line = 698, rest = 750 },
    soundcloud = { hover = { 870, 675 }, base = 670, span = -99, pad = -1, line = 870, rest = 750, vertical = true },
}

for i = 1, #models do
    models[i].hash = joaat(models[i].model)
end

local panelHash = joaat(vehicleCfg.panel)
local vehicleOffsets = {}
for i = 1, #vehicleCfg.models do
    local name = vehicleCfg.models[i]
    vehicleOffsets[joaat(name)] = vehicleCfg.offsets[name] or vehicleCfg.default
end

local tvs = {}
local tvList = {}
local bucket = 0
local muted = false

local active = nil
local activeDistance = 0.0
local renderToken = 0
local ownedTargets = {}

local dui = nil
local duiState = 0
local duiPage = nil
local duiReady = false
local duiToken = 0
local slideToken = 0
local sentVolume = -1
local runtimeTxd = nil
local texName = TEX_PREFIX
local duiSerial = 0

local panels = {}
local panelNet = nil
local spawnedProps = {}

local ui = { open = false, ready = false, id = nil, pending = nil }
local uiEnabled = interface.init(false)
local toolActive = false

---@param message string
---@param kind? string
local function notify(message, kind)
    lib.notify({ title = text.title, description = message, type = kind or 'error' })
end

---@param hash number
---@return boolean
local function loadModel(hash)
    RequestModel(hash)
    local deadline = GetGameTimer() + MODEL_TIMEOUT
    while not HasModelLoaded(hash) do
        if GetGameTimer() > deadline then
            return false
        end
        Wait(10)
    end
    return true
end

---@param data table
local function sendDui(data)
    if dui then
        SendDuiMessage(dui, jsonEncode(data))
    end
end

---@return boolean
local function ensureDui()
    if duiState == 2 then
        return true
    end

    if duiState == 1 then
        while duiState == 1 do
            Wait(50)
        end
        return duiState == 2
    end

    duiState = 1
    duiPage = 'player'
    duiReady = false

    local handle = CreateDui(PLAYER_URL, DUI_WIDTH, DUI_HEIGHT)
    local deadline = GetGameTimer() + 10000
    while not IsDuiAvailable(handle) and GetGameTimer() < deadline do
        Wait(50)
    end

    if not IsDuiAvailable(handle) then
        DestroyDui(handle)
        duiState = 0
        duiPage = nil
        return false
    end

    if not runtimeTxd then
        runtimeTxd = CreateRuntimeTxd(TXD_NAME)
    end
    duiSerial = duiSerial + 1
    texName = TEX_PREFIX .. duiSerial
    CreateRuntimeTextureFromDuiHandle(runtimeTxd, texName, GetDuiHandle(handle))
    dui = handle
    duiState = 2
    return true
end

local function releaseDui()
    if duiState ~= 2 then return end
    duiToken = duiToken + 1
    slideToken = slideToken + 1
    duiState = 0
    duiPage = nil
    duiReady = false
    local handle = dui
    dui = nil
    DestroyDui(handle)
end

---@return number
local function effectiveVolume()
    local tv = active
    if muted or not tv then
        return 0
    end

    local volume = tv.volume
    local range = tv.range
    if range > 0 then
        local start = range * fadeStart
        if activeDistance > start then
            volume = volume * mathMax(0.0, (range - activeDistance) / (range - start))
        end
    end

    return mathFloor(volume + 0.5)
end

local function sendPlayer()
    local tv = active
    if not tv or duiPage ~= 'player' or not duiReady then return end

    local item = tv.media
    if not item then
        sendDui({ action = 'idle' })
        return
    end

    local volume = effectiveVolume()
    sentVolume = volume
    sendDui({
        action = 'play',
        type = item.type,
        src = item.src,
        time = mathMax(0, GetCloudTimeAsInt() - tv.startedAt),
        volume = volume,
    })
end

local function openPlayerPage()
    duiToken = duiToken + 1
    duiPage = 'player'
    duiReady = false
    SetDuiUrl(dui, PLAYER_URL)
end

---@param x number
---@param y number
local function moveMouse(x, y)
    if dui then
        SendDuiMouseMove(dui, x, y)
    end
end

---@param x number
---@param y number
local function click(x, y)
    if not dui then return end
    SendDuiMouseMove(dui, x, y)
    Wait(5)
    if not dui then return end
    SendDuiMouseDown(dui, 'left')
    Wait(5)
    if not dui then return end
    SendDuiMouseUp(dui, 'left')
end

---@param kind string
---@param volume number
---@param token number
local function slideVolume(kind, volume, token)
    local slider = SLIDERS[kind]
    if not slider then return end

    slideToken = slideToken + 1
    local slide = slideToken

    local hover = slider.hover
    if hover then
        moveMouse(hover[1], hover[2])
        Wait(250)
        moveMouse(hover[1], hover[2])
        Wait(500)
    else
        Wait(250)
    end
    if token ~= duiToken or slide ~= slideToken then return end

    local pos = slider.base + mathCeil(volume * slider.span / 100 + slider.pad)
    local x, y = pos, slider.line
    if slider.vertical then
        x, y = slider.line, pos
    end

    moveMouse(x, y)
    Wait(250)
    if token ~= duiToken or slide ~= slideToken then return end

    click(x, y)
    Wait(250)

    if slider.vertical then
        moveMouse(slider.line, slider.rest)
    else
        moveMouse(x, slider.rest)
    end
end

---@param kind string
---@param token number
local function autoplay(kind, token)
    if kind == 'twitch' then
        for y = 440, 500, 5 do
            if token ~= duiToken then return end
            click(550, y)
            Wait(300)
        end
    elseif kind == 'soundcloud' then
        Wait(1500)
        if token == duiToken then
            click(1200, 400)
        end
    end
end

---@param tv table
local function loadEmbed(tv)
    local item = tv.media
    duiToken = duiToken + 1
    local token = duiToken
    duiPage = 'embed'
    duiReady = false
    SetDuiUrl(dui, media.embed(item, mathMax(0, GetCloudTimeAsInt() - tv.startedAt)))

    CreateThread(function()
        autoplay(item.type, token)
        if token == duiToken then
            slideVolume(item.type, muted and 0 or tv.volume, token)
        end
    end)
end

local function applyMedia()
    local tv = active
    if not tv or not ensureDui() or active ~= tv then return end

    local item = tv.media
    if item and not media.isPlayer(item.type) then
        loadEmbed(tv)
        return
    end

    if duiPage ~= 'player' then
        openPlayerPage()
        return
    end

    sendPlayer()
end

---@param includeEmbed boolean
local function refreshVolume(includeEmbed)
    local tv = active
    if not tv or duiState ~= 2 or not tv.media then return end

    if duiPage == 'embed' then
        if includeEmbed then
            local token = duiToken
            local kind = tv.media.type
            local volume = muted and 0 or tv.volume
            CreateThread(function()
                slideVolume(kind, volume, token)
            end)
        end
        return
    end

    if not duiReady then return end

    local volume = effectiveVolume()
    if volume ~= sentVolume then
        sentVolume = volume
        sendDui({ action = 'volume', volume = volume })
    end
end

---@param tv table?
---@return string?
local function targetName(tv)
    if not tv then return nil end
    if tv.kind == 'vehicle' then
        return vehicleCfg.target
    elseif tv.kind == 'object' then
        return tv.model.target
    end
end

---@param name string
---@param hash number
---@return number
local function registerTarget(name, hash)
    if not IsNamedRendertargetRegistered(name) then
        RegisterNamedRendertarget(name, false)
        ownedTargets[name] = true
    end
    if not IsNamedRendertargetLinked(hash) then
        LinkNamedRendertarget(hash)
    end
    return GetNamedRendertargetRenderId(name)
end

---@param renderId number
---@param defaultId number
---@param black boolean
local function drawTarget(renderId, defaultId, black)
    SetTextRenderId(renderId)
    SetScriptGfxDrawOrder(4)
    SetScriptGfxDrawBehindPausemenu(true)
    if black then
        DrawRect(0.5, 0.5, 1.0, 1.0, 0, 0, 0, 255)
    else
        DrawSprite(TXD_NAME, texName, 0.5, 0.5, 1.0, 1.0, 0.0, 255, 255, 255, 255)
    end
    SetTextRenderId(defaultId)
    SetScriptGfxDrawBehindPausemenu(false)
end

---@param handle number
local function bindScaleform(handle)
    BeginScaleformMovieMethod(handle, 'SET_TEXTURE')
    ScaleformMovieMethodAddParamTextureNameString(TXD_NAME)
    ScaleformMovieMethodAddParamTextureNameString(texName)
    ScaleformMovieMethodAddParamInt(0)
    ScaleformMovieMethodAddParamInt(0)
    ScaleformMovieMethodAddParamInt(1920)
    ScaleformMovieMethodAddParamInt(1080)
    EndScaleformMovieMethod()
end

---@param isCurrent fun(): boolean
---@return number?
local function loadScaleform(isCurrent)
    local handle = RequestScaleformMovie(SCALEFORM)
    local deadline = GetGameTimer() + MODEL_TIMEOUT
    while not HasScaleformMovieLoaded(handle) do
        if not isCurrent() or GetGameTimer() > deadline then
            SetScaleformMovieAsNoLongerNeeded(handle)
            return nil
        end
        Wait(0)
    end
    bindScaleform(handle)
    return handle
end

---@param tv table
local function startRender(tv)
    renderToken = renderToken + 1
    local token = renderToken

    CreateThread(function()
        if tv.kind == 'screen' then
            local handle = loadScaleform(function() return token == renderToken end)
            if not handle then return end

            local screen = tv.screen
            local coords, rotation, scale = screen.coords, screen.rotation, screen.scale
            local x, y, z = coords.x, coords.y, coords.z
            local rx, ry, rz = rotation.x, rotation.y, rotation.z
            local sx, sy, sz = scale.x, scale.y, scale.z

            while token == renderToken do
                DrawScaleformMovie_3dSolid(handle, x, y, z, rx, ry, rz, 2.0, 2.0, 2.0, sx, sy, sz, 2)
                Wait(0)
            end

            SetScaleformMovieAsNoLongerNeeded(handle)
            return
        end

        local name = targetName(tv) or vehicleCfg.target
        local hash = tv.kind == 'vehicle' and panelHash or tv.model.hash
        local renderId = registerTarget(name, hash)
        local defaultId = GetDefaultScriptRendertargetRenderId()

        while token == renderToken do
            drawTarget(renderId, defaultId, false)
            Wait(0)
        end

        if targetName(active) == name then return end

        for _ = 1, 3 do
            drawTarget(renderId, defaultId, true)
            Wait(0)
        end

        if ownedTargets[name] and targetName(active) ~= name then
            ReleaseNamedRendertarget(name)
            ownedTargets[name] = nil
        end
    end)
end

local function deactivate()
    active = nil
    renderToken = renderToken + 1
    if duiState ~= 2 then return end

    if duiPage == 'embed' then
        openPlayerPage()
    elseif duiReady then
        sendDui({ action = 'stop' })
    end
end

---@param tv table
---@param distance number
local function activate(tv, distance)
    if not ensureDui() then return end
    active = tv
    activeDistance = distance
    sentVolume = -1
    applyMedia()
    if active == tv then
        startRender(tv)
    end
end

---@return boolean keep
local function scan()
    local count = #tvList
    if count == 0 then
        if active then deactivate() end
        return false
    end

    local pos = GetEntityCoords(cache.ped)
    local best, bestDist = nil, mathHuge
    local keep = false

    for i = 1, count do
        local tv = tvList[i]
        if tv.kind == 'vehicle' then
            if panelNet and tv.netId == panelNet then
                best, bestDist = tv, 0.0
                keep = true
                break
            end
        elseif tv.bucket == bucket then
            local distance = #(pos - tv.coords)
            if distance < tv.range + keepMargin then
                keep = true
            end
            if distance < tv.range and distance < bestDist then
                best, bestDist = tv, distance
            end
        end
    end

    if best and best.kind == 'object' then
        local model = best.model
        local object = GetClosestObjectOfType(pos.x, pos.y, pos.z, model.distance, model.hash, false, false, false)
        if object == 0 or #(GetEntityCoords(object) - best.coords) > BLOCK_TOLERANCE then
            best = nil
        end
    end

    if best ~= active then
        if active then deactivate() end
        if best then activate(best, bestDist) end
        return keep
    end

    if active then
        activeDistance = bestDist
        refreshVolume(false)
    end
    return keep
end

---@param tv table
---@return table
local function uiState(tv)
    local item = tv.media
    return {
        id = tv.id,
        label = tv.label,
        volume = tv.volume,
        media = item and { label = item.label, url = item.url } or false,
    }
end

---@param tv table
local function pushUi(tv)
    if ui.open and ui.ready and ui.id == tv.id then
        interface.send({ action = 'update', data = uiState(tv) })
    end
end

---@param notifyServer boolean
local function closeUi(notifyServer)
    if not ui.open then return end
    local id = ui.id
    ui.open = false
    ui.ready = false
    ui.id = nil
    ui.pending = nil
    interface.focus(false, false)
    interface.hide()
    DisableIdleCamera(false)
    if notifyServer and id then
        TriggerServerEvent('sm_tv:close', id)
    end
end

---@param state table
local function openUi(state)
    if not uiEnabled then return end
    ui.open = true
    ui.ready = false
    ui.id = state.id
    ui.pending = uiState(tvs[state.id] or state)
    interface.show()
    interface.focus(true, true)
    DisableIdleCamera(true)
end

---@param state table
---@return table?
local function prepare(state)
    local kind = state.kind
    if kind == 'object' then
        local model = models[state.index]
        if not model then return nil end
        state.model = model
        state.range = model.distance
    elseif kind == 'screen' then
        local screen = screens[state.index]
        if not screen then return nil end
        state.screen = screen
        state.coords = screen.coords
        state.range = screen.distance
    else
        state.range = 0.0
    end
    return state
end

---@param state table
local function upsert(state)
    local tv = tvs[state.id]
    if tv then
        tv.media = state.media
        tv.volume = state.volume
        tv.startedAt = state.startedAt
        return
    end

    tv = prepare(state)
    if not tv then return end

    tvs[tv.id] = tv
    tvList[#tvList + 1] = tv
end

---@param id number
local function removeTv(id)
    local tv = tvs[id]
    if not tv then return end

    tvs[id] = nil
    for i = #tvList, 1, -1 do
        if tvList[i] == tv then
            tableRemove(tvList, i)
            break
        end
    end

    if active == tv then
        deactivate()
    end
    if ui.id == id then
        closeUi(false)
    end
end

local function clearPanels()
    for i = #panels, 1, -1 do
        local object = panels[i]
        if DoesEntityExist(object) then
            DeleteEntity(object)
        end
        panels[i] = nil
    end
    panelNet = nil
end

---@param vehicle number
local function spawnPanels(vehicle)
    local offsets = vehicleOffsets[GetEntityModel(vehicle)]
    if not offsets or not NetworkGetEntityIsNetworked(vehicle) then return end

    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    if vehicleCfg.requireInstall and not lib.callback.await('sm_tv:installed', false, netId) then return end
    if cache.vehicle ~= vehicle or not loadModel(panelHash) or cache.vehicle ~= vehicle then return end

    clearPanels()
    local coords = GetEntityCoords(vehicle)
    for i = 1, #offsets do
        local entry = offsets[i]
        local offset, rotation = entry.offset, entry.rotation
        local object = CreateObjectNoOffset(panelHash, coords.x, coords.y, coords.z, false, false, false)
        SetEntityCollision(object, false, false)
        AttachEntityToEntity(object, vehicle, 0, offset.x, offset.y, offset.z, rotation.x, rotation.y, rotation.z, false, false, false, false, 2, true)
        panels[i] = object
    end
    SetModelAsNoLongerNeeded(panelHash)
    panelNet = netId
end

---@param lock string|false
---@return table?
local function findTarget(lock)
    local vehicle = cache.vehicle
    if not lock and vehicle and panelNet and panelNet == NetworkGetNetworkIdFromEntity(vehicle) then
        return { kind = 'vehicle', netId = panelNet }
    end

    local pos = GetEntityCoords(cache.ped)
    local best, bestDist = nil, mathHuge

    for i = 1, #screens do
        local screen = screens[i]
        if (screen.item or false) == lock then
            local distance = #(pos - screen.coords)
            if distance < screen.control and distance < bestDist then
                best, bestDist = { kind = 'screen', index = i }, distance
            end
        end
    end

    if lock then
        return best
    end

    for i = 1, #models do
        local model = models[i]
        local object = GetClosestObjectOfType(pos.x, pos.y, pos.z, model.control, model.hash, false, false, false)
        if object ~= 0 then
            local coords = GetEntityCoords(object)
            local distance = #(pos - coords)
            if distance < model.control and distance < bestDist then
                best, bestDist = { kind = 'object', index = i, coords = coords }, distance
            end
        end
    end

    return best
end

---@param state boolean
local function setMuted(state)
    if muted == state then return end
    muted = state
    refreshVolume(true)
end

RegisterNUICallback('sm_tv:duiReady', function(_, cb)
    cb(1)
    if duiPage == 'player' then
        duiReady = true
        sendPlayer()
    end
end)

interface.callback('ready', function(_, cb)
    cb(true)
    ui.ready = true
    if ui.open and ui.pending then
        interface.send({ action = 'open', data = ui.pending })
        ui.pending = nil
    end
end)

interface.callback('close', function(_, cb)
    cb(true)
    closeUi(true)
end)

interface.callback('play', function(data, cb)
    local id = ui.id
    local url = type(data) == 'table' and data.url
    if not id or type(url) ~= 'string' then
        return cb({ ok = false })
    end
    local ok, message = lib.callback.await('sm_tv:play', false, id, url)
    cb({ ok = ok == true, message = message })
end)

interface.callback('volume', function(data, cb)
    cb(true)
    local volume = type(data) == 'table' and tonumber(data.volume)
    if ui.id and volume then
        TriggerServerEvent('sm_tv:volume', ui.id, volume)
    end
end)

interface.callback('off', function(_, cb)
    cb(true)
    local id = ui.id
    closeUi(false)
    if id then
        TriggerServerEvent('sm_tv:off', id)
    end
end)

RegisterNetEvent('sm_tv:remote', function(lock)
    if ui.open or toolActive then return end

    local target = findTarget(lock or false)
    if not target then
        return notify(text.noTv)
    end

    local state = lib.callback.await('sm_tv:open', false, target)
    if state then
        upsert(state)
        openUi(state)
    end
end)

RegisterNetEvent('sm_tv:add', function(state)
    upsert(state)
end)

RegisterNetEvent('sm_tv:media', function(id, item, startedAt)
    local tv = tvs[id]
    if not tv then return end

    tv.media = item
    tv.startedAt = startedAt
    if tv == active then
        sentVolume = -1
        applyMedia()
    end
    pushUi(tv)
end)

RegisterNetEvent('sm_tv:volume', function(id, volume)
    local tv = tvs[id]
    if not tv then return end

    tv.volume = volume
    if tv == active then
        refreshVolume(true)
    end
    pushUi(tv)
end)

RegisterNetEvent('sm_tv:remove', removeTv)

RegisterNetEvent('sm_tv:bucket', function(value)
    bucket = value
end)

RegisterNetEvent('sm_tv:installed', function(netId)
    local vehicle = cache.vehicle
    if vehicle and NetworkGetNetworkIdFromEntity(vehicle) == netId then
        spawnPanels(vehicle)
    end
end)

AddEventHandler('sm_audio:streamerMode', function(state)
    setMuted(state == true)
end)

if vehicleCfg.enabled then
    lib.onCache('vehicle', function(vehicle)
        clearPanels()
        if vehicle then
            CreateThread(function()
                spawnPanels(vehicle)
            end)
        end
    end)
end

for i = 1, #config.props do
    local prop = config.props[i]
    local hash = joaat(prop.model)
    local coords, rotation = prop.coords, prop.rotation

    lib.points.new({
        coords = coords,
        distance = config.propDistance,
        onEnter = function()
            if spawnedProps[i] or not loadModel(hash) then return end
            local object = CreateObjectNoOffset(hash, coords.x, coords.y, coords.z, false, false, false)
            SetEntityRotation(object, rotation.x, rotation.y, rotation.z, 2, false)
            FreezeEntityPosition(object, true)
            SetModelAsNoLongerNeeded(hash)
            spawnedProps[i] = object
        end,
        onExit = function()
            local object = spawnedProps[i]
            if object and DoesEntityExist(object) then
                DeleteEntity(object)
            end
            spawnedProps[i] = nil
        end,
    })
end

CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) do
        Wait(500)
    end

    local ok, streamer = pcall(function()
        return exports[cache.resource]:isStreamerMode()
    end)
    muted = ok and streamer == true

    local data = lib.callback.await('sm_tv:list', false)
    if data then
        bucket = data.bucket or 0
        local list = data.tvs
        for i = 1, #list do
            upsert(list[i])
        end
    end

    if vehicleCfg.enabled and cache.vehicle then
        spawnPanels(cache.vehicle)
    end

    local interval = config.scanInterval
    while true do
        local keep = scan()
        if not keep and not active and not toolActive and duiState == 2 then
            releaseDui()
        end
        Wait(interval)
    end
end)

local TOOL_DISABLED = { 23, 24, 25, 36, 37, 38, 44, 45, 74, 140, 141, 142, 157, 158, 159, 160, 172, 173, 174, 175, 177, 191, 199, 263 }

---@param mode string
---@param axis string
local function showToolHelp(mode, axis)
    lib.showTextUI(sformat('[Panah] Geser  \n[Q/E] Naik/Turun  \n[Shift] Mode: %s  \n[F] Balik arah  \n[H] Sumbu skala: %s  \n[Num+/Num-] Skala  \n[Enter] Salin  \n[Backspace] Batal', mode, axis))
end

RegisterNetEvent('sm_tv:screenTool', function()
    if toolActive or ui.open then return end
    toolActive = true

    if not ensureDui() then
        toolActive = false
        return notify('Gagal membuat DUI layar')
    end

    local handle = loadScaleform(function() return toolActive end)
    if not handle then
        toolActive = false
        return notify(sformat('Scaleform %s gagal dimuat', SCALEFORM))
    end

    local ped = cache.ped
    local start = GetOffsetFromEntityInWorldCoords(ped, 0.0, 2.0, 1.0)
    local x, y, z = start.x, start.y, start.z
    local rx, ry, rz = 0.0, 0.0, (GetEntityHeading(ped) + 180.0) % 360.0
    local sx, sy = 0.2, 0.1125
    local mode, axis = 'geser', 'x'
    local move, turn, grow = toolCfg.moveStep, toolCfg.rotateStep, toolCfg.scaleStep
    local disabled = TOOL_DISABLED
    local disabledCount = #disabled

    showToolHelp(mode, axis)

    while toolActive do
        for i = 1, disabledCount do
            DisableControlAction(0, disabled[i], true)
        end

        if IsDisabledControlJustPressed(0, 21) then
            mode = mode == 'geser' and 'putar' or 'geser'
            showToolHelp(mode, axis)
        end

        if IsDisabledControlJustPressed(0, 74) then
            axis = axis == 'x' and 'y' or 'x'
            showToolHelp(mode, axis)
        end

        if IsDisabledControlJustPressed(0, 23) then
            rz = (rz + 180.0) % 360.0
        end

        local up, down = IsDisabledControlPressed(0, 172), IsDisabledControlPressed(0, 173)
        local left, right = IsDisabledControlPressed(0, 174), IsDisabledControlPressed(0, 175)
        local rise, sink = IsDisabledControlPressed(0, 44), IsDisabledControlPressed(0, 38)

        if mode == 'geser' then
            if up then y = y + move elseif down then y = y - move end
            if left then x = x - move elseif right then x = x + move end
            if rise then z = z + move elseif sink then z = z - move end
        else
            if up then rx = rx + turn elseif down then rx = rx - turn end
            if left then ry = ry - turn elseif right then ry = ry + turn end
            if rise then rz = rz + turn elseif sink then rz = rz - turn end
        end

        if IsDisabledControlPressed(0, 96) then
            if axis == 'x' then sx = sx + grow else sy = sy + grow end
        elseif IsDisabledControlPressed(0, 97) then
            if axis == 'x' then sx = mathMax(0.01, sx - grow) else sy = mathMax(0.01, sy - grow) end
        end

        DrawScaleformMovie_3dSolid(handle, x, y, z, rx, ry, rz, 2.0, 2.0, 2.0, sx, sy, 1.0, 2)

        if IsDisabledControlJustPressed(0, 191) then
            local snippet = sformat(
                '{\n    label = \'Layar Baru\',\n    coords = vec3(%.6f, %.6f, %.6f),\n    rotation = vec3(%.6f, %.6f, %.6f),\n    scale = vec3(%.6f, %.6f, 1.0),\n    distance = 100.0,\n    control = 50.0,\n},',
                x, y, z, rx, ry, rz, sx, sy)
            lib.setClipboard(snippet)
            print(snippet)
            notify('Snippet layar disalin ke clipboard', 'success')
            toolActive = false
        elseif IsDisabledControlJustPressed(0, 177) then
            toolActive = false
        end

        Wait(0)
    end

    lib.hideTextUI()
    SetScaleformMovieAsNoLongerNeeded(handle)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    clearPanels()
    for i, object in pairs(spawnedProps) do
        if DoesEntityExist(object) then
            DeleteEntity(object)
        end
        spawnedProps[i] = nil
    end
    for name in pairs(ownedTargets) do
        ReleaseNamedRendertarget(name)
    end
    if dui then
        DestroyDui(dui)
    end
    if ui.open then
        DisableIdleCamera(false)
    end
end)
