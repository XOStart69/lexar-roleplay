---@alias ShopType "clothing" | "barber" | "tattoo" | "surgeon"

---@class ShopZone
---@field type string
---@field coords vector4
---@field size vector3?
---@field rotation number?
---@field points vector3[]?
---@field job RequireJobs?
---@field gang RequireJobs?
---@field identifiers string[]?
---@field showBlip boolean?

---@class ShopConfig
---@field debug boolean
---@field disabledTypes table<string, boolean>?
---@field account string
---@field icons table<string, string>
---@field costs table<string, number>
---@field blips table<string, table>
---@field stores ShopZone[]
---@field clothingRooms ShopZone[]
---@field outfitRooms ShopZone[]
---@field jobOutfits table<string, table[]>
return {
    debug = false,

    disabledTypes = {
        barber = true
    },

    account = "cash",

    icons = {
        clothing = "fa-solid fa-shirt",
        barber = "fa-solid fa-scissors",
        tattoo = "fa-solid fa-pen-nib",
        surgeon = "fa-solid fa-user-doctor",
        clothingRoom = "fa-solid fa-user-tie",
        outfitRoom = "fa-solid fa-hanger"
    },

    costs = {
        clothing = 2500,
        barber = 5000,
        tattoo = 10000,
        surgeon = 5000
    },

    blips = {
        clothing = { show = true, sprite = 366, color = 47, scale = 0.7 },
        barber = { show = true, sprite = 71, color = 0, scale = 0.7 },
        tattoo = { show = true, sprite = 75, color = 4, scale = 0.7 },
        surgeon = { show = true, sprite = 102, color = 4, scale = 0.7 }
    },

    stores = {
        --- Donasi ALICE Mansion
        {
            type = "clothing",
            coords = vector4(1838.2964, -2319.9143, 148.5782, 84.7853),
            size = vector3(4, 4, 4),
            rotation = 45,
            showBlip = false, -- overrides the blip visibilty configured above for the group
            
        },
        --- Rooxwood baru
        {
            type = "clothing",
            coords = vector4(-330.5125, 8459.5801, 4.9797, 0.0000),
            size = vector3(5, 5, 5),
            rotation = 45,
            showBlip = true, -- overrides the blip visibilty configured above for the group
        },

        --- Gokudo New Locations
        {
            type = "clothing",
            coords = vector4(-4749.8320, 8870.3096, 75.9985, 137.2027),
            size = vector3(3, 3, 3),
            rotation = 45,
            showBlip = false, -- overrides the blip visibilty configured above for the group
            
        },
        --- MG MANSION
        {
            type = "clothing",
            coords = vector4(-2340.9587, 4394.9204, 19.3436, 342.1779),
            size = vector3(4, 4, 4),
            rotation = 45,
            showBlip = false, -- overrides the blip visibilty configured above for the group
            
        },
        --- MG MANSION
        {
            type = "barber",
            coords = vector4(-2346.8899, 4398.2510, 19.3436, 249.5910),
            size = vector3(4, 4, 4),
            rotation = 45,
            showBlip = false, -- overrides the blip visibilty configured above for the group
            
        },
        --- sasp police
        {
            type = "clothing",
            coords = vector4(2444.0122, 1600.2743, 30.0666, 268.5067),
            size = vector3(5, 5, 5),
            rotation = 45,
            showBlip = false, -- overrides the blip visibilty configured above for the group
            
        },
        --- MG MANSION
        {
            type = "barber",
            coords = vector4(1404.1460, -771.7277, 66.7173, 73.6125),
            size = vector3(4, 4, 4),
            rotation = 45,
            showBlip = false, -- overrides the blip visibilty configured above for the group
            
        },
        --MG MANSION
        {
            type = "clothing",
            coords = vector4(1405.2981, -768.1401, 66.7173, 76.6551),
            size = vector3(3, 3, 3),
            rotation = 45,
            showBlip = false, -- overrides the blip visibilty configured above for the group
            
        },

        --- MG ISLAND
        {
            type = "barber",
            coords = vector4(-3210.3518, 2426.0264, 13.6239, 356.1512),
            size = vector3(4, 4, 4),
            rotation = 45,
            showBlip = false, -- overrides the blip visibilty configured above for the group
            
        },
        --MG ISLAND
        {
            type = "clothing",
            coords = vector4(-3207.2490, 2429.7812, 13.6239, 176.1340),
            size = vector3(3, 3, 3),
            rotation = 45,
            showBlip = false, -- overrides the blip visibilty configured above for the group
            
        },
        
        --boilingbroke
        {
            type = "clothing",
            coords = vector4(1713.6953, 2459.4939, 50.4529, 176.0462),
            size = vector3(3, 3, 3),
            rotation = 45,
            showBlip = false, -- overrides the blip visibilty configured above for the group
            
        },
        --casino
        {
            type = "clothing",
            coords = vector4(926.3618, 20.3059, 71.8288, 0.0000),
            size = vector3(3, 3, 3),
            rotation = 45,
            showBlip = false, -- overrides the blip visibilty configured above for the group
            
        },
        --SM HOTEL
        {
            type = "clothing",
            coords = vector4(-812.5112, -717.9846, 28.0602, 179.3633),
            size = vector3(3, 3, 3),
            rotation = 45,
            showBlip = false, -- overrides the blip visibilty configured above for the group
            
        },
        --Closet Toko Baju Roxwood
        {
            type = "clothing",
            coords = vector4(-3007.2490, 6244.8838, 11.9888, 281.3242),
            size = vector3(5, 5, 2),
            rotation = 45,
            showBlip = true, -- overrides the blip visibilty configured above for the group
            
        },
        --Closet Inagawa Roxwood Mansion
        {
            type = "clothing",
            coords = vector4(-832.3697, 7170.0537, 96.1423, 234.2689),
            size = vector3(5, 5, 2),
            rotation = 45,
            showBlip = false, -- overrides the blip visibilty configured above for the group
            
        },
        --Closet Deverux Mansion
        -- {
        --     type = "clothing",
        --     coords = vector4(3513.9143, 5292.6787, 25.9749, 17.3272),
        --     size = vector3(5, 5, 2),
        --     rotation = 45,
        --     showBlip = false, -- overrides the blip visibilty configured above for the group
            
        -- },

        --Closet Roels Casino Penthouse 1
        {
            type = "clothing",
            coords = vector4(975.0411, 64.8389, 116.1640, 322.8307),
            size = vector3(5, 5, 2),
            rotation = 45,
            showBlip = false, -- overrides the blip visibilty configured above for the group
            
        },

        --Closet Roels Casino Penthouse 2
        {
            type = "clothing",
            coords = vector4(985.2191, 60.0080, 116.1641, 333.0405),
            size = vector3(5, 5, 2),
            rotation = 45,
            showBlip = false, -- overrides the blip visibilty configured above for the group
            
        },

        --Closet Roels Beach Mansion 1
        {
            type = "clothing",
            coords = vector4(2947.2476, 489.8460, 43.4904, 5.5391),
            size = vector3(5, 5, 2),
            rotation = 45,
            showBlip = false, -- overrides the blip visibilty configured above for the group
            
        },

        --Closet Roels Beach Mansion 2
        {
            type = "clothing",
            coords = vector4(2945.2935, 494.2816, 39.0077, 278.4227),
            size = vector3(5, 5, 2),
            rotation = 45,
            showBlip = false, -- overrides the blip visibilty configured above for the group
            
        },

        --Closet Roels Beach Mansion 3
        {
            type = "clothing",
            coords = vector4(2933.4314, 522.8432, 47.9922, 97.1597),
            size = vector3(5, 5, 2),
            rotation = 45,
            showBlip = false, -- overrides the blip visibilty configured above for the group
            
        },

        --Closet Roels isloandroel
        {
            type = "clothing",
            coords = vector4(-2818.0732, 4215.6211, 31.0205, 328.5258),
            size = vector3(3, 3, 2),
            rotation = 45,
            showBlip = false, -- overrides the blip visibilty configured above for the group
            
        },

        --Closet2 Roels isloandroel
        {
            type = "clothing",
            coords = vector4(-2719.4585, 4182.8608, 30.9794, 328.3552),
            size = vector3(3, 3, 2),
            rotation = 45,
            showBlip = false, -- overrides the blip visibilty configured above for the group
            
        },


        --Closet3 Roels isloandroel
        {
            type = "clothing",
            coords = vector4(-2733.5703, 4160.0703, 30.9794, 155.9621),
            size = vector3(3, 3, 2),
            rotation = 45,
            showBlip = false, -- overrides the blip visibilty configured above for the group
            
        },

        --Closet Roels 1
        {
            type = "clothing",
            coords = vector4(-1539.4253, 804.3937, 188.6165, 195.6534),
            size = vector3(5, 5, 2),
            rotation = 45,
            showBlip = false, -- overrides the blip visibilty configured above for the group
            
        },

        --Closet Roels 2
        {
            type = "clothing",
            coords = vector4(-1509.4814, 813.6899, 188.6168, 199.5293),
            size = vector3(5, 5, 2),
            rotation = 45,
            showBlip = false, -- overrides the blip visibilty configured above for the group
            
        },

        --Closet Roels 3
        {
            type = "clothing",
            coords = vector4(-1592.8187, 868.0043, 187.9048, 242.0999),
            size = vector3(5, 5, 2),
            rotation = 45,
            showBlip = false, -- overrides the blip visibilty configured above for the group
            
        },

        --Closet Roels 4
        {
            type = "clothing",
            coords = vector4(-1600.3594, 845.8202, 187.9051, 329.8969),
            size = vector3(5, 5, 2),
            rotation = 45,
            showBlip = false, -- overrides the blip visibilty configured above for the group
            
        },

        --Closet Roels 5
        {
            type = "clothing",
            coords = vector4(-1586.2192, 869.5975, 185.0206, 151.6565),
            size = vector3(5, 5, 2),
            rotation = 45,
            showBlip = false, -- overrides the blip visibilty configured above for the group
            
        },

        --Stunberg Garage
        {
            type = "clothing",
            coords = vector4(-268.3338, 6221.3032, 31.7104, 315.6760),
            size = vector3(5, 5, 2),
            rotation = 45,
            showBlip = false, -- overrides the blip visibilty configured above for the group
            
        },

        --roxwood
        {
            type = "clothing",
            coords = vector4(-331.9833, 7210.9219, 6.7981, 85.2355),
            size = vector3(5, 5, 2),
            rotation = 45,
            showBlip = true, -- overrides the blip visibilty configured above for the group
            
        },
        --Maze Bank Idol
        {
            type = "clothing",
            coords = vector4(-320.1107, -1974.4954, 20.7253, 325.6879),
            size = vector3(5, 5, 2),
            rotation = 45,
            showBlip = false, -- overrides the blip visibilty configured above for the group
            
        },
        --digitalden
        {
            type = "clothing",
            coords = vector4(-1333.4707, -412.4398, 37.2115, 197.8922),
            size = vector3(2, 2, 2),
            rotation = 45,
            showBlip = false, -- overrides the blip visibilty configured above for the group
            
        },
        --wartel
        {
            type = "clothing",
            coords = vector4(-777.1604, 5594.9248, 33.7607, 357.6724),
            size = vector3(3, 3, 3),
            rotation = 45,
            showBlip = false, -- overrides the blip visibilty configured above for the group
            
        },
        --969mechanic
        {
            type = "clothing",
            coords = vector4(1185.1, 2626.24, 38.37, 106.42),
            size = vector3(2, 2, 2),
            rotation = 45,
            showBlip = false, -- overrides the blip visibilty configured above for the group
            
        },
        --nightclub
        {
            type = "clothing",
            coords = vector4(104.5596, -1299.4962, 29.2189, 298.7170),
            size = vector3(4, 4, 2),
            rotation = 45,
            showBlip = false, -- overrides the blip visibilty configured above for the group
            
        },
        --luxurynightclub
        {
            type = "clothing",
            coords = vector4(85.2021, 6516.6934, 31.4715, 132.3621),
            size = vector3(2, 2, 2),
            rotation = 45,
            showBlip = false, -- overrides the blip visibilty configured above for the group
            
        },
        --tokobajurumahbosmat2
        {
            type = "clothing",
            coords = vector4(-1231.55, 822.57, 194.15, 183.6),
            size = vector3(2, 2, 2),
            rotation = 45,
            showBlip = false, -- overrides the blip visibilty configured above for the group
            
        },
        --tokobajurumahbosmat
        {
            type = "clothing",
            coords = vector4(-1238.41, 785.63, 193.98, 173.17),
            size = vector3(2, 2, 2),
            rotation = 45,
            showBlip = false, -- overrides the blip visibilty configured above for the group
            
        },
        --rumahbgge
        {
            type = "clothing",
            coords = vector4(1405.9507, 4718.9751, 134.8402, 284.8293),
            size = vector3(2, 2, 2),
            rotation = 45,
            showBlip = false, -- overrides the blip visibilty configured above for the group
            
        },
        --pengadilan
        {
            type = "clothing",
            coords = vector4(236.78, -426.86, 42.81, 151.73),
            size = vector3(2, 2, 2),
            rotation = 45,
            showBlip = false, -- overrides the blip visibilty configured above for the group
            
        },

        --maxspeed
        {
            type = "clothing",
            coords = vector4(-350.2938, -123.6370, 39.0530, 193.5751),
            size = vector3(3, 3, 3),
            rotation = 45,
            showBlip = false, -- overrides the blip visibilty configured above for the group
            
        },

        --cayo
        {
            type = "clothing",
            coords = vector4(4431.7554, -4447.9585, 7.2368, 193.5751),
            size = vector3(3, 3, 3),
            rotation = 45,
            showBlip = true, -- overrides the blip visibilty configured above for the group
            
        },

        --satumedia
        {
            type = "clothing",
            coords = vector4(-276.4512, -627.3735, 41.5203, 0.0000),
            size = vector3(3, 3, 3),
            rotation = 45,
            showBlip = false, -- overrides the blip visibilty configured above for the group
            
        },
        --rumahmlo
        {
            type = "clothing",
            coords = vector4(-74.4, 1004.34, 239.51, 144.97),
            size = vector3(4, 4, 4),
            rotation = 45,
            showBlip = false, -- overrides the blip visibilty configured above for the group
            
        },
        --kanpolss
        {
            type = "clothing",
            coords = vector4(1822.2334, 3681.7708, 29.3079, 29.0574),
            size = vector3(4, 4, 4),
            rotation = 45,
            showBlip = false, -- overrides the blip visibilty configured above for the group
            
        },
        --nyundaresto
        {
            type = "clothing",
            coords = vector4(-1775.23, -1208.77, 14.64, 231.74),
            size = vector3(2, 2, 2),
            rotation = 45,
            showBlip = false, -- overrides the blip visibilty configured above for the group
            
        },
        --kkpresto
        {
            type = "clothing",
            coords = vector4(-597.0494, -1049.4890, 22.3442, 92.11),
            size = vector3(2, 2, 2),
            rotation = 45,
            showBlip = false, -- overrides the blip visibilty configured above for the group
            
        },
        --kkpgarage
        {
            type = "clothing",
            coords = vector4(1386.8467, -2088.0164, 52.0280, 219.5112),
            size = vector3(2, 2, 2),
            rotation = 45,
            showBlip = false, -- overrides the blip visibilty configured above for the group
            
        },
        --pabrik
        {
            type = "clothing",
            coords = vector4(198.4767, 1189.1521, 230.5351, 0.0000),
            size = vector3(2, 2, 2),
            rotation = 45,
            showBlip = false, -- overrides the blip visibilty configured above for the group
            
        },
        --paud
        {
            type = "clothing",
            coords = vector4(348.8103, 3570.8667, 35.2889, 0.0000),
            size = vector3(2, 2, 2),
            rotation = 45,
            showBlip = false, -- overrides the blip visibilty configured above for the group
            
        },
        --upnatom
        {
            type = "clothing",
            coords = vector4(-1302.2385, 6971.7007, 20.5175, 74.3609),
            size = vector3(3, 3, 3),
            rotation = 45,
            showBlip = false, -- overrides the blip visibilty configured above for the group
            
        },
        --smgo
        {
            type = "clothing",
            coords = vector4(-801.1805, -1353.2167, 5.9157, 259.1750),
            size = vector3(3, 3, 3),
            rotation = 45,
            showBlip = false, -- overrides the blip visibilty configured above for the group
            
        },
        --gzcafe
        {
            type = "clothing",
            coords = vector4(-2180.6865, 4210.4971, 37.1896, 327.4554),
            size = vector3(3, 3, 3),
            rotation = 45,
            showBlip = false, -- overrides the blip visibilty configured above for the group
            
        },
        --lawfirm
        {
            type = "clothing",
            coords = vector4(-1007.0657, -428.1332, 72.4610, 208.3460),
            size = vector3(3, 3, 3),
            rotation = 45,
            showBlip = false, -- overrides the blip visibilty configured above for the group
            
        },
        --mhcafe
        {
            type = "clothing",
            coords = vector4(-270.7787, 6679.9536, 8.0549, 0.0000),
            size = vector3(3, 3, 3),
            rotation = 45,
            showBlip = false, -- overrides the blip visibilty configured above for the group
            
        },
        --rumahsakitss
        {
            type = "clothing",
            coords = vector4(637.84, 2771.22, 43.56, 80.37),
            size = vector3(2, 2, 2),
            rotation = 45,
            showBlip = false, -- overrides the blip visibilty configured above for the group
            
        },
        --rsroxwood2
        {
            type = "clothing",
            coords = vector4(-489.4796, 7424.4683, 5.2728, 355.1917),
            size = vector3(3, 3, 3),
            rotation = 45,
            showBlip = false, -- overrides the blip visibilty configured above for the group
            
        },
        --rumahsakit
        {
            type = "clothing",
            coords = vector4(1141.5459, -1551.4484, 34.8442, 186.1145),
            size = vector3(4, 4, 4),
            rotation = 45,
            showBlip = false, -- overrides the blip visibilty configured above for the group
            
        },
        --rumahsakitlt2
        {
            type = "clothing",
            coords = vector4(1146.8795, -1553.4492, 30.3664, 180.7529),
            size = vector3(2, 2, 2),
            rotation = 45,
            showBlip = false, -- overrides the blip visibilty configured above for the group
            
        },
        --rumahsakitroxwood
        {
            type = "clothing",
            coords = vector4(-540.9228, 7373.8755, 12.8352, 53.2178),
            size = vector3(3, 3, 3),
            rotation = 45,
            showBlip = false, -- overrides the blip visibilty configured above for the group
            
        },
        {
            type = "clothing",
            coords = vector4(-553.6362, 7387.6831, 8.5192, 236.0335),
            size = vector3(3, 3, 3),
            rotation = 45,
            showBlip = false, -- overrides the blip visibilty configured above for the group
            
        },
        --pemerintah
        {
            type = "clothing",
            coords = vector4(-410.81, 1090.51, 331.88, 340.89),
            size = vector3(4, 4, 4),
            rotation = 45,
            showBlip = false, -- overrides the blip visibilty configured above for the group
            
        },
        --mrpd
        {
            type = "clothing",
            coords = vector4(455.3650, -990.9355, 30.6896, 85.8408),
            size = vector3(4, 4, 4),
            rotation = 45, -- false => uses the size + rotation to create the zone | true => uses points to create the zone
            showBlip = false, -- overrides the blip visibilty configured above for the group
        },
        {
            type = "clothing",
            coords = vector4(1693.2, 4828.11, 42.07, 188.66),
            size = vector3(4, 4, 4),
            rotation = 45, -- false => uses the size + rotation to create the zone | true => uses points to create the zone
            showBlip = true, -- overrides the blip visibilty configured above for the group
            
        },
        --musicrecord
        {
            type = "clothing",
            coords = vector4(-178.9024, 224.6576, 96.6855, 265.3162),
            size = vector3(3, 3, 3),
            rotation = 45,
            showBlip = false, -- overrides the blip visibilty configured above for the group
            
        },
        {
            type = "clothing",
            coords = vector4(-705.5, -149.22, 37.42, 122),
            size = vector3(4, 4, 4),
            rotation = 45,
            
        },
        {
            type = "clothing",
            coords = vector4(-1192.61, -768.4, 17.32, 216.6),
            size = vector3(4, 4, 4),
            rotation = 45,
            
        },
        {
            type = "clothing",
            coords = vector4(425.91, -801.03, 29.49, 177.79),
            size = vector3(4, 4, 4),
            rotation = 45,
            
        },
        {
            type = "clothing",
            coords = vector4(-168.73, -301.41, 39.73, 238.67),
            size = vector3(4, 4, 4),
            rotation = 45,
            
        },
        {
            type = "clothing",
            coords = vector4(75.39, -1398.28, 29.38, 6.73),
            size = vector3(4, 4, 4),
            rotation = 45,
            
        },
        {
            type = "clothing",
            coords = vector4(-827.39, -1075.93, 11.33, 294.31),
            size = vector3(4, 4, 4),
            rotation = 45,
            
        },
        {
            type = "clothing",
            coords = vector4(-1445.86, -240.78, 49.82, 36.17),
            size = vector3(4, 4, 4),
            rotation = 45,
            
        },
        {
            type = "clothing",
            coords = vector4(9.22, 6515.74, 31.88, 131.27),
            size = vector3(4, 4, 4),
            rotation = 45,
            
        },
        {
            type = "clothing",
            coords = vector4(1191.61, 2710.91, 38.22, 269.96),
            size = vector3(4, 4, 4),
            rotation = 45,
            
        },
        {
            type = "clothing",
            coords = vector4(-3171.32, 1043.56, 20.86, 334.3),
            size = vector3(4, 4, 4),
            rotation = 45,
            
        },
        {
            type = "clothing",
            coords = vector4(-1105.52, 2707.79, 19.11, 317.19),
            size = vector3(4, 4, 4),
            rotation = 45,
            
        },
        {
            type = "clothing",
            coords = vector4(-1119.24, -1440.6, 5.23, 300.5),
            size = vector3(4, 4, 4),
            rotation = 45,
            
        },
        {
            type = "clothing",
            coords = vector4(124.82, -224.36, 54.56, 335.41),
            size = vector3(4, 4, 4),
            rotation = 45,
            
        },
        ------ PEMERINTAH -------
        {
            type = "clothing",
            coords = vector4(-421.8783, 1077.8375, 327.6808, 74.3903),
            size = vector3(4, 4, 4),
            rotation = 45,
            showBlip = false,
            
        },
        ----- BENGKEL YS -----
        {
            type = "clothing",
            coords = vector4(-341.3576, -161.3594, 44.5874, 262.2821),
            size = vector3(4, 4, 4),
            rotation = 45,
            showBlip = false,
            
        },

        ----- BURGENK CAFE -----
        {
            type = "clothing",
            coords = vector4(1516.4161, 3785.6509, 38.2219, 221.9217),
            size = vector3(2, 2, 2),
            rotation = 45,
            showBlip = false,
            
        },

        ----- Gokudo -----
        {
            type = "clothing",
            coords = vector4(496.9184, 7453.9077, 10.3078, 132.1172),
            size = vector3(3, 3, 3),
            rotation = 45,
            showBlip = false,
            
        },

            ----- Gokudo2 -----
        {
            type = "clothing",
            coords = vector4(-3142.9355, 6196.8003, 13.0222, 106.2080),
            size = vector3(3, 3, 3),
            rotation = 45,
            showBlip = false,
            
        },

        
        ----- puskesmas -----
        {
            type = "clothing",
            coords = vector4(-263.4676, 6320.3564, 32.4272, 115.6932),
            size = vector3(2, 2, 2),
            rotation = 45,
            showBlip = false,
            
        },
        
        -- Tekno 
        {
            type = "clothing",
            coords = vector4(-2213.4702, -449.9603, 13.3310, 82.4191),
            size = vector3(4, 4, 4),
            rotation = 45,
            showBlip = false,
            
        },

        --liputan
        {
            type = "clothing",
            coords = vector4(-1022.9, -1360.65, 9.46, 164.93),
            size = vector3(4, 4, 4),
            rotation = 45,
            showBlip = false,
            
        },

        {
            type = "clothing",
            coords = vector4(-398.5317, -366.8638, 25.0989, 84.7907),
            size = vector3(4, 4, 4),
            rotation = 45,
            showBlip = false,
            
        },

        {
            type = "clothing",
            coords = vector4(-1467.9875, -45.5924, 58.6683, 119.7008),
            size = vector3(4, 4, 4),
            rotation = 45,
            showBlip = false,
            
        },

        {
            type = "clothing",
            coords = vector4(79.6089, -379.1516, 41.6247, 100.8126),
            size = vector3(4, 4, 4),
            rotation = 45,
            showBlip = false,
            
        },

        --digitaldenroxwood
        {
            type = "barber",
            coords = vector4(-2998.1277, 6141.2090, 8.5785, 190.6421),
            size = vector3(4, 4, 4),
            rotation = 45,
            showBlip = true,
            
        },

        --dhm
        {
            type = "clothing",
            coords = vector4(-1382.0317, -625.8427, 30.2489, 341.9752),
            size = vector3(4, 4, 4),
            rotation = 45,
            showBlip = false,
            
        },

        --toko baju event balap
        {
            type = "clothing",
            coords = vector4(-2930.1382, 8139.6646, 44.8227, 173.6926),
            size = vector3(4, 4, 4),
            rotation = 45,
            showBlip = false,
            
        },

        --toko baju milbase
        {
            type = "clothing",
            coords = vector4(-2176.2937, 3450.9524, 35.0273, 95.2538),
            size = vector3(4, 4, 4),
            rotation = 45,
            showBlip = false,
            
        },

        --barber milbase
        {
            type = "barber",
            coords = vector4(-2181.7605, 3450.8501, 35.0273, 88.5311),
            size = vector3(2, 2, 2),
            rotation = 45,
            
        },


        {
            type = "barber",
            coords = vector4(-814.22, -183.7, 37.57, 116.91),
            size = vector3(4, 4, 4),
            rotation = 45,
            
        },
        {
            type = "barber",
            coords = vector4(136.78, -1708.4, 29.29, 144.19),
            size = vector3(4, 4, 4),
            rotation = 45,
            
        },
        {
            type = "barber",
            coords = vector4(-1282.57, -1116.84, 6.99, 89.25),
            size = vector3(4, 4, 4),
            rotation = 45,
            
        },
        {
            type = "barber",
            coords = vector4(1931.41, 3729.73, 32.84, 212.08),
            size = vector3(4, 4, 4),
            rotation = 45,
            
        },
        {
            type = "barber",
            coords = vector4(1212.8, -472.9, 65.2, 60.94),
            size = vector3(4, 4, 4),
            rotation = 45,
            
        },
        {
            type = "barber",
            coords = vector4(-32.9, -152.3, 56.1, 335.22),
            size = vector3(4, 4, 4),
            rotation = 45,
            
        },
        {
            type = "barber",
            coords = vector4(109.1790, 6627.5405, 31.7873, 222.6876),
            size = vector3(4, 4, 4),
            rotation = 45,
            
        },
        -- Cayo Perico Villa
        {
            type = "clothing",
            coords = vector4(5028.5537, -5761.1133, 15.7459, 235.2299),
            size = vector3(4, 4, 4),
            rotation = 45,
            showBlip = false,
        },

        -- mercenary
        {
            type = "clothing",
            coords = vector4(2147.1226, 2917.7917, -84.8001, 177.9896),
            size = vector3(3, 3, 3),
            rotation = 45,
            showBlip = false,
            
        },

        -- -- safehouse detective
        -- {
        --     type = "clothing",
        --     coords = vector4(-209.9229, -1339.1547, 34.8944, 1.5746),
        --     size = vector3(3, 3, 3),
        --     rotation = 45,
        --     showBlip = false,
            
        -- },

        -- binco bandara
        {
            type = "clothing",
            coords = vector4(-1619.6963, -3020.4111, -75.2051, 0.0),
            size = vector3(3, 3, 3),
            rotation = 45,
            showBlip = false,
            
        },

        -- safehouse detective #2
        {
            type = "barber",
            coords = vector4(-215.9773, -1313.4805, 34.6971, 216.9003),
            size = vector3(3, 3, 3),
            rotation = 45,
            showBlip = false,
            
        },

        -- doj
        {
            type = "clothing",
            coords = vector4(268.0513, -412.5555, 47.9235, 158.1251),
            size = vector3(3, 3, 3),
            rotation = 45,
            showBlip = false,
            
        },

        -- smasg
        {
            type = "clothing",
            coords = vector4(1468.9519, 1135.9270, 114.3228, 243.5942),
            size = vector3(3, 3, 3),
            rotation = 45,
            showBlip = false,
            
        },

        -- boilingbroke
        {
            type = "clothing",
            coords = vector4(1834.5443, 2571.5808, 46.0078, 0.0000),
            size = vector3(3, 3, 3),
            rotation = 45,
            showBlip = false,
            -- 
        },

        -- sksm
        {
            type = "clothing",
            coords = vector4(3588.3816, 4884.9316, 39.6833, 209.4982),
            size = vector3(2, 2, 2),
            rotation = 45,
            showBlip = false,
            
        },

        {
            type = "barber",
            coords = vector4(2140.3364, 2915.6614, -84.7932, 358.1333),
            size = vector3(3, 3, 3),
            rotation = 45,
            showBlip = false,
            
        },

        {
            type = "barber",
            coords = vector4(5069.4600, -5777.7329, 16.3169, 57.8493),
            size = vector3(4, 4, 4),
            rotation = 45,
            showBlip = false,
            
        },

        --Roels Casino penthouse
        {
            type = "barber",
            coords = vector4(953.1047, 15.4342, 117.3642, 196.4479),
            size = vector3(3, 3, 3),
            rotation = 45,
            showBlip = false,
            
        },

        --nightclub
        {
            type = "barber",
            coords = vector4(109.0240, -1303.2703, 29.2189, 118.5335),
            size = vector3(3, 3, 3),
            rotation = 45,
            showBlip = false,
            
        },
        --smasg
        {
            type = "barber",
            coords = vector4(1460.3973, 1134.3549, 114.3242, 262.2365),
            size = vector3(3, 3, 3),
            rotation = 45,
            showBlip = false,
            
        },
        {
            type = "tattoo",
            coords = vector4(1322.6, -1651.9, 51.2, 42.47),
            size = vector3(4, 4, 4),
            rotation = 45,
            
        },
        {
            type = "tattoo",
            coords = vector4(-1154.01, -1425.31, 4.95, 23.21),
            size = vector3(4, 4, 4),
            rotation = 45,
            
        },
        {
            type = "tattoo",
            coords = vector4(322.62, 180.34, 103.59, 156.2),
            size = vector3(4, 4, 4),
            rotation = 45,
            
        },
        {
            type = "tattoo",
            coords = vector4(-3169.52, 1074.86, 20.83, 253.29),
            size = vector3(4, 4, 4),
            rotation = 45,
            
        },
        {
            type = "tattoo",
            coords = vector4(1864.1, 3747.91, 33.03, 17.23),
            size = vector3(4, 4, 4),
            rotation = 45,
            
        },
        {
            type = "tattoo",
            coords = vector4(-294.24, 6200.12, 31.49, 195.72),
            size = vector3(4, 4, 4),
            rotation = 45,
            
        },
        --- toko tatto roxwood
        {
            type = "tattoo",
            coords = vector4(-332.4016, 7188.0122, 6.4778, 167.3307),
            size = vector3(4, 4, 4),
            rotation = 45,
        },
        {
            type = "surgeon",
            coords = vector4(1124.7380, -1573.0116, 30.1232, 172.5186),
            size = vector3(2, 2, 2),
            rotation = 45,
        }
    },

    clothingRooms = {},

    outfitRooms = {},

    --- Uniforms offered inside a clothing room, keyed by the job or gang name.
    ---@type table<string, { name: string, gender: string?, model: string?, components: PedComponent[], props: PedProp[] }[]>
    jobOutfits = {
        police = {
            {
                name = "Short Sleeve",
                gender = "male",
                components = {
                    { component_id = 4, drawable = 24, texture = 0 },
                    { component_id = 3, drawable = 19, texture = 0 },
                    { component_id = 8, drawable = 58, texture = 0 },
                    { component_id = 9, drawable = 0, texture = 0 },
                    { component_id = 11, drawable = 55, texture = 0 },
                    { component_id = 6, drawable = 51, texture = 0 },
                    { component_id = 7, drawable = 0, texture = 0 },
                    { component_id = 5, drawable = 0, texture = 0 },
                    { component_id = 1, drawable = 0, texture = 0 }
                },
                props = {
                    { prop_id = 0, drawable = -1, texture = -1 },
                    { prop_id = 1, drawable = 0, texture = 0 }
                },
                grades = { 0, 1, 2, 3, 4 }
            },
            {
                name = "Trooper Tan",
                gender = "male",
                components = {
                    { component_id = 4, drawable = 24, texture = 0 },
                    { component_id = 3, drawable = 20, texture = 0 },
                    { component_id = 8, drawable = 58, texture = 0 },
                    { component_id = 9, drawable = 0, texture = 0 },
                    { component_id = 11, drawable = 317, texture = 3 },
                    { component_id = 6, drawable = 51, texture = 0 },
                    { component_id = 7, drawable = 0, texture = 0 },
                    { component_id = 5, drawable = 0, texture = 0 },
                    { component_id = 1, drawable = 0, texture = 0 }
                },
                props = {
                    { prop_id = 0, drawable = 58, texture = 0 },
                    { prop_id = 1, drawable = 0, texture = 0 }
                },
                grades = { 0, 1, 2, 3, 4 }
            },
            {
                name = "Long Sleeve",
                gender = "male",
                components = {
                    { component_id = 4, drawable = 24, texture = 0 },
                    { component_id = 3, drawable = 20, texture = 0 },
                    { component_id = 8, drawable = 58, texture = 0 },
                    { component_id = 9, drawable = 0, texture = 0 },
                    { component_id = 11, drawable = 317, texture = 0 },
                    { component_id = 6, drawable = 51, texture = 0 },
                    { component_id = 7, drawable = 0, texture = 0 },
                    { component_id = 5, drawable = 0, texture = 0 },
                    { component_id = 1, drawable = 0, texture = 0 }
                },
                props = {
                    { prop_id = 0, drawable = -1, texture = -1 },
                    { prop_id = 1, drawable = 0, texture = 0 }
                },
                grades = { 1, 2, 3, 4 }
            },
            {
                name = "Trooper Black",
                gender = "male",
                components = {
                    { component_id = 4, drawable = 24, texture = 0 },
                    { component_id = 3, drawable = 20, texture = 0 },
                    { component_id = 8, drawable = 58, texture = 0 },
                    { component_id = 9, drawable = 0, texture = 0 },
                    { component_id = 11, drawable = 317, texture = 8 },
                    { component_id = 6, drawable = 51, texture = 0 },
                    { component_id = 7, drawable = 0, texture = 0 },
                    { component_id = 5, drawable = 0, texture = 0 },
                    { component_id = 1, drawable = 0, texture = 0 }
                },
                props = {
                    { prop_id = 0, drawable = 58, texture = 3 },
                    { prop_id = 1, drawable = 0, texture = 0 }
                },
                grades = { 2, 3, 4 }
            },
            {
                name = "SWAT",
                gender = "male",
                components = {
                    { component_id = 4, drawable = 130, texture = 1 },
                    { component_id = 3, drawable = 172, texture = 0 },
                    { component_id = 8, drawable = 15, texture = 0 },
                    { component_id = 9, drawable = 15, texture = 2 },
                    { component_id = 11, drawable = 336, texture = 3 },
                    { component_id = 6, drawable = 24, texture = 0 },
                    { component_id = 7, drawable = 133, texture = 0 },
                    { component_id = 1, drawable = 52, texture = 0 }
                },
                props = {
                    { prop_id = 0, drawable = 150, texture = 0 },
                    { prop_id = 1, drawable = 0, texture = 0 }
                },
                grades = { 3, 4 }
            },
            {
                name = "Short Sleeve",
                gender = "female",
                components = {
                    { component_id = 4, drawable = 133, texture = 0 },
                    { component_id = 3, drawable = 31, texture = 0 },
                    { component_id = 8, drawable = 35, texture = 0 },
                    { component_id = 9, drawable = 34, texture = 0 },
                    { component_id = 11, drawable = 48, texture = 0 },
                    { component_id = 6, drawable = 52, texture = 0 },
                    { component_id = 7, drawable = 0, texture = 0 },
                    { component_id = 5, drawable = 0, texture = 0 },
                    { component_id = 1, drawable = 0, texture = 0 }
                },
                props = {
                    { prop_id = 0, drawable = 0, texture = 0 },
                    { prop_id = 1, drawable = 0, texture = 0 }
                },
                grades = { 0, 1, 2, 3, 4 }
            },
            {
                name = "Trooper Tan",
                gender = "female",
                components = {
                    { component_id = 4, drawable = 133, texture = 0 },
                    { component_id = 3, drawable = 31, texture = 0 },
                    { component_id = 8, drawable = 35, texture = 0 },
                    { component_id = 9, drawable = 34, texture = 0 },
                    { component_id = 11, drawable = 327, texture = 3 },
                    { component_id = 6, drawable = 52, texture = 0 },
                    { component_id = 7, drawable = 0, texture = 0 },
                    { component_id = 5, drawable = 0, texture = 0 },
                    { component_id = 1, drawable = 0, texture = 0 }
                },
                props = {
                    { prop_id = 0, drawable = 0, texture = 0 },
                    { prop_id = 1, drawable = 0, texture = 0 }
                },
                grades = { 0, 1, 2, 3, 4 }
            },
            {
                name = "Long Sleeve",
                gender = "female",
                components = {
                    { component_id = 4, drawable = 133, texture = 0 },
                    { component_id = 3, drawable = 31, texture = 0 },
                    { component_id = 8, drawable = 35, texture = 0 },
                    { component_id = 9, drawable = 34, texture = 0 },
                    { component_id = 11, drawable = 327, texture = 0 },
                    { component_id = 6, drawable = 52, texture = 0 },
                    { component_id = 7, drawable = 0, texture = 0 },
                    { component_id = 5, drawable = 0, texture = 0 },
                    { component_id = 1, drawable = 0, texture = 0 }
                },
                props = {
                    { prop_id = 0, drawable = 0, texture = 0 },
                    { prop_id = 1, drawable = 0, texture = 0 }
                },
                grades = { 1, 2, 3, 4 }
            },
            {
                name = "Trooper Black",
                gender = "female",
                components = {
                    { component_id = 4, drawable = 133, texture = 0 },
                    { component_id = 3, drawable = 31, texture = 0 },
                    { component_id = 8, drawable = 35, texture = 0 },
                    { component_id = 9, drawable = 34, texture = 0 },
                    { component_id = 11, drawable = 327, texture = 8 },
                    { component_id = 6, drawable = 52, texture = 0 },
                    { component_id = 7, drawable = 0, texture = 0 },
                    { component_id = 5, drawable = 0, texture = 0 },
                    { component_id = 1, drawable = 0, texture = 0 }
                },
                props = {
                    { prop_id = 0, drawable = 0, texture = 0 },
                    { prop_id = 1, drawable = 0, texture = 0 }
                },
                grades = { 2, 3, 4 }
            },
            {
                name = "SWAT",
                gender = "female",
                components = {
                    { component_id = 4, drawable = 135, texture = 1 },
                    { component_id = 3, drawable = 213, texture = 0 },
                    { component_id = 8, drawable = 0, texture = 0 },
                    { component_id = 9, drawable = 17, texture = 2 },
                    { component_id = 11, drawable = 327, texture = 8 },
                    { component_id = 6, drawable = 52, texture = 0 },
                    { component_id = 7, drawable = 102, texture = 0 },
                    { component_id = 5, drawable = 0, texture = 0 },
                    { component_id = 1, drawable = 35, texture = 0 }
                },
                props = {
                    { prop_id = 0, drawable = 149, texture = 0 },
                    { prop_id = 1, drawable = 0, texture = 0 }
                },
                grades = { 3, 4 }
            }
        },
        realestate = {
            {
                name = "Worker",
                gender = "male",
                components = {
                    { component_id = 4, drawable = 28, texture = 0 },
                    { component_id = 3, drawable = 1, texture = 0 },
                    { component_id = 8, drawable = 31, texture = 0 },
                    { component_id = 9, drawable = 0, texture = 0 },
                    { component_id = 11, drawable = 294, texture = 0 },
                    { component_id = 6, drawable = 10, texture = 0 },
                    { component_id = 7, drawable = 0, texture = 0 },
                    { component_id = 5, drawable = 0, texture = 0 },
                    { component_id = 1, drawable = 0, texture = 0 }
                },
                props = {
                    { prop_id = 0, drawable = 12, texture = -1 },
                    { prop_id = 1, drawable = 0, texture = 0 }
                },
                grades = { 0, 1, 2, 3, 4 }
            },
            {
                name = "Worker",
                gender = "female",
                components = {
                    { component_id = 4, drawable = 57, texture = 2 },
                    { component_id = 3, drawable = 0, texture = 0 },
                    { component_id = 8, drawable = 34, texture = 0 },
                    { component_id = 9, drawable = 0, texture = 0 },
                    { component_id = 11, drawable = 105, texture = 7 },
                    { component_id = 6, drawable = 8, texture = 5 },
                    { component_id = 7, drawable = 11, texture = 3 },
                    { component_id = 5, drawable = 0, texture = 0 },
                    { component_id = 1, drawable = 0, texture = 0 }
                },
                props = {
                    { prop_id = 0, drawable = -1, texture = -1 },
                    { prop_id = 1, drawable = 0, texture = 0 }
                },
                grades = { 0, 1, 2, 3, 4 }
            }
        },
        ambulance = {
            {
                name = "T-Shirt",
                gender = "male",
                components = {
                    { component_id = 3, drawable = 85, texture = 0 },
                    { component_id = 8, drawable = 129, texture = 0 },
                    { component_id = 11, drawable = 250, texture = 0 },
                    { component_id = 9, drawable = 0, texture = 0 },
                    { component_id = 10, drawable = 58, texture = 0 },
                    { component_id = 7, drawable = 127, texture = 0 },
                    { component_id = 5, drawable = 0, texture = 0 },
                    { component_id = 4, drawable = 96, texture = 0 },
                    { component_id = 6, drawable = 54, texture = 0 },
                    { component_id = 1, drawable = 121, texture = 0 }
                },
                props = {
                    { prop_id = 0, drawable = 122, texture = 0 },
                    { prop_id = 1, drawable = 0, texture = 0 },
                    { prop_id = 2, drawable = 0, texture = 0 }
                },
                grades = { 0, 1, 2, 3, 4 }
            },
            {
                name = "Polo",
                gender = "male",
                components = {
                    { component_id = 3, drawable = 90, texture = 0 },
                    { component_id = 8, drawable = 15, texture = 0 },
                    { component_id = 11, drawable = 249, texture = 0 },
                    { component_id = 9, drawable = 0, texture = 0 },
                    { component_id = 10, drawable = 57, texture = 0 },
                    { component_id = 7, drawable = 126, texture = 0 },
                    { component_id = 5, drawable = 0, texture = 0 },
                    { component_id = 4, drawable = 96, texture = 0 },
                    { component_id = 6, drawable = 54, texture = 0 },
                    { component_id = 1, drawable = 121, texture = 0 }
                },
                props = {
                    { prop_id = 0, drawable = 122, texture = 0 },
                    { prop_id = 1, drawable = 0, texture = 0 },
                    { prop_id = 2, drawable = 0, texture = 0 }
                },
                grades = { 2, 3, 4 }
            },
            {
                name = "Doctor",
                gender = "male",
                components = {
                    { component_id = 3, drawable = 93, texture = 0 },
                    { component_id = 8, drawable = 32, texture = 3 },
                    { component_id = 11, drawable = 31, texture = 7 },
                    { component_id = 9, drawable = 0, texture = 0 },
                    { component_id = 10, drawable = 0, texture = 0 },
                    { component_id = 7, drawable = 126, texture = 0 },
                    { component_id = 5, drawable = 0, texture = 0 },
                    { component_id = 4, drawable = 28, texture = 0 },
                    { component_id = 6, drawable = 10, texture = 0 },
                    { component_id = 1, drawable = 0, texture = 0 }
                },
                props = {
                    { prop_id = 0, drawable = -1, texture = 0 },
                    { prop_id = 1, drawable = 0, texture = 0 },
                    { prop_id = 2, drawable = 0, texture = 0 }
                },
                grades = { 3, 4 }
            },
            {
                name = "T-Shirt",
                gender = "female",
                components = {
                    { component_id = 3, drawable = 109, texture = 0 },
                    { component_id = 8, drawable = 159, texture = 0 },
                    { component_id = 11, drawable = 258, texture = 0 },
                    { component_id = 9, drawable = 0, texture = 0 },
                    { component_id = 10, drawable = 66, texture = 0 },
                    { component_id = 7, drawable = 97, texture = 0 },
                    { component_id = 5, drawable = 0, texture = 0 },
                    { component_id = 4, drawable = 99, texture = 0 },
                    { component_id = 6, drawable = 55, texture = 0 },
                    { component_id = 1, drawable = 121, texture = 0 }
                },
                props = {
                    { prop_id = 0, drawable = 121, texture = 0 },
                    { prop_id = 1, drawable = 0, texture = 0 },
                    { prop_id = 2, drawable = 0, texture = 0 }
                },
                grades = { 0, 1, 2, 3, 4 }
            },
            {
                name = "Polo",
                gender = "female",
                components = {
                    { component_id = 3, drawable = 105, texture = 0 },
                    { component_id = 8, drawable = 13, texture = 0 },
                    { component_id = 11, drawable = 257, texture = 0 },
                    { component_id = 9, drawable = 0, texture = 0 },
                    { component_id = 10, drawable = 65, texture = 0 },
                    { component_id = 7, drawable = 96, texture = 0 },
                    { component_id = 5, drawable = 0, texture = 0 },
                    { component_id = 4, drawable = 99, texture = 0 },
                    { component_id = 6, drawable = 55, texture = 0 },
                    { component_id = 1, drawable = 121, texture = 0 }
                },
                props = {
                    { prop_id = 0, drawable = 121, texture = 0 },
                    { prop_id = 1, drawable = 0, texture = 0 },
                    { prop_id = 2, drawable = 0, texture = 0 }
                },
                grades = { 2, 3, 4 }
            },
            {
                name = "Doctor",
                gender = "female",
                components = {
                    { component_id = 3, drawable = 105, texture = 0 },
                    { component_id = 8, drawable = 39, texture = 3 },
                    { component_id = 11, drawable = 7, texture = 1 },
                    { component_id = 9, drawable = 0, texture = 0 },
                    { component_id = 10, drawable = 0, texture = 0 },
                    { component_id = 7, drawable = 96, texture = 0 },
                    { component_id = 5, drawable = 0, texture = 0 },
                    { component_id = 4, drawable = 34, texture = 0 },
                    { component_id = 6, drawable = 29, texture = 0 },
                    { component_id = 1, drawable = 0, texture = 0 }
                },
                props = {
                    { prop_id = 0, drawable = -1, texture = 0 },
                    { prop_id = 1, drawable = 0, texture = 0 },
                    { prop_id = 2, drawable = 0, texture = 0 }
                },
                grades = { 3, 4 }
            }
        }
    }
}
