return {
    menuPosition = 'bottom-right',

    jobRequirement = {
        enabled = true,
        jobs = { 'ambulance', 'rsroxwood', 'police' }
    },

    maxAssignTime = {
        crutch = 10,
        wheelchair = 10,
        infus = 10
    },

    disableOnDeath = {
        crutch = true,
        wheelchair = true,
        infus = true
    },

    items = {
        crutch = { enabled = true, name = 'crutch' },
        wheelchair = { enabled = true, name = 'wheelchair' },
        infus = { enabled = true, name = 'infus' }
    },

    allowSelfUse = true,
    carKeyEvent = 'sm_vehiclekeys:client:setVehicleOwner',

    strings = {
        not_authorized      = 'Anda tidak memiliki izin untuk menggunakan ini!',
        no_one_nearby       = 'Tidak ada pemain di sekitar!',
        invalid_entry       = 'Input tidak valid, silakan coba lagi.',
        invalid_entry_max   = 'Waktu maksimal adalah %s menit!',
        cant_wield          = 'Tidak bisa menggunakan senjata saat memakai alat medis!',
        crutch_removed      = 'Kruk telah dilepas, Anda sudah merasa lebih baik!',
        chair_removed       = 'Kursi roda telah dilepas, Anda sudah merasa lebih baik!',
        infus_removed       = 'Tiang infus telah dilepas, Anda sudah merasa lebih baik!',
        crutch_added        = 'Kruk Terpasang',
        crutch_added_desc   = 'Disarankan memakai kruk selama %s menit!',
        chair_added         = 'Kursi Roda Terpasang',
        chair_added_desc    = 'Disarankan memakai kursi roda selama %s menit!',
        infus_added         = 'Tiang Infus Terpasang',
        infus_added_desc    = 'Disarankan memakai tiang infus selama %s menit!',
        player_id           = 'ID Pemain:',
        select_patient      = 'Pemain Terdekat',
        self_use            = 'Gunakan untuk Diri Sendiri',
        crutch_time_dialog  = 'Waktu Pemakaian Kruk',
        chair_time_dialog   = 'Waktu Pemakaian Kursi Roda',
        infus_time_dialog   = 'Waktu Pemakaian Tiang Infus',
        minutes_dialog      = 'Menit',
    }
}