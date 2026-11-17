local Config = {}

-- Pengaturan Umum
Config.Command = 'billing' -- Command untuk membuka menu billing
Config.MaxInvoiceAmount = 100000000 -- Maksimal jumlah invoice
Config.MinInvoiceAmount = 1 -- Minimal jumlah invoice

-- Pengaturan Bunga dan Keterlambatan
Config.EnableOverdueInterest = true -- Aktifkan bunga keterlambatan
Config.OverdueDays = 7 -- Hari setelah invoice dianggap terlambat
Config.InterestRate = 0.05 -- 5% bunga per hari keterlambatan
Config.MaxInterestDays = 30 -- Maksimal hari bunga dihitung

-- Pengaturan Auto Collection
Config.EnableAutoCollection = true -- Aktifkan auto collection
Config.AutoCollectionInterval = 60 -- Interval check auto collection (menit)

-- Pengaturan Auto Collection berdasarkan Job (dalam hari)
Config.AutoCollectionDays = {
    ['police'] = 3, -- Polisi auto collection setelah 7 hari
    ['usmarshal'] = 3, -- Polisi auto collection setelah 7 hari
    ['ambulance'] = 3,
    ['puskesmas'] = 3,
    ['rsroxwood'] = 3,
    ['pengadilan'] = 3,
    ['government'] = 3,
    ['paspampres'] = 3,
    ['mechanic'] = 3,
    ['stunberg'] = 3,
    ['maxspeedgarage'] = 3,
    ['mechanic969'] = 3,
    ['kkpgarage'] = 3,
    ['taxism'] = 3,
    ['velvetsm'] = 3,
    ['burgershot'] = 3,
    ['uwu'] = 3,
    ['bahama'] = 3,
    ['tequilala'] = 3,
    ['pabrik'] = 3,
    ['resto'] = 3,
    ['pdcafe'] = 3,
    ['kkpresto'] = 3,
    ['digitalden'] = 3,
    ['digitaldenroxwood'] = 3,
    ['gzcafe'] = 3,
    ['mhcafe'] = 3,
    ['wartelsm'] = 3,
    ['reporter'] = 3,
    ['paud'] = 3,
    smmotel = 3,
    ['default'] = 3
}

-- Pengaturan Auto Debit
Config.EnableAutoDebit = true -- Aktifkan auto debit dari bank
Config.AutoDebitNotification = true -- Notifikasi saat auto debit
Config.AutoDebitMaxAttempts = 3 -- Maksimal percobaan auto debit
Config.AutoDebitRetryInterval = 24 -- Interval retry auto debit (jam)

-- Pengaturan Keamanan
Config.RequireApproval = false -- Apakah invoice perlu persetujuan
Config.AdminGroups = {'admin', 'god'} -- Group yang bisa approve/cancel invoice

-- Pengaturan Pajak per Society
Config.TaxRates = {
    ['police'] = 0.80,      -- 50% masuk ke pajak/pemerintah
    ['usmarshal'] = 0.50,      -- 50% masuk ke pajak/pemerintah
    ['ambulance'] = 0.10,   -- 10% masuk ke pajak/pemerintah (society)
    ['puskesmas'] = 0.25,   -- 10% masuk ke pajak/pemerintah (society)
    ['rsroxwood'] = 0.25,   -- 10% masuk ke pajak/pemerintah (society)
    ['resto'] = 0.60,   -- 10% masuk ke pajak/pemerintah (society)
    ['kkpresto'] = 0.65,   -- 10% masuk ke pajak/pemerintah (society)
    ['pdcafe'] = 0.70,   -- 10% masuk ke pajak/pemerintah (society)
    ['mechanic'] = 0.70,
    ['stunberg'] = 0.70,
    ['maxspeedgarage'] = 0.70,
    ['mechanic969'] = 0.70,
    ['kkpgarage'] = 0.70,
    ['digitalden'] = 0.70,
    ['digitaldenroxwood'] = 0.70,
    ['gzcafe'] = 0.70,
    ['mhcafe'] = 0.70,
    ['wartelsm'] = 0.70,
    ['pabrik'] = 0.95,
    ['pengadilan'] = 0.50,
    ['government'] = 0.80,
    ['paspampres'] = 0.80,
    ['taxism'] = 0.40,
    ['velvetsm'] = 0.95,
    ['burgershot'] = 0.15,
    ['nightclub'] = 0.80,
    ['luxurynightclub'] = 0.80,
    ['reporter'] = 0.50,
    ['paud'] = 0.50,  
    ['default'] = 0.12,
    burgenkcafe = 0.80,
    smmotel = 0.50
}

