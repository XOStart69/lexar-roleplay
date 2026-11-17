if not interface.init() then
    return
end

local inputValue
local inVideoInput = false
local playingVideo = false

local function showVideoInput(disabled)
    if playingVideo then
        return lib.notify({
            description = 'A video is already playing. Please stop the current video before playing a new one.',
            type = 'error'
        })
    end

    interface.send({
        action = 'videoInput:open',
        data = disabled or {}
    })

    inVideoInput = true
    interface.focus(inVideoInput, inVideoInput)

    inputValue = promise.new()
    local value = Citizen.Await(inputValue)

    inVideoInput = false
    interface.focus(inVideoInput, inVideoInput)

    return value
end

local function stopVideo()
    interface.send({
        action = 'videoPlayer:stop',
        data = {}
    })
end

local function pauseVideo()
    interface.send({
        action = 'videoPlayer:pause',
        data = {}
    })
end

local function resumeVideo()
    interface.send({
        action = 'videoPlayer:resume',
        data = {}
    })
end

RegisterNetEvent('rhd_video_player:showInput', function ()
    if source == '' then return end

    interface.send({
        action = 'videoInput:open',
        data = {}
    })
    inVideoInput = true
    interface.focus(inVideoInput, inVideoInput)
end)

RegisterNetEvent('rhd_video_player:playVideo', function (link, volume)
    if source == '' then return end

    interface.send({
        action = 'videoPlayer:play',
        data = {
            link = link,
            volume = volume
        }
    })

    interface.focus(true, false)
    playingVideo = true
end)

RegisterNetEvent('rhd_video_player:sendAction', function (action)
    if source == '' or type(action) ~= 'string' then return end
    action = action:lower()

    if action == 'play' then
        local value = showVideoInput()
        if value then
            TriggerTokenEvent('rhd_video_player:submitVideo', value)
        end
    elseif action == 'stop' then
        stopVideo()
    elseif action == 'pause' then
        pauseVideo()
    elseif action == 'resume' then
        resumeVideo()
    elseif action == 'setvolume' then
        local value = showVideoInput({ link = true, distance = true })
        if value then
            TriggerTokenEvent('rhd_video_player:setVolume', value)
        end
    end
end)

RegisterNetEvent('rhd_video_player:setVolume', function (volume)
    if source == '' or not playingVideo then return end

    interface.send({
        action = 'videoPlayer:setVolume',
        data = volume
    })
end)

interface.callback('videoPlayer:stopped', function (data, cb)
    playingVideo = false
    interface.focus(false, false)
    cb(true)
end)

interface.callback('videoInput:submit', function (data, cb)
    inVideoInput = false
    interface.focus(inVideoInput, inVideoInput)
    cb(true)

    if inputValue then
        inputValue:resolve(data)
        inputValue = nil
    end
end)

interface.callback('videoInput:close', function (data, cb)
    inVideoInput = false
    interface.focus(inVideoInput, inVideoInput)
    cb(true)

    if inputValue then
        inputValue:resolve(false)
        inputValue = nil
    end
end)