local sportsbook = require 'casino.sportsbook.config'
local config = require 'casino.sportsbook.ufc.config'
local odds = require 'casino.sportsbook.modules.odds'
local locks = require 'casino.sportsbook.modules.locks'
local storage = require 'casino.sportsbook.ufc.storage'
local parlay = require 'casino.sportsbook.parlay.server'

---@alias UfcRole 'admin'|'staff'
---@alias UfcPick 'a'|'b'

---@param source number
---@return UfcRole?
local function getRole(source)
    local job = sm_core:GetPlayerData(source, 'job')
    if not job or job.name ~= shared.casinoJobName then return nil end

    local level = tonumber(job.grade?.level) or 0
    if level >= sportsbook.access.admin then return 'admin' end
    if level >= sportsbook.access.staff then return 'staff' end

    return nil
end

---@param source number
---@param required UfcRole
---@return boolean
local function hasRole(source, required)
    local role = getRole(source)
    if not role then return false end
    if required == 'staff' then return true end
    return role == 'admin'
end

---@param source number
---@return { identifier: string?, name: string }
local function staffInfo(source)
    return {
        identifier = shared.getIdentifier(source),
        name = shared.getPlayerName(source),
    }
end

---@param value any
---@param maxLength integer
---@return string?
local function cleanString(value, maxLength)
    if type(value) ~= 'string' then return nil end
    local trimmed = value:gsub('^%s+', ''):gsub('%s+$', '')
    if trimmed == '' then return nil end
    return trimmed:sub(1, maxLength)
end

---@param value any
---@param min number
---@param max number
---@return integer?
local function cleanInt(value, min, max)
    local number = math.floor(tonumber(value) or -1)
    if number < min or number > max then return nil end
    return number
end

---@param staffSource number
---@param targetSource number
---@return boolean
local function isNearStaff(staffSource, targetSource)
    if staffSource == targetSource then return true end
    if not shared.playerExist(targetSource) then return false end

    local staffPed = GetPlayerPed(staffSource)
    local targetPed = GetPlayerPed(targetSource)
    if staffPed == 0 or targetPed == 0 then return false end

    return #(GetEntityCoords(staffPed) - GetEntityCoords(targetPed)) <= sportsbook.maxBettorDistance
end

---Membentuk payload fight yang sudah divalidasi, sekaligus menghitung odds dari probabilitas.
---@param data any
---@return table? payload, string? err
local function buildFightPayload(data)
    if type(data) ~= 'table' then return nil, 'Data fight tidak valid.' end

    local label = cleanString(data.label, 64)
    local fighterA = cleanString(data.fighterA, 64)
    local fighterB = cleanString(data.fighterB, 64)

    if not label then return nil, 'Nama fight wajib diisi.' end
    if not (fighterA and fighterB) then return nil, 'Nama kedua fighter wajib diisi.' end
    if fighterA:lower() == fighterB:lower() then return nil, 'Nama fighter tidak boleh sama.' end

    local probA = tonumber(data.probA)
    local probB = tonumber(data.probB)
    if not (probA and probB) then return nil, 'Probabilitas tidak valid.' end
    if probA <= 0 or probB <= 0 then return nil, 'Probabilitas tiap fighter harus lebih dari 0%.' end
    if math.abs((probA + probB) - 100) > 0.01 then return nil, 'Total probabilitas harus 100%.' end

    local houseEdge = tonumber(data.houseEdge)
    if not houseEdge or houseEdge < config.houseEdge.min or houseEdge > config.houseEdge.max then
        return nil, ('House edge harus antara %s%% dan %s%%.'):format(config.houseEdge.min, config.houseEdge.max)
    end

    local liabilityA = cleanInt(data.maxLiabilityA, config.liabilityBounds.min, config.liabilityBounds.max)
    local liabilityB = cleanInt(data.maxLiabilityB, config.liabilityBounds.min, config.liabilityBounds.max)
    if not (liabilityA and liabilityB) then return nil, 'Maximum liability di luar batas yang diizinkan.' end

    local minStake = cleanInt(data.minStake, config.stakeBounds.min, config.stakeBounds.max)
    local maxStake = cleanInt(data.maxStake, config.stakeBounds.min, config.stakeBounds.max)
    if not (minStake and maxStake) then return nil, 'Batas stake di luar rentang yang diizinkan.' end
    if minStake > maxStake then return nil, 'Minimum stake tidak boleh melebihi maximum stake.' end

    return {
        label = label,
        fighter_a = fighterA,
        fighter_b = fighterB,
        prob_a = odds.round2(probA),
        prob_b = odds.round2(probB),
        house_edge = odds.round2(houseEdge),
        odds_a = odds.fixed(probA, houseEdge),
        odds_b = odds.fixed(probB, houseEdge),
        max_liability_a = liabilityA,
        max_liability_b = liabilityB,
        min_stake = minStake,
        max_stake = maxStake,
    }
