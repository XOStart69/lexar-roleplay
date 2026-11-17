local layout = localmodule 'modules.layout'

local random = math.random
local huge = math.huge

local engine = {}

---@class DominoTile
---@field id number
---@field lo number
---@field hi number

---@type DominoTile[]
local TILES = {}
for lo = 0, 6 do
    for hi = lo, 6 do
        TILES[#TILES + 1] = { id = #TILES + 1, lo = lo, hi = hi }
    end
end
engine.tiles = TILES

local DOUBLE_SIX = #TILES

---@param count number
---@param fourMode string
---@return string?
function engine.modeFor(count, fourMode)
    if count == 2 then return 'duel' end
    if count == 3 then return 'ffa' end
    if count == 4 then return fourMode == 'ffa' and 'ffa4' or 'pairs' end
end

---@param mode string
---@return boolean
function engine.drawMode(mode)
    return mode == 'duel' or mode == 'ffa'
end

---@param seats number[]
---@param mode string
---@param target number
---@return table
function engine.newMatch(seats, mode, target)
    local teamOf, teams = {}, 0
    for i = 1, #seats do
        local seat = seats[i]
        if mode == 'pairs' then
            teamOf[seat] = seat % 2 == 1 and 1 or 2
        else
            teamOf[seat] = i
        end
    end
    teams = mode == 'pairs' and 2 or #seats

    local scores = {}
    for i = 1, teams do scores[i] = 0 end

    return { mode = mode, seats = seats, teamOf = teamOf, teams = teams, target = target, scores = scores, round = 0 }
end

---@param match table
---@param seat number
---@return number
function engine.nextSeat(match, seat)
    local seats = match.seats
    for i = 1, #seats do
        if seats[i] == seat then
            return seats[i % #seats + 1]
        end
    end
    return seats[1]
end

---@param tile DominoTile
---@return number
local function pips(tile)
    return tile.lo + tile.hi
end

---@param hand DominoTile[]
---@return number
function engine.handPips(hand)
    local total = 0
    for i = 1, #hand do total = total + pips(hand[i]) end
    return total
end

---@return DominoTile[]
function engine.shuffleDeck()
    local deck = {}
    for i = 1, #TILES do deck[i] = TILES[i] end
    for i = #deck, 2, -1 do
        local j = random(i)
        deck[i], deck[j] = deck[j], deck[i]
    end
    return deck
end

---@param match table
---@param hands table<number, DominoTile[]>
---@param stock DominoTile[]
---@return table
function engine.beginHand(match, hands, stock)
    match.round = match.round + 1

    local hand = { hands = hands, stock = stock, board = {}, passes = 0, turn = 0 }

    local opener = match.opener
    if opener and hands[opener] then
        hand.turn = opener
        hand.free = true
        return hand
    end

    local bestSeat, bestTile, bestScore = nil, nil, -1
    for seat, tiles in pairs(hands) do
        for i = 1, #tiles do
            local tile = tiles[i]
            local score
            if engine.drawMode(match.mode) then
                score = (tile.lo == tile.hi and 100 or 0) + pips(tile)
            else
                score = tile.id == DOUBLE_SIX and 1 or -1
            end
            if score > bestScore then
                bestSeat, bestTile, bestScore = seat, tile, score
            end
        end
    end

    hand.turn = bestSeat or match.seats[1]
    hand.forced = bestTile and bestTile.id
    return hand
end

---@param match table
---@return table
function engine.newHand(match)
    local deck = engine.shuffleDeck()
    local hands, cursor = {}, 0
    for i = 1, #match.seats do
        local tiles = {}
        for n = 1, 7 do
            cursor = cursor + 1
            tiles[n] = deck[cursor]
        end
        hands[match.seats[i]] = tiles
    end

    local stock = {}
    if engine.drawMode(match.mode) then
        for i = cursor + 1, #deck do stock[#stock + 1] = deck[i] end
    end

    return engine.beginHand(match, hands, stock)
end

---@param hand table
---@param tile DominoTile
---@return boolean left
---@return boolean right
function engine.fits(hand, tile)
    if #hand.board == 0 then
        local ok = hand.free or hand.forced == nil or hand.forced == tile.id
        return ok, false
    end
    local left, right = hand.left, hand.right
    return tile.lo == left or tile.hi == left, tile.lo == right or tile.hi == right
end

---@param hand table
---@param seat number
---@return { tile: DominoTile, side: string }[]
function engine.moves(hand, seat)
    local list = {}
    local tiles = hand.hands[seat]
    if not tiles then return list end

    for i = 1, #tiles do
        local tile = tiles[i]
        local left, right = engine.fits(hand, tile)
        if left then list[#list + 1] = { tile = tile, side = 'left' } end
        if right and not (left and hand.left == hand.right) then
            list[#list + 1] = { tile = tile, side = 'right' }
        end
    end

    return list
end

---@param tiles DominoTile[]
---@param id number
---@return number?
local function indexOf(tiles, id)
    for i = 1, #tiles do
        if tiles[i].id == id then return i end
    end
end

---@param hand table
---@param seat number
---@param tileId number
---@param side string
---@return table?
function engine.play(hand, seat, tileId, side)
    if hand.turn ~= seat then return end
    if side ~= 'left' and side ~= 'right' then return end

    local tiles = hand.hands[seat]
    local index = tiles and indexOf(tiles, tileId)
    if not index then return end

    local tile = tiles[index]
    local fitsLeft, fitsRight = engine.fits(hand, tile)
    local board = hand.board

    if #board == 0 then
        if not fitsLeft then return end
        local x, y, yaw, branches = layout.first(tile)
        hand.branches = branches
        hand.left, hand.right = tile.lo, tile.hi
        board[1] = { id = tile.id, lo = tile.lo, hi = tile.hi, x = x, y = y, r = yaw, seat = seat }
    else
        if (side == 'left' and not fitsLeft) or (side == 'right' and not fitsRight) then return end

        local branchIndex = side == 'left' and 1 or 2
        local match = hand[side]
        local x, y, yaw, branch = layout.next(board, hand.branches[branchIndex], tile, match)
        hand.branches[branchIndex] = branch
        hand[side] = tile.lo == match and tile.hi or tile.lo
        board[#board + 1] = { id = tile.id, lo = tile.lo, hi = tile.hi, x = x, y = y, r = yaw, seat = seat }
    end

    table.remove(tiles, index)
    hand.passes = 0
    hand.free = nil
    hand.forced = nil

    local domino = #tiles == 0
    return { tile = tile, domino = domino }
end

---@param hand table
---@param seat number
---@return DominoTile?
function engine.draw(hand, seat)
    if hand.turn ~= seat then return end
    local stock = hand.stock
    local count = #stock
    if count == 0 then return end

    local tile = stock[count]
    stock[count] = nil
    local tiles = hand.hands[seat]
    tiles[#tiles + 1] = tile
    return tile
end

---@param hand table
---@param seat number
---@return boolean
function engine.canPass(hand, seat)
    return hand.turn == seat and #hand.stock == 0 and #engine.moves(hand, seat) == 0
end

---@param match table
---@param hand table
---@param winnerSeat number?
---@return table
function engine.score(match, hand, winnerSeat)
    local teamOf = match.teamOf
    local seatPips, teamPips = {}, {}
    for i = 1, match.teams do teamPips[i] = 0 end

    for seat, tiles in pairs(hand.hands) do
        local total = engine.handPips(tiles)
        seatPips[seat] = total
        local team = teamOf[seat]
        teamPips[team] = teamPips[team] + total
    end

    local blocked = winnerSeat == nil
    local team = winnerSeat and teamOf[winnerSeat] or 0

    if blocked then
        local lowest, ties = huge, 0
        for i = 1, match.teams do
            local total = teamPips[i]
            if total < lowest then
                lowest, team, ties = total, i, 1
            elseif total == lowest then
                ties = ties + 1
            end
        end
        if ties ~= 1 then team = 0 end

        if team ~= 0 then
            local best = huge
            for seat, total in pairs(seatPips) do
                if teamOf[seat] == team and total < best then
                    best, winnerSeat = total, seat
                end
            end
        end
    end

    local points = 0
    if team ~= 0 then
        for i = 1, match.teams do
            if i ~= team then points = points + teamPips[i] end
        end
        match.scores[team] = match.scores[team] + points
    end

    match.opener = winnerSeat

    local over = team ~= 0 and match.scores[team] >= match.target

    return {
        seat = winnerSeat,
        team = team,
        points = points,
        blocked = blocked,
        seatPips = seatPips,
        over = over,
    }
end

---@param hand table
---@param seat number
---@param tile DominoTile
---@param side string
---@return number
local function evaluate(hand, seat, tile, side)
    local tiles = hand.hands[seat]
    local newEnd
    if #hand.board == 0 then
        newEnd = tile.hi
    else
        local match = hand[side]
        newEnd = tile.lo == match and tile.hi or tile.lo
    end

    local keep = 0
    for i = 1, #tiles do
        local other = tiles[i]
        if other.id ~= tile.id and (other.lo == newEnd or other.hi == newEnd) then
            keep = keep + 1
        end
    end

    local value = pips(tile) + keep * 3 + random() * 0.5
    if tile.lo == tile.hi then value = value + 8 end
    return value
end

---@param hand table
---@param seat number
---@return string action
---@return number? tileId
---@return string? side
function engine.botMove(hand, seat)
    local moves = engine.moves(hand, seat)

    if #moves == 0 then
        if #hand.stock > 0 then return 'draw' end
        return 'pass'
    end

    local best, bestValue = moves[1], -huge
    for i = 1, #moves do
        local move = moves[i]
        local value = evaluate(hand, seat, move.tile, move.side)
        if value > bestValue then
            best, bestValue = move, value
        end
    end

    return 'play', best.tile.id, best.side
end

return engine
