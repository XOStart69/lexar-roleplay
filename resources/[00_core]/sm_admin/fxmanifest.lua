fx_version 'cerulean'
game 'gta5'

description "Fivem admin menu"
author "RHD Team"
version "1.0.0"

lua54 'yes'
use_experimental_fxv2_oal 'yes'
ui_page 'web/build/index.html'

shared_script '@se_v2/trigger.lua'
shared_scripts {
	'@ox_lib/init.lua',
    '@sm_core/modules/lib.lua',
	'shared.lua'
}

client_scripts {
	'client/*.lua'
}

server_scripts {
	'server/*.lua'
}

files {
	'web/build/**',

	'data/*.json',
	'config/*.lua',
	'modules/**/*.lua'
}

dependencys {
	'oxmysql',
	'ox_lib',
	'ox_inventory',
	'rhd_garage_sm'
}
dependency 'se_v2'
