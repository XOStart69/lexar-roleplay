return {
    jobs = {
        mercenarysm = 0,
        admin = 0,
    },

    pickupAnyJobs = {
        admin = true,
    },

    items = {
        shield = 'WEAPON_KFTHROWSHIELD',
        drone = 'kf_tactical_drone_shield',
        tablet = 'kf_tactical_drone_tablet',
    },

    weaponHash = `WEAPON_KFTHROWSHIELD`,

    defaultShield = 'Police',
    defaultDrone = 'Regular',

    shield = {
        maxPerPlayer = 3,
        maxTotal = 30,
        placeDistance = 10.0,
        throwDistance = 45.0,
        pickupDistance = 3.5,
        viewDistance = 200.0,
        deployMinMs = 400,
        deployMaxMs = 10000,
        droneDeployMaxMs = 15000,
        throwWindowMs = 8000,
        claimWindowMs = 20000,
        consumeWaitMs = 2000,
    },

    drone = {
        maxPerPlayer = 1,
        placeDistance = 10.0,
        tabletRange = 20.0,
        controlRange = 60.0,
        battery = 600,
        lifetime = 1800,
        shots = 4,
        gunWeapon = `WEAPON_STUNGUN`,
        maxSpeed = 9.0,
        reverseSpeed = 4.0,
        turnRate = 90.0,
        acceleration = 3.0,
        cameraOffset = vec3(0.0, 0.58188, 0.101411),
        cameraFov = 60.0,
        tablet = {
            dict = 'anim@arena@amb@seat_drone_tablet@male@',
            clip = 'base',
            prop = `xs_prop_arena_tablet_drone_01`,
            bone = 28422,
        },
    },

    keys = {
        place = 'H',
        deploy = 'E',
        exit = 'X',
        night = 'N',
        thermal = 'B',
    },

    shieldVariants = {
        ['Regular'] = { anime = 'konf_throw_shield_regular_anime', deployed = 'konf_throw_shield_regular_deployed' },
        ['Regular MK2'] = { anime = 'konf_throw_shield_regular_anime_mk2', deployed = 'konf_throw_shield_regular_deployed_mk2' },
        ['Police'] = { anime = 'konf_throw_shield_police_1_anime', deployed = 'konf_throw_shield_police_1_deployed' },
        ['Police MK2'] = { anime = 'konf_throw_shield_police_2_anime', deployed = 'konf_throw_shield_police_2_deployed' },
        ['FIB'] = { anime = 'konf_throw_shield_fib_1_anime', deployed = 'konf_throw_shield_fib_1_deployed' },
        ['FIB MK2'] = { anime = 'konf_throw_shield_fib_2_anime', deployed = 'konf_throw_shield_fib_2_deployed' },
        ['Sheriff'] = { anime = 'konf_throw_shield_sheriff_1_anime', deployed = 'konf_throw_shield_sheriff_1_deployed' },
        ['Sheriff MK2'] = { anime = 'konf_throw_shield_sheriff_2_anime', deployed = 'konf_throw_shield_sheriff_2_deployed' },
        ['EMS'] = { anime = 'konf_throw_shield_ems_1_anime', deployed = 'konf_throw_shield_ems_1_deployed' },
        ['EMS MK2'] = { anime = 'konf_throw_shield_ems_2_anime', deployed = 'konf_throw_shield_ems_2_deployed' },
    },

    droneVariants = {
        ['Regular'] = { anime = 'kf_tactical_drone_shield_anime', deployed = 'kf_tactical_drone_shield_deployed', vehicle = 'kf_tactical_drone_shield' },
        ['FIB'] = { anime = 'kf_tactical_drone_shield_fib_anime', deployed = 'kf_tactical_drone_shield_fib_deployed', vehicle = 'kf_tactical_drone_shield_fib' },
        ['Sheriff'] = { anime = 'kf_tactical_drone_shield_sheriff_anime', deployed = 'kf_tactical_drone_shield_sheriff_deployed', vehicle = 'kf_tactical_drone_shield_sheriff' },
    },

    text = {
        title = 'Tactical Shield',
        notAllowed = 'Hanya job tertentu yang bisa memakai ini',
        noItem = 'Item tidak ditemukan di inventory',
        notVerified = 'Lemparan shield tidak terverifikasi',
        limitTotal = 'Terlalu banyak shield aktif di server, coba lagi nanti',
        limitDrone = 'Drone kamu masih aktif, ambil dulu',
        inventoryFull = 'Inventory penuh',
        tooFar = 'Terlalu jauh',
        failed = 'Gagal memasang',
        placeBusy = 'Sedang memasang',
        placeInvalid = 'Tidak bisa dipasang di sini',
        placeUnavailable = 'Tidak bisa memasang sekarang',
        placeCancelled = 'Pemasangan dibatalkan',
        placeHint = '[kbd]E[/kbd] Pasang\n[kbd]X[/kbd] Batal\n[kbd]←[/kbd][kbd]→[/kbd] Putar\n[kbd]↑[/kbd][kbd]↓[/kbd] Tinggi\n[kbd]G[/kbd] Tempel ke tanah',
        noDrone = 'Tidak ada drone kamu di dekat sini',
        droneDepleted = 'Baterai drone habis',
        droneLost = 'Sinyal drone hilang',
        droneDestroyed = 'Drone hancur',
        pickupShield = 'Ambil shield',
        controlDrone = 'Kendalikan drone',
        returnDrone = 'Ambil drone',
        placeKey = 'Shield: pasang manual',
    },
}
