fx_version 'cerulean'
game 'gta5'
lua54 'yes'
use_experimental_fxv2_oal 'yes'

author 'RHDWORKS'
description 'RHD Script for FiveM'

ui_page 'html/index.html'

shared_scripts {
    '@ox_lib/init.lua',
    'core.lua'
}

client_scripts {
    -- 'client.lua',
    'dev/rooms.lua',
}


files {
    'html/**/*',
    'config/*.lua',
    'data/*.lua',
    'data/*.sql',
    'dev/*.lua',
    'modules/**/*'
}
