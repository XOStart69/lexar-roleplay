fx_version 'cerulean'
game 'gta5'
lua54 'yes'
use_experimental_fxv2_oal 'yes'

author 'RHDWORKS'
description 'RHD Script for FiveM'

shared_scripts {
    '@ox_lib/init.lua',
    'module.lua',
}

client_scripts {
    'interface.lua',
    'pelumber/client/main.lua',
    'gardener/client/main.lua',
}

server_scripts {
    'pelumber/server/main.lua',
    'gardener/server/main.lua',
}

ui_page '_nui_wrapper/index.html'

files {
    '_nui_wrapper/**/*',
    'modules/**/*',
    'pelumber/config/**/*',
    'pelumber/data/**/*',
    'pelumber/modules/**/*',
    'pelumber/build/**/*',
    'gardener/config/**/*',
    'gardener/data/**/*',
    'gardener/modules/**/*',
    'gardener/build/**/*',
}

dependencies {
    'ox_lib',
    'ox_target',
    'rhd_interact',
}