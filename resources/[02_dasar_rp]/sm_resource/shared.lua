---@meta

tbl = lib.table
array = lib.array
str = lib.string

qb_ecore = exports['qb-core']
qb_jobs = qb_ecore:GetSharedJobs()
illenium_appearance = exports['illenium-appearance']

ox_doorlock = exports.ox_doorlock
ox_inventory = exports.ox_inventory
db = exports.oxmysql

if lib.context == 'client' then
    ox_target = exports.ox_target
    playerState = LocalPlayer.state
    emotemenu = exports.sm_emotes
end

ox_items = ox_inventory and ox_inventory:Items()

---@class QBCoreVehicles
---@overload fun(name: string): table
---@field hash fun(hash: number): table
qb_vehicles = setmetatable({}, {
    __call = function (t, name)
        return qb_ecore:GetVehiclesByName(name)
    end
})

function qb_vehicles.hash(hash)
    return qb_ecore:GetVehiclesByHash(hash)
end

---@class FuelSystem
sm_fuel = {}