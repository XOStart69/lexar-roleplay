local serverConfig = require 'gardener.config.server'
local locations = require 'gardener.data.locations'

local GardenerMission = {}

local orderedJobs = { 'lawnmowing', 'prunegrass', 'branch', 'plantflower' }

local taskLabels = {
    lawnmowing = 'Potong Rumput',
    prunegrass = 'Pangkas Semak',
    branch = 'Potong Dahan',
    plantflower = 'Tanam Bunga',
    wateringcan = 'Siram Bunga (Bonus)',
    takeBranch = 'Angkut Dahan (Bonus)',
}

local taskDescriptions = {
    lawnmowing = 'Lindas rumput liar menggunakan mesin pemotong',
    prunegrass = 'Pangkas semak menggunakan trimmer',
    branch = 'Pasang tangga lalu potong dahan pohon',
    plantflower = 'Tanam bunga di area yang ditandai',
    wateringcan = 'Siram bunga yang sudah ditanam',
    takeBranch = 'Angkut dahan yang jatuh ke bak truk',
}

---@param regionIndex number
---@return table<string, number> jumlah
local function getAvailability(regionIndex)
    local regionLoc = locations[regionIndex] or {}

    local branchMax = 0
    for _, branch in ipairs(regionLoc.potongDahan or {}) do
        branchMax += branch.branchCoords and #branch.branchCoords or 0
    end

    return {
        lawnmowing = regionLoc.potongRumput and #regionLoc.potongRumput or 0,
        prunegrass = regionLoc.pangkasSemak and #regionLoc.pangkasSemak or 0,
        branch = branchMax,
        plantflower = (regionLoc.tanamBunga and #regionLoc.tanamBunga > 0) and math.huge or 0,
    }
end

---@param regionIndex number
---@return boolean
function GardenerMission.regionHasTasks(regionIndex)
    local regionCfg = serverConfig.regions[regionIndex]
    local availability = getAvailability(regionIndex)
    for _, jobName in ipairs(orderedJobs) do
        if regionCfg.tasks[jobName] and availability[jobName] > 0 then
            return true
        end
    end
    return false
end

---@param groupId string
---@param ownerSrc number
---@param regionIndex number
---@return table mission
function GardenerMission.new(groupId, ownerSrc, regionIndex)
    local regionCfg = serverConfig.regions[regionIndex]
    local regionLoc = locations[regionIndex] or {}
    local availability = getAvailability(regionIndex)
    local tasks = {}
    local taskOrder = {}

    for _, jobName in ipairs(orderedJobs) do
        local range = regionCfg.tasks[jobName]
        if range and availability[jobName] > 0 then
            tasks[#tasks + 1] = {
                jobName = jobName,
                jobCount = math.min(math.random(range.min, range.max), availability[jobName]),
                madeAmount = 0,
                finish = false,
                bonus = false,
            }
            taskOrder[#taskOrder + 1] = jobName
        end
    end

    local branchTask = GardenerMission.getTask({ tasks = tasks }, 'branch')
    local flowerTask = GardenerMission.getTask({ tasks = tasks }, 'plantflower')

    if flowerTask then
        tasks[#tasks + 1] = {
            jobName = 'wateringcan',
            jobCount = flowerTask.jobCount,
            madeAmount = 0,
            finish = false,
            bonus = true,
        }
    end
    if branchTask then
        tasks[#tasks + 1] = {
            jobName = 'takeBranch',
            jobCount = branchTask.jobCount,
            madeAmount = 0,
            finish = false,
            bonus = true,
        }
    end

    return {
        groupId = groupId,
        ownerSrc = ownerSrc,
        regionIndex = regionIndex,
        money = regionCfg.money,
        flowerArea = flowerTask and regionLoc.tanamBunga or {},
        tasks = tasks,
        taskOrder = taskOrder,
        currentTaskIndex = 1,
        trucks = {},
        mowers = {},
        shared = {
            mowerObject = {},
            prunegrassObject = {},
            flowerObject = {},
            branchObject = {},
            ladderObject = {},
        },
        finishing = false,
        delivering = false,
    }
end

---@param mission table
---@return table
function GardenerMission.snapshot(mission)
    local trucks = {}
    for i, truck in ipairs(mission.trucks) do
        trucks[i] = { netId = truck.netId, plate = truck.plate, id = truck.id }
    end

    local mowers = {}
    for i, mower in ipairs(mission.mowers) do
        mowers[i] = { netId = mower.netId, plate = mower.plate, id = mower.id }
    end

    return {
        regionIndex = mission.regionIndex,
        ownerSrc = mission.ownerSrc,
        trucks = trucks,
        mowers = mowers,
        tasks = mission.tasks,
        taskOrder = mission.taskOrder,
        currentTaskIndex = mission.currentTaskIndex,
        flowerArea = mission.flowerArea,
        deliverCoords = serverConfig.vehicle.deliverCoords,
        finishing = mission.finishing,
    }
end

---@param mission table
---@return table[] groupTasks
function GardenerMission.groupTasks(mission)
    local groupTasks = {}
    for i, task in ipairs(mission.tasks) do
        groupTasks[i] = {
            id = task.jobName,
            name = taskLabels[task.jobName],
            description = taskDescriptions[task.jobName],
            tasksType = 'count',
            target = task.jobCount,
        }
    end
    return groupTasks
end

---@param mission table
---@return string? jobName
function GardenerMission.currentTask(mission)
    return mission.taskOrder[mission.currentTaskIndex]
end

---@param mission table
---@param jobName string
---@return table? task
function GardenerMission.getTask(mission, jobName)
    for _, task in ipairs(mission.tasks) do
        if task.jobName == jobName then
            return task
        end
    end
end

---@param mission table
---@param jobName string
---@return table? task
function GardenerMission.advanceTask(mission, jobName)
    local task = GardenerMission.getTask(mission, jobName)
    if not task or task.finish then return nil end

    task.madeAmount += 1
    if task.madeAmount >= task.jobCount then
        task.madeAmount = task.jobCount
        task.finish = true
    end
    return task
end

---@param mission table
---@return boolean
function GardenerMission.isAllRequiredFinished(mission)
    for _, task in ipairs(mission.tasks) do
        if not task.bonus and not task.finish then
            return false
        end
    end
    return true
end

---@param mission table
---@param plate string
---@return table? truck
function GardenerMission.findTruck(mission, plate)
    for _, truck in ipairs(mission.trucks) do
        if truck.plate == plate then
            return truck
        end
    end
end

---@param mission table
---@param netId number
---@return table? truck
function GardenerMission.findTruckByNetId(mission, netId)
    for _, truck in ipairs(mission.trucks) do
        if truck.netId == netId then
            return truck
        end
    end
end

---@param mission table
---@param netId number
---@return table? mower
function GardenerMission.findMowerByNetId(mission, netId)
    for _, mower in ipairs(mission.mowers) do
        if mower.netId == netId then
            return mower
        end
    end
end

return GardenerMission
