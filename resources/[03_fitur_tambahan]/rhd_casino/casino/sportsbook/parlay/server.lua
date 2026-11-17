local config = require 'casino.sportsbook.parlay.config'
local common = require 'casino.sportsbook.modules.common'
local odds = require 'casino.sportsbook.modules.odds'
local locks = require 'casino.sportsbook.modules.locks'
local storage = require 'casino.sportsbook.parlay.storage'
local ufcStorage = require 'casino.sportsbook.ufc.storage'
local racingStorage = require 'casino.sportsbook.racing.storage'

---@alias ParlaySport 'ufc'|'racing'

---@class ParlayLegInput
---@field fightId any
---@field pick any
---@field lineId any

---@class ParlayResolvedLeg : ParlayLegRow
---@field lock string
---@field max_liability integer
---@field min_stake integer
---@field max_stake integer
---@field liability fun(): integer

local Parlay = {}

Parlay.publicConfig = {
    legBounds = config.legBounds,
    stakeBounds = config.stakeBounds,
    maxPayout = config.maxPayout,
    receiptItem = config.receiptItem,
    betIdPrefix = config.betId.prefix,
}

local prefix <const> = 'rhd_casino_parlay'
local handlers = {}

---@param name string
---@param handler function
local function callback(name, handler)
    handlers[name] = handler
    lib.callback.register(('%s:%s'):format(prefix, name), handler)
end

---@param title string
---@param logType string
---@param fields table[]
local function log(title, logType, fields)
    shared.log({ title = ('Parlay — %s'):format(title), type = logType, fields = fields })
end

---@param value any
---@return integer
local function toInt(value)
    return math.floor(tonumber(value) or 0)
end

---@param fightId integer?
---@return table<integer, { a: integer, b: integer }>
function Parlay.ufcLiability(fightId)
    return storage.getUfcLiability(fightId)
end

---@param eventId integer?
---@return table<integer, integer>
function Parlay.racingLiability(eventId)
    return storage.getRacingLiability(eventId)
end

