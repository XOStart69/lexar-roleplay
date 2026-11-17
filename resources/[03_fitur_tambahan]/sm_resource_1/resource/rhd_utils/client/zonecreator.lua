local zonecreator = require 'modules.zonecreator.client'

RegisterNetEvent('rutils:createZone', function (type)
    if source == '' then return end
    zonecreator(type)
end)