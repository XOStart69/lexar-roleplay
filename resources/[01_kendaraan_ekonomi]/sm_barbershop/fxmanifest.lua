fx_version 'cerulean'
game 'gta5'
lua54 'yes'
use_experimental_fxv2_oal 'yes'

author 'RHDWORKS'
description 'Barbershop business with per-location ownership, staff service and self service'

ui_page 'html/index.html'

shared_scripts {
    '@ox_lib/init.lua',
    'core.lua'
}

files {
    'html/**/*',
    'config/*.lua',
    'modules/**/*.lua'
}

dependencies {
    'ox_lib',
    'ox_target',
    'oxmysql',
    'sm_core',
    'sm_appearance'
}
