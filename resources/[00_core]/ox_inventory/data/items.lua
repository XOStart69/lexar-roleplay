return {
	['testburger'] = {
		label = 'Test Burger',
		weight = 220,
		degrade = 1,
		client = {
			image = 'burger_chicken.png',
			status = { hunger = 200000 },
			anim = 'eating',
			prop = 'burger',
			usetime = 2500,
			export = 'ox_inventory_examples.testburger'
		},
		server = {
			export = 'ox_inventory_examples.testburger',
			test = 'what an amazingly delicious burger, amirite?'
		},
		buttons = {
			{
				label = 'Lick it',
				action = function(slot)
					print('You licked the burger')
				end
			},
			{
				label = 'Squeeze it',
				action = function(slot)
					print('You squeezed the burger :(')
				end
			},
			{
				label = 'What do you call a vegan burger?',
				group = 'Hamburger Puns',
				action = function(slot)
					print('A misteak.')
				end
			},
			{
				label = 'What do frogs like to eat with their hamburgers?',
				group = 'Hamburger Puns',
				action = function(slot)
					print('French flies.')
				end
			},
			{
				label = 'Why were the burger and fries running?',
				group = 'Hamburger Puns',
				action = function(slot)
					print('Because they\'re fast food.')
				end
			}
		},
		consume = 0.3
	},

	["infus"] = {
		label = "Infus Stand",
		weight = 2000,
		stack = false,
		close = true,
		description = "Tiang Infus untuk perawatan pasien.",
		client = {
			image = "infus.png",
		}
	},

	["bodycam"] = {
        label = "bodycam", weight = 0, stack = false, close = true, description = "Bodycam",
        client = { image = "bodycam.png", event = "sm_bodycamx:bodycamstatus" }
    },
    ["dashcam"] = {
        label = "dashcam", weight = 0, stack = false, close = true, description = "dashcam",
        client = { image = "dashcam.png", event = "sm_bodycamx:toggleCarCam" }
    },

    ["spikestrip"] = {
        label = "Spike Strip", weight = 500, stack = true, close = true, description = "Deployable stop stick",
        client = { image = "spikestrip.png" }
    },

	['bandage'] = {
		label = 'Bandage',
		weight = 10,
		stack = true,
		close = true,
		degrade = 4320,
		allowArmed = true,
		description = "menyembuhkan luka",
	},

	['syringe'] = {
		label = 'Syringe (jarum suntik)',
		weight = 10,
	},

	['black_money'] = {
		label = 'Uang Hitam',
		weight = 0,
		stack = true,
		close = true,
		description = "illegal",
	},

	['red_money'] = {
		label = 'Uang Merah',
		weight = 0,
		stack = true,
		close = true,
		description = "illegal",
	},

	["burger"] = {
		label = "Burger",
		weight = 50,
		stack = true,
		close = true,
		degrade = 4320,
		description = "makanan ringan",
	},

	['sprunk'] = {
		label = 'Sprunk',
		weight = 350,
		client = {
			status = { thirst = 200000 },
			anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
			prop = { model = `prop_ld_can_01`, pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
			usetime = 2500,
			notification = 'You quenched your thirst with a sprunk'
		}
	},

	['parachute'] = {
		label = 'Parachute',
		weight = 8000,
		stack = false,
		client = {
			anim = { dict = 'clothingshirt', clip = 'try_shirt_positive_d' },
			usetime = 1500
		}
	},

	['garbage'] = {
		label = 'Garbage',
	},

	['paperbag'] = {
		label = 'Paper Bag',
		weight = 1,
		stack = false,
		close = false,
		consume = 0
	},

	['identification'] = {
		label = 'Identification',
		client = {
			image = 'card_id.png'
		}
	},

	['panties'] = {
		label = 'Knickers',
		weight = 10,
		consume = 0,
		client = {
			status = { thirst = -100000, stress = -25000 },
			anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
			prop = { model = `prop_cs_panties_02`, pos = vec3(0.03, 0.0, 0.02), rot = vec3(0.0, -13.5, -1.5) },
			usetime = 2500,
		}
	},

	['lockpick'] = {
		label = 'Lockpick',
		weight = 160,
		stack = true,
		close = true,
		description = 'Basic lockpick untuk membuka pintu rumah',
	},

	['phone'] = {
		label = 'Phone',
		weight = 190,
		degrade = 10080,
		decay = true,
		stack = true,
		close = true,
		consume = 0,
	},

	['money'] = {
		label = 'Money',
		weight = 0,
		stack = true,
		close = true,
		description = "uang",
	},

	['mustard'] = {
		label = 'Mustard',
		weight = 500,
		client = {
			status = { hunger = 25000, thirst = 25000 },
			anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
			prop = { model = `prop_food_mustard`, pos = vec3(0.01, 0.0, -0.07), rot = vec3(1.0, 1.0, -1.5) },
			usetime = 2500,
			notification = 'You.. drank mustard'
		}
	},

	['water'] = {
		label = "Water",
		weight = 50,
		stack = true,
		close = true,
		degrade = 4320,
		description = "minuman ringan",
	},

	-- ['radio'] = {
	-- 	label = 'Radio',
	-- 	weight = 1000,
	-- 	stack = false,
	-- 	allowArmed = true
	-- },

	['armour'] = {
		label = 'Bulletproof Vest',
		weight = 3000,
		stack = false,
		client = {
			anim = { dict = 'clothingshirt', clip = 'try_shirt_positive_d' },
			usetime = 3500
		}
	},

	['clothing'] = {
		label = 'Clothing',
		consume = 0,
	},

	['mastercard'] = {
		label = 'Fleeca Card',
		stack = false,
		weight = 10,
		client = {
			image = 'card_bank.png'
		}
	},

	['tactical_backpack'] = {
		label = 'Tactical Backpack',
		weight = 500,
		stack = false,
		close = false,
		consume = 0,
		description = 'A high-capacity tactical backpack for serious operations'
	},

	["tunerlaptop"] = {
		label = "Tunerchip",
		weight = 2000,
		stack = false,
		close = true,
		description = "With this tunerchip you can get your car on steroids... If you know what you're doing",
		client = {
			image = "tunerchip.png",
		}
	},

	["moneybag"] = {
		label = "Money Bag",
		weight = 0,
		stack = false,
		close = true,
		description = "A bag with cash",
		client = {
			image = "moneybag.png",
		}
	},

	["lighter"] = {
		label = "Lighter",
		weight = 0,
		stack = true,
		close = true,
		degrade = 4320,
		description = "On new years eve a nice fire to stand next to",
		client = {
			image = "lighter.png",
		}
	},

	["walkstick"] = {
		label = "Walking Stick",
		weight = 1000,
		stack = true,
		close = true,
		description = "Walking stick for ya'll grannies out there.. HAHA",
		client = {
			image = "walkstick.png",
		}
	},

	["patriotcamo_attachment"] = {
		label = "Patriot Camo",
		weight = 1000,
		stack = true,
		close = true,
		description = "A patriot camo for a weapon",
		client = {
			image = "patriotcamo_attachment.png",
		}
	},

	["thermalscope_attachment"] = {
		label = "Thermal Scope",
		weight = 1000,
		stack = true,
		close = true,
		description = "A thermal scope for a weapon",
		client = {
			image = "thermalscope_attachment.png",
		}
	},

	["empty_evidence_bag"] = {
		label = "Empty Evidence Bag",
		weight = 0,
		stack = true,
		close = false,
		description = "Used a lot to keep DNA from blood, bullet shells and more",
		client = {
			image = "evidence.png",
		}
	},

	["stickynote"] = {
		label = "Sticky note",
		weight = 0,
		stack = false,
		close = false,
		description = "Sometimes handy to remember something :)",
		client = {
			image = "stickynote.png",
		}
	},

	["weed_purplehaze"] = {
		label = "Purple Haze 2g",
		weight = 200,
		stack = true,
		close = false,
		description = "A weed bag with 2g Purple Haze",
		client = {
			image = "weed_baggy.png",
		}
	},

	["thermite"] = {
		label = "Thermite",
		weight = 1000,
        degrade = 10080,
		stack = true,
		close = true,
		description = "Sometimes you'd wish for everything to burn",
		client = {
			image = "thermite.png",
		}
	},

	["laptop_gold"] = {
		label = "Laptop Gold",
		weight = 1000,
        degrade = 10080,
		stack = true,
		close = true,
		description = "Gold Laptop",
		client = {
			image = "laptop_gold.png",
		}
	},

	["laptop_pink"] = {
		label = "Laptop Pink",
		weight = 1000,
		stack = true,
		close = true,
		description = "Pink Laptop",
		client = {
			image = "laptop_pink.png",
		}
	},

	["bank_card"] = {
		label = "Bank Card",
		weight = 0,
		stack = false,
		close = true,
		description = "Used to access ATM",
		client = {
			image = "bank_card.png",
		}
	},

	["drum_attachment"] = {
		label = "Drum",
		weight = 1000,
		stack = true,
		close = true,
		description = "A drum for a weapon",
		client = {
			image = "drum_attachment.png",
		}
	},

	["veh_brakes"] = {
		label = "Brakes",
		weight = 1000,
		stack = true,
		close = true,
		description = "Upgrade vehicle brakes",
		client = {
			image = "veh_brakes.png",
		}
	},

	["flashlight_attachment"] = {
		label = "Flashlight",
		weight = 1000,
		stack = true,
		close = true,
		description = "A flashlight for a weapon",
		client = {
			image = "flashlight_attachment.png",
		}
	},

    ["cleaningkit"] = {
        label = "Cleaning Kit",
        weight = 100,
        stack = true,
        close = true,
        description = "A microfiber cloth with some soap will let your car sparkle again!",
        client = {
            image = "cleaningkit.png",
        },
        server = {
            export = 'vehiclehandler.cleaningkit'
        }
    },

	["rolex"] = {
		label = "Golden Watch",
		weight = 1500,
		stack = true,
		close = true,
		description = "A golden watch seems like the jackpot to me!",
		client = {
			image = "rolex.png",
		}
	},

	["rubber"] = {
		label = "Rubber",
		weight = 100,
		stack = true,
		close = false,
		description = "Rubber, I believe you can make your own rubber ducky with it :D",
		client = {
			image = "rubber.png",
		}
	},

	["veh_xenons"] = {
		label = "Xenons",
		weight = 1000,
		stack = true,
		close = true,
		description = "Upgrade vehicle xenons",
		client = {
			image = "veh_xenons.png",
		}
	},

    ["advancedrepairkit"] = {
        label = "Advanced Repairkit",
        weight = 100,
        stack = true,
        close = true,
        description = "A nice toolbox with stuff to repair your vehicle",
        client = {
            image = "advancedrepairkit.png",
        },
        server = {
            export = 'vehiclehandler.advancedrepairkit',
        }
    },

	["casinochips"] = {
		label = "Casino Chips",
		weight = 0,
		stack = true,
		close = false,
		description = "Chips For Casino Gambling",
		client = {
			image = "casinochips.png",
		}
	},

	["bellend_muzzle_brake"] = {
		label = "Bellend Muzzle Brake",
		weight = 1000,
		stack = true,
		close = true,
		description = "A muzzle brake for a weapon",
		client = {
			image = "bellend_muzzle_brake.png",
		}
	},

	["heavy_duty_muzzle_brake"] = {
		label = "HD Muzzle Brake",
		weight = 1000,
		stack = true,
		close = true,
		description = "A muzzle brake for a weapon",
		client = {
			image = "heavy_duty_muzzle_brake.png",
		}
	},

	["aluminumoxide"] = {
		label = "Aluminium Powder",
		weight = 100,
		stack = true,
		close = false,
		description = "Some powder to mix with",
		client = {
			image = "aluminumoxide.png",
		}
	},

	["fitbit"] = {
		label = "Fitbit",
		weight = 500,
		stack = false,
		close = true,
		description = "I like fitbit",
		client = {
			image = "fitbit.png",
		}
	},

	["weed_amnesia"] = {
		label = "Amnesia 2g",
		weight = 200,
		stack = true,
		close = false,
		description = "A weed bag with 2g Amnesia",
		client = {
			image = "weed_baggy.png",
		}
	},

	["grip_attachment"] = {
		label = "Grip",
		weight = 1000,
		stack = true,
		close = true,
		description = "A grip for a weapon",
		client = {
			image = "grip_attachment.png",
		}
	},

	["advancedlockpick"] = {
		label = "Advanced Lockpick",
		weight = 500,
        degrade = 10080,
		stack = true,
		close = true,
		description = "If you lose your keys a lot this is very useful... Also useful to open your beers",
		client = {
			image = "advancedlockpick.png",
		}
	},

	["cryptostick"] = {
		label = "Crypto Stick",
		weight = 200,
		stack = false,
		close = true,
		description = "Why would someone ever buy money that doesn't exist.. How many would it contain..?",
		client = {
			image = "cryptostick.png",
		}
	},

	["police_stormram"] = {
		label = "Stormram",
		weight = 18000,
		stack = true,
		close = true,
		description = "A nice tool to break into doors",
		client = {
			image = "police_stormram.png",
		}
	},

	["sessantacamo_attachment"] = {
		label = "Sessanta Nove Camo",
		weight = 1000,
		stack = true,
		close = true,
		description = "A sessanta nove camo for a weapon",
		client = {
			image = "sessantacamo_attachment.png",
		}
	},

	["flat_muzzle_brake"] = {
		label = "Flat Muzzle Brake",
		weight = 1000,
		stack = true,
		close = true,
		description = "A muzzle brake for a weapon",
		client = {
			image = "flat_muzzle_brake.png",
		}
	},

	["item_bench"] = {
		label = "Workbench",
		weight = 15000,
		stack = false,
		close = false,
		description = "A workbench to craft items.",
		client = {
			image = "workbench.png",
		}
	},

	["labkey"] = {
		label = "Key",
		weight = 500,
		stack = false,
		close = true,
		description = "Key for a lock...?",
		client = {
			image = "labkey.png",
		}
	},

	["smallscope_attachment"] = {
		label = "Small Scope",
		weight = 1000,
		stack = true,
		close = true,
		description = "A small scope for a weapon",
		client = {
			image = "smallscope_attachment.png",
		}
	},

	-- ["nitrous"] = {
	-- 	label = "Nitrous",
	-- 	weight = 1000,
	-- 	stack = true,
	-- 	close = true,
	-- 	description = "Speed up, gas pedal! :D",
	-- 	client = {
	-- 		image = "nitrous.png",
	-- 	}
	-- },

	["goldchain"] = {
		label = "Golden Chain",
		weight = 1500,
		stack = true,
		close = true,
		description = "A golden chain seems like the jackpot to me!",
		client = {
			image = "goldchain.png",
		}
	},

	["slanted_muzzle_brake"] = {
		label = "Slanted Muzzle Brake",
		weight = 1000,
		stack = true,
		close = true,
		description = "A muzzle brake for a weapon",
		client = {
			image = "slanted_muzzle_brake.png",
		}
	},

	["weed_skunk_seed"] = {
		label = "Skunk Seed",
		weight = 0,
		stack = true,
		close = true,
		description = "A weed seed of Skunk",
		client = {
			image = "weed_seed.png",
		}
	},

	["veh_interior"] = {
		label = "Interior",
		weight = 1000,
		stack = true,
		close = true,
		description = "Upgrade vehicle interior",
		client = {
			image = "veh_interior.png",
		}
	},

	["snikkel_candy"] = {
		label = "Snikkel",
		weight = 100,
		stack = true,
		close = true,
		description = "Some delicious candy :O",
		client = {
			image = "snikkel_candy.png",
		}
	},

	["suppressor_attachment"] = {
		label = "Suppressor",
		weight = 1000,
		stack = true,
		close = true,
		description = "A suppressor for a weapon",
		client = {
			image = "suppressor_attachment.png",
		}
	},

	["woodcamo_attachment"] = {
		label = "Woodland Camo",
		weight = 1000,
		stack = true,
		close = true,
		description = "A woodland camo for a weapon",
		client = {
			image = "woodcamo_attachment.png",
		}
	},

	["veh_transmission"] = {
		label = "Transmission",
		weight = 1000,
		stack = true,
		close = true,
		description = "Upgrade vehicle transmission",
		client = {
			image = "veh_transmission.png",
		}
	},

	["flush_cutter"] = {
		label = "Flush Cutter",
		weight = 100,
		stack = true,
		close = true,
		description = "Flush Cutter",
		client = {
			image = "flush_cutter.png",
		}
	},

	["ziptie"] = {
		label = "Ziptie",
		weight = 100,
		stack = true,
		close = true,
		description = "Ziptie",
		client = {
			image = "ziptie.png",
		}
	},

	["cuffkeys"] = {
		label = "Cuff Keys",
		weight = 5,
		stack = true,
		close = true,
		description = "kunci borgol",
		client = {
			image = "cuffkeys.png",
		}
	},

	["handcuffs"] = {
		label = "Handcuffs",
		weight = 10,
		stack = true,
		close = true,
		description = "Comes in handy when people misbehave. Maybe it can be used for something else?",
		client = {
			image = "handcuffs.png",
		}
	},

	["veh_engine"] = {
		label = "Tools Engine swap",
		weight = 1000,
		stack = true,
		close = true,
		description = "Upgrade vehicle engine",
		client = {
			image = "veh_engine.png",
		}
	},

	["tactical_muzzle_brake"] = {
		label = "Tactical Muzzle Brake",
		weight = 1000,
		stack = true,
		close = true,
		description = "A muzzle brakee for a weapon",
		client = {
			image = "tactical_muzzle_brake.png",
		}
	},

	["weed_skunk"] = {
		label = "Skunk 2g",
		weight = 200,
		stack = true,
		close = false,
		description = "A weed bag with 2g Skunk",
		client = {
			image = "weed_baggy.png",
		}
	},

	["attachment_bench"] = {
		label = "Attachment Workbench",
		weight = 15000,
		stack = false,
		close = false,
		description = "A workbench for crafting attachments.",
		client = {
			image = "attworkbench.png",
		}
	},

	["markedbills"] = {
		label = "Marked Money",
		weight = 1000,
		stack = false,
		close = true,
		description = "Money?",
		client = {
			image = "markedbills.png",
		}
	},

	["veh_plates"] = {
		label = "Plates",
		weight = 1000,
		stack = true,
		close = true,
		description = "Install vehicle plates",
		client = {
			image = "veh_plates.png",
		}
	},

	["rolling_paper"] = {
		label = "Rolling Paper",
		weight = 0,
		stack = true,
		close = true,
		description = "Paper made specifically for encasing and smoking tobacco or cannabis.",
		client = {
			image = "rolling_paper.png",
		}
	},

	["sandwich"] = {
		label = "Sandwich",
		weight = 200,
		stack = true,
		close = true,
		description = "Nice bread for your stomach",
		client = {
			image = "sandwich.png",
		}
	},

	["diamond_ring"] = {
		label = "Diamond Ring",
		weight = 1500,
		stack = true,
		close = true,
		description = "A diamond ring seems like the jackpot to me!",
		client = {
			image = "diamond_ring.png",
		}
	},

	["coffee"] = {
		label = "Coffee",
		weight = 200,
		stack = true,
		close = true,
		description = "Pump 4 Caffeine",
		client = {
			image = "coffee.png",
		}
	},

	["weed_purplehaze_seed"] = {
		label = "Purple Haze Seed",
		weight = 0,
		stack = true,
		close = true,
		description = "A weed seed of Purple Haze",
		client = {
			image = "weed_seed.png",
		}
	},

	["ironoxide"] = {
		label = "Iron Powder",
		weight = 100,
		stack = true,
		close = false,
		description = "Some powder to mix with.",
		client = {
			image = "ironoxide.png",
		}
	},

	["goldbar"] = {
		label = "Gold Bar",
		weight = 500,
		stack = true,
		close = true,
		description = "Looks pretty expensive to me",
		client = {
			image = "goldbar.png",
		}
	},

	["harness"] = {
		label = "Race Harness",
		weight = 1000,
		stack = false,
		close = true,
		description = "Racing Harness so no matter what you stay in the car",
		client = {
			image = "harness.png",
		}
	},

	["laptop"] = {
		label = "Laptop",
		weight = 4000,
		stack = true,
		close = true,
		description = "Expensive laptop",
		client = {
			image = "laptop.png",
		}
	},

	["veh_suspension"] = {
		label = "Suspension",
		weight = 1000,
		stack = true,
		close = true,
		description = "Upgrade vehicle suspension",
		client = {
			image = "veh_suspension.png",
		}
	},

	["lawyerpass"] = {
		label = "Lawyer Pass",
		weight = 0,
		stack = false,
		close = false,
		description = "Pass exclusive to lawyers to show they can represent a suspect",
		client = {
			image = "lawyerpass.png",
		}
	},

	["filled_evidence_bag"] = {
		label = "Evidence Bag",
		weight = 200,
		stack = false,
		close = false,
		description = "A filled evidence bag to see who committed the crime >:(",
		client = {
			image = "evidence.png",
		}
	},

	["firework2"] = {
		label = "Poppelers",
		weight = 1000,
		stack = true,
		close = true,
		description = "Fireworks",
		client = {
			image = "firework2.png",
		}
	},

	["barrel_attachment"] = {
		label = "Barrel",
		weight = 1000,
		stack = true,
		close = true,
		description = "A barrel for a weapon",
		client = {
			image = "barrel_attachment.png",
		}
	},

	["brushcamo_attachment"] = {
		label = "Brushstroke Camo",
		weight = 1000,
		stack = true,
		close = true,
		description = "A brushstroke camo for a weapon",
		client = {
			image = "brushcamo_attachment.png",
		}
	},

	["weed_ogkush_seed"] = {
		label = "OGKush Seed",
		weight = 0,
		stack = true,
		close = true,
		description = "A weed seed of OG Kush",
		client = {
			image = "weed_seed.png",
		}
	},

	["weed_ak47_seed"] = {
		label = "AK47 Seed",
		weight = 0,
		stack = true,
		close = true,
		description = "A weed seed of AK47",
		client = {
			image = "weed_seed.png",
		}
	},

	["grapejuice"] = {
		label = "Grape Juice",
		weight = 200,
		stack = true,
		close = false,
		description = "Grape juice is said to be healthy",
		client = {
			image = "grapejuice.png",
		}
	},

	["veh_tint"] = {
		label = "Tints",
		weight = 1000,
		stack = true,
		close = true,
		description = "Install vehicle tint",
		client = {
			image = "veh_tint.png",
		}
	},

	["iphone"] = {
		label = "iPhone",
		weight = 1000,
		stack = true,
		close = true,
		description = "Very expensive phone",
		client = {
			image = "iphone.png",
		}
	},

	["wine"] = {
		label = "Wine",
		weight = 300,
		stack = true,
		close = false,
		description = "Some good wine to drink on a fine evening",
		client = {
			image = "wine.png",
		}
	},

	["radioscanner"] = {
		label = "Radio Scanner",
		weight = 1000,
		stack = true,
		close = true,
		description = "With this you can get some police alerts. Not 100% effective however",
		client = {
			image = "radioscanner.png",
		}
	},

	["perseuscamo_attachment"] = {
		label = "Perseus Camo",
		weight = 1000,
		stack = true,
		close = true,
		description = "A perseus camo for a weapon",
		client = {
			image = "perseuscamo_attachment.png",
		}
	},

	["largescope_attachment"] = {
		label = "Large Scope",
		weight = 1000,
		stack = true,
		close = true,
		description = "A large scope for a weapon",
		client = {
			image = "largescope_attachment.png",
		}
	},

	["heavyarmor"] = {
		label = "Heavy Armor",
		weight = 5000,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Some protection won't hurt... right?",
		client = {
			image = "armor.png",
		}
	},

	["veh_exterior"] = {
		label = "Exterior",
		weight = 1000,
		stack = true,
		close = true,
		description = "Upgrade vehicle exterior",
		client = {
			image = "veh_exterior.png",
		}
	},

	["armor"] = {
		label = "Armor",
		weight = 5000,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Some protection won't hurt... right?",
	},

	["armorroxwood"] = {
		label = "Armor Roxwood",
		weight = 2500,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Some protection won't hurt... right?",
	},

	["medscope_attachment"] = {
		label = "Medium Scope",
		weight = 1000,
		stack = true,
		close = true,
		description = "A medium scope for a weapon",
		client = {
			image = "medscope_attachment.png",
		}
	},

	["fat_end_muzzle_brake"] = {
		label = "Fat End Muzzle Brake",
		weight = 1000,
		stack = true,
		close = true,
		description = "A muzzle brake for a weapon",
		client = {
			image = "fat_end_muzzle_brake.png",
		}
	},

	-- ["vodka"] = {
	-- 	label = "Vodka",
	-- 	weight = 500,
	-- 	stack = true,
	-- 	close = true,
	-- 	description = "For all the thirsty out there",
	-- 	client = {
	-- 		image = "vodka.png",
	-- 	}
	-- },

	["diamond"] = {
		label = "Diamond",
		weight = 1000,
		stack = true,
		close = true,
		description = "A diamond seems like the jackpot to me!",
		client = {
			image = "diamond.png",
		}
	},

	["painkillers"] = {
		label = "Painkillers",
		weight = 0,
		stack = true,
		close = true,
		description = "For pain you can't stand anymore, take this pill that'd make you feel great again",
		client = {
			image = "painkillers.png",
		}
	},

	["empty_weed_bag"] = {
		label = "Empty Weed Bag",
		weight = 0,
		stack = true,
		close = true,
		description = "A small empty bag",
		client = {
			image = "weed_baggy_empty.png",
		}
	},

	["crack_baggy"] = {
		label = "Bag of Crack",
		weight = 0,
		stack = true,
		close = true,
		description = "To get happy faster",
		client = {
			image = "crack_baggy.png",
		}
	},

	["certificate"] = {
		label = "Certificate",
		weight = 0,
		stack = true,
		close = true,
		description = "Certificate that proves you own certain stuff",
		client = {
			image = "certificate.png",
		}
	},

	["firework4"] = {
		label = "Weeping Willow",
		weight = 1000,
		stack = true,
		close = true,
		description = "Fireworks",
		client = {
			image = "firework4.png",
		}
	},

	["grape"] = {
		label = "Grape",
		weight = 100,
		stack = true,
		close = false,
		description = "Mmmmh yummie, grapes",
		client = {
			image = "grape.png",
		}
	},

	["veh_armor"] = {
		label = "Armor",
		weight = 1000,
		stack = true,
		close = true,
		description = "Upgrade vehicle armor",
		client = {
			image = "veh_armor.png",
		}
	},

	["samsungphone"] = {
		label = "Samsung S10",
		weight = 1000,
		stack = true,
		close = true,
		description = "Very expensive phone",
		client = {
			image = "samsungphone.png",
		}
	},

	["advscope_attachment"] = {
		label = "Advanced Scope",
		weight = 1000,
		stack = true,
		close = true,
		description = "An advanced scope for a weapon",
		client = {
			image = "advscope_attachment.png",
		}
	},

	["veh_turbo"] = {
		label = "Turbo",
		weight = 1000,
		stack = true,
		close = true,
		description = "Install vehicle turbo",
		client = {
			image = "veh_turbo.png",
		}
	},

	["leopardcamo_attachment"] = {
		label = "Leopard Camo",
		weight = 1000,
		stack = true,
		close = true,
		description = "A leopard camo for a weapon",
		client = {
			image = "leopardcamo_attachment.png",
		}
	},

	["coke_small_brick"] = {
		label = "Coke Package",
		weight = 350,
		stack = false,
		close = true,
		description = "Small package of cocaine, mostly used for deals and takes a lot of space",
		client = {
			image = "coke_small_brick.png",
		}
	},

	["binoculars"] = {
		label = "Binoculars",
		weight = 600,
		degrade = 5760,
		stack = true,
		close = true,
		description = "Sneaky Breaky...",
		client = {
			image = "binoculars.png",
		}
	},

	["antipatharia_coral"] = {
		label = "Antipatharia",
		weight = 1000,
		stack = true,
		close = true,
		description = "Its also known as black corals or thorn corals",
		client = {
			image = "antipatharia_coral.png",
		}
	},

	["weed_ogkush"] = {
		label = "OGKush 2g",
		weight = 200,
		stack = true,
		close = false,
		description = "A weed bag with 2g OG Kush",
		client = {
			image = "weed_baggy.png",
		}
	},

    ["repairkit"] = {
        label = "Repairkit",
        weight = 500,
        stack = true,
        close = true,
        description = "A nice toolbox with stuff to repair your vehicle",
        client = {
            image = "repairkit.png",
        },
        server = {
            export = 'vehiclehandler.repairkit',
        }
    },

	["tirekit"] = {
        label = "Tire Kit",
        weight = 250,
        stack = true,
        close = true,
        description = "A nice toolbox with stuff to repair your tire",
        client = {
            image = "tirekit.png",
        },
        server = {
            export = 'vehiclehandler.tirekit'
        }
    },

	["steel"] = {
		label = "Steel",
		weight = 100,
		stack = true,
		close = false,
		description = "Nice piece of metal that you can probably use for something",
		client = {
			image = "steel.png",
		}
	},

	["twerks_candy"] = {
		label = "Twerks",
		weight = 100,
		stack = true,
		close = true,
		description = "Some delicious candy :O",
		client = {
			image = "twerks_candy.png",
		}
	},

	["beer"] = {
		label = "Beer",
		weight = 500,
		stack = true,
		close = true,
		description = "Nothing like a good cold beer!",
		client = {
			image = "beer.png",
		}
	},

	["digicamo_attachment"] = {
		label = "Digital Camo",
		weight = 1000,
		stack = true,
		close = true,
		description = "A digital camo for a weapon",
		client = {
			image = "digicamo_attachment.png",
		}
	},

	["boomcamo_attachment"] = {
		label = "Boom Camo",
		weight = 1000,
		stack = true,
		close = true,
		description = "A boom camo for a weapon",
		client = {
			image = "boomcamo_attachment.png",
		}
	},

	["holoscope_attachment"] = {
		label = "Holo Scope",
		weight = 1000,
		stack = true,
		close = true,
		description = "A holo scope for a weapon",
		client = {
			image = "holoscope_attachment.png",
		}
	},

	["veh_neons"] = {
		label = "Neons",
		weight = 1000,
		stack = true,
		close = true,
		description = "Upgrade vehicle neons",
		client = {
			image = "veh_neons.png",
		}
	},

	["firework3"] = {
		label = "WipeOut",
		weight = 1000,
		stack = true,
		close = true,
		description = "Fireworks",
		client = {
			image = "firework3.png",
		}
	},

	["tosti"] = {
		label = "Grilled Cheese Sandwich",
		weight = 200,
		stack = true,
		close = true,
		description = "Nice to eat",
		client = {
			image = "tosti.png",
		}
	},

	["trojan_usb"] = {
		label = "Trojan USB",
		weight = 0,
        degrade = 10080,
		stack = true,
		close = true,
		description = "Handy software to shut down some systems",
		client = {
			image = "trojan_usb.png",
		}
	},

	["squared_muzzle_brake"] = {
		label = "Squared Muzzle Brake",
		weight = 1000,
		stack = true,
		close = true,
		description = "A muzzle brake for a weapon",
		client = {
			image = "squared_muzzle_brake.png",
		}
	},

	["tenkgoldchain"] = {
		label = "10k Gold Chain",
		weight = 2000,
		stack = true,
		close = true,
		description = "10 carat golden chain",
		client = {
			image = "tenkgoldchain.png",
		}
	},

	["weed_amnesia_seed"] = {
		label = "Amnesia Seed",
		weight = 0,
		stack = true,
		close = true,
		description = "A weed seed of Amnesia",
		client = {
			image = "weed_seed.png",
		}
	},

	["firework1"] = {
		label = "2Brothers",
		weight = 1000,
		stack = true,
		close = true,
		description = "Fireworks",
		client = {
			image = "firework1.png",
		}
	},

	["newsmic"] = {
		label = "News Microphone",
		weight = 100,
		stack = false,
		close = true,
		description = "A microphone for the news",
		client = {
			image = "newsmic.png",
		}
	},

	["diving_gear"] = {
		label = "Diving Gear",
		weight = 300,
		stack = false,
		close = true,
		description = "An oxygen tank and a rebreather",
		client = {
			image = "diving_gear.png",
		}
	},

	["weed_nutrition"] = {
		label = "Plant Fertilizer",
		weight = 2000,
		stack = true,
		close = true,
		description = "Plant nutrition",
		client = {
			image = "weed_nutrition.png",
		}
	},

	["plastic"] = {
		label = "Plastic",
		weight = 100,
		stack = true,
		close = false,
		description = "RECYCLE! - Greta Thunberg 2019",
		client = {
			image = "plastic.png",
		}
	},

	["weed_whitewidow_seed"] = {
		label = "White Widow Seed",
		weight = 0,
		stack = true,
		close = false,
		description = "A weed seed of White Widow",
		client = {
			image = "weed_seed.png",
		}
	},

	["cokebaggy"] = {
		label = "Bag of Coke",
		weight = 0,
		stack = true,
		close = true,
		description = "To get happy real quick",
		client = {
			image = "cocaine_baggy.png",
		}
	},

	["diving_fill"] = {
		label = "Diving Tube",
		weight = 3000,
		stack = false,
		close = true,
		description = "An oxygen tube and a rebreather",
		client = {
			image = "diving_tube.png",
		}
	},

	["security_card_02"] = {
		label = "Security Card B",
		weight = 0,
        degrade = 10080,
		stack = true,
		close = true,
		description = "A security card... I wonder what it goes to",
		client = {
			image = "security_card_02.png",
		}
	},

	["clip_attachment"] = {
		label = "Clip",
		weight = 1000,
		stack = true,
		close = true,
		description = "A clip for a weapon",
		client = {
			image = "clip_attachment.png",
		}
	},

	["firstaid"] = {
		label = "First Aid",
		weight = 10,
		stack = true,
		close = true,
		description = "You can use this First Aid kit to get people back on their feet",
		client = {
			image = "firstaid.png",
		}
	},

	["firstaidblue"] = {
		label = "First Aid (Blue)",
		weight = 10,
		stack = true,
		close = true,
		description = "You can use this First Aid kit to get people back on their feet",
	},

	["drill"] = {
		label = "Drill",
		weight = 3000,
        degrade = 10080,
		stack = true,
		close = false,
		description = "The real deal...",
		client = {
			image = "drill.png",
		}
	},

	["c4_bomb"] = {
		label = "C4 Bomb",
		weight = 1000,
        degrade = 10080,
		stack = true,
		close = false,
		description = "for robbery purpose",
		client = {
			image = "c4_bomb.png",
		}
	},

	["code_injector"] = {
		label = "Code Injector",
		weight = 500,
        degrade = 10080,
		stack = true,
		close = true,
		description = "A device used to inject code into electronic systems",
		client = {
			image = "code_injector.png",
		}
	},

	["pipe_bomb"] = {
		label = "Pipe Bomb",
		weight = 2000,
        degrade = 10080,
		stack = true,
		close = true,
		description = "A homemade explosive device",
		client = {
			image = "pipe_bomb.png",
		}
	},

	["rusty_drill"] = {
		label = "Rusty Drill",
		weight = 3000,
        degrade = 10080,
		stack = true,
		close = true,
		description = "An old but functional drill for breaking through locks",
		client = {
			image = "rusty_drill.png",
		}
	},

	["backdoor_kit"] = {
		label = "Backdoor Kit",
		weight = 1000,
        degrade = 10080,
		stack = true,
		close = true,
		description = "A toolkit for bypassing security systems",
		client = {
			image = "backdoor_kit.png",
		}
	},

	["laptop_malware"] = {
		label = "Laptop Malware",
		weight = 2000,
        degrade = 10080,
		stack = true,
		close = true,
		description = "A laptop preloaded with malware for hacking",
		client = {
			image = "laptop_malware.png",
		}
	},

	["geocamo_attachment"] = {
		label = "Geometric Camo",
		weight = 1000,
		stack = true,
		close = true,
		description = "A geometric camo for a weapon",
		client = {
			image = "geocamo_attachment.png",
		}
	},

	["luxuryfinish_attachment"] = {
		label = "Luxury Finish",
		weight = 1000,
		stack = true,
		close = true,
		description = "A luxury finish for a weapon",
		client = {
			image = "luxuryfinish_attachment.png",
		}
	},

	["weed_whitewidow"] = {
		label = "White Widow 2g",
		weight = 200,
		stack = true,
		close = false,
		description = "A weed bag with 2g White Widow",
		client = {
			image = "weed_baggy.png",
		}
	},

	["split_end_muzzle_brake"] = {
		label = "Split End Muzzle Brake",
		weight = 1000,
		stack = true,
		close = true,
		description = "A muzzle brake for a weapon",
		client = {
			image = "split_end_muzzle_brake.png",
		}
	},

	["whiskey"] = {
		label = "Whiskey",
		weight = 500,
		stack = true,
		close = true,
		description = "For all the thirsty out there",
		client = {
			image = "whiskey.png",
		}
	},

	["xtcbaggy"] = {
		label = "Bag of XTC",
		weight = 0,
		stack = true,
		close = true,
		description = "Pop those pills baby",
		client = {
			image = "xtc_baggy.png",
		}
	},

	["coke_brick"] = {
		label = "Coke Brick",
		weight = 1000,
		stack = false,
		close = true,
		description = "Heavy package of cocaine, mostly used for deals and takes a lot of space",
		client = {
			image = "coke_brick.png",
		}
	},

	["screwdriverset"] = {
		label = "Toolkit",
		weight = 1000,
		stack = true,
		close = false,
		description = "Very useful to screw... screws...",
		client = {
			image = "screwdriverset.png",
		}
	},

	["newsbmic"] = {
		label = "Boom Microphone",
		weight = 100,
		stack = false,
		close = true,
		description = "A Useable BoomMic",
		client = {
			image = "newsbmic.png",
		}
	},

	["ifaks"] = {
		label = "ifaks",
		weight = 200,
		stack = true,
		close = true,
		description = "ifaks for healing and a complete stress remover.",
		client = {
			image = "ifaks.png",
		}
	},

	["weed_ak47"] = {
		label = "AK47 2g",
		weight = 200,
		stack = true,
		close = false,
		description = "A weed bag with 2g AK47",
		client = {
			image = "weed_baggy.png",
		}
	},

	["veh_wheels"] = {
		label = "Wheels",
		weight = 1000,
		stack = true,
		close = true,
		description = "Upgrade vehicle wheels",
		client = {
			image = "veh_wheels.png",
		}
	},

	["joint"] = {
		label = "Joint",
		weight = 250,
		stack = true,
		close = true,
		description = "Sidney would be very proud at you",
		allowArmed = true,
		client = {
			image = "joint.png",
		}
	},

	["k2plant"] = {
		label = "K2 Plant",
		weight = 100,
		stack = true,
		close = true,
		description = "k2 plant piece",
	},
	["paradiseplant"] = {
		label = "Blue Paradise Plant",
		weight = 100,
		stack = true,
		close = true,
		description = "blue paradise plant piece",
	},

	["blueparadise"] = {
		label = "Blue Paradise",
		weight = 0,
		degrade = 40320,
		stack = true,
		close = true,
		description = "Sidney would be very proud at you",
		allowArmed = true,
	},

	["k2narko"] = {
		label = "K2",
		weight = 0,
		degrade = 40320,
		stack = true,
		close = true,
		description = "Sidney would be very proud at you",
		allowArmed = true,
	},

	["veh_toolbox"] = {
		label = "Toolbox",
		weight = 1000,
		stack = true,
		close = true,
		description = "Check vehicle status",
		client = {
			image = "veh_toolbox.png",
		}
	},

	["weed_brick"] = {
		label = "Weed Brick",
		weight = 1000,
		stack = true,
		close = true,
		description = "1KG Weed Brick to sell to large customers.",
		client = {
			image = "weed_brick.png",
		}
	},

	["gatecrack"] = {
		label = "Gatecrack",
		weight = 0,
		stack = true,
		close = true,
		description = "Handy software to tear down some fences",
		client = {
			image = "usb_device.png",
		}
	},

	["oxy"] = {
		label = "Prescription Oxy",
		weight = 0,
		stack = true,
		close = true,
		description = "The Label Has Been Ripped Off",
		client = {
			image = "oxy.png",
		}
	},

	["metalscrap"] = {
		label = "Metal Scrap",
		weight = 100,
		stack = true,
		close = false,
		description = "You can probably make something nice out of this",
		client = {
			image = "metalscrap.png",
		}
	},

	["jerry_can"] = {
		label = "Jerrycan 20L",
		weight = 1000,
		stack = true,
		close = true,
		description = "A can full of Fuel",
		client = {
			image = "jerry_can.png",
		}
	},

	["jerrycan"] = {
		label = "Jerry Can",
		weight = 1000,
		stack = false,
		close = false,
		description = "A Jerry Can made to hold gasoline.",
		client = {
			image = "jerrycan.png",
		}
	},

	["newscam"] = {
		label = "News Camera",
		weight = 100,
		stack = false,
		close = true,
		description = "A camera for the news",
		client = {
			image = "newscam.png",
		}
	},

	["pinger"] = {
		label = "Pinger",
		weight = 1000,
		stack = true,
		close = true,
		description = "With a pinger and your phone you can send out your location",
		client = {
			image = "pinger.png",
		}
	},

	["comp_attachment"] = {
		label = "Compensator",
		weight = 1000,
		stack = true,
		close = true,
		description = "A compensator for a weapon",
		client = {
			image = "comp_attachment.png",
		}
	},

	["precision_muzzle_brake"] = {
		label = "Precision Muzzle Brake",
		weight = 1000,
		stack = true,
		close = true,
		description = "A muzzle brake for a weapon",
		client = {
			image = "precision_muzzle_brake.png",
		}
	},

	["skullcamo_attachment"] = {
		label = "Skull Camo",
		weight = 1000,
		stack = true,
		close = true,
		description = "A skull camo for a weapon",
		client = {
			image = "skullcamo_attachment.png",
		}
	},

	["water_bottle"] = {
		label = "Bottle of Water",
		weight = 500,
		stack = true,
		close = true,
		description = "For all the thirsty out there",
		client = {
			image = "water_bottle.png",
		}
	},

	["dendrogyra_coral"] = {
		label = "Dendrogyra",
		weight = 1000,
		stack = true,
		close = true,
		description = "Its also known as pillar coral",
		client = {
			image = "dendrogyra_coral.png",
		}
	},

	["electronickit"] = {
		label = "Electronic Kit",
		weight = 100,
		stack = true,
		close = true,
		description = "If you've always wanted to build a robot you can maybe start here. Maybe you'll be the new Elon Musk?",
		client = {
			image = "electronickit.png",
		}
	},

	["nvscope_attachment"] = {
		label = "Night Vision Scope",
		weight = 1000,
		stack = true,
		close = true,
		description = "A night vision scope for a weapon",
		client = {
			image = "nvscope_attachment.png",
		}
	},

	["zebracamo_attachment"] = {
		label = "Zebra Camo",
		weight = 1000,
		stack = true,
		close = true,
		description = "A zebra camo for a weapon",
		client = {
			image = "zebracamo_attachment.png",
		}
	},

	["tirerepairkit"] = {
		label = "Tire Repair Kit",
		weight = 1000,
		stack = true,
		close = true,
		description = "A kit to repair your tires",
		client = {
			image = "tirerepairkit.png",
		}
	},

	["security_card_01"] = {
		label = "Security Card A",
		weight = 0,
        degrade = 10080,
		stack = true,
		close = true,
		description = "A security card... I wonder what it goes to",
		client = {
			image = "security_card_01.png",
		}
	},

	["security_card"] = {
		label = "Security Card",
		weight = 0,
        degrade = 10080,
		stack = true,
		close = true,
		description = "A security card... I wonder what it goes to",
		client = {
			image = "security_card.png",
		}
	},

	["glass"] = {
		label = "Glass",
		weight = 100,
		stack = true,
		close = false,
		description = "It is very fragile, watch out",
		client = {
			image = "glass.png",
		}
	},

	["kurkakola"] = {
		label = "Cola",
		weight = 500,
		stack = true,
		close = true,
		description = "For all the thirsty out there",
		client = {
			image = "cola.png",
		}
	},

	['boxstarterpack'] = {
		label = "Box warga baru",
		weight = 100,
		stack = true,
		close = true,
		rarity = 'legendary',
	},
	["nasgor"] = {
		label = "Nasi Goreng Gila",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		rarity = 'mythical',
		description = "makanan Enak",
	},
	["coconut_ice"] = {
		label = "Es Kelapa",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		rarity = 'rare',
		description = "minuman Enak",
	},
	["scarlettseduction"] = {
		label = "Scarlett Seduction",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "minuman alcohol",
	},
	["azul"] = {
		label = "Claze Azul Ultra",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "minuman alcohol",
	},
	["sheridan"] = {
		label = "Sheridan",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "minuman alcohol",
	},
	["cocomax"] = {
		label = "Coco Max",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "penawar mabuk",
	},

	["maxcandy"] = {
		label = "Max Candy",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		allowArmed = true,
		description = "permen enak",
	},

	["ycandy"] = {
		label = "ECL lollipop",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		allowArmed = true,
		description = "permen enak",
	},

	["applecider"] = {
		label = "Apple Cider",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "minuman max club",
	},
	["rootbeer"] = {
		label = "Root Beer",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "minuman max club",
	},

	["calamari"] = {
		label = "Crispy Calamari",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "snack max club",
	},

	["baconfries"] = {
		label = "Bacon Truffle Fries",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "snack max club",
	},

	["steakplate"] = {
		label = "Steak Plate",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "snack luxury club",
	},

	["lemonwater"] = {
		label = "Lemon Water",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "snack luxury club",
	},

	["beefbites"] = {
		label = "Midnight Beef Bites",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "snack luxury club",
	},

	["strjuice"] = {
		label = "Strawberry Juice",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "snack luxury club",
	},

	["bodybooster"] = {
		label = "Body Booster",
		weight = 500,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body Booster gain armor",
	},

	['armor5'] = {
		label = 'Armor5',
		weight = 1000,
		stack = false,
		rarity = 'divine',
	},

	['radio'] = {
		label = 'Radio',
		weight = 1000,
		degrade = 10080,
		allowArmed = true,
		consume = 0,
		close = true,
		client = {
			event = 'mm_radio:client:use'
		}
	},

	['jammer'] = {
		label = 'Radio Jammer',
		weight = 10000,
		allowArmed = true,
		client = {
			event = 'mm_radio:client:usejammer'
		}
	},

	['radiocell'] = {
		label = 'AAA Cells',
		weight = 1000,
		stack = true,
		allowArmed = true,
		client = {
			event = 'mm_radio:client:recharge'
		}
	},

	['ktp'] = {
		label = 'Kartu Tanda Penduduk',
		weight = 10,
		stack = false,
		close = true,
		-- degrade = 10080,
		description = 'Kartu identitas resmi sebagai warga negara.',
		client = {
			image = 'ktp.png'
		}
	},

	['ktp_palsu'] = {
		label = 'Kartu Tanda Penduduk',
		weight = 10,
		stack = false,
		close = true,
		-- degrade = 10080,
		description = 'Kartu identitas resmi sebagai warga negara.',
		client = {
			image = 'ktp.png'
		}
	},

	['kia'] = {
		label = 'Kartu Identitas Anak',
		weight = 10,
		stack = false,
		close = true,
		-- degrade = 10080,
		description = 'Kartu identitas anak-anak',
		client = {
			image = 'kia.png'
		}
	},

	['weaponlicense'] = {
		label = "Weapon License",
		weight = 0,
		stack = false,
		close = true,
		description = "Izin kepemilikan senjata api",
		client = {
			image = "weapon_license.png",
		}
	},

	['huntinglicense'] = {
		label = "Hunting License",
		weight = 0,
		stack = false,
		close = true,
		description = "Izin kepemilikan senjata api untuk berburu",
		client = {
			image = "hunting_license.png",
		}
	},

	['driver_license'] = {
		label = "Drivers License",
		weight = 0,
		stack = false,
		close = true,
		description = "Permit to show you can drive a vehicle",
		client = {
			image = "driver_license.png",
		}
	},

	-- ['driver_license_a'] = {
	-- 	label = "SIM A (Mobil)",
	-- 	weight = 0,
	-- 	stack = false,
	-- 	close = true,
	-- 	description = "Permit to show you can drive a vehicle",
	-- 	client = {
	-- 		image = "driver_license_a.png",
	-- 	}
	-- },

	-- ['driver_license_c'] = {
	-- 	label = "SIM C (Motor)",
	-- 	weight = 0,
	-- 	stack = false,
	-- 	close = true,
	-- 	description = "Permit to show you can drive a vehicle",
	-- 	client = {
	-- 		image = "driver_license_c.png",
	-- 	}
	-- },

	['helicopter_license'] = {
		label = "Helicopter License",
		weight = 0,
		stack = false,
		close = true,
		description = "Permit to show you can drive a helicopter",
		client = {
			image = "helicopter_license.png",
		}
	},

	["id_card"] = {
		label = "ID Card",
		weight = 0,
		stack = false,
		close = false,
		description = "A card containing all your information to identify yourself",
		client = {
			image = "id_card.png",
		}
	},


	-- Tools
	['pickaxe'] = {
		label = 'Pickaxe',
		weight = 2500,
		stack = false,
		close = false,
		description = 'Alat untuk menambang batu',
		client = {
			image = 'pickaxe.png',
		}
	},

	['hatchet'] = {
		label = 'Kapak',
		weight = 2000,
		stack = false,
		close = false,
		description = 'Alat untuk menebang kayu',
		client = {
			image = 'hatchet.png',
		}
	},

	['scissors'] = {
		label = 'Gunting',
		weight = 200,
		degrade = 7200,
		stack = false,
		close = false,
		description = 'Alat untuk memotong benang',
		client = {
			image = 'scissors.png',
		}
	},

	['barber_scissors'] = {
		label = 'Gunting Cukur',
		weight = 150,
		stack = false,
		close = false,
		description = 'Gunting barber untuk memotong rambut pelanggan',
		client = {
			image = 'scissors.png',
		}
	},

	['barber_chair'] = {
		label = 'Kursi Cukur',
		weight = 10000,
		stack = false,
		close = true,
		description = 'Kursi cukur portable untuk layanan home service',
		client = {
			image = 'barber_chair.png',
			export = 'sm_barbershop.placeChair',
		}
	},

	-- Mining Items
	['stone'] = {
		label = 'Batu',
		weight = 500,
		stack = true,
		close = false,
		description = 'Batu mentah dari tambang',
		client = {
			image = 'stone.png',
		}
	},

	['clean_stone'] = {
		label = 'Batu Bersih',
		weight = 400,
		stack = true,
		close = false,
		description = 'Batu yang sudah dicuci',
		client = {
			image = 'clean_stone.png',
		}
	},

	['copper'] = {
		label = 'Tembaga',
		weight = 500,
		stack = true,
		close = false,
		description = 'Batangan tembaga',
		client = {
			image = 'copper.png',
		}
	},

	['silver'] = {
		label = 'Perak',
		weight = 500,
		stack = true,
		close = false,
		description = 'Batangan perak',
		client = {
			image = 'silver.png',
		}
	},

	['sulfur'] = {
		label = 'Sulfur',
		weight = 300,
		stack = true,
		close = false,
		description = 'Kristal sulfur',
		client = {
			image = 'sulfur.png',
		}
	},

	['aluminum'] = {
		label = 'Aluminium',
		weight = 400,
		stack = true,
		close = false,
		description = 'Batangan aluminium',
		client = {
			image = 'aluminum.png',
		}
	},

	['iron'] = {
		label = 'Besi',
		weight = 600,
		stack = true,
		close = false,
		description = 'Batangan besi',
		client = {
			image = 'iron.png',
		}
	},

	['nefrit'] = {
		label = 'Nefrit',
		weight = 300,
		stack = true,
		close = false,
		description = 'Batu nefrit langka',
		client = {
			image = 'nefrit.png',
		}
	},

	['quartz'] = {
		label = 'Quartz',
		weight = 400,
		stack = true,
		close = false,
		description = 'Kristal kuarsa',
		client = {
			image = 'quartz.png',
		}
	},

	-- Lumberjack Items
	['wood_log'] = {
		label = 'Kayu Gelondongan',
		weight = 500,
		stack = true,
		close = false,
		description = 'Kayu mentah dari pohon',
		client = {
			image = 'wood_log.png',
		}
	},

	['wood_cut'] = {
		label = 'Kayu Potong',
		weight = 400,
		stack = true,
		close = false,
		description = 'Kayu yang sudah dipotong',
		client = {
			image = 'wood_cut.png',
		}
	},

	['packaged_plank'] = {
		label = 'Paket Papan Kayu',
		weight = 500,
		stack = true,
		close = false,
		description = 'Papan kayu yang sudah dikemas',
		client = {
			image = 'packaged_plank.png',
		}
	},

	-- Tailor Items
	['thread'] = {
		label = 'Benang',
		weight = 300,
		stack = true,
		close = false,
		description = 'Gulungan benang',
		client = {
			image = 'thread.png',
		}
	},

	['fabric'] = {
		label = 'Kain',
		weight = 100,
		stack = true,
		close = false,
		description = 'Lembaran kain',
		client = {
			image = 'fabric.png',
		}
	},

	['clothes'] = {
		label = 'Baju',
		weight = 200,
		stack = true,
		close = false,
		description = 'Baju hasil jahitan',
		client = {
			image = 'clothes.png',
		}
	},
	-- oilworker
	['minyak_mentah'] = {
		label = 'Minyak Mentah',
		weight = 500,
		stack = true,
		close = false,
		description = 'Minyak bumi',
		client = {
			image = 'minyak_mentah.png',
		}
	},

	['oil'] = {
		label = 'Oli Olahan',
		weight = 100,
		stack = true,
		close = false,
		description = 'Olahan oli dari minyak mentah',
		client = {
			image = 'oil.png',
		}
	},

	['drum_oil'] = {
		label = 'Drum Oil',
		weight = 50,
		stack = true,
		close = false,
		description = 'Drum berisi oli olahan',
		client = {
			image = 'drum_oil.png',
		}
	},
	--recycle
	['recycle_box'] = {
		label = 'Box recycle',
		weight = 500,
		stack = true,
		close = false,
		description = 'Box recycle untuk menampung barang-barang yang bisa didaur ulang',
		client = {
			image = 'recycle_box.png',
		}
	},

	['recycle_package'] = {
		label = 'Package recycle',
		weight = 400,
		stack = true,
		close = false,
		description = 'Package recycle untuk menampung barang-barang yang bisa didaur ulang',
		client = {
			image = 'recycle_package.png',
		}
	},

	-- CHICKEN ITEMS
	['alivechicken'] = {
		label = 'Alive Chicken',
		weight = 500,
		stack = true,
		close = false,
		description = 'A live chicken ready for processing',
		image = 'alivechicken.png'
	},

	['slaughteredchicken'] = {
		label = 'Slaughtered Chicken',
		weight = 500,
		stack = true,
		close = false,
		description = 'A slaughtered chicken ready for packaging',
		image = 'slaughteredchicken.png'
	},

	['packagedchicken'] = {
		label = 'Packaged Chicken',
		weight = 500,
		stack = true,
		close = false,
		description = 'Packaged chicken ready for sale',
		image = 'packagedchicken.png'
	},

	-- COW/DAIRY ITEMS
	['rawmilk'] = {
		label = 'Raw Milk',
		weight = 300,
		stack = true,
		close = false,
		description = 'Fresh raw milk from cow',
		image = 'rawmilk.png'
	},

	['processedmilk'] = {
		label = 'Processed Milk',
		weight = 250,
		stack = true,
		close = false,
		description = 'Processed milk ready for packaging',
		image = 'processedmilk.png'
	},

	['packagedmilk'] = {
		label = 'Packaged Milk',
		weight = 200,
		stack = true,
		close = false,
		description = 'Packaged milk ready for sale',
		image = 'packagedmilk.png'
	},

	['rawbeef'] = {
		label = 'Raw Beef',
		weight = 800,
		stack = true,
		close = false,
		description = 'Fresh raw beef from cow',
		image = 'rawbeef.png'
	},

	['processedbeef'] = {
		label = 'Processed Beef',
		weight = 600,
		stack = true,
		close = false,
		description = 'Processed beef ready for packaging',
		image = 'processedbeef.png'
	},

	['packagedbeef'] = {
		label = 'Packaged Beef',
		weight = 400,
		stack = true,
		close = false,
		description = 'Packaged beef ready for sale',
		image = 'packagedbeef.png'
	},

	['corn_seed'] = {
		label = 'Biji Jagung',
		weight = 1,
		stack = true,
		close = true,
		description = "This is a seed that grows corn."
	},

	['corn_raw'] = {
		label = 'Raw Corn',
		weight = 1,
		stack = true,
		close = true,
		description = "You will need to process this."
	},

	['corn'] = {
		label = 'Corn',
		weight = 100,
		stack = true,
		close = true,
	},

	['tomato_seed'] = {
		label = 'Biji Tomat',
		weight = 1,
		stack = true,
		close = true,
		description = "This is a seed that grows a tomato."
	},

	['tomato_raw'] = {
		label = 'Raw Tomato',
		weight = 1,
		stack = true,
		close = true,
		description = "You will need to process this."
	},

	['tomato'] = {
		label = 'Tomat',
		weight = 100,
		stack = true,
		close = true,
	},

	['wheat_seed'] = {
		label = 'Benih Padi',
		weight = 1,
		stack = true,
		close = true,
		description = "This is a seed that grows Wheat."
	},

	['wheat_raw'] = {
		label = 'Raw Wheat',
		weight = 1,
		stack = true,
		close = true,
		description = "You will need to process this."
	},

	['wheat'] = {
		label = 'Beras',
		weight = 100,
		stack = true,
		close = true,
	},

	['broccoli_seed'] = {
		label = 'Broccoli Seed',
		weight = 1,
		stack = true,
		close = true,
		description = "This is a seed that grows broccoli."
	},

	['broccoli_raw'] = {
		label = 'Raw Broccoli',
		weight = 1,
		stack = true,
		close = true,
		description = "You will need to process this."
	},

	['broccoli'] = {
		label = 'Broccoli',
		weight = 1,
		stack = true,
		close = true,
	},

	['orange_seed'] = {
		label = 'Biji Jeruk',
		weight = 1,
		stack = true,
		close = true,
		description = "This is a seed that grows a orange."
	},

	['chili_seed'] = {
		label = 'Biji Cabai',
		weight = 1,
		stack = true,
		close = true,
		description = "This is a seed that grows a chili."
	},

	['chili'] = {
		label = 'Cabai',
		weight = 100,
		stack = true,
		close = true,
	},

	['carrot_seed'] = {
		label = 'Biji Wortel',
		weight = 1,
		stack = true,
		close = true,
		description = "This is a seed that grows a carrot."
	},

	['carrot_raw'] = {
		label = 'Raw Carrot',
		weight = 1,
		stack = true,
		close = true,
		description = "You will need to process this."
	},

	['carrot'] = {
		label = 'Wortel',
		weight = 100,
		stack = true,
		close = true,
	},

	['potato_seed'] = {
		label = 'Potato Seed',
		weight = 1,
		stack = true,
		close = true,
		description = "This is a seed that grows a potato."
	},

	['potato_raw'] = {
		label = 'Raw Potato',
		weight = 1,
		stack = true,
		close = true,
		description = "You will need to process this."
	},

	['potato'] = {
		label = 'Potato',
		weight = 1,
		stack = true,
		close = true,
	},

	['pickle_seed'] = {
		label = 'Pickle Seed',
		weight = 1,
		stack = true,
		close = true,
		description = "This is a seed that grows a pickle."
	},

	['pickle_raw'] = {
		label = 'Raw Pickle',
		weight = 1,
		stack = true,
		close = true,
		description = "You will need to process this."
	},

	['pickle'] = {
		label = 'Pickle',
		weight = 1,
		stack = true,
		close = true,
	},

	['weed_seed'] = {
		label = 'Weed Seed',
		weight = 1,
		stack = true,
		close = true,
		description = "This is a seed that grows weed."
	},

	['weed_raw'] = {
		label = 'Raw Weed',
		weight = 1,
		stack = true,
		close = true,
		description = "You will need to process this."
	},

	['weed'] = {
		label = 'Weed',
		weight = 1,
		stack = true,
		close = true,
	},

	['cocaine_seed'] = {
		label = 'Cocaine Seed',
		weight = 1,
		stack = true,
		close = true,
		description = "This is a seed that grows cocaine."
	},

	['cocaine_raw'] = {
		label = 'Raw Cocaine',
		weight = 1,
		stack = true,
		close = true,
		description = "You will need to process this."
	},

	['heroin_seed'] = {
		label = 'Heroin Seed',
		weight = 1,
		stack = true,
		close = true,
		description = "This is a seed that grows heroin."
	},

	['heroin_raw'] = {
		label = 'Raw Heroin',
		weight = 1,
		stack = true,
		close = true,
		description = "You will need to process this."
	},

	['heroin'] = {
		label = 'Heroin',
		weight = 1,
		stack = true,
		close = true,
	},

	['garden_pitcher'] = {
		label = 'Garden Pitcher',
		weight = 1,
		stack = true,
		close = true,
	},

	['watering_can'] = {
		label = 'Watering Can',
		weight = 500,
		stack = false,
		close = true,
		description = 'A watering can for plants'
	},

	['garden_shovel'] = {
		label = 'Garden Shovel',
		weight = 1000,
		stack = true,
		close = true,
		description = 'A shovel for harvesting plants'
	},

	['fertilizer'] = {
		label = 'Fertilizer',
		weight = 200,
		stack = true,
		close = true,
		description = 'Plant fertilizer for better growth'
	},

	['gym_membershipcard'] = {
		label = 'Gym Membership Card',
		weight = 100,
		stack = false,
		close = true,
		description = 'Membership card for gym',
		metadata = {'name', 'birthdate', 'expires', 'type'}
	},

	['megaphone'] = {
		label = 'Megaphone',
		weight = 1,
		stack = true,
		close = true,
		description = nil
	},
	['microphone'] = {
		label = 'Microphone',
		weight = 1,
		degrade = 10080,
		stack = true,
		close = true,
		description = nil
	},

	["tablet"] = {
		label = "Tablet",
		weight = 840,
		stack = false,
		consume = 0,
		client = {
			event = "tablet:toggleOpen"
		}
	},

	-- ["tablet_media"] = {
	-- 	label = "Tablet Media",
	-- 	weight = 840,
	-- 	degrade = 10080,
	-- 	stack = true,
	-- 	close = true,
	-- 	description = 'Tablet Satu Media',
	-- },

	['backpack'] = {
		label = 'Backpack',
		stack = false,
		weight = 10,
		rarity = 'mythical',
		client = {
			image = 'backpack.png'
		},
	},

	['backpackstandar'] = {
		label = 'Backpack Standar',
		stack = false,
		weight = 10,
		rarity = 'common',
		client = {
			image = 'backpackstandar.png'
		},
	},

	['backpackdewa'] = {
		label = 'Backpack Dewa',
		stack = false,
		weight = 10,
		rarity = 'divine',
	},

	['powerbank'] = {
        label = 'Power Bank',
        weight = 350,
        stack = true,
        close = true,
        description = 'A Power Bank, that will recharge your phone!',
        consume = 0.50,
    },

	["crutch"] = {
		label = "Crutch",
		weight = 10,
		stack = true,
		close = true,
		description = "",
		client = {
			image = "crutch.png",
		}
	},

	["wheelchair"] = {
		label = "wheelchair",
		weight = 10,
		stack = true,
		close = true,
		description = "",
		client = {
			image = "wheelchair.png",
		}
	},

	--items

	["susukotak"] = {
		label = "Susu Kotak",
		weight = 10,
		stack = true,
		rarity = 'rare',
		description = "minuman Enak",
	},

	["tespek"] = {
		label = "Tespek",
		weight = 10,
		stack = true,
		degrade = 4320,
		rarity = 'rare',
		description = "Alat untuk mengetahui kehamilan",
	},

	["dipurine"] = {
		label = "Dipstick Tes Urine",
		weight = 10,
		stack = true,
		degrade = 4320,
		rarity = 'rare',
		description = "Alat Test Urine",
	},

	["vitaminec"] = {
		label = "Vitamin C",
		weight = 10,
		stack = true,
		degrade = 4320,
		rarity = 'rare',
		description = "Vitamin C",
	},

	["ondansetron"] = {
		label = "Ondansetron",
		weight = 10,
		stack = true,
		degrade = 4320,
		rarity = 'rare',
		description = "Mengurangi Stress",
	},

	["pregnanmilk"] = {
		label = "Pregnanmilk",
		weight = 10,
		stack = true,
		degrade = 4320,
		rarity = 'rare',
		description = "Susu ibu hamil",
	},

	["medkit"] = {
		label = "Medkit",
		weight = 10,
		stack = true,
		close = true,
		description = "Medkit RS Roxwood",
	},

	['perbanelastis'] = {
		label = 'Perban Elastis',
		weight = 10,
		stack = true,
		close = true,
		degrade = 4320,
		description = "menyembuhkan luka",
		allowArmed = true
	},

	["ibuprofen"] = {
		label = "Ibuprofen",
		weight = 10,
		stack = true,
		close = true,
		degrade = 2880,
		description = "menghilangkan stress",
		allowArmed = true
	},


	--boombox
	['boombox_white_large'] = {
    label = 'Large Boombox (White)',
    weight = 160,
	},
	['boombox_red_large'] = {
		label = 'Large Boombox (Red)',
		weight = 160,
	},
	['boombox_purple_large'] = {
		label = 'Large Boombox (Purple)',
		weight = 160,
	},
	['boombox_pink_large'] = {
		label = 'Large Boombox (Pink)',
		weight = 160,
	},
	['boombox_orange_large'] = {
		label = 'Large Boombox (Orange)',
		weight = 160,
	},
	['boombox_green_large'] = {
		label = 'Large Boombox (Green)',
		weight = 160,
	},
	['boombox_blue_large'] = {
		label = 'Large Boombox (Blue)',
		weight = 160,
	},

	['boombox_white_medium'] = {
		label = 'Medium Boombox (White)',
		weight = 160,
	},
	['boombox_red_medium'] = {
		label = 'Medium Boombox (Red)',
		weight = 160,
	},
	['boombox_purple_medium'] = {
		label = 'Medium Boombox (Purple)',
		weight = 160,
	},
	['boombox_pink_medium'] = {
		label = 'Medium Boombox (Pink)',
		weight = 160,
	},
	['boombox_orange_medium'] = {
		label = 'Medium Boombox (Orange)',
		weight = 160,
	},
	['boombox_green_medium'] = {
		label = 'Medium Boombox (Green)',
		weight = 160,
	},
	['boombox_blue_medium'] = {
		label = 'Medium Boombox (Blue)',
		weight = 160,
	},

	['boombox_white_small'] = {
		label = 'Small Boombox (White)',
		weight = 160,
	},
	['boombox_red_small'] = {
		label = 'Small Boombox (Red)',
		weight = 160,
	},
	['boombox_purple_small'] = {
		label = 'Small Boombox (Purple)',
		weight = 160,
	},
	['boombox_pink_small'] = {
		label = 'Small Boombox (Pink)',
		weight = 160,
	},
	['boombox_orange_small'] = {
		label = 'Small Boombox (Orange)',
		weight = 160,
	},
	['boombox_green_small'] = {
		label = 'Small Boombox (Green)',
		weight = 160,
	},
	['boombox_blue_small'] = {
		label = 'Small Boombox (Blue)',
		weight = 160,
	},
	--atmrobbery
	['rope'] = {
		label = 'Rope',
		weight = 160,
		client = {
			event = 'sm_atmrobbery:useRope'
		}
	},

	['atm1'] = {
		label = 'ATM',
		weight = 10000,
		stack = false,
		close = true,
	},

	['atm2'] = {
		label = 'ATM',
		weight = 10000,
		stack = false,
		close = true,
	},

	['atm3'] = {
		label = 'ATM',
		weight = 10000,
		stack = false,
		close = true,
	},

	--houserobbery
	["microwave"]                     = {
		label = "Microwave",
		weight = 1000,
		stack = false,
		close = true,
		description = "microwave",
		client = {
			image = "microwave.png",
		}
	},
	["small_tv"]                     = {
		label = "Tv Kecil",
		weight = 1000,
		stack = false,
		close = true,
		description = "TV",
		client = {
			image = "small_tv.png",
		}
	},

	["old_tv"]                       = {
		label = "TV Jadul",
		weight = 1000,
		stack = false,
		close = true,
		description = "TV",
		client = {
			image = "old_tv.png",
		}
	},

	["tv"]                           = {
		label = "TV Modern",
		weight = 1000,
		stack = false,
		close = true,
		description = "TV",
		client = {
			image = "tv.png",
		}
	},

	["old_phone"]                    = {
		label = "old phone",
		weight = 100,
		stack = false,
		close = true,
		description = "Old phone",
		client = {
			image = "old_phone.png",
		}
	},

	["kettle"]                       = {
		label = "Kettle",
		weight = 100,
		stack = false,
		close = true,
		description = "Kettle",
		client = {
			image = "kettle.png",
		}
	},

	["coffee_machine"]               = {
		label = "Coffee Machine",
		weight = 100,
		stack = false,
		close = true,
		description = "Coffee Machine",
		client = {
			image = "coffee_machine.png",
		}
	},

	["tape_player"]                  = {
		label = "Tape",
		weight = 100,
		stack = false,
		close = true,
		description = "Tape",
		client = {
			image = "tape_player.png",
		}
	},

	["telescope"]                    = {
		label = "Telescope",
		weight = 100,
		stack = false,
		close = true,
		description = "Telescope",
		client = {
			image = "telescope.png",
		}
	},

	["toaster"]                      = {
		label = "Toaster",
		weight = 100,
		stack = false,
		close = true,
		description = "Toast",
		client = {
			image = "toaster.png",
		}
	},

	["monitor"]                      = {
		label = "Monitor",
		weight = 1000,
		stack = true,
		close = true,
		description = "Monitor",
		client = {
			image = "monitor.png",
		}
	},

	["printer"]                      = {
		label = "printer",
		weight = 100,
		stack = true,
		close = true,
		description = "printer",
		client = {
			image = "printer.png",
		}
	},

	["golfbag"]                      = {
		label = "golf",
		weight = 100,
		stack = true,
		close = true,
		description = "golf",
		client = {
			image = "golfbag.png",
		}
	},

	--jewelry

	['cutter'] = {
		label = 'Cutting Machine',
		weight = 0,
        degrade = 10080,
		stack = true,
		close = true,
		description = '',
		client = {
			image = 'cutter.png'
		}
	},

	['paintingg'] = {
		label = 'Vintage Painting',
		weight = 0,
		stack = true,
		close = true,
		description = '',
		client = {
			image = 'paintingg.png'
		}
	},

	['panther'] = {
		label = 'Vintage Panther',
		weight = 0,
		stack = true,
		close = true,
		description = '',
		client = {
			image = 'panther.png'
		}
	},

	['necklace'] = {
		label = 'Diamond Necklace',
		weight = 0,
		stack = true,
		close = true,
		description = '',
		client = {
			image = 'necklace.png'
		}
	},

	['bottle'] = {
		label = 'Bottle',
		weight = 0,
		stack = true,
		close = true,
		description = '',
		client = {
			image = 'bottle.png'
		}
	},

	-- ['racingtablet'] = {
	-- 	label = 'Racing tablet',
	-- 	weight = 500,
	-- 	description = 'Seems like something to do with cars.',
	-- 	stack = false,
	-- 	client = {
	-- 		export = 'rahe-racing.racingtablet',
	-- 	}
	-- },

	["racing_tablet"] = {
		label = "Tablet",
		weight = 500,
		stack = false,
		close = true,
		degrade = 20160,
		-- client = {
		-- 	image = "racing_tablet.png",
		-- 	export = "nx_racing.openTablet"
		-- }
	},

	["pdtablet"] = {
		label = "PD Pursuit Tablet",
		weight = 500,
		stack = false,
		close = true,
		description = "Pursuit Training Tablet",
	},

	-- ["triathlon_tablet"] = {
	-- 	label = "Tablet Triathlon",
	-- 	weight = 500,
	-- 	stack = false,
	-- 	close = true,
	-- 	degrade = 1440,
	-- 	description = "Tablet Event Triathlon Kemerdekaan - Satu Mimpi Merdeka",
	-- },

	["race_access"] = {
		label = "Race Access Pass",
		weight = 100,
		stack = false,
		close = true,
		degrade = 1440,
		decay = true,
		description = "Kartu akses untuk masuk area balapan privat",
	},

	["tire"] = {
		label = "Ban",
		weight = 500,
		stack = true,
		close = true,
		description = "Part kendaraan",
	},

	["spring"] = {
		label = "Spring",
		weight = 300,
		stack = true,
		close = true,
		description = "Part kendaraan",
	},

	["engine"] = {
		label = "Mesin",
		weight = 1000,
		stack = true,
		close = true,
		description = "Part kendaraan",
	},

	["bodypart"] = {
		label = "Body Kendaraan",
		weight = 1000,
		stack = true,
		close = true,
		description = "Part kendaraan",
	},

	-- Fashion props (jarp_*)
	['jarp_nezuko'] = { label='Nezuko Fashion', weight=0, stack=false, close=true, consume=0,
	client = { event = 'jarp_nezuko:SPAWN' } },

	['jarp_zenitsu'] = { label='Zenitsu Fashion', weight=0, stack=false, close=true, consume=0,
	client = { event = 'jarp_zenitsu:SPAWN' } },

	['jarp_rengoku'] = { label='Rengoku Fashion', weight=0, stack=false, close=true, consume=0,
	client = { event = 'jarp_rengoku:SPAWN' } },

	['jarp_tanjiro'] = { label='Tanjiro Fashion', weight=0, stack=false, close=true, consume=0,
	client = { event = 'jarp_tanjiro:SPAWN' } },

	['jarp_inosuke'] = { label='Inosuke Fashion', weight=0, stack=false, close=true, consume=0,
	client = { event = 'jarp_inosuke:SPAWN' } },

	["printerdocument"] = {
		label = "Document",
		weight = 10,
		stack = true,
		close = true,
		description = "A printed document",
		client = {
			image = "printerdocument.png",
			export = "sm_printer.printerdocument"
    	}
	},

	["printerink"] = {
		label = "Ink Cartridge",
		weight = 200,
		stack = true,
		close = false,
		description = "Ink for printing",
	},

	["printerpaper"] = {
		label = "Blank Printer Paper",
		weight = 10,
		stack = true,
		close = false,
		description = "Blank paper for printing",
	},

	--drugs
	["packaged_meth"] = {
		label = "Paket Meth",
		weight = 200,
		stack = true,
		close = true,
		description = "paket processing narkotika",
	},
	["packaged_ganja"] = {
		label = "Paket Ganja",
		weight = 200,
		stack = true,
		close = true,
		description = "paket processing narkotika",
	},
	["packaged_cocaine"] = {
		label = "Paket Cocaine",
		weight = 200,
		stack = true,
		close = true,
		description = "paket processing narkotika",
	},
	["blue_paradise_package"] = {
		label = "Paket Blue Paradise",
		weight = 100,
		stack = true,
		close = true,
		description = "paket processing narkotika",
	},
	["k2_package"] = {
		label = "Paket K2",
		weight = 100,
		stack = true,
		close = true,
		description = "paket processing narkotika",
	},
	["crystalmeth"] = {
		label = "Crystal Meth",
		weight = 250,
		stack = true,
		close = true,
		description = "Crystal meth",
	},
	["meth"] = {
		label = "Meth",
		weight = 250,
		stack = true,
		close = true,
		description = "Methamine",
		allowArmed = true
	},
	["ganja"] = {
		label = "Ganja",
		weight = 100,
		stack = true,
		close = true,
		description = "Ganja",
		allowArmed = true
	},
	["daunkokain"] = {
		label = "Daun Kokain",
		weight = 100,
		stack = true,
		close = true,
		description = "Daun Kokain",
	},
	["cocaine"] = {
		label = "Kokain",
		weight = 250,
		stack = true,
		close = true,
		description = "Kokain",
		allowArmed = true
	},

	["spk_kendaraan"] = {
		label = "SPK Kendaraan",
		weight = 100,
		stack = false,
		close = true,
		description = "SPK Pabrik",
	},

	['brake_parts'] = {
		label = 'Brake Parts',
		weight = 350,
		stack = true,
		close = true,
		description = 'Kampas dan cakram rem pengganti. Dipakai mekanik untuk mengembalikan kondisi rem kendaraan.',
	},

	['clutch_parts'] = {
		label = 'Clutch Parts',
		weight = 350,
		stack = true,
		close = true,
		description = 'Set kampas kopling pengganti. Dipakai mekanik untuk mengembalikan akselerasi kendaraan.',
	},

	['engine_parts'] = {
		label = 'Engine Parts',
		weight = 350,
		stack = true,
		close = true,
		description = 'Komponen internal mesin pengganti. Dipakai mekanik untuk mengembalikan top speed kendaraan.',
	},

	['body_parts'] = {
		label = 'Body Parts',
		weight = 350,
		stack = true,
		close = true,
		description = 'Panel bodi pengganti. Dipakai mekanik untuk mengembalikan ketahanan bodi kendaraan.',
	},

	['bodykit'] = {
		label = 'Body Repair Kit',
		weight = 1000,
		stack = true,
		close = true,
		description = 'Kit untuk memperbaiki kerusakan visual/body kendaraan. Dapat mengembalikan kondisi body seperti baru.',
		client = {
			image = 'bodykit.png',
			}
	},

	['enginekit'] = {
		label = 'Engine Repair Kit',
		weight = 800,
		stack = true,
		close = true,
		description = 'Kit darurat untuk perbaikan mesin. Dapat meningkatkan kesehatan mesin',
		client = {
			image = 'enginekit.png',
		}
	},

    ["badgehighcommandusms"] = {
		label = "Badge High Command",
		weight = 200,
		stack = true,
		close = false,
		description = "Badge High Command US Marshal",
		client = {
			image = 'badgeusmarshal.png',
		}
	},

    ["badgeftfusmsnew"] = {
		label = "Badge FTF",
		weight = 200,
		stack = true,
		close = false,
		description = "Badge Fugitve Task Force US Marshal",
		client = {
			image = 'badgeusmarshal.png',
		}
	},

	["badgeiodusms"] = {
		label = "Badge IOD",
		weight = 200,
		stack = true,
		close = false,
		description = "Badge Investigated Operation Division US Marshal",
        client = {
			image = 'badgeusmarshal.png',
		}
	},

    ["badgeheliusms"] = {
		label = "Badge Helicopter",
		weight = 200,
		stack = true,
		close = false,
		description = "Badge Helicopter US Marshal",
		client = {
			image = 'badgeusmarshal.png',
		}
	},

	["badgevehusmsnew"] = {
		label = "Badge Vehicle",
		weight = 200,
		stack = true,
		close = false,
		description = "Badge Vehicle US Marshal",
		client = {
			image = 'badgeusmarshal.png',
		}
	},

	["shield"] = {
		label = "Riot Shield",
		weight = 3000,
		stack = false,
		close = true,
		description = "Riot shield US Marshal",
	},

	["badgeswatlspd"] = {
		label = "Badge S.W.A.T",
		weight = 200,
		stack = true,
		close = false,
		description = "Badge akses Attachment, Senjata Class 2-4, dan Utility",
		client = {
			image = 'badgepolice.png',
		}
	},

	["roxwoodcard"] = {
		label = "Roxwood Card",
		weight = 200,
		stack = true,
		close = false,
		description = "Roxwood Card",
	},

	["badgedetective"] = {
		label = "Badge Detective",
		weight = 200,
		stack = true,
		close = false,
		description = "Badge akses Attachment dan menghilangkan Blips",
		client = {
			image = 'badgepolice.png',
		}
	},

	["badgehelicopter"] = {
		label = "Badge Helicopter",
		weight = 200,
		stack = true,
		close = false,
		description = "Badge akses Helicopter",
		client = {
			image = 'badgepolice.png',
		}
	},
	["badgearmy"] = {
		label = "Badge Army",
		weight = 200,
		stack = true,
		close = false,
		description = "Badge akses army",
		client = {
			image = 'badgepolice.png',
		}
	},
	["badgeinterceptor"] = {
		label = "Badge Interceptor",
		weight = 200,
		stack = true,
		close = false,
		description = "Badge akses Interceptor (npolstang, npolchal, npolchar, npolvette)",
		client = {
			image = 'badgepolice.png',
		}
	},

	["badgepolantas"] = {
		label = "Badge Polantas",
		weight = 200,
		stack = true,
		close = false,
		description = "Badge akses kepolisian",
		client = {
			image = 'badgepolice.png',
		}
	},

	["badgesabhara"] = {
		label = "Badge Sabhara",
		weight = 200,
		stack = true,
		close = false,
		description = "Badge akses kepolisian",
		client = {
			image = 'badgepolice.png',
		}
	},

	["badgereskrim"] = {
		label = "Badge Reskrim",
		weight = 200,
		stack = true,
		close = false,
		description = "Badge akses kepolisian",
		client = {
			image = 'badgepolice.png',
		}
	},

	["badgeintelkam"] = {
		label = "Badge Intelkam",
		weight = 200,
		stack = true,
		close = false,
		description = "Badge akses kepolisian",
		client = {
			image = 'badgepolice.png',
		}
	},

	["badgebrimob"] = {
		label = "Badge Brimob",
		weight = 200,
		stack = true,
		close = false,
		description = "Badge akses kepolisian",
		client = {
			image = 'badgepolice.png',
		}
	},

	["badgemobrig"] = {
		label = "Badge Mobrig",
		weight = 200,
		stack = true,
		close = false,
		description = "Badge akses kepolisian",
		client = {
			image = 'badgepolice.png',
		}
	},
	["badgekorlantas"] = {
		label = "Badge Korlantas",
		weight = 200,
		stack = true,
		close = false,
		description = "Badge akses kepolisian",
		client = {
			image = 'badgepolice.png',
		}
	},
	["badgeresintel"] = {
		label = "Badge Resintel",
		weight = 200,
		stack = true,
		close = false,
		description = "Badge akses kepolisian",
		client = {
			image = 'badgepolice.png',
		}
	},
	["badgeshc"] = {
		label = "Badge Senior High Command",
		weight = 200,
		stack = true,
		close = false,
		description = "Badge akses penuh (semua akses badge di bawahnya)",
		client = {
			image = 'badgepolice.png',
		}
	},

	["badgeiaf"] = {
		label = "Badge Internal Affairs",
		weight = 200,
		stack = true,
		close = false,
		description = "Badge akses Evidence Locker",
		client = {
			image = 'badgepolice.png',
		}
	},
	["badgepropam"] = {
		label = "Badge Propam",
		weight = 200,
		stack = true,
		close = false,
		description = "Badge akses kepolisian",
		client = {
			image = 'badgepolice.png',
		}
	},
	["badgespecial"] = {
		label = "Badge Special",
		weight = 200,
		stack = true,
		close = false,
		description = "Badge akses kepolisian",
		client = {
			image = 'badgepolice.png',
		}
	},
	["badgehsu"] = {
		label = "Badge High Speed Unit",
		weight = 200,
		stack = true,
		close = false,
		description = "Badge akses kepolisian",
		client = {
			image = 'badgepolice.png',
		}
	},
	["badgepolairut"] = {
		label = "Badge Polairut",
		weight = 200,
		stack = true,
		close = false,
		description = "Badge akses kepolisian",
		client = {
			image = 'badgepolice.png',
		}
	},
	["badgepaspampres"] = {
		label = "Badge Paspampres",
		weight = 200,
		stack = true,
		close = false,
		description = "Badge akses paspampres",
		client = {
			image = 'badgepaspampres.png',
		}
	},
	["bahan_tas"] = {
		label = "Bahan Tas",
		weight = 100,
		stack = true,
		close = false,
		description = "Bahan dasar untuk membuat tas",
	},
	["patchwork"] = {
		label = "Patchwork Tas",
		weight = 100,
		stack = true,
		close = false,
		description = "Jahitan untuk memperkuat tas",
	},
	["kerangka_tas"] = {
		label = "Kerangka Tas",
		weight = 100,
		stack = true,
		close = false,
		description = "Struktur dasar tas",
	},
	["aksesoris_tas"] = {
		label = "Aksesoris Tas",
		weight = 100,
		stack = true,
		close = false,
		description = "Aksesoris pelengkap tas",
	},
	["pelumas_tas"] = {
		label = "Pelumas Tas",
		weight = 100,
		stack = true,
		close = false,
		description = "Pelumas untuk resleting dan aksesoris",
	},
	["skwb"] = {
		label = "SURAT KETERANGAN WARGA BARU",
		weight = 100,
		degrade = 10080,
		-- degrade = 1,
		stack = false,
		close = false,
		description = "Surat keterangan untuk warga baru",
	},
	['multivitamin'] = {
		label = 'Multivitamin',
		weight = 10,
		consume = 0,
		description = "Menjaga kesehatan tubuh & menghilangkan stress",
	},
	['paracetamol'] = {
		label = 'Paracetamol',
		weight = 10,
		stack = true,
		close = true,
		degrade = 4320,
		allowArmed = true,
		description = "menghilangkan stress",
	},
	['obat_custom'] = {
		label = 'Obat Racikan',
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Obat racikan, mengurangi stress",
	},
	['perban_anak'] = {
		label = 'Perban Anak',
		weight = 10,
		stack = true,
		close = true,
		degrade = 4320,
		description = "mengobati luka ringan",
	},
	['paracetamol_syrup'] = {
		label = 'Paracetamol Syrup',
		weight = 10,
		stack = true,
		close = true,
		degrade = 4320,
		description = "menghilangkan stress untuk anak-anak",
	},
	['voucher_ratnan'] = {
		label = 'Voucher Rata Kanan',
		weight = 1,
		degrade = 15000,
		stack = false,
		close = true,
		description = "max performance kendaraan"
	},

	['kuponsr'] = {
		label = 'Kupon Sumber Rezeki',
		weight = 1,
		stack = true,
		close = true,
		description = "Kupon Sumber Rezeki"
	},

    ['voucher_donasi20'] = {
		label = 'Voucher Donasi 20%',
		weight = 1,
		degrade = 10080,
		stack = true,
		close = true,
		description = "Voucher untuk donasi"
	},

	['kupon_pemerintah'] = {
		label = 'Kupon Pemerintah',
		weight = 1,
		stack = true,
		close = true,
		description = "Kupon Pemerintah"
	},

	['kupongacha'] = {
		label = 'Kupon Gacha',
		weight = 1,
		stack = true,
		close = true,
		description = "Kupon untuk mendapatkan item acak"
	},

	['box_kompensasi'] = {
		label = 'Box Kompensasi',
		weight = 100,
		stack = true,
		close = true,
		description = "Buka untuk spin Gacha Kompensasi"
	},

    -- ['box_merdeka'] = {
	-- 	label = 'Box Merdeka',
	-- 	weight = 200,
	-- 	stack = true,
	-- 	close = true,
	-- 	rarity = 'divine',
	-- 	description = "Buka untuk spin Gacha Merdeka"
	-- },

    ['nk_propgacha_mn1'] = {
		label = 'Minion Bob',
		weight = 200,
		stack = true,
		close = true,
		rarity = 'divine',
		description = 'Prop Gacha Exclusive Event 17'
	},

    ['nk_propgacha_mn2'] = {
		label = 'Minion Stuart',
		weight = 200,
		stack = true,
		close = true,
        rarity = 'legendary',
		description = 'Prop Gacha Exclusive Event 17'
	},

    ['nk_propgacha_mn3'] = {
		label = 'Minion Kevin',
		weight = 200,
		stack = true,
		close = true,
		rarity = 'mythical',
		description = 'Prop Gacha Exclusive Event 17'
	},

    ['nk_propgacha_lf'] = {
		label = 'Kimbi',
		weight = 200,
		stack = true,
		close = true,
		rarity = 'rare',
		description = 'Prop Gacha Exclusive Event 17'
	},

    ['nk_propgacha_nf'] = {
		label = 'Kimba',
		weight = 200,
		stack = true,
		close = true,
        rarity = 'common',
		description = 'Prop Gacha Exclusive Event 17'
	},

	['notepad'] = {
		label = 'Notepad',
		weight = 200,
		close = true,
		stack = false,
		client = {
			export = 'sm_notepad.openNotepad'
		}
	},

	['kartu_vii'] = {
		label = 'Kartu VII',
		weight = 1,
		stack = true,
		close = true,
		description = "Kartu VII"
	},

	['kupongacha_casino'] = {
		label = 'Kupon Gacha Casino',
		weight = 1,
		stack = true,
		close = true,
		description = "Kupon untuk mendapatkan item acak",
		client = {
			image = "kupongacha.png",
		}
	},

	['voucher_diskon_casino'] = {
		label = '50% Voucher Diskon Casino',
		weight = 1,
		stack = true,
		close = true,
		description = "Voucher diskon untuk pembelian chip di casino"
	},
	['voucher_kendaraan_casino'] = {
		label = 'Voucher Kendaraan Casino',
		weight = 1,
		stack = true,
		close = true,
		description = "Tukarkan voucher kepada petugas casino untuk mendapatkan kendaraan eksklusif"
	},

	['voucher_plat'] = {
		label = 'Voucher Custom Plat',
		weight = 1,
		degrade = 15000,
		stack = false,
		close = true,
		description = "ganti plat kendaraan"
	},

	['voucher_pass'] = {
		label = 'Voucher SatuMimpi Pass',
		weight = 1,
		degrade = 15000,
		stack = false,
		close = true,
		description = "aktifkan battlepass"

	},

	-- ['voucher_vip'] = {
	-- 	label = 'Voucher VIP',
	-- 	weight = 1,
	-- 	degrade = 15000,
	-- 	stack = false,
	-- 	close = true,
	-- 	description = "aktifkan sistem vip"
	-- },

	['voucher_vvip'] = {
		label = 'Voucher VVIP',
		weight = 1,
		degrade = 15000,
		stack = false,
		close = true,
		description = "aktifkan sistem vvip"
	},

	--resto
	['ikanteri'] = {
		label = 'Ikan Teri',
		weight = 100,
		stack = true,
		close = false,
		description = 'ikan Teri',
	},
	['brokoli'] = {
		label = 'Brokoli',
		weight = 100,
		stack = true,
		close = false,
		description = 'brokoli segar',
	},
	['apel'] = {
		label = 'Apel',
		weight = 100,
		stack = true,
		close = false,
		description = 'apel segar',
	},
	['timun'] = {
		label = 'Timun',
		weight = 100,
		stack = true,
		close = false,
		description = 'timun segar',
	},
	['telur'] = {
		label = 'Telur',
		weight = 100,
		stack = true,
		close = false,
		description = 'telur berkualitas',
	},
	['garam'] = {
		label = 'Garam',
		weight = 100,
		stack = true,
		close = false,
		description = 'garam dapur',
	},
	['minyak_goreng'] = {
		label = 'Minyak Goreng',
		weight = 100,
		stack = true,
		close = false,
		description = 'minyak goreng berkualitas',
	},
	['kelapa'] = {
		label = 'Kelapa',
		weight = 100,
		stack = true,
		close = false,
		description = 'kelapa segar',
	},
	['air'] = {
		label = 'Air',
		weight = 100,
		stack = true,
		close = false,
		description = 'air bersih',
	},
	['gula'] = {
		label = 'Gula',
		weight = 100,
		stack = true,
		close = false,
		description = 'gula pasir',
	},
	['esbatu'] = {
		label = 'Es Batu',
		weight = 100,
		stack = true,
		close = false,
		description = 'es batu dingin',
	},
	['tebu'] = {
		label = 'Tebu',
		weight = 100,
		stack = true,
		close = false,
		description = 'tebu segar',
	},
	['daun_bawang'] = {
		label = 'Daun Bawang',
		weight = 100,
		stack = true,
		close = false,
		description = 'daun bawang segar',
	},
	['bawang_seed'] = {
		label = 'Biji Bawang',
		weight = 1,
		stack = true,
		close = true,
		description = "This is a seed that grows a Onion."
	},
	['bawang'] = {
		label = 'Bawang',
		weight = 100,
		stack = true,
		close = false,
		description = 'bawang segar',
	},
	['tusuksate'] = {
		label = 'Tusuk Sate',
		weight = 100,
		stack = true,
		close = false,
		description = 'tusuk sate dari bambu',
	},
	['jeruk'] = {
		label = 'Jeruk',
		weight = 100,
		stack = true,
		close = false,
		description = 'Jeruk segar',
	},
	['radiator'] = {
		label = 'Radiator',
		weight = 100,
		stack = true,
		close = false,
		description = 'Radiator kendaraan',
	},
	["skateboard"] = {
		label = "skateboard",
		weight = 500,
		stack = false,
		close = true,
		description = "skateboard",
	},

	--bayik
	["salad_sayur"] = {
		label = "Salad Sayur",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "kids meal",
	},

	["yogurt"] = {
		label = "Yogurt",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "kids meal",
	},

	["mango_sticky_rice"] = {
		label = "Mango Sticky Rice",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "kids meal",
	},

	["king_mango_thai"] = {
		label = "King Mango Thai",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "kids meal",
	},

	["bento"] = {
		label = "Bento",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "kids meal",
	},

	["banana_milk"] = {
		label = "Banana Milk",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "kids meal",
	},

	["klepon"] = {
		label = "Klepon",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "kids meal",
	},

	["es_jelly_susu"] = {
		label = "Es Jelly Susu",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "kids meal",
	},

	["bubur_ayam"] = {
		label = "Bubur Ayam",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "kids meal",
	},

	["siomay_kidsmeal"] = {
		label = "Siomay",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "kids meal",
	},

	["strawberry_milktea"] = {
		label = "Strawberry Milk Tea",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "kids meal",
	},

	["esbuah_kidsmeal"] = {
		label = "Es Buah",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "kids meal",
	},

	['kol_selada'] = {
		label = 'Kol/Selada',
		weight = 100,
		stack = true,
		close = false,
		description = 'Kol atau selada segar',
	},

	['yogurt_plain'] = {
		label = 'Yogurt Plain',
		weight = 100,
		stack = true,
		close = false,
		description = 'Yogurt plain tanpa rasa',
	},

	['beras_ketan'] = {
		label = 'Beras Ketan',
		weight = 100,
		stack = true,
		close = false,
		description = 'Beras ketan untuk membuat makanan tradisional',
	},

	['santan'] = {
		label = 'Santan',
		weight = 100,
		stack = true,
		close = false,
		description = 'santan kelapa segar',
	},
	['mangga'] = {
		label = 'Mangga',
		weight = 100,
		stack = true,
		close = false,
		description = 'Mangga segar',
	},

	['pisang'] = {
		label = 'Pisang',
		weight = 100,
		stack = true,
		close = false,
		description = 'Pisang segar',
	},

	['buahpeach'] = {
		label = 'Peach',
		weight = 100,
		stack = true,
		close = false,
		description = 'Peach segar',
	},

	['kantongteh'] = {
		label = 'Kantong Teh',
		weight = 100,
		stack = true,
		close = false,
		description = 'Kantong Teh untuk menyeduh teh',
	},

	['susu_cair'] = {
		label = 'Susu Cair',
		weight = 100,
		stack = true,
		close = false,
		description = 'Susu cair segar',
	},

	['tepung_ketan'] = {
		label = 'Tepung Ketan',
		weight = 100,
		stack = true,
		close = false,
		description = 'Tepung ketan untuk membuat kue',
	},

	['kelapa_parut'] = {
		label = 'Kelapa Parut',
		weight = 100,
		stack = true,
		close = false,
		description = 'Kelapa parut segar',
	},

	['jelly'] = {
		label = 'Jelly',
		weight = 100,
		stack = true,
		close = false,
		description = 'Jelly manis',
	},

	["susu_bantal"] = {
		label = "Susu Bantal",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "Jajan anak-anak",
	},

	["ager_ager"] = {
		label = "Ager Ager",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "Jajan anak-anak",
	},

	--kkp
	['paket_chamanaodried'] = {
		label = 'Paket Chamanao',
		weight = 10,
		stack = true,
		close = true,
		description = 'Paket berisi makanan dan minuman',
		degrade = 2880, -- 2 hari
		client = {
			image = "paketbox.png",
			export = 'sm_resource_1.openPackage'
		}
	},
	["driedmango"] = {
		label = "Dried Mango",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "makanan khas kung kung kap",
	},
	["chamanao"] = {
		label = "Cha Manao",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "makanan khas kung kung kap",
	},
	["padthai"] = {
		label = "Pad Thai",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "makanan khas kung kung kap",
	},

	["somtam"] = {
		label = "Som Tam",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "makanan khas kung kung kap",
	},

	["goongten"] = {
		label = "Goong Ten",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "makanan khas kung kung kap",
	},

	["nampraotan"] = {
		label = "Nam Maprao Pan",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "minuman khas kung kung kap",
	},

    ['paket_kidsmeal_chickenkimpul'] = {
		label = 'Paket Kids Meal Chicken Kimpul',
		weight = 10,
		stack = true,
		close = true,
		description = 'Paket berisi makanan dan minuman',
		degrade = 2880,
		client = {
			image = "paketanaktom.png",
			export = 'sm_resource_1.openPackage',
		}
	},

    ["chickensteak"] = {
		label = "Chicken Steak Kimpul",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "makanan khas kung kung kap",
	},

    ["thaigreantea"] = {
		label = "Thai Green Tea",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "minuman khas kung kung kap",
	},

    kimpul = {
		label = 'Kimpul',
		weight = 100
	},

    chewycookie = {
		label = 'Chewy Cookie Kimpul',
		degrade = 4320,
		weight = 100,
		description = 'Makanan khas kkp'
	},

    icecreamatcha = {
		label = 'Ice Cream Matcha',
		degrade = 4320,
		weight = 100,
		description = 'Makanan khas kkp'
	},

	["tomyum"] = {
		label = "Tom Yum",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "makanan khas kung kung kap",
	},

	["thaitea"] = {
		label = "Thai Tea",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "minuman khas kung kung kap",
	},

	["nomyen"] = {
		label = "Nom Yen",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "minuman khas kung kung kap",
	},

	["oliang"] = {
		label = "O Liang",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "minuman khas kung kung kap",
	},

	--resto
	["gudeg"] = {
		label = "Gudeg",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "makanan khas resto",
	},
	["nasigorengkampung"] = {
		label = "Nasi Goreng Kampung",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "makanan khas resto",
	},
	["nasilemak"] = {
		label = "Nasi Uduk",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "makanan khas resto",
	},
	["bakso"] = {
		label = "Bakso",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "makanan khas resto",
	},
	["nasiliwet"] = {
		label = "Nasi Liwet",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "makanan khas resto",
	},
	["satemaranggi"] = {
		label = "Sate Maranggi",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "makanan khas resto",
	},
	["eskelapa"] = {
		label = "Es Kelapa",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "minuman khas resto",
	},
	["esjeruk"] = {
		label = "Es Jeruk",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "minuman khas resto",
	},
	["applejuice"] = {
		label = "Apple Juice",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "minuman khas resto",
	},
	["esteh"] = {
		label = "Es Teh Manis",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "minuman khas resto",
	},
	--ginzcafe
	['paket_merah_classic'] = {
		label = 'Paket Merah Classic',
		weight = 10,
		stack = true,
		close = true,
		description = 'Paket berisi makanan dan minuman',
		degrade = 2880, -- 2 hari
		client = {
			image = "paketbox.png",
			export = 'sm_resource_1.openPackage'
		}
	},
	['paket_lontong'] = {
		label = 'Paket Lontong Seger',
		weight = 10,
		stack = true,
		close = true,
		description = 'Paket berisi makanan dan minuman',
		degrade = 2880, -- 2 hari
		client = {
			image = "paketbox.png",
			export = 'sm_resource_1.openPackage'
		}
	},
	['paket_mie_nyemek'] = {
		label = 'Paket Mie Nyemek',
		weight = 10,
		stack = true,
		close = true,
		description = 'Paket berisi makanan dan minuman',
		degrade = 2880, -- 2 hari
		client = {
			image = "paketbox.png",
			export = 'sm_resource_1.openPackage'
		}
	},
	['paket_sweetsnack'] = {
		label = 'Paket Sweet Snack Combo',
		weight = 10,
		stack = true,
		close = true,
		description = 'Paket berisi makanan dan minuman',
		degrade = 2880, -- 2 hari
		client = {
			image = "paketbox.png",
			export = 'sm_resource_1.openPackage'
		}
	},
    ['paket_cumbak'] = {
		label = 'Paket Cumi Bakar & Soda Gembira',
		weight = 10,
		stack = true,
		close = true,
		description = 'Paket berisi makanan dan minuman',
		degrade = 2880, -- 2 hari
		client = {
			image = "paketbox.png",
			export = 'sm_resource_1.openPackage'
		}
	},
    ['paket_kidsmeal_kedaiygm'] = {
		label = 'Paket Kids Meal ECL Kedai',
		weight = 10,
		stack = true,
		close = true,
		description = 'Paket berisi makanan dan minuman',
		degrade = 2880, -- 2 hari
		client = {
			image = "kidsmealygm.png",
			export = 'sm_resource_1.openPackage'
		}
	},
    ["cumi_bakar"] = {
		label = "Cumi Bakar",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "makanan khas resto",
	},
    ["corndog"] = {
		label = "Corndog",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "makanan khas resto",
	},
    ["mini_pancake"] = {
		label = "Mini Pancake",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "makanan khas resto",
	},
    ["soda_gembira"] = {
		label = "Soda Gembira",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "minuman khas resto",
	},
    ["kelpshake_soda"] = {
		label = "Kelp Shake Soda",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "minuman khas resto",
	},
    cumi = {
		label = 'cumi',
		weight = 100
	},
    sosis = {
		label = 'Sosis',
		weight = 100
	},
    kecapmanis = {
		label = 'Kecap Manis',
		weight = 100,
        client = {
			image = "kecapikan.png",
		}
	},
    bubuk_kelpshake = {
		label = 'Bubuk Kelpshake',
		weight = 100
	},
	["nasigorengmerah"] = {
		label = "Nasi Goreng Merah",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "makanan khas resto",
	},
	["lontongbalap"] = {
		label = "Lontong Balap",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "makanan khas resto",
	},
	["mie_nyemek"] = {
		label = "Mie Nyemek",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "makanan khas resto",
	},
	["es_tebu"] = {
		label = "Es Tebu",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "minuman khas resto",
	},
	["esmilo"] = {
		label = "Es Milo",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "minuman khas resto",
	},
	["esdawet"] = {
		label = "Es Dawet",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "minuman khas resto",
	},
	["almondcrispy"] = {
		label = "Almond Crispy",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "makanan khas resto",
	},
	--mainsonreinhart
	["matchalattemh"] = {
		label = "Match Latte Matcha",
		weight = 10,
		stack = true,
		close = true,
		degrade = 4320,
		description = "minuman khas MR",
	},
	["peachtea"] = {
		label = "Peach Tea",
		weight = 10,
		stack = true,
		close = true,
		degrade = 4320,
		description = "minuman khas MR",
	},
	['paket_creamy'] = {
		label = 'Paket Creamy Sunset Pair',
		weight = 10,
		stack = true,
		close = true,
		description = 'Paket berisi makanan dan minuman',
		degrade = 2880, -- 2 hari
		client = {
			image = "paketbox.png",
			export = 'sm_resource_1.openPackage'
		}
	},
	['paket_oceanspice'] = {
		label = 'Paket Ocean Spice Pair',
		weight = 10,
		stack = true,
		close = true,
		description = 'Paket berisi makanan dan minuman',
		degrade = 2880, -- 2 hari
		client = {
			image = "paketbox.png",
			export = 'sm_resource_1.openPackage'
		}
	},
	['paket_freshtrop'] = {
		label = 'Paket Fresh Tropical Pair',
		weight = 10,
		stack = true,
		close = true,
		description = 'Paket berisi makanan dan minuman',
		degrade = 2880, -- 2 hari
		client = {
			image = "paketbox.png",
			export = 'sm_resource_1.openPackage'
		}
	},
	['paket_dessertcalm'] = {
		label = 'Paket Dessert Calm Pair',
		weight = 10,
		stack = true,
		close = true,
		description = 'Paket berisi makanan dan minuman',
		degrade = 2880, -- 2 hari
		client = {
			image = "paketbox.png",
			export = 'sm_resource_1.openPackage'
		}
	},
	['paket_manis'] = {
		label = 'Paket Manis 969Cafe',
		weight = 10,
		stack = true,
		close = true,
		description = 'Paket berisi makanan dan minuman',
		degrade = 2880, -- 2 hari
		client = {
			image = "paketbox.png",
			export = 'sm_resource_1.openPackage'
		}
	},
	["pastacreamychicken"] = {
		label = "Pasta Creamy Chicken",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "makanan khas resto",
	},
	["spicygrilledsalmon"] = {
		label = "Spicy Grilled Salmon",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "makanan khas resto",
	},
	["prawnsalad"] = {
		label = "Prawn Salad",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "makanan khas resto",
	},
	["tropicalorange"] = {
		label = "Tropical Orange",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "minuman khas resto",
	},
	["sweetcorncocktail"] = {
		label = "Sweet Corn Cocktail",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "minuman khas resto",
	},
	["tropicalmangobreeze"] = {
		label = "Tropical Mango Breeze",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "minuman khas resto",
	},
	["matchabruleecream"] = {
		label = "Matcha Cake",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "makanan khas resto",
	},
	["minichickensliders"] = {
		label = "Mini Chicken Sliders",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "makanan khas resto",
	},
	["blindfold"] = {
		label = "Blindfold",
		weight = 5,
		stack = true,
		close = true,
		description = "Blindfold untuk menutup mata",
	},
	["blueprint"] = {
		label = "Blueprint",
		weight = 100,
		stack = true,
		close = true,
		description = "blueprint",
	},
	["blackprint"] = {
		label = "Blackprint",
		weight = 100,
		stack = true,
		close = true,
		description = "blackprint",
	},
	["gunpowder"] = {
		label = "Gunpowder",
		weight = 100,
		stack = true,
		close = true,
		description = "bubuk mesiu",
	},
	["gunhandle"] = {
		label = "Gun Handle",
		weight = 100,
		stack = true,
		close = true,
		description = "Handle senjata",
	},
	["newspaper"] = {
		label = "Koran",
		weight = 100,
		degrade = 2880,
		stack = true,
		close = true,
		description = "Koran Satu Media",
	},
    ["kta_digitaldenroxwood"] = {
		label = "KTA-DigitalDen Roxwood",
		weight = 100,
		stack = false,
		close = true,
		description = "Kartu Tanda Anggota DigitalDen Roxwood",
	},
    ["kta_paud"] = {
		label = "KTA-School Kids",
		weight = 100,
		stack = false,
		close = true,
		description = "Kartu Tanda Anggota School Kids",
	},
    ["kta_smmotel"] = {
		label = "KTA-SM Motel",
		weight = 100,
		stack = false,
		close = true,
		description = "Kartu Tanda Anggota SM Motel",
	},
	["kta_wartel"] = {
		label = "KTA-Wartel",
		weight = 100,
		stack = false,
		close = true,
		description = "Kartu Tanda Anggota Wartel",
	},
	["kta_ygmcenter"] = {
		label = "KTA-YGM Center",
		weight = 100,
		stack = false,
		close = true,
		description = "Kartu Tanda Anggota YGM Center",
	},
	["kta_969_garage"] = {
		label = "KTA-969 Garage",
		weight = 100,
		stack = false,
		close = true,
		description = "Kartu Tanda Anggota 969 Garage",
	},
	["kta_969_resto"] = {
		label = "KTA-969 Resto",
		weight = 100,
		stack = false,
		close = true,
		description = "Kartu Tanda Anggota 969 Resto",
	},
	["kta_resto"] = {
		label = "KTA-Nusantara Resto",
		weight = 100,
		stack = false,
		close = true,
		description = "Kartu Tanda Anggota Resto",
	},
	["kta_rainhart"] = {
		label = "KTA-Rainhart Resto",
		weight = 100,
		stack = false,
		close = true,
		description = "Kartu Tanda Anggota Rainhart Resto",
	},
	["kta_maxclub"] = {
		label = "KTA-Max Club",
		weight = 100,
		stack = false,
		close = true,
		description = "Kartu Tanda Anggota Max Club",
	},
	["kta_yclub"] = {
		label = "KTA-ECLUB",
		weight = 100,
		stack = false,
		close = true,
		description = "Kartu Tanda Anggota ECLUB",
	},
	["kta_kkpgarage"] = {
		label = "KTA-KKP Garage",
		weight = 100,
		stack = false,
		close = true,
		description = "Kartu Tanda Anggota KKP Garage",
	},
	["kta_kungkungkap"] = {
		label = "KTA-Kungkungkap",
		weight = 100,
		stack = false,
		close = true,
		description = "Kartu Tanda Anggota Kungkungkap",
	},
	["kta_atomburger"] = {
		label = "KTA-Atom-n Burger",
		weight = 100,
		stack = false,
		close = true,
		description = "Kartu Tanda Anggota Atom n Burger",
	},
	["kta_max_speed"] = {
		label = "KTA-Max Speed Garage",
		weight = 100,
		stack = false,
		close = true,
		description = "Kartu Tanda Anggota Max Speed Garage",
	},
	["kta_rs_roxwood"] = {
		label = "KTA-Rox Wood Hospital",
		weight = 100,
		stack = false,
		close = true,
		description = "Kartu Tanda Anggota Rox Wood Hospital",
	},
	["kta_stunberg"] = {
		label = "KTA-Stunberg Garage",
		weight = 100,
		stack = false,
		close = true,
		description = "Kartu Tanda Anggota Stunberg Garage",
	},
	["kta_taxi"] = {
		label = "KTA-Taxi",
		weight = 100,
		stack = false,
		close = true,
		description = "Kartu Tanda Anggota Taxi",
	},
	["kta_taxism"] = {
		label = "KTA-SMGO",
		weight = 100,
		stack = false,
		close = true,
		description = "Kartu Tanda Anggota SMGO",
	},
	["kta_pabrik"] = {
		label = "KTA-Pabrik",
		weight = 100,
		stack = false,
		close = true,
		description = "Kartu Tanda Anggota Pabrik Sumber Rezeki",
	},
	["kta_reporter"] = {
		label = "KTA-Reporter",
		weight = 100,
		stack = false,
		close = true,
		description = "Kartu Tanda Anggota Reporter",
	},
	["kta_mechanic"] = {
		label = "KTA-TeknoGarages",
		weight = 100,
		stack = false,
		close = true,
		description = "Kartu Tanda Anggota Tekno",
	},
	["kta_police"] = {
		label = "KTA-Polisi",
		weight = 100,
		stack = false,
		close = true,
		description = "Kartu Tanda Anggota Polisi",
	},
	["kta_criminal"] = {
		label = "KTA-Criminal Investigation",
		weight = 100,
		stack = false,
		close = true,
		description = "Kartu Tanda Anggota Criminal Investigation",
	},

	["kta_detective"] = {
		label = "KTA-Detective",
		weight = 100,
		stack = false,
		close = true,
		description = "Kartu Tanda Anggota Detective",
	},

	["kta_fib"] = {
		label = "KTA-FIB",
		weight = 100,
		stack = false,
		close = true,
		description = "Kartu Tanda Anggota FIB",
	},

	["kta_lspd"] = {
		label = "KTA-LSPD",
		weight = 100,
		stack = false,
		close = true,
		description = "Kartu Tanda Anggota LSPD",
	},

	["kta_sheriff"] = {
		label = "KTA-Sheriff",
		weight = 100,
		stack = false,
		close = true,
		description = "Kartu Tanda Anggota Sheriff",
	},

	["kta_smsp"] = {
		label = "KTA-SMSP",
		weight = 100,
		stack = false,
		close = true,
		description = "Kartu Tanda Anggota SMSP",
	},

	["kta_sort"] = {
		label = "KTA-SORT",
		weight = 100,
		stack = false,
		close = true,
		description = "Kartu Tanda Anggota SORT",
	},

	["kta_specialrespon"] = {
		label = "KTA-Special Respon",
		weight = 100,
		stack = false,
		close = true,
		description = "Kartu Tanda Anggota Special Response",
	},

	["kta_specialweapon"] = {
		label = "KTA-Special Weapon",
		weight = 100,
		stack = false,
		close = true,
		description = "Kartu Tanda Anggota Special Weapon",
	},
	["kta_ambulance"] = {
		label = "KTA-EMS",
		weight = 100,
		stack = false,
		close = true,
		description = "Kartu Tanda Anggota EMS",
	},
	["kta_government"] = {
		label = "KTA-PEMERINTAH",
		weight = 100,
		stack = false,
		close = true,
		description = "Kartu Tanda Anggota Pemerintah",
	},

	["kta_doj"] = {
		label = "KTA-DOJ",
		weight = 100,
		stack = false,
		close = true,
		description = "Kartu Tanda Anggota DOJ",
	},

	["kta_usms"] = {
		label = "KTA-usms",
		weight = 100,
		stack = false,
		close = true,
		description = "Kartu Tanda Anggota USMS",
	},

	["kta_statebar"] = {
		label = "Kartu State Bar",
		weight = 100,
		stack = false,
		close = true,
		description = "Kartu Anggota State Bar of San Andreas",
	},

	kta_kedai_ygm = {
		label = "KTA-ECL Kedai",
		weight = 100,
		stack = false,
		close = true,
		description = "Kartu Tanda Anggota ECL Kedai",
	},

	["kartu_kesehatan"] = {
		label = "Kartu Kesehatan",
		weight = 100,
		stack = false,
		close = true,
		description = "Kartu Kesehatan",
	},

	['bass'] = {
		label = "Bass",
		weight = 100,
		stack = true,
		close = false,
	},

	['bluegill'] = {
		label = "Bluegill",
		weight = 100,
		stack = true,
		close = false,
	},

	['common_carp'] = {
		label = "Common Carp",
		weight = 100,
		stack = true,
		close = false,
	},

	['nothern_pike'] = {
		label = "Northern Pike",
		weight = 100,
		stack = true,
		close = false,
	},

	['perch'] = {
		label = "Perch",
		weight = 100,
		stack = true,
		close = false,
	},

	['rainbow_trout'] = {
		label = "Rainbow Trout",
		weight = 100,
		stack = true,
		close = false,
	},

	['redfin_pickerel'] = {
		label = "Redfin Pickerel",
		weight = 100,
		stack = true,
		close = false,
	},

	['rock_bass'] = {
		label = "Rock Bass",
		weight = 100,
		stack = true,
		close = false,
	},

	['small_trout'] = {
		label = "Small Trout",
		weight = 100,
		stack = true,
		close = false,
	},

	['smallmouth_bass'] = {
		label = "Smallmouth Bass",
		weight = 100,
		stack = true,
		close = false,
	},

	['sockeye_salmon'] = {
		label = "Sockeye Salmon",
		weight = 100,
		stack = true,
		close = false,
	},

	['trout'] = {
		label = "Trout",
		weight = 100,
		stack = true,
		close = false,
	},

	['whitefish'] = {
		label = "Whitefish",
		weight = 100,
		stack = true,
		close = false,
	},

	['redpearl'] = {
		label = "Red Pearl",
		weight = 100,
		stack = true,
		close = false,
	},

	['bluepearl'] = {
		label = "Blue Pearl",
		weight = 100,
		stack = true,
		close = false,
	},

	['yellowpearl'] = {
		label = "Yellow Pearl",
		weight = 100,
		stack = true,
		close = false,
	},

	['greenpearl'] = {
		label = "Green Pearl",
		weight = 100,
		stack = true,
		close = false,
	},

	['whitepearl'] = {
		label = "White Pearl",
		weight = 100,
		stack = true,
		close = false,
	},

	['green_crab'] = {
		label = "Green Crab",
		weight = 500,
		stack = true,
		close = false,
	},

	['red_crab'] = {
		label = "Red Crab",
		weight = 500,
		stack = true,
		close = false,
	},

	['blue_crab'] = {
		label = "Blue Crab",
		weight = 500,
		stack = true,
		close = false,
	},

	['king_crab'] = {
		label = "King Crab",
		weight = 500,
		stack = true,
		close = false,
	},

	['fishing_rod_one'] = {
		label = "1 Lvl Fishing Rod",
		weight = 1000,
		stack = false,
		close = true,
	},

	['fishing_rod_two'] = {
		label = "2 Lvl Fishing Rod",
		weight = 1000,
		stack = false,
		close = true,
	},

	['fishing_rod_three'] = {
		label = "3 Lvl Fishing Rod",
		weight = 1000,
		stack = false,
		close = true,
	},

	['fishing_rod_four'] = {
		label = "4 Lvl Fishing Rod",
		weight = 1000,
		stack = false,
		close = true,
	},

	['fishing_rod_five'] = {
		label = "5 Lvl Fishing Rod",
		weight = 1000,
		stack = false,
		close = true,
	},

	['worm_fish_bait'] = {
		label = "Worm Fish Bait",
		weight = 100,
		stack = true,
		close = false,
	},

	['simple_fish_bait'] = {
		label = "Simple Fish Bait",
		weight = 100,
		stack = true,
		close = false,
	},

	['illegal_fish_bait'] = {
		label = "Illegal Fish Bait",
		weight = 100,
		stack = true,
		close = false,
	},

	['diving_cloth'] = {
		label = "Diving Cloths",
		weight = 1000,
		stack = true,
		close = false,
	},

	-- ['diving_gear'] = {
	-- 	label = "Diving Gear",
	-- 	weight = 100,
	-- 	stack = true,
	-- 	close = false,
	-- },

	['diving_tube'] = {
		label = "Diving Tube",
		weight = 1000,
		stack = true,
		close = false,
	},

	['rod_grip'] = {
		label = "Rod Grip",
		weight = 750,
		stack = true,
		close = false,
	},

	['rod_reel_seet'] = {
		label = "Rod Reel Seet",
		weight = 750,
		stack = true,
		close = false,
	},

	['rod_blank'] = {
		label = "Rod Blank",
		weight = 750,
		stack = true,
		close = false,
	},

	['rod_fishing_line'] = {
		label = "Rod Line",
		weight = 750,
		stack = true,
		close = false,
	},

	['vehicle_wheels'] = {
		label = "Vehicle Wheels",
		weight = 2500,
		stack = true,
		close = false,
	},

	['trash_can'] = {
		label = "Trash Can",
		weight = 200,
		stack = true,
		close = false,
	},

	['trash_chips'] = {
		label = "Trash Chips",
		weight = 200,
		stack = true,
		close = false,
	},

	['trash_burger'] = {
		label = "Trash Burger",
		weight = 200,
		stack = true,
		close = false,
	},

	['scrapmetal'] = {
		label = "Scrap Metal",
		weight = 100,
		stack = true,
		close = false,
	},

	['coral_grass'] = {
		label = "Coral Grass",
		weight = 100,
		stack = true,
		close = false,
	},

	['shark'] = {
		label = "Hiu",
		weight = 100,
		stack = true,
		close = false,
	},
	['oplasbaru'] = {
		label = 'Tiket Oplas',
		weight = 10,
		degrade = 2880,
		decay = true,
		stack = true,
		description = 'Tiket operasi plastik. Pakai untuk membuka menu ubah wajah.',
	},
	['banmesidcard'] = {
		label = 'Tiket Banmes',
		weight = 10,
		stack = false,
		description = 'Kartu akses ke job Banmes sementara [Masa berlaku 5 Jam setelah aktif menjadi Banmes]',
	},

	['bucket'] = {
		label = 'Ember',
		weight = 500,
		stack = true,
		close = true,
		description = nil
	},

	['bucketmilk'] = {
		label = 'Ember Susu',
		weight = 750,
		stack = true,
		close = true,
		description = nil,
		client = {
			export = "azakit_cowmilking.useItem"
		}
	},

	['homemademilk'] = {
		label = 'Homemade milk',
		weight = 250,
		stack = true,
		close = true,
		allowArmed = true,
		description = nil
	},

	['lasso'] = {
		label = 'Lasso',
		weight = 800,
		stack = false,
		close = true,
		description = 'Tali laso peternak. Pakai untuk mengikat dan menyeret.',
		image = 'rope.png'
	},

	--hunting
	["kulitrusa"] = {
		label = "Kulit Rusa",
		weight = 500,
		stack = true,
		close = false,
		description = "",
		client = {
			image = "kulitrusa.png",
		}
	},
	["hunting_boar"] = {
		label = "hunting boar",
		weight = 500,
		stack = true,
		close = true,
		description = "",
		client = {
			image = "hunting_boar.png",
		}
	},
	["hunting_skin"] = {
		label = "hunting skin",
		weight = 500,
		stack = true,
		close = true,
		description = "",
		client = {
			image = "hunting_skin.png",
		}
	},

	["hunting_seagull"] = {
		label = "hunting seagull",
		weight = 500,
		stack = true,
		close = true,
		description = "",
		client = {
			image = "hunting_seagull.png",
		}
	},

	["hunting_rabbit"] = {
		label = "hunting rabbit",
		weight = 500,
		stack = true,
		close = true,
		description = "",
		client = {
			image = "hunting_rabbit.png",
		}
	},

	["hunting_pigeon"] = {
		label = "hunting pigeon",
		weight = 500,
		stack = true,
		close = true,
		description = "",
		client = {
			image = "hunting_pigeon.png",
		}
	},

	["hunting_mtlion"] = {
		label = "hunting mtlion",
		weight = 500,
		stack = true,
		close = true,
		description = "",
		client = {
			image = "hunting_mtlion.png",
		}
	},

	["hunting_meat"] = {
		label = "hunting meat",
		weight = 500,
		stack = true,
		close = true,
		description = "",
		client = {
			image = "hunting_meat.png",
		}
	},

	["hunting_deer"] = {
		label = "hunting deer",
		weight = 500,
		stack = true,
		close = true,
		description = "",
		client = {
			image = "hunting_deer.png",
		}
	},

	["hunting_crow"] = {
		label = "hunting crow",
		weight = 500,
		stack = true,
		close = true,
		description = "",
		client = {
			image = "hunting_crow.png",
		}
	},

	["hunting_coyote"] = {
		label = "hunting coyote",
		weight = 500,
		stack = true,
		close = true,
		description = "",
		client = {
			image = "hunting_coyote.png",
		}
	},

	["hunting_chickenhawk"] = {
		label = "hunting chickenhawk",
		weight = 500,
		stack = true,
		close = true,
		description = "",
		client = {
			image = "hunting_chickenhawk.png",
		}
	},
	["album"] = {
		label = "Album Polaroid",
		weight = 200,
		stack = false,
		close = true,
		description = "polaroid things..",
	},
	["photo"] = {
		label = "Photo Polaroid",
		weight = 100,
		stack = false,
		close = true,
		description = "polaroid things..",
        buttons = {
            {
                label = 'Tambah ke Album',
                action = function(slot)
                    TriggerServerEvent('rhd_photo_system:addPhotoToAlbum', slot)
                end
            }
        }
	},
	["polaroid"] = {
		label = "Polaroid Cam",
		weight = 500,
		degrade = 10080,
		stack = true,
		close = true,
		description = "polaroid things..",
	},
	["pdcamera"] = {
		label = "PD Camera",
		weight = 500,
		stack = false,
		close = true,
		description = "Police Documentation Camera",
	},

    ['redw'] = {
        label = 'Redwood Pack',
        weight = 200,
        stack = true,
        close = true,
        description = 'Take out your cigarettes',
    },

    ['marlboro'] = {
        label = 'Cigarette Pack',
        weight = 200,
        stack = true,
        close = true,
        description = 'Take out your cigarettes',
    },

	['packrokom'] = {
        label = 'Marlong Pack',
        weight = 200,
        stack = true,
        close = true,
        description = 'Take out your cigarettes',
    },

	['gpipepack'] = {
        label = 'Gentlemanâ€™s Pipe Pack',
        weight = 200,
        stack = true,
        close = true,
        description = 'Take out your smoking pipe',
    },

	['packcerutus'] = {
        label = 'Surya Pack',
        weight = 200,
        stack = true,
        close = true,
        description = 'Take out your cigarettes',
    },

    ['cubancigar'] = {
        label = 'Cuban Cigar',
        weight = 200,
        stack = true,
        close = true,
        description = 'Real cigar',
    },

    ['davidoffcigar'] = {
        label = 'Davidoff Cigar',
        weight = 200,
        stack = true,
        close = true,
        description = 'Real cigar',
    },

    ['redwcig'] = {
        label = 'Redwood Cigarette',
        weight = 200,
        stack = true,
        close = true,
        description = 'Smoking cigarette',
    },

    ['marlborocig'] = {
        label = 'Cigarette',
        weight = 10,
        stack = true,
        close = true,
        description = 'Smoking cigarette',
    },

	['rokokbatanganm'] = {
        label = 'Marlong Cigarette',
        weight = 10,
        stack = true,
        close = true,
        description = 'Smoking cigarette',
    },

	['cerutubatangans'] = {
        label = 'Surya Cigar',
        weight = 10,
        stack = true,
        close = true,
        description = 'Smoking cigarette',
    },

	['gpipe'] = {
        label = 'Gentlemanâ€™s Pipe',
        weight = 10,
        stack = true,
        close = true,
        description = 'Smoking pipe',
    },

    ['vape'] = {
        label = 'Vape',
        weight = 200,
        stack = true,
        close = true,
        description = 'Electronic cigarette',
    },

    ['liquid'] = {
        label = 'Liquid',
        weight = 200,
        stack = true,
        close = true,
        description = 'Vape liquid',
    },

	['empty_nitrous'] = {
		label = 'Nitrous (Empty)',
		weight = 500,
		client = {
			image = 'nitrous.png'
		}
	},
	['nitrous'] = {
		label = 'Nitrous (Original Colour)',
		weight = 1000,
		client = {
			image = 'nitrous.png'
		}
	},
	['red_nitrous'] = {
		label = 'Nitrous (Red Colour)',
		weight = 1000,
		client = {
			image = 'nitrous.png'
		}
	},
	['blue_nitrous'] = {
		label = 'Nitrous (Blue Colour)',
		weight = 1000,
		client = {
			image = 'nitrous.png'
		}
	},
	['purge_colour'] = {
		label = 'Purge Colour',
		weight = 100,
		client = {
			image = 'purge_colour.png'
		}
	},

	['love_letter'] = {
		label = 'Love Letter',
		weight = 150,
		stack = true,
		close = true,
		description = 'love letter from someone special'
	},
	-- If using Lua format (items.lua)
	['voucher_peredakeram'] = {
		label = 'Voucher Pereda Keram',
		weight = 0,
		stack = true,
		close = true,
		description = 'Voucher yang dapat mengurangi waktu AntiTroll sebanyak 12 jam',
		client = {
			export = 'sm_resource.voucher_peredakeram'
		}
	},
	['coupon_a'] = {
		label = 'Coupon A',
		weight = 0,
		stack = true,
		close = true,
		description = 'Ditukarkan untuk mendapatkan voucher pereda keram',
	},
	['coupon_b'] = {
		label = 'Coupon B',
		weight = 0,
		stack = true,
		close = true,
		description = 'Ditukarkan untuk mendapatkan voucher pereda keram',
	},

	['ceo_badge_anim01'] = {
		label = 'â€¢CEO Badge',
		weight = 100,
		stack = true,
		close = true,
		description = 'Ban lengan badge'
	},

	['founder_badge_anim01'] = {
		label = 'â€¢Founder Badge',
		weight = 100,
		stack = true,
		close = true,
		description = 'Ban lengan badge'
	},

	['god_badge_anim01'] = {
		label = 'â€¢God Badge',
		weight = 100,
		stack = true,
		close = true,
		description = 'Ban lengan badge'
	},

	['un_london_admin_armshile'] = {
		label = 'Armshile Badge',
		weight = 100,
		stack = true,
		close = true,
		description = 'Ban lengan badge'
	},

	['tulisan_bronzeknight_badge'] = {
		label = 'â€¢Bronze Knight Badge',
		weight = 100,
		stack = true,
		close = true,
		description = 'Ban lengan badge'
	},
	['tulisan_emperor_badge'] = {
		label = 'Emperor Knight Badge',
		weight = 100,
		stack = true,
		close = true,
		description = 'Ban lengan badge'
	},
	['tulisan_goldenwar_badge'] = {
		label = 'Goldenwar Knight Badge',
		weight = 100,
		stack = true,
		close = true,
		description = 'Ban lengan badge'
	},
	['tulisan_platinum_badge'] = {
		label = 'Platinum Knight Badge',
		weight = 100,
		stack = true,
		close = true,
		description = 'Ban lengan badge'
	},
	['tulisan_admin_badge'] = {
		label = 'â€¢Admin Badge',
		weight = 100,
		stack = true,
		close = true,
		description = 'Badge lengan badge'
	},
	['tulisan_silverwings_badge'] = {
		label = 'Silverwings Knight Badge',
		weight = 100,
		stack = true,
		close = true,
		description = 'Ban lengan badge'
	},
	['ws_fashion_anim_f_admin'] = {
		label = 'Admin fashion',
		weight = 100,
		stack = false,
		close = true,
		description = 'Title Admin',
	},
	['ws_fashion_anim_f_ceo'] = {
		label = 'CEO fashion',
		weight = 100,
		stack = false,
		close = true,
		description = 'Title CEO',
	},
	['ws_fashion_anim_f_founder'] = {
		label = 'Founder fashion',
		weight = 100,
		stack = false,
		close = true,
		description = 'Title Founder',
	},
	['ws_fashion_anim_silver_plz'] = {
		label = 'Silver Title',
		weight = 100,
		stack = false,
		close = true,
		description = 'Title Silver yang menandakan pencapaian Anda',
	},

	['ws_fashion_anim_platinum_plz'] = {
		label = 'Platinum Title',
		weight = 100,
		stack = false,
		close = true,
		description = 'Title Platinum yang menandakan status elite Anda',
	},

	['ws_fashion_anim_knight_plz'] = {
		label = 'Knight Title',
		weight = 100,
		stack = false,
		close = true,
		description = 'Title Knight yang menunjukkan kehormatan Anda',
	},

	['ws_fashion_anim_gold_plz'] = {
		label = 'Gold Title',
		weight = 100,
		stack = false,
		close = true,
		description = 'Title Gold yang berkilauan dan mewah',
	},

	['ws_fashion_anim_emperor_plz'] = {
		label = 'Emperor Title',
		weight = 100,
		stack = false,
		close = true,
		description = 'Title Emperor legendaris yang sangat langka dan bergengsi',
	},

	-- ==================== SHIRTS ====================

	--- MALE SHIRTS ---
	["m_shirts_rb"] = {
		label = "Kemeja RB Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Kemeja RB untuk pria",
	},

	--- FEMALE SHIRTS ---
	["f_shirts_rb"] = {
		label = "Kemeja RB Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Kemeja RB untuk wanita",
	},

	-- ==================== JACKETS ====================

	["m_jackets_nagasaki1"] = {
		label = "Jaket Nagasaki Pria 1",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Nagasaki tipe 1 untuk pria",
	},

	["m_jackets_nagasaki2"] = {
		label = "Jaket Nagasaki Pria 2",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Nagasaki tipe 2 untuk pria",
	},

	["f_jackets_nagasaki1"] = {
		label = "Jaket Nagasaki Perempuan 1",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Nagasaki tipe 1 untuk Perempuan",
	},

	["f_jackets_nagasaki2"] = {
		label = "Jaket Nagasaki Perempuan 2",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Nagasaki tipe 2 untuk Perempuan",
	},

	["m_jackets_kinggroup2"] = {
		label = "Jaket King Group Pria 2",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket King Group tipe 2 untuk pria",
	},

	["f_jackets_kinggroup2"] = {
		label = "Jaket King Group Perempuan 2",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket King Group tipe 2 untuk Perempuan",
	},

	["m_jackets_kinggroup1"] = {
		label = "Jaket King Group Pria 1",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket King Group tipe 1 untuk pria",
	},

	["f_jackets_kinggroup1"] = {
		label = "Jaket King Group Perempuan 1",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket King Group tipe 1 untuk Perempuan",
	},

    ["m_bodyarmor_jdmc1"] = {
		label = "Body Armor JDMC Pria 1",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body Armor JDMC tipe 1 untuk pria",
	},

	---

	["m_bodyarmor_r9691"] = {
		label = "Body Armor Reborn 969 Pria 1",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body Armor Reborn 969 tipe 1 untuk pria",
	},

	["f_bodyarmor_r9691"] = {
		label = "Body Armor Reborn 969 Perempuan 1",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body Armor Reborn 969 tipe 1 untuk Perempuan",
	},


	["m_jackets_jdmc1"] = {
		label = "Jaket JDMC Pria 1",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket JDMC tipe 1 untuk pria",
	},

	["f_jackets_jdmc1"] = {
		label = "Jaket JDMC Perempuan 1",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket JDMC tipe 1 untuk Perempuan",
	},

	["m_jackets_jdmc2"] = {
		label = "Jaket JDMC Pria 2",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket JDMC tipe 2 untuk pria",
	},

	["f_jackets_jdmc2"] = {
		label = "Jaket JDMC Perempuan 2",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket JDMC tipe 2 untuk Perempuan",
	},

	["m_jackets_jdmc3"] = {
		label = "Jaket JDMC Pria 3",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket JDMC tipe 3 untuk pria",
	},

	["f_jackets_jdmc3"] = {
		label = "Jaket JDMC Perempuan 3",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket JDMC tipe 3 untuk Perempuan",
	},


	--- MALE JACKETS ---
	["m_jackets_wd1"] = {
		label = "Jaket WD1 Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket WD tipe 1 untuk pria",
	},

	["m_jackets_wd2"] = {
		label = "Jaket WD2 Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket WD tipe 2 untuk pria",
	},

	["m_jackets_bz1_0"] = {
		label = "Jaket BZ1 Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket BZ tipe 1 warna hitam untuk pria",
	},

	["m_jackets_bz1_1"] = {
		label = "Jaket BZ1 Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket BZ tipe 1 warna abu-abu untuk pria",
	},

	["m_jackets_bz1_2"] = {
		label = "Jaket BZ1 Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket BZ tipe 1 warna navy untuk pria",
	},

	["m_jackets_bz2_0"] = {
		label = "Jaket BZ2 Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket BZ tipe 2 warna hitam untuk pria",
	},

	["m_jackets_bz2_1"] = {
		label = "Jaket BZ2 Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket BZ tipe 2 warna abu-abu untuk pria",
	},

	["m_jackets_bz2_2"] = {
		label = "Jaket BZ2 Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket BZ tipe 2 warna navy untuk pria",
	},

	["f_bodyarmor_thez1"] = {
		label = "Body Armor The Z Perempuan",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor The Z tipe 1 untuk Perempuan",
	},

	["m_bodyarmor_thez1"] = {
		label = "Body Armor The Z Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor The Z tipe 1 untuk Pria",
	},

	["f_bodyarmor_wlmc1"] = {
		label = "Body Armor WLMC Perempuan",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor WLMC tipe 1 untuk Perempuan",
	},

	["m_bodyarmor_wlmc1"] = {
		label = "Body Armor WLMC Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor WLMC tipe 1 untuk Pria",
	},

	["f_bodyarmor_bbl1"] = {
		label = "Body Armor BBL Perempuan",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor BBL tipe 1 untuk Perempuan",
	},

	["m_bodyarmor_bbl1"] = {
		label = "Body Armor BBL Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor BBL tipe 1 untuk Pria",
	},

	["m_bodyarmor_rmc1_0"] = {
		label = "Body Armor RMC1 Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor RMC tipe 1 untuk pria",
	},
	["m_bodyarmor_rmc1_1"] = {
		label = "Body Armor RMC1 Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor RMC tipe 1 untuk pria",
	},
	["m_bodyarmor_rmc1_2"] = {
		label = "Body Armor RMC1 Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor RMC tipe 1 untuk pria",
	},
	["m_bodyarmor_rmc1_3"] = {
		label = "Body Armor RMC1 Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor RMC tipe 1 untuk pria",
	},
	["m_bodyarmor_rmc1_4"] = {
		label = "Body Armor RMC1 Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor RMC tipe 1 untuk pria",
	},
	["m_bodyarmor_rmc1_5"] = {
		label = "Body Armor RMC1 Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor RMC tipe 1 untuk pria",
	},
	["m_bodyarmor_rmc1_6"] = {
		label = "Body Armor RMC1 Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor RMC tipe 1 untuk pria",
	},
	["m_bodyarmor_rmc1_7"] = {
		label = "Body Armor RMC1 Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor RMC tipe 1 untuk pria",
	},
	["m_bodyarmor_rmc1_8"] = {
		label = "Body Armor RMC1 Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor RMC tipe 1 untuk pria",
	},
	["m_bodyarmor_rmc1_9"] = {
		label = "Body Armor RMC1 Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor RMC tipe 1 untuk pria",
	},

	["f_bodyarmor_rmc1_0"] = {
		label = "Body Armor RMC1 Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor RMC1 tipe 1 untuk wanita",
	},
	["f_bodyarmor_rmc1_1"] = {
		label = "Body Armor RMC1 Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor RMC1 tipe 1 untuk wanita",
	},
	["f_bodyarmor_rmc1_2"] = {
		label = "Body Armor RMC1 Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor RMC1 tipe 1 untuk wanita",
	},
	["f_bodyarmor_rmc1_3"] = {
		label = "Body Armor RMC1 Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor RMC1 tipe 1 untuk wanita",
	},
	["f_bodyarmor_rmc1_4"] = {
		label = "Body Armor RMC1 Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor RMC1 tipe 1 untuk wanita",
	},
	["f_bodyarmor_rmc1_5"] = {
		label = "Body Armor RMC1 Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor RMC1 tipe 1 untuk wanita",
	},
	["f_bodyarmor_rmc1_6"] = {
		label = "Body Armor RMC1 Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor RMC1 tipe 1 untuk wanita",
	},
	["f_bodyarmor_rmc1_7"] = {
		label = "Body Armor RMC1 Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor RMC1 tipe 1 untuk wanita",
	},
	["f_bodyarmor_rmc1_8"] = {
		label = "Body Armor RMC1 Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor RMC1 tipe 1 untuk wanita",
	},
	["f_bodyarmor_rmc1_9"] = {
		label = "Body Armor RMC1 Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor RMC1 tipe 1 untuk wanita",
	},

	["m_bodyarmor_ssmc1_0"] = {
		label = "Body Armor SSMC1 Pria (Hitam)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor SSMC tipe 1 warna hitam untuk pria",
	},
	["f_bodyarmor_ssmc1_0"] = {
		label = "Body Armor SSMC1 Wanita (Hitam)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor SSMC tipe 1 warna hitam untuk wanita",
	},

	["m_bodyarmor_ssmc2_0"] = {
		label = "Body Armor SSMC2 Pria 0",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor SSMC tipe 2 untuk pria",
	},
	["m_bodyarmor_ssmc2_1"] = {
		label = "Body Armor SSMC2 Pria 1",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor SSMC tipe 2 untuk pria",
	},
	["m_bodyarmor_ssmc2_2"] = {
		label = "Body Armor SSMC2 Pria 2",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor SSMC tipe 2 untuk pria",
	},
	["m_bodyarmor_ssmc2_3"] = {
		label = "Body Armor SSMC2 Pria 3",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor SSMC tipe 2 untuk pria",
	},
	["m_bodyarmor_ssmc2_4"] = {
		label = "Body Armor SSMC2 Pria 4",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor SSMC tipe 2 untuk pria",
	},
	["m_bodyarmor_ssmc2_5"] = {
		label = "Body Armor SSMC2 Pria 5",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor SSMC tipe 2 untuk pria",
	},
	["m_bodyarmor_ssmc2_6"] = {
		label = "Body Armor SSMC2 Pria 6",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor SSMC tipe 2 untuk pria",
	},
	["m_bodyarmor_ssmc2_7"] = {
		label = "Body Armor SSMC2 Pria 7",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor SSMC tipe 2 untuk pria",
	},

	["f_bodyarmor_ssmc2_0"] = {
		label = "Body Armor SSMC2 Wanita 0",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor SSMC tipe 2 untuk wanita",
	},
	["f_bodyarmor_ssmc2_1"] = {
		label = "Body Armor SSMC2 Wanita 1",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor SSMC tipe 2 untuk wanita",
	},
	["f_bodyarmor_ssmc2_2"] = {
		label = "Body Armor SSMC2 Wanita 2",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor SSMC tipe 2 untuk wanita",
	},
	["f_bodyarmor_ssmc2_3"] = {
		label = "Body Armor SSMC2 Wanita 3",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor SSMC tipe 2 untuk wanita",
	},
	["f_bodyarmor_ssmc2_4"] = {
		label = "Body Armor SSMC2 Wanita 4",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor SSMC tipe 2 untuk wanita",
	},
	["f_bodyarmor_ssmc2_5"] = {
		label = "Body Armor SSMC2 Wanita 5",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor SSMC tipe 2 untuk wanita",
	},
	["f_bodyarmor_ssmc2_6"] = {
		label = "Body Armor SSMC2 Wanita 6",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor SSMC tipe 2 untuk wanita",
	},
	["f_bodyarmor_ssmc2_7"] = {
		label = "Body Armor SSMC2 Wanita 7",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor SSMC tipe 2 untuk wanita",
	},

	["m_jackets_phantom1"] = {
		label = "Jaket Phantom1 Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Phantom tipe 1 untuk pria",
	},

	["f_bodyarmor_phantom1"] = {
		label = "Jaket Phantom1 Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Phantom tipe 1 untuk wanita",
	},

	["m_jackets_maevan1"] = {
		label = "Jaket Maevan1 Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Maevan tipe 1 untuk pria",
	},
	["f_jackets_maevan1_0"] = {
		label = "Jaket Maevan1 Wanita (Varian 0)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Maevan tipe 1 varian 0 untuk wanita",
	},
	["f_jackets_maevan1_1"] = {
		label = "Jaket Maevan1 Wanita (Varian 1)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Maevan tipe 1 varian 1 untuk wanita",
	},

	["m_bodyarmor_babayo2"] = {
		label = "Body Armor Babayo2 Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Babayo tipe 2 untuk pria",
	},
	["f_bodyarmor_babayo3"] = {
		label = "Body Armor Babayo3 Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Babayo tipe 3 untuk wanita",
	},

	["f_bodyarmor_babayo4"] = {
		label = "Body Armor Babayo4 Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Babayo tipe 4 untuk wanita",
	},

	["m_bodyarmor_whitetiger1"] = {
		label = "Body Armor White Tiger1 Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor White Tiger tipe 1 untuk pria",
	},
	["f_bodyarmor_whitetiger1"] = {
		label = "Body Armor White Tiger1 Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor White Tiger tipe 1 untuk wanita",
	},

	["m_jackets_larosenoir1"] = {
		label = "Jaket Larose noir Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Larose noir tipe 1 untuk pria",
	},

	["f_jackets_larosenoir1"] = {
		label = "Jaket Larose noir Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Larose noir tipe 1 untuk wanita",
	},

	["m_bodyarmor_sfc1_0"] = {
		label = "Body Armor SFC1 Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body Armor SFC tipe 1 untuk pria",
	},

	["m_bodyarmor_sfc1_1"] = {
		label = "Body Armor SFC1 Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body Armor SFC tipe 1 untuk pria",
	},

	["f_bodyarmor_sfc1_0"] = {
		label = "Body Armor SFC1 Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body Armor SFC tipe 1 untuk wanita",
	},

	["m_jackets_cortize1"] = {
		label = "Jaket Cortize Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Cortize untuk pria",
	},
	["f_jackets_cortize1"] = {
		label = "Jaket Cortize Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Cortize untuk wanita",
	},

	["m_jackets_cortize2"] = {
		label = "Jaket Cortize Pria 2",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Cortize untuk pria",
	},
	["f_jackets_cortize2"] = {
		label = "Jaket Cortize Wanita 2",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Cortize untuk wanita",
	},

	["m_jackets_soumc1"] = {
		label = "Jaket Syndicate of Unchild MC Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Syndicate of Unchild MC untuk pria",
	},
	["f_jackets_soumc1"] = {
		label = "Jaket Syndicate of Unchild MC Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Syndicate of Unchild MC untuk wanita",
	},

	["m_jackets_rmc1"] = {
		label = "Jaket Redemption MC Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Redemption MC untuk pria",
	},
	["f_bodyarmor_rmc2"] = {
		label = "Rompi Redemption MC Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi Redemption MC untuk wanita",
	},

	["f_bodyarmor_blacklotus1"] = {
		label = "Rompi Black Lotus Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi Black Lotus untuk wanita",
	},


	["m_bodyarmor_wdmc1_0"] = {
		label = "Rompi Wild Dog MC Pria (President)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi Wild Dog MC variasi 0 untuk pria",
	},

	["m_bodyarmor_wdmc1_1"] = {
		label = "Rompi Wild Dog MC Pria (Vice President)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi Wild Dog MC variasi 0 untuk pria",
	},

	["m_bodyarmor_wdmc1_2"] = {
		label = "Rompi Wild Dog MC Pria (Treasurer)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi Wild Dog MC variasi 0 untuk pria",
	},

	["m_bodyarmor_wdmc1_3"] = {
		label = "Rompi Wild Dog MC Pria (Road Captain)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi Wild Dog MC variasi 0 untuk pria",
	},

	["m_bodyarmor_wdmc1_4"] = {
		label = "Rompi Wild Dog MC Pria (Member)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi Wild Dog MC variasi 0 untuk pria",
	},

	["m_bodyarmor_wdmc1_5"] = {
		label = "Rompi Wild Dog MC Pria (Prospect)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi Wild Dog MC variasi 0 untuk pria",
	},

	["m_bodyarmor_fsg1"] = {
		label = "Rompi FSG Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi FSG untuk pria",
	},

	["m_teef_fsg1"] = {
		label = "Kalung FSG Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Kalung FSG untuk pria",
	},

	["f_teef_fsg1"] = {
		label = "Kalung FSG Perempuan",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Kalung FSG untuk Perempuan",
	},

	---

	["m_teef_ebk1"] = {
		label = "Kalung EBK Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Kalung EBK untuk pria",
	},

	["f_teef_ebk1"] = {
		label = "Kalung EBK Perempuan",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Kalung EBK untuk Perempuan",
	},



	["m_teef_lv1"] = {
		label = "Kalung Lost Virtues Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Kalung Lost Virtues untuk pria",
	},

	["f_teef_lv1"] = {
		label = "Kalung Lost Virtues Perempuan",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Kalung Lost Virtues untuk Perempuan",
	},

	---

	["f_bodyarmor_wdmc1_0"] = {
		label = "Rompi Wild Dog MC Perempuan (President)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi Wild Dog MC variasi 0 untuk Perempuan",
	},

	["f_bodyarmor_wdmc1_1"] = {
		label = "Rompi Wild Dog MC Perempuan (Vice President)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi Wild Dog MC variasi 0 untuk Perempuan",
	},

	["f_bodyarmor_wdmc1_2"] = {
		label = "Rompi Wild Dog MC Perempuan (Treasurer)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi Wild Dog MC variasi 0 untuk Perempuan",
	},

	["f_bodyarmor_wdmc1_3"] = {
		label = "Rompi Wild Dog MC Perempuan (Road Captain)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi Wild Dog MC variasi 0 untuk Perempuan",
	},

	["f_bodyarmor_wdmc1_4"] = {
		label = "Rompi Wild Dog MC Perempuan (Member)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi Wild Dog MC variasi 0 untuk Perempuan",
	},

	["f_bodyarmor_wdmc1_5"] = {
		label = "Rompi Wild Dog MC Perempuan (Prospect)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi Wild Dog MC variasi 0 untuk Perempuan",
	},

	["f_bodyarmor_fsg1"] = {
		label = "Rompi FSG Perempuan",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi FSG untuk Perempuan",
	},

	["m_bodyarmor_mugen1_0"] = {
		label = "Rompi Mugen MC Pria (Var 0)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi Mugen MC variasi 0 untuk pria",
	},
	["m_bodyarmor_mugen1_1"] = {
		label = "Rompi Mugen MC Pria (Var 1)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi Mugen MC variasi 1 untuk pria",
	},
	["m_bodyarmor_mugen1_2"] = {
		label = "Rompi Mugen MC Pria (Var 2)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi Mugen MC variasi 2 untuk pria",
	},
	["m_bodyarmor_mugen1_3"] = {
		label = "Rompi Mugen MC Pria (Var 3)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi Mugen MC variasi 3 untuk pria",
	},
	["m_bodyarmor_mugen1_4"] = {
		label = "Rompi Mugen MC Pria (Var 4)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi Mugen MC variasi 4 untuk pria",
	},
	["m_bodyarmor_mugen1_5"] = {
		label = "Rompi Mugen MC Pria (Var 5)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi Mugen MC variasi 5 untuk pria",
	},
	["m_bodyarmor_mugen1_6"] = {
		label = "Rompi Mugen MC Pria (Var 6)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi Mugen MC variasi 6 untuk pria",
	},
	["m_bodyarmor_mugen1_7"] = {
		label = "Rompi Mugen MC Pria (Var 7)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi Mugen MC variasi 7 untuk pria",
	},
	["m_bodyarmor_mugen1_8"] = {
		label = "Rompi Mugen MC Pria (Var 8)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi Mugen MC variasi 8 untuk pria",
	},
	["m_bodyarmor_mugen1_9"] = {
		label = "Rompi Mugen MC Pria (Var 9)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi Mugen MC variasi 9 untuk pria",
	},
	["m_bodyarmor_mugen1_10"] = {
		label = "Rompi Mugen MC Pria (Var 10)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi Mugen MC variasi 10 untuk pria",
	},
	["m_bodyarmor_mugen1_11"] = {
		label = "Rompi Mugen MC Pria (Var 11)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi Mugen MC variasi 11 untuk pria",
	},
	["m_bodyarmor_mugen1_12"] = {
		label = "Rompi Mugen MC Pria (Var 12)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi Mugen MC variasi 12 untuk pria",
	},
	["f_bodyarmor_mugen1_0"] = {
		label = "Rompi Mugen MC Wanita (Var 0)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi Mugen MC variasi 0 untuk wanita",
	},
	["f_bodyarmor_mugen1_1"] = {
		label = "Rompi Mugen MC Wanita (Var 1)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi Mugen MC variasi 1 untuk wanita",
	},
	["f_bodyarmor_mugen1_2"] = {
		label = "Rompi Mugen MC Wanita (Var 2)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi Mugen MC variasi 2 untuk wanita",
	},
	["f_bodyarmor_mugen1_3"] = {
		label = "Rompi Mugen MC Wanita (Var 3)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi Mugen MC variasi 3 untuk wanita",
	},
	["f_bodyarmor_mugen1_4"] = {
		label = "Rompi Mugen MC Wanita (Var 4)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi Mugen MC variasi 4 untuk wanita",
	},
	["f_bodyarmor_mugen1_5"] = {
		label = "Rompi Mugen MC Wanita (Var 5)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi Mugen MC variasi 5 untuk wanita",
	},
	["f_bodyarmor_mugen1_6"] = {
		label = "Rompi Mugen MC Wanita (Var 6)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi Mugen MC variasi 6 untuk wanita",
	},
	["f_bodyarmor_mugen1_7"] = {
		label = "Rompi Mugen MC Wanita (Var 7)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi Mugen MC variasi 7 untuk wanita",
	},
	["f_bodyarmor_mugen1_8"] = {
		label = "Rompi Mugen MC Wanita (Var 8)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi Mugen MC variasi 8 untuk wanita",
	},
	["f_bodyarmor_mugen1_9"] = {
		label = "Rompi Mugen MC Wanita (Var 9)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi Mugen MC variasi 9 untuk wanita",
	},
	["f_bodyarmor_mugen1_10"] = {
		label = "Rompi Mugen MC Wanita (Var 10)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi Mugen MC variasi 10 untuk wanita",
	},
	["f_bodyarmor_mugen1_11"] = {
		label = "Rompi Mugen MC Wanita (Var 11)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi Mugen MC variasi 11 untuk wanita",
	},
	["f_bodyarmor_mugen1_12"] = {
		label = "Rompi Mugen MC Wanita (Var 12)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi Mugen MC variasi 12 untuk wanita",
	},

	["f_bodyarmor_sfc1_1"] = {
		label = "Body Armor SFC1 Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body Armor SFC tipe 1 untuk wanita",
	},

	["m_bags_shellby"] = {
		label = "Bags Shellby Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Bags Shellby untuk pria",
	},

	["f_bags_shellby"] = {
		label = "Bags Shellby Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Bags Shellby untuk wanita",
	},

	["m_bodyarmor_shellby1"] = {
		label = "Vest Shellby Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Vest Shellby untuk pria",
	},

	["f_bodyarmor_shellby1"] = {
		label = "Vest Shellby Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Vest Shellby untuk wanita",
	},

	["m_jackets_overdrive1"] = {
		label = "Jaket Overdrive Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Overdrive untuk pria",
	},

	["f_jackets_overdrive1"] = {
		label = "Jaket Overdrive Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Overdrive untuk wanita",
	},

	---
	["m_jackets_deleon1"] = {
		label = "Jaket DeLeon Pria 1",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket DeLeon untuk pria",
	},

	["m_jackets_deleon2"] = {
		label = "Jaket DeLeon Pria 2",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket DeLeon untuk pria",
	},

	["m_jackets_deleon3"] = {
		label = "Jaket DeLeon Pria 3",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket DeLeon untuk pria",
	},


	["f_jackets_deleon2"] = {
		label = "Jaket DeLeon Wanita 2",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket DeLeon untuk Wanita",
	},

	["f_jackets_deleon3"] = {
		label = "Jaket DeLeon Wanita 3",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket DeLeon untuk Wanita",
	},
	---

	["m_bodyarmor_sos1"] = {
		label = "Vest SOS Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Vest SOS untuk Pria",
	},

	["f_bodyarmor_sos1"] = {
		label = "Vest SOS Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Vest SOS untuk Wanita",
	},

	["m_jackets_sos1"] = {
		label = "Jaket SOS Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket SOS untuk Pria",
	},

	["f_jackets_sos1"] = {
		label = "Jaket SOS Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket SOS untuk Wanita",
	},

	["m_jackets_nsn1"] = {
		label = "Jaket NSN Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket NSN tipe 1 pria",
	},

	["m_bodyarmor_nsn1"] = {
		label = "Body Armor NSN Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body Armor NSN tipe 1 pria",
	},

	["f_jackets_nsn1"] = {
		label = "Jaket NSN Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket NSN tipe 1 wanita",
	},

	["f_jackets_nsn2"] = {
		label = "Jaket NSN Wanita 2",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket NSN tipe 2 wanita",
	},

	["f_bodyarmor_nsn1"] = {
		label = "Body Armor NSN Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body Armor NSN tipe 1 wanita",
	},

	["m_bodyarmor_karabas1"] = {
		label = "Body Armor Karabas Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body Armor Karabas tipe 1 untuk pria",
	},

	["m_jackets_karabas1"] = {
		label = "Jaket Karabas Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Karabas tipe 1 untuk pria",
	},

	---

	["m_jackets_hakuryu1"] = {
		label = "Jaket hakuryu Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket hakuryu tipe 1 untuk pria",
	},

	["f_jackets_hakuryu1"] = {
		label = "Jaket hakuryu Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket hakuryu tipe 1 untuk Wanita",
	},

	["m_bodyarmor_hakuryu1"] = {
		label = "Vest hakuryu Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Vest hakuryu tipe 1 untuk pria",
	},

	["f_bodyarmor_hakuryu1"] = {
		label = "Vest hakuryu Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Vest hakuryu tipe 1 untuk Wanita",
	},

    ["m_jackets_invamouz2"] = {
		label = "Jaket invamouz Pria Tipe 2",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket invamouz tipe 2 untuk pria",
	},

	["m_jackets_invamouz1"] = {
		label = "Jaket invamouz Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket invamouz tipe 1 untuk pria",
	},

	["f_jackets_invamouz1"] = {
		label = "Jaket invamouz Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket invamouz tipe 1 untuk Wanita",
	},



	---

	["f_bodyarmor_karabas1"] = {
		label = "Body Armor Karabas Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body Armor Karabas tipe 1 untuk wanita",
	},

	["f_jackets_karabas1"] = {
		label = "Jaket Karabas Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Karabas tipe 1 untuk wanita",
	},

	["f_jackets_karabas2"] = {
		label = "Jaket Karabas Wanita 2",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Karabas tipe 2 untuk wanita",
	},


	["f_jackets_brg1_0"] = {
		label = "Jaket BRG Wanita (Hitam)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket BRG tipe 1 untuk wanita",
	},

	["f_jackets_brg1_1"] = {
		label = "Jaket BRG Wanita (Putih)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket BRG tipe 1 untuk wanita",
	},

	["m_jackets_brg1_0"] = {
		label = "Jaket BRG Pria (Hitam)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket BRG tipe 1 untuk Pria",
	},

	["m_jackets_brg1_1"] = {
		label = "Jaket BRG Wanita (Putih)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket BRG tipe 1 untuk wanita",
	},

    ["m_bodyarmor_brg1"] = {
		label = "Vest BRG Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Vest BRG Pria",
	},

	["f_bodyarmor_brg1"] = {
		label = "Vest BRG Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Vest BRG Wanita",
	},


	["m_jackets_bmc1_0"] = {
		label = "Jaket BMC1 Pria (Hitam)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket BMC tipe 1 warna hitam untuk pria",
	},

	["m_jackets_bmc1_1"] = {
		label = "Jaket BMC1 Pria (Abu-abu)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket BMC tipe 1 warna abu-abu untuk pria",
	},

	["m_jackets_bmc2_0"] = {
		label = "Jaket BMC2 Pria (Hitam)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket BMC tipe 2 warna hitam untuk pria",
	},

	["m_jackets_bmc2_1"] = {
		label = "Jaket BMC2 Pria (Abu-abu)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket BMC tipe 2 warna abu-abu untuk pria",
	},

	["m_jackets_invictus1"] = {
		label = "Jaket Invictus Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Invictus untuk pria",
	},
	["f_jackets_invictus1"] = {
		label = "Jaket Invictus Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Invictus untuk wanita",
	},
	["m_bodyarmor_ryc1_0"] = {
		label = "Body Armor Royal Canine Pria (1)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Royal Canine untuk pria",
	},
	["m_bodyarmor_ryc1_1"] = {
		label = "Body Armor Royal Canine Pria (2)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Royal Canine untuk pria",
	},
	["f_bodyarmor_ryc1_0"] = {
		label = "Body Armor Royal Canine Wanita (1)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Royal Canine untuk wanita",
	},
	["f_bodyarmor_ryc1_1"] = {
		label = "Body Armor Royal Canine Wanita (2)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Royal Canine untuk wanita",
	},

	["m_bodyarmor_mx691"] = {
		label = "Body Armor MX69 Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor MX69 untuk pria",
	},

	["f_bodyarmor_mx691"] = {
		label = "Body Armor MX69 Perempuan",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor MX69 untuk Perempuan",
	},

	["m_bodyarmor_cravell1_0"] = {
		label = "Body Armor Cravell MC Pria ( Variasi 0 )",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Cravell MC untuk pria",
	},

	["m_bodyarmor_cravell1_1"] = {
		label = "Body Armor Cravell MC Pria ( Variasi 1 )",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Cravell MC untuk pria",
	},

	["m_bodyarmor_cravell1_2"] = {
		label = "Body Armor Cravell MC Pria ( Variasi 2 )",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Cravell MC untuk pria",
	},

	["m_bodyarmor_cravell1_3"] = {
		label = "Body Armor Cravell MC Pria ( Variasi 3 )",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Cravell MC untuk pria",
	},

	["m_bodyarmor_cravell1_4"] = {
		label = "Body Armor Cravell MC Pria ( Variasi 4 )",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Cravell MC untuk pria",
	},

	["m_bodyarmor_cravell1_5"] = {
		label = "Body Armor Cravell MC Pria ( Variasi 5 )",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Cravell MC untuk pria",
	},

	["m_bodyarmor_cravell1_6"] = {
		label = "Body Armor Cravell MC Pria ( Variasi 6 )",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Cravell MC untuk pria",
	},

	["m_bodyarmor_cravell1_7"] = {
		label = "Body Armor Cravell MC Pria ( Variasi 7 )",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Cravell MC untuk pria",
	},

	["f_bodyarmor_cravell1_0"] = {
		label = "Body Armor Cravell MC Perempuan ( Variasi 0 )",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Cravell MC untuk Perempuan",
	},

	["f_bodyarmor_cravell1_1"] = {
		label = "Body Armor Cravell MC Perempuan ( Variasi 1 )",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Cravell MC untuk Perempuan",
	},

	["f_bodyarmor_cravell1_2"] = {
		label = "Body Armor Cravell MC Perempuan ( Variasi 2 )",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Cravell MC untuk Perempuan",
	},

	["f_bodyarmor_cravell1_3"] = {
		label = "Body Armor Cravell MC Perempuan ( Variasi 3 )",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Cravell MC untuk Perempuan",
	},

	["f_bodyarmor_cravell1_4"] = {
		label = "Body Armor Cravell MC Perempuan ( Variasi 4 )",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Cravell MC untuk Perempuan",
	},

	["f_bodyarmor_cravell1_5"] = {
		label = "Body Armor Cravell MC Perempuan ( Variasi 5 )",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Cravell MC untuk Perempuan",
	},

	["f_bodyarmor_cravell1_6"] = {
		label = "Body Armor Cravell MC Perempuan ( Variasi 6 )",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Cravell MC untuk Perempuan",
	},

	["f_bodyarmor_cravell1_7"] = {
		label = "Body Armor Cravell MC Perempuan ( Variasi 7 )",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Cravell MC untuk Perempuan",
	},

	---

	["m_bodyarmor_youngmc1_0"] = {
		label = "Body Armor Young MC Pria ( Variasi 0 )",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Young MC untuk pria",
	},

	["m_bodyarmor_youngmc1_1"] = {
		label = "Body Armor Young MC Pria ( Variasi 1 )",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Young MC untuk pria",
	},

	["m_bodyarmor_youngmc1_2"] = {
		label = "Body Armor Young MC Pria ( Variasi 2 )",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Young MC untuk pria",
	},

	["m_bodyarmor_youngmc1_3"] = {
		label = "Body Armor Young MC Pria ( Variasi 3 )",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Young MC untuk pria",
	},

	["m_bodyarmor_youngmc1_4"] = {
		label = "Body Armor Young MC Pria ( Variasi 4 )",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Young MC untuk pria",
	},

	["m_bodyarmor_youngmc1_5"] = {
		label = "Body Armor Young MC Pria ( Variasi 5 )",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Young MC untuk pria",
	},

	["m_bodyarmor_youngmc1_6"] = {
		label = "Body Armor Young MC Pria ( Variasi 6 )",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Young MC untuk pria",
	},

	["m_bodyarmor_youngmc1_7"] = {
		label = "Body Armor Young MC Pria ( Variasi 7 )",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Young MC untuk pria",
	},

	["f_bodyarmor_youngmc1_0"] = {
		label = "Body Armor Young MC Perempuan ( Variasi 0 )",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Young MC untuk Perempuan",
	},

	["f_bodyarmor_youngmc1_1"] = {
		label = "Body Armor Young MC Perempuan ( Variasi 1 )",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Young MC untuk Perempuan",
	},

	["f_bodyarmor_youngmc1_2"] = {
		label = "Body Armor Young MC Perempuan ( Variasi 2 )",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Young MC untuk Perempuan",
	},

	["f_bodyarmor_youngmc1_3"] = {
		label = "Body Armor Young MC Perempuan ( Variasi 3 )",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Young MC untuk Perempuan",
	},

	["f_bodyarmor_youngmc1_4"] = {
		label = "Body Armor Young MC Perempuan ( Variasi 4 )",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Young MC untuk Perempuan",
	},

	["f_bodyarmor_youngmc1_5"] = {
		label = "Body Armor Young MC Perempuan ( Variasi 5 )",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Young MC untuk Perempuan",
	},

	["f_bodyarmor_youngmc1_6"] = {
		label = "Body Armor Young MC Perempuan ( Variasi 6 )",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Young MC untuk Perempuan",
	},

	["f_bodyarmor_youngmc1_7"] = {
		label = "Body Armor Young MC Perempuan ( Variasi 7 )",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Young MC untuk Perempuan",
	},

	["m_jackets_youngmc1"] = {
		label = "Jaket Young Mc Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Young Mc tipe 1 untuk pria",
	},

	["f_jackets_youngmc1"] = {
		label = "Jaket Young Mc Perempuan",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Young Mc tipe 1 untuk Perempuan",
	},


	["m_jackets_barong1"] = {
		label = "Jaket Barong Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Barong tipe 1 untuk pria",
	},

	["m_jackets_barong2"] = {
		label = "Jaket Barong Pria ( Variasi 2 )",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Barong tipe 2 untuk pria",
	},

	["m_jackets_barong3"] = {
		label = "Jaket Barong Pria ( Variasi 3 )",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Barong tipe 3 untuk pria",
	},

	["m_jackets_barong4"] = {
		label = "Jaket Barong Pria ( Variasi 4 )",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Barong tipe 4 untuk pria",
	},

	["m_jackets_barong5"] = {
		label = "Jaket Barong Pria ( Variasi 5 )",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Barong tipe 5 untuk pria",
	},

	["f_jackets_barong1"] = {
		label = "Jaket Barong Perempuan",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Barong tipe 1 untuk Perempuan",
	},

	["f_jackets_barong2"] = {
		label = "Jaket Barong Perempuan ( Variasi 2 )",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Barong tipe 2 untuk Perempuan",
	},

	["f_jackets_barong3"] = {
		label = "Jaket Barong Perempuan ( Variasi 3 )",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Barong tipe 3 untuk Perempuan",
	},

	["f_jackets_barong4"] = {
		label = "Jaket Barong Perempuan ( Variasi 4 )",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Barong tipe 4 untuk Perempuan",
	},

	["f_jackets_barong5"] = {
		label = "Jaket Barong Perempuan ( Variasi 5 )",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Barong tipe 5 untuk Perempuan",
	},




	---

	["m_bodyarmor_invamouz1_0"] = {
		label = "Body Armor Invamouz MC Pria ( Variasi 0 )",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Invamouz MC untuk pria",
	},

	["m_bodyarmor_invamouz1_1"] = {
		label = "Body Armor Invamouz MC Pria ( Variasi 1 )",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Invamouz MC untuk pria",
	},

	["m_bodyarmor_invamouz1_2"] = {
		label = "Body Armor Invamouz MC Pria ( Variasi 2 )",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Invamouz MC untuk pria",
	},

	["m_bodyarmor_invamouz1_3"] = {
		label = "Body Armor Invamouz MC Pria ( Variasi 3 )",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Invamouz MC untuk pria",
	},

	["m_bodyarmor_invamouz1_4"] = {
		label = "Body Armor Invamouz MC Pria ( Variasi 4 )",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Invamouz MC untuk pria",
	},

	["m_bodyarmor_invamouz1_5"] = {
		label = "Body Armor Invamouz MC Pria ( Variasi 5 )",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Invamouz MC untuk pria",
	},

	["m_bodyarmor_invamouz1_6"] = {
		label = "Body Armor Invamouz MC Pria ( Variasi 6 )",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Invamouz MC untuk pria",
	},

	["m_bodyarmor_invamouz1_7"] = {
		label = "Body Armor Invamouz MC Pria ( Variasi 7 )",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Invamouz MC untuk pria",
	},

	["m_bodyarmor_invamouz1_8"] = {
		label = "Body Armor Invamouz MC Pria ( Variasi 8 )",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Invamouz MC untuk pria",
	},


	["f_bodyarmor_invamouz1_0"] = {
		label = "Body Armor Invamouz MC Perempuan ( Variasi 0 )",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Invamouz MC untuk Perempuan",
	},

	["f_bodyarmor_invamouz1_1"] = {
		label = "Body Armor Invamouz MC Perempuan ( Variasi 1 )",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Invamouz MC untuk Perempuan",
	},

	["f_bodyarmor_invamouz1_2"] = {
		label = "Body Armor Invamouz MC Perempuan ( Variasi 2 )",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Invamouz MC untuk Perempuan",
	},

	["f_bodyarmor_invamouz1_3"] = {
		label = "Body Armor Invamouz MC Perempuan ( Variasi 3 )",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Invamouz MC untuk Perempuan",
	},

	["f_bodyarmor_invamouz1_4"] = {
		label = "Body Armor Invamouz MC Perempuan ( Variasi 4 )",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Invamouz MC untuk Perempuan",
	},

	["f_bodyarmor_invamouz1_5"] = {
		label = "Body Armor Invamouz MC Perempuan ( Variasi 5 )",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Invamouz MC untuk Perempuan",
	},

	["f_bodyarmor_invamouz1_6"] = {
		label = "Body Armor Invamouz MC Perempuan ( Variasi 6 )",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Invamouz MC untuk Perempuan",
	},

	["f_bodyarmor_invamouz1_7"] = {
		label = "Body Armor Invamouz MC Perempuan ( Variasi 7 )",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Invamouz MC untuk Perempuan",
	},

	["f_bodyarmor_invamouz1_8"] = {
		label = "Body Armor Invamouz MC Perempuan ( Variasi 8 )",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Invamouz MC untuk Perempuan",
	},






	["m_bodyarmor_omc2_0"] = {
		label = "Body Armor Unbeatless Pria (Variasi 1)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor OMC tipe 2 variasi 1 untuk pria",
	},
	["m_bodyarmor_omc2_1"] = {
		label = "Body Armor Unbeatless Pria (Variasi 2)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor OMC tipe 2 variasi 2 untuk pria",
	},
	["m_bodyarmor_omc2_2"] = {
		label = "Body Armor Unbeatless Pria (Variasi 3)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor OMC tipe 2 variasi 3 untuk pria",
	},
	["m_bodyarmor_omc2_3"] = {
		label = "Body Armor Unbeatless Pria (Variasi 4)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor OMC tipe 2 variasi 4 untuk pria",
	},
	["m_bodyarmor_omc2_4"] = {
		label = "Body Armor Unbeatless Pria (Variasi 5)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor OMC tipe 2 variasi 5 untuk pria",
	},
	["m_bodyarmor_omc2_5"] = {
		label = "Body Armor Unbeatless Pria (Variasi 6)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor OMC tipe 2 variasi 6 untuk pria",
	},
	["m_bodyarmor_omc2_6"] = {
		label = "Body Armor Unbeatless Pria (Variasi 7)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor OMC tipe 2 variasi 7 untuk pria",
	},
	["m_bodyarmor_omc2_7"] = {
		label = "Body Armor Unbeatless Pria (Variasi 8)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor OMC tipe 2 variasi 8 untuk pria",
	},

	["f_bodyarmor_omc2_0"] = {
		label = "Body Armor Unbeatless Wanita (Variasi 1)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor OMC tipe 2 variasi 1 untuk wanita",
	},
	["f_bodyarmor_omc2_1"] = {
		label = "Body Armor Unbeatless Wanita (Variasi 2)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor OMC tipe 2 variasi 2 untuk wanita",
	},
	["f_bodyarmor_omc2_2"] = {
		label = "Body Armor Unbeatless Wanita (Variasi 3)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor OMC tipe 2 variasi 3 untuk wanita",
	},
	["f_bodyarmor_omc2_3"] = {
		label = "Body Armor Unbeatless Wanita (Variasi 4)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor OMC tipe 2 variasi 4 untuk wanita",
	},
	["f_bodyarmor_omc2_4"] = {
		label = "Body Armor Unbeatless Wanita (Variasi 5)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor OMC tipe 2 variasi 5 untuk wanita",
	},
	["f_bodyarmor_omc2_5"] = {
		label = "Body Armor Unbeatless Wanita (Variasi 6)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor OMC tipe 2 variasi 6 untuk wanita",
	},
	["f_bodyarmor_omc2_6"] = {
		label = "Body Armor Unbeatless Wanita (Variasi 7)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor OMC tipe 2 variasi 7 untuk wanita",
	},
	["f_bodyarmor_omc2_7"] = {
		label = "Body Armor Unbeatless Wanita (Variasi 8)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor OMC tipe 2 variasi 8 untuk wanita",
	},

	["m_jackets_hsc1_0"] = {
		label = "Jaket HSC1 Pria (Hitam)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket HSC tipe 1 warna hitam untuk pria",
	},
	["m_jackets_hsc1_1"] = {
		label = "Jaket HSC1 Pria (Putih)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket HSC tipe 1 warna putih untuk pria",
	},
	["m_jackets_hsc2_0"] = {
		label = "Jaket HSC2 Pria (Hitam)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket HSC tipe 2 warna hitam untuk pria",
	},
	["m_jackets_hsc2_1"] = {
		label = "Jaket HSC2 Pria (Putih)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket HSC tipe 2 warna putih untuk pria",
	},
	["f_jackets_hsc1_0"] = {
		label = "Jaket HSC1 Wanita (Hitam)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket HSC tipe 1 warna hitam untuk wanita",
	},
	["f_jackets_hsc1_1"] = {
		label = "Jaket HSC1 Wanita (Putih)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket HSC tipe 1 warna putih untuk wanita",
	},
	["f_jackets_hsc2_0"] = {
		label = "Jaket HSC2 Wanita (Hitam)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket HSC tipe 2 warna hitam untuk wanita",
	},
	["f_jackets_hsc2_1"] = {
		label = "Jaket HSC2 Wanita (Putih)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket HSC tipe 2 warna putih untuk wanita",
	},

	["m_jackets_lfa1"] = {
		label = "Jaket LFA1 Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket LFA tipe 1 untuk pria",
	},

	["m_jackets_lfa2"] = {
		label = "Jaket LFA2 Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket LFA tipe 2 untuk pria",
	},

	["m_jackets_rb1"] = {
		label = "Jaket RB Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket RB untuk pria",
	},

	--- FEMALE JACKETS ---
	["f_jackets_wd1"] = {
		label = "Jaket WD1 Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket WD tipe 1 untuk wanita",
	},

	["f_jackets_wd2"] = {
		label = "Jaket WD2 Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket WD tipe 2 untuk wanita",
	},

	["f_jackets_bz1_0"] = {
		label = "Jaket BZ1 Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket BZ tipe 1 warna hitam untuk wanita",
	},

	["f_jackets_bz1_1"] = {
		label = "Jaket BZ1 Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket BZ tipe 1 warna abu-abu untuk wanita",
	},

	["f_jackets_bz1_2"] = {
		label = "Jaket BZ1 Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket BZ tipe 1 warna navy untuk wanita",
	},

	["f_jackets_bz2_0"] = {
		label = "Jaket BZ2 Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket BZ tipe 2 warna hitam untuk wanita",
	},

	["f_jackets_bz2_1"] = {
		label = "Jaket BZ2 Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket BZ tipe 2 warna abu-abu untuk wanita",
	},

	["f_jackets_bz2_2"] = {
		label = "Jaket BZ2 Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket BZ tipe 2 warna navy untuk wanita",
	},

	["f_jackets_bmc1_0"] = {
		label = "Jaket BMC1 Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket BMC tipe 1 warna hitam untuk wanita",
	},

	["f_jackets_bmc1_1"] = {
		label = "Jaket BMC1 Wanita (Abu-abu)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket BMC tipe 1 warna abu-abu untuk wanita",
	},

	["f_jackets_bmc2_0"] = {
		label = "Jaket BMC2 Wanita (Hitam)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket BMC tipe 2 warna hitam untuk wanita",
	},

	["f_jackets_bmc2_1"] = {
		label = "Jaket BMC2 Wanita (Abu-abu)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket BMC tipe 2 warna abu-abu untuk wanita",
	},

	["f_jackets_lfa1"] = {
		label = "Jaket LFA1 Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket LFA tipe 1 untuk wanita",
	},

	["f_jackets_lfa2"] = {
		label = "Jaket LFA2 Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket LFA tipe 2 untuk wanita",
	},

	["f_jackets_rb1"] = {
		label = "Jaket RB Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket RB untuk wanita",
	},

	-- ==================== BODY ARMOR ====================

	--- MALE BODY ARMOR ---
	["m_bodyarmor_wd1"] = {
		label = "Vest WD Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi taktis WD untuk pria",
	},

	["m_bodyarmor_bz1_0"] = {
		label = "Vest BZ1 Pria (Hitam)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi taktis BZ tipe 1 warna hitam untuk pria",
	},

	["m_bodyarmor_bz1_1"] = {
		label = "Vest BZ1 Pria (Abu-abu)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi taktis BZ tipe 1 warna abu-abu untuk pria",
	},

	["m_bodyarmor_bz1_2"] = {
		label = "Vest BZ1 Pria (Navy)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi taktis BZ tipe 1 warna navy untuk pria",
	},

	["m_bodyarmor_bmc1_0"] = {
		label = "Vest BMC1 Pria President",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi taktis BMC tipe 1 warna hitam untuk pria",
	},

	["m_bodyarmor_bmc1_1"] = {
		label = "Vest BMC1 Pria Vice President",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi taktis BMC tipe 1 warna abu-abu untuk pria",
	},

	["m_bodyarmor_bmc1_2"] = {
		label = "Vest BMC1 Pria Road Captain",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi taktis BMC tipe 1 warna navy untuk pria",
	},

	["m_bodyarmor_bmc1_3"] = {
		label = "Vest BMC1 Pria Secretary",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi taktis BMC tipe 1 warna hijau untuk pria",
	},

	["m_bodyarmor_bmc1_4"] = {
		label = "Vest BMC1 Pria Sgt At Arms",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi taktis BMC tipe 1 warna coklat untuk pria",
	},

	["m_bodyarmor_bmc1_5"] = {
		label = "Vest BMC1 Pria Punisher",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi taktis BMC tipe 1 warna putih untuk pria",
	},

	["m_bodyarmor_bmc1_6"] = {
		label = "Vest BMC1 Pria Member",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi taktis BMC tipe 1 warna merah untuk pria",
	},

	["m_bodyarmor_bmc1_7"] = {
		label = "Vest BMC1 Pria Prospect",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi taktis BMC tipe 1 warna biru untuk pria",
	},

	["m_bodyarmor_lfa1"] = {
		label = "Vest LFA Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi taktis LFA untuk pria",
	},

	["m_bodyarmor_rb1"] = {
		label = "Vest RB Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi taktis RB untuk pria",
	},

	--- FEMALE BODY ARMOR ---
	["f_bodyarmor_wd1"] = {
		label = "Vest WD Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi taktis WD untuk wanita",
	},

	["f_bodyarmor_bz1_0"] = {
		label = "Vest BZ1 Wanita (Hitam)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi taktis BZ tipe 1 warna hitam untuk wanita",
	},

	["f_bodyarmor_bz1_1"] = {
		label = "Vest BZ1 Wanita (Abu-abu)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi taktis BZ tipe 1 warna abu-abu untuk wanita",
	},

	["f_bodyarmor_bz1_2"] = {
		label = "Vest BZ1 Wanita (Navy)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi taktis BZ tipe 1 warna navy untuk wanita",
	},

	["f_bodyarmor_bmc1_0"] = {
		label = "Vest BMC1 Wanita President",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi taktis BMC tipe 1 warna hitam untuk wanita",
	},

	["f_bodyarmor_bmc1_1"] = {
		label = "Vest BMC1 Wanita Vice President",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi taktis BMC tipe 1 warna abu-abu untuk wanita",
	},

	["f_bodyarmor_bmc1_2"] = {
		label = "Vest BMC1 Wanita Road Captain",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi taktis BMC tipe 1 warna navy untuk wanita",
	},

	["f_bodyarmor_bmc1_3"] = {
		label = "Vest BMC1 Wanita Secretary",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi taktis BMC tipe 1 warna hijau untuk wanita",
	},

	["f_bodyarmor_bmc1_4"] = {
		label = "Vest BMC1 Wanita Sgt At Arms",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi taktis BMC tipe 1 warna coklat untuk wanita",
	},

	["f_bodyarmor_bmc1_5"] = {
		label = "Vest BMC1 Wanita Punisher",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi taktis BMC tipe 1 warna putih untuk wanita",
	},

	["f_bodyarmor_bmc1_6"] = {
		label = "Vest BMC1 Wanita Member",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi taktis BMC tipe 1 warna merah untuk wanita",
	},

	["f_bodyarmor_bmc1_7"] = {
		label = "Vest BMC1 Wanita Prospect",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi taktis BMC tipe 1 warna biru untuk wanita",
	},

	["f_bodyarmor_lfa1"] = {
		label = "Vest LFA Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi taktis LFA untuk wanita",
	},

	["m_bodyarmor_shinrai"] = {
		label = "Armor Shinrai Laki-laki",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi taktis",
	},

	["m_jackets_shinrai"] = {
		label = "Jacket Shinrai Laki-laki",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket",
	},

	["m_bags_shinrai"] = {
		label = "Samurai Shinrai Laki-laki",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "accs bags",
	},

	["f_bodyarmor_shinrai"] = {
		label = "Armor Shinrai Perempuan",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi taktis",
	},

	["f_jackets_shinrai"] = {
		label = "Jaket Shinrai Perempuan",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket",
	},

	["f_bags_shinrai"] = {
		label = "Samurai Shinrai Perempuan",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "accs bags",
	},

	['torture_kit'] = {
		label = 'Torture Kit',
		weight = 1000,
		stack = false,
		close = true,
	},
	['spraycan'] = {
        label = 'Spray Can',
        weight = 500,
    },
    ['sprayremover'] = {
        label = 'Spray Remover',
        weight = 100,
    },
	['tvremote'] = {
		label = 'TV Remote',
		weight = 200,
		degrade = 43200,
		stack = true,
		close = true,
		description = 'TV Remote',
	},
	['tvremote_reporter'] = {
		label = 'Remote Drive In',
		weight = 200,
		stack = true,
		close = true,
		description = 'Remote khusus Satu Media buat kontrol layar NTEAM Drive In',
		client = {
			image = 'tvremote.png',
		},
	},
	['remote_sksm'] = {
		label = 'Remote SKSM',
		weight = 200,
		stack = true,
		close = true,
		description = 'Remote khusus buat kontrol layar SKSM',
		client = {
			image = 'tvremote.png',
		},
	},
	['vehicletv'] = {
		label = 'Vehicle TV',
		weight = 200,
		stack = true,
		close = true,
		description = 'Vehicle TV',
	},

	["m_jackets_ht1"] = {
		label = "Jaket HT1 Laki-laki",
		weight = 10,
		stack = false,
		close = true,
		allowArmed = true,
		description = "Jaket casual untuk pria",
	},

	["m_jackets_ht2"] = {
		label = "Jaket HT2 Laki-laki",
		weight = 10,
		stack = false,
		close = true,
		allowArmed = true,
		description = "Jaket casual untuk pria",
	},

	["f_jackets_ht1_0"] = {
		label = "Jaket HT1 Wanita (Variasi 1)",
		weight = 10,
		stack = false,
		close = true,
		allowArmed = true,
		description = "Jaket casual untuk wanita",
	},

	["f_jackets_ht1_1"] = {
		label = "Jaket HT1 Wanita (Variasi 2)",
		weight = 10,
		stack = false,
		close = true,
		allowArmed = true,
		description = "Jaket casual untuk wanita",
	},

	["f_jackets_ht1_2"] = {
		label = "Jaket HT1 Wanita (Variasi 3)",
		weight = 10,
		stack = false,
		close = true,
		allowArmed = true,
		description = "Jaket casual untuk wanita",
	},

	["f_jackets_ht2"] = {
		label = "Jaket HT2 Wanita",
		weight = 10,
		stack = false,
		close = true,
		allowArmed = true,
		description = "Jaket casual untuk wanita",
	},

	['halloween_coin'] = {
        label = 'Koin Halloween',
        weight = 1,
        stack = true,
        close = true,
        description = 'Koin misterius dengan aura halloween',
        client = {
            image = 'halloween_coin.png'
        }
    },

    -- ['halloween_candy'] = {
    --     label = 'Permen Halloween',
    --     weight = 1,
    --     stack = true,
    --     close = true,
    --     description = 'Permen Event Halloween',
    --     client = {
    --         image = 'halloween_candy.png'
    --     }
    -- },

    ['halloween_ticket'] = {
        label = 'Tiket Pertunjukan',
        weight = 1,
        stack = true,
        close = true,
        description = 'Tiket untuk pertunjukan spesial halloween',
        client = {
            image = 'halloween_ticket.png'
        }
    },

	['jackolantern'] = {
		label = 'Jack O Lantern',
		weight = 100,
		stack = true,
		close = true,
		description = 'jackolantern',
	},

	['halloween_goldenpumpkin'] = {
		label = 'Golden Pumpkin',
		weight = 100,
		stack = true,
		close = true,
		description = 'drop rate bossmenu',
	},

	['weapon_chucky'] = {
		label = 'chucky Weapon',
		weight = 500,
		stack = true,
		close = true,
		description = 'Whitebeard\'s massive bisento'
	},

	['weapon_jasonvoorhees'] = {
		label = 'jason Weapon',
		weight = 500,
		stack = true,
		close = true,
		description = 'Whitebeard\'s massive bisento'
	},

	['weapon_leatherface_hammer'] = {
		label = 'hammer Weapon',
		weight = 500,
		stack = true,
		close = true,
		description = 'Whitebeard\'s massive bisento'
	},

	['weapon_leatherface_hatchet'] = {
		label = 'hatchet Weapon',
		weight = 500,
		stack = true,
		close = true,
		description = 'Whitebeard\'s massive bisento'
	},

	['weapon_michaelmyers'] = {
		label = 'michael Weapon',
		weight = 500,
		stack = true,
		close = true,
		description = 'Whitebeard\'s massive bisento'
	},

	['weapon_darthvader'] = {
		label = 'darthvader Weapon',
		weight = 500,
		stack = true,
		close = true,
		description = 'Whitebeard\'s massive bisento'
	},

	['weapon_scythe'] = {
		label = 'scythe Weapon',
		weight = 500,
		stack = true,
		close = true,
		description = 'Whitebeard\'s massive bisento'
	},

	["f_jackets_bxd1"] = {
		label = "Jaket BXD1 Perempuan",
		weight = 10,
		stack = false,
		close = true,
		allowArmed = true,
		description = "Jaket casual untuk wanita",
	},

	["f_jackets_bxd2"] = {
		label = "Jaket BXD2 Perempuan",
		weight = 10,
		stack = false,
		close = true,
		allowArmed = true,
		description = "Jaket casual untuk wanita",
	},

	["f_bodyarmor_bxd"] = {
		label = "Body Armor BXD Perempuan",
		weight = 10,
		stack = false,
		close = true,
		allowArmed = true,
		description = "Pelindung tubuh untuk wanita",
	},

	["m_jackets_bxd1"] = {
		label = "Jaket BXD1 Laki-laki",
		weight = 10,
		stack = false,
		close = true,
		allowArmed = true,
		description = "Jaket casual untuk pria",
	},

	["m_jackets_bxd2"] = {
		label = "Jaket BXD2 Laki-laki",
		weight = 10,
		stack = false,
		close = true,
		allowArmed = true,
		description = "Jaket casual untuk pria",
	},

	["m_bodyarmor_bxd"] = {
		label = "Body Armor BXD Laki-laki",
		weight = 10,
		stack = false,
		close = true,
		allowArmed = true,
		description = "Pelindung tubuh untuk pria",
	},

	['gulamerah'] = {
		label = 'Gula Merah',
		weight = 1,
		stack = true,
		close = true,
	},
	['thaiteasachet'] = {
		label = 'Thai Tea Sachet',
		weight = 1,
		stack = true,
		close = true,
	},
	['miekuning'] = {
		label = 'Mie Kuning',
		weight = 1,
		stack = true,
		close = true,
	},
	['tauge'] = {
		label = 'Tauge',
		weight = 1,
		stack = true,
		close = true,
	},
	['udang'] = {
		label = 'Udang',
		weight = 1,
		stack = true,
		close = true,
	},
	['oliangcoffee'] = {
		label = 'Oliang Coffee Sachet',
		weight = 1,
		stack = true,
		close = true,
	},
	['jamur'] = {
		label = 'Jamur',
		weight = 1,
		stack = true,
		close = true,
	},
	['syrup'] = {
		label = 'Syrup',
		weight = 1,
		stack = true,
		close = true,
	},
	['ikan'] = {
		label = 'Ikan',
		weight = 1,
		stack = true,
		close = true,
	},
	['kecapikan'] = {
		label = 'Kecap Ikan',
		weight = 1,
		stack = true,
		close = true,
	},
	['ticket_nc'] = {
		label = 'Nightclub Ticket',
		weight = 1,
		degrade = 720,
		stack = true,
		close = true,
	},
	['meteran_tanaman'] = {
		weight = 100,
		durability = 100,
		decay = true,
		stack = false,
		close = true,
		description = 'Untuk menanam tanaman secara otomatis, 1% daya tahan untuk menanam 1 tanaman',
	},

	['golden_coffee'] = {
		label = 'Golden Coffee',
		weight = 100,
		stack = true,
		close = true,
		description = 'A cup of Golden Coffee',
	},

	-- Teeth/Gigi
	["m_teef_gaviria"] = {
		label = "Gigi Gaviria Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Gigi khas Gaviria untuk pria",
	},

	["f_teef_gaviria"] = {
		label = "Gigi Gaviria Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Gigi khas Gaviria untuk wanita",
	},

	["m_teef_noctis"] = {
		label = "Kalung Noctis Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Kalung Noctis untuk pria",
	},

	["f_teef_noctis"] = {
		label = "Kalung Noctis Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Kalung Noctis untuk wanita",
	},

	-- Bags/Tas
	["m_bags_bfl"] = {
		label = "Tas Burgenk Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Tas khas Burgenk untuk pria",
	},

	["f_bags_bfl"] = {
		label = "Tas Burgenk Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Tas khas Burgenk untuk wanita",
	},

	-- Jackets/Jaket Bratva
	["m_jackets_brv1_0"] = {
		label = "Jaket Bratva 1 Pria (Hitam)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Bratva tipe 1 warna hitam untuk pria",
	},

	["m_jackets_brv1_1"] = {
		label = "Jaket Bratva 1 Pria (Putih)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Bratva tipe 1 warna putih untuk pria",
	},

	["m_jackets_brv2"] = {
		label = "Jaket Bratva 2 Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Bratva tipe 2 untuk pria",
	},

	["f_jackets_brv1_0"] = {
		label = "Jaket Bratva 1 Wanita (Hitam)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Bratva tipe 1 warna hitam untuk wanita",
	},

	["f_jackets_brv1_1"] = {
		label = "Jaket Bratva 1 Wanita (Putih)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Bratva tipe 1 warna putih untuk wanita",
	},

	["f_jackets_brv2"] = {
		label = "Jaket Bratva 2 Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Bratva tipe 2 untuk wanita",
	},

	-- Jackets/Jaket Gaviria
	["m_jackets_gvr"] = {
		label = "Jaket Gaviria Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket khas Gaviria untuk pria",
	},

	["f_jackets_gvr"] = {
		label = "Jaket Gaviria Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket khas Gaviria untuk wanita",
	},

	-- Jackets/Jaket Burgenk
	["m_jackets_bfl"] = {
		label = "Jaket Burgenk Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket khas Burgenk untuk pria",
	},

	["f_jackets_bfl"] = {
		label = "Jaket Burgenk Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket khas Burgenk untuk wanita",
	},

	-- Body Armor/Rompi Anti Peluru Bratva
	["m_bodyarmor_brv"] = {
		label = "Rompi Anti Peluru Bratva Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi anti peluru khas Bratva untuk pria",
	},

	["f_bodyarmor_brv"] = {
		label = "Rompi Anti Peluru Bratva Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi anti peluru khas Bratva untuk wanita",
	},

	-- Body Armor/Rompi Anti Peluru Gaviria
	["m_bodyarmor_gvr"] = {
		label = "Rompi Anti Peluru Gaviria Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi anti peluru khas Gaviria untuk pria",
	},

	["f_bodyarmor_gvr"] = {
		label = "Rompi Anti Peluru Gaviria Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi anti peluru khas Gaviria untuk wanita",
	},

	-- Body Armor/Rompi Anti Peluru Burgenk
	["m_bodyarmor_bfl"] = {
		label = "Rompi Anti Peluru Burgenk Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi anti peluru khas Burgenk untuk pria",
	},

	["f_bodyarmor_bfl"] = {
		label = "Rompi Anti Peluru Burgenk Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Rompi anti peluru khas Burgenk untuk wanita",
	},

	-- Male Items
	["m_pants_ggd"] = {
		label = "Celana GGD Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Celana seragam GGD untuk pria",
	},

	["m_jackets_gdp1"] = {
		label = "Jaket GDP1 Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket GDP tipe 1 untuk pria",
	},

	["m_jackets_ggd1"] = {
		label = "Jaket GGD1 Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket GGD tipe 1 untuk pria",
	},

	["m_jackets_cmc1"] = {
		label = "Jaket CMC1 Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket CMC tipe 1 untuk pria",
	},

	["m_jackets_ls1"] = {
		label = "Jaket LS1 Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket LS tipe 1 untuk pria",
	},

	["m_jackets_sdmc1"] = {
		label = "Jaket SDMC1 Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket SDMC tipe 1 untuk pria",
	},

	["m_bodyarmor_ggd"] = {
		label = "Body Armor GGD Pria",
		weight = 50,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor GGD untuk pria",
	},

	["m_bodyarmor_sdmc1_0"] = {
		label = "Body Armor SDMC1 Pria (Tipe 0)",
		weight = 50,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor SDMC tipe 1 varian 0 untuk pria",
	},

	["m_bodyarmor_sdmc1_1"] = {
		label = "Body Armor SDMC1 Pria (Tipe 1)",
		weight = 50,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor SDMC tipe 1 varian 1 untuk pria",
	},

	["m_bodyarmor_sdmc1_2"] = {
		label = "Body Armor SDMC1 Pria (Tipe 2)",
		weight = 50,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor SDMC tipe 1 varian 2 untuk pria",
	},

	["m_bodyarmor_sdmc1_3"] = {
		label = "Body Armor SDMC1 Pria (Tipe 3)",
		weight = 50,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor SDMC tipe 1 varian 3 untuk pria",
	},

	["m_bodyarmor_sdmc1_4"] = {
		label = "Body Armor SDMC1 Pria (Tipe 4)",
		weight = 50,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor SDMC tipe 1 varian 4 untuk pria",
	},

	["m_bodyarmor_sdmc1_5"] = {
		label = "Body Armor SDMC1 Pria (Tipe 5)",
		weight = 50,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor SDMC tipe 1 varian 5 untuk pria",
	},

	-- Female Items
	["f_pants_ggd"] = {
		label = "Celana GGD Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Celana seragam GGD untuk wanita",
	},

	["f_jackets_gdp1"] = {
		label = "Jaket GDP1 Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket GDP tipe 1 untuk wanita",
	},

	["f_jackets_ggd1"] = {
		label = "Jaket GGD1 Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket GGD tipe 1 untuk wanita",
	},

	["f_jackets_cmc1"] = {
		label = "Jaket CMC1 Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket CMC tipe 1 untuk wanita",
	},

	["f_jackets_ls1"] = {
		label = "Jaket LS1 Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket LS tipe 1 untuk wanita",
	},

	["f_jackets_sdmc1"] = {
		label = "Jaket SDMC1 Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket SDMC tipe 1 untuk wanita",
	},

	["f_bodyarmor_ggd"] = {
		label = "Body Armor GGD Wanita",
		weight = 50,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor GGD untuk wanita",
	},

	["f_bodyarmor_sdmc1_0"] = {
		label = "Body Armor SDMC1 Wanita (Tipe 0)",
		weight = 50,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor SDMC tipe 1 varian 0 untuk wanita",
	},

	["f_bodyarmor_sdmc1_1"] = {
		label = "Body Armor SDMC1 Wanita (Tipe 1)",
		weight = 50,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor SDMC tipe 1 varian 1 untuk wanita",
	},

	["f_bodyarmor_sdmc1_2"] = {
		label = "Body Armor SDMC1 Wanita (Tipe 2)",
		weight = 50,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor SDMC tipe 1 varian 2 untuk wanita",
	},

	["f_bodyarmor_sdmc1_3"] = {
		label = "Body Armor SDMC1 Wanita (Tipe 3)",
		weight = 50,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor SDMC tipe 1 varian 3 untuk wanita",
	},

	["f_bodyarmor_sdmc1_4"] = {
		label = "Body Armor SDMC1 Wanita (Tipe 4)",
		weight = 50,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor SDMC tipe 1 varian 4 untuk wanita",
	},

	["f_bodyarmor_sdmc1_5"] = {
		label = "Body Armor SDMC1 Wanita (Tipe 5)",
		weight = 50,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor SDMC tipe 1 varian 5 untuk wanita",
	},

	["m_bodyarmor_sdmc1_6"] = {
		label = "Body Armor SDMC1 Pria (Tipe 6)",
		weight = 50,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor SDMC tipe 1 varian 6 untuk pria",
	},
	["m_bodyarmor_sdmc1_7"] = {
		label = "Body Armor SDMC1 Pria (Tipe 7)",
		weight = 50,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor SDMC tipe 1 varian 7 untuk pria",
	},
	["m_bodyarmor_sdmc1_8"] = {
		label = "Body Armor SDMC1 Pria (Tipe 8)",
		weight = 50,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor SDMC tipe 1 varian 8 untuk pria",
	},
	["m_bodyarmor_wtmc1_0"] = {
		label = "Body Armor WTMC1 Pria (Tipe 0)",
		weight = 50,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor WTMC tipe 1 varian 0 untuk pria",
	},
	["m_bodyarmor_wtmc1_1"] = {
		label = "Body Armor WTMC1 Pria (Tipe 1)",
		weight = 50,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor WTMC tipe 1 varian 1 untuk pria",
	},
	["m_bodyarmor_wtmc1_2"] = {
		label = "Body Armor WTMC1 Pria (Tipe 2)",
		weight = 50,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor WTMC tipe 1 varian 2 untuk pria",
	},
	["m_bodyarmor_wtmc1_3"] = {
		label = "Body Armor WTMC1 Pria (Tipe 3)",
		weight = 50,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor WTMC tipe 1 varian 3 untuk pria",
	},
	["m_bodyarmor_wtmc1_4"] = {
		label = "Body Armor WTMC1 Pria (Tipe 4)",
		weight = 50,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor WTMC tipe 1 varian 4 untuk pria",
	},
	["m_bodyarmor_wtmc1_5"] = {
		label = "Body Armor WTMC1 Pria (Tipe 5)",
		weight = 50,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor WTMC tipe 1 varian 5 untuk pria",
	},
	["m_bodyarmor_wtmc1_6"] = {
		label = "Body Armor WTMC1 Pria (Tipe 6)",
		weight = 50,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor WTMC tipe 1 varian 6 untuk pria",
	},
	["m_bodyarmor_wtmc1_7"] = {
		label = "Body Armor WTMC1 Pria (Tipe 7)",
		weight = 50,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor WTMC tipe 1 varian 7 untuk pria",
	},
	["m_bodyarmor_wtmc1_8"] = {
		label = "Body Armor WTMC1 Pria (Tipe 8)",
		weight = 50,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor WTMC tipe 1 varian 8 untuk pria",
	},
	["m_bodyarmor_wtmc1_9"] = {
		label = "Body Armor WTMC1 Pria (Tipe 9)",
		weight = 50,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor WTMC tipe 1 varian 9 untuk pria",
	},
	["m_bodyarmor_wtmc1_10"] = {
		label = "Body Armor WTMC1 Pria (Tipe 10)",
		weight = 50,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor WTMC tipe 1 varian 10 untuk pria",
	},
	["f_bodyarmor_sdmc1_6"] = {
		label = "Body Armor SDMC1 Wanita (Tipe 6)",
		weight = 50,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor SDMC tipe 1 varian 6 untuk wanita",
	},
	["f_bodyarmor_sdmc1_7"] = {
		label = "Body Armor SDMC1 Wanita (Tipe 7)",
		weight = 50,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor SDMC tipe 1 varian 7 untuk wanita",
	},
	["f_bodyarmor_sdmc1_8"] = {
		label = "Body Armor SDMC1 Wanita (Tipe 8)",
		weight = 50,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor SDMC tipe 1 varian 8 untuk wanita",
	},
	["f_bodyarmor_wtmc1_0"] = {
		label = "Body Armor WTMC1 Wanita (Tipe 0)",
		weight = 50,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor WTMC tipe 1 varian 0 untuk wanita",
	},
	["f_bodyarmor_wtmc1_1"] = {
		label = "Body Armor WTMC1 Wanita (Tipe 1)",
		weight = 50,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor WTMC tipe 1 varian 1 untuk wanita",
	},
	["f_bodyarmor_wtmc1_2"] = {
		label = "Body Armor WTMC1 Wanita (Tipe 2)",
		weight = 50,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor WTMC tipe 1 varian 2 untuk wanita",
	},
	["f_bodyarmor_wtmc1_3"] = {
		label = "Body Armor WTMC1 Wanita (Tipe 3)",
		weight = 50,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor WTMC tipe 1 varian 3 untuk wanita",
	},
	["f_bodyarmor_wtmc1_4"] = {
		label = "Body Armor WTMC1 Wanita (Tipe 4)",
		weight = 50,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor WTMC tipe 1 varian 4 untuk wanita",
	},
	["f_bodyarmor_wtmc1_5"] = {
		label = "Body Armor WTMC1 Wanita (Tipe 5)",
		weight = 50,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor WTMC tipe 1 varian 5 untuk wanita",
	},
	["f_bodyarmor_wtmc1_6"] = {
		label = "Body Armor WTMC1 Wanita (Tipe 6)",
		weight = 50,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor WTMC tipe 1 varian 6 untuk wanita",
	},
	["f_bodyarmor_wtmc1_7"] = {
		label = "Body Armor WTMC1 Wanita (Tipe 7)",
		weight = 50,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor WTMC tipe 1 varian 7 untuk wanita",
	},
	["f_bodyarmor_wtmc1_8"] = {
		label = "Body Armor WTMC1 Wanita (Tipe 8)",
		weight = 50,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor WTMC tipe 1 varian 8 untuk wanita",
	},
	["f_bodyarmor_wtmc1_9"] = {
		label = "Body Armor WTMC1 Wanita (Tipe 9)",
		weight = 50,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor WTMC tipe 1 varian 9 untuk wanita",
	},
	["f_bodyarmor_wtmc1_10"] = {
		label = "Body Armor WTMC1 Wanita (Tipe 10)",
		weight = 50,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor WTMC tipe 1 varian 10 untuk wanita",
	},
	["m_jackets_sdmc2"] = {
		label = "Jaket SDMC2 Pria",
		weight = 30,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket SDMC tipe 2 untuk pria",
	},
	["m_jackets_wtmc1"] = {
		label = "Jaket WTMC1 Pria",
		weight = 30,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket WTMC tipe 1 untuk pria",
	},
	["m_jackets_blackjack1"] = {
		label = "Jaket Blackjack Pria (Tipe 1)",
		weight = 30,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Blackjack tipe 1 untuk pria",
	},
	["m_jackets_blackjack2"] = {
		label = "Jaket Blackjack Pria (Tipe 2)",
		weight = 30,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Blackjack tipe 2 untuk pria",
	},
	["m_jackets_blackjack3"] = {
		label = "Jaket Blackjack Pria (Tipe 3)",
		weight = 30,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Blackjack tipe 3 untuk pria",
	},
	["m_jackets_blackjack4"] = {
		label = "Jaket Blackjack Pria (Tipe 4)",
		weight = 30,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Blackjack tipe 4 untuk pria",
	},
	["f_jackets_sdmc2"] = {
		label = "Jaket SDMC2 Wanita",
		weight = 30,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket SDMC tipe 2 untuk wanita",
	},
	["f_jackets_wtmc1"] = {
		label = "Jaket WTMC1 Wanita",
		weight = 30,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket WTMC tipe 1 untuk wanita",
	},
	["f_jackets_blackjack1"] = {
		label = "Jaket Blackjack Wanita (Tipe 1)",
		weight = 30,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Blackjack tipe 1 untuk wanita",
	},
	["f_jackets_blackjack2"] = {
		label = "Jaket Blackjack Wanita (Tipe 2)",
		weight = 30,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Blackjack tipe 2 untuk wanita",
	},
	["f_jackets_blackjack3"] = {
		label = "Jaket Blackjack Wanita (Tipe 3)",
		weight = 30,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Blackjack tipe 3 untuk wanita",
	},
	["f_jackets_blackjack4"] = {
		label = "Jaket Blackjack Wanita (Tipe 4)",
		weight = 30,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Blackjack tipe 4 untuk wanita",
	},

	["m_bodyarmor_omc1_0"] = {
		label = "Body Armor OMC1 Pria (Tipe 0)",
		weight = 30,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor OMC1 tipe 0 untuk pria",
	},

	["m_bodyarmor_omc1_1"] = {
		label = "Body Armor OMC1 Pria (Tipe 1)",
		weight = 30,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor OMC1 tipe 1 untuk pria",
	},

	["m_bodyarmor_omc1_2"] = {
		label = "Body Armor OMC1 Pria (Tipe 2)",
		weight = 30,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor OMC1 tipe 2 untuk pria",
	},

	["m_bodyarmor_omc1_3"] = {
		label = "Body Armor OMC1 Pria (Tipe 3)",
		weight = 30,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor OMC1 tipe 3 untuk pria",
	},

	["m_bodyarmor_omc1_4"] = {
		label = "Body Armor OMC1 Pria (Tipe 4)",
		weight = 30,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor OMC1 tipe 4 untuk pria",
	},

	["f_bodyarmor_omc1_0"] = {
		label = "Body Armor OMC1 Wanita (Tipe 0)",
		weight = 30,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor OMC1 tipe 0 untuk wanita",
	},

	["f_bodyarmor_omc1_1"] = {
		label = "Body Armor OMC1 Wanita (Tipe 1)",
		weight = 30,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor OMC1 tipe 1 untuk wanita",
	},

	["f_bodyarmor_omc1_2"] = {
		label = "Body Armor OMC1 Wanita (Tipe 2)",
		weight = 30,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor OMC1 tipe 2 untuk wanita",
	},

	["f_bodyarmor_omc1_3"] = {
		label = "Body Armor OMC1 Wanita (Tipe 3)",
		weight = 30,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor OMC1 tipe 3 untuk wanita",
	},

	["f_bodyarmor_omc1_4"] = {
		label = "Body Armor OMC1 Wanita (Tipe 4)",
		weight = 30,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor OMC1 tipe 4 untuk wanita",
	},



	["m_jackets_fsg1"] = {
		label = "Jaket FSG Pria",
		weight = 30,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket FSG tipe 1 untuk Pria",
	},

	["m_jackets_vanity1"] = {
		label = "Jaket Vanity Pria",
		weight = 30,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Vanity tipe 1 untuk Pria",
	},

	["m_jackets_umc1"] = {
		label = "Jaket UMC Pria",
		weight = 30,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket UMC tipe 1 untuk Pria",
	},

	["f_jackets_fsg1"] = {
		label = "Jaket FSG Wanita",
		weight = 30,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket FSG tipe 1 untuk wanita",
	},

	["f_jackets_vanity1"] = {
		label = "Jaket Vanity Wanita",
		weight = 30,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Vanity tipe 1 untuk wanita",
	},

	["f_jackets_umc1"] = {
		label = "Jaket UMC Wanita",
		weight = 30,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket UMC tipe 1 untuk wanita",
	},

	---@burgenk_cafe_item
	daging = {
		label = 'Daging',
		weight = 100,
	},
	sauce = {
		label = 'Sauce',
		weight = 100
	},
	teh_saset = {
		label = 'Teh Saset',
		weight = 100
	},
	cinnamon = {
		label = 'Cinnamon',
		weight = 100
	},
	burger_buns = {
		label = 'Burger Buns',
		weight = 100
	},
	skm = {
		label = 'Susu kental manis',
		weight = 100
	},
	keju = {
		label = 'Keju',
		weight = 100
	},
	lada = {
		label = 'Lada',
		weight = 100
	},
	sirup_melon = {
		label = 'Sirup melon',
		weight = 100
	},
	biji_selasih = {
		label = 'Biji selasih',
		weight = 100
	},
	tepung = {
		label = 'Tepung',
		weight = 100
	},
	butter = {
		label = 'Butter',
		weight = 100
	},
	creamy = {
		label = 'Creamy',
		weight = 100
	},
	strawberry = {
		label = 'Buah strawberry',
		weight = 100
	},
	soda = {
		label = 'Soda',
		weight = 100
	},
	salmon = {
		label = 'Salmon',
		weight = 100
	},
	almond = {
		label = 'Almond',
		weight = 100
	},
	milosachet = {
		label = 'Milosachet',
		weight = 100
	},
	--paradisedelightbahan
	matchapowder = {
		label = 'Matcha Powder',
		weight = 100
	},
	greentea = {
		label = 'Green Tea',
		weight = 100
	},
	baconbeef = {
		label = 'Bacon Beef',
		weight = 100
	},
	multigrainmix = {
		label = 'Multigrain Mix',
		weight = 100
	},
	gurita = {
		label = 'Gurita',
		weight = 100
	},

	nasi_padang = {
		label = 'Nasi padang',
		degrade = 4320,
		weight = 100,
		description = 'Makanan khas 969'
	},
	mie_aceh = {
		label = 'Mie Aceh',
		degrade = 4320,
		weight = 100,
		description = 'Makanan khas 969'
	},
	batagor = {
		label = 'Batagor',
		degrade = 4320,
		weight = 100,
		description = 'Makanan khas 969'
	},
	es_kopi_sanger = {
		label = 'Es kopi sanger',
		degrade = 4320,
		weight = 100,
		description = 'Makanan khas 969'
	},
	es_doger = {
		label = 'Es doger',
		degrade = 4320,
		weight = 100,
		description = 'Makanan khas 969'
	},
	teh_tarik = {
		label = 'Teh tarik',
		degrade = 4320,
		weight = 100,
		description = 'Makanan khas 969'
	},
	burger_rendang = {
		label = 'Burger rendang',
		degrade = 4320,
		weight = 100,
		description = 'Makanan khas 969'
	},
	es_susu_jagung = {
		label = 'Es susu jagung',
		degrade = 4320,
		weight = 100,
		description = 'Makanan khas 969'
	},
	sop_buntut = {
		label = 'Sop buntut',
		degrade = 4320,
		weight = 100,
		description = 'Makanan khas 969'
	},
	es_timun_serut = {
		label = 'Es timun serut',
		degrade = 4320,
		weight = 100,
		description = 'Makanan khas 969'
	},
    soto_medan = {
		label = 'Soto Medan',
		degrade = 4320,
		weight = 100,
		description = 'Makanan khas 969'
	},
    jus_markisa = {
		label = 'Jus Markisa',
		degrade = 4320,
		weight = 100,
		description = 'Makanan khas 969'
	},
	chocolate_love = {
		label = 'Chocolate Love',
		degrade = 4320,
		weight = 100,
		description = 'Makanan khas 969'
	},
	ice_cream = {
		label = 'Ice cream',
		degrade = 4320,
		weight = 100,
		description = 'Makanan khas 969'
	},
    buah_markisa = {
		label = 'Markisa',
		weight = 100
	},

	['fishing_rod_redcrab'] = {
		label = 'Pancingan Red Crab',
		degrade = 10080,
		description = 'Pancingan V2',
		weight = 500,
		stack = false,
		client = {
			export = 'sm_netfish.rod',
		},
	},

	['fishing_rod_greencrocodile'] = {
		label = 'Pancingan Green Crocodile',
		degrade = 10080,
		description = 'Pancingan V2',
		weight = 500,
		stack = false,
		client = {
			export = 'sm_netfish.rod',
		},
	},

	['fishing_rod_pinkshark'] = {
		label = 'Pancingan Pink Shark',
		degrade = 10080,
		description = 'Pancingan V2',
		weight = 500,
		stack = false,
		client = {
			export = 'sm_netfish.rod',
		},
	},

	['fishing_rod_yellowseahorse'] = {
		label = 'Pancingan Yellow Seahorse',
		degrade = 10080,
		description = 'Pancingan V2',
		weight = 500,
		stack = false,
		client = {
			export = 'sm_netfish.rod',
		},
	},

	['fishing_rod_normal'] = {
		label = 'Pancingan Normal',
		degrade = 10080,
		description = 'Pancingan level 1',
		weight = 500,
		stack = false,
		client = {
			export = 'sm_netfish.rod',
		},
	},

	['fishing_rod_sport'] = {
		label = 'Pancingan Sport',
		degrade = 10080,
		description = 'Pancingan level 2',
		weight = 500,
		stack = false,
		client = {
			export = 'sm_netfish.rod',
		},
	},

	['fishing_rod_advanced'] = {
		label = 'Pancingan Advanced',
		degrade = 10080,
		description = 'Pancingan level 3',
		stack = false,
		weight = 500,
		client = {
			export = 'sm_netfish.rod',
		},
	},

	['fishing_rod_super'] = {
		label = 'Pancingan Super',
		degrade = 10080,
		description = 'Pancingan level 4',
		weight = 500,
		stack = false,
		client = {
			export = 'sm_netfish.rod',
		},
	},

	['fish1'] = {
		label = 'PstrÄ…g',
		weight = 250,
		stack = true,
		rarity = 'common',
	},

	['fish2'] = {
		label = 'Dorada',
		weight = 250,
		stack = true,
		rarity = 'rare',
	},

	['fish5'] = {
		label = 'Rocio Octafasciata',
		weight = 250,
		stack = true,
		rarity = 'rare',
	},

	['fish6'] = {
		label = 'Danio',
		weight = 250,
		stack = true,
		rarity = 'rare',
	},

	['corn_bait'] = {
		label = 'Corn Fishing Bait',
		weight = 50,
		stack = true,
		client = {
			export = 'sm_netfish.bait',
		},
	},

	['crab_bait'] = {
		label = 'Crab Fishing Bait',
		weight = 50,
		stack = true,
		client = {
			export = 'sm_netfish.bait',
		},
	},

	['dot_bait'] = {
		label = 'Dot Fishing Bait',
		weight = 50,
		stack = true,
		client = {
			export = 'sm_netfish.bait',
		},
	},

	['redline_bait'] = {
		label = 'Redline Fishing Bait',
		weight = 50,
		stack = true,
		client = {
			export = 'sm_netfish.bait',
		},
	},

	['shrimp_bait'] = {
		label = 'Shrimp Fishing Bait',
		weight = 50,
		stack = true,
		client = {
			export = 'sm_netfish.bait',
		},
	},

	['black_mamba'] = {
		label = 'Black Mamba Fishing Bait',
		weight = 50,
		stack = true,
		client = {
			export = 'sm_netfish.bait',
		},
	},

	['golden_fish_bait'] = {
		label = 'Golden Fish Bait',
		weight = 50,
		stack = true,
		client = {
			export = 'sm_netfish.bait',
		},
	},


	-- ['diving_gear'] = {
	-- 	label = 'Diving Gear',
	-- 	weight = 50,
	-- 	stack = true,
	-- 	client = {
	-- 		export = 'sm_netfish.divingGear',
	-- 	},
	-- },

	['treasure_shovel'] = {
		label = 'Shovel',
		weight = 50,
		stack = true,
		client = {
			export = 'sm_netfish.shovel',
		},
	},

	['lucky_hat'] = {
		label = 'Lucky Hat',
		weight = 500,
		stack = false,
			client = {
			export = 'sm_netfish.useClothingItemHappy',
		},
	},

	['water_meter'] = {
		label = 'Meter',
		weight = 500,
		stack = false,
			client = {
			export = 'sm_netfish.GetSeaLevel',
		},
	},

	['dry_station'] = {
		label = 'Dry Station',
		weight = 500,
		stack = false,
			client = {
			export = 'sm_netfish.createStation',
		},
	},

	['carp'] = {
		label = 'Carp',
		weight = 250,
		stack = true,
		rarity = 'common',
	},

	['crab'] = {
		label = 'Crab',
		weight = 250,
		stack = true,
		rarity = 'common',
	},

	['catfish'] = {
		label = 'Catfish',
		weight = 250,
		stack = true,
		rarity = 'common',
	},

	['fish3'] = {
		label = 'Certa',
		weight = 250,
		stack = true,
		rarity = 'common',
	},

	['tarpon'] = {
		label = 'Tarpon',
		weight = 250,
		stack = true,
		rarity = 'common',
	},

	['barracuda'] = {
		label = 'Barracuda',
		weight = 250,
		stack = true,
		rarity = 'rare',
	},

	['discus'] = {
		label = 'Discus',
		weight = 250,
		stack = true,
		rarity = 'rare',
	},

	['snapper'] = {
		label = 'Snapper',
		weight = 250,
		stack = true,
		rarity = 'rare',
	},

	['sturgeon'] = {
		label = 'Sturgeon',
		weight = 250,
		stack = true,
		rarity = 'rare',
	},

	['mojarra_fish'] = {
		label = 'Mojarra',
		weight = 250,
		stack = true,
		rarity = 'rare',
	},

	['fish4'] = {
		label = 'Maingano',
		weight = 250,
		stack = true,
		rarity = 'mythical',
	},

	['bocachico_fish'] = {
		label = 'Bocachico',
		weight = 250,
		stack = true,
		rarity = 'mythical',
	},

	['disco_fish'] = {
		label = 'Disco Fish',
		weight = 250,
		stack = true,
		rarity = 'mythical',
	},

	['koi_fish'] = {
		label = 'Koi Fish',
		weight = 250,
		stack = true,
		rarity = 'mythical',
	},

	['angelfishemperror'] = {
		label = 'Angel Fish Emperror',
		weight = 250,
		stack = true,
		rarity = 'legendary',
	},

	['crystal_catfish'] = {
		label = 'Crystal Catfish',
		weight = 250,
		stack = true,
		rarity = 'legendary',
	},

	['flying_fish'] = {
		label = 'Flying Fish',
		weight = 250,
		stack = true,
		rarity = 'legendary',
	},
	['bzzz_fishing_turtle_a'] = {
		label = 'Turtle',
		weight = 250,
		stack = true,
		rarity = 'legendary',
	},
	['bzzz_fishing_lobster_a'] = {
		label = 'Lobster',
		weight = 250,
		stack = true,
		rarity = 'mythical',
	},
	['bzzz_fishing_fish_7_b'] = {
		label = 'European Plaice',
		weight = 250,
		stack = true,
		rarity = 'rare',
	},
	['bzzz_fishing_fish_2_b'] = {
		label = 'Salmon',
		weight = 250,
		stack = true,
		rarity = 'rare',
	},
	['bzzz_fishing_starfish_a'] = {
		label = 'Starfish',
		weight = 250,
		stack = true,
		rarity = 'rare',
	},
	['bzzz_fishing_urchin_a'] = {
		label = 'Sea Urchin',
		weight = 250,
		stack = true,
		rarity = 'common',
	},
	['bzzz_fishing_shell_c'] = {
		label = 'Empty Shells',
		weight = 250,
		stack = true,
		rarity = 'common',
	},
	-- ['bzzz_fishing_fish_15'] = {
	-- 	label = 'Hammerhead',
	-- 	weight = 250,
	-- 	stack = true,
	-- 	rarity = 'legendary',
	-- },
	['bzzz_fishing_octopus_a'] = {
		label = 'Octopus',
		weight = 250,
		stack = true,
		rarity = 'legendary',
	},
	['bzzz_fishing_fish_4_a'] = {
		label = 'Tuna',
		weight = 250,
		stack = true,
		rarity = 'legendary',
	},

	['hammerhead'] = {
		label = 'Hammerhead',
		weight = 250,
		stack = true,
		rarity = 'divine',
	},
	['nkfishing_megalodon'] = {
		label = 'Megalodon',
		weight = 250,
		stack = true,
		rarity = 'divine',
	},
	['nkfishing_kraken'] = {
		label = 'Kraken',
		weight = 250,
		stack = true,
		rarity = 'divine',
	},
	['nkfishing_orca'] = {
		label = 'Orca',
		weight = 250,
		stack = true,
		rarity = 'divine',
	},

	['shoe_shit'] = {
		label = 'Boot',
		weight = 500,
		stack = true,
	},

	['anchor'] = {
		label = 'Anchor',
		weight = 1500,
		stack = false,
		client = {
			export = 'sm_netfish.ToggleAnchor',
		},
	},


	['fishing_net'] = {
		label = 'Fishing Net',
		weight = 500,
		stack = false,
		client = {
			export = 'sm_netfish.createNet',
		},
	},



	['fishing_net_plus'] = {
		label = 'Fishing Net++',
		weight = 500,
		stack = false,
		client = {
			export = 'sm_netfish.createNet',
		},
	},

	['crab_cage'] = {
		label = 'Crab Cage',
		weight = 500,
		stack = false,
		client = {
			export = 'sm_netfish.createCage',
		},
	},



	['crab_cage_plus'] = {
		label = 'Crab Cage++',
		weight = 500,
		stack = false,
		client = {
			export = 'sm_netfish.createCage',
		},
	},

	["elfanberry"] = {
		label = "Elfanberry",
		weight = 100,
		stack = true,
		close = true,
		description = "Buah elf langka yang bercahaya redup",
	},
	["elfblood"] = {
		label = "Elf Blood",
		weight = 100,
		stack = true,
		close = true,
		description = "Darah elf murni",
	},
	["kristaldust"] = {
		label = "Kristal Dust",
		weight = 100,
		stack = true,
		close = true,
		description = "Serbuk kristal berkilau untuk ramuan",
	},
	["moonleaf"] = {
		label = "Moon Leaf",
		weight = 100,
		stack = true,
		close = true,
		description = "Daun yang hanya tumbuh di bawah cahaya bulan",
	},
	["moonwater"] = {
		label = "Moon Water",
		weight = 100,
		stack = true,
		close = true,
		description = "Air suci yang menyerap sinar rembulan",
	},
	["purification_potion"] = {
		label = "Purification Potion",
		weight = 100,
		stack = true,
		close = true,
		description = "Ramuan",
	},
	["silverwood"] = {
		label = "Silverwood",
		weight = 100,
		stack = true,
		close = true,
		description = "Kayu perak keras",
	},
	["starflower"] = {
		label = "Starflower",
		weight = 100,
		stack = true,
		close = true,
		description = "Bunga bintang yang mekar di malam hari",
	},

	["blood_potion"] = {
		label = "Blood Potion",
		weight = 100,
		stack = true,
		close = true,
		description = "Run booster",
	},

	["nightdew_potion"] = {
		label = "Nightdew Potion",
		weight = 100,
		stack = true,
		close = true,
		description = "Poison dew",
	},

	["blood_pfesence"] = {
		label = "Blood Purifying Essence",
		weight = 100,
		stack = true,
		close = true,
		description = "Poison purifying essence",
	},

	['paketmakanan'] = {
		label = 'Paket Makanan',
		weight = 100,
		stack = true,
		close = true,
		description = 'Paket berisi makanan dan minuman',
	},
	['box_makanan'] = {
		label = 'Paket Makanan Nusantara',
		weight = 100,
		stack = true,
		close = true,
		description = 'Paket berisi makanan dan minuman',
		client = {
			export = 'sm_resource_1.openPackage'
		}
	},
	-- PAKET NUSANTARA RESTO
	['paket_sate'] = {
		label = 'Paket Sate Nusantara',
		weight = 10,
		stack = true,
		close = true,
		description = 'Paket berisi makanan dan minuman',
		degrade = 2880, -- 2 hari
		client = {
			image = "paketbox.png",
			export = 'sm_resource_1.openPackage'
		}
	},
	['paket_gudeg'] = {
		label = 'Paket Gudeg Nusantara',
		weight = 10,
		stack = true,
		close = true,
		description = 'Paket berisi makanan dan minuman',
		degrade = 2880,
		client = {
			image = "paketbox.png",
			export = 'sm_resource_1.openPackage'
		}
	},
	['paket_nasilemak'] = {
		label = 'Paket Nasilemak Nusantara',
		weight = 10,
		stack = true,
		close = true,
		description = 'Paket berisi makanan dan minuman',
		degrade = 2880,
		client = {
			export = 'sm_resource_1.openPackage'
		}
	},
	['paket_baksoesteh'] = {
		label = 'Paket Bakso Nusantara',
		weight = 10,
		stack = true,
		close = true,
		description = 'Paket berisi makanan dan minuman',
		degrade = 2880,
		client = {
			image = "paketbox.png",
			export = 'sm_resource_1.openPackage'
		}
	},
	['paket_mieaceh'] = {
		label = 'Paket Mie Aceh',
		weight = 10,
		stack = true,
		close = true,
		description = 'Paket berisi makanan dan minuman',
		degrade = 2880,
		client = {
			image = "paketbox.png",
			export = 'sm_resource_1.openPackage'
		}
	},
	['paket_kidsmeal_bubur'] = {
		label = 'Paket Kids Meal Bubur Ayam',
		weight = 10,
		stack = true,
		close = true,
		description = 'Paket berisi makanan dan minuman',
		degrade = 2880,
		client = {
			image = "paketanaktom.png",
			export = 'sm_resource_1.openPackage',
		}
	},
	['paket_cemilan_nusantara'] = {
		label = 'Paket Cemilan Nusantara',
		weight = 10,
		stack = true,
		close = true,
		description = 'Paket berisi siomay dan sop buah',
		degrade = 2880,
		client = {
			image = "paketbox.png",
			export = 'sm_resource_1.openPackage',
		}
	},

    ['paket_kidsmeal_cslider'] = {
		label = 'Paket Kids Meal Chicken Slider',
		weight = 10,
		stack = true,
		close = true,
		description = 'Paket berisi makanan dan minuman',
		degrade = 2880,
		client = {
			image = "paketanaktom.png",
			export = 'sm_resource_1.openPackage',
		}
	},

	['paket_cemilan_kkp'] = {
		label = 'Paket Cemilan KKP',
		weight = 10,
		stack = true,
		close = true,
		description = 'Paket berisi chewy cookie kimpul dan ice cream matcha',
		degrade = 2880,
		client = {
			image = "paketbox.png",
			export = 'sm_resource_1.openPackage',
		}
	},

-- PAKET Atom
	['paket_atomwings'] = {
		label = 'ATOM WINGS BOX',
		weight = 10,
		stack = true,
		close = true,
		description = 'Paket berisi makanan dan minuman',
		degrade = 2880,
		client = {
			image = "paketnormaltom.png",
			export = 'sm_resource_1.openPackage'
		}
	},
	['paket_sandwichtom'] = {
		label = 'ATOM SANDWICH PACK',
		weight = 10,
		stack = true,
		close = true,
		description = 'Paket berisi makanan dan minuman',
		degrade = 2880,
		client = {
			image = "paketnormaltom.png",
			export = 'sm_resource_1.openPackage'
		}
	},
	['paket_omeletetom'] = {
		label = 'ATOM OMELETTE MEAL',
		weight = 10,
		stack = true,
		close = true,
		description = 'Paket berisi makanan dan minuman',
		degrade = 2880,
		client = {
			image = "paketnormaltom.png",
			export = 'sm_resource_1.openPackage'
		}
	},
	['paket_sweettom'] = {
		label = 'ATOM SWEET BOX',
		weight = 10,
		stack = true,
		close = true,
		description = 'Paket berisi makanan dan minuman',
		degrade = 2880,
		client = {
			image = "paketnormaltom.png",
			export = 'sm_resource_1.openPackage'
		}
	},
	['paket_kidstom'] = {
		label = 'ATOM KIDS BOX',
		weight = 10,
		stack = true,
		close = true,
		description = 'Paket berisi makanan dan minuman',
		degrade = 2880,
		client = {
			image = "paketanaktom.png",
			export = 'sm_resource_1.openPackage'
		}
	},

	-- PAKET KKP RESTO
	['paket_freshseafood'] = {
		label = 'Paket Goong Ten KKP',
		weight = 10,
		stack = true,
		close = true,
		description = 'Paket berisi makanan dan minuman',
		degrade = 2880,
		client = {
			image = "paketbox.png",
			export = 'sm_resource_1.openPackage'
		}
	},
	['paket_padthai'] = {
		label = 'Paket Padthai KKP',
		weight = 10,
		stack = true,
		close = true,
		description = 'Paket berisi makanan dan minuman',
		degrade = 2880,
		client = {
			image = "paketbox.png",
			export = 'sm_resource_1.openPackage'
		}
	},
	['paket_somtam'] = {
		label = 'Paket Somtam KKP',
		weight = 10,
		stack = true,
		close = true,
		description = 'Paket berisi makanan dan minuman',
		degrade = 2880,
		client = {
			image = "paketbox.png",
			export = 'sm_resource_1.openPackage'
		}
	},
	['paket_tomyum'] = {
		label = 'Paket Tomyum KKP',
		weight = 10,
		stack = true,
		close = true,
		description = 'Paket berisi makanan dan minuman',
		degrade = 2880,
		client = {
			image = "paketbox.png",
			export = 'sm_resource_1.openPackage'
		}
	},

	-- PAKET 969 RESTO
	['paket_padang'] = {
		label = 'Paket Padang 969',
		weight = 10,
		stack = true,
		close = true,
		description = 'Paket berisi makanan dan minuman',
		degrade = 2880,
		client = {
			image = "paketbox.png",
			export = 'sm_resource_1.openPackage'
		}
	},
    ['paket_sotomedan'] = {
		label = 'Paket Soto Medan 969',
		weight = 10,
		stack = true,
		close = true,
		description = 'Paket berisi makanan dan minuman',
		degrade = 2880,
		client = {
			image = "paketbox.png",
			export = 'sm_resource_1.openPackage'
		}
	},
	['paket_burger'] = {
		label = 'Paket Burger 969',
		weight = 10,
		stack = true,
		close = true,
		description = 'Paket berisi makanan dan minuman',
		degrade = 2880,
		client = {
			image = "paketbox.png",
			export = 'sm_resource_1.openPackage'
		}
	},
	['paket_sopbuntut'] = {
		label = 'Paket SB 969',
		weight = 10,
		stack = true,
		close = true,
		description = 'Paket berisi makanan dan minuman',
		degrade = 2880,
		client = {
			image = "paketbox.png",
			export = 'sm_resource_1.openPackage'
		}
	},
	['paketbox'] = {
		label = 'Paket Manis 969',
		weight = 10,
		stack = true,
		close = true,
		description = 'Paket berisi makanan dan minuman',
		degrade = 2880,
		client = {
			image = "paketbox.png",
			export = 'sm_resource_1.openPackage'
		}
	},

	-- paket ECLUB
	['paket_dwhiskey'] = {
		label = 'Paket Devil Whiskey',
		weight = 10,
		stack = true,
		close = true,
		description = 'Paket berisi alkohol dan minuman',
		degrade = 2880,
		client = {
			image = "paketbox.png",
			export = 'sm_resource_1.openPackage'
		}
	},
	['paket_pwine'] = {
		label = 'Paket Chateu Margaux',
		weight = 10,
		stack = true,
		close = true,
		description = 'Paket berisi alkohol dan minuman',
		degrade = 2880,
		client = {
			image = "paketbox.png",
			export = 'sm_resource_1.openPackage'
		}
	},
	['paket_ydetox'] = {
		label = 'Paket ECLUB Detox',
		weight = 10,
		stack = true,
		close = true,
		description = 'Paket berisi alkohol dan minuman',
		degrade = 2880,
		client = {
			image = "paketbox.png",
			export = 'sm_resource_1.openPackage'
		}
	},

	['paket_vodka'] = {
		label = 'Paket Vodka ECLUB',
		weight = 10,
		stack = true,
		close = true,
		description = 'Paket berisi alkohol dan minuman',
		degrade = 2880,
		client = {
			image = "paketbox.png",
			export = 'sm_resource_1.openPackage'
		}
	},

	['paket_beefbites'] = {
		label = 'Paket Beef Bites ECLUB',
		weight = 10,
		stack = true,
		close = true,
		description = 'Paket berisi makanan dan minuman',
		degrade = 2880,
		client = {
			image = "paketbox.png",
			export = 'sm_resource_1.openPackage'
		}
	},

	['paket_steakplate'] = {
		label = 'Paket Steak Plate ECLUB',
		weight = 10,
		stack = true,
		close = true,
		description = 'Paket berisi makanan dan minuman',
		degrade = 2880,
		client = {
			image = "paketbox.png",
			export = 'sm_resource_1.openPackage'
		}
	},

	-- PAKET MAXCLUB
	['paket_alkohol'] = {
		label = 'Paket Alkohol Maxclub',
		weight = 10,
		stack = true,
		close = true,
		description = 'Paket berisi makanan dan minuman',
		degrade = 2880,
		client = {
			image = "paketbox.png",
			export = 'sm_resource_1.openPackage'
		}
	},
	['paket_azul'] = {
		label = 'Paket Azul Maxclub',
		weight = 10,
		stack = true,
		close = true,
		description = 'Paket berisi alkohol dan minuman',
		degrade = 2880,
		client = {
			image = "paketbox.png",
			export = 'sm_resource_1.openPackage'
		}
	},
	['paket_scarlettseduction'] = {
		label = 'Paket Scarlettseduction Maxclub',
		weight = 10,
		stack = true,
		close = true,
		description = 'Paket berisi alkohol dan minuman',
		degrade = 2880,
		client = {
			image = "paketbox.png",
			export = 'sm_resource_1.openPackage'
		}
	},
	['paket_sheridan'] = {
		label = 'Paket Sheridan Maxclub',
		weight = 10,
		stack = true,
		close = true,
		description = 'Paket berisi alkohol dan minuman',
		degrade = 2880,
		client = {
			image = "paketbox.png",
			export = 'sm_resource_1.openPackage'
		}
	},
	['paket_cocomax'] = {
		label = 'Paket Cocomax',
		weight = 10,
		stack = true,
		close = true,
		description = 'Paket berisi alkohol dan minuman',
		degrade = 2880,
		client = {
			image = "paketbox.png",
			export = 'sm_resource_1.openPackage'
		}
	},
	['paket_alpha'] = {
		label = 'Paket Alpha Maxclub',
		weight = 10,
		stack = true,
		close = true,
		description = 'Paket berisi makanan dan minuman',
		degrade = 2880,
		client = {
			image = "paketbox.png",
			export = 'sm_resource_1.openPackage'
		}
	},
	['paket_sigma'] = {
		label = 'Paket Sigma Maxclub',
		weight = 10,
		stack = true,
		close = true,
		description = 'Paket berisi makanan dan minuman',
		degrade = 2880,
		client = {
			image = "paketbox.png",
			export = 'sm_resource_1.openPackage'
		}
	},

	["m_jackets_etb1"] = {
		label = "Jacket ETB Tipe 1 Laki-laki",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket",
	},

	["f_jackets_etb1"] = {
		label = "Jaket ETB Tipe 1 Perempuan",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket",
	},

	["m_jackets_nexus1"] = {
		label = "Jaket Nexus 1 (Pria)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Nexus tipe 1 untuk pria",
	},

	["m_jackets_heavenhell1"] = {
		label = "Jaket HeavenHell 1 (Pria)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket HeavenHell tipe 1 untuk pria",
	},

	["m_bodyarmor_ls1"] = {
		label = "Body Armor LS1 (Pria)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor LS tipe 1 untuk pria",
	},

	["m_bodyarmor_heavenhell1_0"] = {
		label = "Body Armor HeavenHell 1 (Pria)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor HeavenHell tipe 0 untuk pria",
	},

	["m_bodyarmor_heavenhell1_1"] = {
		label = "Body Armor HeavenHell 1 (Pria)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor HeavenHell tipe 1 untuk pria",
	},

	["m_bags_ls1_0"] = {
		label = "Tas LS1 Varian 0 (Pria)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Tas LS tipe 1 varian 0 untuk pria",
	},

	["m_bags_ls1_1"] = {
		label = "Tas LS1 Varian 1 (Pria)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Tas LS tipe 1 varian 1 untuk pria",
	},

	["m_pants_heavenhell1"] = {
		label = "Celana HeavenHell 1 (Pria)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Celana HeavenHell tipe 1 untuk pria",
	},

	["f_jackets_nexus1"] = {
		label = "Jaket Nexus 1 (Wanita)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Nexus tipe 1 untuk wanita",
	},

	["f_jackets_heavenhell1"] = {
		label = "Jaket HeavenHell 1 (Wanita)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket HeavenHell tipe 1 untuk wanita",
	},

	["f_bodyarmor_ls1"] = {
		label = "Body Armor LS1 (Wanita)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor LS tipe 1 untuk wanita",
	},

	["f_bodyarmor_heavenhell1_0"] = {
		label = "Body Armor HeavenHell 1 (Wanita)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor HeavenHell tipe 0 untuk wanita",
	},

	["f_bodyarmor_heavenhell1_1"] = {
		label = "Body Armor HeavenHell 1 (Wanita)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor HeavenHell tipe 1 untuk wanita",
	},

	["f_bags_ls1_0"] = {
		label = "Tas LS1 Varian 0 (Wanita)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Tas LS tipe 1 varian 0 untuk wanita",
	},

	["f_bags_ls1_1"] = {
		label = "Tas LS1 Varian 1 (Wanita)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Tas LS tipe 1 varian 1 untuk wanita",
	},

	["f_pants_heavenhell1"] = {
		label = "Celana HeavenHell 1 (Wanita)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Celana HeavenHell tipe 1 untuk wanita",
	},
	["m_jackets_pam1_0"] = {
		label = "Jaket BFL Pria (Varian 0)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket PAM tipe 1 varian 0 untuk pria",
	},

	["m_jackets_pam1_1"] = {
		label = "Jaket PAM1 Pria (Varian 1)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket PAM tipe 1 varian 1 untuk pria",
	},

	["m_jackets_abyssal1"] = {
		label = "Jaket Abyssal1 Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Abyssal tipe 1 untuk pria",
	},

	["m_jackets_abyssal2"] = {
		label = "Jaket Abyssal2 Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Abyssal tipe 2 untuk pria",
	},

	["m_bodyarmor_abyssal1"] = {
		label = "Body Armor Abyssal1 Pria",
		weight = 15,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Abyssal tipe 1 untuk pria",
	},

	["f_jackets_pam1_0"] = {
		label = "Jaket BFL Wanita (Varian 0)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket PAM tipe 1 varian 0 untuk wanita",
	},

	["f_jackets_pam1_1"] = {
		label = "Jaket PAM1 Wanita (Varian 1)",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket PAM tipe 1 varian 1 untuk wanita",
	},

	["f_jackets_abyssal1"] = {
		label = "Jaket Abyssal1 Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Abyssal tipe 1 untuk wanita",
	},

	["f_jackets_abyssal2"] = {
		label = "Jaket Abyssal2 Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Abyssal tipe 2 untuk wanita",
	},

	["f_bodyarmor_abyssal1"] = {
		label = "Body Armor Abyssal1 Wanita",
		weight = 15,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Abyssal tipe 1 untuk wanita",
	},

	["conedeck"] = {
		label = "cOne Deck",
		weight = 10,
		consume = 1,
		degrade = 4320,
		stack = true,
		close = true,
		client = {
			image = "conedeck.png",
			export = "cdev_cOne.createTableOXItem",
		}
	},

	--- pack senjata v3 gacha ---
	["antidote_cure"] = {
		label = "Cure",
		weight = 1,
		stack = true,
		close = true,
	},

	["m_jackets_gehanom1"] = {
		label = "Jaket Gehanom 1 Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Gehanom tipe 1 untuk pria",
	},

	["m_jackets_gehanom2"] = {
		label = "Jaket Gehanom 2 Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Gehanom tipe 2 untuk pria",
	},

	["m_bodyarmor_gehanom1"] = {
		label = "Body Armor Gehanom Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Gehanom untuk pria",
	},

	["f_jackets_gehanom1"] = {
		label = "Jaket Gehanom 1 Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Gehanom tipe 1 untuk wanita",
	},

	["f_jackets_gehanom2"] = {
		label = "Jaket Gehanom 2 Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Gehanom tipe 2 untuk wanita",
	},

	["f_bodyarmor_gehanom1"] = {
		label = "Body Armor Gehanom Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Gehanom untuk wanita",
	},

	["m_jackets_fleelinks1"] = {
		label = "Jaket Fleelinks Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Fleelinks untuk pria",
	},

	["f_jackets_fleelinks1"] = {
		label = "Jaket Fleelinks Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Fleelinks untuk wanita",
	},

	["f_jackets_fleelinks2"] = {
		label = "Jaket Fleelinks2 Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Fleelinks tipe 2 untuk wanita",
	},
	["f_jackets_fleelinks3"] = {
		label = "Jaket Fleelinks3 Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Fleelinks tipe 3 untuk wanita",
	},
	["m_jackets_fleelinks2"] = {
		label = "Jaket Fleelinks2 Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Fleelinks tipe 2 untuk pria",
	},
	["m_jackets_fleelinks3"] = {
		label = "Jaket Fleelinks3 Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Fleelinks tipe 3 untuk pria",
	},

	["m_jackets_gaviria1"] = {
		label = "Jaket Gaviria Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Gaviria Pria 1",
	},
	["m_jackets_gaviria2"] = {
		label = "Jaket Gaviria Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Gaviria Pria 2",
	},
	["f_jackets_gaviria1"] = {
		label = "Jaket Gaviria Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Gaviria Wanita 1",
	},
	["f_bodyarmor_gaviria1"] = {
		label = "Armor Gaviria Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Armor Gaviria Wanita 1",
	},

	---
	["m_jackets_rbl1"] = {
		label = "Jaket Rebellion Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Rebellion Pria 1",
	},

	["f_jackets_rbl1"] = {
		label = "Jaket Rebellion Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Rebellion Wanita 1",
	},



	["m_jackets_swag1"] = {
		label = "Jaket Swag Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Swag Pria 1",
	},

	["m_jackets_swag2"] = {
		label = "Jaket Swag Pria 2",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Swag Pria 2",
	},

	["f_jackets_swag1"] = {
		label = "Jaket Swag Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Swag Wanita 1",
	},

	["f_jackets_swag2"] = {
		label = "Jaket Swag Wanita 2",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Swag Wanita 2",
	},

	["m_pants_swag1"] = {
		label = "Celana Swag Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Celana Swag Pria 1",
	},

	["f_pants_swag1"] = {
		label = "Celana Swag Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Celana Swag Wanita 1",
	},

	["m_jackets_eclipse1"] = {
		label = "Jaket Eclipse Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Eclipse Pria 1",
	},

	["f_jackets_eclipse1"] = {
		label = "Jaket Eclipse Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Eclipse Wanita 1",
	},

	["m_bodyarmor_nagasaki1"] = {
		label = "Armor Nagasaki Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Armor Nagasaki Pria 1",
	},

	["f_bodyarmor_nagasaki1"] = {
		label = "Armor Nagasaki Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Armor Nagasaki Wanita 1",
	},



	---

	['tas_reporter'] = {
		label = 'Tas Reporter',
		weight = 2000,
		stack = false,
		close = true,
		description = 'Tas khusus untuk menyimpan peralatan reporter. Dapat menahan durability item.',
		client = {
			usetime = 1000,
			export = 'sm_addonstash.useTasReporter'
		}
	},
	['tas_ambulance'] = {
		label = 'Tas Ambulance',
		weight = 2000,
		stack = false,
		close = true,
		description = 'Tas khusus untuk menyimpan peralatan medis. Dapat menahan durability item.',
		client = {
			usetime = 1000,
			export = 'sm_addonstash.useTasAmbulance'
		}
	},

	["m_jackets_crimsonreign1_0"] = {
		label = "Jaket crimson",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket 0 pria",
	},

	["m_jackets_crimsonreign1_1"] = {
		label = "Jaket crimson",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket 1 pria",
	},

	["f_jackets_crimsonreign1_0"] = {
		label = "Jaket crimson",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket 1 wanita",
	},

	["f_jackets_crimsonreign1_1"] = {
		label = "Jaket crimson",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket 1 wanita",
	},

	-- Hats Items
	["m_hats_dsr1"] = {
		label = "Topi DSR Pria",
		weight = 5,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Topi DSR untuk pria",
	},

    ["m_hats_dsr2"] = {
		label = "Topi DSR Type 2 Pria",
		weight = 5,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Topi DSR Type 2 untuk pria",
	},

	["f_hats_dsr1"] = {
		label = "Topi DSR Wanita",
		weight = 5,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Topi DSR untuk wanita",
	},

	---

	-- Male Items
	["m_masks_lmc"] = {
		label = "Masker LMC Pria",
		weight = 5,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Masker LMC untuk pria",
	},

	["m_masks_nexus"] = {
		label = "Bandana Nexus Pria",
		weight = 5,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Bandana Nexus untuk pria",
	},

	["m_jackets_kuroyama1"] = {
		label = "Jaket Kuroyama Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Kuroyama untuk pria",
	},

	["m_jackets_lmc1"] = {
		label = "Jaket LMC Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket LMC untuk pria",
	},

	["m_jackets_omc1"] = {
		label = "Jaket OMC Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket OMC untuk pria",
	},

	["m_bodyarmor_lmc1_0"] = {
		label = "Body Armor LMC Pria (Tipe 0)",
		weight = 20,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body Armor LMC tipe 0 untuk pria",
	},

	["m_bodyarmor_lmc1_1"] = {
		label = "Body Armor LMC Pria (Tipe 1)",
		weight = 20,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body Armor LMC tipe 1 untuk pria",
	},

	["m_bodyarmor_lmc1_2"] = {
		label = "Body Armor LMC Pria (Tipe 2)",
		weight = 20,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body Armor LMC tipe 2 untuk pria",
	},

	["m_bodyarmor_lmc1_3"] = {
		label = "Body Armor LMC Pria (Tipe 3)",
		weight = 20,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body Armor LMC tipe 3 untuk pria",
	},

	["m_bodyarmor_lmc1_4"] = {
		label = "Body Armor LMC Pria (Tipe 4)",
		weight = 20,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body Armor LMC tipe 4 untuk pria",
	},

	["m_bodyarmor_lmc1_5"] = {
		label = "Body Armor LMC Pria (Tipe 5)",
		weight = 20,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body Armor LMC tipe 5 untuk pria",
	},

	["m_bodyarmor_lmc1_6"] = {
		label = "Body Armor LMC Pria (Tipe 6)",
		weight = 20,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body Armor LMC tipe 6 untuk pria",
	},

	["m_bodyarmor_lmc1_7"] = {
		label = "Body Armor LMC Pria (Tipe 7)",
		weight = 20,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body Armor LMC tipe 7 untuk pria",
	},

	["m_bodyarmor_lmc1_8"] = {
		label = "Body Armor LMC Pria (Tipe 8)",
		weight = 20,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body Armor LMC tipe 8 untuk pria",
	},

	["m_bodyarmor_lmc1_9"] = {
		label = "Body Armor LMC Pria (Tipe 9)",
		weight = 20,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body Armor LMC tipe 9 untuk pria",
	},

	["m_bodyarmor_lmc1_10"] = {
		label = "Body Armor LMC Pria (Tipe 10)",
		weight = 20,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body Armor LMC tipe 10 untuk pria",
	},

	["m_bodyarmor_nexus1"] = {
		label = "Body Armor Nexus Pria",
		weight = 20,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body Armor Nexus untuk pria",
	},

	-- Female Items
	["f_masks_lmc"] = {
		label = "Masker LMC Wanita",
		weight = 5,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Masker LMC untuk wanita",
	},

	["f_masks_nexus"] = {
		label = "Bandana Nexus Wanita",
		weight = 5,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Bandana Nexus untuk wanita",
	},

	["f_jackets_kuroyama1"] = {
		label = "Jaket Kuroyama Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Kuroyama untuk wanita",
	},

	["f_jackets_lmc1"] = {
		label = "Jaket LMC Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket LMC untuk wanita",
	},

	["f_jackets_omc1"] = {
		label = "Jaket OMC Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket OMC untuk wanita",
	},

	["f_bodyarmor_lmc1_0"] = {
		label = "Body Armor LMC Wanita (Tipe 0)",
		weight = 20,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body Armor LMC tipe 0 untuk wanita",
	},

	["f_bodyarmor_lmc1_1"] = {
		label = "Body Armor LMC Wanita (Tipe 1)",
		weight = 20,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body Armor LMC tipe 1 untuk wanita",
	},

	["f_bodyarmor_lmc1_2"] = {
		label = "Body Armor LMC Wanita (Tipe 2)",
		weight = 20,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body Armor LMC tipe 2 untuk wanita",
	},

	["f_bodyarmor_lmc1_3"] = {
		label = "Body Armor LMC Wanita (Tipe 3)",
		weight = 20,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body Armor LMC tipe 3 untuk wanita",
	},

	["f_bodyarmor_lmc1_4"] = {
		label = "Body Armor LMC Wanita (Tipe 4)",
		weight = 20,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body Armor LMC tipe 4 untuk wanita",
	},

	["f_bodyarmor_lmc1_5"] = {
		label = "Body Armor LMC Wanita (Tipe 5)",
		weight = 20,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body Armor LMC tipe 5 untuk wanita",
	},

	["f_bodyarmor_nexus1"] = {
		label = "Body Armor Nexus Wanita",
		weight = 20,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body Armor Nexus untuk wanita",
	},

	["pol_mdt"] = {
		label = "Police MDT",
		weight = 200,
		stack = true,
		close = true,
		description = "Mobile Data Terminal kepolisian",
	},

	["ems_mdt"] = {
		label = "EMS MDT",
		weight = 200,
		stack = true,
		close = true,
		description = "Mobile Data Terminal medis",
	},
	["pwine"] = {
		label = "ChÃ¢teau Margaux",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "minuman alcohol",
	},
	["vodka"] = {
		label = "Vodka",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "minuman alcohol",
	},
	["dwhiskey"] = {
		label = "Devilâ€™s Whiskey",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "minuman alcohol",
	},
	["ydetox"] = {
		label = "ECLUB Detox Shot",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "penawar mabuk",
	},
	['cigarpack'] = {
        label = 'Cigar Pack',
        weight = 200,
        stack = true,
        close = true,
        description = 'Take out your cigar',
    },
	['cigar'] = {
        label = 'Cigar',
        weight = 10,
        stack = true,
        close = true,
        description = 'Smoking cigarette',
    },

	-- Makanan
	["bacongrilled"] = {
		label = "Bacon Grilled Cheese",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "makanan khas paradise delight",
	},

	["multigrainbagel"] = {
		label = "Multigrain Bagel",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "makanan khas paradise delight",
	},

	["takoyaki"] = {
		label = "Takoyaki",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "makanan khas paradise delight",
	},

	-- Makanan Atom
	["scwings"] = {
		label = "Spicy Chicken Wings",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "makanan khas Atom n Burger",
	},
	["ccsandwich"] = {
		label = "Chicken Creamy Sandwich",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "makanan khas Atom n Burger",
	},
	["omcheese"] = {
		label = "Omelette Cheese",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "makanan khas Atom n Burger",
	},
	["macaron"] = {
		label = "Macaroon",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "makanan khas Atom n Burger",
	},
	-- Minuman atom
	["syogurtsmoothie"] = {
		label = "Strawberry Yogurt Smoothie",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "minuman khas Atom n Burger",
	},

	["icofeemilk"] = {
		label = "Iced Coffee Milk",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "minuman khas Atom n Burger",
	},
	["orangesoda"] = {
		label = "Orange Soda",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "minuman khas Atom n Burger",
	},
	["whitefrappe"] = {
		label = "White Frappe",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "minuman khas Atom n Burger",
	},
	--kidsmealatom
	["scpancake"] = {
		label = "Sweet corn Pancake",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "makanan khas Atom n Burger",
	},
	["carjuice"] = {
		label = "Carrot Juice",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "minuman khas Atom n Burger",
	},


	-- Minuman
	["orangejuice"] = {
		label = "Orange Juice",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "minuman khas paradise delight",
	},

	["matchalatte"] = {
		label = "Matcha Latte",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "minuman khas paradise delight",
	},

	["ochatea"] = {
		label = "Ocha Tea",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "minuman khas paradise delight",
	},

	["gsr_cloth"] = {
		label = "GSR Cloth",
		weight = 100,
		stack = true,
		close = true,
	},

	["gsr_test_kit"] = {
		label = "GSR Test Kit",
		weight = 100,
		stack = true,
		close = true,
	},

	["uv_light"] = {
		label = "UV Flashlight",
		weight = 250,
		stack = true,
		close = true,
	},

	["evidence_camera"] = {
		label = "Evidence Camera",
		weight = 500,
		stack = true,
		close = true,
	},

	["fingerprint_scanner"] = {
		label = "Fingerprint Scanner",
		weight = 250,
		stack = true,
		close = true,
	},

	["bullet_casing"] = {
		label = "Bullet Casing",
		weight = 1,
		stack = false,
	},

	["bullet_fragment"] = {
		label = "Bullet Fragment",
		weight = 1,
		stack = false,
	},

	["blood_sample"] = {
		label = "Blood Sample",
		weight = 1,
		stack = false,
	},

	["fingerprint"] = {
		label = "Fingerprint Sample",
		weight = 1,
		stack = false,
	},

	["evidence"] = {
		label = "Evidence",
		weight = 1,
		stack = false,
	},

	["bullet_hole"] = {
		label = "Impact Sample",
		weight = 1,
		stack = false,
	},

	-- Male CMC Items
	["m_jackets_cmc2"] = {
		label = "Jaket CMC2 Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket CMC tipe 2 untuk pria",
	},

	["m_bodyarmor_cmc1_0"] = {
		label = "Body Armor CMC1 Pria (Hitam)",
		weight = 15,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor CMC1 warna hitam untuk pria",
	},

	["m_bodyarmor_cmc1_1"] = {
		label = "Body Armor CMC1 Pria (Putih)",
		weight = 15,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor CMC1 warna putih untuk pria",
	},

	["m_bodyarmor_cmc1_2"] = {
		label = "Body Armor CMC1 Pria (Abu-abu)",
		weight = 15,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor CMC1 warna abu-abu untuk pria",
	},

	["m_bodyarmor_cmc1_3"] = {
		label = "Body Armor CMC1 Pria (Biru)",
		weight = 15,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor CMC1 warna biru untuk pria",
	},

	["m_bodyarmor_cmc1_4"] = {
		label = "Body Armor CMC1 Pria (Hijau)",
		weight = 15,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor CMC1 warna hijau untuk pria",
	},

	["m_bodyarmor_cmc1_5"] = {
		label = "Body Armor CMC1 Pria (Merah)",
		weight = 15,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor CMC1 warna merah untuk pria",
	},

	["m_bodyarmor_cmc1_6"] = {
		label = "Body Armor CMC1 Pria (Kuning)",
		weight = 15,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor CMC1 warna kuning untuk pria",
	},

	-- Female CMC Items
	["f_jackets_cmc2"] = {
		label = "Jaket CMC1 Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket CMC tipe 1 untuk wanita",
	},

	["f_bodyarmor_cmc1_0"] = {
		label = "Body Armor CMC1 Wanita (Hitam)",
		weight = 15,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor CMC1 warna hitam untuk wanita",
	},

	["f_bodyarmor_cmc1_1"] = {
		label = "Body Armor CMC1 Wanita (Putih)",
		weight = 15,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor CMC1 warna putih untuk wanita",
	},

	["f_bodyarmor_cmc1_2"] = {
		label = "Body Armor CMC1 Wanita (Abu-abu)",
		weight = 15,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor CMC1 warna abu-abu untuk wanita",
	},

	["f_bodyarmor_cmc1_3"] = {
		label = "Body Armor CMC1 Wanita (Biru)",
		weight = 15,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor CMC1 warna biru untuk wanita",
	},

	["f_bodyarmor_cmc1_4"] = {
		label = "Body Armor CMC1 Wanita (Hijau)",
		weight = 15,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor CMC1 warna hijau untuk wanita",
	},

	["f_bodyarmor_cmc1_5"] = {
		label = "Body Armor CMC1 Wanita (Merah)",
		weight = 15,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor CMC1 warna merah untuk wanita",
	},

	["f_bodyarmor_cmc1_6"] = {
		label = "Body Armor CMC1 Wanita (Kuning)",
		weight = 15,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor CMC1 warna kuning untuk wanita",
	},

	-- Babayo Items
	["m_bodyarmor_babayo1"] = {
		label = "Body Armor Babayo Pria",
		weight = 15,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Babayo untuk pria",
	},

	["m_jackets_babayo1"] = {
		label = "Jaket Babayo Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket Babayo untuk pria",
	},

	["f_bodyarmor_babayo1"] = {
		label = "Body Armor Babayo1 Wanita",
		weight = 15,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Babayo tipe 1 untuk wanita",
	},

	["f_bodyarmor_babayo2"] = {
		label = "Body Armor Babayo2 Wanita",
		weight = 15,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor Babayo tipe 2 untuk wanita",
	},

	["m_jackets_ffy1"] = {
		label = "Jacket FFy Pria",
		weight = 15,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jacket FFy untuk pria",
	},
	["m_jackets_phoenix1"] = {
		label = "Jacket Phoenix Pria",
		weight = 15,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jacket Phoenix untuk pria",
	},
	["f_bodyarmor_ffy1"] = {
		label = "Body Armor FFY Wanita",
		weight = 15,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor FFY tipe 1 untuk wanita",
	},
	["f_jackets_phoenix1"] = {
		label = "Jacket Phoenix Wanita",
		weight = 15,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jacket Phoenix untuk wanita",
	},
	["m_jackets_vrn1"] = {
		label = "Jacket VRN Pria",
		weight = 15,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jacket VRN untuk pria",
	},
	["f_jackets_vrn1"] = {
		label = "Jacket VRN Wanita",
		weight = 15,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jacket VRN untuk Wanita",
	},
	['rose_valentine'] = {
		label = 'â€¢Rose',
		weight = 100,
		degrade = 4320,
		stack = false,
		close = true,
		description = 'Rose for special occasions'
	},
	['bouquet_valentine'] = {
		label = 'â€¢Bouquet',
		weight = 100,
		degrade = 4320,
		stack = false,
		close = true,
		description = 'Bouquet of roses'
	},
	['bouquet2_valentine'] = {
		label = 'â€¢Bouquet Premium',
		weight = 100,
		degrade = 4320,
		stack = false,
		close = true,
		description = 'Bouquet of roses'
	},
	['bantal_valentine'] = {
		label = 'â€¢Bantal Valentine',
		weight = 100,
		stack = true,
		close = true,
		description = 'Bantal untuk Valentine\'s Day'
	},
	['boneka_valentine'] = {
		label = 'â€¢Boneka Valentine',
		weight = 100,
		stack = true,
		close = true,
		description = 'Boneka untuk Valentine\'s Day'
	},
	['bunga_valentine'] = {
		label = 'â€¢Bunga Valentine',
		weight = 100,
		stack = true,
		close = true,
		description = 'Bunga untuk Valentine\'s Day'
	},
	['coklat_valentine'] = {
		label = 'â€¢Coklat Valentine',
		weight = 100,
		stack = true,
		close = true,
		description = 'Coklat untuk Valentine\'s Day'
	},
	['permen_valentine'] = {
		label = 'â€¢Permen Valentine',
		weight = 100,
		stack = true,
		close = true,
		description = 'Permen untuk Valentine\'s Day'
	},
	['selimut_valentine'] = {
		label = 'â€¢Selimut Valentine',
		weight = 100,
		stack = true,
		close = true,
		description = 'Selimut untuk Valentine\'s Day'
	},
	['gift_box_valentine'] = {
		label = 'â€¢Gift Box Valentine',
		weight = 100,
		stack = false,
		close = true,
		description = 'Gift box untuk Valentine\'s Day'
	},

	['kolak'] = {
		label = 'Kolak',
		weight = 10,
		stack = true,
		close = true,
		description = 'Takjil kolak pisang yang manis.',
	},
	['kurma'] = {
		label = 'Kurma',
		weight = 10,
		stack = true,
		close = true,
		description = 'Kurma manis untuk berbuka puasa.',
	},
	['gorengan'] = {
		label = 'Gorengan',
		weight = 10,
		stack = true,
		close = true,
		description = 'Gorengan crispy favorit semua orang.',
	},
	['esbuah'] = {
		label = 'Es Buah',
		weight = 10,
		stack = true,
		close = true,
		description = 'Es buah segar untuk berbuka.',
	},
	['escampur'] = {
		label = 'Es Campur',
		weight = 10,
		stack = true,
		close = true,
		description = 'Es campur dengan berbagai topping.',
	},
	['ketupat'] = {
		label = 'Ketupat',
		weight = 10,
		stack = true,
		close = true,
		description = 'Ketupat langka, item spesial Ramadhan!',
	},
	['nastar'] = {
		label = 'Nastar',
		weight = 10,
		stack = true,
		close = true,
		description = 'Kue nastar isi selai nanas, sangat langka!',
	},
	['opor_ayam'] = {
		label = 'Opor Ayam',
		weight = 10,
		stack = true,
		close = true,
		description = 'Opor ayam spesial, item rare Ramadhan!',
	},

	--jajanan
	["cilok"] = {
		label = "Cilok",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "jajannnn",
	},
	["telur_gulung"] = {
		label = "Telur Gulung",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "jajannnn",
	},
	["es_slurp"] = {
		label = "Es Slurp",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "jajannnn",
	},
	["teh_poco"] = {
		label = "Teh Poco",
		weight = 100,
		stack = true,
		close = true,
		degrade = 4320,
		description = "jajannnn",
	},
	['bocahpass'] = {
		label = 'Bocah Pass',
		weight = 100,
		stack = false,
		close = true,
		description = 'Battlepass spesial untuk bocah-bocah di kota!',
		consume = 0,
		client = {
			export = 'sm_resource.openBocahPass',
			image = 'bocahpass.png',
		},
	},

	["bocahstar"] = {
		label = "Bocah Star",
		weight = 100,
		stack = true,
		close = true,
		description = "Tukarkan kepada Guru untuk mendapatkan Hadiah",
	},

	['speaker'] = {
		label = 'Speaker',
		weight = 0,
		description = 'Speaker.',
		consume = 0,
		degrade = 43200,
		server = {
			export = 'sm_resource_1.speaker'
		}
	},

	["m_baju_oplas"] = {
		label = "Baju Operasi",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Baju sekali pakai untuk pria",
	},

	["f_baju_oplas"] = {
		label = "Baju Operasi",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Baju sekali pakai untuk perempuan",
	},

	["oplas_baju_ganti"] = {
		label = "Baju Ganti",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Baju Ganti sekali pakai dari operasi",
	},

		-- Demon Items
	['jpx_demon_daki_fabric'] = {
		label = 'â€¢Daki Fabric',
		weight = 300,
		stack = true,
		close = true,
		description = 'Fabric from the demon Daki'
	},

	['jpx_demon_gyutaro_scythe'] = {
		label = 'â€¢Gyutaro Scythe',
		weight = 1500,
		stack = false,
		close = true,
		description = 'Poisonous scythe of Gyutaro'
	},

	['jpx_demon_gyutaro_scythe2'] = {
		label = 'â€¢Gyutaro Scythe 2',
		weight = 1500,
		stack = false,
		close = true,
		description = 'Second poisonous scythe of Gyutaro'
	},

	['jpx_demon_rui_spider_demon'] = {
		label = 'â€¢Spider Demon',
		weight = 800,
		stack = false,
		close = true,
		description = 'A spider demon minion'
	},

	-- Masks
	['jpx_demon_hotaru_mask'] = {
		label = 'â€¢Hotaru Mask',
		weight = 400,
		stack = false,
		close = true,
		description = 'Traditional mask of the swordsmith Hotaru'
	},

	['jpx_demon_inosuke_mask'] = {
		label = 'â€¢Inosuke Mask',
		weight = 400,
		stack = false,
		close = true,
		description = 'Boar head mask of Inosuke Hashibira'
	},

	['jpx_demon_kozo_mask'] = {
		label = 'â€¢Kozo Mask',
		weight = 400,
		stack = false,
		close = true,
		description = 'Mask of the Final Selection participant Kozo'
	},

	['jpx_demon_makomo_mask'] = {
		label = 'â€¢Makomo Mask',
		weight = 400,
		stack = false,
		close = true,
		description = 'Mask of Urokodaki\'s student Makomo'
	},

	['jpx_demon_rui_spider_mask'] = {
		label = 'â€¢Spider Mask',
		weight = 400,
		stack = false,
		close = true,
		description = 'Spider-themed mask from Rui\'s family'
	},

	['jpx_demon_sabito_mask'] = {
		label = 'â€¢Sabito Mask',
		weight = 400,
		stack = false,
		close = true,
		description = 'Mask of Urokodaki\'s student Sabito'
	},

	['jpx_demon_urokodaki_mask'] = {
		label = 'â€¢Urokodaki Mask',
		weight = 400,
		stack = false,
		close = true,
		description = 'Traditional tengu mask of Sakonji Urokodaki'
	},

	-- Equipment & Accessories
	['jpx_demon_hotaru_swordbox'] = {
		label = 'â€¢Hotaru Swordbox',
		weight = 2000,
		stack = false,
		close = true,
		description = 'Swordsmith\'s box for carrying katanas'
	},

	['jpx_demon_nezuko_bamboo'] = {
		label = 'â€¢Nezuko Bamboo',
		weight = 50,
		stack = false,
		close = true,
		description = 'Bamboo muzzle worn by Nezuko'
	},

	['jpx_demon_nezuko_box'] = {
		label = 'â€¢Nezuko Box',
		weight = 1000,
		stack = false,
		close = true,
		description = 'Special box for carrying Nezuko during daylight'
	},

	['jpx_demon_obanai_snake'] = {
		label = 'â€¢Obanai Snake',
		weight = 200,
		stack = false,
		close = true,
		description = 'Kaburamaru, Obanai\'s snake companion'
	},

	['jpx_demon_rengoku_coat'] = {
		label = 'â€¢Rengoku Coat',
		weight = 800,
		stack = false,
		close = true,
		description = 'Flame Hashira haori coat'
	},

	['jpx_demon_shinobu_butterfly'] = {
		label = 'â€¢Shinobu Bow',
		weight = 100,
		stack = false,
		close = true,
		description = 'Butterfly hair accessory of Shinobu Kocho'
	},

	['jpx_demon_tanjiro_earings'] = {
		label = 'â€¢Tanjiro Earings',
		weight = 20,
		stack = false,
		close = true,
		description = 'Hanafuda earrings passed down through generations'
	},

	-- Weapons
	['jpx_demon_tengen_sword'] = {
		label = 'â€¢Tengen Sword',
		weight = 1400,
		stack = false,
		close = true,
		description = 'One of Tengen\'s dual cleavers'
	},

	['jpx_demon_tengen_sword_back'] = {
		label = 'â€¢Tengen Sword 2',
		weight = 1400,
		stack = false,
		close = true,
		description = 'Second cleaver of the Sound Hashira'
	},

	-- Special Items
	['jpx_demon_magic_circle'] = {
		label = 'â€¢Demon Magic Circle',
		weight = 100,
		stack = true,
		close = true,
		description = 'A mysterious demon summoning circle'
	},

	['jpx_susamaru_ball'] = {
		label = 'â€¢Susamaru Ball',
		weight = 300,
		stack = true,
		close = true,
		description = 'Temari ball used by the demon Susamaru'
	},

		-- Duckling Items
	['jpx_duckling_back'] = {
		label = 'â€¢Duckling Backpack',
		weight = 1,
		stack = true,
		close = true,
		description = 'A cute duckling backpack'
	},

	['jpx_duckling_balloon'] = {
		label = 'â€¢Duckling Balloon',
		weight = 1,
		stack = true,
		close = true,
		description = 'A duckling shaped balloon'
	},

	['jpx_duckling_blow'] = {
		label = 'â€¢Duckling Blow',
		weight = 1,
		stack = true,
		close = true,
		description = 'A duckling blow item'
	},

	['jpx_duckling_egg'] = {
		label = 'â€¢Duckling Egg',
		weight = 1,
		stack = true,
		close = true,
		description = 'A duckling egg'
	},

	['jpx_duckling_flower'] = {
		label = 'â€¢Duckling Flower',
		weight = 1,
		stack = true,
		close = true,
		description = 'A duckling with flower'
	},

	['jpx_duckling_headbutt'] = {
		label = 'â€¢Duckling Headbutt',
		weight = 1,
		stack = true,
		close = true,
		description = 'A duckling headbutt pose'
	},

	['jpx_duckling_hello'] = {
		label = 'â€¢Duckling Hello',
		weight = 1,
		stack = true,
		close = true,
		description = 'A duckling saying hello'
	},

	['jpx_duckling_hold'] = {
		label = 'â€¢Duckling Hold',
		weight = 1,
		stack = true,
		close = true,
		description = 'A duckling being held'
	},

	['jpx_duckling_hug'] = {
		label = 'â€¢Duckling Hug',
		weight = 1,
		stack = true,
		close = true,
		description = 'A duckling hug pose'
	},

	['jpx_duckling_play'] = {
		label = 'â€¢Duckling Play',
		weight = 1,
		stack = true,
		close = true,
		description = 'A playing duckling'
	},

	['jpx_duckling_rain'] = {
		label = 'â€¢Duckling Rain',
		weight = 1,
		stack = true,
		close = true,
		description = 'A duckling in the rain'
	},

	['jpx_duckling_wings'] = {
		label = 'â€¢Duckling Wings',
		weight = 1,
		stack = true,
		close = true,
		description = 'A duckling with wings spread'
	},
		-- Light Fury Items
	['jpx_light_fury_float'] = {
		label = 'â€¢Light Fury Float',
		weight = 1,
		stack = true,
		close = true,
		description = 'A floating Light Fury'
	},

	['jpx_light_fury_ground'] = {
		label = 'â€¢Light Fury Ground',
		weight = 1,
		stack = true,
		close = true,
		description = 'A Light Fury on ground'
	},

	['jpx_light_fury_hold'] = {
		label = 'â€¢Light Fury Hold',
		weight = 1,
		stack = true,
		close = true,
		description = 'A Light Fury being held'
	},

	['jpx_light_fury_mount'] = {
		label = 'â€¢Light Fury Mount',
		weight = 1,
		stack = true,
		close = true,
		description = 'A Light Fury mount'
	},

	['jpx_light_fury_shoulder'] = {
		label = 'â€¢Light Fury Shoulder',
		weight = 1,
		stack = true,
		close = true,
		description = 'A Light Fury on shoulder'
	},

	-- Toothless Items
	['jpx_toothless_float'] = {
		label = 'â€¢Toothless Float',
		weight = 1,
		stack = true,
		close = true,
		description = 'A floating Toothless'
	},

	['jpx_toothless_fly'] = {
		label = 'â€¢Toothless Fly',
		weight = 1,
		stack = true,
		close = true,
		description = 'A flying Toothless'
	},

	['jpx_toothless_ground'] = {
		label = 'â€¢Toothless Ground',
		weight = 1,
		stack = true,
		close = true,
		description = 'A Toothless on ground'
	},

	['jpx_toothless_head'] = {
		label = 'â€¢Toothless Head',
		weight = 1,
		stack = true,
		close = true,
		description = 'A Toothless head pose'
	},

	['jpx_toothless_hold'] = {
		label = 'â€¢Toothless Hold',
		weight = 1,
		stack = true,
		close = true,
		description = 'A Toothless being held'
	},

	['jpx_toothless_play'] = {
		label = 'â€¢Toothless Play',
		weight = 1,
		stack = true,
		close = true,
		description = 'A playing Toothless'
	},

	['jpx_toothless_shoulder'] = {
		label = 'â€¢Toothless Shoulder',
		weight = 1,
		stack = true,
		close = true,
		description = 'A Toothless on shoulder'
	},
		-- School Collection
	['jpx_school_backpack'] = {
		label = 'â€¢School Backpack',
		weight = 200,
		stack = true,
		close = true,
		description = 'A sturdy school backpack'
	},
	['jpx_school_ballons'] = {
		label = 'â€¢School Ballons',
		weight = 50,
		stack = true,
		close = true,
		description = 'Colorful school balloons'
	},
	['jpx_school_book'] = {
		label = 'â€¢School Book',
		weight = 150,
		stack = true,
		close = true,
		description = 'Educational school book'
	},
	['jpx_school_handbag'] = {
		label = 'â€¢School Handbag',
		weight = 150,
		stack = true,
		close = true,
		description = 'A cute school handbag'
	},
	['jpx_school_handbag2'] = {
		label = 'â€¢School Handbag 2',
		weight = 150,
		stack = true,
		close = true,
		description = 'Another school handbag style'
	},
	['jpx_school_paper'] = {
		label = 'â€¢School Paper',
		weight = 25,
		stack = true,
		close = true,
		description = 'School assignment papers'
	},
	['jpx_school_pencil_backpack'] = {
		label = 'â€¢Pencil Backpack',
		weight = 200,
		stack = true,
		close = true,
		description = 'A backpack shaped like a pencil'
	},
	['jpx_school_pencil_earing'] = {
		label = 'â€¢Pencil Earing',
		weight = 25,
		stack = true,
		close = true,
		description = 'Pencil-shaped earrings'
	},
	['jpx_school_pencil_mask'] = {
		label = 'â€¢Pencil Mask',
		weight = 50,
		stack = true,
		close = true,
		description = 'A mask shaped like a pencil'
	},
	['jpx_school_pet'] = {
		label = 'â€¢School Pet',
		weight = 100,
		stack = true,
		close = true,
		description = 'A cute school pet'
	},
	['jpx_school_pet2'] = {
		label = 'â€¢School Pet 2',
		weight = 100,
		stack = true,
		close = true,
		description = 'Another school pet'
	},
	['jpx_school_pet_flying'] = {
		label = 'â€¢School Pet Flying',
		weight = 100,
		stack = true,
		close = true,
		description = 'A flying school pet'
	},
	['jpx_school_pet2_flying'] = {
		label = 'â€¢School Pet 2 Flying',
		weight = 100,
		stack = true,
		close = true,
		description = 'Another flying school pet'
	},

		-- Munchkin Cat Collection
	['jpx_munchkin_cat_dance'] = {
		label = 'â€¢Munchkin Cat Dance',
		weight = 100,
		stack = true,
		close = true,
		description = 'A dancing munchkin cat'
	},
	['jpx_munchkin_cat_hat'] = {
		label = 'â€¢Munchkin Cat Hat',
		weight = 75,
		stack = true,
		close = true,
		description = 'A hat with munchkin cat design'
	},
	['jpx_munchkin_cat_mouth'] = {
		label = 'â€¢Munchkin Cat Mouth',
		weight = 50,
		stack = true,
		close = true,
		description = 'Munchkin cat mouth accessory'
	},
	['jpx_munchkin_cat_round_run'] = {
		label = 'â€¢Munchkin Cat Round Run',
		weight = 100,
		stack = true,
		close = true,
		description = 'Munchkin cat running in circles'
	},
	['jpx_munchkin_cat_run_see'] = {
		label = 'â€¢Munchkin Cat Run',
		weight = 100,
		stack = true,
		close = true,
		description = 'A running munchkin cat'
	},
	['jpx_munchkin_cat_see'] = {
		label = 'â€¢Munchkin Cat See',
		weight = 100,
		stack = true,
		close = true,
		description = 'A watchful munchkin cat'
	},
	['jpx_munchkin_cat_shoulder'] = {
		label = 'â€¢Munchkin Cat Shoulder',
		weight = 100,
		stack = true,
		close = true,
		description = 'Munchkin cat shoulder companion'
	},
	['jpx_munchkin_cat_angel'] = {
		label = 'â€¢Munchkin Cat Angel',
		weight = 100,
		stack = true,
		close = true,
		description = 'An angelic munchkin cat'
	},
	['jpx_munchkin_cat_back_dance'] = {
		label = 'â€¢Munchkin Cat Back Dance',
		weight = 100,
		stack = true,
		close = true,
		description = 'Munchkin cat dancing from behind'
	},
	['jpx_munchkin_cat_flying'] = {
		label = 'â€¢Munchkin Cat Flying',
		weight = 100,
		stack = true,
		close = true,
		description = 'A flying munchkin cat'
	},
	['jpx_munchkin_cat_hiphop_dance'] = {
		label = 'â€¢Munchkin Cat Hiphop Dance',
		weight = 100,
		stack = true,
		close = true,
		description = 'Munchkin cat doing hip-hop dance'
	},
	['jpx_munchkin_cat_scared'] = {
		label = 'â€¢Munchkin Cat Scared',
		weight = 100,
		stack = true,
		close = true,
		description = 'A scared munchkin cat'
	},
	['jpx_munchkin_cat_swimming'] = {
		label = 'â€¢Munchkin Cat Swimming',
		weight = 100,
		stack = true,
		close = true,
		description = 'Munchkin cat swimming'
	},
	['jpx_munchkin_cat_head'] = {
		label = 'â€¢Munchkin Cat Head',
		weight = 75,
		stack = true,
		close = true,
		description = 'Munchkin cat head accessory'
	},
	-- Halloween Collection
	['jpx_hlw_asteria_hat'] = {
		label = 'â€¢Asteria Hat',
		weight = 100,
		stack = true,
		close = true,
		description = 'A mystical asteria hat for Halloween'
	},
	['jpx_hlw_basket'] = {
		label = 'â€¢Halloween Basket',
		weight = 150,
		stack = true,
		close = true,
		description = 'A spooky Halloween basket'
	},
	['jpx_hlw_bat_doll'] = {
		label = 'â€¢Bat Doll',
		weight = 100,
		stack = true,
		close = true,
		description = 'A cute bat doll'
	},
	['jpx_hlw_bat_headband'] = {
		label = 'â€¢Bat Headband',
		weight = 50,
		stack = true,
		close = true,
		description = 'A headband with bat ears'
	},
	['jpx_hlw_broom'] = {
		label = 'â€¢Broom',
		weight = 200,
		stack = true,
		close = true,
		description = 'A witch\'s flying broom'
	},
	['jpx_hlw_cat_doll'] = {
		label = 'â€¢Pumpkin Black Cat',
		weight = 100,
		stack = true,
		close = true,
		description = 'A black cat with pumpkin theme'
	},
	['jpx_hlw_cat_doll2'] = {
		label = 'â€¢Black Cat',
		weight = 100,
		stack = true,
		close = true,
		description = 'A spooky black cat doll'
	},
	['jpx_hlw_devil_doll'] = {
		label = 'â€¢Devil Doll',
		weight = 100,
		stack = true,
		close = true,
		description = 'A devilish doll'
	},
	['jpx_hlw_devil_horns'] = {
		label = 'â€¢Devil Horns',
		weight = 75,
		stack = true,
		close = true,
		description = 'Spooky devil horns'
	},
	['jpx_hlw_devil_wings'] = {
		label = 'â€¢Devil Wings',
		weight = 100,
		stack = true,
		close = true,
		description = 'Dark devil wings'
	},
	['jpx_hlw_diablo_bone'] = {
		label = 'â€¢Diable Bone',
		weight = 100,
		stack = true,
		close = true,
		description = 'A cursed diablo bone'
	},
	['jpx_hlw_dragon_horns'] = {
		label = 'â€¢Dragon Horns',
		weight = 100,
		stack = true,
		close = true,
		description = 'Fearsome dragon horns'
	},
	['jpx_hlw_dragon_tail'] = {
		label = 'â€¢Dragon Tail',
		weight = 150,
		stack = true,
		close = true,
		description = 'A powerful dragon tail'
	},
	['jpx_hlw_gabiru_coffin'] = {
		label = 'â€¢Gabiru Coffin',
		weight = 300,
		stack = true,
		close = true,
		description = 'A spooky gabiru coffin'
	},
	['jpx_hlw_gabiru_spirit'] = {
		label = 'â€¢Gabiru Spirit',
		weight = 100,
		stack = true,
		close = true,
		description = 'The spirit of gabiru'
	},
	['jpx_hlw_galaxy_horns'] = {
		label = 'â€¢Galaxy Horns',
		weight = 100,
		stack = true,
		close = true,
		description = 'Cosmic galaxy horns'
	},
	['jpx_hlw_grim'] = {
		label = 'â€¢Halloween Grim',
		weight = 200,
		stack = true,
		close = true,
		description = 'A grim reaper for Halloween'
	},
	['jpx_hlw_grim2'] = {
		label = 'â€¢Halloween Grim 2',
		weight = 200,
		stack = true,
		close = true,
		description = 'Another grim reaper variant'
	},
	['jpx_hlw_jack'] = {
		label = 'â€¢Jack O Lantern',
		weight = 150,
		stack = true,
		close = true,
		description = 'A classic jack o\'lantern'
	},
	['jpx_hlw_jack_doll'] = {
		label = 'â€¢Jack Doll',
		weight = 100,
		stack = true,
		close = true,
		description = 'A jack o\'lantern doll'
	},
	['jpx_hlw_jack_doll_staff'] = {
		label = '',
		weight = 200,
		stack = true,
		close = true,
		description = 'A staff with jack doll'
	},
	['jpx_hlw_jane'] = {
		label = 'â€¢Jane O Lantern',
		weight = 150,
		stack = true,
		close = true,
		description = 'A jane o\'lantern'
	},
	['jpx_hlw_lamp'] = {
		label = 'â€¢Halloween Lamp',
		weight = 200,
		stack = true,
		close = true,
		description = 'A spooky Halloween lamp'
	},
	['jpx_hlw_lolipop'] = {
		label = 'â€¢Halloween Lolipop',
		weight = 50,
		stack = true,
		close = true,
		description = 'A Halloween-themed lollipop'
	},
	['jpx_hlw_magic_circle'] = {
		label = 'â€¢Halloween Magic Circle',
		weight = 250,
		stack = true,
		close = true,
		description = 'A magical Halloween circle'
	},
	['jpx_hlw_magic_circle2'] = {
		label = 'â€¢Halloween Magic Circle 2',
		weight = 250,
		stack = true,
		close = true,
		description = 'Another Halloween magic circle'
	},
	['jpx_hlw_melissa_cursed'] = {
		label = 'â€¢Meliisa Cursed Doll',
		weight = 150,
		stack = true,
		close = true,
		description = 'A cursed melissa doll'
	},
	['jpx_hlw_melissa_cursed2'] = {
		label = 'â€¢Meliisa Cursed Soul',
		weight = 100,
		stack = true,
		close = true,
		description = 'The cursed soul of melissa'
	},
	['jpx_hlw_melissa_twinge'] = {
		label = 'â€¢Meliisa Twinge Doll',
		weight = 150,
		stack = true,
		close = true,
		description = 'A melissa twinge doll'
	},
	['jpx_hlw_melissa_twinge2'] = {
		label = 'â€¢Meliisa Twinge Soul',
		weight = 100,
		stack = true,
		close = true,
		description = 'The twinge soul of melissa'
	},
	['jpx_hlw_morrigan_headwings'] = {
		label = 'â€¢Morrigan Headwings',
		weight = 100,
		stack = true,
		close = true,
		description = 'Morrigan-style head wings'
	},
	['jpx_hlw_morrigan_wings'] = {
		label = 'â€¢Morrigan Wings',
		weight = 150,
		stack = true,
		close = true,
		description = 'Morrigan-style wings'
	},
	['jpx_hlw_pastel_coffin'] = {
		label = 'â€¢Pastel Coffin',
		weight = 300,
		stack = true,
		close = true,
		description = 'A pastel-colored coffin'
	},
	['jpx_hlw_reaper'] = {
		label = 'â€¢Halloween Reaper',
		weight = 250,
		stack = true,
		close = true,
		description = 'A Halloween grim reaper'
	},
	['jpx_hlw_spider_horn'] = {
		label = 'â€¢Spider Horns',
		weight = 75,
		stack = true,
		close = true,
		description = 'Creepy spider horns'
	},
	['jpx_hlw_staff'] = {
		label = 'â€¢Halloween Staff',
		weight = 200,
		stack = true,
		close = true,
		description = 'A magical Halloween staff'
	},
	['jpx_hlw_sword'] = {
		label = 'â€¢Halloween Sword',
		weight = 250,
		stack = true,
		close = true,
		description = 'A cursed Halloween sword'
	},
	['jpx_hlw_wings'] = {
		label = 'â€¢Halloween Wings',
		weight = 150,
		stack = true,
		close = true,
		description = 'Spooky Halloween wings'
	},
	['jpx_hlw_witch_bonewings'] = {
		label = 'â€¢Witch Bone Wings',
		weight = 150,
		stack = true,
		close = true,
		description = 'Wings made of bones'
	},
	['jpx_hlw_witch_book'] = {
		label = 'â€¢Witch Spell Book',
		weight = 200,
		stack = true,
		close = true,
		description = 'A book of witch spells'
	},
	['jpx_hlw_witch_broom'] = {
		label = 'â€¢Witch Bloom',
		weight = 200,
		stack = true,
		close = true,
		description = 'A witch\'s magical broom'
	},
	['jpx_hlw_witch_soul'] = {
		label = 'â€¢Witch Soul',
		weight = 100,
		stack = true,
		close = true,
		description = 'The soul of a witch'
	},
	['jpx_halloween_eyes'] = {
		label = 'â€¢Halloween Eyes',
		weight = 50,
		stack = true,
		close = true,
		description = 'Spooky Halloween eyes'
	},

	-- More Halloween Items
	['jpx_angel_heart'] = {
		label = 'â€¢Angel Heart',
		weight = 100,
		stack = true,
		close = true,
		description = 'A pure angel heart'
	},
	['jpx_baby_witch_doll'] = {
		label = 'â€¢Baby Witch Doll',
		weight = 100,
		stack = true,
		close = true,
		description = 'A cute baby witch doll'
	},
	['jpx_black_spell'] = {
		label = 'â€¢Black Spell',
		weight = 50,
		stack = true,
		close = true,
		description = 'A dark magic spell'
	},
	['jpx_bone'] = {
		label = 'â€¢Bone',
		weight = 75,
		stack = true,
		close = true,
		description = 'A spooky bone'
	},
	['jpx_coffin_cat'] = {
		label = 'â€¢Coffin Cat',
		weight = 150,
		stack = true,
		close = true,
		description = 'A cat in a coffin'
	},
	['jpx_cute_pumpkin_cat'] = {
		label = 'â€¢Cute Pumpkin Cat',
		weight = 100,
		stack = true,
		close = true,
		description = 'An adorable pumpkin cat'
	},
	['jpx_demon_bear'] = {
		label = 'â€¢Demon Bear',
		weight = 200,
		stack = true,
		close = true,
		description = 'A demonic bear'
	},
	['jpx_devil_heart'] = {
		label = 'â€¢Devil Heart',
		weight = 100,
		stack = true,
		close = true,
		description = 'A corrupted devil heart'
	},
	['jpx_devil_magic_staff'] = {
		label = 'â€¢Devil Magic Staff',
		weight = 250,
		stack = true,
		close = true,
		description = 'A staff with devil magic'
	},
	['jpx_fire_soul'] = {
		label = 'â€¢Fire Soul',
		weight = 100,
		stack = true,
		close = true,
		description = 'A soul made of fire'
	},
	['jpx_ghost_girl'] = {
		label = 'â€¢Ghost Girl',
		weight = 100,
		stack = true,
		close = true,
		description = 'The spirit of a young girl'
	},
	['jpx_halloween_book'] = {
		label = 'â€¢Halloween Book',
		weight = 150,
		stack = true,
		close = true,
		description = 'A spooky Halloween book'
	},
	['jpx_halloween_cat'] = {
		label = 'â€¢Halloween Cat',
		weight = 100,
		stack = true,
		close = true,
		description = 'A Halloween-themed cat'
	},
	['jpx_pumpkin_cat'] = {
		label = 'â€¢Pumpkin Cat',
		weight = 100,
		stack = true,
		close = true,
		description = 'A cat shaped like a pumpkin'
	},
	['jpx_pumpkin_maid'] = {
		label = 'â€¢Pumpkin Maid',
		weight = 150,
		stack = true,
		close = true,
		description = 'A maid with pumpkin theme'
	},
	['jpx_pumpkin_spirit'] = {
		label = 'â€¢Pumpkin Spirit',
		weight = 100,
		stack = true,
		close = true,
		description = 'The spirit of a pumpkin'
	},
	['jpx_scream_mask'] = {
		label = 'â€¢Scream Mask',
		weight = 100,
		stack = true,
		close = true,
		description = 'A terrifying scream mask'
	},
	['jpx_soul_magic_circle'] = {
		label = 'â€¢Soul Magic Circle',
		weight = 250,
		stack = true,
		close = true,
		description = 'A circle for soul magic'
	},
	['jpx_spirit'] = {
		label = 'â€¢Spirit',
		weight = 50,
		stack = true,
		close = true,
		description = 'A wandering spirit'
	},
	['jpx_spirit_doll'] = {
		label = 'â€¢Spirit Doll',
		weight = 100,
		stack = true,
		close = true,
		description = 'A doll possessed by a spirit'
	},
	['jpx_witch_cat'] = {
		label = 'â€¢Witch Cat',
		weight = 100,
		stack = true,
		close = true,
		description = 'A witch\'s familiar cat'
	},
	['jpx_witch_cauldron'] = {
		label = 'â€¢Witch Cauldron',
		weight = 300,
		stack = true,
		close = true,
		description = 'A bubbling witch cauldron'
	},
	['jpx_witch_headwear'] = {
		label = 'â€¢Witch Headwear',
		weight = 100,
		stack = true,
		close = true,
		description = 'Traditional witch headwear'
	},
	['jpx_witch_moon'] = {
		label = 'â€¢Witch Moon',
		weight = 150,
		stack = true,
		close = true,
		description = 'A mystical witch moon'
	},

	-- Labubu Collection - Blue (Sea Salt Coconut)
	['jpx_labubu_bag_blue'] = {
		label = 'â€¢Labubu Bag (Sea Salt Coconut)',
		weight = 150,
		stack = true,
		close = true,
		description = 'A blue Labubu bag in Sea Salt Coconut flavor'
	},
	['jpx_labubu_doll_blue'] = {
		label = 'â€¢Labubu Doll (Sea Salt Coconut)',
		weight = 100,
		stack = true,
		close = true,
		description = 'A blue Labubu doll in Sea Salt Coconut flavor'
	},
	['jpx_labubu_egg_blue'] = {
		label = 'â€¢Labubu Egg (Sea Salt Coconut)',
		weight = 75,
		stack = true,
		close = true,
		description = 'A blue Labubu egg in Sea Salt Coconut flavor'
	},
	['jpx_labubu_headwear_blue'] = {
		label = 'â€¢Labubu Headwear (Sea Salt Coconut)',
		weight = 100,
		stack = true,
		close = true,
		description = 'Blue Labubu headwear in Sea Salt Coconut flavor'
	},
	['jpx_labubu_plushie_blue'] = {
		label = 'â€¢Labubu Plushie (Sea Salt Coconut)',
		weight = 100,
		stack = true,
		close = true,
		description = 'A blue Labubu plushie in Sea Salt Coconut flavor'
	},
	['jpx_labubu_slippers_blue'] = {
		label = 'â€¢Labubu Slippers (Sea Salt Coconut)',
		weight = 125,
		stack = true,
		close = true,
		description = 'Blue Labubu slippers in Sea Salt Coconut flavor'
	},

	-- Labubu Collection - Pink (Lychee Berry)
	['jpx_labubu_bag_pink'] = {
		label = 'â€¢Labubu Bag (Lychee Berry)',
		weight = 150,
		stack = true,
		close = true,
		description = 'A pink Labubu bag in Lychee Berry flavor'
	},
	['jpx_labubu_doll_pink'] = {
		label = 'â€¢Labubu Doll (Lychee Berry)',
		weight = 100,
		stack = true,
		close = true,
		description = 'A pink Labubu doll in Lychee Berry flavor'
	},
	['jpx_labubu_egg_pink'] = {
		label = 'â€¢Labubu Egg (Lychee Berry)',
		weight = 75,
		stack = true,
		close = true,
		description = 'A pink Labubu egg in Lychee Berry flavor'
	},
	['jpx_labubu_headwear_pink'] = {
		label = 'â€¢Labubu Headwear (Lychee Berry)',
		weight = 100,
		stack = true,
		close = true,
		description = 'Pink Labubu headwear in Lychee Berry flavor'
	},
	['jpx_labubu_plushie_pink'] = {
		label = 'â€¢Labubu Plushie (Lychee Berry)',
		weight = 100,
		stack = true,
		close = true,
		description = 'A pink Labubu plushie in Lychee Berry flavor'
	},
	['jpx_labubu_slippers_pink'] = {
		label = 'â€¢Labubu Slippers (Lychee Berry)',
		weight = 125,
		stack = true,
		close = true,
		description = 'Pink Labubu slippers in Lychee Berry flavor'
	},

	-- Labubu Collection - Green (Green Grape)
	['jpx_labubu_bag_green'] = {
		label = 'â€¢Labubu Bag (Green Grape)',
		weight = 150,
		stack = true,
		close = true,
		description = 'A green Labubu bag in Green Grape flavor'
	},
	['jpx_labubu_doll_green'] = {
		label = 'â€¢Labubu Doll (Green Grape)',
		weight = 100,
		stack = true,
		close = true,
		description = 'A green Labubu doll in Green Grape flavor'
	},
	['jpx_labubu_egg_green'] = {
		label = 'â€¢Labubu Egg (Green Grape)',
		weight = 75,
		stack = true,
		close = true,
		description = 'A green Labubu egg in Green Grape flavor'
	},
	['jpx_labubu_headwear_green'] = {
		label = 'â€¢Labubu Headwear (Green Grape)',
		weight = 100,
		stack = true,
		close = true,
		description = 'Green Labubu headwear in Green Grape flavor'
	},
	['jpx_labubu_plushie_green'] = {
		label = 'â€¢Labubu Plushie (Green Grape)',
		weight = 100,
		stack = true,
		close = true,
		description = 'A green Labubu plushie in Green Grape flavor'
	},
	['jpx_labubu_slippers_green'] = {
		label = 'â€¢Labubu Slippers (Green Grape)',
		weight = 125,
		stack = true,
		close = true,
		description = 'Green Labubu slippers in Green Grape flavor'
	},

	-- Labubu Collection - Brown (Chestnut Cocoa)
	['jpx_labubu_bag_brown'] = {
		label = 'â€¢Labubu Bag (Chestnut Cocoa)',
		weight = 150,
		stack = true,
		close = true,
		description = 'A brown Labubu bag in Chestnut Cocoa flavor'
	},
	['jpx_labubu_doll_brown'] = {
		label = 'â€¢Labubu Doll (Chestnut Cocoa)',
		weight = 100,
		stack = true,
		close = true,
		description = 'A brown Labubu doll in Chestnut Cocoa flavor'
	},
	['jpx_labubu_egg_brown'] = {
		label = 'â€¢Labubu Egg (Chestnut Cocoa)',
		weight = 75,
		stack = true,
		close = true,
		description = 'A brown Labubu egg in Chestnut Cocoa flavor'
	},
	['jpx_labubu_headwear_brown'] = {
		label = 'â€¢Labubu Headwear (Chestnut Cocoa)',
		weight = 100,
		stack = true,
		close = true,
		description = 'Brown Labubu headwear in Chestnut Cocoa flavor'
	},
	['jpx_labubu_plushie_brown'] = {
		label = 'â€¢Labubu Plushie (Chestnut Cocoa)',
		weight = 100,
		stack = true,
		close = true,
		description = 'A brown Labubu plushie in Chestnut Cocoa flavor'
	},
	['jpx_labubu_slippers_brown'] = {
		label = 'â€¢Labubu Slippers (Chestnut Cocoa)',
		weight = 125,
		stack = true,
		close = true,
		description = 'Brown Labubu slippers in Chestnut Cocoa flavor'
	},

	-- Labubu Collection - White Brown (Toffee)
	['jpx_labubu_bag_whitebrown'] = {
		label = 'â€¢Labubu Bag (Toffee)',
		weight = 150,
		stack = true,
		close = true,
		description = 'A white-brown Labubu bag in Toffee flavor'
	},
	['jpx_labubu_doll_whitebrown'] = {
		label = 'â€¢Labubu Doll (Toffee)',
		weight = 100,
		stack = true,
		close = true,
		description = 'A white-brown Labubu doll in Toffee flavor'
	},
	['jpx_labubu_egg_whitebrown'] = {
		label = 'â€¢Labubu Egg (Toffee)',
		weight = 75,
		stack = true,
		close = true,
		description = 'A white-brown Labubu egg in Toffee flavor'
	},
	['jpx_labubu_headwear_whitebrown'] = {
		label = 'â€¢Labubu Headwear (Toffee)',
		weight = 100,
		stack = true,
		close = true,
		description = 'White-brown Labubu headwear in Toffee flavor'
	},
	['jpx_labubu_plushie_whitebrown'] = {
		label = 'â€¢Labubu Plushie (Toffee)',
		weight = 100,
		stack = true,
		close = true,
		description = 'A white-brown Labubu plushie in Toffee flavor'
	},
	['jpx_labubu_slippers_whitebrown'] = {
		label = 'â€¢Labubu Slippers (Toffee)',
		weight = 125,
		stack = true,
		close = true,
		description = 'White-brown Labubu slippers in Toffee flavor'
	},

	-- Labubu Collection - Cream (Soymilk)
	['jpx_labubu_bag_cream'] = {
		label = 'â€¢Labubu Bag (Soymilk)',
		weight = 150,
		stack = true,
		close = true,
		description = 'A cream Labubu bag in Soymilk flavor'
	},
	['jpx_labubu_doll_cream'] = {
		label = 'â€¢Labubu Doll (Soymilk)',
		weight = 100,
		stack = true,
		close = true,
		description = 'A cream Labubu doll in Soymilk flavor'
	},
	['jpx_labubu_egg_cream'] = {
		label = 'â€¢Labubu Egg (Soymilk)',
		weight = 75,
		stack = true,
		close = true,
		description = 'A cream Labubu egg in Soymilk flavor'
	},
	['jpx_labubu_headwear_cream'] = {
		label = 'â€¢Labubu Headwear (Soymilk)',
		weight = 100,
		stack = true,
		close = true,
		description = 'Cream Labubu headwear in Soymilk flavor'
	},
	['jpx_labubu_plushie_cream'] = {
		label = 'â€¢Labubu Plushie (Soymilk)',
		weight = 100,
		stack = true,
		close = true,
		description = 'A cream Labubu plushie in Soymilk flavor'
	},
	['jpx_labubu_slippers_cream'] = {
		label = 'â€¢Labubu Slippers (Soymilk)',
		weight = 125,
		stack = true,
		close = true,
		description = 'Cream Labubu slippers in Soymilk flavor'
	},

	-- Labubu Collection - Gray (Sesame Bean)
	['jpx_labubu_bag_gray'] = {
		label = 'â€¢Labubu Bag (Sesame Bean)',
		weight = 150,
		stack = true,
		close = true,
		description = 'A gray Labubu bag in Sesame Bean flavor'
	},
	['jpx_labubu_doll_gray'] = {
		label = 'â€¢Labubu Doll (Sesame Bean)',
		weight = 100,
		stack = true,
		close = true,
		description = 'A gray Labubu doll in Sesame Bean flavor'
	},
	['jpx_labubu_egg_gray'] = {
		label = 'â€¢Labubu Egg (Sesame Bean)',
		weight = 75,
		stack = true,
		close = true,
		description = 'A gray Labubu egg in Sesame Bean flavor'
	},
	['jpx_labubu_headwear_gray'] = {
		label = 'â€¢Labubu Headwear (Sesame Bean)',
		weight = 100,
		stack = true,
		close = true,
		description = 'Gray Labubu headwear in Sesame Bean flavor'
	},
	['jpx_labubu_plushie_gray'] = {
		label = 'â€¢Labubu Plushie (Sesame Bean)',
		weight = 100,
		stack = true,
		close = true,
		description = 'A gray Labubu plushie in Sesame Bean flavor'
	},
	['jpx_labubu_slippers_gray'] = {
		label = 'â€¢Labubu Slippers (Sesame Bean)',
		weight = 125,
		stack = true,
		close = true,
		description = 'Gray Labubu slippers in Sesame Bean flavor'
	},

	-- Labubu Flip Collection
	['jpx_lbb_flip_with_me'] = {
		label = 'â€¢Labubu Flip With Me',
		weight = 100,
		stack = true,
		close = true,
		description = 'Labubu flip with me collectible'
	},
	['jpx_lbb_flip_with_me2'] = {
		label = 'â€¢Labubu Flip With Me 2',
		weight = 100,
		stack = true,
		close = true,
		description = 'Second Labubu flip with me collectible'
	},
	['jpx_lbb_flip_with_me3'] = {
		label = 'â€¢Labubu Flip With Me 3',
		weight = 100,
		stack = true,
		close = true,
		description = 'Third Labubu flip with me collectible'
	},
	['jpx_lbb_flip_with_me4'] = {
		label = 'â€¢Labubu Flip With Me 4',
		weight = 100,
		stack = true,
		close = true,
		description = 'Fourth Labubu flip with me collectible'
	},
	['jpx_lbb_flip_with_me5'] = {
		label = 'â€¢Labubu Flip With Me 5',
		weight = 100,
		stack = true,
		close = true,
		description = 'Fifth Labubu flip with me collectible'
	},

	-- One Piece Collection
	['jpx_ace_hat'] = {
		label = 'â€¢Ace Hat',
		weight = 100,
		stack = true,
		close = true,
		description = 'Portgas D. Ace\'s iconic hat'
	},
	['jpx_ace_hat2'] = {
		label = 'â€¢Ace Hat 2',
		weight = 100,
		stack = true,
		close = true,
		description = 'Another style of Ace\'s hat'
	},
	['jpx_aokiji_coat'] = {
		label = 'â€¢Aokiji Coat',
		weight = 250,
		stack = true,
		close = true,
		description = 'Admiral Aokiji\'s marine coat'
	},
	['jpx_arlong'] = {
		label = 'â€¢Arlong Sword',
		weight = 300,
		stack = true,
		close = true,
		description = 'Arlong\'s fishman sword'
	},
	['jpx_beer_mug'] = {
		label = 'â€¢Beer Mug',
		weight = 150,
		stack = true,
		close = true,
		description = 'A pirate\'s beer mug'
	},
	['jpx_bentham'] = {
		label = 'â€¢Bentham',
		weight = 200,
		stack = true,
		close = true,
		description = 'Mr. 2 Bentham accessory'
	},
	['jpx_bigmum_napoleon_hat'] = {
		label = 'â€¢Bigmum Hat',
		weight = 150,
		stack = true,
		close = true,
		description = 'Big Mom\'s Napoleon hat'
	},
	['jpx_bigmum_napoleon_sword'] = {
		label = 'â€¢Bigmum Sword',
		weight = 400,
		stack = true,
		close = true,
		description = 'Big Mom\'s Napoleon sword'
	},
	['jpx_bigmum_weather'] = {
		label = 'â€¢Bigmum Weather',
		weight = 200,
		stack = true,
		close = true,
		description = 'Big Mom\'s weather manipulation'
	},
	['jpx_blackbeard_coat'] = {
		label = 'â€¢Blackbeard Coat',
		weight = 250,
		stack = true,
		close = true,
		description = 'Marshall D. Teach\'s coat'
	},
	['jpx_boa_hancock'] = {
		label = 'â€¢Boa Hancock',
		weight = 200,
		stack = true,
		close = true,
		description = 'Boa Hancock accessory'
	},
	['jpx_brook_hat'] = {
		label = 'â€¢Brook Hat',
		weight = 100,
		stack = true,
		close = true,
		description = 'Brook\'s gentleman hat'
	},
	['jpx_brook_scarf'] = {
		label = 'â€¢Brook Scarf',
		weight = 75,
		stack = true,
		close = true,
		description = 'Brook\'s feathered scarf'
	},
	['jpx_brook_soul'] = {
		label = 'â€¢Brook Soul',
		weight = 50,
		stack = true,
		close = true,
		description = 'Brook\'s soul energy'
	},
	['jpx_chopper'] = {
		label = 'â€¢Chopper Hat',
		weight = 100,
		stack = true,
		close = true,
		description = 'Tony Tony Chopper\'s hat'
	},
	['jpx_chopper2'] = {
		label = 'â€¢Chopper Hat 2',
		weight = 100,
		stack = true,
		close = true,
		description = 'Another Chopper hat style'
	},
	['jpx_crocodile'] = {
		label = 'â€¢Crocodile Guantlet',
		weight = 200,
		stack = true,
		close = true,
		description = 'Sir Crocodile\'s hook'
	},
	['jpx_denmushi'] = {
		label = 'â€¢Denmushi',
		weight = 100,
		stack = true,
		close = true,
		description = 'Den Den Mushi snail phone'
	},
	['jpx_devilfruit'] = {
		label = 'â€¢Devilfruit',
		weight = 100,
		stack = true,
		close = true,
		description = 'A mysterious devil fruit'
	},
	['jpx_doflamingo'] = {
		label = 'â€¢Doflamingo Coat',
		weight = 250,
		stack = true,
		close = true,
		description = 'Donquixote Doflamingo\'s feather coat'
	},
	['jpx_eneru'] = {
		label = 'â€¢Eneru',
		weight = 200,
		stack = true,
		close = true,
		description = 'God Eneru accessory'
	},
	['jpx_eneru_trident'] = {
		label = 'â€¢Eneru Trident',
		weight = 350,
		stack = true,
		close = true,
		description = 'Eneru\'s golden trident'
	},
	['jpx_franky'] = {
		label = 'â€¢Franky Guantlet',
		weight = 250,
		stack = true,
		close = true,
		description = 'Franky\'s mechanical arms'
	},
	['jpx_garp_coat'] = {
		label = 'â€¢Garp Coat',
		weight = 250,
		stack = true,
		close = true,
		description = 'Vice Admiral Garp\'s coat'
	},
	['jpx_going_merry'] = {
		label = 'â€¢Going Merry',
		weight = 500,
		stack = true,
		close = true,
		description = 'The beloved Going Merry ship model'
	},
	['jpx_kaido_horn'] = {
		label = 'â€¢Kaido Horn',
		weight = 200,
		stack = true,
		close = true,
		description = 'Kaido\'s dragon horns'
	},
	['jpx_kozuki_oden'] = {
		label = 'â€¢Kozuki Oden',
		weight = 300,
		stack = true,
		close = true,
		description = 'Kozuki Oden\'s sword'
	},
	['jpx_kumashi'] = {
		label = 'â€¢Kumashi Doll',
		weight = 200,
		stack = true,
		close = true,
		description = 'Perona\'s Kumashi bear'
	},
	['jpx_laboon'] = {
		label = 'â€¢Laboon',
		weight = 300,
		stack = true,
		close = true,
		description = 'Laboon the whale'
	},
	['jpx_law'] = {
		label = 'â€¢Law Sword',
		weight = 300,
		stack = true,
		close = true,
		description = 'Trafalgar Law\'s Kikoku sword'
	},
	['jpx_law_hat'] = {
		label = 'â€¢Law Hat',
		weight = 100,
		stack = true,
		close = true,
		description = 'Trafalgar Law\'s spotted hat'
	},
	['jpx_luffy_coat'] = {
		label = 'â€¢Luffy Coat',
		weight = 200,
		stack = true,
		close = true,
		description = 'Monkey D. Luffy\'s coat'
	},
	['jpx_luffy_hat'] = {
		label = 'â€¢Luffy Hat',
		weight = 100,
		stack = true,
		close = true,
		description = 'Luffy\'s iconic straw hat'
	},
	['jpx_luffy_hat2'] = {
		label = 'â€¢Luffy Hat 2',
		weight = 100,
		stack = true,
		close = true,
		description = 'Another style of Luffy\'s hat'
	},
	['jpx_luffy_meat'] = {
		label = 'â€¢Luffy Meat',
		weight = 200,
		stack = true,
		close = true,
		description = 'Luffy\'s favorite meat'
	},
	['jpx_magellan_wings'] = {
		label = 'â€¢Magellan Wings',
		weight = 200,
		stack = true,
		close = true,
		description = 'Magellan\'s poison wings'
	},
	['jpx_megalo'] = {
		label = 'â€¢Megalo',
		weight = 250,
		stack = true,
		close = true,
		description = 'Princess Shirahoshi\'s shark'
	},
	['jpx_mihawk_hat'] = {
		label = 'â€¢Mihawk Hat',
		weight = 100,
		stack = true,
		close = true,
		description = 'Dracule Mihawk\'s hat'
	},
	['jpx_nami_weapon'] = {
		label = 'â€¢Nami Weapon',
		weight = 200,
		stack = true,
		close = true,
		description = 'Nami\'s Clima-Tact'
	},
	['jpx_news_coo'] = {
		label = 'â€¢News Coo',
		weight = 100,
		stack = true,
		close = true,
		description = 'News delivery seagull'
	},
	['jpx_perona_ghost'] = {
		label = 'â€¢Perona Ghost',
		weight = 50,
		stack = true,
		close = true,
		description = 'Perona\'s negative ghost'
	},
	['jpx_perona_umbrella'] = {
		label = 'â€¢Perona Umbrella',
		weight = 150,
		stack = true,
		close = true,
		description = 'Perona\'s cute umbrella'
	},
	['jpx_robin_hat'] = {
		label = 'â€¢Robin Hat',
		weight = 100,
		stack = true,
		close = true,
		description = 'Nico Robin\'s hat'
	},
	['jpx_sabo_hat'] = {
		label = 'â€¢Sabo Hat',
		weight = 100,
		stack = true,
		close = true,
		description = 'Sabo\'s top hat'
	},
	['jpx_sanji_cigarette'] = {
		label = 'â€¢Sanji Cigarette',
		weight = 25,
		stack = true,
		close = true,
		description = 'Sanji\'s cigarette'
	},
	['jpx_smoker_weapon'] = {
		label = 'â€¢Smoker Weapon',
		weight = 300,
		stack = true,
		close = true,
		description = 'Smoker\'s jitte weapon'
	},
	['jpx_usopp_bag'] = {
		label = 'â€¢Usopp Bag',
		weight = 150,
		stack = true,
		close = true,
		description = 'Usopp\'s ammunition bag'
	},
	['jpx_usopp_hat'] = {
		label = 'â€¢Usopp Hat',
		weight = 100,
		stack = true,
		close = true,
		description = 'Usopp\'s goggles and hat'
	},
	['jpx_vivi_karo'] = {
		label = 'â€¢Vivi Karo',
		weight = 150,
		stack = true,
		close = true,
		description = 'Princess Vivi\'s Karoo duck'
	},
	['jpx_whtiebeard'] = {
		label = 'â€¢Whtiebeard',
		weight = 200,
		stack = true,
		close = true,
		description = 'Edward Newgate Whitebeard'
	},
	['jpx_whtiebeard_coat'] = {
		label = 'â€¢Whtiebeard Coat',
		weight = 300,
		stack = true,
		close = true,
		description = 'Whitebeard\'s captain coat'
	},
	['jpx_whtiebeard_weapon'] = {
		label = 'â€¢Whtiebeard Weapon',
		weight = 500,
		stack = true,
		close = true,
		description = 'Whitebeard\'s massive bisento'
	},
	['jpx_yoru'] = {
		label = 'â€¢Yoru Sword',
		weight = 400,
		stack = true,
		close = true,
		description = 'Mihawk\'s supreme grade sword Yoru'
	},
	['jpx_zoro_samurai'] = {
		label = 'â€¢Zoro Samurai',
		weight = 300,
		stack = true,
		close = true,
		description = 'Zoro\'s samurai gear'
	},
	['jpx_zoro_wado'] = {
		label = 'â€¢Wado Sword',
		weight = 300,
		stack = true,
		close = true,
		description = 'Zoro\'s Wado Ichimonji sword'
	},
	['jpx_pirate_magic_circle'] = {
		label = 'â€¢Pirate Magic Circle',
		weight = 250,
		stack = true,
		close = true,
		description = 'A magical pirate circle'
	},
	-- Summer/Seaside Collection
	['jpx_bear_water_gun'] = {
		label = 'â€¢Bear Water Gun',
		weight = 150,
		stack = true,
		close = true,
		description = 'A bear-shaped water gun'
	},
	['jpx_duck_water_gun'] = {
		label = 'â€¢Duck Water Gun',
		weight = 150,
		stack = true,
		close = true,
		description = 'A duck-shaped water gun'
	},
	['jpx_duckling_backpack'] = {
		label = 'â€¢Duckling Backpack',
		weight = 200,
		stack = true,
		close = true,
		description = 'A cute duckling backpack'
	},
	['jpx_sm backpack'] = {
		label = 'â€¢Seaside Backpack',
		weight = 200,
		stack = true,
		close = true,
		description = 'A summer seaside backpack'
	},
	['jpx_sm doll'] = {
		label = 'â€¢Seaside Doll',
		weight = 150,
		stack = true,
		close = true,
		description = 'A seaside-themed doll'
	},
	['jpx_sm_bag'] = {
		label = 'â€¢Seaside Bag',
		weight = 150,
		stack = true,
		close = true,
		description = 'A beach bag'
	},
	['jpx_sm_bag2'] = {
		label = 'â€¢Seaside Bag 2',
		weight = 150,
		stack = true,
		close = true,
		description = 'Another seaside bag style'
	},
	['jpx_sm_bucket'] = {
		label = 'â€¢Seaside Bucket',
		weight = 100,
		stack = true,
		close = true,
		description = 'A beach sand bucket'
	},
	['jpx_sm_candy'] = {
		label = 'â€¢Seaside Candy',
		weight = 50,
		stack = true,
		close = true,
		description = 'Sweet seaside candy'
	},
	['jpx_sm_copter'] = {
		label = 'â€¢Seaside Copter',
		weight = 200,
		stack = true,
		close = true,
		description = 'A beach helicopter toy'
	},
	['jpx_sm_dolphin'] = {
		label = 'â€¢Seaside Dolphin',
		weight = 150,
		stack = true,
		close = true,
		description = 'A friendly dolphin'
	},
	['jpx_sm_duck'] = {
		label = 'â€¢Seaside Duck',
		weight = 100,
		stack = true,
		close = true,
		description = 'A rubber duck for the beach'
	},
	['jpx_sm_duck2'] = {
		label = 'â€¢Seaside Duck 2',
		weight = 100,
		stack = true,
		close = true,
		description = 'Another seaside duck'
	},
	['jpx_sm_duck_circle'] = {
		label = 'â€¢Seaside Circle',
		weight = 150,
		stack = true,
		close = true,
		description = 'A duck-shaped pool float'
	},
	['jpx_sm_duck_pipe'] = {
		label = 'â€¢Seaside Duck Pipe',
		weight = 100,
		stack = true,
		close = true,
		description = 'A duck-shaped water pipe'
	},
	['jpx_sm_duckling'] = {
		label = 'â€¢Seaside Duckling',
		weight = 75,
		stack = true,
		close = true,
		description = 'A small duckling toy'
	},
	['jpx_sm_ducky'] = {
		label = 'â€¢Seaside Ducky',
		weight = 100,
		stack = true,
		close = true,
		description = 'A cute ducky for the sea'
	},
	['jpx_sm_float'] = {
		label = 'â€¢Seaside Float',
		weight = 200,
		stack = true,
		close = true,
		description = 'An inflatable pool float'
	},
	['jpx_sm_floor'] = {
		label = 'â€¢Seaside Floor',
		weight = 300,
		stack = true,
		close = true,
		description = 'Beach floor decoration'
	},
	['jpx_sm_floor2'] = {
		label = 'â€¢Seaside Floor 2',
		weight = 300,
		stack = true,
		close = true,
		description = 'Another beach floor style'
	},
	['jpx_sm_sand_floor'] = {
		label = 'â€¢Seaside Sand Floor',
		weight = 300,
		stack = true,
		close = true,
		description = 'Sandy beach floor'
	},
	['jpx_sm_glasses'] = {
		label = 'â€¢Seaside Glasses',
		weight = 50,
		stack = true,
		close = true,
		description = 'Cool sunglasses for the beach'
	},
	['jpx_sm_glasses2'] = {
		label = 'â€¢Seaside Glasses 2',
		weight = 50,
		stack = true,
		close = true,
		description = 'Another pair of beach sunglasses'
	},
	['jpx_sm_octopus'] = {
		label = 'â€¢Seaside Octopus',
		weight = 150,
		stack = true,
		close = true,
		description = 'A friendly sea octopus'
	},
	['jpx_sm_shark'] = {
		label = 'â€¢Seaside Shark',
		weight = 200,
		stack = true,
		close = true,
		description = 'A toy shark for the beach'
	},
	['jpx_sm_snorkle'] = {
		label = 'â€¢Seaside Snorkle',
		weight = 100,
		stack = true,
		close = true,
		description = 'Snorkeling gear'
	},
	['jpx_sm_snorkle2'] = {
		label = 'â€¢Seaside Snorkle 2',
		weight = 100,
		stack = true,
		close = true,
		description = 'Another snorkeling set'
	},
	['jpx_sm_star'] = {
		label = 'â€¢Seaside Star',
		weight = 75,
		stack = true,
		close = true,
		description = 'A beautiful starfish'
	},
	['jpx_sm_sun'] = {
		label = 'â€¢Seaside Sun',
		weight = 150,
		stack = true,
		close = true,
		description = 'A bright summer sun'
	},
	['jpx_sm_sun2'] = {
		label = 'â€¢Seaside Sun 2',
		weight = 150,
		stack = true,
		close = true,
		description = 'Another summer sun design'
	},
	['jpx_sm_sunflower'] = {
		label = 'â€¢Seaside Sunflower',
		weight = 100,
		stack = true,
		close = true,
		description = 'A bright sunflower'
	},
	['jpx_sm_tank'] = {
		label = 'â€¢Seaside Tank',
		weight = 150,
		stack = true,
		close = true,
		description = 'A water tank for the beach'
	},
	['jpx_sm_tank2'] = {
		label = 'â€¢Seaside Tank 2',
		weight = 150,
		stack = true,
		close = true,
		description = 'Another seaside tank'
	},
	['jpx_sm_wings'] = {
		label = 'â€¢Seaside Wings',
		weight = 100,
		stack = true,
		close = true,
		description = 'Wings for beach adventures'
	},
	['jpx_sm_wings2'] = {
		label = 'â€¢Seaside Wings 2',
		weight = 100,
		stack = true,
		close = true,
		description = 'Another pair of seaside wings'
	},
	['jpx_sm_wink'] = {
		label = 'â€¢Seaside Wink',
		weight = 50,
		stack = true,
		close = true,
		description = 'A cute winking accessory'
	},
	['jpx_water_gun_ufo'] = {
		label = 'â€¢UFO Water Gun',
		weight = 150,
		stack = true,
		close = true,
		description = 'A UFO-shaped water gun'
	},
	['jpx_water_gun_watermelon'] = {
		label = 'â€¢Watermelon Water Gun',
		weight = 150,
		stack = true,
		close = true,
		description = 'A watermelon-shaped water gun'
	},
	['jpx_watermelon_cat'] = {
		label = 'â€¢Watermelon Cat',
		weight = 100,
		stack = true,
		close = true,
		description = 'A cat with watermelon theme'
	},
	['jpx_watermelon_cat2'] = {
		label = 'â€¢Watermelon Cat 2',
		weight = 100,
		stack = true,
		close = true,
		description = 'Another watermelon cat'
	},
-- Unicorn Collection
	['jpx_unicorn'] = {
		label = 'â€¢Unicorn',
		weight = 200,
		stack = true,
		close = true,
		description = 'A magical unicorn'
	},
	['jpx_unicorn2'] = {
		label = 'â€¢Unicorn 2',
		weight = 200,
		stack = true,
		close = true,
		description = 'Another magical unicorn'
	},
	['jpx_unicorn_ears'] = {
		label = 'â€¢Unicorn Ears',
		weight = 75,
		stack = true,
		close = true,
		description = 'Mystical unicorn ears'
	},
	['jpx_unicorn_horn'] = {
		label = 'â€¢Unicorn Horn',
		weight = 100,
		stack = true,
		close = true,
		description = 'A magical unicorn horn'
	},
	['jpx_unicorn_staff'] = {
		label = 'â€¢Unicorn Staff',
		weight = 250,
		stack = true,
		close = true,
		description = 'A staff with unicorn magic'
	},
	['jpx_unicorn_tail'] = {
		label = 'â€¢Unicorn Tail',
		weight = 100,
		stack = true,
		close = true,
		description = 'A flowing unicorn tail'
	},
	['jpx_unicorn_wings'] = {
		label = 'â€¢Unicorn Wings',
		weight = 150,
		stack = true,
		close = true,
		description = 'Ethereal unicorn wings'
	},
	['jpx_unicorn_wings2'] = {
		label = 'â€¢Unicorn Wings 2',
		weight = 150,
		stack = true,
		close = true,
		description = 'Another pair of unicorn wings'
	},

	['jpx_circle_ninja'] = {
		label = 'Circle Ninja',
		weight = 500,
		stack = true,
		close = true,
		description = 'Circle Ninja'
	},

	['jpx_jump_force_weapon'] = {
		label = 'Jump Force Weapon',
		weight = 500,
		stack = true,
		close = true,
		description = 'Jump Force Weapon'
	},

	['jpx_jump_force_knife_weapon'] = {
		label = 'Jump Force Knife Weapon',
		weight = 500,
		stack = true,
		close = true,
		description = 'Jump Force Knife Weapon'
	},

	['jpx_sasuke_mask_weapon'] = {
		label = 'Sasuke Mask Weapon',
		weight = 500,
		stack = true,
		close = true,
		description = 'Sasuke Mask Weapon'
	},

	['jpx_apostle_wings'] = {
		label = 'Apostle Wings',
		weight = 500,
		stack = true,
		close = true,
		description = 'Apostle Wings'
	},

	['jpx_archangels_wings'] = {
		label = 'Archangels Wings',
		weight = 500,
		stack = true,
		close = true,
		description = 'Archangels Wings'
	},

	['jpx_arog_fairy_wings'] = {
		label = 'Arog Fairy Wings',
		weight = 500,
		stack = true,
		close = true,
		description = 'Arog Fairy Wings'
	},

	['jpx_arsadim_wings'] = {
		label = 'Arsadim Wings',
		weight = 500,
		stack = true,
		close = true,
		description = 'Arsadim Wings'
	},

	['jpx_bahamut_wings'] = {
		label = 'Bahamut Wings',
		weight = 500,
		stack = true,
		close = true,
		description = 'Bahamut Wings'
	},

	['jpx_beast_wings'] = {
		label = 'Beast Wings',
		weight = 500,
		stack = true,
		close = true,
		description = 'Beast Wings'
	},

	['jpx_bio_dragon_wings'] = {
		label = 'Bio Dragon Wings',
		weight = 500,
		stack = true,
		close = true,
		description = 'Bio Dragon Wings'
	},

	['jpx_blue_phoenix_wings'] = {
		label = 'Blue Phoenix Wings',
		weight = 500,
		stack = true,
		close = true,
		description = 'Blue Phoenix Wings'
	},

	['jpx_commander_wings'] = {
		label = 'Commander Wings',
		weight = 500,
		stack = true,
		close = true,
		description = 'Commander Wings'
	},

	['jpx_dark_demon_wings'] = {
		label = 'Dark Demon Wings',
		weight = 500,
		stack = true,
		close = true,
		description = 'Dark Demon Wings'
	},

	['jpx_dark_devil_wings'] = {
		label = 'Dark Devil Wings',
		weight = 500,
		stack = true,
		close = true,
		description = 'Dark Devil Wings'
	},

	['jpx_dark_dragon_wings'] = {
		label = 'Dark Dragon Wings',
		weight = 500,
		stack = true,
		close = true,
		description = 'Dark Dragon Wings'
	},

	['jpx_dark_vampire_wings'] = {
		label = 'Dark Vampire Wings',
		weight = 500,
		stack = true,
		close = true,
		description = 'Dark Vampire Wings'
	},

	['jpx_demonic_angel_wings'] = {
		label = 'Demonic Angel Wings',
		weight = 500,
		stack = true,
		close = true,
		description = 'Demonic Angel Wings'
	},

	['jpx_diablo_wings'] = {
		label = 'Diablo Wings',
		weight = 500,
		stack = true,
		close = true,
		description = 'Diablo Wings'
	},

	['jpx_ele_wings'] = {
		label = 'Ele Wings',
		weight = 500,
		stack = true,
		close = true,
		description = 'Ele Wings'
	},

	['jpx_ele_wings2'] = {
		label = 'Ele Wings 2',
		weight = 500,
		stack = true,
		close = true,
		description = 'Ele Wings 2'
	},

	['jpx_general_wings'] = {
		label = 'General Wings',
		weight = 500,
		stack = true,
		close = true,
		description = 'General Wings'
	},

	['jpx_gold_angel_wings'] = {
		label = 'Gold Angel Wings',
		weight = 500,
		stack = true,
		close = true,
		description = 'Gold Angel Wings'
	},

	['jpx_high_seraphim_wings'] = {
		label = 'High Seraphim Wings',
		weight = 500,
		stack = true,
		close = true,
		description = 'High Seraphim Wings'
	},

	['jpx_holy_demon_wings'] = {
		label = 'Holy Demon Wings',
		weight = 500,
		stack = true,
		close = true,
		description = 'Holy Demon Wings'
	},

	['jpx_holy_fairy_wings'] = {
		label = 'Holy Fairy Wings',
		weight = 500,
		stack = true,
		close = true,
		description = 'Holy Fairy Wings'
	},

	['jpx_holy_golden_wings'] = {
		label = 'Holy Golden Wings',
		weight = 500,
		stack = true,
		close = true,
		description = 'Holy Golden Wings'
	},

	['jpx_holy_heaven_wings'] = {
		label = 'Holy Heaven Wings',
		weight = 500,
		stack = true,
		close = true,
		description = 'Holy Heaven Wings'
	},

	['jpx_holy_legend_wings'] = {
		label = 'Holy Legend Wings',
		weight = 500,
		stack = true,
		close = true,
		description = 'Holy Legend Wings'
	},

	['jpx_ice_frost_wings'] = {
		label = 'Ice Frost Wings',
		weight = 500,
		stack = true,
		close = true,
		description = 'Ice Frost Wings'
	},

	['jpx_incubus_morphaz_wings'] = {
		label = 'Incubus Morphaz Wings',
		weight = 500,
		stack = true,
		close = true,
		description = 'Incubus Morphaz Wings'
	},

	['jpx_kaishur_wings'] = {
		label = 'Kaishur Wings',
		weight = 500,
		stack = true,
		close = true,
		description = 'Kaishur Wings'
	},

	['jpx_legendary_wings'] = {
		label = 'Legendary Wings',
		weight = 500,
		stack = true,
		close = true,
		description = 'Legendary Wings'
	},

	['jpx_light_angel_wings'] = {
		label = 'Light Angel Wings',
		weight = 500,
		stack = true,
		close = true,
		description = 'Light Angel Wings'
	},

	['jpx_lune_wings'] = {
		label = 'Lune Wings',
		weight = 500,
		stack = true,
		close = true,
		description = 'Lune Wings'
	},

	['jpx_mechanic_wings'] = {
		label = 'Mechanic Wings',
		weight = 500,
		stack = true,
		close = true,
		description = 'Mechanic Wings'
	},

	['jpx_minos_wings'] = {
		label = 'Minos Wings',
		weight = 500,
		stack = true,
		close = true,
		description = 'Minos Wings'
	},

	['jpx_niao_wings'] = {
		label = 'Niao Wings',
		weight = 500,
		stack = true,
		close = true,
		description = 'Niao Wings'
	},

	['jpx_platinum_wings'] = {
		label = 'Platinum Wings',
		weight = 500,
		stack = true,
		close = true,
		description = 'Platinum Wings'
	},

	['jpx_spiky_wings'] = {
		label = 'Spiky Wings',
		weight = 500,
		stack = true,
		close = true,
		description = 'Spiky Wings'
	},

	['jpx_twin_dragon_wings'] = {
		label = 'Twin Dragon Wings',
		weight = 500,
		stack = true,
		close = true,
		description = 'Twin Dragon Wings'
	},

	['jpx_wings1'] = {
		label = 'Wings 1',
		weight = 500,
		stack = true,
		close = true,
		description = 'Wings 1'
	},

	['jpx_wings2'] = {
		label = 'Wings 2',
		weight = 500,
		stack = true,
		close = true,
		description = 'Wings 2'
	},

	['jpx_wings3'] = {
		label = 'Wings 3',
		weight = 500,
		stack = true,
		close = true,
		description = 'Wings 3'
	},

	['jpx_wings4'] = {
		label = 'Wings 4',
		weight = 500,
		stack = true,
		close = true,
		description = 'Wings 4'
	},

	['jpx_wings5'] = {
		label = 'Wings 5',
		weight = 500,
		stack = true,
		close = true,
		description = 'Wings 5'
	},

	['jpx_wings6'] = {
		label = 'Wings 6',
		weight = 500,
		stack = true,
		close = true,
		description = 'Wings 6'
	},

	['jpx_wings7'] = {
		label = 'Wings 7',
		weight = 500,
		stack = true,
		close = true,
		description = 'Wings 7'
	},

	['jpx_wings8'] = {
		label = 'Wings 8',
		weight = 500,
		stack = true,
		close = true,
		description = 'Wings 8'
	},

	['jpx_little_cat_breast'] = {
		label = 'Little Cat Breast',
		weight = 500,
		stack = true,
		close = true,
		description = 'Little Cat Breast'
	},

	['jpx_little_cat_dance'] = {
		label = 'Little Cat Dance',
		weight = 500,
		stack = true,
		close = true,
		description = 'Little Cat Dance'
	},

	['jpx_little_cat_walking'] = {
		label = 'Little Cat Walking',
		weight = 500,
		stack = true,
		close = true,
		description = 'Little Cat Walking'
	},

	['jpx_little_cat_breast2'] = {
		label = 'Little Cat Breast 2',
		weight = 500,
		stack = true,
		close = true,
		description = 'Little Cat Breast 2'
	},

	['jpx_little_cat_dance2'] = {
		label = 'Little Cat Dance 2',
		weight = 500,
		stack = true,
		close = true,
		description = 'Little Cat Dance 2'
	},

	['jpx_little_cat_walking2'] = {
		label = 'Little Cat Walking 2',
		weight = 500,
		stack = true,
		close = true,
		description = 'Little Cat Walking 2'
	},

	['jpx_magic_circle'] = {
		label = 'Magic Circle',
		weight = 500,
		stack = true,
		close = true,
		description = 'Magic Circle'
	},
	['jpx_magic_circle2'] = {
		label = 'Magic Circle 2',
		weight = 500,
		stack = true,
		close = true,
		description = 'Magic Circle 2'
	},
	['jpx_magic_circle3'] = {
		label = 'Magic Circle 3',
		weight = 500,
		stack = true,
		close = true,
		description = 'Magic Circle 3'
	},
	['jpx_magic_circle4'] = {
		label = 'Magic Circle 4',
		weight = 500,
		stack = true,
		close = true,
		description = 'Magic Circle 4'
	},
	['jpx_magic_circle5'] = {
		label = 'Magic Circle 5',
		weight = 500,
		stack = true,
		close = true,
		description = 'Magic Circle 5'
	},
	['jpx_magic_circle6'] = {
		label = 'Magic Circle 6',
		weight = 500,
		stack = true,
		close = true,
		description = 'Magic Circle 6'
	},
	['jpx_magic_circle7'] = {
		label = 'Magic Circle 7',
		weight = 500,
		stack = true,
		close = true,
		description = 'Magic Circle 7'
	},
	['jpx_magic_circle8'] = {
		label = 'Magic Circle 8',
		weight = 500,
		stack = true,
		close = true,
		description = 'Magic Circle 8'
	},
	['jpx_magic_circle9'] = {
		label = 'Magic Circle 9',
		weight = 500,
		stack = true,
		close = true,
		description = 'Magic Circle 9'
	},
	['jpx_magic_circle10'] = {
		label = 'Magic Circle 10',
		weight = 500,
		stack = true,
		close = true,
		description = 'Magic Circle 10'
	},
	['jpx_magic_circle11'] = {
		label = 'Magic Circle 11',
		weight = 500,
		stack = true,
		close = true,
		description = 'Magic Circle 11'
	},
	['jpx_magic_circle12'] = {
		label = 'Magic Circle 12',
		weight = 500,
		stack = true,
		close = true,
		description = 'Magic Circle 12'
	},
	['jpx_magic_circle13'] = {
		label = 'Magic Circle 13',
		weight = 500,
		stack = true,
		close = true,
		description = 'Magic Circle 13'
	},
	['jpx_magic_circle14'] = {
		label = 'Magic Circle 14',
		weight = 500,
		stack = true,
		close = true,
		description = 'Magic Circle 14'
	},
	['jpx_magic_circle15'] = {
		label = 'Magic Circle 15',
		weight = 500,
		stack = true,
		close = true,
		description = 'Magic Circle 15'
	},
	['jpx_magic_circle16'] = {
		label = 'Magic Circle 16',
		weight = 500,
		stack = true,
		close = true,
		description = 'Magic Circle 16'
	},
	['jpx_magic_circle17'] = {
		label = 'Magic Circle 17',
		weight = 500,
		stack = true,
		close = true,
		description = 'Magic Circle 17'
	},
	['jpx_magic_circle18'] = {
		label = 'Magic Circle 18',
		weight = 500,
		stack = true,
		close = true,
		description = 'Magic Circle 18'
	},
	['jpx_magic_circle19'] = {
		label = 'Magic Circle 19',
		weight = 500,
		stack = true,
		close = true,
		description = 'Magic Circle 19'
	},
	['jpx_magic_circle20'] = {
		label = 'Magic Circle 20',
		weight = 500,
		stack = true,
		close = true,
		description = 'Magic Circle 20'
	},
	['jpx_magic_circle21'] = {
		label = 'Magic Circle 21',
		weight = 500,
		stack = true,
		close = true,
		description = 'Magic Circle 21'
	},
	['jpx_magic_circle22'] = {
		label = 'Magic Circle 22',
		weight = 500,
		stack = true,
		close = true,
		description = 'Magic Circle 22'
	},
	['jpx_magic_circle23'] = {
		label = 'Magic Circle 23',
		weight = 500,
		stack = true,
		close = true,
		description = 'Magic Circle 23'
	},
	['jpx_magic_circle24'] = {
		label = 'Magic Circle 24',
		weight = 500,
		stack = true,
		close = true,
		description = 'Magic Circle 24'
	},
	['jpx_magic_circle25'] = {
		label = 'Magic Circle 25',
		weight = 500,
		stack = true,
		close = true,
		description = 'Magic Circle 25'
	},
	['jpx_magic_circle26'] = {
		label = 'Magic Circle 26',
		weight = 500,
		stack = true,
		close = true,
		description = 'Magic Circle 26'
	},
	['jpx_magic_circle27'] = {
		label = 'Magic Circle 27',
		weight = 500,
		stack = true,
		close = true,
		description = 'Magic Circle 27'
	},
	['jpx_magic_circle28'] = {
		label = 'Magic Circle 28',
		weight = 500,
		stack = true,
		close = true,
		description = 'Magic Circle 28'
	},
	['jpx_magic_circle29'] = {
		label = 'Magic Circle 29',
		weight = 500,
		stack = true,
		close = true,
		description = 'Magic Circle 29'
	},
	['jpx_magic_circle30'] = {
		label = 'Magic Circle 30',
		weight = 500,
		stack = true,
		close = true,
		description = 'Magic Circle 30'
	},
	['jpx_shorthair_cat'] = {
		label = 'Shorthair Cat',
		weight = 500,
		stack = true,
		close = true,
		description = 'Shorthair Cat'
	},
	['jpx_shorthair_cat2'] = {
		label = 'Shorthair Cat 2',
		weight = 500,
		stack = true,
		close = true,
		description = 'Shorthair Cat 2'
	},
	['jpx_shorthair_cat3'] = {
		label = 'Shorthair Cat 3',
		weight = 500,
		stack = true,
		close = true,
		description = 'Shorthair Cat 3'
	},
	['jpx_shorthair_cat4'] = {
		label = 'Shorthair Cat 4',
		weight = 500,
		stack = true,
		close = true,
		description = 'Shorthair Cat 4'
	},
	['jpx_shorthair_cat5'] = {
		label = 'Shorthair Cat 5',
		weight = 500,
		stack = true,
		close = true,
		description = 'Shorthair Cat 5'
	},
	['jpx_shorthair_cat6'] = {
		label = 'Shorthair Cat 6',
		weight = 500,
		stack = true,
		close = true,
		description = 'Shorthair Cat 6'
	},
	['jpx_shorthair_cat7'] = {
		label = 'Shorthair Cat 7',
		weight = 500,
		stack = true,
		close = true,
		description = 'Shorthair Cat 7'
	},
	['jpx_shorthair_cat8'] = {
		label = 'Shorthair Cat 8',
		weight = 500,
		stack = true,
		close = true,
		description = 'Shorthair Cat 8'
	},
	['jpx_carrot'] = {
		label = 'Carrot',
		weight = 500,
		stack = true,
		close = true,
		description = 'Carrot'
	},
	['jpx_carrot_backpack'] = {
		label = 'Carrot Backpack',
		weight = 500,
		stack = true,
		close = true,
		description = 'Carrot Backpack'
	},
	['jpx_carrot_slippers'] = {
		label = 'Carrot Slippers',
		weight = 500,
		stack = true,
		close = true,
		description = 'Carrot Slippers'
	},
	['jpx_carrot_slippers2'] = {
		label = 'Carrot Slippers 2',
		weight = 500,
		stack = true,
		close = true,
		description = 'Carrot Slippers 2'
	},

    ['jpx_bee_jar'] = {
		label = 'Bee Jar',
		weight = 500,
		stack = true,
		close = true,
		description = 'Bee Jar'
	},
	['jpx_bee_bucket'] = {
		label = 'Bee Bucket',
		weight = 500,
		stack = true,
		close = true,
		description = 'Bee Bucket'
	},
	['jpx_bee'] = {
		label = 'Bee',
		weight = 500,
		stack = true,
		close = true,
		description = 'Bee'
	},
	['jpx_bee_hat'] = {
		label = 'Bee Hat',
		weight = 500,
		stack = true,
		close = true,
		description = 'Bee Hat'
	},
	['jpx_bee_wings'] = {
		label = 'Bee Wings',
		weight = 500,
		stack = true,
		close = true,
		description = 'Bee Wings'
	},
	['jpx_chicky_head'] = {
		label = 'Chicky Head',
		weight = 500,
		stack = true,
		close = true,
		description = 'Chicky Head'
	},
	['jpx_chicky_backpack'] = {
		label = 'Chicky Backpack',
		weight = 500,
		stack = true,
		close = true,
		description = 'Chicky Backpack'
	},
	['jpx_chicky_slippers'] = {
		label = 'Chicky Slippers',
		weight = 500,
		stack = true,
		close = true,
		description = 'Chicky Slippers'
	},
	['jpx_chicky_slippers2'] = {
		label = 'Chicky Slippers 2',
		weight = 500,
		stack = true,
		close = true,
		description = 'Chicky Slippers 2'
	},
	['jpx_chicky_egg'] = {
		label = 'Chicky Egg',
		weight = 500,
		stack = true,
		close = true,
		description = 'Chicky Egg'
	},
	['jpx_chicky_shooting'] = {
		label = 'Chicky Shooting',
		weight = 500,
		stack = true,
		close = true,
		description = 'Chicky Shooting'
	},
	['jpx_chicky_flying'] = {
		label = 'Chicky Flying',
		weight = 500,
		stack = true,
		close = true,
		description = 'Chicky Flying'
	},
	['jpx_chicky_running'] = {
		label = 'Chicky Running',
		weight = 500,
		stack = true,
		close = true,
		description = 'Chicky Running'
	},
	['jpx_kawaii_doll_whale'] = {
		label = 'Kawaii Doll Whale',
		weight = 500,
		stack = true,
		close = true,
		description = 'Kawaii Doll Whale'
	},
	['jpx_kawaii_doll_dragon'] = {
		label = 'Kawaii Doll Dragon',
		weight = 500,
		stack = true,
		close = true,
		description = 'Kawaii Doll Dragon'
	},
	['jpx_kawaii_doll_airplane'] = {
		label = 'Kawaii Doll Airplane',
		weight = 500,
		stack = true,
		close = true,
		description = 'Kawaii Doll Airplane'
	},
	['jpx_kawaii_doll'] = {
		label = 'Kawaii Doll',
		weight = 500,
		stack = true,
		close = true,
		description = 'Kawaii Doll'
	},
	['jpx_kawaii_doll_whale2'] = {
		label = 'Kawaii Doll Whale 2',
		weight = 500,
		stack = true,
		close = true,
		description = 'Kawaii Doll Whale 2'
	},
	['jpx_kawaii_doll_dragon2'] = {
		label = 'Kawaii Doll Dragon 2',
		weight = 500,
		stack = true,
		close = true,
		description = 'Kawaii Doll Dragon 2'
	},
	['jpx_kawaii_doll_airplane2'] = {
		label = 'Kawaii Doll Airplane 2',
		weight = 500,
		stack = true,
		close = true,
		description = 'Kawaii Doll Airplane 2'
	},
	['jpx_kawaii_doll2'] = {
		label = 'Kawaii Doll 2',
		weight = 500,
		stack = true,
		close = true,
		description = 'Kawaii Doll 2'
	},
	['jpx_pea'] = {
		label = 'Pea',
		weight = 500,
		stack = true,
		close = true,
		description = 'Pea'
	},
	['jpx_pea_backpack'] = {
		label = 'Pea Backpack',
		weight = 500,
		stack = true,
		close = true,
		description = 'Pea Backpack'
	},
	['jpx_pea_slippers'] = {
		label = 'Pea Slippers',
		weight = 500,
		stack = true,
		close = true,
		description = 'Pea Slippers'
	},
	['jpx_pea_slippers2'] = {
		label = 'Pea Slippers 2',
		weight = 500,
		stack = true,
		close = true,
		description = 'Pea Slippers 2'
	},

	--Little Doll Fashion--
	['jpx_pompompurin_moon'] = {
		label = 'Pompompurin Moon',
		weight = 500,
		stack = true,
		close = true,
		description = 'Pompompurin Moon'
	},
	['jpx_kitty_fur'] = {
		label = 'Kitty Fur',
		weight = 500,
		stack = true,
		close = true,
		description = 'Kitty Fur'
	},
	['jpx_gudetama_doll'] = {
		label = 'Gudetama Doll',
		weight = 500,
		stack = true,
		close = true,
		description = 'Gudetama Doll'
	},
	['jpx_gudetama_doll2'] = {
		label = 'Gudetama Doll 2',
		weight = 500,
		stack = true,
		close = true,
		description = 'Gudetama Doll 2'
	},
	['jpx_keroppi_doll'] = {
		label = 'Keroppi Doll',
		weight = 500,
		stack = true,
		close = true,
		description = 'Keroppi Doll'
	},
	['jpx_kitty_doll'] = {
		label = 'Kitty Doll',
		weight = 500,
		stack = true,
		close = true,
		description = 'Kitty Doll'
	},
	['jpx_kitty_doll2'] = {
		label = 'Kitty Doll 2',
		weight = 500,
		stack = true,
		close = true,
		description = 'Kitty Doll 2'
	},
	['jpx_cinnamoroll_backpack'] = {
		label = 'Cinnamoroll Backpack',
		weight = 500,
		stack = true,
		close = true,
		description = 'Cinnamoroll Backpack'
	},
	['jpx_kitty_backpack'] = {
		label = 'Kitty Backpack',
		weight = 500,
		stack = true,
		close = true,
		description = 'Kitty Backpack'
	},
	['jpx_kuromi_tail'] = {
		label = 'Kuromi Tail',
		weight = 500,
		stack = true,
		close = true,
		description = 'Kuromi Tail'
	},
	['jpx_kuromi_wings'] = {
		label = 'Kuromi Wings',
		weight = 500,
		stack = true,
		close = true,
		description = 'Kuromi Wings'
	},
	['jpx_pochacco_backpack'] = {
		label = 'Pochacco Backpack',
		weight = 500,
		stack = true,
		close = true,
		description = 'Pochacco Backpack'
	},
	['jpx_pochacco_doll'] = {
		label = 'Pochacco Doll',
		weight = 500,
		stack = true,
		close = true,
		description = 'Pochacco Doll'
	},
	['jpx_pompompurin_bag'] = {
		label = 'Pompompurin Bag',
		weight = 500,
		stack = true,
		close = true,
		description = 'Pompompurin Bag'
	},
	['jpx_pompompurin_doll'] = {
		label = 'Pompompurin Doll',
		weight = 500,
		stack = true,
		close = true,
		description = 'Pompompurin Doll'
	},
	['jpx_my_melody_bag'] = {
		label = 'My Melody Bag',
		weight = 500,
		stack = true,
		close = true,
		description = 'My Melody Bag'
	},
	['jpx_cinnamoroll_ring'] = {
		label = 'Cinnamoroll Ring',
		weight = 500,
		stack = true,
		close = true,
		description = 'Cinnamoroll Ring'
	},
	['jpx_kitty_ring'] = {
		label = 'Kitty Ring',
		weight = 500,
		stack = true,
		close = true,
		description = 'Kitty Ring'
	},
	['jpx_kuromi_ring'] = {
		label = 'Kuromi Ring',
		weight = 500,
		stack = true,
		close = true,
		description = 'Kuromi Ring'
	},
	['jpx_my_melody_ring'] = {
		label = 'My Melody Ring',
		weight = 500,
		stack = true,
		close = true,
		description = 'My Melody Ring'
	},
	['jpx_pochacco_ring'] = {
		label = 'Pochacco Ring',
		weight = 500,
		stack = true,
		close = true,
		description = 'Pochacco Ring'
	},
	['jpx_pompompurin_ring'] = {
		label = 'Pompompurin Ring',
		weight = 500,
		stack = true,
		close = true,
		description = 'Pompompurin Ring'
	},
	['jpx_cinnamoroll_dropping'] = {
		label = 'Cinnamoroll Dropping',
		weight = 500,
		stack = true,
		close = true,
		description = 'Cinnamoroll Dropping'
	},
	['jpx_gudetama_dropping'] = {
		label = 'Gudetama Dropping',
		weight = 500,
		stack = true,
		close = true,
		description = 'Gudetama Dropping'
	},
	['jpx_keroppi_dropping'] = {
		label = 'Keroppi Dropping',
		weight = 500,
		stack = true,
		close = true,
		description = 'Keroppi Dropping'
	},
	['jpx_kitty_headwear'] = {
		label = 'Kitty Headwear',
		weight = 500,
		stack = true,
		close = true,
		description = 'Kitty Headwear'
	},
	['jpx_cinnamoroll_drink'] = {
		label = 'Cinnamoroll Drink',
		weight = 500,
		stack = true,
		close = true,
		description = 'Cinnamoroll Drink'
	},
	['jpx_cinnamoroll_headwear'] = {
		label = 'Cinnamoroll Headwear',
		weight = 500,
		stack = true,
		close = true,
		description = 'Cinnamoroll Headwear'
	},
	['jpx_kitty_headband'] = {
		label = 'Kitty Headband',
		weight = 500,
		stack = true,
		close = true,
		description = 'Kitty Headband'
	},
	['jpx_kitty_headband2'] = {
		label = 'Kitty Headband 2',
		weight = 500,
		stack = true,
		close = true,
		description = 'Kitty Headband 2'
	},
	['jpx_kuromi_headband'] = {
		label = 'Kuromi Headband',
		weight = 500,
		stack = true,
		close = true,
		description = 'Kuromi Headband'
	},
	['jpx_my_melody_headband'] = {
		label = 'My Melody Headband',
		weight = 500,
		stack = true,
		close = true,
		description = 'My Melody Headband'
	},
	['jpx_my_melody_headwear'] = {
		label = 'My Melody Headwear',
		weight = 500,
		stack = true,
		close = true,
		description = 'My Melody Headwear'
	},
	['jpx_pochacco_hat'] = {
		label = 'Pochacco Hat',
		weight = 500,
		stack = true,
		close = true,
		description = 'Pochacco Hat'
	},
	['jpx_pompompurin_dropping'] = {
		label = 'Pompompurin Dropping',
		weight = 500,
		stack = true,
		close = true,
		description = 'Pompompurin Dropping'
	},
	['jpx_kitty_umbrella'] = {
		label = 'Kitty Umbrella',
		weight = 500,
		stack = true,
		close = true,
		description = 'Kitty Umbrella'
	},
	['jpx_cinnamoroll_bag'] = {
		label = 'Cinnamoroll Bag',
		weight = 500,
		stack = true,
		close = true,
		description = 'Cinnamoroll Bag'
	},
	['jpx_cinnamoroll_plushie'] = {
		label = 'Cinnamoroll Plushie',
		weight = 500,
		stack = true,
		close = true,
		description = 'Cinnamoroll Plushie'
	},
	['jpx_kitty_bag'] = {
		label = 'Kitty Bag',
		weight = 500,
		stack = true,
		close = true,
		description = 'Kitty Bag'
	},
	['jpx_kitty_plushie'] = {
		label = 'Kitty Plushie',
		weight = 500,
		stack = true,
		close = true,
		description = 'Kitty Plushie'
	},
	['jpx_kuromi_plushie'] = {
		label = 'Kuromi Plushie',
		weight = 500,
		stack = true,
		close = true,
		description = 'Kuromi Plushie'
	},
	['jpx_pochacco_chips'] = {
		label = 'Pochacco Chips',
		weight = 500,
		stack = true,
		close = true,
		description = 'Pochacco Chips'
	},
	['jpx_pochacco_plushie'] = {
		label = 'Pochacco Plushie',
		weight = 500,
		stack = true,
		close = true,
		description = 'Pochacco Plushie'
	},
	['jpx_pompompurin_plushie'] = {
		label = 'Pompompurin Plushie',
		weight = 500,
		stack = true,
		close = true,
		description = 'Pompompurin Plushie'
	},
	['jpx_cinnamoroll_slippers'] = {
		label = 'Cinnamoroll Slippers',
		weight = 500,
		stack = true,
		close = true,
		description = 'Cinnamoroll Slippers'
	},
	['jpx_cinnamoroll_slippers2'] = {
		label = 'Cinnamoroll Slippers 2',
		weight = 500,
		stack = true,
		close = true,
		description = 'Cinnamoroll Slippers 2'
	},
	['jpx_bad_badtz_maru_standing'] = {
		label = 'Badtz-Maru Standing',
		weight = 500,
		stack = true,
		close = true,
		description = 'Badtz-Maru Standing'
	},
	['jpx_cinnamoroll_standing'] = {
		label = 'Cinnamoroll Standing',
		weight = 500,
		stack = true,
		close = true,
		description = 'Cinnamoroll Standing'
	},
	['jpx_kitty_standing'] = {
		label = 'Kitty Standing',
		weight = 500,
		stack = true,
		close = true,
		description = 'Kitty Standing'
	},
	['jpx_pompompurin_standing'] = {
		label = 'Pompompurin Standing',
		weight = 500,
		stack = true,
		close = true,
		description = 'Pompompurin Standing'
	},
	['jpx_little_doll_magic_circle'] = {
		label = 'Little Doll Magic Circle',
		weight = 500,
		stack = true,
		close = true,
		description = 'Little Doll Magic Circle'
	},

	--British Shorthair Fashion--
	['jpx_british_shorthair_shoulder'] = {
		label = 'British Shorthair (Shoulder)',
		weight = 500,
		stack = true,
		close = true,
		description = 'A cute British Shorthair cat that sits on your shoulder'
	},

	['jpx_british_shorthair_mouth'] = {
		label = 'British Shorthair (Mouth)',
		weight = 500,
		stack = true,
		close = true,
		description = 'A cute British Shorthair cat held in mouth'
	},

	['jpx_british_shorthair_stand'] = {
		label = 'British Shorthair (Standing)',
		weight = 500,
		stack = true,
		close = true,
		description = 'A cute British Shorthair cat in standing pose'
	},

	['jpx_british_shorthair_stand_two'] = {
		label = 'British Shorthair (Standing Alt)',
		weight = 500,
		stack = true,
		close = true,
		description = 'A cute British Shorthair cat in alternative standing pose'
	},

	['jpx_british_shorthair_walk'] = {
		label = 'British Shorthair (Walking)',
		weight = 500,
		stack = true,
		close = true,
		description = 'A cute British Shorthair cat in walking pose'
	},

	['jpx_british_shorthair_round'] = {
		label = 'British Shorthair (Round)',
		weight = 500,
		stack = true,
		close = true,
		description = 'A cute British Shorthair cat curled up in a round shape'
	},

	['jpx_british_shorthair_walk_round'] = {
		label = 'British Shorthair (Walking Round)',
		weight = 500,
		stack = true,
		close = true,
		description = 'A cute British Shorthair cat walking in round form'
	},

	['jpx_british_shorthair_shoulder2'] = {
		label = 'British Shorthair (Shoulder V2)',
		weight = 500,
		stack = true,
		close = true,
		description = 'A cute British Shorthair cat that sits on your shoulder - variant 2'
	},

	['jpx_british_shorthair_mouth2'] = {
		label = 'British Shorthair (Mouth V2)',
		weight = 500,
		stack = true,
		close = true,
		description = 'A cute British Shorthair cat held in mouth - variant 2'
	},

	['jpx_british_shorthair_stand2'] = {
		label = 'British Shorthair (Standing V2)',
		weight = 500,
		stack = true,
		close = true,
		description = 'A cute British Shorthair cat in standing pose - variant 2'
	},

	['jpx_british_shorthair_stand_two2'] = {
		label = 'British Shorthair (Standing Alt V2)',
		weight = 500,
		stack = true,
		close = true,
		description = 'A cute British Shorthair cat in alternative standing pose - variant 2'
	},

	['jpx_british_shorthair_walk2'] = {
		label = 'British Shorthair (Walking V2)',
		weight = 500,
		stack = true,
		close = true,
		description = 'A cute British Shorthair cat in walking pose - variant 2'
	},

	['jpx_british_shorthair_round2'] = {
		label = 'British Shorthair (Round V2)',
		weight = 500,
		stack = true,
		close = true,
		description = 'A cute British Shorthair cat curled up in a round shape - variant 2'
	},

	['jpx_british_shorthair_walk_round2'] = {
		label = 'British Shorthair (Walking Round V2)',
		weight = 500,
		stack = true,
		close = true,
		description = 'A cute British Shorthair cat walking in round form - variant 2'
	},

	-- Music Collection
	['jpx_acoustic_guitar'] = {
		label = 'â€¢Acoustic Guitar',
		weight = 300,
		stack = true,
		close = true,
		description = 'A beautiful acoustic guitar'
	},
	['jpx_acoustic_guitar_hand'] = {
		label = 'â€¢Acoustic Guitar 2',
		weight = 300,
		stack = true,
		close = true,
		description = 'Another style acoustic guitar'
	},
	['jpx_blackc_guitar'] = {
		label = 'Black Guitar',
		weight = 300,
		stack = true,
		close = true,
		description = 'A sleek black guitar'
	},
	['jpx_blackc_guitar_hand'] = {
		label = 'Black Guitar 2',
		weight = 300,
		stack = true,
		close = true,
		description = 'Another black guitar style'
	},
	['jpx_dj_headears'] = {
		label = 'â€¢DJ Headears',
		weight = 100,
		stack = true,
		close = true,
		description = 'DJ-style head ears'
	},
	['jpx_dj_puppy'] = {
		label = 'â€¢DJ Puppy',
		weight = 150,
		stack = true,
		close = true,
		description = 'A cute DJ puppy'
	},
	['jpx_dj_tarantella'] = {
		label = 'â€¢DJ Tarantella',
		weight = 200,
		stack = true,
		close = true,
		description = 'DJ Tarantella music equipment'
	},
	['jpx_dj_tarantella_back'] = {
		label = 'â€¢DJ Tarantella 2',
		weight = 200,
		stack = true,
		close = true,
		description = 'Back view DJ Tarantella'
	},
	['jpx_dj_tarantella2'] = {
		label = 'â€¢Summer DJ Tarantella',
		weight = 200,
		stack = true,
		close = true,
		description = 'Summer themed DJ Tarantella'
	},
	['jpx_dj_tarantella2_back'] = {
		label = 'â€¢Summer DJ Tarantella 2',
		weight = 200,
		stack = true,
		close = true,
		description = 'Back view summer DJ Tarantella'
	},
	['jpx_electric_guitar'] = {
		label = 'â€¢Electric Guitar',
		weight = 350,
		stack = true,
		close = true,
		description = 'A powerful electric guitar'
	},
	['jpx_electric_guitar_hand'] = {
		label = 'â€¢Electric Guitar 2',
		weight = 350,
		stack = true,
		close = true,
		description = 'Another electric guitar style'
	},
	['jpx_funky_staff'] = {
		label = 'â€¢Funky Staff',
		weight = 200,
		stack = true,
		close = true,
		description = 'A funky musical staff'
	},
	['jpx_gamer_doll'] = {
		label = 'â€¢Gamer Doll',
		weight = 150,
		stack = true,
		close = true,
		description = 'A gaming-themed doll'
	},
	['jpx_guitar_bag'] = {
		label = 'â€¢Guitar Bag',
		weight = 200,
		stack = true,
		close = true,
		description = 'A bag for carrying guitars'
	},
	['jpx_guitar_bag_hand'] = {
		label = 'â€¢Guitar Bag 2',
		weight = 200,
		stack = true,
		close = true,
		description = 'Another guitar bag style'
	},
	['jpx_magical_rings'] = {
		label = 'â€¢Magical Rings',
		weight = 100,
		stack = true,
		close = true,
		description = 'Rings with magical musical powers'
	},
	['jpx_magical_voice'] = {
		label = 'â€¢Magical Voice',
		weight = 50,
		stack = true,
		close = true,
		description = 'A magical voice enhancer'
	},
	['jpx_marshmello_mask'] = {
		label = 'â€¢Marshmello Mask',
		weight = 100,
		stack = true,
		close = true,
		description = 'A Marshmello DJ mask'
	},
	['jpx_megaphone'] = {
		label = 'â€¢Megaphone',
		weight = 150,
		stack = true,
		close = true,
		description = 'A loud megaphone'
	},
	['jpx_melody_ears'] = {
		label = 'â€¢Melody Ears',
		weight = 75,
		stack = true,
		close = true,
		description = 'Musical melody ears'
	},
	['jpx_melody_magic_circle'] = {
		label = 'â€¢Melody Magic Circle',
		weight = 250,
		stack = true,
		close = true,
		description = 'A magical circle for melodies'
	},
	['jpx_melody_moon'] = {
		label = 'â€¢Melody Moon',
		weight = 150,
		stack = true,
		close = true,
		description = 'A moon that plays melodies'
	},
	['jpx_melody_neko'] = {
		label = 'â€¢Melody Neko',
		weight = 100,
		stack = true,
		close = true,
		description = 'A musical cat'
	},
	['jpx_melody_rings'] = {
		label = 'â€¢Melody Rings',
		weight = 75,
		stack = true,
		close = true,
		description = 'Rings that create melodies'
	},
	['jpx_melody_wings'] = {
		label = 'â€¢Melody Wings',
		weight = 100,
		stack = true,
		close = true,
		description = 'Wings that sing melodies'
	},
	['jpx_micstand'] = {
		label = 'â€¢Pinky Micstand',
		weight = 250,
		stack = true,
		close = true,
		description = 'A pink microphone stand'
	},
	['jpx_micstand2'] = {
		label = 'â€¢Yellow Micstand',
		weight = 250,
		stack = true,
		close = true,
		description = 'A yellow microphone stand'
	},
	['jpx_micstand3'] = {
		label = 'â€¢Blue Micstand',
		weight = 250,
		stack = true,
		close = true,
		description = 'A blue microphone stand'
	},
	['jpx_music_book'] = {
		label = 'â€¢Musical Book',
		weight = 150,
		stack = true,
		close = true,
		description = 'A book of musical notes'
	},
	['jpx_notesong'] = {
		label = 'â€¢Notesong',
		weight = 50,
		stack = true,
		close = true,
		description = 'Musical notes that sing'
	},
	['jpx_notesong_star'] = {
		label = 'â€¢Notesong Star',
		weight = 75,
		stack = true,
		close = true,
		description = 'A star-shaped musical note'
	},
	['jpx_piano_bag'] = {
		label = 'â€¢Piano Bag',
		weight = 300,
		stack = true,
		close = true,
		description = 'A bag shaped like a piano'
	},
	['jpx_pinky_guitar'] = {
		label = 'â€¢Pinky Guitar',
		weight = 300,
		stack = true,
		close = true,
		description = 'A pink guitar'
	},
	['jpx_pinky_guitar_hand'] = {
		label = 'â€¢Pinky Guitar 2',
		weight = 300,
		stack = true,
		close = true,
		description = 'Another pink guitar style'
	},
	['jpx_popstar_bird'] = {
		label = 'â€¢Popstar Bird',
		weight = 100,
		stack = true,
		close = true,
		description = 'A singing popstar bird'
	},
	['jpx_popstar_bird2'] = {
		label = 'â€¢Popstar Bird 2',
		weight = 100,
		stack = true,
		close = true,
		description = 'Another popstar bird'
	},
	['jpx_popstar_melody_doll'] = {
		label = 'â€¢Popstar Melody Doll',
		weight = 150,
		stack = true,
		close = true,
		description = 'A popstar melody doll'
	},
	['jpx_popstar_melody_wings'] = {
		label = 'â€¢Popstar Melody Wings',
		weight = 100,
		stack = true,
		close = true,
		description = 'Popstar melody wings'
	},
	['jpx_popstar_tails'] = {
		label = 'â€¢Popstar Tails',
		weight = 75,
		stack = true,
		close = true,
		description = 'Popstar-style tails'
	},
	['jpx_popstar_tails2'] = {
		label = 'â€¢Popstar Tails 2',
		weight = 75,
		stack = true,
		close = true,
		description = 'Another popstar tail style'
	},
	['jpx_popstar_tails3'] = {
		label = 'â€¢Popstar Tails 3',
		weight = 75,
		stack = true,
		close = true,
		description = 'Third popstar tail style'
	},
	['jpx_rapper_doll'] = {
		label = 'â€¢Rapper Doll',
		weight = 150,
		stack = true,
		close = true,
		description = 'A rapper-themed doll'
	},
	['jpx_rockstar_wings'] = {
		label = 'â€¢Rockstar Wings',
		weight = 150,
		stack = true,
		close = true,
		description = 'Wings fit for a rockstar'
	},
	['jpx_vivo_doll'] = {
		label = 'â€¢Vivo Doll',
		weight = 150,
		stack = true,
		close = true,
		description = 'A Vivo character doll'
	},
	['jpx_voice_doll'] = {
		label = 'â€¢Voice Doll',
		weight = 100,
		stack = true,
		close = true,
		description = 'A doll with a beautiful voice'
	},
	['jpx_white_guitar'] = {
		label = 'â€¢White Guitar',
		weight = 300,
		stack = true,
		close = true,
		description = 'A pristine white guitar'
	},
	['jpx_white_guitar_hand'] = {
		label = 'â€¢White Guitar 2',
		weight = 300,
		stack = true,
		close = true,
		description = 'Another white guitar style'
	},
	['jpx_wolf_guitar'] = {
		label = 'â€¢Wolf Guitar',
		weight = 300,
		stack = true,
		close = true,
		description = 'A guitar with wolf design'
	},
	['jpx_wolf_guitar_hand'] = {
		label = 'â€¢Wolf Guitar 2',
		weight = 300,
		stack = true,
		close = true,
		description = 'Another wolf guitar style'
	},
	['jpx_wood_ukulele'] = {
		label = 'â€¢Wood Ukulele',
		weight = 200,
		stack = true,
		close = true,
		description = 'A wooden ukulele'
	},
	['jpx_wood_ukulele_hand'] = {
		label = 'â€¢Wood Ukulele 2',
		weight = 200,
		stack = true,
		close = true,
		description = 'Another wooden ukulele style'
	},
	-- Chinese/Asian Collection
	['jpx_ancient_fur'] = {
		label = 'â€¢Ancient White Fur',
		weight = 50,
		stack = true,
		close = true,
		description = 'Mystical white fur from ancient creatures'
	},
	['jpx_ancient_fur2'] = {
		label = 'â€¢Ancient Black Fur',
		weight = 50,
		stack = true,
		close = true,
		description = 'Mystical black fur from ancient creatures'
	},
	['jpx_bambino_doll'] = {
		label = 'â€¢Bambino Doll',
		weight = 100,
		stack = true,
		close = true,
		description = 'A traditional bambino doll'
	},
	['jpx_blue_handfan'] = {
		label = 'â€¢Blue Handfan',
		weight = 75,
		stack = true,
		close = true,
		description = 'An elegant blue handfan'
	},
	['jpx_blue_handfan2'] = {
		label = 'â€¢Blue Handfan 2',
		weight = 75,
		stack = true,
		close = true,
		description = 'Another style of blue handfan'
	},
	['jpx_chinese_handfan'] = {
		label = 'â€¢Chinese Handfan',
		weight = 75,
		stack = true,
		close = true,
		description = 'A traditional Chinese handfan'
	},
	['jpx_chinese_hat'] = {
		label = 'â€¢Chinese Hat',
		weight = 100,
		stack = true,
		close = true,
		description = 'A traditional Chinese hat'
	},
	['jpx_chinese_hat2'] = {
		label = 'â€¢Chinese Hat 2',
		weight = 100,
		stack = true,
		close = true,
		description = 'Another style of Chinese hat'
	},
	['jpx_chinese_hat3'] = {
		label = 'â€¢Chinese Hat 3',
		weight = 100,
		stack = true,
		close = true,
		description = 'A third style of Chinese hat'
	},
	['jpx_chinese_staff'] = {
		label = 'â€¢Chinese Staff',
		weight = 200,
		stack = true,
		close = true,
		description = 'A traditional Chinese staff'
	},
	['jpx_chinese_umbrella'] = {
		label = 'â€¢Chinese Umbrella',
		weight = 150,
		stack = true,
		close = true,
		description = 'A traditional Chinese umbrella'
	},
	['jpx_chinese_witch_hat'] = {
		label = 'â€¢Chinese Witch Hat',
		weight = 100,
		stack = true,
		close = true,
		description = 'A mystical Chinese witch hat'
	},
	['jpx_dragon'] = {
		label = 'â€¢Dragon',
		weight = 300,
		stack = true,
		close = true,
		description = 'A majestic dragon figurine'
	},
	['jpx_dragon2'] = {
		label = 'â€¢Dragon 2',
		weight = 300,
		stack = true,
		close = true,
		description = 'Another dragon figurine'
	},
	['jpx_dragon3'] = {
		label = 'â€¢Dragon 3',
		weight = 300,
		stack = true,
		close = true,
		description = 'A third dragon figurine'
	},
	['jpx_dragon4'] = {
		label = 'â€¢Dragon 4',
		weight = 300,
		stack = true,
		close = true,
		description = 'A fourth dragon figurine'
	},
	['jpx_dragon5'] = {
		label = 'â€¢Dragon 5',
		weight = 300,
		stack = true,
		close = true,
		description = 'A fifth dragon figurine'
	},
	['jpx_evildragon_hat'] = {
		label = 'â€¢Evildragon Hat',
		weight = 100,
		stack = true,
		close = true,
		description = 'A hat shaped like an evil dragon'
	},
	['jpx_firecracker'] = {
		label = 'â€¢Firecracker',
		weight = 50,
		stack = true,
		close = true,
		description = 'Traditional Chinese firecracker'
	},
	['jpx_firecracker_dragon'] = {
		label = 'â€¢Firecracker Dragon',
		weight = 200,
		stack = true,
		close = true,
		description = 'Dragon-themed firecracker'
	},
	['jpx_firecracker_fur'] = {
		label = 'â€¢Firecracker Fur',
		weight = 75,
		stack = true,
		close = true,
		description = 'Fur with firecracker patterns'
	},
	['jpx_firecracker_liondance'] = {
		label = 'â€¢Firecracker Liondance',
		weight = 250,
		stack = true,
		close = true,
		description = 'Lion dance with firecracker theme'
	},
	['jpx_firecracker_pic'] = {
		label = 'â€¢Firecracker Pic',
		weight = 25,
		stack = true,
		close = true,
		description = 'A picture of firecrackers'
	},
	['jpx_firecracker_pole'] = {
		label = 'â€¢Firecracker Pole',
		weight = 150,
		stack = true,
		close = true,
		description = 'A pole with firecrackers attached'
	},
	['jpx_fortune_bag'] = {
		label = 'â€¢Foretune Bag',
		weight = 100,
		stack = true,
		close = true,
		description = 'A bag that brings good fortune'
	},
	['jpx_fortune_bunny'] = {
		label = 'â€¢Foretune Bunny',
		weight = 100,
		stack = true,
		close = true,
		description = 'A lucky bunny figurine'
	},
	['jpx_fortune_cat'] = {
		label = 'â€¢Foretune Cat',
		weight = 100,
		stack = true,
		close = true,
		description = 'A lucky cat figurine'
	},
	['jpx_fortune_lamp'] = {
		label = 'â€¢Foretune Lamp',
		weight = 150,
		stack = true,
		close = true,
		description = 'A lamp that brings good fortune'
	},
	['jpx_fortune_magic_circle'] = {
		label = 'â€¢Foretune Magic Circle',
		weight = 200,
		stack = true,
		close = true,
		description = 'A magical circle for fortune'
	},
	['jpx_fortune_money'] = {
		label = 'â€¢Foretune Money',
		weight = 50,
		stack = true,
		close = true,
		description = 'Lucky money for fortune'
	},
	['jpx_fortune_wings'] = {
		label = 'â€¢Foretune Wings',
		weight = 100,
		stack = true,
		close = true,
		description = 'Wings that bring good fortune'
	},
	['jpx_fortune_wings2'] = {
		label = 'â€¢Foretune Wings 2',
		weight = 100,
		stack = true,
		close = true,
		description = 'Another style of fortune wings'
	},
	['jpx_gekko_mirrors'] = {
		label = 'â€¢Gekko Mirrors',
		weight = 100,
		stack = true,
		close = true,
		description = 'Mystical gekko mirrors'
	},
	['jpx_gekko_puppet'] = {
		label = 'â€¢Gekko Puppet',
		weight = 150,
		stack = true,
		close = true,
		description = 'A traditional gekko puppet'
	},
	['jpx_kungfu_master_doll'] = {
		label = 'â€¢Kungfu Master Doll',
		weight = 150,
		stack = true,
		close = true,
		description = 'A doll of a kungfu master'
	},
	['jpx_kungfu_master_doll2'] = {
		label = 'â€¢Kungfu Master Doll 2',
		weight = 150,
		stack = true,
		close = true,
		description = 'Another kungfu master doll'
	},
	['jpx_kungfu_master_doll3'] = {
		label = 'â€¢Kungfu Master Doll 3',
		weight = 150,
		stack = true,
		close = true,
		description = 'A third kungfu master doll'
	},
	['jpx_lunar_fest'] = {
		label = 'â€¢Lunar Fest',
		weight = 200,
		stack = true,
		close = true,
		description = 'Lunar festival decoration'
	},
	['jpx_lunar_fest_moon'] = {
		label = 'â€¢Lunar Fest Moon',
		weight = 150,
		stack = true,
		close = true,
		description = 'Moon decoration for lunar festival'
	},
	['jpx_milumu_staff'] = {
		label = 'â€¢Milumu Staff',
		weight = 200,
		stack = true,
		close = true,
		description = 'A mystical milumu staff'
	},
	['jpx_moon_cake'] = {
		label = 'â€¢Moon Cake',
		weight = 100,
		stack = true,
		close = true,
		description = 'Traditional moon cake'
	},
	['jpx_moonstuck'] = {
		label = 'â€¢Moonstuck',
		weight = 100,
		stack = true,
		close = true,
		description = 'A moonstruck item'
	},
	['jpx_paopao'] = {
		label = 'â€¢White Paopao',
		weight = 100,
		stack = true,
		close = true,
		description = 'White paopao traditional item'
	},
	['jpx_paopao2'] = {
		label = 'â€¢Black Paopao',
		weight = 100,
		stack = true,
		close = true,
		description = 'Black paopao traditional item'
	},
	['jpx_phoenix'] = {
		label = 'â€¢Phoenix',
		weight = 300,
		stack = true,
		close = true,
		description = 'A majestic phoenix figurine'
	},
	['jpx_shanghai_handfan'] = {
		label = 'â€¢Shanghai Handfan',
		weight = 75,
		stack = true,
		close = true,
		description = 'A Shanghai style handfan'
	},
	['jpx_soryu_umbrella'] = {
		label = 'â€¢Soryu Umbrella',
		weight = 150,
		stack = true,
		close = true,
		description = 'A soryu style umbrella'
	},
	['jpx_white_tiger_hat'] = {
		label = 'â€¢White Tiger Hat',
		weight = 100,
		stack = true,
		close = true,
		description = 'A hat with white tiger design'
	},
	['jpx_xiaoqing_handfan'] = {
		label = 'â€¢Xiaoqing Handfan',
		weight = 75,
		stack = true,
		close = true,
		description = 'A xiaoqing style handfan'
	},
	['jpx_xiaoqing_handfan2'] = {
		label = 'â€¢Xiaoqing Handfan 2',
		weight = 75,
		stack = true,
		close = true,
		description = 'Another xiaoqing handfan'
	},
	['jpx_yaksha_mask'] = {
		label = 'â€¢Yaksha Mask',
		weight = 100,
		stack = true,
		close = true,
		description = 'A traditional yaksha mask'
	},
	['jpx_zhuge_liang_fantasy'] = {
		label = 'â€¢Zhuge Liang Fantasy',
		weight = 200,
		stack = true,
		close = true,
		description = 'Fantasy item of Zhuge Liang'
	},
	['jpx_zoe_ears'] = {
		label = 'â€¢Zoe Ears',
		weight = 50,
		stack = true,
		close = true,
		description = 'Cute zoe-style ears'
	},
	['jpx_zoe_yoyo'] = {
		label = 'â€¢Zoe Yoyo',
		weight = 75,
		stack = true,
		close = true,
		description = 'A zoe-themed yoyo'
	},
	-- Digimon Collection
	['jpx_agumon'] = {
		label = 'â€¢Agumon',
		weight = 100,
		stack = true,
		close = true,
		description = 'A brave orange dinosaur Digimon'
	},
	['jpx_biyomon'] = {
		label = 'â€¢Biyomon',
		weight = 100,
		stack = true,
		close = true,
		description = 'A pink bird Digimon with colorful feathers'
	},
	['jpx_gabumon'] = {
		label = 'â€¢Gabumon',
		weight = 100,
		stack = true,
		close = true,
		description = 'A friendly reptile Digimon with blue fur'
	},
	['jpx_gatomon'] = {
		label = 'â€¢Gatomon',
		weight = 100,
		stack = true,
		close = true,
		description = 'A white cat Digimon with holy powers'
	},
	['jpx_gomamon'] = {
		label = 'â€¢Gomamon',
		weight = 100,
		stack = true,
		close = true,
		description = 'A white seal Digimon from the ocean'
	},
	['jpx_palmon'] = {
		label = 'â€¢Palmon',
		weight = 100,
		stack = true,
		close = true,
		description = 'A plant-type Digimon with pink flowers'
	},
	['jpx_patamon'] = {
		label = 'â€¢Patamon',
		weight = 100,
		stack = true,
		close = true,
		description = 'A small flying mammal Digimon'
	},
	['jpx_tentomon'] = {
		label = 'â€¢Tentomon',
		weight = 100,
		stack = true,
		close = true,
		description = 'An insect-type Digimon with electrical powers'
	},

	-- Ninja Fashion Items - Back Attachments
	['jpx_shukaku_one_tails'] = {
		label = 'â€¢Shukaku One Tails',
		weight = 500,
		stack = false,
		close = true,
		description = 'One-tailed beast back attachment with yellow flash effects'
	},

	['jpx_matatabi_two_tails'] = {
		label = 'â€¢Matatabi Two Tails',
		weight = 500,
		stack = false,
		close = true,
		description = 'Two-tailed beast back attachment with blue flash effects'
	},

	['jpx_isobu_three_tails'] = {
		label = 'â€¢Isobu Three Tails',
		weight = 500,
		stack = false,
		close = true,
		description = 'Three-tailed beast back attachment with white and purple effects'
	},

	['jpx_songoku_four_tails'] = {
		label = 'â€¢Son Goku Four Tails',
		weight = 500,
		stack = false,
		close = true,
		description = 'Four-tailed beast back attachment with red flash effects'
	},

	['jpx_kokuo_five_tails'] = {
		label = 'â€¢Kokuo Five Tails',
		weight = 500,
		stack = false,
		close = true,
		description = 'Five-tailed beast back attachment with white and yellow effects'
	},

	['jpx_saiken_six_tails'] = {
		label = 'â€¢Saiken Six Tails',
		weight = 500,
		stack = false,
		close = true,
		description = 'Six-tailed beast back attachment with white flash effects'
	},

	['jpx_choumei_seven_tails'] = {
		label = 'â€¢Choumei Seven Tails',
		weight = 500,
		stack = false,
		close = true,
		description = 'Seven-tailed beast back attachment with green and orange effects'
	},

	['jpx_gyuki_eight_tails'] = {
		label = 'â€¢Gyuki Eight Tails',
		weight = 500,
		stack = false,
		close = true,
		description = 'Eight-tailed beast back attachment with purple flash effects'
	},

	['jpx_kurama_nine_tails'] = {
		label = 'â€¢Kurama Nine Tails',
		weight = 500,
		stack = false,
		close = true,
		description = 'Nine-tailed beast back attachment with orange flash effects'
	},

	-- Weapons & Tools
	['jpx_choji_wings'] = {
		label = 'â€¢Choji Wings',
		weight = 300,
		stack = false,
		close = true,
		description = 'Butterfly wings back attachment'
	},

	['jpx_divine_feathers'] = {
		label = 'â€¢Divine Feathers',
		weight = 200,
		stack = false,
		close = true,
		description = 'Divine feather back attachment'
	},

	['jpx_enra'] = {
		label = 'â€¢Enra',
		weight = 400,
		stack = false,
		close = true,
		description = 'Enra back attachment'
	},

	['jpx_gaara_gourd'] = {
		label = 'â€¢Gaara Gourd',
		weight = 800,
		stack = false,
		close = true,
		description = 'Sand gourd back attachment'
	},

	['jpx_gunbai'] = {
		label = 'â€¢Gunbai',
		weight = 600,
		stack = false,
		close = true,
		description = 'Madara war fan back attachment'
	},

	['jpx_hidan_scythe'] = {
		label = 'â€¢Hidan Scythe',
		weight = 700,
		stack = false,
		close = true,
		description = 'Triple-bladed scythe back attachment'
	},

	['jpx_hiramekarei'] = {
		label = 'â€¢Hiramekarei',
		weight = 900,
		stack = false,
		close = true,
		description = 'Twin sword back attachment'
	},

	['jpx_jiraiya_sage_mode'] = {
		label = 'â€¢Jiraiya Sage Mode',
		weight = 300,
		stack = false,
		close = true,
		description = 'Sage mode back attachment'
	},

	['jpx_jiraiya_scroll'] = {
		label = 'â€¢Jiraiya Scroll',
		weight = 400,
		stack = false,
		close = true,
		description = 'Large scroll back attachment'
	},

	['jpx_jump_force'] = {
		label = 'â€¢Jump Force',
		weight = 500,
		stack = false,
		close = true,
		description = 'Jump Force back attachment'
	},

	['jpx_kabuto_sage_mode'] = {
		label = 'â€¢Kabuto Sage Mode',
		weight = 300,
		stack = false,
		close = true,
		description = 'Kabuto sage mode back attachment'
	},

	['jpx_kamatari'] = {
		label = 'â€¢Kamatari',
		weight = 600,
		stack = false,
		close = true,
		description = 'Giant fan back attachment'
	},

	['jpx_killer_b_weapon'] = {
		label = 'â€¢Killer B Weapon',
		weight = 800,
		stack = false,
		close = true,
		description = 'Multiple swords back attachment'
	},

	['jpx_konan_wings'] = {
		label = 'â€¢Konan Wings',
		weight = 250,
		stack = false,
		close = true,
		description = 'Paper wings back attachment'
	},

	['jpx_kubikiribocho'] = {
		label = 'â€¢Kubikiribocho',
		weight = 1000,
		stack = false,
		close = true,
		description = 'Executioner blade back attachment'
	},

	['jpx_kurama_chibi'] = {
		label = 'â€¢Kurama Chibi',
		weight = 200,
		stack = false,
		close = true,
		description = 'Cute Kurama back attachment'
	},

	['jpx_samehada'] = {
		label = 'â€¢Samehada',
		weight = 950,
		stack = false,
		close = true,
		description = 'Shark skin sword back attachment'
	},

	['jpx_shuriken'] = {
		label = 'â€¢Giant Shuriken',
		weight = 400,
		stack = false,
		close = true,
		description = 'Giant shuriken back attachment'
	},

	['jpx_temari_fan'] = {
		label = 'â€¢Temari Fan',
		weight = 550,
		stack = false,
		close = true,
		description = 'Giant battle fan back attachment'
	},

	['jpx_tenten_scroll'] = {
		label = 'â€¢Tenten Scroll',
		weight = 350,
		stack = false,
		close = true,
		description = 'Weapon scroll back attachment'
	},

	['jpx_tonton'] = {
		label = 'â€¢Tonton',
		weight = 150,
		stack = false,
		close = true,
		description = 'Pet pig back attachment'
	},

	['jpx_yagura_staff'] = {
		label = 'â€¢Yagura Staff',
		weight = 500,
		stack = false,
		close = true,
		description = 'Mizukage staff back attachment'
	},

	-- Books
	['jpx_makeout_mischief'] = {
		label = 'â€¢Make-Out Mischief',
		weight = 150,
		stack = true,
		close = true,
		description = 'Make-Out series book'
	},

	['jpx_makeout_paradise'] = {
		label = 'â€¢Make-Out Paradise',
		weight = 150,
		stack = true,
		close = true,
		description = 'Make-Out Paradise book'
	},

	['jpx_makeout_tactics'] = {
		label = 'â€¢Make-Out Tactics',
		weight = 150,
		stack = true,
		close = true,
		description = 'Make-Out Tactics book'
	},

	-- Pets
	['jpx_akamaru'] = {
		label = 'â€¢Akamaru',
		weight = 200,
		stack = false,
		close = true,
		description = 'Ninja dog back attachment'
	},

	-- Head Accessories - Hats
	['jpx_akatsuki_hat'] = {
		label = 'â€¢Akatsuki Hat',
		weight = 100,
		stack = false,
		close = true,
		description = 'Akatsuki organization straw hat'
	},

	['jpx_hokage_hat'] = {
		label = 'â€¢Hokage Hat',
		weight = 150,
		stack = false,
		close = true,
		description = 'Hokage ceremonial hat'
	},

	['jpx_kazekage_hat'] = {
		label = 'â€¢Kazekage Hat',
		weight = 150,
		stack = false,
		close = true,
		description = 'Kazekage ceremonial hat'
	},

	['jpx_mizukage_hat'] = {
		label = 'â€¢Mizukage Hat',
		weight = 150,
		stack = false,
		close = true,
		description = 'Mizukage ceremonial hat'
	},

	['jpx_raikage_hat'] = {
		label = 'â€¢Raikage Hat',
		weight = 150,
		stack = false,
		close = true,
		description = 'Raikage ceremonial hat'
	},

	['jpx_tsuchikage_hat'] = {
		label = 'â€¢Tsuchikage Hat',
		weight = 150,
		stack = false,
		close = true,
		description = 'Tsuchikage ceremonial hat'
	},

	['jpx_naruto_nightcap'] = {
		label = 'â€¢Naruto Nightcap',
		weight = 50,
		stack = false,
		close = true,
		description = 'Naruto sleeping cap'
	},

	-- Masks
	['jpx_anbu_bird_mask'] = {
		label = 'â€¢ANBU Bird Mask',
		weight = 100,
		stack = false,
		close = true,
		description = 'ANBU bird-style mask'
	},

	['jpx_anbu_cat_mask'] = {
		label = 'â€¢ANBU Cat Mask',
		weight = 100,
		stack = false,
		close = true,
		description = 'ANBU cat-style mask'
	},

	['jpx_anbu_fox_mask'] = {
		label = 'â€¢ANBU Fox Mask',
		weight = 100,
		stack = false,
		close = true,
		description = 'ANBU fox-style mask'
	},

	['jpx_anbu_kappa_mask'] = {
		label = 'â€¢ANBU Kappa Mask',
		weight = 100,
		stack = false,
		close = true,
		description = 'ANBU kappa-style mask'
	},

	['jpx_anbu_monkey_mask'] = {
		label = 'â€¢ANBU Monkey Mask',
		weight = 100,
		stack = false,
		close = true,
		description = 'ANBU monkey-style mask'
	},

	['jpx_anbu_owl_mask'] = {
		label = 'â€¢ANBU Owl Mask',
		weight = 100,
		stack = false,
		close = true,
		description = 'ANBU owl-style mask'
	},

	['jpx_anbu_ox_mask'] = {
		label = 'â€¢ANBU Ox Mask',
		weight = 100,
		stack = false,
		close = true,
		description = 'ANBU ox-style mask'
	},

	['jpx_anbu_itachi_mask'] = {
		label = 'â€¢ANBU Itachi Mask',
		weight = 100,
		stack = false,
		close = true,
		description = 'Itachi ANBU mask'
	},

	['jpx_anbu_kakashi_mask'] = {
		label = 'â€¢ANBU Kakashi Mask',
		weight = 100,
		stack = false,
		close = true,
		description = 'Kakashi ANBU mask'
	},

	['jpx_naruto_mask'] = {
		label = 'â€¢Naruto Mask',
		weight = 80,
		stack = false,
		close = true,
		description = 'Naruto character mask'
	},

	['jpx_sasuke_mask'] = {
		label = 'â€¢Sasuke Mask',
		weight = 80,
		stack = false,
		close = true,
		description = 'Sasuke character mask'
	},

	['jpx_madara_mask'] = {
		label = 'â€¢Madara Mask',
		weight = 100,
		stack = false,
		close = true,
		description = 'Madara Uchiha mask'
	},

	['jpx_tobi_mask'] = {
		label = 'â€¢Tobi Mask',
		weight = 100,
		stack = false,
		close = true,
		description = 'Tobi spiral mask'
	},

	['jpx_han_mask'] = {
		label = 'â€¢Han Mask',
		weight = 120,
		stack = false,
		close = true,
		description = 'Han respirator mask'
	},

	['jpx_hanzou_mask'] = {
		label = 'â€¢Hanzou Mask',
		weight = 120,
		stack = false,
		close = true,
		description = 'Hanzou respirator mask'
	},

	['jpx_death_god_mask'] = {
		label = 'â€¢Death God Mask',
		weight = 150,
		stack = false,
		close = true,
		description = 'Shinigami mask'
	},

	['jpx_reaper_mask'] = {
		label = 'â€¢Reaper Mask',
		weight = 120,
		stack = false,
		close = true,
		description = 'Reaper style mask'
	},

	-- Goggles
	['jpx_chojuro_goggles'] = {
		label = 'â€¢Chojuro Goggles',
		weight = 80,
		stack = false,
		close = true,
		description = 'Chojuro eye protection'
	},

	['jpx_naruto_goggles'] = {
		label = 'â€¢Naruto Goggles',
		weight = 80,
		stack = false,
		close = true,
		description = 'Naruto headband goggles'
	},

	['jpx_obito_goggles'] = {
		label = 'â€¢Obito Goggles',
		weight = 80,
		stack = false,
		close = true,
		description = 'Obito protective goggles'
	},

	['jpx_shino_goggles'] = {
		label = 'â€¢Shino Goggles',
		weight = 80,
		stack = false,
		close = true,
		description = 'Shino bug goggles'
	},

	-- Food Items
	['jpx_anko_dango'] = {
		label = 'â€¢Anko Dango',
		weight = 50,
		stack = true,
		close = true,
		description = 'Sweet red bean dango'
	},

	['jpx_hanami_dango'] = {
		label = 'â€¢Hanami Dango',
		weight = 50,
		stack = true,
		close = true,
		description = 'Three-colored festival dango'
	},

	['jpx_mitarashi_dango'] = {
		label = 'â€¢Mitarashi Dango',
		weight = 50,
		stack = true,
		close = true,
		description = 'Soy sauce glazed dango'
	},

	-- Hand Items
	['jpx_jump_force_knife'] = {
		label = 'â€¢Jump Force Knife',
		weight = 200,
		stack = false,
		close = true,
		description = 'Jump Force kunai knife'
	},

	['jpx_kakashi_book'] = {
		label = 'â€¢Kakashi Book',
		weight = 150,
		stack = false,
		close = true,
		description = 'Kakashi reading book'
	},

	['jpx_windmill_shuriken'] = {
		label = 'â€¢Windmill Shuriken',
		weight = 300,
		stack = false,
		close = true,
		description = 'Large windmill shuriken'
	},

	['jpx_paper_bomb_kunai'] = {
		label = 'â€¢Paper Bomb Kunai',
		weight = 150,
		stack = true,
		close = true,
		description = 'Explosive tag kunai'
	},

	-- Special Effects
	['jpx_ninja_magic_circle'] = {
		label = 'â€¢Ninja Magic Circle',
		weight = 100,
		stack = false,
		close = true,
		description = 'Summoning magic circle with red flash effects'
	},

	['jpx_katsuyu'] = {
		label = 'â€¢Katsuyu',
		weight = 200,
		stack = false,
		close = true,
		description = 'Katsuyu slug summon'
	},
	-- Collections & Special Items
	['jpx_demon_blood_collection'] = {
		label = 'â€¢Blood Collection',
		weight = 100,
		stack = true,
		close = true,
		description = 'A mysterious blood collection from demons'
	},

	['jpx_demon_chachamaru'] = {
		label = 'â€¢Chachamaru',
		weight = 500,
		stack = false,
		close = true,
		description = 'A mechanical crow companion'
	},

	['jpx_demon_rui_spider'] = {
		label = 'â€¢Rui Spider',
		weight = 200,
		stack = true,
		close = true,
		description = 'A spider from the demon Rui'
	},

	-- Katanas
	['jpx_demon_giyu_katana'] = {
		label = 'â€¢Giyu Katana',
		weight = 1200,
		stack = false,
		close = true,
		description = 'Water Breathing katana of Giyu Tomioka'
	},

	['jpx_demon_muichiro_katana'] = {
		label = 'â€¢Muichiro Katana',
		weight = 1200,
		stack = false,
		close = true,
		description = 'Mist Breathing katana of Muichiro Tokito'
	},

	['jpx_demon_obanai_katana'] = {
		label = 'â€¢Obanai Katana',
		weight = 1200,
		stack = false,
		close = true,
		description = 'Serpent Breathing katana of Obanai Iguro'
	},

	['jpx_demon_sanemi_katana'] = {
		label = 'â€¢Sanemi Katana',
		weight = 1200,
		stack = false,
		close = true,
		description = 'Wind Breathing katana of Sanemi Shinazugawa'
	},

	['jpx_demon_inosuke_katana'] = {
		label = 'â€¢Inosuke Katana',
		weight = 1200,
		stack = false,
		close = true,
		description = 'Beast Breathing katana of Inosuke Hashibira'
	},

	['jpx_demon_kanao_katana'] = {
		label = 'â€¢Kanao Katana',
		weight = 1200,
		stack = false,
		close = true,
		description = 'Flower Breathing katana of Kanao Tsuyuri'
	},

	['jpx_demon_mitsuri_katana'] = {
		label = 'â€¢Mitsuri Katana',
		weight = 1200,
		stack = false,
		close = true,
		description = 'Love Breathing katana of Mitsuri Kanroji'
	},

	['jpx_demon_rengoku_katana'] = {
		label = 'â€¢Rengoku Katana',
		weight = 1200,
		stack = false,
		close = true,
		description = 'Flame Breathing katana of Kyojuro Rengoku'
	},

	['jpx_demon_shinobu_katana'] = {
		label = 'â€¢Shinobu Katana',
		weight = 1200,
		stack = false,
		close = true,
		description = 'Insect Breathing katana of Shinobu Kocho'
	},

	['jpx_demon_tanjiro_katana'] = {
		label = 'â€¢Tanjiro Katana',
		weight = 1200,
		stack = false,
		close = true,
		description = 'Sun Breathing katana of Tanjiro Kamado'
	},

	['jpx_demon_zenitsu_katana'] = {
		label = 'â€¢Zenitsu Katana',
		weight = 1200,
		stack = false,
		close = true,
		description = 'Thunder Breathing katana of Zenitsu Agatsuma'
	},
	['casino_chips'] = {
		label = 'Casino Chips',
		weight = 0,
		stack = true,
		close = false,
		description = 'Casino Chips',
		client = {
			image = 'casino_chips.png',
		}
	},
	casino_ufc_receipt = {
		label = "Casino UFC Receipt",
		weight = 0,
		stack = false,
		close = false,
		description = "Receipt for UFC bets placed at the casino",
	},
	casino_racing_receipt = {
		label = "Casino Racing Receipt",
		weight = 0,
		stack = false,
		close = false,
		description = "Receipt for racing bets placed at the casino",
		client = {
			image = 'casino_ufc_receipt.png'
		}
	},
	casino_parlay_receipt = {
		label = "Casino Parlay Receipt",
		weight = 0,
		stack = false,
		close = false,
		description = "Receipt for parlay bets placed at the casino",
		client = {
			image = 'casino_ufc_receipt.png'
		}
	},
	['rtxpackingtable'] = {
		label = "Packing Table",
		weight = 2500,
		degrade = 10080,
		stack = false,
		close = true,
	},
	['packingtablelt'] = {
		label = "Packing Table LT",
		weight = 2500,
		degrade = 10080,
		stack = false,
		close = true,
		client = {
			image = 'rtxpackingtable.png'
		}
	},
	['rtxcookingtable'] = {
		label = "Cooking Table",
		weight = 2500,
		degrade = 10080,
		stack = false,
		close = true,
	},
	['rtxmixingtable'] = {
		label = "Mixing Table",
		weight = 1000,
		stack = true,
		close = true,
	},
	['rtxmethchiller'] = {
		label = "Meth Chiller",
		weight = 2500,
		degrade = 10080,
		stack = false,
		close = true,
	},
	['rtxdryingstand'] = {
		label = "Drying Stand",
		weight = 1500,
		degrade = 10080,
		stack = false,
		close = true,
	},
	['rtxcauldron'] = {
		label = "Cauldron",
		weight = 2500,
		degrade = 10080,
		stack = false,
		close = true,
	},
	['rtxpress'] = {
		label = "Drug Press",
		weight = 500,
		stack = true,
		close = true,
	},
	['rtxpot'] = {
		label = "Empty Pot",
		weight = 250,
		degrade = 10080,
		stack = false,
		close = true,
	},
	['rtxlamp1'] = {
		label = "Lamp A",
		weight = 150,
		degrade = 10080,
		stack = false,
		close = true,
	},
	['rtxlamp2'] = {
		label = "GLamp B",
		weight = 150,
		degrade = 10080,
		stack = false,
		close = true,
	},
	['rtxframelamp'] = {
		label = "Framed Lamp",
		weight = 100,
		stack = true,
		close = true,
	},
	['acetone'] = {
		label = "Acetone",
		weight = 100,
		stack = true,
		close = true,
	},
	['cocabag'] = {
		label = "Coca Bag",
		weight = 1,
		stack = true,
		close = true,
	},
	['cocabrick'] = {
		label = "Coca Brick",
		weight = 1,
		stack = true,
		close = true,
	},
	['cocabud'] = {
		label = "Coca Bud",
		weight = 1,
		stack = true,
		close = true,
	},
	['cocaleaves'] = {
		label = "Coca Leaves",
		weight = 1,
		stack = true,
		close = true,
	},
	['cocaseed'] = {
		label = "Coca Seed",
		weight = 5,
		stack = true,
		close = true,
	},
	['emptybag'] = {
		label = "Empty Bag",
		weight = 1,
		stack = true,
		close = true,
	},
	['iodine'] = {
		label = "Iodine",
		weight = 100,
		stack = true,
		close = true,
	},
	['jointpaper'] = {
		label = "Joint Paper",
		weight = 1,
		stack = true,
		close = true,
	},
	['methbag'] = {
		label = "Meth Bag",
		weight = 1,
		stack = true,
		close = true,
	},
	['methbud'] = {
		label = "Meth Bud",
		weight = 1,
		stack = true,
		close = true,
	},
	['methbudlowquality'] = {
		label = "Meth Bud Low",
		weight = 1,
		stack = true,
		close = true,
	},
	['cocabudlowquality'] = {
		label = "Coca Bud Low",
		weight = 1,
		stack = true,
		close = true,
	},
	['weedbuddried'] = {
		label = "Weed Bud Dried",
		weight = 1,
		stack = true,
		close = true,
	},
	['galloon_liquidmeth'] = {
        label = 'Galloon Liquid Meth',
        weight = 200,
		stack = true,
		close = true,
    },
    ['dried_weed'] = {
        label = 'Dried Weed',
        weight = 50,
		stack = true,
		close = true,
    },
    ['raw_cocaine'] = {
        label = 'Raw Cocaine',
        weight = 50,
		stack = true,
		close = true,
    },
    ['crack_meth'] = {
        label = 'Crack Meth',
        weight = 50,
		stack = true,
		close = true,
    },
	['methliquid'] = {
		label = "Meth Liquid",
		weight = 100,
		stack = true,
		close = true,
	},
	['pills'] = {
		label = "Pills",
		weight = 50,
		stack = true,
		close = true,
	},
	['redphosphor'] = {
		label = "Red Phosphor",
		weight = 1,
		stack = true,
		close = true,
	},
	['soilbag'] = {
		label = "Soil Bag",
		weight = 500,
		stack = true,
		close = true,
	},
	['sugar'] = {
		label = "Sugar",
		weight = 1,
		stack = true,
		close = true,
	},
	['wateringcan'] = {
		label = "Watering Can",
		weight = 150,
		degrade = 10080,
		stack = false,
		close = true,
	},
	['weedbag'] = {
		label = "Weed Bag",
		weight = 1,
		stack = true,
		close = true,
	},
	['weedbrick'] = {
		label = "Weed Brick",
		weight = 1,
		stack = true,
		close = true,
	},
	['weedbud'] = {
		label = "Weed Bud",
		weight = 1,
		stack = true,
		close = true,
	},
	['weedjoint'] = {
		label = "Weed Joint",
		weight = 1,
		stack = true,
		close = true,
	},
	['weedseed'] = {
		label = "Weed Seed",
		weight = 5,
		stack = true,
		close = true,
	},
	['hightable_contract'] = {
		label = 'Blood Oath Marker',
		weight = 200,
		stack = true,
		close = true,
		client = { export = 'sm_htcontract.useContract' },
	},
	['signedhightable_contract'] = {
		label = 'Sealed Blood Oath',
		weight = 200,
		stack = false,
		close = true,
		client = { export = 'sm_htcontract.viewSignedContract' },
	},

	['gasmask'] = {
		label = 'Gasmask',
		weight = 500,
		stack = true,
		close = true,
	},

	['ilegal_gasmask'] = {
		label = 'Ilegal Gas Mask',
		weight = 500,
		stack = true,
		close = true,
		description = 'Masker gas sekali pakai. Kebal tear gas & flashbang sampai masker rusak.',
	},

	['gps_jmmr'] = {
		label = 'GPS Jammer',
		weight = 800,
		stack = true,
		close = true,
		description = 'Alat penghancur GPS polisi. Arahkan mata ke polisi untuk memakainya.',
	},

	['motherboard_gps'] = {
		label = 'Motherboard GPS',
		weight = 200,
		stack = true,
		close = true,
		description = 'Komponen elektronik untuk merakit GPS Jammer.',
	},

	['zipline'] = {
		label = 'Zipline',
		weight = 1000,
		stack = true,
	},

	['zipline_ammo'] = {
		label = 'Zipline Ammo',
		weight = 2000,
		stack = true,
	},

	['grapple_gun_ammo'] = {
		label = 'Grapple Gun Ammo',
		weight = 100,
		stack = true,
	},

	['ruby'] = {
		label = 'Ruby',
		weight = 1000,
		stack = true,
		close = true,
		description = 'A precious red gemstone',
	},

	['emerald'] = {
		label = 'Emerald',
		weight = 1000,
		stack = true,
		close = true,
		description = 'A precious green gemstone',
	},

	['blue_sapphire'] = {
		label = 'Blue Sapphire',
		weight = 1000,
		stack = true,
		close = true,
		description = 'A precious blue gemstone',
	},

	['door'] = {
		label = 'Vehicle Door',
		weight = 1000,
		stack = true,
		close = true,
		description = 'Stolen car door',
	},

	['trunk'] = {
		label = 'Vehicle Trunk',
		weight = 1500,
		stack = true,
		close = true,
		description = 'Stolen car trunk',
	},

	['hood'] = {
		label = 'Vehicle Hood',
		weight = 1500,
		stack = true,
		close = true,
		description = 'Stolen car hood',
	},

	['fbumper'] = {
		label = 'Front Bumper',
		weight = 1200,
		stack = true,
		close = true,
		description = 'Stolen front bumper',
	},

	['rbumper'] = {
		label = 'Rear Bumper',
		weight = 1200,
		stack = true,
		close = true,
		description = 'Stolen rear bumper',
	},

	['silver_bar'] = {
		label = 'Silver Bar',
		weight = 500,
		stack = true,
		close = true,
		description = 'A shiny silver bar',
	},

	['silver_ring'] = {
		label = 'Silver Ring',
		weight = 100,
		stack = true,
		close = true,
		description = 'A simple silver ring',
	},

	['golden_ring'] = {
		label = 'Golden Ring',
		weight = 100,
		stack = true,
		close = true,
		description = 'A precious golden ring',
	},


	["m_jackets_bzmc1"] = {
		label = "Jaket BZMC1 Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket BZMC tipe 1 untuk pria",
	},

	["m_jackets_f4ke1_0"] = {
		label = "Jaket F4KE1 Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket F4KE tipe 1 untuk pria",
	},
	["m_jackets_f4ke1_1"] = {
		label = "Jaket F4KE1 Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket F4KE tipe 1 untuk pria",
	},

	["m_bodyarmor_bzmc1_0"] = {
		label = "Body Armor BZMC1 Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor BZMC tipe 1 untuk pria",
	},
	["m_bodyarmor_bzmc1_1"] = {
		label = "Body Armor BZMC1 Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor BZMC tipe 1 untuk pria",
	},
	["m_bodyarmor_bzmc1_2"] = {
		label = "Body Armor BZMC1 Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor BZMC tipe 1 untuk pria",
	},
	["m_bodyarmor_bzmc1_3"] = {
		label = "Body Armor BZMC1 Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor BZMC tipe 1 untuk pria",
	},
	["m_bodyarmor_bzmc1_4"] = {
		label = "Body Armor BZMC1 Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor BZMC tipe 1 untuk pria",
	},
	["m_bodyarmor_bzmc1_5"] = {
		label = "Body Armor BZMC1 Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor BZMC tipe 1 untuk pria",
	},
	["m_bodyarmor_bzmc1_6"] = {
		label = "Body Armor BZMC1 Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor BZMC tipe 1 untuk pria",
	},
	["m_bodyarmor_bzmc1_7"] = {
		label = "Body Armor BZMC1 Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor BZMC tipe 1 untuk pria",
	},

	["f_jackets_bzmc1"] = {
		label = "Jaket BZMC1 Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket BZMC tipe 1 untuk wanita",
	},

	["f_jackets_f4ke1_0"] = {
		label = "Jaket F4KE1 Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket F4KE tipe 1 untuk wanita",
	},
	["f_jackets_f4ke1_1"] = {
		label = "Jaket F4KE1 Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jaket F4KE tipe 1 untuk wanita",
	},

	["f_bodyarmor_bzmc1_0"] = {
		label = "Body Armor BZMC1 Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor BZMC tipe 1 untuk wanita",
	},
	["f_bodyarmor_bzmc1_1"] = {
		label = "Body Armor BZMC1 Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor BZMC tipe 1 untuk wanita",
	},
	["f_bodyarmor_bzmc1_2"] = {
		label = "Body Armor BZMC1 Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor BZMC tipe 1 untuk wanita",
	},
	["f_bodyarmor_bzmc1_3"] = {
		label = "Body Armor BZMC1 Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor BZMC tipe 1 untuk wanita",
	},
	["f_bodyarmor_bzmc1_4"] = {
		label = "Body Armor BZMC1 Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor BZMC tipe 1 untuk wanita",
	},
	["f_bodyarmor_bzmc1_5"] = {
		label = "Body Armor BZMC1 Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor BZMC tipe 1 untuk wanita",
	},
	["f_bodyarmor_bzmc1_6"] = {
		label = "Body Armor BZMC1 Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor BZMC tipe 1 untuk wanita",
	},
	["f_bodyarmor_bzmc1_7"] = {
		label = "Body Armor BZMC1 Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Body armor BZMC tipe 1 untuk wanita",
	},

	["m_jackets_babayo2"] = {
		label = "Jackets BABAYO Pria",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jackets BABAYO Pria",
	},

	["f_jackets_babayo1_0"] = {
		label = "Jackets BABAYO Wanita",
		weight = 10,
		stack = true,
		close = true,
		allowArmed = true,
		description = "Jackets BABAYO Wanita",
	},

	['race_chip'] = {
		label = 'Race Chip',
		weight = 10,
		stack = false,
		close = true,
		description = 'Chip yang digunakan untuk balapan',
	},

	['fakeplate'] = {
		label = 'Fake Plate',
		weight = 500,
		stack = false,
		close = true,
		description = 'Plat palsu untuk menyamarkan kendaraan',
	},
	['originalplate'] = {
		label = 'Plat Asli',
		weight = 500,
		stack = false,
		close = true,
		description = 'Plat asli kendaraan yang sedang memakai fake plate',
	},

	['suppresant_pill'] = {
		label = 'Suppresant Pill',
		weight = 10,
		stack = true,
		close = true,
		description = 'Pill Khusus',
	},

	["cctv_faulty"] = {
		label = "Faulty CCTV Camera",
		weight = 100,
		stack = true,
		close = true,
	},

	["cctv_default"] = {
		label = "Default CCTV Camera",
		weight = 100,
		stack = true,
		close = true,
	},

	["cctv_advanced"] = {
		label = "Advanced CCTV Camera",
		weight = 100,
		stack = true,
		close = true,
	},

	["cctv_tablet"] = {
		label = "CCTV Tablet",
		weight = 100,
		stack = true,
		close = true,
	},

	['spidol'] = {
		label = 'Spidol',
		weight = 50,
		stack = true,
		close = true,
		description = 'Spidol untuk membuat scene. Sekali pakai.',
		client = {
			usetime = false,
		}
	},

	['penghapus'] = {
		label = 'Penghapus',
		weight = 30,
		stack = true,
		close = true,
		description = 'Penghapus untuk menghapus scene terdekat. Sekali pakai.',
		client = {
			usetime = false,
		}
	},

    ['fleeca_tools'] = {
        label = 'Fleeca Tools',
        weight = 500,
        stack = false,
        close = true,
        degrade = 10080,
        description = 'Paket alat perampokan Fleeca',
        client = {
            export = 'sm_resource_1.openPackage'
        }
    },
    ['jewel_tools'] = {
        label = 'Jewelry Tools',
        weight = 500,
        stack = false,
        close = true,
        degrade = 10080,
        description = 'Paket alat perampokan Jewelry',
        client = {
            export = 'sm_resource_1.openPackage'
        }
    },
    ['bc_tools'] = {
        label = 'Blaine County Tools',
        weight = 500,
        stack = false,
        close = true,
        degrade = 10080,
        description = 'Paket alat perampokan Blaine County',
        client = {
            export = 'sm_resource_1.openPackage'
        }
    },
    ['pacific_tools'] = {
        label = 'Pacific Tools',
        weight = 500,
        stack = false,
        close = true,
        degrade = 10080,
        description = 'Paket alat perampokan Pacific',
        client = {
            export = 'sm_resource_1.openPackage'
        }
    },
    --blueprints
    ['wpn_blueprint'] = {
        label = 'Weapon Blueprint',
        stack = true,
        weight = 200,
    },
    ['armor_blueprint'] = {
        label = 'Armor Blueprint',
        stack = true,
        weight = 200,
    },
    ['ammo_blueprint'] = {
        label = 'Ammo Blueprint',
        stack = true,
        weight = 200,
    },
    ['tools_blueprint'] = {
        label = 'Tools Blueprint',
        stack = true,
        weight = 200,
    },

	-- Bleach Fashion Items
	['jpx_jigokucho'] = { label = 'Jigokucho', weight = 0, stack = false, close = true, description = 'JPX Bleach Fashion' },
	['jpx_kon'] = { label = 'Kon', weight = 0, stack = false, close = true, description = 'JPX Bleach Fashion' },
	['jpx_yoruichi_cat_form'] = { label = 'Yoruichi Cat Form', weight = 0, stack = false, close = true, description = 'JPX Bleach Fashion' },
	['jpx_nelliel_hat'] = { label = 'Nelliel Hat', weight = 0, stack = false, close = true, description = 'JPX Bleach Fashion' },
	['jpx_byakuya_sword'] = { label = 'Byakuya Sword', weight = 0, stack = false, close = true, description = 'JPX Bleach Fashion' },
	['jpx_kenpachi_sword'] = { label = 'Kenpachi Sword', weight = 0, stack = false, close = true, description = 'JPX Bleach Fashion' },
	['jpx_kira_izuru_sword'] = { label = 'Kira Izuru Sword', weight = 0, stack = false, close = true, description = 'JPX Bleach Fashion' },
	['jpx_madarame_ikkaku_sword'] = { label = 'Madarame Ikkaku Sword', weight = 0, stack = false, close = true, description = 'JPX Bleach Fashion' },
	['jpx_rukia_sword'] = { label = 'Rukia Sword', weight = 0, stack = false, close = true, description = 'JPX Bleach Fashion' },
	['jpx_shinji_hirako_sword'] = { label = 'Shinji Hirako Sword', weight = 0, stack = false, close = true, description = 'JPX Bleach Fashion' },
	['jpx_sui_feng_sword'] = { label = 'Sui Feng Sword', weight = 0, stack = false, close = true, description = 'JPX Bleach Fashion' },
	['jpx_yumichika_sword'] = { label = 'Yumichika Sword', weight = 0, stack = false, close = true, description = 'JPX Bleach Fashion' },
	['jpx_grimmjow_mask'] = { label = 'Grimmjow Mask', weight = 0, stack = false, close = true, description = 'JPX Bleach Fashion' },
	['jpx_ishida_uryu_bow'] = { label = 'Ishida Uryu Bow', weight = 0, stack = false, close = true, description = 'JPX Bleach Fashion' },
	['jpx_ishida_uryu_bow2'] = { label = 'Ishida Uryu Bow2', weight = 0, stack = false, close = true, description = 'JPX Bleach Fashion' },
	['jpx_kyoraku'] = { label = 'Kyoraku', weight = 0, stack = false, close = true, description = 'JPX Bleach Fashion' },
	['jpx_kyoraku_hat'] = { label = 'Kyoraku Hat', weight = 0, stack = false, close = true, description = 'JPX Bleach Fashion' },
	['jpx_kyoraku_coat'] = { label = 'Kyoraku Coat', weight = 0, stack = false, close = true, description = 'JPX Bleach Fashion' },
	['jpx_kyoraku_sword'] = { label = 'Kyoraku Sword', weight = 0, stack = false, close = true, description = 'JPX Bleach Fashion' },
	['jpx_kyoraku_sword2'] = { label = 'Kyoraku Sword2', weight = 0, stack = false, close = true, description = 'JPX Bleach Fashion' },
	['jpx_ichigo'] = { label = 'Ichigo', weight = 0, stack = false, close = true, description = 'JPX Bleach Fashion' },
	['jpx_ichigo_sword'] = { label = 'Ichigo Sword', weight = 0, stack = false, close = true, description = 'JPX Bleach Fashion' },
	['jpx_hollow_mask'] = { label = 'Hollow Mask', weight = 0, stack = false, close = true, description = 'JPX Bleach Fashion' },
	['jpx_ichigo2'] = { label = 'Ichigo2', weight = 0, stack = false, close = true, description = 'JPX Bleach Fashion' },
	['jpx_ichigo_sword2'] = { label = 'Ichigo Sword2', weight = 0, stack = false, close = true, description = 'JPX Bleach Fashion' },
	['jpx_hollow_mask2'] = { label = 'Hollow Mask2', weight = 0, stack = false, close = true, description = 'JPX Bleach Fashion' },
	['jpx_mayuri'] = { label = 'Mayuri', weight = 0, stack = false, close = true, description = 'JPX Bleach Fashion' },
	['jpx_mayuri_sword'] = { label = 'Mayuri Sword', weight = 0, stack = false, close = true, description = 'JPX Bleach Fashion' },
	['jpx_mayuri_bankai'] = { label = 'Mayuri Bankai', weight = 0, stack = false, close = true, description = 'JPX Bleach Fashion' },
	['jpx_renji'] = { label = 'Renji', weight = 0, stack = false, close = true, description = 'JPX Bleach Fashion' },
	['jpx_renji_sword'] = { label = 'Renji Sword', weight = 0, stack = false, close = true, description = 'JPX Bleach Fashion' },
	['jpx_renji_bankai'] = { label = 'Renji Bankai', weight = 0, stack = false, close = true, description = 'JPX Bleach Fashion' },
	['jpx_toshiro'] = { label = 'Toshiro', weight = 0, stack = false, close = true, description = 'JPX Bleach Fashion' },
	['jpx_toshiro_sword'] = { label = 'Toshiro Sword', weight = 0, stack = false, close = true, description = 'JPX Bleach Fashion' },
	['jpx_toshiro_wings'] = { label = 'Toshiro Wings', weight = 0, stack = false, close = true, description = 'JPX Bleach Fashion' },
	['jpx_toshiro_snow'] = { label = 'Toshiro Snow', weight = 0, stack = false, close = true, description = 'JPX Bleach Fashion' },
	['jpx_toshiro_tail'] = { label = 'Toshiro Tail', weight = 0, stack = false, close = true, description = 'JPX Bleach Fashion' },
	['jpx_toshiro_gauntlet'] = { label = 'Toshiro Gauntlet', weight = 0, stack = false, close = true, description = 'JPX Bleach Fashion' },
	['jpx_ulquiorra'] = { label = 'Ulquiorra', weight = 0, stack = false, close = true, description = 'JPX Bleach Fashion' },
	['jpx_ulquiorra_sword'] = { label = 'Ulquiorra Sword', weight = 0, stack = false, close = true, description = 'JPX Bleach Fashion' },
	['jpx_ulquiorra_wings'] = { label = 'Ulquiorra Wings', weight = 0, stack = false, close = true, description = 'JPX Bleach Fashion' },
	['jpx_ulquiorra_tail'] = { label = 'Ulquiorra Tail', weight = 0, stack = false, close = true, description = 'JPX Bleach Fashion' },
	['jpx_ulquiorra_horns'] = { label = 'Ulquiorra Horns', weight = 0, stack = false, close = true, description = 'JPX Bleach Fashion' },
	['jpx_urahara'] = { label = 'Urahara', weight = 0, stack = false, close = true, description = 'JPX Bleach Fashion' },
	['jpx_urahara_sword'] = { label = 'Urahara Sword', weight = 0, stack = false, close = true, description = 'JPX Bleach Fashion' },
	['jpx_urahara2'] = { label = 'Urahara2', weight = 0, stack = false, close = true, description = 'JPX Bleach Fashion' },
	['jpx_urahara_sword2'] = { label = 'Urahara Sword2', weight = 0, stack = false, close = true, description = 'JPX Bleach Fashion' },
	['jpx_urahara_hat'] = { label = 'Urahara Hat', weight = 0, stack = false, close = true, description = 'JPX Bleach Fashion' },
	['jpx_urahara_sword2_sheath'] = { label = 'Urahara Sword2 Sheath', weight = 0, stack = false, close = true, description = 'JPX Bleach Fashion' },
	['jpx_bleach_magic_circle'] = { label = 'Bleach Magic Circle', weight = 0, stack = false, close = true, description = 'JPX Bleach Fashion' },
	['jpx_aizen_chair'] = { label = 'Aizen Chair', weight = 0, stack = false, close = true, description = 'JPX Bleach Fashion' },
	['jpx_circle_bleach'] = { label = 'Circle Bleach', weight = 0, stack = false, close = true, description = 'JPX Bleach Fashion' },
	['jpx_kyoraku_hat_weapon'] = { label = 'Kyoraku Hat Weapon', weight = 0, stack = false, close = true, description = 'JPX Bleach Fashion' },
	['jpx_kyoraku_coat_weapon'] = { label = 'Kyoraku Coat Weapon', weight = 0, stack = false, close = true, description = 'JPX Bleach Fashion' },
	['jpx_grimmjow_sheath_weapon'] = { label = 'Grimmjow Sheath Weapon', weight = 0, stack = false, close = true, description = 'JPX Bleach Fashion' },
	['jpx_toshiro_snow_weapon'] = { label = 'Toshiro Snow Weapon', weight = 0, stack = false, close = true, description = 'JPX Bleach Fashion' },
	['jpx_toshiro_tail_weapon'] = { label = 'Toshiro Tail Weapon', weight = 0, stack = false, close = true, description = 'JPX Bleach Fashion' },
	['jpx_toshiro_gauntlet_weapon'] = { label = 'Toshiro Gauntlet Weapon', weight = 0, stack = false, close = true, description = 'JPX Bleach Fashion' },
	['jpx_ulquiorra_tail_weapon'] = { label = 'Ulquiorra Tail Weapon', weight = 0, stack = false, close = true, description = 'JPX Bleach Fashion' },
	['jpx_ulquiorra_horns_weapon'] = { label = 'Ulquiorra Horns Weapon', weight = 0, stack = false, close = true, description = 'JPX Bleach Fashion' },

	-- Neko Fashion --
	['jpx_neko_backpack'] = { label = 'Neko Backpack', weight = 0, stack = false, close = true, description = 'JPX Neko Fashion' },
	['jpx_neko_dropping'] = { label = 'Neko Dropping', weight = 0, stack = false, close = true, description = 'JPX Neko Fashion' },
	['jpx_neko_plushie'] = { label = 'Neko Plushie', weight = 0, stack = false, close = true, description = 'JPX Neko Fashion' },
	['jpx_neko_slippers'] = { label = 'Neko Slippers', weight = 0, stack = false, close = true, description = 'JPX Neko Fashion' },
	['jpx_neko_slippers1'] = { label = 'Neko Slippers 1', weight = 0, stack = false, close = true, description = 'JPX Neko Fashion' },
	['jpx_neko_backpack2'] = { label = 'Neko Backpack 2', weight = 0, stack = false, close = true, description = 'JPX Neko Fashion' },
	['jpx_neko_dropping2'] = { label = 'Neko Dropping 2', weight = 0, stack = false, close = true, description = 'JPX Neko Fashion' },
	['jpx_neko_plushie2'] = { label = 'Neko Plushie 2', weight = 0, stack = false, close = true, description = 'JPX Neko Fashion' },
	['jpx_neko_slippers2'] = { label = 'Neko Slippers 2', weight = 0, stack = false, close = true, description = 'JPX Neko Fashion' },
	['jpx_neko_slippers21'] = { label = 'Neko Slippers 21', weight = 0, stack = false, close = true, description = 'JPX Neko Fashion' },
	['jpx_neko_backpack3'] = { label = 'Neko Backpack 3', weight = 0, stack = false, close = true, description = 'JPX Neko Fashion' },
	['jpx_neko_dropping3'] = { label = 'Neko Dropping 3', weight = 0, stack = false, close = true, description = 'JPX Neko Fashion' },
	['jpx_neko_plushie3'] = { label = 'Neko Plushie 3', weight = 0, stack = false, close = true, description = 'JPX Neko Fashion' },
	['jpx_neko_slippers3'] = { label = 'Neko Slippers 3', weight = 0, stack = false, close = true, description = 'JPX Neko Fashion' },
	['jpx_neko_slippers31'] = { label = 'Neko Slippers 31', weight = 0, stack = false, close = true, description = 'JPX Neko Fashion' },

	-- Blooming Fashion --
	['jpx_blooming_balloons'] = { label = 'Blooming Balloons', weight = 0, stack = false, close = true, description = 'JPX Blooming Fashion' },
	['jpx_blooming_dragon'] = { label = 'Blooming Dragon', weight = 0, stack = false, close = true, description = 'JPX Blooming Fashion' },
	['jpx_blooming_floor'] = { label = 'Blooming Floor', weight = 0, stack = false, close = true, description = 'JPX Blooming Fashion' },
	['jpx_blooming_fabric'] = { label = 'Blooming Fabric', weight = 0, stack = false, close = true, description = 'JPX Blooming Fashion' },
	['jpx_blooming_wand'] = { label = 'Blooming Wand', weight = 0, stack = false, close = true, description = 'JPX Blooming Fashion' },
	['jpx_blooming_crown'] = { label = 'Blooming Crown', weight = 0, stack = false, close = true, description = 'JPX Blooming Fashion' },

	-- Pokemon Fashion --
	['jpx_pikachu'] = { label = 'Pikachu', weight = 0, stack = false, close = true, description = 'JPX Pokemon Fashion' },
	['jpx_pidgey'] = { label = 'Pidgey', weight = 0, stack = false, close = true, description = 'JPX Pokemon Fashion' },
	['jpx_butterfree'] = { label = 'Butterfree', weight = 0, stack = false, close = true, description = 'JPX Pokemon Fashion' },
	['jpx_jigglypuff'] = { label = 'Jigglypuff', weight = 0, stack = false, close = true, description = 'JPX Pokemon Fashion' },
	['jpx_bulbasaur'] = { label = 'Bulbasaur', weight = 0, stack = false, close = true, description = 'JPX Pokemon Fashion' },
	['jpx_poliwhirl'] = { label = 'Poliwhirl', weight = 0, stack = false, close = true, description = 'JPX Pokemon Fashion' },
	['jpx_magikarp'] = { label = 'Magikarp', weight = 0, stack = false, close = true, description = 'JPX Pokemon Fashion' },
	['jpx_squirtle'] = { label = 'Squirtle', weight = 0, stack = false, close = true, description = 'JPX Pokemon Fashion' },
	['jpx_meowth'] = { label = 'Meowth', weight = 0, stack = false, close = true, description = 'JPX Pokemon Fashion' },
	['jpx_psyduck'] = { label = 'Psyduck', weight = 0, stack = false, close = true, description = 'JPX Pokemon Fashion' },
	['jpx_charmander'] = { label = 'Charmander', weight = 0, stack = false, close = true, description = 'JPX Pokemon Fashion' },

	--Hirono Fashion--
	['jpx_hirono_being_alive'] = { label = 'Being Alive', weight = 0, stack = false, close = true, description = 'JPX Hirono Fashion' },
	['jpx_hirono_hidden'] = { label = 'Hidden', weight = 0, stack = false, close = true, description = 'JPX Hirono Fashion' },
	['jpx_hirono_the_monster'] = { label = 'The Monster', weight = 0, stack = false, close = true, description = 'JPX Hirono Fashion' },
	['jpx_hirono_raving'] = { label = 'Raving', weight = 0, stack = false, close = true, description = 'JPX Hirono Fashion' },
	['jpx_hirono_the_fox'] = { label = 'The Fox', weight = 0, stack = false, close = true, description = 'JPX Hirono Fashion' },
	['jpx_hirono_amnesia'] = { label = 'Amnesia', weight = 0, stack = false, close = true, description = 'JPX Hirono Fashion' },
	['jpx_hirono_vagrancy'] = { label = 'Vagrancy', weight = 0, stack = false, close = true, description = 'JPX Hirono Fashion' },
	['jpx_hirono_staring'] = { label = 'Staring', weight = 0, stack = false, close = true, description = 'JPX Hirono Fashion' },
	['jpx_hirono_cuckoo'] = { label = 'Cuckoo', weight = 0, stack = false, close = true, description = 'JPX Hirono Fashion' },
	['jpx_hirono_marionette'] = { label = 'Marionette', weight = 0, stack = false, close = true, description = 'JPX Hirono Fashion' },
	['jpx_hirono_no_where'] = { label = 'No Where', weight = 0, stack = false, close = true, description = 'JPX Hirono Fashion' },
	['jpx_hirono_the_crow'] = { label = 'The Crow', weight = 0, stack = false, close = true, description = 'JPX Hirono Fashion' },
	['jpx_hirono_the_ghost'] = { label = 'The Ghost', weight = 0, stack = false, close = true, description = 'JPX Hirono Fashion' },

	-- Crybaby Fashion --
	['jpx_crybaby_baby_blonde'] = { label = 'Baby Blonde', weight = 0, stack = false, close = true, description = 'JPX Crybaby Fashion' },
	['jpx_crybaby_duck_you'] = { label = 'Duck You', weight = 0, stack = false, close = true, description = 'JPX Crybaby Fashion' },
	['jpx_crybaby_the_robber'] = { label = 'The Robber', weight = 0, stack = false, close = true, description = 'JPX Crybaby Fashion' },
	['jpx_crybaby_heartless_girl'] = { label = 'Heartless Girl', weight = 0, stack = false, close = true, description = 'JPX Crybaby Fashion' },
	['jpx_crybaby_i_ll_bring_you_a_flower'] = { label = "I'll Bring You a Flower", weight = 0, stack = false, close = true, description = 'JPX Crybaby Fashion' },
	['jpx_crybaby_love_is_love'] = { label = 'Love Is Love', weight = 0, stack = false, close = true, description = 'JPX Crybaby Fashion' },
	['jpx_crybaby_i_ll_give_you_all_my_love'] = { label = "I'll Give You All My Love", weight = 0, stack = false, close = true, description = 'JPX Crybaby Fashion' },
	['jpx_crybaby_what_a_frog'] = { label = 'What a Frog', weight = 0, stack = false, close = true, description = 'JPX Crybaby Fashion' },
	['jpx_crybaby_the_robber_red'] = { label = 'The Robber Red', weight = 0, stack = false, close = true, description = 'JPX Crybaby Fashion' },
	['jpx_crybaby_star_boy'] = { label = 'Star Boy', weight = 0, stack = false, close = true, description = 'JPX Crybaby Fashion' },
	['jpx_crybaby_the_queen_of_broken_heart'] = { label = 'The Queen of Broken Heart', weight = 0, stack = false, close = true, description = 'JPX Crybaby Fashion' },
	['jpx_crybaby_baby_brown'] = { label = 'Baby Brown', weight = 0, stack = false, close = true, description = 'JPX Crybaby Fashion' },
	['jpx_crybaby_love_makes_us_cry'] = { label = 'Love Makes Us Cry', weight = 0, stack = false, close = true, description = 'JPX Crybaby Fashion' },
	['jpx_crybaby_she_s_alice'] = { label = "She's Alice", weight = 0, stack = false, close = true, description = 'JPX Crybaby Fashion' },
	['jpx_crybaby_she_s_alice_halloween'] = { label = "She's Alice Halloween", weight = 0, stack = false, close = true, description = 'JPX Crybaby Fashion' },

	-- Dragonball Fashion --
	['jpx_dragon_balls'] = { label = 'Dragon Balls', weight = 0, stack = false, close = true, description = 'JPX Dragonball Fashion' },
	['jpx_goku_backpack'] = { label = 'Goku Backpack', weight = 0, stack = false, close = true, description = 'JPX Dragonball Fashion' },
	['jpx_goku_cloud'] = { label = 'Goku Cloud', weight = 0, stack = false, close = true, description = 'JPX Dragonball Fashion' },
	['jpx_goku_tail'] = { label = 'Goku Tail', weight = 0, stack = false, close = true, description = 'JPX Dragonball Fashion' },
	['jpx_roshi_turtle_shell'] = { label = 'Roshi Turtle Shell', weight = 0, stack = false, close = true, description = 'JPX Dragonball Fashion' },
	['jpx_android16'] = { label = 'Android 16', weight = 0, stack = false, close = true, description = 'JPX Dragonball Fashion' },
	['jpx_android17'] = { label = 'Android 17', weight = 0, stack = false, close = true, description = 'JPX Dragonball Fashion' },
	['jpx_android18'] = { label = 'Android 18', weight = 0, stack = false, close = true, description = 'JPX Dragonball Fashion' },
	['jpx_buu'] = { label = 'Buu', weight = 0, stack = false, close = true, description = 'JPX Dragonball Fashion' },
	['jpx_frieza'] = { label = 'Frieza', weight = 0, stack = false, close = true, description = 'JPX Dragonball Fashion' },
	['jpx_goku'] = { label = 'Goku', weight = 0, stack = false, close = true, description = 'JPX Dragonball Fashion' },
	['jpx_krillin'] = { label = 'Krillin', weight = 0, stack = false, close = true, description = 'JPX Dragonball Fashion' },
	['jpx_majin_buu'] = { label = 'Majin Buu', weight = 0, stack = false, close = true, description = 'JPX Dragonball Fashion' },
	['jpx_master_roshi'] = { label = 'Master Roshi', weight = 0, stack = false, close = true, description = 'JPX Dragonball Fashion' },
	['jpx_piccolo'] = { label = 'Piccolo', weight = 0, stack = false, close = true, description = 'JPX Dragonball Fashion' },
	['jpx_shenron'] = { label = 'Shenron', weight = 0, stack = false, close = true, description = 'JPX Dragonball Fashion' },
	['jpx_korin'] = { label = 'Korin', weight = 0, stack = false, close = true, description = 'JPX Dragonball Fashion' },
	['jpx_puar'] = { label = 'Puar', weight = 0, stack = false, close = true, description = 'JPX Dragonball Fashion' },
	['jpx_goku_power_pole'] = { label = 'Goku Power Pole', weight = 0, stack = false, close = true, description = 'JPX Dragonball Fashion' },

	---@CASINO_MEMBER
	casino_gold_member = {
		label = 'Casino Gold Member',
		weight = 0,
		description = 'Casino Gold Membership Card',
	},
	casino_platinum_member = {
		label = 'Casino Platinum Member',
		weight = 0,
		description = 'Casino Platinum Membership Card',
	},

	---@Skateboard
	board_default = {
		label = 'Skateboard',
		weight = 5000,
		stack = false,
		degrade = 86400,
	},
	board_rhdxkosh = {
		label = 'RHD x Kosh Skateboard',
		weight = 5000,
		stack = false,
		degrade = 86400,
	},

    nk_anniv_skateboard = {
		label = '1st SM Skateboard',
		weight = 5000,
		stack = false,
		degrade = 5184000,
	},

	['worklight_04d'] = {
		label = 'Work Light Standard',
		weight = 3000,
		stack = true,
		close = true,
		description = 'Lampu kerja standar untuk penerangan area',
	},

	['worklight_02a'] = {
		label = 'Work Light Compact',
		weight = 2000,
		stack = true,
		close = true,
		description = 'Lampu kerja kompak portabel',
	},

	['worklight_04b'] = {
		label = 'Work Light Tall',
		weight = 3500,
		stack = true,
		close = true,
		description = 'Lampu kerja tinggi untuk area luas',
	},

	['worklight_04d_l1'] = {
		label = 'Work Light Bright',
		weight = 3000,
		stack = true,
		close = true,
		description = 'Lampu kerja terang intensitas tinggi',
	},

	['worklight_tripod_a'] = {
		label = 'Tripod Lamp A',
		weight = 3000,
		stack = true,
		close = true,
		description = 'Lampu tripod untuk penerangan area',
	},

	['worklight_tripod_b'] = {
		label = 'Tripod Lamp B',
		weight = 3000,
		stack = true,
		close = true,
		description = 'Lampu tripod untuk penerangan area',
	},

	['worklight_tower_a'] = {
		label = 'Tower Lamp',
		weight = 5000,
		stack = true,
		close = true,
		description = 'Menara lampu untuk penerangan area luas',
	},

	---@RHD_GIFTBOX
	['empty_giftbox'] = {
		label = 'Empty Gift Box',
		weight = 250,
		stack = true,
		close = true,
		description = 'An empty gift box ready to be packed.',
		client = {
			image = 'empty_giftbox.png'
		}
	},

	['giftbox'] = {
		label = 'Gift Box',
		weight = 500,
		stack = false,
		close = true,
		description = 'A packed gift box.',
		client = {
			image = 'giftbox.png'
		}
	},

	['giftbox_notes'] = {
		label = 'Gift Box with Notes',
		weight = 500,
		stack = false,
		close = true,
		description = 'A packed gift box with a handwritten note.',
		client = {
			image = 'giftbox_notes.png'
		}
	},

	['outfitbag'] = {
		label = 'Outfit Bag',
		weight = 600,
		stack = false,
		consume = 0, -- 1 item per slot; binding ke 1 player via metadata cid
		close = true,
		description = 'Tas berisi outfit. Gunakan untuk menaruh tas & ganti baju dari outfit tersimpan.',
		client = {
			image = 'outfitbag.png',
		},
		server = {
			export = 'sm_resource_1.outfitbag',
		},
	},

	lspdbadge = {
		label = 'LSPD Badge',
		weight = 0,
		stack = false,
		close = true,
		description = 'LSPD Badge',
		client = {
			image = 'lspdbadge.png',
		}
	},
	bcsobadge = {
		label = 'BCSO Badge',
		weight = 0,
		stack = false,
		close = true,
		description = 'BCSO Badge',
		client = {
			image = 'bcsobadge.png',
		}
	},
	dojbadge = {
		label = 'DOJ Badge',
		weight = 0,
		stack = false,
		close = true,
		description = 'DOJ Badge',
		client = {
			image = 'dojbadge.png',
		}
	},
	saspbadge = {
		label = 'SASP Badge',
		weight = 0,
		stack = false,
		close = true,
		description = 'SASP Badge',
		client = {
			image = 'saspbadge.png',
		}
	},
	usmbadge = {
		label = 'USM Badge',
		weight = 0,
		stack = false,
		close = true,
		description = 'USM Badge',
		client = {
			image = 'usmbadge.png',
		}
	},

	merryweather_badge = {
		label = 'Merryweather Badge',
		weight = 0,
		stack = false,
		close = true,
		description = 'Merryweather Badge',
		client = {
			image = 'merryweather_badge.png',
		}
	},

	-- paspampres_badge = {
	-- 	label = 'Paspampres Badge',
	-- 	weight = 0,
	-- 	stack = false,
	-- 	close = true,
	-- 	description = 'Paspampres Badge',
	-- 	client = {
	-- 		image = 'paspampres_badge.png',
	-- 	}
	-- },

	-- style backpack
	["trap_buchonerose"] = {
		label = "Trap Buchone Rose",
		weight = 100,
		stack = true,
		close = true,
		description = "Fashion Backpack",
	},
	["trap_ramorosa"] = {
		label = "Trap Ramorosa",
		weight = 100,
		stack = true,
		close = true,
		description = "Fashion Backpack",
	},
	["trap_lbone"] = {
		label = "Trap Labubu One",
		weight = 100,
		stack = true,
		close = true,
		description = "Fashion Backpack",
	},
	["trap_lbtwo"] = {
		label = "Trap Labubu Two",
		weight = 100,
		stack = true,
		close = true,
		description = "Fashion Backpack",
	},
	["trap_lbtree"] = {
		label = "Trap Labubu Three",
		weight = 100,
		stack = true,
		close = true,
		description = "Fashion Backpack",
	},
	["trap_lbfort"] = {
		label = "Trap Labubu Four",
		weight = 100,
		stack = true,
		close = true,
		description = "Fashion Backpack",
	},
	["tr_cerdito"] = {
		label = "Trap Cerdito",
		weight = 100,
		stack = true,
		close = true,
		description = "Fashion Backpack",
	},
	["ramliliam_trap"] = {
		label = "Trap Ramonovia",
		weight = 100,
		stack = true,
		close = true,
		description = "Fashion Backpack",
	},
	["globolia_trap"] = {
		label = "Trap Globolia",
		weight = 100,
		stack = true,
		close = true,
		description = "Fashion Backpack",
	},
	["trapshop_chukie"] = {
		label = "Trap Chukie",
		weight = 100,
		stack = true,
		close = true,
		description = "Fashion Backpack",
	},
	["trap_juniorh"] = {
		label = "Trap Junior H",
		weight = 100,
		stack = true,
		close = true,
		description = "Fashion Backpack",
	},
	["trap_bichota"] = {
		label = "Trap Bichota",
		weight = 100,
		stack = true,
		close = true,
		description = "Fashion Backpack",
	},
	["trap_dogshark"] = {
		label = "Trap Dog Shark",
		weight = 100,
		stack = true,
		close = true,
		description = "Fashion Backpack",
	},
	["trap_catpurple"] = {
		label = "Trap Cat Purple",
		weight = 100,
		stack = true,
		close = true,
		description = "Fashion Backpack",
	},
	["trap_conejowep"] = {
		label = "Trap Conejo Wep",
		weight = 100,
		stack = true,
		close = true,
		description = "Fashion Backpack",
	},
	["trap_maquinita"] = {
		label = "Trap Maquinita",
		weight = 100,
		stack = true,
		close = true,
		description = "Fashion Backpack",
	},
	["trap_conejogamer"] = {
		label = "Trap Conejo Gamer",
		weight = 100,
		stack = true,
		close = true,
		description = "Fashion Backpack",
	},
	["trap_osofn"] = {
		label = "Trap Oso FN",
		weight = 100,
		stack = true,
		close = true,
		description = "Fashion Backpack",
	},
	["trap_bananin"] = {
		label = "Trap Bananin",
		weight = 100,
		stack = true,
		close = true,
		description = "Fashion Backpack",
	},
	["trap_kawsito"] = {
		label = "Trap Kawsito",
		weight = 100,
		stack = true,
		close = true,
		description = "Fashion Backpack",
	},
	["trap_ardillita"] = {
		label = "Trap Ardillita",
		weight = 100,
		stack = true,
		close = true,
		description = "Fashion Backpack",
	},
	["trap_dinoos"] = {
		label = "Trap Dinoos",
		weight = 100,
		stack = true,
		close = true,
		description = "Fashion Backpack",
	},
	["trap_axolote"] = {
		label = "Trap Axolote",
		weight = 100,
		stack = true,
		close = true,
		description = "Fashion Backpack",
	},
	["trap_ardillaxm"] = {
		label = "Trap Ardilla XM",
		weight = 100,
		stack = true,
		close = true,
		description = "Fashion Backpack",
	},
	["trap_patitogang"] = {
		label = "Trap Patito Gang",
		weight = 100,
		stack = true,
		close = true,
		description = "Fashion Backpack",
	},
	["trap_chukicbe"] = {
		label = "Trap Chuki CBE",
		weight = 100,
		stack = true,
		close = true,
		description = "Fashion Backpack",
	},
	["bidak_catur"] = {
		label = "Bidak Catur",
		weight = 500,
		stack = true,
		close = true,
		description = "Satu set papan catur portabel, bisa ditaruh di mana saja",
	},

    ['gamestation'] = {
        label = 'Game Station',
        weight = 1000,
		degrade = 43200,
        stack = false,
        close = true,
        description = 'A game station console you can place down.'
    },

    ["nk_alienbag"] = {
		label = "Alien Bag",
		weight = 100,
		stack = true,
		close = true,
		description = "Fashion Backpack",
	},
	["nk_astrobag"] = {
		label = "Astro Bag",
		weight = 100,
		stack = true,
		close = true,
		description = "Fashion Backpack",
	},
	["nk_dogbag"] = {
		label = "Dog Bag",
		weight = 100,
		stack = true,
		close = true,
		description = "Fashion Backpack",
	},
	["nk_heartbag"] = {
		label = "Heart Bag",
		weight = 100,
		stack = true,
		close = true,
		description = "Fashion Backpack",
	},
	["nk_gothbag"] = {
		label = "Goth Bag",
		weight = 100,
		stack = true,
		close = true,
		description = "Fashion Backpack",
	},
	["nk_kittybag"] = {
		label = "Kitty Bag",
		weight = 100,
		stack = true,
		close = true,
		description = "Fashion Backpack",
	},
	["nk_monkebag"] = {
		label = "Monke Bag",
		weight = 100,
		stack = true,
		close = true,
		description = "Fashion Backpack",
	},
	["nk_rickbag"] = {
		label = "Rick Bag",
		weight = 100,
		stack = true,
		close = true,
		description = "Fashion Backpack",
	},
	["nk_streetbag"] = {
		label = "Street Bag",
		weight = 100,
		stack = true,
		close = true,
		description = "Fashion Backpack",
	},
	["nk_survivalbag"] = {
		label = "Survival Bag",
		weight = 100,
		stack = true,
		close = true,
		description = "Fashion Backpack",
	},

	["material_a"] = {
		label = "Material A",
		weight = 500,
		stack = true,
		close = true,
		description = "Panel sarang lebah komposit untuk perakitan kendaraan sci-fi",
	},
	["material_b"] = {
		label = "Material B",
		weight = 500,
		stack = true,
		close = true,
		description = "Pelat logam berlapis untuk perakitan kendaraan sci-fi",
	},
	["material_c"] = {
		label = "Material C",
		weight = 500,
		stack = true,
		close = true,
		description = "Bijih logam mentah untuk perakitan kendaraan sci-fi",
	},
	["material_d"] = {
		label = "Material D",
		weight = 500,
		stack = true,
		close = true,
		description = "Kristal energi untuk perakitan kendaraan sci-fi",
	},

	stretcher = {
		label = 'Stretcher',
		weight = 5000,
	},
	-- Battleground
	-- battleground_loadout = {
	-- 	label = 'Battleground Loadout',
	-- 	weight = 0,
	-- 	description = 'Loadout for Battleground',
	-- 	rarity = 'rare',
	-- },
	-- sanchez = {
	-- 	label = 'Sanchez',
	-- 	weight = 0,
	-- 	description = 'Sanchez for Battleground',
	-- 	rarity = 'rare',
	-- }

	-- ["sm_sapu_terbang"] = {
	-- 	label = "Sapu Terbang",
	-- 	weight = 800,
	-- 	stack = false,
	-- 	close = true,
	-- 	degrade = 180,
	-- 	description = "Sapu ajaib Dream City. Aktif 3 jam sejak diambil.",
	-- },

	-- ["sm_sayap_naga"] = {
	-- 	label = "Sayap Naga",
	-- 	weight = 500,
	-- 	stack = false,
	-- 	close = true,
	-- 	degrade = 180,
	-- 	description = "Sayap naga Dream City. Aktif 3 jam sejak diambil.",
	-- },

	-- ["sm_babi_terbang"] = {
	-- 	label = "Babi Terbang",
	-- 	weight = 900,
	-- 	stack = false,
	-- 	close = true,
	-- 	degrade = 180,
	-- 	description = "Babi terbang Dream City. Aktif 3 jam sejak diambil.",
	-- },
    ht_coin1 = {
		label = 'Authority Pass',
		weight = 100
	},
	['cleanwater'] = {
		label = 'Pet Water Gallon',
		weight = 1000,
		stack = true,
		close = true,
		description = 'Air bersih untuk pet.',
		client = {
			image = 'cleanwater.png',
		},
	},

	['petfood1'] = {
		label = 'Chicken Dog Food',
		weight = 500,
		stack = true,
		close = true,
		description = 'Makanan pet. Dipakai saat pet sedang dikeluarkan.',
		client = {
			image = 'petfood1.png',
		},
	},

	['petfood2'] = {
		label = 'Porterhouse Dog Food',
		weight = 500,
		stack = true,
		close = true,
		description = 'Makanan pet. Dipakai saat pet sedang dikeluarkan.',
		client = {
			image = 'petfood2.png',
		},
	},

	['petfood3'] = {
		label = 'Filet Mignon Dog Food',
		weight = 500,
		stack = true,
		close = true,
		description = 'Makanan pet. Dipakai saat pet sedang dikeluarkan.',
		client = {
			image = 'petfood3.png',
		},
	},

	['petfood4'] = {
		label = 'Pate Poultry Platter',
		weight = 400,
		stack = true,
		close = true,
		description = 'Makanan kucing. Dipakai saat pet sedang dikeluarkan.',
		client = {
			image = 'petfood4.png',
		},
	},

	['petfood5'] = {
		label = 'Tasty Treasure Pate',
		weight = 400,
		stack = true,
		close = true,
		description = 'Makanan kucing. Dipakai saat pet sedang dikeluarkan.',
		client = {
			image = 'petfood5.png',
		},
	},

	['petfood6'] = {
		label = 'Proactive Health',
		weight = 400,
		stack = true,
		close = true,
		description = 'Makanan kucing. Dipakai saat pet sedang dikeluarkan.',
		client = {
			image = 'petfood6.png',
		},
	},

	['pettreat1'] = {
		label = 'Beef & Bacon Biscuits',
		weight = 150,
		stack = true,
		close = true,
		description = 'Camilan pet.',
		client = {
			image = 'pettreat1.png',
		},
	},

	['pettreat2'] = {
		label = 'Yogurt Biscuits',
		weight = 150,
		stack = true,
		close = true,
		description = 'Camilan pet.',
		client = {
			image = 'pettreat2.png',
		},
	},

	['pettreat3'] = {
		label = 'Peanut Butter Biscuits',
		weight = 150,
		stack = true,
		close = true,
		description = 'Camilan pet.',
		client = {
			image = 'pettreat3.png',
		},
	},

	['petmedlow'] = {
		label = 'Pet Medkit (Ringan)',
		weight = 300,
		stack = true,
		close = true,
		description = 'Obat pet. Menyembuhkan atau menyadarkan pet.',
		client = {
			image = 'petmedlow.png',
		},
	},

	['petmedmed'] = {
		label = 'Pet Medkit (Sedang)',
		weight = 400,
		stack = true,
		close = true,
		description = 'Obat pet. Menyembuhkan atau menyadarkan pet.',
		client = {
			image = 'petmedmed.png',
		},
	},

	['petmedhigh'] = {
		label = 'Pet Medkit (Kuat)',
		weight = 500,
		stack = true,
		close = true,
		description = 'Obat pet. Menyembuhkan atau menyadarkan pet.',
		client = {
			image = 'petmedhigh.png',
		},
	},

	['kf_tactical_drone_shield'] = {
		label = 'Tactical Shield Drone',
		weight = 12000,
		stack = false,
		close = true,
		description = 'Drone pembawa shield',
		client = {
			export = 'sm_resource_1.useDroneShield',
		},
	},

	['kf_tactical_drone_tablet'] = {
		label = 'Tactical Drone Tablet',
		weight = 1000,
		stack = false,
		close = true,
		description = 'Tablet kendali drone shield',
		client = {
			export = 'sm_resource_1.useDroneTablet',
		},
	},

	['obdadapter'] = {
		label = 'OBD Adapter',
		weight = 300,
		stack = true,
		close = true,
		description = 'Membaca & mem-flash ECU kendaraan',
		client = {
			export = 'sm_ecutuning.useObd',
		},
	},

	['ecurepair'] = {
		label = 'ECU Repair Kit',
		weight = 800,
		stack = true,
		close = true,
		description = 'Memperbaiki ECU yang mati total',
		client = {
			export = 'sm_ecutuning.useRepair',
		},
	},

	['ecu_downpipe'] = {
		label = 'Downpipe',
		weight = 4000,
		stack = true,
		close = true,
		description = 'Part knalpot performa',
		client = {
			export = 'sm_ecutuning.usePart',
		},
	},

	['ecu_straightpipe'] = {
		label = 'Straight Pipe',
		weight = 3500,
		stack = true,
		close = true,
		description = 'Part knalpot performa',
		client = {
			export = 'sm_ecutuning.usePart',
		},
	},

	['ecu_muffler'] = {
		label = 'Rear Muffler',
		weight = 3000,
		stack = true,
		close = true,
		description = 'Muffler belakang, membuka mega flame',
		client = {
			export = 'sm_ecutuning.usePart',
		},
	},

	['ecu_intercooler'] = {
		label = 'Intercooler',
		weight = 4500,
		stack = true,
		close = true,
		description = 'Pendingin udara turbo',
		client = {
			export = 'sm_ecutuning.usePart',
		},
	},

	['ecu_airfilter'] = {
		label = 'Air Filter',
		weight = 800,
		stack = true,
		close = true,
		description = 'Filter udara performa',
		client = {
			export = 'sm_ecutuning.usePart',
		},
	},

	['ecu_turbo'] = {
		label = 'Turbo Upgrade',
		weight = 6000,
		stack = true,
		close = true,
		description = 'Upgrade turbocharger',
		client = {
			export = 'sm_ecutuning.usePart',
		},
	},

	['ecu_stage1'] = {
		label = 'ECU Stage 1',
		weight = 200,
		stack = true,
		close = true,
		description = 'Chip flash ECU stage 1',
		client = {
			export = 'sm_ecutuning.usePart',
		},
	},

	['ecu_stage2'] = {
		label = 'ECU Stage 2',
		weight = 200,
		stack = true,
		close = true,
		description = 'Chip flash ECU stage 2',
		client = {
			export = 'sm_ecutuning.usePart',
		},
	},

	['ecu_stage3'] = {
		label = 'ECU Stage 3',
		weight = 200,
		stack = true,
		close = true,
		description = 'Chip flash ECU stage 3',
		client = {
			export = 'sm_ecutuning.usePart',
		},
	},

	['ecu_gearflash'] = {
		label = 'Gearbox Flash',
		weight = 200,
		stack = true,
		close = true,
		description = 'Flash transmisi (shift pop)',
		client = {
			export = 'sm_ecutuning.usePart',
		},
	},

	['ecu_driftflash'] = {
		label = 'Differential Flash',
		weight = 200,
		stack = true,
		close = true,
		description = 'Flash diferensial (mode drift)',
		client = {
			export = 'sm_ecutuning.usePart',
		},
	},

	['ecu_antilagflash'] = {
		label = 'Anti-Lag Flash',
		weight = 200,
		stack = true,
		close = true,
		description = 'Flash anti-lag & launch control',
		client = {
			export = 'sm_ecutuning.usePart',
		},
	},

    ['peace1'] = {
        label = 'Sovereign Peace Emblem',
        weight = 150,
        stack = true,
        close = true,
        description = 'Goverment Emblem',
    },
    ['peace2'] = {
        label = 'Covenant of Justice',
        weight = 150,
        stack = true,
        close = true,
        description = 'DOJ Emblem',
    },
    ['peace3'] = {
        label = 'Voice of Accord',
        weight = 150,
        stack = true,
        close = true,
        description = 'Media Emblem',
    },
    ['peace4'] = {
        label = 'Guardian Peace Insignia',
        weight = 150,
        stack = true,
        close = true,
        description = 'Police Emblem',
    },
    ['peace5'] = {
        label = 'Sanctuary of Life',
        weight = 150,
        stack = true,
        close = true,
        description = 'EMS Emblem',
    },

	['trolley'] = {
		label = 'Troli Belanja',
		weight = 3000,
		stack = false,
		close = true,
		description = 'Troli penyimpanan sementara (50 slot, 500 kg). Gunakan untuk mengeluarkan atau menyimpan troli.',
	},
    ['warden_pin'] = {
        label = 'The Warden Maker',
        weight = 150,
        stack = true,
        close = true,
        description = 'Warden Pin Maker',
		consume = 0,
		server = { export = 'sm_resource_2.warden_pin' },
    },
    ['warden_pin_final'] = {
        label = 'The Warden ID',
        weight = 150,
        stack = true,
        close = true,
        description = 'Identification Card',
		consume = 0,
		server = { export = 'sm_resource_2.warden_pin_final' },
    },
    ['full_access_card'] = {
        label = 'Fully Authorization Card',
        weight = 150,
        stack = true,
        close = true,
        degrade = 86400,
        description = 'Full Authorization Card for complete access',
    },
    ['restricted_access_card'] = {
        label = 'Restricted Access Card',
        weight = 150,
        stack = true,
        close = true,
        description = 'Restricted Access Card for limited access',
    },
    ['seal_maker'] = {
        label = 'Seal Maker',
        weight = 150,
        stack = true,
        close = true,
        description = 'Seal Maker Card',
		consume = 0,
		server = { export = 'sm_resource_2.seal_maker' },
        client = {
			image = 'seal_card.png',
		},
    },
    ['seal_card'] = {
        label = 'Seal Of Protection',
        weight = 150,
        stack = true,
        close = true,
        description = 'Identification Card',
		consume = 0,
		server = { export = 'sm_resource_2.seal_card' },
        client = {
			image = 'seal_card.png',
		},
    },

    ['c4'] = {
        label = 'C4 Timer',
        weight = 2000,
        stack = true,
        close = true,
        description = 'Bom berwaktu, butuh PIN 6 digit',
        client = {
			image = 'bomb_c4.png',
		},
    },
    ['triggerc4'] = {
        label = 'Trigger C4',
        weight = 1500,
        stack = true,
        close = true,
        description = 'Bom diledakkan lewat detonator',
        client = {
			image = 'WEAPON_STICKYBOMB.png',
		},
    },
    ['detonator'] = {
        label = 'Detonator',
        weight = 300,
        stack = false,
        close = true,
        description = 'Pemicu jarak jauh untuk Trigger C4',
    },
    ['defuse_kit'] = {
        label = 'Defuse Kit',
        weight = 1000,
        stack = false,
        close = true,
        description = 'Alat untuk menjinakkan bom',
    },

    ['domino_table'] = {
        label = 'Domino Table',
        weight = 8000,
        stack = false,
        close = true,
        description = 'Folding domino table with four chairs and a full set of tiles',
    },

	-- MARK:TCG
	['tcg_card'] = {
		label = 'Kartu TCG',
		weight = 10,
		stack = false,
		close = true,
		client = {
			export = 'sm_tcgcards.card',
		},
		buttons = {
			{
				label = 'Masukkan ke album',
				action = function(slot)
					exports.sm_tcgcards:putInAlbum(slot)
				end,
			},
		},
	},

	['tcg_sleeve'] = {
		label = 'Sleeve Kartu',
		weight = 5,
		stack = true,
		close = true,
	},

	['tcg_grading'] = {
		label = 'Kit Grading',
		weight = 200,
		stack = true,
		close = true,
		client = {
			export = 'sm_tcgcards.grading',
		},
	},

	['tcg_pack_dva'] = {
		label = 'Booster Pack Koleksi Perdana',
		weight = 50,
		stack = true,
		close = true,
		client = {
			image = 'tcg_pack.png',
			export = 'sm_tcgcards.pack',
		},
	},

	['tcg_box_dva'] = {
		label = 'Booster Box Koleksi Perdana',
		weight = 600,
		stack = true,
		close = true,
		client = {
			image = 'tcg_box.png',
			export = 'sm_tcgcards.box',
		},
	},

	['tcg_album_dva'] = {
		label = 'Album Koleksi Perdana',
		weight = 800,
		stack = false,
		close = true,
		client = {
			image = 'tcg_album.png',
			export = 'sm_tcgcards.album',
		},
	},

	['taser_cartridge'] = {
		label = 'Taser Cartridge',
		weight = 50,
		stack = true,
		close = true,
		description = 'Taser cartridge, holds 3 shots. Carry limit: 3.',
	},

	['custom_receipt'] = {
		label = 'Modification Receipt',
		weight = 10,
		stack = false,
		close = true,
		description = 'Self service workshop receipt. Hand it to a workshop mechanic to pay and install.',
		client = {
			image = 'custom_receipt.png',
		},
	},
}


