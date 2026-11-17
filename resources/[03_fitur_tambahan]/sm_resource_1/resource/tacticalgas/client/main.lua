local config = localmodule 'config.shared'
local smoke = localmodule 'modules.smoke'
local effects = localmodule 'modules.effects'
local protection = localmodule 'modules.protection'

local grenades = config.grenades
local rubbing = config.rubbing
local tearGas = grenades.tearGas
local timecycle = tearGas.timecycle
local shake = tearGas.shake

local GetEntityCoords = GetEntityCoords
local SetTimecycleModifier = SetTimecycleModifier
local SetTimecycleModifierStrength = SetTimecycleModifierStrength
local ClearTimecycleModifier = ClearTimecycleModifier
local SetExtraTimecycleModifier = SetExtraTimecycleModifier
local SetExtraTimecycleModifierStrength = SetExtraTimecycleModifierStrength
local ClearExtraTimecycleModifier = ClearExtraTimecycleModifier
local ShakeGameplayCam = ShakeGameplayCam
local StopGameplayCamShaking = StopGameplayCamShaking
local IsControlPressed = IsControlPressed
local IsControlJustReleased = IsControlJustReleased
local ClearPedTasks = ClearPedTasks
local GetGameTimer = GetGameTimer
local DrawRect = DrawRect
local UseParticleFxAssetNextCall = UseParticleFxAssetNextCall
local StartParticleFxLoopedAtCoord = StartParticleFxLoopedAtCoord
local StopParticleFxLooped = StopParticleFxLooped
local Wait = Wait
local TriggerServerEvent = TriggerServerEvent
local tonumber = tonumber
local mathmin = math.min
local mathmax = math.max
local mathfloor = math.floor

local GAS_PER_TICK = 20.0
local GAS_DECAY = 0.5
local GAS_MAX = 100.0
local FOGBALL_FX = 'ent_amb_fbi_smoke_fogball'
local FOGBALL_DICT = 'core'
local INFO_ID = 'tacticalgas_teargas'
local RESYNC_INTERVAL = 15000

local COUGH_ANIM = { dict = 'timetable@gardener@smoking_joint', clip = 'idle_cough' }
local COVER_ANIM = { dict = 'anim@heists@ornate_bank@thermal_charge', clip = 'cover_eyes_loop' }
local RUB_ANIM = { dict = 'switch@trevor@floyd_crying', clip = 'console_end_loop_floyd' }
local DRUNK_CLIPSET = 'MOVE_M@DRUNK@VERYDRUNK'

local gasLevel = 0.0
local isCoveringEyes = false
local flashUntil = 0
local flashStartedAt = 0

RegisterNetEvent('tacticalgas:sound', function(file, volume)
    playTacticalGasSound(file, volume)
end)

RegisterNetEvent('tacticalgas:sync', function(list)
    smoke.merge(list)
end)

RegisterNetEvent('tacticalgas:spawn', function(id, cloud)
    smoke.add(id, cloud)
end)

RegisterNetEvent('tacticalgas:activate', function(id)
    smoke.activate(id)
end)

RegisterNetEvent('tacticalgas:step', function(id, step)
    smoke.setStep(id, step)
end)

RegisterNetEvent('tacticalgas:despawn', function(id)
    smoke.remove(id)
end)

CreateThread(function()
    local sinceSync = 0

    TriggerServerEvent('tacticalgas:requestSync')

    while true do
        smoke.refresh()

        Wait(1000)

        sinceSync = sinceSync + 1000

        if sinceSync >= RESYNC_INTERVAL then
            sinceSync = 0
            TriggerServerEvent('tacticalgas:requestSync')
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    smoke.clear()
    infoUI.remove(INFO_ID)
end)

RegisterNetEvent('tacticalgas:stun', function(coords)
    coords = vec3(coords.x, coords.y, coords.z)

    local flash = grenades.stun.flash
    local distance = #(coords - GetEntityCoords(cache.ped))

    if distance >= flash.radius * 4 then return end
    if protection.isImmune('stun') then return end

    local particle = grenades.stun.particle

    smoke.loadPtfx(particle.dict)
    UseParticleFxAssetNextCall(particle.dict)
    StartParticleFxNonLoopedAtCoord(
        particle.fx,
        coords.x, coords.y, coords.z + 0.2,
        0.0, 0.0, 0.0,
        0.4,
        false, false, false
    )

    if distance > flash.radius then
        return playTacticalGasSound('stun', flash.volume * 0.3)
    end

    local strength = 1.0 - (distance / flash.radius)
    local duration = flash.minDuration + ((flash.maxDuration - flash.minDuration) * strength)

    playTacticalGasSound('stun', flash.volume * (0.2 + (0.8 * strength)))

    if lib.requestAnimSet(DRUNK_CLIPSET, 5000) then
        SetPedMovementClipset(cache.ped, DRUNK_CLIPSET, 1.0)
    end

    SetTimecycleModifier('Drunk')
    SetPedIsDrunk(cache.ped, true)

    local startedAt = GetGameTimer()
    local endsAt = startedAt + duration

    if endsAt <= flashUntil then return end

    flashStartedAt = startedAt
    flashUntil = endsAt
end)

