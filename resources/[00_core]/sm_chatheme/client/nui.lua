local Config = require "config.config"

RegisterNUICallback('NUI_READY', function(_, cb)
    NuiLoaded = true
    cb('ok')
end)

RegisterNUICallback('CONFIG_READY', function(_, cb)
    ConfigLoaded = true
    cb('ok')
end)

RegisterNUICallback('CLOSE_UI', function(_, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback("EXECUTE_COMMAND", function(command, cb)
    if not ConfigLoaded then return cb('ok') end
    Wait(200)
    ExecuteCommand(command)
    cb('ok')
end)

RegisterNUICallback("TOGGLE_DICE", function(_, cb)
    ExecuteCommand('dice')
    cb('ok')
end)

RegisterNUICallback("TOGGLE_RPS", function(_, cb)
    ExecuteCommand('rps')
    cb('ok')
end)

RegisterNUICallback("TOGGLE_THREAD", function(data, cb)
    ThreadType = data.type
    cb('ok')
end)

RegisterNUICallback("SONG_PLAYING", function(data, cb)
    ActiveSong = {
        title = data.title or "Unknown Title",
        url = data.url or "",
        isPlaying = true,
        volume = Config.MusicSettings.defaultVolume,
    }

    if not ActiveSong.url or ActiveSong.url == "" then
        cb('ok')
        return
    end

    if GetResourceState("xsound") ~= "started" then
        cb('ok')
        return
    end

    exports.xsound:PlayUrl("sm_chatheme-song-" .. cache.serverId, ActiveSong.url, ActiveSong.volume, false)

    SendVueMessage("SONG_DATA", {
        title = ActiveSong.title,
        url = ActiveSong.url,
        isPlaying = true,
        volume = ActiveSong.volume,
    })

    cb('ok')
end)

RegisterNUICallback("TOGGLE_PLAYING", function(_, cb)
    if not ActiveSong or not ActiveSong.url then
        cb('ok')
        return
    end

    if GetResourceState('xsound') ~= 'started' then
        cb('ok')
        return
    end

    local xsound = exports.xsound
    local songId = "sm_chatheme-song-" .. cache.serverId

    if not xsound:soundExists(songId) then
        cb('ok')
        return
    end

    local isPaused = xsound:isPaused(songId)

    if isPaused then
        xsound:Resume(songId)
    else
        xsound:Pause(songId)
    end

    local newData = xsound:getInfo(songId)
    SendVueMessage("SONG_DATA", {
        title = ActiveSong.title,
        url = ActiveSong.url,
        isPlaying = isPaused,
        volume = newData.volume,
    })

    cb('ok')
end)

RegisterNUICallback("STOP_MUSIC", function(_, cb)
    if ActiveSong and ActiveSong.url and GetResourceState('xsound') == 'started' then
        local xsound = exports.xsound
        local songId = "sm_chatheme-song-" .. cache.serverId

        if xsound:soundExists(songId) then
            xsound:Destroy(songId)
            ActiveSong.isPlaying = false
        end
    end

    cb('ok')
end)

RegisterNUICallback("UPDATE_VOLUME", function(data, cb)
    if ActiveSong and ActiveSong.url and GetResourceState('xsound') == 'started' then
        local xsound = exports.xsound
        local songId = "sm_chatheme-song-" .. cache.serverId

        if xsound:soundExists(songId) then
            local volume = data.volume and tonumber(data.volume) / 100 or Config.MusicSettings.defaultVolume
            xsound:setVolume(songId, volume)
        end
    end

    cb('ok')
end)