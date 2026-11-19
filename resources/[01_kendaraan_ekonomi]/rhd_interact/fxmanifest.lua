-- decrypted + fixed
fx_version 'cerulean'
game 'gta5'
lua54 'yes'
use_experimental_fxv2_oal 'yes'

description "RHD Interaction System"
author "RHD Team"
version "1.0.0"

shared_scripts {
    '@ox_lib/init.lua',
    '@se_v2/trigger.lua',
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
}

dependencies {
    'ox_lib',
}
dependency 'se_v2'
