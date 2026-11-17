interface.init(false)

local SetTimeout = SetTimeout
local Wait = Wait

local SHOW_DELAY = 250
local FINISH_LINGER = 5000
local FALLBACK_GRACE = 15000

local frameToken = 0

---@param delay number
local function hideAfter(delay)
    local token = frameToken
    SetTimeout(delay, function()
        if token == frameToken then
            interface.hide()
        end
    end)
end

---@param duration number
local function startTimer(duration)
    if duration <= 0 then return end

    frameToken += 1
    local token = frameToken

    interface.show()
    Wait(SHOW_DELAY)
    if token ~= frameToken then return end

    interface.send({ action = 'asling:start', data = { duration = duration - SHOW_DELAY } })
    hideAfter(duration + FALLBACK_GRACE)
end

RegisterNetEvent('sm_asling:start', function(duration)
    if source == '' then return end
    startTimer(tonumber(duration) or 0)
end)

RegisterNetEvent('sm_asling:finish', function()
    if source == '' then return end
    frameToken += 1
    interface.send({ action = 'asling:finish' })
    hideAfter(FINISH_LINGER)
end)

RegisterNetEvent('sm_asling:cancel', function()
    if source == '' then return end
    frameToken += 1
    interface.send({ action = 'asling:stop' })
    interface.hide()
end)

CreateThread(function()
    startTimer(lib.callback.await('sm_asling:remaining', false) or 0)
end)
