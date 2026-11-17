return {
    useTargeting = true,

    keybinds = {
        interact = 'E',
        drop = 'C',
        attach = 'G',
        detach = 'G',
        interactVehicle = 'E',
    },

    ui = {
        icon = 'fa-music',
        iconColor = '#00308F',
        position = 'left-center',
    },

    modelTimeout = 10000,

    maxActiveDui = 3,
    hearingRange = 300.0,
    attachRenderRange = 120.0,

    rateLimit = {
        default = 1000,
        expensive = 3000,
    },

    adminPrincipal = 'group.admin',

    inventoryItemId = 'speaker',

    vehicleSaving = true,

    abandonedSpeakerHours = 24,
    cleanupIntervalHours = 0,
    onlyOwnerCanDetachFromVehicle = true,
    speakersPublicByDefault = false,
    speakersPermanentByDefault = false,
    speakersAllowedPerPlayer = 4,

    defaultVolume = 0.3,
    defaultRange = 25.0,

    shop = {
        enabled = false,
        coords = vec4(-42.53, -1039.37, 27.41, 23.18),
        pedModel = `s_m_y_shop_mask`,
        blip = {
            enabled = false,
            sprite = 52,
            color = 2,
            scale = 0.75,
            text = 'Speaker shop',
        },
    },

    enableSpeakersMenu = false,
    enableSpeakerTypesMenu = true,
    enableSpeakerGroupMenu = true,
    enableSafetyPreference = true,

    youtubeApiKey = 'AIzaSyDH5R42nMO0LvemmMFAqIzz_M12Z4KxydU',

    logWebhook = '',
    logActions = {
        ['Speaker created'] = true,
        ['Speaker stored'] = true,
        ['Speaker picked up'] = true,
        ['Speaker placed down'] = true,
        ['Song played'] = true,
        ['Volume/range changed'] = true,
        ['Pause/resume clicked'] = true,
        ['Speaker attached to a vehicle'] = true,
        ['Speaker detached from a vehicle'] = true,
        ['Speaker group created'] = true,
        ['Speaker group accessed'] = true,
        ['Speaker connected to a group'] = true,
        ['Speaker disconnected from a group'] = true,
        ['Song played (group)'] = true,
        ['Pause/resume clicked (group)'] = true,
        ['Speaker created and attached to a vehicle'] = true,
    },

    speakerWhitelist = {
        ['steam:110000111be9ce4'] = 999,
        ['steam:11000015b1c84a5'] = 12,
    },

    ---@type table<number, string> typeId -> nama file di ox_inventory/web/images
    typeImages = {
        [1] = 'boombox.png',
        [2] = 'speaker1.png',
        [3] = 'speaker2.png',
        [4] = 'speaker3.png',
    },

    fallbackImage = 'speaker1.png',

    filters = {
        lowpass = { 'frequency', 'quality', 'detune' },
        highpass = { 'frequency', 'quality', 'detune' },
        bandpass = { 'frequency', 'quality', 'detune' },
        lowshelf = { 'frequency', 'gain', 'detune' },
        highshelf = { 'frequency', 'gain', 'detune' },
        peaking = { 'frequency', 'quality', 'gain', 'detune' },
        notch = { 'frequency', 'quality', 'detune' },
        allpass = { 'frequency', 'quality', 'detune' },
    },

    filterLimits = {
        frequency = { min = 10, max = 10000, default = 350, units = 'Hz', step = 1 },
        quality = { min = 0.0001, max = 1000, default = 1, units = 'units', step = 0.1, precision = 2 },
        gain = { min = -40, max = 40, default = 0, units = 'dB', step = 0.1, precision = 1 },
        detune = { min = -4800, max = 4800, default = 0, units = 'cents', step = 1 },
    },

    publicSpeakerPermissions = {
        playMusic = true,
        useQueue = true,
        pauseResume = true,
        volumeRange = true,
        addGroup = true,
    },
}
