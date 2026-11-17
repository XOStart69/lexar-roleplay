local locations = require 'pelumber.data.locations'

local Mission = {}

local TASK_ORDER = { 'insertpipe', 'repairpipe', 'toilet', 'openvalve', 'fixswitch' }

local REPAIR_CANDIDATE = 'veo_pipes_d'
local REPAIR_BROKEN_COUNT = 2

local TASK_META = {
    insertpipe = { name = 'Pemasangan Pipa', description = 'Pasang seluruh rangkaian pipa baru.' },
    repairpipe = { name = 'Perbaikan Pipa', description = 'Ganti pipa yang rusak.' },
    toilet = { name = 'Bersihkan Toilet', description = 'Bersihkan semua toilet yang tersumbat.' },
    openvalve = { name = 'Buka Katup', description = 'Pasang dan buka katup.' },
    fixswitch = { name = 'Perbaiki Saklar', description = 'Perbaiki panel saklar.' },
}

---@param n number
---@param count number
---@return number[]
local function pickRandom(n, count)
    local pool = {}
    for i = 1, n do pool[i] = i end
    for i = n, 2, -1 do
        local j = math.random(i)
        pool[i], pool[j] = pool[j], pool[i]
    end
    local out = {}
    for i = 1, math.min(count, n) do out[i] = pool[i] end
    return out
end

