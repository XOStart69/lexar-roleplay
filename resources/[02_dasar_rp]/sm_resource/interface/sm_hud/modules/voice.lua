if GetResourceState('pma-voice') ~= 'started' then
    return
end

local lastTalking = false
local lastProximity = 0
local lastMuted = false
local lastOnRadio = false
local lastTalkingOnRadio = false

local pma = exports['pma-voice']
local talkingOnRadio = false

interface.callback('rhd_hud:setVoiceRange', function(data, cb)
    cb('ok')
end)

AddEventHandler("pma-voice:radioActive", function(isRadioTalking)
    talkingOnRadio = isRadioTalking
end)

local function voiceTick()
    local tick = 2000

    if not playerState.isLoggedIn then
        return tick
    end

    local talking = NetworkIsPlayerTalking(cache.playerId)
    local proximity = playerState.proximity?.distance or 3.0
    local muted = pma:isPlayerMuted(cache.serverId)
    local radioChannel = playerState.radioChannel
    local onRadio = radioChannel ~= nil and radioChannel ~= 0

    if talking ~= lastTalking or proximity ~= lastProximity or muted ~= lastMuted
    or onRadio ~= lastOnRadio or talkingOnRadio ~= lastTalkingOnRadio then

        lastTalking = talking
        lastProximity = proximity
        lastMuted = muted
        lastOnRadio = onRadio
        lastTalkingOnRadio = talkingOnRadio

        interface.send({
            action = 'updateVoice',
            data = {
                talking = talking,
                proximity = proximity,
                muted = muted,
                onRadio = onRadio,
                talkingOnRadio = talkingOnRadio,
            },
        })
        tick = 250
    else
        tick = 500
    end

    return tick
end

CreateThread(function()
    while true do
        Wait(voiceTick())
    end
end)
