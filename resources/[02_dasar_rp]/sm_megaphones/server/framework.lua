-- Framework bridge. Config.framework = 'none', jadi semua lewat event/command.

RegisterNetEvent('sm_megaphones:server:use', function()
    TriggerClientEvent('sm_megaphones:client:usemegaphone', source)
end)

RegisterCommand('megaphone', function(source)
    if source == 0 then return end

    TriggerClientEvent('sm_megaphones:client:usemegaphone', source)
end, false)
