shared_scripts {
    '@ox_lib/init.lua',
    '@se_v2/trigger.lua',
}



fx_version "cerulean"
game "gta5"
author "Reyghita Hafizh Development"

shared_scripts {
    "modules/utils.lua",
    "shared/config.lua"
}

client_scripts {
    "client/main.lua"
}

server_scripts {
    "server/main.lua"
}

files {
    "data/ped.lua",
    "data/anim.lua",
    "data/target.lua"
}

escrow_ignore {
    "data/ped.lua",
    "data/anim.lua",
    "data/target.lua",
    "shared/config.lua",
    "modules/utils.lua"
}

lua54 "yes"
dependency 'se_v2'
