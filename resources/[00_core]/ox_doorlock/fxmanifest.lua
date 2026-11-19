fx_version 'cerulean'
game 'gta5'
lua54 'yes'
use_experimental_fxv2_oal 'yes'

name 'ox_doorlock'
version '1.14.4'
license 'GPL-3.0-or-later'
author 'Overextended'

ui_page 'web/build/index.html'

shared_scripts {
    '@ox_lib/init.lua',
    '@se_v2/trigger.lua',
    'config.lua',
}

client_scripts {
    'client/main.lua',
    'client/utils.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/framework/*.lua',
    'server/convert.lua',
    'server/main.lua',
}

files {
    'web/build/index.html',
    'web/build/**/*',
    'locales/*.json',
    'audio/data/oxdoorlock_sounds.dat54.rel',
    'audio/dlc_oxdoorlock/oxdoorlock.awc',
}

data_file 'AUDIO_WAVEPACK' 'audio/dlc_oxdoorlock'
data_file 'AUDIO_SOUNDDATA' 'audio/data/oxdoorlock_sounds.dat'

dependencies {
    'oxmysql',
    'ox_lib',
}
dependency 'se_v2'
