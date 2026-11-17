shared_scripts {
    '@ox_lib/init.lua',
    '@se_v2/trigger.lua',
}



fx_version 'cerulean'

game 'gta5'
lua54 'yes'

shared_scripts {
    'anim.lua'
}

client_scripts {
    'client/*.lua'
} 

server_scripts {
    'server/*.lua'
}

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'consumable/*.lua'
}
dependency 'se_v2'
