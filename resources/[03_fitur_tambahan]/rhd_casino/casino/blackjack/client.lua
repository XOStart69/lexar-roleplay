local DEALER_DICT <const> = 'anim_casino_b@amb@casino@games@blackjack@dealer'
local PLAYER_DICT <const> = 'anim_casino_b@amb@casino@games@blackjack@player'
local SHARED_PLAYER <const> = 'anim_casino_b@amb@casino@games@shared@player@'
local SHARED_DEALER <const> = 'anim_casino_b@amb@casino@games@shared@dealer@'
local CARD_RELEASE_EVENT <const> = 585557868
local CARD_GRAB_EVENT <const> = -1345695206

local CONTROLS = {
    increase = 241,
    decrease = 242,
    place = 24,
    removeBet = 25,
    confirm = 201,
    leave = 202,
    hit = 201,
    stand = 203,
    double = 47,
    split = 311,
    focusCam = 26,
}

local INFO_ID = 'blackjack_info'

local focusCam = 0
local focusCamOn = false

local function isControlJustPressed(control)
    return IsDisabledControlJustPressed(0, control)
end

local function buildBetValues(amounts, maxBet)
    local values = {}
    if type(amounts) ~= 'table' then return values end

    for i = 1, #amounts do
        local value = tonumber(amounts[i])
        if value and value > 0 and value <= maxBet then
            values[#values + 1] = math.floor(value)
        end
    end

    table.sort(values)
    return values
end

---@class BJ_UpdateUIOpts
---@field phase string?
---@field timerSec number?
---@field currentBet number?
---@field chipValue number?
---@field minBet number?
---@field maxBet number?
---@field canDouble boolean?
---@field canSplit boolean?

local cacheEntities = {
    tables = {},
    dealerPeds = {},
    handObjs = {},
    dealerHandObjs = {},
    chipPiles = {},
    chipPilesAlt = {},
    chipPilesDouble = {},
    chipPilesSplitDouble = {},
}

local blackjackTablesLoaded = false
local blackjackTablesLoading = false

local seat = {
    active = false,
    tableIdx = 0,
    seatNumber = 0,
    seatCoords = vec3(0, 0, 0),
    seatRot = vec3(0, 0, 0),
    phase = 'idle',
    inRound = false,
    hand = {},
    splitHand = nil,
    dealerHand = {},
    selectedBet = 1,
    pendingBet = 0,
    roundBet = 0,
    hasLocalBetChips = false,
    leaving = false,
    tableBusy = false,
    tableEndTime = 0,
}

local cards = require 'casino.blackjack.modules.cards'
local config = require 'casino.blackjack.config.blackjack'
local spawnDealer = require 'modules.dealers'
local coords = require 'casino.blackjack.data.coords'

---@param tableIdx integer
local function ensureSlot(tableIdx)
    cacheEntities.handObjs[tableIdx] = cacheEntities.handObjs[tableIdx] or { {}, {}, {}, {} }
    cacheEntities.dealerHandObjs[tableIdx] = cacheEntities.dealerHandObjs[tableIdx] or {}
    cacheEntities.chipPiles[tableIdx] = cacheEntities.chipPiles[tableIdx] or { {}, {}, {}, {} }
    cacheEntities.chipPilesAlt[tableIdx] = cacheEntities.chipPilesAlt[tableIdx] or { {}, {}, {}, {} }
    cacheEntities.chipPilesDouble[tableIdx] = cacheEntities.chipPilesDouble[tableIdx] or { {}, {}, {}, {} }
    cacheEntities.chipPilesSplitDouble[tableIdx] = cacheEntities.chipPilesSplitDouble[tableIdx] or { {}, {}, {}, {} }
end

---Converts a seconds value to mm:ss formatted string.
---@param s number
---@return string
local function s2m(s)
    if s <= 0 then return '00:00' end
    local m = math.floor(s / 60)
    return ('%02d:%02d'):format(m, s - m * 60)
end

---@param title string
---@param description string
local function showInfo(title, description)
    infoUI:show({
        id = INFO_ID,
        title = title or 'Blackjack',
        icon = 'fa-solid fa-diamond',
        description = description,
    })
end

local function hideInfo()
    infoUI:remove(INFO_ID)
end

---@param opts? BJ_UpdateUIOpts
local function updateUI(opts)
    opts = opts or {}
    local phase = opts.phase or seat.phase
    local title = phase == 'betting' and 'Blackjack - Bet'
               or phase == 'move' and 'Blackjack - Move'
               or 'Blackjack'
    local lines = {}

    local timerSec = opts.timerSec
    if not timerSec and seat.tableEndTime > 0 then
        timerSec = math.max(0, math.ceil((seat.tableEndTime - GetGameTimer()) / 1000))
    end
    if timerSec then
        lines[#lines + 1] = ('[kbd]Time[/kbd] %s'):format(s2m(timerSec))
    end

    if phase == 'betting' then
        lines[#lines + 1] = '[kbd]Scroll[/kbd] Select Chip'
        lines[#lines + 1] = '[kbd]LMB[/kbd] Add Chip'
        lines[#lines + 1] = '[kbd]RMB[/kbd] Remove Chip'
        if (opts.currentBet or 0) > 0 then
            lines[#lines + 1] = '[kbd]Enter[/kbd] Confirm Bet'
        end
    elseif phase == 'move' then
        lines[#lines + 1] = '[kbd]Enter[/kbd] Hit'
        lines[#lines + 1] = '[kbd]Space[/kbd] Stand'
        if opts.canDouble then lines[#lines + 1] = '[kbd]G[/kbd] Double Down' end
        if opts.canSplit then lines[#lines + 1] = '[kbd]K[/kbd] Split' end
    else
        if not seat.inRound then
            lines[#lines + 1] = '[kbd]Backspace[/kbd] Leave Table'
        end
    end

    if seat.inRound then
        lines[#lines + 1] = ('[kbd]C[/kbd] %s'):format(focusCamOn and 'Tutup Kamera' or 'Kamera Kartu')
    end

    lines[#lines + 1] = ''

    if seat.dealerHand and #seat.dealerHand > 0 then
        local visHand = {}
        local hasHidden = false
        for i = 1, #seat.dealerHand do
            local d = seat.dealerHand[i]
            if d.flipped then
                hasHidden = true
            else
                visHand[#visHand + 1] = d.card
            end
        end
        if #visHand > 0 then
            lines[#lines + 1] = ('Dealer: %d%s'):format(cards.handValue(visHand), hasHidden and ' + ?' or '')
        else
            lines[#lines + 1] = 'Dealer: ?'
        end
    end

    if seat.hand and #seat.hand > 0 then
        lines[#lines + 1] = ('Hand: %d'):format(cards.handValue(seat.hand))
    elseif seat.inRound then
        lines[#lines + 1] = 'Menunggu kartu...'
    end

    if seat.splitHand and #seat.splitHand > 0 then
        lines[#lines + 1] = ('Split: %d'):format(cards.handValue(seat.splitHand))
    end

    if phase == 'betting' and opts.chipValue ~= nil then
        local balance = ox_inventory:GetItemCount(shared.chipItemName)
        lines[#lines + 1] = ('Chip: $%s'):format(opts.chipValue)
        lines[#lines + 1] = ('Bet:  $%s  (min $%s / max $%s)'):format(
            opts.currentBet or 0, opts.minBet or 1, opts.maxBet or 999999)
        lines[#lines + 1] = ('Balance: $%s'):format(balance)
    elseif seat.pendingBet and seat.pendingBet > 0 then
        lines[#lines + 1] = ('Bet placed: $%s'):format(seat.pendingBet)
    elseif seat.roundBet and seat.roundBet > 0 then
        lines[#lines + 1] = ('Bet: $%s'):format(seat.roundBet)
    end

    while lines[#lines] == '' do table.remove(lines) end

    showInfo(title, table.concat(lines, '\n'))
end

---@param tableIdx integer
---@param seatNum integer
---@param handSize integer
---@param card string
---@param flipped boolean
---@param isSplit boolean?
---@param isDouble boolean?
---@return integer? entity
local function spawnCardEntity(tableIdx, seatNum, handSize, card, flipped, isSplit, isDouble)
    ensureSlot(tableIdx)

    local model = GetHashKey('vw_prop_cas_card_' .. card)
    lib.requestModel(model, 1500)

    local tableCoords = config.tables[tableIdx].coords
    local ent = CreateObjectNoOffset(model, tableCoords.x, tableCoords.y, tableCoords.z, false, false, false)
    SetModelAsNoLongerNeeded(model)

    local dealerPed = cacheEntities.dealerPeds[tableIdx]
    if dealerPed and DoesEntityExist(dealerPed) then
        SetEntityVisible(ent, false, false)
        AttachEntityToEntity(ent, dealerPed, GetPedBoneIndex(dealerPed, 28422),
            0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, true, 2, true)
        Wait(300)
        SetEntityVisible(ent, true, false)
        local timeout = GetGameTimer() + 1200
        while not HasAnimEventFired(dealerPed, CARD_RELEASE_EVENT) and GetGameTimer() < timeout do
            Wait(0)
        end
        DetachEntity(ent, false, true)
    end

    if seatNum == 0 then
        local off = coords.cardOffsetsDealer[handSize] or coords.cardOffsetsDealer[1]
        local rot = coords.cardRotationOffsetsDealer[handSize] or coords.cardRotationOffsetsDealer[1]
        local p = GetObjectOffsetFromCoords(tableCoords.x, tableCoords.y, tableCoords.z, tableCoords.w, off.x, off.y, off.z)
        SetEntityCoordsNoOffset(ent, p.x, p.y, p.z, false, false, false)
        SetEntityRotation(ent, flipped and 180.0 or 0.0, 0.0, tableCoords.w + rot.z, 2, true)
        table.insert(cacheEntities.dealerHandObjs[tableIdx], ent)
    else
        local s = 5 - seatNum
        local off, rotZ
        if isDouble then
            local arr = isSplit and coords.cardSplitOffsets[s] or coords.cardOffsets[s]
            local rarr = isSplit and coords.cardSplitRotationOffsets[s] or coords.cardRotationOffsets[s]
            local lastIdx = math.max(handSize - 1, 1)
            local base = arr[lastIdx] or arr[1]
            local prev = arr[lastIdx - 1] or base
            local dx, dy = base.x - prev.x, base.y - prev.y
            local len = math.sqrt(dx * dx + dy * dy)
            if len > 0.0001 then dx, dy = dx / len, dy / len end
            off = vector3(base.x + dx * 0.03 + dy * 0.015, base.y + dy * 0.03 - dx * 0.015, base.z + 0.004)
            rotZ = (rarr[lastIdx] or 0.0) + 90.0
        elseif isSplit then
            off = coords.cardSplitOffsets[s][handSize]
            rotZ = coords.cardSplitRotationOffsets[s][handSize]
        else
            off = coords.cardOffsets[s][handSize]
            rotZ = coords.cardRotationOffsets[s][handSize]
        end
        if off then
            local p = GetObjectOffsetFromCoords(tableCoords.x, tableCoords.y, tableCoords.z, tableCoords.w, off.x, off.y, off.z)
            SetEntityCoordsNoOffset(ent, p.x, p.y, p.z, false, false, false)
            SetEntityRotation(ent, 0.0, 0.0, tableCoords.w + (rotZ or 0.0), 2, true)
        end
        table.insert(cacheEntities.handObjs[tableIdx][seatNum], ent)
    end
end

local chipDenominations = (function()
    local t = {}
    for k in pairs(config.chipModels) do t[#t + 1] = k end
    table.sort(t, function(a, b) return a > b end)
    return t
end)()

---@param amount number
---@return table<string, number>
local function decomposeChips(amount)
    local out = {}
    local remaining = amount
    for i = 1, #chipDenominations do
        local value = chipDenominations[i]
        while remaining >= value do
            out[#out + 1] = value
            remaining = remaining - value
        end
    end
    return out
end

---@param tableIdx integer
---@param seatNum integer
---@param amount number
---@param double boolean?
---@param split boolean?
local function spawnChipPile(tableIdx, seatNum, amount, double, split)
    ensureSlot(tableIdx)
    if not amount or amount <= 0 then return end

    local tableConfig = config.tables[tableIdx]
    local tableCoords = tableConfig?.coords

    local s = 5 - seatNum

    local offXY, rotExtra
    if split then
        offXY = coords.chipSplitOffsets[s] and coords.chipSplitOffsets[s][1]
        local r = coords.chipSplitRotationOffsets[s] and coords.chipSplitRotationOffsets[s][1]
        rotExtra = r and r.z or 0.0
    else
        offXY = coords.chipOffsets[s] and coords.chipOffsets[s][1]
        local r = coords.chipRotationOffsets[s] and coords.chipRotationOffsets[s][1]
        rotExtra = r and r.z or 0.0
    end
    if not offXY then return end

    local offX, offY, offZ = offXY.x, offXY.y, offXY.z
    if double then
        local dStore = split and coords.chipSplitDoubleOffsets or coords.chipDoubleOffsets
        local dOff = dStore and dStore[s] and dStore[s][1]
        if dOff then
            offX, offY = dOff.x, dOff.y
            if dOff.z and dOff.z > 0.1 then offZ = dOff.z end
        else
            local dir = offX >= 0 and 1.0 or -1.0
            offX = offX + dir * 0.11
        end
        local dRotStore = split and coords.chipSplitDoubleRotationOffsets or coords.chipDoubleRotationOffsets
        local dRot = dRotStore and dRotStore[s] and dRotStore[s][1]
        if dRot then rotExtra = dRot.z end
    end

    local pileStore
    if double and split then
        pileStore = cacheEntities.chipPilesSplitDouble
    elseif double then
        pileStore = cacheEntities.chipPilesDouble
    elseif split then
        pileStore = cacheEntities.chipPilesAlt
    else
        pileStore = cacheEntities.chipPiles
    end

    local pile = pileStore[tableIdx][seatNum]
    for i = 1, #pile do
        if DoesEntityExist(pile[i]) then DeleteEntity(pile[i]) end
    end
    pileStore[tableIdx][seatNum] = {}
    pile = pileStore[tableIdx][seatNum]

    local rotZ = tableCoords.w + rotExtra

    local baseZ = (offZ and offZ > 0.1) and offZ or 0.95
    local baseWorld = GetObjectOffsetFromCoords(tableCoords.x, tableCoords.y, tableCoords.z, tableCoords.w, offX, offY, baseZ)

    local stack = decomposeChips(amount)
    local stackHeight = 0.0

    for i = 1, #stack do
        local modelName = config.chipModels[stack[i]]
        if not modelName then goto continue end
        local hash = GetHashKey(modelName)
        lib.requestModel(hash, 1500)

        local thickness = config.chipThickness[hash] or 0.0057
        local chip = CreateObjectNoOffset(hash,
            baseWorld.x + (math.random() - 0.5) * 0.004,
            baseWorld.y + (math.random() - 0.5) * 0.004,
            baseWorld.z + stackHeight,
            false, false, false
        )
        SetEntityRotation(chip, 0.0, 0.0, rotZ, 2, true)
        SetEntityCollision(chip, false, false)
        SetModelAsNoLongerNeeded(hash)

        table.insert(pile, chip)
        stackHeight = stackHeight + thickness
        ::continue::
    end
end

---@param tableIdx integer
---@param seatNum integer
local function clearSeatVisuals(tableIdx, seatNum)
    ensureSlot(tableIdx)

    if seatNum == 0 then
        for i = 1, #cacheEntities.dealerHandObjs[tableIdx] do DeleteEntity(cacheEntities.dealerHandObjs[tableIdx][i]) end
        cacheEntities.dealerHandObjs[tableIdx] = {}
    else
        for i = 1, #(cacheEntities.handObjs[tableIdx][seatNum] or {}) do DeleteEntity(cacheEntities.handObjs[tableIdx][seatNum][i]) end
        cacheEntities.handObjs[tableIdx][seatNum] = {}
        for i = 1, #(cacheEntities.chipPiles[tableIdx][seatNum] or {}) do DeleteEntity(cacheEntities.chipPiles[tableIdx][seatNum][i]) end
        cacheEntities.chipPiles[tableIdx][seatNum] = {}
        for i = 1, #(cacheEntities.chipPilesAlt[tableIdx][seatNum] or {}) do DeleteEntity(cacheEntities.chipPilesAlt[tableIdx][seatNum][i]) end
        cacheEntities.chipPilesAlt[tableIdx][seatNum] = {}
        for i = 1, #(cacheEntities.chipPilesDouble[tableIdx][seatNum] or {}) do DeleteEntity(cacheEntities.chipPilesDouble[tableIdx][seatNum][i]) end
        cacheEntities.chipPilesDouble[tableIdx][seatNum] = {}
        for i = 1, #(cacheEntities.chipPilesSplitDouble[tableIdx][seatNum] or {}) do DeleteEntity(cacheEntities.chipPilesSplitDouble[tableIdx][seatNum][i]) end
        cacheEntities.chipPilesSplitDouble[tableIdx][seatNum] = {}
    end
end

local runBettingUI ---@type fun(tableIdx: integer, timeLimit: integer): boolean?

RegisterNetEvent('rhd_casino_blackjack:client:dealerAnim', function(tableIdx, anim)
    if source == '' then return end
    local v = config.tables[tableIdx]
    if not v then return end
    local dict, clip = anim[1], anim[2]
    lib.requestAnimDict(dict, 1500)
    local scene = CreateSynchronizedScene(v.coords.x, v.coords.y, v.coords.z - 0.025, 0.0, 0.0, v.coords.w, 2)
    if cacheEntities.dealerPeds[tableIdx] then
        TaskSynchronizedScene(cacheEntities.dealerPeds[tableIdx], scene, dict, clip, 1000.0, -8.0, 4, 1, 1148846080, 0)
    end
end)

RegisterNetEvent('rhd_casino_blackjack:client:dealerSpeech', function(tableIdx, speech)
    if source == '' then return end
    local ped = cacheEntities.dealerPeds[tableIdx]
    if not ped or not DoesEntityExist(ped) then return end

    StopCurrentPlayingSpeech(ped)
    PlayAmbientSpeech1(ped, speech, 'SPEECH_PARAMS_FORCE_NORMAL_CLEAR')
end)

RegisterNetEvent('rhd_casino_blackjack:client:dealerTurnOverCard', function(tableIdx)
    if source == '' then return end

    local list = cacheEntities.dealerHandObjs[tableIdx]
    if not list or not list[1] then return end

    local card = list[1]
    local dealerPed = cacheEntities.dealerPeds[tableIdx]
    if dealerPed and DoesEntityExist(dealerPed) then
        local pos = GetEntityCoords(card)
        local grabTimeout = GetGameTimer() + 1000
        while not HasAnimEventFired(dealerPed, CARD_GRAB_EVENT) and GetGameTimer() < grabTimeout do
            Wait(0)
        end
        AttachEntityToEntity(card, dealerPed, GetPedBoneIndex(dealerPed, 28422),
            0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, true, 2, true)
        local releaseTimeout = GetGameTimer() + 1500
        while not HasAnimEventFired(dealerPed, CARD_RELEASE_EVENT) and GetGameTimer() < releaseTimeout do
            Wait(0)
        end
        DetachEntity(card, false, true)
        SetEntityCoordsNoOffset(card, pos.x, pos.y, pos.z, false, false, false)
    end

    SetEntityRotation(card, 0.0, 0.0,
        config.tables[tableIdx].coords.w + coords.cardRotationOffsetsDealer[1].z, 2, true)

    if seat.active and seat.tableIdx == tableIdx and seat.dealerHand[1] then
        seat.dealerHand[1].flipped = false
        updateUI()
    end
end)

RegisterNetEvent('rhd_casino_blackjack:client:giveCard', function(tableIdx, seatNum, handSize, card, flipped, isSplit, isDouble)
    if source == '' then return end

    if seat.active and seat.tableIdx == tableIdx then
        if seatNum == 0 then

            table.insert(seat.dealerHand, { card = card, flipped = flipped })
        elseif seat.seatNumber == seatNum then
            if isSplit then
                seat.splitHand = seat.splitHand or {}
                table.insert(seat.splitHand, card)
            else
                table.insert(seat.hand, card)
            end
        end
        updateUI()
    end

    spawnCardEntity(tableIdx, seatNum, handSize, card, flipped, isSplit, isDouble)
end)

RegisterNetEvent('rhd_casino_blackjack:client:retrieveCards', function(tableIdx, seatNum)
    if source == '' then return end
    clearSeatVisuals(tableIdx, seatNum)

    if seat.active and seat.tableIdx == tableIdx then
        if seatNum == 0 then
            seat.dealerHand = {}
        elseif seat.seatNumber == seatNum then
            seat.hand = {}
            seat.splitHand = nil
            seat.inRound = false
            seat.pendingBet = 0
            seat.roundBet = 0
            seat.hasLocalBetChips = false
        end
    end
end)

RegisterNetEvent('rhd_casino_blackjack:client:placeChip', function(tableIdx, seatNum, bet, double, split)
    if source == '' then return end

    local isOurInitialBet = seat.active
        and seat.tableIdx == tableIdx
        and seat.seatNumber == seatNum
        and not double and not split
        and seat.hasLocalBetChips
    if not isOurInitialBet then
        spawnChipPile(tableIdx, seatNum, bet, double, split)
    end
    if seat.active and seat.tableIdx == tableIdx and seat.seatNumber == seatNum and not double and not split then
        seat.pendingBet = bet
        if seat.phase == 'idle' then updateUI() end
    end

    if seat.active and seat.tableIdx == tableIdx and seat.seatNumber == seatNum and (double or split) then
        seat.roundBet = (seat.roundBet or 0) + bet
        if seat.phase == 'idle' then updateUI() end
    end
end)

RegisterNetEvent('rhd_casino_blackjack:client:betLocked', function(tableIdx, seatNum, _bet)
    if source == '' then return end
    if seat.active and seat.tableIdx == tableIdx and seat.seatNumber == seatNum then
        seat.roundBet = _bet or 0
        seat.pendingBet = 0
        seat.inRound = true
        if seat.phase == 'idle' then updateUI() end
    end
end)

RegisterNetEvent('rhd_casino_blackjack:client:split', function(tableIdx, seatNum, _splitHandSize, _hand, _splitHand)
    if source == '' then return end
    if seat.active and seat.tableIdx == tableIdx and seat.seatNumber == seatNum then
        seat.hand = _hand
        seat.splitHand = _splitHand
    end

    local list = cacheEntities.handObjs[tableIdx] and cacheEntities.handObjs[tableIdx][seatNum]
    if list and list[#list] then
        local ent = list[#list]
        local tableCoords = config.tables[tableIdx].coords
        local s = 5 - seatNum
        local off = coords.cardSplitOffsets[s][1]
        local rot = coords.cardSplitRotationOffsets[s][1]
        if off then
            local p = GetObjectOffsetFromCoords(tableCoords.x, tableCoords.y, tableCoords.z, tableCoords.w, off.x, off.y, off.z)
            SetEntityCoordsNoOffset(ent, p.x, p.y, p.z, false, false, false)
            SetEntityRotation(ent, 0.0, 0.0, tableCoords.w + (rot or 0.0), 2, true)
        end
    end
end)

local function playSeatGesture(dict, anim)
    if not seat.active then return end
    CreateThread(function()
        if not lib.requestAnimDict(dict, 1500) then return end
        if not seat.active then return end

        local scene = NetworkCreateSynchronisedScene(
            seat.seatCoords.x, seat.seatCoords.y, seat.seatCoords.z,
            seat.seatRot.x, seat.seatRot.y, seat.seatRot.z,
            2, false, false, 1.0, 0.0, 1.0
        )
        NetworkAddPedToSynchronisedScene(cache.ped, scene, dict, anim, 2.0, -2.0, 13, 16, 1148846080, 0)
        NetworkStartSynchronisedScene(scene)

        Wait(math.floor(GetAnimDuration(dict, anim) * 1000))
        if not seat.active then return end

        local idleScene = NetworkCreateSynchronisedScene(
            seat.seatCoords.x, seat.seatCoords.y, seat.seatCoords.z,
            seat.seatRot.x, seat.seatRot.y, seat.seatRot.z,
            2, true, true, 1065353216, 0, 1065353216
        )
        NetworkAddPedToSynchronisedScene(cache.ped, idleScene, SHARED_PLAYER, 'idle_cardgames', 2.0, -2.0, 13, 16, 1148846080, 0)
        NetworkStartSynchronisedScene(idleScene)
    end)
end

RegisterNetEvent('rhd_casino_blackjack:client:gameEndReaction', function(result)
    if source == '' then return end
    if not seat.active then return end
    if shared.activeSeat ~= 'blackjack' then return end

    local handVal = cards.handValue(seat.hand)
    local label = ({ good = 'won', bad = 'lost', impartial = 'tied' })[result] or result

    if #seat.hand == 2 and handVal == 21 and result == 'good' then
        lib.notify({ id = 'bj_result', title = 'Blackjack', description = 'You have Blackjack!', type = 'success' })
    elseif handVal > 21 and result == 'bad' then
        lib.notify({ id = 'bj_result', title = 'Blackjack', description = 'You went bust.', type = 'error' })
    else
        lib.notify({
            id = 'bj_result',
            title = 'Blackjack',
            description = ('You %s with %d.'):format(label, handVal),
            type = result == 'good' and 'success' or (result == 'bad' and 'error' or 'inform'),
        })
    end


    playSeatGesture(SHARED_PLAYER, ('reaction_%s_var_0%d'):format(result, math.random(1, 4)))
end)

RegisterNetEvent('rhd_casino_blackjack:client:phase', function(tableIdx, phase, timeLeft, isSplit)
    if source == '' then return end

    if shared.activeSeat ~= 'blackjack' then return end
    if not seat.active or seat.tableIdx ~= tableIdx then return end

    if phase == 'betting' then
        seat.tableBusy = true
        seat.tableEndTime = GetGameTimer() + (timeLeft or config.bettingTime) * 1000

        CreateThread(function()
            runBettingUI(tableIdx, timeLeft)
        end)
    elseif phase == 'move' then
        seat.phase = phase
        local canDouble, canSplit
        if isSplit then
            canDouble = seat.splitHand ~= nil and #seat.splitHand == 2
            canSplit = false
        else
            canDouble = #seat.hand == 2
            canSplit = #seat.hand == 2 and seat.hand[1]:sub(-3) == seat.hand[2]:sub(-3)
        end
        updateUI({ phase = 'move', timerSec = timeLeft, canDouble = canDouble, canSplit = canSplit })
    elseif phase == 'idle' then
        seat.tableBusy = false
        seat.tableEndTime = 0
        if seat.phase == 'betting' then
            seat.phase = 'idle'
        end
        updateUI()
    end
end)

---@param tableIdx integer
---@param timeLimit number seconds
function runBettingUI(tableIdx, timeLimit)
    if not seat.active or seat.tableIdx ~= tableIdx then return end
    if seat.phase == 'betting' then return end

    local tbl = config.tables[tableIdx]
    local maxBet = tonumber(tbl.maxBettingAmount) or 1e9

    local chipValues = buildBetValues(tbl.bettingAmounts, maxBet)
    if #chipValues == 0 then return end
    local minBet = chipValues[1]

    local chipIdx = 1
    local currentBet = 0
    local endTime = GetGameTimer() + (timeLimit or config.bettingTime) * 1000
    local lastRender = -1
    seat.phase = 'betting'

    local previewChips = {}
    local stackHeight = 0.0

    local tableCoords = tbl.coords
    local s = 5 - seat.seatNumber
    local pOff = coords.chipOffsets[s] and coords.chipOffsets[s][1]
    local pRot = coords.chipRotationOffsets[s] and coords.chipRotationOffsets[s][1]
    local pRotZ = tableCoords.w + (pRot and pRot.z or 0.0)
    local pBaseZ = (pOff and pOff.z and pOff.z > 0.1) and pOff.z or 0.95
    local baseWorld = pOff and GetObjectOffsetFromCoords(
        tableCoords.x, tableCoords.y, tableCoords.z, tableCoords.w,
        pOff.x, pOff.y, pBaseZ
    )

    local function spawnOnePreviewChip(denomination)
        if not baseWorld then return end
        local modelName = config.chipModels[denomination]
        if not modelName then return end
        local hash = GetHashKey(modelName)
        lib.requestModel(hash, 1500)
        local thickness = config.chipThickness[hash] or 0.0057
        local chip = CreateObjectNoOffset(hash,
            baseWorld.x + (math.random() - 0.5) * 0.004,
            baseWorld.y + (math.random() - 0.5) * 0.004,
            baseWorld.z + stackHeight,
            false, false, false
        )
        SetEntityRotation(chip, 0.0, 0.0, pRotZ, 2, true)
        SetEntityCollision(chip, false, false)
        SetModelAsNoLongerNeeded(hash)
        stackHeight = stackHeight + thickness
        table.insert(previewChips, { ent = chip, thickness = thickness, denomination = denomination })
        ensureSlot(tableIdx)
        table.insert(cacheEntities.chipPiles[tableIdx][seat.seatNumber], chip)
    end

    local function rebuildPreviewChips(totalBet)
        local piles = cacheEntities.chipPiles[tableIdx] and cacheEntities.chipPiles[tableIdx][seat.seatNumber]
        while #previewChips > 0 do
            local top = table.remove(previewChips)
            if piles then
                for i = #piles, 1, -1 do
                    if piles[i] == top.ent then table.remove(piles, i) break end
                end
            end
            if DoesEntityExist(top.ent) then DeleteEntity(top.ent) end
        end
        stackHeight = 0.0

        if totalBet <= 0 then
            seat.hasLocalBetChips = false
            return
        end

        local decomp = decomposeChips(totalBet)
        for i = 1, #decomp do
            spawnOnePreviewChip(decomp[i])
        end
        seat.hasLocalBetChips = true
    end

    local function clearPreview()
        rebuildPreviewChips(0)
    end

    local function render(remain)
        updateUI({
            phase = 'betting',
            timerSec = remain,
            chipValue = chipValues[chipIdx],
            currentBet = currentBet,
            minBet = minBet,
            maxBet = maxBet,
        })
    end

    while seat.active and seat.phase == 'betting' and GetGameTimer() < endTime do
        local remain = math.ceil((endTime - GetGameTimer()) / 1000)
        if remain ~= lastRender then
            lastRender = remain
            render(remain)
        end

        if remain <= 1 then break end

        for _, index in pairs(CONTROLS) do
            DisableControlAction(0, index, true)
        end

        if isControlJustPressed(CONTROLS.increase) then
            chipIdx = chipIdx + 1
            if chipIdx > #chipValues then chipIdx = 1 end
            render(remain)
        elseif isControlJustPressed(CONTROLS.decrease) then
            chipIdx = chipIdx - 1
            if chipIdx < 1 then chipIdx = #chipValues end
            render(remain)
        elseif isControlJustPressed(CONTROLS.place) then
            local v = chipValues[chipIdx]
            local balance = ox_inventory:GetItemCount(shared.chipItemName)
            if currentBet + v > maxBet then
                lib.notify({ id = 'bj_max', title = 'Blackjack', description = 'Bet exceeds table limit.', type = 'error' })
            elseif currentBet + v > balance then
                lib.notify({ id = 'bj_funds', title = 'Blackjack', description = 'Not enough chips.', type = 'error' })
            else
                currentBet = currentBet + v
                rebuildPreviewChips(currentBet)
                render(remain)
            end
        elseif isControlJustPressed(CONTROLS.removeBet) then
            local v = chipValues[chipIdx]
            if currentBet >= v then
                currentBet = currentBet - v
                rebuildPreviewChips(currentBet)
                render(remain)
            elseif currentBet > 0 then
                currentBet = 0
                rebuildPreviewChips(0)
                render(remain)
            end
        elseif currentBet > 0 and isControlJustPressed(CONTROLS.confirm) then
            break
        end

        Wait(0)
    end

    local placed = false
    if currentBet > 0 then
        if currentBet < minBet then
            lib.notify({ id = 'bj_min', title = 'Blackjack', description = ('Minimum bet is $%s.'):format(minBet), type = 'error' })
            clearPreview()
        else
            clearPreview()
            local ok = lib.callback.await('rhd_casino_blackjack:callback:placeBet', false, tableIdx, currentBet)
            if ok then
                placed = true
                TriggerServerEvent('rhd_casino_blackjack:server:confirmBet', tableIdx)
                local anim = currentBet >= 5000 and 'place_bet_large' or 'place_bet_small'
                lib.requestAnimDict(PLAYER_DICT, 1500)
                local scene = NetworkCreateSynchronisedScene(
                    seat.seatCoords.x, seat.seatCoords.y, seat.seatCoords.z,
                    seat.seatRot.x, seat.seatRot.y, seat.seatRot.z,
                    2, true, false, 1065353216, 0, 1065353216
                )
                NetworkAddPedToSynchronisedScene(cache.ped, scene, PLAYER_DICT, anim, 2.0, -2.0, 13, 16, 1148846080, 0)
                NetworkStartSynchronisedScene(scene)
            else
                lib.notify({ id = 'bj_bet', title = 'Blackjack', description = 'Bet rejected.', type = 'error' })
            end
        end
    end

    seat.phase = 'idle'
    if seat.active then updateUI() end
    return placed
end

lib.callback.register('rhd_casino_blackjack:callback:requestMove', function(tableIdx, timeLimit, canDouble, canSplitMove)
    if not seat.active or seat.tableIdx ~= tableIdx then return 'stand' end

    local endTime = GetGameTimer() + (timeLimit or config.moveTime) * 1000
    local lastTick = -1

    local action = 'stand'

    while seat.active and GetGameTimer() < endTime do
        local remain = math.ceil((endTime - GetGameTimer()) / 1000)
        if remain ~= lastTick then
            lastTick = remain
            updateUI({ phase = 'move', timerSec = remain, canDouble = canDouble, canSplit = canSplitMove })
        end

        for _, index in pairs(CONTROLS) do
            DisableControlAction(0, index, true)
        end

        if isControlJustPressed(CONTROLS.hit) then
            action = 'hit'
            break
        elseif isControlJustPressed(CONTROLS.stand) then
            action = 'stand'
            break
        elseif canDouble and isControlJustPressed(CONTROLS.double) then
            if ox_inventory:GetItemCount(shared.chipItemName) > 0 then
                action = 'double'
                break
            else
                lib.notify({ id = 'bj_funds', title = 'Blackjack', description = 'Not enough chips to double.', type = 'error' })
            end
        elseif canSplitMove and isControlJustPressed(CONTROLS.split) then
            if ox_inventory:GetItemCount(shared.chipItemName) > 0 then
                action = 'split'
                break
            else
                lib.notify({ id = 'bj_funds', title = 'Blackjack', description = 'Not enough chips to split.', type = 'error' })
            end
        end

        Wait(0)
    end

    if seat.active then updateUI() end

    if action == 'hit' then
        playSeatGesture(PLAYER_DICT, ('request_card%s'):format(({ '', '_alt1', '_alt2' })[math.random(1, 3)]))
    elseif action == 'stand' then
        playSeatGesture(PLAYER_DICT, ({ 'decline_card_001', 'decline_card_alt1', 'decline_card_alt2' })[math.random(1, 3)])
    elseif action == 'double' then
        playSeatGesture(PLAYER_DICT, 'place_bet_double_down')
    elseif action == 'split' then
        playSeatGesture(PLAYER_DICT, 'request_card')
    end

    return action
end)

---@param entity integer
---@return vector3 seatCoords
---@return vector3 seatRot
---@return integer seatIndex
local function findClosestSeat(entity)
    local playerPos = GetEntityCoords(cache.ped)
    local closestDist = math.huge
    local closestPos, closestRot, closestIdx = vec3(0, 0, 0), vec3(0, 0, 0), 1

    for i = 1, 4 do
        local bone = GetEntityBoneIndexByName(entity, 'Chair_Base_0' .. i)
        if bone ~= -1 then
            local bp = GetWorldPositionOfEntityBone(entity, bone)
            local br = GetWorldRotationOfEntityBone(entity, bone)
            local d = #(playerPos - bp)
            if d < closestDist then
                closestDist = d
                closestPos, closestRot, closestIdx = bp, br, i
            end
        end
    end
    return closestPos, closestRot, closestIdx
end

local function sitEnterAnim()
    local playerPos = GetEntityCoords(cache.ped)
    local diff = { x = playerPos.x - seat.seatCoords.x, y = playerPos.y - seat.seatCoords.y }
    local angle = math.rad(seat.seatRot.z)
    local forward = { x = -math.sin(angle), y = math.cos(angle) }
    local dot = diff.x * forward.x + diff.y * forward.y
    local anim = dot < 0 and 'sit_enter_left' or 'sit_enter_right'

    local scene = NetworkCreateSynchronisedScene(
        seat.seatCoords.x, seat.seatCoords.y, seat.seatCoords.z,
        seat.seatRot.x, seat.seatRot.y, seat.seatRot.z,
        2, true, true, 1065353216, 0, 1065353216
    )
    NetworkAddPedToSynchronisedScene(cache.ped, scene, SHARED_PLAYER, anim, 2.0, -2.0, 13, 16, 1148846080, 0)
    NetworkStartSynchronisedScene(scene)

    local timeout = GetGameTimer() + 3000
    while GetGameTimer() < timeout do
        if HasAnimEventFired(cache.ped, -1424880317) then break end
        SetTableGamesCameraThisUpdate('CASINO_BLACKJACK_CAMERA')
        Wait(0)
    end

    if not seat.active then
        ClearPedTasksImmediately(cache.ped)
        return
    end

    local idleScene = NetworkCreateSynchronisedScene(
        seat.seatCoords.x, seat.seatCoords.y, seat.seatCoords.z,
        seat.seatRot.x, seat.seatRot.y, seat.seatRot.z,
        2, true, true, 1065353216, 0, 1065353216
    )
    NetworkAddPedToSynchronisedScene(cache.ped, idleScene, SHARED_PLAYER, 'idle_cardgames', 2.0, -2.0, 13, 16, 1148846080, 0)
    NetworkStartSynchronisedScene(idleScene)
end

local function sitExitAnim()
    if not lib.requestAnimDict(SHARED_PLAYER, 1500) then
        ClearPedTasks(cache.ped)
        return
    end

    local scene = NetworkCreateSynchronisedScene(
        seat.seatCoords.x, seat.seatCoords.y, seat.seatCoords.z,
        seat.seatRot.x, seat.seatRot.y, seat.seatRot.z,
        2, false, false, 1065353216, 0, 1065353216
    )
    NetworkAddPedToSynchronisedScene(cache.ped, scene, SHARED_PLAYER, 'sit_exit_left', 2.0, -2.0, 13, 16, 1148846080, 0)
    NetworkStartSynchronisedScene(scene)

    local duration = GetAnimDuration(SHARED_PLAYER, 'sit_exit_left')
    local waitMs = (duration > 0) and math.floor(duration * 800) or 1500
    Wait(waitMs)
    NetworkStopSynchronisedScene(scene)
    ClearPedTasks(cache.ped)
end

local FOCUS_CAM_PITCH = -72.0
local FOCUS_CAM_HEIGHT = 0.55
local FOCUS_CAM_FOV = 38.0

local function disableFocusCam()
    if DoesCamExist(focusCam) then
        RenderScriptCams(false, true, 350, true, false)
        DestroyCam(focusCam, false)
    end
    focusCam = 0
    focusCamOn = false
end

local function enableFocusCam()
    if not seat.active then return end
    local tableCoords = config.tables[seat.tableIdx] and config.tables[seat.tableIdx].coords
    if not tableCoords then return end

    local s = 5 - seat.seatNumber
    local arr = coords.cardOffsets[s]
    if not arr or #arr == 0 then return end

    local n = math.min(2, #arr)
    local ox, oy, oz = 0.0, 0.0, 0.0
    for i = 1, n do
        ox = ox + arr[i].x
        oy = oy + arr[i].y
        oz = oz + arr[i].z
    end
    ox, oy, oz = ox / n, oy / n, oz / n
    local center = GetObjectOffsetFromCoords(tableCoords.x, tableCoords.y, tableCoords.z, tableCoords.w, ox, oy, oz)

    local ax, ay = tableCoords.x - seat.seatCoords.x, tableCoords.y - seat.seatCoords.y
    local len = math.sqrt(ax * ax + ay * ay)
    if len > 0.001 then ax, ay = ax / len, ay / len end
    local heading = math.deg(math.atan(-ax, ay))
    local back = FOCUS_CAM_HEIGHT / math.tan(math.rad(-FOCUS_CAM_PITCH))

    focusCam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA',
        center.x - ax * back, center.y - ay * back, center.z + FOCUS_CAM_HEIGHT,
        FOCUS_CAM_PITCH, 0.0, heading, FOCUS_CAM_FOV, false, 2)
    SetCamActive(focusCam, true)
    RenderScriptCams(true, true, 350, true, false)
    focusCamOn = true
end

local function toggleFocusCam()
    if focusCamOn then
        disableFocusCam()
    else
        enableFocusCam()
    end
    updateUI()
end

local function resetLocalSession()
    hideInfo()
    shared.activeSeat = 'none'

    disableFocusCam()

    seat.active = false
    seat.phase = 'idle'
    seat.inRound = false
    seat.hand = {}
    seat.splitHand = nil
    seat.dealerHand = {}
    seat.selectedBet = 1
    seat.pendingBet = 0
    seat.roundBet = 0
    seat.hasLocalBetChips = false
    seat.tableBusy = false
    seat.tableEndTime = 0
    seat.leaving = false
end

AddEventHandler('rhd_casino:client:forceLeave', function()
    if not seat.active then return end
    resetLocalSession()
    ClearPedTasksImmediately(cache.ped)
end)

local function leaveSession()
    if not seat.active then return end
    if seat.leaving then return false end
    seat.leaving = true

    if seat.inRound then
        seat.leaving = false
        return false
    end

    if not lib.callback.await('rhd_casino_blackjack:callback:standUp', false) then
        seat.leaving = false
        updateUI()
        return false
    end

    resetLocalSession()
    sitExitAnim()

    return true
end

---@param tableIdx integer
---@param seatNumber integer
---@param sCoords vector3
---@param sRot vector3
---@param initialState string?
---@param initialTimeLeft number?
local function startSession(tableIdx, seatNumber, sCoords, sRot, initialState, initialTimeLeft)
    seat.active = true
    seat.tableIdx = tableIdx
    seat.seatNumber = seatNumber
    seat.seatCoords = sCoords
    seat.seatRot = sRot
    seat.phase = 'idle'
    seat.inRound = false
    seat.hand = {}
    seat.splitHand = nil
    seat.dealerHand = {}

    shared.activeSeat = 'blackjack'

    lib.requestAnimDict(SHARED_PLAYER, 1500)
    lib.requestAnimDict(PLAYER_DICT, 1500)

    sitEnterAnim()
    if not seat.active then return end
    updateUI()

    local stateOk, currentState, currentTimeLeft =
        lib.callback.await('rhd_casino_blackjack:callback:getState', false)

    if stateOk then
        initialState = currentState
        initialTimeLeft = currentTimeLeft
    end

    if initialState == 'betting' and (initialTimeLeft or 0) > 1 then
        seat.tableBusy = true
        CreateThread(function()
            runBettingUI(tableIdx, initialTimeLeft)
        end)
    end

    CreateThread(function()
        while seat.active do
            if seat.phase == 'idle' then updateUI() end
            Wait(1000)
        end
    end)

    CreateThread(function()
        while seat.active do
            for _, index in pairs(CONTROLS) do
                DisableControlAction(0, index, true)
            end

            if isControlJustPressed(CONTROLS.leave) then
                if seat.inRound then
                    lib.notify({
                        id = 'bj_no_leave',
                        title = 'Blackjack',
                        description = 'You cannot leave with chips on the table.',
                        type = 'error',
                    })
                else
                    if leaveSession() then
                        break
                    end
                end
            end

            if isControlJustPressed(CONTROLS.focusCam) and seat.inRound then
                toggleFocusCam()
            end

            if focusCamOn and not seat.inRound then
                disableFocusCam()
                updateUI()
            end

            if IsEntityDead(cache.ped) then
                if not leaveSession() then
                    TriggerServerEvent('rhd_casino_blackjack:server:leaveTable')
                    resetLocalSession()
                end
                break
            end

            Wait(0)
        end

        shared.activeSeat = 'none'
    end)
end

target:addModel({
    config.table_model.standard,
    config.table_model.exclusive,
    config.table_model.highstakes
}, {
    {
        label = 'Play Blackjack',
        icon = 'fa-solid fa-diamond',
        distance = 1.6,
        canInteract = function() return shared.activeSeat == 'none' end,
        onSelect = function(data)
            local entity = data.entity
            local sCoords, sRot, seatIdx = findClosestSeat(entity)

            local tableCoords = GetEntityCoords(entity)
            local tableIdx = lib.array.findIndex(config.tables, function(v)
                return #(vec3(v.coords.x, v.coords.y, v.coords.z) - tableCoords) < 1.5
            end)
            if not tableIdx then return end

            local ok, message, timeLeft = lib.callback.await('rhd_casino_blackjack:callback:sitDown', false, tableIdx, seatIdx)
            if not ok then
                lib.notify({
                    id = 'bj_sit_fail',
                    title = 'Blackjack',
                    description = message or 'Cannot sit at this seat right now.',
                    type = 'error',
                })
                return
            end

            startSession(tableIdx, seatIdx, sCoords, sRot, message, timeLeft)
        end,
    },
})

local function loadBlackjackTables()
    if blackjackTablesLoaded or blackjackTablesLoading then return end
    blackjackTablesLoading = true

    lib.requestAnimDict(DEALER_DICT, 25000)
    lib.requestAnimDict(SHARED_DEALER, 25000)
    lib.requestAnimDict(SHARED_PLAYER, 25000)
    lib.requestAnimDict(PLAYER_DICT, 25000)

    for i = 1, #config.tables do
        if not cacheEntities.tables[i] then
            local v = config.tables[i]
            lib.requestModel(v.model, 25000)

            local obj = CreateObjectNoOffset(v.model, v.coords.x, v.coords.y, v.coords.z, false, false, false)
            SetEntityRotation(obj, 0.0, 0.0, v.coords.w, 2, true)
            SetObjectTextureVariant(obj, v.color or 3)
            SetModelAsNoLongerNeeded(v.model)
            cacheEntities.tables[i] = obj

            local outfitPool = v.dealerOutfit
            local outfit = outfitPool[math.random(1, #outfitPool)]
            local dealerPed = spawnDealer[outfit](vector4(v.coords.x, v.coords.y, v.coords.z, v.coords.w + 180))
            Wait(0)

            local offset = IsPedMale(dealerPed)
                and vec3(-0.09, 0.7, 1.0)
                or  vec3(-0.04, 0.7, 1.0)
            local dpos = vec3(v.coords.x, v.coords.y, v.coords.z) + shared.rotateVec3(offset, v.coords.w)
            SetEntityCoordsNoOffset(dealerPed, dpos.x, dpos.y, dpos.z, false, false, false)

            local scene = CreateSynchronizedScene(v.coords.x, v.coords.y, v.coords.z - 0.025, 0.0, 0.0, v.coords.w, 2)
            TaskSynchronizedScene(dealerPed, scene, SHARED_DEALER, 'idle', 1000.0, -8.0, 4, 1, 1148846080, 0)

            cacheEntities.dealerPeds[i] = dealerPed
            ensureSlot(i)
        end
    end

    blackjackTablesLoaded = true
    blackjackTablesLoading = false
end

local function unloadBlackjackTables()
    if not blackjackTablesLoaded and not blackjackTablesLoading then return end
    blackjackTablesLoading = false
    blackjackTablesLoaded = false

    for i = 1, #config.tables do
        if cacheEntities.tables[i] then
            DeleteEntity(cacheEntities.tables[i])
            cacheEntities.tables[i] = nil
        end
        if cacheEntities.dealerPeds[i] then
            DeleteEntity(cacheEntities.dealerPeds[i])
            cacheEntities.dealerPeds[i] = nil
        end
        for tseat = 1, 4 do
            if cacheEntities.handObjs[i] and cacheEntities.handObjs[i][tseat] then
                for j = 1, #cacheEntities.handObjs[i][tseat] do DeleteEntity(cacheEntities.handObjs[i][tseat][j]) end
                cacheEntities.handObjs[i][tseat] = {}
            end
            if cacheEntities.chipPiles[i] and cacheEntities.chipPiles[i][tseat] then
                for j = 1, #cacheEntities.chipPiles[i][tseat] do DeleteEntity(cacheEntities.chipPiles[i][tseat][j]) end
                cacheEntities.chipPiles[i][tseat] = {}
            end
            if cacheEntities.chipPilesAlt[i] and cacheEntities.chipPilesAlt[i][tseat] then
                for j = 1, #cacheEntities.chipPilesAlt[i][tseat] do DeleteEntity(cacheEntities.chipPilesAlt[i][tseat][j]) end
                cacheEntities.chipPilesAlt[i][tseat] = {}
            end
        end
        if cacheEntities.dealerHandObjs[i] then
            for j = 1, #cacheEntities.dealerHandObjs[i] do DeleteEntity(cacheEntities.dealerHandObjs[i][j]) end
            cacheEntities.dealerHandObjs[i] = {}
        end
    end
end

useAreaHooks(function(inArea)
    if inArea then
        loadBlackjackTables()
    else
        unloadBlackjackTables()
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    unloadBlackjackTables()
    resetLocalSession()
end)

-- require 'casino.blackjack.dev.editor'
