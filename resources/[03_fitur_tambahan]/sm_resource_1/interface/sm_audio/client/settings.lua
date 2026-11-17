local settingsOptions = {
    {
        title = 'Manage queue',
        description = 'Play now, remove, etc.',
        icon = 'list-ol',
        key = 'useQueue',
        arrow = true,
        serverEvent = 'sm_audio:server:requestQueue',
    },
    {
        title = 'Music history',
        description = 'Music history, favourites.',
        icon = 'timeline',
        key = 'playMusic',
        arrow = true,
        serverEvent = 'sm_audio:server:requestHistory',
    },
    {
        title = 'Filters',
        description = 'Apply filters to output.',
        icon = 'filter',
        key = 'useFilters',
        arrow = true,
        event = 'sm_audio:client:speakerFilters',
    },
    {
        title = 'Connect',
        description = 'Connect speaker to a group.',
        icon = 'fa-brands fa-bluetooth',
        key = 'addGroup',
        skipOnGroup = true,
        onSelect = function(speakerId)
            local input = lib.inputDialog(locale('Connect'), {
                {
                    type = 'input',
                    label = locale('Group code'),
                    description = locale('Connect code of the group you want to connect to.'),
                    icon = 'hashtag',
                    required = true,
                },
            })

            if not input then return end
            TriggerServerEvent('sm_audio:server:addToGroup', speakerId, input)
        end,
    },
    {
        title = 'Disconnect',
        description = 'Disconnect speaker from a group.',
        icon = 'fa-brands fa-bluetooth',
        key = 'addGroup',
        requireGroup = true,
        onSelect = function(speakerId)
            TriggerServerEvent('sm_audio:server:removeFromGroup', speakerId)
        end,
    },
    {
        title = 'Public status',
        description = 'Change public status.',
        icon = 'people-arrows',
        key = 'public',
        serverEvent = 'sm_audio:server:changePublicStatus',
    },
    {
        title = 'Permanent status',
        description = 'Mark speaker as permanent.',
        icon = 'lock',
        key = 'permanent',
        skipWhenPermanent = true,
        serverEvent = 'sm_audio:server:makePermanent',
    },
    {
        title = 'Move speaker',
        description = 'Move permanent location.',
        icon = 'arrows-to-dot',
        key = 'gizmo',
        requirePermanent = true,
        serverEvent = 'sm_audio:server:moveSpeaker',
    },
    {
        title = 'Rename speaker',
        description = 'Current name: %s.',
        icon = 'tag',
        key = 'rename',
        onSelect = function(args)
            local input = lib.inputDialog(locale('Rename speaker'), {
                {
                    type = 'input',
                    label = locale('New name'),
                    icon = 'music',
                    default = args[2],
                    required = true,
                },
            })

            if not input then return end
            TriggerServerEvent('sm_audio:server:renameSpeaker', args[1], input[1])
        end,
    },
}

AddEventHandler('sm_audio:client:speakerSettings', function(data)
    local options = {}
    local count = 0
    local permissions = data.permissions

    for i = 1, #settingsOptions do
        local setting = settingsOptions[i]

        local skip = (setting.skipOnGroup and data.groupId)
            or (setting.requireGroup and not data.groupId)
            or (setting.skipWhenPermanent and data.permanent)
            or (setting.requirePermanent and not data.permanent)

        if not skip then
            local option = {
                title = locale(setting.title),
                icon = setting.icon,
                arrow = setting.arrow,
                event = setting.event,
                serverEvent = setting.serverEvent,
                onSelect = setting.onSelect,
                disabled = not permissions[setting.key] or nil,
            }

            if setting.key == 'rename' then
                option.description = locale(setting.description, data.name)
                option.args = { data.speakerId, data.name }
            elseif setting.key == 'useFilters' then
                option.description = locale(setting.description)
                option.args = data
            else
                option.description = locale(setting.description)
                option.args = data.speakerId
            end

            count = count + 1
            options[count] = option
        end
    end

    lib.registerContext({
        id = 'speaker-settings',
        title = locale('Speaker settings'),
        menu = 'speaker-interact',
        options = options,
    })

    lib.showContext('speaker-settings')
end)

RegisterNetEvent('sm_audio:client:receiveQueue', function(speakerId, list)
    local options = {}

    for i = 1, #(list or {}) do
        local song = list[i]

        options[i] = {
            title = song.title or song.videoId,
            icon = 'music',
            iconColor = '#0066b2',
            arrow = true,
            event = 'sm_audio:client:queueOption',
            args = { speakerId, i },
        }
    end

    lib.registerContext({
        id = 'speaker-queue',
        title = locale('Speaker queue'),
        options = options,
        menu = 'speaker-settings',
    })

    lib.showContext('speaker-queue')
end)

AddEventHandler('sm_audio:client:queueOption', function(args)
    lib.registerContext({
        id = 'speaker-queue-select',
        title = locale('Select action'),
        menu = 'speaker-queue',
        options = {
            {
                title = locale('Play now'),
                icon = 'play',
                iconColor = 'green',
                serverEvent = 'sm_audio:server:playQueuedSong',
                args = args,
            },
            {
                title = locale('Remove from queue'),
                icon = 'trash',
                iconColor = '#8A0707',
                serverEvent = 'sm_audio:server:deleteQueuedSong',
                args = args,
            },
        },
    })

    lib.showContext('speaker-queue-select')
end)

RegisterNetEvent('sm_audio:client:receiveHistory', function(speakerId, history)
    local options = {}

    for i = 1, #(history or {}) do
        local song = history[i]

        options[i] = {
            title = song.title or song.url,
            icon = song.is_favorite == 1 and 'star' or nil,
            iconColor = song.is_favorite == 1 and '#E4D00A' or nil,
            arrow = true,
            event = 'sm_audio:client:historyOption',
            args = { speakerId, song.id, song.is_favorite == 1 },
        }
    end

    lib.registerContext({
        id = 'speaker-history',
        title = locale('Speaker history'),
        options = options,
        menu = 'speaker-settings',
    })

    lib.showContext('speaker-history')
end)

AddEventHandler('sm_audio:client:historyOption', function(args)
    local speakerId, historyId, isFavorite = args[1], args[2], args[3]

    local options = {
        {
            title = locale('Play now'),
            icon = 'play',
            iconColor = 'green',
            serverEvent = 'sm_audio:server:playHistorySong',
            args = { speakerId, historyId },
        },
        {
            title = locale('Add to queue'),
            icon = 'list-ol',
            serverEvent = 'sm_audio:server:queueHistorySong',
            args = { speakerId, historyId },
        },
    }

    if isFavorite then
        options[3] = {
            title = locale('Unfavorite'),
            icon = 'thumbs-down',
            serverEvent = 'sm_audio:server:unfavoriteSong',
            args = { historyId },
        }
    else
        options[3] = {
            title = locale('Favourite'),
            icon = 'thumbs-up',
            serverEvent = 'sm_audio:server:favoriteSong',
            args = { historyId },
        }
    end

    options[4] = {
        title = locale('Delete from history'),
        icon = 'trash',
        iconColor = '#8A0707',
        serverEvent = 'sm_audio:server:deleteHistorySong',
        args = { historyId },
    }

    lib.registerContext({
        id = 'speaker-history-select',
        title = locale('Select action'),
        menu = 'speaker-history',
        options = options,
    })

    lib.showContext('speaker-history-select')
end)
