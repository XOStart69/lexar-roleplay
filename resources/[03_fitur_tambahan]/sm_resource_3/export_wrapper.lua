---@param resource string
---@param name string
---@param cb fun(...):any
return function (resource, name, cb)
    AddEventHandler(('__cfx_export_%s_%s'):format(resource, name), function(setCB)
        setCB(cb)
    end)
end