Config.CommissionRates = {
    ['ambulance'] = {
        [0] = 0.90, -- Grade 0: Player dapat 90% dari total invoice
        [1] = 0.90, -- Grade 1: Player dapat 90% dari total invoice
        [2] = 0.90, -- Grade 2: Player dapat 90% dari total invoice
        [3] = 0.90, -- Grade 3: Player dapat 90% dari total invoice
        [4] = 0.90, -- Grade 4: Player dapat 90% dari total invoice
        [5] = 0.90, -- Grade 5: Player dapat 90% dari total invoice
        [6] = 0.90, -- Grade 6: Player dapat 90% dari total invoice
        [7] = 0.90, -- Grade 7: Player dapat 90% dari total invoice
        [8] = 0.90, -- Grade 8: Player dapat 90% dari total invoice
        [9] = 0.90, -- Grade 9: Player dapat 90% dari total invoice
        [10] = 0.90, -- Grade 10: Player dapat 90% dari total invoice
    },
    smmotel = {
        [0] = 0.20,
        [1] = 0.20,
        [2] = 0.20,
        [3] = 0.20,
    },
    ['rsroxwood'] = {
        [0] = 0.75,
        [1] = 0.75,
        [2] = 0.75,
        [3] = 0.75,
        [4] = 0.75,
        [5] = 0.75,
        [6] = 0.75,
        [7] = 0.75,
        [8] = 0.75,
        [9] = 0.75,
        [10] = 0.75,
        [11] = 0.75,
    },
    ['puskesmas'] = {
        [0] = 0.75, -- Grade 0: Player dapat 90% dari total invoice
        [1] = 0.75, -- Grade 1: Player dapat 90% dari total invoice
        [2] = 0.75, -- Grade 2: Player dapat 90% dari total invoice
        [3] = 0.75, -- Grade 3: Player dapat 90% dari total invoice
    },
    burgenkcafe = {
        [0] = 0.20,
        [1] = 0.20,
        [2] = 0.20,
        [3] = 0.20,
        [4] = 0.20,
        [5] = 0.20,
        [6] = 0.20,
        [7] = 0.20,
    },
    ['nightclub'] = {
        [0] = 0.20, -- Grade 0: Player dapat 90% dari total invoice
        [1] = 0.20, -- Grade 1: Player dapat 90% dari total invoice
        [2] = 0.20, -- Grade 2: Player dapat 90% dari total invoice
        [3] = 0.20, -- Grade 3: Player dapat 90% dari total invoice
        [4] = 0.20, -- Grade 4: Player dapat 90% dari total invoice
    },
    ['luxurynightclub'] = {
        [0] = 0.20, -- Grade 0: Player dapat 90% dari total invoice
        [1] = 0.20, -- Grade 1: Player dapat 90% dari total invoice
        [2] = 0.20, -- Grade 2: Player dapat 90% dari total invoice
        [3] = 0.20, -- Grade 3: Player dapat 90% dari total invoice
        [4] = 0.20, -- Grade 4: Player dapat 90% dari total invoice
    },
    ['kkpresto'] = {
        [0] = 0.35, -- Grade 0: Player dapat 90% dari total invoice
        [1] = 0.35, -- Grade 1: Player dapat 90% dari total invoice
        [2] = 0.35, -- Grade 2: Player dapat 90% dari total invoice
        [3] = 0.35, -- Grade 3: Player dapat 90% dari total invoice
        [4] = 0.35, -- Grade 4: Player dapat 90% dari total invoice
    },
    ['pdcafe'] = {
        [0] = 0.30, -- Grade 0: Player dapat 90% dari total invoice
        [1] = 0.30, -- Grade 1: Player dapat 90% dari total invoice
        [2] = 0.30, -- Grade 2: Player dapat 90% dari total invoice
        [3] = 0.30, -- Grade 3: Player dapat 90% dari total invoice
        [4] = 0.30, -- Grade 4: Player dapat 90% dari total invoice
    },
    ['digitalden'] = {
        [0] = 0.30, -- Grade 0: Player dapat 90% dari total invoice
        [1] = 0.30, -- Grade 1: Player dapat 90% dari total invoice
        [2] = 0.30, -- Grade 2: Player dapat 90% dari total invoice
        [3] = 0.30, -- Grade 3: Player dapat 90% dari total invoice
        [4] = 0.30, -- Grade 4: Player dapat 90% dari total invoice
    },
    ['digitaldenroxwood'] = {
        [0] = 0.30, -- Grade 0: Player dapat 90% dari total invoice
        [1] = 0.30, -- Grade 1: Player dapat 90% dari total invoice
        [2] = 0.30, -- Grade 2: Player dapat 90% dari total invoice
        [3] = 0.30, -- Grade 3: Player dapat 90% dari total invoice
        [4] = 0.30, -- Grade 4: Player dapat 90% dari total invoice
    },    
    ['gzcafe'] = {
        [0] = 0.30, -- Grade 0: Player dapat 90% dari total invoice
        [1] = 0.30, -- Grade 1: Player dapat 90% dari total invoice
        [2] = 0.30, -- Grade 2: Player dapat 90% dari total invoice
        [3] = 0.30, -- Grade 3: Player dapat 90% dari total invoice
        [4] = 0.30, -- Grade 4: Player dapat 90% dari total invoice
    },    
    ['mhcafe'] = {
        [0] = 0.30, -- Grade 0: Player dapat 90% dari total invoice
        [1] = 0.30, -- Grade 1: Player dapat 90% dari total invoice
        [2] = 0.30, -- Grade 2: Player dapat 90% dari total invoice
        [3] = 0.30, -- Grade 3: Player dapat 90% dari total invoice
        [4] = 0.30, -- Grade 4: Player dapat 90% dari total invoice
    },
    ['wartelsm'] = {
        [0] = 0.30, -- Grade 0: Player dapat 90% dari total invoice
        [1] = 0.30, -- Grade 1: Player dapat 90% dari total invoice
        [2] = 0.30, -- Grade 2: Player dapat 90% dari total invoice
        [3] = 0.30, -- Grade 3: Player dapat 90% dari total invoice
        [4] = 0.30, -- Grade 4: Player dapat 90% dari total invoice
    },
    ['usmarshal'] = {
        [0] = 0.50, -- Grade 0: Player dapat 90% dari total invoice
        [1] = 0.50, -- Grade 1: Player dapat 90% dari total invoice
        [2] = 0.50, -- Grade 2: Player dapat 90% dari total invoice
        [3] = 0.50, -- Grade 3: Player dapat 90% dari total invoice
        [4] = 0.50, -- Grade 4: Player dapat 90% dari total invoice
        [5] = 0.50, -- Grade 5: Player dapat 90% dari total invoice
    },
    ['police'] = {
        [0] = 0.20,
        [1] = 0.20,
        [2] = 0.20,
        [3] = 0.20,
        [4] = 0.20,
        [5] = 0.20,
        [6] = 0.20,
        [7] = 0.20,
        [8] = 0.20,
        [9] = 0.20,
        [10] = 0.20,
        [11] = 0.20,
        [12] = 0.20,
        [13] = 0.20,
        [14] = 0.20,
        [15] = 0.20,
        [16] = 0.20,
    },
    ['reporter'] = {
        [0] = 0.50,
        [1] = 0.50,
        [2] = 0.50,
        [3] = 0.50,
    },
    ['paud'] = {
        [0] = 0.50,
        [1] = 0.50,
        [2] = 0.50,
        [3] = 0.50,
        [4] = 0.50,
        [5] = 0.50,
        [6] = 0.50,
        [7] = 0.50,
        [8] = 0.50,
        [9] = 0.50,
    },
    ['pengadilan'] = {
        [0] = 0.50,
        [1] = 0.50,
        [2] = 0.50,
        [3] = 0.50,
        [4] = 0.50,
        [5] = 0.50,
        [6] = 0.50,
        [7] = 0.50,
        [8] = 0.50,
        [9] = 0.50,
        [10] = 0.50,
        [11] = 0.50,
    },
    ['government'] = {
        [0] = 0.20,
        [1] = 0.20,
        [2] = 0.20,
        [3] = 0.20,
        [4] = 0.20,
        [5] = 0.20,
        [6] = 0.20,
        [7] = 0.20,
        [8] = 0.20,
        [9] = 0.20,
        [10] = 0.20,
        [11] = 0.20,
        [12] = 0.20,
        [13] = 0.20,
    },
    ['paspampres'] = {
        [0] = 0.20,
        [1] = 0.20,
        [2] = 0.20,
        [3] = 0.20,
        [4] = 0.20,
        [5] = 0.20,
        [6] = 0.20,
        [7] = 0.20,
        [8] = 0.20,
        [9] = 0.20,
        [10] = 0.20,
    },
    ['mechanic'] = {
        [0] = 0.30,
        [1] = 0.30,
        [2] = 0.30,
        [3] = 0.30,
        [4] = 0.30,
    },
    ['stunberg'] = {
        [0] = 0.30,
        [1] = 0.30,
        [2] = 0.30,
        [3] = 0.30,
        [4] = 0.30,
    },
    ['maxspeedgarage'] = {
        [0] = 0.30,
        [1] = 0.30,
        [2] = 0.30,
        [3] = 0.30,
        [4] = 0.30,
    },
    ['kkpgarage'] = {
        [0] = 0.30,
        [1] = 0.30,
        [2] = 0.30,
        [3] = 0.30,
        [4] = 0.30,
    },
    ['mechanic969'] = {
        [0] = 0.30,
        [1] = 0.30,
        [2] = 0.30,
        [3] = 0.30,
        [4] = 0.30,
    },
    ['taxism'] = {
        [0] = 0.60,
        [1] = 0.60,
        [2] = 0.60,
        [3] = 0.60,
        [4] = 0.60,
    },
    ['velvetsm'] = {
        [0] = 0.05,
        [1] = 0.05,
        [2] = 0.05,
        [3] = 0.05,
        [4] = 0.05,
    },
    ['resto'] = {
        [0] = 0.4,
        [1] = 0.4,
        [2] = 0.4,
        [3] = 0.4,
        [4] = 0.4   
    },
    ['pabrik'] = {
        [0] = 0.05,
        [1] = 0.05,
        [2] = 0.05,
        [3] = 0.05,
        [4] = 0.05  
    },
    ['default'] = {
        [0] = 0.0,
        [1] = 0.0,
        [2] = 0.0,
        [3] = 0.0,
        [4] = 0.0
    }
}

