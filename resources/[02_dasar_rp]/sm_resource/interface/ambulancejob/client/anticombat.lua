
local isLimping = false
local isCooldownActive = false
local crutchHidden = false

local centity
local blocktimer

local config = localmodule 'config.client'
local timerModule = require 'modules.timers.shared'

local function removeCrutchProp()
    if not (centity and DoesEntityExist(centity)) then
        centity = nil
        TriggerServerEvent('ambulance:crutch:track', nil)
        return
    end

    pcall(DeleteEntity, centity)
    centity = nil
    TriggerServerEvent('ambulance:crutch:track', nil)
end

local function spawnCrutchProp()
    removeCrutchProp()

    local model = 'crutch'
    lib.requestModel(model, 8000)

    local coords = GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, 2.0, 0.55)
    local x, y, z = table.unpack(coords)
    centity = CreateObject(model, x, y, z, true, true, false)

    if not DoesEntityExist(centity) then
        SetModelAsNoLongerNeeded(model)
        return false
    end

    if not NetworkGetEntityIsNetworked(centity) then
        NetworkRegisterEntityAsNetworked(centity)
    end

    local netId = NetworkGetNetworkIdFromEntity(centity)

    SetModelAsNoLongerNeeded(model)
    SetEntityAsMissionEntity(centity, true, false)
    SetEntityCollision(centity, false, false)
    SetEntityCompletelyDisableCollision(centity, false, false)

    AttachEntityToEntity(
        centity,
        cache.ped,
        GetPedBoneIndex(cache.ped, 43810),
        0.93, -0.15, -0.03,
        9.31, -88.64, 177.48,
        true, true, false, true, 1, true
    )

    TriggerServerEvent('ambulance:crutch:track', netId)
    return true
end

local function stopCrutchLoop()
    crutchHidden = false
    removeCrutchProp()
end

local function applyLimping(shouldLimp)
    local dict = isCooldownActive and
        config.walkstyle.lester or config.walkstyle.injured

    if shouldLimp then
        if not isLimping then
            lib.requestAnimSet(dict, 1500)
            SetPedMovementClipset(cache.ped, dict, 1.0)
        else
            if isLimping and GetPedCombatMovement(cache.ped) ~= dict and not emotemenu:IsPlayerCrouched() then
                lib.requestAnimSet(dict, 1500)
                SetPedMovementClipset(cache.ped, dict, 1.0)
            end
        end
    
        isLimping = true
        SetPlayerSprint(cache.playerId, false)
    else
        if isLimping then
            ResetPedMovementClipset(cache.ped, 1.0)
            SetPlayerSprint(cache.playerId, true)
            isLimping = false
        end
    end
end

local function startCooldownUI()
    isLimping = false
    stopCrutchLoop()
    Wait(500)

    spawnCrutchProp()
    isCooldownActive = true

    if blocktimer then
        blocktimer:stop()
    end

    playerState:set('healing_progress', true, true)

    blocktimer = timerModule:new('detik', QBPlayerData.metadata.medic_bcombat, function ()
        stopCrutchLoop()
        applyLimping(false)

        blocktimer = nil
        isCooldownActive = false

        playerState:set('healing_progress', false, true)
        TriggerTokenEvent('ambulance:set_anticombat', false)
    end)

    CreateThread(function()
        while isCooldownActive do
            infoUI.show({
                id = 'ambulance:blockaction',
                icon = 'fas fa-heartbeat',
                title = 'ANTI COMBAT',
                description = {
                    ['Recovery Mode'] = blocktimer:getTimeLeftFormat()
                }
            })

            if IsPedInMeleeCombat(cache.ped) then
                SetPedToRagdoll(cache.ped, 1000, 1000, 0, false, false, false)
                lib.notify({ description = 'Anda tidak bisa memukul selama cooldown!', type = 'error' })
                Wait(1000)
            end

            Wait(500)
        end

        infoUI.remove('ambulance:blockaction')
    end)
end

lib.onCache('weapon', function(weapon)
    if not isCooldownActive or not weapon then return end

    local whitelisted = config.anticombat.whitelistedWeapons
    local isAllowed = false

    for i = 1, #whitelisted do
        if weapon == whitelisted[i] then
            isAllowed = true
            break
        end
    end

    if not isAllowed then
        SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`, true)
        RemoveWeaponFromPed(cache.ped, weapon)
        lib.notify({ description = 'Anda tidak bisa mengeluarkan senjata selama AntiCombat!', type = 'error' })
    end
end)


lib.onCache('ped', function ()
    Wait(500)

    if isCooldownActive and not crutchHidden then
        isLimping = false
        spawnCrutchProp()
    end
end)

lib.onCache('vehicle', function (vehicle)
    crutchHidden = vehicle

    if crutchHidden then
        removeCrutchProp()
    else
        if isCooldownActive and not crutchHidden then
            spawnCrutchProp()
        end
    end
end)

CreateThread(function()
    while true do
        Wait(500)
        if not cache.ped then goto continue end

        if isCooldownActive then
            applyLimping(true)
        else
            local health = GetEntityHealth(cache.ped)
            local isInjured = health > 100 and health < 130
            applyLimping(isInjured)
        end

        ::continue::
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        stopCrutchLoop()
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function(data)
    Wait(5000)
    local pdata = QBPlayerData

    if pdata.metadata.medic_bcombat and pdata.metadata.medic_bcombat > 0 then
        startCooldownUI()
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    stopCrutchLoop()
end)

RegisterNetEvent('ambulance:anticombat:start', function()
    if source == '' then return end
    startCooldownUI()
end)

RegisterNetEvent('ambulance:anticombat:reset', function(data)
    if source == '' then return end

    if blocktimer then
        blocktimer:stop(true)
    end
end)

RegisterNetEvent('ambulance:anticombat:update', function(time)
    if source == '' or not blocktimer then return end

    blocktimer:setTime('detik', QBPlayerData.metadata.medic_bcombat)
end)
