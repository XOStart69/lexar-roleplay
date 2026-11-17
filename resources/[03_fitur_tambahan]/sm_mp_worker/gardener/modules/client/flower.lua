local State = require 'gardener.modules.client.state'
local Sync = require 'gardener.modules.client.sync'
local utils = require 'modules.utils'

local Flower = {}

local flowerAreaIds = {}
local registeredFlowerNetIds = {}
local lastCamView = 0

local flowerCarryOffset = {
    pos = vec3(0.14746165909764, 0.33243878882189, 0.078867606286405),
    rot = vec3(0.0, -65.378203260751, 0.0),
}
local wateringcanCarryOffset = {
    pos = vec3(0.46942889685943, 0.054772647321097, -0.36672148125791),
    rot = vec3(0.0, 0.0, 85.360302535076),
}

local function rotationToDirection(rotation)
    local rad = math.pi / 180
    local adjZ = rotation.z * rad
    local adjX = rotation.x * rad
    return vec3(
        -math.sin(adjZ) * math.abs(math.cos(adjX)),
        math.cos(adjZ) * math.abs(math.cos(adjX)),
        math.sin(adjX)
    )
end

local function rayCastGameplayCamera(distance)
    local camCoord = GetGameplayCamCoord()
    local direction = rotationToDirection(GetGameplayCamRot(2))
    local destination = camCoord + direction * distance

    local rayHandle = StartShapeTestSweptSphere(camCoord.x, camCoord.y, camCoord.z,
        destination.x, destination.y, destination.z, 0.2, 339, cache.ped, 4)
    local _, hit, endCoords, _, entity = GetShapeTestResult(rayHandle)
    return hit, endCoords, entity
end

---@param hit boolean
---@param endCoords vector3
---@param surfaceNormal vector3
---@param materialHash number
---@return boolean
local function validateGround(hit, endCoords, surfaceNormal, materialHash)
    if not hit then return false end

    local ground = State.cfg.groundValidation
    if ground.useZBased then
        local heightDifference = endCoords.z - GetEntityCoords(cache.ped).z
        if math.abs(heightDifference) > ground.maxHeightDifference then
            return false
        end
        if ground.checkSlope and surfaceNormal and math.abs(1.0 - surfaceNormal.z) > ground.maxSlope then
            return false
        end
        return true
    end

    if ground.materialHashes[materialHash] then
        return true
    end
    return ground.allowUnknownSurfaces
end

local function checkGroundAtObject(object)
    local offsetCoords = GetOffsetFromEntityInWorldCoords(object, 0.0, 0.3, 0.0)
    local rayHandle = StartExpensiveSynchronousShapeTestLosProbe(
        offsetCoords.x, offsetCoords.y, offsetCoords.z + 0.5,
        offsetCoords.x, offsetCoords.y, offsetCoords.z - 0.5,
        1, 0, 4)
    local _, hit, endCoords, surfaceNormal, materialHash = GetShapeTestResultIncludingMaterial(rayHandle)
    return validateGround(hit, endCoords, surfaceNormal, materialHash)
end

local function canPlantAtPlayer()
    local playerCoords = GetEntityCoords(cache.ped)
    local rayHandle = StartExpensiveSynchronousShapeTestLosProbe(
        playerCoords.x, playerCoords.y, playerCoords.z,
        playerCoords.x, playerCoords.y, playerCoords.z - 2.0,
        1, 0, 4)
    local _, hit, endCoords, surfaceNormal, materialHash = GetShapeTestResultIncludingMaterial(rayHandle)

    local ground = State.cfg.groundValidation
    if ground.useZBased and ground.checkWater and hit then
        local hasWater, waterHeight = GetWaterHeight(playerCoords.x, playerCoords.y, playerCoords.z)
        if hasWater and waterHeight > endCoords.z - 0.3 then
            return false
        end
    end
    return validateGround(hit, endCoords, surfaceNormal, materialHash)
end