-- Job yang diizinkan membuat invoice baru (job khusus)
Config.AllowedJobsCreateInvoice = {
    'police',
    'usmarshal',
    'reporter',
    'paud',
    'digitalden',
    'digitaldenroxwood',
    'gzcafe',
    'mhcafe',
    'wartelsm',
    'ambulance',
    'pengadilan',
    'mechanic',
    'stunberg',
    'maxspeedgarage',
    'kkpgarage',
    'mechanic969',
    'taxism',
    'velvetsm',
    'government',
    'paspampres',
    'puskesmas',
    'rsroxwood',
    'pabrik',
    'resto',
    'kkpresto',
    'pdcafe',
    'nightclub',
    'luxurynightclub',
    'burgenkcafe',
    'smmotel'
}

-- Item Pre-set untuk setiap society
Config.PresetItems = {
    -- ['police'] = {
    --     {label = 'Denda Parkir', price = 500, description = 'Denda parkir sembarangan'},
    --     {label = 'Denda Kecepatan', price = 1000, description = 'Denda melanggar batas kecepatan'},
    --     {label = 'Denda Lampu Merah', price = 750, description = 'Denda melanggar lampu merah'},
    --     {label = 'Denda Dokumen', price = 300, description = 'Denda tidak membawa dokumen'}
    -- },
    ['ambulance'] = {
        -- Paket Obat Farmasi
        {label = 'Paket A Dewasa (10 bdg + 2 pct)', price = 60000, description = 'Biaya obat farmasi'},
        {label = 'Paket B Dewasa (20 bdg + 4 pct)', price = 90000, description = 'Biaya obat farmasi'},
        {label = 'Paket A Anak (10 bdg + 5 pct)', price = 55000, description = 'Biaya obat farmasi'},
        {label = 'Paket B Anak (20 bdg + 10 pct)', price = 85000, description = 'Biaya obat farmasi'},
        {label = 'Paket Polisi (20 bdg + 10 pct)', price = 60000, description = 'Biaya obat farmasi'},
        {label = 'Paket EMS (10 bdg + 5 pct)', price = 70000, description = 'Biaya obat farmasi'},
        {label = 'Paket Paket Kerja Sama ( 20 Bandage + 4 PCT)', price = 76000, description = 'Biaya obat farmasi'},
        
        -- Treatment Services
        {label = 'Treatment RS', price = 17000, description = 'Biaya treatment di rumah sakit'},
        {label = 'Treatment Instansi', price = 15000, description = 'Biaya treatment di instansi'},
        {label = 'Treatment Polisi/Marshal', price = 10000, description = 'Biaya treatment untuk Polisi/Marshal'},
        {label = 'Treatment Penanganan Event', price = 25000, description = 'Biaya treatment penanganan event'},
        
        -- Revive Services
        {label = 'Revive RS', price = 20000, description = 'Biaya revive di rumah sakit'},
        {label = 'Revive Instansi', price = 17000, description = 'Biaya revive di instansi'},
        {label = 'Revive Kota', price = 23000, description = 'Biaya revive di kota'},
        {label = 'Revive Sandy Shores', price = 25000, description = 'Biaya revive di Sandy Shores'},
        {label = 'Revive Paleto', price = 27000, description = 'Biaya revive di Paleto'},
        {label = 'Revive Perang', price = 30000, description = 'Biaya revive saat perang'},
        {label = 'Revive Tenggelam', price = 30000, description = 'Biaya revive tenggelam'},
        {label = 'Revive Polisi/Marshal', price = 12000, description = 'Biaya revive untuk Polisi/Marshal'},
        {label = 'Revive Penanganan Event', price = 30000, description = 'Biaya revive penanganan event'},
        {label = 'Revive Kerja Sama', price = 20000, description = 'Biaya revive kerja sama'},
        
        --servicesidcard
        {label = 'Kartu Kesehatan', price = 25000, description = 'Medical Documents'},
        {label = 'Surat Kesehatan', price = 30000, description = 'Medical Documents'},

    },
    ['resto'] = {
        {label = '1 Paket Dine In', price = 20000, description = 'Nusantara Resto - Dine In'},
        {label = '2 Paket Dine In', price = 40000, description = 'Nusantara Resto - Dine In'},
        {label = '1 Paket Takeaway', price = 30000, description = 'Nusantara Resto - Takeaway'},
        {label = '2 Paket Takeaway', price = 60000, description = 'Nusantara Resto - Takeaway'},
        {label = '5 Paket Takeaway', price = 150000, description = 'Nusantara Resto - Takeaway'},
        {label = '10 Paket Takeaway', price = 300000, description = 'Nusantara Resto - Takeaway'},
        {label = '100 Paket Takeaway', price = 2700000, description = 'Nusantara Resto - Takeaway'},
        {label = '1 Paket Kidsmeal', price = 30000, description = 'Nusantara Resto - Kidsmeal'},
        {label = '3 Paket Kidsmeal', price = 90000, description = 'Nusantara Resto - Kidsmeal'},
        {label = '1 Paket Cemilan', price = 20000, description = 'Nusantara Resto - Cemilan'},
        {label = '1 Paket Combo', price = 50000, description = 'Nusantara Resto - Combo'},
        {label = '20 Paket Req Menu', price = 900000, description = 'Nusantara Resto - Request Menu'},
        {label = '100 Paket Req Menu', price = 4050000, description = 'Nusantara Resto - Request Menu'},
        {label = 'Catering Maxspeed', price = 562500, description = 'Nusantara Resto - Catering'},
    },
    -- ['mechanic'] = {
    --     {label = 'Perbaikan Ringan', price = 1500, description = 'Perbaikan ringan kendaraan'},
    --     {label = 'Perbaikan Berat', price = 3000, description = 'Perbaikan berat kendaraan'},
    --     {label = 'Ganti Oli', price = 200, description = 'Ganti oli mesin'},
    --     {label = 'Ganti Ban', price = 800, description = 'Ganti ban kendaraan'},
    --     {label = 'Cat Kendaraan', price = 2500, description = 'Cat ulang kendaraan'}
    -- },
    -- ['burgershot'] = {
    --     {label = 'Burger Combo', price = 25, description = 'Burger dengan kentang dan minuman'},
    --     {label = 'Burger Biasa', price = 15, description = 'Burger biasa'},
    --     {label = 'Kentang Goreng', price = 8, description = 'Kentang goreng crispy'},
    --     {label = 'Minuman Soda', price = 5, description = 'Minuman soda dingin'}
    -- }
}