end

---@param fightId integer
---@return { a: integer, b: integer }
local function totalLiability(fightId)
    local liability = storage.getLiability(fightId)
    local extra = parlay.ufcLiability(fightId)[fightId]

    if extra then
        liability.a += extra.a
        liability.b += extra.b
    end

    return liability
end

---@param row table
---@param liability { a: integer, b: integer }? dipakai kalau pemanggil sudah menghitungnya lebih murah
---@return table
local function mapFight(row, liability)
    liability = liability or totalLiability(row.id)
    local maxLiabilityA = math.floor(tonumber(row.max_liability_a) or 0)
    local maxLiabilityB = math.floor(tonumber(row.max_liability_b) or 0)

    return {
        id = row.id,
        label = row.label,
        status = row.status,
        winner = row.winner,
        houseEdge = tonumber(row.house_edge) or 0,
        minStake = math.floor(tonumber(row.min_stake) or 0),
        maxStake = math.floor(tonumber(row.max_stake) or 0),
        betCount = math.floor(tonumber(row.bet_count) or 0),
        createdBy = row.created_by_name,
        createdAt = row.created_at,
        fighters = {
            a = {
                name = row.fighter_a,
                probability = tonumber(row.prob_a) or 0,
                fairOdds = odds.fair(row.prob_a),
                odds = tonumber(row.odds_a) or 0,
                maxLiability = maxLiabilityA,
                liability = liability.a,
                remaining = math.max(maxLiabilityA - liability.a, 0),
            },
            b = {
                name = row.fighter_b,
                probability = tonumber(row.prob_b) or 0,
                fairOdds = odds.fair(row.prob_b),
                odds = tonumber(row.odds_b) or 0,
                maxLiability = maxLiabilityB,
                liability = liability.b,
                remaining = math.max(maxLiabilityB - liability.b, 0),
            },
        },
    }
end

---@param row table
---@return table
local function mapBet(row)
    return {
        betId = row.bet_id,
        fightId = row.fight_id,
        fightLabel = row.label,
        pick = row.pick,
        pickName = row.pick == 'a' and row.fighter_a or row.fighter_b,
        fighterA = row.fighter_a,
        fighterB = row.fighter_b,
        odds = tonumber(row.odds) or 0,
        stake = math.floor(tonumber(row.stake) or 0),
        potentialReturn = math.floor(tonumber(row.potential_return) or 0),
        status = row.status,
        bettorName = row.bettor_name,
        staffBetName = row.staff_bet_name,
        staffPaidName = row.staff_paid_name,
        receiptTaken = (tonumber(row.receipt_taken) or 0) == 1,
        createdAt = row.created_at,
        paidAt = row.paid_at,
    }
end

lib.callback.register('rhd_casino_ufc:getState', function(source)
    local role = getRole(source)
    if not role then return false, 'Akses ditolak.' end

    local parlayLiability = parlay.ufcLiability()

    ---@param rows table[]
    ---@return table[]
    local function mapRows(rows)
        local mapped = {}
        for i = 1, #rows do
            local row = rows[i]
            local extra = parlayLiability[math.floor(tonumber(row.id) or 0)]
            mapped[i] = mapFight(row, {
                a = math.floor(tonumber(row.liability_a) or 0) + (extra and extra.a or 0),
                b = math.floor(tonumber(row.liability_b) or 0) + (extra and extra.b or 0),
            })
        end
        return mapped
    end

    return true, {
        role = role,
        fights = mapRows(storage.getFights()),
        recapFights = mapRows(storage.getRecapFights()),
        receiptItem = config.receiptItem,
        stakeBounds = config.stakeBounds,
        liabilityBounds = config.liabilityBounds,
        houseEdge = config.houseEdge,
        parlay = parlay.publicConfig,
    }
end)

