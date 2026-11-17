local Config = localmodule 'config'

local osClock = os.clock

local buckets = {}

local RateLimit = {}

---@param playerId number
---@param key string
---@param interval? number
---@return boolean
function RateLimit.check(playerId, key, interval)
    interval = (interval or Config.rateLimit.default) / 1000

    local bucket = buckets[playerId]

    if not bucket then
        bucket = {}
        buckets[playerId] = bucket
    end

    local now = osClock()
    local last = bucket[key]

    if last and (now - last) < interval then
        return false
    end

    bucket[key] = now
    return true
end

---@param playerId number
function RateLimit.clear(playerId)
    buckets[playerId] = nil
end

return RateLimit
