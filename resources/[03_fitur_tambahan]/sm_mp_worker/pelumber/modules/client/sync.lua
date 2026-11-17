local State = require 'pelumber.modules.client.state'

local Sync = {}

---@param objId string
---@return boolean granted
function Sync.acquire(objId)
    return lib.callback.await(State.event('server:acquireProcessing'), false, objId) == true
end

---@param objId string
function Sync.release(objId)
    TriggerServerEvent(State.event('server:releaseProcessing'), objId)
end

---@param objId string
function Sync.objectDone(objId)
    TriggerServerEvent(State.event('server:objectDone'), objId)
end

---@param objId string
function Sync.pipeRemoved(objId)
    TriggerServerEvent(State.event('server:pipeRemoved'), objId)
end

---@param objId string
---@param state 'closed'|'open'|'placed'
function Sync.valveState(objId, state)
    TriggerServerEvent(State.event('server:valveState'), objId, state)
end

return Sync
