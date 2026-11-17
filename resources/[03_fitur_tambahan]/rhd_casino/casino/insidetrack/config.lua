return {

    BetMin = 20000,
    BetMax = 100000,
    BetStep = 5000,

    -- Durasi race scaleform (milliseconds) — harus sama di server & client
    RaceDuration = 30000,

    -- Heading (derajat) yang menghadap ke big screen untuk semua kursi
    -- terminal. -167 = menghadap big screen di interior casino GTAO default.
    ChairHeading = -167.0,

    -- Multiplier kemenangan berdasarkan odds kuda
    -- Setiap kuda mendapat odds yang di-assign server, bukan client
    -- Odds = kelipatan dari bet yang dikembalikan jika menang (termasuk modal)
    HorseOdds = {
        [1] = { min = 1, max = 2 },   -- Kuda 1: odds rendah (favorit)
        [2] = { min = 2, max = 3 },
        [3] = { min = 2, max = 4 },
        [4] = { min = 3, max = 5 },
        [5] = { min = 4, max = 7 },
        [6] = { min = 5, max = 10 },  -- Kuda 6: odds tinggi (underdog)
    },

    -- Peluang menang tiap kuda (total harus = 100)
    -- Server menggunakan ini untuk menentukan pemenang
    HorseWinChance = {
        [1] = 30, -- 30%
        [2] = 22, -- 22%
        [3] = 18, -- 18%
        [4] = 15, -- 15%
        [5] = 10, -- 10%
        [6] = 5, --  5%
    },

    -- Level kesulitan global inside track.
    -- level: pilih salah satu kunci di presets ('easy'|'normal'|'hard'|'rigged').
    -- winChance: peluang (0-100, boleh desimal) sebuah ronde dibiarkan menghasilkan pemenang dari kuda yang ditaruhi.
    --            Jika gagal, server memilih kuda pemenang yang tidak ditaruhi siapa pun (semua bettor kalah penuh).
    Difficulty = {
        level = 'hard',
        presets = {
            easy = { winChance = 100.0 },
            normal = { winChance = 100.0 },
            hard = { winChance = 35.0 },
            rigged = { winChance = 0.1 },
        },
    },

    BigScreen = {
        coords = vector3(952.2609, 85.3877, 70.0328),
        renderTarget = 'casinoscreen_02',
        objectModel = `vw_vwint01_betting_screen`,
        drawDistance = 30.0,
    },

    -- Audio
    AudioBank = 'DLC_VINEWOOD/CASINO_GENERAL',
    RaceAudioBank = 'dlc_vw_casino_inside_track_betting_single_event_sounds',
    RaceMainAudioBank = 'dlc_vw_casino_inside_track_betting_main_event_sounds',
    RaceSound = 'race_loop',

    -- Voice ambient untuk announcer (CAS_HORSE_ANNOUNCER = preset asli GTAO)
    AnnouncerVoice = 'CAS_HORSE_ANNOUNCER',

    -- Mapping slot kuda (1-6) ke speech name id (untuk MINIGAME_TRACK_*_<NAME>)
    -- Sesuai dengan urutan horseDisplayNames di modules/horses.lua
    HorseSpeechIds = {
        'DURBAN_POISON',
        'SWEET_RELEAF',
        'ROBOCALL',
        'BANANA_HAMMOCK',
        'SALTY_AND_WOKE',
        'WONDER_BOY',
    },

    -- ── Main Event (Multiplayer) ─────────────────────────────────────────────
    -- Main Event = race bersama semua pemain di casino setiap beberapa menit
    -- Semua pemain yang pasang bet pada main event akan ikut race yang SAMA
    --
    -- Flow: idle → open (countdown) → presentation → racing → results → idle
    MainEvent = {
        -- Durasi countdown utuh (detik). Betting TERBUKA SELAMA countdown ini.
        -- Saat timer = 0 → race start, menu bet ditutup paksa untuk participant.
        betWindowSeconds = 120,

        -- Durasi tiap segmen big screen selama countdown (detik).
        -- Big screen alternasi: list (5s) → detail kuda 1 (5s) → list (5s) →
        -- detail kuda 2 (5s) → ... → detail kuda 6 (5s) → ulang.
        cycleSeconds = 5,

        -- Layar hasil (screen 4) setelah race selesai (detik)
        resultDisplaySeconds = 10,

        -- Layar intermission (screen 5) sebelum round berikutnya (detik)
        intermissionSeconds = 2,

        -- Radius pemain dianggap "menonton" big screen (subscribe ke broadcast)
        broadcastRadius = 90.0,
    },
}
