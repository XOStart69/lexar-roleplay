local config = localmodule 'config'
local util = localmodule 'modules.util'
local effect = localmodule 'modules.effect'
local wire = localmodule 'modules.wire'
local hasFrame = interface.init(false)

local Wait = Wait
local GetGameTimer = GetGameTimer
local DisablePlayerFiring = DisablePlayerFiring
local DisableControlAction = DisableControlAction
local IsDisabledControlJustPressed = IsDisabledControlJustPressed
local IsPedRagdoll = IsPedRagdoll
local IsPedDeadOrDying = IsPedDeadOrDying
local IsPedInAnyVehicle = IsPedInAnyVehicle
local IsPauseMenuActive = IsPauseMenuActive
local IsNuiFocused = IsNuiFocused
local GetEntityType = GetEntityType
local IsPedAPlayer = IsPedAPlayer
local GetPedBoneCoords = GetPedBoneCoords
local GetFinalRenderedCamCoord = GetFinalRenderedCamCoord
local GetFinalRenderedCamRot = GetFinalRenderedCamRot
local GetEntityCoords = GetEntityCoords
local NetworkGetEntityIsNetworked = NetworkGetEntityIsNetworked
local NetworkGetNetworkIdFromEntity = NetworkGetNetworkIdFromEntity
local StartExpensiveSynchronousShapeTestLosProbe = StartExpensiveSynchronousShapeTestLosProbe
local GetShapeTestResult = GetShapeTestResult
local msin = math.sin
local mcos = math.cos
local mrad = math.rad
local mmax = math.max
local mrandom = math.random
local type = type

local WEAPON_HASH = joaat(config.weapon)
local CARTRIDGE_ITEM = config.cartridge.item
local SHOTS_PER_CARTRIDGE = config.cartridge.shotsPerCartridge
local MAX_CARRY = config.cartridge.maxCarry
local FIRE_COOLDOWN = config.fireCooldown
local RELOAD_TIME = config.reloadTime
local RANGE = config.range
local PROBES_PER_SHOT = config.probesPerShot
local SPREAD = config.probeSpread
local JITTER = config.probeJitter
local BONES = config.probeBones
local BONE_COUNT = #BONES
local NPC_ENABLED = config.npc.enabled
local ARC_TIME = config.player.shakeTime + config.player.twitchTime
local RELOAD_ANIMS = config.reloadAnims
local SOUND_VOLUME = config.sound.volume
local SOUND_DISTANCE = config.sound.distance
local FIRE_SOUND_URL = ('nui://%s/interface/sm_taser/web/build/sounds/fire.mp3'):format(cache.resource)
local RAYCAST_FLAGS = 31
local UP = vec3(0.0, 0.0, 1.0)

local holding = false
local holdToken = 0
local shots = nil
local reloading = false
local lastShot = 0
local lastEmptyNotice = 0
local frameShown = false
local frameReady = false
local pending = {}

---@param description string
---@param kind? string
local function notify(description, kind)
    lib.notify({ title = 'Taser', description = description, type = kind or 'error', icon = 'bolt' })
end

---@return integer
local function cartridgeCount()
    return ox_inventory:GetItemCount(CARTRIDGE_ITEM) or 0
end

