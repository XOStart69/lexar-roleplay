return {
    tables = {
        nightclub_packaging = {
            title = 'Packaging Maxclub',
            icon = 'fas fa-box',
            jobs = { nightclub = 0 },
            animation = { dict = 'mini@repair', anim = 'fixing_a_player' },
            locations = { vec3(113.018524, -1283.062378, 29.626404) },
        },
    },
    recipes = {
        scarlettseduction = {
            category = 'Alcohol',
            toItems = { scarlettseduction = 10 },
            materials = { air = 1, esjeruk = 2, applejuice = 2, esbatu = 2 },
            craftingTime = 3000,
            tables = { 'craftingnightclub', 'craftingnightclub2', 'craftingnightclub3' },
            jobs = { nightclub = 0 },
        },

        azul = {
            category = 'Alcohol',
            toItems = { azul = 10 },
            materials = { air = 1, esjeruk = 2, applejuice = 2, esbatu = 2 },
            craftingTime = 3000,
            tables = { 'craftingnightclub', 'craftingnightclub2', 'craftingnightclub3' },
            jobs = { nightclub = 0 },
        },

        sheridan = {
            category = 'Alcohol',
            toItems = { sheridan = 10 },
            materials = { air = 1, esjeruk = 2, applejuice = 2, esbatu = 2 },
            craftingTime = 3000,
            tables = { 'craftingnightclub', 'craftingnightclub2', 'craftingnightclub3' },
            jobs = { nightclub = 0 },
        },

        cocomax = {
            category = 'Alcohol',
            toItems = { cocomax = 10 },
            materials = { air = 1, esjeruk = 2, applejuice = 2, esbatu = 2 },
            craftingTime = 3000,
            tables = { 'craftingnightclub', 'craftingnightclub2', 'craftingnightclub3' },
            jobs = { nightclub = 0 },
        },

        applecider = {
            category = 'Snacks',
            toItems = { applecider = 10 },
            materials = { air = 1, esjeruk = 2, applejuice = 2, esbatu = 2 },
            craftingTime = 3000,
            tables = { 'craftingnightclub', 'craftingnightclub2', 'craftingnightclub3' },
            jobs = { nightclub = 0 },
        },

        rootbeer = {
            category = 'Snacks',
            toItems = { rootbeer = 10 },
            materials = { air = 1, esjeruk = 2, applejuice = 2, esbatu = 2 },
            craftingTime = 3000,
            tables = { 'craftingnightclub', 'craftingnightclub2', 'craftingnightclub3' },
            jobs = { nightclub = 0 },
        },

        calamari = {
            category = 'Snacks',
            toItems = { calamari = 10 },
            materials = { air = 1, esjeruk = 2, applejuice = 2, esbatu = 2 },
            craftingTime = 3000,
            tables = { 'craftingnightclub', 'craftingnightclub2', 'craftingnightclub3' },
            jobs = { nightclub = 0 },
        },

        baconfries = {
            category = 'Snacks',
            toItems = { baconfries = 10 },
            materials = { air = 1, esjeruk = 2, applejuice = 2, esbatu = 2 },
            craftingTime = 3000,
            tables = { 'craftingnightclub', 'craftingnightclub2', 'craftingnightclub3' },
            jobs = { nightclub = 0 },
        },

        paket_azul = {
            label = 'Paket Azul',
            category = 'Paket',
            package = true,
            toItems = { paket_azul = 1 },
            materials = { azul = 5 },
            craftingTime = 8000,
            maxCraft = 50,
            tables = { 'nightclub_packaging' },
            jobs = { nightclub = 0 },
        },

        paket_scarlettseduction = {
            label = 'Paket Scarlett Seduction',
            category = 'Paket',
            package = true,
            toItems = { paket_scarlettseduction = 1 },
            materials = { scarlettseduction = 5 },
            craftingTime = 8000,
            maxCraft = 50,
            tables = { 'nightclub_packaging' },
            jobs = { nightclub = 0 },
        },

        paket_sheridan = {
            label = 'Paket Sheridan',
            category = 'Paket',
            package = true,
            toItems = { paket_sheridan = 1 },
            materials = { sheridan = 5 },
            craftingTime = 8000,
            maxCraft = 50,
            tables = { 'nightclub_packaging' },
            jobs = { nightclub = 0 },
        },

        paket_cocomax = {
            label = 'Paket Cocomax',
            category = 'Paket',
            package = true,
            toItems = { paket_cocomax = 1 },
            materials = { cocomax = 5 },
            craftingTime = 8000,
            maxCraft = 50,
            tables = { 'nightclub_packaging' },
            jobs = { nightclub = 0 },
        },

        paket_alpha = {
            label = 'Paket Alpha',
            category = 'Paket',
            package = true,
            toItems = { paket_alpha = 1 },
            materials = { rootbeer = 5, baconfries = 5 },
            craftingTime = 8000,
            maxCraft = 50,
            tables = { 'nightclub_packaging' },
            jobs = { nightclub = 0 },
        },

        paket_sigma = {
            label = 'Paket Sigma',
            category = 'Paket',
            package = true,
            toItems = { paket_sigma = 1 },
            materials = { applecider = 5, calamari = 5 },
            craftingTime = 8000,
            maxCraft = 50,
            tables = { 'nightclub_packaging' },
            jobs = { nightclub = 0 },
        },
    },
}
