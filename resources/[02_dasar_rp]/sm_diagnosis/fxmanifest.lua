fx_version 'cerulean'
game 'gta5'
version '1.0.0'
description 'RHD Body Damage System'

ui_page 'html/index.html'

shared_scripts {
	'@ox_lib/init.lua'
}

client_scripts {
	'client/main.lua',
}

server_scripts {
	'server/main.lua',
}

files {
	'html/**/*',

	'config/*.lua',
	'data/*.lua',
	'modules/*.lua',
	'bridge/**/*.lua',
}