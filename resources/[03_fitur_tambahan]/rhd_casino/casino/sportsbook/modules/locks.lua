local held = {}

local Locks = {}

---@param keys string[]
function Locks.acquire(keys)
    table.sort(keys)

    for i = 1, #keys do
        local key = keys[i]
        while held[key] do Wait(0) end
        held[key] = true
    end
end

---@param keys string[]
function Locks.release(keys)
    for i = 1, #keys do
        held[keys[i]] = nil
    end
end

return Locks
