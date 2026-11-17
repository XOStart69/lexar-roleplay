Config = {}

Config.EnableExtraMenu = true
Config.Fliptime = 15000

Config.MenuItems = {
	[1] = {
		id = "citizen",
		title = "Player Menu",
		icon = "hand",
		items = {
			{
				id = "playerinvehicle",
				title = "Put In Vehicle",
				icon = "car-side",
				type = "client",
				event = "police:client:PutPlayerInVehicle",
				shouldClose = true
			},
			{
				id = "playeroutvehicle",
				title = "Put Out Vehicle",
				icon = "car-side",
				type = "client",
				event = "police:client:SetPlayerOutVehicle",
				shouldClose = true
			},
			{
				id = "stealplayer",
				title = "Rob",
				icon = "mask",
				type = "client",
				event = "police:client:RobPlayer",
				shouldClose = true
			},
			
			{
				id = "escort",
				title = "Escort",
				icon = "user-group",
				type = "client",
				event = "police:client:EscortPlayer",
				shouldClose = true
			},
			{
				id = "getintrunk",
				title = "Get In Trunk",
				icon = "car",
				type = "client",
				event = "qb-trunk:client:GetIn",
				shouldClose = true
			},
		}
	},
	[2] = {
		id = 'OpenPhone',
		title = 'Phone',
		icon = 'mobile',
		type = 'client',
		event = 'axon:openPhone',
		shouldClose = true
	},
	[3] = {
        id = 'OpenInventory',
        title = 'Inventory',
        icon = 'bag-shopping',
        type = 'client',
        event = 'ox_inventory:openInventory',
        shouldClose = true
    },
	[6] = {
        id = 'dokumenpenting',
        title = 'Dokumen',
        icon = 'folder-open',
        type = 'command',
        event = 'doc',
        shouldClose = true
    },
	[4] = {
		id = 'emotemenu',
		title = 'Emote Menu',
		icon = 'person',
		items = {
			{
				id="foldarms",
				title="Foldarms",
				icon="person",
				type = "command",
				event = "e foldarms2",
				shouldClose = true
			},
			{
				id="salute",
				title="Salute",
				icon="person",
				type = "command",
				event = "e salute",
				shouldClose = true
			},
			{
				id="facepalm",
				title="Face Palm",
				icon="person",
				type = "command",
				event = "e facepalm",
				shouldClose = true
			},
			{
				id="think2",
				title="Think2",
				icon="person",
				type = "command",
				event = "e think2",
				shouldClose = true
			},
			{
				id="clap",
				title="Clap",
				icon="person",
				type = "command",
				event = "e clap",
				shouldClose = true
			},
			{
				id="valet3",
				title="Valet3",
				icon="person",
				type = "command",
				event = "e valet3",
				shouldClose = true
			},
			{
				id="noway",
				title="No",
				icon="person",
				type = "command",
				event = "e no",
				shouldClose = true
			},
			{
				id="peace",
				title="Peace",
				icon="person",
				type = "command",
				event = "e peace",
				shouldClose = true
			},
			{
				id="wave7",
				title="Wave7",
				icon="person",
				type = "command",
				event = "e wave7",
				shouldClose = true
			},
			{
				id="argue",
				title="Argue",
				icon="person",
				type = "command",
				event = "e argue",
				shouldClose = true
			},
		}
	},
	[5] = {
        id = 'billing',
        title = 'Invoice',
        icon = 'file-invoice',
        type = 'command',
        event = 'billing',
        shouldClose = true
    },
	[8] = {
		id = 'fixmenu',
		title = 'Fix Menu',
		icon = 'wrench',
		items = {
			{
				id = 'reloadskin',
				title = 'reloadskin',
				icon = 'person',
				type = 'command',
				event = 'reloadskin',
				shouldClose = true
			},
			{
				id = 'fixui',
				title = 'fixui',
				icon = 'window-restore',
				type = 'command',
				event = 'fixui',
				shouldClose = true
			},
			{
				id = 'tenggelam',
				title = 'tenggelam',
				icon = 'arrow-up-from-ground-water',
				type = 'command',
				event = 'tenggelam',
				shouldClose = true
			},
			{
				id = 'kedip',
				title = 'kedip',
				icon = 'arrows-rotate',
				type = 'command',
				event = 'kedip',
				shouldClose = true
			},
			{
				id = 'mikir',
				title = 'mikir',
				icon = 'brain',
				action = function()
					lib.registerContext({
						id = 'sm_cache_menu',
						title = 'Download Cache',
						options = {
							{
								title = 'Mulai Download',
								description = 'Download cache aset server tanpa keliling (ESC sembunyikan kursor)',
								icon = 'download',
								onSelect = function() ExecuteCommand('mikir') end,
							},
							{
								title = 'Panel Cache',
								description = 'Scan & pilih resource yang mau di-download',
								icon = 'list-check',
								onSelect = function() ExecuteCommand('aturpikiran') end,
							},
							{
								title = 'Berhenti',
								description = 'Batalkan download, progress disimpan',
								icon = 'circle-stop',
								onSelect = function() ExecuteCommand('berhentimikir') end,
							},
						},
					})
					lib.showContext('sm_cache_menu')
				end,
				shouldClose = true
			},
		}
	},
	[7] = {
		id = "clothesmenu",
		title = "Clothing",
		icon = "shirt",
		action = function()
			exports.sm_appearance:openClothingRail()
		end,
		shouldClose = true
	},

	[9] = {
		id = 'petmenu',
		title = 'Pet',
		icon = 'paw',
		type = 'command',
		event = 'pet',
		shouldClose = true
	},
}

