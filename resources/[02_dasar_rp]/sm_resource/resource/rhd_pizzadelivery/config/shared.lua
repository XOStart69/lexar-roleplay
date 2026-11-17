return {
    location_1 = {
        delivery = {
            time = 10,
            customerTip = math.random(3000, 5000),
            locations = {
                vec(156.6235, -117.1203, 62.4451, 253.5990), -- Ped & Zone Coords
                vec(2.2332, -240.7582, 51.8605, 155.9671), -- Ped & Zone Coords
                vec(66.5922, -255.9108, 52.3539, 72.5448), -- Ped & Zone Coords
                vec(-765.7576, 650.5468, 145.6974, 302.3414), -- Ped & Zone Coords
                vec(-353.2383, 668.4462, 169.0771, 169.8051), -- Ped & Zone Coords
                vec(84.9429, 561.6384, 182.7731, 4.4889) -- Ped & Zone Coords
            },
        },
        blip = {
            sprite = 661,
            color = 60,
            label = 'Pizza delivery'
        },
        ped = {
            model = 'csb_burgerdrug',
            coords = vec(536.6659, 101.2773, 96.5386, 184.1313)
        },
        vehicle = {
            model = 'faggio',
            coords = vec(532.9822, 96.3554, 95.8023, 116.1687)
        },
    }
}