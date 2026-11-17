-- House edge dikonfigurasi per mesin (lihat HouseEdge di tiap SlotsData).
-- enabled = true/false. Jika false, sistem house edge dinonaktifkan dan hanya pakai WinChance.
-- targetRTP = persentase total bet yang dikembalikan ke pemain dalam jangka panjang (0.0 - 1.0)
-- maxWinMultiplier = batas kemenangan (x bet) saat RTP pemain sudah di atas target
-- consolationMultiplier = kelipatan payout consolation, bisa < 1 sehingga pemain "menang" tapi rugi net
-- lossStreakLimit = kalah berapa kali berturut sebelum consolation aktif

-- Data konfigurasi per model mesin slot (bet, multiplier, peluang).
-- Kamu bisa membedakan mesin tertentu sebagai "VIP" dengan peluang dan bet yang berbeda.
-- MisChance = peluang reel berhenti di tengah-tengah simbol (hanya visual). 0 = tidak pernah, 100 = selalu.
-- WinChance = (hanya aktif jika enabled=false) peluang dasar pemain mendapat kombinasi menang. 0 = tidak pernah menang, 100 = selalu menang.
-- Tabel jackpot = { JP1, JP2, JP3, JP4, JP5, JP6, JP7, JP8, JP9 } berupa kelipatan dari bet.