lib.callback.register('rhd_casino_ufc:createFight', function(source, data)
    if not hasRole(source, 'admin') then return false, 'Akses ditolak.' end

    local payload, err = buildFightPayload(data)
    if not payload then return false, err end

    local staff = staffInfo(source)
    payload.created_by_name = staff.name
    payload.created_by_identifier = staff.identifier

    local fightId = storage.createFight(payload)
    if not fightId then return false, 'Gagal menyimpan fight.' end

    shared.log({
        title = 'UFC — Fight Created',
        type = 'info',
        fields = {
            { name = 'Admin', value = ('%s (%s)'):format(staff.name, source) },
            { name = 'Fight', value = ('#%s %s'):format(fightId, payload.label) },
            { name = payload.fighter_a, value = ('%s%% @ %s'):format(payload.prob_a, payload.odds_a), inline = true },
            { name = payload.fighter_b, value = ('%s%% @ %s'):format(payload.prob_b, payload.odds_b), inline = true },
            { name = 'House Edge', value = ('%s%%'):format(payload.house_edge), inline = true },
        },
    })

    return true
end)

lib.callback.register('rhd_casino_ufc:updateFight', function(source, fightId, data)
    if not hasRole(source, 'admin') then return false, 'Akses ditolak.' end

    local id = cleanInt(fightId, 1, math.maxinteger)
    if not id then return false, 'Fight tidak ditemukan.' end

    local fight = storage.getFight(id)
    if not fight then return false, 'Fight tidak ditemukan.' end
    if fight.status ~= 'draft' then return false, 'Fight hanya bisa diubah saat masih draft.' end

    local payload, err = buildFightPayload(data)
    if not payload then return false, err end

    if not storage.updateFight(id, payload) then return false, 'Gagal menyimpan perubahan.' end

    return true
end)

lib.callback.register('rhd_casino_ufc:setFightStatus', function(source, fightId, status)
    if not hasRole(source, 'admin') then return false, 'Akses ditolak.' end

    local id = cleanInt(fightId, 1, math.maxinteger)
    if not id then return false, 'Fight tidak ditemukan.' end

    local allowedFrom = status == 'open' and { 'draft', 'closed' }
        or status == 'closed' and { 'open' }
        or nil

    if not allowedFrom then return false, 'Status tidak valid.' end
    if not storage.setFightStatus(id, status, allowedFrom) then
        return false, 'Status fight tidak bisa diubah dari kondisi saat ini.'
    end

    local staff = staffInfo(source)
    shared.log({
        title = status == 'open' and 'UFC — Betting Opened' or 'UFC — Betting Closed',
        type = status == 'open' and 'success' or 'warning',
        fields = {
            { name = 'Admin', value = ('%s (%s)'):format(staff.name, source) },
            { name = 'Fight', value = ('#%s'):format(id), inline = true },
        },
    })

    return true
end)

lib.callback.register('rhd_casino_ufc:settleFight', function(source, fightId, result)
    if not hasRole(source, 'admin') then return false, 'Akses ditolak.' end

    local id = cleanInt(fightId, 1, math.maxinteger)
    if not id then return false, 'Fight tidak ditemukan.' end

    local fight = storage.getFight(id)
    if not fight then return false, 'Fight tidak ditemukan.' end

    local staff = staffInfo(source)

    if result == 'void' then
        if fight.status == 'settled' or fight.status == 'void' then
            return false, 'Fight ini sudah diselesaikan.'
        end
        if not storage.voidFight(id) then return false, 'Gagal membatalkan fight.' end

        parlay.voidUfc(id)

        shared.log({
            title = 'UFC — Fight Cancelled (VOID)',
            type = 'warning',
            fields = {
                { name = 'Admin', value = ('%s (%s)'):format(staff.name, source) },
                { name = 'Fight', value = ('#%s %s'):format(id, fight.label), inline = true },
            },
        })

        return true
    end

    if result ~= 'a' and result ~= 'b' then return false, 'Pemenang tidak valid.' end
    if fight.status ~= 'open' and fight.status ~= 'closed' then
        return false, 'Hasil hanya bisa diinput untuk fight yang sudah berjalan.'
    end

    if not storage.settleFight(id, result) then return false, 'Gagal menyimpan hasil fight.' end

    parlay.settleUfc(id, result)

    shared.log({
        title = 'UFC — Fight Result',
        type = 'success',
        fields = {
            { name = 'Admin', value = ('%s (%s)'):format(staff.name, source) },
            { name = 'Fight', value = ('#%s %s'):format(id, fight.label), inline = true },
            { name = 'Winner', value = result == 'a' and fight.fighter_a or fight.fighter_b, inline = true },
        },
    })

    return true
end)

