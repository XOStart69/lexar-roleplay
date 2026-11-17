local Config = localmodule 'config.shared'

interface.init(false)

local CreateThread = CreateThread
local DoesEntityExist = DoesEntityExist
local DeleteEntity = DeleteEntity
local GetEntityCoords = GetEntityCoords
local SetCamCoord = SetCamCoord
local PointCamAtCoord = PointCamAtCoord
local SetTimeout = SetTimeout
local sformat = string.format
local ssub = string.sub
local mrad = math.rad
local msin = math.sin
local mcos = math.cos
local mmax = math.max
local mmin = math.min

local STATE_KEY = 'scifiAssembly'
local IMAGE_BASE = 'nui://ox_inventory/web/images/%s'

local defaultSpawnPoint = Config.SpawnPoint
local spawnCoords = vec3(defaultSpawnPoint.x, defaultSpawnPoint.y, defaultSpawnPoint.z)
local ghostAlpha = Config.GhostAlpha
local buildAnim = Config.BuildAnim
local camConfig = Config.PreviewCam
local blueprints = Config.Blueprints
local blueprintCount = #blueprints

local blueprintByModel = {}
local spawnPointByModel = {}
for i = 1, blueprintCount do
    local blueprint = blueprints[i]
    blueprintByModel[blueprint.model] = blueprint
    spawnPointByModel[blueprint.model] = blueprint.spawn or defaultSpawnPoint
end

local camPoint = defaultSpawnPoint
---@type string|false|nil
local camPointModel = false
local camTargetZ = defaultSpawnPoint.z + camConfig.targetHeight
local camMinZ = defaultSpawnPoint.z + 0.3

