return {
    tables = {
        craftingwarga = {
            title = 'Crafting Station',
            icon = 'fas fa-tools',
            animation = { dict = 'mini@repair', anim = 'fixing_a_ped' },
            publicAccess = true,
            spawnTable = { { coords = vector4(956.03, -1149.0, 24.6, 270.83), prop = 'gr_prop_gr_bench_02a' } },
        },

        craftingarmour2 = {
            title = 'Crafting Station',
            icon = 'fas fa-tools',
            animation = { dict = 'mini@repair', anim = 'fixing_a_ped' },
            jobs = { crsm = 1 },
            spawnTable = {
                {
                    coords = vector4(-279.3735, 2206.2981, 128.8414, 241.3711),
                    prop = 'gr_prop_gr_bench_02a',
                },
            },
        },

        craftingarmour3 = {
            title = 'Crafting Station',
            icon = 'fas fa-tools',
            animation = { dict = 'mini@repair', anim = 'fixing_a_ped' },
            jobs = { famsmcsm = 1 },
            spawnTable = {
                {
                    coords = vector4(1455.7152, -1662.4257, 65.0668, 25.1261),
                    prop = 'gr_prop_gr_bench_02a',
                },
            },
        },

        craftingammosenjata = {
            title = 'Crafting Station',
            icon = 'fas fa-tools',
            animation = { dict = 'mini@repair', anim = 'fixing_a_ped' },
            jobs = { omcsm = 4, nexusm = 2, mugensm = 1 },
            spawnTable = { { coords = vector4(-448.21, -2181.97, 9.32, 91.79), prop = 'gr_prop_gr_bench_02a' } },
        },

        craftingsenjatabadside = {
            title = 'Crafting Station',
            icon = 'fas fa-tools',
            animation = { dict = 'mini@repair', anim = 'fixing_a_ped' },
            jobs = { admin = 0, heavenhellsm = 1 },
            spawnTable = {
                {
                    coords = vector4(1173.1578, 836.7614, 150.9814, 330.1607),
                    prop = 'gr_prop_gr_bench_02a',
                },
            },
        },

        craftingsenjatabadside2 = {
            title = 'Crafting Station',
            icon = 'fas fa-tools',
            animation = { dict = 'mini@repair', anim = 'fixing_a_ped' },
            jobs = { shellbysm = 2 },
            locations = { vec3(-466.442810, -2670.741943, 10.702782) },
        },

        craftingsenjatabadside3 = {
            title = 'Crafting Station',
            icon = 'fas fa-tools',
            animation = { dict = 'mini@repair', anim = 'fixing_a_ped' },
            jobs = { eclipsesm = 4 },
            locations = { vec3(1400.83, -650.90, 56.82) },
        },

        craftingbadsidehightable = {
            title = 'Crafting Station',
            icon = 'fas fa-tools',
            animation = { dict = 'mini@repair', anim = 'fixing_a_ped' },
            jobs = { hightable = 2 },
            locations = { vec3(909.467163, -3209.612793, -98.446526) },
        },

        craftingprinthightable = {
            title = 'Crafting Station',
            icon = 'fas fa-tools',
            animation = { dict = 'mini@repair', anim = 'fixing_a_ped' },
            jobs = { hightable = 2 },
            locations = { vec3(905.989075, -3209.395508, -97.187462) },
        },

        craftingvesthightable = {
            title = 'Crafting Station',
            icon = 'fas fa-tools',
            animation = { dict = 'mini@repair', anim = 'fixing_a_ped' },
            jobs = { hightable = 2 },
            locations = { vector3(910.745605, -3222.103760, -98.448547) },
        },

        craftinghightablesenjata = {
            title = 'Crafting Station',
            icon = 'fas fa-tools',
            animation = { dict = 'mini@repair', anim = 'fixing_a_ped' },
            jobs = { hightable = 2 },
            locations = { vector3(905.708923, -3231.515625, -98.494553) },
        },

        craftinghightablesenjata2 = {
            title = 'Crafting Station',
            icon = 'fas fa-tools',
            animation = { dict = 'mini@repair', anim = 'fixing_a_ped' },
            jobs = { hightable = 2 },
            locations = { vector3(895.982971, -3216.818604, -98.428261) },
        },

        craftingammohightable = {
            title = 'Crafting Station',
            icon = 'fas fa-tools',
            animation = { dict = 'mini@repair', anim = 'fixing_a_ped' },
            jobs = { hightable = 2 },
            locations = { vector3(892.754272, -3220.569580, -98.016518) },
        },

        craftingsenjataroxwood = {
            title = 'Crafting Station',
            jobs = { admin = 0, gokudosm = 3 },
            animation = { dict = 'mini@repair', anim = 'fixing_a_ped' },
            spawnTable = {
                {
                    coords = vector4(-1407.7010, 7704.5332, 1.2505, 344.6250),
                    prop = 'gr_prop_gr_bench_02a',
                },
            },
            icon = 'fas fa-tools',
        },

        craftingammoroxwooddua = {
            title = 'Crafting Station',
            jobs = { admin = 0, silencesm = 1 },
            animation = { dict = 'mini@repair', anim = 'fixing_a_ped' },
            spawnTable = {
                {
                    coords = vector4(-5810.2681, 7615.4170, 48.5717, 187.0420),
                    prop = 'gr_prop_gr_bench_02a',
                },
            },
            icon = 'fas fa-tools',
        },

        craftingarmorroxwood = {
            title = 'Crafting Station',
            jobs = { admin = 0, gokudosm = 1 },
            animation = { dict = 'mini@repair', anim = 'fixing_a_ped' },
            spawnTable = {
                {
                    coords = vector4(-1389.5934, 7700.0884, 1.2483, 351.0589),
                    prop = 'gr_prop_gr_bench_02a',
                },
            },
            icon = 'fas fa-tools',
        },

        craftingarmorroxwooddua = {
            title = 'Crafting Station',
            jobs = { admin = 0, ffysm = 1, wildsm = 2, gasaksm = 1, leonsm = 1 },
            animation = { dict = 'mini@repair', anim = 'fixing_a_ped' },
            spawnTable = {
                {
                    coords = vector4(-5359.8037, 8469.8770, 62.2352, 122.0421),
                    prop = 'gr_prop_gr_bench_02a',
                },
            },
            icon = 'fas fa-tools',
        },
    },
    recipes = {
        armor = {
            label = 'Armor',
            toItems = { armor = 1 },
            materials = { hunting_skin = 3, clothes = 25, armor_blueprint = 1 },
            craftingTime = 3000,
            category = 'Tools',
            tables = { 'craftingarmour', 'craftingarmour2', 'craftingarmour3' },
        },

        lockpick = {
            label = 'Lockpick',
            toItems = { lockpick = 1 },
            materials = { packaged_plank = 1, iron = 1, copper = 2 },
            craftingTime = 10000,
            category = 'Tools',
            tables = { 'craftingwarga' },
        },

        gps_jmmr = {
            label = 'GPS Jammer',
            toItems = { gps_jmmr = 1 },
            materials = { motherboard_gps = 1, copper = 3, iron = 5 },
            craftingTime = 10000,
            category = 'Tools',
            tables = { 'craftingwarga' },
        },

        weapon_ceramicpistol = {
            label = 'Ceramic Pistol',
            toItems = { WEAPON_CERAMICPISTOL = 1 },
            materials = { gunhandle = 1, spring = 1, plastic = 2 },
            craftingTime = 10000,
            category = 'Weapon',
            tables = { 'craftingwarga' },
        },

        weapon_pumpshotgun_mk2 = {
            label = 'Pump Shotgun MK2',
            toItems = { WEAPON_PUMPSHOTGUN_MK2 = 1 },
            materials = { blackprint = 1, gunhandle = 1, packaged_plank = 3, spring = 3, aluminum = 2, oil = 5 },
            craftingTime = 10000,
            category = 'Weapon',
            tables = { 'craftingsenjataroxwood' },
        },

        ['ammo-shotgunrx'] = {
            label = 'AMMO 12 GAUGE',
            toItems = { ['ammo-shotgun'] = 50 },
            materials = { blackprint = 1, gunpowder = 1, packaged_plank = 20, sulfur = 1 },
            craftingTime = 10000,
            category = 'Ammo',
            tables = { 'craftingsenjataroxwood', 'craftingammoroxwooddua' },
        },

        ['ammo-riflegkd'] = {
            label = 'AMMO Rifle',
            toItems = { ['ammo-rifle'] = 50 },
            materials = { blackprint = 1, gunpowder = 1, packaged_plank = 20, sulfur = 1 },
            craftingTime = 10000,
            category = 'Ammo',
            tables = { 'craftingsenjataroxwood' },
        },

        ['ammo-38'] = {
            label = 'AMMO .38',
            toItems = { ['ammo-38'] = 60 },
            materials = { blackprint = 1, gunpowder = 1, packaged_plank = 25, sulfur = 1 },
            craftingTime = 10000,
            category = 'Ammo',
            tables = { 'craftingsenjataroxwood', 'craftingammoroxwooddua' },
        },

        armorroxwood = {
            label = 'Armor Roxwood',
            toItems = { armorroxwood = 1 },
            materials = { blackprint = 1, hunting_skin = 1, fabric = 10 },
            craftingTime = 10000,
            category = 'Armor',
            tables = { 'craftingarmorroxwood' },
        },

        armorroxwooddua = {
            label = 'Armor Roxwood',
            toItems = { armorroxwood = 1 },
            materials = { blackprint = 1, hunting_skin = 1, fabric = 10 },
            craftingTime = 10000,
            category = 'Armor',
            tables = { 'craftingarmorroxwooddua' },
        },

        pistol_ammo = {
            label = 'Ammo Pistol',
            toItems = { pistol_ammo = 50 },
            materials = { copper = 1, steel = 1 },
            craftingTime = 10000,
            category = 'Weapon',
            tables = { 'craftingwarga' },
        },

        ['ammo-9'] = {
            label = 'Ammo 9mm',
            toItems = { ['ammo-9'] = 120 },
            materials = { gunpowder = 1, ammo_blueprint = 1, sulfur = 1, packaged_plank = 10 },
            craftingTime = 3000,
            category = 'Ammo',
            tables = { 'craftingammosenjata', 'craftingammosenjata2' },
        },

        ['ammo-45'] = {
            label = 'Ammo .45 ACP',
            toItems = { ['ammo-45'] = 120 },
            materials = { gunpowder = 1, ammo_blueprint = 1, plastic = 2, sulfur = 1 },
            craftingTime = 3000,
            category = 'Ammo',
            tables = { 'craftingammosenjata', 'craftingammosenjata2' },
        },

        ['ammo-223'] = {
            label = 'Ammo 223',
            toItems = { ['ammo-223'] = 100 },
            materials = { gunpowder = 1, ammo_blueprint = 1, packaged_plank = 10, sulfur = 1 },
            craftingTime = 3000,
            category = 'Ammo',
            tables = { 'craftingammosenjata', 'craftingammosenjata2' },
        },

        ['ammo-50'] = {
            label = 'Ammo .50',
            toItems = { ['ammo-50'] = 100 },
            materials = { gunpowder = 1, ammo_blueprint = 1, sulfur = 1, packaged_plank = 5 },
            craftingTime = 3000,
            category = 'Ammo',
            tables = { 'craftingammosenjata', 'craftingammosenjata2' },
        },

        ['ammo-44'] = {
            label = 'Ammo .44',
            toItems = { ['ammo-44'] = 60 },
            materials = { gunpowder = 1, ammo_blueprint = 1, sulfur = 1, packaged_plank = 15 },
            craftingTime = 3000,
            category = 'Ammo',
            tables = { 'craftingammosenjata', 'craftingammosenjata2' },
        },

        weapon_skorpiosm = {
            label = 'SKORPIO SMG',
            toItems = { WEAPON_SKORPIOSM = 1 },
            materials = { wpn_blueprint = 1, spring = 2, glass = 1, steel = 1, iron = 1, gunhandle = 1 },
            craftingTime = 3000,
            category = 'Weapons',
            tables = { 'craftingsenjatabadside', 'craftingsenjatabadside2', 'craftingsenjatabadside3' },
        },

        weapon_buckrevolver = {
            label = 'Buck Revolver',
            toItems = { WEAPON_BUCKREVOLVER = 1 },
            materials = { wpn_blueprint = 1, spring = 3, oil = 5, metalscrap = 3, rubber = 3, gunhandle = 3 },
            craftingTime = 3000,
            category = 'Weapons',
            tables = { 'craftingsenjatabadside', 'craftingsenjatabadside2', 'craftingsenjatabadside3' },
        },

        weapon_bruggersm = {
            label = 'Brugger SMG',
            toItems = { WEAPON_BRUGGERSM = 1 },
            materials = { wpn_blueprint = 1, spring = 3, oil = 5, metalscrap = 3, rubber = 3, gunhandle = 3 },
            craftingTime = 3000,
            category = 'Weapons',
            tables = { 'craftingsenjatabadside', 'craftingsenjatabadside2', 'craftingsenjatabadside3' },
        },

        weapon_hkmp7sm = {
            label = 'Mp7 SMG',
            toItems = { WEAPON_HKMP7SM = 1 },
            materials = { wpn_blueprint = 1, spring = 3, oil = 3, metalscrap = 1, rubber = 3, gunhandle = 2 },
            craftingTime = 3000,
            category = 'Weapons',
            tables = { 'craftingsenjatabadside', 'craftingsenjatabadside2', 'craftingsenjatabadside3' },
        },

        weapon_g20va5 = {
            label = 'G20VA5',
            toItems = { WEAPON_G20VA5 = 1 },
            materials = { wpn_blueprint = 1, spring = 2, glass = 2, iron = 2, plastic = 2, gunhandle = 1 },
            craftingTime = 3000,
            category = 'Weapons',
            tables = { 'craftingsenjatabadside', 'craftingsenjatabadside2', 'craftingsenjatabadside3' },
        },

        weapon_hkmp7smht = {
            label = 'Mp7 SMG',
            toItems = { WEAPON_HKMP7SM = 1 },
            materials = { blueprint = 1, spring = 1, oil = 1, gunhandle = 1 },
            craftingTime = 3000,
            category = 'Weapons',
            tables = { 'craftingbadsidehightable' },
        },

        weapon_deaglesmht = {
            label = 'Deagle SM',
            toItems = { WEAPON_DEAGLESM = 1 },
            materials = { blueprint = 1, spring = 1, plastic = 2, iron = 1, gunhandle = 1 },
            craftingTime = 3000,
            category = 'Weapons',
            tables = { 'craftingbadsidehightable' },
        },

        weapon_bruggersmht = {
            label = 'Brugger SMG',
            toItems = { WEAPON_BRUGGERSM = 1 },
            materials = { blueprint = 1, spring = 1, silver = 1, gunhandle = 1 },
            craftingTime = 3000,
            category = 'Weapons',
            tables = { 'craftingbadsidehightable' },
        },

        weapon_buckrevolver_ht = {
            label = 'Buck Revolver',
            toItems = { WEAPON_BUCKREVOLVER = 1 },
            materials = { blueprint = 1, spring = 1, silver = 1, gunhandle = 1 },
            craftingTime = 3000,
            category = 'Weapons',
            tables = { 'craftingbadsidehightable' },
        },

        weapon_skorpiosmht = {
            label = 'SKORPIO SMG',
            toItems = { WEAPON_SKORPIOSM = 1 },
            materials = { blueprint = 1, spring = 1, silver = 1, gunhandle = 1 },
            craftingTime = 3000,
            category = 'Weapons',
            tables = { 'craftingbadsidehightable' },
        },

        weapon_minirevolversm_ht = {
            label = 'Mini Revolver',
            toItems = { WEAPON_MINIREVOLVERSM = 1 },
            materials = { blueprint = 1, spring = 1, silver = 1, gunhandle = 1 },
            craftingTime = 3000,
            category = 'Weapons',
            tables = { 'craftingbadsidehightable' },
        },

        weapon_pumpshotgun_mk2ht = {
            label = 'Pump Shotgun MK2',
            toItems = { WEAPON_PUMPSHOTGUN_MK2 = 1 },
            materials = { blueprint = 1, spring = 1, oil = 1, gunhandle = 1 },
            craftingTime = 3000,
            category = 'Weapons',
            tables = { 'craftingbadsidehightable' },
        },

        weapon_g20va5_ht = {
            label = 'G20VA5',
            toItems = { WEAPON_G20VA5 = 1 },
            materials = { blueprint = 1, spring = 2, glass = 2, iron = 2, plastic = 2, gunhandle = 1 },
            craftingTime = 3000,
            category = 'Weapons',
            tables = { 'craftingbadsidehightable' },
        },

        blueprinthightable = {
            label = 'Blueprint',
            toItems = { blueprint = 1 },
            materials = { packaged_plank = 3 },
            craftingTime = 3000,
            category = 'Tools',
            tables = { 'craftingprinthightable' },
        },

        blackprinthightable = {
            label = 'Blackprint',
            toItems = { blackprint = 1 },
            materials = { packaged_plank = 1 },
            craftingTime = 3000,
            category = 'Tools',
            tables = { 'craftingprinthightable' },
        },

        wpn_blueprint = {
            label = 'Weapon Blueprint',
            toItems = { wpn_blueprint = 1 },
            materials = { packaged_plank = 1 },
            craftingTime = 3000,
            category = 'Tools',
            tables = { 'craftingprinthightable' },
        },

        armor_blueprint = {
            label = 'Armor Blueprint',
            toItems = { armor_blueprint = 1 },
            materials = { packaged_plank = 1 },
            craftingTime = 3000,
            category = 'Tools',
            tables = { 'craftingprinthightable' },
        },

        ammo_blueprint = {
            label = 'Ammo Blueprint',
            toItems = { ammo_blueprint = 1 },
            materials = { packaged_plank = 1 },
            craftingTime = 3000,
            category = 'Tools',
            tables = { 'craftingprinthightable' },
        },

        tools_blueprint = {
            label = 'Tools Blueprint',
            toItems = { tools_blueprint = 1 },
            materials = { packaged_plank = 1 },
            craftingTime = 3000,
            category = 'Tools',
            tables = { 'craftingprinthightable' },
        },

        armorhightable = {
            label = 'Armor',
            toItems = { armor = 1 },
            materials = { hunting_skin = 1, clothes = 5, blueprint = 1 },
            craftingTime = 3000,
            category = 'Tools',
            tables = { 'craftingvesthightable' },
        },

        at_suppressor_heavy_hightable = {
            label = 'Tactical Suppressor',
            toItems = { at_suppressor_heavy = 1 },
            materials = { plastic = 2, clean_stone = 2 },
            craftingTime = 3000,
            category = 'Weapons',
            tables = { 'craftinghightablesenjata' },
        },

        at_grip_hightable = {
            label = 'Tactical Grip',
            toItems = { at_grip = 1 },
            materials = { plastic = 2 },
            craftingTime = 3000,
            category = 'Weapons',
            tables = { 'craftinghightablesenjata' },
        },

        at_clip_extended_rifle_hightable = {
            label = 'Extended Clip Rifle',
            toItems = { at_clip_extended_rifle = 1 },
            materials = { plastic = 2, clean_stone = 2 },
            craftingTime = 3000,
            category = 'Weapons',
            tables = { 'craftinghightablesenjata' },
        },

        at_flashlight_hightable = {
            label = 'Flashlight',
            toItems = { at_flashlight = 1 },
            materials = { plastic = 2 },
            craftingTime = 3000,
            category = 'Weapons',
            tables = { 'craftinghightablesenjata' },
        },

        at_scope_medium_hightable = {
            label = 'Medium Scope',
            toItems = { at_scope_medium = 1 },
            materials = { plastic = 2, packaged_plank = 2 },
            craftingTime = 3000,
            category = 'Weapons',
            tables = { 'craftinghightablesenjata' },
        },

        at_scope_large_hightable = {
            label = 'Large Scope',
            toItems = { at_scope_large = 1 },
            materials = { metalscrap = 1, glass = 2 },
            craftingTime = 3000,
            category = 'Weapons',
            tables = { 'craftinghightablesenjata' },
        },

        at_clip_extended_sniper_hightable = {
            label = 'Extended Clip Sniper',
            toItems = { at_clip_extended_sniper = 1 },
            materials = { metalscrap = 1, clean_stone = 2 },
            craftingTime = 3000,
            category = 'Weapons',
            tables = { 'craftinghightablesenjata' },
        },

        weapon_heavyrifle = {
            label = 'Heavy Rifle',
            toItems = { WEAPON_HEAVYRIFLE = 1 },
            materials = { blueprint = 1, spring = 1, steel = 2, oil = 1, packaged_plank = 5, gunhandle = 1 },
            craftingTime = 3000,
            category = 'Weapons',
            tables = { 'craftinghightablesenjata' },
        },

        weapon_akstocksm = {
            label = 'AKSM',
            toItems = { WEAPON_AKSTOCKSM = 1 },
            materials = { blueprint = 1, spring = 1, steel = 1, oil = 1, packaged_plank = 5, gunhandle = 1 },
            craftingTime = 3000,
            category = 'Weapons',
            tables = { 'craftinghightablesenjata' },
        },

        weapon_srht = {
            label = 'SPECTER CARBINE',
            toItems = { WEAPON_SRHT = 1 },
            materials = { blueprint = 1, spring = 1, steel = 1, oil = 1, packaged_plank = 5, gunhandle = 1 },
            craftingTime = 3000,
            category = 'Weapons',
            tables = { 'craftinghightablesenjata' },
        },

        weapon_spht = {
            label = 'SPEARHEAD RIFLE',
            toItems = { WEAPON_SPHT = 1 },
            materials = { blueprint = 1, spring = 1, steel = 1, oil = 1, packaged_plank = 5, gunhandle = 1 },
            craftingTime = 3000,
            category = 'Weapons',
            tables = { 'craftinghightablesenjata' },
        },

        weapon_ar15c = {
            label = 'AR-15C',
            toItems = { WEAPON_AR15C = 1 },
            materials = { blueprint = 1, spring = 1, steel = 1, oil = 2, packaged_plank = 5, gunhandle = 1 },
            craftingTime = 3000,
            category = 'Weapons',
            tables = { 'craftinghightablesenjata' },
        },

        weapon_arpism = {
            label = 'ARP-SIM',
            toItems = { WEAPON_ARPISM = 1 },
            materials = { blueprint = 1, spring = 1, steel = 2, oil = 1, packaged_plank = 5, gunhandle = 1 },
            craftingTime = 3000,
            category = 'Weapons',
            tables = { 'craftinghightablesenjata' },
        },

        weapon_akdraco_ht2 = {
            label = 'AK Draco',
            toItems = { WEAPON_AK47SM = 1 },
            materials = { blueprint = 1, gunhandle = 1, oil = 1, packaged_plank = 5, spring = 2, steel = 1 },
            craftingTime = 3000,
            category = 'Weapons',
            tables = { 'craftinghightablesenjata2' },
        },

        weapon_ak74sm_ht = {
            label = 'AK-74 SMG',
            toItems = { WEAPON_AK74SM = 1 },
            materials = { blueprint = 1, gunhandle = 1, oil = 1, packaged_plank = 5, spring = 2, steel = 1 },
            craftingTime = 3000,
            category = 'Weapons',
            tables = { 'craftinghightablesenjata2' },
        },

        weapon_sigmxcvirtus_ht2 = {
            label = 'SIG MXC Virtus',
            toItems = { WEAPON_SIGMXCVIRTUS = 1 },
            materials = { blueprint = 1, gunhandle = 1, oil = 2, packaged_plank = 5, spring = 1, steel = 2 },
            craftingTime = 3000,
            category = 'Weapons',
            tables = { 'craftinghightablesenjata2' },
        },

        weapon_dracosm_ht2 = {
            label = 'Draco SMG',
            toItems = { WEAPON_DRACOSM = 1 },
            materials = { blueprint = 1, gunhandle = 1, silver = 1, spring = 2 },
            craftingTime = 3000,
            category = 'Weapons',
            tables = { 'craftinghightablesenjata2' },
        },

        weapon_glockbeams_ht2 = {
            label = 'Glock Beam Switch',
            toItems = { WEAPON_GLOCKBEAMS = 1 },
            materials = { blueprint = 1, glass = 2, gunhandle = 1, iron = 2, plastic = 2, spring = 2 },
            craftingTime = 3000,
            category = 'Weapons',
            tables = { 'craftinghightablesenjata2' },
        },

        weapon_p90sm_ht2 = {
            label = 'P90 SMG',
            toItems = { WEAPON_P90SM = 1 },
            materials = { blueprint = 1, gunhandle = 1, silver = 1, spring = 1 },
            craftingTime = 3000,
            category = 'Weapons',
            tables = { 'craftinghightablesenjata2' },
        },

        weapon_sawnoffshotgun_ht2 = {
            label = 'Sawn Off Shotgun',
            toItems = { WEAPON_SAWNOFFSHOTGUN = 1 },
            materials = { blueprint = 1, gunhandle = 1, oil = 1, spring = 1 },
            craftingTime = 3000,
            category = 'Weapons',
            tables = { 'craftinghightablesenjata2' },
        },

        ['ammo-untraceable'] = {
            label = 'AMMO Untraceable',
            toItems = {
                ['ammo-untraceable'] = { 100, 1000 },
            },
            materials = { blueprint = 1, gunpowder = 1, plastic = 2, silver = 1 },
            craftingTime = 10000,
            category = 'Ammo',
            tables = { 'craftingammohightable' },
        },

        ['ammo-556'] = {
            label = 'AMMO 556',
            toItems = {
                ['ammo-rifle'] = { 100, 1000 },
            },
            materials = { blueprint = 1, gunpowder = 1, plastic = 2, silver = 1 },
            craftingTime = 10000,
            category = 'Ammo',
            tables = { 'craftingammohightable' },
        },

        ['ammo-762'] = {
            label = 'AMMO 762',
            toItems = { ['ammo-rifle2'] = 50 },
            materials = { blueprint = 1, gunpowder = 1, plastic = 1, silver = 1 },
            craftingTime = 10000,
            category = 'Ammo',
            tables = { 'craftingammohightable' },
        },

        ['ammo-38ht'] = {
            label = 'AMMO 38',
            toItems = { ['ammo-38'] = 50 },
            materials = { blueprint = 1, gunpowder = 1, plastic = 1, silver = 1 },
            craftingTime = 10000,
            category = 'Ammo',
            tables = { 'craftingammohightable' },
        },

        ['ammo-shotgunht'] = {
            label = 'AMMO ShotGun',
            toItems = { ['ammo-shotgun'] = 50 },
            materials = { blueprint = 1, gunpowder = 1, plastic = 1, silver = 1 },
            craftingTime = 10000,
            category = 'Ammo',
            tables = { 'craftingammohightable' },
        },

        ['ammo-45ht'] = {
            label = 'AMMO 45',
            toItems = { ['ammo-45'] = 50 },
            materials = { blueprint = 1, gunpowder = 1, plastic = 1, silver = 1 },
            craftingTime = 10000,
            category = 'Ammo',
            tables = { 'craftingammohightable' },
        },

        ['ammo-9ht'] = {
            label = 'AMMO 9',
            toItems = { ['ammo-9'] = 50 },
            materials = { blueprint = 1, gunpowder = 1, plastic = 1, silver = 1 },
            craftingTime = 10000,
            category = 'Ammo',
            tables = { 'craftingammohightable' },
        },

        at_clip_extended_smg = {
            label = 'Extended Clip SMG',
            toItems = { at_clip_extended_smg = 1 },
            materials = { oil = 3, metalscrap = 1, rubber = 1 },
            craftingTime = 3000,
            category = 'Attachment',
            tables = { 'craftingsenjatabadside', 'craftingsenjatabadside2', 'craftingsenjatabadside3' },
        },

        at_scope_macro = {
            label = 'Macro Scope',
            toItems = { at_scope_macro = 1 },
            materials = { steel = 1, metalscrap = 1, glass = 1 },
            craftingTime = 3000,
            category = 'Attachment',
            tables = { 'craftingsenjatabadside', 'craftingsenjatabadside2', 'craftingsenjatabadside3' },
        },

        at_suppressor_light = {
            label = 'Light Suppressor',
            toItems = { at_suppressor_light = 1 },
            materials = { aluminum = 1, plastic = 5, steel = 1, oil = 2 },
            craftingTime = 3000,
            category = 'Attachment',
            tables = { 'craftingsenjatabadside', 'craftingsenjatabadside2', 'craftingsenjatabadside3' },
        },

        at_suppressor_heavy = {
            label = 'Heavy Suppressor',
            toItems = { at_suppressor_heavy = 1 },
            materials = { aluminum = 1, plastic = 5, steel = 2, oil = 2 },
            craftingTime = 3000,
            category = 'Attachment',
            tables = { 'craftingsenjatabadside', 'craftingsenjatabadside2', 'craftingsenjatabadside3' },
        },

        weapon_deaglesm = {
            label = 'Deagle Sm',
            toItems = { WEAPON_DEAGLESM = 1 },
            materials = { wpn_blueprint = 1, spring = 1, plastic = 2, iron = 1, gunhandle = 1 },
            craftingTime = 3000,
            category = 'Weapons',
            tables = { 'craftingsenjatabadside', 'craftingsenjatabadside2', 'craftingsenjatabadside3' },
        },
    },
}
