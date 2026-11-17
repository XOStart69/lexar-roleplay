return {
    blip = {
        hunting = {
            label = "Zona Berburu",
            color = 1,
            sprite = 442,
            category = 31,
            coords = vector3(70.3352, 6889.2812, 13.7479),
        },
        processing = {
            label = "Potong Hewan",
            color = 1,
            sprite = 442,
            category = 31,
            coords = vector3(3799.2, 4479.2, 6.0),
        },
    },

    huntingRifle = 'weapon_sniperrifle',
    blockShootingPlayers = true,
    killerNeededToSkin = true,
    processingTime = 5000,
    processingWeapon = 'weapon_hatchet',
    requireWeapon = true,

    zone = {
        center = vec3(70.3352, 6889.2812, 13.7479),
        radius = 100.0,
        maxAnimals = 6
    },

    processing = {
        coords = vec3(3799.2, 4479.2, 6.0),
        heading = 167.0
    },

    animals = {
        {
            model = 'a_c_deer',
            item = { add = { hunting_deer = 1 } },
            skin = { item = 'hunting_skin', min = 1, max = 6 },
            aggressive = false
        },
        {
            model = 'a_c_mtlion',
            item = { add = { hunting_mtlion = 1 } },
            skin = { item = 'hunting_skin', min = 1, max = 6 },
            aggressive = true
        },
        {
            model = 'a_c_boar',
            item = { add = { hunting_boar = 1 } },
            skin = { item = 'hunting_skin', min = 1, max = 6 },
            aggressive = true
        },
        {
            model = 'a_c_coyote',
            item = { add = { hunting_coyote = 1 } },
            skin = { item = 'hunting_skin', min = 1, max = 6 },
            aggressive = true
        },
        {
            model = 'a_c_chickenhawk',
            item = { add = { hunting_chickenhawk = 1 } },
            skin = { item = 'hunting_skin', min = 1, max = 6 },
            aggressive = false
        },
        {
            model = 'a_c_rabbit_01',
            item = { add = { hunting_rabbit = 1 } },
            skin = { item = 'hunting_skin', min = 1, max = 6 },
            aggressive = false
        },
        {
            model = 'a_c_crow',
            item = { add = { hunting_crow = 1 } },
            skin = { item = 'hunting_skin', min = 1, max = 6 },
            aggressive = false
        },
        {
            model = 'a_c_pigeon',
            item = { add = { hunting_pigeon = 1 } },
            skin = { item = 'hunting_skin', min = 1, max = 6 },
            aggressive = false
        },
        {
            model = 'a_c_seagull',
            item = { add = { hunting_seagull = 1 } },
            skin = { item = 'hunting_skin', min = 1, max = 6 },
            aggressive = false
        }
    }
}