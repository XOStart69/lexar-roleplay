return {
    tables = {
        burgenk_makanan = {
            title = 'Crafting Station',
            jobs = { burgenkcafe = 0 },
            animation = { dict = 'mini@repair', anim = 'fixing_a_ped' },
            locations = { vec3(1539.484009, 3793.562744, 34.548977) },
            icon = 'fas fa-burger',
        },

        burgenk_minuman = {
            title = 'Crafting Station',
            jobs = { burgenkcafe = 0 },
            animation = { dict = 'mini@repair', anim = 'fixing_a_ped' },
            locations = { vec3(1544.357056, 3792.758789, 34.549782) },
            icon = 'fas fa-burger',
        },

        restoburgenk_packaging = {
            title = 'Packaging 969Resto',
            icon = 'fas fa-box',
            jobs = { burgenkcafe = 0 },
            animation = { dict = 'mini@repair', anim = 'fixing_a_player' },
            locations = { vec3(1539.639526, 3797.131348, 34.427395) },
        },
    },
    recipes = {
        nasi_padang = {
            category = 'Nasi Padang',
            toItems = { nasi_padang = 10 },
            materials = { wheat = 1, packagedchicken = 1, telur = 1, garam = 1, sauce = 1 },
            craftingTime = 3000,
            tables = { 'burgenk_makanan' },
            jobs = { burgenkcafe = 1 },
        },

        mie_aceh = {
            category = 'Mie Aceh',
            toItems = { mie_aceh = 10 },
            materials = { chili = 1, packagedchicken = 1, tepung = 1, garam = 1, sauce = 1 },
            craftingTime = 3000,
            tables = { 'burgenk_makanan' },
            jobs = { burgenkcafe = 1 },
        },

        batagor = {
            category = 'Batagor',
            toItems = { batagor = 10 },
            materials = { telur = 1, packagedchicken = 1, tepung = 1, minyak_goreng = 1 },
            craftingTime = 3000,
            tables = { 'burgenk_makanan' },
            jobs = { burgenkcafe = 1 },
        },

        chocolate_love = {
            category = 'Chocolate Love',
            toItems = { chocolate_love = 10 },
            materials = { homemademilk = 1, corn = 1, tepung = 1, telur = 1, butter = 1 },
            craftingTime = 3000,
            tables = { 'burgenk_makanan' },
            jobs = { burgenkcafe = 1 },
        },

        soto_medan = {
            category = 'Soto Medan',
            toItems = { soto_medan = 10 },
            materials = { packagedchicken = 1, bawang = 1, garam = 1, santan = 1 },
            craftingTime = 3000,
            tables = { 'burgenk_makanan' },
            jobs = { burgenkcafe = 1 },
        },

        teh_tarik = {
            category = 'Teh tarik',
            toItems = { teh_tarik = 10 },
            materials = { homemademilk = 1, teh_saset = 1, esbatu = 1, cinnamon = 1 },
            craftingTime = 3000,
            tables = { 'burgenk_minuman' },
            jobs = { burgenkcafe = 1 },
        },

        es_kopi_sanger = {
            category = 'Es kopi sanger',
            toItems = { es_kopi_sanger = 10 },
            materials = { cinnamon = 1, creamy = 1, homemademilk = 1, esbatu = 1 },
            craftingTime = 3000,
            tables = { 'burgenk_minuman' },
            jobs = { burgenkcafe = 1 },
        },

        jus_markisa = {
            category = 'Jus Markisa',
            toItems = { jus_markisa = 10 },
            materials = { buah_markisa = 1, air = 1, esbatu = 1 },
            craftingTime = 3000,
            tables = { 'burgenk_minuman' },
            jobs = { burgenkcafe = 1 },
        },

        es_doger = {
            category = 'Es doger',
            toItems = { es_doger = 10 },
            materials = { kelapa = 1, homemademilk = 1, esbatu = 1 },
            craftingTime = 3000,
            tables = { 'burgenk_minuman' },
            jobs = { burgenkcafe = 1 },
        },

        ice_cream = {
            category = 'Ice cream',
            toItems = { ice_cream = 10 },
            materials = { homemademilk = 1, gula = 1, garam = 1, creamy = 1 },
            craftingTime = 3000,
            tables = { 'burgenk_minuman' },
            jobs = { burgenkcafe = 1 },
        },

        paket_padang = {
            label = 'Paket Padang',
            category = 'Paket',
            package = true,
            toItems = { paket_padang = 1 },
            materials = { nasi_padang = 10, teh_tarik = 10 },
            craftingTime = 10000,
            maxCraft = 50,
            tables = { 'restoburgenk_packaging' },
            jobs = { burgenkcafe = 0 },
        },

        paket_mieaceh = {
            label = 'Paket Mie Aceh',
            category = 'Paket',
            package = true,
            toItems = { paket_mieaceh = 1 },
            materials = { mie_aceh = 10, es_kopi_sanger = 10 },
            craftingTime = 10000,
            maxCraft = 50,
            tables = { 'restoburgenk_packaging' },
            jobs = { burgenkcafe = 0 },
        },

        paket_sotomedan = {
            label = 'Paket Soto Medan',
            category = 'Paket',
            package = true,
            toItems = { paket_sotomedan = 1 },
            materials = { soto_medan = 10, jus_markisa = 10 },
            craftingTime = 10000,
            maxCraft = 50,
            tables = { 'restoburgenk_packaging' },
            jobs = { burgenkcafe = 0 },
        },

        paket_manis = {
            label = 'Paket Manis isi 5',
            category = 'Paket',
            package = true,
            toItems = { paket_manis = 1 },
            materials = { chocolate_love = 5, ice_cream = 5 },
            craftingTime = 10000,
            maxCraft = 50,
            tables = { 'restoburgenk_packaging' },
            jobs = { burgenkcafe = 0 },
        },
    },
}
