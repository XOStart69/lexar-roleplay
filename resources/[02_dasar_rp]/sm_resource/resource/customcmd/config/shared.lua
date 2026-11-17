return {
    -- Enhanced Consumables
    enhancedItems = {
        blood_potion = {
            label = 'Blood Potion',
            speedBoost = true,
            speedDuration = 180000,
            animDict = "mp_player_intdrink",
            animName = "loop_bottle",
            animFlag = 49,
            duration = 3000,
            progressLabel = 'Minum Blood Potion...',
            screenEffect = "DrugsMichaelAliensFightIn",
            screenEffectDuration = 60000,
            applyInstantEffect = true
        },
        nightdew_potion = {
            label = 'Nightdew Potion',
            animDict = "mp_player_intdrink",
            animName = "loop_bottle",
            animFlag = 49,
            duration = 4000,
            progressLabel = 'Minum Nightdew Potion...',
            screenEffect = "DrugsTrevorClownsFightIn",
            screenEffectDuration = 30000,
            applyInstantEffect = true,
            poison = {
                enabled = true,
                tickInterval = 36000,      -- 36 detik per tick
                damagePerTick = 1,         -- 1% per tick (1 HP dari 100 effective HP)
                totalDuration = 3600000,   -- 1 jam total
                staggerInterval = 120000,  -- stagger tiap 2 menit
                staggerAnim = {
                    dict = "move_m@drunk@moderatedrunk",
                    name = "walk",
                    flag = 49,
                    duration = 3000
                },
                coughInterval = 60000,     -- batuk tiap 1 menit
                coughAnim = {
                    dict = "timetable@gardener@smoking_joint",
                    name = "idle_cough",
                    flag = 49,
                    duration = 2000
                },
                screenPulse = {
                    effect = "DeathFailMPIn",
                    interval = 45000,
                    duration = 2000
                },
                blurEffect = {
                    enabled = true,
                    interval = 60000,
                    duration = 5000,
                    intensity = 3.0
                }
            },
            cutAnimation = {
                enabled = true,
                cutTime = 3000,
                forceStop = true
            }
        },
        blood_pfesence = {
            label = 'Blood Purifying Essence',
            animDict = "mp_player_intdrink",
            animName = "loop_bottle",
            animFlag = 49,
            duration = 4000,
            progressLabel = 'Minum Blood Purifying Essence...',
            screenEffect = "DrugsMichaelAliensFightIn",
            screenEffectDuration = 5000,
            applyInstantEffect = true,
            antidote = {
                enabled = true,
                curesPoison = true,
            },
            cutAnimation = {
                enabled = true,
                cutTime = 3000,
                forceStop = true
            }
        },
        purification_potion = {
            label = 'Purification Potion',
            animDict = "mp_player_intdrink",
            animName = "loop_bottle",
            animFlag = 49,
            duration = 4000,
            progressLabel = 'Minum Purification Potion...',
            blackout = {
                enabled = true,
                totalDuration = 60000,       -- 1 menit layar gelap + batuk
                screenEffect = "DeathFailMPIn",  -- vignette gelap, masih samar kelihatan
                timecycle = "prologue_ending_fog", -- bikin makin redup
                timecycleStrength = 1.0,
                coughInterval = 3000,        -- jeda antar batuk
                coughAnim = {
                    dict = "timetable@gardener@smoking_joint",
                    name = "idle_cough",
                    flag = 51,
                    duration = 2500
                }
            },
            cutAnimation = {
                enabled = true,
                cutTime = 3000,
                forceStop = true
            }
        },
        joint = {
            label = 'Joint',
            armorGain = 30,
            stressGain = 35,
            maxArmor = 90,
            animDict = "amb@world_human_aa_smoke@male@idle_a",
            animName = "idle_c",
            animFlag = 49,
            duration = 5000,
            progressLabel = 'Using joint...',
            screenEffect = "DrugsMichaelAliensFightIn",
            screenEffectDuration = 20000,
            applyInstantEffect = true,
            prop = {
                model = 'ng_proc_cigarette01a',
                bone = 28422,
                placement = {
                    x = 0.0, y = 0.0, z = 0.0,
                    rx = 0.0, ry = 0.0, rz = 0.0
                }
            }
        },
        cocaine = {
            label = 'Cocaine',
            stressReduce = 30,
            animDict = "mp_suicide",
            animName = "pill",
            animFlag = 49,
            duration = 5000,
            progressLabel = 'Using cocaine...',
            screenEffect = "DrugsTrevorClownsFightIn",
            screenEffectDuration = 15000,
            applyInstantEffect = true,
            cutAnimation = {
                enabled = true,
                cutTime = 3000,
                forceStop = true
            }
        },
        meth = {
            label = 'Meth',
            healthGain = 35,
            stressGain = 35,
            animDict = "mp_suicide",
            animName = "pill",
            animFlag = 49,
            duration = 5000,
            progressLabel = 'Using methamine...',
            screenEffect = "DrugsMichaelAliensFightIn",
            screenEffectDuration = 15000,
            applyInstantEffect = true,
            blurEffect = {
                enabled = true,
                duration = 15000,
                interval = 2000,
                blurIntensity = 5.0
            },
            cutAnimation = {
                enabled = true,
                cutTime = 3000,
                forceStop = true
            }
        },
        k2narko = {
            label = "K2 Narko",
            animDict = "mp_suicide",
            animName = "pill",
            animFlag = 49,
            duration = 5000,
            progressLabel = 'Menggunakan K2 Narko...',
            screenEffect = "DrugsMichaelAliensFightIn",
            screenEffectDuration = 900000,
            applyInstantEffect = true,
            stressGain = 40,
            staminaBoost = true,
            staminaDuration = 900000,
            screenShake = {
                enabled = true,
                duration = 900000,
                intensity = 0.3,
                interval = 2000
            },
            cutAnimation = {
                enabled = true,
                cutTime = 3000,
                forceStop = true
            }
        },
        blueparadise = {
            label = "Blue Paradise",
            animDict = "mp_suicide",
            animName = "pill",
            animFlag = 49,
            duration = 5000,
            progressLabel = 'Menggunakan Blue Paradise...',
            screenEffect = "DrugsTrevorClownsFightIn",
            screenEffectDuration = 300000,
            applyInstantEffect = true,
            stressGain = 40,
            holdStress = true,
            holdStressDuration = 600000, -- 10 menit
            screenShake = {
                enabled = true,
                duration = 300000,
                intensity = 0.25,
                interval = 1500
            },
            cutAnimation = {
                enabled = true,
                cutTime = 3000,
                forceStop = true
            }
        }
    },

    -- Regular Consumables
    consumables = {
        powerbooster = {
            label = 'Power Booster',
            armorGain = 30,
            maxArmor = 90,
            animDict = "mp_player_intdrink",
            animName = "loop_bottle",
            duration = 3000,
            progressLabel = 'Minum Power Booster...',
            applyDrunkEffect = true
        },
        bodybooster = {
            label = 'Body Booster',
            armorGain = 30,
            maxArmor = 90,
            animDict = "mp_player_intdrink",
            animName = "loop_bottle",
            duration = 3000,
            progressLabel = 'Minum Body Booster...',
            applyDrunkEffect = true,
            restrictedToJobs = {"government", "paspampres", "police", "usmarshal", "pengadilan"},
            exceptionItem = "badgepaspampres"
        }
    },

    -- Armor Items
    armor = {
        armor1 = { armorGain = 30, duration = 4000 },
        armor2 = { armorGain = 60, duration = 6000 },
        armor3 = { armorGain = 90, duration = 6000, allowCombat = false },
        armor4 = { armorGain = 50, duration = 6000 },
        armor5 = { armorGain = 90, duration = 6000, allowCombat = false },
        armor = { armorGain = 90, duration = 6000 },
        armorroxwood = { armorGain = 45, duration = 4000 }
    },

    -- Homemade Milk
    homemademilk = {
        requiredUses = 3,
        effectReduction = 24000,
        animDict = "mp_player_intdrink",
        animName = "loop_bottle",
        duration = 3000,
        progressLabel = "Minum Homemade Milk..."
    },

    -- Microphone
    microphone = {
        minRadius = 1,
        maxRadius = 100,
        animation = {
            dict = "lunyx@mic@p2",
            anim = "mic@p2",
            flag = 51
        },
        prop = {
            model = `sf_prop_sf_mic_01a`,
            bone = 60309,
            pos = vector3(0.035, 0.018, 0.029),
            rot = vector3(-180.0, -13.0, 0.0)
        }
    },

    -- Vehicle Repair Kits
    vehicleRepair = {
        bodykit = {
            label = 'Body Repair Kit',
            progressDuration = 10000,
            progressLabel = 'Memperbaiki body kendaraan...',
            scenario = 'WORLD_HUMAN_HAMMERING',
            messages = {
                noVehicle = 'Tidak ada kendaraan di sekitar!',
                invalidVehicle = 'Kendaraan tidak valid!',
                noNeedRepair = 'Kendaraan tidak memerlukan perbaikan body!',
                cancelled = 'Perbaikan dibatalkan!',
                success = 'Body kendaraan berhasil diperbaiki!'
            }
        },
        enginekit = {
            label = 'Engine Repair Kit',
            progressDuration = 15000,
            progressLabel = 'Memperbaiki mesin kendaraan...',
            animDict = 'mini@repair',
            animName = 'fixing_a_ped',
            repairAmount = 250,
            messages = {
                noVehicle = 'Tidak ada kendaraan di sekitar!',
                invalidVehicle = 'Kendaraan tidak valid!',
                noNeedRepair = 'Mesin kendaraan tidak memerlukan perbaikan!',
                cancelled = 'Perbaikan dibatalkan!',
                success = 'Mesin diperbaiki 25 persen. Kesehatan mesin sekarang: %d%%'
            }
        }
    },

    -- Kedip Command
    kedip = {
        cooldownTime = 30000,
        focusLocation = vector3(3504.0627, 2575.9893, 10.8849),
        unloadDuration = 2000,
        loadRadius = 150.0,
        loadTimeout = 8000,
        driftTolerance = 3.0,
        fadeOutDuration = 500,
        fadeInDuration = 500,
        messages = {
            inDrugField = 'Tidak bisa menggunakan /kedip di dalam zone tanaman!',
            inVehicle = 'Tidak bisa menggunakan command ini di dalam kendaraan!',
            isAttached = 'Tidak bisa menggunakan command ini saat sedang attach!',
            isCarrying = 'Tidak bisa menggunakan /kedip saat sedang menggendong player!',
            isBeingCarried = 'Tidak bisa menggunakan /kedip saat sedang digendong player lain!',
            isEscorting = 'Tidak bisa menggunakan /kedip saat sedang menyeret (escort) player!',
            isEscorted = 'Tidak bisa menggunakan /kedip saat sedang diseret (escort) player lain!',
            inAnimation = 'Tidak bisa menggunakan /kedip saat sedang memakai emote! Ketik /e c dulu.',
            isRagdoll = 'Tidak bisa menggunakan /kedip saat sedang ragdoll/terjatuh!',
            onCooldown = 'Command masih dalam cooldown, tunggu sebentar!',
            success = 'Map dan character berhasil di-refresh',
            cooldownReady = 'Command /kedip sudah bisa digunakan lagi'
        }
    },

    -- Tenggelam/Jatuh Command (nyangkut di bawah tanah / ga napak dunia)
    tenggelam = {
        cooldownTime = 600000,
        fadeOutDuration = 500,
        fadeInDuration = 500,
        undergroundThreshold = 1.5,
        floatingThreshold = 15.0,
        maxScanHeight = 1500.0,
        minScanHeight = -200.0,
        scanStep = 25.0,
        safeZOffset = 1.0,
        vehicleZOffset = 1.5,
        vehicleStuckMaxSpeed = 1.0,
        collisionTimeout = 10000,
        settleDelay = 500,
        collisionRequestTimeout = 5000,
        fallbackCoords = vector3(0.0, 0.0, 0.0),
        fallbackHeading = 0.0,
        messages = {
            isHandcuffed = 'Tidak bisa menggunakan command ini saat diborgol!',
            inDrugField = 'Tidak bisa menggunakan /tenggelam di dalam zone tanaman!',
            notDriver = 'Cuma pengemudi yang bisa pakai /tenggelam di dalam kendaraan!',
            isAttached = 'Tidak bisa menggunakan command ini saat sedang attach!',
            isCarrying = 'Tidak bisa menggunakan /tenggelam saat sedang menggendong player!',
            isBeingCarried = 'Tidak bisa menggunakan /tenggelam saat sedang digendong player lain!',
            isEscorting = 'Tidak bisa menggunakan /tenggelam saat sedang menyeret (escort) player!',
            isEscorted = 'Tidak bisa menggunakan /tenggelam saat sedang diseret (escort) player lain!',
            inAnimation = 'Tidak bisa menggunakan /tenggelam saat sedang memakai emote! Ketik /e c dulu.',
            notStuck = 'Kamu tidak sedang tenggelam/jatuh ke dalam tanah. Command ini cuma buat yang nyangkut.',
            notStuckVehicle = 'Kendaraan kamu tidak sedang nyangkut di dalam tanah. Command ini cuma buat yang nyangkut.',
            groundNotFound = 'Gagal menemukan permukaan tanah di posisi kamu. Silakan lapor admin.',
            fallbackUsed = 'Tanah di posisi kamu tidak ditemukan, kamu dipindahkan ke titik aman.',
            onCooldown = 'Command /tenggelam masih cooldown, sisa %s lagi.',
            success = 'Kamu berhasil dinaikkan kembali ke permukaan tanah.',
            cooldownReady = 'Command /tenggelam sudah bisa digunakan lagi'
        }
    },

    -- Admin Settings
    admin = {
        allowedSteamIDs = {
            "steam:11000014acba039", --naga
            "steam:110000111be9ce4", --axon
            "steam:11000010920f95d", --gokong
            "steam:11000015b1c84a5", --sampul
            "steam:11000015a9f7938", --piyoyo
        },
        confirmationTimeout = 60,
        searchDistance = 50.0,
        webhooks = {}
    },

    -- General Settings
    cooldownTime = 3,
    drunkEffectDuration = 15000,
    screenEffectDuration = 120000,
    armorAnimDict = "rick3d@weapons",
    armorAnimName = "armorplate",
    armorProp = { model = 'prop_armorplate', bone = 28422, pos = vector3(0.030, 0.010, -0.145), rot = vector3(-168.0, 96.0, 0.0) },
    armorProgressLabel = 'Memakai armor..',
}