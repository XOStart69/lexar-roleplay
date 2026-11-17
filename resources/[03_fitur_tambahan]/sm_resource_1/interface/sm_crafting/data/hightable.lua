return {
    tables = {
        craftinghightable = {
            title = 'Crafting High Table',
            icon = 'fas fa-tools',
            jobs = { hightable = 2 },
            animation = { dict = 'mini@repair', anim = 'fixing_a_ped' },
            locations = {
                vec3(2020.44, 3011.40, -72.90),
            },
        },
    },
    recipes = {
        ilegal_gasmask = {
            category = 'Perlengkapan',
            toItems = { ilegal_gasmask = 1 },
            materials = { plastic = 1, fabric = 1, rubber = 1 },
            craftingTime = 3000,
            tables = { 'craftinghightable' },
        },

        c4 = {
            category = 'Bahan Peledak',
            toItems = { c4 = 1 },
            materials = { sulfur = 1, steel = 1, metalscrap = 1, glass = 1 },
            craftingTime = 3000,
            tables = { 'craftinghightable' },
        },

        triggerc4 = {
            category = 'Bahan Peledak',
            toItems = { triggerc4 = 1 },
            materials = { sulfur = 1, steel = 1, metalscrap = 1, plastic = 2 },
            craftingTime = 3000,
            tables = { 'craftinghightable' },
        },
    },
}
