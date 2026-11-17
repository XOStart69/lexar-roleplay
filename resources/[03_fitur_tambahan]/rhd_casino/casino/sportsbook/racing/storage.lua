local baseStorage = require 'modules.storage'

local safeCall = baseStorage.safeCall
local Storage = {}

local tablesReady = false

local function ensureTables()
    if tablesReady then return true end

    local ok = safeCall('ensure racing tables', function()
        db:execute_async([[
            create table if not exists rhd_casino_racing_events (
                id int unsigned not null auto_increment,
                label varchar(64) not null,
                house_edge decimal(5,2) not null default 0,
                min_stake bigint unsigned not null default 0,
                max_stake bigint unsigned not null default 0,
                status varchar(16) not null default 'draft',
                result_outcome_ids varchar(191) null,
                archived tinyint(1) not null default 0,
                created_by_name varchar(128) null,
                created_by_identifier varchar(64) null,
                created_at timestamp not null default current_timestamp,
                updated_at timestamp not null default current_timestamp on update current_timestamp,
                primary key (id),
                key idx_status (status)
            )
        ]])

        db:execute_async([[
            create table if not exists rhd_casino_racing_outcomes (
                id int unsigned not null auto_increment,
                event_id int unsigned not null,
                slot tinyint unsigned not null,
                name varchar(64) not null,
                primary key (id),
                key idx_event (event_id)
            )
        ]])

        db:execute_async([[
            create table if not exists rhd_casino_racing_lines (
                id int unsigned not null auto_increment,
                event_id int unsigned not null,
                outcome_id int unsigned not null,
                market varchar(16) not null,
                probability decimal(5,2) not null,
                odds decimal(8,2) not null,
                max_liability bigint unsigned not null default 0,
                manual_closed tinyint(1) not null default 0,
                primary key (id),
                unique key idx_outcome_market (outcome_id, market),
                key idx_event_market (event_id, market)
            )
        ]])

        db:execute_async([[
            create table if not exists rhd_casino_racing_bets (
                seq bigint unsigned not null auto_increment,
                bet_id varchar(24) null,
                event_id int unsigned not null,
                line_id int unsigned not null,
                outcome_id int unsigned not null,
                market varchar(16) not null,
                odds decimal(8,2) not null,
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
                paid_at timestamp null,
                primary key (seq),
                unique key idx_bet_id (bet_id),
                key idx_event (event_id),
                key idx_line (line_id),
                key idx_status (status)
            )
        ]])

        return true
    end, false)

    tablesReady = ok == true
    return tablesReady
end

Citizen.CreateThreadNow(ensureTables)

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

local EVENT_SELECT = [[
    select
        e.*,
        (select count(*) from rhd_casino_racing_bets b where b.event_id = e.id) as bet_count
    from rhd_casino_racing_events e
]]

---Menulis outcome beserta line-nya. Dipakai saat create maupun saat draft di-update.
---@param eventId integer
---@param outcomes { name: string, lines: { market: string, probability: number, odds: number, maxLiability: integer }[] }[]
local function writeOutcomes(eventId, outcomes)
    for i = 1, #outcomes do
        local outcome = outcomes[i]

        local outcomeId = db:insert_async([[
            insert into rhd_casino_racing_outcomes (event_id, slot, name)
            values (@event_id, @slot, @name)
        ]], { event_id = eventId, slot = i, name = outcome.name })

        if not outcomeId then error(('gagal menyimpan outcome slot %d'):format(i)) end

        for j = 1, #outcome.lines do
            local line = outcome.lines[j]

            db:execute_async([[
                insert into rhd_casino_racing_lines (
                    event_id, outcome_id, market, probability, odds, max_liability
                ) values (
                    @event_id, @outcome_id, @market, @probability, @odds, @max_liability
                )
            ]], {
                event_id = eventId,
                outcome_id = outcomeId,
                market = line.market,
                probability = line.probability,
                odds = line.odds,
                max_liability = line.maxLiability,
            })
        end
    end
end

---@param eventId integer
local function clearOutcomes(eventId)
    db:execute_async('delete from rhd_casino_racing_lines where event_id = @id', { id = eventId })
    db:execute_async('delete from rhd_casino_racing_outcomes where event_id = @id', { id = eventId })
end

