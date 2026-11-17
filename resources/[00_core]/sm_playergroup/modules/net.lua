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

return Net