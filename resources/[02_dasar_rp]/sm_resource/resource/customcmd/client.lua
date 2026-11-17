local config = localmodule 'config.shared'
local weaponEffect = localmodule 'config.recoil'
local QBCore = exports['qb-core']:GetCoreObject()

local activeScreenEffects = {}
local homeMadeMilkUses = 0
local activeStaminaBoost = false
local staminaBoostEndTime = 0
local activeSpeedBoost = false
local speedBoostEndTime = 0
local activeNoRecoil = false
local noRecoilEndTime = 0
local activeScreenShakes = {}
local microphoneProp = nil
local isHoldingMicrophone = false
local isMicrophoneActive = false
local currentMicrophoneRadius = nil
local markerActive = false
local markerTimeout = 0
local kedipCooldown = false
local _ipDD = IsPedDoingDriveby
local _sgCV = SetGameplayCamRelativePitch
local _gfPV = GetFollowPedCamViewMode
local _ggCP = GetGameplayCamRelativePitch

local activeHoldStress = false
local holdStressEndTime = 0

--poison
local activePoisonEffect = false
local poisonEndTime = 0
local poisonThreads = {}

--blackout
local activeBlackout = false
local blackoutEndTime = 0
local blackoutThreads = {}

-- Helper Functions
local function loadAnimDict(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(100)
    end
end

local function loadModel(model)
    if HasModelLoaded(model) then return end
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(10)
    end
end

local function applyScreenEffect(effectName, customDuration)
    if effectName then
        StartScreenEffect(effectName, 3.0, 0)
        
        local duration = customDuration or config.screenEffectDuration
        local effectId = effectName .. "_" .. GetGameTimer()
        
        activeScreenEffects[effectId] = {
            name = effectName,
            startTime = GetGameTimer(),
            originalDuration = duration,
            endTime = GetGameTimer() + duration
        }
        
        SetTimeout(duration, function()
            if activeScreenEffects[effectId] then
                StopScreenEffect(effectName)
                activeScreenEffects[effectId] = nil
            end
        end)
    end
end

local function applyStaminaBoost(duration)
    if activeStaminaBoost then
        staminaBoostEndTime = GetGameTimer() + duration
        lib.notify({
            title = 'Stamina Boost',
            description = 'Stamina boost diperpanjang!',
            type = 'success'
        })
        return
    end
    
    activeStaminaBoost = true
    staminaBoostEndTime = GetGameTimer() + duration
    
    lib.notify({
        title = 'Stamina Boost',
        description = 'Stamina boost aktif',
        type = 'success'
    })
    
    CreateThread(function()
        while activeStaminaBoost do
            local ped = PlayerPedId()
            
            if GetGameTimer() >= staminaBoostEndTime then
                activeStaminaBoost = false
                lib.notify({
                    title = 'Stamina Boost',
                    description = 'Stamina boost habis!',
                    type = 'inform'
                })
                break
            end
            
            RestorePlayerStamina(PlayerId(), 1.0)
            ResetPlayerStamina(PlayerId())
            
            Wait(100)
        end
    end)
end

local function applySpeedBoost(duration)
    if activeSpeedBoost then
        speedBoostEndTime = GetGameTimer() + duration
        lib.notify({
            title = 'Speed Boost',
            description = 'Speed boost diperpanjang!',
            type = 'success'
        })
        return
    end
    
    activeSpeedBoost = true
    speedBoostEndTime = GetGameTimer() + duration
    
    lib.notify({
        title = 'Speed Boost',
        description = 'Speed boost aktif untuk 3 menit!',
        type = 'success'
    })
    
    CreateThread(function()
        while activeSpeedBoost do
            local playerId = PlayerId()
            
            if GetGameTimer() >= speedBoostEndTime then
                activeSpeedBoost = false
                SetRunSprintMultiplierForPlayer(playerId, 1.0)
                SetPedMoveRateOverride(PlayerPedId(), 1.0)
                lib.notify({
                    title = 'Speed Boost',
                    description = 'Speed boost habis!',
                    type = 'inform'
                })
                break
            end
            
            SetRunSprintMultiplierForPlayer(playerId, 1.49)
            SetPedMoveRateOverride(PlayerPedId(), 1.3)
            
            Wait(100)
        end
    end)
end

-- local function applyNoRecoil(duration)
--     if activeNoRecoil then
--         noRecoilEndTime = GetGameTimer() + duration
--         lib.notify({
--             title = 'No Recoil',
--             description = 'No recoil diperpanjang!',
--             type = 'success'
--         })
--         return
--     end
    
--     activeNoRecoil = true
--     noRecoilEndTime = GetGameTimer() + duration
    
--     lib.notify({
--         title = 'No Recoil',
--         description = 'No recoil aktif untuk 15 menit!',
--         type = 'success'
--     })
    
--     CreateThread(function()
--         while activeNoRecoil do
--             if GetGameTimer() >= noRecoilEndTime then
--                 activeNoRecoil = false
--                 lib.notify({
--                     title = 'No Recoil',
--                     description = 'No recoil habis!',
--                     type = 'inform'
--                 })
--                 break
--             end
--             Wait(1000)
--         end
--     end)
-- end

local function applyHoldStress(duration)
    if activeHoldStress then
        holdStressEndTime = GetGameTimer() + duration
        lib.notify({
            title = 'Hold Stress',
            description = 'Hold stress diperpanjang!',
            type = 'success'
        })
        return
    end

    activeHoldStress = true
    holdStressEndTime = GetGameTimer() + duration

    lib.notify({
        title = 'Hold Stress',
        description = 'Hold stress aktif untuk 10 menit!',
        type = 'success'
    })

    CreateThread(function()
        while activeHoldStress do
            if GetGameTimer() >= holdStressEndTime then
                activeHoldStress = false
                lib.notify({
                    title = 'Hold Stress',
                    description = 'Hold stress habis!',
                    type = 'inform'
                })
                break
            end
            Wait(1000)
        end
    end)
end

local function applyScreenShake(shakeConfig, itemName)
    local shakeId = itemName .. "_" .. GetGameTimer()
    
    activeScreenShakes[shakeId] = {
        intensity = shakeConfig.intensity,
        interval = shakeConfig.interval,
        endTime = GetGameTimer() + shakeConfig.duration,
        active = true
    }
    
    CreateThread(function()
        while activeScreenShakes[shakeId] and activeScreenShakes[shakeId].active do
            if GetGameTimer() >= activeScreenShakes[shakeId].endTime then
                activeScreenShakes[shakeId] = nil
                break
            end
            
            ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', activeScreenShakes[shakeId].intensity)
            Wait(activeScreenShakes[shakeId].interval)
        end
    end)
end

local function applyInstantEffects(itemConfig)
    local ped = PlayerPedId()
    
    if itemConfig.armorGain then
        local currentArmor = GetPedArmour(ped)
        if currentArmor < itemConfig.maxArmor then
            local newArmor = math.min(currentArmor + itemConfig.armorGain, itemConfig.maxArmor)
            SetPedArmour(ped, newArmor)
        end
    end
    
    if itemConfig.stressGain then
        TriggerTokenEvent('sm_hud:server:addStress', itemConfig.stressGain)
    end
    
    if itemConfig.stressReduce then
        TriggerTokenEvent('sm_hud:server:removeStress', itemConfig.stressReduce)
    end
    
    if itemConfig.healthGain then
        SetEntityHealth(ped, GetEntityHealth(ped) + itemConfig.healthGain)
    end

    if itemConfig.speedBoost and itemConfig.speedDuration then
        applySpeedBoost(itemConfig.speedDuration)
    end
    
    if itemConfig.staminaBoost and itemConfig.staminaDuration then
        applyStaminaBoost(itemConfig.staminaDuration)
    end
    
    -- if itemConfig.noRecoil and itemConfig.noRecoilDuration then
    --     applyNoRecoil(itemConfig.noRecoilDuration)
    -- end

    if itemConfig.holdStress and itemConfig.holdStressDuration then
        applyHoldStress(itemConfig.holdStressDuration)
    end
    
end

local function stopPoisonEffect()
    activePoisonEffect = false
    poisonEndTime = 0
    
    for _, threadId in pairs(poisonThreads) do
        if threadId then threadId.active = false end
    end
    poisonThreads = {}
    
    StopScreenEffect("DeathFailMPIn")
    
    lib.notify({
        title = 'Poison',
        description = 'Efek racun telah hilang!',
        type = 'success'
    })
end

local function applyPoisonEffect(poisonConfig)
    if activePoisonEffect then
        poisonEndTime = GetGameTimer() + poisonConfig.totalDuration
        lib.notify({
            title = 'Poison',
            description = 'Racun diperkuat! Durasi direset.',
            type = 'error'
        })
        return
    end
    
    activePoisonEffect = true
    poisonEndTime = GetGameTimer() + poisonConfig.totalDuration
    
    lib.notify({
        title = 'Nightdew Poison',
        description = 'Kamu merasakan sesuatu yang aneh dalam tubuhmu...',
        type = 'error'
    })
    
    -- Main damage tick thread
    local damageThread = { active = true }
    poisonThreads.damage = damageThread
    
    CreateThread(function()
        while damageThread.active and activePoisonEffect do
            if GetGameTimer() >= poisonEndTime then
                stopPoisonEffect()
                break
            end
            
            Wait(poisonConfig.tickInterval)
            
            if not activePoisonEffect then break end
            
            local ped = PlayerPedId()
            local currentHealth = GetEntityHealth(ped)
            local newHealth = currentHealth - poisonConfig.damagePerTick
            
            if newHealth <= 100 then
                SetEntityHealth(ped, 0)
                activePoisonEffect = false
                lib.notify({
                    title = 'Poison',
                    description = 'Racun Nightdew telah membunuhmu...',
                    type = 'error'
                })
                break
            end
            
            SetEntityHealth(ped, newHealth)
        end
    end)
    
    -- Stagger animation thread
    local staggerThread = { active = true }
    poisonThreads.stagger = staggerThread
    
    CreateThread(function()
        Wait(poisonConfig.staggerInterval)
        while staggerThread.active and activePoisonEffect do
            if not activePoisonEffect then break end
            
            local ped = PlayerPedId()
            if not IsPedInAnyVehicle(ped, false) and not IsPedRagdoll(ped) then
                loadAnimDict(poisonConfig.staggerAnim.dict)
                TaskPlayAnim(ped, poisonConfig.staggerAnim.dict, poisonConfig.staggerAnim.name, 
                    4.0, -4.0, poisonConfig.staggerAnim.duration, poisonConfig.staggerAnim.flag, 
                    0, false, false, false)
                
                SetTimeout(poisonConfig.staggerAnim.duration, function()
                    ClearPedTasks(PlayerPedId())
                end)
            end
            
            Wait(poisonConfig.staggerInterval)
        end
    end)
    
    -- Cough animation thread
    local coughThread = { active = true }
    poisonThreads.cough = coughThread
    
    CreateThread(function()
        Wait(poisonConfig.coughInterval / 2)
        while coughThread.active and activePoisonEffect do
            if not activePoisonEffect then break end
            
            local ped = PlayerPedId()
            if not IsPedInAnyVehicle(ped, false) then
                loadAnimDict(poisonConfig.coughAnim.dict)
                TaskPlayAnim(ped, poisonConfig.coughAnim.dict, poisonConfig.coughAnim.name, 
                    8.0, -8.0, poisonConfig.coughAnim.duration, poisonConfig.coughAnim.flag, 
                    0, false, false, false)
                
                SetTimeout(poisonConfig.coughAnim.duration, function()
                    ClearPedTasks(PlayerPedId())
                end)
            end
            
            Wait(poisonConfig.coughInterval)
        end
    end)
    
    -- Screen pulse effect thread
    if poisonConfig.screenPulse then
        local pulseThread = { active = true }
        poisonThreads.pulse = pulseThread
        
        CreateThread(function()
            Wait(poisonConfig.screenPulse.interval)
            while pulseThread.active and activePoisonEffect do
                if not activePoisonEffect then break end
                
                StartScreenEffect(poisonConfig.screenPulse.effect, 1.0, false)
                Wait(poisonConfig.screenPulse.duration)
                StopScreenEffect(poisonConfig.screenPulse.effect)
                
                Wait(poisonConfig.screenPulse.interval)
            end
        end)
    end
    
    -- Blur effect thread
    if poisonConfig.blurEffect and poisonConfig.blurEffect.enabled then
        local blurThread = { active = true }
        poisonThreads.blur = blurThread
        
        CreateThread(function()
            Wait(poisonConfig.blurEffect.interval)
            while blurThread.active and activePoisonEffect do
                if not activePoisonEffect then break end
                
                TriggerScreenblurFadeIn(poisonConfig.blurEffect.intensity)
                Wait(poisonConfig.blurEffect.duration)
                TriggerScreenblurFadeOut(0.0)
                
                Wait(poisonConfig.blurEffect.interval)
            end
        end)
    end
end

local function stopBlackoutEffect(blackoutConfig)
    activeBlackout = false
    blackoutEndTime = 0

    for _, threadData in pairs(blackoutThreads) do
        if threadData then threadData.active = false end
    end
    blackoutThreads = {}

    if blackoutConfig then
        StopScreenEffect(blackoutConfig.screenEffect)
        if blackoutConfig.timecycle then
            ClearTimecycleModifier()
        end
    end

    ClearPedTasks(PlayerPedId())

    lib.notify({
        title = 'Purification Potion',
        description = 'Penglihatanmu kembali normal.',
        type = 'success'
    })
end

local function applyBlackoutEffect(blackoutConfig)
    if activeBlackout then
        blackoutEndTime = GetGameTimer() + blackoutConfig.totalDuration
        return
    end

    activeBlackout = true
    blackoutEndTime = GetGameTimer() + blackoutConfig.totalDuration

    lib.notify({
        title = 'Purification Potion',
        description = 'Pandanganmu menggelap dan dadamu terasa sesak...',
        type = 'error'
    })

    -- Layar gelap: screen effect + timecycle, bukan fade (biar masih samar kelihatan)
    local screenThread = { active = true }
    blackoutThreads.screen = screenThread

    StartScreenEffect(blackoutConfig.screenEffect, 0, true)
    if blackoutConfig.timecycle then
        SetTimecycleModifier(blackoutConfig.timecycle)
        SetTimecycleModifierStrength(blackoutConfig.timecycleStrength or 1.0)
    end

    CreateThread(function()
        while screenThread.active and activeBlackout do
            if GetGameTimer() >= blackoutEndTime then
                stopBlackoutEffect(blackoutConfig)
                break
            end

            Wait(250)
        end
    end)

    -- Batuk terus-menerus selama efek aktif
    local coughThread = { active = true }
    blackoutThreads.cough = coughThread

    CreateThread(function()
        local coughAnim = blackoutConfig.coughAnim
        loadAnimDict(coughAnim.dict)

        while coughThread.active and activeBlackout do
            local ped = PlayerPedId()

            if not IsPedInAnyVehicle(ped, false) and not IsPedRagdoll(ped) then
                TaskPlayAnim(ped, coughAnim.dict, coughAnim.name,
                    8.0, -8.0, coughAnim.duration, coughAnim.flag,
                    0, false, false, false)
            end

            Wait(coughAnim.duration)

            if not (coughThread.active and activeBlackout) then break end

            ClearPedTasks(PlayerPedId())
            Wait(blackoutConfig.coughInterval)
        end
    end)
end

local function applyAntidote(antidoteConfig)
    if not activePoisonEffect then
        lib.notify({
            title = 'Info',
            description = 'Kamu tidak sedang teracuni.',
            type = 'inform'
        })
        return
    end
    
    stopPoisonEffect()
    
    lib.notify({
        title = 'Blood Purifying Essence',
        description = 'Racun berhasil dinetralisir! Tubuhmu mulai pulih.',
        type = 'success'
    })
end

local function loadPropModel(propModel)
    local propHash = GetHashKey(propModel)
    if not IsModelValid(propHash) then return end
    local ok = pcall(lib.requestModel, propHash, 5000)
    if not ok then return end
    return propHash
end

local function createProp(propModel, coords)
    local propHash = loadPropModel(propModel)
    if not propHash then return end
    local obj = CreateObject(propHash, coords.x, coords.y, coords.z, true, true, true)
    SetModelAsNoLongerNeeded(propHash)
    if obj == 0 then return end
    return obj
end

local function attachPropToPed(ped, prop, boneIndex, placement)
    AttachEntityToEntity(
        prop, ped, GetPedBoneIndex(ped, boneIndex),
        placement.x, placement.y, placement.z,
        placement.rx, placement.ry, placement.rz,
        true, true, false, true, 1, true
    )
end

local function deleteProp(prop)
    if DoesEntityExist(prop) then
        DeleteEntity(prop)
    end
end

-- Enhanced Consumables
local function startEnhancedConsumable(itemType)
    local ped = PlayerPedId()
    local itemConfig = config.enhancedItems[itemType]
    
    if not itemConfig then
        lib.notify({
            title = 'Error',
            description = 'Item konfigurasi tidak ditemukan!',
            type = 'error'
        })
        return
    end
    
    if itemConfig.armorGain and GetPedArmour(ped) >= itemConfig.maxArmor then
        lib.notify({
            title = 'Error',
            description = 'Armor sudah maksimal!',
            type = 'error'
        })
        return
    end
    
    local attachedProp = nil
    
    if itemConfig.prop then
        local pedCoords = GetEntityCoords(ped)
        attachedProp = createProp(itemConfig.prop.model, pedCoords)
        if attachedProp then
            attachPropToPed(ped, attachedProp, itemConfig.prop.bone, itemConfig.prop.placement)
        end
    end
    
    loadAnimDict(itemConfig.animDict)
    local animFlag = itemConfig.animFlag or 49
    TaskPlayAnim(ped, itemConfig.animDict, itemConfig.animName, 8.0, -8.0, -1, animFlag, 0, false, false, false)
    
    if itemConfig.cutAnimation and itemConfig.cutAnimation.enabled then
        CreateThread(function()
            Wait(itemConfig.cutAnimation.cutTime)
            if itemConfig.cutAnimation.forceStop then
                ClearPedTasks(ped)
            end
        end)
    end
    
    local success = lib.progressBar({
        duration = itemConfig.duration,
        label = itemConfig.progressLabel,
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = false,
            car = false,
            combat = true
        },
        anim = { 
            dict = itemConfig.animDict, 
            clip = itemConfig.animName 
        }
    })
    
    ClearPedTasks(ped)
    if attachedProp then
        deleteProp(attachedProp)
    end
    
    if not success then
        lib.notify({
            title = 'Cancelled',
            description = 'Kamu membatalkan penggunaan ' .. itemConfig.label .. '!',
            type = 'error'
        })
        return
    end
    
    TriggerTokenEvent('enhanced:server:finalize', itemType)