---@param event table
---@param outcomes table[]
---@return integer? eventId
function Storage.createEvent(event, outcomes)
    if not ensureTables() then return nil end

    return safeCall('create racing event', function()
        local eventId = db:insert_async([[
            insert into rhd_casino_racing_events (
                label, house_edge, min_stake, max_stake,
                created_by_name, created_by_identifier
            ) values (
                @label, @house_edge, @min_stake, @max_stake,
                @created_by_name, @created_by_identifier
            )
        ]], event)

        if not eventId then return nil end

        -- Outcome gagal disimpan berarti event-nya tidak berguna; buang supaya tidak jadi baris yatim.
        local ok, err = pcall(writeOutcomes, eventId, outcomes)
        if not ok then
            clearOutcomes(eventId)
            db:execute_async('delete from rhd_casino_racing_events where id = @id', { id = eventId })
            error(err)
        end

        return eventId
    end, nil)
end

---@param id integer
---@param event table
---@param outcomes table[]
---@return boolean
function Storage.updateEvent(id, event, outcomes)
    if not ensureTables() then return false end

    return safeCall('update racing event', function()
        event.id = id

        local affected = db:update_async([[
            update rhd_casino_racing_events set
                label = @label,
                house_edge = @house_edge,
                min_stake = @min_stake,
                max_stake = @max_stake
            where id = @id and status = 'draft'
        ]], event)

        if (tonumber(affected) or 0) <= 0 then
            -- Nilai bisa saja tidak berubah sama sekali; pastikan lewat status, bukan lewat affected rows.
            local status = db:scalar_async(
                'select status from rhd_casino_racing_events where id = @id', { id = id }
            )
            if status ~= 'draft' then return false end
        end

        clearOutcomes(id)
        writeOutcomes(id, outcomes)

        return true
    end, false)
end

---@param id integer
---@return table?
function Storage.getEvent(id)
    if not ensureTables() then return nil end

    return safeCall('get racing event', function()
        return db:single_async(EVENT_SELECT .. ' where e.id = @id', { id = id })
    end, nil)
end

---Daftar untuk tab Kelola. Event terarsip disaring langsung di SQL.
---@param limit integer?
---@return table[]
function Storage.getEvents(limit)
    if not ensureTables() then return {} end

    return safeCall('get racing events', function()
        return db:query_async(EVENT_SELECT .. [[
            where e.archived = 0
            order by field(e.status, 'open', 'closed', 'draft', 'settled', 'void'), e.id desc
            limit @limit
        ]], { limit = sanitizeLimit(limit) })
    end, {}) or {}
end

---Daftar untuk tab Rekap: hanya event selesai, terarsip atau tidak.
---@param limit integer?
---@return table[]
function Storage.getRecapEvents(limit)
    if not ensureTables() then return {} end

    return safeCall('get racing recap events', function()
        return db:query_async(EVENT_SELECT .. [[
            where e.status in ('settled', 'void')
            order by e.id desc
            limit @limit
        ]], { limit = sanitizeLimit(limit) })
    end, {}) or {}
end

---@param eventIds integer[]
---@return table[]
function Storage.getOutcomesForEvents(eventIds)
    if #eventIds == 0 or not ensureTables() then return {} end

    return safeCall('get racing outcomes', function()
        return db:query_async([[
            select * from rhd_casino_racing_outcomes
            where find_in_set(event_id, @ids)
            order by event_id, slot
        ]], { ids = idList(eventIds) })
    end, {}) or {}
end

---Line beserta liability berjalannya, supaya daftar event tidak perlu query per baris.
---@param eventIds integer[]
---@return table[]
function Storage.getLinesForEvents(eventIds)
    if #eventIds == 0 or not ensureTables() then return {} end

    return safeCall('get racing lines', function()
        return db:query_async([[
            select
                l.*,
                coalesce((
                    select sum(b.potential_return) from rhd_casino_racing_bets b
                    where b.line_id = l.id and b.status in ('confirmed', 'won')
                ), 0) as liability
            from rhd_casino_racing_lines l
            where find_in_set(l.event_id, @ids)
            order by l.event_id, l.market, l.id
        ]], { ids = idList(eventIds) })
    end, {}) or {}
end

