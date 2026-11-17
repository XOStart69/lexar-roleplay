local isCrouched = false
local isCrawling = false
local inAction = false
local proneType = 'onfront'
local lastKeyPress = 0
local forceEndProne = false
local wasCrouched = false

local CRAWL_SETTING = require 'config.client'.crawlSetting
local CROUCH_SETTING = require 'config.client'.crouchSetting

local function changeHeadingSmooth(amount, time)
    local times = math.abs(amount)
    local test = amount / times
    local wait = time / times

    for _i = 1, times do
        Wait(wait)
        SetEntityHeading(cache.ped, GetEntityHeading(cache.ped) + test)
    end
end

local function playAnimOnce(animDict, animName, blendInSpeed, blendOutSpeed, duration, startTime)
    lib.playAnim(cache.ped, animDict, animName, blendInSpeed or 2.0, blendOutSpeed or 2.0, duration or -1, 0,
        startTime or 0.0, false, false, false)
    RemoveAnimDict(animDict)
end

local function canPlayerCrouchCrawl()
    return not LocalPlayer.state.rtxNoCrouch
        and IsPedOnFoot(cache.ped)
        and not IsPedJumping(cache.ped)
        and not IsPedFalling(cache.ped)
        and not IsPedInjured(cache.ped)
        and not IsPedInMeleeCombat(cache.ped)
        and not IsPedRagdoll(cache.ped)
end

local function resetCrouch()
    ResetPedStrafeClipset(cache.ped)
    ResetPedWeaponMovementClipset(cache.ped)
    SetPedMaxMoveBlendRatio(cache.ped, 1.0)
    SetPedCanPlayAmbientAnims(cache.ped, true)

    local walkstyle = kvp.getString("walkstyle")

    if walkstyle then
        lib.requestAnimSet(walkstyle, 1500)
        SetPedMovementClipset(cache.ped, walkstyle, 0.5)
        RemoveClipSet(walkstyle)
    else
        ResetPedMovementClipset(cache.ped, 0.5)
    end

    RemoveAnimSet('move_ped_crouched')
end

local function crouchLoop()
    while isCrouched do
        if not canPlayerCrouchCrawl() then
            isCrouched = false
            break
        end

        if CROUCH_SETTING.overideStealthMode and GetPedStealthMovement(cache.ped) ~= 0 then
            SetPedStealthMovement(cache.ped, false, 'DEFAULT_ACTION')
        end

        if utils.isAiming() then
            SetPedMaxMoveBlendRatio(cache.ped, 0.15)
        end

        DisableControlAction(0, 36, true)
        SetPedCanPlayAmbientAnims(cache.ped, false)

        if IsPedUsingActionMode(cache.ped) == 1 then
            SetPedUsingActionMode(cache.ped, false, -1, 'DEFAULT_ACTION')
        end

        DisableFirstPersonCamThisFrame()

        if CROUCH_SETTING.fpsMode == true then
            DisableControlAction(2, 25, true)
        end

        Wait(0)
    end

    TriggerEvent('crouch_crawl:onCrouch', false)

    resetCrouch()
end

local function StartCrouch()
    isCrouched = true

    lib.requestAnimSet('move_ped_crouched')
    if GetPedStealthMovement(cache.ped) ~= 0 then
        SetPedStealthMovement(cache.ped, false, 'DEFAULT_ACTION')
        Wait(100)
    end

    if GetFollowPedCamViewMode() == 4 then
        SetFollowPedCamViewMode(0) -- THIRD_PERSON_NEAR
    end

    SetPedMovementClipset(cache.ped, 'move_ped_crouched', 0.6)
    SetPedStrafeClipset(cache.ped, 'move_ped_crouched_strafing')

    TriggerEvent('crouch_crawl:onCrouch', true)
    CreateThread(crouchLoop)
end

---@return boolean success
local function attemptCrouch()
    if canPlayerCrouchCrawl() and IsPedHuman(cache.ped) then
        StartCrouch()
        return true
    else
        return false
    end
end

---@param padIndex integer
---@param control integer
local function disableControlUntilReleased(padIndex, control)
    CreateThread(function()
        while IsDisabledControlPressed(padIndex, control) do
            DisableControlAction(padIndex, control, true)
            Wait(0)
        end
    end)
end

