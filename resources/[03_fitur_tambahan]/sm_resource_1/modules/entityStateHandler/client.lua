local handler = {}

---Gets and returns an entity handle and network id from a state bag name
---([source](https://github.com/overextended/ox_core/blob/main/client/utils.lua)).
---Statebag handlers receive changes for every entity on the server, including
---entities outside this client's scope which will never exist locally. Those
---must return quietly instead of throwing, so the wait is short and guarded.
---@async
---@param bagName string
---@return integer? entity, integer? netId
function handler.getEntityAndNetIdFromBagName(bagName)
    local netId = tonumber(bagName:gsub('entity:', ''), 10)
    if not netId then return end

    if NetworkDoesEntityExistWithNetworkId(netId) then
        return NetworkGetEntityFromNetworkId(netId), netId
    end

    local ok, entity = pcall(lib.waitFor, function()
        if NetworkDoesEntityExistWithNetworkId(netId) then
            return NetworkGetEntityFromNetworkId(netId)
        end
    end, nil, 1500)

    if not ok or not entity or entity == 0 then return end

    return entity, netId
end

---Returns a state bag handler made for entities
---([source](https://github.com/overextended/ox_core/blob/main/client/utils.lua)).
---@param keyFilter string
---@param cb fun(entity: number, netId: number, value: any, bagName: string)
---@return number
function handler.entityStateHandler(keyFilter, cb)
    return AddStateBagChangeHandler(keyFilter, '', function(bagName, _, value)
        local entity, netId = handler.getEntityAndNetIdFromBagName(bagName)
        if not entity or entity == 0 or not netId then return end

        cb(entity, netId, value, bagName)
    end)
end

return handler