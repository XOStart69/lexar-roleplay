local config = localmodule 'config'
local interact = exports.rhd_interact
local illenium = illenium_appearance

local Wait = Wait
local GetGameTimer = GetGameTimer
local PlayerPedId = PlayerPedId
local DoesEntityExist = DoesEntityExist
local DeleteEntity = DeleteEntity
local GetEntityCoords = GetEntityCoords
local GetEntityHeading = GetEntityHeading
local IsEntityDead = IsEntityDead
local GetEntityModel = GetEntityModel
local IsEntityAttachedToEntity = IsEntityAttachedToEntity
local IsPedRagdoll = IsPedRagdoll
local IsEntityPlayingAnim = IsEntityPlayingAnim
local IsPauseMenuActive = IsPauseMenuActive
local DisableControlAction = DisableControlAction
local DisableOnFootFirstPersonViewThisUpdate = DisableOnFootFirstPersonViewThisUpdate
local SetPedMoveRateOverride = SetPedMoveRateOverride
local RestorePlayerStamina = RestorePlayerStamina
local GetPlayerFromServerId = GetPlayerFromServerId
local GetPlayerPed = GetPlayerPed
local NetworkGetNetworkIdFromEntity = NetworkGetNetworkIdFromEntity
local IsEntityInAir = IsEntityInAir
local IsEntityInWater = IsEntityInWater
local HasAnimDictLoaded = HasAnimDictLoaded
local GetEntityVelocity = GetEntityVelocity
local GetEntityForwardVector = GetEntityForwardVector
local SetEntityVelocity = SetEntityVelocity
local TaskPlayAnim = TaskPlayAnim
local sqrt = math.sqrt
local smatch = string.match
local tonumber, pairs, next = tonumber, pairs, next

local farm = SmAnimalFarm
local SPECIES = config.species
local RIDE = config.ride
local ANIM = RIDE.riderAnim
local BONE = RIDE.bone
local BLOCKED = RIDE.blockedControls
local BLOCKED_COUNT = #BLOCKED
local JUMP = RIDE.jump
local NPC_COORDS = config.npc.coords.xyz
local STORE_DISTANCE = config.storeDistance
local LEASH = config.lasso.leash
local FOLLOW_TASK = `SCRIPT_TASK_FOLLOW_TO_OFFSET_OF_ENTITY`
local LASSO_ITEM = config.lasso.item
local OUT_BLIP = config.releasedBlip

---@class FarmOut
---@field id integer
---@field species string
---@field entity integer|nil
---@field netId integer|nil
---@field look integer[]|nil
---@field following boolean
---@field leashed boolean|nil
---@field name string|nil
---@field blip integer|nil

---@type FarmOut|nil
local out
---@type table|nil
local ride
---@type table|nil
local seat
---@type table<integer, string>
local riders = {}
---@type table<integer, { ped: integer, netId: integer }>
local registered = {}
local watcherRunning = false
local jumpReadyAt = 0
local busy = false

---@param message string
---@param kind? string
local function notify(message, kind)
    lib.notify({ title = 'Peternakan', description = message, type = kind or 'error' })
end

