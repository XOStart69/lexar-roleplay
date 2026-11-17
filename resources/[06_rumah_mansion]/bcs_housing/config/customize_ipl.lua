CustomizeIPL = {
    --tambahipl
    {
        name = 'F.Clinton & Partner',
        ipl = function()
            if not IsDuplicityVersion() then
                return exports.bob74_ipl:GetMpSecurityOffice2Object()
            end
        end,
        entry = vec4(372.8451, -57.4463, 103.3633, 247.3627),
        prices = {},
    },
    -- dlc_biker
    {
        name = 'Clubhouse1',
        ipl = function()
            if not IsDuplicityVersion() then
                return exports.bob74_ipl:GetBikerClubhouse1Object()
            end
        end,
        entry = vec4(1121.0194, -3152.7607, -37.0627, 4.4515),
        prices = {
            Walls = 1000,
            Mural = 500
        },
        cams = {
            ["default"] = {
                vec3(-2.630005, 0.730957, 1.499996),
                vec3(-16.078577, 0.000009, 125.374260)
            },
            ["Cash"] = {
                vec3(-1.313110, 0.782471, 1.499985),
                vec3(-32.031685, -0.000001, 84.564606)
            },
            ["Coke"] = {
                vec3(-1.827393, 3.640381, 1.499985),
                vec3(-21.196751, 0.000000, -99.027672)
            },
            ["Counterfeit"] = {
                vec3(-1.749023, -8.469482, 1.692268),
                vec3(-47.748093, 0.000001, 160.290359)
            },
            ["Decoration"] = {
                vec3(-0.427734, 0.093994, 1.499977),
                vec3(-16.362019, -0.000008, -21.931940)
            },
            ["Documents"] = {
                vec3(-2.746338, 3.281250, 1.499989),
                vec3(-18.645672, 0.000000, -109.111099)
            },
            ["Furnitures"] = {
                vec3(-5.408691, -4.021973, 1.499985),
                vec3(-15.196832, 0.000003, -28.122103)
            },
            ["GunLocker"] = {
                vec3(-2.841187, -10.524658, 1.692162),
                vec3(-14.157208, 0.000033, -69.790260)
            },
            ["Meth"] = {
                vec3(1.325317, 3.816650, 1.499989),
                vec3(-24.944881, -0.000004, -31.032236)
            },
            -- ["MODBOOTH"] = {
            --     vec3(1.325317, 3.816650, 1.499989),
            --     vec3(-24.944881, -0.000004, -31.032236)
            -- },
            ["Name"] = {
                vec3(-8.799561, 7.378174, 1.499989),
                vec3(-24.850327, 0.000000, -0.644708)
            },
            ["Mural"] = {
                vec3(-2.630005, 0.730957, 1.499996),
                vec3(-16.078577, 0.000009, 125.374260)
            },
            ["Walls"] = {
                vec3(-3.404907, 0.242432, 1.499985),
                vec3(-14.582646, 0.000011, 114.781212)
            },
            ["Weed"] = {
                vec3(-1.827393, 3.640381, 1.499985),
                vec3(-21.196751, 0.000000, -99.027672)
            },

            ["Emblem"] = {
                vec3(1.574585, 6.397949, 1.499989),
                vec3(-12.047222, -0.000001, -1.718581)
            }
        }
    },
    {
        name = 'Clubhouse2',
        ipl = function()
            if not IsDuplicityVersion() then
                return exports.bob74_ipl:GetBikerClubhouse2Object()
            end
        end,
        entry = vec4(997.4394, -3158.2883, -38.9072, 268.2064),
        prices = {
            Walls = 1000,
            Mural = 500
        },
        cams = {
            ["default"] = {
                vec3(13.031616, -6.868164, 6.329758),
                vec3(-13.685032, -0.000001, 147.519897)
            },
            ["Cash"] = {
                vec3(13.764343, 10.062256, 1.500099),
                vec3(-20.015783, -0.000014, 133.533585)
            },
            ["Coke"] = {
                vec3(13.090210, -12.297852, 6.329754),
                vec3(-15.511805, 0.000001, 47.329044)
            },
            ["Counterfeit"] = {
                vec3(9.740051, 8.466309, 1.500092),
                vec3(-33.716557, -0.000000, 94.548538)
            },
            ["Decoration"] = {
                vec3(-0.555542, -10.876953, 1.499889),
                vec3(-6.535428, 0.000000, -42.606255)
            },
            ["Documents"] = {
                vec3(13.207520, 6.060547, 1.500050),
                vec3(-31.543301, 0.000058, 43.827564)
            },
            ["GunLocker"] = {
                vec3(11.331421, -9.191162, 1.500103),
                vec3(-19.133875, -0.000000, -176.784042)
            },
            ["Meth"] = {
                vec3(13.090210, -12.297852, 6.329754),
                vec3(-15.511805, 0.000001, 47.329044)
            },
            ["Emblem"] = {
                vec3(7.699524, 7.088623, 1.500088),
                vec3(-34.456730, -0.000001, -87.359016)
            },
            ["Mural"] = {
                vec3(4.387695, -11.448730, 6.329750),
                vec3(-15.685025, -0.000004, -24.074446)
            },
            ["Name"] = {
                vec3(10.018066, 8.342041, 1.500099),
                vec3(-9.118112, 0.000000, -176.487686)
            },
            ["Walls"] = {
                vec3(13.031616, -6.868164, 6.329758),
                vec3(-13.685032, -0.000001, 147.519897)
            },
            ["Weed"] = {
                vec3(13.090210, -12.297852, 6.329754),
                vec3(-15.511805, 0.000001, 47.329044)
            }
        }
    },
    {
        name = 'Cocaine lockup',
        ipl = function()
            if not IsDuplicityVersion() then
                return exports.bob74_ipl:GetBikerCocaineObject()
            end
        end,
        entry = vec4(1088.5812, -3187.5027, -38.9935, 179.0399),
        prices = {},
        cams = {
            ["default"] = {
                vec3(-33.955444, -46.286377, -0.430717),
                vec3(-15.007881, 0.000002, -55.195946)
            },
            ["Security"] = {
                vec3(-33.955444, -46.286377, -0.430717),
                vec3(-15.007881, 0.000002, -55.195946)
            },
            ["Style"] = {
                vec3(-33.955444, -46.286377, -0.430717),
                vec3(-15.007881, 0.000002, -55.195946)
            },
        }
    },
    {
        name = 'Counterfeit cash factory',
        ipl = function()
            if not IsDuplicityVersion() then
                return exports.bob74_ipl:GetBikerCounterfeitObject()
            end
        end,
        entry = vec4(1138.1580, -3199.1880, -39.6657, 354.3823),
        prices = {},
        cams = {
            ["default"] = {
                vec3(0.503174, 2.760498, 1.500000),
                vec3(-4.740157, 0.000003, 82.707031)
            },
            ["Dryer1"] = {
                vec3(-16.138428, 2.639893, 0.767780),
                vec3(-18.283487, -0.000000, -7.405009)
            },
            ["Dryer2"] = {
                vec3(-14.317749, 2.815430, 0.766930),
                vec3(-19.322849, 0.000000, -3.288164)
            },
            ["Dryer3"] = {
                vec3(-12.351807, 2.837646, 1.499836),
                vec3(-33.732296, -0.000001, 3.165375)
            },
            ["Dryer4"] = {
                vec3(-11.279663, 2.573486, 1.499947),
                vec3(-26.362207, -0.000000, -1.008583)
            },
            ["Printer"] = {
                vec3(-14.940063, 4.216064, 0.763836),
                vec3(-7.685054, -0.000006, -122.444450)
            },
            ["Security"] = {
                vec3(-4.604248, 2.789307, 1.500000),
                vec3(20.472519, -0.000000, 87.135925)
            }
        }
    },
    {
        name = 'Document forgery',
        ipl = function()
            if not IsDuplicityVersion() then
                return exports.bob74_ipl:GetBikerDocumentForgeryObject()
            end
        end,
        entry = vec4(1173.7865, -3196.7373, -39.0080, 91.1098),
        prices = {},
        cams = {
            ["default"] = {
                vec3(-0.000854, 0.063477, 1.500080),
                vec3(-11.622047, -0.000000, 85.613762)
            },
            ["Equipment"] = {
                vec3(-0.486084, -2.329590, 1.500080),
                vec3(-11.763772, -0.000003, 63.226738)
            },
            ["Security"] = {
                vec3(-12.609497, -0.467529, 1.500080),
                vec3(-8.299209, 0.000001, 58.367645)
            },
            ["Style"] = {
                vec3(-0.486084, -2.329590, 1.500080),
                vec3(-11.763772, -0.000003, 63.226738)
            },
        }
    },
    {
        name = 'Meth Lab',
        ipl = function()
            if not IsDuplicityVersion() then
                return exports.bob74_ipl:GetBikerMethLabObject()
            end
        end,
        entry = vec4(996.8154, -3200.7463, -36.3937, 272.8946),
        prices = {},
        cams = {
            ["default"] = {
                vec3(0.265808, 0.111328, 1.500065),
                vec3(-18.897663, 0.000000, -76.174637)
            },
            ["Security"] = {
                vec3(5.889832, 2.864990, -1.099407),
                vec3(-16.677141, 0.000001, -1.392320)
            },
            ["Style"] = {
                vec3(0.265808, 0.111328, 1.500065),
                vec3(-18.897663, 0.000000, -76.174637)
            },
        }
    },
    {
        name = 'Weed Farm',
        ipl = function()
            if not IsDuplicityVersion() then
                return exports.bob74_ipl:GetBikerWeedFarmObject()
            end
        end,
        entry = vec4(1066.2996, -3183.4114, -39.1635, 92.4208),
        prices = {},
        cams = {
            ["default"] = {
                vec3(-18.102661, -23.458252, 2.012066),
                vec3(-4.330711, 0.000003, -47.950912)
            },
            ["Details"] = {
                vec3(-18.697876, -22.864990, 2.176487),
                vec3(-3.307090, 0.000000, -56.348866)
            },
            ["Plant1"] = {
                vec3(-10.634399, -12.089844, 1.502232),
                vec3(-20.409491, -0.000000, 94.319901)
            },
            ["Plant2"] = {
                vec3(-10.595581, -10.870117, 1.502228),
                vec3(-17.102312, -0.000017, 47.593887)
            },
            ["Plant3"] = {
                vec3(-7.839844, -11.782471, 1.502228),
                vec3(-22.377966, -0.000006, 19.971954)
            },
            ["Plant4"] = {
                vec3(-8.876221, -10.022461, 1.502209),
                vec3(-15.433066, 0.000000, -94.572456)
            },
            ["Plant5"] = {
                vec3(-7.330566, -11.590576, 1.502209),
                vec3(-19.417303, 0.000005, -137.169159)
            },
            ["Plant6"] = {
                vec3(-7.474731, -19.584473, 1.512592),
                vec3(-21.496061, -0.000000, -83.424454)
            },
            ["Plant7"] = {
                vec3(-5.594116, -18.133789, 1.513142),
                vec3(-14.787374, -0.000004, 149.706604)
            },
            ["Plant8"] = {
                vec3(-4.841553, -20.660156, 1.619110),
                vec3(-18.204739, 0.000002, 44.516544)
            },
            ["Plant9"] = {
                vec3(-17.150146, -20.529541, 1.502396),
                vec3(-22.913359, 0.000005, -31.881327)
            },
        }
    },
    -- dlc_afterhours
    {
        name = 'Nightclub',
        ipl = function()
            if not IsDuplicityVersion() then
                return exports.bob74_ipl:GetAfterHoursNightclubsObject()
            end
        end,
        entry = vec4(-1569.3912, -3017.6309, -74.4062, 2.2517),
        prices = {},
        cams = {
            ["default"] = {
                vec3(-31.340332, 8.751465, -1.889908),
                vec3(-10.409422, -0.000001, -126.934563)
            },
            ["Speakers"] = {
                vec3(-28.864990, -0.661865, -3.099922),
                vec3(-17.716518, -0.000000, 25.772575)
            },
            ["DryIce"] = {
                vec3(-31.893677, 4.809082, -2.428665),
                vec3(-21.795261, -0.000000, -87.223984)
            },
            ["Name"] = {
                vec3(-29.078979, 2.573486, -2.297157),
                vec3(-1.165355, -0.000000, 162.326355)
            },
            ["Podium"] = {
                vec3(-32.088379, 6.681152, -2.432602),
                vec3(-29.433098, 0.000005, -104.658852)
            },
        }
    },
    -- dlc_casino
    {
        name = 'Penthouse',
        ipl = function()
            if not IsDuplicityVersion() then
                return exports.bob74_ipl:GetDiamondPenthouseObject()
            end
        end,
        entry = vec4(980.6793, 56.5234, 116.1642, 51.8893),
        prices = {},
        cams = {
            ["Arcade"] = {
                vec3(-33.003418, -30.753109, 2.005951),
                vec3(-10.314957, 0.000006, 166.726044)
            },
            ["BarLight"] = {
                vec3(-35.019470, -32.856720, 1.499931),
                vec3(-17.023611, -0.000000, -152.650833)
            },
            ["BarParty"] = {
                vec3(-22.242981, -33.733498, 1.500038),
                vec3(-25.606298, -0.000000, 100.788895)
            },
            ["Clutter"] = {
                vec3(-38.675598, -44.476105, 1.500008),
                vec3(-17.810965, 0.000006, -60.494171)
            },
            ["Pattern"] = {
                vec3(-21.603149, -33.731148, 1.500061),
                vec3(-18.393681, -0.000000, 95.433678)
            },
            ["SpaBar"] = {
                vec3(-35.116028, -54.814663, 1.500198),
                vec3(-11.370071, -0.000002, -60.375065)
            },

            -- Blockers
            ["Lounge"] = {
                vec3(-9.213501, -6.133350, 1.499985),
                vec3(-10.472439, -0.000000, 103.123711)
            },
            ["Bar"] = {
                vec3(-22.933655, -32.898399, 1.500031),
                vec3(-10.078739, -0.000004, 105.138397)
            },
            ["Spa"] = {
                vec3(-35.654358, -54.373848, 1.500023),
                vec3(-11.275569, 0.000003, -65.096519)
            },
        }
    },
    -- dlc_cayoperico
    {
        name = 'The Music Locker',
        ipl = function()
            if not IsDuplicityVersion() then
                return exports.bob74_ipl:GetCayoPericoNightclub()
            end
        end,
        entry = vec4(1545.2987, 254.1307, -46.0061, 0.6308),
        prices = {},
        cams = {
            ["default"] = {
                vec3(17.594971, -4.161438, -1.499908),
                vec3(0.362205, -0.000000, 85.865517)
            },
            ["Speakers"] = {
                vec3(14.056519, -6.408310, -1.499897),
                vec3(-13.007869, 0.000003, 69.147125)
            },
            ["Turntables"] = {
                vec3(5.370483, -2.505600, -1.165714),
                vec3(-28.551167, 0.000004, 149.486328)
            },
            ["Lights"] = {
                vec3(17.594971, -4.161438, -1.499908),
                vec3(0.362205, -0.000000, 85.865517)
            },
        }
    },
    --   dlc_doomsday
    {
        name = 'DoomsdayFacility',
        distance = 200,
        ipl = function()
            if not IsDuplicityVersion() then
                return exports.bob74_ipl:GetDoomsdayFacilityObject()
            end
        end,
        entry = vec4(325.9854, 4882.3374, -58.9995, 129.2806),
        prices = {},
        cams = {
            ["default"] = {
                vec3(6.226379, -19.386719, 1.500675),
                vec3(-12.362168, 0.000007, -119.736244)
            },
            ["Decals"] = {
                vec3(6.226379, -19.386719, 1.500675),
                vec3(-12.362168, 0.000007, -119.736244)
            },
            ["Lounge"] = {
                vec3(31.637207, -41.053711, 1.500164),
                vec3(-8.787397, -0.000000, -78.813431)
            },

        }
    },
    -- dlc_executive
    {
        name = 'Apartment 1',
        ipl = function()
            if not IsDuplicityVersion() then
                return exports.bob74_ipl:GetExecApartment1Object()
            end
        end,
        entry = vec4(-787.4127, 315.6659, 217.6386, 267.6566),
        prices = {},
        cams = {
            ["default"] = {
                vec3(-0.402161, 4.363556, 1.099731),
                vec3(-11.685048, 0.000000, -6.687452)
            },
            ["Theme"] = {
                vec3(-0.402161, 4.363556, 1.099731),
                vec3(-11.685048, 0.000000, -6.687452)
            },
        }
    },
    {
        name = 'Apartment 2',
        ipl = function()
            if not IsDuplicityVersion() then
                return exports.bob74_ipl:GetExecApartment2Object()
            end
        end,
        entry = vec4(-773.5239, 341.9679, 196.6861, 91.4199),
        prices = {},
        cams = {
            ["default"] = {
                vec3(0.792419, -3.642334, 0.899948),
                vec3(-11.732276, -0.000001, 163.869247)
            },
            ["Theme"] = {
                vec3(0.792419, -3.642334, 0.899948),
                vec3(-11.732276, -0.000001, 163.869247)
            },
        }
    },
    {
        name = 'Apartment 3',
        ipl = function()
            if not IsDuplicityVersion() then
                return exports.bob74_ipl:GetExecApartment3Object()
            end
        end,
        entry = vec4(-787.4062, 315.6622, 187.9134, 272.1406),
        prices = {},
        cams = {
            ["default"] = {
                vec3(-1.212769, 4.281219, 0.899872),
                vec3(-12.362197, -0.000007, -14.306152)
            },
            ["Theme"] = {
                vec3(-1.212769, 4.281219, 0.899872),
                vec3(-12.362197, -0.000007, -14.306152)
            },
        }
    },
    -- dlc_finance
    {
        name = 'Office 1 (Arcadius Business Centre)',
        ipl = function()
            if not IsDuplicityVersion() then
                return exports.bob74_ipl:GetFinanceOffice1Object()
            end
        end,
        entry = vec4(-139.4779, -617.4788, 168.8203, 99.2815),
        prices = {},
        cams = {
            default = {
                vec3(-2.685471, -29.212402, 1.500244),
                vec3(-9.732275, -0.000001, -47.753563)
            },
            Chairs = {
                vec3(14.240433, -21.827820, 1.500031),
                vec3(-25.244102, -0.000000, 166.218903)
            },
            Safe = {
                vec3(13.926224, -25.546814, 1.499985),
                vec3(-31.842405, -0.000006, -49.351467)
            },
            Name = {
                vec3(-0.013626, -13.632446, 1.500229),
                vec3(-3.244094, 0.000000, -175.154037)
            }
        }
    },
    {
        name = 'Office 2 (Maze Bank Building)',
        ipl = function()
            if not IsDuplicityVersion() then
                return exports.bob74_ipl:GetFinanceOffice2Object()
            end
        end,
        entry = vec4(-78.9695, -829.3524, 243.3857, 252.6773),
        prices = {},
        cams = {
            ["default"] = {
                vec3(15.179649, 25.071045, 1.500275),
                vec3(-20.708628, -0.000001, 108.556511)
            },
            ["Chairs"] = {
                vec3(-3.667770, 26.237671, 1.515045),
                vec3(-27.779518, -0.000001, -47.350067)
            },
            ["Safe"] = {
                vec3(-0.234772, 27.131348, 1.515030),
                vec3(-12.377951, -0.000003, 67.137482)
            },
            ["Name"] = {
                vec3(5.958351, 13.433533, 1.500275),
                vec3(-2.944884, -0.000000, -23.562487)
            },
        }
    },
    {
        name = 'Office 3 (Lom Bank)',
        ipl = function()
            if not IsDuplicityVersion() then
                return exports.bob74_ipl:GetFinanceOffice3Object()
            end
        end,
        entry = vec4(-1579.5333, -561.0135, 108.5229, 134.1342),
        prices = {},
        cams = {
            ["default"] = {
                vec3(12.212036, -26.656372, 1.520218),
                vec3(-12.440938, -0.000001, -20.412449)
            },
            ["Name"] = {
                vec3(7.000488, -11.779114, 1.500076),
                vec3(-5.527551, 0.000001, -144.066498)
            },
            ["Chairs"] = {
                vec3(22.190918, -12.847412, 1.504272),
                vec3(-40.693096, -0.000046, -133.212555)
            },
            ["Safe"] = {
                vec3(22.187012, -14.558594, 1.504272),
                vec3(-15.039364, -0.000002, -63.512920)
            },
        }
    },
    {
        name = 'Office 4 (Maze Bank West)',
        ipl = function()
            if not IsDuplicityVersion() then
                return exports.bob74_ipl:GetFinanceOffice4Object()
            end
        end,
        entry = vec4(-1396.3055, -478.6074, 72.0421, 193.9121),
        prices = {},
        cams = {
            ["default"] = {
                vec3(29.376953, -1.671844, 1.500099),
                vec3(-10.803148, -0.000000, 45.172760)
            },
            ["Chairs"] = {
                vec3(20.522705, 15.416870, 1.500099),
                vec3(-20.897652, 0.000000, -112.553909)
            },
            ["Name"] = {
                vec3(14.286377, 0.756561, 1.500114),
                vec3(-0.031496, -0.000000, -79.994965)
            },
            ["Safe"] = {
                vec3(23.520996, 11.248047, 1.500099),
                vec3(-10.141722, 0.000005, -3.478549)
            },
        }
    },
    -- dlc_highlife
    -- cam
    {
        name = 'Apartment 1 (Dell Perro Heights, Apt 4)',
        ipl = function()
            if not IsDuplicityVersion() then
                return exports.bob74_ipl:GetHLApartment1Object()
            end
        end,
        entry = vec4(-1452.1353, -540.7191, 74.0443, 33.9719),
        prices = {},
    },
    {
        name = 'Apartment 2 (Richard Majestic, Apt 2)',
        ipl = function()
            if not IsDuplicityVersion() then
                return exports.bob74_ipl:GetHLApartment2Object()
            end
        end,
        entry = vec4(-912.3753, -365.0459, 114.2748, 118.4509),
        prices = {},
    },
    {
        name = 'Apartment 3 (Tinsel Towers, Apt 42)',
        ipl = function()
            if not IsDuplicityVersion() then
                return exports.bob74_ipl:GetHLApartment3Object()
            end
        end,
        entry = vec4(-602.8840, 58.9586, 98.2002, 93.4696),
        prices = {},
    },
    {
        name = 'Apartment 4 (EclipseTowers, Apt 3)',
        ipl = function()
            if not IsDuplicityVersion() then
                return exports.bob74_ipl:GetHLApartment4Object()
            end
        end,
        entry = vec4(-785.1733, 323.7633, 211.9971, 269.4448),
        prices = {},
    },
    {
        name = 'Apartment 5 (4 Integrity Way, Apt 28)',
        ipl = function()
            if not IsDuplicityVersion() then
                return exports.bob74_ipl:GetHLApartment5Object()
            end
        end,
        entry = vec4(-785.1733, 323.7633, 211.9971, 269.4448),
        prices = {},
    },
    {
        name = 'Apartment 6',
        ipl = function()
            if not IsDuplicityVersion() then
                return exports.bob74_ipl:GetHLApartment5Object()
            end
        end,
        entry = vec4(-602.9776, 58.8669, -182.3809, 93.2367),
        prices = {},
    },
    -- cam
    -- dlc_import
    {
        name = 'Vehicle warehouse',
        ipl = function()
            if not IsDuplicityVersion() then
                return exports.bob74_ipl:GetImportVehicleWarehouseObject()
            end
        end,
        entry = vec4(1004.8318, -2992.3586, -39.6470, 92.5176), -- upper
        prices = {},
        cams = {
            ["default"] = {
                vec3(-1.330017, -0.096924, 1.500061),
                vec3(-3.732291, 0.000000, 109.345993)
            },
        }
    },
    -- dlc_smuggler
    {
        name = 'SmugglerHangar',
        ipl = function()
            if not IsDuplicityVersion() then
                return exports.bob74_ipl:GetSmugglerHangarObject()
            end
        end,
        entry = vec4(-1267.0985, -3012.9551, -48.4902, 357.4053),
        prices = {},
        cams = {
            ["default"] = {
                vec3(0.762573, 43.431152, 1.500698),
                vec3(6.582685, 0.000000, 179.144196)
            },
            ["Office"] = {
                vec3(26.699585, -1.704102, 7.102959),
                vec3(-10.346466, -0.000005, -22.203165)
            },
            ["Walls"] = {
                vec3(-2.057617, -33.830078, 1.499352),
                vec3(1.716538, -0.000000, -1.137951)
            },
            ["Floor.Style"] = {
                vec3(-23.875000, -8.795654, 5.903801),
                vec3(-17.637787, -0.000013, -70.561859)
            },
            ["Bedroom.Blinds"] = {
                vec3(32.673096, 22.470215, 8.716915),
                vec3(-13.228348, 0.000007, 16.143280)
            },
            ["Bedroom.Style"] = {
                vec3(34.862671, 26.779541, 8.719479),
                vec3(-18.850357, 0.000005, 58.443813)
            },
        }
    },
    -- gta_online
    -- cam
    {
        name = 'High end apartment 1',
        ipl = function()
            if not IsDuplicityVersion() then
                return exports.bob74_ipl:GetGTAOApartmentHi1Object()
            end
        end,
        entry = vec4(-18.2889, -590.9544, 90.1147, 334.6050),
        prices = {},
    },
    {
        name = 'High end apartment 2',
        ipl = function()
            if not IsDuplicityVersion() then
                return exports.bob74_ipl:GetGTAOApartmentHi2Object()
            end
        end,
        entry = vec4(-1450.0377, -525.8071, 56.9290, 33.0834),
        prices = {},
    },
    {
        name = 'High end house 1',
        ipl = function()
            if not IsDuplicityVersion() then
                return exports.bob74_ipl:GetGTAOHouseHi1Object()
            end
        end,
        entry = vec4(-174.3500, 497.8789, 137.6535, 189.5455),
        prices = {},
    },
    {
        name = 'High end house 2',
        ipl = function()
            if not IsDuplicityVersion() then
                return exports.bob74_ipl:GetGTAOHouseHi2Object()
            end
        end,
        entry = vec4(342.2078, 437.9602, 149.3806, 104.9856),
        prices = {},
    },
    {
        name = 'High end house 3',
        ipl = function()
            if not IsDuplicityVersion() then
                return exports.bob74_ipl:GetGTAOHouseHi3Object()
            end
        end,
        entry = vec4(373.7228, 423.9125, 145.8997, 170.3039),
        prices = {},
    },
    {
        name = 'High end house 4',
        ipl = function()
            if not IsDuplicityVersion() then
                return exports.bob74_ipl:GetGTAOHouseHi4Object()
            end
        end,
        entry = vec4(-682.5748, 592.7130, 145.3795, 222.5850),
        prices = {},
    },
    {
        name = 'High end house 5',
        ipl = function()
            if not IsDuplicityVersion() then
                return exports.bob74_ipl:GetGTAOHouseHi5Object()
            end
        end,
        entry = vec4(-758.1348, 619.1015, 144.1405, 111.8842),
        prices = {},
    },
    {
        name = 'High end house 6',
        ipl = function()
            if not IsDuplicityVersion() then
                return exports.bob74_ipl:GetGTAOHouseHi6Object()
            end
        end,
        entry = vec4(-859.8599, 691.4716, 152.8525, 186.1947),
        prices = {},
    },
    {
        name = 'High end house 7',
        ipl = function()
            if not IsDuplicityVersion() then
                return exports.bob74_ipl:GetGTAOHouseHi7Object()
            end
        end,
        entry = vec4(117.2493, 560.1372, 184.2967, 188.7763),
        prices = {},
    },
    {
        name = 'High end house 8',
        ipl = function()
            if not IsDuplicityVersion() then
                return exports.bob74_ipl:GetGTAOHouseHi8Object()
            end
        end,
        entry = vec4(-1289.9720, 449.9252, 97.8944, 183.8566),
        prices = {},
    },
    {
        name = 'Middle end house 1',
        ipl = function()
            if not IsDuplicityVersion() then
                return exports.bob74_ipl:GetGTAOHouseMid1Object()
            end
        end,
        entry = vec4(346.6476, -1013.2401, -99.1963, 0.7962),
        prices = {},
    },
    -- cam
}


