local targets = require 'server.items'

RegisterNetEvent('sm_nui_browser:openMdt', function(itemName)
    local source = source

    itemName = itemName or 'pol_mdt'

    if not targets[itemName] then return end

    TriggerClientEvent('sm_nui_browser:open', source, targets[itemName].url, targets[itemName].title, targets[itemName].anim)
end)

RegisterNetEvent('sm_nui_browser:server:open', function(url, title, anim)
    local source = source

    if type(url) ~= 'string' or url:find('^https?://') ~= 1 then return end

    TriggerClientEvent('sm_nui_browser:open', source, url, title, anim)
end)

RegisterNetEvent('sm_nui_browser:server:close', function()
    TriggerClientEvent('sm_nui_browser:close', source)
end)

lib.print.info('sm_nui_browser server siap')
