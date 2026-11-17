return {
	-- 0	vehicle has no storage
	-- 1	vehicle has no trunk storage
	-- 2	vehicle has no glovebox storage
	-- 3	vehicle has trunk in the hood
	Storage = {
		[`jester`] = 3,
		[`adder`] = 3,
		[`osiris`] = 1,
		[`pfister811`] = 1,
		[`penetrator`] = 1,
		[`autarch`] = 1,
		[`bullet`] = 1,
		[`cheetah`] = 1,
		[`cyclone`] = 1,
		[`voltic`] = 1,
		[`reaper`] = 3,
		[`entityxf`] = 1,
		[`t20`] = 1,
		[`taipan`] = 1,
		[`tezeract`] = 1,
		[`torero`] = 3,
		[`turismor`] = 1,
		[`fmj`] = 1,
		[`infernus`] = 1,
		[`italigtb`] = 3,
		[`italigtb2`] = 3,
		[`nero2`] = 1,
		[`vacca`] = 3,
		[`vagner`] = 1,
		[`visione`] = 1,
		[`prototipo`] = 1,
		[`zentorno`] = 1,
		[`trophytruck`] = 0,
		[`trophytruck2`] = 0,
		-- [`vv2`] = 1,
		-- [`vv3`] = 1,
	},

	-- slots, maxWeight; default weight is 8000 per slot
	glovebox = {
		[0] = {11, 88000},		-- Compact
		[1] = {11, 88000},		-- Sedan
		[2] = {11, 88000},		-- SUV
		[3] = {11, 88000},		-- Coupe
		[4] = {11, 88000},		-- Muscle
		[5] = {11, 88000},		-- Sports Classic
		[6] = {11, 88000},		-- Sports
		[7] = {11, 88000},		-- Super
		[8] = {5, 40000},		-- Motorcycle
		[9] = {11, 88000},		-- Offroad
		[10] = {11, 88000},		-- Industrial
		[11] = {11, 88000},		-- Utility
		[12] = {11, 88000},		-- Van
		[14] = {31, 248000},	-- Boat
		[15] = {31, 248000},	-- Helicopter
		[16] = {51, 408000},	-- Plane
		[17] = {11, 88000},		-- Service
		[18] = {11, 88000},		-- Emergency
		[19] = {11, 88000},		-- Military
		[20] = {11, 88000},		-- Commercial (trucks)
		models = {
			[`xa21`] = {11, 88000},
			[`smp911t`] = {150, 600000},
			[`ikx3_mcs22`] = {150, 600000},
			[`amgone`] = {150, 600000},
			[`smsennas`] = {150, 600000},
			[`smfd`] = {150, 88000},
			[`trophytruck`] = {150, 600000},
			[`smgrgt`] = {150, 600000},
			[`smn74sx`] = {150, 600000},
			[`sma80asalem`] = {150, 450000},
			[`smz4alch`] = {150, 450000},
			[`smmage`] = {150, 500000},
			[`smrcf`] = {150, 450000},
			[`smmcq`] = {150, 600000},
			[`mr2`] = {150, 300000},
			[`yumi`] = {150, 300000},
			[`dinghy4`] = {150, 1000000},
			[`vanzgt05`] = {150, 1000000},
		}
	},

	trunk = {
		[0] = {21, 168000},		-- Compact
		[1] = {41, 328000},		-- Sedan
		[2] = {51, 408000},		-- SUV
		[3] = {31, 248000},		-- Coupe
		[4] = {41, 328000},		-- Muscle
		[5] = {31, 248000},		-- Sports Classic
		[6] = {31, 248000},		-- Sports
		[7] = {21, 168000},		-- Super
		[8] = {5, 40000},		-- Motorcycle
		[9] = {51, 408000},		-- Offroad
		[10] = {51, 408000},	-- Industrial
		[11] = {41, 328000},	-- Utility
		[12] = {61, 488000},	-- Van
		-- [14] -- Boat
		-- [15] -- Helicopter
		-- [16] -- Plane
		[17] = {41, 328000},	-- Service
		[18] = {41, 328000},	-- Emergency
		[19] = {41, 328000},	-- Military
		[20] = {61, 488000},	-- Commercial
		models = {
			[`xa21`] = {11, 10000},
			[`mulet`] = {100, 20000000},
			[`smw906`] = {100, 20000000},
			[`hilux1`] = {50, 500000},
			[`zstlegender`] = {50, 1000000},
			[`vv1`] = {50, 800000},
			[`smcruis`] = {50, 1000000},
			[`zstbra6x6dar`] = {50, 1000000},
			[`smpm25`] = {50, 1000000},
			[`smrapt`] = {50, 1500000},
			[`sminv`] = {50, 1000000},
			[`smion`] = {50, 1000000},
			[`rculi`] = {50, 1000000},
			[`smg09`] = {50, 1000000},
			[`smlexrx`] = {50, 1000000},
			[`smpalis26`] = {50, 1000000},
			[`smrav4`] = {50, 1000000},
			[`smzen`] = {50, 1000000},
			[`smq8`] = {50, 1000000},
			[`smbentr`] = {50, 1000000},
			[`smxx`] = {50, 1000000},
			[`smtrhawk`] = {50, 1000000},
			[`smxpick`] = {50, 1000000},
			[`sms330i`] = {50, 1000000},
			[`wildtrak`] = {50, 500000},
			[`zstationinv`] = {50, 500000},
			[`nissantitan17`] = {50, 5000000},
			[`smm3tur`] = {50, 500000},
			[`smm5g`] = {50, 500000},
			[`elsapek`] = {50, 500000},
			[`x6mf16`] = {50, 500000},
			[`smfj `] = {50, 500000},
			[`navfit`] = {50, 400000},
			[`mansoryg63`] = {50, 1000000},
			[`smtun`] = {50, 1000000},
			[`pajero19`] = {50, 1000000},
			[`smalp`] = {50, 1000000},
			[`smlx18`] = {50, 1000000},
			[`smrubix`] = {50, 1000000},
			[`smx6`] = {50, 800000},
			[`pemboxcar`] = {50, 5000000},
			[`smtaco`] = {50, 1000000},
			[`smrovevo`] = {50, 1000000},
			[`smferpur`] = {50, 1000000},
			[`smrune`] = {50, 1000000},
			[`smiyescalade`] = {50, 1000000},
			[`zstrover6x6seha`] = {50, 1000000},
			[`sm_nispatrol`] = {50, 1000000},
			[`sm_pbhammer`] = {50, 1000000},
			[`ygm`] = {50, 1000000},
			[`c63v`] = {50, 1000000},
			[`txl`] = {50, 1000000},
			[`sm_gle63`] = {50, 1000000},
			[`smtycancr`] = {50, 1000000},
			[`smdodramtrx`] = {50, 1000000},
			[`smglsp850`] = {50, 1000000},
			[`23sprintl4`] = {50, 20000000},
		},
	}
}
