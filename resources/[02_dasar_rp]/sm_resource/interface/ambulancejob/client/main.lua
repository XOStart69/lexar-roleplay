if not interface.init() then return end

local CONTROLS = {
    CALL_EMS = 38,
    HELP_ME = 74,
    RAGDOLL = 47,
    RESPAWN = 22
}

local COOLDOWN = {
    EMS = 300000,
    HELP_ME = 5000,
    RAGDOLL = 5000
}

local DISABLED_CONTROLS = {
    30, 31, 32, 33, 34, 35,
    24, 25, 37, 44, 45, 140, 141, 142, 143,
    71, 72, 75,
    21, 23, 36, 73, 257, 263, 264
}

local cooldowns = {
    ems = false,
    helpMe = false,
    ragdoll = false
}

local animWatchActive = false

local config = localmodule 'config.client'
local locations = localmodule 'data.locations'
local animation = config.anim

CreateThread(function ()
    if playerState.inMedicBed then
        playerState.canEmote = true
        playerState.inMedicBed = false
    end

    playerState.anticombat = false
end)

local function isDeathAnimActive()
    local animdata = cache.vehicle and animation.death_vehicle or animation.death
    return IsEntityPlayingAnim(cache.ped, animdata.dict, animdata.clip, 3)
end

local function hasBlockingState()
    return IsPedRagdoll(cache.ped)
        or IsPedGettingUp(cache.ped)
        or IsPedBeingStunned(cache.ped)
end

local function isReviveAnimActive()
    return LocalPlayer.state.reviveAnim == true
end

local function playDeathAnimation()
    if not playerState.isdead then return end
    if LocalPlayer.state.reviveAnim then return end
    local animdata = cache.vehicle and animation.death_vehicle or animation.death
    lib.playAnim(cache.ped, animdata.dict, animdata.clip, 1.0, 8.0, -1, 1, 0.0, false, false, false)
end

local function ensureDeathAnimation()
    if animWatchActive then return end

    animWatchActive = true

    CreateThread(function()
        local nextCheck = 0

        while playerState.isdead do
            Wait(150)

            if GetGameTimer() < nextCheck then
                goto continue
            end

            if isReviveAnimActive() then
                nextCheck = GetGameTimer() + 300
                goto continue
            end

            if not isDeathAnimActive() then
                if hasBlockingState() then
                    nextCheck = GetGameTimer() + 300
                else
                    playDeathAnimation()
                    nextCheck = GetGameTimer() + 400
                end
            end

            ::continue::
        end

        animWatchActive = false
    end)
end

local function handleVoiceState(isActive)
    if GetResourceState('pma-voice') ~= 'started' then return end

    MumbleSetActive(isActive)

    if not isActive then
        lib.notify({ description = 'Kamu tidak bisa mendengar/berbicara saat pingsan', type = 'warning' })
    end
end

local function sendDistressSignal()
    local playerData = exports.tk_dispatch:getPlayerData()

    local callData = {
        title = 'Darurat Medis',
        code = '10-52',
        priority = 'Priority 2',
        coords = RHDCache.coords.xyz,
        location = playerData.location,
        direction = playerData.direction,
        gender = playerData.gender,
        weapon = playerData.weapon,
        vehicle = playerData.vehicle,
        message = 'Seseorang membutuhkan bantuan medis segera!',
        removeTime = 300000,
        showTime = 7500,
        color = 'red',
        flash = true,
        playSound = true,
        jobs = { 'ambulance', 'banmeskota' },
        blip = {
            sprite = 153,
            scale = 1.2,
            color = 1,
            flash = true,
            radius = 100.0
        }
    }

    TriggerTokenEvent('ambulance:send_dispatch', callData)
    lib.notify({ description = 'Sinyal darurat telah dikirim ke EMS!' })
end

local function disableControlsWhileDead()
    CreateThread(function()
        while playerState.isdead do
            Wait(0)
            for i = 1, #DISABLED_CONTROLS do
                DisableControlAction(0, DISABLED_CONTROLS[i], true)
            end
        end
    end)
end

local function performRagdoll()
    ClearPedTasksImmediately(cache.ped)
    SetEntityCoordsNoOffset(cache.ped, RHDCache.coords.x, RHDCache.coords.y, RHDCache.coords.z + 1.0, false, false, false)
    Wait(100)

    SetPedToRagdoll(cache.ped, 3000, 3000, 0, false, false, false)
    interface.send({ action = 'ragdollCooldown' })

    SetTimeout(3500, function()
        if playerState.isdead then
            playDeathAnimation()
        end
    end)