end

local function applyEnhancedEffects(itemType)
    local itemConfig = config.enhancedItems[itemType]
    if not itemConfig then return end
    
    if itemConfig.screenEffect then
        local effectDuration = itemConfig.screenEffectDuration or config.screenEffectDuration
        applyScreenEffect(itemConfig.screenEffect, effectDuration)
    end
    
    if itemConfig.applyInstantEffect then
        applyInstantEffects(itemConfig)
    end

    if itemConfig.poison and itemConfig.poison.enabled then
        applyPoisonEffect(itemConfig.poison)
    end
    
    if itemConfig.antidote and itemConfig.antidote.enabled then
        applyAntidote(itemConfig.antidote)
    end

    if itemConfig.blackout and itemConfig.blackout.enabled then
        applyBlackoutEffect(itemConfig.blackout)
    end
    
    if itemConfig.screenShake and itemConfig.screenShake.enabled then
        applyScreenShake(itemConfig.screenShake, itemType)
    end
    
    lib.notify({
        title = 'Success',
        description = 'Berhasil menggunakan ' .. itemConfig.label .. '!',
        type = 'success'
    })
end

RegisterNetEvent('enhanced:start', function(itemType)
    if source ~= 65535 then return end
    if not config.enhancedItems[itemType] then return end
    
    startEnhancedConsumable(itemType)
end)

