local config = localmodule 'config'
local infoui = exports.rhd_infoui
local hasFrame = interface.init(false)

local Wait = Wait
local GetGameTimer = GetGameTimer
local GetEntityCoords = GetEntityCoords
local DoesEntityExist = DoesEntityExist
local DeleteEntity = DeleteEntity
local CreatePed = CreatePed
local SetEntityCoords = SetEntityCoords
local SetEntityHeading = SetEntityHeading
local IsEntityPlayingAnim = IsEntityPlayingAnim
local DisableAllControlActions = DisableAllControlActions
local EnableControlAction = EnableControlAction
local IsDisabledControlJustPressed = IsDisabledControlJustPressed
local ClearPedTasks = ClearPedTasks
local SetEntityInvincible = SetEntityInvincible
local FreezeEntityPosition = FreezeEntityPosition
local SetBlockingOfNonTemporaryEvents = SetBlockingOfNonTemporaryEvents
local SetPedFleeAttributes = SetPedFleeAttributes
local SetPedCanRagdoll = SetPedCanRagdoll
local SetPedKeepTask = SetPedKeepTask
local SetModelAsNoLongerNeeded = SetModelAsNoLongerNeeded
local SetPedMoveRateOverride = SetPedMoveRateOverride
local SetPedToRagdoll = SetPedToRagdoll
local SetCurrentPedWeapon = SetCurrentPedWeapon
local TaskPlayAnim = TaskPlayAnim
local StopAnimTask = StopAnimTask
local ClearPedTasksImmediately = ClearPedTasksImmediately
local SetPedMovementClipset = SetPedMovementClipset
local GetHeadingFromVector_2d = GetHeadingFromVector_2d
local TaskWanderInArea = TaskWanderInArea
local TaskGoStraightToCoord = TaskGoStraightToCoord
local HasEntityClearLosToEntity = HasEntityClearLosToEntity
local IsEntityDead = IsEntityDead
local IsScreenFadedOut = IsScreenFadedOut
local IsScreenFadedIn = IsScreenFadedIn
local DoScreenFadeOut = DoScreenFadeOut
local DoScreenFadeIn = DoScreenFadeIn
local RequestCollisionAtCoord = RequestCollisionAtCoord
local HasCollisionLoadedAroundEntity = HasCollisionLoadedAroundEntity
local GetInteriorAtCoords = GetInteriorAtCoords
local IsInteriorReady = IsInteriorReady
local PinInteriorInMemory = PinInteriorInMemory
local SetTimecycleModifier = SetTimecycleModifier
local SetTimecycleModifierStrength = SetTimecycleModifierStrength
local ClearTimecycleModifier = ClearTimecycleModifier
local ShakeGameplayCam = ShakeGameplayCam
local StopGameplayCamShaking = StopGameplayCamShaking
local AnimpostfxPlay = AnimpostfxPlay
local AnimpostfxStop = AnimpostfxStop
local DisableControlAction = DisableControlAction
local DisablePlayerFiring = DisablePlayerFiring
local DrawMarker = DrawMarker
local GetFollowPedCamViewMode = GetFollowPedCamViewMode
local SetFollowPedCamViewMode = SetFollowPedCamViewMode
local GetInvokingResource = GetInvokingResource
local abs = math.abs
local rad, sin, cos = math.rad, math.sin, math.cos
local GetGameplayCamRot = GetGameplayCamRot
local GetPedBoneCoords = GetPedBoneCoords
local DrawSpotLightWithShadow = DrawSpotLightWithShadow
local sformat = string.format
local CreateCamWithParams = CreateCamWithParams
local PointCamAtCoord = PointCamAtCoord
local SetCamActive = SetCamActive
local SetCamFov = SetCamFov
local ShakeCam = ShakeCam
local RenderScriptCams = RenderScriptCams
local DestroyCam = DestroyCam
local DoesCamExist = DoesCamExist
local SetEntityCoordsNoOffset = SetEntityCoordsNoOffset
local SetEntityLocallyInvisible = SetEntityLocallyInvisible
local HideHudAndRadarThisFrame = HideHudAndRadarThisFrame
local SetGameplayCamRelativeHeading = SetGameplayCamRelativeHeading
local SetGameplayCamRelativePitch = SetGameplayCamRelativePitch

