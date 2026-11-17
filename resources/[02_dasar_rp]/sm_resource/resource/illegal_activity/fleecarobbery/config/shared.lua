return {
    -- Item break mechanic: applies to all robbery types
    itemMechanic = {
        maxFails = 2,       -- 2x gagal = item rusak (destroyed)
        removeOnSuccess = true, -- berhasil = item hilang
    },
    basic = {
       [1] = {
            label = 'Lol',
            door_hack = {
                {
                    id = 'vault',
                    object = `v_ilev_gb_vauldr`,
                    coords = vec3(311.15, -284.49, 54.16),
                    heading = {
                        closed = 250.0,
                        open = 160.0
                    },
                    requiredItem = {
                        trojan_usb = 1
                    },
                    isOpened = false,
                    scene = {
                        name = 'latopHackStart',
                        coords = vector4(311.6306, -284.6318, 54.55, 248.3483),
                        
                    },
                },
                {
                    id = 'bar',
                    object = `v_ilev_gb_vaubar`,
                    coords = vec(314.62, -285.99, 54.46, 159.86),
                    requiredItem = {
                        code_injector = 1
                    },
                    isOpened = false,
                    scene = {
                        name = 'latopHackStart', -- same animation as vault hack (pathFind)
                        coords = vec(313.351532, -285.506714, 54.505241, 159.9179),
                    }
                }
            },
            trolley = {
                {
                    coords = vec(315.3859, -284.5895, 54.1430, 88.3696),
                    looted = false
                },
                {
                    coords = vec(314.2249, -289.2992, 54.1431, 18.4524),
                    looted = false
                },
                {
                    coords = vec(311.0460, -288.2455, 54.1430, 281.8043),
                    looted = false
                }
            },
            drill = {
                {
                    coords = vec(315.247162, -288.157684, 54.396534),
                    looted = false,
                    requiredItem = {
                        drill = 1
                    }
                }
            }
        },
        [2] = {
            label = 'Legion Square',
            door_hack = {
                {
                    id = 'vault',
                    object = `v_ilev_gb_vauldr`,
                    coords = vec3(146.92, -1046.11, 29.36),
                    heading = {
                        closed = 250.0,
                        open = 160.0
                    },
                    requiredItem = {
                        trojan_usb = 1
                    },
                    isOpened = false,
                    scene = {
                        name = 'latopHackStart',
                        coords = vector4(147.3442, -1046.2640, 29.8, 249.1374),
                    },
                },
                {
                    id = 'bar',
                    object = `v_ilev_gb_vaubar`,
                    coords = vec(150.29, -1047.63, 29.67, 159.85),
                    requiredItem = {
                        code_injector = 1
                    },
                    isOpened = false,
                    scene = {
                        name = 'latopHackStart',
                        coords = vec(149.023087, -1047.142212, 29.705883, 164.3748),
                    }
                }
            },
            trolley = {
                {
                    coords = vec(151.1263, -1046.3137, 29.3463, 76.7704),
                    looted = false
                },
                {
                    coords = vec(146.9964, -1050.1722, 29.3463, 350.4200),
                    looted = false
                },
                {
                    coords = vec(149.3188, -1051.0671, 29.3464, 332.2993),
                    looted = false
                }
            },
            drill = {
                {
                    coords = vec3(150.627411, -1049.782837, 29.703100),
                    looted = false,
                    requiredItem = {
                        drill = 1
                    }
                }
            }
        },
        [3] = {
            label = 'Hawick Ave',
            door_hack = {
                {
                    id = 'vault',
                    object = `v_ilev_gb_vauldr`,
                    coords = vec3(-353.82, -55.37, 49.03),
                    heading = {
                        closed = 250.0,
                        open = 160.0
                    },
                    requiredItem = {
                        trojan_usb = 1
                    },
                    isOpened = false,
                    scene = {
                        name = 'latopHackStart',
                        coords = vector4(-353.3885, -55.4943, 49.5, 245.7704),
                    },
                },
                {
                    id = 'bar',
                    object = `v_ilev_gb_vaubar`,
                    coords = vec(-350.41, -56.80, 49.33, 160.86),
                    requiredItem = {
                        code_injector = 1
                    },
                    isOpened = false,
                    scene = {
                        name = 'latopHackStart',
                        coords = vec(-351.714172, -56.326553, 49.343834, 168.9457),
                    }
                }
            },
            trolley = {
                {
                    coords = vec(-349.5735, -55.6512, 49.0148, 77.0982),
                    looted = false
                },
                {
                    coords = vec(-353.5779, -59.3673, 49.0148, 354.9333),
                    looted = false
                },
                {
                    coords = vec(-351.1781, -60.2415, 49.0149, 335.0868),
                    looted = false
                }
            },
            drill = {
                {
                    coords = vec(-349.745026, -58.924332, 49.276966),
                    looted = false,
                    requiredItem = {
                        drill = 1
                    }
                }
            }
        },
        [4] = {
            label = 'Del Perro Blvd',
            door_hack = {
                {
                    id = 'vault',
                    object = `v_ilev_gb_vauldr`,
                    coords = vec3(-1210.77, -336.57, 37.78),
                    heading = {
                        closed = 296.863,
                        open = 206.863
                    },
                    requiredItem = {
                        trojan_usb = 1
                    },
                    isOpened = false,
                    scene = {
                        name = 'latopHackStart',
                        coords = vector4(-1210.4010, -336.2261, 38.2, 296.7554),
                    },
                },
                {
                    id = 'bar',
                    object = `v_ilev_gb_vaubar`,
                    coords = vec(-1207.33, -335.13, 38.08, 206.86),
                    requiredItem = {
                        code_injector = 1
                    },
                    isOpened = false,
                    scene = {
                        name = 'latopHackStart',
                        coords = vec(-1208.549927, -335.725342, 38.125500, 204.6689),
                    }
                }
            },
            trolley = {
                {
                    coords = vec(-1207.6090, -333.7827, 37.7593, 118.2563),
                    looted = false
                },
                {
                    coords = vec(-1207.7108, -339.0943, 37.7593, 34.0808),
                    looted = false
                },
                {
                    coords = vec(-1205.4202, -338.0032, 37.7593, 22.0144),
                    looted = false
                }
            },
            drill = {
                {
                    coords = vec(-1205.339966, -336.111023, 38.043556),
                    looted = false,
                    requiredItem = {
                        drill = 1
                    }
                }
            }
        },
        [5] = {
            label = 'Great Ocean Hwy',
            door_hack = {
                {
                    id = 'vault',
                    object = `hei_prop_heist_sec_door`,
                    coords = vec3(-2956.55, 481.74, 15.69),
                    heading = {
                        closed = 357.5,
                        open = 267.5
                    },
                    requiredItem = {
                        trojan_usb = 1
                    },
                    isOpened = false,
                    scene = {
                        name = 'latopHackStart',
                        coords = vector4(-2956.6045, 482.1689, 16.0, 345.6635),
                    },
                },
                {
                    id = 'bar',
                    object = `v_ilev_gb_vaubar`,
                    coords = vec(-2956.12, 485.42, 16.00, 267.38),
                    requiredItem = {
                        code_injector = 1
                    },
                    isOpened = false,
                    scene = {
                        name = 'latopHackStart',
                        coords = vec(-2956.186279, 484.040100, 15.990762, 273.3850),
                    }
                }
            },
            trolley = {
                {
                    coords = vec(-2957.4944, 485.8508, 15.6753, 178.7002),
                    looted = false
                },
                {
                    coords = vec(-2952.6445, 483.1091, 15.6754, 89.7455),
                    looted = false
                },
                {
                    coords = vec(-2952.6057, 485.6333, 15.6754, 78.5460),
                    looted = false
                }
            },
            drill = {
                {
                    coords = vec3(-2954.251709, 486.643555, 15.965343),
                    looted = false,
                    requiredItem = {
                        drill = 1
                    }
                }
            }
        },
    },
    blaneCounty = {
        computer = {
            coords = vec3(-106.518448, 6470.307617, 31.433706),
            hacked = false,
            requiredItem = {
                security_card = 1
            },
        },
        door_hack = {
            {
                id = 'vault',
                object = `v_ilev_cbankvauldoor01`,
                coords = vec3(-105.61, 6472.03, 31.62),
                heading = {
                    closed = 45.0,
                    open = 130.0
                },
                requiredItem = {
                    laptop_malware = 1
                },
                isOpened = false,
                scene = {
                    name = 'latopHackStart',
                    coords = vector4(-105.8783, 6472.1694, 31.6622, 46.9140),
                },
            },
            {
                id = 'bar',
                object = `v_ilev_cbankvaulgate02`,
                coords = vec(-106.47, 6476.16, 31.95, 315.00),
                requiredItem = {
                    thermite = 1
                },
                isOpened = false,
                scene = {
                    name = 'plantThermite',
                    coords = vec(-105.487122, 6475.104492, 31.979010, 314.5707),
                }
            }
        },
        trolley = {
            {
                coords = vec(-107.5664, 6475.5532, 31.6267, 224.5463),
                looted = false
            },
            {
                coords = vec(-104.4554, 6479.0723, 31.6666, 134.8430),
                looted = false
            },
            {
                coords = vec(-102.5832, 6476.9170, 31.6267, 136.4286),
                looted = false
            },
            {
                coords = vec(-103.5000, 6478.0000, 31.6267, 135.0000),
                looted = false
            }
        },
        drill = {
            {
                coords = vec3(-106.663254, 6478.277344, 31.853802),
                looted = false,
                item = 'goldbar',
                amount = 2,
                tool = 'rusty_drill'
            },
            {
                coords = vec3(-104.000000, 6477.000000, 31.853802),
                looted = false,
                item = 'goldbar',
                amount = 2,
                tool = 'rusty_drill'
            },
            {
                coords = vec3(-103.000000, 6479.000000, 31.853802),
                looted = false,
                item = 'goldbar',
                amount = 2,
                tool = 'rusty_drill'
            }
        },
        -- Table in center of vault: lucky/zonk system
        centerTable = {
            coords = vec(-105.0000, 6477.5000, 31.8538, 315.0000),
            looted = false,
            lucky = {
                item = 'laptop_gold',
                max = 2,
                chance = 80, -- 80% chance
            },
            zonk = {
                { item = 'diamond', amount = 1 },
            }
        }
    },
    pacificBank = {
        door_hack = {
            {
                id = 'bar',
                object = `hei_v_ilev_bk_gate_pris`,
                coords = vec(256.31, 220.66, 106.43, 339.66),
                requiredItem = {
                    thermite = 1
                },
                isOpened = false,
                scene = {
                    name = 'plantThermite',
                    coords = vec(257.388000, 220.248016, 106.435478, 343.7385),
                }
            },
            {
                id = 'bar',
                object = `hei_v_ilev_bk_gate2_pris`,
                coords = vec(262.20, 222.52, 106.43, 250.00),
                requiredItem = {
                    laptop_gold = 1
                },
                scene = {
                    name = 'latopHackStart',
                    coords = vector4(262.3195, 223.0177, 106.59, 244.8353),
                },
                isOpened = false,
                checkDoor = 1
            },
            {
                id = 'vault',
                object = `v_ilev_bk_vaultdoor`,
                coords = vec3(255.23, 223.98, 102.39),
                heading = {
                    closed = 160.0,
                    open = 70.0
                },
                requiredItem = {
                    backdoor_kit = 1
                },
                isOpened = false,
                scene = {
                    name = 'latopHackStart',
                    coords = vector4(252.7816, 228.5458, 102.05, 69.8701),
                },
                checkDoor = 2
            },
            {
                id = 'bar',
                object = `hei_v_ilev_bk_safegate_pris`,
                coords = vec(251.86, 221.07, 101.83, 159.60),
                requiredItem = {
                    thermite = 1
                },
                isOpened = false,
                scene = {
                    name = 'plantThermite',
                    coords = vec(252.952408, 220.708725, 101.827957, 160.8412),
                },
                checkDoor = 3
            },
            {
                id = 'bar',
                object = `hei_v_ilev_bk_safegate_pris`,
                coords = vec(261.30, 214.51, 101.83, 250.38),
                requiredItem = {
                    thermite = 1
                },
                isOpened = false,
                scene = {
                    name = 'plantThermite',
                    coords = vec(261.649597, 215.610931, 101.777222, 250.5419),
                },
                checkDoor = 4
            },
        },
        trolley = {
            -- 2 trolleys at coords 254.8347, 215.9758
            {
                coords = vec(254.8347, 215.9758, 101.6834, 341.2133),
                looted = false
            },
            {
                coords = vec(253.8131, 216.4675, 101.6833, 342.8640),
                looted = false
            },
            -- 2 trolleys at coords 255.8769, 218.9665
            {
                coords = vec(256.8699, 218.3815, 101.6833, 168.2276),
                looted = false
            },
            {
                coords = vec(255.3769, 218.4665, 101.6834, 168.3806),
                looted = false
            },
        },
        drill = {
            -- drill -> diamond_ring x4
            {
                coords = vec(258.4302, 214.1521, 101.6834, 162.9057),
                looted = false,
                item = 'diamond_ring',
                amount = 4,
                tool = 'drill'
            },
            -- drill -> diamond x4
            {
                coords = vec(259.6113, 217.9685, 101.6834, 347.6595),
                looted = false,
                item = 'diamond',
                amount = 4,
                tool = 'drill'
            },
            -- rusty_drill -> emerald 5, blue_sapphire 5
            {
                coords = vec(264.8115, 216.1596, 101.6833, 342.3148),
                looted = false,
                items = {
                    { item = 'emerald', amount = 5 },
                    -- { item = 'blue_sapphire', amount = 5 },
                },
                tool = 'rusty_drill'
            },
            {
                coords = vec(263.2288, 212.4046, 101.6833, 157.3500),
                looted = false,
                items = {
                    -- { item = 'emerald', amount = 5 },
                    { item = 'blue_sapphire', amount = 5 },
                },
                tool = 'rusty_drill'
            },
            {
                coords = vec(266.0883, 213.6695, 101.6834, 251.4315),
                looted = false,
                items = {
                    { item = 'emerald', amount = 5 },
                    -- { item = 'blue_sapphire', amount = 5 },
                },
                tool = 'rusty_drill'
            },
        },
        -- Code injector permission zone (opens access)
        codeInjector = {
            coords = vec(261.2794, 215.6025, 101.6834, 252.7225),
            requiredItem = {
                code_injector = 1
            },
            unlocked = false,
            scene = {
                name = 'latopHackStart',
                coords = vec(261.2794, 215.6025, 101.6834, 252.7225),
            }
        },
        -- Center table: mini game (ruby, emerald max 1 each)
        centerTable = {
            coords = vec(264.329468, 214.009293, 101.532745),
            looted = false,
            rewards = {
                { item = 'ruby', amount = 1 },
                { item = 'emerald', amount = 1 },
            }
        }
    },
}