RegisterNetEvent('enhanced:applyEffects', function(itemType)
    if source ~= 65535 then return end
    if not config.enhancedItems[itemType] then return end
    
    applyEnhancedEffects(itemType)
end)

-- Regular Consumables
local function useConsumable(itemType)
    local ped = PlayerPedId()
    local itemConfig = config.consumables[itemType]
    
    if not itemConfig then return end
    
    if GetPedArmour(ped) >= itemConfig.maxArmor then
        lib.notify({
            title = 'Error',
            description = 'Armor sudah maksimal!',
            type = 'error'
        })
        return
    end
    
    loadAnimDict(itemConfig.animDict)
    TaskPlayAnim(ped, itemConfig.animDict, itemConfig.animName, 8.0, -8.0, -1, 49, 0, false, false, false)
    
    local success = lib.progressBar({
        duration = itemConfig.duration,
        label = itemConfig.progressLabel,
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = false,
            car = false,
            combat = true
        },
        anim = { 
            dict = itemConfig.animDict, 
            clip = itemConfig.animName 
        }
    })
    
    ClearPedTasks(ped)
    
    if not success then
        lib.notify({
            title = 'Cancelled',
            description = 'Kamu membatalkan minum ' .. itemConfig.label .. '!',
            type = 'error'
        })
        return
    end
    
    TriggerTokenEvent('consumable:server:finalize', itemType)
end

RegisterNetEvent('consumable:start', function(itemType)
    if source ~= 65535 then return end
    
    local validItems = {
        powerbooster = true,
        bodybooster = true,
    }
    if not validItems[itemType] then return end
    
    useConsumable(itemType)
end)

RegisterNetEvent('consumable:applyArmor', function(itemType)
    if source ~= 65535 then return end
    
    local itemConfig = config.consumables[itemType]
    if not itemConfig then return end
    
    local ped = PlayerPedId()
    local currentArmor = GetPedArmour(ped)
    local newArmor = math.min(currentArmor + itemConfig.armorGain, itemConfig.maxArmor)
    SetPedArmour(ped, newArmor)
    
    if itemConfig.addStress then
        TriggerTokenEvent('sm_hud:server:addStress', itemConfig.addStress)
    end
    
    if itemConfig.applyDrunkEffect then
        applyScreenEffect("DrugsMichaelAliensFightIn", config.drunkEffectDuration)
        SetTimecycleModifier("spectator5")
        SetTimeout(config.drunkEffectDuration, function()
            ClearTimecycleModifier()
        end)
    end
end)

RegisterNetEvent('consumable:boxmakanan:use', function()
    local ped = PlayerPedId()
    local itemConfig = config.consumables.boxmakanan
    
    loadAnimDict(itemConfig.animDict)
    TaskPlayAnim(ped, itemConfig.animDict, itemConfig.animName, 8.0, -8.0, -1, 49, 0, false, false, false)
    
    local success = lib.progressBar({
        duration = itemConfig.duration,
        label = itemConfig.progressLabel,
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = false,
            car = true,
            combat = true
        },
        anim = {
            dict = itemConfig.animDict,
            clip = itemConfig.animName
        }
    })
    
    ClearPedTasks(ped)
    
    if success then
        lib.callback.await('consumable:boxmakanan:removeItem', false)
    else
        lib.notify({
            title = 'Cancelled',
            description = 'Kamu membatalkan aksi membuka!',
            type = 'error'
        })
    end
end)

