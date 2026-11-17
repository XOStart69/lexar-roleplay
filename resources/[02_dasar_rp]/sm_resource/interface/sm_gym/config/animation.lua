local animation = {}

animation.gym_1 = {
    {
        anim = {
            start = {
                dict = 'amb@prop_human_seat_muscle_bench_press@idle_a',
                clip = 'idle_a',
            },
            idle = {
                dict = 'amb@lo_res_idles@',
                clip = 'prop_human_seat_muscle_bench_lo_res_base',
            },
            exit = {
                dict = 'amb@prop_human_seat_muscle_bench_press@exit',
                clip = 'exit',
            }
        },
        prop = {
            {
                model = 'prop_barbell_02',
                boneIndex = 28422,
                pos = vector3(0.0, 0.0, 0.0),
                rot = vector3(0.0, 0.0, 0.0),
            }
        },
        offset = {
            height = -0.3,
            y = -0.15
        },
        gymProp = {
            model = 'prop_muscle_bench_03',
        },
        FreezePedOnStartAnim = true
    },
    {
        anim = {
            start = {
                dict = 'amb@prop_human_muscle_chin_ups@male@base',
                clip = 'base',
                time = 2500
            },
            idle = {
                dict = 'amb@prop_human_muscle_chin_ups@male@idle_a',
                clip = 'idle_a',
            },
            exit = {
                dict = 'amb@prop_human_muscle_chin_ups@male@exit',
                clip = 'exit',
            }
        },
        offset = {
            y = 0.53,
            heading = 360.0
        },
        gymProp = {
            model = 'prop_muscle_bench_05',
            mission_entity = true,
            coords = {
                vector4(-1199.5365, -1571.81274, 3.603294, 35.0),
                vector4(-1205.22913, -1563.68042, 3.604103, 215.0)
            }
        },
    },
    {
        anim = {
            start = {
                dict = "amb@world_human_muscle_free_weights@male@barbell@base",
                clip = "base",
                time = 3500
            },
            idle = {
                dict = "amb@world_human_muscle_free_weights@male@barbell@idle_a",
                clip = "idle_a",
            },
            exit = {
                dict = "mini@triathlon",
                clip = "ig_2_gen_warmup_02",
            }
        },
        prop = {
            {
                model = "prop_curl_bar_01",
                boneIndex = 28422,
                pos = vector3(0.0, 0.0, 0.0),
                rot = vector3(0.0, 0.0, 0.0),
            }
        },
        interact = {
            {
                type = 'box',
                coords = vec3(-1203.2900390625, -1573.5300292969, 4.75),
                size = vec3(0.60000002384186, 1.6000000238419, 2.5499999523163),
                rotation = 36.0,
            }
        },
        clearWorkOutPropsFirst = true
    },
    {
        anim = {
            enter = {
                dict = 'amb@world_human_sit_ups@male@enter',
                clip = 'enter',
                time = 3500
            },
            start = {
                dict = "amb@world_human_sit_ups@male@base",
                clip = "base",
                time = 3200
            },
            idle = {
                dict = "amb@world_human_sit_ups@male@idle_a",
                clip = "idle_b",
            },
            exit = {
                dict = "amb@world_human_sit_ups@male@exit",
                clip = "exit",
            }
        },
        command = 'situp'
    },
    {
        anim = {
            enter = {
                dict = 'amb@world_human_push_ups@male@enter',
                clip = 'enter',
                time = 3500
            },
            start = {
                dict = "amb@world_human_push_ups@male@base",
                clip = "base",
                time = 1000
            },
            idle = {
                dict = "amb@world_human_push_ups@male@idle_a",
                clip = "idle_c",
            },
            exit = {
                dict = "amb@world_human_push_ups@male@exit",
                clip = "exit",
            }
        },
        command = 'pushup'
    }
}

