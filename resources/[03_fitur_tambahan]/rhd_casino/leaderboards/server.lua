local storage = require 'modules.storage'
local sportsbookConfig = require 'casino.sportsbook.config'

local RESET_GRADES <const> = { 3, 4 }
local RANKING_BOARDS <const> = { fight = true, racing = true }
local RANKING_SCREEN_SIZE <const> = 10
local RANKING_MAX_VALUE <const> = 1000000

---@param source number
---@param grade? number|number[]
---@return boolean
local function canManageSpenders(source, grade)
    local playerJob = sm_core:GetPlayerData(source, 'job')

    if grade then
        local tg = type(grade)
        local level = playerJob?.grade?.level

        if tg == "number" then
            return playerJob?.name == shared.casinoJobName and level >= grade
        elseif tg == 'table' and grade[1] then
            return playerJob?.name == shared.casinoJobName and lib.array.includes(grade, level) --[[@as boolean]]
        end

        return false
    end

    return playerJob?.name == shared.casinoJobName
end

---@param source number
---@param grade? number|number[]
---@return boolean
local function rejectUnauthorized(source, grade)
    if canManageSpenders(source, grade) then return false end

    lib.notify(source, {
        title = 'Access Denied',
        description = 'You do not have permission to manage spender entries.',
        type = 'error',
    })
    return true
end

lib.callback.register('rhd_casino_leaderboards:getWinnersLeaderboard', function (source)
    return storage.getTopChipWinners(10)
end)

lib.callback.register('rhd_casino_leaderboards:getSpendersLeaderboard', function (source)
    return storage.spender.getTopSpender(10)
end)

lib.callback.register('rhd_casino_leaderboards:getAllSpenders', function (source)
    if rejectUnauthorized(source) then return {} end
    return storage.getAllSpenders()
end)

lib.cron.new('*/5 * * * *', function ()
    local winners = storage.getTopChipWinners(10)
    BroadcastCasinoPlayers('rhd_casino_leaderboards:updateWinners', winners)
end)

lib.callback.register('rhd_casino_leaderboards:getManageData', function (source)
    if not canManageSpenders(source) then return false, 'Menu ini khusus pegawai Velvet Casino.' end

    local winners = {}
    for i, row in ipairs(storage.getTopChipWinners(10)) do
        winners[i] = { name = row.name, amount = tonumber(row.amount) or 0 }
    end

    return true, {
        spenders = storage.getAllSpenders(),
        winners = winners,
        canReset = canManageSpenders(source, RESET_GRADES),
    }
end)

lib.callback.register('rhd_casino_leaderboards:resetChipWinnings', function (source)
    if not canManageSpenders(source, RESET_GRADES) then
        return false, 'Hanya General Manager dan Owner yang bisa mereset leaderboard.'
    end

    if not storage.resetChipWinnings() then
        return false, 'Gagal mereset leaderboard chip winnings.'
    end

    BroadcastCasinoPlayers('rhd_casino_leaderboards:updateWinners', storage.getTopChipWinners(10))
    lib.print.info(('[CasinoLeaderboards] Total chip winnings leaderboard reset by %s.'):format(shared.getPlayerName(source)))

    return true
end)

lib.callback.register('rhd_casino_leaderboards:update_spender', function (source, data)
    if rejectUnauthorized(source) or type(data) ~= 'table' then return false end

    local entry = data?.entry or {}
    entry.id = data?.id or entry.id
    entry.name = type(entry.name) == 'string' and entry.name:sub(1, 128) or nil
    entry.image = type(entry.image) == 'string' and entry.image:sub(1, 512) or nil
    entry.amount = math.floor(tonumber(entry.amount) or -1)

    if not entry.name or entry.name == '' or entry.amount < 0 then return false end

    local success = storage.insertOrUpdateSpender(entry)

    if success then
        BroadcastCasinoPlayers('rhd_casino_leaderboards:updateSpenders', storage.getTopSpender(10))
    end

    return success
end)

lib.callback.register('rhd_casino_leaderboards:remove_spender', function (source, data)
    if rejectUnauthorized(source) or type(data) ~= 'table' then return false end

    local id = type(data.id) == 'string' and data.id:sub(1, 128) or nil
    if not id or id == '' then return false end

    local success = storage.removeSpender(id)

    if success then
        BroadcastCasinoPlayers('rhd_casino_leaderboards:updateSpenders', storage.getTopSpender(10))
    end

    return success
end)

