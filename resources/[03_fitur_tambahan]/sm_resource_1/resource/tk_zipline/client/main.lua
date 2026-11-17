local config = localmodule 'config.shared'
local shared = localmodule 'modules.shared'
local placer = localmodule 'modules.placer'

local PULLEY_MODEL = -1232739548
local ZIPLINE_ANIM_DICT = 'skydive@parachute@'
local ZIPLINE_ANIM_NAME = 'chute_idle_alt'
local POSE_ANIM_DICT = 'mp_player_int_uppergang_sign_a'
local POSE_ANIM_NAME = 'mp_player_int_gang_sign_a'
local MOTION_STATE_ZIPLINE = -1871534317
local STREAM_DISTANCE = 100.0
local ROPE_HEIGHT = 2.0
local CANCEL_CONTROL = 73
local FIRE_CONTROLS = { 24, 69, 92, 257 }

local text = config.text
local ziplines = {}
local isZiplining = false
local isPlacing = false
local lastGrappleUse = 0

local function notify(description, notifyType)
    lib.notify({
        title = 'Zipline',
        description = description,
        type = notifyType or 'error'
    })
end

local function playProgress(anim, label)
    return lib.progressCircle({
        duration = anim.duration,
        label = label,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { dict = anim.dict, clip = anim.name }
    })
end

---Abort the ride when the player is shot, stunned, or presses the cancel key.
local function shouldAbortRide(ped, health, armour)
    if GetEntityHealth(ped) < health or GetPedArmour(ped) < armour then
        return true
    end

    if IsPedBeingStunned(ped, 0) then
        return true
    end

    DisableControlAction(0, CANCEL_CONTROL, true)

    return IsDisabledControlJustPressed(0, CANCEL_CONTROL)
end

local function createRope(zipline)
    if zipline.rope then return end

    local startPole, endPole = zipline.startPole, zipline.endPole

    if not (startPole and endPole) then return end
    if not (DoesEntityExist(startPole) and DoesEntityExist(endPole)) then return end

    RopeLoadTextures()

    local timeout = GetGameTimer() + 5000

    while not RopeAreTexturesLoaded() and GetGameTimer() < timeout do
        Wait(10)
    end

    if not RopeAreTexturesLoaded() then return end

    local startPos, endPos = zipline.startPos, zipline.endPos
    local ropeStart = vec3(startPos.x, startPos.y, startPos.z + ROPE_HEIGHT)
    local ropeEnd = vec3(endPos.x, endPos.y, endPos.z + ROPE_HEIGHT)
    local length = #(ropeEnd - ropeStart)

    -- Type 4 is the thick, clearly visible rope used elsewhere on the server.
    local rope = AddRope(
        ropeStart.x, ropeStart.y, ropeStart.z,
        0.0, 0.0, 0.0,
        length, 4, length,
        1.0, 1.0,
        false, true, false,
        1.0, false, 0
    )

    if not rope or rope == 0 then return end

    timeout = GetGameTimer() + 5000

    while not DoesRopeExist(rope) and GetGameTimer() < timeout do
        Wait(10)
    end

    if not DoesRopeExist(rope) then return end

    zipline.rope = rope

    AttachEntitiesToRope(
        rope, startPole, endPole,
        ropeStart.x, ropeStart.y, ropeStart.z,
        ropeEnd.x, ropeEnd.y, ropeEnd.z,
        length, false, false, '', ''
    )

    -- Pull the slack out so the line reads as a taut zipline, not a hanging rope.
    RopeForceLength(rope, length)
end

local function destroyRope(zipline)
    if not zipline.rope then return end

    DeleteRope(zipline.rope)
    RopeUnloadTextures()

    zipline.rope = nil
end

