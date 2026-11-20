fx_version 'cerulean'
game 'gta5'
lua54 'yes'
use_experimental_fxv2_oal 'yes'

description "RHD Vehicle Shop"
author "RHD Team"
version "1.0.0"

ui_page 'web/build/index.html'

shared_scripts {
    '@ox_lib/init.lua',
    '@oxmysql/lib/MySQL.lua',
    '@se_v2/trigger.lua',
    '@sm_core/modules/lib.lua',
    'config.lua',
}

client_scripts {
    'client/interact.lua',
    'client/main.lua',
    'client/callback.lua',
    'client/camera.lua',
    'client/sell_localveh.lua',
    'dev/client/*.lua',
}

server_scripts {
    'server.lua',
    'server/main.lua',
    'server/sell_localveh.lua',
    'dev/server/*.lua',
}

files {
    'web/build/index.html',
    'web/build/assets/*.*',
    'modules/*.lua',
    'data/*.json',
}

dependencies {
    'ox_lib',
    'oxmysql',
}
dependency 'se_v2'
