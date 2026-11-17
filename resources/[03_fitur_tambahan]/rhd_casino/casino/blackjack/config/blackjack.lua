local blackjack = {}

---@enum Blackjack_TableColor
local table_colors = {
    green = 0,
    red = 1,
    blue = 2,
    purple = 3,
}

---@enum Blackjack_TableType
blackjack.table_model = {
    standard = 'vw_prop_casino_blckjack_01',
    highstakes = 'vw_prop_casino_blckjack_01b',
    exclusive = 'h4_prop_casino_blckjack_01e',
}

---@alias BettingAmount
---| 10
---| 50
---| 100
---| 120
---| 500
---| 600
---| 1000
---| 1200
---| 5000
---| 6000
---| 10000
---| 50000
---| 60000
---| 120000

blackjack.bettingTime = 50
blackjack.moveTime = 30

-- Level kesulitan global blackjack.
-- level: pilih salah satu kunci di presets ('easy'|'normal'|'hard'|'rigged').
-- winChance: peluang (0-100, boleh desimal) sebuah ronde dibiarkan menghasilkan kemenangan pemain.
--            Jika gagal, dealer ditarik kartunya agar mengalahkan pemain (dalam batas tanpa bust).
--            Catatan: aturan blackjack membuat rig tidak selalu 100% sukses bila dealer tak bisa
--            melampaui nilai pemain tanpa bust, sehingga hasil bisa sedikit di atas winChance.
blackjack.Difficulty = {
    level = 'hard',
    presets = {
        easy = { winChance = 100.0 },
        normal = { winChance = 100.0 },
        hard = { winChance = 35.0 },
        rigged = { winChance = 0.1 },
    },
}

---@class Blackjack_PayoutMultipliers
---@field blackjack number  natural 21 on the first 2 cards (default 2.5 = 3:2)
---@field win number  regular win (default 2.0 = 1:1 + stake back)
---@field push number  tie with dealer (default 1.0 = stake back)

---@type Blackjack_PayoutMultipliers
local defaultPayouts = {
    blackjack = 2.5,
    win = 2.0,
    push = 1.0,
}

blackjack.tables = {
	{
		coords = vector4(998.2831, 61.2565, 68.4329, 12.5080),
        model = blackjack.table_model.standard,
        bettingAmounts = { 50000 },  ---@type BettingAmount[]
        maxBettingAmount = 200000,
        dealerOutfit = { 'outfit_1', 'outfit_2', 'outfit_3', 'outfit_4', 'outfit_5', 'outfit_6', 'outfit_7', 'outfit_8', 'outfit_9', 'outfit_10', 'outfit_11', 'outfit_12', 'outfit_13', 'outfit_14' },
        payoutMultipliers = defaultPayouts,
        color = table_colors.purple,
        vipOnly = false
	},
	{
		coords = vector4(1000.8967, 50.5012, 68.4328, 193.6876),
        model = blackjack.table_model.highstakes,
        bettingAmounts = { 50000 },  ---@type BettingAmount[]
        maxBettingAmount = 200000,
        dealerOutfit = { 'outfit_1', 'outfit_2', 'outfit_3', 'outfit_4', 'outfit_5', 'outfit_6', 'outfit_7', 'outfit_8', 'outfit_9', 'outfit_10', 'outfit_11', 'outfit_12', 'outfit_13', 'outfit_14' },
        payoutMultipliers = defaultPayouts,
        color = table_colors.purple,
        vipOnly = false
	},
	-- {
	-- 	coords = vector4(985.04803466797, 66.630256652832, 69.232757568359, 7.9998970031738),
    --     model = blackjack.table_model.exclusive,
    --     bettingAmounts = { 10, 50, 100, 120, 500, 600, 1000, 1200 }, ---@type BettingAmount[]
    --     maxBettingAmount = 120000,
    --     dealerOutfit = { 'outfit_1', 'outfit_2', 'outfit_3', 'outfit_4', 'outfit_5', 'outfit_6', 'outfit_7', 'outfit_8', 'outfit_9', 'outfit_10', 'outfit_11', 'outfit_12', 'outfit_13', 'outfit_14' },
    --     payoutMultipliers = defaultPayouts,
    --     color = table_colors.red
	-- },
	-- {
	-- 	coords = vector4(988.46246337891, 64.28556060791, 69.232757568359, 282.99993896484),
    --     model = blackjack.table_model.standard,
    --     bettingAmounts = { 10, 50, 100, 120, 500, 600, 1000, 1200 }, ---@type BettingAmount[]
    --     maxBettingAmount = 120000,
    --     dealerOutfit = { 'outfit_1', 'outfit_2', 'outfit_3', 'outfit_4', 'outfit_5', 'outfit_6', 'outfit_7', 'outfit_8', 'outfit_9', 'outfit_10', 'outfit_11', 'outfit_12', 'outfit_13', 'outfit_14' },
    --     payoutMultipliers = defaultPayouts,
    --     color = table_colors.blue
	-- },

	-- {
	-- 	coords = vector4(993.23443603516, 43.616027832031, 69.232757568359, 282.99996948242),
    --     model = blackjack.table_model.standard,
    --     bettingAmounts = { 10, 50, 100, 120, 500, 600, 1000, 1200 }, ---@type BettingAmount[]
    --     maxBettingAmount = 120000,
    --     dealerOutfit = { 'outfit_1', 'outfit_2', 'outfit_3', 'outfit_4', 'outfit_5', 'outfit_6', 'outfit_7', 'outfit_8', 'outfit_9', 'outfit_10', 'outfit_11', 'outfit_12', 'outfit_13', 'outfit_14' },
    --     payoutMultipliers = defaultPayouts,
    --     color = table_colors.purple
	-- },
	-- {
	-- 	coords = vector4(991.46496582031, 40.094329833984, 69.232757568359, 202.99989318848),
    --     model = blackjack.table_model.highstakes,
    --     bettingAmounts = { 10, 50, 100, 120, 500, 600, 1000, 1200 }, ---@type BettingAmount[]
    --     maxBettingAmount = 120000,
    --     dealerOutfit = { 'outfit_1', 'outfit_2', 'outfit_3', 'outfit_4', 'outfit_5', 'outfit_6', 'outfit_7', 'outfit_8', 'outfit_9', 'outfit_10', 'outfit_11', 'outfit_12', 'outfit_13', 'outfit_14' },
    --     payoutMultipliers = defaultPayouts,
    --     color = table_colors.green
	-- },
	-- {
	-- 	coords = vector4(987.26837158203, 42.203384399414, 69.232688903809, 102.69055938721),
    --     model = blackjack.table_model.exclusive,
    --     bettingAmounts = { 10, 50, 100, 120, 500, 600, 1000, 1200 }, ---@type BettingAmount[]
    --     maxBettingAmount = 120000,
    --     dealerOutfit = { 'outfit_1', 'outfit_2', 'outfit_3', 'outfit_4', 'outfit_5', 'outfit_6', 'outfit_7', 'outfit_8', 'outfit_9', 'outfit_10', 'outfit_11', 'outfit_12', 'outfit_13', 'outfit_14' },
    --     payoutMultipliers = defaultPayouts,
    --     color = table_colors.red
	-- },
	-- {
	-- 	coords = vector4(989.03784179688, 45.724502563477, 69.232688903809, 27.690536499023),
    --     model = blackjack.table_model.standard,
    --     bettingAmounts = { 10, 50, 100, 120, 500, 600, 1000, 1200 }, ---@type BettingAmount[]
    --     maxBettingAmount = 120000,
    --     dealerOutfit = { 'outfit_1', 'outfit_2', 'outfit_3', 'outfit_4', 'outfit_5', 'outfit_6', 'outfit_7', 'outfit_8', 'outfit_9', 'outfit_10', 'outfit_11', 'outfit_12', 'outfit_13', 'outfit_14' },
    --     payoutMultipliers = defaultPayouts,
    --     color = table_colors.blue
	-- },
}

