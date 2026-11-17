local config = localmodule 'config'
local infoui = exports.rhd_infoui

local Wait = Wait
local GetGameTimer = GetGameTimer
local PlayerPedId = PlayerPedId
local DoesEntityExist = DoesEntityExist
local DeleteEntity = DeleteEntity
local GetEntityCoords = GetEntityCoords
local GetPedBoneCoords = GetPedBoneCoords
local GetActivePlayers = GetActivePlayers
local GetPlayerPed = GetPlayerPed
local GetPlayerServerId = GetPlayerServerId
local GetPlayerFromServerId = GetPlayerFromServerId
local IsPedInAnyVehicle = IsPedInAnyVehicle
local IsControlJustPressed = IsControlJustPressed
local IsControlPressed = IsControlPressed
local DrawMarker = DrawMarker
local DoesRopeExist = DoesRopeExist
local RopeForceLength = RopeForceLength
local AttachEntitiesToRope = AttachEntitiesToRope
local SetEntityNoCollisionEntity = SetEntityNoCollisionEntity
local IsPedRagdoll = IsPedRagdoll
local SetPedToRagdoll = SetPedToRagdoll
local DisableAllControlActions = DisableAllControlActions
local EnableControlAction = EnableControlAction
local DisablePlayerFiring = DisablePlayerFiring
local NetworkGetEntityFromNetworkId = NetworkGetEntityFromNetworkId
local NetworkGetNetworkIdFromEntity = NetworkGetNetworkIdFromEntity
local min, max = math.min, math.max
local smatch = string.match
local tonumber, pairs, next = tonumber, pairs, next
local NetworkDoesNetworkIdExist = NetworkDoesNetworkIdExist
local IsEntityAPed = IsEntityAPed

local farm = SmAnimalFarm
local LASSO = config.lasso
local KEYS = LASSO.keys
local DETECT = LASSO.detectDistance
local DETECT_SQ = DETECT * DETECT
local RIDE_DETECT_SQ = (LASSO.rideDetectDistance or DETECT) ^ 2
local VEHICLE_SQ = LASSO.vehicleDistance * LASSO.vehicleDistance
local MARKER_Z = LASSO.markerHeight
local HAND = 28422
local SPINE = 24818
local INFO_ID = 'sm_animalfarm:lasso'
local THROW = { dict = 'anim@heists@narcotics@trash', clip = 'throw_ranged_side_d' }
local PROMPT_DRAG = '[kbd]E[/kbd] Lepas lasso\n[kbd]Panah Atas/Bawah[/kbd] Panjang tali'
local PROMPT_VEHICLE = '[kbd]E[/kbd] Lepas lasso\n[kbd]Y[/kbd] Ikat ke kendaraan\n[kbd]Panah Atas/Bawah[/kbd] Panjang tali'

local prop
local target
local targetPed
local rope
local vehicle
local length = LASSO.initialLength
local dragger
local victimRope
local victimVehicle
local victimLength = LASSO.initialLength
local prompt
local loopRunning = false

---@param text string|nil
local function setPrompt(text)
    if prompt == text then return end

    prompt = text

    if text then
        infoui:show({ id = INFO_ID, title = 'Lasso', icon = 'fa-solid fa-circle-nodes', description = text })
    else
        infoui:remove(INFO_ID)
    end
end

---@return integer
local function holdPed()
    return farm.riderPed and farm.riderPed() or PlayerPedId()
end

---@param owner integer
---@param host integer
---@return integer
local function remoteHold(owner, host)
    if not Player(owner).state.smFarmRide then return host end

    local pool = GetGamePool('CPed')

    for i = 1, #pool do
        local ped = pool[i]

        if ped ~= host and IsEntityAttachedToEntity(ped, host) and Entity(ped).state.smFarmFace then
            return ped
        end
    end

    return host
end

