return {
    blankItem = 'warden_pin',
    cardItem = 'warden_pin_final',

    sealMaker = 'seal_maker',
    sealCard = 'seal_card',

    accessCards = {
        full_access_card = true,
        restricted_access_card = true,
    },

    selectDistance = 5.0,
    showDistance = 5.0,
    showDuration = 10000,
    maxNearby = 16,

    minDays = 1,
    maxDays = 365,

    wearDuration = 3000,
    wearAnim = { dict = 'missmic4', clip = 'michael_tux_fidget', flag = 49 },

    model = 'warden_prop',
    streamDistance = 40.0,
    scanInterval = 1000,

    placement = {
        bone = 24818,
        x = 0.1096, y = 0.1448, z = 0.1192,
        rx = 1.20, ry = 86.40, rz = -102.00,
        scale = 0.145,
    },
    minScale = 0.05,
    maxScale = 0.5,
    maxOffset = 0.4,

    adjustCommand = 'wardenpin',
}
