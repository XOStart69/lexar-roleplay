local config = localmodule 'config'
local state = localmodule 'modules.state'
local util = localmodule 'modules.util'
local keys = localmodule 'modules.keys'
local nui = localmodule 'modules.nui'
local camera = localmodule 'modules.camera'
local control = localmodule 'modules.control'
local selection = localmodule 'modules.selection'
local objects = localmodule 'modules.objects'
local groups = localmodule 'modules.groups'
local orders = localmodule 'modules.orders'
local spawn = localmodule 'modules.spawn'
local placement = localmodule 'modules.placement'
local catalog = localmodule 'modules.catalog'
local infrared = localmodule 'modules.infrared'
local elements = localmodule 'modules.elements'
local bolt = localmodule 'modules.bolt'
local impersonate = localmodule 'modules.impersonate'
local menu = localmodule 'modules.menu'
local draw = localmodule 'modules.draw'

local hasFrame = interface.init(false)

local type = type
local tonumber = tonumber
local min = math.min
local abs = math.abs
local mfloor = math.floor
local Wait = Wait
local CreateThread = CreateThread
local GetGameTimer = GetGameTimer
local PlayerId = PlayerId
local PlayerPedId = PlayerPedId
local DoesEntityExist = DoesEntityExist
local IsEntityDead = IsEntityDead
local IsEntityAPed = IsEntityAPed
local IsEntityAVehicle = IsEntityAVehicle
local IsPedHuman = IsPedHuman
local IsPedDeadOrDying = IsPedDeadOrDying
local IsPedArmed = IsPedArmed
local IsPedInAnyVehicle = IsPedInAnyVehicle
local GetVehiclePedIsIn = GetVehiclePedIsIn
local GetEntityCoords = GetEntityCoords
local GetEntityHeading = GetEntityHeading
local GetEntityModel = GetEntityModel
local NetworkGetEntityIsNetworked = NetworkGetEntityIsNetworked
local GetNuiCursorPosition = GetNuiCursorPosition
local GetActiveScreenResolution = GetActiveScreenResolution
local DisableAllControlActions = DisableAllControlActions
local EnableControlAction = EnableControlAction
local DisablePlayerFiring = DisablePlayerFiring
local IsDisabledControlJustPressed = IsDisabledControlJustPressed
local IsDisabledControlJustReleased = IsDisabledControlJustReleased
local IsDisabledControlPressed = IsDisabledControlPressed
local SetEntityCoords = SetEntityCoords
local SetEntityCoordsNoOffset = SetEntityCoordsNoOffset
local NetworkDoesEntityExistWithNetworkId = NetworkDoesEntityExistWithNetworkId
local NetworkGetEntityFromNetworkId = NetworkGetEntityFromNetworkId
local SetEntityHeading = SetEntityHeading
local SetEntityVisible = SetEntityVisible
local SetEntityCollision = SetEntityCollision
local SetEntityInvincible = SetEntityInvincible
local SetEntityAlpha = SetEntityAlpha
local ResetEntityAlpha = ResetEntityAlpha
local FreezeEntityPosition = FreezeEntityPosition
local SetPedCanBeTargetted = SetPedCanBeTargetted
local SetEveryoneIgnorePlayer = SetEveryoneIgnorePlayer
local TaskLeaveVehicle = TaskLeaveVehicle
local LockMinimapAngle = LockMinimapAngle
local UnlockMinimapAngle = UnlockMinimapAngle
local SetNuiFocus = SetNuiFocus
local SetNuiFocusKeepInput = SetNuiFocusKeepInput
local GetResourceKvpString = GetResourceKvpString
local SetResourceKvp = SetResourceKvp
local GetDisplayNameFromVehicleModel = GetDisplayNameFromVehicleModel
local GetLabelText = GetLabelText
local GetVehicleNumberPlateText = GetVehicleNumberPlateText
local GetVehicleEngineHealth = GetVehicleEngineHealth
local GetVehicleBodyHealth = GetVehicleBodyHealth

local LMB = 24
local RMB = 25
local PTT = 249
local DOUBLE_CLICK_MS = config.doubleClickMs
local KVP_FAVORITES = 'sm_gamemaster:favorites'
local KVP_RADIAL = 'sm_gamemaster:radial'
local KVP_OPTIONS = 'sm_gamemaster:options'
local RADIAL_SLOTS = 5
local SAVED_OPTIONS = { 'persist', 'pickPeds', 'pickVehicles', 'pickObjects' }

---@param key string
---@return any
local function readKvp(key)
    local raw = GetResourceKvpString(key)

    if not raw or raw == '' then return nil end

    return json.decode(raw)
