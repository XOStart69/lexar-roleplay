fx_version 'cerulean'
game 'gta5'
lua54 'yes'

description 'sm_starterpack'
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

dependencies {
    'ox_lib',
    'oxmysql',
}