---@return boolean
local function isWateringHitFlower()
    local startPos = GetEntityCoords(cache.ped)
    local direction = rotationToDirection(GetGameplayCamRot(2))

    for i = 0, 20 do
        local samplePoint = startPos + direction * 7.0 * (i / 20)
        for _, flower in pairs(State.flowerObject) do
            if #(samplePoint - vec3(flower.coords.x, flower.coords.y, flower.coords.z)) < 2.0 then
                return true
            end
        end
    end
    return false
end

local function playWateringAnim()
    local playerPed = cache.ped
    utils.waitForAnim('weapon@w_sp_jerrycan')

    SetCurrentPedWeapon(playerPed, joaat('WEAPON_UNARMED'), false)
    DetachEntity(State.playerHandObject.wateringcan, false, false)
    AttachEntityToEntity(State.playerHandObject.wateringcan, playerPed,
        GetPedBoneIndex(playerPed, 18905), 0.08, -0.02, 0.3, -10.0, 80.0, 90.0,
        true, true, false, false, 2, true)

    TaskPlayAnim(playerPed, 'weapon@w_sp_jerrycan', 'fire', 8.0, -8.0, 4000, 49, 0, false, false, false)

    UseParticleFxAssetNextCall('core')
    local waterParticle = StartNetworkedParticleFxLoopedOnEntityBone('ent_ray_heli_aprtmnt_water',
        playerPed, 0.045, 0.0, -0.1, 0.0, 0.0, 0.0, GetPedBoneIndex(playerPed, 4089), 1.0, true, true, true)

    Wait(4000)

    StopParticleFxLooped(waterParticle, false)
    ClearPedTasks(playerPed)
    RemoveAnimDict('weapon@w_sp_jerrycan')
end

local function missionTruckNearby()
    if not State.mission then return false end

    local playerCoords = GetEntityCoords(cache.ped)
    for _, truck in ipairs(State.mission.trucks) do
        local vehicle = NetworkDoesNetworkIdExist(truck.netId) and NetToVeh(truck.netId) or 0
        if vehicle ~= 0 and #(playerCoords - GetEntityCoords(vehicle)) <= 5.0 then
            return true
        end
    end
    return false
end

local function plantMissionRemaining()
    local task = State.getTask('plantflower')
    return task ~= nil and task.jobCount > 0 and task.madeAmount < task.jobCount
end