local clouds = smoke.clouds
local effectRadius = smoke.effectRadius
local smokeScale = grenades.smoke.scale

---@param grenade string
---@return TacticalGas_Cloud?
local function findCloudAround(grenade)
    local playerCoords = GetEntityCoords(cache.ped)
    local px, py, pz = playerCoords.x, playerCoords.y, playerCoords.z

    for _, cloud in pairs(clouds) do
        if cloud.active and cloud.grenade == grenade then
            local coords = cloud.coords
            local dx, dy, dz = coords.x - px, coords.y - py, coords.z - pz
            local radius = effectRadius(cloud)

            if dx * dx + dy * dy + dz * dz <= radius * radius then
                return cloud
            end
        end
    end
end

CreateThread(function()
    local fogball

    while true do
        local cloud = findCloudAround('smoke')

        if cloud then
            if not fogball then
                local coords = cloud.coords

                UseParticleFxAssetNextCall(FOGBALL_DICT)

                fogball = StartParticleFxLoopedAtCoord(
                    FOGBALL_FX,
                    coords.x, coords.y, coords.z + 0.2,
                    0.0, 0.0, 0.0,
                    smokeScale,
                    false, false, false, false
                )
            end
        elseif fogball then
            StopParticleFxLooped(fogball, 0)
            fogball = nil
        end

        Wait(cloud and 500 or 1000)
    end
end)

local function applyGasVisuals()
    if timecycle.extra then
        SetExtraTimecycleModifier(timecycle.extra.name)
        SetExtraTimecycleModifierStrength(timecycle.extra.opacity)
    end

    SetTimecycleModifier(timecycle.main.name)
    SetTimecycleModifierStrength((timecycle.main.opacity * gasLevel) / GAS_MAX)
end

local function clearGasVisuals()
    StopGameplayCamShaking(false)
    ClearTimecycleModifier()
    ClearExtraTimecycleModifier()
    ClearPedTasks(cache.ped)
end

CreateThread(function()
    local shaking = false

    while true do
        local exposed = findCloudAround('tearGas') ~= nil and not protection.isImmune('tearGas')

        if exposed then
            gasLevel = mathmin(gasLevel + GAS_PER_TICK, GAS_MAX)

            if not shaking then
                shaking = true
                ShakeGameplayCam(shake.name, shake.intensity)
            end
        end

        if gasLevel > 0.0 then
            applyGasVisuals()
        elseif shaking then
            shaking = false
            isCoveringEyes = false
            clearGasVisuals()
        end

        Wait(1000)
    end
end)

CreateThread(function()
    while true do
        if gasLevel > 0.0 then
            gasLevel = mathmax(gasLevel - GAS_DECAY, 0.0)
            Wait(500 / (isCoveringEyes and rubbing.speedMultiplier or 1.0))
        else
            Wait(500)
        end
    end
end)

CreateThread(function()
    local hintShown = false
    local wasFlashing = false

    while true do
        local gassed = gasLevel > 0.0
        local flashing = flashUntil > GetGameTimer()

        if gassed then
            effects.drawRecoveryBar(gasLevel)
            effects.disableControls(tearGas)

            if not hintShown then
                hintShown = true

                infoUI.show({
                    id = INFO_ID,
                    title = 'Terkena Gas Air Mata',
                    icon = 'fa-solid fa-eye-low-vision',
                    description = rubbing.label
                })
            end

            if IsControlPressed(0, rubbing.control) then
                if not isCoveringEyes then
                    isCoveringEyes = true
                    effects.playAnim(RUB_ANIM.dict, RUB_ANIM.clip)
                end
            elseif IsControlJustReleased(0, rubbing.control) then
                isCoveringEyes = false
                ClearPedTasks(cache.ped)
                effects.playAnim(COVER_ANIM.dict, COVER_ANIM.clip)
            end
        elseif hintShown then
            hintShown = false
            infoUI.remove(INFO_ID)
        end

        if flashing then
            local alpha = mathfloor(((flashUntil - GetGameTimer()) / (flashUntil - flashStartedAt)) * 255)

            if alpha > 0 then
                DrawRect(0.5, 0.5, 1.0, 1.0, 255, 255, 255, alpha)
            end

            effects.playAnim(COVER_ANIM.dict, COVER_ANIM.clip)
            effects.disableControls(grenades.stun)
            wasFlashing = true
        elseif wasFlashing then
            wasFlashing = false
            flashUntil = 0

            ClearPedTasks(cache.ped)
            ResetPedMovementClipset(cache.ped, 1.0)
            ClearTimecycleModifier()
            SetPedIsDrunk(cache.ped, false)
            StopGameplayCamShaking(true)
        end

        Wait((gassed or flashing) and 0 or 500)
    end
end)

CreateThread(function()
    while true do
        if gasLevel > 0.0 then
            if not isCoveringEyes then
                effects.playAnim(COUGH_ANIM.dict, COUGH_ANIM.clip)
            end

            Wait(1000)
            TriggerServerEvent('tacticalgas:cough')
            Wait(1000)

            if not isCoveringEyes then
                effects.playAnim(COVER_ANIM.dict, COVER_ANIM.clip)
            end

            Wait(4000)
        else
            Wait(500)
        end
    end
end)

exports('SetOverrideWearingMask', protection.setOverride)
