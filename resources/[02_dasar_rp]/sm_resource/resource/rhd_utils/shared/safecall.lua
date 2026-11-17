local f = setmetatable({}, {
    __newindex = function(self, key, fn)
        rawset(self, key, fn)
        exports(key, fn)
    end
})

---@param cb function Callback function to execute safely
---@param ... any Arguments to pass to callback
---@return any|nil result Returns callback result or nil on error
function f.fun(cb, ...)
    assert(type(cb) == 'function', 'safecall: callback must be a function')

    local success, result = pcall(cb, ...)

    if not success then
        local info = debug.getinfo(2, 'Sl')
        local source = info.source:match('^@?(.+)$') or info.source
        local line = info.currentline or 0
        
        lib.print.error(('safecall failed at %s:%d\n%s'):format(source, line, result))
        return nil
    end

    return result
end

_ENV.safecall = f