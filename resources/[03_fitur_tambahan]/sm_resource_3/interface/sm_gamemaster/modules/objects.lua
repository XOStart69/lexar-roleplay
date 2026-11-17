local config = localmodule 'config'

local type = type
local pairs = pairs
local tonumber = tonumber
local joaat = joaat
local Wait = Wait
local CreateThread = CreateThread
local DoesEntityExist = DoesEntityExist
local DeleteEntity = DeleteEntity
local IsModelInCdimage = IsModelInCdimage
local RequestModel = RequestModel
local HasModelLoaded = HasModelLoaded
local SetModelAsNoLongerNeeded = SetModelAsNoLongerNeeded
local CreateObjectNoOffset = CreateObjectNoOffset
local SetEntityRotation = SetEntityRotation
local FreezeEntityPosition = FreezeEntityPosition
local SetEntityCanBeDamaged = SetEntityCanBeDamaged
local SetEntityInvincible = SetEntityInvincible

local STREAM_RADIUS = config.objects.streamRadius

local objects = {}

---@class GmObjectRecord
---@field id string
---@field model string
---@field x number
---@field y number
---@field z number
---@field rx number
---@field ry number
---@field rz number
---@field persist boolean

---@type table<string, GmObjectRecord>
local records = {}
---@type table<string, CPoint>
local points = {}
---@type table<string, integer>
local spawned = {}
---@type table<integer, string>
local idByEntity = {}

---@param hash integer
---@return boolean
local function loadModel(hash)
    if not IsModelInCdimage(hash) then return false end

    RequestModel(hash)

    local tries = 0

    while not HasModelLoaded(hash) do
        tries += 1

        if tries > 250 then return false end

        Wait(20)
    end

    return true
end

---@param id string
local function despawn(id)
    local entity = spawned[id]

    if not entity then return end

    spawned[id] = nil
    idByEntity[entity] = nil

    if DoesEntityExist(entity) then
        DeleteEntity(entity)
    end
end

---@param id string
local function spawnLocal(id)
    local record = records[id]

    if not record or spawned[id] then return end

    local hash = joaat(record.model)

    if not loadModel(hash) then return end

    local point = points[id]

    if records[id] ~= record or not point or not point.inside or spawned[id] then
        SetModelAsNoLongerNeeded(hash)
        return
    end

    local entity = CreateObjectNoOffset(hash, record.x, record.y, record.z, false, false, false)

    SetModelAsNoLongerNeeded(hash)

    if entity == 0 then return end

    SetEntityRotation(entity, record.rx, record.ry, record.rz, 2, true)
    FreezeEntityPosition(entity, true)
    SetEntityCanBeDamaged(entity, false)
    SetEntityInvincible(entity, true)

    spawned[id] = entity
    idByEntity[entity] = id
end

---@param record GmObjectRecord
local function addPoint(record)
    local point = lib.points.new({
        coords = vector3(record.x, record.y, record.z),
        distance = STREAM_RADIUS,
        objectId = record.id,
        inside = false,
    })

    function point:onEnter()
        self.inside = true

        local id = self.objectId

        CreateThread(function()
            spawnLocal(id)
        end)
    end

    function point:onExit()
        self.inside = false
        despawn(self.objectId)
    end

    points[record.id] = point
end

---@param id string
local function removePoint(id)
    local point = points[id]

    if point then
        point:remove()
        points[id] = nil
    end

    despawn(id)
end

---@param value any
---@return GmObjectRecord?
local function toRecord(value)
    if type(value) ~= 'table' or type(value.id) ~= 'string' or type(value.model) ~= 'string' then return nil end

    local x = tonumber(value.x)
    local y = tonumber(value.y)
    local z = tonumber(value.z)

    if not x or not y or not z then return nil end

    return {
        id = value.id,
        model = value.model,
        x = x,
        y = y,
        z = z,
        rx = tonumber(value.rx) or 0.0,
        ry = tonumber(value.ry) or 0.0,
        rz = tonumber(value.rz) or 0.0,
        persist = value.persist == true,
    }
end

---@param list any
function objects.setAll(list)
    for id in pairs(points) do
        removePoint(id)
    end

    records = {}

    if type(list) ~= 'table' then return end

    for i = 1, #list do
        local record = toRecord(list[i])

        if record then
            records[record.id] = record
            addPoint(record)
        end
    end
end

---@param value any
function objects.add(value)
    local record = toRecord(value)

    if not record then return end

    removePoint(record.id)
    records[record.id] = record
    addPoint(record)
end

---@param value any
function objects.update(value)
    objects.add(value)
end

---@param ids any
function objects.remove(ids)
    if type(ids) ~= 'table' then return end

    for i = 1, #ids do
        local id = ids[i]

        if type(id) == 'string' then
            removePoint(id)
            records[id] = nil
        end
    end
end

---@param entity integer
---@return string?
function objects.idOf(entity)
    return idByEntity[entity]
end

---@param id string
---@return GmObjectRecord?
function objects.record(id)
    return records[id]
end

---@param id string
---@return integer?
function objects.entityOf(id)
    return spawned[id]
end

---@return integer
function objects.count()
    local count = 0

    for _ in pairs(records) do
        count += 1
    end

    return count
end

---@return GmObjectRecord[]
function objects.list()
    local result = {}
    local count = 0

    for _, record in pairs(records) do
        count += 1
        result[count] = record
    end

    return result
end

---@return integer[]
function objects.entities()
    local result = {}
    local count = 0

    for _, entity in pairs(spawned) do
        count += 1
        result[count] = entity
    end

    return result
end

function objects.clear()
    for id in pairs(points) do
        removePoint(id)
    end

    records = {}
end

return objects
