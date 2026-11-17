local IT = {}
local LOAD_TIMEOUT_MS = 10000
local RETURN_TIMEOUT_MS = 2000

---@class IT_HorseStyle
---@field [1] integer
---@field [2] integer
---@field [3] integer
---@field [4] integer

---@class IT_Horse
---@field nameKey string
---@field oddsStr string?
---@field style IT_HorseStyle

---@class IT_Bettor
---@field name string?
---@field bet integer?

---@class IT_ResultEntry
---@field name string?
---@field horse integer?
---@field bet integer?
---@field won boolean?
---@field payout integer?

IT.SCREEN_MAIN = 0
IT.SCREEN_SELECT = 1
IT.SCREEN_SELECT_MAIN = 2
IT.SCREEN_BET = 3
IT.SCREEN_BET_MAIN = 4
IT.SCREEN_RESULTS = 7
IT.SCREEN_RULES = 9
IT.SCREEN_WALL_MAIN = 5   -- horse grid / betting view
IT.SCREEN_WALL_DETAIL = 1   -- detail kuda (zoom view)
IT.SCREEN_WALL_RESULTS = 4   -- podium + leaderboard hasil
IT.SCREEN_WALL_INTERMISSION = 5   -- jeda antar round / refresh
IT._phase = 'results' ---@type 'idle' | 'open' | 'presentation' | 'racing' | 'results'
IT._mainBetPlaced = false
---@param phase string
---@param mainBetPlaced boolean
function IT.SetState(phase, mainBetPlaced)
    IT._phase = phase or 'results'
    IT._mainBetPlaced = mainBetPlaced == true
end
local function PushVoid(sf, method)
    BeginScaleformMovieMethod(sf, method)
    EndScaleformMovieMethod()
end

local function PushInt(sf, method, val)
    BeginScaleformMovieMethod(sf, method)
    ScaleformMovieMethodAddParamInt(val)
    EndScaleformMovieMethod()
end

local function PushBool(sf, method, val)
    BeginScaleformMovieMethod(sf, method)
    ScaleformMovieMethodAddParamBool(val)
    EndScaleformMovieMethod()
end

local function CommaValue(n)
    local s = tostring(math.floor(n))
    return (s:reverse():gsub('(%d%d%d)', '%1,'):reverse():gsub('^,', ''))
end

---@param name string
---@return integer
local function LoadScaleform(name)
    local sf = RequestScaleformMovie(name)
    local timeout = GetGameTimer() + LOAD_TIMEOUT_MS

    while not HasScaleformMovieLoaded(sf) and GetGameTimer() < timeout do
        Wait(0)
    end

    if HasScaleformMovieLoaded(sf) then return sf end

    SetScaleformMovieAsNoLongerNeeded(sf)
    return -1
end

---@param returnValue integer
---@return boolean
local function WaitForReturnValue(returnValue)
    local timeout = GetGameTimer() + RETURN_TIMEOUT_MS

    while not IsScaleformMovieMethodReturnValueReady(returnValue)
        and GetGameTimer() < timeout
    do
        Wait(0)
    end

    return IsScaleformMovieMethodReturnValueReady(returnValue)
end

---@return integer sf
function IT.LoadConsole()
    return LoadScaleform('HORSE_RACING_CONSOLE')
end

---@return integer sf
function IT.LoadWall()
    return LoadScaleform('HORSE_RACING_WALL')
end

---@param sf integer
---@param screenId integer
---@param prevScreen integer|nil
function IT.ShowScreen(sf, screenId, prevScreen)
    if prevScreen ~= nil and prevScreen == screenId then
        PushInt(sf, 'SHOW_SCREEN', 5)
    end
    PushInt(sf, 'SHOW_SCREEN', screenId)
end

---@param sf integer
function IT.CleanUp(sf)
    PushVoid(sf, 'CLEAR_ALL_PLAYERS')
    PushVoid(sf, 'CLEAR_ALL')
end

---@param sf integer
function IT.ClearAll(sf)
    PushVoid(sf, 'CLEAR_ALL')
end

