local TIMES = {
    GAME_NOT_STARTED = 10,
    ROUNDS = 15,
    SHOWING_CARDS = 5,
}

local RAKE_RATE = 0.05

local GAMESTAGE = require 'casino.holdemPoker.config'.gameStage

local Chairs = {
    { offset = vector3(-0.75, 1.43, -0.45), heading = 310.0 },
    { offset = vector3( 0.75, 1.43, -0.45), heading = 225.0 },
    { offset = vector3( 1.10, 0.00, -0.45), heading = 180.0 },
    { offset = vector3( 0.75, -1.43, -0.45), heading = 130.0 },
    { offset = vector3(-0.75, -1.43, -0.45), heading = 45.0 },
}

local Cards = {}
CasinoPoker.tables = {}

do
    local j = 1
    for i = 2, 14 do
        Cards[j] = "h" .. i ; j += 1
        Cards[j] = "d" .. i ; j += 1
        Cards[j] = "c" .. i ; j += 1
        Cards[j] = "s" .. i ; j += 1
    end
end

local minimalPlayer = require 'casino.holdemPoker.config'.debugMinPlayers or 2
local get_winners = require 'casino.holdemPoker.modules.winners'

---@class PokerChairPlayer
---@field src number
---@field cards string[]
---@field throwed boolean
---@field passed boolean
---@field dealer boolean
---@field playername string
---@field roundbet number
---@field chairId integer
---@field wasInRound boolean
---@field chips number
---@field img string
---@field gender string
---@field allined boolean?
---@field totalContrib number?
---@field smallblind boolean?
---@field bigblind boolean?
---@field disconnected boolean?
---@field needsRebuy boolean?
---@field isBot boolean?

---@class PokerTable
local PokerTable = lib.class("PokerTable")

---@param blind number
---@param index integer
---@param tableConfig PokerTableConfig?
function PokerTable:constructor(blind, index, tableConfig)
    self._index = index
    self._blind = blind
    self._vipOnly = tableConfig and tableConfig.vipOnly or false
    self._coords = tableConfig and tableConfig.coords or nil
    self._minBet = tableConfig and tableConfig.minBet or (blind * 2)
    self._maxBet = tableConfig and tableConfig.maxBet or nil
    self._buyIn = tableConfig and tableConfig.buyIn or (blind * 2)
    self._maxBuyIn = tableConfig and tableConfig.maxBuyIn or nil
    self._chairPlayers = {}
    self._identifiers = {}
    self._playersOpened = {}
    self._joinLock = {}
    self._chairReservations = {}
    self._chipOutAt = {}
    self._cardIndexesExist = {}
    self._dealerCards = {}
    self._mainPot = 0
    self._currentplayer = nil
    self._time = TIMES.GAME_NOT_STARTED
    self._gamestage = GAMESTAGE.GAME_NOT_STARTED
    self:setGameStage(GAMESTAGE.GAME_NOT_STARTED)
    self:setTime(TIMES.GAME_NOT_STARTED)
    CasinoPoker.tables[self._index] = self
    lib.print.info(("Poker table created: %s"):format(self._index))
end

---@param msg string
function PokerTable:debug(msg)
    lib.print.info(("PokerTable debug [%s]: %s"):format(self._index, msg))
end

