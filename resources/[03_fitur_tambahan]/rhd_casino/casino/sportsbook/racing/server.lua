local sportsbook = require 'casino.sportsbook.config'
local config = require 'casino.sportsbook.racing.config'
local odds = require 'casino.sportsbook.modules.odds'
local locks = require 'casino.sportsbook.modules.locks'
local storage = require 'casino.sportsbook.racing.storage'
local parlay = require 'casino.sportsbook.parlay.server'

---@class RacingConfig
---@field receiptItem string
---@field betId { prefix: string, digits: integer }
---@field houseEdge { default: number, min: number, max: number }
---@field stakeBounds { min: integer, max: integer }
---@field liabilityBounds { min: integer, max: integer }
---@field labelLength integer
---@field outcomeNameLength integer
---@field outcomeBounds { min: integer, max: integer }
---@field markets RacingMarketDef[] urut tampil di tablet

---@class RacingMarketDef
---@field id string
---@field places integer jumlah posisi finish teratas yang dibayar

---@alias RacingRole 'admin'|'staff'

---@param source number
---@return RacingRole?
local function getRole(source)
    local job = sm_core:GetPlayerData(source, 'job')
    if not job or job.name ~= shared.casinoJobName then return nil end

    local level = tonumber(job.grade?.level) or 0
    if level >= sportsbook.access.admin then return 'admin' end
    if level >= sportsbook.access.staff then return 'staff' end

    return nil
end

---@param source number
---@param required RacingRole
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

