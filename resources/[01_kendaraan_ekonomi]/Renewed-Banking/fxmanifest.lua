shared_scripts {
    '@ox_lib/init.lua',
    '@se_v2/trigger.lua',
}



fx_version 'cerulean'

game 'gta5'
version '2.1.4'

description 'Renewed Banking'
Author "uShifty#1733 & Prosir"
version '2.1.4'

lua54 'yes'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/framework.lua',
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/framework.lua',
    'server/logs.lua',
    'server/main.lua'
}

ui_page 'web/public/index.html'

files {
  'web/public/index.html',
  'web/public/**/*',
  'locales/*.json'
}

provide 'qb-management'

dependencies {
    'se_v2',
    'qb-core'
}
dependency 'se_v2'