blackjack.anim = {
    request = {
        "request_card",
        "request_card_alt1",
        "request_card_alt2",
    },
    decline = {
        "decline_card_001",
        "decline_card_alt1",
        "decline_card_alt2",
    }
}


blackjack.chipModels = {
	[10] = "vw_prop_chip_10dollar_x1",
	[50] = "vw_prop_chip_50dollar_x1",
	[100] = "vw_prop_chip_100dollar_x1",
	[500] = "vw_prop_chip_500dollar_x1",
	[1000] = "vw_prop_chip_1kdollar_x1",
	[5000] = "vw_prop_chip_5kdollar_x1",
	[10000] = "vw_prop_plaq_10kdollar_x1",
}

blackjack.chipThickness = {
	[`vw_prop_chip_10dollar_x1`] = 0.0054170000366867,
	[`vw_prop_chip_50dollar_x1`] = 0.0056730001233518,
	[`vw_prop_chip_100dollar_x1`] = 0.0056900000199676,
	[`vw_prop_chip_10dollar_st`] = 0.061421997845173,
	[`vw_prop_chip_500dollar_x1`] = 0.0057030003517866,
	[`vw_prop_chip_50dollar_st`] = 0.061151999980211,
	[`vw_prop_chip_1kdollar_x1`] = 0.0056910002604127,
	[`vw_prop_chip_100dollar_st`] = 0.060908999294043,
	[`vw_prop_chip_500dollar_st`] = 0.060989998281002,

	[`vw_prop_chip_5kdollar_x1`] = 0.005538,
	[`vw_prop_chip_10kdollar_x1`] = 0.005562,
	[`vw_prop_chip_5kdollar_st`] = 0.061049,
	[`vw_prop_chip_10kdollar_st`] = 0.06095,
	[`vw_prop_plaq_5kdollar_x1`] = 0.006891000084579,
	[`vw_prop_plaq_10kdollar_x1`] = 0.0057889996096492,
	[`vw_prop_plaq_5kdollar_st`] = 0.060949999839067,
	[`vw_prop_plaq_10kdollar_st`] = 0.060749001801014,
}

blackjack.chipHeights = {
	0.95, 0.896, 0.901, 0.907, 0.95, 0.917,
	0.922, 0.927, 0.932, 0.95, 0.904, 0.899,
	0.914, 0.904, 0.924, 0.91, 0.935, 0.95,
	0.95, 0.904, 0.899, 0.915, 0.904, 0.925,
	0.91, 0.935, 0.95, 0.919, 0.924,
	0.93, 0.935, 0.95, 0.902, 0.897,
	0.912, 0.902, 0.922,
	0.907, 0.932, 0.912,
}

return blackjack