---@param label string
---@param driver boolean
---@param canJump? boolean
local function showHelp(label, driver, canJump)
    local keys
    local hint

    if driver then
        local hasLasso = exports.ox_inventory:Search('count', LASSO_ITEM) > 0

        keys = {
            { key = 'W A S D', label = 'Jalan' },
            { key = 'SHIFT', label = 'Lari' },
        }

        if canJump then
            keys[#keys + 1] = { key = 'SPACE', label = 'Lompat' }
        end

        if hasLasso then
            keys[#keys + 1] = { key = 'G', label = 'Lasso' }
        else
            hint = 'Beli Lasso di peternak untuk mengikat orang sambil menunggang.'
        end

        keys[#keys + 1] = { key = 'F', label = 'Turun' }
    else
        keys = { { key = 'F', label = 'Turun' } }
    end

    farm.setHud({
        title = label,
        hint = hint,
        keys = keys,
    })
end

---@param ped integer
local function playSit(ped)
    if not IsEntityPlayingAnim(ped, ANIM.dict, ANIM.clip, 3) then
        lib.playAnim(ped, ANIM.dict, ANIM.clip, 5.0, 5.0, -1, 1, 0.0, false, 0, false)
    end
end

function farm.hasReleased()
    return out ~= nil
end

function farm.riderPed()
    return ride and ride.rider or nil
end

---@param entity integer
local function follow(entity)
    TaskFollowToOffsetOfEntity(entity, cache.ped, 0.0, -2.0, 0.0, 2.0, -1, 2.5, true)
    SetPedKeepTask(entity, true)
end

local function leashLoop()
    CreateThread(function()
        local catchUp = LEASH.catchUpDistance * LEASH.catchUpDistance
        local teleport = LEASH.teleportDistance * LEASH.teleportDistance
        local behind = LEASH.behind
        local speed = 0.0

        while out and out.leashed do
            local entity = out.entity
            local owner = cache.ped

            if not entity or not DoesEntityExist(entity) then break end

            if cache.vehicle then
                farm.setLeash(false)
                break
            end

            local a, b = GetEntityCoords(entity), GetEntityCoords(owner)
            local dx, dy = a.x - b.x, a.y - b.y
            local dist = dx * dx + dy * dy
            local rate = IsPedSprinting(owner) and 1.5 or IsPedRunning(owner) and 1.25 or 1.0

            if dist > teleport then
                local spot = GetOffsetFromEntityInWorldCoords(owner, 0.0, -behind, 0.0)

                SetEntityCoords(entity, spot.x, spot.y, spot.z, false, false, false, false)
                SetEntityHeading(entity, GetEntityHeading(owner))
                speed = 0.0
            end

            SetPedMoveRateOverride(entity, rate)

            local wanted = dist > catchUp and 3.0 or 2.0

            if speed ~= wanted or GetScriptTaskStatus(entity, FOLLOW_TASK) == 7 then
                TaskFollowToOffsetOfEntity(entity, owner, 0.0, -behind, 0.0, wanted, -1, 1.0, true)
                speed = wanted
            end

            Wait(400)
        end

        local entity = out and out.entity

        if entity and DoesEntityExist(entity) then
            SetPedMoveRateOverride(entity, 1.0)
        end
    end)
end

---@param enable boolean
function farm.setLeash(enable)
    if not out or not out.entity then return end

    local result = lib.callback.await('sm_animalfarm:leash', false, enable)

    if type(result) ~= 'table' then return end
    if not result.ok then return notify(result.message) end
    if not out or not out.entity then return end

    out.leashed = enable

    if enable then
        out.following = true
        leashLoop()
    else
        follow(out.entity)
    end
end

local mount

---@param netId integer
local function addOptions(netId)
    local species = SPECIES[out.species]

    interact:addEntity(netId, {
        {
            name = 'sm_animalfarm:mount',
            label = ('Naiki %s'):format(species.localLabel),
            icon = 'fa-solid fa-horse',
            distance = 2.5,
            canInteract = function()
                if farm.riding or seat or cache.vehicle then return false end

                return not (out and out.young) or farm.isKid()
            end,
            onSelect = function()
                mount()
            end,
        },
        {
            name = 'sm_animalfarm:leash',
            label = 'Tuntun dengan Lasso',
            icon = 'fa-solid fa-link',
            distance = 2.5,
            canInteract = function()
                return not farm.riding and out ~= nil and not out.leashed and not cache.vehicle
            end,
            onSelect = function()
                farm.setLeash(true)
            end,
        },
        {
            name = 'sm_animalfarm:unleash',
            label = 'Lepas Lasso',
            icon = 'fa-solid fa-link-slash',
            distance = 2.5,
            canInteract = function()
                return out ~= nil and out.leashed == true
            end,
            onSelect = function()
                farm.setLeash(false)
            end,
        },
        {
            name = 'sm_animalfarm:follow',
            label = 'Ikuti Saya',
            icon = 'fa-solid fa-person-walking-arrow-right',
            distance = 2.5,
            canInteract = function()
                return not farm.riding and out ~= nil and not out.following
            end,
            onSelect = function()
                if not out or not out.entity then return end

                out.following = true
                follow(out.entity)
            end,
        },
        {
            name = 'sm_animalfarm:stay',
            label = 'Diam di Sini',
            icon = 'fa-solid fa-hand',
            distance = 2.5,
            canInteract = function()
                return not farm.riding and out ~= nil and out.following
            end,
            onSelect = function()
                if not out or not out.entity then return end

                out.following = false
                ClearPedTasks(out.entity)
            end,
        },
        {
            name = 'sm_animalfarm:storeOut',
            label = 'Kembalikan ke Kandang',
            icon = 'fa-solid fa-house',
            distance = 2.5,
            canInteract = function()
                return not farm.riding and #(GetEntityCoords(cache.ped) - NPC_COORDS) <= STORE_DISTANCE
            end,
            onSelect = function()
                farm.storeReleased()
            end,
        },
    })
end

local function removeOutBlip()
    if out and out.blip then
        RemoveBlip(out.blip)
        out.blip = nil
    end
end

---@param entity integer
local function addOutBlip(entity)
    removeOutBlip()

    local blip = AddBlipForEntity(entity)

    SetBlipSprite(blip, OUT_BLIP.sprite)
    SetBlipColour(blip, OUT_BLIP.color)
    SetBlipScale(blip, OUT_BLIP.scale)
    SetBlipAsShortRange(blip, false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(out.name or SPECIES[out.species].localLabel)
    EndTextCommandSetBlipName(blip)
    out.blip = blip
end

local function watchOut()
    CreateThread(function()
        while out do
            local entity = out.entity

            if entity and not DoesEntityExist(entity) then
                if out.netId then
                    interact:removeEntity(out.netId)
                end

                removeOutBlip()
                out = nil
                lib.callback.await('sm_animalfarm:lost', false)
                notify('Hewanmu hilang dan kembali ke kandang.', 'inform')
                break
            end

            if entity and IsEntityDead(entity) then
                local netId = out.netId

                removeOutBlip()
                out = nil

                if netId then
                    interact:removeEntity(netId)
                end

                if not lib.callback.await('sm_animalfarm:died', false) then
                    lib.callback.await('sm_animalfarm:lost', false)
                end

                break
            end

            Wait(250)
        end
    end)
end

---@param ped integer
---@return integer[]
local function readLook(ped)
    local look = {}

    for component = 0, 11 do
        look[#look + 1] = GetPedDrawableVariation(ped, component)
        look[#look + 1] = GetPedTextureVariation(ped, component)
    end

    return look
end

---@param ped integer
---@param look integer[]|nil
local function applyLook(ped, look)
    if not look then return end

    for component = 0, 11 do
        local index = component * 2 + 1

        SetPedComponentVariation(ped, component, look[index], look[index + 1], 0)
    end
end

---@param entity integer
---@return false
local function failSpawn(entity)
    if DoesEntityExist(entity) then
        DeleteEntity(entity)
    end

    removeOutBlip()
    out = nil
    lib.callback.await('sm_animalfarm:lost', false)
    notify('Hewan gagal dimunculkan dan dikembalikan ke kandang.')

    return false
end

---@param id integer
---@param speciesKey string
---@param x number
---@param y number
---@param z number
---@param h number
---@param onCreated? fun(entity: integer)
---@return boolean
local function spawnAnimal(id, speciesKey, x, y, z, h, onCreated)
    local species = SPECIES[speciesKey]

    if not species or not lib.requestModel(species.model, 10000) then
        notify('Model hewan gagal dimuat.')
        return false
    end

    local entity = CreatePed(28, species.model, x, y, z, h, true, true)

    SetModelAsNoLongerNeeded(species.model)

    if onCreated then
        onCreated(entity)
    end

    local tries = 0

    while not NetworkGetEntityIsNetworked(entity) do
        tries += 1

        if tries > 50 then
            return failSpawn(entity)
        end

        Wait(20)
    end

    local netId = NetworkGetNetworkIdFromEntity(entity)

    SetNetworkIdCanMigrate(netId, false)
    SetEntityAsMissionEntity(entity, true, true)
    SetBlockingOfNonTemporaryEvents(entity, true)
    SetPedFleeAttributes(entity, 0, false)

    if out.look then
        applyLook(entity, out.look)
    else
        out.look = readLook(entity)
    end

    if not lib.callback.await('sm_animalfarm:spawned', false, id, netId) then
        return failSpawn(entity)
    end

    out.entity = entity
    out.netId = netId
    addOutBlip(entity)
    out.following = true
    addOptions(netId)

    if not out.settling then
        follow(entity)
    end

    return true
end

---@param spawn table
function farm.spawnReleased(spawn)
    if type(spawn) ~= 'table' or type(spawn.coords) ~= 'table' then return end

    out = { id = spawn.id, species = spawn.species, name = type(spawn.name) == 'string' and spawn.name or nil, young = spawn.young == true, following = false }

    CreateThread(function()
        local c = spawn.coords

        if spawnAnimal(spawn.id, spawn.species, c.x, c.y, c.z, c.w) then
            watchOut()
        end
    end)
end

function farm.storeReleased()
    if not out or ride then return end

    local result = lib.callback.await('sm_animalfarm:store', false)

    if type(result) ~= 'table' then return end
    if not result.ok then return notify(result.message) end

    local netId = out.netId

    removeOutBlip()
    out = nil

    if netId then
        interact:removeEntity(netId)
    end

    notify(result.message, 'success')
end

local ANIM_PED_RESOURCES = { 'lb-phone', 'sm_emotes', 'mm_radio', 'pma-voice' }

local kidSeat = { RIDE.kidSeat[1], RIDE.kidSeat[2], RIDE.kidSeat[3] }

---@param base number[]
---@param kid boolean
---@return number[]
local function seatOffset(base, kid)
    if not kid then return base end

    return { base[1] + kidSeat[1], base[2] + kidSeat[2], base[3] + kidSeat[3], base[4], base[5], base[6] }
end

---@param ped integer|nil
local function setAnimationPed(ped)
    local netId = ped and DoesEntityExist(ped) and NetworkGetEntityIsNetworked(ped) and NetworkGetNetworkIdFromEntity(ped) or nil

    playerState:set('animPed', netId, true)

    for i = 1, #ANIM_PED_RESOURCES do
        local resource = ANIM_PED_RESOURCES[i]

        if GetResourceState(resource) == 'started' then
            pcall(exports[resource].SetAnimationPed, exports[resource], ped)
        end
    end
end

---@param rider integer
---@param host integer
---@param offset number[]
local function attachRider(rider, host, offset)
    AttachEntityToEntity(
        rider, host, GetPedBoneIndex(host, BONE),
        offset[1], offset[2], offset[3],
        offset[4], offset[5], offset[6],
        false, true, false, true, 2, true
    )
end

---@param host integer
---@param appearance table
---@param offset number[]
---@return integer|nil
local function createRider(host, appearance, offset)
    local coords = GetEntityCoords(host)
    local model = appearance and appearance.model

    if not model or not lib.requestModel(model, 10000) then return end

    local rider = CreatePed(4, model, coords.x, coords.y, coords.z, GetEntityHeading(host), true, false)

    SetModelAsNoLongerNeeded(model)
    illenium:setPedAppearance(rider, appearance)
    SetEntityAsMissionEntity(rider, true, true)
    SetNetworkIdCanMigrate(NetworkGetNetworkIdFromEntity(rider), false)
    SetEntityInvincible(rider, true)
    SetEntityCollision(rider, false, false)
    SetBlockingOfNonTemporaryEvents(rider, true)
    SetPedCanRagdoll(rider, false)
    SetPedCanBeTargetted(rider, false)
    attachRider(rider, host, offset)
    playSit(rider)

    CreateThread(function()
        Wait(0)

        for _ = 1, 50 do
            if not DoesEntityExist(rider) then return end
            if NetworkGetEntityIsNetworked(rider) then break end

            Wait(100)
        end

        if not DoesEntityExist(rider) or not NetworkGetEntityIsNetworked(rider) then return end

        local hair = appearance.hair

        Entity(rider).state:set('smFarmFace', {
            headBlend = appearance.headBlend,
            faceFeatures = appearance.faceFeatures,
            headOverlays = appearance.headOverlays,
            hairColor = hair and hair.color or 0,
            hairHighlight = hair and hair.highlight or 0,
            eyeColor = appearance.eyeColor,
            decorations = GetPedDecorations(rider),
        }, true)

        if ride and ride.rider == rider then
            setAnimationPed(rider)
        end
    end)

    return rider
end

local dismount

local function controlLoop()
    CreateThread(function()
        local nextCheck = 0
        local ragdollFrom = GetGameTimer() + 2000

        while ride do
            local ped = PlayerPedId()
            local current = ride

            if IsEntityDead(ped) then
                dismount(true)
                break
            end

            if current.ragdollFrom then
                ragdollFrom = current.ragdollFrom
                current.ragdollFrom = nil
            end

            if cache.vehicle then
                dismount(false)
                break
            end

            if not current.jumping and IsPedRagdoll(ped) and GetGameTimer() > ragdollFrom then
                dismount(false, false, true)
                break
            end

            if not IsPauseMenuActive() then
                for i = 1, BLOCKED_COUNT do
                    DisableControlAction(0, BLOCKED[i], true)
                end
            end

            RestorePlayerStamina(cache.playerId, 1.0)
            SetPedMoveRateOverride(ped, current.moveRate)
            DisableOnFootFirstPersonViewThisUpdate()

            local now = GetGameTimer()

            if now >= nextCheck then
                nextCheck = now + 750

                if not DoesEntityExist(current.rider) then
                    dismount(false)
                    break
                end

                if GetEntityModel(ped) ~= current.model then
                    lib.print.warn('sm_animalfarm: model player berubah saat menunggang, turun otomatis')
                    dismount(false)
                    break
                end

                if ped ~= current.host or not IsEntityAttachedToEntity(current.rider, ped) then
                    lib.print.warn(('sm_animalfarm: rider %s, ditempel ulang'):format(ped ~= current.host and 'ped player berganti' or 'terlepas'))
                    current.host = ped
                    attachRider(current.rider, ped, current.offset)
                end

                playSit(current.rider)
            end

            Wait(0)
        end
    end)
end

function mount()
    if busy or ride or seat or not out or not out.entity then return end
    if cache.vehicle or IsEntityDead(cache.ped) then return end
    if playerState.isInAnimation or playerState.handsup then return notify('Kamu sedang dalam animasi.') end

    local entity = out.entity

    if not DoesEntityExist(entity) then return end

    local wanted = SPECIES[out.species]

    if not lib.requestModel(wanted.model, 10000) then return notify('Model hewan gagal dimuat.') end

    local result = lib.callback.await('sm_animalfarm:mount', false)

    if type(result) ~= 'table' then return end
    if not result.ok then return notify(result.message) end

    local species = SPECIES[result.species]
    local coords = GetEntityCoords(entity)
    local heading = GetEntityHeading(entity)
    local look = readLook(entity)
    local ped = cache.ped
    local kid = farm.isKid()

    local backup = {
        appearance = illenium:getPedAppearance(ped),
        health = GetEntityHealth(ped),
        armour = GetPedArmour(ped),
        cam = GetFollowPedCamViewMode(),
        canUseWeapons = playerState.canUseWeapons,
        canEmote = playerState.canEmote,
    }

    TriggerEvent('ox_inventory:disarm', true)
    TriggerEvent('sm_animalfarm:lasso:reset')
    interact:removeEntity(out.netId)
    removeOutBlip()

    local driverOffset = seatOffset(species.ride.driver, kid)
    local seatKey = ('%s:driver:%s'):format(result.species, kid and 'kid' or 'adult')

    busy = true
    ClearPedTasks(entity)
    TaskStandStill(entity, 8000)
    farm.seatTransition(ped, entity, driverOffset, 'getIn', seatKey, true)
    busy = false

    if not out then return end

    if DoesEntityExist(entity) then
        coords = GetEntityCoords(entity)
        heading = GetEntityHeading(entity)
    end

    DeleteEntity(entity)
    out.entity = nil
    out.netId = nil
    out.look = look
    out.leashed = nil

    illenium:setPlayerModel(species.model)
    SetModelAsNoLongerNeeded(species.model)

    local animalPed = PlayerPedId()

    applyLook(animalPed, look)
    SetEntityCoordsNoOffset(animalPed, coords.x, coords.y, coords.z, false, false, true)
    SetEntityHeading(animalPed, heading)
    SetPedCanRagdollFromPlayerImpact(animalPed, false)

    local rider = createRider(animalPed, backup.appearance, driverOffset)

    ride = {
        id = result.id,
        species = result.species,
        rider = rider or 0,
        host = animalPed,
        model = GetEntityModel(animalPed),
        offset = driverOffset,
        seatKey = seatKey,
        kid = kid,
        backup = backup,
        moveRate = species.ride.moveRate,
        jump = species.ride.jump,
    }

    if ride.jump then
        RequestAnimDict(ride.jump.dict)
    end

    farm.riding = true
    showHelp(out and out.name or species.localLabel, true, ride.jump ~= nil)
    playerState:set('canUseWeapons', false, false)
    playerState:set('canEmote', false, true)
    SetFollowPedCamViewMode(1)
    controlLoop()
end

---@param dead boolean
---@param skipServer? boolean
---@param fall? boolean
function dismount(dead, skipServer, fall)
    local current = ride

    if not current then return end

    ride = nil
    farm.riding = false
    farm.setHud(nil)

    local animalPed = PlayerPedId()
    local coords = GetEntityCoords(animalPed)
    local heading = GetEntityHeading(animalPed)
    local side = GetOffsetFromEntityInWorldCoords(animalPed, 1.5, 0.0, 0.0)
    local riderSpot = current.rider ~= 0 and DoesEntityExist(current.rider) and GetEntityCoords(current.rider) or coords
    local pendingId = not skipServer and lib.callback.await('sm_animalfarm:dismount', false, dead)

    TriggerEvent('sm_animalfarm:lasso:reset')
    setAnimationPed(nil)

    if current.jump then
        RemoveAnimDict(current.jump.dict)
    end

    if current.rider ~= 0 and DoesEntityExist(current.rider) then
        DetachEntity(current.rider, true, true)
        DeleteEntity(current.rider)
    end

    local backup = current.backup

    illenium:setPlayerAppearance(backup.appearance)

    local ped = PlayerPedId()
    local animate = RIDE.mount.enabled and not dead and not fall and pendingId and out and true or false

    SetPedArmour(ped, backup.armour)

    if animate then
        FreezeEntityPosition(ped, true)
        SetEntityCollision(ped, false, false)
    elseif fall and not dead then
        local push = RIDE.mount.fallPush

        SetEntityCoordsNoOffset(ped, riderSpot.x, riderSpot.y, riderSpot.z, false, false, false)
        SetPedToRagdoll(ped, RIDE.mount.fallRagdollMs, RIDE.mount.fallRagdollMs, 0, false, false, false)
        SetEntityVelocity(ped, (side.x - coords.x) * push, (side.y - coords.y) * push, push)
    else
        SetEntityCoords(ped, side.x, side.y, side.z, false, false, false, false)
    end

    SetFollowPedCamViewMode(backup.cam == 4 and 1 or backup.cam)
    playerState:set('canUseWeapons', backup.canUseWeapons ~= false, false)
    playerState:set('canEmote', backup.canEmote ~= false, true)

    if dead then
        SetEntityHealth(ped, 0)
    else
        SetEntityHealth(ped, backup.health)
    end

    if not pendingId or not out then return end

    if not animate then
        spawnAnimal(pendingId, current.species, coords.x, coords.y, coords.z, heading)
        return
    end

    local created = false

    out.settling = true
    busy = true

    spawnAnimal(pendingId, current.species, coords.x, coords.y, coords.z, heading, function(entity)
        created = true

        CreateThread(function()
            TaskStandStill(entity, 6000)
            FreezeEntityPosition(ped, false)
            SetEntityCollision(ped, true, true)

            local finished = farm.seatTransition(ped, entity, current.offset, 'getOut', current.seatKey)

            busy = false

            if not finished then
                SetEntityCoords(ped, side.x, side.y, side.z, false, false, false, false)
            end

            if not out then return end

            out.settling = nil

            if out.entity == entity then
                follow(entity)
            end
        end)
    end)

    if created then return end

    busy = false
    FreezeEntityPosition(ped, false)
    SetEntityCollision(ped, true, true)
    SetEntityCoords(ped, side.x, side.y, side.z, false, false, false, false)

    if out then
        out.settling = nil
    end
end

---@param driver integer
local function boardOptions(driver)
    return {
        {
            name = ('sm_animalfarm:board:%d'):format(driver),
            label = 'Bonceng',
            icon = 'fa-solid fa-user-group',
            distance = 2.5,
            canInteract = function()
                if farm.riding or seat or cache.vehicle or farm.inPen then return false end

                return Player(driver).state.smFarmPassenger == nil
            end,
            onSelect = function()
                farm.board(driver)
            end,
        },
    }
end

---@param driver integer
local function unregister(driver)
    local entry = registered[driver]

    if not entry then return end

    registered[driver] = nil
    interact:removeEntity(entry.netId)
end

local function startWatcher()
    if watcherRunning then return end

    watcherRunning = true

    CreateThread(function()
        while next(riders) do
            for driver in pairs(riders) do
                local player = GetPlayerFromServerId(driver)
                local ped = player ~= -1 and GetPlayerPed(player) or 0
                local entry = registered[driver]

                if ped == 0 then
                    unregister(driver)
                elseif not entry or entry.ped ~= ped then
                    unregister(driver)

                    local netId = NetworkGetNetworkIdFromEntity(ped)

                    registered[driver] = { ped = ped, netId = netId }
                    interact:addEntity(netId, boardOptions(driver))
                end
            end

            Wait(1000)
        end

        watcherRunning = false
    end)
end

AddStateBagChangeHandler('smFarmFace', nil, function(bagName, _, value)
    if type(value) ~= 'table' then return end

    local netId = tonumber(smatch(bagName, '^entity:(%d+)$'))

    if not netId then return end

    CreateThread(function()
        local ped = 0

        for _ = 1, 50 do
            ped = NetworkDoesNetworkIdExist(netId) and NetworkGetEntityFromNetworkId(netId) or 0

            if ped ~= 0 and DoesEntityExist(ped) then break end

            Wait(100)
        end

        if ped == 0 or not DoesEntityExist(ped) then return end
        if NetworkGetEntityOwner(ped) == PlayerId() then return end

        if value.headBlend then
            illenium:setPedHeadBlend(ped, value.headBlend)
        end

        if value.faceFeatures then
            illenium:setPedFaceFeatures(ped, value.faceFeatures)
        end

        if value.headOverlays then
            illenium:setPedHeadOverlays(ped, value.headOverlays)
        end

        SetPedHairTint(ped, tonumber(value.hairColor) or 0, tonumber(value.hairHighlight) or 0)
        SetPedEyeColor(ped, tonumber(value.eyeColor) or 0)
        ClearPedDecorations(ped)

        local decorations = value.decorations

        if type(decorations) ~= 'table' then return end

        for i = 1, #decorations do
            local decoration = decorations[i]

            AddPedDecorationFromHashes(ped, decoration[1], decoration[2])
        end
    end)
end)

AddStateBagChangeHandler('smFarmRide', nil, function(bagName, _, value)
    local driver = tonumber(smatch(bagName, '^player:(%d+)$'))

    if not driver or driver == cache.serverId then return end

    if value then
        riders[driver] = value
        startWatcher()
    else
        riders[driver] = nil
        unregister(driver)
    end
end)

---@param notifyServer boolean
---@param animate? boolean
local function unboard(notifyServer, animate)
    local current = seat

    if not current then return end

    seat = nil
    farm.boarded = false
    farm.setHud(nil)

    local ped = cache.ped

    playerState:set('canUseWeapons', current.canUseWeapons ~= false, false)

    if notifyServer then
        TriggerTokenEvent('sm_animalfarm:unboard')
    end

    if animate and DoesEntityExist(current.host) then
        busy = true

        local finished = farm.seatTransition(ped, current.host, current.offset, 'getOut', current.seatKey)

        busy = false

        if finished then return end
    end

    local side = GetOffsetFromEntityInWorldCoords(ped, -1.2, 0.0, 0.0)

    DetachEntity(ped, true, false)
    StopAnimTask(ped, ANIM.dict, ANIM.clip, 1.0)
    ClearPedTasks(ped)
    SetEntityCoords(ped, side.x, side.y, side.z, false, false, false, false)
end

---@param driver integer
function farm.board(driver)
    if busy or seat or farm.riding then return end

    local result = lib.callback.await('sm_animalfarm:board', false, driver)

    if type(result) ~= 'table' then return end
    if not result.ok then return notify(result.message) end

    local species = SPECIES[result.species]
    local player = GetPlayerFromServerId(driver)
    local host = player ~= -1 and GetPlayerPed(player) or 0

    if host == 0 or not DoesEntityExist(host) then
        TriggerTokenEvent('sm_animalfarm:unboard')
        return
    end

    local ped = cache.ped
    local kid = farm.isKid()
    local offset = seatOffset(species.ride.passenger, kid)

    local seatKey = ('%s:passenger:%s'):format(result.species, kid and 'kid' or 'adult')

    TriggerEvent('ox_inventory:disarm', true)
    busy = true
    farm.seatTransition(ped, host, offset, 'getIn', seatKey, true)
    busy = false

    if not DoesEntityExist(host) then
        DetachEntity(ped, true, false)
        ClearPedTasks(ped)
        TriggerTokenEvent('sm_animalfarm:unboard')
        return
    end

    seat = { driver = driver, host = host, canUseWeapons = playerState.canUseWeapons, species = result.species, kid = kid, offset = offset, seatKey = seatKey }
    farm.boarded = true
    showHelp(species.localLabel, false)
    playerState:set('canUseWeapons', false, false)
    AttachEntityToEntity(
        ped, host, GetPedBoneIndex(host, BONE),
        offset[1], offset[2], offset[3],
        offset[4], offset[5], offset[6],
        false, true, false, true, 2, true
    )
    playSit(ped)

    CreateThread(function()
        local nextCheck = 0

        while seat do
            if not IsPauseMenuActive() then
                for i = 1, BLOCKED_COUNT do
                    DisableControlAction(0, BLOCKED[i], true)
                end
            end

            DisableControlAction(0, 30, true)
            DisableControlAction(0, 31, true)

            local now = GetGameTimer()

            if now >= nextCheck then
                nextCheck = now + 500

                local current = seat
                local hostPlayer = GetPlayerFromServerId(current.driver)
                local valid = hostPlayer ~= -1 and GetPlayerPed(hostPlayer) == current.host

                if not valid or IsEntityDead(cache.ped) then
                    unboard(true)
                    break
                end

                playSit(cache.ped)
            end

            Wait(0)
        end
    end)
end

RegisterNetEvent('sm_animalfarm:client:unboard', function()
    if source == '' then return end

    unboard(false)
end)

---@param ped integer
---@param host integer
---@param offset number[]
local function reattach(ped, host, offset)
    AttachEntityToEntity(
        ped, host, GetPedBoneIndex(host, BONE),
        offset[1], offset[2], offset[3],
        offset[4], offset[5], offset[6],
        false, true, false, true, 2, true
    )
end

local function jump()
    local current = ride

    if not current or not current.jump then return end

    local now = GetGameTimer()

    if now < jumpReadyAt then return end

    local scale = playerState.smFarmScale

    if scale and scale ~= 1.0 then return end

    local ped = PlayerPedId()

    if IsEntityInAir(ped) or IsEntityInWater(ped) or IsPedRagdoll(ped) then return end

    local jumpDict = current.jump.dict
    local jumpClip = current.jump.clip

    if not HasAnimDictLoaded(jumpDict) then
        RequestAnimDict(jumpDict)
        return
    end

    jumpReadyAt = now + JUMP.cooldown

    local velocity = GetEntityVelocity(ped)
    local forward = GetEntityForwardVector(ped)
    local speed = sqrt(velocity.x * velocity.x + velocity.y * velocity.y)

    if speed < current.jump.forward then
        speed = current.jump.forward
    end

    if speed > current.jump.forwardMax then
        speed = current.jump.forwardMax
    end

    local up = current.jump.up
    local velocityX = forward.x * speed
    local velocityY = forward.y * speed
    local gravity = JUMP.gravity
    local maxFall = JUMP.maxFall
    local apexHeight = up * up / (2.0 * gravity)
    local fallAccelTime = maxFall / gravity
    local fallAccelHeight = maxFall * maxFall / (2.0 * gravity)
    local descentTime = fallAccelTime + (apexHeight - fallAccelHeight) / maxFall

    if apexHeight <= fallAccelHeight then
        descentTime = up / gravity
    end

    local airtime = up / gravity + descentTime
    local landPhase = current.jump.landPhase
    local rate = current.jump.duration * landPhase / airtime
    local started = now
    local standHeight = GetEntityHeightAboveGround(ped)
    local jumpId = (current.jumpId or 0) + 1

    current.jumpId = jumpId
    current.jumping = true
    SetPedCanRagdoll(ped, false)
    TaskPlayAnim(ped, jumpDict, jumpClip, 4.0, 4.0, -1, 0, 0.0, false, false, false)

    CreateThread(function()
        while ride == current do
            local elapsed = (GetGameTimer() - started) / 1000

            if elapsed > airtime + 1.0 then break end

            local velocityZ = up - gravity * elapsed

            if velocityZ < -maxFall then
                velocityZ = -maxFall
            end

            if velocityZ < 0.0 then
                if GetEntityHeightAboveGround(ped) <= standHeight + JUMP.landHeight then break end
                if velocityZ < -2.0 and GetEntityVelocity(ped).z > -0.5 then break end
            end

            local holding = GetEntityAnimCurrentTime(ped, jumpDict, jumpClip) >= landPhase

            SetEntityVelocity(ped, velocityX, velocityY, velocityZ)
            SetEntityAnimSpeed(ped, jumpDict, jumpClip, holding and 0.0 or rate)

            Wait(0)
        end

        SetEntityAnimSpeed(ped, jumpDict, jumpClip, 1.0)

        current.ragdollFrom = GetGameTimer() + JUMP.landingGrace * 2
        current.jumping = false

        Wait(JUMP.landingGrace)

        if current.jumpId ~= jumpId then return end

        SetPedCanRagdoll(PlayerPedId(), true)
    end)
end

if config.debug and config.debug.enabled then
    RegisterCommand('farmjump', function(_, args)
        if not ride or not ride.jump then
            return notify('Naiki hewan yang bisa melompat dulu.')
        end

        local up = tonumber(args[1]) or ride.jump.up
        local forward = tonumber(args[2]) or ride.jump.forward
        local forwardMax = tonumber(args[3]) or ride.jump.forwardMax
        local tuned = {}

        for key, value in pairs(ride.jump) do
            tuned[key] = value
        end

        tuned.up = up
        tuned.forward = forward
        tuned.forwardMax = forwardMax
        ride.jump = tuned
        notify(('jump = { up = %.1f, forward = %.1f, forwardMax = %.1f }'):format(up, forward, forwardMax), 'inform')
    end, false)

    RegisterCommand('farmseat', function(_, args)
        local x, y, z = tonumber(args[1]), tonumber(args[2]), tonumber(args[3])

        if not x or not y or not z then
            return notify(('kidSeat sekarang: %.2f %.2f %.2f'):format(kidSeat[1], kidSeat[2], kidSeat[3]), 'inform')
        end

        kidSeat[1], kidSeat[2], kidSeat[3] = x, y, z

        if ride and ride.kid and ride.rider ~= 0 and DoesEntityExist(ride.rider) then
            ride.offset = seatOffset(SPECIES[ride.species].ride.driver, true)
            reattach(ride.rider, PlayerPedId(), ride.offset)
        elseif seat and seat.kid and DoesEntityExist(seat.host) then
            reattach(cache.ped, seat.host, seatOffset(SPECIES[seat.species].ride.passenger, true))
        end

        notify(('kidSeat: %.2f %.2f %.2f'):format(x, y, z), 'inform')
    end, false)

    RegisterCommand('farmoffset', function(_, args)
        if not ride or ride.rider == 0 or not DoesEntityExist(ride.rider) then
            return notify('Naiki hewan dulu.')
        end

        local base = SPECIES[ride.species].ride.driver
        local offset = {}

        for i = 1, 6 do
            offset[i] = tonumber(args[i]) or base[i]
        end

        ride.offset = seatOffset(offset, ride.kid)
        reattach(ride.rider, PlayerPedId(), ride.offset)
        notify(('driver = { %.2f, %.2f, %.2f, %.1f, %.1f, %.1f }'):format(offset[1], offset[2], offset[3], offset[4], offset[5], offset[6]), 'inform')
    end, false)
end

lib.addKeybind({
    name = 'sm_animalfarm_lasso',
    description = 'Lasso saat menunggang hewan ternak',
    defaultKey = 'G',
    onPressed = function()
        if ride then
            TriggerTokenEvent('sm_animalfarm:lasso:ride')
        end
    end,
})

lib.addKeybind({
    name = 'sm_animalfarm_jump',
    description = 'Lompat saat menunggang hewan ternak',
    defaultKey = 'SPACE',
    onPressed = jump,
})

lib.addKeybind({
    name = 'sm_animalfarm_dismount',
    description = 'Turun dari hewan ternak',
    defaultKey = 'F',
    onPressed = function()
        if busy then return end

        if ride then
            dismount(false)
        elseif seat then
            unboard(true, true)
        end
    end,
})

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    farm.setHud(nil)

    if ride then
        dismount(false, true)
    end

    if seat then
        unboard(false)
    end

    if out and out.netId then
        interact:removeEntity(out.netId)
    end

    removeOutBlip()

    out = nil

    for driver in pairs(registered) do
        unregister(driver)
    end
end)
