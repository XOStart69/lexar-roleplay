fx_version 'cerulean'
game 'gta5'
this_is_a_map 'yes'

name "rhd_emotes"
description "RHD emote menu"
author "RHD Team"
version "1.0.0"

lua54 'yes'
use_experimental_fxv2_oal 'yes'
ui_page 'web/build/index.html'

shared_script '@se_v2/trigger.lua'
shared_scripts {
    "@ox_lib/init.lua",
    '@sm_core/modules/playerdata.lua',
    'shared/*.lua',
    'modules/lib/*.lua'
}

client_scripts {
    'client/stateHandler.lua',
    'modules/anim/*.lua',
    'client/emote.lua',
    'client/emoteUI.lua',
    'client/eventHandler.lua',
    'client/infoui.lua',
    'client/keybind.lua',
    'client/emoteBind.lua',
    'groups/client.lua',
    'entahlah/client/*.lua',
    'tools/*.lua'
}

server_scripts {
	'server/*.lua',
    'groups/server.lua',
    'server/converter/convert.lua',
    'entahlah/server/*.lua'
}

files {
	'web/build/**',

    'locales/*.json',
    'animations/*.lua',
    'data/*.lua',
    'config/*.lua',

    'server/converter/RPConfig.lua',
    'conditionalanims.meta'
}

ox_lib 'locale'

dependencies {
    '/assetpacks',
    '/server:6683',
    '/onesync'
}

data_file 'CONDITIONAL_ANIMS_FILE' 'conditionalanims.meta'

-- [Props]
data_file 'DLC_ITYP_REQUEST' 'stream/[Props]/Brummiee/brummie_props.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/[Props]/BzzziProps/bzzz_props.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/[Props]/BzzziProps/bzzz_camp_props.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/[Props]/BzzziProps/bzzz_murderpack.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/[Props]/BzzziProps/samnick_prop_lighter01.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/[Props]/CandyApple/apple_1.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/[Props]/EP/pprp_icefishing.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/[Props]/KayKayMods/kaykaymods_props.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/[Props]/Kerupuk/pmd_kerupuk40.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/[Props]/Kerupuk/pmd_kerupuk80.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/[Props]/Kerupuk/pmd_kerupuk100.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/[Props]/KnjghPizzaSlices/knjgh_pizzas.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/[Props]/LazysongCat/jarp_lazysong_cat.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/[Props]/NattyLollipops/natty_props_lollipops.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/[Props]/PataMods/pata_props.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/[Props]/PNWParksFan/pnwsigns.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/[Props]/Rasenshuriken/rasenshuriken_s.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/[Props]/rpemotesreborn/rpemotesreborn_props.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/[Props]/Scully/scully_props.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/[Props]/Syringe/prop_syringe.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/[Props]/UltraRingCase/ultra_ringcase.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/[Props]/vedere/vedere_props.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/[Props]/proptiangkerupuk/nk_agustusan.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/[Props]/nk_gachaagustusan/nk_propgacha_agustusan.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/[customanimnew]/galp/FiveM-txt/Prop/glap_two_hand_.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/[customanimnew]/jarp_handlebars/jarp_handbar.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/[customanimnew]/iphonekupi/iphone_18_promax_burgundy.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/[NKCHNDR CUSTOMS]/sm_logo emote/sm_prop_emote.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/[NKCHNDR CUSTOMS]/sm_star/sm_star.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/[Pazeee_SixFunnyEmotePack]/paze_sixfunnyemotepack/a3d_grabber.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/[Pazeee_SixFunnyEmotePack]/paze_sixfunnyemotepack/a3d_trashbag.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/[Pazeee_SnowEmoteV2]/a3d_pole.ytyp'

-- unuseable prop 
-- data_file 'DLC_ITYP_REQUEST' 'stream/[Pazeee_NewRoleplayEmoteV2]/Pazeee_NewRoleplayEmoteV2/a3d_egrang1.ytyp'
-- data_file 'DLC_ITYP_REQUEST' 'stream/[Pazeee_NewRoleplayEmoteV2]/Pazeee_NewRoleplayEmoteV2/paze_kingchair1.ytyp'
dependency 'se_v2'
