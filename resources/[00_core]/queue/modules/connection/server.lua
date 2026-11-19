local maxClients = GetConvarInt('sv_maxclients', 32)

if Config.DisableHardCap then
    SetConvar('sv_maxclients', '5')
end

local queue = {}
local grace = {}
local lastJoin = 0
local discordCache = {}

local function now()
    return os.time()
end

local function identifiers(src)
    local list = {}

    for _, entry in ipairs(GetPlayerIdentifiers(src) or {}) do
        local kind, value = entry:match('^(%w+):(.+)$')

        if kind and value then list[kind] = value end
    end

    return list
end

local function slots()
    return maxClients
end

local function priorityOf(ids, src)
    local points = 0
    local id = ids[Config.Identifier]

    if not id then return 0 end

    local cached = discordCache[id]

    if cached and cached.expires > now() then
        return cached.points
    end

    local reconnect = grace[id]

    if Config.ReconnectPrio.enabled and reconnect and reconnect > now() then
        points += Config.ReconnectPrio.points
    end

    if Config.Discord.enabled and Config.Discord.token ~= '' and ids.discord then
        local fetched = discordCache[ids.discord]

        if not fetched or fetched.expires <= now() then
            local ok, body = pcall(function()
                local payload

                PerformHttpRequest(('https://discord.com/api/v10/guilds/%s/members/%s'):format(
                    Config.Discord.guildId, ids.discord), function(status, text)
                    if status == 200 then payload = text end
                end, 'GET', '', {
                    ['Authorization'] = ('Bot %s'):format(Config.Discord.token),
                    ['Content-Type'] = 'application/json',
                })

                local waited = 0

                while not payload and waited < 2000 do
                    Wait(50)
                    waited += 50
                end

                return payload
            end)

            local earned = Config.Discord.memberPoints

            if ok and body then
                local member = json.decode(body)

                if member and member.roles then
                    for i = 1, #member.roles do
                        earned += Config.Discord.priorityRoles[member.roles[i]] or 0
                    end
                end
            end

            fetched = { points = earned, expires = now() + Config.Discord.cacheTime }
            discordCache[ids.discord] = fetched
        end

        points += fetched.points
    end

    discordCache[id] = { points = points, expires = now() + Config.Discord.cacheTime }

    return points
end

local function admit(entry)
    if not entry.deferrals then return end

    entry.admitted = true
    lastJoin = now()

    entry.deferrals.update(Lang.admitted)
    entry.deferrals.done()

    queue[entry.id] = nil
end

local function reject(entry, reason)
    if not entry.deferrals then return end

    entry.admitted = true
    entry.deferrals.done(reason)

    queue[entry.id] = nil
end

local function sortQueue()
    local list = {}

    for _, entry in pairs(queue) do
        list[#list + 1] = entry
    end

    table.sort(list, function(a, b)
        if a.priority == b.priority then return a.joinedAt < b.joinedAt end

        return a.priority > b.priority
    end)

    return list
end

CreateThread(function()
    while true do
        Wait(1000)

        local list = sortQueue()
        local free = slots() - GetPlayerCount()

        for index, entry in ipairs(list) do
            if entry.admitted then goto continue end

            if now() - entry.joinedAt > Config.Timeout then
                reject(entry, Lang.timeout:format(Config.Timeout))
                goto continue
            end

            if free > 0 and (now() - lastJoin) * 1000 >= Config.JoinDelay then
                free -= 1
                admit(entry)
            elseif free <= 0 then
                entry.deferrals.update(('%s\n%s'):format(Lang.waiting, Lang.queue:format(index, #list)))
            else
                entry.deferrals.update(('%s\n%s'):format(Lang.waiting, Lang.queue:format(index, #list)))
            end

            ::continue::
        end
    end
end)

AddEventHandler('playerConnecting', function(name, _, deferrals)
    local src = source
    local ids = identifiers(src)

    deferrals.defer()
    deferrals.update(Lang.checking)

    for i = 1, #Config.RequiredIdentifiers do
        local key = Config.RequiredIdentifiers[i]

        if not ids[key] then
            return deferrals.done(Lang.required:format(key))
        end
    end

    local id = ids[Config.Identifier]

    if not id then return deferrals.done(Lang.required:format(Config.Identifier)) end

    if Config.AntiSpam.enabled then
        local recent = grace['spam:' .. id]

        if recent and recent > now() then
            return deferrals.done(Lang.spam:format(math.ceil(recent - now())))
        end

        grace['spam:' .. id] = now() + math.floor(Config.AntiSpam.time / 1000)
    end

    local priority = priorityOf(ids, src)

    if grace[id] and grace[id] > now() and Config.ReconnectPrio.enabled then
        deferrals.update(Lang.reconnect)
    end

    queue[src] = {
        id = src,
        name = name,
        identifier = id,
        priority = priority,
        joinedAt = now(),
        deferrals = deferrals,
        admitted = false,
    }

    deferrals.update(Lang.connecting)
end)

RegisterNetEvent('queue:playerInitiated', function()
    local src = source
    local entry = queue[src]

    if not entry then return end

    entry.admitted = true
    queue[src] = nil

    if Config.ReconnectPrio.enabled then
        grace[entry.identifier] = now() + (Config.ReconnectPrio.time * 60)
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    local entry = queue[src]

    if entry then queue[src] = nil end

    local ids = identifiers(src)
    local id = ids[Config.Identifier]

    if id and Config.ReconnectPrio.enabled then
        grace[id] = now() + (Config.ReconnectPrio.time * 60)
    end
end)

lib.print.info(('queue siap (max %d slot, hardcap %s)'):format(maxClients, tostring(Config.DisableHardCap)))