---@return boolean
local function loadTextures()
    if RopeAreTexturesLoaded() then return true end

    RopeLoadTextures()

    local started = GetGameTimer()

    while not RopeAreTexturesLoaded() do
        if GetGameTimer() - started > 5000 then return false end

        Wait(50)
    end

    return true
end

local function unloadTextures()
    if #GetAllRopes() == 0 then
        RopeUnloadTextures()
    end
end

---@param fromEntity integer
---@param toEntity integer
---@param ropeLength number
---@return integer|nil
local function makeRope(fromEntity, toEntity, ropeLength)
    if not loadTextures() then return end

    local a = GetPedBoneCoords(fromEntity, HAND, 0.0, 0.0, 0.0)
    local b = GetPedBoneCoords(toEntity, SPINE, 0.0, 0.0, 0.0)
    local handle = AddRope(
        a.x, a.y, a.z,
        0.0, 0.0, 0.0,
        ropeLength, LASSO.ropeType, LASSO.maxLength,
        0.1, true, false, true, 1.0, false
    )

    if not DoesRopeExist(handle) then return end

    ActivatePhysics(handle)
    AttachEntitiesToRope(handle, fromEntity, toEntity, a.x, a.y, a.z, b.x, b.y, b.z, ropeLength, false, false, nil, nil)

    return handle
end

local function removeProp()
    if prop and DoesEntityExist(prop) then
        DeleteEntity(prop)
    end

    prop = nil
end

local function clearDrag()
    if rope and DoesRopeExist(rope) then
        DeleteRope(rope)
    end

    if targetPed and DoesEntityExist(targetPed) then
        SetEntityNoCollisionEntity(PlayerPedId(), targetPed, false)
    end

    rope = nil
    target = nil
    targetPed = nil
    vehicle = nil
    length = LASSO.initialLength
    unloadTextures()
end

---@param coords vector3
---@return integer|nil
local function closestPlayer(coords)
    local players = GetActivePlayers()
    local best, bestDist = nil, farm.riding and RIDE_DETECT_SQ or DETECT_SQ
    local me = PlayerPedId()

    for i = 1, #players do
        local ped = GetPlayerPed(players[i])

        if ped ~= me and ped ~= 0 and not IsPedInAnyVehicle(ped, false) and not IsEntityAttachedToEntity(ped, me) then
            local pos = GetEntityCoords(ped)
            local dx, dy, dz = pos.x - coords.x, pos.y - coords.y, pos.z - coords.z
            local dist = dx * dx + dy * dy + dz * dz

            if dist < bestDist then
                best = players[i]
                bestDist = dist
            end
        end
    end

    return best
end

---@param ped integer
local function marker(ped)
    local pos = GetEntityCoords(ped)

    DrawMarker(
        2, pos.x, pos.y, pos.z + MARKER_Z,
        0.0, 0.0, 0.0,
        180.0, 0.0, 0.0,
        0.3, 0.3, 0.3,
        38, 187, 183, 160,
        false, true, 2, false, nil, nil, false
    )
end

local function throwAnim()
    local ped = holdPed()

    lib.playAnim(ped, THROW.dict, THROW.clip, 8.0, -8.0, -1, 0, 0.0, false, 0, false)
    Wait(600)
    StopAnimTask(ped, THROW.dict, THROW.clip, -4.0)
end

