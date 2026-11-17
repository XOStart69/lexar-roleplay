GachaKompensasi = {
    itemName = 'box_kompensasi',
    label = 'Gacha Kompensasi',
    caseLabel = 'BOX KOMPENSASI',

    items = {
        -- DIVINE (0,05%)
        { name = 'jpx_firecracker_dragon', label = 'Firecracker Dragon', tier = 'divine', chance = 0.05,
          reward = { type = 'item', item = 'jpx_firecracker_dragon', count = 1 } },

        -- LEGEND
        { name = 'weapon_redkatana', label = 'Red Katana', tier = 'legendary', chance = 0.10,
          reward = { type = 'item', item = 'WEAPON_REDKATANA', count = 1 }, image = 'WEAPON_REDKATANA.png' },
        { name = 'uang_ic_150k', label = 'UANG IC 150.000', tier = 'legendary', chance = 0.15,
          reward = { type = 'item', item = 'money', count = 150000 }, image = 'money.png' },
        { name = 'uang_ic_100k', label = 'UANG IC 100.000', tier = 'legendary', chance = 0.20,
          reward = { type = 'item', item = 'money', count = 100000 }, image = 'money.png' },

        -- EPIC (pakai tier UI "mythical")
        { name = 'bandage_5', label = 'Bandage 5pcs', tier = 'mythical', chance = 2.45,
          reward = { type = 'item', item = 'bandage', count = 5 }, image = 'bandage.png' },
        { name = 'paracetamol_3', label = 'Paracetamol 3pcs', tier = 'mythical', chance = 3.00,
          reward = { type = 'item', item = 'paracetamol', count = 3 }, image = 'paracetamol.png' },
        { name = 'bandage_1', label = 'Bandage 1pcs', tier = 'mythical', chance = 4.00,
          reward = { type = 'item', item = 'bandage', count = 1 }, image = 'bandage.png' },

        -- RARE
        { name = 'paket_gudeg_2', label = 'Makan Minum 2 Paket Gudeg', tier = 'rare', chance = 8.00,
          reward = { type = 'item', item = 'paket_gudeg', count = 2 }, image = 'paket_gudeg.png' },
        { name = 'golden_coffee_2', label = 'Golden Coffee 2pcs', tier = 'rare', chance = 10.00,
          reward = { type = 'item', item = 'golden_coffee', count = 2 }, image = 'golden_coffee.png' },
        { name = 'recycle_box_50', label = 'Bahan Disnaker Recycle Box 50pcs', tier = 'rare', chance = 12.00,
          reward = { type = 'item', item = 'recycle_box', count = 50 }, image = 'recycle_box.png' },

        -- COMMON
        { name = 'homademilk_20', label = 'Bahan Disnaker Homade Milk 20pcs', tier = 'common', chance = 15.00,
          reward = { type = 'item', item = 'homemademilk', count = 20 }, image = 'homemademilk.png' },
        { name = 'hunting_skin_20', label = 'Hunting Skin 20pcs', tier = 'common', chance = 20.00,
          reward = { type = 'item', item = 'hunting_skin', count = 20 }, image = 'hunting_skin.png' },
        { name = 'bawang_20', label = 'Bawang 20pcs', tier = 'common', chance = 25.00,
          reward = { type = 'item', item = 'bawang', count = 20 }, image = 'bawang.png' },
    },
}
