local garageConfig = require 'config.garage'

glocations = { registered = {} }

for garageId, garageData in pairs(require 'data.garage') do
    glocations.registered[garageId] = garageData
end

function glocations.register(garageId, garageData)
    glocations.registered[garageId] = garageData
end

function glocations.remove(garageId)
    glocations.registered[garageId] = nil
end

return glocations
