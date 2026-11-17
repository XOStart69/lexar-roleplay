shared_scripts {
    '@ox_lib/init.lua',
    '@se_v2/trigger.lua',
}



fx_version 'cerulean'

lua54 'yes'
games { 'gta5' }

client_scripts {
    'client/**.lua'
}

server_scripts {
    'server/**.lua'
}

shared_scripts {
    'config.lua'
}
dependency 'se_v2'
