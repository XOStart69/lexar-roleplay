local activePlayers = {}
local playerSessions = {}
local forcedJackpots = {}
local config = require 'casino.slots.config'
local slotsData = require 'casino.slots.data.slots'
---@class SlotSession
---@field totalBet number
---@field totalPayout number
---@field spins number
---@field lossStreak number
---@param coords vector3
---@return string
local function getMachineKey(coords)
    return coords.x .. "_" .. coords.y .. "_" .. coords.z
end

---Lazily initializes and returns the session record for a player at a specific machine.
---@param source number
---@param machineKey string
---@return SlotSession
local function getSession(source, machineKey)
    if not playerSessions[source] then
        playerSessions[source] = {}
    end
    if not playerSessions[source][machineKey] then
        playerSessions[source][machineKey] = {
            totalBet = 0,
            totalPayout = 0,
            spins = 0,
            lossStreak = 0,
        }
    end
    return playerSessions[source][machineKey]
end

local symbolPositions = {
    sevens = { 0, 8 },
    plums = { 1, 9, 12 },
    cherries = { 2, 6, 14 },
    melons = { 3, 10 },
    bells = { 7, 13 },
    jackpot = { 5 },
    diamonds = { 4, 11, 15 },
}

local calculateMultiplier

---@param source number
---@param betAmount number
---@return boolean
local function canSpin(source, betAmount)
    betAmount = math.floor(tonumber(betAmount) or 0)
    if betAmount <= 0 then return false end

    local itemName = shared.chipItemName
    local itemCount = ox_inventory:GetItemCount(source, itemName)
    if itemCount < betAmount then
        lib.notify(source, {
            id = 'not_enough_money',
            title = 'Not Enough Money',
            description = 'You do not have enough money to play this slot machine.',
            type = 'error'
        })
        return false
    else
        return ox_inventory:RemoveItem(source, itemName, betAmount) == true
    end
end

---@param source number
---@param winAmount number
---@param bankAmount number?
local function rewardPlayer(source, winAmount, bankAmount)
    return shared.payCasinoChipPrize(source, winAmount, 'slots', bankAmount)
end

---@param source number
---@return boolean
local function canUse(source)
    return true
end

---@param reelValue number
---@param symbolName string
---@return boolean
local function isSymbol(reelValue, symbolName)
    local positions = symbolPositions[symbolName]
    for i = 1, #positions do
        if math.floor(reelValue) == positions[i] then
            return true
        end
    end
    return false
end

---@param weights number[]
---@return number
local function getJackpotLevel(weights)
    local total = 0
    for i = 1, #weights do total = total + weights[i] end
    local roll = math.random(1, total)
    local cumulative = 0
    for level = 1, #weights do
        cumulative = cumulative + weights[level]
        if roll <= cumulative then
            return level
        end
    end
    return 1
end

---@param value any
---@return boolean?
local function parseBoolean(value)
    if type(value) == 'boolean' then return value end
    if type(value) == 'number' then
        if value == 1 then return true end
        if value == 0 then return false end
    end
    if type(value) ~= 'string' then return nil end

    value = value:lower()
    if value == 'true' or value == '1' or value == 'on' or value == 'yes' then return true end
    if value == 'false' or value == '0' or value == 'off' or value == 'no' then return false end

    return nil
end

---@param model string
---@return number
local function getMaxJackpotMultiplier(model)
    local slotData = slotsData[model]
    local jackpots = slotData and slotData.Multipliers and slotData.Multipliers.jackpot
    if type(jackpots) == 'number' then return jackpots end

    local multiplier = 0
    if type(jackpots) == 'table' then
        for i = 1, #jackpots do
            multiplier = math.max(multiplier, tonumber(jackpots[i]) or 0)
        end
    end

    return multiplier
end

---@param reels number[]
---@return boolean
local function isJackpotReels(reels)
    return math.floor(reels[1] or -1) == 5
        and math.floor(reels[2] or -1) == 5
        and math.floor(reels[3] or -1) == 5
end

---@param model string
---@return number[]
local function generateLosingReels(model)
    for _ = 1, 50 do
        local reels = {
            math.random(0, 15),
            math.random(0, 15),
            math.random(0, 15),
        }
        if calculateMultiplier(reels, model) <= 0 then
            return reels
        end
    end

    return { 0, 1, 2 }
end