-- Armor Items
local function startArmorUse(armorType)
    local ped = PlayerPedId()
    local currentArmor = GetPedArmour(ped)
    local armorConfig = config.armor[armorType]
    
    if not armorConfig then return end
    
    if currentArmor >= 90 then
        lib.notify({
            title = 'Error',
            description = 'Armor sudah maksimal!',
            type = 'error'
        })
        return
    end
    
    local disableOptions = {
        move = false,
        car = false,
        combat = armorConfig.allowCombat == false
    }
    
    local animDict = armorConfig.anim and armorConfig.anim.dict or config.armorAnimDict
    local animClip = armorConfig.anim and armorConfig.anim.clip or config.armorAnimName

    loadAnimDict(animDict)
    TaskPlayAnim(ped, animDict, animClip, 8.0, -8.0, -1, 49, 0, false, false, false)

    local success = lib.progressBar({
        duration = armorConfig.duration,
        label = config.armorProgressLabel,
        useWhileDead = false,
        canCancel = true,
        disable = disableOptions,
        anim = {
            dict = animDict,
            clip = animClip
        },
        prop = armorConfig.prop or config.armorProp
    })
    
    ClearPedTasks(ped)
    
    if not success then
        lib.notify({
            title = 'Cancelled',
            description = 'Kamu membatalkan pemakaian armor!',
            type = 'error'
        })
        return
    end
    
    TriggerTokenEvent('armor:server:finalize', armorType)
end

local function applyArmorEffects(armorType)
    local ped = PlayerPedId()
    local currentArmor = GetPedArmour(ped)
    local armorConfig = config.armor[armorType]
    
    if not armorConfig then return end
    
    local newArmor = math.min(currentArmor + armorConfig.armorGain, 90)
    SetPedArmour(ped, newArmor)
end

RegisterNetEvent('armor:client:start', function(armorType)
    if source ~= 65535 then return end
    if not config.armor[armorType] then return end
    
    startArmorUse(armorType)
end)

RegisterNetEvent('armor:client:applyEffects', function(armorType)
    if source ~= 65535 then return end
    if not config.armor[armorType] then return end
    
    applyArmorEffects(armorType)
end)

-- Homemade Milk
local function useHomeMadeMilk()
    local ped = PlayerPedId()
    local milkConfig = config.homemademilk
    
    loadAnimDict(milkConfig.animDict)
    TaskPlayAnim(ped, milkConfig.animDict, milkConfig.animName, 8.0, -8.0, -1, 49, 0, false, false, false)
    
    local success = lib.progressBar({
        duration = milkConfig.duration,
        label = milkConfig.progressLabel,
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = false,
            car = false,
            combat = true
        },
        anim = { 
            dict = milkConfig.animDict, 
            clip = milkConfig.animName 
        }
    })
    
    ClearPedTasks(ped)
    
    if not success then
        lib.notify({
            title = 'Cancelled',
            description = 'Kamu membatalkan minum Homemade Milk!',
            type = 'error'
        })
        return
    end
    
    lib.callback.await('homemademilk:removeItem', false)
    
    local hasActiveEffects = false
    
    for _ in pairs(activeScreenEffects) do
        hasActiveEffects = true
        break
    end
    
    if not hasActiveEffects and not activeStaminaBoost and not activeSpeedBoost and not activeNoRecoil then
        local hasShake = false
        for _ in pairs(activeScreenShakes) do
            hasShake = true
            break
        end
        if not hasShake then
            lib.notify({
                title = 'Warning',
                description = 'Kamu tidak sedang dalam efek apapun! Susu terbuang sia-sia.',
                type = 'error'
            })
            return
        end
    end
    
    homeMadeMilkUses = homeMadeMilkUses + 1
    
    if homeMadeMilkUses >= milkConfig.requiredUses then
        for effectId, effectData in pairs(activeScreenEffects) do
            StopScreenEffect(effectData.name)
        end
        activeScreenEffects = {}
        
        for shakeId, _ in pairs(activeScreenShakes) do
            activeScreenShakes[shakeId] = nil
        end
        
        lib.notify({
            title = 'Success',
            description = 'Semua efek obat-obatan berhasil dihilangkan setelah ' .. milkConfig.requiredUses .. 'x minum susu!',
            type = 'success'
        })
        
        homeMadeMilkUses = 0
    else
        local remaining = milkConfig.requiredUses - homeMadeMilkUses
        lib.notify({
            title = 'Progress',
            description = 'Progress: ' .. homeMadeMilkUses .. '/' .. milkConfig.requiredUses .. ' - Butuh ' .. remaining .. ' susu lagi untuk menghilangkan semua efek!',
            type = 'inform'
        })
    end
end

RegisterNetEvent('homemademilk:client:use', useHomeMadeMilk)

-- Microphone
local function spawnMicrophoneProp()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local micConfig = config.microphone
    
    loadModel(micConfig.prop.model)
    
    microphoneProp = CreateObject(micConfig.prop.model, coords.x, coords.y, coords.z, true, true, false)
    
    AttachEntityToEntity(
        microphoneProp, ped,
        GetPedBoneIndex(ped, micConfig.prop.bone),
        micConfig.prop.pos.x, micConfig.prop.pos.y, micConfig.prop.pos.z,
        micConfig.prop.rot.x, micConfig.prop.rot.y, micConfig.prop.rot.z,
        true, true, false, true, 1, true
    )
    
    SetModelAsNoLongerNeeded(micConfig.prop.model)
end

local function deleteMicrophoneProp()
    if microphoneProp and DoesEntityExist(microphoneProp) then
        DeleteEntity(microphoneProp)
        microphoneProp = nil
    end
end

local function playMicrophoneAnimation()
    local ped = PlayerPedId()
    local micConfig = config.microphone
    
    loadAnimDict(micConfig.animation.dict)
    TaskPlayAnim(ped, micConfig.animation.dict, micConfig.animation.anim, 8.0, 8.0, -1, micConfig.animation.flag, 0, false, false, false)
    
    spawnMicrophoneProp()
    isHoldingMicrophone = true
end

local function stopMicrophoneAnimation()
    if not isHoldingMicrophone then return end
    
    local ped = PlayerPedId()
    ClearPedTasks(ped)
    deleteMicrophoneProp()
    isHoldingMicrophone = false
end

local function drawProximityMarker(radius)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local vehicle = GetVehiclePedIsIn(ped, false)
    
    local zOffset = -1.0
    if vehicle ~= 0 then
        local model = GetEntityModel(vehicle)
        local minDim = GetModelDimensions(model)
        zOffset = minDim.z + 0.5
    end
    
    DrawMarker(
        1, coords.x, coords.y, coords.z + zOffset,
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        radius * 2.0, radius * 2.0, 0.5,
        0, 255, 0, 100,
        true, true, 2, false, nil, nil, false
    )
end

local function createProximityRangeMarker(radius)
    markerTimeout = 3
    
    if not markerActive then
        markerActive = true
        
        CreateThread(function()
            while markerTimeout > 0 do
                Wait(0)
                drawProximityMarker(radius)
            end
            markerActive = false
        end)
        
        CreateThread(function()
            while markerTimeout > 0 do
                Wait(1000)
                markerTimeout = markerTimeout - 1
            end
        end)
    end
end

local function toggleMicrophone()
    if isMicrophoneActive then
        exports['pma-voice']:clearProximityOverride()
        currentMicrophoneRadius = nil
        isMicrophoneActive = false
        stopMicrophoneAnimation()
        lib.notify({
            title = 'Microphone',
            description = 'Microphone dimatikan',
            type = 'error'
        })
        lib.callback.await('microphone:setInactive', false)
        return
    end
    
    playMicrophoneAnimation()
    Wait(500)
    
    local input = lib.inputDialog('Microphone Settings', {
        {
            type = 'slider',
            label = 'Voice Range',
            description = 'Atur jarak radius microphone (1-100 meters)',
            required = true,
            default = currentMicrophoneRadius or 15,
            min = config.microphone.minRadius,
            max = config.microphone.maxRadius,
            step = 1
        }
    })

    if not input then 
        stopMicrophoneAnimation()
        return 
    end
    
    local radius = tonumber(input[1])
    if radius then
        local success = lib.callback.await('microphone:setRadius', false, radius)
        if success then
            lib.notify({
                title = 'Microphone',
                description = 'Microphone diaktifkan dengan radius ' .. radius .. ' meters',
                type = 'success'
            })
        end
    else
        stopMicrophoneAnimation()
    end
end

