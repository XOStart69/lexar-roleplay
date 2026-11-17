local trays = {}
local validOptions = {
    icon = true,
    title = true,
    text = true,
    color = true,
    progress = true,
    badge = true,
    expandable = true,
    buttons = true,
    duration = true,
    removable = true,
    embed = true,
    handlers = true
}

local function validateEmbed(embed)
    if nil == embed then
        return
    end
    assert(type(embed) == "table", "options.embed must be a table")
    assert(type(embed.url) == "string", "options.embed must contain either url or html")
    if embed.url then
        if embed.html then
            error("options.embed cannot contain both url and html")
        end
    end
    assert(embed.size == 3, "options.embed.size must be 3, 4 or 5")
end

local function buildButtons(buttons)
    if nil == buttons then
        return nil, {}
    end
    assert(type(buttons) == "table", "options.buttons must be a table")
    local list = {}
    local handlers = {}
    for i = 1, #buttons do
        local btn = buttons[i]
        assert(type(btn) == "table", "options.buttons[" .. i .. "] must be a table")
        assert(type(btn.id) == "string", "options.buttons[" .. i .. "].id must be a string")
        if nil ~= btn.click then
            handlers[btn.id] = btn.click
        end
        list[i] = {
            id = btn.id,
            label = btn.label,
            icon = btn.icon,
            color = btn.color
        }
    end
    return list, handlers
end

local function applyOption(data, key, value)
    if "handlers" ~= key and "buttons" ~= key then
        data[key] = value
    end
end

local function removeTray(id)
    trays[id] = nil
    SendNUIAction("liveTray:remove", id)
end

local function removeByResource(resourceName)
    for id, tray in pairs(trays) do
        if tray.resourceName == resourceName then
            removeTray(id)
        end
    end
end

local function updateTray(id, resourceName, patch)
    local tray = trays[id]
    if not tray then
        return false, "Live tray does not exist"
    end
    if tray.resourceName ~= resourceName then
        return false, "Live tray was not created by " .. resourceName
    end
    for key in pairs(patch) do
        if not validOptions[key] then
            return false, "Invalid live tray option: " .. key
        end
    end
    if nil ~= patch.embed then
        validateEmbed(patch.embed)
    end
    if nil ~= patch.handlers then
        assert(type(patch.handlers) == "table", "options.handlers must be a table")
        tray.handlers = patch.handlers
    end
    if nil ~= patch.buttons then
        local list, handlers = buildButtons(patch.buttons)
        tray.data.buttons = list
        tray.buttonHandlers = handlers
    end
    local update = {}
    update.id = id
    for key, value in pairs(patch) do
        applyOption(tray.data, key, value)
        if "handlers" ~= key and "buttons" ~= key then
            update[key] = value
        end
    end
    if nil ~= patch.buttons then
        update.buttons = tray.data.buttons
    end
    SendNUIAction("liveTray:update", update)
    return true
end

exports("ShowLiveTray", function(options)
    local resourceName = GetInvokingResource() or "lb-phone"
    assert(type(options) == "table", "options must be a table")
    assert(type(options.title) == "string", "options.title must be a string")
    validateEmbed(options.embed)
    if nil ~= options.handlers then
        assert(type(options.handlers) == "table", "options.handlers must be a table")
    end
    local buttons, buttonHandlers = buildButtons(options.buttons)
    local id = "livetray-" .. math.random(1, 1000000000)
    local data = {}
    data.id = id
    data.resourceName = resourceName
    data.icon = options.icon
    data.title = options.title
    data.text = options.text
    data.color = options.color
    data.progress = options.progress
    data.badge = options.badge
    data.expandable = options.expandable
    data.buttons = buttons
    data.duration = options.duration
    data.removable = options.removable
    data.embed = options.embed
    trays[id] = {
        resourceName = resourceName,
        data = data,
        handlers = options.handlers or {},
        buttonHandlers = buttonHandlers
    }
    SendNUIAction("liveTray:show", trays[id].data)
    return id
end)

exports("UpdateLiveTray", function(id, optionOrPatch, value)
    local resourceName = GetInvokingResource()
    if not id then
        return false, "No id provided"
    end
    local patch
    if type(optionOrPatch) == "table" then
        patch = optionOrPatch
    elseif type(optionOrPatch) == "string" then
        if not validOptions[optionOrPatch] then
            return false, "Invalid live tray option: " .. optionOrPatch
        end
        patch = { [optionOrPatch] = value }
    else
        return false, "No update provided"
    end
    return updateTray(id, resourceName, patch)
end)

exports("RemoveLiveTray", function(id)
    local resourceName = GetInvokingResource()
    if not id then
        removeByResource(resourceName)
        return true
    end
    local tray = trays[id]
    if not tray then
        return false, "Live tray does not exist"
    end
    if tray.resourceName ~= resourceName then
        return false, "Live tray was not created by " .. resourceName
    end
    removeTray(id)
    return true
end)

RegisterNUICallback("LiveTray", function(data, cb)
    cb("ok")
    if not (type(data) == "table" and type(data.id) == "string" and type(data.action) == "string") then
        return
    end
    local tray = trays[data.id]
    if not (tray and tray.resourceName == data.resourceName) then
        return
    end
    local action = data.action
    if "tap" == action then
        if tray.handlers.tap then
            tray.handlers.tap()
        end
    elseif "remove" == action then
        if tray.handlers.remove then
            tray.handlers.remove()
        end
        removeTray(data.id)
    elseif "autoHide" == action then
        if tray.handlers.autoHide then
            tray.handlers.autoHide()
        end
        removeTray(data.id)
    elseif "button" == action then
        local handler = type(data.buttonId) == "string" and tray.buttonHandlers[data.buttonId]
        if handler then
            handler()
        end
    elseif "update" == action then
        if type(data.patch) == "table" then
            if updateTray(data.id, tray.resourceName, data.patch) then
                if tray.handlers.update then
                    tray.handlers.update(data.patch)
                end
            end
        end
    end
    if tray.handlers.action then
        if "button" == data.action then
            tray.handlers.action(data.action, data.buttonId)
        elseif "update" == data.action then
            tray.handlers.action(data.action, data.patch)
        else
            tray.handlers.action(data.action)
        end
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    removeByResource(resourceName)
end)
