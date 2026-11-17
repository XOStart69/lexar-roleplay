fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'sm_pdtablet'
description 'Police pursuit training tablet'
version '1.0.0'

shared_scripts {
    '@se_v2/trigger.lua',
    '@ox_lib/init.lua',
    'shared/config.lua',
}

client_scripts {
    'client/creator.lua',
    'client/race.lua',
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/database.lua',
    'server/main.lua',
}

ui_page 'web/build/index.html'

files {
    'web/build/index.html',
    'web/build/assets/*.js',
    'web/build/assets/*.css',
    'web/build/*.png',
}
dependency 'se_v2'
