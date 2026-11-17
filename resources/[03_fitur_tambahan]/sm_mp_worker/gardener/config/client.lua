return {
    blip = {
        ped = {
            sprite = 631,
            color = 2,
            scale = 0.55,
            name = 'Tukang Kebun',
        },
        mission = {
            area = {
                sprite = 570,
                color = 2,
                scale = 0.8,
                name = 'Area Berkebun',
                routeHideDistance = 50.0,
            },
            prunegrass = { sprite = 570, color = 24, scale = 0.6 },
            lawnmowing = { sprite = 570, color = 25, scale = 0.6 },
            branch = { sprite = 836, color = 52, scale = 0.8 },
            flower = { sprite = 570, color = 43, scale = 0.6 },
            vehicle = { sprite = 67, color = 0, scale = 0.8 },
            delivery = { sprite = 38, color = 29, scale = 0.8 },
        },
    },

    models = {
        vehicleLadder = 'tworst_gardener_ladder',
        placementLadder = { 'ladder', 'hw1_06_ldr_02' },
        flower = { 'vw_prop_flowers_vase_03a' },
        mower = {
            'prop_weeddry_nxg04', 'prop_weeds_nxg08', 'prop_weeds_nxg07b001', 'prop_weeds_nxg06',
            'prop_weeds_nxg07b', 'prop_weeds_nxg08b'
        },
        prunegrass = {
            before = { 'prop_bush_neat_08' },
            after = { 'prop_bush_ornament_04', 'prop_bush_ornament_02', 'prop_bush_ornament_03', 'prop_bush_neat_02' },
        },
    },

    groundValidation = {
        useZBased = false,
        maxHeightDifference = 1.5,
        minHeightDifference = -0.5,
        checkSlope = true,
        maxSlope = 0.5,
        checkWater = true,
        allowUnknownSurfaces = true,
        materialHashes = {
            [-461750719] = true,
            [930824497] = true,
            [581794674] = true,
            [-309121453] = true,
            [-913351839] = true,
            [-1885547121] = true,
            [-1915425863] = true,
            [-1833527165] = true,
            [2128369009] = true,
            [-124769592] = true,
            [-840216541] = true,
            [1333033863] = true,
        },
    },
}
