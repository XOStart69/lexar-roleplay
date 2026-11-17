local baseStorage = require 'modules.storage'
local config = require 'casino.sportsbook.parlay.config'

local safeCall = baseStorage.safeCall
local Storage = {}

local tablesReady = false

local function ensureTables()
    if tablesReady then return true end

    local ok = safeCall('ensure parlay tables', function()
        db:execute_async([[
            create table if not exists rhd_casino_parlay_bets (
                seq bigint unsigned not null auto_increment,
                bet_id varchar(24) null,
                sport varchar(16) not null,
                leg_count tinyint unsigned not null,
                odds decimal(12,2) not null,
                stake bigint unsigned not null,
                potential_return bigint unsigned not null,
                status varchar(16) not null default 'confirmed',
                bettor_identifier varchar(64) null,
                bettor_name varchar(128) not null,
                staff_bet_identifier varchar(64) null,
                staff_bet_name varchar(128) null,
                staff_paid_identifier varchar(64) null,
                staff_paid_name varchar(128) null,
                receipt_taken tinyint(1) not null default 0,
                created_at timestamp not null default current_timestamp,
                settled_at timestamp null,
                paid_at timestamp null,
                primary key (seq),
                unique key idx_bet_id (bet_id),
                key idx_sport_status (sport, status)
            )
        ]])

        db:execute_async([[
            create table if not exists rhd_casino_parlay_legs (
                id bigint unsigned not null auto_increment,
                parlay_seq bigint unsigned not null,
                sport varchar(16) not null,
                event_id int unsigned not null,
                line_id int unsigned null,
                pick varchar(1) null,
                market varchar(16) null,
                outcome_id int unsigned null,
                event_label varchar(64) not null,
                pick_name varchar(64) not null,
                odds decimal(8,2) not null,
                status varchar(16) not null default 'pending',
                primary key (id),
                key idx_parlay (parlay_seq),
                key idx_event (sport, event_id),
                key idx_line (line_id)
            )
        ]])

        return true
    end, false)

    tablesReady = ok == true
    return tablesReady
end

Citizen.CreateThreadNow(ensureTables)

---@param seq integer
---@return string
local function formatBetId(seq)
    return ('%s%0' .. config.betId.digits .. 'd'):format(config.betId.prefix, seq)
end

---@param ids integer[]
---@return string
local function idList(ids)
    local parts = {}
    for i = 1, #ids do
        parts[i] = tostring(math.floor(ids[i]))
    end
    return table.concat(parts, ',')
end

---@param limit any
---@return integer
local function sanitizeLimit(limit)
    limit = math.floor(tonumber(limit) or 100)
    if limit < 1 then return 100 end
    if limit > 500 then return 500 end
    return limit
end

---@class ParlayLegRow
---@field event_id integer
---@field line_id integer?
---@field pick string?
---@field market string?
---@field outcome_id integer?
---@field event_label string
---@field pick_name string
---@field odds number

---@param header table
---@param legs ParlayLegRow[]
---@return string? betId
function Storage.insertParlay(header, legs)
    if not ensureTables() then return nil end

    return safeCall('insert parlay', function()
        local seq = db:insert_async([[
            insert into rhd_casino_parlay_bets (
                sport, leg_count, odds, stake, potential_return,
                bettor_identifier, bettor_name, staff_bet_identifier, staff_bet_name
            ) values (
                @sport, @leg_count, @odds, @stake, @potential_return,
                @bettor_identifier, @bettor_name, @staff_bet_identifier, @staff_bet_name
            )
        ]], header)

        if not seq then return nil end

        local ok, err = pcall(function()
            for i = 1, #legs do
                local leg = legs[i]

                db:execute_async([[
                    insert into rhd_casino_parlay_legs (
                        parlay_seq, sport, event_id, line_id, pick, market, outcome_id,
                        event_label, pick_name, odds
                    ) values (
                        @parlay_seq, @sport, @event_id, @line_id, @pick, @market, @outcome_id,
                        @event_label, @pick_name, @odds
                    )
                ]], {
                    parlay_seq = seq,
                    sport = header.sport,
                    event_id = leg.event_id,
                    line_id = leg.line_id,
                    pick = leg.pick,
                    market = leg.market,
                    outcome_id = leg.outcome_id,
                    event_label = leg.event_label,
                    pick_name = leg.pick_name,
                    odds = leg.odds,
                })
            end
        end)

        if not ok then
            db:execute_async('delete from rhd_casino_parlay_legs where parlay_seq = @seq', { seq = seq })
            db:execute_async('delete from rhd_casino_parlay_bets where seq = @seq', { seq = seq })
            error(err)
        end

        local betId = formatBetId(seq)

        db:execute_async(
            'update rhd_casino_parlay_bets set bet_id = @bet_id where seq = @seq',
            { bet_id = betId, seq = seq }
        )

        return betId
    end, nil)