---@param id integer
---@param status string
---@param allowedFrom string[]
---@return boolean
function Storage.setEventStatus(id, status, allowedFrom)
    if not ensureTables() then return false end

    local affected = safeCall('set racing event status', function()
        return db:update_async([[
            update rhd_casino_racing_events
            set status = @status
            where id = @id and find_in_set(status, @allowed)
        ]], {
            id = id,
            status = status,
            allowed = table.concat(allowedFrom, ','),
        })
    end, 0)

    return (tonumber(affected) or 0) > 0
end

---@param lineId integer
---@param closed boolean
---@return boolean
function Storage.setLineClosed(lineId, closed)
    if not ensureTables() then return false end

    local affected = safeCall('set racing line closed', function()
        return db:update_async([[
            update rhd_casino_racing_lines
            set manual_closed = @closed
            where id = @id
        ]], { id = lineId, closed = closed and 1 or 0 })
    end, 0)

    return (tonumber(affected) or 0) > 0
end

---@param lineId integer
---@return table?
function Storage.getLine(lineId)
    if not ensureTables() then return nil end

    return safeCall('get racing line', function()
        return db:single_async([[
            select
                l.*,
                o.name as outcome_name,
                o.slot as outcome_slot,
                coalesce((
                    select sum(b.potential_return) from rhd_casino_racing_bets b
                    where b.line_id = l.id and b.status in ('confirmed', 'won')
                ), 0) as liability
            from rhd_casino_racing_lines l
            inner join rhd_casino_racing_outcomes o on o.id = l.outcome_id
            where l.id = @id
        ]], { id = lineId })
    end, nil)
end

