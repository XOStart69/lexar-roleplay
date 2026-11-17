if not Config.Voice.HearNearby then
    return
end

local liveProximity = {}

local function enterLive(source)
    if not liveProximity[source] then
        return
    end
    liveProximity[source] = true
    debugprint("entered live", source)
    TriggerServerEvent("phone:instagram:enteredLiveProximity", source)
end

local function leaveLive(source)
    if not liveProximity[source] then
        return
    end
    liveProximity[source] = nil
    debugprint("left live 1", source)
    TriggerServerEvent("phone:instagram:leftLiveProximity", source)
end

RegisterNetEvent("phone:instagram:endLive", function(source, newSource)
    if not newSource then
        liveProximity[source] = nil
        return debugprint("left live 2", source)
    end
    if liveProximity[source] then
        liveProximity[source] = nil
        TriggerServerEvent("phone:instagram:leftLiveProximity", newSource, true)
    end
end)

local callProximity = {}

local function leaveCallProximity(source)
    if not source then
        return
    end
    local found, index = table.contains(callProximity, source)
    if not found then
        return
    end
    debugprint("left proximity of", source)
    TriggerServerEvent("phone:phone:leftCallProximity", source)
    exports["lb-phone"]:ClearCallVoiceTarget(source)
    if Config.Voice.SpatialAudio then
        ResetSpatialAudioSubmixForSource(source)
    end
    table.remove(callProximity, index)

    if #callProximity == 0 then
        exports["lb-phone"]:ClearAllCallVoiceTargets()
    end
    return true
end

local function enterCallProximity(source)
    if not source or table.contains(callProximity, source) then
        return
    end
    debugprint("entered proximity of", source)
    TriggerServerEvent("phone:phone:enteredCallProximity", source)
    if Config.Voice.SpatialAudio then
        SetSpatialAudioSubmixForSource(source)
    end
    callProximity[#callProximity + 1] = source
    return true
end

local hearInterval = Interval:new(function()
    local players = GetNearbyPlayers()
    local coords = GetEntityCoords(PlayerPedId())
    for i = 1, #players do
        local player = players[i]
        local state = Player(player.source).state
        local onCall = state.onCallWith and state.speakerphone and state.callAnswered
        local liveSource = state.instapicIsLive
        local dist = #(coords - GetEntityCoords(player.ped))
        if dist <= 10 then
            if liveSource then
                enterLive(liveSource)
            elseif onCall then
                enterCallProximity(player.source)
            elseif state.onCallWith then
                leaveCallProximity(player.source)
            end
        elseif liveSource then
            leaveLive(liveSource)
        elseif state.onCallWith then
            leaveCallProximity(player.source)
        end
    end
    for i = 1, #callProximity do
        local source = callProximity[i]
        if not Player(source).state.onCallWith then
            leaveCallProximity(source)
        end
    end
end, 250, false)

hearInterval.onStart = function()
    debugprint("Hear nearby interval started")
end

hearInterval.onStop = function()
    debugprint("Hear nearby interval stopped")
    for i = 1, #callProximity do
        local source = callProximity[i]
        debugprint("left proximity of", source)
        TriggerServerEvent("phone:phone:leftCallProximity", source)
        -- Safety net for the same race as leaveCallProximity (stuck speakerphone audio).
        exports["lb-phone"]:ClearCallVoiceTarget(source)
        if Config.Voice.SpatialAudio then
            ResetSpatialAudioSubmixForSource(source)
        end
    end
    table.wipe(callProximity)
    -- Belt-and-suspenders: ensure no call target survives the interval stopping.
    exports["lb-phone"]:ClearAllCallVoiceTargets()
    for source in pairs(liveProximity) do
        leaveLive(source)
    end
end

local stateKeys = { "onCallWith", "speakerphone", "callAnswered", "instapicIsLive" }
local playerStates = {}

for i = 1, #stateKeys do
    AddStateBagChangeHandler(stateKeys[i], nil, function(bagName, key, value)
        local source = GetPlayerDataFromStateBag(bagName)
        if not source or source == GetPlayerServerId(PlayerId()) then
            return
        end
        Wait(0)
        if value then
            playerStates[source] = playerStates[source] or {}
            playerStates[source][key] = not not value
            hearInterval:toggle(true)
        else
            if playerStates[source] then
                playerStates[source][key] = nil
                if next(playerStates[source]) == nil then
                    playerStates[source] = nil
                end
            end
        end
        if not next(playerStates) then
            hearInterval:toggle(false)
        end
    end)
end

RegisterNetEvent("onPlayerDropped", function(source)
    playerStates[source] = nil
    if not next(playerStates) then
        hearInterval:toggle(false)
    end
end)
