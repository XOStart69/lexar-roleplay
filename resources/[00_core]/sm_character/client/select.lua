local config = require 'config.client'
local register = require 'config.register'
local camera = require 'modules.client.camera'
local utils = require 'modules.client.utils'
local world = require 'modules.client.world'
local nui = require 'modules.client.nui'
local net = require 'modules.net'
local spawn = require 'client.spawn'

local selection = config.selection

local FEMALE <const> = `mp_f_freemode_01`

local select = {}

local state = {
    active = false,
    busy = false,
    registering = false,
    index = 1,
    characters = {},
    incoming = {},
    outgoing = {},
    slots = 0,
    canCreate = false,
    canDelete = false,
}

---@type table<string, string|false>
local skins = {}
---@type table<string, table>
local decoded = {}
---@type table<string, { duo: boolean, coords: vector4 }>
local spots = {}
---@type table|false|nil
local received

local STAGE_BLEND <const> = 1000.0
local SETTLE_BLEND <const> = 1.0
local EXIT_BLEND <const> = 2.0
local LEAVE_BLEND <const> = -1.5
local HEAD_BONE <const> = 31086
local PARTNER_TIMEOUT <const> = 300000
local PROP_TIMEOUT <const> = 30000
local FETCH_TIMEOUT <const> = 30000
local SKIN_TIMEOUT <const> = 10000
local SETTLE_TIMEOUT <const> = 5000

local staged = { handle = nil, anchor = nil, dict = nil, origin = nil, idle = nil, partner = nil, placeholder = nil, bed = nil, view = nil, props = {} }

---@param data table<string, string|false>
local function storeSkins(data)
    for citizenid, raw in pairs(data) do
        skins[citizenid] = raw
        decoded[citizenid] = nil
    end
end

RegisterNetEvent('sm_characters:client:skins', function(data)
    if source == '' or type(data) ~= 'table' then return end

    storeSkins(data)
end)

RegisterNetEvent('sm_characters:client:characters', function(payload)
    if source == '' then return end

    received = type(payload) == 'table' and payload or false
end)

---@param citizenid string
---@param gender 'male'|'female'
---@return table
local function skinFor(citizenid, gender)
    local skin = decoded[citizenid]

    if not skin then
        skin = utils.decodeSkin(skins[citizenid]) or utils.defaultAppearance(gender)
        decoded[citizenid] = skin
    end

    return skin
end

---@param citizenid string
---@param ms number
---@return boolean received
local function waitSkin(citizenid, ms)
    return net.awaitPush(function() return skins[citizenid] end, ms) ~= nil
end

---@param citizenid string
---@return table?, integer?
local function findCharacter(citizenid)
    for i = 1, #state.characters do
        if state.characters[i].citizenid == citizenid then
            return state.characters[i], i
        end
    end
end

---@param list table[]
---@param test fun(item: table): boolean
local function removeWhere(list, test)
    for i = #list, 1, -1 do
        if test(list[i]) then
            table.remove(list, i)
        end
    end
end

---@return table
local function snapshot()
    return {
        characters = state.characters,
        incoming = state.incoming,
        outgoing = state.outgoing,
        slots = state.slots,
        canCreate = #state.characters < state.slots,
        canDelete = state.canDelete,
        index = state.index,
        registering = state.registering,
        rules = { name = register.name, birthYear = register.birthYear, nationalities = register.nationalities },
    }
end

local function pushUpdate()
    nui.send('update', snapshot())
end

local function clearStage()
    ClearPedTasksImmediately(PlayerPedId())

    if staged.partner and DoesEntityExist(staged.partner) then
        DeleteEntity(staged.partner)
    end

    if staged.placeholder and DoesEntityExist(staged.placeholder) then
        DeleteEntity(staged.placeholder)
    end

    utils.deleteAll(staged.props)

    if staged.dict then
        RemoveAnimDict(staged.dict)
    end

    staged.partner = nil
    staged.placeholder = nil
    staged.dict = nil
    staged.handle = nil
    staged.anchor = nil
    staged.origin = nil
    staged.idle = nil
    staged.bed = nil
    staged.view = nil
