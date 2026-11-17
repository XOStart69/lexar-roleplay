fx_version 'cerulean'
game 'gta5'
this_is_a_map 'yes'

-- Pliki
files {
    'stream/*.ydr',
    'stream/*.ytyp',
    'stream/*.ytd',
}

-- Zasoby
data_file 'DLC_ITYP_REQUEST' 'stream/*.ydr'
data_file 'DLC_ITYP_REQUEST' 'stream/*.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/*.ytd'

-- escrow_ignore {
--     'stream/*.ydr',
--     'stream/*.ytyp',
--     'stream/*.ytd',
-- }
dependency '/assetpacks'