end

---@param key string
---@param value any
local function writeKvp(key, value)
    SetResourceKvp(key, json.encode(value))
end

do
    local saved = readKvp(KVP_OPTIONS)

    if type(saved) == 'table' then
        for i = 1, #SAVED_OPTIONS do
            local key = SAVED_OPTIONS[i]

            if type(saved[key]) == 'boolean' then
                state.options[key] = saved[key]
            end
        end
    end
end

---@return string[]
local function radialSlots()
    local saved = readKvp(KVP_RADIAL)
    local slots = {}

    for i = 1, RADIAL_SLOTS do
        local id = type(saved) == 'table' and saved[i] or config.radialDefaults[i]

        slots[i] = type(id) == 'string' and menu.radialValid(id) and id or ''
    end

    return slots
end

---@param ped integer
local function hidePlayer(ped)
    SetEntityVisible(ped, false, false)
    SetEntityAlpha(ped, 0, false)
    SetEntityCollision(ped, false, false)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    SetPedCanBeTargetted(ped, false)
    SetEveryoneIgnorePlayer(PlayerId(), true)
end

---@param ped integer
local function showPlayer(ped)
    ResetEntityAlpha(ped)
    SetEntityVisible(ped, true, false)
    SetEntityCollision(ped, true, true)
    SetEntityInvincible(ped, false)
    FreezeEntityPosition(ped, false)
    SetPedCanBeTargetted(ped, true)
    SetEveryoneIgnorePlayer(PlayerId(), false)
end

local function publishGroups()
    nui.send('groups', groups.summary())
end

local published = { mode = '', count = -1, placing = false, item = '', follow = 0, modify = false }

local function publishState(force)
    local item = state.item
    local itemKey = item and item.model or ''
    local follow = state.follow and state.follow.entity or 0
    local count = #state.selection
    local modify = count == 1 and selection.isObject(state.selection[1])

    if not force and published.mode == state.mode and published.count == count and published.placing == state.placing and published.item == itemKey and published.follow == follow and published.modify == modify then
        return
    end

    published.mode = state.mode
    published.count = count
    published.placing = state.placing
    published.item = itemKey
    published.follow = follow
    published.modify = modify

    nui.send('state', {
        mode = state.mode,
        selectionCount = count,
        placing = state.placing,
        item = item,
        following = follow ~= 0,
        canModify = modify,
    })
end

---@param ped integer
---@return table
local function pedInfo(ped)
    local health, maxHealth = util.health(ped)
    local entry = orders.peek(ped)
    local hash = GetEntityModel(ped)

    return {
        type = 'ped',
        model = catalog.pedName(hash) or ('0x%X'):format(hash & 0xFFFFFFFF),
        health = health,
        maxHealth = maxHealth,
        dead = IsPedDeadOrDying(ped, true),
        human = IsPedHuman(ped),
        armed = IsPedArmed(ped, 6),
        inVehicle = IsPedInAnyVehicle(ped, false),
        god = orders.isGod(ped),
        frozen = orders.isFrozen(ped),
        spawned = Entity(ped).state.smGamemaster == true,
        busy = orders.hasOrder(ped),
        mode = entry.mode,
        range = entry.range,
        accuracy = entry.accuracy,
        groups = groups.of(ped),
    }
end

---@param vehicle integer
---@return table
local function vehicleInfo(vehicle)
    local hash = GetEntityModel(vehicle)
    local label = GetLabelText(GetDisplayNameFromVehicleModel(hash))

    return {
        type = 'vehicle',
        model = catalog.vehicleName(hash) or GetDisplayNameFromVehicleModel(hash),
        label = label ~= 'NULL' and label or nil,
        plate = GetVehicleNumberPlateText(vehicle),
        engine = mfloor(GetVehicleEngineHealth(vehicle)),
        body = mfloor(GetVehicleBodyHealth(vehicle)),
        spawned = Entity(vehicle).state.smGamemaster == true,
        groups = groups.of(vehicle),
    }
end

