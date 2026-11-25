--[[
    sm_helicam :: server
    Spotlight (state bag Player.heliSpot) dan marker bersama (GlobalState.helicamMarkers).
    Hanya job yang diizinkan, di dalam helikopter yang terdaftar di config.
]]

local config = localmodule 'config'

local SPOT = config.spotlight
local MAX_MARKERS = config.marker.maxAmount or 9

local MODELS = {}
for i = 1, #config.helicopters do MODELS[joaat(config.helicopters[i])] = true end

local MODES = { off = true, forward = true, manual = true, track = true }
local lastMarkers = {}

local function inHeli(src)
    local player = qb_ecore:GetPlayer(src)
    if not player or not config.jobs[player.PlayerData.job.name] then return false end

    local ped = GetPlayerPed(src)
    local vehicle = ped ~= 0 and GetVehiclePedIsIn(ped, false) or 0
    return vehicle ~= 0 and MODELS[GetEntityModel(vehicle)] == true
end

local function clamp(value, range)
    return math.max(range.min, math.min(range.max, value))
end

RegisterTokenEvent('sm_helicam:server:spot', function(mode, netId, paused)
    local src = source
    local state = Player(src).state

    if mode == 'off' or not MODES[mode] then
        state:set('heliSpot', nil, true)
        return
    end

    if not inHeli(src) then return end

    local previous = state.heliSpot or {}

    state:set('heliSpot', {
        mode = mode,
        target = mode == 'track' and tonumber(netId) or nil,
        paused = paused == true,
        brightness = previous.brightness or SPOT.brightness.default,
        radius = previous.radius or SPOT.radius.default,
    }, true)
end)

RegisterTokenEvent('sm_helicam:server:adjust', function(kind, delta)
    local src = source
    delta = tonumber(delta)
    if (kind ~= 'brightness' and kind ~= 'radius') or not delta or not inHeli(src) then return end

    local state = Player(src).state
    local spot = state.heliSpot
    if type(spot) ~= 'table' then return end

    local copy = {}
    for k, v in pairs(spot) do copy[k] = v end

    copy[kind] = clamp((copy[kind] or SPOT[kind].default) + (delta > 0 and 1.0 or -1.0), SPOT[kind])
    state:set('heliSpot', copy, true)
end)

RegisterTokenEvent('sm_helicam:server:markers', function(list)
    local src = source
    if type(list) ~= 'table' or not inHeli(src) then return end

    local now = GetGameTimer()
    if lastMarkers[src] and now - lastMarkers[src] < 300 then return end
    lastMarkers[src] = now

    local out = {}
    for i = 1, math.min(#list, MAX_MARKERS) do
        local c = list[i]
        local x, y, z = tonumber(c and c.x), tonumber(c and c.y), tonumber(c and c.z)
        if x and y and z then out[#out + 1] = { x = x, y = y, z = z } end
    end

    GlobalState.helicamMarkers = out
end)

AddEventHandler('playerDropped', function()
    lastMarkers[source] = nil
end)
