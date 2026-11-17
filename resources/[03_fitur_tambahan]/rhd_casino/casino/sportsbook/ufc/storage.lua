local baseStorage = require 'modules.storage'
local config = require 'casino.sportsbook.ufc.config'

local safeCall = baseStorage.safeCall
local Storage = {}

local tablesReady = false

---@param tableName string
---@param columnName string
---@return boolean? exists nil kalau pengecekan sendiri gagal
local function columnExists(tableName, columnName)
    local ok, result = pcall(function()
        return db:scalar_async([[
            select 1 from information_schema.columns
            where table_schema = database() and table_name = ? and column_name = ?
            limit 1
        ]], { tableName, columnName })
    end)

    if not ok then return nil end
    return result ~= nil
end

---Kolom `archived` ditambahkan belakangan, jadi instalasi lama perlu di-migrasi.
---@return boolean
local function ensureArchivedColumn()
    if columnExists('rhd_casino_ufc_fights', 'archived') == true then return true end

    local altered = pcall(function()
        db:execute_async([[
            alter table rhd_casino_ufc_fights
            add column archived tinyint(1) not null default 0
        ]])
    end)

    if altered then
        lib.print.info('[CasinoUFC] kolom `archived` ditambahkan ke rhd_casino_ufc_fights')
        return true
    end

    -- ALTER bisa gagal justru karena kolomnya sudah ada; pastikan ulang sebelum menyerah.
    if columnExists('rhd_casino_ufc_fights', 'archived') == true then return true end

    lib.print.error('[CasinoUFC] gagal menambahkan kolom `archived`. Hapus fight yang sudah selesai tidak akan berfungsi.')
    return false
end

