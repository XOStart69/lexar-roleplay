local config = localmodule 'config'

local Wait = Wait
local GetGameTimer = GetGameTimer
local DoesEntityExist = DoesEntityExist
local GetEntityCoords = GetEntityCoords
local GetEntityHeading = GetEntityHeading
local GetEntityModel = GetEntityModel
local GetModelDimensions = GetModelDimensions
local GetEntityHeightAboveGround = GetEntityHeightAboveGround
local IsEntityInAir = IsEntityInAir
local SetEntityMatrix = SetEntityMatrix
local GetGroundZFor_3dCoord = GetGroundZFor_3dCoord
local GetPlayerFromServerId = GetPlayerFromServerId
local GetPlayerPed = GetPlayerPed
local NetworkDoesNetworkIdExist = NetworkDoesNetworkIdExist
local NetworkGetEntityFromNetworkId = NetworkGetEntityFromNetworkId
local smatch = string.match
local rad, sin, cos = math.rad, math.sin, math.cos
local tonumber, type, pairs, next = tonumber, type, pairs, next

local RIDE = config.ride

if not RIDE.youngScaleOutside then return end

local RANGE_SQ = RIDE.scaleRenderDistance * RIDE.scaleRenderDistance
local REFRESH_MS = 500
local SETTLE_MS = 1500
local GIVE_UP_MS = 6000

---@type table<integer, number>
local entityScales = {}
---@type table<integer, number>
local playerScales = {}
---@type table<integer, number>
local lifts = {}
---@type table<integer, number>
local fallbacks = {}
---@type table<integer, integer>
local firstSeen = {}
---@type { entity: integer, scale: number, lift: number }[]
local active = {}
local activeCount = 0
local running = false

---@param model integer
---@return number
local function fallbackLift(model)
    local lift = fallbacks[model]

    if lift then return lift end

    local minimum = GetModelDimensions(model)

    lift = -minimum.z

    if lift < 0.2 or lift > 2.0 then
        lift = 0.5
    end

    fallbacks[model] = lift

    return lift
end

---@param entity integer
---@param now integer
---@return number|nil
local function liftOf(entity, now)
    local model = GetEntityModel(entity)
    local lift = lifts[model]

    if lift then return lift end

    local seen = firstSeen[entity]

    if not seen then
        firstSeen[entity] = now
        return
    end

    local waited = now - seen

    if waited >= SETTLE_MS and not IsEntityInAir(entity) then
        local height = GetEntityHeightAboveGround(entity)

        if height > 0.1 and height < 3.0 then
            lifts[model] = height

            return height
        end
    end

    if waited >= GIVE_UP_MS then
        return fallbackLift(model)
    end
end

---@param entity integer
---@param scale number
---@param me vector3
---@param now integer
local function track(entity, scale, me, now)
    if entity == 0 or not DoesEntityExist(entity) then return end

    local pos = GetEntityCoords(entity)
    local dx, dy = pos.x - me.x, pos.y - me.y

    if dx * dx + dy * dy > RANGE_SQ then return end

    local lift = liftOf(entity, now)

    if not lift then return end

    activeCount += 1

    local slot = active[activeCount]

    if slot then
        slot.entity = entity
        slot.scale = scale
        slot.lift = lift
    else
        active[activeCount] = { entity = entity, scale = scale, lift = lift }
    end
end

local function refresh()
    local me = GetEntityCoords(cache.ped)
    local now = GetGameTimer()

    for entity in pairs(firstSeen) do
        if not DoesEntityExist(entity) then
            firstSeen[entity] = nil
        end
    end

    activeCount = 0

    for netId, scale in pairs(entityScales) do
        if NetworkDoesNetworkIdExist(netId) then
            track(NetworkGetEntityFromNetworkId(netId), scale, me, now)
        end
    end

    for serverId, scale in pairs(playerScales) do
        local player = GetPlayerFromServerId(serverId)

        if player ~= -1 then
            track(GetPlayerPed(player), scale, me, now)
        end
    end
end

---@param slot { entity: integer, scale: number, lift: number }
local function apply(slot)
    local entity = slot.entity

    if not DoesEntityExist(entity) then return end

    local s = slot.scale
    local pos = GetEntityCoords(entity)
    local found, ground = GetGroundZFor_3dCoord(pos.x, pos.y, pos.z + 0.5, false)
    local z = found and ground + slot.lift * s or pos.z - slot.lift * (1.0 - s)
    local h = rad(GetEntityHeading(entity))
    local sh, ch = sin(h), cos(h)

    SetEntityMatrix(
        entity,
        -sh * s, ch * s, 0.0,
        ch * s, sh * s, 0.0,
        0.0, 0.0, s,
        pos.x, pos.y, z
    )
end

local function start()
    if running then return end

    running = true

    CreateThread(function()
        local nextRefresh = 0

        while next(entityScales) or next(playerScales) do
            local now = GetGameTimer()

            if now >= nextRefresh then
                nextRefresh = now + REFRESH_MS
                refresh()
            end

            for i = 1, activeCount do
                apply(active[i])
            end

            Wait(activeCount > 0 and 0 or REFRESH_MS)
        end

        activeCount = 0
        running = false
    end)
end

---@param value any
---@return number|nil
local function readScale(value)
    local scale = tonumber(value)

    if not scale or scale <= 0.1 or scale >= 1.0 then return end

    return scale
end

AddStateBagChangeHandler('smFarmAnimal', nil, function(bagName, _, value)
    local netId = tonumber(smatch(bagName, '^entity:(%d+)$'))

    if not netId then return end

    entityScales[netId] = type(value) == 'table' and readScale(value.scale) or nil

    if entityScales[netId] then
        start()
    end
end)

AddStateBagChangeHandler('smFarmScale', nil, function(bagName, _, value)
    local serverId = tonumber(smatch(bagName, '^player:(%d+)$'))

    if not serverId then return end

    playerScales[serverId] = readScale(value)

    if playerScales[serverId] then
        start()
    end
end)
