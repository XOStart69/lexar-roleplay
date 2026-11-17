return {
    traversal = {
        enabled = false,
        minHeight = 1.10,
        lowMax = 1.05,
        mediumMax = 1.75,
        highMax = 2.9,
        grabReach = 0.95,
        maxAssist = 1.1,
        forwardReach = 1.5,
        smartVault = {
            enabled = true,
            maxDepth = 0.9,
            landingGap = 0.4,
            maxDrop = 0.6,
            scanStep = 0.12
        },
        approachAngles = { 0.0, -20.0, 20.0, -40.0, 40.0 },
        scanStep = 0.15,
        scanInterval = 80,
        airInterval = 20,
        groundInterval = 500,
        landingDepth = 0.5,
        bodyRadius = 0.25,
        landingSpread = 0.2,
        hangGap = 0.45,
        minSurfaceNormal = 0.65,
        maxLandingSlope = 0.35,
        catchWhileFalling = true,
        minFallSpeed = 2.0,
        useNativeClamber = true,
        clamberGrace = 220,
        hangAnim = { dict = '', name = '' },
        vaultTime = 400,
        mantleTime = 600,
        climbTime = 900,
        reachTime = 180,
        hangTime = 130,
        cooldown = 450,
        safetyTimeout = 2600,
        probeFlags = 35,
        clearanceFlags = 51
    },

    lean = {
        enabled = true,
        keyLeft = 'Q',
        keyRight = 'E',
        requireAiming = true,
        allowWhileSprinting = false,
        blendSpeed = 9.0,
        distance = 0.227,
        blockWhenObstructed = false,
        obstructionPadding = 0.12,
        anim = {
            dict = 'weapons@misc@digi_scanner',
            left = 'walk_additive_left',
            right = 'walk_additive_right',
            flags = 304
        },
        camera = {
            enabled = true,
            left = 0.7,
            right = 0.7,
            forward = 0.0,
            height = -0.03,
            narrow = 6.0,
            crosshair = false,
            padding = 0.18
        },
        gamepad = {
            enabled = false,
            left = 205,
            right = 206
        }
    },

    ballistics = {
        enabled = true,
        onlyWhileLeaning = false,
        interval = 100,
        maxRange = 120.0,
        clearance = 0.15,
        coverRange = 2.0,
        indicator = true,
        indicatorSize = 0.45,
        probeFlags = 51
    }
}
