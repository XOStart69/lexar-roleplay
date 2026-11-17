---@class GardenerClientState
local State = {}

State.cfg = require 'gardener.config.client'
State.sharedCfg = require 'gardener.config.shared'
State.locations = require 'gardener.data.locations'

State.nuiLoaded = false
State.showBar = false
State.isInteracting = false
State.isPlacingObject = false
State.isPlacingLadder = false
State.isPlacingWateringcan = false

---@type table? snapshot misi dari server
State.mission = nil

State.playerHandObject = {
    trimmer = false,
    ladder = false,
    flower = false,
    wateringcan = false,
    branch = false,
}

State.mowerObject = {}
State.prunegrassObject = {}
State.flowerObject = {}
State.branchObject = {}
State.ladderObject = {
    ladderCoords = {},
    ladderSettings = {},
}

State.flowerState = {
    object = false,
    model = false,
    PlacingObject = false,
    Coords = false,
    isPlant = false,
}

State.stateBlips = {
    lawnmowing = {},
    prunegrass = {},
    branch = {},
    flower = {},
    flowerTwo = {},
}

State.stateThread = {
    deleteLawnMowerObjectThread = false,
    plantFlowerThreadActive = false,
    wateringcanThreadActive = false,
    isFreezeActive = false,
}

State.objectTable = {
    branch = { 'branch_frag_1', 'branch_frag_2', 'branch_frag_3' },
    palm = { 'palm_frag_1', 'palm_frag_2' },
}

local notifTypes = {
    error = 'error',
    info = 'info',
    success = 'success',
}

---@param name string
---@return string
function State.event(name)
    return 'sm_gardener:' .. name
end

function State.getStartJob()
    return State.mission ~= nil
end

function State.isOwner()
    return State.mission ~= nil and State.mission.ownerSrc == (cache.serverId --[[@as number]])
end

---@return table? region data lokasi aktif dari data/locations.lua
function State.getRegion()
    if not State.mission then return nil end
    return State.locations[State.mission.regionIndex]
end

---@param jobName string
---@return table? task
function State.getTask(jobName)
    if not State.mission then return nil end
    for i = 1, #State.mission.tasks do
        if State.mission.tasks[i].jobName == jobName then
            return State.mission.tasks[i]
        end
    end
end

---@return string? jobName tugas step aktif
function State.getCurrentTaskName()
    local mission = State.mission
    if not mission or not mission.taskOrder then return nil end
    return mission.taskOrder[mission.currentTaskIndex]
end

---@param jobName string
---@return boolean
function State.isTaskActive(jobName)
    return State.getCurrentTaskName() == jobName
end

---@param jobName string
---@return boolean step
function State.hasTaskReached(jobName)
    local mission = State.mission
    if not mission or not mission.taskOrder then return false end
    if mission.finishing then return true end

    for i = 1, mission.currentTaskIndex do
        if mission.taskOrder[i] == jobName then
            return true
        end
    end
    return false
end

---@param vehicle number
---@return table? data
function State.getMissionTruck(vehicle)
    if not State.mission or not DoesEntityExist(vehicle) then return nil end
    local plate = GetVehicleNumberPlateText(vehicle)
    for i = 1, #State.mission.trucks do
        if State.mission.trucks[i].plate == plate then
            return State.mission.trucks[i]
        end
    end
end

---@param vehicle number
---@return table? data
function State.getMissionMower(vehicle)
    if not State.mission or not DoesEntityExist(vehicle) then return nil end
    local plate = GetVehicleNumberPlateText(vehicle)
    for i = 1, #State.mission.mowers do
        if State.mission.mowers[i].plate == plate then
            return State.mission.mowers[i]
        end
    end
end

---@param vehicle number
---@return boolean
function State.isMissionMower(vehicle)
    return State.getMissionMower(vehicle) ~= nil
end

---@param vehicle number
---@return boolean
function State.isMissionVehicle(vehicle)
    return State.getMissionTruck(vehicle) ~= nil or State.getMissionMower(vehicle) ~= nil
end

function State.startInteraction()
    State.isInteracting = true
end

function State.endInteraction()
    State.isInteracting = false
end

---@return boolean
function State.isCarryingAnything()
    local hand = State.playerHandObject
    return (hand.trimmer or hand.ladder or hand.flower or hand.wateringcan or hand.branch) and true or false
end

---@param action string
---@param payload any
function State.nuiMessage(action, payload)
    while not State.nuiLoaded do
        Wait(0)
    end
    interface.send({ action = action, payload = payload })
end

---@param message string
---@param notifType? 'error' | 'info' | 'success'
function State.notify(message, notifType)
    lib.notify({
        title = 'Tukang Kebun',
        description = message,
        type = notifTypes[notifType] or 'info',
    })
end

function State.resetPlayerHandObject()
    for item, object in pairs(State.playerHandObject) do
        if object and DoesEntityExist(object) then
            DeleteEntity(object)
        end
        State.playerHandObject[item] = false
    end
end

function State.resetFlowerState()
    State.flowerState = {
        object = false,
        model = false,
        PlacingObject = false,
        Coords = false,
        isPlant = false,
    }
end

function State.resetLadderObject()
    State.ladderObject = {
        ladderCoords = {},
        ladderSettings = {},
    }
end

function State.resetStateBlips()
    State.stateBlips = {
        lawnmowing = {},
        prunegrass = {},
        branch = {},
        flower = {},
        flowerTwo = {},
    }
end

function State.resetStateThread()
    State.stateThread = {
        deleteLawnMowerObjectThread = false,
        plantFlowerThreadActive = false,
        wateringcanThreadActive = false,
        isFreezeActive = false,
    }
end

return State