local function cancelPlacement()
    if State.flowerState.object then
        SetEntityDrawOutline(State.flowerState.object, false)
        DeleteObject(State.flowerState.object)
    end
    State.flowerState.object = false
    State.flowerState.Coords = false
    State.flowerState.PlacingObject = false

    local models = State.cfg.models.flower
    local modelName = models[math.random(#models)]
    local object = utils.createProp(modelName, GetEntityCoords(cache.ped), true)
    if not object then return end

    State.playerHandObject.flower = object
    State.isPlacingObject = true
    AttachEntityToEntity(object, cache.ped, -1, flowerCarryOffset.pos.x, flowerCarryOffset.pos.y,
        flowerCarryOffset.pos.z, flowerCarryOffset.rot.x, flowerCarryOffset.rot.y, flowerCarryOffset.rot.z,
        true, true, false, true, 1, true)
    State.flowerState.model = modelName
end

local function placeSpawnedObject()
    if not State.flowerState.object or not State.flowerState.Coords then return end

    SetEntityDrawOutline(State.flowerState.object, false)
    local finalCoords = State.flowerState.Coords --[[@as vector3]]

    DeleteObject(State.flowerState.object)
    State.flowerState.PlacingObject = false
    State.flowerState.object = false
    State.flowerState.Coords = false
    State.flowerState.isPlant = false

    local playerPed = cache.ped
    TaskTurnPedToFaceCoord(playerPed, finalCoords.x, finalCoords.y, finalCoords.z, 3000)
    TaskStartScenarioInPlace(playerPed, 'WORLD_HUMAN_GARDENER_PLANT', 0, true)
    FreezeEntityPosition(playerPed, true)
    Wait(15000)
    FreezeEntityPosition(playerPed, false)
    ClearPedTasks(playerPed)

    local zOffset = State.flowerState.model == 'vw_prop_flowers_vase_03a' and -0.5 or -0.1
    local spawnCoords = vec3(finalCoords.x, finalCoords.y, finalCoords.z + zOffset)
    local object = utils.createProp(State.flowerState.model, spawnCoords, true)
    if not object then return end

    local id = #State.flowerObject + 1
    State.flowerObject[id] = {
        objectNetId = NetworkGetNetworkIdFromEntity(object),
        object = object,
        coords = spawnCoords,
        id = id,
        watered = false,
        process = false,
    }

    Sync.updateMissionTable('flowerObject', State.flowerObject)
    Sync.updateJobTask('plantflower')
    SetEntityHeading(object, 0.0)
    FreezeEntityPosition(object, true)
    SetEntityCollision(object, false, false)
    Flower.refreshInteractions()
end

local function startPlacement()
    State.flowerState.PlacingObject = true
    local ghost = utils.createProp(State.flowerState.model, vec3(1.0, 1.0, -0.5), false)
    if not ghost then
        State.flowerState.PlacingObject = false
        return
    end

    State.flowerState.object = ghost
    SetEntityHeading(ghost, 0.0)
    SetEntityAlpha(ghost, 150, false)
    SetEntityCollision(ghost, false, false)
    FreezeEntityPosition(ghost, true)
    SetEntityDrawOutline(ghost, true)

    local zOffset = State.flowerState.model == 'vw_prop_flowers_vase_03a' and -0.5 or -0.2

    CreateThread(function()
        while State.flowerState.PlacingObject and State.getStartJob() do
            local validGround = checkGroundAtObject(ghost)
            local hit, coords, entity = rayCastGameplayCamera(5.0)
            State.flowerState.Coords = coords

            local blocked = not hit or #(GetEntityCoords(cache.ped) - coords) > 1.9
            if not blocked and entity ~= 0 and DoesEntityExist(entity) then
                blocked = IsEntityTouchingEntity(ghost, entity)
            end

            if hit then
                SetEntityCoords(ghost, coords.x, coords.y, coords.z + zOffset, false, false, false, false)
            end

            SetEntityDrawOutline(ghost, true)
            if not blocked and validGround then
                SetEntityDrawOutlineColor(0, 240, 0, 100)
            else
                SetEntityDrawOutlineColor(200, 0, 0, 100)
            end

            if IsControlJustPressed(0, 74) then
                State.isPlacingObject = true
                SetFollowPedCamViewMode(lastCamView)
                lastCamView = 0
                cancelPlacement()
            end

            if not blocked and validGround and IsControlJustPressed(0, 38) then
                State.isPlacingObject = false
                SetFollowPedCamViewMode(lastCamView)
                lastCamView = 0
                placeSpawnedObject()
                ClearPedTasksImmediately(cache.ped)
            end

            Wait(0)
        end
    end)
end

---@param enable boolean
function Flower.toggleAreaInteractions(enable)
    if not enable then
        for i = 1, #flowerAreaIds do
            exports.rhd_interact:removeCoords(flowerAreaIds[i])
        end
        flowerAreaIds = {}
        return
    end

    if #flowerAreaIds > 0 or not State.mission then return end

    for key, area in ipairs(State.mission.flowerArea) do
        local coordsId = ('sm_gardener:flowerArea_%s'):format(key)
        exports.rhd_interact:addCoords({
            id = coordsId,
            coords = vec3(area.coords.x, area.coords.y, area.coords.z),
            options = {
                {
                    name = coordsId,
                    label = 'Tanam Bunga',
                    icon = 'fas fa-seedling',
                    distance = area.area,
                    pointDistance = area.area + 5.0,
                    canInteract = function()
                        if not State.isTaskActive('plantflower') then return false end
                        if State.playerHandObject.flower == false or State.flowerState.PlacingObject then
                            return false
                        end
                        if State.isInteracting or not plantMissionRemaining() then return false end
                        return not missionTruckNearby()
                    end,
                    onSelect = function()
                        if State.flowerState.PlacingObject then return end
                        if State.isPlacingObject then
                            State.isPlacingObject = false
                            ClearPedTasksImmediately(cache.ped)
                        end
                        if not canPlantAtPlayer() then return end

                        if DoesEntityExist(State.playerHandObject.flower) then
                            DeleteObject(State.playerHandObject.flower)
                            State.playerHandObject.flower = false
                        end
                        lastCamView = GetFollowPedCamViewMode()
                        SetFollowPedCamViewMode(4)
                        State.flowerState.isPlant = true
                        startPlacement()
                    end,
                },
            },
        })
        flowerAreaIds[#flowerAreaIds + 1] = coordsId
    end
end

---@param model string | false
function Flower.startPlanting(model)
    if not model then
        State.stateThread.plantFlowerThreadActive = false
        return
    end
    if not State.getStartJob() then return end

    State.stateThread.plantFlowerThreadActive = true
    State.flowerState.model = model
    Flower.toggleAreaInteractions(true)
end

local function findFlowerIndexByNetId(netId)
    for i, flower in pairs(State.flowerObject) do
        if flower.objectNetId == netId then
            return i
        end
    end
end

---@param index number
local function waterFlower(index)
    local flower = State.flowerObject[index]
    if not flower then return end

    State.isPlacingWateringcan = false
    ClearPedTasksImmediately(cache.ped)

    flower.process = true
    Sync.updateMissionTable('flowerObject', State.flowerObject)

    playWateringAnim()

    flower.process = false
    if isWateringHitFlower() then
        flower.watered = true
        Sync.updateBonusJobTask('wateringcan')
    else
        State.notify('Siramanmu tidak mengenai bunga', 'error')
    end
    Sync.updateMissionTable('flowerObject', State.flowerObject)

    State.isPlacingWateringcan = true
    AttachEntityToEntity(State.playerHandObject.wateringcan, cache.ped, -1, wateringcanCarryOffset.pos.x,
        wateringcanCarryOffset.pos.y, wateringcanCarryOffset.pos.z, wateringcanCarryOffset.rot.x,
        wateringcanCarryOffset.rot.y, wateringcanCarryOffset.rot.z, true, true, false, true, 1, true)
end

function Flower.refreshInteractions()
    local validNetIds = {}
    for _, flower in pairs(State.flowerObject) do
        if flower.objectNetId and NetworkDoesNetworkIdExist(flower.objectNetId) then
            validNetIds[flower.objectNetId] = true
        end
    end

    for netId in pairs(registeredFlowerNetIds) do
        if not validNetIds[netId] then
            exports.rhd_interact:removeEntity(netId)
            registeredFlowerNetIds[netId] = nil
        end
    end

    for netId in pairs(validNetIds) do
        if not registeredFlowerNetIds[netId] then
            exports.rhd_interact:addEntity(netId, {
                {
                    name = 'sm_gardener:flower:water',
                    label = 'Siram Bunga',
                    icon = 'fas fa-droplet',
                    offset = vec(0.0, 0.0, 1.0),
                    distance = 2.0,
                    pointDistance = 5.0,
                    canInteract = function()
                        local index = findFlowerIndexByNetId(netId)
                        local flower = index and State.flowerObject[index]
                        return flower and not flower.watered and not flower.process
                            and State.playerHandObject.wateringcan ~= false and not State.isInteracting
                    end,
                    onSelect = function()
                        local index = findFlowerIndexByNetId(netId)
                        if index then
                            waterFlower(index)
                        end
                    end,
                },
            })
            registeredFlowerNetIds[netId] = true
        end
    end
end

function Flower.clearInteractions()
    for netId in pairs(registeredFlowerNetIds) do
        exports.rhd_interact:removeEntity(netId)
    end
    registeredFlowerNetIds = {}
end

---@param enable boolean
function Flower.setWateringMode(enable)
    State.stateThread.wateringcanThreadActive = enable
    if enable then
        Flower.refreshInteractions()
    end
end

function Flower.teardown()
    Flower.toggleAreaInteractions(false)
    Flower.clearInteractions()

    if State.flowerState.object and DoesEntityExist(State.flowerState.object) then
        DeleteObject(State.flowerState.object)
    end
    State.resetFlowerState()
end

return Flower
