local ClientUtil = localmodule 'modules/clientutil'

---@param maxVolume number
---@param maxRange number
---@param volume number
---@param range number
---@return table[]
local function volumeRangeFields(maxVolume, maxRange, volume, range)
    return {
        {
            type = 'number',
            label = locale('Volume (0.10-%s)', maxVolume),
            icon = 'volume-high',
            default = volume,
            step = 0.1,
            precision = 2,
            min = 0.1,
            max = maxVolume,
            required = true,
        },
        {
            type = 'number',
            label = locale('Music range (1.0-%s)', maxRange),
            icon = 'radio',
            default = range,
            min = 0.1,
            max = maxRange,
            precision = 1,
            required = true,
        },
    }
end

---@return table[]
local function playMusicFields()
    return {
        {
            type = 'input',
            label = locale('Youtube URL'),
            description = locale('Youtube videos and playlists supported.'),
            required = true,
            icon = 'music',
            min = 30,
            max = 130,
        },
        {
            type = 'number',
            label = locale('Timestamp'),
            description = locale('Skip time in seconds. URL overrides this.'),
            required = true,
            icon = 'clock',
            default = 0,
            min = 0,
            max = 1000,
        },
    }
end

local interactOptions = {
    {
        title = 'Play music',
        description = 'Youtube videos and playlists supported.',
        icon = 'play',
        key = 'playMusic',
        disableOnGroup = true,
        onSelect = function(args)
            local input = lib.inputDialog(locale('Play music'), playMusicFields())
            if not input then return end
            TriggerServerEvent('sm_audio:server:playMusic', args.speakerId, input)
        end,
    },
    {
        title = 'Queue music',
        description = 'Add a song to the queue.',
        icon = 'list-ol',
        key = 'useQueue',
        disableOnGroup = true,
        onSelect = function(args)
            local input = lib.inputDialog(locale('Queue music'), {
                {
                    type = 'input',
                    label = locale('Youtube URL'),
                    description = locale('Youtube videos and playlists supported.'),
                    required = true,
                    icon = 'music',
                    min = 30,
                    max = 130,
                },
            })
            if not input then return end
            TriggerServerEvent('sm_audio:server:addToQueue', args.speakerId, input)
        end,
    },
    {
        title = 'Next song',
        description = 'Play the next song in the queue.',
        icon = 'forward',
        key = 'useQueue',
        disableOnGroup = true,
        onSelect = function(args)
            TriggerServerEvent('sm_audio:server:nextQueuedSong', args.speakerId)
        end,
    },
    {
        title = 'Pause/resume music',
        description = 'Pause or resume the current song.',
        icon = 'pause',
        key = 'pauseResume',
        disableOnGroup = true,
        onSelect = function(args)
            TriggerServerEvent('sm_audio:server:pauseResume', args.speakerId)
        end,
    },
    {
        title = 'Change volume/range',
        description = 'Adjust music volume or range.',
        icon = 'volume-up',
        key = 'volumeRange',
        onSelect = function(args)
            local input = lib.inputDialog(locale('Change volume/range'),
                volumeRangeFields(args.maxVolume, args.maxRange, args.volume, args.range))
            if not input then return end
            TriggerServerEvent('sm_audio:server:changeVolumeRange', args.speakerId, input)
        end,
    },
    {
        title = 'Hold speaker',
        description = 'Carry the speaker around.',
        icon = 'hand-paper',
        key = 'carry',
        onSelect = function(args)
            TriggerServerEvent('sm_audio:server:carrySpeaker', args.speakerId)
        end,
    },
    {
        title = 'Store speaker',
        description = 'Stash the speaker away.',
        icon = 'box',
        key = 'store',
        disableOnGroup = true,
        onSelect = function(args)
            TriggerServerEvent('sm_audio:server:removeSpeaker', args.speakerId)
        end,
    },
    {
        title = 'Other',
        description = 'Manage queue, history, other.',
        icon = 'cog',
        key = 'settings',
        event = 'sm_audio:client:speakerSettings',
    },
}

---@param speakerId string
function InteractSpeaker(speakerId)
    local allowed, data = lib.callback.await('sm_audio:server:getInteractionData', false, speakerId)

    if not allowed then
        ClientUtil.notify(locale("You don't have the necessary permissions."), 'error')
        return
    end

    local options = {}
    local count = 0
    local permissions = data.permissions

    for i = 1, #interactOptions do
        local option = interactOptions[i]

        if permissions[option.key] then
            local args = {
                speakerId = speakerId,
                volume = data.volume,
                range = data.range,
                maxRange = data.maxRange,
                maxVolume = data.maxVolume,
                permanent = data.permanent,
                public = data.public,
                name = data.name,
                groupId = data.groupId,
            }

            if option.key == 'settings' then
                args.filters = data.filters
                args.permissions = permissions
                args.allowedFilters = data.allowedFilters
            end

            count = count + 1
            options[count] = {
                title = locale(option.title),
                description = locale(option.description),
                icon = option.icon,
                args = args,
                event = option.event,
                onSelect = option.onSelect,
                disabled = option.disableOnGroup and data.groupId ~= nil or nil,
            }
        end
    end

    lib.registerContext({
        id = 'speaker-interact',
        title = locale('Speaker interaction'),
        options = options,
    })

    lib.showContext('speaker-interact')
end

---@param speakerId string
---@param action string
function InteractSpeakerTarget(speakerId, action)
    if IsPedInAnyVehicle(cache.ped, true) or IsPedGettingIntoAVehicle(cache.ped) then
        ClientUtil.notify(locale("This can't be done while inside a vehicle."), 'error')
        return
    end

    if not ClientUtil.interactionCheck() then return end

    local allowed, data = lib.callback.await('sm_audio:server:getInteractionData', false, speakerId)

    if not allowed then
        ClientUtil.notify(locale("You don't have the necessary permissions."), 'error')
        return
    end

    if not data.permissions[action] then
        ClientUtil.notify(locale('This action is not supported on this type of speaker.'), 'error')
        return
    end

    if action == 'playMusic' then
        local input = lib.inputDialog(locale('Play music'), playMusicFields())
        if not input then return end
        TriggerServerEvent('sm_audio:server:playMusic', speakerId, input)
    elseif action == 'volumeRange' then
        local input = lib.inputDialog(locale('Change volume/range'),
            volumeRangeFields(data.maxVolume, data.maxRange, data.volume, data.range))
        if not input then return end
        TriggerServerEvent('sm_audio:server:changeVolumeRange', speakerId, input)
    elseif action == 'carry' then
        TriggerServerEvent('sm_audio:server:carrySpeaker', speakerId)
    elseif action == 'store' then
        TriggerServerEvent('sm_audio:server:removeSpeaker', speakerId)
    elseif action == 'addGroup' then
        local input = lib.inputDialog(locale('Connect'), {
            {
                type = 'input',
                label = locale('Group code'),
                description = locale('Connect code of the group you want to connect to.'),
                icon = 'hashtag',
            },
        })
        if not input then return end
        TriggerServerEvent('sm_audio:server:addToGroup', speakerId, input)
    end
end

RegisterNetEvent('sm_audio:client:notify', function(message, kind)
    ClientUtil.notify(message, kind)
end)

lib.callback.register('sm_audio:client:getSafetyPreference', function(options, active)
    return lib.inputDialog(locale('Streamer mode'), {
        {
            type = 'select',
            label = locale('Streamer mode'),
            description = locale('Applies to speakers, cafe/club music and televisions.'),
            options = options,
            default = active,
            required = true,
        },
    })
end)
