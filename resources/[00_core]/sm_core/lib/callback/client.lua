local pendingServerCbs = {}
local clientRateLimit   = {}

local RATE_LIMIT_MAX    = 10   -- max calls per window
local RATE_LIMIT_WINDOW = 5000 -- ms
local CB_TIMEOUT        = 15000 -- ms

local cbCounter = 0
local function makeId()
    cbCounter += 1
    return ('%d-%d-%d'):format(cache.serverId, GetGameTimer(), cbCounter)
end

CreateThread(function()
    while true do
        Wait(30000)
        local now = GetGameTimer()

        for id, entry in pairs(pendingServerCbs) do
            if now > entry.expires then
                lib.print.verbose(('[cb:client] timeout: %s'):format(entry.name))
                pendingServerCbs[id] = nil
            end
        end
    end
end)

---@param name string
---@return boolean allowed
local function checkRateLimit(name)
    local now = GetGameTimer()
    local entry = clientRateLimit[name]

    if not entry or now > entry.resetAt then
        clientRateLimit[name] = { count = 1, resetAt = now + RATE_LIMIT_WINDOW }
        return true
    end

    entry.count += 1

    if entry.count > RATE_LIMIT_MAX then
        lib.print.warn(('[cb:client] rate limit exceeded: %s'):format(name))
        return false
    end

    return true
end

---@param name string Callback name
---@param cb function Handler: function(cb, ...)
local function CreateClientCallback(name, cb)
    QBCore.ClientCallbacks[name] = cb
end

---@param name string Callback name
---@param ... any Optional leading cb function, then args to server
---@return any # Returns server result when no cb provided (async)
local function TriggerCallback(name, ...)
    if not checkRateLimit(name) then return end

    local cb = nil
    local args = { ... }

    if QBCore.Shared.IsFunction(args[1]) then
        cb = args[1]
        table.remove(args, 1)
    end

    local cbId = makeId()
    local p = promise.new()

    pendingServerCbs[cbId] = {
        name     = name,
        promise  = p,
        callback = cb,
        expires  = GetGameTimer() + CB_TIMEOUT,
    }

    TriggerServerEvent('QBCore:Server:TriggerCallback', name, cbId, table.unpack(args))

    if cb == nil then
        Citizen.Await(p)
        return p.value
    end
end

RegisterNetEvent('QBCore:Client:TriggerClientCallback', function(name, cbId, ...)
    if source == '' then return end

    if not QBCore.ClientCallbacks[name] then return end

    QBCore.ClientCallbacks[name](function(...)
        TriggerServerEvent('QBCore:Server:TriggerClientCallback', cbId, ...)
    end, ...)
end)

RegisterNetEvent('QBCore:Client:TriggerCallback', function(name, cbId, ...)
    if source == '' then return end

    local entry = pendingServerCbs[cbId]
    if not entry then return end

    if entry.name ~= name then
        lib.print.warn(('[cb:client] name mismatch: got %s expected %s'):format(name, entry.name))
        return
    end

    if GetGameTimer() > entry.expires then
        pendingServerCbs[cbId] = nil
        return
    end

    pendingServerCbs[cbId] = nil

    entry.promise:resolve(...)

    if entry.callback then
        entry.callback(...)
    end
end)

return {
    CreateClientCallback = CreateClientCallback,
    TriggerCallback      = TriggerCallback,
}
