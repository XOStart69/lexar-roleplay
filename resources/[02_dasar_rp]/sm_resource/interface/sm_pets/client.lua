local Config = localmodule 'config.shared'
Config.Pets = localmodule 'config.pets'
local Catalog = localmodule 'config.catalog'
local Fits = localmodule 'config.fits'
local Anims = localmodule 'config.anims'

interface.init(false)

local CreatePed = CreatePed
local DoesEntityExist = DoesEntityExist
local DeleteEntity = DeleteEntity
local GetEntityCoords = GetEntityCoords
local GetEntityHeading = GetEntityHeading
local GetHeadingFromVector_2d = GetHeadingFromVector_2d
local SetEntityHeading = SetEntityHeading
local TaskGoStraightToCoord = TaskGoStraightToCoord
local TaskTurnPedToFaceEntity = TaskTurnPedToFaceEntity
local GetScreenCoordFromWorldCoord = GetScreenCoordFromWorldCoord
local GetModelDimensions = GetModelDimensions
local GetEntityModel = GetEntityModel
local DisableControlAction = DisableControlAction
local IsControlJustReleased = IsControlJustReleased
local GetOffsetFromEntityInWorldCoords = GetOffsetFromEntityInWorldCoords
local GetGroundZFor_3dCoord = GetGroundZFor_3dCoord
local NetworkGetNetworkIdFromEntity = NetworkGetNetworkIdFromEntity
local NetworkGetEntityIsNetworked = NetworkGetEntityIsNetworked
local SetNetworkIdCanMigrate = SetNetworkIdCanMigrate
local SetEntityAsMissionEntity = SetEntityAsMissionEntity
local SetBlockingOfNonTemporaryEvents = SetBlockingOfNonTemporaryEvents
local SetPedComponentVariation = SetPedComponentVariation
local SetEntityHealth = SetEntityHealth
local SetEntityMaxHealth = SetEntityMaxHealth
local IsPedDeadOrDying = IsPedDeadOrDying
local ClearPedTasks = ClearPedTasks
local ClearPedTasksImmediately = ClearPedTasksImmediately
local TaskPlayAnim = TaskPlayAnim
local GetAnimDuration = GetAnimDuration
local CreateCam = CreateCam
local SetCamActive = SetCamActive
local AttachCamToEntity = AttachCamToEntity
local PointCamAtEntity = PointCamAtEntity
local RenderScriptCams = RenderScriptCams
local DestroyCam = DestroyCam
local DoesCamExist = DoesCamExist
local AddBlipForEntity = AddBlipForEntity
local SetBlipSprite = SetBlipSprite
local SetBlipColour = SetBlipColour
local SetBlipScale = SetBlipScale
local SetBlipAsShortRange = SetBlipAsShortRange
local BeginTextCommandSetBlipName = BeginTextCommandSetBlipName
local AddTextComponentSubstringPlayerName = AddTextComponentSubstringPlayerName
local EndTextCommandSetBlipName = EndTextCommandSetBlipName
local RemoveBlip = RemoveBlip
local DoesBlipExist = DoesBlipExist
local SetModelAsNoLongerNeeded = SetModelAsNoLongerNeeded
local SetPedCanRagdoll = SetPedCanRagdoll
local SetPedFleeAttributes = SetPedFleeAttributes
local SetNuiFocus = SetNuiFocus
local SetNuiFocusKeepInput = SetNuiFocusKeepInput
local GetGameTimer = GetGameTimer
local Wait = Wait
local SetTimeout = SetTimeout
local joaat = joaat
local tostring = tostring
local type = type
local tonumber = tonumber
local pairs = pairs
local mfloor = math.floor
local mmax = math.max
local mmin = math.min
local mrad = math.rad
local msin = math.sin
local mcos = math.cos

local petTypes = {}
for i = 1, #Config.Pets do
    local entry = Config.Pets[i]
    petTypes[entry.id] = entry
end

SmPets = {
    Fits = Fits,
    Config = Config,
    Catalog = Catalog,
    Anims = Anims,
    petTypes = petTypes,
    pet = nil,
    uiActions = {},
    ui = { open = false, view = nil, payload = nil },
}

