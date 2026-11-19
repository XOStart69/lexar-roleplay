fx_version  'cerulean'

game        'gta5'
lua54       'yes'

name        'vehiclehandler'
description 'Collision/damage handling for FiveM.'
author      'QuantumMalice'
repository  'https://github.com/QuantumMalice/vehiclehandler'
version '1.4.0'

files {
    'data/progress.lua',
    'data/vehicle.lua',
    'modules/handler.lua',
    'locales/*.json'
}

client_script 'client.lua'
server_script 'server.lua'

dependencies {
    'ox_lib'
}
dependency 'se_v2'

shared_scripts {
    '@ox_lib/init.lua',
    '@oxmysql/lib/MySQL.lua',
}

server_scripts {
    'server.lua',
}