Config.VehicleDoors = {
	id = "vehicledoors",
	title = "Vehicle Doors",
	icon = "car-side",
	items = {
		{
			id = "door0",
			title = "Drivers door",
			icon = "car-side",
			type = "client",
			event = "qb-radialmenu:client:openDoor",
			arg = 0,
			shouldClose = false
		},
		{
			id = "door4",
			title = "Hood",
			icon = "car",
			type = "client",
			event = "qb-radialmenu:client:openDoor",
			arg = 4,
			shouldClose = false
		},
		{
			id = "door1",
			title = "Passengers door",
			icon = "car-side",
			type = "client",
			event = "qb-radialmenu:client:openDoor",
			arg = 1,
			shouldClose = false
		},
		{
			id = "door3",
			title = "Right rear",
			icon = "car-side",
			type = "client",
			event = "qb-radialmenu:client:openDoor",
			arg = 3,
			shouldClose = false
		},
		{
			id = "door5",
			title = "Trunk",
			icon = "car",
			type = "client",
			event = "qb-radialmenu:client:openDoor",
			arg = 5,
			shouldClose = false
		},
		{
			id = "door2",
			title = "Left rear",
			icon = "car-side",
			type = "client",
			event = "qb-radialmenu:client:openDoor",
			arg = 2,
			shouldClose = false
		}
	}
}

