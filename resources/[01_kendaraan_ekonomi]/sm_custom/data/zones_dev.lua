return {
    rhdcustom = {
        label = 'TEST',
        groups = { mechanic = 0 },
        society = 'mechanic',
        area = {
            points = {
                vec3(-249.1151, -1306.5918, 30.2986),
                vec3(-182.3077, -1304.8342, 30.2986),
                vec3(-183.5118, -1352.557, 30.2986),
                vec3(-251.2386, -1350.3918, 30.2986),
            },
            thickness = 25.5,
        },
        blip = { sprite = 72, colour = 0, scale = 0.8 },
        booths = {
            {
                mode = 'screen',
                vehicle = vec4(-198.9734, -1324.3518, 30.5238, 268.3278),
                screen = vec4(-203.938, -1321.6034, 29.8904, 90.8725),
                nozzles = {
                    {
                        coords = vec3(-202.3056, -1327.0165, 32.3811),
                        rotation = vec3(0.0, 35.0, 44.6047),
                    },
                    {
                        coords = vec3(-198.7121, -1327.0881, 32.4108),
                        rotation = vec3(0.0, 35.0, 84.6047),
                    },
                    {
                        coords = vec3(-195.1308, -1327.0881, 32.4646),
                        rotation = vec3(0.0, 35.0, 124.6047),
                    },
                    {
                        coords = vec3(-195.1215, -1321.736, 32.2865),
                        rotation = vec3(0.0, 35.0, 229.6047),
                    },
                    {
                        coords = vec3(-198.7149, -1321.736, 32.3529),
                        rotation = vec3(0.0, 35.0, 269.6047),
                    },
                    {
                        coords = vec3(-202.1403, -1321.736, 32.3313),
                        rotation = vec3(0.0, 35.0, 304.6047),
                    },
                },
            },
        },
        {
            coords = vec3(-223.1373, -1324.2625, 29.8904),
            menu = { 'performance', 'body', 'wheels', 'lights', 'interior', 'extra' },
            racks = {
                {
                    coords = vec3(-227.8149, -1327.5135, 29.8904),
                    parts = {
                        'modCustomTiresF',
                        'fitment',
                        'modCustomTiresR',
                        'modBackWheels',
                        'modSmokeEnabled',
                        'tyreSmokeColor',
                        'wheelColor',
                        'wheels',
                        'modFrontWheels',
                    },
                },
            },
        },
    },
}
