local config = localmodule 'config'

local Wait = Wait
local GetGameTimer = GetGameTimer
local IsControlJustPressed = IsControlJustPressed
local IsDisabledControlJustPressed = IsDisabledControlJustPressed
local DisableControlAction = DisableControlAction
local IsEntityPlayingAnim = IsEntityPlayingAnim
local IsPedUsingScenario = IsPedUsingScenario
local IsEntityInWater = IsEntityInWater

local PARTICLE_DICT = 'scr_mp_cig'
local PARTICLE_NAME = 'ent_anim_cig_smoke'
local STRESS_INTERVAL = config.stressInterval
local ANIM_CHECK_INTERVAL = 500
local MAX_ANIM_FAILS = 3
local THROW_CONTROL = 73
local OBJECT_WEAPON = `OBJECT`
local UNARMED = `WEAPON_UNARMED`
local COMBAT_CONTROLS = { 24, 25, 37, 44, 45, 47, 140, 141, 142, 143, 263, 264 }

local ALLOWED_ANIMATIONS = {
    { dict = 'mp_common', anim = 'givetake1_a' },
    { dict = 'pickup_object', anim = 'putdown_low' },
}

local STYLES = {
    { label = 'Style 1 - Standing', scenario = 'WORLD_HUMAN_SMOKING' },
    { label = 'Style 2 - Standing', scenario = 'WORLD_HUMAN_DRUG_DEALER' },
    { label = 'Style 3 - Standing', scenario = 'WORLD_HUMAN_SMOKING_POT' },
    { label = 'Style 4 - Casual', dict = 'amb@world_human_aa_smoke@male@idle_a', anim = 'idle_c' },
    { label = 'Style 5 - Relaxed', dict = 'amb@world_human_aa_smoke@male@idle_a', anim = 'idle_b' },
    { label = 'Style 6 - Female', dict = 'amb@world_human_smoking@female@idle_a', anim = 'idle_b' },
    { label = 'Style 7 - Car Meet', dict = 'anim@amb@carmeet@checkout_car@', anim = 'smoke_male_a_idle_b' },
}

---@class SmokingSession
---@field prop number
---@field style table
---@field stress number
---@field cancel boolean

---@type SmokingSession?
local session

---@param description string
---@param kind string
local function notify(description, kind)
    lib.notify({ title = 'Rokok', description = description, type = kind })
end

---@param ped number
---@return boolean
local function isDriving(ped)
    local vehicle = cache.vehicle
    return vehicle ~= false and vehicle ~= nil and GetPedInVehicleSeat(vehicle, -1) == ped
end

---@param ped number
---@return boolean
local function isPlayingAllowed(ped)
    for i = 1, #ALLOWED_ANIMATIONS do
        local entry = ALLOWED_ANIMATIONS[i]

        if IsEntityPlayingAnim(ped, entry.dict, entry.anim, 3) then
            return true
        end
    end

    return false
end

---@param ped number
---@param style table
---@return boolean
local function isStillSmoking(ped, style)
    if style.scenario then
        return IsPedUsingScenario(ped, style.scenario)
    end

    return IsEntityPlayingAnim(ped, style.dict, style.anim, 3)
end

---@param style table
local function playStyle(style)
    local ped = cache.ped

    if style.scenario then
        return TaskStartScenarioInPlace(ped, style.scenario, 0, true)
    end

    if lib.requestAnimDict(style.dict, 5000) then
        TaskPlayAnim(ped, style.dict, style.anim, 8.0, 8.0, -1, 49, 0, false, false, false)
    end
end

---@param model string
---@return number?
local function createProp(model)
    local hash = joaat(model)
    if not lib.requestModel(hash, 5000) then return end

    local ped = cache.ped
    local coords = GetEntityCoords(ped)
    local prop = CreateObject(hash, coords.x, coords.y, coords.z + 0.2, false, false, false)
    SetModelAsNoLongerNeeded(hash)

    if not DoesEntityExist(prop) then return end

    SetEntityCollision(prop, false, false)
    SetEntityCompletelyDisableCollision(prop, false, false)
    AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)

    return prop
end

---@param prop number
---@param smokeType string
local function startParticle(prop, smokeType)
    if not lib.requestNamedPtfxAsset(PARTICLE_DICT, 5000) then return end

    UseParticleFxAssetNextCall(PARTICLE_DICT)
    StartParticleFxLoopedOnEntity(PARTICLE_NAME, prop, -0.07, 0.0, 0.0, 0.0, 0.0, 0.0, smokeType == 'cigar' and config.cigarSmoke or config.cigaretteSmoke, false, false, false)
end

---@param message? string
---@param kind? string
local function stopSmoking(message, kind)
    local current = session
    if not current then return end

    session = nil

    local ped = cache.ped
    local prop = current.prop

    if DoesEntityExist(prop) then
        RemoveParticleFxFromEntity(prop)
        DetachEntity(prop, true, true)
        DeleteEntity(prop)
    end

    if current.style.scenario then
        ClearPedTasksImmediately(ped)
    else
        ClearPedTasks(ped)
    end

    ClearPedSecondaryTask(ped)

    if GetSelectedPedWeapon(ped) == OBJECT_WEAPON then
        SetCurrentPedWeapon(ped, UNARMED, true)
    end

    TriggerTokenEvent('sm_smoking:server:stop')

    if message then
        notify(message, kind or 'inform')
    end
