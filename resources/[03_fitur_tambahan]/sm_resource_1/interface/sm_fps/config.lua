return {
    command = 'fps',
    kvpKey = 'sm_fps:settings',
    minObjectQuality = 50,

    defaults = {
        preset = 'none',
        mode = 'none',
        shadowDistance = 100,
        shadowFilter = 'high',
        objectQuality = 100,
        clearEvents = false,
        lightReflections = true,
        rainWind = true,
        bloodStains = true,
        lightFilter = 'off',
    },

    lightFilters = {
        medium = { main = 'MP_Powerplay_blend', extra = 'reflection_correct_ambient' },
        low = { main = 'tunnel' },
        ultralow = { main = 'yell_tunnel_nodirect' },
    },

    presets = {
        kentang = {
            shadowDistance = 0,
            shadowFilter = 'low',
            objectQuality = 50,
            lightReflections = false,
            rainWind = false,
            bloodStains = false,
            clearEvents = true,
            lightFilter = 'ultralow',
        },
    },

    modes = {
        quality = { lightReflections = true, rainWind = true, bloodStains = true, clearEvents = false, shadowFilter = 'high' },
        balanced = { lightReflections = true, rainWind = true, bloodStains = false, clearEvents = false, shadowFilter = 'medium' },
        performance = { lightReflections = false, rainWind = false, bloodStains = false, clearEvents = true, shadowFilter = 'low' },
    },
}