local function ensureTables()
    if tablesReady then return true end

    local ok = safeCall('ensure ufc tables', function()
        db:execute_async([[
            create table if not exists rhd_casino_ufc_fights (
                id int unsigned not null auto_increment,
                label varchar(64) not null,
                fighter_a varchar(64) not null,
                fighter_b varchar(64) not null,
                prob_a decimal(5,2) not null,
                prob_b decimal(5,2) not null,
                house_edge decimal(5,2) not null default 0,
                odds_a decimal(8,2) not null,
                odds_b decimal(8,2) not null,
                max_liability_a bigint unsigned not null default 0,
                max_liability_b bigint unsigned not null default 0,
                min_stake bigint unsigned not null default 0,
                max_stake bigint unsigned not null default 0,
                status varchar(16) not null default 'draft',
                winner varchar(1) null,
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
            create table if not exists rhd_casino_ufc_bets (
                seq bigint unsigned not null auto_increment,
                bet_id varchar(24) null,
                fight_id int unsigned not null,
                pick varchar(1) not null,
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
                key idx_fight (fight_id),
                key idx_status (status)
            )
        ]])

        return true
    end, false)

    -- Kolom archived wajib ada; tanpa itu arsip fight selesai tidak jalan.
    tablesReady = ok == true and ensureArchivedColumn()
    return tablesReady
end

Citizen.CreateThreadNow(ensureTables)

---@param seq integer
---@return string
local function formatBetId(seq)
    return ('%s%0' .. config.betId.digits .. 'd'):format(config.betId.prefix, seq)
end

---@param data table
---@return integer? fightId
function Storage.createFight(data)
    if not ensureTables() then return nil end

    return safeCall('create ufc fight', function()
        return db:insert_async([[
            insert into rhd_casino_ufc_fights (
                label, fighter_a, fighter_b, prob_a, prob_b, house_edge,
                odds_a, odds_b, max_liability_a, max_liability_b,
                min_stake, max_stake, created_by_name, created_by_identifier
            ) values (
                @label, @fighter_a, @fighter_b, @prob_a, @prob_b, @house_edge,
                @odds_a, @odds_b, @max_liability_a, @max_liability_b,
                @min_stake, @max_stake, @created_by_name, @created_by_identifier
            )
        ]], data)
    end, nil)
end

---@param id integer
---@param data table
---@return boolean
function Storage.updateFight(id, data)
    if not ensureTables() then return false end

    data.id = id

    return safeCall('update ufc fight', function()
        db:execute_async([[
            update rhd_casino_ufc_fights set
                label = @label,
                fighter_a = @fighter_a,
                fighter_b = @fighter_b,
                prob_a = @prob_a,
                prob_b = @prob_b,
                house_edge = @house_edge,
                odds_a = @odds_a,
                odds_b = @odds_b,
                max_liability_a = @max_liability_a,
                max_liability_b = @max_liability_b,
                min_stake = @min_stake,
                max_stake = @max_stake
            where id = @id and status = 'draft'
        ]], data)
        return true
    end, false)
end

---@param id integer
---@return table?
function Storage.getFight(id)
    if not ensureTables() then return nil end

    return safeCall('get ufc fight', function()
        return db:single_async([[
            select
                f.*,
                (select count(*) from rhd_casino_ufc_bets b where b.fight_id = f.id) as bet_count
            from rhd_casino_ufc_fights f
            where f.id = @id
        ]], { id = id })
    end, nil)
end

local FIGHT_SELECT = [[
    select
        f.*,
        coalesce((
            select sum(b.potential_return) from rhd_casino_ufc_bets b
            where b.fight_id = f.id and b.pick = 'a' and b.status in ('confirmed', 'won')
        ), 0) as liability_a,
        coalesce((
            select sum(b.potential_return) from rhd_casino_ufc_bets b
            where b.fight_id = f.id and b.pick = 'b' and b.status in ('confirmed', 'won')
        ), 0) as liability_b,
        (select count(*) from rhd_casino_ufc_bets b where b.fight_id = f.id) as bet_count
    from rhd_casino_ufc_fights f
]]

---@param limit any
---@return integer
local function sanitizeLimit(limit)
    limit = math.floor(tonumber(limit) or 100)
    if limit < 1 then return 100 end
    if limit > 500 then return 500 end
    return limit
end

---Daftar untuk tab Kelola Fight. Fight terarsip disaring langsung di SQL.
---@param limit integer?
---@return table[]
function Storage.getFights(limit)
    if not ensureTables() then return {} end

    return safeCall('get ufc fights', function()
        return db:query_async(FIGHT_SELECT .. [[
            where f.archived = 0
            order by field(f.status, 'open', 'closed', 'draft', 'settled', 'void'), f.id desc
            limit @limit
        ]], { limit = sanitizeLimit(limit) })
    end, {}) or {}
end

---Daftar untuk tab Rekap: hanya fight selesai, terarsip atau tidak.
---@param limit integer?
---@return table[]
function Storage.getRecapFights(limit)
    if not ensureTables() then return {} end

    return safeCall('get ufc recap fights', function()
        return db:query_async(FIGHT_SELECT .. [[
            where f.status in ('settled', 'void')
            order by f.id desc
            limit @limit
        ]], { limit = sanitizeLimit(limit) })
    end, {}) or {}
end

---@param id integer
---@param status string
---@param allowedFrom string[]
---@return boolean
function Storage.setFightStatus(id, status, allowedFrom)
    if not ensureTables() then return false end

    local affected = safeCall('set ufc fight status', function()
        return db:update_async([[
            update rhd_casino_ufc_fights
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

---@param id integer
---@param winner 'a'|'b'
---@return boolean
function Storage.settleFight(id, winner)
    if not ensureTables() then return false end

    local loser = winner == 'a' and 'b' or 'a'

    return safeCall('settle ufc fight', function()
        db:execute_async([[
            update rhd_casino_ufc_fights
            set status = 'settled', winner = @winner
            where id = @id and status in ('open', 'closed')
        ]], { id = id, winner = winner })

        db:execute_async([[
            update rhd_casino_ufc_bets
            set status = 'won'
            where fight_id = @id and status = 'confirmed' and pick = @winner
        ]], { id = id, winner = winner })

        db:execute_async([[
            update rhd_casino_ufc_bets
            set status = 'lost'
            where fight_id = @id and status = 'confirmed' and pick = @loser
        ]], { id = id, loser = loser })

        return true
    end, false)
end

---@param id integer
---@return boolean
function Storage.voidFight(id)
    if not ensureTables() then return false end

    return safeCall('void ufc fight', function()
        db:execute_async([[
            update rhd_casino_ufc_fights
            set status = 'void', winner = null
            where id = @id and status in ('draft', 'open', 'closed')
        ]], { id = id })

        db:execute_async([[
            update rhd_casino_ufc_bets
            set status = 'void'
            where fight_id = @id and status = 'confirmed'
        ]], { id = id })

        return true
    end, false)
end

---Menyembunyikan fight dari daftar kelola tanpa menghapus datanya, supaya rekapnya tetap utuh.
---@param id integer
---@return boolean
function Storage.archiveFight(id)
    if not ensureTables() then return false end

    local affected = safeCall('archive ufc fight', function()
        return db:update_async([[
            update rhd_casino_ufc_fights
            set archived = 1
            where id = @id and status in ('settled', 'void')
        ]], { id = id })
    end, 0)

    if (tonumber(affected) or 0) > 0 then return true end

    lib.print.warn(('[CasinoUFC] archiveFight(%s) tidak mengubah baris apa pun.'):format(id))

    return false
end

---Menghapus fight beserta seluruh taruhannya, tanpa memandang status.
---@param id integer
---@return boolean ok, integer deletedBets
function Storage.deleteFight(id)
    if not ensureTables() then return false, 0 end

    local betCount = 0

    local ok = safeCall('delete ufc fight', function()
        betCount = math.floor(tonumber(db:scalar_async([[
            select count(*) from rhd_casino_ufc_bets where fight_id = @id
        ]], { id = id })) or 0)

        db:execute_async([[
            delete from rhd_casino_ufc_bets where fight_id = @id
        ]], { id = id })

        local affected = db:update_async([[
            delete from rhd_casino_ufc_fights where id = @id
        ]], { id = id })

        return (tonumber(affected) or 0) > 0
    end, false)

    return ok == true, betCount
end

---Total potential payout yang masih ditanggung casino per fighter.
---@param fightId integer
---@return { a: integer, b: integer }
function Storage.getLiability(fightId)
    local result = { a = 0, b = 0 }
    if not ensureTables() then return result end

    local rows = safeCall('get ufc liability', function()
        return db:query_async([[
            select pick, coalesce(sum(potential_return), 0) as liability
            from rhd_casino_ufc_bets
            where fight_id = @fightId and status in ('confirmed', 'won')
            group by pick
        ]], { fightId = fightId })
    end, {}) or {}

    for i = 1, #rows do
        local row = rows[i]
        if row.pick == 'a' or row.pick == 'b' then
            result[row.pick] = math.floor(tonumber(row.liability) or 0)
        end
    end

    return result
end

---@param data table
---@return string? betId
function Storage.insertBet(data)
    if not ensureTables() then return nil end

    return safeCall('insert ufc bet', function()
        local seq = db:insert_async([[
            insert into rhd_casino_ufc_bets (
                fight_id, pick, odds, stake, potential_return,
                bettor_identifier, bettor_name, staff_bet_identifier, staff_bet_name
            ) values (
                @fight_id, @pick, @odds, @stake, @potential_return,
                @bettor_identifier, @bettor_name, @staff_bet_identifier, @staff_bet_name
            )
        ]], data)

        if not seq then return nil end

        local betId = formatBetId(seq)

        db:execute_async([[
            update rhd_casino_ufc_bets set bet_id = @bet_id where seq = @seq
        ]], { bet_id = betId, seq = seq })

        return betId
    end, nil)
end

---@param betId string
---@return table?
function Storage.getBet(betId)
    if not ensureTables() then return nil end

    return safeCall('get ufc bet', function()
        return db:single_async([[
            select b.*, f.label, f.fighter_a, f.fighter_b, f.status as fight_status, f.winner
            from rhd_casino_ufc_bets b
            inner join rhd_casino_ufc_fights f on f.id = b.fight_id
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

    local affected = safeCall('mark ufc bet paid', function()
        return db:update_async([[
            update rhd_casino_ufc_bets set
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

    return safeCall('set ufc receipt taken', function()
        db:execute_async([[
            update rhd_casino_ufc_bets set receipt_taken = 1 where bet_id = @betId
        ]], { betId = betId })
        return true
    end, false)
end

---@param fightId integer
---@return table[]
function Storage.getBetsByFight(fightId)
    if not ensureTables() then return {} end

    return safeCall('get ufc bets by fight', function()
        return db:query_async([[
            select * from rhd_casino_ufc_bets
            where fight_id = @fightId
            order by seq desc
        ]], { fightId = fightId })
    end, {}) or {}
end

---@param fightId integer
---@return table?
function Storage.getRecapTotals(fightId)
    if not ensureTables() then return nil end

    return safeCall('get ufc recap totals', function()
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
            from rhd_casino_ufc_bets
            where fight_id = @fightId
        ]], { fightId = fightId })
    end, nil)
end

return Storage
