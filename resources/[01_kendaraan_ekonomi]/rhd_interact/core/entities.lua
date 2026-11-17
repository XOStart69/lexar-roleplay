---@source https://github.com/darktrovx/interact/blob/main/client/entities.lua

local entities = {}

---@type table<integer, EntityData>
local netIds = {}
---@type table<integer, EntityData[]>
local models = {}
---@type table<integer, EntityData>
local localEntities = {}
---@type table<integer, PlayerEntry>
local playersTable = {}

---@type table<string, integer[]>
local byType = {
    vehicle = {},
    ped = {},
    object = {},
}

local NetworkGetNetworkIdFromEntity = NetworkGetNetworkIdFromEntity
local NetworkGetEntityIsNetworked = NetworkGetEntityIsNetworked
local GetEntityModel = GetEntityModel
local GetEntityCoords = GetEntityCoords

local NEARBY_DISTANCE = 20.0

local POOL_TYPE_MAP = {
    CVehicle = 'vehicle',
    CPed = 'ped',
    CObject = 'object',
}

CACHE_COORDS = vec(0.0, 0.0, 0.0)

---@param netID number
---@return integer|false
function entities.isNetIdNearby(netID)
    local entry = netIds[netID]
    return entry and entry.entity
end

---@param model integer
---@return EntityData[]|nil
function entities.getModelEntities(model)
    return models[model]
end

---@param entity integer
---@return EntityData|nil
function entities.isEntityNearby(entity)
    return localEntities[entity]
end

---@param entityType string
---@return integer count, integer[] list, integer[] serverIds
function entities.getEntitiesByType(entityType)
    if entityType == 'players' then
        local count = 0
        local list = {}
        local serverIds = {}

        for _, v in pairs(playersTable) do
            count += 1
            list[count] = v.entity
            serverIds[count] = v.serverId
        end

        return count, list, serverIds
    end

    local typeList = byType[entityType]
    if not typeList then
        return 0, {}, {}
    end

    return #typeList, typeList, {}
end

local function clearTables()
    table.wipe(netIds)
    table.wipe(localEntities)
    table.wipe(models)
    table.wipe(byType.vehicle)
    table.wipe(byType.ped)
    table.wipe(byType.object)
end

---@param eType string
local function buildEntities(eType)
    local entityPool = GetGamePool(eType)
    local entityType = POOL_TYPE_MAP[eType]
    local typeList = byType[entityType]
    local typeCount = #typeList

    for i = 1, #entityPool do
        local entity = entityPool[i]
        local coords = GetEntityCoords(entity)

        if #(CACHE_COORDS - coords) >= NEARBY_DISTANCE then goto continue end

        local isNetworked = NetworkGetEntityIsNetworked(entity)
        local model = GetEntityModel(entity)

        if isNetworked then
            local netId = NetworkGetNetworkIdFromEntity(entity)
            if not netIds[netId] then
                netIds[netId] = { entity = entity, coords = coords }
            end
        else
            localEntities[entity] = { entity = entity, coords = coords }
        end

        if not models[model] then
            models[model] = {}
        end
        models[model][#models[model] + 1] = { entity = entity, coords = coords }

        typeCount += 1
        typeList[typeCount] = entity

        ::continue::
    end
end


CreateThread(function()
    while true do
        CACHE_COORDS = GetEntityCoords(cache.ped or PlayerPedId())
        Wait(250)
    end
end)

CreateThread(function()
    while true do
        clearTables()
        buildEntities('CVehicle')
        buildEntities('CPed')
        buildEntities('CObject')
        Wait(2500)
    end
end)

RegisterNetEvent('onPlayerDropped', function(serverId)
    playersTable[serverId] = nil
end)

RegisterNetEvent('onPlayerJoining', function(serverId)
    local playerId = GetPlayerFromServerId(serverId)

    local ok, response = pcall(lib.waitFor, function()
        local ped = GetPlayerPed(playerId)
        if ped > 0 then return ped end
    end, '', 10000)

    if not ok then
        lib.print.warn(('Failed to get ped for player %d (%d): %s'):format(playerId, serverId, response))
    end

    if not response or not DoesEntityExist(response) then return end

    playersTable[serverId] = {
        entity = response,
        serverId = serverId,
    }
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= cache.resource then return end

    local players = GetActivePlayers()

    for i = 1, #players do
        local playerId = players[i]
        local serverId = GetPlayerServerId(playerId)

        if serverId == cache.serverId then goto continue end

        local ok, response = pcall(lib.waitFor, function()
            local ped = GetPlayerPed(playerId)
            if ped > 0 then return ped end
        end, '', 10000)

        if not ok then
            lib.print.warn(('Failed to get ped for player %d (%d): %s'):format(playerId, serverId, response))
            goto continue
        end

        if response and DoesEntityExist(response) then
            playersTable[serverId] = {
                entity = response,
                serverId = serverId,
            }
        end

        ::continue::
    end
end)

_ENV.Entities = entities