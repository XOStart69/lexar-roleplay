if not interface.init() then
    return
end

local currentGamePromise = nil
local cconfig = require 'interface.bl_ui.config.client'
local exportHandler = require 'export_wrapper'

local minigame = setmetatable({}, {
    __newindex = function (self, key, fn)
        rawset(self, key, fn)
        exportHandler('bl_ui', key, fn)
    end
})

local GameTypes = cconfig.GameTypes
local Receive = cconfig.Event.Receive
local Send = cconfig.Event.Send

interface.callback(Receive.finish, function(success, cb)
    if currentGamePromise then
        currentGamePromise:resolve(success)
        currentGamePromise = nil
        interface.focus(false, false, false)
    end
    cb(1)
end)

interface.callback(Receive.close, function(_, cb)
    interface.send({
        action = Send.visible,
        data = false
    })
    interface.focus(false, false, false)
    cb(1)
end)

local function isUILoaded()
    local timeout = 5000
    local elapsedTime = 0
    local interval = 100

    while not interface.ready() and elapsedTime < timeout do
        Wait(interval)
        elapsedTime += interval
    end

    return interface.ready()
end

--- The main function to start a game
---@param gameType string The type of game to start
---@param iterations number The amount of iterations to run
---@param config BLUI_MainFunctionConfig config for the game
local function StartGame(gameType, iterations, config)
    assert(isUILoaded(), 'UI loading timeout')

    if not gameType then
        lib.print.warn("No game type provided")
        return
    end

    if currentGamePromise then
        lib.print.warn("A game is already running, please wait for it to finish before starting a new one.")
        return
    end

    currentGamePromise = promise:new()

    interface.send({
        action = Send.visible,
        data = true
    })
    interface.send({
        action = Send.start,
        data = {
            type = gameType,
            iterations = iterations or 1,
            config = config
        }
    })

    local configInput = cconfig.KeepGameInput[gameType]
    local keepGameInput = false

    if configInput ~= nil then
        keepGameInput = configInput
    end

    local configCursor = cconfig.DisplayCursor[gameType]
    local displayCursor = false

    if configCursor ~= nil then
        displayCursor = configCursor
    end

    interface.focus(true, displayCursor, keepGameInput)

    local result = Citizen.Await(currentGamePromise)
    return result
end

function minigame.CancelGame()
    if not currentGamePromise then return end
    currentGamePromise:resolve(false)
    currentGamePromise = nil
    interface.focus(false, false, false)
end

--- CircleProgress Game
---@param iterations number The amount of iterations to run
---@param difficulty number The difficulty of the game (1-100)
---@return boolean
function minigame.circleProgress(iterations, difficulty)
    local promise = promise:new()

    ---@type BLUI_DifficultyConfig
    local config = {
        difficulty = difficulty,
    }

    local result = StartGame(GameTypes.circleProgress, iterations, config)
    promise:resolve(result)

    return Citizen.Await(promise)
end

--- CircleShake Game
---@param iterations number The amount of iterations to run
---@param difficulty number The difficulty of the game (1-100)]
---@param numberOfKeys number The amount of keys to break
---@return boolean
function minigame.circleShake(iterations, difficulty, numberOfKeys)
    local promise = promise:new()

    ---@type BLUI_KeyDifficultyConfig
    local config = {
        difficulty = difficulty or 50,
        numberOfKeys = numberOfKeys or 5,
    }

    local result = StartGame(GameTypes.circleShake, iterations, config)
    promise:resolve(result)

    return Citizen.Await(promise)
end

---@param iterations number The amount of iterations to run
---@param config BLUI_LengthConfig
function minigame.circleSum(iterations, config)
    local promise = promise:new()

    local result = StartGame(GameTypes.circleSum, iterations, config)
    promise:resolve(result)

    return Citizen.Await(promise)
end

---@param iterations number The amount of iterations to run
---@param config BLUI_InputConfig
function minigame.digitDazzle(iterations, config)
    local promise = promise:new()

    local result = StartGame(GameTypes.digitDazzle, iterations, config)
    promise:resolve(result)

    return Citizen.Await(promise)
end

--- KeyCircle Game
---@param iterations number The amount of iterations to run
---@param difficulty number The difficulty of the game (1-100)]
---@param numberOfKeys number The amount of keys to press
---@return boolean
function minigame.keyCircle(iterations, difficulty, numberOfKeys)
    local promise = promise:new()

    ---@type BLUI_KeyDifficultyConfig
    local config = {
        difficulty = difficulty or 50,
        numberOfKeys = numberOfKeys or 3,
    }

    local result = StartGame(GameTypes.keyCircle, iterations, config)
    promise:resolve(result)

    return Citizen.Await(promise)
