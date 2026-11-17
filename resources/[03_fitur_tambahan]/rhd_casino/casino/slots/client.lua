local animDict = ''
local machineCoords = nil
local machineRotation = nil
local machineForward = nil
local machineModel = nil
local machineNumber = nil
local scaleform = nil
local rendertargetId = nil
local betIndex = 1
local lastWin = 0
local isBetIdle = false
local betIdleTimer = 0
local audioSceneWasStopped = false
local slotSessionActive = false
local slotSessionClosing = false
local slotSessionId = 0
local spinInProgress = false
local config = require 'casino.slots.config'
local slotMachines = require 'casino.slots.data.machine'
local slotsData = require 'casino.slots.data.slots'

---@param eventHash integer
---@param timeoutMs? integer
---@return boolean
local function waitForAnimEvent(eventHash, timeoutMs)
    local timeout = GetGameTimer() + (timeoutMs or 3000)
    while slotSessionActive and GetGameTimer() < timeout do
        if HasAnimEventFired(cache.ped, eventHash) then
            return true
        end
        Wait(0)
    end
    return false
end

---@param soundName string
---@param entity? integer
---@param model? integer
local function playSound(soundName, entity, model)
    local soundId = GetSoundId()
    local ped = entity or cache.ped
    local mdl = model or machineModel
    local soundBank = slotMachines[mdl].sound
    PlaySoundFromEntity(soundId, soundName, ped, soundBank, false, 10)
    ReleaseSoundId(soundId)
end

---@param entity integer
local function cacheMachineData(entity)
    machineCoords = GetEntityCoords(entity)
    machineRotation = GetEntityRotation(entity)
    machineForward = GetEntityForwardVector(entity)
    machineModel = GetEntityModel(entity)
    machineNumber = tonumber(string.match(slotMachines[machineModel].scriptrt, '%d+'))
end

local function loadAnimDict()
    if IsPedMale(cache.ped) then
        animDict = 'anim_casino_a@amb@casino@games@slots@male'
    else
        animDict = 'anim_casino_a@amb@casino@games@slots@female'
    end
    lib.requestAnimDict(animDict)
end

