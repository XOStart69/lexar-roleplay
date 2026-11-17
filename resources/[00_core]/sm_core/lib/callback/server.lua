local pendingClientCbs = {}
local serverCbRateLimit = {}

local RATE_LIMIT_MAX    = 10   -- max calls per window
local RATE_LIMIT_WINDOW = 5000 -- ms
local CB_TIMEOUT        = 120000 -- ms sebelum entry dianggap expired

local cbCounter = 0
local function makeId(source)
    cbCounter += 1
    return ('%d-%d-%d'):format(source, GetGameTimer(), cbCounter)
end

CreateThread(function()
    while true do
        Wait(30000)
        local now = GetGameTimer()

        for id, entry in pairs(pendingClientCbs) do
            if now > entry.expires then
                lib.print.verbose(('[cb:server] timeout: %s | src: %s'):format(entry.name, entry.source))
                pendingClientCbs[id] = nil
            end
        end
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    serverCbRateLimit[src] = nil

    for id, entry in pairs(pendingClientCbs) do
        if entry.source == src then
            pendingClientCbs[id] = nil
        end
    end
end)

---@param src number
---@param name string
---@return boolean allowed
local function checkRateLimit(src, name)
    local now = GetGameTimer()
    serverCbRateLimit[src] = serverCbRateLimit[src] or {}
    local entry = serverCbRateLimit[src][name]

    if not entry or now > entry.resetAt then
        serverCbRateLimit[src][name] = { count = 1, resetAt = now + RATE_LIMIT_WINDOW }
        return true
    end

    entry.count += 1
    if entry.count > RATE_LIMIT_MAX then
        lib.print.warn(('[cb:server] rate limit exceeded: %s | src: %s'):format(name, src))
        return false
    end

    return true
end

---@param name string Callback name
---@param source number Player server ID
---@param ... any Additional args passed to client (optional leading cb function)
---@return any # Returns callback result when no cb provided (async)
local function TriggerClientCallback(name, source, ...)
    local cb = nil
    local args = { ... }

    if QBCore.Shared.IsFunction(args[1]) then
        cb = args[1]
        table.remove(args, 1)
    end

    local cbId = makeId(source)
    local p = promise.new()

    pendingClientCbs[cbId] = {
        source   = source,
        name     = name,
        promise  = p,
        callback = cb,
        expires  = GetGameTimer() + CB_TIMEOUT,
    }

    TriggerClientEvent('QBCore:Client:TriggerClientCallback', source, name, cbId, table.unpack(args))

    if cb == nil then
        Citizen.Await(p)
        return p.value
    end
end

---@param name string Callback name
---@param cb function Handler: function(source, cb, ...)
local function CreateCallback(name, cb)
    QBCore.ServerCallbacks[name] = cb
end

RegisterNetEvent('QBCore:Server:TriggerClientCallback', function(cbId, ...)
    local source = source
    local entry = pendingClientCbs[cbId]

    if not entry then return end
    if entry.source ~= source then
        lib.print.warn(('[cb:server] cbId mismatch src %s != expected %s | id: %s'):format(source))
        return
    end

    if GetGameTimer() > entry.expires then
        pendingClientCbs[cbId] = nil
        return
    end

    pendingClientCbs[cbId] = nil

    entry.promise:resolve(...)

    if entry.callback then
        entry.callback(...)
    end
end)

RegisterNetEvent('QBCore:Server:TriggerCallback', function(name, cbId, ...)
    local src = source

    if not QBCore.ServerCallbacks[name] then
        lib.print.warn(('[cb:server] callback not found: %s | src: %s'):format(name, src))
        return
    end

    if not checkRateLimit(src, name) then return end

    QBCore.ServerCallbacks[name](src, function(...)
        TriggerClientEvent('QBCore:Client:TriggerCallback', src, name, cbId, ...)
    end, ...)
end)

return {
    TriggerClientCallback = TriggerClientCallback,
    CreateCallback        = CreateCallback,
}
