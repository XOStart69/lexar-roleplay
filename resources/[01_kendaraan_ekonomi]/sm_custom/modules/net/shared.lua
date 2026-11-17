---@class NetShared
local Net = {}

---@param event string
---@param player number
---@param ... any
function Net.emitLatentClient(event, player, ...)
    local payload = msgpack.pack_args(...)
    local payloadLen = #payload
    local bps = payloadLen + 1000
    TriggerLatentClientEventInternal(event, player --[[@as string]], payload, payloadLen, bps)
end

---@param event string
---@param targets number[]
---@param ... any
function Net.emitLatentClients(event, targets, ...)
    if #targets == 0 then return end

    local payload = msgpack.pack_args(...)
    local payloadLen = #payload
    local bps = payloadLen + 1000

    for i = 1, #targets do
        TriggerLatentClientEventInternal(event, tostring(targets[i]), payload, payloadLen, bps)
    end
end

---@param event string
---@param bps integer
---@param ... any
function Net.broadcastLatent(event, bps, ...)
    local payload = msgpack.pack_args(...)

    TriggerLatentClientEventInternal(event, '-1', payload, #payload, bps)
end

---@param event string
---@param ... any
function Net.emitLatentServer(event, ...)
    local payload = msgpack.pack_args(...)
    local payloadLen = #payload
    local bps = payloadLen + 1000
    TriggerLatentServerEventInternal(event, payload, payloadLen, bps)
end

---@generic T
---@param get fun(): T?
---@param timeout number?
---@return T?
function Net.awaitPush(get, timeout)
    local value = get()

    if value ~= nil then return value end

    local deadline = GetGameTimer() + (timeout or 5000)

    repeat
        Wait(0)
        value = get()
    until value ~= nil or GetGameTimer() > deadline

    return value
end

return Net