---Slide the player along a pulley travelling from startPos to endPos.
local function ride(startPos, endPos, travelDuration, angle, heading, onTick, onFinish)
    local ped = cache.ped

    lib.requestModel(PULLEY_MODEL)

    local pulley = CreateObject(PULLEY_MODEL, startPos.x, startPos.y, startPos.z + 2.0, true, true, false)
    SetEntityRotation(pulley, 0.0, 90.0, heading, 2, true)

    local hangOffset = shared.getHangOffset(angle, heading)

    SetEntityCoords(ped, startPos.x, startPos.y, startPos.z, false, false, false, false)
    SetEntityRotation(ped, 0.0, 90.0, heading, 2, true)

    AttachEntityToEntity(
        ped, pulley, 0,
        hangOffset.x, hangOffset.y, hangOffset.z,
        angle, 0.0, heading,
        false, false, false, true, 2, false
    )

    lib.requestAnimDict(ZIPLINE_ANIM_DICT)
    TaskPlayAnim(ped, ZIPLINE_ANIM_DICT, ZIPLINE_ANIM_NAME, 4.0, 4.0, -1, 1, 0, false, false, false)

    lib.requestAnimDict(POSE_ANIM_DICT)
    TaskPlayAnim(ped, POSE_ANIM_DICT, POSE_ANIM_NAME, 8.0, -8.0, -1, 49, 0, false, false, false)

    local health, armour = GetEntityHealth(ped), GetPedArmour(ped)
    local startTime = GetGameTimer()
    local delta = endPos - startPos

    isZiplining = true

    CreateThread(function()
        while true do
            if shouldAbortRide(ped, health, armour) then break end

            ForcePedMotionState(ped, MOTION_STATE_ZIPLINE, false, 0, false)

            local step = shared.clampProgress((GetGameTimer() - startTime) / travelDuration)
            local pos = startPos + delta * step

            SetEntityCoords(pulley, pos.x, pos.y, pos.z + 2.0, false, false, false, false)

            if onTick then onTick(step) end

            if step >= 1.0 then break end

            Wait(0)
        end

        DetachEntity(ped, true, true)
        DeleteObject(pulley)
        ClearPedTasks(ped)

        isZiplining = false

        if onFinish then onFinish() end
    end)
end

local function startZipline(startPos, endPos, ziplineConfig)
    if isZiplining then return end

    local angle, distance = shared.getAngle(startPos, endPos)
    local maxUpwardsAngle = ziplineConfig.maxUpwardsAngle or config.baseMaxUpwardsAngle

    if angle > 0 and angle > maxUpwardsAngle then
        return notify(text.angleTooSteep)
    end

    local travelDuration = shared.getTravelDuration(
        distance,
        angle,
        config.baseDurationMultiplier * (ziplineConfig.durationMultiplier or 1.0),
        config.baseAngleEffectMultiplier * (ziplineConfig.angleEffectMultiplier or 1.0)
    )

    ride(
        startPos,
        endPos,
        travelDuration,
        angle,
        GetHeadingFromVector_2d(endPos.x - startPos.x, endPos.y - startPos.y)
    )
end

---Ride whichever direction the player is standing closest to.
local function useZipline(zipline)
    local coords = GetEntityCoords(cache.ped)
    local ziplineConfig = shared.getConfig(zipline.ziplineType, zipline.configIndex) or {}

    if #(coords - zipline.startPos) < #(coords - zipline.endPos) then
        startZipline(zipline.startPos, zipline.endPos, ziplineConfig)
    else
        startZipline(zipline.endPos, zipline.startPos, ziplineConfig)
    end
end

local function removeZipline(zipline)
    if not playProgress(config.anims.remove, text.removing) then return end

    TriggerServerEvent('tk_zipline:removeZipline', zipline.id)
end

local warnedModels = {}

local function spawnPole(model, coords, offset)
    -- requestModel throws on a genuinely missing model, so keep it contained:
    -- a bad pole must not stop the rope or the rest of the zipline from loading.
    local loaded = pcall(lib.requestModel, model, 5000)

    if not loaded or not HasModelLoaded(model) then
        if not warnedModels[model] then
            warnedModels[model] = true
            print(('[tk_zipline] poleModel %s gagal dimuat - cek config/shared.lua'):format(model))
        end

        return
    end

    local pos = coords + (offset or vec3(0.0, 0.0, 0.0))
    local pole = CreateObjectNoOffset(model, pos.x, pos.y, pos.z, false, true, false)

    if not pole or pole == 0 or not DoesEntityExist(pole) then return end

    SetEntityRotation(pole, 0.0, 0.0, 0.0, 2, true)
    FreezeEntityPosition(pole, true)

    return pole
end

local function addPoleTarget(zipline, pole)
    local ziplineConfig = shared.getConfig(zipline.ziplineType, zipline.configIndex) or {}

    local options = {
        {
            name = ('tk_zipline_use_%s'):format(zipline.id),
            label = text.useZipline,
            icon = 'fa-solid fa-hand',
            distance = 2.0,
            onSelect = function()
                useZipline(zipline)
            end
        }
    }

    if ziplineConfig.canRemove then
        options[#options + 1] = {
            name = ('tk_zipline_remove_%s'):format(zipline.id),
            label = text.remove,
            icon = 'fa-solid fa-trash',
            distance = 2.0,
            onSelect = function()
                removeZipline(zipline)
            end
        }
    end

    exports.ox_target:addLocalEntity(pole, options)
end

