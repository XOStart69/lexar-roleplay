local KEY_PAUSE <const> = 199
local KEY_ESC <const> = 200
local KEY_BACK <const> = 194
local KEY_LEFT_CLICK <const> = 237
local BTN_PLACE_BET_MAIN <const> = 0
local BTN_PLACE_BET_SINGLE <const> = 1
local BTN_PLACE_BET_ALT <const> = 14
local BTN_BET_UP <const> = 8
local BTN_BET_DOWN <const> = 9
local BTN_CONFIRM <const> = 10
local BTN_CLOSE <const> = 12
local BTN_BACK <const> = 13
local BTN_RULES <const> = 15
local PHASE_MAIN <const> = 'main'
local PHASE_SELECT <const> = 'select'
local PHASE_BET <const> = 'bet'
local PHASE_RACE <const> = 'race'
local PHASE_RULES <const> = 'rules'
local PHASE_VIEW <const> = 'view'
local PHASE_LOCKED <const> = 'locked'
local MODE_MAIN_EVENT <const> = 'main'
local MODE_SINGLE <const> = 'single'
local console = {
    sf = -1,
    active = false,
    phase = PHASE_MAIN,
    horseIndex = -1,
    bet = 100,
    odds = 2.0,
    balance = 0,
    raceSoundId = -1,
    mainBetPlaced = false,
    raceLocked = false,
}
local mainSync = {
    roundId = 0,
    phase = 'idle',
    timer = 0,
    perHorse = { {}, {}, {}, {}, {}, {} },
}
local seatSession = {
    active = false,
    tIndex = nil,
}
local big = {
    sf = -1,
    target = -1,
    loaded = false,
    rendering = false,
    podiumShown = false,
    raceStarted = false,
    intermissionShown = false,
    cycleSegment = -1,
}
local IT = require 'casino.insidetrack.modules.scaleform'
local config = require 'casino.insidetrack.config'
local Horses = require 'casino.insidetrack.modules.horses'
local Anim = require 'casino.insidetrack.modules.animation'
local Ambient = require 'casino.insidetrack.modules.ambient'
local chairs = require 'casino.insidetrack.data.chairs'
local inBettingArea = false
local currentScreen = IT.SCREEN_MAIN
local sitDown, standUp, closeInsideTrack,
    handleClick, startSingleRace, placeMainBet,
    refreshConsoleMain, enterBetView, openInsideTrack
---@param sf integer
---@param newScreen integer
local function switchScreen(sf, newScreen)
    IT.ShowScreen(sf, newScreen, currentScreen)
    currentScreen = newScreen
end
---Loads and initializes the big screen wall scaleform with current race state.
local function bigScreenLoad()
    local cfg = config.BigScreen
    if not IsNamedRendertargetRegistered(cfg.renderTarget) then
        RegisterNamedRendertarget(cfg.renderTarget, false)
    end
    if not IsNamedRendertargetLinked(cfg.objectModel) then
        LinkNamedRendertarget(cfg.objectModel)
    end
    big.target = GetNamedRendertargetRenderId(cfg.renderTarget)
    big.sf = IT.LoadWall()
    if big.sf == -1 then
        ReleaseNamedRendertarget(cfg.renderTarget)
        big.target = -1
        return
    end

    SetScaleformFitRendertarget(big.sf, true)
    IT.SetHorses(big.sf, Horses.buildClient(mainSync.horses))
    IT.SetState(mainSync.phase, false)
    IT.LockMainEvent(big.sf, mainSync.phase ~= 'open')
    IT.ToggleBetting(big.sf, mainSync.phase == 'open')
    IT.SetCountdown(big.sf, mainSync.timer)
    IT.ShowScreen(big.sf, IT.SCREEN_WALL_MAIN, nil)
    big.loaded = true
    big.podiumShown = false
    big.raceStarted = false
    big.intermissionShown = false
    big.currentScreen = IT.SCREEN_WALL_MAIN
    big.cycleSegment = -1
end
local function bigScreenUnload()
    big.loaded = false
    big.rendering = false
    big.podiumShown = false
    big.raceStarted = false
    big.intermissionShown = false
    big.currentScreen = nil
    big.cycleSegment = -1
    if big.sf ~= -1 then
        SetScaleformMovieAsNoLongerNeeded(big.sf)
        big.sf = -1
    end
