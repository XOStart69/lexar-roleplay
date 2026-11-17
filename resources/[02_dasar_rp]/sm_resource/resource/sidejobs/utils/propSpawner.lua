local objects, active, sessions = {}, {}, {}

local function generateId()
    return lib.string.random('........-....-....-....-............')
end

local function getDimensions(model)
    local min, max = GetModelDimensions(model)
    local size = max - min
    return { radius = math.max(size.x, size.y) / 2, height = size.z }
end

local function getGroundZ(x, y, z)
    for i = math.floor(z), 400 do
        local found, groundZ = GetGroundZFor_3dCoord(x, y, i + 0.0, false)
        if found then return groundZ end
    end
    return z
end

local function isValidSpawn(x, y, z, centerZ, indoor)
    if indoor then return true, z end

    local found, groundZ, normal = GetGroundZAndNormalFor_3dCoord(x, y, z + 50.0)
    if not found or groundZ == 0 or (normal and normal.z < 0.85) then return false end
    if centerZ and math.abs(groundZ - centerZ) > 5.0 then return false end

    local _, hitDown = GetShapeTestResult(StartShapeTestRay(x, y, groundZ + 1.0, x, y, groundZ - 2.0, 17, 0, 0))
    local _, hitUp = GetShapeTestResult(StartShapeTestRay(x, y, groundZ + 1.0, x, y, groundZ + 100.0, 17, 0, 0))

    return hitDown and not hitUp, groundZ
end

local function isTooClose(key, coords, minDist)
    local obj = objects[key]
    if not obj then return false end

    for _, ent in pairs(obj.entities) do
        if ent and DoesEntityExist(ent) and #(coords - GetEntityCoords(ent)) < minDist then
            return true
        end
    end
    return false
end

local function findValidCoord(center, radius, key, model, minDist, session, indoor)
    local dim = getDimensions(model)
    minDist = minDist or (dim.radius * 3)

    for _ = 1, 100 do
        if not active[key] or sessions[key] ~= session then return end
        Wait(50)

        local x, y = center.x + math.random(-radius, radius), center.y + math.random(-radius, radius)

        if #(vec(x, y, center.z) - center) <= radius then
            local groundZ = indoor and center.z or getGroundZ(x, y, center.z)
            local valid, actualZ = isValidSpawn(x, y, groundZ, center.z, indoor)

            if valid then
                local coords = vec(x, y, actualZ or groundZ)
                if not isTooClose(key, coords, minDist) then return coords end
            end
        end
    end
end

local function deleteEntity(ent)
    if DoesEntityExist(ent) then
        SetEntityAsMissionEntity(ent, true, true)
        DeleteEntity(ent)
    end
end

---@class PropSpawner
local PropSpawner = {}

function PropSpawner.activate(key)
    sessions[key] = generateId()
    active[key] = true
end

function PropSpawner.deactivate(key)
    PropSpawner.removeAll(key)
end

function PropSpawner.isActive(key)
    return active[key] == true
end

---@class SpawnData
---@field key string
---@field model string|number
---@field coords vector3
---@field positions? vector3[]
---@field maxSpawn? number
---@field distance? number
---@field minDistance? number
---@field respawnTime? number
---@field indoor? boolean
---@field onSpawn? fun(id: string, entity: number, coords: vector3)

