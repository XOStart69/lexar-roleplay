fx_version "cerulean"
game "gta5"
lua54 "yes"

version "2.8.0"

shared_script {
    "config/*.lua",
    "shared/**/*.lua"
}

client_script {
    "lib/client/**.lua",
    "client/**.lua"
}

server_scripts {
    "@oxmysql/lib/MySQL.lua",
    "lib/server/**.lua",
    "server/**/*.lua",
}

files {
    "ui/dist/**/*",
    "ui/components.js",
    "ui/livetray-bridge.js",
    "config/**/*",
    "sound/data/lbphone.dat54.rel",
    "sound/dlc_lbscripts/sounds.awc"
}

data_file 'AUDIO_WAVEPACK'  'sound/dlc_lbscripts'
data_file 'AUDIO_SOUNDDATA' 'sound/data/lbphone.dat'

ui_page "ui/dist/index.html"

dependency "oxmysql"