function PokerTable:playBetSFX()
    local sfxes = {
        "player_bet.wav", "player_bet_2.wav", "player_bet_3.wav",
        "player_bet_4.wav", "player_bet_5.wav", "player_bet_6.wav",
    }

    local randomSfx = sfxes[math.random(#sfxes)]
    self:TCE_OnTablePlayers("rhd_casino_holdemPoker:playSound", randomSfx)
end

---@return integer
function PokerTable:count_playersTable()
    return #self._chairPlayers
end

---@return integer
function PokerTable:count_playersIngame()
    local count = 0

    for i = 1, #self._chairPlayers do
        local p = self._chairPlayers[i]
        if not p.throwed and not p.allined then
            count += 1
        end
    end

    return count
end

---@param source number
---@return PokerChairPlayer|nil
function PokerTable:getPlayerChairData(source)

    for i = 1, #self._chairPlayers do
        local p = self._chairPlayers[i]
        if p.src == source then return p end
    end

    return nil
end

---@param source number
---@return boolean
function PokerTable:isPlayerSitAtTable(source)
    return self:getPlayerChairData(source) ~= nil
end

---@param source number
---@param maxDistance? number
---@return boolean
function PokerTable:isPlayerNear(source, maxDistance)
    if not self._coords then return false end

    local ped = GetPlayerPed(source)
    if ped == 0 then return false end

    local tableCoords = vec3(self._coords.x, self._coords.y, self._coords.z)
    return #(GetEntityCoords(ped) - tableCoords) <= (maxDistance or 5.0)
end

---@param source number
---@return boolean
function PokerTable:isPlayerCurrentPlayer(source)
    return self._chairPlayers[self._currentplayer]?.src == source
end

---@return number|nil
function PokerTable:getCurrentPlayerSrc()
    return self._chairPlayers[self._currentplayer]?.src
end

---@return string
function PokerTable:getCurrentPlayerName()
    return self._chairPlayers[self._currentplayer]?.playername or "UNKNOWN_PLAYER_NAME"
end

---@return integer|nil
function PokerTable:getFreeChairId()
    self:clearExpiredChairReservations()

    for i = 1, #Chairs do
        local found = self._chairReservations[i] ~= nil
        for j = 1, #self._chairPlayers do
            if self._chairPlayers[j].chairId == i then found = true; break end
        end
        if not found then return i end
    end
    return nil
end

---@param chairId integer
---@return boolean
function PokerTable:isChairOccupied(chairId)
    for i = 1, #self._chairPlayers do
        if self._chairPlayers[i].chairId == chairId then
            return true
        end
    end

    return false
end

function PokerTable:clearExpiredChairReservations()
    local now = GetGameTimer()

    for chairId, reservation in pairs(self._chairReservations) do
        if not reservation.source or not GetPlayerName(reservation.source) or now >= reservation.expiresAt then
            self._chairReservations[chairId] = nil
        end
    end
end

---@param source number
---@return integer|nil
function PokerTable:reserveFreeChair(source)
    self:clearExpiredChairReservations()

    for chairId, reservation in pairs(self._chairReservations) do
        if reservation.source == source then
            return chairId
        end
    end

    local chairId = self:getFreeChairId()
    if not chairId then return nil end

    self._chairReservations[chairId] = {
        source = source,
        expiresAt = GetGameTimer() + 60000,
    }

    return chairId
end

---@param source number
---@param chairId integer?
function PokerTable:releaseChairReservation(source, chairId)
    if chairId then
        local reservation = self._chairReservations[chairId]
        if reservation and reservation.source == source then
            self._chairReservations[chairId] = nil
        end
        return
    end

    for reservedChairId, reservation in pairs(self._chairReservations) do
        if reservation.source == source then
            self._chairReservations[reservedChairId] = nil
        end
    end
end

---@return number
function PokerTable:getHighestBet()
    local highest = 0
    for i = 1, #self._chairPlayers do
        local p = self._chairPlayers[i]
        if p.roundbet > highest then highest = p.roundbet end
    end
    return highest
end

---@param source number
---@return number
function PokerTable:calculateCall(source)
    local highest = self:getHighestBet()
    local playerData = self:getPlayerChairData(source)
    return highest - (playerData and playerData.roundbet or 0)
end

---@return number
function PokerTable:calculateNeededRaise()
    return self:getHighestBet() * 2
end

---Sums current round bets from all players into the main pot.
function PokerTable:declareMainPot()
    local total = 0

    for i = 1, #self._chairPlayers do
        total += self._chairPlayers[i].roundbet
    end

    self._mainPot += total
    self:update("everyone", "mainpot")
end

---@param amount any
---@return boolean
function PokerTable:isValidBet(amount)
    amount = type(amount) == "number" and math.floor(amount) or -1
    if amount <= 0 then return false end
    return true
end

---@param source number
---@return boolean
function PokerTable:canPass(source)
    local playerData = self:getPlayerChairData(source)
    if not playerData then return false end

    local highest = self:getHighestBet()
    if (not playerData.wasInRound and not playerData.passed and highest == 0)
        or highest == playerData.roundbet then
        return true
    end

    return false
end

---@return string
function PokerTable:getRandomCard()
    local max = #Cards
    local r = math.random(1, max)

    while self._cardIndexesExist[r] do
        r = math.random(1, max)
    end

    self._cardIndexesExist[r] = true
    return Cards[r]
end

---@param event string
---@param ... any
function PokerTable:TCE_OnTablePlayers(event, ...)
    for i = 1, #self._playersOpened do
        local src = self._playersOpened[i]
        TriggerCasinoEvent(event, tonumber(src), ...)
    end
end

---@param stage integer
function PokerTable:setGameStage(stage)
    self._gamestage = stage
    self:update("everyone", "gamestage")
end

---@param time integer
function PokerTable:setTime(time)
    self._time = time
    self:update("everyone", "timer")
end

function PokerTable:syncActionState()
    local currentSrc = self:getCurrentPlayerSrc()

    for i = 1, #self._chairPlayers do
        local playerData = self._chairPlayers[i]
        local isCurrentPlayer = currentSrc ~= nil and currentSrc == playerData.src
        self:setVar(playerData.src, "disableallbuttons", isCurrentPlayer)
        self:setVar(playerData.src, "canpass", isCurrentPlayer and self:canPass(playerData.src) or false)
    end

    if self._gamestage ~= GAMESTAGE.ROUNDS or currentSrc == nil then return end

    local playerData = self:getPlayerChairData(currentSrc)
    if not playerData then return end

    local callAmount = self:calculateCall(currentSrc)
    local minRaise = self:getHighestBet() * 2 - (playerData.roundbet or 0)
    if minRaise <= 0 then minRaise = self._blind * 2 end

    self:setVar(currentSrc, "callAmount", callAmount)
    self:setVar(currentSrc, "minRaiseAmount", minRaise)
end

---@param id integer?
function PokerTable:setCurrentPlayer(id)
    self._currentplayer = id

    if id ~= nil then
        if self._gamestage == GAMESTAGE.ROUNDS then
            self:setTime(TIMES.ROUNDS)
        end

        TriggerCasinoEvent("rhd_casino_holdemPoker:playSound", self:getCurrentPlayerSrc(), "player_alert.wav")
    end
    self:update("everyone", "currentplayer")
    self:syncActionState()
end

---@param source number|string
---@param key string
---@param val any
function PokerTable:setVar(source, key, val)
    if type(source) == 'string' then
        self:TCE_OnTablePlayers("rhd_casino_holdemPoker:setVariables", key, val)
    else
        TriggerCasinoEvent("rhd_casino_holdemPoker:setVariables", source, key, val)
    end
end

---@param source number|string
---@param updateType string
function PokerTable:update(source, updateType)
    local e = "rhd_casino_holdemPoker:setVariables"

    if updateType == "mainpot" then
        self:setVar(source, "mainpot", self._mainPot)
    elseif updateType == "dealercards" then
        self:setVar(source, "dealercards", self._dealerCards)
    elseif updateType == "timer" then
        self:setVar(source, "timer", self._time)
    elseif updateType == "gamestage" then
        self:setVar(source, "gamestage", self._gamestage)
    elseif updateType == "currentplayer" then
        local cp = self._chairPlayers[self._currentplayer]
        self:setVar(source, "currentplayer", cp?.src)
    elseif updateType == "players" then
        if self._gamestage ~= GAMESTAGE.SHOWING_CARDS then
            local players = lib.table.deepclone(self._chairPlayers)
            for i = 1, #players do players[i].cards = {} end

            if type(source) == "number" then
                TriggerCasinoEvent(e, source, "players", players)
            else
                self:TCE_OnTablePlayers(e, "players", players)

                for i = 1, #self._chairPlayers do
                    local playerData = self._chairPlayers[i]
                    TriggerCasinoEvent("rhd_casino_holdemPoker:updateCards", playerData.src, playerData)
                end
            end
        else
            self:setVar(source, "players", self._chairPlayers)
        end
    elseif updateType == "all" then
        local all = { "mainpot", "dealercards", "timer", "gamestage", "currentplayer", "players" }

        for i = 1, #all do
            self:update(source, all[i])
        end
    else
        self:debug(("update type not found: %s"):format(updateType))
    end
end

function PokerTable:dealPlayerCards()
    for i = 1, #self._chairPlayers do
        local playerData = self._chairPlayers[i]
        while #playerData.cards < 2 do
            local card = self:getRandomCard()
            table.insert(playerData.cards, card)
        end
    end
    self:update("everyone", "players")
end

function PokerTable:resetRoundBets()
    self:declareMainPot()
    for i = 1, #self._chairPlayers do
        local p = self._chairPlayers[i]
        p.roundbet = 0
        p.wasInRound = false
        p.passed = false
    end
end

---Advances the current player pointer, skipping folded or all-in players. Deals dealer cards if all players are done.
function PokerTable:getNextPlayer()
    self._currentplayer = (self._currentplayer or 0) + 1

    if self._currentplayer > self:count_playersTable() then
        self._currentplayer = 1
    end

    local visited = 0
    local total = self:count_playersTable()

    while self._chairPlayers[self._currentplayer] and (
        self._chairPlayers[self._currentplayer].wasInRound or
        self._chairPlayers[self._currentplayer].throwed or
        self._chairPlayers[self._currentplayer].allined
    ) do
        self._currentplayer += 1
        if self._currentplayer > total then
            self._currentplayer = 1
        end
        visited += 1
        if visited >= total then break end
    end

    self:setCurrentPlayer(self._currentplayer)

    local activeCount = 0
    for i = 1, #self._chairPlayers do
        local p = self._chairPlayers[i]
        if not p.wasInRound and not p.throwed and not p.allined then
            activeCount += 1
        end
    end

    if activeCount < 1 then
        local dealed = self:dealDealerCards()
        if dealed then
            for i = 1, #self._chairPlayers do
                local p = self._chairPlayers[i]
                if p.dealer then self._currentplayer = i; break end
            end
            self:getNextPlayer()
        else
            self:checkingWinners()
        end
    else
        self:update("everyone", "players")
    end
end

function PokerTable:raffleDealerPosition()
    if self:count_playersTable() < 1 then return end

    table.sort(self._chairPlayers, function(a, b) return a.chairId < b.chairId end)

    local dealerIdx
    if self._dealerChair then
        dealerIdx = 1
        for i = 1, #self._chairPlayers do
            if self._chairPlayers[i].chairId > self._dealerChair then
                dealerIdx = i
                break
            end
        end
    else
        dealerIdx = math.random(1, #self._chairPlayers)
    end

    self._chairPlayers[dealerIdx].dealer = true
    self._dealerChair = self._chairPlayers[dealerIdx].chairId
    self._currentplayer = dealerIdx
    self:betAutomaticBlinds()
end

function PokerTable:betAutomaticBlinds()
    local count = #self._chairPlayers
    local dealerIdx = self._currentplayer
    if not dealerIdx then return self:resetGame() end

    local smallBlindIdx = count == 2 and dealerIdx or dealerIdx % count + 1
    local bigBlindIdx = smallBlindIdx % count + 1
    local smallBlindPlayerData = self._chairPlayers[smallBlindIdx]
    local bigBlindPlayerData = self._chairPlayers[bigBlindIdx]

    if not smallBlindPlayerData then
        self:resetGame()
        return
    end

    if smallBlindPlayerData == bigBlindPlayerData then
        self:setGameStage(GAMESTAGE.ROUNDS)
        self:setTime(TIMES.ROUNDS)
        self._currentplayer = bigBlindIdx
        self:getNextPlayer()
        self:dealPlayerCards()
        self:playBetSFX()
        return
    end

    local smallblind = self._blind
    local bigblind = self._blind * 2

    if not shared.playerExist(smallBlindPlayerData.src)
        or smallBlindPlayerData.chips < smallblind then
        lib.print.warn(('[Poker] Small blind has insufficient chips, game aborted.'))
        self:openedStatePlayer(smallBlindPlayerData.src, false)
        self:resetGame()
        return
    end

    if not shared.playerExist(bigBlindPlayerData.src)
        or bigBlindPlayerData.chips < bigblind then
        lib.print.warn(('[Poker] Big blind has insufficient chips, game aborted.'))
        self:openedStatePlayer(bigBlindPlayerData.src, false)
        self:resetGame()
        return
    end

    smallBlindPlayerData.smallblind = true
    smallBlindPlayerData.roundbet += smallblind
    bigBlindPlayerData.roundbet += bigblind
    bigBlindPlayerData.bigblind = true
    smallBlindPlayerData.chips -= smallblind
    bigBlindPlayerData.chips -= bigblind
    smallBlindPlayerData.totalContrib = (smallBlindPlayerData.totalContrib or 0) + smallblind
    bigBlindPlayerData.totalContrib = (bigBlindPlayerData.totalContrib or 0) + bigblind

    self:setGameStage(GAMESTAGE.ROUNDS)
    self:setTime(TIMES.ROUNDS)
    self._currentplayer = bigBlindIdx
    self:getNextPlayer()
    self:dealPlayerCards()
    self:playBetSFX()
end

---Deals the next community cards (flop/turn/river). Returns false if all cards are already dealt.
---@return boolean
function PokerTable:dealDealerCards()
    if self:count_playersIngame() <= 1 and #self._chairPlayers > 1 then return false end
    local dc = #self._dealerCards

    if dc == 0 then
        lib.print.info('[Poker] Dealing the flop.')
        while #self._dealerCards < 3 do
            table.insert(self._dealerCards, self:getRandomCard())
        end
        self:resetRoundBets()
        self:TCE_OnTablePlayers("rhd_casino_holdemPoker:playSound", "shuffle_cards.wav")
        self:update("everyone", "dealercards")
        return true
    elseif dc == 3 then
        lib.print.info('[Poker] Dealing the turn.')
        table.insert(self._dealerCards, self:getRandomCard())
        self:resetRoundBets()
        self:TCE_OnTablePlayers("rhd_casino_holdemPoker:playSound", "shuffle_cards_2.wav")
        self:update("everyone", "dealercards")
        return true
    elseif dc == 4 then
        lib.print.info('[Poker] Dealing the river.')
        table.insert(self._dealerCards, self:getRandomCard())
        self:resetRoundBets()
        self:TCE_OnTablePlayers("rhd_casino_holdemPoker:playSound", "shuffle_cards_3.wav")
        self:update("everyone", "dealercards")
        return true
    end

    return false
end

---Reveals all hands, computes side pots, distributes winnings, and transitions to SHOWING_CARDS.
function PokerTable:checkingWinners()
    self:resetRoundBets()
    self:setGameStage(GAMESTAGE.SHOWING_CARDS)
    self:setTime(TIMES.SHOWING_CARDS)
    self:update("everyone", "players")
    self:setCurrentPlayer(nil)

    while #self._dealerCards < 5 do
        table.insert(self._dealerCards, self:getRandomCard())
    end

    self:update("everyone", "dealercards")
    self:TCE_OnTablePlayers("rhd_casino_holdemPoker:playSound", "shuffle_cards.wav")
    local playersNotThrowed = {}
    for i = 1, #self._chairPlayers do
        local p = self._chairPlayers[i]
        if not p.throwed then table.insert(playersNotThrowed, p) end
    end
    local activeContribs = {}
    for i = 1, #playersNotThrowed do
        local p = playersNotThrowed[i]
        if (p.totalContrib or 0) > 0 then
            table.insert(activeContribs, p)
        end
    end
    local caps = {}
    do
        local seen = {}
        for i = 1, #activeContribs do
            local p = activeContribs[i]
            local c = p.totalContrib or 0
            if not seen[c] then
                seen[c] = true
                table.insert(caps, c)
            end
        end
        table.sort(caps)
    end
    local winnerSrcs = {}
    local winnerSeen = {}
    local rakeTotal = 0
    local prevCap = 0
    for ci = 1, #caps do
        local cap = caps[ci]
        local layerTotal = 0
        for i = 1, #self._chairPlayers do
            local p = self._chairPlayers[i]
            local contrib = p.totalContrib or 0
            if contrib > prevCap then
                layerTotal += math.min(contrib, cap) - prevCap
            end
        end
        local eligible = {}
        for i = 1, #activeContribs do
            local p = activeContribs[i]
            if (p.totalContrib or 0) >= cap then
                table.insert(eligible, p)
            end
        end
        if layerTotal > 0 and #eligible > 0 then
            local layerWinners = get_winners(self._dealerCards, eligible) or {}
            local layerWinnerCount = 0
            for i = 1, #eligible do
                if layerWinners[i] then layerWinnerCount += 1 end
            end
            if layerWinnerCount > 0 then
                local layerRake = math.floor(layerTotal * RAKE_RATE)
                local payout = layerTotal - layerRake
                rakeTotal += layerRake
                local share = math.floor(payout / layerWinnerCount)
                for i = 1, #eligible do
                    if layerWinners[i] then
                        local p = eligible[i]
                        p.chips += share
                        if share > 0 and not p.isBot then
                            shared.recordChipWinnings(p.src, share, 'holdemPoker')
                        end
                        if not winnerSeen[p.src] then
                            winnerSeen[p.src] = true
                            table.insert(winnerSrcs, p.src)
                        end
                    end
                end
            end
        end
        prevCap = cap
    end
    if rakeTotal > 0 then
        shared.depositCasinoIncome(rakeTotal, 'holdemPoker:rake', 1.0)
    end
    local winnerCount = #winnerSrcs
    self:setVar("everyone", "winnerSrcs", winnerSrcs)
    for i = 1, #self._chairPlayers do
        local p = self._chairPlayers[i]
        if not p.isBot and not p.disconnected and p.chips <= 0 then
            p.needsRebuy = true
            if shared.playerExist(p.src) then
                TriggerCasinoEvent('rhd_casino_holdemPoker:showRebuyModal', p.src)
                CasinoPoker.notify(p.src, "Chip kamu habis! Lakukan re-buy sekarang atau kamu akan keluar dari meja.")
            end
        end
    end
    local distributionSec = math.ceil(0.9 + (math.max(winnerCount, 1) * 2.15) + 2)
    self:setTime(math.max(TIMES.SHOWING_CARDS, distributionSec))
    self:update("everyone", "players")
end

---@param source number
---@param args { amount: number }
function PokerTable:betPoker(source, args)
    local amount = math.floor(tonumber(args.amount) or -1)
    if self._gamestage ~= GAMESTAGE.ROUNDS then return end
    if not self:isPlayerCurrentPlayer(source) then
        return self:debug("Not the current player is the action holder.")
    end
    if not shared.playerExist(source) then return self:debug("Player not exist: " .. tostring(source)) end
    if not self:isValidBet(amount) then return CasinoPoker.notify(source, "Not a valid bet.") end
    local playerData = self:getPlayerChairData(source)
    local playerChips = playerData and playerData.chips or 0
    if not playerData then return CasinoPoker.notify(source, "Error: Not sitting.") end
    if playerChips < amount then return CasinoPoker.notify(source, "Not enough chips.") end
    if amount >= playerChips then
        playerData.allined = true
        playerData.roundbet += amount
        for i = 1, #self._chairPlayers do
            local p = self._chairPlayers[i]
            if p.src ~= source and p.roundbet < amount then
                p.wasInRound = false
            end
        end
    else
        local minimumBet = self:calculateCall(source)
        if amount < minimumBet and minimumBet > 0 then
            return CasinoPoker.notify(source, ("Minimum bet is %s chips."):format(minimumBet))
        end
        if self._maxBet and amount > self._maxBet then
            return CasinoPoker.notify(source, ("Maximum bet is %s chips."):format(self._maxBet))
        end
        local neededRaiseAdditional = math.max(
            self:getHighestBet() * 2 - playerData.roundbet,
            self._blind * 2
        )
        if playerData.roundbet + amount > self:getHighestBet() then
            if amount < neededRaiseAdditional then
                return CasinoPoker.notify(source, ("Minimum raise is +%s chips."):format(neededRaiseAdditional))
            end
            for i = 1, #self._chairPlayers do
                local p = self._chairPlayers[i]
                if p.src ~= source then p.wasInRound = false end
            end
        else
            if self:getHighestBet() == 0 and amount < self._minBet then
                return CasinoPoker.notify(source, ("Minimum bet is %s chips."):format(self._minBet))
            end
        end
        playerData.roundbet += amount
    end
    self:playBetSFX()
    for i = 1, #self._chairPlayers do
        local p = self._chairPlayers[i]
        if p.passed then
            p.wasInRound = false
            p.passed = false
        end
    end
    playerData.wasInRound = true
    playerData.chips -= amount
    playerData.totalContrib = (playerData.totalContrib or 0) + amount
    self:setTime(TIMES.ROUNDS)
    self:getNextPlayer()
end

---@param source number
function PokerTable:allInPoker(source)
    if self._gamestage ~= GAMESTAGE.ROUNDS then return end
    if not shared.playerExist(source) then return self:debug("Player not exist: " .. tostring(source)) end
    local playerData = self:getPlayerChairData(source)
    if not playerData then return CasinoPoker.notify(source, "Error: Not sitting.") end
    if not self:isPlayerCurrentPlayer(source) then return end
    local maxChips = playerData.chips
    self:betPoker(source, { amount = maxChips })
end

---@param source number
function PokerTable:callPoker(source)
    if self._gamestage ~= GAMESTAGE.ROUNDS then return end
    if not shared.playerExist(source) then return self:debug("Player not exist: " .. tostring(source)) end
    local call = self:calculateCall(source)
    if call == nil then return CasinoPoker.notify(source, "Error: Something went wrong.") end
    local amount = math.floor(call)
    if amount <= 0 then return CasinoPoker.notify(source, "Nothing to call. Use Check.") end
    local playerData = self:getPlayerChairData(source)
    if not playerData then return CasinoPoker.notify(source, "Error: Not sitting.") end
    if not self:isPlayerCurrentPlayer(source) then return end
    if playerData.chips < amount then return CasinoPoker.notify(source, "Not enough chips.") end
    self:betPoker(source, { amount = amount })
end

---@param source number
function PokerTable:passPoker(source)
    if self._gamestage ~= GAMESTAGE.ROUNDS then return end
    if not shared.playerExist(source) then return self:debug("Player not exist: " .. tostring(source)) end
    local playerData = self:getPlayerChairData(source)
    if not playerData then return CasinoPoker.notify(source, "Error: Not sitting.") end
    if not self:isPlayerCurrentPlayer(source) then return end
    if self:canPass(source) then
        self:setTime(TIMES.ROUNDS)
        playerData.wasInRound = true
        playerData.passed = true
        self:getNextPlayer()
    end
end

---@param source number
---@param leaved boolean?
function PokerTable:throwPoker(source, leaved)
    if self._gamestage ~= GAMESTAGE.ROUNDS then return end
    local playerData = self:getPlayerChairData(source)
    if not playerData then return CasinoPoker.notify(source, "Error: Not sitting.") end
    if not self:isPlayerCurrentPlayer(source) and not leaved then return end
    playerData.throwed = true
    self:TCE_OnTablePlayers("rhd_casino_holdemPoker:playSound", "shuffle_cards_2.wav")
    if self:count_playersIngame() <= 1 then
        self:checkingWinners()
    else
        self:setTime(TIMES.ROUNDS)
        self:getNextPlayer()
    end
end

---@param source number
---@param amount number?
function PokerTable:rebuyPlayer(source, amount)
    local playerData = self:getPlayerChairData(source)
    if not playerData then return CasinoPoker.notify(source, "Kamu tidak sedang duduk di meja.") end
    local duringShowdown = self._gamestage == GAMESTAGE.SHOWING_CARDS and playerData.needsRebuy
    if self._gamestage ~= GAMESTAGE.GAME_NOT_STARTED and not duringShowdown then
        return CasinoPoker.notify(source, "Re-buy hanya bisa dilakukan antara putaran.")
    end
    if not shared.playerExist(source) then return end
    if playerData.chips > 0 and not playerData.needsRebuy then
        return CasinoPoker.notify(source, ("Kamu masih punya %s chips."):format(playerData.chips))
    end
    local invChips = shared.getChip(source)
    if invChips < self._buyIn then
        return CasinoPoker.notify(source, ("Butuh minimal %s chips untuk re-buy. Kamu hanya punya %s."):format(self._buyIn, invChips))
    end
    local takeAmount = amount and math.floor(tonumber(amount) or 0) or invChips
    if takeAmount < self._buyIn then
        return CasinoPoker.notify(source, ("Minimum re-buy adalah %s chips."):format(self._buyIn))
    end
    if takeAmount > invChips then
        takeAmount = invChips
    end
    if self._maxBuyIn and takeAmount > self._maxBuyIn then
        takeAmount = self._maxBuyIn
    end
    if not shared.removeChip(source, takeAmount) then
        return CasinoPoker.notify(source, 'Gagal mengambil chip re-buy.')
    end

    playerData.chips = takeAmount --[[@as integer]]
    playerData.needsRebuy = false
    self._chipOutAt[source] = nil
    local identifier = shared.getIdentifier(source)
    if not identifier then
        shared.addChip(source, takeAmount)
        playerData.chips = 0
        return CasinoPoker.notify(source, 'Identifier pemain tidak ditemukan. Chip dikembalikan.')
    end

    shared.saveBuyIn(identifier --[[@as string]], self._index, takeAmount --[[@as integer]])
    shared.log({
        title = 'Poker Re-Buy',
        type = 'info',
        fields = {
            { name = 'Player', value = ('%s (%s)'):format(shared.getPlayerName(source), source) },
            { name = 'Table', value = tostring(self._index), inline = true },
            { name = 'Buy-In', value = ('%s chips'):format(takeAmount), inline = true },
        },
    })
    self:update("everyone", "players")
    CasinoPoker.player:updatePlayerChips(source)
    CasinoPoker.notify(source, ("Re-buy berhasil! Kamu membawa %s chips ke meja."):format(takeAmount))
end

---@param source number
function PokerTable:joinPlayer(source)
    if self._gamestage ~= GAMESTAGE.GAME_NOT_STARTED then
        return CasinoPoker.notify(source, "Cannot join yet.")
    end
    if not self:isPlayerNear(source) then
        return CasinoPoker.notify(source, 'Kamu terlalu jauh dari meja poker.')
    end
    if self._joinLock[source] then
        return CasinoPoker.notify(source, "Permintaan join sedang diproses…")
    end
    self._joinLock[source] = true
    if self:isPlayerSitAtTable(source) then
        self._joinLock[source] = nil
        return CasinoPoker.notify(source, "Kamu sudah duduk di meja ini.")
    end
    for _, inst in pairs(CasinoPoker.tables) do
        if inst ~= self and type(inst.isPlayerSitAtTable) == "function" then
            if inst:isPlayerSitAtTable(source) then
                self._joinLock[source] = nil
                return CasinoPoker.notify(source, "Kamu masih duduk di meja poker lain. Tinggalkan meja itu dulu.")
            end
        end
    end
    local freeChairId = self:reserveFreeChair(source)
    if not (freeChairId and Chairs[freeChairId]) then
        self._joinLock[source] = nil
        return CasinoPoker.notify(source, "No free chair.")
    end

    local function cancelJoin(message)
        self:releaseChairReservation(source, freeChairId)
        self._joinLock[source] = nil
        if message then
            return CasinoPoker.notify(source, message)
        end
    end

    local identifier = shared.getIdentifier(source)
    if not identifier then
        return cancelJoin('Identifier pemain tidak ditemukan.')
    end

    if shared.loadBuyIn(identifier --[[@as string]], self._index) and not CasinoPoker.restoreSavedChips(source) then
        return cancelJoin('Chip poker tersimpan kamu belum bisa dikembalikan. Kosongkan inventory lalu coba lagi.')
    end

    local invChips = shared.getChip(source)
    local buyInAmount = math.floor(tonumber(
        lib.callback.await('rhd_casino_holdemPoker:getBuyInAmount', source, self._index)
    ) or 0)

    if buyInAmount < self._buyIn then
        return cancelJoin("Invalid buy-in amount.")
    end

    if invChips < buyInAmount then
        return cancelJoin(("Minimum buy-in untuk meja ini adalah %s chips."):format(buyInAmount))
    end
    if self:isPlayerSitAtTable(source) then
        return cancelJoin()
    end
    for _, inst in pairs(CasinoPoker.tables) do
        if inst ~= self and type(inst.isPlayerSitAtTable) == "function" then
            if inst:isPlayerSitAtTable(source) then
                return cancelJoin("Kamu masih duduk di meja poker lain.")
            end
        end
    end
    if self:isChairOccupied(freeChairId) then
        return cancelJoin("Kursi ini baru saja digunakan pemain lain. Silakan coba kursi lain.")
    end
    local takeAmount = buyInAmount
    if self._maxBuyIn and takeAmount > self._maxBuyIn then
        takeAmount = self._maxBuyIn
    end
    if not shared.removeChip(source, takeAmount) then
        return cancelJoin("Gagal mengambil chip buy-in.")
    end
    shared.saveBuyIn(identifier --[[@as string]], self._index, takeAmount --[[@as integer]])
    shared.log({
        title = 'Poker Buy-In',
        type = 'info',
        fields = {
            { name = 'Player', value = ('%s (%s)'):format(shared.getPlayerName(source), source) },
            { name = 'Table', value = tostring(self._index), inline = true },
            { name = 'Buy-In', value = ('%s chips'):format(takeAmount), inline = true },
        },
    })
    local ok, gender = pcall(shared.getGender, source)
    if not ok then gender = 'male' end
    local defaultImg = gender == 'female' and 'images/user/user-women.png' or 'images/user/user-man.png'
    local savedImg = CasinoPoker.player:getPlayerImage(source)
    if not savedImg or savedImg == '' then savedImg = defaultImg end
    table.insert(self._chairPlayers, {
        src = source,
        cards = {},
        throwed = false,
        passed = false,
        dealer = false,
        playername = shared.getPlayerName(source),
        roundbet = 0,
        chairId = freeChairId,
        wasInRound = false,
        chips = takeAmount,
        img = savedImg,
        gender = gender,
    })
    self._identifiers[source] = identifier
    local chair = Chairs[freeChairId]
    TriggerCasinoEvent("rhd_casino_holdemPoker:sitDownClient", source, self._index, chair.offset, chair.heading)
    CasinoPoker.player:updatePlayerChips(source)
    self:update("everyone", "players")
    self:releaseChairReservation(source, freeChairId)
    self._joinLock[source] = nil
end

---@param source number
---@param state boolean
---@param dropped boolean?
function PokerTable:openedStatePlayer(source, state, dropped)
    if state then
        if not self:isPlayerNear(source, 7.0) then return end
        if lib.array.includes(self._playersOpened, source) then return end
        if not shared.getIdentifier(source) then return end

        CasinoPoker.restoreSavedChips(source)
        table.insert(self._playersOpened, source)
        self:update(source, "all")
        self:setVar(source, 'myPlayerSrc', source)
        self:setVar(source, 'minBet', self._minBet)
        self:setVar(source, 'maxBet', self._maxBet)
        self:setVar(source, 'buyIn', self._buyIn)
        self:setVar(source, 'maxBuyIn', self._maxBuyIn)
    else
        self:releaseChairReservation(source)
        self._joinLock[source] = nil

        for i = 1, #self._playersOpened do
            local src = self._playersOpened[i]
            if src == source then table.remove(self._playersOpened, i); break end
        end
        if self:isPlayerSitAtTable(source) then
            local playerData = self:getPlayerChairData(source)
            if playerData then
                local chair = Chairs[playerData.chairId]
                local identifier = self._identifiers[source] or shared.getIdentifier(source)
                local chips = playerData.chips
                local cashedOut = not dropped and chips > 0 and shared.addChip(source, chips)

                if not dropped then
                    TriggerCasinoEvent("rhd_casino_holdemPoker:standUpClient", source, self._index, chair.offset, chair.heading)
                end

                if identifier then
                    if chips > 0 and not cashedOut then
                        shared.saveBuyIn(identifier --[[@as string]], self._index, chips)
                    else
                        shared.clearBuyIn(identifier --[[@as string]], self._index)
                    end
                end

                if chips > 0 then
                    if not dropped and not cashedOut then
                        lib.notify(source, {
                            title = 'Casino Poker',
                            description = ('Inventory penuh. %s chip disimpan dan dikembalikan saat kamu kembali ke kasino.'):format(chips),
                            type = 'warning',
                        })
                    end

                    shared.log({
                        title = cashedOut and 'Poker Cash-Out' or 'Poker Chips Saved',
                        type = 'money',
                        fields = {
                            { name = 'Player', value = ('%s (%s)'):format(shared.getPlayerName(source), source) },
                            { name = 'Table', value = tostring(self._index), inline = true },
                            { name = cashedOut and 'Chips Taken' or 'Chips Saved', value = ('%s chips'):format(chips), inline = true },
                            { name = 'Reason', value = dropped and 'disconnect' or 'leave', inline = true },
                        },
                    })
                end

                playerData.chips = 0

                if self._gamestage == GAMESTAGE.ROUNDS then
                    playerData.disconnected = true
                    self:throwPoker(source, true)
                    self:update("everyone", "players")
                else
                    for i = 1, #self._chairPlayers do
                        if self._chairPlayers[i].chairId == playerData.chairId then
                            table.remove(self._chairPlayers, i); break
                        end
                    end
                    self._identifiers[source] = nil
                    self:update("everyone", "players")
                end
            end
        end
        self:setVar(source, 'opened', false)
    end
end

function PokerTable:updatePlayerImages()
    for i = 1, #self._chairPlayers do
        local playerData = self._chairPlayers[i]
        playerData.img = CasinoPoker.player:getPlayerImage(playerData.src)
    end
    self:update("everyone", "players")
end

---Decrements the round timer and advances game phase when it expires.
function PokerTable:tickTime()
    if self._gamestage == GAMESTAGE.GAME_NOT_STARTED then
        if self:count_playersTable() >= minimalPlayer then
            local canPlay = 0
            for i = 1, #self._chairPlayers do
                local p = self._chairPlayers[i]
                if (p.chips or 0) > 0 then canPlay += 1 end
            end
            if canPlay >= minimalPlayer then
                self:setTime(self._time - 1)
                if self._time < 1 then
                    self:raffleDealerPosition()
                end
            end
        end
    elseif self._gamestage == GAMESTAGE.ROUNDS then
        self:setTime(self._time - 1)
        self:syncActionState()
        if self._time < 1 then
            local inactiveSrc = self:getCurrentPlayerSrc()
            if inactiveSrc == nil then return self:resetGame() end
            self:throwPoker(inactiveSrc)
        end
    elseif self._gamestage == GAMESTAGE.SHOWING_CARDS then
        self:setTime(self._time - 1)
        if self._time < 1 then
            self:resetGame()
        end
    end
end

---Removes disconnected players, kicks non-rebuy players, resets all round state, and returns to GAME_NOT_STARTED.
function PokerTable:resetGame()
    for i = #self._chairPlayers, 1, -1 do
        if self._chairPlayers[i].disconnected then
            self._identifiers[self._chairPlayers[i].src] = nil
            table.remove(self._chairPlayers, i)
        end
    end
    for i = #self._chairPlayers, 1, -1 do
        local p = self._chairPlayers[i]
        if p and not p.disconnected and p.needsRebuy then
            local src = p.src
            self._chipOutAt[src] = nil
            if shared.playerExist(src) then
                lib.notify(src, {
                    title = 'Casino Holdem Poker',
                    description = 'Kamu dikeluarkan dari meja karena tidak melakukan re-buy.',
                    type = 'error',
                })
            end
            self:openedStatePlayer(src, false)
        end
    end
    for i = 1, #self._chairPlayers do
        local p = self._chairPlayers[i]
        p.roundbet = 0
        p.cards = {}
        p.throwed = false
        p.passed = false
        p.dealer = false
        p.wasInRound = false
        p.smallblind = false
        p.bigblind = false
        p.allined = false
        p.totalContrib = 0
    end
    self:declareMainPot()
    self._cardIndexesExist = {}
    self._dealerCards = {}
    self._mainPot = 0
    self:setCurrentPlayer(nil)
    self:setGameStage(GAMESTAGE.GAME_NOT_STARTED)
    self:setTime(TIMES.GAME_NOT_STARTED)
    self:update("everyone", "all")
end

AddEventHandler('onServerResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    Wait(1000)
    local tables = require 'casino.holdemPoker.config'.pokerTables
    for i = 1, #tables do
        local a = tables[i]
        ---@diagnostic disable-next-line: undefined-field
        PokerTable:new(a.blind, a.id, a)
    end
end)