---@return table?
local function inspectData()
    local list = state.selection
    local count = #list

    if count == 0 then return nil end

    if count == 1 then
        local entity = list[1]

        if not DoesEntityExist(entity) then return nil end

        local objectId = objects.idOf(entity)

        if objectId then
            local record = objects.record(objectId)

            return {
                type = 'object',
                model = record and record.model or '',
                id = objectId,
                persist = record and record.persist or false,
            }
        end

        if IsEntityAPed(entity) then return pedInfo(entity) end
        if IsEntityAVehicle(entity) then return vehicleInfo(entity) end

        return nil
    end

    local peds = 0
    local vehicles = 0
    local objectCount = 0
    local mode = nil
    local range = nil
    local accuracy = nil

    for i = 1, count do
        local entity = list[i]

        if objects.idOf(entity) then
            objectCount += 1
        elseif IsEntityAPed(entity) then
            peds += 1

            local entry = orders.peek(entity)

            mode = mode == nil and entry.mode or (mode == entry.mode and mode or 'mixed')
            range = range == nil and entry.range or (range == entry.range and range or -1)
            accuracy = accuracy == nil and entry.accuracy or (accuracy == entry.accuracy and accuracy or -1)
        else
            vehicles += 1
        end
    end

    return {
        type = 'multi',
        count = count,
        peds = peds,
        vehicles = vehicles,
        objects = objectCount,
        mode = mode,
        range = range,
        accuracy = accuracy,
    }
end

local lastInspect = 0
local lastInspectJson = ''

---@param now integer
---@param force? boolean
local function publishInspect(now, force)
    if not force and not state.selectionDirty and now - lastInspect < 500 then return end

    lastInspect = now
    state.selectionDirty = false

    local data = inspectData()
    local encoded = data and json.encode(data) or ''

    if not force and encoded == lastInspectJson then return end

    lastInspectJson = encoded
    nui.send('inspect', data or false)
end

local function clearItem()
    state.item = nil
    state.mode = 'select'
    spawn.clearPreview()
    nui.send('itemCleared')
end

local function deleteSelection()
    local netIds, objectIds = selection.deletable()

    if #netIds == 0 and #objectIds == 0 then return end

    selection.clear()

    CreateThread(function()
        local removed = 0
        local skipped = 0

        if #netIds > 0 then
            local result = lib.callback.await('sm_gamemaster:server:delete', false, netIds)

            if type(result) == 'table' and result.ok then
                removed += result.removed or 0
                skipped += result.skipped or 0
            else
                nui.log('error', type(result) == 'table' and result.reason or 'Server tidak merespons')
            end
        end

        if #objectIds > 0 then
            local result = lib.callback.await('sm_gamemaster:server:objectRemove', false, objectIds)

            if type(result) == 'table' and result.ok then
                removed += result.removed or 0
            else
                nui.log('error', type(result) == 'table' and result.reason or 'Server tidak merespons')
            end
        end

        if skipped > 0 then
            nui.log('warn', ('%d dihapus, %d dilewati (milik player/garasi)'):format(removed, skipped))
        elseif removed > 0 then
            nui.log('success', ('%d entitas dihapus'):format(removed))
        end
    end)
end

local leave

---@param ped integer
local function startImpersonate(ped)
    impersonate.start(ped, function()
        leave(false)
    end)
end

menu.setHooks({
    impersonate = startImpersonate,
    delete = deleteSelection,
    modify = placement.modify,
})

local quota = { count = 0, max = config.spawn.maxEntities }

RegisterNetEvent('sm_gamemaster:client:quota', function(count, max)
    quota.count = tonumber(count) or 0
    quota.max = tonumber(max) or quota.max
    nui.send('quota', quota)
end)

local rmb = { held = false, x = 0.0, y = 0.0 }
local click = { entity = 0, at = 0 }
local radialOpen = false

---@return { ped?: integer, vehicle?: integer, ground?: vector3, object?: integer }
local function contextUnderCursor()
    local coords, entity = camera.raycast(-1)
    local ctx = {}

    if entity ~= 0 and DoesEntityExist(entity) then
        if IsEntityAPed(entity) then
            ctx.ped = entity
        elseif IsEntityAVehicle(entity) and NetworkGetEntityIsNetworked(entity) then
            ctx.vehicle = entity
            ctx.ped = selection.occupantNear(entity)
        elseif objects.idOf(entity) then
            ctx.object = entity
        end
    end

    ctx.ground = coords and util.toGround(coords) or camera.ground()

    return ctx
end

local function handleSelectClick()
    local _, entity = camera.raycast(-1)

    if entity ~= 0 and IsEntityAVehicle(entity) then
        entity = selection.occupantNear(entity) or entity
    end

    if entity == 0 or not selection.pickable(entity) then
        if not state.options.pickPeds and selection.isPed(entity) then
            nui.log('warn', 'Filter NPC di panel kanan (Bisa Dipilih) sedang mati')
        elseif not state.options.pickVehicles and selection.isVehicle(entity) then
            nui.log('warn', 'Filter Kendaraan di panel kanan (Bisa Dipilih) sedang mati')
        end

        if not keys.shift() and not keys.ctrl() then
            selection.clear()
        end

        return
    end

    local now = GetGameTimer()

    if keys.ctrl() then
        selection.remove(entity)
    elseif keys.shift() then
        selection.add(entity)
    else
        selection.set({ entity })

        if click.entity == entity and now - click.at <= DOUBLE_CLICK_MS and selection.isPed(entity) then
            camera.follow(entity, 12.0)
            click.entity = 0
            return
        end
    end

    click.entity = entity
    click.at = now
