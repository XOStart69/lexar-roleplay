return {
    bombs = {
        c4 = {
            item = 'c4',
            label = 'C4',
            model = 'bp_c4',
            timer = true,
            vehicle = true,
            hold = { x = 0.042, y = 0.097, z = -0.172, rx = -55.0, ry = 10.0, rz = -10.0 },
            explosion = { types = { 50, 7 }, damageScale = 1.0, fx = 5.0, shake = 1.0 },
        },
        triggerc4 = {
            item = 'triggerc4',
            label = 'Trigger C4',
            model = 'bp_sticky_c4',
            timer = false,
            vehicle = true,
            hold = { x = 0.064, y = 0.084, z = -0.161, rx = -45.0, ry = -10.0, rz = 0.0 },
            explosion = { types = { 2 }, damageScale = 1.0, fx = 2.0, shake = 0.5 },
        },
    },

    detonator = {
        item = 'detonator',
        model = 'bp_detonator',
        bone = 28422,
        offset = { x = 0.064, y = -0.006, z = -0.031, rx = -85.0, ry = -10.0, rz = 0.0 },
        anim = { dict = 'detonator@animation', clip = 'detonator_clip' },
        range = 150.0,
    },

    defuseKit = 'defuse_kit',

    holdAnim = { dict = 'c4hold@animation', clip = 'c4hold_clip' },
    plantAnim = { dict = 'c4attach@animation', clip = 'c4attach_clip' },
    crouchAnim = { dict = 'testcrouch@animation', clip = 'testcrouch_clip' },

    placeDistance = 4.0,
    plantDuration = 3000,
    rotateStep = 5.0,
    previewAlpha = 150,

    timer = { default = 60, min = 10, max = 3600 },
    pinLength = 6,

    maxPerPlayer = 3,
    maxGlobal = 30,
    triggerLifetime = 7200,

    defuse = {
        distance = 2.5,
        attempts = 3,
        patternSize = 5,
        memorizeMs = 1800,
        revealCooldown = 6000,
        failLockout = 5000,
        failPenalty = 5,
        idleTimeout = 180,
    },

    executorRange = 300.0,
    fxRange = 300.0,
    grantMs = 4000,

    screen = {
        txd = 'bp_c4',
        texture = 'c4_screen_texture',
        distance = 15.0,
        width = 512,
        height = 256,
        volume = 0.6,
    },
}
