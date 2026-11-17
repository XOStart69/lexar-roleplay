return {
	megamall = {
		label = 'Megamall',
		blip = {
			id = 59, colour = 69, scale = 0.8
		},
		name = 'Megamall',
		inventory = {
			{ name = 'WEAPON_MACHETE',      price = 20000 },
			{ name = 'WEAPON_CROWBAR',      price = 20000 },
			{ name = 'WEAPON_WRENCH',       price = 20000 },
			{ name = 'WEAPON_HATCHET',      price = 20000 },
			{ name = 'WEAPON_SLEDGEHAMMER', price = 20000 },
			{ name = 'orange_seed',         price = 300 },
			{ name = 'carrot_seed',         price = 300 },
			{ name = 'tomato_seed',         price = 300 },
			{ name = 'wheat_seed',          price = 300 },
			{ name = 'chili_seed',          price = 300 },
			{ name = 'bawang_seed',         price = 300 },
			{ name = 'corn_seed',           price = 300 },
			{ name = 'scissors',            price = 20000 },
			{ name = 'garden_shovel',       price = 20000 },
			{ name = 'bucket',              price = 150 },
			{ name = 'bottle',              price = 150 },
			{ name = 'rope',                price = 50000 },
		},
		coords = {
			vec3(47.4, -1750.35, 29.85),
			vec3(-57.179348, 6521.101074, 31.645248),
			vec3(2455.074707, 4058.585693, 38.259392),
			vec3(-2195.559082, 7439.291016, 37.863708),
		}
	},

	MercenaryArmory = {
		label = 'Mercenary Armory',
		groups = {
			['mercenarysm'] = 0
		},
		name = 'MercenaryArmoury',
		inventory = {
			{ name = 'blindfold',                   price = 5 },
			{ name = 'megaphone',                   price = 5 },
			{ name = 'pol_mdt',                     price = 5 },
			{ name = 'parachute',                   price = 5 },
			{ name = 'diving_gear',                 price = 5 },
			{ name = 'diving_fill',                 price = 5 },
			{ name = 'dashcam',                     price = 5 },
			{ name = 'bodycam',                     price = 5 },
			{ name = 'handcuffs',                   price = 5 },
			{ name = 'ziptie',                      price = 5 },
			{ name = 'cuffkeys',                    price = 5 },
			{ name = 'flush_cutter',                price = 5 },
			{ name = 'empty_evidence_bag',          price = 5 },
			{ name = 'bodybooster',                 price = 5 },
			{ name = 'gasmask',                     price = 5 },

			{ name = 'spikestrip',                  price = 5 },

			{ name = 'cctv_faulty',                 price = 5 },
			{ name = 'cctv_default',                price = 5 },
			{ name = 'cctv_advanced',               price = 5 },
			{ name = 'cctv_tablet',                 price = 5 },

			{ name = 'WEAPON_AUTOCROSS',            price = 5 },
			{ name = 'zipline_ammo',                price = 5 },

			{ name = 'WEAPON_GRENADE_STUN',         price = 5 },
			{ name = 'WEAPON_GRENADE_SMOKE',        price = 5 },
			{ name = 'WEAPON_GRENADE_TEARGAS',      price = 5 },

			{ name = 'heavyarmor',                  price = 5 },
			{ name = 'ammo-flare',                  price = 5 },
			{ name = 'ammo-9karet',                 price = 5 },
			{ name = 'ammo-9police',                price = 5 },
			{ name = 'ammo-riflepolice',            price = 5 },
			{ name = 'ammo-44police',               price = 5 },
			{ name = 'ammo-shotgunpolice',          price = 5 },
			{ name = 'ammo-heavysniper',            price = 5 },

			{ name = 'WEAPON_FLASHLIGHT',           price = 5 },
			{ name = 'WEAPON_RADARGUN',             price = 5 },
			{ name = 'WEAPON_FLAREGUN',             price = 5 },
			{ name = 'WEAPON_NIGHTSTICK',              price = 5 },

			{ name = 'WEAPON_STUNGUN',               price = 5 },
			{ name = 'taser_cartridge', price = 5 },

			{ name = 'at_clip_extended_pistol_pol', price = 5 },
			{ name = 'at_clip_extended_smg_pol',    price = 5 },
			{ name = 'at_clip_extended_rifle_pol',  price = 5 },
			{ name = 'at_suppressor_light_pol',     price = 5 },
			{ name = 'at_suppressor_heavy_pol',     price = 5 },
			{ name = 'at_flashlight_pol',     		price = 5 },
			{ name = 'at_scope_pol',     			price = 5 },

			{ name = 'WEAPON_PDP890',               price = 5, metadata = { registered = true, serial = 'POL' } },

			{ name = 'WEAPON_APPISTOL',             price = 5, metadata = { registered = true, serial = 'POL' } },
			{ name = 'WEAPON_PDSIGMPX',             price = 5, metadata = { registered = true, serial = 'POL' } },
			{ name = 'WEAPON_PDREVOLVERSM',         price = 5, metadata = { registered = true, serial = 'POL' } },
			{ name = 'WEAPON_PDMP9',                price = 5, metadata = { registered = true, serial = 'POL' } },
			{ name = 'WEAPON_PDCQR15',              price = 5, metadata = { registered = true, serial = 'POL' } },
			{ name = 'WEAPON_MK18MD1',              price = 5, metadata = { registered = true, serial = 'POL' } },
			{ name = 'WEAPON_PDAK104',              price = 5, metadata = { registered = true, serial = 'POL' } },
			{ name = 'WEAPON_PDG36',                price = 5, metadata = { registered = true, serial = 'POL' } },

			{ name = 'WEAPON_PDBRYSON800',          price = 5, metadata = { registered = true, serial = 'POL' } },
		},
		coords = {
			vec3(-2239.139648, 3453.242188, 35.248173),
		}
	},

	PoliceArmoury = {
		label = 'Police Armory',
		groups = {
			['police'] = 0
		},
		name = 'PoliceArmoury',
		inventory = {
			{ name = 'blindfold',                   price = 5 },
			{ name = 'megaphone',                   price = 5 },
			{ name = 'pol_mdt',                     price = 5 },
			{ name = 'parachute',                   price = 5 },
			{ name = 'diving_gear',                 price = 5 },
			{ name = 'diving_fill',                 price = 5 },
			{ name = 'dashcam',                     price = 5 },
			{ name = 'bodycam',                     price = 5 },
			{ name = 'handcuffs',                   price = 5 },
			{ name = 'ziptie',                      price = 5 },
			{ name = 'cuffkeys',                    price = 5 },
			{ name = 'flush_cutter',                price = 5 },
			{ name = 'empty_evidence_bag',          price = 5 },
			{ name = 'bodybooster',                 price = 5 },
			{ name = 'gasmask',                     price = 5 },
			{ name = 'pdcamera',                    price = 5 },

			{ name = 'spikestrip',                  price = 5, grade = 1},

			{ name = 'cctv_faulty',                 price = 5, requireditem = { 'badgedetective', 'badgeshc' } },
			{ name = 'cctv_default',                price = 5, requireditem = { 'badgedetective', 'badgeshc' } },
			{ name = 'cctv_advanced',               price = 5, requireditem = { 'badgedetective', 'badgeshc' } },
			{ name = 'cctv_tablet',                 price = 5, requireditem = { 'badgedetective', 'badgeshc' } },

			{ name = 'WEAPON_AUTOCROSS',            price = 5, requireditem = { 'badgeswatlspd', 'badgeshc' } },
			{ name = 'zipline_ammo',                price = 5, requireditem = { 'badgeswatlspd', 'badgeshc' } },

			{ name = 'WEAPON_GRENADE_STUN',         price = 5, requireditem = { 'badgeswatlspd', 'badgeshc' } },
			{ name = 'WEAPON_GRENADE_SMOKE',        price = 5, requireditem = { 'badgeswatlspd', 'badgeshc' } },
			{ name = 'WEAPON_GRENADE_TEARGAS',      price = 5, requireditem = { 'badgeswatlspd', 'badgeshc' } },

			{ name = 'heavyarmor',                  price = 5 },
			{ name = 'ammo-flare',                  price = 5 },
			{ name = 'ammo-9karet',                 price = 5 },
			{ name = 'ammo-9police',                price = 5 },
			{ name = 'ammo-riflepolice',            price = 5 },
			{ name = 'ammo-44police',               price = 5 },
			{ name = 'ammo-shotgunpolice',          price = 5 },
			{ name = 'ammo-heavysniper',            price = 5 },

			{ name = 'WEAPON_FLASHLIGHT',           price = 5 },
			{ name = 'WEAPON_RADARGUN',             price = 5 },
			{ name = 'WEAPON_FLAREGUN',             price = 5 },
			{ name = 'WEAPON_NIGHTSTICK',              price = 5 },

			{ name = 'WEAPON_STUNGUN',               price = 5 },
			{ name = 'taser_cartridge', price = 5 },

			{ name = 'at_clip_extended_pistol_pol', price = 5, requireditem = { 'badgeswatlspd', 'badgedetective', 'badgeshc' } },
			{ name = 'at_clip_extended_smg_pol',    price = 5, requireditem = { 'badgeswatlspd', 'badgedetective', 'badgeshc' } },
			{ name = 'at_clip_extended_rifle_pol',  price = 5, requireditem = { 'badgeswatlspd', 'badgedetective', 'badgeshc' } },
			{ name = 'at_suppressor_light_pol',     price = 5, requireditem = { 'badgeswatlspd', 'badgedetective', 'badgeshc' } },
			{ name = 'at_suppressor_heavy_pol',     price = 5, requireditem = { 'badgeswatlspd', 'badgedetective', 'badgeshc' } },
			{ name = 'at_flashlight_pol',     		price = 5, requireditem = { 'badgeswatlspd', 'badgedetective', 'badgeshc' } },
			{ name = 'at_scope_pol',     			price = 5, requireditem = { 'badgeswatlspd', 'badgedetective', 'badgeshc' } },

			{ name = 'WEAPON_PDP890',               price = 5, metadata = { registered = true, serial = 'POL' } },

			{ name = 'WEAPON_APPISTOL',             price = 5, metadata = { registered = true, serial = 'POL' }, requireditem = { 'badgeswatlspd', 'badgeshc' } },
			{ name = 'WEAPON_PDSIGMPX',             price = 5, metadata = { registered = true, serial = 'POL' }, requireditem = { 'badgeswatlspd', 'badgeshc' } },
			{ name = 'WEAPON_PDREVOLVERSM',         price = 5, metadata = { registered = true, serial = 'POL' }, requireditem = { 'badgeswatlspd', 'badgeshc' } },
			{ name = 'WEAPON_PDMP9',                price = 5, metadata = { registered = true, serial = 'POL' }, requireditem = { 'badgeswatlspd', 'badgeshc' } },
			{ name = 'WEAPON_PDCQR15',              price = 5, metadata = { registered = true, serial = 'POL' }, requireditem = { 'badgeswatlspd', 'badgeshc' } },
			{ name = 'WEAPON_MK18MD1',              price = 5, metadata = { registered = true, serial = 'POL' }, requireditem = { 'badgeswatlspd', 'badgeshc' } },
			{ name = 'WEAPON_PDAK104',              price = 5, metadata = { registered = true, serial = 'POL' }, requireditem = { 'badgeswatlspd', 'badgeshc' } },
			{ name = 'WEAPON_PDG36',                price = 5, metadata = { registered = true, serial = 'POL' }, requireditem = { 'badgeswatlspd', 'badgeshc' } },

			{ name = 'WEAPON_PDBRYSON800',          price = 5, metadata = { registered = true, serial = 'POL' }, requireditem = { 'badgeswatlspd', 'badgeshc' } },
		},
		coords = {
			vec3(2450.731689, 1601.722534, 30.795244),
			vec3(-196.394531, -1314.416016, 31.091375),
			vec3(-448.763885, 6007.841797, 32.133087),
			vec3(1822.641968, 3663.707764, 39.357204),
			vec3(453.012482, -980.122070, 30.683558),
			vec3(527.158142, -24.448883, 70.947372),
		}
	},

	usmarshalarmory = {
		label = 'US Marshall',
		groups = {
			['usmarshal'] = 1
		},
		name = 'usmarshalarmory',
		inventory = {
			{ name = 'blindfold',          price = 5 },
			{ name = 'pol_mdt',            price = 5 },
			{ name = 'handcuffs',          price = 5 },
			{ name = 'ziptie',             price = 5 },
			{ name = 'cuffkeys',           price = 5 },
			{ name = 'flush_cutter',       price = 5 },
			{ name = 'bodycam',            price = 5 },
			{ name = 'heavyarmor',         price = 5 },
			{ name = 'bodybooster',        price = 5 },
			{ name = 'WEAPON_NIGHTSTICK',  price = 5 },
			{ name = 'WEAPON_FLASHLIGHT',  price = 5 },
			{ name = 'parachute',          price = 5 },
			{ name = 'diving_gear',        price = 5 },
			{ name = 'diving_fill',        price = 5 },
			{ name = 'megaphone',          price = 5 },
			{ name = 'shield',             price = 5 },
			{ name = 'gasmask',            price = 5 },
			{ name = 'WEAPON_STUNGUN',     price = 5 },
			{ name = 'taser_cartridge', price = 5 },
			{ name = 'empty_evidence_bag', price = 5 },
			{ name = 'WEAPON_RADARGUN',    price = 5 },
			{ name = 'WEAPON_AUTOCROSS',   price = 5 },
			{ name = 'zipline_ammo',       price = 5 },
			{ name = 'cctv_faulty',        price = 5 },
			{ name = 'cctv_default',       price = 5 },
			{ name = 'cctv_advanced',      price = 5 },
			{ name = 'cctv_tablet',        price = 5 },
			{ name = 'ammo-flare',         price = 5 },
			{ name = 'ammo-9police',       price = 5 },
			{ name = 'ammo-riflepolice',   price = 5 },
			{ name = 'ammo-44police',      price = 5 },
			{ name = 'ammo-shotgunpolice', price = 5 },
			{ name = 'ammo-heavysniper',   price = 5 },

			{ name = 'WEAPON_GRENADE_STUN',         price = 5, requireditem = { 'badgeftfusmsnew', 'badgehighcommandusms' } },
			{ name = 'WEAPON_GRENADE_SMOKE',        price = 5, requireditem = { 'badgeftfusmsnew', 'badgehighcommandusms' } },
			{ name = 'WEAPON_GRENADE_TEARGAS',      price = 5, requireditem = { 'badgeftfusmsnew', 'badgehighcommandusms' } },

			{ name = 'at_clip_extended_pistol_pol', price = 5, requireditem = { 'badgeftfusmsnew', 'badgehighcommandusms' } },
			{ name = 'at_clip_extended_smg_pol',    price = 5, requireditem = { 'badgeftfusmsnew', 'badgehighcommandusms' } },
			{ name = 'at_clip_extended_rifle_pol',  price = 5, requireditem = { 'badgeftfusmsnew', 'badgehighcommandusms' } },
			{ name = 'at_suppressor_light_pol',     price = 5, requireditem = { 'badgeftfusmsnew', 'badgehighcommandusms' } },
			{ name = 'at_suppressor_heavy_pol',     price = 5, requireditem = { 'badgeftfusmsnew', 'badgehighcommandusms' } },
			{ name = 'at_flashlight_pol',           price = 5, requireditem = { 'badgeftfusmsnew', 'badgehighcommandusms' } },
			{ name = 'at_scope_pol',                price = 5, requireditem = { 'badgeftfusmsnew', 'badgehighcommandusms' } },

			{ name = 'WEAPON_PDMK16',        price = 5, metadata = { registered = true, serial = 'POL' }, requireditem = { 'badgeftfusmsnew', 'badgehighcommandusms' } },
			{ name = 'WEAPON_PDMCXSPEAR',    price = 5, metadata = { registered = true, serial = 'POL' }, requireditem = { 'badgeftfusmsnew', 'badgehighcommandusms' } },
			{ name = 'WEAPON_PDM4A1',        price = 5, metadata = { registered = true, serial = 'POL' }, requireditem = { 'badgeftfusmsnew', 'badgehighcommandusms' } },
			{ name = 'WEAPON_PDM3SUPER90',   price = 5, metadata = { registered = true, serial = 'POL' }, requireditem = { 'badgeftfusmsnew', 'badgehighcommandusms' } },
			{ name = 'WEAPON_MILITARYRIFLE', price = 5, metadata = { registered = true, serial = 'POL' }, requireditem = { 'badgeftfusmsnew', 'badgehighcommandusms' } },
			{ name = 'WEAPON_ASSAULTSMG',    price = 5, metadata = { registered = true, serial = 'POL' }, requireditem = { 'badgeftfusmsnew', 'badgehighcommandusms' } },
			{ name = 'WEAPON_COMBATPDW',     price = 5, metadata = { registered = true, serial = 'POL' }, requireditem = { 'badgeftfusmsnew', 'badgehighcommandusms' } },
			{ name = 'WEAPON_PD357MAGNUM',   price = 5, metadata = { registered = true, serial = 'POL' }, requireditem = { 'badgeftfusmsnew', 'badgehighcommandusms' } },
			{ name = 'WEAPON_PDGLOCK43',     price = 5, metadata = { registered = true, serial = 'POL' }, requireditem = { 'badgeftfusmsnew', 'badgehighcommandusms' } },
			{ name = 'WEAPON_APPISTOL',      price = 5, metadata = { registered = true, serial = 'POL' }, requireditem = { 'badgeftfusmsnew', 'badgehighcommandusms' } },
		},
		coords = {
			vec3(212.145462, -417.818542, 43.069550)
		}
	},

	governmentarmory = {
		label = 'Government',
		groups = {
			['government'] = 12
		},
		name = 'governmentarmory',
		inventory = {
			{ name = 'handcuffs',                   price = 5 },
			{ name = 'ziptie',                      price = 5 },
			{ name = 'cuffkeys',                    price = 5 },
			{ name = 'flush_cutter',                price = 5 },
			{ name = 'bodybooster',                 price = 5, grade = 3 },
			{ name = 'bodycam',                     price = 5 },
			{ name = 'badgepaspampres',             price = 5, grade = 3 },
			{ name = 'kupon_pemerintah',            price = 5, grade = 3 },
			{ name = 'trolley',            			price = 5, grade = 3 },

			{ name = 'heavyarmor',                  price = 5, grade = 3 },
			{ name = 'ammo-9police',                price = 5, grade = 3 },
			{ name = 'ammo-riflepolice',            price = 5, grade = 3 },
			{ name = 'ammo-44police',               price = 5 },
			{ name = 'ammo-shotgunpolice',          price = 5 },
			{ name = 'ammo-heavysniper',            price = 5 },

			{ name = 'at_clip_extended_pistol_pol', price = 5, grade = 1 },
			{ name = 'at_clip_extended_smg_pol',    price = 5, grade = 1 },
			{ name = 'at_clip_extended_rifle_pol',  price = 5, grade = 1 },
			{ name = 'at_suppressor_light_pol',     price = 5, grade = 1 },
			{ name = 'at_suppressor_heavy_pol',     price = 5, grade = 1 },
			{ name = 'at_flashlight_pol',     		price = 5, grade = 1 },
			{ name = 'at_scope_pol',     			price = 5, grade = 1 },

			{ name = 'WEAPON_REVOLVER',    price = 5, metadata = { registered = true, serial = 'POL' }, requireditem = { 'badgepaspampres' } },
			{ name = 'WEAPON_APPISTOL',    price = 5, metadata = { registered = true, serial = 'POL' }, requireditem = { 'badgepaspampres' } },
			{ name = 'WEAPON_COMBATPDW',   price = 5, metadata = { registered = true, serial = 'POL' }, requireditem = { 'badgepaspampres' } },
			{ name = 'WEAPON_ASSAULTSMG',  price = 5, metadata = { registered = true, serial = 'POL' }, requireditem = { 'badgepaspampres' } },
			{ name = 'WEAPON_PUMPSHOTGUN', price = 5, metadata = { registered = true, serial = 'POL' }, requireditem = { 'badgepaspampres' } },
			{ name = 'WEAPON_KRISSVECTOR', price = 5, metadata = { registered = true, serial = 'POL' }, requireditem = { 'badgepaspampres' } },
			{ name = 'WEAPON_PDMCXSPEAR',  price = 5, metadata = { registered = true, serial = 'POL' }, requireditem = { 'badgepaspampres' } },

			{ name = 'WEAPON_FN502',  price = 5, metadata = { registered = true, serial = 'POL' }, requireditem = { 'badgepaspampres' } },
			{ name = 'WEAPON_TDIVECTOR',  price = 5, metadata = { registered = true, serial = 'POL' }, requireditem = { 'badgepaspampres' } },
			{ name = 'WEAPON_VHS2',   price = 5, metadata = { registered = true, serial = 'POL' }, requireditem = { 'badgepaspampres' } },
		},
		coords = {
			vec3(-456.145538, 1112.349731, 331.628387)
		}
	},

	MechanicShop = {
		label = 'Mechanic Shop',
		groups = {
			['mechanic'] = 1
		},
		name = 'MechanicShop',
		inventory = {
			{ name = 'brake_parts',      price = 30000 },
			{ name = 'clutch_parts',     price = 20000 },
			{ name = 'engine_parts',     price = 40000 },
			{ name = 'body_parts',       price = 50000 },
		},
		coords = {
			vec3(-2261.23, -421.72, 13.43),
		}
	},

	maxspeedshop = {
		label = 'Maxspeed Shop',
		groups = {
			['maxspeedgarage'] = 1
		},
		name = 'MaxspeedShop',
		inventory = {
			{ name = 'brake_parts',      price = 30000 },
			{ name = 'clutch_parts',     price = 20000 },
			{ name = 'engine_parts',     price = 40000 },
			{ name = 'body_parts',       price = 50000 },
		},
		coords = {
			vec3(-332.562744, -159.230377, 38.592953),
		}
	},

	garage969shop = {
		label = '969Garage Shop',
		groups = {
			['mechanic969'] = 1
		},
		name = 'garage969shop',
		inventory = {
			{ name = 'brake_parts',      price = 30000 },
			{ name = 'clutch_parts',     price = 20000 },
			{ name = 'engine_parts',     price = 40000 },
			{ name = 'body_parts',       price = 50000 },
		},
		coords = {
			vec3(1170.6010, 2621.7751, 38.3738),
		}
	},

	stunbergshop = {
		label = 'Stunberg Shop',
		groups = {
			['stunberg'] = 1
		},
		name = 'stunbergshop',
		inventory = {
			{ name = 'brake_parts',      price = 30000 },
			{ name = 'clutch_parts',     price = 20000 },
			{ name = 'engine_parts',     price = 40000 },
			{ name = 'body_parts',       price = 50000 },
		},
		coords = {
			vec3(-237.2337, 6220.8081, 31.7127),
		}
	},

	kkpgarageshop = {
		label = 'KKP Shop',
		groups = {
			['kkpgarage'] = 0
		},
		name = 'kkpgarageshop',
		inventory = {
			{ name = 'brake_parts',      price = 30000 },
			{ name = 'clutch_parts',     price = 20000 },
			{ name = 'engine_parts',     price = 40000 },
			{ name = 'body_parts',       price = 50000 },
		},
		coords = {
			vec3(1397.937378, -2070.521973, 52.342178),
		}
	},

	ReporterShop = {
		label = 'Reporter Shop',
		groups = {
			['reporter'] = 0
		},
		name = 'ReporterShop',
		inventory = {
			{ name = 'tas_reporter',     price = 55000 },
			{ name = 'microphone',     price = 10000 },
			{ name = 'newsmic',          price = 5 },
			{ name = 'newsbmic',         price = 5 },
			{ name = 'newscam',          price = 5 },

			{ name = 'worklight_04d',    price = 5 },
			{ name = 'worklight_02a',    price = 5 },
			{ name = 'worklight_04b',    price = 5 },
			{ name = 'worklight_04d_l1', price = 5 },
			{ name = 'worklight_tripod_a', price = 5 },
			{ name = 'worklight_tripod_b', price = 5 },
			{ name = 'worklight_tower_a',  price = 5 },

		},
		coords = {
			vec3(-287.231689, -635.131836, 41.514866),
		}
	},

	PabrikShop = {
		label = 'Pabrik Shop',
		groups = {
			['pabrik'] = 3
		},
		name = 'PabrikShop',
		inventory = {
			{ name = 'tirekit',     price = 100 },
			{ name = 'cleaningkit', price = 100 },
			{ name = 'radiator',    price = 100 },
			{ name = 'nitrous',     price = 100, grade = 4 },
		},
		coords = {
			vec3(219.003906, 1091.935669, 225.642120),
		}
	},

	AmbulanceShop = {
		label = 'EMS Shop',
		groups = {
			['ambulance'] = 0
		},
		name = 'AmbulanceShop',
		radius = 2.0,
		distance = 4.0,
		inventory = {
			{ name = 'stretcher',     	  price = 5000,   grade = 2 },
			{ name = 'tas_ambulance',     price = 5000,   grade = 5 },
			{ name = 'bandage',           price = 2500,   grade = 5 },
			{ name = 'firstaid',          price = 3500,   grade = 1 },
			{ name = 'firstaidblue',      price = 3500,   grade = 1 },
			{ name = 'syringe',           price = 6700,   grade = 5 },
			{ name = 'paracetamol',       price = 3400,   grade = 5 },
			{ name = 'paracetamol_syrup', price = 1700,   grade = 5 },
			{ name = 'perban_anak',       price = 2500,   grade = 5 },
			{ name = 'wheelchair',        price = 30000,  grade = 3 },
			{ name = 'infus',             price = 30000,  grade = 3 },
			{ name = 'm_baju_oplas',      price = 30000,  grade = 3 },
			{ name = 'f_baju_oplas',      price = 30000,  grade = 3 },
			{ name = 'crutch',            price = 20000,  grade = 3 },
			{ name = 'tespek',            price = 20000,  grade = 4 },
			{ name = 'susukotak',         price = 2000,   grade = 4 },
			{ name = 'oplasbaru',         price = 150000, grade = 4 },
			{ name = 'banmesidcard',      price = 2000,   grade = 4 },
			{ name = 'diving_gear',       price = 5,      grade = 1 },
			{ name = 'diving_fill',       price = 5,      grade = 1 },
			{ name = 'ems_mdt',           price = 5,      grade = 7 },
		},
		coords = {
			vec3(1116.97, -1540.00, 34.82),
		}
	},

	AmbulanceShop2 = {
		label = 'EMS Shop2',
		groups = {
			['ambulance'] = 4
		},
		name = 'AmbulanceShop',
		radius = 3.0,
		distance = 4.0,
		inventory = {
			{ name = 'oplasbaru', price = 150000, grade = 4 },
		},
		coords = {
			vec3(1145.14, -1590.06, 39.23),
		}
	},

	RSRoxwoodshop = {
		label = 'Shop',
		groups = {
			['rsroxwood'] = 0
		},
		name = 'RSRoxwoodshops',
		radius = 11.0,
		distance = 12.0,
		inventory = {
			{ name = 'oplasbaru',     price = 150000, grade = 10 },
			{ name = 'perbanelastis', price = 2500,   grade = 3 },
			{ name = 'medkit',        price = 3500,   grade = 0 },
			{ name = 'dipurine',      price = 1700,   grade = 3 },
			{ name = 'vitaminec',     price = 1700,   grade = 3 },
			{ name = 'ondansetron',   price = 1700,   grade = 3 },
			{ name = 'pregnanmilk',   price = 1700,   grade = 3 },
			{ name = 'ibuprofen',     price = 3400,   grade = 3 },
			{ name = 'wheelchair',    price = 30000,  grade = 3 },
			{ name = 'crutch',        price = 20000,  grade = 3 },
			{ name = 'diving_gear',   price = 5,      grade = 0 },
			{ name = 'diving_fill',   price = 5,      grade = 0 },
		},
		coords = {
			vec3(-574.888062, 7379.939941, 8.555490),
			vec3(-533.640259, 7375.549316, 12.903254)
		}
	},

	Nightclubmax = {
		label = 'MaxClub Shop',
		groups = {
			['nightclub'] = 3
		},
		name = 'nightclubmaxshop',
		inventory = {
			{ name = 'lighter',           price = 1000,  grade = 3 },
			{ name = 'marlboro',          price = 11000, grade = 3 },
			{ name = 'ticket_nc',         price = 20000, grade = 0 },
			{ name = 'applecider',        price = 400,   grade = 3 },
			{ name = 'rootbeer',          price = 400,   grade = 3 },
			{ name = 'baconfries',        price = 400,   grade = 3 },
			{ name = 'calamari',          price = 400,   grade = 3 },
			{ name = 'azul',              price = 5000,  grade = 3 },
			{ name = 'scarlettseduction', price = 5000,  grade = 3 },
			{ name = 'sheridan',          price = 5000,  grade = 3 },
			{ name = 'cocomax',           price = 3000,  grade = 3 },
			{ name = 'maxcandy',          price = 1500,  grade = 3 },
			{ name = 'cigarpack',         price = 11000, grade = 3 },
		},
		coords = {
			vec3(116.666084, -1279.846069, 29.587255),
		}
	},

	LuxuryNightclub = {
		label = 'ECLUB',
		groups = {
			['luxurynightclub'] = 4
		},
		name = 'luxurynightclubshop',
		inventory = {
			{ name = 'lighter',    price = 1000,  grade = 3 },
			{ name = 'packrokom',  price = 11000, grade = 3 },
			{ name = 'ticket_nc',  price = 20000, grade = 0 },
			{ name = 'beefbites',  price = 400,   grade = 3 },
			{ name = 'steakplate', price = 400,   grade = 3 },
			{ name = 'strjuice',   price = 400,   grade = 3 },
			{ name = 'lemonwater', price = 400,   grade = 3 },
			{ name = 'vodka',      price = 5000,  grade = 3 },
			{ name = 'dwhiskey',   price = 5000,  grade = 3 },
			{ name = 'pwine',      price = 5000,  grade = 3 },
			{ name = 'ydetox',     price = 3000,  grade = 3 },
			{ name = 'ycandy',     price = 1500,  grade = 3 },
			{ name = 'gpipepack',  price = 11000, grade = 3 },
		},
		coords = {
			vec3(71.953598, 6503.471680, 31.626009),
		}
	},

	Hightableshop = {
		label = 'HTShop',
		groups = {
			['hightable'] = 6
		},
		name = 'Hightableshop',
		payment = {
			{ name = 'black_money', label = 'Black Money'}
		},
		inventory = {
			{ name = 'hightable_contract',      price = 100000, grade = 0, currency = 'red_money' },
			{ name = 'torture_kit',             price = 100000, grade = 0, currency = 'red_money' },
			{ name = 'ilegal_gasmask',          price = 50000,  grade = 0, currency = 'red_money' },
			{ name = 'rolling_paper',           price = 40,     grade = 0, currency = 'red_money' },
			{ name = 'spring',                  price = 1200,   grade = 0, currency = 'red_money' },
			{ name = 'gunpowder',               price = 1500,   grade = 0, currency = 'red_money' },
			{ name = 'blueprint',               price = 2000,   grade = 0, currency = 'red_money' },
			{ name = 'gunhandle',               price = 500,    grade = 0, currency = 'red_money' },
			{ name = 'backpack',                price = 150000, grade = 0, currency = 'red_money' },
			{ name = 'at_clip_extended_rifle',  price = 100000, grade = 0, currency = 'red_money' },
			{ name = 'at_flashlight',           price = 100000, grade = 0, currency = 'red_money' },
			{ name = 'at_scope_medium',         price = 100000, grade = 0, currency = 'red_money' },
			{ name = 'at_grip',                 price = 100000, grade = 0, currency = 'red_money' },
			{ name = 'at_suppressor_heavy',     price = 100000, grade = 0, currency = 'red_money' },
			{ name = 'WEAPON_HEAVYRIFLE',       price = 500000, grade = 0, currency = 'red_money' },
			{ name = 'WEAPON_ASSAULTRIFLE_MK2', price = 200000, grade = 0, currency = 'red_money' },
			{ name = 'rtxpot',                  price = 75000,  grade = 0, currency = 'red_money' },
			{ name = 'soilbag',                 price = 500,    grade = 0, currency = 'red_money' },
			{ name = 'weedseed',                price = 1000,   grade = 0, currency = 'red_money' },
			{ name = 'cocaseed',                price = 1250,   grade = 0, currency = 'red_money' },
			{ name = 'wateringcan',             price = 50000,  grade = 0, currency = 'red_money' },
			{ name = 'rtxlamp1',                price = 75000,  grade = 0, currency = 'red_money' },
			{ name = 'rtxlamp2',                price = 75000,  grade = 0, currency = 'red_money' },
			{ name = 'rtxcookingtable',         price = 125000, grade = 0, currency = 'red_money' },
			{ name = 'pills',                   price = 500,    grade = 0, currency = 'red_money' },
			{ name = 'acetone',                 price = 500,    grade = 0, currency = 'red_money' },
			{ name = 'iodine',                  price = 500,    grade = 0, currency = 'red_money' },
			{ name = 'rtxpackingtable',         price = 125000, grade = 0, currency = 'red_money' },
			{ name = 'packingtablelt',          price = 125000, grade = 0, currency = 'red_money' },
			{ name = 'rtxdryingstand',          price = 150000, grade = 0, currency = 'red_money' },
			{ name = 'rtxcauldron',             price = 175000, grade = 0, currency = 'red_money' },
			{ name = 'rtxmethchiller',          price = 175000, grade = 0, currency = 'red_money' },
		},
		coords = {
			vec3(5029.649902, -5737.808105, 17.825693),
		}
	},

	roxwoodutils = {
		label = 'Roxwoodshop',
		groups = {
			['gokudosm'] = 3
		},
		name = 'roxwoodutils',
		radius = 0.6,
		distance = 1.5,
		inventory = {
			{ name = 'spring',     price = 6000,  currency = 'red_money' },
			{ name = 'gunpowder',  price = 7500,  currency = 'red_money' },
			{ name = 'blackprint', price = 10000, currency = 'red_money' },
			{ name = 'gunhandle',  price = 2500,  currency = 'red_money' },
			{ name = 'roxwoodcard',  price = 50000,  currency = 'red_money' },
		},
		coords = {
			vec3(-1408.3104, 7694.7319, 2.2508),
		}
	},

	floristshops = {
		label = 'Florist Shop',
		blip = {
			id = 86, colour = 69, scale = 0.8
		},
		name = 'floristshops',
		inventory = {
			{ name = 'empty_giftbox',  price = 55000 },
			{ name = 'rose_valentine',  price = 55000 },
			{ name = 'bouquet_valentine', price = 150000 },
			{ name = 'bouquet2_valentine', price = 250000 },
		},
		coords = {
			vec3(-1273.520386, -1136.398193, 5.785041)
		}
	},
}
