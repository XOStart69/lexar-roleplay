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
local frameReady = {}

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
---@return boolean
local function waitFrameReady(name)
    if frameReady[name] then return true end

    local timeout = 50
    while not frameReady[name] and timeout > 0 do
        Wait(100)
        timeout = timeout - 1
    end

    if not frameReady[name] then
        lib.print.error(('Frame "%s" not ready after timeout'):format(name))
        return false
    end

    return true
end

---@param name string
---@param url string
---@param visible? boolean defaults true; pass false to register without mounting
local function createFrame(name, url, visible)
    if visible == nil then visible = true end
    SendNUIMessage({action = 'create_frame', name = name, url = url, visible = visible})
    registeredFrames[name] = true
end

-- @param startVisible? boolean defaults true; pass false to register the frame
-- without mounting it (no GPU surface) until the module calls show().
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
            if LoadResourceFile(cache.resource, paths[i]) then
                return paths[i]
            end
        end
    end

    local htmlPath = findHtml(moduleName)

    if not htmlPath then
        lib.print.error(('Frame "%s" tidak punya index.html (dicari di dist/, web/build/, build/)'):format(moduleName))
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
---@return boolean success true if the frame was ready and the message was sent
local function send(msg)
    local moduleName = getCallerModule()
    if not moduleName or not registeredFrames[moduleName] then return false end
    if not waitFrameReady(moduleName) then return false end

    SendNUIMessage({target = moduleName, data = msg})
    return true
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
---@return boolean success true if the frame was ready and focus was applied
local function focus(cursor, cursor2, keepInput)
    local moduleName = getCallerModule()
    if not moduleName or not registeredFrames[moduleName] then return false end
    if not waitFrameReady(moduleName) then return false end

    setFocus(moduleName, cursor, cursor2, keepInput)
    return true
end

---@param name string
local function destroyFrame(name)
    if registeredFrames[name] then
        SendNUIMessage({action = 'destroy_frame', name = name})
        registeredFrames[name] = nil
        frameReady[name] = nil
    end
end

-- Unmount the calling module's iframe from the DOM, releasing its GPU surface.
-- Use this when an on-demand UI (menu/tablet/etc.) is closed so it stops
-- consuming VRAM while not visible. The frame stays registered and can be
-- brought back instantly with show().
local function hide()
    local moduleName = getCallerModule()
    if not moduleName or not registeredFrames[moduleName] then return end
    SendNUIMessage({action = 'hide_frame', name = moduleName})
    -- iframe is destroyed on hide, so it must re-announce readiness on show.
    frameReady[moduleName] = nil
end

-- Re-mount the calling module's iframe. Pair with hide(). Waits for the
-- freshly created frame to report ready before returning so send()/focus()
-- right after show() still land.
---@return boolean
local function show()
    local moduleName = getCallerModule()
    if not moduleName or not registeredFrames[moduleName] then return false end
    SendNUIMessage({action = 'show_frame', name = moduleName})
    return waitFrameReady(moduleName)
end

local captures = {}
local captureSeq = 0

---@param url string
---@param options? { encoding?: 'jpg'|'png'|'webp', quality?: number, field?: string }
---@return table?
local function capture(url, options)
    options = options or {}
    captureSeq += 1

    local id = captureSeq
    local p = promise.new()
    captures[id] = p

    SendNUIMessage({
        action = 'capture',
        id = id,
        url = url,
        field = options.field or 'file',
        encoding = options.encoding or 'jpg',
        quality = options.quality or 0.85
    })

    SetTimeout(20000, function()
        if captures[id] then
            captures[id] = nil
            p:resolve(nil)
        end
    end)

    return Citizen.Await(p)
end

---@param url string
---@param options? { encoding?: 'jpg'|'png'|'webp', quality?: number, field?: string }
---@param cb? fun(resp: table?)
---@return table?
exports('capture', function(url, options, cb)
    if type(url) ~= 'string' then return end

    if cb then
        CreateThread(function()
            cb(capture(url, options))
        end)
        return
    end

    return capture(url, options)
end)

RegisterNUICallback('capture_result', function(data, cb)
    cb('')

    local p = captures[data.id]
    if not p then return end

    captures[data.id] = nil

    local ok, resp = pcall(json.decode, data.body or '')
    p:resolve(ok and type(resp) == 'table' and resp or nil)
end)

RegisterNUICallback('nui_ready', function(_, cb)
    nuiReady = true
    for i = 1, #pendingFrames do
        local frame = pendingFrames[i]
        createFrame(frame.name, frame.url, frame.visible)
    end
    pendingFrames = {}
    cb('')
end)

RegisterNUICallback('frame_ready', function(data, cb)
    local name = data.name
    if name then
        frameReady[name] = true
    end
    cb('')
end)

RegisterNUICallback('frame_message', function(data, cb)
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
    capture = capture,
    ready = function()
        return nuiReady
    end
}