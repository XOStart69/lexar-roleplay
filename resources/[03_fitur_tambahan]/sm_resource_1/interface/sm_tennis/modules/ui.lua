local config = localmodule 'config.shared'

local BeginScaleformMovieMethod = BeginScaleformMovieMethod
local EndScaleformMovieMethod = EndScaleformMovieMethod
local ScaleformMovieMethodAddParamBool = ScaleformMovieMethodAddParamBool
local ScaleformMovieMethodAddParamFloat = ScaleformMovieMethodAddParamFloat
local DrawScaleformMovieFullscreen = DrawScaleformMovieFullscreen
local GetFrameTime = GetFrameTime

local text = config.text
local hudKeys = config.hudKeys
local tableConcat = table.concat

local TUTORIAL_ID = 'sm_tennis_tutorial'
local TOOL_ID = 'sm_tennis_tool'
local JOIN_ID = 'sm_tennis_join'
local POINT_LABEL = { [0] = '0', '15', '30', '40', 'AD' }

local ui = {}

local hudEnabled = interface.init(false)
local hudMounted = false
local hudReady = false
local hud = { side = nil, state = nil, serving = false, prompt = false }
local playKeysWithPrompt = { hudKeys.serveReady }

for i = 1, #hudKeys.play do
    playKeysWithPrompt[i + 1] = hudKeys.play[i]
end

local joinShown = false
local tutorialToken = 0
local meterHandle

---@return table
local function buildHud()
    local state = hud.state
    local serving = hud.serving
    local data = { title = text.title }

    if state and state.ready then
        local side = hud.side
        local score = state.score
        local mine, theirs = score[side], score[side == 'a' and 'b' or 'a']
        local myServe = state.server == side

        data.players = {
            { name = text.you, games = mine.games, points = POINT_LABEL[mine.points] or '-', serving = myServe },
            { name = text.opponent, games = theirs.games, points = POINT_LABEL[theirs.points] or '-', serving = not myServe },
        }
        data.serveSide = state.serveSide == 'left' and text.left or text.right
    else
        data.waiting = text.waiting
    end

    if serving then
        data.keys = hudKeys.serve
        data.hint = text.serveHint
    else
        data.keys = hud.prompt and playKeysWithPrompt or hudKeys.play

        if state and state.ready and state.canServe then
            if state.server == hud.side then
                data.hint = text.yourServe:format(state.serveSide == 'left' and text.left or text.right)
            else
                data.hint = text.opponentServe
            end
        end
    end

    return data
end

local function pushHud()
    if hudReady and hud.side then
        interface.send({ action = 'setHud', data = buildHud() })
    end
end

if hudEnabled then
    interface.callback('ready', function(_, cb)
        hudReady = true
        pushHud()
        cb('ok')
    end)
end

---@param side string
function ui.hudOpen(side)
    hud.side = side
    hud.state = nil
    hud.serving = false
    hud.prompt = false

    if not hudEnabled then return end

    if hudMounted then
        return pushHud()
    end

    hudMounted = true
    hudReady = false
    interface.show()
end

---@param state table?
---@param serving boolean
function ui.hudUpdate(state, serving)
    hud.state = state
    hud.serving = serving
    pushHud()
end

---@param show boolean
function ui.hudPrompt(show)
    if hud.prompt == show then return end
    hud.prompt = show
    if not hud.serving then
        pushHud()
    end
end

function ui.hudClose()
    hud.side = nil
    hud.state = nil
    hud.prompt = false

    if hudMounted then
        hudMounted = false
        hudReady = false
        interface.hide()
    end
end

---@param show boolean
function ui.joinPrompt(show)
    if show == joinShown then return end
    joinShown = show

    if not show then
        return infoUI.remove(JOIN_ID)
    end

    infoUI.show({
        id = JOIN_ID,
        title = text.title,
        icon = 'fa-solid fa-table-tennis-paddle-ball',
        description = text.joinPrompt,
    })
end

---@param message string
---@param nType string?
function ui.notify(message, nType)
    lib.notify({ title = text.title, description = message, type = nType or 'info' })
end

