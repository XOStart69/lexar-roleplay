local insidetrack = {}
insidetrack.roundId = 0
insidetrack.phase = 'idle'  ---@type 'idle' | 'open' | 'racing' | 'results' | 'intermission'
insidetrack.bets = {}
insidetrack.players = {}
insidetrack.timer = 0
insidetrack.seats = {}
insidetrack.perHorse = {
    [1] = {}, [2] = {}, [3] = {}, [4] = {}, [5] = {}, [6] = {},
}
insidetrack.single = {
    pending = {},
    raceLockUntil = {},
}
local config = require 'casino.insidetrack.config'
local Horses = require 'casino.insidetrack.modules.horses'
local Chairs = require 'casino.insidetrack.data.chairs'
---@class InsideTrackState
---@field roundId number
---@field phase string
---@field horses table?
---@field timer number
---@field winner integer?
---@field raceOrder integer[]?
---@field perHorse table<integer, table>
---@param source number
---@return boolean
local function isNearScreen(source)
    local ped = GetPlayerPed(source)
    local coords = config.BigScreen.coords
    local pos = GetEntityCoords(ped)
    local dist = #(pos - coords)
    return dist <= 150
end

---@param source number
---@param chairIndex integer
---@return boolean
local function isNearChair(source, chairIndex)
    local chair = Chairs[chairIndex]
    if not chair then return false end

    local ped = GetPlayerPed(source)
    if ped == 0 then return false end

    return #(GetEntityCoords(ped) - chair) <= 3.0
end
---@return InsideTrackState
local function getState()
    return {
        roundId = insidetrack.roundId,
        phase = insidetrack.phase,
        horses = insidetrack.horses,
        timer = insidetrack.timer,
        winner = insidetrack.winner,
        raceOrder = insidetrack.raceOrder,
        perHorse = insidetrack.perHorse,
    }
end
---Sends full current state and screen assignment to a newly subscribed player.
---@param source number
local function addSubscriber(source)
    TriggerCasinoEvent('rhd_casino_insidetrack:client:mainState', source, getState())
    if insidetrack.phase == 'racing' then
        TriggerCasinoEvent('rhd_casino_insidetrack:client:setScreen', source, 5)
    else
        TriggerCasinoEvent('rhd_casino_insidetrack:client:setScreen', source, 0)
    end
end
---@return integer
local function pickWinner()
    local total = 0
    for i = 1, 6 do total = total + (config.HorseWinChance[i] or 0) end
    if total <= 0 then return math.random(1, 6) end
    local roll = math.random() * total
    local cum = 0
    for i = 1, 6 do
        cum = cum + (config.HorseWinChance[i] or 0)
        if roll <= cum then return i end
    end
    return 6
