return {
    settings = {
        title = {
            text = 'Satu Mimpi',
            -- Set to a URL for a custom logo, or false to use the bundled logosm.png
            logo = false,
        },

        side = 'right',

        showOverlay = false,

        closeOnEscape = true,

        closeOnOutsideClick = true,

        uppercaseNames = false,

        highlightEmptyGroups = true,

        compactPlayers = true,

        compactGroups = true,

        playerColumns = 1,

        groupColumns = 1,
    },

    -- UI text strings sent to the NUI
    locales = {
        groups = 'Jumlah Instansi',
        players = 'Jumlah Warga',
        copy_server_id = 'Copy your server ID',
        server_id_copied = 'Server ID copied',
        anonymous_player = 'Anonymous',
    },

    visibleSections = {
        groups = true,
        groupCount = true,
        players = false,
        playerNames = false,
        playerIds = false,
        statusIndicators = true,
        footer = false,
    },

    -- Command name for opening the scoreboard
    commandName = 'scoreboard',

    -- Default keybind for the '/scoreboard' command
    commandKey = 'F5',

    -- Whether to include off-duty players in group count (if not defined in the group row itself)
    includeOffDuty = false,

    -- Group list shown in the scoreboard
    groups = {
        {
            label = 'Pemerintah',
            groups = {'government'},
        },
        {
            label = 'Department Of Justice | US Marshal',
            groups = {'pengadilan','usmarshal'},
        },
        {
            label = 'Police',
            groups = {'police', 'sheriff'},
            -- includeOffDuty = false,
            maxCount = 8,
        },
        {
            label = 'EMS',
            groups = {'ambulance', 'banmeskota'},
            -- includeOffDuty = false,
            -- maxCount = 5,
        },
        {
            label = '969 Garages',
            groups = {'mechanic969'},
        },
        {
            label = 'Tekno Garages',
            groups = {'lsc', 'mechanic', 'hayes'},
            -- -- includeOffDuty = true,
            -- icon = 'mdi:wrench',
            -- maxCount = 3,
        },
        {
            label = 'Max Speed Garages',
            groups = {'maxspeedgarage'},
        },
        {
            label = 'Stunberg Garages',
            groups = {'stunberg'},
        },
        -- {
        --     label = 'Ananta Garage',
        --     groups = {'mechanicbay'},
        -- },
        {
            label = 'RS Roxwood',
            groups = {'rsroxwood'},
        },
        {
            label = 'Max Health Care',
            groups = {'puskesmas'},
        },
        {
            label = '969 Resto',
            groups = {'burgenkcafe'},
        },
        {
            label = 'Up-n Atom Burger',
            groups = {'pdcafe'},
        },
        {
            label = 'KungKungKap Resto',
            groups = {'kkpresto'},
        },
        {
            label = 'KungKungKap Garage',
            groups = {'kkpgarage'},
        },
        {
            label = 'Nusantara Resto',
            groups = {'resto'},
        },
        {
            label = 'SMGO',
            groups = {'taxism'},
        },
        {
            label = 'Satu Media',
            groups = {'reporter'},
        },
        {
            label = 'Avenue Royale Hotel',
            groups = {'smmotel'},
        },
        {
            label = 'Satu Music Records',
            groups = {'musicsm'},
        },
        {
            label = 'YGM Center DigitalDen',
            groups = {'digitalden'},
        },
        {
            label = 'DigitalDen Roxwood',
            groups = {'digitaldenroxwood'},
        },
        {
            label = 'MaisonRainhart Cafe',
            groups = {'mhcafe'},
        },
        {
            label = 'ECL Kedai',
            groups = {'gzcafe'},
        },
        {
            label = 'Wartel',
            groups = {'wartelsm'},
        },
        {
            label = 'Max Club',
            groups = {'nightclub'},
        },
        {
            label = 'ECLUB',
            groups = {'luxurynightclub'},
        },
        {
            label = 'Velvet Casino',
            groups = {'velvetsm'},
        },

    },

    statusIndicators = {
        {
            id = 'atm_robbery',
            label = 'Atm robbery',
            icon = 'mdi:atm',
            defaultState = false,
            groupTrigger = {
                groups = {'police', 'sheriff'},
                minimumCount = 4,
                includeOffDuty = false,
            },
        },
        {
            id = 'store_robbery',
            label = 'Store robbery',
            icon = 'mdi:store',
            defaultState = false,
            groupTrigger = {
                groups = {'police', 'sheriff'},
                minimumCount = 5,
                includeOffDuty = false,
            },
        },
        {
            id = 'vehicle_robbery',
            label = 'Vehicle robbery',
            icon = 'mdi:car',
            defaultState = false,
            groupTrigger = {
                groups = {'police', 'sheriff'},
                minimumCount = 3,
                includeOffDuty = false,
            },
        },
        {
            id = 'house_robbery',
            label = 'House robbery',
            icon = 'mdi:house',
            defaultState = false,
            groupTrigger = {
                groups = {'police', 'sheriff'},
                minimumCount = 3,
                includeOffDuty = false,
            },
        },
        {
            id = 'gruppe_robbery',
            label = 'Gruppe robbery',
            icon = 'mdi:truck',
            defaultState = false,
            groupTrigger = {
                groups = {'police', 'sheriff'},
                minimumCount = 4,
                includeOffDuty = false,
            },
        },
        {
            id = 'jewelry_robbery',
            label = 'Jewelry robbery',
            icon = 'mdi:Jewelry',
            defaultState = false,
            groupTrigger = {
                groups = {'police', 'sheriff'},
                minimumCount = 7,
                includeOffDuty = false,
            },
        },
        {
            id = 'bank_robbery',
            label = 'Fleeca Bank robbery',
            icon = 'mdi:bank',
            groupTrigger = {
                groups = {'police', 'sheriff'},
                minimumCount = 7,
                includeOffDuty = false,
            },
        },
    },
}
