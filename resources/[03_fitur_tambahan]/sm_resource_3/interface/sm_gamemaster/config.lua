return {
    ace = 'command.gamemaster',
    command = 'gamemaster',

    camera = {
        startAltitude = 10.0,
        moveSpeed = 10.0,
        sprintMultiplier = 5.0,
        heightFactor = 40.0,
        zoomStep = 5.0,
        rotateSpeed = 90.0,
        mouseSensitivity = 200.0,
        scrollSmoothing = 5.0,
        blendInMs = 300,
        travelMs = 1850,
        blendOutMs = 400,
        minPitch = -89.0,
        maxPitch = -5.0,
    },

    exitTeleport = 'entry',
    requireAlive = true,
    selectRadius = 300.0,
    doubleClickMs = 300,

    spawn = {
        maxEntities = 25,
        perSecond = 4,
        maxDistance = 650.0,
        previewAlpha = 120,
    },

    ped = {
        allyGroup = 'SM_GM_ALLY',
        hearingRange = 28.0,
        reapplyCount = 8,
    },

    speeds = {
        ped = { walk = 1.5, run = 3.0 },
        vehicle = { walk = 10.0, run = 22.0 },
    },

    attackAreaMs = 60000,
    attackRange = { min = 10, max = 100, default = 25 },

    objects = {
        streamRadius = 120.0,
        maxStored = 50,
        perSecond = 2,
        syncBps = 64000,
    },

    lightningRadius = 450.0,

    lightningBolt = {
        height = 160.0,
        segments = 14,
        jitter = 8.0,
        branches = 4,
        branchSegments = 5,
        width = 0.4,
        haloWidth = 1.6,
        minScreenWidth = 0.004,
        durationMs = 520,
        maxActive = 4,
        color = { 215, 230, 255 },
        light = { range = 70.0, intensity = 45.0 },
        impact = { asset = 'core', name = 'ent_sht_electrical_box', scale = 4.0 },
        shake = { name = 'SMALL_EXPLOSION_SHAKE', distance = 80.0, amount = 0.35 },
    },

    explosions = {
        { type = 0, label = 'Granat' },
        { type = 2, label = 'Bom Lengket' },
        { type = 3, label = 'Molotov' },
        { type = 4, label = 'Roket' },
        { type = 6, label = 'Hi-Octane' },
        { type = 7, label = 'Ledakan Mobil' },
        { type = 8, label = 'Ledakan Pesawat' },
        { type = 9, label = 'Pompa Bensin' },
        { type = 12, label = 'Semburan Api' },
        { type = 13, label = 'Semburan Hidran' },
        { type = 20, label = 'Granat Asap' },
        { type = 21, label = 'Gas BZ' },
        { type = 22, label = 'Suar' },
        { type = 27, label = 'Tong Meledak' },
        { type = 28, label = 'Tabung Propana' },
    },

    lightningExplosion = 0,

    weapons = {
        { label = 'Pistol', weapon = 'WEAPON_PISTOL' },
        { label = 'Combat Pistol', weapon = 'WEAPON_COMBATPISTOL' },
        { label = 'SMG', weapon = 'WEAPON_SMG' },
        { label = 'Assault Rifle', weapon = 'WEAPON_ASSAULTRIFLE' },
        { label = 'Carbine Rifle', weapon = 'WEAPON_CARBINERIFLE' },
        { label = 'Pump Shotgun', weapon = 'WEAPON_PUMPSHOTGUN' },
        { label = 'Sniper Rifle', weapon = 'WEAPON_SNIPERRIFLE' },
        { label = 'Pisau', weapon = 'WEAPON_KNIFE' },
        { label = 'Tongkat Baseball', weapon = 'WEAPON_BAT' },
    },

    animations = {
        { id = 'hello', label = 'Menyapa', category = 'Gestur', dict = 'gestures@m@standing@casual', name = 'gesture_hello', flag = 0 },
        { id = 'handsup', label = 'Angkat Tangan', category = 'Gestur', dict = 'missminuteman_1ig_2', name = 'handsup_base', flag = 1 },
        { id = 'busted', label = 'Berlutut Menyerah', category = 'Gestur', dict = 'random@arrests@busted', name = 'idle_a', flag = 1 },
        { id = 'crossarms', label = 'Silang Tangan', category = 'Diam', dict = 'amb@world_human_hang_out_street@female_arms_crossed@base', name = 'base', flag = 1 },
        { id = 'hangout', label = 'Nongkrong', category = 'Diam', dict = 'amb@world_human_hang_out_street@male_b@idle_a', name = 'idle_a', flag = 1 },
        { id = 'lean', label = 'Bersandar', category = 'Diam', dict = 'amb@world_human_leaning@male@wall@back@foot_up@idle_a', name = 'idle_a', flag = 1 },
        { id = 'smoke', label = 'Merokok', category = 'Diam', dict = 'amb@world_human_smoking@male@male_a@idle_a', name = 'idle_a', flag = 1 },
        { id = 'phone', label = 'Menelepon', category = 'Diam', dict = 'cellphone@', name = 'cellphone_call_listen_base', flag = 49 },
        { id = 'sitground', label = 'Duduk di Tanah', category = 'Diam', dict = 'anim@heists@fleeca_bank@ig_7_jetski_owner', name = 'owner_idle', flag = 1 },
        { id = 'cheer', label = 'Bersorak', category = 'Keramaian', dict = 'amb@world_human_cheering@male_a', name = 'base', flag = 1 },
        { id = 'dance', label = 'Menari', category = 'Keramaian', dict = 'anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity', name = 'hi_dance_facedj_09_v2_male^1', flag = 1 },
        { id = 'writhe', label = 'Terluka di Tanah', category = 'Dramatis', dict = 'combat@damage@writhe', name = 'writhe_loop', flag = 1 },
        { id = 'cower', label = 'Ketakutan', category = 'Dramatis', dict = 'anim@heists@ornate_bank@hostages@hit', name = 'hit_loop_ped_b', flag = 1 },
    },

    radialDefaults = { 'clear_now', 'clear', 'ambient', 'stand', 'flee' },
}
