local placeAnim = {
    dict = 'weapons@first_person@aim_rng@generic@projectile@sticky_bomb@',
    name = 'plant_floor',
    duration = 1000
}

return {
    anims = {
        place = placeAnim,
        remove = placeAnim
    },

    ziplines = {
        {
            poleModel = `prop_fncsec_02pole`,
            startPos = vec3(930.4150, -1940.3555, 39.1228),
            endPos = vec3(953.3053, -1993.0087, 37.1447)
        },
        {
            poleModel = `prop_fncsec_02pole`,
            startPos = vec3(952.3739, -1995.2802, 37.1468),
            endPos = vec3(932.0899, -2000.2003, 29.2453),
            maxUpwardsAngle = 5.0
        },
        {
            poleModel = `prop_fncsec_02pole`,
            startPos = vec3(874.84, -2113.77, 44.1),
            endPos = vec3(568.82, -2099.38, 49.76)
        }
    },

    items = {
        zipline = {
            item = 'zipline',
            minDist = 2.0,
            maxDist = 50.0,
            poleModel = `prop_fncsec_02pole`,
            offset = vec3(0.0, 0.0, 0.0),
            removeItem = true,
            durationMultiplier = 1.0,
            angleEffectMultiplier = 1.0,
            maxUpwardsAngle = 45.0,
            canRemove = true
        }
    },

    ziplineGun = {
        weaponHash = `WEAPON_AUTOCROSS`,
        minDist = 2.0,
        maxDist = 50.0,
        ammoItem = 'zipline_ammo',
        removeItem = true,
        poleModel = `prop_fncsec_02pole`,
        durationMultiplier = 1.0,
        angleEffectMultiplier = 1.0,
        maxUpwardsAngle = 45.0,
        canRemove = true
    },

    grappleGun = {
        weaponHash = `WEAPON_AUTOCROSSGAADA`,
        minDist = 2.0,
        maxDist = 100.0,
        ammoItem = 'grapple_gun_ammo',
        removeItem = true,
        durationMultiplier = 1.0,
        angleEffectMultiplier = 1.0,
        cooldown = 5000,
        maxUpwardsAngle = 20.0
    },

    baseDurationMultiplier = 1.0,
    baseAngleEffectMultiplier = 1.0,
    baseMaxUpwardsAngle = 45.0,

    disabledAreas = {},

    text = {
        useZipline = 'Gunakan Zipline',
        placing = 'Memasang zipline',
        removing = 'Melepas zipline',
        remove = 'Hapus Zipline',
        grappleCooldown = 'Grapple gun belum siap dipakai',
        invalidPosition = 'Posisi tidak valid',
        pathBlocked = 'Jalur terhalang',
        tooFar = 'Terlalu jauh',
        angleTooSteep = 'Sudutnya terlalu curam',
        needItem = 'Kamu butuh %sx %s',
        removeExisting = 'Hapus zipline yang ada terlebih dahulu',
        disabledArea = 'Tidak bisa dipasang di area ini'
    }
}
