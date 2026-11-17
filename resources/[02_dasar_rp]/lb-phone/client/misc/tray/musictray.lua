local trays = {}
local validOptions = {
    title = true,
    artist = true,
    album = true,
    cover = true,
    duration = true,
    position = true,
    playing = true,
    color = true,
    permissions = true,
    handlers = true
}

local function validatePermissions(permissions)
    if nil == permissions then
        return
    end
    assert(type(permissions) == "table", "options.permissions must be a table")
    assert(permissions.seek == nil, "options.permissions.seek must be a boolean")
    assert(permissions.next == nil, "options.permissions.next must be a boolean")
    assert(permissions.previous == nil, "options.permissions.previous must be a boolean")
end

local function applyPermissions(data, permissions)
    data.canSeek = permissions and permissions.seek
    data.canSkipNext = permissions and permissions.next
    data.canSkipPrev = permissions and permissions.previous
end

local function removeTray(id)
    trays[id] = nil
    SendNUIAction("musicTray:remove", id)
end

local function removeByResource(resourceName)
    for id, tray in pairs(trays) do
        if tray.resourceName == resourceName then
            removeTray(id)
        end
    end
end

exports("ShowMusicTray", function(options)
    local resourceName = GetInvokingResource() or "lb-phone"
    assert(type(options) == "table", "options must be a table")
    assert(type(options.title) == "string", "options.title must be a string")
    if nil ~= options.id then
        assert(type(options.id) == "string", "options.id must be a string")
    end
    validatePermissions(options.permissions)
    if nil ~= options.handlers then
        assert(type(options.handlers) == "table", "options.handlers must be a table")
    end
    local id = options.id
    if not id then
        id = "music-" .. math.random(1, 1000000000)
    end
    if trays[id] then
        return false, "Music tray already exists"
    end
    local data = {}
    data.id = id
    data.resourceName = resourceName
    data.title = options.title
    data.artist = options.artist
    data.album = options.album
    data.cover = options.cover
    data.duration = options.duration
    data.position = options.position
    data.playing = options.playing
    data.color = options.color
    applyPermissions(data, options.permissions)
    trays[id] = {
        resourceName = resourceName,
        data = data,
        handlers = options.handlers or {},
        permissions = options.permissions or {}
    }
    SendNUIAction("musicTray:show", data)
    return id
end)

exports("UpdateMusicTray", function(id, optionOrPatch, value)
    local resourceName = GetInvokingResource()
    if not id then
        return false, "No id provided"
    end
    local tray = trays[id]
    if not tray then
        return false, "Music tray does not exist"
    end
    if tray.resourceName ~= resourceName then
        return false, "Music tray was not created by " .. resourceName
    end
    local patch
    if type(optionOrPatch) == "table" then
        patch = optionOrPatch
    elseif type(optionOrPatch) == "string" then
        if not validOptions[optionOrPatch] then
            return false, "Invalid music tray option: " .. optionOrPatch
        end
        patch = { [optionOrPatch] = value }
    else
        return false, "No update provided"
    end
    for key in pairs(patch) do
        if not validOptions[key] then
            return false, "Invalid music tray option: " .. key
        end
    end
    if nil ~= patch.permissions then
        validatePermissions(patch.permissions)
        tray.permissions = patch.permissions
        applyPermissions(tray.data, patch.permissions)
    end
    if nil ~= patch.handlers then
        assert(type(patch.handlers) == "table", "options.handlers must be a table")
        tray.handlers = patch.handlers
    end
    local update = {}
    update.id = id
    for key, val in pairs(patch) do
        if "permissions" ~= key and "handlers" ~= key then
            tray.data[key] = val
            update[key] = val
        end
    end
    if nil ~= patch.permissions then
        update.canSeek = tray.data.canSeek
        update.canSkipNext = tray.data.canSkipNext
        update.canSkipPrev = tray.data.canSkipPrev
    end
    SendNUIAction("musicTray:update", update)
    return true
end)

exports("RemoveMusicTray", function(id)
    local resourceName = GetInvokingResource()
    if not id then
        removeByResource(resourceName)
        return true
    end
    local tray = trays[id]
    if not tray then
        return false, "Music tray does not exist"
    end
    if tray.resourceName ~= resourceName then
        return false, "Music tray was not created by " .. resourceName
    end
    removeTray(id)
    return true
end)

RegisterNUICallback("MusicTray", function(data, cb)
    cb("ok")
    if not (type(data) == "table" and type(data.id) == "string" and type(data.action) == "string") then
        return
    end
    local tray = trays[data.id]
    if not (tray and tray.resourceName == data.resourceName) then
        return
    end
    local action = data.action
    if "play" == action then
        if tray.handlers.play then
            tray.handlers.play()
        end
    elseif "pause" == action then
        if tray.handlers.pause then
            tray.handlers.pause()
        end
    elseif "next" == action then
        if tray.handlers.next then
            tray.handlers.next()
        end
    elseif "previous" == action then
        if tray.handlers.previous then
            tray.handlers.previous()
        end
    elseif "seek" == action then
        if tray.handlers.seek then
            tray.handlers.seek(data.position)
        end
    end
    if tray.handlers.action then
        if "seek" == data.action then
            tray.handlers.action(data.action, data.position)
        else
            tray.handlers.action(data.action)
        end
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    removeByResource(resourceName)
end)
