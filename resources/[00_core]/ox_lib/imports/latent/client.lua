lib.latent = {}

---@param event string
---@param ... any
function lib.latent.server(event, ...)
    local payload = msgpack.pack_args(...)
    local payloadLen = #payload
    local bps = payloadLen + 1000

    TriggerLatentServerEventInternal(event, payload, payloadLen, bps)
end

return lib.latent
