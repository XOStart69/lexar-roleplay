fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'rhd_playergroup'
author 'RHD'
version '2.0.0'
description 'Player group system with lb-phone app, group chat and backend mission objectives'

shared_scripts {
    '@ox_lib/init.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    'server/main.lua',
}

ui_page 'html/index.html'

files {
    'html/**/*',
    'config/shared.lua',
    'config/client.lua',
    'config/server.lua',
    'modules/net.lua',
    'modules/groups.lua',
    'bridge/init.lua',
    'bridge/**/*.lua',
}

dependencies {
    'ox_lib',
    'lb-phone',
}