Config.VehicleExtras = {
	id = "vehicleextras",
	title = "Vehicle Extras",
	icon = "plus",
	items = {
		{
			id = "extra1",
			title = "Extra 1",
			icon = "box-open",
			type = "client",
			event = "radialmenu:client:setExtra",
			arg = 1,
			shouldClose = false
		},
		{
			id = "extra2",
			title = "Extra 2",
			icon = "box-open",
			type = "client",
			event = "radialmenu:client:setExtra",
			arg = 2,
			shouldClose = false
		},
		{
			id = "extra3",
			title = "Extra 3",
			icon = "box-open",
			type = "client",
			event = "radialmenu:client:setExtra",
			arg = 3,
			shouldClose = false
		},
		{
			id = "extra4",
			title = "Extra 4",
			icon = "box-open",
			type = "client",
			event = "radialmenu:client:setExtra",
			arg = 4,
			shouldClose = false
		},
		{
			id = "extra5",
			title = "Extra 5",
			icon = "box-open",
			type = "client",
			event = "radialmenu:client:setExtra",
			arg = 5,
			shouldClose = false
		},
		{
			id = "extra6",
			title = "Extra 6",
			icon = "box-open",
			type = "client",
			event = "radialmenu:client:setExtra",
			arg = 6,
			shouldClose = false
		},
		{
			id = "extra7",
			title = "Extra 7",
			icon = "box-open",
			type = "client",
			event = "radialmenu:client:setExtra",
			arg = 7,
			shouldClose = false
		},
		{
			id = "extra8",
			title = "Extra 8",
			icon = "box-open",
			type = "client",
			event = "radialmenu:client:setExtra",
			arg = 8,
			shouldClose = false
		},
		{
			id = "extra9",
			title = "Extra 9",
			icon = "box-open",
			type = "client",
			event = "radialmenu:client:setExtra",
			arg = 9,
			shouldClose = false
		},
		{
			id = "extra10",
			title = "Extra 10",
			icon = "box-open",
			type = "client",
			event = "radialmenu:client:setExtra",
			arg = 10,
			shouldClose = false
		},
		{
			id = "extra11",
			title = "Extra 11",
			icon = "box-open",
			type = "client",
			event = "radialmenu:client:setExtra",
			arg = 11,
			shouldClose = false
		},
		{
			id = "extra12",
			title = "Extra 12",
			icon = "box-open",
			type = "client",
			event = "radialmenu:client:setExtra",
			arg = 12,
			shouldClose = false
		},
		{
			id = "extra13",
			title = "Extra 13",
			icon = "box-open",
			type = "client",
			event = "radialmenu:client:setExtra",
			arg = 13,
			shouldClose = false
		}
	}
}

Config.VehicleSeats = {
	id = "vehicleseats",
	label = "Vehicle Seats",
	icon = "chair",
	menu = "vehicleseatsmenu"
}

