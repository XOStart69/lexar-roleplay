fx_version 'cerulean'
game 'gta5'


description "RHD Interaction System"
author "RHD Team"

version "1.0.0"
use_experimental_fxv2_oal 'yes'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
}

client_script {
    'utils/main.lua',
    'framework/init.lua',
    'core/entities.lua',
    'core/manager.lua',
    'core/dui.lua',
    'dev/command.lua',
}
server_script 'server.lua'

files {
    'web/build/assets/*.*',
    'web/build/**/*.*',

    'utils/main.lua',
    'framework/init.lua',
    'framework/**/*.lua',
    'config/*.lua',

    'data/*.json',
}

escrow_ignore {
    'framework/**',
    'config/*.lua',
    'types.lua'
}

dependencys {
    'ox_lib',
}

dependency '/assetpacks'