---@param message table
local function send(message)
    if not frameShown then return end

    if not frameReady then
        pending[#pending + 1] = message
        return
    end

    interface.send(message)
end

local function pushHud()
    send({
        action = 'hud',
        show = holding,
        known = shots ~= nil,
        shots = shots or 0,
        capacity = SHOTS_PER_CARTRIDGE,
        cartridges = cartridgeCount(),
        maxCarry = MAX_CARRY,
        reloading = reloading and RELOAD_TIME or 0,
        cooldown = mmax(0, lastShot + FIRE_COOLDOWN - GetGameTimer()),
        cooldownTotal = FIRE_COOLDOWN,
        reloadKey = config.reloadKey,
    })
end

---@param name string
---@param duration? number
local function sound(name, duration)
    send({ action = 'sound', name = name, volume = SOUND_VOLUME, duration = duration })
end

local function syncFrame()
    if not hasFrame then return end

    local want = holding or effect.selfTased

    if want and not frameShown then
        frameShown = true
        frameReady = false
        interface.show()
    elseif not want and frameShown then
        frameShown = false
        frameReady = false
        pending = {}
        interface.hide()
    end
end

interface.callback('ready', function(_, cb)
    cb({})

    frameReady = true
    pushHud()

    local queued = pending
    pending = {}

    for i = 1, #queued do
        interface.send(queued[i])
    end
end)

---@param a vector3
---@param b vector3
---@return vector3
local function cross(a, b)
    return vec3(a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x)
end

---@param v vector3
---@param axis vector3
---@param degrees number
---@return vector3
local function rotate(v, axis, degrees)
    local rad = mrad(degrees)
    local c = mcos(rad)
    local dot = axis.x * v.x + axis.y * v.y + axis.z * v.z

    return v * c + cross(axis, v) * msin(rad) + axis * dot * (1.0 - c)
end

---@param from vector3
---@param to vector3
---@param ignore number
---@param flags integer
---@return boolean hit
---@return vector3 coords
---@return number entity
local function raycast(from, to, ignore, flags)
    local handle = StartExpensiveSynchronousShapeTestLosProbe(from.x, from.y, from.z, to.x, to.y, to.z, flags, ignore, 7)
    local _, hit, coords, _, entity = GetShapeTestResult(handle)

    return hit == 1 or hit == true, coords, entity
end

---@param ped number
---@return vector3
local function aimPoint(ped)
    local cam = GetFinalRenderedCamCoord()
    local rot = GetFinalRenderedCamRot(2)
    local rx, rz = mrad(rot.x), mrad(rot.z)
    local forward = vec3(-msin(rz) * mcos(rx), mcos(rz) * mcos(rx), msin(rx))
    local toPed = GetEntityCoords(ped) - cam
    local skip = mmax(toPed.x * forward.x + toPed.y * forward.y + toPed.z * forward.z, 0.0)
    local start = cam + forward * (skip + 0.5)
    local finish = cam + forward * (skip + RANGE)
    local hit, coords = raycast(start, finish, ped, RAYCAST_FLAGS)

    return hit and coords or finish
end

---@param ped number
---@param point vector3
---@return integer
local function closestBone(ped, point)
    local best, bestDistance = BONES[1], nil

    for i = 1, BONE_COUNT do
        local bone = BONES[i]
        local distance = #(GetPedBoneCoords(ped, bone, 0.0, 0.0, 0.0) - point)

        if not bestDistance or distance < bestDistance then
            best = bone
            bestDistance = distance
        end
    end

    return best
end

---@param entity number
---@return boolean
local function isTaseable(entity)
    if entity == 0 or GetEntityType(entity) ~= 1 then return false end
    if not NetworkGetEntityIsNetworked(entity) or IsPedInAnyVehicle(entity, false) then return false end

    return NPC_ENABLED or IsPedAPlayer(entity)
end

---@param ped number
---@param origin vector3
---@param direction vector3
---@return table hit
local function traceProbe(ped, origin, direction)
    local finish = origin + direction * RANGE
    local hit, coords, entity = raycast(origin + direction * 0.05, finish, ped, RAYCAST_FLAGS)

    if hit and isTaseable(entity) then
        return {
            target = NetworkGetNetworkIdFromEntity(entity),
            bone = closestBone(entity, coords),
            point = coords,
        }
    end

    if not hit then
        local ground, groundCoords = raycast(finish, finish - vec3(0.0, 0.0, 50.0), ped, 1)
        coords = ground and groundCoords or finish
    end

    return { point = coords }
end

---@param aim vector3
---@return vector3[]
local function probeDirections(aim)
    local right = cross(aim, UP)
    right = #right < 1.0e-4 and vec3(1.0, 0.0, 0.0) or norm(right)

    local list = {}

    for i = 1, PROBES_PER_SHOT do
        local direction = aim

        if i > 1 then
            direction = rotate(direction, right, -SPREAD * (i - 1) / (PROBES_PER_SHOT - 1))
        end

        if JITTER > 0 then
            direction = rotate(direction, right, (mrandom() * 2.0 - 1.0) * JITTER)
            direction = rotate(direction, UP, (mrandom() * 2.0 - 1.0) * JITTER)
        end

        list[i] = norm(direction)
    end

    return list
end

---@param ped number
---@return boolean
local function canFire(ped)
    if reloading or effect.selfTased then return false end
    if IsPedRagdoll(ped) or IsPedDeadOrDying(ped, true) then return false end
    if IsPedInAnyVehicle(ped, false) then return false end

    return not IsPauseMenuActive() and not IsNuiFocused()
end

local function fire()
    local ped = cache.ped
    if not canFire(ped) or shots == nil then return end

    local now = GetGameTimer()
    if now - lastShot < FIRE_COOLDOWN then return end

    if shots < 1 then
        sound('dry')

        if now - lastEmptyNotice > 2000 then
            lastEmptyNotice = now
            notify(('Cartridge empty. Press %s to load a new cartridge.'):format(config.reloadKey))
        end

        return
    end

    lastShot = now
    shots -= 1

    local muzzle = util.muzzle(ped)
    local aim = norm(aimPoint(ped) - muzzle)
    local directions = probeDirections(aim)
    local hits = {}
    local struck = false

    for i = 1, #directions do
        local hit = traceProbe(ped, muzzle, directions[i])
        hits[i] = hit
        struck = struck or hit.target ~= nil
    end

    TriggerTokenEvent('sm_taser:fire', hits)
    util.muzzleFlash(muzzle)
    sound('fire')

    if struck then
        sound('arc', ARC_TIME)
    end

    pushHud()
end

---@param token integer
local function holdLoop(token)
    local playerId = cache.playerId

    while holding and token == holdToken do
        DisablePlayerFiring(playerId, true)
        DisableControlAction(0, 24, true)
        DisableControlAction(0, 257, true)
        DisableControlAction(0, 45, true)
        DisableControlAction(0, 140, true)
        DisableControlAction(0, 141, true)
        DisableControlAction(0, 142, true)

        if IsDisabledControlJustPressed(0, 24) or IsDisabledControlJustPressed(0, 257) then
            fire()
        end

        Wait(0)
    end
end

local function reload()
    if not holding or reloading or effect.selfTased then return end

    if shots and shots > 0 then
        return notify(('Cartridge still has %d shot(s) left.'):format(shots))
    end

    if cartridgeCount() < 1 then
        return notify('You have no Taser Cartridge.')
    end

    reloading = true

    local started, reason = lib.callback.await('sm_taser:reloadStart', false)

    if not started then
        reloading = false
        return reason and notify(reason)
    end

    pushHud()
    sound('reload')

    local ped = cache.ped
    local anim = util.playAnim(ped, RELOAD_ANIMS, 49)
    local finishAt = GetGameTimer() + RELOAD_TIME
    local completed = true

    while GetGameTimer() < finishAt do
        if not holding or effect.selfTased or IsPedRagdoll(ped) then
            completed = false
            break
        end

        DisableControlAction(0, 21, true)
        Wait(0)
    end

    util.stopAnim(ped, anim)

    if completed then
        local ok, result = lib.callback.await('sm_taser:reloadFinish', false)

        if ok then
            shots = result
        elseif type(result) == 'string' then
            notify(result)
        end
    end

    reloading = false
    pushHud()
end

local function fetchShots()
    for _ = 1, 3 do
        Wait(400)

        if not holding then return end

        local value = lib.callback.await('sm_taser:getShots', false)

        if value then
            shots = value
            pushHud()
            return
        end
    end
end

---@param state boolean
local function setHolding(state)
    if holding == state then return end

    holding = state

    if state then
        shots = nil
        holdToken += 1

        local token = holdToken

        CreateThread(function()
            holdLoop(token)
        end)
        CreateThread(fetchShots)
    end

    syncFrame()
    pushHud()
end

effect.onSelf = function(tased, info)
    syncFrame()

    if not tased or not info then return end

    sound('arc', mmax(0, info.twitchEnd - GetGameTimer()))
end

lib.onCache('weapon', function(weapon)
    setHolding(weapon == WEAPON_HASH)
end)

RegisterNetEvent('sm_taser:client:shots', function(value)
    if type(value) ~= 'number' then return end

    shots = value
    pushHud()
end)

RegisterNetEvent('sm_taser:client:shot', function(shooter, list)
    if type(list) ~= 'table' then return end

    wire.add(shooter, list)

    if shooter == cache.serverId then return end

    local player = GetPlayerFromServerId(shooter)
    if player == -1 then return end

    local shooterPed = GetPlayerPed(player)
    local muzzle = util.muzzle(shooterPed)

    util.muzzleFlash(muzzle)

    if GetResourceState('xsound') ~= 'started' then return end
    if #(GetEntityCoords(cache.ped) - muzzle) > SOUND_DISTANCE then return end

    local id = ('sm_taser_%d'):format(shooter)

    exports.xsound:PlayUrlPos(id, FIRE_SOUND_URL, SOUND_VOLUME, muzzle, false)
    exports.xsound:Distance(id, SOUND_DISTANCE)
end)

AddEventHandler('ox_inventory:itemCount', function(name)
    if holding and name == CARTRIDGE_ITEM then
        pushHud()
    end
end)

RegisterCommand('+sm_taser_reload', function()
    if holding then
        CreateThread(reload)
    end
end, false)

RegisterCommand('-sm_taser_reload', function() end, false)

RegisterKeyMapping('+sm_taser_reload', 'Taser: load cartridge', 'keyboard', config.reloadKey)

CreateThread(function()
    util.findAnim(RELOAD_ANIMS)
    pcall(lib.requestNamedPtfxAsset, config.muzzleFx.asset, 5000)

    if cache.weapon == WEAPON_HASH then
        setHolding(true)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    holding = false
    wire.clear()
end)
