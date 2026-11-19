local members = {}
local jammers = {}
local jammerSeq = 0

local function broadcast(channel)
    local players = {}

    for source, name in pairs(members[channel] or {}) do
        players[#players + 1] = { id = source, name = name }
    end

    TriggerClientEvent('mm_radio:client:radioListUpdate', -1, players, channel)
end

RegisterNetEvent('mm_radio:server:addToRadioChannel', function(channel, name)
    local source = source

    if channel == nil then return end

    for ch, list in pairs(members) do
        if list[source] then
            list[source] = nil
            broadcast(ch)
        end
    end

    members[channel] = members[channel] or {}
    members[channel][source] = name or GetPlayerName(tostring(source))

    broadcast(channel)
end)

RegisterNetEvent('mm_radio:server:removeFromRadioChannel', function(channel)
    local source = source

    if not members[channel] then return end

    members[channel][source] = nil
    broadcast(channel)
end)

RegisterNetEvent('mm_radio:server:createdefaultjammer', function()
    jammerSeq += 1

    jammers[jammerSeq] = { id = jammerSeq, state = false, range = 50.0, channels = {} }

    TriggerClientEvent('mm_radio:client:togglejammer', -1, jammerSeq, false)
end)

RegisterNetEvent('mm_radio:server:togglejammer', function(id)
    local jammer = jammers[tonumber(id) or 0]

    if not jammer then return end

    jammer.state = not jammer.state

    TriggerClientEvent('mm_radio:client:togglejammer', -1, jammer.id, jammer.state)
end)

RegisterNetEvent('mm_radio:server:removejammer', function(id)
    id = tonumber(id) or 0

    if not jammers[id] then return end

    jammers[id] = nil

    TriggerClientEvent('mm_radio:client:removejammer', -1, id)
end)

RegisterNetEvent('mm_radio:server:changeJammerRange', function(id, range)
    local jammer = jammers[tonumber(id) or 0]

    if not jammer then return end

    jammer.range = tonumber(range) or jammer.range

    TriggerClientEvent('mm_radio:client:changeJammerRange', -1, jammer.id, jammer.range)
end)

RegisterNetEvent('mm_radio:server:addallowedchannel', function(id, channels)
    local jammer = jammers[tonumber(id) or 0]

    if not jammer then return end

    jammer.channels = channels or {}

    TriggerClientEvent('mm_radio:client:addallowedchannel', -1, jammer.id, jammer.channels)
end)

RegisterNetEvent('mm_radio:server:removeallowedchannel', function(id, channels)
    local jammer = jammers[tonumber(id) or 0]

    if not jammer then return end

    jammer.channels = channels or {}

    TriggerClientEvent('mm_radio:client:removeallowedchannel', -1, jammer.id, jammer.channels)
end)

RegisterNetEvent('mm_radio:server:consumeBattery', function(data)
    if type(data) ~= 'table' then return end
end)

RegisterNetEvent('mm_radio:server:rechargeBattery', function()
    TriggerClientEvent('mm_radio:client:recharge', source)
end)

AddEventHandler('playerDropped', function()
    local source = source

    for ch, list in pairs(members) do
        if list[source] then
            list[source] = nil
            broadcast(ch)
        end
    end
end)

lib.print.info('mm_radio server siap')