-- Pengaturan Company Logs System
Config.CompanyLogs = {
    ['digitalden'] = {
        enabled = true,
        minGrade = 4,
        locations = {
            {
                coords = vec3(-1336.8, -411.2, 37.05),
                heading = 240.0,
                distance = 2.0,
                label = "Akses Log Perusahaan YGM"
            },
        }
    },
    ['digitaldenroxwood'] = {
        enabled = true,
        minGrade = 3,
        locations = {
            {
                coords = vec3(-2932.35, 6240.62, 9.67),
                heading = 240.0,
                distance = 2.0,
                label = "Akses Log Perusahaan Digital Den Roxwood"
            },
        }
    },
    ['taxism'] = {
        enabled = true,
        minGrade = 3,
        locations = {
            {
                coords = vec3(-794.346008, -1348.759033, 12.056185),
                heading = 240.0,
                distance = 2.0,
                label = "Akses Log Perusahaan Taxi"
            },
        }
    },
    ['resto'] = {
        enabled = true,
        minGrade = 4,
        locations = {
            {
                coords = vector3(-1778.705444, -1215.045776, 14.765355),
                heading = 240.0,
                distance = 2.0,
                label = "Akses Log Perusahaan Nusantara Resto"
            },
        }
    },
    ['kkpresto'] = {
        enabled = true,
        minGrade = 4,
        locations = {
            {
                coords = vector3(-596.669128, -1052.830566, 22.245209),
                heading = 240.0,
                distance = 2.0,
                label = "Akses Log Perusahaan KKP"
            },
        }
    },
    ['pdcafe'] = {
        enabled = true,
        minGrade = 4,
        locations = {
            {
                coords = vector3(-1314.498535, 6977.953613, 20.643463),
                heading = 240.0,
                distance = 2.0,
                label = "Akses Log Perusahaan UpnAtom"
            },
        }
    },
    ['rsroxwood'] = {
        enabled = true,
        minGrade = 10,
        locations = {
            {
                coords = vector3(-482.204041, 7456.774414, 8.154289),
                heading = 240.0,
                distance = 2.0,
                label = "Akses Log Perusahaan RSRxw"
            },
        }
    },

    ['burgenkcafe'] = {
        enabled = true,
        minGrade = 7,
        locations = {
            {
                coords = vec3(1533.943237, 3786.089355, 34.610596),
                heading = 240.0,
                distance = 2.0,
                label = "Akses Log Perusahaan 969Resto"
            },
        }
    },
    
    ['smmotel'] = {
        enabled = true,
        minGrade = 3,
        locations = {
            {
                coords = vec3(-818.885315, -690.684692, 27.958401),
                heading = 88.8794,
                distance = 2.0,
                label = "Akses Log Perusahaan SMMotel"
            },
        }
    },
    ['luxurynightclub'] = {
        enabled = true,
        minGrade = 4,
        locations = {
            {
                coords = vec3(48.320881, 6513.389160, 35.629547),
                heading = 240.0,
                distance = 2.0,
                label = "Akses Log Perusahaan ECLUB"
            },
        }
    },
    ['nightclub'] = {
        enabled = true,
        minGrade = 4,
        locations = {
            {
                coords = vec3(95.1754, -1299.4720, 35.5849),
                heading = 240.0,
                distance = 2.0,
                label = "Akses Log Perusahaan MaxClub"
            },
        }
    },
    ['mhcafe'] = {
        enabled = true,
        minGrade = 4,
        locations = {
            {
                coords = vec3(-280.543823, 6691.804199, 8.046207),
                heading = 240.0,
                distance = 2.0,
                label = "Akses Log Perusahaan Maison Rainhart"
            },
        }
    },
    ['gzcafe'] = {
        enabled = true,
        minGrade = 4,
        locations = {
            {
                coords = vec3(-2164.39, 4203.14, 37.36),
                heading = 240.0,
                distance = 2.0,
                label = "Akses Log Perusahaan ECL Kedai"
            },
        }
    },
    ['ambulance'] = {
        enabled = true,
        minGrade = 6,
        locations = {
            {
                coords = vector3(1098.981689, -1521.043213, 40.114342),
                heading = 340.0,
                distance = 2.0,
                label = "Akses Log EMS"
            },
            -- {
            --     coords = vector3(x, y, z),
            --     heading = 0.0,
            --     distance = 2.0,
            --     label = "Akses Log EMS - Ruang Meeting"
            -- },
        }
    }
}