---@param board string
---@return table[]
local function rankingScreen(board)
    local entries = {}

    for i, row in ipairs(storage.ranking.list(board, RANKING_SCREEN_SIZE)) do
        entries[i] = {
            name = row.name,
            image = row.image,
            wins = tonumber(row.wins) or 0,
            losses = tonumber(row.losses) or 0,
            points = tonumber(row.points) or 0,
        }
    end

    return entries
end

---@param board string
local function broadcastRanking(board)
    local entries = rankingScreen(board)

    for _, playerId in ipairs(GetPlayers()) do
        TriggerCasinoEvent('rhd_casino_leaderboards:updateRanking', playerId, board, entries)
    end
end

---@param value any
---@return integer?
local function rankingNumber(value)
    local number = tonumber(value)
    if not number or number ~= number then return nil end

    number = math.floor(number)
    if number < 0 or number > RANKING_MAX_VALUE then return nil end

    return number
end

lib.callback.register('rhd_casino_leaderboards:getRankingScreen', function (_, board)
    if not RANKING_BOARDS[board] then return {} end
    return rankingScreen(board)
end)

lib.callback.register('rhd_casino_leaderboards:getRankings', function (source, data)
    local board = type(data) == 'table' and data.board or nil
    if not RANKING_BOARDS[board] then return false, 'Papan ranking tidak dikenal.' end
    if not canManageSpenders(source) then return false, 'Menu ini khusus pegawai Velvet Casino.' end

    local entries = {}
    for i, row in ipairs(storage.ranking.list(board, 100)) do
        entries[i] = {
            id = row.id,
            name = row.name,
            image = row.image,
            wins = tonumber(row.wins) or 0,
            losses = tonumber(row.losses) or 0,
            points = tonumber(row.points) or 0,
        }
    end

    return true, {
        entries = entries,
        canEdit = canManageSpenders(source, sportsbookConfig.access.admin),
    }
end)

lib.callback.register('rhd_casino_leaderboards:saveRanking', function (source, data)
    if type(data) ~= 'table' or not RANKING_BOARDS[data.board] then return false, 'Data tidak valid.' end
    if not canManageSpenders(source, sportsbookConfig.access.admin) then
        return false, 'Hanya General Manager dan Owner yang bisa mengubah ranking.'
    end

    local name = type(data.name) == 'string' and data.name:gsub('^%s+', ''):gsub('%s+$', ''):sub(1, 128) or ''
    if name == '' then return false, 'Nama wajib diisi.' end

    local image = type(data.image) == 'string' and data.image:sub(1, 512) or ''
    local wins, losses, points = rankingNumber(data.wins or 0), rankingNumber(data.losses or 0), rankingNumber(data.points or 0)
    if not wins or not losses or not points then
        return false, ('Angka harus antara 0 dan %s.'):format(RANKING_MAX_VALUE)
    end

    local id = type(data.id) == 'string' and data.id ~= '' and data.id:sub(1, 64) or nil
    if id and not storage.ranking.exists(data.board, id) then return false, 'Data ranking tidak ditemukan.' end

    local savedId = storage.ranking.save({
        id = id,
        board = data.board,
        name = name,
        image = image ~= '' and image or nil,
        wins = data.board == 'fight' and wins or 0,
        losses = data.board == 'fight' and losses or 0,
        points = data.board == 'racing' and points or 0,
    })

    if not savedId then return false, 'Gagal menyimpan ranking.' end

    broadcastRanking(data.board)
    return true, { id = savedId }
end)

lib.callback.register('rhd_casino_leaderboards:removeRanking', function (source, data)
    if type(data) ~= 'table' or not RANKING_BOARDS[data.board] then return false, 'Data tidak valid.' end
    if not canManageSpenders(source, sportsbookConfig.access.admin) then
        return false, 'Hanya General Manager dan Owner yang bisa mengubah ranking.'
    end

    local id = type(data.id) == 'string' and data.id:sub(1, 64) or nil
    if not id or id == '' then return false, 'Data tidak valid.' end

    if not storage.ranking.remove(data.board, id) then return false, 'Gagal menghapus ranking.' end

    broadcastRanking(data.board)
    return true
end)

