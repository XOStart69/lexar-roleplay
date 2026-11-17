fx_version 'cerulean'
game 'gta5'

name "se"
description "Safe Event FiveM"
author "RHD Team"
version "2.0.0"

lua54 'yes'
use_experimental_fxv2_oal 'yes'

shared_scripts {
	'shared/core.lua',
	-- 'shared/palepale.lua',
}

server_script 'server/ban.lua'

--- Load configuration convars
--- Add "exec @rhd_se_xxx/se.cfg" to your server.cfg

--- Enable this if you want to perform the installation
-- server_script 'installer/main.js'

escrow_ignore {
	'shared/core.lua',
	-- 'shared/palepale.lua',
	'server/ban.lua',
}

files {
	'trigger.lua'
}

dependency '/assetpacks'