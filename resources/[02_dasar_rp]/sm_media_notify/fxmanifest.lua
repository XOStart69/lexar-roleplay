fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'sm_media_notify'
description 'Notifikasi pembaruan Satu Media untuk in-game'
version '1.0.0'

shared_script '@ox_lib/init.lua'

client_scripts {
    'client/main.lua',
}

server_scripts {
    'server/main.lua',
}

files {
    'modules/*.lua',
}
