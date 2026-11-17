local State = require 'gardener.modules.client.state'
local Util = require 'gardener.modules.client.util'
local Sync = require 'gardener.modules.client.sync'
local Branch = require 'gardener.modules.client.branch'
local Flower = require 'gardener.modules.client.flower'
local utils = require 'modules.utils'

local Vehicle = {}

---@type string[]?
local vehicleOptionNames = nil
local deliveryThread = false

local vehicleExtras = {
    trimmer = 7,
    wateringcan = 8,
    ladder = 9,
}

local trimmerAttach = {
    bone = 57005,
    pos = vec3(0.09, 0.02, 0.01),
    rot = vec3(-121.0, 181.0, 187.0),
}
local flowerCarryOffset = {
    pos = vec3(0.14746165909764, 0.33243878882189, 0.078867606286405),
    rot = vec3(0.0, -65.378203260751, 0.0),
}
local wateringcanCarryOffset = {
    pos = vec3(0.46942889685943, 0.054772647321097, -0.36672148125791),
    rot = vec3(0.0, 0.0, 85.360302535076),
}
local ladderCarryOffset = {
    pos = vec3(-0.0019488132165861, 0.36719249267956, 0.13732293274839),
    rot = vec3(172.43208872756, 70.747994138044, -135.06240470822),
}

local function onFootAndIdle()
    return not cache.vehicle and not State.isInteracting
end

local function endInteractionDelayed()
    SetTimeout(400, State.endInteraction)
end

---@param truck table
local function putBackItems(truck)
    for itemName, handObject in pairs(State.playerHandObject) do
        if handObject then
            if not Sync.requestVehicleItem(truck.plate, itemName, 'putback') then
                State.notify('Kamu masih membawa barang lain', 'error')
                return
            end

            State.startInteraction()
            if not Util.playAnim('putToVehicle') then return end

            DeleteEntity(handObject)
            State.playerHandObject[itemName] = false
            Sync.updateVehicleItems(truck.plate, itemName, true)

            if itemName == 'flower' then
                Flower.startPlanting(false)
                State.isPlacingObject = false
                ClearPedTasksImmediately(cache.ped)
            elseif itemName == 'ladder' then
                State.isPlacingLadder = false
            elseif itemName == 'wateringcan' then
                State.isPlacingWateringcan = false
                Flower.setWateringMode(false)
            end

            local extra = vehicleExtras[itemName]
            if extra then
                Sync.updateVehicleExtra(truck.plate, extra, false)
            end

            endInteractionDelayed()
        end
    end
end

---@param truck table
local function takeLadder(truck)
    if not Sync.requestVehicleItem(truck.plate, 'ladder', 'take') then return end

    State.startInteraction()
    if not Util.playAnim('takeFromVehicle') then return end

    Sync.updateVehicleItems(truck.plate, 'ladder', false)
    local object = utils.createProp(State.cfg.models.vehicleLadder, GetEntityCoords(cache.ped), true)
    if not object then
        Sync.updateVehicleItems(truck.plate, 'ladder', true)
        State.endInteraction()
        return
    end

    State.playerHandObject.ladder = object
    SetEntityCollision(object, false, false)
    State.isPlacingLadder = true
    AttachEntityToEntity(object, cache.ped, -1, ladderCarryOffset.pos.x, ladderCarryOffset.pos.y,
        ladderCarryOffset.pos.z, ladderCarryOffset.rot.x, ladderCarryOffset.rot.y, ladderCarryOffset.rot.z,
        true, true, false, true, 1, true)
    Sync.updateVehicleExtra(truck.plate, vehicleExtras.ladder, true)
    endInteractionDelayed()
end

---@param truck table
local function takeTrimmer(truck)
    if not Sync.requestVehicleItem(truck.plate, 'trimmer', 'take') then return end

    State.startInteraction()
    if not Util.playAnim('takeFromVehicle') then return end

    Sync.updateVehicleItems(truck.plate, 'trimmer', false)
    local object = utils.createProp('prop_hedge_trimmer_01', GetEntityCoords(cache.ped), true)
    if not object then
        Sync.updateVehicleItems(truck.plate, 'trimmer', true)
        State.endInteraction()
        return
    end

    State.playerHandObject.trimmer = object
    AttachEntityToEntity(object, cache.ped, GetPedBoneIndex(cache.ped, trimmerAttach.bone),
        trimmerAttach.pos.x, trimmerAttach.pos.y, trimmerAttach.pos.z,
        trimmerAttach.rot.x, trimmerAttach.rot.y, trimmerAttach.rot.z, true, true, false, true, 1, true)
    Sync.updateVehicleExtra(truck.plate, vehicleExtras.trimmer, true)
    endInteractionDelayed()
