local activeSounds = {}
local currentSound = nil
local previewSoundId = nil
local previewSoundKey = nil

local function getRingtone(name)
    local soundName = "1"
    local soundSet = "ringtone"
    local audioBank = nil
    if "vibrate" == name then
        return "vibrate", "ringtone"
    end
    if not (name and Config.Sound.Ringtones[name]) then
        name = next(Config.Sound.Ringtones)
    end
    if name then
        local ringtone = Config.Sound.Ringtones[name]
        soundName = ringtone.name
        soundSet = ringtone.soundSet
        audioBank = ringtone.audioBank
    end
    return soundName, soundSet, audioBank
end

local function getTexttone(name)
    local soundName = "1"
    local soundSet = "notification"
    local audioBank = nil
    if "vibrate" == name then
        return "vibrate", "notification"
    end
    if not (name and Config.Sound.Notifications[name]) then
        name = next(Config.Sound.Notifications)
    end
    if name then
        local notification = Config.Sound.Notifications[name]
        soundName = notification.name
        soundSet = notification.soundSet
        audioBank = notification.audioBank
    end
    return soundName, soundSet, audioBank
end

local function loadAudioBank(audioBank)
    local timeout = GetGameTimer() + 1000
    debugprint("Waiting for audio bank to load")
    while true do
        if RequestScriptAudioBank(audioBank or "dlc_lbscripts/sounds", false) then
            break
        end
        Wait(0)
        if timeout < GetGameTimer() then
            infoprint("warning", "Failed to load audio bank, setting Config.Sound.System to 'nui'. This usually happens when you have too many sounds on your server.")
            Config.Sound.System = "nui"
            SendNUIAction("updateConfigValue", { config = { sound = { system = "nui" } } })
            return false
        end
    end
    debugprint("Audio bank loaded")
    return true
end

local function playSpatialSound(entity, soundType, volume, soundName, soundSet, audioBank)
    if "nui" == Config.Sound.System then
        return
    end
    if type(Config.Sound.Volume.Static) == "number" then
        volume = Config.Sound.Volume.Static
    end
    if Config.Sound.Volume.Multiplier then
        volume = volume * Config.Sound.Volume.Multiplier
    end
    volume = math.clamp(volume, Config.Sound.Volume.Min or 0.0, Config.Sound.Volume.Max or 1.0)
    volume = math.clamp(volume, 0.0, 1.0)
    volume = (volume or 1) / 1
    if 0 == volume then
        return
    end
    if not loadAudioBank(audioBank) then
        return
    end
    local soundId = GetSoundId()
    debugprint("Playing sound:", soundName, soundSet, "with volume:", volume)
    PlaySoundFromEntity(soundId, soundName, entity, soundSet, false, 0)
    SetVariableOnSound(soundId, "Volume", volume)
    ReleaseScriptAudioBank()
    if "ringtone" ~= soundType and "alarm" ~= soundType then
        ReleaseSoundId(soundId)
    end
    local playerPed = PlayerPedId()
    if entity ~= playerPed and Config.Sound.MaxDistance then
        Citizen.CreateThreadNow(function()
            local muted = false
            while true do
                if HasSoundFinished(soundId) then
                    break
                end
                local distance = #(GetEntityCoords(playerPed) - GetEntityCoords(entity))
                if distance > Config.Sound.MaxDistance then
                    if not muted then
                        SetVariableOnSound(soundId, "Volume", 0.0)
                        debugprint("Sound volume set to 0 due to being too far away")
                        muted = true
                    end
                elseif muted then
                    SetVariableOnSound(soundId, "Volume", volume)
                    debugprint("Sound volume restored")
                    muted = false
                end
                Wait(100)
            end
        end)
    end
    return soundId
end

function PlayPhoneSound(soundType, soundName)
    local volume = ((settings and settings.sound and settings.sound.volume) or 0.5) / 1
    local name = nil
    local soundSet = nil
    local audioBank = nil
    debugprint("PlayPhoneSound", soundType)
    if not ValidateChecks("playNativePhoneSound", soundType, soundName) then
        debugprint("PlayPhoneSound: playNativePhoneSound check cancelled the sound")
        return
    end
    if "ringtone" == soundType or "alarm" == soundType then
        if currentSound then
            StopSound(currentSound)
            ReleaseSoundId(currentSound)
            currentSound = nil
        end
    end
    if "cameraShutter" == soundType then
        name = "camera-shutter"
        soundSet = "other"
    elseif "ringtone" == soundType then
        local ringtone = soundName
        if not soundName then
            ringtone = settings and settings.sound and settings.sound.ringtone
        end
        if settings and settings.sound and settings.sound.silent then
            ringtone = "vibrate"
            volume = 1.0
        end
        name, soundSet, audioBank = getRingtone(ringtone)
    elseif "alarm" == soundType then
        name = "alarm"
        soundSet = "other"
        if settings and settings.sound and settings.sound.silent then
            name, soundSet, audioBank = getRingtone("vibrate")
            volume = 1.0
        end
    elseif "notification" == soundType then
        local texttone = soundName
        if not soundName then
            texttone = settings and settings.sound and settings.sound.notification
        end
        name, soundSet, audioBank = getTexttone(texttone)
    else
        debugprint("PlayPhoneSound: invalid sound type", soundType)
        return
    end
    local soundId = playSpatialSound(PlayerPedId(), soundType, volume, name, soundSet, audioBank)
    if not soundId then
        return
    end
    if "ringtone" == soundType or "alarm" == soundType then
        currentSound = soundId
        if not phoneOpen then
            SetVariableOnSound(soundId, "Muffle", 0.05)
        end
    end
    if not Config.Sound.Sync then
        return
    end
    local nearbyPlayers = GetNearbyPlayers()
    local sources = {}
    for i = 1, #nearbyPlayers do
        sources[i] = nearbyPlayers[i].source
    end
    TriggerServerEvent("phone:sound:playSound", sources, soundType, name, soundSet, audioBank)