end
---@param winner integer
---@return integer[]
local function generateRaceOrder(winner)
    local order = { winner }
    local pool = {}
    for i = 1, 6 do
        if i ~= winner then pool[#pool + 1] = i end
    end
    for i = #pool, 2, -1 do
        local j = math.random(i)
        pool[i], pool[j] = pool[j], pool[i]
    end
    for i = 1, #pool do order[#order + 1] = pool[i] end
    return order
end
---@param horseIndex integer
---@return number
local function rollOdds(horseIndex)
    local r = config.HorseOdds[horseIndex]
    if not r then return 2.0 end
    local odds = r.min + (r.max - r.min) * math.random()
    return math.floor(odds * 100) / 100
end
---Resolves all active main event bets against the current winner and populates insidetrack.players.
local function settleMainEventBets()
    for src, bd in pairs(insidetrack.bets) do
        local won = (bd.horseIndex == insidetrack.winner)
        local payout = won and math.floor(bd.bet * bd.odds) or 0
        insidetrack.players[src] = {
            won = won,
            payout = payout,
            bet = bd.bet,
            horseIndex = bd.horseIndex,
            name = bd.name,
        }
    end
end
---Resets all round state and advances the round ID for a new betting window.
local function resetMainEventForNewRound()
    insidetrack.roundId = insidetrack.roundId + 1
    insidetrack.phase = 'open'
    insidetrack.horses = Horses.generate()
    insidetrack.bets = {}
    insidetrack.timer = config.MainEvent.betWindowSeconds
    insidetrack.players = {}
    insidetrack.perHorse = {
        [1] = {}, [2] = {}, [3] = {}, [4] = {}, [5] = {}, [6] = {},
    }
    BroadcastCasinoPlayers('rhd_casino_insidetrack:client:setScreen')
end
---@param source number
---@param amount number
local function addBalance(source, amount)
    ox_inventory:AddItem(source, shared.chipItemName, amount)
end

---@param source number
---@param amount number
---@param game string
---@param bankAmount number?
---@return boolean
local function payPrize(source, amount, game, bankAmount)
    return shared.payCasinoChipPrize(source, amount, game, bankAmount)
end
---Pays out winnings and triggers result notification for all settled players.
local function payoutMainEventBets()
    for src, p in pairs(insidetrack.players) do
        local bet = p.bet or 0
        local payout = p.payout or 0
        if p.won and p.payout > 0 then
            payPrize(src, payout, 'insidetrack_main', math.max(payout - bet, 0))
        end
        local netLoss = bet - payout
        if netLoss > 0 then
            shared.depositCasinoLoss(src, netLoss, 'insidetrack_main')
        end
        local results = {
            won = p.won,
            payout = payout,
            bet = bet,
            horseIndex = p.horseIndex,
            winner = insidetrack.winner,
            finalBalance = ox_inventory:GetItemCount(src, shared.chipItemName) or 0,
        }
        TriggerCasinoEvent('rhd_casino_insidetrack:client:mainResult', src, results)
    end
end
CreateThread(function()
    Wait(5000)
    while true do
        resetMainEventForNewRound()
        BroadcastCasinoPlayers('rhd_casino_insidetrack:client:mainState', getState())
        for i = config.MainEvent.betWindowSeconds - 1, 0, -1 do
            Wait(1000)
            insidetrack.timer = i
            BroadcastCasinoPlayers('rhd_casino_insidetrack:client:mainTick',
                insidetrack.roundId, insidetrack.phase, insidetrack.timer)
        end
        insidetrack.winner = pickWinner()
        if not shared.rollDifficulty(config.Difficulty) then
            local betHorses = {}
            for _, bd in pairs(insidetrack.bets) do
                betHorses[bd.horseIndex] = true
            end
            local candidates = {}
            for i = 1, 6 do
                if not betHorses[i] then candidates[#candidates + 1] = i end
            end
            if #candidates > 0 then
                insidetrack.winner = candidates[math.random(1, #candidates)]
            end
        end
        insidetrack.raceOrder = generateRaceOrder(insidetrack.winner)
        insidetrack.phase = 'racing'
        insidetrack.timer = 0
        settleMainEventBets()
        BroadcastCasinoPlayers('rhd_casino_insidetrack:client:mainState', getState())
        Wait(config.RaceDuration + 2000)
        insidetrack.phase = 'results'
        BroadcastCasinoPlayers('rhd_casino_insidetrack:client:mainState', getState())
        payoutMainEventBets()
        Wait(config.MainEvent.resultDisplaySeconds * 1000)
        insidetrack.phase = 'intermission'
        insidetrack.bets = {}
        insidetrack.players = {}
        BroadcastCasinoPlayers('rhd_casino_insidetrack:client:mainState', getState())
        Wait(config.MainEvent.intermissionSeconds * 1000)
    end
end)
lib.callback.register('rhd_casino_insidetrack:canOpen', function(source)
    if not isNearScreen(source) then
        lib.notify(source, {
            title = 'Inside Track',
            description = 'Terlalu jauh dari terminal.',
            type = 'error',
        })
        return false
    end
    return true, insidetrack.bets[source]
end)

lib.callback.register('rhd_casino_insidetrack:betMain', function(source, data)
    local horseIndex = data and data.horseIndex
    local bet = math.floor(tonumber(data and data.bet) or 0)
    if insidetrack.phase ~= 'open' then
        lib.notify(source, {
            title = 'Inside Track',
            description = 'Pendaftaran main event ditutup.',
            type = 'error',
        })
        return false
    end
    if insidetrack.bets[source] then
        lib.notify(source, {
            title = 'Inside Track',
            description = 'Kamu sudah pasang bet di event ini.',
            type = 'error',
        })
        return false
    end
    if not isNearScreen(source) then
        lib.notify(source, {
            title = 'Inside Track',
            description = 'Terlalu jauh dari terminal.',
            type = 'error',
        })
        return false
    end
    if type(horseIndex) ~= 'number' or horseIndex < 1 or horseIndex > 6 then
        lib.notify(source, {
            title = 'Inside Track',
            description = 'Kuda tidak valid.',
            type = 'error',
        })
        return false
    end
    if bet < config.BetMin or bet > config.BetMax then
        lib.notify(source, {
            title = 'Inside Track',
            description = ('Bet harus $%s - $%s.'):format(config.BetMin, config.BetMax),
            type = 'error',
        })
        return false
    end
    local balance = ox_inventory:GetItemCount(source, shared.chipItemName) or 0
    if balance < bet then
        lib.notify(source, {
            title = 'Inside Track',
            description = 'Uang tidak cukup.',
            type = 'error',
        })
        return false
    end
    if not ox_inventory:RemoveItem(source, shared.chipItemName, bet) then
        lib.notify(source, {
            title = 'Inside Track',
            description = 'Gagal potong saldo.',
            type = 'error',
        })
        return false
    end
    local odds = rollOdds(horseIndex)
    local pname = shared.getPlayerName(source)
    insidetrack.bets[source] = {
        horseIndex = horseIndex,
        bet = bet,
        odds = odds,
        name = pname,
        roundId = insidetrack.roundId,
    }
    table.insert(insidetrack.perHorse[horseIndex], {
        name = pname,
        bet = bet,
        src = source,
    })
    BroadcastCasinoPlayers('rhd_casino_insidetrack:client:perHorseUpdate', {
        roundId = insidetrack.roundId,
        horseIndex = horseIndex,
        bettors = insidetrack.perHorse[horseIndex],
    })
    return {
        odds = odds,
        newBalance = balance - bet,
        timer = insidetrack.timer,
        roundId = insidetrack.roundId,
    }
end)

lib.callback.register('rhd_casino_insidetrack:betSingle', function(source, data)
    local bet = math.floor(tonumber(data?.bet) or 0)
    local horseIndex = data?.horseIndex
    local sess = insidetrack.single
    if sess.pending[source] or os.time() < (sess.raceLockUntil[source] or 0) then
        lib.notify(source, {
            title = 'Inside Track',
            description = 'Race sedang berlangsung.',
            type = 'error',
        })
        return false
    end
    if not isNearScreen(source) then
        lib.notify(source, {
            title = 'Inside Track',
            description = 'Terlalu jauh dari terminal.',
            type = 'error',
        })
        return false
    end
    if type(horseIndex) ~= 'number' or horseIndex < 1 or horseIndex > 6 then
        lib.notify(source, {
            title = 'Inside Track',
            description = 'Kuda tidak valid.',
            type = 'error',
        })
        return false
    end
    if bet < config.BetMin or bet > config.BetMax then
        lib.notify(source, {
            title = 'Inside Track',
            description = ('Bet harus $%s - $%s.'):format(config.BetMin, config.BetMax),
            type = 'error',
        })
        return false
    end
    local balance = ox_inventory:GetItemCount(source, shared.chipItemName) or 0
    if balance < bet then
        lib.notify(source, {
            title = 'Inside Track',
            description = 'Uang tidak cukup.',
            type = 'error',
        })
        return false
    end
    if not ox_inventory:RemoveItem(source, shared.chipItemName, bet) then
        lib.notify(source, {
            title = 'Inside Track',
            description = 'Gagal potong saldo.',
            type = 'error',
        })
        return false
    end
    local newBalance = balance - bet
    local winner = pickWinner()
    local raceOrder = generateRaceOrder(winner)
    local won = (winner == horseIndex)
    local payout = 0
    local isConsol = false
    if won then
        local odds = rollOdds(horseIndex)
        payout = math.floor(bet * odds)
        sess.lossStreak = 0
        sess.totalWon = (sess.totalWon or 0) + (payout - bet)
    else
        sess.lossStreak = (sess.lossStreak or 0) + 1
    end
    local netLoss = bet - payout
    if netLoss > 0 then
        shared.depositCasinoLoss(source, netLoss, 'insidetrack_single')
    end
    local identifier = shared.getIdentifier(source)
    sess.raceLockUntil[source] = os.time() + math.ceil(config.RaceDuration / 1000) + 5
    sess.pending[source] = {
        payAt = GetGameTimer() + config.RaceDuration,
        amount = payout,
        won = won,
        isConsol = isConsol,
        winner = winner,
        bet = bet,
        horseIndex = horseIndex,
        finalBalance = newBalance + payout,
        identifier = identifier,
    }
    SetTimeout(config.RaceDuration, function()
        local p = sess.pending[source]
        if not p then return end
        sess.pending[source] = nil
        sess.raceLockUntil[source] = nil

        if not shared.playerExist(source) or shared.getIdentifier(source) ~= p.identifier then
            return
        end

        if p.amount > 0 then
            payPrize(source, p.amount, 'insidetrack_single', math.max(p.amount - p.bet, 0))
        end
        TriggerCasinoEvent('rhd_casino_insidetrack:client:singleResult', source, {
            won = p.won,
            isConsol = p.isConsol,
            payout = p.amount,
            bet = p.bet,
            horseIndex = p.horseIndex,
            winner = p.winner,
            finalBalance = ox_inventory:GetItemCount(source, shared.chipItemName) or 0,
        })
    end)
    return {
        raceOrder = raceOrder,
        winner = winner,
        newBalance = newBalance,
    }
end)

lib.callback.register('rhd_casino_insidetrack:checkSeat', function(source, tIndex)
    tIndex = math.floor(tonumber(tIndex) or 0)
    if tIndex < 1 or not Chairs[tIndex] or not isNearChair(source, tIndex) then
        return false
    end

    for _, occupant in pairs(insidetrack.seats) do
        if occupant == source then return false end
    end

    local occupant = insidetrack.seats[tIndex]
    if not occupant then
        insidetrack.seats[tIndex] = source
        gstate:set('insidetrack_seat_' .. tIndex, true, true)
        return true
    end
    return false
end)

RegisterNetEvent('rhd_casino_insidetrack:releaseSeat', function(tIndex)
    local source = source
    if type(tIndex) ~= 'number' then return end
    if insidetrack.seats[tIndex] == source then
        insidetrack.seats[tIndex] = nil
        gstate:set('insidetrack_seat_' .. tIndex, false, true)
    end
end)

---@param source number
local function releasePlayer(source)
    if insidetrack.phase == 'open' and insidetrack.bets[source] then
        addBalance(source, insidetrack.bets[source].bet)
        local horseIndex = insidetrack.bets[source].horseIndex
        insidetrack.bets[source] = nil

        local bettors = insidetrack.perHorse[horseIndex]
        if bettors then
            for i = #bettors, 1, -1 do
                if bettors[i].src == source then
                    table.remove(bettors, i)
                end
            end
        end
    end

    for tIndex, occupant in pairs(insidetrack.seats) do
        if occupant == source then
            insidetrack.seats[tIndex] = nil
            gstate:set('insidetrack_seat_' .. tIndex, false, true)
        end
    end

    insidetrack.single.pending[source] = nil
    insidetrack.single.raceLockUntil[source] = nil
end

AddEventHandler('rhd_casino:interiorChanged', function(source, inInterior)
    if inInterior then
        addSubscriber(source)
    end
end)

AddEventHandler('playerDropped', function()
    releasePlayer(source)
end)

AddEventHandler('rhd_casino:releasePlayer', function(playerId)
    releasePlayer(playerId)
end)
