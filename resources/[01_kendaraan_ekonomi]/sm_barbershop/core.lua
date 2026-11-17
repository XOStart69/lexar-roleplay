Config = require 'config.shared'

if lib.context == 'server' then
    Core = exports.sm_core
    Sync = require 'modules.sync.server'
    Text = require 'modules.text'
    Wear = require 'modules.wear.server'
    Pricing = require 'modules.pricing'
    Storage = require 'modules.storage'
    Shops = require 'modules.shops.server'
    Staff = require 'modules.staff.server'
    Roles = require 'modules.roles.server'
    Portable = require 'modules.portable.server'
else

    -- exports.ox_target:addModel(Config.chairModels, {
        
    --     {
    --         icon = 'fa-solid fa-clipboard',
    --         label = 'Copy Coords',
    --         onSelect = function(data)
    --             local coords = GetEntityCoords(cache.ped)
    --             local chairCoords = GetEntityCoords(data.entity)
    --             local chairHeading = GetEntityHeading(data.entity)
    --             local format = ('vector4(%.2f, %.2f, %.2f, %.2f)'):format(chairCoords.x, chairCoords.y, chairCoords.z, chairHeading)

    --             lib.setClipboard(format)
    --         end
    --     }
    -- })
end

local modules = { 'session', 'management', 'portable' }

for i = 1, #modules do
    require(('modules.%s.%s'):format(modules[i], lib.context))
end
