---@class FloorData
---@field coords vector4
---@field label? string
---@field groups? string|string[]|table<string, number>
---@field allowVehicle? boolean

---@alias FloorId string

return { ---@type table<FloorId, FloorData[]>
    gzcafe = {
        {
            coords = vec(-2173.6868, 4269.8101, 48.7537, 58.7878),
            label = 'Lift Dasar',
        },
        {
            coords = vec(-2175.3428, 4260.9551, 63.2114, 70.8499),
            label = 'Lift Rooftop',
        },
    },
    gokudo = {
        {
            coords = vec(-831.1979, 7143.3096, 93.8314, 329.0051),
            label = "Gokudo | Entrance",
            groups = "gokudosm"
        },
        {
            coords = vec(-1399.8624, 7740.9521, 3.6580, 255.2190),
            label = "Gokudo | Interior",
            groups = "gokudosm"
        },
    },
    Elysium_rxwd = {
        {
            coords = vec(-489.5315, 7432.1128, 5.2728, 359.2920),
            label = '1',
        },
        {
            coords = vec(275.4758, -1361.0736, 24.5378, 56.5714),
            label = '2',
        },
    },
    SmMotel = {
        {
            coords = vec(-824.8837, -713.1915, 28.0620, 269.9499),
            label = 'G',
        },
        {
            coords = vec(-820.7907, -713.2260, 46.9162, 269.5026),
            label = '1',
        },
        {
            coords = vec(-820.5952, -713.2378, 81.7834, 265.9089),
            label = '2',
        },
        {
            coords = vec(-820.3982, -713.2485, 113.3164, 265.9817),
            label = '3'
        },
        {
            coords = vec(-814.9254, -695.6044, 121.2720, 178.9804),
            label = 'Rooftop'
        },
    },
    Casino = {
        {
            coords = vec(949.7870, 57.1249, 59.8751, 239.3621),
            label = 'Vault',
            groups = {'velvetsm', 'hightable'}
        },
        {
            label = 'Ground Floor',
            coords = vec(977.4416, 73.8329, 70.2331, 147.9837),
        },
        {
            coords = vec(976.6246, 72.4389, 75.4326, 149.7039),
            label = 'Staff',
            groups = 'velvetsm'
        },
        {
            coords = vec(967.1696, 16.0575, 71.8398, 238.0534),
            label = 'Office',
            groups = 'velvetsm'
        },
        {
            coords = vec(953.2419, 58.5261, 75.4327, 236.7690),
            label = 'Boss',
            groups = 'velvetsm'
        },
        {
            coords = vec(965.1028, 58.3902, 112.5529, 239.3764),
            label = 'Roog Top',
        },
        {
            coords = vec(971.7081, 51.4968, 120.2408, 325.3578),
            label = 'Helipad'
        }
    },

    -- Migrated Elevators from sm_smallresources
    Mercenary = {
        {
            coords = vec(-857.2041, -1282.3889, 6.2004, 201.2796),
            label = "Mercenary | Entrance",
            groups = "mercenarysm"
        },
        {
            coords = vec(2154.5696, 2921.0901, -84.8000, 168.1454),
            label = "Mercenary | Interior",
            groups = "mercenarysm"
        },
        {
            coords = vec(-1643.0641, -1047.2303, 13.3066, 144.0987),
            label = "Mercenary | Entrance 2",
            groups = "mercenarysm"
        },
        {
            coords = vec(2168.7249, 2921.0671, -84.8001, 276.8612),
            label = "Mercenary | Interior 2",
            groups = "mercenarysm"
        },
        {
            coords = vec(5085.5273, -5731.9121, 15.7726, 327.5166),
            label = "Mercenary | Entrance 3",
            groups = "mercenarysm"
        },
        {
            coords = vec(4493.8535, -4525.7129, 4.4124, 292.7070),
            label = "Mercenary | Entrance 4",
            groups = "mercenarysm"
        },
        {
            coords = vec(-342.4688, 6097.6587, 31.3102, 40.4731),
            label = "Mercenary | Entrance 5",
            groups = "mercenarysm"
        },
        {
            coords = vec(-3848.7634, 2579.4675, 23.2733, 278.1744),
            label = "Mercenary | Entrance 6",
            groups = "mercenarysm"
        },
        {
            coords = vec(-1901.8748, 2910.6443, 32.8119, 65.8566),
            label = "Mercenary | Entrance 7",
            groups = "mercenarysm"
        },
    },

    PolicePelabuhan = {
        {
            coords = vec(-546.8730, -2401.8044, 14.7687, 318.5647),
            label = "Police Lt 1"
        },
        {
            coords = vec(-549.2260, -2400.6848, 18.1713, 327.8445),
            label = "Police Lt 2"
        },
        {
            coords = vec(-550.1651, -2401.7070, 21.6221, 321.9371),
            label = "Police Lt 3"
        },
    },

    HighTable = {
        {
            coords = vec(94.2545, -2694.0889, 6.0002, 355.3846),
            label = "EC1",
            allowVehicle = true,
            -- groups = { "hightable", "studentht" }
        },
        {
            coords = vec(2147.9009, 2921.0327, -61.9020, 88.2586),
            label = "EC2",
            allowVehicle = true,
            -- groups = { "hightable", "studentht" }
        },
        {
            coords = vec(2060.3188, 2992.5229, -72.7020, 207.8783),
            label = "EC3",
            allowVehicle = true,
            groups = { "hightable", "studentht" }
        },
    },

    CayoUnderground = {
        {
            coords = vec(4994.7700, -5778.2524, 16.4059, 327.8521),
            label = "Cayo Ground",
            allowVehicle = true,
            groups = { "mercenarysm", "velvetsm", "hightable" }
        },
        {
            coords = vec(895.5493, -3246.0068, -98.2583, 90.7433),
            label = "Cayo UnderGround",
            allowVehicle = true,
            groups = { "mercenarysm", "velvetsm", "hightable" }
        },
    },

    PublicElevator1 = {
        {
            coords = vec(-2024.0709, 3161.5769, 32.8103, 328.1797),
            label = "Public 1",
            allowVehicle = true
        },
        {
            coords = vec(-2019.8564, 3168.2996, 32.8103, 324.7558),
            label = "Public 2",
            allowVehicle = true
        },
    },

    PublicElevator2 = {
        {
            coords = vec(-1369.7444, -176.2709, 47.4662, 265.7498),
            label = "Public lt1"
        },
        {
            coords = vec(-1569.4077, -3017.2598, -74.4062, 1.4271),
            label = "Public lt2"
        },
    },

    PublicLt = {
        {
            coords = vec(-291.7991, -985.5003, 24.1370, 341.1139),
            label = "lt1",
            allowVehicle = true
        },
        {
            coords = vec(-2220.5503, 1157.1420, -23.2592, 214.9688),
            label = "lt2",
            allowVehicle = true
        },
    },

    RainhartCafe = {
        {
            coords = vec(-280.4334, 6672.2490, 13.2595, 315.5233),
            label = "RainhartCafe | Lift 2"
        },
        {
            coords = vec(-280.3636, 6672.3223, 20.3701, 313.6346),
            label = "RainhartCafe | Rooftop"
        },
    },

    -- SMSPLift1 = {
    --     {
    --         coords = vec(136.0378, -761.8582, 45.7520, 159.0122),
    --         label = "SMSP | Lift 1"
    --     },
    --     {
    --         coords = vec(136.1371, -761.7737, 242.1519, 160.6100),
    --         label = "SMSP | Main Room"
    --     },
    --     {
    --         coords = vec(156.9475, -757.2186, 258.1517, 167.0432),
    --         label = "SMSP | Ruang Rapat"
    --     },
    -- },

    -- SMSPLift2 = {
    --     {
    --         coords = vec(139.0099, -762.7585, 45.7520, 158.1795),
    --         label = "SMSP | Lift 2"
    --     },
    --     {
    --         coords = vec(-141.5489, -620.9720, 168.8203, 277.9219),
    --         label = "SMSP | Office Arcadius"
    --     },
    --     {
    --         coords = vec(114.7921, -742.0649, 258.1522, 161.3173),
    --         label = "SMSP | lt. 2 Office Arcadius"
    --     },
    --     {
    --         coords = vec(141.1881, -734.8123, 262.8516, 162.4541),
    --         label = "SMSP | Helipad"
    --     },
    -- },

    HospitalLiftAB = {
        {
            coords = vec(-543.3699, 7394.4473, 12.8352, 230.3873),
            label = "Hospital | Lift A"
        },
        {
            coords = vec(-547.1545, 7394.8740, 8.5192, 51.1741),
            label = "Hospital | Lift B"
        },
    },

    RSKOTA = {
        {
            coords = vec(1143.4901, -1578.4948, 30.3575, 354.1278),
            label = "Hospital | Basement"
        },
        {
            coords = vec(1143.8225, -1578.2003, 34.8449, 338.9414),
            label = "Hospital | 1st Floor"
        },
        {
            coords = vec(1143.9115, -1578.3237, 39.3320, 3.5041),
            label = "Hospital | 2nd Floor"
        },
        {
            coords = vec(1142.1573, -1563.7833, 48.1472, 100.5306),
            label = "Hospital | Rooftop"
        },
    },

    VehicleTeleport = {
        {
            coords = vec(540.6631, -3063.6233, 6.0808, 88.7896),
            label = "Vehicle Teleport | Ground",
            allowVehicle = true
        },
        {
            coords = vec(556.2729, -3067.4580, -1.9237, 96.2212),
            label = "Vehicle Teleport | Basement",
            allowVehicle = true
        }
    },

    DeveruxMansion = {
        {
            coords = vec(3111.4717, 5202.4053, 7.4623, 293.9995),
            label = "Bunker"
        },
        {
            coords = vec(3494.0466, 5321.8901, 19.5398, 22.4198),
            label = "Ruang Tamu"
        },
        {
            coords = vec(3494.0344, 5321.9111, 26.0445, 24.0682),
            label = "Lantai 2"
        },
        {
            coords = vec(3533.7356, 5358.0259, 38.5416, 110.8633),
            label = "Rooftop"
        },
    },

    RoelsPenthouse = {
        {
            coords = vec(-614.5620, 46.6774, 43.5915, 179.3668),
            label = "Lobby"
        },
        {
            coords = vec(-610.4988, 45.6566, 129.2771, 270.6614),
            label = "Penthouse"
        },
    },

    liftyclub = {
        {
            coords = vec(87.3111, 6509.8481, 31.4722, 219.7667),
            label = "Lobby"
        },
        {
            coords = vec(72.1692, 6492.1299, 44.8155, 315.8209),
            label = "Rooftop"
        },
    },
}