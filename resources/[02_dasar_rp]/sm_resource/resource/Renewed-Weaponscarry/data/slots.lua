---@class SlotConfig
---@field boneId? number
---@field boneIndex? number
---@field pos? vector3
---@field rot? vector3

return {
    pistol = {
        default = {
            boneId = 35,
            pos = vec(0.06, -0.17, 0.00),
            rot = vec(181.60, 137.50, 4.20),
        },
        police = {
            boneId = 14,
            pos = vec(0.02, 0.01, 0.13),
            rot = vec(-93.00, 0.50, 0.20),
        }
    },
    rifle = {
        default = {
            {
                boneId = 38,
                pos = vec(0.07, -0.16, 0.06),
                rot = vec(0.00, 0.00, 0.20),
            },
            {
                boneId = 38,
                pos = vec(0.07, -0.16, -0.11),
                rot = vec(0.00, 0.00, 0.20),
            }
        }
    },
    fishing_rod = {
        default = {
            boneId = 38,
            pos = vec(0.00, -0.16, 0.12),
            rot = vec(0.00, 89.10, 0.20),
        }
    },
    meth_props = {
        default = {
            boneId = 1,
            pos = vec(-0.01, -0.18, 0.12),
            rot = vec(0.00, -90.0, 0.0),
        }
    },
    joint_props = {
        default = {
            boneId = 1,
            pos = vec(0.00, -0.19, 0.00),
            rot = vec(0.00, 92.70, 90.00),
        }
    },
    cocaine_props = {
        default = {
            boneId = 1,
            pos = vec(-0.01, -0.18, 0.12),
            rot = vec(0.00, -90.0, 0.0),
        }
    },
    
    skateboard = {
        default = {
            boneId = 38,
            pos = vec(-0.01, -0.26, 0.02),
            rot = vec(61.60, 93.20, 94.00),
        }
    },

    weapon_katana_2 = {
        default = {
            boneId = 38,
            pos = vec(0.37, -0.15, -0.21),
            rot = vec(-9.10, -60.20, 8.90),
        }
    },

    weapon_jpx_zoro = {
        default = {
            boneId = 14,
            pos = vec(0.12, -0.03, 0.15),
            rot = vec(-192.00, -96.00, 12.80),
        }
    },
}