local config = localmodule 'config.shared'
local placement = localmodule 'modules.placement'
local drone = localmodule 'modules.drone'

local Wait = Wait
local GetGameTimer = GetGameTimer
local GetEntityCoords = GetEntityCoords
local GetEntityHeading = GetEntityHeading
local GetEntityVelocity = GetEntityVelocity
local DoesEntityExist = DoesEntityExist
local DeleteEntity = DeleteEntity
local IsControlJustPressed = IsControlJustPressed
local IsDisabledControlJustPressed = IsDisabledControlJustPressed
local IsControlJustReleased = IsControlJustReleased
local IsDisabledControlJustReleased = IsDisabledControlJustReleased
local GetProjectileNearPed = GetProjectileNearPed
local HasEntityCollidedWithAnything = HasEntityCollidedWithAnything
local HasEntityAnimFinished = HasEntityAnimFinished
local NetworkDoesNetworkIdExist = NetworkDoesNetworkIdExist
local type = type

local jobs = config.jobs
local pickupAnyJobs = config.pickupAnyJobs
local shieldCfg = config.shield
local droneCfg = config.drone
local shieldVariants = config.shieldVariants
local droneVariants = config.droneVariants
local defaultShield = config.defaultShield
local defaultDrone = config.defaultDrone
local text = config.text

local WEAPON_HASH = config.weaponHash
local STATE_KEY = 'smDroneShields'
local ATTACK = 24
local PROJECTILE_TIMEOUT = 4000
local PROBE_INTERVAL = 150
local SETTLE_TIMEOUT = 3000
local SETTLE_SPEED_SQ = 0.75 * 0.75
local HINT_ID = 'sm_droneshield_hint'
local INTERACT_PREFIX = 'sm_droneshield_'
local PICKUP_DICT = 'pickup_object'
local PICKUP_CLIP = 'pickup_low'

local shieldAnime, shieldDeployed, droneAnime, droneVehicle = {}, {}, {}, {}
for label, variant in pairs(shieldVariants) do
    shieldAnime[label] = joaat(variant.anime)
    shieldDeployed[label] = joaat(variant.deployed)
end
for label, variant in pairs(droneVariants) do
    droneAnime[label] = joaat(variant.anime)
    droneVehicle[label] = joaat(variant.vehicle)
end

local tracked = {}
local deploying = {}
local interacts = {}
local seen = {}
local throwLoopRunning = false
local placeKey

AddTextEntry('WT_KFTHROWSHIELD', 'Throw Shield')
AddTextEntry('KFTDSHIELD', 'Tactical Drone Shield')

---@param description string
---@param kind? string
local function notify(description, kind)
    lib.notify({ title = text.title, description = description, type = kind or 'error' })
end

---@return string?
local function allowedJob()
    local job = QBPlayerData.job
    local minGrade = job and jobs[job.name]
    if not minGrade or (job.grade and job.grade.level or 0) < minGrade then return nil end
    return job.name
end

---@param isDrone boolean
---@param metadata table?
---@return string
local function variantOf(isDrone, metadata)
    local label = type(metadata) == 'table' and metadata.type or nil
    if isDrone then
        return droneVariants[label] and label or defaultDrone
    end
    return shieldVariants[label] and label or defaultShield
end

---@return string
local function equippedVariant()
    local weapon = ox_inventory:getCurrentWeapon()
    return variantOf(false, weapon and weapon.metadata)
end

---@param entity number
local function deleteLocal(entity)
    if entity and DoesEntityExist(entity) then
        SetEntityAsMissionEntity(entity, true, true)
        DeleteEntity(entity)
    end
end

---@param projectile number
---@param throwHeading number
---@param variant string
local function handleProjectile(projectile, throwHeading, variant)
    local deadline = GetGameTimer() + SETTLE_TIMEOUT
    while DoesEntityExist(projectile) and GetGameTimer() < deadline do
        if HasEntityCollidedWithAnything(projectile) then
            Wait(50)
            break
        end
        local velocity = GetEntityVelocity(projectile)
        if velocity.x * velocity.x + velocity.y * velocity.y + velocity.z * velocity.z <= SETTLE_SPEED_SQ then
            break
        end
        Wait(50)
    end

    if not DoesEntityExist(projectile) then
        tracked[projectile] = nil
        return
    end

    FreezeEntityPosition(projectile, true)
    local coords = GetEntityCoords(projectile)
    local heading = (throwHeading + 180.0) % 360.0
    local grounded = placement.groundCoords(shieldDeployed[variant], coords, heading) or coords

    deleteLocal(projectile)
    tracked[projectile] = nil

    lib.callback.await('sm_droneshield:throw', false, grounded, heading)
