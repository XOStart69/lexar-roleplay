local rewards = {}

-- Glass cutting rewards: removed diamond, kept panther and necklace
rewards.glass_cutting = {
    {
        object = {model = 'h4_prop_h4_art_pant_01a', rot = -53.06},
        displayObj = {model = 'h4_prop_h4_diamond_disp_01a', rot = vector3(360.0, 0.0, 70.0)},
        item = 'panther',
        amount = 1
    },
    {
        object = {model = 'h4_prop_h4_necklace_01a', rot = -53.06},
        displayObj = {model = 'h4_prop_h4_neck_disp_01a', rot = vector3(360.0, 0.0, -60.0)},
        item = 'necklace',
        amount = 1
    },
}

-- Vitrine rewards: removed goldbar, max 1 per glass
rewards.vitrine = {
    {item = 'tenkgoldchain', min = 1, max = 1},
    {item = 'goldchain', min = 1, max = 1},
    {item = 'rolex', min = 1, max = 1},
}

rewards.painting = {
    item = 'paintingg',
    amount = 1
}

-- Locker: lucky/zonk system
-- Lucky: security_card max 2
-- Zonk: 200k black_money OR silver_ring OR golden_ring (max 1 per item)
rewards.locker = {
    hackDuration = 120000, -- 2 minutes hacking
    lucky = {
        item = 'security_card',
        max = 2,
        chance = 30, -- 30% chance to get security_card
    },
    zonk = {
        { item = 'black_money', amount = 200000 },
        { item = 'silver_ring', amount = 1 },
        { item = 'golden_ring', amount = 1 },
    }
}

return rewards