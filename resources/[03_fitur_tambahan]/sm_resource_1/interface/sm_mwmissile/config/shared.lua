return {
    command = 'mwmissile',

    job = {
        name = 'mercenarysm',
        minGrade = 0,
        requireDuty = false,
    },

    cooldown = 30,
    maxActive = 3,
    connectDuration = 3000,

    missile = {
        model = `w_ex_vehiclemissile_4`,
        label = 'MW-04 Guided Missile',
        spawnHeight = 100.0,
        spawnForward = 0.0,
        startPitch = -15.0,

        speed = 55.0,
        boostSpeed = 110.0,
        acceleration = 60.0,
        fuel = 100.0,
        boostConsumption = 20.0,
        boostFlameScale = 1.8,

        turnRate = 70.0,
        mouseSensitivity = 9.0,
        minPitch = -89.0,
        maxPitch = 45.0,
        maxRoll = 25.0,

        maxFlightTime = 90,
        armDelay = 1000,

        camOffset = vec3(0.0, -4.5, 1.6),
        camFov = 80.0,

        explosionType = 81,
        damageScale = 5.0,
        cameraShake = 1.5,

        cullingRadius = 1500.0,
    },

    launchSound = {
        enabled = true,
        volume = 0.1,
        hearDistance = 250.0,
    },

    signal = {
        weakDistance = 700.0,
        maxDistance = 1000.0,
        lostScreenTime = 1500,
    },

    particles = {
        { asset = 'veh_xs_vehicle_mods', name = 'veh_nitrous', offset = vec3(0.0, -1.2, 0.0), rotation = vec3(0.0, 0.0, 0.0), scale = 1.6 },
    },

    boostParticles = {
        { asset = 'scr_ar_planes', name = 'scr_ar_trail_smoke', offset = vec3(0.0, -1.6, 0.0), rotation = vec3(0.0, 0.0, 0.0), scale = 0.35, alpha = 0.45 },
    },

    tablet = {
        dict = 'amb@code_human_in_bus_passenger_idles@female@tablet@idle_a',
        clip = 'idle_a',
        prop = `prop_cs_tablet`,
        bone = 28422,
        offset = vec3(0.0, -0.03, 0.0),
        rotation = vec3(20.0, -90.0, 0.0),
    },

    keys = {
        detonate = 'E',
        boost = 'B',
        vision = 'CAPITAL',
    },

    text = {
        commandHelp = 'Kendalikan missile dari tablet (mercenarysm)',
        notAllowed = 'Kamu tidak punya akses ke kendali missile',
        notOnDuty = 'Kamu harus on duty',
        cooldown = 'Sistem missile masih cooldown %d detik',
        busy = 'Kamu sedang mengendalikan missile',
        limit = 'Terlalu banyak missile di udara, coba lagi nanti',
        inVehicle = 'Tidak bisa dipakai di dalam kendaraan',
        isDead = 'Tidak bisa dipakai saat pingsan',
        inWater = 'Tidak bisa dipakai di dalam air',
        cancelled = 'Peluncuran dibatalkan',
        failed = 'Gagal meluncurkan missile',
        connecting = 'Menghubungkan ke missile...',
        signalLost = 'Sinyal missile hilang',
    },
}