---@param sf integer
---@param locked boolean
function IT.LockMainEvent(sf, locked)
    PushBool(sf, 'SET_MAIN_EVENT_IN_PROGRESS', locked)
end

---@param sf integer
---@param enabled boolean
function IT.ToggleBetting(sf, enabled)
    if IT._phase == 'racing' and not IT._mainBetPlaced then
        enabled = false
        IT.LockMainEvent(sf, true)
    end
    PushBool(sf, 'SET_BETTING_ENABLED', enabled)
end

---@param sf integer
---@param seconds integer
function IT.SetCountdown(sf, seconds)
    if IT._phase ~= 'open' then
        seconds = 0
    end
    PushInt(sf, 'SET_COUNTDOWN', seconds)
end

---@param sf integer
---@param horses IT_Horse[]
function IT.SetHorses(sf, horses)
    for slot = 1, 6 do
        local h = horses[slot]
        local style = h.style
        BeginScaleformMovieMethod(sf, 'SET_HORSE')
        ScaleformMovieMethodAddParamInt(slot)
        BeginTextCommandScaleformString(h.nameKey)
        EndTextCommandScaleformString()
        ScaleformMovieMethodAddParamPlayerNameString(h.oddsStr or '2/1')
        ScaleformMovieMethodAddParamInt(style[1])
        ScaleformMovieMethodAddParamInt(style[2])
        ScaleformMovieMethodAddParamInt(style[3])
        ScaleformMovieMethodAddParamInt(style[4])
        EndScaleformMovieMethod()
    end
end

---@param sf integer
---@param horse integer
---@param bet integer
---@param balance integer
---@param gain integer
function IT.SetBettingValues(sf, horse, bet, balance, gain)
    BeginScaleformMovieMethod(sf, 'SET_BETTING_VALUES')
    ScaleformMovieMethodAddParamInt(horse)
    PushScaleformMovieMethodParameterString(CommaValue(bet))
    PushScaleformMovieMethodParameterString(CommaValue(balance))
    PushScaleformMovieMethodParameterString(CommaValue(gain))
    EndScaleformMovieMethod()
end

---@param sf integer
---@param horse integer
---@param bet integer
---@param balance integer
---@param gain integer
function IT.ResetBettingValues(sf, horse, bet, balance, gain)
    BeginScaleformMovieMethod(sf, 'SET_BETTING_VALUES')
    ScaleformMovieMethodAddParamInt(horse)
    ScaleformMovieMethodAddParamInt(bet)
    ScaleformMovieMethodAddParamInt(balance)
    ScaleformMovieMethodAddParamInt(gain)
    EndScaleformMovieMethod()
end

---@param sf integer
---@param duration number
---@param order integer[]
function IT.StartRace(sf, duration, order)
    BeginScaleformMovieMethod(sf, 'START_RACE')
    ScaleformMovieMethodAddParamFloat(duration * 1.0)
    ScaleformMovieMethodAddParamInt(1)
    for i = 1, 6 do
        ScaleformMovieMethodAddParamInt(order[i])
    end
    ScaleformMovieMethodAddParamFloat(0.0)
    ScaleformMovieMethodAddParamBool(false)
    EndScaleformMovieMethod()
end

---@param sf integer
---@return boolean
function IT.IsRaceFinished(sf)
    BeginScaleformMovieMethod(sf, 'GET_RACE_IS_COMPLETE')
    local rv = EndScaleformMovieMethodReturnValue()
    if not WaitForReturnValue(rv) then return false end
    return GetScaleformMovieMethodReturnValueBool(rv)
end

---@param sf integer
---@return integer[]
function IT.GetHorsePositions(sf)
    local positions = {}
    BeginScaleformMovieMethod(sf, 'GET_HORSE_POSITIONS')
    local rv = EndScaleformMovieMethodReturnValue()
    if not WaitForReturnValue(rv) then return positions end
    local packed = GetScaleformMovieMethodReturnValueInt(rv)
    if packed ~= -1 then
        for i = 6, 1, -1 do
            table.insert(positions, tonumber(string.sub(tostring(packed), i, i)) or 0)
        end
    end
    return positions
