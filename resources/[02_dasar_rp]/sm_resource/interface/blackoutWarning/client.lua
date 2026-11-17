if not interface.init() then
    return
end

local function setAlarm(status)
    interface.send({
        action = 'setWarning',
        data = {
            active = status
        }
    })
end

RegisterNetEvent('illegal_blackout:syncsound', function(state)
    if source == '' then return end

    setAlarm(state)
end)