end

---@param seqs integer[]
---@return table<integer, table[]>
function Storage.getLegs(seqs)
    local result = {}
    if #seqs == 0 or not ensureTables() then return result end

    local rows = safeCall('get parlay legs', function()
        return db:query_async([[
            select * from rhd_casino_parlay_legs
            where find_in_set(parlay_seq, @seqs)
            order by parlay_seq, id
        ]], { seqs = idList(seqs) })
    end, {}) or {}

    for i = 1, #rows do
        local row = rows[i]
        local seq = math.floor(tonumber(row.parlay_seq) or 0)
        result[seq] = result[seq] or {}
        table.insert(result[seq], row)
    end

    return result
end

---@param betId string
---@return table? header
---@return table[] legs
function Storage.getParlay(betId)
    if not ensureTables() then return nil, {} end

    local header = safeCall('get parlay', function()
        return db:single_async(
            'select * from rhd_casino_parlay_bets where bet_id = @betId',
            { betId = betId }
        )
    end, nil)

    if not header then return nil, {} end

    local seq = math.floor(tonumber(header.seq) or 0)
    return header, Storage.getLegs({ seq })[seq] or {}
end

---@param sport string
---@param limit integer?
---@return table[]
function Storage.getParlays(sport, limit)
    if not ensureTables() then return {} end

    return safeCall('get parlays', function()
        return db:query_async([[
            select * from rhd_casino_parlay_bets
            where sport = @sport
            order by seq desc
            limit @limit
        ]], { sport = sport, limit = sanitizeLimit(limit) })
    end, {}) or {}
end

---@param sport string
---@return table?
function Storage.getTotals(sport)
    if not ensureTables() then return nil end

    return safeCall('get parlay totals', function()
        return db:single_async([[
            select
                count(*) as bet_count,
                coalesce(sum(stake), 0) as total_stake,
                coalesce(sum(case when status in ('confirmed', 'won') then potential_return else 0 end), 0) as total_potential,
                coalesce(sum(case when status = 'paid' then potential_return else 0 end), 0) as paid_out,
                coalesce(sum(case when status = 'refunded' then stake else 0 end), 0) as refunded_out,
                coalesce(sum(status = 'confirmed'), 0) as count_confirmed,
                coalesce(sum(status = 'won'), 0) as count_won,
                coalesce(sum(status = 'lost'), 0) as count_lost,
                coalesce(sum(status = 'void'), 0) as count_void,
                coalesce(sum(status = 'paid'), 0) as count_paid,
                coalesce(sum(status = 'refunded'), 0) as count_refunded
            from rhd_casino_parlay_bets
            where sport = @sport
        ]], { sport = sport })
    end, nil)
end

---@param fightId integer?
---@return table<integer, { a: integer, b: integer }>
function Storage.getUfcLiability(fightId)
    local result = {}
    if not ensureTables() then return result end

    local rows = safeCall('get parlay ufc liability', function()
        return db:query_async([[
            select l.event_id, l.pick, coalesce(sum(p.potential_return), 0) as liability
            from rhd_casino_parlay_legs l
            inner join rhd_casino_parlay_bets p on p.seq = l.parlay_seq
            where l.sport = 'ufc' and p.status in ('confirmed', 'won')
              and (@fightId is null or l.event_id = @fightId)
            group by l.event_id, l.pick
        ]], { fightId = fightId })
    end, {}) or {}

    for i = 1, #rows do
        local row = rows[i]
        local id = math.floor(tonumber(row.event_id) or 0)
        result[id] = result[id] or { a = 0, b = 0 }
        if row.pick == 'a' or row.pick == 'b' then
            result[id][row.pick] = math.floor(tonumber(row.liability) or 0)
        end
    end

    return result
end

---@param eventId integer?
---@return table<integer, integer>
function Storage.getRacingLiability(eventId)
    local result = {}
    if not ensureTables() then return result end

    local rows = safeCall('get parlay racing liability', function()
        return db:query_async([[
            select l.line_id, coalesce(sum(p.potential_return), 0) as liability
            from rhd_casino_parlay_legs l
            inner join rhd_casino_parlay_bets p on p.seq = l.parlay_seq
            where l.sport = 'racing' and p.status in ('confirmed', 'won')
              and (@eventId is null or l.event_id = @eventId)
            group by l.line_id
        ]], { eventId = eventId })
    end, {}) or {}

    for i = 1, #rows do
        local row = rows[i]
        result[math.floor(tonumber(row.line_id) or 0)] = math.floor(tonumber(row.liability) or 0)
    end

    return result
end