local LEVELS = config.levels
local PASSOUT = config.passout or { enabled = false }
local PASSOUT_ANIM = PASSOUT.anim
local PASSOUT_GETUP = PASSOUT.getup
local MASH_KEY = 22
local GRACE_MS = config.graceMs
local CATCH_DISTANCE = config.catchDistance
local SIGHT_RANGE = config.sightRange
local HEAR_RANGE = config.hearRange
local LOSE_RANGE = config.loseRange
local LOSE_MS = config.loseMs
local WANDER_RADIUS = config.wanderRadius
local MONSTER_WALK = config.monsterWalk
local CATCH_ANIM = config.catchAnim
local CATCH_CAM = config.catchCam or {}
local CATCH_GAP = CATCH_CAM.gap or 0.8
local CATCH_FOV_FROM = CATCH_CAM.fovFrom or 60.0
local CATCH_FOV_TO = CATCH_CAM.fovTo or 40.0
local CATCH_SHAKE = CATCH_CAM.shake or 2.4
local CATCH_AIM = CATCH_CAM.aim or 0.0
local CATCH_ANIM_READY = false
local EXIT_DISTANCE = config.exitDistance
local EXIT_MARKER = config.exitMarker
local EXIT_MARKER_RANGE = config.exitMarkerRange
local EXIT_MARKER_TYPE = config.exitMarkerType or 1
local EXIT_MARKER_Z = config.exitMarkerZOffset or 0.0
local THINK_MS = 200
local CHASE_REPATH_MS = 400
local STUCK_DISTANCE = 0.4
local STUCK_MS = config.stuckMs or 2500
local CRUMB_MAX = 300
local CRUMB_SPACING = 1.0
local CRUMB_REACH = 1.0
local TELEPORT_BACK = 12
local TELEPORT_MIN_DISTANCE = config.teleportMinDistance or 6.0
local HEARTBEAT_RANGE = config.heartbeatRange or 18.0
local FRAME_HIDE_MS = 2000
local INFO_ID = 'sm_backrooms'
local UNARMED = `WEAPON_UNARMED`
local FIRST_PERSON = 4
local CONTROLS = { 0, 23, 24, 25, 37, 44, 140, 141, 142, 143, 257, 263, 264 }
local FLASH_KEY = 23
local FLASH = config.flash
local FLASH_RANGE = FLASH.range
local FLASH_CONE = FLASH.cone
local FLASH_MS = FLASH.durationMs
local STUN_MS = FLASH.stunMs
local FLASH_BRIGHTNESS = FLASH.brightness
local FLASH_RADIUS = FLASH.radius
local FLASH_R, FLASH_G, FLASH_B = FLASH.color[1], FLASH.color[2], FLASH.color[3]
local STUN_ANIM = FLASH.stunAnim
local STUN_ANIM_READY = false
local CONTROL_COUNT = #CONTROLS
local LEAVE_MESSAGES = {
    caught = { 'Kamu tertangkap makhluk backrooms...', 'error' },
    timeout = { 'Waktu habis, kegelapan backrooms menelanmu...', 'error' },
    escape = { 'Kamu berhasil keluar dari backrooms!', 'success' },
    admin = { 'Kamu dikeluarkan dari backrooms oleh admin.', 'inform' },
}

---@class BackroomsMonster
---@field ped number
---@field home vector4
---@field speed number
---@field rate number
---@field chasing boolean
---@field lastSeen number
---@field nextRepath number
---@field lastPos vector3
---@field movedAt number
---@field crumb integer
---@field stunnedUntil number

---@class BackroomsClientSession
---@field level table
---@field final boolean
---@field monsters BackroomsMonster[]
---@field exits vector3[]
---@field zones number[]
---@field endsAt number
---@field activeAt number
---@field ending boolean
---@field escapeAt number
---@field crumbs vector3[]
---@field crumbHead integer
---@field heartbeat number
---@field flashUsed boolean
---@field flashUntil number