-- dlc_tuner GAME BUILD  3258
if GetGameBuildNumber() >= 3258 then
    CustomizeIPL[#CustomizeIPL + 1] = {
        name = 'Bail office',
        ipl = function()
            if not IsDuplicityVersion() then
                return exports.bob74_ipl:GetSummerOfficeObject()
            end
        end,
        entry = vec4(570.3802, -2675.7354, -49.0000, 91.3974),
        prices = {},
        cams = {
            ["default"] = {
                vec3(-4.133240, -11.751709, 1.502033),
                vec3(-15.496059, -0.000001, 134.783920)
            },
            ["Desk"] = {
                vec3(-3.665283, -11.211914, 1.501938),
                vec3(-16.881882, -0.000002, 138.434128)
            },
            ["Gunsafe"] = {
                vec3(-6.753540, -26.068848, 1.502033),
                vec3(-21.842518, 0.000001, -23.835991)
            },
            ["Style"] = {
                vec3(-4.487610, -11.698242, 1.501953),
                vec3(-39.795307, 0.000003, 152.981125)
            },

        }
    }
end

-- dlc_drugwars GAME BUILD 2802
if GetGameBuildNumber() >= 2802 then
    CustomizeIPL[#CustomizeIPL + 1] = {
        name = 'Freakshop',
        ipl = function()
            if not IsDuplicityVersion() then
                return exports.bob74_ipl:GetDrugWarsFreakshopObject()
            end
        end,
        entry = vec4(555.6788, -433.1870, -69.6471, 283.7341),
        prices = {},
        cams = {
            ["default"] = {
                vec3(11.433350, 8.086578, 1.500092),
                vec3(-5.322840, 0.000000, -78.396065)
            },
            ["Door"] = {
                vec3(11.433350, 8.086578, 1.500092),
                vec3(-5.322840, 0.000000, -78.396065)
            },
        }
    }
    CustomizeIPL[#CustomizeIPL + 1] = {
        name = 'Eclipse Boulevard Garage',
        ipl = function()
            if not IsDuplicityVersion() then
                return exports.bob74_ipl:GetDrugWarsGarageObject()
            end
        end,
        entry = vec4(531.8565, -2637.7612, -49.0000, 86.1326),
        prices = {},
        cams = {
            ["default"] = {
                vec3(-12.262939, -1.916016, 1.500122),
                vec3(-5.637799, 0.000000, 0.324455)
            },
            ["Numbering"] = {
                vec3(-13.519348, 16.690674, 1.500122),
                vec3(0.000000, -0.000000, 91.329704)
            },
            ["Style"] = {
                vec3(-12.262939, -1.916016, 1.500122),
                vec3(-5.637799, 0.000000, 0.324455)
            },
        }
    }
    CustomizeIPL[#CustomizeIPL + 1] = {
        name = 'Acid Lab',
        ipl = function()
            if not IsDuplicityVersion() then
                return exports.bob74_ipl:GetDrugWarsLabObject()
            end
        end,
        entry = vec4(482.5064, -2625.8789, -49.0640, 356.6367),
        prices = {},
        cams = {
            ["default"] = {
                vec3(-0.620575, 0.716064, 1.899899),
                vec3(-37.401634, 0.000001, -89.487061)
            },
        }
    }