---@param source number
---@param fight table
---@param staff { identifier: string?, name: string }
---@param deletedBets integer
local function logFightRemoval(source, fight, staff, deletedBets)
    shared.log({
        title = 'UFC — Summary Deleted',
        type = 'error',
        fields = {
            { name = 'Admin', value = ('%s (%s)'):format(staff.name, source) },
            { name = 'Fight', value = ('#%s %s'):format(fight.id, fight.label) },
            { name = 'Status When Deleted', value = tostring(fight.status):upper(), inline = true },
            { name = 'Bets Deleted', value = tostring(deletedBets), inline = true },
        },
    })
end

lib.callback.register('rhd_casino_ufc:deleteFight', function(source, fightId)
    if not hasRole(source, 'admin') then return false, 'Akses ditolak.' end

    local id = cleanInt(fightId, 1, math.maxinteger)
    if not id then return false, 'Fight tidak ditemukan.' end

    local fight = storage.getFight(id)
    if not fight then return false, 'Fight tidak ditemukan.' end

    local staff = staffInfo(source)
    local isFinished = fight.status == 'settled' or fight.status == 'void'

    if isFinished then
        if not storage.archiveFight(id) then
            return false, 'Gagal mengarsipkan fight. Cek konsol server — kolom `archived` kemungkinan belum ada di database.'
        end

        shared.log({
            title = 'UFC — Fight Removed from List',
            type = 'warning',
            fields = {
                { name = 'Admin', value = ('%s (%s)'):format(staff.name, source) },
                { name = 'Fight', value = ('#%s %s'):format(id, fight.label) },
                { name = 'Status', value = tostring(fight.status):upper(), inline = true },
                { name = 'Summary', value = 'Kept', inline = true },
            },
        })

        return true
    end

    local ok, deletedBets = storage.deleteFight(id)
    if not ok then return false, 'Gagal menghapus fight.' end

    parlay.voidUfc(id)

    shared.log({
        title = 'UFC — Fight Permanently Deleted',
        type = 'error',
        fields = {
            { name = 'Admin', value = ('%s (%s)'):format(staff.name, source) },
            { name = 'Fight', value = ('#%s %s'):format(id, fight.label) },
            { name = 'Status When Deleted', value = tostring(fight.status):upper(), inline = true },
            { name = 'Bets Deleted', value = tostring(deletedBets), inline = true },
        },
    })

    return true
end)

lib.callback.register('rhd_casino_ufc:deleteRecap', function(source, fightId)
    if not hasRole(source, 'admin') then return false, 'Akses ditolak.' end

    local id = cleanInt(fightId, 1, math.maxinteger)
    if not id then return false, 'Fight tidak ditemukan.' end

    local fight = storage.getFight(id)
    if not fight then return false, 'Fight tidak ditemukan.' end
    if fight.status ~= 'settled' and fight.status ~= 'void' then
        return false, 'Rekap hanya bisa dihapus untuk fight yang sudah selesai.'
    end

    local ok, deletedBets = storage.deleteFight(id)
    if not ok then return false, 'Gagal menghapus rekap.' end

    logFightRemoval(source, fight, staffInfo(source), deletedBets)

    return true
end)