---@type BackroomsClientSession?
local active
local catchCam
local previousViewMode
local passedOut = false
local frameShown = false

---@param message table
local function send(message)
    if frameShown then interface.send(message) end
end

local function showFrame()
    if not hasFrame or frameShown then return end
    frameShown = true
    interface.show()
end

local function hideFrame()
    if not frameShown or active or passedOut then return end
    frameShown = false
    interface.hide()
end

---@param name string
---@param volume? number
local function sound(name, volume)
    send({ action = 'sound', name = name, volume = volume or 1.0 })
end

---@param message string
---@param kind? string
local function notify(message, kind)
    lib.notify({ description = message, type = kind or 'inform' })
end

---@param ms number
local function fadeOut(ms)
    DoScreenFadeOut(ms)
    local deadline = GetGameTimer() + ms + 2000
    while not IsScreenFadedOut() and GetGameTimer() < deadline do
        Wait(0)
    end
end

---@param spot vector4
local function teleport(spot)
    local ped = cache.ped
    local x, y, z = spot.x, spot.y, spot.z

    FreezeEntityPosition(ped, true)
    SetEntityCoords(ped, x, y, z, false, false, false, false)
    SetEntityHeading(ped, spot.w)

    local deadline = GetGameTimer() + 6000
    local interior = GetInteriorAtCoords(x, y, z)
    if interior ~= 0 then
        PinInteriorInMemory(interior)
        while not IsInteriorReady(interior) and GetGameTimer() < deadline do
            Wait(0)
        end
    end

    RequestCollisionAtCoord(x, y, z)
    while not HasCollisionLoadedAroundEntity(ped) and GetGameTimer() < deadline do
        RequestCollisionAtCoord(x, y, z)
        Wait(0)
    end

    SetEntityCoords(ped, x, y, z, false, false, false, false)
    FreezeEntityPosition(ped, false)
end

---@param monster BackroomsMonster
local function wander(monster)
    local home = monster.home
    TaskWanderInArea(monster.ped, home.x, home.y, home.z, WANDER_RADIUS, 2.0, 2.0)
end

