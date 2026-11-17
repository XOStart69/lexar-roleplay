return {
    weapon = 'WEAPON_STUNGUN',

    cartridge = {
        item = 'taser_cartridge',
        shotsPerCartridge = 3,
        maxCarry = 3,
    },

    fireCooldown = 3000,
    reloadTime = 1500,

    range = 10.0,
    probesPerShot = 2,
    probesToLock = 1,
    probeSpread = 5.0,
    probeJitter = 0.4,
    wireLength = 12.0,
    probeBones = { 11816, 23553, 24816, 24817, 24818, 39317, 31086, 45509, 40269, 61163, 28252, 58271, 51826, 63931, 36864 },

    player = {
        shakeTime = 1500,
        groundTime = 6000,
        twitchTime = 5000,
        holster = true,
    },

    npc = {
        enabled = true,
        shakeTime = 1500,
        groundTime = 10000,
        twitchTime = 5000,
        after = 'flee',
    },

    flinchTime = 600,
    twitchForce = 1.0,

    shakeAnims = {
        { dict = 'stungun@standing', clip = 'damage' },
        { dict = 'ragdoll@human', clip = 'electrocuted_1' },
    },

    reloadAnims = {
        { dict = 'cover@weapon@reloads@pistol@pistol', clip = 'reload_low_left' },
        { dict = 'mp_arresting', clip = 'a_uncuff' },
    },

    wire = {
        color = { 190, 190, 180, 200 },
        segments = 16,
        slack = 0.1,
        maxSag = 1.5,
        drawDistance = 60.0,
    },

    missLinger = 15000,
    syncDistance = 60.0,

    sound = {
        volume = 0.6,
        distance = 30.0,
    },

    muzzleFx = { asset = 'core', name = 'muz_stungun', scale = 1.0 },

    reloadKey = 'R',
}
