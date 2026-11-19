fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'sm_megaphones'
author 'pen'
description 'A simple free megaphone resource for FiveM'
version '1.0.5'

shared_scripts {
    '@ox_lib/init.lua',
    '@se_v2/trigger.lua',
    'shared/config.lua',
}

client_scripts {
    'client/framework.lua',
    'client/functions.lua',
    'client/megaphone.lua',
    'client/microphones.lua',
}

server_scripts {
    'server/framework.lua',
    'server/main.lua',
}

dependencies {
    'ox_lib',
    'ox_target',
    'pma-voice',
}
dependency 'se_v2'
