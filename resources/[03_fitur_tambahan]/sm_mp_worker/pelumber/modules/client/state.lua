local State = {}

State.cfg = require 'pelumber.config.client'
State.sharedCfg = require 'pelumber.config.shared'
State.offsets = require 'pelumber.data.offsets'
State.locations = require 'pelumber.data.locations'

---@class ClientMission
---@field locationIndex number
---@field location table
---@field vehicleNetId number
---@field vehiclePlate string
---@field ownerSrc number
---@field taskOrder string[]
---@field currentTaskIndex number
---@field brokenPipes table<string, boolean>
---@field pipeRemoved table<string, boolean>
---@field done table<string, boolean>
---@field valveState table<string, string>
---@field processing table<string, number>
---@field finishing boolean

---@type ClientMission?
State.mission = nil

---@class HandObject
---@field object? number
---@field objectNetId? number
---@field objectModel? string
---@field pipe boolean
---@field valve boolean
---@field pipeType? string
State.playerHandObject = {
    object = nil,
    objectNetId = nil,
    objectModel = nil,
    pipe = false,
    valve = false,
    pipeType = nil,
}

---@type number?
State.cam = nil

---@type boolean
State.showBar = false

---@type boolean
State.disableThreadRunning = false

---@type boolean
State.nuiLoaded = false

---@param name string
---@return string
function State.event(name)
    return 'sm_pelumber:' .. name
end

---@param snapshot table
function State.startMission(snapshot)
    State.mission = {
        locationIndex = snapshot.locationIndex,
        location = State.locations[snapshot.locationIndex],
        vehicleNetId = snapshot.vehicleNetId,
        vehiclePlate = snapshot.vehiclePlate,
        ownerSrc = snapshot.ownerSrc,
        taskOrder = snapshot.taskOrder,
        currentTaskIndex = snapshot.currentTaskIndex,
        brokenPipes = snapshot.brokenPipes or {},
        pipeRemoved = snapshot.pipeRemoved or {},
        done = snapshot.done or {},
        valveState = snapshot.valveState or {},
        processing = snapshot.processing or {},
        finishing = false,
    }
end

function State.clearMission()
    State.mission = nil
end

---@return string?
function State.currentTask()
    local m = State.mission
    if not m then return nil end
    return m.taskOrder[m.currentTaskIndex]
end

---@param objId string
---@return boolean
function State.isDone(objId)
    local m = State.mission
    return m ~= nil and m.done[objId] == true
end

---@param objId string
function State.setDone(objId)
    if State.mission then State.mission.done[objId] = true end
end

---@param objId string
---@return boolean
function State.isPipeRemoved(objId)
    local m = State.mission
    return m ~= nil and m.pipeRemoved[objId] == true
end

---@param objId string
function State.setPipeRemoved(objId)
    if State.mission then State.mission.pipeRemoved[objId] = true end
end

---@param objId string
---@return string?
function State.valveState(objId)
    local m = State.mission
    return m and m.valveState[objId] or nil
end

---@param objId string
---@param state string
function State.setValveState(objId, state)
    if State.mission then State.mission.valveState[objId] = state end
end

---@param objId string
---@return number? playerSrc
function State.processing(objId)
    local m = State.mission
    return m and m.processing[objId] or nil
end

---@param objId string
---@return boolean
function State.isBusyByOther(objId)
    local src = State.processing(objId)
    return src ~= nil and src ~= (cache.serverId --[[@as number]])
end

---@param objId string
---@param src number|false
function State.setProcessing(objId, src)
    if not State.mission then return end
    State.mission.processing[objId] = src or nil
end

---@param s number
---@param i number
---@return string
function State.idInsertPipe(s, i) return ('ip_%d_p_%d'):format(s, i) end

---@param s number
---@return string
function State.idInsertValve(s) return ('ip_%d_v'):format(s) end

---@param s number
---@param i number
---@return string
function State.idRepairPipe(s, i) return ('rp_%d_p_%d'):format(s, i) end

---@param s number
---@return string
function State.idRepairValve(s) return ('rp_%d_v'):format(s) end

---@param i number
---@return string
function State.idToilet(i) return ('tl_%d'):format(i) end

---@param i number
---@return string
function State.idOpenValve(i) return ('ov_%d'):format(i) end

---@param i number
---@return string
function State.idSwitch(i) return ('fs_%d'):format(i) end

return State