local ui = SmPets.ui
local interactCallbacks = {}

---@return boolean
local interactLive = false

function SmPets.interactReady()
    return interactLive and GetResourceState('rhd_interact') == 'started'
end

---@return boolean
local function probeInteract()
    if GetResourceState('rhd_interact') ~= 'started' then return false end
    local ok, err = pcall(function() exports.rhd_interact:removeCoords('sm_pets:probe') end)
    return ok or not tostring(err):find('No such export', 1, true)
end

local function waitInteract()
    interactLive = false
    CreateThread(function()
        for _ = 1, 120 do
            if probeInteract() then
                interactLive = true
                for i = 1, #interactCallbacks do interactCallbacks[i]() end
                return
            end
            Wait(500)
        end
    end)
end

---@param fn fun()
function SmPets.onInteractReady(fn)
    interactCallbacks[#interactCallbacks + 1] = fn
    if interactLive then fn() end
end

AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName == 'rhd_interact' then waitInteract() end
end)

AddEventHandler('onClientResourceStop', function(resourceName)
    if resourceName == 'rhd_interact' then interactLive = false end
end)

waitInteract()
local uiActions = SmPets.uiActions
local spawning = false
local camera = nil
local interactRegistered = false

---@param description string
---@param notifyType? string
function SmPets.notify(description, notifyType)
    if not description then return end
    lib.notify({ title = 'Pet', description = description, type = notifyType or 'inform' })
end

---@param dict string
---@return boolean
function SmPets.loadDict(dict)
    return pcall(lib.requestAnimDict, dict, 5000)
end

---@param model string|integer
---@return integer|nil
function SmPets.loadModel(model)
    local hash = type(model) == 'number' and model or joaat(model)
    if not pcall(lib.requestModel, hash, 8000) then
        lib.print.warn(('sm_pets: model %s gagal dimuat'):format(tostring(model)))
        return nil
    end
    return hash
end

---@param ped integer
---@param anim table
---@param flag? integer
---@param duration? integer
---@return integer durationMs
function SmPets.playAnim(ped, anim, flag, duration)
    if not anim or not SmPets.loadDict(anim[1]) then return 0 end
    TaskPlayAnim(ped, anim[1], anim[2], 8.0, -8.0, duration or -1, flag or 1, 0.0, false, false, false)
    return mfloor(GetAnimDuration(anim[1], anim[2]) * 1000)
end

local SELECT_INFO = 'sm_pets:selectTarget'
local selectingTarget = false
local selectMarkerTop = lib.marker.new({ type = 'ChevronUpx1', coords = vec3(0, 0, 0), width = 0.4, height = -0.4, direction = vec3(0, 0, 0), color = { r = 0, g = 204, b = 201, a = 140 } })
local selectMarkerGround = lib.marker.new({ type = 'HorizontalCircleSkinny', coords = vec3(0, 0, 0), width = 1.0, height = 1.0, color = { r = 0, g = 204, b = 201, a = 140 } })

---@param kind 'player'|'vehicle'
---@param range number
---@return integer|nil entity
local function pickTarget(kind, range)
    local origin = GetEntityCoords(cache.ped)
    local list = kind == 'vehicle' and lib.getNearbyVehicles(origin, range, true) or lib.getNearbyPlayers(origin, range, false)
    local best, bestScore = nil, nil
    for i = 1, #list do
        local entry = list[i]
        local entity = kind == 'vehicle' and entry.vehicle or entry.ped
        if kind == 'vehicle' or not IsPedDeadOrDying(entity, true) then
            local c = entry.coords
            local onScreen, sx, sy = GetScreenCoordFromWorldCoord(c.x, c.y, c.z)
            if onScreen then
                local dx, dy = sx - 0.5, sy - 0.5
                local score = dx * dx + dy * dy
                if not bestScore or score < bestScore then
                    best, bestScore = entity, score
                end
            end
        end
    end
    return best
end

