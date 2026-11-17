return {
    tables = {
        craftingalatrobbery = {
            title = 'Crafting Station',
            icon = 'fas fa-tools',
            animation = { dict = 'mini@repair', anim = 'fixing_a_ped' },
            jobs = { limitlessm = 2, fsgsm = 1},
            spawnTable = { { coords = vector4(-53.05, -2521.98, 6.4, 323.56), prop = 'gr_prop_gr_bench_02a' } },
        },
    },
    recipes = {
        advancedlockpick = {
            label = 'Advanced Lockpick',
            toItems = { advancedlockpick = 1 },
            materials = { rubber = 1, steel = 2, tools_blueprint = 1 },
            craftingTime = 10000,
            category = 'Tools',
            tables = { 'craftingalatrobbery' },
        },

        cutter = {
            label = 'Cutting Machine',
            toItems = { cutter = 1 },
            materials = { rubber = 1, steel = 1, metalscrap = 1, tools_blueprint = 1 },
            craftingTime = 10000,
            category = 'Tools',
            tables = { 'craftingalatrobbery' },
        },

        drill = {
            label = 'Drill',
            toItems = { drill = 1 },
            materials = { steel = 1, metalscrap = 1, iron = 1, tools_blueprint = 1 },
            craftingTime = 10000,
            category = 'Tools',
            tables = { 'craftingalatrobbery' },
        },

        thermite = {
            label = 'Thermite',
            toItems = { thermite = 1 },
            materials = { steel = 2, aluminum = 1, iron = 2, tools_blueprint = 1 },
            craftingTime = 10000,
            category = 'Tools',
            tables = { 'craftingalatrobbery' },
        },

        c4_bomb = {
            label = 'C4 Bomb',
            toItems = { c4_bomb = 1 },
            materials = { steel = 2, sulfur = 1, tools_blueprint = 1 },
            craftingTime = 10000,
            category = 'Tools',
            tables = { 'craftingalatrobbery' },
        },

        code_injector = {
            label = 'Code Injector',
            toItems = { code_injector = 1 },
            materials = { steel = 1, aluminum = 1, metalscrap = 1, plastic = 1, tools_blueprint = 1 },
            craftingTime = 10000,
            category = 'Tools',
            tables = { 'craftingalatrobbery' },
        },

        pipe_bomb = {
            label = 'Pipe Bomb',
            toItems = { pipe_bomb = 1 },
            materials = { steel = 2, aluminum = 1, sulfur = 1, iron = 1, tools_blueprint = 1 },
            craftingTime = 10000,
            category = 'Tools',
            tables = { 'craftingalatrobbery' },
        },

        rusty_drill = {
            label = 'Rusty Drill',
            toItems = { rusty_drill = 1 },
            materials = { rubber = 1, steel = 2, metalscrap = 1, iron = 1, plastic = 2, tools_blueprint = 1 },
            craftingTime = 10000,
            category = 'Tools',
            tables = { 'craftingalatrobbery' },
        },

        backdoor_kit = {
            label = 'Backdoor Kit',
            toItems = { backdoor_kit = 1 },
            materials = { steel = 2, aluminum = 1, metalscrap = 2, plastic = 2, tools_blueprint = 1 },
            craftingTime = 10000,
            category = 'Tools',
            tables = { 'craftingalatrobbery' },
        },
        fleeca_tools = {
            label = 'Fleeca Tools',
            category = 'Paket',
            package = true,
            toItems = { fleeca_tools = 1 },
            materials = { trojan_usb = 1, code_injector = 1, drill = 1 },
            craftingTime = 10000,
            tables = { 'craftingalatrobbery' },
        },

        jewel_tools = {
            label = 'Jewel Tools',
            category = 'Paket',
            package = true,
            toItems = { jewel_tools = 1 },
            materials = { pipe_bomb = 1, cutter = 1, advancedlockpick = 1 },
            craftingTime = 10000,
            tables = { 'craftingalatrobbery' },
        },

        bc_tools = {
            label = 'Blaine County Tools',
            category = 'Paket',
            package = true,
            toItems = { bc_tools = 1 },
            materials = { thermite = 1, rusty_drill = 3 },
            craftingTime = 10000,
            tables = { 'craftingalatrobbery' },
        },

        pacific_tools = {
            label = 'Pacific Tools',
            category = 'Paket',
            package = true,
            toItems = { pacific_tools = 1 },
            materials = { thermite = 3, drill = 2, rusty_drill = 3 , backdoor_kit = 1 },
            craftingTime = 10000,
            tables = { 'craftingalatrobbery' },
        },
    },
}
