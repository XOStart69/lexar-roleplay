local tests = {
    "straight_flush", "four_of_a_kind", "full_house",
    "flush", "straight", "three_of_a_kind",
    "two_pair", "one_pair", "hi_card"
}
local function getCardRank(card)
    return tonumber(card:sub(2, 3))
end

local function getCardSuit(card)
    return card:sub(1, 1)
end

local function group_cards(dealerdeck, playerdeck)
    local c = {}
    for i = 1, 5 do c[i] = dealerdeck[i] end
    c[6] = playerdeck[1]
    c[7] = playerdeck[2]
    return c
end

local function get_predominant_suit(my_cards)
    local count = { c = 0, s = 0, h = 0, d = 0 }
    for i = 1, #my_cards do
        local s = getCardSuit(my_cards[i])
        if count[s] then count[s] = count[s] + 1 end
    end
    local best = "c"
    for i = 1, 3 do
        local suit = ({ "s", "h", "d" })[i]
        if count[suit] > count[best] then best = suit end
    end
    return best
end

local function fill_and_sort(t, size)
    for i = 1, size do
        if t[i] == nil then t[i] = -1 end
    end
    table.sort(t, function(a, b) return a > b end)
end

local function find_best_stretch(wc)
    local abs_len, abs_hi = 0, 0
    local cur_len, cur_hi = 1, 0
    for i = 1, 8 do
        local a = wc[i]
        local b = wc[i + 1]
        if a and b and a > 0 and b > 0 and (a - b) == 1 then
            cur_len = cur_len + 1
            if cur_hi < 1 then cur_hi = a end
        elseif a and a > 0 then
            if cur_len > abs_len then
                abs_len = cur_len
                if cur_hi < 1 then cur_hi = a end
                abs_hi = cur_hi
            end
            cur_len = 1
            cur_hi = 0
        end
    end
    return abs_len, abs_hi
end

local compare_straight
local function compare_straight_flush(a, b)
    return compare_straight(a, b)
end

local function test_straight_flush(dealercards, playercards)
    local my_cards = group_cards(dealercards, playercards)
    local the_suit = get_predominant_suit(my_cards)
    local wc = {}
    local wi = 1
    for i = 1, 7 do
        if getCardSuit(my_cards[i]) == the_suit then
            local r = getCardRank(my_cards[i])
            wc[wi] = r
            wi = wi + 1
            if r == 14 then wc[8] = 1 end
        end
    end
    fill_and_sort(wc, 8)
    local abs_len, abs_hi = find_best_stretch(wc)
    local num_mine = 0
    for i = 0, abs_len - 1 do
        local r = abs_hi - i
        if the_suit .. r == playercards[1] or
           the_suit .. r == playercards[2] then
            num_mine = num_mine + 1
        end
    end
    return {
        straight_hi = abs_hi,
        num_needed = 5 - abs_len,
        num_mine = num_mine,
        hand_name = "Straight Flush",
    }
end

local function test_four_of_a_kind(dealercards, playercards)
    local my_cards = group_cards(dealercards, playercards)
    local ranks = {}
    for i = 1, 13 do ranks[i] = 0 end
    for i = 1, #my_cards do
        local idx = getCardRank(my_cards[i]) - 1
        ranks[idx] = ranks[idx] + 1
    end
    local four, kicker
    for i = 1, 13 do
        if ranks[i] == 4 then
            four = i + 1
        elseif ranks[i] > 0 then
            kicker = i + 1
        end
    end
    local num_mine = 0
    if four then
        if getCardRank(playercards[1]) == four then num_mine = num_mine + 1 end
        if getCardRank(playercards[2]) == four then num_mine = num_mine + 1 end
    end
    return {
        rank = four,
        kicker = kicker,
        num_needed = four and 0 or 4,
        num_mine = num_mine,
        hand_name = "Four of a Kind",
    }
end

local function compare_four_of_a_kind(a, b)
    if a.rank > b.rank then return "a"
    elseif b.rank > a.rank then return "b"
    elseif a.kicker > b.kicker then return "a"
    elseif b.kicker > a.kicker then return "b"
    else return "c" end
