local nui = {
    ready = false,
}

---@param action string
---@param data? any
function nui.send(action, data)
    if not nui.ready then return end

    interface.send({ action = action, data = data })
end

---@param level 'info'|'success'|'warn'|'error'
---@param text string
function nui.log(level, text)
    nui.send('log', { level = level, text = text })
end

return nui
