fx_version 'cerulean'
game 'gta5'

author 'ZSTATIONTUNING'
description 'SM SCRIPT VEHICLE'
version '1.0.0'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client.lua',
    'vehicle_names.lua'
}

files {
    'data/**/*.meta'
}

data_file 'VEHICLE_LAYOUTS_FILE' 'data/**/vehiclelayouts.meta'
data_file 'HANDLING_FILE' 'data/**/handling.meta'
data_file 'VEHICLE_METADATA_FILE' 'data/**/vehicles.meta'
data_file 'CARCOLS_FILE' 'data/**/carcols.meta'
data_file 'VEHICLE_VARIATION_FILE' 'data/**/carvariations.meta'
data_file 'DLCTEXT_FILE' 'data/**/dlctext.meta'
data_file 'CARCONTENTUNLOCKS_FILE' 'data/**/carcontentunlocks.meta'
data_file 'EXPLOSION_INFO_FILE' 'data/**/explosion.meta'
data_file 'WEAPONINFO_FILE' 'data/**/vehicleweapons_*.meta'
data_file 'WEAPON_METADATA_FILE' 'data/**/weaponarchetypes.meta'