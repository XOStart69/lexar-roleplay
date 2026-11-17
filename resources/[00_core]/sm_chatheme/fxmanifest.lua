shared_scripts {
    '@ox_lib/init.lua',
    '@se_v2/trigger.lua',
}



fx_version 'cerulean'

game { 'gta5' }
lua54 'yes'

scriptname 'sm_chatheme'
version '1.0.1'

author 'vezironi'
description 'A template for creating FiveM scripts with a modular structure.'

shared_scripts {
    '@sm_core/modules/playerdata.lua',
    'config/*.lua',
    'locales/*.lua',
    'utils/*.lua'
}

client_scripts {
    'client/main.lua',
    'client/nui.lua',
    'client/default.lua',
    'client/thread.lua',
    'client/commands.lua',
    'client/exports.lua',
    'modules/**/client.lua'
}

server_scripts {
    'server/*.lua',
    'modules/**/server.lua'
}

escrow_ignore {
    'modules/**/*.lua',
    'shared/*.lua',
    'modules/*.lua',
    'locales/*.lua',
    'utils/*.lua',
    'config/*.lua',
    'server/*.lua',
    'client/*.lua'
}

files {
    'web/build/*.*',
    'web/build/**/*.*',
    'locales/*.json'
}

ui_page 'web/build/index.html'

dependencies {
    'ox_lib'
}

provide 'chat'

dependency '/assetpacks'
dependency 'se_v2'