---@param level table
---@return BackroomsMonster[]
local function spawnMonsters(level)
    local list = level.monsters
    local monsters = {}
    local walkReady = MONSTER_WALK and pcall(lib.requestAnimSet, MONSTER_WALK, 5000)
    CATCH_ANIM_READY = pcall(lib.requestAnimDict, CATCH_ANIM.dict, 5000)
    STUN_ANIM_READY = pcall(lib.requestAnimDict, STUN_ANIM.dict, 5000)

    for i = 1, #list do
        local entry = list[i]
        if pcall(lib.requestModel, entry.model, 10000) then
            local spot = entry.coords
            local ped = CreatePed(4, entry.model, spot.x, spot.y, spot.z - 1.0, spot.w, false, true)
            SetModelAsNoLongerNeeded(entry.model)
            SetEntityInvincible(ped, true)
            SetBlockingOfNonTemporaryEvents(ped, true)
            SetPedFleeAttributes(ped, 0, false)
            SetPedCanRagdoll(ped, false)
            SetPedKeepTask(ped, true)
            if walkReady then
                SetPedMovementClipset(ped, MONSTER_WALK, 0.25)
            end

            local monster = {
                ped = ped,
                home = spot,
                speed = entry.speed or 2.0,
                rate = entry.rate or 1.0,
                chasing = false,
                lastSeen = 0,
                nextRepath = 0,
                lastPos = spot.xyz,
                movedAt = 0,
                crumb = 0,
                stunnedUntil = 0,
            }
            wander(monster)
            monsters[#monsters + 1] = monster
        else
            print(sformat('^1[sm_backrooms]^7 model monster %s gagal dimuat', entry.model))
        end
    end

    return monsters
end

local function cleanupSession()
    local session = active
    if not session then return end
    active = nil

    local monsters = session.monsters
    for i = 1, #monsters do
        local ped = monsters[i].ped
        if DoesEntityExist(ped) then DeleteEntity(ped) end
    end

    local zones = session.zones
    for i = 1, #zones do
        ox_target:removeZone(zones[i])
    end

    send({ action = 'stopAll' })
    ClearTimecycleModifier()
    AnimpostfxStop('DeathFailMPIn')
    StopGameplayCamShaking(true)
    infoui:remove(INFO_ID)
end

local function destroyCatchCam()
    local cam = catchCam
    catchCam = nil
    if not cam or not DoesCamExist(cam) then return end
    RenderScriptCams(false, false, 0, true, false)
    DestroyCam(cam, false)
end

---@param ped number
---@param mped number
local function catchCinematic(ped, mped)
    local eye = GetPedBoneCoords(ped, 31086, 0.0, 0.0, 0.0)
    local mpos = GetEntityCoords(mped)
    local dx, dy = mpos.x - eye.x, mpos.y - eye.y
    local flat = (dx * dx + dy * dy) ^ 0.5
    if flat > CATCH_GAP then
        local scale = CATCH_GAP / flat
        SetEntityCoordsNoOffset(mped, eye.x + dx * scale, eye.y + dy * scale, mpos.z, false, false, false)
    end
    SetEntityHeading(mped, GetHeadingFromVector_2d(eye.x - mpos.x, eye.y - mpos.y))

    local head = GetPedBoneCoords(mped, 31086, 0.0, 0.0, 0.0)
    local cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', eye.x, eye.y, eye.z, 0.0, 0.0, 0.0, CATCH_FOV_FROM, false, 0)
    catchCam = cam
    PointCamAtCoord(cam, head.x, head.y, head.z - CATCH_AIM)
    SetCamActive(cam, true)
    RenderScriptCams(true, false, 0, true, false)
    ShakeCam(cam, 'HAND_SHAKE', CATCH_SHAKE)

    if CATCH_ANIM_READY then
        TaskPlayAnim(mped, CATCH_ANIM.dict, CATCH_ANIM.clip, 8.0, -8.0, CATCH_ANIM.duration, 0, 0.0, false, false, false)
    end

    local duration = CATCH_ANIM.duration
    local zoomMs = duration * 0.45
    local startedAt = GetGameTimer()
    local elapsed = 0
    while elapsed < duration and catchCam == cam do
        local progress = elapsed / zoomMs
        if progress > 1.0 then progress = 1.0 end
        SetCamFov(cam, CATCH_FOV_FROM + (CATCH_FOV_TO - CATCH_FOV_FROM) * progress)
        if DoesEntityExist(mped) then
            head = GetPedBoneCoords(mped, 31086, 0.0, 0.0, 0.0)
            PointCamAtCoord(cam, head.x, head.y, head.z - CATCH_AIM)
        end
        SetEntityLocallyInvisible(ped)
        HideHudAndRadarThisFrame()
        DisableAllControlActions(0)
        Wait(0)
        elapsed = GetGameTimer() - startedAt
    end

    destroyCatchCam()
    SetGameplayCamRelativeHeading(0.0)
    SetGameplayCamRelativePitch(0.0, 1.0)
end

---@param monster? BackroomsMonster
local function caught(monster)
    local session = active
    if not session or session.ending then return end
    session.ending = true

    local ped = cache.ped
    if monster and DoesEntityExist(monster.ped) then
        local mped = monster.ped
        local mpos = GetEntityCoords(mped)
        local ppos = GetEntityCoords(ped)
        ClearPedTasksImmediately(mped)
        SetEntityHeading(mped, GetHeadingFromVector_2d(ppos.x - mpos.x, ppos.y - mpos.y))
        SetEntityHeading(ped, GetHeadingFromVector_2d(mpos.x - ppos.x, mpos.y - ppos.y))
        FreezeEntityPosition(ped, true)
        send({ action = 'loopStop', name = 'heartbeat' })
        sound('jumpscare', 1.0)
        catchCinematic(ped, mped)
        FreezeEntityPosition(ped, false)
        ShakeGameplayCam('LARGE_EXPLOSION_SHAKE', 0.5)
        AnimpostfxPlay('DeathFailMPIn', 0, false)
        sound('thud', 1.0)
        SetPedToRagdoll(ped, 2000, 2000, 0, false, false, false)
        Wait(1000)
    end

    fadeOut(500)
    TriggerTokenEvent('sm_backrooms:caught')

    SetTimeout(10000, function()
        if active == session and IsScreenFadedOut() then
            session.ending = false
            DoScreenFadeIn(500)
        end
    end)
end

local function tryEscape()
    local session = active
    if not session or session.ending then return end
    local now = GetGameTimer()
    if now < session.escapeAt then return end
    session.escapeAt = now + 2000
    TriggerTokenEvent('sm_backrooms:escape')
end

---@param crumbs vector3[]
---@param index integer
---@return vector3
local function crumbAt(crumbs, index)
    return crumbs[(index - 1) % CRUMB_MAX + 1]
end

---@param session BackroomsClientSession
---@param monster BackroomsMonster
---@param playerPos vector3
---@param now number
---@return vector3?
local function teleportBehind(session, monster, playerPos, now)
    local crumbs = session.crumbs
    local head = session.crumbHead
    local oldest = head - CRUMB_MAX + 1
    if oldest < 1 then oldest = 1 end

    monster.movedAt = now
    for index = head - TELEPORT_BACK, oldest, -1 do
        local spot = crumbAt(crumbs, index)
        if #(spot - playerPos) >= TELEPORT_MIN_DISTANCE then
            SetEntityCoords(monster.ped, spot.x, spot.y, spot.z, false, false, false, false)
            monster.crumb = index
            monster.lastPos = spot
            monster.nextRepath = 0
            return spot
        end
    end
end

---@param session BackroomsClientSession
---@param volume number
local function setHeartbeat(session, volume)
    local last = session.heartbeat
    if volume <= 0.0 then
        if last > 0.0 then
            session.heartbeat = 0.0
            send({ action = 'loopStop', name = 'heartbeat' })
        end
        return
    end
    if last > 0.0 and abs(volume - last) < 0.05 then return end
    session.heartbeat = volume
    send({ action = 'loop', name = 'heartbeat', volume = volume })
end

---@param session BackroomsClientSession
local function thinkLoop(session)
    local monsters = session.monsters
    local monsterCount = #monsters
    local crumbs = session.crumbs

    while active == session do
        local now = GetGameTimer()
        local ped = cache.ped

        if not session.ending then
            local playerPos = GetEntityCoords(ped)
            local head = session.crumbHead
            if head == 0 or #(playerPos - crumbAt(crumbs, head)) >= CRUMB_SPACING then
                head = head + 1
                crumbs[(head - 1) % CRUMB_MAX + 1] = playerPos
                session.crumbHead = head
            end

            if IsEntityDead(ped) then
                caught(nil)
            elseif now >= session.activeAt and now >= session.escapeAt then
                local closest = HEARTBEAT_RANGE

                for i = 1, monsterCount do
                    local monster = monsters[i]
                    local mped = monster.ped

                    if DoesEntityExist(mped) then
                        if monster.stunnedUntil > now then
                            goto nextMonster
                        end
                        if monster.stunnedUntil > 0 then
                            monster.stunnedUntil = 0
                            StopAnimTask(mped, STUN_ANIM.dict, STUN_ANIM.clip, 1.0)
                            monster.nextRepath = 0
                            monster.lastSeen = now
                            monster.movedAt = now
                            monster.lastPos = GetEntityCoords(mped)
                        end

                        local mpos = GetEntityCoords(mped)
                        local distance = #(mpos - playerPos)

                        if distance <= CATCH_DISTANCE then
                            caught(monster)
                            break
                        end

                        local seen = distance <= SIGHT_RANGE and HasEntityClearLosToEntity(mped, ped, 17)

                        if not monster.chasing and (seen or distance <= HEAR_RANGE) then
                            monster.chasing = true
                            monster.lastSeen = now
                            monster.crumb = head
                            monster.nextRepath = 0
                            monster.lastPos = mpos
                            monster.movedAt = now
                            sound('shriek', distance < 10.0 and 0.9 or 0.5)
                        end

                        if monster.chasing then
                            if seen then
                                monster.lastSeen = now
                                monster.crumb = head
                            end

                            if distance > LOSE_RANGE or now - monster.lastSeen > LOSE_MS then
                                monster.chasing = false
                                wander(monster)
                            else
                                if #(mpos - monster.lastPos) >= STUCK_DISTANCE then
                                    monster.lastPos = mpos
                                    monster.movedAt = now
                                elseif now - monster.movedAt > STUCK_MS then
                                    mpos = teleportBehind(session, monster, playerPos, now) or mpos
                                end

                                local target
                                if seen then
                                    target = playerPos
                                else
                                    local oldest = head - CRUMB_MAX + 1
                                    if monster.crumb < oldest then monster.crumb = oldest end
                                    target = crumbAt(crumbs, monster.crumb)
                                    if monster.crumb < head and #(mpos - target) <= CRUMB_REACH then
                                        monster.crumb = monster.crumb + 1
                                        target = crumbAt(crumbs, monster.crumb)
                                        monster.nextRepath = 0
                                    end
                                end

                                if now >= monster.nextRepath then
                                    monster.nextRepath = now + CHASE_REPATH_MS
                                    TaskGoStraightToCoord(mped, target.x, target.y, target.z, monster.speed, -1, GetHeadingFromVector_2d(target.x - mpos.x, target.y - mpos.y), 0.5)
                                end

                                if distance < closest then closest = distance end
                            end
                        end
                    end
                    ::nextMonster::
                end

                if not session.ending then
                    setHeartbeat(session, closest < HEARTBEAT_RANGE and (1.0 - closest / HEARTBEAT_RANGE) or 0.0)
                end
            end
        end

        Wait(THINK_MS)
    end
end

---@return vector3
---@return vector3
local function flashRay()
    local rot = GetGameplayCamRot(2)
    local rx, rz = rad(rot.x), rad(rot.z)
    local pitch = cos(rx)
    local direction = vec3(-sin(rz) * pitch, cos(rz) * pitch, sin(rx))
    local head = GetPedBoneCoords(cache.ped, 31086, 0.0, 0.0, 0.0)
    return head + direction * 0.3, direction
end

---@param session BackroomsClientSession
local function triggerFlash(session)
    local now = GetGameTimer()
    session.flashUsed = true
    session.flashUntil = now + FLASH_MS
    sound('click', 1.0)

    local ped = cache.ped
    local origin, direction = flashRay()
    local monsters = session.monsters
    local hit = 0

    for i = 1, #monsters do
        local monster = monsters[i]
        local mped = monster.ped
        if DoesEntityExist(mped) then
            local offset = GetEntityCoords(mped) - origin
            local distance = #offset
            if distance > 0.01 and distance <= FLASH_RANGE
                and (offset.x * direction.x + offset.y * direction.y + offset.z * direction.z) / distance >= FLASH_CONE
                and HasEntityClearLosToEntity(ped, mped, 17) then
                monster.stunnedUntil = now + STUN_MS
                ClearPedTasksImmediately(mped)
                if STUN_ANIM_READY then
                    TaskPlayAnim(mped, STUN_ANIM.dict, STUN_ANIM.clip, 8.0, -8.0, STUN_MS, 1, 0.0, false, false, false)
                end
                hit = hit + 1
            end
        end
    end

    if hit > 0 then
        notify(sformat('%d makhluk silau dan terhenti sementara!', hit), 'success')
    else
        notify('Flash tidak mengenai makhluk apa pun.', 'error')
    end
end

---@param session BackroomsClientSession
local function frameLoop(session)
    local monsters = session.monsters
    local monsterCount = #monsters
    local exits = session.exits
    local exitCount = #exits
    local playerId = cache.playerId

    while active == session do
        DisablePlayerFiring(playerId, true)
        for i = 1, CONTROL_COUNT do
            DisableControlAction(0, CONTROLS[i], true)
        end
        if GetFollowPedCamViewMode() ~= FIRST_PERSON then
            SetFollowPedCamViewMode(FIRST_PERSON)
        end

        if not session.flashUsed and not session.ending and IsDisabledControlJustPressed(0, FLASH_KEY) then
            triggerFlash(session)
        end
        if session.flashUntil > GetGameTimer() then
            local origin, direction = flashRay()
            DrawSpotLightWithShadow(origin.x, origin.y, origin.z, direction.x, direction.y, direction.z, FLASH_R, FLASH_G, FLASH_B, FLASH_RANGE, FLASH_BRIGHTNESS, 1.0, FLASH_RADIUS, 1.0, 1)
        end

        for i = 1, monsterCount do
            local monster = monsters[i]
            if monster.chasing and monster.rate ~= 1.0 then
                SetPedMoveRateOverride(monster.ped, monster.rate)
            end
        end

        if EXIT_MARKER then
            local playerPos = GetEntityCoords(cache.ped)
            for i = 1, exitCount do
                local exit = exits[i]
                if #(playerPos - exit) < EXIT_MARKER_RANGE then
                    DrawMarker(EXIT_MARKER_TYPE, exit.x, exit.y, exit.z + EXIT_MARKER_Z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0, 204, 201, 160, false, true, 2, false, nil, nil, false)
                end
            end
        end

        Wait(0)
    end
end

---@param session BackroomsClientSession
local function hudLoop(session)
    local title = session.level.label
    local goal = session.final and 'Cari pintu keluar dan jangan sampai tertangkap.' or 'Cari pintu ke level berikutnya.'
    while active == session do
        local left = (session.endsAt - GetGameTimer()) // 1000
        if left < 0 then left = 0 end
        infoui:show({
            id = INFO_ID,
            title = title,
            icon = 'fa-solid fa-ghost',
            description = sformat('%s\nSisa waktu: %02d:%02d\n[kbd]F[/kbd] Flash senter: %s', goal, left // 60, left % 60, session.flashUsed and 'sudah dipakai' or 'siap (1x)'),
        })
        Wait(1000)
    end
end

---@param level table
---@param endsAt number
---@param final boolean
---@param startExit integer
local function beginLevel(level, endsAt, final, startExit)
    SetFollowPedCamViewMode(FIRST_PERSON)

    local exitList = level.exits
    local swappedStart = startExit and exitList[startExit]
    if swappedStart then
        teleport(swappedStart)
        exitList = { level.spawn }
    else
        teleport(level.spawn)
    end

    local exits = {}
    local zones = {}
    for i = 1, #exitList do
        local exit = exitList[i].xyz
        exits[i] = exit
        zones[i] = ox_target:addSphereZone({
            coords = exit,
            radius = 1.2,
            debug = false,
            options = {
                {
                    name = 'sm_backrooms_exit',
                    label = final and 'Buka pintu keluar' or 'Masuk ke level berikutnya',
                    icon = 'fa-solid fa-door-open',
                    distance = EXIT_DISTANCE,
                    onSelect = tryEscape,
                },
            },
        })
    end

    local now = GetGameTimer()
    local session = {
        level = level,
        final = final,
        monsters = spawnMonsters(level),
        exits = exits,
        zones = zones,
        endsAt = endsAt,
        activeAt = now + GRACE_MS,
        ending = false,
        escapeAt = 0,
        crumbs = {},
        crumbHead = 0,
        heartbeat = 0.0,
        flashUsed = false,
        flashUntil = 0,
    }
    active = session

    if level.timecycle then
        SetTimecycleModifier(level.timecycle)
        SetTimecycleModifierStrength(level.timecycleStrength or 1.0)
    end

    CreateThread(function() thinkLoop(session) end)
    CreateThread(function() frameLoop(session) end)
    CreateThread(function() hudLoop(session) end)
end

---@param ped number
local function playPassoutAnim(ped)
    TaskPlayAnim(ped, PASSOUT_ANIM.dict, PASSOUT_ANIM.clip, 8.0, -8.0, -1, 1, 0.0, false, false, false)
end

---@return boolean
local function startPassout()
    local ped = cache.ped
    if IsEntityDead(ped) or not pcall(lib.requestAnimDict, PASSOUT_ANIM.dict, 5000) then return false end
    passedOut = true
    ClearPedTasksImmediately(ped)
    playPassoutAnim(ped)
    return true
end

local function runPassout()
    local ped = cache.ped
    local step = PASSOUT.step
    local decay = PASSOUT.decay / 1000
    local now = GetGameTimer()
    local last = now
    local deadline = now + PASSOUT.maxMs
    local nextUpdate = 0
    local progress = 0.0
    local mashMessage = { action = 'mash', show = true, progress = 0 }

    send(mashMessage)

    while passedOut do
        now = GetGameTimer()
        DisableAllControlActions(0)
        EnableControlAction(0, 1, true)
        EnableControlAction(0, 2, true)
        EnableControlAction(0, 249, true)

        if IsDisabledControlJustPressed(0, MASH_KEY) then
            progress = progress + step
        end
        progress = progress - decay * (now - last)
        if progress < 0.0 then progress = 0.0 end
        last = now

        if progress >= 100.0 or now >= deadline or IsEntityDead(ped) then break end

        if now >= nextUpdate then
            nextUpdate = now + 100
            mashMessage.progress = progress
            send(mashMessage)
            if not IsEntityPlayingAnim(ped, PASSOUT_ANIM.dict, PASSOUT_ANIM.clip, 3) then
                playPassoutAnim(ped)
            end
        end

        Wait(0)
    end

    send({ action = 'mash', show = false })
    if not passedOut then return end
    passedOut = false
    if IsEntityDead(ped) then return end

    StopAnimTask(ped, PASSOUT_ANIM.dict, PASSOUT_ANIM.clip, 1.0)
    if pcall(lib.requestAnimDict, PASSOUT_GETUP.dict, 3000) then
        TaskPlayAnim(ped, PASSOUT_GETUP.dict, PASSOUT_GETUP.clip, 8.0, -8.0, PASSOUT_GETUP.duration, 0, 0.0, false, false, false)
        Wait(PASSOUT_GETUP.duration)
    end
    ClearPedTasks(ped)
    notify('Kamu tersadar kembali.', 'success')
end

local function restoreCamera()
    if not previousViewMode then return end
    SetFollowPedCamViewMode(previousViewMode)
    previousViewMode = nil
end

RegisterNetEvent('sm_backrooms:client:enter', function(levelIndex, duration, final, startExit)
    if GetInvokingResource() then return end
    local level = LEVELS[levelIndex]
    if not level or active then return end

    showFrame()
    fadeOut(800)

    previousViewMode = previousViewMode or GetFollowPedCamViewMode()
    SetCurrentPedWeapon(cache.ped, UNARMED, true)
    beginLevel(level, GetGameTimer() + duration * 1000, final == true, startExit)

    DoScreenFadeIn(1200)
    notify(sformat('%s — kamu terjebak di backrooms! Cari pintu keluar dan hindari makhluk di dalamnya.', level.label), 'error')
end)

RegisterNetEvent('sm_backrooms:client:level', function(levelIndex, final, startExit)
    if GetInvokingResource() then return end
    local level = LEVELS[levelIndex]
    local current = active
    if not level or not current then return end

    current.ending = true
    fadeOut(600)
    local endsAt = current.endsAt
    cleanupSession()
    beginLevel(level, endsAt, final == true, startExit)
    DoScreenFadeIn(1000)

    notify(sformat('%s — %s', level.label, final and 'level terakhir, temukan jalan keluar!' or 'cari pintu ke level berikutnya.'), 'error')
end)

RegisterNetEvent('sm_backrooms:client:leave', function(origin, reason)
    if GetInvokingResource() then return end

    if not IsScreenFadedOut() then fadeOut(600) end
    cleanupSession()
    restoreCamera()
    teleport(origin)

    local knockedOut = PASSOUT.enabled and (reason == 'caught' or reason == 'timeout') and startPassout()
    DoScreenFadeIn(1000)

    local message = LEAVE_MESSAGES[reason]
    if message then notify(message[1], message[2]) end

    if knockedOut then
        runPassout()
    end

    SetTimeout(FRAME_HIDE_MS, hideFrame)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end
    destroyCatchCam()
    cleanupSession()
    restoreCamera()
    if passedOut then
        passedOut = false
        ClearPedTasks(cache.ped)
    end
    if not IsScreenFadedIn() then DoScreenFadeIn(0) end
end)