end

local function throwLoop()
    local pendingAt, pendingHeading, pendingVariant
    local nextProbe = 0

    while true do
        local ped = cache.ped
        local now = GetGameTimer()
        local holding = cache.weapon == WEAPON_HASH

        if holding then
            if IsControlJustPressed(0, ATTACK) or IsDisabledControlJustPressed(0, ATTACK) then
                TriggerTokenEvent('sm_droneshield:server:prepareThrow')
            end
            if IsControlJustReleased(0, ATTACK) or IsDisabledControlJustReleased(0, ATTACK) then
                pendingAt, pendingHeading, pendingVariant = now, GetEntityHeading(ped), equippedVariant()
            end
        end

        if pendingAt then
            if now - pendingAt > PROJECTILE_TIMEOUT then
                pendingAt = nil
            elseif now >= nextProbe then
                nextProbe = now + PROBE_INTERVAL
                local found, _, projectile = GetProjectileNearPed(ped, WEAPON_HASH, 12.0, false)
                if found and projectile and projectile ~= 0 and not tracked[projectile] then
                    tracked[projectile] = true
                    local heading, variant = pendingHeading, pendingVariant
                    pendingAt = nil
                    CreateThread(function()
                        handleProjectile(projectile, heading, variant)
                    end)
                end
            end
        end

        if not holding and not pendingAt then break end
        Wait(holding and 0 or 25)
    end

    throwLoopRunning = false
end

---@param holding boolean
local function setHint(holding)
    if holding and allowedJob() then
        local key = placeKey:getCurrentKey()
        if type(key) ~= 'string' or key == '' or key:match('^%d+$') then
            key = config.keys.place
        end
        infoUI.show({
            id = HINT_ID,
            title = text.title,
            icon = 'fa-solid fa-shield-halved',
            description = ('[kbd]LMB[/kbd] Lempar shield\n[kbd]%s[/kbd] Pasang manual'):format(key),
        })
    else
        infoUI.remove(HINT_ID)
    end
end

---@param weapon number|false
local function onWeapon(weapon)
    local holding = weapon == WEAPON_HASH
    setHint(holding)
    if not holding then
        if placement.isActive() then placement.cancel() end
        return
    end
    if not throwLoopRunning then
        throwLoopRunning = true
        CreateThread(throwLoop)
    end
end

lib.onCache('weapon', onWeapon)

---@param entity number
---@param dict string
---@param clip string
---@param timeout number
---@param id number
local function playDeploy(entity, dict, clip, timeout, id)
    if not pcall(lib.requestAnimDict, dict) then return end
    PlayEntityAnim(entity, clip, dict, 8.0, false, true, false, 0.0, 0)
    Wait(0)
    local deadline = GetGameTimer() + timeout
    while deploying[id] == entity and DoesEntityExist(entity) and not HasEntityAnimFinished(entity, dict, clip, 3) and GetGameTimer() < deadline do
        Wait(50)
    end
    RemoveAnimDict(dict)
end

RegisterNetEvent('sm_droneshield:client:deploying', function(id, coords, heading, isDrone, variant, owner)
    local variants = isDrone and droneVariants or shieldVariants
    local data = variants[variant]
    if not data or deploying[id] then return end

    local isOwner = owner == cache.serverId
    local model = (isDrone and droneAnime or shieldAnime)[variant]

    CreateThread(function()
        if IsModelInCdimage(model) and pcall(lib.requestModel, model) then
            local entity = CreateObjectNoOffset(model, coords.x, coords.y, coords.z, false, false, false)
            SetModelAsNoLongerNeeded(model)
            if entity and entity ~= 0 then
                SetEntityRotation(entity, 0.0, 0.0, heading, 2, true)
                FreezeEntityPosition(entity, true)
                deploying[id] = entity
                playDeploy(entity, 'clip@' .. data.anime, data.anime, isDrone and shieldCfg.droneDeployMaxMs or shieldCfg.deployMaxMs, id)
            end
        end

        if isOwner then
            TriggerTokenEvent('sm_droneshield:server:deployDone', id)
        end
    end)
end)

RegisterNetEvent('sm_droneshield:client:deployed', function(id, netId)
    local entity = deploying[id]
    if not entity then return end
    CreateThread(function()
        local deadline = GetGameTimer() + 2000
        while not NetworkDoesNetworkIdExist(netId) and GetGameTimer() < deadline do
            Wait(100)
        end
        Wait(300)
        if deploying[id] == entity then
            deploying[id] = nil
        end
        deleteLocal(entity)
    end)
end)

