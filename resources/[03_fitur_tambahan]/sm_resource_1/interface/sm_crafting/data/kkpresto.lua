return {
    tables = {
        craftingkkpresto = {
            title = 'Crafting Station',
            jobs = { kkpresto = 0 },
            animation = { dict = 'anim@amb@business@coc@coc_unpack_cut@', anim = 'fullcut_cycle_v7_cokecutter' },
            locations = { vector3(-591.1, -1056.6, 22.25) },
            icon = 'fas fa-tools',
        },

        kkpresto_packaging = {
            title = 'Packaging KKP',
            icon = 'fas fa-box',
            jobs = { kkpresto = 0 },
            animation = { dict = 'mini@repair', anim = 'fixing_a_player' },
            locations = { vec3(-587.884583, -1059.56958, 22.261929) },
        },
    },
    recipes = {
        goongten = {
            category = 'Food',
            toItems = { goongten = 10 },
            materials = { udang = 1, tomato = 1, chili = 1, garam = 1 },
            craftingTime = 3000,
            tables = { 'craftingkkpresto' },
            jobs = { kkpresto = 2 },
        },

        chewycookie = {
            category = 'Food',
            toItems = { chewycookie = 10 },
            materials = { tepung = 1, homemademilk = 1, kimpul = 1 },
            craftingTime = 3000,
            tables = { 'craftingkkpresto' },
            jobs = { kkpresto = 2 },
        },

        chickensteak = {
            category = 'Food',
            toItems = { chickensteak = 10 },
            materials = { packagedchicken = 1, tepung = 1, bawang = 1, garam = 1 },
            craftingTime = 3000,
            tables = { 'craftingkkpresto' },
            jobs = { kkpresto = 2 },
        },

        icecreamatcha = {
            category = 'Drinks',
            toItems = { icecreamatcha = 10 },
            materials = { homemademilk = 1, matchapowder = 1, air = 1 },
            craftingTime = 3000,
            tables = { 'craftingkkpresto' },
            jobs = { kkpresto = 2 },
        },

        padthai = {
            category = 'Food',
            toItems = { padthai = 10 },
            materials = { chili = 1, tomato = 1, telur = 1, miekuning = 1, tauge = 1 },
            craftingTime = 3000,
            tables = { 'craftingkkpresto' },
            jobs = { kkpresto = 2 },
        },

        somtam = {
            category = 'Food',
            toItems = { somtam = 10 },
            materials = { tomato = 1, carrot = 1, kecapikan = 1, gulamerah = 1, bawang = 1 },
            craftingTime = 3000,
            tables = { 'craftingkkpresto' },
            jobs = { kkpresto = 2 },
        },

        tomyum = {
            category = 'Food',
            toItems = { tomyum = 10 },
            materials = { corn = 1, jeruk = 1, chili = 1, udang = 1, jamur = 1 },
            craftingTime = 3000,
            tables = { 'craftingkkpresto' },
            jobs = { kkpresto = 2 },
        },

        thaigreantea = {
            category = 'Drinks',
            toItems = { thaigreantea = 10 },
            materials = { esbatu = 1, air = 1, matchapowder = 1 },
            craftingTime = 3000,
            tables = { 'craftingkkpresto' },
            jobs = { kkpresto = 2 },
        },

        nampraotan = {
            category = 'Drinks',
            toItems = { nampraotan = 10 },
            materials = { kelapa_parut = 1, gula = 1, homemademilk = 1, esbatu = 1 },
            craftingTime = 3000,
            tables = { 'craftingkkpresto' },
            jobs = { kkpresto = 2 },
        },

        thaitea = {
            category = 'Drinks',
            toItems = { thaitea = 10 },
            materials = { homemademilk = 1, gula = 1, thaiteasachet = 1, esbatu = 1 },
            craftingTime = 3000,
            tables = { 'craftingkkpresto' },
            jobs = { kkpresto = 2 },
        },

        nomyen = {
            category = 'Drinks',
            toItems = { nomyen = 10 },
            materials = { homemademilk = 1, syrup = 1, esbatu = 1, air = 1 },
            craftingTime = 3000,
            tables = { 'craftingkkpresto' },
            jobs = { kkpresto = 2 },
        },

        oliang = {
            category = 'Drinks',
            toItems = { oliang = 10 },
            materials = { oliangcoffee = 1, gula = 1, esbatu = 1, air = 1 },
            craftingTime = 3000,
            tables = { 'craftingkkpresto' },
            jobs = { kkpresto = 2 },
        },

        paket_kidsmeal_chickenkimpul = {
            label = 'Paket Kids Meal Chicken Kimpul',
            category = 'Paket',
            package = true,
            toItems = { paket_kidsmeal_chickenkimpul = 1 },
            materials = { chickensteak = 10, thaigreantea = 10 },
            craftingTime = 10000,
            maxCraft = 50,
            tables = { 'kkpresto_packaging' },
            jobs = { kkpresto = 0 },
        },

        paket_padthai = {
            label = 'Paket Padthai',
            category = 'Paket',
            package = true,
            toItems = { paket_padthai = 1 },
            materials = { padthai = 10, thaitea = 10 },
            craftingTime = 10000,
            maxCraft = 50,
            tables = { 'kkpresto_packaging' },
            jobs = { kkpresto = 0 },
        },

        paket_somtam = {
            label = 'Paket Somtam',
            category = 'Paket',
            package = true,
            toItems = { paket_somtam = 1 },
            materials = { somtam = 10, nomyen = 10 },
            craftingTime = 10000,
            maxCraft = 50,
            tables = { 'kkpresto_packaging' },
            jobs = { kkpresto = 0 },
        },

        paket_tomyum = {
            label = 'Paket Tomyum',
            category = 'Paket',
            package = true,
            toItems = { paket_tomyum = 1 },
            materials = { tomyum = 10, oliang = 10 },
            craftingTime = 10000,
            maxCraft = 50,
            tables = { 'kkpresto_packaging' },
            jobs = { kkpresto = 0 },
        },

        paket_freshseafood = {
            label = 'Paket Goong Ten',
            category = 'Paket',
            package = true,
            toItems = { paket_freshseafood = 1 },
            materials = { goongten = 10, nampraotan = 10 },
            craftingTime = 10000,
            maxCraft = 50,
            tables = { 'kkpresto_packaging' },
            jobs = { kkpresto = 0 },
        },

        paket_cemilan_kkp = {
            label = 'Paket Cemilan Cookie & Ice Cream Matcha',
            category = 'Paket',
            package = true,
            toItems = { paket_cemilan_kkp = 1 },
            materials = { chewycookie = 5, icecreamatcha = 5 },
            craftingTime = 10000,
            maxCraft = 50,
            tables = { 'kkpresto_packaging' },
            jobs = { kkpresto = 0 },
        },
    },
}
