return {
    -- https://docs.fivem.net/docs/game-references/controls/
    Controls = {
        play = {
            start = 38,
            stop = 202
        },
        bet = {
            up = 172,
            down = 173
        },
        maxBet = 23,
        spin = 201,
    },

    -- Pada kelipatan berapa pemain akan melakukan animasi menang besar
    WinBigAnimation = 75,
    -- Pada jumlah bet berapa pemain akan melakukan animasi kalah "kejam"
    LostCruelAnimation = 10000,

    -- Bobot level jackpot (JP1 = paling sering, JP9 = paling jarang)
    -- Total bobot = 1000. Ubah nilai untuk mengatur probabilitas masing-masing level.
    JackpotWeights = { 400, 250, 150, 80, 50, 30, 20, 15, 5 },

    -- Level kesulitan global mesin slot.
    -- level: pilih salah satu kunci di presets ('easy'|'normal'|'hard'|'rigged').
    -- winChance: peluang (0-100, boleh desimal) sebuah putaran menang benar-benar dibayar.
    --            Gate ini hanya mengurangi kemenangan; jika gagal, putaran dipaksa kalah penuh.
    Difficulty = {
        level = 'hard',
        presets = {
            easy = { winChance = 100.0 },
            normal = { winChance = 100.0 },
            hard = { winChance = 35.0 },
            rigged = { winChance = 0.1 },
        },
    },
}