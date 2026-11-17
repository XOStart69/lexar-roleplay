---@alias ClothingItemPiece { drawable: number, texture: number?, free: boolean? }
---@alias ClothingItemLook table<string, ClothingItemPiece>

--[[
    Clothing that is owned as an inventory item instead of being picked in the menu. Everything
    listed here is blacklisted wherever the editor can reach, shops and the admin panel included, so
    using the item is the only way to put it on.
    
    Naming a texture takes only that one, leaving the drawable's other textures to everyone else.
    Leaving it out takes the drawable and every texture on it.
    
    Slot names are the ones in data/constants.lua SLOTS. One item may cover several slots at once.
    Every name here is registered with the framework as a usable item, so the inventory definition
    needs nothing beyond the item itself.
]]

---@type table<string, table<string, ClothingItemLook>>
return {
    --- Testring
    -- garbage = {
    --     male = {
    --         masks = { drawable = 234, texture = 3 }
    --     }
    -- },

    f_bodyarmor_wlmc1 = {
        female = {
            bodyArmor = { drawable = 677, texture = 0 },
        },
    },

    f_bodyarmor_bbl1 = {
        female = {
            bodyArmor = { drawable = 678, texture = 0 },
        },
    },

    m_bodyarmor_wlmc1 = {
       male = {
            bodyArmor = { drawable = 395, texture = 0 }, 
        },
    },

    m_bodyarmor_bbl1 = {
        male = {
            bodyArmor = { drawable = 396, texture = 0 }, 
        },
    },

    --- Baju Operasi Male ---
    m_baju_oplas = {
        male = {
            jackets = { drawable = 1494, texture = 1 },
            lowerBody = { drawable = 14, texture = 12 },
            upperBody = { drawable = 15, texture = 0, free = true },
        },
    },

    --- Baju Operasi Female ---
    f_baju_oplas = {
        female = {
            jackets = { drawable = 1916, texture = 0 },
            lowerBody = { drawable = 10, texture = 0, free = true },
            upperBody = { drawable = 272, texture = 0, free = true },
        },
    },

    --- masks Male ---
    m_masks_lmc = {
        male = {
            masks = { drawable = 316, texture = 0 },
        },
    },

    m_masks_nexus = {
        male = {
            masks = { drawable = 317, texture = 0 },
        },
    },


     --- masks Female ---
    f_masks_lmc = {
        female = {
            masks = { drawable = 407, texture = 0 },
        },
    },

    f_masks_nexus = {
        female = {
            masks = { drawable = 408, texture = 0 },
        },
    },




    --- Hats Male ---
    m_hats_dsr1 = {
        male = {
            hats = { drawable = 320, texture = 0 },
        },
    },

    m_hats_dsr2 = {
        male = {
            hats = { drawable = 321, texture = 0 },
        },
    },


     --- Hats Female ---
    f_hats_dsr1 = {
        female = {
            hats = { drawable = 215, texture = 0 },
        },
    },



    --- pants Male ---
    -- m_pants_ggd = {
    --     male = {
    --         pants = { drawable = 667, texture = 0 },
    --     },
    -- },

    m_pants_heavenhell1 = {
        male = {
            lowerBody = { drawable = 668, texture = 0 },
        },
    },

    m_pants_swag1 = {
        male = {
            lowerBody = { drawable = 719, texture = 0 },
        },
    },


     --- pants Female ---
    -- f_pants_ggd = {
    --     female = {
    --         pants = { drawable = 211, texture = 0 },
    --     },
    -- },

    f_pants_heavenhell1 = {
        female = {
            lowerBody = { drawable = 212, texture = 0 },
        },
    },

    f_pants_swag1 = {
        female = {
            lowerBody = { drawable = 251, texture = 0 },
        },
    },

    --- scarfAndChains Male ---
    -- m_teef_gaviria = {
    --     male = {
    --         scarfAndChains = { drawable = 550, texture = 0 },
    --     },
    -- },

    m_teef_noctis = {
        male = {
            scarfAndChains = { drawable = 637, texture = 0 },
        },
    },

    m_teef_fsg1 = {
        male = {
            scarfAndChains = { drawable = 639, texture = 0 },
        },
    },

    m_teef_ebk1 = {
        male = {
            scarfAndChains = { drawable = 642, texture = 0 },
        },
    },

    m_teef_lv1 = {
        male = {
            scarfAndChains = { drawable = 643, texture = 0 },
        },
    },


     --- scarfAndChains Female ---
    -- f_teef_gaviria = {
    --     female = {
    --         scarfAndChains = { drawable = 752, texture = 0 },
    --     },
    -- },

    f_teef_noctis = {
        female = {
            scarfAndChains = { drawable = 828, texture = 0 },
        },
    },

    f_teef_fsg1 = {
        female = {
            scarfAndChains = { drawable = 830, texture = 0 },
        },
    },

    f_teef_ebk1 = {
        female = {
            scarfAndChains = { drawable = 833, texture = 0 },
        },
    },

    f_teef_lv1 = {
        female = {
            scarfAndChains = { drawable = 834, texture = 0 },
        },
    },

	--- bags Male ---
	
	-- m_bags_shinrai = {
    --     male = {
    --         bags = { drawable = 222, texture = 0 },
    --     },
    -- },

    m_bags_bfl = {
        male = {
            bags = { drawable = 225, texture = 0 },
        },
    },

    m_bags_ls1_0 = {
        male = {
            bags = { drawable = 231, texture = 0 },
        },
    },

    m_bags_ls1_1 = {
        male = {
            bags = { drawable = 231, texture = 1 },
        },
    },

    m_bags_shellby = {
        male = {
            bags = { drawable = 257, texture = 0 },
        },
    },
	
	
	--- bags Female ---
	
	-- f_bags_shinrai = {
    --     female = {
    --         bags = { drawable = 486, texture = 0 },
    --     },
    -- },

    f_bags_bfl = {
        female = {
            bags = { drawable = 489, texture = 0 },
        },
    },

    f_bags_ls1_0 = {
        female = {
            bags = { drawable = 491, texture = 0 },
        },
    },

    f_bags_ls1_1 = {
        female = {
            bags = { drawable = 491, texture = 1 },
        },
    },

    f_bags_shellby = {
        female = {
            bags = { drawable = 516, texture = 0 },
        },
    },


    --- shirts Male ---
    
    m_shirts_rb = {
        male = {
            shirts = { drawable = 343, texture = 0 },
        },
    },


    --- shirts Female ---

    f_shirts_rb = {
        female = {
            shirts = { drawable = 1096, texture = 0 },
        },
    },
    




    --- jackets Male ---
    m_jackets_wd1 = {
        male = {
            jackets = { drawable = 1521, texture = 0 },
        },
    },

    m_jackets_wd2 = {
        male = {
            jackets = { drawable = 1522, texture = 0 },
        },
    },

    m_jackets_bz1_0 = {
        male = {
            jackets = { drawable = 1523, texture = 0 },
        },
    },

    m_jackets_bz1_1 = {
        male = {
            jackets = { drawable = 1523, texture = 1 },
        },
    },

    m_jackets_bz1_2 = {
        male = {
            jackets = { drawable = 1523, texture = 2 },
        },
    },

    m_jackets_bz2_0 = {
        male = {
            jackets = { drawable = 1524, texture = 0 },
        },
    },

    m_jackets_bz2_1 = {
        male = {
            jackets = { drawable = 1524, texture = 1 },
        },
    },

    m_jackets_bz2_2 = {
        male = {
            jackets = { drawable = 1524, texture = 2 },
        },
    },

    -- m_jackets_bmc1_0 = {
    --     male = {
    --         jackets = { drawable = 1525, texture = 0 },
    --     },
    -- },

    -- m_jackets_bmc1_1 = {
    --     male = {
    --         jackets = { drawable = 1525, texture = 1 },
    --     },
    -- },

    -- m_jackets_bmc2_0 = {
    --     male = {
    --         jackets = { drawable = 1526, texture = 0 },
    --     },
    -- },

    -- m_jackets_bmc2_1 = {
    --     male = {
    --         jackets = { drawable = 1526, texture = 1 },
    --     },
    -- },

    m_jackets_lfa1 = {
        male = {
            jackets = { drawable = 1527, texture = 0 },
        },
    },

    m_jackets_lfa2 = {
        male = {
            jackets = { drawable = 1528, texture = 0 },
        },
    },

    m_jackets_rb1 = {
        male = {
            jackets = { drawable = 1529, texture = 0 },
        },
    },
	
	-- m_jackets_shinrai = {
    --     male = {
    --         jackets = { drawable = 1530, texture = 0 },
    --     },
    -- },

    m_jackets_ht1 = {
        male = {
            jackets = { drawable = 1531, texture = 0 },
        },
    },

    m_jackets_ht2 = {
        male = {
            jackets = { drawable = 1532, texture = 0 },
        },
    },

    -- m_jackets_bxd1 = {
    --     male = {
    --         jackets = { drawable = 1541, texture = 0 },
    --     },
    -- },

    -- m_jackets_bxd2 = {
    --     male = {
    --         jackets = { drawable = 1542, texture = 0 },
    --     },
    -- },

    -- m_jackets_brv1_0 = {
    --     male = {
    --         jackets = { drawable = 1550, texture = 0 },
    --     },
    -- },

    -- m_jackets_brv1_1 = {
    --     male = {
    --         jackets = { drawable = 1550, texture = 1 },
    --     },
    -- },

    -- m_jackets_brv2 = {
    --     male = {
    --         jackets = { drawable = 1551, texture = 0 },
    --     },
    -- },

    m_jackets_gvr = {
        male = {
            jackets = { drawable = 1552, texture = 0 },
        },
    },

    m_jackets_bfl = {
        male = {
            jackets = { drawable = 1553, texture = 0 },
        },
    },

    m_jackets_gdp1 = {
        male = {
            jackets = { drawable = 1556, texture = 0 },
        },
    },

    -- m_jackets_ggd1 = {
    --     male = {
    --         jackets = { drawable = 1557, texture = 0 },
    --     },
    -- },

    -- m_jackets_cmc1 = {
    --     male = {
    --         jackets = { drawable = 1558, texture = 0 },
    --     },
    -- },

    -- m_jackets_cmc2 = {
    --     male = {
    --         jackets = { drawable = 1663, texture = 0 },
    --     },
    -- },

    m_jackets_ls1 = {
        male = {
            jackets = { drawable = 1559, texture = 0 },
        },
    },

    -- m_jackets_sdmc1 = {
    --     male = {
    --         jackets = { drawable = 1560, texture = 0 },
    --     },
    -- },

    -- m_jackets_sdmc2 = {
    --     male = {
    --         jackets = { drawable = 1564, texture = 0 },
    --     },
    -- },

    m_jackets_wtmc1 = {
        male = {
            jackets = { drawable = 1565, texture = 0 },
        },
    },

    m_jackets_blackjack1 = {
        male = {
            jackets = { drawable = 1566, texture = 0 },
        },
    },

    m_jackets_blackjack2 = {
        male = {
            jackets = { drawable = 1567, texture = 0 },
        },
    },

    m_jackets_blackjack3 = {
        male = {
            jackets = { drawable = 1568, texture = 0 },
        },
    },

    m_jackets_blackjack4 = {
        male = {
            jackets = { drawable = 1569, texture = 0 },
        },
    },

    m_jackets_nexus1 = {
        male = {
            jackets = { drawable = 1574, texture = 0 },
        },
    },

    m_jackets_heavenhell1 = {
        male = {
            jackets = { drawable = 1575, texture = 0 },
        },
    },

    m_jackets_pam1_0 = {
        male = {
            jackets = { drawable = 1577, texture = 0 },
        },
    },

    m_jackets_pam1_1 = {
        male = {
            jackets = { drawable = 1577, texture = 1 },
        },
    },

    m_jackets_abyssal1 = {
        male = {
            jackets = { drawable = 1578, texture = 0 },
        },
    },

    m_jackets_abyssal2 = {
        male = {
            jackets = { drawable = 1579, texture = 0 }, 
        },
    },

    m_jackets_gehanom1 = {
        male = {
            jackets = { drawable = 1585, texture = 0 }, 
        },
    },

    m_jackets_gehanom2 = {
        male = {
            jackets = { drawable = 1586, texture = 0 }, 
        },
    },

    m_jackets_fleelinks1 = {
        male = {
            jackets = { drawable = 1587, texture = 0 }, 
        },
    },

    -- m_jackets_gaviria1 = {
    --     male = {
    --         jackets = { drawable = 1589, texture = 0 }, 
    --     },
    -- },

    -- m_jackets_gaviria2 = {
    --     male = {
    --         jackets = { drawable = 1590, texture = 0 }, 
    --     },
    -- },

    m_jackets_crimsonreign1_0 = {
        male = {
            jackets = { drawable = 1596, texture = 0 }, 
        },
    },

    m_jackets_crimsonreign1_1 = {
        male = {
            jackets = { drawable = 1596, texture = 1 }, 
        },
    },

    m_jackets_kuroyama1 = {
        male = {
            jackets = { drawable = 1598, texture = 0 }, 
        },
    },

    m_jackets_lmc1 = {
        male = {
            jackets = { drawable = 1599, texture = 0 }, 
        },
    },

    m_jackets_omc1 = {
        male = {
            jackets = { drawable = 1600, texture = 0 }, 
        },
    },

    m_jackets_babayo1 = {
        male = {
            jackets = { drawable = 1654, texture = 0 },
        },
    },

    m_jackets_babayo2 = {
        male = {
            jackets = { drawable = 1776, texture = 0 },
        },
    },

    m_jackets_ffy1 = {
        male = {
            jackets = { drawable = 1664, texture = 0 },
        },
    },

    m_jackets_vrn1 = {
        male = {
            jackets = { drawable = 1665, texture = 0 },
        },
    },

    -- m_jackets_hsc1_0 = {
    --     male = {
    --         jackets = { drawable = 1717, texture = 0 }, 
    --     },
    -- },

    -- m_jackets_hsc1_1 = {
    --     male = {
    --         jackets = { drawable = 1717, texture = 1 }, 
    --     },
    -- },

    -- m_jackets_hsc2_0 = {
    --     male = {
    --         jackets = { drawable = 1718, texture = 0 }, 
    --     },
    -- },

    -- m_jackets_hsc2_1 = {
    --     male = {
    --         jackets = { drawable = 1718, texture = 1 }, 
    --     },
    -- },

    m_jackets_fleelinks2 = {
        male = {
            jackets = { drawable = 1726, texture = 0 }, 
        },
    },

    m_jackets_fleelinks3 = {
        male = {
            jackets = { drawable = 1727, texture = 0 }, 
        },
    },

    m_jackets_phoenix1 = {
        male = {
            jackets = { drawable = 1744, texture = 0 }, 
        },
    },

    -- m_jackets_phantom1 = {
    --     male = {
    --         jackets = { drawable = 1748, texture = 0 }, 
    --     },
    -- },
    
    m_jackets_maevan1 = {
        male = {
            jackets = { drawable = 1752, texture = 0 }, 
        },
    },

    -- m_jackets_larosenoir1 = {
    --     male = {
    --         jackets = { drawable = 1754, texture = 0 }, 
    --     },
    -- },

    m_jackets_bzmc1 = {
        male = {
            jackets = { drawable = 1766, texture = 0 }, 
        },
    },

    m_jackets_f4ke1_0 = {
        male = {
            jackets = { drawable = 1767, texture = 0 }, 
        },
    },

    m_jackets_f4ke1_1 = {
        male = {
            jackets = { drawable = 1767, texture = 1 }, 
        },
    },

    m_jackets_cortize1 = {
        male = {
            jackets = { drawable = 1782, texture = 0 }, 
        },
    },

    m_jackets_soumc1 = {
        male = {
            jackets = { drawable = 1783, texture = 0 }, 
        },
    },

    m_jackets_rmc1 = {
        male = {
            jackets = { drawable = 1784, texture = 0 }, 
        },
    },

    m_jackets_nsn1 = {
        male = {
            jackets = { drawable = 1807, texture = 0 }, 
        },
    },

    m_jackets_karabas1 = {
        male = {
            jackets = { drawable = 1812, texture = 0 }, 
        },
    },

    m_jackets_brg1_0 = {
        male = {
            jackets = { drawable = 1818, texture = 0 }, 
        },
    },

    m_jackets_brg1_1 = {
        male = {
            jackets = { drawable = 1818, texture = 1 }, 
        },
    },

    m_jackets_invictus1 = {
        male = {
            jackets = { drawable = 1821, texture = 0 }, 
        },
    },

    m_jackets_jdmc1 = {
        male = {
            jackets = { drawable = 1859, texture = 0 }, 
        },
    },

    m_jackets_jdmc2 = {
        male = {
            jackets = { drawable = 1946, texture = 0 }, 
        },
    },

    m_jackets_jdmc3 = {
        male = {
            jackets = { drawable = 1968, texture = 0 }, 
        },
    },

    m_jackets_nagasaki1 = {
        male = {
            jackets = { drawable = 1862, texture = 0 }, 
        },
    },

    m_jackets_nagasaki2 = {
        male = {
            jackets = { drawable = 1939, texture = 0 }, 
        },
    },
    
    m_jackets_cortize2 = {
        male = {
            jackets = { drawable = 1895, texture = 0 }, 
        },
    },

    m_jackets_overdrive1 = {
        male = {
            jackets = { drawable = 1904, texture = 0 }, 
        },
    },

    m_jackets_deleon1 = {
        male = {
            jackets = { drawable = 1905, texture = 0 }, 
        },
    },

    m_jackets_deleon2 = {
        male = {
            jackets = { drawable = 1944, texture = 0 }, 
        },
    },

    m_jackets_deleon3 = {
        male = {
            jackets = { drawable = 1945, texture = 0 }, 
        },
    },

    m_jackets_kinggroup1 = {
        male = {
            jackets = { drawable = 1920, texture = 0 }, 
        },
    },

    m_jackets_kinggroup2 = {
        male = {
            jackets = { drawable = 1960, texture = 0 }, 
        },
    },

    m_jackets_fsg1 = {
        male = {
            jackets = { drawable = 1931, texture = 0 }, 
        },
    },

    m_jackets_vanity1 = {
        male = {
            jackets = { drawable = 1932, texture = 0 }, 
        },
    },

    m_jackets_umc1 = {
        male = {
            jackets = { drawable = 1933, texture = 0 }, 
        },
    },

    m_jackets_swag1 = {
        male = {
            jackets = { drawable = 1937, texture = 0 }, 
        },
    },

    m_jackets_swag2 = {
        male = {
            jackets = { drawable = 1962, texture = 0 }, 
        },
    },

    m_jackets_eclipse1 = {
        male = {
            jackets = { drawable = 1936, texture = 0 }, 
        },
    },

    m_jackets_sos1 = {
        male = {
            jackets = { drawable = 1938, texture = 0 }, 
        },
    },

    m_jackets_hakuryu1 = {
        male = {
            jackets = { drawable = 1941, texture = 0 }, 
        },
    },

    m_jackets_invamouz1 = {
        male = {
            jackets = { drawable = 1942, texture = 0 }, 
        },
    },

    m_jackets_invamouz2 = {
        male = {
            jackets = { drawable = 1964, texture = 0 }, 
        },
    },

    m_jackets_youngmc1 = {
        male = {
            jackets = { drawable = 1952, texture = 0 }, 
        },
    },

    m_jackets_barong1 = {
        male = {
            jackets = { drawable = 1954, texture = 0 }, 
        },
    },

    m_jackets_barong2 = {
        male = {
            jackets = { drawable = 1955, texture = 0 }, 
        },
    },

    m_jackets_barong3 = {
        male = {
            jackets = { drawable = 1956, texture = 0 }, 
        },
    },

    m_jackets_barong4 = {
        male = {
            jackets = { drawable = 1957, texture = 0 }, 
        },
    },

    m_jackets_barong5 = {
        male = {
            jackets = { drawable = 1959, texture = 0 }, 
        },
    },

    m_jackets_rbl1 = {
        male = {
            jackets = { drawable = 1963, texture = 0 }, 
        },
    },

    m_jackets_etb1 = {
        male = {
            jackets = { drawable = 1967, texture = 0 }, 
        },
    },
    









    --- jackets Female ---
    f_jackets_wd1 = {
        female = {
            jackets = { drawable = 1943, texture = 0 },
        },
    },

    f_jackets_wd2 = {
        female = {
            jackets = { drawable = 1944, texture = 0 },
        },
    },

    f_jackets_bz1_0 = {
        female = {
            jackets = { drawable = 1945, texture = 0 },
        },
    },

    f_jackets_bz1_1 = {
        female = {
            jackets = { drawable = 1945, texture = 1 },
        },
    },

    f_jackets_bz1_2 = {
        female = {
            jackets = { drawable = 1945, texture = 2 },
        },
    },

    f_jackets_bz2_0 = {
        female = {
            jackets = { drawable = 1946, texture = 0 },
        },
    },

    f_jackets_bz2_1 = {
        female = {
            jackets = { drawable = 1946, texture = 1 },
        },
    },

    f_jackets_bz2_2 = {
        female = {
            jackets = { drawable = 1946, texture = 2 },
        },
    },

    -- f_jackets_bmc1_0 = {
    --     female = {
    --         jackets = { drawable = 1947, texture = 0 },
    --     },
    -- },

    -- f_jackets_bmc1_1 = {
    --     female = {
    --         jackets = { drawable = 1947, texture = 1 },
    --     },
    -- },

    -- f_jackets_bmc2_0 = {
    --     female = {
    --         jackets = { drawable = 1948, texture = 0 },
    --     },
    -- },

    -- f_jackets_bmc2_1 = {
    --     female = {
    --         jackets = { drawable = 1948, texture = 1 },
    --     },
    -- },
    
    f_jackets_lfa1 = {
        female = {
            jackets = { drawable = 1949, texture = 0 },
        },
    },

    f_jackets_lfa2 = {
        female = {
            jackets = { drawable = 1950, texture = 0 },
        },
    },

    f_jackets_rb1 = {
        female = {
            jackets = { drawable = 1951, texture = 0 },
        },
    },
	
	-- f_jackets_shinrai = {
    --     female = {
    --         jackets = { drawable = 1952, texture = 0 },
    --     },
    -- },

    f_jackets_ht1_0 = {
        female = {
            jackets = { drawable = 1953, texture = 0 },
        },
    },

    f_jackets_ht1_1 = {
        female = {
            jackets = { drawable = 1953, texture = 1 },
        },
    },

    f_jackets_ht1_2 = {
        female = {
            jackets = { drawable = 1953, texture = 2 },
        },
    },

    f_jackets_ht2 = {
        female = {
            jackets = { drawable = 1954, texture = 0 },
        },
    },

    -- f_jackets_bxd1 = {
    --     female = {
    --         jackets = { drawable = 1963, texture = 0 },
    --     },
    -- },

    -- f_jackets_bxd2 = {
    --     female = {
    --         jackets = { drawable = 1964, texture = 0 },
    --     },
    -- },

    -- f_jackets_brv1_0 = {
    --     female = {
    --         jackets = { drawable = 1973, texture = 0 },
    --     },
    -- },

    -- f_jackets_brv1_1 = {
    --     female = {
    --         jackets = { drawable = 1973, texture = 1 },
    --     },
    -- },

    -- f_jackets_brv2 = {
    --     female = {
    --         jackets = { drawable = 1974, texture = 0 },
    --     },
    -- },

    f_jackets_gvr = {
        female = {
            jackets = { drawable = 1975, texture = 0 },
        },
    },

    f_jackets_bfl = {
        female = {
            jackets = { drawable = 1976, texture = 0 },
        },
    },

    f_jackets_gdp1 = {
        female = {
            jackets = { drawable = 1979, texture = 0 },
        },
    },

    -- f_jackets_ggd1 = {
    --     female = {
    --         jackets = { drawable = 1980, texture = 0 },
    --     },
    -- },

    -- f_jackets_cmc1 = {
    --     female = {
    --         jackets = { drawable = 1981, texture = 0 },
    --     },
    -- },

    -- f_jackets_cmc2 = {
    --     female = {
    --         jackets = { drawable = 2076, texture = 0 },
    --     },
    -- },

    f_jackets_ls1 = {
        female = {
            jackets = { drawable = 1982, texture = 0 },
        },
    },

    -- f_jackets_sdmc1 = {
    --     female = {
    --         jackets = { drawable = 1983, texture = 0 },
    --     },
    -- },

    -- f_jackets_sdmc2 = {
    --     female = {
    --         jackets = { drawable = 1987, texture = 0 },
    --     },
    -- },

    f_jackets_wtmc1 = {
        female = {
            jackets = { drawable = 1988, texture = 0 },
        },
    },

    f_jackets_blackjack1 = {
        female = {
            jackets = { drawable = 1989, texture = 0 },
        },
    },

    f_jackets_blackjack2 = {
        female = {
            jackets = { drawable = 1990, texture = 0 },
        },
    },

    f_jackets_blackjack3 = {
        female = {
            jackets = { drawable = 1991, texture = 0 },
        },
    },

    f_jackets_blackjack4 = {
        female = {
            jackets = { drawable = 1992, texture = 0 },
        },
    },

    f_jackets_nexus1 = {
        female = {
            jackets = { drawable = 1999, texture = 0 },
        },
    },

    f_jackets_heavenhell1 = {
        female = {
            jackets = { drawable = 2000, texture = 0 },
        },
    },

    f_jackets_pam1_0 = {
        female = {
            jackets = { drawable = 2001, texture = 0 },
        },
    },

    f_jackets_pam1_1 = {
        female = {
            jackets = { drawable = 2001, texture = 1 },
        },
    },

    f_jackets_abyssal1 = {
        female = {
            jackets = { drawable = 2002, texture = 0 },
        },
    },

    f_jackets_abyssal2 = {
        female = {
            jackets = { drawable = 2003, texture = 0 }, 
        },
    },

    f_jackets_gehanom1 = {
        female = {
            jackets = { drawable = 2009, texture = 0 }, 
        },
    },

    f_jackets_gehanom2 = {
        female = {
            jackets = { drawable = 2010, texture = 0 }, 
        },
    },

    f_jackets_fleelinks1 = {
        female = {
            jackets = { drawable = 2011, texture = 0 }, 
        },
    },
    
    -- f_jackets_gaviria1 = {
    --     female = {
    --         jackets = { drawable = 2012, texture = 0 }, 
    --     },
    -- },

    f_jackets_crimsonreign1_0 = {
        female = {
            jackets = { drawable = 2016, texture = 0 }, 
        },
    },

    f_jackets_crimsonreign1_1 = {
        female = {
            jackets = { drawable = 2016, texture = 1 }, 
        },
    },

    f_jackets_kuroyama1 = {
        female = {
            jackets = { drawable = 2018, texture = 0 }, 
        },
    },

    f_jackets_lmc1 = {
        female = {
            jackets = { drawable = 2019, texture = 0 }, 
        },
    },

    f_jackets_omc1 = {
        female = {
            jackets = { drawable = 2020, texture = 0 }, 
        },
    },

    f_jackets_vrn1 = {
        female = {
            jackets = { drawable = 2077, texture = 0 }, 
        },
    },

    -- f_jackets_hsc1_0 = {
    --     female = {
    --         jackets = { drawable = 2131, texture = 0 }, 
    --     },
    -- },

    -- f_jackets_hsc1_1 = {
    --     female = {
    --         jackets = { drawable = 2131, texture = 1 }, 
    --     },
    -- },

    -- f_jackets_hsc2_0 = {
    --     female = {
    --         jackets = { drawable = 2132, texture = 0 }, 
    --     },
    -- },

    -- f_jackets_hsc2_1 = {
    --     female = {
    --         jackets = { drawable = 2132, texture = 1 }, 
    --     },
    -- },

    f_jackets_fleelinks2 = {
        female = {
            jackets = { drawable = 2140, texture = 0 }, 
        },
    },

    f_jackets_fleelinks3 = {
        female = {
            jackets = { drawable = 2141, texture = 0 }, 
        },
    },

    f_jackets_phoenix1 = {
        female = {
            jackets = { drawable = 2151, texture = 0 }, 
        },
    },

    f_jackets_maevan1_0 = {
        female = {
            jackets = { drawable = 2156, texture = 0 }, 
        },
    },

    f_jackets_maevan1_1 = {
        female = {
            jackets = { drawable = 2156, texture = 1 }, 
        },
    },

    -- f_jackets_larosenoir1 = {
    --     female = {
    --         jackets = { drawable = 2157, texture = 0 }, 
    --     },
    -- },

    f_jackets_bzmc1 = {
        female = {
            jackets = { drawable = 2170, texture = 0 }, 
        },
    },

    f_jackets_f4ke1_0 = {
        female = {
            jackets = { drawable = 2171, texture = 0 }, 
        },
    },

    f_jackets_f4ke1_1 = {
        female = {
            jackets = { drawable = 2171, texture = 1 }, 
        },
    },

    f_jackets_babayo1_0 = {
        female = {
            jackets = { drawable = 2179, texture = 0 }, 
        },
    },

    f_jackets_cortize1 = {
        female = {
            jackets = { drawable = 2185, texture = 0 }, 
        },
    },

    f_jackets_soumc1 = {
        female = {
            jackets = { drawable = 2186, texture = 0 }, 
        },
    },

    f_jackets_nsn1 = {
        female = {
            jackets = { drawable = 2216, texture = 0 }, 
        },
    },

    f_jackets_nsn2 = {
        female = {
            jackets = { drawable = 2333, texture = 0 }, 
        },
    },

    f_jackets_karabas1 = {
        female = {
            jackets = { drawable = 2220, texture = 0 }, 
        },
    },

    f_jackets_brg1_0 = {
        female = {
            jackets = { drawable = 2225, texture = 0 }, 
        },
    },

    f_jackets_brg1_1 = {
        female = {
            jackets = { drawable = 2225, texture = 1 }, 
        },
    },

    f_jackets_invictus1 = {
        female = {
            jackets = { drawable = 2226, texture = 0 }, 
        },
    },

    f_jackets_jdmc1 = {
        female = {
            jackets = { drawable = 2261, texture = 0 }, 
        },
    },

    f_jackets_jdmc2 = {
        female = {
            jackets = { drawable = 2330, texture = 0 }, 
        },
    },

    f_jackets_jdmc3 = {
        female = {
            jackets = { drawable = 2356, texture = 0 }, 
        },
    },

    f_jackets_nagasaki1 = {
        female = {
            jackets = { drawable = 2264, texture = 0 }, 
        },
    },

    f_jackets_nagasaki2 = {
        female = {
            jackets = { drawable = 2324, texture = 0 }, 
        },
    },

    f_jackets_cortize2 = {
        female = {
            jackets = { drawable = 2290, texture = 0 }, 
        },
    },

    f_jackets_overdrive1 = {
        female = {
            jackets = { drawable = 2298, texture = 0 }, 
        },
    },

    f_jackets_kinggroup1 = {
        female = {
            jackets = { drawable = 2309, texture = 0 }, 
        },
    },

    f_jackets_kinggroup2 = {
        female = {
            jackets = { drawable = 2349, texture = 0 }, 
        },
    },

    f_jackets_fsg1 = {
        female = {
            jackets = { drawable = 2318, texture = 0 }, 
        },
    },

    f_jackets_vanity1 = {
        female = {
            jackets = { drawable = 2319, texture = 0 }, 
        },
    },

    f_jackets_umc1 = {
        female = {
            jackets = { drawable = 2320, texture = 0 }, 
        },
    },

    f_jackets_swag1 = {
        female = {
            jackets = { drawable = 2322, texture = 0 }, 
        },
    },

    f_jackets_swag2 = {
        female = {
            jackets = { drawable = 2351, texture = 0 }, 
        },
    },

    f_jackets_eclipse1 = {
        female = {
            jackets = { drawable = 2321, texture = 0 }, 
        },
    },

    f_jackets_sos1 = {
        female = {
            jackets = { drawable = 2323, texture = 0 }, 
        },
    },

    f_jackets_hakuryu1 = {
        female = {
            jackets = { drawable = 2326, texture = 0 }, 
        },
    },

    f_jackets_invamouz1 = {
        female = {
            jackets = { drawable = 2327, texture = 0 }, 
        },
    },

    f_jackets_deleon2 = {
        female = {
            jackets = { drawable = 2328, texture = 0 }, 
        },
    },

    f_jackets_deleon3 = {
        female = {
            jackets = { drawable = 2329, texture = 0 }, 
        },
    },

    f_jackets_youngmc1 = {
        female = {
            jackets = { drawable = 2340, texture = 0 }, 
        },
    },

    f_jackets_barong1 = {
        female = {
            jackets = { drawable = 2342, texture = 0 }, 
        },
    },

    f_jackets_barong2 = {
        female = {
            jackets = { drawable = 2343, texture = 0 }, 
        },
    },

    f_jackets_barong3 = {
        female = {
            jackets = { drawable = 2344, texture = 0 }, 
        },
    },

    f_jackets_barong4 = {
        female = {
            jackets = { drawable = 2345, texture = 0 }, 
        },
    },

    f_jackets_barong5 = {
        female = {
            jackets = { drawable = 2347, texture = 0 }, 
        },
    },

    f_jackets_rbl1 = {
        female = {
            jackets = { drawable = 2352, texture = 0 }, 
        },
    },

    f_jackets_etb1 = {
        female = {
            jackets = { drawable = 2355, texture = 0 }, 
        },
    },








    
    --- bodyArmor Male ---
    m_bodyarmor_wd1 = {
        male = {
            bodyArmor = { drawable = 224, texture = 0 },
        },
    },

    m_bodyarmor_bz1_0 = {
        male = {
            bodyArmor = { drawable = 225, texture = 0 },
        },
    },

    m_bodyarmor_bz1_1 = {
        male = {
            bodyArmor = { drawable = 225, texture = 1 },
        },
    },

    m_bodyarmor_bz1_2 = {
        male = {
            bodyArmor = { drawable = 225, texture = 2 },
        },
    },

    -- m_bodyarmor_bmc1_0 = {
    --     male = {
    --         bodyArmor = { drawable = 226, texture = 0 },
    --     },
    -- },

    -- m_bodyarmor_bmc1_1 = {
    --     male = {
    --         bodyArmor = { drawable = 226, texture = 1 },
    --     },
    -- },

    -- m_bodyarmor_bmc1_2 = {
    --     male = {
    --         bodyArmor = { drawable = 226, texture = 2 },
    --     },
    -- },

    -- m_bodyarmor_bmc1_3 = {
    --     male = {
    --         bodyArmor = { drawable = 226, texture = 3 },
    --     },
    -- },

    -- m_bodyarmor_bmc1_4 = {
    --     male = {
    --         bodyArmor = { drawable = 226, texture = 4 },
    --     },
    -- },

    -- m_bodyarmor_bmc1_5 = {
    --     male = {
    --         bodyArmor = { drawable = 226, texture = 5 },
    --     },
    -- },

    -- m_bodyarmor_bmc1_6 = {
    --     male = {
    --         bodyArmor = { drawable = 226, texture = 6 },
    --     },
    -- },

    -- m_bodyarmor_bmc1_7 = {
    --     male = {
    --         bodyArmor = { drawable = 226, texture = 7 },
    --     },
    -- },

    m_bodyarmor_lfa1 = {
        male = {
            bodyArmor = { drawable = 227, texture = 0 },
        },
    },

    m_bodyarmor_rb1 = {
        male = {
            bodyArmor = { drawable = 228, texture = 0 },
        },
    },
	
	-- m_bodyarmor_shinrai = {
    --     male = {
    --         bodyArmor = { drawable = 229, texture = 0 },
    --     },
    -- },

    -- m_bodyarmor_bxd = {
    --     male = {
    --         bodyArmor = { drawable = 232, texture = 0 },
    --     },
    -- },

    -- m_bodyarmor_brv = {
    --     male = {
    --         bodyArmor = { drawable = 233, texture = 0 },
    --     },
    -- },

    m_bodyarmor_gvr = {
        male = {
            bodyArmor = { drawable = 234, texture = 0 },
        },
    },

    m_bodyarmor_bfl = {
        male = {
            bodyArmor = { drawable = 235, texture = 0 },
        },
    },

    -- m_bodyarmor_ggd = {
    --     male = {
    --         bodyArmor = { drawable = 236, texture = 0 },
    --     },
    -- },

    -- m_bodyarmor_sdmc1_0 = {
    --     male = {
    --         bodyArmor = { drawable = 237, texture = 0 },
    --     },
    -- },

    -- m_bodyarmor_sdmc1_1 = {
    --     male = {
    --         bodyArmor = { drawable = 237, texture = 1 },
    --     },
    -- },

    -- m_bodyarmor_sdmc1_2 = {
    --     male = {
    --         bodyArmor = { drawable = 237, texture = 2 },
    --     },
    -- },

    -- m_bodyarmor_sdmc1_3 = {
    --     male = {
    --         bodyArmor = { drawable = 237, texture = 3 },
    --     },
    -- },

    -- m_bodyarmor_sdmc1_4 = {
    --     male = {
    --         bodyArmor = { drawable = 237, texture = 4 },
    --     },
    -- },

    -- m_bodyarmor_sdmc1_5 = {
    --     male = {
    --         bodyArmor = { drawable = 237, texture = 5 },
    --     },
    -- },

    -- m_bodyarmor_sdmc1_6 = {
    --     male = {
    --         bodyArmor = { drawable = 237, texture = 6 },
    --     },
    -- },

    -- m_bodyarmor_sdmc1_7 = {
    --     male = {
    --         bodyArmor = { drawable = 237, texture = 7 },
    --     },
    -- },

    -- m_bodyarmor_sdmc1_8 = {
    --     male = {
    --         bodyArmor = { drawable = 237, texture = 8 },
    --     },
    -- },

    m_bodyarmor_wtmc1_0 = {
        male = {
            bodyArmor = { drawable = 238, texture = 0 },
        },
    },

    m_bodyarmor_wtmc1_1 = {
        male = {
            bodyArmor = { drawable = 238, texture = 1 },
        },
    },

    m_bodyarmor_wtmc1_2 = {
        male = {
            bodyArmor = { drawable = 238, texture = 2 },
        },
    },

    m_bodyarmor_wtmc1_3 = {
        male = {
            bodyArmor = { drawable = 238, texture = 3 },
        },
    },

    m_bodyarmor_wtmc1_4 = {
        male = {
            bodyArmor = { drawable = 238, texture = 4 },
        },
    },

    m_bodyarmor_wtmc1_5 = {
        male = {
            bodyArmor = { drawable = 238, texture = 5 },
        },
    },

    m_bodyarmor_wtmc1_6 = {
        male = {
            bodyArmor = { drawable = 238, texture = 6 },
        },
    },

    m_bodyarmor_wtmc1_7 = {
        male = {
            bodyArmor = { drawable = 238, texture = 7 },
        },
    },

    m_bodyarmor_wtmc1_8 = {
        male = {
            bodyArmor = { drawable = 238, texture = 8 },
        },
    },

    m_bodyarmor_wtmc1_9 = {
        male = {
            bodyArmor = { drawable = 238, texture = 9 },
        },
    },

    m_bodyarmor_wtmc1_10 = {
        male = {
            bodyArmor = { drawable = 238, texture = 10 },
        },
    },

    m_bodyarmor_omc1_0 = {
        male = {
            bodyArmor = { drawable = 239, texture = 0 },
        },
    },

    m_bodyarmor_omc1_1 = {
        male = {
            bodyArmor = { drawable = 239, texture = 1 },
        },
    },

    m_bodyarmor_omc1_2 = {
        male = {
            bodyArmor = { drawable = 239, texture = 2 },
        },
    },

    m_bodyarmor_omc1_3 = {
        male = {
            bodyArmor = { drawable = 239, texture = 3 },
        },
    },

    m_bodyarmor_omc1_4 = {
        male = {
            bodyArmor = { drawable = 239, texture = 4 },
        },
    },

    m_bodyarmor_ls1 = {
        male = {
            bodyArmor = { drawable = 241, texture = 0 },
        },
    },

    m_bodyarmor_heavenhell1_0 = {
        male = {
            bodyArmor = { drawable = 242, texture = 0 },
        },
    },

    m_bodyarmor_heavenhell1_1 = {
        male = {
            bodyArmor = { drawable = 242, texture = 1 },
        },
    },

    m_bodyarmor_abyssal1 = {
        male = {
            bodyArmor = { drawable = 243, texture = 0 }, 
        },
    },

    m_bodyarmor_gehanom1 = {
        male = {
            bodyArmor = { drawable = 246, texture = 0 }, 
        },
    },

    m_bodyarmor_lmc1_0 = {
        male = {
            bodyArmor = { drawable = 249, texture = 0 }, 
        },
    },

    m_bodyarmor_lmc1_1 = {
        male = {
            bodyArmor = { drawable = 249, texture = 1 }, 
        },
    },

    m_bodyarmor_lmc1_2 = {
        male = {
            bodyArmor = { drawable = 249, texture = 2 }, 
        },
    },

    m_bodyarmor_lmc1_3 = {
        male = {
            bodyArmor = { drawable = 249, texture = 3 }, 
        },
    },

    m_bodyarmor_lmc1_4 = {
        male = {
            bodyArmor = { drawable = 249, texture = 4 }, 
        },
    },

    m_bodyarmor_lmc1_5 = {
        male = {
            bodyArmor = { drawable = 249, texture = 5 }, 
        },
    },

    m_bodyarmor_lmc1_6 = {
        male = {
            bodyArmor = { drawable = 249, texture = 6 }, 
        },
    },

    m_bodyarmor_lmc1_7 = {
        male = {
            bodyArmor = { drawable = 249, texture = 7 }, 
        },
    },

    m_bodyarmor_lmc1_8 = {
        male = {
            bodyArmor = { drawable = 249, texture = 8 }, 
        },
    },

    m_bodyarmor_lmc1_9 = {
        male = {
            bodyArmor = { drawable = 249, texture = 9 }, 
        },
    },

    m_bodyarmor_lmc1_10 = {
        male = {
            bodyArmor = { drawable = 249, texture = 10 }, 
        },
    },

    m_bodyarmor_nexus1 = {
        male = {
            bodyArmor = { drawable = 250, texture = 0 }, 
        },
    },

    m_bodyarmor_babayo1 = {
        male = {
            bodyArmor = { drawable = 262, texture = 0 }, 
        },
    },

    -- m_bodyarmor_cmc1_0 = {
    --     male = {
    --         bodyArmor = { drawable = 263, texture = 0 }, 
    --     },
    -- },

    -- m_bodyarmor_cmc1_1 = {
    --     male = {
    --         bodyArmor = { drawable = 263, texture = 1 }, 
    --     },
    -- },

    -- m_bodyarmor_cmc1_2 = {
    --     male = {
    --         bodyArmor = { drawable = 263, texture = 2 }, 
    --     },
    -- },

    -- m_bodyarmor_cmc1_3 = {
    --     male = {
    --         bodyArmor = { drawable = 263, texture = 3 }, 
    --     },
    -- },

    -- m_bodyarmor_cmc1_4 = {
    --     male = {
    --         bodyArmor = { drawable = 263, texture = 4 }, 
    --     },
    -- },

    -- m_bodyarmor_cmc1_5 = {
    --     male = {
    --         bodyArmor = { drawable = 263, texture = 5 }, 
    --     },
    -- },

    -- m_bodyarmor_cmc1_6 = {
    --     male = {
    --         bodyArmor = { drawable = 263, texture = 6 }, 
    --     },
    -- },

    m_bodyarmor_omc2_0 = {
        male = {
            bodyArmor = { drawable = 279, texture = 0 }, 
        },
    },

    m_bodyarmor_omc2_1 = {
        male = {
            bodyArmor = { drawable = 279, texture = 1 }, 
        },
    },

    m_bodyarmor_omc2_2 = {
        male = {
            bodyArmor = { drawable = 279, texture = 2 }, 
        },
    },

    m_bodyarmor_omc2_3 = {
        male = {
            bodyArmor = { drawable = 279, texture = 3 }, 
        },
    },

    m_bodyarmor_omc2_4 = {
        male = {
            bodyArmor = { drawable = 279, texture = 4 }, 
        },
    },

    m_bodyarmor_omc2_5 = {
        male = {
            bodyArmor = { drawable = 279, texture = 5 }, 
        },
    },

    m_bodyarmor_omc2_6 = {
        male = {
            bodyArmor = { drawable = 279, texture = 6 }, 
        },
    },
    m_bodyarmor_omc2_7 = {
        male = {
            bodyArmor = { drawable = 279, texture = 7 }, 
        },
    },

    m_bodyarmor_ssmc1_0 = {
        male = {
            bodyArmor = { drawable = 287, texture = 0 }, 
        },
    },

    m_bodyarmor_babayo2 = {
        male = {
            bodyArmor = { drawable = 291, texture = 0 }, 
        },
    },

    m_bodyarmor_whitetiger1 = {
        male = {
            bodyArmor = { drawable = 292, texture = 0 }, 
        },
    },

    m_bodyarmor_ssmc2_0 = {
        male = {
            bodyArmor = { drawable = 293, texture = 0 }, 
        },
    },

    m_bodyarmor_ssmc2_1 = {
        male = {
            bodyArmor = { drawable = 293, texture = 1 }, 
        },
    },

    m_bodyarmor_ssmc2_2 = {
        male = {
            bodyArmor = { drawable = 293, texture = 2 }, 
        },
    },

    m_bodyarmor_ssmc2_3 = {
        male = {
            bodyArmor = { drawable = 293, texture = 3 }, 
        },
    },

    m_bodyarmor_ssmc2_4 = {
        male = {
            bodyArmor = { drawable = 293, texture = 4 }, 
        },
    },

    m_bodyarmor_ssmc2_5 = {
        male = {
            bodyArmor = { drawable = 293, texture = 5 }, 
        },
    },

    m_bodyarmor_ssmc2_6 = {
        male = {
            bodyArmor = { drawable = 293, texture = 6 }, 
        },
    },

    m_bodyarmor_ssmc2_7 = {
        male = {
            bodyArmor = { drawable = 293, texture = 7 }, 
        },
    },

    m_bodyarmor_sfc1_0 = {
        male = {
            bodyArmor = { drawable = 294, texture = 0 }, 
        },
    },

    m_bodyarmor_sfc1_1 = {
        male = {
            bodyArmor = { drawable = 294, texture = 1 }, 
        },
    },

    m_bodyarmor_rmc1_0 = {
        male = {
            bodyArmor = { drawable = 300, texture = 0 }, 
        },
    },

    m_bodyarmor_rmc1_1 = {
        male = {
            bodyArmor = { drawable = 300, texture = 1 }, 
        },
    },

    m_bodyarmor_rmc1_2 = {
        male = {
            bodyArmor = { drawable = 300, texture = 2 }, 
        },
    },

    m_bodyarmor_rmc1_3 = {
        male = {
            bodyArmor = { drawable = 300, texture = 3 }, 
        },
    },

    m_bodyarmor_rmc1_4 = {
        male = {
            bodyArmor = { drawable = 300, texture = 4 }, 
        },
    },

    m_bodyarmor_rmc1_5 = {
        male = {
            bodyArmor = { drawable = 300, texture = 5 }, 
        },
    },

    m_bodyarmor_rmc1_6 = {
        male = {
            bodyArmor = { drawable = 300, texture = 6 }, 
        },
    },

    m_bodyarmor_rmc1_7 = {
        male = {
            bodyArmor = { drawable = 300, texture = 7 }, 
        },
    },

    m_bodyarmor_rmc1_8 = {
        male = {
            bodyArmor = { drawable = 300, texture = 8 }, 
        },
    },

    m_bodyarmor_rmc1_9 = {
        male = {
            bodyArmor = { drawable = 300, texture = 9 }, 
        },
    },

    m_bodyarmor_bzmc1_0 = {
        male = {
            bodyArmor = { drawable = 303, texture = 0 }, 
        },
    },

    m_bodyarmor_bzmc1_1 = {
        male = {
            bodyArmor = { drawable = 303, texture = 1 }, 
        },
    },

    m_bodyarmor_bzmc1_2 = {
        male = {
            bodyArmor = { drawable = 303, texture = 2 }, 
        },
    },

    m_bodyarmor_bzmc1_3 = {
        male = {
            bodyArmor = { drawable = 303, texture = 3 }, 
        },
    },

    m_bodyarmor_bzmc1_4 = {
        male = {
            bodyArmor = { drawable = 303, texture = 4 }, 
        },
    },

    m_bodyarmor_bzmc1_5 = {
        male = {
            bodyArmor = { drawable = 303, texture = 5 }, 
        },
    },

    m_bodyarmor_bzmc1_6 = {
        male = {
            bodyArmor = { drawable = 303, texture = 6 }, 
        },
    },

    m_bodyarmor_bzmc1_7 = {
        male = {
            bodyArmor = { drawable = 303, texture = 7 }, 
        },
    },

    m_bodyarmor_mugen1_0 = {
        male = {
            bodyArmor = { drawable = 305, texture = 0 }, 
        },
    },

    m_bodyarmor_mugen1_1 = {
        male = {
            bodyArmor = { drawable = 305, texture = 1 }, 
        },
    },

    m_bodyarmor_mugen1_2 = {
        male = {
            bodyArmor = { drawable = 305, texture = 2 }, 
        },
    },

    m_bodyarmor_mugen1_3 = {
        male = {
            bodyArmor = { drawable = 305, texture = 3 }, 
        },
    },

    m_bodyarmor_mugen1_4 = {
        male = {
            bodyArmor = { drawable = 305, texture = 4 }, 
        },
    },

    m_bodyarmor_mugen1_5 = {
        male = {
            bodyArmor = { drawable = 305, texture = 5 }, 
        },
    },

    m_bodyarmor_mugen1_6 = {
        male = {
            bodyArmor = { drawable = 305, texture = 6 }, 
        },
    },

    m_bodyarmor_mugen1_7 = {
        male = {
            bodyArmor = { drawable = 305, texture = 7 }, 
        },
    },

    m_bodyarmor_mugen1_8 = {
        male = {
            bodyArmor = { drawable = 305, texture = 8 }, 
        },
    },

    m_bodyarmor_mugen1_9 = {
        male = {
            bodyArmor = { drawable = 305, texture = 9 }, 
        },
    },
    
    m_bodyarmor_mugen1_10 = {
        male = {
            bodyArmor = { drawable = 305, texture = 10 }, 
        },
    },
    
    m_bodyarmor_mugen1_11 = {
        male = {
            bodyArmor = { drawable = 305, texture = 11 }, 
        },
    },

    m_bodyarmor_mugen1_12 = {
        male = {
            bodyArmor = { drawable = 305, texture = 12 }, 
        },
    },

    m_bodyarmor_mugen1_13 = {
        male = {
            bodyArmor = { drawable = 305, texture = 13 }, 
        },
    },

    m_bodyarmor_wdmc1_0 = {
        male = {
            bodyArmor = { drawable = 313, texture = 0 }, 
        },
    },

    m_bodyarmor_wdmc1_1 = {
        male = {
            bodyArmor = { drawable = 313, texture = 1 }, 
        },
    },

    m_bodyarmor_wdmc1_2 = {
        male = {
            bodyArmor = { drawable = 313, texture = 2 }, 
        },
    },

    m_bodyarmor_wdmc1_3 = {
        male = {
            bodyArmor = { drawable = 313, texture = 3 }, 
        },
    },

    m_bodyarmor_wdmc1_4 = {
        male = {
            bodyArmor = { drawable = 313, texture = 4 }, 
        },
    },

    m_bodyarmor_wdmc1_5 = {
        male = {
            bodyArmor = { drawable = 313, texture = 5 }, 
        },
    },

    m_bodyarmor_fsg1 = {
        male = {
            bodyArmor = { drawable = 314, texture = 0 }, 
        },
    },

    m_bodyarmor_nsn1 = {
        male = {
            bodyArmor = { drawable = 318, texture = 0 }, 
        },
    },

    m_bodyarmor_karabas1 = {
        male = {
            bodyArmor = { drawable = 319, texture = 0 }, 
        },
    },

    m_bodyarmor_ryc1_0 = {
        male = {
            bodyArmor = { drawable = 325, texture = 0 }, 
        },
    },

    m_bodyarmor_ryc1_1 = {
        male = {
            bodyArmor = { drawable = 325, texture = 1 }, 
        },
    },

    m_bodyarmor_thez1 = {
        male = {
            bodyArmor = { drawable = 370, texture = 0 }, 
        },
    },

    m_bodyarmor_mx691 = {
        male = {
            bodyArmor = { drawable = 376, texture = 0 }, 
        },
    },

    m_bodyarmor_cravell1_0 = {
        male = {
            bodyArmor = { drawable = 377, texture = 0 }, 
        },
    },

    m_bodyarmor_cravell1_1 = {
        male = {
            bodyArmor = { drawable = 377, texture = 1 }, 
        },
    },

    m_bodyarmor_cravell1_2 = {
        male = {
            bodyArmor = { drawable = 377, texture = 2 }, 
        },
    },

    m_bodyarmor_cravell1_3 = {
        male = {
            bodyArmor = { drawable = 377, texture = 3 }, 
        },
    },

    m_bodyarmor_cravell1_4 = {
        male = {
            bodyArmor = { drawable = 377, texture = 4 }, 
        },
    },

    m_bodyarmor_cravell1_5 = {
        male = {
            bodyArmor = { drawable = 377, texture = 5 }, 
        },
    },

    m_bodyarmor_cravell1_6 = {
        male = {
            bodyArmor = { drawable = 377, texture = 6 }, 
        },
    },

    m_bodyarmor_cravell1_7 = {
        male = {
            bodyArmor = { drawable = 377, texture = 7 }, 
        },
    },

    m_bodyarmor_invamouz1_0 = {
        male = {
            bodyArmor = { drawable = 381, texture = 0 }, 
        },
    },

    m_bodyarmor_invamouz1_1 = {
        male = {
            bodyArmor = { drawable = 381, texture = 1 }, 
        },
    },

    m_bodyarmor_invamouz1_2 = {
        male = {
            bodyArmor = { drawable = 381, texture = 2 }, 
        },
    },

    m_bodyarmor_invamouz1_3 = {
        male = {
            bodyArmor = { drawable = 381, texture = 3 }, 
        },
    },

    m_bodyarmor_invamouz1_4 = {
        male = {
            bodyArmor = { drawable = 381, texture = 4 }, 
        },
    },

    m_bodyarmor_invamouz1_5 = {
        male = {
            bodyArmor = { drawable = 381, texture = 5 }, 
        },
    },

    m_bodyarmor_invamouz1_6 = {
        male = {
            bodyArmor = { drawable = 381, texture = 6 }, 
        },
    },

    m_bodyarmor_invamouz1_7 = {
        male = {
            bodyArmor = { drawable = 381, texture = 7 }, 
        },
    },

    m_bodyarmor_invamouz1_8 = {
        male = {
            bodyArmor = { drawable = 381, texture = 8 }, 
        },
    },

    m_bodyarmor_shellby1 = {
        male = {
            bodyArmor = { drawable = 384, texture = 0 }, 
        },
    },

    m_bodyarmor_sos1 = {
        male = {
            bodyArmor = { drawable = 387, texture = 0 }, 
        },
    },

    m_bodyarmor_brg1 = {
        male = {
            bodyArmor = { drawable = 390, texture = 0 }, 
        },
    },

    m_bodyarmor_nagasaki1 = {
        male = {
            bodyArmor = { drawable = 399, texture = 0 }, 
        },
    },

    m_bodyarmor_hakuryu1 = {
        male = {
            bodyArmor = { drawable = 401, texture = 0 }, 
        },
    },

    m_bodyarmor_youngmc1_0 = {
        male = {
            bodyArmor = { drawable = 402, texture = 0 }, 
        },
    },

    m_bodyarmor_youngmc1_1 = {
        male = {
            bodyArmor = { drawable = 402, texture = 1 }, 
        },
    },

    m_bodyarmor_youngmc1_2 = {
        male = {
            bodyArmor = { drawable = 402, texture = 2 }, 
        },
    },

    m_bodyarmor_youngmc1_3 = {
        male = {
            bodyArmor = { drawable = 402, texture = 3 }, 
        },
    },

    m_bodyarmor_youngmc1_4 = {
        male = {
            bodyArmor = { drawable = 402, texture = 4 }, 
        },
    },

    m_bodyarmor_youngmc1_5 = {
        male = {
            bodyArmor = { drawable = 402, texture = 5 }, 
        },
    },

    m_bodyarmor_youngmc1_6 = {
        male = {
            bodyArmor = { drawable = 402, texture = 6 }, 
        },
    },

    m_bodyarmor_youngmc1_7 = {
        male = {
            bodyArmor = { drawable = 402, texture = 7 }, 
        },
    },

    m_bodyarmor_jdmc1 = {
        male = {
            bodyArmor = { drawable = 403, texture = 0 }, 
        },
    },

    m_bodyarmor_r9691 = {
        male = {
            bodyArmor = { drawable = 406, texture = 0 }, 
        },
    },












    
    --- bodyArmor Female ---
    f_bodyarmor_wd1 = {
        female = {
            bodyArmor = { drawable = 474, texture = 0 },
        },
    },

    f_bodyarmor_bz1_0 = {
        female = {
            bodyArmor = { drawable = 475, texture = 0 },
        },
    },
    
    f_bodyarmor_bz1_1 = {
        female = {
            bodyArmor = { drawable = 475, texture = 1 },
        },
    },

    f_bodyarmor_bz1_2 = {
        female = {
            bodyArmor = { drawable = 475, texture = 2 },
        },
    },

    -- f_bodyarmor_bmc1_0 = {
    --     female = {
    --         bodyArmor = { drawable = 476, texture = 0 },
    --     },
    -- },

    -- f_bodyarmor_bmc1_1 = {
    --     female = {
    --         bodyArmor = { drawable = 476, texture = 1 },
    --     },
    -- },

    -- f_bodyarmor_bmc1_2 = {
    --     female = {
    --         bodyArmor = { drawable = 476, texture = 2 },
    --     },
    -- },

    -- f_bodyarmor_bmc1_3 = {
    --     female = {
    --         bodyArmor = { drawable = 476, texture = 3 },
    --     },
    -- },

    -- f_bodyarmor_bmc1_4 = {
    --     female = {
    --         bodyArmor = { drawable = 476, texture = 4 },
    --     },
    -- },

    -- f_bodyarmor_bmc1_5 = {
    --     female = {
    --         bodyArmor = { drawable = 476, texture = 5 },
    --     },
    -- },

    -- f_bodyarmor_bmc1_6 = {
    --     female = {
    --         bodyArmor = { drawable = 476, texture = 6 },
    --     },
    -- },

    -- f_bodyarmor_bmc1_7 = {
    --     female = {
    --         bodyArmor = { drawable = 476, texture = 7 },
    --     },
    -- },

    f_bodyarmor_lfa1 = {
        female = {
            bodyArmor = { drawable = 477, texture = 0 },
        },
    },
	
	-- f_bodyarmor_shinrai = {
    --     female = {
    --         bodyArmor = { drawable = 478, texture = 0 },
    --     },
    -- },

    -- f_bodyarmor_bxd = {
    --     female = {
    --         bodyArmor = { drawable = 481, texture = 0 },
    --     },
    -- },

    -- f_bodyarmor_brv = {
    --     female = {
    --         bodyArmor = { drawable = 482, texture = 0 },
    --     },
    -- },

    f_bodyarmor_gvr = {
        female = {
            bodyArmor = { drawable = 483, texture = 0 },
        },
    },

    f_bodyarmor_bfl = {
        female = {
            bodyArmor = { drawable = 484, texture = 0 },
        },
    },
    
    -- f_bodyarmor_ggd = {
    --     female = {
    --         bodyArmor = { drawable = 485, texture = 0 },
    --     },
    -- },

    -- f_bodyarmor_sdmc1_0 = {
    --     female = {
    --         bodyArmor = { drawable = 486, texture = 0 },
    --     },
    -- },

    -- f_bodyarmor_sdmc1_1 = {
    --     female = {
    --         bodyArmor = { drawable = 486, texture = 1 },
    --     },
    -- },

    -- f_bodyarmor_sdmc1_2 = {
    --     female = {
    --         bodyArmor = { drawable = 486, texture = 2 },
    --     },
    -- },

    -- f_bodyarmor_sdmc1_3 = {
    --     female = {
    --         bodyArmor = { drawable = 486, texture = 3 },
    --     },
    -- },

    -- f_bodyarmor_sdmc1_4 = {
    --     female = {
    --         bodyArmor = { drawable = 486, texture = 4 },
    --     },
    -- },

    -- f_bodyarmor_sdmc1_5 = {
    --     female = {
    --         bodyArmor = { drawable = 486, texture = 5 },
    --     },
    -- },

    -- f_bodyarmor_sdmc1_6 = {
    --     female = {
    --         bodyArmor = { drawable = 486, texture = 6 },
    --     },
    -- },

    -- f_bodyarmor_sdmc1_7 = {
    --     female = {
    --         bodyArmor = { drawable = 486, texture = 7 },
    --     },
    -- },

    -- f_bodyarmor_sdmc1_8 = {
    --     female = {
    --         bodyArmor = { drawable = 486, texture = 8 },
    --     },
    -- },

    f_bodyarmor_wtmc1_0 = {
        female = {
            bodyArmor = { drawable = 487, texture = 0 },
        },
    },

    f_bodyarmor_wtmc1_1 = {
        female = {
            bodyArmor = { drawable = 487, texture = 1 },
        },
    },

    f_bodyarmor_wtmc1_2 = {
        female = {
            bodyArmor = { drawable = 487, texture = 2 },
        },
    },

    f_bodyarmor_wtmc1_3 = {
        female = {
            bodyArmor = { drawable = 487, texture = 3 },
        },
    },

    f_bodyarmor_wtmc1_4 = {
        female = {
            bodyArmor = { drawable = 487, texture = 4 },
        },
    },

    f_bodyarmor_wtmc1_5 = {
        female = {
            bodyArmor = { drawable = 487, texture = 5 },
        },
    },

    f_bodyarmor_wtmc1_6 = {
        female = {
            bodyArmor = { drawable = 487, texture = 6 },
        },
    },

    f_bodyarmor_wtmc1_7 = {
        female = {
            bodyArmor = { drawable = 487, texture = 7 },
        },
    },

    f_bodyarmor_wtmc1_8 = {
        female = {
            bodyArmor = { drawable = 487, texture = 8 },
        },
    },

    f_bodyarmor_wtmc1_9 = {
        female = {
            bodyArmor = { drawable = 487, texture = 9 },
        },
    },

    f_bodyarmor_wtmc1_10 = {
        female = {
            bodyArmor = { drawable = 487, texture = 10 },
        },
    },

    f_bodyarmor_omc1_0 = {
        female = {
            bodyArmor = { drawable = 488, texture = 0 },
        },
    },

    f_bodyarmor_omc1_1 = {
        female = {
            bodyArmor = { drawable = 488, texture = 1 },
        },
    },

    f_bodyarmor_omc1_2 = {
        female = {
            bodyArmor = { drawable = 488, texture = 2 },
        },
    },

    f_bodyarmor_omc1_3 = {
        female = {
            bodyArmor = { drawable = 488, texture = 3 },
        },
    },

    f_bodyarmor_omc1_4 = {
        female = {
            bodyArmor = { drawable = 488, texture = 4 },
        },
    },

    f_bodyarmor_ls1 = {
        female = {
            bodyArmor = { drawable = 492, texture = 0 },
        },
    },

    f_bodyarmor_heavenhell1_0 = {
        female = {
            bodyArmor = { drawable = 493, texture = 0 },
        },
    },

    f_bodyarmor_heavenhell1_1 = {
        female = {
            bodyArmor = { drawable = 493, texture = 1 },
        },
    },

    f_bodyarmor_abyssal1 = {
        female = {
            bodyArmor = { drawable = 494, texture = 0 },
        },
    },

    f_bodyarmor_gehanom1 = {
        female = {
            bodyArmor = { drawable = 496, texture = 0 },
        },
    },

    -- f_bodyarmor_gaviria1 = {
    --     female = {
    --         bodyArmor = { drawable = 499, texture = 0 },
    --     },
    -- },

    f_bodyarmor_lmc1_0 = {
        female = {
            bodyArmor = { drawable = 501, texture = 0 },
        },
    },

    f_bodyarmor_lmc1_1 = {
        female = {
            bodyArmor = { drawable = 501, texture = 1 },
        },
    },

    f_bodyarmor_lmc1_2 = {
        female = {
            bodyArmor = { drawable = 501, texture = 2 },
        },
    },

    f_bodyarmor_lmc1_3 = {
        female = {
            bodyArmor = { drawable = 501, texture = 3 },
        },
    },

    f_bodyarmor_lmc1_4 = {
        female = {
            bodyArmor = { drawable = 501, texture = 4 },
        },
    },

    f_bodyarmor_lmc1_5 = {
        female = {
            bodyArmor = { drawable = 501, texture = 5 },
        },
    },

    f_bodyarmor_nexus1 = {
        female = {
            bodyArmor = { drawable = 502, texture = 0 },
        },
    },

    f_bodyarmor_babayo1 = {
        female = {
            bodyArmor = { drawable = 516, texture = 0 },
        },
    },

    f_bodyarmor_babayo2 = {
        female = {
            bodyArmor = { drawable = 517, texture = 0 },
        },
    },

    -- f_bodyarmor_cmc1_0 = {
    --     female = {
    --         bodyArmor = { drawable = 518, texture = 0 },
    --     },
    -- },

    -- f_bodyarmor_cmc1_1 = {
    --     female = {
    --         bodyArmor = { drawable = 518, texture = 1 },
    --     },
    -- },

    -- f_bodyarmor_cmc1_2 = {
    --     female = {
    --         bodyArmor = { drawable = 518, texture = 2 },
    --     },
    -- },

    -- f_bodyarmor_cmc1_3 = {
    --     female = {
    --         bodyArmor = { drawable = 518, texture = 3 },
    --     },
    -- },

    -- f_bodyarmor_cmc1_4 = {
    --     female = {
    --         bodyArmor = { drawable = 518, texture = 4 },
    --     },
    -- },

    -- f_bodyarmor_cmc1_5 = {
    --     female = {
    --         bodyArmor = { drawable = 518, texture = 5 },
    --     },
    -- },

    -- f_bodyarmor_cmc1_6 = {
    --     female = {
    --         bodyArmor = { drawable = 518, texture = 6 },
    --     },
    -- },

    f_bodyarmor_ffy1 = {
        female = {
            bodyArmor = { drawable = 519, texture = 0 },
        },
    },

    f_bodyarmor_omc2_0 = {
        female = {
            bodyArmor = { drawable = 535, texture = 0 }, 
        },
    },

    f_bodyarmor_omc2_1 = {
        female = {
            bodyArmor = { drawable = 535, texture = 1 }, 
        },
    },

    f_bodyarmor_omc2_2 = {
        female = {
            bodyArmor = { drawable = 535, texture = 2 }, 
        },
    },

    f_bodyarmor_omc2_3 = {
        female = {
            bodyArmor = { drawable = 535, texture = 3 }, 
        },
    },

    f_bodyarmor_omc2_4 = {
        female = {
            bodyArmor = { drawable = 535, texture = 4 }, 
        },
    },

    f_bodyarmor_omc2_5 = {
        female = {
            bodyArmor = { drawable = 535, texture = 5 }, 
        },
    },

    f_bodyarmor_omc2_6 = {
        female = {
            bodyArmor = { drawable = 535, texture = 6 }, 
        },
    },

    f_bodyarmor_omc2_7 = {
        female = {
            bodyArmor = { drawable = 535, texture = 7 }, 
        },
    },

    f_bodyarmor_ssmc1_0 = {
        female = {
            bodyArmor = { drawable = 542, texture = 0 }, 
        },
    },

    -- f_bodyarmor_phantom1 = {
    --     female = {
    --         bodyArmor = { drawable = 547, texture = 0 }, 
    --     },
    -- },

    f_bodyarmor_babayo3 = {
        female = {
            bodyArmor = { drawable = 550, texture = 0 },
        },
    },

    f_bodyarmor_babayo4 = {
        female = {
            bodyArmor = { drawable = 567, texture = 0 },
        },
    },

    f_bodyarmor_whitetiger1 = {
        female = {
            bodyArmor = { drawable = 551, texture = 0 },
        },
    },

    f_bodyarmor_ssmc2_0 = {
        female = {
            bodyArmor = { drawable = 552, texture = 0 },
        },
    },

    f_bodyarmor_ssmc2_1 = {
        female = {
            bodyArmor = { drawable = 552, texture = 1 },
        },
    },

    f_bodyarmor_ssmc2_2 = {
        female = {
            bodyArmor = { drawable = 552, texture = 2 },
        },
    },

    f_bodyarmor_ssmc2_3 = {
        female = {
            bodyArmor = { drawable = 552, texture = 3 },
        },
    },

    f_bodyarmor_ssmc2_4 = {
        female = {
            bodyArmor = { drawable = 552, texture = 4 },
        },
    },

    f_bodyarmor_ssmc2_5 = {
        female = {
            bodyArmor = { drawable = 552, texture = 5 },
        },
    },

    f_bodyarmor_ssmc2_6 = {
        female = {
            bodyArmor = { drawable = 552, texture = 6 },
        },
    },

    f_bodyarmor_ssmc2_7 = {
        female = {
            bodyArmor = { drawable = 552, texture = 7 },
        },
    },

    f_bodyarmor_sfc1_0 = {
        female = {
            bodyArmor = { drawable = 553, texture = 0 },
        },
    },

    f_bodyarmor_sfc1_1 = {
        female = {
            bodyArmor = { drawable = 553, texture = 1 },
        },
    },

    f_bodyarmor_rmc1_0 = {
        female = {
            bodyArmor = { drawable = 559, texture = 0 },
        },
    },

    f_bodyarmor_rmc1_1 = {
        female = {
            bodyArmor = { drawable = 559, texture = 1 },
        },
    },

    f_bodyarmor_rmc1_2 = {
        female = {
            bodyArmor = { drawable = 559, texture = 2 },
        },
    },

    f_bodyarmor_rmc1_3 = {
        female = {
            bodyArmor = { drawable = 559, texture = 3 },
        },
    },

    f_bodyarmor_rmc1_4 = {
        female = {
            bodyArmor = { drawable = 559, texture = 4 },
        },
    },

    f_bodyarmor_rmc1_5 = {
        female = {
            bodyArmor = { drawable = 559, texture = 5 },
        },
    },

    f_bodyarmor_rmc1_6 = {
        female = {
            bodyArmor = { drawable = 559, texture = 6 },
        },
    },

    f_bodyarmor_rmc1_7 = {
        female = {
            bodyArmor = { drawable = 559, texture = 7 },
        },
    },

    f_bodyarmor_rmc1_8 = {
        female = {
            bodyArmor = { drawable = 559, texture = 8 },
        },
    },

    f_bodyarmor_rmc1_9 = {
        female = {
            bodyArmor = { drawable = 559, texture = 9 },
        },
    },

    f_bodyarmor_bzmc1_0 = {
        female = {
            bodyArmor = { drawable = 564, texture = 0 },
        },
    },

    f_bodyarmor_bzmc1_1 = {
        female = {
            bodyArmor = { drawable = 564, texture = 1 },
        },
    },

    f_bodyarmor_bzmc1_2 = {
        female = {
            bodyArmor = { drawable = 564, texture = 2 },
        },
    },

    f_bodyarmor_bzmc1_3 = {
        female = {
            bodyArmor = { drawable = 564, texture = 3 },
        },
    },

    f_bodyarmor_bzmc1_4 = {
        female = {
            bodyArmor = { drawable = 564, texture = 4 },
        },
    },

    f_bodyarmor_bzmc1_5 = {
        female = {
            bodyArmor = { drawable = 564, texture = 5 },
        },
    },

    f_bodyarmor_bzmc1_6 = {
        female = {
            bodyArmor = { drawable = 564, texture = 6 },
        },
    },

    f_bodyarmor_bzmc1_7 = {
        female = {
            bodyArmor = { drawable = 564, texture = 7 },
        },
    },

    f_bodyarmor_rmc2 = {
        female = {
            bodyArmor = { drawable = 570, texture = 0 },
        },
    },

    f_bodyarmor_mugen1_0 = {
        female = {
            bodyArmor = { drawable = 569, texture = 0 },
        },
    },

    f_bodyarmor_mugen1_1 = {
        female = {
            bodyArmor = { drawable = 569, texture = 1 },
        },
    },

    f_bodyarmor_mugen1_2 = {
        female = {
            bodyArmor = { drawable = 569, texture = 2 },
        },
    },

    f_bodyarmor_mugen1_3 = {
        female = {
            bodyArmor = { drawable = 569, texture = 3 },
        },
    },

    f_bodyarmor_mugen1_4 = {
        female = {
            bodyArmor = { drawable = 569, texture = 4 },
        },
    },

    f_bodyarmor_mugen1_5 = {
        female = {
            bodyArmor = { drawable = 569, texture = 5 },
        },
    },

    f_bodyarmor_mugen1_6 = {
        female = {
            bodyArmor = { drawable = 569, texture = 6 },
        },
    },

    f_bodyarmor_mugen1_7 = {
        female = {
            bodyArmor = { drawable = 569, texture = 7 },
        },
    },

    f_bodyarmor_mugen1_8 = {
        female = {
            bodyArmor = { drawable = 569, texture = 8 },
        },
    },

    f_bodyarmor_mugen1_9 = {
        female = {
            bodyArmor = { drawable = 569, texture = 9 },
        },
    },

    f_bodyarmor_mugen1_10 = {
        female = {
            bodyArmor = { drawable = 569, texture = 10 },
        },
    },

    f_bodyarmor_mugen1_11 = {
        female = {
            bodyArmor = { drawable = 569, texture = 11 },
        },
    },

    f_bodyarmor_mugen1_12 = {
        female = {
            bodyArmor = { drawable = 569, texture = 12 },
        },
    },

    f_bodyarmor_blacklotus1 = {
        female = {
            bodyArmor = { drawable = 572, texture = 0 },
        },
    },

    f_bodyarmor_wdmc1_0 = {
        female = {
            bodyArmor = { drawable = 579, texture = 0 },
        },
    },

    f_bodyarmor_wdmc1_1 = {
        female = {
            bodyArmor = { drawable = 579, texture = 1 },
        },
    },

    f_bodyarmor_wdmc1_2 = {
        female = {
            bodyArmor = { drawable = 579, texture = 2 },
        },
    },

    f_bodyarmor_wdmc1_3 = {
        female = {
            bodyArmor = { drawable = 579, texture = 3 },
        },
    },

    f_bodyarmor_wdmc1_4 = {
        female = {
            bodyArmor = { drawable = 579, texture = 4 },
        },
    },

    f_bodyarmor_wdmc1_5 = {
        female = {
            bodyArmor = { drawable = 579, texture = 5 },
        },
    },

    f_bodyarmor_fsg1 = {
        female = {
            bodyArmor = { drawable = 580, texture = 0 },
        },
    },

    f_bodyarmor_nsn1 = {
        female = {
            bodyArmor = { drawable = 585, texture = 0 },
        },
    },

    f_bodyarmor_karabas1 = {
        female = {
            bodyArmor = { drawable = 586, texture = 0 },
        },
    },

    f_bodyarmor_ryc1_0 = {
        female = {
            bodyArmor = { drawable = 598, texture = 0 },
        },
    },

    f_bodyarmor_ryc1_1 = {
        female = {
            bodyArmor = { drawable = 598, texture = 1 },
        },
    },

    f_bodyarmor_thez1 = {
        female = {
            bodyArmor = { drawable = 644, texture = 0 },
        },
    },

    f_bodyarmor_mx691 = {
        female = {
            bodyArmor = { drawable = 651, texture = 0 },
        },
    },

    f_bodyarmor_cravell1_0 = {
        female = {
            bodyArmor = { drawable = 652, texture = 0 },
        },
    },

    f_bodyarmor_cravell1_1 = {
        female = {
            bodyArmor = { drawable = 652, texture = 1 },
        },
    },

    f_bodyarmor_cravell1_2 = {
        female = {
            bodyArmor = { drawable = 652, texture = 2 },
        },
    },

    f_bodyarmor_cravell1_3 = {
        female = {
            bodyArmor = { drawable = 652, texture = 3 },
        },
    },

    f_bodyarmor_cravell1_4 = {
        female = {
            bodyArmor = { drawable = 652, texture = 4 },
        },
    },

    f_bodyarmor_cravell1_5 = {
        female = {
            bodyArmor = { drawable = 652, texture = 5 },
        },
    },

    f_bodyarmor_cravell1_6 = {
        female = {
            bodyArmor = { drawable = 652, texture = 6 },
        },
    },

    f_bodyarmor_cravell1_7 = {
        female = {
            bodyArmor = { drawable = 652, texture = 7 },
        },
    },

    f_bodyarmor_invamouz1_0 = {
        female = {
            bodyArmor = { drawable = 658, texture = 0 },
        },
    },

    f_bodyarmor_invamouz1_1 = {
        female = {
            bodyArmor = { drawable = 658, texture = 1 },
        },
    },

    f_bodyarmor_invamouz1_2 = {
        female = {
            bodyArmor = { drawable = 658, texture = 2 },
        },
    },

    f_bodyarmor_invamouz1_3 = {
        female = {
            bodyArmor = { drawable = 658, texture = 3 },
        },
    },

    f_bodyarmor_invamouz1_4 = {
        female = {
            bodyArmor = { drawable = 658, texture = 4 },
        },
    },

    f_bodyarmor_invamouz1_5 = {
        female = {
            bodyArmor = { drawable = 658, texture = 5 },
        },
    },

    f_bodyarmor_invamouz1_6 = {
        female = {
            bodyArmor = { drawable = 658, texture = 6 },
        },
    },

    f_bodyarmor_invamouz1_7 = {
        female = {
            bodyArmor = { drawable = 658, texture = 7 },
        },
    },

    f_bodyarmor_invamouz1_8 = {
        female = {
            bodyArmor = { drawable = 658, texture = 8 },
        },
    },

    f_bodyarmor_shellby1 = {
        female = {
            bodyArmor = { drawable = 662, texture = 0 },
        },
    },

    f_bodyarmor_brg1 = {
        female = {
            bodyArmor = { drawable = 668, texture = 0 },
        },
    },

    f_bodyarmor_nagasaki1 = {
        female = {
            bodyArmor = { drawable = 682, texture = 0 },
        },
    },

    f_bodyarmor_sos1 = {
        female = {
            bodyArmor = { drawable = 683, texture = 0 },
        },
    },

    f_bodyarmor_hakuryu1 = {
        female = {
            bodyArmor = { drawable = 685, texture = 0 },
        },
    },

    f_jackets_karabas2 = {
        female = {
            bodyArmor = { drawable = 687, texture = 0 }, 
        },
    },

    f_bodyarmor_youngmc1_0 = {
        female = {
            bodyArmor = { drawable = 688, texture = 0 },
        },
    },

    f_bodyarmor_youngmc1_1 = {
        female = {
            bodyArmor = { drawable = 688, texture = 1 },
        },
    },

    f_bodyarmor_youngmc1_2 = {
        female = {
            bodyArmor = { drawable = 688, texture = 2 },
        },
    },

    f_bodyarmor_youngmc1_3 = {
        female = {
            bodyArmor = { drawable = 688, texture = 3 },
        },
    },

    f_bodyarmor_youngmc1_4 = {
        female = {
            bodyArmor = { drawable = 688, texture = 4 },
        },
    },

    f_bodyarmor_youngmc1_5 = {
        female = {
            bodyArmor = { drawable = 688, texture = 5 },
        },
    },

    f_bodyarmor_youngmc1_6 = {
        female = {
            bodyArmor = { drawable = 688, texture = 6 },
        },
    },

    f_bodyarmor_youngmc1_7 = {
        female = {
            bodyArmor = { drawable = 688, texture = 7 },
        },
    },

    f_bodyarmor_r9691 = {
        female = {
            bodyArmor = { drawable = 691, texture = 0 },
        },
    },
}