end

---@param pressed boolean
---@param down boolean
---@param released boolean
local function handleLmb(pressed, down, released)
    local hold = spawn.hold()

    if pressed and not state.overUi and not state.menuOpen then
        if state.mode == 'spawn' and state.item then
            local ground = camera.ground()

            if ground then
                if state.item.kind == 'object' then
                    placement.begin(state.item.model, ground)
                else
                    spawn.holdStart(ground)
                end
            end
        else
            handleSelectClick()
        end
    end

    if hold and down then
        spawn.holdUpdate(camera.ground())
    end

    if hold and released then
        local item = state.item
        local pos, heading = spawn.holdEnd(not state.overUi and camera.ground() or nil)

        if item and pos and item.kind ~= 'object' then
            CreateThread(function()
                spawn.request(item.kind, item.model, pos, heading)
            end)
        end
    end
end

---@param pressed boolean
---@param down boolean
---@param released boolean
local function handleRmb(pressed, down, released)
    if pressed and not state.overUi then
        if state.mode == 'spawn' then
            clearItem()
            return
        end

        rmb.held = true
        rmb.x = state.cursorX
        rmb.y = state.cursorY
        state.rmbDragging = false
    end

    if not rmb.held then return end

    if down and not state.rmbDragging then
        if abs(state.cursorX - rmb.x) >= 0.02 or abs(state.cursorY - rmb.y) >= 0.02 then
            state.rmbDragging = true
        end
    end

    if not released then return end

    local dragging = state.rmbDragging

    rmb.held = false
    state.rmbDragging = false

    if dragging and #state.selection > 0 then
        local target = camera.ground()

        if target and not state.overUi then
            local kind = state.options.path and 'path' or 'direct'

            CreateThread(function()
                orders.goTo(target, kind)
            end)
        end

        return
    end

    local ctx = contextUnderCursor()

    if #state.selection == 0 then
        local target = ctx.ped or ctx.vehicle

        if target and selection.pickable(target) then
            selection.set({ target })
        end
    end

    menu.open(ctx)
end

