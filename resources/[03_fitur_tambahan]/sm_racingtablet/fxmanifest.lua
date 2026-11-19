shared_scripts {
    '@ox_lib/init.lua',
    '@se_v2/trigger.lua',
}



-- Resource Metadata
fx_version 'cerulean'
games { 'gta5' }

author 'Coffeelot & Wuggie'
description 'CW Racing App'
version '5.1.4'

ui_page {
    "web/dist/index.html"
}

shared_scripts {
    'locales/*.lua',
    'shared/config.lua',
    'shared/drift.lua',
    'shared/elo.lua',
    'shared/head2head.lua',
    -- '@qbx_core/modules/playerdata.lua', -- remove this if you don't use qbox
}

client_scripts {
    'bridge/client/*.lua',
    'client/classes.lua',
    'client/globals.lua',
    'client/functions.lua',
    'client/main.lua',
    'client/gui.lua',
    'client/head2head.lua',
    'client/drift.lua',
    'client/racebucket.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/debug.lua',
    'server/database.lua',
    'server/databaseTimes.lua',
    'server/functions.lua',
    'bridge/server/*.lua',
    'server/bounties.lua',
    'server/tracks.lua',
    'server/main.lua',
    'server/crypto.lua',
    'server/crews.lua',
    'server/racers.lua',
    'server/head2head.lua',
    'server/admin.lua',
    'server/elo.lua',
    'server/drift.lua',
    'server/racebucket.lua'
}

files {
    "web/dist/index.html",
    "web/dist/assets/*.*"
}

lua54 'yes'
dependency 'se_v2'
