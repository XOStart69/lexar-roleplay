return {
    -- https://docs.fivem.net/docs/game-references/controls/
    Controls = {
        play = {
            enter = 38,
            leave = 202
        },
        camera = {
            wheel = 45,
            table = 23
        },
        bet = {
            increase = 15,
            decrease = 14,
            place = 24,
            remove = 25
        }
    },

    -- Level kesulitan global roulette.
    -- level: pilih salah satu kunci di presets ('easy'|'normal'|'hard'|'rigged').
    -- winChance: peluang (0-100, boleh desimal) sebuah putaran dibiarkan menghasilkan kemenangan.
    --            Jika gagal, server memilih nomor pemenang yang membuat semua taruhan kalah penuh.
    Difficulty = {
        level = 'hard',
        presets = {
            easy = { winChance = 100.0 },
            normal = { winChance = 100.0 },
            hard = { winChance = 35.0 },
            rigged = { winChance = 0.1 },
        },
    },

    Roulettes = {
        -- { coords = vector4(985.91241455078, 49.010475158691, 69.232749938965, 224.0), tableType = 'default' },
        -- { coords = vector4(982.16448974609, 52.203956604004, 69.232757568359, 284.0), tableType = 'default' },
        -- { coords = vector4(984.30212402344, 55.93537902832, 69.232749938965, 343.99996948242), tableType = 'default' },
        { coords = vector4(999.88592529297, 54.403343200684, 68.432754516602, 193.00006103516), tableType = 'default' },
        { coords = vector4(998.97375488281, 57.771678924561, 68.432754516602, 12.999969482422), tableType = 'default' },
        { coords = vector4(1004.7904052734, 57.295074462891, 68.432754516602, 282.99993896484), tableType = 'default' },
    },

    -- tableColour can be green, red, blue, or purple
    -- dealerOutfit comes from dealers.lua | A random outfit will be chosen from the table provided. Even if you only want one outfit, you still need to put in a table.
    TableType = {
        ['default'] = {
            whiteChairs = true,
            tableColour = 'blue',
            dealerOutfit = { 'outfit_1', 'outfit_2', 'outfit_3', 'outfit_4', 'outfit_5', 'outfit_6', 'outfit_7', 'outfit_8', 'outfit_9', 'outfit_10', 'outfit_11', 'outfit_12', 'outfit_13', 'outfit_14' },
            bettingAmmounts = { 20000 },
            maxBettingAmount = 100000,
            payoutMultipliers = {
                [1] = 35,   -- Single number (straight up)
                [2] = 17,   -- Split bet
                [3] = 11,   -- Street bet
                [4] = 8,    -- Corner bet
                [5] = 6,    -- Basket bet (American roulette: 0, 00, 1, 2, 3)
                [6] = 5,    -- Six line bet
                [12] = 2,   -- Dozen/Column bet
                [18] = 1    -- Red/Black, Odd/Even, High/Low
            },
        },

        ['vip'] = {
            whiteChairs = true,
            tableColour = 'purple',
            dealerOutfit = { 'outfit_1', 'outfit_2', 'outfit_3', 'outfit_4', 'outfit_5', 'outfit_6', 'outfit_7', 'outfit_8', 'outfit_9', 'outfit_10', 'outfit_11', 'outfit_12', 'outfit_13', 'outfit_14' },
            bettingAmmounts = { 50000 },
            maxBettingAmount = 200000,
            payoutMultipliers = {
                [1] = 35,   -- Single number (straight up)
                [2] = 17,   -- Split bet
                [3] = 11,   -- Street bet
                [4] = 8,    -- Corner bet
                [5] = 6,    -- Basket bet (American roulette: 0, 00, 1, 2, 3)
                [6] = 5,    -- Six line bet
                [12] = 2,   -- Dozen/Column bet
                [18] = 1    -- Red/Black, Odd/Even, High/Low
            },
        }
    }

}
