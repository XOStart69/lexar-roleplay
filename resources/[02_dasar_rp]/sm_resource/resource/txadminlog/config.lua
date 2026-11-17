return {
    -- [ Basic Webhook Settings ]
    webhook = {
        url = '',
        username = 'SMLogs',
        avatar = 'https://media.discordapp.net/attachments/1218808338956161062/1412428693174882496/Satu_Mimpi_Logo.png?ex=696cdfba&is=696b8e3a&hm=1c2bec8f49ab499ba7ef0a85fd8728a47778958a5998f237762ae8ef66477c93&=&format=webp&quality=lossless&width=1050&height=1050'
    },

    -- [ Join/Leave Webhook Settings ]
    joinleave_webhook = {
        enabled = true, -- Set false untuk disable log join/leave
        url = '',
        username = 'SMLogs',
        avatar = 'https://media.discordapp.net/attachments/1218808338956161062/1412428693174882496/Satu_Mimpi_Logo.png?ex=696cdfba&is=696b8e3a&hm=1c2bec8f49ab499ba7ef0a85fd8728a47778958a5998f237762ae8ef66477c93&=&format=webp&quality=lossless&width=1050&height=1050'
    },

    -- [ Color Settings ]
    colors = {
        warn = 16744192,
        kick = 65535,
        ban = 16711680,
        heal = 65280,
        announcement = 8421504,
        restart = 16776960,
        dm = 13938487,
        revoked = 255,
        whitelist = 255,
        join = 5763719,  -- Warna hijau untuk join
        leave = 15158332 -- Warna merah untuk leave
    },

    -- [ Locale Settings ]
    locale = {
        -- Webhook Titles
        restarting_now = "Server is restarting NOW!",
        restarting = "Server Restarting Soon",
        dm = "Direct Message",
        revoked = "Action Revoked",
        kicked = "Player Kicked",
        warned = "Player Warned",
        banned = "Player Banned",
        heal = "Admin Heal",
        announcement = "Server Announcement",
        whitelist = "Whitelist Updated",
        joined = "Player Joined",
        left = "Player Left",

        -- Fields
        permanent = "PERMANENT",
        minutes_remaining = "Minutes Remaining",
        admin_name = "Admin Name",
        revoked_by = "Revoked By",
        target = "Target Player",
        reason = "Reason",
        ids = "Target Identifiers",
        expiration = "Ban Expiration",
        ban_id = "Ban ID",
        announcer = "Announcer",
        message = "Message",
        type = "Action Type",
        license = "Player License",
        player_name = "Player Name",
        player_id = "Player ID",
        identifiers = "Identifiers",

        -- Other
        not_found = "Not Found",
        ban = "Ban",
        warn = "Warning"
    }
}