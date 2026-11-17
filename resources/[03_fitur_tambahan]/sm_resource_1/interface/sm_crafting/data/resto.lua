return {
    tables = {
        craftingresto = {
            title = 'Crafting Station',
            jobs = { resto = 0 },
            animation = { dict = 'anim@amb@business@coc@coc_unpack_cut@', anim = 'fullcut_cycle_v7_cokecutter' },
            locations = { vector3(-1771.8, -1217.35, 14.65) },
            icon = 'fas fa-tools',
        },

        nusantara_packaging = {
            title = 'Packaging Nusantara Resto',
            icon = 'fas fa-box',
            jobs = { resto = 0 },
            animation = { dict = 'mini@repair', anim = 'fixing_a_player' },
            locations = { vec3(-1772.598511, -1213.082275, 14.704207) },
        },
    },
    recipes = {
        gudeg = {
            category = 'Food',
            toItems = { gudeg = 10 },
            materials = { wheat = 1, telur = 1, chili = 1, garam = 1, bawang = 1 },
            craftingTime = 3000,
            tables = { 'craftingresto' },
            jobs = { resto = 2 },
        },

        bubur_ayam = {
            category = 'Food',
            toItems = { bubur_ayam = 10 },
            materials = { bawang = 1, wheat = 1, garam = 1, packagedchicken = 1 },
            craftingTime = 3000,
            tables = { 'craftingresto' },
            jobs = { resto = 2 },
        },

        siomay_kidsmeal = {
            category = 'Food',
            toItems = { siomay_kidsmeal = 10 },
            materials = { ikan = 1, tepung = 1, air = 1, garam = 1 },
            craftingTime = 3000,
            tables = { 'craftingresto' },
            jobs = { resto = 2 },
        },

        strawberry_milktea = {
            category = 'Drinks',
            toItems = { strawberry_milktea = 10 },
            materials = { air = 1, strawberry = 1, homemademilk = 1 },
            craftingTime = 3000,
            tables = { 'craftingresto' },
            jobs = { resto = 2 },
        },

        esbuah_kidsmeal = {
            category = 'Drinks',
            toItems = { esbuah_kidsmeal = 10 },
            materials = { strawberry = 1, grape = 1, homemademilk = 1 },
            craftingTime = 3000,
            tables = { 'craftingresto' },
            jobs = { resto = 2 },
        },

        bakso = {
            category = 'Food',
            toItems = { bakso = 10 },
            materials = { packagedchicken = 1, bawang = 1, chili = 1, tepung = 1, garam = 1 },
            craftingTime = 3000,
            tables = { 'craftingresto' },
            jobs = { resto = 2 },
        },

        satemaranggi = {
            category = 'Food',
            toItems = { satemaranggi = 10 },
            materials = { packagedchicken = 1, chili = 1, tomato = 1, bawang = 1, tusuksate = 1 },
            craftingTime = 3000,
            tables = { 'craftingresto' },
            jobs = { resto = 2 },
        },

        esjeruk = {
            category = 'Drinks',
            toItems = { esjeruk = 10 },
            materials = { air = 1, gula = 1, jeruk = 1, esbatu = 1 },
            craftingTime = 3000,
            tables = { 'craftingresto' },
            jobs = { resto = 2 },
        },

        eskelapa = {
            category = 'Drinks',
            toItems = { eskelapa = 10 },
            materials = { kelapa = 1, esbatu = 1 },
            craftingTime = 3000,
            tables = { 'craftingresto' },
            jobs = { resto = 2 },
        },

        esteh = {
            category = 'Drinks',
            toItems = { esteh = 10 },
            materials = { gula = 1, esbatu = 1, kantongteh = 1 },
            craftingTime = 3000,
            tables = { 'craftingresto' },
            jobs = { resto = 2 },
        },

        paket_sate = {
            label = 'Paket Sate',
            category = 'Paket',
            package = true,
            toItems = { paket_sate = 1 },
            materials = { satemaranggi = 10, esjeruk = 10 },
            craftingTime = 10000,
            maxCraft = 50,
            tables = { 'nusantara_packaging' },
            jobs = { resto = 0 },
        },

        paket_gudeg = {
            label = 'Paket Gudeg',
            category = 'Paket',
            package = true,
            toItems = { paket_gudeg = 1 },
            materials = { gudeg = 10, eskelapa = 10 },
            craftingTime = 10000,
            maxCraft = 50,
            tables = { 'nusantara_packaging' },
            jobs = { resto = 0 },
        },

        paket_baksoesteh = {
            label = 'Paket Bakso Esteh',
            category = 'Paket',
            package = true,
            toItems = { paket_baksoesteh = 1 },
            materials = { bakso = 10, esteh = 10 },
            craftingTime = 10000,
            maxCraft = 50,
            tables = { 'nusantara_packaging' },
            jobs = { resto = 0 },
        },

        paket_kidsmeal_bubur = {
            label = 'Paket Kids Meal Bubur Ayam',
            category = 'Paket',
            package = true,
            toItems = { paket_kidsmeal_bubur = 1 },
            materials = { bubur_ayam = 10, strawberry_milktea = 10 },
            craftingTime = 10000,
            maxCraft = 50,
            tables = { 'nusantara_packaging' },
            jobs = { resto = 0 },
        },

        paket_cemilan_nusantara = {
            label = 'Paket Cemilan Siomay & Sop Buah',
            category = 'Paket',
            package = true,
            toItems = { paket_cemilan_nusantara = 1 },
            materials = { siomay_kidsmeal = 5, esbuah_kidsmeal = 5 },
            craftingTime = 10000,
            maxCraft = 50,
            tables = { 'nusantara_packaging' },
            jobs = { resto = 0 },
        },
    },
}
