interface.init()

RegisterNetEvent('mwannounce:activate', function(message, duration, volume)
    if GetInvokingResource() then return end
    interface.send({
        action = 'mwannounce:show',
        data = {
            message = message,
            duration = duration,
            volume = volume,
        },
    })
end)
