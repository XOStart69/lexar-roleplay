
interface.init(false)

local frameToken = 0

RegisterNetEvent('simplebadge:show', function (image)
    if source == '' then return end

    frameToken += 1
    local token = frameToken

    interface.show()

    SetTimeout(6000, function()
        if token == frameToken then
            interface.hide()
        end
    end)

    interface.send({
        action = 'show_simplebadge',
        data = {
            image = image,
        }
    })
end)