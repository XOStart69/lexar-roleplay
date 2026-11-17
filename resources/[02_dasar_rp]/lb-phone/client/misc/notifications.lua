local cachedNotifications = {}

local function getNotifications()
    local notifications = AwaitCallback("getNotifications")
    for i = 1, #notifications do
        local notif = notifications[i]
        if notif.content == nil then
            notif.content = notif.title
            notif.title = nil
        end
        if notif.custom_data then
            local custom = json.decode(notif.custom_data)
            if custom.buttons then
                notif.actions = custom.buttons
                cachedNotifications[notif.id] = notif
            end
            notif.custom_data = nil
        end
    end
    return notifications
end

local function deleteNotification(id)
    if not id then
        return true
    end
    if cachedNotifications[id] then
        cachedNotifications[id] = nil
    end
    if type(id) == "string" then
        if id:find("client%-notification%-") then
            return true
        end
    end
    if type(id) ~= "number" then
        return true
    end
    return AwaitCallback("deleteNotification", id)
end

local function clearNotifications(app)
    local success = AwaitCallback("clearNotifications", app)
    if not success then
        return false
    end
    for i = 1, #cachedNotifications do
        if cachedNotifications[i].app == app then
            cachedNotifications[i] = nil
        end
    end
    return success
end

local function handleButton(id, buttonId)
    local actions = cachedNotifications[id]
    if actions then
        actions = actions.actions
    end
    if not actions then
        debugprint("No buttons found for notification", id, cachedNotifications)
        return false
    end
    local button = actions[buttonId]
    if not button then
        debugprint("Button not found for notification", id, buttonId)
        return false
    end
    if button.event then
        if button.server then
            TriggerServerEvent(button.event, button.data)
        else
            TriggerEvent(button.event, button.data)
        end
    end
    if button.remove then
        SendNUIAction("removeNotification", id)
        cachedNotifications[id] = nil
    end
    if type(id) == "number" then
        AwaitCallback("deleteNotification", id)
    end
    return true
end

RegisterNUICallback("Notifications", function(data, cb)
    local action = data.action
    debugprint("Notifications:" .. (action or ""))
    if action == "getNotifications" then
        return cb(getNotifications())
    elseif action == "deleteNotification" then
        if data.id ~= nil then
            return cb(deleteNotification(data.id))
        end
    elseif action == "clearNotifications" then
        return cb(clearNotifications(data.app))
    elseif action == "button" then
        return cb(handleButton(data.id, (data.buttonId or 0) + 1))
    end
end)

RegisterNetEvent("phone:sendNotification", function(notification)
    if not HasPhoneItem(currentPhone) or phoneDisabled then
        debugprint("no phone, not showing notification")
        return
    end
    if not notification.id then
        notification.id = "client-notification-" .. math.random()
    end
    if notification.content == nil then
        notification.content = notification.title
        notification.title = nil
    end
    if notification.customData then
        if notification.customData.buttons and notification.id then
            notification.actions = notification.customData.buttons
            cachedNotifications[notification.id] = notification
        end
        notification.customData = nil
    end
    SendNUIAction("newNotification", notification)
    if not phoneOpen then
        if Config.NotificationsUpdateZIndex and SetNuiZindex then
            SetNuiZindex(99)
        end
    end
end)

exports("SendNotification", function(notification)
    notification.id = "client-notification-" .. math.random()
    TriggerEvent("phone:sendNotification", notification)
end)

exports("DeleteNotification", deleteNotification)
