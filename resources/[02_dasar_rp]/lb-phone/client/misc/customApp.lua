function FormatCustomAppDataForUI(data)
    return {
        identifier = data.identifier,
        resourceName = data.resourceName,
        custom = true,
        name = data.name,
        icon = data.icon,
        description = data.description,
        images = data.images,
        developer = data.developer,
        size = data.size or 42000,
        price = data.price,
        game = data.game,
        landscape = data.landscape or false,
        removable = not data.defaultApp,
        disableInAppNotifications = data.disableInAppNotifications,
        ui = data.ui,
        fixBlur = data.fixBlur,
        access = HasAccessToApp(data.identifier)
    }
end

exports("SendCustomAppMessage", function(identifier, message)
    local resource = GetInvokingResource()
    if not identifier then
        infoprint("error", "SendCustomAppMessage: No identifier provided by resource " .. resource)
        return false, "No identifier provided"
    end
    if not Config.CustomApps[identifier] then
        infoprint("error", "SendCustomAppMessage: App " .. identifier .. " does not exist. Triggered by: " .. resource)
        return false, "App does not exist"
    end
    if Config.CustomApps[identifier].resourceName ~= resource then
        infoprint("error", "SendCustomAppMessage: App " .. identifier .. " was not created by " .. resource)
        return false, "App was not created by " .. resource
    end
    SendNUIAction("customApp:sendMessage", { identifier = identifier, message = message })
    return true
end)

exports("AddCustomApp", function(data)
    local resource = GetInvokingResource()
    if not data or not data.identifier then
        return false, "No identifier provided"
    end
    if not data.name then
        return false, "No name provided"
    end
    if not data.description then
        return false, "No description provided"
    end
    if Config.CustomApps[data.identifier] then
        return false, "App already exists"
    end
    Config.CustomApps[data.identifier] = {
        identifier = data.identifier,
        resourceName = resource,
        custom = true,
        name = data.name,
        icon = data.icon,
        description = data.description,
        images = data.images,
        developer = data.developer,
        size = data.size or 42000,
        price = data.price,
        game = data.game,
        landscape = data.landscape or false,
        removable = not data.defaultApp,
        defaultApp = data.defaultApp,
        disableInAppNotifications = data.disableInAppNotifications,
        ui = data.ui,
        fixBlur = data.fixBlur,
        onOpen = data.onOpen,
        onClose = data.onClose,
        onUse = data.onUse,
        onDelete = data.onDelete,
        onInstall = data.onInstall
    }
    debugprint("adding custom app", data.identifier)
    SendNUIAction("addCustomApp", FormatCustomAppDataForUI(Config.CustomApps[data.identifier]))
    return true
end)

exports("RemoveCustomApp", function(identifier)
    local resource = GetInvokingResource()
    if not identifier then
        return false, "No identifier provided"
    end
    if not Config.CustomApps[identifier] then
        return false, "App does not exist"
    end
    if Config.CustomApps[identifier].resourceName ~= resource then
        return false, "App was not created by " .. resource
    end
    Config.CustomApps[identifier] = nil
    SendNUIAction("removeCustomApp", identifier)
    return true
end)

AddEventHandler("onResourceStop", function(resource)
    for identifier, app in pairs(Config.CustomApps) do
        if app.resourceName == resource then
            Config.CustomApps[identifier] = nil
            SendNUIAction("removeCustomApp", identifier)
            debugprint("Removed app " .. identifier .. " due to resource stopping")
        end
    end
end)
