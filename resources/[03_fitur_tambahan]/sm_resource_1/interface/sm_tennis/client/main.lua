local config = localmodule 'config.shared'
local geometry = localmodule 'modules.geometry'
local physics = localmodule 'modules.physics'
local anims = localmodule 'modules.anims'
local ui = localmodule 'modules.ui'
local tool = localmodule 'modules.tool'

local Wait = Wait
local GetGameTimer = GetGameTimer
local GetFrameTime = GetFrameTime
local GetEntityCoords = GetEntityCoords
local SetEntityHeading = SetEntityHeading
local SetEntityCoordsNoOffset = SetEntityCoordsNoOffset
local DoesEntityExist = DoesEntityExist
local DeleteEntity = DeleteEntity
local DrawMarker = DrawMarker
local TaskPlayAnim = TaskPlayAnim
local StopAnimTask = StopAnimTask
local IsControlJustPressed = IsControlJustPressed
local IsControlPressed = IsControlPressed
local IsDisabledControlPressed = IsDisabledControlPressed
local IsDisabledControlJustPressed = IsDisabledControlJustPressed
local DisableAllControlActions = DisableAllControlActions
local EnableControlAction = EnableControlAction
local DisablePlayerFiring = DisablePlayerFiring
local IsEntityInAngledArea = IsEntityInAngledArea
local IsPointInAngledArea = IsPointInAngledArea
local GetOffsetFromEntityInWorldCoords = GetOffsetFromEntityInWorldCoords
local GetPlayerFromServerId = GetPlayerFromServerId
local GetPlayerPed = GetPlayerPed
local GetPedBoneIndex = GetPedBoneIndex
local GetPedBoneCoords = GetPedBoneCoords
local AttachEntityToEntity = AttachEntityToEntity
local IsEntityAttachedToEntity = IsEntityAttachedToEntity
local DetachEntity = DetachEntity
local CreateObject = CreateObject
local PlaySoundFromEntity = PlaySoundFromEntity
local PlaySoundFrontend = PlaySoundFrontend
local DoesParticleFxLoopedExist = DoesParticleFxLoopedExist
local SetParticleFxLoopedOffsets = SetParticleFxLoopedOffsets
local StopParticleFxLooped = StopParticleFxLooped
local UseParticleFxAssetNextCall = UseParticleFxAssetNextCall
local StartParticleFxLoopedAtCoord = StartParticleFxLoopedAtCoord
local SetParticleFxLoopedColour = SetParticleFxLoopedColour
local GetInvokingResource = GetInvokingResource
local TriggerServerEvent = TriggerServerEvent
local IsEntityDead = IsEntityDead
local mathFloor = math.floor
local mathMax = math.max
local mathMin = math.min
local mathSqrt = math.sqrt
local pairs = pairs

local controls = config.controls
local text = config.text
local joinDistance = config.joinDistance
local markerDistance = config.markerDistance
local ballRadius = config.ballRadius
local highlightSize = config.ballHighlight.size
local highlightR, highlightG, highlightB, highlightA = table.unpack(config.ballHighlight.color)
local shadowSize = config.ballShadow.size
local shadowAlpha = config.ballShadow.alpha
local toIdle = anims.toIdle
local animTree = anims.tree
local hitDelay = anims.hitDelay

local ANIM_DICT = anims.dict
local BALL_MODEL = -1720813907
local RACKET_MODEL = `prop_tennis_rack_01b`
local PTFX_ASSET = 'scr_minigametennis'
local RACKET_BONE = 28422
local BALL_HAND_BONE = 60309
local RADIUS_OFFSET = vec3(0.0, 0.0, ballRadius)
local FALL_OFFSET = vec3(0.0, 0.0, 5.0)
local HAND_FALLBACK = vec3(0.0, 0.0, 1.4)
local SIDES = { 'a', 'b' }
local MAX_REPORTS = 4
local GROUND_TOLERANCE = 0.35
local SERVE_MIN_SPEED = 13.0
local SERVE_SPEED_RANGE = 7.0
local RETURN_LEAD = config.returnLead
local RETURN_MIN_PAST = 2.0
local RETURN_FALLBACK = 8.0
local returnSpeed = config.returnSpeed

local suffixed = function(suffix)
    return setmetatable({}, {
        __index = function(self, key)
            local value = key .. suffix
            self[key] = value
            return value
        end,
    })
end
local loopName = suffixed('_loop')
local introName = suffixed('_intro')

