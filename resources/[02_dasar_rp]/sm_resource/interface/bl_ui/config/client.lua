local config = {}

config.GameTypes = {
    circleProgress = "CircleProgress",
    progress = "Progress",
    keyCircle = "KeyCircle",
    keySpam = "KeySpam",
    numberSlide = "NumberSlide",
    rapidLines = "RapidLines",
    circleShake = "CircleShake",
    pathFind = "PathFind",

    circleSum = "CircleSum",
    digitDazzle = "DigitDazzle",
    -- hexaPipe = "HexaPipe",
    lightsOut = "LightsOut",
    mineSweeper = "MineSweeper",
    printLock = "PrintLock",
    untangle = "Untangle",
    waveMatch = "WaveMatch",
    wordWiz = "WordWiz",
}

config.KeepGameInput = {
    [config.GameTypes.circleProgress] = true,
    [config.GameTypes.progress] = true,
    [config.GameTypes.keySpam] = true,
    [config.GameTypes.numberSlide] = true,
    [config.GameTypes.rapidLines] = true,
}

config.DisplayCursor = {
    [config.GameTypes.circleShake] = true,
    [config.GameTypes.pathFind] = true,
    [config.GameTypes.circleSum] = true,
    [config.GameTypes.digitDazzle] = true,
    [config.GameTypes.lightsOut] = true,
    [config.GameTypes.mineSweeper] = true,
    [config.GameTypes.printLock] = true,
    [config.GameTypes.untangle] = true,
    [config.GameTypes.waveMatch] = true,
    [config.GameTypes.wordWiz] = true,
}

config.Event = {
    Send = {
        visible = "ui:visible",
        start = "ui:start",
    },

    Receive = {
        close = "ui:close",
        finish = "ui:finish",
        uiLoaded = 'ui:loaded',
    }
}

return config