end

--- KeySpam Game
---@param iterations number The amount of iterations to run
---@param difficulty number The difficulty of the game (1-100)
---@return boolean
function minigame.keySpam(iterations, difficulty)
    local promise = promise:new()

    ---@type BLUI_DifficultyConfig
    local config = {
        difficulty = difficulty or 50,
    }

    local result = StartGame(GameTypes.keySpam, iterations, config)
    promise:resolve(result)

    return Citizen.Await(promise)
end

---@param iterations number The amount of iterations to run
---@param config BLUI_LevelConfig
function minigame.lightsOut(iterations, config)
    local promise = promise:new()

    local result = StartGame(GameTypes.lightsOut, iterations, config)
    promise:resolve(result)

    return Citizen.Await(promise)
end

---@param iterations number The amount of iterations to run
---@param config BLUI_GridConfig
function minigame.mineSweeper(iterations, config)
    local promise = promise:new()

    local result = StartGame(GameTypes.mineSweeper, iterations, config)
    promise:resolve(result)

    return Citizen.Await(promise)
end

--- NumberSlide Game
---@param iterations number The amount of iterations to run
---@param difficulty number The difficulty of the game (1-100)]
---@param numberOfKeys number The amount of keys to press
---@return boolean
function minigame.numberSlide(iterations, difficulty, numberOfKeys)
    local promise = promise:new()

    ---@type BLUI_KeyDifficultyConfig
    local config = {
        difficulty = difficulty or 50,
        numberOfKeys = numberOfKeys or 5,
    }

    local result = StartGame(GameTypes.numberSlide, iterations, config)
    promise:resolve(result)

    return Citizen.Await(promise)
end

---@param iterations number The amount of iterations to run
---@param config BLUI_NodeConfig
function minigame.pathFind(iterations, config)
    local promise = promise:new()

    local result = StartGame(GameTypes.pathFind, iterations, config)
    promise:resolve(result)

    return Citizen.Await(promise)
end

---@param iterations number The amount of iterations to run
---@param config BLUI_GridConfig
function minigame.printLock(iterations, config)
    local promise = promise:new()

    local result = StartGame(GameTypes.printLock, iterations, config)
    promise:resolve(result)

    return Citizen.Await(promise)
end

--- Progress Game
---@param iterations number The amount of iterations to run
---@param difficulty number The difficulty of the game (1-100)
---@return boolean
function minigame.progress(iterations, difficulty)
    local promise = promise:new()

    ---@type BLUI_DifficultyConfig
    local config = {
        difficulty = difficulty or 50,
    }

    local result = StartGame(GameTypes.progress, iterations, config)
    promise:resolve(result)

    return Citizen.Await(promise)
end

--- RapidLines Game
---@param iterations number The amount of iterations to run
---@param difficulty number The difficulty of the game (1-100)]
---@param numberOfLines number The amount of keys to press
---@return boolean
function minigame.rapidLines(iterations, difficulty, numberOfLines)
    local promise = promise:new()

    ---@type BLUI_KeyDifficultyConfig
    local config = {
        difficulty = difficulty or 50,
        numberOfKeys = numberOfLines or 5,
    }

    local result = StartGame(GameTypes.rapidLines, iterations, config)
    promise:resolve(result)

    return Citizen.Await(promise)
end

---@param iterations number The amount of iterations to run
---@param config BLUI_NodeConfig
function minigame.untangle(iterations, config)
    local promise = promise:new()

    local result = StartGame(GameTypes.untangle, iterations, config)
    promise:resolve(result)

    return Citizen.Await(promise)
end

---@param iterations number The amount of iterations to run
---@param config {duration: number}
function minigame.waveMatch(iterations, config)
    local promise = promise:new()

    local result = StartGame(GameTypes.waveMatch, iterations, config)
    promise:resolve(result)

    return Citizen.Await(promise)
end

---@param iterations number The amount of iterations to run
---@param config BLUI_LengthConfig
function minigame.wordWiz(iterations, config)
    local promise = promise:new()

    local result = StartGame(GameTypes.wordWiz, iterations, config)
    promise:resolve(result)

    return Citizen.Await(promise)
end

_ENV.bl_ui = minigame
