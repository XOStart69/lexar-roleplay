local playerSeats = {}
local playerTableIdx = {}
local tableGameActive = {}
local tablePlayers = {}
local acceptingBets = {}
---Nomor pemenang ronde sebelumnya per meja; klien memakainya supaya fase animasi roda seragam.
local tableLastNumber = {}

---@param _source number
---@return boolean
local function canUse(_source)
    return true
end

local config = require 'casino.roulette.config'
local utils = require 'casino.roulette.modules.utils'

---@param bets table?
---@return table<integer, number>
local function normalizePlayerBets(bets, maxBet)
    local normalized = {}
    local totalBet = 0
    if type(bets) ~= 'table' then return normalized end

    for cellIdx, amount in pairs(bets) do
        cellIdx = tonumber(cellIdx)
        amount = math.floor(tonumber(amount) or 0)
        if cellIdx and amount > 0 and utils.IsValidBetCell(cellIdx) then
            normalized[cellIdx] = (normalized[cellIdx] or 0) + amount
            totalBet = totalBet + amount
        end
    end

    if maxBet and totalBet > maxBet then
        return {}
    end

    return normalized
end

---@param bets table<integer, number>
---@return number
local function getTotalBet(bets)
    local total = 0
    for _, amount in pairs(bets) do
        total = total + amount
    end
    return total
end

---@param source number
---@param betAmount number
---@return boolean
local function canParticipate(source, betAmount)
    local itemCount = ox_inventory:GetItemCount(source, shared.chipItemName)
    if itemCount < betAmount then
        lib.notify(source, {
            id = 'not_enough_items',
            title = 'Roulette',
            description = 'Kamu tidak memiliki cukup uang untuk bermain.',
            type = 'error'
        })
        return false
    end
    return ox_inventory:RemoveItem(source, shared.chipItemName, betAmount) == true
end

---@param source number
---@param winAmount number
---@param bankAmount number?
local function rewardPlayer(source, winAmount, bankAmount)
    return shared.payCasinoChipPrize(source, winAmount, 'roulette', bankAmount)
end

