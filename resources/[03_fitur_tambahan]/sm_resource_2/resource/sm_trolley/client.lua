local config = localmodule 'config'
local interact = exports.rhd_interact
local infoui = exports.rhd_infoui

local Wait = Wait
local GetGameTimer = GetGameTimer
local DoesEntityExist = DoesEntityExist
local NetworkDoesNetworkIdExist = NetworkDoesNetworkIdExist
local NetworkGetEntityFromNetworkId = NetworkGetEntityFromNetworkId
local NetworkHasControlOfEntity = NetworkHasControlOfEntity
local NetworkRequestControlOfEntity = NetworkRequestControlOfEntity
local DisableControlAction = DisableControlAction
local IsEntityPlayingAnim = IsEntityPlayingAnim
local IsEntityAttachedToEntity = IsEntityAttachedToEntity
local IsPedDeadOrDying = IsPedDeadOrDying
local IsPedRagdoll = IsPedRagdoll
local IsPedSwimming = IsPedSwimming
local IsPedInAnyVehicle = IsPedInAnyVehicle
local IsPedFalling = IsPedFalling
local TaskPlayAnim = TaskPlayAnim
local type, pairs = type, pairs

local ATTACH = config.attach
local ANIM_DICT = config.anim.dict
local ANIM_CLIP = config.anim.clip
local ANIM_FLAG = config.anim.flag
local SHARE_STASH = config.shareStash
local INTERACT_DISTANCE = config.interactDistance
local SPAWN_DISTANCE = config.spawnDistance
local INFO_ID = 'sm_trolley:push'
local CONTROLS = { 21, 22, 23, 24, 25, 37, 44, 45, 140, 141, 142, 143, 257, 263, 264 }
local CONTROL_COUNT = #CONTROLS

local EMPTY = {}

---@type table<number, string>
local registered = {}
---@type table<number, number>
local seen = {}
local syncTick = 0
---@type { net: number, id: string }[]
local activeCarts = EMPTY
local pushingCart = false
local releaseKeybind

---@param message? string
---@param kind? string
local function notify(message, kind)
    if not message then return end
    lib.notify({ description = message, type = kind or 'error' })
end

---@param netId number
---@return table?
local function cartState(netId)
    if not NetworkDoesNetworkIdExist(netId) then return nil end
    local entity = NetworkGetEntityFromNetworkId(netId)
    if not DoesEntityExist(entity) then return nil end
    local state = Entity(entity).state
    if not state.smTrolley then return nil end
    return state
end

---@param entity number
---@return boolean
local function requestControl(entity)
    local deadline = GetGameTimer() + 1500
    NetworkRequestControlOfEntity(entity)
    while not NetworkHasControlOfEntity(entity) do
        if GetGameTimer() > deadline or not DoesEntityExist(entity) then return false end
        NetworkRequestControlOfEntity(entity)
        Wait(10)
    end
    return true
end

---@param entity number
local function settleOnGround(entity)
    FreezeEntityPosition(entity, false)
    local coords = GetEntityCoords(entity)
    local found, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + 1.5, false)
    if found then
        SetEntityCoordsNoOffset(entity, coords.x, coords.y, groundZ + 0.5, false, false, false)
    end
    PlaceObjectOnGroundProperly(entity)
    FreezeEntityPosition(entity, true)
end

local function stopPush()
    local entity = pushingCart
    if not entity then return end
    pushingCart = false

    if releaseKeybind then releaseKeybind:disable(true) end
    infoui:remove(INFO_ID)

    local ped = cache.ped
    StopAnimTask(ped, ANIM_DICT, ANIM_CLIP, 2.0)

    if DoesEntityExist(entity) and NetworkHasControlOfEntity(entity) then
        DetachEntity(entity, true, false)
        settleOnGround(entity)
    end

    lib.callback('sm_trolley:release', false, function() end)
end

---@param entity number
local function pushLoop(entity)
    local ped = cache.ped
    local nextCheck = 0

    while pushingCart == entity do
        for i = 1, CONTROL_COUNT do
            DisableControlAction(0, CONTROLS[i], true)
        end

        local now = GetGameTimer()
        if now >= nextCheck then
            nextCheck = now + 250
            ped = cache.ped

            if not DoesEntityExist(entity) or not IsEntityAttachedToEntity(entity, ped)
                or IsPedDeadOrDying(ped, true) or IsPedRagdoll(ped) or IsPedSwimming(ped)
                or IsPedFalling(ped) or IsPedInAnyVehicle(ped, true) then
                stopPush()
                break
            end

            if not IsEntityPlayingAnim(ped, ANIM_DICT, ANIM_CLIP, 3) then
                TaskPlayAnim(ped, ANIM_DICT, ANIM_CLIP, 4.0, 4.0, -1, ANIM_FLAG, 0.0, false, false, false)
            end
        end

        Wait(0)
    end
end