RegisterNetEvent('microphone:toggle', toggleMicrophone)

RegisterNetEvent('microphone:updateRadius', function(radius)
    currentMicrophoneRadius = radius
    isMicrophoneActive = true
    
    exports['pma-voice']:overrideProximityRange(radius, true)
    createProximityRangeMarker(radius)
end)

-- Vehicle Repair Kits
local function getNearbyVehicle()
    local ped = PlayerPedId()
    
    if IsPedInAnyVehicle(ped, false) then
        return GetVehiclePedIsIn(ped, false)
    else
        local coords = GetEntityCoords(ped)
        return lib.getClosestVehicle(coords, 5.0, false)
    end
end

local function validateVehicle(vehicle, repairType)
    local kitConfig = config.vehicleRepair[repairType]
    
    if not vehicle then
        lib.notify({
            title = kitConfig.label,
            description = kitConfig.messages.noVehicle,
            type = 'error',
            duration = 3000
        })
        return false
    end
    
    if not DoesEntityExist(vehicle) then
        lib.notify({
            title = kitConfig.label,
            description = kitConfig.messages.invalidVehicle,
            type = 'error',
            duration = 3000
        })
        return false
    end
    
    return true
end

RegisterNetEvent('vehiclekit:client:useBodykit', function()
    local vehicle = getNearbyVehicle()
    local kitConfig = config.vehicleRepair.bodykit
    
    if not validateVehicle(vehicle, 'bodykit') then return end
    
    local bodyHealth = GetVehicleBodyHealth(vehicle)
    if bodyHealth >= 1000.0 then
        lib.notify({
            title = kitConfig.label,
            description = kitConfig.messages.noNeedRepair,
            type = 'inform',
            duration = 3000
        })
        return
    end
    
    local ped = PlayerPedId()
    TaskStartScenarioInPlace(ped, kitConfig.scenario, 0, true)
    
    if lib.progressBar({
        duration = kitConfig.progressDuration,
        label = kitConfig.progressLabel,
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true
        }
    }) then
        local burstTires = {}
        for i = 0, 7 do
            burstTires[i] = IsVehicleTyreBurst(vehicle, i, false) or IsVehicleTyreBurst(vehicle, i, true)
        end
        local originalEngineHealth = GetVehicleEngineHealth(vehicle)
        
        SetVehicleFixed(vehicle)
        SetVehicleDirtLevel(vehicle, 0.0)
        WashDecalsFromVehicle(vehicle, 1.0)
        RemoveDecalsFromVehicle(vehicle)
        
        for i = 0, 7 do
            if burstTires[i] then
                SetVehicleTyreBurst(vehicle, i, true, 1000.0)
            end
        end
        SetVehicleEngineHealth(vehicle, originalEngineHealth)
        
        lib.callback.await('vehiclekit:removeBodykit', false)
    else
        lib.notify({
            title = kitConfig.label,
            description = kitConfig.messages.cancelled,
            type = 'error',
            duration = 3000
        })
    end
    
    ClearPedTasks(ped)
end)

RegisterNetEvent('vehiclekit:client:useEnginekit', function()
    local vehicle = getNearbyVehicle()
    local kitConfig = config.vehicleRepair.enginekit
    
    if not validateVehicle(vehicle, 'enginekit') then return end
    
    local engineHealth = GetVehicleEngineHealth(vehicle)
    if engineHealth >= 1000.0 then
        lib.notify({
            title = kitConfig.label,
            description = kitConfig.messages.noNeedRepair,
            type = 'inform',
            duration = 3000
        })
        return
    end
    
    local ped = PlayerPedId()
    
    loadAnimDict(kitConfig.animDict)
    TaskPlayAnim(ped, kitConfig.animDict, kitConfig.animName, 8.0, -8.0, -1, 49, 0, false, false, false)
    
    local success = lib.progressBar({
        duration = kitConfig.progressDuration,
        label = kitConfig.progressLabel,
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true
        },
        anim = {
            dict = kitConfig.animDict,
            clip = kitConfig.animName
        }
    })
    
    ClearPedTasks(ped)
    
    if success then
        local currentHealth = GetVehicleEngineHealth(vehicle)
        local newHealth = math.min(1000.0, currentHealth + kitConfig.repairAmount)
        
        SetVehicleEngineHealth(vehicle, newHealth)
        SetVehicleEngineOn(vehicle, true, true, false)
        
        local healthPercentage = math.floor((newHealth / 1000) * 100)
        lib.callback.await('vehiclekit:removeEnginekit', false, healthPercentage)
    else
        lib.notify({
            title = kitConfig.label,
            description = kitConfig.messages.cancelled,
            type = 'error',
            duration = 3000
        })
    end
    
    RemoveAnimDict(kitConfig.animDict)
end)

lib.onCache('vehicle', function(value, oldValue)
    local isMotorcycle = GetVehicleClass(value) == 8
    if not isMotorcycle then return end

    SetPedHelmet(cache.ped, false)
    RemovePedHelmet(cache.ped, true)
end)

lib.onCache('ped', function(value)
    if value then
        SetPedConfigFlag(value, 35, false)
    end
end)

-- Vehicle Teleport
local function EnumerateVehicles()
    return coroutine.wrap(function()
        local handle, vehicle = FindFirstVehicle()
        local success
        repeat
            coroutine.yield(vehicle)
            success, vehicle = FindNextVehicle(handle)
        until not success
        EndFindVehicle(handle)
    end)
end

local function FindAvailableSeat(vehicle)
    local maxSeats = GetVehicleMaxNumberOfPassengers(vehicle)
    for seat = 0, maxSeats - 1 do
        if IsVehicleSeatFree(vehicle, seat) then
            return seat
        end
    end
    return nil
end

local function EnterVehicle(vehicle, seat, notifySuccess, notifyForced)
    local ped = PlayerPedId()
    local actualSeat = seat or 0
    
    TaskWarpPedIntoVehicle(ped, vehicle, actualSeat)
    
    local notifyType = seat and 'success' or 'warning'
    local message = seat and notifySuccess or notifyForced
    
    lib.notify({
        title = seat and 'Sukses' or 'Penuh, Masuk Paksa!',
        description = message,
        type = notifyType
    })
    
    print("Vehicle ID: " .. vehicle .. " Seat: " .. actualSeat)
end

RegisterNetEvent('xonx:enterNearestVehicle', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local closestVehicle, closestDistance = nil, 50.0

    for vehicle in EnumerateVehicles() do
        local distance = #(coords - GetEntityCoords(vehicle))
        if distance < closestDistance then
            closestDistance = distance
            closestVehicle = vehicle
        end
    end

    if closestVehicle and closestVehicle ~= 0 then
        local availableSeat = FindAvailableSeat(closestVehicle)
        EnterVehicle(
            closestVehicle, 
            availableSeat,
            'Kamu telah teleport ke kendaraan terdekat di kursi ' .. (availableSeat or 0),
            'Kendaraan penuh! Masuk paksa ke kursi penumpang (seat 0).'
        )
    else
        lib.notify({
            title = 'Gagal',
            description = 'Tidak ada kendaraan terdekat!',
            type = 'error'
        })
    end
end)

RegisterNetEvent('xonx:enterVehicleOfPlayer', function(targetId)
    local targetPlayer = GetPlayerFromServerId(targetId)
    if not targetPlayer or targetPlayer == -1 then
        lib.notify({
            title = 'Gagal',
            description = 'ID pemain tidak valid!',
            type = 'error'
        })
        return
    end

    local targetPed = GetPlayerPed(targetPlayer)
    if not targetPed or targetPed == 0 then
        lib.notify({
            title = 'Gagal',
            description = 'Entitas pemain tidak valid!',
            type = 'error'
        })
        return
    end

    local vehicle = GetVehiclePedIsIn(targetPed, false)
    if not vehicle or vehicle == 0 then
        lib.notify({
            title = 'Gagal',
            description = 'Pemain tidak berada dalam kendaraan!',
            type = 'error'
        })
        return
    end

    local availableSeat = FindAvailableSeat(vehicle)
    EnterVehicle(
        vehicle, 
        availableSeat,
        'Kamu telah teleport ke kendaraan pemain ID: ' .. targetId .. ' di kursi ' .. (availableSeat or 0),
        'Kendaraan penuh! Masuk paksa ke kursi penumpang (seat 0).'
    )
end)