local function loop()
    if loopRunning then return end

    loopRunning = true

    CreateThread(function()
        local candidate
        local nearVehicle
        local nextScan = 0
        local lastLengthSent = 0
        local sentLength = length

        while prop or target do
            local now = GetGameTimer()
            local me = PlayerPedId()
            local pos = GetEntityCoords(me)

            if target then
                local player = GetPlayerFromServerId(target)

                targetPed = player ~= -1 and GetPlayerPed(player) or nil

                if targetPed and targetPed ~= 0 and rope and DoesRopeExist(rope) then
                    if IsControlPressed(0, KEYS.lengthUp) then
                        length = min(length + 0.1, LASSO.maxLength)
                    elseif IsControlPressed(0, KEYS.lengthDown) then
                        length = max(length - 0.1, LASSO.minLength)
                    end

                    if length ~= sentLength and now - lastLengthSent > 250 then
                        lastLengthSent = now
                        sentLength = length
                        TriggerTokenEvent('sm_animalfarm:lasso:length', length)
                    end

                    RopeForceLength(rope, length)

                    local anchor = vehicle and DoesEntityExist(vehicle) and vehicle or holdPed()
                    local a = anchor == vehicle and GetEntityCoords(anchor) or GetPedBoneCoords(anchor, HAND, 0.0, 0.0, 0.0)
                    local b = GetPedBoneCoords(targetPed, SPINE, 0.0, 0.0, 0.0)

                    AttachEntitiesToRope(rope, anchor, targetPed, a.x, a.y, a.z, b.x, b.y, b.z, length, false, false, nil, nil)
                    SetEntityNoCollisionEntity(me, targetPed, true)

                    if now >= nextScan then
                        nextScan = now + 250
                        nearVehicle = not cache.vehicle and lib.getClosestVehicle(pos, LASSO.vehicleDistance, false) or nil
                    end

                    if vehicle then
                        setPrompt('[kbd]Y[/kbd] Lepas dari kendaraan')

                        if IsControlJustPressed(0, KEYS.vehicle) then
                            vehicle = nil
                            TriggerTokenEvent('sm_animalfarm:lasso:vehicle', false)
                        end
                    elseif nearVehicle and not farm.riding then
                        setPrompt(PROMPT_VEHICLE)

                        if IsControlJustPressed(0, KEYS.vehicle) then
                            vehicle = nearVehicle
                            TriggerTokenEvent('sm_animalfarm:lasso:vehicle', NetworkGetNetworkIdFromEntity(nearVehicle))
                        end
                    else
                        setPrompt(PROMPT_DRAG)
                    end

                    if not vehicle and IsControlJustPressed(0, KEYS.attach) then
                        TriggerTokenEvent('sm_animalfarm:lasso:stop')
                    end
                end
            elseif prop then
                if now >= nextScan then
                    nextScan = now + 250
                    candidate = closestPlayer(pos)
                end

                local ped = candidate and GetPlayerPed(candidate) or 0

                if ped ~= 0 then
                    marker(ped)
                    setPrompt('[kbd]E[/kbd] Lempar lasso')

                    if IsControlJustPressed(0, KEYS.attach) then
                        throwAnim()
                        TriggerTokenEvent('sm_animalfarm:lasso:start', GetPlayerServerId(candidate))
                        nextScan = GetGameTimer() + 1000
                        candidate = nil
                    end
                else
                    setPrompt(nil)
                end
            end

            Wait(0)
        end

        setPrompt(nil)
        loopRunning = false
    end)
end

local function createProp()
    if not lib.requestModel(LASSO.propModel, 5000) then
        return lib.notify({ title = 'Lasso', description = 'Prop lasso gagal dimuat.', type = 'error' })
    end

    local ped = holdPed()
    local pos = GetEntityCoords(ped)

    prop = CreateObject(LASSO.propModel, pos.x, pos.y, pos.z, true, true, false)
    SetModelAsNoLongerNeeded(LASSO.propModel)
    SetEntityCollision(prop, false, false)
    AttachEntityToEntity(
        prop, ped, GetPedBoneIndex(ped, HAND),
        0.25, -0.05, -0.05,
        190.0, 10.0, 0.0,
        true, true, false, true, 1, true
    )
    loop()
end

RegisterNetEvent('sm_animalfarm:lasso:use', function()
    if source == '' then return end
    if dragger or farm.inPen or farm.boarded then return end

    if target then
        return TriggerTokenEvent('sm_animalfarm:lasso:stop')
    end

    if prop then
        return removeProp()
    end

    createProp()
end)

