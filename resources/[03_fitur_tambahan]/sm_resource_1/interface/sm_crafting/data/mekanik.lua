return {
    tables = {
        craftingmechanic = {
            title = 'Crafting Station',
            jobs = { mechanic = 0 },
            animation = { dict = 'mini@repair', anim = 'fixing_a_ped' },
            locations = { vector3(-2261.65, -428.6, 13.6) },
            icon = 'fas fa-tools',
        },

        craftingmechanic969 = {
            title = 'Crafting Station',
            jobs = { mechanic969 = 0 },
            animation = { dict = 'mini@repair', anim = 'fixing_a_ped' },
            locations = { vector3(1179.6, 2622.4, 39.0) },
            icon = 'fas fa-tools',
        },

        craftingkkpgarage = {
            title = 'Crafting Station',
            jobs = { kkpgarage = 0 },
            animation = { dict = 'mini@repair', anim = 'fixing_a_ped' },
            locations = { vector3(1376.413086, -2077.957031, 52.610306) },
            icon = 'fas fa-tools',
        },

        craftingmaxspeedgarages = {
            title = 'Crafting Station',
            jobs = { maxspeedgarage = 0 },
            animation = { dict = 'mini@repair', anim = 'fixing_a_ped' },
            locations = { vector3(-319.9, -119.8, 38.85) },
            icon = 'fas fa-tools',
        },

        craftingstunberg = {
            title = 'Crafting Station',
            jobs = { stunberg = 0 },
            animation = { dict = 'mini@repair', anim = 'fixing_a_ped' },
            locations = { vector3(-241.542389, 6227.460449, 31.911793) },
            icon = 'fas fa-tools',
        },
    },
    recipes = {
        advancedrepairkit3 = {
            category = 'Tools',
            toItems = { advancedrepairkit = 1 },
            materials = { copper = 1, radiator = 1 },
            maxCraft = 30,
            craftingTime = 5000,
            tables = { 'craftingmechanic969' },
        },

        advancedrepairkit1 = {
            category = 'Tools',
            toItems = { advancedrepairkit = 1 },
            materials = { copper = 1, radiator = 1 },
            maxCraft = 30,
            craftingTime = 5000,
            tables = { 'craftingmechanic' },
        },

        advancedrepairkit2 = {
            category = 'Tools',
            toItems = { advancedrepairkit = 1 },
            materials = { copper = 1, radiator = 1 },
            maxCraft = 30,
            craftingTime = 5000,
            tables = { 'craftingmaxspeedgarages' },
        },

        advancedrepairkit5 = {
            category = 'Tools',
            toItems = { advancedrepairkit = 1 },
            materials = { copper = 1, radiator = 1 },
            maxCraft = 30,
            craftingTime = 5000,
            tables = { 'craftingstunberg' },
        },

        advancedrepairkit6 = {
            category = 'Tools',
            toItems = { advancedrepairkit = 1 },
            materials = { copper = 1, radiator = 1 },
            maxCraft = 30,
            craftingTime = 5000,
            tables = { 'craftingkkpgarage' },
        },
    },
}
