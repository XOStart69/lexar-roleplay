return {
    tables = {
        craftingmedis = {
            title = 'Racik Obat',
            icon = 'fas fa-briefcase-medical',
            jobs = { ambulance = 3, rsroxwood = 3 },
            animation = { dict = 'mini@repair', anim = 'fixing_a_player' },
            locations = {
                vec3(-566.34, 7358.55, 8.67),
                vec3(242.80, -1371.30, 39.55),
                vec3(1165.06, -1556.98, 30.38),
            },
        },
    },
    recipes = {
        obat_custom = {
            category = 'Obat Racikan',
            toItems = { obat_custom = 1 },
            materials = { firstaid = 1, bawang = 1 },
            craftingTime = 3000,
            tables = { 'craftingmedis' },
            jobs = { ambulance = 3, rsroxwood = 3 },
        },

        paracetamol = {
            category = 'Obat',
            toItems = { paracetamol = 1 },
            materials = { firstaid = 1, bawang = 1 },
            craftingTime = 3000,
            tables = { 'craftingmedis' },
            jobs = { admin = 0 },
        },

        bandage = {
            category = 'Obat',
            toItems = { bandage = 1 },
            materials = { clothes = 1 },
            craftingTime = 3000,
            tables = { 'craftingmedis' },
            jobs = { admin = 0 },
        },
    },
}