---@param mission table
---@param location table
local function buildRepairBroken(mission, location)
    if not location.repairpipe then return end

    for s = 1, #location.repairpipe do
        local set = location.repairpipe[s]
        local candidates = {}
        for i = 1, #set.pipes do
            if set.pipes[i].object == REPAIR_CANDIDATE then
                candidates[#candidates + 1] = i
            end
        end

        local chosen = pickRandom(#candidates, REPAIR_BROKEN_COUNT)
        for _, ci in ipairs(chosen) do
            local pipeIndex = candidates[ci]
            mission.brokenPipes[('rp_%d_p_%d'):format(s, pipeIndex)] = true
        end
    end
end

---@param mission table
---@param taskType string
---@param location table
---@return string[]? units
local function buildUnits(mission, taskType, location)
    local data = location[taskType]
    if not data or #data == 0 then return nil end

    local units = {}

    if taskType == 'insertpipe' or taskType == 'repairpipe' then
        local prefix = taskType == 'insertpipe' and 'ip' or 'rp'
        local pipeGate = taskType == 'insertpipe' and 'sequence' or 'closed'
        local expectedState = taskType == 'insertpipe' and 'placed' or 'closed'
        for s = 1, #data do
            local set = data[s]
            local valveId = ('%s_%d_v'):format(prefix, s)
            local pipeIds = {}

            for i = 1, #set.pipes do
                local pipeId = ('%s_%d_p_%d'):format(prefix, s, i)
                if taskType == 'insertpipe' or mission.brokenPipes[pipeId] then
                    pipeIds[#pipeIds + 1] = pipeId
                    mission.pipeValve[pipeId] = valveId
                    mission.pipeGate[pipeId] = pipeGate
                    mission.unitCoords[pipeId] = set.pipes[i].coords
                    units[#units + 1] = pipeId
                end
            end

            mission.valveDeps[valveId] = pipeIds
            mission.valveExpectedState[valveId] = expectedState
            mission.unitCoords[valveId] = set.valve.coords
            units[#units + 1] = valveId
        end
    elseif taskType == 'toilet' then
        for i = 1, #data do
            local objId = ('tl_%d'):format(i)
            mission.unitCoords[objId] = data[i].coords
            units[#units + 1] = objId
        end
    elseif taskType == 'openvalve' then
        for i = 1, #data do
            local objId = ('ov_%d'):format(i)
            mission.unitCoords[objId] = data[i].valve.coords
            units[#units + 1] = objId
        end
    elseif taskType == 'fixswitch' then
        for i = 1, #data do
            local objId = ('fs_%d'):format(i)
            mission.unitCoords[objId] = data[i].coords
            units[#units + 1] = objId
        end
    end

    return units
end

---@param groupId string
---@param ownerSrc number
---@param locationIndex number
---@param vehicle { entity: number, netId: number, plate: string }
---@return table
function Mission.new(groupId, ownerSrc, locationIndex, vehicle)
    local location = locations[locationIndex]

    local mission = {
        groupId = groupId,
        ownerSrc = ownerSrc,
        locationIndex = locationIndex,
        vehicleEntity = vehicle.entity,
        vehicleNetId = vehicle.netId,
        vehiclePlate = vehicle.plate,
        taskOrder = {},
        currentTaskIndex = 1,
        brokenPipes = {},
        pipeRemoved = {},
        done = {},
        valveState = {},
        processing = {},
        units = {},
        unitDone = {},
        unitCoords = {},
        pipeValve = {},
        pipeGate = {},
        valveDeps = {},
        valveExpectedState = {},
        finishing = false,
    }

    buildRepairBroken(mission, location)

    for _, taskType in ipairs(TASK_ORDER) do
        local units = buildUnits(mission, taskType, location)
        if units and #units > 0 then
            mission.taskOrder[#mission.taskOrder + 1] = taskType
            mission.units[taskType] = units
            mission.unitDone[taskType] = 0
        end
    end

    return mission
end

---@param mission table
---@return table
function Mission.snapshot(mission)
    return {
        locationIndex = mission.locationIndex,
        vehicleNetId = mission.vehicleNetId,
        vehiclePlate = mission.vehiclePlate,
        ownerSrc = mission.ownerSrc,
        taskOrder = mission.taskOrder,
        currentTaskIndex = mission.currentTaskIndex,
        brokenPipes = mission.brokenPipes,
        pipeRemoved = mission.pipeRemoved,
        done = mission.done,
        valveState = mission.valveState,
        processing = mission.processing,
    }
end

---@param mission table
---@return string? taskType
function Mission.currentTask(mission)
    return mission.taskOrder[mission.currentTaskIndex]
end

---@param mission table
---@param objId string
---@return boolean
local function isCurrentUnit(mission, objId)
    local taskType = Mission.currentTask(mission)
    if not taskType then return false end

    local units = mission.units[taskType]
    for i = 1, #units do
        if units[i] == objId then return true end
    end
    return false
end

Mission.isCurrentUnit = isCurrentUnit

---@param mission table
---@param objId string
---@return boolean
function Mission.canComplete(mission, objId)
    if mission.done[objId] then return false end
    if not isCurrentUnit(mission, objId) then return false end

    local deps = mission.valveDeps[objId]
    if deps then
        for i = 1, #deps do
            if not mission.done[deps[i]] then return false end
        end
        return mission.valveState[objId] == mission.valveExpectedState[objId]
    end

    local valveId = mission.pipeValve[objId]
    if valveId then
        local gate = mission.pipeGate[objId]
        if gate == 'closed' then
            if not mission.pipeRemoved[objId] then return false end
            return mission.valveState[valveId] == 'closed'
        elseif gate == 'sequence' then
            local list = mission.valveDeps[valveId]
            for i = 1, #list do
                if list[i] == objId then return true end
                if not mission.done[list[i]] then return false end
            end
            return true
        end
        return true
    end

    return true
end

---@param mission table
---@param objId string
---@return boolean marked
function Mission.markDone(mission, objId)
    if not Mission.canComplete(mission, objId) then return false end

    local taskType = Mission.currentTask(mission)
    if not taskType then return false end

    mission.done[objId] = true
    mission.unitDone[taskType] = mission.unitDone[taskType] + 1

    if mission.valveDeps[objId] then
        mission.valveState[objId] = 'open'
    end

    return true
end

---@param mission table
---@param objId string
---@param state string
---@return boolean applied
function Mission.setValveState(mission, objId, state)
    if not mission.valveDeps[objId] then return false end
    if mission.done[objId] then return false end
    if not isCurrentUnit(mission, objId) then return false end

    if state ~= mission.valveExpectedState[objId] then return false end

    if state == 'placed' then
        local deps = mission.valveDeps[objId]
        for i = 1, #deps do
            if not mission.done[deps[i]] then return false end
        end
    end

    mission.valveState[objId] = state
    return true
end

---@param mission table
---@param objId string
---@return boolean applied
function Mission.setPipeRemoved(mission, objId)
    if mission.done[objId] then return false end
    if mission.pipeRemoved[objId] then return false end
    if mission.pipeGate[objId] ~= 'closed' then return false end
    if not isCurrentUnit(mission, objId) then return false end

    local valveId = mission.pipeValve[objId]
    if mission.valveState[valveId] ~= 'closed' then return false end

    mission.pipeRemoved[objId] = true
    return true
end

---@param mission table
---@param objId string
---@param playerSrc number
---@return boolean granted
function Mission.acquireProcessing(mission, objId, playerSrc)
    if mission.processing[objId] then return false end
    mission.processing[objId] = playerSrc
    return true
end

---@param mission table
---@param objId string
---@param playerSrc number
---@return boolean released
function Mission.releaseProcessing(mission, objId, playerSrc)
    if mission.processing[objId] ~= playerSrc then return false end
    mission.processing[objId] = nil
    return true
end

---@param mission table
---@param playerSrc number
---@return string[] released
function Mission.releaseAllForPlayer(mission, playerSrc)
    local released = {}
    for objId, src in pairs(mission.processing) do
        if src == playerSrc then
            mission.processing[objId] = nil
            released[#released + 1] = objId
        end
    end
    return released
end

---@param mission table
---@return boolean
function Mission.isCurrentTaskComplete(mission)
    local taskType = Mission.currentTask(mission)
    if not taskType then return true end
    return mission.unitDone[taskType] >= #mission.units[taskType]
end

---@param mission table
---@return string[] completed
function Mission.forceCompletePipes(mission)
    local taskType = Mission.currentTask(mission)
    if not taskType then return {} end
    if taskType ~= 'insertpipe' and taskType ~= 'repairpipe' then return {} end

    local completed = {}
    local units = mission.units[taskType]
    for i = 1, #units do
        local objId = units[i]
        if mission.pipeValve[objId] and not mission.done[objId] then
            if mission.pipeGate[objId] == 'closed' then
                mission.pipeRemoved[objId] = true
            end
            mission.done[objId] = true
            mission.unitDone[taskType] = (mission.unitDone[taskType] or 0) + 1
            completed[#completed + 1] = objId
        end
    end
    return completed
end

---@param mission table
---@return boolean advanced
---@return boolean finished
function Mission.advance(mission)
    if mission.currentTaskIndex >= #mission.taskOrder then
        return false, true
    end
    mission.currentTaskIndex = mission.currentTaskIndex + 1
    return true, false
end

---@param mission table
---@return { id: string, name: string, description: string, tasksType: string, target: number }[]
function Mission.groupTasks(mission)
    local tasks = {}
    for i = 1, #mission.taskOrder do
        local taskType = mission.taskOrder[i]
        local meta = TASK_META[taskType]
        tasks[#tasks + 1] = {
            id = taskType,
            name = meta.name,
            description = meta.description,
            tasksType = 'count',
            target = #mission.units[taskType],
        }
    end
    return tasks
end

---@param mission table
---@param taskType string
---@return number
function Mission.taskValue(mission, taskType)
    return mission.unitDone[taskType] or 0
end

return Mission
