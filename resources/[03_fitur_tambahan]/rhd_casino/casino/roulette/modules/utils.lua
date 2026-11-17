local utils = {}

utils.GridNumberMap = {
    2, 19, 21, 23, 35, 37, 39, 51, 53, 55,
    67, 69, 71, 83, 85, 87, 99, 101, 103, 115,
    117, 119, 131, 133, 135, 147, 149, 151, 163, 165,
    167, 179, 181, 183, 195, 197, 199, 4,
}

utils.GridToRouletteMap = {}
for i = 1, #utils.GridNumberMap do
    utils.GridToRouletteMap[utils.GridNumberMap[i]] = i - 1
end

utils.SpecialIndexMap = {
    [0] = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18 },
    [40] = { 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36 },
    [8] = { 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32, 34, 36 },
    [32] = { 1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25, 27, 29, 31, 33, 35 },
    [16] = { 1, 3, 5, 7, 9, 12, 14, 16, 18, 19, 21, 23, 25, 27, 30, 32, 34, 36 },
    [24] = { 2, 4, 6, 8, 10, 11, 13, 15, 17, 20, 22, 24, 26, 28, 29, 31, 33, 35 },

    [1] = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 },
    [9] = { 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24 },
    [17] = { 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36 },

    [203] = { 1, 4, 7, 10, 13, 16, 19, 22, 25, 28, 31, 34 },
    [204] = { 2, 5, 8, 11, 14, 17, 20, 23, 26, 29, 32, 35 },
    [205] = { 3, 6, 9, 12, 15, 18, 21, 24, 27, 30, 33, 36 },

    [10] = { 0, 37, 1, 2, 3 },
    [11] = { 0, 1 },
    [3] = { 0, 37 },
    [12] = { 0, 1, 2 },
    [13] = { 0, 2, 37 },
    [14] = { 2, 3, 37 },
    [15] = { 37, 3 },
}

---@param cellIndex integer
---@return boolean
function utils.IsValidBetCell(cellIndex)
    if type(cellIndex) ~= 'number' then return false end
    if utils.SpecialIndexMap[cellIndex] or utils.GridToRouletteMap[cellIndex] ~= nil then
        return true
    end

    local col = math.floor(cellIndex / 8)
    local row = cellIndex % 8
    return utils.GetBetNumbers(row, col) ~= nil
end

---@param row integer
---@param col integer
---@return integer[]|nil
function utils.GetBetNumbers(row, col)
    if not (row >= 2 and row <= 7 and col >= 2 and col <= 24) then
        return nil
    end

    local halfCol = math.floor(col / 2)
    local isEvenCol = (col % 2 == 0)

    if row == 2 and halfCol >= 1 and halfCol <= 12 then
        if isEvenCol then
            local nums = { halfCol * 3 - 2, halfCol * 3 - 1, halfCol * 3 }
            if nums[1] >= 1 and nums[3] <= 36 then
                return nums
            end
            return nil
        elseif halfCol <= 11 then
            local s1 = halfCol * 3
            local s2 = (halfCol + 1) * 3
            if (s1 - 2) >= 1 and s2 <= 36 then
                return { s1 - 2, s1 - 1, s1, s2 - 2, s2 - 1, s2 }
            end
            return nil
        end
    end

    if (row == 4 or row == 6) and isEvenCol and halfCol >= 1 and halfCol <= 12 then
        local offset = (row == 4) and 2 or 1
        local num = halfCol * 3 - offset
        if num >= 1 and (num + 1) <= 36 then
            return { num, num + 1 }
        end
        return nil
    end

    if (row == 3 or row == 5 or row == 7) and not isEvenCol and col >= 3 and col <= 23 then
        local colGroup = math.floor((col - 1) / 2)
        if colGroup >= 1 and colGroup <= 11 then
            local offset = (row == 3) and 2 or ((row == 5) and 1 or 0)
            local num1 = colGroup * 3 - offset
            local num2 = (colGroup + 1) * 3 - offset
            if num1 >= 1 and num2 <= 36 then
                return { num1, num2 }
            end
            return nil
        end
    end

    if (row == 4 or row == 6) and not isEvenCol and col >= 3 and col <= 23 then
        local colGroup = math.floor((col - 1) / 2)
        if colGroup >= 1 and colGroup <= 11 then
            local offset = (row == 4) and 2 or 1
            local tl = colGroup * 3 - offset
            local tr = tl + 1
            local bl = (colGroup + 1) * 3 - offset
            local br = bl + 1
            if tl >= 1 and br <= 36 then
                return { tl, tr, bl, br }
            end
            return nil
        end
    end

    return nil
end

---@param bets table<integer, number>
---@param winningNumber integer
---@param payoutMultipliers table<integer, number>
---@return number
function utils.CalculateWinnings(bets, winningNumber, payoutMultipliers)
    if not (bets and winningNumber and payoutMultipliers) then
        return 0
    end

    local totalWinnings = 0

    for cellIndex, betAmount in pairs(bets) do
        local col = math.floor(cellIndex / 8)
        local row = cellIndex % 8

        local coveredNumbers = utils.GetBetNumbers(row, col)

        if not coveredNumbers then
            coveredNumbers = utils.SpecialIndexMap[cellIndex]
            if not coveredNumbers then
                local rouletteNum = utils.GridToRouletteMap[cellIndex]
                if rouletteNum then
                    coveredNumbers = { rouletteNum }
                end
            end
        end

        if coveredNumbers then
            local isWinner = false
            for i = 1, #coveredNumbers do
                if coveredNumbers[i] == winningNumber then
                    isWinner = true
                    break
                end
            end

            if isWinner then
                local multiplier = payoutMultipliers[#coveredNumbers]
                if multiplier then
                    totalWinnings = totalWinnings + (betAmount * (multiplier + 1))
                end
            end
        end
    end

    return totalWinnings
end

return utils