---@param sport ParlaySport
---@param eventId integer
---@return { won: integer, lost: integer, void: integer }
local function resolveParlays(sport, eventId)
    local rows = storage.getOpenLegsForEvent(sport, eventId)
    local groups = {}
    local order = {}

    for i = 1, #rows do
        local row = rows[i]
        local seq = toInt(row.parlay_seq)

        if not groups[seq] then
            groups[seq] = { stake = toInt(row.stake), legs = {} }
            order[#order + 1] = seq
        end

        table.insert(groups[seq].legs, row)
    end

    local counts = { won = 0, lost = 0, void = 0 }

    for i = 1, #order do
        local seq = order[i]
        local group = groups[seq]
        local anyLost, anyPending = false, false
        local wonCount, product = 0, 1.0

        for j = 1, #group.legs do
            local status = group.legs[j].status

            if status == 'lost' then
                anyLost = true
            elseif status == 'pending' then
                anyPending = true
            elseif status == 'won' then
                wonCount += 1
                product *= tonumber(group.legs[j].odds) or 0
            end
        end

        if anyLost then
            if storage.finalizeParlay(seq, 'lost') then counts.lost += 1 end
        elseif not anyPending then
            if wonCount == 0 then
                if storage.finalizeParlay(seq, 'void') then counts.void += 1 end
            else
                local finalOdds = odds.round2(product)
                local payout = odds.potentialReturn(group.stake, finalOdds)
                if storage.finalizeParlay(seq, 'won', finalOdds, payout) then counts.won += 1 end
            end
        end
    end

    return counts
end

---@param sport ParlaySport
---@param eventId integer
---@param counts { won: integer, lost: integer, void: integer }
local function logResolution(sport, eventId, counts)
    if counts.won + counts.lost + counts.void == 0 then return end

    log('Parlay Resolved', 'info', {
        { name = 'Sport', value = sport:upper(), inline = true },
        { name = 'Event', value = ('#%s'):format(eventId), inline = true },
        { name = 'WON', value = tostring(counts.won), inline = true },
        { name = 'LOST', value = tostring(counts.lost), inline = true },
        { name = 'VOID', value = tostring(counts.void), inline = true },
    })
end

---@param fightId integer
---@param winner 'a'|'b'
function Parlay.settleUfc(fightId, winner)
    if not storage.settleUfcLegs(fightId, winner) then return end
    logResolution('ufc', fightId, resolveParlays('ufc', fightId))
end

---@param fightId integer
function Parlay.voidUfc(fightId)
    if not storage.voidLegs('ufc', fightId) then return end
    logResolution('ufc', fightId, resolveParlays('ufc', fightId))
end

---@param eventId integer
---@param resultOutcomeIds integer[]
---@param marketPlaces table<string, integer>
function Parlay.settleRacing(eventId, resultOutcomeIds, marketPlaces)
    if not storage.settleRacingLegs(eventId, resultOutcomeIds, marketPlaces) then return end
    logResolution('racing', eventId, resolveParlays('racing', eventId))
end

---@param eventId integer
function Parlay.voidRacing(eventId)
    if not storage.voidLegs('racing', eventId) then return end
    logResolution('racing', eventId, resolveParlays('racing', eventId))
end

---@param input ParlayLegInput
---@return ParlayResolvedLeg? leg
---@return string? err
local function buildUfcLeg(input)
    if type(input) ~= 'table' then return nil, 'Data leg tidak valid.' end

    local fightId = common.cleanInt(input.fightId, 1, math.maxinteger)
    local pick = input.pick
    if not fightId or (pick ~= 'a' and pick ~= 'b') then return nil, 'Pilihan fight tidak valid.' end

    local fight = ufcStorage.getFight(fightId)
    if not fight then return nil, 'Fight tidak ditemukan.' end
    if fight.status ~= 'open' then
        return nil, ('Betting untuk %s sedang tidak dibuka.'):format(fight.label)
    end

    local legOdds = tonumber(pick == 'a' and fight.odds_a or fight.odds_b) or 0
    if legOdds <= 0 then return nil, ('Odds %s tidak valid.'):format(fight.label) end

    return {
        event_id = fightId,
        pick = pick,
        event_label = fight.label,
        pick_name = pick == 'a' and fight.fighter_a or fight.fighter_b,
        odds = legOdds,
        lock = ('ufc:%d'):format(fightId),
        max_liability = toInt(pick == 'a' and fight.max_liability_a or fight.max_liability_b),
        min_stake = toInt(fight.min_stake),
        max_stake = toInt(fight.max_stake),
        liability = function()
            local extra = storage.getUfcLiability(fightId)[fightId]
            return ufcStorage.getLiability(fightId)[pick] + (extra and extra[pick] or 0)
        end,
    }
end

---@param input ParlayLegInput
---@return ParlayResolvedLeg? leg
---@return string? err
local function buildRacingLeg(input)
    if type(input) ~= 'table' then return nil, 'Data leg tidak valid.' end

    local lineId = common.cleanInt(input.lineId, 1, math.maxinteger)
    if not lineId then return nil, 'Pilihan taruhan tidak valid.' end

    local line = racingStorage.getLine(lineId)
    if not line then return nil, 'Pilihan taruhan tidak valid.' end

    local eventId = toInt(line.event_id)
    local event = racingStorage.getEvent(eventId)
    if not event then return nil, 'Event tidak ditemukan.' end
    if event.status ~= 'open' then
        return nil, ('Betting untuk %s sedang tidak dibuka.'):format(event.label)
    end
    if toInt(line.manual_closed) == 1 then
        return nil, ('%s sedang ditutup untuk taruhan.'):format(line.outcome_name)
    end

    local lineOdds = tonumber(line.odds) or 0
    if lineOdds <= 0 then return nil, ('Odds %s tidak valid.'):format(line.outcome_name) end

    return {
        event_id = eventId,
        line_id = lineId,
        market = line.market,
        outcome_id = toInt(line.outcome_id),
        event_label = event.label,
        pick_name = line.outcome_name,
        odds = lineOdds,
        lock = ('racing:%d'):format(lineId),
        max_liability = toInt(line.max_liability),
        min_stake = toInt(event.min_stake),
        max_stake = toInt(event.max_stake),
        liability = function()
            return (racingStorage.getLiability(eventId)[lineId] or 0)
                + (storage.getRacingLiability(eventId)[lineId] or 0)
        end,
    }
end

---@param rows table[]
---@return table[]
local function mapLegs(rows)
    local legs = {}

    for i = 1, #rows do
        local row = rows[i]
        legs[i] = {
            eventId = toInt(row.event_id),
            eventLabel = row.event_label,
            market = row.market,
            pickName = row.pick_name,
            odds = tonumber(row.odds) or 0,
            status = row.status or 'pending',
        }
    end

    return legs
end

---@param header table
---@param legRows table[]
---@return table
local function mapParlay(header, legRows)
    return {
        betId = header.bet_id,
        sport = header.sport,
        legCount = toInt(header.leg_count),
        odds = tonumber(header.odds) or 0,
        stake = toInt(header.stake),
        potentialReturn = toInt(header.potential_return),
        status = header.status,
        legs = mapLegs(legRows),
        bettorName = header.bettor_name,
        staffBetName = header.staff_bet_name,
        staffPaidName = header.staff_paid_name,
        receiptTaken = toInt(header.receipt_taken) == 1,
        createdAt = header.created_at,
        paidAt = header.paid_at,
    }
end

callback('placeParlay', function(source, data)
    if not common.hasRole(source, 'staff') then return false, 'Akses ditolak.' end
    if type(data) ~= 'table' then return false, 'Data parlay tidak valid.' end

    local sport = data.sport
    local buildLeg = sport == 'ufc' and buildUfcLeg
        or sport == 'racing' and buildRacingLeg
        or nil
    if not buildLeg then return false, 'Sport tidak valid.' end

    local input = data.legs
    if type(input) ~= 'table' then return false, 'Daftar leg tidak valid.' end

    local count = #input
    if count < config.legBounds.min or count > config.legBounds.max then
        return false, ('Parlay harus berisi %d sampai %d leg.'):format(config.legBounds.min, config.legBounds.max)
    end

    local bettorSource = common.cleanInt(data.bettorSource, 1, math.maxinteger)
    if not bettorSource or not shared.playerExist(bettorSource) then
        return false, 'Bettor tidak ditemukan.'
    end
    if not common.isNearStaff(source, bettorSource) then
        return false, 'Bettor harus berada di dekat kamu.'
    end

    local legs = {}
    local keys = {}
    local seenEvent = {}
    local minStake, maxStake = config.stakeBounds.min, config.stakeBounds.max
    local product = 1.0

    for i = 1, count do
        local leg, err = buildLeg(input[i])
        if not leg then return false, err end

        if seenEvent[leg.event_id] then
            return false, ('%s dipakai lebih dari satu leg.'):format(leg.event_label)
        end
        seenEvent[leg.event_id] = true

        legs[i] = leg
        keys[i] = leg.lock
        if leg.min_stake > minStake then minStake = leg.min_stake end
        if leg.max_stake < maxStake then maxStake = leg.max_stake end
        product *= leg.odds
    end

    if minStake > maxStake then
        return false, 'Batas stake antar event tidak bisa digabung dalam satu parlay.'
    end

    local stake = common.cleanInt(data.stake, minStake, maxStake)
    if not stake then
        return false, ('Stake harus antara %s dan %s chip.'):format(minStake, maxStake)
    end

    local combinedOdds = odds.round2(product)
    local potentialReturn = odds.potentialReturn(stake, combinedOdds)
    if potentialReturn <= 0 then return false, 'Potential return tidak valid.' end
    if potentialReturn > config.maxPayout then
        return false, ('Potential return %s melebihi batas maksimum %s chip.'):format(potentialReturn, config.maxPayout)
    end

    locks.acquire(keys)

    for i = 1, #legs do
        local leg = legs[i]
        local remaining = math.max(leg.max_liability - leg.liability(), 0)

        if potentialReturn > remaining then
            locks.release(keys)
            return false, ('BET REJECTED — sisa liability %s (%s) %s chip, potential return %s chip.')
                :format(leg.event_label, leg.pick_name, remaining, potentialReturn)
        end
    end

    local staff = common.staffInfo(source)
    local bettorName = shared.getPlayerName(bettorSource)

    local betId = storage.insertParlay({
        sport = sport,
        leg_count = count,
        odds = combinedOdds,
        stake = stake,
        potential_return = potentialReturn,
        bettor_identifier = shared.getIdentifier(bettorSource),
        bettor_name = bettorName,
        staff_bet_identifier = staff.identifier,
        staff_bet_name = staff.name,
    }, legs)

    locks.release(keys)

    if not betId then return false, 'Gagal menyimpan parlay.' end

    local summary = {}
    for i = 1, #legs do
        summary[i] = ('%s: %s @ %s'):format(legs[i].event_label, legs[i].pick_name, legs[i].odds)
    end

    local receiptGiven = ox_inventory:AddItem(bettorSource, config.receiptItem, 1, {
        betId = betId,
        sport = sport,
        legs = table.concat(summary, '\n'),
        odds = combinedOdds,
        stake = stake,
        potentialReturn = potentialReturn,
        description = ('%s\n%d leg @ %s\nStake %s → %s'):format(betId, count, combinedOdds, stake, potentialReturn),
    })

    log('Parlay Confirmed', 'money', {
        { name = 'Bet ID', value = betId },
        { name = 'Sport', value = sport:upper(), inline = true },
        { name = 'Bettor', value = ('%s (%s)'):format(bettorName, bettorSource), inline = true },
        { name = 'Leg', value = table.concat(summary, '\n') },
        { name = 'Combined Odds', value = tostring(combinedOdds), inline = true },
        { name = 'Stake', value = ('%s chips'):format(stake), inline = true },
        { name = 'Potential Return', value = ('%s chips'):format(potentialReturn), inline = true },
        { name = 'Staff', value = ('%s (%s)'):format(staff.name, source), inline = true },
        { name = 'Receipt', value = receiptGiven and 'Given' or 'FAILED (inventory full)', inline = true },
    })

    return true, {
        betId = betId,
        sport = sport,
        legs = mapLegs(legs),
        odds = combinedOdds,
        stake = stake,
        potentialReturn = potentialReturn,
        bettorName = bettorName,
        staffName = staff.name,
        receiptGiven = receiptGiven == true,
    }
end)

callback('lookupParlay', function(source, betId)
    if not common.hasRole(source, 'staff') then return false, 'Akses ditolak.' end

    local id = common.cleanString(betId, 24)
    if not id then return false, 'Bet ID tidak valid.' end

    local header, legRows = storage.getParlay(id:upper())
    if not header then return false, 'Bet ID tidak ditemukan.' end

    return true, mapParlay(header, legRows)
end)

callback('markPaid', function(source, betId, claimantSource)
    if not common.hasRole(source, 'staff') then return false, 'Akses ditolak.' end

    local id = common.cleanString(betId, 24)
    if not id then return false, 'Bet ID tidak valid.' end

    local header = storage.getParlay(id:upper())
    if not header then return false, 'Bet ID tidak ditemukan.' end

    if header.status == 'paid' or header.status == 'refunded' then
        return false, 'BET ALREADY PAID'
    end

    local nextStatus = header.status == 'won' and 'paid'
        or header.status == 'void' and 'refunded'
        or nil

    if not nextStatus then
        return false, ('Parlay berstatus %s tidak bisa diklaim.'):format(header.status:upper())
    end

    local claimant = common.cleanInt(claimantSource, 1, math.maxinteger)
    if not claimant or not shared.playerExist(claimant) then
        return false, 'Penerima pembayaran tidak ditemukan.'
    end
    if not common.isNearStaff(source, claimant) then
        return false, 'Penerima harus berada di dekat kamu.'
    end

    local staff = common.staffInfo(source)

    if not storage.markPaid(header.bet_id, nextStatus, header.status, staff, false) then
        return false, 'Status parlay berubah, coba cari ulang Bet ID.'
    end

    local receiptTaken = false
    local slots = ox_inventory:Search(claimant, 'slots', config.receiptItem, { betId = header.bet_id })

    if type(slots) == 'table' and slots[1] then
        receiptTaken = ox_inventory:RemoveItem(claimant, config.receiptItem, 1, nil, slots[1].slot) == true
        if receiptTaken then
            storage.setReceiptTaken(header.bet_id)
        end
    end

    local amount = nextStatus == 'paid' and toInt(header.potential_return) or toInt(header.stake)

    log(nextStatus == 'paid' and 'Payout Paid' or 'Stake Refunded', 'money', {
        { name = 'Bet ID', value = header.bet_id },
        { name = 'Sport', value = tostring(header.sport):upper(), inline = true },
        { name = 'Bettor', value = header.bettor_name, inline = true },
        { name = 'Receiver', value = ('%s (%s)'):format(shared.getPlayerName(claimant), claimant), inline = true },
        { name = 'Amount', value = ('%s chips'):format(amount), inline = true },
        { name = 'Staff', value = ('%s (%s)'):format(staff.name, source), inline = true },
        { name = 'Receipt', value = receiptTaken and 'Collected' or 'NOT in receiver inventory', inline = true },
    })

    return true, {
        betId = header.bet_id,
        status = nextStatus,
        amount = amount,
        receiptTaken = receiptTaken,
    }
end)

callback('getParlays', function(source, sport)
    if not common.hasRole(source, 'admin') then return false, 'Akses ditolak.' end
    if sport ~= 'ufc' and sport ~= 'racing' then return false, 'Sport tidak valid.' end

    local headers = storage.getParlays(sport)
    local seqs = {}
    for i = 1, #headers do
        seqs[i] = toInt(headers[i].seq)
    end

    local legsBySeq = storage.getLegs(seqs)
    local parlays = {}
    for i = 1, #headers do
        parlays[i] = mapParlay(headers[i], legsBySeq[seqs[i]] or {})
    end

    local totals = storage.getTotals(sport) or {}
    local totalStake = toInt(totals.total_stake)
    local paidOut = toInt(totals.paid_out)
    local refundedOut = toInt(totals.refunded_out)

    return true, {
        parlays = parlays,
        totals = {
            betCount = toInt(totals.bet_count),
            totalStake = totalStake,
            totalPotential = toInt(totals.total_potential),
            actualPayout = paidOut + refundedOut,
            profit = totalStake - paidOut - refundedOut,
            confirmed = toInt(totals.count_confirmed),
            won = toInt(totals.count_won),
            lost = toInt(totals.count_lost),
            void = toInt(totals.count_void),
            paid = toInt(totals.count_paid),
            refunded = toInt(totals.count_refunded),
        },
    }
end)

local HEAVY <const> = { getParlays = true }

RegisterNetEvent(('%s:request'):format(prefix), function(requestId, name, ...)
    local src = source

    if type(requestId) ~= 'number' or not HEAVY[name] then return end

    local ok, result = handlers[name](src, ...)

    TriggerCasinoEvent(('%s:response'):format(prefix), src, requestId, ok, result)
end)

return Parlay
