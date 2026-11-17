local Net = {}

function Net.emitLatentClient(event, target, ...)
    local payload = msgpack.pack_args(...)
    local size = #payload
    TriggerLatentClientEventInternal(event, tostring(target), payload, size, size + 1000)
end

return Net
