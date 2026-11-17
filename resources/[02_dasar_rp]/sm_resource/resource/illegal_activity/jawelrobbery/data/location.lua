local location = {}

location.robbed = false

location.start = {
    coords = vec(-596.002441, -283.731079, 50.636166, 302.3211),
    radius = 0.5,
    inUse = false,
}

location.laser = {
    coords = vec(-622.0230, -231.0551, 38.0570),
    distance = 25,
    laser_disabled = false,
    inUse = false,
}

location.glass_cutting = {
    displayPos = vector3(-617.4622, -227.4347, 37.057),
    displayHeading = -53.06,
    rewardPos = vector3(-617.4622, -227.4347, 38.0861),
    rewardRot = vector3(360.0, 0.0, 70.0),
    looted = false,
    inUse = false,
    globalObject = nil,
    globalItem = nil,
}

location.locker = {
    coords = vec(-631.7342, -229.4191, 38.0570, 57.6157),
    looted = false,
    inUse = false,
}

location.vitrine = {
    { coords = vector3(-626.85, -235.34, 38.06), heading = 38.38, looted = false, inUse = false, oldModel = 'des_jewel_cab3_start', newModel = 'des_jewel_cab3_end', objPos = vector3(-627.35, -234.947, 37.8531), coordsAnim = vector3(-626.51, -235.8, 38.06) },
    { coords = vector3(-625.69, -234.52, 38.06), heading = 38.38, looted = false, inUse = false, oldModel = 'des_jewel_cab4_start', newModel = 'des_jewel_cab4_end', objPos = vector3(-626.298, -234.193, 37.8492), coordsAnim = vector3(-625.59, -234.9, 38.06) },
    { coords = vector3(-627.98, -233.94, 38.06), heading = 214.82, looted = false, inUse = false, oldModel = 'des_jewel_cab_start', newModel = 'des_jewel_cab_end', objPos = vector3(-627.735, -234.439, 37.875), coordsAnim = vector3(-628.09, -233.65, 38.06) },
    { coords = vector3(-626.84, -233.11, 38.06), heading = 214.82, looted = false, inUse = false, oldModel = 'des_jewel_cab_start', newModel = 'des_jewel_cab_end', objPos = vector3(-626.716, -233.685, 37.8583), coordsAnim = vector3(-627.05, -232.9, 38.06) },
    { coords = vector3(-625.63, -237.83, 38.06), heading = 214.82, looted = false, inUse = false, oldModel = 'des_jewel_cab3_start', newModel = 'des_jewel_cab3_end', objPos = vector3(-625.376, -238.358, 37.8687), coordsAnim = vector3(-625.867, -237.458, 38.06) },
    { coords = vector3(-626.7, -238.55, 38.06), heading = 214.82, looted = false, inUse = false, oldModel = 'des_jewel_cab2_start', newModel = 'des_jewel_cab2_end', objPos = vector3(-626.399, -239.132, 37.8616), coordsAnim = vector3(-626.894, -238.2, 38.06) },
    { coords = vector3(-620.28, -234.49, 38.06), heading = 214.82, looted = false, inUse = false, oldModel = 'des_jewel_cab_start', newModel = 'des_jewel_cab_end', objPos = vector3(-619.978, -234.93, 37.8537), coordsAnim = vector3(-620.44, -234.084, 38.06) },
    { coords = vector3(-619.15, -233.69, 38.06), heading = 214.82, looted = false, inUse = false, oldModel = 'des_jewel_cab3_start', newModel = 'des_jewel_cab3_end', objPos = vector3(-618.937, -234.16, 37.8425), coordsAnim = vector3(-619.39, -233.32, 38.06) },
    { coords = vector3(-624.98, -227.84, 38.06), heading = 38.38, looted = false, inUse = false, oldModel = 'des_jewel_cab3_start', newModel = 'des_jewel_cab3_end', objPos = vector3(-625.517, -227.421, 37.86), coordsAnim = vector3(-624.738, -228.2, 38.06) },
    { coords = vector3(-623.89, -227.04, 38.06), heading = 38.38, looted = false, inUse = false, oldModel = 'des_jewel_cab4_start', newModel = 'des_jewel_cab4_end', objPos = vector3(-624.467, -226.653, 37.861), coordsAnim = vector3(-623.688, -227.437, 38.06) },
    { coords = vector3(-620.44, -226.52, 38.06), heading = 307.11, looted = false, inUse = false, oldModel = 'des_jewel_cab_start', newModel = 'des_jewel_cab_end', objPos = vector3(-620.163, -226.212, 37.8266), coordsAnim = vector3(-620.797, -226.79, 38.06) },
    { coords = vector3(-619.63, -227.64, 38.06), heading = 307.11, looted = false, inUse = false, oldModel = 'des_jewel_cab2_start', newModel = 'des_jewel_cab2_end', objPos = vector3(-619.384, -227.259, 37.8342), coordsAnim = vector3(-620.055, -227.817, 38.06) },
    { coords = vector3(-618.32, -229.48, 38.06), heading = 307.11, looted = false, inUse = false, oldModel = 'des_jewel_cab3_start', newModel = 'des_jewel_cab3_end', objPos = vector3(-618.019, -229.115, 37.8302), coordsAnim = vector3(-618.679, -229.704, 38.06) },
    { coords = vector3(-617.53, -230.55, 38.06), heading = 307.11, looted = false, inUse = false, oldModel = 'des_jewel_cab2_start', newModel = 'des_jewel_cab2_end', objPos = vector3(-617.249, -230.156, 37.8201), coordsAnim = vector3(-617.5, -230.7, 38.06) },
    { coords = vector3(-620.13, -233.31, 38.06), heading = 39.12, looted = false, inUse = false, oldModel = 'des_jewel_cab4_start', newModel = 'des_jewel_cab4_end', objPos = vector3(-620.6465, -232.9308, 37.8407), coordsAnim = vector3(-620.184, -233.729, 38.06) },
    { coords = vector3(-619.79, -230.34, 38.06), heading = 131.18, looted = false, inUse = false, oldModel = 'des_jewel_cab_start', newModel = 'des_jewel_cab_end', objPos = vector3(-620.3262, -230.829, 37.8578), coordsAnim = vector3(-619.408, -230.1969, 38.06) },
    { coords = vector3(-623.08, -232.93, 38.06), heading = 307.11, looted = false, inUse = false, oldModel = 'des_jewel_cab_start', newModel = 'des_jewel_cab_end', objPos = vector3(-622.7541, -232.614, 37.8638), coordsAnim = vector3(-623.3596, -233.2296, 38.06) },
    { coords = vector3(-621.04, -228.59, 38.06), heading = 131.18, looted = false, inUse = false, oldModel = 'des_jewel_cab3_start', newModel = 'des_jewel_cab3_end', objPos = vector3(-621.7181, -228.9636, 37.8425), coordsAnim = vector3(-620.864, -228.481, 38.06) },
    { coords = vector3(-624.44, -231.04, 38.06), heading = 307.11, looted = false, inUse = false, oldModel = 'des_jewel_cab4_start', newModel = 'des_jewel_cab4_end', objPos = vector3(-624.1267, -230.7476, 37.8618), coordsAnim = vector3(-624.939, -231.247, 38.06) },
    { coords = vector3(-624.03, -228.11, 38.06), heading = 214.82, looted = false, inUse = false, oldModel = 'des_jewel_cab2_start', newModel = 'des_jewel_cab2_end', objPos = vector3(-623.8118, -228.6336, 37.8522), coordsAnim = vector3(-624.293, -227.83, 38.06) },
}

