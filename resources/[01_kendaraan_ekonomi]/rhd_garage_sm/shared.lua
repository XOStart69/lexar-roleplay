sm_core = exports.sm_core
inventory = exports.ox_inventory
target = exports.target
garages = exports.sm_garage
db = exports.oxmysql

infoUi = setmetatable({}, {
    __index = function(self, index)
        self[index] = function(...)
            return exports.rhd_infoui[index](nil, ...)
        end
        return self[index]
    end
})

if lib.context == 'client' then
    PlayerState = LocalPlayer.state
else
    PlayerState = function(source)
        return Player(source)?.state
    end
end

---@class QBVehicle
---@field hash fun(hash: number): table
---@overload fun(name: string): table
qb_vehicles = setmetatable({}, {
    __call = function (t, name)
        return sm_core:GetVehiclesByName(name)
    end
})

function qb_vehicles.hash(hash)
    return sm_core:GetVehiclesByHash(hash)
end

require 'modules.utils'