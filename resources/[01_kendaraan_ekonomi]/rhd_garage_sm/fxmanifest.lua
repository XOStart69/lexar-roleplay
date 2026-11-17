shared_scripts {
    '@ox_lib/init.lua',
    '@se_v2/trigger.lua',
}



fx_version 'cerulean'
game 'gta5'
lua54 'yes'
use_experimental_fxv2_oal  'yes'

author 'RHDWORKS'
description 'RHD Garage for Satu Mimpi RP'

ui_page 'web/build/index.html'

shared_scripts {
    '@sm_core/modules/playerdata.lua',
    '@sm_core/modules/lib.lua',
    'shared.lua'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    'server/*.lua'
}

files {
    'web/build/**/*',

    'modules/*.lua',
    'config/*.lua',
    'data/*.lua'
}

dependencys {
    'ox_lib',
    'sm_core',
    'sm_resource',
    'se_v2'
}

provide 'sm_garage'
dependency 'se_v2'
