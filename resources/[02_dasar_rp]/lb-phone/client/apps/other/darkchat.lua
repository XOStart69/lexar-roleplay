RegisterNUICallback("DarkChat", function(data, cb)
    if not currentPhone then
        return
    end

    local action = data.action
    debugprint("DarkChat:" .. (action or ""))

    if action == "getUsername" then
        TriggerCallback("darkchat:getUsername", cb)
    elseif action == "setPassword" then
        TriggerCallback("darkchat:setPassword", cb, data.password)
    elseif action == "login" then
        TriggerCallback("darkchat:login", cb, data.username, data.password)
    elseif action == "logout" then
        TriggerCallback("darkchat:logout", cb)
    elseif action == "changePassword" then
        TriggerCallback("darkchat:changePassword", cb, data.oldPassword, data.newPassword)
    elseif action == "deleteAccount" then
        TriggerCallback("darkchat:deleteAccount", cb, data.password)
    elseif action == "register" then
        TriggerCallback("darkchat:register", cb, data.username, data.password)
    elseif action == "getChannels" then
        TriggerCallback("darkchat:getChannels", cb)
    elseif action == "createChannel" then
        TriggerCallback("darkchat:createChannel", cb, data.channel, data.password)
    elseif action == "joinChannel" then
        TriggerCallback("darkchat:joinChannel", cb, data.channel, data.password)
    elseif action == "getMessages" then
        TriggerCallback("darkchat:getMessages", cb, data.channel, data.lastId)
    elseif action == "sendMessage" then
        if not CanInteract() then
            return cb(false)
        end
        TriggerCallback("darkchat:sendMessage", cb, data.channel, data.content)
    elseif action == "leaveChannel" then
        TriggerCallback("darkchat:leaveChannel", cb, data.channel)
    end
end)

RegisterNetEvent("phone:darkChat:newMessage", function(channel, sender, content)
    SendNUIAction("darkChat:newMessage", {
        channel = channel,
        sender = sender,
        content = content
    })
end)

RegisterNetEvent("phone:darkChat:updateChannel", function(channel, username, action)
    SendNUIAction("darkChat:updateChannel", {
        action = action,
        channel = channel,
        username = username
    })
end)

RegisterNetEvent("phone:darkChat:joinChannel", function(channel)
    SendNUIAction("darkChat:addChannel", channel)
end)

RegisterNetEvent("phone:darkChat:leaveChannel", function(channel)
    SendNUIAction("darkChat:leaveChannel", channel)
end)
