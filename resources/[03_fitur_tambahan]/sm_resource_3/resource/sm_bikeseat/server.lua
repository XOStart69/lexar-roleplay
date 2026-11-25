--[[
    sm_bikeseat :: server
    Satu penumpang per sepeda. Klaim disimpan di state bag `bikeSeat`.
]]

local config = localmodule 'config'

local MAX_DISTANCE = (config.maxDistance or 2.0) + 3.0

local BIKES = {}
for model in pairs(config.bikes or {}) do
    BIKES[joaat(model)] = true
end

---@type table<number, number> src -> netId
local claims = {}

local function release(src)
    local netId = claims[src]
    claims[src] = nil
    if not netId then return end

    local bike = NetworkGetEntityFromNetworkId(netId)
    if bike ~= 0 and DoesEntityExist(bike) then
        local state = Entity(bike).state
        if state.bikeSeat == src then
            state:set('bikeSeat', nil, true)
        end
    end
end

lib.callback.register('sm_bikeseat:server:claim', function(src, netId)
    netId = tonumber(netId)
    if not netId then return false end

    release(src)

    local bike = NetworkGetEntityFromNetworkId(netId)
    if bike == 0 or not DoesEntityExist(bike) then return false end
    if not BIKES[GetEntityModel(bike)] then return false end

    local ped = GetPlayerPed(src)
    if ped == 0 or #(GetEntityCoords(ped) - GetEntityCoords(bike)) > MAX_DISTANCE then return false end

    local state = Entity(bike).state
    if state.bikeSeat then return false end

    state:set('bikeSeat', src, true)
    claims[src] = netId

    return true
end)

RegisterTokenEvent('sm_bikeseat:server:release', function()
    release(source)
end)

AddEventHandler('playerDropped', function()
    release(source)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    for src in pairs(claims) do release(src) end
end)
