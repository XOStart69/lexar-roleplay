local config = require 'config.client'

local world = {}

---@type { hour: integer, minute: integer, weather: string }?
local locked

---@param weather string
local function applyWeather(weather)
    ClearOverrideWeather()
    ClearWeatherTypePersist()
    SetWeatherTypePersist(weather)
    SetWeatherTypeNow(weather)
    SetWeatherTypeNowPersist(weather)
end

---@param hour integer
---@param minute integer
---@param weather string
function world.lock(hour, minute, weather)
    local running = locked ~= nil

    locked = { hour = hour, minute = minute, weather = weather }
    config.weatherSync(false, weather)
    applyWeather(weather)
    NetworkOverrideClockTime(hour, minute, 0)
    SetArtificialLightsState(false)

    if running then return end

    CreateThread(function()
        while locked do
            if config.weatherSync(false, locked.weather) then
                applyWeather(locked.weather)
            end

            NetworkOverrideClockTime(locked.hour, locked.minute, 0)
            SetArtificialLightsState(false)
            Wait(250)
        end
    end)
end

function world.unlock()
    if not locked then return end

    locked = nil
    NetworkClearClockTimeOverride()
    ClearWeatherTypePersist()
    SetArtificialLightsState(GlobalState.blackOut == true)
    config.weatherSync(true)
end

return world
