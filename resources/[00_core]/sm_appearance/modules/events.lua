local handlers = {}

local events = {}

---@param name string
---@param fn function
function events.on(name, fn)
    local list = handlers[name]

    if not list then
        list = {}
        handlers[name] = list
    end

    list[#list + 1] = fn
end

---@param name string
---@param ... any
---@return boolean allowed
function events.emit(name, ...)
    local list = handlers[name]

    if not list then return true end

    for i = 1, #list do
        local ok, response = pcall(list[i], ...)

        if not ok then
            lib.print.error(("handler %d for '%s' failed: %s"):format(i, name, response))
        elseif response == false then
            return false
        end
    end

    return true
end

return events
