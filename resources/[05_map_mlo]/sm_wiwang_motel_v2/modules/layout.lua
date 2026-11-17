local config = require 'config.shared'
local rooms = require 'data.rooms'

local roomsPerFloor = math.max(1, tonumber(config.management.roomsPerFloor) or 12)
local storageConfig = config.room.storage
local occupantConfig = config.room.occupants

---@class MotelRoomLayout
---@field id string
---@field floor integer
---@field number integer

local Layout = {}

---@type MotelRoomLayout[]
local entries = {}

---@type table<string, MotelRoomLayout>
local entryById = {}

for index = 1, #rooms do
    local id = rooms[index].id

    local entry = {
        id = id,
        floor = math.ceil(index / roomsPerFloor),
        number = tonumber(id:match('^room_(%d+)$')) or index,
    }

    entries[index] = entry
    entryById[entry.id] = entry
end

---@param entry MotelRoomLayout
---@param source table
local function roomOverride(entry, source)
    local floorRooms = source.rooms and source.rooms[entry.floor]

    return floorRooms and floorRooms[entry.number]
end

---@param entry MotelRoomLayout
---@param source table
local function floorOverride(entry, source)
    return source.floors and source.floors[entry.floor]
end

---@return MotelRoomLayout[]
function Layout.list()
    return entries
end

---@param roomId string
---@return MotelRoomLayout?
function Layout.get(roomId)
    return entryById[roomId]
end

---@param roomId string
---@return integer slots
---@return integer weight
function Layout.getStorage(roomId)
    local entry = entryById[roomId]
    local slots = storageConfig.slots
    local weight = storageConfig.weight

    if entry then
        local floorValue = floorOverride(entry, storageConfig)
        local roomValue = roomOverride(entry, storageConfig)

        slots = (roomValue and roomValue.slots) or (floorValue and floorValue.slots) or slots
        weight = (roomValue and roomValue.weight) or (floorValue and floorValue.weight) or weight
    end

    -- Berat di config ditulis dalam kilogram, ox_inventory memakai gram.
    return math.max(1, math.floor(tonumber(slots) or 50)), math.max(1, math.floor((tonumber(weight) or 1000) * 1000))
end

---@param roomId string
---@return integer
function Layout.getMaxOccupants(roomId)
    local entry = entryById[roomId]
    local value = occupantConfig.max

    if entry then
        value = roomOverride(entry, occupantConfig) or floorOverride(entry, occupantConfig) or value
    end

    return math.max(1, math.floor(tonumber(value) or 1))
end

---@return integer
function Layout.getExtraOccupantPrice()
    return math.max(0, math.floor(tonumber(occupantConfig.extraPrice) or 0))
end

return Layout
