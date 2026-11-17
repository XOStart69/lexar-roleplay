local explosiveAttempt = {}
local trackedTrucks = {}
local blips = {}

local config = require 'resource.illegal_activity.gruppe.config'
local progressTimer = require 'modules.scaleformsUI.timerBars.bars.progressTimerBar'
local entityHandler = require 'modules.entityStateHandler.client'
local blipModule = require 'modules.blipHandle.client'

local maxC4Fails = config.c4_mechanic.maxFails
local nodeRadius = config.spawn.nodeRadius
local nodeTries = config.spawn.nodeTries
local spotClearance = 5.0
local workAnimDict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@'
local workAnimClip = 'machinic_loop_mechandplayer'
local driveTaskHash = 0x93A5526E

local explosionTimer = progressTimer:new(
    "Explosion in", {r = 112, g = 25, b = 25, a = 255}, {r = 224, g = 50, b = 50, a = 255}, 0, 0
)

explosionTimer:setEnabled(false)

---@param netId number
---@return number
local function getEntity(netId)
    return NetworkDoesEntityExistWithNetworkId(netId) and NetworkGetEntityFromNetworkId(netId) or 0
end

local function applyGuardCombat(guard)
    SetPedSuffersCriticalHits(guard, false)
    SetPedFleeAttributes(guard, 0, false)
    SetPedCombatAttributes(guard, 46, true)
    SetPedCombatAbility(guard, 2)
    SetPedCombatMovement(guard, 2)
    SetPedCanBeShotInVehicle(guard, false)
    SetPedAsCop(guard, true)
    SetPedAccuracy(guard, 100)
    SetPedCombatRange(guard, 2)
    SetPedKeepTask(guard, true)
    SetPedAlertness(guard, 3)
    SetEntityProofs(guard, false, false, false, true, false, false, false, false)
    SetPedCanRagdollFromPlayerImpact(guard, false)
end

