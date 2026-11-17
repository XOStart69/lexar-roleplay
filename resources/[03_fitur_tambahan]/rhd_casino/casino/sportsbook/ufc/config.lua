return {
    receiptItem = 'casino_ufc_receipt',

    betId = {
        prefix = 'UFC-',
        digits = 6,
    },

    houseEdge = {
        default = 5.0,
        min = 0.0,
        max = 50.0,
    },

    ---Batas absolut yang membungkus nilai min/max stake yang diisi admin per fight.
    stakeBounds = {
        min = 1000,
        max = 50000000,
    },

    liabilityBounds = {
        min = 1000,
        max = 1000000000,
    },
}
