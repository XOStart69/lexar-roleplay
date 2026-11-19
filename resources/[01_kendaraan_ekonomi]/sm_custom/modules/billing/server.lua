---@class BillingServer
local billing = {}

local pending = {}
local seq = 0

---@param target number
---@param zone table
---@param amount number
---@param onReply fun(accepted: boolean)
---@return boolean
function billing.request(target, zone, amount, onReply)
    if amount <= 0 then return false end

    seq += 1
    pending[seq] = { target = target, onReply = onReply }

    TriggerClientEvent('sm_custom:client:bill', target, seq, {
        label = zone.label,
        amount = amount,
    })

    return true
end

RegisterNetEvent('sm_custom:server:billReply', function(id, accepted)
    local entry = pending[id]

    if not entry then return end

    pending[id] = nil

    if entry.onReply then entry.onReply(accepted == true) end
end)

AddEventHandler('playerDropped', function()
    local source = source

    for id, entry in pairs(pending) do
        if entry.target == source then pending[id] = nil end
    end
end)

return billing
