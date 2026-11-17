return {
    tables = {
        craftingdigitalden = {
            title = 'Crafting Station',
            jobs = { digitalden = 2 },
            animation = { dict = 'anim@amb@business@coc@coc_unpack_cut@', anim = 'fullcut_cycle_v7_cokecutter' },
            locations = { vector3(-1315.75, -399.95, 37.2) },
            icon = 'fas fa-tools',
        },

        craftingwartelsm = {
            title = 'Crafting Station',
            jobs = { wartelsm = 2 },
            animation = { dict = 'anim@amb@business@coc@coc_unpack_cut@', anim = 'fullcut_cycle_v7_cokecutter' },
            locations = { vector3(-766.308411, 5602.113281, 33.830742) },
            icon = 'fas fa-tools',
        },

        craftingdigitaldenroxwood = {
            title = 'Crafting Station',
            jobs = { digitaldenroxwood = 2 },
            animation = { dict = 'anim@amb@business@coc@coc_unpack_cut@', anim = 'fullcut_cycle_v7_cokecutter' },
            locations = { vector3(-2930.15, 6241.00, 9.85) },
            icon = 'fas fa-tools',
        },
    },
    recipes = {
        speaker_retro = {
            label = 'Speaker Retro',
            toItems = { speaker = 1 },
            toItemsMeta = {
                speaker = {
                    typeId = 1,
                    label = 'Speaker Retro',
                    description = 'Low volume, range and quality.',
                    imageurl = 'https://media.rahe.dev/img/boombox.png',
                },
            },
            materials = { plastic = 40, steel = 25, glass = 20, rubber = 10, metalscrap = 5 },
            craftingTime = 5000,
            category = 'Electronic',
            tables = { 'craftingwartelsm', 'craftingdigitalden', 'craftingdigitaldenroxwood' },
            jobs = { wartelsm = 0, digitalden = 0, digitaldenroxwood = 0 },
        },

        speaker_vibe = {
            label = 'Speaker Vibe',
            toItems = { speaker = 1 },
            toItemsMeta = {
                speaker = {
                    typeId = 2,
                    label = 'Speaker Vibe',
                    description = 'Good volume, range and quality.',
                    imageurl = 'https://media.rahe.dev/img/speaker1.png',
                },
            },
            materials = { plastic = 30, steel = 30, glass = 20, rubber = 12, metalscrap = 8 },
            craftingTime = 5000,
            category = 'Electronic',
            tables = { 'craftingwartelsm', 'craftingdigitalden', 'craftingdigitaldenroxwood' },
            jobs = { wartelsm = 0, digitalden = 0, digitaldenroxwood = 0 },
        },

        speaker_beat = {
            label = 'Speaker Beat',
            toItems = { speaker = 1 },
            toItemsMeta = {
                speaker = {
                    typeId = 3,
                    label = 'Speaker Beat',
                    description = 'Great volume, range, quality and bass.',
                    imageurl = 'https://media.rahe.dev/img/speaker2.png',
                },
            },
            materials = { plastic = 35, steel = 30, glass = 15, rubber = 15, metalscrap = 7 },
            craftingTime = 5000,
            category = 'Electronic',
            tables = { 'craftingwartelsm', 'craftingdigitalden', 'craftingdigitaldenroxwood' },
            jobs = { wartelsm = 0, digitalden = 0, digitaldenroxwood = 0 },
        },

        speaker_blast = {
            label = 'Speaker Blast',
            toItems = { speaker = 1 },
            toItemsMeta = {
                speaker = {
                    typeId = 4,
                    label = 'Speaker Blast',
                    description = 'Epic volume, range, quality, bass and filters.',
                    imageurl = 'https://media.rahe.dev/img/speaker3.png',
                },
            },
            materials = { plastic = 25, steel = 35, glass = 20, rubber = 15, metalscrap = 8 },
            craftingTime = 5000,
            category = 'Electronic',
            tables = { 'craftingwartelsm', 'craftingdigitalden', 'craftingdigitaldenroxwood' },
            jobs = { wartelsm = 0, digitalden = 0, digitaldenroxwood = 0 },
        },

        phone = {
            category = 'Electronic',
            toItems = { phone = 4 },
            materials = { plastic = 1, glass = 1 },
            craftingTime = 3000,
            tables = { 'craftingdigitalden', 'craftingdigitaldenroxwood' },
            jobs = { digitalden = 0, digitaldenroxwood = 0 },
        },

        radio = {
            category = 'Electronic',
            toItems = { radio = 4 },
            materials = { rubber = 1 },
            craftingTime = 3000,
            tables = { 'craftingdigitalden', 'craftingdigitaldenroxwood' },
            jobs = { digitalden = 0, digitaldenroxwood = 0 },
        },

        phonewartel = {
            category = 'Electronic',
            toItems = { phone = 4 },
            materials = { plastic = 1, glass = 1 },
            craftingTime = 3000,
            tables = { 'craftingwartelsm' },
            jobs = { wartelsm = 0 },
        },

        radiowartel = {
            category = 'Electronic',
            toItems = { radio = 4 },
            materials = { rubber = 1 },
            craftingTime = 3000,
            tables = { 'craftingwartelsm' },
            jobs = { wartelsm = 0 },
        },
    },
}
