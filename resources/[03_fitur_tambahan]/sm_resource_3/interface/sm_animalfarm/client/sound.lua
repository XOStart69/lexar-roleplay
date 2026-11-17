local config = localmodule 'config'

local Wait = Wait
local GetGameTimer = GetGameTimer
local DoesEntityExist = DoesEntityExist
local IsEntityDead = IsEntityDead
local GetEntityCoords = GetEntityCoords
local GetEntitySpeed = GetEntitySpeed
local GetResourceState = GetResourceState
local GetPlayerFromServerId = GetPlayerFromServerId
local GetPlayerPed = GetPlayerPed
local NetworkDoesNetworkIdExist = NetworkDoesNetworkIdExist
local NetworkGetEntityFromNetworkId = NetworkGetEntityFromNetworkId
local smatch = string.match
local random = math.random
local tonumber, type, pairs, next, pcall = tonumber, type, pairs, next, pcall

local SOUND = config.sound
local SPECIES = config.species
local RANGE = SOUND.distance
local RANGE_SQ = RANGE * RANGE
local URL = ('nui://%s/interface/sm_animalfarm/web/build/sounds/%%s.ogg'):format(cache.resource)

---@class FarmSoundSource
---@field species string
---@field entity fun(): integer
---@field loop string|nil
---@field loopId string
---@field fxId string
---@field nextIdle integer
---@field nextRun integer

---@type table<string, FarmSoundSource>
local sources = {}
local running = false

---@param fn string
local function xs(fn, ...)
    pcall(exports.xsound[fn], exports.xsound, ...)
end

---@param source FarmSoundSource
local function stopLoop(source)
    if not source.loop then return end

    xs('Destroy', source.loopId)
    source.loop = nil
end

---@param source FarmSoundSource
---@param name string
---@param coords vector3
local function playOnce(source, name, coords)
    xs('PlayUrlPos', source.fxId, URL:format(name), SOUND.volume, coords, false)
    xs('Distance', source.fxId, RANGE)
end

---@param range integer[]
---@param now integer
---@return integer
local function later(range, now)
    return now + random(range[1], range[2])
end

---@param source FarmSoundSource
---@param me vector3
---@param now integer
local function update(source, me, now)
    local sounds = SPECIES[source.species] and SPECIES[source.species].sounds
    local entity = source.entity()

    if not sounds or entity == 0 or not DoesEntityExist(entity) or IsEntityDead(entity) then
        return stopLoop(source)
    end

    local coords = GetEntityCoords(entity)
    local dx, dy, dz = coords.x - me.x, coords.y - me.y, coords.z - me.z

    if dx * dx + dy * dy + dz * dz > RANGE_SQ then
        return stopLoop(source)
    end

    local speed = GetEntitySpeed(entity)
    local wanted = speed >= SOUND.runSpeed and 'running' or speed >= SOUND.walkSpeed and 'walking' or nil

    if wanted ~= source.loop then
        stopLoop(source)

        local name = wanted and sounds[wanted]

        if name then
            xs('PlayUrlPos', source.loopId, URL:format(name), SOUND.volume, coords, true)
            xs('Distance', source.loopId, RANGE)
            source.loop = wanted
        end
    elseif source.loop then
        xs('Position', source.loopId, coords)
    end

    if not wanted and sounds.idle and now >= source.nextIdle then
        source.nextIdle = later(SOUND.idleEvery, now)
        playOnce(source, sounds.idle, coords)
    elseif wanted == 'running' and sounds.randomrunning and now >= source.nextRun then
        source.nextRun = later(SOUND.runEvery, now)
        playOnce(source, sounds.randomrunning, coords)
    end
end

local function start()
    if running then return end

    running = true

    CreateThread(function()
        while next(sources) do
            if GetResourceState('xsound') == 'started' then
                local me = GetEntityCoords(cache.ped)
                local now = GetGameTimer()

                for _, source in pairs(sources) do
                    update(source, me, now)
                end
            end

            Wait(SOUND.tickMs)
        end

        running = false
    end)
end

---@param key string
---@param species string|nil
---@param resolve fun(): integer
local function setSource(key, species, resolve)
    local current = sources[key]

    if current then
        stopLoop(current)
        sources[key] = nil
    end

    if not species or not SPECIES[species] or not SPECIES[species].sounds then return end

    local now = GetGameTimer()

    sources[key] = {
        species = species,
        entity = resolve,
        loopId = 'smfarm_loop_' .. key,
        fxId = 'smfarm_fx_' .. key,
        nextIdle = later(SOUND.idleEvery, now),
        nextRun = later(SOUND.runEvery, now),
    }
    start()
end

AddStateBagChangeHandler('smFarmAnimal', nil, function(bagName, _, value)
    local netId = tonumber(smatch(bagName, '^entity:(%d+)$'))

    if not netId then return end

    setSource('a' .. netId, type(value) == 'table' and value.species or nil, function()
        return NetworkDoesNetworkIdExist(netId) and NetworkGetEntityFromNetworkId(netId) or 0
    end)
end)

AddStateBagChangeHandler('smFarmRide', nil, function(bagName, _, value)
    local serverId = tonumber(smatch(bagName, '^player:(%d+)$'))

    if not serverId then return end

    setSource('p' .. serverId, type(value) == 'string' and value or nil, function()
        local player = GetPlayerFromServerId(serverId)

        return player ~= -1 and GetPlayerPed(player) or 0
    end)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    for _, source in pairs(sources) do
        stopLoop(source)
    end
end)
