shared_scripts {
    '@ox_lib/init.lua',
    '@se_v2/trigger.lua',
}



fx_version "cerulean"

game "gta5"
lua54 "yes"

name "mnr_cayo"
description "Cayo Perico loader script"
author "IlMelons"
version "1.0.3"
repository "https://github.com/Monarch-Development/mnr_cayo"

this_is_a_map "yes"


client_scripts {
    "client/*.lua"
}

files {
    "data/*.lua"
}
dependency 'se_v2'
