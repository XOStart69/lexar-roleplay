local level = {
    { value = 'Mudah' },
    { value = 'Sedang' },
    { value = 'Sulit' }
}

local drillModule = require 'resource.illegal_activity.utils.drill'

return {
    terminal_hack = {
        label = 'Terminal Hack',
        level = level,
        onSelect = function(selectedLevel)
            local cfg = {
                Mudah = 'easy',
                Sedang = 'medium',
                Sulit  = 'hard',
            }
            local c = cfg[selectedLevel]
            local success = terminal_hack.start(c)
            return success
        end
    },
    lockpick = {
        label = 'Lockpick',
        level = level,
        onSelect = function(selectedLevel)
            local cfg = {
                Mudah  = { difficulty = 2, pins = 3 },
                Sedang = { difficulty = 4, pins = 5 },
                Sulit  = { difficulty = 7, pins = 7 },
            }
            local c = cfg[selectedLevel]
            local success = exports.sm_sidejob:startLockpick('lockpick', c.difficulty, c.pins)
            return success
        end
    },
    advanced_lockpick = {
        label = 'Advanced Lockpick',
        level = level,
        onSelect = function(selectedLevel)
            local cfg = {
                Mudah  = { difficulty = 3, pins = 4 },
                Sedang = { difficulty = 5, pins = 6 },
                Sulit  = { difficulty = 7, pins = 8 },
            }
            local c = cfg[selectedLevel]
            local success = exports.sm_sidejob:startLockpick('advanced-lockpick', c.difficulty, c.pins)
            return success
        end
    },
    drill = {
        label = 'Drill',
        onSelect = function(selectedLevel)
            drillModule.LoadDrillSound()
            Wait(250)
            local soundId = GetSoundId()
            PlaySoundFromEntity(soundId, 'Drill', cache.ped, 'DLC_HEIST_FLEECA_SOUNDSET', true, 0)

            local success = promise.new()

            drillModule.Start(function(result)
                drillModule.UnloadDrillSound(soundId)
                success:resolve(result)
            end)

            return Citizen.Await(success)
        end
    },
    circlesum = {
        label = 'Circle Sum',
        level = level,
        onSelect = function(selectedLevel)
            local cfg = {
                Mudah  = { iterations = 1, length = 3, duration = 7000 },
                Sedang = { iterations = 2, length = 5, duration = 5000 },
                Sulit  = { iterations = 3, length = 7, duration = 4000 },
            }
            local c = cfg[selectedLevel]
            local success = bl_ui.circleSum(c.iterations, {
                length   = c.length,
                duration = c.duration,
            })
            return success
        end
    },
    digitdazzle = {
        label = 'Digit Dazzle',
        level = level,
        onSelect = function(selectedLevel)
            local cfg = {
                Mudah  = { iterations = 1, length = 3, duration = 7000 },
                Sedang = { iterations = 2, length = 5, duration = 5000 },
                Sulit  = { iterations = 3, length = 7, duration = 4000 },
            }
            local c = cfg[selectedLevel]
            local success = bl_ui.digitDazzle(c.iterations, {
                length   = c.length,
                duration = c.duration,
            })
            return success
        end
    },
    lightsout = {
        label = 'Lights Out',
        level = level,
        onSelect = function(selectedLevel)
            local cfg = {
                Mudah  = { iterations = 1, level = 1, duration = 15000 },
                Sedang = { iterations = 2, level = 2, duration = 12000 },
                Sulit  = { iterations = 3, level = 3, duration = 10000 },
            }
            local c = cfg[selectedLevel]
            local success = bl_ui.lightsOut(c.iterations, {
                level    = c.level,
                duration = c.duration,
            })
            return success
        end
    },
    minesweeper = {
        label = 'Mine Sweeper',
        level = level,
        onSelect = function(selectedLevel)
            local cfg = {
                Mudah  = { iterations = 1, grid = 3, target = 3, duration = 15000, previewDuration = 3000 },
                Sedang = { iterations = 2, grid = 4, target = 5, duration = 12000, previewDuration = 2000 },
                Sulit  = { iterations = 3, grid = 5, target = 7, duration = 10000, previewDuration = 1500 },
            }
            local c = cfg[selectedLevel]
            local success = bl_ui.mineSweeper(c.iterations, {
                grid            = c.grid,
                duration        = c.duration,
                target          = c.target,
                previewDuration = c.previewDuration,
            })
            return success
        end
    },
    pathfind = {
        label = 'Path Find',
        level = level,
        onSelect = function(selectedLevel)
            local cfg = {
                Mudah  = { iterations = 1, numberOfNodes = 6,  duration = 8000  },
                Sedang = { iterations = 2, numberOfNodes = 10, duration = 6000  },
                Sulit  = { iterations = 3, numberOfNodes = 14, duration = 5000  },
            }
            local c = cfg[selectedLevel]
            local success = bl_ui.pathFind(c.iterations, {
                numberOfNodes = c.numberOfNodes,
                duration      = c.duration,
            })
            return success
        end
    },
    printlock = {
        label = 'Print Lock',
        level = level,
        onSelect = function(selectedLevel)
            local cfg = {
                Mudah  = { iterations = 1, grid = 3, target = 3, duration = 10000 },
                Sedang = { iterations = 2, grid = 4, target = 5, duration = 8000  },
                Sulit  = { iterations = 3, grid = 5, target = 7, duration = 6000  },
            }
            local c = cfg[selectedLevel]
            local success = bl_ui.printLock(c.iterations, {
                grid     = c.grid,
                duration = c.duration,
                target   = c.target,
            })
            return success
        end
    },
    untangle = {
        label = 'Untangle',
        level = level,
        onSelect = function(selectedLevel)
            local cfg = {
                Mudah  = { iterations = 1, numberOfNodes = 6,  duration = 20000 },
                Sedang = { iterations = 2, numberOfNodes = 10, duration = 15000 },
                Sulit  = { iterations = 3, numberOfNodes = 14, duration = 12000 },
            }
            local c = cfg[selectedLevel]
            local success = bl_ui.untangle(c.iterations, {
                numberOfNodes = c.numberOfNodes,
                duration      = c.duration,
            })
            return success
        end
    },
    wavematch = {
        label = 'Wave Match',
        level = level,
        onSelect = function(selectedLevel)
            local cfg = {
                Mudah  = { iterations = 1, duration = 10000 },
                Sedang = { iterations = 2, duration = 7000  },
                Sulit  = { iterations = 3, duration = 5000  },
            }
            local c = cfg[selectedLevel]
            local success = bl_ui.waveMatch(c.iterations, {
                duration = c.duration,
            })
            return success
        end
    },
    wordwiz = {
        label = 'Word Wiz',
        level = level,
        onSelect = function(selectedLevel)
            local cfg = {
                Mudah  = { iterations = 1, length = 3, duration = 10000 },
                Sedang = { iterations = 2, length = 5, duration = 8000  },
                Sulit  = { iterations = 3, length = 7, duration = 6000  },
            }
            local c = cfg[selectedLevel]
            local success = bl_ui.wordWiz(c.iterations, {
                length   = c.length,
                duration = c.duration,
            })
            return success
        end
    },
    circleprogress = {
        label = 'Circle Progress',
        level = level,
        onSelect = function(selectedLevel)
            local cfg = {
                Mudah  = { iterations = 1, difficulty = 25 },
                Sedang = { iterations = 2, difficulty = 50 },
                Sulit  = { iterations = 3, difficulty = 75 },
            }
            local c = cfg[selectedLevel]
            local success = bl_ui.circleProgress(c.iterations, c.difficulty)
            return success
        end
    },
    progress = {
        label = 'Progress',
        level = level,
        onSelect = function(selectedLevel)
            local cfg = {
                Mudah  = { iterations = 1, difficulty = 25 },
                Sedang = { iterations = 2, difficulty = 50 },
                Sulit  = { iterations = 3, difficulty = 75 },
            }
            local c = cfg[selectedLevel]
            local success = bl_ui.progress(c.iterations, c.difficulty)
            return success
        end
    },
    keyspam = {
        label = 'Key Spam',
        level = level,
        onSelect = function(selectedLevel)
            local cfg = {
                Mudah  = { iterations = 1, difficulty = 25 },
                Sedang = { iterations = 2, difficulty = 50 },
                Sulit  = { iterations = 3, difficulty = 75 },
            }
            local c = cfg[selectedLevel]
            local success = bl_ui.keySpam(c.iterations, c.difficulty)
            return success
        end
    },
    keycircle = {
        label = 'Key Circle',
        level = level,
        onSelect = function(selectedLevel)
            local cfg = {
                Mudah  = { iterations = 1, difficulty = 25, numberOfKeys = 2 },
                Sedang = { iterations = 2, difficulty = 50, numberOfKeys = 4 },
                Sulit  = { iterations = 3, difficulty = 75, numberOfKeys = 6 },
            }
            local c = cfg[selectedLevel]
            local success = bl_ui.keyCircle(c.iterations, c.difficulty, c.numberOfKeys)
            return success
        end
    },
    numberslide = {
        label = 'Number Slide',
        level = level,
        onSelect = function(selectedLevel)
            local cfg = {
                Mudah  = { iterations = 1, difficulty = 25, numberOfKeys = 2 },
                Sedang = { iterations = 2, difficulty = 50, numberOfKeys = 4 },
                Sulit  = { iterations = 3, difficulty = 75, numberOfKeys = 6 },
            }
            local c = cfg[selectedLevel]
            local success = bl_ui.numberSlide(c.iterations, c.difficulty, c.numberOfKeys)
            return success
        end
    },
    rapidlines = {
        label = 'Rapid Lines',
        level = level,
        onSelect = function(selectedLevel)
            local cfg = {
                Mudah  = { iterations = 1, difficulty = 25, numberOfLines = 3 },
                Sedang = { iterations = 2, difficulty = 50, numberOfLines = 5 },
                Sulit  = { iterations = 3, difficulty = 75, numberOfLines = 7 },
            }
            local c = cfg[selectedLevel]
            local success = bl_ui.rapidLines(c.iterations, c.difficulty, c.numberOfLines)
            return success
        end
    },
    circleshake = {
        label = 'Circle Shake',
        level = level,
        onSelect = function(selectedLevel)
            local cfg = {
                Mudah  = { iterations = 1, difficulty = 25, numberOfStages = 2 },
                Sedang = { iterations = 2, difficulty = 50, numberOfStages = 3 },
                Sulit  = { iterations = 3, difficulty = 75, numberOfStages = 5 },
            }
            local c = cfg[selectedLevel]
            local success = bl_ui.circleShake(c.iterations, c.difficulty, c.numberOfStages)
            return success
        end
    },
}