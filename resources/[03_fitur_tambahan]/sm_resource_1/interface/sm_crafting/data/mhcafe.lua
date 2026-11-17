return {
    tables = {
        craftingmhcafemakanan = {
            title = 'Crafting Station',
            jobs = { mhcafe = 0 },
            animation = { dict = 'anim@amb@business@coc@coc_unpack_cut@', anim = 'fullcut_cycle_v7_cokecutter' },
            locations = { vector3(-258.263458, 6671.667480, 7.910167) },
            icon = 'fas fa-tools',
        },

        craftingmhcafeminuman = {
            title = 'Crafting Station',
            jobs = { mhcafe = 0 },
            animation = { dict = 'mini@repair', anim = 'fixing_a_ped' },
            locations = { vector3(-267.411743, 6673.391113, 8.450451) },
            icon = 'fas fa-tools',
        },

        mhcafe_packaging = {
            title = 'Packaging Maison Reinhart',
            icon = 'fas fa-box',
            jobs = { mhcafe = 0 },
            animation = { dict = 'mini@repair', anim = 'fixing_a_player' },
            locations = { vec3(-263.430817, 6666.76123, 8.247812) },
        },
    },
    recipes = {
        pastacreamychicken = {
            category = 'Food',
            toItems = { pastacreamychicken = 10 },
            materials = { tomato = 1, packagedchicken = 1, homemademilk = 1, butter = 1, garam = 1 },
            craftingTime = 3000,
            tables = { 'craftingmhcafemakanan' },
            jobs = { mhcafe = 2 },
        },

        spicygrilledsalmon = {
            category = 'Food',
            toItems = { spicygrilledsalmon = 10 },
            materials = { tomato = 1, chili = 1, carrot = 1, salmon = 1, sauce = 1 },
            craftingTime = 3000,
            tables = { 'craftingmhcafemakanan' },
            jobs = { mhcafe = 2 },
        },

        prawnsalad = {
            category = 'Food',
            toItems = { prawnsalad = 10 },
            materials = { tomato = 1, jeruk = 1, corn = 1, lada = 1, garam = 1 },
            craftingTime = 3000,
            tables = { 'craftingmhcafemakanan' },
            jobs = { mhcafe = 2 },
        },

        matchabruleecream = {
            category = 'Food',
            toItems = { matchabruleecream = 10 },
            materials = { homemademilk = 1, matchapowder = 1, gula = 1, air = 1 },
            craftingTime = 3000,
            tables = { 'craftingmhcafemakanan' },
            jobs = { mhcafe = 2 },
        },

        minichickensliders = {
            category = 'Food',
            toItems = { minichickensliders = 10 },
            materials = { packagedchicken = 1, burger_buns = 1, keju = 1, sauce = 1 },
            craftingTime = 3000,
            tables = { 'craftingmhcafemakanan' },
            jobs = { mhcafe = 2 },
        },

        tropicalorange = {
            category = 'Drinks',
            toItems = { tropicalorange = 10 },
            materials = { jeruk = 1, soda = 1, air = 1, esbatu = 1 },
            craftingTime = 3000,
            tables = { 'craftingmhcafeminuman' },
            jobs = { mhcafe = 2 },
        },

        peachtea = {
            category = 'Drinks',
            toItems = { peachtea = 10 },
            materials = { buahpeach = 1, kantongteh = 1, air = 1, esbatu = 1 },
            craftingTime = 3000,
            tables = { 'craftingmhcafeminuman' },
            jobs = { mhcafe = 2 },
        },

        matchalattemh = {
            category = 'Drinks',
            toItems = { matchalattemh = 10 },
            materials = { matchapowder = 1, homemademilk = 1, air = 1, esbatu = 1 },
            craftingTime = 3000,
            tables = { 'craftingmhcafeminuman' },
            jobs = { mhcafe = 2 },
        },

        sweetcorncocktail = {
            category = 'Drinks',
            toItems = { sweetcorncocktail = 10 },
            materials = { corn = 1, soda = 1, syrup = 1, esbatu = 1 },
            craftingTime = 3000,
            tables = { 'craftingmhcafeminuman' },
            jobs = { mhcafe = 2 },
        },

        tropicalmangobreeze = {
            category = 'Drinks',
            toItems = { tropicalmangobreeze = 10 },
            materials = { mangga = 1, homemademilk = 1, air = 1, soda = 1 },
            craftingTime = 3000,
            tables = { 'craftingmhcafeminuman' },
            jobs = { mhcafe = 2 },
        },

        paket_creamy = {
            label = 'Creamy Sunset Pair',
            category = 'Paket',
            package = true,
            toItems = { paket_creamy = 1 },
            materials = { pastacreamychicken = 10, tropicalmangobreeze = 10 },
            craftingTime = 10000,
            maxCraft = 50,
            tables = { 'mhcafe_packaging' },
            jobs = { mhcafe = 0 },
        },

        paket_oceanspice = {
            label = 'Ocean Spice Pair',
            category = 'Paket',
            package = true,
            toItems = { paket_oceanspice = 1 },
            materials = { spicygrilledsalmon = 10, tropicalorange = 10 },
            craftingTime = 10000,
            maxCraft = 50,
            tables = { 'mhcafe_packaging' },
            jobs = { mhcafe = 0 },
        },

        paket_freshtrop = {
            label = 'Fresh Tropical Pair',
            category = 'Paket',
            package = true,
            toItems = { paket_freshtrop = 1 },
            materials = { prawnsalad = 10, sweetcorncocktail = 10 },
            craftingTime = 10000,
            maxCraft = 50,
            tables = { 'mhcafe_packaging' },
            jobs = { mhcafe = 0 },
        },

        paket_dessertcalm = {
            label = 'Dessert Calm Pair',
            category = 'Paket',
            package = true,
            toItems = { paket_dessertcalm = 1 },
            materials = { matchabruleecream = 5, matchalattemh = 5 },
            craftingTime = 10000,
            maxCraft = 50,
            tables = { 'mhcafe_packaging' },
            jobs = { mhcafe = 0 },
        },

        paket_kidsmeal_cslider = {
            label = 'Paket Kids Meal Chicken Slider',
            category = 'Paket',
            package = true,
            toItems = { paket_kidsmeal_cslider = 1 },
            materials = { minichickensliders = 10, peachtea = 10 },
            craftingTime = 10000,
            maxCraft = 50,
            tables = { 'mhcafe_packaging' },
            jobs = { mhcafe = 0 },
        },
    },
}
