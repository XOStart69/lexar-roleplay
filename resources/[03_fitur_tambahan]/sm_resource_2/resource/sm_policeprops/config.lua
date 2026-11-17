return {
    syncRadius = 50.0,
    streamInterval = 1500,
    placeRadius = 15.0,
    pickupRadius = 8.0,

    groups = {
        police = {
            jobs = { police = 0, usmarshal = 0, sasp = 0, bcso = 0 },
            requireDuty = true,
            maxPerPlayer = 3,
            cooldown = 3000,
            noAccess = 'Hanya polisi on duty yang bisa memakai ini.',
        },
        media = {
            jobs = { reporter = 0 },
            requireDuty = false,
            maxPerPlayer = 4,
            cooldown = 2000,
            noAccess = 'Hanya Satu Media yang bisa memasang lampu ini.',
        },
    },

    objects = {
        cone = { group = 'police', model = `prop_roadcone02a`, label = 'Traffic Cone', icon = 'road', freeze = false },
        barrier = { group = 'police', model = `prop_barrier_work06a`, label = 'Road Barrier', icon = 'road-barrier', freeze = true },
        roadsign = { group = 'police', model = `prop_snow_sign_road_06g`, label = 'Road Sign', icon = 'triangle-exclamation', freeze = true },
        tent = { group = 'police', model = `prop_gazebo_03`, label = 'Command Tent', icon = 'tent', freeze = true },
        light = { group = 'police', model = `prop_worklight_03b`, label = 'Work Light', icon = 'lightbulb', freeze = true },

        worklight_04d = { group = 'media', item = true, model = `prop_worklight_04d`, label = 'Work Light Standard', freeze = true },
        worklight_02a = { group = 'media', item = true, model = `prop_worklight_02a`, label = 'Work Light Compact', freeze = true },
        worklight_04b = { group = 'media', item = true, model = `prop_worklight_03b`, label = 'Work Light Tall', freeze = true },
        worklight_04d_l1 = { group = 'media', item = true, model = `prop_worklight_04d`, label = 'Work Light Bright', freeze = true },
        worklight_tripod_a = { group = 'media', item = true, model = `xm_prop_base_tripod_lampa`, label = 'Tripod Lamp A', freeze = true },
        worklight_tripod_b = { group = 'media', item = true, model = `xm_prop_base_tripod_lampb`, label = 'Tripod Lamp B', freeze = true },
        worklight_tower_a = { group = 'media', item = true, model = `xm_prop_base_tower_lampa`, label = 'Tower Lamp', freeze = true },
    },

    spike = {
        group = 'police',
        item = 'spikestrip',
        model = `P_ld_stinger_s`,
        label = 'Spike Strip',
        maxPerPlayer = 20,
        lifetime = 300000,
        placeDuration = 1500,
        placeForward = 1.5,
        length = 9.0,
        width = 1.5,
        zoneRadius = 20.0,
        burstCooldown = 2000,
    },

    anim = { dict = 'anim@narcotics@trash', clip = 'drop_front' },
    placeDuration = 2000,
    pickupDuration = 2500,

    gizmo = {
        rayDistance = 10.0,
        verticalSpeed = 0.01,
        rotateSpeed = 2.0,
        maxTilt = 90.0,
    },
}