---@param netId number
local function startPush(netId)
    if pushingCart or cache.vehicle then return end

    local ok, err = lib.callback.await('sm_trolley:push', false, netId)
    if not ok then return notify(err) end

    local entity = NetworkDoesNetworkIdExist(netId) and NetworkGetEntityFromNetworkId(netId)
    if not entity or not DoesEntityExist(entity) or not requestControl(entity) then
        lib.callback('sm_trolley:release', false, function() end)
        return notify('Gagal memegang troli.')
    end

    if not pcall(lib.requestAnimDict, ANIM_DICT, 3000) then
        lib.callback('sm_trolley:release', false, function() end)
        return notify('Animasi troli gagal dimuat.')
    end

    local ped = cache.ped
    TriggerEvent('ox_inventory:disarm', true)
    FreezeEntityPosition(entity, false)
    AttachEntityToEntity(entity, ped, GetPedBoneIndex(ped, 0), ATTACH.x, ATTACH.y, ATTACH.z, 0.0, 0.0, ATTACH.heading, false, false, false, false, 2, true)
    TaskPlayAnim(ped, ANIM_DICT, ANIM_CLIP, 4.0, 4.0, -1, ANIM_FLAG, 0.0, false, false, false)

    pushingCart = entity
    if releaseKeybind then releaseKeybind:disable(false) end
    infoui:show({
        id = INFO_ID,
        title = 'Mendorong Troli',
        icon = 'fa-solid fa-cart-shopping',
        description = ('[kbd]%s[/kbd] Lepas troli'):format(releaseKeybind and releaseKeybind.currentKey or config.releaseKey),
    })

    CreateThread(function()
        pushLoop(entity)
    end)
end

---@param netId number
local function openStash(netId)
    local ok, err = lib.callback.await('sm_trolley:open', false, netId)
    if not ok then notify(err) end
end

---@param netId number
local function storeTrolley(netId)
    local ok, err = lib.callback.await('sm_trolley:store', false, netId)
    if ok then
        notify('Troli disimpan.', 'success')
    else
        notify(err)
    end
end

---@param netId number
---@param cartId string
local function register(netId, cartId)
    if registered[netId] then return end
    registered[netId] = cartId
    local suffix = ' #' .. cartId

    interact:addEntity(netId, {
        {
            name = 'sm_trolley:push',
            label = 'Dorong Troli',
            icon = 'fas fa-cart-shopping',
            distance = INTERACT_DISTANCE,
            pointDistance = 5.0,
            canInteract = function()
                if pushingCart then return false end
                local state = cartState(netId)
                return state ~= nil and not state.smTrolleyPusher
            end,
            onSelect = function()
                startPush(netId)
            end,
        },
        {
            name = 'sm_trolley:open',
            label = 'Buka Troli' .. suffix,
            icon = 'fas fa-box-open',
            distance = INTERACT_DISTANCE,
            pointDistance = 5.0,
            canInteract = function()
                if pushingCart then return false end
                local state = cartState(netId)
                if not state or state.smTrolleyPusher then return false end
                return SHARE_STASH or state.smTrolley.owner == cache.serverId
            end,
            onSelect = function()
                openStash(netId)
            end,
        },
        {
            name = 'sm_trolley:store',
            label = 'Simpan Troli',
            icon = 'fas fa-hand-holding',
            distance = INTERACT_DISTANCE,
            pointDistance = 5.0,
            canInteract = function()
                if pushingCart then return false end
                local state = cartState(netId)
                return state ~= nil and not state.smTrolleyPusher and state.smTrolley.owner == cache.serverId
            end,
            onSelect = function()
                storeTrolley(netId)
            end,
        },
    })
end

---@param netId number
local function unregister(netId)
    if not registered[netId] then return end
    registered[netId] = nil
    interact:removeEntity(netId)
end

local function syncCarts()
    local list = activeCarts
    for i = 1, #list do
        local cart = list[i]
        local netId = cart.net
        if NetworkDoesNetworkIdExist(netId) and DoesEntityExist(NetworkGetEntityFromNetworkId(netId)) then
            local current = registered[netId]
            if current and current ~= cart.id then unregister(netId) end
            register(netId, cart.id)
            seen[netId] = syncTick
        end
    end

    for netId in pairs(registered) do
        if seen[netId] ~= syncTick then
            seen[netId] = nil
            unregister(netId)
        end
    end
    syncTick = syncTick + 1
end

AddStateBagChangeHandler('smTrolleys', 'global', function(_, _, value)
    activeCarts = type(value) == 'table' and value or EMPTY
end)

RegisterNetEvent('sm_trolley:client:place', function(slot)
    if pushingCart or cache.vehicle then return end

    local ped = cache.ped
    local front = GetOffsetFromEntityInWorldCoords(ped, 0.0, SPAWN_DISTANCE, 0.0)
    local found, groundZ = GetGroundZFor_3dCoord(front.x, front.y, front.z + 1.0, false)
    local z = found and groundZ or front.z - 1.0

    local heading = (GetEntityHeading(ped) + ATTACH.heading) % 360.0
    local ok, err, netId = lib.callback.await('sm_trolley:place', false, slot, { x = front.x, y = front.y, z = z }, heading)
    if not ok then return notify(err or 'Gagal mengeluarkan troli.') end

    local deadline = GetGameTimer() + 3000
    while not NetworkDoesNetworkIdExist(netId) do
        if GetGameTimer() > deadline then return end
        Wait(50)
    end

    local entity = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(entity) and requestControl(entity) then
        settleOnGround(entity)
    end
end)

CreateThread(function()
    releaseKeybind = lib.addKeybind({
        name = 'sm_trolley_release',
        description = 'Lepas troli',
        defaultKey = config.releaseKey,
        disabled = true,
        onPressed = function()
            stopPush()
        end,
    })

    local initial = GlobalState.smTrolleys
    if type(initial) == 'table' then activeCarts = initial end

    while true do
        syncCarts()
        Wait(500)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end
    if pushingCart then
        local entity = pushingCart
        pushingCart = false
        infoui:remove(INFO_ID)
        StopAnimTask(cache.ped, ANIM_DICT, ANIM_CLIP, 2.0)
        if DoesEntityExist(entity) then DetachEntity(entity, true, false) end
    end
    for netId in pairs(registered) do
        interact:removeEntity(netId)
    end
end)
