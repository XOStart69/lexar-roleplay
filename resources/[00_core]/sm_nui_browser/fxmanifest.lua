fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'sm_nui_browser'
description 'In-game browser wrapper untuk NUI FiveM'
version '1.0.0'

ui_page 'html/index.html'

shared_script '@ox_lib/init.lua'

client_scripts {
    'client/main.lua',
}

server_scripts {
    'server/main.lua',
    'server/items.lua',
}

files {
    'html/index.html',
    'html/script.js',
    'html/styles.css',
    'html/fonts/**/*',
}