end

---@param sf integer
---@return integer button
function IT.GetClickedButton(sf)
    CallScaleformMovieMethodWithNumber(sf, 'SET_INPUT_EVENT',
        237.0, -1082130432, -1082130432, -1082130432, -1082130432)
    BeginScaleformMovieMethod(sf, 'GET_CURRENT_SELECTION')
    local rv = EndScaleformMovieMethodReturnValue()
    if not WaitForReturnValue(rv) then return -1 end
    return GetScaleformMovieMethodReturnValueInt(rv)
end

---@param sf integer
---@param title string
---@param message string|nil
function IT.ShowError(sf, title, message)
    BeginScaleformMovieMethod(sf, 'SHOW_ERROR')
    ScaleformMovieMethodAddParamPlayerNameString(title or '')
    ScaleformMovieMethodAddParamPlayerNameString(message or '')
    EndScaleformMovieMethod()
end

---@param sf integer
---@param gamertag string
---@param horse integer
---@param bet integer
function IT.AddPlayer(sf, gamertag, horse, bet)
    BeginScaleformMovieMethod(sf, 'ADD_PLAYER')
    ScaleformMovieMethodAddParamPlayerNameString(gamertag or 'Unknown')
    ScaleformMovieMethodAddParamInt(tonumber(horse) or 1)
    ScaleformMovieMethodAddParamInt(tonumber(bet) or 0)
    EndScaleformMovieMethod()
end

---@param sf integer
---@param gamertag string
function IT.RemovePlayer(sf, gamertag)
    BeginScaleformMovieMethod(sf, 'REMOVE_PLAYER')
    ScaleformMovieMethodAddParamPlayerNameString(gamertag or '')
    EndScaleformMovieMethod()
end

---@param sf integer
---@param gamertag string
---@param result string|integer
function IT.SetPlayerResult(sf, gamertag, result)
    BeginScaleformMovieMethod(sf, 'SET_PLAYER_RESULT')
    ScaleformMovieMethodAddParamPlayerNameString(gamertag or '')
    if type(result) == 'number' then
        ScaleformMovieMethodAddParamInt(result)
    else
        PushScaleformMovieMethodParameterString(tostring(result or ''))
    end
    EndScaleformMovieMethod()
end

---@param sf integer
---@param number integer
function IT.SetDetailHorse(sf, number)
    PushInt(sf, 'SET_DETAIL_HORSE', tonumber(number) or 0)
end

---@param sf integer
---@param isSingleRace boolean
function IT.SetRaceType(sf, isSingleRace)
    PushBool(sf, 'SET_RACE_TYPE', isSingleRace == true)
end

---@param sf integer
function IT.ClearPlayers(sf)
    PushVoid(sf, 'CLEAR_ALL_PLAYERS')
end

---@param sf integer
---@param horseSlot integer
---@param bettors IT_Bettor[]
function IT.FocusHorseOnBigScreen(sf, horseSlot, bettors)
    IT.SetDetailHorse(sf, horseSlot)
    if not bettors then return end
    for i = 1, #bettors do
        local b = bettors[i]
        IT.AddPlayer(sf, b.name or 'Unknown', horseSlot, b.bet or 0)
    end
end

---@param sf integer
---@param entries IT_ResultEntry[]
---@param prevScreen integer|nil
function IT.ShowResultsOnBigScreen(sf, entries, prevScreen)
    PushInt(sf, 'SHOW_SCREEN', 5)
    IT.ClearPlayers(sf)
    if entries then
        for i = 1, #entries do
            local e = entries[i]
            IT.AddPlayer(sf, e.name or 'Unknown', e.horse or 1, e.bet or 0)
            local net
            if e.won then
                net = (e.payout or 0) - (e.bet or 0)
                if net <= 0 then net = e.payout or 0 end
            else
                net = -(e.bet or 0)
            end
            IT.SetPlayerResult(sf, e.name or 'Unknown', net)
        end
    end
    PushInt(sf, 'SHOW_SCREEN', IT.SCREEN_WALL_RESULTS)
end
return IT
