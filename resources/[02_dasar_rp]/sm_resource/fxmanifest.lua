-- decrypted + fixed
fx_version 'cerulean'
game 'gta5'

name "sm_resource_pack"
description "Resource Pack"
author "RHD Team"
version "1.0.0"

lua54 'yes'
use_experimental_fxv2_oal 'yes'
ui_page 'interface/wrapper/index.html'

shared_script '@se_v2/trigger.lua'
shared_scripts {
	'@ox_lib/init.lua',
	'localmodule.lua',
	'@sm_core/modules/playerdata.lua',
	'@sm_core/modules/lib.lua',
	'shared.lua',
	'resource/**/shared.lua',
	'resource/**/shared/*.lua',
	'interface/**/shared.lua'
}

client_scripts {
	'interface/core.lua',
	'interface/**/client.lua',
	'interface/**/client/*.lua',

	'resource/**/client.lua',
	'resource/**/client/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
	'interface/**/server.lua',
	'interface/**/server/**/*.lua',

	'resource/**/server.lua',
	'resource/**/server/*.lua',
}

files {
	'interface/wrapper/**/*',
	'interface/**/web/build/**/*',
	'interface/**/dist/**/*',
	'interface/**/build/**/*',

	'interface/**/utils/*.lua',
	'interface/**/config/*.lua',
	'interface/**/config.lua',
	'interface/**/data/*.lua',
	'interface/**/data/*.json',
	'interface/**/template/*.lua',
	'interface/**/modules/*.lua',
	'interface/**/line_navigator/*.lua',

	'resource/**/config/*.lua',
	'resource/**/config.lua',
	'resource/**/utils/*.lua',
	'resource/**/modules/*.lua',
	'resource/**/data/*.lua',

	'modules/**/*',
	'export_wrapper.lua',
}

dependencies {
    '/server:7290',
    '/onesync',

	'ox_lib',
	'ox_target',
	'ox_inventory',
	'oxmysql'
}

provides {
	'qb-core',
	'qb-management',
	'LegacyFuel'
}

dependency 'se_v2'