---@param fightId integer
---@param winner 'a'|'b'
---@return boolean
function Storage.settleUfcLegs(fightId, winner)
    if not ensureTables() then return false end

    return safeCall('settle parlay ufc legs', function()
        db:execute_async([[
            update rhd_casino_parlay_legs
            set status = 'won'
            where sport = 'ufc' and event_id = @id and status = 'pending' and pick = @winner
        ]], { id = fightId, winner = winner })

        db:execute_async([[
            update rhd_casino_parlay_legs
            set status = 'lost'
            where sport = 'ufc' and event_id = @id and status = 'pending'
        ]], { id = fightId })

        return true
    end, false)
end

---@param eventId integer
---@param resultOutcomeIds integer[]
---@param marketPlaces table<string, integer>
---@return boolean
function Storage.settleRacingLegs(eventId, resultOutcomeIds, marketPlaces)
    if not ensureTables() then return false end

    return safeCall('settle parlay racing legs', function()
        for market, places in pairs(marketPlaces) do
            local winners = {}
            for i = 1, math.min(places, #resultOutcomeIds) do
                winners[i] = resultOutcomeIds[i]
            end

            db:execute_async([[
                update rhd_casino_parlay_legs
                set status = 'won'
                where sport = 'racing' and event_id = @id and market = @market and status = 'pending'
                  and find_in_set(outcome_id, @winners)
            ]], { id = eventId, market = market, winners = idList(winners) })

            db:execute_async([[
                update rhd_casino_parlay_legs
                set status = 'lost'
                where sport = 'racing' and event_id = @id and market = @market and status = 'pending'
            ]], { id = eventId, market = market })
        end

        return true
    end, false)
end

---@param sport string
---@param eventId integer
---@return boolean
function Storage.voidLegs(sport, eventId)
    if not ensureTables() then return false end

    return safeCall('void parlay legs', function()
        db:execute_async([[
            update rhd_casino_parlay_legs
            set status = 'void'
            where sport = @sport and event_id = @id and status = 'pending'
        ]], { sport = sport, id = eventId })

        return true
    end, false)
end

---@param sport string
---@param eventId integer
---@return table[]
function Storage.getOpenLegsForEvent(sport, eventId)
    if not ensureTables() then return {} end

    return safeCall('get open parlay legs', function()
        return db:query_async([[
            select l.*, p.stake
            from rhd_casino_parlay_legs l
            inner join rhd_casino_parlay_bets p on p.seq = l.parlay_seq
            where p.status = 'confirmed'
              and p.seq in (
                  select parlay_seq from rhd_casino_parlay_legs
                  where sport = @sport and event_id = @id
              )
            order by l.parlay_seq, l.id
        ]], { sport = sport, id = eventId })
    end, {}) or {}
end

---@param seq integer
---@param status 'won'|'lost'|'void'
---@param odds number?
---@param potentialReturn integer?
---@return boolean
function Storage.finalizeParlay(seq, status, odds, potentialReturn)
    if not ensureTables() then return false end

    local affected = safeCall('finalize parlay', function()
        return db:update_async([[
            update rhd_casino_parlay_bets set
                status = @status,
                odds = coalesce(@odds, odds),
                potential_return = coalesce(@potential_return, potential_return),
                settled_at = current_timestamp
            where seq = @seq and status = 'confirmed'
        ]], {
            seq = seq,
            status = status,
            odds = odds,
            potential_return = potentialReturn,
        })
    end, 0)

    return (tonumber(affected) or 0) > 0
end

---@param betId string
---@param nextStatus 'paid'|'refunded'
---@param fromStatus string
---@param staff { identifier: string?, name: string }
---@param receiptTaken boolean
---@return boolean
function Storage.markPaid(betId, nextStatus, fromStatus, staff, receiptTaken)
    if not ensureTables() then return false end

    local affected = safeCall('mark parlay paid', function()
        return db:update_async([[
            update rhd_casino_parlay_bets set
                status = @nextStatus,
                staff_paid_identifier = @staffIdentifier,
                staff_paid_name = @staffName,
                receipt_taken = @receiptTaken,
                paid_at = current_timestamp
            where bet_id = @betId and status = @fromStatus
        ]], {
            betId = betId,
            nextStatus = nextStatus,
            fromStatus = fromStatus,
            staffIdentifier = staff.identifier,
            staffName = staff.name,
            receiptTaken = receiptTaken and 1 or 0,
        })
    end, 0)

    return (tonumber(affected) or 0) > 0
end

---@param betId string
---@return boolean
function Storage.setReceiptTaken(betId)
    if not ensureTables() then return false end

    return safeCall('set parlay receipt taken', function()
        db:execute_async(
            'update rhd_casino_parlay_bets set receipt_taken = 1 where bet_id = @betId',
            { betId = betId }
        )
        return true
    end, false)
end

return Storage
