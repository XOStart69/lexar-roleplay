fx_version 'cerulean'
game 'gta5'
lua54 'yes'
use_fxv2_oal 'yes'

author 'Axon'
description 'Rental Stash System'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    '@se_v2/trigger.lua',
    'configs/main.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

dependency 'se_v2'
