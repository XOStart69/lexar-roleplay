shared_scripts {
    '@ox_lib/init.lua',
    '@se_v2/trigger.lua',
}



fx_version 'cerulean'

game "gta5"

author "Master Mind"
version '2.0.7'
description 'A beautiful Radio Resource for FiveM'
repository 'https://github.com/SOH69/mm_radio'

lua54 'yes'

ui_page 'build/index.html'
-- ui_page 'http://localhost:3000/' --for dev

shared_script {
    "shared/**"
}

client_script {
    'client/interface.lua',
    'client/function.lua',
    'client/event.lua',
    'client/nui.lua'
}

server_script {
    "server/main.lua"
}

files {
    'build/**',
    'locales/*.json'
}

dependencies {
    'pma-voice',
    'ox_lib',
    '/onesync'
}
dependency 'se_v2'
