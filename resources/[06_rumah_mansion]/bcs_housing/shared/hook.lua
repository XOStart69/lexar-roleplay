local hooks = {}

function TriggerEventHooks(eventName, data)
    for i = 1, #hooks do
        if hooks[i].event == eventName then
            local _, result, extra = pcall(hooks[i].handler, data)
            return result, extra
        end
    end
    return true
end

function RegisterHook(eventName, handler)
    local hookId = #hooks + 1
    table.insert(hooks, { event = eventName, resource = GetInvokingResource(), handler = handler, id = hookId })
    return hookId
end

exports("RegisterHook", RegisterHook)

function RemoveHook(hookId)
    for i = 1, #hooks do
        if hooks[i].id == hookId then
            hooks[i] = nil
        end
    end
end

exports("RemoveHook", RemoveHook)

AddEventHandler("onResourceStop", function(resourceName)
    for i = 1, #hooks do
        if hooks[i].resource == resourceName then
            hooks[i] = nil
        end
    end
end)