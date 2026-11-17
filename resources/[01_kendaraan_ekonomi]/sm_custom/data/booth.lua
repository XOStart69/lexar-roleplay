return {
    preview = 'sultan',
    radius = 2.5,
    reach = 1.8,
    time = 20000,

    screen = {
        model = 'rhd_paint_screen',
        target = 'rhd_paint_screen',
        width = 1280,
        height = 720,
        surface = {
            vec3(0.32, 0.1537, 1.6363),
            vec3(-0.32, 0.1537, 1.6363),
            vec3(-0.32, 0.2286, 1.2841),
            vec3(0.32, 0.2286, 1.2841),
        },
        camera = { fov = 40.0, fill = 0.5 },
    },

    nozzle = {
        model = 'prop_tool_nailgun',
        asset = 'core',
        effect = 'ent_amb_steam',
        scale = 1.2,
        alpha = 100.0,
        offset = vec3(0.2, 0.0, 0.1),
        rotation = vec3(0.0, 80.0, 0.0),
    },

    primer = { colour = { 255, 255, 255 }, share = 0.4 },

    smoke = {
        asset = 'scr_paintnspray',
        effect = 'scr_respray_smoke',
        scale = 0.5,
        alpha = 100.0,
        offset = vec3(0.2, 0.0, 0.1),
        rotation = vec3(0.0, 80.0, 0.0),
        time = 10000,
    },
}
