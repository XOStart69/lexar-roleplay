---@class ReceiptServer
local receipt = {}

local active = {}

---@param source number
---@param id any
---@param netId any
---@return table
function receipt.check(source, id, netId)
    if type(id) ~= 'number' or type(netId) ~= 'number' then return { ok = false } end

    local entity = NetworkGetEntityFromNetworkId(netId)

    if not entity or entity == 0 then return { ok = false } end

    active[source] = { id = id, net = netId }

    return { ok = true }
end

---@param source number
---@return table
function receipt.customers(source)
    local list = {}

    for _, raw in ipairs(GetPlayers()) do
        local target = tonumber(raw)

        if target ~= source then
            list[#list + 1] = { id = target, name = GetPlayerName(raw) }
        end
    end

    return list
end

---@param source number
---@param netId number
---@param zone table
---@return table
function receipt.register(source, netId, zone)
    local entity = NetworkGetEntityFromNetworkId(netId)

    if not entity or entity == 0 then return { ok = false } end

    active[source] = { net = netId, zone = zone and zone.id or nil }

    return { ok = true }
end

lib.callback.register('sm_custom:server:receiptCheck', function(source, id, netId)
    return receipt.check(source, id, netId)
end)

lib.callback.register('sm_custom:server:receiptCustomers', function(source)
    return receipt.customers(source)
end)

lib.callback.register('sm_custom:server:receiptRegister', function(source, netId, zone)
    return receipt.register(source, netId, zone)
end)

AddEventHandler('playerDropped', function()
    active[source] = nil
end)

return receipt