function PropSpawner.spawn(data, index)
    local key, model = data.key, data.model
    if not key or not model or not active[key] then return end

    model = type(model) == 'string' and joaat(model) or model

    if not objects[key] then
        objects[key] = { entities = {}, used = {}, map = {}, total = 0, config = data, positions = data.positions }
    else
        objects[key].config = data
        if data.positions then objects[key].positions = data.positions end
    end

    local obj = objects[key]
    local positions = obj.positions
    local maxSpawn = positions and #positions or (data.maxSpawn or 15)

    if obj.total >= maxSpawn then return end

    local session = sessions[key]
    lib.requestModel(model, 5000)

    if not active[key] or sessions[key] ~= session then return end

    local spawnCoords

    if positions then
        if not index or index < 1 or index > #positions or obj.used[index] then return end
        local distance = #(positions[index].xyz - data.coords.xyz)

        if math.floor(distance) > data.distance then
            return
        end

        spawnCoords = positions[index] --[[@as vector4]]
        obj.used[index] = true
    else
        spawnCoords = findValidCoord(data.coords, data.distance or 20, key, model, data.minDistance, session, data.indoor)
    end

    if not spawnCoords or not active[key] or sessions[key] ~= session then return end

    local ent = CreateObject(model, spawnCoords.x, spawnCoords.y, spawnCoords.z, false, false, false)
    SetEntityHeading(ent, spawnCoords.w or math.random(0, 360) + 0.0)

    if not data.indoor then PlaceObjectOnGroundProperly(ent) end

    FreezeEntityPosition(ent, true)
    SetEntityProofs(ent, true, true, true, true, true, true, true, true)

    local id = generateId()
    obj.entities[id], obj.map[id], obj.total = ent, index, obj.total + 1

    if data.onSpawn then data.onSpawn(id, ent, spawnCoords) end

    return id, ent, spawnCoords
end

function PropSpawner.remove(key, id, respawn)
    local obj = objects[key]
    if not obj or not obj.entities[id] then return end

    deleteEntity(obj.entities[id])

    local posIndex = obj.map[id]
    obj.entities[id], obj.map[id], obj.total = nil, nil, math.max(0, obj.total - 1)

    if respawn and obj.config and active[key] then
        local session = sessions[key]

        SetTimeout((obj.config.respawnTime or 5) * 1000, function()
            if active[key] and sessions[key] == session then
                if posIndex then obj.used[posIndex] = nil end
                PropSpawner.spawn(obj.config, posIndex)
            end
        end)
    end
end

function PropSpawner.removeAll(key)
    active[key] = false

    local obj = objects[key]
    if not obj then return end

    for _, ent in pairs(obj.entities) do
        deleteEntity(ent)
    end

    objects[key] = { entities = {}, used = {}, map = {}, total = 0, config = obj.config, positions = obj.positions }
end

function PropSpawner.findIdByEntity(key, entity)
    local obj = objects[key]
    if not obj then return end

    for id, ent in pairs(obj.entities) do
        if ent == entity then return id end
    end
end

function PropSpawner.findNearest(key)
    local obj = objects[key]
    if not obj then return end

    local pc = GetEntityCoords(cache.ped)
    local nearest, nearestDist

    for _, ent in pairs(obj.entities) do
        if ent and DoesEntityExist(ent) then
            local dist = #(pc - GetEntityCoords(ent))
            if not nearestDist or dist < nearestDist then
                nearest, nearestDist = ent, dist
            end
        end
    end

    return nearest, nearestDist
end

function PropSpawner.spawnProgressProps(propsData)
    if not propsData then return {} end

    local entities = {}

    for _, prop in ipairs(propsData) do
        local model = lib.requestModel(prop.model)

        if model then
            local coords

            if prop.frontped then
                local pc = GetEntityCoords(cache.ped)
                local fwd = GetEntityForwardVector(cache.ped)
                coords = vec(pc.x + fwd.x * 0.8, pc.y + fwd.y * 0.8, pc.z - 0.5)
            else
                coords = prop.coords
            end

            local ent = CreateObject(model, coords.x, coords.y, coords.z, false, false, false)
            SetEntityHeading(ent, prop.heading or GetEntityHeading(cache.ped))

            if prop.ground ~= false then PlaceObjectOnGroundProperly(ent) end

            FreezeEntityPosition(ent, true)
            entities[#entities + 1] = ent
        end
    end

    return entities
end

function PropSpawner.deleteProgressProps(entities)
    for i = 1, #(entities or {}) do
        if DoesEntityExist(entities[i]) then DeleteEntity(entities[i]) end
    end
end

AddEventHandler('onResourceStop', function(res)
    if res == cache.resource then
        for key in pairs(objects) do
            PropSpawner.removeAll(key)
        end
    end
end)

return PropSpawner