---Registers the player at a table and starts the game loop thread if not already running.
---@param source number
---@param tableIdx integer
local function playerJoinTable(source, tableIdx)
    tablePlayers[tableIdx] = tablePlayers[tableIdx] or {}

    for i = 1, #tablePlayers[tableIdx] do
        if tablePlayers[tableIdx][i] == source then return end
    end

    table.insert(tablePlayers[tableIdx], source)
    BroadcastCasinoPlayers('rhd_casino_roulette:client:greetSpeech', tableIdx, source)

    if tableGameActive[tableIdx] then
        return
    end

    tableGameActive[tableIdx] = true
    CreateThread(function()
        Wait(3000)
        while #tablePlayers[tableIdx] > 0 do
            acceptingBets[tableIdx] = true
            BroadcastCasinoPlayers('rhd_casino_roulette:client:acceptBetsSpeech', tableIdx)
            Wait(10000)
            BroadcastCasinoPlayers('rhd_casino_roulette:client:startWheel', tableIdx, tableLastNumber[tableIdx])
            Wait(15000)

            acceptingBets[tableIdx] = false
            local allPlayerBets = {}
            local validPlayers = {}
            local playerBetTotals = {}
            local playerIdentifiers = {}
            local tableConfig = config.TableType[config.Roulettes[tableIdx].tableType]
            local maxBet = tableConfig and tableConfig.maxBettingAmount

            for i = 1, #tablePlayers[tableIdx] do
                local playerId = tablePlayers[tableIdx][i]
                local playerBets = normalizePlayerBets(
                    lib.callback.await('rhd_casino_roulette:callback:playerInput', playerId),
                    maxBet
                )
                allPlayerBets[playerId] = playerBets
                local totalBet = getTotalBet(playerBets)
                playerBetTotals[playerId] = totalBet
                local identifier = shared.getIdentifier(playerId)
                if identifier and totalBet > 0 and canParticipate(playerId, totalBet) then
                    validPlayers[playerId] = true
                    playerIdentifiers[playerId] = identifier
                else
                    allPlayerBets[playerId] = {}
                end
            end

            local payouts = tableConfig and tableConfig.payoutMultipliers or {
                [1] = 35, [2] = 17, [3] = 11, [4] = 8,
                [5] = 6, [6] = 5, [12] = 2, [18] = 1,
            }

            local winningNumber = math.random(0, 37)
            if not shared.rollDifficulty(config.Difficulty) then
                local losingNumbers = {}
                for n = 0, 37 do
                    local totalWin = 0
                    for playerId, playerBets in pairs(allPlayerBets) do
                        if validPlayers[playerId] then
                            totalWin = totalWin + utils.CalculateWinnings(playerBets, n, payouts)
                        end
                    end
                    if totalWin == 0 then
                        losingNumbers[#losingNumbers + 1] = n
                    end
                end
                if #losingNumbers > 0 then
                    winningNumber = losingNumbers[math.random(1, #losingNumbers)]
                end
            end

            tableLastNumber[tableIdx] = winningNumber

            BroadcastCasinoPlayers('rhd_casino_roulette:client:stopAcceptingBets', tableIdx, winningNumber, allPlayerBets)
            Wait(15000)

            local winners = {}
            for playerId, playerBets in pairs(allPlayerBets) do
                if not validPlayers[playerId] then
                    playerBets = {}
                end
                local winAmount = utils.CalculateWinnings(playerBets, winningNumber, payouts)
                if winAmount > 0 then
                    winners[playerId] = winAmount
                end
                if validPlayers[playerId] then
                    local netLoss = (playerBetTotals[playerId] or 0) - winAmount
                    if netLoss > 0 then
                        shared.depositCasinoLoss(playerId, netLoss, 'roulette')
                    end
                end
            end

            for playerId, winAmount in pairs(winners) do
                local samePlayer = shared.playerExist(playerId)
                    and shared.getIdentifier(playerId) == playerIdentifiers[playerId]

                if samePlayer then
                    local stake = playerBetTotals[playerId] or 0
                    local casinoLiability = math.max(winAmount - stake, 0)
                    rewardPlayer(playerId, winAmount, casinoLiability)
                end
            end
            Wait(5000)
        end
        tableGameActive[tableIdx] = false
    end)
end

lib.callback.register('rhd_casino_roulette:callback:canUse', function(source, tableIdx, chairPos)
    local configTable = config.Roulettes[tableIdx]
    
    if not configTable then
        return false
    end

    if configTable.tableType == 'vip' and not shared.checkVIP(source) then
        return lib.notify(source, {
            title = 'Roulette',
            description = 'Meja ini hanya untuk pemain VIP. Dapatkan VIP untuk bisa bermain di meja ini!',
            type = 'error',
        })
    end

    if playerSeats[source] then
        return false
    end
    if type(tableIdx) ~= 'number' or not config.Roulettes[tableIdx] then
        return false
    end

    local playerCoords = GetEntityCoords(GetPlayerPed(source))
    local roundedPos = vec3(
        math.floor(chairPos.x * 100) / 100,
        math.floor(chairPos.y * 100) / 100,
        math.floor(chairPos.z * 100) / 100
    )
    if #(playerCoords - roundedPos) > 3.0 then
        return false
    end
    if #(roundedPos - config.Roulettes[tableIdx].coords.xyz) > 4.0 then
        return false
    end

    for _, occupiedPos in pairs(playerSeats) do
        if occupiedPos == roundedPos then
            lib.notify(source, {
                id = 'chair_in_use',
                title = 'Roulette',
                description = 'Kursi ini sedang digunakan. Silakan coba yang lain.',
                type = 'error'
            })
            return false
        end
    end

    playerSeats[source] = roundedPos
    playerTableIdx[source] = tableIdx
    playerJoinTable(source, tableIdx)
    return true, acceptingBets[tableIdx] == true
end)

---@param src number
local function removePlayer(src)
    local seatCoords = playerSeats[src]
    local tableIdx = playerTableIdx[src]
    if not seatCoords or not tableIdx then
        return
    end

    playerSeats[src] = nil
    playerTableIdx[src] = nil
    if tablePlayers[tableIdx] then
        for i = 1, #tablePlayers[tableIdx] do
            if tablePlayers[tableIdx][i] == src then
                table.remove(tablePlayers[tableIdx], i)
                break
            end
        end
    end
    BroadcastCasinoPlayers('rhd_casino_roulette:client:leaveSpeech', tableIdx, src)
end

RegisterNetEvent('rhd_casino_roulette:server:leaveTable', function()
    removePlayer(source)
end)

AddEventHandler('playerDropped', function()
    removePlayer(source)
end)

AddEventHandler('rhd_casino:releasePlayer', function(playerId)
    removePlayer(playerId)
end)
