---@type table<number, number>
local buckets = {}

local BASE <const> = 1000

---@param src number
---@param raceId number
function setBucket(src, raceId)
    local bucket = BASE + (raceId % 4000) + 1

    buckets[src] = bucket
    SetPlayerRoutingBucket(src, bucket)
end

---@param src number
function clearBucket(src)
    if not buckets[src] then return end

    buckets[src] = nil
    SetPlayerRoutingBucket(src, 0)
end

---@param src number
---@return boolean
function inBucket(src)
    return buckets[src] ~= nil
end

AddEventHandler('playerDropped', function()
    buckets[source] = nil
end)