end

local function handleEmsCall()
    if cooldowns.ems then
        return lib.notify({ description = 'Tunggu sebelum mengirim sinyal darurat lagi!', type = 'error' })
    end

    cooldowns.ems = true
    sendDistressSignal()
    interface.send({ action = 'setStatus', status = 'ems_called' })

    SetTimeout(COOLDOWN.EMS, function()
        cooldowns.ems = false
    end)
end

local function handleHelpMe()
    if cooldowns.helpMe then
        return lib.notify({ description = 'Tunggu sebelum mengirim pesan bantuan lagi!', type = 'error' })
    end

    cooldowns.helpMe = true
    ExecuteCommand('helpme')
    interface.send({ action = 'helpMeCooldown' })

    SetTimeout(COOLDOWN.HELP_ME, function()
        cooldowns.helpMe = false
    end)
end

local function handleRagdoll()
    if cooldowns.ragdoll then
        return lib.notify({ description = 'Tunggu sebelum refresh body lagi!', type = 'error' })
    end

    cooldowns.ragdoll = true
    performRagdoll()

    SetTimeout(COOLDOWN.RAGDOLL, function()
        cooldowns.ragdoll = false
    end)
end

local function processInputs()
    if not config.eventMode then
        if IsControlJustPressed(0, CONTROLS.CALL_EMS) then
            handleEmsCall()
        end

        if IsControlJustPressed(0, CONTROLS.HELP_ME) then
            handleHelpMe()
        end
    end

    if IsControlJustPressed(0, CONTROLS.RAGDOLL) then
        handleRagdoll()
    end

    if playerState.deathtime and playerState.deathtime <= 0 then
        if IsControlJustPressed(0, CONTROLS.RESPAWN) then
            interface.send({ action = 'startRespawn' })
        elseif IsControlPressed(0, CONTROLS.RESPAWN) then
            interface.send({ action = 'holdRespawn' })
        elseif IsControlJustReleased(0, CONTROLS.RESPAWN) then
            interface.send({ action = 'cancelRespawn' })
        end
    end
end

local function resurrectPlayer()
    if cache.vehicle then
        local seats = GetVehicleModelNumberOfSeats(GetEntityModel(cache.vehicle))

        for seat = -1, seats do
            if GetPedInVehicleSeat(cache.vehicle, seat) == cache.ped then
                NetworkResurrectLocalPlayer(RHDCache.coords.x, RHDCache.coords.y, RHDCache.coords.z + 0.5, RHDCache.coords.w, true, false)
                SetPedIntoVehicle(cache.ped, cache.vehicle, seat)
                break
            end
        end
    else
        NetworkResurrectLocalPlayer(RHDCache.coords.x, RHDCache.coords.y, RHDCache.coords.z + 0.5, RHDCache.coords.w, true, false)
    end
end

local function initializeDeathUI()
    interface.send({
        action = 'initState',
        show = true,
        critical = false,
        time = playerState.deathtime,
        emsCooldown = 300,
        billCost = config.billCost,
        isDead = true,
        eventMode = config.eventMode == true,
        eventHint = config.eventHint,
        eventCommand = config.eventCommand
    })
end

local function cleanupAfterRevive()
    playerState.isdead = false
    playerState.deathtime = 0

    animWatchActive = false

    cooldowns.ems = false
    cooldowns.helpMe = false
    cooldowns.ragdoll = false

    ClearPedTasksImmediately(cache.ped)
    ClearPedTasks(cache.ped)

    handleVoiceState(true)
    SetEntityInvincible(cache.ped, false)

    interface.focus(false, false)
    interface.send({ action = 'hide' })
    interface.send({ action = 'resetUI' })

    TriggerTokenEvent('ambulance:set_dead', false)
end

local function onDeath()
    if playerState.isdead then return end

    playerState.isdead = true
    TriggerTokenEvent('ambulance:set_dead', true)
    TriggerServerEvent('InteractSound_SV:PlayOnSource', 'demo', 0.1)

    handleVoiceState(false)
    while GetEntitySpeed(cache.ped) > 0.5 or IsPedRagdoll(cache.ped) do
        Wait(10)
    end

    if not playerState.isdead then return end

    resurrectPlayer()
    SetEntityInvincible(cache.ped, true)
    SetEntityHealth(cache.ped, GetEntityMaxHealth(cache.ped))

    playDeathAnimation()
    ensureDeathAnimation()
    disableControlsWhileDead()

    playerState.deathtime = config.deathTime
    initializeDeathUI()
