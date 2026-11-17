return {
    editor = {
        command = 'tcgeditor',
        group = 'group.admin',
    },

    items = {
        card = 'tcg_card',
        sleeve = 'tcg_sleeve',
        grading = 'tcg_grading',
    },

    defaultDivision = {
        name = 'Koleksi Perdana',
        code = 'DVA',
        slots = 24,
        packItem = 'tcg_pack_dva',
        boxItem = 'tcg_box_dva',
        albumItem = 'tcg_album_dva',
        backColor = '#0c8599',
    },

    classes = {
        { id = 'common', label = 'Umum', color = '#9ca3af', reveal = 'none', revealTime = 600 },
        { id = 'uncommon', label = 'Tak Umum', color = '#22c55e', reveal = 'none', revealTime = 700 },
        { id = 'rare', label = 'Langka', color = '#3b82f6', reveal = 'glow', revealTime = 900 },
        { id = 'epic', label = 'Epik', color = '#a855f7', reveal = 'burst', revealTime = 1100 },
        { id = 'legendary', label = 'Legendaris', color = '#f59e0b', reveal = 'storm', revealTime = 1800 },
    },

    templates = {
        { id = 'classic', label = 'Klasik', frame = 'classic', foilArea = 'window', fields = { 'name', 'artist', 'description', 'hp', 'attack' } },
        { id = 'classic_full', label = 'Klasik penuh', frame = 'classic', foilArea = 'card', fields = { 'name', 'artist', 'description', 'hp', 'attack' } },
        { id = 'bordered', label = 'Berbingkai', frame = 'bordered', foilArea = 'card', fields = { 'name', 'artist', 'description', 'hp', 'attack' } },
        { id = 'modern', label = 'Modern', frame = 'modern', foilArea = 'card', fields = { 'name', 'artist', 'description', 'hp', 'attack' } },
        { id = 'fullart', label = 'Full art', frame = 'fullart', foilArea = 'card', fields = { 'name', 'artist', 'hp', 'attack' } },
    },

    effects = {
        'matte', 'none', 'holo', 'reverse', 'cosmos', 'glitter', 'aurora', 'rainbow', 'gold',
        'prism', 'radiant', 'crystal', 'metal', 'oilslick', 'sunburst', 'mosaic',
        'galaxy', 'etched', 'diagonal', 'pastel',
        'chevron_moon', 'chevron_sun', 'chevron_bolt', 'chevron_star', 'chevron_drop', 'chevron_flame',
        'chevron_leaf', 'chevron_snow', 'chevron_skull', 'chevron_crown', 'chevron_gear', 'chevron_feather',
    },

    pack = {
        slots = {
            { common = 100 },
            { common = 65, uncommon = 35 },
            { uncommon = 55, rare = 32, epic = 12, legendary = 1 },
        },
        fallbackClass = 'common',
        noDuplicate = true,
        cooldown = 2000, -- ms
    },

    box = {
        packs = 10,
        cooldown = 2000, -- ms
    },

    quality = {
        { min = 50.0, max = 69.9, weight = 45.0 },
        { min = 70.0, max = 84.9, weight = 34.0 },
        { min = 85.0, max = 94.9, weight = 15.0 },
        { min = 95.0, max = 99.9, weight = 5.5 },
        { min = 100.0, max = 100.0, weight = 0.5 },
    },

    degradation = {
        enabled = true,
        interval = 15, -- menit
        amount = 0.05,
        floor = 1.0,
    },

    conditions = {
        { min = 95.0, id = 'mint' },
        { min = 85.0, id = 'near_mint' },
        { min = 70.0, id = 'good' },
        { min = 50.0, id = 'played' },
        { min = 0.0, id = 'poor' },
    },

    grades = {
        { min = 100.0, grade = 10 },
        { min = 97.0, grade = 9 },
        { min = 93.0, grade = 8 },
        { min = 88.0, grade = 7 },
        { min = 82.0, grade = 6 },
        { min = 75.0, grade = 5 },
        { min = 65.0, grade = 4 },
        { min = 55.0, grade = 3 },
        { min = 40.0, grade = 2 },
        { min = 0.0, grade = 1 },
    },

    sleeve = {
        reusable = true,
    },

    album = {
        takesGraded = true,
    },

    grading = {
        duration = 6000, -- ms
    },

    show = {
        distance = 4.0, -- meter
        duration = 8000, -- ms
    },

    give = {
        distance = 3.0, -- meter
    },

    anims = {
        album = { dict = 'amb@world_human_clipboard@male@idle_a', clip = 'idle_c', flag = 49 },
        pack = { dict = 'amb@world_human_stand_mobile@female@text@base', clip = 'base', flag = 49 },
        card = { dict = 'amb@world_human_stand_mobile@female@text@base', clip = 'base', flag = 49 },
    },
}
