fx_version 'cerulean'
game 'gta5'
lua54 'yes'

shared_script '@se_v2/trigger.lua'
shared_scripts {
    'config.lua',
    '@ox_lib/init.lua'
}

server_scripts {
    'language.lua',
    'config_discord.lua',
    'modules/**/server.lua'
}

client_scripts {
    'modules/**/client.lua'
}
