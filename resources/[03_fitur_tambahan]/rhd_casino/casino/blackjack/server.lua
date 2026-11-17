local DEALER_DICT = 'anim_casino_b@amb@casino@games@blackjack@dealer'

---@class BJ_PlayerData
---@field src number
---@field seat integer
---@field bet integer
---@field splitBet integer
---@field pendingBet integer
---@field hand string[]
---@field splitHand string[]?
---@field inRound boolean
---@field doubled boolean
---@field splitDoubled boolean
---@field splitDone boolean
---@field betConfirmed boolean

---@type table<integer, table<integer, BJ_PlayerData>>
local tablePlayers = {}

---@type table<integer, boolean>
local tableActive = {}

---@type table<integer, string> -- 'idle' | 'betting' | 'dealing' | 'playing' | 'dealer' | 'resolving'
local tableState = {}

---@type table<integer, boolean>
local tableEarlyStart = {}

---@type table<integer, integer>
local tableBettingDeadline = {}

---@type table<integer, { tableIdx: integer, seat: integer }>
local playerSeats = {}

local config = require 'casino.blackjack.config.blackjack'
local cards = require 'casino.blackjack.modules.cards'

for i = 1, #config.tables do
    tablePlayers[i] = {}
    tableState[i] = 'idle'
end

---@type table<integer, boolean>
local rigBlackjack = {}
---@type table<integer, boolean>
local rigSplit = {}

---Removes a card with the target face value from the deck; falls back to a random card if not found.
---@param deck string[]
---@param targetValue integer
---@return string?
local function drawCardOfValue(deck, targetValue)
    for i = 1, #deck do
        if cards.cardValue(deck[i]) == targetValue then
            return table.remove(deck, i)
        end
    end
    return cards.takeCard(deck)
end

