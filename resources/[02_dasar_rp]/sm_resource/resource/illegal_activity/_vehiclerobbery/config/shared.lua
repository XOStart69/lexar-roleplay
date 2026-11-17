return {
    ped = {
        model = "U_M_Y_SmugMech_01",
        coords = vec4(510.6594, -3390.0181, 6.0699, 60.4297),
        renderDistance = 50.0
    },
    locations = {
        removeTracker = {
            vec4(2352.19, 3132.84, 47.8, 260.31)
        },
        chopping = {
            vec4(-553.19, -1700.97, 18.48, 27.09),
            vec4(472.0028, -3148.8965, 6.0701, 0.0),
            vec4(2196.4595, 5607.7915, 53.4855, 0.0),
            vec4(-1578.1039, 5160.0830, 19.8422, 0.0),
            vec4(-1146.0824, -1970.1130, 13.1604, 0.0),
        },
        pickup = {
            {enter = vec4(929.51, -2307.92, 30.65, 269.95), spawn = vec4(926.26, -2307.63, 30.51, 89.03)},
        }
    },
    timer = {
        mission = 20, -- 20 menit
        cooldown = 15 -- menit
    },
    maxActive = 3, -- maksimal heist berjalan bersamaan (0 = tanpa batas)
    vehicles = {
        ---@cars only (motorcycles disabled)
        {
            'smbenz55',
        },
    },
}