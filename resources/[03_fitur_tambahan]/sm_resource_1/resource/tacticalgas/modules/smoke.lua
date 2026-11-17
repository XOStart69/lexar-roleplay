local config = localmodule 'config.shared'

local grenades = config.grenades
local broadcastRadius = config.broadcastRadius
local BROADCAST_RADIUS_SQ = broadcastRadius * broadcastRadius

local MIN_PARTICLE_SIZE = 0.5
local MAX_PARTICLE_SIZE = 2.5
local STEP_INTERVAL = 10000.0
local STALE_TTL = 60000

local RequestNamedPtfxAsset = RequestNamedPtfxAsset
local HasNamedPtfxAssetLoaded = HasNamedPtfxAssetLoaded
local UseParticleFxAssetNextCall = UseParticleFxAssetNextCall
local StartParticleFxLoopedAtCoord = StartParticleFxLoopedAtCoord
local StopParticleFxLooped = StopParticleFxLooped
local GetEntityCoords = GetEntityCoords
local GetGameTimer = GetGameTimer

local clouds = {}
local handles = {}

local smoke = { clouds = clouds }

---@param duration integer
---@param step integer
---@return number
function smoke.sizeForStep(duration, step)
    local scale = duration / STEP_INTERVAL
    if scale <= 0 then return MIN_PARTICLE_SIZE end

    return MIN_PARTICLE_SIZE + ((step / scale) * (MAX_PARTICLE_SIZE - MIN_PARTICLE_SIZE))
end

---@param dict string
local function loadPtfx(dict)
    if HasNamedPtfxAssetLoaded(dict) then return end

    RequestNamedPtfxAsset(dict)

    while not HasNamedPtfxAssetLoaded(dict) do
        Wait(0)
    end
end

smoke.loadPtfx = loadPtfx

---@param id integer
local function stop(id)
    local handle = handles[id]
    if not handle then return end

    StopParticleFxLooped(handle, 0)
    handles[id] = nil
end

---@param id integer
local function start(id)
    local cloud = clouds[id]
    if not cloud or handles[id] then return end

    local grenade = grenades[cloud.grenade]
    if not grenade then return end

    local particle = grenade.particle
    local coords = cloud.coords

    loadPtfx(particle.dict)

    if not clouds[id] then return end

    UseParticleFxAssetNextCall(particle.dict)

    handles[id] = StartParticleFxLoopedAtCoord(
        particle.fx,
        coords.x, coords.y, coords.z + 0.2,
        0.0, 0.0, 0.0,
        smoke.sizeForStep(grenade.duration, cloud.step),
        false, false, false, false
    )
end

---@param cloud TacticalGas_Cloud
---@return TacticalGas_Cloud
local function normalise(cloud)
    local coords = cloud.coords

    if type(coords) ~= 'vector3' then
        cloud.coords = vec3(coords.x, coords.y, coords.z)
    end

    cloud.seenAt = GetGameTimer()

    return cloud
end

---@param list table<integer, TacticalGas_Cloud>?
function smoke.merge(list)
    if not list then return end

    for id, cloud in pairs(list) do
        local known = clouds[id]

        if known then
            known.step = cloud.step
            known.active = cloud.active
            known.seenAt = GetGameTimer()
        else
            clouds[id] = normalise(cloud)
        end
    end
end

---@param id integer
---@param cloud TacticalGas_Cloud
function smoke.add(id, cloud)
    clouds[id] = normalise(cloud)
end

---@param id integer
function smoke.remove(id)
    stop(id)
    clouds[id] = nil
end

---@param id integer
---@param step integer
function smoke.setStep(id, step)
    local cloud = clouds[id]
    if not cloud then return end

    cloud.step = step
    cloud.seenAt = GetGameTimer()

    if handles[id] then
        stop(id)
        start(id)
    end
end

---@param id integer
function smoke.activate(id)
    local cloud = clouds[id]
    if cloud then cloud.active = true end
end

function smoke.refresh()
    local playerCoords = GetEntityCoords(cache.ped)
    local px, py, pz = playerCoords.x, playerCoords.y, playerCoords.z
    local now = GetGameTimer()

    for id, cloud in pairs(clouds) do
        local coords = cloud.coords
        local dx, dy, dz = coords.x - px, coords.y - py, coords.z - pz

        if dx * dx + dy * dy + dz * dz < BROADCAST_RADIUS_SQ then
            cloud.seenAt = now

            start(id)
        else
            stop(id)

            if now - (cloud.seenAt or now) > STALE_TTL then
                clouds[id] = nil
            end
        end
    end
end

---@param cloud TacticalGas_Cloud
---@return number
function smoke.effectRadius(cloud)
    local grenade = grenades[cloud.grenade]
    if not grenade then return 0.0 end

    return smoke.sizeForStep(grenade.duration, cloud.step) * 6
end

function smoke.clear()
    for id in pairs(handles) do
        stop(id)
    end

    for id in pairs(clouds) do
        clouds[id] = nil
    end
end

return smoke