local function crouchKeyPressed()
    if not PState.canEmote then return end

    if inAction then
        return
    end

    if IsPauseMenuActive() or IsNuiFocused() then
        return
    end

    if isCrouched then
        isCrouched = false

        local crouchKey = GetControlInstructionalButton(0, `+crouch` | 0x80000000, false)
        local lookBehindKey = GetControlInstructionalButton(0, 26, false) -- INPUT_LOOK_BEHIND

        if crouchKey == lookBehindKey then
            disableControlUntilReleased(0, 26) -- INPUT_LOOK_BEHIND
        end

        return
    end

    if not canPlayerCrouchCrawl() or not IsPedHuman(cache.ped) then
        return
    end

    local crouchKey = GetControlInstructionalButton(0, `+crouch` | 0x80000000, false)
    local lookBehindKey = GetControlInstructionalButton(0, 26, false) -- INPUT_LOOK_BEHIND
    local duckKey = GetControlInstructionalButton(0, 36, false) -- INPUT_DUCK

    if crouchKey == lookBehindKey then
        disableControlUntilReleased(0, 26) -- INPUT_LOOK_BEHIND
    end

    if crouchKey == duckKey then
        if CROUCH_SETTING.overideStealthMode then
            DisableControlAction(0, 36, true) -- Disable INPUT_DUCK this frame
        elseif not PState.isProne then
            local timer = GetGameTimer()

            if GetPedStealthMovement(cache.ped) ~= 0 and timer - lastKeyPress < 1000 then
                DisableControlAction(0, 36, true) -- Disable INPUT_DUCK this frame
                lastKeyPress = 0
            else
                lastKeyPress = timer
                return
            end
        end
    end

    StartCrouch()

    if PState.isProne then
        inAction = true
        PState:set('isProne', true, false)
        playAnimOnce('get_up@directional@transition@prone_to_knees@crawl', 'front', nil, nil, 780)
        Wait(780)
        inAction = false
    end
end


-- Crawling --
---@return boolean
local function chouldPlayerDiveToCrawl()
    return IsPedRunning(cache.ped) or IsPedSprinting(cache.ped)
end

---Stops the player from being prone
---@param force boolean If forced then no exit anim is played
local function stopPlayerProne(force)
    forceEndProne = force
    PState:set('isProne', false, false)
end

---@param blendInSpeed number|nil
local function playIdleCrawlAnim(heading, blendInSpeed)
    local playerCoords = GetEntityCoords(cache.ped)

    heading = heading or GetEntityHeading(cache.ped)
    TaskPlayAnimAdvanced(cache.ped, 'move_crawl', proneType..'_fwd', playerCoords.x, playerCoords.y, playerCoords.z, 0.0, 0.0, heading, blendInSpeed or 2.0, 2.0, -1, 2, 1.0, false, false)
end

---@param forceEnd boolean
local function playExitCrawlAnims(forceEnd)
    if forceEnd then return end
    inAction = true

    local animDict, animName, waitTime
    if proneType == 'onfront' then
        animDict, animName, waitTime = 'get_up@directional@transition@prone_to_knees@crawl', 'front', 780
    else
        animDict, animName, waitTime = 'get_up@directional@transition@prone_to_seated@crawl', 'back', 950
    end

    playAnimOnce(animDict, animName, nil, nil, waitTime)

    if not isCrouched then
        Wait(waitTime)
        playAnimOnce('get_up@directional@movement@from_'..(proneType == 'onfront' and 'knees' or 'seated')..'@standard', 'getup_l_0', nil, nil, 1300)
    end
end

---@param type string
---@param direction string
local function crawl(type, direction)
    isCrawling = true

    lib.playAnim(cache.ped, 'move_crawl', type..'_'..direction, 8.0, -8.0, -1, 2, 0.0, false, false, false)

    local time = {
        onfront = {
            fwd = 820,
            bwd = 990
        },
        onback = {
            fwd = 1200,
            bwd = 1200
        }
    }

    SetTimeout(time[type][direction], function()
        isCrawling = false
    end)
end

local function crawlFlip()
    inAction = true
    local heading = GetEntityHeading(cache.ped)

    proneType = proneType == 'onfront' and 'onback' or 'onfront'

    if proneType == 'onback' then
        playAnimOnce('get_up@directional_sweep@combat@pistol@front', 'front_to_prone', 2.0)
        changeHeadingSmooth(-18.0, 3600)
    else
        playAnimOnce('move_crawlprone2crawlfront', 'back', 2.0, nil, -1)
        changeHeadingSmooth(12.0, 1700)
    end

    playIdleCrawlAnim(heading + 180.0)
    Wait(400)
    inAction = false
end