RegisterNetEvent('sm_animalfarm:lasso:startDragging', function(targetId)
    if source == '' then return end

    local player = GetPlayerFromServerId(targetId)
    local ped = player ~= -1 and GetPlayerPed(player) or 0

    if ped == 0 then
        return TriggerTokenEvent('sm_animalfarm:lasso:stop')
    end

    length = LASSO.initialLength
    rope = makeRope(holdPed(), ped, length)

    if not rope then
        return TriggerTokenEvent('sm_animalfarm:lasso:stop')
    end

    target = targetId
    targetPed = ped
    loop()
end)

RegisterNetEvent('sm_animalfarm:lasso:stopDragging', function()
    if source == '' then return end

    clearDrag()
end)

local function clearVictim()
    if victimRope and DoesRopeExist(victimRope) then
        DeleteRope(victimRope)
    end

    victimRope = nil
    victimVehicle = nil
    victimLength = LASSO.initialLength
    unloadTextures()
end

RegisterNetEvent('sm_animalfarm:lasso:dragged', function(draggerId)
    if source == '' or dragger then return end

    dragger = draggerId
    victimLength = LASSO.initialLength

    CreateThread(function()
        local me = PlayerPedId()
        local hold
        local nextHold = 0

        SetEntityInvincible(me, true)

        while dragger do
            local now = GetGameTimer()
            local player = GetPlayerFromServerId(dragger)
            local host = player ~= -1 and GetPlayerPed(player) or 0

            if now >= nextHold or (hold and not DoesEntityExist(hold)) then
                nextHold = now + 2000
                hold = host ~= 0 and remoteHold(dragger, host) or nil
            end

            if not IsPedRagdoll(me) then
                SetPedToRagdoll(me, -1, -1, 0, true, true, false)
            end

            DisablePlayerFiring(cache.playerId, true)
            DisableAllControlActions(0)
            EnableControlAction(0, 1, true)
            EnableControlAction(0, 2, true)
            EnableControlAction(0, 249, true)

            local from = victimVehicle and DoesEntityExist(victimVehicle) and victimVehicle or hold

            if from and DoesEntityExist(from) then
                if not victimRope then
                    victimRope = makeRope(from, me, victimLength)
                end

                if victimRope and DoesRopeExist(victimRope) then
                    local a = from == victimVehicle and GetEntityCoords(from) or GetPedBoneCoords(from, HAND, 0.0, 0.0, 0.0)
                    local b = GetPedBoneCoords(me, SPINE, 0.0, 0.0, 0.0)

                    AttachEntitiesToRope(victimRope, from, me, a.x, a.y, a.z, b.x, b.y, b.z, victimLength, false, false, nil, nil)
                    RopeForceLength(victimRope, victimLength)
                end
            end

            Wait(0)
        end

        clearVictim()
        SetEntityInvincible(me, false)
        DisablePlayerFiring(cache.playerId, false)

        if not IsEntityDead(me) and not IsPedInAnyVehicle(me, false) then
            ClearPedTasksImmediately(me)
        end
    end)
end)

AddEventHandler('sm_animalfarm:lasso:reset', function()
    if target then
        TriggerTokenEvent('sm_animalfarm:lasso:stop')
    end

    removeProp()
end)

RegisterNetEvent('sm_animalfarm:lasso:stopDragged', function()
    if source == '' then return end

    dragger = nil
end)

RegisterNetEvent('sm_animalfarm:lasso:length', function(value)
    if source == '' or not dragger or type(value) ~= 'number' then return end

    victimLength = value
end)

RegisterNetEvent('sm_animalfarm:lasso:vehicle', function(netId)
    if source == '' or not dragger then return end

    if not netId then
        victimVehicle = nil
        return
    end

    local entity = NetworkGetEntityFromNetworkId(netId)

    victimVehicle = entity ~= 0 and entity or nil
end)