Config.JobInteractions = {
	["ambulance"] = {
		-- {
		-- 	id = "deathcheck",
		-- 	title = "Check Death Cause",
		-- 	icon = "heart-pulse",
		-- 	type = "client",
		-- 	event = "deathcheck:client:checkNearestPlayer",
		-- 	shouldClose = true
		-- },
		{
			id = "revivep",
			title = "Revive",
			icon = "user-doctor",
			type = "client",
			event = "hospital:client:RevivePlayer",
			shouldClose = true
		},
		{
			id = "treatwounds",
			title = "Heal wounds",
			icon = "bandage",
			type = "client",
			event = "hospital:client:TreatWounds",
			shouldClose = true
		},
		{
			id = "stretcher",
			title = "Stretcher",
			icon = "bed",
			items = {
				{
					id = "spawnstretcher",
					title = "Spawn Stretcher",
					icon = "plus",
					type = "client",
					event = "qb-radialmenu:client:TakeStretcher",
					shouldClose = true
				},
				{
					id = "despawnstretcher",
					title = "Despawn Stretcher",
					icon = "minus",
					type = "client",
					event = "qb-radialmenu:client:RemoveStretcher",
					shouldClose = true
				}
			}
		},
		{
			id = "searchplayer",
			title = "Search",
			icon = "magnifying-glass",
			type = "client",
			event = "police:client:SearchPlayer",
			shouldClose = true
		}
	},
	["sksm"] = {
		{
			id = "searchplayer",
			title = "Search",
			icon = "magnifying-glass",
			type = "client",
			event = "police:client:SearchPlayer",
			shouldClose = true
		}
	},
	["rsroxwood"] = {
		{
			id = "treatwounds",
			title = "Heal wounds",
			icon = "bandage",
			type = "client",
			event = "hospital:client:TreatWounds",
			shouldClose = true
		},
		{
			id = "revivep",
			title = "Revive",
			icon = "user-doctor",
			type = "client",
			event = "hospital:client:RevivePlayer",
			shouldClose = true
		},
	},
	["puskesmas"] = {
		{
			id = "treatwounds",
			title = "Heal wounds",
			icon = "bandage",
			type = "client",
			event = "hospital:client:TreatWounds",
			shouldClose = true
		},
		{
			id = "revivep",
			title = "Revive",
			icon = "user-doctor",
			type = "client",
			event = "hospital:client:RevivePlayer",
			shouldClose = true
		},
	},
	["banmeskota"] = {
		{
			id = "revivep",
			title = "Revive",
			icon = "user-doctor",
			type = "client",
			event = "hospital:client:RevivePlayer",
			shouldClose = true
		},
	},
	["taxism"] = {
		{
			id = "togglemeter",
			title = "Taxi Ride with Customer",
			icon = "taxi",
			type = "client",
			event = "qb-taxi:startTaxiRide",
			shouldClose = false
		},
		{
			id = "togglemouse",
			title = "Start Argometer",
			icon = "taxi",
			type = "client",
			event = "qb-taxi:startmeter",
			shouldClose = true
		},
		{
			id = "pause_meter",
			title = "Pause Argometer",
			icon = "taxi",
			type = "client",
			event = "qb-taxi:pausemeter",
			shouldClose = true
		},
		{
			id = "reset_meter",
			title = "Reset Argometer",
			icon = "taxi",
			type = "client",
			event = "qb-taxi:resetmeter",
			shouldClose = true
		},
	},
	["tow"] = {
		{
			id = "togglenpc",
			title = "Toggle NPC",
			icon = "toggle-on",
			type = "client",
			event = "jobs:client:ToggleNpc",
			shouldClose = true
		},
		{
			id = "towvehicle",
			title = "Tow vehicle",
			icon = "truck-pickup",
			type = "client",
			event = "qb-tow:client:TowVehicle",
			shouldClose = true
		}
	},
	["mechanic"] = {
		{
			id = "unlockvehicle",
			title = "Buka Paksa Kendaraan",
			icon = "key",
			type = "client",
			event = "radialmenu:client:forceUnlockVehicle",
			shouldClose = true
		},
	},
	["maxspeedgarage"] = {
		{
			id = "unlockvehicle",
			title = "Buka Paksa Kendaraan",
			icon = "key",
			type = "client",
			event = "radialmenu:client:forceUnlockVehicle",
			shouldClose = true
		},
	},
	["mechanic969"] = {
		{
			id = "unlockvehicle",
			title = "Buka Paksa Kendaraan",
			icon = "key",
			type = "client",
			event = "radialmenu:client:forceUnlockVehicle",
			shouldClose = true
		},
	},
	["usmarshal"] = {
		{
			id = "usmsradio",
			title = "USMS Radio",
			icon = "walkie-talkie",
			items = {
				{
					id = "central_usms",
					title = "Central USMS",
					icon = "tower-broadcast",
					type = "client",
					event = "radialmenu:client:JoinRadio",
					arg = 8,
					shouldClose = true
				},
				{
					id = "tac1",
					title = "TAC 1",
					icon = "tower-broadcast",
					type = "client",
					event = "radialmenu:client:JoinRadio",
					arg = 8.1,
					shouldClose = true
				},
				{
					id = "tac2",
					title = "TAC 2",
					icon = "tower-broadcast",
					type = "client",
					event = "radialmenu:client:JoinRadio",
					arg = 8.2,
					shouldClose = true
				},
				{
					id = "tac3",
					title = "TAC 3",
					icon = "tower-broadcast",
					type = "client",
					event = "radialmenu:client:JoinRadio",
					arg = 8.3,
					shouldClose = true
				},
				{
					id = "tac4",
					title = "TAC 4",
					icon = "tower-broadcast",
					type = "client",
					event = "radialmenu:client:JoinRadio",
					arg = 8.4,
					shouldClose = true
				},
				{
					id = "tac5",
					title = "TAC 5",
					icon = "tower-broadcast",
					type = "client",
					event = "radialmenu:client:JoinRadio",
					arg = 8.5,
					shouldClose = true
				}
			}
		},
		{
			id = "unlockvehicle",
			title = "Buka Paksa Kendaraan",
			icon = "key",
			type = "client",
			event = "radialmenu:client:forceUnlockVehicle",
			shouldClose = true
		},
		{
			id = "fingerprint",
			title = "Check Fingerprint",
			icon = "list-check",
			type = "command",
			event = "fingerprint",
			shouldClose = true
		},
		{
			id = "jailplayer",
			title = "Jail",
			icon = "user-lock",
			type = "command",
			event = "jail",
			shouldClose = true
		},
		{
			id = "statuscheck",
			title = "GSR",
			icon = "list-check",
			type = "command",
			event = "gsrcheck",
			shouldClose = true
		},
	},
	["government"] = {
		{
			id = "govtradio",
			title = "Gov-Police Radio",
			icon = "walkie-talkie",
			items = {
				{
					id = "central_smsp",
					title = "Central SMSP",
					icon = "tower-broadcast",
					type = "client",
					event = "radialmenu:client:JoinRadio",
					arg = 1,
					shouldClose = true
				},
				{
					id = "central_lspd",
					title = "Central LSPD",
					icon = "tower-broadcast",
					type = "client",
					event = "radialmenu:client:JoinRadio",
					arg = 1.1,
					shouldClose = true
				},
				{
					id = "central_bcso",
					title = "Central BCSO",
					icon = "tower-broadcast",
					type = "client",
					event = "radialmenu:client:JoinRadio",
					arg = 1.2,
					shouldClose = true
				},
				{
					id = "tac1",
					title = "TAC 1",
					icon = "tower-broadcast",
					type = "client",
					event = "radialmenu:client:JoinRadio",
					arg = 3.1,
					shouldClose = true
				},
				{
					id = "tac2",
					title = "TAC 2",
					icon = "tower-broadcast",
					type = "client",
					event = "radialmenu:client:JoinRadio",
					arg = 3.2,
					shouldClose = true
				},
				{
					id = "tac3",
					title = "TAC 3",
					icon = "tower-broadcast",
					type = "client",
					event = "radialmenu:client:JoinRadio",
					arg = 3.3,
					shouldClose = true
				},
				{
					id = "tac4",
					title = "TAC 4",
					icon = "tower-broadcast",
					type = "client",
					event = "radialmenu:client:JoinRadio",
					arg = 3.4,
					shouldClose = true
				},
				{
					id = "tac5",
					title = "TAC 5",
					icon = "tower-broadcast",
					type = "client",
					event = "radialmenu:client:JoinRadio",
					arg = 3.5,
					shouldClose = true
				}
			}
		},
	},
	["police"] = {
		{
			id = "mdtopen",
			title = "MDT",
			icon = "tablet",
			type = "client",
			event = "radialmenu:client:openmdt",
			shouldClose = true
		},
		{
			id = "policeradio",
			title = "Police Radio",
			icon = "walkie-talkie",
			items = {
				{
					id = "central_smsp",
					title = "Central SMSP",
					icon = "tower-broadcast",
					type = "client",
					event = "radialmenu:client:JoinRadio",
					arg = 1,
					shouldClose = true
				},
				{
					id = "central_lspd",
					title = "Central LSPD",
					icon = "tower-broadcast",
					type = "client",
					event = "radialmenu:client:JoinRadio",
					arg = 1.1,
					shouldClose = true
				},
				{
					id = "central_bcso",
					title = "Central BCSO",
					icon = "tower-broadcast",
					type = "client",
					event = "radialmenu:client:JoinRadio",
					arg = 1.2,
					shouldClose = true
				},
				{
					id = "central_usms",
					title = "Central USMS",
					icon = "tower-broadcast",
					type = "client",
					event = "radialmenu:client:JoinRadio",
					arg = 8,
					shouldClose = true
				},
				{
					id = "central_ems",
					title = "Central EMS",
					icon = "tower-broadcast",
					type = "client",
					event = "radialmenu:client:JoinRadio",
					arg = 2,
					shouldClose = true
				},
				{
					id = "tac1",
					title = "TAC 1",
					icon = "tower-broadcast",
					type = "client",
					event = "radialmenu:client:JoinRadio",
					arg = 1.3,
					shouldClose = true
				},
				{
					id = "tac2",
					title = "TAC 2",
					icon = "tower-broadcast",
					type = "client",
					event = "radialmenu:client:JoinRadio",
					arg = 1.4,
					shouldClose = true
				},
				{
					id = "tac3",
					title = "TAC 3",
					icon = "tower-broadcast",
					type = "client",
					event = "radialmenu:client:JoinRadio",
					arg = 1.5,
					shouldClose = true
				},
				{
					id = "tac4",
					title = "TAC 4",
					icon = "tower-broadcast",
					type = "client",
					event = "radialmenu:client:JoinRadio",
					arg = 1.6,
					shouldClose = true
				},
				{
					id = "tac5",
					title = "TAC 5",
					icon = "tower-broadcast",
					type = "client",
					event = "radialmenu:client:JoinRadio",
					arg = 1.7,
					shouldClose = true
				},
				{
					id = "tac6",
					title = "TAC 6",
					icon = "tower-broadcast",
					type = "client",
					event = "radialmenu:client:JoinRadio",
					arg = 1.8,
					shouldClose = true
				},
				{
					id = "tac7",
					title = "TAC 7",
					icon = "tower-broadcast",
					type = "client",
					event = "radialmenu:client:JoinRadio",
					arg = 1.9,
					shouldClose = true
				},
				{
					id = "tac8",
					title = "TAC 8",
					icon = "tower-broadcast",
					type = "client",
					event = "radialmenu:client:JoinRadio",
					arg = 1.11,
					shouldClose = true
				},
				{
					id = "tac9",
					title = "TAC 9",
					icon = "tower-broadcast",
					type = "client",
					event = "radialmenu:client:JoinRadio",
					arg = 1.12,
					shouldClose = true
				},
				{
					id = "tac10",
					title = "TAC 10",
					icon = "tower-broadcast",
					type = "client",
					event = "radialmenu:client:JoinRadio",
					arg = 1.13,
					shouldClose = true
				}
			}
		},
		{
			id = "policeinteraction",
			title = "Police Actions",
			icon = "list-check",
			items = {
				{
					id = "unlockvehicle",
					title = "Buka Paksa Kendaraan",
					icon = "key",
					type = "client",
					event = "radialmenu:client:forceUnlockVehicle",
					shouldClose = true
				},
				{
					id = "statuscheck",
					title = "GSR",
					icon = "list-check",
					type = "command",
					event = "gsrcheck",
					shouldClose = true
				},
				{
					id = "policetools",
					title = "Tools",
					icon = "box-open",
					type = "command",
					event = "policetools",
					shouldClose = true
				},
				{
					id = "fingerprint",
					title = "Check Fingerprint",
					icon = "list-check",
					type = "command",
					event = "fingerprint",
					shouldClose = true
				},
				{
					id = "communityservice",
					title = "Hukuman Sosial",
					icon = "user-lock",
					type = "command",
					event = "cs",
					shouldClose = true
				},
				-- {
				-- 	id = "anklet",
				-- 	title = "Anklet",
				-- 	icon = "user-lock",
				-- 	type = "command",
				-- 	event = "anklet",
				-- 	shouldClose = true
				-- },
				{
					id = "escort",
					title = "Escort",
					icon = "user-group",
					type = "client",
					event = "police:client:EscortPlayer",
					shouldClose = true
				},
				{
					id = "searchplayer",
					title = "Search",
					icon = "magnifying-glass",
					type = "client",
					event = "police:client:SearchPlayer",
					shouldClose = true
				},
				{
					id = "jailplayer",
					title = "Jail",
					icon = "user-lock",
					type = "command",
					event = "jail",
					shouldClose = true
				},
			}
		},
	},
	["hotdog"] = {
		{
			id = "togglesell",
			title = "Toggle sell",
			icon = "hotdog",
			type = "client",
			event = "qb-hotdogjob:client:ToggleSell",
			shouldClose = true
		}
	}
}