local materialItems = {}
do
    local seen = {}
    for i = 1, blueprintCount do
        local materials = blueprints[i].materials
        for j = 1, #materials do
            local item = materials[j].item
            if not seen[item] then
                seen[item] = true
                materialItems[#materialItems + 1] = item
            end
        end
    end
end

local reasonMessages = {
    disabled = 'Perakitan kendaraan sci-fi sedang dinonaktifkan.',
    busy = 'Masih ada perakitan lain yang sedang berlangsung.',
    blocked = 'Area perakitan masih terhalang kendaraan.',
    far = 'Kamu terlalu jauh dari lokasi perakitan.',
    materials = 'Material di kantong kamu tidak mencukupi.',
    notselected = 'Pilih blueprint terlebih dahulu.',
    invalid = 'Blueprint tidak valid.',
    throttle = 'Tunggu sebentar.',
    nobuild = 'Tidak ada perakitan yang berlangsung.',
    interrupted = 'Perakitan terputus.',
    spawnfail = 'Kendaraan gagal dimunculkan, material dikembalikan.',
}

local currentState = GlobalState[STATE_KEY] or {}
local inRange = false
local uiOpen = false
local building = false
local ghostEntity = 0
local ghostModel = nil
local previewCam = nil
local camYaw = 0.0
local camPitch = 0.0
local camDistance = 0.0
local stationZone = nil
local itemInfo = nil
local pendingPayload = nil
local syncing = false
local resyncRequested = false

---@param description string
---@param notifyType? string
local function notify(description, notifyType)
    lib.notify({ title = 'Perakitan Sci-Fi', description = description, type = notifyType or 'inform' })
end

local function deleteGhost()
    if ghostEntity ~= 0 and DoesEntityExist(ghostEntity) then
        DeleteEntity(ghostEntity)
    end
    ghostEntity = 0
    ghostModel = nil
end

---@param model string
local function spawnGhost(model)
    local hash = joaat(model)
    if not IsModelInCdimage(hash) or not IsModelAVehicle(hash) then return end
    if not pcall(lib.requestModel, hash, 15000) then return end

    local spawnPoint = spawnPointByModel[model]
    local vehicle = CreateVehicle(hash, spawnPoint.x, spawnPoint.y, spawnPoint.z, spawnPoint.w, false, false)
    SetModelAsNoLongerNeeded(hash)
    if vehicle == 0 then return end

    SetVehicleOnGroundProperly(vehicle)
    FreezeEntityPosition(vehicle, true)
    SetEntityCollision(vehicle, false, false)
    SetEntityInvincible(vehicle, true)
    SetVehicleDoorsLocked(vehicle, 2)
    SetVehicleUndriveable(vehicle, true)
    SetVehicleEngineOn(vehicle, false, true, true)
    SetVehicleDirtLevel(vehicle, 0.0)
    SetEntityAlpha(vehicle, ghostAlpha, false)

    ghostEntity = vehicle
    ghostModel = model
end

local function applyState()
    local model = currentState.stage and currentState.model

    if not model or not (inRange or uiOpen) then
        if ghostEntity ~= 0 then deleteGhost() end
        return
    end

    if ghostModel ~= model or not DoesEntityExist(ghostEntity) then
        deleteGhost()
        spawnGhost(model)
    end
end

local function sync()
    if syncing then
        resyncRequested = true
        return
    end

    syncing = true
    repeat
        resyncRequested = false
        applyState()
    until not resyncRequested
    syncing = false
end

local function requestSync()
    CreateThread(sync)
end

---@return table
local function buildStatus()
    local state = currentState
    return {
        enabled = state.enabled == true,
        stage = state.stage or false,
        model = state.model or false,
        mine = state.owner ~= nil and state.owner == cache.serverId,
    }
end

---@param image string?
---@param item string
---@return string
local function resolveImage(image, item)
    if not image then return sformat(IMAGE_BASE, sformat('%s.png', item)) end
    local prefix = ssub(image, 1, 4)
    if prefix == 'http' or prefix == 'nui:' then return image end
    return sformat(IMAGE_BASE, image)
end

---@return table
local function getItemInfo()
    if itemInfo then return itemInfo end

    itemInfo = {}
    local items = exports.ox_inventory:Items()
    for i = 1, #materialItems do
        local name = materialItems[i]
        local data = items and items[name]
        itemInfo[name] = {
            label = data and data.label or name,
            image = resolveImage(data and data.client and data.client.image, name),
        }
    end
    return itemInfo
end

---@return table
local function buildPayload()
    local info = getItemInfo()
    local counts = exports.ox_inventory:Search('count', materialItems)
    if type(counts) ~= 'table' then counts = {} end

    local list = {}
    for i = 1, blueprintCount do
        local blueprint = blueprints[i]
        local materials = blueprint.materials
        local materialList = {}

        for j = 1, #materials do
            local material = materials[j]
            local item = material.item
            local itemData = info[item]
            materialList[j] = {
                item = item,
                label = itemData.label,
                image = itemData.image,
                count = material.count,
                have = counts[item] or 0,
            }
        end

        list[i] = {
            model = blueprint.model,
            name = blueprint.name,
            class = blueprint.class or '',
            description = blueprint.description or '',
            image = blueprint.image or false,
            materials = materialList,
        }
    end

    return {
        blueprints = list,
        status = buildStatus(),
    }
end

local function updatePreviewCam()
    if not previewCam then return end

    local yaw = mrad(camYaw)
    local pitch = mrad(camPitch)
    local horizontal = camDistance * mcos(pitch)
    local camZ = mmax(camTargetZ + camDistance * msin(pitch), camMinZ)

    SetCamCoord(previewCam, camPoint.x - msin(yaw) * horizontal, camPoint.y + mcos(yaw) * horizontal, camZ)
    PointCamAtCoord(previewCam, camPoint.x, camPoint.y, camTargetZ)
end

---@param model string|false
local function setCamTarget(model)
    if not previewCam or model == camPointModel then return end

    local blueprint = model and blueprintByModel[model]
    camPointModel = model
    camPoint = model and spawnPointByModel[model] or defaultSpawnPoint
    camTargetZ = camPoint.z + camConfig.targetHeight
    camMinZ = camPoint.z + 0.3
    camYaw = camPoint.w + camConfig.yawOffset
    camPitch = camConfig.pitch
    camDistance = blueprint and blueprint.camDistance or camConfig.distance

    SetFocusPosAndVel(camPoint.x, camPoint.y, camPoint.z, 0.0, 0.0, 0.0)
    updatePreviewCam()
end

local function startPreviewCam()
    if not camConfig.enabled or previewCam then return end

    previewCam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', camPoint.x, camPoint.y, camTargetZ, 0.0, 0.0, 0.0, camConfig.fov, false, 0)
    camPointModel = nil
    setCamTarget(currentState.stage and currentState.model or false)
    SetCamActive(previewCam, true)
    RenderScriptCams(true, true, 800, true, true)
end

local function stopPreviewCam()
    if not previewCam then return end
    RenderScriptCams(false, true, 600, true, true)
    DestroyCam(previewCam, false)
    ClearFocus()
    previewCam = nil
end

local function closeUI()
    if not uiOpen then return end
    uiOpen = false
    pendingPayload = nil

    interface.focus(false, false)
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    stopPreviewCam()

    local state = currentState
    if state.stage == 'preview' and state.owner == cache.serverId then
        TriggerTokenEvent('scifi_assembly:release')
    end

    SetTimeout(50, function()
        if not uiOpen then interface.hide() end
    end)

    requestSync()
end

local function openUI()
    if uiOpen or building then return end

    if not currentState.enabled then
        notify('Perakitan kendaraan sci-fi sedang dinonaktifkan. Tunggu Mercenary mengaktifkannya.', 'error')
        return
    end

    uiOpen = true
    pendingPayload = buildPayload()

    if not interface.show() then
        uiOpen = false
        pendingPayload = nil
        return
    end

    interface.focus(true, true)
    startPreviewCam()
    requestSync()
end

---@param duration number
---@param name string
local function runBuild(duration, name)
    building = true

    local finished = lib.progressBar({
        duration = duration,
        label = sformat('Merakit %s', name),
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { dict = buildAnim.dict, clip = buildAnim.clip, flag = buildAnim.flag },
    })

    if finished then
        local restZ = ghostEntity ~= 0 and DoesEntityExist(ghostEntity) and GetEntityCoords(ghostEntity).z or nil
        local ok, result = lib.callback.await('scifi_assembly:finish', false, restZ)
        if ok then
            notify(sformat('%s selesai dirakit!', result), 'success')
        else
            notify(reasonMessages[result] or 'Perakitan gagal.', 'error')
        end
    else
        TriggerTokenEvent('scifi_assembly:cancelBuild')
        notify('Perakitan dibatalkan.', 'error')
    end

    building = false
end

interface.callback('ready', function(_, cb)
    cb(pendingPayload or buildPayload())
end)

interface.callback('camera', function(data, cb)
    cb({})
    if not previewCam or type(data) ~= 'table' then return end

    local dx = tonumber(data.dx) or 0
    local dy = tonumber(data.dy) or 0
    local zoom = tonumber(data.zoom) or 0
    local speed = camConfig.rotateSpeed

    camYaw = (camYaw - dx * speed) % 360.0
    camPitch = mmin(mmax(camPitch + dy * speed, camConfig.minPitch), camConfig.maxPitch)
    camDistance = mmin(mmax(camDistance + zoom * camConfig.zoomStep, camConfig.minDistance), camConfig.maxDistance)
    updatePreviewCam()
end)

interface.callback('select', function(data, cb)
    CreateThread(function()
        local ok, reason = lib.callback.await('scifi_assembly:select', false, data and data.model)
        cb({ ok = ok == true, message = not ok and (reasonMessages[reason] or 'Gagal memilih blueprint.') or nil })
    end)
end)

interface.callback('build', function(data, cb)
    CreateThread(function()
        local ok, duration, name = lib.callback.await('scifi_assembly:build', false, data and data.model)
        if not ok then
            cb({ ok = false, message = reasonMessages[duration] or 'Gagal memulai perakitan.' })
            return
        end

        cb({ ok = true })
        closeUI()
        Wait(300)
        runBuild(duration, name)
    end)
end)

interface.callback('close', function(_, cb)
    cb({})
    closeUI()
end)

local fxByModel = {}
do
    local baseFx = Config.CompleteFx
    for i = 1, blueprintCount do
        local blueprint = blueprints[i]
        local fx = {}
        for key, value in pairs(baseFx) do fx[key] = value end
        if blueprint.fx then
            for key, value in pairs(blueprint.fx) do fx[key] = value end
        end

        local point = spawnPointByModel[blueprint.model]
        local count = fx.points
        local radius = fx.radius
        local step = 2.0 * math.pi / count
        local points = {}
        for j = 1, count do
            local angle = (j - 1) * step
            points[j] = vec3(point.x + mcos(angle) * radius, point.y + msin(angle) * radius, point.z)
        end
        if fx.center then
            points[#points + 1] = vec3(point.x, point.y, point.z)
        end

        fx.coords = points
        fx.count = #points
        fxByModel[blueprint.model] = fx
    end
end
local activeFx = {}

RegisterNetEvent('scifi_assembly:completed', function(model)
    local fx = fxByModel[model]
    if not fx or not fx.enabled or not inRange then return end

    CreateThread(function()
        local asset = fx.asset
        if not pcall(lib.requestNamedPtfxAsset, asset, 5000) then return end

        local name = fx.name
        local scale = fx.scale
        local coords = fx.coords
        local count = fx.count
        local handles = {}
        for i = 1, count do
            local point = coords[i]
            UseParticleFxAsset(asset)
            local handle = StartParticleFxLoopedAtCoord(name, point.x, point.y, point.z, 0.0, 0.0, 0.0, scale, false, false, false, false)
            handles[i] = handle
            activeFx[handle] = true
        end

        Wait(fx.duration)

        for i = 1, count do
            local handle = handles[i]
            if activeFx[handle] then
                StopParticleFxLooped(handle, false)
                activeFx[handle] = nil
            end
        end
        if asset ~= 'core' then RemoveNamedPtfxAsset(asset) end
    end)
end)

RegisterNetEvent('scifi_assembly:settle', function(netId)
    local found, vehicle = pcall(lib.waitFor, function()
        if not NetworkDoesEntityExistWithNetworkId(netId) then return end
        local entity = NetworkGetEntityFromNetworkId(netId)
        if entity ~= 0 and DoesEntityExist(entity) then return entity end
    end, nil, 5000)

    if not found or not vehicle or not NetworkHasControlOfEntity(vehicle) then return end
    SetVehicleOnGroundProperly(vehicle)
end)

AddStateBagChangeHandler(STATE_KEY, 'global', function(_, _, value)
    currentState = value or {}

    if building and currentState.stage ~= 'building' then
        lib.cancelProgress()
    end

    if previewCam then
        setCamTarget(currentState.stage and currentState.model or false)
    end

    requestSync()

    if uiOpen then
        CreateThread(function()
            if uiOpen then interface.send({ action = 'status', data = buildStatus() }) end
        end)
    end
end)

lib.points.new({
    coords = spawnCoords,
    distance = Config.StreamDistance,
    onEnter = function()
        inRange = true
        requestSync()
    end,
    onExit = function()
        inRange = false
        requestSync()
    end,
})

stationZone = exports.ox_target:addSphereZone({
    coords = Config.Station,
    radius = Config.StationRadius,
    debug = false,
    options = {
        {
            name = 'scifi_assembly_station',
            icon = 'fas fa-microchip',
            label = 'Perakitan Kendaraan Sci-Fi',
            distance = 2.5,
            canInteract = function() return not building end,
            onSelect = function()
                CreateThread(openUI)
            end,
        },
    },
})

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    deleteGhost()
    stopPreviewCam()

    for handle in pairs(activeFx) do
        StopParticleFxLooped(handle, false)
    end

    if uiOpen then
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
    end

    if stationZone then
        exports.ox_target:removeZone(stationZone)
    end
end)
