local originalSendNUIMessage = SendNUIMessage
function SendNUIMessage(data)
    if type(data) == 'table' then
        data._resource = cache.resource
    end
    originalSendNUIMessage(data)
end

local registeredFrames = {}
local nuiReady = false
local pendingFrames = {}

---@return string|nil
local function getCallerModule()
    for level = 2, 10 do
        local info = debug.getinfo(level, 'S')
        if not info then break end
        if info.source then
            local module = info.source:match('interface/([^/]+)/')
            if module then
                return module
            end
        end
    end
    return nil
end

---@param name string
---@param url string
---@param visible? boolean defaults true; pass false to register without mounting
local function createFrame(name, url, visible)
    if visible == nil then visible = true end
    SendNUIMessage({action = 'create_frame', name = name, url = url, visible = visible})
    registeredFrames[name] = true
end

---@return boolean
local function init(startVisible)
    if startVisible == nil then startVisible = true end
    local moduleName = getCallerModule()
    if not moduleName then
        lib.print.error('Tidak dapat mendeteksi module yang memanggil')
        return false
    end

    if registeredFrames[moduleName] then
        lib.print.warn(('Frame "%s" sudah terdaftar'):format(moduleName))
        return false
    end

    local function findHtml(module)
        local paths = {
            ('interface/%s/dist/index.html'):format(module),
            ('interface/%s/web/build/index.html'):format(module),
            ('interface/%s/build/index.html'):format(module),
        }

        for i = 1, #paths do
            local path = paths[i]
            if LoadResourceFile(cache.resource, path) ~= nil then
                return path
            end
        end
    end

    local htmlPath = findHtml(moduleName)

    if not htmlPath then
        return false
    end

    local url = ('https://cfx-nui-%s/%s'):format(cache.resource, htmlPath)

    if nuiReady then
        createFrame(moduleName, url, startVisible)
    else
        pendingFrames[#pendingFrames + 1] = {
            name = moduleName,
            url = url,
            visible = startVisible
        }
    end

    return true
end

---@param msg table
local function send(msg)
    local moduleName = getCallerModule()
    if moduleName and registeredFrames[moduleName] then
        SendNUIMessage({target = moduleName, data = msg})
    end
end

---@param name string
---@param cb fun(data: any, cb: fun(...))
local function callback(name, cb)
    local moduleName = getCallerModule()
    if not moduleName then
        lib.print.error('callback() harus dipanggil dari module interface')
        return
    end

    local fullName = ('%s:%s'):format(moduleName, name)

    return RegisterRawNuiCallback(fullName, function(req, nuiCallback)
        local origin = req.headers and req.headers['Origin']
        local validOrigin = ('https://cfx-nui-%s'):format(cache.resource)

        if origin and origin ~= '' and origin ~= validOrigin then
            lib.print.error(('[Interface] Callback %s rejected - invalid origin'):format(fullName))
            return nuiCallback({ status = 403, body = json.encode({ error = 'Forbidden' }) })
        end

        local data = json.decode(req.body)

        cb(data, function(result)
            nuiCallback({ status = 200, body = json.encode(result or {}) })
        end)
    end)
end

---@param name string
---@param cursor boolean
---@param cursor2 boolean
---@param keepInput? boolean
local function setFocus(name, cursor, cursor2, keepInput)
    SendNUIMessage({action = 'focus_frame', name = name})
    SetNuiFocus(cursor and cursor or false, cursor2 and cursor2 or false)
    SetNuiFocusKeepInput(keepInput or false)
end

---@param cursor boolean
---@param cursor2 boolean
---@param keepInput? boolean
local function focus(cursor, cursor2, keepInput)
    local moduleName = getCallerModule()
    if moduleName and registeredFrames[moduleName] then
        setFocus(moduleName, cursor, cursor2, keepInput)
    end
end

---@param name string
local function destroyFrame(name)
    if registeredFrames[name] then
        SendNUIMessage({action = 'destroy_frame', name = name})
        registeredFrames[name] = nil
    end
end

local function hide()
    local moduleName = getCallerModule()
    if moduleName and registeredFrames[moduleName] then
        SendNUIMessage({action = 'hide_frame', name = moduleName})
    end
end

local function show()
    local moduleName = getCallerModule()
    if moduleName and registeredFrames[moduleName] then
        SendNUIMessage({action = 'show_frame', name = moduleName})
    end
end

RegisterNUICallback('nui_ready', function(_, cb)
    nuiReady = true
    for i = 1, #pendingFrames do
        local frame = pendingFrames[i]
        createFrame(frame.name, frame.url, frame.visible)
    end
    pendingFrames = {}
    cb('')
end)

RegisterNUICallback('frame_message', function (data, cb)
    local name, msg in data
    lib.print.info(('[%s] %s jcnk'):format(name, msg))
    cb('')
end)

_ENV.interface = {
    init = init,
    send = send,
    callback = callback,
    focus = focus,
    setFocus = setFocus,
    show = show,
    hide = hide,
    destroyFrame = destroyFrame,
    ready = function ()
        return nuiReady
    end
}
