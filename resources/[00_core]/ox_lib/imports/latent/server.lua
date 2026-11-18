lib.latent = {}

---@param event string
---@param target number|string
---@param ... any
function lib.latent.client(event, target, ...)
    local payload = msgpack.pack_args(...)
    local payloadLen = #payload
    local bps = payloadLen + 1000

    TriggerLatentClientEvent(event, target, bps, payloadLen, payload)
end

return lib.latent