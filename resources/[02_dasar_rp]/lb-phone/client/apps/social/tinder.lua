local actions = {"createAccount", "saveProfile", "sendMessage"}

local function getMatches(unreadOnly, page)
    local matches = AwaitCallback("spark:getMatches", unreadOnly, page)
    local result = {}
    for i = 1, #matches do
        local match = matches[i]
        local entry = {}
        entry.name = match.name
        entry.number = match.phone_number
        entry.photos = json.decode(match.photos)
        entry.dob = match.dob
        entry.bio = match.bio
        entry.isMale = match.is_male
        entry.timestamp = match.latest_message_timestamp
        entry.unread = true == match.unread
        if match.latest_message then
            entry.lastMessage = match.latest_message
            entry.lastSender = match.latest_sender
        end
        result[i] = entry
    end
    return result
end

RegisterNUICallback("Tinder", function(data, cb)
    if not currentPhone then
        return
    end
    local action = data.action
    debugprint("Spark:" .. (action or ""))
    if table.contains(actions, action) then
        if not CanInteract() then
            return cb(false)
        end
    end
    if "createAccount" == action then
        return TriggerCallback("spark:createAccount", cb, data.data)
    elseif "deleteAccount" == action then
        return TriggerCallback("spark:deleteAccount", cb)
    elseif "saveProfile" == action then
        return TriggerCallback("spark:updateAccount", cb, data.data)
    elseif "isLoggedIn" == action then
        return cb(AwaitCallback("spark:isLoggedIn", data.phoneNumber) or false)
    elseif "getFeed" == action then
        local feed = AwaitCallback("spark:getFeed", data.page)
        local result = {}
        for i = 1, #feed do
            local profile = feed[i]
            local entry = {}
            entry.name = profile.name
            entry.dob = profile.dob
            entry.bio = profile.bio
            entry.photos = json.decode(profile.photos)
            entry.number = profile.phone_number
            result[i] = entry
        end
        cb(result)
    elseif "swipe" == action then
        TriggerCallback("spark:swipe", cb, data.number, data.like)
    elseif "getNewMatchesCount" == action then
        TriggerCallback("spark:getNewMatchesCount", cb)
    elseif "getMatches" == action then
        return cb(getMatches(false, data.page))
    elseif "getRecentMessages" == action then
        return cb(getMatches(true, data.page))
    elseif "sendMessage" == action then
        data = data.data
        if not (type(data.attachments) == "table" and #data.attachments ~= 0) then
            data.attachments = nil
        end
        TriggerCallback("spark:sendMessage", cb, data.recipient, data.content, data.attachments)
    elseif "getMessages" == action then
        local messages = AwaitCallback("spark:getMessages", data.number, data.lastId)
        for i = 1, #messages do
            if messages[i].attachments then
                messages[i].attachments = json.decode(messages[i].attachments)
            else
                messages[i].attachments = {}
            end
        end
        cb(messages)
    elseif "markAsRead" == action then
        TriggerCallback("spark:markAsRead", cb, data.number)
    end
end)

RegisterNetEvent("phone:spark:newMessage", function(data)
    data.attachments = data.attachments or {}
    SendNUIAction("tinder:newMessage", data)
end)
