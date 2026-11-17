return {
    tables = {
        craftingpdcafemakanan = {
            title = 'Crafting Station',
            jobs = { pdcafe = 0 },
            animation = { dict = 'anim@amb@business@coc@coc_unpack_cut@', anim = 'fullcut_cycle_v7_cokecutter' },
            locations = { vector3(-1309.474854, 6972.825195, 20.418594) },
            icon = 'fas fa-tools',
        },

        craftingpdcafeminuman = {
            title = 'Crafting Station',
            jobs = { pdcafe = 0 },
            animation = { dict = 'mini@repair', anim = 'fixing_a_ped' },
            locations = { vector3(-1304.641724, 6974.511230, 20.652430) },
            icon = 'fas fa-tools',
        },

        atomburger_packaging = {
            title = 'Packaging Atom n Burger',
            icon = 'fas fa-box',
            jobs = { pdcafe = 0 },
            animation = { dict = 'mini@repair', anim = 'fixing_a_player' },
            locations = { vec3(-1309.260742, 6978.413574, 20.588211) },
        },
    },
    recipes = {
        scwings = {
            category = 'Food',
            toItems = { scwings = 10 },
            materials = { packagedchicken = 1, kol_selada = 1, sauce = 1, tepung = 1, chili = 1 },
            craftingTime = 3000,
            tables = { 'craftingpdcafemakanan' },
            jobs = { pdcafe = 2 },
        },

        ccsandwich = {
            category = 'Food',
            toItems = { ccsandwich = 10 },
            materials = { burger_buns = 1, packagedchicken = 1, corn = 1, creamy = 1, keju = 1 },
            craftingTime = 3000,
            tables = { 'craftingpdcafemakanan' },
            jobs = { pdcafe = 2 },
        },

        omcheese = {
            category = 'Food',
            toItems = { omcheese = 10 },
            materials = { telur = 1, keju = 1, butter = 1, carrot = 1, tomato = 1 },
            craftingTime = 3000,
            tables = { 'craftingpdcafemakanan' },
            jobs = { pdcafe = 2 },
        },

        macaron = {
            category = 'Food',
            toItems = { macaron = 10 },
            materials = { telur = 1, gula = 1, butter = 1, homemademilk = 2 },
            craftingTime = 3000,
            tables = { 'craftingpdcafemakanan' },
            jobs = { pdcafe = 2 },
        },

        scpancake = {
            category = 'Food',
            toItems = { scpancake = 10 },
            materials = { carrot = 1, corn = 1, tepung = 1, butter = 1, gula = 1 },
            craftingTime = 3000,
            tables = { 'craftingpdcafemakanan' },
            jobs = { pdcafe = 2 },
        },

        syogurtsmoothie = {
            category = 'Drinks',
            toItems = { syogurtsmoothie = 10 },
            materials = { strawberry = 1, yogurt_plain = 1, homemademilk = 1, gula = 1 },
            craftingTime = 3000,
            tables = { 'craftingpdcafeminuman' },
            jobs = { pdcafe = 2 },
        },

        icofeemilk = {
            category = 'Drinks',
            toItems = { icofeemilk = 10 },
            materials = { oliangcoffee = 1, homemademilk = 1, gula = 1, esbatu = 1 },
            craftingTime = 3000,
            tables = { 'craftingpdcafeminuman' },
            jobs = { pdcafe = 2 },
        },

        orangesoda = {
            category = 'Drinks',
            toItems = { orangesoda = 10 },
            materials = { soda = 1, air = 1, jeruk = 1, esbatu = 1 },
            craftingTime = 3000,
            tables = { 'craftingpdcafeminuman' },
            jobs = { pdcafe = 2 },
        },

        whitefrappe = {
            category = 'Drinks',
            toItems = { whitefrappe = 10 },
            materials = { homemademilk = 1, gula = 1, esbatu = 1 },
            craftingTime = 3000,
            tables = { 'craftingpdcafeminuman' },
            jobs = { pdcafe = 2 },
        },

        carjuice = {
            category = 'Drinks',
            toItems = { carjuice = 10 },
            materials = { carrot = 1, gula = 1, esbatu = 1 },
            craftingTime = 3000,
            tables = { 'craftingpdcafeminuman' },
            jobs = { pdcafe = 2 },
        },

        paket_atomwings = {
            label = 'ATOM WINGS BOX',
            category = 'Paket',
            package = true,
            toItems = { paket_atomwings = 1 },
            materials = { scwings = 10, icofeemilk = 10 },
            craftingTime = 10000,
            maxCraft = 50,
            tables = { 'atomburger_packaging' },
            jobs = { pdcafe = 0 },
        },

        paket_sandwichtom = {
            label = 'ATOM SANDWICH PACK',
            category = 'Paket',
            package = true,
            toItems = { paket_sandwichtom = 1 },
            materials = { ccsandwich = 10, orangesoda = 10 },
            craftingTime = 10000,
            maxCraft = 50,
            tables = { 'atomburger_packaging' },
            jobs = { pdcafe = 0 },
        },

        paket_omeletetom = {
            label = 'ATOM OMELETTE MEAL',
            category = 'Paket',
            package = true,
            toItems = { paket_omeletetom = 1 },
            materials = { omcheese = 10, syogurtsmoothie = 10 },
            craftingTime = 10000,
            maxCraft = 50,
            tables = { 'atomburger_packaging' },
            jobs = { pdcafe = 0 },
        },

        paket_sweettom = {
            label = 'ATOM SWEET BOX',
            category = 'Paket',
            package = true,
            toItems = { paket_sweettom = 1 },
            materials = { macaron = 10, whitefrappe = 10 },
            craftingTime = 10000,
            maxCraft = 50,
            tables = { 'atomburger_packaging' },
            jobs = { pdcafe = 0 },
        },

        paket_kidstom = {
            label = 'ATOM KIDS BOX',
            category = 'Paket',
            package = true,
            toItems = { paket_kidstom = 1 },
            materials = { scpancake = 10, carjuice = 10 },
            craftingTime = 10000,
            maxCraft = 50,
            tables = { 'atomburger_packaging' },
            jobs = { pdcafe = 0 },
        },
    },
}
