return {
    zones = {
        distance = 20.0,
    },

    install = {
        distance = 60.0,
    },

    camera = {
        fov = 45.0,
        speed = 6.0,
        stiffness = 9.0,
        sensitivity = 0.25,
        pitch = { -5.0, 65.0 },
        zoom = { 0.6, 1.0 },
        rest = 0.5,
        padding = 1.05,
        clearance = 0.35,
        margin = 0.6,
        frame = vec4(0.03, 0.15, 0.73, 0.85),
        aesthetic = {
            ratio = { 0.28, 0.45 },
            pitch = { 4.0, 10.0 },
            bike = -65.0,
        },
        cockpit = {
            eye = vec3(0.0, 0.0, 0.08),
            nearClip = 0.05,
            heading = { -100.0, 110.0 },
            pitch = { -55.0, 30.0 },
            zoom = { 0.6, 1.2 },
        },
        views = {
            overview = { heading = -40.0, pitch = 6.0, size = 1.0 },
            front = { heading = 0.0, pitch = 10.0, size = 1.0 },
            rear = { heading = 180.0, pitch = 10.0, size = 1.0 },
            left = { heading = -90.0, pitch = 5.0, size = 1.0 },
            right = { heading = 90.0, pitch = 5.0, size = 1.0 },
            top = { heading = 150.0, pitch = 45.0, size = 1.0 },
            wheel = { heading = 70.0, pitch = 3.0, size = 0.3, fov = 36.0, target = vec3(0.6, 0.6, -0.4) },
            engine = { heading = 0.0, pitch = 40.0, size = 0.45, fov = 40.0, target = vec3(0.0, 0.5, 0.2), door = 4 },
            trunk = { heading = 180.0, pitch = 35.0, size = 0.45, fov = 40.0, target = vec3(0.0, -0.5, 0.2), door = 5 },
            interior = { heading = 110.0, pitch = 35.0, size = 0.45, fov = 40.0, target = vec3(0.0, 0.05, 0.3) },
            stance = { heading = 0.0, pitch = 3.0, size = 1.0, fov = 38.0 },
            bumperFront = { heading = 25.0, pitch = 8.0, size = 0.6, fov = 40.0, target = vec3(0.0, 0.85, -0.35) },
            bumperRear = { heading = 155.0, pitch = 8.0, size = 0.6, fov = 40.0, target = vec3(0.0, -0.85, -0.35) },
            grille = { heading = 15.0, pitch = 6.0, size = 0.5, fov = 40.0, target = vec3(0.0, 0.95, 0.0) },
            hood = { heading = 20.0, pitch = 28.0, size = 0.65, fov = 40.0, target = vec3(0.0, 0.5, 0.35) },
            spoiler = { heading = 150.0, pitch = 20.0, size = 0.6, fov = 40.0, target = vec3(0.0, -0.85, 0.55) },
            exhaust = { heading = 165.0, pitch = 5.0, size = 0.5, fov = 38.0, target = vec3(0.0, -0.95, -0.45) },
            skirt = { heading = -90.0, pitch = 4.0, size = 0.85, fov = 40.0, target = vec3(-0.9, 0.0, -0.5) },
            fenderLeft = { heading = -65.0, pitch = 8.0, size = 0.45, fov = 40.0, target = vec3(-0.85, 0.55, 0.0) },
            fenderRight = { heading = 65.0, pitch = 8.0, size = 0.45, fov = 40.0, target = vec3(0.85, 0.55, 0.0) },
            plate = { heading = 180.0, pitch = 6.0, size = 0.35, fov = 36.0, target = vec3(0.0, -1.0, -0.25) },
            plateFront = { heading = 0.0, pitch = 6.0, size = 0.35, fov = 36.0, target = vec3(0.0, 1.0, -0.25) },
            neon = { heading = -60.0, pitch = 2.0, size = 1.0 },
            flame = { heading = 165.0, pitch = 6.0, size = 0.6, fov = 38.0, target = vec3(0.0, -0.9, -0.4) },
            purge = { heading = 20.0, pitch = 5.0, size = 0.7, fov = 40.0, target = vec3(0.0, 0.6, -0.35) },
            dashboard = { heading = 12.0, pitch = -12.0, fov = 65.0, cockpit = true },
            dial = { heading = 0.0, pitch = -14.0, fov = 40.0, cockpit = true },
            steering = { heading = 0.0, pitch = -22.0, fov = 52.0, cockpit = true },
            shifter = { heading = 38.0, pitch = -40.0, fov = 55.0, cockpit = true },
            door = { heading = -75.0, pitch = -25.0, fov = 62.0, cockpit = true },
            seat = { heading = 80.0, pitch = -22.0, fov = 65.0, cockpit = true },
        },
    },

    fitment = {
        enable = true,
        distance = 20.0,
        scan = 2500,
        suspension = {
            [`niko370z`] = { threshold = 0.0, compensation = 1.0, minUpperLimit = 0.15 },
        },
    },

    nitrous = {
        enable = true,
        keys = { boost = 'X', purge = 'LSHIFT' },
        multiplier = 2.0,
        maxSpeed = 300.0,
        drain = 5.0,
        installTime = 5000,
        turbo = true,
        classes = {
            [14] = true, [15] = true, [16] = true
        },
        overheat = { warn = 5, damage = 10, explode = 15 },
        flame = { scale = 0.8, colour = { 32, 32, 255 } },
        purge = { scale = 0.8, colour = { 255, 255, 255 } },
        hud = function(level)
            TriggerEvent('sm_hud:client:updateNitrous', level)
        end,
    },

    hud = {
        hide = function()
            LocalPlayer.state:set('inCutscene', true, false)
            pcall(function() exports.sm_hud:setVisible(false) end)
            pcall(function() exports.sm_resource:toggleTrollUI(true) end)
        end,
        show = function()
            LocalPlayer.state:set('inCutscene', false, false)
            pcall(function() exports.sm_resource:toggleTrollUI(false) end)
        end,
    },
}
