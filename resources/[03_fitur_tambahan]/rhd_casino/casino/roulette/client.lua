local tableProps = {}
local dealerPeds = {}
local gridMarkers = {}
local ballEntities = {}
local wheelBoneRotations = {}
local currentTableIndex = 0
local tableEntity = 0
local seatPosition = vec3(0, 0, 0)
local seatRotation = vec3(0, 0, 0)
local wheelCamera = 0
local tableCamera = 0
local chipCursorEntity = 0
local playerChips = {}
local wheelSlotIndices = {}
local ballSoundIds = {}
local playerSeatNumber = 0
local hoveredCell = 0
local canPlaceBets = true
local selectedBetAmount = 0
local availableBetAmounts = {}
local betAmountIndex = 1
local totalBetAmount = 0
local cellBets = {}
local submittedCellBets = {}
local maxBetAmount = 0
local otherPlayerChipObjects = {}
local otherPlayerBetTotals = {}
local highlightedNumbers = {}
local prevHighlightedNumbers = {}
local dealerIdling = {}
local forceLeaveTable = false
local ROULETTE_TABLE_DICT <const> = 'anim_casino_b@amb@casino@games@roulette@table'
local PLAYER_SHARED_DICT <const> = 'anim_casino_b@amb@casino@games@shared@player@'
local CHIP_BASE_OFFSET <const> = vec3(-0.097, -0.42, 0.947)
local TABLE_COLOUR_MAP = {
    green = 0,
    red = 1,
    blue = 2,
    purple = 3,
}
local CHIP_MODELS = {
    [10] = 'vw_prop_chip_10dollar_x1',
    [50] = 'vw_prop_chip_50dollar_x1',
    [100] = 'vw_prop_chip_100dollar_x1',
    [500] = 'vw_prop_chip_500dollar_x1',
    [1000] = 'vw_prop_chip_1kdollar_x1',
    [5000] = 'vw_prop_chip_5kdollar_x1',
    [10000] = 'vw_prop_chip_10kdollar_x1',
}
local tableModels = {
    'vw_prop_casino_roulette_01',
    'vw_prop_casino_roulette_01b'
}
local rouletteTablesLoaded = false
local rouletteTablesLoading = false
local BALL_ANIM_OFFSETS = (function()
    local pattern = {
        0.32235476374626, 0.34061053395271, 0.32698601484299,
        0.53701442480087, 0.71876162290573, 0.31776028871536,
        0.5192134976387,  0.53069269657135, 0.33149981498718,
    }
    local t = {}
    for i = 1, 38 do
        t[i] = pattern[((i - 1) % 9) + 1]
    end
    return t
end)()
local ROULETTE_TO_SLOT = {
    [0] = 20, [28] = 21, [9] = 22,  [26] = 23, [30] = 24,
    [11] = 25, [7] = 26, [20] = 27, [32] = 28, [17] = 29,
    [5] = 30, [22] = 31, [34] = 32, [15] = 33, [3] = 34,
    [24] = 35, [36] = 36, [13] = 37, [1] = 38,
    [37] = 1,  [27] = 2,  [10] = 3,  [25] = 4,  [29] = 5,
    [12] = 6,  [8] = 7,   [19] = 8,  [31] = 9,  [18] = 10,
    [6] = 11,  [21] = 12, [33] = 13, [16] = 14, [4] = 15,
    [23] = 16, [35] = 17, [14] = 18, [2] = 19,
}
local SET_TEXTURE_VARIATION = 0x71CB7F90BBE0D684
local config = require 'casino.roulette.config'
local spawnDealer = require 'modules.dealers'
local utils = require 'casino.roulette.modules.utils'
local INFO_ID = 'roulette_info'
local infoActive = false
local infoLastKey

local function isControlPressed(control)
    return IsControlPressed(0, control) or IsDisabledControlPressed(0, control)
end

local function isControlJustReleased(control)
    return IsControlJustReleased(0, control) or IsDisabledControlJustReleased(0, control)
end

