---@class CarryPoseConfig
---@field animDict string
---@field anim string
---@field flag number
---@field attachX number?
---@field attachY number?
---@field attachZ number?
---@field rotX number?
---@field rotY number?
---@field rotZ number?
---@field boneIndex? number
---@field fixedRot? boolean

---@class CarryTypeConfig
---@field personCarrying CarryPoseConfig
---@field personCarried CarryPoseConfig
---@field personCarried2? CarryPoseConfig

---@type table<string, CarryTypeConfig>
return {
    carry = {
        personCarrying = {
            animDict = "missfinale_c2mcs_1",
            anim = "fin_c2_mcs_1_camman",
            flag = 49,
        },
        personCarried = {
            animDict = "nm",
            anim = "firemans_carry",
            attachX = 0.27,
            attachY = -0.01,
            attachZ = 0.63,
            flag = 33,
        }
    },
    carry2 = {
        personCarrying = {
            animDict = "timetable@amanda@ig_3",
            anim = "ig_3_base_tracy",
            flag = 49,
        },
        personCarried = {
            animDict = "timetable@ron@ig_3_couch",
            anim = "base",
            attachX = 0.0,
            attachY = 0.1,
            attachZ = 0.83,
            rotZ = 0.0,
            flag = 33,
        }
    },
    carry3 = {
        personCarrying = {
            animDict = "anim@heists@box_carry@",
            anim = "idle",
            flag = 49,
        },
        personCarried = {
            animDict = "amb@code_human_in_car_idles@generic@ps@base",
            anim = "base",
            attachX = 0.015,
            attachY = 0.38,
            attachZ = 0.11,
            rotX = 0.9,
            rotY = 0.30,
            rotZ = 90.0,
            flag = 33,
        }
    },
    gendongbocil1 = {
        personCarrying = {
            animDict = "move_m@hiking",
            anim = "idle",
            flag = 49,
        },
        personCarried = {
            animDict = "timetable@ron@ig_3_couch",
            anim = "base",
            attachX = 0.0,
            attachY = 0.4,
            attachZ = 1.6,
            rotX = 0.5,
            rotY = 0.5,
            rotZ = 0.0,
            flag = 33,
        }
    },
    gendongbocil2 = {
        personCarrying = {
            animDict = "amb@world_human_drinking@coffee@male@base",
            anim = "base",
            flag = 49,
        },
        personCarried = {
            animDict = "timetable@tracy@ig_14@",
            anim = "ig_14_base_tracy",
            attachX = 0.0,
            attachY = 0.1,
            attachZ = 1.6,
            rotX = 0.5,
            rotY = 0.5,
            rotZ = 0.0,
            flag = 33,
        }
    },
    gendongbocil3 = {
        personCarrying = {
            animDict = "suty@parent2",
            anim = "clip3",
            flag = 49,
        },
        personCarried = {
            animDict = "suty@child2",
            anim = "clip3",
            attachX = -0.440,
            attachY = 0.221,
            attachZ = 0.742,
            rotX = 23.20,
            rotY = 0.00,
            rotZ = -115.90,
            fixedRot = true,
            flag = 33,
        }
    },
    gendongbocil4 = {
        personCarrying = {
            animDict = "anim@sports@ballgame@handball@",
            anim = "ball_idle",
            flag = 49,
        },
        personCarried = {
            animDict = "amb@prop_human_seat_chair@male@elbows_on_knees@idle_a",
            anim = "idle_a",
            attachX = -0.203,
            attachY = 0.037,
            attachZ = 0.722,
            rotX = 12.40,
            rotY = 0.00,
            rotZ = 4.90,
            fixedRot = true,
            flag = 33,
        }
    },
    gendongbocil5 = {
        personCarrying = {
            animDict = "anim@sports@ballgame@handball@",
            anim = "ball_idle",
            flag = 49,
        },
        personCarried = {
            animDict = "timetable@ron@ig_5_p3",
            anim = "ig_5_p3_base",
            attachX = -0.073,
            attachY = 0.475,
            attachZ = 0.994,
            rotX = 0.00,
            rotY = 0.00,
            rotZ = 0.00,
            fixedRot = true,
            flag = 33,
        }
    },
    gendongbocil6 = {
        personCarrying = {
            animDict = "anim@sports@ballgame@handball@",
            anim = "ball_idle",
            flag = 49,
        },
        personCarried = {
            animDict = "anim@scripted@freemode_npc@fix_astu_ig3_pooh_jimmy@jimmy@",
            anim = "sit_base_jimmy",
            attachX = -0.180,
            attachY = 0.092,
            attachZ = 1.104,
            rotX = 0.00,
            rotY = 0.00,
            rotZ = 0.00,
            fixedRot = true,
            flag = 33,
        }
    },
    gendongbocilkembar = {
        personCarrying = {
            animDict = "suty@parent2",
            anim = "clip3",
            flag = 49,
        },
        personCarried = {
            animDict = "suty@child2",
            anim = "clip3",
            attachX = -0.440,
            attachY = 0.221,
            attachZ = 0.742,
            rotX = 23.20,
            rotY = 0.00,
            rotZ = -115.90,
            fixedRot = true,
            flag = 32,
        },
        personCarried2 = {
            animDict = "suty@child2",
            anim = "clip3",
            attachX = 0.407,
            attachY = 0.203,
            attachZ = 0.646,
            rotX = 396.40,
            rotY = 6.60,
            rotZ = 457.40,
            fixedRot = true,
            flag = 32,
        },
    }
}