local courtMap, courtList = {}, {}
local activeCourts, activeCount = {}, 0
local rackets, wantedRackets = {}, {}
local blips = {}

local playing
local blockUntil = 0
local actionCooldown = 0
local currentAnim, lastSideways, shouldSqueak
local promptCourt
local ptfxState = 0

for id, data in pairs(config.courts) do
    local court = {
        id = id,
        z = data.z,
        center = data.center,
        heading = data.heading,
        geo = geometry.build(data.center, data.heading, data.width, data.length, data.netOffset),
        players = {},
        ball = { spin = 'normal', collidedLast = false, reports = 0, version = 0, moving = false },
        active = false,
    }
    courtMap[id] = court
    courtList[#courtList + 1] = court
end

local function disableControls()
    DisablePlayerFiring(cache.playerId, true)
    DisableAllControlActions(0)
    EnableControlAction(0, 249, true)
    EnableControlAction(0, 245, true)
    EnableControlAction(0, 0, true)
    EnableControlAction(0, 1, true)
    EnableControlAction(0, 2, true)
end

---@param entity number?
local function deleteEntity(entity)
    if entity and DoesEntityExist(entity) then
        DeleteEntity(entity)
    end
end

---@param ball table
local function stopTrail(ball)
    if ball.ptfx then
        if DoesParticleFxLoopedExist(ball.ptfx) then
            StopParticleFxLooped(ball.ptfx, true)
        end
        ball.ptfx = nil
    end
end

---@param ball table
local function updateTrail(ball)
    if ptfxState ~= 2 then
        if ptfxState == 0 then
            ptfxState = 1
            CreateThread(function()
                ptfxState = lib.requestNamedPtfxAsset(PTFX_ASSET, 5000) and 2 or 0
            end)
        end
        return
    end

    if #ball.vel <= 0.1 then
        return stopTrail(ball)
    end

    local pos = ball.pos

    if ball.ptfx and DoesParticleFxLoopedExist(ball.ptfx) then
        SetParticleFxLoopedOffsets(ball.ptfx, pos.x, pos.y, pos.z, 0.0, 0.0, 0.0)
        return
    end

    UseParticleFxAssetNextCall(PTFX_ASSET)
    ball.ptfx = StartParticleFxLoopedAtCoord('scr_tennis_ball_trail', pos.x, pos.y, pos.z, 0.0, 0.0, 0.0, 1.0, false, false, false, true)
    SetParticleFxLoopedColour(ball.ptfx, 1.0, 0.9176, 0.0314, false)
end

---@param court table
---@param coords vector3
---@return number?
local function ensureBallEntity(court, coords)
    local ball = court.ball
    local entity = ball.entity

    if entity and DoesEntityExist(entity) then
        DetachEntity(entity, false, false)
        return entity
    end

    if not lib.requestModel(BALL_MODEL, 3000) then return nil end

    entity = CreateObject(BALL_MODEL, coords.x, coords.y, coords.z, false, false, false)
    SetEntityHasGravity(entity, false)
    SetEntityCollision(entity, false, false)
    SetEntityLodDist(entity, 500)
    SetModelAsNoLongerNeeded(BALL_MODEL)
    ball.entity = entity

    return entity
end

---@param court table
local function clearBall(court)
    local ball = court.ball
    stopTrail(ball)
    deleteEntity(ball.entity)
    ball.entity = nil
    ball.pos = nil
    ball.vel = nil
    ball.holder = nil
    ball.predicted = nil
    ball.moving = false
    ball.version += 1
end

---@param court table
local function refreshPrediction(court)
    local ball = court.ball
    ball.version += 1
    local version = ball.version
    local spin, pos, vel = ball.spin, ball.pos, ball.vel

    CreateThread(function()
        local predicted = physics.firstGroundHit(spin, pos, vel, court.z)
        if ball.version == version then
            ball.predicted = predicted
        end
    end)
end

---@param serverId number
---@return number?
local function pedFromServerId(serverId)
    local player = GetPlayerFromServerId(serverId)
    if player == -1 then return nil end

    local ped = GetPlayerPed(player)
    return ped ~= 0 and ped or nil
end

---@param serverId number
local function removeRacket(serverId)
    deleteEntity(rackets[serverId])
    rackets[serverId] = nil
end

local reconciling = false

local function reconcileRackets()
    if reconciling then return end
    reconciling = true

    local modelReady = HasModelLoaded(RACKET_MODEL)

    if not modelReady then
        for i = 1, activeCount do
            local players = activeCourts[i].players
            if players.a or players.b then
                modelReady = lib.requestModel(RACKET_MODEL, 3000) ~= nil
                break
            end
        end
    end

    for i = 1, activeCount do
        local players = activeCourts[i].players
        local a, b = players.a, players.b
        if a then wantedRackets[a] = true end
        if b then wantedRackets[b] = true end
    end

    for serverId, entity in pairs(rackets) do
        if not wantedRackets[serverId] then
            deleteEntity(entity)
            rackets[serverId] = nil
        end
    end

    for serverId in pairs(wantedRackets) do
        wantedRackets[serverId] = nil

        local ped = pedFromServerId(serverId)
        local entity = rackets[serverId]

        if not ped then
            removeRacket(serverId)
        elseif not entity or not DoesEntityExist(entity) or not IsEntityAttachedToEntity(entity, ped) then
            removeRacket(serverId)

            if modelReady then
                local coords = GetEntityCoords(ped)
                entity = CreateObject(RACKET_MODEL, coords.x, coords.y + 1.0, coords.z, false, false, false)
                SetEntityCollision(entity, false, false)
                SetEntityLodDist(entity, 500)
                AttachEntityToEntity(entity, ped, GetPedBoneIndex(ped, RACKET_BONE), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, false, false, false, 2, true)
                rackets[serverId] = entity
            end
        end
    end

    if modelReady and not next(rackets) then
        SetModelAsNoLongerNeeded(RACKET_MODEL)
    end

    reconciling = false
end

---@param court table
local function activateCourt(court)
    if court.active then return end
    court.active = true
    activeCount += 1
    activeCourts[activeCount] = court
    TriggerServerEvent('sm_tennis:subscribe', court.id)
end

---@param court table
local function deactivateCourt(court)
    if not court.active then return end
    court.active = false

    for i = 1, activeCount do
        if activeCourts[i] == court then
            activeCourts[i] = activeCourts[activeCount]
            activeCourts[activeCount] = nil
            activeCount -= 1
            break
        end
    end

    TriggerServerEvent('sm_tennis:unsubscribe', court.id)
    clearBall(court)
    court.players.a, court.players.b = nil, nil
    reconcileRackets()
end

---@param ped number
---@param setIdle boolean?
---@param forcedIdle string?
local function stopMovementAnim(ped, setIdle, forcedIdle)
    if not currentAnim then return end

    StopAnimTask(ped, ANIM_DICT, currentAnim, 1.0)
    StopAnimTask(ped, ANIM_DICT, loopName[currentAnim], 1.0)

    if setIdle then
        local idle = forcedIdle or toIdle[lastSideways] or toIdle[currentAnim] or 'idle_fh'
        TaskPlayAnim(ped, ANIM_DICT, idle, 4.0, 4.0, -1, 1, 1.0, false, false, false)
        lastSideways = nil
    end

    shouldSqueak = false
    currentAnim = nil
end

---@param ped number
---@param anim string
---@param skipIntro boolean
---@param squeak boolean
local function playMovementAnim(ped, anim, skipIntro, squeak)
    if anim == currentAnim then return end

    stopMovementAnim(ped)
    currentAnim = anim

    if anim ~= 'strafe_bwd' and anim ~= 'run_fwd_0' then
        lastSideways = anim
    end

    shouldSqueak = squeak

    if skipIntro then
        TaskPlayAnim(ped, ANIM_DICT, anim, 4.0, 4.0, -1, 1, 1.0, false, false, false)
    else
        TaskPlayAnim(ped, ANIM_DICT, introName[anim], 4.0, 4.0, -1, 0, 1.0, false, false, false)
        TaskPlayAnim(ped, ANIM_DICT, loopName[anim], 4.0, 4.0, -1, 1, 1.0, false, false, false)
    end
end

---@param ped number
---@param point vector3
---@return boolean
local function isInFront(ped, point)
    local back = GetOffsetFromEntityInWorldCoords(ped, 0.0, -0.5, 0.0)
    local front = GetOffsetFromEntityInWorldCoords(ped, 0.0, 5.0, 0.0)
    return IsPointInAngledArea(point.x, point.y, point.z, back.x, back.y, back.z, front.x, front.y, front.z, 5.0, false, false)
end

---@param ped number
---@return vector3
local function racketCoords(ped)
    local racket = rackets[cache.serverId]
    if racket and DoesEntityExist(racket) then
        return GetOffsetFromEntityInWorldCoords(racket, 0.0, 0.0, 0.4)
    end
    return GetPedBoneCoords(ped, RACKET_BONE, 0.0, 0.0, 0.0)
end

---@param court table
---@param ped number
---@return vector3
local function ballCoords(court, ped)
    local entity = court.ball.entity
    if entity and DoesEntityExist(entity) then
        return GetEntityCoords(entity)
    end
    return GetEntityCoords(ped) + HAND_FALLBACK
end

---@param session table
---@return number
local function facing(session)
    return session.court.heading + (session.side == 'a' and 180.0 or 0.0)
end

---@param court table
---@return boolean
local function isBallInPlay(court)
    local ball = court.ball
    local vel = ball.vel
    return not ball.holder and ball.pos ~= nil and vel ~= nil and #vel >= 0.01
end

---@param session table
---@return boolean
local function canStartServing(session)
    local court = session.court
    return session.canServe and not court.ball.holder and court.players.a ~= nil and court.players.b ~= nil
end

---@param court table
---@param kind string
---@param half string?
local function report(court, kind, half)
    local ball = court.ball
    if ball.reports >= MAX_REPORTS then return end
    ball.reports += 1
    TriggerServerEvent('sm_tennis:impact', kind, half)
end

---@param court table
---@param hit vector3
local function onCollision(court, hit)
    if hit.z - court.z > GROUND_TOLERANCE then return end

    local _, _, isASide = geometry.pointData(court.geo, hit, playing.side)
    report(court, 'court', isASide and 'a' or 'b')
end

---@param court table
---@param dt number
local function stepBall(court, dt)
    local ball = court.ball
    local groundZ = court.z

    local pos, vel, hit = physics.step(dt, ball.spin, ball.pos, ball.vel, groundZ, true, not ball.collidedLast)
    ball.pos, ball.vel = pos, vel

    local isReporter = playing and playing.court == court and playing.side == ball.auth

    if isReporter then
        local drop = pos.z - groundZ
        if drop < -1.0 and drop > -1.5 then
            ball.pos = pos - FALL_OFFSET
            report(court, 'lost')
        end
    end

    updateTrail(ball)
    ball.collidedLast = false

    if hit then
        ball.spin = 'normal'
        ball.collidedLast = true

        if vel.z > 0.5 then
            refreshPrediction(court)
        else
            ball.version += 1
            ball.predicted = nil
        end

        if isReporter then
            onCollision(court, hit)
        end
    end

    local predicted = ball.predicted
    if predicted then
        DrawMarker(25, predicted.x, predicted.y, predicted.z + 0.03, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.5, 255, 255, 255, 150, false, false, 2, false, nil, nil, false)
    end

    local ballPos = ball.pos

    if ball.entity then
        SetEntityCoordsNoOffset(ball.entity, ballPos + RADIUS_OFFSET, false, false, false)
    end

    DrawMarker(28, ballPos.x, ballPos.y, ballPos.z + ballRadius, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, highlightSize, highlightSize, highlightSize, highlightR, highlightG, highlightB, highlightA, false, false, 2, false, nil, nil, false)

    if ballPos.z - groundZ > 0.1 then
        DrawMarker(25, ballPos.x, ballPos.y, groundZ + 0.02, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, shadowSize, shadowSize, shadowSize, 0, 0, 0, shadowAlpha, false, false, 2, false, nil, nil, false)
    end

    if #ball.vel == 0.0 or ball.pos.z < groundZ - 10.0 then
        ball.moving = false
        ball.predicted = nil
        stopTrail(ball)

        if isReporter then
            report(court, 'lost')
        end
    end
end

local function stopPlaying(skipServer)
    local session = playing
    if not session then return end

    playing = nil
    ClearPedTasks(cache.ped)

    if not skipServer then
        TriggerServerEvent('sm_tennis:leave')
    end

    StopAudioScene('TENNIS_SCENE')
    ReleaseNamedScriptAudioBank('SCRIPT\\Tennis')
    ReleaseNamedScriptAudioBank('SCRIPT\\TENNIS_VER2_A')

    ui.closeMeter()
    ui.releaseMeter()
    ui.hudClose()

    currentAnim, lastSideways, shouldSqueak = nil, nil, false
    blockUntil = 0
end

---@param session table
---@param origin vector3
---@param spin string
---@param speed number?
---@return vector3
local function returnVelocity(session, origin, spin, speed)
    local court = session.court
    local geo = court.geo
    local normal = session.side == 'a' and -geo.toA or geo.toA
    local normalXY = normal.xy
    local netXY = geo.netMid.xy

    local opponentId = court.players[session.side == 'a' and 'b' or 'a']
    local opponentPed = opponentId and pedFromServerId(opponentId)
    local target

    if opponentPed then
        target = GetEntityCoords(opponentPed).xy - normalXY * RETURN_LEAD
    else
        target = netXY + normalXY * RETURN_FALLBACK
    end

    local rel = target - netXY
    local past = rel.x * normalXY.x + rel.y * normalXY.y
    if past < RETURN_MIN_PAST then
        target = target + normalXY * (RETURN_MIN_PAST - past)
    end

    local dx, dy = target.x - origin.x, target.y - origin.y
    local total = mathMax(1.0, mathSqrt(dx * dx + dy * dy))
    local dirX, dirY = dx / total, dy / total

    local cosine = mathMax(0.3, dirX * normalXY.x + dirY * normalXY.y)
    local toNetPerp = mathMax(0.5, (netXY.x - origin.x) * normalXY.x + (netXY.y - origin.y) * normalXY.y)
    local horizontal, vertical = physics.solveShot(origin.z - court.z, toNetPerp / cosine, total, speed or returnSpeed[spin] or returnSpeed.normal, spin)

    return vec3(dirX * horizontal, dirY * horizontal, vertical)
end

---@param ped number
---@param name string
---@param hand string
---@param dist string
---@param spin string
---@param session table
local function playHitAnim(ped, name, hand, dist, spin, session)
    local duration = mathFloor(GetAnimDuration(ANIM_DICT, name) * 1000) - 200

    currentAnim = nil
    TaskPlayAnim(ped, ANIM_DICT, name, 4.0, 4.0, duration, 1, 1.0, false, false, false)
    blockUntil = GetGameTimer() + duration

    SetTimeout(mathMax(0, duration), function()
        if playing ~= session then return end
        currentAnim = name
        lastSideways = hand == 'backhand' and 'run_fwd_0' or 'strafe_bwd'
    end)

    SetTimeout(mathMax(1, hitDelay[dist] - 150), function()
        if playing ~= session then return end

        local ball = session.court.ball
        local ballPos = ball.pos
        if not ballPos or ball.holder then return end

        local currentPed = cache.ped
        local origin = racketCoords(currentPed)

        if #(origin.xy - ballPos.xy) < 3.5 and isInFront(currentPed, ballPos) then
            TriggerServerEvent('sm_tennis:ball', spin, ballPos, returnVelocity(session, ballPos, spin), 'HIT')
        end
    end)
end

---@param ped number
---@param session table
---@param spin string
local function attemptHit(ped, session, spin)
    local court = session.court
    local ball = court.ball
    local hand, dist, predictedPos = physics.predictHit(ped, ball.spin, ball.pos, ball.vel, court.z)
    if not hand then return end

    Wait(0)
    if playing ~= session then return end

    ped = cache.ped
    local band = anims.groundBand((predictedPos.z + ballRadius) - GetEntityCoords(ped).z)
    playHitAnim(ped, animTree[hand][dist][spin][band], hand, dist, spin, session)
end

---@param session table
---@param ped number
---@param strength number
---@return vector3 origin
---@return vector3 velocity
local function serveVelocity(session, ped, strength)
    local origin = ballCoords(session.court, ped)
    return origin, returnVelocity(session, origin, 'normal', SERVE_MIN_SPEED + strength * SERVE_SPEED_RANGE)
end

---@param ped number
---@param session table
---@param heading number
---@param meter table?
local function serveSwing(ped, session, heading, meter)
    local startedAt = GetGameTimer()
    local submitted = false

    while playing == session do
        Wait(0)
        disableControls()
        SetEntityHeading(ped, heading)

        local elapsed = GetGameTimer() - startedAt

        if elapsed <= 3550 then
            if meter then
                if elapsed > 1000 then
                    ui.tickMeter(meter)
                end

                if not meter.active and not meter.strength and elapsed > 2000 then
                    meter.active = true
                end

                if meter.active and IsDisabledControlJustPressed(0, controls.shotRegular) then
                    meter.active = false
                    meter.strength = mathMax(0.0, mathMin(1.0, 1.0 - meter.progress))
                end
            end
        elseif not submitted then
            submitted = true
            local origin, velocity = serveVelocity(session, ped, (meter and meter.strength) or 0.25)
            TriggerServerEvent('sm_tennis:ball', 'normal', origin, velocity, 'SERVE')
        elseif elapsed > 5000 then
            break
        end
    end
end

---@param ped number
---@param session table
local function handleServe(ped, session)
    local court = session.court
    local geo = court.geo
    local side = session.side
    local serveSide = session.state and session.state.serveSide or 'right'
    local bounds = geo.serveBounds[side][serveSide]
    local leftBound, rightBound = bounds.left, bounds.right
    local heading = facing(session)

    session.inServe = true
    ui.hudPrompt(false)
    ui.hudUpdate(session.state, true)
    TaskPlayAnim(ped, ANIM_DICT, 'serve_idle_01', 4.0, 4.0, -1, 1, 1.0, false, false, false)

    local meter = ui.openMeter()

    while playing == session do
        Wait(0)
        disableControls()
        SetEntityHeading(ped, heading)

        if GetGameTimer() > blockUntil then
            if IsDisabledControlJustPressed(0, controls.shotServe) then
                playMovementAnim(ped, 'serve', true, true)
                serveSwing(ped, session, heading, meter)
                break
            elseif IsDisabledControlPressed(0, controls.aimLeft) and not IsEntityInAngledArea(ped, leftBound[1].x, leftBound[1].y, leftBound[1].z, leftBound[2].x, leftBound[2].y, leftBound[2].z, 1.0, false, false, 0) then
                playMovementAnim(ped, 'serve_walk_l', true, true)
            elseif IsDisabledControlPressed(0, controls.aimRight) and not IsEntityInAngledArea(ped, rightBound[1].x, rightBound[1].y, rightBound[1].z, rightBound[2].x, rightBound[2].y, rightBound[2].z, 1.0, false, false, 0) then
                playMovementAnim(ped, 'serve_walk_r', true, true)
            elseif IsDisabledControlJustPressed(0, controls.dropBall) then
                TriggerServerEvent('sm_tennis:ball', 'normal', ballCoords(court, ped), GetEntityForwardVector(ped), 'DROP')
                ClearPedTasks(ped)
                currentAnim = 'idle_fh'
                stopMovementAnim(ped, true, currentAnim)
                break
            else
                stopMovementAnim(ped, true, 'serve_idle_01')
            end
        end
    end

    ui.closeMeter()
    session.inServe = false

    if playing == session then
        ui.hudUpdate(session.state, false)
    end
end

---@param session table
---@param ped number
---@param coords vector3
local function handleServePoint(session, ped, coords)
    local state = session.state
    local point = session.court.geo.servePoints[session.side][state and state.serveSide or 'right']

    DrawMarker(0, point.x, point.y, point.z + 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.5, 255, 255, 255, 180, true, false, 2, false, nil, nil, false)

    if #(coords.xy - point.xy) >= joinDistance then
        return ui.hudPrompt(false)
    end

    ui.hudPrompt(true)

    if IsDisabledControlJustPressed(0, controls.serve) then
        local now = GetGameTimer()
        if now > actionCooldown then
            actionCooldown = now + 1000
            TriggerServerEvent('sm_tennis:requestBall')
        end
    end
end

---@param session table
local function runWorker(session)
    local ped = cache.ped
    local court = session.court
    local geo = court.geo
    local side = session.side
    local frame = 0

    StartAudioScene('TENNIS_SCENE')
    RequestScriptAudioBank('SCRIPT\\Tennis', false, -1)
    RequestScriptAudioBank('SCRIPT\\TENNIS_VER2_A', false, -1)
    lib.requestAnimDict(ANIM_DICT, 3000)
    ui.loadMeter()
    reconcileRackets()

    TaskPlayAnim(ped, ANIM_DICT, 'idle_fh', 4.0, 4.0, -1, 1, 1.0, false, false, false)

    while playing == session do
        Wait(0)
        ped = cache.ped
        disableControls()
        SetEntityHeading(ped, facing(session))

        if session.serving then
            session.serving = false
            handleServe(ped, session)
            if playing ~= session then break end
        end

        if GetGameTimer() > blockUntil then
            local coords = GetEntityCoords(ped)

            if canStartServing(session) then
                handleServePoint(session, ped, coords)
            else
                ui.hudPrompt(false)
            end

            local inPlay = isBallInPlay(court)
            local far, near = IsDisabledControlPressed(0, controls.aimFar), IsDisabledControlPressed(0, controls.aimNear)
            local left, right = IsDisabledControlPressed(0, controls.aimLeft), IsDisabledControlPressed(0, controls.aimRight)

            if inPlay and IsDisabledControlJustPressed(0, controls.shotRegular) then
                attemptHit(ped, session, 'normal')
            elseif inPlay and IsDisabledControlJustPressed(0, controls.shotBackspin) then
                attemptHit(ped, session, 'backspin')
            elseif inPlay and IsDisabledControlJustPressed(0, controls.shotTopspin) then
                attemptHit(ped, session, 'topspin')
            elseif far and left then
                playMovementAnim(ped, 'run_fwd_-45', false, true)
            elseif far and right then
                playMovementAnim(ped, 'run_fwd_45', false, true)
            elseif near and left then
                playMovementAnim(ped, 'run_bwd_-135', false, true)
            elseif near and right then
                playMovementAnim(ped, 'run_bwd_135', false, true)
            elseif far then
                playMovementAnim(ped, 'run_fwd_0', false, true)
            elseif near then
                playMovementAnim(ped, 'strafe_bwd', false, true)
            elseif left then
                playMovementAnim(ped, 'run_bwd_-90_loop', true, true)
            elseif right then
                playMovementAnim(ped, 'run_fwd_90_loop', true, true)
            elseif IsDisabledControlJustPressed(0, controls.leave) then
                stopPlaying()
                break
            else
                if shouldSqueak then
                    PlaySoundFromEntity(-1, 'TENNIS_FOOT_SQUEAKS_MASTER', ped, 0, false, 0)
                    shouldSqueak = false
                end
                stopMovementAnim(ped, true)
            end
        end

        frame += 1
        if frame % 10 == 0 and playing == session then
            local _, inExtended, isASide = geometry.pointData(geo, GetEntityCoords(ped), side)
            local wrongSide = (side == 'a') ~= isASide

            if wrongSide or not inExtended or IsEntityDead(ped) then
                stopPlaying()
            end
        end
    end
end

---@param court table
---@param distance number
local function handleJoinPoints(court, distance)
    if playing or distance > markerDistance then return end

    local coords = GetEntityCoords(cache.ped)
    local points = court.geo.servePoints
    local players = court.players
    local nearSide

    for i = 1, 2 do
        local side = SIDES[i]
        if not players[side] then
            local point = points[side].right
            DrawMarker(0, point.x, point.y, point.z + 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.5, 255, 255, 255, 150, false, false, 2, false, nil, nil, false)

            if #(coords.xy - point.xy) < joinDistance then
                nearSide = side
            end
        end
    end

    if not nearSide then
        if promptCourt == court then
            promptCourt = nil
            ui.joinPrompt(false)
        end
        return
    end

    promptCourt = court
    ui.joinPrompt(true)

    local now = GetGameTimer()
    if now <= actionCooldown or not IsControlJustPressed(0, controls.join) then return end

    if IsControlPressed(0, controls.tutorialModifier) then
        actionCooldown = now + 500
        ui.toggleTutorial()
    else
        actionCooldown = now + 3000
        TriggerServerEvent('sm_tennis:join', court.id, nearSide)
    end
end

for i = 1, #courtList do
    local court = courtList[i]

    lib.points.new({
        coords = court.center,
        distance = config.subscribeDistance,
        onEnter = function()
            activateCourt(court)
        end,
        onExit = function()
            if promptCourt == court then
                promptCourt = nil
                ui.joinPrompt(false)
            end
            deactivateCourt(court)
        end,
        nearby = function(self)
            handleJoinPoints(court, self.currentDistance)
        end,
    })
end

CreateThread(function()
    local blipConfig = config.blip

    for i = 1, #courtList do
        local court = courtList[i]
        if config.courts[court.id].blip then
            local center = court.center
            local blip = AddBlipForCoord(center.x, center.y, center.z)
            SetBlipSprite(blip, blipConfig.sprite)
            SetBlipColour(blip, blipConfig.color)
            SetBlipScale(blip, blipConfig.scale)
            SetBlipDisplay(blip, 4)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(blipConfig.label)
            EndTextCommandSetBlipName(blip)
            blips[#blips + 1] = blip
        end
    end
end)

CreateThread(function()
    while true do
        local busy = false

        if activeCount > 0 then
            local dt = mathMin(GetFrameTime(), 0.05)

            for i = 1, activeCount do
                local court = activeCourts[i]
                if court.ball.moving then
                    busy = true
                    stepBall(court, dt)
                end
            end
        end

        Wait((busy or playing) and 0 or 100)
    end
end)

CreateThread(function()
    while true do
        if activeCount > 0 or next(rackets) then
            reconcileRackets()
        end
        Wait(1000)
    end
end)

RegisterNetEvent('sm_tennis:players', function(courtId, players)
    if GetInvokingResource() then return end

    local court = courtMap[courtId]
    if not court then return end

    court.players.a = players.a
    court.players.b = players.b
    reconcileRackets()
end)

RegisterNetEvent('sm_tennis:granted', function(courtId, side)
    if GetInvokingResource() or playing then return end

    local court = courtMap[courtId]
    if not court then return end

    promptCourt = nil
    ui.joinPrompt(false)

    local session = { court = court, side = side, state = nil, serving = false, canServe = false, inServe = false }
    playing = session
    ui.hudOpen(side)

    CreateThread(function()
        runWorker(session)
    end)
end)

RegisterNetEvent('sm_tennis:state', function(courtId, state)
    if GetInvokingResource() then return end

    local session = playing
    if not session or session.court.id ~= courtId then return end

    session.state = state
    session.canServe = state.canServe and state.server == session.side
    ui.hudUpdate(state, session.inServe)
end)

RegisterNetEvent('sm_tennis:result', function(kind, side)
    if GetInvokingResource() then return end

    local session = playing
    if not session then return end

    local mine = session.side == side

    if kind == 'point' then
        PlaySoundFrontend(-1, 'TENNIS_POINT_WON', 'HUD_AWARDS', true)
        ui.notify(mine and text.youWonPoint or text.opponentWonPoint, mine and 'success' or 'error')
    elseif kind == 'game' then
        PlaySoundFrontend(-1, 'TENNIS_MATCH_POINT', 'HUD_AWARDS', true)
        ui.notify(mine and text.youWonGame or text.opponentWonGame, mine and 'success' or 'error')
    elseif kind == 'start' then
        ui.notify(text.matchStart, 'success')
    elseif kind == 'left' then
        ui.notify(text.opponentLeft, 'warning')
    end
end)

RegisterNetEvent('sm_tennis:ball', function(serverId, courtId, spin, pos, vel, auth)
    if GetInvokingResource() then return end

    local court = courtMap[courtId]
    if not court or not court.active then return end

    local ped = pedFromServerId(serverId)
    if ped then
        PlaySoundFromEntity(-1, 'TENNIS_PLYR_SMASH_MASTER', ped, 0, false, 0)
    end

    local ball = court.ball
    ensureBallEntity(court, pos)

    ball.pos, ball.vel, ball.spin, ball.auth = pos, vel, spin, auth
    ball.holder = nil
    ball.collidedLast = false
    ball.reports = 0
    ball.predicted = nil
    ball.moving = true

    refreshPrediction(court)
end)

RegisterNetEvent('sm_tennis:ballInHand', function(serverId, courtId)
    if GetInvokingResource() then return end

    local court = courtMap[courtId]
    if not court or not court.active then return end

    local ball = court.ball
    stopTrail(ball)
    ball.pos, ball.vel, ball.predicted, ball.auth = nil, nil, nil, nil
    ball.moving = false
    ball.holder = serverId
    ball.version += 1

    local ped = pedFromServerId(serverId)
    if ped then
        local entity = ensureBallEntity(court, GetEntityCoords(ped))
        if entity then
            AttachEntityToEntity(entity, ped, GetPedBoneIndex(ped, BALL_HAND_BONE), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, false, false, false, 2, true)
        end
    end

    local session = playing
    if session and session.court == court and serverId == cache.serverId then
        session.serving = true
    end
end)

RegisterNetEvent('sm_tennis:tool', function()
    if GetInvokingResource() then return end
    tool.start(GetEntityCoords(cache.ped) - vec3(0.0, 0.0, 0.99))
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    stopPlaying()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    if playing then
        stopPlaying(true)
    end

    tool.stop()
    ui.clear()

    for i = 1, #courtList do
        clearBall(courtList[i])
    end

    for serverId in pairs(rackets) do
        removeRacket(serverId)
    end

    for i = 1, #blips do
        RemoveBlip(blips[i])
    end
end)
