RegisterNUICallback("voice:getConfig", function(data, cb)
    cb({
        recordNearbyVoices = Config.Voice.RecordNearby,
        rtc = Config.RTCConfig
    })
end)

if not Config.Voice.RecordNearby then
    return
end

local activeChannels = {}

local volumeInterval = Interval:new(function()
    local coords = GetEntityCoords(PlayerPedId())
    for _, channel in pairs(activeChannels) do
        local dist = #(coords - GetEntityCoords(channel.ped))
        local volume = GetVoiceVolume(dist)
        if volume ~= channel.volume then
            channel.volume = volume
            SendNUIAction("voice:setVolume", { channel = channel.channel, volume = volume })
        end
    end
end, 50, false)

Interval:new(function()
    local newChannels = {}
    local players = GetNearbyPlayers()
    local coords = GetEntityCoords(PlayerPedId())
    for i = 1, #players do
        local player = players[i]
        local state = Player(player.source).state
        local peerId = state and state.listeningPeerId
        if peerId then
            local dist = #(coords - GetEntityCoords(player.ped))
            if dist <= 25.0 then
                local entry = {
                    source = player.source,
                    ped = player.ped,
                    channel = state.listeningPeerId
                }
                newChannels[player.source] = entry
                local existing = activeChannels[player.source]
                if existing then
                    entry.volume = existing.volume
                else
                    entry.volume = GetVoiceVolume(dist)
                    SendNUIAction("voice:joinChannel", { channel = state.listeningPeerId, volume = GetVoiceVolume(dist) })
                end
            end
        end
    end
    for source, channel in pairs(activeChannels) do
        if not newChannels[source] then
            SendNUIAction("voice:leaveChannel", channel.channel)
        end
    end
    activeChannels = newChannels
    volumeInterval:toggle(next(activeChannels) ~= nil)
end, 1000)

RegisterNetEvent("phone:startedListening", function(serverId, channel)
    local player = GetPlayerFromServerId(serverId)
    if not player or player == PlayerId() or player == -1 then
        return
    end
    local myPed = PlayerPedId()
    local targetPed = GetPlayerPed(player)
    local dist = #(GetEntityCoords(myPed) - GetEntityCoords(targetPed))
    if not DoesEntityExist(targetPed) or targetPed == myPed or dist > 25.0 then
        return
    end
    if activeChannels[serverId] then
        return
    end
    activeChannels[serverId] = {
        source = serverId,
        ped = targetPed,
        channel = channel,
        volume = GetVoiceVolume(dist)
    }
    SendNUIAction("voice:joinChannel", { channel = channel, volume = GetVoiceVolume(dist) })
    volumeInterval:toggle(true)
end)

RegisterNetEvent("phone:stoppedListening", function(serverId, channel)
    if not activeChannels[serverId] then
        return
    end
    SendNUIAction("voice:leaveChannel", channel)
    activeChannels[serverId] = nil
    volumeInterval:toggle(next(activeChannels) ~= nil)
end)

RegisterNUICallback("setListeningPeerId", function(data, cb)
    TriggerServerEvent("phone:setListeningPeerId", data)
    cb("ok")
end)