end

function StopPhoneSound()
    if not currentSound then
        return
    end
    StopSound(currentSound)
    ReleaseSoundId(currentSound)
    currentSound = nil
end

RegisterNetEvent("phone:sound:playSound", function(serverId, soundType, volume, soundName, soundSet, audioBank)
    local ped = GetPlayerPed(GetPlayerFromServerId(serverId))
    if ped == PlayerPedId() then
        return
    end
    playSpatialSound(ped, soundType, volume, soundName, soundSet, audioBank)
end)

local function stopActiveSound(id)
    local sound = activeSounds[id]
    if sound then
        StopSound(sound)
        ReleaseSoundId(sound)
        activeSounds[id] = nil
    end
end

RegisterNetEvent("onPlayerDropped", function(id)
    stopActiveSound(id)
end)

AddStateBagChangeHandler("lbPhoneAudio", nil, function(bagName, key, value, reserved, replicated)
    local playerId, ped = GetPlayerDataFromStateBag(bagName)
    if not playerId or playerId == GetPlayerServerId(PlayerId()) then
        return
    end
    stopActiveSound(playerId)
    if not value or not ped then
        return
    end
    local soundId = playSpatialSound(ped, table.unpack(value))
    if not soundId then
        return
    end
    if not Player(playerId).state.phoneOpen then
        SetVariableOnSound(soundId, "Muffle", 0.05)
    end
    activeSounds[playerId] = soundId
end)

AddStateBagChangeHandler("phoneOpen", nil, function(bagName, key, value, reserved, replicated)
    local playerId = tonumber(bagName:match("player:(%d+)"))
    if not playerId then
        return
    end
    local sound
    if playerId == GetPlayerServerId(PlayerId()) and currentSound then
        sound = currentSound
    else
        sound = activeSounds[playerId]
    end
    if not sound then
        return
    end
    SetVariableOnSound(sound, "Muffle", value and 1.0 or 0.05)
end)

RegisterNetEvent("phone:sound:stopSound", function()
    StopPhoneSound()
end)

RegisterNUICallback("playSound", function(data, cb)
    cb("ok")
    PlayPhoneSound(data.soundType, data.soundName)
end)

RegisterNUICallback("stopSound", function(data, cb)
    cb("ok")
    TriggerServerEvent("phone:sound:stopSound")
end)

RegisterNUICallback("previewSound", function(data, cb)
    cb("ok")
    if not loadAudioBank() then
        return
    end
    local soundName = nil
    local soundSet = nil
    local audioBank = nil
    if "ringtone" == data.soundType then
        soundName, soundSet, audioBank = getRingtone(data.sound)
    elseif "texttone" == data.soundType then
        soundName, soundSet, audioBank = getTexttone(data.sound)
    else
        return
    end
    if previewSoundId then
        StopSound(previewSoundId)
    else
        previewSoundId = GetSoundId()
    end
    local key = soundName .. soundSet
    previewSoundKey = key
    PlaySoundFrontend(previewSoundId, soundName, soundSet, false)
    local volume = (settings and settings.sound and settings.sound.volume) or 1
    if type(Config.Sound.Volume.Static) == "number" then
        volume = Config.Sound.Volume.Static
    end
    if Config.Sound.Volume.Multiplier then
        volume = volume * Config.Sound.Volume.Multiplier
    end
    volume = math.clamp(volume, Config.Sound.Volume.Min or 0.0, Config.Sound.Volume.Max or 1.0)
    volume = math.clamp(volume, 0.0, 1.0)
    volume = (volume or 1) / 1
    SetVariableOnSound(previewSoundId, "Volume", volume)
    Wait(5000)
    if previewSoundKey ~= key then
        return
    end
    if not previewSoundId then
        return
    end
    StopSound(previewSoundId)
    ReleaseSoundId(previewSoundId)
    ReleaseScriptAudioBank()
    previewSoundId = nil
    previewSoundKey = nil
end)

RegisterNUICallback("stopPreviewingSound", function(data, cb)
    cb("ok")
    if previewSoundId then
        StopSound(previewSoundId)
        ReleaseSoundId(previewSoundId)
        ReleaseScriptAudioBank()
        previewSoundId = nil
        previewSoundKey = nil
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end
    for _, sound in pairs(activeSounds) do
        ReleaseSoundId(sound)
    end
    ReleaseScriptAudioBank()
end)

CreateThread(function()
    if "nui" == Config.Sound.System then
        return
    end
    while true do
        if FrameworkLoaded then
            break
        end
        Wait(0)
    end
    if not loadAudioBank() then
        Config.Sound.System = "nui"
    end
    ReleaseScriptAudioBank()
end)
