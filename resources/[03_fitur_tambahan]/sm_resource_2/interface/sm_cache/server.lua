--[[
    sm_cache :: server
    Bangun daftar aset stream (model, txd, anim, ped) dari metadata manifest tiap resource,
    cache hasilnya, lalu kirim ke klien yang meminta.
]]

local SELF = GetCurrentResourceName()
local COOLDOWN = 5
local MAX_PER_RESOURCE = 6000

local MODEL_EXT = { ydr = true }
local TXD_EXT = { ytd = true }
local ANIM_EXT = { ycd = true }

local PED_PREFIX = {
    'a_m_', 'a_f_', 'mp_m_', 'mp_f_', 'cs_', 'csb_', 'ig_', 'g_m_', 'g_f_',
    's_m_', 's_f_', 'u_m_', 'u_f_', 'hc_'
}

local cache
local building = false
local queue = {}
local cooldowns = {}

local function notify(src, message, nType)
    lib.notify(src, { description = message, type = nType or 'inform' })
end

local function isPed(name)
    local lower = name:lower()

    for i = 1, #PED_PREFIX do
        local prefix = PED_PREFIX[i]
        if lower:sub(1, #prefix) == prefix then return true end
    end

    return false
end

local function scanResource(name)
    local entry = { n = name, m = {}, t = {}, a = {}, p = {} }
    local count = GetNumResourceMetadata(name, 'file')
    if count > MAX_PER_RESOURCE then count = MAX_PER_RESOURCE end

    for i = 0, count - 1 do
        local path = GetResourceMetadata(name, 'file', i)

        if path then
            local file = path:match('([^/\\]+)$')
            local base, ext = file and file:match('^(.+)%.(%a+)$')

            if base then
                ext = ext:lower()

                if MODEL_EXT[ext] then
                    if isPed(base) then
                        entry.p[#entry.p + 1] = base
                    else
                        entry.m[#entry.m + 1] = base
                    end
                elseif TXD_EXT[ext] then
                    entry.t[#entry.t + 1] = base
                elseif ANIM_EXT[ext] then
                    entry.a[#entry.a + 1] = base
                end
            end
        end
    end

    entry.h = tostring(GetHashKey(('%s:%d'):format(name, #entry.m + #entry.t + #entry.a + #entry.p)))
    return entry
end

local function build()
    local resources = {}
    local total = GetNumResources()

    for i = 0, total - 1 do
        local name = GetResourceByFindIndex(i)

        if name and name ~= SELF and GetResourceState(name) == 'started' then
            resources[#resources + 1] = scanResource(name)
        end

        if i % 40 == 0 then Wait(0) end
    end

    return resources
end

local function deliver(src)
    if not cache then return end

    TriggerClientEvent('sm_cache:list', src, cache.version, cache.raw)
    cooldowns[src] = os.time() + COOLDOWN
end

local function ensureCache()
    if cache or building then return end

    building = true

    CreateThread(function()
        local resources = build()
        local raw = json.encode({ r = resources })

        cache = { version = tostring(GetHashKey(raw)), raw = raw }
        building = false

        print(('^2[sm_cache] daftar aset siap: %d resource^7'):format(#resources))

        local pending = queue
        queue = {}

        for src in pairs(pending) do
            if GetPlayerName(src) then deliver(src) end
        end
    end)
end

RegisterNetEvent('sm_cache:request', function()
    local src = source

    local wait = cooldowns[src]
    if wait and wait > os.time() then
        TriggerClientEvent('sm_cache:list', src, nil, nil, true)
        return
    end

    if not cache then
        ensureCache()

        queue[src] = true
        local position = 0
        for _ in pairs(queue) do position = position + 1 end

        TriggerClientEvent('sm_cache:queued', src, position)
        return
    end

    deliver(src)
end)

AddEventHandler('playerDropped', function()
    queue[source] = nil
    cooldowns[source] = nil
end)

AddEventHandler('onResourceStart', function(resource)
    if resource == SELF then return end
    cache = nil
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == SELF then return end
    cache = nil
end)