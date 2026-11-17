fx_version 'cerulean'
game 'gta5'
lua54 'yes'
use_experimental_fxv2_oal  'yes'

author 'RHD Team'
description 'Casino script for FiveM'

ui_page 'html/index.html'

dependency 'oxmysql'

shared_script '@se_v2/trigger.lua'

shared_scripts {
    '@ox_lib/init.lua',
    '@sm_core/modules/playerdata.lua',
    'shared.lua'
}

client_scripts {
    'addon/client/**/*'
}

server_scripts {
    'addon/server/**/*'
}

files {
    'html/**',
    'dui/html/**',
    'leaderboards/**/*',
    'modules/**/*',
    'casino/**/*',
    'addon/config/**/*',
}
dependency 'se_v2'