---Calculates the win multiplier for a spin based on reel values and machine model.
---Handles jackpot, three-of-a-kind, two-of-a-kind (if enabled), and diamond bonus.
---@param reels number[]
---@param model string
---@return number
function calculateMultiplier(reels, model)
    local slotData = slotsData[model]
    local jackpotCount = 0
    for i = 1, #reels do
        if math.floor(reels[i]) == 5 then
            jackpotCount = jackpotCount + 1
        end
    end
    local multiplier = 0
    if jackpotCount == 3 then
        local level = getJackpotLevel(config.JackpotWeights)
        multiplier = slotData.Multipliers.jackpot[level]
    else
        local allSevens = true
        local allPlums = true
        local allCherries = true
        local allMelons = true
        local allBells = true
        local allDiamonds = true
        for i = 1, #reels do
            local reel = reels[i]
            if not isSymbol(reel, 'sevens') then allSevens = false end
            if not isSymbol(reel, 'plums') then allPlums = false end
            if not isSymbol(reel, 'cherries') then allCherries = false end
            if not isSymbol(reel, 'melons') then allMelons = false end
            if not isSymbol(reel, 'bells') then allBells = false end
            if not isSymbol(reel, 'diamonds') then allDiamonds = false end
        end
        if allSevens then
            multiplier = slotData.Multipliers.threeOfAKind.sevens
        elseif allDiamonds then
            multiplier = slotData.Multipliers.threeOfAKind.diamonds
                or slotData.Multipliers.threeOfAKind.sevens
        elseif allPlums then
            multiplier = slotData.Multipliers.threeOfAKind.plums
        elseif allCherries then
            multiplier = slotData.Multipliers.threeOfAKind.cherries
        elseif allMelons then
            multiplier = slotData.Multipliers.threeOfAKind.melons
        elseif allBells then
            multiplier = slotData.Multipliers.threeOfAKind.bells
        elseif slotData.EnableTwoOfAKind then
            local counts = {
                sevens = 0,
                plums = 0,
                cherries = 0,
                melons = 0,
                bells = 0,
                diamonds = 0,
            }
            for i = 1, #reels do
                local reel = reels[i]
                for name, _ in pairs(counts) do
                    if isSymbol(reel, name) then
                        counts[name] = counts[name] + 1
                    end
                end
            end
            if counts.sevens >= 2 then
                multiplier = math.max(multiplier, slotData.Multipliers.twoOfAKind.sevens)
            end
            if counts.plums >= 2 then
                multiplier = math.max(multiplier, slotData.Multipliers.twoOfAKind.plums)
            end
            if counts.cherries >= 2 then
                multiplier = math.max(multiplier, slotData.Multipliers.twoOfAKind.cherries)
            end
            if counts.melons >= 2 then
                multiplier = math.max(multiplier, slotData.Multipliers.twoOfAKind.melons)
            end
            if counts.bells >= 2 then
                multiplier = math.max(multiplier, slotData.Multipliers.twoOfAKind.bells)
            end
            if counts.diamonds >= 2 then
                multiplier = math.max(
                    multiplier,
                    slotData.Multipliers.twoOfAKind.diamonds
                        or slotData.Multipliers.twoOfAKind.sevens
                )
            end
        end
    end
    local diamondCount = 0
    for i = 1, #reels do
        if isSymbol(reels[i], 'diamonds') then
            diamondCount = diamondCount + 1
        end
    end
    return multiplier + (diamondCount * slotData.Multipliers.diamondBonus)
end

lib.callback.register('rhd_casino_slots:callback:canUse', function(source, coords)
    if not canUse(source) then
        return false
    end
    if activePlayers[source] then
        return false
    end
    local playerPed = GetPlayerPed(source)
    local playerCoords = GetEntityCoords(playerPed)
    local roundedCoords = vec3(
        math.floor(coords.x * 10) / 10,
        math.floor(coords.y * 10) / 10,
        math.floor(coords.z * 10) / 10
    )
    if #(playerCoords - roundedCoords) > 5.5 then
        return false
    end
    for _, machineCoords in pairs(activePlayers) do
        if machineCoords == roundedCoords then
            lib.notify(source, {
                id = 'slot_machine_in_use',
                title = 'Slot Machine in Use',
                description = 'This slot machine is currently in use. Please try another one.',
                type = 'error',
            })
            return false
        end
    end
    activePlayers[source] = roundedCoords
    return true
end)

