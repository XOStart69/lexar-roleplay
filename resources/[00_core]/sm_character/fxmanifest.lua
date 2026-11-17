fx_version 'cerulean'
game 'gta5'

name 'sm_characters'
description 'Character selection & spawn'
author 'RHD Team'
version '2.0.0'

lua54 'yes'
use_experimental_fxv2_oal 'yes'

ui_page 'web/build/index.html'

shared_script '@se_v2/trigger.lua'
shared_script '@ox_lib/init.lua'

client_script 'client/init.lua'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/init.lua'
}

files {
    'web/build/**',
    'client/*.lua',
    'modules/net.lua',
    'modules/client/*.lua',
    'config/client.lua',
    'config/register.lua',
    'data/default.lua',
    'meta/peds.meta'
}

data_file 'PED_METADATA_FILE' 'meta/peds.meta'

dependencies {
    '/server:7290',
    '/onesync',
    'oxmysql',
    'ox_lib',
    'sm_core',
    'sm_appearance'
}

