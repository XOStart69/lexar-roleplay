fx_version "cerulean"
game "gta5"

author "RHD Team"
description "Player appearance and clothing system."
version "1.0.0"

lua54 "yes"

shared_scripts {
    "@ox_lib/init.lua",
    "bridge/framework.lua"
}

client_scripts {
    "client.lua"
}

server_scripts {
    "server.lua"
}

files {
    "typings.lua",
    "locales/*.json",
    "config/*.lua",
    "data/*.lua",
    "core/*.lua",
    "features/*.lua",
    "modules/*.lua",
    "compat/**/*.lua",
    "server/**/*.lua",
    "bridge/**/*.lua",
    "web/dist/index.html",
    "web/dist/**/*"
}

ui_page "web/dist/index.html"

ox_libs {
    "locale"
}

dependencies {
    "ox_lib",
    "oxmysql",
    "sm_resource_1"
}

provide 'illenium-appearance'
