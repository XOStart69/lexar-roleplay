local STREAM_NAME = 'casino_walla'
local STREAM_SET = 'DLC_VW_Casino_Interior_Sounds'
local AUDIO_SCENE = 'dlc_vw_casino_slot_machines_playing'

local isPlaying = false
local startTokenSeq = 0

local function stopAmbient()
    startTokenSeq = startTokenSeq + 1
    isPlaying = false

    if IsAudioSceneActive(AUDIO_SCENE) then
        StopAudioScene(AUDIO_SCENE)
    end
    StopStream()
end

---Starts the casino ambient audio stream. Guards against duplicate playback via token sequencing.
local function startAmbient()
    if isPlaying then return end

    startTokenSeq = startTokenSeq + 1
    local token = startTokenSeq
    isPlaying = true

    StopStream()
    Wait(500)

    while not LoadStream(STREAM_NAME, STREAM_SET) do
        if token ~= startTokenSeq or not isPlaying then
            return
        end
        Wait(33)
    end

    if token ~= startTokenSeq or not isPlaying then
        StopStream()
        return
    end

    if not IsAudioSceneActive(AUDIO_SCENE) then
        StartAudioScene(AUDIO_SCENE)
    end

    local pos = GetEntityCoords(cache.ped)
    PlayStreamFromPosition(pos.x, pos.y, pos.z)
end

useAreaHooks(function(inArea)
    if inArea then
        CreateThread(startAmbient)
    else
        stopAmbient()
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end
    stopAmbient()
end)
