local open = {}

local Nui = {}

local function refresh()
    local focused = next(open) ~= nil

    SetNuiFocus(focused, focused)
end

---@param name string
---@param action string
---@param data any
function Nui.open(name, action, data)
    open[name] = true
    SendNUIMessage({ action = action, data = data })
    refresh()
end

---@param name string
---@param action string
function Nui.close(name, action)
    if not open[name] then return end

    open[name] = nil
    SendNUIMessage({ action = action })
    refresh()
end

---@param name string
---@return boolean
function Nui.isOpen(name)
    return open[name] == true
end

---@param name string
---@param handler fun(payload: table): any
function Nui.callback(name, handler)
    RegisterNUICallback(name, function(payload, cb)
        local ok, result = pcall(handler, payload or {})

        if not ok then
            lib.print.error(('nui callback %s failed: %s'):format(name, result))
            cb({})

            return
        end

        cb(result == nil and {} or result)
    end)
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    SetNuiFocus(false, false)
end)

return Nui
