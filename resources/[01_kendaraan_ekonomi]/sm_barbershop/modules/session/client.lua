local config = Config
local animation = config.animation
local Nui = require 'modules.nui'
local Sync = require 'modules.sync.client'
local appearance = exports.sm_appearance

local INTERACT_KEY = 38
local SEAT_RADIUS = 0.4
local ROTATION_ORDER = 2
local INSTANT_BLEND = 1000.0
local SMOOTH_BLEND = 8.0
local APPROACH_TIMEOUT = 4000
local KEEPER_WALK_TIMEOUT = 12000
local APPROACH_TASK = 0x2A89B8A7
local TASK_FINISHED = 7
local FADE_STEPS = 6
local FADE_MS = 300
local MIN_CUT_MS = 500
local SCENE_END_PHASE = 0.99
local SCENE_START_GRACE = 2000

local SYNC_USE_PHYSICS = 1
local SYNC_TAG_SYNC_OUT = 2
local SYNC_DONT_INTERRUPT = 4
local SYNC_LOOP_WITHIN_SCENE = 64
local SYNC_EXPAND_CAPSULE = 256

local KEEPER_FLAGS = SYNC_USE_PHYSICS | SYNC_DONT_INTERRUPT | SYNC_LOOP_WITHIN_SCENE

---@class BarberSceneStage
---@field hold boolean
---@field loop boolean
---@field blendIn number
---@field blendOut number
---@field mover number?
---@field flags integer
---@field propFlags integer?

---@type table<string, BarberSceneStage>
local CUSTOMER_STAGE = {
    enter = { hold = true, loop = false, blendIn = SMOOTH_BLEND, blendOut = -INSTANT_BLEND, mover = SMOOTH_BLEND, flags = SYNC_LOOP_WITHIN_SCENE | SYNC_DONT_INTERRUPT },
    seated = { hold = false, loop = true, blendIn = INSTANT_BLEND, blendOut = -8.0, flags = SYNC_DONT_INTERRUPT },
    exit = { hold = false, loop = false, blendIn = INSTANT_BLEND, blendOut = -1.0, flags = SYNC_USE_PHYSICS | SYNC_TAG_SYNC_OUT | SYNC_DONT_INTERRUPT | SYNC_EXPAND_CAPSULE },
}

---@type table<string, BarberSceneStage>
local KEEPER_STAGE = {
    enter = { hold = true, loop = false, blendIn = SMOOTH_BLEND, blendOut = -INSTANT_BLEND, mover = SMOOTH_BLEND, flags = KEEPER_FLAGS, propFlags = SYNC_LOOP_WITHIN_SCENE },
    base = { hold = false, loop = true, blendIn = INSTANT_BLEND, blendOut = -INSTANT_BLEND, flags = KEEPER_FLAGS, propFlags = SYNC_LOOP_WITHIN_SCENE },
    join = { hold = false, loop = true, blendIn = SMOOTH_BLEND, blendOut = -INSTANT_BLEND, mover = SMOOTH_BLEND, flags = KEEPER_FLAGS, propFlags = SYNC_LOOP_WITHIN_SCENE },
    cut = { hold = true, loop = false, blendIn = 4.0, blendOut = -INSTANT_BLEND, flags = KEEPER_FLAGS, propFlags = SYNC_LOOP_WITHIN_SCENE },
    settle = { hold = false, loop = true, blendIn = 4.0, blendOut = -INSTANT_BLEND, flags = KEEPER_FLAGS, propFlags = SYNC_LOOP_WITHIN_SCENE },
    exit = { hold = true, loop = false, blendIn = 4.0, blendOut = -2.0, flags = SYNC_USE_PHYSICS | SYNC_DONT_INTERRUPT, propFlags = 0 },
}

local MOVEMENT_CONTROLS = { 21, 22, 23, 24, 25, 30, 31, 36, 37, 44, 140, 141, 142, 143, 257, 263 }

local WAIT_TEXT = '[E] Berdiri dari kursi'

---@type table<string, string>
local BUNDLES = {}

for i = 1, #config.priceItems do
    local item = config.priceItems[i]

    if item.includedWith then
        BUNDLES[item.key] = item.includedWith
    end
end

---@class BarberChairEntry
---@field shop string
---@field index number|string
---@field coords vector4
---@field seat vector3?
---@field portable boolean?
---@field ownerId number?

---@class BarberSceneOrigin
---@field pos vector3
---@field heading number
---@field dict string
---@field set BarberAnimationSet

---@class BarberSeat
---@field shop string
---@field chair number|string
---@field origin BarberSceneOrigin
---@field seated string
---@field stage BarberSeatStage
---@field snapshot table?

---@class BarberService
---@field mode 'barber'|'self'
---@field origin BarberSceneOrigin
---@field keeper number
---@field networked boolean
---@field scissors number?
---@field customerId number?
---@field customerPed number?
---@field result (BarberServiceStart|BarberSelfStart)?
---@field stage BarberServiceStage
---@field entered boolean?
---@field attached boolean?
---@field ready boolean?
---@field arrived boolean?

---@type BarberChairEntry[]
local chairs = {}

---@type table<string, BarberAnimationSet>
local shopAnimation = {}

