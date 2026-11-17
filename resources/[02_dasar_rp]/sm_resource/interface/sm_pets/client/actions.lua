local Config = SmPets.Config
local Catalog = SmPets.Catalog
local followCfg = Config.Follow
local uiActions = SmPets.uiActions
local wardrobe = Catalog.wardrobe

local DoesEntityExist = DoesEntityExist
local DeleteEntity = DeleteEntity
local GetEntityCoords = GetEntityCoords
local GetEntityHeading = GetEntityHeading
local SetEntityHeading = SetEntityHeading
local SetEntityCoords = SetEntityCoords
local GetOffsetFromEntityInWorldCoords = GetOffsetFromEntityInWorldCoords
local GetOffsetFromEntityGivenWorldCoords = GetOffsetFromEntityGivenWorldCoords
local FreezeEntityPosition = FreezeEntityPosition
local ClearPedTasks = ClearPedTasks
local ClearPedTasksImmediately = ClearPedTasksImmediately
local TaskFollowToOffsetOfEntity = TaskFollowToOffsetOfEntity
local TaskGoToCoordAnyMeans = TaskGoToCoordAnyMeans
local TaskAchieveHeading = TaskAchieveHeading
local SetPedMoveRateOverride = SetPedMoveRateOverride
local IsPedSprinting = IsPedSprinting
local IsPedRunning = IsPedRunning
local IsPedInAnyVehicle = IsPedInAnyVehicle
local IsEntityPlayingAnim = IsEntityPlayingAnim
local TaskPlayAnim = TaskPlayAnim
local CreateObject = CreateObject
local AttachEntityToEntity = AttachEntityToEntity
local DetachEntity = DetachEntity
local GetPedBoneIndex = GetPedBoneIndex
local GetEntityBoneIndexByName = GetEntityBoneIndexByName
local GetWorldPositionOfEntityBone = GetWorldPositionOfEntityBone
local SetEntityCollision = SetEntityCollision
local SetEntityVelocity = SetEntityVelocity
local GetEntitySpeed = GetEntitySpeed
local ActivatePhysics = ActivatePhysics
local GetGameplayCamRot = GetGameplayCamRot
local IsVehicleSeatFree = IsVehicleSeatFree
local SetVehicleDoorOpen = SetVehicleDoorOpen
local SetVehicleDoorShut = SetVehicleDoorShut
local SetPedCanRagdoll = SetPedCanRagdoll
local IsModelInCdimage = IsModelInCdimage
local PlayAnimalVocalization = PlayAnimalVocalization
local DisableControlAction = DisableControlAction
local IsDisabledControlJustPressed = IsDisabledControlJustPressed
local SetCurrentPedWeapon = SetCurrentPedWeapon
local AddRope = AddRope
local RopeLoadTextures = RopeLoadTextures
local AttachEntitiesToRope = AttachEntitiesToRope
local StartRopeWinding = StartRopeWinding
local DeleteRope = DeleteRope
local GetGameTimer = GetGameTimer
local GetEntityFromStateBagName = GetEntityFromStateBagName
local GetResourceState = GetResourceState
local smatch = string.match
local type = type
local GetAnimInitialOffsetPosition = GetAnimInitialOffsetPosition
local GetAnimInitialOffsetRotation = GetAnimInitialOffsetRotation
local Wait = Wait
local CreateThread = CreateThread
local joaat = joaat
local GetScriptTaskStatus = GetScriptTaskStatus
local tonumber = tonumber
local tostring = tostring
local mrandom = math.random
local mrad = math.rad
local msin = math.sin
local mcos = math.cos
local mmax = math.max

local UNARMED = `WEAPON_UNARMED`
local THROW_ANIM = { 'anim@arena@celeb@flat@paired@no_props@', 'baseball_a_player_b' }
local WHISTLE_ANIM = { 'rcmnigel1c', 'hailing_whistle_waive_a' }
local HAND_BONE = 57005
local SPINE_BONE = 24818
local FETCH_TIMEOUT = 15000
local CUDDLE_MIN_MS = 4000
local PAIR_DICT = 'creatures@rottweiler@tricks@'
local PAIR_PLAYER = 'petting_franklin'
local PAIR_PET = 'petting_chop'

local blockWeapons = false
local accessoryHandlers = {}
SmPets.accessoryHandlers = accessoryHandlers

lib.onCache('weapon', function(weapon)
    if blockWeapons and weapon and weapon ~= UNARMED then
        SetCurrentPedWeapon(cache.ped, UNARMED, true)
    end
end)

---@param state boolean
local function setWeaponBlock(state)
    blockWeapons = state
    if state and cache.weapon and cache.weapon ~= UNARMED then
        SetCurrentPedWeapon(cache.ped, UNARMED, true)
    end
end

local soundSeq = 0
local nextSoundAt = 0

