return {
    bucketBase = 400000,
    duration = 2700,
    passout = {
        enabled = true,
        anim = { dict = 'anim@scripted@data_leak@fix_bil_ig2_chopper_crawl@', clip = 'fix_bil_ig2_chopper_crawl_dead_loop_ped' },
        getup = { dict = 'get_up@sat_on_floor@to_stand', clip = 'getup_0', duration = 2000 },
        step = 6.0,
        decay = 10.0,
        maxMs = 90000,
    },

    graceMs = 6000,
    catchDistance = 2.0,
    sightRange = 25.0,
    hearRange = 6.0,
    loseRange = 45.0,
    loseMs = 15000,
    stuckMs = 2500,
    teleportMinDistance = 6.0,
    heartbeatRange = 18.0,

    flash = {
        range = 18.0,
        cone = 0.85,
        durationMs = 1200,
        stunMs = 5000,
        brightness = 25.0,
        radius = 30.0,
        color = { 255, 244, 214 },
        stunAnim = { dict = 'stungun@standing', clip = 'damage' },
    },
    wanderRadius = 15.0,
    monsterWalk = 'anim_group_move_ballistic',
    catchAnim = { dict = 'zombies_animations', clip = 'scream', duration = 1800 },
    catchCam = { gap = 0.8, fovFrom = 60.0, fovTo = 40.0, shake = 2.4, aim = 0.05 },

    exitDistance = 2.0,
    exitMarker = true,
    exitMarkerRange = 60.0,
    exitMarkerType = 42,
    exitMarkerZOffset = 0.0,

    levels = {
        {
            label = 'Level 0 - The Lobby',
            timecycle = 'gam_pris_hall',
            timecycleStrength = 0.85,
            spawn = vec4(331.002197, 5506.404297, 14.502563, 337.322845),
            exits = {
                vec4(372.5529, 5542.6138, 14.5109, 331.2051),
            },
            monsters = {
                { model = 'QS_096', coords = vec4(312.1552, 5526.5352, 14.5109, 65.0075), speed = 3.0, rate = 2.0 },
                { model = 'QS_bacteria', coords = vec4(355.0354, 5529.9766, 14.5109, 61.8396), speed = 3.0, rate = 2.0 },
            },
        },
        {
            label = 'Level 1 - Habitable Zone',
            timecycle = 'CAMERA_securitycam',
            timecycleStrength = 0.92,
            spawn = vec4(1026.88, 801.66, 25.88, 90.0),
            exits = {
                vec4(1014.4791, 800.0274, 25.9230, 241.5605),
            },
            monsters = {
                { model = 'QS_173', coords = vec4(1023.9945, 798.0373, 25.9230, 57.5894), speed = 3.0, rate = 2.0 },
            },
        },
        {
            label = 'Level 2 - Pipe Dreams',
            timecycle = 'int_carrier_hanger',
            timecycleStrength = 1.0,
            spawn = vec4(1780.18, -274.04, 20.66, 237.93),
            exits = {
                vec4(1779.1078, -260.8062, 20.8649, 65.0495),
            },
            monsters = {
                { model = 'QS_ATC', coords = vec4(1773.2604, -287.6272, 20.8649, 250.3472), speed = 3.0, rate = 2.0 },
                { model = 'QS_173', coords = vec4(1792.5421, -303.2031, 20.8649, 195.9791), speed = 3.0, rate = 2.0 },
            },
        },
        {
            label = 'Level 3 - Electrical Station',
            timecycle = 'ex_dlc_casino_apartment_sec_cam',
            timecycleStrength = 1.0,
            spawn = vec4(-2289.3804, 1433.7816, 81.9163, 87.0136),
            exits = {
                vec4(-2302.7952, 1420.1538, 81.9164, 90.6453),
            },
            monsters = {
                { model = 'hantu_01', coords = vec4(-2291.5381, 1426.1204, 81.9163, 92.7961), speed = 3.0, rate = 2.0 },
                { model = 'hantu_02', coords = vec4(-2289.7539, 1445.1384, 81.9163, 295.0953), speed = 3.0, rate = 2.0 },
            },
        },
        {
            label = 'Level X - The Sublevel',
            timecycle = 'int_carrier_hanger',
            timecycleStrength = 1.0,
            spawn = vec4(-162.052734, -1243.041748, -51.481323, 277.795288),
            exits = {
                vec4(-185.3122, -1255.9651, -51.4652, 266.8443),
            },
            monsters = {
                { model = 'QS_096', coords = vec4(-156.8426, -1182.9292, -51.4652, 86.5106), speed = 3.0, rate = 2.0 },
                { model = 'QS_bacteria', coords = vec4(-185.9877, -1242.2635, -51.4652, 359.1385), speed = 3.0, rate = 2.0 },
                { model = 'QS_ATC', coords = vec4(-189.1037, -1194.2731, -51.4652, 213.7824), speed = 3.0, rate = 2.0 },
                { model = 'QS_173', coords = vec4(-181.9761, -1276.0338, -51.4652, 59.1082), speed = 3.0, rate = 2.0 },
                { model = 'hantu_01', coords = vec4(-161.9012, -1251.2518, -51.4652, 257.5710), speed = 3.0, rate = 2.0 },
                { model = 'hantu_02', coords = vec4(-109.9236, -1259.3345, -51.4652, 263.3652), speed = 3.0, rate = 2.0 },
            },
        },
    },
}