-- animation.gym_2 = {
--     {
--         anim = {
--             start = {
--                 dict = 'move_m@jog@',
--                 clip = 'run',
--                 time = 3500
--             },
--             idle = {
--                 dict = 'move_m@jogger',
--                 clip = 'idle',
--             },
--             exit = {
--                 dict = 'mini@triathlon',
--                 clip = 'ig_2_gen_warmup_02'
--             }
--         },
--         interact = {
--             {
--                 type = 'box',
--                 coords = vec3(-538.0, -2409.7900390625, 18.35000038147),
--                 size = vec3(0.5, 0.44999998807907, 0.69999998807907),
--                 rotation = 319.75,
--             }
--         },
--         playerCoords = vec(-537.4540, -2409.0894, 18.2546, 136.1996)
--     },
--     {
--         anim = {
--             start = {
--                 dict = 'move_m@jog@',
--                 clip = 'run',
--                 time = 3500
--             },
--             idle = {
--                 dict = 'move_m@jogger',
--                 clip = 'idle',
--             },
--             exit = {
--                 dict = 'mini@triathlon',
--                 clip = 'ig_2_gen_warmup_02'
--             }
--         },
--         interact = {
--             {
--                 type = 'box',
--                 coords = vec3(-539.02001953125, -2408.8898925781, 18.39999961853),
--                 size = vec3(0.60000002384186, 0.60000002384186, 0.5),
--                 rotation = 318.5,
--             }
--         },
--         playerCoords = vec(-538.4727, -2408.1338, 18.2531, 139.8516)
--     },
--     {
--         anim = {
--             start = {
--                 dict = 'amb@prop_human_muscle_chin_ups@male@base',
--                 clip = 'base',
--                 time = 2500
--             },
--             idle = {
--                 dict = 'amb@prop_human_muscle_chin_ups@male@idle_a',
--                 clip = 'idle_a',
--             },
--             exit = {
--                 dict = 'amb@prop_human_muscle_chin_ups@male@exit',
--                 clip = 'exit',
--             }
--         },
--         offset = {
--             y = 0.53,
--             heading = 360.0
--         },
--         gymProp = {
--             model = 'prop_muscle_bench_05',
--             mission_entity = true,
--             coords = {
--                 vector4(-538.8666, -2404.2522, 17.1713, 229.5813),
--             }
--         },
--     },
--     {
--         anim = {
--             start = {
--                 dict = "amb@world_human_muscle_free_weights@male@barbell@base",
--                 clip = "base",
--                 time = 3500
--             },
--             idle = {
--                 dict = "amb@world_human_muscle_free_weights@male@barbell@idle_a",
--                 clip = "idle_a",
--             },
--             exit = {
--                 dict = "mini@triathlon",
--                 clip = "ig_2_gen_warmup_02",
--             }
--         },
--         prop = {
--             {
--                 model = "prop_curl_bar_01",
--                 boneIndex = 28422,
--                 pos = vector3(0.0, 0.0, 0.0),
--                 rot = vector3(0.0, 0.0, 0.0),
--             }
--         },
--         interact = {
--             {
--                 type = 'box',
--                 coords = vec3(-537.551514, -2402.081787, 18.214998),
--                 size = vec3(0.60000002384186, 1.6000000238419, 2.5499999523163),
--                 rotation = 36.0,
--             },
--             {
--                 type = 'box',
--                 coords = vec3(-536.045166, -2403.175049, 18.214998),
--                 size = vec3(0.60000002384186, 1.6000000238419, 2.5499999523163),
--                 rotation = 36.0,
--             },
--         },
--         clearWorkOutPropsFirst = true
--     },
--     {
--         anim = {
--             enter = {
--                 dict = 'amb@world_human_sit_ups@male@enter',
--                 clip = 'enter',
--                 time = 3500
--             },
--             start = {
--                 dict = "amb@world_human_sit_ups@male@base",
--                 clip = "base",
--                 time = 3200
--             },
--             idle = {
--                 dict = "amb@world_human_sit_ups@male@idle_a",
--                 clip = "idle_b",
--             },
--             exit = {
--                 dict = "amb@world_human_sit_ups@male@exit",
--                 clip = "exit",
--             }
--         },
--         command = 'situp'
--     },
--     {
--         anim = {
--             enter = {
--                 dict = 'amb@world_human_push_ups@male@enter',
--                 clip = 'enter',
--                 time = 3500
--             },
--             start = {
--                 dict = "amb@world_human_push_ups@male@base",
--                 clip = "base",
--                 time = 1000
--             },
--             idle = {
--                 dict = "amb@world_human_push_ups@male@idle_a",
--                 clip = "idle_c",
--             },
--             exit = {
--                 dict = "amb@world_human_push_ups@male@exit",
--                 clip = "exit",
--             }
--         },
--         command = 'pushup'
--     }
-- }

return animation