local function spawnZipline(zipline)
    if zipline.startPole then return end

    local ziplineConfig = shared.getConfig(zipline.ziplineType, zipline.configIndex) or {}
    local model = ziplineConfig.poleModel or config.ziplineGun.poleModel
    local offset = ziplineConfig.offset

    zipline.startPole = spawnPole(model, zipline.startPos, offset)
    zipline.endPole = spawnPole(model, zipline.endPos, offset)

    if zipline.startPole then addPoleTarget(zipline, zipline.startPole) end
    if zipline.endPole then addPoleTarget(zipline, zipline.endPole) end

    createRope(zipline)
end

local function despawnZipline(zipline)
    destroyRope(zipline)

    local startPole, endPole = zipline.startPole, zipline.endPole

    if startPole then
        exports.ox_target:removeLocalEntity(startPole)

        if DoesEntityExist(startPole) then
            DeleteEntity(startPole)
        end

        zipline.startPole = nil
    end

    if endPole then
        exports.ox_target:removeLocalEntity(endPole)

        if DoesEntityExist(endPole) then
            DeleteEntity(endPole)
        end

        zipline.endPole = nil
    end
end

---Register a zipline plus the two points that stream its poles in and out.
local function registerZipline(id, data)
    if ziplines[id] then return end

    local zipline = {
        id = id,
        startPos = data.startPos,
        endPos = data.endPos,
        configIndex = data.configIndex,
        ziplineType = data.ziplineType or 'static'
    }

    -- Both ends share the prop set, so only despawn once the player leaves both.
    local nearby = 0

    local function onEnter()
        nearby = nearby + 1

        spawnZipline(zipline)
    end

    local function onExit()
        nearby = nearby - 1

        if nearby > 0 then return end

        nearby = 0

        despawnZipline(zipline)
    end

    zipline.points = {
        lib.points.new({ coords = zipline.startPos, distance = STREAM_DISTANCE, onEnter = onEnter, onExit = onExit }),
        lib.points.new({ coords = zipline.endPos, distance = STREAM_DISTANCE, onEnter = onEnter, onExit = onExit })
    }

    ziplines[id] = zipline
end

local function unregisterZipline(id)
    local zipline = ziplines[id]

    if not zipline then return end

    for i = 1, #zipline.points do
        zipline.points[i]:remove()
    end

    despawnZipline(zipline)

    ziplines[id] = nil
end

local function startGrapple(startPos, endPos)
    if isZiplining then return end

    local now = GetGameTimer()

    if now - lastGrappleUse < config.grappleGun.cooldown then
        return notify(text.grappleCooldown)
    end

    if not lib.callback.await('tk_zipline:useGrappleAmmo', false) then return end

    lastGrappleUse = now

    local angle, distance = shared.getAngle(startPos, endPos)
    local travelDuration = shared.getTravelDuration(
        distance,
        angle,
        config.grappleGun.durationMultiplier,
        config.grappleGun.angleEffectMultiplier
    )

    RopeLoadTextures()

    local timeout = GetGameTimer() + 5000

    while not RopeAreTexturesLoaded() and GetGameTimer() < timeout do
        Wait(10)
    end

    local rope = AddRope(
        startPos.x, startPos.y, startPos.z + 1.0,
        endPos.x, endPos.y, endPos.z,
        distance, 4, distance,
        0.1, 1.0,
        false, false, true, 1.0, false, 0
    )

    if rope and rope ~= 0 then
        StartRopeWinding(rope)
    end

    ride(
        startPos,
        endPos + vec3(0.0, 0.0, 1.0),
        travelDuration,
        angle,
        GetHeadingFromVector_2d(endPos.x - startPos.x, endPos.y - startPos.y),
        function(step)
            if rope and DoesRopeExist(rope) then
                RopeForceLength(rope, distance * (1.0 - step))
            end
        end,
        function()
            if rope and DoesRopeExist(rope) then
                DeleteRope(rope)
                RopeUnloadTextures()
            end
        end
    )
end

---Anchor a gun zipline at the aimed point, dropping it to the surface below.
local function fireZiplineGun()
    local gun = config.ziplineGun
    local hit, hitEntity, hitCoords = lib.raycast.fromCamera(511, 4, gun.maxDist)

    if not hit then
        return notify(text.invalidPosition)
    end

    local down = vec3(0.0, 0.0, 1.0)
    local groundHit, _, groundCoords = lib.raycast.fromCoords(hitCoords, hitCoords - (down * 5.0), 1, hitEntity)
    local endCoords = groundHit and groundCoords or (hitCoords + down)
    local playerCoords = GetEntityCoords(cache.ped) - down
    local distance = #(endCoords - playerCoords)

    if distance > gun.maxDist or distance < gun.minDist then
        return notify(text.invalidPosition)
    end

    TriggerServerEvent('tk_zipline:saveZipline', 'zipline', {
        startCoords = playerCoords,
        endCoords = endCoords,
        ziplineType = 'gun'
    })
