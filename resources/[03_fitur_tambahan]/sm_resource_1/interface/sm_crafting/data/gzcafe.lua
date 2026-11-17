return {
    tables = {
        craftinggzcafemakanan = {
            title = 'Crafting Station',
            jobs = { gzcafe = 2 },
            animation = { dict = 'anim@amb@business@coc@coc_unpack_cut@', anim = 'fullcut_cycle_v7_cokecutter' },
            locations = { vec3(-2186.13, 4250.41, 48.74) },
            icon = 'fas fa-tools',
        },

        craftinggzcafeminuman = {
            title = 'Crafting Station',
            jobs = { gzcafe = 2 },
            animation = { dict = 'mini@repair', anim = 'fixing_a_ped' },
            locations = { vec3(-2183.73, 4245.80, 48.77) },
            icon = 'fas fa-tools',
        },

        ginzcafe_packaging = {
            title = 'Packaging ECL Kedai',
            icon = 'fas fa-box',
            jobs = { gzcafe = 0 },
            animation = { dict = 'mini@repair', anim = 'fixing_a_player' },
            locations = { vec3(-2188.50, 4248.98, 48.89) },
        },
    },
    recipes = {
        lontongbalap = {
            category = 'Food',
            toItems = { lontongbalap = 10 },
            materials = { wheat = 1, carrot = 1, packagedchicken = 1, tauge = 1, bawang = 1 },
            craftingTime = 3000,
            tables = { 'craftinggzcafemakanan' },
            jobs = { gzcafe = 2 },
        },

        mie_nyemek = {
            category = 'Food',
            toItems = { mie_nyemek = 10 },
            materials = { wheat = 1, bawang = 1, garam = 1, telur = 1, daun_bawang = 1 },
            craftingTime = 3000,
            tables = { 'craftinggzcafemakanan' },
            jobs = { gzcafe = 2 },
        },

        cumi_bakar = {
            category = 'Food',
            toItems = { cumi_bakar = 10 },
            materials = { cumi = 1, bawang = 1, garam = 1, kecapmanis = 1 },
            craftingTime = 3000,
            tables = { 'craftinggzcafemakanan' },
            jobs = { gzcafe = 2 },
        },

        corndog = {
            category = 'Food',
            toItems = { corndog = 10 },
            materials = { gula = 1, sosis = 1 },
            craftingTime = 3000,
            tables = { 'craftinggzcafemakanan' },
            jobs = { gzcafe = 2 },
        },

        mini_pancake = {
            category = 'Food',
            toItems = { mini_pancake = 10 },
            materials = { tepung = 1, telur = 1, gula = 1, butter = 1 },
            craftingTime = 3000,
            tables = { 'craftinggzcafemakanan' },
            jobs = { gzcafe = 2 },
        },

        soda_gembira = {
            category = 'Drinks',
            toItems = { soda_gembira = 10 },
            materials = { soda = 1, homemademilk = 1, air = 1 },
            craftingTime = 3000,
            tables = { 'craftinggzcafeminuman' },
            jobs = { gzcafe = 2 },
        },

        kelpshake_soda = {
            category = 'Drinks',
            toItems = { kelpshake_soda = 10 },
            materials = { esbatu = 1, air = 1, bubuk_kelpshake = 1 },
            craftingTime = 3000,
            tables = { 'craftinggzcafeminuman' },
            jobs = { gzcafe = 2 },
        },

        esmilo = {
            category = 'Drinks',
            toItems = { esmilo = 10 },
            materials = { milosachet = 1, homemademilk = 1, air = 1, esbatu = 1 },
            craftingTime = 3000,
            tables = { 'craftinggzcafeminuman' },
            jobs = { gzcafe = 2 },
        },

        es_tebu = {
            category = 'Drinks',
            toItems = { es_tebu = 10 },
            materials = { tebu = 1, air = 1, esbatu = 1 },
            craftingTime = 3000,
            tables = { 'craftinggzcafeminuman' },
            jobs = { gzcafe = 2 },
        },

        esdawet = {
            category = 'Drinks',
            toItems = { esdawet = 10 },
            materials = { tepung_ketan = 1, homemademilk = 1, santan = 1, esbatu = 1 },
            craftingTime = 3000,
            tables = { 'craftinggzcafeminuman' },
            jobs = { gzcafe = 2 },
        },

        paket_kidsmeal_kedaiygm = {
            label = 'Paket Kids Meal ECL Kedai',
            category = 'Paket',
            package = true,
            toItems = { paket_kidsmeal_kedaiygm = 1 },
            materials = { mini_pancake = 10, kelpshake_soda = 10 },
            craftingTime = 10000,
            maxCraft = 50,
            tables = { 'ginzcafe_packaging' },
            jobs = { gzcafe = 0 },
        },

        paket_lontong = {
            label = 'Paket Lontong Seger',
            category = 'Paket',
            package = true,
            toItems = { paket_lontong = 1 },
            materials = { lontongbalap = 10, esdawet = 10 },
            craftingTime = 10000,
            maxCraft = 50,
            tables = { 'ginzcafe_packaging' },
            jobs = { gzcafe = 0 },
        },

        paket_mie_nyemek = {
            label = 'Paket Mie Nyemek',
            category = 'Paket',
            package = true,
            toItems = { paket_mie_nyemek = 1 },
            materials = { mie_nyemek = 10, es_tebu = 10 },
            craftingTime = 10000,
            maxCraft = 50,
            tables = { 'ginzcafe_packaging' },
            jobs = { gzcafe = 0 },
        },

        paket_sweetsnack = {
            label = 'Sweet Snack Combo',
            category = 'Paket',
            package = true,
            toItems = { paket_sweetsnack = 1 },
            materials = { corndog = 10, esmilo = 10 },
            craftingTime = 10000,
            maxCraft = 50,
            tables = { 'ginzcafe_packaging' },
            jobs = { gzcafe = 0 },
        },
        paket_cumbak = {
            label = 'Paket Cumi Bakar & Soda Gembira',
            category = 'Paket',
            package = true,
            toItems = { paket_cumbak = 1 },
            materials = { cumi_bakar = 10, soda_gembira = 10 },
            craftingTime = 10000,
            maxCraft = 50,
            tables = { 'ginzcafe_packaging' },
            jobs = { gzcafe = 0 },
        },
    },
}
