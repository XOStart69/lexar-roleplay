RegisterNUICallback("CustomApp", function(data, cb)
    local app = data.app
    local action = data.action
    cb("ok")
    if not action or not app then
        debugprint("invalid data")
        return
    end
    local appConfig = Config.CustomApps[app]
    if action == "open" then
        if appConfig and appConfig.onServerUse then
            TriggerServerEvent("lb-phone:customApp", app)
        end
        if not (appConfig and appConfig.ui) then
            if not (appConfig and appConfig.keepOpen) then
                debugprint("Closing phone due to custom app without ui")
                ToggleOpen(false)
            end
        end
        if appConfig and appConfig.onUse then
            Citizen.CreateThreadNow(function()
                appConfig.onUse()
            end)
        end
        if appConfig and appConfig.onOpen then
            Citizen.CreateThreadNow(function()
                appConfig.onOpen()
            end)
        end
    elseif action == "close" then
        if appConfig and appConfig.onClose then
            appConfig.onClose()
        end
    elseif action == "install" then
        if appConfig and appConfig.onInstall then
            appConfig.onInstall()
        end
    elseif action == "uninstall" then
        if appConfig and appConfig.onDelete then
            appConfig.onDelete()
        end
    end
end)

local callbacks = {}
local validColors = {}
validColors.blue = true
validColors.red = true
validColors.green = true
validColors.yellow = true

local function generateId()
    local id = math.random(999999999)
    while callbacks[id] do
        id = math.random(999999999)
    end
    return id
end

RegisterNUICallback("PopUp", function(id, cb)
    if not callbacks[id] then
        return
    end
    cb("ok")
    callbacks[id]()
    callbacks[id] = nil
end)

RegisterNUICallback("PopUpInputChanged", function(data, cb)
    local id = data.id
    local value = data.value
    if not callbacks[id] then
        return
    end
    cb("ok")
    callbacks[id](value)
end)

local function setPopUp(data, cb)
    assert(data.buttons and #data.buttons > 0, "You need at least one button")
    data = table.clone(data)
    for _, button in pairs(data.buttons) do
        assert(button.title, "You need a title for each button")
        assert(validColors[button.color or "blue"], "Invalid color")
        if cb == true then
            if button.cb then
                local id = generateId()
                local buttonCb = button.cb
                callbacks[id] = function()
                    buttonCb(button.callbackId)
                end
                button.cb = id
            end
        else
            if button.callbackId then
                local id = generateId()
                callbacks[id] = function()
                    cb(button.callbackId)
                end
                button.cb = id
            end
        end
    end
    local inputs = data.inputs or {}
    if data.input then
        inputs[#inputs + 1] = data.input
    end
    for i = 1, #inputs do
        local input = inputs[i]
        if input.onChange then
            local id = generateId()
            if cb == true then
                local onChange = input.onChange
                callbacks[id] = function(value)
                    onChange(value)
                end
            else
                callbacks[id] = function(value)
                    SendNUIAction("customApp:sendMessage", {
                        identifier = "any",
                        message = { type = "popUpInputChanged", value = value }
                    })
                end
            end
            input.onChange = id
        end
    end
    SendNUIAction("onComponentUse", { type = "popup", data = data })
end

RegisterNUICallback("SetPopUp", setPopUp)

exports("SetPopUp", function(data)
    setPopUp(data, true)
end)

RegisterNUICallback("ContextMenu", function(id, cb)
    if not callbacks[id] then
        return
    end
    callbacks[id]()
    callbacks[id] = nil
    cb("ok")
end)

local function setContextMenu(data, cb)
    assert(data.buttons and #data.buttons > 0, "You need at least one button")
    for _, button in pairs(data.buttons) do
        assert(button.title, "You need a title for each button")
        assert(validColors[button.color or "blue"], "Invalid colour")
        if cb == true then
            assert(button.cb, "You need a callback for each button")
        else
            assert(button.callbackId, "You need a callback for each button")
        end
        local id = generateId()
        local buttonCb = button.cb
        callbacks[id] = function()
            if cb == true then
                buttonCb()
            else
                cb(button.callbackId)
            end
        end
        button.cb = id
    end
    SendNUIAction("onComponentUse", { type = "contextmenu", data = data })
end

RegisterNUICallback("SetContextMenu", setContextMenu)

exports("SetContextMenu", function(data)
    setContextMenu(data, true)
end)

local function setCameraComponent(data, cb)
    if type(data) ~= "table" or not data then
        data = {}
    end
    local prom
    local wasOpen = phoneOpen
    local id = generateId()
    data.id = id
    if not wasOpen then
        debugprint("Opening phone due to camera component")
        ToggleOpen(true)
    end
    if not cb then
        prom = promise.new()
    end
    callbacks[id] = function(result)
        if cb then
            cb(result.url)
        else
            prom:resolve(result.url)
        end
        if not wasOpen then
            debugprint("Closing phone due to camera component")
            ToggleOpen(false)
        end
    end
    SendNUIAction("onComponentUse", { type = "camera", data = data })
    if not cb then
        return Citizen.Await(prom)
    end
end

exports("SetCameraComponent", setCameraComponent)

local function setContactModal(phoneNumber)
    assert(phoneNumber, "You need to provide a phone number")
    SendNUIAction("onComponentUse", { type = "contactmodal", data = phoneNumber })
end

RegisterNUICallback("SetContactModal", function(data, cb)
    setContactModal(data)
    cb("ok")
end)

exports("SetContactModal", setContactModal)

local componentTypes = {
    gallery = { "image" },
    gif = { "gif" },
    emoji = { "emoji" },
    camera = { "url" },
    colorpicker = { "color" },
    contactselector = { "contact" }
}

RegisterNUICallback("UsedComponent", function(data, cb)
    local id = data and data.id
    if not id or not callbacks[id] then
        return
    end
    callbacks[id](data)
    callbacks[id] = nil
    cb("ok")
end)

local function showComponent(data, cb)
    local component = data.component
    assert(component, "You need to specify a component")
    assert(componentTypes[component], "Invalid component")
    local id = generateId()
    callbacks[id] = function(result)
        local values = {}
        for _, field in pairs(componentTypes[component]) do
            values[#values + 1] = result[field]
        end
        cb(table.unpack(values))
    end
    data.id = id
    SendNUIAction("onComponentUse", { type = component, data = data })
end

RegisterNUICallback("ShowComponent", showComponent)

exports("ShowComponent", showComponent)

RegisterNUICallback("CreateCall", function(data, cb)
    CreateCall(data)
    cb("ok")
end)

RegisterNUICallback("GetSettings", function(data, cb)
    cb(settings)
end)

RegisterNUICallback("GetLocale", function(data, cb)
    cb(L(data.path, data.format))
end)

RegisterNUICallback("SendNotification", function(data, cb)
    if data and data.customData and data.customData.buttons then
        data.customData.buttons = nil
        debugprint("You cannot create notifications with buttons from the NUI.")
    end
    TriggerEvent("phone:sendNotification", data)
    cb(true)
end)