-- Pengaturan Notifikasi
Config.Notifications = {
    ['invoice_created'] = {
        title = 'Invoice Dibuat',
        description = 'Invoice berhasil dibuat dan dikirim',
        type = 'success'
    },
    ['invoice_paid'] = {
        title = 'Invoice Dibayar',
        description = 'Invoice berhasil dibayar',
        type = 'success'
    },
    ['invoice_cancelled'] = {
        title = 'Invoice Dibatalkan',
        description = 'Invoice berhasil dibatalkan',
        type = 'inform'
    },
    ['insufficient_funds'] = {
        title = 'Dana Tidak Cukup',
        description = 'Anda tidak memiliki cukup uang untuk membayar invoice ini',
        type = 'error'
    },
    ['no_permission'] = {
        title = 'Tidak Ada Izin',
        description = 'Anda tidak memiliki izin untuk melakukan tindakan ini',
        type = 'error'
    },
    ['invoice_overdue'] = {
        title = 'Invoice Terlambat',
        description = 'Invoice Anda sudah terlambat dan dikenakan bunga',
        type = 'warning'
    }
}

-- Pengaturan Database
Config.Database = {
    ['invoices'] = 'qb_invoices',
    ['invoice_items'] = 'qb_invoice_items',
    ['invoice_logs'] = 'qb_invoice_logs'
}

return Config