---@param kind string
function SmPets.vocal(kind)
    local pet = SmPets.pet
    if not pet or not DoesEntityExist(pet.ped) then return end
    if pet.sound then
        local now = GetGameTimer()
        local forced = kind == 'attack' and pet.attackSound or kind == 'follow' and pet.followSound and pet.sound
        if not forced and now < nextSoundAt then return end
        nextSoundAt = now + (pet.soundCooldownMs or Config.Sound.cooldownMs)
        local name = forced or pet.sound
        if type(name) == 'table' then name = name[mrandom(1, #name)] end
        soundSeq = soundSeq + 1
        Entity(pet.ped).state:set('smPetSound', ('%s:%d'):format(name, soundSeq), true)
        return
    end
    if pet.mute then return end
    local voice = pet.anims.voice[kind == 'attack' and 'growl' or kind == 'follow' and 'bark' or kind]
    if voice then PlayAnimalVocalization(pet.ped, 3, voice) end
end

AddStateBagChangeHandler('smPetSound', nil, function(bagName, _, value)
    if type(value) ~= 'string' or GetResourceState('xsound') ~= 'started' then return end
    local name = smatch(value, '^([%w_]+):')
    if not name then return end
    local entity = GetEntityFromStateBagName(bagName)
    if entity == 0 or not DoesEntityExist(entity) then return end
    local cfg = Config.Sound
    local coords = GetEntityCoords(entity)
    if #(GetEntityCoords(cache.ped) - coords) > cfg.distance then return end
    local id = ('sm_pets_%s'):format(smatch(bagName, '(%d+)$') or name)
    exports.xsound:PlayUrlPos(id, ('nui://sm_resource/interface/sm_pets/web/build/sounds/%s.ogg'):format(name), cfg.volumes[name] or cfg.volume, coords, false)
    exports.xsound:Distance(id, cfg.distance)
end)

---@param model string
---@param coords vector3
---@param heading number
---@return integer
local function spawnProp(model, coords, heading)
    local hash = SmPets.loadModel(model)
    if not hash then return 0 end
    local object = CreateObject(hash, coords.x, coords.y, coords.z, true, true, false)
    SetEntityHeading(object, heading or 0.0)
    SetModelAsNoLongerNeeded(hash)
    return object
end

---@param entity integer
local function deleteEntity(entity)
    if entity and entity ~= 0 and DoesEntityExist(entity) then
        DetachEntity(entity, true, true)
        DeleteEntity(entity)
    end
end

---@param name string
---@param onCancel fun(silent: boolean)
---@return table pet
local function begin(name, onCancel)
    local pet = SmPets.pet
    local wasFollowing = pet.state == 'follow' or pet.state == 'leash'
    if pet.cancel then
        local cancel = pet.cancel
        pet.cancel = nil
        cancel(true)
    end
    pet.resumeFollow = wasFollowing
    SmPets.setAction(name, onCancel)
    return pet
end

local function finish()
    local pet = SmPets.pet
    if not pet then return end
    pet.cancel = nil
    if pet.state == 'dead' then return end
    pet.state = 'idle'
    local resume = pet.resumeFollow
    pet.resumeFollow = false
    if resume then SmPets.follow(true) end
end

local FOLLOW_TASK = joaat('SCRIPT_TASK_FOLLOW_TO_OFFSET_OF_ENTITY')
local HUGE = math.huge

---@param pet table
---@param target integer
---@param speed? number
local function followTask(pet, target, speed)
    TaskFollowToOffsetOfEntity(pet.ped, target, 0.6, -0.6, 0.0, speed or 2.0, -1, 1.2, true)
end

---@param pet table
local function followLoop(pet)
    CreateThread(function()
        local interval = followCfg.intervalMs
        local boost2 = followCfg.boostDistance * followCfg.boostDistance
        local teleport2 = followCfg.teleportDistance * followCfg.teleportDistance
        local stuckMs = followCfg.stuckMs
        local stuck2 = boost2 * 4.0
        local speed = 0.0
        local bestDist2, bestAt = HUGE, GetGameTimer()
        while SmPets.pet == pet and (pet.state == 'follow' or pet.state == 'leash') do
            local ped, owner = pet.ped, cache.ped
            if not DoesEntityExist(ped) then break end
            local a, b = GetEntityCoords(ped), GetEntityCoords(owner)
            local dx, dy, dz = a.x - b.x, a.y - b.y, a.z - b.z
            local dist2 = dx * dx + dy * dy + dz * dz
            local far = dist2 > boost2
            local rate = followCfg.baseRate
            if far then
                rate = IsPedSprinting(owner) and followCfg.sprintRate or IsPedRunning(owner) and followCfg.runRate or followCfg.baseRate
            end
            SetPedMoveRateOverride(ped, rate)

            local now = GetGameTimer()
            if not far then
                bestDist2, bestAt = HUGE, now
            elseif dist2 < bestDist2 - 1.0 then
                bestDist2, bestAt = dist2, now
            end
            local inVehicle = IsPedInAnyVehicle(owner, false)
            if not inVehicle and (dist2 > teleport2 or (dist2 > stuck2 and now - bestAt > stuckMs)) then
                local spot = GetOffsetFromEntityInWorldCoords(owner, 0.0, -2.0, 0.0)
                SetEntityCoords(ped, spot.x, spot.y, SmPets.groundZ(spot), false, false, false, false)
                SetEntityHeading(ped, GetEntityHeading(owner))
                speed = 0.0
                bestDist2, bestAt = HUGE, now
            end
            if far and not inVehicle then
                local chase = GetOffsetFromEntityInWorldCoords(owner, 0.0, -1.5, 0.0)
                SmPets.goTo(ped, chase, 3.0)
                speed = 3.0
            elseif speed ~= 2.0 or GetScriptTaskStatus(ped, FOLLOW_TASK) == 7 then
                followTask(pet, owner, 2.0)
                speed = 2.0
            end

            if pet.state == 'leash' and IsPedInAnyVehicle(owner, false) then
                SmPets.cancelAction()
                break
            end
            Wait(interval)
        end
        if DoesEntityExist(pet.ped) then SetPedMoveRateOverride(pet.ped, 1.0) end
    end)
end

---@param silent? boolean
function SmPets.follow(silent)
    local pet = SmPets.pet
    if not pet then return end
    if not silent and not SmPets.canCommand() then return end
    if pet.state == 'dead' then return end
    if pet.cancel then
        local cancel = pet.cancel
        pet.cancel = nil
        cancel(true)
    end
    if not lib.callback.await('sm_pets:follow', false, true) then
        pet.state = 'idle'
        return
    end
    pet.state = 'follow'
    pet.cancel = function()
        lib.callback('sm_pets:follow', false, function() end, false)
        if DoesEntityExist(pet.ped) then
            ClearPedTasks(pet.ped)
            SetPedMoveRateOverride(pet.ped, 1.0)
        end
    end
    followTask(pet, cache.ped)
    followLoop(pet)
    if not silent then SmPets.vocal('follow') end
end

function SmPets.stay()
    local pet = SmPets.pet
    if not pet or pet.state ~= 'follow' then return end
    SmPets.cancelAction()
end

function SmPets.call()
    local pet = SmPets.pet
    if not pet or pet.state == 'dead' then return end
    if not SmPets.isNearPet(Config.CallRange) then return SmPets.notify('Pet terlalu jauh untuk dipanggil.', 'error') end
    SmPets.playAnim(cache.ped, WHISTLE_ANIM, 48, 1500)
    if pet.state ~= 'follow' then SmPets.follow(true) end
end

---@param player integer
---@param ped integer
---@return vector3 coords
---@return number heading
local function pettingSpot(player, ped)
    local origin = GetEntityCoords(player)
    local heading = GetEntityHeading(player)
    local petZ = GetEntityCoords(ped).z
    local fallback = GetOffsetFromEntityInWorldCoords(player, 0.0, 0.8, 0.0)
    if not SmPets.loadDict(PAIR_DICT) then
        return vec3(fallback.x, fallback.y, petZ), heading + 180.0
    end
    local baseRot = GetAnimInitialOffsetRotation(PAIR_DICT, PAIR_PLAYER, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 2)
    local sceneHeading = heading - baseRot.z
    local playerStart = GetAnimInitialOffsetPosition(PAIR_DICT, PAIR_PLAYER, 0.0, 0.0, 0.0, 0.0, 0.0, sceneHeading, 0.0, 2)
    local petStart = GetAnimInitialOffsetPosition(PAIR_DICT, PAIR_PET, 0.0, 0.0, 0.0, 0.0, 0.0, sceneHeading, 0.0, 2)
    local petRot = GetAnimInitialOffsetRotation(PAIR_DICT, PAIR_PET, 0.0, 0.0, 0.0, 0.0, 0.0, sceneHeading, 0.0, 2)
    local dx, dy = petStart.x - playerStart.x, petStart.y - playerStart.y
    if dx * dx + dy * dy > 4.0 then
        return vec3(fallback.x, fallback.y, petZ), heading + 180.0
    end
    return vec3(origin.x + dx, origin.y + dy, petZ), petRot.z
end

---@param player integer
---@param ped integer
---@param isCancelled fun(): boolean
---@return boolean
local function moveToPettingSpot(player, ped, isCancelled)
    local approach = GetOffsetFromEntityInWorldCoords(player, 0.0, 1.2, 0.0)
    TaskGoToCoordAnyMeans(ped, approach.x, approach.y, approach.z, 2.0, 0, false, 786603, 0.0)
    SmPets.waitArrive(ped, approach, 0.8, 4000, isCancelled)
    if isCancelled() or not DoesEntityExist(ped) then return false end
    ClearPedTasks(ped)
    local coords, heading = pettingSpot(player, ped)
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
    SetEntityHeading(ped, heading)
    Wait(100)
    return not isCancelled()
end

function SmPets.cuddle()
    if not SmPets.canCommand() then return end
    if not lib.callback.await('sm_pets:cuddle', false) then return end
    local cancelled = false
    local pet = begin('busy', function()
        cancelled = true
        FreezeEntityPosition(cache.ped, false)
        ClearPedTasks(cache.ped)
        local p = SmPets.pet
        if p and DoesEntityExist(p.ped) then ClearPedTasks(p.ped) end
    end)
    local ped, player = pet.ped, cache.ped
    local anims = pet.anims

    if not moveToPettingSpot(player, ped, function() return cancelled end) then return end

    FreezeEntityPosition(player, true)
    local playerMs = SmPets.playAnim(player, anims.cuddlePlayer, 1)
    local petMs = SmPets.playAnim(ped, anims.cuddlePet, 1)
    Wait(mmax(playerMs, petMs, CUDDLE_MIN_MS))
    if cancelled then return end

    FreezeEntityPosition(player, false)
    ClearPedTasks(player)
    if DoesEntityExist(ped) then ClearPedTasks(ped) end
    SmPets.vocal('bark')
    finish()
end

function SmPets.sit()
    if not SmPets.canCommand() then return end
    local pet = begin('sit', function() end)
    SmPets.playAnim(pet.ped, pet.anims.sit, 1)
end

---@param pet table
---@param suffix string
---@return string
local function bowlModel(pet, suffix)
    local key = pet.bowl
    local item = key and wardrobe[key]
    local base = item and item.prop or 'silverbowl'
    local model = base .. suffix
    if not IsModelInCdimage(joaat(model)) then model = 'silverbowl' .. suffix end
    return model
end

---@param kind string
local function playEat(kind)
    local pet = SmPets.pet
    if not pet or pet.state == 'dead' or not DoesEntityExist(pet.ped) then return end
    local cancelled, bowl = false, 0
    pet = begin('busy', function()
        cancelled = true
        deleteEntity(bowl)
        if DoesEntityExist(pet.ped) then FreezeEntityPosition(pet.ped, false) end
    end)
    local ped, player, anims = pet.ped, cache.ped, pet.anims

    SmPets.playAnim(player, anims.pickup, 0, 1500)
    Wait(1200)
    if cancelled then return end

    local spot = GetOffsetFromEntityInWorldCoords(player, 0.0, 0.9, 0.0)
    bowl = spawnProp(bowlModel(pet, kind == 'water' and 'water' or 'filled'), vec3(spot.x, spot.y, SmPets.groundZ(spot)), GetEntityHeading(player))
    if bowl == 0 then return finish() end
    FreezeEntityPosition(bowl, true)

    local front = GetOffsetFromEntityInWorldCoords(bowl, 0.0, 0.7, 0.0)
    TaskGoToCoordAnyMeans(ped, front.x, front.y, front.z, 2.0, 0, false, 786603, 0.0)
    SmPets.waitArrive(ped, front, 0.6, 8000, function() return cancelled end)
    if cancelled then return end

    local eatHeading = GetEntityHeading(bowl) + (anims.eatHeading or 180.0)
    TaskAchieveHeading(ped, eatHeading, 1500)
    Wait(900)
    if cancelled then return end
    SetEntityHeading(ped, eatHeading)

    SmPets.playAnim(ped, anims.eat, 1)
    FreezeEntityPosition(ped, true)
    local stopAt = GetGameTimer() + 4500
    while GetGameTimer() < stopAt and not cancelled do
        Wait(250)
    end
    if cancelled then return end

    FreezeEntityPosition(ped, false)
    ClearPedTasks(ped)
    deleteEntity(bowl)
    finish()
end

local function playTreat()
    local pet = SmPets.pet
    if not pet or pet.state == 'dead' or not DoesEntityExist(pet.ped) then return end
    local cancelled = false
    pet = begin('busy', function()
        cancelled = true
        ClearPedTasks(cache.ped)
    end)
    local ped, player, anims = pet.ped, cache.ped, pet.anims
    if not moveToPettingSpot(player, ped, function() return cancelled end) then return end
    local beg = SmPets.playAnim(ped, anims.beg, 1)
    Wait(beg > 0 and beg or 1500)
    if cancelled then return end
    local petting = SmPets.playAnim(player, anims.petting, 0)
    Wait(petting > 0 and petting or 2000)
    if cancelled then return end
    ClearPedTasks(player)
    SmPets.vocal('bark')
    finish()
end

lib.callback.register('sm_pets:client:medkit', function()
    local pet = SmPets.pet
    if not pet or not DoesEntityExist(pet.ped) or IsPedInAnyVehicle(cache.ped, false) then return false end
    return SmPets.injectProgress('Mengobati pet...', Config.Inject.medkitDuration, pet.ped)
end)

RegisterNetEvent('sm_pets:client:consume', function(kind)
    if kind == 'food' or kind == 'water' then
        playEat(kind)
    elseif kind == 'treat' then
        playTreat()
    end
end)

---@param pet table
---@param item table
---@param bed integer
local function settleInBed(pet, item, bed)
    local ped = pet.ped
    local offset = item.offset
    local spot = GetOffsetFromEntityInWorldCoords(bed, offset.x, offset.y, offset.z)
    SetEntityCoords(ped, spot.x, spot.y, spot.z + Config.BedLift, false, false, false, false)
    SetEntityHeading(ped, GetEntityHeading(bed) + item.heading)
    SmPets.playAnim(ped, pet.anims.sleep, 1)
    FreezeEntityPosition(ped, true)
end

accessoryHandlers.bed = function(item)
    local cancelled, bed = false, 0
    local pet = begin('busy', function(silent)
        cancelled = true
        local p = SmPets.pet
        lib.callback('sm_pets:bedState', false, function() end, false)
        if p and DoesEntityExist(p.ped) then
            FreezeEntityPosition(p.ped, false)
            if not silent and p.state == 'bed' then
                SmPets.playAnim(p.ped, p.anims.sleepExit, 0)
                Wait(1500)
            end
        end
        deleteEntity(bed)
    end)
    local ped, player = pet.ped, cache.ped

    SmPets.playAnim(player, pet.anims.pickup, 0, 1500)
    Wait(1200)
    if cancelled then return end

    local spot = GetOffsetFromEntityInWorldCoords(player, 0.0, 1.2, 0.0)
    bed = spawnProp(item.prop, vec3(spot.x, spot.y, SmPets.groundZ(spot)), GetEntityHeading(player))
    if bed == 0 then return SmPets.cancelAction(true) end
    FreezeEntityPosition(bed, true)

    TaskGoToCoordAnyMeans(ped, spot.x, spot.y, spot.z, 2.0, 0, false, 786603, 0.0)
    SmPets.waitArrive(ped, spot, 1.0, 8000, function() return cancelled end)
    if cancelled then return end

    settleInBed(pet, item, bed)
    pet.state = 'bed'
end

accessoryHandlers.leash = function(item)
    local rope, prop = nil, 0
    local pet = begin('leash', function()
        if rope then
            DeleteRope(rope)
            rope = nil
        end
        deleteEntity(prop)
        lib.callback('sm_pets:follow', false, function() end, false)
        local p = SmPets.pet
        if p and DoesEntityExist(p.ped) then ClearPedTasks(p.ped) end
    end)
    if not lib.callback.await('sm_pets:follow', false, true) then return SmPets.cancelAction(true) end

    local ped, player = pet.ped, cache.ped
    local here = GetEntityCoords(player)
    prop = spawnProp(item.prop, vec3(here.x, here.y, here.z - 5.0), 0.0)
    if prop ~= 0 then
        SetEntityCollision(prop, false, false)
        AttachEntityToEntity(prop, player, GetPedBoneIndex(player, HAND_BONE), item.offset.x, item.offset.y, item.offset.z, item.rot.x, item.rot.y, item.rot.z, true, true, false, true, 1, true)
    end

    RopeLoadTextures()
    local petPos = GetEntityCoords(ped)
    rope = AddRope(petPos.x, petPos.y, petPos.z, 0.0, 0.0, 0.0, 1.0, 5, 1.0, 1.0, 1.0, false, false, false, false)
    AttachEntitiesToRope(rope, player, ped, 0.0, 0.0, -0.1, 0.0, 0.15, -0.1, 6.0, false, false, 'SKEL_R_Hand', pet.speciesCfg.neckBone)
    StartRopeWinding(rope)

    followTask(pet, player)
    followLoop(pet)
end

accessoryHandlers.fetch = function()
    local active, ball, carried = true, 0, 0
    local pet = begin('fetch', function()
        active = false
        deleteEntity(ball)
        deleteEntity(carried)
        setWeaponBlock(false)
        local p = SmPets.pet
        if p and DoesEntityExist(p.ped) then ClearPedTasks(p.ped) end
    end)
    setWeaponBlock(true)

    local function giveBall()
        deleteEntity(ball)
        local player = cache.ped
        local here = GetEntityCoords(player)
        ball = spawnProp('w_am_baseball', vec3(here.x, here.y, here.z + 1.0), 0.0)
        if ball ~= 0 then
            AttachEntityToEntity(ball, player, GetPedBoneIndex(player, HAND_BONE), 0.12, 0.02, -0.03, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
        end
    end
    giveBall()

    infoUI.show({ id = 'sm_pets:fetch', title = 'Lempar Bola', icon = 'fas fa-baseball', description = ('Klik kiri untuk melempar, tekan %s untuk berhenti.'):format(Config.CancelKey) })

    CreateThread(function()
        local busyThrow = false
        while active and SmPets.pet == pet do
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 140, true)
            DisableControlAction(0, 141, true)
            DisableControlAction(0, 142, true)
            if not busyThrow and ball ~= 0 and IsDisabledControlJustPressed(0, 24) then
                busyThrow = true
                CreateThread(function()
                    if not lib.callback.await('sm_pets:fetchThrow', false) then
                        busyThrow = false
                        return
                    end
                    local player = cache.ped
                    SmPets.playAnim(player, THROW_ANIM, 48, 1400)
                    Wait(650)
                    if not active then return end
                    DetachEntity(ball, true, true)
                    ActivatePhysics(ball)
                    local rot = GetGameplayCamRot(2)
                    local pitch, yaw = mrad(rot.x), mrad(rot.z)
                    local cosPitch = mcos(pitch)
                    SetEntityVelocity(ball, -msin(yaw) * cosPitch * 16.0, mcos(yaw) * cosPitch * 16.0, msin(pitch) * 16.0 + 4.0)

                    local deadline = GetGameTimer() + 4000
                    Wait(400)
                    while active and GetGameTimer() < deadline and DoesEntityExist(ball) and GetEntitySpeed(ball) > 0.3 do Wait(100) end
                    if not active then return end

                    local ped = pet.ped
                    local landing = GetEntityCoords(ball)
                    SmPets.goTo(ped, landing, 3.0)
                    local reached = SmPets.waitArrive(ped, landing, 1.2, FETCH_TIMEOUT, function() return not active end)
                    if not active then return end

                    deleteEntity(ball)
                    ball = 0
                    if reached then
                        SmPets.playAnim(ped, pet.anims.fetchPickup, 0, 1200)
                        Wait(900)
                        local here = GetEntityCoords(ped)
                        carried = spawnProp('w_am_baseball', here, 0.0)
                        if carried ~= 0 then
                            local offset = Config.BallOffset
                            AttachEntityToEntity(carried, ped, GetPedBoneIndex(ped, Config.BallBone), offset.x, offset.y, offset.z, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
                        end
                        local back = GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, 1.4, 0.0)
                        SmPets.goTo(ped, back, 3.0)
                        SmPets.waitArrive(ped, back, 1.0, FETCH_TIMEOUT, function() return not active end)
                        if not active then return end
                        SmPets.playAnim(ped, pet.anims.fetchDrop, 0, 1200)
                        Wait(900)
                        deleteEntity(carried)
                        carried = 0
                        lib.callback('sm_pets:fetchReturn', false, function() end)
                        SmPets.vocal('bark')
                    end
                    ClearPedTasks(ped)
                    giveBall()
                    busyThrow = false
                end)
            end
            Wait(0)
        end
        infoUI.remove('sm_pets:fetch')
    end)
end

---@param pet table
---@param item table
local function bagOffsets(pet, item)
    if item.bag == 'cat' then
        return { -0.3, 0.025, 0.0, 180.0, 90.0, 0.0 }, { -0.35, 0.0, 0.0, 0.0, 90.0, 0.0 }, pet.anims.layDown or pet.anims.sit
    elseif item.bag == 'small' then
        return { -0.4, -0.25, 0.0, 180.0, 90.0, 0.0 }, { -0.025, -0.25, 0.0, 0.0, 90.0, 90.0 }, pet.anims.bag
    end
    return { -0.415, -0.25, 0.0, 180.0, 90.0, 0.0 }, { -0.275, -0.05, 0.0, 180.0, 90.0, 0.0 }, pet.anims.bag
end

accessoryHandlers.bag = function(item)
    local prop = 0
    local pet = begin('bag', function()
        deleteEntity(prop)
        setWeaponBlock(false)
        local p = SmPets.pet
        if p and DoesEntityExist(p.ped) then
            DetachEntity(p.ped, true, true)
            ClearPedTasks(p.ped)
            local spot = GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, 0.8, 0.0)
            SetEntityCoords(p.ped, spot.x, spot.y, SmPets.groundZ(spot), false, false, false, false)
            SetEntityCollision(p.ped, true, true)
        end
        infoUI.remove('sm_pets:bag')
    end)
    local ped, player = pet.ped, cache.ped
    local bagOffset, petOffset, anim = bagOffsets(pet, item)
    local here = GetEntityCoords(player)
    prop = spawnProp(item.prop, here, 0.0)
    if prop == 0 then return SmPets.cancelAction(true) end
    local bone = GetPedBoneIndex(player, SPINE_BONE)
    AttachEntityToEntity(prop, player, bone, bagOffset[1], bagOffset[2], bagOffset[3], bagOffset[4], bagOffset[5], bagOffset[6], false, false, false, false, 2, true)
    AttachEntityToEntity(ped, player, bone, petOffset[1], petOffset[2], petOffset[3], petOffset[4], petOffset[5], petOffset[6], false, false, false, true, 2, true)
    SmPets.playAnim(ped, anim, 1)
    setWeaponBlock(true)
    infoUI.show({ id = 'sm_pets:bag', title = 'Membawa Pet', icon = 'fas fa-bag-shopping', description = ('Tekan %s untuk menurunkan pet.'):format(Config.CancelKey) })
end

local PROP_DISTANCE = 1.3

---@param item table
---@return number forward
---@return boolean faceProp
local function toySpot(item)
    local offset = item.offset or vec3(0.0, 0.0, 0.0)
    if item.kind == 'scratch' then return PROP_DISTANCE - (1.0 + offset.y), true end
    if item.kind == 'playball' then return PROP_DISTANCE - offset.y, true end
    return PROP_DISTANCE, false
end

---@param item table
---@param anim table
local function playWithProp(item, anim)
    local cancelled, prop = false, 0
    local pet = begin('busy', function()
        cancelled = true
        deleteEntity(prop)
        local p = SmPets.pet
        if p and DoesEntityExist(p.ped) then FreezeEntityPosition(p.ped, false) end
    end)
    local ped, player = pet.ped, cache.ped
    SmPets.playAnim(player, pet.anims.pickup, 0, 1500)
    Wait(1200)
    if cancelled then return end

    local heading = GetEntityHeading(player)
    local spot = GetOffsetFromEntityInWorldCoords(player, 0.0, PROP_DISTANCE, 0.0)
    local ground = vec3(spot.x, spot.y, SmPets.groundZ(spot))
    prop = spawnProp(item.prop, ground, heading + (item.heading or 0.0))
    if prop == 0 then return SmPets.cancelAction(true) end
    FreezeEntityPosition(prop, true)

    local forward, faceProp = toySpot(item)
    local target = GetOffsetFromEntityInWorldCoords(player, 0.0, forward, 0.0)
    TaskGoToCoordAnyMeans(ped, target.x, target.y, target.z, 2.0, 0, false, 786603, 0.0)
    SmPets.waitArrive(ped, target, 0.7, 8000, function() return cancelled end)
    if cancelled then return end

    local lift = item.kind == 'showcase' and item.offset and item.offset.z or 0.0
    SetEntityCoords(ped, target.x, target.y, ground.z + lift, false, false, false, false)
    SetEntityHeading(ped, faceProp and heading or heading + 180.0)
    FreezeEntityPosition(ped, true)
    SmPets.playAnim(ped, anim, 1)
    pet.state = 'toy'
end

accessoryHandlers.scratch = function(item)
    local pet = SmPets.pet
    playWithProp(item, pet.anims.scratch or pet.anims.sit)
end

accessoryHandlers.playball = function(item)
    local pet = SmPets.pet
    playWithProp(item, pet.anims.playBall or pet.anims.sit)
end

accessoryHandlers.showcase = function(item)
    playWithProp(item, SmPets.pet.anims.sit)
end

---@param poseId string
function SmPets.pose(poseId)
    if not SmPets.canCommand() then return end
    local pet = SmPets.pet
    local pose
    for i = 1, #pet.anims.poses do
        if pet.anims.poses[i].id == poseId then pose = pet.anims.poses[i] end
    end
    if not pose then return end
    if IsPedInAnyVehicle(cache.ped, false) then return SmPets.notify('Turun dari kendaraan dulu.', 'error') end
    if not lib.callback.await('sm_pets:pose', false) then return end

    local active = true
    pet = begin('pose', function()
        active = false
        local player = cache.ped
        FreezeEntityPosition(player, false)
        ClearPedTasks(player)
        setWeaponBlock(false)
        local p = SmPets.pet
        if p and DoesEntityExist(p.ped) then
            DetachEntity(p.ped, true, true)
            ClearPedTasks(p.ped)
            local spot = GetOffsetFromEntityInWorldCoords(player, 0.0, 0.8, 0.0)
            SetEntityCoords(p.ped, spot.x, spot.y, SmPets.groundZ(spot), false, false, false, false)
        end
        infoUI.remove('sm_pets:pose')
    end)
    local ped, player = pet.ped, cache.ped

    local target = GetOffsetFromEntityInWorldCoords(player, 0.0, 1.0, 0.0)
    TaskGoToCoordAnyMeans(ped, target.x, target.y, target.z, 2.0, 0, false, 786603, 0.0)
    SmPets.waitArrive(ped, target, 0.8, 6000, function() return not active end)
    if not active then return end

    setWeaponBlock(true)
    if pose.freeze then FreezeEntityPosition(player, true) end
    local flag = pose.flag or 1
    SmPets.playAnim(player, pose.player, flag)
    SmPets.playAnim(ped, pose.pet, 15)
    if pose.bone then
        AttachEntityToEntity(ped, player, pose.bone, pose.offset.x, pose.offset.y, pose.offset.z, pose.rot.x, pose.rot.y, pose.rot.z, false, false, false, true, 2, true)
    end
    infoUI.show({ id = 'sm_pets:pose', title = pose.label, icon = 'fas fa-paw', description = ('Tekan %s untuk berhenti.'):format(Config.CancelKey) })

    CreateThread(function()
        local dict, clip = pose.player[1], pose.player[2]
        while active and SmPets.pet == pet do
            if not IsEntityPlayingAnim(cache.ped, dict, clip, 3) then
                TaskPlayAnim(cache.ped, dict, clip, 8.0, -8.0, -1, flag, 0.0, false, false, false)
            end
            Wait(500)
        end
    end)
end

local SEATS = {
    { seat = 0, door = 1, bone = 'seat_pside_f', front = true, side = 2.0 },
    { seat = 2, door = 3, bone = 'seat_pside_r', front = false, side = 2.0 },
    { seat = 1, door = 2, bone = 'seat_dside_r', front = false, side = -2.0 },
}

function SmPets.enterVehicle()
    if not SmPets.canCommand() then return end
    local current = SmPets.pet
    if not current then return end
    local vehicle = SmPets.selectTarget({ kind = 'vehicle', range = 8.0, title = ('Naikkan %s ke kendaraan'):format(current.name), action = 'Naikkan', icon = 'fas fa-car-side' })
    if not vehicle then return end
    local choice
    for i = 1, #SEATS do
        local seat = SEATS[i]
        if IsVehicleSeatFree(vehicle, seat.seat) and GetEntityBoneIndexByName(vehicle, seat.bone) ~= -1 then
            choice = seat
            break
        end
    end
    if not choice then return SmPets.notify('Tidak ada kursi kosong untuk pet.', 'error') end
    if not lib.callback.await('sm_pets:canAct', false) then return end

    local cancelled = false
    local pet = begin('busy', function()
        cancelled = true
        local p = SmPets.pet
        if not p or not DoesEntityExist(p.ped) then return end
        DetachEntity(p.ped, true, true)
        ClearPedTasksImmediately(p.ped)
        SetPedCanRagdoll(p.ped, true)
        if DoesEntityExist(vehicle) then
            SetVehicleDoorOpen(vehicle, choice.door, false, false)
            local out = GetOffsetFromEntityInWorldCoords(vehicle, choice.side, 0.0, 0.0)
            SetEntityCoords(p.ped, out.x, out.y, SmPets.groundZ(out), false, false, false, false)
            SetTimeout(1200, function()
                if DoesEntityExist(vehicle) then SetVehicleDoorShut(vehicle, choice.door, false) end
            end)
        end
    end)
    local ped = pet.ped

    local side = GetOffsetFromEntityInWorldCoords(vehicle, choice.side, 0.0, 0.0)
    TaskGoToCoordAnyMeans(ped, side.x, side.y, side.z, 2.0, 0, false, 786603, 0.0)
    SmPets.waitArrive(ped, side, 1.2, 8000, function() return cancelled end)
    if cancelled then return end
    if not DoesEntityExist(vehicle) or not IsVehicleSeatFree(vehicle, choice.seat) then
        SmPets.notify('Kursi sudah terisi.', 'error')
        return SmPets.cancelAction(true)
    end

    SetVehicleDoorOpen(vehicle, choice.door, false, false)
    Wait(600)
    if cancelled then return end
    ClearPedTasksImmediately(ped)
    SetPedCanRagdoll(ped, false)
    local bonePos = GetWorldPositionOfEntityBone(vehicle, GetEntityBoneIndexByName(vehicle, choice.bone))
    local seatOffset = GetOffsetFromEntityGivenWorldCoords(vehicle, bonePos.x, bonePos.y, bonePos.z)
    local extra = choice.front and pet.speciesCfg.carSeat.front or pet.speciesCfg.carSeat.back
    AttachEntityToEntity(ped, vehicle, 0, seatOffset.x + extra.x, seatOffset.y + extra.y, seatOffset.z + extra.z, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
    SmPets.playAnim(ped, pet.anims.sit, 1)
    Wait(500)
    if DoesEntityExist(vehicle) then SetVehicleDoorShut(vehicle, choice.door, false) end
    pet.state = 'vehicle'

    CreateThread(function()
        while SmPets.pet == pet and pet.state == 'vehicle' do
            if not DoesEntityExist(vehicle) then
                SmPets.cancelAction(true)
                break
            end
            Wait(1000)
        end
    end)
end

uiActions.follow = function()
    SmPets.closeUI()
    SmPets.follow()
    return { ok = true, closed = true }
end

uiActions.stay = function()
    SmPets.stay()
    return { ok = true }
end

uiActions.cuddle = function()
    SmPets.closeUI()
    CreateThread(SmPets.cuddle)
    return { ok = true, closed = true }
end

uiActions.sit = function()
    SmPets.closeUI()
    SmPets.sit()
    return { ok = true, closed = true }
end

uiActions.call = function()
    SmPets.closeUI()
    SmPets.call()
    return { ok = true, closed = true }
end

uiActions.cancel = function()
    SmPets.cancelAction()
    return { ok = true }
end

uiActions.pose = function(data)
    SmPets.closeUI()
    CreateThread(function() SmPets.pose(data.id) end)
    return { ok = true, closed = true }
end

uiActions.vehicle = function()
    SmPets.closeUI()
    CreateThread(SmPets.enterVehicle)
    return { ok = true, closed = true }
end

uiActions.equip = function(data)
    local pet = SmPets.pet
    if not pet then return { ok = false, msg = 'Keluarkan pet dulu.' } end
    local result = lib.callback.await('sm_pets:equip', false, data.key)
    if not result or not result.ok then return { ok = false, msg = result and result.msg } end
    if result.bowl then
        pet.bowl = result.bowl
        return { ok = true, bowl = result.bowl }
    end
    pet.look = result.look
    if DoesEntityExist(pet.ped) then
        local item = wardrobe[data.key]
        if item and not result.rawLook[tostring(item.comp)] then
            SetPedComponentVariation(pet.ped, item.comp, 0, 0, 0)
        end
        SmPets.applyLook(pet.ped, result.look)
    end
    return { ok = true, look = result.rawLook }
end

uiActions.use = function(data)
    local pet = SmPets.pet
    if not pet then return { ok = false, msg = 'Keluarkan pet dulu.' } end
    local key = data.key
    local item = wardrobe[key]
    if not item then return { ok = false } end
    local handler = accessoryHandlers[item.kind]
    if not handler then return { ok = false } end
    if not SmPets.canCommand() then return { ok = false } end

    if item.kind == 'training' then
        SmPets.closeUI()
        CreateThread(function() handler(item, key) end)
        return { ok = true, closed = true }
    end

    local result = lib.callback.await('sm_pets:useAccessory', false, key)
    if not result or not result.ok then return { ok = false, msg = result and result.msg } end
    SmPets.closeUI()
    CreateThread(function() handler(item, key) end)
    return { ok = true, closed = true }
end

AddEventHandler('sm_pets:client:removed', function()
    setWeaponBlock(false)
    infoUI.remove('sm_pets:fetch')
    infoUI.remove('sm_pets:bag')
    infoUI.remove('sm_pets:pose')
end)