---Menyelesaikan event. Bet menang kalau outcome-nya masuk `places` teratas di market tersebut.
---@param id integer
---@param resultOutcomeIds integer[] urut dari posisi pertama
---@param marketPlaces table<string, integer>
---@return boolean
function Storage.settleEvent(id, resultOutcomeIds, marketPlaces)
    if not ensureTables() then return false end

    return safeCall('settle racing event', function()
        db:execute_async([[
            update rhd_casino_racing_events
            set status = 'settled', result_outcome_ids = @result
            where id = @id and status in ('open', 'closed')
        ]], { id = id, result = idList(resultOutcomeIds) })

        for market, places in pairs(marketPlaces) do
            local winners = {}
            for i = 1, math.min(places, #resultOutcomeIds) do
                winners[i] = resultOutcomeIds[i]
            end

            db:execute_async([[
                update rhd_casino_racing_bets
                set status = 'won'
                where event_id = @id and market = @market and status = 'confirmed'
                  and find_in_set(outcome_id, @winners)
            ]], { id = id, market = market, winners = idList(winners) })

            db:execute_async([[
                update rhd_casino_racing_bets
                set status = 'lost'
                where event_id = @id and market = @market and status = 'confirmed'
            ]], { id = id, market = market })
        end

        return true
    end, false)
end

---@param id integer
---@return boolean
function Storage.voidEvent(id)
    if not ensureTables() then return false end

    return safeCall('void racing event', function()
        db:execute_async([[
            update rhd_casino_racing_events
            set status = 'void', result_outcome_ids = null
            where id = @id and status in ('draft', 'open', 'closed')
        ]], { id = id })

        db:execute_async([[
            update rhd_casino_racing_bets
            set status = 'void'
            where event_id = @id and status = 'confirmed'
        ]], { id = id })

        return true
    end, false)
end

---Menyembunyikan event dari daftar kelola tanpa menghapus datanya, supaya rekapnya tetap utuh.
---@param id integer
---@return boolean
function Storage.archiveEvent(id)
    if not ensureTables() then return false end

    local affected = safeCall('archive racing event', function()
        return db:update_async([[
            update rhd_casino_racing_events
            set archived = 1
            where id = @id and status in ('settled', 'void')
        ]], { id = id })
    end, 0)

    if (tonumber(affected) or 0) > 0 then return true end

    lib.print.warn(('[CasinoRacing] archiveEvent(%s) tidak mengubah baris apa pun.'):format(id))

    return false
end

---Menghapus event beserta outcome, line, dan seluruh taruhannya.
---@param id integer
---@return boolean ok, integer deletedBets
function Storage.deleteEvent(id)
    if not ensureTables() then return false, 0 end

    local betCount = 0

    local ok = safeCall('delete racing event', function()
        betCount = math.floor(tonumber(db:scalar_async([[
            select count(*) from rhd_casino_racing_bets where event_id = @id
        ]], { id = id })) or 0)

        db:execute_async('delete from rhd_casino_racing_bets where event_id = @id', { id = id })
        clearOutcomes(id)

        local affected = db:update_async(
            'delete from rhd_casino_racing_events where id = @id', { id = id }
        )

        return (tonumber(affected) or 0) > 0
    end, false)

    return ok == true, betCount
end

---Total potential payout yang masih ditanggung casino, per line.
---@param eventId integer
---@return table<integer, integer>
function Storage.getLiability(eventId)
    local result = {}
    if not ensureTables() then return result end

    local rows = safeCall('get racing liability', function()
        return db:query_async([[
            select line_id, coalesce(sum(potential_return), 0) as liability
            from rhd_casino_racing_bets
            where event_id = @eventId and status in ('confirmed', 'won')
            group by line_id
        ]], { eventId = eventId })
    end, {}) or {}

    for i = 1, #rows do
        local row = rows[i]
        result[math.floor(tonumber(row.line_id) or 0)] = math.floor(tonumber(row.liability) or 0)
    end

    return result
end

---@param data table
---@param betIdFormat { prefix: string, digits: integer }
---@return string? betId
function Storage.insertBet(data, betIdFormat)
    if not ensureTables() then return nil end

    return safeCall('insert racing bet', function()
        local seq = db:insert_async([[
            insert into rhd_casino_racing_bets (
                event_id, line_id, outcome_id, market, odds, stake, potential_return,
                bettor_identifier, bettor_name, staff_bet_identifier, staff_bet_name
            ) values (
                @event_id, @line_id, @outcome_id, @market, @odds, @stake, @potential_return,
                @bettor_identifier, @bettor_name, @staff_bet_identifier, @staff_bet_name
            )
        ]], data)

        if not seq then return nil end

        local betId = ('%s%0' .. betIdFormat.digits .. 'd'):format(betIdFormat.prefix, seq)

        db:execute_async(
            'update rhd_casino_racing_bets set bet_id = @bet_id where seq = @seq',
            { bet_id = betId, seq = seq }
        )

        return betId
    end, nil)
end

---@param betId string
---@return table?
function Storage.getBet(betId)
    if not ensureTables() then return nil end

    return safeCall('get racing bet', function()
        return db:single_async([[
            select
                b.*,
                e.label, e.status as event_status, e.result_outcome_ids,
                o.name as outcome_name, o.slot as outcome_slot
            from rhd_casino_racing_bets b
            inner join rhd_casino_racing_events e on e.id = b.event_id
            inner join rhd_casino_racing_outcomes o on o.id = b.outcome_id
            where b.bet_id = @betId
        ]], { betId = betId })
    end, nil)
end

---Menandai bet sebagai sudah dibayar. Hanya berhasil kalau status masih bisa diklaim.
---@param betId string
---@param nextStatus 'paid'|'refunded'
---@param fromStatus string
---@param staff { identifier: string?, name: string }
---@param receiptTaken boolean
---@return boolean
function Storage.markBetPaid(betId, nextStatus, fromStatus, staff, receiptTaken)
    if not ensureTables() then return false end

    local affected = safeCall('mark racing bet paid', function()
        return db:update_async([[
            update rhd_casino_racing_bets set
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

    return safeCall('set racing receipt taken', function()
        db:execute_async(
            'update rhd_casino_racing_bets set receipt_taken = 1 where bet_id = @betId',
            { betId = betId }
        )
        return true
    end, false)
end

---@param eventId integer
---@return table[]
function Storage.getBetsByEvent(eventId)
    if not ensureTables() then return {} end

    return safeCall('get racing bets by event', function()
        return db:query_async([[
            select b.*, o.name as outcome_name, o.slot as outcome_slot
            from rhd_casino_racing_bets b
            inner join rhd_casino_racing_outcomes o on o.id = b.outcome_id
            where b.event_id = @eventId
            order by b.seq desc
        ]], { eventId = eventId })
    end, {}) or {}
end

---@param eventId integer
---@return table?
function Storage.getRecapTotals(eventId)
    if not ensureTables() then return nil end

    return safeCall('get racing recap totals', function()
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
            from rhd_casino_racing_bets
            where event_id = @eventId
        ]], { eventId = eventId })
    end, nil)
end

return Storage
