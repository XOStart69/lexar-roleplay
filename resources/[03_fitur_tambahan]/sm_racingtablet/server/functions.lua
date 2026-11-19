---------------------
-- CALLBACK SERVER --
---------------------

local callbacks = {}

---@param name string
---@param handler fun(source: number, ...): any
function cwCallback.register(name, handler)
    callbacks[name] = handler
end

RegisterNetEvent('server:triggerServerCallback', function(name, id, ...)
    local src = source
    local handler = callbacks[name]

    if not handler then
        if Config.Debug then print(('[racing] callback tidak dikenal: %s'):format(tostring(name))) end
        TriggerClientEvent('client:serverCallback', src, id)
        return
    end

    local result = table.pack(pcall(handler, src, ...))

    if not result[1] then
        print(('[racing] callback %s gagal: %s'):format(tostring(name), tostring(result[2])))
        TriggerClientEvent('client:serverCallback', src, id)
        return
    end

    TriggerClientEvent('client:serverCallback', src, id, result[2], result[3], result[4], result[5])
end)

---@param src number
---@param message string
---@param kind? string
function notify(src, message, kind)
    TriggerClientEvent('ox_lib:notify', src, { title = Config.NotifyTitle, description = message, type = kind or 'inform' })
end

---@param input any
---@return string
function StrictSanitize(input)
    if type(input) ~= 'string' then return '' end

    return (input:gsub('^%s+', ''):gsub('%s+$', ''):gsub('%s+', ' '):gsub('[^%w%s%-_]', ''))
end

---@param a vector3
---@param b vector3
---@return number
function distance(a, b)
    return #(a - b)
end