lib.callback.register('rhd_casino_ufc:placeBet', function(source, data)
    if not hasRole(source, 'staff') then return false, 'Akses ditolak.' end
    if type(data) ~= 'table' then return false, 'Data taruhan tidak valid.' end

    local fightId = cleanInt(data.fightId, 1, math.maxinteger)
    if not fightId then return false, 'Fight tidak ditemukan.' end

    local pick = data.pick
    if pick ~= 'a' and pick ~= 'b' then return false, 'Pilihan fighter tidak valid.' end

    local fight = storage.getFight(fightId)
    if not fight then return false, 'Fight tidak ditemukan.' end
    if fight.status ~= 'open' then return false, 'Betting untuk fight ini sedang tidak dibuka.' end

    local bettorSource = cleanInt(data.bettorSource, 1, math.maxinteger)
    if not bettorSource or not shared.playerExist(bettorSource) then
        return false, 'Bettor tidak ditemukan.'
    end
    if not isNearStaff(source, bettorSource) then
        return false, 'Bettor harus berada di dekat kamu.'
    end

    local minStake = math.floor(tonumber(fight.min_stake) or 0)
    local maxStake = math.floor(tonumber(fight.max_stake) or 0)
    local stake = cleanInt(data.stake, minStake, maxStake)
    if not stake then
        return false, ('Stake harus antara %s dan %s chip.'):format(minStake, maxStake)
    end

    local fightOdds = tonumber(pick == 'a' and fight.odds_a or fight.odds_b) or 0
    if fightOdds <= 0 then return false, 'Odds fight tidak valid.' end

    local potentialReturn = odds.potentialReturn(stake, fightOdds)
    if potentialReturn <= 0 then return false, 'Potential return tidak valid.' end

    local maxLiability = math.floor(tonumber(pick == 'a' and fight.max_liability_a or fight.max_liability_b) or 0)

    local lockKeys = { ('ufc:%d'):format(fightId) }
    locks.acquire(lockKeys)

    local liability = totalLiability(fightId)
    local remaining = math.max(maxLiability - liability[pick], 0)

    if potentialReturn > remaining then
        locks.release(lockKeys)
        return false, ('BET REJECTED — sisa liability %s chip, potential return %s chip.'):format(remaining, potentialReturn)
    end

    local staff = staffInfo(source)
    local bettorName = shared.getPlayerName(bettorSource)

    local betId = storage.insertBet({
        fight_id = fightId,
        pick = pick,
        odds = fightOdds,
        stake = stake,
        potential_return = potentialReturn,
        bettor_identifier = shared.getIdentifier(bettorSource),
        bettor_name = bettorName,
        staff_bet_identifier = staff.identifier,
        staff_bet_name = staff.name,
    })

    locks.release(lockKeys)

    if not betId then return false, 'Gagal menyimpan taruhan.' end

    local pickName = pick == 'a' and fight.fighter_a or fight.fighter_b
    local receiptGiven = ox_inventory:AddItem(bettorSource, config.receiptItem, 1, {
        betId = betId,
        fight = fight.label,
        pick = pickName,
        odds = fightOdds,
        stake = stake,
        potentialReturn = potentialReturn,
        description = ('%s\n%s @ %s\nStake %s → %s'):format(betId, pickName, fightOdds, stake, potentialReturn),
    })

    shared.log({
        title = 'UFC — Bet Confirmed',
        type = 'money',
        fields = {
            { name = 'Bet ID', value = betId },
            { name = 'Fight', value = ('#%s %s'):format(fightId, fight.label), inline = true },
            { name = 'Bettor', value = ('%s (%s)'):format(bettorName, bettorSource), inline = true },
            { name = 'Pick', value = ('%s @ %s'):format(pickName, fightOdds), inline = true },
            { name = 'Stake', value = ('%s chips'):format(stake), inline = true },
            { name = 'Potential Return', value = ('%s chips'):format(potentialReturn), inline = true },
            { name = 'Staff', value = ('%s (%s)'):format(staff.name, source), inline = true },
            { name = 'Receipt', value = receiptGiven and 'Given' or 'FAILED (inventory full)', inline = true },
        },
    })

    return true, {
        betId = betId,
        fightLabel = fight.label,
        fighterA = fight.fighter_a,
        fighterB = fight.fighter_b,
        pickName = pickName,
        odds = fightOdds,
        stake = stake,
        potentialReturn = potentialReturn,
        bettorName = bettorName,
        staffName = staff.name,
        receiptGiven = receiptGiven == true,
    }
end)

lib.callback.register('rhd_casino_ufc:lookupBet', function(source, betId)
    if not hasRole(source, 'staff') then return false, 'Akses ditolak.' end

    local id = cleanString(betId, 24)
    if not id then return false, 'Bet ID tidak valid.' end

    local row = storage.getBet(id:upper())
    if not row then return false, 'Bet ID tidak ditemukan.' end

    return true, mapBet(row)
end)

