local isToggle = require 'config.client'.handsUpIsToggle
local handsupThreadActive = false
local lastHandsupTime = 0
local handsupCooldown = 500
---@type number?
local animationPed

---@return number
local function animPed()
    if animationPed and DoesEntityExist(animationPed) then
        return animationPed
    end

    return cache.ped
end

local function stopHandsup()
    local ped = animPed()

    if PState.handsup then
        TriggerServerEvent('sm_emote:server:setHandsup', false)
    end

    handsupThreadActive = false

    if IsEntityPlayingAnim(ped, 'random@mugging3', 'handsup_standing_base', 3) then
        StopAnimTask(ped, 'random@mugging3', 'handsup_standing_base', 8.0)
    end

    RemoveAnimDict('random@mugging3')
end

local QBCore

local function isPlayerDead()
    if PState.isdead or IsEntityDead(cache.ped) or GetEntityHealth(cache.ped) <= 0 then return true end
    if utils and utils.isDead and utils.isDead() then return true end

    if not QBCore then
        local ok, core = pcall(function() return exports['qb-core']:GetCoreObject() end)
        QBCore = ok and core or nil
    end

    if QBCore then
        local pd = QBCore.Functions.GetPlayerData()
        if pd and pd.metadata and (pd.metadata.isdead or pd.metadata.inlaststand) then
            return true
        end
    end

    return false
end

local function onPress()

    if isPlayerDead() or PState.naikSapi then
        return
    end

    -- Block handsup when player is handcuffed
    local ok, isCuffed = pcall(function() return exports.sm_policejob:IsHandcuffed() end)
    if ok and isCuffed then
        return
    end

    local currentTime = GetGameTimer()
    if currentTime - lastHandsupTime < handsupCooldown then
        return
    end

    if isToggle and PState.handsup then
        stopHandsup()
        lastHandsupTime = currentTime
        return
    end

    if GetVehiclePedIsEntering(cache.ped) ~= 0 then return end

    if cache.vehicle then
        local model = GetEntityModel(cache.vehicle)
        local onBike = IsThisModelABike(model)
        
        if not onBike then
            return
        end
    end

    if handsupThreadActive or PState.handsup then
        stopHandsup()
        Wait(50)
    end

    local onBike = false
    if cache.vehicle then
        local model = GetEntityModel(cache.vehicle)
        onBike = IsThisModelABike(model)
    end

    if not lib.requestAnimDict('random@mugging3') then
        return
    end

    local ped = animPed()

    TaskPlayAnim(ped, 'random@mugging3', 'handsup_standing_base', 2.0, 2.0, -1, 49, 0, false, (onBike and 4127 or false), false)

    TriggerServerEvent('sm_emote:server:setHandsup', true)

    handsupThreadActive = true
    lastHandsupTime = currentTime

    local needsReset = false
    CreateThread(function()
        local timeout = 0
        local maxTimeout = 100

        while not IsEntityPlayingAnim(ped, 'random@mugging3', 'handsup_standing_base', 3) and timeout < maxTimeout do
            Wait(100)
            timeout = timeout + 1
        end

        if timeout >= maxTimeout then
            stopHandsup()
            return
        end

        local confirmed = false
        local waited = 0

        while handsupThreadActive do
            Wait(10)

            if PState.handsup then
                confirmed = true
            elseif confirmed then
                stopHandsup()
                break
            else
                waited = waited + 10

                if waited >= 1000 then
                    stopHandsup()
                    break
                end
            end

            if not IsEntityPlayingAnim(ped, 'random@mugging3', 'handsup_standing_base', 3) and not IsPedRagdoll(ped) and not needsReset then
                stopHandsup()
                break
            end

            if cache.vehicle then
                DisableControlAction(0, 59, true)
            end

            DisableControlAction(0, 25, true)
            DisablePlayerFiring(cache.playerId, true)

            if IsPedRagdoll(ped) then
                needsReset = true
            end

            if (isToggle and not IsEntityPlayingAnim(ped, 'random@mugging3', 'handsup_standing_base', 3)) or (needsReset and not IsPedRagdoll(ped)) then
                TaskPlayAnim(ped, 'random@mugging3', 'handsup_standing_base', 2.0, 2.0, -1, 49, 0, false, onBike and 4127 or false, false)
                needsReset = false
            end
        end

        handsupThreadActive = false
        if isToggle then
            StopAnimTask(ped, 'random@mugging3', 'handsup_standing_base', 8.0)
            RemoveAnimDict('random@mugging3')
        end
    end)
end

local function onRelease()
    if not PState.handsup or isToggle then return end
    stopHandsup()
end

---@param ped? number
local function setAnimationPed(ped)
    if handsupThreadActive or PState.handsup then
        stopHandsup()
    end

    animationPed = ped and DoesEntityExist(ped) and ped or nil
end

exports('SetAnimationPed', setAnimationPed)

_ENV.handsup = {
    onPress = onPress,
    onRelease = onRelease,
    stop = stopHandsup
}