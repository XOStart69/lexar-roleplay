---@meta

QBCore = {}
QBCore.Config = QBConfig
QBCore.Shared = QBShared
QBCore.ClientCallbacks = {}
QBCore.ServerCallbacks = {}

if lib.context == 'server' then
    QBCore.Player_Buckets = {}
    QBCore.Entity_Buckets = {}
    QBCore.UsableItems = {}
else
    QBCore.PlayerData = {}
end

inventory = setmetatable({}, {
    __index = function(self, index)
        self[index] = function(...)
            return exports.ox_inventory[index](nil, ...)
        end
        return self[index]
    end
})

db = setmetatable({}, {
    __index = function(self, index)
        self[index] = function(...)
            return exports.oxmysql[index](nil, ...)
        end
        return self[index]
    end
})

lib = lib or {}
tbl = lib.table
array = lib.array

require 'lib.shared'

local function getCore(filters)
    if not filters then return QBCore end

    local results = {}
    for i = 1, #filters do
        local key = filters[i]
        if QBCore[key] then
            results[key] = QBCore[key]
        end
    end

    return results
end

local qbExport = require 'export-functions'
qbExport('GetCoreObject', getCore)

local function GetSharedItems()
    return QBShared.Items
end

exports('GetSharedItems', GetSharedItems)
qbExport('GetSharedItems', GetSharedItems)

local function GetSharedVehicles()
    return QBShared.Vehicles
end

exports('GetSharedVehicles', GetSharedVehicles)
qbExport('GetSharedVehicles', GetSharedVehicles)

local function GetVehiclesByName(key)
    local vehicles = QBShared.Vehicles
    return vehicles[key]
end

exports('GetVehiclesByName', GetVehiclesByName)
qbExport('GetVehiclesByName', GetVehiclesByName)

local function GetVehiclesByHash(key)
    local vehicles = QBShared.VehicleHashes
    return vehicles[key]
end

exports('GetVehiclesByHash', GetVehiclesByHash)
qbExport('GetVehiclesByHash', GetVehiclesByHash)

local function GetSharedWeapons()
    return QBShared.Weapons
end

exports('GetSharedWeapons', GetSharedWeapons)
qbExport('GetSharedWeapons', GetSharedWeapons)

local function GetSharedJobs()
    return QBShared.Jobs
end

exports('GetSharedJobs', GetSharedJobs)
qbExport('GetSharedJobs', GetSharedJobs)

local function GetSharedGangs()
    return QBShared.Gangs
end

exports('GetSharedGangs', GetSharedGangs)
qbExport('GetSharedGangs', GetSharedGangs)