local function playBaseIdleAnim()
    local anims = { 'base_idle_a', 'base_idle_b', 'base_idle_c', 'base_idle_d', 'base_idle_e', 'base_idle_f' }
    local anim = anims[math.random(1, #anims)]
    ---@cast machineCoords vector3
    ---@cast machineRotation vector3
    local scene = NetworkCreateSynchronisedScene(
        machineCoords.x, machineCoords.y, machineCoords.z,
        machineRotation.x, machineRotation.y, machineRotation.z,
        2, false, true, 1.0, 0.0, 1.0
    )
    NetworkAddPedToSynchronisedScene(cache.ped, scene, animDict, anim, 2.0, -1.5, 13, 16, 1000.0, 0)
    NetworkStartSynchronisedScene(scene)
end

local function playBetIdleAnim()
    local anims = { 'betidle_idle_a', 'betidle_idle_b', 'betidle_idle_c' }
    local anim = anims[math.random(1, #anims)]
    ---@cast machineCoords vector3
    ---@cast machineRotation vector3
    local scene = NetworkCreateSynchronisedScene(
        machineCoords.x, machineCoords.y, machineCoords.z,
        machineRotation.x, machineRotation.y, machineRotation.z,
        2, false, true, 1.0, 0.0, 1.0
    )
    NetworkAddPedToSynchronisedScene(cache.ped, scene, animDict, anim, 2.0, -1.5, 13, 16, 1000.0, 0)
    NetworkStartSynchronisedScene(scene)
    isBetIdle = true
    betIdleTimer = GetGameTimer() + 4000
end

local function playEnterAnim()
    local playerPos = GetEntityCoords(cache.ped)
    local diff = {
        x = playerPos.x - machineCoords.x,
        y = playerPos.y - machineCoords.y,
    }
    local distance = math.sqrt(diff.x * diff.x + diff.y * diff.y)
    ---@cast machineForward vector3
    local perp = {
        x = machineForward.y,
        y = -machineForward.x,
    }
    local dot = diff.x * perp.x + diff.y * perp.y
    local leftAnims = { 'enter_left', 'enter_left_short' }
    local rightAnims = { 'enter_right', 'enter_right_short' }
    local enterAnims = (dot < 0) and leftAnims or rightAnims
    local anim = (distance < 1.1 and enterAnims[2]) and enterAnims[2] or enterAnims[1]
    local scene = NetworkCreateSynchronisedScene(
        machineCoords.x, machineCoords.y, machineCoords.z,
        machineRotation.x, machineRotation.y, machineRotation.z,
        2, true, false, 1.0, 0.0, 1.0
    )
    NetworkAddPedToSynchronisedScene(cache.ped, scene, animDict, anim, 2.0, -1.5, 13, 16, 2.0, 0)
    NetworkStartSynchronisedScene(scene)
    waitForAnimEvent(-278874898)
end

local function playBetOneAnim()
    local anims, scene, anim
    if isBetIdle then
        anims = { 'betidle_press_betone_a', 'betidle_press_betone_b', 'betidle_press_betone_c' }
        scene = NetworkCreateSynchronisedScene(
            machineCoords.x, machineCoords.y, machineCoords.z,
            machineRotation.x, machineRotation.y, machineRotation.z,
            2, true, false, 1.0, 0.0, 1.0
        )
        anim = anims[math.random(1, #anims)]
        NetworkAddPedToSynchronisedScene(cache.ped, scene, animDict, anim, 8.0, -8.0, 13, 16, 1000.0, 0)
    else
        anims = { 'press_betone_a' }
        scene = NetworkCreateSynchronisedScene(
            machineCoords.x, machineCoords.y, machineCoords.z,
            machineRotation.x, machineRotation.y, machineRotation.z,
            2, true, false, 1.0, 0.0, 1.0
        )
        anim = anims[math.random(1, #anims)]
        NetworkAddPedToSynchronisedScene(cache.ped, scene, animDict, anim, 4.0, -8.0, 13, 16, 1000.0, 0)
    end
    NetworkStartSynchronisedScene(scene)
    waitForAnimEvent(-1424880317)
    playBetIdleAnim()
end

local function playBetMaxAnim()
    local anims, scene, anim
    if isBetIdle then
        anims = { 'betidle_press_betmax_a', 'betidle_press_betmax_b', 'betidle_press_betmax_c' }
        scene = NetworkCreateSynchronisedScene(
            machineCoords.x, machineCoords.y, machineCoords.z,
            machineRotation.x, machineRotation.y, machineRotation.z,
            2, true, false, 1.0, 0.0, 1.0
        )
        anim = anims[math.random(1, #anims)]
        NetworkAddPedToSynchronisedScene(cache.ped, scene, animDict, anim, 8.0, -8.0, 13, 16, 1000.0, 0)
    else
        anims = { 'press_betmax_a' }
        scene = NetworkCreateSynchronisedScene(
            machineCoords.x, machineCoords.y, machineCoords.z,
            machineRotation.x, machineRotation.y, machineRotation.z,
            2, true, false, 1.0, 0.0, 1.0
        )
        anim = anims[math.random(1, #anims)]
        NetworkAddPedToSynchronisedScene(cache.ped, scene, animDict, anim, 4.0, -8.0, 13, 16, 1000.0, 0)
    end
    NetworkStartSynchronisedScene(scene)
    waitForAnimEvent(-1424880317)
    playBetIdleAnim()
end

local function playExitAnim()
    local anims, scene, anim
    if not lib.requestAnimDict(animDict, 1500) then
        ClearPedTasks(cache.ped)
        return
    end
    if isBetIdle then
        anims = { 'betidle_exit_left', 'betidle_exit_right' }
        scene = NetworkCreateSynchronisedScene(
            machineCoords.x, machineCoords.y, machineCoords.z,
            machineRotation.x, machineRotation.y, machineRotation.z,
            2, true, false, 1.0, 0.0, 1.0
        )
        anim = anims[math.random(1, #anims)]
        NetworkAddPedToSynchronisedScene(cache.ped, scene, animDict, anim, 8.0, -8.0, 13, 16, 1000.0, 0)
    else
        anims = { 'exit_left', 'exit_right' }
        scene = NetworkCreateSynchronisedScene(
            machineCoords.x, machineCoords.y, machineCoords.z,
            machineRotation.x, machineRotation.y, machineRotation.z,
            2, true, false, 1.0, 0.0, 1.0
        )
        anim = anims[math.random(1, #anims)]
        NetworkAddPedToSynchronisedScene(cache.ped, scene, animDict, anim, 4.0, -8.0, 13, 16, 1000.0, 0)
    end
    NetworkStartSynchronisedScene(scene)
    local timeout = GetGameTimer() + 3000
    while GetGameTimer() < timeout do
        if HasAnimEventFired(cache.ped, -1424880317) then break end
        Wait(0)
    end
    NetworkStopSynchronisedScene(scene)
    ClearPedTasks(cache.ped)
end

local function playBetIdleToBaseTransition()
    local scene = NetworkCreateSynchronisedScene(
        machineCoords.x, machineCoords.y, machineCoords.z,
        machineRotation.x, machineRotation.y, machineRotation.z,
        2, true, false, 1.0, 0.0, 1.0
    )
    NetworkAddPedToSynchronisedScene(cache.ped, scene, animDict, 'betidle_to_base_transition', 2.0, -1.5, 13, 16, 1000.0, 0)
    NetworkStartSynchronisedScene(scene)
    waitForAnimEvent(-1424880317)
    playBaseIdleAnim()
end

local function playSpinAnim()
    local spinType
    if math.random(0, 3) == 0 then
        spinType = 'pull_spin'
    else
        spinType = 'press_spin'
    end
    if isBetIdle then
        spinType = ('betidle_%s'):format(spinType)
    end
    if math.random(0, 1) == 0 then
        spinType = ('%s_a'):format(spinType)
    else
        spinType = ('%s_b'):format(spinType)
    end
    local scene = NetworkCreateSynchronisedScene(
        machineCoords.x, machineCoords.y, machineCoords.z,
        machineRotation.x, machineRotation.y, machineRotation.z,
        2, true, false, 1.0, 0.0, 1.0
    )
    NetworkAddPedToSynchronisedScene(cache.ped, scene, animDict, spinType, 2.0, -1.5, 13, 16, 1000.0, 0)
    if string.find(spinType, 'pull') then
        ---@cast machineModel number
        NetworkAddMapEntityToSynchronisedScene(
            scene, machineModel,
            machineCoords.x, machineCoords.y, machineCoords.z,
            animDict, ('%s_slotmachine'):format(spinType),
            2.0, -1.5, 13.0
        )
    end
    NetworkStartSynchronisedScene(scene)
end

local function playSpinningAnim()
    local anims = { 'spinning_a', 'spinning_b', 'spinning_c' }
    local anim = anims[math.random(1, #anims)]
    local scene = NetworkCreateSynchronisedScene(
        machineCoords.x, machineCoords.y, machineCoords.z,
        machineRotation.x, machineRotation.y, machineRotation.z,
        2, false, true, 1.0, 0.0, 1.0
    )
    NetworkAddPedToSynchronisedScene(cache.ped, scene, animDict, anim, 2.0, -1.5, 13, 16, 1000.0, 0)
    NetworkStartSynchronisedScene(scene)
end

---@param animName string
local function playResultAnim(animName)
    local scene = NetworkCreateSynchronisedScene(
        machineCoords.x, machineCoords.y, machineCoords.z,
        machineRotation.x, machineRotation.y, machineRotation.z,
        2, true, false, 1.0, 0.0, 1.0
    )
    NetworkAddPedToSynchronisedScene(cache.ped, scene, animDict, animName, 2.0, -1.5, 13, 16, 1000.0, 0)
    NetworkStartSynchronisedScene(scene)
    CreateThread(function()
        Wait(0)
        while IsEntityPlayingAnim(cache.ped, animDict, animName, 3) do
            if HasAnimEventFired(cache.ped, -1424880317) then
                playBetIdleAnim()
                break
            end
            Wait(0)
        end
    end)
end

local function updateBetDisplay()
    BeginScaleformMovieMethod(scaleform --[[@as number]], 'SET_BET')
    ScaleformMovieMethodAddParamInt(slotsData[machineModel].BetAmounts[betIndex])
    EndScaleformMovieMethod()
end

local function updateLastWinDisplay()
    BeginScaleformMovieMethod(scaleform --[[@as number]], 'SET_LAST_WIN')
    ScaleformMovieMethodAddParamInt(lastWin)
    EndScaleformMovieMethod()
end

---@param message string
local function setScaleformMessage(message)
    BeginScaleformMovieMethod(scaleform --[[@as number]], 'SET_MESSAGE')
    BeginTextCommandScaleformString(message)
    EndTextCommandScaleformString()
    EndScaleformMovieMethod()
end

local function setupScaleform()
    scaleform = lib.requestScaleformMovie('SLOT_MACHINE', 20000)
    local renderTargetName = ('machine_%s'):format(slotMachines[machineModel].scriptrt)
    if not IsNamedRendertargetRegistered(renderTargetName) then
        RegisterNamedRendertarget(renderTargetName, false)
    end
    ---@cast machineModel number
    if not IsNamedRendertargetLinked(machineModel) then
        LinkNamedRendertarget(machineModel)
    end
    rendertargetId = GetNamedRendertargetRenderId(renderTargetName)
    BeginScaleformMovieMethod(scaleform, 'SET_THEME')
    ScaleformMovieMethodAddParamInt(slotMachines[machineModel].theme)
    EndScaleformMovieMethod()
    updateBetDisplay()
    updateLastWinDisplay()
    setScaleformMessage(('SLOTS_TITLE%s'):format(machineNumber))
end

local function cleanupScaleform()
    isBetIdle = false
    betIndex = 1
    lastWin = 0
    if animDict ~= '' then
        RemoveAnimDict(animDict)
    end
    StopAudioScene('dlc_vw_casino_slot_machines_playing')
    if scaleform and HasScaleformMovieLoaded(scaleform) then
        SetScaleformMovieAsNoLongerNeeded(scaleform)
    end
    local machine = machineModel and slotMachines[machineModel]
    if machine then
        ReleaseNamedRendertarget(('machine_%s'):format(machine.scriptrt))
    end
    scaleform = nil
    rendertargetId = nil
end

---@param playExit boolean
local function finishSlotSession(playExit)
    if slotSessionClosing then return end
    slotSessionClosing = true
    slotSessionActive = false
    spinInProgress = false

    TriggerServerEvent('rhd_casino_slots:server:stopSlotMachine')
    infoUI:remove('casino_slots_instructions')

    if playExit and machineCoords and machineRotation and animDict ~= '' then
        playExitAnim()
    else
        ClearPedTasks(cache.ped)
    end

    cleanupScaleform()
    playerState.interact_state = 'enabled'

    animDict = ''
    machineCoords = nil
    machineRotation = nil
    machineForward = nil
    machineModel = nil
    machineNumber = nil
    slotSessionClosing = false
end

AddEventHandler('rhd_casino:client:forceLeave', function()
    if not slotSessionActive then return end
    finishSlotSession(false)
end)

useAreaHooks(function(inArea)
    if inArea then
        lib.requestAudioBank('dlc_vinewood/casino_slot_machines_01', 10000)
        lib.requestAudioBank('dlc_vinewood/casino_slot_machines_02', 10000)
        lib.requestAudioBank('dlc_vinewood/casino_slot_machines_03', 10000)
        if IsAudioSceneActive('CHARACTER_CHANGE_IN_SKY_SCENE') then
            StopAudioScene('CHARACTER_CHANGE_IN_SKY_SCENE')
            audioSceneWasStopped = true
        end
    else
        ReleaseNamedScriptAudioBank('dlc_vinewood/casino_slot_machines_01')
        ReleaseNamedScriptAudioBank('dlc_vinewood/casino_slot_machines_02')
        ReleaseNamedScriptAudioBank('dlc_vinewood/casino_slot_machines_03')
        if audioSceneWasStopped then
            StartAudioScene('CHARACTER_CHANGE_IN_SKY_SCENE')
            audioSceneWasStopped = false
        end
    end
end)

---@param model integer|string
---@param coords vector3
local function startSlotMachine(model, coords)
    if slotSessionActive or slotSessionClosing then return end

    CreateThread(function()
        slotSessionActive = true
        spinInProgress = false
        slotSessionId = slotSessionId + 1
        local currentSessionId = slotSessionId
        playerState.interact_state = 'disabled'

        local entity = GetClosestObjectOfType(coords.x, coords.y, coords.z, 3.0, model, false, false, false)
        if not DoesEntityExist(entity) then
            lib.notify({
                id = 'slot_machine_not_found',
                title = 'Slot Machine Not Found',
                description = 'This slot machine does not exist. Please try another one.',
                type = 'error',
            })
            finishSlotSession(false)
            return
        end
        cacheMachineData(entity)
        loadAnimDict()
        setupScaleform()
        CreateThread(function()
            playSound('welcome_stinger')
            ---@cast scaleform number
            ---@cast rendertargetId number
            while slotSessionActive
                and slotSessionId == currentSessionId
                and scaleform
                and HasScaleformMovieLoaded(scaleform)
            do
                SetScaleformMovieToUseLargeRt(scaleform, true)
                SetTextRenderId(rendertargetId)
                SetScriptGfxDrawOrder(4)
                SetScriptGfxDrawBehindPausemenu(true)
                DrawScaleformMovie(scaleform, 0.401, 0.09, 0.805, 0.195, 255, 255, 255, 255, 0)
                SetTextRenderId(GetDefaultScriptRendertargetRenderId())
                SetTableGamesCameraThisUpdate('CASINO_SLOT_MACHINE_CAMERA')
                Wait(0)
            end
        end)
        if not IsAudioSceneActive('dlc_vw_casino_slot_machines_playing') then
            StartAudioScene('dlc_vw_casino_slot_machines_playing')
        end
        playEnterAnim()
        if not slotSessionActive or slotSessionId ~= currentSessionId then return end

        infoUI:show({
            id = 'casino_slots_instructions',
            title = 'Casino',
            icon = 'fas fa-gem',
            description = [[
            [kbd]↑[/kbd] Untuk menaikkan bet
            [kbd]↓[/kbd] Untuk menurunkan bet
            [kbd]F[/kbd] Untuk bet max
            [kbd]Enter[/kbd] Spin
            [kbd]Backspace[/kbd] Exit
            ]]
        })
        playBaseIdleAnim()
        while slotSessionActive and slotSessionId == currentSessionId do
            if IsControlJustReleased(0, config.Controls.play.stop) then
                finishSlotSession(true)
                break
            end
            if not spinInProgress and IsControlJustReleased(0, config.Controls.bet.up) then
                betIndex = betIndex + 1
                if betIndex > #slotsData[machineModel].BetAmounts then
                    betIndex = 1
                end
                updateBetDisplay()
                playBetOneAnim()
                playSound('place_bet')
            end
            if not spinInProgress and IsControlJustReleased(0, config.Controls.bet.down) then
                betIndex = betIndex - 1
                if betIndex < 1 then
                    betIndex = #slotsData[machineModel].BetAmounts
                end
                updateBetDisplay()
                playBetOneAnim()
                playSound('place_bet')
            end
            if not spinInProgress and IsControlJustReleased(0, config.Controls.maxBet) then
                betIndex = #slotsData[machineModel].BetAmounts
                updateBetDisplay()
                playBetMaxAnim()
                playSound('place_max_bet')
            end
            if not spinInProgress and IsControlJustReleased(0, config.Controls.spin) then
                spinInProgress = true
                local spinSessionId = currentSessionId
                local spinModel = machineModel
                local spinBetAmount = slotsData[spinModel].BetAmounts[betIndex]

                CreateThread(function()
                    playSpinAnim()
                    if isBetIdle then
                        isBetIdle = false
                    end
                    waitForAnimEvent(2044168827)
                    if not slotSessionActive or slotSessionId ~= spinSessionId then return end

                    playSound('start_spin')
                    playSpinningAnim()
                    playSound('spinning')
                    local winAmount, resultAnim = lib.callback.await(
                        'rhd_casino_slots:callback:startSpin', false,
                        spinModel,
                        spinBetAmount
                    )

                    if not slotSessionActive or slotSessionId ~= spinSessionId then return end

                    if winAmount then
                        lastWin = winAmount
                        updateLastWinDisplay()
                        playResultAnim(resultAnim)
                        local msgBase = 'SLOTS_MES'
                        if winAmount > 0 then
                            msgBase = msgBase .. 'P'
                        elseif winAmount == 0 then
                            msgBase = msgBase .. 'N'
                        end
                        local message = ('%s%s%02d'):format(msgBase, machineNumber, math.random(1, 16))
                        setScaleformMessage(message)
                    else
                        playBetIdleAnim()
                    end
                    spinInProgress = false
                end)
            end
            if not spinInProgress and isBetIdle and GetGameTimer() >= betIdleTimer then
                isBetIdle = false
                playBetIdleToBaseTransition()
            end
            Wait(0)
        end

        if slotSessionActive and slotSessionId == currentSessionId then
            finishSlotSession(false)
        end
    end)
end

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() or not slotSessionActive then return end
    finishSlotSession(false)
end)

local reelObjects = {}
local spinnerObjects = {}
local reelOffsets = { -0.115, 0.005, 0.125 }

---@param reelIndex integer
---@param machinePos number
---@param entityCoords vector3
---@param model integer
---@param reels number[]
---@param heading number
---@param nearbyPlayer number
local function stopReel(reelIndex, machinePos, entityCoords, model, reels, heading, nearbyPlayer)
    if DoesEntityExist(spinnerObjects[machinePos][reelIndex]) then
        DeleteObject(spinnerObjects[machinePos][reelIndex])
        local reelPos = GetObjectOffsetFromCoords(
            entityCoords.x, entityCoords.y, entityCoords.z,
            heading, reelOffsets[reelIndex], 0.047, 0.906
        )
        reelObjects[machinePos][reelIndex] = CreateObject(
            slotMachines[model].reelA,
            reelPos.x, reelPos.y, reelPos.z,
            false, false, false
        )
        FreezeEntityPosition(reelObjects[machinePos][reelIndex], true)
        SetEntityRotation(
            reelObjects[machinePos][reelIndex],
            reels[reelIndex] * 22.5, 0.0, heading,
            2, true
        )
        playSound('wheel_stop_clunk', nearbyPlayer, model)
    end
end

local slotModels = {
    'vw_prop_casino_slot_01a',
    'vw_prop_casino_slot_02a',
    'vw_prop_casino_slot_03a',
    'vw_prop_casino_slot_04a',
    'vw_prop_casino_slot_05a',
    'vw_prop_casino_slot_06a',
    'vw_prop_casino_slot_07a',
    'vw_prop_casino_slot_08a',
}
for i = 1, #slotModels do
    target:addModel(slotModels[i], {
        {
            label = 'Mainkan Mesin Slot',
            icon = 'fa-solid fa-coins',
            distance = 3.0,
            onSelect = function(data)
                local coords = GetEntityCoords(data.entity)
                local canUse = lib.callback.await('rhd_casino_slots:callback:canUse', false, coords)
                if canUse then
                    startSlotMachine(slotModels[i], coords)
                end
            end,
        }
    })
end

RegisterNetEvent('rhd_casino_slots:client:spinReels', function(reels, machinePos, model, winAmount, resultAnim, betAmount)
    if source == '' then return end
    if not reelObjects[machinePos] then
        reelObjects[machinePos] = {}
    end
    if not spinnerObjects[machinePos] then
        spinnerObjects[machinePos] = {}
    end
    for i = 1, #reelObjects[machinePos] do
        if DoesEntityExist(reelObjects[machinePos][i]) then
            DeleteObject(reelObjects[machinePos][i])
        end
    end
    local entity = GetClosestObjectOfType(machinePos.x, machinePos.y, machinePos.z, 3.0, model, false, false, false)
    if not DoesEntityExist(entity) then return end
    local _, closestPlayerPed = lib.getClosestPlayer(machinePos, 4.0, true)
    local entityCoords = GetEntityCoords(entity)
    local heading = GetEntityHeading(entity)
    for i = 1, 3 do
        local reelPos = GetObjectOffsetFromCoords(
            entityCoords.x, entityCoords.y, entityCoords.z,
            heading, reelOffsets[i], 0.047, 0.906
        )
        spinnerObjects[machinePos][i] = CreateObject(
            slotMachines[model].reelB,
            reelPos.x, reelPos.y, reelPos.z,
            false, false, false
        )
        FreezeEntityPosition(spinnerObjects[machinePos][i], true)
    end
    local endTime = GetGameTimer() + 6000
    while GetGameTimer() < endTime do
        for i = 1, #spinnerObjects[machinePos] do
            if DoesEntityExist(spinnerObjects[machinePos][i]) then
                SetEntityRotation(
                    spinnerObjects[machinePos][i],
                    GetEntityPitch(spinnerObjects[machinePos][i]) + 4.0,
                    0.0, heading, 2, true
                )
            end
        end
        local timeLeft = endTime - GetGameTimer()
        if timeLeft < math.random(3500, 4500) then
            stopReel(1, machinePos, entityCoords, model, reels, heading, closestPlayerPed)
        end
        if timeLeft < math.random(1500, 2500) then
            stopReel(2, machinePos, entityCoords, model, reels, heading, closestPlayerPed)
        end
        Wait(0)
    end
    stopReel(3, machinePos, entityCoords, model, reels, heading, closestPlayerPed)
    if winAmount > 0 then
        if string.find(resultAnim, 'big') then
            local jackpotMultiplier = 0
            local jackpotMultipliers = slotsData[model].Multipliers.jackpot
            if type(jackpotMultipliers) == 'table' then
                for i = 1, #jackpotMultipliers do
                    jackpotMultiplier = math.max(jackpotMultiplier, tonumber(jackpotMultipliers[i]) or 0)
                end
            else
                jackpotMultiplier = tonumber(jackpotMultipliers) or 0
            end
            local jackpotWin = jackpotMultiplier * betAmount
            if jackpotWin == winAmount then
                playSound('jackpot', closestPlayerPed, model)
            else
                playSound('big_win', closestPlayerPed, model)
            end
        else
            playSound('small_win', closestPlayerPed, model)
        end
    elseif winAmount == 0 then
        playSound('no_win', closestPlayerPed, model)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= cache.resource then return end
    ---@cast scaleform number
    if HasScaleformMovieLoaded(scaleform) then
        cleanupScaleform()
        ClearPedTasksImmediately(cache.ped)
    end
    for _, objects in pairs(spinnerObjects) do
        for i = 1, #objects do
            if DoesEntityExist(objects[i]) then
                DeleteObject(objects[i])
            end
        end
    end
    for _, objects in pairs(reelObjects) do
        for i = 1, #objects do
            if DoesEntityExist(objects[i]) then
                DeleteObject(objects[i])
            end
        end
    end
end)
