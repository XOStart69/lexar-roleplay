---@class NuiCallback
---@field server fun(name: string)
---@overload fun(name: string, cb: fun(data: table, cb: fun(...)))
local callback = setmetatable({}, {
    __call = function (self, name, cb)
        return RegisterNUICallback(name, cb)
    end
})

callback('getApiConfig', function (_, cb)
    cb(require 'config.api')
end)

callback('closeGarage', function (_, cb)
    SetNuiFocus(false, false)
    cb({ success = true})
end)

callback('fetchGarageVehicles', function (_, cb)
    cb({ vehicles = Client.prepareVehicles(), favorites = Client.getFavorites() })
end)

callback('getVehicleDetails', function (data, cb)
    cb({ details = utils.getVehicleStats(data) })
end)

callback('takeOutVehicle', function (data, cb)
    cb({ spawned = lib.callback.await('rhd_garage:server:spawnVehicle', 500, data) })
end)

callback('toggleFavorite', function (data, cb)
    local favorites = Client.toggleFavorite(data.plate)
    cb({ favorites = favorites })
end)