local function safeExport(resourceName, exportName)
    if GetResourceState(resourceName) ~= 'started' then return false end

    local ok, result = pcall(function()
        return exports[resourceName][exportName]()
    end)

    if not ok then return true end
    return result == true
end

local function isInBlockedState()
    local kedipConfig = config.kedip
    local playerPed = PlayerPedId()

    if safeExport('sm_policejob', 'IsEscortingPlayer') then
        return kedipConfig.messages.isEscorting
    end

    if safeExport('sm_policejob', 'IsEscorted') then
        return kedipConfig.messages.isEscorted
    end

    if safeExport('sm_carrysystem', 'isCarrying') then
        return kedipConfig.messages.isCarrying
    end

    if safeExport('sm_carrysystem', 'isBeingCarried') then
        return kedipConfig.messages.isBeingCarried
    end

    if LocalPlayer.state.isInAnimation or LocalPlayer.state.currentEmote then
        return kedipConfig.messages.inAnimation
    end

    if IsEntityAttached(playerPed)
        or IsEntityAttachedToAnyPed(playerPed)
        or IsEntityAttachedToAnyVehicle(playerPed)
        or IsEntityAttachedToAnyObject(playerPed) then
        return kedipConfig.messages.isAttached
    end

    if IsPedRagdoll(playerPed) or IsPedFalling(playerPed) then
        return kedipConfig.messages.isRagdoll
    end

    return nil
end

local kedipInputLocked = false

local function setKedipInputLock(locked)
    kedipInputLocked = locked
    LocalPlayer.state.canEmote = not locked
end

local function fadeScreen(fadeOut, duration)
    if fadeOut then
        DoScreenFadeOut(duration)
        while not IsScreenFadedOut() do
            Wait(0)
        end
    else
        DoScreenFadeIn(duration)
        while not IsScreenFadedIn() do
            Wait(0)
        end
    end
end

-- Callbacks
lib.callback.register('getVehicleClassByPlate', function(plate)
    local allVehicles = GetGamePool('CVehicle')
    
    for _, vehicle in ipairs(allVehicles) do
        local vehPlate = GetVehicleNumberPlateText(vehicle)
        if vehPlate then
            local cleanVehPlate = string.gsub(vehPlate, "%s+", "")
            local cleanInputPlate = string.gsub(plate, "%s+", "")
            
            if cleanVehPlate == cleanInputPlate then
                local vehicleClass = GetVehicleClass(vehicle)
                return vehicleClass
            end
        end
    end
    
    return nil
end)

-- CK Confirmation
RegisterNetEvent('ck:client:ConfirmDelete', function()
    if source ~= 65535 then return end
    
    local alert = lib.alertDialog({
        header = 'Character Kill Confirmation',
        content = 'Admin ingin menghapus karakter kamu. Apakah kamu setuju?',
        centered = true,
        cancel = true,
        labels = {
            confirm = 'Ya, Hapus Karakter',
            cancel = 'Tidak, Batalkan'
        }
    })

    lib.callback.await('ck:confirmDelete', false, alert == 'confirm')
end)

-- Resource Stop Handler
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    if isMicrophoneActive then
        exports['pma-voice']:clearProximityOverride()
    end
    deleteMicrophoneProp()

    if kedipInputLocked then
        ClearFocus()
        NewLoadSceneStop()
        DoScreenFadeIn(0)
        setKedipInputLock(false)
    end

    if activeBlackout then
        activeBlackout = false
        for _, threadData in pairs(blackoutThreads) do
            if threadData then threadData.active = false end
        end
        blackoutThreads = {}

        local blackoutConfig = config.enhancedItems.purification_potion
            and config.enhancedItems.purification_potion.blackout
        if blackoutConfig then
            StopScreenEffect(blackoutConfig.screenEffect)
        end
        ClearTimecycleModifier()
        ClearPedTasks(PlayerPedId())
    end
end)

-- Exports
exports('isStaminaBoosted', function()
    return activeStaminaBoost
end)

exports('isPoisoned', function()
    return activePoisonEffect
end)

exports('getPoisonTimeRemaining', function()
    if not activePoisonEffect then return 0 end
    return math.max(0, poisonEndTime - GetGameTimer())
end)

exports('curePoison', function()
    if activePoisonEffect then
        stopPoisonEffect()
    end
end)

exports('isBlackedOut', function()
    return activeBlackout
end)

exports('getBlackoutTimeRemaining', function()
    if not activeBlackout then return 0 end
    return math.max(0, blackoutEndTime - GetGameTimer())
end)

exports('getStaminaBoostTimeRemaining', function()
    if not activeStaminaBoost then return 0 end
    return math.max(0, staminaBoostEndTime - GetGameTimer())
end)

exports('isNoRecoilActive', function()
    return activeNoRecoil
end)

exports('getNoRecoilTimeRemaining', function()
    if not activeNoRecoil then return 0 end
    return math.max(0, noRecoilEndTime - GetGameTimer())
end)

exports('getActiveScreenShakes', function()
    return activeScreenShakes
end)

exports('stopAllScreenShakes', function()
    for shakeId, _ in pairs(activeScreenShakes) do
        activeScreenShakes[shakeId] = nil
    end
end)

exports('isHoldStressActive', function()
    return activeHoldStress
end)

exports('getHoldStressTimeRemaining', function()
    if not activeHoldStress then return 0 end
    return math.max(0, holdStressEndTime - GetGameTimer())
end)

-- Recoil Override System
-- local function callRecoil(recoils)
--     if activeNoRecoil then
--         return
--     end
    
--     if not _ipDD(cache.ped) then
--         local originalPitch = _ggCP()
        
--         -- Kick up
--         local tv = 0
--         repeat
--             Wait(0)
--             local camPos = _ggCP()
--             if _gfPV() ~= 4 then
--                 _sgCV(camPos + 0.2, 0.4)
--             end
--             tv = tv + 0.6
--         until tv >= recoils
        
--         -- Recovery: force return to original pitch
--         local maxFrames = 30 -- safety limit biar ga infinite loop
--         local frame = 0
--         repeat
--             Wait(0)
--             local camPos = _ggCP()
--             local diff = camPos - originalPitch
            
--             if math.abs(diff) < 0.05 then
--                 -- udah cukup deket, snap langsung
--                 if _gfPV() ~= 4 then
--                     _sgCV(originalPitch, 0.4)
--                 end
--                 break
--             end
            
--             -- ease back: makin deket makin pelan
--             local step = diff * 0.35
--             if math.abs(step) < 0.05 then
--                 step = diff > 0 and 0.05 or -0.05
--             end
            
--             if _gfPV() ~= 4 then
--                 _sgCV(camPos - step, 0.4)
--             end
            
--             frame = frame + 1
--         until frame >= maxFrames
        
--         -- final snap ke posisi exact
--         if _gfPV() ~= 4 then
--             _sgCV(originalPitch, 0.4)
--         end
--     end
-- end

-- local function pistolWhipLoop()
--     CreateThread(function()
--         local sleep
--         while cache.weapon do
--             sleep = 1
--             local effect = weaponEffect[cache.weapon]

--             if effect then
--                 if IsPedShooting(cache.ped) then
--                     if effect.camera_shake and not activeNoRecoil then
--                         ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', effect.camera_shake)
--                     end
--                     if effect.recoil then
--                         callRecoil(effect.recoil)
--                     end
--                     if effect.infinite_ammo then
--                         SetPedInfiniteAmmo(cache.ped, true, cache.weapon)
--                     end
--                 end
--             end
--             Wait(sleep)
--         end
--     end)
-- end

-- lib.onCache('weapon', function(weapon)
--     Wait(5)
--     if not weapon then return end
--     pistolWhipLoop()
-- end)