local function buildBetAmounts(tableConfig)
    local amounts = tableConfig.bettingAmmounts or tableConfig.bettingAmounts or {}
    local maxBet = tableConfig.maxBettingAmount or math.huge
    local values = {}

    for i = 1, #amounts do
        local value = tonumber(amounts[i])
        if value and value > 0 and value <= maxBet then
            values[#values + 1] = math.floor(value)
        end
    end

    table.sort(values)
    return values
end

---@param key string
---@param title string
---@param description string
local function showInfo(key, title, description)
    if infoActive and infoLastKey == key then return end
    infoLastKey = key
    infoActive = true
    infoUI:show({
        id = INFO_ID,
        title = title,
        icon = 'fa-solid fa-circle-dot',
        description = description
    })
end
local function hideInfo()
    if not infoActive then return end
    infoActive = false
    infoLastKey = nil
    infoUI:remove(INFO_ID)
end

local function infoEnter()
    showInfo('enter', 'Roulette', '[kbd]E[/kbd] Take a seat')
end

local function infoNormal()
    showInfo('normal', 'Roulette',
        '[kbd]R[/kbd] Wheel Focus\n[kbd]F[/kbd] Table Focus\n[kbd]Backspace[/kbd] Leave')
end

local function infoBetting()
    local key = ('bet:%s:%s:%s'):format(selectedBetAmount, totalBetAmount, cellBets[hoveredCell] or 0)
    showInfo(key, 'Roulette',
        ('[kbd]\u{2191}[/kbd] Bet Up\n[kbd]\u{2193}[/kbd] Bet Down\n[kbd]LMB[/kbd] Place Bet\n[kbd]RMB[/kbd] Remove Bet\n\nBet Amount: $%s\nTotal Placed: $%s\nAt This Location: $%s')
            :format(selectedBetAmount, totalBetAmount, cellBets[hoveredCell] or 0))
end

---@param tableIdx integer?
---@return integer
local function getTableColourIndex(tableIdx)
    local roulette = config.Roulettes[tableIdx or currentTableIndex]
    local tableConfig = config.TableType[roulette.tableType]
    return TABLE_COLOUR_MAP[tableConfig.tableColour] or 0
end

---@param v vector3
---@param angleDeg number
---@return vector3
local function rotateVec3(v, angleDeg)
    local rad = math.rad(angleDeg)
    local sinA = math.sin(rad)
    local cosA = math.cos(rad)
    return vec3(
        v.x * cosA - v.y * sinA,
        v.x * sinA + v.y * cosA,
        v.z
    )
end

---@param cellIndex integer
---@return string
local function getMarkerModel(cellIndex)
    local row = cellIndex % 8
    local col = math.floor(cellIndex / 8)
    if col == 0 and row >= 2 then
        return 'vw_prop_vw_marker_01a'
    end
    return 'vw_prop_vw_marker_02a'
end

---@param row integer
---@param col integer
---@return number
local function getCellWidth(row, col)
    if col == 0 and row >= 2 then return 0.1245195 end
    if row == 0 or row == 1 then return 0.074 end
    return 0.083013
end

---@param row integer
---@param col integer
---@return number
local function getCellHeight(row, col)
    if col == 0 and row >= 2 and row ~= 3 then return 0.1 end
    if col == 0 and row == 3 then return 0.081287 end
    if row == 0 then return 0.162574 end
    if row == 1 then return 0.325148 end
    return 0.081287
end

---@param entity integer
---@param tableIdx integer?
local function setTextureVariation(entity, tableIdx)
    local colorIndex = getTableColourIndex(tableIdx)
    Citizen.InvokeNative(SET_TEXTURE_VARIATION, entity, colorIndex)
end

---@param cellIndex integer
---@param tableIdx integer?
---@return vector3
local function getGridWorldPos(cellIndex, tableIdx)
    local row = cellIndex % 8
    local col = math.floor(cellIndex / 8)
    local localPos
    if row >= 2 then
        local cellW = getCellWidth(row, col)
        local cellH = getCellHeight(row, col)
        local x = (row - 2) * cellW + 0.148
        local y = col * cellH * 0.5
        if col ~= 25 then
            y = y - cellH * 0.5
            if col == 0 then
                x = x + cellW
                y = -0.04
                if row == 4 then
                    x = x + 0.004
                end
            end
        else
            x = x + cellW * (row - 3)
        end
        localPos = vec3(y, x, 0.0)
    else
        local cellW = getCellWidth(row, col)
        local cellH = getCellHeight(row, col)
        local x = row * cellW + cellW * 0.5
        local y = col * cellH + cellH * 0.5
        localPos = vec3(y, x, 0.0)
    end
    local idx = tableIdx or currentTableIndex
    local heading = config.Roulettes[idx].coords.w
    local baseWorld = rotateVec3(CHIP_BASE_OFFSET, heading) + config.Roulettes[idx].coords.xyz
    local offset = rotateVec3(localPos, heading)
    return baseWorld + offset
end

---@param inputPos vector3
---@return integer row, integer col
local function screenToGridCell(inputPos)
    local pos = vec3(inputPos.y, inputPos.x, inputPos.z)
    local gridStartX = 0.148
    local gridEndY = 1.056731
    local gridMinY = -0.1
    local gridMaxX = gridStartX + 0.498078
    if pos.x < 0.0 or pos.x > gridMaxX or pos.y > gridEndY or pos.y < gridMinY then
        return -1, -1
    end
    local row, col
    if pos.x < 0.074 then
        local cellH = 0.162574
        row = 0
        col = math.floor((pos.y - cellH * 0.5) / cellH + 0.5)
    elseif pos.x < gridStartX then
        local cellH = 0.325148
        row = 1
        col = math.floor((pos.y - cellH * 0.5) / cellH + 0.5)
    else
        local rawX = (pos.x - 0.0415065 + gridStartX) / 0.083013 - gridStartX
        col = math.floor(pos.y / 0.0406435 + 0.5) + 1
        row = math.min(math.floor(rawX + 0.5) - 1, 7)
        if pos.y < -0.02032175 then
            col = 0
            row = 2
            local gap = 0.06641040000000001
            if pos.x > gridStartX + 0.249039 + gap then
                row = 4
            elseif pos.x > gridStartX + 0.166026 + gap then
                row = 3
            end
        elseif pos.y >= 0.975444 then
            col = 25
            if pos.x > gridStartX + 0.332052 then
                row = 5
            elseif pos.x > gridStartX + 0.166026 then
                row = 4
            else
                row = 3
            end
        elseif pos.y >= 0.9348004999999999 then
            col = 24
        end
    end
    if row < 0 or row > 7 or col < 0 or col > 25 then
        return -1, -1
    end
    return row, col
end

local function playSitEnterAnimation()
    local playerPos = GetEntityCoords(cache.ped)
    local diff = { x = playerPos.x - seatPosition.x, y = playerPos.y - seatPosition.y }
    local distance = math.sqrt(diff.x * diff.x + diff.y * diff.y)
    local angle = math.rad(seatRotation.z)
    local forward = { x = math.sin(angle), y = -math.cos(angle) }
    local dot = diff.x * forward.x + diff.y * forward.y
    local leftAnims = { 'sit_enter_left', 'sit_enter_left_side' }
    local rightAnims = { 'sit_enter_right', 'sit_enter_right_side' }
    local anims = (dot < 0) and leftAnims or rightAnims
    local animName = (distance < 0.9) and anims[2] or anims[1]
    local scene = NetworkCreateSynchronisedScene(
        seatPosition.x, seatPosition.y, seatPosition.z,
        seatRotation.x, seatRotation.y, seatRotation.z,
        2, true, false, 1.0, 0.0, 1.0
    )
    NetworkAddPedToSynchronisedScene(cache.ped, scene, PLAYER_SHARED_DICT, animName, 2.0, -2.0, 13, 16, 2.0, 0)
    NetworkStartSynchronisedScene(scene)
    while true do
        if HasAnimEventFired(cache.ped, -1424880317) then break end
        SetTableGamesCameraThisUpdate('CASINO_ROULETTE_CAMERA')
        Wait(0)
    end
end

local function playSitExitAnimation()
    local exitAnims = { 'sit_exit_left', 'sit_exit_right' }
    local animName = exitAnims[math.random(1, #exitAnims)]
    if not lib.requestAnimDict(PLAYER_SHARED_DICT, 1500) then
        ClearPedTasks(cache.ped)
        return
    end
    local scene = NetworkCreateSynchronisedScene(
        seatPosition.x, seatPosition.y, seatPosition.z,
        seatRotation.x, seatRotation.y, seatRotation.z,
        2, false, false, 1.0, 0.0, 1.0
    )
    NetworkAddPedToSynchronisedScene(cache.ped, scene, PLAYER_SHARED_DICT, animName, 2.0, -2.0, 13, 16, 2.0, 0)
    NetworkStartSynchronisedScene(scene)
    local timeout = GetGameTimer() + 3000
    while GetGameTimer() < timeout do
        if HasAnimEventFired(cache.ped, -1424880317) then break end
        Wait(0)
    end
    NetworkStopSynchronisedScene(scene)
    ClearPedTasks(cache.ped)
end

local function playRandomIdleAnimation()
    if shared.activeSeat ~= 'roulette' or currentTableIndex == 0 then return end
    local isMale = IsPedMale(cache.ped)
    local idleAnims = isMale
        and { 'idle_var_01', 'idle_var_02', 'idle_var_03', 'idle_var_04' }
        or { 'female_idle_var_01', 'female_idle_var_02', 'female_idle_var_03', 'female_idle_var_04' }
    local animName = idleAnims[math.random(1, #idleAnims)]
    local scene = NetworkCreateSynchronisedScene(
        seatPosition.x, seatPosition.y, seatPosition.z,
        seatRotation.x, seatRotation.y, seatRotation.z,
        2, false, true, 1.0, 0.0, 1.0
    )
    NetworkAddPedToSynchronisedScene(cache.ped, scene, PLAYER_SHARED_DICT, animName, 2.0, -2.0, 13, 16, 2.0, 0)
    NetworkStartSynchronisedScene(scene)
end

local function setupCameras()
    local coords = config.Roulettes[currentTableIndex].coords
    wheelCamera = CreateCameraWithParams('DEFAULT_SCRIPTED_CAMERA', coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 65.0, false, 2)
    AttachCamToEntity(wheelCamera, tableEntity, -0.2713, -0.2519, 1.6719, true)
    PointCamAtEntity(wheelCamera, tableEntity, -1.7807, 0.3194, -0.8033, true)
    SetCamFov(wheelCamera, 50.0)
    tableCamera = CreateCameraWithParams('DEFAULT_SCRIPTED_CAMERA', coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 65.0, false, 2)
    AttachCamToEntity(tableCamera, tableEntity, 0.068, -0.2737, 3.1523, true)
    PointCamAtEntity(tableCamera, tableEntity, 0.0677, -0.0155, 0.1634, true)
    SetCamFov(tableCamera, 41.1502)
end

local function createGridMarkers()
    lib.requestModel('vw_prop_chip_10dollar_x1')
    chipCursorEntity = CreateObject('vw_prop_chip_10dollar_x1',
        config.Roulettes[currentTableIndex].coords.x,
        config.Roulettes[currentTableIndex].coords.y,
        config.Roulettes[currentTableIndex].coords.z,
        false, false, false
    )
    SetModelAsNoLongerNeeded('vw_prop_chip_10dollar_x1')
    SetEntityCollision(chipCursorEntity, false, false)
    SetEntityVisible(chipCursorEntity, false, false)
    setTextureVariation(chipCursorEntity)
    lib.requestModel('vw_prop_vw_marker_01a')
    lib.requestModel('vw_prop_vw_marker_02a')
    for i = 0, 37 do
        local cellId = utils.GridNumberMap[i + 1]
        local model = getMarkerModel(cellId)
        local worldPos = getGridWorldPos(cellId)
        local heading = config.Roulettes[currentTableIndex].coords.w
        gridMarkers[i] = CreateObject(model, worldPos.x, worldPos.y, worldPos.z, false, false, false)
        SetEntityRotation(gridMarkers[i], 0.0, 90.0, 90.0, 2, true)
        SetEntityCoordsNoOffset(gridMarkers[i], worldPos.x, worldPos.y, worldPos.z, false, false, true)
        SetEntityHeading(gridMarkers[i], heading)
        SetEntityDynamic(gridMarkers[i], false)
        SetEntityHasGravity(gridMarkers[i], false)
        SetEntityCompletelyDisableCollision(gridMarkers[i], false, false)
        SetEntityAlpha(gridMarkers[i], 200, true)
        SetEntityVisible(gridMarkers[i], false, false)
        setTextureVariation(gridMarkers[i])
    end
    SetModelAsNoLongerNeeded('vw_prop_vw_marker_01a')
    SetModelAsNoLongerNeeded('vw_prop_vw_marker_02a')
end

---@param amount number
---@param worldPos vector3
---@param tableIdx integer?
---@return integer[]
local function createChipStack(amount, worldPos, tableIdx)
    local chips = {}
    local remaining = amount
    while remaining > 0 do
        local chipValue = 10
        for value, _ in pairs(CHIP_MODELS) do
            if value > chipValue and remaining >= value then
                chipValue = value
            end
        end
        local chip = CreateObject(CHIP_MODELS[chipValue],
            worldPos.x + (math.random() - 0.5) * 0.005,
            worldPos.y + (math.random() - 0.5) * 0.005,
            worldPos.z + 0.005 * #chips,
            false, false, false
        )
        SetEntityCollision(chip, false, false)
        setTextureVariation(chip, tableIdx)
        chips[#chips + 1] = chip
        remaining = remaining - chipValue
    end
    return chips
end

local function updateMyChipDisplay()
    local amount = cellBets[hoveredCell] or 0
    playerChips[hoveredCell] = playerChips[hoveredCell] or {}
    for i = 1, #(playerChips[hoveredCell]) do
        DeleteObject(playerChips[hoveredCell][i])
    end
    playerChips[hoveredCell] = {}
    if amount > 0 then
        local worldPos = getGridWorldPos(hoveredCell)
        playerChips[hoveredCell] = createChipStack(amount, worldPos)
    end
end

---@param tableIdx integer
---@param newBets? table<integer, table>
local function updateOtherPlayerChips(tableIdx, newBets)
    if newBets then
        otherPlayerBetTotals[tableIdx] = otherPlayerBetTotals[tableIdx] or {}
        for _, playerBet in pairs(newBets) do
            for cellIdx, amount in pairs(playerBet) do
                otherPlayerBetTotals[tableIdx][cellIdx] = (otherPlayerBetTotals[tableIdx][cellIdx] or 0) + amount
            end
        end
        otherPlayerChipObjects[tableIdx] = otherPlayerChipObjects[tableIdx] or {}
        for cellIdx, totalAmount in pairs(otherPlayerBetTotals[tableIdx]) do
            otherPlayerChipObjects[tableIdx][cellIdx] = otherPlayerChipObjects[tableIdx][cellIdx] or {}
            local worldPos = getGridWorldPos(cellIdx, tableIdx)
            local remaining = totalAmount
            while remaining > 0 do
                local chipValue = 10
                for value, _ in pairs(CHIP_MODELS) do
                    if value > chipValue and remaining >= value then
                        chipValue = value
                    end
                end
                local chip = CreateObject(CHIP_MODELS[chipValue],
                    worldPos.x + (math.random() - 0.5) * 0.005,
                    worldPos.y + (math.random() - 0.5) * 0.005,
                    worldPos.z + 0.005 * #otherPlayerChipObjects[tableIdx][cellIdx],
                    false, false, false
                )
                SetEntityCollision(chip, false, false)
                setTextureVariation(chip, tableIdx)
                local arr = otherPlayerChipObjects[tableIdx][cellIdx]
                arr[#arr + 1] = chip
                remaining = remaining - chipValue
            end
        end
    else
        for cellIdx, chips in pairs(otherPlayerChipObjects[tableIdx]) do
            for i = 1, #chips do
                DeleteObject(chips[i])
            end
            otherPlayerChipObjects[tableIdx][cellIdx] = {}
        end
        otherPlayerBetTotals[tableIdx] = {}
    end
end

---@param entity integer
local function animateChipFade(entity)
    CreateThread(function()
        local alpha = 255
        while alpha > 0 do
            alpha = alpha - 5
            SetEntityAlpha(entity, math.max(alpha, 0), false)
            Wait(15)
        end
        while alpha < 255 do
            alpha = alpha + 15
            SetEntityAlpha(entity, math.min(alpha, 255), false)
            Wait(10)
        end
        while alpha > 0 do
            alpha = alpha - 10
            SetEntityAlpha(entity, math.max(alpha, 0), false)
            Wait(7)
        end
        while alpha < 255 do
            alpha = alpha + 25
            SetEntityAlpha(entity, math.min(alpha, 255), false)
            Wait(5)
        end
        while alpha > 0 do
            alpha = alpha - 25
            SetEntityAlpha(entity, math.max(alpha, 0), false)
            Wait(3)
        end
    end)
end

local function handleBettingInput()
    local cursorX = GetControlNormal(2, 239)
    local cursorY = 1.0 - GetControlNormal(2, 240)
    local heading = config.Roulettes[currentTableIndex].coords.w
    local cursorLocal = vec3(
        cursorX * 1.23 + (-0.14),
        cursorY * 0.7 + (-0.03),
        0.0
    )
    local cursorWorld = rotateVec3(cursorLocal, heading)
    local baseWorld = rotateVec3(CHIP_BASE_OFFSET, heading) + config.Roulettes[currentTableIndex].coords.xyz
    local chipPos = vec3(baseWorld.x + cursorWorld.x, baseWorld.y + cursorWorld.y, baseWorld.z + cursorWorld.z)
    SetEntityCoords(chipCursorEntity, chipPos.x, chipPos.y, chipPos.z, false, false, false, false)
    local gridLocal = rotateVec3(cursorWorld, -heading)
    local gridRow, gridCol = screenToGridCell(gridLocal)
    local cellIndex = gridCol * 8 + gridRow
    if cellIndex ~= hoveredCell then
        hoveredCell = cellIndex
        local betNums = utils.GetBetNumbers(gridRow, gridCol)
        infoBetting()
        if betNums then
            highlightedNumbers = betNums
        else
            local rouletteNum = utils.GridToRouletteMap[cellIndex]
            if rouletteNum then
                highlightedNumbers = { rouletteNum }
            else
                local special = utils.SpecialIndexMap[cellIndex]
                if special then
                    highlightedNumbers = special
                elseif cellIndex == -9 then
                    highlightedNumbers = {}
                end
            end
        end
    end
    if isControlJustReleased(config.Controls.bet.place) then
        if canPlaceBets then
            local newTotal = totalBetAmount + selectedBetAmount
            local itemCount = ox_inventory:GetItemCount(shared.chipItemName)
            if newTotal > maxBetAmount then
                lib.notify({
                    id = 'roulette_max_exceeded',
                    title = 'Roulette',
                    description = ('You cannot place a bet exceeding the maximum allowed amount of $%s. (Already put down $%s)')
                        :format(maxBetAmount, totalBetAmount),
                    type = 'error'
                })
                if not IsAmbientSpeechPlaying(dealerPeds[currentTableIndex]) then
                    PlayPedAmbientSpeechNative(dealerPeds[currentTableIndex], 'MINIGAME_DEALER_REFUSE_BETS', 'SPEECH_PARAMS_STANDARD')
                end
                PlaySoundFrontend(-1, 'DLC_VW_BET_MAX', 'dlc_vw_table_games_frontend_sounds', false)
            elseif newTotal > itemCount then
                lib.notify({
                    id = 'not_enough_items',
                    title = 'Roulette',
                    description = 'You do not have enough money to play.',
                    type = 'error'
                })
                PlaySoundFrontend(-1, 'DLC_VW_ERROR_MAX', 'dlc_vw_table_games_frontend_sounds', false)
            else
                totalBetAmount = newTotal
                cellBets[hoveredCell] = (cellBets[hoveredCell] or 0) + selectedBetAmount
                PlaySoundFrontend(-1, 'DLC_VW_BET_HIGHLIGHT', 'dlc_vw_table_games_frontend_sounds', false)
                updateMyChipDisplay()
            end
            infoBetting()
        end
    end
    if isControlJustReleased(config.Controls.bet.place) and not canPlaceBets then
        PlaySoundFrontend(-1, 'DLC_VW_ERROR_MAX', 'dlc_vw_table_games_frontend_sounds', false)
    end
    if isControlJustReleased(config.Controls.bet.remove) and canPlaceBets then
        local currentCellBet = cellBets[hoveredCell] or 0
        local remaining = currentCellBet - selectedBetAmount
        if remaining < 0 then
            totalBetAmount = totalBetAmount - (cellBets[hoveredCell] or 0)
            cellBets[hoveredCell] = 0
        else
            totalBetAmount = totalBetAmount - selectedBetAmount
            cellBets[hoveredCell] = remaining
        end
        updateMyChipDisplay()
        PlaySoundFrontend(-1, 'DLC_VW_REMOVE_BET', 'dlc_vw_table_games_frontend_sounds', false)
        infoBetting()
    end
    if highlightedNumbers ~= prevHighlightedNumbers then
        prevHighlightedNumbers = highlightedNumbers
        for i = 0, 37 do
            SetEntityVisible(gridMarkers[i], false, false)
        end
        for i = 1, #highlightedNumbers do
            SetEntityVisible(gridMarkers[highlightedNumbers[i]], true, false)
        end
    end
end

---@return vector3 seatIndex
---@return vector3 seatPosition
local function findClosestSeat()
    local playerPos = GetEntityCoords(cache.ped)
    local closestDist = math.huge
    local closestPos = vec3(0, 0, 0)
    local closestRot = vec3(0, 0, 0)
    local closestSeat = 1
    for i = 1, 4 do
        local boneIdx = GetEntityBoneIndexByName(tableEntity, string.format('Chair_Base_0%s', i))
        local bonePos = GetEntityBonePosition_2(tableEntity, boneIdx)
        local boneRot = GetEntityBoneRotation(tableEntity, boneIdx)
        local dist = #(playerPos - bonePos)
        if closestDist > dist then
            closestDist = dist
            closestPos = bonePos
            closestRot = boneRot
            closestSeat = i
        end
    end
    playerSeatNumber = closestSeat
    return closestPos, closestRot
end

local function startPlaying()
    forceLeaveTable = false
    lib.requestAnimDict(PLAYER_SHARED_DICT)
    for _, model in pairs(CHIP_MODELS) do
        lib.requestModel(model)
    end
    AddEntityToAudioMixGroup(dealerPeds[currentTableIndex], 'DLC_VW_Casino_Table_Games_Dealer_Group', 0.0)
    StartAudioScene('DLC_VW_Casino_Table_Games')
    setupCameras()
    createGridMarkers()
    local tableConfig = config.TableType[config.Roulettes[currentTableIndex].tableType]
    availableBetAmounts = buildBetAmounts(tableConfig)
    if #availableBetAmounts == 0 then
        lib.notify({
            id = 'roulette_invalid_bets',
            title = 'Roulette',
            description = 'No valid betting amount configured for this table.',
            type = 'error'
        })
        return
    end
    betAmountIndex = 1
    selectedBetAmount = availableBetAmounts[betAmountIndex]
    maxBetAmount = tableConfig.maxBettingAmount
    totalBetAmount = 0
    cellBets = {}
    submittedCellBets = {}
    playerChips = {}
    shared.activeSeat = 'roulette'
    infoNormal()
    playSitEnterAnimation()
    playRandomIdleAnimation()
    while not forceLeaveTable do
        if isControlJustReleased(config.Controls.play.leave) then
            TriggerServerEvent('rhd_casino_roulette:server:leaveTable', currentTableIndex)
            break
        end
        if isControlPressed(config.Controls.camera.wheel) then
            SetCamFov(wheelCamera, math.max(GetCamFov(wheelCamera) - 0.01, 40.0))
            if not IsCamActive(wheelCamera) then
                SetCamActive(tableCamera, false)
                SetCamActive(wheelCamera, true)
                RenderScriptCams(true, false, 0, false, false)
            end
        elseif isControlPressed(config.Controls.camera.table) then
            handleBettingInput()
            if not IsCamActive(tableCamera) then
                infoBetting()
                SetCamActive(wheelCamera, false)
                SetCamActive(tableCamera, true)
                RenderScriptCams(true, false, 0, false, false)
            end
            if not IsEntityVisible(chipCursorEntity) then
                SetEntityVisible(chipCursorEntity, true, false)
            end
            if isControlJustReleased(config.Controls.bet.increase) and #availableBetAmounts > 1 then
                betAmountIndex = betAmountIndex + 1
                if betAmountIndex > #availableBetAmounts then betAmountIndex = 1 end
                selectedBetAmount = availableBetAmounts[betAmountIndex]
                PlaySoundFrontend(-1, 'DLC_VW_BET_UP', 'dlc_vw_table_games_frontend_sounds', false)
                infoBetting()
            end
            if isControlJustReleased(config.Controls.bet.decrease) and #availableBetAmounts > 1 then
                betAmountIndex = betAmountIndex - 1
                if betAmountIndex < 1 then betAmountIndex = #availableBetAmounts end
                selectedBetAmount = availableBetAmounts[betAmountIndex]
                PlaySoundFrontend(-1, 'DLC_VW_BET_DOWN', 'dlc_vw_table_games_frontend_sounds', false)
                infoBetting()
            end
        else
            if IsCamActive(wheelCamera) or IsCamActive(tableCamera) then
                infoNormal()
                SetEntityVisible(chipCursorEntity, false, false)
                SetCamActive(wheelCamera, false)
                SetCamActive(tableCamera, false)
                SetCamFov(wheelCamera, 50.0)
                RenderScriptCams(false, false, 0, false, false)
                for i = 0, 37 do
                    if gridMarkers[i] then
                        SetEntityVisible(gridMarkers[i], false, false)
                    end
                end
                prevHighlightedNumbers = {}
            end
        end
        SetTableGamesCameraThisUpdate('CASINO_ROULETTE_CAMERA')
        Wait(0)
    end
    hideInfo()
    DeleteEntity(chipCursorEntity)
    for i = 0, 37 do
        if gridMarkers[i] then
            DeleteObject(gridMarkers[i])
        end
    end
    for _, chips in pairs(playerChips) do
        for i = 1, #chips do
            DeleteObject(chips[i])
        end
    end
    DestroyCam(wheelCamera, false)
    DestroyCam(tableCamera, false)
    StopAudioScene('DLC_VW_Casino_Table_Games')
    if dealerPeds[currentTableIndex] then
        RemoveEntityFromAudioMixGroup(dealerPeds[currentTableIndex], 2000.0)
    end
    currentTableIndex = 0
    shared.activeSeat = 'none'
    for _, model in pairs(CHIP_MODELS) do
        SetModelAsNoLongerNeeded(model)
    end
    if not IsEntityDead(cache.ped) then
        playSitExitAnimation()
    else
        ClearPedTasksImmediately(cache.ped)
    end
    RemoveAnimDict(PLAYER_SHARED_DICT)
end

AddEventHandler('rhd_casino:client:forceLeave', function()
    if shared.activeSeat ~= 'roulette' then return end
    forceLeaveTable = true
end)

---@param tableIdx integer
---@param dealerPos vector3
local function startDealerIdleLoop(tableIdx, dealerPos)
    CreateThread(function()
        dealerIdling[tableIdx] = true
        local dealer = dealerPeds[tableIdx]
        local isMale = IsPedMale(dealer)
        local animDict = isMale
            and 'anim_casino_b@amb@casino@games@roulette@dealer'
            or 'anim_casino_b@amb@casino@games@roulette@dealer_female'
        local idleAnims = {
            'empty_table_idle_var01', 'empty_table_idle_var02',
            'idle', 'idle_var01', 'idle_var02',
            'idle_var03', 'idle_var04', 'idle_var05',
        }
        local heading = GetEntityHeading(dealer)
        while DoesEntityExist(dealer) do
            if dealerIdling[tableIdx] then
                local anim = idleAnims[math.random(#idleAnims)]
                TaskPlayAnimAdvanced(dealer, animDict, anim,
                    dealerPos.x, dealerPos.y, dealerPos.z,
                    0.0, 0.0, heading, 8.0, -8.0, -1, 2, 0.0, false, false
                )
                Wait(GetAnimDuration(animDict, anim) * 1000)
            end
            Wait(50)
        end
    end)
end

local function loadRouletteTables()
    if rouletteTablesLoaded or rouletteTablesLoading then return end
    rouletteTablesLoading = true

    for i = 1, #config.Roulettes do
        local roulette = config.Roulettes[i]
        if not tableProps[i] then
            local tableConfig = config.TableType[roulette.tableType]
            local model = tableConfig.whiteChairs and tableModels[1] or tableModels[2]
            lib.requestModel(model)
            tableProps[i] = CreateObject(model, roulette.coords.x, roulette.coords.y, roulette.coords.z, false, false, false)
            SetEntityHeading(tableProps[i], roulette.coords.w)
            setTextureVariation(tableProps[i], i)
            SetCanClimbOnEntity(tableProps[i], false)
            SetModelAsNoLongerNeeded(model)
            
            lib.requestModel('vw_prop_roulette_ball')
            local wheelBone = GetEntityBoneIndexByName(tableProps[i], 'Roulette_Wheel')
            local wheelPos = GetEntityBonePosition_2(tableProps[i], wheelBone)
            local wheelRot = GetEntityBoneRotation(tableProps[i], wheelBone)
            wheelBoneRotations[i] = wheelRot
            wheelSlotIndices[i] = 1
            lib.requestAnimDict(ROULETTE_TABLE_DICT)
            PlayEntityAnim(tableProps[i], 'exit_1_wheel', ROULETTE_TABLE_DICT, 1000.0, false, true, false, 0.99, 0)
            ballEntities[i] = CreateObject('vw_prop_roulette_ball', wheelPos.x, wheelPos.y, wheelPos.z, false, false, false)
            FreezeEntityPosition(ballEntities[i], true)
            SetEntityCollision(ballEntities[i], false, false)
            SetEntityVisible(ballEntities[i], false, false)
            SetEntityRotation(ballEntities[i], wheelRot.x, wheelRot.y, wheelRot.z, 2, false)
            SetEntityCoordsNoOffset(ballEntities[i], wheelPos.x, wheelPos.y, wheelPos.z, false, false, false)
            local outfitPool = tableConfig.dealerOutfit
            local outfit = outfitPool[math.random(1, #outfitPool)]
            dealerPeds[i] = spawnDealer[outfit](vector4(roulette.coords.x, roulette.coords.y, roulette.coords.z, roulette.coords.w + 180))
            Wait(0)
            local dealerPos = vec3(0.0, 0.0, 0.0)
            local dealerOffset = IsPedMale(dealerPeds[i])
                and vec3(-0.09, 0.7, 1.0)
                or vec3(-0.04, 0.7, 1.0)
            dealerPos = vec3(roulette.coords.x, roulette.coords.y, roulette.coords.z)
                + rotateVec3(dealerOffset, roulette.coords.w)
            SetEntityCoordsNoOffset(dealerPeds[i], dealerPos.x, dealerPos.y, dealerPos.z, false, false, false)
            startDealerIdleLoop(i, dealerPos)
        end
    end
    lib.requestAudioBank('DLC_VINEWOOD/CASINO_GENERAL', 10000)
    lib.requestAnimDict('anim_casino_b@amb@casino@games@roulette@player')
    lib.requestAnimDict('anim_casino_b@amb@casino@games@roulette@dealer')
    lib.requestAnimDict('anim_casino_b@amb@casino@games@roulette@dealer_female')
    lib.requestAnimDict(ROULETTE_TABLE_DICT)
    rouletteTablesLoaded = true
    rouletteTablesLoading = false
end

local function unloadRouletteTables()
    if not rouletteTablesLoaded and not rouletteTablesLoading then return end
    rouletteTablesLoading = false
    rouletteTablesLoaded = false

    for i = 1, #config.Roulettes do
        if tableProps[i] then
            DeleteObject(tableProps[i])
            DeleteEntity(dealerPeds[i])
            DeleteEntity(ballEntities[i])
            tableProps[i] = nil
            dealerPeds[i] = nil
            ballEntities[i] = nil
        end
    end
    ReleaseNamedScriptAudioBank('DLC_VINEWOOD/CASINO_GENERAL')
    RemoveAnimDict('anim_casino_b@amb@casino@games@roulette@player')
    RemoveAnimDict('anim_casino_b@amb@casino@games@roulette@dealer')
    RemoveAnimDict('anim_casino_b@amb@casino@games@roulette@dealer_female')
    RemoveAnimDict(ROULETTE_TABLE_DICT)
end

useAreaHooks(function(inArea)
    if inArea then
        loadRouletteTables()
    else
        unloadRouletteTables()
    end
end)

target:addModel(tableModels, {
    {
        label = 'Main Roulette',
        icon = 'fa-solid fa-circle-dot',
        onSelect = function(data)
            tableEntity = data.entity
            local chairPos, chairRot = findClosestSeat()
            seatPosition = chairPos
            seatRotation = chairRot
            
            local tableCoords = GetEntityCoords(tableEntity)
            local tableIndex = lib.array.findIndex(config.Roulettes, function(val)
                local distance = #(val.coords.xyz - tableCoords)
                return distance < 1.5
            end)
            local canUse, betsOpen = lib.callback.await('rhd_casino_roulette:callback:canUse', false, tableIndex, seatPosition)
            if canUse then
                canPlaceBets = betsOpen
                currentTableIndex = tableIndex
                startPlaying()
            end
        end,
        distance = 1.5
    }
})

local function cleanupEverything()
    for i = 1, #config.Roulettes do
        if tableProps[i] then
            DeleteObject(tableProps[i])
            DeleteEntity(dealerPeds[i])
            DeleteEntity(ballEntities[i])
        end
    end
    for i = 0, 37 do
        if gridMarkers[i] then
            DeleteObject(gridMarkers[i])
        end
    end
    if DoesCamExist(wheelCamera) then
        DestroyCam(wheelCamera, false)
        DestroyCam(tableCamera, false)
    end
    if DoesEntityExist(chipCursorEntity) then
        DeleteEntity(chipCursorEntity)
    end
    for _, chips in pairs(playerChips) do
        for i = 1, #chips do
            DeleteObject(chips[i])
        end
    end
    for tableIdx, cellChips in pairs(otherPlayerChipObjects) do
        for cellIdx, chips in pairs(cellChips) do
            for i = 1, #chips do
                DeleteObject(chips[i])
            end
            otherPlayerChipObjects[tableIdx][cellIdx] = {}
        end
    end
    StopAudioScene('DLC_VW_Casino_Table_Games')
    ReleaseNamedScriptAudioBank('DLC_VINEWOOD/CASINO_GENERAL')
    RemoveAnimDict('anim_casino_b@amb@casino@games@roulette@player')
    RemoveAnimDict('anim_casino_b@amb@casino@games@roulette@dealer')
    RemoveAnimDict('anim_casino_b@amb@casino@games@roulette@dealer_female')
    RemoveAnimDict(ROULETTE_TABLE_DICT)
end

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        cleanupEverything()
    end
end)

RegisterNetEvent('rhd_casino_roulette:client:greetSpeech', function(tableIdx, playerId)
    if source == '' then return end
    local serverId = GetPlayerServerId(playerId)
    local playerPed = GetPlayerPed(GetPlayerFromServerId(serverId))
    local dealer = dealerPeds[tableIdx]
    if DoesEntityExist(playerPed) and DoesEntityExist(dealer) and not IsAmbientSpeechPlaying(dealer) then
        local greetLines = IsPedMale(playerPed)
            and { 'MINIGAME_DEALER_GREET', 'MINIGAME_DEALER_GREET_MALE' }
            or { 'MINIGAME_DEALER_GREET', 'MINIGAME_DEALER_GREET_FEMALE' }
        local line = greetLines[math.random(1, #greetLines)]
        TaskLookAtEntity(dealer, playerPed, 2000, 2048, 3)
        PlayPedAmbientSpeechNative(dealer, line, 'SPEECH_PARAMS_STANDARD')
    end
end)

RegisterNetEvent('rhd_casino_roulette:client:leaveSpeech', function(tableIdx, playerId)
    if source == '' then return end
    local serverId = GetPlayerServerId(playerId)
    local playerPed = GetPlayerPed(GetPlayerFromServerId(serverId))
    local dealer = dealerPeds[tableIdx]
    if DoesEntityExist(playerPed) and DoesEntityExist(dealer) and not IsAmbientSpeechPlaying(dealer) then
        TaskLookAtEntity(dealer, playerPed, 2000, 2048, 3)
        PlayPedAmbientSpeechNative(dealer, 'MINIGAME_DEALER_LEAVE_NEUTRAL_GAME', 'SPEECH_PARAMS_STANDARD')
    end
end)

RegisterNetEvent('rhd_casino_roulette:client:acceptBetsSpeech', function(tableIdx)
    if source == '' then return end
    if currentTableIndex == tableIdx then
        canPlaceBets = true
    end
    local dealer = dealerPeds[tableIdx]
    if DoesEntityExist(dealer) and not IsAmbientSpeechPlaying(dealer) then
        PlayPedAmbientSpeechNative(dealer, 'MINIGAME_DEALER_PLACE_BET', 'SPEECH_PARAMS_STANDARD')
    end
end)

RegisterNetEvent('rhd_casino_roulette:client:startWheel', function(tableIdx, lastNumber)
    if source == '' then return end
    wheelSlotIndices[tableIdx] = ROULETTE_TO_SLOT[lastNumber] or wheelSlotIndices[tableIdx] or 1
    local animOffset = BALL_ANIM_OFFSETS[wheelSlotIndices[tableIdx]]
    dealerIdling[tableIdx] = false
    local dealer = dealerPeds[tableIdx]
    if not DoesEntityExist(dealer) then return end
    local dealerCoords = GetEntityCoords(dealer)
    local wheelBone = GetEntityBoneIndexByName(tableProps[tableIdx], 'Roulette_Wheel')
    local wheelPos = GetEntityBonePosition_2(tableProps[tableIdx], wheelBone)
    local dealerAnimDict = IsPedMale(dealer)
        and 'anim_casino_b@amb@casino@games@roulette@dealer'
        or 'anim_casino_b@amb@casino@games@roulette@dealer_female'
    TaskPlayAnimAdvanced(dealer, dealerAnimDict, 'spin_wheel',
        dealerCoords.x, dealerCoords.y, dealerCoords.z,
        0.0, 0.0, GetEntityHeading(dealer),
        4.0, -4.0, -1, 0, 0.0, false, false
    )
    SetEntityCoords(ballEntities[tableIdx], wheelPos.x, wheelPos.y, wheelPos.z, false, false, false, false)
    SetEntityRotation(ballEntities[tableIdx],
        wheelBoneRotations[tableIdx].x, wheelBoneRotations[tableIdx].y, wheelBoneRotations[tableIdx].z, 2, false
    )
    PlayEntityAnim(ballEntities[tableIdx], 'intro_ball', ROULETTE_TABLE_DICT, 1000.0, false, true, false, 0.0, 136704)
    CreateThread(function()
        Wait(3200)
        ballSoundIds[tableIdx] = GetSoundId()
        PlaySoundFromEntity(ballSoundIds[tableIdx], 'DLC_VW_ROULETTE_BALL_LOOP', ballEntities[tableIdx], 'dlc_vw_table_games_sounds', false, 0)
    end)
    repeat
        Wait(0)
    until GetEntityAnimCurrentTime(dealer, dealerAnimDict, 'spin_wheel') >= 0.160919547
    SetEntityVisible(ballEntities[tableIdx], true, false)
    SetEntityAlpha(ballEntities[tableIdx], 255, false)
    PlayEntityAnim(tableProps[tableIdx], 'intro_wheel', ROULETTE_TABLE_DICT, 1000.0, false, true, false, animOffset, 131072)
    while true do
        if HasAnimEventFired(tableProps[tableIdx], -567275695) then
            if not IsEntityPlayingAnim(tableProps[tableIdx], ROULETTE_TABLE_DICT, 'loop_wheel', 3) then
                local localRot = GetEntityBoneRotationLocal(tableProps[tableIdx], wheelBone)
                if localRot.z >= 86.0 and localRot.z <= 90.0 then
                    PlayEntityAnim(tableProps[tableIdx], 'loop_wheel', ROULETTE_TABLE_DICT, 1000.0, true, false, false, 0.0, 131072)
                    ForceEntityAiAndAnimationUpdate(tableProps[tableIdx])
                end
            end
        end
        local ballTime = GetEntityAnimCurrentTime(ballEntities[tableIdx], ROULETTE_TABLE_DICT, 'intro_ball')
        if ballTime >= 0.77136969026672 then
            if not IsEntityPlayingAnim(ballEntities[tableIdx], ROULETTE_TABLE_DICT, 'loop_ball', 3) then
                SetEntityCoords(ballEntities[tableIdx], wheelPos.x, wheelPos.y, wheelPos.z, false, false, false, false)
                SetEntityRotation(ballEntities[tableIdx],
                    wheelBoneRotations[tableIdx].x, wheelBoneRotations[tableIdx].y, wheelBoneRotations[tableIdx].z, 2, false
                )
                PlayEntityAnim(ballEntities[tableIdx], 'loop_ball', ROULETTE_TABLE_DICT, 1000.0, true, false, false, 0.0, 136704)
                ForceEntityAiAndAnimationUpdate(ballEntities[tableIdx])
            end
        end
        if IsEntityPlayingAnim(ballEntities[tableIdx], ROULETTE_TABLE_DICT, 'loop_ball', 3) and
           IsEntityPlayingAnim(tableProps[tableIdx], ROULETTE_TABLE_DICT, 'loop_wheel', 3) then
            break
        end
        Wait(0)
    end
    dealerIdling[tableIdx] = true
    local ballLoopTime = GetEntityAnimCurrentTime(ballEntities[tableIdx], ROULETTE_TABLE_DICT, 'loop_ball')
    local wheelLoopTime = GetEntityAnimCurrentTime(tableProps[tableIdx], ROULETTE_TABLE_DICT, 'loop_wheel')
    local diff = wheelLoopTime - ballLoopTime
    local wrappedDiff = ballLoopTime + 1.0 - wheelLoopTime
    if math.abs(diff) < math.abs(wrappedDiff) then
        SetEntityAnimSpeed(ballEntities[tableIdx], ROULETTE_TABLE_DICT, 'loop_ball', 1.12)
    else
        SetEntityAnimSpeed(ballEntities[tableIdx], ROULETTE_TABLE_DICT, 'loop_ball', 0.88)
    end
    repeat
        Wait(0)
        local syncDiff = math.abs(
            GetEntityAnimCurrentTime(ballEntities[tableIdx], ROULETTE_TABLE_DICT, 'loop_ball') -
            GetEntityAnimCurrentTime(tableProps[tableIdx], ROULETTE_TABLE_DICT, 'loop_wheel')
        )
    until syncDiff < 0.0005
    SetEntityAnimSpeed(ballEntities[tableIdx], ROULETTE_TABLE_DICT, 'loop_ball', 1.0)
end)

RegisterNetEvent('rhd_casino_roulette:client:stopAcceptingBets', function(tableIdx, winningNumber, allPlayerBets)
    local dealer = dealerPeds[tableIdx]
    if not DoesEntityExist(dealer) then return end
    dealerIdling[tableIdx] = false
    local isLocalPlayer = (tableIdx == currentTableIndex)
    local dealerAnimDict = IsPedMale(dealer)
        and 'anim_casino_b@amb@casino@games@roulette@dealer'
        or 'anim_casino_b@amb@casino@games@roulette@dealer_female'
    local dealerCoords = GetEntityCoords(dealer)
    TaskPlayAnimAdvanced(dealer, dealerAnimDict, 'no_more_bets',
        dealerCoords.x, dealerCoords.y, dealerCoords.z,
        0.0, 0.0, GetEntityHeading(dealer),
        2.0, -2.0, -1, 2, 0.0, false, false
    )
    local tableDist = #(config.Roulettes[tableIdx].coords.xyz - GetEntityCoords(PlayerPedId()))
    if tableDist < 4.5 and not IsAmbientSpeechPlaying(dealer) then
        PlayPedAmbientSpeechNative(dealer, 'MINIGAME_DEALER_CLOSED_BETS', 'SPEECH_PARAMS_STANDARD')
    end
    local playerReactionAnim = ''
    local playerAnimDict = 'anim_casino_b@amb@casino@games@roulette@player'
    local playerWon = false
    if isLocalPlayer and shared.activeSeat == 'roulette' then
        for _, chips in pairs(playerChips) do
            for i = 1, #chips do
                DeleteObject(chips[i])
            end
        end
        local resultBets = next(submittedCellBets) and submittedCellBets or cellBets
        local winnings = utils.CalculateWinnings(resultBets, winningNumber,
            config.TableType[config.Roulettes[tableIdx].tableType].payoutMultipliers
        )
        local reaction, variants
        if totalBetAmount == 0 then
            reaction = 'no_bet'
            variants = 3
        elseif winnings == 0 then
            if totalBetAmount >= maxBetAmount * 0.5 then
                reaction = 'bad'
            else
                reaction = 'deflated'
            end
            variants = (reaction == 'deflated') and 2 or 3
        else
            local ratio = winnings / totalBetAmount
            if ratio >= 10 then
                reaction = 'great'
                playerWon = true
            elseif ratio >= 2 then
                reaction = 'good'
                playerWon = true
            else
                reaction = 'impartial'
            end
            variants = 3
        end
        local varName = string.format('var%02d', math.random(1, variants))
        playerReactionAnim = string.format('reaction_%s_%s_seat%d', reaction, varName, playerSeatNumber)
        cellBets = {}
        submittedCellBets = {}
        playerChips = {}
        CreateThread(function()
            if shared.activeSeat ~= 'roulette' or currentTableIndex ~= tableIdx then return end
            local betRatio = totalBetAmount / maxBetAmount
            local betLevel = 'no'
            if betRatio > 0.75 then betLevel = 'high'
            elseif betRatio > 0.0 then betLevel = 'mid' end
            local introAnim = string.format('ready_up_%s_bet_%s_seat%d', betLevel, 'intro', playerSeatNumber)
            local loopAnim = string.format('ready_up_%s_bet_%s_seat%d', betLevel, 'loop', playerSeatNumber)
            local scene = NetworkCreateSynchronisedScene(
                seatPosition.x, seatPosition.y, seatPosition.z,
                seatRotation.x, seatRotation.y, seatRotation.z,
                2, true, false, 1.0, 0.0, 1.0
            )
            NetworkAddPedToSynchronisedScene(PlayerPedId(), scene, playerAnimDict, introAnim, 2.0, -2.0, 13, 16, 2.0, 0)
            NetworkStartSynchronisedScene(scene)
            local timeout = GetGameTimer() + 5000
            while GetGameTimer() < timeout do
                if shared.activeSeat ~= 'roulette' or currentTableIndex ~= tableIdx then return end
                if HasAnimEventFired(PlayerPedId(), -1424880317) then break end
                Wait(0)
            end
            if shared.activeSeat ~= 'roulette' or currentTableIndex ~= tableIdx then return end
            scene = NetworkCreateSynchronisedScene(
                seatPosition.x, seatPosition.y, seatPosition.z,
                seatRotation.x, seatRotation.y, seatRotation.z,
                2, false, true, 1.0, 0.0, 1.0
            )
            NetworkAddPedToSynchronisedScene(PlayerPedId(), scene, playerAnimDict, loopAnim, 2.0, -2.0, 13, 16, 2.0, 0)
            NetworkStartSynchronisedScene(scene)
            totalBetAmount = 0
        end)
    end
    updateOtherPlayerChips(tableIdx, allPlayerBets)
    Wait(GetAnimDuration(dealerAnimDict, 'no_more_bets') * 999)
    dealerIdling[tableIdx] = true
    local slotIndex = ROULETTE_TO_SLOT[winningNumber]
    wheelSlotIndices[tableIdx] = slotIndex
    local wheelBone = GetEntityBoneIndexByName(tableProps[tableIdx], 'Roulette_Wheel')
    local wheelPos = GetEntityBonePosition_2(tableProps[tableIdx], wheelBone)
    repeat
        Wait(0)
    until GetEntityAnimCurrentTime(tableProps[tableIdx], ROULETTE_TABLE_DICT, 'loop_wheel') >= 0.99
    SetEntityCoords(ballEntities[tableIdx], wheelPos.x, wheelPos.y, wheelPos.z, false, false, false, false)
    SetEntityRotation(ballEntities[tableIdx],
        wheelBoneRotations[tableIdx].x, wheelBoneRotations[tableIdx].y, wheelBoneRotations[tableIdx].z, 2, false
    )
    PlayEntityAnim(ballEntities[tableIdx], string.format('exit_%s_ball', slotIndex), ROULETTE_TABLE_DICT, 1000.0, false, true, false, 0.0, 136704)
    ForceEntityAiAndAnimationUpdate(ballEntities[tableIdx])
    PlayEntityAnim(tableProps[tableIdx], string.format('exit_%s_wheel', slotIndex), ROULETTE_TABLE_DICT, 1000.0, false, true, false, 0.0, 131072)
    ForceEntityAiAndAnimationUpdate(tableProps[tableIdx])
    StopSound(ballSoundIds[tableIdx])
    ReleaseSoundId(ballSoundIds[tableIdx])
    PlaySoundFromEntity(-1, string.format('dlc_vw_roulette_exit_%s', slotIndex), ballEntities[tableIdx], 'dlc_vw_table_games_roulette_exit_sounds', false, 0)
    repeat
        repeat
            Wait(0)
        until GetEntityAnimCurrentTime(ballEntities[tableIdx], ROULETTE_TABLE_DICT, string.format('exit_%s_ball', slotIndex)) >= 0.9
    until GetEntityAnimCurrentTime(tableProps[tableIdx], ROULETTE_TABLE_DICT, string.format('exit_%s_wheel', slotIndex)) >= 0.9
    if tableDist < 4.5 and not IsAmbientSpeechPlaying(dealer) then
        local numLabel = (winningNumber == 37) and '00' or winningNumber
        PlayPedAmbientSpeechNative(dealer, string.format('MINIGAME_ROULETTE_BALL_%s', numLabel), 'SPEECH_PARAMS_STANDARD')
    end
    dealerIdling[tableIdx] = false
    if isLocalPlayer then
        CreateThread(function()
            if shared.activeSeat ~= 'roulette' or currentTableIndex ~= tableIdx then return end
            if not DoesEntityExist(chipCursorEntity) then return end
            local scene = NetworkCreateSynchronisedScene(
                seatPosition.x, seatPosition.y, seatPosition.z,
                seatRotation.x, seatRotation.y, seatRotation.z,
                2, true, false, 1.0, 0.0, 1.0
            )
            NetworkAddPedToSynchronisedScene(PlayerPedId(), scene, playerAnimDict, playerReactionAnim, 2.0, -2.0, 13, 16, 2.0, 0)
            NetworkStartSynchronisedScene(scene)
            if playerWon then
                PlaySoundFrontend(-1, 'DLC_VW_WIN_CHIPS', 'dlc_vw_table_games_frontend_sounds', false)
            end
            local timeout = GetGameTimer() + 5000
            while GetGameTimer() < timeout do
                if shared.activeSeat ~= 'roulette' or currentTableIndex ~= tableIdx then return end
                if HasAnimEventFired(PlayerPedId(), -1424880317) then break end
                Wait(0)
            end
            playRandomIdleAnimation()
        end)
    end
    TaskPlayAnimAdvanced(dealer, dealerAnimDict, 'clear_chips_intro',
        dealerCoords.x, dealerCoords.y, dealerCoords.z,
        0.0, 0.0, GetEntityHeading(dealer), 2.0, -2.0, -1, 2, 0.0, false, false
    )
    Wait(GetAnimDuration(dealerAnimDict, 'clear_chips_intro') * 950)
    TaskPlayAnimAdvanced(dealer, dealerAnimDict, 'clear_chips_zone2',
        dealerCoords.x, dealerCoords.y, dealerCoords.z,
        0.0, 0.0, GetEntityHeading(dealer), 2.0, -2.0, -1, 2, 0.0, false, false
    )
    Wait(GetAnimDuration(dealerAnimDict, 'clear_chips_zone2') * 300)
    CreateThread(function()
        for _, chips in pairs(otherPlayerChipObjects[tableIdx]) do
            for j = 1, #chips do
                animateChipFade(chips[j])
            end
        end
        Wait(10000)
        updateOtherPlayerChips(tableIdx)
    end)
    Wait(GetAnimDuration(dealerAnimDict, 'clear_chips_zone2') * 650)
    TaskPlayAnimAdvanced(dealer, dealerAnimDict, 'clear_chips_outro',
        dealerCoords.x, dealerCoords.y, dealerCoords.z,
        0.0, 0.0, GetEntityHeading(dealer), 2.0, -2.0, -1, 2, 0.0, false, false
    )
    Wait(GetAnimDuration(dealerAnimDict, 'clear_chips_outro') * 950)
    CreateThread(function()
        animateChipFade(ballEntities[tableIdx])
    end)
    dealerIdling[tableIdx] = true
end)

lib.callback.register('rhd_casino_roulette:callback:playerInput', function()
    canPlaceBets = false
    submittedCellBets = {}
    for cellIdx, amount in pairs(cellBets) do
        submittedCellBets[cellIdx] = amount
    end
    return submittedCellBets
end)