end
local function bigScreenSync()
    if not big.loaded or big.sf == -1 then return end
    local p = mainSync.phase
    IT.SetState(p, false)
    IT.LockMainEvent(big.sf, p ~= 'open')
    IT.ToggleBetting(big.sf, p == 'open')
    IT.SetCountdown(big.sf, p == 'open' and mainSync.timer or 0)
    if p == 'open' then
        if big.raceStarted or big.podiumShown or big.intermissionShown then
            big.raceStarted = false
            big.podiumShown = false
            big.intermissionShown = false
            IT.CleanUp(big.sf)
            big.cycleSegment = -1
        end
        if mainSync.horses then
            IT.SetHorses(big.sf, Horses.buildClient(mainSync.horses))
        end
        local cycleSecs = (config.MainEvent and config.MainEvent.cycleSeconds) or 5
        local elapsed = (config.MainEvent.betWindowSeconds or 60) - (mainSync.timer or 0)
        if elapsed < 0 then elapsed = 0 end
        local segIdx = math.floor(elapsed / cycleSecs)
        if segIdx ~= big.cycleSegment then
            big.cycleSegment = segIdx
            local pos = segIdx % 12
            local isDetail = (pos % 2) == 1
            if isDetail then
                local horseSlot = math.floor(pos / 2) + 1
                IT.FocusHorseOnBigScreen(big.sf, horseSlot, mainSync.perHorse and mainSync.perHorse[horseSlot])
                if big.currentScreen ~= IT.SCREEN_WALL_DETAIL then
                    IT.ShowScreen(big.sf, IT.SCREEN_WALL_DETAIL, big.currentScreen)
                    big.currentScreen = IT.SCREEN_WALL_DETAIL
                end
            else
                IT.SetDetailHorse(big.sf, 0)
                if big.currentScreen ~= IT.SCREEN_WALL_MAIN then
                    IT.ShowScreen(big.sf, IT.SCREEN_WALL_MAIN, big.currentScreen)
                    big.currentScreen = IT.SCREEN_WALL_MAIN
                end
            end
        end
    elseif p == 'racing' and mainSync.raceOrder then
        if not big.raceStarted then
            big.raceStarted = true
            big.podiumShown = false
            big.intermissionShown = false
            big.cycleSegment = -1
            IT.SetDetailHorse(big.sf, 0)
            if mainSync.horses then
                IT.SetHorses(big.sf, Horses.buildClient(mainSync.horses))
            end
            if big.currentScreen ~= IT.SCREEN_WALL_MAIN then
                IT.ShowScreen(big.sf, IT.SCREEN_WALL_MAIN, big.currentScreen)
                big.currentScreen = IT.SCREEN_WALL_MAIN
            end
            if mainSync.perHorse then
                for hi = 1, 6 do
                    local list = mainSync.perHorse[hi] or {}
                for i = 1, #list do
                        IT.AddPlayer(big.sf, list[i].name or 'Unknown', hi, list[i].bet or 0)
                    end
                end
            end
            IT.StartRace(big.sf, config.RaceDuration, mainSync.raceOrder)
        end
    elseif p == 'results' then
        if not big.podiumShown then
            big.podiumShown = true
            big.intermissionShown = false
            big.cycleSegment = -1
            local entries = {}
            for hi = 1, 6 do
                local list = mainSync.perHorse and mainSync.perHorse[hi] or {}
                for i = 1, #list do
                    local b = list[i]
                    local won = (hi == mainSync.winner)
                    local entry = { name = b.name, horse = hi, bet = b.bet, won = won }
                    if won then
                        local oddsR = config.HorseOdds[hi]
                        local oddsAvg = oddsR and ((oddsR.min + oddsR.max) / 2) or 2.0
                        entry.payout = math.floor((b.bet or 0) * oddsAvg)
                    end
                    entries[#entries + 1] = entry
                end
            end
            IT.ShowResultsOnBigScreen(big.sf, entries, big.currentScreen)
            big.currentScreen = IT.SCREEN_WALL_RESULTS
        end
    elseif p == 'intermission' then
        if not big.intermissionShown then
            big.intermissionShown = true
            big.podiumShown = false
            big.raceStarted = false
            big.cycleSegment = -1
            IT.CleanUp(big.sf)
            if big.currentScreen ~= IT.SCREEN_WALL_INTERMISSION then
                IT.ShowScreen(big.sf, IT.SCREEN_WALL_INTERMISSION, big.currentScreen)
                big.currentScreen = IT.SCREEN_WALL_INTERMISSION
            end
        end
    elseif p == 'idle' then
        if big.currentScreen ~= IT.SCREEN_WALL_MAIN then
            IT.ShowScreen(big.sf, IT.SCREEN_WALL_MAIN, big.currentScreen)
            big.currentScreen = IT.SCREEN_WALL_MAIN
        end
    end
end

---Plays a full race animation on the console scaleform and shows results on completion.
---@param raceOrder integer[]
---@param lockClose boolean
---@param onFinish fun()?
local function playRaceOnConsole(raceOrder, lockClose, onFinish)
    if not console.active or console.sf == -1 then return end
    console.phase = PHASE_RACE
    console.raceLocked = lockClose == true
    IT.StartRace(console.sf, config.RaceDuration, raceOrder)
    console.raceSoundId = GetSoundId()
    PlaySoundFrontend(console.raceSoundId, config.RaceSound, config.RaceAudioBank, false)
    Ambient.spawnRaceAnnouncer(raceOrder, false, function()
        return console.active and console.phase == PHASE_RACE
    end)
    CreateThread(function()
        local timeout = GetGameTimer() + config.RaceDuration + 8000
        while console.active and GetGameTimer() < timeout do
            if IT.IsRaceFinished(console.sf) then break end
            Wait(150)
        end
        if console.raceSoundId ~= -1 then
            StopSound(console.raceSoundId)
            ReleaseSoundId(console.raceSoundId)
            console.raceSoundId = -1
        end
        if not console.active then return end
        IT.ClearPlayers(console.sf)
        if console.mode == MODE_MAIN_EVENT and mainSync.perHorse then
            for hi = 1, 6 do
                local list = mainSync.perHorse[hi] or {}
                for i = 1, #list do
                    local b = list[i]
                    local bname = b.name or 'Unknown'
                    local bbet = b.bet or 0
                    IT.AddPlayer(console.sf, bname, hi, bbet)
                    local net
                    if mainSync.winner and hi == mainSync.winner then
                        local oddsR = config.HorseOdds[hi]
                        local oddsAvg = oddsR and ((oddsR.min + oddsR.max) / 2) or 2.0
                        local payout = math.floor(bbet * oddsAvg)
                        net = payout - bbet
                        if net <= 0 then net = payout end
                    else
                        net = -bbet
                    end
                
                    IT.SetPlayerResult(console.sf, bname, net)
                end
            end
        elseif console.mode == MODE_SINGLE then
            local myName = GetPlayerName(cache.playerId) or 'You'
            IT.AddPlayer(console.sf, myName, console.horseIndex, console.bet)
        end
        IT.ShowScreen(console.sf, IT.SCREEN_RESULTS)
        console.raceLocked = false
        if onFinish then onFinish() end
        Wait(4000)
        if console.active then
            refreshConsoleMain()
        end
    end)
end

local function seatKeyThread()
    local info = [[
    [kbd]E[/kbd] - Open Inside Track
    [kbd]Backspace[/kbd] - Stand up
    ]]
    infoUI:show({
        id = 'insidetrack_seat',
        title = 'Inside Track',
        icon = 'fas fa-horse',
        description = info
    })
    CreateThread(function (threadId)
        local showInfo = true
        while seatSession.active do
            local sleep = 500
            if not console.active then
                sleep = 0
                if not showInfo then
                    infoUI:show({
                        id = 'insidetrack_seat',
                        title = 'Inside Track',
                        icon = 'fas fa-horse',
                        description = info
                    })
                    showInfo = true
                end
                DisableControlAction(0, KEY_PAUSE, true)
                DisableControlAction(0, KEY_ESC, true)
                DisableControlAction(0, KEY_BACK, true)
                if IsDisabledControlJustPressed(0, KEY_BACK) then
                    standUp()
                elseif IsDisabledControlJustPressed(0, 38) then
                    openInsideTrack()
                end
            else
                if showInfo then
                    infoUI:remove('insidetrack_seat')
                    showInfo = false
                end
            end
            Wait(sleep)
        end
        infoUI:remove('insidetrack_seat')
    end)
end

refreshConsoleMain = function()
    if not console.active or console.sf == -1 then return end
    console.mode = nil
    console.horseIndex = -1
    local p = mainSync.phase
    if console.mainBetPlaced
       and (p == 'racing' or p == 'results' or p == 'intermission') then
        console.phase = PHASE_LOCKED
        IT.CleanUp(console.sf)
        IT.SetState(p, true)
        IT.LockMainEvent(console.sf, true)
        IT.ToggleBetting(console.sf, false)
        IT.SetCountdown(console.sf, 0)
        currentScreen = IT.SCREEN_MAIN
        IT.ShowScreen(console.sf, IT.SCREEN_MAIN, nil)
        return
    end
    console.phase = PHASE_MAIN
    IT.CleanUp(console.sf)
    IT.SetState(p, console.mainBetPlaced)
    IT.LockMainEvent(console.sf, p ~= 'open')
    IT.ToggleBetting(console.sf, p == 'open' and not console.mainBetPlaced)
    IT.SetHorses(console.sf, console.horses or Horses.buildClient(mainSync.horses))
    IT.SetCountdown(console.sf, p == 'open' and mainSync.timer or 0)
    if console.mainBetPlaced and console.myMainBet then
        local bet = console.myMainBet.bet  or 0
        local odds = console.myMainBet.odds or 2.0
        local gain = math.floor(bet * odds)
        IT.ResetBettingValues(console.sf,
            console.myMainBet.horseIndex or 0,
            bet, console.balance, gain)
        IT.ToggleBetting(console.sf, false)
    end
    currentScreen = IT.SCREEN_MAIN
    IT.ShowScreen(console.sf, IT.SCREEN_MAIN, nil)
end

sitDown = function(tIndex)
    if seatSession.active then return end
    local chairPos = chairs[tIndex]
    if not chairPos then return end
    seatSession.active = true
    seatSession.tIndex = tIndex
    Anim.setup(chairPos, config.ChairHeading)
    Anim.enter(seatKeyThread)
end

standUp = function()
    if not seatSession.active then return end
    local tIndex = seatSession.tIndex
    seatSession.active = false
    seatSession.tIndex = nil
    Anim.exit(function()
        TriggerServerEvent('rhd_casino_insidetrack:releaseSeat', tIndex)
    end)
end

openInsideTrack = function(tIndex)
    if console.active then return end
    local canOpen, myBet = lib.callback.await('rhd_casino_insidetrack:canOpen')
    if not canOpen then
        return
    end
    local balance = ox_inventory:GetItemCount(shared.chipItemName) or 0
    console.balance = balance
    console.bet = config.BetMin
    console.horseIndex = -1
    console.mode = nil
    console.phase = PHASE_MAIN
    console.mainBetPlaced = myBet ~= nil
    console.myMainBet = myBet
    console.active = true
    console.raceLocked = false
    DisplayHud(false)
    SetPlayerControl(cache.playerId, false, 0)

    pcall(function()
        local hud = exports.sm_hud
        hud:setComponentVisible('compass', false)
        hud:setComponentVisible('information', false)
        hud:setComponentVisible('healthArmor', false)
    end)

    Ambient.loadBank()
    console.sf = IT.LoadConsole()
    if console.sf == -1 then
        lib.notify({
            title = 'Inside Track',
            description = 'Tampilan Inside Track gagal dimuat. Silakan coba lagi.',
            type = 'error',
        })
        closeInsideTrack()
        return
    end

    local horsesShow = Horses.buildClient(mainSync.horses)
    console.horses = horsesShow
    IT.SetState(mainSync.phase, console.mainBetPlaced)
    IT.LockMainEvent(console.sf, mainSync.phase ~= 'open')
    IT.CleanUp(console.sf)
    IT.ToggleBetting(console.sf, mainSync.phase == 'open' and not console.mainBetPlaced)
    IT.SetHorses(console.sf, horsesShow)
    IT.SetCountdown(console.sf, mainSync.timer)
    if console.mainBetPlaced and console.myMainBet then
        local bet = console.myMainBet.bet  or 0
        local odds = console.myMainBet.odds or 2.0
        local gain = math.floor(bet * odds)
        IT.ResetBettingValues(console.sf,
            console.myMainBet.horseIndex or 0,
            bet, console.balance, gain)
        IT.ToggleBetting(console.sf, false)
    end
    currentScreen = IT.SCREEN_MAIN
    IT.ShowScreen(console.sf, IT.SCREEN_MAIN, IT.SCREEN_MAIN)
    if console.mainBetPlaced
       and (mainSync.phase == 'racing'
            or mainSync.phase == 'results'
            or mainSync.phase == 'intermission') then
        console.phase = PHASE_LOCKED
    end
    CreateThread(function()
        while console.active do
            Wait(0)
            if console.sf ~= -1 then
                local mouseX = GetDisabledControlNormal(2, 239)
                local mouseY = GetDisabledControlNormal(2, 240)
                BeginScaleformMovieMethod(console.sf, 'SET_MOUSE_INPUT')
                ScaleformMovieMethodAddParamFloat(mouseX)
                ScaleformMovieMethodAddParamFloat(mouseY)
                EndScaleformMovieMethod()
                DrawScaleformMovieFullscreen(console.sf, 255, 255, 255, 255, 0)
            end
        end
    end)
    CreateThread(function()
        while console.active do
            Wait(0)
            DisableAllControlActions(0)
            
            EnableControlAction(0, 249, true)
            EnableControlAction(0, KEY_LEFT_CLICK, true)
            if not console.raceLocked then
                EnableControlAction(0, KEY_ESC, true)
                EnableControlAction(0, KEY_BACK, true)
                if IsDisabledControlJustPressed(0, KEY_ESC) or
                   IsDisabledControlJustPressed(0, KEY_BACK) then
                    closeInsideTrack()
                    break
                end
            else
                DisableControlAction(0, KEY_ESC, true)
                DisableControlAction(0, KEY_BACK, true)
            end
            if IsDisabledControlJustPressed(0, KEY_LEFT_CLICK) then
                if console.sf ~= -1 then
                    local btn = IT.GetClickedButton(console.sf)
                    if btn and btn ~= -1 then
                        handleClick(btn)
                    end
                end
            end
        end
    end)
end

closeInsideTrack = function()
    if not console.active then return end
    if console.raceLocked then return end
    console.active = false
    DisplayHud(true)
    SetPlayerControl(cache.playerId, true, 0)
    EnableAllControlActions(0)
    if console.sf ~= -1 then
        IT.CleanUp(console.sf)
        IT.ShowScreen(console.sf, IT.SCREEN_MAIN, IT.SCREEN_MAIN)
        SetScaleformMovieAsNoLongerNeeded(console.sf)
        console.sf = -1
    end
    if console.raceSoundId ~= -1 then
        StopSound(console.raceSoundId)
        ReleaseSoundId(console.raceSoundId)
        console.raceSoundId = -1
    end
    if not inBettingArea then
        Ambient.releaseBank()
    end

    pcall(function()
        local hud = exports.sm_hud
        hud:setComponentVisible('compass', true)
        hud:setComponentVisible('information', true)
        hud:setComponentVisible('healthArmor', true)
    end)

    console.phase = PHASE_MAIN
    console.mode = nil
    console.horseIndex = -1
end

AddEventHandler('rhd_casino:client:forceLeave', function()
    if console.active then
        console.raceLocked = false
        closeInsideTrack()
    end

    if seatSession.active then
        infoUI:remove('insidetrack_seat')
        Anim.cleanup()
        seatSession.active = false
        seatSession.tIndex = nil
    end
end)

enterBetView = function()
    if not console.myMainBet then return end
    console.mode = MODE_MAIN_EVENT
    console.horseIndex = console.myMainBet.horseIndex
    console.bet = console.myMainBet.bet
    console.odds = console.myMainBet.odds or 2.0
    local gain = math.floor(console.bet * console.odds)
    if mainSync.horses then
        console.horses = Horses.buildClient(mainSync.horses)
        IT.SetHorses(console.sf, console.horses)
    end
    IT.SetState(mainSync.phase, true)
    IT.ToggleBetting(console.sf, false)
    IT.ResetBettingValues(console.sf, console.horseIndex, console.bet, console.balance, gain)
    switchScreen(console.sf, IT.SCREEN_BET_MAIN)
    console.phase = PHASE_VIEW
end

handleClick = function(btn)
    local effectivePhase = console.phase
    if effectivePhase == PHASE_RACE then return end
    if effectivePhase == PHASE_LOCKED then
        effectivePhase = PHASE_MAIN
    end
    if effectivePhase == PHASE_VIEW then
        if btn == BTN_CLOSE or btn == BTN_BACK then
            refreshConsoleMain()
        end
        return
    end
    if effectivePhase == PHASE_MAIN then
        if btn == BTN_PLACE_BET_MAIN or btn == BTN_PLACE_BET_ALT then
            if console.mainBetPlaced then
                enterBetView()
                return
            end
            if mainSync.phase ~= 'open' then
                lib.notify({
                    title = 'Inside Track',
                    description = 'Main event belum dibuka. Tunggu round berikutnya.',
                    type = 'inform',
                })
                return
            end
            console.mode = MODE_MAIN_EVENT
            console.bet = config.BetMin
            if mainSync.horses then
                console.horses = Horses.buildClient(mainSync.horses)
            end
            IT.SetHorses(console.sf, console.horses)
            switchScreen(console.sf, IT.SCREEN_SELECT_MAIN)
            console.phase = PHASE_SELECT
            return
        end
        if btn == BTN_PLACE_BET_SINGLE then
            console.mode = MODE_SINGLE
            console.bet = config.BetMin
            IT.SetHorses(console.sf, console.horses)
            switchScreen(console.sf, IT.SCREEN_SELECT)
            console.phase = PHASE_SELECT
            return
        end
        if btn == BTN_RULES then
            switchScreen(console.sf, IT.SCREEN_RULES)
            console.phase = PHASE_RULES
            return
        end
        return
    end
    if console.phase == PHASE_RULES then
        if btn == BTN_CLOSE or btn == BTN_BACK then
            refreshConsoleMain()
        end
        return
    end
    if console.phase == PHASE_SELECT then
        if btn == BTN_CLOSE or btn == BTN_BACK then
            refreshConsoleMain()
            return
        end
        if btn >= 2 and btn <= 7 then
            console.horseIndex = btn - 1
            local r = config.HorseOdds[console.horseIndex]
            console.odds = r and r.min or 2.0
            local gain = math.floor(console.bet * console.odds)
            local betScreen = (console.mode == MODE_MAIN_EVENT) and IT.SCREEN_BET_MAIN or IT.SCREEN_BET
            IT.SetState(mainSync.phase, console.mainBetPlaced)
            IT.ToggleBetting(console.sf, true)
            IT.SetBettingValues(console.sf, console.horseIndex, console.bet, console.balance, gain)
            switchScreen(console.sf, betScreen)
            console.phase = PHASE_BET
        end
        return
    end
    if console.phase == PHASE_BET then
        if btn == BTN_BET_UP then
            local newBet = math.min(console.bet + config.BetStep, config.BetMax, console.balance)
            if newBet ~= console.bet then
                console.bet = newBet
                local gain = math.floor(console.bet * console.odds)
                IT.SetBettingValues(console.sf, console.horseIndex, console.bet, console.balance, gain)
            end
            return
        end
        if btn == BTN_BET_DOWN then
            local newBet = math.max(console.bet - config.BetStep, config.BetMin)
            if newBet ~= console.bet then
                console.bet = newBet
                local gain = math.floor(console.bet * console.odds)
                IT.SetBettingValues(console.sf, console.horseIndex, console.bet, console.balance, gain)
            end
            return
        end
        if btn == BTN_CONFIRM then
            if console.mode == MODE_MAIN_EVENT then
                placeMainBet()
            else
                startSingleRace()
            end
            return
        end
        if btn == BTN_CLOSE or btn == BTN_BACK then
            local selectScreen = (console.mode == MODE_MAIN_EVENT) and IT.SCREEN_SELECT_MAIN or IT.SCREEN_SELECT
            switchScreen(console.sf, selectScreen)
            console.phase = PHASE_SELECT
            console.horseIndex = -1
            return
        end
    end
end

placeMainBet = function()
    if not console.active then return end
    local res = lib.callback.await('rhd_casino_insidetrack:betMain', false, {
        horseIndex = console.horseIndex,
        bet = console.bet,
    })
    if not res then
        return
    end
    console.balance = res.newBalance
    console.mainBetPlaced = true
    console.myMainBet = {
        horseIndex = console.horseIndex,
        bet = console.bet,
        odds = res.odds,
        roundId = res.roundId,
    }
    console.odds = res.odds
    lib.notify({
        title = 'Inside Track',
        description = ('Bet $%s pada kuda #%d (odds: %.2fx). Race dalam %ds.'):format(
            lib.math.groupdigits(console.bet),
            console.horseIndex,
            res.odds,
            res.timer
        ),
        type = 'success',
        duration = 5000,
    })
    refreshConsoleMain()
end

startSingleRace = function()
    if not console.active then return end
    local res = lib.callback.await('rhd_casino_insidetrack:betSingle', false, {
        horseIndex = console.horseIndex,
        bet = console.bet,
    })
    if not res then
        return
    end
    console.balance = res.newBalance
    playRaceOnConsole(res.raceOrder, true, function()
        lib.notify({
            title = 'Inside Track',
            description = ('Kuda #%d menang. Hasil sedang diproses...'):format(res.winner),
            type = 'inform',
            duration = 3000,
        })
    end)
end

useAreaHooks(function(inside)
    if inside then
        if not big.loaded then
            bigScreenLoad()
        end
    else
        if big.loaded then
            bigScreenUnload()
        end
        Ambient.stopMainRaceLoop()
        Ambient.resetRoundState()
        if not console.active then
            Ambient.releaseBank()
        end
    end
end)

useInteriorRoom(function(roomname)
    local nowInside = (roomname == 'rm_BettingRoom')
    if nowInside ~= inBettingArea then
        inBettingArea = nowInside
        if inBettingArea then
            Ambient.loadBank()
        else
            Ambient.stopMainRaceLoop()
            Ambient.resetRoundState()
            if not console.active then
                Ambient.releaseBank()
            end
        end
    end
end)

CreateThread(function()
    while true do
        local sleep =
        (not console.active and big.target ~= 0 and big.sf ~= -1 and inBettingArea) and 0 or 500
        if sleep == 0 then
            SetTextRenderId(big.target)
            SetScriptGfxDrawOrder(4)
            SetScriptGfxDrawBehindPausemenu(true)
            DrawScaleformMovie(big.sf, 0.5, 0.5, 0.999, 0.999, 255, 255, 255, 255, 0)
            SetTextRenderId(GetDefaultScriptRendertargetRenderId())
            SetScriptGfxDrawBehindPausemenu(false)
        end
        Wait(sleep)
    end
end)

for i = 1, #chairs do
    local chairPos = chairs[i]
    target:addSphereZone({
        coords = vec(chairPos.x, chairPos.y, chairPos.z + 0.8),
        radius = 0.5,
        options = {
            {
                label = 'Duduk & Main InsideTrack',
                distance = 2.0,
                icon = 'fas fa-horse',
                canInteract = function()
                    return inBettingArea and not seatSession.active
                end,
                onSelect = function()
                    sitDown(i)
                end,
            },
        },
    })
end
RegisterNetEvent('rhd_casino_insidetrack:client:setScreen', function (index)
    if source == '' then return end
    IT.SCREEN_WALL_MAIN = index or 0
end)

RegisterNetEvent('rhd_casino_insidetrack:client:singleResult', function(data)
    if source == '' or not data then return end
    console.balance = data.finalBalance or console.balance
    if console.active and console.sf ~= -1 then
        local myName = GetPlayerName(cache.playerId) or 'You'
        local net = (data.won or data.isConsol)
            and ((data.payout or 0) - (data.bet or 0))
            or -(data.bet or 0)
        if (data.won or data.isConsol) and net <= 0 then net = data.payout or 0 end
        IT.SetPlayerResult(console.sf, myName, net)
    end
    if data.won or data.isConsol then
        lib.notify({
            title = 'Inside Track',
            description = ('Kuda #%d menang! Kamu menang **$%s**'):format(
                data.winner, lib.math.groupdigits(data.payout)
            ),
            type = 'success',
            duration = 6000,
        })
    else
        lib.notify({
            title = 'Inside Track',
            description = ('Kuda #%d menang. Kamu kalah $%s.'):format(
                data.winner, lib.math.groupdigits(data.bet)
            ),
            type = 'error',
            duration = 4000,
        })
    end
end)

RegisterNetEvent('rhd_casino_insidetrack:client:mainState', function(data)
    if source == '' or not data then return end
    if data.roundId and data.roundId ~= mainSync.roundId then
        if data.phase == 'open' or data.phase == 'idle' then
            console.mainBetPlaced = false
            console.myMainBet = nil
        end
        Ambient.resetRoundState()
    end
    local prevPhase = mainSync.phase
    mainSync.roundId = data.roundId or mainSync.roundId
    mainSync.phase = data.phase or mainSync.phase
    mainSync.horses = data.horses or mainSync.horses
    mainSync.timer = data.timer or 0
    mainSync.perHorse = data.perHorse or mainSync.perHorse
    mainSync.raceOrder = data.raceOrder
    mainSync.winner = data.winner
    local newPhase = mainSync.phase
    if inBettingArea or console.active then
        if newPhase ~= prevPhase then
            if newPhase == 'open' then
                Ambient.resetRoundState()
                Ambient.announceCustom('MINIGAME_TRACK_EVENT_STARTING', true)
            elseif newPhase == 'racing' then
                Ambient.stopMainRaceLoop()
                Ambient.startMainRaceLoop()
                Ambient.spawnRaceAnnouncer(mainSync.raceOrder, true, function()
                    return mainSync.phase == 'racing'
                end)
            elseif newPhase == 'results' then
                Ambient.stopMainRaceLoop()
                Ambient.spawnPodiumAnnounce(mainSync.raceOrder, mainSync.winner, function()
                    return mainSync.phase == 'results'
                end)
            elseif newPhase == 'intermission' or newPhase == 'idle' then
                Ambient.stopMainRaceLoop()
            end
        end
    end
    if console.active and console.sf ~= -1 then
        local p = mainSync.phase
        if p == 'racing' then
            if (console.phase == PHASE_SELECT or console.phase == PHASE_BET)
               and console.mode == MODE_MAIN_EVENT then
                lib.notify({
                    title = 'Inside Track',
                    description = 'Waktu betting habis. Tunggu round berikutnya.',
                    type = 'error',
                    duration = 4000,
                })
                refreshConsoleMain()
            elseif console.phase ~= PHASE_RACE then
                refreshConsoleMain()
            end
        elseif p == 'open' or p == 'results' or p == 'intermission' or p == 'idle' then
            if console.phase == PHASE_MAIN
               or console.phase == PHASE_LOCKED
               or console.phase == PHASE_VIEW then
                refreshConsoleMain()
            end
        end
    end
    bigScreenSync()
end)

RegisterNetEvent('rhd_casino_insidetrack:client:mainTick', function(round, phase, timer)
    if source == '' then return end
    mainSync.timer = timer or 0
    if phase then mainSync.phase = phase end
    if (inBettingArea or console.active) and mainSync.phase == 'open' then
        Ambient.tickCountdown(mainSync.timer)
    end
    local showTimer = (mainSync.phase == 'open') and mainSync.timer or 0
    if console.active and console.sf ~= -1
       and (console.phase == PHASE_MAIN or console.phase == PHASE_SELECT
            or console.phase == PHASE_BET or console.phase == PHASE_VIEW) then
        IT.SetCountdown(console.sf, showTimer)
    end
    if big.loaded and big.sf ~= -1 then
        IT.SetCountdown(big.sf, showTimer)
        bigScreenSync()
    end
end)

RegisterNetEvent('rhd_casino_insidetrack:client:perHorseUpdate', function(data)
    if source == '' then return end
    if not data or data.roundId ~= mainSync.roundId then return end
    mainSync.perHorse[data.horseIndex] = data.bettors or {}
    if big.loaded and big.sf ~= -1 and mainSync.phase == 'open'
       and big.currentScreen == IT.SCREEN_WALL_DETAIL then
        IT.FocusHorseOnBigScreen(big.sf, data.horseIndex, mainSync.perHorse[data.horseIndex])
    end
end)

RegisterNetEvent('rhd_casino_insidetrack:client:mainResult', function(data)
    if source == '' or not data then return end
    console.balance = data.finalBalance or console.balance
    lib.notify({
        title = 'Inside Track',
        description = ('Kuda #%d berhasil memenangkan Main Event. Round akan segera dimulai kembali.'):format(
            data.winner
        ),
        type = 'info',
        duration = 8000,
    })
    console.mainBetPlaced = false
    console.myMainBet = nil
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == cache.resource then
        if console.active then
            DisplayHud(true)
            SetPlayerControl(PlayerId(), true, 0)
            EnableAllControlActions(0)
            if console.sf ~= -1 then
                SetScaleformMovieAsNoLongerNeeded(console.sf)
            end
        end
        if seatSession.active then
            Anim.cleanup()
            seatSession.active = false
            seatSession.tIndex = nil
        end
        Ambient.stopMainRaceLoop()
        Ambient.releaseBank()
        bigScreenUnload()
    end
end)