lib.callback.register('rhd_casino_slots:callback:startSpin', function(source, model, betAmount)
    if not activePlayers[source] then
        return false
    end
    betAmount = math.floor(tonumber(betAmount) or 0)
    local slotData = slotsData[model]
    if not slotData then return false end
    local validBet = false
    for i = 1, #(slotData.BetAmounts or {}) do
        if betAmount == slotData.BetAmounts[i] then
            validBet = true
            break
        end
    end
    if not validBet then return false end

    local cacheCoords = activePlayers[source]
    local playerPed = GetPlayerPed(source)
    local playerCoords = GetEntityCoords(playerPed)
    if #(playerCoords - cacheCoords) > 5.5 then
        activePlayers[source] = nil
        return false
    end
    local playerIdentifier = shared.getIdentifier(source)
    if not playerIdentifier then return false end
    if not canSpin(source, betAmount) then
        return false
    end

    local edge = slotData.HouseEdge
    local machineKey = getMachineKey(cacheCoords)
    local session = getSession(source, machineKey)
    local reels = {
        math.random(0, 15),
        math.random(0, 15),
        math.random(0, 15),
    }
    local forceJackpot = forcedJackpots[source] == true
    if forceJackpot then
        reels = { 5, 5, 5 }
    else
        for i = 1, #reels do
            if math.random(1, 100) <= slotData.MisChance then
                reels[i] = reels[i] + math.random(3, 7) / 10
            end
        end
    end

    local multiplier = forceJackpot and getMaxJackpotMultiplier(model) or calculateMultiplier(reels, model)
    local winAmount = betAmount * multiplier
    local forceWinAnim = false
    local jackpotWin = isJackpotReels(reels)
    local allowWin = forceJackpot or shared.rollDifficulty(config.Difficulty)
    if not allowWin and winAmount > 0 then
        reels = generateLosingReels(model)
        winAmount = 0
        multiplier = 0
        jackpotWin = false
    end
    if forceJackpot then
        forceWinAnim = true
    elseif not edge.enabled then
        local winChance = slotData.WinChance or 100
        if winAmount > 0 and math.random(1, 100) > winChance then
            reels = generateLosingReels(model)
            winAmount = 0
            multiplier = 0
        end
    else
        local currentRTP = session.totalBet > 0 and (session.totalPayout / session.totalBet) or edge.targetRTP
        if currentRTP > edge.targetRTP then
            local overRTP = currentRTP - edge.targetRTP
            if overRTP > 0.15 then
                if not jackpotWin and math.random(1, 100) <= 75 then
                    reels = generateLosingReels(model)
                    winAmount = 0
                    multiplier = 0
                elseif not jackpotWin and winAmount > betAmount * edge.maxWinMultiplier then
                    winAmount = betAmount * edge.maxWinMultiplier
                end
            else
                if not jackpotWin and winAmount > betAmount * edge.maxWinMultiplier then
                    winAmount = betAmount * edge.maxWinMultiplier
                end
            end
        elseif session.lossStreak >= edge.lossStreakLimit and winAmount == 0 and allowWin then
            winAmount = math.floor(betAmount * edge.consolationMultiplier)
            multiplier = 1
            forceWinAnim = true
        end
        session.totalBet = session.totalBet + betAmount
        session.spins = session.spins + 1
        if winAmount > 0 then
            session.totalPayout = session.totalPayout + winAmount
            session.lossStreak = 0
        else
            session.lossStreak = session.lossStreak + 1
        end
    end
    local resultAnim = nil
    if multiplier > 0 or forceWinAnim then
        local winAnims = { 'win_a', 'win_b', 'win_c' }
        resultAnim = winAnims[math.random(1, #winAnims)]
        if multiplier >= config.WinBigAnimation then
            resultAnim = resultAnim:gsub('win_', 'win_big_')
        end
    else
        local loseAnims = { 'lose_a', 'lose_b' }
        resultAnim = loseAnims[math.random(1, #loseAnims)]
        if betAmount >= config.LostCruelAnimation then
            resultAnim = resultAnim:gsub('lose_', 'lose_cruel_')
        end
    end
    BroadcastCasinoPlayers('rhd_casino_slots:client:spinReels', reels, cacheCoords, model, winAmount, resultAnim, betAmount)
    Wait(6000)

    if not shared.playerExist(source) or shared.getIdentifier(source) ~= playerIdentifier then
        return false
    end

    local netLoss = betAmount - winAmount
    if netLoss > 0 then
        shared.depositCasinoLoss(source, netLoss, 'slots')
    end
    if winAmount > 0 then
        local casinoLiability = math.max(winAmount - betAmount, 0)
        rewardPlayer(source, winAmount, casinoLiability)
    end
    return winAmount, resultAnim
end)

---Clears active slot machine occupancy and session data for a player.
---@param source number
local function releaseSlotMachine(source)
    if activePlayers[source] then
        local machineKey = getMachineKey(activePlayers[source])
        if playerSessions[source] then
            playerSessions[source][machineKey] = nil
            if next(playerSessions[source]) == nil then
                playerSessions[source] = nil
            end
        end
        activePlayers[source] = nil
    end
end

RegisterNetEvent('rhd_casino_slots:server:stopSlotMachine', function()
    releaseSlotMachine(source)
end)

AddEventHandler('playerDropped', function()
    forcedJackpots[source] = nil
    releaseSlotMachine(source)
end)

AddEventHandler('rhd_casino:releasePlayer', function(playerId)
    forcedJackpots[playerId] = nil
    releaseSlotMachine(playerId)
end)

lib.addCommand('slotjackpot', {
    help = 'Development: force your slot spins to hit the highest jackpot.',
    params = {
        { name = 'state', type = 'string', help = 'true/false, on/off, 1/0' },
    },
    restricted = 'group.god',
}, function(source, args)
    local state = parseBoolean(args.state)
    if state == nil then
        local message = 'Usage: /slotjackpot true|false'
        if source > 0 then
            return lib.notify(source, { type = 'error', description = message })
        end
        return print(message)
    end

    forcedJackpots[source] = state or nil
    local message = ('Slot jackpot development mode: %s'):format(state and 'enabled' or 'disabled')
    if source > 0 then
        lib.notify(source, { type = 'success', description = message })
    else
        print(message)
    end
end)
