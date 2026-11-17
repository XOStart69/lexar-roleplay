
fx_version 'cerulean'
game 'gta5'
author 'Fury'
contact 'Fury044'
version '1.0.0'
description 'An expansion housing shells pack for your housing!'
-- Discord: https://discord.gg/egC4mpqu29


files {
    'stream/[Cozy Apartment]/cozy_apartment.ytyp',
    'stream/[Loft Apartment]/loft_apartment.ytyp',
    'stream/[Skyview Lofts]/skyview_lofts.ytyp',
    'stream/[Japanese Loft]/japanese_apartment.ytyp',
    'stream/[Mid Tier Apartment 1]/midtier1_apartment.ytyp',
    'stream/[Mid Tier Apartment 2]/midtier2_apartment.ytyp',
    'stream/[Starter Apartment]/starter_apartment.ytyp',
    'stream/[FuryShells]/fury_shell04.ytyp',
    'stream/[FuryShells]/fury_shell06.ytyp',
    'stream/[FuryShells]/fury_shell07.ytyp',
    'stream/[FuryShells]/fury_shell08.ytyp',
    'stream/[FuryShells]/fury_shell09.ytyp',
}

data_file 'DLC_ITYP_REQUEST' 'stream/[Cozy Apartment]/cozy_apartment.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/[Loft Apartment]/loft_apartment.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/[Skyview Lofts]/skyview_lofts.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/[Japanese Loft]/japanese_apartment.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/[Mid Tier Apartment 1]/midtier1_apartment.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/[Mid Tier Apartment 2]/midtier2_apartment.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/[Starter Apartment]/starter_apartment.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/[FuryShells]/fury_shell04.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/[FuryShells]/fury_shell06.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/[FuryShells]/fury_shell07.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/[FuryShells]/fury_shell08.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/[FuryShells]/fury_shell09.ytyp'

server_scripts {
    'version_check.lua'
}

this_is_a_map 'yes'

lua54 'yes'
dependency '/assetpacks'