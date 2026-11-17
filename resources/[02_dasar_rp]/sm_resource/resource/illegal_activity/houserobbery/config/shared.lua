return {
    
    coreName = "qb-core", --if you use qbox just leave qb-core

    lang = {
        ["nolockpick"] = "Kamu membutuhkan alat yang lebih canggih!",
        ["nopolice"] = "Tidak ada polisi yang bertugas saat ini!",
        ["noxp"] = "Pengalaman kamu tidak cukup untuk rumah ini!",
        ["noinfo"] = "Kamu tidak punya informasi tentang rumah ini! Beli dulu di telepon umum.",
        ["+xp"] = "Kamu mendapat ",
        ["busy"] = "Sedang digunakan oleh orang lain",
        ["notpolice"] = "Kamu bukan polisi!",
        ["nohouse"] = "Rumah ini tidak terbuka atau tidak ditemukan!",
        ["closedoor"] = "Kamu menutup rumah yang dirampok!",
        ["cantcarry"] = "Kamu tidak bisa membawa barang ini!",
        ["alreadycarry"] = "Kamu tidak bisa membawa barang sekarang!",
        ["rob"] = "Merampok...",
        ["search"] = "Geledah",
        ["enter"] = "[E] Masuk",
        ["leave"] = "[E] Keluar",
        
        -- Additional Indonesian messages for better UX
        ["already_opened"] = "Rumah ini sudah terbuka!",
        ["wrong_time"] = "Perampokan hanya bisa dilakukan antara jam 22:00 - 05:00!",
        ["lockpick_broken"] = "Alat pembuka kunci patah!",
        ["lockpick_success"] = "Berhasil membuka pintu dengan hati-hati!",
        ["lockpick_failed"] = "Gagal membuka pintu!",
        ["alarm_triggered"] = "Alarm rumah berbunyi! Polisi sudah dipanggil!",
        ["alarm_silent"] = "Alarm tersembunyi aktif! Polisi mungkin sudah tahu!",
        ["loot_success"] = "Kamu menemukan beberapa barang berharga!",
        ["pickup_success"] = "Berhasil mengambil barang!",
        ["inventory_full"] = "Inventori penuh, tidak bisa mengambil barang!",
        ["house_closed"] = "Rumah berhasil ditutup dan dikembalikan ke kondisi semula!"


    },

    houseInfoSystem = {
        models = {
            'prop_phonebox_01b',
            'prop_phonebox_01a',
            'prop_phonebox_03',
            'prop_payphone_02',
            'prop_phonebox_04'
            -- Tambah model lain sesuai kebutuhan
        },
        price = 500, -- Biaya untuk mendapatkan info rumah
        blipDuration = 30000, -- 30 detik dalam milliseconds
        blipSprite = 40, -- House icon
        blipColor = 5, -- Yellow
        blipScale = 0.6, -- Small size
        blipName = "Target House",
    },

    
    -- Pre set interiors to use in Config.Houses. Shouldn't touch this unless you know what you are doing. You can however change the skillcheck difficulty.
    -- And change the loot pools around to give players different rewards. The player will randomly get the rewards from one of the pools defined underneath.
    interiors = {
        [1] = {
            exit = vec4(151.35, -1007.96, -99.0, 179.12),
            peds = {
                vec4(154.75, -1004.24, -98.42, 168.83),
            },
            skillcheck = {'easy', 'medium', 'easy', 'medium'},
            loot = {
                {coords = vec3(150.93, -1004.59, -99.45), pool = {1, 3, 4}},
                {coords = vec3(155.17, -1003.32, -99.43), pool = {1, 2, 3, 4}},
                {coords = vec3(150.98, -1003.13, -99.37), pool = {1, 2, 4}},
                {coords = vec3(151.45, -1001.48, -98.95), pool = {1, 3, 4}},
                {coords = vec3(155.26, -1005.86, -99.27), pool = {1, 2, 3, 4}},
                -- {coords = vec3(153.5, -1004.6, -99.41), pool = {1, 2, 3, 4}},
                -- {coords = vec3(154.7, -1002.55, -99.51), pool = {1, 2, 3, 4}},
            },
            pickups = {
                {coords = vec3(155.26, -1005.86, -99.27), model = 'v_res_j_phone', reward = 'old_phone'},
                {coords = vec3(150.7, -1003.39, -98.9),  model = 'prop_kettle', reward = 'kettle'}
            }
        },
        [2] = {
            exit = vec4(266.11, -1007.61, -101.01, 357.68),
            peds = {
                vec4(262.62, -1004.23, -98.26, 187.45),
            },
            skillcheck = {'easy', 'medium', 'easy', 'medium'},
            loot = {
                {coords = vec3(266.24, -999.4, -99.08), pool = {1, 3, 4}},
                {coords = vec3(266.05, -997.6, -98.85), pool = {1, 2, 3, 4}},
                {coords = vec3(263.7, -995.13, -99.3), pool = {1, 2, 4}},
                {coords = vec3(262.57, -1000.52, -99.3), pool = {1, 3, 4}},
                {coords = vec3(256.74, -995.47, -99.63), pool = {1, 2, 3, 4}},
                {coords = vec3(256.97, -998.97, -99.56), pool = {1, 2, 3, 4}},
                {coords = vec3(259.74, -1004.4, -98.81), pool = {1, 2, 4}},
                {coords = vec3(261.39, -1002.21, -99.31), pool = {1, 2, 4}},
            },
            pickups = {
                {coords = vec3(262.67, -1001.86, -99.08), model = 'prop_tv_flat_03', reward = 'small_tv'},
                {coords = vec3(266.59, -995.33, -98.88),  model = 'prop_toaster_02', reward = 'toaster'},
                {coords = vec3(256.7, -995.65, -98.75),  model = 'prop_tv_03', reward = 'old_tv'},
            },
            
        },
        [3] = {
            exit = vec4(346.55, -1012.83, -99.2, 5.8),
            peds = {
                vec4(349.31, -995.88, -98.54, 358.67),
            },
            skillcheck = {'medium', 'easy', 'hard', 'medium'},
            loot = {
                {coords = vec3(345.7, -1001.7, -99.17), pool = {1, 3, 4, 5, 6, 7}},
                {coords = vec3(345.65, -995.83, -98.78),  pool = {1, 2, 3, 4, 5, 6, 7}},
                {coords = vec3(341.48, -996.14, -99.66),  pool = {1, 2, 4, 5, 6, 7}},
                {coords = vec3(337.86, -995.12, -98.7),  pool = {1, 3, 4, 5, 6, 7}},
                {coords = vec3(337.86, -998.19, -98.79),  pool = {1, 2, 3, 4, 5, 6, 7}},
                {coords = vec3(339.86, -994.14, -99.75),  pool = {1, 2, 3, 4, 5, 6, 7}},
                {coords = vec3(339.36, -1001.34, -99.46), pool = {1, 2, 4, 5, 6, 7}},
                {coords = vec3(339.22, -1003.69, -99.31),  pool = {1, 2, 3, 4, 5, 6, 7}},
                {coords = vec3(340.86, -1003.9, -98.81),  pool = {1, 2, 3, 4, 5, 6, 7}},
                {coords = vec3(351.23, -999.56, -99.33),  pool = {1, 2, 3, 4, 5, 6, 7}},
                -- {coords = vec3(351.43, -993.24, -98.77),  pool = {1, 2, 3, 4, 5, 6, 7}},
                -- {coords = vec3(348.85, -994.87, -99.44),  pool = {1, 2, 3, 4, 5, 6, 7}},
                -- {coords = vec3(346.98, -994.18, -99.22),   pool = {1, 2, 3, 4, 5, 6, 7}},
                -- {coords = vec3(352.38, -998.76, -99.64),   pool = {1, 2, 3, 4, 5, 6, 7}},
            },
            pickups = {
                {coords = vec3(344.69, -1002.05, -99.04), model = 'prop_micro_01',   reward = 'microwave'},
                {coords = vec3(341.8, -1003.88, -99.08),  model = 'prop_toaster_01', reward = 'toaster'},
                {coords = vec3(342.78, -1003.89, -98.97),  model = 'prop_coffee_mac_02', reward = 'coffee_machine'},
                {coords = vec3(341.62, -1001.07, -99.0),  model = 'prop_tapeplayer_01', reward = 'tape_player'},
            },
            
        },
        [4] = {
            exit = vec4(-174.27, 497.71, 137.65, 191.5),
            peds = {
                vec4(-163.55, 483.98, 134.56, 185.93),
                vec4(-167.79, 482.4, 137.81, 283.69),
            },
            skillcheck = {'hard', 'medium', 'hard', 'medium'},
            loot = {
                {coords = vec3(-170.33, 496.44, 138.12), pool = {1, 3, 4, 5, 6, 7}},
                {coords = vec3(-167.74, 493.56, 137.45), pool = {1, 2, 3, 4, 5, 6, 7}},
                {coords = vec3(-171.05, 482.59, 137.08), pool = {1, 2, 4, 5, 6, 7}},
                {coords = vec3(-171.76, 486.86, 137.23),  pool = {1, 3, 4, 5, 6, 7}},
                {coords = vec3(-164.35, 486.47, 137.71), pool = {1, 2, 3, 4, 5, 6, 7}},
                {coords = vec3(-170.99, 481.82, 133.73), pool = {1, 2, 3, 4, 5, 6, 7}},
                {coords = vec3(-162.86, 485.19, 133.46), pool = {1, 2, 3, 4, 5, 6, 7}},
                {coords = vec3(-162.27, 482.16, 133.47), pool = {1, 2, 4, 5, 6, 7}},
                {coords = vec3(-167.5, 488.46, 133.72),  pool = {1, 2, 3, 4, 5, 6, 7}},
                {coords = vec3(-165.83, 496.03, 133.4), pool = {1, 2, 3, 4, 5, 6, 7}},
                -- {coords = vec3(-172.79, 501.05, 129.85), pool = {1, 2, 3, 4, 5, 6, 7}},
                -- {coords = vec3(-174.49, 495.38, 130.3), pool = {1, 2, 3, 4, 5, 6, 7}},
                -- {coords = vec3(-170.26, 490.46, 129.48), pool = {1, 2, 3, 4, 5, 6, 7}},
                -- {coords = vec3(-174.55, 494.27, 130.09), pool = {1, 2, 3, 4, 5, 6, 7}},
                -- {coords = vec3(-175.57, 490.15, 129.77), pool = {1, 2, 3, 4, 5, 6, 7}},
                -- {coords = vec3(-165.08, 496.5, 137.45), pool = {1, 2, 3, 4, 5, 6, 7}},
            },
            pickups = {
                {coords = vec3(-164.56, 494.56, 137.85), model = 'prop_micro_02',   reward = 'microwave'},
                {coords = vec3(-166.12, 497.85, 137.75),  model = 'prop_toaster_01', reward = 'toaster'},
                {coords = vec3(-162.27, 479.6, 137.34),  model = 'prop_t_telescope_01b', reward = 'telescope'},
                {coords = vec3(-169.72, 490.14, 129.79),  model = 'prop_laptop_01a', reward = 'laptop'},
                {coords = vec3(-168.98, 492.27, 130.16),  model = 'prop_monitor_w_large', reward = 'monitor'},
                {coords = vec3(-169.11, 493.1, 130.17),  model = 'prop_monitor_w_large', reward = 'monitor'},
                {coords = vec3(-175.39, 489.13, 130.07),  model = 'prop_printer_01', reward = 'printer'},

            },
            
        },
        [5] = {
            exit = vec4(-787.38, 315.73, 217.64, 90.51),
            peds = {
                vec4(-786.56, 338.24, 217.31, 91.53),
                vec4(-797.52, 335.63, 221.11, 88.84),
            },
            skillcheck = {'hard', 'medium', 'hard', 'medium'},
            loot = {
                {coords = vec3(-789.31, 320.83, 216.91), pool = {1, 3, 4, 5, 6, 7}},
                {coords = vec3(-792.99, 329.06, 217.2), pool = {1, 2, 3, 4, 5, 6, 7}},
                {coords = vec3(-792.99, 331.99, 217.12), pool = {1, 2, 4, 5, 6, 7}},
                {coords = vec3(-781.64, 331.79, 216.64),  pool = {1, 3, 4, 5, 6, 7}},
                {coords = vec3(-781.64, 329.72, 216.65), pool = {1, 2, 3, 4, 5, 6, 7}},
                {coords = vec3(-782.94, 330.01, 216.77), pool = {1, 2, 3, 4, 5, 6, 7}},
                {coords = vec3(-782.94, 328.04, 216.73), pool = {1, 2, 3, 4, 5, 6, 7}},
                {coords = vec3(-783.64, 325.07, 217.6), pool = {1, 2, 4, 5, 6, 7}},
                {coords = vec3(-780.99, 338.47, 216.37),  pool = {1, 2, 3, 4, 5, 6, 7}},
                {coords = vec3(-781.65, 325.56, 217.59), pool = {1, 2, 3, 4, 5, 6, 7}},
                -- {coords = vec3(-799.18, 322.82, 216.31), pool = {1, 2, 3, 4, 5, 6, 7}},
                -- {coords = vec3(-798.63, 328.06, 216.47), pool = {1, 2, 3, 4, 5, 6, 7}},
                -- {coords = vec3(-794.62, 326.45, 217.13), pool = {1, 2, 3, 4, 5, 6, 7}},
                -- {coords = vec3(-800.46, 338.33, 220.12), pool = {1, 2, 3, 4, 5, 6, 7}},
                -- {coords = vec3(-796.02, 328.8, 220.14), pool = {1, 2, 3, 4, 5, 6, 7}},
                -- {coords = vec3(-796.02, 326.61, 220.16), pool = {1, 2, 3, 4, 5, 6, 7}},
                -- {coords = vec3(-799.5, 326.64, 220.08), pool = {1, 2, 3, 4, 5, 6, 7}},
                -- {coords = vec3(-799.5, 328.83, 220.1), pool = {1, 2, 3, 4, 5, 6, 7}},
                -- {coords = vec3(-795.95, 330.82, 220.16), pool = {1, 2, 3, 4, 5, 6, 7}},
                -- {coords = vec3(-805.53, 332.04, 219.97), pool = {1, 2, 3, 4, 5, 6, 7}},
            },
            pickups = {
                {coords = vec3(-781.24, 329.27, 217.26),  model = 'prop_coffee_mac_02', reward = 'coffee_machine'},
                {coords = vec3(-789.12, 342.76, 217.06),  model = 'prop_t_telescope_01b', reward = 'telescope'},
                {coords = vec3(-799.62, 322.36, 216.8),  model = 'prop_laptop_01a', reward = 'laptop'},
                {coords = vec3(-797.67, 321.22, 217.15),  model = 'prop_monitor_w_large', reward = 'monitor'},
                {coords = vec3(-796.77, 321.19, 217.18),  model = 'prop_monitor_w_large', reward = 'monitor'},
                {coords = vec3(-799.45, 328.11, 217.02),  model = 'prop_printer_01', reward = 'printer'},

            },
            
        },
        [6] = {
            exit = vec4(-576.68, -715.74, 113.01, 93.95),
            peds = {
                vec4(-594.09, -709.85, 122.31, 91.92),
                vec4(-584.66, -710.24, 122.08, 276.5),
                vec4(-579.9, -708.79, 122.08, 91.31),
                vec4(-584.9, -712.27, 116.69, 88.31),
                vec4(-599.2, -714.32, 117.69, 175.1),
                vec4(-589.9, -714.01, 112.89, 56.71)
            },
            skillcheck = {'hard', 'medium', 'hard', 'medium'},
            loot = {
                {coords = vec3(-599.51, -721.2, 116.6), pool = {1, 3, 4, 5, 6, 7}},
                {coords = vec3(-598.28, -719.44, 116.32), pool = {1, 2, 3, 4, 5, 6, 7}},
                {coords = vec3(-600.38, -719.44, 116.3), pool = {1, 2, 4, 5, 6, 7}},
                {coords = vec3(-595.07, -723.26, 116.51),  pool = {1, 3, 4, 5, 6, 7}},
                {coords = vec3(-586.39, -723.28, 116.44), pool = {1, 2, 3, 4, 5, 6, 7}},
                {coords = vec3(-590.17, -716.24, 116.34), pool = {1, 2, 3, 4, 5, 6, 7}},
                {coords = vec3(-579.85, -711.45, 116.27), pool = {1, 2, 3, 4, 5, 6, 7}},
                {coords = vec3(-579.86, -713.7, 116.27), pool = {1, 2, 4, 5, 6, 7}},
                {coords = vec3(-582.16, -728.02, 121.79),  pool = {1, 2, 3, 4, 5, 6, 7}},
                {coords = vec3(-580.22, -728.03, 121.17), pool = {1, 2, 3, 4, 5, 6, 7}},
                -- {coords = vec3(-578.94, -726.49, 121.21), pool = {1, 2, 3, 4, 5, 6, 7}},
                -- {coords = vec3(-578.93, -722.63, 121.18), pool = {1, 2, 3, 4, 5, 6, 7}},
                -- {coords = vec3(-578.92, -720.6, 121.69), pool = {1, 2, 3, 4, 5, 6, 7}},
                -- {coords = vec3(-588.79, -728.01, 121.9), pool = {1, 2, 3, 4, 5, 6, 7}},
                -- {coords = vec3(-590.78, -728.0, 121.94), pool = {1, 2, 3, 4, 5, 6, 7}},
                -- {coords = vec3(-592.84, -727.99, 121.75), pool = {1, 2, 3, 4, 5, 6, 7}},
                -- {coords = vec3(-594.81, -728.02, 121.76), pool = {1, 2, 3, 4, 5, 6, 7}},
                -- {coords = vec3(-597.4, -727.98, 121.79), pool = {1, 2, 3, 4, 5, 6, 7}},
                -- {coords = vec3(-601.37, -721.96, 121.73), pool = {1, 2, 3, 4, 5, 6, 7}},
                -- {coords = vec3(-599.82, -727.98, 121.22), pool = {1, 2, 3, 4, 5, 6, 7}},
                -- {coords = vec3(-601.34, -726.46, 121.18), pool = {1, 2, 3, 4, 5, 6, 7}},
                -- {coords = vec3(-601.34, -724.45, 121.18), pool = {1, 2, 3, 4, 5, 6, 7}},
                -- {coords = vec3(-601.33, -720.2, 121.71), pool = {1, 2, 3, 4, 5, 6, 7}},
                -- {coords = vec3(-595.26, -716.73, 121.8), pool = {1, 2, 3, 4, 5, 6, 7}},
                -- {coords = vec3(-586.26, -715.99, 121.77), pool = {1, 2, 3, 4, 5, 6, 7}},
                -- {coords = vec3(-591.71, -717.98, 121.2), pool = {1, 2, 3, 4, 5, 6, 7}},
                -- {coords = vec3(-602.07, -709.82, 121.35), pool = {1, 2, 3, 4, 5, 6, 7}},
                -- {coords = vec3(-599.46, -708.56, 121.41), pool = {1, 2, 3, 4, 5, 6, 7}},
                -- {coords = vec3(-599.47, -711.07, 121.44), pool = {1, 2, 3, 4, 5, 6, 7}},
                -- {coords = vec3(-595.01, -713.86, 121.82), pool = {1, 2, 3, 4, 5, 6, 7}},
                -- {coords = vec3(-592.55, -713.86, 121.78), pool = {1, 2, 3, 4, 5, 6, 7}},
                -- {coords = vec3(-589.04, -713.87, 121.87), pool = {1, 2, 3, 4, 5, 6, 7}},
                -- {coords = vec3(-586.61, -713.88, 121.77), pool = {1, 2, 3, 4, 5, 6, 7}},
                -- {coords = vec3(-589.78, -710.81, 121.75), pool = {1, 2, 3, 4, 5, 6, 7}},
                -- {coords = vec3(-589.81, -709.64, 121.26), pool = {1, 2, 3, 4, 5, 6, 7}},
                -- {coords = vec3(-583.83, -719.81, 117.01), pool = {1, 2, 3, 4, 5, 6, 7}},
                -- {coords = vec3(-581.81, -719.82, 116.93), pool = {1, 2, 3, 4, 5, 6, 7}},
                -- {coords = vec3(-579.88, -719.82, 117.05), pool = {1, 2, 3, 4, 5, 6, 7}},
            },
            pickups = {
                {coords = vec3(-588.08, -707.06, 117.01),  model = 'prop_t_telescope_01b', reward = 'telescope'},
                {coords = vec3(-578.51, -709.45, 116.49),  model = 'prop_golf_bag_01b', reward = 'golfbag'},
                {coords = vec3(-595.39, -723.25, 117.43),  model = 'prop_tv_flat_01', reward = 'tv'},
                {coords = vec3(-592.42, -718.51, 121.58),  model = 'prop_laptop_01a', reward = 'laptop'},
                {coords = vec3(-601.79, -725.07, 122.3),  model = 'prop_tv_flat_01', reward = 'tv'},
                {coords = vec3(-582.24, -705.82, 122.54),  model = 'prop_tv_flat_01', reward = 'tv'},
                {coords = vec3(-593.37, -706.14, 121.81),  model = 'prop_t_telescope_01b', reward = 'telescope'},

            },
            
        },
    },
    houses = {
        [1] = {
            routingbucket = 600,
            interior = 1,
            opened = false,
            coords = vec3(495.25, -1823.31, 28.87),
            setup = {
                loot = {
                    min = 5,
                    max = 5
                },
                pickups = {
                    min = 2,
                    max = 2
                }
            },
            loot = {},
            pickups = {},
            isAlarmTriggered = false,
            peds = {},
            
        },
        [2] = {
            routingbucket = 601,
            interior = 1,
            opened = false,
            coords = vec3(311.99, -1956.12, 24.62),
            setup = {
                loot = {
                    min = 5,
                    max = 5
                },
                pickups = {
                    min = 2,
                    max = 2
                }
            },
            loot = {},
            pickups = {},
            isAlarmTriggered = false,
            peds = {},
            
        },
        [3] = {
            routingbucket = 602,
            interior = 1,
            opened = false,
            coords = vec3(1193.67, -1656.54, 43.03),
            setup = {
                loot = {
                    min = 5,
                    max = 5
                },
                pickups = {
                    min = 2,
                    max = 2
                }
            },
            loot = {},
            pickups = {},
            isAlarmTriggered = false,
            peds = {},
            
        },
        [4] = {
            routingbucket = 603,
            interior = 1,
            opened = false,
            coords = vec3(179.29, -1923.98, 21.37),
            setup = {
                loot = {
                    min = 5,
                    max = 5
                },
                pickups = {
                    min = 2,
                    max = 2
                }
            },
            loot = {},
            pickups = {},
            isAlarmTriggered = false,
            peds = {},
            
        },
        [5] = {
            routingbucket = 604,
            interior = 1,
            opened = false,
            coords = vec3(-64.58, -1449.61, 32.52),
            setup = {
                loot = {
                    min = 5,
                    max = 5
                },
                pickups = {
                    min = 2,
                    max = 2
                }
            },
            loot = {},
            pickups = {},
            isAlarmTriggered = false,
            peds = {},
            
        },
        [6] = {
            routingbucket = 605,
            interior = 1,
            opened = false,
            coords = vec3(-138.22, -1470.78, 36.99),
            setup = {
                loot = {
                    min = 5,
                    max = 5
                },
                pickups = {
                    min = 1,
                    max = 1
                }
            },
            loot = {},
            pickups = {},
            isAlarmTriggered = false,
            peds = {},
            
        },
        [7] = {
            routingbucket = 606,
            interior = 2,
            opened = false,
            coords = vec3(-884.14, -1072.51, 2.53),
            setup = {
                loot = {
                    min = 6,
                    max = 8
                },
                pickups = {
                    min = 3,
                    max = 3
                }
            },
            loot = {},
            pickups = {},
            isAlarmTriggered = false,
            peds = {},
            
        },
        [8] = {
            routingbucket = 607,
            interior = 2,
            opened = false,
            coords = vec3(-1134.11, -1050.19, 2.15),
            setup = {
                loot = {
                    min = 4,
                    max = 8
                },
                pickups = {
                    min = 1,
                    max = 1
                }
            },
            loot = {},
            pickups = {},
            isAlarmTriggered = false,
            peds = {},
            
        },
        [9] = {
            routingbucket = 608,
            interior = 2,
            opened = false,
            coords = vec3(-1089.85, -1680.31, 4.67),
            setup = {
                loot = {
                    min = 4,
                    max = 8
                },
                pickups = {
                    min = 1,
                    max = 1
                }
            },
            loot = {},
            pickups = {},
            isAlarmTriggered = false,
            peds = {},
            
        },
        [10] = {
            routingbucket = 609,
            interior = 2,
            opened = false,
            coords = vec3(960.01, -669.94, 58.45),
            setup = {
                loot = {
                    min = 4,
                    max = 8
                },
                pickups = {
                    min = 1,
                    max = 1
                }
            },
            loot = {},
            pickups = {},
            isAlarmTriggered = false,
            peds = {},
            
        },
        [11] = {
            routingbucket = 610,
            interior = 2,
            opened = false,
            coords = vec3(1240.51, -601.62, 69.78),
            setup = {
                loot = {
                    min = 4,
                    max = 8
                },
                pickups = {
                    min = 1,
                    max = 1
                }
            },
            loot = {},
            pickups = {},
            isAlarmTriggered = false,
            peds = {},
            
        },
        [12] = {
            routingbucket = 611,
            interior = 2,
            opened = false,
            coords = vec3(1098.57, -464.54, 67.32),
            setup = {
                loot = {
                    min = 4,
                    max = 8
                },
                pickups = {
                    min = 1,
                    max = 1
                }
            },
            loot = {},
            pickups = {},
            isAlarmTriggered = false,
            peds = {},
            
        },
        [13] = {
            routingbucket = 612,
            interior = 1,
            opened = false,
            coords = vec3(69.43, -56.69, 73.02),
            setup = {
                loot = {
                    min = 5,
                    max = 5
                },
                pickups = {
                    min = 1,
                    max = 1
                }
            },
            loot = {},
            pickups = {},
            isAlarmTriggered = false,
            peds = {},
            
        },
        [14] = {
            routingbucket = 613,
            interior = 1,
            opened = false,
            coords = vec3(-102.84, -11.91, 70.52),
            setup = {
                loot = {
                    min = 5,
                    max = 5
                },
                pickups = {
                    min = 1,
                    max = 1
                }
            },
            loot = {},
            pickups = {},
            isAlarmTriggered = false,
            peds = {},
            
        },
        [15] = {
            routingbucket = 614,
            interior = 2,
            opened = false,
            coords = vec3(-332.97, 57.08, 54.43),
            setup = {
                loot = {
                    min = 6,
                    max = 8
                },
                pickups = {
                    min = 1,
                    max = 1
                }
            },
            loot = {},
            pickups = {},
            isAlarmTriggered = false,
            peds = {},
            
        },
        [16] = {
            routingbucket = 615,
            interior = 2,
            opened = false,
            coords = vec3(-1009.5, 479.12, 79.59),
            setup = {
                loot = {
                    min = 6,
                    max = 8
                },
                pickups = {
                    min = 1,
                    max = 2
                }
            },
            loot = {},
            pickups = {},
            isAlarmTriggered = false,
            peds = {},
            
        },
        [17] = {
            routingbucket = 616,
            interior = 2,
            opened = false,
            coords = vec3(-371.74, 343.46, 109.94),
            setup = {
                loot = {
                    min = 6,
                    max = 8
                },
                pickups = {
                    min = 1,
                    max = 2
                }
            },
            loot = {},
            pickups = {},
            isAlarmTriggered = false,
            peds = {},
            
        },
        [18] = {
            routingbucket = 617,
            interior = 1,
            opened = false,
            coords = vec3(1435.45, 3657.04, 34.4),
            setup = {
                loot = {
                    min = 5,
                    max = 5
                },
                pickups = {
                    min = 1,
                    max = 1
                }
            },
            loot = {},
            pickups = {},
            isAlarmTriggered = false,
            peds = {},
            
        },
        [19] = {
            routingbucket = 618,
            interior = 1,
            opened = false,
            coords = vec3(1808.93, 3907.97, 33.74),
            setup = {
                loot = {
                    min = 5,
                    max = 5
                },
                pickups = {
                    min = 2,
                    max = 2
                }
            },
            loot = {},
            pickups = {},
            isAlarmTriggered = false,
            peds = {},
            
        },
        [20] = {
            routingbucket = 619,
            interior = 2,
            opened = false,
            coords = vec3(-480.95, 6266.33, 13.63),
            setup = {
                loot = {
                    min = 8,
                    max = 8
                },
                pickups = {
                    min = 3,
                    max = 3
                }
            },
            loot = {},
            pickups = {},
            isAlarmTriggered = false,
            peds = {},
            
        },
        [21] = {
            routingbucket = 620,
            interior = 3,
            opened = false,
            coords = vec3(-280.54, 6350.67, 32.6),
            setup = {
                loot = {
                    min = 8,
                    max = 9
                },
                pickups = {
                    min = 4,
                    max = 4
                }
            },
            loot = {},
            pickups = {},
            isAlarmTriggered = false,
            peds = {},
            
        },
        [22] = {
            routingbucket = 621,
            interior = 4,
            opened = false,
            coords = vec3(-174.65, 502.47, 137.42),
            setup = {
                loot = {
                    min = 10,
                    max = 10
                },
                pickups = {
                    min = 7,
                    max = 7
                }
            },
            loot = {},
            pickups = {},
            isAlarmTriggered = false,
            peds = {},
            
        },
        [23] = {
            routingbucket = 622,
            interior = 5,
            opened = false,
            coords = vec3(-230.17, 487.94, 128.77),
            setup = {
                loot = {
                    min = 10,
                    max = 10
                },
                pickups = {
                    min = 6,
                    max = 6
                }
            },
            loot = {},
            pickups = {},
            isAlarmTriggered = false,
            peds = {},
            
        },
        [24] = {
            routingbucket = 623,
            interior = 6,
            opened = false,
            coords = vec3(-589.5, -708.28, 36.28),
            setup = {
                loot = {
                    min = 10,
                    max = 10
                },
                pickups = {
                    min = 7,
                    max = 7
                }
            },
            loot = {},
            pickups = {},
            isAlarmTriggered = false,
            peds = {},
            
        },
    },


    AlertCops = function(isOutside, house)
        local function GetStreetAndZone(coords)
            local zone = GetLabelText(GetNameOfZone(coords.x, coords.y, coords.z))
            local street = GetStreetNameFromHashKey(GetStreetNameAtCoord(coords.x, coords.y, coords.z))
            return street .. ", " .. zone
        end

        local coords
        if isOutside then
            coords = GetEntityCoords(cache.ped)
        else
            coords = house.coords
        end

        local s1, s2 = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
        local street1name = GetStreetNameFromHashKey(s1)
        local street2name = s2 ~= 0 and GetStreetNameFromHashKey(s2) or nil
        local locationText = street2name and (street1name .. " & " .. street2name) or street1name

        local h, m, s = GetClockHours(), GetClockMinutes(), GetClockSeconds()
        local gameTime = string.format("%02d:%02d:%02d", h, m, s)

        local data = {
            priority = 'medium',            -- 'low' | 'medium' | 'high' (sesuaikan)
            code = '10-90',
            title = 'House Robbery',
            description = ('Possible house break-in near %s (%s)'):format(locationText, GetStreetAndZone(coords)),
            location = {
                label = 'Incident Location',
                coords = { x = coords.x, y = coords.y, z = coords.z }, -- aman sertakan z kalau dibutuhkan
            },
            time = 300,                     -- detik (durasi aktifnya dispatch di tablet)
            job = 'police',                 -- sesuaikan dengan nama job di server-mu
            sound = 'notification.mp3',     -- pastikan file ada (atau hapus field ini)
            fields = {
                { icon = 'home',                label = 'Jenis',   value = 'House Robbery' },
                { icon = 'map-marker',          label = 'Lokasi',  value = locationText },
                { icon = 'clock',               label = 'Waktu',   value = gameTime },
                { icon = 'shield-checkmark',    label = 'Kode',    value = '10-90' },
                { icon = 'exclamation-triangle',label = 'Status',  value = 'In Progress' },
            },
            blip = {
                sprite = 40,                -- rumah (mirip blip lama)
                color = 1,                  -- merah
                size = 0.9,
                shortRange = false,
                label = 'House Robbery'
            }
        }

        -- Kirim ke server untuk dipass ke lb-tablet
        TriggerServerEvent('houserobbery:triggerDispatch', data)
    end,

}