end

---@param ped number
---@param partner number
local function walkAway(ped, partner)
    local leave = selection.partnerLeave
    local origin = GetEntityCoords(partner)
    local side = GetOffsetFromEntityGivenWorldCoords(ped, origin.x, origin.y, origin.z).x < 0.0 and -1.0 or 1.0
    local away = GetOffsetFromEntityInWorldCoords(ped, side * leave.side, -leave.back, 0.0)
    local heading = GetHeadingFromVector_2d(away.x - origin.x, away.y - origin.y)
    local deadline = GetGameTimer() + leave.waitMs

    ClearPedTasks(partner)
    TaskGoStraightToCoord(partner, away.x, away.y, away.z, 1.0, leave.waitMs * 2, heading, 0.5)

    CreateThread(function()
        while DoesEntityExist(partner) do
            local far = #(GetEntityCoords(partner) - GetEntityCoords(ped)) >= leave.removeDistance

            if far or IsPedFalling(partner) or GetGameTimer() >= deadline then
                FreezeEntityPosition(partner, true)
                DeleteEntity(partner)
                break
            end

            Wait(0)
        end
    end)
end

---@param ped number
local function settle(ped)
    local origin = staged.origin

    if not staged.idle or not origin then
        staged.anchor = nil
        return ClearPedTasks(ped)
    end

    local handle = CreateSynchronizedScene(origin.x, origin.y, origin.z, 0.0, 0.0, origin.w, 2)

    SetSynchronizedSceneLooped(handle, true)
    TaskSynchronizedScene(ped, handle, staged.dict, staged.idle, SETTLE_BLEND, -4.0, 1, 16, 1000.0, 0)
    staged.handle = handle
    staged.anchor = handle
end

