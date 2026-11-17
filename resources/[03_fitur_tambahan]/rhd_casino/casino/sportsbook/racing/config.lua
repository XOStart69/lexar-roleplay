---@type RacingConfig
return {
    receiptItem = 'casino_racing_receipt',

    betId = {
        prefix = 'RACE-',
        digits = 6,
    },

    houseEdge = {
        default = 5.0,
        min = 0.0,
        max = 50.0,
    },

    ---Batas absolut yang membungkus nilai min/max stake yang diisi admin per event.
    stakeBounds = {
        min = 1000,
        max = 50000000,
    },

    liabilityBounds = {
        min = 1000,
        max = 1000000000,
    },

    labelLength = 64,
    outcomeNameLength = 64,

    outcomeBounds = { min = 2, max = 20 },

    ---`places` = jumlah posisi finish teratas yang dibayar. Sebuah market baru ikut
    ---aktif kalau jumlah driver melebihi `places`. Urutan di sini = urutan tampil di tablet.
    markets = {
        { id = 'winner', places = 1 },
        { id = 'podium', places = 3 },
    },
}
