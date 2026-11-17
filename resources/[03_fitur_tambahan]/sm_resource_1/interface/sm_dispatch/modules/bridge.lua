local Bridge = {
    readyListeners = {},
}

---@param listener function
function Bridge.onReady(listener)
    local listeners = Bridge.readyListeners
    listeners[#listeners + 1] = listener
end

return Bridge
