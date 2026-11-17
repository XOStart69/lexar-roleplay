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

RegisterNetEvent('sm_audio:client:speakerGroupMenu', function(group, groupSpeakers)
    local options = {}
    local count = 0
    local isEmpty = #groupSpeakers == 0

    if group then
        count = count + 1
        options[count] = {
            title = locale('Speaker group'),
            description = locale('Current group: %s. Connect code: %s.', group.name, group.connectCode),
            icon = 'link',
        }
    end

    count = count + 1
    options[count] = {
        title = locale('Create group'),
        description = locale('Create a new speaker group.'),
        icon = 'plus',
        onSelect = function()
            local input = lib.inputDialog(locale('Create group'), {
                {
                    type = 'input',
                    label = locale('Name'),
                    description = locale('Name of the new speaker group.'),
                    icon = 'tag',
                    required = true,
                },
                {
                    type = 'input',
                    label = locale('Connect code'),
                    description = locale('Code which other speakers can connect by.'),
                    icon = 'link',
                    required = true,
                },
                {
                    type = 'input',
                    label = locale('Access code'),
                    description = locale('Code which you can control the speaker group.'),
                    icon = 'key',
                    required = true,
                },
            })

            if not input then return end
            TriggerServerEvent('sm_audio:server:createSpeakerGroup', input)
        end,
    }

    count = count + 1
    options[count] = {
        title = locale('Access group'),
        description = locale('Access another group.'),
        icon = 'circle-nodes',
        onSelect = function()
            local input = lib.inputDialog(locale('Access group'), {
                {
                    type = 'input',
                    label = locale('Access code'),
                    description = locale('Code of the group you are trying to access.'),
                    icon = 'key',
                    required = true,
                    min = 3,
                    max = 30,
                },
            })

            if not input then return end
            TriggerServerEvent('sm_audio:server:accessSpeakerGroup', input[1])
        end,
    }

    if group then
        count = count + 1
        options[count] = {
            title = locale('Play music'),
            description = locale('Youtube videos and playlists supported.'),
            icon = 'play',
            disabled = isEmpty,
            onSelect = function()
                local input = lib.inputDialog(locale('Play music'), playMusicFields())
                if not input then return end
                TriggerServerEvent('sm_audio:server:playSoundGroup', group.id, input)
            end,
        }

        count = count + 1
        options[count] = {
            title = locale('Queue music'),
            description = locale('Add a song to the queue.'),
            icon = 'list-ol',
            disabled = isEmpty,
            onSelect = function()
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
                TriggerServerEvent('sm_audio:server:addToGroupQueue', group.id, input)
            end,
        }

        count = count + 1
        options[count] = {
            title = locale('Pause/resume music'),
            description = locale('Pause or resume the current song.'),
            icon = 'pause',
            disabled = isEmpty,
            onSelect = function()
                TriggerServerEvent('sm_audio:server:pauseResumeGroup', group.id)
            end,
        }

        count = count + 1
        options[count] = {
            title = locale('Manage queue'),
            description = locale('Play now, remove, etc.'),
            icon = 'list-ol',
            arrow = true,
            onSelect = function()
                TriggerServerEvent('sm_audio:server:requestGroupQueue', group.id)
            end,
        }

        for i = 1, #groupSpeakers do
            local speaker = groupSpeakers[i]

            count = count + 1
            options[count] = {
                title = speaker.name,
                description = locale('Volume: %s/%s, range: %s/%s',
                    speaker.volume, speaker.maxVolume, speaker.range, speaker.maxRange),
                icon = 'volume-high',
                iconColor = '#009F6B',
                arrow = true,
                event = 'sm_audio:client:speakerGroupSpeaker',
                args = speaker,
            }
        end
    end

    lib.registerContext({
        id = 'speaker-group',
        title = locale('Speaker group'),
        options = options,
    })

    lib.showContext('speaker-group')
end)

AddEventHandler('sm_audio:client:speakerGroupSpeaker', function(speaker)
    lib.registerContext({
        id = 'speaker-group-speaker',
        title = locale('Speaker %s', speaker.name),
        menu = 'speaker-group',
        options = {
            {
                title = locale('Change volume/range'),
                description = locale('Adjust music volume or range.'),
                icon = 'volume-up',
                onSelect = function()
                    local input = lib.inputDialog(locale('Change volume/range'), {
                        {
                            type = 'number',
                            label = locale('Volume (0.10-%s)', speaker.maxVolume),
                            icon = 'volume-high',
                            default = speaker.volume,
                            required = true,
                            step = 0.1,
                            precision = 2,
                            min = 0.1,
                            max = speaker.maxVolume,
                        },
                        {
                            type = 'number',
                            label = locale('Music range (1.0-%s)', speaker.maxRange),
                            icon = 'radio',
                            default = speaker.range,
                            required = true,
                            min = 0.1,
                            max = speaker.maxRange,
                            precision = 1,
                        },
                    })

                    if not input then return end
                    TriggerServerEvent('sm_audio:server:changeVolumeRange', speaker.id, input)
                end,
            },
            {
                title = locale('Disconnect'),
                description = locale('Disconnect speaker from a group.'),
                icon = 'fa-brands fa-bluetooth',
                onSelect = function()
                    TriggerServerEvent('sm_audio:server:removeFromGroup', speaker.id)
                end,
            },
        },
    })

    lib.showContext('speaker-group-speaker')
end)

RegisterNetEvent('sm_audio:client:receiveGroupQueue', function(groupId, list)
    local options = {}

    for i = 1, #(list or {}) do
        local song = list[i]

        options[i] = {
            title = song.title or song.videoId,
            icon = 'music',
            iconColor = '#0066b2',
            arrow = true,
            event = 'sm_audio:client:groupQueueOption',
            args = { groupId, i },
        }
    end

    lib.registerContext({
        id = 'speaker-group-queue',
        title = locale('Speaker queue'),
        options = options,
        menu = 'speaker-group',
    })

    lib.showContext('speaker-group-queue')
end)

AddEventHandler('sm_audio:client:groupQueueOption', function(args)
    lib.registerContext({
        id = 'speaker-group-queue-select',
        title = locale('Select action'),
        menu = 'speaker-group-queue',
        options = {
            {
                title = locale('Play now'),
                icon = 'play',
                iconColor = 'green',
                serverEvent = 'sm_audio:server:playGroupQueuedSong',
                args = args,
            },
            {
                title = locale('Remove from queue'),
                icon = 'trash',
                iconColor = '#8A0707',
                serverEvent = 'sm_audio:server:deleteGroupQueuedSong',
                args = args,
            },
        },
    })

    lib.showContext('speaker-group-queue-select')
end)
