return {
    fleeca = {
        vault_door = function ()
            local success = bl_ui.pathFind(3, {
                numberOfNodes = 6, duration = 35000
            })
            return success
        end,
        bar_door = function ()
            -- Code Injector: same minigame as vault hack (pathFind)
            local success = bl_ui.pathFind(3, {
                numberOfNodes = 6, duration = 35000
            })
            return success
        end
    },
    blaneCounty = {
        vault_door = function ()
            -- laptop_malware: pathFind hack
            local success = bl_ui.pathFind(3, {
                numberOfNodes = 6, duration = 35000
            })
            return success
        end,
        bar_door = function ()
            -- thermite: mineSweeper
            local success = bl_ui.mineSweeper(3, {
                grid = 5,
                duration = 10000,
                target = 5,
                previewDuration = 2000
            })
            return success
        end,
        computer = function ()
            -- security_card: terminal hack
            local success = terminal_hack.start({
                totalDecoy = 3,
                totalFile = math.random(3, 5),
                totalTime = 300,
                totalForlder = math.random(2, 4),
                theme = 'cyan'
            })
            return success
        end
    },
    pacificBank = {
        bar_door = function ()
            -- thermite bar door 1
            local success = bl_ui.mineSweeper(3, {
                grid = 6,
                duration = 12000,
                target = 6,
                previewDuration = 1500
            })
            return success
        end,
        bar_door_2 = function ()
            -- laptop_gold bar door 2
            local success = bl_ui.pathFind(3, {
                numberOfNodes = 8, duration = 40000
            })
            return success
        end,
        vault_door = function ()
            -- backdoor_kit: terminal hack
            local success = terminal_hack.start({
                totalDecoy = 1,
                totalFile = 1,
                totalTime = 800,
                totalForlder = 1,
                theme = 'cyan'
            })
            return success
        end
    }
}