location.painting = {
    {
        scenePos = vector3(-626.70, -228.3, 38.06),
        sceneRot = vector3(0.0, 0.0, 90.0),
        object = 'ch_prop_vault_painting_01g',
        objectPos = vector3(-627.20, -228.31, 38.06),
        objHeading = 94.75,
        looted = false,
        inUse = false,
    },
    {
        scenePos = vector3(-622.97, -225.54, 38.06),
        sceneRot = vector3(0.0, 0.0, -20.0),
        object = 'ch_prop_vault_painting_01f',
        objectPos = vector3(-622.80, -225.14, 38.06),
        objHeading = 345.85,
        looted = false,
        inUse = false,
    },
    {
        scenePos = vector3(-617.48, -233.22, 38.06),
        sceneRot = vector3(0.0, 0.0, -90.0),
        object = 'ch_prop_vault_painting_01h',
        objectPos = vector3(-617.00, -233.22, 38.06),
        objHeading = 269.53,
        looted = false,
        inUse = false,
    },
    {
        scenePos = vector3(-621.25, -235.78, 38.06),
        sceneRot = vector3(0.0, 0.0, 160.0),
        object = 'ch_prop_vault_painting_01j',
        objectPos = vector3(-621.25, -236.38, 38.06),
        objHeading = 161.22,
        looted = false,
        inUse = false,
    },
}

return location
