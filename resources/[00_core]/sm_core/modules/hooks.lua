-- Modified from original source https://github.com/overextended/ox_inventory/blob/main/modules/hooks/server.lua
-- Copyright (C) 2021  Linden <https://github.com/thelindat>, Dunak <https://github.com/dunak-debug>, Luke <https://github.com/LukeWasTakenn>

assert(lib.checkDependency('ox_lib', '3.8.0', true))

local eventHooks = {}
local isServer = IsDuplicityVersion()

local getTime = isServer and os.microtime or function()
    return GetGameTimer() * 1000
end

local function triggerEventHooks(event, ...)
    local hooks = eventHooks[event]
    if not hooks then return true end

    for i = 1, #hooks do
        local hook = hooks[i]

        local start = getTime()
        local success, response = pcall(hook, ...)
        local executionTime = getTime() - start

        if executionTime >= 100000 then
            local side = isServer and "SERVER" or "CLIENT"
            warn(('[%s] Execution of event hook "%s:%s:%s" took %.2fms.'):format(side, hook.resource, event, i, executionTime / 1e3))
        end

        if not success then
            local side = isServer and "SERVER" or "CLIENT"
            warn(('[%s] Error in event hook "%s:%s:%s": %s'):format(side, hook.resource, event, i, response))
        end

        if response == false then
            return false
        end
    end

    return true
end

local hookId = 0

---Registers a callback function to be triggered by a resource. Returning false from the callback function cancels the event
---@param event string
---@param cb any
---@return integer hookId
local function registerHook(event, cb)
    if not eventHooks[event] then
        eventHooks[event] = {}
    end

    local mt = getmetatable(cb)
    mt.__index = nil
    mt.__newindex = nil
    cb.resource = GetInvokingResource()
    hookId += 1
    cb.hookId = hookId

    eventHooks[event][#eventHooks[event] + 1] = cb
    return hookId
end

local function removeResourceHooks(resource, id)
    for _, hooks in pairs(eventHooks) do
        for i = #hooks, 1, -1 do
            local hook = hooks[i]

            if hook.resource == resource and (not id or hook.hookId == id) then
                table.remove(hooks, i)
            end
        end
    end
end

AddEventHandler('onResourceStop', removeResourceHooks)

---@param id number hookId
local function removeHooks(id)
    local resource = GetInvokingResource() or GetCurrentResourceName()
    removeResourceHooks(resource, id)
end

exports('registerHook', registerHook)
exports('removeHooks', removeHooks)

return triggerEventHooks
