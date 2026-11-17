local stressEffects = {
    enabled = true,
    screenShakeThreshold = 80,
    ragdollThreshold = 90
}

local function getEffectInterval(stress)
    if stress >= 100 then return math.random(3000, 5000)
    elseif stress >= 80 then return math.random(5000, 10000)
    elseif stress >= 60 then return math.random(10000, 30000)
    elseif stress >= 40 then return math.random(30000, 40000)
    else return math.random(40000, 60000) end
end

local function getBlurIntensity(stress)
    if stress >= 100 then return math.random(5000, 8000)
    elseif stress >= 80 then return math.random(3000, 5000)
    elseif stress >= 60 then return math.random(2000, 3000)
    else return math.random(1000, 2000) end
end

local function isPlayerDead()
    if playerState.isdead then return true end

    local metadata = QBPlayerData and QBPlayerData.metadata
    return metadata and (metadata.isdead or metadata.inlaststand) or false
end

local function stressThread()
    local tick = 5000

    if not (playerState.isLoggedIn and QBPlayerData and stressEffects.enabled) then
        return tick
    end

    if isPlayerDead() then
        return tick
    end

    local stress = QBPlayerData.metadata.stress or 0

    if stress >= stressEffects.ragdollThreshold then
        local blurTime = getBlurIntensity(stress)
        local interval = getEffectInterval(stress)

        TriggerScreenblurFadeIn(1000.0)
        Wait(blurTime)
        TriggerScreenblurFadeOut(1000.0)

        if isPlayerDead() then
            return tick
        end

        if not IsPedRagdoll(cache.ped) and IsPedOnFoot(cache.ped) and not IsPedSwimming(cache.ped) and not cache.vehicle then
            local timeout = math.random(2, 4) * 1750
            SetPedToRagdollWithFall(cache.ped, timeout, timeout, 1, GetEntityForwardVector(cache.ped), 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
        end

        tick = interval
    elseif stress >= stressEffects.screenShakeThreshold then
        TriggerScreenblurFadeIn(1000.0)
        Wait(getBlurIntensity(stress))
        TriggerScreenblurFadeOut(1000.0)
        tick = getEffectInterval(stress)
    end

    return tick
end

CreateThread(function()
    while true do
        Wait(stressThread())
    end
end)
