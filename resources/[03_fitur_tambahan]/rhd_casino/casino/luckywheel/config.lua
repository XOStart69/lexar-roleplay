return {
    WheelPos = vec(949.69, 45.07, 70.9, 328.0),
    InteractPos = vec(949.3759, 44.6235, 71.6380),

    MaxDistance = 3.0,

    SpinPrice = 5000,

    -- Offset kalibrasi rotasi roda (derajat).
    -- Naikkan/turunkan nilainya sampai /showrewards 1 tepat menunjuk hadiah #1.
    -- Contoh: jika posisi meleset ke kanan, turunkan nilainya.
    WheelOffset = 0,

    -- Setiap pemain mendapat 1 free spin setiap N jam (disimpan di cache)
    FreeSpin = {
        enabled = true, -- aktifkan/nonaktifkan fitur free spin
        cooldownHours = 24, -- reset free spin setiap N jam (default: 24 jam)
    },

    -- Batasi total spin (berbayar + gratis) menjadi 1x per hari
    -- Jika FreeSpin.enabled = true, maka 1x spin per hari tersebut gratis
    -- Jika FreeSpin.enabled = false, pemain tetap harus membayar tapi hanya bisa 1x per hari
    DailySpin = {
        enabled = true, -- aktifkan/nonaktifkan batasan 1 spin per hari
    },

    VehiclePrizeCooldown = {
        enabled = true,
        hours = 72,
        prizeNames = {
            voucher_kendaraan_casino = true,
        },
    },

    -- Level kesulitan global lucky wheel.
    -- level: pilih salah satu kunci di presets ('easy'|'normal'|'hard'|'rigged').
    -- winChance: peluang (0-100, boleh desimal) hadiah non-zonk benar-benar diberikan.
    --            Jika gagal, hasil dipaksa zonk (kalah penuh).
    Difficulty = {
        level = 'hard',
        presets = {
            easy = { winChance = 100.0 },
            normal = { winChance = 100.0 },
            hard = { winChance = 20.0 },
            rigged = { winChance = 0.1 },
        },
    },

    --- Prizes Setting
    --
    -- type :
    -- | 'Zonk'
    -- | 'item' (gunakan item dengan ox_inventory)
    -- | 'money' (tunai langsung)
    -- | 'vehicle' hadiah kendaraan (akan disimpan di garasi yang ditentukan di bawah)

    -- name : jika item mempunyai label yang berbeda dengan nama item di ox_inventory, gunakan field label untuk menampilkan nama hadiah di UI
    -- sound : 'car' | 'cash' | 'clothes' | 'chips' | 'mystery' | 'win'
    -- chance: persentase kemunculan (0.0–100.0), total semua prize harus = 100
    -- vipChance: (opsional) pengganti chance untuk pemegang kartu VIP aktif
    --
    -- Urutan [1]–[20] = urutan segmen roda searah jarum jam (masing-masing 18°)
    -- Sesuai tampilan visual roda di dalam game

    Prizes = {
        [1] = { type = 'zonk', name = 'Zonk', count = 0, sound = 'mystery', chance = 10.0, vipChance = 7.72 },
        [2] = { type = 'money', name = 'money', label = 'Money', count = 200000, sound = 'cash', chance = 0.75, vipChance = 3.0 },
        [3] = { type = 'item', name = 'voucher_kendaraan_casino', label = 'Vehicle Voucher', count = 1, sound = 'car', chance = 0.5 },
        [4] = { type = 'zonk', name = 'Zonk', count = 0, sound = 'mystery', chance = 10.0, vipChance = 7.72 },
        [5] = { type = 'zonk', name = 'Zonk', count = 0, sound = 'mystery', chance = 10.0, vipChance = 7.72 },
        [6] = { type = 'item', name = 'casino_chips', label = 'Casino Chips', count = 150000, sound = 'chips', chance = 1.25, vipChance = 3.0 },
        [7] = { type = 'money', name = 'money', label = 'Money', count = 150000, sound = 'cash', chance = 1.0, vipChance = 3.0 },
        [8] = { type = 'zonk', name = 'Zonk', count = 0, sound = 'mystery', chance = 10.0, vipChance = 7.72 },
        [9] = { type = 'zonk', name = 'Zonk', count = 0, sound = 'mystery', chance = 10.0, vipChance = 7.72 },
        [10] = { type = 'item', name = 'kupongacha_casino', label = 'Mystery', count = 1, sound = 'mystery', chance = 0.75, vipChance = 3.0 },
        [11] = { type = 'item', name = 'casino_chips', label = 'Casino Chips', count = 75000, sound = 'cash', chance = 1.0, vipChance = 3.0 },
        [12] = { type = 'zonk', name = 'Zonk', count = 0, sound = 'mystery', chance = 10.0, vipChance = 7.72 },
        [13] = { type = 'zonk', name = 'Zonk', count = 0, sound = 'mystery', chance = 10.0, vipChance = 7.72 },
        [14] = { type = 'item', name = 'casino_chips', label = 'Casino Chips', count = 200000, sound = 'chips', chance = 1.0, vipChance = 3.0 },
        [15] = { type = 'money', name = 'money', label = 'Money', count = 100000, sound = 'cash', chance = 1.25, vipChance = 3.0 },
        [16] = { type = 'zonk', name = 'Zonk', count = 0, sound = 'mystery', chance = 10.0, vipChance = 7.72 },
        [17] = { type = 'item', name = 'voucher_diskon_casino', label = 'Discount', count = 1, sound = 'mystery', chance = 0.75, vipChance = 3.0 },
        [18] = { type = 'item', name = 'casino_chips', label = 'Casino Chips', count = 250000, sound = 'chips', chance = 0.75, vipChance = 3.0 },
        [19] = { type = 'money', name = 'money', label = 'Money', count = 50000, sound = 'cash', chance = 1.0, vipChance = 3.0 },
        [20] = { type = 'zonk', name = 'Zonk', count = 0, sound = 'mystery', chance = 10.0, vipChance = 7.72 },
    },

    Vehicle = {
        model = 'simprezawrx22',
        previewLoc = vec(935.3254, 42.5033, 72.2481, 130.6376),
        rotation = true,
        default_garage = 'motelgarage',

        --- paint type:
        --- | 0 = Normal
        --- | 1 = Metalic
        --- | 2 = Pearl
        --- | 3 = Matte
        --- | 4 = Metal
        --- | 5 = Chrome

        color = {
            type = 0,
            primary = 'rgb(184, 245, 0)',
            secondary = 'rgb(184, 245, 0)',
        },
    },
}
