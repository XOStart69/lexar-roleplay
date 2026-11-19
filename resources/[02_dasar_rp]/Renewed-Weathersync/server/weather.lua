local CYCLE = 10 * 60 * 1000

local weathers = {
    { weather = 'EXTRASUNNY', weight = 22 },
    { weather = 'CLEAR', weight = 20 },
    { weather = 'CLOUDS', weight = 18 },
    { weather = 'OVERCAST', weight = 12 },
    { weather = 'CLEARING', weight = 8 },
    { weather = 'RAIN', weight = 8 },
    { weather = 'THUNDER', weight = 4 },
    { weather = 'SMOG', weight = 4 },
    { weather = 'FOGGY', weight = 3 },
    { weather = 'NEUTRAL', weight = 1 },
}

local current = 'CLEAR'
local wind = 0

local function publish()
    GlobalState.weather = { weather = current, windDirection = wind }
end

publish()

local function pick()
    local total = 0

    for i = 1, #weathers do total += weathers[i].weight end

    local roll = math.random() * total
    local acc = 0

    for i = 1, #weathers do
        acc += weathers[i].weight

        if roll <= acc then return weathers[i].weather end
    end

    return 'CLEAR'
end

function SetWeather(value)
    if type(value) ~= 'string' then return end

    current = value:upper()
    wind = math.random(0, 359)

    publish()
end

exports('setWeather', SetWeather)

RegisterNetEvent('Renewed-Weathersync:server:setWeather', function(value)
    SetWeather(value)
end)

RegisterCommand('weather', function(source, args)
    local value = args[1]

    if not value then return end

    SetWeather(value)

    if source ~= 0 then
        TriggerClientEvent('ox_lib:notify', source, { description = 'Cuaca: ' .. value:upper(), type = 'success' })
    end
end, false)

CreateThread(function()
    Wait(5000)

    while true do
        Wait(CYCLE)
        SetWeather(pick())
    end
end)

lib.print.info('weathersync weather siap')
