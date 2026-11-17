local actions = {"sendMessage", "createGroup", "renameGroup"}

RegisterNUICallback("Messages", function(data, cb)
    if not currentPhone then
        return
    end
    local action = data.action
    debugprint("Messages:" .. (action or ""))
    if table.contains(actions, action) then
        if not CanInteract() then
            return cb(false)
        end
    end
    if data.attachments and #data.attachments > 0 then
        data.attachments = json.encode(data.attachments)
    else
        data.attachments = nil
    end
    if "sendMessage" == action then
        TriggerServerEvent("phone:messages:messageSent", data.number, data.content, data.attachments)
        TriggerCallback("messages:sendMessage", cb, data.number, data.content, data.attachments, data.replyTo, data.id)
    elseif "createGroup" == action then
        local members = {}
        for i = 1, #data.members do
            members[i] = data.members[i].number
        end
        TriggerCallback("messages:createGroup", cb, members, data.content, data.attachments)
    elseif "renameGroup" == action then
        TriggerCallback("messages:renameGroup", cb, data.id, data.name)
    elseif "getRecentMessages" == action then
        local messages = AwaitCallback("messages:getRecentMessages")
        local channels = {}
        local function findChannel(id)
            for i = 1, #channels do
                if channels[i].id == id then
                    return i
                end
            end
            return false
        end
        for i = 1, #messages do
            local msg = messages[i]
            local index = findChannel(msg.channel_id)
            if not index then
                if msg.is_group then
                    channels[#channels + 1] = {
                        id = msg.channel_id,
                        lastMessage = msg.last_message,
                        timestamp = msg.last_message_timestamp,
                        name = msg.name,
                        isGroup = true,
                        members = {
                            {
                                isOwner = msg.is_owner,
                                number = msg.phone_number
                            }
                        }
                    }
                elseif msg.phone_number ~= currentPhone then
                    channels[#channels + 1] = {
                        id = msg.channel_id,
                        lastMessage = msg.last_message,
                        timestamp = msg.last_message_timestamp,
                        number = msg.phone_number,
                        isGroup = false
                    }
                end
            elseif msg.is_group then
                local groupMembers = channels[index].members
                groupMembers[#groupMembers + 1] = {
                    isOwner = msg.is_owner,
                    number = msg.phone_number
                }
            end
        end
        for i = 1, #messages do
            local msg = messages[i]
            local index = findChannel(msg.channel_id)
            if index and msg.phone_number == currentPhone then
                channels[index].deleted = msg.deleted
                channels[index].unread = msg.unread > 0
            end
        end
        cb(channels)
    elseif "getMessages" == action then
        TriggerCallback("messages:getMessages", function(messages)
            for i = 1, #messages do
                local msg = messages[i]
                if msg.attachments then
                    msg.attachments = json.decode(msg.attachments)
                end
                if msg.reply_message then
                    msg.reply = {
                        id = msg.reply_to,
                        sender = msg.reply_sender,
                        message = msg.reply_message,
                        attachment = msg.reply_attachment
                    }
                    msg.reply_to = nil
                    msg.reply_sender = nil
                    msg.reply_message = nil
                    msg.reply_attachment = nil
                end
            end
            cb(messages)
        end, data.id, data.lastId)
    elseif "deleteMessage" == action then
        if Config.DeleteMessages then
            TriggerCallback("messages:deleteMessage", cb, data.id, data.channel)
        end
    elseif "addMember" == action then
        TriggerCallback("messages:addMember", cb, data.id, data.number)
    elseif "removeMember" == action then
        TriggerCallback("messages:removeMember", cb, data.id, data.number)
    elseif "leaveGroup" == action then
        TriggerCallback("messages:leaveGroup", cb, data.id)
    elseif "markRead" == action then
        TriggerCallback("messages:markRead", cb, data.id)
    elseif "deleteConversations" == action then
        TriggerCallback("messages:deleteConversations", cb, data.channels)
    elseif "toggleReaction" == action then
        TriggerCallback("messages:toggleReaction", cb, data.messageId, data.reaction, data.toggle)
    end
end)

RegisterNetEvent("phone:messages:newMessage", function(channelId, messageId, sender, content, attachments, replyData)
    local payload = {}
    payload.channelId = channelId
    payload.messageId = messageId
    payload.sender = sender
    payload.content = content
    payload.attachments = (attachments and json.decode(attachments)) or {}
    if replyData then
        payload.reply = {
            sender = replyData.sender,
            message = replyData.content,
            attachment = replyData.attachments ~= nil
        }
    else
        payload.reply = payload.attachments
    end
    SendNUIAction("messages:newMessage", payload)
end)

RegisterNetEvent("phone:messages:messageDeleted", function(channelId, messageId, isLastMessage)
    SendNUIAction("messages:messageDeleted", {
        channelId = channelId,
        messageId = messageId,
        isLastMessage = isLastMessage
    })
end)

RegisterNetEvent("phone:messages:renameGroup", function(channelId, name)
    SendNUIAction("messages:renameGroup", {
        channelId = channelId,
        name = name
    })
end)

RegisterNetEvent("phone:messages:memberAdded", function(channelId, number)
    SendNUIAction("messages:addMember", {
        channelId = channelId,
        number = number
    })
end)

RegisterNetEvent("phone:messages:memberRemoved", function(channelId, number)
    SendNUIAction("messages:removeMember", {
        channelId = channelId,
        number = number
    })
end)

RegisterNetEvent("phone:messages:ownerChanged", function(channelId, number)
    SendNUIAction("messages:changeOwner", {
        channelId = channelId,
        number = number
    })
end)

RegisterNetEvent("phone:messages:newChannel", function(data)
    SendNUIAction("messages:newChannel", data)
end)

RegisterNetEvent("phone:messages:toggleReaction", function(data)
    SendNUIAction("messages:toggleReaction", data)
end)