Config.GangInteractions = {
	["lostmc"] = {
		{
			id = "playerinvehicle",
			title = "Put In Vehicle",
			icon = "car-side",
			type = "client",
			event = "police:client:PutPlayerInVehicle",
			shouldClose = true
		},
		{
			id = "playeroutvehicle",
			title = "Put Out Vehicle",
			icon = "car-side",
			type = "client",
			event = "police:client:SetPlayerOutVehicle",
			shouldClose = true
		},
		{
			id = "stealplayer",
			title = "Steal",
			icon = "mask",
			type = "client",
			event = "police:client:SearchPlayer",
			shouldClose = true
		},
		{
			id = "escort2",
			title = "Escort",
			icon = "user-group",
			type = "client",
			event = "police:client:EscortPlayer",
			shouldClose = true
		}
	}
}

Config.TrunkClasses = {
	[0] = {allowed = true, x = 0.0, y = -1.5, z = 0.0}, -- Coupes
	[1] = {allowed = true, x = 0.0, y = -2.0, z = 0.0}, -- Sedans
	[2] = {allowed = true, x = 0.0, y = -1.0, z = 0.25}, -- SUVs
	[3] = {allowed = true, x = 0.0, y = -1.5, z = 0.0}, -- Coupes
	[4] = {allowed = true, x = 0.0, y = -2.0, z = 0.0}, -- Muscle
	[5] = {allowed = true, x = 0.0, y = -2.0, z = 0.0}, -- Sports Classics
	[6] = {allowed = true, x = 0.0, y = -2.0, z = 0.0}, -- Sports
	[7] = {allowed = true, x = 0.0, y = -2.0, z = 0.0}, -- Super
	[8] = {allowed = false, x = 0.0, y = -1.0, z = 0.25}, -- Motorcycles
	[9] = {allowed = true, x = 0.0, y = -1.0, z = 0.25}, -- Off-road
	[10] = {allowed = true, x = 0.0, y = -1.0, z = 0.25}, -- Industrial
	[11] = {allowed = true, x = 0.0, y = -1.0, z = 0.25}, -- Utility
	[12] = {allowed = true, x = 0.0, y = -1.0, z = 0.25}, -- Vans
	[13] = {allowed = true, x = 0.0, y = -1.0, z = 0.25}, -- Cycles
	[14] = {allowed = true, x = 0.0, y = -1.0, z = 0.25}, -- Boats
	[15] = {allowed = true, x = 0.0, y = -1.0, z = 0.25}, -- Helicopters
	[16] = {allowed = true, x = 0.0, y = -1.0, z = 0.25}, -- Planes
	[17] = {allowed = true, x = 0.0, y = -1.0, z = 0.25}, -- Service
	[18] = {allowed = true, x = 0.0, y = -1.0, z = 0.25}, -- Emergency
	[19] = {allowed = true, x = 0.0, y = -1.0, z = 0.25}, -- Military
	[20] = {allowed = true, x = 0.0, y = -1.0, z = 0.25}, -- Commercial
	[21] = {allowed = true, x = 0.0, y = -1.0, z = 0.25} -- Trains
}

