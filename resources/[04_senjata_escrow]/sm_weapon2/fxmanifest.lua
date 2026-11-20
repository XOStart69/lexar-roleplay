-- decrypted + fixed

fx_version 'cerulean'
game 'gta5'
games {'gta5'}
lua54 "yes"
description 'Add-on Melee weapons V2'


author 'Polar The Plug'
description 'Made By Polar | https://discord.gg/PjNgP4tAv9'
version '1.0'

files{
	'**/weaponcomponents.meta',
	'**/weaponarchetypes.meta',
	'**/weaponanimations.meta',
	'**/pedpersonality.meta',
	'**/weapons.meta',
}

data_file 'WEAPONCOMPONENTSINFO_FILE' '**/weaponcomponents.meta'
data_file 'WEAPON_METADATA_FILE' '**/weaponarchetypes.meta'
data_file 'WEAPON_ANIMATIONS_FILE' '**/weaponanimations.meta'
data_file 'PED_PERSONALITY_FILE' '**/pedpersonality.meta'
data_file 'WEAPONINFO_FILE' '**/weapons.meta'

-- client_script 'cl_weaponNames.lua'

-- escrow_ignore {
--     "cl_weaponNames",
-- }
