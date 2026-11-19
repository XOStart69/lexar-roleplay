local shared = lib.load('animations.Shared')

local function getEmote(name)
    if type(name) ~= 'string' then return nil end

    return shared[name]
end

RegisterNetEvent('sm_emote:server:requestShared', function(target, emoteName)
    local source = source
    target = tonumber(target)

    if not target or target == source then return end
    if not GetPlayerName(target) then return end

    local data = getEmote(emoteName)

    if not data or not data.secondPlayersAnim then return end

    TriggerClientEvent('sm_emote:client:requestShared', target, source, emoteName)
end)

RegisterNetEvent('sm_emote:server:confirmShared', function(sender, emoteName)
    local source = source
    sender = tonumber(sender)

    if not sender or not GetPlayerName(sender) then return end

    local data = getEmote(emoteName)

    if not data or not data.secondPlayersAnim then return end

    TriggerClientEvent('sm_emote:client:syncEmote', source, sender, emoteName, data.secondPlayersAnim)
    TriggerClientEvent('sm_emote:client:syncEmoteSource', sender, source, emoteName)
end)

lib.print.info('sm_emotes server siap')