Config.Commands = {
	["top"] = {
		Func = function()
			ToggleClothing({"Top"})
		end,
		Sprite = "top",
		Desc = "Take your shirt off/on",
		Button = 1,
		Name = "Torso"
	},
	["gloves"] = {
		Func = function()
			ToggleClothing({"Gloves"})
		end,
		Sprite = "gloves",
		Desc = "Take your gloves off/on",
		Button = 2,
		Name = "Gloves"
	},
	["visor"] = {
		Func = function()
			ToggleProps({"Visor"})
		end,
		Sprite = "visor",
		Desc = "Toggle hat variation",
		Button = 3,
		Name = "Visor"
	},
	["bag"] = {
		Func = function()
			ToggleClothing({"Bag"})
		end,
		Sprite = "bag",
		Desc = "Opens or closes your bag",
		Button = 8,
		Name = "Bag"
	},
	["shoes"] = {
		Func = function()
			ToggleClothing({"Shoes"})
		end,
		Sprite = "shoes",
		Desc = "Take your shoes off/on",
		Button = 5,
		Name = "Shoes"
	},
	["vest"] = {
		Func = function()
			ToggleClothing({"Vest"})
		end,
		Sprite = "vest",
		Desc = "Take your vest off/on",
		Button = 14,
		Name = "Vest"
	},
	["hair"] = {
		Func = function()
			ToggleClothing({"Hair"})
		end,
		Sprite = "hair",
		Desc = "Put your hair up/down/in a bun/ponytail.",
		Button = 7,
		Name = "Hair"
	},
	["hat"] = {
		Func = function()
			ToggleProps({"Hat"})
		end,
		Sprite = "hat",
		Desc = "Take your hat off/on",
		Button = 4,
		Name = "Hat"
	},
	["glasses"] = {
		Func = function()
			ToggleProps({"Glasses"})
		end,
		Sprite = "glasses",
		Desc = "Take your glasses off/on",
		Button = 9,
		Name = "Glasses"
	},
	["ear"] = {
		Func = function()
			ToggleProps({"Ear"})
		end,
		Sprite = "ear",
		Desc = "Take your ear accessory off/on",
		Button = 10,
		Name = "Ear"
	},
	["neck"] = {
		Func = function()
			ToggleClothing({"Neck"})
		end,
		Sprite = "neck",
		Desc = "Take your neck accessory off/on",
		Button = 11,
		Name = "Neck"
	},
	["watch"] = {
		Func = function()
			ToggleProps({"Watch"})
		end,
		Sprite = "watch",
		Desc = "Take your watch off/on",
		Button = 12,
		Name = "Watch",
		Rotation = 5.0
	},
	["bracelet"] = {
		Func = function()
			ToggleProps({"Bracelet"})
		end,
		Sprite = "bracelet",
		Desc = "Take your bracelet off/on",
		Button = 13,
		Name = "Bracelet"
	},
	["mask"] = {
		Func = function()
			ToggleClothing({"Mask"})
		end,
		Sprite = "mask",
		Desc = "Take your mask off/on",
		Button = 6,
		Name = "Mask"
	}
}