---@param ped number
---@param bed { scene: table, origin: vector4 }
---@return integer
local function leaveBed(ped, bed)
    local scene, origin = bed.scene, bed.origin
    local exit = scene.exits[math.random(#scene.exits)]
    local handle = CreateSynchronizedScene(origin.x, origin.y, origin.z, 0.0, 0.0, origin.w, 2)

    SetSynchronizedSceneHoldLastFrame(handle, true)
    TaskSynchronizedScene(ped, handle, scene.dict, exit.player, EXIT_BLEND, -4.0, 1, 16, 1000.0, 0)

    if staged.partner and DoesEntityExist(staged.partner) then
        TaskSynchronizedScene(staged.partner, handle, scene.dict, exit.partner, EXIT_BLEND, -4.0, 1, 16, 1000.0, 0)
    end

    staged.handle = handle
    staged.anchor = handle
    camera.follow(ped, HEAD_BONE, not scene.camera.focus and scene.camera.shift or 0.0)

    return math.floor(GetAnimDuration(scene.dict, exit.player) * 1000)
end

---@param ped number
---@return integer waitMs
local function leaveStage(ped)
    utils.deleteAll(staged.props)

    if staged.bed then
        return leaveBed(ped, staged.bed)
    end

    local partner = staged.partner

    staged.partner = nil

    if partner and DoesEntityExist(partner) then
        walkAway(ped, partner)
        ClearPedTasks(ped)
        staged.anchor = nil

        return selection.partnerLeave.waitMs
    end

    settle(ped)

    return 0
end

---@return boolean
local function holdStage()
    local handle = staged.anchor

    if not handle or not IsSynchronizedSceneRunning(handle) then return false end

    SetSynchronizedSceneRate(handle, 0.0)

    return true
end

---@param character table
---@param duo boolean
---@return vector4
local function spotFor(character, duo)
    local spot = spots[character.citizenid]

    if spot and spot.duo == duo then return spot.coords end

    local pool = duo and selection.duo or selection.solo
    local coords = pool[math.random(#pool)]

    spots[character.citizenid] = { duo = duo, coords = coords }

    return coords
end

---@param ped number
---@param coords vector4
local function stageDrinking(ped, coords)
    local drinking = selection.drinking

    if not utils.loadAnimDict(drinking.dict) then return end

    staged.dict = drinking.dict

    local origin = vec4(coords.x, coords.y, coords.z - 0.95, drinking.rotation)
    local handle = CreateSynchronizedScene(origin.x, origin.y, origin.z, 0.0, 0.0, origin.w, 2)

    SetSynchronizedSceneLooped(handle, true)
    TaskSynchronizedScene(ped, handle, drinking.dict, drinking.clip, STAGE_BLEND, -4.0, 1, 16, 1000.0, 0)
    staged.origin = origin
    staged.idle = drinking.idle

    for i = 1, #drinking.props do
        local prop = drinking.props[i]
        local object = utils.createObject(prop.model, coords, PROP_TIMEOUT)

        if object then
            staged.props[#staged.props + 1] = object
            PlaySynchronizedEntityAnim(object, handle, prop.clip, drinking.dict, 1000.0, -4.0, 0, 1000.0)
        end
    end

    staged.handle = handle
end

---@param partner table
---@return { bed?: table, anim?: table }?
local function coupleScene(partner)
    waitSkin(partner.citizenid, SKIN_TIMEOUT)

    local beds = selection.bedroom
    local bed = selection.duoScene[partner.type] == 'bedroom' and beds[math.random(#beds)] or nil
    local anims = selection.couple[partner.type]
    local anim = not bed and anims[math.random(#anims)] or nil
    local dict = bed and bed.dict or anim.dict
    local skin = skinFor(partner.citizenid, partner.gender)

    if not utils.loadAnimDict(dict) then return end

    if not utils.loadModel(skin.model, PARTNER_TIMEOUT) then
        RemoveAnimDict(dict)
        return
    end

    return { bed = bed, anim = anim }
end

---@param ped number
---@param coords vector4
---@param partner table
---@param anim table
local function stageCouple(ped, coords, partner, anim)
    local skin = skinFor(partner.citizenid, partner.gender)
    local z, heading, own, other = coords.z, coords.w, nil, nil

    if partner.type == 'bff' then
        z = coords.z - 1.0
        heading = coords.w + 90.0
        own = anim.left
        other = anim.right
    else
        local female = GetEntityModel(ped) == FEMALE

        own = female and anim.female or anim.male
        other = female and anim.male or anim.female
    end

    staged.dict = anim.dict

    local partnerPed = utils.createPed(skin.model, coords, PARTNER_TIMEOUT)
    local handle = CreateSynchronizedScene(coords.x, coords.y, z, 0.0, 0.0, heading, 2)

    SetSynchronizedSceneLooped(handle, true)
    TaskSynchronizedScene(ped, handle, anim.dict, own, STAGE_BLEND, LEAVE_BLEND, 1, 16, 1000.0, 0)
    staged.handle = handle

    if not partnerPed then return end

    utils.applyPed(partnerPed, skin)
    staged.partner = partnerPed
    TaskSynchronizedScene(partnerPed, handle, anim.dict, other, STAGE_BLEND, LEAVE_BLEND, 1, 16, 1000.0, 0)
end

---@param ped number
---@param bed table
---@param partner table
local function stageBed(ped, bed, partner)
    local skin = skinFor(partner.citizenid, partner.gender)
    local origin = vec4(bed.coords.x, bed.coords.y, bed.coords.z + bed.deltaZ, bed.coords.w)

    staged.dict = bed.dict

    local partnerPed = utils.createPed(skin.model, bed.coords, PARTNER_TIMEOUT)
    local handle = CreateSynchronizedScene(origin.x, origin.y, origin.z, 0.0, 0.0, origin.w, 2)

    SetSynchronizedSceneLooped(handle, true)
    TaskSynchronizedScene(ped, handle, bed.dict, bed.idle.player, STAGE_BLEND, -4.0, 1, 16, 1000.0, 0)
    staged.handle = handle
    staged.bed = { scene = bed, origin = origin }

    if not partnerPed then return end

    utils.applyPed(partnerPed, skin)
    staged.partner = partnerPed
    TaskSynchronizedScene(partnerPed, handle, bed.dict, bed.idle.partner, STAGE_BLEND, -4.0, 1, 16, 1000.0, 0)
end

---@param ped number
---@param scene table
local function stageChild(ped, scene)
    local coords = scene.coords
    local found, ground = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + 0.5, false)

    SetEntityCoords(ped, coords.x, coords.y, found and ground or coords.z - 1.0, false, false, false, false)
    SetEntityHeading(ped, coords.w)

    if not utils.loadAnimDict(scene.dict) then return end

    staged.dict = scene.dict
    TaskPlayAnim(ped, scene.dict, scene.clip, 5.0, 5.0, -1, scene.flag, 0.0, false, false, false)
end

---@param ped number
---@param anchor vector3
---@param heading number
---@param view table
---@return CameraFocus
local function sceneView(ped, anchor, heading, view)
    local position, focus = view.position, view.focus
    local eye = GetOffsetFromCoordAndHeadingInWorldCoords(anchor.x, anchor.y, anchor.z, heading, position.x, position.y, position.z)
    local target = focus and GetOffsetFromCoordAndHeadingInWorldCoords(anchor.x, anchor.y, anchor.z, heading, focus.x, focus.y, focus.z)
        or camera.aside(eye, GetPedBoneCoords(ped, HEAD_BONE, 0.0, 0.0, 0.0), view.shift or 0.0)

    staged.view = { config = view, anchor = anchor, heading = heading, label = 'camera' }

    return {
        position = eye,
        target = target,
        fov = view.fov,
        dof = { near = 0.5, far = 4.0 },
    }
end

---@param ped number
---@return vector3
local function anchorOf(ped)
    local coords = GetEntityCoords(ped)
    local partner = staged.partner

    if partner and DoesEntityExist(partner) then
        return (coords + GetEntityCoords(partner)) / 2
    end

    return coords
end

---@param spot vector4
---@param anchor vector3
---@param duo boolean
---@return CameraFocus
local function viewFor(spot, anchor, duo)
    local view = duo and selection.camera.duo or selection.camera.solo
    local position, focus = view.position, view.focus

    staged.view = { config = view, anchor = anchor, heading = spot.w, label = duo and 'duo' or 'solo' }

    return {
        position = GetOffsetFromCoordAndHeadingInWorldCoords(anchor.x, anchor.y, anchor.z, spot.w, position.x, position.y, position.z),
        target = GetOffsetFromCoordAndHeadingInWorldCoords(anchor.x, anchor.y, anchor.z, spot.w, focus.x, focus.y, focus.z),
        fov = view.fov,
        dof = { near = 0.5, far = 4.0 },
    }
end

---@param model string|number
local function requestModel(model)
    local hash = type(model) == 'string' and joaat(model) or model

    if IsModelInCdimage(hash) then
        RequestModel(hash)
    end
end

---@param character table
---@param child table?
---@param partner table?
local function prefetch(character, child, partner)
    requestModel(skinFor(character.citizenid, character.gender).model)

    if child then
        RequestAnimDict(child.dict)
        return
    end

    if not partner then
        local drinking = selection.drinking

        RequestAnimDict(drinking.dict)

        for i = 1, #drinking.props do
            requestModel(drinking.props[i].model)
        end

        return
    end

    if waitSkin(partner.citizenid, SKIN_TIMEOUT) then
        requestModel(skinFor(partner.citizenid, partner.gender).model)
    end

    local scenes = selection.duoScene[partner.type] == 'bedroom' and selection.bedroom or selection.couple[partner.type]

    for i = 1, #scenes do
        RequestAnimDict(scenes[i].dict)
    end
end

---@param character table
---@return CameraFocus
local function buildPreview(character)
    clearStage()

    if not waitSkin(character.citizenid, SKIN_TIMEOUT) then
        lib.print.warn(('memuat karakter: skin %s belum diterima, pakai default'):format(character.citizenid))
    end

    local child = character.child and selection.child or nil
    local partner = not child and character.partner or nil

    if partner?.child then
        partner = nil
    end

    local began = GetGameTimer()

    prefetch(character, child, partner)

    local ped = utils.applyPlayer(skinFor(character.citizenid, character.gender), character.gender)
    local modelAt = GetGameTimer()
    local scene = partner and coupleScene(partner)
    local partnerAt = GetGameTimer()
    local bed = scene and scene.bed
    local spot = child and child.coords or bed and bed.coords or spotFor(character, scene ~= nil)

    utils.teleport(ped, spot, true)
    ResetEntityAlpha(ped)
    SetEntityVisible(ped, true, false)

    local placedAt = GetGameTimer()

    if child then
        stageChild(ped, child)
    elseif bed then
        stageBed(ped, bed, partner)
    elseif scene then
        stageCouple(ped, spot, partner, scene.anim)
    else
        stageDrinking(ped, spot)
    end

    lib.print.info(('memuat karakter: model %d ms (%s), pasangan %d ms, lokasi %d ms, pose %d ms'):format(modelAt - began, tostring(skinFor(character.citizenid, character.gender).model), partnerAt - modelAt, placedAt - partnerAt, GetGameTimer() - placedAt))
    Wait(250)

    if child then
        return sceneView(ped, GetEntityCoords(ped), child.coords.w, child.camera)
    elseif bed then
        return sceneView(ped, bed.coords.xyz, bed.coords.w, bed.camera)
    end

    return viewFor(spot, anchorOf(ped), scene ~= nil)
end

---@param build fun(...): CameraFocus
---@param ... any
---@return CameraFocus
local function safely(build, ...)
    local ok, view = pcall(build, ...)

    if ok then return view end

    lib.print.error(('gagal menyiapkan scene: %s'):format(view))

    local spot = selection.solo[1]

    return viewFor(spot, spot.xyz, false)
end

---@param index integer
local function preview(index)
    local character = state.characters[index]
    if not character then return end

    state.index = index
    state.registering = false

    utils.fadeOut(250)
    camera.focus(safely(buildPreview, character))
    utils.fadeIn(400)
end

---@return vector4
local function registerSpot()
    local character = state.characters[state.index]
    local spot = character and spots[character.citizenid]

    if spot and not spot.duo then return spot.coords end

    return selection.solo[math.random(#selection.solo)]
end

---@return CameraFocus
local function buildRegister()
    state.registering = true

    clearStage()

    local spot = registerSpot()
    local placeholder = selection.placeholder
    local player = PlayerPedId()

    utils.teleport(player, spot, true)
    SetEntityVisible(player, false, false)

    local ped = utils.createPed(placeholder.models[math.random(#placeholder.models)], spot)
    local anchor = player

    if ped and DoesEntityExist(ped) then
        SetEntityAlpha(ped, placeholder.alpha, false)
        SetEntityNoCollisionEntity(ped, player, false)
        staged.placeholder = ped
        stageDrinking(ped, spot)
        anchor = ped
        Wait(250)
    end

    return viewFor(spot, GetEntityCoords(anchor), false)
end

local function stageRegister()
    utils.fadeOut(250)
    camera.focus(safely(buildRegister))
    utils.fadeIn(800)
end

---@param citizenid string
local function refreshIfCurrent(citizenid)
    local character = state.characters[state.index]

    if state.active and not state.registering and not state.busy and character?.citizenid == citizenid then
        state.busy = true
        preview(state.index)
        state.busy = false
    end
end

---@return table|false
function select.load()
    received = nil
    table.wipe(skins)
    table.wipe(decoded)

    local began = GetGameTimer()

    TriggerServerEvent('sm_characters:server:fetch')

    local payload = net.awaitPush(function() return received end, FETCH_TIMEOUT)

    if not payload then
        lib.print.warn(('memuat karakter: data %s (%d ms)'):format(payload == false and 'ditolak server' or 'tidak diterima', GetGameTimer() - began))
        return false
    end

    lib.print.info(('memuat karakter: data diterima (%d ms)'):format(GetGameTimer() - began))

    return payload
end

local function settleWorld()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    pcall(lib.waitFor, function()
        RequestCollisionAtCoord(coords.x, coords.y, coords.z)

        return HasCollisionLoadedAroundEntity(ped) or nil
    end, nil, SETTLE_TIMEOUT)
end

---@param payload table
---@return CameraFocus
function select.prepare(payload)
    local began = GetGameTimer()

    state.active = true
    state.busy = true
    state.characters = payload.characters
    state.incoming = payload.incoming
    state.outgoing = payload.outgoing
    state.slots = payload.slots
    state.canDelete = payload.canDelete
    state.index = 1
    state.registering = false

    table.wipe(spots)

    local view = #state.characters == 0 and safely(buildRegister) or safely(buildPreview, state.characters[1])

    lib.print.info(('memuat karakter: scene siap (%d ms)'):format(GetGameTimer() - began))

    return view
end

---@param view CameraFocus
function select.show(view)
    settleWorld()
    spawn.preload()
    world.lock(selection.hour, selection.minute, selection.weather)
    camera.focus(view)
    utils.fadeIn(1200)

    state.busy = false
    nui.send('select', snapshot())
    nui.focus(true)
end

---@param keepStage? boolean
function select.close(keepStage)
    state.active = false

    if not keepStage then
        clearStage()
    end

    nui.send('hide')
    nui.focus(false)
end

---@return boolean
function select.isActive()
    return state.active
end

---@return { config: table, anchor: vector3, heading: number, label: string }?
function select.view()
    return state.active and staged.view or nil
end

---@param kind string
---@param payload table
function select.sync(kind, payload)
    if not state.active then return end

    if kind == 'incoming' then
        state.incoming[#state.incoming + 1] = payload
    elseif kind == 'incomingRemoved' then
        removeWhere(state.incoming, function(item) return item.id == payload.id end)
    elseif kind == 'outgoingRemoved' then
        removeWhere(state.outgoing, function(item) return item.id == payload.id end)
    elseif kind == 'linked' then
        local character = findCharacter(payload.citizenid)

        if character then
            character.partner = payload.partner
            removeWhere(state.outgoing, function(item) return item.sender == payload.citizenid end)
        end
    elseif kind == 'unlinked' then
        local character = findCharacter(payload.citizenid)

        if character then
            character.partner = nil
        end
    end

    pushUpdate()

    if kind == 'linked' or kind == 'unlinked' then
        refreshIfCurrent(payload.citizenid)
    end
end

RegisterNUICallback('preview', function(data, cb)
    local index = math.tointeger(data?.index)

    if not state.active or state.busy or not index or not state.characters[index] then
        return cb(false)
    end

    state.busy = true
    preview(index)
    state.busy = false
    cb(true)
end)

RegisterNUICallback('register', function(data, cb)
    if not state.active or state.busy then return cb(false) end

    state.busy = true

    if data?.open then
        stageRegister()
    elseif #state.characters > 0 then
        preview(state.index)
    end

    state.busy = false
    cb(true)
end)

RegisterNUICallback('create', function(data, cb)
    if not state.active or state.busy or type(data) ~= 'table' then return cb({ error = 'invalid' }) end

    state.busy = true

    local result = lib.callback.await('sm_characters:create', false, {
        firstname = data.firstname,
        lastname = data.lastname,
        birthdate = data.birthdate,
        gender = data.gender,
        nationality = data.nationality,
    })

    if not result?.coords then
        state.busy = false
        return cb({ error = result?.error or 'failed' })
    end

    cb({ ok = true })

    local gender = data.gender == 'female' and 'female' or 'male'

    select.close(true)
    utils.fadeOut(500)
    clearStage()
    utils.applyPlayer(utils.defaultAppearance(gender), gender)
    spawn.newCharacter(result.coords, gender)
end)

RegisterNUICallback('play', function(data, cb)
    local character = state.active and not state.busy and findCharacter(data?.citizenid)
    if not character then return cb(false) end

    state.busy = true

    local list = lib.callback.await('sm_characters:select', false, character.citizenid)

    if not list then
        state.busy = false
        return cb(false)
    end

    cb(true)
    select.close(true)

    local waitMs = leaveStage(PlayerPedId())

    if waitMs > 0 then
        Wait(waitMs)
    end

    local info = { name = ('%s %s'):format(character.firstname, character.lastname), child = character.child }

    spawn.phone(list, info, clearStage, holdStage)
end)

RegisterNUICallback('delete', function(data, cb)
    local character, index = findCharacter(data?.citizenid)
    if not state.active or state.busy or not character or not state.canDelete then return cb(false) end

    state.busy = true

    local ok = lib.callback.await('sm_characters:delete', false, character.citizenid)

    if ok then
        table.remove(state.characters, index)
        spots[character.citizenid] = nil

        if #state.characters == 0 then
            stageRegister()
        else
            preview(1)
        end

        pushUpdate()
    end

    state.busy = false
    cb(ok == true)
end)

RegisterNUICallback('invite', function(data, cb)
    if not state.active or type(data) ~= 'table' then return cb({ error = 'invalid' }) end

    local result = lib.callback.await('sm_characters:partner:invite', false, data.from, data.target, data.type)

    if result?.invite then
        state.outgoing[#state.outgoing + 1] = result.invite
        pushUpdate()
    end

    cb(result or { error = 'failed' })
end)

RegisterNUICallback('inviteRespond', function(data, cb)
    local id = math.tointeger(data?.id)
    if not id then return cb({ error = 'invalid' }) end

    local result = lib.callback.await('sm_characters:partner:respond', false, id, data.accept == true)

    if result?.ok and state.active then
        removeWhere(state.incoming, function(item) return item.id == id end)

        local character = result.partner and findCharacter(result.citizenid)

        if character then
            character.partner = result.partner

            removeWhere(state.incoming, function(item)
                return item.target == result.citizenid or item.sender == result.partner.citizenid
            end)

            removeWhere(state.outgoing, function(item) return item.sender == result.citizenid end)
        end

        pushUpdate()

        if character then
            refreshIfCurrent(result.citizenid)
        end
    end

    cb(result or { error = 'failed' })
end)

RegisterNUICallback('inviteCancel', function(data, cb)
    local id = math.tointeger(data?.id)
    if not state.active or not id then return cb(false) end

    local ok = lib.callback.await('sm_characters:partner:cancel', false, id)

    if ok then
        removeWhere(state.outgoing, function(item) return item.id == id end)
        pushUpdate()
    end

    cb(ok == true)
end)

RegisterNUICallback('partnerRemove', function(data, cb)
    local character = state.active and findCharacter(data?.citizenid)
    if not character then return cb(false) end

    local ok = lib.callback.await('sm_characters:partner:remove', false, character.citizenid)

    if ok then
        character.partner = nil
        pushUpdate()
        refreshIfCurrent(character.citizenid)
    end

    cb(ok == true)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    clearStage()
    camera.destroy(0)
end)

return select
