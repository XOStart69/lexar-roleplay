return {
    tables = {
        luxuryclub_packaging = {
            title = 'Packaging YClub',
            icon = 'fas fa-box',
            jobs = { luxurynightclub = 0 },
            animation = { dict = 'mini@repair', anim = 'fixing_a_player' },
            locations = { vec3(70.111542, 6505.541992, 31.493263) },
        },
    },
    recipes = {
        paket_dwhiskey = {
            label = 'Paket Devil Whiskey',
            category = 'Paket',
            package = true,
            toItems = { paket_dwhiskey = 1 },
            materials = { dwhiskey = 5 },
            craftingTime = 8000,
            maxCraft = 50,
            tables = { 'luxuryclub_packaging' },
            jobs = { luxurynightclub = 0 },
        },

        paket_pwine = {
            label = 'Paket Chateu Margaux',
            category = 'Paket',
            package = true,
            toItems = { paket_pwine = 1 },
            materials = { pwine = 5 },
            craftingTime = 8000,
            maxCraft = 50,
            tables = { 'luxuryclub_packaging' },
            jobs = { luxurynightclub = 0 },
        },

        paket_vodka = {
            label = 'Paket Vodka',
            category = 'Paket',
            package = true,
            toItems = { paket_vodka = 1 },
            materials = { vodka = 5 },
            craftingTime = 8000,
            maxCraft = 50,
            tables = { 'luxuryclub_packaging' },
            jobs = { luxurynightclub = 0 },
        },

        paket_ydetox = {
            label = 'Paket Y Detox',
            category = 'Paket',
            package = true,
            toItems = { paket_ydetox = 1 },
            materials = { ydetox = 5 },
            craftingTime = 8000,
            maxCraft = 50,
            tables = { 'luxuryclub_packaging' },
            jobs = { luxurynightclub = 0 },
        },

        paket_beefbites = {
            label = 'Paket Beef Bites',
            category = 'Paket',
            package = true,
            toItems = { paket_beefbites = 1 },
            materials = { beefbites = 10, strjuice = 10 },
            craftingTime = 8000,
            maxCraft = 50,
            tables = { 'luxuryclub_packaging' },
            jobs = { luxurynightclub = 0 },
        },

        paket_steakplate = {
            label = 'Paket Steak Plate',
            category = 'Paket',
            package = true,
            toItems = { paket_steakplate = 1 },
            materials = { steakplate = 10, lemonwater = 10 },
            craftingTime = 8000,
            maxCraft = 50,
            tables = { 'luxuryclub_packaging' },
            jobs = { luxurynightclub = 0 },
        },
    },
}