local function createTruckGuards(model, vehicle, weapon)
    local guards = {}
    local hash = joaat(model)

    local ok = pcall(lib.requestModel, hash, 5000)
    if not ok then return guards end

    for seat = -1, 2 do
        local guard = CreatePedInsideVehicle(vehicle, 26, hash, seat, true, true)

        local exists = pcall(lib.waitFor, function()
            if DoesEntityExist(guard) then return true end
        end, 'guard timeout', 3000)

        if exists then
            SetEntityAsMissionEntity(guard, true, true)
            SetPedArmour(guard, 100)
            GiveWeaponToPed(guard, joaat(weapon), 500, false, true)
            applyGuardCombat(guard)
            guards[#guards + 1] = guard
        else
            pcall(DeleteEntity, guard)
        end
    end

    SetModelAsNoLongerNeeded(hash)
    return guards
end

---@param spots vector4[]
---@return vector4?
local function findFreeSpot(spots)
    local IsAnyVehicleNearPoint = IsAnyVehicleNearPoint

    for i = 1, #spots do
        local point = spots[i]
        if not IsAnyVehicleNearPoint(point.x, point.y, point.z, spotClearance) then
            return point
        end
    end

    local GetNthClosestVehicleNodeWithHeading = GetNthClosestVehicleNodeWithHeading
    local mabs = math.abs

    for i = 1, #spots do
        local point = spots[i]
        local origin = point.xyz

        for n = 1, nodeTries do
            local found, pos, heading = GetNthClosestVehicleNodeWithHeading(point.x, point.y, point.z, n, 0, 3.0, 0)

            if found and #(pos - origin) <= nodeRadius and mabs(pos.z - point.z) < 8.0
                and not IsAnyVehicleNearPoint(pos.x, pos.y, pos.z, spotClearance) then
                return vector4(pos.x, pos.y, pos.z, heading)
            end
        end
    end
end

---@param model string
---@param spots vector4[]
---@param guardModel string
---@param weapon string
local function createTruck(model, spots, guardModel, weapon)
    local spot = findFreeSpot(spots)

    if not spot then
        return nil, 'blocked'
    end

    local hash = joaat(model)
    if not pcall(lib.requestModel, hash, 5000) then
        return nil, "model gagal di-load"
    end

    RequestCollisionAtCoord(spot.x, spot.y, spot.z)

    local vehicle = CreateVehicle(hash, spot.x, spot.y, spot.z + 0.5, spot.w, true, true)

    if not pcall(lib.waitFor, function()
        if DoesEntityExist(vehicle) then return true end
    end, 'truck timeout', 5000) then
        SetModelAsNoLongerNeeded(hash)
        return nil, "entity truk tidak terbentuk"
    end

    FreezeEntityPosition(vehicle, true)
    SetEntityAsMissionEntity(vehicle, true, true)
    SetEntityLoadCollisionFlag(vehicle, true, 1)

    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    SetNetworkIdExistsOnAllMachines(netId, true)
    SetNetworkIdCanMigrate(netId, true)

    pcall(lib.waitFor, function()
        if HasCollisionLoadedAroundEntity(vehicle) then return true end
    end, 'truck collision timeout', 3000)

    SetVehicleOnGroundProperly(vehicle)
    FreezeEntityPosition(vehicle, false)
    SetVehicleDoorsLocked(vehicle, 2)
    SetVehicleEngineOn(vehicle, true, true, false)
    SetVehicleHasBeenOwnedByPlayer(vehicle, true)
    SetModelAsNoLongerNeeded(hash)

    pcall(function() exports.LegacyFuel:SetFuel(vehicle, 100) end)

    local guards = createTruckGuards(guardModel, vehicle, weapon)

    if #guards == 0 then
        pcall(DeleteEntity, vehicle)
        return nil, "guard gagal dibuat"
    end

    return vehicle, guards
end

---@param second number
local function startExplosionTimer(second)
    if explosionTimer.enabled then
        return
    end

    local timeInMs = second * 1000
    explosionTimer:setPercentage(1.0)
    explosionTimer:setEnabled(true)

    CreateThread(function()
        local startTime = GetGameTimer()

        while explosionTimer.enabled do
            local progress = math.max(0.0, 1.0 - ((GetGameTimer() - startTime) / timeInMs))

            explosionTimer:setPercentage(progress)
            explosionTimer:draw(0)

            if progress <= 0.0 then
                break
            end

            Wait(0)
        end

        explosionTimer:setEnabled(false)
    end)
end

local function armExplosiveMinigame(vehicle)
    local netId = NetworkGetNetworkIdFromEntity(vehicle)

    TaskTurnPedToFaceEntity(cache.ped, vehicle, -1)
    FreezeEntityPosition(cache.ped, true)

    if pcall(lib.requestAnimDict, workAnimDict) then
        TaskPlayAnim(cache.ped, workAnimDict, workAnimClip, 8.0, -8.0, -1, 1, 0, false, false, false)
    end

    local success = exports.bl_ui:mineSweeper(3, {
        grid = 4,
        duration = 60000,
        target = 6,
        previewDuration = 2000
    })

    Wait(1500)
    ClearPedTasks(cache.ped)
    FreezeEntityPosition(cache.ped, false)
    RemoveAnimDict(workAnimDict)

    if success then
        local fuse = lib.callback.await('sm_gruppe:armC4', false, netId)

        if not fuse then
            return lib.notify({
                description = config.lang.c4_failed,
                type = 'error',
                duration = 8000
            })
        end

        explosiveAttempt[netId] = nil

        startExplosionTimer(fuse)

        return lib.notify({
            description = config.lang.c4_success,
            type = 'info',
            duration = 8000
        })
    end

    local attempts = (explosiveAttempt[netId] or 0) + 1

    if attempts >= maxC4Fails then
        TriggerServerEvent('sm_gruppe:removeC4')
        explosiveAttempt[netId] = nil

        return lib.notify({
            description = config.lang.c4_destroyed:format(maxC4Fails),
            type = 'error',
            duration = 8000
        })
    end

    explosiveAttempt[netId] = attempts

    lib.notify({
        description = config.lang.minigame_failed .. (maxC4Fails - attempts),
        type = 'error',
        duration = 8000
    })
end

CreateThread(function()
    ox_target:addGlobalVehicle({
        {
            name = 'arm_explosive',
            onSelect = function(data)
                if ox_inventory:GetItemCount('c4_bomb') < 1 then
                    return lib.notify({
                        description = config.lang.noc4,
                        type = 'error'
                    })
                end

                armExplosiveMinigame(data.entity)
            end,
            icon = 'fas fa-bomb',
            label = config.lang.arm,
            canInteract = function(entity)
                local state = Entity(entity).state
                if not (state.gruppe_truck and not state.gruppe_armed and not cache.vehicle and not IsEntityDead(entity)) then
                    return false
                end

                if IsVehicleStopped(entity) then
                    return true
                end

                local driver = GetPedInVehicleSeat(entity, -1)
                return driver == 0 or IsEntityDead(driver)
            end,
        },
        {
            name = 'loot_truck',
            onSelect = function(data)
                TriggerServerEvent('sm_gruppe:loot', NetworkGetNetworkIdFromEntity(data.entity))
            end,
            icon = 'fas fa-hand-holding-usd',
            label = config.lang.loot,
            canInteract = function(entity)
                local state = Entity(entity).state
                if not (state.gruppe_truck and not cache.vehicle) then
                    return false
                end
                return state.gruppe_exploded or IsEntityDead(entity) or not IsVehicleDriveable(entity, false)
            end,
        },
    })
end)

---@param truck number
---@param state table
---@return boolean
local function isEngaged(truck, state)
    if state.gruppe_armed then return true end
    if GetVehicleBodyHealth(truck) < 900.0 or GetVehicleEngineHealth(truck) < 900.0 then return true end

    local driver = GetPedInVehicleSeat(truck, -1)
    return driver == 0 or IsEntityDead(driver)
end

---@param truck number
---@param guards number[]
---@param configured table<number, boolean>
---@param engaged boolean
local function deployGuards(truck, guards, configured, engaged)
    if #(GetEntityCoords(truck) - GetEntityCoords(cache.ped)) > 60.0 then return end

    local stopped = engaged and IsVehicleStopped(truck)

    for i = 1, #guards do
        local guard = getEntity(guards[i])

        if guard ~= 0 and not IsEntityDead(guard) and NetworkHasControlOfEntity(guard) then
            if not configured[guard] then
                applyGuardCombat(guard)
                configured[guard] = true
            end

            if IsPedInAnyVehicle(guard, false) then
                if stopped and not GetIsTaskActive(guard, 2) then
                    ClearPedTasks(guard)
                    TaskLeaveVehicle(guard, truck, 0)
                end
            elseif not IsPedInCombat(guard, 0) then
                TaskCombatPed(guard, cache.ped, 0, 16)
            end
        end
    end
end

local function manageTruck(netId)
    if trackedTrucks[netId] then return end
    trackedTrucks[netId] = true

    CreateThread(function()
        local misses = 0
        local frozenWreck = false
        local configured = {}

        while true do
            local truck = getEntity(netId)

            if truck == 0 or not DoesEntityExist(truck) then
                misses = misses + 1
                if misses >= 5 then
                    break
                end
                Wait(3000)
            else
                misses = 0

                local state = Entity(truck).state
                local active = state.gruppe_truck
                local exploded = state.gruppe_exploded

                if not active and not exploded then
                    break
                end

                local owned = NetworkHasControlOfEntity(truck)

                if exploded then
                    if owned then
                        local anchor = state.gruppe_anchor

                        if anchor and #(GetEntityCoords(truck) - vector3(anchor.x, anchor.y, anchor.z)) > 4.0 then
                            SetEntityCoordsNoOffset(truck, anchor.x, anchor.y, anchor.z, false, false, false)
                            frozenWreck = false
                        end

                        if not frozenWreck then
                            FreezeEntityPosition(truck, true)
                            frozenWreck = true
                        end
                    else
                        frozenWreck = false
                    end
                elseif owned then
                    SetEntityLoadCollisionFlag(truck, true, 1)

                    local driver = GetPedInVehicleSeat(truck, -1)

                    if driver ~= 0 and not IsEntityDead(driver) and not GetIsTaskActive(driver, 2) then
                        if state.gruppe_armed then
                            TaskVehicleTempAction(driver, truck, 1, 2000)
                        elseif state.gruppe_destination and not IsEntityDead(truck) then
                            local destination = state.gruppe_destination

                            if #(GetEntityCoords(truck) - vector3(destination.x, destination.y, destination.z)) > 15.0 then
                                local status = GetScriptTaskStatus(driver, driveTaskHash)
                                if status ~= 0 and status ~= 1 then
                                    TaskVehicleDriveToCoord(driver, truck, destination.x, destination.y, destination.z, 50.0, 1, GetEntityModel(truck), 786603, 10, 1)
                                end
                            else
                                TriggerServerEvent('sm_gruppe:arrived', netId)
                            end
                        end
                    end
                end

                if active and state.gruppe_guards then
                    deployGuards(truck, state.gruppe_guards, configured, isEngaged(truck, state))
                end

                Wait(exploded and 3000 or 2000)
            end
        end

        trackedTrucks[netId] = nil
    end)
end

entityHandler.entityStateHandler('gruppe_truck', function(entity, netId, value)
    if not value then
        local blip = blips[netId]
        if blip then
            pcall(blip.remove, blip)
            blips[netId] = nil
        end
        return
    end

    if not blips[netId] then
        blips[netId] = blipModule:new({
            id = 'gruppe:' .. netId,
            entity = entity,
            sprite = 67,
            color = 1,
            scale = 1.0,
            label = config.lang.blip_initial,
            shortRange = false,
        })
    end

    manageTruck(netId)
end)

local spawningRoute = false

lib.callback.register('sm_gruppe:beginRoute', function(info)
    if spawningRoute then
        return false, 'spawn sebelumnya belum selesai'
    end

    local spots = info.spots
    if type(spots) ~= 'table' or #spots == 0 then
        return false, 'tidak ada titik spawn'
    end

    spawningRoute = true
    local okSpawn, vehicle, guards = pcall(createTruck, info.truck, spots, info.guard, info.weapon)
    spawningRoute = false

    if not okSpawn then
        return false, vehicle
    end

    if not vehicle then
        return false, guards
    end

    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    local guardNetIds = {}
    for i = 1, #guards do
        guardNetIds[i] = NetworkGetNetworkIdFromEntity(guards[i])
    end

    local finish = info.finish
    local state = Entity(vehicle).state
    state:set('gruppe_destination', { x = finish.x, y = finish.y, z = finish.z }, true)
    state:set('gruppe_guards', guardNetIds, true)
    state:set('gruppe_truck', true, true)

    return netId, guardNetIds
end)

RegisterNetEvent('sm_gruppe:doExplode', function(netId)
    local veh = getEntity(netId)
    if veh == 0 then return end

    if not NetworkHasControlOfEntity(veh) then
        NetworkRequestControlOfEntity(veh)
        local timeout = GetGameTimer() + 2000
        while not NetworkHasControlOfEntity(veh) and GetGameTimer() < timeout do
            Wait(10)
        end

        if not NetworkHasControlOfEntity(veh) then return end
    end

    NetworkExplodeVehicle(veh, true, false, false)
end)

lib.callback.register('sm_gruppe:lootProgress', function(netId)
    local vehicle = getEntity(netId)
    if vehicle == 0 then return false end

    TaskTurnPedToFaceEntity(cache.ped, vehicle, -1)
    FreezeEntityPosition(cache.ped, true)

    local success = lib.progressCircle({
        duration = 5500,
        position = 'bottom',
        label = 'Looting truck...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true,
        },
        anim = {
            dict = workAnimDict,
            clip = workAnimClip
        },
    })

    ClearPedTasks(cache.ped)
    FreezeEntityPosition(cache.ped, false)
    RemoveAnimDict(workAnimDict)

    return success
end)
