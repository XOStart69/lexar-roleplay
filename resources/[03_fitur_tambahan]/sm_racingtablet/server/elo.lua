local K <const> = 32

---@param a number
---@param b number
---@return number
local function expected(a, b)
    return 1 / (1 + 10 ^ ((b - a) / 400))
end

---@param citizenid string
---@param opponent string
---@param won boolean
function applyElo(citizenid, opponent, won)
    local mine = getRacer(citizenid)
    local theirs = getRacer(opponent)

    if not mine or not theirs then return end

    local delta = math.floor(K * ((won and 1 or 0) - expected(mine.elo, theirs.elo)))

    MySQL.update.await(
        'UPDATE racing_racers SET elo = GREATEST(elo + ?, 100), wins = wins + ?, losses = losses + ?, races = races + 1, best_elo = GREATEST(best_elo, elo + ?) WHERE citizenid = ?',
        { delta, won and 1 or 0, won and 0 or 1, delta, citizenid }
    )

    MySQL.update.await(
        'UPDATE racing_racers SET elo = GREATEST(elo - ?, 100), wins = wins + ?, losses = losses + ?, races = races + 1 WHERE citizenid = ?',
        { delta, won and 0 or 1, won and 1 or 0, opponent }
    )
end

---@param citizenid string
---@return string
function eloRank(citizenid)
    local racer = getRacer(citizenid)
    if not racer then return 'Unranked' end

    local elo = racer.elo

    if elo >= 1800 then return 'Legend' end
    if elo >= 1600 then return 'Master' end
    if elo >= 1400 then return 'Diamond' end
    if elo >= 1200 then return 'Platinum' end
    if elo >= 1100 then return 'Gold' end
    if elo >= 1000 then return 'Silver' end

    return 'Bronze'
end