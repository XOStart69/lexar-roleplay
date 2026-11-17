local state = localmodule 'modules.state'

local pairs = pairs
local GetGameTimer = GetGameTimer
local GetGamePool = GetGamePool
local GetEntityCoords = GetEntityCoords
local DoesEntityExist = DoesEntityExist
local IsPedAPlayer = IsPedAPlayer
local IsEntityDead = IsEntityDead
local SetSeethrough = SetSeethrough
local SeethroughSetHiLightIntensity = SeethroughSetHiLightIntensity
local SeethroughSetMaxThickness = SeethroughSetMaxThickness
local SeethroughSetNoiseAmountMax = SeethroughSetNoiseAmountMax
local SeethroughSetNoiseAmountMin = SeethroughSetNoiseAmountMin
local SetPedHeatscaleOverride = SetPedHeatscaleOverride
local InvokeNative = Citizen.InvokeNative

local RESET_HEATSCALE = 0x600048C60D5C2C51

local RANGE_SQ = 200.0 * 200.0
local REFRESH_MS = 1200

local infrared = {}

local active = false
local lastRefresh = 0
---@type table<integer, true>
local heated = {}

local function refresh()
    local cam = state.camPos
    local pool = GetGamePool('CPed')

    for i = 1, #pool do
        local ped = pool[i]

        if not heated[ped] and not IsPedAPlayer(ped) and not IsEntityDead(ped) then
            local coords = GetEntityCoords(ped)
            local dx = coords.x - cam.x
            local dy = coords.y - cam.y
            local dz = coords.z - cam.z

            if dx * dx + dy * dy + dz * dz < RANGE_SQ then
                SetPedHeatscaleOverride(ped, 1.25)
                heated[ped] = true
            end
        end
    end
end

---@param enabled boolean
function infrared.set(enabled)
    if enabled == active then
        if active and GetGameTimer() - lastRefresh > REFRESH_MS then
            lastRefresh = GetGameTimer()
            refresh()
        end

        return
    end

    active = enabled
    SetSeethrough(enabled)

    if enabled then
        SeethroughSetHiLightIntensity(1.5)
        SeethroughSetMaxThickness(10000.0)
        SeethroughSetNoiseAmountMax(0.0)
        SeethroughSetNoiseAmountMin(0.0)
        lastRefresh = GetGameTimer()
        refresh()
        return
    end

    for ped in pairs(heated) do
        if DoesEntityExist(ped) then
            InvokeNative(RESET_HEATSCALE, ped)
        end
    end

    heated = {}
end

return infrared