RegisterNetEvent('sm_droneshield:client:removed', function(id)
    local entity = deploying[id]
    if not entity then return end
    deploying[id] = nil
    deleteLocal(entity)
end)

RegisterNetEvent('sm_droneshield:client:droneGone', function(id, reason)
    drone.forget(id)
    if reason then
        notify(reason)
    end
end)

---@param id number
local function pickup(id)
    local ped = cache.ped
    if pcall(lib.requestAnimDict, PICKUP_DICT) then
        TaskPlayAnim(ped, PICKUP_DICT, PICKUP_CLIP, 8.0, -8.0, 1000, 48, 0, false, false, false)
        RemoveAnimDict(PICKUP_DICT)
        Wait(700)
    end
    TriggerTokenEvent('sm_droneshield:server:pickup', id)
end

---@param list any
local function syncInteracts(list)
    local myId = cache.serverId
    local job = allowedJob()
    local canAny = job ~= nil and pickupAnyJobs[job] == true

    table.wipe(seen)
    if type(list) == 'table' then
        for i = 1, #list do
            local entry = list[i]
            local id = entry.id
            if canAny or entry.owner == myId then
                seen[id] = true
                if not interacts[id] then
                    interacts[id] = true
                    local coords = entry.coords
                    exports.rhd_interact:addCoords({
                        id = INTERACT_PREFIX .. id,
                        coords = vec3(coords.x, coords.y, coords.z + 0.8),
                        options = {
                            {
                                name = 'sm_droneshield_pickup',
                                label = text.pickupShield,
                                icon = 'fa-solid fa-hand',
                                distance = shieldCfg.pickupDistance - 0.5,
                                onSelect = function()
                                    pickup(id)
                                end,
                            },
                        },
                    })
                end
            end
        end
    end

    for id in pairs(interacts) do
        if not seen[id] then
            interacts[id] = nil
            exports.rhd_interact:removeCoords(INTERACT_PREFIX .. id)
        end
    end
end

AddStateBagChangeHandler(STATE_KEY, 'global', function(_, _, value)
    syncInteracts(value)
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function()
    syncInteracts(GlobalState[STATE_KEY])
    setHint(cache.weapon == WEAPON_HASH)
end)

placeKey = lib.addKeybind({
    name = 'sm_droneshield_place',
    description = text.placeKey,
    defaultKey = config.keys.place,
    onPressed = function()
        if cache.weapon ~= WEAPON_HASH or placement.isActive() or drone.isControlling() then return end
        if not allowedJob() then return notify(text.notAllowed) end

        placement.start({
            model = shieldDeployed[equippedVariant()],
            maxDistance = shieldCfg.placeDistance,
            heading = (GetEntityHeading(cache.ped) + 180.0) % 360.0,
            canContinue = function()
                return cache.weapon == WEAPON_HASH
            end,
            onConfirm = function(coords, heading)
                lib.callback.await('sm_droneshield:placeShield', false, coords, heading)
            end,
        })
    end,
})

exports('useDroneShield', function(_, slot)
    if not allowedJob() then return notify(text.notAllowed) end
    if placement.isActive() or drone.isControlling() then return end

    local metadata = type(slot) == 'table' and slot.metadata or nil
    local slotId = type(slot) == 'table' and slot.slot or nil
    local variant = variantOf(true, metadata)

    placement.start({
        model = droneVehicle[variant],
        maxDistance = droneCfg.placeDistance,
        heading = GetEntityHeading(cache.ped),
        canContinue = function()
            return true
        end,
        onConfirm = function(coords, heading)
            local result = lib.callback.await('sm_droneshield:placeDrone', false, slotId, coords, heading)
            if type(result) == 'table' then
                drone.spawn(result.id, result.variant, coords, heading)
            end
        end,
    })
end)

exports('useDroneTablet', function()
    if not allowedJob() then return notify(text.notAllowed) end
    if placement.isActive() then return end
    if not drone.controlNearest() then
        notify(text.noDrone)
    end
end)

CreateThread(function()
    syncInteracts(GlobalState[STATE_KEY])
    onWeapon(cache.weapon)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end
    placement.cancel()
    drone.shutdown()
    infoUI.remove(HINT_ID)
    for id, entity in pairs(deploying) do
        deploying[id] = nil
        deleteLocal(entity)
    end
    for id in pairs(interacts) do
        exports.rhd_interact:removeCoords(INTERACT_PREFIX .. id)
    end
end)
