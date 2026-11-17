
local config = {}

local anim_data = localmodule 'animation'

config.stressReduction = 1

config.location = {
    gym_1 = {
        polygon = {
            points = {
                vec3(-1203.1600341797, -1555.6899414062, 4.0),
                vec3(-1192.2900390625, -1571.1600341797, 4.0),
                vec3(-1192.3900146484, -1571.25, 4.0),
                vec3(-1191.9399414062, -1571.8499755859, 4.0),
                vec3(-1192.8499755859, -1572.4899902344, 4.0),
                vec3(-1192.5799560547, -1572.8900146484, 4.0),
                vec3(-1195.1999511719, -1574.7199707031, 4.0),
                vec3(-1195.4899902344, -1574.3299560547, 4.0),
                vec3(-1196.5, -1575.0799560547, 4.0),
                vec3(-1194.5500488281, -1577.9399414062, 4.0),
                vec3(-1195.5500488281, -1578.6099853516, 4.0),
                vec3(-1195.2600097656, -1579.0400390625, 4.0),
                vec3(-1198.0, -1580.8900146484, 4.0),
                vec3(-1198.3000488281, -1580.5500488281, 4.0),
                vec3(-1199.2299804688, -1581.1999511719, 4.0),
                vec3(-1212.6800537109, -1562.2099609375, 4.0),
                vec3(-1211.1700439453, -1556.5799560547, 4.0),
            },
            thickness = 4.0,
        },
        blip = {
            sprite = 311,
            scale = 0.8,
            color = 3,
            label = 'Gym Area',
            shortRange = true
        },
        ped = {
            model = 'a_m_y_runner_01',
            scenario = 'WORLD_HUMAN_MUSCLE_FLEX',
            coords = vec(-1195.3132, -1577.2386, 4.6058, 131.2690)
        },
        price = {
            { price = 30000, days = 3, label = '3 Hari', value = '3_days' },
            { price = 50000, days = 7, label = '7 Hari', value = '7_days' },
            { price = 200000, days = 30, label = '30 Hari', value = '30_days' }
        },
        anim_data = anim_data.gym_1,
    },
    -- gym_2 = {
    --     polygon = {
    --         points = {
    --             vec3(-532.0, -2407.0, 18.0),
    --             vec3(-536.0, -2411.0, 18.0),
    --             vec3(-545.0, -2404.0, 18.0),
    --             vec3(-540.0, -2399.0, 18.0),
    --         },
    --         thickness = 4.0,
    --     },
    --     blip = false,
    --     ped = {
    --         model = 'a_m_y_runner_01',
    --         scenario = 'WORLD_HUMAN_MUSCLE_FLEX',
    --         coords = vec(-543.6404, -2405.0366, 18.1713, 314.8729)
    --     },
    --     price = {
    --         { price = 30000, days = 3, label = '3 Hari', value = '3_days' },
    --         { price = 50000, days = 7, label = '7 Hari', value = '7_days' },
    --         { price = 200000, days = 30, label = '30 Hari', value = '30_days' }
    --     },
    --     anim_data = anim_data.gym_2,
    -- },
}

return config