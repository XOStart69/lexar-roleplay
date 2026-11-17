return {
    start = {
        target = {
            coords = vec(2808.367432, 5977.146484, 350.519806),
            radius = 0.5,
            distance = 1.5,
            label = 'Hack system',
        },
        requireItems = {
            trojan_usb = 1,
            laptop_pink = 1
        },
        scene = {
            name = 'latopHackStart',
            coords = vec(2808.0354, 5976.9902, 350.3, 317.9212),
            minigame = function ()
                local success = bl_ui.waveMatch(3, {
                    duration = 50000,
                })
                return success
                -- return true
            end
        },
        enable = true,
    },
    thermite = {
        target = {
            coords = vec(735.523743, 132.890060, 80.804268),
            radius = 0.5,
            distance = 1.5,
            label = 'Break the door',
        },
        requireItems = {
            thermite = 1
        },
        doorId = 'electric_anjay',
        scene = {
            name = 'plantThermite',
            coords = vec(735.826294, 133.414047, 80.816940, 60.1894),
            particle = vec(735.8500, 132.9470, 80.7316, 63.8349),
            minigame = function ()
                local success = bl_ui.mineSweeper(3, {
                    grid = 5, -- grid 4x4
                    duration = 10000, -- 10sec to fail
                    target = 5, --target you need to remember
                    previewDuration = 2000 --preview duration (time for red mines preview to hide)
                })
                return success
                
                -- return true
            end
        },
        enable = false,
    },
    shutdown = {
        target = {
            coords = vec3(710.604065, 165.780060, 80.660995),
            radius = 0.5,
            distance = 1.5,
            label = 'Plant bomb',
        },
        requireItems = {
            c4_bomb = 1
        },
        scene = {
            name = 'plantBomb',
            coords = vec(710.4841, 165.5347, 80.7545, 333.4009),
            minigame = function ()
                local success = bl_ui.mineSweeper(3, {
                    grid = 5, -- grid 4x4
                    duration = 10000, -- 10sec to fail
                    target = 5, --target you need to remember
                    previewDuration = 2000 --preview duration (time for red mines preview to hide)
                })
                return success
                
                -- return true
            end
        },
        enable = false,
    }
}