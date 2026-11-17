return {
    ["usmarshal"] = {
        label = "BossMenu Shop",
        inventory = {
            { name = 'badgehighcommandusms', price = 1 },
            { name = 'badgeftfusmsnew', price = 1 },
            { name = 'badgeiodusms', price = 1 },
            { name = 'badgeheliusms', price = 1 },
            { name = 'badgevehusmsnew', price = 1 },
        },
        groups = { usmarshal = 5 },
    },
    ["musicsm"] = {
        label = "BossMenu Shop",
        inventory = {
            { name = 'microphone', price = 1 },
        },
        groups = { musicsm = 3 },
    },
    ["police"] = {
        label = "Police Equipment Shop",
        inventory = {
            { name = 'pdtablet',           price = 50, grade = 17 },
            { name = 'badgeshc',           price = 50 },
            { name = 'badgeswatlspd',      price = 50 },
            { name = 'badgedetective',     price = 50 },
            { name = 'badgeiaf',           price = 50 },
            { name = 'badgehelicopter',    price = 50 },
            { name = 'badgeinterceptor',   price = 50 },
            { name = 'badgepaspampres',    price = 50 },
        },
        groups = { police = 12 },
    },
    ["velvetsm"] = {
        label = "BossMenu Shop",
        inventory = {
            { name = 'casino_chips', price = 1 },
        },
        groups = { velvetsm = 2 },
    },
    ["lfasm"] = {
        label = "BossMenu Shop",
        inventory = {
            -- Male Jackets LFA
            { name = 'm_jackets_lfa1',       price = 55000, currency = 'red_money' },
            { name = 'm_jackets_lfa2',       price = 55000, currency = 'red_money' },
            -- Female Jackets LFA
            { name = 'f_jackets_lfa1',       price = 55000, currency = 'red_money' },
            { name = 'f_jackets_lfa2',       price = 55000, currency = 'red_money' },
            -- Male Body Armor LFA
            { name = 'm_bodyarmor_lfa1',     price = 55000, currency = 'red_money' },
            -- Female Body Armor LFA
            { name = 'f_bodyarmor_lfa1',     price = 55000, currency = 'red_money' },

            { name = 'm_jackets_gehanom1',   price = 55000, currency = 'red_money' },
            { name = 'm_jackets_gehanom2',   price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_gehanom1', price = 55000, currency = 'red_money' },
            { name = 'f_jackets_gehanom1',   price = 55000, currency = 'red_money' },
            { name = 'f_jackets_gehanom2',   price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_gehanom1', price = 55000, currency = 'red_money' },

        },
        groups = { lfasm = 3 },
    },
    -- ["bzsm"] = {
    --     label = "BossMenu Shop",
    --     inventory = {
    --         -- Male Jackets BZ
    --         { name = 'm_jackets_bz1_0',     price = 55000, currency = 'red_money' },
    --         { name = 'm_jackets_bz1_1',     price = 55000, currency = 'red_money' },
    --         { name = 'm_jackets_bz1_2',     price = 55000, currency = 'red_money' },
    --         { name = 'm_jackets_bz2_0',     price = 55000, currency = 'red_money' },
    --         { name = 'm_jackets_bz2_1',     price = 55000, currency = 'red_money' },
    --         { name = 'm_jackets_bz2_2',     price = 55000, currency = 'red_money' },
    --         { name = 'm_jackets_bzmc1',     price = 55000, currency = 'red_money' },
    --         -- Female Jackets BZ
    --         { name = 'f_jackets_bz1_0',     price = 55000, currency = 'red_money' },
    --         { name = 'f_jackets_bz1_1',     price = 55000, currency = 'red_money' },
    --         { name = 'f_jackets_bz1_2',     price = 55000, currency = 'red_money' },
    --         { name = 'f_jackets_bz2_0',     price = 55000, currency = 'red_money' },
    --         { name = 'f_jackets_bz2_1',     price = 55000, currency = 'red_money' },
    --         { name = 'f_jackets_bz2_2',     price = 55000, currency = 'red_money' },
    --         { name = 'f_jackets_bzmc1',     price = 55000, currency = 'red_money' },
    --         -- Male Body Armor BZ
    --         { name = 'm_bodyarmor_bz1_0',   price = 55000, currency = 'red_money' },
    --         { name = 'm_bodyarmor_bz1_1',   price = 55000, currency = 'red_money' },
    --         { name = 'm_bodyarmor_bz1_2',   price = 55000, currency = 'red_money' },
    --         { name = 'm_bodyarmor_bzmc1_0', price = 55000, currency = 'red_money' },
    --         { name = 'm_bodyarmor_bzmc1_1', price = 55000, currency = 'red_money' },
    --         { name = 'm_bodyarmor_bzmc1_2', price = 55000, currency = 'red_money' },
    --         { name = 'm_bodyarmor_bzmc1_3', price = 55000, currency = 'red_money' },
    --         { name = 'm_bodyarmor_bzmc1_4', price = 55000, currency = 'red_money' },
    --         { name = 'm_bodyarmor_bzmc1_5', price = 55000, currency = 'red_money' },
    --         { name = 'm_bodyarmor_bzmc1_6', price = 55000, currency = 'red_money' },
    --         { name = 'm_bodyarmor_bzmc1_7', price = 55000, currency = 'red_money' },
    --         -- Female Body Armor BZ
    --         { name = 'f_bodyarmor_bz1_0',   price = 55000, currency = 'red_money' },
    --         { name = 'f_bodyarmor_bz1_1',   price = 55000, currency = 'red_money' },
    --         { name = 'f_bodyarmor_bz1_2',   price = 55000, currency = 'red_money' },
    --         { name = 'f_bodyarmor_bzmc1_0', price = 55000, currency = 'red_money' },
    --         { name = 'f_bodyarmor_bzmc1_1', price = 55000, currency = 'red_money' },
    --         { name = 'f_bodyarmor_bzmc1_2', price = 55000, currency = 'red_money' },
    --         { name = 'f_bodyarmor_bzmc1_3', price = 55000, currency = 'red_money' },
    --         { name = 'f_bodyarmor_bzmc1_4', price = 55000, currency = 'red_money' },
    --         { name = 'f_bodyarmor_bzmc1_5', price = 55000, currency = 'red_money' },
    --         { name = 'f_bodyarmor_bzmc1_6', price = 55000, currency = 'red_money' },
    --         { name = 'f_bodyarmor_bzmc1_7', price = 55000, currency = 'red_money' },
    --     },
    --     groups = { bzsm = 3 },
    -- },
    ["karabassm"] = {
        label = "BossMenu Shop",
        inventory = {
            { name = 'm_bodyarmor_karabas1', price = 55000, currency = 'red_money' },
            { name = 'm_jackets_karabas1', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_karabas1', price = 55000, currency = 'red_money' },
            { name = 'f_jackets_karabas1', price = 55000, currency = 'red_money' },
            { name = 'f_jackets_karabas2', price = 55000, currency = 'red_money' },
        },
        groups = { karabassm = 3 },
    },
    -- ["nightwalkersm"] = {
    --     label = "BossMenu Shop",
    --     inventory = {
    --         { name = 'elfanberry', price = 55000 },
    --         { name = 'elfblood', price = 55000 },
    --         { name = 'kristaldust', price = 55000 },
    --         { name = 'moonleaf', price = 55000 },
    --         { name = 'moonwater', price = 55000 },
    --         { name = 'silverwood', price = 55000 },
    --         { name = 'starflower', price = 55000 },
    --     },
    --     groups = { nightwalkersm = 7 },
    -- },
    ["rbsm"] = {
        label = "BossMenu Shop",
        inventory = {
            -- -- Male Shirts RB
            -- { name = 'm_shirts_rb',     price = 55000, currency = 'red_money' },
            -- -- Female Shirts RB
            -- { name = 'f_shirts_rb',     price = 55000, currency = 'red_money' },
            -- -- Male Jackets RB
            -- { name = 'm_jackets_rb1',   price = 55000, currency = 'red_money' },
            -- -- Female Jackets RB
            -- { name = 'f_jackets_rb1',   price = 55000, currency = 'red_money' },
            -- -- Male Body Armor RB
            -- { name = 'm_bodyarmor_rb1', price = 55000, currency = 'red_money' },
            -- Female Jackets Nagasaki
            { name = 'f_jackets_nagasaki1',   price = 55000, currency = 'red_money' },
            { name = 'f_jackets_nagasaki2',   price = 55000, currency = 'red_money' },
            -- Male Jackets Nagasaki
            { name = 'm_jackets_nagasaki1', price = 55000, currency = 'red_money' },
            { name = 'm_jackets_nagasaki2', price = 55000, currency = 'red_money' },
            -- Female Body Armor Nagasaki
            { name = 'm_bodyarmor_nagasaki1',   price = 55000, currency = 'red_money' },
            -- Male Body Armor Nagasaki
            { name = 'f_bodyarmor_nagasaki1', price = 55000, currency = 'red_money' },
        },
        groups = { rbsm = 3 },
    },
    ["shinraism"] = {
        label = "BossMenu Shop",
        inventory = {
            -- Male Shirts RB
            { name = 'm_bodyarmor_shinrai', price = 55000, currency = 'red_money' },
            -- Female Shirts RB
            { name = 'm_jackets_shinrai',   price = 55000, currency = 'red_money' },
            -- Male Jackets RB
            { name = 'm_bags_shinrai',      price = 55000, currency = 'red_money' },
            -- Female Jackets RB
            { name = 'f_bodyarmor_shinrai', price = 55000, currency = 'red_money' },
            -- Male Body Armor RB
            { name = 'f_jackets_shinrai',   price = 55000, currency = 'red_money' },

            { name = 'f_bags_shinrai',      price = 55000, currency = 'red_money' },

        },
        groups = { shinraism = 7 },
    },
    -- ["blacklotussm"] = {
    --     label = "BossMenu Shop",
    --     inventory = {
    --         { name = 'm_jackets_ht1',   price = 55000, currency = 'red_money' },
    --         { name = 'm_jackets_ht2',   price = 55000, currency = 'red_money' },
    --         { name = 'f_jackets_ht1_0', price = 55000, currency = 'red_money' },
    --         { name = 'f_jackets_ht1_1', price = 55000, currency = 'red_money' },
    --         { name = 'f_jackets_ht1_2', price = 55000, currency = 'red_money' },
    --         { name = 'f_jackets_ht2',   price = 55000, currency = 'red_money' },
    --         { name = 'f_bodyarmor_blacklotus1',   price = 55000, currency = 'red_money' },
    --     },
    --     groups = { blacklotussm = 5 },
    -- },
    ["bxdsm"] = {
        label = "BossMenu Shop",
        inventory = {
            { name = 'm_bodyarmor_bxd', price = 55000, currency = 'red_money' },
            { name = 'm_jackets_bxd2',  price = 55000, currency = 'red_money' },
            { name = 'm_jackets_bxd1',  price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_bxd', price = 55000, currency = 'red_money' },
            { name = 'f_jackets_bxd2',  price = 55000, currency = 'red_money' },
            { name = 'f_jackets_bxd1',  price = 55000, currency = 'red_money' },
        },
        groups = { bxdsm = 4 },
    },
    ["gardapatism"] = {
        label = "BossMenu Shop",
        inventory = {
            { name = 'm_jackets_gdp1', price = 55000, currency = 'red_money' },
            { name = 'f_jackets_gdp1', price = 55000, currency = 'red_money' },
        },
        groups = { gardapatism = 5 },
    },
    ["bbysm"] = {
        label = "BossMenu Shop",
        inventory = {
            { name = 'm_bodyarmor_babayo1', price = 55000, currency = 'red_money' },
            { name = 'm_jackets_babayo1',   price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_babayo1', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_babayo2', price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_babayo2', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_babayo3', price = 55000, currency = 'red_money' },
            { name = 'm_jackets_babayo2',   price = 55000, currency = 'red_money' },
            { name = 'f_jackets_babayo1_0', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_babayo4', price = 55000, currency = 'red_money' },
        },
        groups = { bbysm = 3 },
    },
    ["limitlessm"] = {
        label = "BossMenu Shop",
        inventory = {
            -- Jackets LS (existing)
            { name = 'm_jackets_ls1',   price = 55000, currency = 'red_money' },
            { name = 'f_jackets_ls1',   price = 55000, currency = 'red_money' },

            -- Male LS
            { name = 'm_bodyarmor_ls1', price = 55000, currency = 'red_money' },
            { name = 'm_bags_ls1_0',    price = 55000, currency = 'red_money' },
            { name = 'm_bags_ls1_1',    price = 55000, currency = 'red_money' },

            -- Female LS
            { name = 'f_bodyarmor_ls1', price = 55000, currency = 'red_money' },
            { name = 'f_bags_ls1_0',    price = 55000, currency = 'red_money' },
            { name = 'f_bags_ls1_1',    price = 55000, currency = 'red_money' },
        },
        groups = { limitlessm = 6 },
    },
    -- ["bratvasm"] = {
    --     label = "BossMenu Shop",
    --     inventory = {
    --         -- Male Jackets Bratva
    --         { name = 'm_jackets_brv1_0', price = 55000, currency = 'red_money' },
    --         { name = 'm_jackets_brv1_1', price = 55000, currency = 'red_money' },
    --         { name = 'm_jackets_brv2',   price = 55000, currency = 'red_money' },
    --         -- Female Jackets Bratva
    --         { name = 'f_jackets_brv1_0', price = 55000, currency = 'red_money' },
    --         { name = 'f_jackets_brv1_1', price = 55000, currency = 'red_money' },
    --         { name = 'f_jackets_brv2',   price = 55000, currency = 'red_money' },
    --         -- Male Body Armor Bratva
    --         { name = 'm_bodyarmor_brv',  price = 55000, currency = 'red_money' },
    --         -- Female Body Armor Bratva
    --         { name = 'f_bodyarmor_brv',  price = 55000, currency = 'red_money' },
    --     },
    --     groups = { bratvasm = 3 },
    -- },
    ["heavenhellsm"] = {
        label = "BossMenu Shop",
        inventory = {
            -- Male HeavenHell
            { name = 'm_jackets_heavenhell1',     price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_heavenhell1_0', price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_heavenhell1_1', price = 55000, currency = 'red_money' },
            { name = 'm_pants_heavenhell1',       price = 55000, currency = 'red_money' },

            -- Female HeavenHell
            { name = 'f_jackets_heavenhell1',     price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_heavenhell1_0', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_heavenhell1_1', price = 55000, currency = 'red_money' },
            { name = 'f_pants_heavenhell1',       price = 55000, currency = 'red_money' },
        },
        groups = { heavenhellsm = 3 },
    },

    ["wtsm"] = {
        label = "BossMenu Shop",
        inventory = {
            { name = 'm_jackets_wtmc1',         price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_wtmc1_0',     price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_wtmc1_1',     price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_wtmc1_2',     price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_wtmc1_3',     price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_wtmc1_4',     price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_wtmc1_5',     price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_wtmc1_6',     price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_wtmc1_7',     price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_wtmc1_8',     price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_wtmc1_9',     price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_wtmc1_10',    price = 55000, currency = 'red_money' },
            { name = 'f_jackets_wtmc1',         price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_wtmc1_0',     price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_wtmc1_1',     price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_wtmc1_2',     price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_wtmc1_3',     price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_wtmc1_4',     price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_wtmc1_5',     price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_wtmc1_6',     price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_wtmc1_7',     price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_wtmc1_8',     price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_wtmc1_9',     price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_wtmc1_10',    price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_whitetiger1', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_whitetiger1', price = 55000, currency = 'red_money' },
        },
        groups = { wtsm = 3 },
    },

    ["omcsm"] = {
        label = "BossMenu Shop",
        inventory = {
            -- Male Jackets OMC
            { name = 'm_jackets_omc1',     price = 55000, currency = 'red_money' },
            -- Female Jackets OMC
            { name = 'f_jackets_omc1',     price = 55000, currency = 'red_money' },
            -- Male Body Armor OMC1
            { name = 'm_bodyarmor_omc1_0', price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_omc1_1', price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_omc1_2', price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_omc1_3', price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_omc1_4', price = 55000, currency = 'red_money' },
            -- Female Body Armor OMC1
            { name = 'f_bodyarmor_omc1_0', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_omc1_1', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_omc1_2', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_omc1_3', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_omc1_4', price = 55000, currency = 'red_money' },
            -- Male Body Armor OMC2
            { name = 'm_bodyarmor_omc2_0', price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_omc2_1', price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_omc2_2', price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_omc2_3', price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_omc2_4', price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_omc2_5', price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_omc2_6', price = 55000, currency = 'red_money' },
            -- Female Body Armor OMC2
            { name = 'f_bodyarmor_omc2_0', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_omc2_1', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_omc2_2', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_omc2_3', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_omc2_4', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_omc2_5', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_omc2_6', price = 55000, currency = 'red_money' },

            { name = 'm_bodyarmor_omc2_7', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_omc2_7', price = 55000, currency = 'red_money' },
            
            { name = 'm_jackets_umc1',     price = 55000, currency = 'red_money' },
            { name = 'f_jackets_umc1',     price = 55000, currency = 'red_money' },
        },
        groups = { omcsm = 6 },
    },
    ["ggdsm"] = {
        label = "BossMenu Shop",
        inventory = {
            { name = 'm_pants_ggd',     price = 55000, currency = 'red_money' },
            { name = 'm_jackets_ggd1',  price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_ggd', price = 55000, currency = 'red_money' },
            { name = 'f_pants_ggd',     price = 55000, currency = 'red_money' },
            { name = 'f_jackets_ggd1',  price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_ggd', price = 55000, currency = 'red_money' },
        },
        groups = { ggdsm = 3 },
    },
    ["sdmcsm"] = {
        label = "BossMenu Shop",
        inventory = {
            { name = 'm_jackets_sdmc1',     price = 55000, currency = 'red_money' },
            { name = 'm_jackets_sdmc2',     price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_sdmc1_0', price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_sdmc1_1', price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_sdmc1_2', price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_sdmc1_3', price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_sdmc1_4', price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_sdmc1_5', price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_sdmc1_6', price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_sdmc1_7', price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_sdmc1_8', price = 55000, currency = 'red_money' },
            { name = 'f_jackets_sdmc1',     price = 55000, currency = 'red_money' },
            { name = 'f_jackets_sdmc2',     price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_sdmc1_0', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_sdmc1_1', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_sdmc1_2', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_sdmc1_3', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_sdmc1_4', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_sdmc1_5', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_sdmc1_6', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_sdmc1_7', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_sdmc1_8', price = 55000, currency = 'red_money' },
        },
        groups = { sdmcsm = 6 },
    },
    -- ["blfsm"] = {
    --     label = "BossMenu Shop",
    --     inventory = {
    --         -- Male Items Burgenk
    --         { name = 'm_bags_bfl',      price = 55000, currency = 'red_money' },
    --         { name = 'm_jackets_bfl',   price = 55000, currency = 'red_money' },
    --         { name = 'm_bodyarmor_bfl', price = 55000, currency = 'red_money' },
    --         -- Female Items Burgenk
    --         { name = 'f_bags_bfl',      price = 55000, currency = 'red_money' },
    --         { name = 'f_jackets_bfl',   price = 55000, currency = 'red_money' },
    --         { name = 'f_bodyarmor_bfl', price = 55000, currency = 'red_money' },

    --         { name = 'm_jackets_nsn1', price = 55000, currency = 'red_money' },
    --         { name = 'm_bodyarmor_nsn1', price = 55000, currency = 'red_money' },
    --         { name = 'f_jackets_nsn1', price = 55000, currency = 'red_money' },
    --         { name = 'f_jackets_nsn2', price = 55000, currency = 'red_money' },
    --         { name = 'f_bodyarmor_nsn1', price = 55000, currency = 'red_money' },
    --     },
    --     groups = { blfsm = 4 },
    -- },
    ["kuroyamasm"] = {
        label = "BossMenu Shop",
        inventory = {
            -- Male Jackets Kuroyama
            { name = 'm_jackets_kuroyama1', price = 55000, currency = 'red_money' },
            -- Female Jackets Kuroyama
            { name = 'f_jackets_kuroyama1', price = 55000, currency = 'red_money' },
        },
        groups = { kuroyamasm = 3 },
    },
    ["blackjacksm"] = {
        label = "BossMenu Shop",
        inventory = {
            { name = 'm_jackets_blackjack1', price = 55000, currency = 'red_money' },
            { name = 'm_jackets_blackjack2', price = 55000, currency = 'red_money' },
            { name = 'm_jackets_blackjack3', price = 55000, currency = 'red_money' },
            { name = 'm_jackets_blackjack4', price = 55000, currency = 'red_money' },
            { name = 'f_jackets_blackjack1', price = 55000, currency = 'red_money' },
            { name = 'f_jackets_blackjack2', price = 55000, currency = 'red_money' },
            { name = 'f_jackets_blackjack3', price = 55000, currency = 'red_money' },
            { name = 'f_jackets_blackjack4', price = 55000, currency = 'red_money' },
        },
        groups = { blackjacksm = 4 },
    },
    ["crsm"] = {
        label = "BossMenu Shop",
        inventory = {
            { name = 'm_jackets_crimsonreign1_0', price = 55000, currency = 'red_money' },
            { name = 'm_jackets_crimsonreign1_1', price = 55000, currency = 'red_money' },
            { name = 'f_jackets_crimsonreign1_0', price = 55000, currency = 'red_money' },
            { name = 'f_jackets_crimsonreign1_1', price = 55000, currency = 'red_money' },
        },
        groups = { crsm = 4 },
    },
    ["nexusm"] = {
        label = "BossMenu Shop",
        inventory = {
            -- Male Masks Nexus (Bandana)
            { name = 'm_masks_nexus',      price = 55000, currency = 'red_money' },
            -- Female Masks Nexus (Bandana)
            { name = 'f_masks_nexus',      price = 55000, currency = 'red_money' },
            -- Male Jackets Nexus
            { name = 'm_jackets_nexus1',   price = 55000, currency = 'red_money' },
            -- Female Jackets Nexus
            { name = 'f_jackets_nexus1',   price = 55000, currency = 'red_money' },
            -- Male Body Armor Nexus
            { name = 'm_bodyarmor_nexus1', price = 55000, currency = 'red_money' },
            -- Female Body Armor Nexus
            { name = 'f_bodyarmor_nexus1', price = 55000, currency = 'red_money' },
        },
        groups = { nexusm = 4 },
    },
    ["freelinksm"] = {
        label = "BossMenu Shop",
        inventory = {
            { name = 'm_jackets_fleelinks1', price = 55000, currency = 'red_money' },
            { name = 'f_jackets_fleelinks1', price = 55000, currency = 'red_money' },
            { name = 'm_jackets_fleelinks2', price = 55000, currency = 'red_money' },
            { name = 'f_jackets_fleelinks2', price = 55000, currency = 'red_money' },
            { name = 'm_jackets_fleelinks3', price = 55000, currency = 'red_money' },
            { name = 'f_jackets_fleelinks3', price = 55000, currency = 'red_money' },
        },
        groups = { freelinksm = 4 },
    },
    -- ["lanoirsm"] = {
    --     label = "BossMenu Shop",
    --     inventory = {
    --         { name = 'm_jackets_larosenoir1', price = 55000, currency = 'red_money' },
    --         { name = 'f_jackets_larosenoir1', price = 55000, currency = 'red_money' },
    --     },
    --     groups = { lanoirsm = 7 },
    -- },
    ["snakeflowersm"] = {
        label = "BossMenu Shop",
        inventory = {
            { name = 'm_bodyarmor_sfc1_0', price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_sfc1_1', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_sfc1_0', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_sfc1_1', price = 55000, currency = 'red_money' },
            
            { name = 'm_jackets_hakuryu1', price = 55000, currency = 'red_money' },
            { name = 'f_jackets_hakuryu1', price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_hakuryu1', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_hakuryu1', price = 55000, currency = 'red_money' },
        },
        groups = { snakeflowersm = 4 },
    },
    ["fsgsm"] = {
        label = "BossMenu Shop",
        inventory = {
            { name = 'f_bodyarmor_fsg1', price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_fsg1', price = 55000, currency = 'red_money' },
            { name = 'm_teef_fsg1',      price = 55000, currency = 'red_money' },
            { name = 'f_teef_fsg1',      price = 55000, currency = 'red_money' },
            { name = 'm_jackets_fsg1',   price = 55000, currency = 'red_money' },
            { name = 'f_jackets_fsg1',   price = 55000, currency = 'red_money' },
        },
        groups = { fsgsm = 4 },
    },
    ["shellbysm"] = {
        label = "BossMenu Shop",
        inventory = {
            { name = 'm_bags_shellby', price = 55000, currency = 'red_money' },
            { name = 'f_bags_shellby', price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_shellby1', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_shellby1', price = 55000, currency = 'red_money' },
        },
        groups = { shellbysm = 5 },
    },
    -- ["invism"] = {
    --     label = "BossMenu Shop",
    --     inventory = {
    --         -- { name = 'm_jackets_invictus1', price = 55000, currency = 'red_money' },
    --         -- { name = 'f_jackets_invictus1', price = 55000, currency = 'red_money' },
    --         { name = 'm_jackets_vanity1',   price = 55000, currency = 'red_money' },
    --         { name = 'f_jackets_vanity1',   price = 55000, currency = 'red_money' },
    --     },
    --     groups = { invism = 3 },
    -- },
    ["rcsm"] = {
        label = "BossMenu Shop",
        inventory = {
            { name = 'm_bodyarmor_ryc1_0', price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_ryc1_1', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_ryc1_0', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_ryc1_1', price = 55000, currency = 'red_money' },
        },
        groups = { rcsm = 4 },
    },
    ["wildsm"] = {
        label = "BossMenu Shop",
        inventory = {
            { name = 'm_bodyarmor_wdmc1_0', price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_wdmc1_1', price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_wdmc1_2', price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_wdmc1_3', price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_wdmc1_4', price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_wdmc1_5', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_wdmc1_0', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_wdmc1_1', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_wdmc1_2', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_wdmc1_3', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_wdmc1_4', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_wdmc1_5', price = 55000, currency = 'red_money' },
        },
        groups = { wildsm = 4 },
    },
    ["pamsm"] = {
        label = "BossMenu Shop",
        inventory = {
            -- Male Jackets PAM
            { name = 'm_jackets_pam1_0', price = 55000, currency = 'red_money' },
            { name = 'm_jackets_pam1_1', price = 55000, currency = 'red_money' },
            -- Female Jackets PAM
            { name = 'f_jackets_pam1_0', price = 55000, currency = 'red_money' },
            { name = 'f_jackets_pam1_1', price = 55000, currency = 'red_money' },

            { name = 'm_jackets_brg1_0', price = 55000, currency = 'red_money' },
            { name = 'm_jackets_brg1_1', price = 55000, currency = 'red_money' },
            { name = 'f_jackets_brg1_0', price = 55000, currency = 'red_money' },
            { name = 'f_jackets_brg1_1', price = 55000, currency = 'red_money' },

            -- Male Bodyarmor BRG
            { name = 'm_bodyarmor_brg1', price = 55000, currency = 'red_money' },
            -- Female Bodyarmor BRG
            { name = 'f_bodyarmor_brg1', price = 55000, currency = 'red_money' },
        },
        groups = { pamsm = 3 },
    },
    ["ffysm"] = {
        label = "BossMenu Shop",
        inventory = {
            { name = 'm_jackets_ffy1',     price = 55000, currency = 'red_money' },
            { name = 'm_jackets_phoenix1', price = 55000, currency = 'red_money' },
            { name = 'f_jackets_phoenix1', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_ffy1',   price = 55000, currency = 'red_money' },
        },
        groups = { ffysm = 3 },
    },
    -- ["thezsm"] = {
    --     label = "BossMenu Shop",
    --     inventory = {
    --         { name = 'f_bodyarmor_thez1',     price = 55000, currency = 'red_money' },
    --         { name = 'm_bodyarmor_thez1', price = 55000, currency = 'red_money' },
    --     },
    --     groups = { thezsm = 9 },
    -- },
    ["shadowsm"] = {
        label = "BossMenu Shop",
        inventory = {
            { name = 'm_bodyarmor_rmc1_0', price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_rmc1_1', price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_rmc1_2', price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_rmc1_3', price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_rmc1_4', price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_rmc1_5', price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_rmc1_6', price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_rmc1_7', price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_rmc1_8', price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_rmc1_9', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_rmc1_0', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_rmc1_1', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_rmc1_2', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_rmc1_3', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_rmc1_4', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_rmc1_5', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_rmc1_6', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_rmc1_7', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_rmc1_8', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_rmc1_9', price = 55000, currency = 'red_money' },
            -- Male Jackets RMC (Redemption MC)
            { name = 'm_jackets_rmc1',     price = 55000, currency = 'red_money' },
            -- Female Body Armor RMC (Redemption MC)
            { name = 'f_bodyarmor_rmc2',   price = 55000, currency = 'red_money' },
        },
        groups = { shadowsm = 5 },
    },
    ["abyssm"] = {
        label = "BossMenu Shop",
        inventory = {
            -- Male Jackets Abyssal
            { name = 'm_jackets_abyssal1',   price = 55000, currency = 'red_money' },
            { name = 'm_jackets_abyssal2',   price = 55000, currency = 'red_money' },
            -- Female Jackets Abyssal
            { name = 'f_jackets_abyssal1',   price = 55000, currency = 'red_money' },
            { name = 'f_jackets_abyssal2',   price = 55000, currency = 'red_money' },
            -- Male Body Armor Abyssal
            { name = 'm_bodyarmor_abyssal1', price = 55000, currency = 'red_money' },
            -- Female Body Armor Abyssal
            { name = 'f_bodyarmor_abyssal1', price = 55000, currency = 'red_money' },
        },
        groups = { abyssm = 3 },
    },
    ["ctfsm"] = {
        label = "BossMenu Shop",
        inventory = {
            -- Male Jackets Cortize
            { name = 'm_jackets_cortize1', price = 55000, currency = 'red_money' },
            { name = 'm_jackets_cortize2', price = 55000, currency = 'red_money' },
            -- Female Jackets Cortize
            { name = 'f_jackets_cortize1', price = 55000, currency = 'red_money' },
            { name = 'f_jackets_cortize2', price = 55000, currency = 'red_money' },
        },
        groups = { ctfsm = 7 },
    },
    ["soumcsm"] = {
        label = "BossMenu Shop",
        inventory = {
            -- Male Jackets SOU MC
            { name = 'm_jackets_soumc1', price = 55000, currency = 'red_money' },
            -- Female Jackets SOU MC
            { name = 'f_jackets_soumc1', price = 55000, currency = 'red_money' },
        },
        groups = { soumcsm = 5 },
    },
    ["mugensm"] = {
        label = "BossMenu Shop",
        inventory = {
            -- Male Body Armor Mugen
            { name = 'm_bodyarmor_mugen1_0',  price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_mugen1_1',  price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_mugen1_2',  price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_mugen1_3',  price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_mugen1_4',  price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_mugen1_5',  price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_mugen1_6',  price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_mugen1_7',  price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_mugen1_8',  price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_mugen1_9',  price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_mugen1_10', price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_mugen1_11', price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_mugen1_12', price = 55000, currency = 'red_money' },
            -- Female Body Armor Mugen
            { name = 'f_bodyarmor_mugen1_0',  price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_mugen1_1',  price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_mugen1_2',  price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_mugen1_3',  price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_mugen1_4',  price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_mugen1_5',  price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_mugen1_6',  price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_mugen1_7',  price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_mugen1_8',  price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_mugen1_9',  price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_mugen1_10', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_mugen1_11', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_mugen1_12', price = 55000, currency = 'red_money' },
        },
        groups = { mugensm = 5 },
    },
    ["jdmcsm"] = {
        label = "BossMenu Shop",
        inventory = {
            -- Male Jackets JDMC
            { name = 'm_jackets_jdmc1', price = 55000, currency = 'red_money' },
            { name = 'm_jackets_jdmc2', price = 55000, currency = 'red_money' },
            { name = 'm_jackets_jdmc3', price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_jdmc1', price = 55000, currency = 'red_money' },
            -- Female Jackets JDMC
            { name = 'f_jackets_jdmc1', price = 55000, currency = 'red_money' },
            { name = 'f_jackets_jdmc2', price = 55000, currency = 'red_money' },
            { name = 'f_jackets_jdmc3', price = 55000, currency = 'red_money' },
        },
        groups = { jdmcsm = 5 },
    },
    -- ["mx69sm"] = {
    --     label = "BossMenu Shop",
    --     inventory = {
    --         -- Male Vest MX69
    --         { name = 'm_bodyarmor_mx691', price = 55000, currency = 'red_money' },
    --         -- Female Vest MX69
    --         { name = 'f_bodyarmor_mx691', price = 55000, currency = 'red_money' },
    --     },
    --     groups = { mx69sm = 4 },
    -- },
    -- ["cravelsm"] = {
    --     label = "BossMenu Shop",
    --     inventory = {
    --         -- Male Vest Cravell
    --         { name = 'm_bodyarmor_cravell1_0', price = 55000, currency = 'red_money' },
    --         { name = 'm_bodyarmor_cravell1_1', price = 55000, currency = 'red_money' },
    --         { name = 'm_bodyarmor_cravell1_2', price = 55000, currency = 'red_money' },
    --         { name = 'm_bodyarmor_cravell1_3', price = 55000, currency = 'red_money' },
    --         { name = 'm_bodyarmor_cravell1_4', price = 55000, currency = 'red_money' },
    --         { name = 'm_bodyarmor_cravell1_5', price = 55000, currency = 'red_money' },
    --         { name = 'm_bodyarmor_cravell1_6', price = 55000, currency = 'red_money' },
    --         { name = 'm_bodyarmor_cravell1_7', price = 55000, currency = 'red_money' },
    --         -- Female Vest Cravell
    --         { name = 'f_bodyarmor_cravell1_0', price = 55000, currency = 'red_money' },
    --         { name = 'f_bodyarmor_cravell1_1', price = 55000, currency = 'red_money' },
    --         { name = 'f_bodyarmor_cravell1_2', price = 55000, currency = 'red_money' },
    --         { name = 'f_bodyarmor_cravell1_3', price = 55000, currency = 'red_money' },
    --         { name = 'f_bodyarmor_cravell1_4', price = 55000, currency = 'red_money' },
    --         { name = 'f_bodyarmor_cravell1_5', price = 55000, currency = 'red_money' },
    --         { name = 'f_bodyarmor_cravell1_6', price = 55000, currency = 'red_money' },
    --         { name = 'f_bodyarmor_cravell1_7', price = 55000, currency = 'red_money' },
    --     },
    --     groups = { cravelsm = 7 },
    -- },
    ["ivmsm"] = {
        label = "BossMenu Shop",
        inventory = {
            -- Male Vest Invamouz
            { name = 'm_bodyarmor_invamouz1_0', price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_invamouz1_1', price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_invamouz1_2', price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_invamouz1_3', price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_invamouz1_4', price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_invamouz1_5', price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_invamouz1_6', price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_invamouz1_7', price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_invamouz1_8', price = 55000, currency = 'red_money' },

            -- Female Vest Invamouz
            { name = 'f_bodyarmor_invamouz1_0', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_invamouz1_1', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_invamouz1_2', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_invamouz1_3', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_invamouz1_4', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_invamouz1_5', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_invamouz1_6', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_invamouz1_7', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_invamouz1_8', price = 55000, currency = 'red_money' },

            -- Male Jackets Invamouz
            { name = 'm_jackets_invamouz1', price = 55000, currency = 'red_money' },
            { name = 'm_jackets_invamouz2', price = 55000, currency = 'red_money' },
            -- Female Jackets Invamouz
            { name = 'f_jackets_invamouz1', price = 55000, currency = 'red_money' },
        },
        groups = { ivmsm = 7 },
    },
    ["silencesm"] = {
        label = "BossMenu Shop",
        inventory = {
            -- Male Vest SOS
            { name = 'm_bodyarmor_sos1', price = 55000, currency = 'red_money' },
            -- Feale Vest SOS
            { name = 'f_bodyarmor_sos1', price = 55000, currency = 'red_money' },
            -- Male Jackets SOS
            { name = 'm_jackets_sos1', price = 55000, currency = 'red_money' },
            -- Feale Jackets SOS
            { name = 'f_jackets_sos1', price = 55000, currency = 'red_money' },
        },
        groups = { silencesm = 4 },
    },
    -- ["overdrivesm"] = {
    --     label = "BossMenu Shop",
    --     inventory = {
    --         -- Male Jackets Overdrive
    --         { name = 'm_jackets_overdrive1', price = 55000, currency = 'red_money' },
    --         -- Female Jackets Overdrive
    --         { name = 'f_jackets_overdrive1', price = 55000, currency = 'red_money' },
    --     },
    --     groups = { overdrivesm = 4 },
    -- },
    ["leonsm"] = {
        label = "BossMenu Shop",
        inventory = {
            -- Male Jackets Deleon
            { name = 'm_jackets_deleon1', price = 55000, currency = 'red_money' },
            { name = 'm_jackets_deleon2', price = 55000, currency = 'red_money' },
            { name = 'm_jackets_deleon3', price = 55000, currency = 'red_money' },
            -- Female Jackets Deleon
            { name = 'f_jackets_deleon2', price = 55000, currency = 'red_money' },
            { name = 'f_jackets_deleon3', price = 55000, currency = 'red_money' },
        },
        groups = { leonsm = 4 },
    },
    ["kingsm"] = {
        label = "BossMenu Shop",
        inventory = {
            -- Male Jackets King Group
            { name = 'm_jackets_kinggroup1', price = 55000, currency = 'red_money' },
            { name = 'm_jackets_kinggroup2', price = 55000, currency = 'red_money' },
            -- Female Jackets King Group
            { name = 'f_jackets_kinggroup1', price = 55000, currency = 'red_money' },
            { name = 'f_jackets_kinggroup2', price = 55000, currency = 'red_money' },
        },
        groups = { kingsm = 3 },
    },
    -- ["wolfsm"] = {
    --     label = "BossMenu Shop",
    --     inventory = {
    --         -- Male Bodyarmor WLMC
    --         { name = 'm_bodyarmor_wlmc1', price = 55000, currency = 'red_money' },
    --         -- Female Bodyarmor WLMC
    --         { name = 'f_bodyarmor_wlmc1', price = 55000, currency = 'red_money' },
    --     },
    --     groups = { wolfsm = 5 },
    -- },
    ["blazingsm"] = {
        label = "BossMenu Shop",
        inventory = {
            -- Male Bodyarmor BBL
            { name = 'm_bodyarmor_bbl1', price = 55000, currency = 'red_money' },
            -- Female Bodyarmor BBL
            { name = 'f_bodyarmor_bbl1', price = 55000, currency = 'red_money' },
        },
        groups = { blazingsm = 4 },
    },
    ["swagsm"] = {
        label = "BossMenu Shop",
        inventory = {
            -- Male jackets Swag
            { name = 'm_jackets_swag1', price = 55000, currency = 'red_money' },
            { name = 'm_jackets_swag2', price = 55000, currency = 'red_money' },
            -- Female jackets Swag
            { name = 'f_jackets_swag1', price = 55000, currency = 'red_money' },
            { name = 'f_jackets_swag2', price = 55000, currency = 'red_money' },
            -- Male Pants Swag
            { name = 'm_pants_swag1',   price = 55000, currency = 'red_money' },
            -- Female Pants Swag
            { name = 'f_pants_swag1',   price = 55000, currency = 'red_money' },
        },
        groups = { swagsm = 4 },
    },
    ["eclipsesm"] = {
        label = "BossMenu Shop",
        inventory = {
            -- Male Jackets Eclipse
            { name = 'm_jackets_eclipse1', price = 55000, currency = 'red_money' },
            -- Female Jackets Eclipse
            { name = 'f_jackets_eclipse1', price = 55000, currency = 'red_money' },
        },
        groups = { eclipsesm = 4 },
    },
    -- ["ebk54sm"] = {
    --     label = "BossMenu Shop",
    --     inventory = {
    --         -- Male Teef EBK
    --         { name = 'm_teef_ebk1', price = 55000, currency = 'red_money' },
    --         -- Female Teef EBK
    --         { name = 'f_teef_ebk1', price = 55000, currency = 'red_money' },
    --     },
    --     groups = { ebk54sm = 4 },
    -- },
    ["famsmcsm"] = {
        label = "BossMenu Shop",
        inventory = {
            -- Male Outfits Young Mc
            { name = 'm_jackets_youngmc1', price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_youngmc1_0', price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_youngmc1_1', price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_youngmc1_2', price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_youngmc1_3', price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_youngmc1_4', price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_youngmc1_5', price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_youngmc1_6', price = 55000, currency = 'red_money' },
            { name = 'm_bodyarmor_youngmc1_7', price = 55000, currency = 'red_money' },

            -- Female Outfits Young Mc
            { name = 'f_jackets_youngmc1', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_youngmc1_0', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_youngmc1_1', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_youngmc1_2', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_youngmc1_3', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_youngmc1_4', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_youngmc1_5', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_youngmc1_6', price = 55000, currency = 'red_money' },
            { name = 'f_bodyarmor_youngmc1_7', price = 55000, currency = 'red_money' },

        },
        groups = { famsmcsm = 6 },
    },
    ["barongsm"] = {
        label = "BossMenu Shop",
        inventory = {
            -- Male Jackets Barong
            { name = 'm_jackets_barong1', price = 55000, currency = 'red_money' },
            { name = 'm_jackets_barong2', price = 55000, currency = 'red_money' },
            { name = 'm_jackets_barong3', price = 55000, currency = 'red_money' },
            { name = 'm_jackets_barong4', price = 55000, currency = 'red_money' },
            { name = 'm_jackets_barong5', price = 55000, currency = 'red_money' },
            -- Female Jackets Barong
            { name = 'f_jackets_barong1', price = 55000, currency = 'red_money' },
            { name = 'f_jackets_barong2', price = 55000, currency = 'red_money' },
            { name = 'f_jackets_barong3', price = 55000, currency = 'red_money' },
            { name = 'f_jackets_barong4', price = 55000, currency = 'red_money' },
            { name = 'f_jackets_barong5', price = 55000, currency = 'red_money' },
        },
        groups = { barongsm = 4 },
    },
    ["dsrsm"] = {
        label = "BossMenu Shop",
        inventory = {
            -- Male Hats DSR
            { name = 'm_hats_dsr1', price = 55000, currency = 'red_money' },
            { name = 'm_hats_dsr2', price = 55000, currency = 'red_money' },
            -- Female Hats DSR
            { name = 'f_hats_dsr1', price = 55000, currency = 'red_money' },
        },
        groups = { dsrsm = 5 },
    },
    ["lvsm"] = {
        label = "BossMenu Shop",
        inventory = {
            -- Male Chain LV
            { name = 'm_teef_lv1', price = 55000, currency = 'red_money' },
            -- Female Chain LV
            { name = 'f_teef_lv1', price = 55000, currency = 'red_money' },
        },
        groups = { lvsm = 3 },
    },
    ["rebelsm"] = {
        label = "BossMenu Shop",
        inventory = {
            -- Male Jackets RBL
            { name = 'm_jackets_rbl1', price = 55000, currency = 'red_money' },
            -- Female Jackets RBL
            { name = 'f_jackets_rbl1', price = 55000, currency = 'red_money' },
        },
        groups = { rebelsm = 4 },
    },
    ["etbsm"] = {
        label = "BossMenu Shop",
        inventory = {
            -- Male Jackets ETB
            { name = 'm_jackets_etb1', price = 55000, currency = 'red_money' },
            -- Female Jackets ETB
            { name = 'f_jackets_etb1', price = 55000, currency = 'red_money' },
        },
        groups = { etbsm = 4 },
    },
    ["reborn969sm"] = {
        label = "BossMenu Shop",
        inventory = {
            -- Male Body Armor Reborn 969
            { name = 'm_bodyarmor_r9691', price = 55000, currency = 'red_money' },
            -- Female Body Armor Reborn 969
            { name = 'f_bodyarmor_r9691', price = 55000, currency = 'red_money' },
        },
        groups = { reborn969sm = 4 },
    },
}
