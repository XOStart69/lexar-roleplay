return {
    Lumberjack = {
        collect = {
            target = {
                coords = {
                    vec(-558.4, 5419.15, 63.3),
                    vec(-578.75, 5426.95, 59.25),
                    vec(-600.2, 5397.2, 54.0),
                    vec(-613.95, 5399.4, 52.0),
                    vec(-616.3, 5424.15, 51.0),
                    vec(-595.05, 5451.25, 59.4),
                    vec(-580.85, 5470.1, 60.0),
                    vec(-552.75, 5445.9, 64.15),
                    vec(-564.2, 5457.45, 63.35),
                    vec(-538.2, 5483.9, 66.15),
                    vec(-586.2, 5447.25, 60.3),
                    vec(-566.65, 5503.2, 58.0)
                },
                distance = 2.0,
                label = 'Tebang pohon',
                requiredWeapon = 'weapon_hatchet',
                busyChek = true
            },
            progressbar = {
                duration = 5000,
                label = 'Menebang kayu...',
                anim = {
                    dict = 'melee@hatchet@streamed_core',
                    clip = 'plyr_rear_takedown_b'
                }
            },
            items = {
                add = { wood_log = { min = 3, max = 5 } }
            },
            blip = {
                coords = vec(-565.44, 5473.72, 61.92),
                sprite = 527,
                color = 56,
                scale = 0.7,
                label = 'Lumberjack - Potong Kayu'
            },
            battlepass = {
                standart = {
                    count = 1,
                    taskid = 1
                },
            }
        },
        cut = {
            target = {
                model = 'prop_log_01',
                coords = vec(-552.21, 5326.91, 73.60, 180.0),
                distance = 2.5,
                renderDistance = 15.0,
                label = 'Potong kayu'
            },
            items = {
                remove = { wood_log = 10 },
                add = { wood_cut = {min = 5, max = 10} }
            },
            progressbar = {
                duration = 8000,
                label = 'Memotong kayu...',
                anim = {
                    dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
                    clip = 'machinic_loop_mechandplayer'
                }
            },
            blip = {
                coords = vec(-552.21, 5326.91, 73.60),
                sprite = 527,
                color = 56,
                scale = 0.7,
                label = 'Lumberjack - Processing'
            }
        },
        packing = {
            target = {
                model = 'prop_boxpile_07d',
                coords = {
                    vec(-501.38, 5280.53, 80.62, 270.0),
                    vec(-507.2397, 5263.1738, 80.6224, 74.6883)
                },
                distance = 2.5,
                renderDistance = 15.0,
                label = 'Packing kayu'
            },
            items = {
                remove = { wood_cut = 10 },
                add = { packaged_plank = 10}
            },
            progressbar = {
                duration = 8000,
                label = 'Mengemas kayu...',
                anim = {
                    dict = 'anim@heists@box_carry@',
                    clip = 'idle'
                }
            },
            battlepass = {
                standart = {
                    count = 1,
                    taskid = 2
                },
            },
            blip = {
                coords = vec(-501.38, 5280.53, 80.62),
                sprite = 527,
                color = 56,
                scale = 0.7,
                label = 'Lumberjack - Packing Kayu'
            }
        }
    },
    Tailor = {
        collect = {
            blip = {
                coords = vec(2531.41, 4362.95, 39.73),
                sprite = 366,
                color = 47,
                scale = 0.8,
                label = 'Tailor - Ambil Benang'
            },
            target = {
                label = 'Collect',
                distance = 2.5,
                requiredWeapon = 'weapon_crowbar'
            },
            prop = {
                model = 'prop_haybale_03',
                distance = 25,
                gap = 10,
                coords = vec(2531.9282, 4357.9937, 40.1387),
                max_spawn = 10,
                respawn_time = 5, -- detik
            },
            items = {
                add = {thread = {min = 1, max = 3}}
            },
            progressbar = {
                duration = 5000,
                label = 'Mengumpulkan benang...',
                anim = {
                    dict = 'mini@repair',
                    clip = 'fixing_a_ped'
                }
            }
        },
        fabric = {
            blip = {
                coords = vec(716.3, -961.57, 30.4),
                sprite = 366,
                color = 47,
                scale = 0.8,
                label = 'Tailor - Processing'
            },
            target = {
                coords = vec(716.11, -960.01, 30.4),
                radius = 2.5,
                label = 'Process'
            },
            items = {
                remove = {thread = 10},
                add = {fabric = 10}
            },
            progressbar = {
                duration = 8000,
                label = 'Membuat kain...',
                anim = {
                    dict = 'mini@repair',
                    clip = 'fixing_a_ped'
                }
            }
        },
        tailor = {
            blip = {
                coords = vec(712.9, -973.73, 30.4),
                sprite = 366,
                color = 47,
                scale = 0.8,
                label = 'Tailor - Jahit Baju'
            },
            target = {
                coords = vec(712.9, -973.73, 30.4),
                radius = 2.5,
                label = 'Jahit baju'
            },
            items = {
                remove = {fabric = 10},
                add = { clothes = 5}
            },
            progressbar = {
                duration = 12000,
                label = 'Menjahit baju...',
                anim = {
                    dict = 'mini@repair',
                    clip = 'fixing_a_ped'
                }
            }
        }
    },
    OilWorker = {
        collect = {
            blip = {
                coords = vec(2738.36, 1602.85, 24.5),
                sprite = 361,
                color = 47,
                scale = 0.7,
                label = "Oil Worker - Ambil Minyak Mentah"
            },
            target = {
                label = 'Ambil minyak',
                requiredWeapon = 'weapon_wrench',
                distance = 1.5
            },
            prop = {
                model = 'prop_barrel_03a',
                distance = 20,
                respawn_time = 5,
                coords = vec(2759.05, 1596.13, 24.50),
                positions = {
                    vec(2744.76, 1594.71, 23.50, 100.56),
                    vec(2742.93, 1588.51, 23.50, 100.56),
                    vec(2747.46, 1589.62, 23.50, 100.56),
                    vec(2747.74, 1584.02, 23.50, 100.56),
                    vec(2752.77, 1578.68, 23.50, 100.56),
                    vec(2757.06, 1584.57, 23.50, 100.56),
                    vec(2757.50, 1578.72, 23.50, 100.56),
                    vec(2762.41, 1580.57, 23.50, 100.56),
                    vec(2761.91, 1585.58, 23.50, 100.56),
                    vec(2757.86, 1590.48, 23.50, 100.56),
                    vec(2753.56, 1595.96, 23.50, 100.56),
                    vec(2748.12, 1602.96, 23.50, 100.56),
                    vec(2754.14, 1602.81, 23.50, 100.56),
                    vec(2763.50, 1605.43, 23.50, 100.56),
                    vec(2764.32, 1596.15, 23.50, 100.56),
                    vec(2771.29, 1600.18, 23.50, 100.56),
                    vec(2771.89, 1592.73, 23.50, 100.56),
                    vec(2768.91, 1585.80, 23.50, 100.56)
                },
                effects = {
                    particle = {
                        dict = 'core',
                        name = 'ent_sht_steam',
                        scale = 1.0,
                        rot = vec(0.0, 0.0, 0.0) -- optional
                    },
                    sound = {
                        name = 'CHEMICAL_SPLASH',
                        set = 'CONSTRUCTION_DRILLING_SOUNDSET'
                    }
                }
            },
            items = {
                add = { minyak_mentah = { min = 3, max = 6 } }
            },
            progressbar = {
                duration = 5000,
                label = 'Mengambil minyak mentah...',
                anim = {
                    dict = 'mini@repair',
                    clip = 'fixing_a_ped'
                }
            },
        },

        process = {
            blip = {
                coords = vec(2658.3921, 1549.6647, 24.4849),
                sprite = 361,
                color = 47,
                scale = 0.7,
                label = "Oil Worker - Proses Minyak"
            },
            target = {
                model = 'prop_generator_01a',
                coords = {
                    vec(2658.5693, 1547.1398, 24.4852, 179.3111),
                    vec(2658.5464, 1549.5585, 24.4852, 178.1183),
                },
                radius = 5.0,
                distance = 1.5,
                renderDistance = 15.0,
                label = 'Proses minyak'
            },
            items = {
                remove = {minyak_mentah = 10},
                add = {oil = 10}
            },
            progressbar = {
                duration = 9000,
                label = 'Memproses minyak mentah...',
                anim = {
                    dict = 'amb@prop_human_parking_meter@male@idle_a',
                    clip = 'idle_a'
                }
            }
        },


        package = {
            blip = {
                coords = vec(2660.12, 1506.26, 24.5),
                sprite = 361,
                color = 47,
                scale = 0.7,
                label = "Oil Worker - Kemas Drum Minyak"
            },
            target = {
                model = 'prop_generator_01a',
                coords = {
                    vec(2660.12, 1506.26, 24.5),
                    vec(2660.0508, 1509.0876, 24.5008),
                },
                radius = 5.0,
                distance = 1.5,
                label = 'Kemas minyak'
            },
            items = {
                remove = {oil = 10},
                add = {drum_oil = 5}
            },
            progressbar = {
                duration = 11000,
                label = 'Mengemas drum minyak...',
                anim = {
                    dict = 'anim@heists@box_carry@',
                    clip = 'idle'
                }
            }
        }
    },
    Recycle = {
        collect = {
            blip = {
                coords = vec(1180.2494, -3114.2603, 6.0280),
                sprite = 365,
                color = 69,
                scale = 0.8,
                label = "Recycle - Ambil Kardus Bekas"
            },
            prop = {
                model = 'prop_boxpile_05a',
                distance = 15,
                respawn_time = 5,
                coords = vec(1011.2440, -3099.8835, -38.9999),
                positions = {
                    vec(1003.59, -3108.40, -40.00, 181.21),
                    vec(1006.05, -3108.33, -40.00, 181.21),
                    vec(1008.46, -3108.34, -40.00, 181.21),
                    vec(1010.86, -3108.32, -40.00, 181.21),
                    vec(1013.33, -3108.27, -40.00, 181.21),
                    vec(1015.70, -3108.16, -40.00, 181.21),
                    vec(1018.09, -3108.06, -40.00, 181.21),
                    vec(1018.12, -3103.19, -40.00, 181.21),
                    vec(1015.74, -3103.17, -40.00, 181.21),
                    vec(1013.28, -3103.19, -40.00, 181.21),
                    vec(1010.91, -3103.05, -40.00, 181.21),
                    vec(1008.44, -3103.10, -40.00, 181.21),
                    vec(1006.11, -3103.12, -40.00, 181.21),
                    vec(1003.55, -3103.11, -40.00, 181.21),
                    vec(1003.58, -3096.90, -40.00, 181.21),
                    vec(1006.01, -3096.83, -40.00, 181.21),
                    vec(1008.42, -3096.81, -40.00, 181.21),
                    vec(1010.82, -3096.93, -40.00, 181.21),
                    vec(1013.54, -3096.68, -40.00, 181.21),
                    vec(1015.78, -3096.79, -40.00, 181.21),
                    vec(1018.24, -3096.86, -40.00, 181.21)
                },
                sound = {
                    name = 'PICK_UP',
                    set = 'HUD_FRONTEND_DEFAULT_SOUNDSET'
                }
            },
            items = {
                add = {recycle_box = { min = 1, max = 3 }}
            },
            progressbar = {
                duration = 5000,
                label = 'Mengambil kardus bekas...',
                anim = {
                    dict = 'anim@heists@box_carry@',
                    clip = 'idle'
                }
            },
        },
        process = {
            blip = {
                coords = vec(1227.02, -3200.04, 5.73),
                sprite = 365,
                color = 69,
                scale = 0.8,
                label = "Recycle - Proses Kardus"
            },
            target = {
                coords = {
                    vec(1234.62, -3200.04, 5.83),
                    vec(1219.42, -3200.04, 5.63)
                },
                radius = 2.0,
                distance = 1.5
            },
            items = {
                remove = {recycle_box = 10},
                add = {recycle_package = { min = 5, max = 10} }
            },
            progressbar = {
                duration = 6000,
                label = 'Memproses kardus bekas...',
                anim = {
                    dict = 'mini@repair',
                    clip = 'fixing_a_ped'
                }
            }
        },
        package = {
            blip = {
                coords = vec(1201.55, -3177.85, 6.2),
                sprite = 478,
                color = 69,
                scale = 0.8,
                label = "Recycle - Daur Ulang Final"
            },
            target = {
                coords = vec(1201.55, -3177.85, 6.2),
                radius = 4.0,
                distance = 2.5
            },
            menu = {
                {
                    label = 'Plastic',
                    description = 'Membutuhkan 5 Recycle Package',
                    icon = 'fas fa-recycle',
                    items = {
                        remove = { recycle_package = 5 },
                        add = { plastic = 1 }
                    },
                },
                {
                    label = 'Steel',
                    description = 'Membutuhkan 10 Recycle Package',
                    icon = 'fas fa-recycle',
                    items = {
                        remove = { recycle_package = 10 },
                        add = { steel = 1 }
                    },
                },
                {
                    label = 'Glass',
                    description = 'Membutuhkan 15 Recycle Package',
                    icon = 'fas fa-recycle',
                    items = {
                        remove = { recycle_package = 15 },
                        add = { glass = 1 }
                    },
                },
                {
                    label = 'Rubber',
                    description = 'Membutuhkan 20 Recycle Package',
                    icon = 'fas fa-recycle',
                    items = {
                        remove = { recycle_package = 20 },
                        add = { rubber = 1 }
                    },
                },
                {
                    label = 'Metal Scrap',
                    description = 'Membutuhkan 25 Recycle Package',
                    icon = 'fas fa-recycle',
                    items = {
                        remove = { recycle_package = 25 },
                        add = { metalscrap = 1 }
                    },
                }
            },
            battlepass = {
                premium = {
                    count = 1,
                    taskid = 6
                },
            },
            progressbar = {
                duration = 8000,
                label = 'Mendaur ulang material...',
                anim = {
                    dict = 'amb@prop_human_parking_meter@male@idle_a',
                    clip = 'idle_a'
                }
            },
        }
    },
    Mining = {
        collect = {
            blip = {
                coords = vec(2949.13, 2792.31, 40.74),
                sprite = 618,
                color = 42,
                scale = 0.8,
                label = "Mining - Tambang Batu"
            },
            prop = {
                model = 'bzzz_prop_mine_stone_big', -- Changed to smaller rock
                respawn_time = 5,
                distance = 25,
                gap = 9,
                max_spawn = 15,
                coords = vec(2952.8179, 2790.4575, 41.3330),
                requiredWeapon = 'weapon_sledgehammer',
                loopedEffects = {
                    delay = 1000,
                    tick = 'animduration',
                    particle = {
                        dict = 'core',
                        name = 'ent_dst_rocks',
                        scale = 2.5
                    },
                    sound = {
                        name = 'Drill_Pin_Break',
                        set = 'DLC_HEIST_FLEECA_SOUNDSET'
                    }
                }
            },
            items = {
                add = {stone = { min = 3, max = 6 }}
            },
            progressbar = {
                duration = 5000,
                label = 'Mengambil batu...',
                anim = {
                    dict = 'melee@large_wpn@streamed_core',
                    clip = 'ground_attack_on_spot'
                }
            },
        },
        wash = {
            blip = {
                coords = vec(1962.6716, 444.3721, 159.5259),
                sprite = 467,
                color = 3,
                scale = 0.8,
                label = "Mining - Cuci Batu"
            },
            points = {
                coords = vec(1962.6716, 444.3721, 159.5259),
                distance = 20,
                drawtext = 'E - cuci batu',
                keyIndex = 38 -- E
            },
            items = {
                remove = { stone = 10 },
                add = { clean_stone = { min = 5, max = 7 } }
            },
            progressbar = {
                duration = 8000,
                label = 'Mencuci batu...',
                anim = {
                    dict = 'amb@world_human_bum_wash@male@high@idle_a',
                    clip = 'idle_a',
                    flag = 11,
                    bone = 60309
                }
            },
            progressprops = {
                before = {
                    {
                        model = 'bzzz_prop_mine_bowl_gold_a',
                        frontped = true,      -- spawn di depan ped
                        -- coords = vec(x,y,z),  -- atau pakai coords (jika frontped = false)
                        -- heading = 180.0,      -- optional, default ikut heading ped
                        -- ground = true         -- optional, default true (PlaceObjectOnGroundProperly)
                    }
                },
                after = {
                    {
                        model = 'bzzz_prop_mine_bowl_gold_b',
                        frontped = true,      -- spawn di depan ped
                        -- coords = vec(x,y,z),  -- atau pakai coords (jika frontped = false)
                        -- heading = 180.0,      -- optional, default ikut heading ped
                        -- ground = true         -- optional, default true (PlaceObjectOnGroundProperly)
                    },
                }
            },
        },
        smelt = {
            blip = {
                coords = vec(1110.55, -2008.6, 32.02),
                sprite = 436,
                color = 1,
                scale = 0.8,
                label = "Mining - Lebur Batu"
            },
            target = {
                coords = vec(1110.55, -2008.6, 32.02),
                radius = 5.0,
                distance = 1.5
            },
            battlepass = {
                premium = {
                    count = 1,
                    taskid = 5
                },
            },
            menu = {
                {
                    label = 'Copper',
                    description = 'Membutuhkan 8 Clean Stone',
                    icon = 'fas fa-fire',
                    items = {
                        remove = { clean_stone = 8 },
                        add = { copper = { min = 1, max = 3 } }
                    },
                },
                {
                    label = 'Iron',
                    description = 'Membutuhkan 13 Clean Stone',
                    icon = 'fas fa-fire',
                    items = {
                        remove = { clean_stone = 13 },
                        add = { iron = { min = 1, max = 3 } }
                    },
                },
                {
                    label = 'Silver',
                    description = 'Membutuhkan 18 Clean Stone',
                    icon = 'fas fa-fire',
                    items = {
                        remove = { clean_stone = 18 },
                        add = { silver = { min = 1, max = 3 } }
                    },
                },
                {
                    label = 'Sulfur',
                    description = 'Membutuhkan 23 Clean Stone',
                    icon = 'fas fa-fire',
                    items = {
                        remove = { clean_stone = 23 },
                        add = { sulfur = { min = 1, max = 3 } }
                    },
                },
                {
                    label = 'Aluminum',
                    description = 'Membutuhkan 28 Clean Stone',
                    icon = 'fas fa-fire',
                    items = {
                        remove = { clean_stone = 28 },
                        add = { aluminum = { min = 1, max = 3 } }
                    },
                },
                {
                    label = 'Nefrit',
                    description = 'Membutuhkan 38 Clean Stone',
                    icon = 'fas fa-fire',
                    items = {
                        remove = { clean_stone = 38 },
                        add = { nefrit = { min = 1, max = 3 } }
                    },
                },
                {
                    label = 'Quartz',
                    description = 'Membutuhkan 43 Clean Stone',
                    icon = 'fas fa-fire',
                    items = {
                        remove = { clean_stone = 43 },
                        add = { quartz = { min = 1, max = 3 } }
                    },
                }
            },
            progressbar = {
                duration = 10000,
                label = 'Melebur batu...',
                anim = {
                    dict = 'amb@prop_human_parking_meter@male@idle_a',
                    clip = 'idle_a'
                },
            }
        }
    }
}