return {
    -- KELAS ATAS: Diamond Slot, Deity of the sun
    [`vw_prop_casino_slot_01a`] = {
        BetAmounts = { 20000, 40000, 60000, 80000, 100000 },
        MisChance = 10,
        WinChance = 30,
        EnableTwoOfAKind = true,
        HouseEdge = {
            enabled = true,
            targetRTP = 0.75, -- Pemain mendapat kembali ~75% dari total bet di mesin ini
            maxWinMultiplier = 8, -- Saat RTP pemain sudah di atas target, kemenangan max dibatasi 8x bet
            consolationMultiplier = 0.5,  -- Consolation win = 50% dari bet (pemain "menang" tapi rugi net)
            lossStreakLimit = 4, -- Kalah 4x berturut → consolation aktif
        },
        Multipliers = {
            jackpot = { 2, 5, 25, 50, 75, 100, 250, 500, 1000 },
            threeOfAKind = {
                diamonds = 25,
                sevens = 25,
                bells = 15,
                plums = 10,
                melons = 10,
                cherries = 5
            },
            twoOfAKind = {
                diamonds = 5,
                sevens = 5,
                bells = 3,
                plums = 2,
                melons = 2,
                cherries = 1
            },
            diamondBonus = 0
        }
    },
    [`vw_prop_casino_slot_02a`] = {
        BetAmounts = { 20000, 40000, 60000, 80000, 100000 },
        MisChance = 10,
        WinChance = 40,
        EnableTwoOfAKind = true,
        HouseEdge = {
            enabled = true,
            targetRTP = 0.75,
            maxWinMultiplier = 8,
            consolationMultiplier = 0.5,
            lossStreakLimit = 4,
        },
        Multipliers = {
            jackpot = { 2, 5, 25, 50, 75, 100, 250, 500, 1000 },
            threeOfAKind = {
                diamonds = 25,
                sevens = 25,
                bells = 15,
                plums = 10,
                melons = 10,
                cherries = 5
            },
            twoOfAKind = {
                diamonds = 5,
                sevens = 5,
                bells = 3,
                plums = 2,
                melons = 2,
                cherries = 1
            },
            diamondBonus = 0
        }
    },

    -- KELAS MENENGAH: Evacuator, Space Ranger, Impotant Rage, Angel Knight, Twilight Knife
    [`vw_prop_casino_slot_03a`] = {
        BetAmounts = { 10000, 20000, 30000, 40000, 50000 },
        MisChance = 13,
        WinChance = 30,
        EnableTwoOfAKind = true,
        HouseEdge = {
            enabled = true,
            targetRTP = 0.70,
            maxWinMultiplier = 6,
            consolationMultiplier = 0.5,
            lossStreakLimit = 5,
        },
        Multipliers = {
            jackpot = { 2, 5, 25, 50, 75, 125, 250, 500, 1000 },
            threeOfAKind = {
                diamonds = 25,
                sevens = 25,
                bells = 15,
                plums = 10,
                melons = 10,
                cherries = 5
            },
            twoOfAKind = {
                diamonds = 5,
                sevens = 5,
                bells = 3,
                plums = 2,
                melons = 2,
                cherries = 1
            },
            diamondBonus = 0
        }
    },
    [`vw_prop_casino_slot_04a`] = {
        BetAmounts = { 10000, 20000, 30000, 40000, 50000 },
        MisChance = 13,
        WinChance = 30,
        EnableTwoOfAKind = true,
        HouseEdge = {
            enabled = true,
            targetRTP = 0.70,
            maxWinMultiplier = 6,
            consolationMultiplier = 0.5,
            lossStreakLimit = 5,
        },
        Multipliers = {
            jackpot = { 2, 5, 25, 50, 75, 125, 250, 500, 1000 },
            threeOfAKind = {
                diamonds = 25,
                sevens = 25,
                bells = 15,
                plums = 10,
                melons = 10,
                cherries = 5
            },
            twoOfAKind = {
                diamonds = 5,
                sevens = 5,
                bells = 3,
                plums = 2,
                melons = 2,
                cherries = 1
            },
            diamondBonus = 0
        }
    },
    [`vw_prop_casino_slot_05a`] = {
        BetAmounts = { 10000, 20000, 30000, 40000, 50000 },
        MisChance = 13,
        WinChance = 30,
        EnableTwoOfAKind = true,
        HouseEdge = {
            enabled = true,
            targetRTP = 0.70,
            maxWinMultiplier = 6,
            consolationMultiplier = 0.5,
            lossStreakLimit = 5,
        },
        Multipliers = {
            jackpot = { 2, 5, 25, 50, 75, 125, 250, 500, 1000 },
            threeOfAKind = {
                diamonds = 25,
                sevens = 25,
                bells = 15,
                plums = 10,
                melons = 10,
                cherries = 5
            },
            twoOfAKind = {
                diamonds = 5,
                sevens = 5,
                bells = 3,
                plums = 2,
                melons = 2,
                cherries = 1
            },
            diamondBonus = 0
        }
    },
    [`vw_prop_casino_slot_06a`] = {
        BetAmounts = { 10000, 20000, 30000, 40000, 50000 },
        MisChance = 13,
        WinChance = 30,
        EnableTwoOfAKind = true,
        HouseEdge = {
            enabled = true,
            targetRTP = 0.70,
            maxWinMultiplier = 6,
            consolationMultiplier = 0.5,
            lossStreakLimit = 5,
        },
        Multipliers = {
            jackpot = { 2, 5, 25, 50, 75, 125, 250, 500, 1000 },
            threeOfAKind = {
                diamonds = 25,
                sevens = 25,
                bells = 15,
                plums = 10,
                melons = 10,
                cherries = 5
            },
            twoOfAKind = {
                diamonds = 5,
                sevens = 5,
                bells = 3,
                plums = 2,
                melons = 2,
                cherries = 1
            },
            diamondBonus = 0
        }
    },
    [`vw_prop_casino_slot_07a`] = {
        BetAmounts = { 10000, 20000, 30000, 40000, 50000 },
        MisChance = 13,
        WinChance = 30,
        EnableTwoOfAKind = true,
        HouseEdge = {
            enabled = true,
            targetRTP = 0.70,
            maxWinMultiplier = 6,
            consolationMultiplier = 0.5,
            lossStreakLimit = 5,
        },
        Multipliers = {
            jackpot = { 2, 5, 25, 50, 75, 125, 250, 500, 1000 },
            threeOfAKind = {
                diamonds = 25,
                sevens = 25,
                bells = 15,
                plums = 10,
                melons = 10,
                cherries = 5
            },
            twoOfAKind = {
                diamonds = 5,
                sevens = 5,
                bells = 3,
                plums = 2,
                melons = 2,
                cherries = 1
            },
            diamondBonus = 0
        }
    },

    -- KELAS BAWAH: Fame or Shame
    [`vw_prop_casino_slot_08a`] = {
        BetAmounts = { 5000, 10000, 15000, 20000, 25000 },
        MisChance = 15,
        WinChance = 25,
        EnableTwoOfAKind = true,
        HouseEdge = {
            enabled = true,
            targetRTP = 0.65, -- Mesin kelas bawah, RTP lebih rendah
            maxWinMultiplier = 5,
            consolationMultiplier = 0.5,
            lossStreakLimit = 6,
        },
        Multipliers = {
            jackpot = { 2, 5, 25, 50, 75, 125, 250, 500, 1000 },
            threeOfAKind = {
                diamonds = 25,
                sevens = 25,
                bells = 15,
                plums = 10,
                melons = 10,
                cherries = 5
            },
            twoOfAKind = {
                diamonds = 5,
                sevens = 5,
                bells = 3,
                plums = 2,
                melons = 2,
                cherries = 1
            },
            diamondBonus = 0
        }
    }
}