end

local function deathTimer()
    if not config.eventMode then
        CreateThread(function()
            local dtime = playerState.deathtime

            while playerState.isdead do
                Wait(1000)

                if dtime > 0 then
                    dtime = dtime - 1
                    interface.send({ action = 'updateTimer', time = dtime })

                    if dtime <= 0 then
                        interface.send({ action = 'enableRespawn' })
                    end

                    playerState.deathtime = dtime
                end
            end
        end)
    end

    CreateThread(function()
        while playerState.isdead do
            processInputs()
            Wait(1)
        end
    end)
end

AddEventHandler('gameEventTriggered', function(event, data)
    if event ~= 'CEventNetworkEntityDamage' then return end
    if playerState.pvpMatch then return end

    local victim = data[1]
    local victimDied = data[4]

    if not IsEntityAPed(victim) then return end
    if NetworkGetPlayerIndexFromPed(victim) ~= cache.playerId then return end

    local currentHealth = GetEntityHealth(cache.ped)
    local isEntityDead = IsEntityDead(cache.ped)

    if victimDied and currentHealth <= 0 and isEntityDead and not playerState.isdead then
        onDeath()
        deathTimer()
    end
end)

interface.callback('keyPressed', function(_, cb)
    cb(1)
end)

interface.callback('close', function(_, cb)
    interface.focus(false, false)
    cb(1)
end)

interface.callback('completeRespawn', function()
    if playerState.isdead and playerState.deathtime and playerState.deathtime <= 0 then
        TriggerTokenEvent('ambulance:respawn')
    end
end)

RegisterNetEvent('ambulance:client:revive', function()
    if source == '' then return end

    if IsPedDeadOrDying(cache.ped, true) or IsEntityDead(cache.ped) then
        local pos = RHDCache.coords
        NetworkResurrectLocalPlayer(pos.x, pos.y, pos.z, pos.w, true, false)
    end

    SetEntityInvincible(cache.ped, false)
    SetEntityMaxHealth(cache.ped, 200)
    SetEntityHealth(cache.ped, 200)

    Wait(100)

    if playerState.inMedicBed then
        lib.playAnim(cache.ped, animation.revive.dict, animation.revive.clip, 8.0, 1.0, -1, 1, 0, 0, 0, 0)
        SetEntityInvincible(cache.ped, true)
    end

    ClearPedBloodDamage(cache.ped)
    SetPlayerSprint(cache.playerId, true)
    ResetPedMovementClipset(cache.ped, 0.0)

    cleanupAfterRevive()
    TriggerEvent('idle:client:ResetState')
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    exports.spawnmanager:setAutoSpawn(false)

    playerState.isdead = false
    animWatchActive = false

    interface.send({ action = 'hide' })

    CreateThread(function()
        SetEntityHealth(cache.ped, 200)
        Wait(5000)

        SetPlayerHealthRechargeMultiplier(cache.playerId, 0.0)
        SetPlayerHealthRechargeLimit(cache.playerId, 0.0)

        local pdata = QBPlayerData
        if not pdata or not pdata.metadata then
            pdata = exports.sm_core:GetPlayerData()
        end
        local metadata = pdata and pdata.metadata

        if metadata then
            local isDead = metadata.isdead or metadata.inlaststand
            if config.clearInventoryOnDisconnect then
                if isDead then
                    TriggerTokenEvent('ambulance:clearInventoryIfDead')
                end
            end

            if isDead then
                playerState.deathtime = config.deathTime
                onDeath()
                deathTimer()
            end
        end
    end)
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    playerState.isdead = false
    playerState.deathtime = 0
    animWatchActive = false

    if cache.ped and DoesEntityExist(cache.ped) then
        SetEntityInvincible(cache.ped, false)
    end

    interface.send({ action = 'hide' })
    interface.send({ action = 'resetUI' })
end)

CreateThread(function()
    AddTextEntry("BLIP_CAT_" .. 37, "Rumah Sakit")
    for i = 1, #locations.stations do
        local station = locations.stations[i]
        local blip = AddBlipForCoord(station.coords.x, station.coords.y, station.coords.z)
        SetBlipSprite(blip, 61)
        SetBlipAsShortRange(blip, true)
        SetBlipScale(blip, 0.8)
        SetBlipColour(blip, 25)
        SetBlipCategory(blip, 37)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(station.label)
        EndTextCommandSetBlipName(blip)
    end
end)
