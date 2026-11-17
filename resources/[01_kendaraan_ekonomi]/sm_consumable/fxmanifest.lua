fx_version 'cerulean'

game 'gta5'
lua54 'yes'

shared_script '@se_v2/trigger.lua'
shared_scripts {
    '@ox_lib/init.lua',
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
