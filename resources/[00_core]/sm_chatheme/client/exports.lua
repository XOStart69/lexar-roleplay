exports('addMessage', function(message)
    while not ConfigLoaded do
        Wait(0)
    end

    TriggerServerEvent('sm_chatheme:server:sendMessage', {
        category = 'custom',
        message = message,
        isImage = false,
        mask = false,
    })
end)