local function crawlLoop()
    Wait(400)

    while PState.isProne do

        if not canPlayerCrouchCrawl() or IsEntityInWater(cache.ped) then
            ClearPedTasks(cache.ped)
            stopPlayerProne(true)
            break
        end

        local forward, backwards = IsControlPressed(0, 32), IsControlPressed(0, 33) -- INPUT_MOVE_UP_ONLY, INPUT_MOVE_DOWN_ONLY
        
        if not isCrawling then
            if forward then -- Forward
                crawl(proneType, 'fwd')
            elseif backwards then -- Back
                crawl(proneType, 'bwd')
            end
        end

        -- Moving left/right
        if IsControlPressed(0, 34) then -- INPUT_MOVE_LEFT_ONLY
            if isCrawling then
                local headingDiff = forward and 1.0 or -1.0
                SetEntityHeading(cache.ped, GetEntityHeading(cache.ped) + headingDiff)
            else
                inAction = true
                if proneType == 'onfront' then
                    local playerCoords = GetEntityCoords(cache.ped)
                    TaskPlayAnimAdvanced(cache.ped, 'move_crawlprone2crawlfront', 'left', playerCoords.x, playerCoords.y, playerCoords.z, 0.0, 0.0, GetEntityHeading(cache.ped), 2.0, 2.0, -1, 2, 0.1, false, false)
                    changeHeadingSmooth(-10.0, 300)
                    Wait(700)
                else
                    playAnimOnce('get_up@directional_sweep@combat@pistol@left', 'left_to_prone')
                    changeHeadingSmooth(25.0, 400)
                    playIdleCrawlAnim(cache.ped)
                    Wait(600)
                end
                inAction = false
            end
        elseif IsControlPressed(0, 35) then -- INPUT_MOVE_RIGHT_ONLY
            if isCrawling then
                local headingDiff = backwards and 1.0 or -1.0
                SetEntityHeading(cache.ped, GetEntityHeading(cache.ped) + headingDiff)
            else
                inAction = true
                if proneType == 'onfront' then
                    local playerCoords = GetEntityCoords(cache.ped)
                    TaskPlayAnimAdvanced(cache.ped, 'move_crawlprone2crawlfront', 'right', playerCoords.x, playerCoords.y, playerCoords.z, 0.0, 0.0, GetEntityHeading(cache.ped), 2.0, 2.0, -1, 2, 0.1, false, false)
                    changeHeadingSmooth(10.0, 300)
                    Wait(700)
                else
                    playAnimOnce('get_up@directional_sweep@combat@pistol@right', 'right_to_prone')
                    changeHeadingSmooth(-25.0, 400)
                    playIdleCrawlAnim(cache.ped)
                    Wait(600)
                end
                inAction = false
            end
        end

        if not isCrawling then
            if IsControlPressed(0, 22) then -- INPUT_JUMP
                crawlFlip()
            end
        end

        Wait(0)
    end

    TriggerEvent('crouch_crawl:onCrawl', false)

    playExitCrawlAnims(forceEndProne)

    isCrawling = false
    inAction = false
    forceEndProne = false
    proneType = 'onfront'
    SetPedConfigFlag(cache.ped, 48, false)

    RemoveAnimDict('move_crawl')
    RemoveAnimDict('move_crawlprone2crawlfront')
end

local function CrawlKeyPressed()
    if not PState.canEmote then return end

    if inAction then
        return
    end

    if IsPauseMenuActive() or IsNuiFocused() then
        return
    end

    if PState.isProne then
        PState:set('isProne', false, false)
        return
    end

    if PState.isInAnimation then
        Emote.cancel()
    end

    wasCrouched = false

    if isCrouched then
        isCrouched = false
        wasCrouched = true
    end

    if not canPlayerCrouchCrawl() or IsEntityInWater(cache.ped) or not IsPedHuman(cache.ped) then
        return
    end

    inAction = true

    if Pointing then
        Pointing = false
    end

    if PState.handsup then
        return
    end

    if utils.isInActionWithErrorMessage({isProne = true}) then
        return
    end

    PState:set('isProne', true, false)
    SetPedConfigFlag(cache.ped, 48, true)

    if GetPedStealthMovement(cache.ped) ~= 0 then
        SetPedStealthMovement(cache.ped, false, 'DEFAULT_ACTION')
        Wait(100)
    end

    lib.requestAnimDict('move_crawl')
    lib.requestAnimDict('move_crawlprone2crawlfront')

    if chouldPlayerDiveToCrawl() then
        playAnimOnce('explosions', 'react_blown_forwards', nil, 3.0)
        Wait(1100)
    elseif wasCrouched then
        playAnimOnce('amb@world_human_sunbathe@male@front@enter', 'enter', nil, nil, -1, 0.3)
        Wait(1500)
    else
        playAnimOnce('amb@world_human_sunbathe@male@front@enter', 'enter')
        Wait(3000)
    end

    if canPlayerCrouchCrawl() and not IsEntityInWater(cache.ped) then
        playIdleCrawlAnim(nil, 3.0)
    end

    TriggerEvent('crouch_crawl:onCrawl', true)

    inAction = false
    CreateThread(crawlLoop)
end


if CROUCH_SETTING.enable then
    RegisterCommand('crouch', function()
        if not PState.canEmote or PState.isdead then return end

        if isCrouched then
            isCrouched = false
            return
        end

        attemptCrouch()
    end, false)

    TriggerEvent('chat:addSuggestion', '/crouch', locale('crouch'))
end

if CRAWL_SETTING.enable then
    RegisterCommand('crawl', function() CrawlKeyPressed() end, false)
    TriggerEvent('chat:addSuggestion', '/crawl', locale('crawl'))
end

_ENV.stance = {
    crouch = crouchKeyPressed,
    crawl = CrawlKeyPressed
}

---@return boolean
local function IsPlayerCrouched()
	return isCrouched
end
exportWrapper('IsPlayerCrouched', IsPlayerCrouched)

---@return boolean
local function IsPlayerProne()
	return PState.isProne
end
exportWrapper('IsPlayerProne', IsPlayerProne)

---@return boolean
local function IsPlayerCrawling()
	return isCrawling
end
exportWrapper('IsPlayerCrawling', IsPlayerCrawling)

---@return string
local function GetPlayerProneType()
	return proneType
end
exportWrapper('GetPlayerProneType', GetPlayerProneType)

exportWrapper('StopPlayerProne', stopPlayerProne)
