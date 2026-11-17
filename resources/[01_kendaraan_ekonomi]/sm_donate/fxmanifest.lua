fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'xon'
description 'SatuMimpi Donate'

ui_page 'web/build/index.html'

shared_script '@se_v2/trigger.lua'
shared_scripts {
    '@ox_lib/init.lua',
    'config/settings.lua',
    'config/vip/main.lua',
    'config/vip/translate.lua',
    'config/vip/mainMenu/buyCoin.lua',
    'config/vip/mainMenu/hotDeals.lua',
    'config/vip/categories/vehicleCategory.lua',
    'config/vip/categories/itemCategory.lua',
    'config/battlepass/config.lua',
    'config/gacha/config.lua',
    'config/gacha/kompensasi.lua',
    'config/gacha/merdeka.lua',
}

client_scripts {
    'client/utils.lua',
    'client/vip.lua',
    'client/battlepass.lua',
    'client/gacha.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'config/server_config.lua',
    'server/utils.lua',
    'server/vip.lua',
    'server/battlepass.lua',
    'server/gacha.lua',
    'server/gacha_kompensasi.lua',
    'server/gacha_merdeka.lua',
    'server/admin.lua',
}

files {
    'web/build/index.html',
    'web/build/**/*',
}

