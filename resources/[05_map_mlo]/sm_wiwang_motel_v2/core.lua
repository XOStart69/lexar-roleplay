local server = lib.context == 'server'

Core = exports.sm_core
Inventory = exports.ox_inventory

if server then
    Event = require 'modules.net'
    Storage = require 'modules.storage'
    Staff = require 'modules.staff.server'

else
    local blipcoords = vec(-832.7085, -694.9909, 27.2793)
    local blip = AddBlipForCoord(blipcoords.x, blipcoords.y, blipcoords.z)
    SetBlipSprite(blip, 475)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.8)
    SetBlipColour(blip, 5)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName("AVENUE ROYALE HOTEL")
    EndTextCommandSetBlipName(blip)
end

local modules = {
    'management',
    'doorlock',
    'room',
}

for i=1, #modules do
    local module = modules[i]
    local path = ('modules.%s.%s'):format(module, lib.context)
    require(path)
end
