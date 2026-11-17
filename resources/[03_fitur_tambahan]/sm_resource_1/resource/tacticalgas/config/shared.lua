return {
    broadcastRadius = 200.0,
    masks = {
        tearGas = {
            [`mp_m_freemode_01`] = { [1] = { 36 } },
            [`mp_f_freemode_01`] = { [1] = { 36 } }
        },
        stun = {
            [`mp_m_freemode_01`] = { [5] = { 2 } },
            [`mp_f_freemode_01`] = { [5] = { 2 } }
        }
    },

    rubbing = {
        control = 104,
        label = 'Tekan [H] terus-menerus untuk mengucek mata dan pulih lebih cepat.',
        speedMultiplier = 2.0
    },

    grenades = {
        tearGas = {
            weapon = `WEAPON_GRENADE_TEARGAS`,
            prop = `w_ex_grenadesmoke`,
            label = { id = 'WT_GRENADE_TEARGAS', text = 'Tear Gas Grenade' },
            particle = { dict = 'core', fx = 'exp_grd_bzgas_smoke' },
            scale = 55.0,
            duration = 30000,
            disable = { sprint = true, vehicle = true, jump = true, combat = false },
            timecycle = {
                extra = { name = 'ufo', opacity = 1.0 },
                main = { name = 'MP_death_grade_blend01', opacity = 0.8 }
            },
            shake = { name = 'DRUNK_SHAKE', intensity = 3.0 }
        },

        stun = {
            weapon = `WEAPON_GRENADE_STUN`,
            prop = `w_ex_grenadesmoke`,
            label = { id = 'WT_GRENADE_STUN', text = 'Stun Grenade' },
            particle = { dict = 'core', fx = 'exp_grd_sticky_sp' },
            disable = { sprint = true, vehicle = true, jump = true, combat = false },
            flash = {
                radius = 25.0,
                minDuration = 5000,
                maxDuration = 12000,
                volume = 0.1
            }
        },

        smoke = {
            weapon = `WEAPON_GRENADE_SMOKE`,
            prop = `w_ex_grenadesmoke`,
            label = { id = 'WT_GRENADE_SMOKE', text = 'Smoke Grenade' },
            particle = { dict = 'core', fx = 'exp_grd_grenade_smoke' },
            scale = 20.0,
            duration = 50000
        }
    },

    progressBar = {
        color = { 52, 152, 219 },
        label = 'RECOVERY'
    },

    illegalMask = {
        item = 'ilegal_gasmask',
        duration = 10 * 60 * 1000,
        male = 36,
        female = 23
    }
} --[[@as TacticalGasConfig]]