---@param entity integer
---@param kind 'player'|'vehicle'
local function drawTargetMarker(entity, kind)
    local c = GetEntityCoords(entity)
    if kind == 'vehicle' then
        local min, max = GetModelDimensions(GetEntityModel(entity))
        local size = mmax(max.x - min.x, max.y - min.y) + 0.6
        selectMarkerTop.coords = vec3(c.x, c.y, c.z + max.z + 0.5)
        selectMarkerGround.coords = vec3(c.x, c.y, c.z + min.z + 0.05)
        selectMarkerGround.width, selectMarkerGround.height = size, size
    else
        selectMarkerTop.coords = vec3(c.x, c.y, c.z + 1.2)
        selectMarkerGround.coords = vec3(c.x, c.y, c.z - 0.95)
        selectMarkerGround.width, selectMarkerGround.height = 1.0, 1.0
    end
    selectMarkerTop:draw()
    selectMarkerGround:draw()
end

---@param opts { kind: 'player'|'vehicle', range: number, title: string, action: string, icon?: string, color?: { r: integer, g: integer, b: integer } }
---@return integer|nil entity
function SmPets.selectTarget(opts)
    if selectingTarget then return nil end
    local pet = SmPets.pet
    if not pet then return nil end
    selectingTarget = true
    local color = opts.color or { r = 0, g = 204, b = 201 }
    selectMarkerTop.color = { r = color.r, g = color.g, b = color.b, a = 140 }
    selectMarkerGround.color = { r = color.r, g = color.g, b = color.b, a = 140 }
    infoUI.show({
        id = SELECT_INFO,
        title = opts.title,
        icon = opts.icon or 'fas fa-crosshairs',
        description = ('Arahkan kamera ke target\n%s - [kbd]E[/kbd]\nBatal - [kbd]BACKSPACE[/kbd]'):format(opts.action),
    })
    local chosen, target, nextScan = nil, nil, 0
    local emptyText = opts.kind == 'vehicle' and 'Tidak ada kendaraan di sekitar.' or 'Tidak ada orang di sekitar.'
    while selectingTarget and SmPets.pet == pet and pet.state ~= 'dead' do
        DisableControlAction(2, 200, true)
        if IsControlJustReleased(0, 202) then break end
        local now = GetGameTimer()
        if now >= nextScan then
            nextScan = now + 150
            target = pickTarget(opts.kind, opts.range)
        end
        if target and DoesEntityExist(target) then
            drawTargetMarker(target, opts.kind)
            if IsControlJustReleased(0, 38) then
                chosen = target
                break
            end
        elseif IsControlJustReleased(0, 38) then
            SmPets.notify(emptyText, 'error')
        end
        Wait(0)
    end
    selectingTarget = false
    infoUI.remove(SELECT_INFO)
    return chosen
end

---@param label string
---@param duration integer
---@param target? integer
---@return boolean
function SmPets.injectProgress(label, duration, target)
    local inject = Config.Inject
    if target and DoesEntityExist(target) then
        TaskTurnPedToFaceEntity(cache.ped, target, 700)
        Wait(700)
    end
    return lib.progressBar({
        duration = duration,
        label = label,
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = inject.anim,
        prop = inject.prop,
    }) == true
end

---@param ped integer
---@param coords vector3
---@param speed number
function SmPets.goTo(ped, coords, speed)
    local pos = GetEntityCoords(ped)
    local dx, dy = coords.x - pos.x, coords.y - pos.y
    local want = GetEntityHeading(ped)
    if dx * dx + dy * dy > 0.25 then
        want = GetHeadingFromVector_2d(dx, dy)
        local diff = (want - GetEntityHeading(ped) + 540.0) % 360.0 - 180.0
        if diff > 45.0 or diff < -45.0 then SetEntityHeading(ped, want) end
    end
    TaskGoStraightToCoord(ped, coords.x, coords.y, coords.z, speed, -1, want, 0.0)
end

---@param ped integer
---@param coords vector3
---@param radius number
---@param timeoutMs integer
---@param isCancelled? fun(): boolean
---@return boolean arrived
function SmPets.waitArrive(ped, coords, radius, timeoutMs, isCancelled)
    local deadline = GetGameTimer() + timeoutMs
    local r2 = radius * radius
    while GetGameTimer() < deadline do
        if not DoesEntityExist(ped) or (isCancelled and isCancelled()) then return false end
        local pos = GetEntityCoords(ped)
        local dx, dy = pos.x - coords.x, pos.y - coords.y
        if dx * dx + dy * dy <= r2 then return true end
        Wait(100)
    end
    return false
