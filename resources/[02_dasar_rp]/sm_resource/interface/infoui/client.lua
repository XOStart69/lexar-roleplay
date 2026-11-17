if not interface.init() then
    return
end

local cached = {}
local handle = false
local exportHandler = require 'export_wrapper'

local information = setmetatable({}, {
    __newindex = function (self, key, fn)
        rawset(self, key, fn)
        exportHandler('rhd_infoui', key, fn)
    end
})

---@class InformationProps
---@field id string
---@field title string
---@field icon string
---@field description string|table<string, any>
---@field defaultCollapsed? boolean

---@param data InformationProps|InformationProps[]
function information.show(data)
    cached[data.id] = data
    interface.send({
        action = 'updateInformation',
        data = cached
    })
end

function information.remove(id)
    if not cached[id] then
        return
    end

    cached[id] = nil

    interface.send({
        action = 'updateInformation',
        data = cached
    })
end

function information.removeAll()
    cached = {}
    
    interface.send({
        action = 'updateInformation',
        data = cached
    })
end

local function setFocus(state)
    handle = state
    interface.focus(handle, handle, false)
end

interface.callback('disableFocus', function (data, cb)
    setFocus(false)
    cb('ok')
end)

RegisterCommand('handleinfo', function ()
    setFocus(not handle)
end, false)

CreateThread(function()
    TriggerEvent('chat:addSuggestion', '/handleinfo', 'Handle information UI')
end)

_ENV.infoUI = information