end

local function test_full_house(dealercards, playercards)
    local my_cards = group_cards(dealercards, playercards)
    local ranks = {}
    for i = 1, 13 do ranks[i] = 0 end
    for i = 1, #my_cards do
        local idx = getCardRank(my_cards[i]) - 1
        ranks[idx] = ranks[idx] + 1
    end
    local three, two
    for i = 1, 13 do
        if ranks[i] == 3 then
            if three and three > (two or 0) then two = three end
            three = i + 1
        elseif ranks[i] == 2 then
            two = i + 1
        end
    end
    local num_needed = 5
    local major_rank, num_mine_major = nil, 0
    if three then
        num_needed = num_needed - 3
        major_rank = three
        if getCardRank(playercards[1]) == three then num_mine_major = num_mine_major + 1 end
        if getCardRank(playercards[2]) == three then num_mine_major = num_mine_major + 1 end
    end
    local minor_rank, num_mine_minor = nil, 0
    if two then
        num_needed = num_needed - 2
        minor_rank = two
        if getCardRank(playercards[1]) == two then num_mine_minor = num_mine_minor + 1 end
        if getCardRank(playercards[2]) == two then num_mine_minor = num_mine_minor + 1 end
    end
    return {
        major_rank = major_rank,
        minor_rank = minor_rank,
        num_mine_major = num_mine_major,
        num_mine_minor = num_mine_minor,
        num_mine = num_mine_major + num_mine_minor,
        num_needed = num_needed,
        hand_name = "Full House",
    }
end

local function compare_full_house(a, b)
    if a.major_rank > b.major_rank then return "a"
    elseif b.major_rank > a.major_rank then return "b"
    elseif a.minor_rank > b.minor_rank then return "a"
    elseif b.minor_rank > a.minor_rank then return "b"
    else return "c" end
end

local function test_flush(dealercards, playercards)
    local my_cards = group_cards(dealercards, playercards)
    local the_suit = get_predominant_suit(my_cards)
    local wc = {}
    local wi = 1
    local num_in_flush = 0
    for i = 1, #my_cards do
        local card = my_cards[i]
        if getCardSuit(card) == the_suit then
            num_in_flush = num_in_flush + 1
            wc[wi] = getCardRank(card)
            wi = wi + 1
        end
    end
    for i = 1, 7 do
        if wc[i] == nil then wc[i] = -1 end
    end
    table.sort(wc, function(a, b) return a > b end)
    local result = { num_needed = 5 - num_in_flush, suit = the_suit, hand_name = "Flush" }
    local num_mine = 0
    for i = 1, 5 do
        local rank = wc[i]
        result["flush_" .. (i - 1)] = (rank > 0) and rank or ""
        if rank > 0 then
            if the_suit .. rank == playercards[1] or
               the_suit .. rank == playercards[2] then
                num_mine = num_mine + 1
            end
        end
    end
    result.num_mine = num_mine
    return result
end

local function compare_flush(a, b)
    for i = 0, 4 do
        local fa = a["flush_" .. i]
        local fb = b["flush_" .. i]
        if fa > fb then return "a" elseif fb > fa then return "b" end
    end
    return "c"
end

local function test_straight(dealercards, playercards)
    local my_cards = group_cards(dealercards, playercards)
    local wc = {}
    local seen = {}
    local wi = 1
    for i = 1, 7 do
        local r = getCardRank(my_cards[i])
        if not seen[r] then
            seen[r] = true
            wc[wi] = r
            wi = wi + 1
            if r == 14 then wc[8] = 1 end
        end
    end
    fill_and_sort(wc, 8)
    local abs_len, abs_hi = find_best_stretch(wc)
    local num_mine = 0
    for i = 0, abs_len - 1 do
        local r = abs_hi - i
        if r == getCardRank(playercards[1]) or
           r == getCardRank(playercards[2]) then
            num_mine = num_mine + 1
        end
    end
    return {
        straight_hi = abs_hi,
        num_needed = 5 - abs_len,
        num_mine = num_mine,
        hand_name = "Straight",
    }
