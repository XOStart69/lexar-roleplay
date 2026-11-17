fx_version 'cerulean'

game 'gta5'
lua54 'yes'
author 'RHD Team'
description 'Core resource for the framework, contains all the core functionality and features'
version '1.3.0'

shared_script '@se_v2/trigger.lua'

shared_scripts {
    '@ox_lib/init.lua',
    'modules/lib.lua',
    'config.lua',
    'shared/locale.lua',
    'locale/en.lua',
    'locale/*.lua',
    'shared/main.lua',
    'shared/items.lua',
    'shared/jobs.lua',
    'shared/vehicles.lua',
    'shared/gangs.lua',
    'shared/weapons.lua',
    'shared/locations.lua',
    'shared.lua',
}

client_scripts {
    'client/loops.lua',
    'client/events.lua',
    'client/drawtext.lua',
}

server_scripts {
    'server/player/identifier.lua',
    'server/player/main.lua',
    'server/player/method.lua',

    'server/events.lua',
    'server/commands.lua',
    'server/connecting.lua',
    'server/loops.lua',
    'server/debug.lua'
}


files {
    'lib/**/*.lua',
    'modules/**/*',
    'export-functions.lua'
}

provide 'qb-core'

dependency 'oxmysql'