function ui.toggleTutorial()
    tutorialToken += 1

    if tutorialToken % 2 == 0 then
        return infoUI.remove(TUTORIAL_ID)
    end

    local token = tutorialToken

    infoUI.show({
        id = TUTORIAL_ID,
        title = 'Tutorial Tenis',
        icon = 'fa-solid fa-circle-question',
        description = tableConcat(config.tutorial, '\n'),
    })

    SetTimeout(config.tutorialDuration, function()
        if tutorialToken ~= token then return end
        tutorialToken += 1
        infoUI.remove(TUTORIAL_ID)
    end)
end

---@param show boolean
function ui.toolCard(show)
    if not show then
        return infoUI.remove(TOOL_ID)
    end

    infoUI.show({
        id = TOOL_ID,
        title = 'Tennis Court Tool',
        icon = 'fa-solid fa-ruler-combined',
        description = text.toolControls,
    })
end

function ui.clear()
    ui.joinPrompt(false)
    ui.hudClose()
    infoUI.remove(TOOL_ID)
    if tutorialToken % 2 == 1 then
        tutorialToken += 1
        infoUI.remove(TUTORIAL_ID)
    end
end

local function setMarker(handle, marker)
    BeginScaleformMovieMethod(handle, 'SWING_METER_SET_MARKER')
    ScaleformMovieMethodAddParamBool(true)
    ScaleformMovieMethodAddParamFloat(marker)
    ScaleformMovieMethodAddParamBool(false)
    ScaleformMovieMethodAddParamFloat(-0.25)
    EndScaleformMovieMethod()

    BeginScaleformMovieMethod(handle, 'SWING_METER_SET_APEX_MARKER')
    ScaleformMovieMethodAddParamBool(true)
    ScaleformMovieMethodAddParamFloat(marker + 0.002)
    ScaleformMovieMethodAddParamBool(false)
    ScaleformMovieMethodAddParamFloat(-0.25)
    EndScaleformMovieMethod()
end

---@return boolean
function ui.loadMeter()
    if meterHandle then return true end

    local handle = lib.requestScaleformMovie('TENNIS', 3000)
    if not handle then return false end

    meterHandle = handle
    return true
end

function ui.releaseMeter()
    if not meterHandle then return end
    SetScaleformMovieAsNoLongerNeeded(meterHandle)
    meterHandle = nil
end

---@return table?
function ui.openMeter()
    if not meterHandle then return nil end

    local handle = meterHandle
    BeginScaleformMovieMethod(handle, 'SWING_METER_TRANSITION_IN')
    EndScaleformMovieMethod()

    BeginScaleformMovieMethod(handle, 'SWING_METER_SET_FILL')
    ScaleformMovieMethodAddParamFloat(0.5)
    ScaleformMovieMethodAddParamFloat(1.0)
    EndScaleformMovieMethod()

    BeginScaleformMovieMethod(handle, 'SWING_METER_SET_TARGET')
    ScaleformMovieMethodAddParamFloat(0.7)
    ScaleformMovieMethodAddParamFloat(0.1)
    EndScaleformMovieMethod()

    BeginScaleformMovieMethod(handle, 'SWING_METER_POSITION')
    ScaleformMovieMethodAddParamFloat(0.7)
    ScaleformMovieMethodAddParamFloat(0.5)
    ScaleformMovieMethodAddParamBool(true)
    EndScaleformMovieMethod()

    setMarker(handle, 1.0)

    return { active = false, progress = 1.0, speed = 0.3, acceleration = 1.0, peaked = false, strength = nil }
end

---@param meter table
function ui.tickMeter(meter)
    if not meterHandle then return end

    if meter.active then
        local dt = GetFrameTime()
        meter.progress -= meter.speed * dt
        meter.speed += meter.acceleration * dt

        if meter.progress <= 0.0 then
            meter.speed = -meter.speed
            meter.acceleration = -meter.acceleration
            meter.peaked = true
        end

        if meter.peaked and meter.progress >= 0.75 then
            meter.active = false
            meter.strength = 0.25
        end
    end

    setMarker(meterHandle, meter.progress)
    DrawScaleformMovieFullscreen(meterHandle, 255, 255, 255, 255, 0)
end

function ui.closeMeter()
    if not meterHandle then return end
    BeginScaleformMovieMethod(meterHandle, 'SWING_METER_TRANSITION_OUT')
    ScaleformMovieMethodAddParamFloat(0.0)
    EndScaleformMovieMethod()
end

return ui