end

compare_straight = function(a, b)
    if a.straight_hi > b.straight_hi then return "a"
    elseif b.straight_hi > a.straight_hi then return "b"
    else return "c" end
end

local function test_three_of_a_kind(dealercards, playercards)
    local my_cards = group_cards(dealercards, playercards)
    local ranks = {}
    for i = 1, 13 do ranks[i] = 0 end
    for i = 1, #my_cards do
        local idx = getCardRank(my_cards[i]) - 1
        ranks[idx] = ranks[idx] + 1
    end
    local three, k1, k2
    for i = 1, 13 do
        if ranks[i] == 3 then
            three = i + 1
        elseif ranks[i] == 1 then
            k2 = k1 ; k1 = i + 1
        elseif ranks[i] > 1 then
            k1 = i + 1 ; k2 = i + 1
        end
    end
    local num_mine = 0
    if three then
        if getCardRank(playercards[1]) == three then num_mine = num_mine + 1 end
        if getCardRank(playercards[2]) == three then num_mine = num_mine + 1 end
    end
    return {
        rank = three,
        num_needed = three and 0 or 3,
        num_mine = num_mine,
        kicker_1 = k1,
        kicker_2 = k2,
        hand_name = "Three of a Kind",
    }
end

local function compare_three_of_a_kind(a, b)
    if a.rank > b.rank then return "a"
    elseif b.rank > a.rank then return "b"
    elseif a.kicker_1 > b.kicker_1 then return "a"
    elseif b.kicker_1 > a.kicker_1 then return "b"
    elseif a.kicker_2 > b.kicker_2 then return "a"
    elseif b.kicker_2 > a.kicker_2 then return "b"
    else return "c" end
end

local function test_two_pair(dealercards, playercards)
    local my_cards = group_cards(dealercards, playercards)
    local ranks = {}
    for i = 1, 13 do ranks[i] = 0 end
    for i = 1, #my_cards do
        local idx = getCardRank(my_cards[i]) - 1
        ranks[idx] = ranks[idx] + 1
    end
    local first, second, kicker
    for i = 13, 1, -1 do
        if ranks[i] == 2 then
            if not first then first = i + 1
            elseif not second then second = i + 1
            elseif not kicker then kicker = i + 1
            else break end
        elseif not kicker and ranks[i] > 0 then
            kicker = i + 1
        end
    end
    local r0 = getCardRank(playercards[1])
    local r1 = getCardRank(playercards[2])
    local num_mine = 0
    if r0 == first or r0 == second then num_mine = num_mine + 1 end
    if r1 == first or r1 == second then num_mine = num_mine + 1 end
    return {
        rank_1 = first,
        rank_2 = second,
        kicker = kicker,
        num_needed = second and 0 or (first and 1 or 2),
        num_mine = num_mine,
        hand_name = "Two Pair",
    }
end

local function compare_two_pair(a, b)
    if a.rank_1 > b.rank_1 then return "a"
    elseif b.rank_1 > a.rank_1 then return "b"
    elseif a.rank_2 > b.rank_2 then return "a"
    elseif b.rank_2 > a.rank_2 then return "b"
    elseif a.kicker > b.kicker then return "a"
    elseif b.kicker > a.kicker then return "b"
    else return "c" end
end

local function test_one_pair(dealercards, playercards)
    local my_cards = group_cards(dealercards, playercards)
    local ranks = {}
    for i = 1, 13 do ranks[i] = 0 end
    for i = 1, #my_cards do
        local idx = getCardRank(my_cards[i]) - 1
        ranks[idx] = ranks[idx] + 1
    end
    local pair = 0
    local k1, k2, k3
    for i = 1, 13 do
        if ranks[i] == 2 then
            pair = i + 1
        elseif ranks[i] == 1 then
            k3 = k2 ; k2 = k1 ; k1 = i + 1
        elseif ranks[i] > 2 then
            k1 = i + 1 ; k2 = i + 1 ; k3 = i + 1
        end
    end
    local num_mine = 0
    if pair ~= 0 then
        if getCardRank(playercards[1]) == pair then num_mine = num_mine + 1 end
        if getCardRank(playercards[2]) == pair then num_mine = num_mine + 1 end
    end
    return {
        rank = pair,
        num_needed = (pair ~= 0) and 0 or 1,
        num_mine = num_mine,
        kicker_1 = k1,
        kicker_2 = k2,
        kicker_3 = k3,
        hand_name = "One Pair",
    }
