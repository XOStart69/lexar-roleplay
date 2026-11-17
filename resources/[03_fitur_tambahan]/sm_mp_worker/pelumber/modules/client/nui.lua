local State = require 'pelumber.modules.client.state'

local Nui = {}

---@type promise?
local pending = nil

---@param action string
---@param payload? any
function Nui.send(action, payload)
    while not State.nuiLoaded do Wait(0) end
    interface.send({ action = action, payload = payload })
end

---@param cursor boolean
---@param cursor2 boolean
---@param keepInput? boolean
function Nui.focus(cursor, cursor2, keepInput)
    interface.focus(cursor, cursor2, keepInput)
end

---@param name string
---@param cb fun(data: any, cb: fun(result?: any))
function Nui.callback(name, cb)
    interface.callback(name, cb)
end

---@param action string
---@param payload any
---@return boolean success
function Nui.runNuiMinigame(action, payload)
    if pending then return false end

    pending = promise.new()
    Nui.send(action, payload)
    Nui.focus(true, true)

    local result = Citizen.Await(pending)
    pending = nil
    Nui.focus(false, false)

    return type(result) == 'table' and result.success == true
end

function Nui.cancel()
    if pending then
        pending:resolve({ success = false, cancelled = true })
    end
end

function Nui.pingUntilReady()
    CreateThread(function()
        while not State.nuiLoaded do
            if NetworkIsSessionStarted() then
                interface.send({ action = 'CHECK_NUI' })
            end
            Wait(2000)
        end
    end)
end

interface.callback('minigameClose', function(data, cb)
    cb('ok')
    if pending then pending:resolve(data or {}) end
end)

interface.callback('valveGameResult', function(data, cb)
    cb('ok')
    if pending then pending:resolve(data or {}) end
end)

return Nui
