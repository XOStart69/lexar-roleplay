interface.init(false)

local frameToken = 0

RegisterNetEvent('siaga1:activate', function(message, duration)
    frameToken += 1
    local token = frameToken

    interface.show()

    SetTimeout((tonumber(duration) or 60000) + 1000, function()
        if token == frameToken then
            interface.hide()
        end
    end)

    interface.send({
        action = 'siaga1:show',
        data = {
            message = message,
            duration = duration,
        },
    })
end)
