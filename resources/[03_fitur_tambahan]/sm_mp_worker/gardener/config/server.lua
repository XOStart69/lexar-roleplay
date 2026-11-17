return {
    debug = false,
    startCooldownSeconds = 5,

    validation = {
        startDistance = 10.0,
        deliverDistance = 25.0,
        taskObjectDistance = 15.0,
        branchLadderDistance = 25.0,
        branchObjectDistance = 35.0,
        prunegrassVehicleDistance = 150.0,
        bonusVehicleDistance = 15.0,
    },

    vehicle = {
        truck = 'tolsadler',
        mower = 'mower',
        truckPlatePrefix = 'GRDN',
        mowerPlatePrefix = 'GRDM',
        extraVehicle = true,
        truckSpawns = {
            vec4(-685.23, -885.77, 24.57, 180.75),
            vec4(-681.05, -884.81, 24.24, 180.16),
        },
        mowerSpawns = {
            vec4(-686.2, -877.41, 24.89, 180.79),
            vec4(-680.95, -877.76, 23.93, 180.24),
        },
        deliverCoords = vec3(-685.23, -885.77, 24.57),
    },

    reward = {
        moneyType = 'cash',
        items = {
            enabled = false,
            mode = 'weightedPool',
            pool = {
                { item = 'burger_rendang', count = 1, chance = 50 },
                { item = 'es_kopi_sanger', count = 1, chance = 30 },
                { item = 'bandage', count = 1, chance = 100 },
            },
        },
    },

    regions = {
        {
            money = 35000,
            tasks = {
                lawnmowing = { min = 20, max = 30 },
                prunegrass = { min = 8, max = 12 },
                branch = { min = 1, max = 2 },
                plantflower = { min = 4, max = 10 },
            },
        },
        {
            money = 35000,
            tasks = {
                lawnmowing = { min = 20, max = 25 },
                prunegrass = { min = 15, max = 20 },
                branch = { min = 2, max = 6 },
                plantflower = { min = 5, max = 12 },
            },
        },
        {
            money = 35000,
            tasks = {
                lawnmowing = { min = 25, max = 32 },
                prunegrass = { min = 15, max = 24 },
                branch = { min = 5, max = 5 },
                plantflower = { min = 7, max = 12 },
            },
        },
        {
            money = 35000,
            tasks = {
                lawnmowing = { min = 20, max = 28 },
                prunegrass = { min = 10, max = 15 },
                branch = { min = 2, max = 4 },
                plantflower = { min = 8, max = 13 },
            },
        },
        {
            money = 35000,
            tasks = {
                lawnmowing = { min = 30, max = 45 },
                prunegrass = { min = 10, max = 12 },
                branch = { min = 1, max = 2 },
                plantflower = { min = 6, max = 12 },
            },
        },
    },
}
