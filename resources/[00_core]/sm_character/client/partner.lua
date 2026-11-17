local select = require 'client.select'

RegisterNetEvent('sm_characters:client:partnerSync', function(kind, payload)
    if GetInvokingResource() then return end

    select.sync(kind, payload)
end)

RegisterNetEvent('sm_characters:client:notify', function(data)
    if GetInvokingResource() then return end

    lib.notify(data)
end)
