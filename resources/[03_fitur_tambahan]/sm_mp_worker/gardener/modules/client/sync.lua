local State = require 'gardener.modules.client.state'

local Sync = {}

---@param missionName 'branchObject' | 'flowerObject' | 'ladderObject' | 'mowerObject' | 'prunegrassObject'
---@param missionTable table
function Sync.updateMissionTable(missionName, missionTable)
    TriggerServerEvent(State.event('server:updateMissionTable'), missionName, missionTable)
end

---@param jobName 'lawnmowing' | 'prunegrass' | 'branch' | 'plantflower'
function Sync.updateJobTask(jobName)
    TriggerServerEvent(State.event('server:updateJobTask'), jobName)
end

---@param bonusName 'wateringcan' | 'takeBranch'
function Sync.updateBonusJobTask(bonusName)
    TriggerServerEvent(State.event('server:updateBonusJobTask'), bonusName)
end

---@param plate string
---@param item string
---@param value boolean | number
function Sync.updateVehicleItems(plate, item, value)
    TriggerServerEvent(State.event('server:updateVehicleItems'), plate, item, value)
end

---@param plate string
function Sync.updateVehicleBranch(plate)
    TriggerServerEvent(State.event('server:updateVehicleBranch'), plate)
end

---@param plate string
---@param extra number
---@param enabled boolean
function Sync.updateVehicleExtra(plate, extra, enabled)
    TriggerServerEvent(State.event('server:updateVehicleExtra'), plate, extra, enabled)
end

---@param modelName string
---@param coords vector3
---@param heading number
---@param areaName 'potongRumput' | 'pangkasSemak'
---@param id number
---@param update? boolean
function Sync.addObject(modelName, coords, heading, areaName, id, update)
    TriggerServerEvent(State.event('server:syncAddObject'), modelName, coords, heading, areaName, id, update)
end

---@param id number
function Sync.deleteLawnMowerObject(id)
    TriggerServerEvent(State.event('server:deleteLawnMowerObject'), id)
end

---@param key number
---@param id number
function Sync.trimPruneTree(key, id)
    TriggerServerEvent(State.event('server:trimPruneTree'), key, id)
end

---@param netId number
---@param door number
function Sync.toggleEntityDoor(netId, door)
    TriggerServerEvent(State.event('server:toggleEntityDoor'), netId, door)
end

---@param mowerNetId number
---@param truckNetId number
function Sync.attachMower(mowerNetId, truckNetId)
    TriggerServerEvent(State.event('server:attachMower'), mowerNetId, truckNetId)
end

---@param mowerNetId number
function Sync.detachMower(mowerNetId)
    TriggerServerEvent(State.event('server:detachMower'), mowerNetId)
end

---@param blipsData { task: table, blipsName: string, id: number }[]
function Sync.blipsBatch(blipsData)
    TriggerServerEvent(State.event('server:syncBlipsBatch'), blipsData)
end

---@param blipIndex number
---@param blipName string
function Sync.blipsDelete(blipIndex, blipName)
    TriggerServerEvent(State.event('server:syncBlipsDelete'), blipIndex, blipName)
end

---@param objectNetId number
---@return boolean deleted
function Sync.deleteObject(objectNetId)
    return lib.callback.await(State.event('server:deleteObject'), false, objectNetId) --[[@as boolean]]
end

---@param plate string
---@param item 'trimmer' | 'ladder' | 'wateringcan' | 'flower'
---@param action 'take' | 'putback'
---@return boolean allowed
function Sync.requestVehicleItem(plate, item, action)
    return lib.callback.await(State.event('server:requestVehicleItem'), false, plate, item, action) --[[@as boolean]]
end

---@param plate string
---@return number branchCount
function Sync.getVehicleBranchCount(plate)
    return lib.callback.await(State.event('server:getVehicleBranchCount'), false, plate) --[[@as number]]
end

return Sync