lib.callback.register('rhd_casino_ufc:markPaid', function(source, betId, claimantSource)
    if not hasRole(source, 'staff') then return false, 'Akses ditolak.' end

    local id = cleanString(betId, 24)
    if not id then return false, 'Bet ID tidak valid.' end

    local row = storage.getBet(id:upper())
    if not row then return false, 'Bet ID tidak ditemukan.' end

    if row.status == 'paid' or row.status == 'refunded' then
        return false, 'BET ALREADY PAID'
    end

    local nextStatus = row.status == 'won' and 'paid'
        or row.status == 'void' and 'refunded'
        or nil

    if not nextStatus then
        return false, ('Taruhan berstatus %s tidak bisa diklaim.'):format(row.status:upper())
    end

    local claimant = cleanInt(claimantSource, 1, math.maxinteger)
    if not claimant or not shared.playerExist(claimant) then
        return false, 'Penerima pembayaran tidak ditemukan.'
    end
    if not isNearStaff(source, claimant) then
        return false, 'Penerima harus berada di dekat kamu.'
    end

    local staff = staffInfo(source)

    if not storage.markBetPaid(row.bet_id, nextStatus, row.status, staff, false) then
        return false, 'Status taruhan berubah, coba cari ulang Bet ID.'
    end

    local receiptTaken = false
    local slots = ox_inventory:Search(claimant, 'slots', config.receiptItem, { betId = row.bet_id })

    if type(slots) == 'table' and slots[1] then
        receiptTaken = ox_inventory:RemoveItem(claimant, config.receiptItem, 1, nil, slots[1].slot) == true
        if receiptTaken then
            storage.setReceiptTaken(row.bet_id)
        end
    end

    local amount = nextStatus == 'paid'
        and math.floor(tonumber(row.potential_return) or 0)
        or math.floor(tonumber(row.stake) or 0)

    shared.log({
        title = nextStatus == 'paid' and 'UFC — Payout Paid' or 'UFC — Stake Refunded',
        type = 'money',
        fields = {
            { name = 'Bet ID', value = row.bet_id },
            { name = 'Bettor', value = row.bettor_name, inline = true },
            { name = 'Receiver', value = ('%s (%s)'):format(shared.getPlayerName(claimant), claimant), inline = true },
            { name = 'Amount', value = ('%s chips'):format(amount), inline = true },
            { name = 'Staff', value = ('%s (%s)'):format(staff.name, source), inline = true },
            { name = 'Receipt', value = receiptTaken and 'Collected' or 'NOT in receiver inventory', inline = true },
        },
    })

    return true, {
        betId = row.bet_id,
        status = nextStatus,
        amount = amount,
        receiptTaken = receiptTaken,
    }
end)

lib.callback.register('rhd_casino_ufc:getRecap', function(source, fightId)
    if not hasRole(source, 'admin') then return false, 'Akses ditolak.' end

    local id = cleanInt(fightId, 1, math.maxinteger)
    if not id then return false, 'Fight tidak ditemukan.' end

    local fight = storage.getFight(id)
    if not fight then return false, 'Fight tidak ditemukan.' end

    local totals = storage.getRecapTotals(id) or {}
    local rows = storage.getBetsByFight(id)
    local bets = {}

    for i = 1, #rows do
        local row = rows[i]
        row.label = fight.label
        row.fighter_a = fight.fighter_a
        row.fighter_b = fight.fighter_b
        bets[i] = mapBet(row)
    end

    local totalStake = math.floor(tonumber(totals.total_stake) or 0)
    local paidOut = math.floor(tonumber(totals.paid_out) or 0)
    local refundedOut = math.floor(tonumber(totals.refunded_out) or 0)

    return true, {
        fight = mapFight(fight),
        totals = {
            betCount = math.floor(tonumber(totals.bet_count) or 0),
            totalStake = totalStake,
            totalPotential = math.floor(tonumber(totals.total_potential) or 0),
            actualPayout = paidOut + refundedOut,
            profit = totalStake - paidOut - refundedOut,
            confirmed = math.floor(tonumber(totals.count_confirmed) or 0),
            won = math.floor(tonumber(totals.count_won) or 0),
            lost = math.floor(tonumber(totals.count_lost) or 0),
            void = math.floor(tonumber(totals.count_void) or 0),
            paid = math.floor(tonumber(totals.count_paid) or 0),
            refunded = math.floor(tonumber(totals.count_refunded) or 0),
        },
        bets = bets,
    }
end)