-- Microphone Commands
RegisterCommand('resetmic', function()
    if not isMicrophoneActive then
        lib.notify({
            title = 'Error',
            description = 'Tidak ada microphone yang aktif',
            type = 'error'
        })
        return
    end
    
    exports['pma-voice']:clearProximityOverride()
    currentMicrophoneRadius = nil
    isMicrophoneActive = false
    stopMicrophoneAnimation()
    lib.callback.await('microphone:setInactive', false)
    
    lib.notify({
        title = 'Microphone',
        description = 'Microphone direset ke default',
        type = 'inform'
    })
end, false)

RegisterCommand('stopmic', function()
    if not isHoldingMicrophone then
        lib.notify({
            title = 'Error',
            description = 'Tidak memegang mic',
            type = 'error'
        })
        return
    end
    stopMicrophoneAnimation()
end, false)

-- Kedip Command
RegisterCommand('kedip', function()
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    local kedipConfig = config.kedip

    local playerData = QBCore.Functions.GetPlayerData()
    local metadata = playerData and playerData.metadata

    if IsEntityDead(PlayerPedId()) or (metadata and (metadata["isdead"] or metadata["inlaststand"])) then
        lib.notify({ description = "Tidak bisa menggunakan command ini saat mati", type = "error" })
        return
    end

    if metadata and metadata["ishandcuffed"] then
        lib.notify({ description = "Tidak bisa menggunakan command ini saat diborgol", type = "error" })
        return
    end

    if LocalPlayer.state.smFarmRide or LocalPlayer.state.smFarmBoarded then
        lib.notify({ description = "Turun dari hewan dulu sebelum kedip.", type = "error" })
        return
    end

    if exports.sm_sidejob:isInDrugField() then
        lib.notify({
            title = 'Error',
            description = kedipConfig.messages.inDrugField,
            type = 'error'
        })
        return
    end
    
    if vehicle ~= 0 then
        lib.notify({
            title = 'Error',
            description = kedipConfig.messages.inVehicle,
            type = 'error'
        })
        return
    end

    local blockedReason = isInBlockedState()
    if blockedReason then
        lib.notify({
            title = 'Error',
            description = blockedReason,
            type = 'error'
        })
        return
    end

    if kedipCooldown then
        lib.notify({
            title = 'Cooldown',
            description = kedipConfig.messages.onCooldown,
            type = 'error'
        })
        return
    end
    
    kedipCooldown = true
    setKedipInputLock(true)

    local originalCoords = GetEntityCoords(playerPed)
    local originalHeading = GetEntityHeading(playerPed)
    local focusCoords = kedipConfig.focusLocation

    fadeScreen(true, kedipConfig.fadeOutDuration)

    lib.callback.await('kedip:changeBucket', false, 'temp')

    SetFocusPosAndVel(focusCoords.x, focusCoords.y, focusCoords.z, 0.0, 0.0, 0.0)

    local unloadUntil = GetGameTimer() + kedipConfig.unloadDuration

    while GetGameTimer() < unloadUntil do
        RequestCollisionAtCoord(originalCoords.x, originalCoords.y, originalCoords.z)
        Wait(0)
    end

    ClearFocus()

    lib.callback.await('kedip:changeBucket', false, 'normal')

    NewLoadSceneStartSphere(originalCoords.x, originalCoords.y, originalCoords.z, kedipConfig.loadRadius, 0)

    local loadUntil = GetGameTimer() + kedipConfig.loadTimeout

    while not IsNewLoadSceneLoaded() and GetGameTimer() < loadUntil do
        RequestCollisionAtCoord(originalCoords.x, originalCoords.y, originalCoords.z)
        Wait(0)
    end

    NewLoadSceneStop()

    local collisionUntil = GetGameTimer() + kedipConfig.loadTimeout

    while not HasCollisionLoadedAroundEntity(playerPed) and GetGameTimer() < collisionUntil do
        RequestCollisionAtCoord(originalCoords.x, originalCoords.y, originalCoords.z)
        Wait(0)
    end

    if #(GetEntityCoords(playerPed) - originalCoords) > kedipConfig.driftTolerance then
        SetEntityCoords(playerPed, originalCoords.x, originalCoords.y, originalCoords.z, false, false, false, false)
        SetEntityHeading(playerPed, originalHeading)
    end

    fadeScreen(false, kedipConfig.fadeInDuration)

    setKedipInputLock(false)

    lib.notify({
        title = 'Success',
        description = kedipConfig.messages.success,
        type = 'success'
    })

    SetTimeout(kedipConfig.cooldownTime, function()
        kedipCooldown = false
        lib.notify({
            title = 'Info',
            description = kedipConfig.messages.cooldownReady,
            type = 'inform'
        })
    end)
end, false)

-- Tenggelam/Jatuh Command
local tenggelamCooldownEnd = 0

local function notifyError(description)
    lib.notify({ title = 'Error', description = description, type = 'error' })
end

---@param x number
---@param y number
---@param timeout number
local function streamCollisionColumn(x, y, timeout)
    local deadline = GetGameTimer() + timeout
    local scanZ = config.tenggelam.minScanHeight

    while scanZ < config.tenggelam.maxScanHeight do
        RequestCollisionAtCoord(x, y, scanZ)
        scanZ = scanZ + 100.0
    end

    repeat
        RequestCollisionAtCoord(x, y, 0.0)
        Wait(0)
    until HasCollisionLoadedAroundEntity(PlayerPedId()) or GetGameTimer() >= deadline
end

local function findGroundZ(x, y, fromZ)
    local cfg = config.tenggelam

    streamCollisionColumn(x, y, cfg.collisionRequestTimeout)

    local scanZ = cfg.minScanHeight
    local nearestBelow = nil
    local nearestAbove = nil

    while scanZ < cfg.maxScanHeight do
        local found, groundZ = GetGroundZFor_3dCoord(x, y, scanZ, false)
        if found then
            if groundZ <= fromZ then
                if not nearestBelow or groundZ > nearestBelow then
                    nearestBelow = groundZ
                end
            elseif not nearestAbove or groundZ < nearestAbove then
                nearestAbove = groundZ
            end
        end

        scanZ = scanZ + cfg.scanStep
        Wait(0)
    end

    if nearestBelow then return nearestBelow, nearestAbove end
    if nearestAbove then return nearestAbove, nearestAbove end

    return nil
end

local function formatRemaining(ms)
    local totalSeconds = math.ceil(ms / 1000)
    local minutes = math.floor(totalSeconds / 60)
    local seconds = totalSeconds % 60

    if minutes > 0 then
        return string.format('%dm %ds', minutes, seconds)
    end

    return string.format('%ds', seconds)
end

local function isStuckOutOfWorld(entity, coords, groundZ, inVehicle, ceilingZ)
    local cfg = config.tenggelam

    if groundZ and ceilingZ and coords.z < (ceilingZ - cfg.undergroundThreshold)
        and not IsEntityInWater(entity) then
        return true
    end

    if not groundZ then
        if IsEntityInWater(entity) then
            return false
        end

        if not inVehicle and (IsPedSwimming(entity) or IsPedSwimmingUnderWater(entity)) then
            return false
        end

        return true
    end

    if inVehicle then
        if coords.z < (groundZ - cfg.undergroundThreshold) then
            return true
        end

        if IsEntityInWater(entity) then
            return false
        end

        return (coords.z - groundZ) > cfg.floatingThreshold
            and GetEntitySpeed(entity) < cfg.vehicleStuckMaxSpeed
    end

    if IsPedSwimming(entity) or IsPedSwimmingUnderWater(entity) then
        return false
    end

    if coords.z < (groundZ - cfg.undergroundThreshold) then
        return true
    end

    local isDead = IsEntityDead(entity) or LocalPlayer.state.isdead

    if isDead then
        return false
    end

    if not IsEntityInAir(entity) and not IsPedFalling(entity) then
        return false
    end

    if IsPedInParachuteFreeFall(entity) then
        return false
    end

    return (coords.z - groundZ) > cfg.floatingThreshold
        and GetEntityHeightAboveGround(entity) > cfg.floatingThreshold
end

