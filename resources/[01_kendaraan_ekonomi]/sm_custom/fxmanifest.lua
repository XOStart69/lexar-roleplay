fx_version 'cerulean'
game 'gta5'

name 'sm_custom'
description 'Vehicle Customization'
version '1.0.0'

author 'RHD Team'

lua54 'yes'
use_experimental_fxv2_oal 'yes'

ui_page 'html/index.html'

shared_script '@ox_lib/init.lua'

ox_libs { 'locale' }

server_script '@oxmysql/lib/MySQL.lua'
shared_script 'init.lua'

client_script 'client/main.lua'
server_script 'server/main.lua'

rhd_modules {
    'net',
    'zones',
    'areas',
    'jobs',
    'pricing',
    'cart',
    'billing',
    'wheels',
    'fitment',
    'swap',
    'nitrous',
    'camera',
    'interact',
    'placer',
    'catalog',
    'shops',
    'install',
    'receipt',
    'booth',
    'editor',
    'discount',
    'logs',
}

files {
    'meta/carcols_gen9.meta',
    'meta/carmodcols_gen9.meta',
    'stream/paint_screen/rhd_paint_screen.ytyp',

    'html/**',
    'locales/*.json',
    'config/client.lua',
    'data/*.lua',
    'data/menu/*.lua',
    'modules/**/client.lua',
    'modules/**/shared.lua',
}

data_file 'CARCOLS_GEN9_FILE' 'meta/carcols_gen9.meta'
data_file 'CARMODCOLS_GEN9_FILE' 'meta/carmodcols_gen9.meta'
data_file 'FIVEM_LOVES_YOU_447B37BE29496FA0' 'stream/rhd_nitrous_flame.ypt'
data_file 'DLC_ITYP_REQUEST' 'stream/paint_screen/rhd_paint_screen.ytyp'

dependencies {
    '/server:7290',
    '/onesync',
    'oxmysql',
    'ox_lib',
    'ox_inventory',
    'sm_core',
}
