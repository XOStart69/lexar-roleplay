local locations = {
    {
        managementId = 'ambulance_license',
        coords = {
            vec(1140.0398, -1535.3790, 34.8376, 0.0000),
        },
        ped_config = {
            model = 's_m_m_doctor_01',
            scenario = 'WORLD_HUMAN_CLIPBOARD',
        },
        interact = {
            {
                action_id = 'create',
                label = 'Buat Kartu',
                icon = 'fas fa-drivers-license',
                distance = 1.5,
                groups = { ambulance = 0 },
            },
            {
                action_id = 'management',
                label = 'Manage Kartu',
                icon = 'fas fa-drivers-license',
                distance = 1.5,
                groups = { ambulance = 0 },
            }
        },
        cardList = {
            { label = 'Kartu Kesehatan', value = 'kartu_kesehatan', price = 5000 }
        }
    },
    {
        managementId = 'kta_pabrik_license',
        coords = vec(204.134018, 1163.417480, 230.484146, 0.0),
        radius = 1.0,
        interact = {
            {
                action_id = 'create',
                label = 'Buat Kartu',
                icon = 'fas fa-drivers-license',
                distance = 1.5,
                groups = { pabrik = 4 },
            },
            {
                action_id = 'management',
                label = 'Manage Kartu',
                icon = 'fas fa-drivers-license',
                distance = 1.5,
                groups = { pabrik = 4 },
            }
        },
        cardList = {
            { label = 'KTA Pabrik', value = 'kta_pabrik', price = 5000 }
        }
    },
    {
        managementId = 'kta_rainhart',
        coords = vec(-281.924835, 6689.865723, 7.859717),
        radius = 1.0,
        interact = {
            {
                action_id = 'create',
                label = 'Buat Kartu',
                icon = 'fas fa-drivers-license',
                distance = 1.5,
                groups = { mhcafe = 0 },
            },
            {
                action_id = 'management',
                label = 'Manage Kartu',
                icon = 'fas fa-drivers-license',
                distance = 1.5,
                groups = { mhcafe = 0 },
            }
        },
        cardList = {
            { label = 'KTA Rainhart', value = 'kta_rainhart', price = 5000 }
        }
    },
    {
        managementId = 'kta_maxclub',
        coords = vec(98.130287, -1298.881226, 35.410877),
        radius = 1.0,
        interact = {
            {
                action_id = 'create',
                label = 'Buat Kartu',
                icon = 'fas fa-drivers-license',
                distance = 1.5,
                groups = { nightclub = 0 },
            },
            {
                action_id = 'management',
                label = 'Manage Kartu',
                icon = 'fas fa-drivers-license',
                distance = 1.5,
                groups = { nightclub = 0 },
            }
        },
        cardList = {
            { label = 'KTA Max Club', value = 'kta_maxclub', price = 5000 }
        }
    },
    {
        managementId = 'kta_yclub',
        coords = vec(50.5045, 6517.8853, 35.8418),
        radius = 1.0,
        interact = {
            {
                action_id = 'create',
                label = 'Buat Kartu',
                icon = 'fas fa-drivers-license',
                distance = 1.5,
                groups = { luxurynightclub = 0 },
            },
            {
                action_id = 'management',
                label = 'Manage Kartu',
                icon = 'fas fa-drivers-license',
                distance = 1.5,
                groups = { luxurynightclub = 0 },
            }
        },
        cardList = {
            { label = 'KTA Y Club', value = 'kta_yclub', price = 5000 }
        }
    },
    {
        managementId = 'dukcapil_license',
        coords = vec(-432.25, 1099.1, 327.78, 342.89),
        ped_config = {
            model = 's_m_y_cop_01',
            scenario = 'WORLD_HUMAN_CLIPBOARD',
        },
        interact = {
            {
                action_id = 'create',
                label = 'Buat Kartu',
                icon = 'fas fa-drivers-license',
                distance = 1.5,
                groups = { government = 0, paspampres = 0 },
            },
            {
                action_id = 'management',
                label = 'Manage Kartu',
                icon = 'fas fa-drivers-license',
                distance = 1.5,
                groups = { government = 0, paspampres = 0 },
            },
            {
                action_id = 'changename',
                label = 'Ganti Identitas',
                icon = 'fas fa-edit',
                distance = 1.5,
                groups = { government = 5 }
            }
        },
        cardList = {
            { label = 'KTP', value = 'ktp', price = 2000 },
            { label = 'KIA', value = 'kia', price = 2000 }
        },
        blip = {
            sprite = 280,
            color = 3,
            label = 'Layanan Pemerintah'
        }
    },
    {
        managementId = 'smpd_license',
        coords = {
            vec(442.0383, -978.8735, 30.6896, 176.1853),
            vec(2468.3188, 1578.7388, 30.5677, 357.3324),
        },
        ped_config = {
            model = 's_m_y_cop_01',
            scenario = 'WORLD_HUMAN_CLIPBOARD',
        },
        interact = {
            {
                action_id = 'create',
                label = 'Buat Kartu',
                icon = 'fas fa-drivers-license',
                distance = 1.5,
                groups = { police = 1 },
            },
            {
                action_id = 'management',
                label = 'Manage Kartu',
                icon = 'fas fa-drivers-license',
                distance = 1.5,
                groups = { police = 1 },
            }
        },
        cardList = {
            { label = 'Driver License', value = 'driver_license', price = 0 },
            -- { label = 'SIM A', value = 'driver_license_a', price = 0 },
            -- { label = 'SIM C', value = 'driver_license_c', price = 0 },
            { label = 'Helicopter License', value = 'helicopter_license', price = 0 },
            { label = 'Hunting License', value = 'huntinglicense', price = 0 },
            { label = 'Weapon License', value = 'weaponlicense', price = 0 }
        },
    },
    {
        managementId = 'kta_reporter_license',
        coords = vec(-294.997986, -603.729736, 45.302223, 0.0),
        radius = 0.5,
        interact = {
            {
                action_id = 'create',
                label = 'Buat Kartu',
                icon = 'fas fa-drivers-license',
                distance = 1.5,
                groups = { reporter = 5 },
            },
            {
                action_id = 'management',
                label = 'Manage Kartu',
                icon = 'fas fa-drivers-license',
                distance = 1.5,
                groups = { reporter = 5 },
            }
        },
        cardList = {
            { label = 'KTA Reporter', value = 'kta_reporter', price = 5000 },
        },
    },
    {
        managementId = 'kta_teknogarage_license',
        coords = vec(-2196.8, -452.75, 13.15, 0.0),
        radius = 0.5,
        interact = {
            {
                action_id = 'create',
                label = 'Buat Kartu',
                icon = 'fas fa-drivers-license',
                distance = 1.5,
                groups = { mechanic = 3 },
            },
            {
                action_id = 'management',
                label = 'Manage Kartu',
                icon = 'fas fa-drivers-license',
                distance = 1.5,
                groups = { mechanic = 3 },
            }
        },
        cardList = {
            { label = 'KTA Tekno Garage', value = 'kta_mechanic', price = 5000 },
        },
    },
    {
        managementId = 'kta_taxism_license',
        coords = vec3(-802.909546, -1354.273682, 12.045444),
        radius = 0.5,
        interact = {
            {
                action_id = 'create',
                label = 'Buat Kartu',
                icon = 'fas fa-drivers-license',
                distance = 1.5,
                groups = { taxism = 1 },
            },
            {
                action_id = 'management',
                label = 'Manage Kartu',
                icon = 'fas fa-drivers-license',
                distance = 1.5,
                groups = { taxism = 1 },
            }
        },
        cardList = {
            { label = 'KTA SMGO', value = 'kta_taxism', price = 5000 },
        },
    },
    {
        managementId = 'kta_smpd_license',
        coords = {
            vec(447.376007, -974.341492, 30.468256),
            vec(2469.459229, 1570.519287, 30.399115),
        },
        radius = 0.5,
        interact = {
            {
                action_id = 'create',
                label = 'Buat Kartu',
                icon = 'fas fa-drivers-license',
                distance = 1.5,
                groups = { police = 3 },
            },
            {
                action_id = 'management',
                label = 'Manage Kartu',
                icon = 'fas fa-drivers-license',
                distance = 1.5,
                groups = { police = 3 },
            }
        },
        cardList = {
            { label = 'LSPD Badge', value = 'lspdbadge', price = 0},
            { label = 'BCSO Badge', value = 'bcsobadge', price = 0},
            { label = 'SASP Badge', value = 'saspbadge', price = 0},
        },
    },
    -- {
    --     managementId = 'kta_smpd_license2',
    --     coords = vec(148.277817, -758.205444, 241.999634, 0.0),
    --     radius = 0.5,
    --     interact = {
    --         {
    --             action_id = 'create',
    --             label = 'Buat Kartu',
    --             icon = 'fas fa-drivers-license',
    --             distance = 1.5,
    --             groups = { police = 3 },
    --         },
    --         {
    --             action_id = 'management',
    --             label = 'Manage Kartu',
    --             icon = 'fas fa-drivers-license',
    --             distance = 1.5,
    --             groups = { police = 3 },
    --         }
    --     },
    --     cardList = {
    --         { label = 'KTA Criminal',        value = 'kta_criminal',       price = 5000 },
    --         { label = 'KTA Detective',        value = 'kta_detective',      price = 5000 },
    --         { label = 'KTA FIB',              value = 'kta_fib',            price = 5000 },
    --         { label = 'KTA LSPD',             value = 'kta_lspd',           price = 5000 },
    --         { label = 'KTA Sheriff',          value = 'kta_sheriff',        price = 5000 },
    --         { label = 'KTA SMSP',             value = 'kta_smsp',           price = 5000 },
    --         { label = 'KTA SORT',             value = 'kta_sort',           price = 5000 },
    --         { label = 'KTA Special Response', value = 'kta_specialrespon',  price = 5000 },
    --         { label = 'KTA Special Weapon',   value = 'kta_specialweapon',  price = 5000 },
    --     },
    -- },
    {
        managementId = 'kta_government_license',
        coords = vec(-432.2, 1094.6, 326.65, 0.0),
        radius = 0.5,
        interact = {
            {
                action_id = 'create',
                label = 'Buat Kartu',
                icon = 'fas fa-drivers-license',
                distance = 1.5,
                groups = { government = 3, paspampres = 3 },
            },
            {
                action_id = 'management',
                label = 'Manage Kartu',
                icon = 'fas fa-drivers-license',
                distance = 1.5,
                groups = { government = 3, paspampres = 3 },
            }
        },
        cardList = {
            { label = 'KTA Government', value = 'kta_government', price = 5000 },
        },
    },
    {
        managementId = 'kta_rsroxwood_license',
        coords = vec(-477.249817, 7438.133789, 8.086507),
        radius = 0.5,
        interact = {
            {
                action_id = 'create',
                label = 'Buat Kartu',
                icon = 'fas fa-drivers-license',
                distance = 1.5,
                groups = { rsroxwood = 0 },
            },
            {
                action_id = 'management',
                label = 'Manage Kartu',
                icon = 'fas fa-drivers-license',
                distance = 1.5,
                groups = { rsroxwood = 0 },
            }
        },
        cardList = {
            { label = 'KTA RS Roxwood', value = 'kta_rs_roxwood', price = 5000 },
        },
    },
    {
        managementId = 'kta_kkp_license',
        coords = vec(-578.007507, -1066.945923, 26.515198),
        radius = 0.5,
        interact = {
            {
                action_id = 'create',
                label = 'Buat Kartu',
                icon = 'fas fa-drivers-license',
                distance = 1.5,
                groups = { kkpresto = 0 },
            },
            {
                action_id = 'management',
                label = 'Manage Kartu',
                icon = 'fas fa-drivers-license',
                distance = 1.5,
                groups = { kkpresto = 0 },
            }
        },
        cardList = {
            { label = 'KTA KKP', value = 'kta_kungkungkap', price = 5000 },
        },
    },
    {
        managementId = 'kta_resto_license',
        coords = vec(-1773.105957, -1228.581665, 14.444554),
        radius = 0.5,
        interact = {
            {
                action_id = 'create',
                label = 'Buat Kartu',
                icon = 'fas fa-drivers-license',
                distance = 1.5,
                groups = { resto = 3 },
            },
            {
                action_id = 'management',
                label = 'Manage Kartu',
                icon = 'fas fa-drivers-license',
                distance = 1.5,
                groups = { resto = 3 },
            }
        },
        cardList = {
            { label = 'KTA Nusantara', value = 'kta_resto', price = 5000 },
        },
    },
    {
        managementId = 'kta_969_resto_license',
        coords = vec(1531.719971, 3784.598145, 34.434738),
        radius = 0.5,
        interact = {
            {
                action_id = 'create',
                label = 'Buat Kartu',
                icon = 'fas fa-drivers-license',
                distance = 1.5,
                groups = { burgenkcafe = 5 },
            },
            {
                action_id = 'management',
                label = 'Manage Kartu',
                icon = 'fas fa-drivers-license',
                distance = 1.5,
                groups = { burgenkcafe = 5 },
            }
        },
        cardList = {
            { label = 'KTA 969 Resto', value = 'kta_969_resto', price = 5000 },
        },
    },
    {
        managementId = 'kta_stunberg_license',
        coords = vec(-236.118210, 6208.445801, 31.781487),
        radius = 0.5,
        interact = {
            {
                action_id = 'create',
                label = 'Buat Kartu',
                icon = 'fas fa-drivers-license',
                distance = 1.5,
                groups = { stunberg = 3 },
            },
            {
                action_id = 'management',
                label = 'Manage Kartu',
                icon = 'fas fa-drivers-license',
                distance = 1.5,
                groups = { stunberg = 3 },
            }
        },
        cardList = {
            { label = 'KTA Stunberg', value = 'kta_stunberg', price = 5000 },
        },
    },
    {
        managementId = 'kta_969_garage_license',
        coords = vec(1190.613525, 2648.576660, 38.270031),
        radius = 0.5,
        interact = {
            {
                action_id = 'create',
                label = 'Buat Kartu',
                icon = 'fas fa-drivers-license',
                distance = 1.5,
                groups = { mechanic969 = 3 },
            },
            {
                action_id = 'management',
                label = 'Manage Kartu',
                icon = 'fas fa-drivers-license',
                distance = 1.5,
                groups = { mechanic969 = 3 },
            }
        },
        cardList = {
            { label = 'KTA 969 Garage', value = 'kta_969_garage', price = 5000 },
        },
    },
    {
        managementId = 'kta_max_speed_license',
        coords = vec(-345.909698, -130.392975, 38.935299),
        radius = 0.5,
        interact = {
            {
                action_id = 'create',
                label = 'Buat Kartu',
                icon = 'fas fa-drivers-license',
                distance = 1.5,
                groups = { maxspeedgarage = 3 },
            },
            {
                action_id = 'management',
                label = 'Manage Kartu',
                icon = 'fas fa-drivers-license',
                distance = 1.5,
                groups = { maxspeedgarage = 3 },
            }
        },
        cardList = {
            { label = 'KTA Max Speed Garage', value = 'kta_max_speed', price = 5000 },
        },
    },
    {
        managementId = 'kta_atomburger_license',
        coords = vec(-1317.550293, 6972.689453, 20.687342),
        radius = 0.5,
        interact = {
            {
                action_id = 'create',
                label = 'Buat Kartu',
                icon = 'fas fa-drivers-license',
                distance = 1.5,
                groups = { pdcafe = 0 },
            },
            {
                action_id = 'management',
                label = 'Manage Kartu',
                icon = 'fas fa-drivers-license',
                distance = 1.5,
                groups = { pdcafe = 0 },
            }
        },
        cardList = {
            { label = 'KTA Atom Burger', value = 'kta_atomburger', price = 5000 },
        },
    },

    {
        managementId = 'kta_dojusms_license',
        coords = vec(218.240448, -431.888336, 47.760658),
        radius = 0.5,
        interact = {
            {
                action_id = 'create',
                label = 'Buat Kartu',
                icon = 'fas fa-drivers-license',
                distance = 1.5,
                groups = { pengadilan = 4, usmarshal = 4, },
            },
            {
                action_id = 'management',
                label = 'Manage Kartu',
                icon = 'fas fa-drivers-license',
                distance = 1.5,
                groups = { pengadilan = 4, usmarshal = 4, },
            }
        },
        cardList = {
            { label = 'DOJ Badge', value = 'dojbadge', price = 0},
            { label = 'US Marshal Badge', value = 'usmbadge', price = 0},
            { label = 'Kartu State Bar', value = 'kta_statebar', price = 0},
        },
    },

    {
        managementId = 'ktp_palsu_license1',
        coords = vec(5012.070312, -5788.292969, 17.791313),
        radius = 0.5,
        interact = {
            {
                action_id = 'create',
                label = 'Buat Kartu',
                icon = 'fas fa-drivers-license',
                distance = 1.5,
                groups = { hightable = 5 },
            },
            {
                action_id = 'management',
                label = 'Manage Kartu',
                icon = 'fas fa-drivers-license',
                distance = 1.5,
                groups = { hightable = 5 },
            }
        },
        cardList = {
            { label = 'KTP Palsu', value = 'ktp_palsu', price = 50000 }
        }
    },
    {
        managementId = 'ktp_palsu_license2',
        coords = vec(-127.274445, -641.616272, 168.625580),
        radius = 0.5,
        interact = {
            {
                action_id = 'create',
                label = 'Buat Kartu',
                icon = 'fas fa-drivers-license',
                distance = 1.5,
                groups = { police = 15 },
            },
            {
                action_id = 'management',
                label = 'Manage Kartu',
                icon = 'fas fa-drivers-license',
                distance = 1.5,
                groups = { police = 15 },
            }
        },
        cardList = {
            { label = 'KTP Palsu', value = 'ktp_palsu', price = 50000 }
        }
    },
    -- {
    --     managementId = 'ktp_palsu_license3',
    --     coords = vec(-103.687508, 982.458191, 235.696121),
    --     radius = 0.5,
    --     interact = {
    --         {
    --             action_id = 'create',
    --             label = 'Buat Kartu',
    --             icon = 'fas fa-drivers-license',
    --             distance = 1.5,
    --             groups = { nightwalkersm = 6 },
    --         },
    --         {
    --             action_id = 'management',
    --             label = 'Manage Kartu',
    --             icon = 'fas fa-drivers-license',
    --             distance = 1.5,
    --             groups = { nightwalkersm = 6 },
    --         }
    --     },
    --     cardList = {
    --         { label = 'KTP Palsu', value = 'ktp_palsu', price = 50000 }
    --     }
    -- },

    {
        managementId = 'casino_member_license',
        coords = vec3(954.330627, 55.735062, 75.605804),
        radius = 0.5,
        interact = {
            {
                action_id = 'create',
                label = 'Buat Kartu',
                icon = 'fas fa-drivers-license',
                distance = 1.5,
                groups = { velvetsm = 4 },
            },
            {
                action_id = 'management',
                label = 'Manage Kartu',
                icon = 'fas fa-drivers-license',
                distance = 1.5,
                groups = { velvetsm = 4 },
            }
        },
        cardList = {
            { label = 'Casino Gold Member', value = 'casino_gold_member', price = 10000 },
            -- { label = 'Casino Platinum Member', value = 'casino_platinum_member', price = 25000 },
        },
    },
    {
        managementId = 'kta_kedai_ygm',
        coords = vec3(-2165.25, 4201.52, 37.10),
        radius = 0.5,
        interact = {
            {
                action_id = 'create',
                label = 'Buat Kartu',
                icon = 'fas fa-drivers-license',
                distance = 1.5,
                groups = { gzcafe = 4 },
            },
            {
                action_id = 'management',
                label = 'Manage Kartu',
                icon = 'fas fa-drivers-license',
                distance = 1.5,
                groups = { gzcafe = 4 },
            }
        },
        cardList = {
            { label = 'KTA ECL Kedai', value = 'kta_kedai_ygm', price = 10000 },
            -- { label = 'Casino Platinum Member', value = 'casino_platinum_member', price = 25000 },
        },
    },
    
    {
        managementId = 'kta_wartel',
        coords = vec3(-775.827454, 5598.360840, 33.563599),
        radius = 0.5,
        interact = {
            {
                action_id = 'create',
                label = 'Buat Kartu',
                icon = 'fas fa-drivers-license',
                distance = 1.5,
                groups = { wartelsm = 3 },
            },
            {
                action_id = 'management',
                label = 'Manage Kartu',
                icon = 'fas fa-drivers-license',
                distance = 1.5,
                groups = { wartelsm = 3 },
            }
        },
        cardList = {
            { label = 'KTA Wartel', value = 'kta_wartel', price = 10000 },
        },
    },

    {
        managementId = 'kta_smmotel',
        coords = vec3(-813.110352, -690.959229, 27.956768),
        radius = 0.5,
        interact = {
            {
                action_id = 'create',
                label = 'Buat Kartu',
                icon = 'fas fa-drivers-license',
                distance = 1.5,
                groups = { smmotel = 1 },
            },
            {
                action_id = 'management',
                label = 'Manage Kartu',
                icon = 'fas fa-drivers-license',
                distance = 1.5,
                groups = { smmotel = 1 },
            }
        },
        cardList = {
            { label = 'KTA SM Motel', value = 'kta_smmotel', price = 10000 },
        },
    },

    {
        managementId = 'kta_paud',
        coords = vec3(348.591766, 3553.244385, 35.172531),
        radius = 0.5,
        interact = {
            {
                action_id = 'create',
                label = 'Buat Kartu',
                icon = 'fas fa-drivers-license',
                distance = 1.5,
                groups = { paud = 1 },
            },
            {
                action_id = 'management',
                label = 'Manage Kartu',
                icon = 'fas fa-drivers-license',
                distance = 1.5,
                groups = { paud = 1 },
            }
        },
        cardList = {
            { label = 'KTA School Kids', value = 'kta_paud', price = 10000 },
        },
    },

    {
        managementId = 'kta_digitaldenroxwood',
        coords = vec3(-2933.493408, 6238.172363, 9.402450),
        radius = 0.5,
        interact = {
            {
                action_id = 'create',
                label = 'Buat Kartu',
                icon = 'fas fa-drivers-license',
                distance = 1.5,
                groups = { digitaldenroxwood = 3 },
            },
            {
                action_id = 'management',
                label = 'Manage Kartu',
                icon = 'fas fa-drivers-license',
                distance = 1.5,
                groups = { digitaldenroxwood = 3 },
            }
        },
        cardList = {
            { label = 'KTA DigitalDen Roxwood', value = 'kta_digitaldenroxwood', price = 10000 },
        },
    },

    {
        managementId = 'kta_ygmcenter',
        coords = vec3(-1336.8, -411.2, 37.05),
        radius = 0.5,
        interact = {
            {
                action_id = 'create',
                label = 'Buat Kartu',
                icon = 'fas fa-drivers-license',
                distance = 1.5,
                groups = { digitalden = 3 },
            },
            {
                action_id = 'management',
                label = 'Manage Kartu',
                icon = 'fas fa-drivers-license',
                distance = 1.5,
                groups = { digitalden = 3 },
            }
        },
        cardList = {
            { label = 'KTA YGM Center', value = 'kta_ygmcenter', price = 10000 },
        },
    },
    {
        managementId = 'kta_kkpgarage',
        coords = vec3(1374.123657, -2092.517334, 51.82288),
        radius = 0.5,
        interact = {
            {
                action_id = 'create',
                label = 'Buat Kartu',
                icon = 'fas fa-drivers-license',
                distance = 1.5,
                groups = { kkpgarage = 3 },
            },
            {
                action_id = 'management',
                label = 'Manage Kartu',
                icon = 'fas fa-drivers-license',
                distance = 1.5,
                groups = { kkpgarage = 3 },
            }
        },
        cardList = {
            { label = 'KTA KKP Garage', value = 'kta_kkpgarage', price = 10000 },
            -- { label = 'Casino Platinum Member', value = 'casino_platinum_member', price = 25000 },
        },
    },
    -- {
    --     managementId = 'dev_test',
    --     coords = vec3(-748.437927, -1294.163452, 4.828076),
    --     radius = 0.5,
    --     interact = {
    --         {
    --             action_id = 'create',
    --             label = 'Buat Kartu',
    --             icon = 'fas fa-drivers-license',
    --             distance = 1.5,
    --             -- groups = { ambulance = 0 },
    --         },
    --         {
    --             action_id = 'management',
    --             label = 'Manage Kartu',
    --             icon = 'fas fa-drivers-license',
    --             distance = 1.5,
    --             -- groups = { ambulance = 0 },
    --         },
    --         {
    --             action_id = 'changename',
    --             label = 'Ganti Identitas',
    --             icon = 'fas fa-edit',
    --             distance = 1.5,
    --             -- groups = { ambulance = 0 }
    --         }
    --     },
    --     cardList = {},
    -- },
}

-- local sconfig = localmodule 'shared'

-- local function buildDevCardList()
--     local seen, list = {}, {}

--     for i = 1, #locations do
--         local loc = locations[i]
--         if loc.managementId ~= 'dev_test' and loc.cardList then
--             for j = 1, #loc.cardList do
--                 local card = loc.cardList[j]
--                 if not seen[card.value] then
--                     seen[card.value] = true
--                     list[#list + 1] = { label = card.label, value = card.value, price = 0 }
--                 end
--             end
--         end
--     end

--     for itemname in pairs(sconfig.template) do
--         if not seen[itemname] then
--             seen[itemname] = true
--             list[#list + 1] = { label = (itemname:gsub('_', ' ')):upper(), value = itemname, price = 0 }
--         end
--     end

--     table.sort(list, function (a, b)
--         return a.label < b.label
--     end)

--     return list
-- end

-- for i = 1, #locations do
--     if locations[i].managementId == 'dev_test' then
--         locations[i].cardList = buildDevCardList()
--     end
-- end

return locations 