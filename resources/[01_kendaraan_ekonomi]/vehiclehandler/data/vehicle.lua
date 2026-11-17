return {
    units = 'kmh' ,             -- (mph, kmh)
    breaktire = false,           -- Enable/Disable breaking off vehicle wheel on impact
    threshold = {
        soft   = 15.0,
        health = 75.0,          -- Health difference needed to break off wheel (LastHealth - CurrentHealth) - INCREASED from 50
        speed  = 70.0,          -- Speed difference needed to break off wheel (LastSpeed - CurrentSpeed) - INCREASED from 50
        heavy  = 120.0,         -- Speed difference needed to disable vehicle instantly (LastSpeed - CurrentSpeed) - INCREASED from 90
    },
    globalmultiplier = 5.0,     -- Base damage multiplier for all vehicles (DECREASED from 20.0 for less damage)
    classmultiplier = {         -- Add-on damage multiplier for vehicle classes
        [0] =   0.6,            -- 0: Compacts - REDUCED for less damage
                0.6,            -- 1: Sedans - REDUCED
                0.6,	        -- 2: SUVs - REDUCED
                0.5,	        -- 3: Coupes - REDUCED
                0.6,	        -- 4: Muscle - REDUCED
                0.5,            -- 5: Sports Classics - REDUCED
                0.5,	        -- 6: Sports - REDUCED
                0.5,	        -- 7: Super - REDUCED
                0.3,	        -- 8: Motorcycles - REDUCED
                0.4,	        -- 9: Off-road - REDUCED
                0.25,	        -- 10: Industrial - REDUCED
                0.3,	        -- 11: Utility - REDUCED
                0.5,	        -- 12: Vans - REDUCED
                0.6,	        -- 13: Bicycles
                0.7,	        -- 14: Boats - REDUCED
                0.8,	        -- 15: Helicopters - REDUCED
                0.4,	        -- 16: Planes - REDUCED
                0.45,	        -- 17: Service - REDUCED
                0.3,	        -- 18: Emergency - REDUCED
                0.25,	        -- 19: Military - REDUCED
                0.35,	        -- 20: Commercial - REDUCED
                0.15,	        -- 21: Trains - REDUCED
                0.6,	        -- 22: Open Wheel - REDUCED
    },
    regulated = {               -- Prevent controls for vehicle class while flipped/airborne
        [0] =   true,           -- 0: Compacts
                true,           -- 1: Sedans
                true,           -- 2: SUVs
                true,           -- 3: Coupes
                true,           -- 4: Muscle
                true,           -- 5: Sports Classics
                true,           -- 6: Sports
                true,           -- 7: Super
                false,          -- 8: Motorcycles
                true,           -- 9: Off-road
                true,           -- 10: Industrial
                true,           -- 11: Utility
                true,           -- 12: Vans
                false,          -- 13: Bicycles
                false,          -- 14: Boats
                false,          -- 15: Helicopters
                false,          -- 16: Planes
                true,           -- 17: Service
                true,           -- 18: Emergency
                false,          -- 19: Military
                true,           -- 20: Commercial
                false,          -- 21: Trains
                true,           -- 22: Open Wheel
    },
    backengine = {
        [`ninef`] = true,
        [`adder`] = true,
        [`vagner`] = true,
        [`t20`] = true,
        [`infernus`] = true,
        [`zentorno`] = true,
        [`reaper`] = true,
        [`comet2`] = true,
        [`jester`] = true,
        [`jester2`] = true,
        [`cheetah`] = true,
        [`cheetah2`] = true,
        [`prototipo`] = true,
        [`turismor`] = true,
        [`pfister811`] = true,
        [`ardent`] = true,
        [`nero`] = true,
        [`nero2`] = true,
        [`tempesta`] = true,
        [`vacca`] = true,
        [`bullet`] = true,
        [`osiris`] = true,
        [`entityxf`] = true,
        [`turismo2`] = true,
        [`fmj`] = true,
        [`re7b`] = true,
        [`tyrus`] = true,
        [`italigtb`] = true,
        [`penetrator`] = true,
        [`monroe`] = true,
        [`ninef2`] = true,
        [`stingergt`] = true,
        [`surfer`] = true,
        [`surfer2`] = true,
        [`comet3`] = true,
    }
}