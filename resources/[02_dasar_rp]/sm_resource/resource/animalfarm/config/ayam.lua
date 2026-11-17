return {
    blip = {
        chickenFarm = {
            sprite = 238,
            color = 5,
            scale = 0.7,
            category = 25,
            label = "Peternakan Ayam",
            coords = vec(2389.9648, 5038.2363, 46.2034)
        },
        chickenProcessing = {
            sprite = 238,
            color = 5,
            scale = 0.7,
            category = 25,
            label = "Processing Ayam",
            coords = vec(-98.7648, 6209.5156, 31.0250)
        }
    },
    catch = {
        npc = {
            model = `a_m_m_farmer_01`,
            coords = vector4(2383.98, 5031.81, 45.89, 309.61),
            scenario = "WORLD_HUMAN_COP_IDLES",
        },

        chicken = {
            model = `a_c_hen`,
            count = 10,
            chance = 0.85, --- chance 85%, 1.0 = 100%
        },

        playercoords = {
            enter = vec(2385.0388, 5045.8979, 46.3485, 46.8917),
            exit = vec(2385.4543, 5041.8545, 46.2691, 201.4404)
        },

        polygon = {
            points = {
                vec3(2384.330078125, 5043.490234375, 46.0),
                vec3(2382.7399902344, 5042.759765625, 46.0),
                vec3(2381.2600097656, 5042.25, 46.0),
                vec3(2379.330078125, 5041.919921875, 46.0),
                vec3(2377.2700195312, 5041.9599609375, 46.0),
                vec3(2375.5900878906, 5042.240234375, 46.0),
                vec3(2373.8500976562, 5042.8598632812, 46.0),
                vec3(2373.1499023438, 5043.16015625, 46.0),
                vec3(2372.0500488281, 5043.8701171875, 46.0),
                vec3(2370.6999511719, 5044.919921875, 46.0),
                vec3(2368.9599609375, 5046.9501953125, 46.0),
                vec3(2367.6201171875, 5049.7202148438, 46.0),
                vec3(2367.1398925781, 5052.3500976562, 46.0),
                vec3(2367.3000488281, 5055.2099609375, 46.0),
                vec3(2368.0, 5057.6201171875, 46.0),
                vec3(2369.2700195312, 5059.8701171875, 46.0),
                vec3(2371.3100585938, 5062.009765625, 46.0),
                vec3(2373.5, 5063.3598632812, 46.0),
                vec3(2376.1599121094, 5064.3598632812, 46.0),
                vec3(2378.5300292969, 5064.5200195312, 46.0),
                vec3(2380.4099121094, 5064.3598632812, 46.0),
                vec3(2382.669921875, 5063.6801757812, 46.0),
                vec3(2384.8400878906, 5062.5600585938, 46.0),
                vec3(2385.9399414062, 5061.6899414062, 46.0),
                vec3(2387.0900878906, 5060.5, 46.0),
                vec3(2388.1599121094, 5059.080078125, 46.0),
                vec3(2389.0500488281, 5057.2099609375, 46.0),
                vec3(2389.5600585938, 5055.4599609375, 46.0),
                vec3(2389.7700195312, 5053.3701171875, 46.0),
                vec3(2389.5900878906, 5051.2202148438, 46.0),
                vec3(2388.9899902344, 5049.1201171875, 46.0),
                vec3(2388.2600097656, 5047.66015625, 46.0),
                vec3(2387.5400390625, 5046.4301757812, 46.0),
                vec3(2385.8798828125, 5044.6298828125, 46.0),
                vec3(2385.1101074219, 5043.990234375, 46.0),
                vec3(2385.0, 5044.0, 46.0),
            },
            thickness = 4.0,
        }
    },
    proccess = {
        {
            target = {
                coords = vec(-95.183479, 6207.646484, 31.025970),
                radius = 0.5
            },
            items = {
                remove = {
                    alivechicken = 10,
                },
                add = {
                    slaughteredchicken = 10,
                    telur = 2,
                }
            },
            animation = {
                coords = vec(-96.007, 6206.92, 31.02, 311.0),
                dict = 'anim@amb@business@coc@coc_unpack_cut_left@',
                clip = 'coke_cut_v1_coccutter',

                props = {
                    chicken = {
                        model = 'prop_int_cf_chick_01',
                        pos = vec(-94.87, 6207.008, 30.08),
                        rot = vec(90.0, 0.0, 45.0),
                        rotOrder = 1
                    },
                    knife = {
                        model = 'prop_knife',
                        bone = 0xDEAD,
                        pos = vec(0.13, 0.14, 0.09),
                        rot = vec(40.0, 0.0, 0.0)
                    }
                }
            },
        },
        {
            target = {
                coords = vec(-99.951080, 6202.018066, 31.073465),
                radius = 0.5
            },
            items = {
                remove = {
                    alivechicken = 10,
                },
                add = {
                    slaughteredchicken = 10,
                    telur = 2,
                }
            },
            animation = {
                coords = vec(-100.64, 6202.30, 31.02, 220.0),
                dict = 'anim@amb@business@coc@coc_unpack_cut_left@',
                clip = 'coke_cut_v1_coccutter',

                props = {
                    chicken = {
                        model = 'prop_int_cf_chick_01',
                        pos = vec(-100.39, 6201.56, 29.99),
                        rot = vec(90.0, 0.0, -45.0),
                        rotOrder = 1
                    },
                    knife = {
                        model = 'prop_knife',
                        bone = 0xDEAD,
                        pos = vec(0.13, 0.14, 0.09),
                        rot = vec(40.0, 0.0, 0.0)
                    }
                }
            },
        }
    },
    packing = {
        coords = {
            vector3(-100.7852, 6211.3174, 30.9928),
            vector3(-103.1141, 6209.3901, 30.9928),
            vector3(-104.6272, 6207.5127, 30.9928),
            vector3(-107.1317, 6205.4102, 30.9391)
        },
        items = {
            remove = {
                slaughteredchicken = 5,
            },
            add = {
                packagedchicken = 5
            }
        },
        animation = {
            dict = 'anim@heists@ornate_bank@grab_cash_heels',
            clip = 'grab',

            props = {
                meat = {
                    model = 'prop_cs_steak',
                    bone = 0x49D9,
                    pos = vec(0.15, 0.0, 0.01),
                    rot = vec(0.0, 0.0, 0.0)
                },
                box = {
                    model = 'prop_cs_clothes_box',
                    bone = 57005,
                    pos = vec(0.13, 0.0, -0.16),
                    rot = vec(250.0, -30.0, 0.0)
                }
            }
        }
    }
}