local function getTenggelamBlockedReason(playerPed, metadata, vehicle)
    local cfg = config.tenggelam

    if metadata and metadata['ishandcuffed'] then
        return cfg.messages.isHandcuffed
    end

    if exports.sm_sidejob:isInDrugField() then
        return cfg.messages.inDrugField
    end

    if vehicle ~= 0 then
        if GetPedInVehicleSeat(vehicle, -1) ~= playerPed then
            return cfg.messages.notDriver
        end

        return nil
    end

    local blockedReason = isInBlockedState()
    if not blockedReason then
        return nil
    end

    local kedipMessages = config.kedip.messages

    if blockedReason == kedipMessages.isRagdoll then
        return nil
    end

    if LocalPlayer.state.isdead and blockedReason == kedipMessages.inAnimation then
        return nil
    end

    return blockedReason
end

local function returnToGround(playerPed, coords, groundZ, vehicle)
    local cfg = config.tenggelam
    local inVehicle = vehicle ~= 0
    local entity = inVehicle and vehicle or playerPed
    local zOffset = inVehicle and cfg.vehicleZOffset or cfg.safeZOffset
    local usedFallback = false

    if not groundZ then
        usedFallback = true
        coords = cfg.fallbackCoords
        groundZ = coords.z
    end

    local targetZ = groundZ + zOffset

    fadeScreen(true, cfg.fadeOutDuration)
    Wait(cfg.fadeOutDuration)

    local isDead = IsEntityDead(playerPed) or LocalPlayer.state.isdead

    if inVehicle then
        SetVehicleOnGroundProperly(vehicle)
    else
        DetachEntity(playerPed, true, false)
        if not isDead then
            ClearPedTasksImmediately(playerPed)
        end
    end

    SetEntityCoordsNoOffset(entity, coords.x, coords.y, targetZ, false, false, false)
    FreezeEntityPosition(entity, true)

    local timeout = GetGameTimer() + cfg.collisionTimeout
    repeat
        RequestCollisionAtCoord(coords.x, coords.y, targetZ)
        Wait(0)
    until HasCollisionLoadedAroundEntity(entity) or GetGameTimer() >= timeout

    local found, finalGroundZ = GetGroundZFor_3dCoord(coords.x, coords.y, cfg.maxScanHeight, false)
    if not found then
        found, finalGroundZ = GetGroundZFor_3dCoord(coords.x, coords.y, targetZ + 5.0, false)
    end

    if found and (usedFallback or finalGroundZ <= targetZ) then
        SetEntityCoordsNoOffset(entity, coords.x, coords.y, finalGroundZ + zOffset, false, false, false)
    end

    FreezeEntityPosition(entity, false)

    if inVehicle then
        SetEntityVelocity(vehicle, 0.0, 0.0, 0.0)
        SetVehicleOnGroundProperly(vehicle)
        if usedFallback then
            SetEntityHeading(vehicle, cfg.fallbackHeading)
        end
    else
        if usedFallback then
            SetEntityHeading(playerPed, cfg.fallbackHeading)
        end
        if not isDead then
            ClearPedTasks(playerPed)
        end
    end

    Wait(cfg.settleDelay)
    fadeScreen(false, cfg.fadeInDuration)

    return usedFallback
end

RegisterCommand('tenggelam', function()
    local cfg = config.tenggelam
    local playerPed = PlayerPedId()
    local playerData = QBCore.Functions.GetPlayerData()
    local vehicle = GetVehiclePedIsIn(playerPed, false)

    local blockedReason = getTenggelamBlockedReason(playerPed, playerData and playerData.metadata, vehicle)
    if blockedReason then
        return notifyError(blockedReason)
    end

    local remaining = tenggelamCooldownEnd - GetGameTimer()
    if remaining > 0 then
        return lib.notify({
            title = 'Cooldown',
            description = string.format(cfg.messages.onCooldown, formatRemaining(remaining)),
            type = 'error'
        })
    end

    local entity = vehicle ~= 0 and vehicle or playerPed
    local coords = GetEntityCoords(entity)
    local groundZ, ceilingZ = findGroundZ(coords.x, coords.y, coords.z)

    if not isStuckOutOfWorld(entity, coords, groundZ, vehicle ~= 0, ceilingZ) then
        return notifyError(vehicle ~= 0 and cfg.messages.notStuckVehicle or cfg.messages.notStuck)
    end

    tenggelamCooldownEnd = GetGameTimer() + cfg.cooldownTime

    local usedFallback = returnToGround(playerPed, coords, groundZ, vehicle)

    lib.notify({
        title = 'Success',
        description = usedFallback and cfg.messages.fallbackUsed or cfg.messages.success,
        type = 'success'
    })

    SetTimeout(cfg.cooldownTime, function()
        lib.notify({ title = 'Info', description = cfg.messages.cooldownReady, type = 'inform' })
    end)
end, false)

-- CID Command
RegisterCommand('cid', function()
    local PlayerData = QBCore.Functions.GetPlayerData()
    
    if PlayerData and PlayerData.citizenid then
        local citizenid = PlayerData.citizenid
        
        lib.setClipboard(citizenid)
        
        lib.notify({
            title = 'Citizen ID',
            description = 'ID: ' .. citizenid .. '\nBerhasil di copy!',
            type = 'success',
        })
    else
        lib.notify({
            title = 'Error',
            description = 'Gagal mendapatkan Citizen ID',
            type = 'error',
        })
    end
end, false)


RegisterCommand('cekracun', function()
    if activePoisonEffect then
        local timeRemaining = math.max(0, poisonEndTime - GetGameTimer())
        local minutes = math.floor(timeRemaining / 60000)
        local seconds = math.floor((timeRemaining % 60000) / 1000)
        lib.notify({
            title = 'Poison Status',
            description = string.format("TERACUNI - Sisa: %dm %ds", minutes, seconds),
            type = 'error'
        })
    else
        lib.notify({
            title = 'Poison Status',
            description = 'Tidak teracuni',
            type = 'success'
        })
    end
end, false)

-- Check Recoil Command
RegisterCommand('checkrecoil', function()
    if activeNoRecoil then
        local timeRemaining = math.max(0, noRecoilEndTime - GetGameTimer())
        local minutes = math.floor(timeRemaining / 60000)
        local seconds = math.floor((timeRemaining % 60000) / 1000)
        lib.notify({
            title = 'No Recoil',
            description = string.format("AKTIF - Sisa: %dm %ds", minutes, seconds),
            type = 'success'
        })
    else
        lib.notify({
            title = 'No Recoil',
            description = 'TIDAK AKTIF',
            type = 'error'
        })
    end
end, false)

-- World Boundary Extension
CreateThread(function()
    ExtendWorldBoundaryForPlayer(-100000000000000000000000.0, -100000000000000000000000.0, 100000000000000000000000.0)  
    ExtendWorldBoundaryForPlayer(100000000000000000000000.0, 100000000000000000000000.0, 100000000000000000000000.0)
end)


-- Gas Mask
local wearingGasMask = false
local savedMaskDrawable = nil
local savedMaskTexture = nil

local function isFemale(ped)
    local model = GetEntityModel(ped)
    return model == GetHashKey('mp_f_freemode_01')
end

RegisterNetEvent('gasmask:client:toggle', function()
    local ped = PlayerPedId()

    local maskDrawable = isFemale(ped) and 23 or 36

    if not wearingGasMask then
        savedMaskDrawable = GetPedDrawableVariation(ped, 1)
        savedMaskTexture = GetPedTextureVariation(ped, 1)

        SetPedComponentVariation(ped, 1, maskDrawable, 0, 2)
        wearingGasMask = true

        lib.notify({
            title = 'Gas Mask',
            description = 'Gas mask dipasang',
            type = 'success'
        })
    else
        SetPedComponentVariation(ped, 1, savedMaskDrawable or 0, savedMaskTexture or 0, 2)
        wearingGasMask = false
        savedMaskDrawable = nil
        savedMaskTexture = nil

        lib.notify({
            title = 'Gas Mask',
            description = 'Gas mask dilepas',
            type = 'inform'
        })
    end
end)

exports('isWearingGasMask', function()
    return wearingGasMask
end)