---Market baru aktif kalau jumlah outcome melebihi jumlah posisi yang dibayar.
---@param outcomeCount integer
---@return string[]
local function activeMarkets(outcomeCount)
    local list = {}

    for i = 1, #config.markets do
        local market = config.markets[i]
        if outcomeCount > market.places then
            list[#list + 1] = market.id
        end
    end

    return list
end

---@param marketId string
---@return integer
local function placesOf(marketId)
    for i = 1, #config.markets do
        if config.markets[i].id == marketId then return config.markets[i].places end
    end
    return 0
end

---@param markets string[]
---@return integer
local function maxPlaces(markets)
    local places = 0
    for i = 1, #markets do
        local marketPlaces = placesOf(markets[i])
        if marketPlaces > places then places = marketPlaces end
    end
    return places
end

---Membentuk payload event yang sudah divalidasi, sekaligus menghitung odds dari probabilitas.
---@param data any
---@return table? event, table[]? outcomes, string? err
local function buildEventPayload(data)
    if type(data) ~= 'table' then return nil, nil, 'Data event tidak valid.' end

    local label = cleanString(data.label, config.labelLength)
    if not label then return nil, nil, 'Nama event wajib diisi.' end

    local houseEdge = tonumber(data.houseEdge)
    if not houseEdge or houseEdge < config.houseEdge.min or houseEdge > config.houseEdge.max then
        return nil, nil, ('House edge harus antara %s%% dan %s%%.'):format(config.houseEdge.min, config.houseEdge.max)
    end

    local minStake = cleanInt(data.minStake, config.stakeBounds.min, config.stakeBounds.max)
    local maxStake = cleanInt(data.maxStake, config.stakeBounds.min, config.stakeBounds.max)
    if not (minStake and maxStake) then return nil, nil, 'Batas stake di luar rentang yang diizinkan.' end
    if minStake > maxStake then return nil, nil, 'Minimum stake tidak boleh melebihi maximum stake.' end

    local input = data.outcomes
    if type(input) ~= 'table' then return nil, nil, 'Daftar peserta tidak valid.' end

    local count = #input
    if count < config.outcomeBounds.min or count > config.outcomeBounds.max then
        return nil, nil, ('Jumlah peserta harus antara %d dan %d.'):format(config.outcomeBounds.min, config.outcomeBounds.max)
    end

    local markets = activeMarkets(count)
    if #markets == 0 then return nil, nil, 'Jumlah peserta belum cukup untuk membuka market apa pun.' end

    local outcomes = {}
    local seenNames = {}
    local probTotals = {}

    for i = 1, count do
        local entry = input[i]
        if type(entry) ~= 'table' then return nil, nil, ('Data peserta #%d tidak valid.'):format(i) end

        local name = cleanString(entry.name, config.outcomeNameLength)
        if not name then return nil, nil, ('Nama peserta #%d wajib diisi.'):format(i) end

        local lowered = name:lower()
        if seenNames[lowered] then return nil, nil, ('Nama peserta "%s" dipakai lebih dari sekali.'):format(name) end
        seenNames[lowered] = true

        local entryMarkets = type(entry.markets) == 'table' and entry.markets or {}
        local lines = {}
        local probByMarket = {}

        for m = 1, #markets do
            local market = markets[m]
            local line = entryMarkets[market]
            if type(line) ~= 'table' then
                return nil, nil, ('Data market %s untuk "%s" belum diisi.'):format(market, name)
            end

            local probability = tonumber(line.probability)
            if not probability or probability <= 0 or probability > 100 then
                return nil, nil, ('Probabilitas %s untuk "%s" harus di antara 0%% dan 100%%.'):format(market, name)
            end

            local maxLiability = cleanInt(line.maxLiability, config.liabilityBounds.min, config.liabilityBounds.max)
            if not maxLiability then
                return nil, nil, ('Maximum liability %s untuk "%s" di luar batas yang diizinkan.'):format(market, name)
            end

            probByMarket[market] = probability
            probTotals[market] = (probTotals[market] or 0) + probability

            lines[#lines + 1] = {
                market = market,
                probability = odds.round2(probability),
                odds = odds.fixed(probability, houseEdge),
                maxLiability = maxLiability,
            }
        end

        if probByMarket.podium and probByMarket.winner and probByMarket.podium < probByMarket.winner then
            return nil, nil, ('Probabilitas podium "%s" tidak boleh lebih kecil daripada probabilitas winner.'):format(name)
        end

        outcomes[i] = { name = name, lines = lines }
    end

    for m = 1, #markets do
        local market = markets[m]
        local expected = placesOf(market) * 100
        if math.abs((probTotals[market] or 0) - expected) > 0.01 then
            return nil, nil, ('Total probabilitas market %s harus %s%%, sekarang %s%%.')
                :format(market, expected, odds.round2(probTotals[market] or 0))
        end
    end

    return {
        label = label,
        house_edge = odds.round2(houseEdge),
        min_stake = minStake,
        max_stake = maxStake,
    }, outcomes
end

---@param value string?
---@return integer[]
local function parseIdList(value)
    local ids = {}
    if type(value) ~= 'string' then return ids end

    for chunk in value:gmatch('[^,]+') do
        local id = math.floor(tonumber(chunk) or 0)
        if id > 0 then ids[#ids + 1] = id end
    end

    return ids
end

---@param lineRow table
---@param minStake integer
---@param eventStatus string
---@return table
local function mapLine(lineRow, minStake, eventStatus)
    local maxLiability = math.floor(tonumber(lineRow.max_liability) or 0)
    local liability = math.floor(tonumber(lineRow.liability) or 0)
    local remaining = math.max(maxLiability - liability, 0)
    local lineOdds = tonumber(lineRow.odds) or 0
    local manualClosed = (tonumber(lineRow.manual_closed) or 0) == 1

    local minReturn = odds.potentialReturn(minStake, lineOdds)
    local autoClosed = minReturn <= 0 or remaining < minReturn

    return {
        id = math.floor(tonumber(lineRow.id) or 0),
        market = lineRow.market,
        probability = tonumber(lineRow.probability) or 0,
        fairOdds = odds.fair(lineRow.probability),
        odds = lineOdds,
        maxLiability = maxLiability,
        liability = liability,
        remaining = remaining,
        manualClosed = manualClosed,
        autoClosed = autoClosed,
        open = eventStatus == 'open' and not manualClosed and not autoClosed,
    }
end

---@param eventRow table
---@param outcomeRows table[]
---@param lineRows table[]
---@return table
local function mapEvent(eventRow, outcomeRows, lineRows)
    local eventId = math.floor(tonumber(eventRow.id) or 0)
    local minStake = math.floor(tonumber(eventRow.min_stake) or 0)
    local status = eventRow.status

    local linesByOutcome = {}
    local marketSeen = {}

    for i = 1, #lineRows do
        local row = lineRows[i]
        local outcomeId = math.floor(tonumber(row.outcome_id) or 0)
        linesByOutcome[outcomeId] = linesByOutcome[outcomeId] or {}
        linesByOutcome[outcomeId][row.market] = mapLine(row, minStake, status)
        marketSeen[row.market] = true
    end

    local markets = {}
    for i = 1, #config.markets do
        local market = config.markets[i].id
        if marketSeen[market] then markets[#markets + 1] = market end
    end

    local outcomes = {}
    for i = 1, #outcomeRows do
        local row = outcomeRows[i]
        local outcomeId = math.floor(tonumber(row.id) or 0)
        outcomes[#outcomes + 1] = {
            id = outcomeId,
            slot = math.floor(tonumber(row.slot) or 0),
            name = row.name,
            lines = linesByOutcome[outcomeId] or {},
        }
    end

    return {
        id = eventId,
        label = eventRow.label,
        status = status,
        houseEdge = tonumber(eventRow.house_edge) or 0,
        minStake = minStake,
        maxStake = math.floor(tonumber(eventRow.max_stake) or 0),
        betCount = math.floor(tonumber(eventRow.bet_count) or 0),
        createdBy = eventRow.created_by_name,
        createdAt = eventRow.created_at,
        markets = markets,
        result = parseIdList(eventRow.result_outcome_ids),
        outcomes = outcomes,
    }
end

---@param eventIds integer[]
---@return table[]
local function linesWithParlay(eventIds)
    local rows = storage.getLinesForEvents(eventIds)
    local extra = parlay.racingLiability(#eventIds == 1 and eventIds[1] or nil)

    for i = 1, #rows do
        local lineExtra = extra[math.floor(tonumber(rows[i].id) or 0)]
        if lineExtra then
            rows[i].liability = (tonumber(rows[i].liability) or 0) + lineExtra
        end
    end

    return rows
end

---@param eventRows table[]
---@return table[]
local function mapEventList(eventRows)
    if #eventRows == 0 then return {} end

    local ids = {}
    for i = 1, #eventRows do
        ids[i] = math.floor(tonumber(eventRows[i].id) or 0)
    end

    local outcomeRows = storage.getOutcomesForEvents(ids)
    local lineRows = linesWithParlay(ids)

    local outcomesByEvent = {}
    for i = 1, #outcomeRows do
        local row = outcomeRows[i]
        local eventId = math.floor(tonumber(row.event_id) or 0)
        outcomesByEvent[eventId] = outcomesByEvent[eventId] or {}
        table.insert(outcomesByEvent[eventId], row)
    end

    local linesByEvent = {}
    for i = 1, #lineRows do
        local row = lineRows[i]
        local eventId = math.floor(tonumber(row.event_id) or 0)
        linesByEvent[eventId] = linesByEvent[eventId] or {}
        table.insert(linesByEvent[eventId], row)
    end

    local mapped = {}
    for i = 1, #eventRows do
        local row = eventRows[i]
        local eventId = math.floor(tonumber(row.id) or 0)
        mapped[i] = mapEvent(row, outcomesByEvent[eventId] or {}, linesByEvent[eventId] or {})
    end

    return mapped
end

---@param id integer
---@return table?
local function mapSingleEvent(id)
    local row = storage.getEvent(id)
    if not row then return nil end

    return mapEvent(row, storage.getOutcomesForEvents({ id }), linesWithParlay({ id }))
end

---@param row table
---@return table
local function mapBet(row)
    return {
        betId = row.bet_id,
        eventId = math.floor(tonumber(row.event_id) or 0),
        eventLabel = row.label,
        market = row.market,
        outcomeId = math.floor(tonumber(row.outcome_id) or 0),
        outcomeName = row.outcome_name,
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

local prefix <const> = 'rhd_casino_racing'
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
    shared.log({ title = ('Racing — %s'):format(title), type = logType, fields = fields })
end

callback('getState', function(source)
    local role = getRole(source)
    if not role then return false, 'Akses ditolak.' end

    local marketInfo = {}
    local marketNames = {}
    for i = 1, #config.markets do
        local market = config.markets[i]
        marketNames[i] = market.id
        marketInfo[market.id] = { places = market.places }
    end

    return true, {
        role = role,
        sport = 'racing',
        events = mapEventList(storage.getEvents()),
        recapEvents = mapEventList(storage.getRecapEvents()),
        receiptItem = config.receiptItem,
        outcomeBounds = config.outcomeBounds,
        markets = marketNames,
        marketInfo = marketInfo,
        stakeBounds = config.stakeBounds,
        liabilityBounds = config.liabilityBounds,
        houseEdge = config.houseEdge,
        parlay = parlay.publicConfig,
    }
end)

callback('createEvent', function(source, data)
    if not hasRole(source, 'admin') then return false, 'Akses ditolak.' end

    local payload, outcomes, err = buildEventPayload(data)
    if not (payload and outcomes) then return false, err end

    local staff = staffInfo(source)
    payload.created_by_name = staff.name
    payload.created_by_identifier = staff.identifier

    local eventId = storage.createEvent(payload, outcomes)
    if not eventId then return false, 'Gagal menyimpan event.' end

    log('Event Created', 'info', {
        { name = 'Admin', value = ('%s (%s)'):format(staff.name, source) },
        { name = 'Event', value = ('#%s %s'):format(eventId, payload.label) },
        { name = 'Participants', value = tostring(#outcomes), inline = true },
        { name = 'House Edge', value = ('%s%%'):format(payload.house_edge), inline = true },
    })

    return true
end)

callback('updateEvent', function(source, eventId, data)
    if not hasRole(source, 'admin') then return false, 'Akses ditolak.' end

    local id = cleanInt(eventId, 1, math.maxinteger)
    if not id then return false, 'Event tidak ditemukan.' end

    local event = storage.getEvent(id)
    if not event then return false, 'Event tidak ditemukan.' end
    if event.status ~= 'draft' then return false, 'Event hanya bisa diubah saat masih draft.' end

    local payload, outcomes, err = buildEventPayload(data)
    if not (payload and outcomes) then return false, err end

    if not storage.updateEvent(id, payload, outcomes) then return false, 'Gagal menyimpan perubahan.' end

    return true
end)

callback('setEventStatus', function(source, eventId, status)
    if not hasRole(source, 'admin') then return false, 'Akses ditolak.' end

    local id = cleanInt(eventId, 1, math.maxinteger)
    if not id then return false, 'Event tidak ditemukan.' end

    local event = storage.getEvent(id)
    if not event then return false, 'Event tidak ditemukan.' end

    local allowedFrom = status == 'open' and { 'draft', 'closed' }
        or status == 'closed' and { 'open' }
        or nil

    if not allowedFrom then return false, 'Status tidak valid.' end
    if not storage.setEventStatus(id, status, allowedFrom) then
        return false, 'Status event tidak bisa diubah dari kondisi saat ini.'
    end

    local staff = staffInfo(source)
    log(status == 'open' and 'Betting Opened' or 'Betting Closed', status == 'open' and 'success' or 'warning', {
        { name = 'Admin', value = ('%s (%s)'):format(staff.name, source) },
        { name = 'Event', value = ('#%s %s'):format(id, event.label), inline = true },
    })

    return true
end)

callback('setLineClosed', function(source, lineId, closed)
    if not hasRole(source, 'admin') then return false, 'Akses ditolak.' end

    local id = cleanInt(lineId, 1, math.maxinteger)
    if not id then return false, 'Peserta tidak ditemukan.' end

    local line = storage.getLine(id)
    if not line then return false, 'Peserta tidak ditemukan.' end

    local event = storage.getEvent(math.floor(tonumber(line.event_id) or 0))
    if not event then return false, 'Peserta tidak ditemukan.' end

    if not storage.setLineClosed(id, closed == true) then return false, 'Gagal mengubah status peserta.' end

    return true
end)

callback('settleEvent', function(source, eventId, result)
    if not hasRole(source, 'admin') then return false, 'Akses ditolak.' end

    local id = cleanInt(eventId, 1, math.maxinteger)
    if not id then return false, 'Event tidak ditemukan.' end

    local event = storage.getEvent(id)
    if not event then return false, 'Event tidak ditemukan.' end

    local staff = staffInfo(source)

    if result == 'void' then
        if event.status == 'settled' or event.status == 'void' then
            return false, 'Event ini sudah diselesaikan.'
        end
        if not storage.voidEvent(id) then return false, 'Gagal membatalkan event.' end

        parlay.voidRacing(id)

        log('Event Cancelled (VOID)', 'warning', {
            { name = 'Admin', value = ('%s (%s)'):format(staff.name, source) },
            { name = 'Event', value = ('#%s %s'):format(id, event.label), inline = true },
        })

        return true
    end

    if event.status ~= 'open' and event.status ~= 'closed' then
        return false, 'Hasil hanya bisa diinput untuk event yang sudah berjalan.'
    end

    local outcomeRows = storage.getOutcomesForEvents({ id })
    local validOutcome = {}
    local outcomeName = {}
    for i = 1, #outcomeRows do
        local outcomeId = math.floor(tonumber(outcomeRows[i].id) or 0)
        validOutcome[outcomeId] = true
        outcomeName[outcomeId] = outcomeRows[i].name
    end

    local markets = activeMarkets(#outcomeRows)
    local places = maxPlaces(markets)

    if type(result) ~= 'table' or #result ~= places then
        return false, ('Hasil harus berisi %d posisi finish.'):format(places)
    end

    local resultIds = {}
    local seen = {}
    for i = 1, places do
        local outcomeId = cleanInt(result[i], 1, math.maxinteger)
        if not outcomeId or not validOutcome[outcomeId] then
            return false, ('Peserta untuk posisi %d tidak valid.'):format(i)
        end
        if seen[outcomeId] then return false, 'Satu peserta tidak boleh mengisi dua posisi.' end
        seen[outcomeId] = true
        resultIds[i] = outcomeId
    end

    local marketPlaces = {}
    for i = 1, #markets do
        marketPlaces[markets[i]] = placesOf(markets[i])
    end

    if not storage.settleEvent(id, resultIds, marketPlaces) then return false, 'Gagal menyimpan hasil event.' end

    parlay.settleRacing(id, resultIds, marketPlaces)

    local podium = {}
    for i = 1, #resultIds do
        podium[i] = ('P%d: %s'):format(i, outcomeName[resultIds[i]])
    end

    log('Event Result', 'success', {
        { name = 'Admin', value = ('%s (%s)'):format(staff.name, source) },
        { name = 'Event', value = ('#%s %s'):format(id, event.label) },
        { name = 'Result', value = table.concat(podium, '\n') },
    })

    return true
end)

callback('deleteEvent', function(source, eventId)
    if not hasRole(source, 'admin') then return false, 'Akses ditolak.' end

    local id = cleanInt(eventId, 1, math.maxinteger)
    if not id then return false, 'Event tidak ditemukan.' end

    local event = storage.getEvent(id)
    if not event then return false, 'Event tidak ditemukan.' end

    local staff = staffInfo(source)
    local isFinished = event.status == 'settled' or event.status == 'void'

    -- Event yang sudah selesai hanya diarsipkan supaya rekapnya tidak ikut hilang.
    if isFinished then
        if not storage.archiveEvent(id) then return false, 'Gagal mengarsipkan event.' end

        log('Event Removed from List', 'warning', {
            { name = 'Admin', value = ('%s (%s)'):format(staff.name, source) },
            { name = 'Event', value = ('#%s %s'):format(id, event.label) },
            { name = 'Status', value = tostring(event.status):upper(), inline = true },
            { name = 'Summary', value = 'Kept', inline = true },
        })

        return true
    end

    local ok, deletedBets = storage.deleteEvent(id)
    if not ok then return false, 'Gagal menghapus event.' end

    parlay.voidRacing(id)

    log('Event Permanently Deleted', 'error', {
        { name = 'Admin', value = ('%s (%s)'):format(staff.name, source) },
        { name = 'Event', value = ('#%s %s'):format(id, event.label) },
        { name = 'Status When Deleted', value = tostring(event.status):upper(), inline = true },
        { name = 'Bets Deleted', value = tostring(deletedBets), inline = true },
    })

    return true
end)

callback('deleteRecap', function(source, eventId)
    if not hasRole(source, 'admin') then return false, 'Akses ditolak.' end

    local id = cleanInt(eventId, 1, math.maxinteger)
    if not id then return false, 'Event tidak ditemukan.' end

    local event = storage.getEvent(id)
    if not event then return false, 'Event tidak ditemukan.' end
    if event.status ~= 'settled' and event.status ~= 'void' then
        return false, 'Rekap hanya bisa dihapus untuk event yang sudah selesai.'
    end

    local ok, deletedBets = storage.deleteEvent(id)
    if not ok then return false, 'Gagal menghapus rekap.' end

    local staff = staffInfo(source)
    log('Summary Deleted', 'error', {
        { name = 'Admin', value = ('%s (%s)'):format(staff.name, source) },
        { name = 'Event', value = ('#%s %s'):format(id, event.label) },
        { name = 'Status When Deleted', value = tostring(event.status):upper(), inline = true },
        { name = 'Bets Deleted', value = tostring(deletedBets), inline = true },
    })

    return true
end)

callback('placeBet', function(source, data)
    if not hasRole(source, 'staff') then return false, 'Akses ditolak.' end
    if type(data) ~= 'table' then return false, 'Data taruhan tidak valid.' end

    local lineId = cleanInt(data.lineId, 1, math.maxinteger)
    if not lineId then return false, 'Pilihan taruhan tidak valid.' end

    local line = storage.getLine(lineId)
    if not line then return false, 'Pilihan taruhan tidak valid.' end

    local eventId = math.floor(tonumber(line.event_id) or 0)
    local event = storage.getEvent(eventId)
    if not event then return false, 'Event tidak ditemukan.' end
    if event.status ~= 'open' then return false, 'Betting untuk event ini sedang tidak dibuka.' end
    if (tonumber(line.manual_closed) or 0) == 1 then return false, 'Peserta ini sedang ditutup untuk taruhan.' end

    local bettorSource = cleanInt(data.bettorSource, 1, math.maxinteger)
    if not bettorSource or not shared.playerExist(bettorSource) then
        return false, 'Bettor tidak ditemukan.'
    end
    if not isNearStaff(source, bettorSource) then
        return false, 'Bettor harus berada di dekat kamu.'
    end

    local minStake = math.floor(tonumber(event.min_stake) or 0)
    local maxStake = math.floor(tonumber(event.max_stake) or 0)
    local stake = cleanInt(data.stake, minStake, maxStake)
    if not stake then
        return false, ('Stake harus antara %s dan %s chip.'):format(minStake, maxStake)
    end

    local lineOdds = tonumber(line.odds) or 0
    if lineOdds <= 0 then return false, 'Odds tidak valid.' end

    local potentialReturn = odds.potentialReturn(stake, lineOdds)
    if potentialReturn <= 0 then return false, 'Potential return tidak valid.' end

    local maxLiability = math.floor(tonumber(line.max_liability) or 0)

    local lockKeys = { ('racing:%d'):format(lineId) }
    locks.acquire(lockKeys)

    local liability = (storage.getLiability(eventId)[lineId] or 0) + (parlay.racingLiability(eventId)[lineId] or 0)
    local remaining = math.max(maxLiability - liability, 0)

    if potentialReturn > remaining then
        locks.release(lockKeys)
        return false, ('BET REJECTED — sisa liability %s chip, potential return %s chip.'):format(remaining, potentialReturn)
    end

    local staff = staffInfo(source)
    local bettorName = shared.getPlayerName(bettorSource)

    local betId = storage.insertBet({
        event_id = eventId,
        line_id = lineId,
        outcome_id = math.floor(tonumber(line.outcome_id) or 0),
        market = line.market,
        odds = lineOdds,
        stake = stake,
        potential_return = potentialReturn,
        bettor_identifier = shared.getIdentifier(bettorSource),
        bettor_name = bettorName,
        staff_bet_identifier = staff.identifier,
        staff_bet_name = staff.name,
    }, config.betId)

    locks.release(lockKeys)

    if not betId then return false, 'Gagal menyimpan taruhan.' end

    local receiptGiven = ox_inventory:AddItem(bettorSource, config.receiptItem, 1, {
        betId = betId,
        event = event.label,
        market = line.market,
        pick = line.outcome_name,
        odds = lineOdds,
        stake = stake,
        potentialReturn = potentialReturn,
        description = ('%s\n%s — %s @ %s\nStake %s → %s')
            :format(betId, line.market:upper(), line.outcome_name, lineOdds, stake, potentialReturn),
    })

    log('Bet Confirmed', 'money', {
        { name = 'Bet ID', value = betId },
        { name = 'Event', value = ('#%s %s'):format(eventId, event.label), inline = true },
        { name = 'Market', value = line.market:upper(), inline = true },
        { name = 'Bettor', value = ('%s (%s)'):format(bettorName, bettorSource), inline = true },
        { name = 'Pick', value = ('%s @ %s'):format(line.outcome_name, lineOdds), inline = true },
        { name = 'Stake', value = ('%s chips'):format(stake), inline = true },
        { name = 'Potential Return', value = ('%s chips'):format(potentialReturn), inline = true },
        { name = 'Staff', value = ('%s (%s)'):format(staff.name, source), inline = true },
        { name = 'Receipt', value = receiptGiven and 'Given' or 'FAILED (inventory full)', inline = true },
    })

    return true, {
        betId = betId,
        eventLabel = event.label,
        market = line.market,
        outcomeName = line.outcome_name,
        odds = lineOdds,
        stake = stake,
        potentialReturn = potentialReturn,
        bettorName = bettorName,
        staffName = staff.name,
        receiptGiven = receiptGiven == true,
    }
end)

callback('lookupBet', function(source, betId)
    if not hasRole(source, 'staff') then return false, 'Akses ditolak.' end

    local id = cleanString(betId, 24)
    if not id then return false, 'Bet ID tidak valid.' end

    local row = storage.getBet(id:upper())
    if not row then return false, 'Bet ID tidak ditemukan.' end

    return true, mapBet(row)
end)

callback('markPaid', function(source, betId, claimantSource)
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

    log(nextStatus == 'paid' and 'Payout Paid' or 'Stake Refunded', 'money', {
        { name = 'Bet ID', value = row.bet_id },
        { name = 'Bettor', value = row.bettor_name, inline = true },
        { name = 'Receiver', value = ('%s (%s)'):format(shared.getPlayerName(claimant), claimant), inline = true },
        { name = 'Amount', value = ('%s chips'):format(amount), inline = true },
        { name = 'Staff', value = ('%s (%s)'):format(staff.name, source), inline = true },
        { name = 'Receipt', value = receiptTaken and 'Collected' or 'NOT in receiver inventory', inline = true },
    })

    return true, {
        betId = row.bet_id,
        status = nextStatus,
        amount = amount,
        receiptTaken = receiptTaken,
    }
end)

callback('getRecap', function(source, eventId)
    if not hasRole(source, 'admin') then return false, 'Akses ditolak.' end

    local id = cleanInt(eventId, 1, math.maxinteger)
    if not id then return false, 'Event tidak ditemukan.' end

    local eventRow = storage.getEvent(id)
    if not eventRow then return false, 'Event tidak ditemukan.' end

    local totals = storage.getRecapTotals(id) or {}
    local rows = storage.getBetsByEvent(id)
    local bets = {}

    for i = 1, #rows do
        rows[i].label = eventRow.label
        bets[i] = mapBet(rows[i])
    end

    local totalStake = math.floor(tonumber(totals.total_stake) or 0)
    local paidOut = math.floor(tonumber(totals.paid_out) or 0)
    local refundedOut = math.floor(tonumber(totals.refunded_out) or 0)

    return true, {
        event = mapSingleEvent(id),
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

local HEAVY <const> = { getState = true, getRecap = true }

RegisterNetEvent(('%s:request'):format(prefix), function(requestId, name, ...)
    local src = source

    if type(requestId) ~= 'number' or not HEAVY[name] then return end

    local ok, result = handlers[name](src, ...)

    TriggerCasinoEvent(('%s:response'):format(prefix), src, requestId, ok, result)
end)