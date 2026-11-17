return {
    key = 'G',
    interval = 250,
    walkSpeed = 2.5,

    clipset = {
        hold = 'move_ped_wpn_jerrycan_generic',
        idle = false,
    },

    blend = {
        onehand = 0.5,
        twohand = 1.5,
    },

    groups = {
        GROUP_PISTOL = 'onehand',
        GROUP_STUNGUN = 'onehand',
        GROUP_SMG = 'twohand',
        GROUP_RIFLE = 'twohand',
        GROUP_MG = 'twohand',
        GROUP_SHOTGUN = 'twohand',
        GROUP_SNIPER = 'twohand',
        GROUP_HEAVY = 'twohand',
        GROUP_MELEE = 'onehand',
        GROUP_THROWN = 'onehand',
        GROUP_PETROLCAN = 'onehand',
        GROUP_FIREEXTINGUISHER = 'onehand',
    },

    overrides = {
        WEAPON_MICROSMG = 'onehand',
        WEAPON_MINISMG = 'onehand',
        WEAPON_MACHINEPISTOL = 'onehand',
    },

    ktwr = {
        jobs = {
            admin = true,
            police = true,
            mercenarysm = true,
            usmarshal = true,
            hightable = true,
            paspampres = true,
        },

        blend = 1.0,

        styles = {
            rifle = {
                { id = 'std_low_ready', label = 'Standard Low Ready' },
                { id = 'sling_relaxed', label = 'Sling Relaxed' },
            },
            pistol = {
                { id = 'comp_low_ready', label = 'Compressed Low Ready' },
            },
        },

        groups = {
            GROUP_PISTOL = 'pistol',
            GROUP_STUNGUN = 'pistol',
            GROUP_SMG = 'rifle',
            GROUP_RIFLE = 'rifle',
            GROUP_MG = 'rifle',
            GROUP_SHOTGUN = 'rifle',
            GROUP_SNIPER = 'rifle',
        },

        overrides = {
            WEAPON_MICROSMG = 'pistol',
            WEAPON_MINISMG = 'pistol',
            WEAPON_MACHINEPISTOL = 'pistol',
        },
    },
}
