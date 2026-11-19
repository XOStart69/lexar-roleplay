local MINUTE_MS = 2000

local hour = 12
local minute = 0
local scale = MINUTE_MS
local frozen = false

local function publish()
    GlobalState.currentTime = { hour = hour, minute = minute }
end

GlobalState.timeScale = scale
GlobalState.freezeTime = false

publish()

local function tick()
    if frozen then return end

    minute += 1

    if minute >= 60 then
        minute = 0
        hour += 1

        if hour >= 24 then hour = 0 end
    end

    publish()
end

CreateThread(function()
    while true do
        Wait(scale)
        tick()
    end
end)

function SetClock(h, m)
    hour = math.floor(math.max(math.min(tonumber(h) or hour, 23), 0))
    minute = math.floor(math.max(math.min(tonumber(m) or minute, 59), 0))

    publish()
end

function SetTimeScale(value)
    value = math.floor(tonumber(value) or MINUTE_MS)

    if value < 100 then value = 100 end

    scale = value
    GlobalState.timeScale = value
end

function SetFrozen(state)
    frozen = state == true
    GlobalState.freezeTime = frozen
end

exports('setTime', SetClock)
exports('setTimeScale', SetTimeScale)
exports('freezeTime', SetFrozen)

RegisterNetEvent('Renewed-Weathersync:server:setTime', function(h, m)
    SetClock(h, m)
end)

RegisterNetEvent('Renewed-Weathersync:server:freezeTime', function(state)
    SetFrozen(state)
end)

RegisterCommand('time', function(source, args)
    local h, m = tonumber(args[1]), tonumber(args[2]) or 0

    if not h then return end

    SetClock(h, m)

    if source ~= 0 then
        TriggerClientEvent('ox_lib:notify', source, { description = ('Waktu %02d:%02d'):format(h, m), type = 'success' })
    end
end, false)

lib.print.info('weathersync time siap')
