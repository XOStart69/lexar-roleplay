fx_version 'cerulean'
game 'gta5'
lua54 'yes'

description 'sm_notepad'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    '@oxmysql/lib/MySQL.lua',
    'config.lua',
}

client_scripts {
    'client.lua',
}

server_scripts {
    'server.lua',
}

ui_page 'web/build/index.html'

files {
    'web/build/**',
}

dependencies {
    'ox_lib',
    'oxmysql',
}
