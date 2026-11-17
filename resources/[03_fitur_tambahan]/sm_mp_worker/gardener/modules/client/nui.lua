local State = require 'gardener.modules.client.state'

local Nui = {}

---@param action string
---@param payload any
function Nui.send(action, payload)
    State.nuiMessage(action, payload)
end

---@param cursor boolean
---@param keepInput? boolean
function Nui.focus(cursor, keepInput)
    interface.focus(cursor, cursor, keepInput)
end

function Nui.pingUntilReady()
    CreateThread(function()
        while not State.nuiLoaded do
            interface.send({ action = 'CHECK_NUI' })
            Wait(2000)
        end
    end)
end

return Nui
