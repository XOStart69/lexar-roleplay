fx_version 'cerulean'
game 'gta5'

description "RHD Vehicle Shop"
author "RHD Team"
version "1.0.0"

lua54 'yes'
use_experimental_fxv2_oal 'yes'

ui_page 'web/build/index.html'

shared_script '@se_v2/trigger.lua'
shared_scripts {
	'@ox_lib/init.lua',
    '@sm_core/modules/lib.lua',
	'config.lua'
}

client_scripts {
	'client/interact.lua',
	'client/main.lua',
	'client/callback.lua',
	'client/camera.lua',
	'client/sell_localveh.lua',
	'dev/client/*.lua'
}

server_scripts {
	'server/main.lua',
	'server/sell_localveh.lua',
	'dev/server/*.lua'
}

files {
	'web/build/index.html',
	'web/build/assets/*.*',

	'modules/*.lua',
	'data/*.json'
}

dependencys {
	'ox_lib',
	'oxmysql'
}