---Finds and removes a deck card that pushes the dealer above `best` without busting.
---@param deck string[]
---@param dealerHand string[]
---@param best integer
---@return string?
local function drawDealerWinningCard(deck, dealerHand, best)
    for i = 1, #deck do
        local trial = { table.unpack(dealerHand) }
        trial[#trial + 1] = deck[i]
        local v = cards.handValue(trial)
        if v > best and v <= 21 then
            return table.remove(deck, i)
        end
    end
    return nil
end

---@param src number
---@return number
local function getChipBalance(src)
    return ox_inventory:GetItemCount(src, shared.chipItemName) or 0
end

---@param src number
---@param amount number
---@return boolean
local function takeChips(src, amount)
    if amount <= 0 then return true end
    if getChipBalance(src) < amount then return false end
    return ox_inventory:RemoveItem(src, shared.chipItemName, amount)
end

---@param src number
---@param amount number
---@param bankAmount number?
local function giveChips(src, amount, bankAmount)
    if amount <= 0 then return false end
    return shared.payCasinoChipPrize(src, amount, 'blackjack', bankAmount)
end

---@param tableIdx integer
---@return integer
local function countPlayers(tableIdx)
    local n = 0
    for _ in pairs(tablePlayers[tableIdx]) do n = n + 1 end
    return n
end

---@param tableIdx integer
---@return BJ_PlayerData[]
local function getOrderedPlayers(tableIdx)
    local list = {}
    for _, p in pairs(tablePlayers[tableIdx]) do
        list[#list + 1] = p
    end
    table.sort(list, function(a, b) return a.seat < b.seat end)
    return list
end

---@param tableIdx integer
---@param seat integer
---@return boolean
local function isSeatTaken(tableIdx, seat)
    for _, p in pairs(tablePlayers[tableIdx]) do
        if p.seat == seat then return true end
    end
    return false
end

---@param tableIdx integer
---@param clip string
local function dealerAnim(tableIdx, clip)
    BroadcastCasinoPlayers('rhd_casino_blackjack:client:dealerAnim', tableIdx, { DEALER_DICT, clip })
end

---@param tableIdx integer
---@param speech string
local function dealerSpeech(tableIdx, speech)
    BroadcastCasinoPlayers('rhd_casino_blackjack:client:dealerSpeech', tableIdx, speech)
end

---@param hand string[]
---@return boolean
local function canSplit(hand)
    return #hand == 2 and cards.cardValue(hand[1]) == cards.cardValue(hand[2])
end

---@param tableIdx integer
local function resetRoundData(tableIdx)
    for _, p in pairs(tablePlayers[tableIdx]) do
        p.hand = {}
        p.splitHand = nil
        p.bet = 0
        p.splitBet = 0
        p.pendingBet = 0
        p.inRound = false
        p.doubled = false
        p.splitDoubled = false
        p.splitDone = false
        p.betConfirmed = false
    end
end

---@param tableIdx integer
local function clearTableVisuals(tableIdx)
    BroadcastCasinoPlayers('rhd_casino_blackjack:client:retrieveCards', tableIdx, 0)
    for seat = 1, 4 do
        BroadcastCasinoPlayers('rhd_casino_blackjack:client:retrieveCards', tableIdx, seat)
    end
end

---@param tableIdx integer
---@param phase string
---@param timeLeft number
---@param isSplit boolean?
local function sendPhaseToSeatedPlayers(tableIdx, phase, timeLeft, isSplit)
    for src in pairs(tablePlayers[tableIdx]) do
        TriggerCasinoEvent(
            'rhd_casino_blackjack:client:phase',
            src,
            tableIdx,
            phase,
            timeLeft,
            isSplit
        )
    end
end

---@param tableIdx integer
local function phaseBetting(tableIdx)
    tableState[tableIdx] = 'betting'
    tableEarlyStart[tableIdx] = false

    dealerAnim(tableIdx, 'female_place_bet_request')
    dealerSpeech(tableIdx, 'MINIGAME_DEALER_PLACE_CHIPS')
    sendPhaseToSeatedPlayers(tableIdx, 'betting', config.bettingTime)

    local deadline = GetGameTimer() + (config.bettingTime * 1000)
    tableBettingDeadline[tableIdx] = deadline
    while GetGameTimer() < deadline do
        if tableEarlyStart[tableIdx] then break end
        Wait(300)
    end
    tableEarlyStart[tableIdx] = false
    tableBettingDeadline[tableIdx] = nil

    for src, p in pairs(tablePlayers[tableIdx]) do
        if p.pendingBet and p.pendingBet > 0 then
            if takeChips(src, p.pendingBet) then
                p.bet = p.pendingBet
                p.inRound = true
                TriggerCasinoEvent('rhd_casino_blackjack:client:betLocked', src, tableIdx, p.seat, p.bet)
            else
                BroadcastCasinoPlayers('rhd_casino_blackjack:client:retrieveCards', tableIdx, p.seat)
            end
            p.pendingBet = 0
        end
    end

    sendPhaseToSeatedPlayers(tableIdx, 'idle', 0)
end

lib.callback.register('rhd_casino_blackjack:callback:placeBet', function(source, tableIdx, bet)
    if type(tableIdx) ~= 'number' or type(bet) ~= 'number' then return false end

    local p = tablePlayers[tableIdx] and tablePlayers[tableIdx][source]
    if not p then return false end
    if tableState[tableIdx] ~= 'betting' then return false end
    if p.inRound then return false end
    if p.pendingBet and p.pendingBet > 0 then return false end

    local tbl = config.tables[tableIdx]
    if not tbl then return false end

    bet = math.floor(bet)
    local minBet = (tbl.bettingAmounts and tbl.bettingAmounts[1]) or 1
    local maxBet = tbl.maxBettingAmount or math.huge
    if bet < minBet or bet > maxBet then return false end

    if getChipBalance(source) < bet then return false end

    p.pendingBet = bet
    BroadcastCasinoPlayers(
        'rhd_casino_blackjack:client:placeChip',
        tableIdx, p.seat, bet, false, false
    )
    return true
end)

RegisterNetEvent('rhd_casino_blackjack:server:confirmBet', function(tableIdx)
    local source = source
    if type(tableIdx) ~= 'number' then return end
    local p = tablePlayers[tableIdx] and tablePlayers[tableIdx][source]
    if not p then return end
    if tableState[tableIdx] ~= 'betting' then return end
    if not p.pendingBet or p.pendingBet <= 0 then return end

    p.betConfirmed = true

    local allConfirmed = true
    for _, player in pairs(tablePlayers[tableIdx]) do
        if not player.betConfirmed then
            allConfirmed = false
            break
        end
    end
    if allConfirmed then
        tableEarlyStart[tableIdx] = true
    end
end)

local function dealOne(tableIdx, seat, hand, card, flipped, isSplit, isDouble)
    table.insert(hand, card)
    BroadcastCasinoPlayers(
        'rhd_casino_blackjack:client:giveCard',
        tableIdx, seat, #hand, card, flipped or false, isSplit or false, isDouble or false
    )
end

---@param tableIdx integer
---@param deck string[]
---@param dealerHand string[]
local function phaseDealing(tableIdx, deck, dealerHand)
    tableState[tableIdx] = 'dealing'
    dealerSpeech(tableIdx, 'MINIGAME_DEALER_CLOSED_BETS')
    Wait(1500)

    for round = 1, 2 do
        local card = cards.takeCard(deck)
        table.insert(dealerHand, card)

        BroadcastCasinoPlayers(
            'rhd_casino_blackjack:client:giveCard',
            tableIdx, 0, #dealerHand, card, #dealerHand == 1, false
        )

        if #dealerHand == 1 then
            dealerAnim(tableIdx, 'female_deal_card_self')
        else
            dealerAnim(tableIdx, 'female_deal_card_self_second_card')
        end

        Wait(2000)

        if #dealerHand > 1 then
            dealerSpeech(tableIdx, 'MINIGAME_BJACK_DEALER_' .. cards.cardValue(dealerHand[2]))
        end

        local dealRoundPlayers = getOrderedPlayers(tableIdx)
        for i = 1, #dealRoundPlayers do
            local p = dealRoundPlayers[i]
            if p.inRound then
                local c
                if round == 2 and rigSplit[p.src] and p.hand[1] then
                    rigSplit[p.src] = nil
					c = drawCardOfValue(deck, cards.cardValue(p.hand[1]))
                else
                    c = cards.takeCard(deck)
                end
                dealOne(tableIdx, p.seat, p.hand, c, false, false)
                dealerAnim(tableIdx, ('female_deal_card_player_0%s'):format(5 - p.seat))
                Wait(2000)

                if round == 2 and cards.handValue(p.hand) == 21 then
                    local mult = (config.tables[tableIdx].payoutMultipliers and config.tables[tableIdx].payoutMultipliers.blackjack) or 2.5
                    local payout = math.floor(p.bet * mult)
                    TriggerCasinoEvent('rhd_casino_blackjack:client:gameEndReaction', p.src, 'good')
                    giveChips(p.src, payout, math.max(payout - p.bet, 0))
                    p.inRound = false
                    dealerSpeech(tableIdx, 'MINIGAME_BJACK_DEALER_BLACKJACK')
                end
            end
        end
    end
end

---@param tableIdx integer
---@param p BJ_PlayerData
---@param hand string[]
---@param deck string[]
---@param isSplit boolean
---@return boolean continued
local function playerTurnLoop(tableIdx, p, hand, deck, isSplit)
    while #hand < 5 do
        if not tablePlayers[tableIdx][p.src] then return false end

        if cards.handValue(hand) >= 21 then return true end

        if isSplit then
            dealerAnim(tableIdx, ('female_hit_second_card_player_0%s'):format(5 - p.seat))
            Wait(600)
        else
            dealerAnim(tableIdx, ('female_dealer_focus_player_0%s_idle'):format(5 - p.seat))
        end
        dealerSpeech(tableIdx, 'MINIGAME_BJACK_DEALER_ANOTHER_CARD')

        TriggerCasinoEvent('rhd_casino_blackjack:client:phase', p.src,
            tableIdx, 'move', config.moveTime, isSplit)

        local canDouble = (#hand == 2) and (isSplit and not p.splitDoubled or not isSplit and not p.doubled)
        local move = lib.callback.await(
            'rhd_casino_blackjack:callback:requestMove',
            p.src, tableIdx, config.moveTime,
            canDouble,
            (not isSplit) and canSplit(hand)
        ) or 'stand'

        if not tablePlayers[tableIdx][p.src] then return false end

        if move == 'hit' then
            local c
            if rigBlackjack[p.src] then
                rigBlackjack[p.src] = nil
                local need = 21 - cards.handValue(hand)
                if need >= 2 and need <= 11 then
                    c = drawCardOfValue(deck, need)
                else
                    c = cards.takeCard(deck)
                end
            else
                c = cards.takeCard(deck)
            end
            dealOne(tableIdx, p.seat, hand, c, false, isSplit)
            dealerAnim(tableIdx, (isSplit and 'female_hit_second_card_player_0%s' or 'female_hit_card_player_0%s'):format(5 - p.seat))
            Wait(1500)

            local v = cards.handValue(hand)
            if v == 21 then
                dealerSpeech(tableIdx, 'MINIGAME_BJACK_DEALER_21')
                return true
            elseif v > 21 then
                TriggerCasinoEvent('rhd_casino_blackjack:client:gameEndReaction', p.src, 'bad')
                dealerSpeech(tableIdx, 'MINIGAME_BJACK_DEALER_PLAYER_BUST')
                return false
            else
                dealerSpeech(tableIdx, 'MINIGAME_BJACK_DEALER_' .. v)
            end
        elseif move == 'double' and #hand == 2 and (isSplit and not p.splitDoubled or not isSplit and not p.doubled) then
            local doubleCost = isSplit and p.splitBet or p.bet
            if takeChips(p.src, doubleCost) then
                if isSplit then
                    p.splitDoubled = true
                    p.splitBet = p.splitBet * 2
                    BroadcastCasinoPlayers(
                        'rhd_casino_blackjack:client:placeChip',
                        tableIdx, p.seat, doubleCost, true, true
                    )
                else
                    p.doubled = true
                    p.bet = p.bet * 2
                    BroadcastCasinoPlayers(
                        'rhd_casino_blackjack:client:placeChip',
                        tableIdx, p.seat, doubleCost, true, false
                    )
                end

                local c = cards.takeCard(deck)
                dealOne(tableIdx, p.seat, hand, c, false, isSplit, true)
                dealerAnim(tableIdx, (isSplit and 'female_hit_second_card_player_0%s' or 'female_hit_card_player_0%s'):format(5 - p.seat))
                Wait(1500)

                local v = cards.handValue(hand)
                if v > 21 then
                    TriggerCasinoEvent('rhd_casino_blackjack:client:gameEndReaction', p.src, 'bad')
                    dealerSpeech(tableIdx, 'MINIGAME_BJACK_DEALER_PLAYER_BUST')
                    return false
                else
                    dealerSpeech(tableIdx, 'MINIGAME_BJACK_DEALER_' .. v)
                    return true
                end
            end
        elseif move == 'split' and not isSplit and canSplit(hand) and not p.splitDone then
            if takeChips(p.src, p.bet) then
                p.splitDone = true
                p.splitBet = p.bet
                p.splitHand = { table.remove(hand, 2) }

                dealerAnim(tableIdx, ('female_split_card_player_0%s'):format(5 - p.seat))
                BroadcastCasinoPlayers(
                    'rhd_casino_blackjack:client:placeChip',
                    tableIdx, p.seat, p.bet, false, true
                )
                BroadcastCasinoPlayers(
                    'rhd_casino_blackjack:client:split',
                    tableIdx, p.seat, #p.splitHand, p.hand, p.splitHand
                )
                Wait(1000)

                local c1 = cards.takeCard(deck)
                dealOne(tableIdx, p.seat, p.hand, c1, false, false)
                dealerAnim(tableIdx, ('female_hit_card_player_0%s'):format(5 - p.seat))
                Wait(1200)

                local c2 = cards.takeCard(deck)
                dealOne(tableIdx, p.seat, p.splitHand, c2, false, true)
                dealerAnim(tableIdx, ('female_hit_second_card_player_0%s'):format(5 - p.seat))
                Wait(1200)
            end
        else
            return true
        end
    end
    return true
end

---@param tableIdx integer
---@param deck string[]
local function phasePlayers(tableIdx, deck)
    tableState[tableIdx] = 'playing'

    local orderedPlayers = getOrderedPlayers(tableIdx)
    for i = 1, #orderedPlayers do
        local p = orderedPlayers[i]
        if p.inRound and tablePlayers[tableIdx][p.src] then
            dealerAnim(tableIdx, ('female_dealer_focus_player_0%s_idle_intro'):format(5 - p.seat))
            Wait(800)

            local handAlive = playerTurnLoop(tableIdx, p, p.hand, deck, false)

            if not tablePlayers[tableIdx][p.src] then
                BroadcastCasinoPlayers('rhd_casino_blackjack:client:retrieveCards', tableIdx, p.seat)
            elseif p.splitHand then
                dealerAnim(tableIdx, ('female_hit_second_card_player_0%s'):format(5 - p.seat))
                Wait(800)
                playerTurnLoop(tableIdx, p, p.splitHand, deck, true)
            end

            dealerAnim(tableIdx, ('female_dealer_focus_player_0%s_idle_outro'):format(5 - p.seat))
            Wait(800)
        end
    end
end

---@param tableIdx integer
---@param deck string[]
---@param dealerHand string[]
local function phaseDealer(tableIdx, deck, dealerHand)
    tableState[tableIdx] = 'dealer'

    local anyAlive = false
    for _, p in pairs(tablePlayers[tableIdx]) do
        if p.inRound then
            if cards.handValue(p.hand) <= 21 then anyAlive = true break end
            if p.splitHand and cards.handValue(p.splitHand) <= 21 then anyAlive = true break end
        end
    end

    if not anyAlive then return end

    dealerAnim(tableIdx, 'female_turn_card')
    BroadcastCasinoPlayers('rhd_casino_blackjack:client:dealerTurnOverCard', tableIdx)
    Wait(2000)

    dealerSpeech(tableIdx, 'MINIGAME_BJACK_DEALER_' .. cards.handValue(dealerHand))
    Wait(1000)

    local rigWin = not shared.rollDifficulty(config.Difficulty)
    local best = 0
    if rigWin then
        for _, p in pairs(tablePlayers[tableIdx]) do
            if p.inRound then
                local v = cards.handValue(p.hand)
                if v <= 21 and v > best then best = v end
                if p.splitHand then
                    local sv = cards.handValue(p.splitHand)
                    if sv <= 21 and sv > best then best = sv end
                end
            end
        end
    end

    while cards.handValue(dealerHand) < 17 do
        local c
        if rigWin and best > 0 then
            c = drawDealerWinningCard(deck, dealerHand, best) or cards.takeCard(deck)
        else
            c = cards.takeCard(deck)
        end
        table.insert(dealerHand, c)
        BroadcastCasinoPlayers(
            'rhd_casino_blackjack:client:giveCard',
            tableIdx, 0, #dealerHand, c, false, false
        )
        dealerAnim(tableIdx, 'female_deal_card_self_second_card')
        Wait(2200)

        dealerSpeech(tableIdx, 'MINIGAME_BJACK_DEALER_' .. cards.handValue(dealerHand))
    end

    if cards.handValue(dealerHand) > 21 then
        dealerSpeech(tableIdx, 'MINIGAME_DEALER_BUSTS')
    end
end

---@param tableIdx integer
---@param dealerHand string[]
local function phaseResolve(tableIdx, dealerHand)
    tableState[tableIdx] = 'resolving'

    local mults = config.tables[tableIdx].payoutMultipliers or { blackjack = 2.5, win = 2.0, push = 1.0 }
    local dealerVal = cards.handValue(dealerHand)
    local dealerBust = dealerVal > 21

    for _, p in pairs(tablePlayers[tableIdx]) do
        if p.inRound then
            local handsToCheck = { { hand = p.hand, bet = p.bet } }
            if p.splitHand then
                handsToCheck[#handsToCheck + 1] = { hand = p.splitHand, bet = p.splitBet }
            end

            local winAmount = 0
            local totalBet = 0
            local outcome = 'bad'

            for i = 1, #handsToCheck do
                local hData = handsToCheck[i]
                local v = cards.handValue(hData.hand)
                local hBet = hData.bet
                totalBet = totalBet + hBet
                if v > 21 then
                    -- player bust always loses
                elseif dealerBust or v > dealerVal then
                    winAmount = winAmount + (hBet * (mults.win or 2.0))
                    outcome = 'good'
                elseif v == dealerVal then
                    winAmount = winAmount + (hBet * (mults.push or 1.0))
                    if outcome == 'bad' then outcome = 'impartial' end
                end
            end

            if winAmount > 0 then
                giveChips(p.src, math.floor(winAmount), math.max(winAmount - totalBet, 0))
            end

            local netLoss = totalBet - winAmount
            if netLoss > 0 then
                shared.depositCasinoLoss(p.src, netLoss, 'blackjack')
            end
            TriggerCasinoEvent('rhd_casino_blackjack:client:gameEndReaction', p.src, outcome)
        end
    end

    if dealerBust then
        dealerAnim(tableIdx, 'female_dealer_reaction_bad_var0' .. math.random(1, 3))
    elseif dealerVal >= 17 then
        dealerAnim(tableIdx, 'female_dealer_reaction_impartial_var0' .. math.random(1, 3))
    end

    Wait(2500)

    for _, p in pairs(tablePlayers[tableIdx]) do
        if p.hand and #p.hand > 0 then
            dealerAnim(tableIdx, ('female_retrieve_cards_player_0%s'):format(5 - p.seat))
            Wait(400)
            BroadcastCasinoPlayers('rhd_casino_blackjack:client:retrieveCards', tableIdx, p.seat)
            Wait(800)
        end
    end

    dealerAnim(tableIdx, 'female_retrieve_own_cards_and_remove')
    Wait(500)
    BroadcastCasinoPlayers('rhd_casino_blackjack:client:retrieveCards', tableIdx, 0)
    Wait(800)
end

local function startTableThread(tableIdx)
    if tableActive[tableIdx] then return end
    tableActive[tableIdx] = true

    CreateThread(function()
        Wait(2500)

        while countPlayers(tableIdx) > 0 do
            resetRoundData(tableIdx)

            phaseBetting(tableIdx)

            local anyIn = false
            for _, p in pairs(tablePlayers[tableIdx]) do
                if p.inRound then anyIn = true break end
            end

            if not anyIn then
                tableState[tableIdx] = 'idle'
                Wait(2000)
                goto continue
            end

            do
                local deck = cards.getDeck()
                local dealerHand = {}

                phaseDealing(tableIdx, deck, dealerHand)

                if cards.handValue(dealerHand) == 21 then
                    dealerAnim(tableIdx, 'female_check_and_turn_card')
                    BroadcastCasinoPlayers('rhd_casino_blackjack:client:dealerTurnOverCard', tableIdx)
                    Wait(1500)
                    dealerSpeech(tableIdx, 'MINIGAME_BJACK_DEALER_BLACKJACK')

                    for _, p in pairs(tablePlayers[tableIdx]) do
                        if p.inRound and cards.handValue(p.hand) ~= 21 then
                            shared.depositCasinoLoss(p.src, p.bet, 'blackjack')
                            TriggerCasinoEvent('rhd_casino_blackjack:client:gameEndReaction', p.src, 'bad')
                        end
                    end
                    Wait(3000)
                else
                    phasePlayers(tableIdx, deck)
                    phaseDealer(tableIdx, deck, dealerHand)
                    phaseResolve(tableIdx, dealerHand)
                end

                clearTableVisuals(tableIdx)
                Wait(1500)
            end

            ::continue::
        end

        tableState[tableIdx] = 'idle'
        tableActive[tableIdx] = false
    end)
end

local function removePlayer(src)
    local data = playerSeats[src]
    if not data then return end

    playerSeats[src] = nil
    local p = tablePlayers[data.tableIdx][src]
    if not p then return end

    if p.pendingBet and p.pendingBet > 0 and tableState[data.tableIdx] == 'betting' then
        p.pendingBet = 0
    end

    tablePlayers[data.tableIdx][src] = nil
    BroadcastCasinoPlayers('rhd_casino_blackjack:client:retrieveCards', data.tableIdx, p.seat)
    dealerSpeech(data.tableIdx, 'MINIGAME_DEALER_LEAVE_NEUTRAL_GAME')
end

lib.callback.register('rhd_casino_blackjack:callback:sitDown', function(source, tableIdx, seat)
    if type(tableIdx) ~= 'number' or not config.tables[tableIdx] then return false end
    if type(seat) ~= 'number' or seat < 1 or seat > 4 then return false end

    local configTable = config.tables[tableIdx]

    if configTable.vipOnly and not shared.checkVIP(source) then
        return false, 'Meja ini hanya untuk pemain VIP. Dapatkan VIP untuk bisa bermain di meja ini!'
    end

    if playerSeats[source] then return false end
    if isSeatTaken(tableIdx, seat) then return false end

    local playerCoords = GetEntityCoords(GetPlayerPed(source))
    local tableCoords = configTable.coords
    if #(playerCoords - vec3(tableCoords.x, tableCoords.y, tableCoords.z)) > 4.5 then
        return false
    end

    tablePlayers[tableIdx][source] = {
        src = source,
        seat = seat,
        bet = 0,
        splitBet = 0,
        pendingBet = 0,
        hand = {},
        splitHand = nil,
        inRound = false,
        doubled = false,
        splitDoubled = false,
        splitDone = false,
        betConfirmed = false,
    }
    playerSeats[source] = { tableIdx = tableIdx, seat = seat }

    dealerSpeech(tableIdx, 'MINIGAME_DEALER_GREET')
    startTableThread(tableIdx)

    local remaining = config.bettingTime
    if tableState[tableIdx] == 'betting' and tableBettingDeadline[tableIdx] then
        remaining = math.max(1, math.ceil((tableBettingDeadline[tableIdx] - GetGameTimer()) / 1000))
    end

    return true, tableState[tableIdx] or 'idle', remaining
end)

lib.callback.register('rhd_casino_blackjack:callback:getState', function(source)
    local data = playerSeats[source]
    if not data then return false end

    local remaining = 0
    if tableState[data.tableIdx] == 'betting' and tableBettingDeadline[data.tableIdx] then
        remaining = math.max(
            0,
            math.ceil((tableBettingDeadline[data.tableIdx] - GetGameTimer()) / 1000)
        )
    end

    return true, tableState[data.tableIdx] or 'idle', remaining
end)

lib.callback.register('rhd_casino_blackjack:callback:standUp', function(source)
    local data = playerSeats[source]
    if not data then return true end
    local p = tablePlayers[data.tableIdx] and tablePlayers[data.tableIdx][source]
    if not p then
        playerSeats[source] = nil
        return true
    end

    if p.inRound then return false end

    removePlayer(source)
    return true
end)

RegisterNetEvent('rhd_casino_blackjack:server:leaveTable', function()
    local data = playerSeats[source]
    if not data then return end
    local p = tablePlayers[data.tableIdx] and tablePlayers[data.tableIdx][source]
    if not p then return end

    if p.inRound then return end

    removePlayer(source)
end)

AddEventHandler('playerDropped', function()
    removePlayer(source)
    rigBlackjack[source] = nil
    rigSplit[source] = nil
end)

AddEventHandler('rhd_casino:releasePlayer', function(playerId)
    removePlayer(playerId)
    rigBlackjack[playerId] = nil
    rigSplit[playerId] = nil
end)

lib.addCommand('setblackjack', {
    help = 'Rig the next blackjack hit for a player to land exactly 21.',
    params = {
        { name = 'target', type = 'playerId', help = 'Player server id (defaults to self)' },
    },
    restricted = 'group.admin',
}, function(source, args)
    local target = args.target or source
    if not playerSeats[target] then
        return lib.notify(source, { type = 'error', description = ('Player %s is not seated at a blackjack table.'):format(target) })
    end
    rigBlackjack[target] = true
    lib.notify(source, { type = 'success', description = ('Player %s will hit blackjack on next hit.'):format(target) })
end)

lib.addCommand('setsplit', {
    help = 'Force a player to be dealt a splittable pair this round (must be in betting phase).',
    params = {
        { name = 'target', type = 'playerId', help = 'Player server id (defaults to self)' },
    },
    restricted = 'group.admin',
}, function(source, args)
    local target = args.target or source
    local seatData = playerSeats[target]
    if not seatData then
        return lib.notify(source, { type = 'error', description = ('Player %s is not seated at a blackjack table.'):format(target) })
    end
    if tableState[seatData.tableIdx] ~= 'betting' then
        return lib.notify(source, { type = 'error', description = 'This command can only be used during the betting phase.' })
    end
    rigSplit[target] = true
    lib.notify(source, { type = 'success', description = ('Player %s will be dealt a splittable pair this round.'):format(target) })
end)

-- require 'casino.blackjack.dev.save'
