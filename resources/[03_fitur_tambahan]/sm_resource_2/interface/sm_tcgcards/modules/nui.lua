local Nui = {}

interface.init(true)

---@type string?
local view
---@type fun()?
local onClose

---@param name string
---@param data table
---@param closed? fun()
---@return boolean
function Nui.open(name, data, closed)
    if view then return false end

    view = name
    onClose = closed
    data.view = name
    interface.focus(true, true)
    interface.send({ action = 'open', data = data })

    return true
end

---@param action string
---@param data any
function Nui.send(action, data)
    interface.send({ action = action, data = data })
end

---@param keepInput boolean
function Nui.focus(keepInput)
    interface.focus(true, true, keepInput)
end

function Nui.unfocus()
    interface.focus(false, false)
end

---@return string?
function Nui.view()
    return view
end

---@param silent? boolean
function Nui.release(silent)
    if not view then return end

    local closed = onClose

    view = nil
    onClose = nil
    interface.focus(false, false)

    if closed and not silent then closed() end
end

---@param silent? boolean
function Nui.close(silent)
    if not view then return end

    interface.send({ action = 'close' })
    Nui.release(silent)
end

---@param name string
---@param handler fun(data: any): table?
function Nui.on(name, handler)
    interface.callback(name, function(data, cb)
        local ok, result = pcall(handler, type(data) == 'table' and data or {})

        if not ok then
            lib.print.error(('nui callback "%s" failed: %s'):format(name, result))
            return cb({ ok = false })
        end

        cb(result or { ok = true })
    end)
end

Nui.on('close', function()
    Nui.release()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() and view then SetNuiFocus(false, false) end
end)

return Nui