end

---@param coords vector3
---@return number
function SmPets.groundZ(coords)
    local found, z = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + 1.0, false)
    return found and z or coords.z
end

---@param range number
---@return boolean
function SmPets.isNearPet(range)
    local pet = SmPets.pet
    if not pet or not DoesEntityExist(pet.ped) then return false end
    return #(GetEntityCoords(cache.ped) - GetEntityCoords(pet.ped)) <= range
end

---@param ped integer
---@param look table
function SmPets.applyLook(ped, look)
    for comp, value in pairs(look or {}) do
        local index = tonumber(comp)
        if index and type(value) == 'table' then
            SetPedComponentVariation(ped, index, value[1] or 0, value[2] or 0, 0)
        end
    end
end

---@param name string
---@param kind? string
---@return string
function SmPets.imageFor(name, kind)
    if kind == 'consumable' then return ('nui://ox_inventory/web/images/%s.png'):format(name) end
    return ('images/%s.webp'):format(name)
end

local function removeBlip()
    local pet = SmPets.pet
    if pet and pet.blip and DoesBlipExist(pet.blip) then RemoveBlip(pet.blip) end
end

---@param pet table
local function addBlip(pet)
    local cfg = Config.Blip
    local blip = AddBlipForEntity(pet.ped)
    SetBlipSprite(blip, cfg.sprite)
    SetBlipColour(blip, cfg.color)
    SetBlipScale(blip, cfg.scale)
    SetBlipAsShortRange(blip, false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(pet.name)
    EndTextCommandSetBlipName(blip)
    pet.blip = blip
end

local function unregisterInteract()
    local pet = SmPets.pet
    if interactRegistered and pet and SmPets.interactReady() then
        exports.rhd_interact:removeEntity(pet.netId)
    end
    interactRegistered = false
end

local function registerInteract()
    local pet = SmPets.pet
    if not pet or interactRegistered or not SmPets.interactReady() then return end
    local distance = Config.InteractDistance
    exports.rhd_interact:addEntity(pet.netId, {
        {
            name = 'sm_pets:follow',
            label = 'Ikuti Aku',
            icon = 'fas fa-person-walking',
            distance = distance,
            canInteract = function()
                local p = SmPets.pet
                return p and p.state == 'idle'
            end,
            onSelect = function() SmPets.follow() end,
        },
        {
            name = 'sm_pets:stay',
            label = 'Diam di Sini',
            icon = 'fas fa-hand',
            distance = distance,
            canInteract = function()
                local p = SmPets.pet
                return p and p.state == 'follow'
            end,
            onSelect = function() SmPets.stay() end,
        },
        {
            name = 'sm_pets:cuddle',
            label = 'Elus',
            icon = 'fas fa-heart',
            distance = distance,
            canInteract = function()
                local p = SmPets.pet
                return p and (p.state == 'idle' or p.state == 'follow')
            end,
            onSelect = function() SmPets.cuddle() end,
        },
        {
            name = 'sm_pets:wake',
            label = 'Bangunkan',
            icon = 'fas fa-sun',
            distance = distance,
            canInteract = function()
                local p = SmPets.pet
                return p and p.state == 'bed'
            end,
            onSelect = function() SmPets.cancelAction() end,
        },
        {
            name = 'sm_pets:menu',
            label = 'Menu Pet',
            icon = 'fas fa-paw',
            distance = distance,
            canInteract = function()
                local p = SmPets.pet
                return p and p.state ~= 'busy'
            end,
            onSelect = function() SmPets.openPanel() end,
        },
    })
    interactRegistered = true
end

SmPets.onInteractReady(function()
    interactRegistered = false
    registerInteract()
end)

local function destroyCamera()
    if camera and DoesCamExist(camera) then
        RenderScriptCams(false, true, 500, true, true)
        DestroyCam(camera, true)
    end
    camera = nil
end

local orbit = { yaw = 0.0, pitch = 0.0, dist = 0.0 }

local function updateOrbit()
    local pet = SmPets.pet
    if not camera or not pet or not DoesEntityExist(pet.ped) then return end
    local cfg = Config.Camera
    local yaw, pitch = mrad(orbit.yaw), mrad(orbit.pitch)
    local flat = mcos(pitch) * orbit.dist
    AttachCamToEntity(camera, pet.ped, -msin(yaw) * flat, mcos(yaw) * flat, msin(pitch) * orbit.dist + cfg.targetZ, false)
    PointCamAtEntity(camera, pet.ped, 0.0, 0.0, cfg.targetZ, true)
end

---@return boolean created
local function createPetCamera()
    destroyCamera()
    local pet = SmPets.pet
    if not pet or not DoesEntityExist(pet.ped) or pet.state == 'dead' or pet.state == 'vehicle' then return false end
    if not SmPets.isNearPet(15.0) then return false end
    local cfg = Config.Camera
    orbit.yaw = GetEntityHeading(pet.ped) + cfg.yawOffset
    orbit.pitch = cfg.pitch
    orbit.dist = cfg.distance
    camera = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    updateOrbit()
    SetCamActive(camera, true)
    RenderScriptCams(true, true, 500, true, true)
    return true
end

---@param hidden boolean
local function setHudHidden(hidden)
    playerState:set('petUiOpen', hidden, false)
    if hidden then
        if SM_HUD and SM_HUD.visible then SM_HUD.setVisible(false) end
        DisplayRadar(false)
    end
end

---@param view string
---@param payload table
---@param withCamera? boolean
function SmPets.openUI(view, payload, withCamera)
    payload.view = view
    if ui.open then
        ui.view = view
        ui.payload = payload
        interface.send({ action = 'open', data = payload })
        return
    end
    ui.open = true
    ui.view = view
    ui.payload = payload
    local hasCamera = withCamera and createPetCamera() or false
    payload.cameraActive = hasCamera
    if not interface.show() then
        ui.open = false
        ui.payload = nil
        destroyCamera()
        return
    end
    if hasCamera then setHudHidden(true) end
    interface.focus(true, true)
    TriggerServerEvent('sm_pets:server:viewing', true)
end

function SmPets.closeUI()
    if not ui.open then return end
    ui.open = false
    ui.view = nil
    ui.payload = nil
    destroyCamera()
    setHudHidden(false)
    interface.focus(false, false)
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    TriggerServerEvent('sm_pets:server:viewing', false)
    SetTimeout(50, function()
        if not ui.open then interface.hide() end
    end)
end

---@param action string
---@param data any
function SmPets.sendUI(action, data)
    if not ui.open then return end
    interface.send({ action = action, data = data })
end

---@param keys string[]
---@return table
local function wardrobeMeta(keys)
    local meta = {}
    for i = 1, #keys do
        local key = keys[i]
        local item = Catalog.wardrobe[key]
        if item then
            meta[key] = { label = item.label, cat = item.cat, kind = item.kind, comp = item.comp, draw = item.draw, tex = item.tex, image = SmPets.imageFor(key) }
        end
    end
    return meta
end

---@param species string
---@return table
local function posesFor(species)
    local cfg = Config.Species[species]
    local set = cfg and Anims[cfg.anims]
    local list = {}
    if not set then return list end
    for i = 1, #set.poses do
        local pose = set.poses[i]
        list[i] = { id = pose.id, label = pose.label, image = SmPets.imageFor(pose.icon) }
    end
    return list
end

---@return table|nil
function SmPets.buildPanelPayload()
    local data = lib.callback.await('sm_pets:bag', false)
    if not data then return nil end
    local keys, seen = {}, {}
    for i = 1, #data.pets do
        local entry = data.pets[i]
        entry.image = SmPets.imageFor(entry.image)
        entry.poses = posesFor(entry.species)
        for j = 1, #entry.wardrobe do
            local key = entry.wardrobe[j]
            if not seen[key] then
                seen[key] = true
                keys[#keys + 1] = key
            end
        end
    end
    local pet = SmPets.pet
    data.activeState = pet and pet.state or false
    data.wardrobeMeta = wardrobeMeta(keys)
    data.transfer = { enabled = data.canTransfer == true, maxFee = Config.Transfer.maxFee }
    data.commands = { bag = Config.Commands.bag }
    data.cameraActive = camera ~= nil
    return data
end

function SmPets.openPanel()
    if ui.open and ui.view == 'pets' then return end
    local payload = SmPets.buildPanelPayload()
    if not payload then return end
    SmPets.openUI('pets', payload, true)
end

function SmPets.refreshPanel()
    if not ui.open or ui.view ~= 'pets' then return end
    local payload = SmPets.buildPanelPayload()
    if payload then
        payload.view = 'pets'
        ui.payload = payload
        interface.send({ action = 'open', data = payload })
    end
end

---@param petId integer
function SmPets.spawn(petId)
    if spawning or SmPets.pet then return SmPets.notify('Simpan pet yang sedang keluar dulu.', 'error') end
    if IsPedInAnyVehicle(cache.ped, false) then return SmPets.notify('Turun dari kendaraan dulu.', 'error') end
    spawning = true

    local result = lib.callback.await('sm_pets:spawn', false, petId)
    if not result or not result.ok then
        spawning = false
        return SmPets.notify(result and result.msg or 'Gagal mengeluarkan pet.', 'error')
    end

    local data = result.pet
    local hash = SmPets.loadModel(data.model)
    if not hash then
        spawning = false
        lib.callback.await('sm_pets:spawned', false, 0)
        return SmPets.notify('Model pet gagal dimuat.', 'error')
    end

    local playerPed = cache.ped
    local front = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 1.2, 0.0)
    local ped = CreatePed(28, hash, front.x, front.y, SmPets.groundZ(front), GetEntityHeading(playerPed), true, false)
    SetModelAsNoLongerNeeded(hash)

    local tries = 0
    while not NetworkGetEntityIsNetworked(ped) and tries < 40 do
        tries = tries + 1
        Wait(25)
    end

    local netId = NetworkGetNetworkIdFromEntity(ped)
    SetNetworkIdCanMigrate(netId, false)
    SetEntityAsMissionEntity(ped, true, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedFleeAttributes(ped, 0, false)
    SetEntityMaxHealth(ped, 200)
    SetEntityHealth(ped, 100 + (data.health > 0 and data.health or 0))
    SmPets.applyLook(ped, data.look)

    if not lib.callback.await('sm_pets:spawned', false, netId) then
        if DoesEntityExist(ped) then DeleteEntity(ped) end
        spawning = false
        return SmPets.notify('Pet gagal dikeluarkan, coba lagi.', 'error')
    end

    local speciesCfg = Config.Species[data.species]
    local pet = {
        id = data.id,
        type = data.type,
        name = data.name,
        model = data.model,
        species = data.species,
        speciesCfg = speciesCfg,
        anims = Anims[speciesCfg.anims],
        k9 = data.k9,
        clothing = data.clothing,
        mute = petTypes[data.type] and petTypes[data.type].mute == true,
        canAttack = petTypes[data.type] and petTypes[data.type].attack == true,
        sound = petTypes[data.type] and petTypes[data.type].sound or nil,
        soundCooldownMs = petTypes[data.type] and petTypes[data.type].soundCooldownMs or nil,
        attackSound = petTypes[data.type] and petTypes[data.type].attackSound or nil,
        followSound = petTypes[data.type] and petTypes[data.type].followSound == true,
        look = data.look,
        bowl = data.bowl,
        ped = ped,
        netId = netId,
        state = 'idle',
        stats = { health = data.health },
    }
    SmPets.pet = pet
    addBlip(pet)
    registerInteract()
    spawning = false

    if data.health <= 0 then
        SetEntityHealth(ped, 0)
        pet.state = 'dead'
        SmPets.notify(('%s sedang pingsan. Pakai obat pet untuk menyadarkannya.'):format(pet.name), 'warning')
    else
        SmPets.notify(('%s keluar.'):format(pet.name), 'success')
    end
    TriggerEvent('sm_pets:client:spawned', pet)
end

---@param keepEntity? boolean
local function cleanupLocal(keepEntity)
    local pet = SmPets.pet
    if not pet then return end
    SmPets.cancelAction(true)
    unregisterInteract()
    removeBlip()
    if not keepEntity and DoesEntityExist(pet.ped) then DeleteEntity(pet.ped) end
    TriggerEvent('sm_pets:client:removed', pet)
    SmPets.pet = nil
end

function SmPets.store()
    local pet = SmPets.pet
    if not pet then return end
    if pet.state ~= 'dead' and not SmPets.isNearPet(15.0) then
        return SmPets.notify('Pet terlalu jauh untuk disimpan.', 'error')
    end
    SmPets.cancelAction(true)
    lib.callback.await('sm_pets:store', false)
end

---@param name string
---@param onCancel fun(silent: boolean)
function SmPets.setAction(name, onCancel)
    local pet = SmPets.pet
    if not pet then return end
    pet.state = name
    pet.cancel = onCancel
end

---@param silent? boolean
function SmPets.cancelAction(silent)
    local pet = SmPets.pet
    if not pet then return end
    local cancel = pet.cancel
    pet.cancel = nil
    if cancel then cancel(silent == true) end
    if pet.state ~= 'dead' then
        pet.state = 'idle'
        if DoesEntityExist(pet.ped) then ClearPedTasks(pet.ped) end
    end
end

---@return boolean
function SmPets.canCommand()
    local pet = SmPets.pet
    if not pet or not DoesEntityExist(pet.ped) then return false end
    if pet.state == 'dead' then
        SmPets.notify(('%s sedang pingsan.'):format(pet.name), 'error')
        return false
    end
    if pet.state == 'busy' then return false end
    if not SmPets.isNearPet(Config.CommandRange) then
        SmPets.notify('Pet terlalu jauh.', 'error')
        return false
    end
    return true
end

interface.callback('ready', function(_, cb)
    cb(ui.payload or { view = 'none' })
end)

interface.callback('camera', function(data, cb)
    cb({})
    if not camera or type(data) ~= 'table' then return end
    local cfg = Config.Camera
    local dx, dy, zoom = tonumber(data.dx) or 0, tonumber(data.dy) or 0, tonumber(data.zoom) or 0
    orbit.yaw = (orbit.yaw - dx * cfg.sensitivity) % 360.0
    orbit.pitch = mmax(cfg.minPitch, mmin(cfg.maxPitch, orbit.pitch + dy * cfg.sensitivity))
    orbit.dist = mmax(cfg.minDistance, mmin(cfg.maxDistance, orbit.dist + zoom * cfg.zoomStep))
    updateOrbit()
end)

interface.callback('close', function(_, cb)
    cb({})
    SmPets.closeUI()
end)

interface.callback('action', function(data, cb)
    local handler = type(data) == 'table' and uiActions[data.type]
    if not handler then return cb({ ok = false }) end
    local ok, result = pcall(handler, data)
    if not ok then
        lib.print.error(('sm_pets action %s: %s'):format(tostring(data.type), result))
        return cb({ ok = false, msg = 'Terjadi kesalahan.' })
    end
    cb(type(result) == 'table' and result or { ok = result == true })
end)

uiActions.spawn = function(data)
    SmPets.closeUI()
    SmPets.spawn(tonumber(data.petId))
    return { ok = true, closed = true }
end

uiActions.store = function()
    SmPets.store()
    return SmPets.buildPanelPayload() or { ok = false }
end

uiActions.refresh = function()
    return SmPets.buildPanelPayload() or { ok = false }
end

uiActions.transfer = function(data)
    local result = lib.callback.await('sm_pets:transfer', false, tonumber(data.petId), tonumber(data.target), tonumber(data.fee) or 0)
    if result and result.msg then SmPets.notify(result.msg, result.ok and 'success' or 'error') end
    if result and result.ok then
        local payload = SmPets.buildPanelPayload()
        if payload then
            payload.ok = true
            return payload
        end
    end
    return result or { ok = false }
end

RegisterNetEvent('sm_pets:client:despawned', function(petId, reason)
    local pet = SmPets.pet
    if not pet or pet.id ~= petId then return end
    if camera then
        destroyCamera()
        setHudHidden(false)
    end
    if reason == 'escaped' and DoesEntityExist(pet.ped) then
        local ped = pet.ped
        cleanupLocal(true)
        SetBlockingOfNonTemporaryEvents(ped, false)
        TaskWanderStandard(ped, 10.0, 10)
    else
        cleanupLocal(reason == 'lost' or reason == 'owner' or reason == 'bucket')
        if reason == 'stored' then SmPets.notify('Pet disimpan.', 'success') end
    end
    SmPets.refreshPanel()
end)

RegisterNetEvent('sm_pets:client:setHealth', function(petId, health)
    local pet = SmPets.pet
    if not pet or pet.id ~= petId or not DoesEntityExist(pet.ped) then return end
    pet.stats.health = health
    local ped = pet.ped
    if health <= 0 then
        if not IsPedDeadOrDying(ped, true) then SetEntityHealth(ped, 0) end
        SmPets.cancelAction(true)
        pet.state = 'dead'
        return
    end
    if IsPedDeadOrDying(ped, true) or pet.state == 'dead' then
        ResurrectPed(ped)
        ClearPedTasksImmediately(ped)
        SetEntityMaxHealth(ped, 200)
        SetEntityHealth(ped, 100 + health)
        ClearPedBloodDamage(ped)
        SetPedCanRagdoll(ped, true)
        pet.state = 'idle'
        SmPets.applyLook(ped, pet.look)
        return
    end
    SetEntityHealth(ped, 100 + health)
end)

RegisterNetEvent('sm_pets:client:stats', function(petId, stats, skills)
    local pet = SmPets.pet
    if pet and pet.id == petId then
        pet.stats = stats
        pet.skills = skills
    end
    SmPets.sendUI('stats', { id = petId, stats = stats, skills = skills })
end)

RegisterNetEvent('sm_pets:client:mood', function(mood)
    local pet = SmPets.pet
    if not pet then return end
    if mood == 'tired' then
        SmPets.notify(('%s kelelahan. Biarkan istirahat di kasur.'):format(pet.name), 'warning')
    elseif mood == 'angry' then
        SmPets.notify(('%s sedang kesal.'):format(pet.name), 'warning')
    elseif mood == 'sad' then
        SmPets.notify(('%s terlihat sedih.'):format(pet.name), 'warning')
    end
    if SmPets.vocal then SmPets.vocal(mood == 'angry' and 'growl' or 'whine') end
end)

AddEventHandler('gameEventTriggered', function(name, args)
    if name ~= 'CEventNetworkEntityDamage' then return end
    local pet = SmPets.pet
    if not pet or args[1] ~= pet.ped then return end
    if args[2] == cache.ped then TriggerServerEvent('sm_pets:server:hitByOwner') end
    if pet.state ~= 'dead' and IsPedDeadOrDying(pet.ped, true) then
        SmPets.cancelAction(true)
        pet.state = 'dead'
        pet.stats.health = 0
        SmPets.notify(('%s terluka parah.'):format(pet.name), 'error')
    elseif pet.state == 'bed' then
        SmPets.cancelAction(true)
    end
end)

AddEventHandler('sm_pets:client:forceClose', function()
    SmPets.closeUI()
end)

RegisterCommand(Config.Commands.bag, function()
    if ui.open then return end
    SmPets.openPanel()
end, false)

RegisterCommand('+smpets_cancel', function()
    local pet = SmPets.pet
    if pet and pet.cancel then SmPets.cancelAction() end
end, false)
RegisterCommand('-smpets_cancel', function() end, false)
RegisterKeyMapping('+smpets_cancel', 'Pet: hentikan aksi', 'keyboard', Config.CancelKey)

TriggerEvent('chat:addSuggestion', '/' .. Config.Commands.bag, 'Buka daftar hewan peliharaan')

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= cache.resource then return end
    destroyCamera()
    playerState:set('petUiOpen', false, false)
    local pet = SmPets.pet
    if pet then
        removeBlip()
        if DoesEntityExist(pet.ped) then DeleteEntity(pet.ped) end
    end
end)

exports('GetPet', function()
    local pet = SmPets.pet
    return pet and { id = pet.id, name = pet.name, ped = pet.ped, netId = pet.netId, k9 = pet.k9, state = pet.state } or nil
end)

exports('OpenPetMenu', function()
    SmPets.openPanel()
end)