local bags = {[40] = true, [41] = true, [44] = true, [45] = true}

Config.ExtraCommands = {
	["pants"] = {
		Func = function()
			ToggleClothing({"Pants", true})
		end,
		Sprite = "pants",
		Desc = "Take your pants off/on",
		Name = "Pants",
		OffsetX = -0.04,
		OffsetY = 0.0
	},
	["shirt"] = {
		Func = function()
			ToggleClothing({"Shirt", true})
		end,
		Sprite = "shirt",
		Desc = "Take your shirt off/on",
		Name = "shirt",
		OffsetX = 0.04,
		OffsetY = 0.0
	},
	["reset"] = {
		Func = function()
			if not ResetClothing(true) then
				Notify("Nothing To Reset", "error")
			end
		end,
		Sprite = "reset",
		Desc = "Revert everything back to normal",
		Name = "reset",
		OffsetX = 0.12,
		OffsetY = 0.2,
		Rotate = true
	},
	["bagoff"] = {
		Func = function()
			ToggleClothing({"Bagoff", true})
		end,
		Sprite = "bagoff",
		SpriteFunc = function()
			local Bag = GetPedDrawableVariation(cache.ped, 5)
			local BagOff = LastEquipped["Bagoff"]
			if LastEquipped["Bagoff"] then
				if bags[BagOff.Drawable] then
					return "bagoff"
				else
					return "paraoff"
				end
			end
			if Bag ~= 0 then
				if bags[Bag] then
					return "bagoff"
				else
					return "paraoff"
				end
			else
				return false
			end
		end,
		Desc = "Take your bag off/on",
		Name = "bagoff",
		OffsetX = -0.12,
		OffsetY = 0.2
	}
}