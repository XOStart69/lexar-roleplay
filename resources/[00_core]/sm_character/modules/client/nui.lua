local nui = {}

---@param action string
---@param data? any
function nui.send(action, data)
    SendNUIMessage({ action = action, data = data })
end

---@param state boolean
function nui.focus(state)
    SetNuiFocus(state, state)
end

return nui
