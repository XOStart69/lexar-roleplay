--[[
    sm_asling :: server
    Timer asling per pemain. Durasi disimpan di server, klien hanya menampilkan.
    Mulai lewat /asling <detik> [id], batalkan lewat /aslingstop [id].
]]

local sessions = {}

local MAX_SECONDS = 3600
local DEFAULT_SECONDS = 300

local function notify(src, message, nType)
    lib.notify(src, { description = message, type = nType or 'inform' })
end

local function cancel(src)
    local session = sessions[src]
    if not session then return false end

    sessions[src] = nil
    TriggerClientEvent('sm_asling:cancel', src)

    return true
end

local function start(src, seconds)
    if sessions[src] then cancel(src) end

    local duration = math.floor(seconds * 1000)

    sessions[src] = {
        endAt = GetGameTimer() + duration
    }

    TriggerClientEvent('sm_asling:start', src, duration)

    SetTimeout(duration, function()
        local session = sessions[src]
        if not session then return end
        if GetGameTimer() < session.endAt - 50 then return end

        sessions[src] = nil
        TriggerClientEvent('sm_asling:finish', src)
    end)
end

lib.callback.register('sm_asling:remaining', function(src)
    local session = sessions[src]
    if not session then return 0 end

    return math.max(0, session.endAt - GetGameTimer())
end)

lib.addCommand('asling', {
    help = 'Mulai timer asling',
    params = {
        { name = 'detik', type = 'number', help = ('Durasi 1-%d detik'):format(MAX_SECONDS), optional = true },
        { name = 'id', type = 'number', help = 'ID pemain target', optional = true }
    },
    restricted = 'admin'
}, function(src, args)
    local seconds = math.floor(tonumber(args.detik) or DEFAULT_SECONDS)
    seconds = math.max(1, math.min(MAX_SECONDS, seconds))

    local target = tonumber(args.id) or src

    if not GetPlayerName(target) then
        return notify(src, 'Pemain target tidak ditemukan.', 'error')
    end

    start(target, seconds)
    notify(src, ('Timer %d detik dimulai untuk %s.'):format(seconds, GetPlayerName(target)), 'success')
end)

lib.addCommand('aslingstop', {
    help = 'Batalkan timer asling',
    params = {
        { name = 'id', type = 'number', help = 'ID pemain target', optional = true }
    },
    restricted = 'admin'
}, function(src, args)
    local target = tonumber(args.id) or src

    if not cancel(target) then
        return notify(src, 'Tidak ada timer aktif.', 'error')
    end

    notify(src, 'Timer dibatalkan.', 'success')
end)

AddEventHandler('playerDropped', function()
    sessions[source] = nil
end)