for i = 1, #config.shops do
    local shop = config.shops[i]

    shopAnimation[shop.id] = animation.sets[shop.animation or 'barbers']

    for j = 1, #shop.coords.chairs do
        chairs[#chairs + 1] = { shop = shop.id, index = j, coords = shop.coords.chairs[j] }
    end
end

---@type BarberSeat?
local customer

---@type BarberService?
local service

local busy = false
local exiting = false

local function notify(notifyType, description)
    lib.notify({ type = notifyType, description = description })
end

---@param list string[]
---@return string
local function pick(list)
    return list[math.random(#list)]
end

---@param entry BarberChairEntry
---@return BarberSceneOrigin
local function sceneOrigin(entry)
    local coords = entry.coords
    local set = entry.portable and animation.sets[config.portable.animation] or shopAnimation[entry.shop] or animation.sets.barbers

    return {
        pos = coords.xyz,
        heading = coords.w + config.scene.headingOffset,
        dict = set.dict,
        set = set,
    }
end

---@param origin BarberSceneOrigin
---@param clip string
---@return vector3 position
---@return number heading
local function clipStart(origin, clip)
    local pos = origin.pos
    local start = GetAnimInitialOffsetPosition(origin.dict, clip, pos.x, pos.y, pos.z, 0.0, 0.0, origin.heading, 0.0, ROTATION_ORDER)
    local rotation = GetAnimInitialOffsetRotation(origin.dict, clip, pos.x, pos.y, pos.z, 0.0, 0.0, origin.heading, 0.0, ROTATION_ORDER)

    return start, rotation.z
end

---@param origin BarberSceneOrigin
---@param clip string
---@return integer
local function clipDuration(origin, clip)
    return math.floor(GetAnimDuration(origin.dict, clip) * 1000)
end

---@param clip string
---@return string
local function propClip(clip)
    return (clip:gsub('^keeper_', 'scissors_'))
end

---@param list BarberChairEntry[]
---@param coords vector3
---@param best BarberChairEntry?
---@param bestDistance number?
---@return BarberChairEntry?
---@return number?
local function closer(list, coords, best, bestDistance)
    for i = 1, #list do
        local entry = list[i]
        local distance = #(coords - entry.coords.xyz)

        if distance <= config.chairDistance and (not bestDistance or distance < bestDistance) then
            best, bestDistance = entry, distance
        end
    end

    return best, bestDistance
end

---@param coords vector3
---@return BarberChairEntry?
local function nearestChair(coords)
    local best, bestDistance = closer(chairs, coords)

    return (closer(Sync.portables(), coords, best, bestDistance))
end

---@param entry BarberChairEntry
---@return vector3?
local function seatPosition(entry)
    if entry.seat then return entry.seat end

    local origin = sceneOrigin(entry)

    if not HasAnimDictLoaded(origin.dict) then
        RequestAnimDict(origin.dict)

        return
    end

    entry.seat = clipStart(origin, origin.set.seated[1])

    return entry.seat
end

---@param entry BarberChairEntry
---@return boolean
local function chairFree(entry)
    if Sync.chair(entry.shop, entry.index) then return false end

    local seat = seatPosition(entry)

    if not seat then return true end

    if #lib.getNearbyPlayers(seat, SEAT_RADIUS, false) > 0 then
        return false
    end

    return lib.getClosestPed(seat, SEAT_RADIUS) == nil
end

---@param ped number
---@param origin BarberSceneOrigin
---@param clip string
---@param stage BarberSceneStage
---@param prop number?
---@return integer netScene
local function playNetworkScene(ped, origin, clip, stage, prop)
    local pos = origin.pos
    local scene = NetworkCreateSynchronisedScene(pos.x, pos.y, pos.z, 0.0, 0.0, origin.heading, ROTATION_ORDER, stage.hold, stage.loop, 1.0, 0.0, 1.0)

    NetworkAddPedToSynchronisedScene(ped, scene, origin.dict, clip, stage.blendIn, stage.blendOut, stage.flags, 0, stage.mover or INSTANT_BLEND, 0)

    if prop and DoesEntityExist(prop) then
        FreezeEntityPosition(prop, false)
        NetworkAddEntityToSynchronisedScene(prop, scene, origin.dict, propClip(clip), INSTANT_BLEND, -INSTANT_BLEND, stage.propFlags or 0)
    end

    NetworkStartSynchronisedScene(scene)

    return scene
end

---@param scene integer
---@param networked boolean
---@param phase number
---@param timeout integer
---@param active (fun(): boolean)?
---@return boolean reached
local function waitScenePhase(scene, networked, phase, timeout, active)
    local deadline = GetGameTimer() + timeout
    local started = false

    while GetGameTimer() < deadline and (not active or active()) do
        local id = networked and NetworkGetLocalSceneFromNetworkId(scene) or scene

        if id ~= -1 and IsSynchronizedSceneRunning(id) then
            started = true

            if GetSynchronizedScenePhase(id) >= phase then return true end
        elseif started then
            return false
        end

        Wait(0)
    end

    return false
end

---@param ped number
---@param origin BarberSceneOrigin
---@param clip string
---@param stage BarberSceneStage
---@param prop number?
---@return integer scene
local function playLocalScene(ped, origin, clip, stage, prop)
    local pos = origin.pos
    local scene = CreateSynchronizedScene(pos.x, pos.y, pos.z, 0.0, 0.0, origin.heading, ROTATION_ORDER)

    SetSynchronizedSceneHoldLastFrame(scene, stage.hold)
    SetSynchronizedSceneLooped(scene, stage.loop)
    TaskSynchronizedScene(ped, scene, origin.dict, clip, stage.blendIn, stage.blendOut, stage.flags, 0, stage.mover or INSTANT_BLEND, 0)

    if prop and DoesEntityExist(prop) then
        FreezeEntityPosition(prop, false)
        PlaySynchronizedEntityAnim(prop, scene, propClip(clip), origin.dict, INSTANT_BLEND, -INSTANT_BLEND, 0, INSTANT_BLEND)
        ForceEntityAiAndAnimationUpdate(prop)
    end

    return scene
end

---@param current BarberService
---@param clip string
---@param stage BarberSceneStage
---@return integer? scene
local function playKeeper(current, clip, stage)
    if not DoesEntityExist(current.keeper) then return end

    local prop = not current.attached and current.scissors or nil

    if current.networked then
        return playNetworkScene(current.keeper, current.origin, clip, stage, prop)
    end

    return playLocalScene(current.keeper, current.origin, clip, stage, prop)
end

---@param current BarberService
---@param entry string?
---@return boolean ready
local function keeperEnter(current, entry)
    local origin = current.origin
    local networked = current.networked

    local function active()
        return service == current
    end

    current.entered = true

    if not entry then
        local base = playKeeper(current, 'keeper_base', KEEPER_STAGE.join)

        return base ~= nil and waitScenePhase(base, networked, 0.0, SCENE_START_GRACE, active)
    end

    local enter = playKeeper(current, entry, KEEPER_STAGE.enter)
    local timeout = clipDuration(origin, entry) + SCENE_START_GRACE

    if not enter or not waitScenePhase(enter, networked, SCENE_END_PHASE, timeout, active) then
        return false
    end

    local base = playKeeper(current, 'keeper_base', KEEPER_STAGE.base)

    return base ~= nil and waitScenePhase(base, networked, 0.0, SCENE_START_GRACE, active)
end

---@param ped number
---@param origin BarberSceneOrigin
---@param clip string
---@param timeout integer?
local function approach(ped, origin, clip, timeout)
    local target, heading = clipStart(origin, clip)

    timeout = timeout or APPROACH_TIMEOUT

    if #(target.xy - origin.pos.xy) > 3.0 or #(GetEntityCoords(ped).xy - target.xy) < 0.2 then return end

    TaskFollowNavMeshToCoord(ped, target.x, target.y, target.z, 1.0, timeout, 0.05, 0, heading)

    local deadline = GetGameTimer() + timeout

    repeat
        Wait(0)
    until GetScriptTaskStatus(ped, APPROACH_TASK) == TASK_FINISHED or GetGameTimer() > deadline
end

---@param entities number[]
---@param from integer
---@param to integer
local function fade(entities, from, to)
    for step = 1, FADE_STEPS do
        local alpha = math.floor(from + (to - from) * step / FADE_STEPS)

        for i = 1, #entities do
            if DoesEntityExist(entities[i]) then
                SetEntityAlpha(entities[i], alpha, false)
            end
        end

        Wait(FADE_MS // FADE_STEPS)
    end
end

local function lockPed(ped)
    SetPedCanRagdoll(ped, false)
    SetBlockingOfNonTemporaryEvents(ped, true)
end

local function releasePed(ped)
    FreezeEntityPosition(ped, false)
    SetPedCanRagdoll(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, false)
end

local function unlockPed(ped)
    ClearPedTasks(ped)
    releasePed(ped)
end

---@param seat BarberSeat
local function revertCustomer(seat)
    local snapshot = seat.snapshot

    if snapshot then
        appearance:applyBarberValues({
            hair = snapshot.hair,
            headOverlays = snapshot.headOverlays,
            eyeColor = snapshot.eyeColor,
        })
    end

    appearance:setBarberHat(false)
end

---@param seat BarberSeat
local function sitScene(seat)
    local ped = cache.ped
    local origin = seat.origin

    playNetworkScene(ped, origin, 'player_enterchair', CUSTOMER_STAGE.enter)
    Wait(clipDuration(origin, 'player_enterchair'))

    if customer == seat then
        playNetworkScene(ped, origin, seat.seated, CUSTOMER_STAGE.seated)
    end
end

---@param origin BarberSceneOrigin
local function standScene(origin)
    local ped = cache.ped

    exiting = true

    local scene = playNetworkScene(ped, origin, 'player_exitchair', CUSTOMER_STAGE.exit)

    waitScenePhase(scene, true, config.scene.exitPhase, clipDuration(origin, 'player_exitchair'))
    NetworkStopSynchronisedScene(scene)
    releasePed(ped)
    exiting = false
end

local END_MESSAGES = {
    timeout = { 'warning', 'Sesi self service berakhir.' },
    chair_removed = { 'warning', 'Kursi cukur dibereskan, sesi berakhir.' },
}

local function announce(reason)
    local message = END_MESSAGES[reason]

    if message then
        notify(message[1], message[2])
    end
end

local function customerCleanup(reason)
    local seat = customer

    if not seat then return end

    customer = nil

    Nui.close('invoice', 'barber:invoice:close')
    lib.hideTextUI()
    appearance:closeBarberMenu()

    revertCustomer(seat)
    announce(reason)
    standScene(seat.origin)
end

local function leaveChair()
    if not customer then return end

    if lib.callback.await('sm_barbershop:chair:leave', false) then
        customerCleanup('left')
    end
end

local function seatLoop()
    local seat = customer

    while seat and customer == seat do
        for i = 1, #MOVEMENT_CONTROLS do
            DisableControlAction(0, MOVEMENT_CONTROLS[i], true)
        end

        if (seat.stage == 'waiting' or seat.stage == 'service') and IsControlJustReleased(0, INTERACT_KEY) then
            leaveChair()
        end

        Wait(0)
    end
end

---@param entry BarberChairEntry
local function sitDown(entry)
    if customer or service or busy or exiting then return end

    busy = true

    local result = lib.callback.await('sm_barbershop:chair:sit', false, entry.shop, entry.index)

    if not result.success then
        busy = false

        return notify('error', result.message)
    end

    local origin = sceneOrigin(entry)

    lib.requestAnimDict(origin.dict)

    ---@type BarberSeat
    local seat = { shop = entry.shop, chair = entry.index, origin = origin, seated = pick(origin.set.seated), stage = 'entering' }

    customer = seat
    lockPed(cache.ped)
    approach(cache.ped, origin, 'player_enterchair')

    if customer ~= seat then
        busy = false

        return
    end

    CreateThread(seatLoop)
    sitScene(seat)

    if customer ~= seat then
        busy = false

        return
    end

    seat.stage = 'waiting'

    local seated = lib.callback.await('sm_barbershop:chair:seated', false)

    busy = false

    if customer ~= seat then return end

    if not seated then return leaveChair() end

    lib.showTextUI(WAIT_TEXT, { position = 'right-center' })
end

---@param networked boolean
---@param coords vector3
---@return number
local function createScissors(networked, coords)
    local model = lib.requestModel(animation.scissors)
    local object = CreateObject(model, coords.x, coords.y, coords.z, networked, networked, false)

    SetModelAsNoLongerNeeded(model)
    SetEntityCollision(object, false, false)
    FreezeEntityPosition(object, true)

    if networked then
        local deadline = GetGameTimer() + 1000

        while not NetworkGetEntityIsNetworked(object) and GetGameTimer() < deadline do
            Wait(0)
        end
    end

    return object
end

---@class BarberGrip
---@field bone integer
---@field pos vector3
---@field rot vector3
---@field order integer

local HAND_BONES = { 57005, 18905 }
local GRIP_REACH = 0.35
local GRIP_TOLERANCE = 0.02
local ATTACH_FLAGS = { true, true, false, true }

---@type table<string, BarberGrip|false>
local grips = {}

---@param a vector3
---@param b vector3
---@return number
local function dot(a, b)
    return a.x * b.x + a.y * b.y + a.z * b.z
end

---@param v vector3
---@param bx vector3
---@param by vector3
---@param bz vector3
---@return vector3
local function intoBone(v, bx, by, bz)
    return vec3(dot(v, bx), dot(v, by), dot(v, bz))
end

---@param value number
---@return number
local function unit(value)
    return math.max(-1.0, math.min(1.0, value))
end

---@param entity number
---@return vector3 right
---@return vector3 forward
---@return vector3 up
---@return vector3 at
local function axesOf(entity)
    local at = GetEntityCoords(entity)

    return GetOffsetFromEntityInWorldCoords(entity, 1.0, 0.0, 0.0) - at,
        GetOffsetFromEntityInWorldCoords(entity, 0.0, 1.0, 0.0) - at,
        GetOffsetFromEntityInWorldCoords(entity, 0.0, 0.0, 1.0) - at,
        at
end

local EULER = {
    {
        order = 2,
        solve = function(r, f, u)
            return vec3(math.deg(math.asin(unit(f.z))), math.deg(math.atan(-r.z, u.z)), math.deg(math.atan(-f.x, f.y)))
        end,
    },
    {
        order = 0,
        solve = function(r, f, u)
            return vec3(math.deg(math.atan(f.z, u.z)), math.deg(math.asin(unit(-r.z))), math.deg(math.atan(r.y, r.x)))
        end,
    },
}

---@param entity number
---@param ped number
---@param boneIndex integer
---@param pos vector3
---@param rot vector3
---@param order integer
local function attachTo(entity, ped, boneIndex, pos, rot, order)
    AttachEntityToEntity(entity, ped, boneIndex, pos.x, pos.y, pos.z, rot.x, rot.y, rot.z,
        ATTACH_FLAGS[1], ATTACH_FLAGS[2], ATTACH_FLAGS[3], ATTACH_FLAGS[4], order, true)
end

---@param origin BarberSceneOrigin
---@return BarberGrip|false
local function measureGrip(origin)
    local pos = origin.pos
    local keeperModel = lib.requestModel(origin.set.keeper)
    local propModel = lib.requestModel(animation.scissors)
    local probe = CreatePed(4, keeperModel, pos.x, pos.y, pos.z, origin.heading, false, false)
    local prop = CreateObject(propModel, pos.x, pos.y, pos.z, false, false, false)
    local test = CreateObject(propModel, pos.x, pos.y, pos.z, false, false, false)

    SetModelAsNoLongerNeeded(keeperModel)
    SetModelAsNoLongerNeeded(propModel)

    for _, entity in ipairs({ probe, prop, test }) do
        SetEntityAlpha(entity, 0, false)
        SetEntityCollision(entity, false, false)
    end

    SetEntityInvincible(probe, true)
    SetBlockingOfNonTemporaryEvents(probe, true)

    local scene = CreateSynchronizedScene(pos.x, pos.y, pos.z, 0.0, 0.0, origin.heading, ROTATION_ORDER)

    SetSynchronizedSceneLooped(scene, true)
    TaskSynchronizedScene(probe, scene, origin.dict, 'keeper_base', INSTANT_BLEND, -INSTANT_BLEND, 0, 0, INSTANT_BLEND, 0)
    PlaySynchronizedEntityAnim(prop, scene, propClip('keeper_base'), origin.dict, INSTANT_BLEND, -INSTANT_BLEND, 0, INSTANT_BLEND)

    for _ = 1, 6 do
        ForcePedAiAndAnimationUpdate(probe, false, false)
        ForceEntityAiAndAnimationUpdate(prop)
        Wait(0)
    end

    SetSynchronizedSceneRate(scene, 0.0)
    Wait(0)

    local right, forward, up, at = axesOf(prop)
    local bone, reach = nil, GRIP_REACH

    for i = 1, #HAND_BONES do
        local distance = #(GetPedBoneCoords(probe, HAND_BONES[i], 0.0, 0.0, 0.0) - at)

        if distance < reach then
            bone, reach = HAND_BONES[i], distance
        end
    end

    ---@type BarberGrip|false
    local grip = false

    if bone then
        local base = GetPedBoneCoords(probe, bone, 0.0, 0.0, 0.0)
        local bx = GetPedBoneCoords(probe, bone, 1.0, 0.0, 0.0) - base
        local by = GetPedBoneCoords(probe, bone, 0.0, 1.0, 0.0) - base
        local bz = GetPedBoneCoords(probe, bone, 0.0, 0.0, 1.0) - base
        local offset = intoBone(at - base, bx, by, bz)
        local r, f, u = intoBone(right, bx, by, bz), intoBone(forward, bx, by, bz), intoBone(up, bx, by, bz)
        local boneIndex = GetPedBoneIndex(probe, bone)
        local bestError

        for i = 1, #EULER do
            local candidate = EULER[i]
            local rot = candidate.solve(r, f, u)

            attachTo(test, probe, boneIndex, offset, rot, candidate.order)
            Wait(0)

            local _, testForward, testUp, testAt = axesOf(test)
            local deviation = (1.0 - dot(testForward, forward)) + (1.0 - dot(testUp, up)) + #(testAt - at)

            if not bestError or deviation < bestError then
                bestError = deviation
                grip = { bone = bone, pos = offset, rot = rot, order = candidate.order }
            end

            DetachEntity(test, false, false)
        end

        if bestError and bestError > GRIP_TOLERANCE then
            lib.print.warn(('scissors grip for %s off by %.3f, falling back to the scene'):format(origin.dict, bestError))
            grip = false
        end
    end

    DeleteEntity(test)
    DeleteEntity(prop)
    DeleteEntity(probe)

    return grip
end

---@param origin BarberSceneOrigin
---@return BarberGrip|false
local function gripFor(origin)
    local grip = grips[origin.dict]

    if grip == nil then
        grip = measureGrip(origin)
        grips[origin.dict] = grip
    end

    return grip
end

---@type table<string, vector4>
local pedSpawns = {}

for i = 1, #config.shops do
    pedSpawns[config.shops[i].id] = config.shops[i].coords.pedspawn
end

---@param shopId string
---@param origin BarberSceneOrigin
---@return number npc
---@return number scissors
local function spawnKeeper(shopId, origin)
    local model = lib.requestModel(origin.set.keeper)
    local start, heading = clipStart(origin, 'keeper_enterchair')
    local spawn = pedSpawns[shopId]
    local coords = spawn and spawn.xyz or start
    local npc = CreatePed(4, model, coords.x, coords.y, coords.z, spawn and spawn.w or heading, false, false)

    SetModelAsNoLongerNeeded(model)
    SetEntityAlpha(npc, 0, false)
    SetEntityInvincible(npc, true)
    lockPed(npc)

    local scissors = createScissors(false, start)

    SetEntityAlpha(scissors, 0, false)

    return npc, scissors
end

---@param current BarberService
local function keeperWalk(current)
    local npc = current.keeper

    fade({ npc }, 0, 255)

    if DoesEntityExist(npc) then ResetEntityAlpha(npc) end

    approach(npc, current.origin, 'keeper_enterchair', KEEPER_WALK_TIMEOUT)

    if service ~= current then return end

    if current.scissors and DoesEntityExist(current.scissors) then
        ResetEntityAlpha(current.scissors)
    end

    current.ready = true
end

local function deleteEntity(entity)
    if entity and DoesEntityExist(entity) then
        DeleteEntity(entity)
    end
end

local function endBarberService()
    local current = service

    if not current or current.mode ~= 'barber' then return end

    service = nil
    exiting = true

    appearance:closeBarberMenu()

    local exit = current.entered and playKeeper(current, 'keeper_exitchair', KEEPER_STAGE.exit)

    if exit then
        waitScenePhase(exit, true, config.scene.exitPhase, clipDuration(current.origin, 'keeper_exitchair'))
        NetworkStopSynchronisedScene(exit)
    end

    deleteEntity(current.scissors)
    unlockPed(cache.ped)

    exiting = false
end

local function endSelfService(reason)
    local current = service
    local seat = customer

    if not current or current.mode ~= 'self' then return end

    service = nil
    customer = nil

    appearance:closeBarberMenu()
    announce(reason)

    local exit = current.entered and playKeeper(current, 'keeper_exitchair', KEEPER_STAGE.exit)

    if seat then
        standScene(seat.origin)
    end

    if exit then
        waitScenePhase(exit, false, config.scene.exitPhase, clipDuration(current.origin, 'keeper_exitchair'))
        SetSynchronizedSceneRate(exit, 0.0)
    end

    fade({ current.keeper, current.scissors --[[@as number]] }, 255, 0)
    deleteEntity(current.scissors)
    deleteEntity(current.keeper)
end

---@param current BarberService
---@param result table
---@param customerPed number
local function openServiceMenu(current, result, customerPed)
    local snapshot = result.snapshot

    local opened = appearance:openBarberMenu({
        target = customerPed,
        relay = true,
        appearance = snapshot.appearance,
        hairBlacklist = snapshot.hairBlacklist,
        hatWorn = snapshot.hatWorn,
        title = result.shopLabel,
        subtitle = result.customerName,
        prices = result.prices,
        bundles = BUNDLES,
        action = 'bill',
        onChange = function(values)
            TriggerServerEvent('sm_barbershop:service:preview', values)
        end,
        onHat = function(hidden)
            TriggerServerEvent('sm_barbershop:service:hat', hidden)
        end,
        onSubmit = function(values)
            CreateThread(function()
                local response = lib.callback.await('sm_barbershop:service:finish', false, values)

                if type(response) == 'table' and response.success and service == current then
                    current.stage = 'invoice'
                end

                appearance:resolveBarberMenu(response)
            end)
        end,
        onCancel = function()
            CreateThread(function()
                if service ~= current then return end

                lib.callback.await('sm_barbershop:service:cancel', false)
            end)
        end,
    })

    if not opened then
        lib.callback.await('sm_barbershop:service:cancel', false)

        return
    end

    TriggerServerEvent('sm_barbershop:service:ready')
end

---@param entry BarberChairEntry
local function startService(entry)
    if customer or service or busy or exiting then return end

    busy = true

    local result = lib.callback.await('sm_barbershop:service:start', false, entry.shop, entry.index)

    if not result.success then
        busy = false

        return notify('error', result.message)
    end

    local player = GetPlayerFromServerId(result.customerId)
    local ped = player ~= -1 and GetPlayerPed(player) or 0

    if ped == 0 then
        busy = false
        lib.callback.await('sm_barbershop:service:cancel', false)

        return notify('error', 'Pelanggan tidak terlihat.')
    end

    local origin = sceneOrigin(entry)
    local me = cache.ped

    lib.requestAnimDict(origin.dict)

    ---@type BarberService
    local current = {
        mode = 'barber',
        origin = origin,
        keeper = me,
        networked = true,
        customerId = result.customerId,
        customerPed = ped,
        result = result,
        stage = 'entering',
    }

    service = current
    lockPed(me)
    approach(me, origin, 'keeper_base')

    if service ~= current then
        busy = false

        return
    end

    local grip = gripFor(origin)

    if service ~= current then
        busy = false

        return
    end

    current.scissors = createScissors(true, GetEntityCoords(me))

    if grip then
        FreezeEntityPosition(current.scissors, false)
        attachTo(current.scissors, me, GetPedBoneIndex(me, grip.bone), grip.pos, grip.rot, grip.order)
        current.attached = true
    end

    local ready = keeperEnter(current)

    busy = false

    if service ~= current then return end

    if not ready then
        notify('error', 'Animasi barber gagal dimulai, silakan coba lagi.')
        lib.callback.await('sm_barbershop:service:cancel', false)

        return
    end

    current.stage = 'service'
    openServiceMenu(current, result, ped)
end

---@param current BarberService
---@param seat BarberSeat
---@param result table
local function openSelfMenu(current, seat, result)
    local opened = appearance:openBarberMenu({
        title = result.shopLabel,
        subtitle = 'Self service',
        appearance = result.appearance,
        prices = result.prices,
        bundles = BUNDLES,
        action = 'pay',
        methods = config.payment.methods,
        onSubmit = function(values, method)
            CreateThread(function()
                local response = lib.callback.await('sm_barbershop:selfservice:pay', false, values, method)

                appearance:resolveBarberMenu(response)
            end)
        end,
        onCancel = function()
            CreateThread(function()
                if service ~= current or customer ~= seat then return end

                lib.callback.await('sm_barbershop:chair:leave', false)
            end)
        end,
    })

    if not opened then
        lib.callback.await('sm_barbershop:chair:leave', false)
    end
end

---@param entry BarberChairEntry
local function startSelfService(entry)
    if customer or service or busy or exiting then return end

    local state = Sync.shop(entry.shop)

    if not state then return end

    local answer = lib.alertDialog({
        header = state.label,
        content = ('Harga dihitung per item yang diubah, %s%% dari harga barber. Bayar tunai atau bank setelah selesai. Lanjutkan?'):format(state.selfServiceRate or 100),
        centered = true,
        cancel = true,
        labels = { cancel = 'Batal', confirm = 'Lanjut' },
    })

    if answer ~= 'confirm' then return end

    busy = true

    local result = lib.callback.await('sm_barbershop:selfservice:start', false, entry.shop, entry.index)

    if not result.success then
        busy = false

        return notify('error', result.message)
    end

    local origin = sceneOrigin(entry)

    lib.requestAnimDict(origin.dict)

    ---@type BarberSeat
    local seat = {
        shop = entry.shop,
        chair = entry.index,
        origin = origin,
        seated = pick(origin.set.seated),
        stage = 'entering',
    }

    local npc, scissors = spawnKeeper(entry.shop, origin)

    ---@type BarberService
    local current = { mode = 'self', origin = origin, keeper = npc, networked = false, scissors = scissors, result = result, stage = 'entering' }

    customer = seat
    service = current

    CreateThread(function()
        keeperWalk(current)
    end)

    lockPed(cache.ped)
    approach(cache.ped, origin, 'player_enterchair')
    CreateThread(seatLoop)

    while service == current and not current.ready do
        Wait(0)
    end

    if service ~= current then
        busy = false

        return
    end

    Citizen.CreateThreadNow(function()
        current.arrived = keeperEnter(current, 'keeper_enterchair')
    end)

    sitScene(seat)

    busy = false

    if service ~= current then return end

    seat.stage = 'self'

    while service == current and current.arrived == nil do
        Wait(100)
    end

    if service ~= current then return end

    current.stage = 'edit'

    openSelfMenu(current, seat, result)
end

---@param current BarberService
---@param deadline integer
local function cuttingLoop(current, deadline)
    local origin = current.origin

    current.entered = true

    if current.scissors and DoesEntityExist(current.scissors) then
        ResetEntityAlpha(current.scissors)
    end

    while service == current and GetGameTimer() < deadline do
        local clip = pick(origin.set.cutting)
        local finish = math.min(deadline, GetGameTimer() + math.max(MIN_CUT_MS, clipDuration(origin, clip)))

        playKeeper(current, clip, KEEPER_STAGE.cut)

        while service == current and GetGameTimer() < finish do
            Wait(100)
        end
    end

    if service == current then
        playKeeper(current, 'keeper_base', KEEPER_STAGE.settle)
    end
end

---@param duration number
local function cuttingProgress(duration)
    lib.progressCircle({
        duration = duration,
        label = 'Sedang mencukur',
        position = 'bottom',
        canCancel = false,
        disable = { move = true, combat = true, car = true },
    })
end

local function idle()
    return not (customer or service or busy or exiting)
end

---@param entry BarberChairEntry
local function pickupChair(entry)
    if not idle() then return end

    busy = true

    local result = lib.callback.await('sm_barbershop:portable:pickup', false, entry.index)

    busy = false

    if result.success then
        notify('success', 'Kursi cukur diangkat.')
    else
        notify('error', result.message)
    end
end

exports.ox_target:addModel(config.chairModels, {
    {
        name = 'sm_barbershop_sit',
        label = 'Duduk untuk dilayani barber',
        icon = 'fas fa-chair',
        distance = 2.0,
        canInteract = function(entity)
            if not idle() then return false end

            local entry = nearestChair(GetEntityCoords(entity))

            if not entry then return false end

            local state = Sync.shop(entry.shop)

            return state ~= nil and state.operational == true and chairFree(entry)
        end,
        onSelect = function(data)
            local entry = nearestChair(GetEntityCoords(data.entity))

            if entry then sitDown(entry) end
        end,
    },
    {
        name = 'sm_barbershop_self',
        label = 'Self service',
        icon = 'fas fa-scissors',
        distance = 2.0,
        canInteract = function(entity)
            if not idle() then return false end

            local entry = nearestChair(GetEntityCoords(entity))

            if not entry or entry.portable then return false end

            local state = Sync.shop(entry.shop)

            return state ~= nil and state.selfService == true and chairFree(entry)
        end,
        onSelect = function(data)
            local entry = nearestChair(GetEntityCoords(data.entity))

            if entry then startSelfService(entry) end
        end,
    },
    {
        name = 'sm_barbershop_serve',
        label = 'Layani pelanggan',
        icon = 'fas fa-scissors',
        distance = 2.0,
        canInteract = function(entity)
            if not idle() then return false end

            local entry = nearestChair(GetEntityCoords(entity))

            return entry ~= nil and LocalPlayer.state.barberDuty == entry.shop and Sync.chair(entry.shop, entry.index) == 'waiting'
        end,
        onSelect = function(data)
            local entry = nearestChair(GetEntityCoords(data.entity))

            if entry then startService(entry) end
        end,
    },
    {
        name = 'sm_barbershop_pickup',
        label = 'Angkat kursi cukur',
        icon = 'fas fa-hand-holding',
        distance = 2.0,
        canInteract = function(entity)
            if not idle() then return false end

            local entry = nearestChair(GetEntityCoords(entity))

            if not entry or not entry.portable or Sync.chair(entry.shop, entry.index) then return false end

            local shops = LocalPlayer.state.barberShops

            return entry.ownerId == cache.serverId or (type(shops) == 'table' and shops[entry.shop] ~= nil)
        end,
        onSelect = function(data)
            local entry = nearestChair(GetEntityCoords(data.entity))

            if entry then pickupChair(entry) end
        end,
    },
})

Nui.callback('barber:invoice:pay', function(payload)
    if not customer then return { success = false } end

    local result = lib.callback.await('sm_barbershop:invoice:pay', false, payload.id, payload.method)

    if result.success then
        Nui.close('invoice', 'barber:invoice:close')

        if customer then customer.snapshot = nil end
    end

    return result
end)

Nui.callback('barber:invoice:decline', function(payload)
    if customer then
        lib.callback.await('sm_barbershop:invoice:decline', false, payload.id)
        Nui.close('invoice', 'barber:invoice:close')
    end

    return true
end)

lib.callback.register('sm_barbershop:customer:prepare', function(baseline)
    local seat = customer

    if not seat or seat.stage == 'entering' then return end

    if type(baseline) == 'table' then
        appearance:applyBarberValues(baseline)
    end

    local snapshot = appearance:getBarberSnapshot()

    seat.snapshot = snapshot.appearance

    return snapshot
end)

RegisterNetEvent('sm_barbershop:customer:serviceStarted', function(barberName, shopLabel, prices)
    if source == '' or not customer then return end
    ---@cast barberName string
    ---@cast shopLabel string
    ---@cast prices table<string, integer>

    customer.stage = 'service'

    Nui.close('invoice', 'barber:invoice:close')
    lib.hideTextUI()

    appearance:openBarberMenu({
        action = 'view',
        title = shopLabel,
        subtitle = barberName,
        prices = prices,
        bundles = BUNDLES,
        onCancel = function()
            CreateThread(leaveChair)
        end,
    })
end)

RegisterNetEvent('sm_barbershop:service:resume', function(snapshot)
    local current = service
    local base = current and current.result
    local ped = current and current.customerPed

    if source == '' or not current or current.mode ~= 'barber' or not base or not ped or type(snapshot) ~= 'table' then return end

    current.stage = 'service'

    local result = lib.table.deepclone(base)

    result.snapshot = snapshot
    openServiceMenu(current, result, ped)
end)

RegisterNetEvent('sm_barbershop:selfservice:resume', function(values)
    local current = service
    local seat = customer
    local base = current and current.result

    if source == '' or not current or current.mode ~= 'self' or not base or not seat or type(values) ~= 'table' then return end

    seat.stage = 'self'
    current.stage = 'edit'

    local result = lib.table.deepclone(base)

    result.appearance = values
    openSelfMenu(current, seat, result)
end)

RegisterNetEvent('sm_barbershop:customer:applyPreview', function(values)
    if source == '' or not customer or customer.stage ~= 'service' then return end

    appearance:applyBarberValues(values)
end)

RegisterNetEvent('sm_barbershop:customer:hat', function(hidden)
    if source == '' or not customer or customer.stage ~= 'service' then return end

    appearance:setBarberHat(hidden == true)
end)

RegisterNetEvent('sm_barbershop:customer:revert', function()
    if source == '' or not customer then return end

    appearance:closeBarberMenu()
    revertCustomer(customer)

    customer.stage = 'waiting'
    customer.snapshot = nil

    Nui.close('invoice', 'barber:invoice:close')
    lib.hideTextUI()
    lib.showTextUI(WAIT_TEXT, { position = 'right-center' })
end)

RegisterNetEvent('sm_barbershop:customer:invoice', function(data)
    if source == '' or not customer then return end

    customer.stage = 'invoice'

    lib.hideTextUI()
    appearance:closeBarberMenu()
    Nui.open('invoice', 'barber:invoice:open', data)
end)

RegisterNetEvent('sm_barbershop:session:cutting', function(duration)
    if source == '' then return end

    if service then
        local current = service
        local deadline = GetGameTimer() + duration

        current.stage = 'cutting'
        CreateThread(function()
            cuttingLoop(current, deadline)
        end)
    end

    if customer then
        customer.stage = 'cutting'
    end

    if service or customer then
        cuttingProgress(duration)
    end
end)

RegisterNetEvent('sm_barbershop:session:ended', function(reason)
    if source == '' then return end

    if service and service.mode == 'self' then
        endSelfService(reason)
    elseif customer then
        customerCleanup(reason)
    elseif service then
        endBarberService()
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    local current = service

    service = nil
    customer = nil

    pcall(function() appearance:closeBarberMenu() end)

    if current then
        deleteEntity(current.scissors)

        if not current.networked then
            deleteEntity(current.keeper)
        end
    end

    lib.hideTextUI()
    unlockPed(cache.ped)
end)