end

---@param current SmokingSession
local function controlLoop(current)
    local disableCombat = config.disableCombat
    local count = #COMBAT_CONTROLS

    while session == current do
        if IsControlJustPressed(0, THROW_CONTROL) or IsDisabledControlJustPressed(0, THROW_CONTROL) then
            current.cancel = true
            break
        end

        if disableCombat then
            for i = 1, count do
                DisableControlAction(0, COMBAT_CONTROLS[i], true)
            end
        end

        Wait(0)
    end
end

---@param current SmokingSession
local function watchLoop(current)
    local lastStress = GetGameTimer()
    local fails = 0
    local overriding = false

    while session == current do
        Wait(ANIM_CHECK_INTERVAL)

        if session ~= current then break end

        local ped = cache.ped
        local allowed = isPlayingAllowed(ped)

        if allowed then
            overriding = true
            fails = 0
        elseif overriding then
            overriding = false
            SetTimeout(100, function()
                if session == current then
                    playStyle(current.style)
                end
            end)
        end

        if current.cancel then
            return stopSmoking('Rokok dibuang')
        end

        if isDriving(ped) then
            return stopSmoking('Rokok dibuang karena menyetir!', 'error')
        end

        local smoking = isStillSmoking(ped, current.style)

        if not allowed then
            fails = smoking and 0 or fails + 1

            if fails >= MAX_ANIM_FAILS then
                return stopSmoking('Rokok dibuang')
            end
        end

        local now = GetGameTimer()

        if now - lastStress >= STRESS_INTERVAL and (smoking or allowed) then
            lastStress = now

            if config.removeStress then
                TriggerTokenEvent('sm_smoking:server:stress')
            end
        end

        if IsEntityInWater(ped) then
            return stopSmoking('Rokok basah!', 'error')
        end
    end
end

---@param style table
---@param prop string
---@param smokeType string
---@param stress number
local function startSmoking(style, prop, smokeType, stress)
    if session then
        return notify('Anda sudah sedang merokok!', 'error')
    end

    if isDriving(cache.ped) then
        return notify('Anda tidak bisa merokok saat menyetir!', 'error')
    end

    if not lib.callback.await('sm_smoking:server:start', false) then return end

    local handle = createProp(prop)

    if not handle then
        TriggerTokenEvent('sm_smoking:server:stop')
        return notify('Gagal membuat prop rokok', 'error')
    end

    local current = { prop = handle, style = style, stress = stress, cancel = false }
    session = current

    startParticle(handle, smokeType)
    playStyle(style)
    Wait(500)

    CreateThread(function()
        watchLoop(current)
    end)

    CreateThread(function()
        controlLoop(current)
    end)

    notify(('Merokok dimulai - Stress akan turun -%s%% per 2 menit'):format(stress), 'inform')
end

RegisterNetEvent('sm_smoking:client:offer', function(_, prop, smokeType, stress)
    if session then
        return notify('Anda sudah sedang merokok!', 'error')
    end

    local options = {}

    for i = 1, #STYLES do
        local style = STYLES[i]

        options[i] = {
            title = style.label,
            description = 'Pilih gaya merokok ini',
            icon = 'smoking',
            onSelect = function()
                startSmoking(style, prop, smokeType, stress)
            end
        }
    end

    lib.registerContext({
        id = 'sm_smoking:styles',
        title = 'Pilih Gaya Merokok',
        options = options
    })

    lib.showContext('sm_smoking:styles')
end)

RegisterNetEvent('sm_smoking:client:unpack', function()
    local ped = cache.ped
    local coords = GetEntityCoords(ped)

    if lib.requestAnimDict('amb@world_human_smoking@male@male_a@enter', 5000) then
        TaskPlayAnim(ped, 'amb@world_human_smoking@male@male_a@enter', 'enter', 8.0, 8.0, 1000, 0, 0, false, false, false)
    end

    Wait(800)

    local hash = `prop_cigar_pack_01`
    if not lib.requestModel(hash, 5000) then return end

    local pack = CreateObject(hash, coords.x, coords.y, coords.z + 0.9, true, true, false)
    SetModelAsNoLongerNeeded(hash)
    AttachEntityToEntity(pack, ped, GetPedBoneIndex(ped, 64016), 0.020, -0.05, -0.010, 100.0, 0.0, 0.0, true, true, false, true, 1, true)

    if lib.requestAnimDict('mp_arresting', 5000) then
        TaskPlayAnim(ped, 'mp_arresting', 'a_uncuff', 8.0, 8.0, 3000, 0, 0, false, false, false)
    end

    Wait(3500)

    if DoesEntityExist(pack) then
        DeleteEntity(pack)
    end
end)

RegisterCommand('stopsmoking', function()
    stopSmoking()
end, false)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource or not session then return end

    stopSmoking()
end)