local function handleShortcuts()
    if (keys.pressed(keys.DELETE) or keys.pressed(keys.BACKSPACE)) and #state.selection > 0 then
        nui.send('confirmDelete', { count = #state.selection })
    end

    if keys.pressed(keys.ENTER) and #state.selection == 1 and selection.isObject(state.selection[1]) then
        placement.modify(state.selection[1])
    end

    local radialKey = keys.down(keys.B)

    if radialKey and not radialOpen then
        radialOpen = true
        nui.send('radial', { open = true, x = state.cursorX, y = state.cursorY })
    elseif not radialKey and radialOpen then
        radialOpen = false
        nui.send('radial', { open = false })
    end
end

local function updateCursor()
    local x, y = GetNuiCursorPosition()
    local w, h = GetActiveScreenResolution()

    if w > 0 and h > 0 then
        state.screenW = w
        state.screenH = h
        state.cursorX = x / w
        state.cursorY = y / h
    end
end

local lastSync = 0

---@param now integer
local function syncPlayer(now)
    if now - lastSync < 1000 then return end

    lastSync = now

    local ped = PlayerPedId()
    local pos = state.camPos

    hidePlayer(ped)
    SetEntityCoordsNoOffset(ped, pos.x, pos.y, pos.z, false, false, false)
    SetEntityHeading(ped, state.heading)
    LockMinimapAngle(camera.headingInt())

    if selection.prune() or groups.prune() then
        publishGroups()
    end

    control.prune()
end

local function loop()
    local last = GetGameTimer()

    while state.enabled do
        local now = GetGameTimer()
        local dt = min((now - last) / 1000.0, 0.1)

        last = now

        DisableAllControlActions(0)
        EnableControlAction(0, PTT, true)
        DisablePlayerFiring(PlayerId(), true)

        updateCursor()
        camera.update(dt)
        syncPlayer(now)

        if not state.typing and not camera.inTransition() then
            local lmbPressed = IsDisabledControlJustPressed(0, LMB)
            local lmbReleased = IsDisabledControlJustReleased(0, LMB)
            local rmbPressed = IsDisabledControlJustPressed(0, RMB)

            infrared.set(keys.down(keys.TAB) and not placement.active())

            if placement.active() then
                placement.update({ pressed = lmbPressed, released = lmbReleased, rmb = rmbPressed and not state.overUi })
            else
                handleShortcuts()
                handleLmb(lmbPressed, IsDisabledControlPressed(0, LMB), lmbReleased)
                handleRmb(rmbPressed, IsDisabledControlPressed(0, RMB), IsDisabledControlJustReleased(0, RMB))
            end
        else
            infrared.set(false)

            if placement.active() then
                placement.update({ pressed = false, released = false, rmb = false })
            end
        end

        spawn.updatePreview(dt)
        draw.frame()
        publishState(false)
        publishInspect(now)

        Wait(0)
    end
end

---@param teleport boolean
function leave(teleport)
    if not state.enabled then return end

    state.enabled = false
    state.typing = false
    state.overUi = false
    state.rmbDragging = false
    rmb.held = false
    radialOpen = false

    placement.cancel()
    spawn.clearPreview()
    spawn.holdEnd(nil)
    menu.close()
    infrared.set(false)
    selection.clear()
    draw.reset()
    camera.destroy(false)
    UnlockMinimapAngle()
    LocalPlayer.state:set('gamemasterOpen', nil, false)

    local ped = PlayerPedId()

    showPlayer(ped)

    if teleport then
        local entry = state.entryCoords

        if config.exitTeleport == 'entry' and entry then
            SetEntityCoords(ped, entry.x, entry.y, entry.z, false, false, false, false)
            SetEntityHeading(ped, state.entryHeading or 0.0)
        else
            local pos = util.toGround(state.camPos)

            SetEntityCoords(ped, pos.x, pos.y, pos.z, false, false, false, false)
        end
    end

    state.entryCoords = nil
    state.item = nil
    state.mode = 'select'

    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    nui.send('close')

    SetTimeout(250, function()
        if not state.enabled then
            nui.ready = false
            interface.hide()
        end
    end)

    CreateThread(function()
        lib.callback.await('sm_gamemaster:server:session', false, false)
    end)
end

local function enter()
    if state.enabled or not hasFrame then return end

    local ped = PlayerPedId()

    if config.requireAlive and IsEntityDead(ped) then
        lib.notify({ title = 'Gamemaster', description = 'Tidak bisa dipakai saat pingsan.', type = 'error' })
        return
    end

    local session = lib.callback.await('sm_gamemaster:server:session', false, true)

    if type(session) ~= 'table' or not session.ok then
        lib.notify({ title = 'Gamemaster', description = 'Kamu tidak punya izin.', type = 'error' })
        return
    end

    if IsPedInAnyVehicle(ped, false) then
        TaskLeaveVehicle(ped, GetVehiclePedIsIn(ped, false), 16)
        Wait(100)
        ped = PlayerPedId()
    end

    state.enabled = true
    state.entryCoords = GetEntityCoords(ped)
    state.entryHeading = GetEntityHeading(ped)
    state.mode = 'select'
    state.item = nil
    published.count = -1

    hidePlayer(ped)
    LocalPlayer.state:set('gamemasterOpen', true, false)
    camera.create()
    interface.show()
    CreateThread(loop)
end

local toggling = false

local function toggle()
    if toggling then return end

    toggling = true

    if impersonate.active() then
        impersonate.revert()
        Wait(300)
        enter()
    elseif state.enabled then
        leave(true)
    else
        enter()
    end

    toggling = false
end

RegisterNetEvent('sm_gamemaster:client:toggle', function()
    CreateThread(toggle)
end)

AddEventHandler('sm_gamemaster:client:forceClose', function()
    leave(true)
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    leave(false)
end)

local OBJECT_MAX = config.objects.maxStored

local function publishObjectQuota()
    if not state.enabled then return end

    nui.send('objectQuota', { count = objects.count(), max = OBJECT_MAX })
end

RegisterNetEvent('sm_gamemaster:client:objects', function(list)
    objects.setAll(list)
    publishObjectQuota()
end)

RegisterNetEvent('sm_gamemaster:client:objectAdd', function(record)
    objects.add(record)
    publishObjectQuota()
end)

RegisterNetEvent('sm_gamemaster:client:objectUpdate', function(record)
    objects.update(record)
end)

RegisterNetEvent('sm_gamemaster:client:objectRemove', function(ids)
    objects.remove(ids)
    publishObjectQuota()
end)

RegisterNetEvent('sm_gamemaster:client:lightning', function(x, y, z)
    if source == '' then return end

    elements.flash()
    bolt.strike(x, y, z)
end)

local function requestObjects()
    lib.callback('sm_gamemaster:server:objects', false, function() end)
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', requestObjects)

CreateThread(function()
    if LocalPlayer.state.isLoggedIn then
        requestObjects()
    end
end)

---@param value any
---@return boolean?
local function bool(value)
    if type(value) == 'boolean' then return value end

    return nil
end

---@param value any
---@return { kind: string, model: string }[]
local function readFavorites(value)
    local result = {}

    if type(value) ~= 'table' then return result end

    for i = 1, 9 do
        local entry = value[i]

        if type(entry) == 'table' and type(entry.model) == 'string' and (entry.kind == 'ped' or entry.kind == 'vehicle' or entry.kind == 'object') then
            result[i] = { kind = entry.kind, model = entry.model }
        else
            result[i] = false
        end
    end

    return result
end

if hasFrame then
    interface.callback('ready', function(_, cb)
        nui.ready = true
        cb({ ok = true })

        if not state.enabled then return end

        nui.send('open', {
            favorites = readFavorites(readKvp(KVP_FAVORITES)),
            radial = radialSlots(),
            radialCatalog = menu.radialCatalog(),
            options = state.options,
            groups = groups.summary(),
            attackRange = config.attackRange,
            quota = quota,
            objectQuota = { count = objects.count(), max = OBJECT_MAX },
            vehicles = catalog.addons(),
        })

        publishState(true)
        publishInspect(GetGameTimer(), true)
        placement.publish()

        interface.focus(true, true, true)
    end)

    interface.callback('close', function(_, cb)
        cb({ ok = true })
        leave(true)
    end)

    interface.callback('escape', function(_, cb)
        if placement.active() then
            placement.cancel()
            cb({ handled = true })
            return
        end

        if state.item then
            clearItem()
            cb({ handled = true })
            return
        end

        if #state.selection > 0 then
            selection.clear()
            cb({ handled = true })
            return
        end

        cb({ handled = false })
    end)

    interface.callback('pointer', function(data, cb)
        state.overUi = type(data) == 'table' and data.over == true
        cb({ ok = true })
    end)

    interface.callback('typing', function(data, cb)
        local active = type(data) == 'table' and data.active == true

        state.typing = active

        if state.enabled then
            SetNuiFocusKeepInput(not active)
        end

        cb({ ok = true })
    end)

    interface.callback('wheel', function(data, cb)
        local delta = type(data) == 'table' and tonumber(data.delta) or 0

        if state.enabled and not state.typing and delta then
            camera.wheel(delta)
        end

        cb({ ok = true })
    end)

    interface.callback('rect', function(data, cb)
        cb({ ok = true })

        if not state.enabled or state.mode ~= 'select' or placement.active() then return end
        if type(data) ~= 'table' then return end

        local x1 = tonumber(data.x1)
        local y1 = tonumber(data.y1)
        local x2 = tonumber(data.x2)
        local y2 = tonumber(data.y2)

        if not x1 or not y1 or not x2 or not y2 then return end

        selection.rect(x1, y1, x2, y2)
    end)

    interface.callback('item', function(data, cb)
        cb({ ok = true })

        if not state.enabled or type(data) ~= 'table' then return end
        if type(data.model) ~= 'string' then return end

        local kind = data.kind

        if kind ~= 'ped' and kind ~= 'vehicle' and kind ~= 'object' then return end

        placement.cancel()
        spawn.clearPreview()
        state.item = { kind = kind, model = data.model }
        state.mode = 'spawn'
    end)

    interface.callback('clearItem', function(_, cb)
        cb({ ok = true })
        clearItem()
    end)

    interface.callback('options', function(data, cb)
        cb({ ok = true })

        if type(data) ~= 'table' then return end

        local options = state.options

        for i = 1, #SAVED_OPTIONS do
            local key = SAVED_OPTIONS[i]
            local value = bool(data[key])

            if value ~= nil then
                options[key] = value
            end
        end

        writeKvp(KVP_OPTIONS, options)
        placement.publish()
    end)

    interface.callback('menuSelect', function(data, cb)
        cb({ ok = true })

        if type(data) == 'table' and type(data.id) == 'string' then
            menu.select(data.id)
        end
    end)

    interface.callback('menuClosed', function(_, cb)
        cb({ ok = true })
        menu.close()
    end)

    interface.callback('favorites', function(data, cb)
        local favorites = readFavorites(type(data) == 'table' and data.slots or nil)

        writeKvp(KVP_FAVORITES, favorites)
        cb({ ok = true })
    end)

    interface.callback('radialBind', function(data, cb)
        if type(data) ~= 'table' then return cb({ ok = false }) end

        local index = tonumber(data.index)
        local id = data.id

        if not index or index < 1 or index > RADIAL_SLOTS or type(id) ~= 'string' then return cb({ ok = false }) end
        if id ~= '' and not menu.radialValid(id) then return cb({ ok = false }) end

        local slots = radialSlots()

        slots[mfloor(index)] = id
        writeKvp(KVP_RADIAL, slots)

        cb({ ok = true, slots = slots })
    end)

    interface.callback('radialSelect', function(data, cb)
        cb({ ok = true })

        if type(data) == 'table' and type(data.id) == 'string' and data.id ~= '' then
            menu.radialRun(data.id)
        end
    end)

    interface.callback('pedSettings', function(data, cb)
        cb({ ok = true })

        if type(data) ~= 'table' then return end

        local peds = selection.peds()

        if #peds == 0 then return end

        CreateThread(function()
            control.ensure(peds)

            local mode = data.mode
            local range = tonumber(data.range)
            local accuracy = tonumber(data.accuracy)

            for i = 1, #peds do
                local ped = peds[i]

                if DoesEntityExist(ped) then
                    if mode == 'none' or mode == 'players' or mode == 'everyone' then
                        orders.setMode(ped, mode)
                    end

                    if range then
                        orders.setRange(ped, range)
                    end

                    if accuracy then
                        orders.setAccuracy(ped, accuracy)
                    end
                end
            end

            publishInspect(GetGameTimer(), true)
        end)
    end)

    interface.callback('rangePreview', function(data, cb)
        cb({ ok = true })

        local peds = selection.peds()
        local range = type(data) == 'table' and tonumber(data.range) or nil

        if #peds > 0 and range then
            orders.previewRange(peds[1], util.clamp(range, config.attackRange.min, config.attackRange.max))
        end
    end)

    interface.callback('follow', function(_, cb)
        cb({ ok = true })

        local entity = state.selection[1]

        if state.follow then
            camera.stopFollow()
        elseif entity and DoesEntityExist(entity) then
            camera.follow(entity, 12.0)
        end
    end)

    interface.callback('objectList', function(_, cb)
        local cam = state.camPos
        local result = {}
        local count = 0

        ---@param id string
        ---@param kind string
        ---@param model string
        ---@param x number
        ---@param y number
        ---@param z number
        ---@param persist boolean
        ---@param by? string
        local function push(id, kind, model, x, y, z, persist, by)
            local dx = x - cam.x
            local dy = y - cam.y
            local dz = z - cam.z

            count += 1
            result[count] = {
                id = id,
                kind = kind,
                model = model,
                persist = persist,
                by = by,
                distance = mfloor(math.sqrt(dx * dx + dy * dy + dz * dz)),
            }
        end

        local list = objects.list()

        for i = 1, #list do
            local record = list[i]

            push('o:' .. record.id, 'object', record.model, record.x, record.y, record.z, record.persist, nil)
        end

        local remote = lib.callback.await('sm_gamemaster:server:entities', false)

        if type(remote) == 'table' and remote.ok and type(remote.entities) == 'table' then
            for i = 1, #remote.entities do
                local entry = remote.entities[i]

                push('n:' .. entry.netId, entry.kind, entry.model, entry.x, entry.y, entry.z, false, entry.by)
            end
        end

        table.sort(result, function(a, b)
            return a.distance < b.distance
        end)

        cb({ ok = true, objects = result })
    end)

    ---@param coords vector3
    ---@param find fun(): integer?
    local function focusOn(coords, find)
        placement.cancel()
        clearItem()
        selection.clear()
        camera.flyTo(coords)

        CreateThread(function()
            local tries = 0

            while state.enabled and tries < 40 do
                local entity = find()

                if entity and entity ~= 0 and DoesEntityExist(entity) then
                    selection.only(entity)
                    return
                end

                tries += 1
                Wait(100)

                if tries == 10 then
                    SetEntityCoordsNoOffset(PlayerPedId(), coords.x, coords.y, coords.z + 10.0, false, false, false)
                end
            end
        end)
    end

    ---@param data any
    ---@return string?, integer?
    local function parseKey(data)
        local key = type(data) == 'table' and type(data.id) == 'string' and data.id or ''

        return key:match('^o:(.+)$'), tonumber(key:match('^n:(%d+)$'))
    end

    interface.callback('objectFocus', function(data, cb)
        local objectId, netId = parseKey(data)

        if objectId then
            local record = objects.record(objectId)

            if not record then return cb({ ok = false, reason = 'Objek tidak ditemukan' }) end

            cb({ ok = true })
            focusOn(vector3(record.x, record.y, record.z), function()
                return objects.entityOf(objectId)
            end)

            return
        end

        if not netId then return cb({ ok = false, reason = 'Data tidak valid' }) end

        local coords = lib.callback.await('sm_gamemaster:server:locate', false, netId)

        if type(coords) ~= 'table' or not coords.x then return cb({ ok = false, reason = 'Entitas sudah tidak ada' }) end

        cb({ ok = true })
        focusOn(vector3(coords.x, coords.y, coords.z), function()
            if not NetworkDoesEntityExistWithNetworkId(netId) then return nil end

            return NetworkGetEntityFromNetworkId(netId)
        end)
    end)

    interface.callback('objectDelete', function(data, cb)
        local objectId, netId = parseKey(data)
        local result

        if objectId then
            result = lib.callback.await('sm_gamemaster:server:objectRemove', false, { objectId })
        elseif netId then
            result = lib.callback.await('sm_gamemaster:server:delete', false, { netId })

            if type(result) == 'table' and result.ok and (result.removed or 0) == 0 then
                result = { ok = false, reason = 'Entitas tidak bisa dihapus (sedang dipakai player)' }
            end
        else
            return cb({ ok = false, reason = 'Data tidak valid' })
        end

        if type(result) ~= 'table' or not result.ok then
            return cb({ ok = false, reason = type(result) == 'table' and result.reason or 'Server tidak merespons' })
        end

        cb({ ok = true })
    end)

    interface.callback('modify', function(_, cb)
        cb({ ok = true })

        local entity = state.selection[1]

        if #state.selection == 1 and selection.isObject(entity) then
            placement.modify(entity)
        end
    end)

    interface.callback('delete', function(_, cb)
        cb({ ok = true })
        deleteSelection()
    end)

    interface.callback('cleanup', function(_, cb)
        local result = lib.callback.await('sm_gamemaster:server:cleanup', false)

        if type(result) ~= 'table' or not result.ok then
            return cb({ ok = false, reason = type(result) == 'table' and result.reason or 'Server tidak merespons' })
        end

        selection.prune()
        cb({ ok = true, removed = result.removed })
    end)

    interface.callback('groupCreate', function(data, cb)
        local name = type(data) == 'table' and type(data.name) == 'string' and data.name or ''

        name = name:sub(1, 32)

        if name == '' then return cb({ ok = false, reason = 'Nama grup wajib diisi' }) end

        local id = groups.create(name)

        if #state.selection > 0 then
            groups.add(id, state.selection)
        end

        publishGroups()
        cb({ ok = true, id = id })
    end)

    interface.callback('groupDelete', function(data, cb)
        if type(data) == 'table' and type(data.id) == 'string' then
            groups.delete(data.id)
            publishGroups()
        end

        cb({ ok = true })
    end)

    interface.callback('groupAdd', function(data, cb)
        if type(data) == 'table' and type(data.id) == 'string' then
            groups.add(data.id, state.selection)
            publishGroups()
            state.selectionDirty = true
        end

        cb({ ok = true })
    end)

    interface.callback('groupRemove', function(data, cb)
        if type(data) == 'table' and type(data.id) == 'string' then
            groups.remove(data.id, state.selection)
            publishGroups()
            state.selectionDirty = true
        end

        cb({ ok = true })
    end)

    interface.callback('groupSelect', function(data, cb)
        if type(data) == 'table' and type(data.id) == 'string' then
            selection.set(groups.members(data.id))
        end

        cb({ ok = true })
    end)

    interface.callback('placement', function(data, cb)
        cb({ ok = true })

        if type(data) ~= 'table' then return end

        if data.action == 'mode' then
            placement.toggleMode()
        elseif data.action == 'confirm' then
            placement.confirm()
        elseif data.action == 'cancel' then
            placement.cancel()
        end
    end)

end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    impersonate.abort()

    if state.enabled then
        state.enabled = false
        placement.cancel()
        spawn.clearPreview()
        infrared.set(false)
        camera.destroy(true)
        UnlockMinimapAngle()
        LocalPlayer.state:set('gamemasterOpen', nil, false)

        local ped = PlayerPedId()

        showPlayer(ped)

        local entry = state.entryCoords

        if entry then
            SetEntityCoords(ped, entry.x, entry.y, entry.z, false, false, false, false)
        end

        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
    end

    orders.reset()
    objects.clear()
    elements.clear()
end)
