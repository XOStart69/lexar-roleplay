local default = {}

default.vehicles = {}
default.garages = {}
default.items = {}
default.peds = lib.loadJson('data.peds')

local vehicles = qb_core:GetSharedVehicles()

for _, v in pairs(vehicles) do
    default.vehicles[#default.vehicles+1] = {
        label = ('%s %s (%s)'):format(v.brand, v.name, v.model),
        value = v.model
    }
end

for _, v in pairs(inventory:Items()) do
    default.items[#default.items+1] = {
        label = ('%s (%s)'):format(v.label, v.name),
        value = v.name
    }
end

return default