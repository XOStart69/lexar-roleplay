return {
    {
        name = 'El Burro Heights',
        areaCoords = vec(1539.5895, -2092.1470, 77.0830), --- Coords untuk blip route
        insertpipe = {
            {
                pipes = {
                    { object = 'veo_pipes_d', coords = vec3(1517.043, -2059.834, 76.735), rotation = vec3(90.000, 0.000, 0.000) },
                    { object = 'veo_pipes_e', coords = vec3(1517.095, -2059.927, 77.463), rotation = vec3(-29.409, 90.000, 0.000) },
                    { object = 'veo_pipes_d', coords = vec3(1517.445, -2060.549, 77.569), rotation = vec3(0.000, 0.000, 30.000) },
                    { object = 'veo_pipes_d', coords = vec3(1517.974, -2061.454, 77.569), rotation = vec3(0.000, 0.000, 30.000) },
                    { object = 'veo_pipes_d', coords = vec3(1518.490, -2062.350, 77.569), rotation = vec3(0.000, 0.000, 30.000) },
                    { object = 'veo_pipes_d', coords = vec3(1519.013, -2063.240, 77.569), rotation = vec3(0.000, 0.000, 30.000) },
                    { object = 'veo_pipes_f', coords = vec3(1519.171, -2064.319, 77.569), rotation = vec3(0.000, 0.000, -150.000) },
                    { object = 'veo_pipes_c', coords = vec3(1518.608, -2064.772, 76.496), rotation = vec3(90.000, 0.000, 0.000) },
                    { object = 'veo_pipes_p', coords = vec3(1518.604, -2064.766, 77.568), rotation = vec3(-180.000, 0.000, -60.763) },
                    { object = 'veo_pipes_c', coords = vec3(1517.270, -2065.532, 77.562), rotation = vec3(0.000, 0.000, -60.000) },
                    { object = 'veo_pipes_c', coords = vec3(1515.515, -2066.549, 77.562), rotation = vec3(0.000, 0.000, -60.000) },
                    { object = 'veo_pipes_c', coords = vec3(1514.189, -2067.321, 76.496), rotation = vec3(90.000, 0.000, 0.000) },
                    { object = 'veo_pipes_p', coords = vec3(1514.180, -2067.319, 77.562), rotation = vec3(-180.000, 0.000, -60.000) },
                    { object = 'veo_pipes_c', coords = vec3(1512.871, -2068.075, 77.562), rotation = vec3(0.000, 0.000, -60.000) },
                    { object = 'veo_pipes_c', coords = vec3(1511.393, -2068.931, 77.562), rotation = vec3(0.000, 0.000, -60.000) },
                },
                valve = { coords = vec3(1517.052, -2059.803, 76.924), heading = -150.0, openPercent = false },
            },
        },

        repairpipe = {
            {
                pipes = {
                    { object = 'veo_pipes_c', coords = vec3(1522.174, -2175.854, 76.518), rotation = vec3(90.017, 0.000, 0.000) },
                    { object = 'veo_pipes_e', coords = vec3(1522.094, -2175.784, 77.747), rotation = vec3(131.978, 90.000, 0.000) },
                    { object = 'veo_pipes_c', coords = vec3(1521.159, -2174.992, 77.859), rotation = vec3(0.000, 0.000, 50.000) },
                    { object = 'veo_pipes_d', coords = vec3(1519.985, -2174.012, 77.859), rotation = vec3(0.000, 0.000, 50.000) },
                    { object = 'veo_pipes_d', coords = vec3(1519.195, -2173.354, 77.859), rotation = vec3(0.000, 0.000, 50.000) },
                    { object = 'veo_pipes_d', coords = vec3(1518.405, -2172.696, 77.859), rotation = vec3(0.000, 0.000, 50.000) },
                    { object = 'veo_pipes_c', coords = vec3(1517.230, -2171.708, 77.859), rotation = vec3(0.000, 0.000, 50.000) },
                },
                valve = { coords = vec3(1522.136, -2175.890, 77.668), heading = -42.5, openPercent = true },
            },
        },

        toilet = {
            {
                object = 'toilet2',
                coords = vec3(1623.06, -2356.61, 92.32),
                heading = 200.0,
                shitProps = {
                    { prop = 'prop_big_shit_01', type = 'shit' },
                    { prop = 'prop_big_shit_01', type = 'shit' },
                },
                waterProp = { prop = 'suing', type = 'water' },
                plungerOffset = vec3(0.0, 0.16, 0.55),
            },
            {
                object = 'toilet2',
                coords = vec3(1525.35, -2148.09, 76.37),
                heading = 0.0,
                shitProps = {
                    { prop = 'prop_big_shit_01', type = 'shit' },
                    { prop = 'prop_big_shit_01', type = 'shit' },
                },
                waterProp = { prop = 'suing', type = 'water' },
                plungerOffset = vec3(0.0, 0.16, 0.55),
            },
        },

        openvalve = {
            {
                pipe  = { object = 'veo_pipes_r',       coords = vec3(1557.455, -2110.802, 76.403), rotation = vec3(0.000, 0.000, 95.781) },
                valve = { object = 'prop_oil_valve_01', coords = vec3(1557.308, -2110.795, 76.774), rotation = vec3(0.000, 0.000, -85.789), heading = -85.789 },
            },
            {
                pipe  = { object = 'veo_pipes_r',       coords = vec3(1558.671, -2102.063, 80.888), rotation = vec3(0.000, 0.000, -74.078) },
                valve = { object = 'prop_oil_valve_01', coords = vec3(1558.855, -2102.052, 81.250), rotation = vec3(0.000, 0.000, 114.198), heading = 114.198 },
            },
        },

        fixswitch = {
            { object = 'tt_h4_int_sub_switches', coords = vec3(1621.882, -1880.994, 105.326), rotation = vec3(81.148, -3.352, 73.057) },
            { object = 'tt_h4_int_sub_switches', coords = vec3(1624.853, -1957.568, 104.717), rotation = vec3(-89.526, -1.158, 76.582) },
            { object = 'tt_h4_int_sub_switches', coords = vec3(1572.768, -1856.179, 93.937),  rotation = vec3(-85.671, -0.585, -0.661) },
        },
    },

    {
        name = 'Alta Building',
        areaCoords = vec(118.5920, -417.4317, 41.0604), --- Coords untuk blip route

        insertpipe = {
            {
                pipes = {
                    { object = 'veo_pipes_d', coords = vec3(71.863, -411.347, 36.382), rotation = vec3(90.000, 0.000, 0.000) },
                    { object = 'veo_pipes_e', coords = vec3(71.833, -411.432, 37.100), rotation = vec3(21.000, 90.000, 1.000) },
                    { object = 'veo_pipes_d', coords = vec3(71.571, -412.112, 37.195), rotation = vec3(0.000, 0.000, -21.000) },
                    { object = 'veo_pipes_c', coords = vec3(71.020, -413.545, 37.195), rotation = vec3(0.000, 0.000, -21.000) },
                    { object = 'veo_pipes_d', coords = vec3(70.473, -414.990, 36.459), rotation = vec3(90.000, 0.000, 0.000) },
                    { object = 'veo_pipes_p', coords = vec3(70.470, -414.987, 37.195), rotation = vec3(-180.000, 0.000, -21.000) },
                    { object = 'veo_pipes_c', coords = vec3(69.924, -416.413, 37.188), rotation = vec3(0.000, 0.000, -21.000) },
                    { object = 'veo_pipes_f', coords = vec3(69.394, -417.497, 37.195), rotation = vec3(-180.000, 0.000, 69.000) },
                    { object = 'veo_pipes_e', coords = vec3(68.101, -417.550, 37.195), rotation = vec3(0.000, 0.000, -20.000) },
                    { object = 'veo_pipes_c', coords = vec3(67.580, -418.663, 37.195), rotation = vec3(0.000, 0.000, -21.000) },
                    { object = 'veo_pipes_d', coords = vec3(67.030, -420.090, 37.195), rotation = vec3(0.000, 0.000, -21.000) },
                    { object = 'veo_pipes_e', coords = vec3(66.684, -420.737, 37.195), rotation = vec3(0.000, 0.000, 160.000) },
                    { object = 'veo_pipes_d', coords = vec3(65.953, -420.580, 36.445), rotation = vec3(90.000, 0.000, 0.000) },
                    { object = 'veo_pipes_p', coords = vec3(65.966, -420.586, 37.195), rotation = vec3(180.000, 0.000, 70.000) },
                    { object = 'veo_pipes_c', coords = vec3(64.528, -420.062, 37.186), rotation = vec3(0.000, 0.000, 69.982) },
                },
                valve = { coords = vec3(71.889, -411.322, 36.939), heading = 160.0, openPercent = false },
            },
        },

        repairpipe = {
            {
                pipes = {
                    { object = 'veo_pipes_c', coords = vec3(56.752, -332.768, 54.151), rotation = vec3(90.017, 0.000, 0.000) },
                    { object = 'veo_pipes_e', coords = vec3(56.794, -332.682, 55.214), rotation = vec3(90.000, 0.000, 67.329) },
                    { object = 'veo_pipes_d', coords = vec3(57.045, -332.016, 55.320), rotation = vec3(0.000, 0.000, -18.825) },
                    { object = 'veo_pipes_d', coords = vec3(57.376, -331.057, 55.320), rotation = vec3(0.000, 0.000, -18.825) },
                    { object = 'veo_pipes_d', coords = vec3(57.718, -330.092, 55.320), rotation = vec3(0.000, 0.000, -18.825) },
                    { object = 'veo_pipes_d', coords = vec3(58.048, -329.129, 55.320), rotation = vec3(0.000, 0.000, -18.825) },
                    { object = 'veo_pipes_d', coords = vec3(58.383, -328.174, 55.320), rotation = vec3(0.000, 0.000, -20.753) },
                    { object = 'veo_pipes_d', coords = vec3(58.749, -327.197, 55.320), rotation = vec3(0.000, 0.000, -19.770) },
                    { object = 'veo_pipes_e', coords = vec3(59.010, -326.501, 55.266), rotation = vec3(19.690, 90.000, 0.000) },
                    { object = 'veo_pipes_c', coords = vec3(59.038, -326.413, 54.050), rotation = vec3(90.000, 0.000, 0.000) },
                },
                valve = { coords = vec3(56.807, -332.808, 54.801), heading = 79.0, openPercent = true },
            },
        },

        toilet = {
            {
                object = 'toilet2',
                coords = vec3(31.428, -374.476, 44.572),
                heading = 0.0,
                shitProps = {
                    { prop = 'prop_big_shit_01', type = 'shit' },
                    { prop = 'prop_big_shit_01', type = 'shit' },
                },
                waterProp = { prop = 'suing', type = 'water' },
                plungerOffset = vec3(0.0, 0.16, 0.55),
            },
            {
                object = 'toilet2',
                coords = vec3(117.49, -348.09, 54.5),
                heading = 10.28,
                shitProps = {
                    { prop = 'prop_big_shit_01', type = 'shit' },
                    { prop = 'prop_big_shit_01', type = 'shit' },
                },
                waterProp = { prop = 'suing', type = 'water' },
                plungerOffset = vec3(0.0, 0.16, 0.55),
            },
        },

        openvalve = {
            {
                pipe  = { object = 'veo_pipes_r',       coords = vec3(33.225, -432.388, 44.629), rotation = vec3(0.000, 0.000, 159.836) },
                valve = { object = 'prop_oil_valve_01', coords = vec3(33.149, -432.523, 44.850), rotation = vec3(0.000, 0.000, -19.175), heading = -19.175 },
            },
            {
                pipe  = { object = 'veo_pipes_r',       coords = vec3(38.817, -399.504, 44.561), rotation = vec3(0.000, 0.000, -21.926) },
                valve = { object = 'prop_oil_valve_01', coords = vec3(38.906, -399.369, 44.800), rotation = vec3(0.000, 0.000, 158.341), heading = 158.341 },
            },
        },

        fixswitch = {
            { object = 'tt_h4_int_sub_switches', coords = vec3(63.086, -421.031, 37.394), rotation = vec3(13.695, 90.000, 0.000) },
            { object = 'tt_h4_int_sub_switches', coords = vec3(61.075, -426.743, 37.636), rotation = vec3(-180.000, 90.000, 166.305) },
        },
    },

    -- {
    --     name = 'Paleto Bay',
    --     areaCoords = vec(102.7568, 6563.0850, 31.4726), --- Coords untuk blip route

    --     insertpipe = {
    --         {
    --             pipes = {
    --                 { object = 'veo_pipes_d', coords = vec3(71.521, 6564.706, 27.517), rotation = vec3(90.000, 0.000, 0.000) },
    --                 { object = 'veo_pipes_e', coords = vec3(71.446, 6564.774, 28.248), rotation = vec3(131.502, 90.000, 0.000) },
    --                 { object = 'veo_pipes_c', coords = vec3(70.572, 6565.643, 28.351), rotation = vec3(0.000, 0.000, 44.375) },
    --                 { object = 'veo_pipes_d', coords = vec3(69.494, 6566.763, 28.352), rotation = vec3(0.000, 0.000, 42.324) },
    --                 { object = 'veo_pipes_d', coords = vec3(68.790, 6567.547, 27.610), rotation = vec3(90.000, 0.000, 0.000) },
    --                 { object = 'veo_pipes_p', coords = vec3(68.780, 6567.524, 28.355), rotation = vec3(178.643, -1.292, 43.904) },
    --                 { object = 'veo_pipes_c', coords = vec3(67.696, 6568.630, 28.322), rotation = vec3(0.000, 0.000, 45.000) },
    --                 { object = 'veo_pipes_d', coords = vec3(66.617, 6569.711, 28.321), rotation = vec3(0.000, 0.000, 45.000) },
    --                 { object = 'veo_pipes_d', coords = vec3(65.871, 6570.408, 28.341), rotation = vec3(0.000, 0.000, 45.000) },
    --                 { object = 'veo_pipes_d', coords = vec3(65.134, 6571.150, 27.610), rotation = vec3(90.000, 0.000, 45.000) },
    --                 { object = 'veo_pipes_p', coords = vec3(65.138, 6571.151, 28.355), rotation = vec3(180.000, 0.000, 45.000) },
    --                 { object = 'veo_pipes_d', coords = vec3(64.400, 6571.887, 28.337), rotation = vec3(0.000, 0.000, 45.000) },
    --                 { object = 'veo_pipes_d', coords = vec3(63.661, 6572.632, 28.332), rotation = vec3(0.000, 0.000, 45.000) },
    --                 { object = 'veo_pipes_f', coords = vec3(63.073, 6573.083, 28.336), rotation = vec3(0.000, 0.000, -45.000) },
    --                 { object = 'veo_pipes_d', coords = vec3(61.702, 6572.287, 28.335), rotation = vec3(0.000, 0.000, -45.000) },
    --                 { object = 'veo_pipes_d', coords = vec3(60.954, 6571.549, 28.326), rotation = vec3(0.000, 0.000, -45.000) },
    --                 { object = 'veo_pipes_e', coords = vec3(60.523, 6570.967, 28.346), rotation = vec3(0.000, 0.000, 45.000) },
    --                 { object = 'veo_pipes_d', coords = vec3(60.964, 6570.382, 27.616), rotation = vec3(90.000, 0.000, 0.000) },
    --                 { object = 'veo_pipes_p', coords = vec3(60.964, 6570.379, 28.344), rotation = vec3(-180.000, 0.000, 45.000) },
    --                 { object = 'veo_pipes_c', coords = vec3(62.042, 6569.303, 28.330), rotation = vec3(0.000, 0.000, 45.000) },
    --                 { object = 'veo_pipes_e', coords = vec3(62.917, 6568.433, 28.220), rotation = vec3(86.114, -1.537, 133.219) },
    --                 { object = 'veo_pipes_d', coords = vec3(63.037, 6568.418, 27.515), rotation = vec3(95.000, 0.000, -45.000) },
    --             },
    --             valve = { coords = vec3(71.544, 6564.690, 28.049), heading = 47.0, openPercent = false },
    --         },
    --     },

    --     repairpipe = {
    --         {
    --             pipes = {
    --                 { object = 'veo_pipes_c', coords = vec3(93.038, 6538.462, 30.252), rotation = vec3(90.017, 0.000, 0.000) },
    --                 { object = 'veo_pipes_e', coords = vec3(93.117, 6538.542, 31.462), rotation = vec3(-134.577, 90.000, 0.000) },
    --                 { object = 'veo_pipes_d', coords = vec3(93.633, 6539.061, 31.557), rotation = vec3(0.000, 0.000, -45.000) },
    --                 { object = 'veo_pipes_d', coords = vec3(94.366, 6539.797, 31.557), rotation = vec3(0.000, 0.000, -45.000) },
    --                 { object = 'veo_pipes_d', coords = vec3(95.096, 6540.538, 31.557), rotation = vec3(0.000, 0.000, -45.000) },
    --                 { object = 'veo_pipes_d', coords = vec3(95.829, 6541.274, 31.557), rotation = vec3(0.000, 0.000, -45.000) },
    --                 { object = 'veo_pipes_d', coords = vec3(96.562, 6542.010, 31.557), rotation = vec3(0.000, 0.000, -45.000) },
    --                 { object = 'veo_pipes_d', coords = vec3(97.295, 6542.729, 31.557), rotation = vec3(0.000, 0.000, -45.000) },
    --                 { object = 'veo_pipes_d', coords = vec3(98.028, 6543.465, 31.557), rotation = vec3(0.000, 0.000, -45.000) },
    --                 { object = 'veo_pipes_d', coords = vec3(98.761, 6544.201, 31.557), rotation = vec3(0.000, 0.000, -45.000) },
    --                 { object = 'veo_pipes_d', coords = vec3(99.487, 6544.955, 30.833), rotation = vec3(90.000, 0.000, 0.000) },
    --                 { object = 'veo_pipes_p', coords = vec3(99.491, 6544.943, 31.557), rotation = vec3(-180.000, 0.000, -45.000) },
    --                 { object = 'veo_pipes_d', coords = vec3(100.226, 6545.674, 31.557), rotation = vec3(0.000, 0.000, -45.000) },
    --                 { object = 'veo_pipes_d', coords = vec3(100.944, 6546.389, 31.557), rotation = vec3(0.000, 0.000, -45.000) },
    --                 { object = 'veo_pipes_d', coords = vec3(101.678, 6547.125, 31.557), rotation = vec3(0.000, 0.000, -45.000) },
    --                 { object = 'veo_pipes_d', coords = vec3(102.411, 6547.861, 31.557), rotation = vec3(0.000, 0.000, -45.000) },
    --                 { object = 'veo_pipes_d', coords = vec3(103.144, 6548.597, 31.557), rotation = vec3(0.000, 0.000, -45.000) },
    --                 { object = 'veo_pipes_e', coords = vec3(103.673, 6549.103, 31.459), rotation = vec3(45.000, 90.000, 0.000) },
    --                 { object = 'veo_pipes_c', coords = vec3(103.743, 6549.174, 30.231), rotation = vec3(90.000, 0.000, 0.000) },
    --             },
    --             valve = { coords = vec3(93.063, 6538.440, 31.121), heading = 46.0, openPercent = true },
    --         },
    --     },

    --     toilet = {
    --         {
    --             object = 'toilet2',
    --             coords = vec3(38.6, 6544.15, 30.71),
    --             heading = 0.0,
    --             shitProps = {
    --                 { prop = 'prop_big_shit_01', type = 'shit' },
    --                 { prop = 'prop_big_shit_01', type = 'shit' },
    --             },
    --             waterProp = { prop = 'suing', type = 'water' },
    --             plungerOffset = vec3(0.0, 0.16, 0.55),
    --         },
    --         {
    --             object = 'toilet2',
    --             coords = vec3(88.26, 6494.02, 30.37),
    --             heading = 0.0,
    --             shitProps = {
    --                 { prop = 'prop_big_shit_01', type = 'shit' },
    --                 { prop = 'prop_big_shit_01', type = 'shit' },
    --             },
    --             waterProp = { prop = 'suing', type = 'water' },
    --             plungerOffset = vec3(0.0, 0.16, 0.55),
    --         },
    --         {
    --             object = 'toilet2',
    --             coords = vec3(151.05, 6455.24, 30.45),
    --             heading = 0.0,
    --             shitProps = {
    --                 { prop = 'prop_big_shit_01', type = 'shit' },
    --                 { prop = 'prop_big_shit_01', type = 'shit' },
    --             },
    --             waterProp = { prop = 'suing', type = 'water' },
    --             plungerOffset = vec3(0.0, 0.16, 0.55),
    --         },
    --         {
    --             object = 'toilet2',
    --             coords = vec3(114.3, 6417.64, 30.42),
    --             heading = 0.0,
    --             shitProps = {
    --                 { prop = 'prop_big_shit_01', type = 'shit' },
    --                 { prop = 'prop_big_shit_01', type = 'shit' },
    --             },
    --             waterProp = { prop = 'suing', type = 'water' },
    --             plungerOffset = vec3(0.0, 0.16, 0.55),
    --         },
    --         {
    --             object = 'toilet2',
    --             coords = vec3(-60.38, 6283.51, 30.42),
    --             heading = 0.0,
    --             shitProps = {
    --                 { prop = 'prop_big_shit_01', type = 'shit' },
    --                 { prop = 'prop_big_shit_01', type = 'shit' },
    --             },
    --             waterProp = { prop = 'suing', type = 'water' },
    --             plungerOffset = vec3(0.0, 0.16, 0.55),
    --         },
    --         {
    --             object = 'toilet2',
    --             coords = vec3(145.34, 6563.58, 31.1),
    --             heading = 0.0,
    --             shitProps = {
    --                 { prop = 'prop_big_shit_01', type = 'shit' },
    --                 { prop = 'prop_big_shit_01', type = 'shit' },
    --             },
    --             waterProp = { prop = 'suing', type = 'water' },
    --             plungerOffset = vec3(0.0, 0.16, 0.55),
    --         },
    --     },

    --     openvalve = {
    --         {
    --             pipe  = { object = 'veo_pipes_r',       coords = vec3(19.204, 6527.832, 30.400), rotation = vec3(0.000, 0.000, -43.540) },
    --             valve = { object = 'prop_oil_valve_01', coords = vec3(19.365, 6527.942, 30.751), rotation = vec3(0.000, 0.000, 133.438), heading = 133.0 },
    --         },
    --         {
    --             pipe  = { object = 'veo_pipes_r',       coords = vec3(-12.965, 6438.271, 30.782), rotation = vec3(0.000, 0.000, -141.042) },
    --             valve = { object = 'prop_oil_valve_01', coords = vec3(-12.845, 6438.122, 31.130), rotation = vec3(0.000, 0.000, 39.471), heading = 39.471 },
    --         },
    --         {
    --             pipe  = { object = 'veo_pipes_r',       coords = vec3(130.860, 6438.735, 30.694), rotation = vec3(0.000, 0.000, -41.041) },
    --             valve = { object = 'prop_oil_valve_01', coords = vec3(131.042, 6438.813, 31.016), rotation = vec3(0.000, 0.000, 148.185), heading = 148.185 },
    --         },
    --         {
    --             pipe  = { object = 'veo_pipes_r',       coords = vec3(-172.188, 6409.748, 30.982), rotation = vec3(0.000, 0.000, 41.561) },
    --             valve = { object = 'prop_oil_valve_01', coords = vec3(-172.248, 6409.880, 31.339), rotation = vec3(0.000, 0.000, -135.467), heading = -135.467 },
    --         },
    --     },

    --     fixswitch = {
    --         { object = 'tt_h4_int_sub_switches', coords = vec3(37.763, 6546.467, 32.758), rotation = vec3(0.000, 89.881, 43.511) },
    --         { object = 'tt_h4_int_sub_switches', coords = vec3(-27.238, 6596.131, 32.722), rotation = vec3(0.000, 89.881, 125.537) },
    --         { object = 'tt_h4_int_sub_switches', coords = vec3(-94.546, 6512.178, 33.041), rotation = vec3(0.000, 89.885, 52.311) },
    --         { object = 'tt_h4_int_sub_switches', coords = vec3(109.025, 6369.057, 32.613), rotation = vec3(0.000, 89.885, 128.822) },
    --     },
    -- },

    -- {
    --     name = 'Grapeseed',
    --     areaCoords = vec(831.1021, 2408.1497, 54.3275), --- Coords untuk blip route

    --     insertpipe = {
    --         {
    --             pipes = {
    --                 { object = 'veo_pipes_d', coords = vec3(1027.700, 2292.594, 43.711), rotation = vec3(90.000, 0.000, 0.000) },
    --                 { object = 'veo_pipes_e', coords = vec3(1027.799, 2292.591, 44.438), rotation = vec3(90.000, 0.000, 0.000) },
    --                 { object = 'veo_pipes_d', coords = vec3(1028.534, 2292.591, 44.537), rotation = vec3(0.000, 0.000, 90.000) },
    --                 { object = 'veo_pipes_c', coords = vec3(1030.049, 2292.590, 44.537), rotation = vec3(0.000, 0.000, 90.000) },
    --                 { object = 'veo_pipes_c', coords = vec3(1032.066, 2292.589, 44.537), rotation = vec3(0.000, 0.000, 90.000) },
    --                 { object = 'veo_pipes_d', coords = vec3(1033.600, 2292.589, 43.811), rotation = vec3(90.000, 0.000, 0.000) },
    --                 { object = 'veo_pipes_p', coords = vec3(1033.594, 2292.589, 44.537), rotation = vec3(-180.000, 0.000, 90.000) },
    --                 { object = 'veo_pipes_d', coords = vec3(1034.635, 2292.589, 44.537), rotation = vec3(0.000, 0.000, 90.000) },
    --                 { object = 'veo_pipes_c', coords = vec3(1036.150, 2292.589, 44.537), rotation = vec3(0.000, 0.000, 90.000) },
    --                 { object = 'veo_pipes_c', coords = vec3(1038.164, 2292.589, 44.537), rotation = vec3(0.000, 0.000, 90.000) },
    --                 { object = 'veo_pipes_d', coords = vec3(1039.696, 2292.596, 43.811), rotation = vec3(90.000, 0.000, 0.000) },
    --                 { object = 'veo_pipes_p', coords = vec3(1039.706, 2292.589, 44.537), rotation = vec3(-180.000, 0.000, 90.000) },
    --                 { object = 'veo_pipes_d', coords = vec3(1040.736, 2292.589, 44.537), rotation = vec3(0.000, 0.000, 90.000) },
    --                 { object = 'veo_pipes_c', coords = vec3(1042.251, 2292.589, 44.537), rotation = vec3(0.000, 0.000, 90.000) },
    --                 { object = 'veo_pipes_c', coords = vec3(1044.279, 2292.589, 44.537), rotation = vec3(0.000, 0.000, 90.000) },
    --                 { object = 'veo_pipes_d', coords = vec3(1045.799, 2292.589, 43.811), rotation = vec3(90.000, 0.000, 0.000) },
    --                 { object = 'veo_pipes_p', coords = vec3(1045.795, 2292.589, 44.540), rotation = vec3(-180.000, 0.000, 90.000) },
    --                 { object = 'veo_pipes_d', coords = vec3(1046.824, 2292.589, 44.537), rotation = vec3(0.000, 0.000, 90.000) },
    --                 { object = 'veo_pipes_c', coords = vec3(1048.360, 2292.589, 44.537), rotation = vec3(0.000, 0.000, 90.000) },
    --                 { object = 'veo_pipes_c', coords = vec3(1050.364, 2292.589, 44.537), rotation = vec3(0.000, 0.000, 90.000) },
    --                 { object = 'veo_pipes_f', coords = vec3(1052.389, 2292.984, 44.527), rotation = vec3(-180.000, 0.000, 90.000) },
    --                 { object = 'veo_pipes_d', coords = vec3(1052.507, 2293.694, 44.515), rotation = vec3(0.000, 0.000, 0.000) },
    --                 { object = 'veo_pipes_c', coords = vec3(1052.507, 2295.213, 44.515), rotation = vec3(0.000, 0.000, 0.000) },
    --                 { object = 'veo_pipes_d', coords = vec3(1052.507, 2296.737, 43.803), rotation = vec3(90.000, 0.000, 0.000) },
    --                 { object = 'veo_pipes_p', coords = vec3(1052.507, 2296.737, 44.515), rotation = vec3(-180.000, 0.000, 0.000) },
    --                 { object = 'veo_pipes_d', coords = vec3(1052.507, 2297.748, 44.515), rotation = vec3(0.000, 0.000, 0.000) },
    --                 { object = 'veo_pipes_c', coords = vec3(1052.507, 2299.269, 44.515), rotation = vec3(0.000, 0.000, 0.000) },
    --                 { object = 'veo_pipes_c', coords = vec3(1052.507, 2301.308, 44.515), rotation = vec3(0.000, 0.000, 0.000) },
    --                 { object = 'veo_pipes_c', coords = vec3(1052.507, 2303.347, 44.515), rotation = vec3(0.000, 0.000, 0.000) },
    --                 { object = 'veo_pipes_e', coords = vec3(1052.489, 2304.576, 44.421), rotation = vec3(0.000, 89.805, 0.000) },
    --                 { object = 'veo_pipes_d', coords = vec3(1052.507, 2304.668, 43.702), rotation = vec3(90.000, 0.000, 0.000) },
    --             },
    --             valve = { coords = vec3(1027.705, 2292.635, 44.084), heading = 180.0, openPercent = false },
    --         },
    --     },

    --     repairpipe = {
    --         {
    --             pipes = {
    --                 { object = 'veo_pipes_c', coords = vec3(1133.245, 2103.437, 54.340), rotation = vec3(90.017, 0.000, 0.000) },
    --                 { object = 'veo_pipes_e', coords = vec3(1133.255, 2103.336, 55.574), rotation = vec3(0.000, 90.000, 0.000) },
    --                 { object = 'veo_pipes_d', coords = vec3(1133.251, 2102.605, 55.679), rotation = vec3(0.000, 0.000, 0.000) },
    --                 { object = 'veo_pipes_d', coords = vec3(1133.251, 2101.581, 55.679), rotation = vec3(0.000, 0.000, 0.000) },
    --                 { object = 'veo_pipes_d', coords = vec3(1133.251, 2100.536, 55.679), rotation = vec3(0.000, 0.000, 0.000) },
    --                 { object = 'veo_pipes_d', coords = vec3(1133.251, 2099.491, 55.679), rotation = vec3(0.000, 0.000, 0.000) },
    --                 { object = 'veo_pipes_d', coords = vec3(1133.251, 2098.446, 55.679), rotation = vec3(0.000, 0.000, 0.000) },
    --                 { object = 'veo_pipes_d', coords = vec3(1133.251, 2097.401, 55.679), rotation = vec3(0.000, 0.000, 0.000) },
    --                 { object = 'veo_pipes_d', coords = vec3(1133.251, 2096.356, 55.679), rotation = vec3(0.000, 0.000, 0.000) },
    --                 { object = 'veo_pipes_d', coords = vec3(1133.251, 2095.311, 55.679), rotation = vec3(0.000, 0.000, 0.000) },
    --                 { object = 'veo_pipes_d', coords = vec3(1133.251, 2094.266, 55.679), rotation = vec3(0.000, 0.000, 0.000) },
    --                 { object = 'veo_pipes_d', coords = vec3(1133.251, 2093.221, 55.679), rotation = vec3(0.000, 0.000, 0.000) },
    --                 { object = 'veo_pipes_d', coords = vec3(1133.251, 2092.176, 55.679), rotation = vec3(0.000, 0.000, 0.000) },
    --                 { object = 'veo_pipes_d', coords = vec3(1133.251, 2091.131, 55.679), rotation = vec3(0.000, 0.000, 0.000) },
    --                 { object = 'veo_pipes_d', coords = vec3(1133.251, 2090.086, 55.679), rotation = vec3(0.000, 0.000, 0.000) },
    --                 { object = 'veo_pipes_d', coords = vec3(1133.251, 2089.041, 55.679), rotation = vec3(0.000, 0.000, 0.000) },
    --                 { object = 'veo_pipes_e', coords = vec3(1133.253, 2088.314, 55.575), rotation = vec3(-180.000, 90.000, 0.000) },
    --                 { object = 'veo_pipes_c', coords = vec3(1133.239, 2088.211, 54.356), rotation = vec3(90.000, 0.000, 0.000) },
    --             },
    --             valve = { coords = vec3(1133.274, 2103.456, 55.188), heading = -180.0, openPercent = true },
    --         },
    --     },

    --     toilet = {
    --         {
    --             object = 'toilet2',
    --             coords = vec3(1123.97, 2205.13, 48.6),
    --             heading = 0.0,
    --             shitProps = {
    --                 { prop = 'prop_big_shit_01', type = 'shit' },
    --                 { prop = 'prop_big_shit_01', type = 'shit' },
    --             },
    --             waterProp = { prop = 'suing', type = 'water' },
    --             plungerOffset = vec3(0.0, 0.16, 0.55),
    --         },
    --         {
    --             object = 'toilet2',
    --             coords = vec3(1045.67, 2467.99, 48.1),
    --             heading = 0.0,
    --             shitProps = {
    --                 { prop = 'prop_big_shit_01', type = 'shit' },
    --                 { prop = 'prop_big_shit_01', type = 'shit' },
    --             },
    --             waterProp = { prop = 'suing', type = 'water' },
    --             plungerOffset = vec3(0.0, 0.16, 0.55),
    --         },
    --         {
    --             object = 'toilet2',
    --             coords = vec3(1018.01, 2489.37, 48.25),
    --             heading = 0.0,
    --             shitProps = {
    --                 { prop = 'prop_big_shit_01', type = 'shit' },
    --                 { prop = 'prop_big_shit_01', type = 'shit' },
    --             },
    --             waterProp = { prop = 'suing', type = 'water' },
    --             plungerOffset = vec3(0.0, 0.16, 0.55),
    --         },
    --         {
    --             object = 'toilet2',
    --             coords = vec3(1210.86, 2393.54, 64.81),
    --             heading = 0.0,
    --             shitProps = {
    --                 { prop = 'prop_big_shit_01', type = 'shit' },
    --                 { prop = 'prop_big_shit_01', type = 'shit' },
    --             },
    --             waterProp = { prop = 'suing', type = 'water' },
    --             plungerOffset = vec3(0.0, 0.16, 0.55),
    --         },
    --         {
    --             object = 'toilet2',
    --             coords = vec3(1123.46, 2115.53, 54.46),
    --             heading = 0.0,
    --             shitProps = {
    --                 { prop = 'prop_big_shit_01', type = 'shit' },
    --                 { prop = 'prop_big_shit_01', type = 'shit' },
    --             },
    --             waterProp = { prop = 'suing', type = 'water' },
    --             plungerOffset = vec3(0.0, 0.16, 0.55),
    --         },
    --         {
    --             object = 'toilet2',
    --             coords = vec3(828.18, 2356.62, 51.25),
    --             heading = 0.0,
    --             shitProps = {
    --                 { prop = 'prop_big_shit_01', type = 'shit' },
    --                 { prop = 'prop_big_shit_01', type = 'shit' },
    --             },
    --             waterProp = { prop = 'suing', type = 'water' },
    --             plungerOffset = vec3(0.0, 0.16, 0.55),
    --         },
    --     },

    --     openvalve = {
    --         {
    --             pipe  = { object = 'veo_pipes_r',       coords = vec3(1067.282, 2310.921, 44.579), rotation = vec3(0.000, 0.000, 0.000) },
    --             valve = { object = 'prop_oil_valve_01', coords = vec3(1067.333, 2311.062, 44.911), rotation = vec3(0.000, 0.000, -179.472), heading = -179.472 },
    --         },
    --         {
    --             pipe  = { object = 'veo_pipes_r',       coords = vec3(955.400, 2298.154, 46.116), rotation = vec3(0.000, 0.000, 0.000) },
    --             valve = { object = 'prop_oil_valve_01', coords = vec3(955.423, 2298.287, 46.469), rotation = vec3(-4.790, 0.493, -179.296), heading = -179.296 },
    --         },
    --         {
    --             pipe  = { object = 'veo_pipes_r',       coords = vec3(1133.660, 2177.890, 48.049), rotation = vec3(-0.060, -5.133, 0.003) },
    --             valve = { object = 'prop_oil_valve_01', coords = vec3(1133.655, 2178.005, 48.395), rotation = vec3(1.495, 5.666, -179.220), heading = -179.220 },
    --         },
    --         {
    --             pipe  = { object = 'veo_pipes_r',       coords = vec3(1001.610, 2352.427, 50.466), rotation = vec3(0.000, 0.000, -178.229) },
    --             valve = { object = 'prop_oil_valve_01', coords = vec3(1001.587, 2352.232, 50.800), rotation = vec3(0.000, 0.000, -1.909), heading = -1.909 },
    --         },
    --         {
    --             pipe  = { object = 'veo_pipes_r',       coords = vec3(1040.740, 2493.589, 48.699), rotation = vec3(0.000, 0.000, -178.229) },
    --             valve = { object = 'prop_oil_valve_01', coords = vec3(1040.711, 2493.454, 49.012), rotation = vec3(0.000, 0.000, -178.229), heading = -178.229 },
    --         },
    --     },

    --     fixswitch = {
    --         { object = 'tt_h4_int_sub_switches', coords = vec3(827.231, 2368.783, 53.391), rotation = vec3(-79.982, 0.000, -5.016) },
    --         { object = 'tt_h4_int_sub_switches', coords = vec3(850.303, 2419.531, 55.682), rotation = vec3(-84.485, -0.825, 89.638) },
    --         { object = 'tt_h4_int_sub_switches', coords = vec3(826.413, 2184.107, 53.363), rotation = vec3(90.815, -0.588, -25.055) },
    --         { object = 'tt_h4_int_sub_switches', coords = vec3(858.004, 2128.863, 53.249), rotation = vec3(90.030, 0.515, 93.325) },
    --         { object = 'tt_h4_int_sub_switches', coords = vec3(847.787, 2382.682, 55.105), rotation = vec3(86.650, -0.657, 49.967) },
    --     },
    -- },

    -- {
    --     name = 'Vinewood Hills',
    --     areaCoords = vec(-921.9144, 383.6047, 79.3266), --- Coords untuk blip route

    --     insertpipe = {
    --         {
    --             pipes = {
    --                 { object = 'veo_pipes_d', coords = vec3(-936.542, 398.216, 77.007), rotation = vec3(90.000, 0.000, 0.000) },
    --                 { object = 'veo_pipes_e', coords = vec3(-936.570, 398.316, 77.734), rotation = vec3(90.000, 0.000, 111.956) },
    --                 { object = 'veo_pipes_d', coords = vec3(-936.833, 398.995, 77.824), rotation = vec3(0.000, 0.000, 22.053) },
    --                 { object = 'veo_pipes_d', coords = vec3(-937.220, 399.938, 77.840), rotation = vec3(0.000, 0.000, 22.053) },
    --                 { object = 'veo_pipes_d', coords = vec3(-937.586, 400.900, 77.840), rotation = vec3(0.000, 0.000, 22.053) },
    --                 { object = 'veo_pipes_d', coords = vec3(-937.974, 401.862, 77.840), rotation = vec3(0.000, 0.000, 22.053) },
    --                 { object = 'veo_pipes_e', coords = vec3(-938.252, 402.527, 77.744), rotation = vec3(-21.941, 90.000, 0.000) },
    --                 { object = 'veo_pipes_d', coords = vec3(-938.294, 402.609, 77.034), rotation = vec3(90.000, 0.000, 0.000) },
    --             },
    --             valve = { coords = vec3(-936.627, 398.193, 77.322), heading = -65.0, openPercent = false },
    --         },
    --     },

    --     repairpipe = {
    --         {
    --             pipes = {
    --                 { object = 'veo_pipes_d', coords = vec3(-933.549, 390.429, 77.028), rotation = vec3(90.000, 0.000, 0.000) },
    --                 { object = 'veo_pipes_e', coords = vec3(-933.533, 390.517, 77.735), rotation = vec3(90.000, 0.000, 111.956) },
    --                 { object = 'veo_pipes_d', coords = vec3(-933.774, 391.204, 77.828), rotation = vec3(0.000, 0.000, 22.053) },
    --                 { object = 'veo_pipes_d', coords = vec3(-934.148, 392.167, 77.828), rotation = vec3(0.000, 0.000, 22.053) },
    --                 { object = 'veo_pipes_d', coords = vec3(-934.514, 393.125, 77.828), rotation = vec3(0.000, 0.000, 22.053) },
    --                 { object = 'veo_pipes_d', coords = vec3(-934.880, 394.083, 77.828), rotation = vec3(0.000, 0.000, 22.053) },
    --                 { object = 'veo_pipes_d', coords = vec3(-935.267, 395.036, 77.828), rotation = vec3(0.000, 0.000, 22.053) },
    --                 { object = 'veo_pipes_e', coords = vec3(-935.537, 395.725, 77.717), rotation = vec3(-21.941, 90.000, 0.000) },
    --                 { object = 'veo_pipes_d', coords = vec3(-935.584, 395.805, 77.004), rotation = vec3(90.000, 0.000, 0.000) },
    --             },
    --             valve = { coords = vec3(-933.615, 390.397, 77.322), heading = -65.0, openPercent = true },
    --         },
    --     },

    --     toilet = {
    --         {
    --             object = 'toilet2',
    --             coords = vec3(-931.53, 386.92, 76.01),
    --             heading = 214.0,
    --             shitProps = {
    --                 { prop = 'prop_big_shit_01', type = 'shit' },
    --                 { prop = 'prop_big_shit_01', type = 'shit' },
    --             },
    --             waterProp = { prop = 'suing', type = 'water' },
    --             plungerOffset = vec3(0.0, 0.16, 0.55),
    --         },
    --         {
    --             object = 'toilet2',
    --             coords = vec3(-957.16, 381.86, 72.25),
    --             heading = 125.0,
    --             shitProps = {
    --                 { prop = 'prop_big_shit_01', type = 'shit' },
    --                 { prop = 'prop_big_shit_01', type = 'shit' },
    --             },
    --             waterProp = { prop = 'suing', type = 'water' },
    --             plungerOffset = vec3(0.0, 0.16, 0.55),
    --         },
    --         {
    --             object = 'toilet2',
    --             coords = vec3(-921.48, 407.41, 78.6),
    --             heading = 0.0,
    --             shitProps = {
    --                 { prop = 'prop_big_shit_01', type = 'shit' },
    --                 { prop = 'prop_big_shit_01', type = 'shit' },
    --             },
    --             waterProp = { prop = 'suing', type = 'water' },
    --             plungerOffset = vec3(0.0, 0.16, 0.55),
    --         },
    --         {
    --             object = 'toilet2',
    --             coords = vec3(1210.86, 2393.54, 64.81),
    --             heading = 337.07,
    --             shitProps = {
    --                 { prop = 'prop_big_shit_01', type = 'shit' },
    --                 { prop = 'prop_big_shit_01', type = 'shit' },
    --             },
    --             waterProp = { prop = 'suing', type = 'water' },
    --             plungerOffset = vec3(0.0, 0.16, 0.55),
    --         },
    --     },

    --     openvalve = {
    --         {
    --             pipe  = { object = 'veo_pipes_r',       coords = vec3(-924.425, 406.301, 78.193), rotation = vec3(0.000, 0.000, -165.415) },
    --             valve = { object = 'prop_oil_valve_01', coords = vec3(-924.425, 406.162, 78.538), rotation = vec3(0.000, 0.000, 9.825), heading = 9.825 },
    --         },
    --         {
    --             pipe  = { object = 'veo_pipes_r',       coords = vec3(-970.320, 378.265, 71.919), rotation = vec3(0.000, 0.000, 0.000) },
    --             valve = { object = 'prop_oil_valve_01', coords = vec3(-970.285, 378.372, 72.252), rotation = vec3(0.000, 0.000, 0.000), heading = 0.0 },
    --         },
    --     },

    --     fixswitch = {
    --         { object = 'tt_h4_int_sub_switches', coords = vec3(-958.217, 387.760, 74.255), rotation = vec3(-79.982, 0.000, 114.699) },
    --         { object = 'tt_h4_int_sub_switches', coords = vec3(-941.445, 396.052, 78.324), rotation = vec3(-89.277, 1.912, -149.537) },
    --         { object = 'tt_h4_int_sub_switches', coords = vec3(-922.887, 407.068, 80.187), rotation = vec3(-89.477, 2.206, -76.663) },
    --     },
    -- },

    {
        name = 'Pacific Bluffs',
        areaCoords = vec(-1985.9601, 549.6125, 111.1083), --- Coords untuk blip route

        insertpipe = {
            {
                pipes = {
                    { object = 'veo_pipes_d', coords = vec3(-2006.558, 543.536, 109.552), rotation = vec3(90.000, 0.000, 0.000) },
                    { object = 'veo_pipes_e', coords = vec3(-2006.645, 543.570, 110.278), rotation = vec3(108.767, 90.000, 0.000) },
                    { object = 'veo_pipes_d', coords = vec3(-2007.337, 543.796, 110.375), rotation = vec3(0.000, 0.000, 72.823) },
                    { object = 'veo_pipes_d', coords = vec3(-2008.326, 544.095, 110.375), rotation = vec3(0.000, 0.000, 72.823) },
                    { object = 'veo_pipes_d', coords = vec3(-2008.810, 544.254, 110.375), rotation = vec3(0.000, 0.000, 72.823) },
                    { object = 'veo_pipes_e', coords = vec3(-2009.486, 544.453, 110.285), rotation = vec3(88.810, -2.367, -19.487) },
                    { object = 'veo_pipes_d', coords = vec3(-2009.566, 544.490, 109.562), rotation = vec3(90.000, 0.000, 0.000) },
                },
                valve = { coords = vec3(-2006.558, 543.483, 109.908), heading = -12.3, openPercent = false },
            },
        },

        repairpipe = {
            {
                pipes = {
                    { object = 'veo_pipes_d', coords = vec3(-2006.205, 560.315, 109.624), rotation = vec3(90.000, 0.000, 0.000) },
                    { object = 'veo_pipes_e', coords = vec3(-2006.233, 560.211, 110.351), rotation = vec3(12.290, 90.000, 0.000) },
                    { object = 'veo_pipes_d', coords = vec3(-2006.415, 559.499, 110.448), rotation = vec3(0.000, 0.000, -15.235) },
                    { object = 'veo_pipes_d', coords = vec3(-2006.689, 558.496, 110.448), rotation = vec3(0.000, 0.000, -15.235) },
                    { object = 'veo_pipes_d', coords = vec3(-2006.957, 557.507, 110.448), rotation = vec3(0.000, 0.000, -15.235) },
                    { object = 'veo_pipes_e', coords = vec3(-2007.142, 556.807, 110.346), rotation = vec3(140.928, 89.286, -50.230) },
                    { object = 'veo_pipes_d', coords = vec3(-2007.162, 556.707, 109.624), rotation = vec3(90.000, 0.000, 0.000) },
                },
                valve = { coords = vec3(-2006.260, 560.323, 109.908), heading = -104.5, openPercent = true },
            },
        },

        toilet = {
            {
                object = 'toilet2',
                coords = vec3(-2016.69, 546.94, 109.16),
                heading = 337.55,
                shitProps = {
                    { prop = 'prop_big_shit_01', type = 'shit' },
                    { prop = 'prop_big_shit_01', type = 'shit' },
                },
                waterProp = { prop = 'suing', type = 'water' },
                plungerOffset = vec3(0.0, 0.16, 0.55),
            },
            {
                object = 'toilet2',
                coords = vec3(-2036.94, 550.99, 109.69),
                heading = 261.19,
                shitProps = {
                    { prop = 'prop_big_shit_01', type = 'shit' },
                    { prop = 'prop_big_shit_01', type = 'shit' },
                },
                waterProp = { prop = 'suing', type = 'water' },
                plungerOffset = vec3(0.0, 0.16, 0.55),
            },
            {
                object = 'toilet2',
                coords = vec3(-2023.16, 554.24, 107.41),
                heading = 11.16,
                shitProps = {
                    { prop = 'prop_big_shit_01', type = 'shit' },
                    { prop = 'prop_big_shit_01', type = 'shit' },
                },
                waterProp = { prop = 'suing', type = 'water' },
                plungerOffset = vec3(0.0, 0.16, 0.55),
            },
        },

        openvalve = {
            {
                pipe  = { object = 'veo_pipes_r',       coords = vec3(-2011.597, 560.920, 110.567), rotation = vec3(0.000, 0.000, -103.893) },
                valve = { object = 'prop_oil_valve_01', coords = vec3(-2011.488, 560.859, 110.933), rotation = vec3(0.000, 0.000, 74.216), heading = 74.216 },
            },
            {
                pipe  = { object = 'veo_pipes_r',       coords = vec3(-2012.091, 538.996, 112.470), rotation = vec3(0.000, 0.000, -103.816) },
                valve = { object = 'prop_oil_valve_01', coords = vec3(-2011.954, 538.921, 112.834), rotation = vec3(0.000, 0.000, 80.885), heading = 80.885 },
            },
        },

        fixswitch = {
            { object = 'tt_h4_int_sub_switches', coords = vec3(-2001.738, 548.303, 113.543), rotation = vec3(-89.381, -2.857, 86.451) },
            { object = 'tt_h4_int_sub_switches', coords = vec3(-2016.108, 557.658, 109.198), rotation = vec3(-97.771, 0.322, 72.123) },
        },
    },
}
