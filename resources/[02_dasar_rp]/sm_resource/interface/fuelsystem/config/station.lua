return {
    electric_charging = true,

    price = {
        refuel = 600, --- per liter
        charger = 600 --- per kwh
    },

    nozzle = {
        fuel = {
            bone = 18905,
            model = 'prop_cs_fuel_nozle',
            pos = vec(0.13, 0.04, 0.01),
            rot = vec(-42.0, -115.0, -63.42),
            rope = {
                type = 1,
                prefixZ = 1.5,
                length = 5.0,

            }
        },
        electric = {
            bone = 18905,
            model = 'electric_nozzle',
            pos = vec(0.24, 0.10, -0.052),
            rot = vec(-45.0, 120.0, 75.00),
            rope = {
                type = 1,
                prefixZ = 1.5,
                length = 5.0,

            }
        }
    },

    pump_props = {
        "prop_gas_pump_1d",
        "prop_gas_pump_1a",
        "prop_gas_pump_1b",
        "prop_gas_pump_1c",
        "amb_rox_caspump_pf",
        "amb_pefu_barrel_01b",
        "amb_pefu_barrel_01c",
        "denis3d_prop_gas_pump", -- Gabz Ballas Gas Station Pump.
        `1767019582`
    },

    pump_props_old = {
        "prop_vintage_pump",
        "prop_gas_pump_old2",
        "prop_gas_pump_old3",
    },

    location = {
        {
            id = 'pom_1',
            ped = {
                model = 'a_m_m_indian_01',
                coords = vec(167.06, -1553.56, 28.26, 220.44)
            },
            polygon = {
                points = {
                    vec3(173.5299987793, -1530.4899902344, 29.0),
                    vec3(144.22999572754, -1560.1700439453, 29.0),
                    vec3(171.33000183105, -1578.2700195312, 29.0),
                    vec3(200.05000305176, -1563.6300048828, 29.0),
                },
                thickness = 4.0,
            },
            vehcoords = vec(175.7030, -1539.7371, 29.4351, 221.0592),
            chargercoords = vector4(175.9, -1546.65, 28.26, 224.29),
        },
        {
            id = 'pom_2',
            ped = {
                model = 'a_m_m_indian_01',
                coords = vec(-40.94, -1751.7, 28.42, 140.72)
            },
            polygon = {
                points = {
                    vec3(-53.03, -1737.50, 29.3),
                    vec3(-92.80, -1751.89, 29.3),
                    vec3(-91.29, -1759.09, 29.3),
                    vec3(-65.53, -1782.58, 29.3),
                    vec3(-36.36, -1751.52, 29.3),
                },
                thickness = 4.0,
            },
            vehcoords = vec(-44.9373, -1742.2229, 29.4550, 52.2930),
            chargercoords = vector4(-51.09, -1767.02, 28.26, 47.16),
        },
        {
            id = 'pom_3',
            ped = {
                model = 'a_m_m_indian_01',
                coords = vec(-531.2, -1220.83, 17.45, 335.73)
            },
            polygon = {
                points = {
                    vec3(-543.94, -1218.18, 19.2),
                    vec3(-533.71, -1191.67, 19.2),
                    vec3(-500.00, -1204.55, 19.2),
                    vec3(-521.97, -1232.58, 19.2),
                },
                thickness = 4.0,
            },
            vehcoords = vec(-543.3353, -1217.7958, 18.5107, 333.8071),
            chargercoords = vector4(-514.06, -1216.25, 17.46, 66.29),
        },
        {
            id = 'pom_4',
            ped = {
                model = 'a_m_m_indian_01',
                coords = vec(-705.66, -905.04, 18.22, 179.46)
            },
            polygon = {
                points = {
                    vec3(-696.77, -948.94, 19.2),
                    vec3(-739.47, -951.07, 19.2),
                    vec3(-734.73, -906.5, 19.2),
                    vec3(-711.0, -906.76, 19.2),
                    vec3(-710.65, -903.27, 19.2),
                    vec3(-696.82, -903.21, 19.2),
                },
                thickness = 4.0,
            },
            vehcoords = vec(-701.9839, -920.1072, 19.2490, 88.8288),
            chargercoords = vector4(-704.64, -935.71, 18.21, 90.02),
        },
        {
            id = 'pom_5',
            ped = {
                model = 'a_m_m_indian_01',
                coords = vec(288.83, -1267.01, 28.44, 93.81)
            },
            polygon = {
                points = {
                    vec3(243.18, -1281.82, 29.7),
                    vec3(243.94, -1228.41, 29.7),
                    vec3(299.62, -1228.03, 29.7),
                    vec3(300.76, -1286.36, 29.7),
                },
                thickness = 4.0,
            },
            vehcoords = vec(293.4226, -1247.5935, 29.5219, 90.9282),
            chargercoords = vector4(279.79, -1237.35, 28.35, 181.07),
        },
        {
            id = 'pom_6',
            ped = {
                model = 'a_m_m_indian_01',
                coords = vec(816.42, -1040.51, 25.75, 2.07)
            },
            polygon = {
                points = {
                    vec3(798.48, -1017.05, 26.6),
                    vec3(801.89, -1061.74, 26.6),
                    vec3(847.73, -1063.26, 26.6),
                    vec3(845.08, -1015.91, 26.6),
                },
                thickness = 4.0,
            },
            vehcoords = vec(826.0133, -1045.0823, 27.4904, 357.8149),
            chargercoords = vector4(834.27, -1028.7, 26.16, 88.39),
        },
        {
            id = 'pom_7',
            ped = {
                model = 'a_m_m_indian_01',
                coords = vec(1211.13, -1389.18, 34.38, 177.39)
            },
            polygon = {
                points = {
                    vec3(1212.12, -1381.44, 35.2),
                    vec3(1221.21, -1395.08, 35.2),
                    vec3(1219.70, -1403.41, 35.2),
                    vec3(1207.58, -1417.05, 35.2),
                    vec3(1194.70, -1418.94, 35.2),
                    vec3(1192.80, -1389.02, 35.2),
                },
                thickness = 4.0,
            },
            vehcoords = vec(1197.3911, -1384.0518, 35.4603, 182.5337),
            chargercoords = vector4(1194.41, -1394.44, 34.37, 270.3),
        },
        {
            id = 'pom_8',
            ped = {
                model = 'a_m_m_indian_01',
                coords = vec(1163.64, -314.21, 68.21, 190.92)
            },
            polygon = {
                points = {
                    vec3(1188.28, -306.38, 68.9),
                    vec3(1145.24, -314.19, 68.9),
                    vec3(1150.81, -346.52, 68.9),
                    vec3(1195.44, -353.92, 68.9),
                    vec3(1197.01, -340.55, 68.9),
                },
                thickness = 4.0,
            },
            vehcoords = vec(1176.3929, -314.7283, 69.4137, 279.7426),
            chargercoords = vector4(1168.38, -323.56, 68.3, 280.22),
        },
        {
            id = 'pom_9',
            ped = {
                model = 'a_m_m_indian_01',
                coords = vec(642.08, 260.59, 102.3, 61.39)
            },
            polygon = {
                points = {
                    vec3(650.76, 229.92, 103.35),
                    vec3(599.24, 256.44, 103.35),
                    vec3(598.48, 271.21, 103.35),
                    vec3(610.61, 287.88, 103.35),
                    vec3(634.85, 289.39, 103.35),
                    vec3(664.77, 271.21, 103.35),
                },
                thickness = 4.0,
            },
            vehcoords = vec(642.9693, 269.7089, 103.3778, 148.8837),
            chargercoords = vector4(633.64, 247.22, 102.3, 60.29),
        },
        {
            id = 'pom_10',
            ped = {
                model = 'a_m_m_indian_01',
                coords = vec(-1428.4, -268.69, 45.21, 132.94)
            },
            polygon = {
                points = {
                    vec3(-1460.98, -276.89, 46.15),
                    vec3(-1419.32, -237.12, 46.15),
                    vec3(-1390.91, -270.45, 46.15),
                    vec3(-1435.23, -305.68, 46.15),
                },
                thickness = 4.0,
            },
            vehcoords = vec(-1412.9913, -281.3479, 46.5651, 130.3375),
            chargercoords = vector4(-1420.51, -278.76, 45.26, 137.35),
        },
        {
            id = 'pom_11',
            ped = {
                model = 'a_m_m_indian_01',
                coords = vec(-2074.28, -327.22, 12.32, 132.94)
            },
            polygon = {
                points = {
                    vec3(-2135.61, -327.27, 13.15),
                    vec3(-2134.85, -286.36, 13.15),
                    vec3(-2051.52, -300.00, 13.15),
                    vec3(-2054.55, -345.45, 13.15),
                    vec3(-2081.82, -347.73, 13.15),
                    vec3(-2113.64, -343.18, 13.15),
                },
                thickness = 4.0,
            },
            vehcoords = vec(-2068.8442, -307.9710, 13.3847, 86.2116),
            chargercoords = vector4(-2080.61, -338.52, 12.26, 352.21),
        },
        {
            id = 'pom_12',
            ped = {
                model = 'a_m_m_indian_01',
                coords = vec(-93.02, 6410.11, 30.64, 49.19)
            },
            polygon = {
                points = {
                    vec3(-91.5, 6431.47, 31.92),
                    vec3(-77.83, 6419.75, 31.92),
                    vec3(-101.06, 6397.01, 31.92),
                    vec3(-113.59, 6409.91, 31.92),
                },
                thickness = 4.0,
            },
            vehcoords = vec(-70.9958, 6429.5488, 31.6734, 46.3554),
            chargercoords = vector4(-98.12, 6403.39, 30.64, 141.49),
        },
        {
            id = 'pom_13',
            ped = {
                model = 'a_m_m_indian_01',
                coords = vec(170.44, 6633.74, 30.59, 221.95)
            },
            polygon = {
                points = {
                    vec3(167.08, 6631.73, 32.05),
                    vec3(176.47, 6640.66, 32.05),
                    vec3(199.71, 6632.08, 32.05),
                    vec3(202.3, 6597.25, 32.05),
                    vec3(162.95, 6590.22, 32.05),
                    vec3(158.64, 6610.64, 32.05),
                },
                thickness = 4.0,
            },
            vehcoords = vec(173.6250, 6625.3589, 31.9437, 314.3952),
            chargercoords = vector4(181.14, 6636.17, 30.61, 179.96),
        },
        {
            id = 'pom_13',
            polygon = {
                points = {
                    vec3(157.8, 6624.45, 31.7),
                    vec3(162.12, 6628.46, 31.7),
                    vec3(154.27, 6636.61, 31.7),
                    vec3(148.14, 6631.45, 31.7),
                },
                thickness = 4.0,
            },
            chargercoords = vector4(159.79, 6632.41, 30.68, 141.56),
        },
        {
            id = 'pom_14',
            ped = {
                model = 'a_m_m_indian_01',
                coords = vec(1698.62, 6425.84, 31.76, 156.61)
            },
            polygon = {
                points = {
                    vec3(1684.5, 6413.73, 32.8),
                    vec3(1693.67, 6431.38, 32.8),
                    vec3(1721.72, 6428.14, 32.8),
                    vec3(1710.47, 6402.65, 32.8),
                },
                thickness = 4.0,
            },
            vehcoords = vec(1687.3636, 6435.3545, 32.6909, 182.2138),
            chargercoords = vector4(1714.14, 6425.44, 31.79, 155.94),
        },
        {
            id = 'pom_15',
            ped = {
                model = 'a_m_m_indian_01',
                coords = vec(1704.59, 4917.5, 41.06, 52.16)
            },
            polygon = {
                points = {
                    vec3(1696.59, 4939.02, 42.11),
                    vec3(1723.48, 4920.08, 42.11),
                    vec3(1698.11, 4886.74, 42.11),
                    vec3(1669.70, 4907.20, 42.11),
                    vec3(1678.41, 4929.17, 42.11),
                },
                thickness = 4.0,
            },
            vehcoords = vec(1698.4327, 4913.5146, 42.3121, 54.3330),
            chargercoords = vector4(1703.57, 4937.23, 41.08, 55.74),
        },
        {
            id = 'pom_16',
            ped = {
                model = 'a_m_m_indian_01',
                coords = vec(2001.33, 3779.87, 31.18, 211.44)
            },
            polygon = {
                points = {
                    vec3(1972.35, 3777.27, 32.39),
                    vec3(1989.02, 3748.11, 32.39),
                    vec3(2018.18, 3762.12, 32.39),
                    vec3(2001.52, 3790.91, 32.39),
                },
                thickness = 4.0,
            },
            vehcoords = vec(1983.3102, 3783.1582, 32.4157, 209.7147),
            chargercoords = vector4(1994.54, 3778.44, 31.18, 215.25),
        },
        {
            id = 'pom_17',
            ped = {
                model = 'a_m_m_indian_01',
                coords = vec(1776.57, 3327.36, 40.43, 297.57)
            },
            polygon = {
                points = {
                    vec3(1774.24, 3308.71, 41.8),
                    vec3(1752.65, 3345.83, 41.8),
                    vec3(1784.47, 3357.95, 41.8),
                    vec3(1808.71, 3321.21, 41.8),
                },
                thickness = 4.0,
            },
            vehcoords = vec(1762.4784, 3344.4050, 41.2214, 300.2642),
            chargercoords = vector4(1770.86, 3337.97, 40.43, 301.1),
        },
        {
            id = 'pom_18',
            ped = {
                model = 'a_m_m_indian_01',
                coords = vec(2673.98, 3266.87, 54.24, 240.9)
            },
            polygon = {
                points = {
                    vec3(2671.21, 3290.53, 55.32),
                    vec3(2649.62, 3254.55, 55.32),
                    vec3(2682.95, 3237.50, 55.32),
                    vec3(2703.79, 3275.38, 55.32),
                },
                thickness = 4.0,
            },
            vehcoords = vec(2654.3879, 3266.4138, 55.4745, 156.9737),
            chargercoords = vector4(2690.25, 3265.62, 54.24, 58.98),
        },
        {
            id = 'pom_19',
            ped = {
                model = 'a_m_m_indian_01',
                coords = vec(1201.68, 2655.24, 36.85, 322.97)
            },
            polygon = {
                points = {
                    vec3(1188.64, 2651.89, 37.78),
                    vec3(1202.27, 2663.64, 37.78),
                    vec3(1212.50, 2661.74, 37.78),
                    vec3(1217.05, 2651.52, 37.78),
                    vec3(1210.61, 2633.33, 37.78),
                    vec3(1201.52, 2638.26, 37.78),
                },
                thickness = 4.0,
            },
            vehcoords = vec(1205.5380, 2641.3059, 38.0673, 314.4621),
            chargercoords = vector4(1217.61, 2658.8, 36.77, 87.7),
        },
        {
            id = 'pom_20',
            ped = {
                model = 'a_m_m_indian_01',
                coords = vec(1039.44, 2664.37, 38.55, 10.07)
            },
            polygon = {
                points = {
                    vec3(1026.14, 2669.70, 39.55),
                    vec3(1028.03, 2640.91, 39.55),
                    vec3(1058.33, 2640.53, 39.55),
                    vec3(1055.30, 2668.94, 39.55),
                },
                thickness = 4.0,
            },
            vehcoords = vec(1056.4115, 2657.6282, 39.7901, 358.7656),
            chargercoords = vector4(1033.32, 2662.91, 38.55, 95.38),
        },
        {
            id = 'pom_21',
            ped = {
                model = 'a_m_m_indian_01',
                coords = vec(265.89, 2598.3, 43.84, 9.88)
            },
            polygon = {
                points = {
                    vec3(269.70, 2606.44, 44.95),
                    vec3(275.38, 2585.23, 44.95),
                    vec3(241.29, 2576.52, 44.95),
                    vec3(235.23, 2609.09, 44.95),
                    vec3(268.56, 2617.05, 44.95),
                },
                thickness = 4.0,
            },
            vehcoords = vec(275.7782, 2591.9351, 44.7304, 285.5523),
            chargercoords = vector4(267.96, 2599.47, 43.69, 5.8),
        },
        {
            id = 'pom_22',
            ped = {
                model = 'a_m_m_indian_01',
                coords = vec(46.53, 2789.05, 56.88, 143.93)
            },
            polygon = {
                points = {
                    vec3(46.59, 2795.45, 57.9),
                    vec3(27.65, 2775.76, 57.9),
                    vec3(49.24, 2754.55, 57.9),
                    vec3(68.56, 2778.03, 57.9),
                },
                thickness = 4.0,
            },
            vehcoords = vec(66.7658, 2783.2981, 58.1126, 144.2255),
            chargercoords = vector4(50.21, 2787.38, 56.88, 147.2),
        },
        {
            id = 'pom_23',
            ped = {
                model = 'a_m_m_indian_01',
                coords = vec(-2544.04, 2316.15, 32.22, 2.5)
            },
            polygon = {
                points = {
                    vec3(-2562.12, 2340.53, 33.06),
                    vec3(-2560.98, 2299.62, 33.06),
                    vec3(-2514.39, 2300.76, 33.06),
                    vec3(-2516.29, 2314.02, 33.06),
                    vec3(-2523.86, 2344.70, 33.06),
                },
                thickness = 4.0,
            },
            vehcoords = vec(-2537.0720, 2345.7473, 33.2940, 30.3036),
            chargercoords = vector4(-2570.04, 2317.1, 32.22, 21.29),
        },
        {
            id = 'pom_24',
            ped = {
                model = 'a_m_m_indian_01',
                coords = vec(2545.02, 2591.72, 36.96, 113.52)
            },
            polygon = {
                points = {
                    vec3(2545.08, 2601.14, 37.94),
                    vec3(2556.06, 2573.11, 37.94),
                    vec3(2545.83, 2568.56, 37.94),
                    vec3(2531.06, 2601.14, 37.94),
                    vec3(2540.91, 2599.24, 37.94),
                },
                thickness = 4.0,
            },
            vehcoords = vec(2535.6978, 2579.0862, 38.1789, 11.6245),
            chargercoords = vector4(2545.81, 2586.18, 36.94, 83.74),
        },
        {
            id = 'pom_25',
            ped = {
                model = 'a_m_m_indian_01',
                coords = vec(2559.36, 373.68, 107.62, 272.2)
            },
            polygon = {
                points = {
                    vec3(2540.15, 373.86, 108.4),
                    vec3(2538.26, 345.83, 108.4),
                    vec3(2592.80, 343.56, 108.4),
                    vec3(2594.70, 369.70, 108.4),
                    vec3(2557.58, 384.85, 108.4),
                },
                thickness = 4.0,
            },
            vehcoords = vec(2554.3508, 405.6071, 108.6874, 133.8318),
            chargercoords = vector4(2561.24, 357.3, 107.62, 266.65),
        },
        {
            id = 'pom_26',
            ped = {
                model = 'a_m_m_indian_01',
                coords = vec(-1825.33, 800.96, 137.1, 220.96)
            },
            polygon = {
                points = {
                    vec3(-1820.41, 767.31, 138.27),
                    vec3(-1775.49, 802.95, 138.27),
                    vec3(-1798.5, 828.42, 138.27),
                    vec3(-1841.71, 791.66, 138.27),
                },
                thickness = 4.0,
            },
            vehcoords = vec(-1823.5436, 779.9325, 138.0571, 219.8474),
            chargercoords = vector4(-1819.22, 798.51, 137.16, 315.13),
        },
        {
            id = 'pom_27',
            ped = {
                model = 'a_m_m_indian_01',
                coords = vec(-342.37, -1482.97, 29.71, 273.47)
            },
            polygon = {
                points = {
                    vec3(-354.55, -1452.65, 30.7),
                    vec3(-354.17, -1499.62, 30.7),
                    vec3(-301.52, -1497.73, 30.7),
                    vec3(-296.59, -1453.03, 30.7),
                },
                thickness = 4.0,
            },
            vehcoords = vec(-348.3763, -1495.7202, 30.7820, 272.6716),
            chargercoords = vector4(-341.63, -1459.39, 29.76, 271.73),
        },
        {
            id = 'pom_28',
            -- ped = {
            --     model = 'a_m_m_indian_01',
            --     coords = vec(155.12, 6637.5, 31.69, 132.46)
            -- },
            polygon = {
                points = {
                    vec3(171.83, 1694.56, 230.7),
                    vec3(175.62, 1684.61, 230.7),
                    vec3(196.27, 1693.66, 230.7),
                    vec3(191.21, 1705.27, 230.7),
                },
                thickness = 4.0,
            },
            chargercoords = vector4(184.95, 1702.71, 229.24, 116.26),
        },
        {
            id = 'pom_29',
            ped = {
                model = 'a_m_m_indian_01',
                coords = vec(4513.24, -4469.33, 4.02, 23.74)
            },
            polygon = {
                points = {
                    vec3(4508.0, -4469.0, 4.7),
                    vec3(4526.0, -4462.0, 4.7),
                    vec3(4530.0, -4471.0, 4.7),
                    vec3(4511.0, -4478.0, 4.7),
                },
                thickness = 4.0,
            },
            vehcoords = vec(4468.4976, -4466.4751, 4.4788, 261.8344),
            chargercoords = vector4(4527.16, -4468.06, 3.19, 109.86),
        },
        {
            id = 'pom_30',
            ped = {
                model = 'a_m_m_indian_01',
                coords = vec(-513.2318, 7575.8799, 5.4149, 231.5943)
            },
            polygon = {
                points = {
                    vec3(-506.0, 7584.0, 4.7),
                    vec3(-481.0, 7564.0, 4.7),
                    vec3(-492.0, 7553.0, 4.7),
                    vec3(-519.0, 7574.0, 4.7),
                },
                thickness = 4.0,
            },
            vehcoords = vec(-522.1989, 7571.7207, 6.6463, 230.8101),
            chargercoords = vector4(-509.4412, 7579.1948, 5.4147, 228.2947),
        },
        {
            id = 'pom_31',
            ped = {
                model = 'a_m_m_indian_01',
                coords = vec(-1227.8942, 6923.7803, 19.420, 160.8193)
            },
            polygon = {
                points = {
                    vec3(-1248.5899658203, 6910.7998046875, 20.0),
                    vec3(-1240.1400146484, 6943.830078125, 20.0),
                    vec3(-1210.6500244141, 6936.4501953125, 20.0),
                    vec3(-1219.6800537109, 6903.919921875, 20.0),
                },
                thickness = 19.05,
            },
            vehcoords = vec(-1215.6724, 6925.6821, 20.7323, 167.8822),
            chargercoords = vector4(-1224.6868, 6922.8853, 19.4393, 162.6151),
        },
        {
            id = 'pom_32',
            -- ped = {
            --     model = 'a_m_m_indian_01',
            --     coords = vec(-3284.9600, 6189.6143, 12.6528, 160.8193)
            -- },
            polygon = {
                points = {
                    vec3(-3263.0, 6169.0, 14.0),
                    vec3(-3293.0, 6165.0, 14.0),
                    vec3(-3296.0, 6186.0, 14.0),
                    vec3(-3263.0, 6189.0, 14.0),
                },
                thickness = 4.0,
            },
            chargercoords = vector4(-3270.9414, 6189.6143, 12.6528, 190.9231),
        },
        {
            id = 'pom_33',
            -- ped = {
            --     model = 'a_m_m_indian_01',
            --     coords = vec(-2763.4690, 7022.7881, 28.5484, 273.4463)
            -- },
            polygon = {
                points = {
                    vec3(-2754.0, 7058.0, 28.0),
                    vec3(-2754.0, 7010.0, 28.0),
                    vec3(-2735.0, 7011.0, 28.0),
                    vec3(-2735.0, 7057.0, 28.0),
                },
                thickness = 4.0,
            },
            chargercoords = vector4(-2752.0205, 7011.7803, 27.6438, 359.4370),
        },
        {
            id = 'pom_34',
            polygon = {
                points = {
                    vec3(193.0, 1221.0, 226.0),
                    vec3(186.27000427246, 1251.5100097656, 226.0),
                    vec3(224.99000549316, 1259.9000244141, 226.0),
                    vec3(231.44000244141, 1230.2900390625, 226.0),
                    vec3(231.0, 1230.0, 226.0),
                },
                thickness = 4.0,
            },
            ped = {
                model = 'a_m_m_indian_01',
                coords = vec(202.9929, 1244.6506, 224.6572, 283.8600)
            },
            vehcoords = vec(219.3775, 1256.6412, 225.7118, 195.0251),
            chargercoords = vec(193.1848, 1237.3385, 224.5956, 280.0046)
        },

        {
            id = 'pom_35',
            polygon = {
                points = {
                    vec3(2898.7099609375, 521.79998779297, 52.0),
                    vec3(2897.7399902344, 527.03997802734, 52.0),
                    vec3(2906.7700195312, 528.88000488281, 52.0),
                    vec3(2910.25, 513.09002685547, 52.0),
                    vec3(2899.8798828125, 511.98001098633, 52.0),
                    vec3(2899.7600097656, 512.96002197266, 52.0),
                },
                thickness = 4.0,
            },
            ped = {
                model = 'a_m_m_indian_01',
                coords = vec(2903.0122, 523.6114, 52.4012, 280.1469)
            },
            vehcoords = vec(2903.5513, 518.6636, 52.2398, 96.5985),
            chargercoords = vec(2900.8374, 526.0133, 51.9384, 99.5037)
        },

        {
            id = 'pom_36',
            polygon = {
                points = {
                    vec3(-435.5299987793, 7913.6298828125, 6.0),
                    vec3(-457.17999267578, 7892.75, 6.0),
                    vec3(-427.10998535156, 7863.1098632812, 6.0),
                    vec3(-406.01000976562, 7884.3198242188, 6.0),
                    vec3(-406.0, 7884.0, 6.0),
                },
                thickness = 13.0,
            },
            chargercoords = vec(-421.6245, 7891.4854, 6.4120, 46.2040)
        },

        {
            id = 'pom_36',
            polygon = {
                points = {
                    vec3(-522.16998291016, 8798.73046875, 7.0),
                    vec3(-553.46997070312, 8795.5498046875, 7.0),
                    vec3(-548.78002929688, 8766.5302734375, 7.0),
                    vec3(-519.75, 8769.1396484375, 7.0),
                    vec3(-520.71997070312, 8775.6298828125, 7.0),
                },
                thickness = 13.0,
            },
            chargercoords = vec(-522.0193, 8792.2627, 6.3950, 95.2721)
        },

        --- MARK: WHITELIST LOC
        --- MRPD 
         {
            id = 'pom_wl_mrpd',
            price = {
                refuel = 150,
                charger = 150
            },
            blip = false,
            polygon = {
                points = {
                    vec3(456.79000854492, -1027.4100341797, 28.0),
                    vec3(448.07000732422, -1028.6300048828, 28.0),
                    vec3(447.48001098633, -1022.4199829102, 28.0),
                    vec3(455.79998779297, -1021.2600097656, 28.0),
                    vec3(456.0, -1021.0, 28.0),
                },
                thickness = 7.5,
            },
            groups = {
                'police',
            },
            requiredDuty = true,
            vehicles = {
                'npolexp',
                'npolvic',
                'police3',
                'policet',
                'fbi',
                'npolstang',
                'npolchal',
                'npolchar',
                'npolvette',
                'npolmm',
            }
        },
        --- SASP 
        {
            id = 'pom_wl_sasp',
            price = {
                refuel = 150,
                charger = 150
            },
            blip = false,
            polygon = {
                points = {
                    vec3(2423.1999511719, 1534.1500244141, 31.0),
                    vec3(2423.1499023438, 1544.6800537109, 31.0),
                    vec3(2436.9899902344, 1545.0, 31.0),
                    vec3(2437.0, 1533.9499511719, 31.0),
                    vec3(2430.2900390625, 1533.8900146484, 31.0),
                },
                thickness = 7.5,
            },
            groups = {
                'police',
            },
            requiredDuty = true,
            vehicles = {
                'npolexp',
                'npolvic',
                'police3',
                'policet',
                'fbi',
                'npolstang',
                'npolchal',
                'npolchar',
                'npolvette',
                'npolmm',
            }
        },
        --- SDSO 
         {
            id = 'pom_wl_SDSO',
            price = {
                refuel = 150,
                charger = 150
            },
            blip = false,
            polygon = {
                points = {
                    vec3(1863.0400390625, 3695.0200195312, 34.0),
                    vec3(1865.7900390625, 3689.8898925781, 34.0),
                    vec3(1861.0100097656, 3686.6000976562, 34.0),
                    vec3(1858.4399414062, 3692.1201171875, 34.0),
                    vec3(1858.0, 3692.0, 34.0),
                },
                thickness = 7.5,
            },
            groups = {
                'police',
            },
            requiredDuty = true,
            vehicles = {
                'npolexp',
                'npolvic',
                'police3',
                'policet',
                'fbi',
                'npolstang',
                'npolchal',
                'npolchar',
                'npolvette',
            }
        },
        --- PBSO 
         {
            id = 'pom_wl_PBSO',
            price = {
                refuel = 150,
                charger = 150
            },
            blip = false,
            polygon = {
                points = {
                    vec3(-482.88000488281, 6018.3701171875, 31.0),
                    vec3(-477.35998535156, 6012.9301757812, 31.0),
                    vec3(-471.57000732422, 6018.4301757812, 31.0),
                    vec3(-477.38000488281, 6023.9599609375, 31.0),
                    vec3(-477.64001464844, 6023.3598632812, 31.0),
                },
                thickness = 7.5,
            },
            groups = {
                'police',
            },
            requiredDuty = true,
            vehicles = {
                'npolexp',
                'npolvic',
                'police3',
                'policet',
                'fbi',
                'npolstang',
                'npolchal',
                'npolchar',
                'npolvette',
            }
        },
        -- MRPD Helipad
        -- {
        --     id = 'pom_wl_1',
        --     aircraft = true,
        --     polygon = {
        --         points = {
        --             vec3(-523.0, -2361.0, 14.0),
        --             vec3(-532.0, -2372.0, 14.0),
        --             vec3(-503.0, -2398.0, 14.0),
        --             vec3(-494.0, -2387.0, 14.0),
        --         },
        --         thickness = 10.0,
        --     },
        --     groups = {
        --         'police', 'ambulance'
        --     },
        --     requiredDuty = true
        -- },
        -- Mission Row PD Helipad
        -- {
        --     id = 'pom_wl_2',
        --     aircraft = true,
        --     polygon = {
        --         points = {
        --             vec3(340.46, -580.02, 75.5),
        --             vec3(351.11, -575.06, 75.5),
        --             vec3(360.2, -578.35, 75.5),
        --             vec3(364.99, -588.36, 75.5),
        --             vec3(361.57, -597.44, 75.5),
        --             vec3(351.71, -601.99, 75.5),
        --             vec3(342.19, -598.38, 75.5),
        --             vec3(337.23, -587.49, 75.5),
        --         },
        --         thickness = 6.0,
        --     },
        --     groups = {
        --         'police', 'ambulance'
        --     },
        --     requiredDuty = true
        -- },
        -- Cental Los Santos Medical Center
        {
            id = 'pom_wl_3',
            aircraft = true,
            polygon = {
                points = {
                    vec3(287.81, -1454.52, 46.75),
                    vec3(298.6, -1441.48, 46.75),
                    vec3(325.74, -1464.21, 46.75),
                    vec3(314.95, -1477.29, 46.75),
                },
                thickness = 7.5,
            },
            groups = {
                'police', 'ambulance'
            },
            requiredDuty = true
        },
        -- Devin Weston Terminal
        {
            id = 'pom_wl_4',
            aircraft = true,
            polygon = {
                points = {
                    vec3(-944.57, -2963.51, 15.25),
                    vec3(-954.6, -2981.75, 15.25),
                    vec3(-929.13, -2996.81, 15.25),
                    vec3(-918.35, -2978.74, 15.25),
                },
                thickness = 8.5,
            },
        },
        -- Back Right Terminal
        {
            id = 'pom_wl_5',
            aircraft = true,
            polygon = {
                points = {
                    vec3(-1658.47, -3109.69, 15.75),
                    vec3(-1645.78, -3085.85, 15.75),
                    vec3(-1664.28, -3074.94, 15.75),
                    vec3(-1677.93, -3098.61, 15.75),
                },
                thickness = 7.5,
            },
        },
        -- La Puerta Helicopter Pad #1
        {
            id = 'pom_wl_6',
            aircraft = true,
            polygon = {
                points = {
                    vec3(-701.34, -1441.48, 7.25),
                    vec3(-728.05, -1473.15, 7.25),
                    vec3(-712.1, -1486.4, 7.25),
                    vec3(-685.58, -1454.86, 7.25),
                },
                thickness = 6.5,
            },
        },
        -- La Puerta Helicopter Pad #2
        {
            id = 'pom_wl_7',
            aircraft = true,
            polygon = {
                points = {
                    vec3(-777.17, -1446.61, 7.25),
                    vec3(-761.78, -1459.59, 7.25),
                    vec3(-739.92, -1433.25, 7.25),
                    vec3(-755.4, -1420.29, 7.25),
                },
                thickness = 6.5,
            },
        },
        -- La Puerta Boat Dock #1
        {
            id = 'pom_wl_8',
            aircraft = true,
            polygon = {
                points = {
                    vec3(-793.1, -1482.94, 1.75),
                    vec3(-786.39, -1500.85, 1.75),
                    vec3(-809.39, -1508.94, 1.75),
                    vec3(-817.48, -1491.62, 1.75),
                },
                thickness = 13.5,
            },
        },
        -- Fort Zancudo Military Base Hangar
        {
            id = 'pom_wl_9',
            aircraft = true,
            polygon = {
                points = {
                    vec3(-2145.24, 3291.63, 33.75),
                    vec3(-2127.94, 3281.7, 33.75),
                    vec3(-2139.37, 3260.35, 33.75),
                    vec3(-2157.69, 3271.1, 33.75),
                },
                thickness = 7.5,
            },
            groups = {
                'police', 'ambulance'
            },
            requiredDuty = true
        },
        -- -- Paleto Bay Police Department
        -- {
        --     id = 'pom_wl_10',
        --     polygon = {
        --         points = {
        --             vec3(-497.03, 5987.98, 33.75),
        --             vec3(-476.48, 6008.6, 33.75),
        --             vec3(-454.99, 5986.53, 33.75),
        --             vec3(-475.77, 5966.83, 33.75),
        --         },
        --         thickness = 7.5,
        --     },
        --     groups = {
        --         'police', 'ambulance'
        --     },
        --     requiredDuty = true
        -- },
        -- Grapeseed Airfield
        {
            id = 'pom_wl_11',
            aircraft = true,
            polygon = {
                points = {
                    vec3(2094.41, 4771.26, 43.75),
                    vec3(2080.85, 4797.71, 43.75),
                    vec3(2104.56, 4811.8, 43.75),
                    vec3(2118.06, 4782.09, 43.75),
                },
                thickness = 7.5,
            },
        },
        -- Alamo Sea Boat Dock
        {
            id = 'pom_wl_12',
            aircraft = true,
            polygon = {
                points = {
                    vec3(1347.76, 4277.37, 32.75),
                    vec3(1330.47, 4279.02, 32.75),
                    vec3(1328.53, 4261.64, 32.75),
                    vec3(1346.13, 4260.88, 32.75),
                },
                thickness = 9.5,
            },
        },
        -- Bob Smith PD
        {
            id = 'pom_wl_13',
            aircraft = true,
            polygon = {
                points = {
                    vec3(-1083.85, -837.07, 39.25),
                    vec3(-1100.36, -849.84, 39.25),
                    vec3(-1108.85, -839.11, 39.25),
                    vec3(-1107.04, -837.76, 39.25),
                    vec3(-1109.65, -834.04, 39.25),
                    vec3(-1104.1, -829.69, 39.25),
                    vec3(-1104.29, -829.07, 39.25),
                    vec3(-1095.62, -822.42, 39.25),
                },
                thickness = 6.5,
            },
            groups = {
                'police', 'ambulance'
            },
            requiredDuty = true
        },
        -- Merryweather Helipad
        {
            id = 'pom_wl_14',
            aircraft = true,
            polygon = {
                points = {
                    vec3(488.84, -3383.66, 7.5),
                    vec3(489.23, -3356.98, 7.5),
                    vec3(467.46, -3356.83, 7.5),
                    vec3(467.58, -3383.62, 7.5),
                    vec3(472.59, -3383.59, 7.5),
                    vec3(472.63, -3382.13, 7.5),
                    vec3(476.67, -3382.11, 7.5),
                    vec3(476.8, -3383.94, 7.5),
                },
                thickness = 6.0,
            },
        },
        -- Airport Helipad #1 & #2
        {
            id = 'pom_wl_15',
            aircraft = true,
            polygon = {
                points = {
                    vec3(-1133.49, -2860.32, 15.5),
                    vec3(-1143.33, -2877.61, 15.5),
                    vec3(-1191.03, -2850.14, 15.5),
                    vec3(-1180.98, -2832.84, 15.5),
                },
                thickness = 6.0,
            },
        },
        -- Airport Helipad #3
        {
            id = 'pom_wl_16',
            aircraft = true,
            polygon = {
                points = {
                    vec3(-1124.63, -2865.31, 15.5),
                    vec3(-1134.74, -2882.56, 15.5),
                    vec3(-1108.76, -2897.71, 15.5),
                    vec3(-1099.04, -2880.39, 15.5),
                },
                thickness = 6.0,
            },
        },
        -- Sandy Shores Helipad
        {
            id = 'pom_wl_17',
            aircraft = true,
            polygon = {
                points = {
                    vec3(1764.15, 3226.34, 44.0),
                    vec3(1758.66, 3246.44, 44.0),
                    vec3(1777.28, 3250.51, 44.0),
                    vec3(1781.89, 3230.8, 44.0),
                },
                thickness = 7.0,
            },
        },
        -- Sandy Shores Hangar
        {
            id = 'pom_wl_18',
            aircraft = true,
            polygon = {
                points = {
                    vec3(1755.37, 3301.3, 43.75),
                    vec3(1764.9, 3294.63, 43.75),
                    vec3(1769.42, 3277.19, 43.75),
                    vec3(1728.83, 3266.58, 43.75),
                    vec3(1721.75, 3291.6, 43.75),
                },
                thickness = 7.5,
            },
        },
    }
}
