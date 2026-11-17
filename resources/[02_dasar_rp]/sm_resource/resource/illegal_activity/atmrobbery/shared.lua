return {
    item = {
        start = {
            name = 'rope',
            count = 1
        },
        rewards = {
            { name = 'black_money', count = 446429, chance = 1.0 },
            { name = 'gunpowder', count = { min = 7, max = 10 }, chance = 0.5 }
        },
        atm_models = {
            [`ep_atm_02`] = 'atm1',
            [`ep_atm_03`] = 'atm2',
            [`ep_fleeca_atm`] = 'atm3',
        },
    },
    jobcheck = {
        police = 4,
        ems = 2
    },
    damage = {
        base = 5,
        cops_threshold = 5,
        vehicle_multiplier = {
            [`vectre`] = 1.5,
        },
        class_multiplier = {
            0.9, 1.0, 1.3, 0.9, 0.9,
            1.0, 1.0, 1.0, 0.0, 1.0,
            1.0, 1.0, 1.0, 0.0, 1.0,
            0.0, 0.0, 1.0, 1.0, 1.0,
            1.0, 0.0, 1.0,
        },
    },
    timing = {
        time_to_loot = 300,
        cooldown = 1200,
    },
    keys = {
        place_rope = 38,
        cancel = 73,
    },
    model = {
        [`prop_atm_02`] = `ep_atm_02`,
        [`prop_atm_03`] = `ep_atm_03`,
        [`prop_fleeca_atm`] = `ep_fleeca_atm`,
    },
    lang = {
        arm = "Pasang Tali ke ATM",
        steal = "Ambil ATM",
        place_rope = "Arahkan ke kendaraan lalu tekan [E]",
        attach_atm = "Arahkan ke ATM lalu tekan [E]",
        cooldown = "Semua ATM tidak tersedia. Cooldown: ",
        c4_success = "Bahan peledak berhasil dipasang.",
        c4_failed = "Gagal memasang bahan peledak! Sisa percobaan: ",
        c4_destroyed = "Kamu gagal 3 kali! C4 hancur dan tidak bisa digunakan lagi.",
        no_rope = "Kamu tidak memiliki tali!",
        service_unavailable = "Layanan saat ini tidak tersedia",
        min_police = "Minimal 3 polisi online diperlukan",
        collected = "ATM berhasil diambil",
        too_far = "Kamu terlalu jauh dari ATM",
        not_ready = "ATM belum siap untuk diambil",
        inv_full = "Inventory penuh",
    }
}