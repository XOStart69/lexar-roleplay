return {
    jobs = {
        police = true,
        usmarshal = true,
        puskesmas = true,
        banmeskota = true,
        ambulance = true,
        rsroxwood = true,
    },

    helicopters = {
        'polmav', 'aw139', 'ms_heli', 'newsmav', 'helipol', 'usmheli1', 'MH6M', 'bell360',
        'pavelow', 'hh60g', 'mh6mpolice', 'cv22', 'mh6mm', 'pantera',
    },

    theme = 'blue',
    speedUnit = 'Km/h',

    fovMax = 80.0,
    fovMin = 5.0,
    zoomSpeed = 3.0,
    panSpeed = 4.0,
    minHeight = 2.0,
    maxTargetDistance = 700.0,
    losBlockFlags = 1 + 2 + 8 + 16,
    thermalMaxThickness = 0.25,

    keys = {
        toggleCam = 51,
        vision = 25,
        rappel = 154,
        spotlight = 183,
        lockOn = 22,
        display = 44,
        lightUp = 246,
        lightDown = 173,
        radiusUp = 137,
        radiusDown = 21,
    },

    spotlight = {
        brightness = { default = 1.0, min = 1.0, max = 10.0 },
        radius = { default = 4.0, min = 4.0, max = 10.0 },
        drawRange = 800.0,
    },

    marker = {
        maxAmount = 9,
        drawDistance = 1000.0,
        circle = { type = 23, scale = 8.0, r = 230, g = 50, b = 50, a = 200 },
        number = { display = true, scale = 6.0, r = 230, g = 50, b = 50, a = 200 },
        blip = { display = true, number = true, sprite = 57, scale = 0.75, colour = 1 },
    },
}