end

---@param truck table
local function takeFlower(truck)
    if not Sync.requestVehicleItem(truck.plate, 'flower', 'take') then return end

    State.startInteraction()
    if not Util.playAnim('takeFromVehicle') then return end

    Sync.updateVehicleItems(truck.plate, 'flower', false)
    local models = State.cfg.models.flower
    local modelName = models[math.random(#models)]
    local object = utils.createProp(modelName, GetEntityCoords(cache.ped), true)
    if not object then
        Sync.updateVehicleItems(truck.plate, 'flower', true)
        State.endInteraction()
        return
    end

    State.playerHandObject.flower = object
    State.isPlacingObject = true
    AttachEntityToEntity(object, cache.ped, -1, flowerCarryOffset.pos.x, flowerCarryOffset.pos.y,
        flowerCarryOffset.pos.z, flowerCarryOffset.rot.x, flowerCarryOffset.rot.y, flowerCarryOffset.rot.z,
        true, true, false, true, 1, true)
    Flower.startPlanting(modelName)
    endInteractionDelayed()
end

---@param truck table
local function takeWateringcan(truck)
    if not Sync.requestVehicleItem(truck.plate, 'wateringcan', 'take') then return end

    State.startInteraction()
    if not Util.playAnim('takeFromVehicle') then return end

    Sync.updateVehicleItems(truck.plate, 'wateringcan', false)
    local object = utils.createProp('prop_wateringcan', GetEntityCoords(cache.ped), true)
    if not object then
        Sync.updateVehicleItems(truck.plate, 'wateringcan', true)
        State.endInteraction()
        return
    end

    State.playerHandObject.wateringcan = object
    State.isPlacingWateringcan = true
    AttachEntityToEntity(object, cache.ped, -1, wateringcanCarryOffset.pos.x, wateringcanCarryOffset.pos.y,
        wateringcanCarryOffset.pos.z, wateringcanCarryOffset.rot.x, wateringcanCarryOffset.rot.y,
        wateringcanCarryOffset.rot.z, true, true, false, true, 1, true)
    Sync.updateVehicleExtra(truck.plate, vehicleExtras.wateringcan, true)
    Flower.setWateringMode(true)
    endInteractionDelayed()
end

---@param truck table
local function putBranchToTruck(truck)
    local handBranch = State.playerHandObject.branch
    if not handBranch then return end

    local branchNetId = NetworkGetNetworkIdFromEntity(handBranch)
    local branchIndex
    for index, branch in ipairs(State.branchObject) do
        if branch.objectNetId == branchNetId and not branch.inVehicle then
            branchIndex = index
            break
        end
    end
    if not branchIndex then return end

    if DoesEntityExist(handBranch) then
        DeleteEntity(handBranch)
    end
    State.playerHandObject.branch = false
    State.isPlacingObject = false
    ClearPedTasksImmediately(cache.ped)
    Sync.updateJobTask('branch')
    Sync.updateBonusJobTask('takeBranch')

    local branch = State.branchObject[branchIndex]
    local branchCount = Sync.getVehicleBranchCount(truck.plate)

    if branchCount > 2 then
        table.remove(State.branchObject, branchIndex)
        Sync.updateMissionTable('branchObject', State.branchObject)
        Branch.refreshInteractions()
        return
    end

    local vehicle = NetworkDoesNetworkIdExist(truck.netId) and NetToVeh(truck.netId) or 0
    if vehicle == 0 then return end

    local object = utils.createProp(branch.prop, GetEntityCoords(vehicle), true)
    if not object then return end

    local isBranchProp = false
    for _, name in ipairs(State.objectTable.branch) do
        if name == branch.prop then
            isBranchProp = true
            break
        end
    end

    local offset = vec3(-1.1, -1.9 + (branchCount - 1) * 0.4, 0.3)
    local rotation = isBranchProp and vec3(90.0, 0.0, 90.0) or vec3(0.0, 90.0, 0.0)
    AttachEntityToEntity(object, vehicle, 73, offset.x, offset.y, offset.z,
        rotation.x, rotation.y, rotation.z, false, false, false, false, 1, true)

    branch.object = object
    branch.objectNetId = NetworkGetNetworkIdFromEntity(object)
    branch.inVehicle = true
    Sync.updateMissionTable('branchObject', State.branchObject)
    Sync.updateVehicleBranch(truck.plate)
    Branch.refreshInteractions()
end

local function buildTruckOptions()
    local backOffset = vec3(0.0, -4.8, 0.0)
    local rightOffset = vec3(1.3, -2.3, 0.2)
    local leftOffset = vec3(-1.3, -2.3, 0.2)

    return {
        {
            name = 'sm_gardener:veh:door',
            label = 'Buka/Tutup Bagasi',
            icon = 'fas fa-car',
            offset = backOffset,
            absoluteOffset = true,
            distance = 2.0,
            canInteract = function(entity)
                return State.getMissionTruck(entity) ~= nil and onFootAndIdle()
            end,
            onSelect = function(data)
                if not data.entity then return end
                State.startInteraction()
                endInteractionDelayed()

                if NetworkGetEntityOwner(data.entity) == cache.playerId then
                    Util.toggleVehicleDoor(data.entity, 5)
                else
                    Sync.toggleEntityDoor(VehToNet(data.entity), 5)
                end
            end,
        },
        {
            name = 'sm_gardener:veh:backPut',
            label = 'Kembalikan Barang',
            icon = 'fas fa-car',
            offset = backOffset,
            absoluteOffset = true,
            distance = 2.0,
            canInteract = function(entity)
                return State.getMissionTruck(entity) ~= nil and onFootAndIdle()
                    and State.isCarryingAnything() and not State.playerHandObject.branch
            end,
            onSelect = function(data)
                local truck = data.entity and State.getMissionTruck(data.entity)
                if not truck then return end
                putBackItems(truck)
            end,
        },
        {
            name = 'sm_gardener:veh:putBranch',
            label = 'Taruh Dahan',
            icon = 'fas fa-car',
            offset = backOffset,
            absoluteOffset = true,
            distance = 2.0,
            canInteract = function(entity)
                return State.getMissionTruck(entity) ~= nil and onFootAndIdle()
                    and State.playerHandObject.branch ~= false
            end,
            onSelect = function(data)
                local truck = data.entity and State.getMissionTruck(data.entity)
                if not truck then return end
                State.startInteraction()
                if not Util.playAnim('putToVehicle') then return end
                putBranchToTruck(truck)
                endInteractionDelayed()
            end,
        },
        {
            name = 'sm_gardener:veh:takeLadder',
            label = 'Ambil Tangga',
            icon = 'fas fa-car',
            offset = rightOffset,
            absoluteOffset = true,
            distance = 2.0,
            canInteract = function(entity)
                return State.getMissionTruck(entity) ~= nil and State.hasTaskReached('branch')
                    and onFootAndIdle() and not State.isCarryingAnything()
            end,
            onSelect = function(data)
                local truck = data.entity and State.getMissionTruck(data.entity)
                if not truck then return end
                takeLadder(truck)
            end,
        },
        {
            name = 'sm_gardener:veh:takeTrimmer',
            label = 'Ambil Trimmer',
            icon = 'fas fa-car',
            offset = leftOffset,
            absoluteOffset = true,
            distance = 2.0,
            canInteract = function(entity)
                return State.getMissionTruck(entity) ~= nil
                    and (State.hasTaskReached('prunegrass') or State.hasTaskReached('branch'))
                    and onFootAndIdle() and not State.isCarryingAnything()
            end,
            onSelect = function(data)
                local truck = data.entity and State.getMissionTruck(data.entity)
                if not truck then return end
                takeTrimmer(truck)
            end,
        },
        {
            name = 'sm_gardener:veh:takeFlower',
            label = 'Ambil Bunga',
            icon = 'fas fa-car',
            offset = leftOffset,
            absoluteOffset = true,
            distance = 2.0,
            canInteract = function(entity)
                return State.getMissionTruck(entity) ~= nil and State.hasTaskReached('plantflower')
                    and onFootAndIdle() and not State.isCarryingAnything()
            end,
            onSelect = function(data)
                local truck = data.entity and State.getMissionTruck(data.entity)
                if not truck then return end
                takeFlower(truck)
            end,
        },
        {
            name = 'sm_gardener:veh:takeWateringcan',
            label = 'Ambil Penyiram',
            icon = 'fas fa-car',
            offset = leftOffset,
            absoluteOffset = true,
            distance = 2.0,
            canInteract = function(entity)
                return State.getMissionTruck(entity) ~= nil and State.hasTaskReached('plantflower')
                    and onFootAndIdle() and not State.isCarryingAnything()
            end,
            onSelect = function(data)
                local truck = data.entity and State.getMissionTruck(data.entity)
                if not truck then return end
                takeWateringcan(truck)
            end,
        },
    }
end

local function getPairedTruck(mowerId)
    if not State.mission then return nil end
    for _, truck in ipairs(State.mission.trucks) do
        if truck.id == mowerId then
            return truck
        end
    end
end

local function buildMowerOptions()
    local function getMowerContext(entity)
        local mower = State.getMissionMower(entity)
        if not mower then return nil end

        local truck = getPairedTruck(mower.id)
        local truckEntity = truck and NetworkDoesNetworkIdExist(truck.netId) and NetToVeh(truck.netId) or 0
        if truckEntity == 0 or not DoesEntityExist(truckEntity) then return nil end

        return mower, truck, truckEntity
    end

    local function nearTruckAndControllable(entity, truckEntity)
        if #(GetEntityCoords(truckEntity) - GetEntityCoords(entity)) > 4.0 then return false end
        local currentVehicle = cache.vehicle
        return (not currentVehicle or currentVehicle == entity) and not State.isInteracting
    end

    return {
        {
            name = 'sm_gardener:mower:detach',
            label = 'Lepas Mesin Pemotong',
            icon = 'fas fa-car',
            distance = 4.0,
            canInteract = function(entity)
                local mower, _, truckEntity = getMowerContext(entity)
                if not mower or not truckEntity then return false end
                return nearTruckAndControllable(entity, truckEntity)
                    and IsEntityAttachedToEntity(entity, truckEntity)
            end,
            onSelect = function(data)
                local mower = data.entity and State.getMissionMower(data.entity)
                if not mower then return end
                State.startInteraction()
                endInteractionDelayed()
                Sync.detachMower(mower.netId)
            end,
        },
        {
            name = 'sm_gardener:mower:attach',
            label = 'Pasang Mesin Pemotong',
            icon = 'fas fa-car',
            distance = 4.0,
            canInteract = function(entity)
                local mower, _, truckEntity = getMowerContext(entity)
                if not mower or not truckEntity then return false end
                return nearTruckAndControllable(entity, truckEntity)
                    and not IsEntityAttachedToEntity(entity, truckEntity)
            end,
            onSelect = function(data)
                local mower = data.entity and State.getMissionMower(data.entity)
                local truck = mower and getPairedTruck(mower.id)
                if not mower or not truck then return end
                State.startInteraction()
                endInteractionDelayed()
                Sync.attachMower(mower.netId, truck.netId)
            end,
        },
    }
end

function Vehicle.registerInteractions()
    if vehicleOptionNames or not State.mission then return end

    local options = buildTruckOptions()
    for _, option in ipairs(buildMowerOptions()) do
        options[#options + 1] = option
    end

    vehicleOptionNames = {}
    for i = 1, #options do
        vehicleOptionNames[i] = options[i].name
    end
    exports.ox_target:addGlobalVehicle(options)
end

function Vehicle.clearInteractions()
    if not vehicleOptionNames then return end
    exports.ox_target:removeGlobalVehicle(vehicleOptionNames)
    vehicleOptionNames = nil
end

function Vehicle.setup()
    Vehicle.registerInteractions()

    CreateThread(function()
        local deadline = GetGameTimer() + 30000

        while State.getStartJob() and GetGameTimer() < deadline do
            local allStreamed = true
            for _, list in ipairs({ State.mission.trucks, State.mission.mowers }) do
                for _, data in ipairs(list) do
                    if not NetworkDoesNetworkIdExist(data.netId) then
                        allStreamed = false
                        break
                    end
                end
                if not allStreamed then break end
            end

            if allStreamed then break end
            Wait(1000)
        end

        if State.getStartJob() and State.isOwner() then
            for _, mower in ipairs(State.mission.mowers) do
                for _, truck in ipairs(State.mission.trucks) do
                    if truck.id == mower.id then
                        Sync.attachMower(mower.netId, truck.netId)
                        break
                    end
                end
            end
        end
    end)
end

---@param enable boolean
function Vehicle.toggleDelivery(enable)
    if not enable then
        deliveryThread = false
        return
    end

    if deliveryThread or not State.mission then return end
    deliveryThread = true

    local deliverCoords = State.mission.deliverCoords

    CreateThread(function()
        while deliveryThread and State.getStartJob() do
            Wait(0)

            local playerCoords = GetEntityCoords(cache.ped)
            if #(playerCoords - deliverCoords) >= 10.0 or State.isInteracting then
                Wait(500)
                goto continue
            end

            local inMissionVehicle = cache.vehicle and State.isMissionVehicle(cache.vehicle) or false
            local allVehiclesInZone = true

            for _, list in ipairs({ State.mission.trucks, State.mission.mowers }) do
                for _, data in ipairs(list) do
                    local vehicle = NetworkDoesNetworkIdExist(data.netId) and NetToVeh(data.netId) or 0
                    if vehicle ~= 0 and not IsEntityAttached(vehicle)
                        and #(GetEntityCoords(vehicle) - deliverCoords) > 10.0 then
                        allVehiclesInZone = false
                        break
                    end
                end
                if not allVehiclesInZone then break end
            end

            if inMissionVehicle and allVehiclesInZone then
                Util.drawText3D(deliverCoords + vec3(0.0, 0.0, 1.5), '[E] - Serahkan Kendaraan')

                if IsControlJustReleased(0, 38) then
                    State.startInteraction()
                    TriggerServerEvent(State.event('server:completeJob'))
                    SetTimeout(1000, State.endInteraction)
                end
            elseif not allVehiclesInZone then
                Util.drawText3D(deliverCoords + vec3(0.0, 0.0, 1.5),
                    'Semua kendaraan harus berada di dekat titik penyerahan')
            else
                Util.drawText3D(deliverCoords + vec3(0.0, 0.0, 1.5),
                    'Kamu harus berada di kendaraan kerja untuk menyerahkan')
            end

            ::continue::
        end
        deliveryThread = false
    end)
end

---@param netId number
---@param door number
function Vehicle.onToggleEntityDoor(netId, door)
    local vehicle = NetToVeh(netId)
    if DoesEntityExist(vehicle) then
        Util.toggleVehicleDoor(vehicle, door)
    end
end

---@param plate string
---@param extra number
---@param taken boolean
function Vehicle.onUpdateVehicleExtra(plate, extra, taken)
    if not State.mission then return end

    for _, truck in ipairs(State.mission.trucks) do
        if truck.plate == plate and NetworkDoesNetworkIdExist(truck.netId) then
            local vehicle = NetToVeh(truck.netId)
            if DoesEntityExist(vehicle) then
                SetVehicleExtra(vehicle, extra, taken)
            end
        end
    end
end

---@param mowerNetId number
function Vehicle.onDetachMower(mowerNetId)
    local mower = NetworkDoesNetworkIdExist(mowerNetId) and NetToVeh(mowerNetId) or 0
    if mower == 0 then return end

    local attempt = 0
    while (IsEntityAttached(mower) or IsEntityAttachedToAnyVehicle(mower)) and attempt < 50 do
        NetworkRequestControlOfEntity(mower)
        if NetworkGetEntityOwner(mower) == cache.playerId then
            DetachEntity(mower, false, false)
        end
        attempt += 1
        Wait(100)
    end
end

---@param mowerNetId number
---@param truckNetId number
---@param clearExtras? boolean
function Vehicle.onAttachMower(mowerNetId, truckNetId, clearExtras)
    local mower = NetworkDoesNetworkIdExist(mowerNetId) and NetToVeh(mowerNetId) or 0
    local truck = NetworkDoesNetworkIdExist(truckNetId) and NetToVeh(truckNetId) or 0
    if mower == 0 or truck == 0 then return end

    local function attach()
        AttachEntityToEntity(mower, truck, 73, 0.0, -3.8, 0.7, 0.0, 0.0, 0.0, false, false, true, false, 2, true)
    end

    NetworkRequestControlOfEntity(mower)
    NetworkRequestControlOfEntity(truck)
    attach()

    if clearExtras then
        for extra = 6, 9 do
            SetVehicleExtra(truck, extra, false)
        end
    end

    local attempt = 0
    while not IsEntityAttachedToEntity(mower, truck) and attempt < 50 do
        NetworkRequestControlOfEntity(mower)
        NetworkRequestControlOfEntity(truck)
        attach()
        attempt += 1
        Wait(100)
    end
end

function Vehicle.teardown()
    Vehicle.clearInteractions()
    Vehicle.toggleDelivery(false)
end

return Vehicle
