return {
    Station = vec3(-2131.598877, 3284.728271, 38.686565),
    StationRadius = 1.5,
    StationUseDistance = 6.0,

    SpawnPoint = vec4(-2166.6858, 3207.9351, 32.8118, 147.5535),
    SpawnClearRadius = 5.0,

    ControlJob = {
        name = 'mercenarysm',
        minGrade = 0,
    },
    Command = 'rakitscifi',

    GhostAlpha = 140,
    StreamDistance = 150.0,
    BuildDuration = 30000,
    PreviewTimeout = 180,
    PlatePrefix = 'SCIFI',

    BuildAnim = {
        dict = 'mini@repair',
        clip = 'fixing_a_ped',
        flag = 1,
    },

    CompleteFx = {
        enabled = true,
        asset = 'core',
        name = 'exp_grd_bzgas_smoke',
        scale = 1.2,
        duration = 7000,
        radius = 3.5,
        points = 6,
        center = true,
    },

    PreviewCam = {
        enabled = true,
        fov = 50.0,
        targetHeight = 1.0,
        yawOffset = 35.0,
        pitch = 12.0,
        minPitch = -5.0,
        maxPitch = 60.0,
        distance = 14.0,
        minDistance = 5.0,
        maxDistance = 30.0,
        rotateSpeed = 0.25,
        zoomStep = 1.5,
    },

    Blueprints = {
        {
            model = 'hvriot2',
            type = 'automobile',
            name = 'HV Riot',
            class = 'Prototype',
            description = 'Kendaraan anti huru-hara berlapis baja dengan rangka komposit dan inti energi kristal.',
            image = nil,
            materials = {
                { item = 'material_a', count = 1 },
                { item = 'material_b', count = 1 },
                { item = 'material_c', count = 1 },
                { item = 'material_d', count = 1 },
            },
        },
        {
            model = 'hvswatbuffalo4',
            type = 'automobile',
            name = 'HV SWAT Buffalo',
            class = 'Prototype',
            description = 'Sedan pengejar SWAT berbodi ringan dengan rangka komposit dan inti energi kristal.',
            image = nil,
            materials = {
                { item = 'material_a', count = 1 },
                { item = 'material_b', count = 1 },
                { item = 'material_c', count = 1 },
                { item = 'material_d', count = 1 },
            },
        },
    },
}
