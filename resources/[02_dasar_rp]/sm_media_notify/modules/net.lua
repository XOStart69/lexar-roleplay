local Net = {}

---@param event string
---@param target number
---@param ... any
function Net.emitLatentClient(event, target, ...)
    local payload = msgpack.pack_args(...)
    local size = #payload

    TriggerLatentClientEventInternal(event, tostring(target), payload, size, size + 1000)
end

---@param event string
---@param ... any
function Net.emitLatentAll(event, ...)
    Net.emitLatentClient(event, -1, ...)
end

return Net
