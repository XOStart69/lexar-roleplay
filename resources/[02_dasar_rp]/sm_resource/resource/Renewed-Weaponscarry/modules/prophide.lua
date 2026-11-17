local KVP_KEY = 'sm_prophide'

local enabled = GetResourceKvpInt(KVP_KEY) == 1
local listeners = {}

local Prophide = {}

---@return boolean
function Prophide.isEnabled()
    return enabled
end

---@param cb fun(enabled: boolean)
function Prophide.onChange(cb)
    listeners[#listeners + 1] = cb
end

function Prophide.refresh()
    LocalPlayer.state:set('prophide', enabled or nil, true)

    for i = 1, #listeners do
        listeners[i](enabled)
    end
end

---@param value boolean
function Prophide.setEnabled(value)
    if value == enabled then
        return
    end

    enabled = value

    SetResourceKvpInt(KVP_KEY, value and 1 or 0)
end

return Prophide
