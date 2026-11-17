---@diagnostic disable-next-line: undefined-doc-class
---@class timer: OxClass
local timer = lib.class('timer')

local time_type = {
    jam = 60 * 60,
    menit = 60,
    detik = 1
}

local isServer = lib.context == 'server'

local function getCurrentTime()
    if isServer then
        return os.time()
    end
    return math.floor(GetGameTimer() / 1000)
end

function timer:constructor(tt, time, on_done)
    self.task = on_done
    self.active = true
    self.second = math.floor(time * time_type[tt])
    self.startTime = getCurrentTime()
    self.expired = self.startTime + self.second
    self.isServer = isServer

    self.timeoutId = SetTimeout(self.second * 1000, function()
        if not self.active then return end
        if self.task and type(self.task) == "function" then
            self.task()
        end
        self:stop()
    end)
end

function timer:getTimeLeft()
    if not self.active then return 0 end
    return math.max(0, self.expired - getCurrentTime())
end

function timer:getTimeLeftFormat()
    local second = self:getTimeLeft()

    if not second or second <= 0 then
        return "00 detik"
    end

    local hours = math.floor(second / 3600)
    local minutes = math.floor((second % 3600) / 60)
    local seconds = second % 60

    if second >= 3600 then
        return string.format("%02d jam %02d menit %02d detik", hours, minutes, seconds)
    elseif second >= 60 then
        return string.format("%02d menit %02d detik", minutes, seconds)
    else
        return string.format("%02d detik", seconds)
    end
end

---@param runTask? boolean
function timer:stop(runTask)
    self.active = false

    if self.timeoutId then
        ---@diagnostic disable-next-line: undefined-global
        ClearTimeout(self.timeoutId)
        self.timeoutId = nil
    end

    if runTask and type(self.task) == 'function' then
        self.task(true)
    end
end

function timer:restart()
    -- Hentikan timeout yang lama jika ada
    if self.timeoutId then
        ---@diagnostic disable-next-line: undefined-global
        ClearTimeout(self.timeoutId)
    end

    self.active = true
    self.startTime = getCurrentTime()
    self.expired = self.startTime + self.second
    self.remainingTime = nil

    self.timeoutId = SetTimeout(self.second * 1000, function()
        if not self.active then return end
        if self.task and type(self.task) == "function" then
            self.task()
        end
        self:stop()
    end)
end

function timer:pause()
    if not self.active then return end

    self.remainingTime = self:getTimeLeft()
    self.active = false
    
    if self.timeoutId then
        ---@diagnostic disable-next-line: undefined-global
        ClearTimeout(self.timeoutId)
        self.timeoutId = nil
    end
end

function timer:resume()
    if self.active or not self.remainingTime then return end

    self.active = true
    self.startTime = getCurrentTime()
    self.expired = self.startTime + self.remainingTime

    self.timeoutId = SetTimeout(self.remainingTime * 1000, function()
        if not self.active then return end
        if self.task and type(self.task) == "function" then
            self.task()
        end
        self:stop()
    end)

    self.remainingTime = nil
end

function timer:isActive()
    return self.active and self:getTimeLeft() > 0
end

function timer:getTotalDuration()
    return self.second
end

function timer:getElapsedTime()
    if not self.startTime then return 0 end
    return math.min(self.second, getCurrentTime() - self.startTime)
end

function timer:getProgress()
    if not self.second or self.second == 0 then return 1 end
    return math.min(1, math.max(0, self:getElapsedTime() / self.second))
end

function timer:extend(tt, additionalTime)
    if not self.active then return false end

    local additionalSeconds = math.floor(additionalTime * time_type[tt])
    self.second = self.second + additionalSeconds
    self.expired = self.expired + additionalSeconds

    return true
end

function timer:reduce(tt, timeToReduce)
    if not self.active then return false end

    local secondsToReduce = math.floor(timeToReduce * time_type[tt])
    local newSecond = math.max(1, self.second - secondsToReduce)
    local newExpired = math.max(getCurrentTime() + 1, self.expired - secondsToReduce)
    
    self.second = newSecond
    self.expired = newExpired

    return true
end

function timer:setTime(tt, newTime)
    if not self.active then return false end

    if self.timeoutId then
        ---@diagnostic disable-next-line: undefined-global
        ClearTimeout(self.timeoutId)
        self.timeoutId = nil
    end

    self.second = math.floor(newTime * time_type[tt])
    self.startTime = getCurrentTime()
    self.expired = self.startTime + self.second

    self.timeoutId = SetTimeout(self.second * 1000, function()
        if not self.active then return end
        if self.task and type(self.task) == "function" then
            self.task()
        end
        self:stop()
    end)

    return true
end

function timer:getEnvironment()
    return self.isServer and "server" or "client"
end

return timer