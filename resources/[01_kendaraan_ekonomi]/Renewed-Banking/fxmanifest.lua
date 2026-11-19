fx_version 'cerulean'
game 'gta5'
lua54 'yes'

description 'Renewed Banking'
author 'uShifty#1733 & Prosir'
version '2.1.4'

ui_page 'web/public/index.html'

shared_scripts {
    '@ox_lib/init.lua',
    '@se_v2/trigger.lua',
    'config.lua',
}

client_scripts {
    'client/framework.lua',
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/framework.lua',
    'server/logs.lua',
    'server/main.lua',
}

files {
    'web/public/index.html',
    'web/public/**/*',
    'locales/*.json',
}

provide 'qb-management'

dependencies {
    'se_v2',
    'qb-core',
}
dependency 'se_v2'