local VIEW_SQ = LASSO.leash.renderDistance * LASSO.leash.renderDistance

---@class FarmLassoView
---@field target integer
---@field vehicle integer|nil
---@field rope integer|nil
---@field from integer
---@field to integer
---@field hold integer|nil
---@field nextHold integer

---@type table<integer, FarmLassoView>
local views = {}
local viewRunning = false

---@param view FarmLassoView
local function dropView(view)
    if view.rope and DoesRopeExist(view.rope) then
        DeleteRope(view.rope)
    end

    view.rope = nil
    unloadTextures()
end

local function watchViews()
    if viewRunning then return end

    viewRunning = true

    CreateThread(function()
        while next(views) do
            local me = GetEntityCoords(PlayerPedId())
            local now = GetGameTimer()

            for owner, view in pairs(views) do
                local ownerPlayer = GetPlayerFromServerId(owner)
                local targetPlayer = GetPlayerFromServerId(view.target)
                local host = ownerPlayer ~= -1 and GetPlayerPed(ownerPlayer) or 0
                local victim = targetPlayer ~= -1 and GetPlayerPed(targetPlayer) or 0
                local from = 0
                local inRange = false

                if host ~= 0 and victim ~= 0 then
                    local pos = GetEntityCoords(victim)
                    local dx, dy = pos.x - me.x, pos.y - me.y

                    inRange = dx * dx + dy * dy <= VIEW_SQ
                end

                if inRange then
                    if view.vehicle then
                        local entity = NetworkDoesNetworkIdExist(view.vehicle) and NetworkGetEntityFromNetworkId(view.vehicle) or 0

                        from = entity ~= 0 and DoesEntityExist(entity) and entity or 0
                    else
                        if now >= view.nextHold or not (view.hold and DoesEntityExist(view.hold)) then
                            view.nextHold = now + 2000
                            view.hold = remoteHold(owner, host)
                        end

                        from = view.hold or host
                    end
                end

                if from == 0 or not DoesEntityExist(from) then
                    dropView(view)
                else
                    local a = IsEntityAPed(from) and GetPedBoneCoords(from, HAND, 0.0, 0.0, 0.0) or GetEntityCoords(from)
                    local b = GetPedBoneCoords(victim, SPINE, 0.0, 0.0, 0.0)
                    local span = min(max(#(a - b), LASSO.minLength), LASSO.maxLength)

                    if not view.rope or view.from ~= from or view.to ~= victim or not DoesRopeExist(view.rope) then
                        dropView(view)
                        view.rope = makeRope(from, victim, span)
                        view.from = from
                        view.to = victim
                    end

                    if view.rope then
                        AttachEntitiesToRope(view.rope, from, victim, a.x, a.y, a.z, b.x, b.y, b.z, span, false, false, nil, nil)
                        RopeForceLength(view.rope, span)
                    end
                end
            end

            Wait(500)
        end

        viewRunning = false
    end)
end

AddStateBagChangeHandler('smFarmLasso', nil, function(bagName, _, value)
    local owner = tonumber(smatch(bagName, '^player:(%d+)$'))

    if not owner then return end

    local view = views[owner]

    if view then
        dropView(view)
        views[owner] = nil
    end

    if type(value) ~= 'table' then return end

    local targetId = tonumber(value.target)
    local mine = cache.serverId

    if not targetId or owner == mine or targetId == mine then return end

    views[owner] = { target = targetId, vehicle = tonumber(value.vehicle), from = 0, to = 0, nextHold = 0 }
    watchViews()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    for owner, view in pairs(views) do
        dropView(view)
        views[owner] = nil
    end

    clearDrag()
    removeProp()

    if dragger then
        dragger = nil
        clearVictim()
        SetEntityInvincible(PlayerPedId(), false)
    end

    infoui:remove(INFO_ID)
end)
