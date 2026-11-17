local LoadResourceFile = LoadResourceFile
local GetVehicleClassFromName = GetVehicleClassFromName
local GetVehicleClass = GetVehicleClass
local GetIsDoorValid = GetIsDoorValid
local GetEntityBoneIndexByName = GetEntityBoneIndexByName
local joaat = joaat
local load = load
local type = type

local storageData

local function loadStorageData()
    if storageData then
        return storageData
    end

    local chunk = LoadResourceFile('ox_inventory', 'data/vehicles.lua')

    if not chunk then
        return
    end

    local fn = load(chunk, '@ox_inventory/data/vehicles.lua', 't')

    if not fn then
        return
    end

    local ok, data = pcall(fn)

    if not ok or type(data) ~= 'table' then
        return
    end

    storageData = data
    return storageData
end

---@param container table
---@param model string
---@param class number
---@return number? slots
---@return number? weight
local function resolve(container, model, class)
    if not container then
        return
    end

    local models = container.models
    local byModel = models and models[joaat(model)]

    if byModel then
        return byModel[1], byModel[2]
    end

    local byClass = container[class]

    if byClass then
        return byClass[1], byClass[2]
    end
end

---@class VehicleStorageInfo
---@field trunkSlots number?
---@field trunkWeight number?
---@field gloveSlots number?
---@field gloveWeight number?
---@field storageType number?

---@param model string
---@return VehicleStorageInfo?
local function getStorage(model)
    local data = loadStorageData()

    if not data then
        return
    end

    local hash = joaat(model)
    local class = GetVehicleClassFromName(hash)
    local storage = data.Storage
    local storageType = storage and storage[hash]
    local info = { storageType = storageType }

    if storageType ~= 0 and storageType ~= 1 then
        info.trunkSlots, info.trunkWeight = resolve(data.trunk, model, class)
    end

    if storageType ~= 0 and storageType ~= 2 then
        info.gloveSlots, info.gloveWeight = resolve(data.glovebox, model, class)
    end

    return info
end

---@param entity number
---@param model string
---@return boolean
local function hasTrunkDoor(entity, model)
    local data = loadStorageData()

    if not data then
        return true
    end

    local hash = joaat(model)
    local storage = data.Storage
    local checkVehicle = storage and storage[hash]
    local doorId = checkVehicle and 4 or 5
    local boneIndex = data.trunk and data.trunk.boneIndex

    if boneIndex and boneIndex[hash] then
        return true
    end

    if GetIsDoorValid(entity, doorId) then
        return true
    end

    local class = GetVehicleClass(entity)

    if class == 11 then
        return true
    end

    if doorId ~= 5 then
        return false
    end

    return GetEntityBoneIndexByName(entity, 'boot') == -1 and GetIsDoorValid(entity, 2)
end

return {
    getStorage = getStorage,
    hasTrunkDoor = hasTrunkDoor
}
