local Net = localmodule 'modules.net'

local Pull = {}

local pending = {}
local responses = {}
local lastId = 0

RegisterNetEvent('sm_tcgcards:push', function(id, data)
    if source == '' then return end

    if pending[id] then responses[id] = data end
end)

---@param name string
---@param ... any
---@return any
function Pull.await(name, ...)
    lastId += 1

    local id = lastId

    pending[id] = true
    TriggerServerEvent('sm_tcgcards:pull', id, name, ...)

    local result = Net.awaitPush(function()
        return responses[id]
    end, 15000)

    pending[id] = nil
    responses[id] = nil

    if type(result) == 'table' then return result[1], result[2], result[3] end

    return result
end

return Pull
