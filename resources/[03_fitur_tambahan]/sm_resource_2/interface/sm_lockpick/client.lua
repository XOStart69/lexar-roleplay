local config = localmodule 'config'
local exportWrapper = require 'export_wrapper'
local hasFrame = interface.init(false)

local tonumber = tonumber
local floor, min, max = math.floor, math.min, math.max

local STRENGTH = config.strength
local READY_TIMEOUT = config.readyTimeout

---@type promise?
local active
---@type table?
local pending
local frameMounted = false
local frameReady = false
local token = 0

---@param value any
---@param fallback number
---@param low number
---@param high number
---@return number
local function clamp(value, fallback, low, high)
    return min(high, max(low, floor(tonumber(value) or fallback)))
end

local function sendPending()
    local data = pending
    if not data then return end
    pending = nil
    interface.send({ action = 'startLockpick', data = data })
    interface.focus(true, true)
end

---@param result boolean
local function finish(result)
    local current = active
    if not current then return end

    active = nil
    pending = nil
    interface.focus(false, false)

    SetTimeout(50, function()
        if active or not frameMounted then return end
        frameMounted = false
        frameReady = false
        interface.hide()
    end)

    current:resolve(result)
end

---@param strength? string|number item name atau kekuatan 0.0-1.0
---@param difficulty? number
---@param pins? number
---@return boolean
local function startLockpick(strength, difficulty, pins)
    if not hasFrame or active then return false end

    if type(strength) ~= 'number' then
        strength = STRENGTH[strength] or config.defaultStrength
    end

    local current = promise.new()
    active = current
    pending = {
        strength = strength,
        difficulty = clamp(difficulty, config.defaultDifficulty, 1, 5),
        pins = clamp(pins, config.defaultPins, 3, 9),
    }

    token = token + 1
    local myToken = token

    if frameReady then
        sendPending()
    elseif not frameMounted then
        frameMounted = true
        interface.show()
    end

    SetTimeout(READY_TIMEOUT, function()
        if myToken == token and active == current and pending then
            finish(false)
        end
    end)

    return Citizen.Await(current)
end

if hasFrame then
    interface.callback('ready', function(_, cb)
        frameReady = true
        sendPending()
        cb({})
    end)

    interface.callback('succeed', function(_, cb)
        cb({})
        finish(true)
    end)

    interface.callback('failed', function(_, cb)
        cb({})
        finish(false)
    end)

    interface.callback('close', function(_, cb)
        cb({})
        finish(false)
    end)
end

AddEventHandler('sm_lockpick:client:forceClose', function()
    if not active then return end
    if frameReady then
        interface.send({ action = 'stop' })
    end
    finish(false)
end)

exportWrapper('sm_sidejob', 'startLockpick', startLockpick)
