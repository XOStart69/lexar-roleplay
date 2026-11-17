---@class PokerTableConfig
---@field id number
---@field coords vector4
---@field vipOnly boolean? -- hanya pemain dengan VIP yang bisa duduk (default: false)
---@field blind number -- small blind (big blind = blind * 2)
---@field buyIn number -- minimum chips yang dibutuhkan untuk duduk
---@field maxBuyIn number? -- maksimum chips yang bisa dibawa ke meja (nil = semua chip)
---@field maxBet number? -- maksimum bet per aksi (nil = unlimited)
---@field minBet number? -- minimum bet per aksi (nil = blind)
---@field dealerOutfit string[] -- daftar outfit untuk dealer, akan dipilih secara acak

---@class PokerBotConfig
---@field enabled boolean -- aktif/nonaktif auto-bot
---@field count number -- jumlah bot maksimal per meja
---@field personality 'aggressive' | 'passive' | 'balanced'
---@field startingChips number -- chip awal bot
---@field thinkMin number -- ms minimum sebelum bot bertindak
---@field thinkMax number -- ms maksimum sebelum bot bertindak
---@field churnIntervalMin number -- detik minimum antar bot keluar/masuk
---@field churnIntervalMax number -- detik maksimum antar bot keluar/masuk
---@field churnLeaveChance number -- peluang bot keluar per interval (0.0 - 1.0)
---@field rejoinDelayMin number -- ms minimum sebelum bot baru masuk
---@field rejoinDelayMax number -- ms maksimum sebelum bot baru masuk

return {
    ---@type PokerTableConfig[]
    pokerTables = {
        {
            id = 1,
            coords = vector4(993.3676, 41.1351, 70.2379, 148.2547),
            blind = 10000,
            buyIn = 250000,
            maxBuyIn = 1000000,
            maxBet = 1000000,
            vipOnly = true,
            dealerOutfit = { 'outfit_1', 'outfit_2', 'outfit_3', 'outfit_4', 'outfit_5', 'outfit_6', 'outfit_7', 'outfit_8', 'outfit_9', 'outfit_10', 'outfit_11', 'outfit_12', 'outfit_13', 'outfit_14' },
        },
        {
            id = 2,
            coords = vector4(986.9665, 44.8900, 70.2379, 322.7194),

            blind = 10000,
            buyIn = 250000,
            maxBuyIn = 1000000,
            maxBet = 1000000,
            vipOnly = true,
            dealerOutfit = { 'outfit_1', 'outfit_2', 'outfit_3', 'outfit_4', 'outfit_5', 'outfit_6', 'outfit_7', 'outfit_8', 'outfit_9', 'outfit_10', 'outfit_11', 'outfit_12', 'outfit_13', 'outfit_14' },
        },
        {
            id = 3,
            coords = vector4(987.43347167969, 66.620979309082, 70.23, 239.56340026855),
            blind = 10000,
            buyIn = 250000,
            maxBuyIn = 1000000,
            maxBet = 1000000,
            vipOnly = true,
            dealerOutfit = { 'outfit_1', 'outfit_2', 'outfit_3', 'outfit_4', 'outfit_5', 'outfit_6', 'outfit_7', 'outfit_8', 'outfit_9', 'outfit_10', 'outfit_11', 'outfit_12', 'outfit_13', 'outfit_14' },
        },
        {
            id = 4,
            coords = vector4(983.66534423828, 60.532718658447, 70.23, 55.144569396973),
            blind = 10000,
            buyIn = 250000,
            maxBuyIn = 1000000,
            maxBet = 1000000,
            vipOnly = true,
            dealerOutfit = { 'outfit_1', 'outfit_2', 'outfit_3', 'outfit_4', 'outfit_5', 'outfit_6', 'outfit_7', 'outfit_8', 'outfit_9', 'outfit_10', 'outfit_11', 'outfit_12', 'outfit_13', 'outfit_14' },
        },
    },

    ---@type PokerBotConfig
    bot = {
        enabled = false,
        count = 3,
        personality = 'balanced',
        startingChips = math.random(250000, 1000000),

        thinkMin = 1200,
        thinkMax = 3000,

        churnIntervalMin = 12,
        churnIntervalMax = 28,
        churnLeaveChance = 0.40,
        rejoinDelayMin = 4000,
        rejoinDelayMax = 10000,
    },

    dealerAnimDictShared = 'anim_casino_b@amb@casino@games@shared@dealer@',
    playerAnimDictShared = 'anim_casino_b@amb@casino@games@shared@player@',

    debugMinPlayers = 2, -- set ke 1 untuk testing solo, 2 untuk production

    ---@enum GameStage
    gameStage = {
        GAME_NOT_STARTED = 1,
        ROUNDS = 2,
        SHOWING_CARDS = 3,
    }
}