end

local function fireGrappleGun()
    local gun = config.grappleGun
    local hit, _, hitCoords = lib.raycast.fromCamera(511, 4, gun.maxDist)

    if not hit then
        return notify(text.invalidPosition)
    end

    local playerCoords = GetEntityCoords(cache.ped)
    local distance = #(hitCoords - playerCoords)

    if distance <= gun.minDist or distance >= gun.maxDist then
        return notify(text.invalidPosition)
    end

    startGrapple(playerCoords, hitCoords)
end

---Place a pole at each end of an item zipline, then hand it to the server.
local function placeZiplineFromItem(itemIndex)
    if isPlacing then return end

    local itemConfig = config.items[itemIndex]

    if not itemConfig then return end

    isPlacing = true

    local function finish()
        isPlacing = false
    end

    local placeProps = { { model = itemConfig.poleModel, offset = itemConfig.offset } }

    placer.start(placeProps, function(startCoords)
        if not startCoords then return finish() end

        if shared.isInDisabledArea(startCoords) then
            notify(text.disabledArea)
            return finish()
        end

        if not playProgress(config.anims.place, text.placing) then return finish() end

        placer.start(placeProps, function(endCoords)
            if not endCoords then return finish() end

            if shared.isInDisabledArea(endCoords) then
                notify(text.disabledArea)
                return finish()
            end

            local up = vec3(0.0, 0.0, 1.0)
            local blocked = lib.raycast.fromCoords(startCoords + up, endCoords + up, 1)

            if blocked then
                notify(text.pathBlocked)
                return finish()
            end

            local distance = #(endCoords - startCoords)

            if distance > itemConfig.maxDist or distance < itemConfig.minDist then
                notify(text.tooFar)
                return finish()
            end

            if not playProgress(config.anims.place, text.placing) then return finish() end

            finish()

            TriggerServerEvent('tk_zipline:saveZipline', itemIndex, {
                startCoords = startCoords,
                endCoords = endCoords,
                ziplineType = 'item'
            })
        end)
    end)
end

---Runs per-frame only while a zipline or grapple gun is equipped; idle players
---cost nothing, since ox_lib only fires this event when the weapon changes.
local gunThreadActive = false

local function startGunThread(isZiplineGun)
    if gunThreadActive then return end

    gunThreadActive = true

    CreateThread(function()
        local fireCount = #FIRE_CONTROLS

        while gunThreadActive do
            for i = 1, fireCount do
                DisableControlAction(0, FIRE_CONTROLS[i], true)
            end

            if IsControlPressed(0, 25) then
                for i = 1, fireCount do
                    if IsDisabledControlJustPressed(0, FIRE_CONTROLS[i]) then
                        if isZiplineGun then
                            fireZiplineGun()
                        else
                            fireGrappleGun()
                        end

                        break
                    end
                end
            end

            Wait(0)
        end
    end)
end

local function onWeaponChanged(weapon)
    local isZiplineGun = weapon == config.ziplineGun.weaponHash
    local isGrappleGun = weapon == config.grappleGun.weaponHash

    if isZiplineGun or isGrappleGun then
        startGunThread(isZiplineGun)
    else
        gunThreadActive = false
    end
end

AddEventHandler('ox_lib:cache:weapon', onWeaponChanged)

-- The event only fires on change, so pick up a gun already equipped at start.
onWeaponChanged(cache.weapon)

RegisterNetEvent('tk_zipline:createZipline', function(id, data)
    registerZipline(id, data)
end)

RegisterNetEvent('tk_zipline:removeZipline', function(id)
    unregisterZipline(id)
end)

RegisterNetEvent('tk_zipline:removeZiplines', function(ids)
    for i = 1, #ids do
        unregisterZipline(ids[i])
    end
end)

RegisterNetEvent('tk_zipline:placeZiplinePole', function(itemIndex)
    placeZiplineFromItem(itemIndex)
end)

CreateThread(function()
    for index = 1, #config.ziplines do
        local data = config.ziplines[index]

        registerZipline(('static_%d'):format(index), {
            startPos = data.startPos,
            endPos = data.endPos,
            configIndex = index,
            ziplineType = 'static'
        })
    end

    local saved = lib.callback.await('tk_zipline:getZiplines', false)

    for id, data in pairs(saved) do
        registerZipline(id, data)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    for _, zipline in pairs(ziplines) do
        despawnZipline(zipline)
    end
end)