end

-- dlc_mercenaries GAME BUILD 2944
if GetGameBuildNumber() >= 2944 then
    CustomizeIPL[#CustomizeIPL + 1] = {
        name = 'Vinewood Car Club',
        ipl = function()
            if not IsDuplicityVersion() then
                return exports.bob74_ipl:GetMercenariesClubObject()
            end
        end,
        entry = vec4(1180.8115, -3261.0137, -47.9999, 1.7485),
        prices = {},
        cams = {
            ["default"] = {
                vec3(31.463989, 8.174072, 0.502117),
                vec3(-5.385824, 0.000000, 85.646378)
            },

        }
    }
    CustomizeIPL[#CustomizeIPL + 1] = {
        name = 'Fort Zancudo Lab',
        ipl = function()
            if not IsDuplicityVersion() then
                return exports.bob74_ipl:GetMercenariesLabObject()
            end
        end,
        entry = vec4(-1922.3163, 3749.7444, -99.6459, 266.2562),
        prices = {},
    }
end

-- dlc_chopshop GAME BUILD 3095
if GetGameBuildNumber() >= 3095 then
    CustomizeIPL[#CustomizeIPL + 1] = {
        name = 'Cartel Garage',
        ipl = function()
            if not IsDuplicityVersion() then
                return exports.bob74_ipl:GetChopShopCartelGarageObject()
            end
        end,
        entry = vec4(1203.3193, -2297.6094, -47.8996, 277.7933),
        prices = {},
    }
    CustomizeIPL[#CustomizeIPL + 1] = {
        name = 'Salvage Yard',
        ipl = function()
            if not IsDuplicityVersion() then
                return exports.bob74_ipl:GetChopShopSalvageObject()
            end
        end,
        entry = vec4(1098.5929, -2266.0334, -48.9999, 183.2450),
        prices = {},
        cams = {
            ["default"] = {
                vec3(1.889893, -1.884033, 1.500027),
                vec3(-3.275591, -0.000000, 126.543671)
            },
            ["Lift1"] = {
                vec3(-14.588379, -9.515625, 1.500027),
                vec3(-21.606302, -0.000000, 13.515335)
            },
            ["Lift2"] = {
                vec3(-9.974365, -9.501953, 1.500023),
                vec3(-11.133862, -0.000000, -6.950900)
            },
        }
    }
end

if GetGameBuildNumber() >= 3407 then
    -- dlc_agents -- GAME BUILD 3407
    CustomizeIPL[#CustomizeIPL + 1] = {
        name = 'Garment Factory',
        ipl = function()
            if not IsDuplicityVersion() then
                return exports.bob74_ipl:GetAgentsFactory()
            end
        end,
        entry = vec4(755.4099, -998.0137, -46.3767, 93.6736),
        prices = {},
        cams = {
            ["default"] = {
                vec3(-2.297241, -0.398499, 1.499973),
                vec3(-13.244090, 0.000001, 51.855770)
            },
        }
    }
    CustomizeIPL[#CustomizeIPL + 1] = {
        name = 'McKenzie Field Hangar Office',
        ipl = function()
            if not IsDuplicityVersion() then
                return exports.bob74_ipl:GetAgentsOffice()
            end
        end,
        entry = vec4(2147.2131, 4789.7134, -46.3750, 186.3166),
        prices = {},
        cams = {
            ["default"] = {
                vec3(-0.644775, -0.103516, 1.500095),
                vec3(-10.393687, 0.000001, -127.782234)
            },
        }
    }
end