end

local function compare_one_pair(a, b)
    if a.rank > b.rank then return "a"
    elseif b.rank > a.rank then return "b"
    elseif a.kicker_1 > b.kicker_1 then return "a"
    elseif b.kicker_1 > a.kicker_1 then return "b"
    elseif a.kicker_2 > b.kicker_2 then return "a"
    elseif b.kicker_2 > a.kicker_2 then return "b"
    elseif a.kicker_3 > b.kicker_3 then return "a"
    elseif b.kicker_3 > a.kicker_3 then return "b"
    else return "c" end
end

local function test_hi_card(dealercards, playercards)
    local my_cards = group_cards(dealercards, playercards)
    local wc = {}
    for i = 1, #my_cards do
        wc[i] = getCardRank(my_cards[i]) or -1
    end
    table.sort(wc, function(a, b) return a > b end)
    local result = { num_needed = 0, hand_name = "High Card" }
    for i = 1, 5 do
        result["hi_card_" .. (i - 1)] = wc[i] or ""
    end
    return result
end

local function compare_hi_card(a, b)
    for i = 0, 4 do
        local ha = a["hi_card_" .. i]
        local hb = b["hi_card_" .. i]
        if ha > hb then return "a" elseif hb > ha then return "b" end
    end
    return "c"
end

local test_fn = {
    straight_flush = test_straight_flush,
    four_of_a_kind = test_four_of_a_kind,
    full_house = test_full_house,
    flush = test_flush,
    straight = test_straight,
    three_of_a_kind = test_three_of_a_kind,
    two_pair = test_two_pair,
    one_pair = test_one_pair,
    hi_card = test_hi_card,
}
local compare_fn = {
    straight_flush = compare_straight_flush,
    four_of_a_kind = compare_four_of_a_kind,
    full_house = compare_full_house,
    flush = compare_flush,
    straight = compare_straight,
    three_of_a_kind = compare_three_of_a_kind,
    two_pair = compare_two_pair,
    one_pair = compare_one_pair,
    hi_card = compare_hi_card,
}
local function execute_test(name, dealercards, playercards)
    local fn = test_fn[name]
    assert(fn, "execute_test: unknown test '" .. name .. "'")
    return fn(dealercards, playercards)
end

local function execute_compare(name, hand_in, best_hand)
    local fn = compare_fn[name]
    assert(fn, "execute_compare: unknown compare '" .. name .. "'")
    return fn(hand_in, best_hand)
end

local function winners_helper(dealercards, my_players, test)
    local best
    local winners = {}
    for i = 1, #my_players do
        if not my_players[i] then goto continue end
        local a = execute_test(test, dealercards, my_players[i].cards)
        if a.num_needed > 0 then goto continue end
        if best == nil then
            best = a
            winners = {}
            winners[i] = a
        else
            local comp = execute_compare(test, a, best)
            if comp == "a" then
                best = a
                winners = {}
                winners[i] = a
            elseif comp == "b" then
            elseif comp == "c" then
                winners[i] = a
            end
        end
        ::continue::
    end
    for i = 1, #my_players do
        if winners[i] then return winners end
    end
    return nil
end
---Determines which players hold the best hand against the community cards.
---@param dealercards string[]
---@param my_players PokerChairPlayer[]
---@return table<integer, PokerChairPlayer>|nil
return function (dealercards, my_players)
    local winners
    for i = 1, #tests do
        local test = tests[i]
        winners = winners_helper(dealercards, my_players, test)
        if winners then break end
    end
    return winners
end